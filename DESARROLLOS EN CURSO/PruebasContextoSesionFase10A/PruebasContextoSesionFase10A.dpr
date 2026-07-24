program PruebasContextoSesionFase10A;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibContextoSesionIntf in
    '..\..\src\Lib\inLibContextoSesionIntf.pas',
  inLibContextoSesion in
    '..\..\src\Lib\inLibContextoSesion.pas';

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

procedure ProbarResultadoNoAutenticado;
var
  ResultadoInicioSesion: TResultadoInicioSesion;
begin
  ResultadoInicioSesion :=
    TResultadoInicioSesion.CrearNoAutenticado;
  Comprobar(
    not ResultadoInicioSesion.Autenticado,
    'El resultado inicial no está autenticado');
  Comprobar(
    ResultadoInicioSesion.Identidad.Usuario = '',
    'El resultado inicial no conserva una identidad anterior');
  Comprobar(
    ResultadoInicioSesion.Ubicacion.Empresa = '',
    'El resultado inicial no conserva una ubicación anterior');
end;

procedure ProbarResultadoAutenticado;
var
  ResultadoInicioSesion: TResultadoInicioSesion;
  ContextoSesion: IContextoSesionAplicacion;
begin
  ResultadoInicioSesion :=
    TResultadoInicioSesion.CrearAutenticado(
      TIdentidadSesion.Crear(
        ' usuario.prueba ',
        ' grupo.prueba ',
        ' s '),
      TUbicacionSesion.Crear(
        ' EMP01 ',
        ' ALM01 ',
        ' CAJA01 '));
  Comprobar(
    ResultadoInicioSesion.Autenticado,
    'El resultado correcto queda autenticado');
  Comprobar(
    (ResultadoInicioSesion.Identidad.Usuario = 'usuario.prueba') and
    (ResultadoInicioSesion.Identidad.Grupo = 'grupo.prueba'),
    'El resultado transporta la identidad normalizada');
  Comprobar(
    ResultadoInicioSesion.Identidad.EsAdministrador,
    'El resultado conserva el indicador de administrador');
  Comprobar(
    (ResultadoInicioSesion.Ubicacion.Empresa = 'EMP01') and
    (ResultadoInicioSesion.Ubicacion.Almacen = 'ALM01') and
    (ResultadoInicioSesion.Ubicacion.Caja = 'CAJA01'),
    'El resultado transporta la ubicación normalizada');
  ContextoSesion := TContextoSesionAplicacion.Create(
    ResultadoInicioSesion.Identidad,
    ResultadoInicioSesion.Ubicacion);
  Comprobar(
    (ContextoSesion.Identidad.Usuario = 'usuario.prueba') and
    (ContextoSesion.Ubicacion.Caja = 'CAJA01'),
    'El contexto se construye directamente desde el resultado');
  ResultadoInicioSesion :=
    TResultadoInicioSesion.CrearNoAutenticado;
  Comprobar(
    (ContextoSesion.Identidad.Usuario = 'usuario.prueba') and
    (ContextoSesion.Ubicacion.Caja = 'CAJA01'),
    'El contexto no depende de la vida del resultado');
end;

begin
  Pruebas := 0;
  Fallos := 0;
  ProbarResultadoNoAutenticado;
  ProbarResultadoAutenticado;
  Writeln;
  Writeln('Pruebas: ', Pruebas, ' | Fallos: ', Fallos);
  if Fallos > 0 then
    Halt(1);
end.
