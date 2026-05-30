{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConsultaOpe                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de consulta de operaciones de caja (F10).                     }
{    Maestro y pestañas (operación, pagos, vales, movimientos, cliente,        }
{    depósitos, factura).                                                      }
{******************************************************************************}
unit UniDataConsultaOpe;

// =============================================================================
// Modulo de datos para la consulta de operaciones de caja (F10
// Buscar/Modificar).
//
//  Expone 8 queries (1 maestro + 7 para pestañas) que se refrescan al
//  cambiar la fila del maestro. TODO ES SOLO LECTURA.
//
//  El filtrado del maestro es por:
//    - Fecha + empresa/almacen/caja (contexto fijo heredado del menu)
//    - Texto libre (numero operacion, nº factura, cliente, concepto,
//                   descripcion/codigo/SKU de articulos en lineas de factura)
//
//  Pestañas:
//    - Operacion    : filas crudas de fza_caja_operaciones.
//    - Pagos        : lineas de fza_caja_pagos. SOLO pagos, sin vales.
//    - Vales        : vales emitidos y/o redimidos en esta operacion (NUEVO).
//    - Movimientos  : kardex (fza_movimientos_almacen).
//    - Cliente      : ficha cliente.
//    - Depositos    : depositos tocados, agrupados por ID_DEPOSITO_DEP
//                     para evitar duplicados (alta + cobro_inicial juntos).
//    - Factura      : cabecera + lineas (fza_facturas / fza_facturas_lineas).
// =============================================================================

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, MemDS, DBAccess, vcl.dialogs;

type
  TdmConsultaOpe = class(TDataModule)
    qryMaestro:      TUniQuery;
    qryOperacion:    TUniQuery;
    qryPagos:        TUniQuery;
    qryVales:        TUniQuery;
    qryMovimientos:  TUniQuery;
    qryCliente:      TUniQuery;
    qryDepositos:    TUniQuery;
    qryFactura:      TUniQuery;
    qryFacturaLin:   TUniQuery;
    dsMaestro:       TDataSource;
    dsOperacion:     TDataSource;
    dsPagos:         TDataSource;
    dsVales:         TDataSource;
    dsMovimientos:   TDataSource;
    dsCliente:       TDataSource;
    dsDepositos:     TDataSource;
    dsFactura:       TDataSource;
    dsFacturaLin:    TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    FCargando: Boolean;
    // Clave (Emp|Alm|Caja|NumOp) de la ultima operacion para la que se
    // refrescaron las pestanas hijas. Si una nueva llamada a
    // RefrescarPestanasHijas trae la misma clave, salimos sin tocar BBDD:
    // el grid suele disparar OnDataChange varias veces por la misma fila
    // (al abrir el form, al aplicar el layout, al cambiar visibilidad de
    // pestanas, etc.) y antes recargabamos 3-4 veces lo mismo.
    FUltimaClaveHijas: string;
    // Clave (Fecha|Emp|Alm|Caja|Txt) de la ultima carga del maestro. Si
    // CargarMaestro entra con la misma combinacion, salimos sin tocar
    // BBDD ni resetear FUltimaClaveHijas, evitando la cascada completa.
    // Caso tipico: al abrir el form, dtpFecha.Date := AFecha dispara
    // OnEditValueChanged y luego FormShow llama tambien a RecargarMaestro:
    // antes salian 2-3 cargas identicas.
    FUltimaClaveMaestro: string;
  public
    procedure CargarMaestro(AFecha:     TDate;
                            const AEmp,
                                  AAlm,
                                  ACaja,
                                  ATextoLibre: string);
    procedure RefrescarPestanasHijas;
    function  TienePagos:       Boolean;
    function  TieneVales:       Boolean;
    function  TieneMovimientos: Boolean;
    function  TieneCliente:     Boolean;
    function  TieneDepositos:   Boolean;
    function  TieneFactura:     Boolean;
    function  EsOperacionCaja: Boolean;
    // True si la operacion seleccionada es un traspaso (TR misma empresa /
    // TA entre empresas). Usado para reimprimir su ticket especifico.
    function  EsTraspaso: Boolean;
  private
    procedure AbrirSeguro(q: TUniQuery; const sNombre: string);
  end;

var
  dmConsultaOpe: TdmConsultaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibGlobalVar, inLibLog;

{$R *.dfm}

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.DataModuleCreate(Sender: TObject);
begin
  qryMaestro.Connection     := oConn;
  qryOperacion.Connection   := oConn;
  qryPagos.Connection       := oConn;
  qryVales.Connection       := oConn;
  qryMovimientos.Connection := oConn;
  qryCliente.Connection     := oConn;
  qryDepositos.Connection   := oConn;
  qryFactura.Connection     := oConn;
  qryFacturaLin.Connection  := oConn;

  // ------------------------------------------------------------------
  //  Grid MAESTRO: una fila por NUMERO_OPERACION_OPCAJA del dia.
  //  Agrupa los distintos tipos de operacion (VENTA, DEV, CB, ...) de
  //  una misma numeracion en una sola fila visible.
  // ------------------------------------------------------------------
  qryMaestro.SQL.Text :=
    'SELECT o.CODIGO_EMP_OPCAJA, '                                    +
    '       o.CODIGO_ALM_OPCAJA, '                                    +
    '       o.CODIGO_CAJA_OPCAJA, '                                       +
    '       o.NUMERO_OPERACION_OPCAJA, '                                  +
    '       MIN(o.FECHA_OPERACION_OPCAJA)            AS FECHA_OP, '       +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA '               +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA '               +
    '                    SEPARATOR '','')            AS TIPOS_OP, '       +
    '       GROUP_CONCAT(DISTINCT NULLIF(o.CONCEPTO_GASTO_INGRESO_OPCAJA,'''') '
      +
    '                    SEPARATOR '' | '')          AS CONCEPTOS, '      +
    '       COALESCE(MAX(f.TOTAL_LIQUIDO_FAC), '                          +
    '                SUM(o.IMPORTE_TOTAL_OPCAJA))    AS IMPORTE_TOTAL, '  +
    '       COALESCE(MAX(f.SERIE_FAC), MAX(o.SERIE_FAC_OPCAJA)) '       +
    '                                                AS SERIE_FAC, '     +
    '       COALESCE(MAX(f.NUMERO_FAC), MAX(o.NUMERO_FAC_OPCAJA)) '      +
    '                                                AS NUMERO_FAC, '     +
    '       MAX(COALESCE(f.CODIGO_CLI_FAC, o.CODIGO_CLI_OPCAJA)) ' +
    '                                                AS CLIENTE, '        +
    '       MAX(cli.RAZON_SOCIAL_CLI)             AS RAZON_SOCIAL_CLI,'+
    '       MAX(o.USUARIO_ALTA)                       AS EMPLEADO '        +
    '  FROM fza_caja_operaciones o '                                      +
    '  LEFT JOIN fza_facturas f '                                         +
    '    ON f.CODIGO_EMP_FAC   = o.CODIGO_EMP_OPCAJA '        +
    '   AND f.CODIGO_ALM_FAC   = o.CODIGO_ALM_OPCAJA '        +
    '   AND f.CODIGO_CAJA_FAC      = o.CODIGO_CAJA_OPCAJA '           +
    '   AND f.NUMERO_OPERACION_FAC = o.NUMERO_OPERACION_OPCAJA '      +
    '  LEFT JOIN fza_clientes cli '                                       +
    '    ON cli.CODIGO_CLI_CLI = COALESCE(f.CODIGO_CLI_FAC, '     +
    '                                     o.CODIGO_CLI_OPCAJA) '      +
    ' WHERE o.FECHA_OP_DIA_OPCAJA = :PFECHA '                             +
    '   AND o.CODIGO_EMP_OPCAJA = :PEMP '                             +
    '   AND o.CODIGO_ALM_OPCAJA = :PALM '                             +
    '   AND o.CODIGO_CAJA_OPCAJA    = :PCAJA '                            +
    '   AND ( :PTXT = '''' '                                              +
    '         OR o.NUMERO_OPERACION_OPCAJA LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR f.NUMERO_FAC           LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR cli.RAZON_SOCIAL_CLI LIKE CONCAT(''%'', :PTXT, ''%'') ' +
    '         OR o.CONCEPTO_GASTO_INGRESO_OPCAJA LIKE CONCAT(''%'', :PTXT, ' +
    '''%'') ' +
    '         OR EXISTS ( '                                                +
    '               SELECT 1 FROM fza_facturas_lineas l '                  +
    '                WHERE l.CODIGO_EMP_FACLIN   = o.CODIGO_EMP_OPCAJA ' +
    '                  AND l.CODIGO_ALM_FACLIN   = o.CODIGO_ALM_OPCAJA ' +
    '                  AND l.CODIGO_CAJA_FACLIN      = o.CODIGO_CAJA_OPCAJA ' +
    '                  AND l.NUMERO_OPERACION_FACLIN = ' +
    'o.NUMERO_OPERACION_OPCAJA ' +
    '                  AND ( l.DESCRIPCION_ARTICULO_FACLIN LIKE ' +
    'CONCAT(''%'', :PTXT, ''%'') ' +
    '                     OR l.CODIGO_ART_FACLIN      LIKE CONCAT(''%'', ' +
    ':PTXT, ''%'') ' +
    '                     OR l.CODIGO_UNIDAD_FACLIN        LIKE ' +
    'CONCAT(''%'', :PTXT, ''%'') ' +
    '                      ) '                                             +
    '                   ) '                                                +
    '       ) '                                                           +
    ' GROUP BY o.CODIGO_EMP_OPCAJA, '                                 +
    '          o.CODIGO_ALM_OPCAJA, '                                 +
    '          o.CODIGO_CAJA_OPCAJA, '                                    +
    '          o.NUMERO_OPERACION_OPCAJA '                                +
    ' ORDER BY FECHA_OP DESC ';

  // ------------------------------------------------------------------
  //  Pestaña OPERACION: filas crudas de fza_caja_operaciones.
  //  Una misma numeracion puede tener varias filas (VENTA + DEV + CB).
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
    ' WHERE CODIGO_EMP_OPCAJA   = :PEMP '                             +
    '   AND CODIGO_ALM_OPCAJA   = :PALM '                             +
    '   AND CODIGO_CAJA_OPCAJA      = :PCAJA '                            +
    '   AND NUMERO_OPERACION_OPCAJA = :PNUMOP '                           +
    ' ORDER BY FECHA_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA ';

  // ------------------------------------------------------------------
  //  Pestaña PAGOS: solo lineas de fza_caja_pagos.
  //  Los vales (emitidos / redimidos) van en su propia pestaña.
  // ------------------------------------------------------------------
  qryPagos.SQL.Text :=
    'SELECT p.NUMERO_LINEA_PAGO, '                                    +
    '       p.CODIGO_FP_CFP, '                                        +
    '       fp.DESCRIPCION_FORMA_PAGO_CFP, '                          +
    '       p.IMPORTE_ENTREGADO_PAGO, '                               +
    '       p.IMPORTE_CAMBIO_PAGO, '                                  +
    '       (p.IMPORTE_ENTREGADO_PAGO - p.IMPORTE_CAMBIO_PAGO) '      +
    '                                AS IMPORTE_NETO_PAGO, '          +
    '       p.CODIGO_DIVISA_PAGO, '                                   +
    '       p.RED_BLOCKCHAIN_PAGO, '                                  +
    '       p.FACTOR_CAMBIO_PAGO, '                                   +
    '       p.IMPORTE_DIVISA_PAGO, '                                  +
    '       p.REFERENCIA_FACPAG, '                                    +
    '       p.OBSERVACIONES_PAGO '                                    +
    '  FROM fza_caja_pagos p '                                        +
    '  LEFT JOIN fza_caja_formas_pago fp '                            +
    '    ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP '                      +
    ' WHERE p.CODIGO_EMP_PAGO        = :PEMP '                        +
    '   AND p.CODIGO_ALM_PAGO        = :PALM '                        +
    '   AND p.CODIGO_CAJA_PAGO       = :PCAJA '                       +
    '   AND p.NUMERO_OPERACION_PAGO  = :PNUMOP '                      +
    ' ORDER BY p.NUMERO_LINEA_PAGO ';

  // ------------------------------------------------------------------
  //  Pestaña VALES: vales emitidos y redimidos en esta operacion.
  //  ROL_VL = 'EMI' (emitido aqui) | 'RED' (redimido aqui).
  //  Si un vale se emite y se redime en la misma operacion (raro pero
  //  posible), aparecera dos veces, una por rol -- es lo correcto.
  // ------------------------------------------------------------------
  qryVales.SQL.Text :=
    '(SELECT ''EMI''                AS ROL_VL, '                      +
    '        v.CODIGO_VL, '                                           +
    '        v.CODIGO_PADRE_VL, '                                     +
    '        v.PIN_SEGURIDAD_VL, '                                    +
    '        v.ESTADO_VL, '                                           +
    '        v.IMPORTE_NOMINAL_VL, '                                  +
    '        v.IMPORTE_REDIMIDO_VL, '                                 +
    '        v.FECHA_EMISION_VL, '                                    +
    '        v.FECHA_CADUCIDAD_VL, '                                  +
    '        v.FECHA_REDENCION_VL, '                                  +
    '        v.OBSERVACIONES_VL '                                     +
    '   FROM fza_caja_vales v '                                       +
    '  WHERE v.CODIGO_EMP_EMI_VL        = :PEMP '                     +
    '    AND v.CODIGO_ALM_EMI_VL        = :PALM '                     +
    '    AND v.CODIGO_CAJA_EMI_VL       = :PCAJA '                    +
    '    AND v.NUMERO_OPERACION_EMI_VL  = :PNUMOP) '                  +
    'UNION ALL '                                                      +
    '(SELECT ''RED''                AS ROL_VL, '                      +
    '        v.CODIGO_VL, '                                           +
    '        v.CODIGO_PADRE_VL, '                                     +
    '        v.PIN_SEGURIDAD_VL, '                                    +
    '        v.ESTADO_VL, '                                           +
    '        v.IMPORTE_NOMINAL_VL, '                                  +
    '        v.IMPORTE_REDIMIDO_VL, '                                 +
    '        v.FECHA_EMISION_VL, '                                    +
    '        v.FECHA_CADUCIDAD_VL, '                                  +
    '        v.FECHA_REDENCION_VL, '                                  +
    '        v.OBSERVACIONES_VL '                                     +
    '   FROM fza_caja_vales v '                                       +
    '  WHERE v.CODIGO_EMP_RED_VL        = :PEMP '                     +
    '    AND v.CODIGO_ALM_RED_VL        = :PALM '                     +
    '    AND v.CODIGO_CAJA_RED_VL       = :PCAJA '                    +
    '    AND v.NUMERO_OPERACION_RED_VL  = :PNUMOP) '                  +
    'ORDER BY ROL_VL, CODIGO_VL ';

  // ------------------------------------------------------------------
  //  Pestaña MOVIMIENTOS: filas de fza_caja_movimientos (stock/kardex).
  // ------------------------------------------------------------------
  qryMovimientos.SQL.Text :=
    'SELECT m.NUMERO_MOV, '                                               +
    '       m.TIPO_DOC_MOV, '                                             +
    '       m.LINEA_MOV, '                                                +
    '       m.CODIGO_ALM_MOV, '                                       +
    '       m.CODIGO_ALM_CONTRA_MOV, '                                +
    '       m.CODIGO_ART_MOV, '                                      +
    '       m.CODIGO_UNIDAD_MOV, '                                        +
    '       a.DESCRIPCION_ART, '                                     +
    '       m.TIPO_MOV, '                                      +
    '       m.CANTIDAD_MOV, '                                             +
    '       m.PRECIO_MEDIO_MOV, '                                         +
    '       m.TOTAL_COSTE_MOV '                                           +
    '  FROM fza_movimientos_almacen m '                                   +
    '  LEFT JOIN fza_articulos a '                                        +
    '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV '                   +
    ' WHERE m.CODIGO_EMP_MOV          = :PEMP '                       +
    '   AND m.CODIGO_ALM_DOC_MOV      = :PALM '                       +
    '   AND m.CODIGO_CAJA_DOC_MOV         = :PCAJA '                      +
    '   AND m.NUMERO_OPERACION_DOC_MOV    = :PNUMOP '                     +
    ' ORDER BY m.NUMERO_MOV, m.LINEA_MOV ';

  // ------------------------------------------------------------------
  //  Pestaña CLIENTE: ficha del cliente asociado a la operacion.
  // ------------------------------------------------------------------
  qryCliente.SQL.Text :=
    'SELECT c.CODIGO_CLI_CLI, '                                           +
    '       c.RAZON_SOCIAL_CLI, '                                      +
    '       c.NIF_CLI, '                                              +
    '       c.MOVIL_CLI, '                                            +
    '       c.EMAIL_CLI, '                                            +
    '       c.DIRECCION1_CLI, '                                       +
    '       c.POBLACION_CLI, '                                        +
    '       c.PROVINCIA_CLI, '                                        +
    '       c.CODIGO_POSTAL_CLI, '                                          +
    '       c.TOTAL_DEUDA_CLI '                                       +
    '  FROM fza_clientes c '                                              +
    ' WHERE c.CODIGO_CLI_CLI = :PCLI ';

  // ------------------------------------------------------------------
  //  Pestaña DEPOSITOS: depositos tocados por esta operacion.
  //  La vista fza_caja_depositos_view devuelve hasta 3 filas por
  //  deposito (ALTA, CANCELACION, COBRO_INICIAL/COBRO_PARCIAL).
  //  Aqui las colapsamos a UNA sola fila por ID_DEPOSITO_DEP, y en
  //  ROL_EN_OPERACION concatenamos los roles que toco esta operacion.
  // ------------------------------------------------------------------
  qryDepositos.SQL.Text :=
    'SELECT d.ID_DEPOSITO_DEP, '                                      +
    '       MAX(d.CODIGO_CLI_DEP)            AS CODIGO_CLI_DEP, '     +
    '       MAX(d.CODIGO_ART_DEP)            AS CODIGO_ART_DEP, '     +
    '       MAX(d.CODIGO_UNIDAD_DEP)         AS CODIGO_UNIDAD_DEP, '  +
    '       MAX(d.CODIGO_ALM_DEP)            AS CODIGO_ALM_DEP, '     +
    '       MAX(d.CANTIDAD_PENDIENTE_DEP)    AS CANTIDAD_PENDIENTE_DEP, ' +
    '       MAX(d.PRECIO_VENTA_DEP)          AS PRECIO_VENTA_DEP, '   +
    '       MAX(d.PORCENTAJE_IVA_DEP)        AS PORCENTAJE_IVA_DEP, ' +
    '       MAX(d.IMPORTE_ANTICIPO_DEP)      AS IMPORTE_ANTICIPO_DEP, ' +
    '       MAX(d.IMPORTE_PENDIENTE_DEP)     AS IMPORTE_PENDIENTE_DEP, ' +
    '       MAX(d.ESTADO_DEP)                AS ESTADO_DEP, '         +
    '       MIN(d.FECHA_CREACION_DEP)        AS FECHA_CREACION_DEP, ' +
    '       MAX(d.FECHA_ENTREGA_DEP)         AS FECHA_ENTREGA_DEP, '  +
    '       MAX(d.EMPRESA_CANCEL_DEP)        AS EMPRESA_CANCEL_DEP, ' +
    '       MAX(d.ALMACEN_CANCEL_DEP)        AS ALMACEN_CANCEL_DEP, ' +
    '       MAX(d.CAJA_CANCEL_DEP)           AS CAJA_CANCEL_DEP, '    +
    '       MAX(d.NUMERO_OPERACION_CANCEL_DEP) AS NUMERO_OPERACION_CANCEL_DEP, '
      +
    '       GROUP_CONCAT(DISTINCT d.ROL_EN_OPERACION '                +
    '                    ORDER BY d.ROL_EN_OPERACION '                +
    '                    SEPARATOR '','')      AS ROL_EN_OPERACION '  +
    '  FROM fza_caja_depositos_view d '                               +
    ' WHERE d.CODIGO_EMPRESA_OP   = :PEMP '                           +
    '   AND d.CODIGO_ALMACEN_OP   = :PALM '                           +
    '   AND d.CODIGO_CAJA_OP      = :PCAJA '                          +
    '   AND d.NUMERO_OPERACION_OP = :PNUMOP '                         +
    ' GROUP BY d.ID_DEPOSITO_DEP '                                    +
    ' ORDER BY d.ID_DEPOSITO_DEP ';

  // ------------------------------------------------------------------
  //  Pestaña FACTURA (cabecera).
  // ------------------------------------------------------------------
  qryFactura.SQL.Text :=
    'SELECT f.SERIE_FAC, '                                            +
    '       f.NUMERO_FAC, '                                              +
    '       f.FECHA_FAC, '                                            +
    '       f.TIPO_FAC, '                                             +
    '       f.CODIGO_CLI_FAC, '                                   +
    '       f.RAZON_SOCIAL_CLIENTE_FAC, '                              +
    '       f.TOTAL_BASES_FAC, '                                      +
    '       f.TOTAL_IMPUESTOS_FAC, '                                  +
    '       f.TOTAL_LIQUIDO_FAC '                                     +
    '  FROM fza_facturas f '                                              +
    ' WHERE f.CODIGO_EMP_FAC   = :PEMP '                          +
    '   AND f.CODIGO_ALM_FAC   = :PALM '                          +
    '   AND f.CODIGO_CAJA_FAC      = :PCAJA '                         +
    '   AND f.NUMERO_OPERACION_FAC = :PNUMOP ';

  // ------------------------------------------------------------------
  //  Pestaña FACTURA (lineas).
  // ------------------------------------------------------------------
  qryFacturaLin.SQL.Text :=
    'SELECT l.LINEA_FACLIN, '                                      +
    '       l.CODIGO_ART_FACLIN, '                            +
    '       l.CODIGO_UNIDAD_FACLIN, '                              +
    '       l.DESCRIPCION_ARTICULO_FACLIN, '                       +
    '       l.CANTIDAD_FACLIN, '                                   +
    '       l.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, '                  +
    '       l.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, '                  +
    '       l.PORCENTAJE_DTO_FACLIN, '                                 +
    '       l.TIPO_IVA_ARTICULO_FACLIN, '                           +
    '       l.PORCENTAJE_IVA_FACLIN, '                                 +
    '       l.TOTAL_FAC_SIVA_FACLIN, '                                  +
    '       l.TOTAL_FACLIN '                                       +
    '  FROM fza_facturas_lineas l '                                       +
    ' WHERE l.SERIE_FAC_FACLIN            = :PSERIE '                  +
    '   AND l.NUMERO_FAC_FACLIN              = :PNROFAC '                 +
    ' ORDER BY l.LINEA_FACLIN ';
end;

procedure TdmConsultaOpe.RefrescarPestanasHijas;
var
  sEmp, sAlm, sCaja, sNumOp, sCli, sSerie, sNroFac, sClave: string;
begin
  if FCargando then
  begin
    Log.LogInfo('RefrescarPestanasHijas: BLOQUEADA por FCargando=True');
    Exit;
  end;
  if qryMaestro.IsEmpty then
  begin
    if FUltimaClaveHijas <> '' then
    begin
      Log.LogInfo('RefrescarPestanasHijas: maestro vacio, cerrando hijas');
      qryOperacion.Close;
      qryPagos.Close;
      qryVales.Close;
      qryMovimientos.Close;
      qryCliente.Close;
      qryDepositos.Close;
      qryFactura.Close;
      qryFacturaLin.Close;
      FUltimaClaveHijas := '';
    end
    else
      Log.LogInfo('RefrescarPestanasHijas: maestro vacio (no-op, ya cerradas)');
    Exit;
  end;
  sEmp    := qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm    := qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja   := qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp  := qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCli    := qryMaestro.FieldByName('CLIENTE').AsString;
  sSerie  := qryMaestro.FieldByName('SERIE_FAC').AsString;
  sNroFac := qryMaestro.FieldByName('NUMERO_FAC').AsString;
  // Escudo anti-recarga redundante: si la fila activa del maestro no ha
  // cambiado, no relanzamos las 8 queries hijas.
  sClave := sEmp + '|' + sAlm + '|' + sCaja + '|' + sNumOp;
  if sClave = FUltimaClaveHijas then
  begin
    Log.LogInfo(Format('RefrescarPestanasHijas: SKIP (misma op "%s")',
                       [sClave]));
    Exit;
  end;
  Log.LogInfo(Format('RefrescarPestanasHijas: cargando op "%s" (prev="%s")',
                     [sClave, FUltimaClaveHijas]));
  // --- Operacion ---
  qryOperacion.Close;
  qryOperacion.ParamByName('PEMP').AsString    := sEmp;
  qryOperacion.ParamByName('PALM').AsString    := sAlm;
  qryOperacion.ParamByName('PCAJA').AsString   := sCaja;
  qryOperacion.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryOperacion, 'Operaciones');

  // --- Pagos ---
  qryPagos.Close;
  qryPagos.ParamByName('PEMP').AsString    := sEmp;
  qryPagos.ParamByName('PALM').AsString    := sAlm;
  qryPagos.ParamByName('PCAJA').AsString   := sCaja;
  qryPagos.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryPagos, 'Pagos');

  // --- Vales ---
  qryVales.Close;
  qryVales.ParamByName('PEMP').AsString    := sEmp;
  qryVales.ParamByName('PALM').AsString    := sAlm;
  qryVales.ParamByName('PCAJA').AsString   := sCaja;
  qryVales.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryVales, 'Vales');

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

  // --- Depositos ---
  qryDepositos.Close;
  qryDepositos.ParamByName('PEMP').AsString    := sEmp;
  qryDepositos.ParamByName('PALM').AsString    := sAlm;
  qryDepositos.ParamByName('PCAJA').AsString   := sCaja;
  qryDepositos.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryDepositos, 'Depositos');

  // --- Factura (cabecera + lineas) ---
  qryFactura.Close;
  qryFacturaLin.Close;
  qryFactura.ParamByName('PEMP').AsString    := sEmp;
  qryFactura.ParamByName('PALM').AsString    := sAlm;
  qryFactura.ParamByName('PCAJA').AsString   := sCaja;
  qryFactura.ParamByName('PNUMOP').AsString  := sNumOp;
  AbrirSeguro(qryFactura, 'Facturas');
  if (not qryFactura.IsEmpty) and (Trim(sSerie) <> '')
     and (Trim(sNroFac) <> '') then
  begin
    qryFacturaLin.ParamByName('PSERIE').AsString  := sSerie;
    qryFacturaLin.ParamByName('PNROFAC').AsString := sNroFac;
    AbrirSeguro(qryFacturaLin, 'Lineas de Facturas');
  end;
  FUltimaClaveHijas := sClave;
end;

// -----------------------------------------------------------------------------
procedure TdmConsultaOpe.CargarMaestro(AFecha:     TDate;
                                       const AEmp,
                                             AAlm,
                                             ACaja,
                                             ATextoLibre: string);
var
  sClaveMaestro: string;
begin
  // Escudo anti-recarga del maestro: si los parametros no han cambiado,
  // no relanzamos ni el SELECT del maestro ni las 8 queries hijas. Al
  // abrir el form, PrepararValores + FormShow encadenaban hasta 3
  // CargarMaestro identicos (uno por handler de dtpFecha y otro por
  // FormShow); ahora la 2a y 3a salen sin tocar BBDD.
  sClaveMaestro := DateToStr(AFecha) + '|' + AEmp + '|' + AAlm + '|' + ACaja +
                   '|' + ATextoLibre;
  if sClaveMaestro = FUltimaClaveMaestro then
  begin
    Log.LogInfo(Format('CargarMaestro: SKIP (mismos params "%s")',
                       [sClaveMaestro]));
    Exit;
  end;
  Log.LogInfo(Format('CargarMaestro: fecha=%s emp="%s" alm="%s" caja="%s" ' +
                     'txt="%s" (prev="%s")',
                     [DateToStr(AFecha), AEmp, AAlm, ACaja, ATextoLibre,
                      FUltimaClaveMaestro]));
  // Cerramos todas las queries hijas primero para que OnDataChange no
  // dispare mientras recargamos el maestro.
  FCargando := True;
  try
    qryOperacion.Close;
    qryPagos.Close;
    qryVales.Close;
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
    // Reset del cache de clave de hijas: forzamos que la siguiente
    // RefrescarPestanasHijas SI recargue (puede ser la misma op pero con
    // datos del maestro recien releidos).
    FUltimaClaveHijas  := '';
    FUltimaClaveMaestro := sClaveMaestro;
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
      // tirar el maestro ni las demas pestañas.
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

function TdmConsultaOpe.TieneVales: Boolean;
begin
  Result := qryVales.Active and (not qryVales.IsEmpty);
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

function TdmConsultaOpe.EsOperacionCaja: Boolean;
var
  sTipos: string;
begin
  Result := False;
  if qryMaestro.IsEmpty then
    Exit;
  sTipos := qryMaestro.FieldByName('TIPOS_OP').AsString;
  Result := (Pos('EC', sTipos) > 0) or (Pos('GC', sTipos) > 0);
end;

function TdmConsultaOpe.EsTraspaso: Boolean;
var
  sTipos: string;
begin
  Result := False;
  if qryMaestro.IsEmpty then
    Exit;
  sTipos := qryMaestro.FieldByName('TIPOS_OP').AsString;
  Result := (Pos('TR', sTipos) > 0) or (Pos('TA', sTipos) > 0);
end;

end.
