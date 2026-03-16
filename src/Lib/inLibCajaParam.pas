unit inLibCajaParam;

interface

uses
  System.Generics.Collections, System.SysUtils, Uni;

type
  TCajaParams = class
  private
    FParams: TDictionary<string, string>;
    procedure CargarValoresPorDefecto; // NUEVO: Pre-carga los valores base
    procedure CargarDesdeDB(const pUsuario, pGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Inicializar(const pUsuario, pGrupo: string);
    procedure Recargar(const pUsuario, pGrupo: string);

    // Acceso tipado a cada parámetro (los Default ahora actúan solo como red de seguridad extra)
    function GetString (const Key: string; const Default: string  = ''   ): string;
    function GetBool   (const Key: string; const Default: Boolean = False): Boolean;
    function GetInt    (const Key: string; const Default: Integer = 0    ): Integer;

    // Acceso directo al diccionario por si se necesita
    property Params: TDictionary<string, string> read FParams;
  end;

// Instancia global accesible desde cualquier unidad
var
  oCajaParams: TCajaParams;

implementation

uses
  inLibGlobalVar;

{ TCajaParams }

constructor TCajaParams.Create;
begin
  inherited;
  FParams := TDictionary<string, string>.Create;
end;

destructor TCajaParams.Destroy;
begin
  FParams.Free;
  inherited;
end;

// Centralizamos todos los valores por defecto de la aplicación aquí
procedure TCajaParams.CargarValoresPorDefecto;
begin
  FParams.Clear;

  // --- Booleans (guardamos como string 'False' o 'True') ---
  FParams.Add('vgerChkExistOnly', 'True');
  FParams.Add('vgerChkStockOnly', 'False');
  FParams.Add('vgerShowCajaSelection', 'False');
  FParams.Add('vgerFillEmpleadoDefecto', 'False');
  FParams.Add('vgerReqRefDevolucion', 'False');
  FParams.Add('vgerRecuperaValePIN', 'False');
  FParams.Add('vgerCaducidadDefVale', 'False');
  FParams.Add('vgerBusqArtStockOnly', 'False');
  FParams.Add('vgerBusqArtTarifaOnly', 'False');
  FParams.Add('vgerMoverLineaIdentif', 'False');
  FParams.Add('vgerShowEmpleadoLinea', 'True');
  FParams.Add('vgerArqueoTarjetas', 'False');
  FParams.Add('vgerVentasCredito', 'True');
  FParams.Add('vgerDescuentos', 'True');

  // --- Integers ---
  FParams.Add('vgerMaxOpPending', '5');
  FParams.Add('vgerDiasCaducidadVale', '365');

  // --- Strings ---
  FParams.Add('vgerAvisoStockWarning', 'Artículo sin stock. Compruebe stock en almacén.');
  FParams.Add('vgerDefTarifa', 'PVP');
  FParams.Add('vgerDefPrinter', '');
  FParams.Add('vgerTipoImpresion', 'ESC POS'); // Valor por defecto del combo
  FParams.Add('vgerFormatoImpPredet', '');
  FParams.Add('vgerCodEmpleadoDefecto', '');
end;

procedure TCajaParams.CargarDesdeDB(const pUsuario, pGrupo: string);
var
  qry: TUniQuery;
begin
  // 1. Llenamos el diccionario con los valores seguros por defecto
  CargarValoresPorDefecto;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   := 'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;

    // 2. Sobrescribimos los valores por defecto con los que tenga el usuario en la BD
    while not qry.Eof do
    begin
      FParams.AddOrSetValue(
        qry.FieldByName('SUBKEY_PERFILES').AsString,
        qry.FieldByName('VALUE_PERFILES').AsString
      );
      qry.Next;
    end;
  finally
    qry.Free;
  end;
end;

procedure TCajaParams.Inicializar(const pUsuario, pGrupo: string);
begin
  CargarDesdeDB(pUsuario, pGrupo);
end;

procedure TCajaParams.Recargar(const pUsuario, pGrupo: string);
begin
  CargarDesdeDB(pUsuario, pGrupo);
end;

function TCajaParams.GetString(const Key: string; const Default: string): string;
begin
  // Si la clave no está (ej. un parámetro nuevo que olvidaste poner en CargarValoresPorDefecto), usa el Default del método
  if not FParams.TryGetValue(Key, Result) then
    Result := Default;
end;

function TCajaParams.GetBool(const Key: string; const Default: Boolean): Boolean;
var
  sVal: string;
begin
  if FParams.TryGetValue(Key, sVal) then
    Result := SameText(sVal, 'True') or (sVal = '1')
  else
    Result := Default;
end;

function TCajaParams.GetInt(const Key: string; const Default: Integer): Integer;
var
  sVal: string;
begin
  if FParams.TryGetValue(Key, sVal) then
  begin
    if not TryStrToInt(sVal, Result) then
      Result := Default;
  end
  else
    Result := Default;
end;

initialization
  oCajaParams := TCajaParams.Create;

finalization
  FreeAndNil(oCajaParams);

end.
