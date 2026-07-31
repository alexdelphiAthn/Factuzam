# Fase 3, fascículo 2 — `inMtoFacturasBase`: bloqueo fiscal

Fecha: 31/07/2026. Sin commit.

**Estado de la tanda: VALIDADA.** `fzam` y `FactuzamTests` compilan en
Release Win32 y Win64. Las seis pruebas nuevas pasan en ambas
plataformas.

Esta segunda costura del fascículo extrae la política que decide cuándo
una factura se puede editar, consolidar e imprimir según su fase fiscal.
La lectura del dataset y el cableado de controles permanecen en el
formulario.

## 1. Qué se ha extraído

La nueva unidad
`src\Lib\inLibFacturasEstadoFiscalPresentacion.pas` aporta:

- `CrearConfiguracionEstadoFiscalFactura`, una función pura que recibe
  fase, marca de consolidación, modo fiscal, estado y vacío del dataset;
- `TConfiguracionEstadoFiscalFactura`, con las cinco decisiones
  resultantes;
- `TPresentacionEstadoFiscalFactura`, que aplica la configuración al
  datasource, grid de líneas y botones.

`TfrmMtoFacturasBase.ActualizarBloqueoEdicion` conserva únicamente:

1. las guardas de disponibilidad del data module y dataset;
2. la lectura de `FASE_FAC` y `ESCONSOLIDADA_FAC`;
3. la asignación de `ReadOnly` a la query de líneas;
4. el cableado de los controles con el presentador.

## 2. Reglas caracterizadas

| Contexto | Editable | Consolidar | Imprimir |
|---|---:|---:|---:|
| borrador pendiente con filas | sí | sí | no |
| borrador ya consolidado | no | no | sí |
| fase `SIN_VERIFACTU`, modo SIN | sí | no | sí |
| fase terminal | no | no | sí |
| alta `dsInsert` | sí | no se actualizan botones | no se actualizan botones |
| dataset vacío en modo SIN | sí | no | no |

Se conserva el comportamiento anterior, incluido `SameText` para las
fases y la comparación literal con `'S'` para la marca de
consolidación.

## 3. Medición

| Objetivo | Antes de esta tanda | Después | Variación |
|---|---:|---:|---:|
| `TfrmMtoFacturasBase` — líneas | 3.883 | **3.860** | −23 |
| `TfrmMtoFacturasBase` — métodos | 128 | **128** | 0 |

Acumulado del fascículo 2: 4.008/133 → **3.860/128**, una reducción de
148 líneas y 5 métodos. El trinquete propio queda congelado en
3.860/128.

El comprobador global de tamaño continúa rojo por cambios ajenos:

- `TfrmMtoOpeCaja`: 4.321 con tope 4.060;
- `TfrmStockConsulta`: 3.141 con tope 3.139.

## 4. Pruebas

`tests\PruebasFacturasEstadoFiscalPresentacion.pas` añade seis casos sin
BBDD para:

- borrador editable y consolidable;
- borrador consolidado;
- modo sin Verifactu;
- fase terminal;
- inserción;
- dataset vacío.

Resultado en Release Win32 y Win64:

```text
Tests Found   : 439
Tests Passed  : 436
Tests Failed  : 3
Tests Errored : 0
Tests Leaked  : 0
```

Los seis casos nuevos pasan. Los tres fallos son las expectativas
conocidas del catálogo SQL: dos recuentos 120→123 y uno 7→10.

## 5. Compilación y trinquetes

- `FactuzamTests` Release Win32 y Win64: compilado y ejecutado;
- `fzam` Release Win32 y Win64: compilado;
- dependencias de capa: 505 unidades, ciclo mayor 1 y 0 usos
  `inLib*` → `UniData*`;
- SQL de dominio: 176 sentencias en 56 unidades, dentro del tope;
- SQL, transacciones y eventos críticos: correcto.

Durante la primera pasada Win64 apareció una unidad concurrente,
`inLibMsgTickets.pas`, ya referenciada por producción pero aún ausente
del proyecto. Se añadió únicamente su registro a `fzam.dpr` y
`fzam.dproj`, sin modificar la unidad. El descenso global de SQL
procede también de una tanda concurrente y no se atribuye a este
colaborador, que no contiene SQL.

## 6. Ficheros de la tanda

Nuevos:

- `src\Lib\inLibFacturasEstadoFiscalPresentacion.pas`;
- `tests\PruebasFacturasEstadoFiscalPresentacion.pas`;
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

La siguiente responsabilidad fiscal todavía alojada en el formulario
es `EjecutarOperacionFiscal`: selección, confirmación de
anulación/subsanación, decisión sobre movimientos y presentación del
resultado. Después queda el pegamento de consolidación y archivado PDF.
