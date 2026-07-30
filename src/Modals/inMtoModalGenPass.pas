{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenPass                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal generico de cambio de contrasena de usuario.                        }
{    Valida la confirmacion antes de aceptar el cambio.                        }
{******************************************************************************}
unit inMtoModalGenPass;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsForm, cxClasses,
  cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics, cxControls,
  cxLookAndFeelPainters, cxLabel, cxTextEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons,
  dxCore, cxStyles, JvComponentBase, JvEnterTab;

type
  TfrmModalGenPass = class(TfrmBase)
    edtUsuario: TcxTextEdit;
    lbl1: TcxLabel;
    edtPassword: TcxTextEdit;
    lbl2: TcxLabel;
    edtPasswordCon: TcxTextEdit;
    lbl3: TcxLabel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    sFicha:string;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgConfiguracion;

procedure TfrmModalGenPass.btnCancelarClick(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalGenPass.btnGuardarClick(Sender: TObject);
begin
  inherited;
  if (edtPassword.Text <> edtPasswordCon.Text) then
  begin
    ShowMessage(SErrorContrasenasNoCoinciden);
  end
  else
  begin
    sFicha := 'S';
    PostMessage(Handle, WM_CLOSE, 0, 0);
  end;
end;

procedure TfrmModalGenPass.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmModalGenPass.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

end.
