unit inMtoCajaParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxFilter, dxScrollbarAnnotations, cxEdit,
  cxCheckBox, cxVGrid, cxInplaceContainer, cxTextEdit, cxContainer,
  inLibGlobalVar, dxCoreGraphics, cxMaskEdit, cxButtonEdit, cxSpinEdit,
  Vcl.ExtCtrls, inMtoFrmBase, Uni, cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons, JvComponentBase, JvInspector, JvExControls;

type
  TfrmMtoCajaParam = class(TFrmBase)
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    Panel2: TPanel;     // Mostrar empleado en linea de caja

    // Otros componentes
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    JvInspector1: TJvInspector;
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;           //permite descuentos en ventas

    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
  private
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    function QuitarTildes(const Texto: string): string;
    procedure CargarParametros(Grid: TJvInspector;
                           const pUsuario, pGrupo: string);
    { Public declarations }
  private
    // --- VARIABLES PARA EL INSPECTOR ---
    // GRUPO: Control de Artículos
    FvgerChkExistOnly: Boolean;
    FvgerChkStockOnly: Boolean;
    // GRUPO: Configuración de Caja
    FvgerShowCajaSelection: Boolean;
    FvgerFillEmpleadoDefecto: Boolean;
    FvgerDefTarifa: string;
    FvgerMaxOpPending: Integer;
    // GRUPO: Devoluciones y Vales
    FvgerReqRefDevolucion: Boolean;
    FvgerRecuperaValePIN: Boolean;
    FvgerCaducidadDefVale: Boolean;
    FvgerDiasCaducidadVale: Integer;
    // GRUPO: Avisos y Búsquedas
    FvgerAvisoStockWarning: string;
    FvgerBusqArtStockOnly: Boolean;
    FvgerBusqArtTarifaOnly: Boolean;
    FvgerMoverLineaIdentif: Boolean;
    // GRUPO: Impresión
    FvgerDefPrinter: string;
    FvgerTipoImpresion: string;
    FvgerFormatoImpPredet: string;
    // GRUPO: Empleado
    FvgerCodEmpleadoDefecto: string;
    FvgerShowEmpleadoLinea: Boolean;
    // GRUPO: Otros (Permisos extra)
    FvgerArqueoTarjetas: Boolean;
    FvgerVentasCredito: Boolean;
    FvgerDescuentos: Boolean;
    // Métodos que vamos a adaptar:
    procedure ConstruirInspector;
    procedure GetTipoImpresionList(Sender: TJvCustomInspectorItem; Strings: TStrings);
    procedure CargarValoresPorDefecto;
  end;

var
  frmMtoCajaParam: TfrmMtoCajaParam;

implementation

{$R *.dfm}

uses
  StrUtils, inLibCajaParam; // Necesario para la función AnsiContainsText (búsqueda insensible a mayúsculas)

// Función para normalizar el texto quitando tildes
function TfrmMtoCajaParam.QuitarTildes(const Texto: string): string;
var
  i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
  begin
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
end;

procedure TfrmMtoCajaParam.edtBusquedaKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoCajaParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
begin
  case cmbGrupoUsuario.ItemIndex of
    0: begin sUsuario := oUser;  sGrupo := '';      end; // Usuario específico
    1: begin sUsuario := '';     sGrupo := oGroup;  end; // Grupo
    2: begin sUsuario := '';     sGrupo := oAll;    end; // Todos
  else
    Exit;
  end;
  CargarParametros(JvInspector1, sUsuario, sGrupo);
end;

procedure TfrmMtoCajaParam.ConstruirInspector;
var
  CatArticulos, CatCaja, CatDevoluciones, CatAvisos, CatImpresion, CatEmpleado, CatOtros: TJvInspectorCustomCategoryItem;
  ItemCombo: TJvCustomInspectorItem;
begin
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;
    // --- GRUPO: Control de Artículos ---
    CatArticulos := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatArticulos.DisplayName := 'Control de Artículos';
    with TJvInspectorVarData.New(CatArticulos, 'vgerChkExistOnly', TypeInfo(Boolean), @FvgerChkExistOnly) do DisplayName := 'Permitir sólo artículos que existan';
    with TJvInspectorVarData.New(CatArticulos, 'vgerChkStockOnly', TypeInfo(Boolean), @FvgerChkStockOnly) do DisplayName := 'Permitir vender sin stock';
    // --- GRUPO: Configuración de Caja ---
    CatCaja := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatCaja.DisplayName := 'Configuración de Caja';
    with TJvInspectorVarData.New(CatCaja, 'vgerShowCajaSelection', TypeInfo(Boolean), @FvgerShowCajaSelection) do DisplayName := 'Presentar selección de caja';
    with TJvInspectorVarData.New(CatCaja, 'vgerFillEmpleadoDefecto', TypeInfo(Boolean), @FvgerFillEmpleadoDefecto) do DisplayName := 'Rellenar empleado por defecto al abrir';
    with TJvInspectorVarData.New(CatCaja, 'vgerDefTarifa', TypeInfo(string), @FvgerDefTarifa) do DisplayName := 'Tarifa por defecto en caja';
    with TJvInspectorVarData.New(CatCaja, 'vgerMaxOpPending', TypeInfo(Integer), @FvgerMaxOpPending) do DisplayName := 'Número de operaciones pendientes';
    // --- GRUPO: Devoluciones y Vales ---
    CatDevoluciones := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatDevoluciones.DisplayName := 'Devoluciones y Vales';
    with TJvInspectorVarData.New(CatDevoluciones, 'vgerReqRefDevolucion', TypeInfo(Boolean), @FvgerReqRefDevolucion) do DisplayName := 'Pedir referencia en devoluciones';
    with TJvInspectorVarData.New(CatDevoluciones, 'vgerRecuperaValePIN', TypeInfo(Boolean), @FvgerRecuperaValePIN) do DisplayName := 'Recuperar Vale sólo con PIN';
    with TJvInspectorVarData.New(CatDevoluciones, 'vgerCaducidadDefVale', TypeInfo(Boolean), @FvgerCaducidadDefVale) do DisplayName := 'Caducidad por defecto en vale';
    with TJvInspectorVarData.New(CatDevoluciones, 'vgerDiasCaducidadVale', TypeInfo(Integer), @FvgerDiasCaducidadVale) do DisplayName := 'Días hasta caducidad en vale';
    // --- GRUPO: Avisos y Búsquedas ---
    CatAvisos := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatAvisos.DisplayName := 'Avisos y Búsquedas';
    with TJvInspectorVarData.New(CatAvisos, 'vgerAvisoStockWarning', TypeInfo(String), @FvgerAvisoStockWarning) do DisplayName := 'Aviso en artículos sin stock';
    with TJvInspectorVarData.New(CatAvisos, 'vgerBusqArtStockOnly', TypeInfo(Boolean), @FvgerBusqArtStockOnly) do DisplayName := 'Búsqueda de artículos sólo con stock';
    with TJvInspectorVarData.New(CatAvisos, 'vgerBusqArtTarifaOnly', TypeInfo(Boolean), @FvgerBusqArtTarifaOnly) do DisplayName := 'Búsqueda de artículos sólo con tarifa';
    with TJvInspectorVarData.New(CatAvisos, 'vgerMoverLineaIdentif', TypeInfo(Boolean), @FvgerMoverLineaIdentif) do DisplayName := 'Mover linea al identificar artículo';
    // --- GRUPO: Impresión ---
    CatImpresion := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatImpresion.DisplayName := 'Impresión';
    with TJvInspectorVarData.New(CatImpresion, 'vgerDefPrinter', TypeInfo(string), @FvgerDefPrinter) do DisplayName := 'Nombre impresora de tickets';
    ItemCombo := TJvInspectorVarData.New(CatImpresion, 'vgerTipoImpresion', TypeInfo(string), @FvgerTipoImpresion);
    ItemCombo.DisplayName := 'Tipo de Impresión tickets';
    ItemCombo.Flags := ItemCombo.Flags + [iifValueList]; // Combo desplegable
    ItemCombo.OnGetValueList := GetTipoImpresionList;
    with TJvInspectorVarData.New(CatImpresion, 'vgerFormatoImpPredet', TypeInfo(string), @FvgerFormatoImpPredet) do DisplayName := 'Formato de impresión predeterminado';
    // --- GRUPO: Empleado ---
    CatEmpleado := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatEmpleado.DisplayName := 'Empleado';
    with TJvInspectorVarData.New(CatEmpleado, 'vgerCodEmpleadoDefecto', TypeInfo(string), @FvgerCodEmpleadoDefecto) do DisplayName := 'Código de empleado por defecto';
    with TJvInspectorVarData.New(CatEmpleado, 'vgerShowEmpleadoLinea', TypeInfo(Boolean), @FvgerShowEmpleadoLinea) do DisplayName := 'Mostrar empleado en linea de caja';
    // --- GRUPO: Otros ---
    CatOtros := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
    CatOtros.DisplayName := 'Permisos Extra';
    with TJvInspectorVarData.New(CatOtros, 'vgerArqueoTarjetas', TypeInfo(Boolean), @FvgerArqueoTarjetas) do DisplayName := 'Permitir Arqueo de Tarjetas';
    with TJvInspectorVarData.New(CatOtros, 'vgerVentasCredito', TypeInfo(Boolean), @FvgerVentasCredito) do DisplayName := 'Permitir Ventas a Crédito';
    with TJvInspectorVarData.New(CatOtros, 'vgerDescuentos', TypeInfo(Boolean), @FvgerDescuentos) do DisplayName := 'Permite descuentos en ventas';
    // (Opcional) Expandir todas las categorías por defecto
    CatArticulos.Expanded := True;
    CatCaja.Expanded := True;
    CatDevoluciones.Expanded := True;
    CatAvisos.Expanded := True;
    CatImpresion.Expanded := True;
    CatEmpleado.Expanded := True;
    CatOtros.Expanded := True;
  finally
    JvInspector1.EndUpdate;
  end;
end;

// Evento que rellena tu ComboBox de Tipo de Impresión
procedure TfrmMtoCajaParam.GetTipoImpresionList(Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('ESC POS');
  Strings.Add('ESC POS NOQR');
  Strings.Add('EDITOR');
end;

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoCajaParam.btnChangeIdClick(Sender: TObject);
var
  qry: TUniQuery;
  usuarios: TStringList;
  sUsuario: string;
  idx: Integer;
begin
  qry := TUniQuery.Create(nil);
  usuarios := TStringList.Create;
  try
    // Obtener usuarios distintos que tengan parámetros de este formulario
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT DISTINCT USUARIO_GRUPO_PERFILES ' +
      'FROM fza_usuarios_perfiles ' +
      'WHERE KEY_PERFILES = ''frmMtoCajaParam'' ' +
      'ORDER BY USUARIO_GRUPO_PERFILES';
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

    // Selección mediante InputQuery con combo simulado
    sUsuario := usuarios[0];
    if not InputQuery('Cambiar usuario',
                      'Usuarios disponibles:' + sLineBreak +
                      usuarios.CommaText + sLineBreak + sLineBreak +
                      'Introduce el nombre de usuario:',
                      sUsuario) then
      Exit;

    // Verificar que el usuario introducido existe
    idx := usuarios.IndexOf(sUsuario);
    if idx < 0 then
    begin
      ShowMessage('Usuario no encontrado: ' + sUsuario);
      Exit;
    end;

    // Cargar parámetros como si fuéramos ese usuario
    CargarParametros(JvInspector1, sUsuario, '');
    // Opcional: reflejar en el combo quién está "activo"
    // Añadir al combo si no estaba
    if cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario) < 0 then
      cmbGrupoUsuario.Properties.Items.Add(sUsuario);
    cmbGrupoUsuario.ItemIndex :=
      cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario);
  finally
    usuarios.Free;
    qry.Free;
  end;
end;

procedure TfrmMtoCajaParam.btnGuardarClick(Sender: TObject);
var
  qry: TUniQuery;
  sUsuarioGrupo: string;
  // Función local para recorrer el árbol del Inspector y guardar
  procedure GuardarNodos(ItemPadre: TJvCustomInspectorItem);
  var i: Integer; ItemHijo: TJvCustomInspectorItem;
  begin
    for i := 0 to ItemPadre.Count - 1 do
    begin
      ItemHijo := ItemPadre.Items[i];
      if ItemHijo is TJvInspectorCustomCategoryItem then
        GuardarNodos(ItemHijo) // Si es categoría, entramos dentro
      else
      begin
        // Si es un parámetro real, guardamos en BD
        qry.ParamByName('p_usuario_grupo').AsString := sUsuarioGrupo;
        qry.ParamByName('p_formulario').AsString    := 'frmMtoCajaParam';
        qry.ParamByName('p_subkey').AsString        := ItemHijo.Name; // Ej: 'vgerChkExistOnly'
        qry.ParamByName('p_value').AsString         := ItemHijo.Data.AsString; // Valor del parámetro
        qry.Execute;
      end;
    end;
  end;
begin
  if cmbGrupoUsuario.ItemIndex = -1 then Exit;
  sUsuarioGrupo := cmbGrupoUsuario.Text;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'CALL PRC_SETPERFILFORMULARIO(:p_usuario_grupo, :p_formulario, :p_subkey, :p_value)';
    // Inicia el proceso recursivo desde la raíz
    GuardarNodos(JvInspector1.Root);
    ShowMessage('Parámetros guardados correctamente para: ' + sUsuarioGrupo);
  finally
    qry.Free;
  end;
  if (sUsuarioGrupo = oUser) or (sUsuarioGrupo = oGroup) or (sUsuarioGrupo = oAll) then
    oCajaParams.Recargar(oUser, oGroup);
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TJvInspector; const pUsuario, pGrupo: string);
var
  qry: TUniQuery;
  SubKey, ValorStr: string;
  function BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem; const Nombre: string): TJvCustomInspectorItem;
  var i: Integer; Encontrado: TJvCustomInspectorItem;
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
var
  ItemData: TJvCustomInspectorItem;
begin
  // 1. Limpiamos las variables en memoria y refrescamos el grid
  // para no heredar "basura" del usuario que estuviera seleccionado antes.
  CargarValoresPorDefecto;
  Grid.Refresh;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
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
            // Si el destino es un Número y en la BD viene vacío, le forzamos un '0'
            if (ValorStr = '') and (ItemData.Data.TypeInfo.Kind in [tkInteger, tkFloat]) then
              ValorStr := '0';
            // Intentamos asignar el valor
            ItemData.DisplayValue := ValorStr;
          except
            // Si algo falla (ej. BD corrupta), lo capturamos silenciosamente.
            // Así el TcxComboBox no se entera del fallo y no se revierte.
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

procedure TfrmMtoCajaParam.CargarValoresPorDefecto;
begin
  // Booleans
  FvgerChkExistOnly := False;
  FvgerChkStockOnly := False;
  FvgerShowCajaSelection := False;
  FvgerFillEmpleadoDefecto := False;
  FvgerReqRefDevolucion := False;
  FvgerRecuperaValePIN := False;
  FvgerCaducidadDefVale := False;
  FvgerAvisoStockWarning := 'Artículo sin stock. Compruebe stock en almacén.';
  FvgerBusqArtStockOnly := False;
  FvgerBusqArtTarifaOnly := False;
  FvgerMoverLineaIdentif := False;
  FvgerShowEmpleadoLinea := False;
  FvgerArqueoTarjetas := False;
  FvgerVentasCredito := False;
  FvgerDescuentos := False;
  // Integers
  FvgerMaxOpPending := 0;
  FvgerDiasCaducidadVale := 0;
  // Strings
  FvgerDefTarifa := '';
  FvgerDefPrinter := '';
  FvgerTipoImpresion := 'ESC POS'; // Valor por defecto del combo
  FvgerFormatoImpPredet := '';
  FvgerCodEmpleadoDefecto := '';
end;

procedure TfrmMtoCajaParam.FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
var
  TextoBusquedaLimpio: string;
  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var
    Coincide, HijoVisible: Boolean;
    i: Integer;
  begin
    Coincide := (Texto = '') or (AnsiContainsText(QuitarTildes(Row.DisplayName), TextoBusquedaLimpio));
    HijoVisible := False;
    // Recursividad para comprobar si tiene hijos visibles (así mostramos la categoría si un hijo coincide)
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    // El elemento es visible si él coincide o si alguno de sus hijos coincide
    Row.Visible := Coincide or HijoVisible;
    // Si la categoría tiene resultados, la expandimos automáticamente para verlos
    if (Row is TJvInspectorCustomCategoryItem) and
        HijoVisible and
       (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;
var
  i: Integer;
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

procedure TfrmMtoCajaParam.FormShow(Sender: TObject);
begin
  // 1. Dar valores por defecto a la memoria
  CargarValoresPorDefecto;
  // 2. Construir el esqueleto visual del Inspector
  ConstruirInspector;
  // 3. Cargar combo con usuario, grupo y 'Todos'
  cmbGrupoUsuario.Properties.Items.Clear;
  cmbGrupoUsuario.Properties.Items.Add(oUser);
  cmbGrupoUsuario.Properties.Items.Add(oGroup);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  // 4. ¡IMPORTANTE! Al asignar el ItemIndex a 0, se disparará automáticamente
  // el evento OnChange del Combo, que es el que cargará los datos de la BD.
  cmbGrupoUsuario.ItemIndex := 0;
  if oRootGroup = 'S' then
    btnChangeId.Visible := True
  else
    btnChangeId.Visible := False;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

end.
