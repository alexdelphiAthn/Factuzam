unit inLibCajaParam;

interface

uses
  System.Generics.Collections, System.SysUtils, Uni;

type
  TCajaParams = class
  private
    FParams: TDictionary<string, string>;
    procedure CargarDesdeDB(const pUsuario, pGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Inicializar(const pUsuario, pGrupo: string);
    procedure Recargar(const pUsuario, pGrupo: string);

    // Acceso tipado a cada parámetro
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

procedure TCajaParams.CargarDesdeDB(const pUsuario, pGrupo: string);
var
  qry: TUniQuery;
begin
  FParams.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   := 'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;
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
