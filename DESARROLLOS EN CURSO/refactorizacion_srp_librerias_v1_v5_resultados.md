# V1-V5 — pivote de venta (resultados)

Fecha: 30/07/2026. Fascículos V1 a V5 implementados. Sin commit.
Compilación Win32/Win64 y DUnitX propios del módulo completados en
Windows. La certificación global y las seis pruebas funcionales siguen
pendientes por los otros procesos concurrentes; ver §Verificación.

## Resultado

`inLibGridPivoteVenta` deja de contener el modo completo. La clase
`TGridPivoteVenta` pasa de **2.971 líneas, 86 métodos y 49 campos** a un
coordinador de `IModoEntradaGrid` de **944 líneas, 40 métodos y 10
campos**, por debajo ya del objetivo final de §5.2 (1.500/45/25). El
modo queda repartido por responsabilidad:

| Unidad | Clase | Líneas | Métodos | Campos | Responsabilidad |
|---|---|---:|---:|---:|---|
| `inLibPivoteVentaCalculo` | procedural (13 rutinas, 208 líneas) | — | — | — | claves de grupo/celda, bandas, pendientes y rótulos (V1) |
| `inLibPivoteVentaIntf` | contratos (80 líneas) | — | — | — | puerto `IRepositorioPivoteVenta` y records (V2) |
| `UniDataPivoteVenta` | `TRepositorioPivoteVentaUniDAC` | 471 | 15 | 2 | adaptador UniDAC: 14 sentencias SQL (V2) |
| `inLibPivoteVentaModelo` | `TModeloPivoteVenta` | 727 | 31 | 15 | grupos, celdas, bandas, conjuntos, volcado (V3) |
| `inLibGridPivoteVentaVista` | `TVistaPivoteVenta` | 290 | 10 | 8 | `TClientDataSet` temporal y desvío del grid (V4) |
| `inLibGridPivoteVentaPresentacion` | `TPresentacionPivoteVenta` | 1.131 | 40 | 15 | columnas, dibujo, edición, foco, timer, eventos (V4) |
| `inLibGridPivoteVenta` | `TGridPivoteVenta` | 944 | 40 | 10 | fachada coordinadora de `IModoEntradaGrid` (V5) |

Todas las clases nuevas quedan dentro del límite de colaboradores de
§5.2 (≤ 1.200 líneas, ≤ 40 métodos y ≤ 20 campos) y ningún método nuevo
supera las 120 líneas.

La API pública se conserva: `CrearModoEntradaGridPivoteVenta`,
`TGridPivoteVentaConfig`, `TBandaPivoteVenta` (alias con sus constantes
`bpv*`), `IPivoteVentaAlbaranar` e `IPivoteVentaBorrarGrupo` siguen
saliendo de `inLibGridPivoteVenta`. `TGridPivoteVentaConfig` gana el
campo `Repositorio: IRepositorioPivoteVenta` y los seis formularios
consumidores lo componen con `CrearRepositorioPivoteVenta` (una
asignación y un `uses` por formulario; resto sin cambios).

La dependencia de `TGestorGridTallas` (`inLibGridTallasInline`)
desaparece del pivote de venta: las posiciones de conjuntos, reales o
virtuales, ahora las sirve el modelo con el puerto (los conjuntos
virtuales conservan el id negativo compartido por lista de tallas).

## Comportamiento fijado

`PruebasPivoteVenta` añade 27 casos DUnitX sin conexión, con el doble
`DoblesPivoteVenta` como repositorio en memoria:

- claves puras: agrupación artículo+color+precio, fila propia de las
  líneas sin talla, clave de celda reversible y líneas de vista por
  banda;
- pendiente base y visual nunca negativos y ajuste de "a albaranar" al
  rango [0..pendiente base], también al cargar valores excesivos;
- rótulos de banda (tres bandas frente a banda única, 'A recibir') y de
  tipo de cantidad, con conservación del tipo especial del grupo;
- tres líneas de vista por grupo frente a una en banda única, con banda
  y línea base correctas;
- cantidades por banda y correspondencia celda → SKU → línea real →
  almacén;
- línea sin talla en la primera posición de columnas;
- conjunto virtual cuando ningún conjunto real cubre las tallas: id
  negativo, compartido entre grupos con las mismas tallas, y tallas del
  grupo anexadas si el artículo no las aporta;
- grupo sin conjunto posible queda registrado para el aviso;
- marcar y limpiar "a albaranar" en caché y volcado a albaranar con
  almacén común/único;
- líneas reales del grupo para el borrado completo;
- máximo de columnas visibles capado al del host;
- suma de unidades del grupo para la columna Total de banda única;
- resolución de SKU por campo directo, código de barras (incluida la
  mejora de talla al escanear), artículo con SKU único y conservación
  del código visible cuando no hay resolución.

## SQL

- `inLibGridPivoteVenta`: **13 → 0 sentencias**. Objetivo de §5.2
  cumplido.
- `UniDataPivoteVenta`: 14 sentencias (las 13 del monolito más la
  lectura de posiciones de conjunto que el pivote tomaba de
  `inLibGridTallasInline`), todas con parámetros UniDAC; las únicas
  concatenaciones son listas `IN` de enteros generados por código.
- El buscador de artículos vive en el adaptador como operación
  `ElegirArticuloDesdeBusqueda` y usa el ejecutor registrado de
  `inLibGenBusq` (§14.4); el contrato no cruza `TDataSet` ni
  `TUniQuery`.
- Inventario del dominio: 328 → **315 sentencias** en este árbol. El
  tope de `comprobar_sql_en_dominio.ps1` baja de 331 a **318** (la
  reducción de este fascículo); el número de unidades con SQL queda en
  67 frente al tope 66 por trabajo concurrente ajeno (ver §Estado del
  árbol).

## Salida del trinquete previa a compilación

`.\scripts\comprobar_tamano_clases.ps1` (topes sustituidos por la
medida actual; ninguno al alza):

```text
TGridPivoteVenta
  ActualLineas=944   TopeAnteriorLineas=944   ObjetivoLineas=1500
  ActualMetodos=40   TopeAnteriorMetodos=40   ObjetivoMetodos=45
  ActualCampos=10    TopeAnteriorCampos=10    ObjetivoCampos=25
  EstadoObjetivo=ALCANZADO
TModeloPivoteVenta        727 / 31 / 15   (obj. 1200/40/20) ALCANZADO
TPresentacionPivoteVenta 1131 / 40 / 15   (obj. 1200/40/20) ALCANZADO
TVistaPivoteVenta         290 / 10 /  8   (obj. 1200/40/20) ALCANZADO
TRepositorioPivoteVentaUniDAC 471 / 15 / 2 (obj. 1200/40/20) ALCANZADO
inLibPivoteVentaCalculo   208 lineas / 13 rutinas  ALCANZADO
inLibPivoteVentaIntf       80 lineas /  0 rutinas  ALCANZADO
```

Las clases y unidades nuevas quedan vigiladas individualmente en
`LimitesClases` / `LimitesUnidades`.

## Consumidores (V5)

Cableado aplicado (un `uses` y la composición del repositorio):
`inMtoPedidos`, `inMtoFacturasBase`, `inMtoPedidosCompra`,
`inMtoAlbaranesCompra`, `inMtoFacturasCompra` e
`inMtoDevolucionesCompra`. Las pruebas funcionales mínimas de §8 del
anexo quedan pendientes de la compilación:

| Consumidor | Caso |
|---|---|
| `inMtoPedidos` | tres bandas, cantidades pendientes y a albaranar |
| `inMtoFacturasBase` | banda única y creación de línea SKU |
| `inMtoPedidosCompra` | rótulo a recibir y líneas reales |
| `inMtoAlbaranesCompra` | carga y edición del pivote |
| `inMtoFacturasCompra` | banda única de compra |
| `inMtoDevolucionesCompra` | signo, cantidad y borrado de grupo |

## Balance de código y plan de reducción

Las 7 unidades de producción suman **4.251 líneas físicas** frente a
las 3.100 de la unidad de partida: **+1.151 líneas** de contratos,
modelo, colaboradores y dobles de composición. Como en C1-C7, la subida
no se presenta como reducción; queda con plan medible:

1. **RV1 — campos de configuración muertos.** `Usuario`,
   `SourceMaster`, `FieldSerieMaster`, `FieldNumeroMaster`,
   `FieldDescripcion` y `FieldAlmacenMaster` de
   `TGridPivoteVentaConfig` ya no se usan (el usuario viaja por el
   repositorio y el gestor de tallas desapareció). Retirarlos exige
   tocar los seis consumidores: fascículo corto propio. Objetivo:
   -40 líneas.
2. **RV2 — helpers de dataset compartidos.** `CampoTexto`,
   `CampoFloat` y `PonerFloat` de la fachada duplican utilidades
   existentes; unificarlos en la librería de datasets. Objetivo:
   -50 líneas.
3. **RV3 — compactar comentarios históricos** ya contados en el plan
   general de reducción. Objetivo: -60 líneas.

## Paridad de comportamiento

El fascículo es de caracterización: se conserva el comportamiento del
monolito, incluidos estos puntos verificados expresamente:

- `OnResuelto` y `OnBandaCambiada` se almacenan y no se disparan desde
  la librería (los consumidores llaman a `PivoteVentaBandaCambiada` por
  su cuenta), igual que antes;
- el `AddOrSetValue` de celdas repetidas (misma talla en dos líneas del
  mismo grupo) conserva la semántica "la última gana" del monolito;
- los `Post`/`Edit` masivos de marcar/limpiar "a albaranar", la
  restauración de filtros y el enganche de `OnExit` del editor inplace
  reproducen el flujo original.

Tres blindajes menores sin cambio funcional: guarda de código de barras
vacío al completar talla en `ResolverInfoLinea`, guarda `ATallaAv > 0`
en el alta de atributos del adaptador y un comentario corregido en el
ajuste de "a albaranar".

## Estado del árbol (trabajo concurrente)

Al medir sobre este árbol hay desviaciones AJENAS al fascículo, ya
presentes antes de empezar: `TfrmMtoComprasSesiones` 3.660 > 3.659,
`TfrmStockConsulta` 3.141 > 3.139 y 67 unidades con SQL > 66.
`TfrmMtoFacturasBase` estaba en 4.003 > 4.000 y el cableado V5 añade
**+2 líneas** (4.005): esas dos líneas son de este fascículo y deben
descontarse cuando el fascículo concurrente rebaje el formulario. Los
topes correspondientes NO se han subido.

`comprobar_dependencias_capas`, `comprobar_flujos_largos`,
`comprobar_estado_global` y `comprobar_acoplamiento` se ejecutaron en
un entorno Linux donde sus exclusiones de ruta con `\` no aplican;
deben repetirse en Windows junto a la compilación.
`comprobar_sql_transacciones`: OK (115 literales fijos, 3
identificadores con lista blanca, 0 valores externos concatenados).
`comprobar_formularios_delgados` y `comprobar_supports`: OK.

## Verificación en Windows

RAD Studio 37.0 sí está instalado en el equipo de validación.

Verificación aislada de V1-V5, sin depender de las unidades que
modifican los otros tres procesos:

- las siete unidades de producción compilan en Win32 y Win64 con la
  configuración y las rutas de búsqueda del proyecto de pruebas;
- `PruebasPivoteVenta`: **27/27**, 0 ignoradas, 0 fugas, 0 fallos y
  0 errores en Win64;
- los topes propios permanecen exactos: `TGridPivoteVenta` 944/40/10,
  `TPresentacionPivoteVenta` 1.131/40/15 y `TVistaPivoteVenta`
  290/10/8;
- el log de vista y presentación vuelve a pasar por callbacks de la
  fachada. Así las extracciones no añaden dos consumidores de
  `inLibLog`: `comprobar_acoplamiento.ps1` queda en 84 y pasa.

La batería global llegó a compilar en Debug Win64 y ejecutó **348/348**
casos antes de los últimos cambios concurrentes. No se certifica como
resultado final del árbol porque la compilación global actual queda
bloqueada en un módulo ajeno: `UniDataComprasSesionesEstado` llama a
`UniDataComprasSesionesOperaciones.ValidarSesion`, identificador que el
proceso de Compras ha retirado. No se modifica ese módulo por indicación
expresa del usuario.

Pasada final de los nueve trinquetes en Windows:

- **OK (7/9):** estado global, SQL en dominio (304 sentencias/64
  unidades), acoplamiento, dependencias de capas, `Supports`,
  formularios delgados y SQL/transacciones;
- `comprobar_tamano_clases.ps1`: falla por
  `TfrmMtoComprasSesiones` 3.669 > 3.659; los límites de V1-V5 pasan;
- `comprobar_flujos_largos.ps1`: el proceso Verifactu ha movido
  `GuardarRegistroNoVerifactu` a
  `UniDataVerifactuColaRepositorio`, mientras el trinquete aún lo busca
  en `inLibVerifactuCola`. No se toca ese proceso.

Las pruebas funcionales de los seis consumidores de §8 permanecen
pendientes: necesitan el ejecutable global estable, inicio de sesión y
una BBDD de pruebas con documentos adecuados. No se han simulado ni se
han ejecutado contra una BBDD no identificada.
