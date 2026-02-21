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
    vgerDepositos: TcxEditorRow;
    vgerDescuentos: TcxEditorRow;
    
    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
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
  StrUtils; // Necesario para la función AnsiContainsText (búsqueda insensible a mayúsculas)

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

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(cxVerticalGrid1, edtBusqueda.Text);
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TcxVerticalGrid; const pUsuario, pGrupo: string);
var
  sp: TUniStoredProc;
  i: Integer;
  Row: TcxCustomRow;
  SubKey: string;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection := oConn;
    sp.StoredProcName := 'PRC_GETPERFILFORMULARIO';
    sp.Params.ParamByName('p_usuario').AsString := pUsuario;
    sp.Params.ParamByName('p_grupo').AsString := pGrupo;
    sp.Params.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    sp.Open;

    Grid.BeginUpdate;
    try
      while not sp.Eof do
      begin
        SubKey := sp.FieldByName('SUBKEY_PERFILES').AsString;

        // Buscamos la fila en el grid que coincida con el nombre del parámetro
        for i := 0 to cxVerticalGrid1.Rows.Count - 1 do
        begin
          Row := cxVerticalGrid1.Rows[i];
          if (Row is TcxEditorRow) and (SameText(Row.Name, SubKey)) then
          begin
             // Asignamos el valor recuperado
             TcxEditorRow(Row).Properties.Value := sp.FieldByName('VALUE_PERFILES').Value;
             Break;
          end;
        end;
        sp.Next;
      end;
    finally
      Grid.EndUpdate;
    end;
  finally
    sp.Free;
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
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

end.
