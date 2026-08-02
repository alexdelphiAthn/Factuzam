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
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxButtonEdit, cxMaskEdit, cxDropDownEdit, cxRadioGroup, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid,
  inLibFacturacionAlbaranesCompraPersistenciaIntf;

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
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnCargarClick(Sender: TObject);
    procedure btnEmpresaPropertiesButtonClick(Sender: TObject;
                                              AButtonIndex: Integer);
    procedure btnProveedorPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure btnFacturarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure rgModoPropertiesEditValueChanged(Sender: TObject);
  private
    FRepositorio: IRepositorioFacturacionAlbaranesCompra;
    FConsultaAlbaranes: IConsultaFacturacionAlbaranesCompra;
    FDsAlb: TDataSource;
    FFacSeries: TStringList;
    FFacNumeros: TStringList;
    FConfirmado: Boolean;
    FFacSerie: string;
    FFacNumero: string;
    procedure ActualizarModo;
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
  inLibUser, inLibGenBusq, inLibFormatoDocumento,
  inLibMsgFacturas, inLibMsgVentas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalFacturarAlbaranes.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmado := False;
  FFacSeries  := TStringList.Create;
  FFacNumeros := TStringList.Create;
  FRepositorio := ContextoRepositoriosPantalla.Documentos.
    CrearRepositorioFacturacionAlbaranesCompra;
  FDsAlb := TDataSource.Create(Self);
  tvAlb.DataController.DataSource := FDsAlb;
  rgModo.ItemIndex := 0;
  ActualizarModo;
end;

procedure TfrmModalFacturarAlbaranes.FormDestroy(Sender: TObject);
begin
  FDsAlb.DataSet := nil;
  FConsultaAlbaranes := nil;
  FRepositorio := nil;
  FreeAndNil(FFacSeries);
  FreeAndNil(FFacNumeros);
  inherited;
end;

procedure TfrmModalFacturarAlbaranes.FormKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  // Ctrl+Enter sobre empresa / proveedor abre su caja de busqueda: el
  // TcxButtonEdit no dispara el boton elipsis por teclado por si solo.
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    if btnEmpresa.Focused then
    begin
      Key := 0;
      btnEmpresaPropertiesButtonClick(btnEmpresa, 0);
    end
    else if btnProveedor.Focused then
    begin
      Key := 0;
      btnProveedorPropertiesButtonClick(btnProveedor, 0);
    end;
  end;
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
begin
  lblNombrePrv.Caption := '';
  if APrv <> '' then
    lblNombrePrv.Caption := FRepositorio.BuscarNombreProveedor(APrv);
end;

procedure TfrmModalFacturarAlbaranes.CargarFacturasAbiertas(const AEmp,
                                                            APrv: string);
var
  Factura: TFacturaCompraAbierta;
  Facturas: TFacturasCompraAbiertas;
begin
  FFacSeries.Clear;
  FFacNumeros.Clear;
  cbbFacExistente.Properties.Items.Clear;
  cbbFacExistente.ItemIndex := -1;
  Facturas := FRepositorio.ListarFacturasAbiertas(AEmp, APrv);
  for Factura in Facturas do
  begin
    // Listas paralelas: el ItemIndex del combo indexa serie/numero reales.
    FFacSeries.Add(Factura.Serie);
    FFacNumeros.Add(Factura.Numero);
    cbbFacExistente.Properties.Items.Add(
      FormatearDocumentoEmpresa(ConexionPrincipal, AEmp,
        Factura.Serie,
        Factura.Numero) + '   (' +
      FormatDateTime('dd/mm/yyyy', Factura.Fecha) + ')');
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnCargarClick(Sender: TObject);
var
  sEmp, sPrv: string;
begin
  inherited;
  sEmp := Trim(btnEmpresa.Text);
  sPrv := Trim(btnProveedor.Text);
  if (sEmp = '') or (sPrv = '') then
    ShowMessage(SErrorEmpresaProveedorFacturacionNoIndicados)
  else
  begin
    CargarProveedorNombre(sPrv);
    FDsAlb.DataSet := nil;
    FConsultaAlbaranes := FRepositorio.ConsultarAlbaranesPendientes(
      sEmp,
      sPrv);
    FDsAlb.DataSet := FConsultaAlbaranes.DataSet;
    CargarFacturasAbiertas(sEmp, sPrv);
    if FConsultaAlbaranes.DataSet.IsEmpty then
      ShowMessage(SInfoAlbaranesPendientesProveedorNoEncontrados);
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnEmpresaPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Consulta: IConsultaFacturacionAlbaranesCompra;
  Datos: TDataSet;
  sVal: string;
begin
  inherited;
  Consulta := FRepositorio.ConsultarEmpresas;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       'Buscar empresa', Datos, 'srchEmpFacAlb', Self) then
  begin
    sVal := Datos.FieldByName('CODIGO_EMP_EMP').AsString;
    btnEmpresa.Text := sVal;
  end;
end;

procedure TfrmModalFacturarAlbaranes.btnProveedorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Consulta: IConsultaFacturacionAlbaranesCompra;
  Datos: TDataSet;
  sVal: string;
begin
  inherited;
  Consulta := FRepositorio.ConsultarProveedores;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       'Buscar proveedor', Datos, 'srchPrvFacAlb', Self) then
  begin
    sVal := Datos.FieldByName('CODIGO_PRV_PRV').AsString;
    btnProveedor.Text := sVal;
    CargarProveedorNombre(sVal);
  end;
end;

procedure TfrmModalFacturarAlbaranes.RecogerAlbaranes(ASeries,
                                                      ANumeros: TStringList);
var
  Datos: TDataSet;
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
  else if (FConsultaAlbaranes <> nil) and
          FConsultaAlbaranes.DataSet.Active and
          (not FConsultaAlbaranes.DataSet.IsEmpty) then
  begin
    if MessageDlg(SPreguntaFacturarTodosAlbaranesListados,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Datos := FConsultaAlbaranes.DataSet;
      Datos.DisableControls;
      try
        Datos.First;
        while not Datos.Eof do
        begin
          ASeries.Add(Datos.FieldByName('SERIE_ALBC').AsString);
          ANumeros.Add(Datos.FieldByName('NUMERO_ALBC').AsString);
          Datos.Next;
        end;
      finally
        Datos.EnableControls;
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
  i, nOk, nSkip: Integer;
  Resultado: TResultadoFacturacionAlbaranCompra;
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
        ShowMessage(SErrorBorradorAlbaranesExistenteNoSeleccionado);
    end;
    if bSeguir then
    begin
      nOk   := 0;
      nSkip := 0;
      for i := 0 to lSeries.Count - 1 do
      begin
        Resultado := FRepositorio.FacturarAlbaran(
          lSeries[i],
          lNumeros[i],
          sSerieAcum,
          sNumAcum,
          IdentidadSesion.Usuario);
        if Resultado.Procesado then
        begin
          // La 1a llamada deja la factura (nueva o la elegida); las
          // siguientes acumulan en ella.
          sSerieAcum := Resultado.SerieFactura;
          sNumAcum := Resultado.NumeroFactura;
          Inc(nOk);
        end
        else
          Inc(nSkip);
      end;
      FFacSerie   := sSerieAcum;
      FFacNumero  := sNumAcum;
      FConfirmado := nOk > 0;
      ShowMessage(Format(SInfoAlbaranesGeneradosEnBorrador,
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
