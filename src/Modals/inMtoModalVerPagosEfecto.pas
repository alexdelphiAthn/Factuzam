{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalVerPagosEfecto                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       11/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Muestra el historico de pagos de un efecto (fza_efectos_compra_pagos):    }
{    cada pago con su fecha, importe, tipo, referencia y entidad. Solo         }
{    consulta. Se carga con Cargar(serie, numero, nroEfecto).                  }
{******************************************************************************}
unit inMtoModalVerPagosEfecto;

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
  TfrmModalVerPagosEfecto = class(TfrmBase)
    pnlTop:        TPanel;
    lblInfo:       TcxLabel;
    pnlGrid:       TPanel;
    cxgrdPagos:    TcxGrid;
    tvPagos:       TcxGridDBTableView;
    lvlPagos:      TcxGridLevel;
    colPagNum:     TcxGridDBColumn;
    colPagFecha:   TcxGridDBColumn;
    colPagImporte: TcxGridDBColumn;
    colPagTipo:    TcxGridDBColumn;
    colPagRef:     TcxGridDBColumn;
    colPagEntidad: TcxGridDBColumn;
    pnlButton:     TPanel;
    btnCerrar:     TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConn: TUniConnection;
    FQry:  TUniQuery;
    FDs:   TDataSource;
  public
    procedure Cargar(const ASerieFac, ANumeroFac: string; ANumEfec: Integer;
                     const AInfo: string);
  end;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalVerPagosEfecto.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConn := inLibGlobalVar.oConn;
  FQry := TUniQuery.Create(Self);
  FQry.Connection := FConn;
  FQry.SQL.Text :=
    'SELECT NUMERO_PAGO_EFECPAG, FECHA_EFECPAG, IMPORTE_EFECPAG, ' +
    '       TIPO_EFECPAG, REFERENCIA_EFECPAG, ENTIDAD_PAGO_EFECPAG ' +
    '  FROM fza_efectos_compra_pagos ' +
    ' WHERE SERIE_FACC_EFECPAG  = :s ' +
    '   AND NUMERO_FACC_EFECPAG = :n ' +
    '   AND NUMERO_EFEC_EFECPAG = :e ' +
    ' ORDER BY NUMERO_PAGO_EFECPAG';
  FDs := TDataSource.Create(Self);
  FDs.DataSet := FQry;
  tvPagos.DataController.DataSource := FDs;
end;

procedure TfrmModalVerPagosEfecto.Cargar(const ASerieFac, ANumeroFac: string;
                                         ANumEfec: Integer; const AInfo: string);
begin
  lblInfo.Caption := AInfo;
  FQry.Close;
  FQry.ParamByName('s').AsString  := ASerieFac;
  FQry.ParamByName('n').AsString  := ANumeroFac;
  FQry.ParamByName('e').AsInteger := ANumEfec;
  FQry.Open;
end;

procedure TfrmModalVerPagosEfecto.btnCerrarClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrOk;
end;

initialization
  ForceReferenceToClass(TfrmModalVerPagosEfecto);
end.
