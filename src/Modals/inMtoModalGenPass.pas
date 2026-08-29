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
    procedure AjustarControles;
  public
    sFicha:string;
    class function SolicitarNueva(
      AOwner: TComponent;
      const AUsuario: string;
      out AContrasena: string): Boolean; static;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgConfiguracion;

procedure TfrmModalGenPass.AjustarControles;
var
  iAnchoBotones: Integer;
  iAnchoEtiqueta: Integer;
  iMargen: Integer;
  iSeparacion: Integer;
  iSeparacionBotones: Integer;
begin
  iMargen := MulDiv(24, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacion := MulDiv(12, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iAnchoEtiqueta := lbl1.Width;
  if lbl2.Width > iAnchoEtiqueta then
    iAnchoEtiqueta := lbl2.Width;
  if lbl3.Width > iAnchoEtiqueta then
    iAnchoEtiqueta := lbl3.Width;

  iSeparacionBotones := btnGuardar.Left -
    (btnCancelar.Left + btnCancelar.Width);
  if iSeparacionBotones < iSeparacion then
    iSeparacionBotones := iSeparacion;
  iAnchoBotones := btnCancelar.Width + iSeparacionBotones +
    btnGuardar.Width;

  edtUsuario.Left := iMargen + iAnchoEtiqueta + iSeparacion;
  edtPassword.Left := edtUsuario.Left;
  edtPasswordCon.Left := edtUsuario.Left;
  lbl1.Left := edtUsuario.Left - iSeparacion - lbl1.Width;
  lbl2.Left := edtUsuario.Left - iSeparacion - lbl2.Width;
  lbl3.Left := edtUsuario.Left - iSeparacion - lbl3.Width;
  ClientWidth := edtUsuario.Left + edtUsuario.Width + iMargen;
  if ClientWidth < iAnchoBotones + (2 * iMargen) then
    ClientWidth := iAnchoBotones + (2 * iMargen);
  btnCancelar.Left := (ClientWidth - iAnchoBotones) div 2;
  btnGuardar.Left := btnCancelar.Left + btnCancelar.Width +
    iSeparacionBotones;
end;

procedure TfrmModalGenPass.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sFicha := '';
  ModalResult := mrCancel;
end;

procedure TfrmModalGenPass.btnGuardarClick(Sender: TObject);
begin
  inherited;
  if edtPassword.Text = '' then
  begin
    ShowMessage(SErrorContrasenaUsuarioVacia);
    if edtPassword.CanFocus then
      edtPassword.SetFocus;
  end
  else if (edtPassword.Text <> edtPasswordCon.Text) then
  begin
    ShowMessage(SErrorContrasenasNoCoinciden);
    if edtPasswordCon.CanFocus then
      edtPasswordCon.SetFocus;
  end
  else
  begin
    sFicha := 'S';
    ModalResult := mrOk;
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
  sFicha := '';
end;

class function TfrmModalGenPass.SolicitarNueva(
  AOwner: TComponent;
  const AUsuario: string;
  out AContrasena: string): Boolean;
var
  oFormulario: TfrmModalGenPass;
begin
  AContrasena := '';
  oFormulario := TfrmModalGenPass.Create(AOwner);
  try
    oFormulario.Caption := SCaptionNuevaContrasenaUsuario;
    oFormulario.edtUsuario.Text := AUsuario;
    oFormulario.lbl2.Caption := SCaptionNuevaContrasenaUsuario;
    oFormulario.lbl3.Caption :=
      SCaptionRepetirNuevaContrasenaUsuario;
    oFormulario.btnGuardar.Caption :=
      SCaptionContinuarNuevaContrasena;
    oFormulario.AjustarControles;
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      AContrasena := oFormulario.edtPassword.Text;
  finally
    oFormulario.edtPassword.Text := '';
    oFormulario.edtPasswordCon.Text := '';
    FreeAndNil(oFormulario);
  end;
end;

end.
