{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoListados                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Listados contables estilo Factuzam con auditoría y exportación XLSX.      }
{******************************************************************************}
unit inMtoListados;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Dialogs, inMtoGen, inLibConfiguracion, inLibListadosTipos,
  Uni, UniDataListados;

type
  TfrmMtoListados = class(TfrmMtoGen)
  private
    FDataModule: TdmListados;
    FListado: TComboBox;
    FFechaDesde: TDateTimePicker;
    FFechaHasta: TDateTimePicker;
    FCuenta: TEdit;
    FBtnConsultar: TButton;
    FBtnExportar: TButton;
    FDialogoGuardar: TSaveDialog;
    procedure AnadirEtiqueta(
      const ATexto: string;
      AIzquierda: Integer;
      AArriba: Integer);
    function ContextoExportacion: string;
    procedure ConsultarClick(Sender: TObject);
    procedure ExportarClick(Sender: TObject);
    function TipoSeleccionado: TTipoListadoContable;
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
  System.SysUtils, System.DateUtils, System.StrUtils, System.UITypes,
  Data.DB, Vcl.Forms, inLibExportadorXlsx;

constructor TfrmMtoListados.Create(AOwner: TComponent);
var
  oTipo: TTipoListadoContable;
begin
  inherited;
  Caption := 'Listados contables';
  Width := 1220;
  Height := 760;
  PanelSuperior.Height := 84;
  BtnActualizar.Visible := False;
  Navegador.Visible := False;
  LblEstado.SetBounds(12, 53, 1160, 20);
  VistaPrincipal.OptionsData.Deleting := False;
  VistaPrincipal.OptionsData.Editing := False;
  VistaPrincipal.OptionsData.Inserting := False;
  VistaPrincipal.OptionsSelection.CellSelect := False;
  AnadirEtiqueta('Listado', 12, 12);
  FListado := TComboBox.Create(Self);
  FListado.Parent := PanelSuperior;
  FListado.SetBounds(68, 7, 300, 27);
  FListado.Style := csDropDownList;
  for oTipo := Low(TTipoListadoContable) to
    High(TTipoListadoContable) do
  begin
    FListado.Items.Add(TituloListado(oTipo));
  end;
  FListado.ItemIndex := 0;
  AnadirEtiqueta('Desde', 390, 12);
  FFechaDesde := TDateTimePicker.Create(Self);
  FFechaDesde.Parent := PanelSuperior;
  FFechaDesde.SetBounds(438, 7, 105, 27);
  AnadirEtiqueta('Hasta', 558, 12);
  FFechaHasta := TDateTimePicker.Create(Self);
  FFechaHasta.Parent := PanelSuperior;
  FFechaHasta.SetBounds(603, 7, 105, 27);
  AnadirEtiqueta('Cuenta', 725, 12);
  FCuenta := TEdit.Create(Self);
  FCuenta.Parent := PanelSuperior;
  FCuenta.SetBounds(782, 7, 150, 27);
  FCuenta.MaxLength := 15;
  FBtnConsultar := TButton.Create(Self);
  FBtnConsultar.Parent := PanelSuperior;
  FBtnConsultar.SetBounds(950, 6, 100, 29);
  FBtnConsultar.Caption := 'Consultar';
  FBtnConsultar.OnClick := ConsultarClick;
  FBtnExportar := TButton.Create(Self);
  FBtnExportar.Parent := PanelSuperior;
  FBtnExportar.SetBounds(1060, 6, 125, 29);
  FBtnExportar.Caption := 'Exportar Excel';
  FBtnExportar.OnClick := ExportarClick;
  FDialogoGuardar := TSaveDialog.Create(Self);
  FDialogoGuardar.DefaultExt := 'xlsx';
  FDialogoGuardar.Filter :=
    'Libro de Excel (*.xlsx)|*.xlsx';
  FDialogoGuardar.Options :=
    [ofOverwritePrompt, ofPathMustExist, ofEnableSizing];
end;

procedure TfrmMtoListados.ActualizarDatos;
var
  oTipo: TTipoListadoContable;
begin
  if FFechaDesde.Date > FFechaHasta.Date then
  begin
    raise EArgumentException.Create(
      'La fecha inicial no puede ser posterior a la final.');
  end;
  oTipo := TipoSeleccionado;
  Seguridad.ExigirPermiso(
    RecursoListado(oTipo),
    'CONSULTAR',
    Configuracion.Empresa);
  FDataModule.Consultar(
    oTipo,
    FFechaDesde.Date,
    FFechaHasta.Date,
    FCuenta.Text);
  AjustarVistaPrincipal;
  LblEstado.Caption := Format(
    '%d registros. Usuario %s. Empresa %s, ejercicio %d.',
    [FDataModule.DataSet.RecordCount,
     Seguridad.UsuarioActual,
     Configuracion.Empresa,
     Configuracion.Ejercicio]);
  Seguridad.RegistrarUsoListado(
    RecursoListado(oTipo),
    'CONSULTAR',
    Configuracion.Empresa,
    Configuracion.Ejercicio,
    FFechaDesde.Date,
    FFechaHasta.Date,
    FCuenta.Text,
    FDataModule.DataSet.RecordCount,
    '');
end;

procedure TfrmMtoListados.AnadirEtiqueta(
  const ATexto: string;
  AIzquierda: Integer;
  AArriba: Integer);
var
  oEtiqueta: TLabel;
begin
  oEtiqueta := TLabel.Create(Self);
  oEtiqueta.Parent := PanelSuperior;
  oEtiqueta.Left := AIzquierda;
  oEtiqueta.Top := AArriba;
  oEtiqueta.Caption := ATexto;
end;

procedure TfrmMtoListados.ConsultarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

function TfrmMtoListados.ContextoExportacion: string;
begin
  Result := Format(
    'Empresa %s | Ejercicio %d | %s a %s | Cuenta %s | Usuario %s',
    [Configuracion.Empresa,
     Configuracion.Ejercicio,
     FormatDateTime('dd/mm/yyyy', FFechaDesde.Date),
     FormatDateTime('dd/mm/yyyy', FFechaHasta.Date),
     IfThen(Trim(FCuenta.Text) = '', 'todas', Trim(FCuenta.Text)),
     Seguridad.UsuarioActual]);
end;

destructor TfrmMtoListados.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoListados.ExportarClick(Sender: TObject);
var
  oTipo: TTipoListadoContable;
  sRuta: string;
begin
  if (FDataModule = nil) or not FDataModule.DataSet.Active then
  begin
    ActualizarDatos;
  end;
  oTipo := TipoSeleccionado;
  Seguridad.ExigirPermiso(
    RecursoListado(oTipo),
    'EXPORTAR',
    Configuracion.Empresa);
  FDialogoGuardar.FileName :=
    RecursoListado(oTipo) + '_' +
    Configuracion.Empresa + '_' +
    IntToStr(Configuracion.Ejercicio) + '.xlsx';
  if FDialogoGuardar.Execute then
  begin
    sRuta := FDialogoGuardar.FileName;
    if not SameText(ExtractFileExt(sRuta), '.xlsx') then
    begin
      sRuta := ChangeFileExt(sRuta, '.xlsx');
    end;
    TExportadorXlsx.Exportar(
      FDataModule.DataSet,
      sRuta,
      TituloListado(oTipo),
      ContextoExportacion);
    Seguridad.RegistrarUsoListado(
      RecursoListado(oTipo),
      'EXPORTAR',
      Configuracion.Empresa,
      Configuracion.Ejercicio,
      FFechaDesde.Date,
      FFechaHasta.Date,
      FCuenta.Text,
      FDataModule.DataSet.RecordCount,
      sRuta);
    MessageDlg(
      'El listado se ha exportado correctamente.',
      mtInformation,
      [mbOK],
      0);
  end;
end;

procedure TfrmMtoListados.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  Seguridad.ExigirPermiso(
    'LISTADOS',
    'ABRIR',
    AConfiguracion.Empresa);
  FDataModule := TdmListados.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  AsignarDataSet(FDataModule.DataSet);
  FFechaDesde.Date := StartOfAYear(
    AConfiguracion.Ejercicio);
  FFechaHasta.Date := EndOfAYear(
    AConfiguracion.Ejercicio);
  LblEstado.Caption :=
    'Selecciona un listado y pulsa Consultar. Cada operación se audita.';
end;

function TfrmMtoListados.TipoSeleccionado: TTipoListadoContable;
begin
  if FListado.ItemIndex < 0 then
  begin
    raise EInvalidOpException.Create(
      'Selecciona el listado que deseas consultar.');
  end;
  Result := TTipoListadoContable(FListado.ItemIndex);
end;

end.
