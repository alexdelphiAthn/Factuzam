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
{    existente. Sirve tanto para remesas de COMPRA (pagos, PRC_REMC_*)         }
{    como de VENTA (cobros, PRC_REMV_*): la variante se elige con              }
{    Configurar / CrearParaCompra / CrearParaVenta. Sustituye al antiguo       }
{    par duplicado inMtoModalCargarEfectosRemesa(Venta).                       }
{******************************************************************************}
unit inMtoModalCargarEfectosRemesa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxButtonEdit, cxMaskEdit, cxDropDownEdit, cxRadioGroup,
  cxCalendar, cxCurrencyEdit, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid;

type
  // Todo lo que distingue una remesa de compra (pagos a proveedor) de
  // una de venta (cobros a cliente): tablas, sufijos de campo, SPs y
  // textos. El SELECT de efectos usa alias neutros (SERIE_FAC_EFECTO,
  // TERCERO_EFECTO...) para que el mismo dfm sirva a ambas variantes.
  TConfigRemesa = record
    TablaEfectos:   string;  // fza_efectos_compra / fza_efectos_venta
    TablaRemesas:   string;  // fza_remesas_compra / fza_remesas_venta
    SufEfecto:      string;  // EFEC / EFV
    SufRemesa:      string;  // REMC / REMV
    CampoSerieFac:  string;  // SERIE_FACC_EFEC / SERIE_FAC_EFV
    CampoNumeroFac: string;  // NUMERO_FACC_EFEC / NUMERO_FAC_EFV
    CampoTercero:   string;  // RAZON_SOCIAL_PRV_EFEC / RAZON_SOCIAL_CLI_EFV
    TituloTercero:  string;  // Proveedor / Cliente
    SPCrear:        string;  // PRC_REMC_CREAR / PRC_REMV_CREAR
    SPAnyadir:      string;  // PRC_REMC_ANYADIR_EFECTO / PRC_REMV_...
    ParamNumEfecto: string;  // p_NUM_EFEC / p_NUM_EFV
    TextoOmitidos:  string;  // pagados / cobrados
  end;

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
    // Campos primero (E2169).
    FConfig:     TConfigRemesa;
    FConn:       TUniConnection;
    FQryEfe:     TUniQuery;
    FDsEfe:      TDataSource;
    FQryRem:     TUniQuery;
    FRemSeries:  TStringList;
    FRemNumeros: TStringList;
    FConfirmado: Boolean;
    FRemSerie:   string;
    FRemNumero:  string;
    procedure ActualizarModo;
    procedure CargarRemesasAbiertas(const AEmp: string);
    function  CrearRemesaNueva(const AEmp: string;
                               out ASerie, ANumero: string): Boolean;
  public
    // Aplica la variante (compra/venta): reescribe el SQL de efectos y
    // la cabecera de la columna del tercero. Se puede llamar tras
    // Create; los CrearPara* ya la dejan aplicada.
    procedure Configurar(const AConfig: TConfigRemesa);
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

function ConfigRemesaCompra: TConfigRemesa;
function ConfigRemesaVenta: TConfigRemesa;

implementation

uses
  inLibUser, inLibGenBusq, inLibMsgVentas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function ConfigRemesaCompra: TConfigRemesa;
begin
  Result.TablaEfectos   := 'fza_efectos_compra';
  Result.TablaRemesas   := 'fza_remesas_compra';
  Result.SufEfecto      := 'EFEC';
  Result.SufRemesa      := 'REMC';
  Result.CampoSerieFac  := 'SERIE_FACC_EFEC';
  Result.CampoNumeroFac := 'NUMERO_FACC_EFEC';
  Result.CampoTercero   := 'RAZON_SOCIAL_PRV_EFEC';
  Result.TituloTercero  := 'Proveedor';
  Result.SPCrear        := 'PRC_REMC_CREAR';
  Result.SPAnyadir      := 'PRC_REMC_ANYADIR_EFECTO';
  Result.ParamNumEfecto := 'p_NUM_EFEC';
  Result.TextoOmitidos  := 'pagados';
end;

function ConfigRemesaVenta: TConfigRemesa;
begin
  Result.TablaEfectos   := 'fza_efectos_venta';
  Result.TablaRemesas   := 'fza_remesas_venta';
  Result.SufEfecto      := 'EFV';
  Result.SufRemesa      := 'REMV';
  Result.CampoSerieFac  := 'SERIE_FAC_EFV';
  Result.CampoNumeroFac := 'NUMERO_FAC_EFV';
  Result.CampoTercero   := 'RAZON_SOCIAL_CLI_EFV';
  Result.TituloTercero  := 'Cliente';
  Result.SPCrear        := 'PRC_REMV_CREAR';
  Result.SPAnyadir      := 'PRC_REMV_ANYADIR_EFECTO';
  Result.ParamNumEfecto := 'p_NUM_EFV';
  Result.TextoOmitidos  := 'cobrados';
end;

class function TfrmModalCargarEfectosRemesa.CrearParaCompra(
  AOwner: TComponent): TfrmModalCargarEfectosRemesa;
begin
  Result := TfrmModalCargarEfectosRemesa.Create(AOwner);
  Result.Configurar(ConfigRemesaCompra);
end;

class function TfrmModalCargarEfectosRemesa.CrearParaVenta(
  AOwner: TComponent): TfrmModalCargarEfectosRemesa;
begin
  Result := TfrmModalCargarEfectosRemesa.Create(AOwner);
  Result.Configurar(ConfigRemesaVenta);
end;

procedure TfrmModalCargarEfectosRemesa.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmado := False;
  FRemSeries  := TStringList.Create;
  FRemNumeros := TStringList.Create;
  FConn := ConexionPrincipal;
  FQryEfe := TUniQuery.Create(Self);
  FQryEfe.Connection := FConn;
  FDsEfe := TDataSource.Create(Self);
  FDsEfe.DataSet := FQryEfe;
  tvEfe.DataController.DataSource := FDsEfe;
  FQryRem := TUniQuery.Create(Self);
  FQryRem.Connection := FConn;
  rgModo.ItemIndex := 0;
  dteHasta.Clear;
  ActualizarModo;
  // Variante por defecto: compra (comportamiento historico de esta
  // unidad). CrearParaVenta la reconfigura justo despues del Create.
  Configurar(ConfigRemesaCompra);
end;

procedure TfrmModalCargarEfectosRemesa.Configurar(
  const AConfig: TConfigRemesa);
begin
  FConfig := AConfig;
  colTercero.Caption := FConfig.TituloTercero;
  // Efectos candidatos: pendientes, sin remesar, de la empresa, hasta
  // vto. Alias neutros para que el dfm valga en compra y en venta.
  FQryEfe.Close;
  FQryEfe.SQL.Text :=
    'SELECT ' + FConfig.CampoSerieFac + ' AS SERIE_FAC_EFECTO, ' +
    '       ' + FConfig.CampoNumeroFac + ' AS NUMERO_FAC_EFECTO, ' +
    '       NUMERO_' + FConfig.SufEfecto + ' AS NUMERO_EFECTO, ' +
    '       ' + FConfig.CampoTercero + ' AS TERCERO_EFECTO, ' +
    '       FECHA_VENCIMIENTO_' + FConfig.SufEfecto +
    '         AS FECHA_VENCIMIENTO_EFECTO, ' +
    '       IMPORTE_PENDIENTE_' + FConfig.SufEfecto +
    '         AS IMPORTE_PENDIENTE_EFECTO, ' +
    '       ESTADO_' + FConfig.SufEfecto + ' AS ESTADO_EFECTO ' +
    '  FROM ' + FConfig.TablaEfectos + ' ' +
    ' WHERE CODIGO_EMP_' + FConfig.SufEfecto + ' = :emp ' +
    '   AND SERIE_' + FConfig.SufRemesa + '_' + FConfig.SufEfecto +
    '       IS NULL ' +
    '   AND COALESCE(ESTADO_' + FConfig.SufEfecto + ', ' +
    QuotedStr('') + ') IN (' + QuotedStr('PENDIENTE') + ', ' +
    QuotedStr('PARCIAL') + ') ' +
    '   AND COALESCE(IMPORTE_PENDIENTE_' + FConfig.SufEfecto +
    ', 0) > 0 ' +
    '   AND FECHA_VENCIMIENTO_' + FConfig.SufEfecto + ' <= :hasta ' +
    ' ORDER BY FECHA_VENCIMIENTO_' + FConfig.SufEfecto + ', ' +
    FConfig.CampoTercero;
end;

procedure TfrmModalCargarEfectosRemesa.FormDestroy(Sender: TObject);
begin
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
  sVal: string;
begin
  inherited;
  if BusquedaVisual.EjecutarBusqueda(ConexionPrincipal, 'Buscar empresa',
       'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP',
       'CODIGO_EMP_EMP', sVal, 'srchEmpRem', Self) then
    btnEmpresa.Text := sVal;
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
begin
  FRemSeries.Clear;
  FRemNumeros.Clear;
  cbbRemExistente.Properties.Items.Clear;
  cbbRemExistente.ItemIndex := -1;
  FQryRem.Close;
  FQryRem.SQL.Text :=
    'SELECT SERIE_' + FConfig.SufRemesa + ' AS SERIE_REMESA, ' +
    '       NUMERO_' + FConfig.SufRemesa + ' AS NUMERO_REMESA, ' +
    '       FECHA_' + FConfig.SufRemesa + ' AS FECHA_REMESA, ' +
    '       TOTAL_' + FConfig.SufRemesa + ' AS TOTAL_REMESA ' +
    '  FROM ' + FConfig.TablaRemesas + ' ' +
    ' WHERE CODIGO_EMP_' + FConfig.SufRemesa + ' = :emp ' +
    '   AND COALESCE(ESTADO_' + FConfig.SufRemesa + ', ' +
    QuotedStr('') + ') IN (' + QuotedStr('ABIERTA') + ', ' +
    QuotedStr('CERRADA') + ') ' +
    ' ORDER BY FECHA_' + FConfig.SufRemesa + ' DESC, ' +
    '          NUMERO_' + FConfig.SufRemesa + ' DESC';
  FQryRem.ParamByName('emp').AsString := AEmp;
  FQryRem.Open;
  while not FQryRem.Eof do
  begin
    FRemSeries.Add(FQryRem.FieldByName('SERIE_REMESA').AsString);
    FRemNumeros.Add(FQryRem.FieldByName('NUMERO_REMESA').AsString);
    cbbRemExistente.Properties.Items.Add(
      FQryRem.FieldByName('SERIE_REMESA').AsString + ' / ' +
      FQryRem.FieldByName('NUMERO_REMESA').AsString + '   (' +
      FormatDateTime('dd/mm/yyyy',
        FQryRem.FieldByName('FECHA_REMESA').AsDateTime) + ')');
    FQryRem.Next;
  end;
  FQryRem.Close;
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
    FQryEfe.Close;
    FQryEfe.ParamByName('emp').AsString     := sEmp;
    FQryEfe.ParamByName('hasta').AsDateTime := dHasta;
    FQryEfe.Open;
    CargarRemesasAbiertas(sEmp);
    if FQryEfe.IsEmpty then
      ShowMessage(SInfoEfectosPendientesRemesaNoEncontrados);
  end;
end;

function TfrmModalCargarEfectosRemesa.CrearRemesaNueva(const AEmp: string;
  out ASerie, ANumero: string): Boolean;
var
  sp: TUniStoredProc;
begin
  ASerie  := '';
  ANumero := '';
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection     := FConn;
    sp.StoredProcName := FConfig.SPCrear;
    sp.Params.Clear;
    sp.Params.CreateParam(ftString, 'p_EMPRESA',    ptInput);
    sp.Params.CreateParam(ftString, 'p_IBAN',       ptInput);
    sp.Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    sp.Params.CreateParam(ftString, 'p_SERIE_OUT',  ptOutput);
    sp.Params.CreateParam(ftString, 'p_NUMERO_OUT', ptOutput);
    sp.ParamByName('p_EMPRESA').AsString := AEmp;
    sp.ParamByName('p_IBAN').AsString    := '';
    sp.ParamByName('p_USUARIO').AsString := IdentidadSesion.Usuario;
    sp.ExecProc;
    ASerie  := sp.ParamByName('p_SERIE_OUT').AsString;
    ANumero := sp.ParamByName('p_NUMERO_OUT').AsString;
    Result  := ANumero <> '';
  finally
    FreeAndNil(sp);
  end;
end;

procedure TfrmModalCargarEfectosRemesa.btnRemesarClick(Sender: TObject);
var
  i, ri, nOk, nSkip, nSel, res: Integer;
  sSerieRem, sNumRem: string;
  spAdd: TUniStoredProc;
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
    spAdd := TUniStoredProc.Create(nil);
    try
      spAdd.Connection     := FConn;
      spAdd.StoredProcName := FConfig.SPAnyadir;
      spAdd.Params.Clear;
      spAdd.Params.CreateParam(ftString,  'p_SERIE_REM',  ptInput);
      spAdd.Params.CreateParam(ftString,  'p_NUMERO_REM', ptInput);
      spAdd.Params.CreateParam(ftString,  'p_SERIE_FAC',  ptInput);
      spAdd.Params.CreateParam(ftString,  'p_NUMERO_FAC', ptInput);
      spAdd.Params.CreateParam(ftInteger, FConfig.ParamNumEfecto, ptInput);
      spAdd.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
      spAdd.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
      nOk   := 0;
      nSkip := 0;
      for i := 0 to nSel - 1 do
      begin
        ri := tvEfe.Controller.SelectedRecords[i].RecordIndex;
        spAdd.ParamByName('p_SERIE_REM').AsString  := sSerieRem;
        spAdd.ParamByName('p_NUMERO_REM').AsString := sNumRem;
        spAdd.ParamByName('p_SERIE_FAC').AsString  :=
          VarToStr(tvEfe.DataController.Values[ri, colSerieFac.Index]);
        spAdd.ParamByName('p_NUMERO_FAC').AsString :=
          VarToStr(tvEfe.DataController.Values[ri, colNumFac.Index]);
        spAdd.ParamByName(FConfig.ParamNumEfecto).AsInteger :=
          StrToIntDef(VarToStr(
            tvEfe.DataController.Values[ri, colNumEfe.Index]), 0);
        spAdd.ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
        spAdd.ExecProc;
        res := spAdd.ParamByName('p_RESULTADO').AsInteger;
        if res = 1 then
          Inc(nOk)
        else
          Inc(nSkip);
      end;
    finally
      FreeAndNil(spAdd);
    end;
    FRemSerie   := sSerieRem;
    FRemNumero  := sNumRem;
    FConfirmado := nOk > 0;
    ShowMessage(Format(SInfoEfectosCargadosRemesa,
      [nOk, sSerieRem, sNumRem, FConfig.TextoOmitidos, nSkip]));
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
