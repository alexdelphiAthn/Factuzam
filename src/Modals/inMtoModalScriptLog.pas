{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalScriptLog                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de visualizacion del log de ejecucion de scripts SQL.               }
{    Muestra la salida con resaltado de sintaxis y autoscroll.                 }
{******************************************************************************}
unit inMtoModalScriptLog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  SynEdit, SynEditHighlighter, SynHighlighterSQL;

type
  TfrmMtoModalScriptLog = class(TForm)
    pnlBotonera: TPanel;
    btnGuardarComo: TButton;
    LogMemo: TSynEdit;
    LogHigSQL: TSynSQLSyn;
    procedure FormCreate(Sender: TObject);
    procedure btnGuardarComoClick(Sender: TObject);
  public
    procedure AppendLine(const AText: string);
    procedure AppendLines(const ALines: TStrings);
    procedure ScrollToEnd;
  end;

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

procedure TfrmMtoModalScriptLog.btnGuardarComoClick(Sender: TObject);
var
  dlg: TSaveDialog;
begin
  dlg := TSaveDialog.Create(Self);
  try
    dlg.Title := 'Guardar log como...';
    dlg.DefaultExt := 'sql';
    dlg.Filter := 'Archivos SQL (*.sql)|*.sql|' +
                  'Archivos de texto (*.txt)|*.txt|' +
                  'Todos los archivos (*.*)|*.*';
    dlg.FileName := 'log_script_' +
                     FormatDateTime('yyyy_mm_dd_HH_nn_ss', Now);
    if dlg.Execute then
    begin
      LogMemo.Lines.SaveToFile(dlg.FileName, TEncoding.UTF8);
      ShowMessage('Log guardado en ' + dlg.FileName);
    end;
  finally
    dlg.Free;
  end;
end;

end.
