{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPlanContable                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Edición tabular y navegación jerárquica del plan contable.                }
{******************************************************************************}
unit inMtoPlanContable;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  inMtoGen, inLibConfiguracion, Uni, UniDataPlanContable;

type
  TfrmMtoPlanContable = class(TfrmMtoGen)
  private
    FDataModule: TdmPlanContable;
    FArbolCuentas: TTreeView;
    FBtnCargarModelo: TButton;
    FSeparador: TSplitter;
    procedure CargarModeloClick(Sender: TObject);
    procedure DatosCambiados(DataSet: TDataSet);
    procedure SeleccionarCuenta(
      Sender: TObject;
      Node: TTreeNode);
    procedure ReconstruirArbol;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.UITypes,
  Vcl.Dialogs;

constructor TfrmMtoPlanContable.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Plan contable';
  FBtnCargarModelo := TButton.Create(Self);
  FBtnCargarModelo.Parent := PanelSuperior;
  FBtnCargarModelo.SetBounds(610, 8, 180, 29);
  FBtnCargarModelo.Caption := 'Cargar modelo PYMES';
  FBtnCargarModelo.OnClick := CargarModeloClick;
  FArbolCuentas := TTreeView.Create(Self);
  FArbolCuentas.Parent := Self;
  FArbolCuentas.Align := alLeft;
  FArbolCuentas.Width := 390;
  FArbolCuentas.ReadOnly := True;
  FArbolCuentas.OnChange := SeleccionarCuenta;
  FSeparador := TSplitter.Create(Self);
  FSeparador.Parent := Self;
  FSeparador.Align := alLeft;
end;

procedure TfrmMtoPlanContable.CargarModeloClick(Sender: TObject);
begin
  if MessageDlg(
    'Se añadirán únicamente las cuentas que aún no existan. ¿Continuar?',
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes then
  begin
    FDataModule.CargarModeloPymes;
    LblEstado.Caption := 'Modelo PYMES incorporado sin sobrescribir cuentas.';
  end;
end;

procedure TfrmMtoPlanContable.DatosCambiados(DataSet: TDataSet);
begin
  AjustarVistaPrincipal;
  ReconstruirArbol;
end;

destructor TfrmMtoPlanContable.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoPlanContable.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FDataModule := TdmPlanContable.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  AsignarDataSet(FDataModule.DataSet);
  FDataModule.DataSet.AfterOpen := DatosCambiados;
  FDataModule.DataSet.AfterPost := DatosCambiados;
  FDataModule.DataSet.AfterDelete := DatosCambiados;
  FDataModule.Abrir;
  LblEstado.Caption :=
    'Las subcuentas admiten hasta 15 dígitos.';
end;

procedure TfrmMtoPlanContable.ReconstruirArbol;
var
  oNodos: TDictionary<string, TTreeNode>;
  oNodo: TTreeNode;
  oPadre: TTreeNode;
  sCodigo: string;
  sCodigoActual: string;
  sPadre: string;
begin
  if not FDataModule.DataSet.Active then
  begin
    FArbolCuentas.Items.Clear;
  end
  else
  begin
    sCodigoActual :=
      FDataModule.DataSet.FieldByName('CODIGO_CTA').AsString;
    oNodos := TDictionary<string, TTreeNode>.Create;
    FDataModule.DataSet.DisableControls;
    FArbolCuentas.Items.BeginUpdate;
    try
      FArbolCuentas.Items.Clear;
      FDataModule.DataSet.First;
      while not FDataModule.DataSet.Eof do
      begin
        sCodigo :=
          FDataModule.DataSet.FieldByName('CODIGO_CTA').AsString;
        sPadre := FDataModule.DataSet.FieldByName(
          'CODIGO_CTA_PADRE_CTA').AsString;
        oPadre := nil;
        if sPadre <> '' then
        begin
          oNodos.TryGetValue(sPadre, oPadre);
        end;
        oNodo := FArbolCuentas.Items.AddChild(
          oPadre,
          sCodigo + ' - ' +
          FDataModule.DataSet.FieldByName('NOMBRE_CTA').AsString);
        oNodos.AddOrSetValue(sCodigo, oNodo);
        FDataModule.DataSet.Next;
      end;
    finally
      FArbolCuentas.Items.EndUpdate;
      FDataModule.DataSet.EnableControls;
      FreeAndNil(oNodos);
    end;
    FDataModule.DataSet.Locate(
      'CODIGO_CTA',
      sCodigoActual,
      []);
    FArbolCuentas.FullExpand;
  end;
end;

procedure TfrmMtoPlanContable.SeleccionarCuenta(
  Sender: TObject;
  Node: TTreeNode);
var
  iSeparador: Integer;
  sCodigo: string;
begin
  if Node <> nil then
  begin
    iSeparador := Pos(' - ', Node.Text);
    if iSeparador > 0 then
    begin
      sCodigo := Copy(Node.Text, 1, iSeparador - 1);
      FDataModule.DataSet.Locate('CODIGO_CTA', sCodigo, []);
    end;
  end;
end;

end.
