program PruebasFiltrosFase9;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibFiltrosGuardadosIntf in
    '..\..\src\Lib\inLibFiltrosGuardadosIntf.pas';

type
  TServicioFiltrosPrueba = class(
    TInterfacedObject,
    IFiltrosGuardados
  )
  private
    FUltimoIdBorrado: Int64;
  public
    function ListarFiltros(
      const AMto, AVista: string
    ): TFiltrosGuardadosList;
    function BuscarFiltroPropio(
      const AMto, AVista, ANombre: string
    ): Int64;
    function GuardarFiltroNuevo(
      const AMto, AVista, ANombre, ADescripcion, AFiltroBase64: string
    ): Int64;
    procedure SobrescribirFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion, AFiltroBase64: string
    );
    procedure RenombrarFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion: string
    );
    procedure BorrarFiltro(AIdFiltro: Int64);
    function EsPropietario(AIdFiltro: Int64): Boolean;
    function CargarFiltroBase64(AIdFiltro: Int64): string;
    function ListarDestinosCompartidos(
      AIdFiltro: Int64
    ): TDestinosCompartidosList;
    procedure CompartirConDestino(
      AIdFiltro: Int64;
      const ATipoDestino, ADestino: string
    );
    procedure QuitarDestinoCompartido(AIdDestino: Int64);
    property UltimoIdBorrado: Int64 read FUltimoIdBorrado;
  end;

  TProveedorFiltrosPrueba = class(
    TInterfacedObject,
    IProveedorFiltrosGuardados
  )
  private
    FServicio: IFiltrosGuardados;
    function GetFiltrosGuardados: IFiltrosGuardados;
  public
    constructor Create(const AServicio: IFiltrosGuardados);
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

function TServicioFiltrosPrueba.ListarFiltros(
  const AMto, AVista: string): TFiltrosGuardadosList;
var
  Info: TFiltroGuardadoInfo;
begin
  Result := TFiltrosGuardadosList.Create;
  Info.Id := 42;
  Info.Nombre := AMto + '.' + AVista;
  Info.Descripcion := 'Filtro de prueba';
  Info.Propietario := 'usuario.prueba';
  Info.EsPropio := True;
  Result.Add(Info);
end;

function TServicioFiltrosPrueba.BuscarFiltroPropio(
  const AMto, AVista, ANombre: string): Int64;
begin
  Result := 42;
end;

function TServicioFiltrosPrueba.GuardarFiltroNuevo(
  const AMto, AVista, ANombre, ADescripcion,
  AFiltroBase64: string): Int64;
begin
  Result := 43;
end;

procedure TServicioFiltrosPrueba.SobrescribirFiltro(
  AIdFiltro: Int64;
  const ANombre, ADescripcion, AFiltroBase64: string);
begin
end;

procedure TServicioFiltrosPrueba.RenombrarFiltro(
  AIdFiltro: Int64;
  const ANombre, ADescripcion: string);
begin
end;

procedure TServicioFiltrosPrueba.BorrarFiltro(AIdFiltro: Int64);
begin
  FUltimoIdBorrado := AIdFiltro;
end;

function TServicioFiltrosPrueba.EsPropietario(
  AIdFiltro: Int64): Boolean;
begin
  Result := AIdFiltro = 42;
end;

function TServicioFiltrosPrueba.CargarFiltroBase64(
  AIdFiltro: Int64): string;
begin
  Result := 'BASE64-' + IntToStr(AIdFiltro);
end;

function TServicioFiltrosPrueba.ListarDestinosCompartidos(
  AIdFiltro: Int64): TDestinosCompartidosList;
var
  Info: TDestinoCompartidoInfo;
begin
  Result := TDestinosCompartidosList.Create;
  Info.Id := 7;
  Info.TipoDestino := 'GRUPO';
  Info.UsuarioGrupo := 'grupo.prueba';
  Result.Add(Info);
end;

procedure TServicioFiltrosPrueba.CompartirConDestino(
  AIdFiltro: Int64;
  const ATipoDestino, ADestino: string);
begin
end;

procedure TServicioFiltrosPrueba.QuitarDestinoCompartido(
  AIdDestino: Int64);
begin
end;

constructor TProveedorFiltrosPrueba.Create(
  const AServicio: IFiltrosGuardados);
begin
  inherited Create;
  FServicio := AServicio;
end;

function TProveedorFiltrosPrueba.GetFiltrosGuardados: IFiltrosGuardados;
begin
  Result := FServicio;
end;

procedure ProbarContrato;
var
  ObjetoServicio: TServicioFiltrosPrueba;
  Servicio: IFiltrosGuardados;
  Proveedor: IProveedorFiltrosGuardados;
  Filtros: TFiltrosGuardadosList;
  Destinos: TDestinosCompartidosList;
begin
  ObjetoServicio := TServicioFiltrosPrueba.Create;
  Servicio := ObjetoServicio;
  Proveedor := TProveedorFiltrosPrueba.Create(Servicio);
  Comprobar(
    Proveedor.FiltrosGuardados = Servicio,
    'El proveedor publica el servicio mediante la interfaz');
  Filtros := Servicio.ListarFiltros('frmPrueba', 'vistaPrueba');
  try
    Comprobar(
      Filtros.Count = 1,
      'El contrato devuelve una lista de filtros');
    Comprobar(
      (Filtros[0].Id = 42) and
      Filtros[0].EsPropio and
      (Filtros[0].Propietario = 'usuario.prueba'),
      'El DTO conserva identidad y propiedad del filtro');
  finally
    FreeAndNil(Filtros);
  end;
  Comprobar(
    Servicio.CargarFiltroBase64(42) = 'BASE64-42',
    'El contenido serializado atraviesa el contrato');
  Destinos := Servicio.ListarDestinosCompartidos(42);
  try
    Comprobar(
      (Destinos.Count = 1) and
      (Destinos[0].TipoDestino = 'GRUPO') and
      (Destinos[0].UsuarioGrupo = 'grupo.prueba'),
      'El DTO conserva los destinos compartidos');
  finally
    FreeAndNil(Destinos);
  end;
  Servicio.BorrarFiltro(42);
  Comprobar(
    ObjetoServicio.UltimoIdBorrado = 42,
    'Las órdenes se despachan a través de la interfaz');
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
