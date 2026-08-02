{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArqueosHistCaja                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico de arqueos dentro del TPV (caja). Lista los cierres grabados    }
{    de la caja actual y permite reemitir un DUPLICADO del ticket de arqueo    }
{    o del justificante de cierre en la impresora de tickets.                  }
{    Se abre desde el modal de arqueo (F11) y no recalcula nada: lee de        }
{    fza_caja_arqueos / fza_caja_arqueos_recuento.                             }
{******************************************************************************}
unit inMtoModalArqueosHistCaja;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxCurrencyEdit, cxLabel, cxButtons,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses, cxStyles, dxDateRanges,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, dxScrollbarAnnotations,
  // Acceso a datos
  Uni,
  inMtoFrmBase, inLibArqueoTicket,
  inLibInformesCajaPersistenciaIntf;

type
  TfrmModalArqueosHistCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlSuperior: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdArqueos: TcxGrid;
    dbtvArqueos: TcxGridDBTableView;
    cxgrdlvlArqueos: TcxGridLevel;
    colCodigo: TcxGridDBColumn;
    colDesde: TcxGridDBColumn;
    colHasta: TcxGridDBColumn;
    colFase: TcxGridDBColumn;
    colVentas: TcxGridDBColumn;
    colTotalVentas: TcxGridDBColumn;
    colEfectivo: TcxGridDBColumn;
    colRecuento: TcxGridDBColumn;
    colDiferencia: TcxGridDBColumn;
    colUsuario: TcxGridDBColumn;
    dsArqueos: TDataSource;
    btnDupTicket: TcxButton;
    btnDupCierre: TcxButton;
    btnSalir: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnDupTicketClick(Sender: TObject);
    procedure btnDupCierreClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure dbtvArqueosDblClick(Sender: TObject);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FDatos: TDataSet;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    procedure CargarArqueos;
    function ArqueoSeleccionado: string;
  public
    class procedure Ejecutar(AOwner: TComponent;
                             AConn: TUniConnection;
                             const AEmpresa: string;
                             const AAlmacen: string;
                             const ACaja: string);
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmModalArqueosHistCaja }

class procedure TfrmModalArqueosHistCaja.Ejecutar(AOwner: TComponent;
                                                  AConn: TUniConnection;
                                                  const AEmpresa: string;
                                                  const AAlmacen: string;
                                                  const ACaja: string);
var
  Frm: TfrmModalArqueosHistCaja;
begin
  Frm := TfrmModalArqueosHistCaja.Create(AOwner);
  try
    Frm.FConn    := AConn;
    Frm.FRepositorioPersistencia :=
      Frm.ContextoRepositoriosPantalla.Caja.CrearRepositorioInformesCaja(AConn);
    Frm.FEmpresa := AEmpresa;
    Frm.FAlmacen := AAlmacen;
    Frm.FCaja    := ACaja;
    Frm.ShowModal;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmModalArqueosHistCaja.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
end;

procedure TfrmModalArqueosHistCaja.FormDestroy(Sender: TObject);
begin
  dsArqueos.DataSet := nil;
  FDatos := nil;
  FResultado := nil;
  FRepositorioPersistencia := nil;
  inherited;
end;

procedure TfrmModalArqueosHistCaja.FormShow(Sender: TObject);
begin
  inherited;
  lblTitulo.Caption := Format(STituloHistoricoArqueosCaja, [FCaja]);
  CargarArqueos;
  // Ajustar el ancho de las columnas al contenido al presentar la pantalla.
  dbtvArqueos.ApplyBestFit;
end;

procedure TfrmModalArqueosHistCaja.CargarArqueos;
begin
  if (FConn = nil) or (not FConn.Connected) then
    Exit;
  dsArqueos.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorioPersistencia.ConsultarArqueosHistorico(
    FEmpresa,
    FAlmacen,
    FCaja);
  FDatos := FResultado.DataSet;
  dsArqueos.DataSet := FDatos;
end;

function TfrmModalArqueosHistCaja.ArqueoSeleccionado: string;
begin
  Result := '';
  if Assigned(FDatos) and FDatos.Active and (not FDatos.IsEmpty) then
  begin
    Result := FDatos.FieldByName('CODIGO_ARQ').AsString;
  end;
end;

procedure TfrmModalArqueosHistCaja.btnDupTicketClick(Sender: TObject);
var
  sCod: string;
begin
  sCod := ArqueoSeleccionado;
  if sCod = '' then
  begin
    ShowMessage(SErrorArqueoCajaNoSeleccionado);
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    TArqueoTicket.ImprimirDesdeHistorico(
      PreviewTicket,
      ContextoRepositoriosPantalla.TicketsCaja.
        CrearRepositorioArqueoCaja(FConn),
      ContextoRepositoriosPantalla.TicketsCaja.
        CrearRepositorioArqueoTicket(FConn),
      ParametrosCaja,
      FEmpresa,
      FAlmacen,
      FCaja,
      sCod,
      ParametrosCaja.ImpresoraCaja);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalArqueosHistCaja.btnDupCierreClick(Sender: TObject);
var
  sCod: string;
begin
  sCod := ArqueoSeleccionado;
  if sCod = '' then
  begin
    ShowMessage(SErrorArqueoCajaNoSeleccionado);
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    TArqueoTicket.ImprimirCierreDesdeHistorico(
      PreviewTicket,
      ContextoRepositoriosPantalla.TicketsCaja.
        CrearRepositorioArqueoTicket(FConn),
      ContextoSesion,
      FEmpresa,
      FAlmacen,
      FCaja,
      sCod,
      ParametrosCaja.ImpresoraCaja);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalArqueosHistCaja.dbtvArqueosDblClick(Sender: TObject);
begin
  // Doble clic = duplicado del cierre (el documento más completo).
  btnDupCierreClick(Sender);
end;

procedure TfrmModalArqueosHistCaja.btnSalirClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueosHistCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F2:
      begin
        Key := 0;
        btnDupTicketClick(Self);
      end;
    VK_F3:
      begin
        Key := 0;
        btnDupCierreClick(Self);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        Close;
      end;
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalArqueosHistCaja);
end.
