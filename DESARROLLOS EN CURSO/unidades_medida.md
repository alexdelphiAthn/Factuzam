# Cantidades con decimales por unidad de medida

## Objetivo
Un cliente maneja telas por metros y quiere **decimales en las cantidades en
todo el programa** (entradas/compras, ventas, caja, inventarios, informes).
El numero de decimales **depende de la unidad de medida** del articulo
(Uds = 0, metros = 2, kilos = 3...), no es un valor global unico.

## Situacion de partida (analisis)
- La BBDD ya guarda casi todas las cantidades como `DECIMAL(19,6)` y el codigo
  Delphi ya las lee como `Double` / `AsFloat` / `TBCDField`. **El dato decimal
  ya se almacena y se calcula bien hoy.** No es un problema de esquema.
- El problema es de **presentacion/entrada**: spin-edits y columnas de grid sin
  decimales, algun `DisplayFormat` entero, y tickets/informes que imprimen la
  cantidad sin decimales (`FloatToStr`).
- **No existia catalogo de unidades**: `TIPO_CANTIDAD_ART` (y los
  `TIPO_CANTIDAD_*` de las lineas) eran texto libre (`TcxDBTextEdit`).
- Excepciones que **no** son cantidad de producto y no se tocan:
  `CANTIDAD_VENTAS_ARQ` / `CANTIDAD_OPERACIONES_ARQ` (contadores `int` de
  arqueo de caja).

## Diseno de la tabla `fza_unidades_medida` (sufijo `UNIMED`)
Ver `unidades_medida.sql`. Columnas clave:
- `DECIMALES_UNIMED` (def 2): decimales a mostrar/teclear.
- `MAGNITUD_UNIMED` + `ESBASE_UNIMED` + `FACTOR_BASE_UNIMED`: conversion a la
  unidad estandar de cada magnitud (`valor_base = valor * FACTOR_BASE`).
  Ej.: cm/mm -> metros, g -> kilos, ml -> litros.

Pendiente de registrar (libro de estilo): sufijo `UNIMED` en
`LIBRO_DE_ESTILO_BBDD.md` §2 y en `UNormalizerEngine.pas -> InitDefaults`.

## Plan por fases
- [x] **Fase 1 - Esquema**: `unidades_medida.sql` idempotente (tabla + semilla
      + alta automatica de las unidades de texto libre existentes).
- [x] **Fase 2 - Maestro**: `UniDataUnidadesMedida` + form `inMtoUnidadesMedida`
      (hereda `TfrmMtoGen`) + entrada en menu (`inMtoPrincipal`, bajo Articulos),
      alta en `fzam.dpr`, registro en `fza_winforms` + permiso de menu, y sufijo
      `UNIMED` registrado en `LIBRO_DE_ESTILO_BBDD.md` y `UNormalizerEngine.pas`.
      Ademas, los articulos nuevos arrancan en `Uds` (0 decimales) por defecto.
- [ ] **Fase 3 - Helper** `inLibUnidadesMedida.pas`: cache unidad->(decimales,
      magnitud, factor); `DecimalesDeUnidad`, `FormatearCantidad`,
      `MascaraCantidad`, `ConvertirEntreUnidades`. Carga al arrancar.
- [x] **Fase 4 - Articulo**: "Tipo de Cantidad" pasa de texto libre a
      desplegable (`TcxDBLookupComboBox cbbTipoCantidad`) contra
      `fza_unidades_medida`. Lookup `unqryUnidadesMedidaLookup` +
      `dsUnidadesMedidaLookup` en `UniDataArticulos`, ListSource asignado en
      `CrearTablaPrincipal`. Pendiente (Fase 5): columnas "Tipo Cantidad" de
      las lineas de documento (hoy se autorrellenan desde el articulo).
- [ ] **Fase 5 - Documentos**: formato decimal por fila (via
      `OnGetCellProperties` segun la unidad de la linea) y spin-edits a float
      en facturas, caja, albaranes (venta/compra), pedidos (venta/compra),
      traspasos, inventarios, compras-sesiones.
- [ ] **Fase 6 - Tickets/informes/Excel**: sustituir formato entero/`FloatToStr`
      por `FormatearCantidad(valor, unidad)` en `inLibGenerarTicket(BD)`,
      `inLibFacturaExcel`, `inLibDocCompraExcel`, `inLibInventarioExcel`,
      balances y `.fr3`.
- [ ] **Fase 7 - Cierre**: pump de version en `inLibGlobalVar.pas` y compilar.
