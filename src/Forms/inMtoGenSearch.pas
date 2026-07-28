{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGenSearch                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base de mantenimientos con busqueda integrada.                 }
{    Anade filtrado y altas rapidas sobre inMtoGen.                            }
{******************************************************************************}
unit inMtoGenSearch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  cxDBNavigator, Vcl.Buttons, dxBevel, Vcl.StdCtrls, cxButtons, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, MemDS,
  DBAccess, Uni, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxMaskEdit, cxDropDownEdit, inLibValoresAutomaticos,
  inMtoModalAltaRapida, inLibDevExp,
  inLibConfigCampos;

type
  TDefCampo = record
    NombreCampo: string;
    Valor: Variant;
    Opciones: string;
    ComponenteUI: TControl;
  end;
  TConfigAltaRapida = record
    Activo: Boolean;
    Tabla: string;
    CampoCodigo: string;
    CampoDescripcion: string;
    TituloVentana: string;
    TipoDocContador: string;
    ValoresDefecto: TArray<TDefCampo>;
  end;
  TfrmMtoSearch = class(TfrmMtoGen)
    pnl1: TPanel;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    btnAltaRapida: TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAltaRapidaClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    function MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
    function ProcesarValor(const aValor, aTipo: string): Variant;
    procedure AddValorDefecto(const aCampo: string; const aValor: Variant);
    function EjecutarAltaGenerica(sCod, sDesc: string):Boolean;
  protected
    function DebeAjustarColumnasAutomaticamente: Boolean; virtual;
  public
    FConfigAlta: TConfigAltaRapida;
    sFicha:string;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure CargarDefaultsDesdeBD(const aNombreTabla: string);
    { Public declarations }
  end;

var
  frmMtoSearch: TfrmMtoSearch;

implementation

uses
  inLibGenBusq, inLibMsg;

type
  TEjecutorBusquedaMto = class(TEjecutorBusqueda)
  public
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption: string;
                                    ADataSet: TCustomDADataSet;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload; override;
    class function EjecutarBusqueda(AConexion: TUniConnection;
                                    const ACaption, ASql,
                                          ACampoResultado: string;
                                    out AValorDevuelto: string;
                                    const AName: string;
                                    AParentForm: TCustomForm = nil):
                                    Boolean; overload; override;
  end;

{$R *.dfm}

class function TEjecutorBusquedaMto.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption: string;
  ADataSet: TCustomDADataSet; const AName: string;
  AParentForm: TCustomForm): Boolean;
var
  oFormulario: TfrmMtoSearch;
begin
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.Caption := ACaption;
    oFormulario.Name := AName;
    if Assigned(AParentForm) then
      oFormulario.PopupParent := AParentForm;
    ADataSet.Connection := AConexion;
    oFormulario.dsTablaG.DataSet := ADataSet;
    if not ADataSet.Active then
      ADataSet.Open;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
  finally
    FreeAndNil(oFormulario);
  end;
end;

class function TEjecutorBusquedaMto.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption, ASql,
  ACampoResultado: string; out AValorDevuelto: string;
  const AName: string; AParentForm: TCustomForm): Boolean;
var
  oFormulario: TfrmMtoSearch;
  qryTemporal: TUniQuery;
begin
  Result := False;
  oFormulario := TfrmMtoSearch.Create(nil);
  qryTemporal := TUniQuery.Create(oFormulario);
  try
    oFormulario.Caption := ACaption;
    oFormulario.Name := AName;
    if Assigned(AParentForm) then
      oFormulario.PopupParent := AParentForm;
    qryTemporal.Connection := AConexion;
    qryTemporal.SQL.Text := ASql;
    oFormulario.dsTablaG.DataSet := qryTemporal;
    qryTemporal.Open;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    if ((oFormulario.sFicha = 'S') and
        (qryTemporal.RecordCount > 0)) then
    begin
      AValorDevuelto := qryTemporal.FieldByName(
        ACampoResultado).AsString;
      Result := True;
    end;
  finally
    FreeAndNil(qryTemporal);
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmMtoSearch.AddValorDefecto(const aCampo: string;
                                        const aValor: Variant);
var
  Idx: Integer;
begin
  Idx := Length(FConfigAlta.ValoresDefecto);
  SetLength(FConfigAlta.ValoresDefecto, Idx + 1);
  FConfigAlta.ValoresDefecto[Idx].NombreCampo := aCampo;
  FConfigAlta.ValoresDefecto[Idx].Valor := aValor;
end;

procedure TfrmMtoSearch.AplicarEtiquetas;
begin
  inherited;
  //AbrirPerfiles(tsPerfil.TabVisible);
end;

procedure TfrmMtoSearch.btnAceptarClick(Sender: TObject);
begin
  //inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.btnCancelarClick(Sender: TObject);
begin
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.CrearTablaPrincipal;
var
  i, j: Integer;
  sField: string;
  bYaExiste: Boolean;
  col: TcxGridDBColumn;
  ds: TDataSet;
  sTit: string;
  iAncho: Integer;
begin
  inherited;
  if Assigned(dsTablaG.DataSet) and (dsTablaG.DataSet is TUniQuery) then
    AplicarGuiasGrid(TUniQuery(dsTablaG.DataSet));
  // Crear columnas solo para campos que aún no tengan columna
  ds := cxGrdDBTabPrin.DataController.DataSource.DataSet;
  if Assigned(ds) then
  begin
    for i := 0 to ds.FieldCount - 1 do
    begin
      sField := ds.Fields[i].FieldName;
      bYaExiste := False;
      for j := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
      begin
        if SameText(
          (cxGrdDBTabPrin.Columns[j] as TcxGridDBColumn)
            .DataBinding.FieldName, sField) then
        begin
          bYaExiste := True;
          Break;
        end;
      end;
      if not bYaExiste then
      begin
        col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
        col.DataBinding.FieldName := sField;
      end;
    end;
  end;
  // Asignar properties por prefijo (PRECIO_/TOTAL_/IMPORTE_ -> currency €,
  // PORCENTAJE_ -> %, VALOR_/CANTIDAD_ -> numerico, ESxxx -> checkbox S/N).
  AplicarPropertiesPorPrefijo(cxGrdDBTabPrin);
  if DebeAjustarColumnasAutomaticamente then
    cxGrdDBTabPrin.ApplyBestFit();
  // Titulos y anchos "bonitos" desde fza_config_campos (cache oConfigCampos):
  // sustituye los nombres crudos de columna (CODIGO_PRV_PRV, RAZON_SOCIAL_PRV
  // ...) por el TITULO_VISUAL_CC configurado. Es el mismo origen que usa
  // PonerAnchosTitulos en los Mtos normales, pero el buscador crea sus
  // columnas a mano y no pasa por esa ruta (va ligada a oApplyWidth), asi que
  // lo aplicamos aqui explicitamente. Tras ApplyBestFit para que el ancho
  // configurado prevalezca.
  if Assigned(oConfigCampos) and oConfigCampos.Cargada then
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      col := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
      sField := col.DataBinding.FieldName;
      sTit := oConfigCampos.ObtenerTitulo(sField);
      if sTit <> '' then
        col.Caption := sTit;
      iAncho := oConfigCampos.ObtenerAncho(sField);
      if iAncho > 0 then
        col.Width := iAncho;
    end;
end;

function TfrmMtoSearch.DebeAjustarColumnasAutomaticamente: Boolean;
begin
  Result := True;
end;

procedure TfrmMtoSearch.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoSearch.cxGrdDBTabPrinCellDblClick(
                                    Sender: TcxCustomGridTableView;
                                    ACellViewInfo: TcxGridTableDataCellViewInfo;
                                    AButton: TMouseButton;
                                    AShift: TShiftState; var AHandled: Boolean);
begin
  inherited;
  btnAceptarClick(Self);
end;

procedure TfrmMtoSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmMtoSearch.FormCreate(Sender: TObject);
begin
  inherited;
  Self.KeyPreview := True;
  sUso := 'Busq';
  sFicha := 'N';
  FConfigAlta.Activo := False;
  SetLength(FConfigAlta.ValoresDefecto, 0);
  with btnAltaRapida do
  begin
    OnClick := btnAltaRapidaClick;
    Visible := False;
  end;
end;

procedure TfrmMtoSearch.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // F12 solo (sin modificadores) -> Aceptar búsqueda
  if (Key = VK_F12) and (Shift = []) then
  begin
    Key := 0;
    btnAceptarClick(Self);
    Exit;
  end;
  if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    btnCancelarClick(Self);
    Exit;
  end;
  inherited;
end;

function TfrmMtoSearch.MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
var
  frm: TfrmMtoModalAltaRapida;
  lbl: TcxLabel;
  newEdit: TcxTextEdit;
  newCombo: TcxComboBox;
  i, TopPos: Integer;
begin
  Result := False;
  frm := TfrmMtoModalAltaRapida.Create(nil);
  try
    frm.Caption    := FConfigAlta.TituloVentana;
    frm.edtCod.Text  := sCod;
    frm.edtDesc.Text := sDesc;

    TopPos := TfrmMtoModalAltaRapida.DynStartTop;
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
    begin
      lbl := TcxLabel.Create(frm);
      lbl.Parent  := frm.ScrollBox;
      lbl.Transparent := True;
      lbl.Caption := StringReplace(FConfigAlta.ValoresDefecto[i].NombreCampo,
                                                 '_', ' ', [rfReplaceAll]);
      lbl.Left := TfrmMtoModalAltaRapida.ColMargin;
      lbl.Top  := TopPos;

      if FConfigAlta.ValoresDefecto[i].Opciones <> '' then
      begin
        newCombo := TcxComboBox.Create(frm);
        newCombo.Parent := frm.ScrollBox;
        newCombo.Left   := TfrmMtoModalAltaRapida.ColMargin;
        newCombo.Top    := TopPos + 20;
        newCombo.Width  := TfrmMtoModalAltaRapida.ColWidth;
        newCombo.Properties.Items.CommaText :=
                                       FConfigAlta.ValoresDefecto[i].Opciones;
        newCombo.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        newCombo.Properties.DropDownListStyle := lsFixedList;
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newCombo;
      end
      else
      begin
        newEdit := TcxTextEdit.Create(frm);
        newEdit.Parent := frm.ScrollBox;
        newEdit.Left   := TfrmMtoModalAltaRapida.ColMargin;
        newEdit.Top    := TopPos + 20;
        newEdit.Width  := TfrmMtoModalAltaRapida.ColWidth;
        newEdit.Text   := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newEdit;
      end;
      TopPos := TopPos + TfrmMtoModalAltaRapida.FieldStep;
    end;

    if frm.ShowModal = mrOk then
    begin
      sCod  := frm.edtCod.Text;
      sDesc := frm.edtDesc.Text;
      for i := 0 to High(FConfigAlta.ValoresDefecto) do
      begin
        if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxComboBox then
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxComboBox(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text
        else if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxTextEdit then
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxTextEdit(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text;
      end;
      Result := (Trim(sCod) <> '');
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoSearch.btnAltaRapidaClick(Sender: TObject);
var
  sCodigo, sDescripcion: string;
begin
  if not FConfigAlta.Activo then Exit;
  sCodigo := '0';
  sDescripcion := '';
  if MostrarDialogoDinamico(sCodigo, sDescripcion) then
  begin
    EjecutarAltaGenerica(sCodigo, sDescripcion);
  end;
end;

function TfrmMtoSearch.EjecutarAltaGenerica(sCod, sDesc: string): Boolean;
var
  Conn: TUniConnection;
  Qry: TUniQuery;
  sCodigoFinal: string;
  i: Integer;
begin
  sCodigoFinal := sCod;
  Conn := ConexionTrabajo;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Conn.StartTransaction;
    try
      if ((Trim(sCodigoFinal) = '0') or (Trim(sCodigoFinal) = '')) and
         (FConfigAlta.TipoDocContador <> '') then
      begin
        sCodigoFinal := ObtenerSiguienteContador(
          ConexionPrincipal,
          FConfigAlta.TipoDocContador,
          IdentidadSesion.Usuario);
        if sCodigoFinal = '' then
          raise Exception.Create(SErrorContadorAutomaticoBusqueda);
      end;
      Qry.SQL.Text := 'SELECT * FROM ' + FConfigAlta.Tabla + ' WHERE 1=0';
      Qry.Open;
      Qry.Insert;
      if Qry.FindField(FConfigAlta.CampoCodigo) <> nil then
        Qry.FieldByName(FConfigAlta.CampoCodigo).AsString := sCodigoFinal;
      if Qry.FindField(FConfigAlta.CampoDescripcion) <> nil then
        Qry.FieldByName(FConfigAlta.CampoDescripcion).AsString := sDesc;
      for i := 0 to High(FConfigAlta.ValoresDefecto) do
      begin
        if Qry.FindField(FConfigAlta.ValoresDefecto[i].NombreCampo) <> nil then
        begin
          Qry.FieldByName(FConfigAlta.ValoresDefecto[i].NombreCampo).Value :=
             FConfigAlta.ValoresDefecto[i].Valor;
        end;
      end;
      ActualizarAuditoria(Qry);
      Qry.Post;
      Conn.Commit;
      Result := True;
      ShowMessage(Format(SInfoRegistroBusquedaCreado, [sCodigoFinal]));
      if Assigned(cxGrdDBTabPrin.DataController.DataSource) and
         (cxGrdDBTabPrin.DataController.DataSource.DataSet.Active) then
      begin
        cxGrdDBTabPrin.DataController.DataSource.DataSet.Refresh;
        if cxGrdDBTabPrin.DataController.DataSource.DataSet.FindField(
                                            FConfigAlta.CampoCodigo) <> nil then
          cxGrdDBTabPrin.DataController.DataSource.DataSet.Locate(
                                     FConfigAlta.CampoCodigo, sCodigoFinal, []);
      end;
    except
      on E: Exception do
      begin
        Conn.Rollback;
        if Qry.State in [dsInsert, dsEdit] then Qry.Cancel;
        ShowMessage(Format(SErrorInsertarRegistroBusqueda, [E.Message]));
        Result := False;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmMtoSearch.FormShow(Sender: TObject);
begin
  inherited;
  edtBusqGlobal.SetFocus;
end;

procedure TfrmMtoSearch.CargarDefaultsDesdeBD(const aNombreTabla: string);
var
  QryDef, QryCont: TUniQuery;
begin
  FConfigAlta.Activo := True;
  if Assigned(btnAltaRapida) then
    btnAltaRapida.Visible := True;
  FConfigAlta.Tabla := aNombreTabla;
  FConfigAlta.TipoDocContador := ''; // Limpiamos valor anterior
  SetLength(FConfigAlta.ValoresDefecto, 0);
  QryDef := TUniQuery.Create(nil);
  try
    QryDef.Connection := ConexionTrabajo;
    QryDef.SQL.Text := 'SELECT * ' +
                       'FROM fza_gen_defaults ' +
                       'WHERE TABLA_OBJETIVO_DEF_VD = :Tabla';
    QryDef.ParamByName('Tabla').AsString := aNombreTabla;
    QryDef.Open;
    while not QryDef.Eof do
    begin
      AddValorDefecto(
        QryDef.FieldByName('CAMPO_OBJETIVO_DEF_VD').AsString,
        ProcesarValor(QryDef.FieldByName('VALOR_DEF_VD').AsString,
                      QryDef.FieldByName('TIPO_DATO_DEF_VD').AsString)
      );
      FConfigAlta.ValoresDefecto[High(FConfigAlta.ValoresDefecto)].Opciones :=
         QryDef.FieldByName('VALORES_POSIBLES_DEF_VD').AsString;
      QryDef.Next;
    end;
  finally
    FreeAndNil(QryDef);
  end;
  QryCont := TUniQuery.Create(nil);
  try
    QryCont.Connection := ConexionTrabajo;
    QryCont.SQL.Text :=
      'SELECT TIPO_DOC_CON ' +
      '  FROM fza_contadores ' +
      ' WHERE TABLAORIGEN_CONTADOR = :Tabla ' +
      '   AND SERIE_CON = ''-''';
    QryCont.ParamByName('Tabla').AsString := aNombreTabla;
    QryCont.Open;
    if not QryCont.IsEmpty then
    begin
      FConfigAlta.TipoDocContador :=
                               QryCont.FieldByName('TIPO_DOC_CON').AsString;
    end;
  finally
    FreeAndNil(QryCont);
  end;
end;

function TfrmMtoSearch.ProcesarValor(const aValor, aTipo: string): Variant;
begin
  if (aTipo = 'INTEGER') then
    Result := StrToIntDef(aValor, 0)
  else if (aTipo = 'FLOAT') then
    Result := StrToFloatDef(aValor, 0.0)
  else if (aTipo = 'BOOLEAN') then
    Result := (UpperCase(aValor) = 'TRUE') or (aValor = '1')
  else
    Result := aValor;
end;

initialization
  TBusquedaUtils.RegistrarEjecutor(TEjecutorBusquedaMto);

finalization
  TBusquedaUtils.RegistrarEjecutor(nil);

end.
