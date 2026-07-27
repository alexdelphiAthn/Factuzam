{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFrmBase                                                  }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Este formulario es el formulario base para todos los demás. Tiene la      }
{    traducción al Español de Developer Express. Sólo sirve a propósito de     }
{    herencia para generar otros formularios                                   }
{******************************************************************************}
unit inMtoFrmBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Data.DB, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxClasses, cxLocalization, cxContainer,
  cxEdit, cxLabel, cxDropDownEdit, dxSkinsCore, dxSkinsDefaultPainters,
  cxLookAndFeels, dxSkinsForm, dxSkinBlack, dxSkinBlue, dxSkinBlueprint,
  dxSkinDarkRoom, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinHighContrast, dxSkinMetropolis, dxSkinMetropolisDark,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp,
  dxSkinSharpPlus, dxSkinSpringTime, dxSkinTheAsphaltWorld, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinStardust, dxSkinSummer2008,
  dxSkinValentine, dxSkinXmas2008Blue, dxSkinscxPCPainter, dxCore, cxStyles,
  dxSkinBasic, dxSkinCaramel, dxSkinCoffee, dxSkinDarkSide, dxSkinGlassOceans,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSilver, dxSkinTheBezier, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, JvComponentBase,
  JvEnterTab, Uni, inLibPermisosIntf, inLibConexionesIntf,
  inLibAuditoriaDatosIntf, inLibMonitorSQLIntf,
  inLibContextoSesionIntf, inLibFiltrosGuardadosIntf,
  inLibPerfilesUsuarioIntf, inLibParametrosIntf,
  inLibInformesGuiasCache;

type
  TEnterAsTabEstado = record
    Componente : TJvEnterAsTab;
    EnterAsTab : Boolean;
  end;

  TfrmBase = class(
    TForm,
    IProveedorPermisosAplicacion,
    IProveedorConexiones,
    IProveedorAuditoriaDatos,
    IProveedorMonitorSQL,
    IProveedorContextoSesion,
    IProveedorFiltrosGuardados,
    IProveedorPerfilesUsuario,
    IProveedorParametros,
    IProveedorInformesGuiasCache
  )
    Localizer1: TcxLocalizer;
    jvntrstb1: TJvEnterAsTab;
    procedure FormCreate(Sender: TObject);
  private
    FPermisos: IPermisosAplicacion;
    FConexiones: IServicioConexiones;
    FAuditoriaDatos: IServicioAuditoriaDatos;
    FMonitorSQL: IServicioMonitorSQL;
    FContextoSesion: IContextoSesionAplicacion;
    FFiltrosGuardados: IFiltrosGuardados;
    FPerfilesUsuario: IPerfilesUsuario;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FInformesGuiasCache: IInformesGuiasCache;
    FEnterAsTabEstados: array of TEnterAsTabEstado;
    FEnterAsTabTemporalActivo: Boolean;
    function GetPermisos: IPermisosAplicacion;
    function GetConexiones: IServicioConexiones;
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    function GetMonitorSQL: IServicioMonitorSQL;
    function GetContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    function GetUbicacionSesion: TUbicacionSesion;
    function GetFiltrosGuardados: IFiltrosGuardados;
    function GetPerfilesUsuario: IPerfilesUsuario;
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    function GetInformesGuiasCache: IInformesGuiasCache;
    function GetConexionPrincipal: TUniConnection;
    procedure HeredarConexiones(AOwner: TComponent);
    procedure HeredarAuditoriaDatos(AOwner: TComponent);
    procedure HeredarMonitorSQL(AOwner: TComponent);
    procedure HeredarContextoSesion(AOwner: TComponent);
    procedure HeredarFiltrosGuardados(AOwner: TComponent);
    procedure HeredarPerfilesUsuario(AOwner: TComponent);
    procedure HeredarParametros(AOwner: TComponent);
    procedure HeredarInformesGuiasCache(AOwner: TComponent);
    procedure GuardarEnterAsTabDe(AOwner: TComponent);
    function EnterAsTabGuardado(AComp: TJvEnterAsTab): Boolean;
  protected
    // Hooks de log avanzado a nivel de formulario. Se loguean solo si
    // ltAvanzado esta activo en TLog (parametro appLogAvanzado).
    procedure DoShow; override;
    procedure DoClose(var Action: TCloseAction); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DesactivarEnterAsTabTemporal(Sender: TObject);
    procedure RestaurarEnterAsTabTemporal(Sender: TObject);
    procedure ActualizarAuditoria(DataSet: TDataSet);
    procedure CerrarMonitorSQLPendiente;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(AOwner: TComponent;
                       const APermisos: IPermisosAplicacion); reintroduce;
                       overload;
    procedure AsignarPermisos(const APermisos: IPermisosAplicacion);
    procedure AsignarConexiones(
      const AConexiones: IServicioConexiones);
    procedure AsignarAuditoriaDatos(
      const AAuditoriaDatos: IServicioAuditoriaDatos);
    procedure AsignarMonitorSQL(
      const AMonitorSQL: IServicioMonitorSQL);
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    procedure AsignarFiltrosGuardados(
      const AFiltrosGuardados: IFiltrosGuardados);
    procedure AsignarPerfilesUsuario(
      const APerfilesUsuario: IPerfilesUsuario);
    procedure AsignarParametros(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja);
    procedure AsignarInformesGuiasCache(
      const AInformesGuiasCache: IInformesGuiasCache);
    // Articulo/sku del registro/linea en foco, para la consulta de stock
    // global (Ctrl+U, capturado en inMtoPrincipal). Por defecto vacio; los
    // formularios con articulo activo lo sobreescriben.
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); virtual;
    property Permisos: IPermisosAplicacion read GetPermisos;
    property Conexiones: IServicioConexiones read GetConexiones;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
    property MonitorSQL: IServicioMonitorSQL read GetMonitorSQL;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
    property IdentidadSesion: TIdentidadSesion
      read GetIdentidadSesion;
    property UbicacionSesion: TUbicacionSesion
      read GetUbicacionSesion;
    property FiltrosGuardados: IFiltrosGuardados
      read GetFiltrosGuardados;
    property PerfilesUsuario: IPerfilesUsuario read GetPerfilesUsuario;
    property ParametrosApp: IParametrosAplicacion read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja read GetParametrosCaja;
    property InformesGuiasCache: IInformesGuiasCache
      read GetInformesGuiasCache;
    property ConexionPrincipal: TUniConnection read GetConexionPrincipal;
  end;

var
  frmBase: TfrmBase;

implementation

uses
  inLibLog, inLibMsg;

{$R *.dfm}
{$R CXLOCALIZATION.res}

constructor TfrmBase.Create(AOwner: TComponent);
var
  ProveedorPermisos: IProveedorPermisosAplicacion;
begin
  FPermisos := nil;
  if Supports(
       AOwner,
       IProveedorPermisosAplicacion,
       ProveedorPermisos) then
    FPermisos := ProveedorPermisos.Permisos;
  HeredarConexiones(AOwner);
  HeredarAuditoriaDatos(AOwner);
  HeredarMonitorSQL(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarFiltrosGuardados(AOwner);
  HeredarPerfilesUsuario(AOwner);
  HeredarParametros(AOwner);
  HeredarInformesGuiasCache(AOwner);
  inherited Create(AOwner);
end;

constructor TfrmBase.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  FPermisos := APermisos;
  HeredarConexiones(AOwner);
  HeredarAuditoriaDatos(AOwner);
  HeredarMonitorSQL(AOwner);
  HeredarContextoSesion(AOwner);
  HeredarFiltrosGuardados(AOwner);
  HeredarPerfilesUsuario(AOwner);
  HeredarParametros(AOwner);
  HeredarInformesGuiasCache(AOwner);
  inherited Create(AOwner);
end;

procedure TfrmBase.HeredarConexiones(AOwner: TComponent);
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

procedure TfrmBase.HeredarAuditoriaDatos(AOwner: TComponent);
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

procedure TfrmBase.HeredarMonitorSQL(AOwner: TComponent);
var
  Proveedor: IProveedorMonitorSQL;
begin
  FMonitorSQL := nil;
  if Supports(AOwner, IProveedorMonitorSQL, Proveedor) then
    FMonitorSQL := Proveedor.MonitorSQL;
  if not Assigned(FMonitorSQL) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorMonitorSQL,
       Proveedor) then
    FMonitorSQL := Proveedor.MonitorSQL;
end;

procedure TfrmBase.HeredarContextoSesion(AOwner: TComponent);
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

procedure TfrmBase.HeredarFiltrosGuardados(AOwner: TComponent);
var
  Proveedor: IProveedorFiltrosGuardados;
begin
  FFiltrosGuardados := nil;
  if Supports(AOwner, IProveedorFiltrosGuardados, Proveedor) then
    FFiltrosGuardados := Proveedor.FiltrosGuardados;
  if not Assigned(FFiltrosGuardados) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorFiltrosGuardados,
       Proveedor) then
    FFiltrosGuardados := Proveedor.FiltrosGuardados;
end;

procedure TfrmBase.HeredarPerfilesUsuario(AOwner: TComponent);
var
  Proveedor: IProveedorPerfilesUsuario;
begin
  FPerfilesUsuario := nil;
  if Supports(AOwner, IProveedorPerfilesUsuario, Proveedor) then
    FPerfilesUsuario := Proveedor.PerfilesUsuario;
  if not Assigned(FPerfilesUsuario) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorPerfilesUsuario,
       Proveedor) then
    FPerfilesUsuario := Proveedor.PerfilesUsuario;
end;

procedure TfrmBase.HeredarParametros(AOwner: TComponent);
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

procedure TfrmBase.HeredarInformesGuiasCache(AOwner: TComponent);
var
  Proveedor: IProveedorInformesGuiasCache;
begin
  FInformesGuiasCache := nil;
  if Supports(
    AOwner,
    IProveedorInformesGuiasCache,
    Proveedor
  ) then
    FInformesGuiasCache := Proveedor.InformesGuiasCache;
  if not Assigned(FInformesGuiasCache) and
     Assigned(Application.MainForm) and
     (Application.MainForm <> AOwner) and
     Supports(
       Application.MainForm,
       IProveedorInformesGuiasCache,
       Proveedor
     ) then
    FInformesGuiasCache := Proveedor.InformesGuiasCache;
end;

procedure TfrmBase.AsignarPermisos(
  const APermisos: IPermisosAplicacion);
begin
  FPermisos := APermisos;
end;

procedure TfrmBase.AsignarConexiones(
  const AConexiones: IServicioConexiones);
begin
  FConexiones := AConexiones;
end;

procedure TfrmBase.AsignarAuditoriaDatos(
  const AAuditoriaDatos: IServicioAuditoriaDatos);
begin
  FAuditoriaDatos := AAuditoriaDatos;
end;

procedure TfrmBase.AsignarMonitorSQL(
  const AMonitorSQL: IServicioMonitorSQL);
begin
  FMonitorSQL := AMonitorSQL;
end;

procedure TfrmBase.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TfrmBase.AsignarFiltrosGuardados(
  const AFiltrosGuardados: IFiltrosGuardados);
begin
  FFiltrosGuardados := AFiltrosGuardados;
end;

procedure TfrmBase.AsignarPerfilesUsuario(
  const APerfilesUsuario: IPerfilesUsuario);
begin
  FPerfilesUsuario := APerfilesUsuario;
end;

procedure TfrmBase.AsignarParametros(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja);
begin
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
end;

procedure TfrmBase.AsignarInformesGuiasCache(
  const AInformesGuiasCache: IInformesGuiasCache);
begin
  FInformesGuiasCache := AInformesGuiasCache;
end;

function TfrmBase.GetPermisos: IPermisosAplicacion;
begin
  Result := FPermisos;
end;

function TfrmBase.GetConexiones: IServicioConexiones;
begin
  Result := FConexiones;
end;

function TfrmBase.GetAuditoriaDatos: IServicioAuditoriaDatos;
begin
  Result := FAuditoriaDatos;
end;

function TfrmBase.GetMonitorSQL: IServicioMonitorSQL;
begin
  Result := FMonitorSQL;
end;

function TfrmBase.GetContextoSesion: IContextoSesionAplicacion;
begin
  Result := FContextoSesion;
end;

function TfrmBase.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionFormularioNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function TfrmBase.GetUbicacionSesion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionFormularioNoConfigurado);
  Result := FContextoSesion.Ubicacion;
end;

function TfrmBase.GetFiltrosGuardados: IFiltrosGuardados;
begin
  Result := FFiltrosGuardados;
end;

function TfrmBase.GetPerfilesUsuario: IPerfilesUsuario;
begin
  Result := FPerfilesUsuario;
end;

function TfrmBase.GetParametrosApp: IParametrosAplicacion;
begin
  Result := FParametrosApp;
end;

function TfrmBase.GetParametrosCaja: IParametrosCaja;
begin
  Result := FParametrosCaja;
end;

function TfrmBase.GetInformesGuiasCache: IInformesGuiasCache;
begin
  Result := FInformesGuiasCache;
end;

function TfrmBase.GetConexionPrincipal: TUniConnection;
begin
  Result := nil;
  if Assigned(FConexiones) then
    Result := FConexiones.ConexionPrincipal;
end;

procedure TfrmBase.ActualizarAuditoria(DataSet: TDataSet);
begin
  if Assigned(FAuditoriaDatos) then
    FAuditoriaDatos.Actualizar(DataSet)
  else if not (csDesigning in ComponentState) then
    raise Exception.Create(SErrorServicioAuditoriaDatosNoConfigurado);
end;

procedure TfrmBase.CerrarMonitorSQLPendiente;
begin
  if Assigned(FMonitorSQL) then
    FMonitorSQL.CerrarPendiente;
end;

procedure TfrmBase.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  KeyPreview := True;
  FEnterAsTabTemporalActivo := False;
  Localizer1.Locale := 1034;
  Localizer1.Active := True;
  // Etiquetas TcxLabel transparentes (sin fondo solido) en toda la jerarquia
  // que herede de TfrmBase. Centralizado aqui para no repetirlo pantalla a
  // pantalla y cubrir tambien los labels que se anadan en el futuro.
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TcxLabel then
      TcxLabel(Components[i]).Transparent := True;
end;

function TfrmBase.EnterAsTabGuardado(AComp: TJvEnterAsTab): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(FEnterAsTabEstados) - 1 do
    if FEnterAsTabEstados[i].Componente = AComp then
      Result := True;
end;

procedure TfrmBase.GuardarEnterAsTabDe(AOwner: TComponent);
var
  i: Integer;
  n: Integer;
  Comp: TJvEnterAsTab;
begin
  if Assigned(AOwner) then
    for i := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[i] is TJvEnterAsTab then
      begin
        Comp := TJvEnterAsTab(AOwner.Components[i]);
        if not EnterAsTabGuardado(Comp) then
        begin
          n := Length(FEnterAsTabEstados);
          SetLength(FEnterAsTabEstados, n + 1);
          FEnterAsTabEstados[n].Componente := Comp;
          FEnterAsTabEstados[n].EnterAsTab := Comp.EnterAsTab;
          Comp.EnterAsTab := False;
        end;
      end;
end;

procedure TfrmBase.DesactivarEnterAsTabTemporal(Sender: TObject);
begin
  if not FEnterAsTabTemporalActivo then
  begin
    SetLength(FEnterAsTabEstados, 0);
    GuardarEnterAsTabDe(Self);
    GuardarEnterAsTabDe(Owner);
    GuardarEnterAsTabDe(Application.MainForm);
    FEnterAsTabTemporalActivo := True;
  end;
end;

procedure TfrmBase.RestaurarEnterAsTabTemporal(Sender: TObject);
var
  i: Integer;
  MantenerDesactivado: Boolean;
begin
  MantenerDesactivado := False;
  if Sender is TcxCustomDropDownEdit then
    MantenerDesactivado := TcxCustomDropDownEdit(Sender).DroppedDown;
  if FEnterAsTabTemporalActivo and not MantenerDesactivado then
  begin
    for i := 0 to Length(FEnterAsTabEstados) - 1 do
      if Assigned(FEnterAsTabEstados[i].Componente) then
        FEnterAsTabEstados[i].Componente.EnterAsTab :=
          FEnterAsTabEstados[i].EnterAsTab;
    SetLength(FEnterAsTabEstados, 0);
    FEnterAsTabTemporalActivo := False;
  end;
end;

procedure TfrmBase.DoShow;
begin
  inherited;
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, Self.ClassName, 'Show', Self.Name);
end;

procedure TfrmBase.DoClose(var Action: TCloseAction);
begin
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, Self.ClassName, 'Close', Self.Name);
  inherited;
end;

procedure TfrmBase.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (fsModal in FormState) then
  begin
    Key := 0;
    if CloseQuery then
      ModalResult := mrCancel;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmBase.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  // Por defecto un formulario no aporta articulo en foco para Ctrl+U.
  ACodArt := '';
  ACodSku := '';
end;

{
Cómo heredar un form sin haber pasado por File New Others Inheritance.....
Primero poniendo en la definición de la clase, añadiendo el unit a uses y luego
TFormOtherType = class(InheritedFormType)
y después pasando por el dfm coomo se explica a continuación

https://stackoverflow.com/questions/70742195/
                                    how-to-make-an-old-form-inherit-from-another


Open dfm file in some other text editor and replace object with inherited

object FrmMyForm : TFrmMyForm

to

inherited FrmMyForm : TFrmMyForm

However, Delphi has issues with opening such forms
if they don't belong to the same project. For instance,
if you have base form declared in a package and you are
using it to inherit forms in application or another package.

If you have problem opening such forms, make sure that you first
open base form and then inherited.
}
end.
