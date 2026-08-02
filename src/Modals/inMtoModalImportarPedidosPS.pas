{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImportarPedidosPS                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de importacion de pedidos desde PrestaShop.                         }
{    Conecta via API y permite seleccionar los pedidos a importar.             }
{******************************************************************************}
unit inMtoModalImportarPedidosPS;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCheckBox,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGrid, dxSkinsCore, dxSkinBlue, cxContainer, cxMaskEdit,
  cxDropDownEdit, cxListBox, cxCheckListBox, cxNavigator,
  cxPropertiesStore, dxSkinsForm,
  System.Generics.Collections,
  UniDataPedidos, Vcl.Menus, inMtoFrmBase,
  inLibImportacionPedidosIntf;

type
  TfrmModalImportarPedidosPS = class(TfrmBase)
    pnlTop: TPanel;
    pnlMid:  TPanel;
    pnlBottom: TPanel;
    lblBaseURL: TcxLabel;
    edtBaseURL: TcxTextEdit;
    lblApiKey: TcxLabel;
    edtApiKey: TcxTextEdit;
    btnConectar: TcxButton;
    cxgrdPedidos: TcxGrid;
    tvPedidos: TcxGridTableView;
    cxgrdlvlPedidos: TcxGridLevel;
    colSel: TcxGridColumn;
    colId: TcxGridColumn;
    colRef: TcxGridColumn;
    colFecha: TcxGridColumn;
    colCliente: TcxGridColumn;
    colTotal: TcxGridColumn;
    colEstado: TcxGridColumn;
    colImportado: TcxGridColumn;
    btnImportar: TcxButton;
    btnCerrar: TcxButton;
    lblEstado: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnImportarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FResumen: TResumenPedidosImportacion;
    FCasoUsoImportacion: ICasoUsoImportacionPedidos;
  public
    procedure Configurar(ADataModule: TdmPedidos);
  end;

implementation

{$R *.dfm}

uses
  inLibImportacionPedidos,
  inLibPrestaShopPedidosAdaptador,
  UniDataImportacionPedidos,
  inMtoImportacionPedidosVcl;

function CrearContextoImportacionPedidosVcl(
  AFormulario: TfrmModalImportarPedidosPS
): TContextoImportacionPedidosVcl;
begin
  Result := Default(TContextoImportacionPedidosVcl);
  Result.Vista := AFormulario.tvPedidos;
  Result.Estado := AFormulario.lblEstado;
  Result.Resumen := AFormulario.FResumen;
  Result.CasoUso := AFormulario.FCasoUsoImportacion;
  Result.BaseURL := AFormulario.edtBaseURL.Text;
  Result.ApiKey := AFormulario.edtApiKey.Text;
  Result.IndiceSeleccion := AFormulario.colSel.Index;
  Result.IndiceId := AFormulario.colId.Index;
  Result.IndiceReferencia := AFormulario.colRef.Index;
  Result.IndiceFecha := AFormulario.colFecha.Index;
  Result.IndiceCliente := AFormulario.colCliente.Index;
  Result.IndiceTotal := AFormulario.colTotal.Index;
  Result.IndiceEstado := AFormulario.colEstado.Index;
  Result.IndiceImportado := AFormulario.colImportado.Index;
end;

procedure TfrmModalImportarPedidosPS.FormCreate(Sender: TObject);
begin
  inherited;
  FResumen := TResumenPedidosImportacion.Create;
  // Valores por defecto recuperables desde el servicio de parámetros.
  edtBaseURL.Text := 'http://localhost/api';
  edtApiKey.Text  := '';
end;

procedure TfrmModalImportarPedidosPS.btnCerrarClick(Sender: TObject);
begin
  FreeAndNil(FResumen);
  Close;
end;

procedure TfrmModalImportarPedidosPS.btnConectarClick(Sender: TObject);
begin
  TCoordinadorImportacionPedidosVcl.Conectar(
    CrearContextoImportacionPedidosVcl(Self));
end;

procedure TfrmModalImportarPedidosPS.Configurar(
  ADataModule: TdmPedidos);
begin
  FCasoUsoImportacion := CrearCasoUsoImportacionPedidos(
    CrearFabricaFuentePedidosPrestaShop(RegistroLog),
    CrearRepositorioImportacionPedidosUniDAC(ADataModule));
end;

procedure TfrmModalImportarPedidosPS.btnImportarClick(Sender: TObject);
begin
  TCoordinadorImportacionPedidosVcl.Importar(
    CrearContextoImportacionPedidosVcl(Self));
end;

end.
