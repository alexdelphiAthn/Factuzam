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
  cxDateUtils, cxCurrencyEdit, cxSpinEdit, cxRadioGroup,
  JvComponentBase, JvEnterTab, cxLocalization, cxGroupBox;

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
    lblTituloHasta: TcxLabel;
    dteFechaHasta: TcxDateEdit;
    lblTituloVentas: TcxLabel;
    lblVentas: TcxLabel;
    btnRecalcular: TcxButton;
    btnImprimir: TcxButton;
    btnHistorico: TcxButton;

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
    // -- Sección 1: Resto día anterior
    pnlAnterior: TPanel;
    lblAnteriorTit: TcxLabel;
    lblAnteriorImporte: TcxLabel;
    // -- Sección 2: Billetes y monedas
    pnlBilletes: TPanel;
    lblBilletesTit: TcxLabel;
    cxgrdBilletes: TcxGrid;
    tvBilletes: TcxGridTableView;
    tvBilletesDenom: TcxGridColumn;
    tvBilletesUds: TcxGridColumn;
    tvBilletesSubtotal: TcxGridColumn;
    lvBilletes: TcxGridLevel;
    lblTotalEfectivo: TcxLabel;
    // -- Sección 3: Otras formas de pago
    pnlOtrasFP: TPanel;
    lblOtrasFPTit: TcxLabel;
    cxgrdRecuento: TcxGrid;
    tvRecuento: TcxGridTableView;
    tvRecuentoFP: TcxGridColumn;
    tvRecuentoDesc: TcxGridColumn;
    tvRecuentoSistema: TcxGridColumn;
    tvRecuentoImporte: TcxGridColumn;
    tvRecuentoDiferencia: TcxGridColumn;
    lvRecuento: TcxGridLevel;
    // -- Sección 4: Totales + Retirada + Dejo mañana
    pnlRecuentoTotales: TPanel;
    lblDesgloseEfectivo: TcxLabel;
    lblRecTotalSistemaLbl: TcxLabel;
    lblRecTotalSistema: TcxLabel;
    lblRecTotalRecuentoLbl: TcxLabel;
    lblRecTotalRecuento: TcxLabel;
    lblRecDiferenciaLbl: TcxLabel;
    lblRecDiferencia: TcxLabel;
    lblRetiradaLbl: TcxLabel;
    rgRetiradaTipo: TcxRadioGroup;
    txtRetiradaImporte: TcxCurrencyEdit;
    lblDejoLbl: TcxLabel;
    lblDejoImporte: TcxLabel;
    txtObservaciones: TcxTextEdit;
    lblObservacionesLbl: TcxLabel;
    lblVendedorLbl: TcxLabel;
    txtVendedorCodigo: TcxTextEdit;
    lblVendedorNombre: TcxLabel;
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
    actDesplegarDesde: TAction;
    actDesplegarHasta: TAction;
    actHistorico: TAction;
    actTiraCaja: TAction;
    btnTiraCaja: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAtrasClick(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnHistoricoClick(Sender: TObject);
    procedure btnTiraCajaClick(Sender: TObject);
    procedure btnGrabarArqueoClick(Sender: TObject);
    procedure actEscapeExecute(Sender: TObject);
    procedure actRecalcularExecute(Sender: TObject);
    procedure actImprimirExecute(Sender: TObject);
    procedure actHistoricoExecute(Sender: TObject);
    procedure actTiraCajaExecute(Sender: TObject);
    procedure actGrabarExecute(Sender: TObject);
    procedure actDesplegarDesdeExecute(Sender: TObject);
    procedure actDesplegarHastaExecute(Sender: TObject);
    procedure dteFechaDesdePropertiesChange(Sender: TObject);
    procedure dteFechaHastaPropertiesChange(Sender: TObject);
    procedure tvRecuentoImportePropertiesEditValueChanged(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvBilletesUdsEditValueChanged(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvBilletesKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure tvRecuentoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure txtRetiradaImportePropertiesChange(Sender: TObject);
    procedure txtVendedorCodigoExit(Sender: TObject);
  private
    FConn         : TUniConnection;
    FEmpresa      : string;
    FAlmacen      : string;
    FCaja         : string;
    FArqueoActual : TArqueoCaja;
    function  FechaEditada(AEdit: TcxDateEdit): TDateTime;
    function  FechaDesdeSeleccionada: TDateTime;
    function  FechaHastaSeleccionada: TDateTime;
    procedure RellenarPantalla(const AArqueo: TArqueoCaja);
    procedure Recalcular;
    procedure ConfigurarResumenes;
    procedure RefrescarResumenes;
    procedure AbrirQryConParams(Q: TUniQuery);
    function  FormatImporte(AValor: Currency): string;
    procedure CargarBilletes;
    procedure CargarRecuento(const AArqueo: TArqueoCaja);
    procedure RecalcularTotalEfectivo;
    procedure RecalcularTotalesRecuento;
    procedure RecalcularDejoManana;
    function  ObtenerDesgloseBilletes: string;
    function  ObtenerTotalEfectivoBilletes: Currency;
    function  ObtenerConceptoRetirada: string;
    function  BuscarNombreVendedor(const ACodigo: string): string;
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

uses inLibGlobalVar, inLibPermisos, inLibLog, inMtoModalArqueosHistCaja,
     inLibCajaParam, inLibTiraCajaTicket, inMtoModalTiraCaja, inLibVerifactu;

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
    frm.dteFechaDesde.EditValue := DateOf(AFechaDesde);
    frm.dteFechaHasta.EditValue :=
      DateOf(AFechaHasta) + EncodeTime(23, 59, 59, 0);
    // Permisos
    if Assigned(oPermisos) then
    begin
      if not oPermisos.TienePermiso('caja.cambiarFecha') then
      begin
        frm.dteFechaDesde.Properties.ReadOnly := True;
        frm.dteFechaHasta.Properties.ReadOnly := True;
      end;
      if not oPermisos.TienePermiso('arqueo.verImportes') then
      begin
        // Ocultar importes en recuento; solo salen en el ticket de cierre
        frm.tvRecuentoSistema.Visible := False;
        frm.tvRecuentoImporte.Visible := False;
        frm.tvRecuentoDiferencia.Visible := False;
      end;
    end;
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

function TfrmModalArqueo.FechaEditada(AEdit: TcxDateEdit): TDateTime;
var
  vFecha: Variant;
begin
  vFecha := AEdit.EditValue;
  if VarIsNull(vFecha) or VarIsEmpty(vFecha) then
    Result := AEdit.Date
  else
    Result := VarToDateTime(vFecha);
end;

function TfrmModalArqueo.FechaDesdeSeleccionada: TDateTime;
begin
  Result := FechaEditada(dteFechaDesde);
end;

function TfrmModalArqueo.FechaHastaSeleccionada: TDateTime;
begin
  Result := FechaEditada(dteFechaHasta);
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
                           FechaDesdeSeleccionada,
                           FechaHastaSeleccionada,
                           oNomImpresoraCaja);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalArqueo.btnHistoricoClick(Sender: TObject);
begin
  inherited;
  actHistoricoExecute(Sender);
end;

procedure TfrmModalArqueo.actHistoricoExecute(Sender: TObject);
begin
  inherited;
  // Pantalla de histórico de arqueos de esta caja: reemite duplicados del
  // ticket o del cierre ya grabados, sin recalcular.
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  TfrmModalArqueosHistCaja.Ejecutar(Self, FConn, FEmpresa, FAlmacen, FCaja);
end;

procedure TfrmModalArqueo.btnTiraCajaClick(Sender: TObject);
begin
  inherited;
  actTiraCajaExecute(Sender);
end;

procedure TfrmModalArqueo.actTiraCajaExecute(Sender: TObject);
var
  Series: TArray<string>;
  sSerie: string;
  bQR, bVerifactu, bMostrar: Boolean;
begin
  inherited;
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  // Series facturadas en el rango; si no hay ninguna, no hay tira que sacar.
  Series := TTiraCajaTicket.ObtenerSeries(FConn, FEmpresa, FAlmacen, FCaja,
                                          FechaDesdeSeleccionada,
                                          FechaHastaSeleccionada);
  if Length(Series) = 0 then
  begin
    Application.MessageBox(
      'No hay operaciones facturadas en el rango seleccionado.',
      'Tira de Caja', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  // El QR solo aplica con Verifactu activo (envío PRE o PRO).
  bVerifactu := VerifactuActivo;
  sSerie     := '';
  bQR        := False;
  // Se pregunta la serie cuando hay más de una; también se abre el diálogo si
  // hay opción de QR. Con una sola serie y sin Verifactu, se imprime directo.
  bMostrar := (Length(Series) > 1) or bVerifactu;
  if bMostrar then
  begin
    if not TfrmModalTiraCaja.Ejecutar(Self, FCaja, Series, bVerifactu,
                                      sSerie, bQR) then
      Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    TTiraCajaTicket.Imprimir(FConn, FEmpresa, FAlmacen, FCaja,
                             FechaDesdeSeleccionada,
                             FechaHastaSeleccionada,
                             sSerie, bQR, oNomImpresoraCaja);
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
  if FechaHastaSeleccionada < FechaDesdeSeleccionada then
    dteFechaHasta.EditValue := FechaDesdeSeleccionada;
end;

procedure TfrmModalArqueo.dteFechaHastaPropertiesChange(Sender: TObject);
begin
  inherited;
  if FechaHastaSeleccionada < FechaDesdeSeleccionada then
    dteFechaHasta.EditValue := FechaDesdeSeleccionada;
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
                                                   FechaDesdeSeleccionada,
                                                   FechaHastaSeleccionada);
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
    '   COALESCE(e.DIMINUTIVO_TICKET_EMPL,                                ' +
    '            o.CODIGO_EMPLEADO_OPCAJA, ''?'') AS EMPLEADO,            ' +
    '   COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA)  AS UDS,                ' +
    '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0)   AS NETO                ' +
    '   FROM fza_caja_operaciones o                                       ' +
    '   LEFT JOIN fza_empleados e                                         ' +
    '     ON e.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA                     ' +
    '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
    '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
    '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
    '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
    '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
    '  GROUP BY o.CODIGO_EMPLEADO_OPCAJA, e.DIMINUTIVO_TICKET_EMPL        ' +
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
    '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
    '  GROUP BY p.CODIGO_FP_CFP                                           ' +
    '  ORDER BY p.CODIGO_FP_CFP                                           ';

  // Familia: ruta jerárquica raíz→hoja recortada a los primeros N niveles
  // configurados en Parámetros de Caja (vgerArqueoNivelesFamilia). N=1 deja
  // solo la sección raíz; N=2 sección-familia; N=3 +subfamilia… La consulta
  // la construye TArqueoCalculadora.SQLResumenSeccion (compartida con el
  // ticket impreso).
  qryResFam.SQL.Text := TArqueoCalculadora.SQLResumenSeccion(
    NivelesFamiliaArqueo);

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
    '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
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
  Q.ParamByName('pFDESDE').AsDateTime    := FechaDesdeSeleccionada;
  Q.ParamByName('pFHASTA').AsDateTime    := FechaHastaSeleccionada;
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
//   Recuento: billetes, formas de pago, retirada, dejo mañana
// =============================================================================

const
  DENOMINACIONES: array[0..14] of Double = (
    500, 200, 100, 50, 20, 10, 5, 2, 1, 0.50, 0.20, 0.10, 0.05, 0.02, 0.01);

procedure TfrmModalArqueo.CargarBilletes;
var
  i: Integer;
  sNombre: string;
begin
  tvBilletes.BeginUpdate;
  try
    tvBilletes.DataController.RecordCount := Length(DENOMINACIONES);
    for i := 0 to High(DENOMINACIONES) do
    begin
      if DENOMINACIONES[i] >= 5 then
        sNombre := FormatFloat('0', DENOMINACIONES[i]) + ' EUR'
      else
        sNombre := FormatFloat('0.00', DENOMINACIONES[i]) + ' EUR';
      tvBilletes.DataController.Values[
        i, tvBilletesDenom.Index] := sNombre;
      tvBilletes.DataController.Values[
        i, tvBilletesUds.Index] := 0;
      tvBilletes.DataController.Values[
        i, tvBilletesSubtotal.Index] := Double(0);
    end;
  finally
    tvBilletes.EndUpdate;
  end;
  lblTotalEfectivo.Caption := '0,00';
end;

procedure TfrmModalArqueo.CargarRecuento(const AArqueo: TArqueoCaja);
var
  i, iRow: Integer;
begin
  { Resto día anterior }
  lblAnteriorImporte.Caption :=
    FormatFloat(',0.00', AArqueo.EfectivoAnterior) + ' EUR';
  { Desglose del efectivo }
  lblDesgloseEfectivo.Caption :=
    Format(
      'Efectivo sist. = ventas (%s) + entradas (%s) ' +
      #8722' gastos (%s) + anterior (%s)',
      [FormatFloat(',0.00', AArqueo.EfectivoIngresos),
       FormatFloat(',0.00', AArqueo.EfectivoEntradas),
       FormatFloat(',0.00', AArqueo.EfectivoSalidas),
       FormatFloat(',0.00', AArqueo.EfectivoAnterior)]);
  { Grid de otras formas de pago (solo las NO efectivo) }
  Log.LogInfo(Format('CargarRecuento: PagosPorForma=%d filas',
    [Length(AArqueo.PagosPorForma)]));
  tvRecuento.BeginUpdate;
  try
    tvRecuento.DataController.RecordCount := 0;
    iRow := 0;
    for i := 0 to High(AArqueo.PagosPorForma) do
    begin
      Log.LogInfo(Format('  FP[%d]: %s (%s) EsEfectivo=%s Importe=%.2f',
        [i, AArqueo.PagosPorForma[i].Codigo,
         AArqueo.PagosPorForma[i].Descripcion,
         BoolToStr(AArqueo.PagosPorForma[i].EsEfectivo, True),
         Double(AArqueo.PagosPorForma[i].Importe)]));
      if AArqueo.PagosPorForma[i].EsEfectivo then
        Continue;
      tvRecuento.DataController.RecordCount := iRow + 1;
      tvRecuento.DataController.Values[
        iRow, tvRecuentoFP.Index] :=
        AArqueo.PagosPorForma[i].Codigo;
      tvRecuento.DataController.Values[
        iRow, tvRecuentoDesc.Index] :=
        AArqueo.PagosPorForma[i].Descripcion;
      tvRecuento.DataController.Values[
        iRow, tvRecuentoSistema.Index] :=
        Double(AArqueo.PagosPorForma[i].Importe);
      // Pre-rellenar con el importe del sistema para avisar del recuento
      tvRecuento.DataController.Values[
        iRow, tvRecuentoImporte.Index] :=
        Double(AArqueo.PagosPorForma[i].Importe);
      tvRecuento.DataController.Values[
        iRow, tvRecuentoDiferencia.Index] := Double(0);
      Inc(iRow);
    end;
  finally
    tvRecuento.EndUpdate;
  end;
  { Inicializar billetes a 0 }
  CargarBilletes;
  RecalcularTotalesRecuento;
end;

function TfrmModalArqueo.ObtenerTotalEfectivoBilletes: Currency;
var
  i: Integer;
  v: Variant;
begin
  Result := 0;
  for i := 0 to tvBilletes.DataController.RecordCount - 1 do
  begin
    v := tvBilletes.DataController.Values[
           i, tvBilletesSubtotal.Index];
    if not VarIsNull(v) then
      Result := Result + Currency(Double(v));
  end;
end;

procedure TfrmModalArqueo.RecalcularTotalEfectivo;
begin
  lblTotalEfectivo.Caption :=
    FormatFloat(',0.00', ObtenerTotalEfectivoBilletes);
  RecalcularTotalesRecuento;
end;

procedure TfrmModalArqueo.RecalcularTotalesRecuento;
var
  i: Integer;
  dSistema, dRecuento, dDif: Double;
  v: Variant;
begin
  { Sistema: efectivo caja + otras FP }
  dSistema := Double(FArqueoActual.EfectivoCaja);
  for i := 0 to tvRecuento.DataController.RecordCount - 1 do
  begin
    v := tvRecuento.DataController.Values[
           i, tvRecuentoSistema.Index];
    if not VarIsNull(v) then
      dSistema := dSistema + Double(v);
  end;
  { Recontado: billetes + otras FP recontadas }
  dRecuento := Double(ObtenerTotalEfectivoBilletes);
  for i := 0 to tvRecuento.DataController.RecordCount - 1 do
  begin
    v := tvRecuento.DataController.Values[
           i, tvRecuentoImporte.Index];
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
  RecalcularDejoManana;
end;

procedure TfrmModalArqueo.RecalcularDejoManana;
var
  dEfectivoRecontado, dRetirada, dDejo: Currency;
begin
  dEfectivoRecontado := ObtenerTotalEfectivoBilletes;
  dRetirada := Currency(txtRetiradaImporte.Value);
  dDejo := dEfectivoRecontado - dRetirada;
  if dDejo < 0 then
    dDejo := 0;
  lblDejoImporte.Caption :=
    FormatFloat(',0.00', dDejo) + ' EUR';
end;

procedure TfrmModalArqueo.tvBilletesUdsEditValueChanged(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
var
  iRow, iUds: Integer;
  dDenom: Double;
  v: Variant;
  oEdit: TcxCustomEdit;
begin
  if AItem <> tvBilletesUds then
    Exit;
  iRow := tvBilletes.DataController.FocusedRecordIndex;
  if (iRow < 0) or (iRow > High(DENOMINACIONES)) then
    Exit;
  dDenom := DENOMINACIONES[iRow];
  iUds := 0;
  oEdit := tvBilletes.Controller.EditingController.Edit;
  if Assigned(oEdit) then
  begin
    v := oEdit.EditValue;
    if not VarIsNull(v) then
      iUds := Round(Double(v));
  end;
  tvBilletes.DataController.Values[
    iRow, tvBilletesUds.Index] := iUds;
  tvBilletes.DataController.Values[
    iRow, tvBilletesSubtotal.Index] := dDenom * iUds;
  RecalcularTotalEfectivo;
end;

procedure TfrmModalArqueo.tvRecuentoImportePropertiesEditValueChanged(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
var
  iRow: Integer;
  dSistema, dRecuento, dDif: Double;
  v: Variant;
  oEdit: TcxCustomEdit;
begin
  if AItem <> tvRecuentoImporte then
    Exit;
  iRow := tvRecuento.DataController.FocusedRecordIndex;
  if iRow < 0 then
    Exit;
  dSistema := 0;
  v := tvRecuento.DataController.Values[
         iRow, tvRecuentoSistema.Index];
  if not VarIsNull(v) then
    dSistema := Double(v);
  dRecuento := 0;
  oEdit := tvRecuento.Controller.EditingController.Edit;
  if Assigned(oEdit) then
  begin
    v := oEdit.EditValue;
    if not VarIsNull(v) then
      dRecuento := Double(v);
  end;
  dDif := dRecuento - dSistema;
  tvRecuento.DataController.Values[
    iRow, tvRecuentoDiferencia.Index] := dDif;
  tvRecuento.DataController.Values[
    iRow, tvRecuentoImporte.Index] := dRecuento;
  RecalcularTotalesRecuento;
end;

procedure TfrmModalArqueo.tvBilletesKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  iRow, iDest: Integer;
begin
  if (Key = VK_RETURN) or
     ((Key = VK_END) and (ssCtrl in Shift)) or
     ((Key = VK_HOME) and (ssCtrl in Shift)) then
  begin
    if tvBilletes.Controller.EditingController.IsEditing then
      tvBilletes.Controller.EditingController.HideEdit(True);
    iRow := tvBilletes.DataController.FocusedRecordIndex;
    if Key = VK_RETURN then
      iDest := iRow + 1
    else if Key = VK_END then
      iDest := tvBilletes.DataController.RecordCount - 1
    else
      iDest := 0;
    if iDest < 0 then
      iDest := 0;
    if iDest > tvBilletes.DataController.RecordCount - 1 then
      iDest := tvBilletes.DataController.RecordCount - 1;
    if iDest <> iRow then
    begin
      tvBilletes.DataController.FocusedRecordIndex := iDest;
      tvBilletes.Controller.FocusedColumn := tvBilletesUds;
      tvBilletes.Controller.EditingController.ShowEdit(
        tvBilletesUds);
    end;
    Key := 0;
  end;
end;

procedure TfrmModalArqueo.tvRecuentoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  iRow, iDest: Integer;
begin
  if (Key = VK_RETURN) or
     ((Key = VK_END) and (ssCtrl in Shift)) or
     ((Key = VK_HOME) and (ssCtrl in Shift)) then
  begin
    if tvRecuento.Controller.EditingController.IsEditing then
      tvRecuento.Controller.EditingController.HideEdit(True);
    iRow := tvRecuento.DataController.FocusedRecordIndex;
    if Key = VK_RETURN then
      iDest := iRow + 1
    else if Key = VK_END then
      iDest := tvRecuento.DataController.RecordCount - 1
    else
      iDest := 0;
    if iDest < 0 then
      iDest := 0;
    if iDest > tvRecuento.DataController.RecordCount - 1 then
      iDest := tvRecuento.DataController.RecordCount - 1;
    if iDest <> iRow then
    begin
      tvRecuento.DataController.FocusedRecordIndex := iDest;
      tvRecuento.Controller.FocusedColumn := tvRecuentoImporte;
      tvRecuento.Controller.EditingController.ShowEdit(
        tvRecuentoImporte);
    end;
    Key := 0;
  end;
end;

procedure TfrmModalArqueo.txtRetiradaImportePropertiesChange(
  Sender: TObject);
begin
  RecalcularDejoManana;
end;

function TfrmModalArqueo.ObtenerDesgloseBilletes: string;
var
  i, iUds: Integer;
  v: Variant;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Delimiter := ';';
    for i := 0 to High(DENOMINACIONES) do
    begin
      iUds := 0;
      v := tvBilletes.DataController.Values[
             i, tvBilletesUds.Index];
      if not VarIsNull(v) then
        iUds := Round(Double(v));
      sl.Add(FormatFloat('0.##', DENOMINACIONES[i]) +
             ':' + IntToStr(iUds));
    end;
    Result := sl.DelimitedText;
  finally
    FreeAndNil(sl);
  end;
end;

function TfrmModalArqueo.ObtenerConceptoRetirada: string;
begin
  case rgRetiradaTipo.ItemIndex of
    0: Result := 'Retirada banco';
    1: Result := 'Retirada encargado';
    2: Result := 'Caja fuerte';
    3: Result := 'Pago proveedor';
    4: Result := 'Gastos limpieza';
  else
    Result := 'Retirada cierre';
  end;
end;

// Nombre del empleado de caja activo en fza_empleados ('' si no existe).
// El vendedor que cierra el arqueo debe estar dado de alta como empleado.
function TfrmModalArqueo.BuscarNombreVendedor(const ACodigo: string): string;
var
  Q: TUniQuery;
begin
  Result := '';
  if (FConn <> nil) and FConn.Connected and (Trim(ACodigo) <> '') then
  begin
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := FConn;
      Q.SQL.Text :=
        'SELECT COALESCE(NOMBRE_EMPL, DIMINUTIVO_TICKET_EMPL, ' +
        '                CODIGO_EMPL) AS NOMBRE ' +
        '  FROM fza_empleados ' +
        ' WHERE CODIGO_EMPL   = :pCODIGO ' +
        '   AND ESACTIVO_EMPL = ''S''';
      Q.ParamByName('pCODIGO').AsString := Trim(ACodigo);
      Q.Open;
      if not Q.IsEmpty then
        Result := Q.FieldByName('NOMBRE').AsString;
    finally
      FreeAndNil(Q);
    end;
  end;
end;

procedure TfrmModalArqueo.txtVendedorCodigoExit(Sender: TObject);
begin
  // Feedback inmediato: nombre del empleado (vacío si el código no vale)
  lblVendedorNombre.Caption :=
    BuscarNombreVendedor(txtVendedorCodigo.Text);
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

procedure TfrmModalArqueo.actDesplegarDesdeExecute(Sender: TObject);
begin
  dteFechaDesde.DroppedDown := True;
end;

procedure TfrmModalArqueo.actDesplegarHastaExecute(Sender: TObject);
begin
  dteFechaHasta.DroppedDown := True;
end;

procedure TfrmModalArqueo.GrabarArqueo;
var
  Lineas: TArray<TArqueoRecuentoLinea>;
  LinEfe: TArqueoRecuentoLinea;
  i, iLin: Integer;
  dTotalRecuento, dDiferenciaTotal: Currency;
  dTotalSistema: Currency;
  dEfectivoRecontado, dRetirada, dDejo: Currency;
  sObs, sDesglose, sConceptoRet: string;
  sVendedor, sNombreVendedor: string;
  v: Variant;
begin
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  // Vendedor obligatorio: quien cierra estampa su número de empleado de
  // caja (fza_empleados), sea o no el usuario logado en el programa
  sVendedor := Trim(txtVendedorCodigo.Text);
  if sVendedor = '' then
  begin
    Application.MessageBox(
      'Debe indicar el número de empleado de caja del vendedor que ' +
      'realiza el cierre.',
      'Vendedor obligatorio', MB_OK or MB_ICONWARNING);
    pcArqueo.ActivePage := tsRecuento;
    txtVendedorCodigo.SetFocus;
    Exit;
  end;
  sNombreVendedor := BuscarNombreVendedor(sVendedor);
  if sNombreVendedor = '' then
  begin
    Application.MessageBox(
      'El número de empleado indicado no existe o no está activo.',
      'Vendedor no válido', MB_OK or MB_ICONWARNING);
    pcArqueo.ActivePage := tsRecuento;
    txtVendedorCodigo.SetFocus;
    Exit;
  end;
  lblVendedorNombre.Caption := sNombreVendedor;
  // Comprobar doble cierre
  var qryChk := TUniQuery.Create(nil);
  try
    qryChk.Connection := FConn;
    qryChk.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ  = :E ' +
      '   AND CODIGO_ALM_ARQ  = :A ' +
      '   AND CODIGO_CAJA_ARQ = :C ' +
      '   AND FASE_ARQ = ''CERRADO''' +
      '   AND FECHA_DESDE_ARQ <= :FH ' +
      '   AND FECHA_HASTA_ARQ >= :FD ';
    qryChk.ParamByName('E').AsString  := FEmpresa;
    qryChk.ParamByName('A').AsString  := FAlmacen;
    qryChk.ParamByName('C').AsString  := FCaja;
    qryChk.ParamByName('FD').AsDateTime := FechaDesdeSeleccionada;
    qryChk.ParamByName('FH').AsDateTime := FechaHastaSeleccionada;
    qryChk.Open;
    if qryChk.FieldByName('N').AsInteger > 0 then
    begin
      Application.MessageBox(
        'Ya existe un cierre que solapa este rango y caja. ' +
        'No se permite doble cierre.',
        'Arqueo duplicado', MB_OK or MB_ICONWARNING);
      Exit;
    end;
  finally
    FreeAndNil(qryChk);
  end;
  dEfectivoRecontado := ObtenerTotalEfectivoBilletes;
  if (dEfectivoRecontado = 0)
     and (tvRecuento.DataController.RecordCount = 0) then
  begin
    Application.MessageBox(
      'No hay datos de recuento. Pulse Recalcular primero.',
      'Aviso', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if Application.MessageBox(
       'Se va a grabar el arqueo con los importes recontados.' +
       #13#10 +
       'Periodo: ' +
       FormatDateTime('dd/mm/yyyy hh:nn:ss',
                      FechaDesdeSeleccionada) +
       ' - ' +
       FormatDateTime('dd/mm/yyyy hh:nn:ss',
                      FechaHastaSeleccionada) +
       #13#10 +
       'Las operaciones del rango quedarán marcadas.' +
       #13#10#13#10 +
       '¿Desea continuar?',
       'Confirmar Arqueo',
       MB_YESNO or MB_ICONQUESTION) <> IDYES then
    Exit;
  dRetirada := Currency(txtRetiradaImporte.Value);
  dDejo     := dEfectivoRecontado - dRetirada;
  if dDejo < 0 then
    dDejo := 0;
  sConceptoRet := ObtenerConceptoRetirada;
  sDesglose    := ObtenerDesgloseBilletes;
  sObs         := Trim(txtObservaciones.Text);
  { Montar array de líneas: 1 para efectivo + N para otras FP }
  iLin := 1 + tvRecuento.DataController.RecordCount;
  SetLength(Lineas, iLin);
  { Línea 0: efectivo (billetes+monedas) }
  LinEfe.CodigoFP    := 'EFE';
  LinEfe.Descripcion := 'Efectivo (billetes y monedas)';
  LinEfe.EsCajon     := 'S';
  LinEfe.Sistema     := FArqueoActual.EfectivoCaja;
  LinEfe.Recuento    := dEfectivoRecontado;
  LinEfe.Diferencia  := dEfectivoRecontado - FArqueoActual.EfectivoCaja;
  Lineas[0] := LinEfe;
  dTotalSistema  := FArqueoActual.EfectivoCaja;
  dTotalRecuento := dEfectivoRecontado;
  { Líneas 1..N: otras formas de pago }
  for i := 0 to tvRecuento.DataController.RecordCount - 1 do
  begin
    Lineas[i + 1].CodigoFP := VarToStr(
      tvRecuento.DataController.Values[i, tvRecuentoFP.Index]);
    Lineas[i + 1].Descripcion := VarToStr(
      tvRecuento.DataController.Values[i, tvRecuentoDesc.Index]);
    Lineas[i + 1].EsCajon := 'N';
    v := tvRecuento.DataController.Values[
           i, tvRecuentoSistema.Index];
    if not VarIsNull(v) then
      Lineas[i + 1].Sistema := Currency(Double(v))
    else
      Lineas[i + 1].Sistema := 0;
    v := tvRecuento.DataController.Values[
           i, tvRecuentoImporte.Index];
    if not VarIsNull(v) then
      Lineas[i + 1].Recuento := Currency(Double(v))
    else
      Lineas[i + 1].Recuento := 0;
    Lineas[i + 1].Diferencia :=
      Lineas[i + 1].Recuento - Lineas[i + 1].Sistema;
    dTotalSistema  := dTotalSistema  + Lineas[i + 1].Sistema;
    dTotalRecuento := dTotalRecuento + Lineas[i + 1].Recuento;
  end;
  dDiferenciaTotal := dTotalRecuento - dTotalSistema;
  Screen.Cursor := crHourGlass;
  try
    TArqueoPersistencia.GrabarArqueo(
      FConn,
      FArqueoActual,
      Lineas,
      dTotalRecuento,
      dDiferenciaTotal,
      dDejo,
      dRetirada,
      sConceptoRet,
      sDesglose,
      sObs,
      sVendedor,
      oUser);
  finally
    Screen.Cursor := crDefault;
  end;
  { Justificante del cierre }
  TArqueoTicket.ImprimirCierre(
    FConn,
    FArqueoActual,
    Lineas,
    dTotalSistema,
    dTotalRecuento,
    dDiferenciaTotal,
    dRetirada,
    sConceptoRet,
    dDejo,
    sDesglose,
    sObs,
    sVendedor + ' - ' + sNombreVendedor,
    oNomImpresoraCaja);
end;

initialization
  ForceReferenceToClass(TfrmModalArqueo);
end.
