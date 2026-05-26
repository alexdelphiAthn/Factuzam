{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArqueo                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla F11 del menú de caja: arqueo (cierre Z) de un rango de fechas.   }
{    Pestaña Arqueo/Resúmenes/Más datos: importes calculados (lectura).        }
{    Pestaña Recuento: grid editable con una fila por forma de pago para       }
{    que el usuario introduzca lo que ha contado. Botón Grabar Arqueo          }
{    persiste en fza_caja_arqueos + fza_caja_arqueos_recuento.                 }
{******************************************************************************}
unit inMtoModalArqueo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions, Vcl.Menus,
  System.DateUtils,
  Data.DB, MemDS, DBAccess,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxClasses, cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxPC, cxNavigator, cxDBData,
  cxCustomData, cxData, cxDataStorage, cxFilter,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  Uni,
  inMtoFrmBase, inLibArqueo, inLibArqueoTicket, inLibArqueoPersistencia,
  Vcl.ComCtrls, dxCore,
  cxDateUtils, cxCurrencyEdit, JvComponentBase, JvEnterTab, cxLocalization;

type
  TfrmModalArqueo = class(TfrmBase)
    pnlTop: TPanel;
    pnlBody: TPanel;
    pnlBottom: TPanel;

    // Pestañas
    pcArqueo: TcxPageControl;
    tsArqueo: TcxTabSheet;
    tsResumenes: TcxTabSheet;
    tsMasDatos: TcxTabSheet;

    // Más datos: rejilla resumen por IVA
    pnlResIVA: TPanel;
    lblResIVATit: TcxLabel;
    cxgrdResIVA: TcxGrid;
    tvResIVA: TcxGridDBTableView;
    tvResIVABASE: TcxGridDBColumn;
    tvResIVAPORC_IVA: TcxGridDBColumn;
    tvResIVACUOTA_IVA: TcxGridDBColumn;
    tvResIVAPORC_RE: TcxGridDBColumn;
    tvResIVACUOTA_RE: TcxGridDBColumn;
    tvResIVABASE_IVAS: TcxGridDBColumn;
    lvResIVA: TcxGridLevel;
    dsResIVA: TDataSource;
    qryResIVA: TUniQuery;

    // Resúmenes: paneles y grids (uno por agrupación)
    pnlResEmpleado: TPanel;
    lblResEmpleadoTit: TcxLabel;
    cxgrdResEmpleado: TcxGrid;
    tvResEmpleado: TcxGridDBTableView;
    tvResEmpleadoEMP: TcxGridDBColumn;
    tvResEmpleadoUDS: TcxGridDBColumn;
    tvResEmpleadoNETO: TcxGridDBColumn;
    lvResEmpleado: TcxGridLevel;
    dsResEmpleado: TDataSource;
    qryResEmpleado: TUniQuery;

    pnlResFP: TPanel;
    lblResFPTit: TcxLabel;
    cxgrdResFP: TcxGrid;
    tvResFP: TcxGridDBTableView;
    tvResFPFP: TcxGridDBColumn;
    tvResFPUDS: TcxGridDBColumn;
    tvResFPNETO: TcxGridDBColumn;
    lvResFP: TcxGridLevel;
    dsResFP: TDataSource;
    qryResFP: TUniQuery;

    pnlResFam: TPanel;
    lblResFamTit: TcxLabel;
    cxgrdResFam: TcxGrid;
    tvResFam: TcxGridDBTableView;
    tvResFamFAM: TcxGridDBColumn;
    tvResFamUDS: TcxGridDBColumn;
    tvResFamNETO: TcxGridDBColumn;
    lvResFam: TcxGridLevel;
    dsResFam: TDataSource;
    qryResFam: TUniQuery;

    pnlResProp: TPanel;
    lblResPropTit: TcxLabel;
    cxgrdResProp: TcxGrid;
    tvResProp: TcxGridDBTableView;
    tvResPropPROP: TcxGridDBColumn;
    tvResPropVAL: TcxGridDBColumn;
    tvResPropUDS: TcxGridDBColumn;
    tvResPropNETO: TcxGridDBColumn;
    lvResProp: TcxGridLevel;
    dsResProp: TDataSource;
    qryResProp: TUniQuery;

    // Cabecera (rango + ventas + accesos)
    lblTituloDesde: TcxLabel;
    dteFechaDesde: TcxDateEdit;
    lblF10: TcxLabel;
    lblTituloHasta: TcxLabel;
    dteFechaHasta: TcxDateEdit;
    lblF6: TcxLabel;
    lblTituloVentas: TcxLabel;
    lblVentas: TcxLabel;
    btnRecalcular: TcxButton;
    btnImprimir: TcxButton;

    // Sección Líneas artículos
    pnlLineas: TPanel;
    lblLineasTitulo: TcxLabel;
    lblLinBrutoLbl: TcxLabel;
    lblLinBruto: TcxLabel;
    lblLinDescuentoLbl: TcxLabel;
    lblLinDescuento: TcxLabel;
    lblLinNetoLbl: TcxLabel;
    lblLinNeto: TcxLabel;

    // Sección Operaciones
    pnlOperaciones: TPanel;
    lblOpeTitulo: TcxLabel;
    lblOpeVentasNormLbl: TcxLabel;
    lblOpeVentasNorm: TcxLabel;
    lblOpeVentasPrestLbl: TcxLabel;
    lblOpeVentasPrest: TcxLabel;
    lblOpeDevolLbl: TcxLabel;
    lblOpeDevol: TcxLabel;
    lblOpeTotalVentasLbl: TcxLabel;
    lblOpeTotalVentas: TcxLabel;

    // Sección Cobros
    pnlCobros: TPanel;
    lblCobrosTitulo: TcxLabel;
    lblCobValesRecLbl: TcxLabel;
    lblCobValesRec: TcxLabel;
    lblCobValesEmiLbl: TcxLabel;
    lblCobValesEmi: TcxLabel;
    lblCobClientesLbl: TcxLabel;
    lblCobClientes: TcxLabel;
    lblCobPendienteLbl: TcxLabel;
    lblCobPendiente: TcxLabel;
    lblCobIngresosLbl: TcxLabel;
    lblCobIngresos: TcxLabel;

    lblEftIngresosLbl: TcxLabel;
    lblEftIngresos: TcxLabel;
    lblEftEntradasLbl: TcxLabel;
    lblEftEntradas: TcxLabel;
    lblEftSalidasLbl: TcxLabel;
    lblEftSalidas: TcxLabel;
    lblEftAnteriorLbl: TcxLabel;
    lblEftAnterior: TcxLabel;
    lblEftCajaLbl: TcxLabel;
    lblEftCaja: TcxLabel;
    lblTarjetasLbl: TcxLabel;
    lblTarjetas: TcxLabel;
    lblSaldoLbl: TcxLabel;
    lblSaldo: TcxLabel;

    // Pestaña Recuento
    tsRecuento: TcxTabSheet;
    pnlRecuento: TPanel;
    lblRecuentoTit: TcxLabel;
    cxgrdRecuento: TcxGrid;
    tvRecuento: TcxGridTableView;
    tvRecuentoFP: TcxGridColumn;
    tvRecuentoDesc: TcxGridColumn;
    tvRecuentoSistema: TcxGridColumn;
    tvRecuentoImporte: TcxGridColumn;
    tvRecuentoDiferencia: TcxGridColumn;
    lvRecuento: TcxGridLevel;
    pnlRecuentoTotales: TPanel;
    lblRecTotalSistemaLbl: TcxLabel;
    lblRecTotalSistema: TcxLabel;
    lblRecTotalRecuentoLbl: TcxLabel;
    lblRecTotalRecuento: TcxLabel;
    lblRecDiferenciaLbl: TcxLabel;
    lblRecDiferencia: TcxLabel;
    txtObservaciones: TcxTextEdit;
    lblObservacionesLbl: TcxLabel;
    btnGrabarArqueo: TcxButton;

    // Pie
    btnAtras: TcxButton;
    lblESC: TcxLabel;

    // Acciones de teclado
    alArqueo: TActionList;
    actEscape: TAction;
    actRecalcular: TAction;
    actImprimir: TAction;
    actGrabar: TAction;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAtrasClick(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnGrabarArqueoClick(Sender: TObject);
    procedure actEscapeExecute(Sender: TObject);
    procedure actRecalcularExecute(Sender: TObject);
    procedure actImprimirExecute(Sender: TObject);
    procedure actGrabarExecute(Sender: TObject);
    procedure dteFechaDesdePropertiesChange(Sender: TObject);
    procedure dteFechaHastaPropertiesChange(Sender: TObject);
    procedure tvRecuentoImportePropertiesEditValueChanged(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
  private
    FConn         : TUniConnection;
    FEmpresa      : string;
    FAlmacen      : string;
    FCaja         : string;
    FArqueoActual : TArqueoCaja;
    procedure RellenarPantalla(const AArqueo: TArqueoCaja);
    procedure Recalcular;
    procedure ConfigurarResumenes;
    procedure RefrescarResumenes;
    procedure AbrirQryConParams(Q: TUniQuery);
    function  FormatImporte(AValor: Currency): string;
    procedure CargarRecuento(const AArqueo: TArqueoCaja);
    procedure RecalcularTotalesRecuento;
    procedure GrabarArqueo;
  public
    class procedure Ejecutar(AOwner       : TComponent;
                             AConn        : TUniConnection;
                             const AEmpresa : string;
                             const AAlmacen : string;
                             const ACaja    : string;
                             AFechaDesde    : TDate;
                             AFechaHasta    : TDate);
  end;

implementation

{$R *.dfm}

uses inLibGlobalVar;

procedure ForceReferenceToClass(C: TClass); begin end;

// =============================================================================
//   API pública
// =============================================================================

class procedure TfrmModalArqueo.Ejecutar(AOwner       : TComponent;
                                         AConn        : TUniConnection;
                                         const AEmpresa : string;
                                         const AAlmacen : string;
                                         const ACaja    : string;
                                         AFechaDesde    : TDate;
                                         AFechaHasta    : TDate);
var
  frm: TfrmModalArqueo;
begin
  frm := TfrmModalArqueo.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    // Defaults: desde = 00:00:00, hasta = 23:59:59 del mismo día/rango.
    frm.dteFechaDesde.Date := DateOf(AFechaDesde);
    frm.dteFechaHasta.Date := DateOf(AFechaHasta) + EncodeTime(23, 59, 59, 0);
    frm.Recalcular;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

// =============================================================================
//   Eventos
// =============================================================================

procedure TfrmModalArqueo.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  ConfigurarResumenes;
end;

procedure TfrmModalArqueo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmModalArqueo.btnAtrasClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueo.btnRecalcularClick(Sender: TObject);
begin
  inherited;
  Recalcular;
end;

procedure TfrmModalArqueo.btnImprimirClick(Sender: TObject);
begin
  inherited;
  actImprimirExecute(Sender);
end;

procedure TfrmModalArqueo.actImprimirExecute(Sender: TObject);
begin
  inherited;
  if (FConn = nil) or (not FConn.Connected) then Exit;
  Screen.Cursor := crHourGlass;
  try
    TArqueoTicket.Imprimir(FConn, FEmpresa, FAlmacen, FCaja,
                           dteFechaDesde.Date, dteFechaHasta.Date,
                           oNomImpresoraCaja);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalArqueo.actEscapeExecute(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueo.actRecalcularExecute(Sender: TObject);
begin
  inherited;
  Recalcular;
end;

procedure TfrmModalArqueo.dteFechaDesdePropertiesChange(Sender: TObject);
begin
  inherited;
  // Fuerza que "hasta" no quede antes que "desde"
  if dteFechaHasta.Date < dteFechaDesde.Date then
    dteFechaHasta.Date := dteFechaDesde.Date;
end;

procedure TfrmModalArqueo.dteFechaHastaPropertiesChange(Sender: TObject);
begin
  inherited;
  if dteFechaHasta.Date < dteFechaDesde.Date then
    dteFechaHasta.Date := dteFechaDesde.Date;
end;

// =============================================================================
//   Lógica interna
// =============================================================================

procedure TfrmModalArqueo.Recalcular;
begin
  Screen.Cursor := crHourGlass;
  try
    FArqueoActual := TArqueoCalculadora.Calcular(FConn,
                                                  FEmpresa,
                                                  FAlmacen,
                                                  FCaja,
                                                  dteFechaDesde.Date,
                                                  dteFechaHasta.Date);
    RellenarPantalla(FArqueoActual);
    CargarRecuento(FArqueoActual);
    RefrescarResumenes;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// =============================================================================
//   Resúmenes (pestaña 2)
// =============================================================================

procedure TfrmModalArqueo.ConfigurarResumenes;
begin
  // Empleado: 1 fila por CODIGO_EMPLEADO_OPCAJA. Mide unidades de venta
  // (operaciones distintas) y el neto vendido.
  qryResEmpleado.SQL.Text :=
    ' SELECT                                                              ' +
    '   COALESCE(o.CODIGO_EMPLEADO_OPCAJA, ''?'')   AS EMPLEADO,          ' +
    '   COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA)  AS UDS,                ' +
    '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0)   AS NETO                ' +
    '   FROM fza_caja_operaciones o                                       ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
    '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
    '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
    '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
    '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
    '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ' +
    '  GROUP BY o.CODIGO_EMPLEADO_OPCAJA                                  ' +
    '  ORDER BY o.CODIGO_EMPLEADO_OPCAJA                                  ';

  // Forma de pago: 1 fila por CODIGO_FP_CFP (EFE/TARJ/BONO/USD/BTC/...). Mide
  // unidades = nº de pagos, e importe total entregado.
  qryResFP.SQL.Text :=
    ' SELECT                                                              ' +
    '   p.CODIGO_FP_CFP                          AS FP,                   ' +
    '   COUNT(*)                                 AS UDS,                  ' +
    '   COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO),0) AS NETO                 ' +
    '   FROM fza_caja_pagos        p                                      ' +
    '   JOIN fza_caja_operaciones  o                                      ' +
    '     ON o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO                ' +
    '    AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO                ' +
    '    AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO               ' +
    '    AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO          ' +
    '  WHERE p.CODIGO_EMP_PAGO      = :pEMPRESA                           ' +
    '    AND p.CODIGO_ALM_PAGO      = :pALMACEN                           ' +
    '    AND p.CODIGO_CAJA_PAGO     = :pCAJA                              ' +
    '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                            ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                            ' +
    '  GROUP BY p.CODIGO_FP_CFP                                           ' +
    '  ORDER BY p.CODIGO_FP_CFP                                           ';

  // Familia: nombre = "PADRE-HIJO" si la familia tiene padre (vía
  // CODIGO_SUBFAMILIA_FAM = código del padre), si no = nombre de la familia.
  // Las líneas de factura no siempre tienen CODIGO_FAM_FACLIN poblado, así
  // que tiramos también de fza_articulos.CODIGO_FAM_ART como fallback.
  qryResFam.SQL.Text :=
    ' SELECT                                                              ' +
    '   CASE                                                              ' +
    '     WHEN p.NOMBRE_FAM_FAM IS NOT NULL                               ' +
    '     THEN CONCAT(p.NOMBRE_FAM_FAM, ''-'', f.NOMBRE_FAM_FAM)          ' +
    '     ELSE COALESCE(f.NOMBRE_FAM_FAM, l.NOMBRE_FAM_FACLIN,            ' +
    '                   l.CODIGO_FAM_FACLIN, a.CODIGO_FAM_ART,            ' +
    '                   ''(sin familia)'')                                ' +
    '   END                                       AS FAMILIA,             ' +
    '   COUNT(*)                                  AS UDS,                 ' +
    '   COALESCE(SUM(l.TOTAL_FACLIN), 0)          AS NETO                 ' +
    '   FROM fza_caja_operaciones o                                       ' +
    '   JOIN fza_facturas_lineas  l                                       ' +
    '     ON l.CODIGO_EMP_FACLIN        = o.CODIGO_EMP_OPCAJA             ' +
    '    AND l.CODIGO_ALM_FACLIN        = o.CODIGO_ALM_OPCAJA             ' +
    '    AND l.CODIGO_CAJA_FACLIN       = o.CODIGO_CAJA_OPCAJA            ' +
    '    AND l.NUMERO_OPERACION_FACLIN  = o.NUMERO_OPERACION_OPCAJA       ' +
    '   LEFT JOIN fza_articulos a                                         ' +
    '     ON a.CODIGO_ART_ART = l.CODIGO_ART_FACLIN                       ' +
    '   LEFT JOIN fza_articulos_familias f                                ' +
    '     ON f.CODIGO_FAM_FAM = COALESCE(l.CODIGO_FAM_FACLIN,             ' +
    '                                    a.CODIGO_FAM_ART)                ' +
    '   LEFT JOIN fza_articulos_familias p                                ' +
    '     ON p.CODIGO_FAM_FAM = f.CODIGO_SUBFAMILIA_FAM                   ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
    '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
    '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
    '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
    '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
    '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ' +
    '  GROUP BY FAMILIA                                                   ' +
    '  ORDER BY FAMILIA                                                   ';

  // IVA (pestaña Más datos): 4 filas, una por tipo de IVA (Normal, Reducido,
  // Super Reducido, Exento). Se toma de fza_facturas SOLO las
  // SIMPLIFICADAS — incluye también las facturas asociadas a operaciones
  // de depósito (apertura "Depósito: Abono") que llevan su propio IVA.
  // Filtro por f.CODIGO_EMP/ALM/CAJA_FAC directamente y por f.FECHA_FAC,
  // sin pasar por fza_caja_operaciones (evita multiplicar totales cuando
  // una operación tiene varias filas — DE+VE+CB en un cierre).
  qryResIVA.SQL.Text :=
    ' SELECT ORD, TIPO, PORC_IVA, BASE, CUOTA_IVA, PORC_RE, CUOTA_RE,      ' +
    '        (BASE + CUOTA_IVA + CUOTA_RE) AS BASE_IVAS                    ' +
    ' FROM (                                                               ' +
    '   SELECT 1 AS ORD, ''N'' AS TIPO,                                    ' +
    '          MAX(f.PORCENTAJE_IVAN_FAC)                AS PORC_IVA,      ' +
    '          COALESCE(SUM(f.TOTAL_BASEI_IVAN_FAC), 0)  AS BASE,          ' +
    '          COALESCE(SUM(f.TOTAL_IVAN_FAC), 0)        AS CUOTA_IVA,     ' +
    '          MAX(f.PORCENTAJE_REN_FAC)                 AS PORC_RE,       ' +
    '          COALESCE(SUM(f.TOTAL_REN_FAC), 0)         AS CUOTA_RE       ' +
    '     FROM fza_facturas f                                              ' +
    '    WHERE f.TIPO_FAC        = ''SIMPLIFICADA''                        ' +
    '      AND f.CODIGO_EMP_FAC  = :pEMPRESA                               ' +
    '      AND f.CODIGO_ALM_FAC  = :pALMACEN                               ' +
    '      AND f.CODIGO_CAJA_FAC = :pCAJA                                  ' +
    '      AND f.FECHA_FAC      >= :pFDESDE                                ' +
    '      AND f.FECHA_FAC      <= :pFHASTA                                ' +
    '   UNION ALL                                                          ' +
    '   SELECT 2, ''R'',                                                   ' +
    '          MAX(f.PORCENTAJE_IVAR_FAC),                                 ' +
    '          COALESCE(SUM(f.TOTAL_BASEI_IVAR_FAC), 0),                   ' +
    '          COALESCE(SUM(f.TOTAL_IVAR_FAC), 0),                         ' +
    '          MAX(f.PORCENTAJE_RER_FAC),                                  ' +
    '          COALESCE(SUM(f.TOTAL_RER_FAC), 0)                           ' +
    '     FROM fza_facturas f                                              ' +
    '    WHERE f.TIPO_FAC        = ''SIMPLIFICADA''                        ' +
    '      AND f.CODIGO_EMP_FAC  = :pEMPRESA                               ' +
    '      AND f.CODIGO_ALM_FAC  = :pALMACEN                               ' +
    '      AND f.CODIGO_CAJA_FAC = :pCAJA                                  ' +
    '      AND f.FECHA_FAC      >= :pFDESDE                                ' +
    '      AND f.FECHA_FAC      <= :pFHASTA                                ' +
    '   UNION ALL                                                          ' +
    '   SELECT 3, ''S'',                                                   ' +
    '          MAX(f.PORCENTAJE_IVAS_FAC),                                 ' +
    '          COALESCE(SUM(f.TOTAL_BASEI_IVAS_FAC), 0),                   ' +
    '          COALESCE(SUM(f.TOTAL_IVAS_FAC), 0),                         ' +
    '          MAX(f.PORCENTAJE_RES_FAC),                                  ' +
    '          COALESCE(SUM(f.TOTAL_RES_FAC), 0)                           ' +
    '     FROM fza_facturas f                                              ' +
    '    WHERE f.TIPO_FAC        = ''SIMPLIFICADA''                        ' +
    '      AND f.CODIGO_EMP_FAC  = :pEMPRESA                               ' +
    '      AND f.CODIGO_ALM_FAC  = :pALMACEN                               ' +
    '      AND f.CODIGO_CAJA_FAC = :pCAJA                                  ' +
    '      AND f.FECHA_FAC      >= :pFDESDE                                ' +
    '      AND f.FECHA_FAC      <= :pFHASTA                                ' +
    '   UNION ALL                                                          ' +
    '   SELECT 4, ''E'',                                                   ' +
    '          MAX(f.PORCENTAJE_IVAE_FAC),                                 ' +
    '          COALESCE(SUM(f.TOTAL_BASEI_IVAE_FAC), 0),                   ' +
    '          COALESCE(SUM(f.TOTAL_IVAE_FAC), 0),                         ' +
    '          MAX(f.PORCENTAJE_REE_FAC),                                  ' +
    '          COALESCE(SUM(f.TOTAL_REE_FAC), 0)                           ' +
    '     FROM fza_facturas f                                              ' +
    '    WHERE f.TIPO_FAC        = ''SIMPLIFICADA''                        ' +
    '      AND f.CODIGO_EMP_FAC  = :pEMPRESA                               ' +
    '      AND f.CODIGO_ALM_FAC  = :pALMACEN                               ' +
    '      AND f.CODIGO_CAJA_FAC = :pCAJA                                  ' +
    '      AND f.FECHA_FAC      >= :pFDESDE                                ' +
    '      AND f.FECHA_FAC      <= :pFHASTA                                ' +
    ' ) ivas                                                               ' +
    ' WHERE BASE <> 0 OR CUOTA_IVA <> 0 OR CUOTA_RE <> 0                   ' +
    ' ORDER BY ORD                                                         ';

  // Propiedad: 1 fila por (propiedad, valor). Suma sobre las líneas de venta
  // los TOTAL_FACLIN agregados al CODIGO_ART. Si la propiedad es de tipo
  // LISTA, el valor sale de fza_propiedades_valores.PV; si es libre, de
  // VALOR_LIBRE_ARTPROP.
  qryResProp.SQL.Text :=
    ' SELECT                                                              ' +
    '   ap.CODIGO_PROP_ARTPROP                                  AS PROP,  ' +
    '   COALESCE(pv.PV, ap.VALOR_LIBRE_ARTPROP, ''?'')          AS VALOR, ' +
    '   COUNT(*)                                                AS UDS,   ' +
    '   COALESCE(SUM(l.TOTAL_FACLIN), 0)                        AS NETO   ' +
    '   FROM fza_caja_operaciones        o                                ' +
    '   JOIN fza_facturas_lineas         l                                ' +
    '     ON l.CODIGO_EMP_FACLIN        = o.CODIGO_EMP_OPCAJA             ' +
    '    AND l.CODIGO_ALM_FACLIN        = o.CODIGO_ALM_OPCAJA             ' +
    '    AND l.CODIGO_CAJA_FACLIN       = o.CODIGO_CAJA_OPCAJA            ' +
    '    AND l.NUMERO_OPERACION_FACLIN  = o.NUMERO_OPERACION_OPCAJA       ' +
    '   JOIN fza_articulos_propiedades   ap                               ' +
    '     ON ap.CODIGO_ART_ART = l.CODIGO_ART_FACLIN                      ' +
    '   LEFT JOIN fza_propiedades_valores pv                              ' +
    '     ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP                          ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
    '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
    '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
    '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
    '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
    '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ' +
    '  GROUP BY ap.CODIGO_PROP_ARTPROP, VALOR                             ' +
    '  ORDER BY ap.CODIGO_PROP_ARTPROP, VALOR                             ';
end;

procedure TfrmModalArqueo.AbrirQryConParams(Q: TUniQuery);
begin
  if Q.Active then Q.Close;
  Q.Connection := FConn;
  Q.ParamByName('pEMPRESA').AsString := FEmpresa;
  Q.ParamByName('pALMACEN').AsString := FAlmacen;
  Q.ParamByName('pCAJA').AsString    := FCaja;
  Q.ParamByName('pFDESDE').AsDateTime    := dteFechaDesde.Date;
  Q.ParamByName('pFHASTA').AsDateTime    := dteFechaHasta.Date;
  Q.Open;
end;

procedure TfrmModalArqueo.RefrescarResumenes;
begin
  if (FConn = nil) or (not FConn.Connected) then Exit;
  AbrirQryConParams(qryResEmpleado);
  AbrirQryConParams(qryResFP);
  AbrirQryConParams(qryResFam);
  AbrirQryConParams(qryResProp);
  AbrirQryConParams(qryResIVA);
end;

procedure TfrmModalArqueo.RellenarPantalla(const AArqueo: TArqueoCaja);
begin
  lblVentas.Caption          := IntToStr(AArqueo.CantidadVentas);

  lblLinBruto.Caption        := FormatImporte(AArqueo.BrutoLineas);
  lblLinDescuento.Caption    := FormatImporte(AArqueo.DescuentosLineas);
  lblLinNeto.Caption         := FormatImporte(AArqueo.NetoLineas);

  lblOpeVentasNorm.Caption    := FormatImporte(AArqueo.VentasNormales);
  lblOpeVentasPrest.Caption   := FormatImporte(AArqueo.VentasPrestamos);
  lblOpeDevol.Caption         := FormatImporte(AArqueo.Devoluciones);
  lblOpeTotalVentas.Caption   := FormatImporte(AArqueo.TotalVentas);

  lblCobValesRec.Caption     := FormatImporte(AArqueo.ValesRecogidos);
  lblCobValesEmi.Caption     := FormatImporte(AArqueo.ValesEmitidos);
  lblCobClientes.Caption     := FormatImporte(AArqueo.CobrosClientes);
  lblCobPendiente.Caption    := FormatImporte(AArqueo.PendienteCobro);
  lblCobIngresos.Caption     := FormatImporte(AArqueo.IngresosCaja);

  lblEftIngresos.Caption     := FormatImporte(AArqueo.EfectivoIngresos);
  lblEftEntradas.Caption     := FormatImporte(AArqueo.EfectivoEntradas);
  lblEftSalidas.Caption      := FormatImporte(AArqueo.EfectivoSalidas);
  lblEftAnterior.Caption     := FormatImporte(AArqueo.EfectivoAnterior);
  lblEftCaja.Caption         := FormatImporte(AArqueo.EfectivoCaja);
  lblTarjetas.Caption        := FormatImporte(AArqueo.OtrosIngresos);
  lblSaldo.Caption           := FormatImporte(AArqueo.SaldoRecontar);
end;

function TfrmModalArqueo.FormatImporte(AValor: Currency): string;
begin
  if AValor = 0 then
    Result := ''
  else
    Result := FormatFloat(',0.00', AValor);
end;

// =============================================================================
//   Recuento
// =============================================================================

procedure TfrmModalArqueo.CargarRecuento(const AArqueo: TArqueoCaja);
var
  i: Integer;
begin
  tvRecuento.BeginUpdate;
  try
    tvRecuento.DataController.RecordCount := 0;
    tvRecuento.DataController.RecordCount := Length(AArqueo.PagosPorForma);
    for i := 0 to High(AArqueo.PagosPorForma) do
    begin
      tvRecuento.DataController.Values[i, tvRecuentoFP.Index] :=
        AArqueo.PagosPorForma[i].Codigo;
      tvRecuento.DataController.Values[i, tvRecuentoDesc.Index] :=
        AArqueo.PagosPorForma[i].Descripcion;
      tvRecuento.DataController.Values[i, tvRecuentoSistema.Index] :=
        Double(AArqueo.PagosPorForma[i].Importe);
      tvRecuento.DataController.Values[i, tvRecuentoImporte.Index] :=
        Double(0);
      tvRecuento.DataController.Values[i, tvRecuentoDiferencia.Index] :=
        Double(0) - Double(AArqueo.PagosPorForma[i].Importe);
    end;
  finally
    tvRecuento.EndUpdate;
  end;
  RecalcularTotalesRecuento;
end;

procedure TfrmModalArqueo.RecalcularTotalesRecuento;
var
  i: Integer;
  dSistema, dRecuento, dDif: Double;
  v: Variant;
begin
  dSistema  := 0;
  dRecuento := 0;
  for i := 0 to tvRecuento.DataController.RecordCount - 1 do
  begin
    v := tvRecuento.DataController.Values[i, tvRecuentoSistema.Index];
    if not VarIsNull(v) then
      dSistema := dSistema + Double(v);
    v := tvRecuento.DataController.Values[i, tvRecuentoImporte.Index];
    if not VarIsNull(v) then
      dRecuento := dRecuento + Double(v);
  end;
  dDif := dRecuento - dSistema;
  lblRecTotalSistema.Caption  := FormatFloat(',0.00', dSistema);
  lblRecTotalRecuento.Caption := FormatFloat(',0.00', dRecuento);
  lblRecDiferencia.Caption    := FormatFloat(',0.00', dDif);
  if dDif < 0 then
    lblRecDiferencia.Style.TextColor := clRed
  else if dDif > 0 then
    lblRecDiferencia.Style.TextColor := clGreen
  else
    lblRecDiferencia.Style.TextColor := clWindowText;
end;

procedure TfrmModalArqueo.tvRecuentoImportePropertiesEditValueChanged(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
var
  iRow: Integer;
  dSistema, dRecuento, dDif: Double;
  v: Variant;
begin
  { Solo recalcular si se editó la columna de recuento }
  if AItem <> tvRecuentoImporte then
    Exit;
  iRow := tvRecuento.DataController.FocusedRecordIndex;
  if iRow < 0 then
    Exit;
  dSistema  := 0;
  dRecuento := 0;
  v := tvRecuento.DataController.Values[
         iRow, tvRecuentoSistema.Index];
  if not VarIsNull(v) then
    dSistema := Double(v);
  v := tvRecuento.DataController.Values[
         iRow, tvRecuentoImporte.Index];
  if not VarIsNull(v) then
    dRecuento := Double(v);
  dDif := dRecuento - dSistema;
  tvRecuento.DataController.Values[
    iRow, tvRecuentoDiferencia.Index] := dDif;
  RecalcularTotalesRecuento;
end;

procedure TfrmModalArqueo.btnGrabarArqueoClick(Sender: TObject);
begin
  inherited;
  actGrabarExecute(Sender);
end;

procedure TfrmModalArqueo.actGrabarExecute(Sender: TObject);
begin
  inherited;
  GrabarArqueo;
end;

procedure TfrmModalArqueo.GrabarArqueo;
var
  Lineas: TArray<TArqueoRecuentoLinea>;
  i: Integer;
  dTotalRecuento, dDiferenciaTotal: Currency;
  dTotalSistema: Currency;
  sObs: string;
  v: Variant;
begin
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  if tvRecuento.DataController.RecordCount = 0 then
  begin
    Application.MessageBox(
      'No hay datos de recuento. Pulse Recalcular primero.',
      'Aviso', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if Application.MessageBox(
       'Se va a grabar el arqueo con los importes recontados.' +
       #13#10 +
       'Las operaciones del rango quedarán marcadas.' +
       #13#10#13#10 +
       '¿Desea continuar?',
       'Confirmar Arqueo',
       MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    SetLength(Lineas, tvRecuento.DataController.RecordCount);
    dTotalSistema  := 0;
    dTotalRecuento := 0;
    for i := 0 to High(Lineas) do
    begin
      Lineas[i].CodigoFP := VarToStr(
        tvRecuento.DataController.Values[
          i, tvRecuentoFP.Index]);
      Lineas[i].Descripcion := VarToStr(
        tvRecuento.DataController.Values[
          i, tvRecuentoDesc.Index]);
      if (i <= High(FArqueoActual.PagosPorForma)) and
         FArqueoActual.PagosPorForma[i].EsEfectivo then
        Lineas[i].EsCajon := 'S'
      else
        Lineas[i].EsCajon := 'N';
      v := tvRecuento.DataController.Values[
             i, tvRecuentoSistema.Index];
      if not VarIsNull(v) then
        Lineas[i].Sistema := Currency(Double(v))
      else
        Lineas[i].Sistema := 0;
      v := tvRecuento.DataController.Values[
             i, tvRecuentoImporte.Index];
      if not VarIsNull(v) then
        Lineas[i].Recuento := Currency(Double(v))
      else
        Lineas[i].Recuento := 0;
      Lineas[i].Diferencia :=
        Lineas[i].Recuento - Lineas[i].Sistema;
      dTotalSistema  := dTotalSistema  + Lineas[i].Sistema;
      dTotalRecuento := dTotalRecuento + Lineas[i].Recuento;
    end;
    dDiferenciaTotal := dTotalRecuento - dTotalSistema;
    sObs := Trim(txtObservaciones.Text);
    TArqueoPersistencia.GrabarArqueo(
      FConn,
      FArqueoActual,
      Lineas,
      dTotalRecuento,
      dDiferenciaTotal,
      sObs,
      oUser);
    Application.MessageBox(
      'Arqueo grabado correctamente.',
      'Información', MB_OK or MB_ICONINFORMATION);
  finally
    Screen.Cursor := crDefault;
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalArqueo);
end.
