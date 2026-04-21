unit UniDataConsultaOpe;

// =============================================================================
//  Módulo de datos para la consulta de operaciones de caja (F10 Buscar/Modificar).
//
//  Expone 7 queries (1 maestro + 6 para pestañas) que se refrescan al
//  cambiar la fila del maestro. TODO ES SÓLO LECTURA.
//
//  El filtrado del maestro es por:
//    - Fecha + empresa/almacén/caja (contexto fijo heredado del menú)
//    - Texto libre (número operación, nº factura, cliente, concepto)
// =============================================================================

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, MemDS, DBAccess;

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

  // -----------------------------------------------------------------
  //  Grid MAESTRO: una fila por NUMERO_OPERACION_OPCAJA
  // -----------------------------------------------------------------
  qryMaestro.SQL.Text :=
    'SELECT o.CODIGO_EMPRESA_OPCAJA, '                                    +
    '       o.CODIGO_ALMACEN_OPCAJA, '                                    +
    '       o.CODIGO_CAJA_OPCAJA, '                                       +
    '       o.NUMERO_OPERACION_OPCAJA, '                                  +
    '       MIN(o.FECHA_OPERACION_OPCAJA)  AS FECHA_OP, '                 +
    '       MIN(o.CODIGO_EMPLEADO_OPCAJA)  AS EMPLEADO, '                 +
    '       MIN(o.CODIGO_CLIENTE_OPCAJA)   AS CLIENTE, '                  +
    '       MIN(c.RAZONSOCIAL_CLIENTE)     AS RAZON_SOCIAL_CLI, '         +
    '       MIN(o.SERIE_FACTURA_OPCAJA)    AS SERIE_FACTURA, '            +
    '       MIN(o.NRO_FACTURA_OPCAJA)      AS NRO_FACTURA, '              +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA '               +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA '               +
    '                    SEPARATOR ''+'')  AS TIPOS_OP, '                 +
    '       SUM(o.IMPORTE_TOTAL_OPCAJA)    AS IMPORTE_TOTAL, '            +
    '       GROUP_CONCAT(DISTINCT o.CONCEPTO_GASTO_INGRESO_OPCAJA '       +
    '                    SEPARATOR '' | '') AS CONCEPTOS '                +
    '  FROM fza_caja_operaciones o '                                      +
    '  LEFT JOIN fza_clientes c '                                         +
    '    ON c.CODIGO_CLIENTE = o.CODIGO_CLIENTE_OPCAJA '                  +
    ' WHERE DATE(o.FECHA_OPERACION_OPCAJA) = :PFECHA '                    +
    '   AND o.CODIGO_EMPRESA_OPCAJA = :PEMP '                             +
    '   AND o.CODIGO_ALMACEN_OPCAJA = :PALM '                             +
    '   AND o.CODIGO_CAJA_OPCAJA    = :PCAJA '                            +
    '   AND (:PTEXTO = '''' '                                             +
    '        OR o.NUMERO_OPERACION_OPCAJA LIKE CONCAT(''%'', :PTEXTO2, ''%'') ' +
    '        OR o.NRO_FACTURA_OPCAJA      LIKE CONCAT(''%'', :PTEXTO3, ''%'') ' +
    '        OR o.CODIGO_CLIENTE_OPCAJA   LIKE CONCAT(''%'', :PTEXTO4, ''%'') ' +
    '        OR c.RAZONSOCIAL_CLIENTE     LIKE CONCAT(''%'', :PTEXTO5, ''%'') ' +
    '        OR o.CONCEPTO_GASTO_INGRESO_OPCAJA LIKE CONCAT(''%'', :PTEXTO6, ''%'')) ' +
    ' GROUP BY o.CODIGO_EMPRESA_OPCAJA, '                                 +
    '          o.CODIGO_ALMACEN_OPCAJA, '                                 +
    '          o.CODIGO_CAJA_OPCAJA, '                                    +
    '          o.NUMERO_OPERACION_OPCAJA '                                +
    ' ORDER BY FECHA_OP DESC, NUMERO_OPERACION_OPCAJA DESC';

  // -----------------------------------------------------------------
  //  Pestaña OPERACIÓN: filas de fza_caja_operaciones (una por TIPO_OP).
  //  Los pagos ya NO van aquí — tienen su propia pestaña.
  // -----------------------------------------------------------------
  qryOperacion.SQL.Text :=
    'SELECT o.TIPO_OPERACION_OPCAJA, '                                    +
    '       o.IMPORTE_TOTAL_OPCAJA, '                                     +
    '       o.CONCEPTO_GASTO_INGRESO_OPCAJA, '                            +
    '       o.ID_DEPOSITO_OPCAJA, '                                       +
    '       o.SERIE_REF_ORIGEN_OPCAJA, '                                  +
    '       o.NUMERO_REF_ORIGEN_OPCAJA, '                                 +
    '       o.MOTIVO_DEVOLUCION_OPCAJA, '                                 +
    '       o.ESTADO_DEVOLUCION_OPCAJA, '                                 +
    '       o.IMPORTE_DEVUELTO_ACUM_OPCAJA, '                             +
    '       o.FECHA_OPERACION_OPCAJA '                                    +
    '  FROM fza_caja_operaciones o '                                      +
    ' WHERE o.CODIGO_EMPRESA_OPCAJA   = :PEMP '                           +
    '   AND o.CODIGO_ALMACEN_OPCAJA   = :PALM '                           +
    '   AND o.CODIGO_CAJA_OPCAJA      = :PCAJA '                          +
    '   AND o.NUMERO_OPERACION_OPCAJA = :PNUMOP '                         +
    ' ORDER BY o.FECHA_OPERACION_OPCAJA, o.ID_OPCAJA';

  // -----------------------------------------------------------------
  //  Pestaña PAGOS: formas de pago de la operación.
  //  LEFT JOIN con fza_caja_formas_pago para mostrar el nombre descriptivo
  //  en lugar de solo el código ('EFE', 'TARJ', 'VALE', etc.)
  // -----------------------------------------------------------------
  qryPagos.SQL.Text :=
    'SELECT p.NUMERO_LINEA_PAGO, '                                        +
    '       p.CODIGO_FORMAP, '                                            +
    '       fp.DESCRIPCION_FORMAP, '                                      +
    '       p.IMPORTE_ENTREGADO_PAGO, '                                   +
    '       p.IMPORTE_CAMBIO_PAGO, '                                      +
    '       (p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO) '          +
    '            AS IMPORTE_NETO_PAGO, '                                  +
    '       p.CODIGO_DIVISA_PAGO, '                                       +
    '       p.RED_BLOCKCHAIN, '                                           +
    '       p.FACTOR_CAMBIO_PAGO, '                                       +
    '       p.IMPORTE_DIVISA_PAGO, '                                      +
    '       p.REFERENCIA_PAGO, '                                          +
    '       p.OBSERVACIONES_PAGO, '                                       +
    '       p.INSTANTEALTA '                                              +
    '  FROM fza_caja_pagos p '                                            +
    '  LEFT JOIN fza_caja_formas_pago fp '                                +
    '    ON fp.CODIGO_FORMAP = p.CODIGO_FORMAP '                          +
    ' WHERE p.CODIGO_EMPRESA_PAGO   = :PEMP '                             +
    '   AND p.CODIGO_ALMACEN_PAGO   = :PALM '                             +
    '   AND p.CODIGO_CAJA_PAGO      = :PCAJA '                            +
    '   AND p.NUMERO_OPERACION_PAGO = :PNUMOP '                           +
    ' ORDER BY p.NUMERO_LINEA_PAGO';

  // -----------------------------------------------------------------
  //  Pestaña MOVIMIENTOS DE ALMACÉN
  // -----------------------------------------------------------------
  qryMovimientos.SQL.Text :=
    'SELECT m.NUMERO_MOV, '                                               +
    '       m.TIPO_DOC_MOV, '                                             +
    '       m.LINEA_MOV, '                                                +
    '       m.CODIGO_ALMACEN_MOV, '                                       +
    '       m.CODIGO_ALMACEN_CONTRA_MOV, '                                +
    '       m.CODIGO_ARTICULO_MOV, '                                      +
    '       m.CODIGO_UNIDAD_MOV, '                                        +
    '       COALESCE(m.DESCRIPCION_ARTICULO_MOV, a.DESCRIPCION_ARTICULO) ' +
    '            AS DESCRIPCION_ARTICULO, '                               +
    '       m.TIPO_MOVIMIENTO_MOV, '                                      +
    '       m.CANTIDAD_MOV, '                                             +
    '       m.PRECIO_MEDIO_MOV, '                                         +
    '       m.TOTAL_COSTE_MOV, '                                          +
    '       m.FECHA_MOV '                                                 +
    '  FROM fza_movimientos_almacen m '                                   +
    '  LEFT JOIN fza_articulos a '                                        +
    '    ON a.CODIGO_ARTICULO = m.CODIGO_ARTICULO_MOV '                   +
    ' WHERE m.CODIGO_EMPRESA_MOV        = :PEMP '                         +
    '   AND m.CODIGO_ALMACEN_DOC_MOV    = :PALM '                         +
    '   AND m.CODIGO_CAJA_DOC_MOV       = :PCAJA '                        +
    '   AND m.NUMERO_OPERACION_DOC_MOV  = :PNUMOP '                       +
    ' ORDER BY m.LINEA_MOV, m.TIPO_MOVIMIENTO_MOV';

  // -----------------------------------------------------------------
  //  Pestaña CLIENTE
  // -----------------------------------------------------------------
  qryCliente.SQL.Text :=
    'SELECT * FROM fza_clientes WHERE CODIGO_CLIENTE = :PCLI';

  // -----------------------------------------------------------------
  //  Pestaña DEPÓSITOS: depósitos creados o cancelados en esta operación
  // -----------------------------------------------------------------
  qryDepositos.SQL.Text :=
    'SELECT d.ID_DEPOSITO_DEP, '                                          +
    '       d.CODIGO_CLIENTE_DEP, '                                       +
    '       d.CODIGO_ARTICULO_DEP, '                                      +
    '       d.CODIGO_UNIDAD_DEP, '                                        +
    '       d.CODIGO_ALMACEN_DEP, '                                       +
    '       d.CANTIDAD_PENDIENTE_DEP, '                                   +
    '       d.PRECIO_VENTA_DEP, '                                         +
    '       d.IMPORTE_ANTICIPO_DEP, '                                     +
    '       d.ESTADO_DEP, '                                               +
    '       d.FECHA_CREACION_DEP, '                                       +
    '       d.NUMERO_OPERACION_DEP, '                                     +
    '       d.NUMERO_OPERACION_CANCEL_DEP, '                              +
    '       CASE WHEN d.NUMERO_OPERACION_DEP = :PNUMOP '                  +
    '            THEN ''ALTA'' '                                          +
    '            WHEN d.NUMERO_OPERACION_CANCEL_DEP = :PNUMOP2 '          +
    '            THEN ''CANCELADO'' '                                     +
    '            ELSE ''OTRO'' END AS ROL_EN_OPERACION '                  +
    '  FROM fza_depositos_cliente d '                                     +
    ' WHERE (d.CODIGO_EMPRESA_DEP = :PEMP '                               +
    '        AND d.NUMERO_OPERACION_DEP = :PNUMOP3) '                     +
    '    OR (d.EMPRESA_CANCEL_DEP = :PEMP2 '                              +
    '        AND d.NUMERO_OPERACION_CANCEL_DEP = :PNUMOP4) '              +
    ' ORDER BY d.FECHA_CREACION_DEP';

  // -----------------------------------------------------------------
  //  Pestaña FACTURA (cabecera + líneas)
  // -----------------------------------------------------------------
  qryFactura.SQL.Text :=
    'SELECT * FROM fza_facturas '                                         +
    ' WHERE SERIE_FACTURA = :PSERIE AND NRO_FACTURA = :PNRO';

  qryFacturaLin.SQL.Text :=
    'SELECT LINEA_FACTURA_LINEA, '                                        +
    '       CODIGO_ARTICULO_FACTURA_LINEA, '                              +
    '       CODIGO_UNIDAD_FACTURA_LINEA, '                                +
    '       DESCRIPCION_ARTICULO_FACTURA_LINEA, '                         +
    '       CANTIDAD_FACTURA_LINEA, '                                     +
    '       PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA, '                    +
    '       PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA, '                    +
    '       PORCEN_DTO_FACTURA_LINEA, '                                   +
    '       TIPOIVA_ARTICULO_FACTURA_LINEA, '                             +
    '       PORCEN_IVA_FACTURA_LINEA, '                                   +
    '       TOTAL_FACTURASIVA_LINEA, '                                    +
    '       TOTAL_FACTURA_LINEA '                                         +
    '  FROM fza_facturas_lineas '                                         +
    ' WHERE SERIE_FACTURA_LINEA = :PSERIE '                               +
    '   AND NRO_FACTURA_LINEA   = :PNRO '                                 +
    ' ORDER BY LINEA_FACTURA_LINEA';
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.CargarMaestro(AFecha:     TDate;
                                       const AEmp,
                                             AAlm,
                                             ACaja,
                                             ATextoLibre: string);
begin
  FCargando := True;
  try
    qryMaestro.Close;
    qryMaestro.ParamByName('PFECHA').AsDate   := AFecha;
    qryMaestro.ParamByName('PEMP').AsString   := AEmp;
    qryMaestro.ParamByName('PALM').AsString   := AAlm;
    qryMaestro.ParamByName('PCAJA').AsString  := ACaja;
    // El mismo valor de búsqueda va a 6 parámetros (OR entre columnas)
    qryMaestro.ParamByName('PTEXTO').AsString  := ATextoLibre;
    qryMaestro.ParamByName('PTEXTO2').AsString := ATextoLibre;
    qryMaestro.ParamByName('PTEXTO3').AsString := ATextoLibre;
    qryMaestro.ParamByName('PTEXTO4').AsString := ATextoLibre;
    qryMaestro.ParamByName('PTEXTO5').AsString := ATextoLibre;
    qryMaestro.ParamByName('PTEXTO6').AsString := ATextoLibre;
    qryMaestro.Open;
  finally
    FCargando := False;
  end;
  // Primer refresco manual de las hijas tras abrir
  RefrescarPestanasHijas;
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.RefrescarPestanasHijas;
var
  sEmp, sAlm, sCaja, sNumOp, sCli, sSerie, sNroFac: string;
begin
  if FCargando then Exit;

  qryOperacion.Close;
  qryPagos.Close;
  qryMovimientos.Close;
  qryCliente.Close;
  qryDepositos.Close;
  qryFactura.Close;
  qryFacturaLin.Close;

  if (not qryMaestro.Active) or qryMaestro.IsEmpty or
     qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').IsNull then
    Exit;

  sEmp    := qryMaestro.FieldByName('CODIGO_EMPRESA_OPCAJA').AsString;
  sAlm    := qryMaestro.FieldByName('CODIGO_ALMACEN_OPCAJA').AsString;
  sCaja   := qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp  := qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCli    := qryMaestro.FieldByName('CLIENTE').AsString;
  sSerie  := qryMaestro.FieldByName('SERIE_FACTURA').AsString;
  sNroFac := qryMaestro.FieldByName('NRO_FACTURA').AsString;

  // ---- OPERACIÓN (solo fza_caja_operaciones) ----
  qryOperacion.ParamByName('PEMP').AsString    := sEmp;
  qryOperacion.ParamByName('PALM').AsString    := sAlm;
  qryOperacion.ParamByName('PCAJA').AsString   := sCaja;
  qryOperacion.ParamByName('PNUMOP').AsString  := sNumOp;
  qryOperacion.Open;

  // ---- PAGOS ----
  qryPagos.ParamByName('PEMP').AsString    := sEmp;
  qryPagos.ParamByName('PALM').AsString    := sAlm;
  qryPagos.ParamByName('PCAJA').AsString   := sCaja;
  qryPagos.ParamByName('PNUMOP').AsString  := sNumOp;
  qryPagos.Open;

  // ---- MOVIMIENTOS ----
  qryMovimientos.ParamByName('PEMP').AsString   := sEmp;
  qryMovimientos.ParamByName('PALM').AsString   := sAlm;
  qryMovimientos.ParamByName('PCAJA').AsString  := sCaja;
  qryMovimientos.ParamByName('PNUMOP').AsString := sNumOp;
  qryMovimientos.Open;

  // ---- CLIENTE ----
  if Trim(sCli) <> '' then
  begin
    qryCliente.ParamByName('PCLI').AsString := sCli;
    qryCliente.Open;
  end;

  // ---- DEPÓSITOS ----
  qryDepositos.ParamByName('PEMP').AsString    := sEmp;
  qryDepositos.ParamByName('PNUMOP').AsString  := sNumOp;
  qryDepositos.ParamByName('PNUMOP2').AsString := sNumOp;
  qryDepositos.ParamByName('PEMP2').AsString   := sEmp;
  qryDepositos.ParamByName('PNUMOP3').AsString := sNumOp;
  qryDepositos.ParamByName('PNUMOP4').AsString := sNumOp;
  qryDepositos.Open;

  // ---- FACTURA ----
  if (Trim(sSerie) <> '') and (Trim(sNroFac) <> '') and (sNroFac <> '0') then
  begin
    qryFactura.ParamByName('PSERIE').AsString := sSerie;
    qryFactura.ParamByName('PNRO').AsString   := sNroFac;
    qryFactura.Open;
    qryFacturaLin.ParamByName('PSERIE').AsString := sSerie;
    qryFacturaLin.ParamByName('PNRO').AsString   := sNroFac;
    qryFacturaLin.Open;
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
