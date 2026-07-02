{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlbaranesCompra                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de albaranes de COMPRA.                                     }
{    Cabecera + lineas sobre fza_albaranes_compra. Espejo simplificado         }
{    de inMtoAlbaranes adaptado a documento de compra (proveedor en            }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataAlbaranesCompra)             }
{    reconstruye los movimientos AC desde las lineas actuales del              }
{    documento para mantener el kardex sincronizado tras correcciones.         }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoAlbaranesCompra;

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
  UniDataAlbaranesCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList;

const
  CANT_TALLAS_MAX = 20;
  CANT_ATRIB_MAX  = 5;
  ID_VA_COLOR     = 'CO';

type
  TfrmMtoAlbaranesCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcAlbaran:           TcxPageControl;
    tsLineasAlbaran:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasAlbaran:  TcxGrid;
    tvLineasAlbaran:     TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    tsProveedor:         TcxTabSheet;
    cxgrdMovimientosProveedor: TcxGrid;
    tvMovimientosProveedor: TcxGridDBTableView;
    cxgrdlvlMovimientosProveedor: TcxGridLevel;

    // Cabecera
    lblNroAlbaran:    TcxLabel;
    txtNUMERO_ALBC:   TcxDBTextEdit;
    lblSerieAlbaran:  TcxLabel;
    // Serie en combo editable: lista las series 'AB' de la empresa
    // (fza_empresas_series) y permite teclear una nueva.
    cbbSERIE_ALBC:    TcxDBComboBox;
    lblFechaAlbaran:  TcxLabel;
    dteFECHA_ALBC:    TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALBC:   TcxDBTextEdit;
    lblPedidoOrigen:  TcxLabel;
    txtNUMERO_PED_ALBC: TcxDBTextEdit;
    txtSERIE_PED_ALBC:  TcxDBTextEdit;
    lblFacturaDestino: TcxLabel;
    txtNUMERO_FAC_ALBC: TcxDBTextEdit;
    txtSERIE_FAC_ALBC:  TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALBC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_ALBC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreAlbc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_ALBC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_ALBC: TcxDBTextEdit;
    // Check informativo: el albaran es mercancia en deposito.
    chkESDEPOSITO_ALBC: TcxDBCheckBox;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_ALBC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_ALBC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_ALBC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_ALBC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_ALBC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_ALBC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_ALBC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_ALBC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_ALBC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_ALBC: TcxDBCurrencyEdit;
    lblTotalesTotalPrendas: TcxLabel;
    curTotalesTOTAL_PRENDAS_ALBC: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_ALBC: TcxDBLookupComboBox;
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
    // Boton para saltar al pedido de compra de origen del albaran
    // (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    ActionList1: TActionList;
    actArticulos: TAction;
    actIrDocumento: TAction;
    actIrFacturaCreada: TAction;
    actIrProveedor: TAction;
    btnIrFacturaCreada: TcxButton;

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
    procedure tvLineasAlbaranFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasAlbaranCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasAlbaranEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasAlbaranEnter(Sender: TObject);
    procedure cxgrdLineasAlbaranExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrFacturaCreadaExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_ALBCPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_ALBCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_PRV_ALBCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_ALBCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure cbbCODIGO_PRV_ALBCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure colLineaAlbcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaAlbcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
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
    FAfterOpenLineasOriginal: TDataSetNotifyEvent;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreAlbc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataAlbaranesCompra
    // .unqryPrvDataAlbc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function BuscarArticuloAlbaranCompra: string;
    function BuscarSkuAlbaranCompra(const ACodigoArt: string): string;
    function ArticuloLineaActivaAlbaranCompra: string;
    procedure AplicarArticuloAlbaranCompra(const ACodigoArt: string);
    procedure colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinAlbcColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure PersistirPreferenciaPivote;
  public
    dmmAlbaranesCompra: TdmAlbaranesCompra;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoAlbaranesCompra: TfrmMtoAlbaranesCompra;

implementation

uses
  System.StrUtils,
  inLibGlobalVar,
  inLibFiltroUsuario,
  inLibFotos,
  inLibLog,
  inLibtb,
  inLibArticulosResolver,
  inLibArticulosValidador,
  inLibComprasImpuestos,
  inLibAtributosPaleta,
  UniDataArticulos,
  inMtoModalImpAlbCompra,
  inMtoModalImpAlbCompraV,
  inMtoModalEtiqAlb, inLibShowMto, inLibGenBusq;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// dsTablaG apunta a la cabecera del albaran de compra. El articulo
// activo vive en la fila del sub-grid tvLineasAlbaran
// (CODIGO_ART_ALBCLIN / CODIGO_UNIDAD_ALBCLIN).
procedure TfrmMtoAlbaranesCompra.ResolverArtSkuActivo(out ACodArt,
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
// albaran, ademas de dsTablaG (cabecera) enganchamos
// dsAlbaranesCompraLineas.
function TfrmMtoAlbaranesCompra.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmAlbaranesCompra) then
    Result := [dsTablaG, dmmAlbaranesCompra.dsAlbaranesCompraLineas]
  else
    Result := [dsTablaG];
end;

function TfrmMtoAlbaranesCompra.BuscarArticuloAlbaranCompra: string;
var
  qry : TUniQuery;
  sPrv: string;
begin
  Result := '';
  if Assigned(dmmAlbaranesCompra) then
  begin
    sPrv := Trim(dmmAlbaranesCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_ALBC').AsString);
    if (sPrv = '') or (sPrv = '0') then
      MessageDlg('Selecciona un proveedor antes de buscar artículos.',
                 mtInformation, [mbOk], 0)
    else
    begin
      qry := TUniQuery.Create(nil);
      try
        qry.Connection := dmmAlbaranesCompra.unqryTablaG.Connection;
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
             'frmMtoDevcArtSearch',
             Self) and (qry.FindField('CODIGO_ART_ART') <> nil) then
          Result := qry.FieldByName('CODIGO_ART_ART').AsString;
      finally
        FreeAndNil(qry);
      end;
    end;
  end;
end;

function TfrmMtoAlbaranesCompra.ArticuloLineaActivaAlbaranCompra: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmAlbaranesCompra) then
  begin
    ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBCLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_ALBCLIN').AsString);
  end;
end;

function TfrmMtoAlbaranesCompra.BuscarSkuAlbaranCompra(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmAlbaranesCompra) then
    MessageDlg('No está abierto el albarán de compra.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranesCompra.unqryTablaG.Connection;
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
           'frmMtoAlbcSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.CargarBasicosColorArticulo(
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

procedure TfrmMtoAlbaranesCompra.AplicarArticuloAlbaranCompra(
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
    Campo := dmmAlbaranesCompra.unqryTablaG.FindField(ACampo);
    if Campo <> nil then
      Result := Trim(Campo.AsString);
  end;

  function FechaCabecera: TDateTime;
  var
    Campo: TField;
  begin
    Result := Date;
    Campo := dmmAlbaranesCompra.unqryTablaG.FindField('FECHA_ALBC');
    if (Campo <> nil) and (not Campo.IsNull) then
      Result := Campo.AsDateTime;
  end;

  function ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string): Integer;
  begin
    Result := 0;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranesCompra.unqryTablaG.Connection;
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
      qry.Connection := dmmAlbaranesCompra.unqryTablaG.Connection;
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
    colSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBCLIN');
    if colSku <> nil then
    begin
      colSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasAlbaran.Controller.FocusedColumn := colSku;
          tvLineasAlbaran.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmAlbaranesCompra) and
     (not FAplicandoArticulo) then
  begin
    ds := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
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
        sPrv := CampoCabeceraString('CODIGO_PRV_ALBC');
        sAlm := CampoCabeceraString('CODIGO_ALM_ALBC');
        dFecha := FechaCabecera;
        Validador := TArticulosValidador.Create(
                       dmmAlbaranesCompra.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmAlbaranesCompra.unqryTablaG.Connection);
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
            PonerString('CODIGO_ART_ALBCLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_ALBCLIN', Datos.CodigoSku);
            PonerString('REF_PRV_ALBCLIN', sModeloPrv);
            PonerString('CODIGO_FAM_ALBCLIN', Datos.CodigoFamilia);
            PonerString('DESCRIPCION_ARTICULO_ALBCLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_ALBCLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_ALBCLIN', Datos.TipoIVA);
            if sAlm <> '' then
              PonerString('CODIGO_ALMACEN_ALBCLIN', sAlm);
            if iAcPivot > 0 then
              PonerInteger('ID_AC_PIVOT_ALBCLIN', iAcPivot)
            else
              LimpiarCampo('ID_AC_PIVOT_ALBCLIN');
            rCantidad := 0;
            if ds.FindField('CANTIDAD_ALBCLIN') <> nil then
              rCantidad := ds.FieldByName('CANTIDAD_ALBCLIN').AsFloat;
            if Datos.RequiereSku and (Datos.CodigoSku = '') then
            begin
              PonerFloat('CANTIDAD_ALBCLIN', 0);
              PonerFloat('TOTAL_UNIDADES_ALBCLIN', 0);
              rCantidad := 0;
            end
            else if rCantidad = 0 then
            begin
              rCantidad := 1;
              PonerFloat('CANTIDAD_ALBCLIN', rCantidad);
              PonerFloat('TOTAL_UNIDADES_ALBCLIN', rCantidad);
            end;
            PonerFloat('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN',
                       Datos.UltimoCoste.PrecioUltCompra);
            PonerFloat('TOTAL_ALBCLIN',
                       rCantidad * Datos.UltimoCoste.PrecioUltCompra);
            PrepararLineaFiscalCompra(
              dmmAlbaranesCompra.unqryTablaG.Connection,
              dmmAlbaranesCompra.unqryTablaG, ds, 'ALBC', 'ALBCLIN',
              'TOTAL_ALBCLIN');
            if Assigned(FPivote) and
               (CampoCabeceraString('ESPIVOTE_HORIZONTAL_ALBC') <> 'N') then
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

// Combo de serie de la cabecera: al desplegar se recargan las series
// 'AB' vigentes de la empresa del albaran. Si la empresa no tiene
// ninguna, se avisa y se ofrece ir a Empresas -> Series a crearlas.
procedure TfrmMtoAlbaranesCompra.cbbSERIE_ALBCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmAlbaranesCompra <> nil) and dmmAlbaranesCompra.unqryTablaG.Active then
    sEmpresa := Trim(dmmAlbaranesCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_ALBC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(inLibGlobalVar.oEmpresa);
  CargarSeriesEmpresa(sEmpresa, 'AB', cbbSERIE_ALBC.Properties.Items);
  if cbbSERIE_ALBC.Properties.Items.Count = 0 then
  begin
    if MessageDlg('No hay series de albaranes de compra (tipo AB) para la ' +
                  'empresa "' + sEmpresa + '".' + sLineBreak +
                  'Se dan de alta en Empresas -> Series. ' +
                  '¿Abrir el mantenimiento de Empresas ahora?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShowMto(Self.Owner, 'Empresas');
  end;
end;

procedure TfrmMtoAlbaranesCompra.FormCreate(Sender: TObject);
var
  colSku: TcxGridDBColumn;
begin
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := tvLineasAlbaran.CreateColumn;
  FColColorPivot.Name    := 'colLinAlbcColorPivot';
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
    OnButtonClick := colLinAlbcColorPivotButtonClick;
  end;
  inherited;
  colSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBCLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := colLineaAlbcCODIGO_UNIDADPropertiesButtonClick;
    end;
  end;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre albaranes, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor del albaran enfocado al abrir el form.
  ActualizarLabelProveedor;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesAlbaranCompra).
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  FAfterOpenLineasOriginal :=
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterOpen;
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.AfterOpen :=
                                             unqryLineasAfterOpenHook;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
end;

function TfrmMtoAlbaranesCompra.SqlRestriccionUsuario: string;
begin
  // Documentos de compra: empresa y almacén (no llevan caja)
  Result := SqlFiltroEmpAlmCaja('CODIGO_EMP_ALBC', 'CODIGO_ALM_ALBC', '');
end;

procedure TfrmMtoAlbaranesCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms y la dejo en
  // tdmDataModule, ademas de enganchar dsTablaG.DataSet a su unqryTablaG.
  // Tomamos esa misma instancia; antes haciamos TdmAlbaranesCompra.Create
  // en FormCreate y enlazabamos el grid de lineas a un segundo DM cuyo
  // unqryAlbaranesCompraLineas nunca recibia el .Open de
  // AbrirTablaPrincipalAsync. Fallback Create(Self) por si la BBDD no
  // tiene la entrada en fza_winforms (migracion no aplicada).
  dmmAlbaranesCompra := (tdmDataModule as TdmAlbaranesCompra);
  if not Assigned(dmmAlbaranesCompra) then
  begin
    dmmAlbaranesCompra := TdmAlbaranesCompra.Create(Self);
    dsTablaG.DataSet := dmmAlbaranesCompra.unqryTablaG;
    // Sin esta linea, TfrmMtoGen.AbrirTablaPrincipalAsync ve
    // tdmDataModule=nil y aborta -> la query principal nunca se abre y
    // el form se queda vacio. Solo pasa cuando fza_winforms NO tiene la
    // entrada de AlbaranesCompra (BBDD sin la migracion aplicada); con
    // la entrada presente, el padre rellena tdmDataModule antes de
    // entrar a CrearTablaPrincipal y este bloque no se ejecuta.
    tdmDataModule := dmmAlbaranesCompra;
  end;
  tvLineasAlbaran.DataController.DataSource :=
    dmmAlbaranesCompra.dsAlbaranesCompraLineas;
  tvMovimientosProveedor.DataController.DataSource :=
    dmmAlbaranesCompra.dsMovimientosProveedor;
  cbbTotalesFORMA_PAGO_ALBC.Properties.ListSource :=
    dmmAlbaranesCompra.dsFormasPago;
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataAlbc, ya cargado para el rotulo.
  cbbCODIGO_PRV_ALBC.Properties.ListSource := dmmAlbaranesCompra.dsPrvDataAlbc;
  // MasterSource se enlaza en DataModuleCreate del DM, pero lo
  // re-aseguramos por idempotencia.
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.MasterSource := dsTablaG;
  dmmAlbaranesCompra.unqryMovimientosProveedor.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_ALBC;NUMERO_ALBC';
end;

procedure TfrmMtoAlbaranesCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoAlbaranesCompra.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineasAlbaran.CreateColumn;
    col.Name    := 'dbcLinAlbcTalla' + Format('%.2d', [i + 1]);
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
procedure TfrmMtoAlbaranesCompra.CrearColumnasAtributos;
var
  i: Integer;
  col: TcxGridDBColumn;
begin
  for i := 0 to CANT_ATRIB_MAX - 1 do
  begin
    col := tvLineasAlbaran.CreateColumn;
    col.Name    := 'dbcLinAlbcAtrib' + Format('%.2d', [i + 1]);
    col.Caption := '';
    col.Width   := 90;
    col.Tag     := -(i + 1);  // tag negativo para no chocar con tallas
    col.Visible := False;
    col.Options.Editing := False;
    FAtribColumns[i] := col;
  end;
end;

procedure TfrmMtoAlbaranesCompra.InicializarGestorYPivote;
var
  cfgT : TGridTallasConfig;
  cfgP : TGridPivoteCompraConfig;
  i    : Integer;
  arr  : TArray<TcxGridDBColumn>;
begin
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if FPivote       <> nil then FreeAndNil(FPivote);
  if dmmAlbaranesCompra = nil then Exit;
  SetLength(arr, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arr[i] := FTallaColumns[i];
  // 1. Gestor inline de tallas (libreria existente). Mismo patron que
  //    Sesiones, con los nombres ALBC/ALBCLIN/ALBCCEL.
  cfgT := Default(TGridTallasConfig);
  cfgT.Conexion           := dmmAlbaranesCompra.unqryTablaG.Connection;
  cfgT.Usuario            := oUser;
  cfgT.Grid               := tvLineasAlbaran;
  cfgT.SourceMaster       := dsTablaG;
  cfgT.SourceLineas       := dmmAlbaranesCompra.dsAlbaranesCompraLineas;
  cfgT.ColumnasTallas     := arr;
  cfgT.FieldSerieMaster   := 'SERIE_ALBC';
  cfgT.FieldNumeroMaster  := 'NUMERO_ALBC';
  cfgT.FieldLinea         := 'LINEA_ALBCLIN';
  cfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_ALBCLIN';
  cfgT.FieldPrecioBase    := 'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN';
  cfgT.FieldTotalUds      := 'TOTAL_UNIDADES_ALBCLIN';
  cfgT.FieldTotalLinea    := 'TOTAL_ALBCLIN';
  cfgT.TablaCeldas        := 'fza_albaranes_compra_celdas';
  cfgT.FieldSerieCel      := 'SERIE_ALBC_ALBCCEL';
  cfgT.FieldNumeroCel     := 'NUMERO_ALBC_ALBCCEL';
  cfgT.FieldLineaCel      := 'LINEA_ALBC_ALBCCEL';
  cfgT.FieldFilaCel       := 'ID_FILA_ALBC_ALBCCEL';
  cfgT.FieldAvPivotCel    := 'ID_AV_PIVOT_ALBCCEL';
  cfgT.FieldCantidadCel   := 'CANTIDAD_ALBCCEL';
  cfgT.FieldAlmacenCel    := 'CODIGO_ALM_ALBCCEL';
  cfgT.IdFilaFijo         := 1;
  cfgT.MaxColumnas        := CANT_TALLAS_MAX;
  FGestorTallas := TGestorGridTallas.Create(cfgT);
  // Hookea el OnEditValueChanged de cada columna talla. En pivote compra
  // actualiza la linea SKU real; fuera de pivote usa el gestor inline.
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
  cfgP.Conexion             := dmmAlbaranesCompra.unqryTablaG.Connection;
  cfgP.Grid                 := tvLineasAlbaran;
  cfgP.SourceMaster         := dsTablaG;
  cfgP.SourceLineas         := dmmAlbaranesCompra.unqryAlbaranesCompraLineas;
  cfgP.Gestor               := FGestorTallas;
  cfgP.ColColorPivot        := FColColorPivot;
  cfgP.ColumnasTallas       := arr;
  cfgP.MaxColumnasTallas    := CANT_TALLAS_MAX;
  cfgP.TablaLineas          := 'fza_albaranes_compra_lineas';
  cfgP.FieldSerieMaster     := 'SERIE_ALBC';
  cfgP.FieldNumeroMaster    := 'NUMERO_ALBC';
  cfgP.FieldSerieLin        := 'SERIE_ALBC_ALBCLIN';
  cfgP.FieldNumeroLin       := 'NUMERO_ALBC_ALBCLIN';
  cfgP.FieldLinea           := 'LINEA_ALBCLIN';
  cfgP.FieldArt             := 'CODIGO_ART_ALBCLIN';
  cfgP.FieldSku             := 'CODIGO_UNIDAD_ALBCLIN';
  cfgP.FieldCantidad        := 'CANTIDAD_ALBCLIN';
  cfgP.FieldPrecioBase      := 'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN';
  cfgP.FieldTotalUds        := 'TOTAL_UNIDADES_ALBCLIN';
  cfgP.FieldTotalLinea      := 'TOTAL_ALBCLIN';
  cfgP.FieldIdAcPivot       := 'ID_AC_PIVOT_ALBCLIN';
  cfgP.FieldAlmacen         := 'CODIGO_ALMACEN_ALBCLIN';
  cfgP.FieldAlmacenMaster   := 'CODIGO_ALM_ALBC';
  cfgP.CamposOcultosEnPivote := TArray<string>.Create(
    'CODIGO_UNIDAD_ALBCLIN',
    'CANTIDAD_ALBCLIN',
    'TOTAL_ALBCLIN');
  FPivote := TGridPivoteCompra.Create(cfgP);
end;

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadTallas;
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

procedure TfrmMtoAlbaranesCompra.RefrescarVisibilidadAtributos;
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
procedure TfrmMtoAlbaranesCompra.CargarCaptionsAtributosLineaActiva;
var
  i: Integer;
  sArt: string;
  qry: TUniQuery;
  iCol: Integer;
begin
  if dmmAlbaranesCompra = nil then Exit;
  qry := dmmAlbaranesCompra.unqryDefArticuloAlbc;
  if qry = nil then Exit;

  // Reset de captions a placeholder.
  for i := 0 to CANT_ATRIB_MAX - 1 do
    if FAtribColumns[i] <> nil then
      FAtribColumns[i].Caption := 'Atributo ' + IntToStr(i + 1);

  if (dmmAlbaranesCompra.unqryAlbaranesCompraLineas = nil) or
     (not dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active) or
     (dmmAlbaranesCompra.unqryAlbaranesCompraLineas.IsEmpty) then Exit;
  sArt := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
            FieldByName('CODIGO_ART_ALBCLIN').AsString;
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

procedure TfrmMtoAlbaranesCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmAlbaranesCompra = nil) or (FPivote = nil) then Exit;
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

procedure TfrmMtoAlbaranesCompra.PersistirPreferenciaPivote;
begin
  // Persiste el modo en la cabecera para que la proxima apertura del
  // albaran arranque ya en el modo elegido.
  if (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty or
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_ALBC') = nil) then
    Exit;
  if not (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
    dsTablaG.DataSet.Edit;
  dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString :=
    IfThen(FPivote.Activo, 'S', 'N');
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintAlbCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if dmmAlbaranesCompra = nil then Exit;
  if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay albaran de compra activo que imprimir.');
    Exit;
  end;
  if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryTablaG.Post;
  if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Post;
  sSerie  := dmmAlbaranesCompra.unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  form := TfrmPrintAlbCompra.Create(Application);
  try
    form.dmAlbc        := dmmAlbaranesCompra;
    form.edtSerie.Text := sSerie;
    form.edtNumero.Text:= sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintAlbCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if dmmAlbaranesCompra = nil then Exit;
  if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay albaran de compra activo que imprimir.');
    Exit;
  end;
  if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryTablaG.Post;
  if dmmAlbaranesCompra.unqryAlbaranesCompraLineas.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Post;
  sSerie  := dmmAlbaranesCompra.unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  form := TfrmPrintAlbCompraV.Create(Application);
  try
    form.dmAlbc        := dmmAlbaranesCompra;
    form.edtSerie.Text := sSerie;
    form.edtNumero.Text:= sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;


procedure TfrmMtoAlbaranesCompra.btnPegatinasClick(Sender: TObject);
var
  form    : TfrmPrintEtiqAlb;
  dmArt   : TdmArticulos;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if dmmAlbaranesCompra = nil then Exit;
  if dmmAlbaranesCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay albaran de compra activo.');
    Exit;
  end;
  if dmmAlbaranesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmAlbaranesCompra.unqryTablaG.Post;
  sSerie  := dmmAlbaranesCompra.unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := dmmAlbaranesCompra.unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  // El modal reutiliza el dataset de etiquetas del DM de articulos
  // (cdsEtiquetasArt, fxdsEtiquetasArt) para que el mismo .fr3 sirva
  // en ambos sitios. Creamos un DM temporal porque el form de
  // albaranes no necesita uno permanente.
  // TdmArticulos.Create dispara DataModuleCreate que ya asigna la
  // conexion. No necesitamos AbrirDetalles ni OpenTables — las queries
  // de print (unqryTarifasPrint, unqryArtPrint) se abren bajo demanda
  // desde el modal / CrearDataSetEtiquetasArt.
  dmArt := TdmArticulos.Create(nil);
  try
    form := TfrmPrintEtiqAlb.Create(Application);
    try
      form.DMArt  := dmArt;
      form.DMAlbc := dmmAlbaranesCompra;
      form.Serie  := sSerie;
      form.Numero := sNumero;
      form.ShowModal;
    finally
      FreeAndNil(form);
    end;
  finally
    FreeAndNil(dmArt);
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoAlbaranesCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranesCompra.btnGrabarClick(Sender: TObject);
begin
  if inLibLog.Log <> nil then
    inLibLog.Log.LogInfo('AlbaranesCompra.btnGrabarClick: INICIO');
  if Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadesPendientes;
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
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
procedure TfrmMtoAlbaranesCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
var
  bDeberiaEstarActivo: Boolean;
begin
  // Refrescar el rotulo del proveedor al navegar entre albaranes (Field=nil)
  // o al cambiar CODIGO_PRV_ALBC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_ALBC') then
    ActualizarLabelProveedor;
  if Field <> nil then Exit;
  if FPivote = nil then Exit;
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) and
     (dsTablaG.DataSet.FindField('ESPIVOTE_HORIZONTAL_ALBC') <> nil) then
  begin
    // Por defecto la vista es horizontal: solo un 'N' explicito
    // (excepcion que el usuario guardo a mano) la mantiene vertical.
    // NULL / vacio / 'S' abren en horizontal.
    bDeberiaEstarActivo :=
      dsTablaG.DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString <> 'N';
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

procedure TfrmMtoAlbaranesCompra.ActualizarLabelProveedor;
var
  sCodigo : string;
  sNombre : string;
  sRazon  : string;
begin
  // Resuelve NOMBRE_PRV + RAZON_SOCIAL_PRV (via el lookup unqryPrvDataAlbc)
  // y los pinta en el rotulo. Se antepone el nombre comercial: es el que
  // el usuario reconoce a simple vista; la razon social solo se anade
  // entre parentesis como referencia si difiere.
  sCodigo := '';
  if (dmmAlbaranesCompra <> nil) and Assigned(dmmAlbaranesCompra.unqryTablaG) and
     dmmAlbaranesCompra.unqryTablaG.Active and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
    sCodigo :=
      Trim(dmmAlbaranesCompra.unqryTablaG.FieldByName('CODIGO_PRV_ALBC').AsString);
  if sCodigo = '' then
    lblProveedorNombreAlbc.Caption := ''
  else if (dmmAlbaranesCompra.unqryPrvDataAlbc <> nil) and
          dmmAlbaranesCompra.unqryPrvDataAlbc.Active and
          dmmAlbaranesCompra.unqryPrvDataAlbc.Locate('CODIGO_PRV_PRV', sCodigo, []) then
  begin
    sRazon  := dmmAlbaranesCompra.unqryPrvDataAlbc.FieldByName('RAZON_SOCIAL_PRV').AsString;
    sNombre := dmmAlbaranesCompra.unqryPrvDataAlbc.FieldByName('NOMBRE_PRV').AsString;
    // Si no hay nombre comercial cargado, caemos a la razon social como
    // rotulo principal. Si hay nombre y difiere de la razon social, la
    // razon social se anade entre parentesis como referencia.
    if Trim(sNombre) = '' then
      lblProveedorNombreAlbc.Caption := sCodigo + ' - ' + sRazon
    else if not SameText(Trim(sNombre), Trim(sRazon)) then
      lblProveedorNombreAlbc.Caption :=
        sCodigo + ' - ' + sNombre + '  (' + sRazon + ')'
    else
      lblProveedorNombreAlbc.Caption := sCodigo + ' - ' + sNombre;
  end
  else
    lblProveedorNombreAlbc.Caption := sCodigo + ' - (proveedor no encontrado)';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesAlbaranCompra) con la republicacion del controlador.
procedure TfrmMtoAlbaranesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(dmmAlbaranesCompra) then
  begin
    dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
    dmmAlbaranesCompra.SincronizarMovimientos;
  end;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

procedure TfrmMtoAlbaranesCompra.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if Assigned(FAfterOpenLineasOriginal) then
    FAfterOpenLineasOriginal(DataSet);
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranFocusedRecordChanged(
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
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoAlbaranesCompra.tvLineasAlbaranEditing(
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
procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;

procedure TfrmMtoAlbaranesCompra.cxgrdLineasAlbaranExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoAlbaranesCompra.TallaEditValueChangedHook(Sender: TObject);
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

procedure TfrmMtoAlbaranesCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

procedure TfrmMtoAlbaranesCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  with tvLineasAlbaran.DataController.DataSet do
    ShowMto(Self.Owner,
            'Articulos',
            FieldByName('CODIGO_ART_ALBCLIN').AsString);
end;

procedure TfrmMtoAlbaranesCompra.actIrProveedorExecute(Sender: TObject);
var
  sPrv: string;
begin
  sPrv := '';
  if Assigned(dmmAlbaranesCompra) and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
    sPrv := Trim(dmmAlbaranesCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_ALBC').AsString);
  if sPrv = '' then
    ShowMto(Self.Owner, 'Proveedores')
  else
    ShowMto(Self.Owner, 'Proveedores', sPrv);
end;

procedure TfrmMtoAlbaranesCompra.btnCODIGO_EMP_ALBCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) then
  begin
    ds := dmmAlbaranesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg('Crea o selecciona un albarán de compra antes de ' +
                 'elegir la empresa.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
              'Búsqueda de empresas',
              'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP',
              'CODIGO_EMP_EMP',
              sCodigo,
              'frmMtoEmpFacSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_EMP_ALBC').AsString := sCodigo;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.cbbCODIGO_PRV_ALBCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo : string;
  ds      : TDataSet;
begin
  inherited;
  if Assigned(dmmAlbaranesCompra) then
  begin
    ds := dmmAlbaranesCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg('Crea o selecciona un albarán de compra antes de ' +
                 'elegir el proveedor.', mtInformation, [mbOk], 0)
    else if TBusquedaUtils.EjecutarBusqueda(
              'Búsqueda de proveedores',
              'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
              'CODIGO_PRV_PRV',
              sCodigo,
              'frmMtoAlbcProvSearch',
              Self) then
    begin
      if not (ds.State in [dsInsert, dsEdit]) then
        ds.Edit;
      ds.FieldByName('CODIGO_PRV_ALBC').AsString := sCodigo;
      AplicarIvaExentoIntracomunitarioProveedor(inLibGlobalVar.oConn, ds,
        'CODIGO_PRV_ALBC', 'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC');
      dmmAlbaranesCompra.CalcularTotalesAlbaranCompra;
      ActualizarLabelProveedor;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnCODIGO_EMP_ALBCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_ALBCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranesCompra.cbbCODIGO_PRV_ALBCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_ALBCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaranCompra;
  if sCodigo <> '' then
    AplicarArticuloAlbaranCompra(sCodigo);
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_ARTPropertiesValidate(
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
      AplicarArticuloAlbaranCompra(sCodigo);
      if Assigned(dmmAlbaranesCompra) and
         dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Active and
         (dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
            FindField('CODIGO_ART_ALBCLIN') <> nil) then
        DisplayValue := dmmAlbaranesCompra.unqryAlbaranesCompraLineas.
                          FieldByName('CODIGO_ART_ALBCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranesCompra.colLineaAlbcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaAlbaranCompra;
  sSku := BuscarSkuAlbaranCompra(sArt);
  if sSku <> '' then
    AplicarArticuloAlbaranCompra(sSku);
end;

procedure TfrmMtoAlbaranesCompra.colLinAlbcColorPivotButtonClick(
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
    sArt := ArticuloLineaActivaAlbaranCompra;
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

// "Ir a documento" (Ctrl+May+A): salta al pedido de compra del que nace
// el albaran (SERIE_PED_ALBC / NUMERO_PED_ALBC). Si el albaran se creo a
// mano y no procede de ningun pedido, avisamos en lugar de abrir un Mto
// vacio.
procedure TfrmMtoAlbaranesCompra.actIrDocumentoExecute(Sender: TObject);
var
  sSeriePed, sNumeroPed: string;
begin
  inherited;
  if (dmmAlbaranesCompra <> nil) and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
  begin
    sSeriePed  := Trim(dmmAlbaranesCompra.unqryTablaG.
                         FieldByName('SERIE_PED_ALBC').AsString);
    sNumeroPed := Trim(dmmAlbaranesCompra.unqryTablaG.
                         FieldByName('NUMERO_PED_ALBC').AsString);
    if (sSeriePed <> '') and (sNumeroPed <> '') then
      ShowMto(Self.Owner, 'PedidosCompra', sSeriePed + ',' + sNumeroPed)
    else
      ShowMessage('Este albaran no procede de ningun pedido de compra.');
  end;
end;

procedure TfrmMtoAlbaranesCompra.actIrFacturaCreadaExecute(Sender: TObject);
var
  sSerieFac, sNumeroFac: string;
begin
  inherited;
  if (dmmAlbaranesCompra <> nil) and
     (not dmmAlbaranesCompra.unqryTablaG.IsEmpty) then
  begin
    sSerieFac  := Trim(dmmAlbaranesCompra.unqryTablaG.
                         FieldByName('SERIE_FAC_ALBC').AsString);
    sNumeroFac := Trim(dmmAlbaranesCompra.unqryTablaG.
                         FieldByName('NUMERO_FAC_ALBC').AsString);
    if (sSerieFac <> '') and (sNumeroFac <> '') then
      ShowMto(Self.Owner, 'FacturasCompra', sSerieFac + ',' + sNumeroFac)
    else
      ShowMessage('Este albaran no tiene factura de compra creada.');
  end;
end;

procedure TfrmMtoAlbaranesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Append;
end;

procedure TfrmMtoAlbaranesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranesCompra.unqryAlbaranesCompraLineas.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranesCompra);
end.
