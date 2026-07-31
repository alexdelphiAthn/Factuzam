# Fase 3, fascículo 2 — consolidación y archivado PDF

Fecha: 31/07/2026. Sin commit.

**Estado de la tanda: IMPLEMENTADA Y CARACTERIZADA.** En un punto estable
del árbol compartido, `fzam` y `FactuzamTests` compilaron en Release Win32
y Win64 y las cuatro pruebas nuevas pasaron en ambas plataformas. La
repetición final queda bloqueada por separaciones ISP concurrentes aún
incompletas, ajenas a esta costura.

Esta cuarta costura cierra el fascículo de `inMtoFacturasBase`. La
validación y la transacción continúan en
`IServicioConsolidacionFactura`; el formulario conserva únicamente la
selección, los diálogos, la composición de servicios y el refresco.

## 1. Presentación previa

La nueva unidad
`src\Lib\inLibFacturasConsolidacionPresentacion.pas` aporta:

- `TPreparacionConsolidacionFactura`;
- `PrepararConsolidacionFactura`, que transforma el resultado del servicio
  en mensaje de error o pregunta de confirmación.

La función es pura, no usa BBDD, VCL, UniDAC ni unidades `UniData*`.

## 2. Archivado PDF

El método `GenerarPdfFacturaConsolidada` sale del mantenimiento. La
responsabilidad pasa a
`TfrmPrintFac.ArchivarFacturaConsolidada`, dentro de
`inMtoModalImpFac`, porque ese modal ya posee:

- la carga del formato predeterminado;
- `ExportarPdfActual`;
- el hook `PdfExportado` que guarda el blob y sus metadatos.

Se conserva el comportamiento anterior: nombre temporal con instante,
borrado del fichero tras exportar y error recuperable registrado sin
invalidar una consolidación fiscal ya completada.

## 3. Medición

| Objetivo | Antes | Árbol compartido actual | Variación |
|---|---:|---:|---:|
| `TfrmMtoFacturasBase` — líneas | 3.853 | **1.965** | −1.888 |
| `TfrmMtoFacturasBase` — métodos | 127 | **115** | −12 |

La variación compartida incluye esta tanda y extracciones concurrentes
de edición de líneas y coordinación del formulario. Esta tanda elimina
específicamente `GenerarPdfFacturaConsolidada`; no se atribuyen aquí como
propias las reducciones concurrentes.

Acumulado del fascículo 2: 4.008/133 → **1.965/115**, una reducción
conjunta de 2.043 líneas y 18 métodos. El trinquete queda congelado en
1.965/115; se alcanzan los objetivos ≤2.000/≤120.

## 4. Pruebas

`tests\PruebasFacturasConsolidacionPresentacion.pas` añade cuatro casos
sin BBDD:

- una validación correcta permite confirmar;
- la pregunta identifica serie y número;
- una validación fallida conserva el mensaje;
- una validación fallida no genera pregunta.

Resultado en Release Win32 y Win64:

```text
Tests Found   : 488
Tests Passed  : 488
Tests Failed  : 0
Tests Errored : 0
Tests Leaked  : 0
```

Los cuatro casos nuevos pasan. La tanda concurrente actualizó también
las tres expectativas conocidas del catálogo SQL, por lo que la batería
completa queda verde.

## 5. Compilación y trinquetes

- `FactuzamTests` Release Win32 y Win64: último punto estable compilado y
  ejecutado;
- `fzam` Release Win32 y Win64: último punto estable compilado;
- Win64 se generó en una salida aislada para evitar colisiones con otras
  compilaciones concurrentes;
- la repetición Release Win32 sobre el árbol final no llega a esta tanda:
  las pruebas se detienen en referencias pendientes a `FServicio` dentro
  de `inLibGestorPerfilesMto` y la aplicación en una referencia pendiente
  a `FPerfilesUsuario` dentro de `inLibParametrosBase`, ambas pertenecientes
  a la separación ISP concurrente;
- se retiraron dos residuos de la extracción concurrente de columnas:
  una referencia local sin consumidor y el wrapper sin usos
  `PorcentajeIvaFactura`.

Trinquetes:

- dependencias de capa: 520 unidades, ciclo mayor 1 y 0 usos
  `inLib*` → `UniData*`;
- SQL de dominio: 158 sentencias en 53 unidades, dentro del tope;
- SQL, transacciones y eventos críticos: correcto tras adaptar la
  identificación del evento a `TControladorFacturas`;
- la clase de facturas cumple su trinquete en 1.965/115; el control
  global de tamaño se detiene primero en `TfrmMtoOpeCaja`, con 4.187
  líneas y 111 métodos frente a los topes 4.060/104, y el árbol
  concurrente mantiene además unidades procedurales sobre sus topes;
- acoplamiento: `inLibLog` mantiene el fallo concurrente 85>84; esta tanda
  no añade consumidores;
- flujos largos: continúa sin encontrar una implementación única de
  `GuardarRegistroNoVerifactu`.

Para desbloquear las compilaciones del árbol compartido se completaron
también tres altas mecánicas de tandas concurrentes:

- registro de `inLibFacturasColumnasPresentacion` en `fzam`;
- imports DevExpress que necesitaba esa unidad;
- import del contrato `inLibHojaCalculoIntf` en
  `inMtoModalImpMovVentasArt`.

## 6. Ficheros de la tanda

Nuevos:

- `src\Lib\inLibFacturasConsolidacionPresentacion.pas`;
- `tests\PruebasFacturasConsolidacionPresentacion.pas`;
- este informe.

Modificados:

- `src\Forms\inMtoFacturasBase.pas`;
- `src\Modals\inMtoModalImpFac.pas`;
- `fzam.dpr` y `fzam.dproj`;
- `tests\FactuzamTests.dpr` y `tests\FactuzamTests.dproj`;
- `scripts\comprobar_tamano_clases.ps1`;
- `scripts\comprobar_sql_transacciones.ps1`;
- `DESARROLLOS EN CURSO\facturas_pdf_blob.md`;
- `PLAN_SOLID.md`.

Los ficheros compartidos se editaron sobre el contenido vigente,
preservando las tandas concurrentes.

## 7. Siguiente corte sugerido

`inMtoCajaOpe`, `inMtoArticulos` e `inMtoStockConsulta` ya tienen
fascículos concurrentes en curso. El siguiente foco libre del orden de
Fase 3 es `inMtoInventarios`: resolución de entradas y líneas de stock.
