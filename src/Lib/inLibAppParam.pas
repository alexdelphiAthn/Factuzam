{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAppParam                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de aplicación configurables.                                   }
{    Definición, carga desde BBDD y acceso tipado a opciones del programa.     }
{******************************************************************************}
unit inLibAppParam;

interface

uses
  System.Generics.Collections, System.SysUtils, Uni;

type
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  TAppParamDef = class
  public
    Categoria      : string;
    Nombre         : string;
    Descripcion    : string;
    Tipo           : TTipoParametro;
    ValorPorDefecto: string;
    ValorActual    : string;
    constructor Create(const aCategoria, aNombre, aDesc: string;
                       aTipo: TTipoParametro; const aDefecto: string);
  end;

  TAppParams = class
  private
    FParams: TObjectDictionary<string, TAppParamDef>;
    procedure CargarDesdeDB(const pUsuario, pGrupo: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegistrarParametro(const pCategoria, pNombre, pDesc: string;
                                 pTipo: TTipoParametro; const pDefecto: string);
    procedure RegistrarDefectos;
    procedure InicializarParametrosApp(const pUsuario, pGrupo: string);
    procedure Inicializar(const pUsuario, pGrupo: string);
    procedure Recargar(const pUsuario, pGrupo: string);
    function GetPath(const Nombre: string): string;
    function GetString(const Key: string; const Default: string = '' ): string;
    function GetBool  (const Key: string;
                       const Default: Boolean  = False): Boolean;
    function GetInt (const Key: string; const Default: Integer = 0 ): Integer;

    property Params: TObjectDictionary<string, TAppParamDef> read FParams;
  end;

var
  oAppParams: TAppParams;

implementation

uses
  inLibGlobalVar, inLibPathTokens;

{ TAppParamDef }

constructor TAppParamDef.Create(const aCategoria, aNombre, aDesc: string;
                                aTipo: TTipoParametro; const aDefecto: string);
begin
  Categoria       := aCategoria;
  Nombre          := aNombre;
  Descripcion     := aDesc;
  Tipo            := aTipo;
  ValorPorDefecto := aDefecto;
  ValorActual     := aDefecto;
end;

{ TAppParams }

constructor TAppParams.Create;
begin
  inherited;
  FParams := TObjectDictionary<string, TAppParamDef>.Create([doOwnsValues]);
end;

destructor TAppParams.Destroy;
begin
  FreeAndNil(FParams);
  inherited;
end;

procedure TAppParams.RegistrarParametro(const pCategoria,
                                        pNombre,
                                        pDesc: string;
                                        pTipo: TTipoParametro;
                                        const pDefecto: string);
begin
  FParams.AddOrSetValue(pNombre,
    TAppParamDef.Create(pCategoria, pNombre, pDesc, pTipo, pDefecto));
end;

procedure TAppParams.RegistrarDefectos;
var
  Param: TAppParamDef;
begin
  for Param in FParams.Values do
    Param.ValorActual := Param.ValorPorDefecto;
end;

procedure TAppParams.CargarDesdeDB(const pUsuario, pGrupo: string);
var
  qry    : TUniQuery;
  KeyDB  : string;
  ValueDB: string;
  ParamObj: TAppParamDef;
begin
  RegistrarDefectos;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   :=
      'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoAppParam';
    qry.Open;
    while not qry.Eof do
    begin
      KeyDB   := qry.FieldByName('SUBKEY_USUPER').AsString;
      ValueDB := qry.FieldByName('VALUE_USUPER').AsString;
      if FParams.TryGetValue(KeyDB, ParamObj) then
        ParamObj.ValorActual := ValueDB
      else
      begin
        // Parámetro huérfano en BD → lo registramos para que siga visible
        RegistrarParametro('Otros (Heredados de BD)', KeyDB,
                           'Parámetro sin descripción', tpString, ValueDB);
        FParams.Items[KeyDB].ValorActual := ValueDB;
      end;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TAppParams.Inicializar(const pUsuario, pGrupo: string);
begin
  CargarDesdeDB(pUsuario, pGrupo);
end;

procedure TAppParams.InicializarParametrosApp(const pUsuario, pGrupo: string);
begin
  // --- Directorios ---
  RegistrarParametro('Directorios', 'appDirPDF',
    'Carpeta donde se guardan los PDFs', tpString, '');
  RegistrarParametro('Directorios', 'appDirExcel',
    'Carpeta donde se guardan los Excels', tpString, '');
  RegistrarParametro('Directorios', 'appDirCopiasSeguridad',
    'Carpeta de Copias de seguridad', tpString, '');
  RegistrarParametro('Directorios', 'appDirHistoricoCaja',
    'Carpeta de Histórico de Caja', tpString, '');
  // --- Impresión ---
  RegistrarParametro('Impresión', 'appImpresoraInformes',
    'Impresora para informes', tpString, '');

  // --- Apariencia ---
  RegistrarParametro('Apariencia', 'appTema',
    'Tema de interfaz (DevExpress)', tpString, 'Office2019Colorful');

  Inicializar(pUsuario, pGrupo);
end;

procedure TAppParams.Recargar(const pUsuario, pGrupo: string);
begin
  CargarDesdeDB(pUsuario, pGrupo);
end;

function TAppParams.GetString(const Key: string; const Default: string): string;
var
  ParamObj: TAppParamDef;
begin
  if FParams.TryGetValue(Key, ParamObj) then
    Result := ParamObj.ValorActual
  else
    Result := Default;
end;

function TAppParams.GetBool(const Key: string; const Default: Boolean): Boolean;
var
  ParamObj: TAppParamDef;
  sVal: string;
begin
  if FParams.TryGetValue(Key, ParamObj) then
  begin
    sVal   := ParamObj.ValorActual;
    Result := SameText(sVal, 'True') or (sVal = '1');
  end
  else
    Result := Default;
end;

function TAppParams.GetInt(const Key: string; const Default: Integer): Integer;
var
  ParamObj: TAppParamDef;
begin
  if FParams.TryGetValue(Key, ParamObj) then
  begin
    if not TryStrToInt(ParamObj.ValorActual, Result) then
      Result := Default;
  end
  else
    Result := Default;
end;

function TAppParams.GetPath(const Nombre: string): string;
begin
  Result := ExpandPathTokens(GetString(Nombre));
end;

initialization
  oAppParams := TAppParams.Create;

finalization
  FreeAndNil(oAppParams);

end.