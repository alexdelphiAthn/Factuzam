program PruebaAuditoriaDatos;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  MidasLib,
  inLibAuditoriaDatos;

procedure Comprobar(ACondicion: Boolean; const AMensaje: string);
begin
  if not ACondicion then
    raise Exception.Create(AMensaje);
end;

procedure CrearCampos(ADataSet: TClientDataSet);
begin
  ADataSet.FieldDefs.Add('VALOR', ftString, 50);
  ADataSet.FieldDefs.Add('INSTANTE_ALTA', ftDateTime);
  ADataSet.FieldDefs.Add('INSTANTE_MODIF', ftDateTime);
  ADataSet.FieldDefs.Add('USUARIO_ALTA', ftString, 50);
  ADataSet.FieldDefs.Add('USUARIO_MODIF', ftString, 50);
  ADataSet.CreateDataSet;
end;

procedure ProbarEdicionActualizaCamposSoloLectura;
var
  Auditoria: TServicioAuditoriaDatos;
  Datos: TClientDataSet;
  InstanteAnterior: TDateTime;
begin
  Datos := TClientDataSet.Create(nil);
  Auditoria := TServicioAuditoriaDatos.Create('Administrador');
  try
    CrearCampos(Datos);
    InstanteAnterior := EncodeDate(2026, 3, 27);
    Datos.Append;
    Datos.FieldByName('VALOR').AsString := 'Antes';
    Datos.FieldByName('INSTANTE_ALTA').AsDateTime := InstanteAnterior;
    Datos.FieldByName('INSTANTE_MODIF').AsDateTime := InstanteAnterior;
    Datos.FieldByName('USUARIO_ALTA').AsString := 'Inicial';
    Datos.FieldByName('USUARIO_MODIF').AsString := 'Inicial';
    Datos.Post;
    Datos.FieldByName('INSTANTE_MODIF').ReadOnly := True;
    Datos.FieldByName('USUARIO_MODIF').ReadOnly := True;
    Datos.Edit;
    Datos.FieldByName('VALOR').AsString := 'Despues';
    Auditoria.Actualizar(Datos);
    Comprobar(
      Datos.FieldByName('USUARIO_MODIF').AsString = 'Administrador',
      'La edición no actualizó USUARIO_MODIF');
    Comprobar(
      Datos.FieldByName('INSTANTE_MODIF').AsDateTime > InstanteAnterior,
      'La edición no actualizó INSTANTE_MODIF');
    Comprobar(
      Datos.FieldByName('USUARIO_MODIF').ReadOnly,
      'USUARIO_MODIF no recuperó ReadOnly');
    Comprobar(
      Datos.FieldByName('INSTANTE_MODIF').ReadOnly,
      'INSTANTE_MODIF no recuperó ReadOnly');
    Datos.Post;
  finally
    Auditoria.Free;
    Datos.Free;
  end;
end;

procedure ProbarInsercionCompletaAuditoriaSoloLectura;
var
  Auditoria: TServicioAuditoriaDatos;
  Datos: TClientDataSet;
begin
  Datos := TClientDataSet.Create(nil);
  Auditoria := TServicioAuditoriaDatos.Create('Administrador');
  try
    CrearCampos(Datos);
    Datos.FieldByName('INSTANTE_ALTA').ReadOnly := True;
    Datos.FieldByName('INSTANTE_MODIF').ReadOnly := True;
    Datos.FieldByName('USUARIO_ALTA').ReadOnly := True;
    Datos.FieldByName('USUARIO_MODIF').ReadOnly := True;
    Datos.Append;
    Datos.FieldByName('VALOR').AsString := 'Nuevo';
    Auditoria.Actualizar(Datos);
    Comprobar(
      Datos.FieldByName('USUARIO_ALTA').AsString = 'Administrador',
      'La inserción no asignó USUARIO_ALTA');
    Comprobar(
      Datos.FieldByName('USUARIO_MODIF').AsString = 'Administrador',
      'La inserción no asignó USUARIO_MODIF');
    Comprobar(
      not Datos.FieldByName('INSTANTE_ALTA').IsNull,
      'La inserción no asignó INSTANTE_ALTA');
    Comprobar(
      not Datos.FieldByName('INSTANTE_MODIF').IsNull,
      'La inserción no asignó INSTANTE_MODIF');
    Comprobar(
      Datos.FieldByName('INSTANTE_ALTA').ReadOnly and
      Datos.FieldByName('INSTANTE_MODIF').ReadOnly and
      Datos.FieldByName('USUARIO_ALTA').ReadOnly and
      Datos.FieldByName('USUARIO_MODIF').ReadOnly,
      'La inserción no restauró ReadOnly');
    Datos.Post;
  finally
    Auditoria.Free;
    Datos.Free;
  end;
end;

begin
  try
    ProbarEdicionActualizaCamposSoloLectura;
    ProbarInsercionCompletaAuditoriaSoloLectura;
    Writeln('PRUEBAS_AUDITORIA_DATOS=OK');
  except
    on E: Exception do
    begin
      Writeln('PRUEBAS_AUDITORIA_DATOS=ERROR: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
