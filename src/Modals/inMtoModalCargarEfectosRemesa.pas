{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalCargarEfectosRemesa                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       2.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Carga efectos pendientes (sin remesar) en una remesa: nueva o             }
{    existente. Sirve tanto para remesas de COMPRA (pagos) como de VENTA       }
{    (cobros); la variante se elige con CrearParaCompra / CrearParaVenta.      }
{    Sustituye al antiguo }
{    par duplicado inMtoModalCargarEfectosRemesa(Venta).                       }
{******************************************************************************}
unit inMtoModalCargarEfectosRemesa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxButtonEdit, cxMaskEdit, cxDropDownEdit, cxRadioGroup,
  cxCalendar, cxCurrencyEdit, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  inLibCargaEfectosRemesaPersistenciaIntf;

type
  TfrmModalCargarEfectosRemesa = class(TfrmBase)
    pnlTop:          TPanel;
    lblEmpresa:      TcxLabel;
    btnEmpresa:      TcxButtonEdit;
    lblHasta:        TcxLabel;
    dteHasta:        TcxDateEdit;
    btnBuscar:       TcxButton;
    rgModo:          TcxRadioGroup;
    lblRemExistente: TcxLabel;
    cbbRemExistente: TcxComboBox;
    pnlGrid:         TPanel;
    cxgrdEfe:        TcxGrid;
    tvEfe:           TcxGridDBTableView;
    lvlEfe:          TcxGridLevel;
    colSerieFac:     TcxGridDBColumn;
    colNumFac:       TcxGridDBColumn;
    colNumEfe:       TcxGridDBColumn;
    colTercero:      TcxGridDBColumn;
    colVto:          TcxGridDBColumn;
    colPend:         TcxGridDBColumn;
    colEstado:       TcxGridDBColumn;
    pnlButton:       TPanel;
    btnSalir:        TcxButton;
    btnRemesar:      TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnRemesarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnEmpresaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure rgModoPropertiesEditValueChanged(Sender: TObject);
  private
    FTipoRemesa: TTipoCargaEfectosRemesa;
    FRepositorio: IRepositorioCargaEfectosRemesa;
    FConsultaEfectos: IConsultaEfectosRemesa;
    FDsEfe: TDataSource;
    FRemSeries: TStringList;
    FRemNumeros: TStringList;
    FConfirmado: Boolean;
    FRemSerie: string;
    FRemNumero: string;
    procedure ActualizarModo;
    procedure Configurar(ATipo: TTipoCargaEfectosRemesa);
    procedure CargarRemesasAbiertas(const AEmp: string);
    function  CrearRemesaNueva(const AEmp: string;
                               out ASerie, ANumero: string): Boolean;
  public
    procedure PrepararRemesaExistente(const AEmp, ASerie, ANumero: string);
    procedure PrepararNuevaRemesa(const AEmp: string);
    class function CrearParaCompra(AOwner: TComponent):
      TfrmModalCargarEfectosRemesa;
    class function CrearParaVenta(AOwner: TComponent):
      TfrmModalCargarEfectosRemesa;
    property Confirmado:   Boolean read FConfirmado;
    property RemesaSerie:  string  read FRemSerie;
    property RemesaNumero: string  read FRemNumero;
  end;

implementation

uses
  inLibUser, inLibGenBusq, inLibMsgVentas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalCargarEfectosRemesa.CrearParaCompra(
  AOwner: TComponent): TfrmModalCargarEfectosRemesa;
begin
  Result := TfrmModalCargarEfectosRemesa.Create(AOwner);
  Result.Configurar(tcerCompra);
end;

class function TfrmModalCargarEfectosRemesa.CrearParaVenta(
  AOwner: TComponent): TfrmModalCargarEfectosRemesa;
begin
  Result := TfrmModalCargarEfectosRemesa.Create(AOwner);
  Result.Configurar(tcerVenta);
end;

procedure TfrmModalCargarEfectosRemesa.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmado := False;
  FRemSeries  := TStringList.Create;
  FRemNumeros := TStringList.Create;
  FRepositorio := ContextoRepositoriosPantalla.Remesas.
    CrearRepositorioCargaEfectosRemesa;
  FDsEfe := TDataSource.Create(Self);
  tvEfe.DataController.DataSource := FDsEfe;
  rgModo.ItemIndex := 0;
  dteHasta.Clear;
  ActualizarModo;
  // Variante por defecto: compra (comportamiento historico de esta
  // unidad). CrearParaVenta la reconfigura justo despues del Create.
  Configurar(tcerCompra);
end;

procedure TfrmModalCargarEfectosRemesa.Configurar(
  ATipo: TTipoCargaEfectosRemesa);
begin
  FDsEfe.DataSet := nil;
  FConsultaEfectos := nil;
  FTipoRemesa := ATipo;
  if FTipoRemesa = tcerCompra then
    colTercero.Caption := 'Proveedor'
  else
    colTercero.Caption := 'Cliente';
end;

procedure TfrmModalCargarEfectosRemesa.FormDestroy(Sender: TObject);
begin
  FDsEfe.DataSet := nil;
  FConsultaEfectos := nil;
  FRepositorio := nil;
  FreeAndNil(FRemSeries);
  FreeAndNil(FRemNumeros);
  inherited;
end;

procedure TfrmModalCargarEfectosRemesa.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  // Ctrl+Enter sobre empresa abre su caja de busqueda.
  if (Key = VK_RETURN) and (ssCtrl in Shift) and btnEmpresa.Focused then
  begin
    Key := 0;
    btnEmpresaPropertiesButtonClick(btnEmpresa, 0);
  end;
end;

procedure TfrmModalCargarEfectosRemesa.btnEmpresaPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Consulta: IConsultaEfectosRemesa;
  Datos: TDataSet;
  sVal: string;
begin
  inherited;
  Consulta := FRepositorio.ConsultarEmpresas;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       'Buscar empresa', Datos, 'srchEmpRem', Self) then
  begin
    sVal := Datos.FieldByName('CODIGO_EMP_EMP').AsString;
    btnEmpresa.Text := sVal;
  end;
end;

procedure TfrmModalCargarEfectosRemesa.ActualizarModo;
var
  bExistente: Boolean;
begin
  bExistente := rgModo.ItemIndex = 1;
  lblRemExistente.Enabled := bExistente;
  cbbRemExistente.Enabled := bExistente;
end;

procedure TfrmModalCargarEfectosRemesa.rgModoPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarModo;
end;

procedure TfrmModalCargarEfectosRemesa.CargarRemesasAbiertas(
  const AEmp: string);
var
  Remesa: TRemesaAbierta;
  Remesas: TRemesasAbiertas;
begin
  FRemSeries.Clear;
  FRemNumeros.Clear;
  cbbRemExistente.Properties.Items.Clear;
  cbbRemExistente.ItemIndex := -1;
  Remesas := FRepositorio.ListarRemesasAbiertas(FTipoRemesa, AEmp);
  for Remesa in Remesas do
  begin
    FRemSeries.Add(Remesa.Serie);
    FRemNumeros.Add(Remesa.Numero);
    cbbRemExistente.Properties.Items.Add(
      Remesa.Serie + ' / ' + Remesa.Numero + '   (' +
      FormatDateTime('dd/mm/yyyy', Remesa.Fecha) + ')');
  end;
end;

procedure TfrmModalCargarEfectosRemesa.PrepararRemesaExistente(const AEmp,
  ASerie, ANumero: string);
var
  i: Integer;
begin
  btnEmpresa.Text := AEmp;
  rgModo.ItemIndex := 1;
  ActualizarModo;
  btnBuscarClick(btnBuscar);
  for i := 0 to FRemSeries.Count - 1 do
  begin
    if (FRemSeries[i] = ASerie) and (FRemNumeros[i] = ANumero) then
      cbbRemExistente.ItemIndex := i;
  end;
end;

procedure TfrmModalCargarEfectosRemesa.PrepararNuevaRemesa(
  const AEmp: string);
begin
  btnEmpresa.Text := AEmp;
  rgModo.ItemIndex := 0;
  ActualizarModo;
end;

procedure TfrmModalCargarEfectosRemesa.btnBuscarClick(Sender: TObject);
var
  sEmp: string;
  dHasta: TDateTime;
begin
  inherited;
  sEmp := Trim(btnEmpresa.Text);
  if sEmp = '' then
    ShowMessage(SErrorEmpresaEfectosRemesaNoIndicada)
  else
  begin
    // Sin fecha "hasta" -> tope lejano (todos los pendientes).
    if VarIsNull(dteHasta.EditValue) or VarIsEmpty(dteHasta.EditValue) then
      dHasta := EncodeDate(2999, 12, 31)
    else
      dHasta := dteHasta.Date;
    FDsEfe.DataSet := nil;
    FConsultaEfectos := FRepositorio.ConsultarEfectosPendientes(
      FTipoRemesa,
      sEmp,
      dHasta);
    FDsEfe.DataSet := FConsultaEfectos.DataSet;
    CargarRemesasAbiertas(sEmp);
    if FConsultaEfectos.DataSet.IsEmpty then
      ShowMessage(SInfoEfectosPendientesRemesaNoEncontrados);
  end;
end;

function TfrmModalCargarEfectosRemesa.CrearRemesaNueva(const AEmp: string;
  out ASerie, ANumero: string): Boolean;
var
  Resultado: TResultadoCreacionRemesa;
begin
  Resultado := FRepositorio.CrearRemesa(
    FTipoRemesa,
    AEmp,
    IdentidadSesion.Usuario);
  ASerie := Resultado.Serie;
  ANumero := Resultado.Numero;
  Result := Resultado.Creada;
end;

procedure TfrmModalCargarEfectosRemesa.btnRemesarClick(Sender: TObject);
var
  Efectos: TEfectosParaRemesar;
  Resultado: TResultadoCargaEfectosRemesa;
  i, ri, nSel: Integer;
  sSerieRem, sNumRem: string;
  sTextoOmitidos: string;
  bSeguir: Boolean;
begin
  inherited;
  nSel := tvEfe.Controller.SelectedRecordCount;
  bSeguir := True;
  if nSel = 0 then
  begin
    ShowMessage(SErrorEfectosRemesaNoSeleccionados);
    bSeguir := False;
  end;
  sSerieRem := '';
  sNumRem   := '';
  if bSeguir then
  begin
    // Determinar la remesa destino (existente o nueva).
    if rgModo.ItemIndex = 1 then
    begin
      if (cbbRemExistente.ItemIndex < 0) or
         (cbbRemExistente.ItemIndex >= FRemSeries.Count) then
      begin
        ShowMessage(SErrorRemesaExistenteNoSeleccionada);
        bSeguir := False;
      end
      else
      begin
        sSerieRem := FRemSeries[cbbRemExistente.ItemIndex];
        sNumRem   := FRemNumeros[cbbRemExistente.ItemIndex];
      end;
    end
    else
      bSeguir := CrearRemesaNueva(Trim(btnEmpresa.Text), sSerieRem, sNumRem);
  end;
  if bSeguir then
  begin
    SetLength(Efectos, nSel);
    for i := 0 to nSel - 1 do
    begin
      ri := tvEfe.Controller.SelectedRecords[i].RecordIndex;
      Efectos[i].SerieFactura :=
        VarToStr(tvEfe.DataController.Values[ri, colSerieFac.Index]);
      Efectos[i].NumeroFactura :=
        VarToStr(tvEfe.DataController.Values[ri, colNumFac.Index]);
      Efectos[i].NumeroEfecto := StrToIntDef(
        VarToStr(tvEfe.DataController.Values[ri, colNumEfe.Index]),
        0);
    end;
    Resultado := FRepositorio.AnyadirEfectos(
      FTipoRemesa,
      sSerieRem,
      sNumRem,
      Efectos,
      IdentidadSesion.Usuario);
    FRemSerie   := sSerieRem;
    FRemNumero  := sNumRem;
    FConfirmado := Resultado.Procesados > 0;
    if FTipoRemesa = tcerCompra then
      sTextoOmitidos := 'pagados'
    else
      sTextoOmitidos := 'cobrados';
    ShowMessage(Format(SInfoEfectosCargadosRemesa,
      [Resultado.Procesados, sSerieRem, sNumRem, sTextoOmitidos,
       Resultado.Omitidos]));
    if FConfirmado then
      ModalResult := mrOk;
  end;
end;

procedure TfrmModalCargarEfectosRemesa.btnSalirClick(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalCargarEfectosRemesa);
end.
