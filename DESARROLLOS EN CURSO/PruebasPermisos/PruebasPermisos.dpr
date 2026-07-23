program PruebasPermisos;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibPermisosIntf in '..\..\src\Lib\inLibPermisosIntf.pas',
  inLibPermisos in '..\..\src\Lib\inLibPermisos.pas';

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

function CrearPermisos(
  const AIdentidad: TIdentidadPermisos;
  const AReglas: TArray<TReglaPermiso>
): IPermisosAplicacion;
begin
  Result := TPermisosAplicacion.Create(
    AIdentidad,
    AReglas,
    True);
end;

procedure ProbarAdministrador;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('admin', 'Administradores', True);
  Permisos := TPermisosAplicacion.CrearNoDisponible(Identidad);
  Resultado := Permisos.Evaluar('caja.verCoste', paDenegar);
  Comprobar(Resultado.Permitido,
            'El administrador siempre tiene permiso');
  Comprobar(Resultado.Origen = opAdministrador,
            'El origen del administrador queda identificado');
end;

procedure ProbarPrioridadUsuario;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('ana', 'Ventas', False);
  Permisos := CrearPermisos(
    Identidad,
    [
      TReglaPermiso.Crear('Todos', 'facturas.modificar', True),
      TReglaPermiso.Crear('Ventas', 'facturas.modificar', True),
      TReglaPermiso.Crear('ana', 'facturas.modificar', False)
    ]);
  Resultado := Permisos.Evaluar('facturas.modificar', paPermitir);
  Comprobar(not Resultado.Permitido,
            'El usuario prevalece sobre el grupo y Todos');
  Comprobar(Resultado.Origen = opUsuario,
            'La resolución informa del origen usuario');
end;

procedure ProbarPrioridadGrupo;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('ana', 'Ventas', False);
  Permisos := CrearPermisos(
    Identidad,
    [
      TReglaPermiso.Crear('Todos', 'facturas.borrar', True),
      TReglaPermiso.Crear('Ventas', 'facturas.borrar', False)
    ]);
  Resultado := Permisos.Evaluar('facturas.borrar', paPermitir);
  Comprobar(not Resultado.Permitido,
            'El grupo prevalece sobre Todos');
  Comprobar(Resultado.Origen = opGrupo,
            'La resolución informa del origen grupo');
end;

procedure ProbarTodos;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('ana', 'Ventas', False);
  Permisos := CrearPermisos(
    Identidad,
    [TReglaPermiso.Crear('Todos', 'articulos.consultar', True)]);
  Resultado := Permisos.Evaluar('articulos.consultar', paDenegar);
  Comprobar(Resultado.Permitido,
            'La regla Todos se aplica como último ámbito');
  Comprobar(Resultado.Origen = opTodos,
            'La resolución informa del origen Todos');
end;

procedure ProbarPermisoAusente;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('ana', 'Ventas', False);
  Permisos := CrearPermisos(Identidad, []);
  Resultado := Permisos.Evaluar('sin.regla', paPermitir);
  Comprobar(Resultado.Permitido,
            'Un permiso ausente puede permitirse explícitamente');
  Comprobar(Resultado.Origen = opNoDefinido,
            'El permiso ausente queda identificado');
  Resultado := Permisos.Evaluar('sin.regla', paDenegar);
  Comprobar(not Resultado.Permitido,
            'Un permiso ausente puede denegarse explícitamente');
end;

procedure ProbarNoDisponible;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
  Resultado: TResultadoPermiso;
begin
  Identidad := TIdentidadPermisos.Crear('ana', 'Ventas', False);
  Permisos := TPermisosAplicacion.CrearNoDisponible(Identidad);
  Resultado := Permisos.Evaluar('caja.abrirCajon', paPermitir);
  Comprobar(not Resultado.Permitido,
            'El servicio no disponible aplica fallo cerrado');
  Comprobar(Resultado.Origen = opNoDisponible,
            'El fallo cerrado informa de que no hay servicio');
end;

procedure ProbarNormalizacion;
var
  Identidad: TIdentidadPermisos;
  Permisos: IPermisosAplicacion;
begin
  Identidad := TIdentidadPermisos.Crear(' ANA ', ' Ventas ', False);
  Permisos := CrearPermisos(
    Identidad,
    [TReglaPermiso.Crear('ana', ' CAJA.VERCOSTE ', True)]);
  Comprobar(
    Permisos.TienePermiso('caja.verCoste', paDenegar),
    'Sujetos y códigos se comparan normalizados');
end;

procedure ProbarCodigoMto;
begin
  Comprobar(
    CodigoPermisoMto('Facturas', apmImprimir) = 'Facturas.imprimir',
    'El código de permiso de mantenimiento se construye por acción');
end;

begin
  Pruebas := 0;
  Fallos := 0;
  try
    ProbarAdministrador;
    ProbarPrioridadUsuario;
    ProbarPrioridadGrupo;
    ProbarTodos;
    ProbarPermisoAusente;
    ProbarNoDisponible;
    ProbarNormalizacion;
    ProbarCodigoMto;
  except
    on E: Exception do
    begin
      Inc(Fallos);
      Writeln('[EXCEPCION] ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln;
  Writeln('Pruebas: ', Pruebas, ' | Fallos: ', Fallos);
  if Fallos = 0 then
    ExitCode := 0
  else
    ExitCode := 1;
end.
