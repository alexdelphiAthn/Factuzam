program PruebasAuditoriaFase5;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  MidasLib,
  inLibContextoSesionIntf in
    '..\..\src\Lib\inLibContextoSesionIntf.pas',
  inLibContextoSesion in
    '..\..\src\Lib\inLibContextoSesion.pas',
  inLibAuditoriaDatosIntf in
    '..\..\src\Lib\inLibAuditoriaDatosIntf.pas',
  inLibAuditoriaDatos in
    '..\..\src\Lib\inLibAuditoriaDatos.pas';

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

function CrearDataSetAuditable: TClientDataSet;
begin
  Result := TClientDataSet.Create(nil);
  Result.FieldDefs.Add('NOMBRE', ftString, 50);
  Result.FieldDefs.Add('USUARIO_MODIF', ftString, 50);
  Result.FieldDefs.Add('USUARIO_ALTA', ftString, 50);
  Result.FieldDefs.Add('INSTANTE_ALTA', ftDateTime);
  Result.FieldDefs.Add('INSTANTE_MODIF', ftDateTime);
  Result.CreateDataSet;
end;

procedure ProbarDataSetNulo;
var
  Servicio: IServicioAuditoriaDatos;
  SinExcepcion: Boolean;
begin
  Servicio := TServicioAuditoriaDatos.Create('usuario.prueba');
  SinExcepcion := True;
  try
    Servicio.Actualizar(nil);
  except
    SinExcepcion := False;
  end;
  Comprobar(
    SinExcepcion,
    'Un dataset nulo no provoca una excepción');
end;

procedure ProbarInsercion;
var
  DataSet: TClientDataSet;
  Servicio: IServicioAuditoriaDatos;
  InstanteAntes: TDateTime;
  InstanteDespues: TDateTime;
begin
  DataSet := CrearDataSetAuditable;
  try
    Servicio := TServicioAuditoriaDatos.Create('usuario.prueba');
    DataSet.Append;
    DataSet.FieldByName('NOMBRE').AsString := 'Alta';
    InstanteAntes := Now;
    Servicio.Actualizar(DataSet);
    InstanteDespues := Now;
    Comprobar(
      DataSet.FieldByName('USUARIO_MODIF').AsString = 'usuario.prueba',
      'La inserción asigna USUARIO_MODIF');
    Comprobar(
      DataSet.FieldByName('USUARIO_ALTA').AsString = 'usuario.prueba',
      'La inserción asigna USUARIO_ALTA');
    Comprobar(
      (DataSet.FieldByName('INSTANTE_ALTA').AsDateTime >= InstanteAntes) and
      (DataSet.FieldByName('INSTANTE_ALTA').AsDateTime <= InstanteDespues),
      'La inserción asigna INSTANTE_ALTA');
    Comprobar(
      (DataSet.FieldByName('INSTANTE_MODIF').AsDateTime >= InstanteAntes) and
      (DataSet.FieldByName('INSTANTE_MODIF').AsDateTime <= InstanteDespues),
      'La inserción asigna INSTANTE_MODIF');
  finally
    FreeAndNil(DataSet);
  end;
end;

procedure ProbarEdicion;
var
  DataSet: TClientDataSet;
  Servicio: IServicioAuditoriaDatos;
  InstanteAlta: TDateTime;
  InstanteModif: TDateTime;
begin
  DataSet := CrearDataSetAuditable;
  try
    Servicio := TServicioAuditoriaDatos.Create('usuario.alta');
    DataSet.Append;
    Servicio.Actualizar(DataSet);
    DataSet.Post;
    InstanteAlta := DataSet.FieldByName('INSTANTE_ALTA').AsDateTime;
    InstanteModif := DataSet.FieldByName('INSTANTE_MODIF').AsDateTime;
    DataSet.Edit;
    Servicio := TServicioAuditoriaDatos.Create('usuario.edicion');
    Servicio.Actualizar(DataSet);
    Comprobar(
      DataSet.FieldByName('USUARIO_MODIF').AsString = 'usuario.edicion',
      'La edición actualiza USUARIO_MODIF');
    Comprobar(
      DataSet.FieldByName('USUARIO_ALTA').AsString = 'usuario.alta',
      'La edición conserva USUARIO_ALTA');
    Comprobar(
      DataSet.FieldByName('INSTANTE_ALTA').AsDateTime = InstanteAlta,
      'La edición conserva INSTANTE_ALTA');
    Comprobar(
      DataSet.FieldByName('INSTANTE_MODIF').AsDateTime = InstanteModif,
      'La edición conserva el comportamiento anterior de INSTANTE_MODIF');
  finally
    FreeAndNil(DataSet);
  end;
end;

procedure ProbarCamposOpcionales;
var
  DataSet: TClientDataSet;
  Servicio: IServicioAuditoriaDatos;
  SinExcepcion: Boolean;
begin
  DataSet := TClientDataSet.Create(nil);
  try
    DataSet.FieldDefs.Add('NOMBRE', ftString, 50);
    DataSet.CreateDataSet;
    DataSet.Append;
    SinExcepcion := True;
    Servicio := TServicioAuditoriaDatos.Create('usuario.prueba');
    try
      Servicio.Actualizar(DataSet);
    except
      SinExcepcion := False;
    end;
    Comprobar(
      SinExcepcion,
      'Los campos de auditoría continúan siendo opcionales');
  finally
    FreeAndNil(DataSet);
  end;
end;

procedure ProbarEstadoConsulta;
var
  DataSet: TClientDataSet;
  Servicio: IServicioAuditoriaDatos;
begin
  DataSet := CrearDataSetAuditable;
  try
    DataSet.Append;
    DataSet.FieldByName('USUARIO_MODIF').AsString := 'sin.cambios';
    DataSet.Post;
    Servicio := TServicioAuditoriaDatos.Create('usuario.prueba');
    Servicio.Actualizar(DataSet);
    Comprobar(
      DataSet.FieldByName('USUARIO_MODIF').AsString = 'sin.cambios',
      'El estado de consulta no modifica el dataset');
  finally
    FreeAndNil(DataSet);
  end;
end;

procedure ProbarCambioIdentidadContexto;
var
  Contexto: IContextoSesionAplicacion;
  Gestor: IGestorContextoSesion;
  DataSet: TClientDataSet;
  Servicio: IServicioAuditoriaDatos;
begin
  Contexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('usuario.inicial', 'grupo', 'N'),
    TUbicacionSesion.Crear('empresa', 'almacen', 'caja'));
  Supports(Contexto, IGestorContextoSesion, Gestor);
  Servicio := TServicioAuditoriaDatos.Create(Contexto);
  DataSet := CrearDataSetAuditable;
  try
    DataSet.Append;
    Servicio.Actualizar(DataSet);
    Comprobar(
      DataSet.FieldByName('USUARIO_MODIF').AsString = 'usuario.inicial',
      'La auditoría lee el usuario inicial del contexto');
    DataSet.Post;
    Gestor.EstablecerIdentidad(
      TIdentidadSesion.Crear('usuario.nuevo', 'grupo', 'N'));
    DataSet.Edit;
    Servicio.Actualizar(DataSet);
    Comprobar(
      DataSet.FieldByName('USUARIO_MODIF').AsString = 'usuario.nuevo',
      'La auditoría observa los cambios de identidad');
  finally
    FreeAndNil(DataSet);
  end;
end;

begin
  Pruebas := 0;
  Fallos := 0;
  try
    ProbarDataSetNulo;
    ProbarInsercion;
    ProbarEdicion;
    ProbarCamposOpcionales;
    ProbarEstadoConsulta;
    ProbarCambioIdentidadContexto;
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
