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
  System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxButtons, cxRadioGroup, cxPC, dxSkinsCore,
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
    function ConfirmarRevisionPeriodo(
      const ARevision: TRevisionPeriodoFacturacionCaja): Boolean;
    function TextoResultado(
      const AResultado: TResultadoFacturacionCaja): string;
    function RevisarPeriodo(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja
    ): TRevisionPeriodoFacturacionCaja;
    procedure EjecutarGeneracion(
      AModalidad: TModalidadFacturacionCaja;
      const ASolicitud: TSolicitudFacturacionCaja);
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
    'Se generarán borradores de facturas normales por los traspasos TA. ' +
    'El IVA y VeriFactu se declararán al consolidarlos en Venta mayor. ' +
    '¿Desea continuar?';
  SInfoSinOperacionesFacturacionCaja =
    'No hay operaciones ni ajustes pendientes para el periodo indicado.';
  SInfoResultadoFacturacionCaja =
    'Documentos generados: %d. Operaciones incluidas: %d. Ajustes: %d.';
  SInfoSeleccionarProformaCaja =
    'Debe seleccionar una proforma de venta para imprimirla.';
  SInfoImprimirFacturaTraspaso =
    'Las facturas de traspasos TA se imprimen desde Venta mayor.';
  SInfoPeriodoFacturacionCajaSinDocumento =
    'El registro de periodo seleccionado no tiene un documento imprimible.';
  SErrorReferenciaProformaCajaInvalida =
    'No se ha podido identificar la proforma seleccionada.';
  SAvisoPeriodoFacturacionCajaDuplicado =
    'Ya existe un registro con el mismo periodo, empresa y modalidad.';
  SAvisoPeriodoFacturacionCajaSolapado =
    'El periodo indicado se solapa con otro registro de facturación.';
  SInfoIdempotenciaFacturacionCaja =
    'Las operaciones e ítems ya vinculados no volverán a facturarse.';
  SPreguntaContinuarPeriodoFacturacionCaja =
    '¿Desea revisar igualmente las operaciones pendientes y continuar?';

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
      'Traspasos (TA): borrador fiscal de Venta mayor';
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
    CrearColumna('ID_PERIODO', 'Id. periodo', 80);
    CrearColumna('ESTADO_PERIODO', 'Estado periodo', 110);
    CrearColumna('SERIE_DOCUMENTO', 'Serie', 80);
    CrearColumna('NUMERO_DOCUMENTO', 'Número', 100);
    CrearColumna('FECHA_DOCUMENTO', 'Fecha', 90);
    CrearColumna('FECHA_DESDE', 'Periodo desde', 100);
    CrearColumna('FECHA_HASTA', 'Periodo hasta', 100);
    CrearColumna('CODIGO_EMPRESA', 'Empresa', 100);
    CrearColumna('EMPRESA_DESTINO', 'Empresa destino', 210);
    CrearColumna('ESTADO_DOCUMENTO', 'Estado', 100);
    CrearColumna('CANTIDAD_OPERACIONES', 'Operaciones', 90);
    CrearColumna('CANTIDAD_AJUSTES', 'Ajustes', 75);
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

function TfrmMtoFacturasProforma.ConfirmarRevisionPeriodo(
  const ARevision: TRevisionPeriodoFacturacionCaja): Boolean;
var
  sAviso: string;
begin
  Result := True;
  if ARevision.EsDuplicado or ARevision.EsSolapado then
  begin
    sAviso := '';
    if ARevision.EsDuplicado then
      sAviso := SAvisoPeriodoFacturacionCajaDuplicado;
    if ARevision.EsSolapado then
    begin
      if sAviso <> '' then
        sAviso := sAviso + sLineBreak;
      sAviso := sAviso + SAvisoPeriodoFacturacionCajaSolapado;
    end;
    if Trim(ARevision.Descripcion) <> '' then
      sAviso := sAviso + sLineBreak + Trim(ARevision.Descripcion);
    sAviso := sAviso + sLineBreak + sLineBreak +
      SInfoIdempotenciaFacturacionCaja + sLineBreak +
      SPreguntaContinuarPeriodoFacturacionCaja;
    Result := MessageDlg(
      sAviso, mtWarning, [mbYes, mbNo], 0) = mrYes;
  end;
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

function TfrmMtoFacturasProforma.RevisarPeriodo(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja
): TRevisionPeriodoFacturacionCaja;
var
  oServicio: TFacturadorOperacionesCaja;
begin
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    Result := oServicio.RevisarPeriodo(AModalidad, ASolicitud);
  finally
    FreeAndNil(oServicio);
  end;
end;

procedure TfrmMtoFacturasProforma.EjecutarGeneracion(
  AModalidad: TModalidadFacturacionCaja;
  const ASolicitud: TSolicitudFacturacionCaja);
var
  oResultado: TResultadoFacturacionCaja;
  oServicio : TFacturadorOperacionesCaja;
begin
  oServicio := TFacturadorOperacionesCaja.Create(
    dmmFacturasProforma.CrearRepositorio(ParametrosApp));
  try
    oResultado := oServicio.Ejecutar(AModalidad, ASolicitud);
    dmmFacturasProforma.RefrescarDocumentos;
    ShowMessage(TextoResultado(oResultado));
  finally
    FreeAndNil(oServicio);
  end;
end;

procedure TfrmMtoFacturasProforma.btnGenerarClick(Sender: TObject);
var
  eModalidad: TModalidadFacturacionCaja;
  oRevision : TRevisionPeriodoFacturacionCaja;
  oSolicitud: TSolicitudFacturacionCaja;
begin
  eModalidad := ObtenerModalidad;
  oSolicitud := PrepararSolicitud;
  btnGenerar.Enabled := False;
  try
    try
      oRevision := RevisarPeriodo(eModalidad, oSolicitud);
      if ConfirmarRevisionPeriodo(oRevision) and
         ConfirmarGeneracion(eModalidad) then
        EjecutarGeneracion(eModalidad, oSolicitud);
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  finally
    btnGenerar.Enabled := True;
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
    sClave := dsTablaG.DataSet.FieldByName(
      'CLAVE_DOCUMENTO').AsString;
    sTipo := dsTablaG.DataSet.FieldByName(
      'TIPO_DOCUMENTO').AsString;
    if SameText(Copy(sClave, 1, 4), 'PER-') then
      ShowMessage(SInfoPeriodoFacturacionCajaSinDocumento)
    else if not SameText(sTipo, 'VE') then
      ShowMessage(SInfoImprimirFacturaTraspaso)
    else
    begin
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
