unit inLibCajaParam;

interface

uses
  System.Generics.Collections, System.SysUtils, Uni;

type
  // Enumerado para definir el tipo de dato del parámetro
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  // Clase que contiene la definición, metadatos y valor actual de cada parámetro
  TParamDef = class
  public
    Categoria: string;
    Nombre: string;
    Descripcion: string;
    Tipo: TTipoParametro;
    ValorPorDefecto: string;
    ValorActual: string;

    constructor Create(const aCategoria, aNombre, aDesc: string; aTipo: TTipoParametro; const aDefecto: string);
  end;

  TCajaParams = class
  private
    FParams: TObjectDictionary<string, TParamDef>;
    procedure CargarDesdeDB(const pUsuario, pGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    // --- INTERFAZ PARA REGISTRAR PARÁMETROS (Actualizada con Categoría) ---
    procedure RegistrarParametro(const pCategoria, pNombre, pDesc: string; pTipo: TTipoParametro; const pDefecto: string);
    procedure RegistrarDefectos;
    procedure InicializarParametrosCaja(const pUsuario, pGrupo: string);
    procedure Inicializar(const pUsuario, pGrupo: string);
    procedure Recargar(const pUsuario, pGrupo: string);

    // Acceso tipado
    function GetString (const Key: string; const Default: string  = ''   ): string;
    function GetBool   (const Key: string; const Default: Boolean = False): Boolean;
    function GetInt    (const Key: string; const Default: Integer = 0    ): Integer;

    property Params: TObjectDictionary<string, TParamDef> read FParams;
  end;

var
  oCajaParams: TCajaParams;

implementation

uses
  inLibGlobalVar; // Asumo que aquí tienes oConn

{ TParamDef }

constructor TParamDef.Create(const aCategoria, aNombre, aDesc: string; aTipo: TTipoParametro; const aDefecto: string);
begin
  Categoria := aCategoria;
  Nombre := aNombre;
  Descripcion := aDesc;
  Tipo := aTipo;
  ValorPorDefecto := aDefecto;
  ValorActual := aDefecto;
end;

{ TCajaParams }

constructor TCajaParams.Create;
begin
  inherited;
  FParams := TObjectDictionary<string, TParamDef>.Create([doOwnsValues]);
end;

destructor TCajaParams.Destroy;
begin
  FParams.Free;
  inherited;
end;

procedure TCajaParams.RegistrarParametro(const pCategoria, pNombre, pDesc: string; pTipo: TTipoParametro; const pDefecto: string);
begin
  FParams.AddOrSetValue(pNombre, TParamDef.Create(pCategoria, pNombre, pDesc, pTipo, pDefecto));
end;

procedure TCajaParams.RegistrarDefectos;
var
  Param: TParamDef;
begin
  for Param in FParams.Values do
    Param.ValorActual := Param.ValorPorDefecto;
end;

procedure TCajaParams.CargarDesdeDB(const pUsuario, pGrupo: string);
var
  qry: TUniQuery;
  KeyDB, ValueDB: string;
  ParamObj: TParamDef;
begin
  // 1. Aseguramos que la base sea la de por defecto antes de sobreescribir
  RegistrarDefectos;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   := 'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;
    // 2. Sobrescribimos los valores por defecto con los que tenga el usuario
    while not qry.Eof do
    begin
      KeyDB := qry.FieldByName('SUBKEY_PERFILES').AsString;
      ValueDB := qry.FieldByName('VALUE_PERFILES').AsString;
      if FParams.TryGetValue(KeyDB, ParamObj) then
      begin
        ParamObj.ValorActual := ValueDB;
      end
      else
      begin
        // Si hay un parámetro huérfano en la BD que no hemos registrado,
        // lo metemos en una categoría genérica para que siga viéndose.
        RegistrarParametro('Otros (Heredados de BD)', KeyDB, 'Parámetro sin descripción', tpString, ValueDB);
        FParams.Items[KeyDB].ValorActual := ValueDB;
      end;
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

procedure TCajaParams.InicializarParametrosCaja(const pUsuario, pGrupo: string);
begin
  // --- Control de Artículos ---
  RegistrarParametro('Control de Artículos', 'vgerChkExistOnly', 'Permitir sólo artículos que existan', tpBoolean, 'True');
  RegistrarParametro('Control de Artículos', 'vgerChkStockOnly', 'Permitir vender sin stock', tpBoolean, 'False');

  // --- Configuración de Caja ---
  RegistrarParametro('Configuración de Caja', 'vgerShowCajaSelection', 'Presentar selección de caja', tpBoolean, 'False');
  RegistrarParametro('Configuración de Caja', 'vgerFillEmpleadoDefecto', 'Rellenar empleado por defecto al abrir', tpBoolean, 'False');
  RegistrarParametro('Configuración de Caja', 'vgerDefTarifa', 'Tarifa por defecto en caja', tpString, 'PVP');
  RegistrarParametro('Configuración de Caja', 'vgerMaxOpPending', 'Número de operaciones pendientes', tpInteger, '5');
  RegistrarParametro('Configuración de Caja', 'vgerAutoLoadDepositos', 'Cargar depósitos automáticamente al seleccionar cliente', tpBoolean, 'False');

  // --- Devoluciones y Vales ---
  RegistrarParametro('Devoluciones y Vales', 'vgerReqRefDevolucion', 'Pedir referencia en devoluciones', tpBoolean, 'False');
  RegistrarParametro('Devoluciones y Vales', 'vgerRecuperaValePIN', 'Recuperar Vale sólo con PIN', tpBoolean, 'False');
  RegistrarParametro('Devoluciones y Vales', 'vgerCaducidadDefVale', 'Caducidad por defecto en vale', tpBoolean, 'False');
  RegistrarParametro('Devoluciones y Vales', 'vgerDiasCaducidadVale', 'Días hasta caducidad en vale', tpInteger, '365');


  // --- Avisos y Búsquedas ---
  RegistrarParametro('Avisos y Búsquedas', 'vgerAvisoStockWarning', 'Aviso en artículos sin stock', tpString, 'Artículo sin stock. Compruebe stock en almacén.');
  RegistrarParametro('Avisos y Búsquedas', 'vgerBusqArtStockOnly', 'Búsqueda de artículos sólo con stock', tpBoolean, 'False');
  RegistrarParametro('Avisos y Búsquedas', 'vgerBusqArtTarifaOnly', 'Búsqueda de artículos sólo con tarifa', tpBoolean, 'False');
  RegistrarParametro('Avisos y Búsquedas', 'vgerMoverLineaIdentif', 'Mover linea al identificar artículo', tpBoolean, 'False');

  // --- Impresión ---
  RegistrarParametro('Impresión', 'vgerDefPrinter', 'Nombre impresora de tickets', tpString, '');
  RegistrarParametro('Impresión', 'vgerTipoImpresion', 'Tipo de Impresión tickets', tpString, 'ESC POS');
  RegistrarParametro('Impresión', 'vgerFormatoImpPredet', 'Formato de impresión predeterminado', tpString, '');

  // --- Empleado ---
  RegistrarParametro('Empleado', 'vgerCodEmpleadoDefecto', 'Código de empleado por defecto', tpString, '');
  RegistrarParametro('Empleado', 'vgerShowEmpleadoLinea', 'Mostrar empleado en linea de caja', tpBoolean, 'True');

  // --- Permisos Extra ---
  RegistrarParametro('Permisos Extra', 'vgerArqueoTarjetas', 'Permitir Arqueo de Tarjetas', tpBoolean, 'False');
  RegistrarParametro('Permisos Extra', 'vgerVentasCredito', 'Permitir Ventas a Crédito', tpBoolean, 'True');
  RegistrarParametro('Permisos Extra', 'vgerDescuentos', 'Permite descuentos en ventas', tpBoolean, 'True');

  // ----------------------------------------------------------------------------------
  // Una vez registrada toda la "estructura" en memoria, le decimos a la librería
  // que se conecte a la base de datos y cargue los valores reales del usuario.
  // ----------------------------------------------------------------------------------
  Inicializar(pUsuario, pGrupo);
end;

procedure TCajaParams.Recargar(const pUsuario, pGrupo: string);
begin
  CargarDesdeDB(pUsuario, pGrupo);
end;

// --- Getters ---
function TCajaParams.GetString(const Key: string; const Default: string): string;
var
  ParamObj: TParamDef;
begin
  if FParams.TryGetValue(Key, ParamObj) then
    Result := ParamObj.ValorActual
  else
    Result := Default;
end;

function TCajaParams.GetBool(const Key: string; const Default: Boolean): Boolean;
var
  ParamObj: TParamDef;
  sVal: string;
begin
  if FParams.TryGetValue(Key, ParamObj) then
  begin
    sVal := ParamObj.ValorActual;
    Result := SameText(sVal, 'True') or (sVal = '1');
  end
  else
    Result := Default;
end;

function TCajaParams.GetInt(const Key: string; const Default: Integer): Integer;
var
  ParamObj: TParamDef;
begin
  if FParams.TryGetValue(Key, ParamObj) then
  begin
    if not TryStrToInt(ParamObj.ValorActual, Result) then
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
