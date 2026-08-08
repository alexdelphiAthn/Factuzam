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
{    Herramientas auxiliares para consultar los metadatos de la BBDD.          }
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
  cxStyles, cxCustomListBox, cxListBox, SynEdit, SynEditHighlighter,
  SynHighlighterSQL,
  inMtoFrmBase, inLibMetadatosBBDDIntf, UniDataMetadatosBBDD;

type
  TfrmModalProcesosAuxiliaresBBDD = class(TfrmBase)
    procedure FormCreate(Sender: TObject);
  private
    pnlCuerpo: TPanel;
    pnlArbol: TPanel;
    pnlArbolBotones: TPanel;
    pnlContenidoBotones: TPanel;
    pnlBotonera: TPanel;
    splArbol: TSplitter;
    lstTablas: TcxListBox;
    pcDetalle: TcxPageControl;
    tsEstructura: TcxTabSheet;
    tsContenido: TcxTabSheet;
    synEstructura: TSynEdit;
    synSQL: TSynSQLSyn;
    grdContenido: TcxGrid;
    tvContenido: TcxGridDBTableView;
    lvContenido: TcxGridLevel;
    btnRefrescar: TcxButton;
    btnVerContenido: TcxButton;
    btnEditar: TcxButton;
    btnExportar: TcxButton;
    btnCopiarSQL: TcxButton;
    btnCerrar: TcxButton;
    lblAyuda: TcxLabel;
    FDataModule: TdmMetadatosBBDD;
    FCatalogo: ICatalogoMetadatosBBDD;
    procedure CrearInterfaz;
    procedure CrearArbol;
    procedure CrearDetalle;
    procedure CrearBotonera;
    procedure RefrescarMetadatos;
    procedure CargarTablas;
    procedure CargarEstructuraSeleccionada;
    procedure MostrarContenidoSeleccionado;
    procedure ActualizarAcciones;
    function MetadatoSeleccionado(
      out ATipo, ANombre: string): Boolean;
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnVerContenidoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnCopiarSQLClick(Sender: TObject);
    procedure lstTablasClick(Sender: TObject);
    procedure lstTablasDblClick(Sender: TObject);
  public
    destructor Destroy; override;
    class procedure Ejecutar(AOwner: TComponent);
  end;

implementation

uses
  Vcl.Clipbrd,
  inLibDevExp,
  inLibMsgComun,
  ts.Editor.CodeFormatters,
  UniDataMetadatosBBDDRepositorio;

{$R *.dfm}

procedure TfrmModalProcesosAuxiliaresBBDD.FormCreate(Sender: TObject);
begin
  inherited;
  CrearInterfaz;
  FDataModule := TdmMetadatosBBDD.Create(Self);
  FCatalogo := CrearCatalogoMetadatosBBDDUniDAC(
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
  pnlBotonera := TPanel.Create(Self);
  pnlBotonera.Parent := Self;
  pnlBotonera.Align := alBottom;
  pnlBotonera.Height := 58;
  pnlBotonera.BevelOuter := bvNone;
  pnlCuerpo := TPanel.Create(Self);
  pnlCuerpo.Parent := Self;
  pnlCuerpo.Align := alClient;
  pnlCuerpo.BevelOuter := bvNone;
  CrearArbol;
  CrearDetalle;
  CrearBotonera;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearArbol;
begin
  pnlArbol := TPanel.Create(Self);
  pnlArbol.Parent := pnlCuerpo;
  pnlArbol.Align := alLeft;
  pnlArbol.Width := 340;
  pnlArbol.BevelOuter := bvNone;
  pnlArbolBotones := TPanel.Create(Self);
  pnlArbolBotones.Parent := pnlArbol;
  pnlArbolBotones.Align := alBottom;
  pnlArbolBotones.Height := 82;
  pnlArbolBotones.BevelOuter := bvNone;
  lstTablas := TcxListBox.Create(Self);
  lstTablas.Parent := pnlArbol;
  lstTablas.Align := alClient;
  lstTablas.MultiSelect := True;
  lstTablas.ExtendedSelect := True;
  lstTablas.OnClick := lstTablasClick;
  lstTablas.OnDblClick := lstTablasDblClick;
  btnRefrescar := TcxButton.Create(Self);
  btnRefrescar.Parent := pnlArbolBotones;
  btnRefrescar.SetBounds(8, 8, 150, 30);
  btnRefrescar.Caption := '&Refrescar metadatos';
  btnRefrescar.OnClick := btnRefrescarClick;
  btnVerContenido := TcxButton.Create(Self);
  btnVerContenido.Parent := pnlArbolBotones;
  btnVerContenido.SetBounds(166, 8, 166, 30);
  btnVerContenido.Caption := '&Ver contenido';
  btnVerContenido.OnClick := btnVerContenidoClick;
  lblAyuda := TcxLabel.Create(Self);
  lblAyuda.Parent := pnlArbolBotones;
  lblAyuda.SetBounds(8, 46, 324, 24);
  lblAyuda.AutoSize := False;
  lblAyuda.Caption :=
    'Ctrl/Mayús selecciona varias; doble clic muestra la tabla activa.';
  lblAyuda.Transparent := True;
  splArbol := TSplitter.Create(Self);
  splArbol.Parent := pnlCuerpo;
  splArbol.Align := alLeft;
  splArbol.Width := 6;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearDetalle;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := pnlCuerpo;
  pcDetalle.Align := alClient;
  tsEstructura := TcxTabSheet.Create(Self);
  tsEstructura.PageControl := pcDetalle;
  tsEstructura.Caption := '&Estructura SQL';
  tsContenido := TcxTabSheet.Create(Self);
  tsContenido.PageControl := pcDetalle;
  tsContenido.Caption := '&Contenido';
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
  btnEditar := TcxButton.Create(Self);
  btnEditar.Parent := pnlContenidoBotones;
  btnEditar.SetBounds(8, 8, 128, 30);
  btnEditar.Caption := '&Editar datos';
  btnEditar.OnClick := btnEditarClick;
  btnExportar := TcxButton.Create(Self);
  btnExportar.Parent := pnlContenidoBotones;
  btnExportar.SetBounds(144, 8, 128, 30);
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
    SCaptionSinDatosMostrar;
  lvContenido := grdContenido.Levels.Add;
  lvContenido.GridView := tvContenido;
  pcDetalle.ActivePage := tsEstructura;
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

procedure TfrmModalProcesosAuxiliaresBBDD.RefrescarMetadatos;
begin
  Screen.Cursor := crHourGlass;
  try
    FCatalogo.Refrescar(ConexionPrincipal.Database);
    CargarTablas;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarTablas;
var
  sCodigo: string;
  sNombre: string;
  iCodigo: Integer;
begin
  lstTablas.Items.BeginUpdate;
  FDataModule.unqryMetadatos.DisableControls;
  try
    lstTablas.Items.Clear;
    FDataModule.unqryMetadatos.First;
    while not FDataModule.unqryMetadatos.Eof do
    begin
      sNombre := FDataModule.unqryMetadatos.FieldByName(
        'NOMBRE_META_META').AsString;
      sCodigo := FDataModule.unqryMetadatos.FieldByName(
        'CODIGO_META_META').AsString;
      iCodigo := StrToIntDef(sCodigo, 0);
      lstTablas.Items.AddObject(
        sNombre,
        TObject(NativeInt(iCodigo)));
      FDataModule.unqryMetadatos.Next;
    end;
  finally
    FDataModule.unqryMetadatos.EnableControls;
    lstTablas.Items.EndUpdate;
  end;
  if lstTablas.Count > 0 then
  begin
    lstTablas.ItemIndex := 0;
    lstTablas.Selected[0] := True;
    CargarEstructuraSeleccionada;
  end;
  ActualizarAcciones;
end;

function TfrmModalProcesosAuxiliaresBBDD.MetadatoSeleccionado(
  out ATipo, ANombre: string): Boolean;
var
  iCodigo: Integer;
begin
  ATipo := '';
  ANombre := '';
  Result := (lstTablas.ItemIndex >= 0) and
    (lstTablas.ItemIndex < lstTablas.Count);
  if Result then
  begin
    iCodigo := NativeInt(
      lstTablas.Items.Objects[lstTablas.ItemIndex]);
    Result := FDataModule.unqryMetadatos.Locate(
      'CODIGO_META_META',
      iCodigo,
      []);
  end;
  if Result then
  begin
    ATipo := FDataModule.unqryMetadatos.FieldByName(
      'PARENT_META').AsString;
    ANombre := FDataModule.unqryMetadatos.FieldByName(
      'NOMBRE_META_META').AsString;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarEstructuraSeleccionada;
var
  oFormateador: ICodeFormatter;
  sEstructura: string;
  sNombre: string;
  sTipo: string;
begin
  synEstructura.Lines.Clear;
  if MetadatoSeleccionado(sTipo, sNombre) and
     ((sTipo = '1') or (sTipo = '2') or (sTipo = '3')) then
  begin
    sEstructura := FCatalogo.CargarEstructura(sTipo, sNombre);
    if sTipo = '2' then
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
    if sTipo = '3' then
      sEstructura := StringReplace(
        sEstructura,
        ' DEFINER=`root`@`localhost`',
        '',
        [rfReplaceAll]);
    if (sTipo = '2') or (sTipo = '3') then
    begin
      oFormateador := GetSQLFormatter;
      sEstructura := oFormateador.Format(sEstructura);
    end;
    synEstructura.Lines.Text := sEstructura;
    tsEstructura.Caption := '&Estructura SQL - ' + sNombre;
  end
  else
    tsEstructura.Caption := '&Estructura SQL';
  pcDetalle.ActivePage := tsEstructura;
  ActualizarAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarContenidoSeleccionado;
var
  sNombre: string;
  sTipo: string;
begin
  if MetadatoSeleccionado(sTipo, sNombre) and
     ((sTipo = '1') or (sTipo = '2')) then
  begin
    if FDataModule.unqryContenido.State in [dsEdit, dsInsert] then
      FDataModule.unqryContenido.Post;
    tvContenido.OptionsData.Deleting := False;
    tvContenido.OptionsData.Editing := False;
    tvContenido.OptionsData.Inserting := False;
    btnEditar.Caption := '&Editar datos';
    tvContenido.ClearItems;
    FCatalogo.CargarContenido(sNombre);
    tvContenido.DataController.CreateAllItems;
    tvContenido.ApplyBestFit;
    tsContenido.Caption := '&Contenido - ' + sNombre;
    pcDetalle.ActivePage := tsContenido;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ActualizarAcciones;
var
  sNombre: string;
  sTipo: string;
  bSeleccionado: Boolean;
begin
  bSeleccionado := MetadatoSeleccionado(sTipo, sNombre);
  btnVerContenido.Enabled := bSeleccionado and (sTipo = '1');
  btnCopiarSQL.Enabled := Trim(synEstructura.Lines.Text) <> '';
  btnEditar.Enabled := FDataModule.unqryContenido.Active;
  btnExportar.Enabled := FDataModule.unqryContenido.Active;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRefrescarClick(
  Sender: TObject);
begin
  RefrescarMetadatos;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnVerContenidoClick(
  Sender: TObject);
begin
  MostrarContenidoSeleccionado;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEditarClick(
  Sender: TObject);
var
  bEditar: Boolean;
begin
  bEditar := not tvContenido.OptionsData.Editing;
  if (not bEditar) and
     (FDataModule.unqryContenido.State in [dsEdit, dsInsert]) then
    FDataModule.unqryContenido.Post;
  tvContenido.OptionsData.Deleting := bEditar;
  tvContenido.OptionsData.Editing := bEditar;
  tvContenido.OptionsData.Inserting := bEditar;
  if bEditar then
    btnEditar.Caption := '&Bloquear edición'
  else
    btnEditar.Caption := '&Editar datos';
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnExportarClick(
  Sender: TObject);
begin
  if FDataModule.unqryContenido.Active then
    ExportarExcel(
      ParametrosApp,
      grdContenido,
      'Metadatos_BBDD');
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnCopiarSQLClick(
  Sender: TObject);
begin
  if Trim(synEstructura.Lines.Text) <> '' then
    Clipboard.AsText := synEstructura.Lines.Text;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstTablasClick(
  Sender: TObject);
begin
  CargarEstructuraSeleccionada;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstTablasDblClick(
  Sender: TObject);
begin
  MostrarContenidoSeleccionado;
end;

end.
