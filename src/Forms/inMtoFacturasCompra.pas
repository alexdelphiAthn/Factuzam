{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasCompra                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de facturas de COMPRA.                                     }
{    Cabecera + lineas sobre fza_facturas_compra. Espejo simplificado         }
{    de inMtoFacturas adaptado a documento de compra (proveedor en            }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataFacturasCompra)             }
{    detecta transiciones de ESTADO_FACC en BeforePost y dispara en            }
{    AfterPost la generacion (ABIERTA -> CERRADA) o reversion                  }
{    (CERRADA -> ABIERTA) via inLibFacturasCompraMovimientos.                 }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoFacturasCompra;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Types,
  inMtoGen, dxSkinsCore, dxSkinBlue, dxSkinsForm,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  Vcl.Menus, JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls,
  cxRadioGroup, cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo,
  cxCheckBox, cxGroupBox, cxDBLabel, cxButtonEdit, cxGridBandedTableView,
  cxGridDBBandedTableView,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  UniDataFacturasCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList, cxSplitter;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';

type
  TfrmMtoFacturasCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcFactura:           TcxPageControl;
    tsLineasFactura:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasFactura:  TcxGrid;
    tvLineasFactura:     TcxGridDBTableView;
    cxgrdlvlLineasFactura: TcxGridLevel;

    // Cabecera
    lblNroFactura:    TcxLabel;
    txtNUMERO_FACC:   TcxDBTextEdit;
    lblSerieFactura:  TcxLabel;
    cbbSERIE_FACC:    TcxDBComboBox;
    lblFechaFactura:  TcxLabel;
    dteFECHA_FACC:    TcxDBDateEdit;
    lblEstadoFactura: TcxLabel;
    txtESTADO_FACC:   TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_FACC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_FACC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreFacc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_FACC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_FACC: TcxDBTextEdit;
    lblFormaPago: TcxLabel;
    cbbFORMA_PAGO_FACC: TcxDBLookupComboBox;
    tsEfectos: TcxTabSheet;
    pnlEfectosTop: TPanel;
    btnGenerarEfectos: TcxButton;
    btnRegistrarPago: TcxButton;
    cxgrdEfectos: TcxGrid;
    tvEfectos: TcxGridDBTableView;
    lvlEfectos: TcxGridLevel;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_FACC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_FACC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_FACC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_FACC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_FACC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_FACC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_FACC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_FACC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_FACC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_FACC: TcxDBCurrencyEdit;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasFacc: TcxLabel;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_FACC: TcxDBLookupComboBox;
    grpDesgloseImpuestos: TGroupBox;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de accion
    btnAnadirLinea:       TcxButton;
    btnBorrarLinea:       TcxButton;
    btnTallasHorizontal:  TcxButton;
    btnAtributosColumna:  TcxButton;
    btnImprimirH: TcxButton;
    btnImprimirV: TcxButton;
    btnPegatinas: TcxButton;
    ActionList1: TActionList;
    actArticulos: TAction;
    actIrProveedor: TAction;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnImprimirHClick(Sender: TObject);
    procedure btnImprimirVClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    // Eventos del grid de lineas — mismos handlers que en Sesiones de compra:
    // sin esto, las celdas talla quedan vacias al navegar, no se sombrean
    // las celdas fuera del conjunto pivot y Enter no salta de celda.
    procedure tvLineasFacturaFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasFacturaCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasFacturaEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasFacturaEnter(Sender: TObject);
    procedure cxgrdLineasFacturaExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_FACCPropertiesInitPopup(Sender: TObject);
    procedure cbbCODIGO_PRV_FACCPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_PRV_FACCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_PRV_FACCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure btnGenerarEfectosClick(Sender: TObject);
    procedure btnRegistrarPagoClick(Sender: TObject);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    FBasicosColor    : TArray<string>;
    FAplicandoArticulo: Boolean;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreFacc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataFacturasCompra
    // .unqryPrvDataFacc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    // Pinta lblTotalPrendasFacc con el total de prendas (suma de
    // CANTIDAD_FACCLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function BuscarArticuloFacturaCompra: string;
    function BuscarSkuFacturaCompra(const ACodigoArt: string): string;
    function ArticuloLineaActivaFacturaCompra: string;
    procedure AplicarArticuloFacturaCompra(const ACodigoArt: string);
    procedure colLineaFaccCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaFaccCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaFaccCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinFaccColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure PersistirPreferenciaPivote;
  public
    dmmFacturasCompra: TdmFacturasCompra;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoFacturasCompra: TfrmMtoFacturasCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFiltroUsuario,
  inLibFotos,
  inLibArticulosResolver,
  inLibArticulosValidador,
  inLibComprasImpuestos,
  inLibAtributosPaleta,
  UniDataArticulos,
  inMtoModalImpFacCompra,
  inMtoModalImpFacCompraV,
  inLibShowMto, inMtoModalRegistrarPago,
  inMtoModalSeleccionarBanco, inLibGenBusq, inLibtb;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoFacturasCompra.cbbSERIE_FACCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmFacturasCompra <> nil) and
     dmmFacturasCompra.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmFacturasCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_FACC').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  end;
  CargarSeriesEmpresa(sEmpresa, 'FP', cbbSERIE_FACC.Properties.Items);
  if cbbSERIE_FACC.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de facturas de compra (tipo FP) para la ' +
                  'empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera del factura de compra. El articulo
// activo vive en la fila del sub-grid tvLineasFactura
// (CODIGO_ART_FACCLIN / CODIGO_UNIDAD_FACCLIN).
procedure TfrmMtoFacturasCompra.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasFactura.DataController.DataSource) then
  begin
    ds := tvLineasFactura.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

// Para que la pantalla flotante refresque al moverse entre lineas del
// factura, ademas de dsTablaG (cabecera) enganchamos
// dsFacturasCompraLineas.
function TfrmMtoFacturasCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmFacturasCompra) then
    Result := [dsTablaG, dmmFacturasCompra.dsFacturasCompraLineas]
  else
    Result := [dsTablaG];
end;

function TfrmMtoFacturasCompra.BuscarArticuloFacturaCompra: string;
var
  qry : TUniQuery;
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmFacturasCompra) then
  begin
    sPrv := Trim(dmmFacturasCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_FACC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg('Selecciona un proveedor antes de buscar artículos.',
                 mtInformation, [mbOk], 0)
    else
    begin
      qry := TUniQuery.Create(nil);
      try
        qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
        qry.SQL.Text :=
          'SELECT art.CODIGO_ART_ART, art.ESACTIVO_ART, art.ORDEN_ART, ' +
          '       art.DESCRIPCION_ART, art.CODIGO_FAM_ART, ' +
          '       fam.DESCRIPCION_FAM, art.TIPO_IVA_ART, ' +
          '       iva.NOMBRE_TIPO_IVA_IVATIP, art.TIPO_CANTIDAD_ART, ' +
          '       ap.CODIGO_PRV_AP, prv.RAZON_SOCIAL_PRV, prv.NOMBRE_PRV, ' +
          '       ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
          '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP ' +
          '  FROM fza_articulos_proveedores ap ' +
          '  JOIN fza_articulos art ' +
          '    ON art.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
          '  LEFT JOIN fza_articulos_familias fam ' +
          '    ON fam.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
          '  LEFT JOIN fza_ivas_tipos iva ' +
          '    ON iva.CODIGO_ABREVIATURA_IVA_IVATIP = art.TIPO_IVA_ART ' +
          '  LEFT JOIN fza_proveedores prv ' +
          '    ON prv.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
          ' WHERE ap.CODIGO_PRV_AP = :prv ' +
          '   AND COALESCE(art.ESACTIVO_ART, ''S'') = ''S'' ' +
          ' ORDER BY art.ORDEN_ART, art.CODIGO_ART_ART';
        qry.ParamByName('prv').AsString := sPrv;
        if TBusquedaUtils.EjecutarBusqueda(
             'Búsqueda de artículos',
             qry,
             'frmMtoFaccArtSearch',
             Self) and (qry.FindField('CODIGO_ART_ART') <> nil) then
          Result := qry.FieldByName('CODIGO_ART_ART').AsString;
      finally
        FreeAndNil(qry);
      end;
    end;
  end;
end;

function TfrmMtoFacturasCompra.ArticuloLineaActivaFacturaCompra: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmFacturasCompra) then
  begin
    ds := dmmFacturasCompra.unqryFacturasCompraLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_FACCLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_FACCLIN').AsString);
  end;
end;

function TfrmMtoFacturasCompra.BuscarSkuFacturaCompra(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmFacturasCompra) then
    MessageDlg('No está abierta la factura de compra.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
        '       GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
        '                    AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
        '  FROM fza_articulos_skus SK ' +
        '  LEFT JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  LEFT JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = SA.ID_AV_SA ' +
        '  LEFT JOIN fza_variaciones_atributos VA ' +
        '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
        '   AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
        ' ORDER BY SK.CODIGO_UNIDAD_SKU';
      qry.ParamByName('art').AsString := sArt;
      if TBusquedaUtils.EjecutarBusqueda(
           'SKUs del artículo ' + sArt,
           qry,
           'frmMtoFaccSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
var
  q   : TUniQuery;
  i   : Integer;
  sArt: string;
begin
  SetLength(FBasicosColor, 0);
  sArt := Trim(ACodigoArt);
  if sArt <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := inLibGlobalVar.oConn;
      q.SQL.Text :=
        'SELECT ATB.CODIGO_ATB, MIN(ATB.ORDEN_ATB) AS ORDEN_ATB, ' +
        '       MIN(ATB.NOMBRE_ATB) AS NOMBRE_ATB ' +
        '  FROM fza_articulos_skus SK ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = SA.ID_AV_SA ' +
        '   AND AV.ID_VA_AV = :va ' +
        '  JOIN fza_atributos_basicos ATB ' +
        '    ON ATB.ID_VA_ATB = :va ' +
        '   AND (ATB.ID_ATB = AV.ID_ATB_AV ' +
        '        OR (AV.ID_ATB_AV IS NULL AND ATB.CODIGO_ATB = AV.AV)) ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        '   AND COALESCE(AV.ESACTIVO_AV, ''S'') = ''S'' ' +
        '   AND COALESCE(ATB.ESACTIVO_ATB, ''S'') = ''S'' ' +
        ' GROUP BY ATB.CODIGO_ATB ' +
        ' ORDER BY ORDEN_ATB, NOMBRE_ATB, ATB.CODIGO_ATB';
      q.ParamByName('va').AsString := ID_VA_COLOR;
      q.ParamByName('art').AsString := sArt;
      q.Open;
      SetLength(FBasicosColor, q.RecordCount);
      i := 0;
      while not q.Eof do
      begin
        FBasicosColor[i] := q.FieldByName('CODIGO_ATB').AsString;
        Inc(i);
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.FormCreate(Sender: TObject);
var
  colArt: TcxGridDBColumn;
  colSku: TcxGridDBColumn;
begin
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := tvLineasFactura.CreateColumn;
  FColColorPivot.Name    := 'colLinFaccColorPivot';
  FColColorPivot.Caption := 'Color';
  FColColorPivot.Width   := 110;
  FColColorPivot.Visible := False;
  FColColorPivot.Options.Editing := True;
  FColColorPivot.Options.ShowEditButtons := isebAlways;
  FColColorPivot.PropertiesClass := TcxButtonEditProperties;
  with TcxButtonEditProperties(FColColorPivot.Properties) do
  begin
    Buttons.Clear;
    with Buttons.Add do
      Kind := bkEllipsis;
    OnButtonClick := colLinFaccColorPivotButtonClick;
  end;
  inherited;
  colArt := tvLineasFactura.GetColumnByFieldName('CODIGO_ART_FACCLIN');
  if colArt <> nil then
  begin
    colArt.PropertiesClass := TcxButtonEditProperties;
    colArt.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colArt.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := colLineaFaccCODIGO_ARTPropertiesButtonClick;
      OnValidate := colLineaFaccCODIGO_ARTPropertiesValidate;
    end;
  end;
  colSku := tvLineasFactura.GetColumnByFieldName('CODIGO_UNIDAD_FACCLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := colLineaFaccCODIGO_UNIDADPropertiesButtonClick;
    end;
  end;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre facturas, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor de la factura enfocada al abrir el form.
  ActualizarLabelProveedor;
  ActualizarLabelPrendas;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesFacturaCompra).
  dmmFacturasCompra.unqryFacturasCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
end;

function TfrmMtoFacturasCompra.SqlRestriccionUsuario: string;
begin
  // Documentos de compra: empresa y almacén (no llevan caja)
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_FACC', 'CODIGO_ALM_FACC', '');
end;

procedure TfrmMtoFacturasCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms y la dejo en
  // tdmDataModule, ademas de enganchar dsTablaG.DataSet a su unqryTablaG.
  // Tomamos esa misma instancia; antes haciamos TdmFacturasCompra.Create
  // en FormCreate y enlazabamos el grid de lineas a un segundo DM cuyo
  // unqryFacturasCompraLineas nunca recibia el .Open de
  // AbrirTablaPrincipalAsync. Fallback Create(Self) por si la BBDD no
  // tiene la entrada en fza_winforms (migracion no aplicada).
  dmmFacturasCompra := (tdmDataModule as TdmFacturasCompra);
  if not Assigned(dmmFacturasCompra) then
  begin
    dmmFacturasCompra := TdmFacturasCompra.Create(Self);
    dsTablaG.DataSet := dmmFacturasCompra.unqryTablaG;
    // Sin esta linea, TfrmMtoGen.AbrirTablaPrincipalAsync ve
    // tdmDataModule=nil y aborta -> la query principal nunca se abre y
    // el form se queda vacio. Solo pasa cuando fza_winforms NO tiene la
    // entrada de FacturasCompra (BBDD sin la migracion aplicada); con
    // la entrada presente, el padre rellena tdmDataModule antes de
    // entrar a CrearTablaPrincipal y este bloque no se ejecuta.
    tdmDataModule := dmmFacturasCompra;
  end;
  tvLineasFactura.DataController.DataSource :=
    dmmFacturasCompra.dsFacturasCompraLineas;
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmFacturasCompra.unqryFacturasCompraLineas.MasterSource := dsTablaG;
  tvEfectos.DataController.DataSource := dmmFacturasCompra.dsEfectos;
  cbbFORMA_PAGO_FACC.Properties.ListSource :=
    dmmFacturasCompra.dsFormasPago;
  cbbTotalesFORMA_PAGO_FACC.Properties.ListSource :=
    dmmFacturasCompra.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataFacc, ya cargado para el rotulo.
  cbbCODIGO_PRV_FACC.Properties.ListSource := dmmFacturasCompra.dsPrvDataFacc;
  dmmFacturasCompra.unqryEfectos.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_FACC;NUMERO_FACC';
end;

procedure TfrmMtoFacturasCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoFacturasCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasFactura.CreateColumn;
    col.Name    := 'dbcLinFaccTalla' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 50;
    col.Tag     := i + 1;
    col.Visible := False;
    col.DataBinding.ValueTypeClass := TcxFloatValueType;
    col.PropertiesClass := TcxCurrencyEditProperties;
    curProps := TcxCurrencyEditProperties(col.Properties);
    curProps.DisplayFormat := '#,##0';
    FTallaColumns[i] := col;
  end;
end;

// Crea CANT_ATRIB_MAX columnas no-bound para mostrar los valores de
// los atributos del SKU de cada linea (modo "atributo por columna",
// estilo inventarios). Read-only y no persistentes: solo
// visualizacion. La carga real de valores por SKU queda como TODO.
procedure TfrmMtoFacturasCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasFactura.CreateColumn;
    col.Name    := 'dbcLinFaccAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoFacturasCompra.InicializarGestorYPivote;
var
  cfgT : TGridTallasConfig;
  cfgP : TGridPivoteCompraConfig;
  i    : Integer;
  arr  : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if FPivote       <> nil then FreeAndNil(FPivote);
  if dmmFacturasCompra = nil then Exit;
  SetLength(arr, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arr[i] := FTallaColumns[i];
  // 1. Gestor inline de tallas (libreria existente). Mismo patron que
  //    Sesiones, con los nombres FACC/FACCLIN/FACCCEL.
  cfgT := Default(TGridTallasConfig);
  cfgT.Conexion           := dmmFacturasCompra.unqryTablaG.Connection;
  cfgT.Usuario            := oUser;
  cfgT.Grid               := tvLineasFactura;
  cfgT.SourceMaster       := dsTablaG;
  cfgT.SourceLineas       := dmmFacturasCompra.dsFacturasCompraLineas;
  cfgT.ColumnasTallas     := arr;
  cfgT.FieldSerieMaster   := 'SERIE_FACC';
  cfgT.FieldNumeroMaster  := 'NUMERO_FACC';
  cfgT.FieldLinea         := 'LINEA_FACCLIN';
  cfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_FACCLIN';
  cfgT.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN';
  cfgT.FieldTotalUds      := 'TOTAL_UNIDADES_FACCLIN';
  cfgT.FieldTotalLinea    := 'TOTAL_FACCLIN';
  cfgT.TablaCeldas        := 'fza_facturas_compra_celdas';
  cfgT.FieldSerieCel      := 'SERIE_FACC_FACCCEL';
  cfgT.FieldNumeroCel     := 'NUMERO_FACC_FACCCEL';
  cfgT.FieldLineaCel      := 'LINEA_FACC_FACCCEL';
  cfgT.FieldFilaCel       := 'ID_FILA_FACC_FACCCEL';
  cfgT.FieldAvPivotCel    := 'ID_AV_PIVOT_FACCCEL';
  cfgT.FieldCantidadCel   := 'CANTIDAD_FACCCEL';
  cfgT.FieldAlmacenCel    := 'CODIGO_ALM_FACCCEL';
  cfgT.IdFilaFijo         := 1;
  cfgT.MaxColumnas        := CANT_TALLAS_MAX;
  FGestorTallas := TGestorGridTallas.Create(cfgT);
  // Hookea el OnEditValueChanged de cada columna talla al gestor para
  // que persista la celda y refresque totales al teclear.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
    begin
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnEditValueChanged := TallaEditValueChangedHook;
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).
        OnValidate := TallaValidateHook;
    end;
  // 2. Orquestador de pivote (libreria nueva, compartida con pedidos).
  cfgP := Default(TGridPivoteCompraConfig);
  cfgP.Conexion             := dmmFacturasCompra.unqryTablaG.Connection;
  cfgP.Grid                 := tvLineasFactura;
  cfgP.SourceMaster         := dsTablaG;
  cfgP.SourceLineas         := dmmFacturasCompra.unqryFacturasCompraLineas;
  cfgP.Gestor               := FGestorTallas;
  cfgP.ColColorPivot        := FColColorPivot;
  cfgP.ColumnasTallas       := arr;
  cfgP.MaxColumnasTallas    := CANT_TALLAS_MAX;
  cfgP.TablaLineas          := 'fza_facturas_compra_lineas';
  cfgP.FieldSerieMaster     := 'SERIE_FACC';
  cfgP.FieldNumeroMaster    := 'NUMERO_FACC';
  cfgP.FieldSerieLin        := 'SERIE_FACC_FACCLIN';
  cfgP.FieldNumeroLin       := 'NUMERO_FACC_FACCLIN';
  cfgP.FieldLinea           := 'LINEA_FACCLIN';
  cfgP.FieldArt             := 'CODIGO_ART_FACCLIN';
  cfgP.FieldSku             := 'CODIGO_UNIDAD_FACCLIN';
  cfgP.FieldCantidad        := 'CANTIDAD_FACCLIN';
  cfgP.FieldPrecioBase      := 'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN';
  cfgP.FieldTotalUds        := 'TOTAL_UNIDADES_FACCLIN';
  cfgP.FieldTotalLinea      := 'TOTAL_FACCLIN';
  cfgP.FieldIdAcPivot       := 'ID_AC_PIVOT_FACCLIN';
  cfgP.FieldAlmacen         := 'CODIGO_ALMACEN_FACCLIN';
  cfgP.FieldAlmacenMaster   := 'CODIGO_ALM_FACC';
  cfgP.CamposOcultosEnPivote := TArray<string>.Create(
    'CODIGO_UNIDAD_FACCLIN',
    'CANTIDAD_FACCLIN',
    'TOTAL_FACCLIN');
  FPivote := TGridPivoteCompra.Create(cfgP);
end;

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadTallas;
var
  i: Integer;
begin
  // Sin pivote activo: ocultar todas las columnas talla. Con pivote
  // activo: delega en el gestor para mostrar solo las que aplican y
  // pintar captions. La carga de cantidades del pivote la hace el
  // controlador (no usamos FGestorTallas.CargarCantidadesTodasLineas
  // porque en compras la cantidad por SKU vive en la linea, no en
  // una tabla de celdas como en sesiones).
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
  begin
    for i := 0 to CANT_TALLAS_MAX - 1 do
      if FTallaColumns[i] <> nil then
        FTallaColumns[i].Visible := False;
    Exit;
  end;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
end;

procedure TfrmMtoFacturasCompra.RefrescarVisibilidadAtributos;
var
  i: Integer;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Visible := FMostrarAtributos;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributos del articulo de la linea con foco y
// los aplica como captions de las columnas ATTRn. La carga de los
// VALORES por SKU se hara en un hito posterior (cuando este el flujo
// completo de edicion de SKU por talla / color).
procedure TfrmMtoFacturasCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmFacturasCompra = nil then Exit;
  qry := dmmFacturasCompra.unqryDefArticuloFacc;
  if qry = nil then Exit;

  // Reset de captions a placeholder.
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);

  if (dmmFacturasCompra.unqryFacturasCompraLineas = nil) or
     (not dmmFacturasCompra.unqryFacturasCompraLineas.Active) or
     (dmmFacturasCompra.unqryFacturasCompraLineas.IsEmpty) then Exit;
  sArt := dmmFacturasCompra.unqryFacturasCompraLineas.
            FieldByName('CODIGO_ART_FACCLIN').AsString;
  if sArt = '' then Exit;

  qry.Close;
  qry.ParamByName('ARTICULO').AsString := sArt;
  qry.Open;
  iCol := 0;
  while (not qry.Eof) and (iCol < CANT_ATRIB_MAX) do
  begin
    if FAtribColumns[iCol] <> nil then
      FAtribColumns[iCol].Caption :=
        qry.FieldByName('NOMBRE_ATRIBUTO').AsString;
    Inc(iCol);
    qry.Next;
  end;
  qry.Close;
end;

procedure TfrmMtoFacturasCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmFacturasCompra = nil) or (FPivote = nil) then Exit;
  // Guardia de reentrada: ver comentario en el campo FInToggleClick.
  if FInToggleClick then Exit;
  FInToggleClick := True;
  try
    // Toggle alterna entre vista plana (1 fila por SKU) y vista pivote
    // (1 fila representante por articulo+color, columnas talla con la
    // cantidad de cada SKU). El modelo BBDD no cambia: el filtro vive
    // en cliente y lo gestiona la libreria.
    if not FPivote.Activo then
    begin
      if not FPivote.ValidarPivotePosible(sMensaje) then
      begin
        // Sender=nil => apertura automatica con la preferencia por
        // defecto (horizontal). Si el documento no es pivotable dejamos
        // la vista vertical en silencio; solo avisamos cuando el usuario
        // pulsa el boton expresamente (Sender<>nil).
        if Sender <> nil then
          MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        Exit;
      end;
      FPivote.Activar;
    end
    else
      FPivote.Desactivar;
    // Sender=nil: llamada automatica desde el data-change hook; no
    // re-escribir la preferencia.
    if Sender <> nil then
      PersistirPreferenciaPivote;
  finally
    FInToggleClick := False;
  end;
end;

procedure TfrmMtoFacturasCompra.PersistirPreferenciaPivote;
begin
  // Persiste el modo en la cabecera para que la proxima apertura del
  // factura arranque ya en el modo elegido.
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty or
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_FACC') = nil) then
    Exit;
  if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
    dsTablaG.DataSet.Edit;
  dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString :=
    IfThen(FPivote.Activo, 'S', 'N');
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoFacturasCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintFacCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if dmmFacturasCompra = nil then
    ShowMessage('No hay factura de compra activa que imprimir.')
  else if dmmFacturasCompra.unqryTablaG.IsEmpty then
    ShowMessage('No hay factura de compra activa que imprimir.')
  else
  begin
    if dmmFacturasCompra.unqryTablaG.State in [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryTablaG.Post;
    if dmmFacturasCompra.unqryFacturasCompraLineas.State in
       [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryFacturasCompraLineas.Post;
    sSerie  := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'SERIE_FACC').AsString;
    sNumero := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'NUMERO_FACC').AsString;
    form := TfrmPrintFacCompra.Create(Application);
    try
      form.dmFacc         := dmmFacturasCompra;
      form.edtSerie.Text  := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintFacCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if dmmFacturasCompra = nil then
    ShowMessage('No hay factura de compra activa que imprimir.')
  else if dmmFacturasCompra.unqryTablaG.IsEmpty then
    ShowMessage('No hay factura de compra activa que imprimir.')
  else
  begin
    if dmmFacturasCompra.unqryTablaG.State in [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryTablaG.Post;
    if dmmFacturasCompra.unqryFacturasCompraLineas.State in
       [dsEdit, dsInsert] then
      dmmFacturasCompra.unqryFacturasCompraLineas.Post;
    sSerie  := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'SERIE_FACC').AsString;
    sNumero := dmmFacturasCompra.unqryTablaG.FieldByName(
                 'NUMERO_FACC').AsString;
    form := TfrmPrintFacCompraV.Create(Application);
    try
      form.dmFacc         := dmmFacturasCompra;
      form.edtSerie.Text  := sSerie;
      form.edtNumero.Text := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnPegatinasClick(Sender: TObject);
begin
  inherited;
  ShowMessage('Etiquetas de borrador de compra: pendiente (hito de ' +
              'informes).');
end;

procedure TfrmMtoFacturasCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoFacturasCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcFactura.ActivePage := tsLineasFactura;
end;

procedure TfrmMtoFacturasCompra.btnGrabarClick(Sender: TObject);
begin
  if Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadesPendientes;
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmFacturasCompra.CalcularTotalesFacturaCompra;
    dsTablaG.DataSet.Post;
  end;
  // Tras Grabar, cxGrid borra los Values[] no-bound al repintar.
  // RecargarYRepublicar lo solventa.
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil) que dispara cxGrid al cambiar de record activo. Sincroniza
// el toggle con la preferencia guardada en la cabecera y dispara la
// recarga del controlador de pivote.
procedure TfrmMtoFacturasCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
var
  bDeberiaEstarActivo: Boolean;
begin
  // Refrescar el rotulo del proveedor al navegar entre facturas (Field=nil)
  // o al cambiar CODIGO_PRV_FACC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_FACC') then
    ActualizarLabelProveedor;
  // Al navegar entre facturas hay que recalcular el total de prendas: las
  // lineas cargadas son las de la factura recien enfocada.
  if Field = nil then
    ActualizarLabelPrendas;
  if Field <> nil then Exit;
  if FPivote = nil then Exit;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_FACC') <> nil) then
  begin
    // Por defecto la vista es horizontal: solo un 'N' explicito
    // (excepcion que el usuario guardo a mano) la mantiene vertical.
    // NULL / vacio / 'S' abren en horizontal.
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString <> 'N';
    if bDeberiaEstarActivo and (not FPivote.Activo) then
      btnTallasHorizontalClick(nil)
    else if (not bDeberiaEstarActivo) and FPivote.Activo then
      btnTallasHorizontalClick(nil);
  end;
  if not FPivote.Activo then Exit;
  // RecargarYRepublicar ya hace RecalcularMaxColumnas + Captions
  // ANTES de publicar. Llamar a RefrescarVisibilidadTallas aqui haria
  // un segundo RecalcularMax tras publicar y limpiaria los Values[]
  // recien puestos.
  FPivote.RecargarYRepublicar;
end;

procedure TfrmMtoFacturasCompra.ActualizarLabelProveedor;
var
  sCodigo : string;
  sNombre : string;
  sRazon  : string;
begin
  // Resuelve NOMBRE_PRV + RAZON_SOCIAL_PRV (via el lookup unqryPrvDataFacc)
  // y los pinta en el rotulo. Se antepone el nombre comercial: es el que
  // el usuario reconoce a simple vista; la razon social solo se anade
  // entre parentesis como referencia si difiere.
  sCodigo := '';
  if (dmmFacturasCompra <> nil) and Assigned(dmmFacturasCompra.unqryTablaG) and
     dmmFacturasCompra.unqryTablaG.Active and
     (not dmmFacturasCompra.unqryTablaG.IsEmpty) then
    sCodigo :=
      Trim(dmmFacturasCompra.unqryTablaG.FieldByName('CODIGO_PRV_FACC').AsString);
  if sCodigo = '' then
    lblProveedorNombreFacc.Caption := ''
  else if (dmmFacturasCompra.unqryPrvDataFacc <> nil) and
          dmmFacturasCompra.unqryPrvDataFacc.Active and
          dmmFacturasCompra.unqryPrvDataFacc.Locate('CODIGO_PRV_PRV', sCodigo, []) then
  begin
    sRazon  := dmmFacturasCompra.unqryPrvDataFacc.FieldByName('RAZON_SOCIAL_PRV').AsString;
    sNombre := dmmFacturasCompra.unqryPrvDataFacc.FieldByName('NOMBRE_PRV').AsString;
    // Si no hay nombre comercial cargado, caemos a la razon social como
    // rotulo principal. Si hay nombre y difiere de la razon social, la
    // razon social se anade entre parentesis como referencia.
    if Trim(sNombre) = '' then
      lblProveedorNombreFacc.Caption := sCodigo + ' - ' + sRazon
    else if not SameText(Trim(sNombre), Trim(sRazon)) then
      lblProveedorNombreFacc.Caption :=
        sCodigo + ' - ' + sNombre + '  (' + sRazon + ')'
    else
      lblProveedorNombreFacc.Caption := sCodigo + ' - ' + sNombre;
  end
  else
    lblProveedorNombreFacc.Caption := sCodigo + ' - (proveedor no encontrado)';
end;

procedure TfrmMtoFacturasCompra.ActualizarLabelPrendas;
begin
  if (dmmFacturasCompra <> nil) and Assigned(dmmFacturasCompra.unqryTablaG) and
     dmmFacturasCompra.unqryTablaG.Active and
     (not dmmFacturasCompra.unqryTablaG.IsEmpty) then
    lblTotalPrendasFacc.Caption :=
      FormatFloat('#,##0', dmmFacturasCompra.TotalPrendasFactura)
  else
    lblTotalPrendasFacc.Caption := '0';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesFacturaCompra) con la republicacion del controlador.
procedure TfrmMtoFacturasCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmFacturasCompra) then
    dmmFacturasCompra.CalcularTotalesFacturaCompra;
  ActualizarLabelPrendas;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoFacturasCompra.tvLineasFacturaFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if Assigned(FGestorTallas) and Assigned(FPivote) and FPivote.Activo then
    FGestorTallas.ActualizarCaptionsLineaActiva;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Sombreado de celdas talla fuera del conjunto pivot — delegamos en lib.
procedure TfrmMtoFacturasCompra.tvLineasFacturaCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoFacturasCompra.tvLineasFacturaEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.EditingCeldaTalla(Sender, AItem, AAllow);
end;

// Apaga TJvEnterAsTab al entrar al grid para que Enter navegue de
// celda a celda (combinado con FocusCellOnTab del grid en el DFM) y lo
// reactiva al salir. Misma logica que en Sesiones.
procedure TfrmMtoFacturasCompra.cxgrdLineasFacturaEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;

procedure TfrmMtoFacturasCompra.cxgrdLineasFacturaExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoFacturasCompra.TallaEditValueChangedHook(Sender: TObject);
begin
  if Assigned(FPivote) and FPivote.Activo then
  begin
    if FPivote.Expandido then
      FPivote.CapturarARecibirEditValueChanged(Sender)
    else
      FPivote.CapturarCantidadEditValueChanged(Sender);
  end
  else if Assigned(FGestorTallas) then
    FGestorTallas.PersistirCeldaActiva(Sender);
end;

procedure TfrmMtoFacturasCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

procedure TfrmMtoFacturasCompra.AsegurarCabeceraPersistidaParaLineas;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
begin
  if not Assigned(dmmFacturasCompra) then
    raise Exception.Create('No esta inicializada la factura de compra.')
  else
  begin
    dsCab := dmmFacturasCompra.unqryTablaG;
    dsLin := dmmFacturasCompra.unqryFacturasCompraLineas;
    if (dsCab = nil) or (not dsCab.Active) or dsCab.IsEmpty then
      raise Exception.Create(
        'Crea o selecciona una factura antes de añadir lineas.');
    sNumero := Trim(dsCab.FieldByName('NUMERO_FACC').AsString);
    if Assigned(dsLin) and dsLin.Active and (dsLin.State = dsInsert) then
    begin
      if (sNumero = '') or (sNumero = '0') then
        dsLin.Cancel
      else if (Trim(dsLin.FieldByName('CODIGO_ART_FACCLIN').AsString) = '') and
              (Trim(dsLin.FieldByName('CODIGO_UNIDAD_FACCLIN').AsString) = '')
              then
        dsLin.Cancel;
    end;
    if (dsCab.State in dsEditModes) or (sNumero = '') or (sNumero = '0') then
    begin
      if not (dsCab.State in dsEditModes) then
        dsCab.Edit;
      if (dsCab.FindField('ESPIVOTE_HORIZONTAL_FACC') <> nil) and
         (Trim(dsCab.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString) = '')
         then
        dsCab.FieldByName('ESPIVOTE_HORIZONTAL_FACC').AsString := 'S';
      dsCab.Post;
    end;
    if Assigned(dsLin) and dsLin.Active and
       (not (dsLin.State in dsEditModes)) then
    begin
      dsLin.Close;
      dsLin.Open;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.AplicarArticuloFacturaCompra(
  const ACodigoArt: string);
var
  ds         : TDataSet;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  qry        : TUniQuery;
  sInput     : string;
  sPrv       : string;
  sAlm       : string;
  sModeloPrv : string;
  dFecha     : TDateTime;
  iAcPivot   : Integer;
  rCantidad  : Double;

  function CampoCabeceraString(const ACampo: string): string;
  var
    Campo: TField;
  begin
    Result := '';
    Campo := dmmFacturasCompra.unqryTablaG.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function FechaCabecera: TDateTime;
  var
    Campo: TField;
  begin
    Result := Date;
    Campo := dmmFacturasCompra.unqryTablaG.FindField('FECHA_FACC');
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsDateTime;
  end;

  function ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string): Integer;
  begin
    Result := 0;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT aca.ID_AC_ACA ' +
        '  FROM fza_articulos_conjuntos_asign aca ' +
        ' WHERE aca.CODIGO_ART_ACA = :art ' +
        '   AND aca.ID_VA_ACA <> ''CO'' ' +
        ' ORDER BY aca.ID_VA_ACA ' +
        ' LIMIT 1';
      qry.ParamByName('art').AsString := ACodigoArticulo;
      qry.Open;
      if not qry.IsEmpty then
        Result := qry.FieldByName('ID_AC_ACA').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;

  function ModeloProveedorArticulo(const ACodigoArticulo,
                                        ACodigoProveedor: string): string;
  begin
    Result := '';
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmFacturasCompra.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT ap.REF_PROVEEDOR_AP ' +
        '  FROM fza_articulos_proveedores ap ' +
        ' WHERE ap.CODIGO_ART_AP = :art ' +
        '   AND COALESCE(TRIM(ap.REF_PROVEEDOR_AP), '''') <> '''' ' +
        ' ORDER BY CASE WHEN ap.CODIGO_PRV_AP = :prv THEN 0 ELSE 1 END, ' +
        '          CASE ap.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ' +
        '               ELSE 1 END, ' +
        '          ap.FECHA_VALIDEZ_AP DESC, ap.CODIGO_PRV_AP ' +
        ' LIMIT 1';
      qry.ParamByName('art').AsString := ACodigoArticulo;
      qry.ParamByName('prv').AsString := ACodigoProveedor;
      qry.Open;
      if not qry.IsEmpty then
        Result := qry.FieldByName('REF_PROVEEDOR_AP').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;

  procedure PonerString(const ACampo, AValor: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsString := AValor;
  end;

  procedure PonerFloat(const ACampo: string; AValor: Double);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsFloat := AValor;
  end;

  procedure PonerInteger(const ACampo: string; AValor: Integer);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.AsInteger := AValor;
  end;

  procedure LimpiarCampo(const ACampo: string);
  var
    Campo: TField;
  begin
    Campo := ds.FindField(ACampo);
    if Campo <> nil then
      Campo.Clear;
  end;

  procedure EnfocarSku(AAbrirBusqueda: Boolean);
  var
    colSku: TcxGridDBColumn;
  begin
    colSku := tvLineasFactura.GetColumnByFieldName('CODIGO_UNIDAD_FACCLIN');
    if colSku <> nil then
    begin
      colSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasFactura.Controller.FocusedColumn := colSku;
          tvLineasFactura.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            colLineaFaccCODIGO_UNIDADPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmFacturasCompra) and
     (not FAplicandoArticulo) then
  begin
    ds := dmmFacturasCompra.unqryFacturasCompraLineas;
    if Assigned(ds) and ds.Active then
    begin
      FAplicandoArticulo := True;
      Validador := nil;
      Resolver := nil;
      try
        if ds.IsEmpty then
          ds.Append;
        if not (ds.State in dsEditModes) then
          ds.Edit;
        sPrv := CampoCabeceraString('CODIGO_PRV_FACC');
        sAlm := CampoCabeceraString('CODIGO_ALM_FACC');
        dFecha := FechaCabecera;
        Validador := TArticulosValidador.Create(
                       dmmFacturasCompra.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmFacturasCompra.unqryTablaG.Connection);
        Resolucion := Validador.Resolver(sInput);
        if Resolucion.Encontrado then
        begin
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                          Resolucion.CodigoSku,
                                          '',
                                          dFecha,
                                          sAlm,
                                          sPrv);
          if Datos.Encontrado then
          begin
            if Datos.RequiereSku then
              Datos.UltimoCoste := Resolver.ResolverUltimoCoste(
                Datos.CodigoArticulo, sPrv, '');
            iAcPivot := ResolverConjuntoPivotArticulo(Datos.CodigoArticulo);
            sModeloPrv := ModeloProveedorArticulo(Datos.CodigoArticulo, sPrv);
            if sModeloPrv = '' then
              sModeloPrv := Datos.UltimoCoste.RefProveedor;
            PonerString('CODIGO_ART_FACCLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_FACCLIN', Datos.CodigoSku);
            PonerString('REF_PRV_FACCLIN', sModeloPrv);
            PonerString('CODIGO_FAM_FACCLIN', Datos.CodigoFamilia);
            PonerString('NOMBRE_FAM_FACCLIN', Datos.DescripcionFamilia);
            PonerString('DESCRIPCION_ARTICULO_FACCLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_FACCLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_FACCLIN', Datos.TipoIVA);
            if sAlm <> '' then
              PonerString('CODIGO_ALMACEN_FACCLIN', sAlm);
            if iAcPivot > 0 then
              PonerInteger('ID_AC_PIVOT_FACCLIN', iAcPivot)
            else
              LimpiarCampo('ID_AC_PIVOT_FACCLIN');
            rCantidad := 0;
            if ds.FindField('CANTIDAD_FACCLIN') <> nil then
              rCantidad := ds.FieldByName('CANTIDAD_FACCLIN').AsFloat;
            if Datos.RequiereSku and (Datos.CodigoSku = '') then
            begin
              PonerFloat('CANTIDAD_FACCLIN', 0);
              PonerFloat('TOTAL_UNIDADES_FACCLIN', 0);
              rCantidad := 0;
            end
            else if rCantidad = 0 then
            begin
              rCantidad := 1;
              PonerFloat('CANTIDAD_FACCLIN', rCantidad);
              PonerFloat('TOTAL_UNIDADES_FACCLIN', rCantidad);
            end
            else
              PonerFloat('TOTAL_UNIDADES_FACCLIN', rCantidad);
            PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN',
                       Datos.UltimoCoste.PrecioUltCompra);
            PonerFloat('TOTAL_FACCLIN',
                       rCantidad * Datos.UltimoCoste.PrecioUltCompra);
            PrepararLineaFiscalCompra(
              dmmFacturasCompra.unqryTablaG.Connection,
              dmmFacturasCompra.unqryTablaG, ds, 'FACC', 'FACCLIN',
              'TOTAL_FACCLIN');
            if Assigned(FPivote) and
               (CampoCabeceraString('ESPIVOTE_HORIZONTAL_FACC') <> 'N') then
            begin
              if not FPivote.Activo then
                btnTallasHorizontalClick(nil);
              if FPivote.Activo then
              begin
                if ds.State in dsEditModes then
                  ds.Post;
                FPivote.RecargarYRepublicar;
              end;
            end;
            if Datos.RequiereSku and (Datos.CodigoSku = '') and
               ((FPivote = nil) or (not FPivote.Activo)) then
              EnfocarSku(True);
            RefrescarVisibilidadTallas;
            if FMostrarAtributos then
              CargarCaptionsAtributosLineaActiva;
            if Assigned(FPivote) and FPivote.Activo and
               (ds.State in dsEditModes) then
              ds.Post;
          end
          else if Datos.Mensaje <> '' then
            MessageDlg(Datos.Mensaje, mtWarning, [mbOk], 0);
        end
        else if Resolucion.Mensaje <> '' then
          MessageDlg(Resolucion.Mensaje, mtWarning, [mbOk], 0);
      finally
        FreeAndNil(Resolver);
        FreeAndNil(Validador);
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloFacturaCompra;
  if sCodigo <> '' then
    AplicarArticuloFacturaCompra(sCodigo);
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_ARTPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloFacturaCompra(sCodigo);
      if Assigned(dmmFacturasCompra) and
         dmmFacturasCompra.unqryFacturasCompraLineas.Active and
         (dmmFacturasCompra.unqryFacturasCompraLineas.
            FindField('CODIGO_ART_FACCLIN') <> nil) then
        DisplayValue := dmmFacturasCompra.unqryFacturasCompraLineas.
                          FieldByName('CODIGO_ART_FACCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.colLineaFaccCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaFacturaCompra;
  sSku := BuscarSkuFacturaCompra(sArt);
  if sSku <> '' then
    AplicarArticuloFacturaCompra(sSku);
end;

procedure TfrmMtoFacturasCompra.colLinFaccColorPivotButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt    : string;
  sActual : string;
  sNuevo  : string;
  sMensaje: string;
  Edit    : TWinControl;
  ScrPt   : TPoint;
  WidHint : Integer;
begin
  if (FPivote = nil) or (not FPivote.Activo) then
  begin
    MessageDlg('Activa las tallas en horizontal antes de elegir color.',
               mtInformation, [mbOk], 0);
  end
  else
  begin
    sArt := ArticuloLineaActivaFacturaCompra;
    if sArt = '' then
      MessageDlg('Selecciona un artículo antes de elegir color.',
                 mtInformation, [mbOk], 0)
    else
    begin
      CargarBasicosColorArticulo(sArt);
      if Length(FBasicosColor) = 0 then
        MessageDlg('El artículo "' + sArt + '" no tiene colores básicos ' +
                   'activos en sus SKUs.',
                   mtInformation, [mbOk], 0)
      else
      begin
        sActual := FPivote.ColorCodigoLineaActiva;
        ScrPt.X := -1;
        ScrPt.Y := -1;
        WidHint := FColColorPivot.Width;
        if Sender is TWinControl then
        begin
          Edit := TWinControl(Sender);
          ScrPt := Edit.ClientToScreen(Point(0, Edit.Height));
          WidHint := Edit.Width;
        end;
        if SeleccionarAvConPaleta(ID_VA_COLOR, FBasicosColor, sActual,
                                  sNuevo, ScrPt.X, ScrPt.Y, WidHint) then
        begin
          if FPivote.CambiarColorLineaActiva(sNuevo, sMensaje) then
            FPivote.RecargarYRepublicar
          else if sMensaje <> '' then
            MessageDlg(sMensaje, mtWarning, [mbOk], 0);
        end
      end;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  with tvLineasFactura.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ART_FACCLIN').AsString);
end;

procedure TfrmMtoFacturasCompra.actIrProveedorExecute(Sender: TObject);
var
  sPrv: string;
begin
  sPrv := '';
  if Assigned(dmmFacturasCompra) and
     (not dmmFacturasCompra.unqryTablaG.IsEmpty) then
    sPrv := Trim(dmmFacturasCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_FACC').AsString);
  if sPrv = '' then
    ShowMto(Self.Owner, 'Proveedores')
  else
    ShowMto(Self.Owner, 'Proveedores', sPrv);
end;

procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  // Al cargar/cambiar el proveedor, precarga su forma de pago en la cabecera.
  if (Assigned(dmmFacturasCompra) and Assigned(dsTablaG.DataSet) and
      ((dsTablaG.DataSet.State = dsInsert) or
       (dsTablaG.DataSet.State = dsEdit))) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := VarToStr(e.EditingValue);
    dmmFacturasCompra.CargarFormaPagoProveedor(sCodigo);
  end;
  ActualizarLabelProveedor;
end;

// Boton "..." del combo de proveedor: busqueda modal por nombre/razon
// social, acceso alternativo a la busqueda incremental por codigo del
// propio combo.
procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmFacturasCompra) then
  begin
    ds := dmmFacturasCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg('Crea o selecciona una factura de compra antes de ' +
                 'elegir el proveedor.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
              'Búsqueda de proveedores',
              'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
              'CODIGO_PRV_PRV',
              sCodigo,
              'frmMtoFaccProvSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_FACC').AsString := sCodigo;
      dmmFacturasCompra.CargarFormaPagoProveedor(sCodigo);
      ActualizarLabelProveedor;
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.cbbCODIGO_PRV_FACCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_FACCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoFacturasCompra.btnGenerarEfectosClick(Sender: TObject);
var
  iRes: Integer;
  sEmp, sPrv, sPref: string;
  selBanco: TSeleccionBancoResult;
begin
  inherited;
  if Assigned(dmmFacturasCompra) then
  begin
    // Cuenta de la empresa (cargo) para el pago: eleccion manual, con el
    // banco por defecto del proveedor pre-seleccionado si lo tiene.
    sEmp  := dsTablaG.DataSet.FieldByName('CODIGO_EMP_FACC').AsString;
    sPrv  := dsTablaG.DataSet.FieldByName('CODIGO_PRV_FACC').AsString;
    sPref := dmmFacturasCompra.GetBancoDefectoProveedor(sPrv);
    selBanco := TfrmModalSeleccionarBanco.Ejecutar(Self, inLibGlobalVar.oConn,
                                                   sEmp, ubePago, sPref);
    if not selBanco.Aceptado then
      ShowMessage('Generación de efectos cancelada.')
    else
    begin
      iRes := dmmFacturasCompra.GenerarEfectos(selBanco.CodigoEmpban,
                                               selBanco.Iban);
      if iRes > 0 then
        ShowMessage(Format('Generados %d efecto(s) de pago.', [iRes]))
      else if iRes = 0 then
        ShowMessage('No se generaron efectos. Revisa que el borrador tenga ' +
                    'forma de pago y total, y que no tenga ya efectos ' +
                    'pagados ' +
                    'o remesados.')
      else
        ShowMessage('No hay borrador activo (o hubo un error al generar).');
    end;
  end;
end;

procedure TfrmMtoFacturasCompra.btnRegistrarPagoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmFacturasCompra) and
     (dmmFacturasCompra.unqryEfectos <> nil) and
     dmmFacturasCompra.unqryEfectos.Active and
     (not dmmFacturasCompra.unqryEfectos.IsEmpty) then
  begin
    q     := dmmFacturasCompra.unqryEfectos;
    iEfe  := q.FieldByName('NUMERO_EFEC').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(
        Format('Efecto %d - vto %s - pendiente %.2f',
          [iEfe,
           FormatDateTime('dd/mm/yyyy',
             q.FieldByName('FECHA_VENCIMIENTO_EFEC').AsDateTime),
           fPend]),
        fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmFacturasCompra.RegistrarPagoEfecto(iEfe, frm.Fecha,
                  frm.Importe, frm.Tipo, frm.Referencia);
        if iRes > 0 then
          ShowMessage('Efecto conciliado.')
        else
          ShowMessage('No se pudo conciliar el efecto.');
      end;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage('Selecciona un efecto en la rejilla de la pestana Efectos.');
end;

procedure TfrmMtoFacturasCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  dmmFacturasCompra.unqryFacturasCompraLineas.Append;
end;

procedure TfrmMtoFacturasCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmFacturasCompra.unqryFacturasCompraLineas.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasCompra);
end.
