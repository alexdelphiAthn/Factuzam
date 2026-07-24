program PruebasPerfilesFase9;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibPerfilesUsuarioIntf in
    '..\..\src\Lib\inLibPerfilesUsuarioIntf.pas';

type
  TServicioPerfilesPrueba = class(
    TInterfacedObject,
    IPerfilesUsuario
  )
  private
    FUltimoUsuarioGrupo: string;
    FUltimaClave: string;
    FUltimaSubclave: string;
    FUltimoValor: string;
    FUltimoValorTexto: WideString;
    FPerfilesGrabados: Integer;
    FPrecargado: Boolean;
    FInvalidado: Boolean;
    FFormularioResincronizado: string;
  public
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    procedure PrecargarPerfilesUsuario;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    procedure ResincronizarPerfilFormulario(const AFormulario: string);
    procedure InvalidarCachePerfiles;
    property UltimoUsuarioGrupo: string read FUltimoUsuarioGrupo;
    property UltimaClave: string read FUltimaClave;
    property UltimaSubclave: string read FUltimaSubclave;
    property UltimoValor: string read FUltimoValor;
    property UltimoValorTexto: WideString read FUltimoValorTexto;
    property PerfilesGrabados: Integer read FPerfilesGrabados;
    property Precargado: Boolean read FPrecargado;
    property Invalidado: Boolean read FInvalidado;
    property FormularioResincronizado: string
      read FFormularioResincronizado;
  end;

  TProveedorPerfilesPrueba = class(
    TInterfacedObject,
    IProveedorPerfilesUsuario
  )
  private
    FServicio: IPerfilesUsuario;
    function GetPerfilesUsuario: IPerfilesUsuario;
  public
    constructor Create(const AServicio: IPerfilesUsuario);
  end;

var
  Pruebas: Integer;
  Fallos: Integer;

procedure Comprobar(ACondicion: Boolean; const ANombre: string);
begin
  Inc(Pruebas);
  if ACondicion then
    Writeln('[OK] ', ANombre)
  else
  begin
    Inc(Fallos);
    Writeln('[ERROR] ', ANombre);
  end;
end;

procedure TServicioPerfilesPrueba.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
begin
  FUltimoUsuarioGrupo := AUsuarioGrupo;
  FUltimaClave := AClave;
  FUltimaSubclave := ASubclave;
  FUltimoValor := AValor;
  FUltimoValorTexto := AValorTexto;
end;

procedure TServicioPerfilesPrueba.GrabarPerfiles(
  const APerfiles: TPerfilList);
begin
  FPerfilesGrabados := 0;
  if Assigned(APerfiles) then
    FPerfilesGrabados := APerfiles.Count;
end;

procedure TServicioPerfilesPrueba.EliminarPerfil(
  const AUsuarioGrupo, AClave, ASubclave: string);
begin
  FUltimoUsuarioGrupo := AUsuarioGrupo;
  FUltimaClave := AClave;
  FUltimaSubclave := ASubclave;
  FUltimoValor := '';
  FUltimoValorTexto := '';
end;

function TServicioPerfilesPrueba.ObtenerValorPerfil(
  const AClave, ASubclave, AValorPredeterminado: string): string;
begin
  Result := AClave + ':' + ASubclave;
end;

function TServicioPerfilesPrueba.ObtenerSubclavePerfil(
  const AClave, AValorPredeterminado: string): string;
begin
  Result := AClave + ':subclave';
end;

procedure TServicioPerfilesPrueba.PrecargarPerfilesUsuario;
begin
  FPrecargado := True;
end;

function TServicioPerfilesPrueba.CargarPerfilFormulario(
  const AFormulario: string;
  out APerfil: TProfileDicc): Boolean;
var
  Valor: TDictValue;
begin
  APerfil := TProfileDicc.Create;
  Valor.sValue := AFormulario;
  Valor.sValueText := 'actual';
  APerfil.Add('clave', Valor);
  Result := True;
end;

function TServicioPerfilesPrueba.CargarPerfilFormulario(
  const AFormulario, AUsuario, AGrupo: string;
  out APerfil: TProfileDicc): Boolean;
var
  Valor: TDictValue;
begin
  APerfil := TProfileDicc.Create;
  Valor.sValue := AUsuario;
  Valor.sValueText := AGrupo;
  APerfil.Add(AFormulario, Valor);
  Result := True;
end;

procedure TServicioPerfilesPrueba.ResincronizarPerfilFormulario(
  const AFormulario: string);
begin
  FFormularioResincronizado := AFormulario;
end;

procedure TServicioPerfilesPrueba.InvalidarCachePerfiles;
begin
  FInvalidado := True;
end;

constructor TProveedorPerfilesPrueba.Create(
  const AServicio: IPerfilesUsuario);
begin
  inherited Create;
  FServicio := AServicio;
end;

function TProveedorPerfilesPrueba.GetPerfilesUsuario: IPerfilesUsuario;
begin
  Result := FServicio;
end;

procedure ProbarContrato;
var
  ObjetoServicio: TServicioPerfilesPrueba;
  Servicio: IPerfilesUsuario;
  Proveedor: IProveedorPerfilesUsuario;
  Perfiles: TPerfilList;
  Item: TPerfilItem;
  Perfil: TProfileDicc;
begin
  ObjetoServicio := TServicioPerfilesPrueba.Create;
  Servicio := ObjetoServicio;
  Proveedor := TProveedorPerfilesPrueba.Create(Servicio);
  Comprobar(
    Proveedor.PerfilesUsuario = Servicio,
    'El proveedor publica el servicio mediante la interfaz');
  Servicio.GrabarPerfil(
    'usuario.prueba',
    'frmPrueba',
    'clave',
    'valor',
    'valor extenso');
  Comprobar(
    (ObjetoServicio.UltimoUsuarioGrupo = 'usuario.prueba') and
    (ObjetoServicio.UltimaClave = 'frmPrueba') and
    (ObjetoServicio.UltimaSubclave = 'clave') and
    (ObjetoServicio.UltimoValor = 'valor') and
    (ObjetoServicio.UltimoValorTexto = 'valor extenso'),
    'La grabación individual atraviesa el contrato');
  Perfiles := TPerfilList.Create;
  try
    Item.UserGroup := 'usuario.prueba';
    Item.KeyPerfil := 'frmPrueba';
    Item.SubKey := 'ancho';
    Item.Value := '120';
    Perfiles.Add(Item);
    Item.SubKey := 'alto';
    Item.Value := '80';
    Perfiles.Add(Item);
    Servicio.GrabarPerfiles(Perfiles);
  finally
    FreeAndNil(Perfiles);
  end;
  Comprobar(
    ObjetoServicio.PerfilesGrabados = 2,
    'La lista permite grabar perfiles por lote');
  Comprobar(
    Servicio.ObtenerValorPerfil('form', 'clave', '') = 'form:clave',
    'La lectura de valores atraviesa el contrato');
  Comprobar(
    Servicio.ObtenerSubclavePerfil('form', '') = 'form:subclave',
    'La lectura de subclaves atraviesa el contrato');
  Perfil := nil;
  try
    Comprobar(
      Servicio.CargarPerfilFormulario('frmActual', Perfil) and
      (Perfil['clave'].sValue = 'frmActual'),
      'El contrato devuelve el perfil del contexto actual');
  finally
    FreeAndNil(Perfil);
  end;
  Perfil := nil;
  try
    Comprobar(
      Servicio.CargarPerfilFormulario(
        'frmOtro',
        'otro.usuario',
        'otro.grupo',
        Perfil) and
      (Perfil['frmOtro'].sValue = 'otro.usuario') and
      (Perfil['frmOtro'].sValueText = 'otro.grupo'),
      'El contrato admite una identidad explícita');
  finally
    FreeAndNil(Perfil);
  end;
  Servicio.PrecargarPerfilesUsuario;
  Servicio.ResincronizarPerfilFormulario('frmPrueba');
  Servicio.InvalidarCachePerfiles;
  Comprobar(
    ObjetoServicio.Precargado and
    ObjetoServicio.Invalidado and
    (ObjetoServicio.FormularioResincronizado = 'frmPrueba'),
    'Las órdenes de caché se despachan por la interfaz');
  Servicio.EliminarPerfil('usuario.prueba', 'frmPrueba', 'clave');
  Comprobar(
    (ObjetoServicio.UltimoUsuarioGrupo = 'usuario.prueba') and
    (ObjetoServicio.UltimaClave = 'frmPrueba') and
    (ObjetoServicio.UltimaSubclave = 'clave'),
    'La eliminación se despacha por la interfaz');
end;

begin
  Pruebas := 0;
  Fallos := 0;
  ProbarContrato;
  Writeln;
  Writeln('Pruebas: ', Pruebas, ' | Fallos: ', Fallos);
  if Fallos > 0 then
    Halt(1);
end.
