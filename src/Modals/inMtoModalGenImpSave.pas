{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenImpSave                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para guardar un formato de impresion personalizado.                 }
{    Solicita nombre, descripcion y permisos del nuevo formato.                }
{******************************************************************************}
unit inMtoModalGenImpSave;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFrmBase, dxSkinsForm, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons, dxCore, cxMaskEdit,
  cxDropDownEdit, cxStyles, JvComponentBase, JvEnterTab;

type
  TfrmModalGenImpSave = class(TfrmBase)
    edtNombreOrigen: TcxTextEdit;
    lbl1: TcxLabel;
    edtDescripcion: TcxTextEdit;
    lbl2: TcxLabel;
    lbl3: TcxLabel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    cbbPermisos: TcxComboBox;
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

uses
  inLibGlobalVar, inLibLayoutForm;

type
  TEjecutorPermisoLayoutMto = class(TEjecutorPermisoLayout)
  public
    class function Solicitar(const AFormKey, ADescripcion: string;
                             out APermisos: string): Boolean; override;
  end;

{$R *.dfm}

class function TEjecutorPermisoLayoutMto.Solicitar(
  const AFormKey, ADescripcion: string;
  out APermisos: string): Boolean;
var
  oFormulario: TfrmModalGenImpSave;
begin
  Result := False;
  APermisos := '';
  oFormulario := TfrmModalGenImpSave.Create(Application);
  try
    oFormulario.edtNombreOrigen.Text := AFormKey;
    oFormulario.edtDescripcion.Enabled := False;
    oFormulario.edtDescripcion.Text := ADescripcion;
    oFormulario.ShowModal;
    if oFormulario.sFicha = 'S' then
    begin
      APermisos := oFormulario.cbbPermisos.Text;
      Result := True;
    end;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalGenImpSave.btnCancelarClick(Sender: TObject);
begin
  inherited;
//  PostMessage(Handle, WM_CLOSE, 0, 0);
  ModalResult := mrOk;
end;

procedure TfrmModalGenImpSave.btnGuardarClick(Sender: TObject);
begin
  inherited;
  sFicha := 'S';
//  PostMessage(Handle, WM_CLOSE, 0, 0);
  ModalResult := mrOk;
end;

procedure TfrmModalGenImpSave.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
//  Action := caFree;
end;

procedure TfrmModalGenImpSave.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  with cbbPermisos.Properties.Items do
  begin
    BeginUpdate;
    try
      Clear;
      Add(IdentidadSesion.Usuario);
      Add(IdentidadSesion.Grupo);
      if (IdentidadSesion.GrupoRaiz = 'S') then
        Add(oAll);
      cbbpermisos.Text := IdentidadSesion.Usuario;
    finally
      EndUpdate;
    end;
  end;
end;

initialization
  TSolicitudPermisoLayout.RegistrarEjecutor(
    TEjecutorPermisoLayoutMto);

finalization
  TSolicitudPermisoLayout.RegistrarEjecutor(nil);

end.
