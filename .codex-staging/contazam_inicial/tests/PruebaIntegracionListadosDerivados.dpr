program PruebaIntegracionListadosDerivados;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Datasnap.DBClient,
  MidasLib,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibListadosDerivadosIntf in
    '..\src\Lib\inLibListadosDerivadosIntf.pas',
  inLibListadoFastReport in
    '..\src\Lib\inLibListadoFastReport.pas',
  inLibContadoresIntf in
    '..\src\Lib\inLibContadoresIntf.pas',
  inMtoFrmBase in
    '..\src\Core\inMtoFrmBase.pas',
  inMtoModalGuardarListado in
    '..\src\Modals\inMtoModalGuardarListado.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataContadoresRepositorio in
    '..\src\DataModules\UniDataContadoresRepositorio.pas',
  UniDataListadosDerivados in
    '..\src\DataModules\UniDataListadosDerivados.pas';

procedure EjecutarPrueba;
var
  bEncontrado: Boolean;
  iIndice: Integer;
  iIdExistente: Int64;
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oContexto: TContextoListadosDerivados;
  oDatos: TClientDataSet;
  oGuardado: TListadoDerivado;
  oListadoActual: TListadoDerivado;
  oListados: TListadosDerivados;
  oPlantilla: TMemoryStream;
  oRecuperada: TMemoryStream;
  oRepositorio: IRepositorioListadosDerivados;
  oServicio: TServicioListadoFastReport;
  oSolicitud: TSolicitudGuardarListadoDerivado;
begin
  oConfiguracion := Default(TConfiguracionContazam);
  oConfiguracion.Servidor := '127.0.0.1';
  oConfiguracion.Puerto := 3306;
  oConfiguracion.Usuario := 'root';
  oConfiguracion.Contrasena := GetEnvironmentVariable(
    'CONTAZAM_DB_PASSWORD');
  oConfiguracion.BaseDatos := 'contazam';
  oConexion := TdmConexion.Create(nil, oConfiguracion);
  oDatos := TClientDataSet.Create(nil);
  oPlantilla := TMemoryStream.Create;
  oRecuperada := TMemoryStream.Create;
  try
    oDatos.FieldDefs.Add('CUENTA', ftString, 15);
    oDatos.FieldDefs.Add('NOMBRE', ftString, 80);
    oDatos.FieldDefs.Add('SUMA_DEBE', ftCurrency);
    oDatos.FieldDefs.Add('SUMA_HABER', ftCurrency);
    oDatos.CreateDataSet;
    oDatos.AppendRecord([
      '430000000000',
      'Clientes de prueba',
      Currency(121.50),
      Currency(0)
    ]);
    oContexto := Default(TContextoListadosDerivados);
    oContexto.RecursoBase := 'LISTADO_BALANCE';
    oContexto.Empresa := '001';
    oContexto.Usuario := UpperCase(
      GetEnvironmentVariable('USERNAME'));
    oRepositorio := CrearRepositorioListadosDerivados(
      oConexion.Conexion);
    oServicio := TServicioListadoFastReport.Create(
      oDatos,
      'Balance sencillo de demostración',
      'Empresa 001 | Ejercicio 2026',
      oContexto,
      oRepositorio);
    try
      oListadoActual := Default(TListadoDerivado);
      oServicio.Cargar(nil, oListadoActual);
      if not oServicio.Preparar then
      begin
        raise Exception.Create(
          'FastReport no ha podido preparar el listado.');
      end;
      oServicio.GuardarPlantilla(oPlantilla);
    finally
      FreeAndNil(oServicio);
    end;
    oSolicitud := Default(TSolicitudGuardarListadoDerivado);
    oSolicitud.Contexto := oContexto;
    oSolicitud.Nombre := 'Balance sencillo (demo)';
    oSolicitud.Descripcion :=
      'Formato de demostración editable desde FastReport.';
    oSolicitud.Alcance.Alcance := 'EMPRESA';
    oSolicitud.Alcance.Empresa := '001';
    iIdExistente := oRepositorio.BuscarId(
      oContexto,
      oSolicitud.Nombre,
      oSolicitud.Alcance);
    oSolicitud.Id := iIdExistente;
    oGuardado := oRepositorio.Guardar(oSolicitud, oPlantilla);
    if oGuardado.Id = 0 then
    begin
      raise Exception.Create(
        'El formato derivado no ha recibido identificador.');
    end;
    if not oRepositorio.Leer(
      oContexto,
      oGuardado.Id,
      oRecuperada) then
    begin
      raise Exception.Create(
        'El formato derivado no se puede leer desde la BBDD.');
    end;
    if oRecuperada.Size <> oPlantilla.Size then
    begin
      raise Exception.Create(
        'El BLOB recuperado no conserva el tamaño de la plantilla.');
    end;
    oListados := oRepositorio.Listar(oContexto);
    bEncontrado := False;
    iIndice := 0;
    while (iIndice < Length(oListados)) and not bEncontrado do
    begin
      bEncontrado := oListados[iIndice].Id = oGuardado.Id;
      if not bEncontrado then
      begin
        Inc(iIndice);
      end;
    end;
    if not bEncontrado then
    begin
      raise Exception.Create(
        'El formato guardado no aparece en la lista de la empresa.');
    end;
    Writeln('LISTADO_DERIVADO_ID=', oGuardado.Id);
    Writeln('LISTADO_DERIVADO_VERSION=', oGuardado.Version);
    Writeln('PLANTILLA_FR3_BYTES=', oPlantilla.Size);
  finally
    oRepositorio := nil;
    FreeAndNil(oRecuperada);
    FreeAndNil(oPlantilla);
    FreeAndNil(oDatos);
    FreeAndNil(oConexion);
  end;
end;

begin
  try
    EjecutarPrueba;
    Writeln('LISTADOS_DERIVADOS_BBDD=OK');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
