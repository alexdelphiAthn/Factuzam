{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasProforma                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación por periodo de proformas VE y facturas fiscales TA.           }
{******************************************************************************}
unit inMtoFacturasProforma;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxButtons,
  cxRadioGroup, cxPC, dxSkinsCore, dxSkinsDefaultPainters,
  dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataFacturasProforma, inLibFacturasProformaIntf, inMtoGen;

type
  TfrmMtoFacturasProforma = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados   : Boolean;
    dmmFacturasProforma : TdmFacturasProforma;
    pnlFacturacion      : TPanel;
    dteDesde            : TcxDateEdit;
    dteHasta            : TcxDateEdit;
    cbbEmpresaDestino   : TcxLookupComboBox;
    rgModalidad         : TcxRadioGroup;
    btnGenerar          : TcxButton;
    btnRefrescar        : TcxButton;
    btnImprimir         : TcxButton;
    lblExplicacion      : TcxLabel;
    procedure CrearControlesDinamicos;
    procedure CrearEtiqueta(const ATexto: string; AIzq, ATop: Integer);
    procedure CrearColumnas;
    function CrearColumna(const ACampo, ATitulo: string;
      AAncho: Integer): TcxGridDBColumn;
    function ObtenerModalidad: TModalidadFacturacionCaja;
    function PrepararSolicitud: TSolicitudFacturacionCaja;
    function ConfirmarGeneracion(
      AModalidad: TModalidadFacturacionCaja): Boolean;
    function TextoResultado(
      const AResultado: TResultadoFacturacionCaja): string;
    procedure EjecutarGeneracion;
    procedure ImprimirSeleccion;
    procedure btnGenerarClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

resourcestring
  SPreguntaGenerarProformaVenta =
    'Se generará una proforma interna no fiscal para VENTA CONTADO. ' +
    'No declarará IVA ni VeriFactu. ¿Desea continuar?';
  SPreguntaGenerarFacturaTraspaso =
    'Se generarán facturas fiscales normales por los traspasos TA. ' +
    'Al consolidarlas entrarán en IVA y VeriFactu. ¿Desea continuar?';
  SInfoSinOperacionesFacturacionCaja =
    'No hay operaciones ni ajustes pendientes para el periodo indicado.';
  SInfoResultadoFacturacionCaja =
    'Documentos generados: %d. Operaciones incluidas: %d. Ajustes: %d.';
  SInfoSeleccionarProformaCaja =
    'Debe seleccionar una proforma de venta para imprimirla.';
  SInfoImprimirFacturaTraspaso =
    'Las facturas de traspasos TA se imprimen desde Facturas normales.';
  SErrorReferenciaProformaCajaInvalida =
    'No se ha podido identificar la proforma seleccionada.';

implementation

uses
  inLibFacturasProforma, inMtoModalImpFacturasProforma;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoFacturasProforma.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
end;

destructor TfrmMtoFacturasProforma.Destroy;
begin
  if Assigned(cbbEmpresaDestino) then
    cbbEmpresaDestino.Properties.ListSource := nil;
  inherited;
end;

procedure TfrmMtoFacturasProforma.CrearControlesDinamicos;
var
  dHoy: TDateTime;
begin
  if not FControlesCreados then
  begin
    pnlFacturacion := TPanel.Create(Self);
    pnlFacturacion.Parent := tsLista;
    pnlFacturacion.Align := alTop;
    pnlFacturacion.Height := 132;
    pnlFacturacion.BevelOuter := bvNone;
    pnlFacturacion.ParentBackground := False;
    pnlFacturacion.Color := clWhite;
    CrearEtiqueta('Desde', 12, 14);
    dteDesde := TcxDateEdit.Create(Self);
    dteDesde.Parent := pnlFacturacion;
    dteDesde.Left := 64;
    dteDesde.Top := 10;
    dteDesde.Width := 118;
    CrearEtiqueta('Hasta', 198, 14);
    dteHasta := TcxDateEdit.Create(Self);
    dteHasta.Parent := pnlFacturacion;
    dteHasta.Left := 250;
    dteHasta.Top := 10;
    dteHasta.Width := 118;
    CrearEtiqueta('Empresa destino', 388, 14);
    cbbEmpresaDestino := TcxLookupComboBox.Create(Self);
    cbbEmpresaDestino.Parent := pnlFacturacion;
    cbbEmpresaDestino.Left := 506;
    cbbEmpresaDestino.Top := 10;
    cbbEmpresaDestino.Width := 330;
    cbbEmpresaDestino.Properties.DropDownListStyle := lsFixedList;
    cbbEmpresaDestino.Properties.KeyFieldNames := 'CODIGO_EMP_EMP';
    cbbEmpresaDestino.Properties.ListFieldNames := 'RAZON_SOCIAL_EMP';
    rgModalidad := TcxRadioGroup.Create(Self);
    rgModalidad.Parent := pnlFacturacion;
    rgModalidad.Left := 12;
    rgModalidad.Top := 47;
    rgModalidad.Width := 824;
    rgModalidad.Height := 48;
    rgModalidad.Caption := ' Modalidad ';
    rgModalidad.Properties.Columns := 2;
    rgModalidad.Properties.Items.Add.Caption :=
      'Ventas (VE): proforma interna no fiscal';
    rgModalidad.Properties.Items.Add.Caption :=
      'Traspasos (TA): factura fiscal normal';
    rgModalidad.ItemIndex := 0;
    btnGenerar := TcxButton.Create(Self);
    btnGenerar.Parent := pnlFacturacion;
    btnGenerar.Left := 856;
    btnGenerar.Top := 10;
    btnGenerar.Width := 174;
    btnGenerar.Height := 34;
    btnGenerar.Caption := 'Generar documentos';
    btnGenerar.OnClick := btnGenerarClick;
    btnRefrescar := TcxButton.Create(Self);
    btnRefrescar.Parent := pnlFacturacion;
    btnRefrescar.Left := 856;
    btnRefrescar.Top := 56;
    btnRefrescar.Width := 174;
    btnRefrescar.Height := 34;
    btnRefrescar.Caption := 'Refrescar historial';
    btnRefrescar.OnClick := btnRefrescarClick;
    btnImprimir := TcxButton.Create(Self);
    btnImprimir.Parent := pnlFacturacion;
    btnImprimir.Left := 856;
    btnImprimir.Top := 96;
    btnImprimir.Width := 174;
    btnImprimir.Height := 30;
    btnImprimir.Caption := 'Imprimir selección';
    btnImprimir.OnClick := btnImprimirClick;
    lblExplicacion := TcxLabel.Create(Self);
    lblExplicacion.Parent := pnlFacturacion;
    lblExplicacion.Left := 12;
    lblExplicacion.Top := 102;
    lblExplicacion.Caption :=
      'Cada operación conserva su fecha e identificador. Las ventas ' +
      'rectificadas se incorporan como ajustes posteriores.';
    lblExplicacion.Transparent := True;
    dHoy := Date;
    dteDesde.Date := EncodeDate(
      YearOf(dHoy), ((MonthOf(dHoy) - 1) div 3) * 3 + 1, 1);
    dteHasta.Date := dHoy;
    FControlesCreados := True;
  end;
end;

procedure TfrmMtoFacturasProforma.CrearEtiqueta(
  const ATexto: string; AIzq, ATop: Integer);
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent := pnlFacturacion;
  lbl.Left := AIzq;
  lbl.Top := ATop;
  lbl.Caption := ATexto;
  lbl.Transparent := True;
end;

function TfrmMtoFacturasProforma.CrearColumna(
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := cxGrdDBTabPrin.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := AAncho;
  Result.Options.Editing := False;
end;

procedure TfrmMtoFacturasProforma.CrearColumnas;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna('TIPO_DOCUMENTO', 'Tipo', 55);
    CrearColumna('SERIE_DOCUMENTO', 'Serie', 80);
    CrearColumna('NUMERO_DOCUMENTO', 'Número', 100);
    CrearColumna('FECHA_DOCUMENTO', 'Fecha', 90);
    CrearColumna('FECHA_DESDE', 'Periodo desde', 100);
    CrearColumna('FECHA_HASTA', 'Periodo hasta', 100);
    CrearColumna('CODIGO_EMPRESA', 'Empresa origen', 100);
    CrearColumna('EMPRESA_DESTINO', 'Empresa destino', 210);
    CrearColumna('ESTADO_DOCUMENTO', 'Estado', 100);
    CrearColumna('CANTIDAD_OPERACIONES', 'Operaciones', 90);
    CrearColumna('TOTAL_BASE', 'Base', 100);
    CrearColumna('TOTAL_IMPUESTOS', 'Impuestos', 100);
    CrearColumna('TOTAL_DOCUMENTO', 'Total', 110);
  end;
end;

procedure TfrmMtoFacturasProforma.CrearTablaPrincipal;
begin
  inherited;
  dmmFacturasProforma := tdmDataModule as TdmFacturasProforma;
  pkFieldName := 'CLAVE_DOCUMENTO';
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  cbbEmpresaDestino.Properties.ListSource :=
    dmmFacturasProforma.dsEmpresas;
  cbbEmpresaDestino.EditValue := UbicacionSesion.Empresa;
  CrearColumnas;
end;

function TfrmMtoFacturasProforma.ObtenerModalidad:
  TModalidadFacturacionCaja;
begin
  Result := mfcVenta;
  if rgModalidad.ItemIndex = 1 then
    Result := mfcTraspaso;
end;

function TfrmMtoFacturasProforma.PrepararSolicitud:
  TSolicitudFacturacionCaja;
begin
  Result.FechaDesde := Trunc(dteDesde.Date);
  Result.FechaHasta := Trunc(dteHasta.Date);
  Result.CodigoEmpresaDestino :=
    Trim(VarToStr(cbbEmpresaDestino.EditValue));
  Result.Usuario := Trim(IdentidadSesion.Usuario);
end;

function TfrmMtoFacturasProforma.ConfirmarGeneracion(
  AModalidad: TModalidadFacturacionCaja): Boolean;
var
  sPregunta: string;
begin
  sPregunta := SPreguntaGenerarProformaVenta;
  if AModalidad = mfcTraspaso then
    sPregunta := SPreguntaGenerarFacturaTraspaso;
  Result := MessageDlg(
    sPregunta, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmMtoFacturasProforma.TextoResultado(
  const AResultado: TResultadoFacturacionCaja): string;
begin
  Result := Trim(AResultado.Descripcion);
  if Result = '' then
  begin
    if (AResultado.CantidadDocumentos = 0) and
       (AResultado.CantidadOperaciones = 0) and
       (AResultado.CantidadAjustes = 0) then
      Result := SInfoSinOperacionesFacturacionCaja
    else
      Result := Format(
        SInfoResultadoFacturacionCaja,
        [AResultado.CantidadDocumentos,
         AResultado.CantidadOperaciones,
         AResultado.CantidadAjustes]);
  end;
end;

procedure TfrmMtoFacturasProforma.EjecutarGeneracion;
var
  eModalidad: TModalidadFacturacionCaja;
  oServicio : TFacturadorOperacionesCaja;
  oSolicitud: TSolicitudFacturacionCaja;
  oResultado: TResultadoFacturacionCaja;
begin
  eModalidad := ObtenerModalidad;
  oSolicitud := PrepararSolicitud;
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio);
  try
    oResultado := oServicio.Ejecutar(eModalidad, oSolicitud);
    dmmFacturasProforma.RefrescarDocumentos;
    ShowMessage(TextoResultado(oResultado));
  finally
    FreeAndNil(oServicio);
  end;
end;

procedure TfrmMtoFacturasProforma.btnGenerarClick(Sender: TObject);
var
  eModalidad: TModalidadFacturacionCaja;
begin
  eModalidad := ObtenerModalidad;
  if ConfirmarGeneracion(eModalidad) then
  begin
    btnGenerar.Enabled := False;
    try
      try
        EjecutarGeneracion;
      except
        on E: Exception do
          ShowMessage(E.Message);
      end;
    finally
      btnGenerar.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoFacturasProforma.btnRefrescarClick(Sender: TObject);
begin
  if Assigned(dmmFacturasProforma) then
    dmmFacturasProforma.RefrescarDocumentos;
end;

procedure TfrmMtoFacturasProforma.ImprimirSeleccion;
var
  iIdProforma: Int64;
  sClave     : string;
  sTipo      : string;
begin
  if (not Assigned(dsTablaG.DataSet)) or dsTablaG.DataSet.IsEmpty then
    ShowMessage(SInfoSeleccionarProformaCaja)
  else
  begin
    sTipo := dsTablaG.DataSet.FieldByName(
      'TIPO_DOCUMENTO').AsString;
    if not SameText(sTipo, 'VE') then
      ShowMessage(SInfoImprimirFacturaTraspaso)
    else
    begin
      sClave := dsTablaG.DataSet.FieldByName(
        'CLAVE_DOCUMENTO').AsString;
      iIdProforma := StrToInt64Def(Copy(sClave, 4, MaxInt), 0);
      if iIdProforma > 0 then
        TfrmPrintFacturasProforma.Mostrar(Self, iIdProforma)
      else
        ShowMessage(SErrorReferenciaProformaCajaInvalida);
    end;
  end;
end;

procedure TfrmMtoFacturasProforma.btnImprimirClick(Sender: TObject);
begin
  ImprimirSeleccion;
end;

procedure TfrmMtoFacturasProforma.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

initialization
  RegistrarPantalla(TfrmMtoFacturasProforma);
  ForceReferenceToClass(TfrmMtoFacturasProforma);
end.
