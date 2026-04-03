unit inMtoCajaParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, // Añadido Generics
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxFilter, dxScrollbarAnnotations, cxEdit,
  cxCheckBox, cxInplaceContainer, cxTextEdit, cxContainer,
  inLibGlobalVar, dxCoreGraphics, cxMaskEdit, cxButtonEdit, cxSpinEdit,
  Vcl.ExtCtrls, inMtoFrmBase, Uni, cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons, JvComponentBase, JvInspector, JvExControls, System.Actions,
  Vcl.ActnList;

type
  // Tipos de punteros necesarios para la generación dinámica en JvInspector
  PBoolean = ^Boolean;
  PInteger = ^Integer;
  PString  = ^String;

  TfrmMtoCajaParam = class(TFrmBase)
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    Panel2: TPanel;
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    JvInspector1: TJvInspector;
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;
    ActionList1: TActionList;
    actGuardar: TAction;
    actSalir: TAction;

    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
    procedure actGuardarExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Listas para gestionar la memoria dinámica de los parámetros
    FBools: TList<PBoolean>;
    FInts:  TList<PInteger>;
    FStrs:  TList<PString>;

    procedure LimpiarMemoria;
    procedure ResetearADefectos;

    function  ObtenerCategoria(const NombreCat: string): TJvInspectorCustomCategoryItem;
    function  QuitarTildes(const Texto: string): string;
    function  BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem; const Nombre: string): TJvCustomInspectorItem;
//    procedure GuardarNodos(ItemPadre: TJvCustomInspectorItem; qryS:TUniQuery);
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    procedure CargarParametros(Grid: TJvInspector; const pUsuario, pGrupo: string);
    procedure ConstruirInspector;
    procedure GetTipoImpresionList(Sender: TJvCustomInspectorItem; Strings: TStrings);
  end;

var
  frmMtoCajaParam: TfrmMtoCajaParam;

implementation

{$R *.dfm}

uses
  StrUtils, inLibCajaParam;

// ----------------------------------------------------------------------
// GESTIÓN DE MEMORIA Y CICLO DE VIDA
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.FormCreate(Sender: TObject);
begin
  inherited;
  FBools := TList<PBoolean>.Create;
  FInts  := TList<PInteger>.Create;
  FStrs  := TList<PString>.Create;
end;

procedure TfrmMtoCajaParam.FormDestroy(Sender: TObject);
begin
  LimpiarMemoria;
  FBools.Free;
  FInts.Free;
  FStrs.Free;
  inherited;
end;

procedure TfrmMtoCajaParam.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoCajaParam.LimpiarMemoria;
var
  pB: PBoolean; pI: PInteger; pS: PString;
begin
  // Liberamos la memoria de los punteros que asignamos a JvInspector.
  // Es vital tiparlos (Dispose) para que los strings decremente su contador de referencias.
  for pB in FBools do Dispose(pB);
  FBools.Clear;

  for pI in FInts do Dispose(pI);
  FInts.Clear;

  for pS in FStrs do Dispose(pS);
  FStrs.Clear;
end;

// ----------------------------------------------------------------------
// CONSTRUCCIÓN DINÁMICA DE LA INTERFAZ
// ----------------------------------------------------------------------

function TfrmMtoCajaParam.ObtenerCategoria(const NombreCat: string): TJvInspectorCustomCategoryItem;
var
  i: Integer;
begin
  // Busca si la categoría ya existe; si no, la crea al vuelo
  for i := 0 to JvInspector1.Root.Count - 1 do
    if (JvInspector1.Root.Items[i] is TJvInspectorCustomCategoryItem) and
       SameText(JvInspector1.Root.Items[i].DisplayName, NombreCat) then
      Exit(TJvInspectorCustomCategoryItem(JvInspector1.Root.Items[i]));

  Result := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
  Result.DisplayName := NombreCat;
  Result.Expanded := True; // Expandir por defecto
end;

procedure TfrmMtoCajaParam.ConstruirInspector;
var
  Param: TParamDef;
  CatItem: TJvInspectorCustomCategoryItem;
  ItemCombo: TJvCustomInspectorItem;
  pBool: PBoolean; pInt: PInteger; pStr: PString;
begin
  LimpiarMemoria;
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;

    // Magia pura: Leemos la librería de parámetros y dibujamos según su tipo y categoría
    for Param in oCajaParams.Params.Values do
    begin
      // Nota: Asume que has añadido "Categoria: string" en TParamDef (inLibCajaParam)
      // Si no, puedes usar una categoría genérica: ObtenerCategoria('General');
      CatItem := ObtenerCategoria(Param.Categoria);

      case Param.Tipo of
        tpBoolean:
          begin
            New(pBool);
            FBools.Add(pBool);
            pBool^ := SameText(Param.ValorPorDefecto, 'True') or (Param.ValorPorDefecto = '1');
            with TJvInspectorVarData.New(CatItem, Param.Nombre, TypeInfo(Boolean), pBool) do
              DisplayName := Param.Descripcion;
          end;
        tpInteger:
          begin
            New(pInt);
            FInts.Add(pInt);
            pInt^ := StrToIntDef(Param.ValorPorDefecto, 0);
            with TJvInspectorVarData.New(CatItem, Param.Nombre, TypeInfo(Integer), pInt) do
              DisplayName := Param.Descripcion;
          end;
        tpString:
          begin
            New(pStr);
            FStrs.Add(pStr);
            pStr^ := Param.ValorPorDefecto;
            ItemCombo := TJvInspectorVarData.New(CatItem, Param.Nombre, TypeInfo(string), pStr);
            ItemCombo.DisplayName := Param.Descripcion;

            // Excepción específica visual para tu combo de impresión
            if SameText(Param.Nombre, 'vgerTipoImpresion') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetTipoImpresionList;
            end;
          end;
      end;
    end;
  finally
    JvInspector1.EndUpdate;
  end;
end;

// ----------------------------------------------------------------------
// CARGA Y GUARDADO (LÓGICA GENÉRICA)
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.ResetearADefectos;
var
  Param: TParamDef;
  ItemData: TJvCustomInspectorItem;
begin
  // Fuerza a los controles visuales a mostrar el valor por defecto antes de cargar de DB
  for Param in oCajaParams.Params.Values do
  begin
    ItemData := BuscarItemPorNombre(JvInspector1.Root, Param.Nombre);
    if ItemData <> nil then
      ItemData.DisplayValue := Param.ValorPorDefecto;
  end;
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TJvInspector;
                                            const pUsuario,
                                            pGrupo: string);
var
  qry: TUniQuery;
  SubKey, ValorStr: string;
  ItemData: TJvCustomInspectorItem;
begin
  ResetearADefectos;
  Grid.Refresh;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
            'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;

    Grid.BeginUpdate;
    try
      while not qry.Eof do
      begin
        SubKey := qry.FieldByName('SUBKEY_PERFILES').AsString;
        ValorStr := qry.FieldByName('VALUE_PERFILES').AsString;
        ItemData := BuscarItemPorNombre(Grid.Root, SubKey);

        if (ItemData <> nil) and (ItemData.Data <> nil) then
        begin
          try
            if (ValorStr = '') and
                      (ItemData.Data.TypeInfo.Kind in [tkInteger, tkFloat]) then
              ValorStr := '0';
            ItemData.DisplayValue := ValorStr;
          except
          end;
        end;
        qry.Next;
      end;
    finally
      Grid.EndUpdate;
    end;
  finally
    qry.Free;
  end;
end;

procedure TfrmMtoCajaParam.btnGuardarClick(Sender: TObject);
var
  qry: TUniQuery;
  sUsuarioGrupo: string;
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorAGuardar: string; // Variable auxiliar para extraer el valor seguro
begin
  // 1. Movemos el foco fuera para disparar el evento OnExit del editor
  JvInspector1.SaveValues;
  if cmbGrupoUsuario.ItemIndex = -1 then Exit;
  sUsuarioGrupo := cmbGrupoUsuario.Text;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'CALL PRC_SETPERFILFORMULARIO(:p_usuario_grupo, :p_formulario, :p_subkey, :p_value)';

    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      NodoPrincipal := JvInspector1.Root.Items[i];

      if NodoPrincipal is TJvInspectorCustomCategoryItem then
      begin
        for j := 0 to NodoPrincipal.Count - 1 do
        begin
          ParamItem := NodoPrincipal.Items[j];

          // --- EXTRACCIÓN SEGURA SEGÚN EL TIPO DE DATO ---
          if ParamItem.Data <> nil then
          begin
            case ParamItem.Data.TypeInfo.Kind of
              tkEnumeration: // Los Booleanos entran aquí en RTTI
                if ParamItem.Data.AsOrdinal <> 0 then
                  ValorAGuardar := 'True'
                else
                  ValorAGuardar := 'False';

              tkInteger: // Números enteros
                ValorAGuardar := IntToStr(ParamItem.Data.AsOrdinal);

              else // Para tkString, tkUString, tkWString, etc.
                ValorAGuardar := ParamItem.Data.AsString;
            end;
          end
          else
            ValorAGuardar := ''; // Por si acaso algún nodo no tiene Data

          // Guardamos en BD
          qry.ParamByName('p_usuario_grupo').AsString := sUsuarioGrupo;
          qry.ParamByName('p_formulario').AsString    := 'frmMtoCajaParam';
          qry.ParamByName('p_subkey').AsString        := ParamItem.Name;
          qry.ParamByName('p_value').AsString         := ValorAGuardar;
          qry.Execute;
        end;
      end;
      // Nota: He quitado el "else" del NodoPrincipal porque, como vimos,
      // tu diseño siempre usa Categorías en el nivel 0.
      // Si tuvieras nodos sueltos, la lógica de extracción sería exactamente la misma.
    end;
    ShowMessage('Parámetros guardados correctamente para: ' + sUsuarioGrupo);
  finally
    qry.Free;
  end;
  if (sUsuarioGrupo = oUser) or (sUsuarioGrupo = oGroup) or (sUsuarioGrupo = oAll) then
    oCajaParams.Recargar(oUser, oGroup);
end;

procedure TfrmMtoCajaParam.FormShow(Sender: TObject);
begin
  ConstruirInspector;

  cmbGrupoUsuario.Properties.Items.Clear;
  cmbGrupoUsuario.Properties.Items.Add(oUser);
  cmbGrupoUsuario.Properties.Items.Add(oGroup);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  cmbGrupoUsuario.ItemIndex := 0;

  btnChangeId.Visible := (oRootGroup = 'S');

  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

procedure TfrmMtoCajaParam.GetTipoImpresionList(Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('ESC POS');
  Strings.Add('ESC POS NOQR');
  Strings.Add('EDITOR');
  Strings.Add('DEBUG');
end;

function TfrmMtoCajaParam.BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem; const Nombre: string): TJvCustomInspectorItem;
var
  i: Integer; Encontrado: TJvCustomInspectorItem;
begin
  Result := nil;
  for i := 0 to ItemPadre.Count - 1 do
  begin
    if SameText(ItemPadre.Items[i].Name, Nombre) then Exit(ItemPadre.Items[i]);
    if ItemPadre.Items[i] is TJvInspectorCustomCategoryItem then
    begin
      Encontrado := BuscarItemPorNombre(ItemPadre.Items[i], Nombre);
      if Encontrado <> nil then Exit(Encontrado);
    end;
  end;
end;

procedure TfrmMtoCajaParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
begin
  case cmbGrupoUsuario.ItemIndex of
    0: begin sUsuario := oUser;  sGrupo := '';      end;
    1: begin sUsuario := '';     sGrupo := oGroup;  end;
    2: begin sUsuario := '';     sGrupo := oAll;    end;
  else
    Exit;
  end;
  CargarParametros(JvInspector1, sUsuario, sGrupo);
end;

procedure TfrmMtoCajaParam.actGuardarExecute(Sender: TObject);
begin
  inherited;
  btnGuardarClick(Sender);
  Close;
end;

procedure TfrmMtoCajaParam.actSalirExecute(Sender: TObject);
begin
  inherited;
  if MessageDlg('¿Está seguro de que desea salir sin guardar?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Close;
end;

procedure TfrmMtoCajaParam.btnChangeIdClick(Sender: TObject);
var
  qry: TUniQuery;
  usuarios: TStringList;
  sUsuario: string;
begin
  qry := TUniQuery.Create(nil);
  usuarios := TStringList.Create;
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'SELECT DISTINCT USUARIO_GRUPO_PERFILES FROM fza_usuarios_perfiles WHERE KEY_PERFILES = ''frmMtoCajaParam'' ORDER BY USUARIO_GRUPO_PERFILES';
    qry.Open;
    while not qry.Eof do
    begin
      usuarios.Add(qry.Fields[0].AsString);
      qry.Next;
    end;

    if usuarios.Count = 0 then
    begin
      ShowMessage('No hay usuarios con parámetros guardados para este formulario.');
      Exit;
    end;

    sUsuario := usuarios[0];
    if InputQuery('Cambiar usuario', 'Usuarios disponibles:' + sLineBreak + usuarios.CommaText + sLineBreak + sLineBreak + 'Introduce el nombre de usuario:', sUsuario) then
    begin
      if usuarios.IndexOf(sUsuario) < 0 then
        ShowMessage('Usuario no encontrado: ' + sUsuario)
      else
      begin
        CargarParametros(JvInspector1, sUsuario, '');
        if cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario) < 0 then
          cmbGrupoUsuario.Properties.Items.Add(sUsuario);
        cmbGrupoUsuario.ItemIndex := cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario);
      end;
    end;
  finally
    usuarios.Free;
    qry.Free;
  end;
end;

function TfrmMtoCajaParam.QuitarTildes(const Texto: string): string;
var i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
    case Result[i] of
      'á', 'à', 'ä', 'â': Result[i] := 'a';
      'é', 'è', 'ë', 'ê': Result[i] := 'e';
      'í', 'ì', 'ï', 'î': Result[i] := 'i';
      'ó', 'ò', 'ö', 'ô': Result[i] := 'o';
      'ú', 'ù', 'ü', 'û': Result[i] := 'u';
      'Á', 'À', 'Ä', 'Â': Result[i] := 'A';
      'É', 'È', 'Ë', 'Ê': Result[i] := 'E';
      'Í', 'Ì', 'Ï', 'Î': Result[i] := 'I';
      'Ó', 'Ò', 'Ö', 'Ô': Result[i] := 'O';
      'Ú', 'Ù', 'Ü', 'Û': Result[i] := 'U';
    end;
end;

procedure TfrmMtoCajaParam.FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
var
  TextoBusquedaLimpio: string;
  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var Coincide, HijoVisible: Boolean; i: Integer;
  begin
    Coincide := (Texto = '') or (AnsiContainsText(QuitarTildes(Row.DisplayName), TextoBusquedaLimpio));
    HijoVisible := False;
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    Row.Visible := Coincide or HijoVisible;
    if (Row is TJvInspectorCustomCategoryItem) and HijoVisible and (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;
var i: Integer;
begin
  Grid.BeginUpdate;
  try
    TextoBusquedaLimpio := QuitarTildes(Texto);
    for i := 0 to Grid.Root.Count - 1 do
      ProcesarFila(Grid.Root.Items[i]);
  finally
    Grid.EndUpdate;
  end;
end;

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoCajaParam.edtBusquedaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

end.
