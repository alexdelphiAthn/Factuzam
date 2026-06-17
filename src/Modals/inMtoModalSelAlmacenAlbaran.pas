{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenAlbaran                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.1.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de "Crear albaran desde pedido" (ventas). Permite elegir el         }
{    almacen del que sale la mercancia y, opcionalmente, anadir las lineas     }
{    a un albaran que ya existe en lugar de crear uno nuevo.                   }
{                                                                              }
{    El llamador (inMtoPedidos) calcula el almacen comun de las lineas que     }
{    se van a entregar y lo pasa como defecto:                                 }
{      * Si todas las lineas comparten almacen, el combo aparece ya con        }
{        ese almacen seleccionado (basta con Aceptar).                         }
{      * Si las lineas son de almacenes distintos (o sin almacen), el          }
{        combo aparece vacio y obliga a elegir uno.                            }
{                                                                              }
{    Modo "anadir a albaran existente": si el pedido ya tiene albaranes no     }
{    facturados, el usuario puede marcar la casilla y elegir uno de ellos      }
{    como destino. En ese caso las lineas se agregan a ese albaran (mismo      }
{    cliente y empresa por construccion, ya que proceden del mismo pedido)     }
{    y el almacen elegido solo afecta a las lineas nuevas.                     }
{                                                                              }
{    Devuelve el almacen elegido y, si procede, el albaran destino; la         }
{    generacion la hace UniDataPedidos.CrearAlbaranDesdePedido.                }
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
  cxDBLookupComboBox, cxCheckBox,
  System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni;

type
  TSelAlmacenAlbaranResult = record
    Aceptado      : Boolean;
    CodigoAlmacen : string;
    // Modo "anadir a albaran existente": cuando EsExistente es True, las
    // lineas se agregan al albaran (NumeroAlb / SerieAlb) en lugar de
    // crear uno nuevo.
    EsExistente   : Boolean;
    NumeroAlb     : string;
    SerieAlb      : string;
  end;

  TfrmModalSelAlmacenAlbaran = class(TfrmBase)
    pnlButton:          TPanel;
    btnCancelar:        TcxButton;
    btnAceptar:         TcxButton;
    pnlBody:            TPanel;
    lblPedido:          TLabel;
    lblAlmacen:         TcxLabel;
    cbbAlmacen:         TcxLookupComboBox;
    unqryAlmacenes:     TUniQuery;
    dsAlmacenes:        TDataSource;
    ActionList1:        TActionList;
    actAceptar:         TAction;
    chkAnadirExistente: TcxCheckBox;
    lblAlbaran:         TcxLabel;
    cbbAlbaran:         TcxLookupComboBox;
    unqryAlbaranesPed:  TUniQuery;
    dsAlbaranesPed:     TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure chkAnadirExistenteClick(Sender: TObject);
  private
    FCodigoEmpresa  : string;
    FSeriePed       : string;
    FNumPed         : string;
    FAlmacenDefecto : string;
    FCodigoAlmacen  : string;
    FAceptado       : Boolean;
    FEsExistente    : Boolean;
    FNumeroAlb      : string;
    FSerieAlb       : string;
    procedure CargarAlmacenes;
    procedure CargarAlbaranesPedido;
    procedure ActualizarEstadoControles;
  public
    class function Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoEmpresa,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
  end;

var
  frmModalSelAlmacenAlbaran: TfrmModalSelAlmacenAlbaran;

implementation

uses
  inLibGlobalVar, inLibFormatoDocumento;

{$R *.dfm}

class function TfrmModalSelAlmacenAlbaran.Ejecutar(AOwner: TComponent;
                            const ASeriePed, ANumPed,
                                  ACodigoEmpresa,
                                  ACodigoAlmacenDefecto: string
                           ): TSelAlmacenAlbaranResult;
var
  frm: TfrmModalSelAlmacenAlbaran;
begin
  Result.Aceptado      := False;
  Result.CodigoAlmacen := '';
  Result.EsExistente   := False;
  Result.NumeroAlb     := '';
  Result.SerieAlb      := '';
  frm := TfrmModalSelAlmacenAlbaran.Create(AOwner);
  try
    frm.FCodigoEmpresa  := ACodigoEmpresa;
    frm.FSeriePed       := ASeriePed;
    frm.FNumPed         := ANumPed;
    frm.FAlmacenDefecto := ACodigoAlmacenDefecto;
    frm.ShowModal;
    Result.Aceptado      := frm.FAceptado;
    Result.CodigoAlmacen := frm.FCodigoAlmacen;
    Result.EsExistente   := frm.FEsExistente;
    Result.NumeroAlb     := frm.FNumeroAlb;
    Result.SerieAlb      := frm.FSerieAlb;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSelAlmacenAlbaran.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position  := poScreenCenter;
  FCodigoEmpresa := '';
  FAceptado      := False;
  FCodigoAlmacen := '';
  FEsExistente   := False;
  FNumeroAlb     := '';
  FSerieAlb      := '';
  unqryAlmacenes.Connection    := inLibGlobalVar.oConn;
  unqryAlbaranesPed.Connection := inLibGlobalVar.oConn;
end;

procedure TfrmModalSelAlmacenAlbaran.FormShow(Sender: TObject);
begin
  inherited;
  lblPedido.Caption := 'Crear albarán desde pedido ' +
    FormatearDocumentoEmpresa(FCodigoEmpresa, FSeriePed, FNumPed);
  CargarAlmacenes;
  CargarAlbaranesPedido;
  // Defecto: almacen comun de las lineas a entregar. Si viene vacio
  // (lineas de almacenes distintos o sin almacen) el combo queda en
  // blanco y obliga a elegir.
  if Trim(FAlmacenDefecto) <> '' then
    cbbAlmacen.EditValue := FAlmacenDefecto
  else
    cbbAlmacen.EditValue := Null;
  // Por defecto se crea un albaran nuevo; el usuario decide si lo anade
  // a uno existente.
  chkAnadirExistente.Checked := False;
  ActualizarEstadoControles;
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

procedure TfrmModalSelAlmacenAlbaran.CargarAlbaranesPedido;
begin
  // Albaranes ya creados desde ESTE pedido y no facturados; son los
  // unicos destinos validos para anadir lineas.
  unqryAlbaranesPed.Connection := inLibGlobalVar.oConn;
  if unqryAlbaranesPed.Active then
    unqryAlbaranesPed.Close;
  unqryAlbaranesPed.ParamByName('np').AsString := FNumPed;
  unqryAlbaranesPed.ParamByName('sp').AsString := FSeriePed;
  unqryAlbaranesPed.Open;
  cbbAlbaran.Properties.ListSource := dsAlbaranesPed;
end;

procedure TfrmModalSelAlmacenAlbaran.ActualizarEstadoControles;
var
  bHayAlbaranes: Boolean;
begin
  // Solo se puede anadir a un albaran existente si el pedido tiene
  // alguno no facturado.
  bHayAlbaranes := unqryAlbaranesPed.Active and
                   (unqryAlbaranesPed.RecordCount > 0);
  chkAnadirExistente.Enabled := bHayAlbaranes;
  if not bHayAlbaranes then
    chkAnadirExistente.Checked := False;
  cbbAlbaran.Enabled := chkAnadirExistente.Checked;
  lblAlbaran.Enabled := chkAnadirExistente.Checked;
  if not chkAnadirExistente.Checked then
    cbbAlbaran.EditValue := Null;
end;

procedure TfrmModalSelAlmacenAlbaran.chkAnadirExistenteClick(Sender: TObject);
begin
  inherited;
  ActualizarEstadoControles;
  if chkAnadirExistente.Checked and cbbAlbaran.CanFocus then
    cbbAlbaran.SetFocus;
end;

procedure TfrmModalSelAlmacenAlbaran.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenAlbaran.btnAceptarClick(Sender: TObject);
var
  vAlm: Variant;
  vAlb: Variant;
  sNumAlb: string;
begin
  inherited;
  vAlm := cbbAlmacen.EditValue;
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) or (Trim(VarToStr(vAlm)) = '') then
  begin
    // El almacen es obligatorio: las lineas nuevas necesitan saber de
    // que almacen sale la mercancia (genera los movimientos de salida).
    MessageDlg('Selecciona un almacen.', mtInformation, [mbOk], 0);
    if cbbAlmacen.CanFocus then
      cbbAlmacen.SetFocus;
  end
  else if chkAnadirExistente.Checked then
  begin
    // Modo anadir a un albaran existente: hay que elegir el destino.
    vAlb := cbbAlbaran.EditValue;
    if VarIsNull(vAlb) or VarIsEmpty(vAlb) or (Trim(VarToStr(vAlb)) = '') then
    begin
      MessageDlg('Selecciona el albaran al que anadir las lineas.',
                 mtInformation, [mbOk], 0);
      if cbbAlbaran.CanFocus then
        cbbAlbaran.SetFocus;
    end
    else
    begin
      sNumAlb := VarToStr(vAlb);
      // La serie real se lee de la fila localizada; los albaranes de un
      // pedido comparten serie con el pedido, pero no lo damos por hecho.
      if unqryAlbaranesPed.Locate('NUMERO_ALB', sNumAlb, []) then
        FSerieAlb := unqryAlbaranesPed.FieldByName('SERIE_ALB').AsString
      else
        FSerieAlb := FSeriePed;
      FNumeroAlb     := sNumAlb;
      FEsExistente   := True;
      FCodigoAlmacen := VarToStr(vAlm);
      FAceptado      := True;
      ModalResult    := mrOk;
    end;
  end
  else
  begin
    // Modo clasico: crear un albaran nuevo.
    FEsExistente   := False;
    FNumeroAlb     := '';
    FSerieAlb      := '';
    FCodigoAlmacen := VarToStr(vAlm);
    FAceptado      := True;
    ModalResult    := mrOk;
  end;
end;

end.
