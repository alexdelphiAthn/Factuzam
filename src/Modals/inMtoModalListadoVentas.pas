{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalListadoVentas                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       26/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Listado en grid de lineas de factura de venta. Incluye filtros de fecha,  }
{    familia, proveedor y temporada, con precarga de los ultimos dos anyos.    }
{******************************************************************************}
unit inMtoModalListadoVentas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxButtons, cxCheckBox, cxCurrencyEdit,
  JvComponentBase, JvEnterTab;

type
  TfrmModalListadoVentas = class(TfrmBase)
    procedure FormCreate(Sender: TObject);
  private
    // Campos primero (E2169).
    pnlFiltros:            TPanel;
    pnlBotones:            TPanel;
    lblDesde:              TcxLabel;
    lblHasta:              TcxLabel;
    lblFamilia:            TcxLabel;
    lblProveedor:          TcxLabel;
    lblTemporada:          TcxLabel;
    lblInfo:               TcxLabel;
    lblPrimeraVenta:       TcxLabel;
    lblUltimaVenta:        TcxLabel;
    dteDesde:              TcxDateEdit;
    dteHasta:              TcxDateEdit;
    cbbFamilia:            TcxComboBox;
    cbbProveedor:          TcxComboBox;
    cbbTemporada:          TcxComboBox;
    chkSoloConsolidadas:   TcxCheckBox;
    btnBuscar:             TcxButton;
    btnExcel:              TcxButton;
    btnSalir:              TcxButton;
    cxgrdVentas:           TcxGrid;
    tvVentas:              TcxGridDBTableView;
    lvVentas:              TcxGridLevel;
    unqryVentas:           TUniQuery;
    dsVentas:              TDataSource;
    pmVentas:              TPopupMenu;
    miAgregarDocumento:    TMenuItem;
    procedure CrearInterfaz;
    procedure CrearFiltros;
    procedure CrearGrid;
    procedure CrearColumnas;
    procedure CrearMenuContextual;
    procedure CargarCombos;
    procedure CargarCombo(ACombo: TcxComboBox;
                          const ASQL,
                                ACampoCodigo,
                                ACampoNombre: string);
    procedure CargarListado;
    procedure ActualizarResumenListado;
    procedure btnBuscarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure pmVentasPopup(Sender: TObject);
    procedure miAgregarDocumentoClick(Sender: TObject);
    function  CodigoCombo(ACombo: TcxComboBox): string;
    function  NuevaColumna(const ACampo,
                                 ACaption: string;
                           AAncho: Integer): TcxGridDBColumn;
    procedure ConfigurarMoneda(ACol: TcxGridDBColumn);
    procedure ConfigurarNumero(ACol: TcxGridDBColumn);
    procedure MostrarFotoArticuloActivo;
    function  SQLListado: string;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
  end;

implementation

uses
  System.Diagnostics, inLibDevExp, inLibFotos, inLibLog,
  inLibDocumentosTrabajo, inLibDocumentosTrabajoPresentacion,
  UniDataDocumentosTrabajoRepositorio,
  inMtoFotoArticulo, UniDataRectificativasSql,
  inLibMsgComun, inLibMsgVentas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmModalListadoVentas.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  KeyPreview := True;
  unqryVentas := TUniQuery.Create(Self);
  unqryVentas.Connection := ConexionPrincipal;
  dsVentas := TDataSource.Create(Self);
  dsVentas.DataSet := unqryVentas;
  CrearInterfaz;
  CargarCombos;
  CargarListado;
end;

procedure TfrmModalListadoVentas.CrearInterfaz;
begin
  CrearFiltros;
  CrearGrid;
  pnlBotones := TPanel.Create(Self);
  pnlBotones.Parent := Self;
  pnlBotones.Align := alBottom;
  pnlBotones.Height := 46;
  pnlBotones.BevelOuter := bvNone;
  lblInfo := TcxLabel.Create(Self);
  lblInfo.Parent := pnlBotones;
  lblInfo.Left := 12;
  lblInfo.Top := 12;
  lblInfo.Width := 170;
  lblInfo.Transparent := True;
  lblPrimeraVenta := TcxLabel.Create(Self);
  lblPrimeraVenta.Parent := pnlBotones;
  lblPrimeraVenta.Left := 194;
  lblPrimeraVenta.Top := 12;
  lblPrimeraVenta.Width := 220;
  lblPrimeraVenta.Transparent := True;
  lblUltimaVenta := TcxLabel.Create(Self);
  lblUltimaVenta.Parent := pnlBotones;
  lblUltimaVenta.Left := 426;
  lblUltimaVenta.Top := 12;
  lblUltimaVenta.Width := 220;
  lblUltimaVenta.Transparent := True;
  btnExcel := TcxButton.Create(Self);
  btnExcel.Parent := pnlBotones;
  btnExcel.Left := 888;
  btnExcel.Top := 8;
  btnExcel.Width := 130;
  btnExcel.Height := 30;
  btnExcel.Caption := SCaptionExportarExcel;
  btnExcel.Anchors := [akTop, akRight];
  btnExcel.OnClick := btnExcelClick;
  btnSalir := TcxButton.Create(Self);
  btnSalir.Parent := pnlBotones;
  btnSalir.Left := 1030;
  btnSalir.Top := 8;
  btnSalir.Width := 130;
  btnSalir.Height := 30;
  btnSalir.Caption := SCaptionSalir;
  btnSalir.Anchors := [akTop, akRight];
  btnSalir.OnClick := btnSalirClick;
end;

procedure TfrmModalListadoVentas.CrearFiltros;
begin
  pnlFiltros := TPanel.Create(Self);
  pnlFiltros.Parent := Self;
  pnlFiltros.Align := alTop;
  pnlFiltros.Height := 92;
  pnlFiltros.BevelOuter := bvNone;
  lblDesde := TcxLabel.Create(Self);
  lblDesde.Parent := pnlFiltros;
  lblDesde.Left := 12;
  lblDesde.Top := 10;
  lblDesde.Caption := SCaptionDesde;
  lblDesde.Transparent := True;
  dteDesde := TcxDateEdit.Create(Self);
  dteDesde.Parent := pnlFiltros;
  dteDesde.Left := 12;
  dteDesde.Top := 32;
  dteDesde.Width := 112;
  dteDesde.Date := IncYear(Date, -2);
  lblHasta := TcxLabel.Create(Self);
  lblHasta.Parent := pnlFiltros;
  lblHasta.Left := 136;
  lblHasta.Top := 10;
  lblHasta.Caption := SCaptionHasta;
  lblHasta.Transparent := True;
  dteHasta := TcxDateEdit.Create(Self);
  dteHasta.Parent := pnlFiltros;
  dteHasta.Left := 136;
  dteHasta.Top := 32;
  dteHasta.Width := 112;
  dteHasta.Date := Date;
  lblFamilia := TcxLabel.Create(Self);
  lblFamilia.Parent := pnlFiltros;
  lblFamilia.Left := 268;
  lblFamilia.Top := 10;
  lblFamilia.Caption := SCaptionFamilia;
  lblFamilia.Transparent := True;
  cbbFamilia := TcxComboBox.Create(Self);
  cbbFamilia.Parent := pnlFiltros;
  cbbFamilia.Left := 268;
  cbbFamilia.Top := 32;
  cbbFamilia.Width := 220;
  cbbFamilia.Properties.DropDownListStyle := lsFixedList;
  lblProveedor := TcxLabel.Create(Self);
  lblProveedor.Parent := pnlFiltros;
  lblProveedor.Left := 500;
  lblProveedor.Top := 10;
  lblProveedor.Caption := SCaptionProveedor;
  lblProveedor.Transparent := True;
  cbbProveedor := TcxComboBox.Create(Self);
  cbbProveedor.Parent := pnlFiltros;
  cbbProveedor.Left := 500;
  cbbProveedor.Top := 32;
  cbbProveedor.Width := 250;
  cbbProveedor.Properties.DropDownListStyle := lsFixedList;
  lblTemporada := TcxLabel.Create(Self);
  lblTemporada.Parent := pnlFiltros;
  lblTemporada.Left := 762;
  lblTemporada.Top := 10;
  lblTemporada.Caption := SCaptionTemporada;
  lblTemporada.Transparent := True;
  cbbTemporada := TcxComboBox.Create(Self);
  cbbTemporada.Parent := pnlFiltros;
  cbbTemporada.Left := 762;
  cbbTemporada.Top := 32;
  cbbTemporada.Width := 170;
  cbbTemporada.Properties.DropDownListStyle := lsFixedList;
  chkSoloConsolidadas := TcxCheckBox.Create(Self);
  chkSoloConsolidadas.Parent := pnlFiltros;
  chkSoloConsolidadas.Left := 944;
  chkSoloConsolidadas.Top := 32;
  chkSoloConsolidadas.Width := 130;
  chkSoloConsolidadas.Caption := SCaptionSoloEmitidas;
  chkSoloConsolidadas.Checked := True;
  btnBuscar := TcxButton.Create(Self);
  btnBuscar.Parent := pnlFiltros;
  btnBuscar.Left := 1082;
  btnBuscar.Top := 30;
  btnBuscar.Width := 82;
  btnBuscar.Height := 28;
  btnBuscar.Caption := SCaptionBuscar;
  btnBuscar.Anchors := [akTop, akRight];
  btnBuscar.OnClick := btnBuscarClick;
end;

procedure TfrmModalListadoVentas.CrearGrid;
begin
  cxgrdVentas := TcxGrid.Create(Self);
  cxgrdVentas.Parent := Self;
  cxgrdVentas.Align := alClient;
  tvVentas :=
    cxgrdVentas.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  tvVentas.Name := 'tvListadoVentas';
  tvVentas.DataController.DataSource := dsVentas;
  tvVentas.OptionsData.Appending := False;
  tvVentas.OptionsData.Deleting := False;
  tvVentas.OptionsData.Editing := False;
  tvVentas.OptionsData.Inserting := False;
  tvVentas.OptionsSelection.CellSelect := True;
  tvVentas.OptionsView.GroupByBox := True;
  tvVentas.OptionsView.NoDataToDisplayInfoText := 'No hay ventas';
  lvVentas := cxgrdVentas.Levels.Add;
  lvVentas.GridView := tvVentas;
  CrearColumnas;
  CrearMenuContextual;
end;

procedure TfrmModalListadoVentas.CrearMenuContextual;
begin
  pmVentas := TPopupMenu.Create(Self);
  pmVentas.OnPopup := pmVentasPopup;
  miAgregarDocumento := TMenuItem.Create(pmVentas);
  miAgregarDocumento.Caption := SCaptionAnadirDocumentoTrabajo;
  miAgregarDocumento.OnClick := miAgregarDocumentoClick;
  pmVentas.Items.Add(miAgregarDocumento);
  cxgrdVentas.PopupMenu := pmVentas;
end;

procedure TfrmModalListadoVentas.CrearColumnas;
var
  col: TcxGridDBColumn;
begin
  NuevaColumna('FECHA_FAC', 'Fecha', 86);
  NuevaColumna('DOCUMENTO_FAC', 'Documento', 112);
  NuevaColumna('TIPO_FAC', 'Tipo', 96);
  NuevaColumna('FASE_FAC', 'Fase', 96);
  NuevaColumna('ESCONSOLIDADA_FAC', 'Emitida', 68);
  NuevaColumna('CODIGO_ALM_FACLIN', 'Almacen', 80);
  NuevaColumna('CODIGO_CLI_FAC', 'Cliente', 86);
  NuevaColumna('RAZON_SOCIAL_CLIENTE_FAC', 'Razon social cliente', 190);
  NuevaColumna('LINEA_FACLIN', 'Linea', 62);
  NuevaColumna('CODIGO_ART_FACLIN', 'Articulo', 96);
  NuevaColumna('CODIGO_UNIDAD_FACLIN', 'SKU', 140);
  NuevaColumna('DESCRIPCION_ARTICULO_FACLIN', 'Descripcion', 230);
  NuevaColumna('DESCRIPCION_VARIACION_FACLIN', 'Variacion', 120);
  NuevaColumna('REF_PROVEEDOR', 'Modelo', 120);
  NuevaColumna('CODIGO_FAM_FACLIN', 'Cod. familia', 90);
  NuevaColumna('NOMBRE_FAM_FACLIN', 'Familia', 150);
  NuevaColumna('CODIGO_PRV_FACLIN', 'Cod. prov.', 80);
  NuevaColumna('RAZON_SOCIAL_PROVEEDOR_FACLIN', 'Proveedor', 170);
  NuevaColumna('TEMPORADA_ART', 'Temporada', 130);
  col := NuevaColumna('CANTIDAD_FACLIN', 'Cantidad', 82);
  ConfigurarNumero(col);
  col := NuevaColumna('PRECIO_SALIDA_FACLIN', 'Precio salida', 96);
  ConfigurarMoneda(col);
  col := NuevaColumna('PORCENTAJE_DTO_FACLIN', 'Dto. %', 72);
  ConfigurarNumero(col);
  col := NuevaColumna('PRECIO_VENTA_SIVA_ARTICULO_FACLIN', 'PVP s/IVA', 94);
  ConfigurarMoneda(col);
  col := NuevaColumna('PRECIO_VENTA_CIVA_ARTICULO_FACLIN', 'PVP c/IVA', 94);
  ConfigurarMoneda(col);
  col := NuevaColumna('TOTAL_FAC_SIVA_FACLIN', 'Total s/IVA', 96);
  ConfigurarMoneda(col);
  col := NuevaColumna('TOTAL_FACLIN', 'Total c/IVA', 96);
  ConfigurarMoneda(col);
end;

function TfrmModalListadoVentas.NuevaColumna(const ACampo,
  ACaption: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := tvVentas.CreateColumn;
  Result.Caption := ACaption;
  Result.DataBinding.FieldName := ACampo;
  Result.Width := AAncho;
  Result.Options.Editing := False;
end;

procedure TfrmModalListadoVentas.ConfigurarMoneda(ACol: TcxGridDBColumn);
var
  props: TcxCurrencyEditProperties;
begin
  if ACol <> nil then
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    props := TcxCurrencyEditProperties(ACol.Properties);
    props.DisplayFormat := '#,##0.00;-#,##0.00;0.00';
    props.UseDisplayFormatWhenEditing := True;
  end;
end;

procedure TfrmModalListadoVentas.ConfigurarNumero(ACol: TcxGridDBColumn);
var
  props: TcxCurrencyEditProperties;
begin
  if ACol <> nil then
  begin
    ACol.PropertiesClass := TcxCurrencyEditProperties;
    props := TcxCurrencyEditProperties(ACol.Properties);
    props.DisplayFormat := '#,##0.##;-#,##0.##;0';
    props.UseDisplayFormatWhenEditing := True;
  end;
end;

procedure TfrmModalListadoVentas.CargarCombos;
begin
  CargarCombo(cbbFamilia,
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    '       COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, CODIGO_FAM_FAM) NOM ' +
    '  FROM fza_articulos_familias ' +
    ' WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_FAM, CODIGO_FAM_FAM',
    'COD', 'NOM');
  CargarCombo(cbbProveedor,
    'SELECT CODIGO_PRV_PRV AS COD, RAZON_SOCIAL_PRV AS NOM ' +
    '  FROM fza_proveedores ' +
    ' WHERE IFNULL(ESACTIVO_PRV, ''S'') = ''S'' ' +
    ' ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV',
    'COD', 'NOM');
  CargarCombo(cbbTemporada,
    'SELECT PV AS COD, PV AS NOM ' +
    '  FROM fza_propiedades_valores ' +
    ' WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    '   AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    ' ORDER BY PV',
    'COD', 'NOM');
end;

procedure TfrmModalListadoVentas.CargarCombo(ACombo: TcxComboBox;
  const ASQL, ACampoCodigo, ACampoNombre: string);
var
  q: TUniQuery;
  sCod: string;
  sNom: string;
begin
  if ACombo <> nil then
  begin
    ACombo.Properties.Items.BeginUpdate;
    try
      ACombo.Properties.Items.Clear;
      ACombo.Properties.Items.Add('(Todos)');
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionPrincipal;
        q.SQL.Text := ASQL;
        q.Open;
        while not q.Eof do
        begin
          sCod := q.FieldByName(ACampoCodigo).AsString;
          sNom := q.FieldByName(ACampoNombre).AsString;
          if (sNom <> '') and (sNom <> sCod) then
            ACombo.Properties.Items.Add(sCod + ' - ' + sNom)
          else
            ACombo.Properties.Items.Add(sCod);
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;
    finally
      ACombo.Properties.Items.EndUpdate;
    end;
    ACombo.ItemIndex := 0;
  end;
end;

procedure TfrmModalListadoVentas.CargarListado;
var
  sw: TStopwatch;
  sConsolidadas: string;
begin
  if dteDesde.Date <= 0 then
    dteDesde.Date := IncYear(Date, -2);
  if dteHasta.Date <= 0 then
    dteHasta.Date := Date;
  if dteHasta.Date < dteDesde.Date then
    dteHasta.Date := dteDesde.Date;
  if chkSoloConsolidadas.Checked then
    sConsolidadas := 'S'
  else
    sConsolidadas := 'N';
  Screen.Cursor := crHourGlass;
  sw := TStopwatch.StartNew;
  try
    try
      unqryVentas.Close;
      unqryVentas.SQL.Text := SQLListado;
      unqryVentas.ParamByName('pDESDE').AsDateTime := Trunc(dteDesde.Date);
      unqryVentas.ParamByName('pHASTA').AsDateTime :=
        Trunc(dteHasta.Date) + 1;
      unqryVentas.ParamByName('pFAM').AsString := CodigoCombo(cbbFamilia);
      unqryVentas.ParamByName('pPRV').AsString := CodigoCombo(cbbProveedor);
      unqryVentas.ParamByName('pTMP').AsString := CodigoCombo(cbbTemporada);
      unqryVentas.ParamByName('pCON').AsString := sConsolidadas;
      unqryVentas.Open;
      ActualizarResumenListado;
      Log.LogPerf('ListadoVentas.CargarListado',
        Format('filas=%d', [unqryVentas.RecordCount]),
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        Log.LogError('ListadoVentas.CargarListado: ' + E.Message);
        raise;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalListadoVentas.ActualizarResumenListado;
var
  dPrimeraVenta: TDateTime;
  dUltimaVenta: TDateTime;
begin
  lblInfo.Caption := Format(SCaptionLineasCargadas,
                            [unqryVentas.RecordCount]);
  lblPrimeraVenta.Caption := SCaptionPrimeraVentaVacia;
  lblUltimaVenta.Caption := SCaptionUltimaVentaVacia;
  if not unqryVentas.IsEmpty then
  begin
    unqryVentas.DisableControls;
    try
      unqryVentas.First;
      dUltimaVenta := unqryVentas.FieldByName('FECHA_FAC').AsDateTime;
      unqryVentas.Last;
      dPrimeraVenta := unqryVentas.FieldByName('FECHA_FAC').AsDateTime;
      unqryVentas.First;
    finally
      unqryVentas.EnableControls;
    end;
    lblPrimeraVenta.Caption := Format(SCaptionPrimeraVenta,
      [FormatDateTime('dd/mm/yyyy', dPrimeraVenta)]);
    lblUltimaVenta.Caption := Format(SCaptionUltimaVenta,
      [FormatDateTime('dd/mm/yyyy', dUltimaVenta)]);
  end;
end;

procedure TfrmModalListadoVentas.btnBuscarClick(Sender: TObject);
begin
  CargarListado;
end;

procedure TfrmModalListadoVentas.btnExcelClick(Sender: TObject);
begin
  if unqryVentas.Active then
    ExportarExcel(ParametrosApp, cxgrdVentas, 'Listado_ventas');
end;

procedure TfrmModalListadoVentas.btnSalirClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalListadoVentas.pmVentasPopup(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  ResolverArtSkuStock(sArt, sSku);
  miAgregarDocumento.Enabled := Trim(sArt) <> '';
end;

procedure TfrmModalListadoVentas.miAgregarDocumentoClick(Sender: TObject);
begin
  try
    AgregarArticuloActivoADocumentoTrabajo(Self, ConexionPrincipal,
      CrearRepositoriosDocumentosTrabajo(ConexionPrincipal),
      CrearInteraccionDocumentosTrabajoVcl,
      BusquedaVisual, ContextoSesion, ParametrosCaja, ResolverArtSkuStock,
      CrearResolverArticulos(ConexionPrincipal));
  except
    on E: Exception do
      MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmModalListadoVentas.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = Ord('F')) and (ssCtrl in Shift) and
     not (ssShift in Shift) and not (ssAlt in Shift) then
  begin
    MostrarFotoArticuloActivo;
    Key := 0;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmModalListadoVentas.MostrarFotoArticuloActivo;
var
  FormularioFoto: TfrmFotoArticulo;
  sArt: string;
  sSku: string;
begin
  FormularioFoto := FotoFlotanteActual;
  if (FormularioFoto <> nil) and FormularioFoto.Visible then
    FormularioFoto.Hide
  else
  begin
    ResolverArtSkuStock(sArt, sSku);
    if sArt <> '' then
    begin
      MostrarFotoFlotante(Self, sArt, sSku);
      FormularioFoto := FotoFlotanteActual;
      if FormularioFoto <> nil then
        FormularioFoto.VincularDataSources([dsVentas],
                                           ResolverArtSkuStock);
    end;
  end;
end;

procedure TfrmModalListadoVentas.ResolverArtSkuStock(out ACodArt,
  ACodSku: string);
begin
  inLibFotos.LeerArtSkuDeDataSet(unqryVentas, ACodArt, ACodSku);
end;

function TfrmModalListadoVentas.CodigoCombo(ACombo: TcxComboBox): string;
var
  iPos: Integer;
  sTexto: string;
begin
  Result := '';
  if (ACombo <> nil) and (ACombo.ItemIndex > 0) then
  begin
    sTexto := Trim(ACombo.Text);
    iPos := Pos(' - ', sTexto);
    if iPos > 0 then
      Result := Copy(sTexto, 1, iPos - 1)
    else
      Result := sTexto;
  end;
end;

function TfrmModalListadoVentas.SQLListado: string;
var
  sl: TStringList;

  procedure Add(const S: string);
  begin
    sl.Add(S);
  end;

begin
  sl := TStringList.Create;
  try
    Add('SELECT L.*');
    Add('  FROM (');
    Add('SELECT f.`FECHA_FAC`,');
    Add('       CONCAT(fl.`SERIE_FAC_FACLIN`, ''.'',');
    Add('              fl.`NUMERO_FAC_FACLIN`) AS `DOCUMENTO_FAC`,');
    Add('       f.`TIPO_FAC`,');
    Add('       f.`FASE_FAC`,');
    Add('       f.`ESCONSOLIDADA_FAC`,');
    Add('       COALESCE(fl.`CODIGO_ALM_FACLIN`,');
    Add('                f.`CODIGO_ALM_FAC`) AS `CODIGO_ALM_FACLIN`,');
    Add('       f.`CODIGO_CLI_FAC`,');
    Add('       f.`RAZON_SOCIAL_CLIENTE_FAC`,');
    Add('       fl.`SERIE_FAC_FACLIN`,');
    Add('       fl.`NUMERO_FAC_FACLIN`,');
    Add('       fl.`LINEA_FACLIN`,');
    Add('       fl.`CODIGO_ART_FACLIN`,');
    Add('       fl.`CODIGO_UNIDAD_FACLIN`,');
    Add('       fl.`DESCRIPCION_ARTICULO_FACLIN`,');
    Add('       fl.`DESCRIPCION_VARIACION_FACLIN`,');
    Add('       COALESCE(ap.`REF_PROVEEDOR_AP`, '''')');
    Add('         AS `REF_PROVEEDOR`,');
    // Conserva el dato historico y recupera el maestro solo si falta.
    Add('       COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Add('                art.`CODIGO_FAM_ART`, '''') AS `CODIGO_FAM_FACLIN`,');
    Add('       COALESCE(NULLIF(fl.`NOMBRE_FAM_FACLIN`, ''''),');
    Add('                NULLIF(fam.`NOMBRE_FAM_FAM`, ''''),');
    Add('                NULLIF(fam.`DESCRIPCION_FAM`, ''''),');
    Add('                NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Add('                art.`CODIGO_FAM_ART`, '''') AS `NOMBRE_FAM_FACLIN`,');
    Add('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Add('                ap.`CODIGO_PRV_AP`, '''') AS `CODIGO_PRV_FACLIN`,');
    Add('       COALESCE(NULLIF(fl.`RAZON_SOCIAL_PROVEEDOR_FACLIN`, ''''),');
    Add('                NULLIF(prv.`RAZON_SOCIAL_PRV`, ''''),');
    Add('                NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Add('                ap.`CODIGO_PRV_AP`, '''')');
    Add('         AS `RAZON_SOCIAL_PROVEEDOR_FACLIN`,');
    Add('       COALESCE(pvsku.`PV`, tsku.`VALOR_LIBRE_ARTPROP`,');
    Add('                pvcol.`PV`, tcol.`VALOR_LIBRE_ARTPROP`,');
    Add('                pvart.`PV`, tart.`VALOR_LIBRE_ARTPROP`,');
    Add('                '''') AS `TEMPORADA_ART`,');
    Add('       fl.`CANTIDAD_FACLIN`,');
    Add('       fl.`PRECIO_SALIDA_FACLIN`,');
    Add('       fl.`PORCENTAJE_DTO_FACLIN`,');
    Add('       fl.`PRECIO_VENTA_SIVA_ARTICULO_FACLIN`,');
    Add('       fl.`PRECIO_VENTA_CIVA_ARTICULO_FACLIN`,');
    Add('       fl.`TOTAL_FAC_SIVA_FACLIN`,');
    Add('       fl.`TOTAL_FACLIN`');
    Add('  FROM `fza_facturas_lineas` fl');
    Add('  JOIN `fza_facturas` f');
    Add('    ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`');
    Add('   AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`');
    Add('  LEFT JOIN `fza_articulos` art');
    Add('    ON art.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Add('  LEFT JOIN `fza_articulos_familias` fam');
    Add('    ON fam.`CODIGO_FAM_FAM` =');
    Add('       COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Add('                art.`CODIGO_FAM_ART`)');
    Add('  LEFT JOIN `fza_articulos_proveedores` ap');
    Add('    ON ap.`CODIGO_ART_AP` = art.`CODIGO_ART_ART`');
    Add('   AND ap.`CODIGO_PRV_AP` =');
    // Usa el proveedor historico de la venta y el principal como respaldo.
    Add('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Add('         (SELECT apx.`CODIGO_PRV_AP`');
    Add('            FROM `fza_articulos_proveedores` apx');
    Add('           WHERE apx.`CODIGO_ART_AP` = art.`CODIGO_ART_ART`');
    Add('           ORDER BY CASE');
    Add('                      WHEN apx.`ESPROVEEDORPRINCIPAL_AP` = ''S''');
    Add('                      THEN 0 ELSE 1');
    Add('                    END,');
    Add('                    apx.`FECHA_VALIDEZ_AP` DESC,');
    Add('                    apx.`CODIGO_PRV_AP`');
    Add('           LIMIT 1))');
    Add('  LEFT JOIN `fza_proveedores` prv');
    Add('    ON prv.`CODIGO_PRV_PRV` =');
    Add('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Add('                ap.`CODIGO_PRV_AP`)');
    Add('  LEFT JOIN `fza_articulos_propiedades` tsku');
    Add('    ON tsku.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Add('   AND tsku.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Add('   AND tsku.`CODIGO_UNIDAD_ARTPROP` = fl.`CODIGO_UNIDAD_FACLIN`');
    Add('  LEFT JOIN `fza_propiedades_valores` pvsku');
    Add('    ON pvsku.`ID_PV_ARTPROP` = tsku.`ID_PV_ARTPROP`');
    Add('  LEFT JOIN `fza_articulos_propiedades` tcol');
    Add('    ON tcol.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Add('   AND tcol.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Add('   AND tcol.`CODIGO_UNIDAD_ARTPROP` =');
    Add('       SUBSTRING_INDEX(fl.`CODIGO_UNIDAD_FACLIN`, ''/'', 2)');
    Add('  LEFT JOIN `fza_propiedades_valores` pvcol');
    Add('    ON pvcol.`ID_PV_ARTPROP` = tcol.`ID_PV_ARTPROP`');
    Add('  LEFT JOIN `fza_articulos_propiedades` tart');
    Add('    ON tart.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Add('   AND tart.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Add('   AND tart.`CODIGO_UNIDAD_ARTPROP` = ''''');
    Add('  LEFT JOIN `fza_propiedades_valores` pvart');
    Add('    ON pvart.`ID_PV_ARTPROP` = tart.`ID_PV_ARTPROP`');
    Add(' WHERE f.`FECHA_FAC` >= :pDESDE');
    Add('   AND f.`FECHA_FAC` < :pHASTA');
    Add('   AND (:pFAM = '''' OR');
    Add('        COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Add('                 art.`CODIGO_FAM_ART`) = :pFAM)');
    Add('   AND (:pPRV = '''' OR');
    Add('        COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Add('                 ap.`CODIGO_PRV_AP`) = :pPRV)');
    Add('   AND (:pCON = ''N''');
    Add('        OR COALESCE(f.`ESCONSOLIDADA_FAC`, ''N'') = ''S'')');
    Add('   AND COALESCE(f.`FASE_FAC`, '''') <> ''CANCELADA''');
    Add(SQLExcluirVentaRetirada(
      'f.CODIGO_EMP_FAC', 'f.SERIE_FAC', 'f.NUMERO_FAC'));
    Add('       ) L');
    Add(' WHERE (:pTMP = '''' OR L.`TEMPORADA_ART` = :pTMP)');
    Add(' ORDER BY L.`FECHA_FAC` DESC, L.`SERIE_FAC_FACLIN`,');
    Add('          L.`NUMERO_FAC_FACLIN`, L.`LINEA_FACLIN`');
    Result := sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalListadoVentas);

end.
