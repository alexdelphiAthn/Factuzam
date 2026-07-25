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
  UniDataPedidos, inLibPresta, inLibPrestaImporter, Vcl.Menus;

type
  TfrmModalImportarPedidosPS = class(TForm)
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
    FResumen: TPrestaPedidoResumenList;
    procedure CargarGridDesdeResumen;
  public
    dmPedidos: TdmPedidos;
  end;

implementation

{$R *.dfm}

procedure TfrmModalImportarPedidosPS.FormCreate(Sender: TObject);
begin
  FResumen := TPrestaPedidoResumenList.Create;
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
  Screen.Cursor := crHourGlass;
  try
    lblEstado.Caption := 'Conectando con PrestaShop...';
    Application.ProcessMessages;
    if ListarPedidosResumen(edtBaseURL.Text, edtApiKey.Text, FResumen) then
    begin
      CargarGridDesdeResumen;
      lblEstado.Caption := Format('Recuperados %d pedidos', [FResumen.Count]);
    end
    else
      lblEstado.Caption := 'No se pudieron recuperar pedidos';
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalImportarPedidosPS.CargarGridDesdeResumen;
var
  i: Integer;
begin
  tvPedidos.DataController.RecordCount := 0;
  tvPedidos.DataController.RecordCount := FResumen.Count;
  for i := 0 to FResumen.Count - 1 do
  begin
    tvPedidos.DataController.Values[i, colSel.Index]   := False;
    tvPedidos.DataController.Values[i, colId.Index]    := FResumen[i].IdPedido;
    tvPedidos.DataController.Values[i, colRef.Index] := FResumen[i].Referencia;
    tvPedidos.DataController.Values[i, colFecha.Index] := FResumen[i].Fecha;
    tvPedidos.DataController.Values[i, colCliente.Index]:= FResumen[i].Cliente;
    tvPedidos.DataController.Values[i, colTotal.Index] := FResumen[i].Total;
    tvPedidos.DataController.Values[i, colEstado.Index]:= FResumen[i].Estado;
    if (dmPedidos <> nil)
       and dmPedidos.ExistePedidoPrestaShop(FResumen[i].IdPedido) then
      tvPedidos.DataController.Values[i, colImportado.Index] := 'S'
    else
      tvPedidos.DataController.Values[i, colImportado.Index] := 'N';
  end;
end;

procedure TfrmModalImportarPedidosPS.btnImportarClick(Sender: TObject);
var
  i, importados, errores: Integer;
  conn: TPrestaConn;
  ord: TOrder;
  sIdPS: string;
begin
  if dmPedidos = nil then
  begin
    ShowMessage('No hay datamodule de pedidos asignado.');
    Exit;
  end;
  importados := 0;
  errores    := 0;
  conn := TPrestaConn.Create(edtBaseURL.Text, edtApiKey.Text);
  try
    Screen.Cursor := crHourGlass;
    for i := 0 to FResumen.Count - 1 do
    begin
      if not Boolean(tvPedidos.DataController.Values[i, colSel.Index]) then
        Continue;
      sIdPS := FResumen[i].IdPedido;
      if dmPedidos.ExistePedidoPrestaShop(sIdPS) then
        Continue;
      lblEstado.Caption := Format('Importando %s...', [sIdPS]);
      Application.ProcessMessages;
      try
        ord := conn.CargarPedido(sIdPS);
        try
          if dmPedidos.ImportarPedidoPrestaShop(ord) then
          begin
            Inc(importados);
            tvPedidos.DataController.Values[i, colImportado.Index] := 'S';
          end;
        finally
          FreeAndNil(ord);
        end;
      except
        on E: Exception do
        begin
          Inc(errores);
          lblEstado.Caption := Format('Error en %s: %s', [sIdPS, E.Message]);
        end;
      end;
    end;
  finally
    FreeAndNil(conn);
    Screen.Cursor := crDefault;
  end;
  ShowMessageFmt('Importación finalizada. Pedidos importados: %d. Errores: %d.',
                 [importados, errores]);
end;

end.
