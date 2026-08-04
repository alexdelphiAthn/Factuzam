{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalProcesosAuxiliaresBBDD                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Herramientas auxiliares sobre los objetos de la base de datos.            }
{******************************************************************************}
unit inMtoModalProcesosAuxiliaresBBDD;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.StdCtrls,
  cxButtons, cxClasses, cxControls, cxData, cxDataStorage, cxDBData,
  cxEdit, cxFilter, cxGraphics, cxGrid, cxGridCustomTableView,
  cxGridCustomView, cxGridDBTableView, cxGridLevel, cxGridTableView,
  cxLabel, cxLookAndFeelPainters, cxLookAndFeels, cxNavigator, cxPC,
  cxRadioGroup, cxStyles, cxCustomListBox, cxListBox, SynEdit,
  SynEditHighlighter, SynHighlighterSQL,
  inMtoFrmBase, inLibMetadatosBBDDIntf, UniDataMetadatosBBDD;

type
  TTipoOperacionAuxiliarTabla = (
    toatRegenerarTabla,
    toatRegenerarIndices,
    toatVaciarTabla,
    toatBorrarTabla
  );
  TTipoOtraAccionAuxiliar = (
    toaaVerMetadatos,
    toaaEditarTabla,
    toaaRegenerarTabla,
    toaaRegenerarIndices,
    toaaVaciarTabla,
    toaaBorrarTabla,
    toaaEjecutarVista,
    toaaRegenerarVista,
    toaaEjecutarProcedimiento,
    toaaAnalizarEstadisticas,
    toaaComprobarIntegridad,
    toaaVerEstadoTabla,
    toaaVerPlanVista,
    toaaVerDependencias,
    toaaExportarDDL,
    toaaRegenerarProcedimiento,
    toaaCalcularChecksum,
    toaaRefrescarMetadatos
  );
  TfrmModalProcesosAuxiliaresBBDD = class(TfrmBase)
    procedure FormCreate(Sender: TObject);
  private
    pnlSelector: TPanel;
    pnlCuerpo: TPanel;
    pnlLista: TPanel;
    pnlListaPie: TPanel;
    pnlAcciones: TPanel;
    pnlContenidoBotones: TPanel;
    pnlBotonera: TPanel;
    splLista: TSplitter;
    rgTipoObjeto: TcxRadioGroup;
    lstObjetos: TcxListBox;
    lstOtrasAcciones: TcxListBox;
    pcDetalle: TcxPageControl;
    tsEstructura: TcxTabSheet;
    tsContenido: TcxTabSheet;
    synEstructura: TSynEdit;
    synSQL: TSynSQLSyn;
    grdContenido: TcxGrid;
    tvContenido: TcxGridDBTableView;
    lvContenido: TcxGridLevel;
    btnEjecutarOtraAccion: TcxButton;
    btnExportar: TcxButton;
    btnCopiarSQL: TcxButton;
    btnCerrar: TcxButton;
    lblSelector: TcxLabel;
    lblSeleccion: TcxLabel;
    lblAcciones: TcxLabel;
    lblAyuda: TcxLabel;
    FDataModule: TdmMetadatosBBDD;
    FCatalogo: ICatalogoMetadatosBBDD;
    procedure CrearInterfaz;
    procedure CrearSelector;
    procedure CrearLista;
    procedure CrearDetalle;
    procedure CrearAcciones;
    procedure CrearListaOtrasAcciones;
    procedure CrearBotonera;
    procedure CerrarContenidoActual;
    procedure RefrescarMetadatos;
    procedure CargarObjetos;
    procedure CargarObjetosConSeleccion(
      const ASeleccionados: TArray<string>;
      const AObjetoActivo: string);
    procedure CargarEstructuraSeleccionada;
    procedure MostrarContenidoSeleccionado(AEditar: Boolean);
    procedure MostrarDatosActuales(
      const ATitulo: string;
      AEditar: Boolean);
    procedure ActualizarAcciones;
    procedure ActualizarListaOtrasAcciones;
    procedure AgregarOtraAccion(
      const ATexto: string;
      AAccion: TTipoOtraAccionAuxiliar);
    procedure EjecutarOtraAccion;
    procedure MostrarResultadoOperacion(const ATitulo: string);
    procedure ExportarDDLSeleccionado;
    procedure RegenerarProcedimientosSeleccionados;
    procedure EjecutarOperacionTablas(
      AOperacion: TTipoOperacionAuxiliarTabla);
    procedure EjecutarRegeneracionVistas;
    function TipoObjetoActivo: TTipoObjetoMetadatosBBDD;
    function ObjetoActivo(out ANombre: string): Boolean;
    function ObjetosSeleccionados: TArray<string>;
    function CantidadObjetosSeleccionados: Integer;
    function TextoObjetosSeleccionados(
      const AObjetos: TArray<string>): string;
    function ConfirmarOperacion(
      const AAccion, AAdvertencia: string;
      ARequiereCopia: Boolean): Boolean;
    function CrearCopiaSeguridad: Boolean;
    function OtraAccionSeleccionada(
      out AAccion: TTipoOtraAccionAuxiliar): Boolean;
    procedure rgTipoObjetoChange(Sender: TObject);
    procedure lstObjetosClick(Sender: TObject);
    procedure lstObjetosDblClick(Sender: TObject);
    procedure btnVerMetadatosClick(Sender: TObject);
    procedure btnEditarTablaClick(Sender: TObject);
    procedure btnRegenerarTablaClick(Sender: TObject);
    procedure btnRegenerarIndicesClick(Sender: TObject);
    procedure btnVaciarTablaClick(Sender: TObject);
    procedure btnBorrarTablaClick(Sender: TObject);
    procedure btnEjecutarVistaClick(Sender: TObject);
    procedure btnRegenerarVistaClick(Sender: TObject);
    procedure btnEjecutarProcedimientoClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnEjecutarOtraAccionClick(Sender: TObject);
    procedure lstOtrasAccionesDblClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnCopiarSQLClick(Sender: TObject);
  public
    destructor Destroy; override;
    class procedure Ejecutar(AOwner: TComponent);
  end;

implementation

uses
  System.StrUtils, System.UITypes, Vcl.Clipbrd, Vcl.Dialogs,
  inLibAnfitrionMtoIntf, inLibDevExp, ts.Editor.CodeFormatters,
  UniDataMetadatosBBDDRepositorio;

{$R *.dfm}

procedure TfrmModalProcesosAuxiliaresBBDD.FormCreate(Sender: TObject);
begin
  inherited;
  CrearInterfaz;
  FDataModule := TdmMetadatosBBDD.Create(Self);
  FCatalogo := CrearCatalogoMetadatosBBDDUniDAC(
    ConexionPrincipal,
    FDataModule.unqryMetadatos,
    FDataModule.unqryEstructura,
    FDataModule.unqryContenido,
    FDataModule.unstrdprcRefrescar);
  tvContenido.DataController.DataSource := FDataModule.dsContenido;
  RefrescarMetadatos;
end;

destructor TfrmModalProcesosAuxiliaresBBDD.Destroy;
begin
  FCatalogo := nil;
  inherited;
end;

class procedure TfrmModalProcesosAuxiliaresBBDD.Ejecutar(
  AOwner: TComponent);
var
  oFormulario: TfrmModalProcesosAuxiliaresBBDD;
begin
  oFormulario := TfrmModalProcesosAuxiliaresBBDD.Create(AOwner);
  try
    oFormulario.ShowModal;
  finally
    oFormulario.Free;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearInterfaz;
begin
  CrearSelector;
  pnlBotonera := TPanel.Create(Self);
  pnlBotonera.Parent := Self;
  pnlBotonera.Align := alBottom;
  pnlBotonera.Height := 58;
  pnlBotonera.BevelOuter := bvNone;
  pnlCuerpo := TPanel.Create(Self);
  pnlCuerpo.Parent := Self;
  pnlCuerpo.Align := alClient;
  pnlCuerpo.BevelOuter := bvNone;
  CrearLista;
  CrearAcciones;
  CrearDetalle;
  CrearBotonera;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearSelector;
var
  oItem: TcxRadioGroupItem;
begin
  pnlSelector := TPanel.Create(Self);
  pnlSelector.Parent := Self;
  pnlSelector.Align := alTop;
  pnlSelector.Height := 92;
  pnlSelector.BevelOuter := bvNone;
  lblSelector := TcxLabel.Create(Self);
  lblSelector.Parent := pnlSelector;
  lblSelector.SetBounds(12, 5, 400, 24);
  lblSelector.Caption := 'Tipo de objeto de base de datos';
  lblSelector.Transparent := True;
  rgTipoObjeto := TcxRadioGroup.Create(Self);
  rgTipoObjeto.Parent := pnlSelector;
  rgTipoObjeto.SetBounds(12, 28, ClientWidth - 24, 58);
  rgTipoObjeto.Anchors := [akLeft, akTop, akRight];
  rgTipoObjeto.Properties.Columns := 3;
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := '&Tablas';
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := '&Vistas';
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := '&Procedimientos almacenados';
  rgTipoObjeto.ItemIndex := 0;
  rgTipoObjeto.Properties.OnEditValueChanged := rgTipoObjetoChange;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearLista;
begin
  pnlLista := TPanel.Create(Self);
  pnlLista.Parent := pnlCuerpo;
  pnlLista.Align := alLeft;
  pnlLista.Width := 310;
  pnlLista.BevelOuter := bvNone;
  lblSeleccion := TcxLabel.Create(Self);
  lblSeleccion.Parent := pnlLista;
  lblSeleccion.Align := alTop;
  lblSeleccion.Height := 28;
  lblSeleccion.Caption := 'Objetos disponibles';
  lblSeleccion.Transparent := True;
  pnlListaPie := TPanel.Create(Self);
  pnlListaPie.Parent := pnlLista;
  pnlListaPie.Align := alBottom;
  pnlListaPie.Height := 55;
  pnlListaPie.BevelOuter := bvNone;
  lblAyuda := TcxLabel.Create(Self);
  lblAyuda.Parent := pnlListaPie;
  lblAyuda.Align := alClient;
  lblAyuda.AutoSize := False;
  lblAyuda.Caption :=
    'Use Ctrl o Mayús para seleccionar varios objetos.';
  lblAyuda.Properties.WordWrap := True;
  lblAyuda.Transparent := True;
  lstObjetos := TcxListBox.Create(Self);
  lstObjetos.Parent := pnlLista;
  lstObjetos.Align := alClient;
  lstObjetos.MultiSelect := True;
  lstObjetos.ExtendedSelect := True;
  lstObjetos.OnClick := lstObjetosClick;
  lstObjetos.OnDblClick := lstObjetosDblClick;
  splLista := TSplitter.Create(Self);
  splLista.Parent := pnlCuerpo;
  splLista.Align := alLeft;
  splLista.Width := 6;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearDetalle;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := pnlCuerpo;
  pcDetalle.Align := alClient;
  tsEstructura := TcxTabSheet.Create(Self);
  tsEstructura.PageControl := pcDetalle;
  tsEstructura.Caption := '&Metadatos SQL';
  tsContenido := TcxTabSheet.Create(Self);
  tsContenido.PageControl := pcDetalle;
  tsContenido.Caption := '&Resultado';
  synSQL := TSynSQLSyn.Create(Self);
  synSQL.SQLDialect := sqlMySQL;
  synEstructura := TSynEdit.Create(Self);
  synEstructura.Parent := tsEstructura;
  synEstructura.Align := alClient;
  synEstructura.Font.Name := 'Consolas';
  synEstructura.Font.Size := 10;
  synEstructura.Gutter.ShowLineNumbers := True;
  synEstructura.Highlighter := synSQL;
  synEstructura.ReadOnly := True;
  synEstructura.ScrollBars := ssBoth;
  pnlContenidoBotones := TPanel.Create(Self);
  pnlContenidoBotones.Parent := tsContenido;
  pnlContenidoBotones.Align := alTop;
  pnlContenidoBotones.Height := 46;
  pnlContenidoBotones.BevelOuter := bvNone;
  btnExportar := TcxButton.Create(Self);
  btnExportar.Parent := pnlContenidoBotones;
  btnExportar.SetBounds(8, 8, 148, 30);
  btnExportar.Caption := 'Exportar a E&xcel';
  btnExportar.OnClick := btnExportarClick;
  grdContenido := TcxGrid.Create(Self);
  grdContenido.Parent := tsContenido;
  grdContenido.Align := alClient;
  tvContenido := grdContenido.CreateView(
    TcxGridDBTableView) as TcxGridDBTableView;
  tvContenido.Navigator.Visible := True;
  tvContenido.OptionsData.Deleting := False;
  tvContenido.OptionsData.Editing := False;
  tvContenido.OptionsData.Inserting := False;
  tvContenido.OptionsView.GroupByBox := False;
  tvContenido.OptionsView.NoDataToDisplayInfoText :=
    '<No hay datos a mostrar>';
  lvContenido := grdContenido.Levels.Add;
  lvContenido.GridView := tvContenido;
  pcDetalle.ActivePage := tsEstructura;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearAcciones;
begin
  pnlAcciones := TPanel.Create(Self);
  pnlAcciones.Parent := pnlCuerpo;
  pnlAcciones.Align := alRight;
  pnlAcciones.Width := 280;
  pnlAcciones.BevelOuter := bvNone;
  lblAcciones := TcxLabel.Create(Self);
  lblAcciones.Parent := pnlAcciones;
  lblAcciones.SetBounds(12, 4, 256, 24);
  lblAcciones.Caption := 'Operaciones compatibles';
  lblAcciones.Transparent := True;
  CrearListaOtrasAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearListaOtrasAcciones;
begin
  lstOtrasAcciones := TcxListBox.Create(Self);
  lstOtrasAcciones.Parent := pnlAcciones;
  lstOtrasAcciones.SetBounds(
    12,
    32,
    256,
    pnlAcciones.Height - 84);
  lstOtrasAcciones.Anchors := [akLeft, akTop, akRight, akBottom];
  lstOtrasAcciones.OnDblClick := lstOtrasAccionesDblClick;
  btnEjecutarOtraAccion := TcxButton.Create(Self);
  btnEjecutarOtraAccion.Parent := pnlAcciones;
  btnEjecutarOtraAccion.SetBounds(
    12,
    pnlAcciones.Height - 44,
    256,
    34);
  btnEjecutarOtraAccion.Anchors := [akLeft, akRight, akBottom];
  btnEjecutarOtraAccion.Caption := 'Ejecutar operación';
  btnEjecutarOtraAccion.OnClick := btnEjecutarOtraAccionClick;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearBotonera;
begin
  btnCopiarSQL := TcxButton.Create(Self);
  btnCopiarSQL.Parent := pnlBotonera;
  btnCopiarSQL.SetBounds(12, 12, 150, 34);
  btnCopiarSQL.Caption := '&Copiar SQL';
  btnCopiarSQL.OnClick := btnCopiarSQLClick;
  btnCerrar := TcxButton.Create(Self);
  btnCerrar.Parent := pnlBotonera;
  btnCerrar.SetBounds(ClientWidth - 162, 12, 150, 34);
  btnCerrar.Anchors := [akTop, akRight];
  btnCerrar.Caption := '&Cerrar';
  btnCerrar.Cancel := True;
  btnCerrar.Default := True;
  btnCerrar.ModalResult := mrCancel;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CerrarContenidoActual;
begin
  if Assigned(FDataModule) then
  begin
    if FDataModule.unqryContenido.State in [dsEdit, dsInsert] then
      FDataModule.unqryContenido.Post;
    FDataModule.unqryContenido.Close;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.RefrescarMetadatos;
var
  aSeleccionados: TArray<string>;
  sObjetoActivo: string;
begin
  aSeleccionados := ObjetosSeleccionados;
  sObjetoActivo := '';
  if (lstObjetos.ItemIndex >= 0) and
     (lstObjetos.ItemIndex < lstObjetos.Count) then
    sObjetoActivo := lstObjetos.Items[lstObjetos.ItemIndex];
  Screen.Cursor := crHourGlass;
  try
    CerrarContenidoActual;
    FCatalogo.Refrescar(ConexionPrincipal.Database);
    CargarObjetosConSeleccion(
      aSeleccionados,
      sObjetoActivo);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarObjetos;
var
  aSeleccionados: TArray<string>;
begin
  SetLength(aSeleccionados, 0);
  CargarObjetosConSeleccion(aSeleccionados, '');
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarObjetosConSeleccion(
  const ASeleccionados: TArray<string>;
  const AObjetoActivo: string);
var
  bSeleccionado: Boolean;
  i: Integer;
  iPrimeroSeleccionado: Integer;
  j: Integer;
  sNombre: string;
begin
  CerrarContenidoActual;
  FCatalogo.CargarObjetos(TipoObjetoActivo);
  lstObjetos.Items.BeginUpdate;
  FDataModule.unqryMetadatos.DisableControls;
  try
    lstObjetos.Items.Clear;
    FDataModule.unqryMetadatos.First;
    while not FDataModule.unqryMetadatos.Eof do
    begin
      sNombre := FDataModule.unqryMetadatos.FieldByName(
        'NOMBRE_META_META').AsString;
      lstObjetos.Items.Add(sNombre);
      FDataModule.unqryMetadatos.Next;
    end;
  finally
    FDataModule.unqryMetadatos.EnableControls;
    lstObjetos.Items.EndUpdate;
  end;
  synEstructura.Lines.Clear;
  tsEstructura.Caption := '&Metadatos SQL';
  tsContenido.Caption := '&Resultado';
  pcDetalle.ActivePage := tsEstructura;
  lstObjetos.ItemIndex := -1;
  iPrimeroSeleccionado := -1;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    bSeleccionado := False;
    j := 0;
    while (j < Length(ASeleccionados)) and
          not bSeleccionado do
    begin
      bSeleccionado := SameText(
        lstObjetos.Items[i],
        ASeleccionados[j]);
      Inc(j);
    end;
    lstObjetos.Selected[i] := bSeleccionado;
    if bSeleccionado and (iPrimeroSeleccionado < 0) then
      iPrimeroSeleccionado := i;
    if SameText(lstObjetos.Items[i], AObjetoActivo) then
      lstObjetos.ItemIndex := i;
  end;
  if lstObjetos.Count > 0 then
  begin
    if lstObjetos.ItemIndex < 0 then
      lstObjetos.ItemIndex := iPrimeroSeleccionado;
    if lstObjetos.ItemIndex < 0 then
      lstObjetos.ItemIndex := 0;
    if iPrimeroSeleccionado < 0 then
      lstObjetos.Selected[lstObjetos.ItemIndex] := True;
    CargarEstructuraSeleccionada;
  end;
  ActualizarListaOtrasAcciones;
  ActualizarAcciones;
end;

function TfrmModalProcesosAuxiliaresBBDD.TipoObjetoActivo:
  TTipoObjetoMetadatosBBDD;
begin
  if rgTipoObjeto.ItemIndex = 1 then
    Result := tombVista
  else if rgTipoObjeto.ItemIndex = 2 then
    Result := tombProcedimiento
  else
    Result := tombTabla;
end;

function TfrmModalProcesosAuxiliaresBBDD.ObjetoActivo(
  out ANombre: string): Boolean;
begin
  ANombre := '';
  Result := (lstObjetos.ItemIndex >= 0) and
    (lstObjetos.ItemIndex < lstObjetos.Count);
  if Result then
  begin
    ANombre := lstObjetos.Items[lstObjetos.ItemIndex];
    Result := FDataModule.unqryMetadatos.Locate(
      'NOMBRE_META_META',
      ANombre,
      []);
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.ObjetosSeleccionados:
  TArray<string>;
var
  i: Integer;
  iCantidad: Integer;
begin
  SetLength(Result, CantidadObjetosSeleccionados);
  iCantidad := 0;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    if lstObjetos.Selected[i] then
    begin
      Result[iCantidad] := lstObjetos.Items[i];
      Inc(iCantidad);
    end;
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.CantidadObjetosSeleccionados:
  Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    if lstObjetos.Selected[i] then
      Inc(Result);
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.TextoObjetosSeleccionados(
  const AObjetos: TArray<string>): string;
var
  i: Integer;
  iLimite: Integer;
begin
  Result := '';
  iLimite := Length(AObjetos);
  if iLimite > 15 then
    iLimite := 15;
  for i := 0 to iLimite - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + AObjetos[i];
  end;
  if Length(AObjetos) > iLimite then
    Result := Result + Format(
      ' y %d más',
      [Length(AObjetos) - iLimite]);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarEstructuraSeleccionada;
var
  oFormateador: ICodeFormatter;
  sEstructura: string;
  sNombre: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  synEstructura.Lines.Clear;
  if ObjetoActivo(sNombre) then
  begin
    eTipo := TipoObjetoActivo;
    sEstructura := FCatalogo.CargarEstructura(eTipo, sNombre);
    if eTipo = tombVista then
    begin
      sEstructura := StringReplace(
        sEstructura,
        'ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` ' +
        'SQL SECURITY DEFINER',
        '',
        [rfReplaceAll]);
      sEstructura := StringReplace(
        sEstructura,
        ' separator '',''',
        '',
        [rfReplaceAll, rfIgnoreCase]);
      sEstructura := StringReplace(
        sEstructura,
        '`',
        '',
        [rfReplaceAll]);
      while Pos('  ', sEstructura) > 0 do
        sEstructura := StringReplace(
          sEstructura,
          '  ',
          ' ',
          [rfReplaceAll]);
    end;
    if eTipo = tombProcedimiento then
      sEstructura := StringReplace(
        sEstructura,
        ' DEFINER=`root`@`localhost`',
        '',
        [rfReplaceAll]);
    if eTipo in [tombVista, tombProcedimiento] then
    begin
      oFormateador := GetSQLFormatter;
      sEstructura := oFormateador.Format(sEstructura);
    end;
    synEstructura.Lines.Text := sEstructura;
    tsEstructura.Caption := '&Metadatos SQL - ' + sNombre;
  end
  else
    tsEstructura.Caption := '&Metadatos SQL';
  pcDetalle.ActivePage := tsEstructura;
  ActualizarAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarDatosActuales(
  const ATitulo: string;
  AEditar: Boolean);
begin
  tvContenido.ClearItems;
  tvContenido.DataController.CreateAllItems;
  tvContenido.ApplyBestFit;
  tvContenido.OptionsData.Deleting := AEditar;
  tvContenido.OptionsData.Editing := AEditar;
  tvContenido.OptionsData.Inserting := AEditar;
  tsContenido.Caption := ATitulo;
  pcDetalle.ActivePage := tsContenido;
  ActualizarListaOtrasAcciones;
  ActualizarAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarContenidoSeleccionado(
  AEditar: Boolean);
var
  sNombre: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  eTipo := TipoObjetoActivo;
  if ObjetoActivo(sNombre) and
     (eTipo in [tombTabla, tombVista]) then
  begin
    CerrarContenidoActual;
    FCatalogo.CargarContenido(sNombre);
    AEditar := AEditar and (eTipo = tombTabla);
    MostrarDatosActuales('&Resultado - ' + sNombre, AEditar);
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ActualizarAcciones;
begin
  btnCopiarSQL.Enabled := Trim(synEstructura.Lines.Text) <> '';
  btnExportar.Enabled := FDataModule.unqryContenido.Active;
  btnEjecutarOtraAccion.Enabled := lstOtrasAcciones.ItemIndex >= 0;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.AgregarOtraAccion(
  const ATexto: string;
  AAccion: TTipoOtraAccionAuxiliar);
begin
  lstOtrasAcciones.Items.AddObject(
    ATexto,
    TObject(NativeInt(AAccion)));
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ActualizarListaOtrasAcciones;
var
  iSeleccionados: Integer;
begin
  iSeleccionados := CantidadObjetosSeleccionados;
  lstOtrasAcciones.Items.BeginUpdate;
  try
    lstOtrasAcciones.Items.Clear;
    if (iSeleccionados > 0) and
       (TipoObjetoActivo = tombTabla) then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          'Ver metadatos',
          toaaVerMetadatos);
        if tvContenido.OptionsData.Editing then
          AgregarOtraAccion(
            'Bloquear edición de tabla',
            toaaEditarTabla)
        else
          AgregarOtraAccion(
            'Editar datos de tabla',
            toaaEditarTabla);
        AgregarOtraAccion(
          'Ver estado y tamaño',
          toaaVerEstadoTabla);
        AgregarOtraAccion(
          'Ver dependencias',
          toaaVerDependencias);
      end;
      AgregarOtraAccion(
        'Analizar estadísticas',
        toaaAnalizarEstadisticas);
      AgregarOtraAccion(
        'Comprobar integridad',
        toaaComprobarIntegridad);
      AgregarOtraAccion(
        'Regenerar tabla',
        toaaRegenerarTabla);
      AgregarOtraAccion(
        'Regenerar índices',
        toaaRegenerarIndices);
      AgregarOtraAccion(
        'Exportar DDL seleccionado',
        toaaExportarDDL);
      AgregarOtraAccion(
        'Calcular checksum',
        toaaCalcularChecksum);
      AgregarOtraAccion(
        'Vaciar tabla',
        toaaVaciarTabla);
      AgregarOtraAccion(
        'Borrar tabla',
        toaaBorrarTabla);
    end
    else if (iSeleccionados > 0) and
            (TipoObjetoActivo = tombVista) then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          'Ver metadatos',
          toaaVerMetadatos);
        AgregarOtraAccion(
          'Ver datos / ejecutar vista',
          toaaEjecutarVista);
        AgregarOtraAccion(
          'Ver plan de ejecución',
          toaaVerPlanVista);
        AgregarOtraAccion(
          'Ver dependencias',
          toaaVerDependencias);
      end;
      AgregarOtraAccion(
        'Comprobar integridad',
        toaaComprobarIntegridad);
      AgregarOtraAccion(
        'Regenerar vista',
        toaaRegenerarVista);
      AgregarOtraAccion(
        'Exportar DDL seleccionado',
        toaaExportarDDL);
    end
    else if iSeleccionados > 0 then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          'Ver metadatos',
          toaaVerMetadatos);
        AgregarOtraAccion(
          'Ejecutar procedimiento',
          toaaEjecutarProcedimiento);
      end;
      AgregarOtraAccion(
        'Regenerar procedimiento',
        toaaRegenerarProcedimiento);
      AgregarOtraAccion(
        'Exportar DDL seleccionado',
        toaaExportarDDL);
    end;
    AgregarOtraAccion(
      'Refrescar metadatos',
      toaaRefrescarMetadatos);
  finally
    lstOtrasAcciones.Items.EndUpdate;
  end;
  if lstOtrasAcciones.Count > 0 then
    lstOtrasAcciones.ItemIndex := 0;
end;

function TfrmModalProcesosAuxiliaresBBDD.OtraAccionSeleccionada(
  out AAccion: TTipoOtraAccionAuxiliar): Boolean;
begin
  Result := (lstOtrasAcciones.ItemIndex >= 0) and
    (lstOtrasAcciones.ItemIndex < lstOtrasAcciones.Count);
  if Result then
    AAccion := TTipoOtraAccionAuxiliar(
      NativeInt(
        lstOtrasAcciones.Items.Objects[
          lstOtrasAcciones.ItemIndex]));
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarResultadoOperacion(
  const ATitulo: string);
begin
  MostrarDatosActuales('&Resultado - ' + ATitulo, False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ExportarDDLSeleccionado;
var
  aObjetos: TArray<string>;
  i: Integer;
  oDialogo: TSaveDialog;
  oLineas: TStringList;
  sSQL: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  aObjetos := ObjetosSeleccionados;
  eTipo := TipoObjetoActivo;
  if Length(aObjetos) > 0 then
  begin
    oLineas := TStringList.Create;
    try
      for i := 0 to Length(aObjetos) - 1 do
      begin
        sSQL := FCatalogo.CargarEstructura(eTipo, aObjetos[i]);
        oLineas.Add('-- ' + aObjetos[i]);
        if eTipo = tombProcedimiento then
        begin
          oLineas.Add('DELIMITER $$');
          oLineas.Add(sSQL + '$$');
          oLineas.Add('DELIMITER ;');
        end
        else
        begin
          if not EndsText(';', Trim(sSQL)) then
            sSQL := sSQL + ';';
          oLineas.Add(sSQL);
        end;
        oLineas.Add('');
      end;
      synEstructura.Lines.Assign(oLineas);
      tsEstructura.Caption := '&DDL seleccionado';
      pcDetalle.ActivePage := tsEstructura;
      oDialogo := TSaveDialog.Create(Self);
      try
        oDialogo.DefaultExt := 'sql';
        oDialogo.Filter := 'Script SQL (*.sql)|*.sql';
        oDialogo.FileName := 'objetos_bbdd.sql';
        if oDialogo.Execute then
          oLineas.SaveToFile(oDialogo.FileName, TEncoding.UTF8);
      finally
        oDialogo.Free;
      end;
    finally
      oLineas.Free;
    end;
    ActualizarAcciones;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.
  RegenerarProcedimientosSeleccionados;
var
  aObjetos: TArray<string>;
  sAccion: string;
begin
  aObjetos := ObjetosSeleccionados;
  sAccion := 'Se regenerarán estos procedimientos: ' +
    TextoObjetosSeleccionados(aObjetos) + '.';
  if (Length(aObjetos) > 0) and
     ConfirmarOperacion(
       sAccion,
       'Se volverá a aplicar la definición actual de cada procedimiento.',
       False) then
  begin
    Screen.Cursor := crHourGlass;
    try
      FCatalogo.RegenerarProcedimientos(aObjetos);
    finally
      Screen.Cursor := crDefault;
    end;
    MessageDlg(
      'Procedimientos regenerados correctamente.',
      mtInformation,
      [mbOk],
      0);
    CargarEstructuraSeleccionada;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarOtraAccion;
var
  aObjetos: TArray<string>;
  sNombre: string;
  sTextoObjetos: string;
  eAccion: TTipoOtraAccionAuxiliar;
begin
  aObjetos := ObjetosSeleccionados;
  sTextoObjetos := TextoObjetosSeleccionados(aObjetos);
  if OtraAccionSeleccionada(eAccion) then
  begin
    case eAccion of
      toaaVerMetadatos:
        btnVerMetadatosClick(Self);
      toaaEditarTabla:
        btnEditarTablaClick(Self);
      toaaRegenerarTabla:
        btnRegenerarTablaClick(Self);
      toaaRegenerarIndices:
        btnRegenerarIndicesClick(Self);
      toaaVaciarTabla:
        btnVaciarTablaClick(Self);
      toaaBorrarTabla:
        btnBorrarTablaClick(Self);
      toaaEjecutarVista:
        btnEjecutarVistaClick(Self);
      toaaRegenerarVista:
        btnRegenerarVistaClick(Self);
      toaaEjecutarProcedimiento:
        btnEjecutarProcedimientoClick(Self);
      toaaAnalizarEstadisticas:
      begin
        if ConfirmarOperacion(
             'Se analizarán estas tablas: ' + sTextoObjetos + '.',
             'La operación puede tardar en tablas grandes.',
             False) then
        begin
          FCatalogo.AnalizarTablas(aObjetos);
          MostrarResultadoOperacion('análisis de estadísticas');
        end;
      end;
      toaaComprobarIntegridad:
      begin
        if ConfirmarOperacion(
             'Se comprobarán estos objetos: ' + sTextoObjetos + '.',
             'La comprobación puede bloquear objetos mientras se ejecuta.',
             False) then
        begin
          FCatalogo.ComprobarObjetos(aObjetos);
          MostrarResultadoOperacion('comprobación de integridad');
        end;
      end;
      toaaVerEstadoTabla:
      begin
        if ObjetoActivo(sNombre) then
        begin
          FCatalogo.CargarEstadoTabla(sNombre);
          MostrarResultadoOperacion('estado de ' + sNombre);
        end;
      end;
      toaaVerPlanVista:
      begin
        if ObjetoActivo(sNombre) then
        begin
          FCatalogo.CargarPlanVista(sNombre);
          MostrarResultadoOperacion('plan de ' + sNombre);
        end;
      end;
      toaaVerDependencias:
      begin
        if ObjetoActivo(sNombre) then
        begin
          FCatalogo.CargarDependencias(
            TipoObjetoActivo,
            sNombre);
          MostrarResultadoOperacion('dependencias de ' + sNombre);
        end;
      end;
      toaaExportarDDL:
        ExportarDDLSeleccionado;
      toaaRegenerarProcedimiento:
        RegenerarProcedimientosSeleccionados;
      toaaCalcularChecksum:
      begin
        if ConfirmarOperacion(
             'Se calculará el checksum de: ' + sTextoObjetos + '.',
             'Puede requerir leer por completo las tablas seleccionadas.',
             False) then
        begin
          FCatalogo.CalcularChecksum(aObjetos);
          MostrarResultadoOperacion('checksum');
        end;
      end;
      toaaRefrescarMetadatos:
        btnRefrescarClick(Self);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarRegeneracionVistas;
var
  aObjetos: TArray<string>;
  sAccion: string;
begin
  aObjetos := ObjetosSeleccionados;
  sAccion := 'Se regenerarán estas vistas: ' +
    TextoObjetosSeleccionados(aObjetos) + '.';
  if (Length(aObjetos) > 0) and
     ConfirmarOperacion(
       sAccion,
       'Se volverá a aplicar la definición actual de cada vista.',
       False) then
  begin
    Screen.Cursor := crHourGlass;
    try
      FCatalogo.RegenerarVistas(aObjetos);
    finally
      Screen.Cursor := crDefault;
    end;
    MessageDlg(
      'Vistas regeneradas correctamente.',
      mtInformation,
      [mbOk],
      0);
    CargarEstructuraSeleccionada;
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.CrearCopiaSeguridad: Boolean;
var
  oAnfitrion: IAnfitrionMantenimiento;
begin
  Result := Supports(Owner, IAnfitrionMantenimiento, oAnfitrion);
  if not Result then
    Result := Supports(
      Application.MainForm,
      IAnfitrionMantenimiento,
      oAnfitrion);
  if Result then
    Result := oAnfitrion.CrearCopiaPreviaScriptSoporte
  else
    MessageDlg(
      'No está disponible el servicio de copia de seguridad.',
      mtError,
      [mbOk],
      0);
end;

function TfrmModalProcesosAuxiliaresBBDD.ConfirmarOperacion(
  const AAccion, AAdvertencia: string;
  ARequiereCopia: Boolean): Boolean;
var
  sMensaje: string;
begin
  sMensaje := AAccion + sLineBreak + sLineBreak + AAdvertencia;
  if ARequiereCopia then
    sMensaje := sMensaje + sLineBreak + sLineBreak +
      'Antes de continuar se solicitará una copia de seguridad completa.';
  sMensaje := sMensaje + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  Result := MessageDlg(
    sMensaje,
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
  if Result and ARequiereCopia then
    Result := CrearCopiaSeguridad;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarOperacionTablas(
  AOperacion: TTipoOperacionAuxiliarTabla);
var
  aObjetos: TArray<string>;
  sAccion: string;
  sAdvertencia: string;
  bRequiereCopia: Boolean;
begin
  aObjetos := ObjetosSeleccionados;
  sAccion := '';
  sAdvertencia := '';
  bRequiereCopia := False;
  case AOperacion of
    toatRegenerarTabla:
    begin
      sAccion := 'Se regenerarán estas tablas: ' +
        TextoObjetosSeleccionados(aObjetos) + '.';
      sAdvertencia :=
        'La operación puede bloquear las tablas y tardar varios minutos.';
    end;
    toatRegenerarIndices:
    begin
      sAccion := 'Se regenerarán los índices de estas tablas: ' +
        TextoObjetosSeleccionados(aObjetos) + '.';
      sAdvertencia :=
        'La operación puede bloquear las tablas y tardar varios minutos.';
    end;
    toatVaciarTabla:
    begin
      sAccion := 'Se vaciarán estas tablas: ' +
        TextoObjetosSeleccionados(aObjetos) + '.';
      sAdvertencia :=
        'Se eliminarán todos sus registros y no se puede deshacer.';
      bRequiereCopia := True;
    end;
    toatBorrarTabla:
    begin
      sAccion := 'Se borrarán estas tablas: ' +
        TextoObjetosSeleccionados(aObjetos) + '.';
      sAdvertencia :=
        'Se eliminarán las tablas, sus datos y su estructura.';
      bRequiereCopia := True;
    end;
  end;
  if (Length(aObjetos) > 0) and
     ConfirmarOperacion(sAccion, sAdvertencia, bRequiereCopia) then
  begin
    Screen.Cursor := crHourGlass;
    try
      case AOperacion of
        toatRegenerarTabla:
          FCatalogo.RegenerarTablas(aObjetos);
        toatRegenerarIndices:
          FCatalogo.RegenerarIndices(aObjetos);
        toatVaciarTabla:
          FCatalogo.VaciarTablas(aObjetos);
        toatBorrarTabla:
          FCatalogo.BorrarTablas(aObjetos);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
    MessageDlg(
      'Operación finalizada correctamente.',
      mtInformation,
      [mbOk],
      0);
    if AOperacion in [toatVaciarTabla, toatBorrarTabla] then
      RefrescarMetadatos
    else
      CargarEstructuraSeleccionada;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.rgTipoObjetoChange(
  Sender: TObject);
begin
  CargarObjetos;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstObjetosClick(
  Sender: TObject);
begin
  ActualizarListaOtrasAcciones;
  CargarEstructuraSeleccionada;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstObjetosDblClick(
  Sender: TObject);
begin
  if TipoObjetoActivo = tombVista then
    btnEjecutarVistaClick(Sender)
  else if TipoObjetoActivo = tombProcedimiento then
    btnEjecutarProcedimientoClick(Sender)
  else
    MostrarContenidoSeleccionado(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnVerMetadatosClick(
  Sender: TObject);
begin
  CargarEstructuraSeleccionada;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEditarTablaClick(
  Sender: TObject);
var
  bEditar: Boolean;
begin
  bEditar := not tvContenido.OptionsData.Editing;
  if (pcDetalle.ActivePage <> tsContenido) or
     not FDataModule.unqryContenido.Active then
    bEditar := True;
  if bEditar then
    MostrarContenidoSeleccionado(True)
  else
  begin
    if FDataModule.unqryContenido.State in [dsEdit, dsInsert] then
      FDataModule.unqryContenido.Post;
    tvContenido.OptionsData.Deleting := False;
    tvContenido.OptionsData.Editing := False;
    tvContenido.OptionsData.Inserting := False;
    ActualizarListaOtrasAcciones;
    ActualizarAcciones;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatRegenerarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarIndicesClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatRegenerarIndices);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnVaciarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatVaciarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnBorrarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatBorrarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarVistaClick(
  Sender: TObject);
begin
  MostrarContenidoSeleccionado(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarVistaClick(
  Sender: TObject);
begin
  EjecutarRegeneracionVistas;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarProcedimientoClick(
  Sender: TObject);
var
  sNombre: string;
  sSQL: string;
begin
  if ObjetoActivo(sNombre) then
  begin
    sSQL := FCatalogo.GenerarLlamadaProcedimiento(sNombre);
    if InputQuery(
         'Ejecutar procedimiento almacenado',
         'Revise la llamada e indique los valores de los parámetros:',
         sSQL) and
       (Trim(sSQL) <> '') then
    begin
      CerrarContenidoActual;
      FCatalogo.EjecutarConsulta(sSQL);
      MostrarDatosActuales('&Resultado - ' + sNombre, False);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRefrescarClick(
  Sender: TObject);
begin
  RefrescarMetadatos;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarOtraAccionClick(
  Sender: TObject);
begin
  EjecutarOtraAccion;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstOtrasAccionesDblClick(
  Sender: TObject);
begin
  EjecutarOtraAccion;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnExportarClick(
  Sender: TObject);
begin
  if FDataModule.unqryContenido.Active then
    ExportarExcel(
      ParametrosApp,
      grdContenido,
      'Procesos_auxiliares_BBDD');
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnCopiarSQLClick(
  Sender: TObject);
begin
  if Trim(synEstructura.Lines.Text) <> '' then
    Clipboard.AsText := synEstructura.Lines.Text;
end;

end.
