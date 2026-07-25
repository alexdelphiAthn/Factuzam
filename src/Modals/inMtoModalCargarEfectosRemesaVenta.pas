{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalCargarEfectosRemesa                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       11/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Carga efectos de cobro pendientes (sin remesar) en una remesa: nueva       }
{    (PRC_REMV_CREAR) o existente. Por cada efecto marcado llama a             }
{    PRC_REMV_ANYADIR_EFECTO. Filtro por empresa y, opcionalmente, por         }
{    fecha de vencimiento (hasta). Devuelve la remesa en RemesaSerie/Numero.   }
{******************************************************************************}
unit inMtoModalCargarEfectosRemesaVenta;

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
  TfrmModalCargarEfectosRemesaVenta = class(TfrmBase)
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
    colCli:          TcxGridDBColumn;
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
    procedure PrepararNuevaRemesa(const AEmp: string);
    procedure PrepararRemesaExistente(const AEmp, ASerie, ANumero: string);
    property Confirmado:   Boolean read FConfirmado;
    property RemesaSerie:  string  read FRemSerie;
    property RemesaNumero: string  read FRemNumero;
  end;

implementation

uses
  inLibUser, inLibGenBusq;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalCargarEfectosRemesaVenta.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmado := False;
  FRemSeries  := TStringList.Create;
  FRemNumeros := TStringList.Create;
  FConn := ConexionPrincipal;
  // Efectos candidatos: pendientes, sin remesar, de la empresa, hasta vto.
  FQryEfe := TUniQuery.Create(Self);
  FQryEfe.Connection := FConn;
  FQryEfe.SQL.Text :=
    'SELECT SERIE_FAC_EFV, NUMERO_FAC_EFV, NUMERO_EFV, ' +
    '       RAZON_SOCIAL_CLI_EFV, FECHA_VENCIMIENTO_EFV, ' +
    '       IMPORTE_PENDIENTE_EFV, ESTADO_EFV ' +
    '  FROM fza_efectos_venta ' +
    ' WHERE CODIGO_EMP_EFV = :emp ' +
    '   AND SERIE_REMV_EFV IS NULL ' +
    '   AND COALESCE(ESTADO_EFV, '''') IN (''PENDIENTE'', ''PARCIAL'') ' +
    '   AND COALESCE(IMPORTE_PENDIENTE_EFV, 0) > 0 ' +
    '   AND FECHA_VENCIMIENTO_EFV <= :hasta ' +
    ' ORDER BY FECHA_VENCIMIENTO_EFV, RAZON_SOCIAL_CLI_EFV';
  FDsEfe := TDataSource.Create(Self);
  FDsEfe.DataSet := FQryEfe;
  tvEfe.DataController.DataSource := FDsEfe;
  FQryRem := TUniQuery.Create(Self);
  FQryRem.Connection := FConn;
  rgModo.ItemIndex := 0;
  dteHasta.Clear;
  ActualizarModo;
end;

procedure TfrmModalCargarEfectosRemesaVenta.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FRemSeries);
  FreeAndNil(FRemNumeros);
  inherited;
end;

procedure TfrmModalCargarEfectosRemesaVenta.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  // Ctrl+Enter sobre empresa abre su caja de busqueda.
  if (Key = VK_RETURN) and (ssCtrl in Shift) and btnEmpresa.Focused then
  begin
    Key := 0;
    btnEmpresaPropertiesButtonClick(btnEmpresa, 0);
  end;
end;

procedure TfrmModalCargarEfectosRemesaVenta.btnEmpresaPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sVal: string;
begin
  inherited;
  if TBusquedaUtils.EjecutarBusqueda(ConexionPrincipal, 'Buscar empresa',
       'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP',
       'CODIGO_EMP_EMP', sVal, 'srchEmpRem', Self) then
    btnEmpresa.Text := sVal;
end;

procedure TfrmModalCargarEfectosRemesaVenta.ActualizarModo;
var
  bExistente: Boolean;
begin
  bExistente := rgModo.ItemIndex = 1;
  lblRemExistente.Enabled := bExistente;
  cbbRemExistente.Enabled := bExistente;
end;

procedure TfrmModalCargarEfectosRemesaVenta.rgModoPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarModo;
end;

procedure TfrmModalCargarEfectosRemesaVenta.CargarRemesasAbiertas(
  const AEmp: string);
begin
  FRemSeries.Clear;
  FRemNumeros.Clear;
  cbbRemExistente.Properties.Items.Clear;
  cbbRemExistente.ItemIndex := -1;
  FQryRem.Close;
  FQryRem.SQL.Text :=
    'SELECT SERIE_REMV, NUMERO_REMV, FECHA_REMV, TOTAL_REMV ' +
    '  FROM fza_remesas_venta ' +
    ' WHERE CODIGO_EMP_REMV = :emp ' +
    '   AND COALESCE(ESTADO_REMV, '''') IN (''ABIERTA'', ''CERRADA'') ' +
    ' ORDER BY FECHA_REMV DESC, NUMERO_REMV DESC';
  FQryRem.ParamByName('emp').AsString := AEmp;
  FQryRem.Open;
  while not FQryRem.Eof do
  begin
    FRemSeries.Add(FQryRem.FieldByName('SERIE_REMV').AsString);
    FRemNumeros.Add(FQryRem.FieldByName('NUMERO_REMV').AsString);
    cbbRemExistente.Properties.Items.Add(
      FQryRem.FieldByName('SERIE_REMV').AsString + ' / ' +
      FQryRem.FieldByName('NUMERO_REMV').AsString + '   (' +
      FormatDateTime('dd/mm/yyyy', FQryRem.FieldByName('FECHA_REMV').AsDateTime)
      + ')');
    FQryRem.Next;
  end;
  FQryRem.Close;
end;

procedure TfrmModalCargarEfectosRemesaVenta.PrepararRemesaExistente(const AEmp,
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

procedure TfrmModalCargarEfectosRemesaVenta.PrepararNuevaRemesa(
  const AEmp: string);
begin
  btnEmpresa.Text := AEmp;
  rgModo.ItemIndex := 0;
  ActualizarModo;
end;

procedure TfrmModalCargarEfectosRemesaVenta.btnBuscarClick(Sender: TObject);
var
  sEmp: string;
  dHasta: TDateTime;
begin
  inherited;
  sEmp := Trim(btnEmpresa.Text);
  if sEmp = '' then
    ShowMessage('Indica la empresa.')
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
      ShowMessage('No hay efectos pendientes sin remesar para esa empresa.');
  end;
end;

function TfrmModalCargarEfectosRemesaVenta.CrearRemesaNueva(const AEmp: string;
  out ASerie, ANumero: string): Boolean;
var
  sp: TUniStoredProc;
begin
  ASerie  := '';
  ANumero := '';
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection     := FConn;
    sp.StoredProcName := 'PRC_REMV_CREAR';
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

procedure TfrmModalCargarEfectosRemesaVenta.btnRemesarClick(Sender: TObject);
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
    ShowMessage('Marca al menos un efecto (Ctrl/Mayus+clic).');
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
        ShowMessage('Elige la remesa existente.');
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
      spAdd.StoredProcName := 'PRC_REMV_ANYADIR_EFECTO';
      spAdd.Params.Clear;
      spAdd.Params.CreateParam(ftString,  'p_SERIE_REM',  ptInput);
      spAdd.Params.CreateParam(ftString,  'p_NUMERO_REM', ptInput);
      spAdd.Params.CreateParam(ftString,  'p_SERIE_FAC',  ptInput);
      spAdd.Params.CreateParam(ftString,  'p_NUMERO_FAC', ptInput);
      spAdd.Params.CreateParam(ftInteger, 'p_NUM_EFV',   ptInput);
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
        spAdd.ParamByName('p_NUM_EFV').AsInteger  :=
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
    ShowMessage(Format('Cargados %d efecto(s) en la remesa %s / %s.' +
      sLineBreak + 'Omitidos (ya remesados o cobrados): %d.',
      [nOk, sSerieRem, sNumRem, nSkip]));
    if FConfirmado then
      ModalResult := mrOk;
  end;
end;

procedure TfrmModalCargarEfectosRemesaVenta.btnSalirClick(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalCargarEfectosRemesaVenta);
end.


