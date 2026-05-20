program FactuzamMigrator;

uses
  Vcl.Forms,
  UMigConn in 'UMigConn.pas' {dmMig: TDataModule},
  UMigEngine in 'UMigEngine.pas',
  inLibMigDumpEsqueleto in 'inLibMigDumpEsqueleto.pas',
  UMigrator in 'UMigrator.pas' {FormMigrator},
  inLibMigFormasPago in 'inLibMigFormasPago.pas',
  inLibMigIvasGrupos in 'inLibMigIvasGrupos.pas',
  inLibMigIvas in 'inLibMigIvas.pas',
  inLibMigEmpresas in 'inLibMigEmpresas.pas',
  inLibMigAlmacenes in 'inLibMigAlmacenes.pas',
  inLibMigClientes in 'inLibMigClientes.pas',
  inLibMigProveedores in 'inLibMigProveedores.pas',
  inLibMigFamilias in 'inLibMigFamilias.pas',
  inLibMigAtributos in 'inLibMigAtributos.pas',
  inLibMigArticulos in 'inLibMigArticulos.pas',
  inLibMigArticulosAtributos in 'inLibMigArticulosAtributos.pas',
  inLibMigArticulosSkus in 'inLibMigArticulosSkus.pas',
  inLibMigInventarios in 'inLibMigInventarios.pas',
  inLibMigTallajes in 'inLibMigTallajes.pas',
  inLibMigArticulosTallajes in 'inLibMigArticulosTallajes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Factuzam Migrator SQL Server';
  Application.CreateForm(TdmMig, dmMig);
  Application.CreateForm(TFormMigrator, FormMigrator);
  Application.Run;
end.
