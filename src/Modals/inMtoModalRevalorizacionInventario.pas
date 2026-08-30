{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRevalorizacionInventario                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Simula la apreciación o depreciación porcentual del PMP de las líneas     }
{    seleccionadas sin modificar el inventario hasta confirmar.                }
{******************************************************************************}
unit inMtoModalRevalorizacionInventario;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxCheckBox,
  cxContainer,
  cxControls,
  cxCurrencyEdit,
  cxEdit,
  cxGrid,
  cxGridCustomTableView,
  cxGridCustomView,
  cxGridDBTableView,
  cxGridLevel,
  cxGridTableView,
  cxLabel,
  cxRadioGroup,
  inLibInventariosRevalorizacion,
  inMtoFrmBase;

type
  TResultadoRevalorizacionInventario = record
    Aceptado: Boolean;
    Simulacion: TSimulacionRevalorizacionInventario;
  end;

  TfrmModalRevalorizacionInventario = class(TfrmBase)
    pnlConfiguracion: TPanel;
    lblExplicacion: TcxLabel;
    lblInventario: TcxLabel;
    rgTipo: TcxRadioGroup;
    lblPorcentaje: TcxLabel;
    curPorcentaje: TcxCurrencyEdit;
    btnSimular: TcxButton;
    btnSeleccionarTodo: TcxButton;
    btnSeleccionarNinguno: TcxButton;
    cxgrdSimulacion: TcxGrid;
    tvSimulacion: TcxGridDBTableView;
    cxgrdlvlSimulacion: TcxGridLevel;
    pnlResumen: TPanel;
    lblNumeroLineas: TcxLabel;
    lblTotalAnterior: TcxLabel;
    curTotalAnterior: TcxCurrencyEdit;
    lblTotalSimulado: TcxLabel;
    curTotalSimulado: TcxCurrencyEdit;
    lblTotalDiferencia: TcxLabel;
    curTotalDiferencia: TcxCurrencyEdit;
    lblAvisos: TcxLabel;
    pnlBotones: TPanel;
    btnCancelar: TcxButton;
    btnPreparar: TcxButton;
    cdsSimulacion: TClientDataSet;
    dsSimulacion: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure btnSimularClick(Sender: TObject);
    procedure btnSeleccionarTodoClick(Sender: TObject);
    procedure btnSeleccionarNingunoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnPrepararClick(Sender: TObject);
    procedure ConfiguracionPropertiesChange(Sender: TObject);
    procedure cdsSimulacionAfterPost(DataSet: TDataSet);
  private
    FActualizando: Boolean;
    FColumnaIndiceBase: TcxGridDBColumn;
    FLineasBase: TLineasBaseRevalorizacionInventario;
    FResultado: TResultadoRevalorizacionInventario;
    FUltimaSimulacion: TSimulacionRevalorizacionInventario;
    procedure AplicarTextos;
    procedure CrearEstructura;
    procedure CrearColumnas;
    procedure CargarLineas;
    procedure MarcarLineas(AMarcar: Boolean);
    function ObtenerLineasVisibles: TArray<Boolean>;
    procedure LimpiarCamposCalculados;
    procedure LimpiarResumen;
    procedure InvalidarSimulacion;
    function TipoSeleccionado: TTipoRevalorizacionInventario;
    function RecogerLineasSeleccionadas:
      TLineasBaseRevalorizacionInventario;
    function CalcularSimulacion: Boolean;
    procedure MostrarSimulacion(
      const ASimulacion: TSimulacionRevalorizacionInventario);
    procedure MostrarResumen(
      const AResumen: TResumenSimulacionRevalorizacionInventario);
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ALineas: TLineasBaseRevalorizacionInventario;
      const AIdentificacionInventario: string):
      TResultadoRevalorizacionInventario;
  end;

implementation

uses
  Vcl.Dialogs,
  Vcl.Graphics,
  cxClasses,
  cxData,
  cxDataStorage,
  cxDBData,
  cxGraphics,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxStyles,
  inLibMsgArticulos,
  inLibMsgComun;

{$R *.dfm}

const
  CAMPO_APLICAR = 'APLICAR';
  CAMPO_INDICE_BASE = 'INDICE_BASE';
  CAMPO_LINEA = 'LINEA';
  CAMPO_ARTICULO = 'ARTICULO';
  CAMPO_SKU = 'SKU';
  CAMPO_DESCRIPCION = 'DESCRIPCION';
  CAMPO_CANTIDAD_TEORICA = 'CANTIDAD_TEORICA';
  CAMPO_CANTIDAD_FISICA = 'CANTIDAD_FISICA';
  CAMPO_PMP_ANTERIOR = 'PMP_ANTERIOR';
  CAMPO_PMP_SIMULADO = 'PMP_SIMULADO';
  CAMPO_VALOR_ANTERIOR = 'VALOR_ANTERIOR';
  CAMPO_VALOR_SIMULADO = 'VALOR_SIMULADO';
  CAMPO_DIFERENCIA = 'DIFERENCIA';

class function TfrmModalRevalorizacionInventario.Ejecutar(
  AOwner: TComponent;
  const ALineas: TLineasBaseRevalorizacionInventario;
  const AIdentificacionInventario: string):
  TResultadoRevalorizacionInventario;
var
  Formulario: TfrmModalRevalorizacionInventario;
begin
  Result := Default(TResultadoRevalorizacionInventario);
  Formulario := TfrmModalRevalorizacionInventario.Create(AOwner);
  try
    Formulario.FLineasBase := Copy(ALineas, 0, Length(ALineas));
    Formulario.lblInventario.Caption := AIdentificacionInventario;
    Formulario.CargarLineas;
    Formulario.ShowModal;
    Result := Formulario.FResultado;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalRevalorizacionInventario.FormCreate(Sender: TObject);
begin
  inherited;
  FActualizando := False;
  FResultado := Default(TResultadoRevalorizacionInventario);
  FUltimaSimulacion := Default(TSimulacionRevalorizacionInventario);
  AplicarTextos;
  CrearEstructura;
  CrearColumnas;
  rgTipo.ItemIndex := 0;
  curPorcentaje.Value := 10;
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.AplicarTextos;
begin
  Caption := STituloRevalorizacionInventario;
  lblExplicacion.Caption := STextoRevalorizacionInventario;
  rgTipo.Caption := SCaptionOperacionRevalorizacionInventario;
  rgTipo.Properties.Items[0].Caption := SCaptionApreciarInventario;
  rgTipo.Properties.Items[1].Caption := SCaptionDepreciarInventario;
  lblPorcentaje.Caption := SCaptionPorcentajeRevalorizacionInventario;
  btnSimular.Caption := SCaptionSimularRevalorizacionInventario;
  btnSeleccionarTodo.Caption :=
    SCaptionSeleccionarTodoRevalorizacionInventario;
  btnSeleccionarNinguno.Caption :=
    SCaptionSeleccionarNingunoRevalorizacionInventario;
  btnPreparar.Caption := SCaptionPrepararPmpRevalorizacionInventario;
  btnCancelar.Caption := SCaptionCancelarEsc;
  lblTotalAnterior.Caption :=
    SCaptionTotalAnteriorRevalorizacionInventario;
  lblTotalSimulado.Caption :=
    SCaptionTotalSimuladoRevalorizacionInventario;
  lblTotalDiferencia.Caption :=
    SCaptionTotalDiferenciaRevalorizacionInventario;
end;

procedure TfrmModalRevalorizacionInventario.CrearEstructura;
begin
  cdsSimulacion.Close;
  cdsSimulacion.FieldDefs.Clear;
  cdsSimulacion.FieldDefs.Add(CAMPO_APLICAR, ftBoolean);
  cdsSimulacion.FieldDefs.Add(CAMPO_INDICE_BASE, ftInteger);
  cdsSimulacion.FieldDefs.Add(CAMPO_LINEA, ftWideString, 8);
  cdsSimulacion.FieldDefs.Add(CAMPO_ARTICULO, ftWideString, 50);
  cdsSimulacion.FieldDefs.Add(CAMPO_SKU, ftWideString, 100);
  cdsSimulacion.FieldDefs.Add(CAMPO_DESCRIPCION, ftWideString, 250);
  cdsSimulacion.FieldDefs.Add(CAMPO_CANTIDAD_TEORICA, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_CANTIDAD_FISICA, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_PMP_ANTERIOR, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_PMP_SIMULADO, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_VALOR_ANTERIOR, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_VALOR_SIMULADO, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_DIFERENCIA, ftCurrency);
  cdsSimulacion.CreateDataSet;
end;

procedure ConfigurarColumnaMonetaria(
  AColumna: TcxGridDBColumn;
  const AFormato: string);
var
  Propiedades: TcxCurrencyEditProperties;
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  Propiedades := TcxCurrencyEditProperties(AColumna.Properties);
  Propiedades.DisplayFormat := AFormato;
  Propiedades.ReadOnly := True;
end;

function CrearColumna(
  AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string;
  AAncho: Integer;
  AEditable: Boolean): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := AAncho;
  Result.Options.Editing := AEditable;
end;

procedure TfrmModalRevalorizacionInventario.CrearColumnas;
var
  Columna: TcxGridDBColumn;
  PropiedadesCheck: TcxCheckBoxProperties;
begin
  tvSimulacion.ClearItems;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_APLICAR,
    SCaptionColAplicarRevalorizacionInventario,
    65,
    True);
  Columna.PropertiesClass := TcxCheckBoxProperties;
  PropiedadesCheck := TcxCheckBoxProperties(Columna.Properties);
  PropiedadesCheck.ValueChecked := True;
  PropiedadesCheck.ValueUnchecked := False;
  FColumnaIndiceBase := CrearColumna(
    tvSimulacion,
    CAMPO_INDICE_BASE,
    '',
    0,
    False);
  FColumnaIndiceBase.Visible := False;
  CrearColumna(
    tvSimulacion,
    CAMPO_LINEA,
    SCaptionColLineaRevalorizacionInventario,
    65,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_ARTICULO,
    SCaptionColArticulo,
    110,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_SKU,
    SCaptionColSku,
    145,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_DESCRIPCION,
    SCaptionColDescripcion,
    220,
    False);
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_CANTIDAD_TEORICA,
    SCaptionColCantidadTeoricaRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.####');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_CANTIDAD_FISICA,
    SCaptionColCantidadFisicaRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.####');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_PMP_ANTERIOR,
    SCaptionColPmpAnteriorRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.0000');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_PMP_SIMULADO,
    SCaptionColPmpSimuladoRevalorizacionInventario,
    100,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.0000');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_VALOR_ANTERIOR,
    SCaptionColValorAnteriorRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.00 €;-#,##0.00 €');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_VALOR_SIMULADO,
    SCaptionColValorSimuladoRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.00 €;-#,##0.00 €');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_DIFERENCIA,
    SCaptionColDiferenciaRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '+#,##0.00 €;-#,##0.00 €');
end;

procedure TfrmModalRevalorizacionInventario.CargarLineas;
var
  iLinea: Integer;
begin
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.EmptyDataSet;
    for iLinea := 0 to High(FLineasBase) do
    begin
      cdsSimulacion.Append;
      cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean := False;
      cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger := iLinea;
      cdsSimulacion.FieldByName(CAMPO_LINEA).AsString :=
        FLineasBase[iLinea].Linea;
      cdsSimulacion.FieldByName(CAMPO_ARTICULO).AsString :=
        FLineasBase[iLinea].CodigoArticulo;
      cdsSimulacion.FieldByName(CAMPO_SKU).AsString :=
        FLineasBase[iLinea].CodigoUnidad;
      cdsSimulacion.FieldByName(CAMPO_DESCRIPCION).AsString :=
        FLineasBase[iLinea].Descripcion;
      cdsSimulacion.FieldByName(CAMPO_CANTIDAD_TEORICA).AsCurrency :=
        FLineasBase[iLinea].CantidadTeorica;
      cdsSimulacion.FieldByName(CAMPO_CANTIDAD_FISICA).AsCurrency :=
        FLineasBase[iLinea].CantidadFisica;
      cdsSimulacion.FieldByName(CAMPO_PMP_ANTERIOR).AsCurrency :=
        FLineasBase[iLinea].PrecioMedioActual;
      cdsSimulacion.Post;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.MarcarLineas(
  AMarcar: Boolean);
var
  EsLineaVisible: TArray<Boolean>;
  IndiceBase: Integer;
  DebeMarcar: Boolean;
begin
  if AMarcar then
    EsLineaVisible := ObtenerLineasVisibles;
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    if cdsSimulacion.State in [dsEdit, dsInsert] then
      cdsSimulacion.Post;
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      IndiceBase :=
        cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger;
      DebeMarcar := False;
      if AMarcar then
        DebeMarcar :=
          (IndiceBase >= 0) and
          (IndiceBase < Length(EsLineaVisible)) and
          EsLineaVisible[IndiceBase];
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean <>
         DebeMarcar then
      begin
        cdsSimulacion.Edit;
        cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean := DebeMarcar;
        cdsSimulacion.Post;
      end;
      cdsSimulacion.Next;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  InvalidarSimulacion;
end;

function TfrmModalRevalorizacionInventario.ObtenerLineasVisibles:
  TArray<Boolean>;
var
  iFila: Integer;
  iIndiceBase: Integer;
  iRegistro: Integer;
begin
  SetLength(Result, Length(FLineasBase));
  for iFila := 0 to tvSimulacion.DataController.FilteredRecordCount - 1 do
  begin
    iRegistro :=
      tvSimulacion.DataController.FilteredRecordIndex[iFila];
    iIndiceBase := tvSimulacion.DataController.Values[
      iRegistro, FColumnaIndiceBase.Index];
    if (iIndiceBase >= 0) and (iIndiceBase < Length(Result)) then
      Result[iIndiceBase] := True;
  end;
end;

procedure TfrmModalRevalorizacionInventario.LimpiarCamposCalculados;
var
  EsMarcadorValido: Boolean;
  Marcador: TBookmark;
begin
  EsMarcadorValido := not cdsSimulacion.IsEmpty;
  if EsMarcadorValido then
    Marcador := cdsSimulacion.GetBookmark;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      if not cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).IsNull then
      begin
        cdsSimulacion.Edit;
        cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).Clear;
        cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).Clear;
        cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).Clear;
        cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).Clear;
        cdsSimulacion.Post;
      end;
      cdsSimulacion.Next;
    end;
  finally
    if EsMarcadorValido then
    begin
      if cdsSimulacion.BookmarkValid(Marcador) then
        cdsSimulacion.GotoBookmark(Marcador);
      cdsSimulacion.FreeBookmark(Marcador);
    end;
    cdsSimulacion.EnableControls;
  end;
end;

procedure TfrmModalRevalorizacionInventario.LimpiarResumen;
begin
  lblNumeroLineas.Caption := Format(
    SFormatoLineasRevalorizacionInventario,
    [0]);
  curTotalAnterior.EditValue := Null;
  curTotalSimulado.EditValue := Null;
  curTotalDiferencia.EditValue := Null;
end;

procedure TfrmModalRevalorizacionInventario.InvalidarSimulacion;
begin
  if not FActualizando then
  begin
    FActualizando := True;
    try
      LimpiarCamposCalculados;
      LimpiarResumen;
      FUltimaSimulacion :=
        Default(TSimulacionRevalorizacionInventario);
      btnPreparar.Enabled := False;
      lblAvisos.Style.Font.Color := clWindowText;
      lblAvisos.Caption :=
        SInfoSimulacionPendienteRevalorizacionInventario;
    finally
      FActualizando := False;
    end;
  end;
end;

function TfrmModalRevalorizacionInventario.TipoSeleccionado:
  TTipoRevalorizacionInventario;
begin
  Result := triApreciacion;
  if rgTipo.ItemIndex = 1 then
    Result := triDepreciacion;
end;

function TfrmModalRevalorizacionInventario.RecogerLineasSeleccionadas:
  TLineasBaseRevalorizacionInventario;
var
  IndiceBase: Integer;
  NumeroSeleccionadas: Integer;
begin
  SetLength(Result, Length(FLineasBase));
  if cdsSimulacion.State in [dsEdit, dsInsert] then
    cdsSimulacion.Post;
  NumeroSeleccionadas := 0;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean then
      begin
        IndiceBase :=
          cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger;
        Result[NumeroSeleccionadas] := FLineasBase[IndiceBase];
        Inc(NumeroSeleccionadas);
      end;
      cdsSimulacion.Next;
    end;
  finally
    cdsSimulacion.EnableControls;
  end;
  SetLength(Result, NumeroSeleccionadas);
end;

function TfrmModalRevalorizacionInventario.CalcularSimulacion: Boolean;
var
  LineasSeleccionadas: TLineasBaseRevalorizacionInventario;
  Tipo: TTipoRevalorizacionInventario;
  Porcentaje: Currency;
begin
  Result := False;
  Tipo := TipoSeleccionado;
  Porcentaje := curPorcentaje.Value;
  if not PorcentajeRevalorizacionValido(Tipo, Porcentaje) then
    ShowMessage(SErrorPorcentajeRevalorizacionInventario)
  else
  begin
    LineasSeleccionadas := RecogerLineasSeleccionadas;
    if Length(LineasSeleccionadas) = 0 then
      ShowMessage(SErrorSeleccionRevalorizacionInventario)
    else
    begin
      FUltimaSimulacion := SimularRevalorizacionInventario(
        LineasSeleccionadas,
        Tipo,
        Porcentaje);
      MostrarSimulacion(FUltimaSimulacion);
      btnPreparar.Enabled := True;
      Result := True;
    end;
  end;
end;

procedure TfrmModalRevalorizacionInventario.MostrarSimulacion(
  const ASimulacion: TSimulacionRevalorizacionInventario);
var
  iLinea: Integer;
begin
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    iLinea := 0;
    while not cdsSimulacion.Eof do
    begin
      cdsSimulacion.Edit;
      cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).Clear;
      cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).Clear;
      cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).Clear;
      cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).Clear;
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean and
         (iLinea < Length(ASimulacion.Lineas)) then
      begin
        cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).AsCurrency :=
          ASimulacion.Lineas[iLinea].PrecioMedioNuevo;
        cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).AsCurrency :=
          ASimulacion.Lineas[iLinea].ValorAnterior;
        cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).AsCurrency :=
          ASimulacion.Lineas[iLinea].ValorNuevo;
        cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).AsCurrency :=
          ASimulacion.Lineas[iLinea].DiferenciaValor;
        Inc(iLinea);
      end;
      cdsSimulacion.Post;
      cdsSimulacion.Next;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  MostrarResumen(ASimulacion.Resumen);
end;

procedure TfrmModalRevalorizacionInventario.MostrarResumen(
  const AResumen: TResumenSimulacionRevalorizacionInventario);
var
  Avisos: TStringList;
begin
  lblNumeroLineas.Caption := Format(
    SFormatoLineasRevalorizacionInventario,
    [AResumen.NumeroLineas]);
  curTotalAnterior.Value := AResumen.ValorAnterior;
  curTotalSimulado.Value := AResumen.ValorNuevo;
  curTotalDiferencia.Value := AResumen.DiferenciaValor;
  Avisos := TStringList.Create;
  try
    if AResumen.LineasConDiferenciaUnidades > 0 then
      Avisos.Add(Format(
        SAvisoDiferenciasUnidadesRevalorizacionInventario,
        [AResumen.LineasConDiferenciaUnidades]));
    if AResumen.LineasConPrecioCorregido > 0 then
      Avisos.Add(Format(
        SAvisoPmpCorregidosRevalorizacionInventario,
        [AResumen.LineasConPrecioCorregido]));
    lblAvisos.Style.Font.Color := clMaroon;
    lblAvisos.Caption := Trim(Avisos.Text);
  finally
    FreeAndNil(Avisos);
  end;
end;

procedure TfrmModalRevalorizacionInventario.btnSimularClick(
  Sender: TObject);
begin
  CalcularSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.btnSeleccionarTodoClick(
  Sender: TObject);
begin
  MarcarLineas(True);
end;

procedure TfrmModalRevalorizacionInventario.btnSeleccionarNingunoClick(
  Sender: TObject);
begin
  MarcarLineas(False);
end;

procedure TfrmModalRevalorizacionInventario.btnCancelarClick(
  Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalRevalorizacionInventario.btnPrepararClick(
  Sender: TObject);
begin
  if CalcularSimulacion then
  begin
    FResultado.Aceptado := True;
    FResultado.Simulacion := FUltimaSimulacion;
    Close;
  end;
end;

procedure TfrmModalRevalorizacionInventario.ConfiguracionPropertiesChange(
  Sender: TObject);
begin
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.cdsSimulacionAfterPost(
  DataSet: TDataSet);
begin
  InvalidarSimulacion;
end;

end.
