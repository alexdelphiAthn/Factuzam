{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRepetirModelo                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pregunta que hacer cuando en una sesion de compra se teclea un modelo     }
{    de proveedor que ya existe en otra linea de la MISMA sesion:              }
{      - Repetir en otro color: copia completa (cantidades por talla           }
{        incluidas) dejando vacio el color.                                    }
{      - Otro rango de precios: copia completa repitiendo el color pero        }
{        dejando vacios el coste y el precio de venta.                         }
{      - Cancelar: la linea solo hereda los datos del modelo (REUSAR),         }
{        sin cantidades ni color, como hasta ahora.                            }
{    El caller lee sOpcion tras el ShowModal y libera el form (sin caFree).    }
{******************************************************************************}
unit inMtoModalRepetirModelo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, JvComponentBase,
  JvEnterTab, cxClasses, cxLocalization, Vcl.ExtCtrls, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, Vcl.StdCtrls,
  cxControls, cxContainer, cxEdit, cxLabel, cxButtons,
  System.Actions, Vcl.ActnList;

type
  TfrmModalRepetirModelo = class(TfrmBase)
    pnlButton: TPanel;
    btnCancelar: TcxButton;
    btnOtroPrecio: TcxButton;
    btnOtroColor: TcxButton;
    pnlBody: TPanel;
    lblMensaje: TcxLabel;
    lblOpcionColor: TcxLabel;
    lblOpcionPrecio: TcxLabel;
    lblOpcionCancelar: TcxLabel;
    ActionList1: TActionList;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOtroColorClick(Sender: TObject);
    procedure btnOtroPrecioClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    { Private declarations }
  public
    // 'C' = repetir en otro color, 'P' = otro rango de precios,
    // 'N' = cancelar (solo herencia REUSAR, sin copia completa).
    sOpcion: string;
    procedure PrepararMensaje(const AModelo: string; ALineaOrigen: Integer);
  end;

implementation

{$R *.dfm}

procedure TfrmModalRepetirModelo.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  sOpcion := 'N';
end;

procedure TfrmModalRepetirModelo.FormShow(Sender: TObject);
begin
  inherited;
  if btnOtroColor.CanBeFocused then
    btnOtroColor.SetFocus;
end;

procedure TfrmModalRepetirModelo.PrepararMensaje(const AModelo: string;
  ALineaOrigen: Integer);
begin
  lblMensaje.Caption := Format(
    'El modelo %s ya está en la línea %d de esta sesión. ¿Qué quieres hacer?',
    [AModelo, ALineaOrigen]);
end;

procedure TfrmModalRepetirModelo.btnOtroColorClick(Sender: TObject);
begin
  inherited;
  sOpcion := 'C';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalRepetirModelo.btnOtroPrecioClick(Sender: TObject);
begin
  inherited;
  sOpcion := 'P';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalRepetirModelo.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sOpcion := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalRepetirModelo.actCancelarExecute(Sender: TObject);
begin
  inherited;
  btnCancelarClick(Sender);
end;

end.
