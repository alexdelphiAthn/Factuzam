program FactuzamTestSqlSrv;

uses
  Vcl.Forms,
  UTestSqlSrv in 'UTestSqlSrv.pas' {frmTestSqlSrv};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Factuzam Test SQL Server (prDirect / prNativeClient)';
  Application.CreateForm(TfrmTestSqlSrv, frmTestSqlSrv);
  Application.Run;
end.
