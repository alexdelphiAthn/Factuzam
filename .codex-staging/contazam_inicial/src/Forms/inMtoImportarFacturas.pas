{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoImportarFacturas                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Previsualiza e importa facturas emitidas pendientes de Factuzam.          }
{******************************************************************************}
unit inMtoImportarFacturas;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  inMtoGen, inLibConfiguracion, Uni, UniDataImportadorFacturas;

type
  TfrmMtoImportarFacturas = class(TfrmMtoGen)
  private
    FDataModule: TdmImportadorFacturas;
    FLblDesde: TLabel;
    FLblHasta: TLabel;
    FFechaDesde: TDateTimePicker;
    FFechaHasta: TDateTimePicker;
    FBtnBuscar: TButton;
    FBtnImportar: TButton;
    procedure BuscarClick(Sender: TObject);
    procedure ImportarClick(Sender: TObject);
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
  System.SysUtils, System.DateUtils, System.UITypes, Vcl.Dialogs,
  inLibContabilidadTipos;

constructor TfrmMtoImportarFacturas.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Importar facturas de Factuzam';
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
  FBtnBuscar := TButton.Create(Self);
  FBtnBuscar.Parent := PanelSuperior;
  FBtnBuscar.SetBounds(925, 8, 80, 29);
  FBtnBuscar.Caption := 'Buscar';
  FBtnBuscar.OnClick := BuscarClick;
  FBtnImportar := TButton.Create(Self);
  FBtnImportar.Parent := PanelSuperior;
  FBtnImportar.SetBounds(1013, 8, 145, 29);
  FBtnImportar.Caption := 'Importar pendientes';
  FBtnImportar.OnClick := ImportarClick;
  VistaPrincipal.OptionsData.Deleting := False;
  VistaPrincipal.OptionsData.Editing := False;
  VistaPrincipal.OptionsData.Inserting := False;
  VistaPrincipal.OptionsSelection.CellSelect := False;
end;

procedure TfrmMtoImportarFacturas.ActualizarDatos;
begin
  FDataModule.CargarPendientes(
    FFechaDesde.Date,
    FFechaHasta.Date);
  AjustarVistaPrincipal;
  LblEstado.Caption := Format(
    '%d facturas pendientes de importar.',
    [FDataModule.Pendientes.RecordCount]);
end;

procedure TfrmMtoImportarFacturas.BuscarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

destructor TfrmMtoImportarFacturas.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoImportarFacturas.ImportarClick(Sender: TObject);
var
  oResultado: TResultadoImportacionFacturas;
begin
  if MessageDlg(
       'Las facturas se crearán como borradores. ¿Continuar?',
       mtConfirmation,
       [mbYes, mbNo],
       0) = mrYes then
  begin
    oResultado := FDataModule.ImportarPendientes;
    MessageDlg(
      Format(
        '%d facturas importadas como asientos en borrador.',
        [oResultado.Importadas]),
      mtInformation,
      [mbOK],
      0);
    ActualizarDatos;
  end;
end;

procedure TfrmMtoImportarFacturas.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FDataModule := TdmImportadorFacturas.Create(
    nil,
    AConexion,
    AConfiguracion,
    AConfiguracion.Ejercicio);
  AsignarDataSet(FDataModule.Pendientes);
  FFechaDesde.Date := StartOfTheYear(Date);
  FFechaHasta.Date := EndOfTheYear(Date);
  ActualizarDatos;
end;

end.
