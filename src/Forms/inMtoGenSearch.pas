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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxBarBuiltInMenu, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  cxDBNavigator, Vcl.Buttons, dxBevel, Vcl.StdCtrls, cxButtons, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, MemDS,
  DBAccess, Uni, UniDataConn, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, JvComponentBase, JvEnterTab, dxShellDialogs, inLibGlobalVar,
  cxMaskEdit, cxDropDownEdit;

type
  TDefCampo = record
    NombreCampo: string;
    Valor: Variant;       // El valor seleccionado por defecto
    Opciones: string;     // NUEVO: String separado por comas "S,N"
    ComponenteUI: TControl; // NUEVO: Referencia temporal al control visual creado
  end;
  TConfigAltaRapida = record
    Activo: Boolean;
    Tabla: string;
    CampoCodigo: string;
    CampoDescripcion: string;
    TituloVentana: string;
    // NUEVO: Tipo de documento para PRC_GET_NEXT_CONT (ej: 'AR', 'CL')
    TipoDocContador: string;
    ValoresDefecto: TArray<TDefCampo>;
  end;
  TfrmMtoSearch = class(TfrmMtoGen)
    pnl1: TPanel;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAltaRapidaClick(Sender: TObject);
  private
    btnAltaRapida:TcxButton;

    function MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
    function ProcesarValor(const aValor, aTipo: string): Variant;
    procedure AddValorDefecto(const aCampo: string; const aValor: Variant);
    function EjecutarAltaGenerica(sCod, sDesc: string):Boolean;
    function ObtenerSiguienteContador(const aTipoDoc: string): string;
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
  //inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.CrearTablaPrincipal;
begin
  inherited;
  //
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

  // Inicialización segura
  FConfigAlta.Activo := False;
  SetLength(FConfigAlta.ValoresDefecto, 0);

  // CREAMOS EL BOTÓN PERO OCULTO
  // (Si prefieres que no ocupe espacio, asegúrate de que esté alineado o usa un LayoutControl,
  // pero con Visible := False es suficiente para que el usuario no lo vea)
  btnAltaRapida := TcxButton.Create(Self);
  with btnAltaRapida do
  begin
    Parent := pnlTopGrid; // O tu panel de botones
    Caption := 'Alta Rápida';
    Width := 100;
    Left := 10;
    Top := 5;
    OnClick := btnAltaRapidaClick;
    Visible := False; // <--- POR DEFECTO OCULTO
  end;
end;

// =============================================================================
// CONSTRUCTOR DE FORMULARIO DINÁMICO (Versión Visual Completa)
// =============================================================================
function TfrmMtoSearch.MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
var
  FormAlta: TForm;
  ScrollBox: TScrollBox;
  pnlBotones: TPanel;
  btnOk, btnCancel: TcxButton;

  // Referencias locales para Código y Descripción
  edtCod, edtDesc: TcxTextEdit;
  lbl: TcxLabel;

  // Variables de bucle
  i, TopPos, LeftLbl, LeftEdit, EditWidth: Integer;

  // Componentes dinámicos
  newEdit: TcxTextEdit;
  newCombo: TcxComboBox;
begin
  Result := False;

  // 1. Configuración de la Ventana
  FormAlta := TForm.Create(nil);
  try
    FormAlta.Caption := FConfigAlta.TituloVentana;
    FormAlta.Position := poScreenCenter;
    FormAlta.BorderStyle := bsDialog;
    FormAlta.Width := 450;
    FormAlta.Height := 500; // Altura inicial razonable
    // Fuente un poco más grande para que se vea moderno
    FormAlta.Font.Size := 10;
    FormAlta.Font.Name := 'Segoe UI';

    // 2. Crear ScrollBox (Para que si hay muchos campos, aparezca barra de scroll)
    ScrollBox := TScrollBox.Create(FormAlta);
    ScrollBox.Parent := FormAlta;
    ScrollBox.Align := alClient;
    ScrollBox.BorderStyle := bsNone;

    // 3. Panel inferior para botones
    pnlBotones := TPanel.Create(FormAlta);
    pnlBotones.Parent := FormAlta;
    pnlBotones.Align := alBottom;
    pnlBotones.Height := 50;
    pnlBotones.BevelOuter := bvNone;

    // --- Coordenadas base ---
    TopPos := 20;
    LeftLbl := 20;
    LeftEdit := 140;
    EditWidth := 250;

    // -------------------------------------------------------------------------
    // A. CAMPO CÓDIGO (Obligatorio)
    // -------------------------------------------------------------------------
    lbl := TcxLabel.Create(FormAlta);
    lbl.Parent := ScrollBox;
    lbl.Caption := 'Código:';
    lbl.Left := LeftLbl;
    lbl.Top := TopPos + 3; // +3 para alinear texto con edit

    edtCod := TcxTextEdit.Create(FormAlta);
    edtCod.Parent := ScrollBox;
    edtCod.Left := LeftEdit;
    edtCod.Top := TopPos;
    edtCod.Width := 100; // El código suele ser corto
    edtCod.Text := sCod; // Valor inicial (ej: "0")

    TopPos := TopPos + 35;

    // -------------------------------------------------------------------------
    // B. CAMPO DESCRIPCIÓN (Obligatorio)
    // -------------------------------------------------------------------------
    lbl := TcxLabel.Create(FormAlta);
    lbl.Parent := ScrollBox;
    lbl.Caption := 'Descripción:';
    lbl.Left := LeftLbl;
    lbl.Top := TopPos + 3;

    edtDesc := TcxTextEdit.Create(FormAlta);
    edtDesc.Parent := ScrollBox;
    edtDesc.Left := LeftEdit;
    edtDesc.Top := TopPos;
    edtDesc.Width := EditWidth;
    edtDesc.Text := sDesc;

    TopPos := TopPos + 35;

    // Separador visual (opcional)
    with TBevel.Create(FormAlta) do
    begin
      Parent := ScrollBox;
      Left := 20; Top := TopPos; Width := 380; Height := 2;
      Shape := bsTopLine;
    end;
    TopPos := TopPos + 15;

    // -------------------------------------------------------------------------
    // C. CAMPOS DINÁMICOS (Desde Base de Datos)
    // -------------------------------------------------------------------------
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
    begin
      // 1. Crear Etiqueta (Label)
      lbl := TcxLabel.Create(FormAlta);
      lbl.Parent := ScrollBox;
      // Quitamos guiones bajos o lo dejamos tal cual según prefieras
      lbl.Caption := StringReplace(FConfigAlta.ValoresDefecto[i].NombreCampo, '_', ' ', [rfReplaceAll]) + ':';
      lbl.Left := LeftLbl;
      lbl.Top := TopPos + 3;

      // 2. Crear Control de Edición (Combo o TextEdit)
      if FConfigAlta.ValoresDefecto[i].Opciones <> '' then
      begin
        // --- ES UN COMBOBOX ---
        newCombo := TcxComboBox.Create(FormAlta);
        newCombo.Parent := ScrollBox;
        newCombo.Left := LeftEdit;
        newCombo.Top := TopPos;
        newCombo.Width := EditWidth;

        // Cargar opciones (ej: S,N)
        newCombo.Properties.Items.CommaText := FConfigAlta.ValoresDefecto[i].Opciones;
        // Poner valor por defecto
        newCombo.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        // Estilo: DropDownList para que no escriban cosas raras
        newCombo.Properties.DropDownListStyle := lsFixedList;

        // Guardamos referencia
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newCombo;
      end
      else
      begin
        // --- ES UNA CAJA DE TEXTO NORMAL ---
        newEdit := TcxTextEdit.Create(FormAlta);
        newEdit.Parent := ScrollBox;
        newEdit.Left := LeftEdit;
        newEdit.Top := TopPos;
        newEdit.Width := EditWidth;

        // Poner valor por defecto
        newEdit.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        // Guardamos referencia
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newEdit;
      end;
      TopPos := TopPos + 35;
    end;
    // -------------------------------------------------------------------------
    // D. BOTONES
    // -------------------------------------------------------------------------
    btnOk := TcxButton.Create(FormAlta);
    btnOk.Parent := pnlBotones;
    btnOk.Caption := 'Guardar';
    btnOk.ModalResult := mrOk;
    btnOk.Left := 230; btnOk.Top := 12;
    btnOk.Width := 90;
    // Si usas skins:
    btnOk.LookAndFeel.NativeStyle := False;
    btnCancel := TcxButton.Create(FormAlta);
    btnCancel.Parent := pnlBotones;
    btnCancel.Caption := 'Cancelar';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := 330; btnCancel.Top := 12;
    btnCancel.Width := 90;
    // -------------------------------------------------------------------------
    // E. MOSTRAR Y PROCESAR
    // -------------------------------------------------------------------------
    if FormAlta.ShowModal = mrOk then
    begin
      // 1. Recuperar Código y Descripción
      sCod := edtCod.Text;
      sDesc := edtDesc.Text;
      // 2. Recuperar valores de los campos dinámicos
      // Aquí recorremos la UI para ver qué ha cambiado el usuario
      for i := 0 to High(FConfigAlta.ValoresDefecto) do
      begin
        if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxComboBox then
        begin
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxComboBox(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text;
        end
        else if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxTextEdit then
        begin
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxTextEdit(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text;
        end;
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
    if (Trim(sCodigo) = '0') and (FConfigAlta.TipoDocContador <> '') then
    begin
      sCodigo := ObtenerSiguienteContador(FConfigAlta.TipoDocContador);
      if sCodigo = '' then Exit;
    end;
    EjecutarAltaGenerica(sCodigo, sDescripcion);
  end;
end;

function TfrmMtoSearch.EjecutarAltaGenerica(sCod, sDesc: string):Boolean;
var
  Qry: TUniQuery;
  SQL: string;
  ParamNames: string;
  i: Integer;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn; // Tu conexión global

    // 1. Construcción dinámica del INSERT
    // Empezamos con: INSERT INTO Tabla (CampoCod, CampoDesc
    SQL := 'INSERT INTO ' + FConfigAlta.Tabla + ' (' +
           FConfigAlta.CampoCodigo + ', ' +
           FConfigAlta.CampoDescripcion;

    // Añadimos los campos extra definidos en defaults
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
      SQL := SQL + ', ' + FConfigAlta.ValoresDefecto[i].NombreCampo;

    // Pasamos a los valores: ) VALUES (:pCod, :pDesc
    SQL := SQL + ') VALUES (:pCod, :pDesc';

    // Añadimos los parámetros para los defaults
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
      SQL := SQL + ', :pDef' + IntToStr(i);

    SQL := SQL + ')';

    Qry.SQL.Text := SQL;

    // 2. Asignación de Parámetros
    Qry.ParamByName('pCod').Value := sCod;
    Qry.ParamByName('pDesc').Value := sDesc;

    for i := 0 to High(FConfigAlta.ValoresDefecto) do
    begin
      // Asignamos el valor variant al parámetro dinámico
      Qry.ParamByName('pDef' + IntToStr(i)).Value := FConfigAlta.ValoresDefecto[i].Valor;
    end;

    // 3. Ejecución
    try
      Qry.Execute;
      ShowMessage('Registro creado correctamente.');
      Result := True;
      // Refrescar la rejilla
      if Assigned(cxGrdDBTabPrin.DataController.DataSource) and
         (cxGrdDBTabPrin.DataController.DataSource.DataSet.Active) then
      begin
        cxGrdDBTabPrin.DataController.DataSource.DataSet.Refresh;
        // Intentar localizar el nuevo registro
        if cxGrdDBTabPrin.DataController.DataSource.DataSet.FindField(FConfigAlta.CampoCodigo) <> nil then
          cxGrdDBTabPrin.DataController.DataSource.DataSet.Locate(FConfigAlta.CampoCodigo, sCod, []);
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Error al crear registro: ' + E.Message);
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

function TfrmMtoSearch.ObtenerSiguienteContador(const aTipoDoc: string): string;
var
  SP: TUniStoredProc;
begin
  Result := '';
  SP := TUniStoredProc.Create(nil);
  try
    SP.Connection := inLibGlobalVar.oConn; // Tu conexión global
    SP.StoredProcName := 'PRC_GET_NEXT_CONT';

    // Parámetros de entrada
    SP.Params.Clear;
    SP.Params.CreateParam(ftString, 'pTipoDoc', ptInput).AsString := aTipoDoc;
    // Parámetro de salida (según tu descripción devuelve pcont)
    SP.Params.CreateParam(ftString, 'pcont', ptOutput);

    try
      SP.Execute;
      Result := SP.Params.ParamByName('pcont').AsString;
    except
      on E: Exception do
        ShowMessage('Error al generar contador automático: ' + E.Message);
    end;
  finally
    SP.Free;
  end;
end;

procedure TfrmMtoSearch.CargarDefaultsDesdeBD(const aNombreTabla: string);
var
  QryDef, QryCont: TUniQuery;
begin
  FConfigAlta.Activo := True;
  if Assigned(btnAltaRapida) then
    btnAltaRapida.Visible := True;
  // 1. Configuración Básica
  FConfigAlta.Tabla := aNombreTabla;
  FConfigAlta.TipoDocContador := ''; // Limpiamos valor anterior
  SetLength(FConfigAlta.ValoresDefecto, 0);
  // 2. Cargar DEFAULTS y OPCIONES (fza_gen_defaults)
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
        QryDef.FieldByName('CAMPO_OBJETIVO').AsString,
        ProcesarValor(QryDef.FieldByName('VALOR_DEFECTO').AsString,
                      QryDef.FieldByName('TIPO_DATO').AsString)
      );
      // Cargar opciones de ComboBox si existen
      FConfigAlta.ValoresDefecto[High(FConfigAlta.ValoresDefecto)].Opciones :=
         QryDef.FieldByName('VALORES_POSIBLES').AsString;
      QryDef.Next;
    end;
  finally
    QryDef.Free;
  end;
  // Buscamos el TIPODOC asociado a la tabla origen, asumiendo serie '-'
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
  // Aquí podrías añadir lógica para macros como @HOY o @USUARIO
  if (aTipo = 'INTEGER') then
    Result := StrToIntDef(aValor, 0)
  else if (aTipo = 'FLOAT') then
    Result := StrToFloatDef(aValor, 0.0)
  else if (aTipo = 'BOOLEAN') then
    Result := (UpperCase(aValor) = 'TRUE') or (aValor = '1')
  else
    Result := aValor; // String por defecto
end;

end.
