{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOperacionesHist                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de operaciones de caja.                                         }
{    Consulta de tickets y operaciones realizadas en el TPV.                   }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista.        }
{******************************************************************************}
unit inMtoCajaOperacionesHist;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, Vcl.ComCtrls,
  UniDataCajaOperacionesHist, UniDataPerfiles, MemDS, DBAccess, Uni,
  cxCheckBox, cxCheckComboBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs, System.Actions, Vcl.ActnList, cxCalendar,
  UniDataConsultaOpe, dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetStyles, dxHashUtils, cxMaskEdit, cxDropDownEdit;

type
  TfrmMtoCajaOperacionesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinRAZON_SOCIAL_CLI: TcxGridDBColumn;
    cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    pnlFiltrosCaja: TPanel;
    btnToggleFiltrosCaja: TcxButton;
    pnlContFiltrosCaja: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    btnGuardarPrecargaCaja: TcxButton;
    alOperaciones: TActionList;
    actIrFacturaSimplif: TAction;
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure btnToggleFiltrosCajaClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure btnGuardarPrecargaCajaClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actIrFacturaSimplifExecute(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
  private
    // Guarda contra reentrada: bloquea el OnCloseUp de los combos mientras
    // inicializamos sus estados desde el perfil (si no, cada marca dispara
    // una reapertura del SQL).
    FFiltrosCargando: Boolean;
    // La carga inicial con barra de progreso se hace una sola vez (en el
    // primer Show); las siguientes aperturas son por cambio de filtro.
    FCargaInicialHecha: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items: el combo
    // muestra "código - nombre" pero el filtro usa solo el código.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente la primera vez).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    FdmConsulta: TdmConsultaOpe;
    FDetalleCreado: Boolean;
    FpcDetalleCaja: TcxPageControl;
    FtsDetalleOperacion: TcxTabSheet;
    FtsDetallePagos: TcxTabSheet;
    FtsDetalleVales: TcxTabSheet;
    FtsDetalleMovimientos: TcxTabSheet;
    FtsDetalleCliente: TcxTabSheet;
    FtsDetalleDepositos: TcxTabSheet;
    FtsDetalleFactura: TcxTabSheet;
    FtvDetalleOperacion: TcxGridDBTableView;
    FtvDetallePagos: TcxGridDBTableView;
    FtvDetalleVales: TcxGridDBTableView;
    FtvDetalleMovimientos: TcxGridDBTableView;
    FtvDetalleCliente: TcxGridDBTableView;
    FtvDetalleDepositos: TcxGridDBTableView;
    FtvDetalleFacturaCab: TcxGridDBTableView;
    FtvDetalleFacturaLin: TcxGridDBTableView;
    FactIrArticulo: TAction;
    FactIrCliente: TAction;
    FactIrDeposito: TAction;
    FactIrFormaPago: TAction;
    FactIrPagoHist: TAction;
    FactIrMovimiento: TAction;
    FactIrVale: TAction;
    FactExportarOperacionExcel: TAction;
    dmmCajaOperacionesHist: TdmCajaOperacionesHist;
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function  ConstruirWhereOperaciones: string;
    function  ConstruirSqlOperaciones: string;
    function  ContarOperaciones: Integer;
    procedure AplicarFiltrosOperaciones;
    procedure AbrirConProgreso;
    procedure MostrarProgresoCarga(const AMax: Integer);
    procedure ActualizarProgresoCarga(const APos, AMax: Integer);
    procedure OcultarProgresoCarga;
    procedure CrearFichaDetalle;
    function  CrearVistaDetalle(var APagina: TcxTabSheet;
                                const ACaption,
                                      ANombreVista: string;
                                ADataSource: TDataSource): TcxGridDBTableView;
    function  CrearVistaEnContenedor(AParent: TWinControl;
                                     const ANombreVista: string;
                                     ADataSource: TDataSource):
                                     TcxGridDBTableView;
    procedure AnadirColumna(AVista: TcxGridDBTableView;
                            const ANombre,
                                  ACaption,
                                  ACampo: string;
                            AAncho: Integer;
                            const AClaseProp: string = '';
                            const AFormato: string = '';
                            AVisible: Boolean = True);
    procedure RefrescarFichaOperacion;
    procedure CerrarFichaOperacion;
    procedure AjustarVisibilidadPestanasFicha;
    procedure OnTablaGDataChange(Sender: TObject; Field: TField);
    function  CrearAccionFicha(const ANombre,
                                     ACaption,
                                     AAtajo: string;
                               AOnExecute: TNotifyEvent): TAction;
    procedure CrearAccionesFicha;
    procedure CrearBarraAcciones(APagina: TcxTabSheet;
                                 const AAcciones: array of TAction);
    function  ValorCampoDataSet(ADataset: TDataSet;
                                const ACampo: string): string;
    function  ValorCampoVista(AVista: TcxGridDBTableView;
                              const ACampo: string): string;
    function  ValorCampoPrincipal(const ACampo: string): string;
    procedure AbrirMantenimiento(const ACallWinF, AClave: string);
    procedure actIrArticuloExecute(Sender: TObject);
    procedure actIrClienteExecute(Sender: TObject);
    procedure actIrDepositoExecute(Sender: TObject);
    procedure actIrFormaPagoExecute(Sender: TObject);
    procedure actIrPagoHistExecute(Sender: TObject);
    procedure actIrMovimientoExecute(Sender: TObject);
    procedure actIrValeExecute(Sender: TObject);
    procedure actExportarOperacionExcelExecute(Sender: TObject);
    function  CrearHojaExcel(ASheetControl: TdxSpreadSheet;
                             const ANombre: string):
                             TdxSpreadSheetTableView;
    function  SanearNombreHojaExcel(const ANombre: string): string;
    function  ValorExcelCampo(AField: TField): Variant;
    procedure AplicarFormatoExcel(Sheet: TdxSpreadSheetTableView;
                                  ARow,
                                  ACol: Integer;
                                  AField: TField);
    function  VistaTieneDatos(AVista: TcxGridDBTableView): Boolean;
    procedure ExportarResumenExcel(ASheetControl: TdxSpreadSheet);
    procedure ExportarVistaExcel(ASheetControl: TdxSpreadSheet;
                                 const AHoja,
                                       ATitulo: string;
                                 AVista: TcxGridDBTableView);
    procedure ExportarOperacionExcel(ASheetControl: TdxSpreadSheet);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

var
  frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist;

implementation

uses
  inLibWin, inLibUser, inLibGlobalVar, inLibShowMto, inMtoPrincipal,
  inMtoModalGenImpSave, inMtoModalImpOperaciones, inMtoPreviewExcel,
  inLibDevExcel, inLibAppParam, inLibFotos, inLibFiltroUsuario,
  dxSpreadSheetGraphics;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaOperacionesHist }

procedure TfrmMtoCajaOperacionesHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintOperaciones;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport) de las operaciones de caja. El
  // usuario filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintOperaciones.Create(Application);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.actIrFacturaSimplifExecute(
                                                            Sender: TObject);
var
  ds: TDataSet;
  sSerie, sNumero: string;
begin
  inherited;
  // Ctrl+Shift+F: ir a la factura simplificada de la operacion enfocada.
  // La lista historica usa el mismo resumen que Buscar/Modificar: SERIE_FAC
  // y NUMERO_FAC salen de la factura real o de la operacion de caja.
  sSerie := '';
  sNumero := '';
  if Assigned(FdmConsulta) and
     Assigned(FdmConsulta.dsFactura.DataSet) then
  begin
    ds := FdmConsulta.dsFactura.DataSet;
    if ds.Active and
       (not ds.IsEmpty) then
    begin
      sSerie := Trim(ds.FieldByName('SERIE_FAC').AsString);
      sNumero := Trim(ds.FieldByName('NUMERO_FAC').AsString);
    end;
  end;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) and
     dmmCajaOperacionesHist.unqryTablaG.Active and
     ((sSerie = '') or (sNumero = '')) then
  begin
    ds := dmmCajaOperacionesHist.unqryTablaG;
    if not ds.IsEmpty then
    begin
      sSerie := Trim(ds.FieldByName('SERIE_FAC').AsString);
      sNumero := Trim(ds.FieldByName('NUMERO_FAC').AsString);
    end;
  end;
  if (sSerie <> '') and (sNumero <> '') then
    ShowMto(Self.Owner, 'FacturasSimplif', sNumero + ',' + sSerie)
  else
    ShowMto(Self.Owner, 'FacturasSimplif');
end;

procedure TfrmMtoCajaOperacionesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaOperacionesHist := tdmDataModule as TdmCajaOperacionesHist;
  FdmConsulta := TdmConsultaOpe.Create(Self);
  CrearAccionesFicha;
  CrearFichaDetalle;
  pkFieldName := 'CODIGO_EMP_OPCAJA;CODIGO_ALM_OPCAJA;' +
                 'CODIGO_CAJA_OPCAJA;NUMERO_OPERACION_OPCAJA';
  tsFicha.TabVisible := True;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.Enabled := False;
  actEliminarRegistro.Enabled := False;
  actEditarRegistro.Enabled := False;
  actGrabarRegistro.Enabled := False;
  btnGrabar.Visible := False;
  btnCancelar.Visible := False;
  // Persiana de filtros de carga: arranca colapsada (igual que el Mto de
  // articulos); se despliega al pulsar la cabecera.
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. NO
  // abrimos aqui: la query esta Active=False en su .dfm y la apertura con
  // barra de progreso se hace en ResetForm, ya con el form visible.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    dmmCajaOperacionesHist.unqryTablaG.SQL.Text := ConstruirSqlOperaciones;
    dsTablaG.OnDataChange := OnTablaGDataChange;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales. En la instancia de busqueda (Ctrl+A) la apertura la maneja
  // PrepararBusquedaExterna + AbrirTablaPrincipalSincrono.
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ResolverArtSkuActivo(
  out ACodArt, ACodSku: string);
var
  ds: TDataSet;
  procedure LeerDeVista(AVista: TcxGridDBTableView);
  begin
    if (ACodArt = '') and
       Assigned(AVista) and
       Assigned(AVista.DataController.DataSource) then
    begin
      ds := AVista.DataController.DataSource.DataSet;
      inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
    end;
  end;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(FpcDetalleCaja) and
     (pcPantalla.ActivePage = tsFicha) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleMovimientos then
      LeerDeVista(FtvDetalleMovimientos)
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      LeerDeVista(FtvDetalleDepositos)
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      LeerDeVista(FtvDetalleFacturaLin);
    if ACodArt = '' then
    begin
      LeerDeVista(FtvDetalleMovimientos);
      LeerDeVista(FtvDetalleDepositos);
      LeerDeVista(FtvDetalleFacturaLin);
    end;
  end;
  if ACodArt = '' then
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
end;

function TfrmMtoCajaOperacionesHist.DataSourcesParaFoto:
  TArray<TDataSource>;
begin
  if Assigned(FdmConsulta) then
    Result := [FdmConsulta.dsMovimientos,
               FdmConsulta.dsDepositos,
               FdmConsulta.dsFacturaLin]
  else
    Result := inherited DataSourcesParaFoto;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAnyosFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  // Años distintos presentes en el historico (descendente). Es un unico
  // escaneo que devuelve pocas filas, mucho mas barato que traer la tabla
  // entera, y permite ofrecer al usuario solo los años con datos.
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_OPERACION_OPCAJA) AS ANYO ' +
      '  FROM fza_caja_operaciones ' +
      ' WHERE FECHA_OPERACION_OPCAJA IS NOT NULL ' +
      ' ORDER BY ANYO DESC';
    qry.Open;
    while not qry.Eof do
    begin
      item := ccbFiltroAnyo.Properties.Items.Add;
      item.Description := qry.FieldByName('ANYO').AsString;
      if item.Description = sAnyoActual then
        bExisteActual := True;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
  // El año en curso es el valor por defecto del filtro: lo añadimos aunque
  // todavia no tenga operaciones para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAlmacenesFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
begin
  ccbFiltroAlmacen.Properties.Items.Clear;
  if FCodigosAlmacen = nil then
    FCodigosAlmacen := TStringList.Create
  else
    FCodigosAlmacen.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
    // Con la restricción por usuario activa el combo solo ofrece su
    // empresa/almacén (fza_almacenes lleva la empresa en CODIGO_EMP_ALM).
    qry.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      SqlFiltroEmpAlmCaja('CODIGO_EMP_ALM', 'CODIGO_ALM_ALM', '') +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    qry.Open;
    while not qry.Eof do
    begin
      item := ccbFiltroAlmacen.Properties.Items.Add;
      item.Description := qry.FieldByName('CODIGO_ALM_ALM').AsString +
                          ' - ' + qry.FieldByName('NOMBRE_ALM_ALM').AsString;
      FCodigosAlmacen.Add(qry.FieldByName('CODIGO_ALM_ALM').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  // FFiltrosCargando evita que cada asignacion de States dispare el
  // OnCloseUp y reabra el SQL mientras inicializamos.
  FFiltrosCargando := True;
  try
    // Por defecto: año en curso marcado; ningun almacen marcado (= todos).
    sAnyosCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAnyos',
                                   IntToStr(YearOf(Date)));
    sAlmCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacenes', '');
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sAnyosCsv;
      for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      begin
        if lst.IndexOf(ccbFiltroAnyo.Properties.Items[i].Description) >= 0 then
          ccbFiltroAnyo.States[i] := cbsChecked
        else
          ccbFiltroAnyo.States[i] := cbsUnchecked;
      end;
      lst.DelimitedText := sAlmCsv;
      for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      begin
        if (i < FCodigosAlmacen.Count) and
           (lst.IndexOf(FCodigosAlmacen[i]) >= 0) then
          ccbFiltroAlmacen.States[i] := cbsChecked
        else
          ccbFiltroAlmacen.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosCargando := False;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  // Volcamos los filtros al batch de sbGrabarGridClick para que se graben
  // junto al resto de preferencias del Mto, respetando el ambito elegido.
  if Assigned(ccbFiltroAnyo) then
  begin
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    sAnyos := '';
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
    begin
      if ccbFiltroAnyo.States[i] = cbsChecked then
      begin
        if sAnyos <> '' then
          sAnyos := sAnyos + ';';
        sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
      end;
    end;
    item.SubKey := 'oFiltroAnyos';
    item.Value := sAnyos;
    oList.Add(item);
    sAlmacenes := '';
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
    begin
      if (ccbFiltroAlmacen.States[i] = cbsChecked) and
         (i < FCodigosAlmacen.Count) then
      begin
        if sAlmacenes <> '' then
          sAlmacenes := sAlmacenes + ';';
        sAlmacenes := sAlmacenes + FCodigosAlmacen[i];
      end;
    end;
    item.SubKey := 'oFiltroAlmacenes';
    item.Value := sAlmacenes;
    oList.Add(item);
  end;
end;

function TfrmMtoCajaOperacionesHist.ConstruirWhereOperaciones: string;
var
  sAnyos, sAlm: string;
  i: Integer;
begin
  // Años marcados -> lista IN sobre YEAR(FECHA_OPERACION_OPCAJA). Si no hay
  // ninguno marcado no se filtra por año (salen todos).
  sAnyos := '';
  for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
  begin
    if ccbFiltroAnyo.States[i] = cbsChecked then
    begin
      if sAnyos <> '' then
        sAnyos := sAnyos + ', ';
      sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
    end;
  end;
  // Almacenes marcados -> lista IN de codigos. Sin nada marcado = todos.
  sAlm := '';
  for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
  begin
    if (ccbFiltroAlmacen.States[i] = cbsChecked) and
       (i < FCodigosAlmacen.Count) then
    begin
      if sAlm <> '' then
        sAlm := sAlm + ', ';
      sAlm := sAlm + QuotedStr(FCodigosAlmacen[i]);
    end;
  end;
  Result := ' WHERE 1 = 1';
  if sAnyos <> '' then
    Result := Result +
              ' AND YEAR(o.FECHA_OPERACION_OPCAJA) IN (' + sAnyos + ')';
  if sAlm <> '' then
    Result := Result + ' AND o.CODIGO_ALM_OPCAJA IN (' + sAlm + ')';
  // Restricción por usuario (appRestringirEmpAlmCaja): acota a su
  // empresa/almacén/caja por encima de lo marcado en los combos.
  Result := Result + SqlFiltroEmpAlmCaja('o.CODIGO_EMP_OPCAJA',
                                         'o.CODIGO_ALM_OPCAJA',
                                         'o.CODIGO_CAJA_OPCAJA');
end;

function TfrmMtoCajaOperacionesHist.ConstruirSqlOperaciones: string;
begin
  Result :=
    'SELECT o.CODIGO_EMP_OPCAJA, ' +
    '       o.CODIGO_ALM_OPCAJA, ' +
    '       o.CODIGO_CAJA_OPCAJA, ' +
    '       o.NUMERO_OPERACION_OPCAJA, ' +
    '       MIN(o.FECHA_OPERACION_OPCAJA) AS FECHA_OP, ' +
    '       GROUP_CONCAT(DISTINCT o.TIPO_OPERACION_OPCAJA ' +
    '                    ORDER BY o.TIPO_OPERACION_OPCAJA ' +
    '                    SEPARATOR '','') AS TIPOS_OP, ' +
    '       GROUP_CONCAT(DISTINCT ' +
    '                    NULLIF(o.CONCEPTO_GASTO_INGRESO_OPCAJA, '''') ' +
    '                    SEPARATOR '' | '') AS CONCEPTOS, ' +
    '       COALESCE(MAX(f.TOTAL_LIQUIDO_FAC), ' +
    '                SUM(o.IMPORTE_TOTAL_OPCAJA)) AS IMPORTE_TOTAL, ' +
    '       COALESCE(MAX(f.SERIE_FAC), MAX(o.SERIE_FAC_OPCAJA)) ' +
    '         AS SERIE_FAC, ' +
    '       COALESCE(MAX(f.NUMERO_FAC), MAX(o.NUMERO_FAC_OPCAJA)) ' +
    '         AS NUMERO_FAC, ' +
    '       MAX(COALESCE(f.CODIGO_CLI_FAC, o.CODIGO_CLI_OPCAJA)) ' +
    '         AS CLIENTE, ' +
    '       MAX(cli.RAZON_SOCIAL_CLI) AS RAZON_SOCIAL_CLI, ' +
    '       MAX(o.USUARIO_ALTA) AS EMPLEADO ' +
    '  FROM fza_caja_operaciones o ' +
    '  LEFT JOIN fza_facturas f ' +
    '    ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA ' +
    '   AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA ' +
    '   AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA ' +
    '   AND f.NUMERO_OPERACION_FAC = o.NUMERO_OPERACION_OPCAJA ' +
    '  LEFT JOIN fza_clientes cli ' +
    '    ON cli.CODIGO_CLI_CLI = COALESCE(f.CODIGO_CLI_FAC, ' +
    '                                     o.CODIGO_CLI_OPCAJA) ' +
    ConstruirWhereOperaciones +
    ' GROUP BY o.CODIGO_EMP_OPCAJA, ' +
    '          o.CODIGO_ALM_OPCAJA, ' +
    '          o.CODIGO_CAJA_OPCAJA, ' +
    '          o.NUMERO_OPERACION_OPCAJA ' +
    // Ultima operacion arriba: ante empate de FECHA_OP desempatamos por
    // numero de operacion en numerico, no como texto.
    ' ORDER BY FECHA_OP DESC, ' +
    '          CAST(o.NUMERO_OPERACION_OPCAJA AS UNSIGNED) DESC';
end;

function TfrmMtoCajaOperacionesHist.ContarOperaciones: Integer;
var
  qry: TUniQuery;
begin
  // Total de filas con el filtro activo: alimenta el Max de la barra de
  // progreso para que avance "segun el nro de registros".
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT COUNT(*) AS N FROM ( ' +
      '  SELECT 1 ' +
      '    FROM fza_caja_operaciones o ' +
      ConstruirWhereOperaciones +
      '   GROUP BY o.CODIGO_EMP_OPCAJA, ' +
      '            o.CODIGO_ALM_OPCAJA, ' +
      '            o.CODIGO_CAJA_OPCAJA, ' +
      '            o.NUMERO_OPERACION_OPCAJA ' +
      ') q';
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.Fields[0].AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarFiltrosOperaciones;
var
  qry: TUniQuery;
  sSql: string;
begin
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    qry := dmmCajaOperacionesHist.unqryTablaG;
    sSql := ConstruirSqlOperaciones;
    if Trim(qry.SQL.Text) <> Trim(sSql) then
    begin
      qry.SQL.Text := sSql;
      AbrirConProgreso;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
  MAX_FILAS_CARGA = 200000;
var
  qry: TUniQuery;
  nTotal, nLeidos: Integer;
  cursorPrev: TCursor;
begin
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    qry := dmmCajaOperacionesHist.unqryTablaG;
    cursorPrev := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    // Mostramos el overlay antes del COUNT para que el usuario tenga
    // feedback tambien durante el conteo previo.
    MostrarProgresoCarga(0);
    // FetchRows define el tamaño de bloque; al recorrer, UniDAC trae los
    // registros por bloques (FetchAll por defecto es False) y vamos
    // avanzando la barra. Un FetchRows grande evita miles de round-trips
    // (el valor por defecto de 25 seria lento). DisableControls evita que
    // el grid fuerce el fetch completo y nos quite el progreso. FetchRows
    // solo se puede fijar con la query cerrada, asi que no se restaura.
    qry.DisableControls;
    try
      nTotal := ContarOperaciones;
      // Tope de seguridad: cargar cientos de miles de filas de golpe
      // bloquea el grid. Si la seleccion es enorme (p.ej. el año "1900" de
      // fechas vacias, o todos), avisamos y NO cargamos.
      if nTotal > MAX_FILAS_CARGA then
      begin
        OcultarProgresoCarga;
        Screen.Cursor := cursorPrev;
        MessageDlg(Format('La selección cargaría %s registros, demasiados ' +
          'para mostrarlos de una vez.' + sLineBreak +
          'Acota los filtros (años / almacenes) y vuelve a intentarlo.',
          [FormatFloat('#,##0', nTotal)]), mtWarning, [mbOK], 0);
      end
      else
      begin
        if Assigned(FbarProgreso) then
        begin
          if nTotal > 0 then
            FbarProgreso.Max := nTotal
          else
            FbarProgreso.Max := 1;
        end;
        qry.Close;
        qry.FetchRows := TAM_BLOQUE;
        qry.Open;
        nLeidos := 0;
        qry.First;
        while not qry.Eof do
        begin
          Inc(nLeidos);
          if (nLeidos mod 200) = 0 then
            ActualizarProgresoCarga(nLeidos, nTotal);
          qry.Next;
        end;
        qry.First;
      end;
    finally
      qry.EnableControls;
      OcultarProgresoCarga;
      Screen.Cursor := cursorPrev;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.MostrarProgresoCarga(const AMax: Integer);
begin
  if FPnlProgreso = nil then
  begin
    FPnlProgreso := TPanel.Create(Self);
    FPnlProgreso.Parent := Self;
    FPnlProgreso.BevelOuter := bvLowered;
    FPnlProgreso.ParentBackground := False;
    FPnlProgreso.Color := clWindow;
    FPnlProgreso.Width := 340;
    FPnlProgreso.Height := 96;
    FlblProgreso := TcxLabel.Create(Self);
    FlblProgreso.Parent := FPnlProgreso;
    FlblProgreso.Left := 16;
    FlblProgreso.Top := 18;
    FlblProgreso.Style.Font.Style := [fsBold];
    FbarProgreso := TProgressBar.Create(Self);
    FbarProgreso.Parent := FPnlProgreso;
    FbarProgreso.Left := 16;
    FbarProgreso.Top := 52;
    FbarProgreso.Width := 308;
    FbarProgreso.Height := 22;
  end;
  FbarProgreso.Min := 0;
  if AMax > 0 then
    FbarProgreso.Max := AMax
  else
    FbarProgreso.Max := 1;
  FbarProgreso.Position := 0;
  FlblProgreso.Caption := 'Cargando operaciones...';
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmMtoCajaOperacionesHist.ActualizarProgresoCarga(const APos,
                                                             AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := 'Cargando operaciones: ' +
                            FormatFloat('#,##0', APos) + ' / ' +
                            FormatFloat('#,##0', AMax);
    Application.ProcessMessages;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

function TfrmMtoCajaOperacionesHist.CrearAccionFicha(
  const ANombre,
        ACaption,
        AAtajo: string;
  AOnExecute: TNotifyEvent): TAction;
begin
  Result := TAction.Create(Self);
  Result.Name := ANombre;
  Result.Caption := ACaption;
  Result.ShortCut := TextToShortCut(AAtajo);
  Result.Hint := ACaption + ' (' + ShortCutToText(Result.ShortCut) + ')';
  Result.ActionList := alOperaciones;
  Result.OnExecute := AOnExecute;
end;

procedure TfrmMtoCajaOperacionesHist.CrearAccionesFicha;
begin
  actIrFacturaSimplif.Caption := 'Ir a borrador';
  actIrFacturaSimplif.Hint := 'Ir a borrador (' +
                              ShortCutToText(actIrFacturaSimplif.ShortCut) +
                              ')';
  FactIrArticulo := CrearAccionFicha('actHistIrArticulo',
                                     'Ir a artículo',
                                     'Ctrl+A',
                                     actIrArticuloExecute);
  FactIrCliente := CrearAccionFicha('actHistIrCliente',
                                    'Ir a cliente',
                                    'Ctrl+Shift+L',
                                    actIrClienteExecute);
  FactIrDeposito := CrearAccionFicha('actHistIrDeposito',
                                     'Ir a depósito',
                                     'Ctrl+D',
                                     actIrDepositoExecute);
  FactIrFormaPago := CrearAccionFicha('actHistIrFormaPago',
                                      'Ir a forma de pago',
                                      'Ctrl+Shift+P',
                                      actIrFormaPagoExecute);
  FactIrPagoHist := CrearAccionFicha('actHistIrPagoHist',
                                     'Ir a hist. pagos',
                                     'Ctrl+Shift+H',
                                     actIrPagoHistExecute);
  FactIrMovimiento := CrearAccionFicha('actHistIrMovimiento',
                                       'Ir a movimiento',
                                       'Ctrl+M',
                                       actIrMovimientoExecute);
  FactIrVale := CrearAccionFicha('actHistIrVale',
                                 'Ir a vale',
                                 'Ctrl+Shift+V',
                                 actIrValeExecute);
  FactExportarOperacionExcel :=
    CrearAccionFicha('actHistExportarOperacionExcel',
                     'Exportar a Excel',
                     'Ctrl+Shift+E',
                     actExportarOperacionExcelExecute);
end;

procedure TfrmMtoCajaOperacionesHist.CrearBarraAcciones(
  APagina: TcxTabSheet;
  const AAcciones: array of TAction);
var
  pnl: TPanel;
  btn: TcxButton;
  i, iLeft, iAncho: Integer;
begin
  pnl := TPanel.Create(Self);
  pnl.Parent := APagina;
  pnl.Align := alTop;
  pnl.Height := 38;
  pnl.BevelOuter := bvNone;
  pnl.ParentBackground := False;
  pnl.Color := clBtnFace;
  iLeft := 8;
  for i := Low(AAcciones) to High(AAcciones) do
  begin
    if Assigned(AAcciones[i]) then
    begin
      btn := TcxButton.Create(Self);
      btn.Parent := pnl;
      btn.Action := AAcciones[i];
      btn.Left := iLeft;
      btn.Top := 5;
      btn.Height := 28;
      iAncho := 28 + Length(AAcciones[i].Caption) * 7;
      if iAncho < 112 then
        iAncho := 112;
      if iAncho > 180 then
        iAncho := 180;
      btn.Width := iAncho;
      btn.ShowHint := True;
      btn.ParentShowHint := False;
      iLeft := iLeft + btn.Width + 8;
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.ValorCampoDataSet(ADataset: TDataSet;
                                                      const ACampo: string):
                                                      string;
var
  Campo: TField;
begin
  Result := '';
  if Assigned(ADataset) and
     ADataset.Active and
     (not ADataset.IsEmpty) then
  begin
    Campo := ADataset.FindField(ACampo);
    if Assigned(Campo) then
      Result := Trim(Campo.AsString);
  end;
end;

function TfrmMtoCajaOperacionesHist.ValorCampoVista(
  AVista: TcxGridDBTableView;
  const ACampo: string): string;
var
  ds: TDataSet;
begin
  ds := nil;
  if Assigned(AVista) and
     Assigned(AVista.DataController.DataSource) then
    ds := AVista.DataController.DataSource.DataSet;
  Result := ValorCampoDataSet(ds, ACampo);
end;

function TfrmMtoCajaOperacionesHist.ValorCampoPrincipal(
  const ACampo: string): string;
begin
  Result := '';
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
    Result := ValorCampoDataSet(dmmCajaOperacionesHist.unqryTablaG, ACampo);
end;

procedure TfrmMtoCajaOperacionesHist.AbrirMantenimiento(
  const ACallWinF,
        AClave: string);
begin
  if Trim(AClave) <> '' then
    ShowMto(frmMtoPrincipal, ACallWinF, AClave)
  else
    ShowMto(frmMtoPrincipal, ACallWinF);
end;

procedure TfrmMtoCajaOperacionesHist.actIrArticuloExecute(Sender: TObject);
var
  sArticulo: string;
begin
  inherited;
  sArticulo := '';
  if Assigned(FpcDetalleCaja) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleMovimientos then
      sArticulo := ValorCampoVista(FtvDetalleMovimientos, 'CODIGO_ART_MOV')
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      sArticulo := ValorCampoVista(FtvDetalleDepositos, 'CODIGO_ART_DEP')
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      sArticulo := ValorCampoVista(FtvDetalleFacturaLin,
                                   'CODIGO_ART_FACLIN');
  end;
  AbrirMantenimiento('Articulos', sArticulo);
end;

procedure TfrmMtoCajaOperacionesHist.actIrClienteExecute(Sender: TObject);
var
  sCliente: string;
begin
  inherited;
  sCliente := '';
  if Assigned(FpcDetalleCaja) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleCliente then
      sCliente := ValorCampoVista(FtvDetalleCliente, 'CODIGO_CLI_CLI')
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      sCliente := ValorCampoVista(FtvDetalleDepositos, 'CODIGO_CLI_DEP')
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      sCliente := ValorCampoVista(FtvDetalleFacturaCab, 'CODIGO_CLI_FAC')
    else if FpcDetalleCaja.ActivePage = FtsDetalleOperacion then
      sCliente := ValorCampoVista(FtvDetalleOperacion, 'CODIGO_CLI_OPCAJA');
  end;
  if sCliente = '' then
    sCliente := ValorCampoPrincipal('CLIENTE');
  AbrirMantenimiento('Clientes', sCliente);
end;

procedure TfrmMtoCajaOperacionesHist.actIrDepositoExecute(Sender: TObject);
var
  sDeposito: string;
begin
  inherited;
  sDeposito := ValorCampoVista(FtvDetalleDepositos, 'ID_DEPOSITO_DEP');
  if sDeposito = '' then
    sDeposito := ValorCampoVista(FtvDetalleOperacion, 'ID_DEPOSITO_OPCAJA');
  AbrirMantenimiento('DepositosCliente', sDeposito);
end;

procedure TfrmMtoCajaOperacionesHist.actIrFormaPagoExecute(Sender: TObject);
var
  sFormaPago: string;
begin
  inherited;
  sFormaPago := ValorCampoVista(FtvDetallePagos, 'CODIGO_FP_CFP');
  AbrirMantenimiento('CajaFormasPago', sFormaPago);
end;

procedure TfrmMtoCajaOperacionesHist.actIrPagoHistExecute(Sender: TObject);
var
  sEmpresa: string;
  sAlmacen: string;
  sCaja: string;
  sSerie: string;
  sOperacion: string;
  sLinea: string;
  sClave: string;
begin
  inherited;
  sEmpresa := ValorCampoVista(FtvDetallePagos, 'CODIGO_EMP_PAGO');
  sAlmacen := ValorCampoVista(FtvDetallePagos, 'CODIGO_ALM_PAGO');
  sCaja := ValorCampoVista(FtvDetallePagos, 'CODIGO_CAJA_PAGO');
  sSerie := ValorCampoVista(FtvDetallePagos, 'SERIE_OPERACION_PAGO');
  sOperacion := ValorCampoVista(FtvDetallePagos, 'NUMERO_OPERACION_PAGO');
  sLinea := ValorCampoVista(FtvDetallePagos, 'NUMERO_LINEA_PAGO');
  sClave := '';
  if (sEmpresa <> '') and
     (sAlmacen <> '') and
     (sCaja <> '') and
     (sOperacion <> '') and
     (sLinea <> '') then
    sClave := sEmpresa + ',' + sAlmacen + ',' + sCaja + ',' + sSerie + ',' +
              sOperacion + ',' + sLinea;
  AbrirMantenimiento('CajaPagosHist', sClave);
end;

procedure TfrmMtoCajaOperacionesHist.actIrMovimientoExecute(Sender: TObject);
var
  sMovimiento: string;
begin
  inherited;
  sMovimiento := ValorCampoVista(FtvDetalleMovimientos, 'NUMERO_MOV');
  AbrirMantenimiento('MovimientosAlmacen', sMovimiento);
end;

procedure TfrmMtoCajaOperacionesHist.actIrValeExecute(Sender: TObject);
var
  sVale: string;
begin
  inherited;
  sVale := ValorCampoVista(FtvDetalleVales, 'CODIGO_VL');
  AbrirMantenimiento('CajaValesHist', sVale);
end;

procedure TfrmMtoCajaOperacionesHist.actExportarOperacionExcelExecute(
                                                            Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  sNombre: string;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  fPreview := nil;
  if (not Assigned(dmmCajaOperacionesHist)) or
     (not Assigned(dmmCajaOperacionesHist.unqryTablaG)) or
     (not dmmCajaOperacionesHist.unqryTablaG.Active) or
     dmmCajaOperacionesHist.unqryTablaG.IsEmpty then
    ShowMessage('No hay ninguna operación seleccionada para exportar.')
  else
  begin
    try
      Screen.Cursor := crHourGlass;
      try
        RefrescarFichaOperacion;
        fPreview := TfrmMtoPreviewExcel.Create(Self);
        fPreview.PopupParent := Self;
        fPreview.DialogoGuardar.InitialDir :=
          oAppParams.GetPath('appDirExcel');
        sNombre := 'Operacion_Caja_' +
                   ValorCampoPrincipal('CODIGO_EMP_OPCAJA') + '_' +
                   ValorCampoPrincipal('CODIGO_ALM_OPCAJA') + '_' +
                   ValorCampoPrincipal('CODIGO_CAJA_OPCAJA') + '_' +
                   ValorCampoPrincipal('NUMERO_OPERACION_OPCAJA');
        fPreview.DialogoGuardar.FileName := sNombre;
        ExportarOperacionExcel(fPreview.dxSpreadSheet1);
      finally
        Screen.Cursor := crDefault;
      end;
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.SanearNombreHojaExcel(
  const ANombre: string): string;
var
  i: Integer;
begin
  Result := Trim(ANombre);
  for i := 1 to Length(Result) do
    if CharInSet(Result[i], ['\', '/', ':', '*', '?', '[', ']']) then
      Result[i] := '_';
  if Result = '' then
    Result := 'Hoja';
  Result := Copy(Result, 1, 31);
end;

function TfrmMtoCajaOperacionesHist.CrearHojaExcel(
  ASheetControl: TdxSpreadSheet;
  const ANombre: string): TdxSpreadSheetTableView;
var
  sNombre: string;
begin
  sNombre := SanearNombreHojaExcel(ANombre);
  Result := ASheetControl.AddSheet(sNombre,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Result.Caption := sNombre;
end;

function TfrmMtoCajaOperacionesHist.ValorExcelCampo(AField: TField): Variant;
begin
  Result := '';
  if Assigned(AField) and
     (not AField.IsNull) then
  begin
    case AField.DataType of
      ftDate, ftTime, ftDateTime, ftTimeStamp:
        Result := AField.AsDateTime;
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftFloat,
      ftCurrency, ftBCD, ftFMTBcd, ftSingle:
        Result := AField.AsFloat;
    else
      Result := AField.AsString;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarFormatoExcel(
  Sheet: TdxSpreadSheetTableView;
  ARow,
  ACol: Integer;
  AField: TField);
begin
  if Assigned(AField) and
     Assigned(Sheet.Cells[ARow, ACol]) then
  begin
    case AField.DataType of
      ftDate:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          'dd/mm/yyyy';
      ftTime:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode := 'hh:mm:ss';
      ftDateTime, ftTimeStamp:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          'dd/mm/yyyy hh:mm';
      ftCurrency:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          '#,##0.00" €"';
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftFloat,
      ftBCD, ftFMTBcd, ftSingle:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode := '#,##0.00';
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.VistaTieneDatos(
  AVista: TcxGridDBTableView): Boolean;
var
  ds: TDataSet;
begin
  Result := False;
  ds := nil;
  if Assigned(AVista) and
     Assigned(AVista.DataController.DataSource) then
    ds := AVista.DataController.DataSource.DataSet;
  if Assigned(ds) and
     ds.Active and
     (not ds.IsEmpty) and
     (AVista.VisibleColumnCount > 0) then
    Result := True;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarResumenExcel(
  ASheetControl: TdxSpreadSheet);
var
  Sheet: TdxSpreadSheetTableView;
  ds: TDataSet;
  Campo: TField;
  Col: TcxGridDBColumn;
  i, iRow, iFilaInicio: Integer;
begin
  Sheet := CrearHojaExcel(ASheetControl, 'Resumen');
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'OPERACIÓN DE CAJA', True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 16;
    Inc(iRow, 2);
    ds := nil;
    if Assigned(dmmCajaOperacionesHist) then
      ds := dmmCajaOperacionesHist.unqryTablaG;
    if (ds = nil) or
       (not ds.Active) or
       ds.IsEmpty then
      W(Sheet, iRow, 0, 'Sin operación seleccionada')
    else
    begin
      iFilaInicio := iRow;
      for i := 0 to cxGrdDBTabPrin.VisibleColumnCount - 1 do
      begin
        Col := cxGrdDBTabPrin.VisibleColumns[i] as TcxGridDBColumn;
        Campo := ds.FindField(Col.DataBinding.FieldName);
        W(Sheet, iRow, 0, Col.Caption, True);
        if Assigned(Campo) then
        begin
          W(Sheet, iRow, 1, ValorExcelCampo(Campo));
          AplicarFormatoExcel(Sheet, iRow, 1, Campo);
        end;
        Inc(iRow);
      end;
      Sheet.Columns[0].Size := 170;
      Sheet.Columns[1].Size := 260;
      PintarCuadro(Sheet, iFilaInicio, 0, iRow - 1, 1, sscbsThin);
    end;
  finally
    Sheet.EndUpdate;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarVistaExcel(
  ASheetControl: TdxSpreadSheet;
  const AHoja,
        ATitulo: string;
  AVista: TcxGridDBTableView);
var
  Sheet: TdxSpreadSheetTableView;
  ds: TDataSet;
  Bm: TBookmark;
  Campo: TField;
  Col: TcxGridDBColumn;
  iCol, iRow, iFilaCabecera: Integer;
begin
  if VistaTieneDatos(AVista) then
  begin
    Sheet := CrearHojaExcel(ASheetControl, AHoja);
    Sheet.BeginUpdate;
    try
      iRow := 1;
      W(Sheet, iRow, 0, ATitulo, True);
      Sheet.Cells[iRow, 0].Style.Font.Size := 14;
      Inc(iRow, 2);
      ds := AVista.DataController.DataSource.DataSet;
      iFilaCabecera := iRow;
      for iCol := 0 to AVista.VisibleColumnCount - 1 do
      begin
        Col := AVista.VisibleColumns[iCol] as TcxGridDBColumn;
        W(Sheet, iRow, iCol, Col.Caption, True, ssahCenter);
        Sheet.Cells[iRow, iCol].Style.Brush.BackgroundColor := clSilver;
        if Col.Width > 0 then
          Sheet.Columns[iCol].Size := Col.Width;
      end;
      Inc(iRow);
      ds.DisableControls;
      Bm := ds.GetBookmark;
      try
        ds.First;
        while not ds.Eof do
        begin
          for iCol := 0 to AVista.VisibleColumnCount - 1 do
          begin
            Col := AVista.VisibleColumns[iCol] as TcxGridDBColumn;
            Campo := ds.FindField(Col.DataBinding.FieldName);
            if Assigned(Campo) then
            begin
              W(Sheet, iRow, iCol, ValorExcelCampo(Campo));
              AplicarFormatoExcel(Sheet, iRow, iCol, Campo);
            end;
          end;
          Inc(iRow);
          ds.Next;
        end;
        if ds.BookmarkValid(Bm) then
          ds.GotoBookmark(Bm);
        finally
          ds.FreeBookmark(Bm);
          ds.EnableControls;
        end;
        PintarCuadro(Sheet,
                     iFilaCabecera,
                     0,
                     iRow - 1,
                     AVista.VisibleColumnCount - 1,
                     sscbsThin);
      finally
        Sheet.EndUpdate;
      end;
    end;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarOperacionExcel(
  ASheetControl: TdxSpreadSheet);
begin
  ASheetControl.ClearAll;
  ExportarResumenExcel(ASheetControl);
  ExportarVistaExcel(ASheetControl,
                     'Operación',
                     'Detalle de operación',
                     FtvDetalleOperacion);
  ExportarVistaExcel(ASheetControl,
                     'Pagos',
                     'Pagos de la operación',
                     FtvDetallePagos);
  ExportarVistaExcel(ASheetControl,
                     'Vales',
                     'Vales de la operación',
                     FtvDetalleVales);
  ExportarVistaExcel(ASheetControl,
                     'Movimientos',
                     'Movimientos de almacén',
                     FtvDetalleMovimientos);
  ExportarVistaExcel(ASheetControl,
                     'Cliente',
                     'Cliente de la operación',
                     FtvDetalleCliente);
  ExportarVistaExcel(ASheetControl,
                     'Depósitos',
                     'Depósitos de la operación',
                     FtvDetalleDepositos);
  ExportarVistaExcel(ASheetControl,
                     'Borrador',
                     'Cabecera del borrador',
                     FtvDetalleFacturaCab);
  ExportarVistaExcel(ASheetControl,
                     'Líneas borrador',
                     'Líneas del borrador',
                     FtvDetalleFacturaLin);
end;

function TfrmMtoCajaOperacionesHist.CrearVistaEnContenedor(
  AParent: TWinControl;
  const ANombreVista: string;
  ADataSource: TDataSource): TcxGridDBTableView;
var
  cxGrd: TcxGrid;
begin
  cxGrd := TcxGrid.Create(Self);
  cxGrd.Parent := AParent;
  cxGrd.Align := alClient;
  cxGrd.TabOrder := 0;
  Result := cxGrd.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  Result.Name := ANombreVista;
  Result.DataController.DataSource := ADataSource;
  Result.OptionsData.Deleting := False;
  Result.OptionsData.Editing := False;
  Result.OptionsData.Inserting := False;
  Result.OptionsSelection.CellSelect := False;
  Result.OptionsView.GroupByBox := False;
  Result.OptionsView.NoDataToDisplayInfoText := 'No hay datos';
  cxGrd.Levels.Add.GridView := Result;
end;

function TfrmMtoCajaOperacionesHist.CrearVistaDetalle(
  var APagina: TcxTabSheet;
  const ACaption,
        ANombreVista: string;
  ADataSource: TDataSource): TcxGridDBTableView;
begin
  APagina := TcxTabSheet.Create(Self);
  APagina.PageControl := FpcDetalleCaja;
  APagina.Caption := ACaption;
  Result := CrearVistaEnContenedor(APagina, ANombreVista, ADataSource);
end;

procedure TfrmMtoCajaOperacionesHist.AnadirColumna(
  AVista: TcxGridDBTableView;
  const ANombre,
        ACaption,
        ACampo: string;
  AAncho: Integer;
  const AClaseProp: string = '';
  const AFormato: string = '';
  AVisible: Boolean = True);
var
  col: TcxGridDBColumn;
begin
  col := AVista.CreateColumn;
  col.Name := ANombre;
  col.Caption := ACaption;
  col.DataBinding.FieldName := ACampo;
  col.Width := AAncho;
  col.Visible := AVisible;
  if AClaseProp <> '' then
  begin
    col.PropertiesClassName := AClaseProp;
    if (AFormato <> '') and
       (col.Properties is TcxCurrencyEditProperties) then
      TcxCurrencyEditProperties(col.Properties).DisplayFormat := AFormato
    else if (AFormato <> '') and
            (col.Properties is TcxDateEditProperties) then
      TcxDateEditProperties(col.Properties).DisplayFormat := AFormato;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CrearFichaDetalle;
var
  pnlFacturaCab: TPanel;
begin
  if not FDetalleCreado then
  begin
    FDetalleCreado := True;
    FpcDetalleCaja := TcxPageControl.Create(Self);
    FpcDetalleCaja.Parent := tsFicha;
    FpcDetalleCaja.Align := alClient;

    FtvDetalleOperacion := CrearVistaDetalle(FtsDetalleOperacion,
      'Operación', 'tvHistCajaOperacion', FdmConsulta.dsOperacion);
    CrearBarraAcciones(FtsDetalleOperacion,
      [FactExportarOperacionExcel]);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeFecha', 'Fecha/Hora',
      'FECHA_OPERACION_OPCAJA', 140, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn:ss');
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeTipo', 'Tipo',
      'TIPO_OPERACION_OPCAJA', 60);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeImporte', 'Importe',
      'IMPORTE_TOTAL_OPCAJA', 110, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeConcepto', 'Concepto',
      'CONCEPTO_GASTO_INGRESO_OPCAJA', 340);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeIdDep', 'Id depósito',
      'ID_DEPOSITO_OPCAJA', 160);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeSerieRef', 'Serie ref.',
      'SERIE_REF_ORIGEN_OPCAJA', 80);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeNroRef', 'Nro ref.',
      'NUMERO_REF_ORIGEN_OPCAJA', 80);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeMotivo', 'Motivo dev.',
      'MOTIVO_DEVOLUCION_OPCAJA', 130);
    AnadirColumna(FtvDetalleOperacion, 'colHistOpeEstadoDev', 'Est.Dev.',
      'ESTADO_DEVOLUCION_OPCAJA', 60);

    FtvDetallePagos := CrearVistaDetalle(FtsDetallePagos,
      'Pagos', 'tvHistCajaPagos', FdmConsulta.dsPagos);
    CrearBarraAcciones(FtsDetallePagos,
      [FactIrPagoHist, FactIrFormaPago, FactExportarOperacionExcel]);
    FtvDetallePagos.OptionsView.Footer := True;
    AnadirColumna(FtvDetallePagos, 'colHistPagLinea', 'Línea',
      'NUMERO_LINEA_PAGO', 96);
    AnadirColumna(FtvDetallePagos, 'colHistPagCodigo', 'Código',
      'CODIGO_FP_CFP', 106);
    AnadirColumna(FtvDetallePagos, 'colHistPagForma', 'Forma de pago',
      'DESCRIPCION_FORMA_PAGO_CFP', 142);
    AnadirColumna(FtvDetallePagos, 'colHistPagEntregado', 'Entregado',
      'IMPORTE_ENTREGADO_PAGO', 146, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetallePagos, 'colHistPagCambio', 'Cambio',
      'IMPORTE_CAMBIO_PAGO', 96, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetallePagos, 'colHistPagNeto', 'Neto',
      'IMPORTE_NETO_PAGO', 87, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetallePagos, 'colHistPagDivisa', 'Divisa',
      'CODIGO_DIVISA_PAGO', 97);
    AnadirColumna(FtvDetallePagos, 'colHistPagImpDivisa', 'Imp.divisa',
      'IMPORTE_DIVISA_PAGO', 150, 'TcxCurrencyEditProperties',
      '#,##0.00000000');
    AnadirColumna(FtvDetallePagos, 'colHistPagBlockchain', 'Red',
      'RED_BLOCKCHAIN_PAGO', 65);
    AnadirColumna(FtvDetallePagos, 'colHistPagReferencia', 'Referencia',
      'REFERENCIA_FACPAG', 131);
    AnadirColumna(FtvDetallePagos, 'colHistPagObs', 'Observaciones',
      'OBSERVACIONES_PAGO', 180);

    FtvDetalleVales := CrearVistaDetalle(FtsDetalleVales,
      'Vales', 'tvHistCajaVales', FdmConsulta.dsVales);
    CrearBarraAcciones(FtsDetalleVales,
      [FactIrVale, FactExportarOperacionExcel]);
    FtvDetalleVales.OptionsView.Footer := True;
    AnadirColumna(FtvDetalleVales, 'colHistValRol', 'Rol',
      'ROL_VL', 70);
    AnadirColumna(FtvDetalleVales, 'colHistValCodigo', 'Cód. vale',
      'CODIGO_VL', 180);
    AnadirColumna(FtvDetalleVales, 'colHistValPin', 'PIN',
      'PIN_SEGURIDAD_VL', 70);
    AnadirColumna(FtvDetalleVales, 'colHistValEstado', 'Estado',
      'ESTADO_VL', 110);
    AnadirColumna(FtvDetalleVales, 'colHistValNominal', 'Nominal',
      'IMPORTE_NOMINAL_VL', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleVales, 'colHistValRedimido', 'Redimido',
      'IMPORTE_REDIMIDO_VL', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleVales, 'colHistValEmision', 'F. Emisión',
      'FECHA_EMISION_VL', 130, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn');
    AnadirColumna(FtvDetalleVales, 'colHistValCaducidad', 'F. Caducidad',
      'FECHA_CADUCIDAD_VL', 110, 'TcxDateEditProperties', 'dd/mm/yyyy');
    AnadirColumna(FtvDetalleVales, 'colHistValRedencion', 'F. Redención',
      'FECHA_REDENCION_VL', 130, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn');
    AnadirColumna(FtvDetalleVales, 'colHistValPadre', 'Vale padre',
      'CODIGO_PADRE_VL', 140);
    AnadirColumna(FtvDetalleVales, 'colHistValObs', 'Observaciones',
      'OBSERVACIONES_VL', 200);

    FtvDetalleMovimientos := CrearVistaDetalle(FtsDetalleMovimientos,
      'Movimientos', 'tvHistCajaMovimientos', FdmConsulta.dsMovimientos);
    CrearBarraAcciones(FtsDetalleMovimientos,
      [FactIrMovimiento, FactIrArticulo, FactExportarOperacionExcel]);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovNum', 'Nº Mov',
      'NUMERO_MOV', 94);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovTipoDoc', 'Tipo Doc',
      'TIPO_DOC_MOV', 132);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovLinea', 'Línea',
      'LINEA_MOV', 90);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovAlmacen', 'Almacén',
      'CODIGO_ALM_MOV', 138);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovAlmacenContra',
      'Contra', 'CODIGO_ALM_CONTRA_MOV', 112);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovArticulo', 'Artículo',
      'CODIGO_ART_MOV', 88);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovSku', 'SKU',
      'CODIGO_UNIDAD_MOV', 126);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovDesc', 'Descripción',
      'DESCRIPCION_ART', 206);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovTipo', 'E/S',
      'TIPO_MOV', 89);
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovCantidad', 'Cantidad',
      'CANTIDAD_MOV', 91, 'TcxCurrencyEditProperties', '#,##0.00');
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovPMP', 'PMP',
      'PRECIO_MEDIO_MOV', 80, 'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleMovimientos, 'colHistMovCoste', 'Total coste',
      'TOTAL_COSTE_MOV', 100, 'TcxCurrencyEditProperties', '#,##0.00 €');

    FtvDetalleCliente := CrearVistaDetalle(FtsDetalleCliente,
      'Cliente', 'tvHistCajaCliente', FdmConsulta.dsCliente);
    CrearBarraAcciones(FtsDetalleCliente,
      [FactIrCliente, FactExportarOperacionExcel]);
    AnadirColumna(FtvDetalleCliente, 'colHistCliCodigo', 'Código',
      'CODIGO_CLI_CLI', 80);
    AnadirColumna(FtvDetalleCliente, 'colHistCliRazon', 'Razón social',
      'RAZON_SOCIAL_CLI', 250);
    AnadirColumna(FtvDetalleCliente, 'colHistCliNif', 'NIF', 'NIF_CLI', 100);
    AnadirColumna(FtvDetalleCliente, 'colHistCliMovil', 'Móvil',
      'MOVIL_CLI', 100);
    AnadirColumna(FtvDetalleCliente, 'colHistCliEmail', 'Email',
      'EMAIL_CLI', 180);
    AnadirColumna(FtvDetalleCliente, 'colHistCliDir1', 'Dirección',
      'DIRECCION1_CLI', 200);
    AnadirColumna(FtvDetalleCliente, 'colHistCliPobl', 'Población',
      'POBLACION_CLI', 130);
    AnadirColumna(FtvDetalleCliente, 'colHistCliProv', 'Provincia',
      'PROVINCIA_CLI', 120);
    AnadirColumna(FtvDetalleCliente, 'colHistCliCP', 'C.P.',
      'CODIGO_POSTAL_CLI', 60);
    AnadirColumna(FtvDetalleCliente, 'colHistCliDeuda', 'Deuda',
      'TOTAL_DEUDA_CLI', 100, 'TcxCurrencyEditProperties', '#,##0.00 €');

    FtvDetalleDepositos := CrearVistaDetalle(FtsDetalleDepositos,
      'Depósitos', 'tvHistCajaDepositos', FdmConsulta.dsDepositos);
    CrearBarraAcciones(FtsDetalleDepositos,
      [FactIrDeposito, FactIrCliente, FactIrArticulo,
       FactExportarOperacionExcel]);
    FtvDetalleDepositos.OptionsView.Footer := True;
    AnadirColumna(FtvDetalleDepositos, 'colHistDepRol', 'Rol',
      'ROL_EN_OPERACION', 110, '', '', False);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepEstado', 'Estado',
      'ESTADO_DEP', 130);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepId', 'Id depósito',
      'ID_DEPOSITO_DEP', 160);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepCli', 'Cliente',
      'CODIGO_CLI_DEP', 110);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepArt', 'Artículo',
      'CODIGO_ART_DEP', 141);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepSku', 'SKU',
      'CODIGO_UNIDAD_DEP', 160);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepAlm', 'Almacén',
      'CODIGO_ALM_DEP', 91);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepCant', 'Cantidad pdte.',
      'CANTIDAD_PENDIENTE_DEP', 131, 'TcxCurrencyEditProperties',
      '#,##0.00');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepPvp', 'Precio venta',
      'PRECIO_VENTA_DEP', 114, 'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepPorcIva', '% IVA',
      'PORCENTAJE_IVA_DEP', 55, 'TcxCurrencyEditProperties', '0.00');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepAnt', 'Anticipo',
      'IMPORTE_ANTICIPO_DEP', 90, 'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepPendiente', 'Pendiente',
      'IMPORTE_PENDIENTE_DEP', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepFecha', 'Fecha alta',
      'FECHA_CREACION_DEP', 120, 'TcxDateEditProperties',
      'dd/mm/yyyy hh:nn');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepFechaEntrega',
      'Fecha entrega', 'FECHA_ENTREGA_DEP', 146, 'TcxDateEditProperties',
      'dd/mm/yyyy');
    AnadirColumna(FtvDetalleDepositos, 'colHistDepEmpCancel',
      'Emp. cancel.', 'EMPRESA_CANCEL_DEP', 80, '', '', False);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepAlmCancel',
      'Alm. cancel.', 'ALMACEN_CANCEL_DEP', 80, '', '', False);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepCajCancel',
      'Caja cancel.', 'CAJA_CANCEL_DEP', 70, '', '', False);
    AnadirColumna(FtvDetalleDepositos, 'colHistDepNumOpeCancel',
      'Op. cancel.', 'NUMERO_OPERACION_CANCEL_DEP', 100, '', '', False);

    FtsDetalleFactura := TcxTabSheet.Create(Self);
    FtsDetalleFactura.PageControl := FpcDetalleCaja;
    FtsDetalleFactura.Caption := 'Borrador';
    CrearBarraAcciones(FtsDetalleFactura,
      [actIrFacturaSimplif, FactIrCliente, FactIrArticulo,
       FactExportarOperacionExcel]);
    pnlFacturaCab := TPanel.Create(Self);
    pnlFacturaCab.Parent := FtsDetalleFactura;
    pnlFacturaCab.Align := alTop;
    pnlFacturaCab.Height := 70;
    pnlFacturaCab.BevelOuter := bvNone;
    FtvDetalleFacturaCab := CrearVistaEnContenedor(pnlFacturaCab,
      'tvHistCajaFacturaCab', FdmConsulta.dsFactura);
    FtvDetalleFacturaLin := CrearVistaEnContenedor(FtsDetalleFactura,
      'tvHistCajaFacturaLin', FdmConsulta.dsFacturaLin);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacSerie', 'Serie',
      'SERIE_FAC', 80);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacNro', 'Nº',
      'NUMERO_FAC', 80);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacFecha', 'Fecha',
      'FECHA_FAC', 100, 'TcxDateEditProperties', 'dd/mm/yyyy');
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacTipo', 'Tipo',
      'TIPO_FAC', 110);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacCliente', 'Cliente',
      'CODIGO_CLI_FAC', 80);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacRazon', 'Razón social',
      'RAZON_SOCIAL_CLIENTE_FAC', 220);
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacBases', 'Bases',
      'TOTAL_BASES_FAC', 100, 'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacImp', 'Impuestos',
      'TOTAL_IMPUESTOS_FAC', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaCab, 'colHistFacLiq', 'Líquido',
      'TOTAL_LIQUIDO_FAC', 110, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlLinea', 'Lín',
      'LINEA_FACLIN', 50);
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlArt', 'Artículo',
      'CODIGO_ART_FACLIN', 110);
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlSku', 'SKU',
      'CODIGO_UNIDAD_FACLIN', 160);
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlDesc', 'Descripción',
      'DESCRIPCION_ARTICULO_FACLIN', 280);
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlCant', 'Cant.',
      'CANTIDAD_FACLIN', 70, 'TcxCurrencyEditProperties', '#,##0.00');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlPrSiva', 'P.S.IVA',
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN', 90,
      'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlPrCiva', 'P.C.IVA',
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN', 90,
      'TcxCurrencyEditProperties', '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlDto', '% Dto',
      'PORCENTAJE_DTO_FACLIN', 60, 'TcxCurrencyEditProperties', '0.00 %');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlTipoIva', 'T.IVA',
      'TIPO_IVA_ARTICULO_FACLIN', 50);
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlPorcIva', '% IVA',
      'PORCENTAJE_IVA_FACLIN', 60, 'TcxCurrencyEditProperties', '0.00');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlTotSiva', 'Tot. S.IVA',
      'TOTAL_FAC_SIVA_FACLIN', 100, 'TcxCurrencyEditProperties',
      '#,##0.00 €');
    AnadirColumna(FtvDetalleFacturaLin, 'colHistFlTotCiva', 'Tot. C.IVA',
      'TOTAL_FACLIN', 100, 'TcxCurrencyEditProperties', '#,##0.00 €');

    FpcDetalleCaja.ActivePage := FtsDetalleOperacion;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CerrarFichaOperacion;
begin
  if Assigned(FdmConsulta) then
  begin
    FdmConsulta.CerrarPestanasHijas;
    AjustarVisibilidadPestanasFicha;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RefrescarFichaOperacion;
var
  ds: TDataSet;
begin
  if Assigned(FdmConsulta) and
     Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) and
     dmmCajaOperacionesHist.unqryTablaG.Active and
     (not dmmCajaOperacionesHist.unqryTablaG.IsEmpty) then
  begin
    ds := dmmCajaOperacionesHist.unqryTablaG;
    FdmConsulta.CargarDetalleOperacion(
      ds.FieldByName('CODIGO_EMP_OPCAJA').AsString,
      ds.FieldByName('CODIGO_ALM_OPCAJA').AsString,
      ds.FieldByName('CODIGO_CAJA_OPCAJA').AsString,
      ds.FieldByName('NUMERO_OPERACION_OPCAJA').AsString,
      ds.FieldByName('CLIENTE').AsString,
      ds.FieldByName('SERIE_FAC').AsString,
      ds.FieldByName('NUMERO_FAC').AsString);
    AjustarVisibilidadPestanasFicha;
  end
  else
    CerrarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.AjustarVisibilidadPestanasFicha;
var
  PagActiva: TcxTabSheet;
begin
  if Assigned(FpcDetalleCaja) and Assigned(FdmConsulta) then
  begin
    PagActiva := FpcDetalleCaja.ActivePage;
    FtsDetalleOperacion.TabVisible := True;
    FtsDetallePagos.TabVisible := FdmConsulta.TienePagos;
    FtsDetalleVales.TabVisible := FdmConsulta.TieneVales;
    FtsDetalleMovimientos.TabVisible := FdmConsulta.TieneMovimientos;
    FtsDetalleCliente.TabVisible := FdmConsulta.TieneCliente;
    FtsDetalleDepositos.TabVisible := FdmConsulta.TieneDepositos;
    FtsDetalleFactura.TabVisible := FdmConsulta.TieneFactura;
    if Assigned(PagActiva) and
       (not PagActiva.TabVisible) then
      FpcDetalleCaja.ActivePage := FtsDetalleOperacion;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.OnTablaGDataChange(Sender: TObject;
                                                        Field: TField);
begin
  if (Field = nil) and
     Assigned(pcPantalla) and
     (pcPantalla.ActivePage = tsFicha) then
    RefrescarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.tsFichaShow(Sender: TObject);
begin
  inherited;
  RefrescarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.btnToggleFiltrosCajaClick(
                                                            Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  // Persiana: alterna visibilidad y altura del contenedor de filtros.
  pnlContFiltrosCaja.Visible := not pnlContFiltrosCaja.Visible;
  if pnlContFiltrosCaja.Visible then
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltrosCaja.Caption := #9660'  Filtros de carga';
  end
  else
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA;
    btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.btnGuardarPrecargaCajaClick(
                                                            Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  oList: TPerfilList;
begin
  sPermisos := '';
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text := Self.Name;
    formulario.edtDescripcion.Text := 'Guardar precarga';
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  if sPermisos <> '' then
  begin
    Screen.Cursor := crHourGlass;
    oList := TPerfilList.Create;
    try
      RecogerPerfilesParticulares(oList, sPermisos);
      oConn.StartTransaction;
      try
        odmPerfiles.GrabarPerfilesBatch(oList);
        oConn.Commit;
      except
        oConn.Rollback;
        raise;
      end;
    finally
      FreeAndNil(oList);
      Screen.Cursor := crDefault;
    end;
    ShowMessage('Precarga guardada.');
  end;
end;

procedure TfrmMtoCajaOperacionesHist.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+A): sin filtros de carga, asi el Locate
  // encuentra la operacion sea del año/almacen que sea. Reseteamos los
  // combos y el SQL antes de que inherited añada el WHERE de la PK.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
    dmmCajaOperacionesHist.unqryTablaG.SQL.Text := ConstruirSqlOperaciones;
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  inherited;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  // La instancia de busqueda llega directa a la ficha; el panel de filtros
  // de carga no aplica.
  pnlFiltrosCaja.Visible := False;
end;

procedure TfrmMtoCajaOperacionesHist.FormDestroy(Sender: TObject);
begin
  inherited;
  FreeAndNil(FdmConsulta);
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaOperacionesHist);
end.
