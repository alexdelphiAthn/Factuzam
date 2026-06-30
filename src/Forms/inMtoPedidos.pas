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
  cxGridBandedTableView, cxGridDBBandedTableView,
  System.Actions, Vcl.ActnList;

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
    tsTotales: TcxTabSheet;
    scrTotales: TScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_PED: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit;
    lblTotalesPorcRetencion: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_PED: TcxDBSpinEdit;
    lblTotalesTotalRetencion: TcxLabel;
    curTotalesTOTAL_RETENCION_PED: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_PED: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_PED: TcxDBCheckBox;
    chkTotalesESRETENCIONES_CLIENTE_PED: TcxDBCheckBox;
    chkTotalesESRETENCIONES_EMPRESA_PED: TcxDBCheckBox;
    grpDesgloseImpuestos: TGroupBox;
    lblTotalesBaseNeta: TcxLabel;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesPorRe: TcxLabel;
    lblTotalesTotalRe: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    curTotalesTOTAL_BASEI_IVAN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAR_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAS_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAE_PED: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_IVAN_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_PED: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_PED: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_REN_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_PED: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_PED: TcxDBSpinEdit;
    curTotalesTOTAL_REN_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_RER_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_RES_PED: TcxDBCurrencyEdit;
    curTotalesTOTAL_REE_PED: TcxDBCurrencyEdit;

    // Botones de acción
    pnlBotonesAcciones: TPanel;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnEntregarTodo: TcxButton;
    btnCrearAlbaran: TcxButton;
    btnImportarPS: TcxButton;

    // Observaciones
    memObservaciones: TcxDBMemo;
    // Atajo Ctrl+May+A en la pestania Albaranes: abre el albaran de venta
    // seleccionado en la rejilla.
    ActionList1: TActionList;
    actIrDocumento: TAction;
    btnImprimir: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnEntregarTodoClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
    procedure btnImportarPSClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
  private
    procedure RellenarLineasAlEntregarTodo;
  public
    dmmPedidos: TdmPedidos;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoPedidos: TfrmMtoPedidos;

implementation

uses
  inMtoModalImportarPedidosPS, inLibFotos, inLibGridCantidad,
  inMtoModalSelAlmacenAlbaran, inMtoModalDocsCreados, inLibShowMto;

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
  tsTotales.TabVisible := True;
  tsTotales.Enabled := True;
  if Trim(tsTotales.Caption) = '' then
    tsTotales.Caption := '&2_Totales';
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvPedidosLineas.GetColumnByFieldName('CANTIDAD_PEDLIN'),
    tvPedidosLineas.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_PEDLIN'));

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

procedure TfrmMtoPedidos.CrearTablaPrincipal;
begin
  inherited;
  // Tomamos la instancia creada por TfrmMtoGen.CrearTablaPrincipal. Antes
  // este form creaba otro TdmPedidos en FormCreate; la carga async abria el
  // DM del padre y el grid quedaba enlazado al segundo DM, con las lineas
  // cerradas al pulsar "Añadir linea".
  dmmPedidos := (tdmDataModule as TdmPedidos);
  if not Assigned(dmmPedidos) then
  begin
    dmmPedidos := TdmPedidos.Create(Self);
    dsTablaG.DataSet := dmmPedidos.unqryTablaG;
    tdmDataModule := dmmPedidos;
  end;
  tvPedidosLineas.DataController.DataSource := dmmPedidos.dsPedidosLineas;
  tvAlbaranes.DataController.DataSource := dmmPedidos.dsAlbaranes;
  tvMensajes.DataController.DataSource := dmmPedidos.dsMensajes;
  cbbTotalesFORMA_PAGO_PED.Properties.ListSource := dmmPedidos.dsFormasPago;
  dmmPedidos.unqryPedidosLineas.MasterSource := dsTablaG;
  dmmPedidos.unqryAlbaranes.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_PED;NUMERO_PED';
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
  if not dmmPedidos.unqryPedidosLineas.Active then
    dmmPedidos.AbrirDetalles;
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
  sEmpresa, sSerie, sNumero, sAlm, sAlmComun, sAlmDefecto: string;
  EsAlmacenUnico, bAlmInit: Boolean;
  res: TSelAlmacenAlbaranResult;
  frmDocs: TfrmModalDocsCreados;
  bOk: Boolean;
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
    // Mientras recogemos las líneas a entregar, vamos comprobando si
    // todas comparten almacén (CODIGO_ALMACEN_PEDLIN).
    EsAlmacenUnico := True;
    bAlmInit       := False;
    sAlmComun      := '';
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
          sAlm := Trim(ds.FieldByName('CODIGO_ALMACEN_PEDLIN').AsString);
          if not bAlmInit then
          begin
            sAlmComun := sAlm;
            bAlmInit  := True;
          end
          else if sAlm <> sAlmComun then
            EsAlmacenUnico := False;
        end;
        ds.Next;
      end;
    finally
      ds.EnableControls;
    end;
    if lst.Count = 0 then
      ShowMessage(
        'No hay líneas con cantidad entregada para crear el albarán.')
    else
    begin
      sSerie  := dmmPedidos.unqryTablaG.FieldByName('SERIE_PED').AsString;
      sNumero := dmmPedidos.unqryTablaG.FieldByName('NUMERO_PED').AsString;
      sEmpresa := dmmPedidos.unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString;
      // Si todas las líneas a entregar son del mismo almacén, ese sale
      // preseleccionado en el modal; si no, el combo va vacío y obliga
      // a elegir el almacén del albarán.
      if EsAlmacenUnico and (Trim(sAlmComun) <> '') then
        sAlmDefecto := sAlmComun
      else
        sAlmDefecto := '';
      res := TfrmModalSelAlmacenAlbaran.Ejecutar(Self, sSerie, sNumero,
                                                 sEmpresa, sAlmDefecto);
      if res.Aceptado then
      begin
        // Segun lo elegido en el modal: crear albaran nuevo o anadir las
        // lineas a un albaran ya existente del propio pedido.
        if res.EsExistente then
          bOk := dmmPedidos.CrearAlbaranDesdePedido(sNumeroAlb, sSerieAlb,
                                                    lst, res.CodigoAlmacen,
                                                    res.NumeroAlb,
                                                    res.SerieAlb)
        else
          bOk := dmmPedidos.CrearAlbaranDesdePedido(sNumeroAlb, sSerieAlb,
                                                    lst, res.CodigoAlmacen);
        if bOk then
        begin
          // Mostrar el albaran creado / ampliado en un modal estilo
          // Sesiones, con boton "Ir a documento" para abrir su ficha.
          frmDocs := TfrmModalDocsCreados.Create(Self);
          // Bloqueamos el caFree del ancestro (FormClose lo pone) para
          // poder leer Confirmado tras ShowModal y liberarlo nosotros.
          frmDocs.OnClose := nil;
          try
            if res.EsExistente then
              frmDocs.lblTitulo.Caption :=
                Format('Lineas anadidas al albaran desde el pedido %s/%s',
                       [sSerie, sNumero])
            else
              frmDocs.lblTitulo.Caption :=
                Format('Albaran creado desde el pedido %s/%s',
                       [sSerie, sNumero]);
            frmDocs.Agregar('Albaran', sSerieAlb, sNumeroAlb,
                            res.CodigoAlmacen);
            frmDocs.ShowModal;
            if frmDocs.Confirmado then
              ShowMto(Self.Owner, 'Albaranes', sSerieAlb + ',' + sNumeroAlb);
          finally
            FreeAndNil(frmDocs);
          end;
        end
        else if res.EsExistente then
          ShowMessage('No se pudo anadir al albaran.')
        else
          ShowMessage('No se pudo crear el albaran.');
      end;
    end;
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

// "Ir a documento" (Ctrl+May+A) desde la pestania Albaranes del pedido:
// abre la ficha del albaran de venta seleccionado en la rejilla. Solo
// actua si esa pestania esta activa y hay un albaran en la fila actual.
procedure TfrmMtoPedidos.actIrDocumentoExecute(Sender: TObject);
var
  sSerie, sNumero: string;
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranes) and
     (dmmPedidos <> nil) and
     dmmPedidos.unqryAlbaranes.Active and
     (not dmmPedidos.unqryAlbaranes.IsEmpty) then
  begin
    sSerie  := Trim(dmmPedidos.unqryAlbaranes.FieldByName(
                    'SERIE_ALB').AsString);
    sNumero := Trim(dmmPedidos.unqryAlbaranes.FieldByName(
                    'NUMERO_ALB').AsString);
    if (sSerie <> '') and (sNumero <> '') then
      ShowMto(Self.Owner, 'Albaranes', sSerie + ',' + sNumero);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoPedidos);

end.
