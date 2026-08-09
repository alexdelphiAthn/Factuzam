program PruebaIntegracionArchivoDocumental;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Hash,
  System.IOUtils,
  Data.DB,
  Uni,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibContadoresIntf in
    '..\src\Lib\inLibContadoresIntf.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataContadoresRepositorio in
    '..\src\DataModules\UniDataContadoresRepositorio.pas',
  UniDataArchivoDocumental in
    '..\src\DataModules\UniDataArchivoDocumental.pas';

const
  ReferenciaPrueba = 'TEST-INTEGRACION-PDF';

procedure EliminarDocumentoPrueba(AConexion: TUniConnection);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'DELETE FROM cza_documentos ' +
      'WHERE CODIGO_EMP_DOC = ''001'' ' +
      'AND EJERCICIO_DOC = 2026 AND REFERENCIA_DOC = :REFERENCIA';
    oConsulta.ParamByName('REFERENCIA').AsString := ReferenciaPrueba;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EjecutarPrueba;
var
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oArchivo: TdmArchivoDocumental;
  sPdf: string;
  sCopia: string;
begin
  oConfiguracion := Default(TConfiguracionContazam);
  oConfiguracion.Servidor := '127.0.0.1';
  oConfiguracion.Puerto := 3306;
  oConfiguracion.Usuario := 'root';
  oConfiguracion.Contrasena := GetEnvironmentVariable(
    'CONTAZAM_DB_PASSWORD');
  oConfiguracion.BaseDatos := 'contazam';
  oConexion := TdmConexion.Create(nil, oConfiguracion);
  try
    EliminarDocumentoPrueba(oConexion.Conexion);
    oArchivo := TdmArchivoDocumental.Create(
      nil,
      oConexion.Conexion,
      '001',
      2026);
    try
      oArchivo.Abrir;
      sPdf := TPath.Combine(
        GetCurrentDir,
        'fixtures\documento_prueba.pdf');
      oArchivo.ImportarPdf(
        sPdf,
        ReferenciaPrueba,
        'Documento de integración');
      if oArchivo.Documentos.IsEmpty then
      begin
        raise Exception.Create('El PDF no se ha guardado en la BBDD.');
      end;
      sCopia := TPath.Combine(
        TPath.GetTempPath,
        'contazam_prueba_documento.pdf');
      oArchivo.GuardarCopiaActual(sCopia);
      try
        if not SameText(
             THashSHA2.GetHashStringFromFile(sPdf),
             THashSHA2.GetHashStringFromFile(sCopia)) then
        begin
          raise Exception.Create(
            'La copia recuperada no coincide con el PDF original.');
        end;
      finally
        if TFile.Exists(sCopia) then
        begin
          TFile.Delete(sCopia);
        end;
      end;
    finally
      FreeAndNil(oArchivo);
      EliminarDocumentoPrueba(oConexion.Conexion);
    end;
  finally
    FreeAndNil(oConexion);
  end;
end;

begin
  try
    EjecutarPrueba;
    Writeln('ARCHIVO_DOCUMENTAL_BBDD=OK');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
