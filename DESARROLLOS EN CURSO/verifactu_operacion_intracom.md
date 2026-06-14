# Verifactu: calificacion de operacion (intracomunitarias, ISP, export, REBU)

Soporte para facturas que no son ventas interiores en regimen general:
intracomunitarias (servicios no sujetos / entregas de bienes exentas),
inversion del sujeto pasivo, exportaciones y regimenes especiales como
bienes usados. El tipo se elige en la pestana "Otros" del mantenimiento de
facturas y el envio a la AEAT construye la calificacion correcta.

## Problema que resuelve

El subsistema solo sabia emitir operaciones interiores en regimen general
con cliente de NIF espanol:

- Identificaba al destinatario siempre por `<NIF>` y exigia 9 caracteres,
  asi que un NIF-IVA europeo (FR/DE...) reventaba el envio.
- El desglose fijaba siempre `ClaveRegimen=01`, `CalificacionOperacion=S1`
  (o `OperacionExenta=E1` en la banda exenta). No contemplaba N2, S2, E5,
  E2 ni claves de regimen especiales.

## Diseno: catalogo abierto

En vez de cablear los tipos en el codigo, se usa una tabla catalogo
**`fza_verifactu_operaciones`** que el usuario puede ampliar sin recompilar.
Cada fila define el mapeo a Verifactu:

| Columna | Uso |
|---|---|
| `CODIGO_VFO` (PK) | Identificador (INTERIOR, SERVICIO_INTRA, ISP, ...) |
| `DESCRIPCION_VFO` / `AYUDA_VFO` | Texto y ayuda para el usuario |
| `CLAVE_REGIMEN_VFO` | ClaveRegimen (01 general, 03 bienes usados...) |
| `CALIFICACION_VFO` | CalificacionOperacion (S1/S2/N1/N2) o vacio |
| `OPERACION_EXENTA_VFO` | OperacionExenta (E1..E6) o vacio |
| `ESREPERCUTE_IVA_VFO` | S = desglose por bandas; N = base sin cuota |
| `ORDEN_VFO`, `ESACTIVO_VFO` + 4 auditoria | estandar del repo |

Semilla inicial: INTERIOR, SERVICIO_INTRA (N2), ENTREGA_INTRA (E5), ISP
(S2), EXPORT (E2), BIENES_USADOS (clave 03).

La factura guarda el codigo elegido en la columna nueva
**`TIPO_OPER_VFACTU_FAC`** de `fza_facturas` (FK logica al catalogo).

## Cambios

### Esquema — `verifactu_operacion_intracom.sql` (idempotente)

1. Crea `fza_verifactu_operaciones` y la siembra (INSERT IGNORE).
2. Anade `TIPO_OPER_VFACTU_FAC` a `fza_facturas`.
3. Recrea `vi_facturas` / `vi_facturas_normales` /
   `vi_facturas_simplificadas` (usan `SELECT fza_facturas.*`, que MariaDB
   expande al crear: hay que recrearlas para exponer la columna nueva al
   formulario). **Aplicar este script antes de desplegar el binario nuevo**
   (el envio hace JOIN al catalogo).

### Envio — `src/verifactu/inLibVerifactuEnvio.pas`

- La consulta hace `LEFT JOIN fza_paises` (ISO-2 y miembro UE del cliente)
  y `LEFT JOIN fza_verifactu_operaciones` (mapeo del tipo elegido).
- **Destinatario**: si el cliente es extranjero (pais distinto de ES/724)
  se identifica por `<IDOtro>` (CodigoPais + IDType + ID) en vez de
  `<NIF>`; IDType 02 = NIF-IVA (UE), 04 = documento del pais (resto). Se
  exige NIF-IVA no vacio, pero ya no los 9 caracteres del NIF espanol.
- **Desglose** (`ConstruirDesglose`), dirigido por el catalogo:
  - `ESREPERCUTE_IVA = N` -> un unico `DetalleDesglose` con la base total,
    sin tipo ni cuota, y `OperacionExenta` o `CalificacionOperacion` segun
    el catalogo.
  - `ESREPERCUTE_IVA = S` -> desglose por bandas (como antes) usando la
    `ClaveRegimen` y la `CalificacionOperacion` del catalogo (la banda
    exenta mantiene E1).
  - Sin tipo asignado: comportamiento interior de siempre; **salvo** que el
    cliente no sea de la UE, en cuyo caso se aplica exportacion (E2) de
    forma automatica.

### Formulario — `src/Forms/inMtoFacturasBase.pas` + `.dfm`

`TcxDBLookupComboBox` (`cbbTipoOperVerifactu`) en la pestana "Otros", ligado a
`TIPO_OPER_VFACTU_FAC`, que **muestra `DESCRIPCION_VFO` y guarda `CODIGO_VFO`**
(mismo patron que Forma de Pago / Paises). La lista sale del catalogo via un
`TUniQuery`/`TDataSource` nuevos en el datamodule (`unqryVerifactuOpe` /
`dsVerifactuOpe`, abiertos en `AbrirDetalles`, `ListSource` asignado en
`CrearTablaPrincipal`). Solo lista los tipos activos (`ESACTIVO_VFO = 'S'`),
asi que los tipos nuevos del catalogo aparecen solos sin recompilar.

### Guardado de la columna — `src/DataModules/UniDataFacturas.dfm`

El dataset de facturas tiene `SQLInsert`/`SQLUpdate` escritos a mano con la
lista de columnas fija. Una columna nueva se LEE (la consulta es `SELECT *`)
pero **no se graba** si no se anade tambien a esas sentencias. Se ha anadido
`TIPO_OPER_VFACTU_FAC` al INSERT (columnas + valores) y al UPDATE (SET).
Recordatorio para futuras columnas de `fza_facturas`: tocar tambien aqui.

### Validaciones BeforePost — `src/DataModules/UniDataFacturas.pas`

`unqryFacBeforePost` valida coherencia antes de grabar la cabecera (solo
mientras la factura es BORRADOR, para no interferir con el lanzamiento a
Verifactu). Bloquea (ShowMessage + raise) o avisa segun el caso:

- **Bloqueo**: tipo intracomunitario con cliente no UE; exportacion con
  cliente UE/nacional; operacion sin IVA repercutido pero la factura lleva
  IVA; cliente extranjero sin NIF-IVA; fecha de factura vacia; fecha
  anterior a la ultima factura emitida de la serie (orden cronologico).
- **Aviso** (deja grabar): fecha posterior a hoy; salto en la numeracion de
  la serie (la ley exige numeracion correlativa: el hueco debe cubrirse).

Helpers anadidos: `EsPaisUE`, `ObtenerOperVfactu` (lee ambito/repercute del
catalogo), `UltimaFechaSerie`, `HayHuecoNumeracion`, `ValidarOperacionVfactu`.
La coherencia usa la columna `AMBITO_VFO` del catalogo (NACIONAL / UE /
EXTRA_UE / CUALQUIERA).

## Limitaciones / avisos

- **Bienes usados (REBU)**: el IVA va sobre el **margen**, no sobre la base
  total, y eso rompe el invariante base+IVA=total del motor. Queda **inactivo**
  en el catalogo (`ESACTIVO_VFO = 'N'`, no aparece en el selector) hasta
  implementarlo. Diseno y base legal en `verifactu_rebu.md`.
- **Cliente no-UE = exportacion automatica**: una venta presencial a un
  turista no comunitario es realmente interior con IVA. Si se da el caso,
  marcar la factura como `INTERIOR` en el selector para anular el E2 auto.
- **IDType para no-UE**: se usa 04 (documento del pais). Revisar caso a caso
  si la AEAT espera otro tipo para alguna operacion concreta.

## Verificacion pendiente

1. Compilar (`fzam.dproj`) tras anadir los controles al form.
2. Aplicar el script en una BBDD de pruebas.
3. En preproduccion (`src/verifactu/entornopre`): enviar una factura de
   servicio intracomunitario a un profesional UE (con NIF-IVA) y confirmar
   que la AEAT acepta el IDOtro y la calificacion N2.
