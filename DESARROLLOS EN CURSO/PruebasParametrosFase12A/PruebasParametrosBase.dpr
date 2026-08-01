program PruebasParametrosBase;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  inLibParametrosIntf,
  inLibParametrosBase,
  inLibPerfilesUsuarioIntf,
  inLibCajaParam;

type
  TFuentePerfilesFalsa = class(TInterfacedObject, IPerfilesUsuario)
  private
    FDatos: TProfileDicc;
    FResincronizaciones: Integer;
    function ClonarDatos: TProfileDicc;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Establecer(const AClave, AValor: string);
    procedure Limpiar;
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = ''
    );
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = ''
    );
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
    property Resincronizaciones: Integer read FResincronizaciones;
  end;

  TParametrosPrueba = class(
    TParametrosBase,
    IParametrosAplicacion
  )
  public
    constructor Create(
      const APerfilesUsuario: IPerfilesUsuario;
      const AUsuario, AGrupo: string
    );
    function GetPath(const ANombre: string): string;
  end;

  TLectorParametros = class(TThread)
  private
    FParametros: IParametrosAplicacion;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AParametros: IParametrosAplicacion);
    property Error: string read FError;
  end;

procedure Comprobar(ACondicion: Boolean; const ADescripcion: string);
begin
  if not ACondicion then
    raise Exception.Create('Fallo: ' + ADescripcion);
end;

function BuscarParametro(
  const AParametros: TArray<TParamInfo>;
  const ANombre: string;
  out AParametro: TParamInfo
): Boolean;
var
  Parametro: TParamInfo;
begin
  Result := False;
  for Parametro in AParametros do
  begin
    if SameText(Parametro.Nombre, ANombre) then
    begin
      AParametro := Parametro;
      Result := True;
    end;
  end;
end;

{ TFuentePerfilesFalsa }

constructor TFuentePerfilesFalsa.Create;
begin
  inherited;
  FDatos := TProfileDicc.Create;
end;

destructor TFuentePerfilesFalsa.Destroy;
begin
  FreeAndNil(FDatos);
  inherited;
end;

procedure TFuentePerfilesFalsa.Establecer(
  const AClave, AValor: string);
var
  Valor: TDictValue;
begin
  Valor.sValue := AValor;
  Valor.sValueText := '';
  FDatos.AddOrSetValue(AClave, Valor);
end;

procedure TFuentePerfilesFalsa.Limpiar;
begin
  FDatos.Clear;
end;

function TFuentePerfilesFalsa.ClonarDatos: TProfileDicc;
var
  Par: TPair<string, TDictValue>;
begin
  Result := TProfileDicc.Create;
  for Par in FDatos do
    Result.AddOrSetValue(Par.Key, Par.Value);
end;

procedure TFuentePerfilesFalsa.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
begin
  Establecer(ASubclave, AValor);
end;

procedure TFuentePerfilesFalsa.GrabarPerfiles(
  const APerfiles: TPerfilList);
begin
end;

procedure TFuentePerfilesFalsa.EliminarPerfil(
  const AUsuarioGrupo, AClave, ASubclave: string);
begin
  FDatos.Remove(ASubclave);
end;

function TFuentePerfilesFalsa.ObtenerValorPerfil(
  const AClave, ASubclave, AValorPredeterminado: string): string;
var
  Valor: TDictValue;
begin
  if FDatos.TryGetValue(ASubclave, Valor) then
    Result := Valor.sValue
  else
    Result := AValorPredeterminado;
end;

function TFuentePerfilesFalsa.ObtenerSubclavePerfil(
  const AClave, AValorPredeterminado: string): string;
begin
  Result := AValorPredeterminado;
end;

procedure TFuentePerfilesFalsa.PrecargarPerfilesUsuario;
begin
end;

function TFuentePerfilesFalsa.CargarPerfilFormulario(
  const AFormulario: string;
  out APerfil: TProfileDicc): Boolean;
begin
  APerfil := ClonarDatos;
  Result := True;
end;

function TFuentePerfilesFalsa.CargarPerfilFormulario(
  const AFormulario, AUsuario, AGrupo: string;
  out APerfil: TProfileDicc): Boolean;
begin
  APerfil := ClonarDatos;
  Result := True;
end;

procedure TFuentePerfilesFalsa.ResincronizarPerfilFormulario(
  const AFormulario: string);
begin
  Inc(FResincronizaciones);
end;

procedure TFuentePerfilesFalsa.InvalidarCachePerfiles;
begin
end;

{ TParametrosPrueba }

constructor TParametrosPrueba.Create(
  const APerfilesUsuario: IPerfilesUsuario;
  const AUsuario, AGrupo: string);
begin
  inherited Create(
    APerfilesUsuario,
    'frmParametrosPrueba',
    TArray<string>.Create('Excluir')
  );
  RegistrarParametro(
    'Pruebas',
    'Texto',
    'Texto de prueba',
    tpString,
    'DEF'
  );
  RegistrarParametro(
    'Pruebas',
    'Entero',
    'Entero de prueba',
    tpInteger,
    '7'
  );
  RegistrarParametro(
    'Pruebas',
    'Booleano',
    'Booleano de prueba',
    tpBoolean,
    'True'
  );
  Inicializar(AUsuario, AGrupo);
end;

function TParametrosPrueba.GetPath(const ANombre: string): string;
begin
  Result := GetString(ANombre);
end;

{ TLectorParametros }

constructor TLectorParametros.Create(
  const AParametros: IParametrosAplicacion);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FParametros := AParametros;
end;

procedure TLectorParametros.Execute;
var
  Indice: Integer;
  Valor: string;
begin
  try
    for Indice := 1 to 20000 do
    begin
      Valor := FParametros.GetString('Texto');
      if (Valor <> 'A') and (Valor <> 'B') then
        FError := 'El lector observó un valor parcial: ' + Valor;
    end;
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
  FParametros := nil;
end;

procedure ProbarMotorComun;
var
  FuenteObjeto: TFuentePerfilesFalsa;
  Fuente: IPerfilesUsuario;
  Parametros: IParametrosAplicacion;
  ParametrosLectura: IParametros;
  Edicion: IParametrosEdicion;
  Lista: TArray<TParamInfo>;
  Info: TParamInfo;
  Lectores: array[0..3] of TLectorParametros;
  Indice: Integer;
begin
  FuenteObjeto := TFuentePerfilesFalsa.Create;
  Fuente := FuenteObjeto;
  FuenteObjeto.Establecer('Texto', 'A');
  FuenteObjeto.Establecer('Entero', 'no-es-entero');
  FuenteObjeto.Establecer('Booleano', 'yes');
  FuenteObjeto.Establecer('Excluir', 'oculto');
  FuenteObjeto.Establecer('Huerfano', 'legado');
  Parametros := TParametrosPrueba.Create(Fuente, 'usuario', 'grupo');
  Comprobar(
    Supports(Parametros, IParametros, ParametrosLectura),
    'QueryInterface de IParametros'
  );
  Comprobar(
    Supports(Parametros, IParametrosEdicion, Edicion),
    'QueryInterface de IParametrosEdicion'
  );
  Comprobar(Parametros.GetString('Texto') = 'A', 'lectura string');
  Comprobar(
    Parametros.GetInt('Entero', 7) = 7,
    'entero inválido conserva el default'
  );
  Comprobar(
    not Parametros.GetBool('Booleano', True),
    'booleano inválido conserva la semántica False'
  );
  Lista := Edicion.ListarDefiniciones;
  Comprobar(
    BuscarParametro(Lista, 'Huerfano', Info),
    'parámetro huérfano visible'
  );
  Comprobar(
    Info.Categoria = 'Otros (Heredados de BD)',
    'categoría del parámetro huérfano'
  );
  Comprobar(
    not BuscarParametro(Lista, 'Excluir', Info),
    'clave excluida no visible'
  );
  Lista[0].ValorActual := 'MODIFICADO';
  Lista := Edicion.ListarDefiniciones;
  Comprobar(
    not SameText(Lista[0].ValorActual, 'MODIFICADO'),
    'ListarDefiniciones devuelve una copia'
  );
  for Indice := Low(Lectores) to High(Lectores) do
  begin
    Lectores[Indice] := TLectorParametros.Create(Parametros);
    Lectores[Indice].Start;
  end;
  for Indice := 1 to 100 do
  begin
    if Odd(Indice) then
      FuenteObjeto.Establecer('Texto', 'A')
    else
      FuenteObjeto.Establecer('Texto', 'B');
    Edicion.Recargar('usuario', 'grupo');
  end;
  for Indice := Low(Lectores) to High(Lectores) do
  begin
    Lectores[Indice].WaitFor;
    Comprobar(
      Lectores[Indice].Error = '',
      'lector concurrente ' + IntToStr(Indice + 1)
    );
    FreeAndNil(Lectores[Indice]);
  end;
  Comprobar(
    FuenteObjeto.Resincronizaciones >= 101,
    'la carga y las recargas resincronizan el perfil'
  );
  ParametrosLectura := nil;
  Edicion := nil;
  Parametros := nil;
  Fuente := nil;
end;

procedure ProbarSemanticaCaja;
var
  FuenteObjeto: TFuentePerfilesFalsa;
  Fuente: IPerfilesUsuario;
  Parametros: IParametrosCaja;
  Edicion: IParametrosEdicion;
begin
  FuenteObjeto := TFuentePerfilesFalsa.Create;
  Fuente := FuenteObjeto;
  Parametros := CrearParametrosCaja(Fuente, 'usuario', 'grupo');
  Comprobar(
    Supports(Parametros, IParametrosEdicion, Edicion),
    'QueryInterface de edición para Caja'
  );
  Comprobar(
    Parametros.TarifaDefecto = 'PVP',
    'tarifa ausente usa PVP'
  );
  FuenteObjeto.Establecer('vgerDefTarifa', '');
  Edicion.Recargar('usuario', 'grupo');
  Comprobar(
    Parametros.TarifaDefecto = '',
    'tarifa existente vacía sigue vacía'
  );
  FuenteObjeto.Establecer('vgerArqueoNivelesFamilia', '0');
  Edicion.Recargar('usuario', 'grupo');
  Comprobar(
    Parametros.NivelesFamiliaArqueo = 1,
    'nivel de familias respeta el mínimo'
  );
  FuenteObjeto.Establecer('vgerArqueoNivelesFamilia', '10');
  Edicion.Recargar('usuario', 'grupo');
  Comprobar(
    Parametros.NivelesFamiliaArqueo = 9,
    'nivel de familias respeta el máximo'
  );
  Edicion := nil;
  Parametros := nil;
  Fuente := nil;
end;

begin
  try
    ProbarMotorComun;
    ProbarSemanticaCaja;
    Writeln('RESULTADO UNITARIO: CORRECTO');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
