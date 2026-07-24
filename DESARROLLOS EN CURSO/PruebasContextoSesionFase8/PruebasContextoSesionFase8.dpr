program PruebasContextoSesionFase8;

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

procedure ProbarEstructuras;
var
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  Identidad := TIdentidadSesion.Crear(
    '  usuario.prueba  ',
    '  grupo.prueba  ',
    ' s ');
  Ubicacion := TUbicacionSesion.Crear(
    '  EMP01  ',
    '  ALM01  ',
    '  CAJA01  ');
  Comprobar(
    Identidad.Usuario = 'usuario.prueba',
    'La identidad normaliza el usuario');
  Comprobar(
    Identidad.Grupo = 'grupo.prueba',
    'La identidad normaliza el grupo');
  Comprobar(
    Identidad.EsAdministrador,
    'El indicador de administrador no distingue mayúsculas');
  Comprobar(
    Ubicacion.Empresa = 'EMP01',
    'La ubicación normaliza la empresa');
  Comprobar(
    (Ubicacion.Almacen = 'ALM01') and
    (Ubicacion.Caja = 'CAJA01'),
    'La ubicación conserva almacén y caja');
end;

procedure ProbarLecturaYEscritura;
var
  Contexto: IContextoSesionAplicacion;
  Gestor: IGestorContextoSesion;
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  Contexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('usuario.inicial', 'grupo.inicial', 'N'),
    TUbicacionSesion.Crear('EMP01', 'ALM01', 'CAJA01'));
  Comprobar(
    Contexto.Identidad.Usuario = 'usuario.inicial',
    'El contrato de lectura publica la identidad inicial');
  Comprobar(
    Contexto.Ubicacion.Caja = 'CAJA01',
    'El contrato de lectura publica la ubicación inicial');
  Comprobar(
    Supports(Contexto, IGestorContextoSesion, Gestor),
    'La implementación admite el contrato separado de escritura');
  Gestor.EstablecerIdentidad(
    TIdentidadSesion.Crear('usuario.nuevo', 'grupo.nuevo', 'S'));
  Comprobar(
    (Contexto.Identidad.Usuario = 'usuario.nuevo') and
    Contexto.Identidad.EsAdministrador,
    'El gestor actualiza la identidad observada por los lectores');
  Gestor.CambiarUbicacion(
    TUbicacionSesion.Crear('EMP02', 'ALM02', 'CAJA02'));
  Comprobar(
    (Contexto.Ubicacion.Empresa = 'EMP02') and
    (Contexto.Ubicacion.Almacen = 'ALM02') and
    (Contexto.Ubicacion.Caja = 'CAJA02'),
    'El gestor actualiza la ubicación completa');
  Identidad := Contexto.Identidad;
  Identidad.Usuario := 'alterado.fuera';
  Comprobar(
    Contexto.Identidad.Usuario = 'usuario.nuevo',
    'La identidad se entrega como una instantánea');
  Ubicacion := Contexto.Ubicacion;
  Ubicacion.Caja := 'alterada.fuera';
  Comprobar(
    Contexto.Ubicacion.Caja = 'CAJA02',
    'La ubicación se entrega como una instantánea');
end;

begin
  Pruebas := 0;
  Fallos := 0;
  ProbarEstructuras;
  ProbarLecturaYEscritura;
  Writeln;
  Writeln('Pruebas: ', Pruebas, ' | Fallos: ', Fallos);
  if Fallos > 0 then
    Halt(1);
end.
