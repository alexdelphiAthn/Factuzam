{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVentasWsCola                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta de la cola de ventas WS, intentos HTTP y respuestas.             }
{    Es una pantalla de diagnóstico sin acciones de edición ni reintento.      }
{******************************************************************************}
unit inMtoVentasWsCola;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, cxButtons, cxGrid, cxGridDBTableView,
  cxGridLevel, cxLabel, cxMemo, cxPC,
  inMtoGen, UniDataVentasWsColaMonitor;

type
  TfrmMtoVentasWsCola = class(TfrmMtoGen)
    colIdCola: TcxGridDBColumn;
    colIdEvento: TcxGridDBColumn;
    colEmpresa: TcxGridDBColumn;
    colNombreEmpresa: TcxGridDBColumn;
    colSerie: TcxGridDBColumn;
    colNumero: TcxGridDBColumn;
    colTipo: TcxGridDBColumn;
    colEstado: TcxGridDBColumn;
    colIntentos: TcxGridDBColumn;
    colProximoIntento: TcxGridDBColumn;
    colEnvio: TcxGridDBColumn;
    colIdPeticion: TcxGridDBColumn;
    colErrorCola: TcxGridDBColumn;
    colAlta: TcxGridDBColumn;
    pnlDetalle: TPanel;
    pnlTituloHistorial: TPanel;
    lblHistorial: TcxLabel;
    cxgrdIntentos: TcxGrid;
    tvIntentos: TcxGridDBTableView;
    lvIntentos: TcxGridLevel;
    tvIntentosId: TcxGridDBColumn;
    tvIntentosNumero: TcxGridDBColumn;
    tvIntentosIdPeticion: TcxGridDBColumn;
    tvIntentosMetodo: TcxGridDBColumn;
    tvIntentosRecurso: TcxGridDBColumn;
    tvIntentosHttp: TcxGridDBColumn;
    tvIntentosResultado: TcxGridDBColumn;
    tvIntentosInicio: TcxGridDBColumn;
    tvIntentosDuracion: TcxGridDBColumn;
    pcContenido: TcxPageControl;
    tsPeticion: TcxTabSheet;
    tsRespuesta: TcxTabSheet;
    tsError: TcxTabSheet;
    mPeticion: TcxMemo;
    mRespuesta: TcxMemo;
    mError: TcxMemo;
    btnActualizar: TcxButton;
    btnIrADocumento: TcxButton;
    procedure btnActualizarClick(Sender: TObject);
    procedure btnIrADocumentoClick(Sender: TObject);
  private
    dmmVentasWsCola: TdmVentasWsColaMonitor;
    FIdColaActual: Int64;
    FIdIntentoActual: Int64;
    FPuedeVerDetalle: Boolean;
    procedure ConfigurarSoloLectura;
    procedure ColaDataChange(Sender: TObject; Field: TField);
    procedure IntentoDataChange(Sender: TObject; Field: TField);
    procedure LimpiarContenido;
    procedure MostrarErrorDetalle(const AContexto, AError: string);
  public
    procedure CrearTablaPrincipal; override;
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibFiltroUsuario, inLibPermisosIntf, inLibRegistroPantallas,
  inLibShowMto, UniDataDestinoFacturaRepositorio;

{$R *.dfm}

const
  CPermisoConsultar = 'VentasWsCola.consultar';
  CPermisoDetalle = 'VentasWsCola.detalle';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoVentasWsCola.ConfigurarSoloLectura;
begin
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.Enabled := False;
  actInsertarRegistro.ShortCut := 0;
  actEditarRegistro.Enabled := False;
  actEliminarRegistro.Enabled := False;
  actEliminarRegistro.ShortCut := 0;
  actGrabarRegistro.Enabled := False;
  btnGrabar.Visible := False;
  btnCancelar.Visible := False;
end;

procedure TfrmMtoVentasWsCola.CrearTablaPrincipal;
begin
  inherited;
  dmmVentasWsCola := tdmDataModule as TdmVentasWsColaMonitor;
  pkFieldName := 'ID_VWSC';
  FIdColaActual := -1;
  FIdIntentoActual := -1;
  ConfigurarSoloLectura;
  FPuedeVerDetalle := Assigned(Permisos) and
    Permisos.TienePermiso(CPermisoDetalle, paDenegar);
  pnlDetalle.Visible := FPuedeVerDetalle;
  if FPuedeVerDetalle then
  begin
    tvIntentos.DataController.DataSource := dmmVentasWsCola.dsIntentos;
    dsTablaG.OnDataChange := ColaDataChange;
    dmmVentasWsCola.dsIntentos.OnDataChange := IntentoDataChange;
  end;
  LimpiarContenido;
end;

procedure TfrmMtoVentasWsCola.LimpiarContenido;
begin
  mPeticion.Lines.Clear;
  mRespuesta.Lines.Clear;
  mError.Lines.Clear;
end;

procedure TfrmMtoVentasWsCola.MostrarErrorDetalle(
  const AContexto, AError: string);
begin
  LimpiarContenido;
  mError.Lines.Text := AError;
  pcContenido.ActivePage := tsError;
  RegistroLog.RegistrarError(AContexto + ': ' + AError);
end;

procedure TfrmMtoVentasWsCola.ColaDataChange(
  Sender: TObject; Field: TField);
var
  iIdCola: Int64;
begin
  if FPuedeVerDetalle and Assigned(dmmVentasWsCola) then
  begin
    iIdCola := 0;
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
       not dsTablaG.DataSet.IsEmpty then
      iIdCola := dsTablaG.DataSet.FieldByName('ID_VWSC').AsLargeInt;
    if iIdCola <> FIdColaActual then
    begin
      FIdColaActual := iIdCola;
      FIdIntentoActual := -1;
      LimpiarContenido;
      try
        dmmVentasWsCola.CargarIntentos(iIdCola);
      except
        on E: Exception do
          MostrarErrorDetalle(
            'No se pudo cargar el historial de ventas WS', E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoVentasWsCola.IntentoDataChange(
  Sender: TObject; Field: TField);
var
  iIdIntento: Int64;
  sError: string;
  sPeticion: string;
  sRespuesta: string;
begin
  if FPuedeVerDetalle and Assigned(dmmVentasWsCola) then
  begin
    iIdIntento := 0;
    if dmmVentasWsCola.unqryIntentos.Active and
       not dmmVentasWsCola.unqryIntentos.IsEmpty then
      iIdIntento := dmmVentasWsCola.unqryIntentos.FieldByName(
        'ID_VWSCI').AsLargeInt;
    if iIdIntento <> FIdIntentoActual then
    begin
      FIdIntentoActual := iIdIntento;
      try
        dmmVentasWsCola.LeerContenidoIntento(
          iIdIntento, sPeticion, sRespuesta, sError);
        mPeticion.Lines.Text := sPeticion;
        mRespuesta.Lines.Text := sRespuesta;
        mError.Lines.Text := sError;
      except
        on E: Exception do
          MostrarErrorDetalle(
            'No se pudo cargar el contenido HTTP de ventas WS', E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoVentasWsCola.btnActualizarClick(Sender: TObject);
var
  oCursorAnterior: TCursor;
begin
  oCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    FIdColaActual := -1;
    FIdIntentoActual := -1;
    dmmVentasWsCola.ActualizarCola;
    ColaDataChange(Self, nil);
  finally
    Screen.Cursor := oCursorAnterior;
  end;
end;

procedure TfrmMtoVentasWsCola.btnIrADocumentoClick(Sender: TObject);
var
  sCall: string;
  sNumero: string;
  sSerie: string;
begin
  sNumero := '';
  sSerie := '';
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
  begin
    sNumero := dsTablaG.DataSet.FieldByName(
      'NUMERO_FAC_VWSC').AsString;
    sSerie := dsTablaG.DataSet.FieldByName('SERIE_FAC_VWSC').AsString;
  end;
  if (sNumero <> '') and (sSerie <> '') then
  begin
    sCall := ResolverCallFactura(
      CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
      sNumero,
      sSerie);
    ShowMto(Self.Owner, sCall, sNumero + ',' + sSerie);
  end;
end;

function TfrmMtoVentasWsCola.SqlRestriccionUsuario: string;
begin
  Result := '';
  if (not Assigned(Permisos)) or
     (not Permisos.TienePermiso(CPermisoConsultar, paDenegar)) then
    Result := ' AND 1 = 0'
  else
    Result := SqlFiltroEmpAlmCaja(
      ContextoSesion,
      ParametrosApp,
      'C.CODIGO_EMP_VWSC',
      '',
      '');
end;

procedure TfrmMtoVentasWsCola.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoVentasWsCola);
  ForceReferenceToClass(TfrmMtoVentasWsCola);
end.
