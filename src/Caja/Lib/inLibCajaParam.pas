{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaParam                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de configuración del punto de venta.                           }
{    Definición, carga desde BBDD y acceso tipado a opciones de caja.          }
{******************************************************************************}
unit inLibCajaParam;

interface

uses
  System.Generics.Collections, System.SysUtils, Uni;

type
  // Enumerado para definir el tipo de dato del parámetro
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  // Clase que contiene la definición, metadatos y valor actual de cada
  // parámetro
  TParamDef = class
  public
    Categoria: string;
    Nombre: string;
    Descripcion: string;
    Tipo: TTipoParametro;
    ValorPorDefecto: string;
    ValorActual: string;

    constructor Create(const ACategoria,
                       ANombre,
                       ADesc: string;
                       ATipo: TTipoParametro;
                       const ADefecto: string);
  end;

  TCajaParams = class
  private
    FParams: TObjectDictionary<string, TParamDef>;
    procedure CargarDesdeDB(const AUsuario, AGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    // --- INTERFAZ PARA REGISTRAR PARÁMETROS (Actualizada con Categoría) ---
    procedure RegistrarParametro(const ACategoria,
                                 ANombre,
                                 ADesc: string;
                                 ATipo: TTipoParametro;
                                 const ADefecto: string);
    procedure RegistrarDefectos;
    procedure InicializarParametrosCaja(const AUsuario, AGrupo: string);
    procedure Inicializar(const AUsuario, AGrupo: string);
    procedure Recargar(const AUsuario, AGrupo: string);

    // Acceso tipado
    function GetString (const AKey: string; const ADefault: string = '' ): string;
    function GetBool   (const AKey: string;
                        const ADefault: Boolean = False): Boolean;
    function GetInt (const AKey: string; const ADefault: Integer = 0 ): Integer;

    property Params: TObjectDictionary<string, TParamDef> read FParams;
  end;

var
  oCajaParams: TCajaParams;

implementation

uses
  System.StrUtils, inLibGlobalVar; // Asumo que aquí tienes oConn

{ TParamDef }

constructor TParamDef.Create(const ACategoria,
                             ANombre,
                             ADesc: string;
                             ATipo: TTipoParametro;
                             const ADefecto: string);
begin
  Categoria := ACategoria;
  Nombre := ANombre;
  Descripcion := ADesc;
  Tipo := ATipo;
  ValorPorDefecto := ADefecto;
  ValorActual := ADefecto;
end;

{ TCajaParams }

constructor TCajaParams.Create;
begin
  inherited;
  FParams := TObjectDictionary<string, TParamDef>.Create([doOwnsValues]);
end;

destructor TCajaParams.Destroy;
begin
  FreeAndNil(FParams);
  inherited;
end;

procedure TCajaParams.RegistrarParametro(const ACategoria,
                                         ANombre,
                                         ADesc: string;
                                         ATipo: TTipoParametro;
                                         const ADefecto: string);
begin
  FParams.AddOrSetValue(ANombre,
    TParamDef.Create(ACategoria, ANombre, ADesc, ATipo, ADefecto));
end;

procedure TCajaParams.RegistrarDefectos;
var
  Param: TParamDef;
begin
  for Param in FParams.Values do
    Param.ValorActual := Param.ValorPorDefecto;
end;

procedure TCajaParams.CargarDesdeDB(const AUsuario, AGrupo: string);
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
    qry.SQL.Text   :=
      'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := AUsuario;
    qry.ParamByName('p_grupo').AsString      := AGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;
    // 2. Sobrescribimos los valores por defecto con los que tenga el usuario
    while not qry.Eof do
    begin
      KeyDB := qry.FieldByName('SUBKEY_USUPER').AsString;
      ValueDB := qry.FieldByName('VALUE_USUPER').AsString;
      // Las claves de geometría/layout (WindowState, Left, Top, Width,
      // Height, Divider) se persisten bajo el mismo KEY_USUPER que los
      // parámetros (véase inLibLayoutForm.TLayoutSaver). No son parámetros
      // configurables: las saltamos para que no aparezcan como huérfanas.
      if not MatchText(KeyDB, ['WindowState', 'Left', 'Top', 'Width',
                               'Height', 'Divider']) then
      begin
        if FParams.TryGetValue(KeyDB, ParamObj) then
        begin
          ParamObj.ValorActual := ValueDB;
        end
        else
        begin
          // Si hay un parámetro huérfano en la BD que no hemos registrado,
          // lo metemos en una categoría genérica para que siga viéndose.
          RegistrarParametro('Otros (Heredados de BD)',
                             KeyDB,
                             'Parámetro sin descripción',
                             tpString,
                             ValueDB);
          FParams.Items[KeyDB].ValorActual := ValueDB;
        end;
      end;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TCajaParams.Inicializar(const AUsuario, AGrupo: string);
begin
  CargarDesdeDB(AUsuario, AGrupo);
end;

procedure TCajaParams.InicializarParametrosCaja(const AUsuario, AGrupo: string);
begin
  // --- Control de Artículos ---
  RegistrarParametro('Control de Artículos',
                     'vgerChkExistOnly',
                     'Permitir sólo artículos que existan',
                     tpBoolean,
                     'True');
  RegistrarParametro('Control de Artículos',
                     'vgerChkStockOnly',
                     'Permitir sólo artículos con stock',
                     tpBoolean,
                     'False');

  // --- Configuración de Caja ---
  RegistrarParametro('Configuración de Caja',
                     'vgerShowCajaSelection',
                     'Presentar selección de caja',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerFillEmpleadoDefecto',
                     'Rellenar empleado por defecto al abrir',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerDefTarifa',
                     'Tarifa por defecto en caja',
                     tpString,
                     'PVP');
  RegistrarParametro('Configuración de Caja',
                     'vgerMaxOpPending',
                     'Número de operaciones pendientes',
                     tpInteger,
                     '5');
  RegistrarParametro('Configuración de Caja',
                     'vgerAutoLoadDepositos',
                     'Cargar depósitos automáticamente al seleccionar cliente',
                     tpBoolean,
                     'False');

  // --- Devoluciones y Vales ---
  RegistrarParametro('Devoluciones y Vales',
                     'vgerReqRefDevolucion',
                     'Pedir referencia en devoluciones',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerRecuperaValePIN',
                     'Recuperar Vale sólo con PIN',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerCaducidadDefVale',
                     'Caducidad por defecto en vale',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerDiasCaducidadVale',
                     'Días hasta caducidad en vale',
                     tpInteger,
                     '365');


  // --- Avisos y Búsquedas ---
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoStockWarning',
                     'Aviso en artículos sin stock',
                     tpString,
                     'Artículo sin stock. Compruebe stock en almacén.');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtStockOnly',
                     'Búsqueda de artículos sólo con stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtTarifaOnly',
                     'Búsqueda de artículos sólo con tarifa',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerMoverLineaIdentif',
                     'Mover linea al identificar artículo',
                     tpBoolean,
                     'False');

  // --- Lector de Código de Barras ---
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelActivo',
                     'Detectar lecturas por velocidad de tecleo (código + CR)',
                     tpBoolean,
                     'True');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelMs',
                     'Máx. ms entre teclas para considerarlo lectura',
                     tpInteger,
                     '40');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanMinLong',
                     'Longitud mínima del código para aceptar la lectura',
                     tpInteger,
                     '4');

  // --- Impresión ---
  RegistrarParametro('Impresión',
                     'vgerDefPrinter',
                     'Nombre impresora de tickets',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     'vgerTipoImpresion',
                     'Tipo de Impresión tickets',
                     tpString,
                     'ESC POS');
  RegistrarParametro('Impresión',
                     'vgerFormatoImpPredet',
                     'Formato de impresión predeterminado',
                     tpString,
                     '');

  // --- Empleado ---
  RegistrarParametro('Empleado',
                     'vgerCodEmpleadoDefecto',
                     'Código de empleado por defecto',
                     tpString,
                     '');
  RegistrarParametro('Empleado',
                     'vgerShowEmpleadoLinea',
                     'Mostrar empleado en linea de caja',
                     tpBoolean,
                     'True');

  // --- Permisos Extra ---
  RegistrarParametro('Permisos Extra',
                     'vgerArqueoTarjetas',
                     'Permitir Arqueo de Tarjetas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Permisos Extra',
                     'vgerVentasCredito',
                     'Permitir Ventas a Crédito',
                     tpBoolean,
                     'True');
  RegistrarParametro('Permisos Extra',
                     'vgerDescuentos',
                     'Permite descuentos en ventas',
                     tpBoolean,
                     'True');

  // ----------------------------------------------------------------------------------
  // Una vez registrada toda la estructura en memoria, le decimos a la librería
  // que se conecte a la base de datos y cargue los valores reales del usuario.
  // ----------------------------------------------------------------------------------
  Inicializar(AUsuario, AGrupo);
end;

procedure TCajaParams.Recargar(const AUsuario, AGrupo: string);
begin
  CargarDesdeDB(AUsuario, AGrupo);
end;

// --- Getters ---
function TCajaParams.GetString(const AKey: string;
                               const ADefault: string): string;
var
  ParamObj: TParamDef;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
    Result := ParamObj.ValorActual
  else
    Result := ADefault;
end;

function TCajaParams.GetBool(const AKey: string;
                             const ADefault: Boolean): Boolean;
var
  ParamObj: TParamDef;
  sVal: string;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
  begin
    sVal := ParamObj.ValorActual;
    Result := SameText(sVal, 'True') or (sVal = '1');
  end
  else
    Result := ADefault;
end;

function TCajaParams.GetInt(const AKey: string; const ADefault: Integer): Integer;
var
  ParamObj: TParamDef;
begin
  if FParams.TryGetValue(AKey, ParamObj) then
  begin
    if not TryStrToInt(ParamObj.ValorActual, Result) then
      Result := ADefault;
  end
  else
    Result := ADefault;
end;

initialization
  oCajaParams := TCajaParams.Create;

finalization
  FreeAndNil(oCajaParams);

end.
