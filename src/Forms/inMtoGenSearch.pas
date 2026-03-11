{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoGenSearch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  cxDBNavigator, Vcl.Buttons, dxBevel, Vcl.StdCtrls, cxButtons, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, MemDS,
  DBAccess, Uni, UniDataConn, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, JvComponentBase, JvEnterTab, dxShellDialogs, inLibGlobalVar,
  cxMaskEdit, cxDropDownEdit, inLibtb;

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
  public
    FConfigAlta: TConfigAltaRapida;
    sFicha:string;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
    procedure CargarDefaultsDesdeBD(const aNombreTabla: string);
    { Public declarations }
  end;

var
  frmMtoSearch: TfrmMtoSearch;

implementation

{$R *.dfm}

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
begin
  inherited;
  cxGrdDBTabPrin.DataController.CreateAllItems;
  cxGrdDBTabPrin.ApplyBestFit();
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
  Action := caFree;
end;

procedure TfrmMtoSearch.FormCreate(Sender: TObject);
begin
Self.Position := poScreenCenter;
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
  inherited;
  case Key of
    VK_F12:
    begin
      // Evita que el sistema procese la tecla después de nosotros
      Key := 0;
      btnAceptarClick(Self);
    end;
    VK_ESCAPE:
    begin
      Key := 0;
      btnCancelarClick(Self);
    end;
  end;
end;

function TfrmMtoSearch.MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
var
  FormAlta: TForm;
  ScrollBox: TScrollBox;
  pnlBotones: TPanel;
  btnOk, btnCancel: TcxButton;
  edtCod, edtDesc: TcxTextEdit;
  lbl: TcxLabel;
  i, TopPos, LeftMargin, ControlWidth: Integer;
  newEdit: TcxTextEdit;
  newCombo: TcxComboBox;
begin
  Result := False;
  FormAlta := TForm.Create(nil);
  try
    FormAlta.Caption := FConfigAlta.TituloVentana;
    FormAlta.Position := poScreenCenter;
    FormAlta.BorderStyle := bsDialog;
    FormAlta.Width := 450;
    FormAlta.Height := 600;
    FormAlta.Font.Size := 10;
    FormAlta.Font.Name := 'Segoe UI';
    ScrollBox := TScrollBox.Create(FormAlta);
    ScrollBox.Parent := FormAlta;
    ScrollBox.Align := alClient;
    ScrollBox.BorderStyle := bsNone;
    pnlBotones := TPanel.Create(FormAlta);
    pnlBotones.Parent := FormAlta;
    pnlBotones.Align := alBottom;
    pnlBotones.Height := 50;
    pnlBotones.BevelOuter := bvNone;
    TopPos := 15;
    LeftMargin := 25;       // Margen izquierdo para todo
    ControlWidth := 380;    // Ancho grande para llenar la ventana
    lbl := TcxLabel.Create(FormAlta);
    lbl.Parent := ScrollBox;
    lbl.Caption := 'Código:';
    lbl.Left := LeftMargin;
    lbl.Top := TopPos;
    lbl.Style.Font.Style := [fsBold]; // Negrita para destacar
    edtCod := TcxTextEdit.Create(FormAlta);
    edtCod.Parent := ScrollBox;
    edtCod.Left := LeftMargin;
    edtCod.Top := TopPos + 20; // 20px debajo de la etiqueta
    edtCod.Width := 150;       // El código suele ser corto
    edtCod.Text := sCod;
    TopPos := TopPos + 55;
    lbl := TcxLabel.Create(FormAlta);
    lbl.Parent := ScrollBox;
    lbl.Caption := 'Descripción:';
    lbl.Left := LeftMargin;
    lbl.Top := TopPos;
    lbl.Style.Font.Style := [fsBold];
    edtDesc := TcxTextEdit.Create(FormAlta);
    edtDesc.Parent := ScrollBox;
    edtDesc.Left := LeftMargin;
    edtDesc.Top := TopPos + 20;
    edtDesc.Width := ControlWidth; // Ancho completo
    edtDesc.Text := sDesc;
    TopPos := TopPos + 55;
    // Separador visual
    with TBevel.Create(FormAlta) do
    begin
      Parent := ScrollBox;
      Left := LeftMargin; Top := TopPos; Width := ControlWidth; Height := 2;
      Shape := bsTopLine;
    end;
    TopPos := TopPos + 15;
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
    begin
      // 1. Etiqueta (Arriba)
      lbl := TcxLabel.Create(FormAlta);
      lbl.Parent := ScrollBox;
      // Quitamos guiones bajos
      lbl.Caption := StringReplace(FConfigAlta.ValoresDefecto[i].NombreCampo, '_', ' ', [rfReplaceAll]);
      lbl.Left := LeftMargin;
      lbl.Top := TopPos;
      if FConfigAlta.ValoresDefecto[i].Opciones <> '' then
      begin
        newCombo := TcxComboBox.Create(FormAlta);
        newCombo.Parent := ScrollBox;
        newCombo.Left := LeftMargin;
        newCombo.Top := TopPos + 20;
        newCombo.Width := ControlWidth;
        newCombo.Properties.Items.CommaText :=
                                         FConfigAlta.ValoresDefecto[i].Opciones;
        newCombo.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        newCombo.Properties.DropDownListStyle := lsFixedList;
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newCombo;
      end
      else
      begin
        newEdit := TcxTextEdit.Create(FormAlta);
        newEdit.Parent := ScrollBox;
        newEdit.Left := LeftMargin;
        newEdit.Top := TopPos + 20;
        newEdit.Width := ControlWidth;
        newEdit.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newEdit;
      end;
      TopPos := TopPos + 55;
    end;
    TopPos := TopPos + 20;
    with TPanel.Create(FormAlta) do
    begin
      Parent := ScrollBox;
      Top := TopPos;
      Left := 1; Width := 1; Height := 1;
      BevelOuter := bvNone;
      Color := clNone;
    end;
    btnOk := TcxButton.Create(FormAlta);
    btnOk.Parent := pnlBotones;
    btnOk.Caption := 'Guardar';
    btnOk.ModalResult := mrOk;
    btnOk.Left := 230; btnOk.Top := 12;
    btnOk.Width := 90;
    btnOk.LookAndFeel.NativeStyle := False;
    btnCancel := TcxButton.Create(FormAlta);
    btnCancel.Parent := pnlBotones;
    btnCancel.Caption := 'Cancelar';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := 330; btnCancel.Top := 12;
    btnCancel.Width := 90;
    if FormAlta.ShowModal = mrOk then
    begin
      sCod := edtCod.Text;
      sDesc := edtDesc.Text;
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
    FormAlta.Free;
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
  Qry: TUniQuery;
  sCodigoFinal: string;
  i: Integer;
begin
  Result := False;
  sCodigoFinal := sCod;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    inLibGlobalVar.oConn.StartTransaction;
    try
      if ((Trim(sCodigoFinal) = '0') or (Trim(sCodigoFinal) = '')) and
         (FConfigAlta.TipoDocContador <> '') then
      begin
        sCodigoFinal := ObtenerSiguienteContador(FConfigAlta.TipoDocContador);
        if sCodigoFinal = '' then
          raise Exception.Create('No se pudo obtener el contador automático.');
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
      odmConn.ActualizarUserTimeModif(Qry);
      Qry.Post;
      inLibGlobalVar.oConn.Commit;
      Result := True;
      ShowMessage('Registro ' + sCodigoFinal + ' creado correctamente.');
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
        inLibGlobalVar.oConn.Rollback;
        if Qry.State in [dsInsert, dsEdit] then Qry.Cancel;
        ShowMessage('Error al insertar (se ha cancelado la operación): ' +
                                                                     E.Message);
        Result := False;
      end;
    end;
  finally
    Qry.Free;
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
    QryDef.Connection := inLibGlobalVar.oConn;
    QryDef.SQL.Text := 'SELECT * ' +
                       'FROM fza_gen_defaults ' +
                       'WHERE TABLA_OBJETIVO_DEF = :Tabla';
    QryDef.ParamByName('Tabla').AsString := aNombreTabla;
    QryDef.Open;
    while not QryDef.Eof do
    begin
      AddValorDefecto(
        QryDef.FieldByName('CAMPO_OBJETIVO_DEF').AsString,
        ProcesarValor(QryDef.FieldByName('VALOR_DEFECTO_DEF').AsString,
                      QryDef.FieldByName('TIPO_DATO_DEF').AsString)
      );
      FConfigAlta.ValoresDefecto[High(FConfigAlta.ValoresDefecto)].Opciones :=
         QryDef.FieldByName('VALORES_POSIBLES_DEF').AsString;
      QryDef.Next;
    end;
  finally
    QryDef.Free;
  end;
  QryCont := TUniQuery.Create(nil);
  try
    QryCont.Connection := inLibGlobalVar.oConn;
    QryCont.SQL.Text :=
      'SELECT TIPODOC_CONTADOR ' +
      '  FROM fza_contadores ' +
      ' WHERE TABLAORIGEN_CONTADOR = :Tabla ' +
      '   AND SERIE_CONTADOR = ''-''';
    QryCont.ParamByName('Tabla').AsString := aNombreTabla;
    QryCont.Open;
    if not QryCont.IsEmpty then
    begin
      FConfigAlta.TipoDocContador :=
                               QryCont.FieldByName('TIPODOC_CONTADOR').AsString;
    end;
  finally
    QryCont.Free;
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

end.
