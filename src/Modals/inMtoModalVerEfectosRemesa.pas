{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalVerEfectosRemesa                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       11/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Muestra los efectos de una remesa (fza_efectos_compra remesados a ella),  }
{    con su importe, pagado, pendiente y estado. Solo consulta. Se carga con   }
{    Cargar(serieRemesa, numeroRemesa).                                        }
{******************************************************************************}
unit inMtoModalVerEfectosRemesa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid;

type
  TfrmModalVerEfectosRemesa = class(TfrmBase)
    pnlTop:      TPanel;
    lblInfo:     TcxLabel;
    pnlGrid:     TPanel;
    cxgrdEfe:    TcxGrid;
    tvEfe:       TcxGridDBTableView;
    lvlEfe:      TcxGridLevel;
    colSerieFac: TcxGridDBColumn;
    colNumFac:   TcxGridDBColumn;
    colNumEfe:   TcxGridDBColumn;
    colPrv:      TcxGridDBColumn;
    colVto:      TcxGridDBColumn;
    colImporte:  TcxGridDBColumn;
    colPagado:   TcxGridDBColumn;
    colPend:     TcxGridDBColumn;
    colEstado:   TcxGridDBColumn;
    pnlButton:   TPanel;
    btnCerrar:   TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConn: TUniConnection;
    FQry:  TUniQuery;
    FDs:   TDataSource;
  public
    procedure Cargar(const ASerieRem, ANumeroRem, AInfo: string);
  end;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalVerEfectosRemesa.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConn := inLibGlobalVar.oConn;
  FQry := TUniQuery.Create(Self);
  FQry.Connection := FConn;
  FQry.SQL.Text :=
    'SELECT SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC, ' +
    '       RAZON_SOCIAL_PRV_EFEC, FECHA_VENCIMIENTO_EFEC, IMPORTE_EFEC, ' +
    '       IMPORTE_PAGADO_EFEC, IMPORTE_PENDIENTE_EFEC, ESTADO_EFEC ' +
    '  FROM fza_efectos_compra ' +
    ' WHERE SERIE_REMC_EFEC  = :s ' +
    '   AND NUMERO_REMC_EFEC = :n ' +
    ' ORDER BY FECHA_VENCIMIENTO_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC';
  FDs := TDataSource.Create(Self);
  FDs.DataSet := FQry;
  tvEfe.DataController.DataSource := FDs;
end;

procedure TfrmModalVerEfectosRemesa.Cargar(const ASerieRem, ANumeroRem,
                                           AInfo: string);
begin
  lblInfo.Caption := AInfo;
  FQry.Close;
  FQry.ParamByName('s').AsString := ASerieRem;
  FQry.ParamByName('n').AsString := ANumeroRem;
  FQry.Open;
end;

procedure TfrmModalVerEfectosRemesa.btnCerrarClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrOk;
end;

initialization
  ForceReferenceToClass(TfrmModalVerEfectosRemesa);
end.
