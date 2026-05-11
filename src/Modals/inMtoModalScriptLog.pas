unit inMtoModalScriptLog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  SynEdit, SynEditHighlighter, SynHighlighterSQL;

type
  TfrmMtoModalScriptLog = class(TForm)
    LogMemo: TSynEdit;
    LogHigSQL: TSynSQLSyn;
    procedure FormCreate(Sender: TObject);
  public
    procedure AppendLine(const AText: string);
    procedure AppendLines(const ALines: TStrings);
    procedure ScrollToEnd;
  end;

var
  frmMtoModalScriptLog: TfrmMtoModalScriptLog;

implementation

{$R *.dfm}

procedure TfrmMtoModalScriptLog.FormCreate(Sender: TObject);
begin
  LogMemo.Highlighter := LogHigSQL;
  LogHigSQL.SQLDialect := sqlMySQL;
  LogHigSQL.Enabled := True;
end;

procedure TfrmMtoModalScriptLog.AppendLine(const AText: string);
begin
  LogMemo.Lines.Add(AText);
  ScrollToEnd;
end;

procedure TfrmMtoModalScriptLog.AppendLines(const ALines: TStrings);
begin
  LogMemo.Lines.AddStrings(ALines);
  ScrollToEnd;
end;

procedure TfrmMtoModalScriptLog.ScrollToEnd;
begin
  LogMemo.SelStart := Length(LogMemo.Text);
  SendMessage(LogMemo.Handle, EM_SCROLLCARET, 0, 0);
end;

end.
