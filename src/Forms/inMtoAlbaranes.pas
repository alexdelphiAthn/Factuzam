{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlbaranes                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de albaranes de venta.                                      }
{    Cabecera, lineas y datos fiscales sobre fza_albaranes.                    }
{******************************************************************************}
unit inMtoAlbaranes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen, dxSkinsCore, dxSkinBlue,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsForm, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxSpinEdit, cxCurrencyEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView, UniDataAlbaranes,
  System.Actions, Vcl.ActnList;

type
  TfrmMtoAlbaranes = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBotonesAcciones: TPanel;
    pnlBodyFicha: TPanel;
    pcAlbaran: TcxPageControl;
    tsLineasAlbaran: TcxTabSheet;
    tsFacturas: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxgrdLineasAlbaran: TcxGrid;
    tvLineasAlbaran: TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    cxGrdFacturas: TcxGrid;
    tvFacturas: TcxGridDBTableView;
    cxGrdFacturasLevel: TcxGridLevel;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxGrdMovimientosLevel: TcxGridLevel;

    // Cabecera
    lblNroAlbaran: TcxLabel;
    txtNUMERO_ALB: TcxDBTextEdit;
    lblSerieAlbaran: TcxLabel;
    txtSERIE_ALB: TcxDBTextEdit;
    lblFechaAlbaran: TcxLabel;
    dteFECHA_ALB: TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALB: TcxDBTextEdit;
    lblPedidoOrigen: TcxLabel;
    txtNUMERO_PED_ALB: TcxDBTextEdit;
    txtSERIE_PED_ALB: TcxDBTextEdit;
    lblFacturaDestino: TcxLabel;
    txtNUMERO_FAC_ALB: TcxDBTextEdit;
    txtSERIE_FAC_ALB: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel;
    lblCodigoCliente: TcxLabel;
    btnCODIGO_CLI_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel;

    // Empresa
    grpEmpresa: TcxGroupBox;
    lblNIFEmp: TcxLabel;
    txtNIF_EMPRESA_ALB: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtMOVIL_EMPRESA_ALB: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtEMAIL_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION1_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_ALB: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_ALB: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_ALB: TcxDBTextEdit;

    // Cliente fiscal
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNIF_CLIENTE_ALB: TcxDBTextEdit;
    txtEMAIL_CLIENTE_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ALB: TcxDBTextEdit;

    // Cliente envío
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_ALB: TcxDBTextEdit;

    // Totales
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    tsTotales: TcxTabSheet;
    scrTotales: TScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_ALB: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_ALB: TcxDBCheckBox;
    grpDesgloseImpuestos: TGroupBox;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    spnTotalesPORCENTAJE_IVAN_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_ALB: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_ALB: TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de acción
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnFacturarSeleccionadas: TcxButton;
    btnFacturarTodo: TcxButton;
    btnFacturarPorFechas: TcxButton;
    btnImprimir: TcxButton;
    // Boton + accion para saltar al pedido de venta de origen del
    // albaran (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    ActionList1: TActionList;
    actIrDocumento: TAction;

    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnFacturarSeleccionadasClick(Sender: TObject);
    procedure btnFacturarTodoClick(Sender: TObject);
    procedure btnFacturarPorFechasClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
  public
    dmmAlbaranes: TdmAlbaranes;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoAlbaranes: TfrmMtoAlbaranes;

implementation

uses
  inMtoModalFacturarAlbaranesFechas, inLibFotos, inLibGridCantidad,
  inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera de albaran. El articulo activo vive en
// la fila del sub-grid tvLineasAlbaran (CODIGO_ART_ALBLIN /
// CODIGO_UNIDAD_ALBLIN).
procedure TfrmMtoAlbaranes.ResolverArtSkuActivo(out ACodArt,
                                                ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasAlbaran.DataController.DataSource) then
  begin
    ds := tvLineasAlbaran.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// albaran, ademas de dsTablaG (cabecera) enganchamos dsAlbaranesLineas.
function TfrmMtoAlbaranes.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmAlbaranes) then
    Result := [dsTablaG, dmmAlbaranes.dsAlbaranesLineas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoAlbaranes.FormCreate(Sender: TObject);
var
  colFact: TcxGridDBColumn;
  stFact: TcxStyle;
begin
  inherited;
  dmmAlbaranes := TdmAlbaranes.Create(Self);
  dsTablaG.DataSet := dmmAlbaranes.unqryTablaG;
  tvLineasAlbaran.DataController.DataSource := dmmAlbaranes.dsAlbaranesLineas;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvLineasAlbaran.GetColumnByFieldName('CANTIDAD_ALBLIN'),
    tvLineasAlbaran.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_ALBLIN'));
  tvFacturas.DataController.DataSource      := dmmAlbaranes.dsFacturas;
  tvMovimientos.DataController.DataSource   := dmmAlbaranes.dsMovimientosAlb;
  cbbTotalesFORMA_PAGO_ALB.Properties.ListSource := dmmAlbaranes.dsFormasPago;
  // Clave de localizacion para ShowMto (p.ej. "Ir a documento" desde el
  // pedido de venta o navegacion hacia su pedido de origen).
  pkFieldName := 'SERIE_ALB;NUMERO_ALB';
  // OpenTables -> ahora se llama desde TfrmMtoGen.AbrirTablaPrincipalAsync
  // (callback main thread) via dmmAlbaranes.AbrirDetalles. Se quita aqui
  // para no abrir las queries sincronamente durante el FormCreate.

  // Resaltar la columna ESFACTURADA_ALBLIN cuando exista (S/N).
  colFact := tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN');
  if colFact <> nil then
  begin
    stFact := TcxStyle.Create(Self);
    stFact.AssignedValues := [svColor];
    stFact.Color := $00C4E1FF;
    colFact.Styles.Content := stFact;
  end;
end;

procedure TfrmMtoAlbaranes.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranes.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmAlbaranes.CalcularTotalesAlbaran;
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoAlbaranes.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmAlbaranes.unqryAlbaranesLineas.Append;
end;

procedure TfrmMtoAlbaranes.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranes.unqryAlbaranesLineas.Delete;
end;

procedure TfrmMtoAlbaranes.btnFacturarSeleccionadasClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<string>;
  sNumFac, sSerFac, sLinea, sFacturada: string;
  i, iLineaCol, iFactCol: Integer;
  rec: TcxCustomGridRecord;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  if not ds.Active or (ds.RecordCount = 0) then
  begin
    ShowMessage('El albarán no tiene líneas.');
    Exit;
  end;
  if tvLineasAlbaran.Controller.SelectedRowCount = 0 then
  begin
    ShowMessage('Seleccione las líneas para crear borrador en la rejilla ' +
                '(Ctrl+click para selección múltiple).');
    Exit;
  end;
  lst := TList<string>.Create;
  try
    iLineaCol := -1;
    iFactCol  := -1;
    if tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN') <> nil then
      iLineaCol := tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN').Index;
    if tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN') <> nil then
      iFactCol :=
        tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN').Index;
    if iLineaCol < 0 then Exit;

    for i := 0 to tvLineasAlbaran.Controller.SelectedRowCount - 1 do
    begin
      rec := tvLineasAlbaran.Controller.SelectedRows[i];
      sLinea := VarToStr(rec.Values[iLineaCol]);
      if iFactCol >= 0 then
        sFacturada := VarToStr(rec.Values[iFactCol])
      else
        sFacturada := 'N';
      if (sLinea <> '') and (sFacturada <> 'S') then
        lst.Add(sLinea);
    end;

    if lst.Count = 0 then
    begin
      ShowMessage('Las líneas seleccionadas ya tienen borrador.');
      Exit;
    end;
    if MessageDlg(Format('¿Generar borrador con %d línea(s) del albarán?',
                         [lst.Count]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    if dmmAlbaranes.CrearFacturaDesdeAlbaran(sNumFac, sSerFac, lst) then
      ShowMessageFmt('Borrador creado: %s / %s', [sSerFac, sNumFac])
    else
      ShowMessage('No se pudo crear el borrador.');
  finally
    FreeAndNil(lst);
  end;
end;

procedure TfrmMtoAlbaranes.btnFacturarTodoClick(Sender: TObject);
var
  sNumFac, sSerFac: string;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  if not dmmAlbaranes.unqryAlbaranesLineas.Active or
     (dmmAlbaranes.unqryAlbaranesLineas.RecordCount = 0) then
  begin
    ShowMessage('El albarán no tiene líneas.');
    Exit;
  end;
  if MessageDlg('¿Crear borrador con todas las líneas pendientes del albarán?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if dmmAlbaranes.CrearFacturaDesdeAlbaran(sNumFac, sSerFac, nil) then
    ShowMessageFmt('Borrador creado: %s / %s', [sSerFac, sNumFac])
  else
    ShowMessage('No se pudo crear el borrador.');
end;

procedure TfrmMtoAlbaranes.btnFacturarPorFechasClick(Sender: TObject);
var
  form: TfrmModalFacturarAlbaranesFechas;
begin
  inherited;
  form := TfrmModalFacturarAlbaranesFechas.Create(Self);
  try
    form.dmmAlbaranes := dmmAlbaranes;
    form.ShowModal;
    dmmAlbaranes.unqryTablaG.Close;
    dmmAlbaranes.unqryTablaG.Open;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoAlbaranes.btnImprimirClick(Sender: TObject);
begin
  inherited;
  // Hook FastReport: cargar fxdsPrintAlb / fxdstPrintLinAlb y mostrar.
end;

// "Ir a documento" (Ctrl+May+A): salta al pedido de venta del que nace
// el albaran (SERIE_PED_ALB / NUMERO_PED_ALB). Si el albaran se creo a
// mano y no procede de ningun pedido, avisamos en lugar de abrir un Mto
// vacio.
procedure TfrmMtoAlbaranes.actIrDocumentoExecute(Sender: TObject);
var
  sSeriePed, sNumeroPed: string;
begin
  inherited;
  if (dmmAlbaranes <> nil) and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
  begin
    sSeriePed  := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('SERIE_PED_ALB').AsString);
    sNumeroPed := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('NUMERO_PED_ALB').AsString);
    if (sSeriePed <> '') and (sNumeroPed <> '') then
      ShowMto(Self.Owner, 'Pedidos', sSeriePed + ',' + sNumeroPed)
    else
      ShowMessage('Este albaran no procede de ningun pedido de venta.');
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranes);

end.
