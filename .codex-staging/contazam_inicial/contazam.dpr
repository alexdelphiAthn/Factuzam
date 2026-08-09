program contazam;

uses
  Vcl.Forms,
  System.SysUtils,
  inLibAplicacionContazam in 'src\Lib\inLibAplicacionContazam.pas',
  inLibConfiguracion in 'src\Lib\inLibConfiguracion.pas',
  inLibRegistroPantallas in 'src\Lib\inLibRegistroPantallas.pas',
  inLibDir in 'src\Lib\inLibDir.pas',
  inLibLogIntf in 'src\Lib\inLibLogIntf.pas',
  inLibLog in 'src\Lib\inLibLog.pas',
  inLibErroresAplicacion in
    'src\Lib\inLibErroresAplicacion.pas',
  inLibGridDevExpress in
    'src\Lib\inLibGridDevExpress.pas',
  inLibSeguridadIntf in 'src\Lib\inLibSeguridadIntf.pas',
  inLibListadosTipos in 'src\Lib\inLibListadosTipos.pas',
  inLibExportadorXlsx in 'src\Lib\inLibExportadorXlsx.pas',
  inLibContabilidadTipos in 'src\Lib\inLibContabilidadTipos.pas',
  inLibValidacionAsientos in 'src\Lib\inLibValidacionAsientos.pas',
  inMtoFrmBase in 'src\Core\inMtoFrmBase.pas',
  inMtoPrincipal in 'src\Core\inMtoPrincipal.pas',
  inMtoGen in 'src\Forms\inMtoGen.pas',
  inMtoEmpresas in 'src\Forms\inMtoEmpresas.pas',
  inMtoEjercicios in 'src\Forms\inMtoEjercicios.pas',
  inMtoPlanContable in 'src\Forms\inMtoPlanContable.pas',
  inMtoLibroDiario in 'src\Forms\inMtoLibroDiario.pas',
  inMtoLibroMayor in 'src\Forms\inMtoLibroMayor.pas',
  inMtoContadores in 'src\Forms\inMtoContadores.pas',
  inMtoImportarFacturas in 'src\Forms\inMtoImportarFacturas.pas',
  inMtoArchivoDocumental in 'src\Forms\inMtoArchivoDocumental.pas',
  inMtoListados in 'src\Forms\inMtoListados.pas',
  inMtoSeguridad in 'src\Forms\inMtoSeguridad.pas',
  UniDataConexion in 'src\DataModules\UniDataConexion.pas',
  UniDataGen in 'src\DataModules\UniDataGen.pas',
  UniDataEmpresas in 'src\DataModules\UniDataEmpresas.pas',
  UniDataEjercicios in 'src\DataModules\UniDataEjercicios.pas',
  UniDataPlanContable in 'src\DataModules\UniDataPlanContable.pas',
  UniDataLibroDiario in 'src\DataModules\UniDataLibroDiario.pas',
  UniDataLibroMayor in 'src\DataModules\UniDataLibroMayor.pas',
  UniDataContadores in 'src\DataModules\UniDataContadores.pas',
  UniDataContadoresRepositorio in
    'src\DataModules\UniDataContadoresRepositorio.pas',
  inLibContadoresIntf in 'src\Lib\inLibContadoresIntf.pas',
  UniDataImportadorFacturas in
    'src\DataModules\UniDataImportadorFacturas.pas',
  UniDataArchivoDocumental in
    'src\DataModules\UniDataArchivoDocumental.pas',
  UniDataListados in 'src\DataModules\UniDataListados.pas',
  UniDataSeguridad in 'src\DataModules\UniDataSeguridad.pas',
  UniDataSeguridadMantenimiento in
    'src\DataModules\UniDataSeguridadMantenimiento.pas';

var
  oAplicacion: TAplicacionContazam;

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Contazam';
  try
    oAplicacion := TAplicacionContazam.Create;
    try
      oAplicacion.Ejecutar;
    finally
      FreeAndNil(oAplicacion);
    end;
  except
    on E: Exception do
    begin
      Application.ShowException(E);
    end;
  end;
end.
