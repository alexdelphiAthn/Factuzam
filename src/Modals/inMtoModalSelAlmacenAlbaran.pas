{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenAlbaran                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       08/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de "Crear albaran desde pedido" (ventas). Permite elegir el         }
{    almacen del que sale la mercancia del albaran.                            }
{                                                                              }
{    El llamador (inMtoPedidos) calcula el almacen comun de las lineas que     }
{    se van a entregar y lo pasa como defecto:                                 }
{      * Si todas las lineas comparten almacen, el combo aparece ya con        }
{        ese almacen seleccionado (basta con Aceptar).                         }
{      * Si las lineas son de almacenes distintos (o sin almacen), el          }
{        combo aparece vacio y obliga a elegir uno.                            }
{                                                                              }
{    Devuelve el almacen elegido; el albaran y sus lineas se generan           }
{    contra el via UniDataPedidos.CrearAlbaranDesdePedido.                     }
{******************************************************************************}
unit inMtoModalSelAlmacenAlbaran;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoFrmBase,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxButtons, cxContainer, cxEdit, cxLabel, cxTextEdit,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox,
  System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni;

type
  TSelAlmacenAlbaranResult = record
    Aceptado      : Boolean;
    CodigoAlmacen : string;
  end;

  TfrmModalSelAlmacenAlbaran = class(TfrmBase)
    pnlButton:      TPanel;
    btnCancelar:    TcxButton;
    btnAceptar:     TcxButton;
    pnlBody:        TPanel;
    lblPedido:      TLabel;
    lblAlmacen:     TcxLabel;
    cbbAlmacen:     TcxLookupComboBox;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes:    TDataSource;
    ActionList1:    TActionList;
    actAceptar:     TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
  private
    FSeriePed       : string;
    FNumPed         : string;
    FAlmacenDefecto : string;
    FCodigoAlmacen  : string;
    FAceptado       : Boolean;
    procedure CargarAlmacenes;
  public
    class function Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
  end;

var
  frmModalSelAlmacenAlbaran: TfrmModalSelAlmacenAlbaran;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

class function TfrmModalSelAlmacenAlbaran.Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
var
  frm: TfrmModalSelAlmacenAlbaran;
begin
  Result.Aceptado      := False;
  Result.CodigoAlmacen := '';
  frm := TfrmModalSelAlmacenAlbaran.Create(AOwner);
  try
    frm.FSeriePed       := ASeriePed;
    frm.FNumPed         := ANumPed;
    frm.FAlmacenDefecto := ACodigoAlmacenDefecto;
    frm.ShowModal;
    Result.Aceptado      := frm.FAceptado;
    Result.CodigoAlmacen := frm.FCodigoAlmacen;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSelAlmacenAlbaran.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position  := poScreenCenter;
  FAceptado      := False;
  FCodigoAlmacen := '';
  unqryAlmacenes.Connection := inLibGlobalVar.oConn;
end;

procedure TfrmModalSelAlmacenAlbaran.FormShow(Sender: TObject);
begin
  inherited;
  lblPedido.Caption := Format('Crear albaran desde pedido %s/%s',
                              [FSeriePed, FNumPed]);
  CargarAlmacenes;
  // Defecto: almacen comun de las lineas a entregar. Si viene vacio
  // (lineas de almacenes distintos o sin almacen) el combo queda en
  // blanco y obliga a elegir.
  if Trim(FAlmacenDefecto) <> '' then
    cbbAlmacen.EditValue := FAlmacenDefecto
  else
    cbbAlmacen.EditValue := Null;
  if cbbAlmacen.CanFocus then
    cbbAlmacen.SetFocus;
end;

procedure TfrmModalSelAlmacenAlbaran.FormClose(Sender: TObject;
                                               var Action: TCloseAction);
begin
  inherited;
  // caHide: Ejecutar lee los campos tras ShowModal y libera con
  // FreeAndNil. caFree dejaria un puntero colgante (double-free).
  Action := caHide;
end;

procedure TfrmModalSelAlmacenAlbaran.CargarAlmacenes;
begin
  // Combo con todos los almacenes activos.
  unqryAlmacenes.Connection := inLibGlobalVar.oConn;
  if unqryAlmacenes.Active then
    unqryAlmacenes.Close;
  unqryAlmacenes.Open;
  cbbAlmacen.Properties.ListSource := dsAlmacenes;
end;

procedure TfrmModalSelAlmacenAlbaran.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenAlbaran.btnAceptarClick(Sender: TObject);
var
  vAlm: Variant;
begin
  inherited;
  vAlm := cbbAlmacen.EditValue;
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) or (Trim(VarToStr(vAlm)) = '') then
  begin
    MessageDlg('Selecciona un almacen.', mtInformation, [mbOk], 0);
    if cbbAlmacen.CanFocus then
      cbbAlmacen.SetFocus;
  end
  else
  begin
    FCodigoAlmacen := VarToStr(vAlm);
    FAceptado      := True;
    ModalResult    := mrOk;
  end;
end;

end.
