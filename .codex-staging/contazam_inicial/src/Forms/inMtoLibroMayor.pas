{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLibroMayor                                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta del mayor por fechas y prefijo de cuenta contable.               }
{******************************************************************************}
unit inMtoLibroMayor;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  inMtoGen, inLibConfiguracion, Uni, UniDataLibroMayor;

type
  TfrmMtoLibroMayor = class(TfrmMtoGen)
  private
    FDataModule: TdmLibroMayor;
    FLblDesde: TLabel;
    FLblHasta: TLabel;
    FLblCuenta: TLabel;
    FFechaDesde: TDateTimePicker;
    FFechaHasta: TDateTimePicker;
    FEdtCuenta: TEdit;
    FBtnFiltrar: TButton;
    procedure FiltrarClick(Sender: TObject);
  protected
    procedure ActualizarDatos; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

constructor TfrmMtoLibroMayor.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Libro mayor';
  FLblDesde := TLabel.Create(Self);
  FLblDesde.Parent := PanelSuperior;
  FLblDesde.SetBounds(610, 14, 45, 18);
  FLblDesde.Caption := 'Desde';
  FFechaDesde := TDateTimePicker.Create(Self);
  FFechaDesde.Parent := PanelSuperior;
  FFechaDesde.SetBounds(655, 9, 105, 27);
  FLblHasta := TLabel.Create(Self);
  FLblHasta.Parent := PanelSuperior;
  FLblHasta.SetBounds(770, 14, 40, 18);
  FLblHasta.Caption := 'Hasta';
  FFechaHasta := TDateTimePicker.Create(Self);
  FFechaHasta.Parent := PanelSuperior;
  FFechaHasta.SetBounds(810, 9, 105, 27);
  FLblCuenta := TLabel.Create(Self);
  FLblCuenta.Parent := PanelSuperior;
  FLblCuenta.SetBounds(925, 14, 45, 18);
  FLblCuenta.Caption := 'Cuenta';
  FEdtCuenta := TEdit.Create(Self);
  FEdtCuenta.Parent := PanelSuperior;
  FEdtCuenta.SetBounds(972, 9, 115, 27);
  FBtnFiltrar := TButton.Create(Self);
  FBtnFiltrar.Parent := PanelSuperior;
  FBtnFiltrar.SetBounds(1095, 8, 75, 29);
  FBtnFiltrar.Caption := 'Filtrar';
  FBtnFiltrar.OnClick := FiltrarClick;
end;

procedure TfrmMtoLibroMayor.ActualizarDatos;
begin
  FDataModule.Consultar(
    FFechaDesde.Date,
    FFechaHasta.Date,
    FEdtCuenta.Text);
  AjustarVistaPrincipal;
  LblEstado.Caption := Format(
    '%d movimientos encontrados.',
    [FDataModule.DataSet.RecordCount]);
end;

destructor TfrmMtoLibroMayor.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoLibroMayor.FiltrarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

procedure TfrmMtoLibroMayor.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FDataModule := TdmLibroMayor.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  AsignarDataSet(FDataModule.DataSet);
  FFechaDesde.Date := StartOfTheYear(Date);
  FFechaHasta.Date := EndOfTheYear(Date);
  ActualizarDatos;
end;

end.
