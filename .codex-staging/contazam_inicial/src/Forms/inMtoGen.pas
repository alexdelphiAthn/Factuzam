{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGen                                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Base visual mínima para mantenimientos tabulares de Contazam.             }
{******************************************************************************}
unit inMtoGen;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoFrmBase, cxGrid, cxGridDBTableView, cxGridLevel,
  cxDBNavigator;

type
  TfrmMtoGen = class(TfrmBase)
  private
    FPanelSuperior: TPanel;
    FBtnActualizar: TButton;
    FDataSource: TDataSource;
    FGridPrincipal: TcxGrid;
    FVistaPrincipal: TcxGridDBTableView;
    FNivelPrincipal: TcxGridLevel;
    FNavegador: TcxDBNavigator;
    FLblEstado: TLabel;
    procedure ActualizarClick(Sender: TObject);
  protected
    property BtnActualizar: TButton read FBtnActualizar;
    property DataSource: TDataSource read FDataSource;
    property GridPrincipal: TcxGrid read FGridPrincipal;
    property VistaPrincipal: TcxGridDBTableView read FVistaPrincipal;
    property Navegador: TcxDBNavigator read FNavegador;
    property PanelSuperior: TPanel read FPanelSuperior;
    property LblEstado: TLabel read FLblEstado;
    procedure AsignarDataSet(ADataSet: TDataSet);
    procedure AjustarVistaPrincipal;
    procedure ActualizarDatos; virtual;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  inLibGridDevExpress;

constructor TfrmMtoGen.Create(AOwner: TComponent);
begin
  inherited;
  Width := 1100;
  Height := 700;
  FDataSource := TDataSource.Create(Self);
  FPanelSuperior := TPanel.Create(Self);
  FPanelSuperior.Parent := Self;
  FPanelSuperior.Align := alTop;
  FPanelSuperior.Height := 45;
  FPanelSuperior.BevelOuter := bvNone;
  FBtnActualizar := TButton.Create(Self);
  FBtnActualizar.Parent := FPanelSuperior;
  FBtnActualizar.AlignWithMargins := True;
  FBtnActualizar.Left := 8;
  FBtnActualizar.Top := 8;
  FBtnActualizar.Width := 100;
  FBtnActualizar.Caption := 'Actualizar';
  FBtnActualizar.OnClick := ActualizarClick;
  FNavegador := TcxDBNavigator.Create(Self);
  FNavegador.Parent := FPanelSuperior;
  FNavegador.Left := 120;
  FNavegador.Top := 8;
  FNavegador.Width := 260;
  FNavegador.Height := 27;
  FNavegador.DataSource := FDataSource;
  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := FPanelSuperior;
  FLblEstado.Left := 395;
  FLblEstado.Top := 14;
  FLblEstado.Caption := '';
  FGridPrincipal := CrearGridContazam(
    Self,
    Self,
    FDataSource,
    True,
    FVistaPrincipal,
    FNivelPrincipal);
end;

procedure TfrmMtoGen.ActualizarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

procedure TfrmMtoGen.ActualizarDatos;
begin
  if FDataSource.DataSet <> nil then
  begin
    FDataSource.DataSet.Close;
    FDataSource.DataSet.Open;
    AjustarVistaPrincipal;
  end;
end;

procedure TfrmMtoGen.AsignarDataSet(ADataSet: TDataSet);
begin
  FDataSource.DataSet := ADataSet;
  AjustarVistaPrincipal;
end;

procedure TfrmMtoGen.AjustarVistaPrincipal;
begin
  if Visible then
  begin
    AjustarColumnasContazam(FVistaPrincipal);
  end;
end;

end.

