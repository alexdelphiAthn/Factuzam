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
    // Boton + accion para saltar al pedido de venta de origen del
    // albaran (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    btnIrFacturaCreada: TcxButton;
    ActionList1: TActionList;
    actIrDocumento: TAction;
    actIrFacturaCreada: TAction;
    btnImprimir: TcxButton;

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
    procedure actIrFacturaCreadaExecute(Sender: TObject);
    procedure btnCODIGO_EMP_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_CLI_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_EMP_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_CLI_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLI_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure cxgrdcArtAlbPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure cxgrdcArtAlbPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
  private
    FBuscandoDatosCabecera: Boolean;
    FAplicandoArticulo: Boolean;
    function BuscarArticuloAlbaran: string;
    function BuscarSkuAlbaran(const ACodigoArt: string): string;
    function ArticuloLineaActivaAlbaran: string;
    procedure AplicarArticuloAlbaran(const ACodigoArt: string);
    procedure cxgrdcArtAlbSkuPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
  public
    dmmAlbaranes: TdmAlbaranes;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoAlbaranes: TfrmMtoAlbaranes;

implementation

uses
  inMtoModalFacturarAlbaranesFechas, inLibFotos, inLibGridCantidad,
  inLibGenBusq, inLibShowMto, inLibGlobalVar, Uni,
  inLibArticulosResolver, inLibArticulosValidador, inLibVentasImpuestos;

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

function TfrmMtoAlbaranes.BuscarArticuloAlbaran: string;
var
  qry     : TUniQuery;
  Campo   : TField;
  sTarifa : string;
  dFecha  : TDateTime;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    sTarifa := dmmAlbaranes.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    dFecha := Date;
    if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFecha := dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranes.unqryTablaG.Connection;
      qry.SQL.Text :=
        'SELECT * ' +
        '  FROM vi_art_busquedas ' +
        ' WHERE (CODIGO_TAR_ARTTAR = :tarifa ' +
        '    OR CODIGO_TAR_ARTTAR IS NULL) ' +
        '   AND FECHA_DESDE_ARTTAR < :fecha ' +
        '   AND (FECHA_HASTA_ARTTAR IS NULL ' +
        '        OR FECHA_HASTA_ARTTAR > :fecha)';
      qry.ParamByName('tarifa').AsString := sTarifa;
      qry.ParamByName('fecha').AsDateTime := dFecha;
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Artículos en Líneas de Albarán',
           qry,
           'frmMtoArtFacSearch',
           Self) then
      begin
        Campo := qry.FindField('CODIGO_ART_ART');
        if Campo = nil then
          Campo := qry.FindField('CODIGO_ART');
        if Campo <> nil then
          Result := Campo.AsString;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TfrmMtoAlbaranes.ArticuloLineaActivaAlbaran: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString);
  end;
end;

function TfrmMtoAlbaranes.BuscarSkuAlbaran(
  const ACodigoArt: string): string;
var
  qry : TUniQuery;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmAlbaranes) then
    MessageDlg('No está abierto el albarán de venta.',
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg('Selecciona un artículo antes de buscar sus SKUs.',
               mtInformation, [mbOk], 0)
  else
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := dmmAlbaranes.unqryTablaG.Connection;
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
           'frmMtoAlbSkuSearch',
           Self) and (qry.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        Result := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TfrmMtoAlbaranes.AplicarArticuloAlbaran(const ACodigoArt: string);
var
  ds         : TDataSet;
  Validador  : TArticulosValidador;
  Resolver   : TArticulosResolver;
  Resolucion : TArtResolucionEntrada;
  Datos      : TArticuloDatos;
  Precio     : TArticuloPrecio;
  sInput     : string;
  sTarifa    : string;
  dFecha     : TDateTime;
  rPrecioSiva: Double;
  rPorIva    : Double;

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

  function PorcentajeIva(const ATipoIva: string): Double;
  var
    sTipo: string;
  begin
    sTipo := UpperCase(Trim(ATipoIva));
    if sTipo = 'R' then
      Result := dmmAlbaranes.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAR_ALB').AsFloat
    else if sTipo = 'S' then
      Result := dmmAlbaranes.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAS_ALB').AsFloat
    else if sTipo = 'E' then
      Result := dmmAlbaranes.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAE_ALB').AsFloat
    else
      Result := dmmAlbaranes.unqryTablaG.
                  FieldByName('PORCENTAJE_IVAN_ALB').AsFloat;
  end;

  procedure EnfocarSku(AAbrirBusqueda: Boolean);
  var
    ColSku: TcxGridDBColumn;
  begin
    ColSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBLIN');
    if ColSku <> nil then
    begin
      ColSku.Visible := True;
      TThread.ForceQueue(nil,
        procedure
        begin
          tvLineasAlbaran.Controller.FocusedColumn := ColSku;
          tvLineasAlbaran.Controller.EditingController.ShowEdit;
          if AAbrirBusqueda then
            cxgrdcArtAlbSkuPropertiesButtonClick(nil, 0);
        end);
    end;
  end;

begin
  sInput := Trim(ACodigoArt);
  if (sInput <> '') and Assigned(dmmAlbaranes) and
     (not FAplicandoArticulo) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
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
        sTarifa := dmmAlbaranes.unqryTablaG.
                     FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
        dFecha := Date;
        if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
          dFecha := dmmAlbaranes.unqryTablaG.
                      FieldByName('FECHA_ALB').AsDateTime;
        Validador := TArticulosValidador.Create(
                       dmmAlbaranes.unqryTablaG.Connection);
        Resolver := TArticulosResolver.Create(
                      dmmAlbaranes.unqryTablaG.Connection);
        Resolucion := Validador.Resolver(sInput);
        if Resolucion.Encontrado then
        begin
          Datos := Resolver.ResolverDatos(Resolucion.CodigoArticulo,
                                          Resolucion.CodigoSku,
                                          sTarifa,
                                          dFecha);
          if Datos.Encontrado then
          begin
            if Datos.RequiereSku then
              Precio := Resolver.ResolverPrecio(Datos.CodigoArticulo, '',
                                                sTarifa, dFecha)
            else
              Precio := Datos.PrecioPedido;
            rPorIva := PorcentajeIva(Datos.TipoIVA);
            rPrecioSiva := Precio.PrecioFinal;
            if Precio.EsImpIncl and ((1 + rPorIva / 100) <> 0) then
              rPrecioSiva := Precio.PrecioFinal / (1 + rPorIva / 100);
            PonerString('CODIGO_ART_ALBLIN', Datos.CodigoArticulo);
            PonerString('CODIGO_UNIDAD_ALBLIN', Datos.CodigoSku);
            PonerString('DESCRIPCION_VARIACION_ALBLIN',
                        Datos.DescripcionSku);
            PonerString('CODIGO_FAM_ALBLIN', Datos.CodigoFamilia);
            PonerString('NOMBRE_FAM_ALBLIN', Datos.DescripcionFamilia);
            PonerString('DESCRIPCION_ARTICULO_ALBLIN',
                        Datos.DescripcionArticulo);
            PonerString('TIPO_CANTIDAD_ARTICULO_ALBLIN',
                        Datos.TipoCantidad);
            PonerString('TIPO_IVA_ARTICULO_ALBLIN', Datos.TipoIVA);
            PonerString('CODIGO_TAR_ALBLIN', sTarifa);
            if Precio.EsImpIncl then
              PonerString('ESIMP_INCL_TARIFA_ALBLIN', 'S')
            else
              PonerString('ESIMP_INCL_TARIFA_ALBLIN', 'N');
            if Datos.RequiereSku then
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', 0)
            else
              PonerFloat('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', rPrecioSiva);
            PrepararLineaFiscalVenta(dmmAlbaranes.unqryTablaG.Connection,
              dmmAlbaranes.unqryTablaG, ds, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');
            if Datos.RequiereSku then
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

procedure TfrmMtoAlbaranes.CrearTablaPrincipal;
begin
  inherited;
  // Reutilizar la instancia de data module creada por
  // TfrmMtoGen.CrearTablaPrincipal (tdmDataModule). Antes este form creaba
  // OTRO TdmAlbaranes en FormCreate y enganchaba los grids a ese segundo DM,
  // cuyas queries de detalle nunca se abren (la carga async abre las del DM
  // del padre): las pestanas de lineas, facturas y movimientos salian vacias.
  dmmAlbaranes := (tdmDataModule as TdmAlbaranes);
  if not Assigned(dmmAlbaranes) then
  begin
    dmmAlbaranes := TdmAlbaranes.Create(Self);
    dsTablaG.DataSet := dmmAlbaranes.unqryTablaG;
    tdmDataModule := dmmAlbaranes;
  end;
  tvLineasAlbaran.DataController.DataSource := dmmAlbaranes.dsAlbaranesLineas;
  tvFacturas.DataController.DataSource      := dmmAlbaranes.dsFacturas;
  tvMovimientos.DataController.DataSource   := dmmAlbaranes.dsMovimientosAlb;
  cbbTotalesFORMA_PAGO_ALB.Properties.ListSource := dmmAlbaranes.dsFormasPago;
  // Master-detail: enganchar las queries de detalle a la cabecera (dsTablaG)
  // para que lineas, facturas y movimientos sigan al albaran seleccionado.
  dmmAlbaranes.unqryAlbaranesLineas.MasterSource := dsTablaG;
  dmmAlbaranes.unqryFacturas.MasterSource        := dsTablaG;
  dmmAlbaranes.unqryMovimientosAlb.MasterSource  := dsTablaG;
  // Clave de localizacion para ShowMto (p.ej. "Ir a documento" desde el
  // pedido de venta o navegacion hacia su pedido de origen).
  pkFieldName := 'SERIE_ALB;NUMERO_ALB';
end;

procedure TfrmMtoAlbaranes.FormCreate(Sender: TObject);
var
  colFact, colSku: TcxGridDBColumn;
  stFact: TcxStyle;
begin
  inherited;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvLineasAlbaran.GetColumnByFieldName('CANTIDAD_ALBLIN'),
    tvLineasAlbaran.GetColumnByFieldName('TIPO_CANTIDAD_ARTICULO_ALBLIN'));
  colSku := tvLineasAlbaran.GetColumnByFieldName('CODIGO_UNIDAD_ALBLIN');
  if colSku <> nil then
  begin
    colSku.PropertiesClass := TcxButtonEditProperties;
    colSku.Options.ShowEditButtons := isebAlways;
    with TcxButtonEditProperties(colSku.Properties) do
    begin
      Buttons.Clear;
      with Buttons.Add do
        Kind := bkEllipsis;
      OnButtonClick := cxgrdcArtAlbSkuPropertiesButtonClick;
    end;
  end;
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

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Empresas en Albaranes',
           dmmAlbaranes.unqryEmpDataAlb,
           'frmMtoEmpFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarEmpresaaAlbaran(dmmAlbaranes.unqryEmpDataAlb);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if TBusquedaUtils.EjecutarBusqueda(
           'Búsqueda de Clientes en Albaranes',
           dmmAlbaranes.unqryCliDataAlb,
           'frmMtoCliFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarClienteaAlbaran(dmmAlbaranes.unqryCliDataAlb);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmAlbaranes.BuscarEmpresa(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmAlbaranes.BuscarCliente(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_CLI_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaran;
  if sCodigo <> '' then
    AplicarArticuloAlbaran(sCodigo);
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloAlbaran(sCodigo);
      if Assigned(dmmAlbaranes) and
         dmmAlbaranes.unqryAlbaranesLineas.Active and
         (dmmAlbaranes.unqryAlbaranesLineas.
            FindField('CODIGO_ART_ALBLIN') <> nil) then
        DisplayValue := dmmAlbaranes.unqryAlbaranesLineas.
                          FieldByName('CODIGO_ART_ALBLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaAlbaran;
  sSku := BuscarSkuAlbaran(sArt);
  if sSku <> '' then
    AplicarArticuloAlbaran(sSku);
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

procedure TfrmMtoAlbaranes.actIrFacturaCreadaExecute(Sender: TObject);
var
  sSerieFac, sNumeroFac: string;
  sCallFactura: string;
begin
  inherited;
  if (dmmAlbaranes <> nil) and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
  begin
    sSerieFac  := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('SERIE_FAC_ALB').AsString);
    sNumeroFac := Trim(dmmAlbaranes.unqryTablaG.
                         FieldByName('NUMERO_FAC_ALB').AsString);
    if (sSerieFac <> '') and (sNumeroFac <> '') then
    begin
      sCallFactura := ResolverCallFactura(sNumeroFac, sSerieFac);
      ShowMto(Self.Owner, sCallFactura, sSerieFac + ',' + sNumeroFac);
    end
    else
      ShowMessage('Este albaran no tiene borrador creado.');
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoAlbaranes);

end.
