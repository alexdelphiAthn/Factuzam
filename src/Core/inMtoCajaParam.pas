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
  cxButtons;

type
  TfrmMtoCajaParam = class(TFrmBase)
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    Panel2: TPanel;
    cxVerticalGrid1: TcxVerticalGrid;
    
    // GRUPO: Control de Artículos
    vgerChkExistOnly: TcxEditorRow;          // Permitir sólo artículos que existan
    vgerChkStockOnly: TcxEditorRow;          // Permitir vender sin stock
    
    // GRUPO: Configuración de Caja
    vgerShowCajaSelection: TcxEditorRow;     // Presentar selección de caja
    vgerFillEmpleadoDefecto: TcxEditorRow;   // Rellenar empleado por defecto al abrir
    vgerDefTarifa: TcxEditorRow;             // Tarifa por defecto en caja
    vgerMaxOpPending: TcxEditorRow;          // Número de operaciones pendientes
    
    // GRUPO: Devoluciones y Vales
    vgerReqRefDevolucion: TcxEditorRow;      // Pedir referencia en devoluciones
    vgerRecuperaValePIN: TcxEditorRow;       // Recuperar Vale sólo con PIN
    vgerCaducidadDefVale: TcxEditorRow;      // Caducidad por defecto en vale
    vgerDiasCaducidadVale: TcxEditorRow;     // Días hasta caducidad en vale
    
    // GRUPO: Avisos y Búsquedas
    vgerAvisoStockWarning: TcxEditorRow;     // Aviso en artículos sin stock
    vgerBusqArtStockOnly: TcxEditorRow;      // Búsqueda de artículos sólo con stock
    vgerBusqArtTarifaOnly: TcxEditorRow;     // Búsqueda de artículos sólo con tarifa
    vgerMoverLineaIdentif: TcxEditorRow;     // Mover linea al identificar artículo
    
    // GRUPO: Impresión
    vgerDefPrinter: TcxEditorRow;            // Nombre impresora de tickets
    vgerTipoImpresion: TcxEditorRow;         // Tipo de Impresión tickets
    vgerFormatoImpPredet: TcxEditorRow;      // Formato de impresión predeterminado
    
    // GRUPO: Empleado
    vgerCodEmpleadoDefecto: TcxEditorRow;    // Código de empleado por defecto
    vgerShowEmpleadoLinea: TcxEditorRow;     // Mostrar empleado en linea de caja

    // Otros componentes
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    vgerArqueoTarjetas: TcxEditorRow;
    vgerVentasCredito: TcxEditorRow;
    vgerDescuentos: TcxEditorRow;           //permite descuentos en ventas

    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
  private
    procedure FiltrarVerticalGrid(Grid: TcxVerticalGrid; Texto: string);
    function QuitarTildes(const Texto: string): string;
    procedure CargarParametros(Grid: TcxVerticalGrid;
                               const pUsuario, pGrupo: string);
  public
    { Public declarations }
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
  CargarParametros(cxVerticalGrid1, sUsuario, sGrupo);
end;

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(cxVerticalGrid1, edtBusqueda.Text);
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
    CargarParametros(cxVerticalGrid1, sUsuario, '');

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
  i: Integer;
  Row: TcxCustomRow;
  sUsuarioGrupo: string;
begin
  // CORRECCIÓN: Validar que haya algo seleccionado
  if cmbGrupoUsuario.ItemIndex = -1 then Exit;

  // CORRECCIÓN: Tomamos el texto directamente del combo.
  // Esto funcionará tanto para oUser, oGroup como para el usuario cargado por btnChangeId.
  sUsuarioGrupo := cmbGrupoUsuario.Text;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    // Usamos el procedimiento almacenado para guardar
    qry.SQL.Text := 'CALL PRC_SETPERFILFORMULARIO(:p_usuario_grupo, :p_formulario, :p_subkey, :p_value)';

    for i := 0 to cxVerticalGrid1.Rows.Count - 1 do
    begin
      Row := cxVerticalGrid1.Rows[i];
      if not (Row is TcxEditorRow) then
        Continue;

      qry.ParamByName('p_usuario_grupo').AsString := sUsuarioGrupo;
      qry.ParamByName('p_formulario').AsString    := 'frmMtoCajaParam';
      qry.ParamByName('p_subkey').AsString        := Row.Name;
      qry.ParamByName('p_value').AsString         := VarToStr(TcxEditorRow(Row).Properties.Value);
      qry.Execute;
    end;

    ShowMessage('Parámetros guardados correctamente para: ' + sUsuarioGrupo);
  finally
    qry.Free;
  end;

  // Refrescar variables globales si el guardado fue para el usuario actual
  if (sUsuarioGrupo = oUser) or (sUsuarioGrupo = oGroup) or (sUsuarioGrupo = oAll) then
    oCajaParams.Recargar(oUser, oGroup);
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TcxVerticalGrid; const pUsuario, pGrupo: string);
var
  qry: TUniQuery;
  i: Integer;
  Row: TcxCustomRow;
  SubKey: string;
begin
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
        for i := 0 to Grid.Rows.Count - 1 do
        begin
          Row := Grid.Rows[i];
          if (Row is TcxEditorRow) and SameText(Row.Name, SubKey) then
          begin
            TcxEditorRow(Row).Properties.Value := qry.FieldByName('VALUE_PERFILES').Value;
            Break;
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

procedure TfrmMtoCajaParam.FiltrarVerticalGrid(Grid: TcxVerticalGrid; Texto: string);
var
  i: Integer;
  TextoBusquedaLimpio: string;

  // Función local recursiva para revisar filas y sus hijos
  function ProcesarFila(Row: TcxCustomRow): Boolean;
  var
    Coincide: Boolean;
    TextoFila: string;
    // j: Integer;
    // HijoVisible: Boolean;
  begin
    TextoFila := '';
    if Row is TcxEditorRow then
      TextoFila := TcxEditorRow(Row).Properties.Caption
    else if Row is TcxCategoryRow then
      TextoFila := TcxCategoryRow(Row).Properties.Caption;

    Coincide := (Texto = '') or
               (AnsiContainsText(QuitarTildes(TextoFila), TextoBusquedaLimpio));
    {// 3. Revisamos los hijos (recursividad)
    HijoVisible := False;
    for j := 0 to Row.Count - 1 do
    begin
      if ProcesarFila(Row.Rows[j]) then
        HijoVisible := True;
    end;}
    Row.Visible := Coincide;// or HijoVisible;
    Result := Row.Visible;
  end;

begin
  Grid.BeginUpdate;
  try
    TextoBusquedaLimpio := QuitarTildes(Texto);
    for i := 0 to Grid.Rows.Count - 1 do
      ProcesarFila(Grid.Rows[i]);
  finally
    Grid.EndUpdate;
  end;
end;


procedure TfrmMtoCajaParam.FormShow(Sender: TObject);
begin
  // Cargar combo con usuario, grupo y 'Todos'
  cmbGrupoUsuario.Properties.Items.Clear;
  cmbGrupoUsuario.Properties.Items.Add(oUser);
  cmbGrupoUsuario.Properties.Items.Add(oGroup);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  cmbGrupoUsuario.ItemIndex := 0; // Seleccionar usuario por defecto
  if oRootGroup = 'S' then
    btnChangeId.Visible := True
  else
    btnChangeId.Visible := False;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

end.
