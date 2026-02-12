program Project1;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  ts.core.sqlparser in 'ts.core.sqlparser.pas',
  ts.core.sqlscanner in 'ts.core.sqlscanner.pas',
  ts.core.sqltree in 'ts.core.sqltree.pas',
  ts.editor.codeformatters.sql in 'ts.editor.codeformatters.sql.pas',
  ts.editor.codeformatters in 'ts.editor.codeformatters.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
