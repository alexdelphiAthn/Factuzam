unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ts.editor.codeformatters.sql, ts.editor.codeformatters;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  Formatter: ICodeFormatter;
  SQLOriginal: string;
  SQLFormateado: string;
begin
  SQLOriginal := Memo1.Text;
  if Trim(SQLOriginal) = '' then
  begin
    ShowMessage('No hay SQL para formatear');
    Exit;
  end;
  try
    Formatter := TSQLFormatter.Create;
    SQLFormateado := Formatter.Format(SQLOriginal);
    if SQLFormateado <> '' then
      Memo1.Text := SQLFormateado
    else
      ShowMessage('No se pudo formatear el SQL. Verifica la sintaxis.');
  except
    on E: Exception do
      ShowMessage('Error al formatear: ' + E.Message + sLineBreak +
                  'El SQL original permanece sin cambios.');
  end;
end;

end.
