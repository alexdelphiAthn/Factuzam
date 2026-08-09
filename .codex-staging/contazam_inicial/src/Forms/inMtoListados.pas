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
{    Listados con Excel, FastReport y formatos derivados en la BBDD.          }
{******************************************************************************}
unit inMtoListados;

interface

uses
  System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Dialogs, inMtoGen, inLibConfiguracion, inLibListadosTipos,
  Uni, UniDataListados, cxButtons, inLibListadosDerivadosIntf;

type
  TfrmMtoListados = class(TfrmMtoGen)
  private
    FBtnConsultar: TButton;
    FBtnDisenar: TcxButton;
    FBtnExportar: TButton;
    FBtnVistaExcel: TcxButton;
    FBtnVistaPreliminar: TcxButton;
    FConsultaPreparada: Boolean;
    FCuenta: TEdit;
    FDataModule: TdmListados;
    FDialogoGuardar: TSaveDialog;
    FFechaDesde: TDateTimePicker;
    FFechaHasta: TDateTimePicker;
    FFormato: TComboBox;
    FFormatos: TListadosDerivados;
    FListado: TComboBox;
    FRepositorio: IRepositorioListadosDerivados;
    procedure AnadirEtiqueta(
      const ATexto: string;
      AIzquierda: Integer;
      AArriba: Integer);
    procedure AsegurarConsulta;
    procedure ActualizarFormatos;
    procedure CargarPlantilla(
      AStream: TStream;
      const AListado: TListadoDerivado);
    function ContextoDerivados: TContextoListadosDerivados;
    function ContextoExportacion: string;
    procedure ConsultarClick(Sender: TObject);
    procedure DisenarClick(Sender: TObject);
    procedure ExportarClick(Sender: TObject);
    procedure ListadoChange(Sender: TObject);
    function ListadoDerivadoSeleccionado: TListadoDerivado;
    function NombreArchivoXlsx: string;
    procedure SeleccionarFormato(AId: Int64);
    function TipoSeleccionado: TTipoListadoContable;
    procedure VistaExcelClick(Sender: TObject);
    procedure VistaPreliminarClick(Sender: TObject);
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
  System.IOUtils, Data.DB, Vcl.Forms, inLibExportadorXlsx,
  inLibListadoFastReport, inMtoPreviewExcelContazam,
  UniDataListadosDerivados;

constructor TfrmMtoListados.Create(AOwner: TComponent);
var
  oTipo: TTipoListadoContable;
begin
  inherited;
  Caption := 'Listados contables';
  Width := 1220;
  Height := 760;
  PanelSuperior.Height := 124;
  BtnActualizar.Visible := False;
  Navegador.Visible := False;
  LblEstado.SetBounds(12, 96, 1160, 20);
  VistaPrincipal.OptionsData.Deleting := False;
  VistaPrincipal.OptionsData.Editing := False;
  VistaPrincipal.OptionsData.Inserting := False;
  VistaPrincipal.OptionsSelection.CellSelect := False;
  AnadirEtiqueta('Listado', 12, 12);
  FListado := TComboBox.Create(Self);
  FListado.Parent := PanelSuperior;
  FListado.SetBounds(68, 7, 300, 27);
  FListado.Style := csDropDownList;
  FListado.OnChange := ListadoChange;
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
  AnadirEtiqueta('Formato', 12, 56);
  FFormato := TComboBox.Create(Self);
  FFormato.Parent := PanelSuperior;
  FFormato.SetBounds(68, 49, 300, 27);
  FFormato.Style := csDropDownList;
  FFormato.Items.Add('Predeterminado');
  FFormato.ItemIndex := 0;
  FBtnVistaExcel := TcxButton.Create(Self);
  FBtnVistaExcel.Parent := PanelSuperior;
  FBtnVistaExcel.SetBounds(390, 48, 125, 34);
  FBtnVistaExcel.Caption := 'Vista Excel';
  FBtnVistaExcel.OnClick := VistaExcelClick;
  FBtnExportar := TButton.Create(Self);
  FBtnExportar.Parent := PanelSuperior;
  FBtnExportar.SetBounds(525, 49, 125, 32);
  FBtnExportar.Caption := 'Guardar Excel...';
  FBtnExportar.OnClick := ExportarClick;
  FBtnVistaPreliminar := TcxButton.Create(Self);
  FBtnVistaPreliminar.Parent := PanelSuperior;
  FBtnVistaPreliminar.SetBounds(660, 48, 145, 34);
  FBtnVistaPreliminar.Caption := 'Vista preliminar';
  FBtnVistaPreliminar.OnClick := VistaPreliminarClick;
  FBtnDisenar := TcxButton.Create(Self);
  FBtnDisenar.Parent := PanelSuperior;
  FBtnDisenar.SetBounds(815, 48, 175, 34);
  FBtnDisenar.Caption := 'Diseñar y guardar';
  FBtnDisenar.OnClick := DisenarClick;
  FDialogoGuardar := TSaveDialog.Create(Self);
  FDialogoGuardar.DefaultExt := 'xlsx';
  FDialogoGuardar.Filter :=
    'Libro de Excel (*.xlsx)|*.xlsx';
  FDialogoGuardar.Options :=
    [ofOverwritePrompt, ofPathMustExist, ofEnableSizing];
end;

destructor TfrmMtoListados.Destroy;
begin
  FRepositorio := nil;
  FreeAndNil(FDataModule);
  inherited;
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
  FConsultaPreparada := True;
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

procedure TfrmMtoListados.ActualizarFormatos;
var
  iFormato: Integer;
begin
  FFormato.Items.BeginUpdate;
  try
    FFormato.Items.Clear;
    FFormato.Items.Add('Predeterminado');
    SetLength(FFormatos, 0);
    if FRepositorio <> nil then
    begin
      FFormatos := FRepositorio.Listar(ContextoDerivados);
      for iFormato := 0 to Length(FFormatos) - 1 do
      begin
        FFormato.Items.Add(Format(
          '%s [%s, v%d]',
          [FFormatos[iFormato].Nombre,
           LowerCase(FFormatos[iFormato].Alcance.Alcance),
           FFormatos[iFormato].Version]));
      end;
    end;
    FFormato.ItemIndex := 0;
  finally
    FFormato.Items.EndUpdate;
  end;
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

procedure TfrmMtoListados.AsegurarConsulta;
begin
  if not FConsultaPreparada or
    (FDataModule = nil) or
    not FDataModule.DataSet.Active then
  begin
    ActualizarDatos;
  end;
end;

procedure TfrmMtoListados.CargarPlantilla(
  AStream: TStream;
  const AListado: TListadoDerivado);
begin
  if AListado.Id <> 0 then
  begin
    if not FRepositorio.Leer(
      ContextoDerivados,
      AListado.Id,
      AStream) then
    begin
      raise EInvalidOpException.Create(
        'No se ha podido recuperar el formato seleccionado.');
    end;
  end;
end;

procedure TfrmMtoListados.ConsultarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

function TfrmMtoListados.ContextoDerivados:
  TContextoListadosDerivados;
begin
  Result := Default(TContextoListadosDerivados);
  Result.RecursoBase := RecursoListado(TipoSeleccionado);
  Result.Empresa := Configuracion.Empresa;
  Result.Usuario := Seguridad.UsuarioActual;
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

procedure TfrmMtoListados.DisenarClick(Sender: TObject);
var
  oListado: TListadoDerivado;
  oPlantilla: TMemoryStream;
  oServicio: TServicioListadoFastReport;
begin
  AsegurarConsulta;
  Seguridad.ExigirPermiso(
    RecursoListado(TipoSeleccionado),
    'MODIFICAR',
    Configuracion.Empresa);
  oListado := ListadoDerivadoSeleccionado;
  oPlantilla := TMemoryStream.Create;
  oServicio := TServicioListadoFastReport.Create(
    FDataModule.DataSet,
    TituloListado(TipoSeleccionado),
    ContextoExportacion,
    ContextoDerivados,
    FRepositorio);
  try
    CargarPlantilla(oPlantilla, oListado);
    oServicio.Cargar(oPlantilla, oListado);
    if oServicio.Disenar then
    begin
      oListado := oServicio.ListadoGuardado;
      ActualizarFormatos;
      SeleccionarFormato(oListado.Id);
      Seguridad.RegistrarUsoListado(
        RecursoListado(TipoSeleccionado),
        'MODIFICAR',
        Configuracion.Empresa,
        Configuracion.Ejercicio,
        FFechaDesde.Date,
        FFechaHasta.Date,
        FCuenta.Text,
        FDataModule.DataSet.RecordCount,
        'BBDD_' + oListado.Nombre + '.fr3');
      MessageDlg(
        Format(
          'El formato "%s" se ha guardado en la base de datos ' +
          'como versión %d.',
          [oListado.Nombre, oListado.Version]),
        mtInformation,
        [mbOK],
        0);
    end;
  finally
    FreeAndNil(oServicio);
    FreeAndNil(oPlantilla);
  end;
end;

procedure TfrmMtoListados.ExportarClick(Sender: TObject);
var
  oTipo: TTipoListadoContable;
  sRuta: string;
begin
  AsegurarConsulta;
  oTipo := TipoSeleccionado;
  Seguridad.ExigirPermiso(
    RecursoListado(oTipo),
    'EXPORTAR',
    Configuracion.Empresa);
  FDialogoGuardar.FileName := NombreArchivoXlsx;
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
  FRepositorio := CrearRepositorioListadosDerivados(AConexion);
  AsignarDataSet(FDataModule.DataSet);
  FFechaDesde.Date := StartOfAYear(
    AConfiguracion.Ejercicio);
  FFechaHasta.Date := EndOfAYear(
    AConfiguracion.Ejercicio);
  FConsultaPreparada := False;
  ActualizarFormatos;
  LblEstado.Caption :=
    'Selecciona un listado y pulsa Consultar. Cada operación se audita.';
end;

procedure TfrmMtoListados.ListadoChange(Sender: TObject);
begin
  FConsultaPreparada := False;
  ActualizarFormatos;
  LblEstado.Caption :=
    'Selecciona los filtros y pulsa Consultar. Después puedes ' +
    'previsualizar, exportar o diseñar un formato.';
end;

function TfrmMtoListados.ListadoDerivadoSeleccionado:
  TListadoDerivado;
var
  iIndice: Integer;
begin
  Result := Default(TListadoDerivado);
  iIndice := FFormato.ItemIndex - 1;
  if (iIndice >= 0) and (iIndice < Length(FFormatos)) then
  begin
    Result := FFormatos[iIndice];
  end;
end;

function TfrmMtoListados.NombreArchivoXlsx: string;
begin
  Result :=
    RecursoListado(TipoSeleccionado) + '_' +
    Configuracion.Empresa + '_' +
    IntToStr(Configuracion.Ejercicio) + '.xlsx';
end;

procedure TfrmMtoListados.SeleccionarFormato(AId: Int64);
var
  bEncontrado: Boolean;
  iIndice: Integer;
begin
  bEncontrado := False;
  iIndice := 0;
  while (iIndice < Length(FFormatos)) and not bEncontrado do
  begin
    bEncontrado := FFormatos[iIndice].Id = AId;
    if not bEncontrado then
    begin
      Inc(iIndice);
    end;
  end;
  if bEncontrado then
  begin
    FFormato.ItemIndex := iIndice + 1;
  end;
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

procedure TfrmMtoListados.VistaExcelClick(Sender: TObject);
var
  oId: TGUID;
  oPreview: TfrmMtoPreviewExcelContazam;
  sNombre: string;
  sRuta: string;
begin
  AsegurarConsulta;
  Seguridad.ExigirPermiso(
    RecursoListado(TipoSeleccionado),
    'CONSULTAR',
    Configuracion.Empresa);
  CreateGUID(oId);
  sNombre := NombreArchivoXlsx;
  sRuta := TPath.Combine(
    TPath.GetTempPath,
    'contazam_' + GUIDToString(oId) + '.xlsx');
  oPreview := nil;
  try
    TExportadorXlsx.Exportar(
      FDataModule.DataSet,
      sRuta,
      TituloListado(TipoSeleccionado),
      ContextoExportacion);
    oPreview := TfrmMtoPreviewExcelContazam.Create(Self);
    oPreview.Cargar(sRuta, sNombre);
    oPreview.ShowModal;
    Seguridad.RegistrarUsoListado(
      RecursoListado(TipoSeleccionado),
      'CONSULTAR',
      Configuracion.Empresa,
      Configuracion.Ejercicio,
      FFechaDesde.Date,
      FFechaHasta.Date,
      FCuenta.Text,
      FDataModule.DataSet.RecordCount,
      'VISTA_EXCEL');
  finally
    FreeAndNil(oPreview);
    if TFile.Exists(sRuta) then
    begin
      TFile.Delete(sRuta);
    end;
  end;
end;

procedure TfrmMtoListados.VistaPreliminarClick(Sender: TObject);
var
  oListado: TListadoDerivado;
  oPlantilla: TMemoryStream;
  oServicio: TServicioListadoFastReport;
begin
  AsegurarConsulta;
  Seguridad.ExigirPermiso(
    RecursoListado(TipoSeleccionado),
    'CONSULTAR',
    Configuracion.Empresa);
  oListado := ListadoDerivadoSeleccionado;
  oPlantilla := TMemoryStream.Create;
  oServicio := TServicioListadoFastReport.Create(
    FDataModule.DataSet,
    TituloListado(TipoSeleccionado),
    ContextoExportacion,
    ContextoDerivados,
    FRepositorio);
  try
    CargarPlantilla(oPlantilla, oListado);
    oServicio.Cargar(oPlantilla, oListado);
    oServicio.MostrarVistaPrevia;
    Seguridad.RegistrarUsoListado(
      RecursoListado(TipoSeleccionado),
      'CONSULTAR',
      Configuracion.Empresa,
      Configuracion.Ejercicio,
      FFechaDesde.Date,
      FFechaHasta.Date,
      FCuenta.Text,
      FDataModule.DataSet.RecordCount,
      'VISTA_FASTREPORT');
  finally
    FreeAndNil(oServicio);
    FreeAndNil(oPlantilla);
  end;
end;

end.
