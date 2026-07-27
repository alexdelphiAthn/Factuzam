# Fase 3 — Bloque B2: registro de pantallas por clase (resultados)

Fecha: 27/07/2026. **Compilado Release/Win64: 0 errores** (307.590
líneas, 16,1 s), sin warnings nuevos. Ficheros: 3 nuevos + 8 tocados.

## Qué se ha hecho

### 1. Muere el RTTI-por-cadena: registro de clases

- **`inLibRegistroPantallas`** (nueva): diccionarios nombre cualificado →
  clase, para formularios y data modules. La clave se calcula con
  `QualifiedClassName`, así que en el código no hay ni una cadena que
  pueda divergir del identificador real.
- **`inMtoCatalogoPantallas`** (nueva, Core): registra las **52 clases de
  formulario y 48 de data module** que `fza_winforms` puede abrir. Un
  typo aquí **no compila** (antes, un typo en la BBDD reventaba en
  runtime con "Clase no encontrada en rtti").
- `ShowMto` resuelve con `ClasePantalla(...)` y `CrearDataModule` con
  `ClaseDataModule(...).Create(...)` — fuera `TRttiContext.FindType` y
  fuera el `NewInstance` + `Create` sobre instancia ya construida.
- **Validación en el arranque**: `TfzaWinF.ComprobarRegistradas` recorre
  `fza_winforms` tras `Charge` y deja un error en el log por cada
  pantalla o DM sin clase registrada. Ya tiene su primer cliente: la
  fila **`ArticulosPropiedades` apunta a
  `inMtoArticulosPropiedades.TfrmMtoArticulosPropiedades`, que NO existe
  en el código** (verificado contra las 625 unidades del árbol real).
  Hoy, quien abra ese menú recibe un error críptico; desde ahora el log
  de arranque lo canta. Conviene borrar la fila o esconder su menú.

### 2. Identidad de ventana por clave, no por caption

`TEmbeddedFormManager` mantiene un diccionario clave→form
(`CALL#instancia`, p. ej. `Clientes#2`) y `ShowMto` localiza instancias
con `FormPorClave`. El caption queda como texto visible de la pestaña:
cambiarlo o traducirlo ya no rompe la detección de ventanas abiertas ni
el truco de la instancia 1 reservada a búsquedas. (`CloseFormByCaption`
sigue existiendo para el cierre por pestaña del principal.)

### 3. Las librerías del marco ya no conocen a los formularios

- **`inLibVentanaEmbebidaIntf`** (nueva): `IVentanaEmbebida`
  (`InterceptarCierre`: la primera X desde la ficha vuelve a la lista) e
  `IMantenimientoEmbebido` (modo búsqueda, `PrepararBusquedaExterna`,
  `AbrirTablaPrincipal` síncrono/asíncrono, `LocalizarYEnfocar`).
  `TfrmMtoGen` las implementa.
- `IAnfitrionPantallas` (en `inLibShowMto`): `TfrmMtoPrincipal` publica
  su gestor de ventanas, el registro `fza_winforms` y la preparación de
  apertura (restaurar ventana, minimizar caja).
- `inLibFormManager` **ya no usa `inMtoGen`** e `inLibShowMto` **ya no
  usa ni `inMtoGen` ni `inMtoPrincipal`**. El cableado DM↔form que
  `CrearDataModule` hacía hurgando en el form (FCurrentForm, dsTablaG,
  SQL de perfil) vive ahora en `TfrmMtoGen.CrearTablaPrincipal`.
- `BuscarTabla` (locate genérico por clave primaria) se muda de
  `inLibShowMto` a `inLibData`. `ResolverCallFactura` se queda en
  `inLibShowMto`: ya era una función suelta sin dependencia de
  formularios y moverla habría tocado 7 unidades más sin ganancia.

## Resultado medido

| Métrica | Antes de B2 | Ahora |
|---|---|---|
| Infracciones `inLib*`/`UniData*` → `inMto*` | 10 | **7** |
| `inLibShowMto` / `inLibFormManager` en ciclos | sí (núcleo) | **no** |
| Resolución de pantallas | RTTI por texto de BBDD | registro compilado |
| Error de configuración | diálogo críptico al abrir | log al arrancar |

Las 7 infracciones restantes: las dos de tickets (`inMtoPreviewTicket`,
dependencia viva restaurada en B1), `inLibGenBusq` e `inLibDefaultValues`
→ `inMtoGenSearch`, `inLibColumnasSkuModoTallas`, `inLibLayoutForm` e
`inLibArticulosPropiedades` → modales. Todas son de la familia B4
(mover/partir los modales y el buscador), ya sin el núcleo de por medio.

El ciclo grande que queda (14 unidades) es ya **entre formularios**
(Principal↔Gen↔GenSearch↔modales, más `inLibGenBusq` e
`inLibDocumentosTrabajo` colgando de `inMtoGenSearch`): territorio B4.

## Errores que la compilación cazó (y su moraleja)

Una variable mía llamada `oF` chocó con la palabra reservada `of`
(Pascal no distingue mayúsculas) — 15 errores idénticos, un rename.
Antes, en B1, la misma pasada cazó el falso "uses muerto" de los
tickets. La secuencia editar→compilar→leer log funciona.

## Plan de pruebas en pantalla (B2 toca el arranque y TODA apertura)

1. **Arranque + log**: abrir el monitor SQL / log y comprobar que
   aparece exactamente UNA pareja de errores de registro (la fila
   muerta `ArticulosPropiedades`) y ninguna más.
2. **Abrir una a una las 52 pantallas del menú** (media hora): cada una
   debe abrir igual que antes. Esto no es muestreo: el riesgo de B2 es
   justo una pantalla que no quedara registrada.
3. **Multiinstancia**: abrir Clientes 2 veces (pestañas "Clientes 2" y
   "Clientes 3"), cerrar la 2, volver a abrir → reutiliza el hueco.
4. **Búsqueda cruzada (Ctrl+A / saltos entre pantallas)**: desde
   Verifactu/Albaranes saltar a una factura concreta → abre la
   instancia 1, filtra, localiza y pasa a la ficha; si el dato no
   existe, avisa. Cubre `PrepararBusquedaExterna` + `LocalizarYEnfocar`.
5. **Cierre desde la ficha**: X con la ficha activa → vuelve a la
   lista; segunda X → cierra (ahora vía `IVentanaEmbebida`).
6. **Menú oculto / permisos**: usuario restringido — las pantallas sin
   permiso siguen sin abrirse.
7. **Caja**: abrir el menú de caja y una pantalla de gestión después
   (la caja debe minimizarse, ahora vía `PrepararAperturaPantalla`).

Nota IDE: las 3 unidades nuevas están en el `.dpr` y compilan por
msbuild; el Project Manager del IDE no las listará hasta añadirlas al
`.dproj` (Add to project), sin efecto en el build.
