unit UniDataConsultaOpe;

// =============================================================================
//  Módulo de datos para la consulta de operaciones de caja (F10 Buscar/Modificar).
//
//  Expone 7 queries (1 maestro + 7 para pestañas) que se refrescan al
//  cambiar la fila del maestro. TODO ES SÓLO LECTURA.
//
//  El filtrado del maestro es por:
//    - Fecha + empresa/almacén/caja (contexto fijo heredado del menú)
//    - Texto libre (número operación, nº factura, cliente, concepto,
//                   descripción/código/SKU de artículos en líneas de factura)
//
//  NOTA sobre qryPagos:
//    La pestaña "Pagos" ahora muestra también los vales de la operación.
//    Se construye como UNION de dos conjuntos:
//
//    (A) Líneas de fza_caja_pagos, con LEFT JOIN a fza_caja_vales para los
//        pagos de tipo VALE (cruce por REFERENCIA_PAGO = CODIGO_VL si viene
//        informada; fallback por empresa+almacén+caja+operación+importe).
//
//    (B) Vales EMITIDOS en esta operación (típicamente vale de cambio) que
//        no tienen línea de pago asociada — aparecen como fila "sólo vale".
//
//    Así cada línea de pago sale una vez y cada vale sale una vez, sin
//    duplicar ni perder información.
// =============================================================================

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, MemDS, DBAccess, vcl.dialogs;

type
  TdmConsultaOpe = class(TDataModule)
    qryMaestro:      TUniQuery;
    qryOperacion:    TUniQuery;
    qryPagos:        TUniQuery;
    qryMovimientos:  TUniQuery;
    qryCliente:      TUniQuery;
    qryDepositos:    TUniQuery;
    qryFactura:      TUniQuery;
    qryFacturaLin:   TUniQuery;
    dsMaestro:       TDataSource;
    dsOperacion:     TDataSource;
    dsPagos:         TDataSource;
    dsMovimientos:   TDataSource;
    dsCliente:       TDataSource;
    dsDepositos:     TDataSource;
    dsFactura:       TDataSource;
    dsFacturaLin:    TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    FCargando: Boolean;
  public
    procedure CargarMaestro(AFecha:     TDate;
                            const AEmp,
                                  AAlm,
                                  ACaja,
                                  ATextoLibre: string);
    procedure RefrescarPestanasHijas;
    function  TienePagos:       Boolean;
    function  TieneMovimientos: Boolean;
    function  TieneCliente:     Boolean;
    function  TieneDepositos:   Boolean;
    function  TieneFactura:     Boolean;
  private
    procedure AbrirSeguro(q: TUniQuery; const sNombre: string);
  end;

var
  dmConsultaOpe: TdmConsultaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibGlobalVar;

{$R *.dfm}

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.DataModuleCreate(Sender: TObject);
begin
  qryMaestro.Connection     := oConn;
  qryOperacion.Connection   := oConn;
  qryPagos.Connection       := oConn;
  qryMovimientos.Connection := oConn;
  qryCliente.Connection     := oConn;
  qryDepositos.Connection   := oConn;
  qryFactura.Connection     := oConn;
  qryFacturaLin.Connection  := oConn;

  // ------------------------------------------------------------------
  //  Grid MAESTRO: una fila por NUMERO_OPERACION_OPCAJA del día.
  //  Agrupa los distintos tipos de operación (VENTA, DEV, CB, ...) de
  //  una misma numeración en una sola fila visible.
  // ------------------------------------------------------------------
  qryMaestro.SQL.Text :=
    'SELECT o.CODIGO_EMPRESA_OPCAJA, '                                    +
    '       o.CODIGO_ALMACEN_OPCAJA, '                                    +
    '       o.CODIGO_CAJA_OPCAJA, '                                       +
    '       o.NUMERO_OPERACION_OPCAJA, '                                  +
    '       MIN(o.FECHA_OPERACION_OPCAJA)            AS FECHA_OP, '       +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA '               +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA '               +
    '                    SEPARATOR '','')            AS TIPOS_OP, '       +
    '       GROUP_CONCAT(DISTINCT NULLIF(o.CONCEPTO_GASTO_INGRESO_OPCAJA,'''') ' +
    '                    SEPARATOR '' | '')          AS CONCEPTOS, '      +
    '       SUM(o.IMPORTE_TOTAL_OPCAJA)              AS IMPORTE_TOTAL, '  +
    '       MAX(f.SERIE_FACTURA)                     AS SERIE_FACTURA, '  +
    '       MAX(f.NRO_FACTURA)                       AS NRO_FACTURA, '    +
    '       MAX(COALESCE(f.CODIGO_CLIENTE_FACTURA, c.CODIGO_CLIENTE_OPCAJA)) ' +
    '                                                AS CLIENTE, '        +
    '       MAX(cli.RAZONSOCIAL_CLIENTE)             AS RAZON_SOCIAL_CLI,'+
    '       MAX(o.USUARIOALTA)                       AS EMPLEADO '        +
    '  FROM fza_caja_operaciones o '                                      +
    '  LEFT JOIN fza_facturas f '                                         +
    '    ON f.CODIGO_EMPRESA_FACTURA   = o.CODIGO_EMPRESA_OPCAJA '        +
    '   AND f.CODIGO_ALMACEN_FACTURA   = o.CODIGO_ALMACEN_OPCAJA '        +
    '   AND f.CODIGO_CAJA_FACTURA      = o.CODIGO_CAJA_OPCAJA '           +
    '   AND f.NUMERO_OPERACION_FACTURA = o.NUMERO_OPERACION_OPCAJA '      +
    '  LEFT JOIN fza_caja_operaciones c '                                 +
    '    ON c.CODIGO_EMPRESA_OPCAJA   = o.CODIGO_EMPRESA_OPCAJA '         +
    '   AND c.CODIGO_ALMACEN_OPCAJA   = o.CODIGO_ALMACEN_OPCAJA '         +
    '   AND c.CODIGO_CAJA_OPCAJA      = o.CODIGO_CAJA_OPCAJA '            +
    '   AND c.NUMERO_OPERACION_OPCAJA = o.NUMERO_OPERACION_OPCAJA '       +
    '   AND c.CODIGO_CLIENTE_OPCAJA IS NOT NULL '                         +
    '   AND c.CODIGO_CLIENTE_OPCAJA <> '''' '                             +
    '  LEFT JOIN fza_clientes cli '                                       +
    '    ON cli.CODIGO_CLIENTE = COALESCE(f.CODIGO_CLIENTE_FACTURA, '     +
    '                                     c.CODIGO_CLIENTE_OPCAJA) '      +
    ' WHERE DATE(o.FECHA_OPERACION_OPCAJA) = :PFECHA '                    +
    '   AND o.CODIGO_EMPRESA_OPCAJA = :PEMP '                             +
    '   AND o.CODIGO_ALMACEN_OPCAJA = :PALM '                             +
    '   AND o.CODIGO_CAJA_OPCAJA    = :PCAJA '                            +
    '   AND ( :PTXT = '''' '                                              +
    '         OR o.NUMERO_OPERACION_OPCAJA LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR f.NRO_FACTURA           LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR cli.RAZONSOCIAL_CLIENTE LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR o.CONCEPTO_GASTO_INGRESO_OPCAJA LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR EXISTS ( '                                                +
    '               SELECT 1 FROM fza_facturas_lineas l '                  +
    '                WHERE l.CODIGO_EMPRESA_FACTURA_LINEA   = o.CODIGO_EMPRESA_OPCAJA ' +
    '                  AND l.CODIGO_ALMACEN_FACTURA_LINEA   = o.CODIGO_ALMACEN_OPCAJA ' +
    '                  AND l.CODIGO_CAJA_FACTURA_LINEA      = o.CODIGO_CAJA_OPCAJA ' +
    '                  AND l.NUMERO_OPERACION_FACTURA_LINEA = o.NUMERO_OPERACION_OPCAJA ' +
    '                  AND ( l.DESCRIPCION_ARTICULO_FACTURA_LINEA LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '                     OR l.CODIGO_ARTICULO_FACTURA_LINEA      LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '                     OR l.CODIGO_UNIDAD_FACTURA_LINEA        LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '                      ) '                                             +
    '                   ) '                                                +
    '       ) '                                                           +
    ' GROUP BY o.CODIGO_EMPRESA_OPCAJA, '                                 +
    '          o.CODIGO_ALMACEN_OPCAJA, '                                 +
    '          o.CODIGO_CAJA_OPCAJA, '                                    +
    '          o.NUMERO_OPERACION_OPCAJA '                                +
    ' ORDER BY FECHA_OP DESC ';

  // ------------------------------------------------------------------
  //  Pestaña OPERACIÓN: filas crudas de fza_caja_operaciones.
  //  Una misma numeración puede tener varias filas (VENTA + DEV + CB).
  // ------------------------------------------------------------------
  qryOperacion.SQL.Text :=
    'SELECT FECHA_OPERACION_OPCAJA, '                                     +
    '       TIPO_OPERACION_OPCAJA, '                                      +
    '       IMPORTE_TOTAL_OPCAJA, '                                       +
    '       CONCEPTO_GASTO_INGRESO_OPCAJA, '                              +
    '       ID_DEPOSITO_OPCAJA, '                                         +
    '       SERIE_REF_ORIGEN_OPCAJA, '                                    +
    '       NUMERO_REF_ORIGEN_OPCAJA, '                                   +
    '       MOTIVO_DEVOLUCION_OPCAJA, '                                   +
    '       ESTADO_DEVOLUCION_OPCAJA '                                    +
    '  FROM fza_caja_operaciones '                                        +
    ' WHERE CODIGO_EMPRESA_OPCAJA   = :PEMP '                             +
    '   AND CODIGO_ALMACEN_OPCAJA   = :PALM '                             +
    '   AND CODIGO_CAJA_OPCAJA      = :PCAJA '                            +
    '   AND NUMERO_OPERACION_OPCAJA = :PNUMOP '                           +
    ' ORDER BY FECHA_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA ';

  // ------------------------------------------------------------------
  //  Pestaña PAGOS (ampliada): líneas de pago + vales emitidos/redimidos.
  //
  //  Bloque A -> líneas de fza_caja_pagos con LEFT JOIN a fza_caja_vales
  //              cuando el pago es de tipo VALE (redención).
  //  Bloque B -> vales EMITIDOS en esta operación que no tienen línea
  //              de pago propia (típicamente vale de cambio).
  //
  //  El cruce del bloque A sobre vales usa:
  //    - REFERENCIA_PAGO = CODIGO_VL  (cruce exacto, convención nueva)
  //    - fallback: mismo empresa+almacén+caja+operación de redención +
  //                IMPORTE_REDIMIDO_VL = IMPORTE_ENTREGADO_PAGO
  //
  //  Si no existe aún la columna fza_caja_formas_pago.NOMBRE_FORMAP,
  //  ajustar el SELECT devolviendo NULL para DESCRIPCION_FORMAP.
  // ------------------------------------------------------------------
  qryPagos.SQL.Text :=
    '(SELECT p.NUMERO_LINEA_PAGO, '                                       +
    '        p.CODIGO_FORMAP, '                                           +
    '        fp.DESCRIPCION_FORMAP      AS DESCRIPCION_FORMAP, '          +
    '        p.IMPORTE_ENTREGADO_PAGO, '                                  +
    '        p.IMPORTE_CAMBIO_PAGO, '                                     +
    '        (p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO) '         +
    '                                   AS IMPORTE_NETO_PAGO, '           +
    '        p.CODIGO_DIVISA_PAGO, '                                      +
    '        p.RED_BLOCKCHAIN, '                                          +
    '        p.FACTOR_CAMBIO_PAGO, '                                      +
    '        p.IMPORTE_DIVISA_PAGO, '                                     +
    '        p.REFERENCIA_PAGO, '                                         +
    '        p.OBSERVACIONES_PAGO, '                                      +
    '        v.CODIGO_VL, '                                               +
    '        v.CODIGO_PADRE_VL, '                                         +
    '        v.PIN_SEGURIDAD_VL, '                                        +
    '        v.ESTADO_VL, '                                               +
    '        v.IMPORTE_NOMINAL_VL, '                                      +
    '        v.IMPORTE_REDIMIDO_VL, '                                     +
    '        v.FECHA_EMISION_VL, '                                        +
    '        v.FECHA_CADUCIDAD_VL, '                                      +
    '        v.FECHA_REDENCION_VL, '                                      +
    '        v.OBSERVACIONES_VL, '                                        +
    '        CASE WHEN v.CODIGO_VL IS NOT NULL THEN ''RED'' END '         +
    '                                   AS ROL_VL '                       +
    '   FROM fza_caja_pagos p '                                           +
    '   LEFT JOIN fza_caja_formas_pago fp '                               +
    '     ON fp.CODIGO_FORMAP = p.CODIGO_FORMAP '                         +
    '   LEFT JOIN fza_caja_vales v '                                      +
    '     ON p.CODIGO_FORMAP = ''VALE'' '                                 +
    '    AND v.CODIGO_EMPRESA_RED_VL   = p.CODIGO_EMPRESA_PAGO '          +
    '    AND v.CODIGO_ALMACEN_RED_VL   = p.CODIGO_ALMACEN_PAGO '          +
    '    AND v.CODIGO_CAJA_RED_VL      = p.CODIGO_CAJA_PAGO '             +
    '    AND v.NUMERO_OPERACION_RED_VL = p.NUMERO_OPERACION_PAGO '        +
    '    AND ( v.CODIGO_VL = p.REFERENCIA_PAGO '                          +
    '          OR ( COALESCE(p.REFERENCIA_PAGO,'''') = '''' '             +
    '               AND v.IMPORTE_REDIMIDO_VL = p.IMPORTE_ENTREGADO_PAGO ' +
    '             ) '                                                     +
    '        ) '                                                          +
    '  WHERE p.CODIGO_EMPRESA_PAGO   = :PEMP '                            +
    '    AND p.CODIGO_ALMACEN_PAGO   = :PALM '                            +
    '    AND p.CODIGO_CAJA_PAGO      = :PCAJA '                           +
    '    AND p.NUMERO_OPERACION_PAGO = :PNUMOP ) '                        +
    'UNION ALL '                                                          +
    '(SELECT NULL AS NUMERO_LINEA_PAGO, '                                 +
    '        NULL AS CODIGO_FORMAP, '                                     +
    '        NULL AS DESCRIPCION_FORMAP, '                                +
    '        NULL AS IMPORTE_ENTREGADO_PAGO, '                            +
    '        NULL AS IMPORTE_CAMBIO_PAGO, '                               +
    '        NULL AS IMPORTE_NETO_PAGO, '                                 +
    '        NULL AS CODIGO_DIVISA_PAGO, '                                +
    '        NULL AS RED_BLOCKCHAIN, '                                    +
    '        NULL AS FACTOR_CAMBIO_PAGO, '                                +
    '        NULL AS IMPORTE_DIVISA_PAGO, '                               +
    '        NULL AS REFERENCIA_PAGO, '                                   +
    '        NULL AS OBSERVACIONES_PAGO, '                                +
    '        v.CODIGO_VL, '                                               +
    '        v.CODIGO_PADRE_VL, '                                         +
    '        v.PIN_SEGURIDAD_VL, '                                        +
    '        v.ESTADO_VL, '                                               +
    '        v.IMPORTE_NOMINAL_VL, '                                      +
    '        v.IMPORTE_REDIMIDO_VL, '                                     +
    '        v.FECHA_EMISION_VL, '                                        +
    '        v.FECHA_CADUCIDAD_VL, '                                      +
    '        v.FECHA_REDENCION_VL, '                                      +
    '        v.OBSERVACIONES_VL, '                                        +
    '        ''EMI'' AS ROL_VL '                                          +
    '   FROM fza_caja_vales v '                                           +
    '  WHERE v.CODIGO_EMPRESA_EMI_VL   = :PEMP '                          +
    '    AND v.CODIGO_ALMACEN_EMI_VL   = :PALM '                          +
    '    AND v.CODIGO_CAJA_EMI_VL      = :PCAJA '                         +
    '    AND v.NUMERO_OPERACION_EMI_VL = :PNUMOP ) '                      +
    'ORDER BY NUMERO_LINEA_PAGO IS NULL, NUMERO_LINEA_PAGO, ROL_VL ';

  // ------------------------------------------------------------------
  //  Pestaña MOVIMIENTOS: filas de fza_caja_movimientos (stock/kardex).
  // ------------------------------------------------------------------
  qryMovimientos.SQL.Text :=
    'SELECT m.NUMERO_MOV, '                                               +
    '       m.TIPO_DOC_MOV, '                                             +
    '       m.LINEA_MOV, '                                                +
    '       m.CODIGO_ALMACEN_MOV, '                                       +
    '       m.CODIGO_ALMACEN_CONTRA_MOV, '                                +
    '       m.CODIGO_ARTICULO_MOV, '                                      +
    '       m.CODIGO_UNIDAD_MOV, '                                        +
    '       a.DESCRIPCION_ARTICULO, '                                     +
    '       m.TIPO_MOVIMIENTO_MOV, '                                      +
    '       m.CANTIDAD_MOV, '                                             +
    '       m.PRECIO_MEDIO_MOV, '                                         +
    '       m.TOTAL_COSTE_MOV '                                           +
    '  FROM fza_movimientos_almacen m '                                   +
    '  LEFT JOIN fza_articulos a '                                        +
    '    ON a.CODIGO_ARTICULO = m.CODIGO_ARTICULO_MOV '                   +
    ' WHERE m.CODIGO_EMPRESA_MOV          = :PEMP '                       +
    '   AND m.CODIGO_ALMACEN_DOC_MOV      = :PALM '                       +
    '   AND m.CODIGO_CAJA_DOC_MOV         = :PCAJA '                      +
    '   AND m.NUMERO_OPERACION_DOC_MOV    = :PNUMOP '                     +
    ' ORDER BY m.NUMERO_MOV, m.LINEA_MOV ';

  // ------------------------------------------------------------------
  //  Pestaña CLIENTE: ficha del cliente asociado a la operación.
  // ------------------------------------------------------------------
  qryCliente.SQL.Text :=
    'SELECT c.CODIGO_CLIENTE, '                                           +
    '       c.RAZONSOCIAL_CLIENTE, '                                      +
    '       c.NIF_CLIENTE, '                                              +
    '       c.MOVIL_CLIENTE, '                                            +
    '       c.EMAIL_CLIENTE, '                                            +
    '       c.DIRECCION1_CLIENTE, '                                       +
    '       c.POBLACION_CLIENTE, '                                        +
    '       c.PROVINCIA_CLIENTE, '                                        +
    '       c.CPOSTAL_CLIENTE, '                                          +
    '       c.TOTAL_DEUDA_CLIENTE '                                       +
    '  FROM fza_clientes c '                                              +
    ' WHERE c.CODIGO_CLIENTE = :PCLI ';

  // ------------------------------------------------------------------
  //  Pestaña DEPÓSITOS: depósitos tocados por esta operación.
  //  ROL = ALTA / CANCELACION / COBRO_PARCIAL según haga falta.
  // ------------------------------------------------------------------
  qryDepositos.SQL.Text :=
    'SELECT DISTINCT  '                                         +
    '       d.ID_DEPOSITO_DEP, '                                          +
    '       d.CODIGO_CLIENTE_DEP, '                                       +
    '       d.CODIGO_ARTICULO_DEP, '                                      +
    '       d.CODIGO_UNIDAD_DEP, '                                        +
    '       d.CODIGO_ALMACEN_DEP, '                                       +
    '       d.CANTIDAD_PENDIENTE_DEP, '                                   +
    '       d.PRECIO_VENTA_DEP, '                                         +
    '       d.IMPORTE_ANTICIPO_DEP, '                                     +
    '       d.ESTADO_DEP, '                                               +
    '       d.FECHA_CREACION_DEP '                                        +
    '  FROM fza_caja_depositos_view d '                                   +
    ' WHERE d.CODIGO_EMPRESA_OP   = :PEMP '                               +
    '   AND d.CODIGO_ALMACEN_OP   = :PALM '                               +
    '   AND d.CODIGO_CAJA_OP      = :PCAJA '                              +
    '   AND d.NUMERO_OPERACION_OP = :PNUMOP ';

  // ------------------------------------------------------------------
  //  Pestaña FACTURA (cabecera).
  // ------------------------------------------------------------------
  qryFactura.SQL.Text :=
    'SELECT f.SERIE_FACTURA, '                                            +
    '       f.NRO_FACTURA, '                                              +
    '       f.FECHA_FACTURA, '                                            +
    '       f.TIPO_FACTURA, '                                             +
    '       f.CODIGO_CLIENTE_FACTURA, '                                   +
    '       f.RAZONSOCIAL_CLIENTE_FACTURA, '                              +
    '       f.TOTAL_BASES_FACTURA, '                                      +
    '       f.TOTAL_IMPUESTOS_FACTURA, '                                  +
    '       f.TOTAL_LIQUIDO_FACTURA '                                     +
    '  FROM fza_facturas f '                                              +
    ' WHERE f.CODIGO_EMPRESA_FACTURA   = :PEMP '                          +
    '   AND f.CODIGO_ALMACEN_FACTURA   = :PALM '                          +
    '   AND f.CODIGO_CAJA_FACTURA      = :PCAJA '                         +
    '   AND f.NUMERO_OPERACION_FACTURA = :PNUMOP ';

  // ------------------------------------------------------------------
  //  Pestaña FACTURA (líneas).
  // ------------------------------------------------------------------
  qryFacturaLin.SQL.Text :=
    'SELECT l.LINEA_FACTURA_LINEA, '                                      +
    '       l.CODIGO_ARTICULO_FACTURA_LINEA, '                            +
    '       l.CODIGO_UNIDAD_FACTURA_LINEA, '                              +
    '       l.DESCRIPCION_ARTICULO_FACTURA_LINEA, '                       +
    '       l.CANTIDAD_FACTURA_LINEA, '                                   +
    '       l.PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA, '                  +
    '       l.PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA, '                  +
    '       l.PORCEN_DTO_FACTURA_LINEA, '                                 +
    '       l.TIPOIVA_ARTICULO_FACTURA_LINEA, '                           +
    '       l.PORCEN_IVA_FACTURA_LINEA, '                                 +
    '       l.TOTAL_FACTURASIVA_LINEA, '                                  +
    '       l.TOTAL_FACTURA_LINEA '                                       +
    '  FROM fza_facturas_lineas l '                                       +
    ' WHERE l.SERIE_FACTURA_LINEA            = :PSERIE '                  +
    '   AND l.NRO_FACTURA_LINEA              = :PNROFAC '                 +
    ' ORDER BY l.LINEA_FACTURA_LINEA ';
end;

procedure TdmConsultaOpe.RefrescarPestanasHijas;
var
  sEmp, sAlm, sCaja, sNumOp, sCli, sSerie, sNroFac: string;
begin
  if FCargando then
    Exit;
  if qryMaestro.IsEmpty then
  begin
    qryOperacion.Close;
    qryPagos.Close;
    qryMovimientos.Close;
    qryCliente.Close;
    qryDepositos.Close;
    qryFactura.Close;
    qryFacturaLin.Close;
    Exit;
  end;

  sEmp    := qryMaestro.FieldByName('CODIGO_EMPRESA_OPCAJA').AsString;
  sAlm    := qryMaestro.FieldByName('CODIGO_ALMACEN_OPCAJA').AsString;
  sCaja   := qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp  := qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCli    := qryMaestro.FieldByName('CLIENTE').AsString;
  sSerie  := qryMaestro.FieldByName('SERIE_FACTURA').AsString;
  sNroFac := qryMaestro.FieldByName('NRO_FACTURA').AsString;

  // --- Operación ---
  qryOperacion.Close;
  qryOperacion.ParamByName('PEMP').AsString    := sEmp;
  qryOperacion.ParamByName('PALM').AsString    := sAlm;
  qryOperacion.ParamByName('PCAJA').AsString   := sCaja;
  qryOperacion.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryOperacion, 'Operaciones');

  // --- Pagos + Vales ---
  qryPagos.Close;
  qryPagos.ParamByName('PEMP').AsString    := sEmp;
  qryPagos.ParamByName('PALM').AsString    := sAlm;
  qryPagos.ParamByName('PCAJA').AsString   := sCaja;
  qryPagos.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryPagos, 'Pagos');

  // --- Movimientos ---
  qryMovimientos.Close;
  qryMovimientos.ParamByName('PEMP').AsString    := sEmp;
  qryMovimientos.ParamByName('PALM').AsString    := sAlm;
  qryMovimientos.ParamByName('PCAJA').AsString   := sCaja;
  qryMovimientos.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryMovimientos, 'Movimientos');
  // --- Cliente ---
  qryCliente.Close;
  if Trim(sCli) <> '' then
  begin
    qryCliente.ParamByName('PCLI').AsString := sCli;
    AbrirSeguro(qryCliente, 'Clientes');
  end;
  // --- Depósitos ---
  qryDepositos.Close;
  qryDepositos.ParamByName('PEMP').AsString    := sEmp;
  qryDepositos.ParamByName('PALM').AsString    := sAlm;
  qryDepositos.ParamByName('PCAJA').AsString   := sCaja;
  qryDepositos.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryDepositos, 'Depósitos');
  // --- Factura (cabecera + líneas) ---
  qryFactura.Close;
  qryFacturaLin.Close;
  qryFactura.ParamByName('PEMP').AsString    := sEmp;
  qryFactura.ParamByName('PALM').AsString    := sAlm;
  qryFactura.ParamByName('PCAJA').AsString   := sCaja;
  qryFactura.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryFactura, 'Facturas');
  if (not qryFactura.IsEmpty) and (Trim(sSerie) <> '') and (Trim(sNroFac) <> '') then
  begin
    qryFacturaLin.ParamByName('PSERIE').AsString  := sSerie;
    qryFacturaLin.ParamByName('PNROFAC').AsString := sNroFac;
    AbrirSeguro(qryFacturaLin, 'Líneas de Facturas');
  end;
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.CargarMaestro(AFecha:     TDate;
                                       const AEmp,
                                             AAlm,
                                             ACaja,
                                             ATextoLibre: string);
begin
  // Cerramos todas las queries hijas primero para que OnDataChange no
  // dispare mientras recargamos el maestro.
  FCargando := True;
  try
    qryOperacion.Close;
    qryPagos.Close;
    qryMovimientos.Close;
    qryCliente.Close;
    qryDepositos.Close;
    qryFactura.Close;
    qryFacturaLin.Close;
    qryMaestro.Close;
    qryMaestro.ParamByName('PFECHA').AsDate    := AFecha;
    qryMaestro.ParamByName('PEMP').AsString    := AEmp;
    qryMaestro.ParamByName('PALM').AsString    := AAlm;
    qryMaestro.ParamByName('PCAJA').AsString   := ACaja;
    qryMaestro.ParamByName('PTXT').AsString    := ATextoLibre;
    qryMaestro.Open;
  finally
    FCargando := False;
  end;
  // Una vez cargado el maestro, refrescamos las pestañas hijas con la
  // primera fila (si hay).
  RefrescarPestanasHijas;
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.AbrirSeguro(q: TUniQuery; const sNombre: string);
begin
  try
    q.Open;
  except
    on E: Exception do
    begin
      q.Close;
      // Registramos pero no propagamos: un fallo en una pestaña no debe
      // tirar el maestro ni las demás pestañas.
      showmessage((Format('[ConsultaOpe] Error abriendo %s: %s',
                                     [sNombre, E.Message])));
    end;
  end;
end;

// -----------------------------------------------------------------------------
function TdmConsultaOpe.TienePagos: Boolean;
begin
  Result := qryPagos.Active and (not qryPagos.IsEmpty);
end;

function TdmConsultaOpe.TieneMovimientos: Boolean;
begin
  Result := qryMovimientos.Active and (not qryMovimientos.IsEmpty);
end;

function TdmConsultaOpe.TieneCliente: Boolean;
begin
  Result := qryCliente.Active and (not qryCliente.IsEmpty);
end;

function TdmConsultaOpe.TieneDepositos: Boolean;
begin
  Result := qryDepositos.Active and (not qryDepositos.IsEmpty);
end;

function TdmConsultaOpe.TieneFactura: Boolean;
begin
  Result := qryFactura.Active and (not qryFactura.IsEmpty);
end;

end.
