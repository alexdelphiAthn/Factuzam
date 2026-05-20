program FactuzamMigrator;

uses
  Vcl.Forms,
  UMigConn in 'UMigConn.pas' {dmMig: TDataModule},
  UMigEngine in 'UMigEngine.pas',
  UMigrator in 'UMigrator.pas' {FormMigrator},
  inLibMigFormasPago in 'inLibMigFormasPago.pas',
  inLibMigIvasGrupos in 'inLibMigIvasGrupos.pas',
  inLibMigIvas in 'inLibMigIvas.pas',
  inLibMigEmpresas in 'inLibMigEmpresas.pas',
  inLibMigAlmacenes in 'inLibMigAlmacenes.pas',
  inLibMigClientes in 'inLibMigClientes.pas',
  inLibMigArticulos in 'inLibMigArticulos.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Factuzam Migrator SQL Server';
  Application.CreateForm(TdmMig, dmMig);
  Application.CreateForm(TFormMigrator, FormMigrator);
  Application.Run;
end.
