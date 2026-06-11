{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalFacturarAlbaranes                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Agrupa albaranes de compra en una factura de compra. Permite:            }
{      - CREAR una factura nueva con los albaranes seleccionados, o           }
{      - INCORPORAR los albaranes a una factura existente del mismo           }
{        proveedor y empresa.                                                  }
{    Itera los albaranes marcados llamando a PRC_FACC_FACTURAR_ALBARAN: la     }
{    1a llamada crea (o usa) la factura y las siguientes acumulan en ella.     }
{    Devuelve la factura resultante en FacturaSerie / FacturaNumero.           }
{******************************************************************************}
unit inMtoModalFacturarAlbaranes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, MemDS,
  DBAccess, Uni,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxButtonEdit, cxMaskEdit, cxDropDownEdit, cxRadioGroup, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid;

type
  TfrmModalFacturarAlbaranes = class(TfrmBase)
    pnlTop:          TPanel;
    lblEmpresa:      TcxLabel;
    btnEmpresa:      TcxButtonEdit;
    lblProveedor:    TcxLabel;
    btnProveedor:    TcxButtonEdit;
    btnCargar:       TcxButton;
    lblNombrePrv:    TcxLabel;
    rgModo:          TcxRadioGroup;
    lblFacExistente: TcxLabel;
    cbbFacExistente: TcxComboBox;
    pnlGrid:         TPanel;
    cxgrdAlb:        TcxGrid;
    tvAlb:           TcxGridDBTableView;
    lvlAlb:          TcxGridLevel;
    colAlbNumero:    TcxGridDBColumn;
    colAlbSerie:     TcxGridDBColumn;
    colAlbFecha:     TcxGridDBColumn;
    colAlbRefPrv:    TcxGridDBColumn;
    colAlbTotal:     TcxGridDBColumn;
    pnlButton:       TPanel;
    btnSalir:        TcxButton;
    btnFacturar:     TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCargarClick(Sender: TObject);
    procedure btnEmpresaPropertiesButtonClick(Sender: TObject;
                                              AButtonIndex: Integer);
    procedure btnProveedorPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnFacturarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure rgModoPropertiesEditValueChanged(Sender: TObject);
  private
    // Campos primero (E2169): conexion y datasets de trabajo.
    FConn:       TUniConnection;
    FQryAlb:     TUniQuery;
    FDsAlb:      TDataSource;
    FQryFac:     TUniQuery;
    FSp:         TUniStoredProc;
    FFacSeries:  TStringList;
    FFacNumeros: TStringList;
    FConfirmado: Boolean;
    FFacSerie:   string;
    FFacNumero:  string;
    procedure ActualizarModo;
    procedure DefinirParamsSp;
    procedure CargarProveedorNombre(const APrv: string);
    procedure CargarFacturasAbiertas(const AEmp, APrv: string);
    procedure RecogerAlbaranes(ASeries, ANumeros: TStringList);
    function  ResolverFacturaExistente(out ASerie, ANumero: string): Boolean;
  public
    // Prefija empresa y proveedor (p.ej. desde la cabecera del Mto llamante).
    procedure SetContexto(const AEmpresa, AProveedor: string);
    property Confirmado:    Boolean read FConfirmado;
    property FacturaSerie:  string  read FFacSerie;
    property FacturaNumero: string  read FFacNumero;
  end;

implementation

uses
  inLibGlobalVar, inLibUser, inLibGenBusq;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalFacturarAlbaranes.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmado := False;
  FFacSeries  := TStringList.Create;
  FFacNumeros := TStringList.Create;
  FConn := inLibGlobalVar.oConn;
  // Query de albaranes candidatos (pendientes de facturar). El DataSource se
  // engancha al grid por codigo para no depender de un data module.
  FQryAlb := TUniQuery.Create(Self);
  FQryAlb.Connection := FConn;
  FQryAlb.SQL.Text :=
    'SELECT NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, REF_PROVEEDOR_ALBC, ' +
    '       RAZON_SOCIAL_PRV_ALBC, TOTAL_LIQUIDO_ALBC, ESTADO_ALBC ' +
    '  FROM fza_albaranes_compra ' +
    ' WHERE CODIGO_EMP_ALBC = :emp AND CODIGO_PRV_ALBC = :prv ' +
    '   AND COALESCE(ESTADO_ALBC, '''') NOT IN (''FACTURADO'', ''CANCELADO'') ' +
    ' ORDER BY FECHA_ALBC, NUMERO_ALBC';
  FDsAlb := TDataSource.Create(Self);
  FDsAlb.DataSet := FQryAlb;
  tvAlb.DataController.DataSource := FDsAlb;
  // Query de facturas abiertas (para el modo "incorporar").
  FQryFac := TUniQuery.Create(Self);
  FQryFac.Connection := FConn;
  // Stored proc de facturacion con sus parametros fijados una vez.
  FSp := TUniStoredProc.Create(Self);
  FSp.Connection := FConn;
  FSp.StoredProcName := 'PRC_FACC_FACTURAR_ALBARAN';
  DefinirParamsSp;
  rgModo.ItemIndex := 0;
  ActualizarModo;
end;

procedure TfrmModalFacturarAlbaranes.FormDestroy(Sender: TObject);
begin
  // Las queries / datasource / sp se liberan con el form (Owner = Self).
  FreeAndNil(FFacSeries);
  FreeAndNil(FFacNumeros);
  inherited;
end;

procedure TfrmModalFacturarAlbaranes.DefinirParamsSp;
begin
  // Orden EXACTO de la firma de PRC_FACC_FACTURAR_ALBARAN (5 IN + 3 OUT):
  // los parametros de CALL en MySQL/MariaDB se enlazan por posicion.
  FSp.Params.Clear;
  FSp.Params.CreateParam(ftString,  'p_SERIE_ALB',     ptInput);
  FSp.Params.CreateParam(ftString,  'p_NUMERO_ALB',    ptInput);
  FSp.Params.CreateParam(ftString,  'p_SERIE_FAC',     ptInput);
  FSp.Params.CreateParam(ftString,  'p_NUMERO_FAC',    ptInput);
  FSp.Params.CreateParam(ftString,  'p_USUARIO',       ptInput);
  FSp.Params.CreateParam(ftString,  'p_SERIE_FAC_OUT', ptOutput);
  FSp.Params.CreateParam(ftString,  'p_NUMERO_FAC_OUT',ptOutput);
  FSp.Params.CreateParam(ftInteger, 'p_RESULTADO',     ptOutput);
end;

procedure TfrmModalFacturarAlbaranes.SetContexto(const AEmpresa,
                                                 AProveedor: string);
begin
  btnEmpresa.Text   := AEmpresa;
  btnProveedor.Text := AProveedor;
end;

procedure TfrmModalFacturarAlbaranes.ActualizarModo;
var
  bExistente: Boolean;
begin
  // ItemIndex 0 = factura nueva; 1 = incorporar a una existente.
  bExistente := rgModo.ItemIndex = 1;
  lblFacExistente.Enabled := bExistente;
  cbbFacExistente.Enabled := bExistente;
end;

procedure TfrmModalFacturarAlbaranes.rgModoPropertiesEditValueChanged(
                                                       Sender: TObject);
begin
  ActualizarModo;
end;

procedure TfrmModalFacturarAlbaranes.CargarProveedorNombre(const APrv: string);
var
  q: TUniQuery;
begin
  lblNombrePrv.Caption := '';
  if APrv = '' then
    Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConn;
    q.SQL.Text :=
      'SELECT NOMBRE_PRV FROM fza_proveedores WHERE CODIGO_PRV_PRV = :p';
    q.ParamByName('p').AsString := APrv;
    q.Open;
    if not q.Eof then
      lblNombrePrv.Caption := q.FieldByName('NOMBRE_PRV').AsString;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmModalFacturarAlbaranes.CargarFacturasAbiertas(const AEmp,
                                                            APrv: string);
begin
  FFacSeries.Clear;
  FFacNumeros.Clear;
  cbbFacExistente.Properties.Items.Clear;
  cbbFacExistente.ItemIndex := -1;
  FQryFac.Close;
  FQryFac.SQL.Text :=
    'SELECT SERIE_FACC, NUMERO_FACC, FECHA_FACC, TOTAL_LIQUIDO_FACC ' +
    '  FROM fza_facturas_compra ' +
    ' WHERE CODIGO_EMP_FACC = :emp AND CODIGO_PRV_FACC = :prv ' +
    '   AND COALESCE(ESTADO_FACC, '''') IN (''ABIERTA'', ''CERRADA'') ' +
    ' ORDER BY FECHA_FACC DESC, NUMERO_FACC DESC';
  FQryFac.ParamByName('emp').AsString := AEmp;
  FQryFac.ParamByName('prv').AsString := APrv;
  FQryFac.Open;
  while not FQryFac.Eof do
  begin
    // Listas paralelas: el ItemIndex del combo indexa serie/numero reales.
    FFacSeries.Add(FQryFac.FieldByName('SERIE_FACC').AsString);
    FFacNumeros.Add(FQryFac.FieldByName('NUMERO_FACC').AsString);
    cbbFacExistente.Properties.Items.Add(
      FQryFac.FieldByName('SERIE_FACC').AsString + ' / ' +
      FQryFac.FieldByName('NUMERO_FACC').AsString + '   (' +
      FormatDateTime('dd/mm/yyyy',
        FQryFac.FieldByName('FECHA_FACC').AsDateTime) + ')');
    FQryFac.Next;
  end;
  FQryFac.Close;
end;

procedure TfrmModalFacturarAlbaranes.btnCargarClick(Sender: TObject);
var
  sEmp, sPrv: string;
begin
  inherited;
  sEmp := Trim(btnEmpresa.Text);
  sPrv := Trim(btnProveedor.Text);
  if (sEmp = '') or (sPrv = '') then
    ShowMessage('Indica empresa y proveedor.')
  else
  begin
    CargarProveedorNombre(sPrv);
    FQryAlb.Close;
    FQryAlb.ParamByName('emp').AsString := sEmp;
    FQryAlb.ParamByName('prv').AsString := sPrv;
    FQryAlb.Open;
    CargarFacturasAbiertas(sEmp, sPrv);
    if FQryAlb.IsEmpty then
      ShowMessage('No hay albaranes pendientes de facturar para ese ' +
                  'proveedor.');
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnEmpresaPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sVal: string;
begin
  inherited;
  // Caja de busqueda modal generica (TfrmMtoSearch via inLibGenBusq).
  if TBusquedaUtils.EjecutarBusqueda('Buscar empresa',
       'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP',
       'CODIGO_EMP_EMP', sVal, 'srchEmpFacAlb', Self) then
    btnEmpresa.Text := sVal;
end;

procedure TfrmModalFacturarAlbaranes.btnProveedorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sVal: string;
begin
  inherited;
  if TBusquedaUtils.EjecutarBusqueda('Buscar proveedor',
       'SELECT * FROM fza_proveedores ORDER BY NOMBRE_PRV',
       'CODIGO_PRV_PRV', sVal, 'srchPrvFacAlb', Self) then
  begin
    btnProveedor.Text := sVal;
    CargarProveedorNombre(sVal);
  end;
end;

procedure TfrmModalFacturarAlbaranes.RecogerAlbaranes(ASeries,
                                                      ANumeros: TStringList);
var
  i, ri: Integer;
begin
  ASeries.Clear;
  ANumeros.Clear;
  // Con seleccion en la rejilla (Ctrl/Mayus+clic): solo esos albaranes.
  if tvAlb.Controller.SelectedRecordCount > 0 then
  begin
    for i := 0 to tvAlb.Controller.SelectedRecordCount - 1 do
    begin
      ri := tvAlb.Controller.SelectedRecords[i].RecordIndex;
      ASeries.Add(VarToStr(tvAlb.DataController.Values[ri, colAlbSerie.Index]));
      ANumeros.Add(VarToStr(tvAlb.DataController.Values[ri,
                                                     colAlbNumero.Index]));
    end;
  end
  // Sin seleccion: ofrecer facturar TODOS los albaranes listados.
  else if FQryAlb.Active and (not FQryAlb.IsEmpty) then
  begin
    if MessageDlg('No has marcado albaranes (Ctrl/Mayus+clic para elegir).' +
                  sLineBreak + 'Facturar TODOS los listados?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FQryAlb.DisableControls;
      try
        FQryAlb.First;
        while not FQryAlb.Eof do
        begin
          ASeries.Add(FQryAlb.FieldByName('SERIE_ALBC').AsString);
          ANumeros.Add(FQryAlb.FieldByName('NUMERO_ALBC').AsString);
          FQryAlb.Next;
        end;
      finally
        FQryAlb.EnableControls;
      end;
    end;
  end;
end;

function TfrmModalFacturarAlbaranes.ResolverFacturaExistente(out ASerie,
                                                  ANumero: string): Boolean;
begin
  ASerie  := '';
  ANumero := '';
  Result := (cbbFacExistente.ItemIndex >= 0) and
            (cbbFacExistente.ItemIndex < FFacSeries.Count);
  if Result then
  begin
    ASerie  := FFacSeries[cbbFacExistente.ItemIndex];
    ANumero := FFacNumeros[cbbFacExistente.ItemIndex];
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnFacturarClick(Sender: TObject);
var
  i, nOk, nSkip, res: Integer;
  sSerieAcum, sNumAcum: string;
  lSeries, lNumeros: TStringList;
  bSeguir: Boolean;
begin
  inherited;
  lSeries  := TStringList.Create;
  lNumeros := TStringList.Create;
  try
    RecogerAlbaranes(lSeries, lNumeros);
    bSeguir    := lSeries.Count > 0;
    sSerieAcum := '';
    sNumAcum   := '';
    // En modo "incorporar" (ItemIndex=1) hay que tener factura destino valida.
    if bSeguir and (rgModo.ItemIndex = 1) then
    begin
      bSeguir := ResolverFacturaExistente(sSerieAcum, sNumAcum);
      if not bSeguir then
        ShowMessage('Elige la factura existente a la que incorporar los ' +
                    'albaranes.');
    end;
    if bSeguir then
    begin
      nOk   := 0;
      nSkip := 0;
      for i := 0 to lSeries.Count - 1 do
      begin
        FSp.ParamByName('p_SERIE_ALB').AsString  := lSeries[i];
        FSp.ParamByName('p_NUMERO_ALB').AsString := lNumeros[i];
        FSp.ParamByName('p_SERIE_FAC').AsString  := sSerieAcum;
        FSp.ParamByName('p_NUMERO_FAC').AsString := sNumAcum;
        FSp.ParamByName('p_USUARIO').AsString    := oUser;
        FSp.ExecProc;
        res := FSp.ParamByName('p_RESULTADO').AsInteger;
        if res = 1 then
        begin
          // La 1a llamada deja la factura (nueva o la elegida); las
          // siguientes acumulan en ella.
          sSerieAcum := FSp.ParamByName('p_SERIE_FAC_OUT').AsString;
          sNumAcum   := FSp.ParamByName('p_NUMERO_FAC_OUT').AsString;
          Inc(nOk);
        end
        else
          Inc(nSkip);
      end;
      FFacSerie   := sSerieAcum;
      FFacNumero  := sNumAcum;
      FConfirmado := nOk > 0;
      ShowMessage(Format(
        'Facturados %d albaran(es) en la factura %s / %s.' + sLineBreak +
        'Omitidos (ya facturados o incompatibles): %d.',
        [nOk, sSerieAcum, sNumAcum, nSkip]));
      if FConfirmado then
        ModalResult := mrOk;
    end;
  finally
    lSeries.Free;
    lNumeros.Free;
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnSalirClick(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalFacturarAlbaranes);
end.
