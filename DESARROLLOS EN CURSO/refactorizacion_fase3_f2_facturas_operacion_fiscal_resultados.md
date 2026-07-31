# Fase 3, fascículo 2 — `inMtoFacturasBase`: operación fiscal

Fecha: 31/07/2026. Sin commit.

**Estado de la tanda: VALIDADA.** `fzam` y `FactuzamTests` compilan en
Release Win32 y Win64. Las seis pruebas nuevas pasan en ambas
plataformas.

Esta tercera costura del fascículo extrae la preparación de anulaciones y
subsanaciones fiscales. El formulario conserva la lectura del dataset,
los diálogos VCL, la creación del servicio, la emisión y el refresco.

## 1. Qué se ha extraído

La nueva unidad `src\Lib\inLibFacturasOperacionFiscal.pas` aporta:

- `TContextoOperacionFiscalFactura`, con los datos necesarios para decidir
  y emitir;
- `PrepararOperacionFiscalFactura`, una función pura que valida el
  borrador y compone las preguntas;
- `CrearSolicitudOperacionFiscalFactura`, que construye la solicitud del
  servicio fiscal sin depender del formulario.

`TfrmMtoFacturasBase.EjecutarOperacionFiscal` queda como coordinador de
interfaz y servicios. También desaparece el método intermediario
`EmitirFiscalmente`.

## 2. Reglas caracterizadas

- sin número se informa de que no hay borrador seleccionado;
- un borrador no consolidado no admite la operación;
- la confirmación incluye acción, serie y número;
- solo una anulación de factura simplificada pregunta si deben borrarse
  los movimientos;
- el resto de operaciones conserva el borrado de movimientos activado;
- la solicitud mantiene serie, número, usuario, operación, acción y
  decisión sobre movimientos.

Las comparaciones de tipo de factura y operación continúan siendo
insensibles a mayúsculas. La marca de consolidación conserva la
comparación literal con `'S'`.

## 3. Medición

| Objetivo | Antes de esta tanda | Después | Variación |
|---|---:|---:|---:|
| `TfrmMtoFacturasBase` — líneas | 3.860 | **3.853** | −7 |
| `TfrmMtoFacturasBase` — métodos | 128 | **127** | −1 |

Acumulado del fascículo 2: 4.008/133 → **3.853/127**, una reducción de
155 líneas y 6 métodos. El trinquete propio queda congelado en
3.853/127.

El comprobador global de tamaño continúa rojo por cambios ajenos:

- `TfrmMtoOpeCaja`: 4.321 con tope 4.060;
- `TfrmStockConsulta`: 3.141 con tope 3.139.

## 4. Pruebas

`tests\PruebasFacturasOperacionFiscal.pas` añade seis casos sin BBDD:

- selección vacía;
- borrador no consolidado;
- anulación simplificada;
- anulación normal;
- otra operación sobre factura simplificada;
- construcción íntegra de la solicitud.

Resultado en Release Win32 y Win64:

```text
Tests Found   : 481
Tests Passed  : 478
Tests Failed  : 3
Tests Errored : 0
Tests Leaked  : 0
```

Los seis casos nuevos pasan. Los tres fallos son las expectativas
conocidas del catálogo SQL: dos recuentos 120→123 y uno 7→10.

## 5. Compilación y trinquetes

- `FactuzamTests` Release Win32 y Win64: compilado y ejecutado;
- `fzam` Release Win32 y Win64: compilado;
- dependencias de capa: 514 unidades, ciclo mayor 1 y 0 usos
  `inLib*` → `UniData*`;
- SQL de dominio: 163 sentencias en 54 unidades, dentro del tope;
- SQL, transacciones y eventos críticos: correcto.

El ejecutable habitual de `fzam` Win64 estaba abierto durante la
validación. Para no interrumpir esa sesión, la compilación se hizo con
salida aislada en `build\validacion_fiscal_operacion`.

Dos trinquetes globales continúan rojos por cambios concurrentes:

- acoplamiento: `inLibLog` tiene fan-in 85 con tope 84;
- flujos largos: no encuentra una implementación única de
  `GuardarRegistroNoVerifactu`.

La nueva unidad no contiene SQL ni introduce referencias a `UniData*`.

## 6. Ficheros de la tanda

Nuevos:

- `src\Lib\inLibFacturasOperacionFiscal.pas`;
- `tests\PruebasFacturasOperacionFiscal.pas`;
- este informe.

Modificados:

- `src\Forms\inMtoFacturasBase.pas`;
- `fzam.dpr` y `fzam.dproj`;
- `tests\FactuzamTests.dpr` y `tests\FactuzamTests.dproj`;
- `scripts\comprobar_tamano_clases.ps1`;
- `PLAN_SOLID.md`.

Los ficheros compartidos se editaron sobre el contenido vigente,
preservando las tandas concurrentes.

## 7. Siguiente corte sugerido

La siguiente responsabilidad cohesionada es la consolidación del borrador:
validación, confirmación, coordinación de servicios y archivado PDF.
