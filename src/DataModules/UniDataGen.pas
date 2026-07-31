{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGen                                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module base de los mantenimientos (TdmBase).                         }
{    Provee unqryTablaG y servicios comunes (perfiles, GetOwnerForm) que       }
{    heredan los Mtos.                                                         }
{******************************************************************************}
unit UniDataGen;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, inLibWin, inLibLog, inLibAnfitrionDatosIntf,
  inLibAuditoriaDatosIntf, inLibConexionesIntf, inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf, inLibParametrosIntf;

type
  TdmBase = class(
    TDataModule,
    IAnfitrionDatosDocumento,
    IProveedorAuditoriaDatos,
    IProveedorConexiones,
    IProveedorContextoSesion,
    IProveedorPerfilesUsuario,
    IProveedorParametros
  )
    unqryTablaG: TUniQuery;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
  private
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FPerfilesLectura: ILectorPerfilesUsuario;
    FPerfilesEscritura: IEscritorPerfilesUsuario;
    FCachePerfiles: ICachePerfilesUsuario;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FOnActivarFicha: TNotifyEvent;
    function GetCurrentForm: TComponent;
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    function GetConexiones: IServicioConexiones;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    function GetUbicacionSesion: TUbicacionSesion;
    function GetPerfilesLectura: ILectorPerfilesUsuario;
    function GetServiciosPerfilesUsuario: TServiciosPerfilesUsuario;
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    function GetConexionPrincipal: TUniConnection;
    procedure SetCurrentForm(const Value: TComponent);
    procedure HeredarAuditoriaDatos(AOwner: TComponent);
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
    procedure HeredarPerfilesUsuario(AOwner: TComponent);
    procedure HeredarParametros(AOwner: TComponent);
  protected
    // DataSource de la cabecera (dsTablaG del Mto), empujado por el
    // form via AsignarMaestroCabecera.
    FMaestroCabecera: TDataSource;
    procedure DoCreate; reintroduce; virtual;
    function GetOwnerForm<T: TComponent>: T;
    function HasOwnerForm: Boolean;
    procedure ActualizarAuditoria(DataSet: TDataSet);
  public
    constructor Create(AOwner: TComponent); override;
    property CurrentForm: TComponent read GetCurrentForm write SetCurrentForm;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
    property Conexiones: IServicioConexiones read GetConexiones;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
    property IdentidadSesion: TIdentidadSesion
      read GetIdentidadSesion;
    property UbicacionSesion: TUbicacionSesion
      read GetUbicacionSesion;
    property PerfilesLectura: ILectorPerfilesUsuario
      read GetPerfilesLectura;
    property ParametrosApp: IParametrosAplicacion read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja read GetParametrosCaja;
    property ConexionPrincipal: TUniConnection
      read GetConexionPrincipal;
    procedure AsignarAuditoriaDatos(
      const AAuditoriaDatos: IServicioAuditoriaDatos);
    procedure AsignarConexiones(
      const AConexiones: IServicioConexiones);
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure AsignarPerfilesUsuario(
      const AServicios: TServiciosPerfilesUsuario);
    procedure AsignarParametros(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja);
    // El form empuja el DataSource de su cabecera (dsTablaG); el DM ya
    // no sube a buscarlo con GetOwnerForm. Cada TdmXxx sobreescribe
    // para cablear los MasterSource de sus detalles.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); virtual;
    // Tabla principal del documento, expuesta por el contrato
    // IAnfitrionDatosDocumento para que inLib* cablee sin conocer
    // TdmBase.
    function ObtenerTablaPrincipal: TDataSet;
    // Aviso al insertar en la tabla principal: el form suscrito activa
    // su pestania de ficha (antes el DM tocaba pcPantalla del form).
    property OnActivarFicha: TNotifyEvent
      read FOnActivarFicha write FOnActivarFicha;
    function CrearConexionTrabajo(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure ResetGridsProfile(sGrid, sForm, sPermisos:String);
    // Reasigna la conexion (TUniConnection) de todos los datasets/SQL del
    // data module a `NewConn`. Lo usa TfrmMtoGen tras crear el data module
    // para que cada pestaña use una conexion propia del pool en lugar de
    // la conexion principal compartida (asi dos tabs no se serializan).
    procedure ReasignarConexion(NewConn: TUniConnection);
    // Corta consultas/procedimientos UniDAC en curso antes de destruir el
    // mantenimiento. Se llama desde el hilo principal mientras la tarea BBDD
    // corre en background.
    procedure CancelarEjecucionActiva;
    // Abre las queries detalle/lookup propias del Mto. Default no hace
    // nada; cada TdmXxx override para listar sus queries en el orden
    // adecuado. Lo invoca TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del
    // thread tras abrir unqryTablaG, asi todas las queries se abren en
    // background mientras la UI muestra el overlay y otros tabs siguen
    // interactivos. Antes esto ocurria sincrono en DataModuleCreate (y
    // congelaba la UI 21s en Articulos).
    procedure AbrirDetalles; virtual;
    // Reactiva los TDataSource y dispara cualquier AfterScroll que se
    // hubiera suprimido durante AbrirDetalles. Se invoca en MAIN thread
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync. Cada Mto override para
    // recorrer sus DataSource concretos.
    procedure ReactivarControlesTrasAbrir; virtual;
  public
    FCurrentForm: TComponent;
    FoPerfilDic: TProfileDicc;
  end;

  // Referencia de clase del data module de documento; los formularios
  // la pasan a AsegurarDataModuleDocumento (movida desde
  // inLibColumnasDocumento en la Fase 2b).
  TClaseDataModuleDocumento = class of TdmBase;

// Reutiliza o crea el data module del documento validando su clase.
function AsegurarDataModuleDocumento(
  APropietario: TComponent; var ADataModule: TObject;
  AClaseDataModule: TClaseDataModuleDocumento): TdmBase;

//var
//  dmBase: TdmBase;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  Vcl.Forms, inLibData, inLibMsgComun;

{$R *.dfm}

constructor TdmBase.Create(AOwner: TComponent);
begin
  HeredarAuditoriaDatos(AOwner);
  HeredarConexiones(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarPerfilesUsuario(AOwner);
  HeredarParametros(AOwner);
  inherited Create(AOwner);
end;

procedure TdmBase.HeredarAuditoriaDatos(AOwner: TComponent);
var
  Proveedor: IProveedorAuditoriaDatos;
begin
  FAuditoriaDatos := nil;
  if Supports(AOwner, IProveedorAuditoriaDatos, Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
  if not Assigned(FAuditoriaDatos) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorAuditoriaDatos,
       Proveedor) then
    FAuditoriaDatos := Proveedor.AuditoriaDatos;
end;

procedure TdmBase.HeredarConexiones(AOwner: TComponent);
var
  Proveedor: IProveedorConexiones;
begin
  FConexiones := nil;
  if Supports(AOwner, IProveedorConexiones, Proveedor) then
    FConexiones := Proveedor.Conexiones;
  if not Assigned(FConexiones) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorConexiones,
       Proveedor) then
    FConexiones := Proveedor.Conexiones;
end;

procedure TdmBase.HeredarContextoSesion(AOwner: TComponent);
var
  Proveedor: IProveedorContextoSesion;
begin
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
  if not Assigned(FContextoSesion) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorContextoSesion,
       Proveedor) then
    FContextoSesion := Proveedor.ContextoSesion;
end;

procedure TdmBase.HeredarPerfilesUsuario(AOwner: TComponent);
var
  Proveedor: IProveedorPerfilesUsuario;
  Servicios: TServiciosPerfilesUsuario;
begin
  FPerfilesLectura := nil;
  FPerfilesEscritura := nil;
  FCachePerfiles := nil;
  if Supports(AOwner, IProveedorPerfilesUsuario, Proveedor) then
  begin
    Servicios := Proveedor.ServiciosPerfilesUsuario;
    FPerfilesLectura := Servicios.Lectura;
    FPerfilesEscritura := Servicios.Escritura;
    FCachePerfiles := Servicios.Cache;
  end;
  if not Assigned(FPerfilesLectura) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorPerfilesUsuario,
       Proveedor) then
  begin
    Servicios := Proveedor.ServiciosPerfilesUsuario;
    FPerfilesLectura := Servicios.Lectura;
    FPerfilesEscritura := Servicios.Escritura;
    FCachePerfiles := Servicios.Cache;
  end;
end;

procedure TdmBase.HeredarParametros(AOwner: TComponent);
var
  Proveedor: IProveedorParametros;
begin
  FParametrosApp := nil;
  FParametrosCaja := nil;
  if Supports(AOwner, IProveedorParametros, Proveedor) then
  begin
    FParametrosApp := Proveedor.ParametrosApp;
    FParametrosCaja := Proveedor.ParametrosCaja;
  end;
  if (not Assigned(FParametrosApp) or
      not Assigned(FParametrosCaja)) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorParametros,
       Proveedor) then
  begin
    FParametrosApp := Proveedor.ParametrosApp;
    FParametrosCaja := Proveedor.ParametrosCaja;
  end;
end;

procedure TdmBase.AsignarAuditoriaDatos(
  const AAuditoriaDatos: IServicioAuditoriaDatos);
begin
  FAuditoriaDatos := AAuditoriaDatos;
end;

function TdmBase.GetAuditoriaDatos: IServicioAuditoriaDatos;
begin
  Result := FAuditoriaDatos;
end;

procedure TdmBase.AsignarConexiones(
  const AConexiones: IServicioConexiones);
begin
  FConexiones := AConexiones;
end;

function TdmBase.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

procedure TdmBase.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TdmBase.AsignarPerfilesUsuario(
  const AServicios: TServiciosPerfilesUsuario);
begin
  FPerfilesLectura := AServicios.Lectura;
  FPerfilesEscritura := AServicios.Escritura;
  FCachePerfiles := AServicios.Cache;
end;

procedure TdmBase.AsignarParametros(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja);
begin
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
end;

function TdmBase.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TdmBase.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionModuloDatosNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function TdmBase.GetUbicacionSesion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionModuloDatosNoConfigurado);
  Result := FContextoSesion.Ubicacion;
end;

function TdmBase.GetPerfilesLectura: ILectorPerfilesUsuario;
begin
  Result := FPerfilesLectura;
end;

function TdmBase.GetServiciosPerfilesUsuario:
  TServiciosPerfilesUsuario;
begin
  Result := CrearServiciosPerfilesUsuario(
    FPerfilesLectura,
    FPerfilesEscritura,
    FCachePerfiles);
end;

function TdmBase.GetParametrosApp: IParametrosAplicacion;
begin
  Result := FParametrosApp;
end;

function TdmBase.GetParametrosCaja: IParametrosCaja;
begin
  Result := FParametrosCaja;
end;

function TdmBase.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
  if not Assigned(Result) and
     not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
end;

function TdmBase.CrearConexionTrabajo(
  AOwner: TComponent;
  AUso: TUsoConexionTrabajo): TUniConnection;
begin
  if not Assigned(FConexiones) then
    raise Exception.Create(SErrorServicioConexionesDatosNoConfigurado);
  Result := FConexiones.CrearConexion(AOwner, AUso);
end;

procedure TdmBase.ActualizarAuditoria(DataSet: TDataSet);
begin
  if Assigned(FAuditoriaDatos) then
    FAuditoriaDatos.Actualizar(DataSet)
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioAuditoriaDatosNoConfigurado);
end;

procedure TdmBase.DoCreate;
var
  Conexion: TUniConnection;
begin
  FoPerfilDic := nil;
  Conexion := ConexionPrincipal;
  if Assigned(Conexion) then
  begin
    unqryTablaG.Connection := Conexion;
    unqryPerfiles.Connection := Conexion;
  end;
end;

procedure TdmBase.DataModuleCreate(Sender: TObject);
begin
  DoCreate;
end;

procedure TdmBase.DataModuleDestroy(Sender: TObject);
begin
  unqryTablaG.Close;
  unqryPerfiles.Close;
  if (FoPerfilDic <> nil) then
    FreeAndNil(FoPerfilDic);
//  oPerfilDic.Free;
end;

function TdmBase.GetCurrentForm: TComponent;
begin
  Result := FCurrentForm;
end;

procedure TdmBase.SetCurrentForm(const Value: TComponent);
begin
  FCurrentForm := Value;
end;

function TdmBase.GetOwnerForm<T>: T;
begin
  Result := nil;
  if Assigned(FCurrentForm) and (FCurrentForm is T) then
    Result := T(FCurrentForm)
  else if (Self.Owner <> nil) and (Self.Owner is T) then
    Result := T(Self.Owner);
end;

function TdmBase.HasOwnerForm: Boolean;
begin
  Result := Assigned(FCurrentForm) and
            not (csDestroying in FCurrentForm.ComponentState);
end;

procedure TdmBase.ReasignarConexion(NewConn: TUniConnection);
var
  i: Integer;
  Comp: TComponent;
  ds: TCustomDADataSet;
  sql: TCustomDASQL;
begin
  if NewConn = nil then
    Exit;
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    // TUniQuery, TUniTable, TUniStoredProc heredan de TCustomDADataSet.
    if Comp is TCustomDADataSet then
    begin
      ds := TCustomDADataSet(Comp);
      // Si el dataset YA esta activo, lo dejamos en paz. Muchos data
      // modules (Empresas, Clientes, Atributos...) abren lookups contra la
      // conexion principal en DataModuleCreate; cerrarlos para reasignar
      // los dejaria vacios y obligaria a re-fetchearlos. Solo redirigimos
      // los datasets que aun no se han abierto — esos son los que nos
      // interesa que vayan contra FConn (unqryTablaG, SPs como
      // unspAplicar, queries on-demand que se abran mas tarde).
      if not ds.Active then
        ds.Connection := NewConn;
    end
    // TUniSQL, TUniScript heredan de TCustomDASQL. No tienen estado de
    // "activo" — solo guardan SQL pendiente — asi que reasignar es seguro.
    else if Comp is TCustomDASQL then
    begin
      sql := TCustomDASQL(Comp);
      sql.Connection := NewConn;
    end;
  end;
end;

procedure TdmBase.AbrirDetalles;
begin
  // Default: nada. Los Mtos con queries detalle/lookup override este metodo.
end;

procedure TdmBase.ReactivarControlesTrasAbrir;
begin
  // Default: nada.
end;

procedure TdmBase.CancelarEjecucionActiva;
var
  i: Integer;
  Comp: TComponent;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    try
      if Comp is TUniQuery then
        TUniQuery(Comp).BreakExec
      else if Comp is TUniStoredProc then
        TUniStoredProc(Comp).BreakExec;
    except
      on E: Exception do
        inLibLog.Log.LogError('No se pudo cancelar ' + Comp.Name + ': ' +
                              E.Message);
    end;
  end;
end;

procedure TdmBase.ResetGridsProfile(sGrid, sForm, sPermisos: String);
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := ConexionPrincipal;
  unqrySol.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                       '      WHERE USUARIO_GRUPO_USUPER = :user ' +
                       '        AND KEY_USUPER = :form ';
//                       '        AND SUBKEY_USUPER LIKE ' +
//                                                      QuotedSTr(sGrid + '_%');
  unqrysol.ParamByName('user').AsString := sPermisos;
  unqrysol.ParamByName('form').AsString := sForm;
  unqrySol.Execute;
  FreeAndNil(unqrySol);
end;

procedure TdmBase.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  ActualizarAuditoria(DataSet);
  if (Log() <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforePost',
                  'state=' + GetEnumName(TypeInfo(TDataSetState),
                                          Ord(DataSet.State)));
end;

// Guarda el maestro empujado por el form; los TdmXxx sobreescriben y
// cablean aqui los MasterSource de sus queries de detalle.
procedure TdmBase.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  FMaestroCabecera := ADataSource;
end;

procedure TdmBase.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  // El DM ya no toca la UI: avisa y el form activa su pestania Ficha.
  if Assigned(FOnActivarFicha) then
    FOnActivarFicha(Self);
  if (Log() <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforeInsert', '');
end;

procedure TdmBase.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  AjustarEmpresasAlmacenesDocumento(unqryTablaG.Connection, DataSet);
  ActualizarAuditoria(DataSet);
  if (Log() <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforePost',
                  'state=' + GetEnumName(TypeInfo(TDataSetState),
                                          Ord(DataSet.State)));
end;

function TdmBase.ObtenerTablaPrincipal: TDataSet;
begin
  Result := unqryTablaG;
end;

function AsegurarDataModuleDocumento(
  APropietario: TComponent; var ADataModule: TObject;
  AClaseDataModule: TClaseDataModuleDocumento): TdmBase;
begin
  if not Assigned(AClaseDataModule) then
    raise EArgumentNilException.Create(
      'No se ha indicado la clase del data module.');
  if Assigned(ADataModule) then
  begin
    if ADataModule.ClassType.InheritsFrom(AClaseDataModule) then
      Result := TdmBase(ADataModule)
    else
      raise EInvalidCast.CreateFmt(
        'El data module %s no es de la clase %s.',
        [ADataModule.ClassName, AClaseDataModule.ClassName]);
  end
  else
  begin
    Result := AClaseDataModule.Create(APropietario);
    ADataModule := Result;
  end;
end;

end.
