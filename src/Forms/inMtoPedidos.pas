{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPedidos                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de pedidos de venta.                                        }
{    Cabecera, lineas y datos fiscales sobre fza_pedidos.                      }
{******************************************************************************}
unit inMtoPedidos;

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
  cxSpinEdit, cxCurrencyEdit, UniDataPedidos, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView;

type
  TfrmMtoPedidos = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBodyFicha: TPanel;
    pcPedido: TcxPageControl;
    tsLineasPedido: TcxTabSheet;
    tsAlbaranes: TcxTabSheet;
    tsMensajes: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxGrdPedidosLineas: TcxGrid;
    tvPedidosLineas: TcxGridDBTableView;
    cxGrdPedidosLineasLevel1: TcxGridLevel;
    cxGrdAlbaranes: TcxGrid;
    tvAlbaranes: TcxGridDBTableView;
    cxGrdAlbaranesLevel: TcxGridLevel;
    cxGrdMensajes: TcxGrid;
    tvMensajes: TcxGridDBTableView;
    cxGrdMensajesLevel: TcxGridLevel;

    // Cabecera
    lblNroPedido: TcxLabel;
    txtNUMERO_PED: TcxDBTextEdit;
    lblSerie: TcxLabel;
    txtSERIE_PED: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFECHA_PED: TcxDBDateEdit;
    lblFechaEntrega: TcxLabel;
    dteFECHA_ENTREGA_PED: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_PED: TcxDBTextEdit;
    lblIDPS: TcxLabel;
    txtIDPS_PED: TcxDBTextEdit;
    lblRefPS: TcxLabel;
    txtREFERENCIAPS_PED: TcxDBTextEdit;

    btnCODIGO_EMP: TcxDBButtonEdit;
    lblCodigoEmpresa: TcxLabel;
    cxdblblRAZON_SOCIAL_EMPRESA_PED: TcxDBLabel;
    btnCODIGO_CLI: TcxDBButtonEdit;
    lblCodigoCliente: TcxLabel;
    cxdblblRAZON_SOCIAL_CLIENTE_PED: TcxDBLabel;

    // Empresa
    grpEmpresa: TcxGroupBox;
    txtNIF_EMPRESA_PED: TcxDBTextEdit;
    lblNIFEmp: TcxLabel;
    txtMOVIL_EMPRESA_PED: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtEMAIL_EMPRESA_PED: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtDIRECCION1_EMPRESA_PED: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_PED: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_PED: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_PED: TcxDBTextEdit;

    // Cliente fiscal
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtNIF_CLIENTE_PED: TcxDBTextEdit;
    txtEMAIL_CLIENTE_PED: TcxDBTextEdit;
    txtMOVIL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_FISCAL_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_FISCAL_PED: TcxDBTextEdit;

    // Cliente envío
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_PED: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_PED: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_PED: TcxDBTextEdit;

    // Totales
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_PED: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit;

    // Botones de acción
    pnlBotonesAcciones: TPanel;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnEntregarTodo: TcxButton;
    btnCrearAlbaran: TcxButton;
    btnImportarPS: TcxButton;
    btnImprimir: TcxButton;

    // Observaciones
    memObservaciones: TcxDBMemo;

    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnEntregarTodoClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
    procedure btnImportarPSClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
  private
    procedure RellenarLineasAlEntregarTodo;
  public
    dmmPedidos: TdmPedidos;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoPedidos: TfrmMtoPedidos;

implementation

uses
  inMtoModalImportarPedidosPS, inLibFotos, inLibGridCantidad;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera de pedido. El articulo activo vive en
// la fila del sub-grid tvPedidosLineas (CODIGO_ART_PEDLIN; los pedidos
// trabajan a nivel articulo, sin SKU).
procedure TfrmMtoPedidos.ResolverArtSkuActivo(out ACodArt,
                                              ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvPedidosLineas.DataController.DataSource) then
  begin
    ds := tvPedidosLineas.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// pedido, ademas de dsTablaG (cabecera) enganchamos dsPedidosLineas.
function TfrmMtoPedidos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmPedidos) then
    Result := [dsTablaG, dmmPedidos.dsPedidosLineas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoPedidos.FormCreate(Sender: TObject);
var
  colEnt, colPend: TcxGridDBColumn;
  stEnt, stPend: TcxStyle;
begin
  inherited;
  dmmPedidos := TdmPedidos.Create(Self);
  dsTablaG.DataSet := dmmPedidos.unqryTablaG;
  tvPedidosLineas.DataController.DataSource := dmmPedidos.dsPedidosLineas;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PEDLIN'),
    tvPedidosLineas.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_PEDLIN'));
  tvAlbaranes.DataController.DataSource     := dmmPedidos.dsAlbaranes;
  tvMensajes.DataController.DataSource      := dmmPedidos.dsMensajes;
  // OpenTables -> ahora se llama desde TfrmMtoGen.AbrirTablaPrincipalAsync
  // (callback main thread) via dmmPedidos.AbrirDetalles. Se quita aqui
  // para no abrir las queries sincronamente durante el FormCreate.

  colEnt  := tvPedidosLineas.GetColumnByFieldName('CANTIDAD_ENTREGADA_PEDLIN');
  colPend := tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PENDIENTE_PEDLIN');
  if colEnt <> nil then
  begin
    stEnt := TcxStyle.Create(Self);
    stEnt.AssignedValues := [svColor];
    stEnt.Color := $00E0FFE0;
    colEnt.Styles.Content := stEnt;
  end;
  if colPend <> nil then
  begin
    stPend := TcxStyle.Create(Self);
    stPend.AssignedValues := [svColor];
    stPend.Color := $00C4E1FF;
    colPend.Styles.Content := stPend;
  end;
end;

procedure TfrmMtoPedidos.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidos.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmPedidos.CalcularTotalesPedido;
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoPedidos.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmPedidos.unqryPedidosLineas.Append;
end;

procedure TfrmMtoPedidos.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('¿Está seguro de que desea eliminar esta línea?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    dmmPedidos.unqryPedidosLineas.Delete;
end;

procedure TfrmMtoPedidos.RellenarLineasAlEntregarTodo;
var
  ds: TDataSet;
  fCant, fEntr: Double;
begin
  ds := dmmPedidos.unqryPedidosLineas;
  if not ds.Active then Exit;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      fCant := ds.FieldByName('CANTIDAD_PEDLIN').AsFloat;
      fEntr := ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
      if fEntr < fCant then
      begin
        ds.Edit;
        ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
        ds.Post;
      end;
      ds.Next;
    end;
  finally
    ds.EnableControls;
  end;
end;

procedure TfrmMtoPedidos.btnEntregarTodoClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Marcar todas las líneas como entregadas en su totalidad?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    RellenarLineasAlEntregarTodo;
end;

procedure TfrmMtoPedidos.btnCrearAlbaranClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<TPair<string, Currency>>;
  par: TPair<string, Currency>;
  fEntrPend: Double;
  sNumeroAlb, sSerieAlb: string;
begin
  inherited;
  // Antes de crear, asegurar que el pedido esté guardado
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  ds := dmmPedidos.unqryPedidosLineas;
  if not ds.Active or (ds.RecordCount = 0) then
  begin
    ShowMessage('El pedido no tiene líneas');
    Exit;
  end;
  lst := TList<TPair<string, Currency>>.Create;
  try
    ds.DisableControls;
    try
      ds.First;
      while not ds.Eof do
      begin
        // Cantidad a albaranar = entregada en pedido - lo ya albaranado
        // Como CANTIDAD_ENTREGADA_PEDLIN se actualiza por trigger del propio
        // procedimiento, usamos la diferencia inferida por el cliente:
        // (cantidad introducida en la columna entregada - 0 cada vez)
        fEntrPend := ds.FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
        // El procedimiento PRC_PED_CREAR_ALBARAN_LINEA sólo tomará lo
        // pendiente real comparando con CANTIDAD_PEDLIN. Aquí enviamos
        // la cantidad que el usuario marca.
        if fEntrPend > 0 then
        begin
          par.Key   := ds.FieldByName('LINEA_PEDLIN').AsString;
          par.Value := fEntrPend;
          lst.Add(par);
        end;
        ds.Next;
      end;
    finally
      ds.EnableControls;
    end;
    if lst.Count = 0 then
    begin
      ShowMessage(
        'No hay líneas con cantidad entregada para crear el albarán.');
      Exit;
    end;
    if dmmPedidos.CrearAlbaranDesdePedido(sNumeroAlb, sSerieAlb, lst) then
      ShowMessageFmt('Albarán creado: %s / %s', [sSerieAlb, sNumeroAlb])
    else
      ShowMessage('No se pudo crear el albarán.');
  finally
    FreeAndNil(lst);
  end;
end;

procedure TfrmMtoPedidos.btnImportarPSClick(Sender: TObject);
var
  form: TfrmModalImportarPedidosPS;
begin
  inherited;
  form := TfrmModalImportarPedidosPS.Create(Self);
  try
    form.dmPedidos := dmmPedidos;
    form.ShowModal;
    dmmPedidos.unqryTablaG.Close;
    dmmPedidos.unqryTablaG.Open;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoPedidos.btnImprimirClick(Sender: TObject);
begin
  inherited;
  // Hook FastReport
end;

initialization
  ForceReferenceToClass(TfrmMtoPedidos);

end.
