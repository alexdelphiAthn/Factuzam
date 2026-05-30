{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEmpresas                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de empresas.                                                }
{    CRUD sobre fza_empresas con datos fiscales y configuracion.               }
{******************************************************************************}
unit inMtoEmpresas;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, dxSkinBlue,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
   cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  cxCurrencyEdit, cxDataControllerConditionalFormattingRulesManagerDialog,
  dxBevel, cxDBNavigator, UniDataEmpresas,  cxGridExportLink,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan,
  cxSplitter, cxGroupBox, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark, inLibCertificates,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint, inMtoModalEmpCer,
  dxSkinXmas2008Blue, JvComponentBase, JvEnterTab, dxShellDialogs, cxDBLabel,
  cxListView;

type
  TfrmMtoEmpresas = class(TfrmMtoGen)
    pnlFichaDetail: TPanel;
    pcPestana: TcxPageControl;
    tsMasDatos: TcxTabSheet;
    pnlFichaCab: TPanel;
    tsOtros: TcxTabSheet;
    pnlUserInstantBottom: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinORDEN_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVA_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    lblTextoLegal: TcxLabel;
    cxdbmTEXTO_LEGAL_FACTURA_EMPRESA: TcxDBMemo;
    tsRetenciones: TcxTabSheet;
    lblOrden: TcxLabel;
    btnNuevaEmpresa: TcxButton;
    cxdbspndtORDEN_EMPRESA: TcxDBSpinEdit;
    pnlRetenOpts: TPanel;
    pnlRetencionesCli: TPanel;
    cxgrdRetenciones: TcxGrid;
    tvRetenciones: TcxGridDBTableView;
    cxgrdbclmntv1CODIGO_RETENCION: TcxGridDBColumn;
    cxgrdbclmntv1CODIGO_EMPRESA_RETENCION: TcxGridDBColumn;
    cxgrdbclmntv1FECHA_DESDE_RETENCION: TcxGridDBColumn;
    cxgrdbclmntv1FECHA_HASTA_RETENCION: TcxGridDBColumn;
    cxgrdbclmntv1INSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmntv1INSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmntv1USUARIOALTA: TcxGridDBColumn;
    cxgrdbclmntv1USUARIOMODIF: TcxGridDBColumn;
    cxgrdlvlRetenciones: TcxGridLevel;
    btnAddIRPF: TcxButton;
    cxGrdDBTabPrinPAIS_EMPRESA: TcxGridDBColumn;
    cxGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    tsHistoriaFacturacion: TcxTabSheet;
    pnlFactura: TPanel;
    cxgrdEmpresasFacturas: TcxGrid;
    tvFacturacion: TcxGridDBTableView;
    tvLineasFacturacion: TcxGridDBTableView;
    tvLineasFacturacionLINEA_LINEA: TcxGridDBColumn;
    tvLineasFacturacionCODIGO_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn;
    tvLineasFacturacionCANTIDAD_LINEA: TcxGridDBColumn;
    tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    tvLineasFacturacionSUM_TOTAL_LINEA: TcxGridDBColumn;
    tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlcxgrd1Level1: TcxGridLevel;
    cxgrdlvlcxgrd1Level2: TcxGridLevel;
    pnlFacturaOpts: TPanel;
    btnIraFactura: TcxButton;
    tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    btnIraCliente: TcxButton;
    btnExportarExcel: TcxButton;
    tvFacturacionFECHA_FACTURA: TcxGridDBColumn;
    tvFacturacionNRO_FACTURA: TcxGridDBColumn;
    tvFacturacionSERIE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn;
    tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn;
    tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn;
    tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn;
    tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn;
    tvRetencionesPORCENRETENCION_RETENCION: TcxGridDBColumn;
    tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn;
    tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    spltFicha: TcxSplitter;
    btnIraArticulo: TcxButton;
    tsSeries: TcxTabSheet;
    pnlSeriesOpts: TPanel;
    btnAddSerie: TcxButton;
    pnlSeriesCli: TPanel;
    cxGrdSeries: TcxGrid;
    tvSeries: TcxGridDBTableView;
    lvSeries: TcxGridLevel;
    dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn;
    cxgrpbxIdentificacion: TcxGroupBox;
    lblMovil: TcxLabel;
    txtMOVIL_EMPRESA: TcxDBTextEdit;
    lblEmail: TcxLabel;
    lblDireccion: TcxLabel;
    txtDIRECCION1_EMPRESA: TcxDBTextEdit;
    txtEMAIL_EMPRESA: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA: TcxDBTextEdit;
    txtPOBLACION_EMPRESA: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    lblProvincia: TcxLabel;
    txtPROVINCIA_EMPRESA: TcxDBTextEdit;
    chkRegimenEspecial: TcxDBCheckBox;
    cxgrpbxFiscalidad: TcxGroupBox;
    lblCodigo: TcxLabel;
    txtCODIGO_EMPRESA: TcxDBTextEdit;
    lblNif: TcxLabel;
    txtNIF_EMPRESA: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtRAZONSOCIAL_EMPRESA: TcxDBTextEdit;
    chkActivo: TcxDBCheckBox;
    chkAplicaRetenciones: TcxDBCheckBox;
    lblCanalIVA: TcxLabel;
    cbbZonaIVA: TcxDBLookupComboBox;
    ActionListEmpresas: TActionList;
    actClientes: TAction;
    actArticulos: TAction;
    actFacturas: TAction;
    tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn;
    tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn;
    tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn;
    tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn;
    txtCODIGO_POSTAL_EMP: TcxDBTextEdit;
    lblCodPostal: TcxLabel;
    lblIBAN: TcxLabel;
    txtIBAN_EMPRESA: TcxDBMaskEdit;
    btnValidar: TcxButton;
    lblProvincia1: TcxLabel;
    txtNOMBRE_PAIS_EMPRESA: TcxDBTextEdit;
    txtCODIGO_PAIS_EMPRESA: TcxDBTextEdit;
    cbbPaises: TcxDBLookupComboBox;
    lblTextoLegal1: TcxLabel;
    lblDBNumeroSerieCertificado: TcxDBLabel;
    lblNumSerie: TcxLabel;
    lblTipoCertificado: TcxLabel;
    lblDBTipoCertificado: TcxDBLabel;
    lblTitular: TcxLabel;
    lblDBTitularCertificado: TcxDBLabel;
    btnSeleccionarCer: TcxButton;
    lblFechaCaducidad: TcxLabel;
    txtFECHACADUCIDAD: TcxDBTextEdit;
    dbmSeriesCODIGO_ALMACEN_SERIE: TcxGridDBColumn;
    dbmSeriesCODIGO_CAJA_SERIE: TcxGridDBColumn;
    dbmSeriesSERIE_SERIE: TcxGridDBColumn;
    dbmSeriesTIPODOC_SERIE: TcxGridDBColumn;
    dbmSeriesSUBITPO_SERIE: TcxGridDBColumn;
    dbmSeriesFECHA_DESDE_SERIE: TcxGridDBColumn;
    dbmSeriesFECHA_HASTA_SERIE: TcxGridDBColumn;
    procedure tsFichaEnter(Sender: TObject);
    procedure chkAplicaRetencionesPropertiesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCargarColumnasClick(Sender: TObject);
    procedure btnNuevaEmpresaClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAddIRPFClick(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnAddSerieClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure btnValidarClick(Sender: TObject);
    procedure txtCODIGO_PAIS_EMPRESAPropertiesChange(Sender: TObject);
    procedure btnSeleccionarCerClick(Sender: TObject);
  public
    dmmEmpresas: TdmEmpresas;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  private
    procedure IncorporarCertificados;
    procedure IterateCheckedList(lst: TcxListView);
    // Carga perezosa de sub-pestañas detail (Retenciones, Historia).
    procedure PcPestanaChange(Sender: TObject);
  end;

var
  frmMtoEmpresas: TfrmMtoEmpresas;

implementation

uses
  inLibWin,
  inLibUser,
  inLibShowMto,
  inLibDir,
  inLibDevExp,
  inLibIBAN,
  inLibFotos,
  inMtoPrincipal,
  inMtoFacturasBase,
  inMtoArticulos,
  inMtoClientes;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// La historia de facturacion muestra lineas con articulo
// (tvLineasFacturacion, CODIGO_ART_FACLIN); ese es el articulo activo.
procedure TfrmMtoEmpresas.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvLineasFacturacion.DataController.DataSource) then
  begin
    ds := tvLineasFacturacion.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoEmpresas.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmEmpresas) then
    Result := [dsTablaG, dmmEmpresas.dsFacturasLineasEmpresas]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoEmpresas.actClientesExecute(Sender: TObject);
begin
  inherited;
  //Control + K
  //https://stackoverflow.com/questions/2317208/
  //how-to-fire-keypreview-event-when-form-has-a-tactionmainmenubar
  if ((pcPestana.ActivePage = tsHistoriaFacturacion)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoEmpresas.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F
    if (pcPestana.ActivePage = tsHistoriaFacturacion) then
       btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoEmpresas.actArticulosExecute(Sender: TObject);
begin
  inherited;
  //Control + A -> Articulos
   if (pcPestana.ActivePage = tsHistoriaFacturacion) then
     btnIraArticuloClick(Sender)
   else
     ShowMto(Self.Owner,
             'Articulos');
end;

procedure TfrmMtoEmpresas.btnExportarExcelClick(Sender: TObject);
begin
  ExportarExcel(cxgrdEmpresasFacturas, 'Historico_Facturas_Empresa_' +
                       dsTablaG.Dataset.FieldByName('CODIGO_EMP_EMP').AsString);
end;

procedure TfrmMtoEmpresas.btnIraFacturaClick(Sender: TObject);
var
  sNroFactura, sSerieFactura:String;
begin
  inherited;
  with tvFacturacion.DataController.DataSet do
  begin
    if ((not(FieldByName('NUMERO_FAC').IsNull)) and
        (not(FieldByName('SERIE_FAC').IsNull))
       ) then
       begin
          sNroFactura := FieldByName('NUMERO_FAC').AsString;
          sSerieFactura := FieldByName('SERIE_FAC').AsString;
          ShowMto(Self.Owner,
                  ResolverCallFactura(sNroFactura, sSerieFactura),
                  sNroFactura + ',' + sSerieFactura);
       end
     else
       ShowMto(Self.Owner,
               'Facturas');
  end;
end;

procedure TfrmMtoEmpresas.btnAddIRPFClick(Sender: TObject);
begin
  inherited;
  with dmmEmpresas do
  begin
    if ((unqryTablaG.State = dsInsert) or
        (unqryTablaG.State = dsEdit)) then
      unqryTablaG.Post;
    if ((unqryRetenciones.State = dsInsert) or
        (unqryRetenciones.State = dsEdit)) then
      unqryRetenciones.Post;
    unqryRetenciones.Insert;
  end;
end;

procedure TfrmMtoEmpresas.btnAddSerieClick(Sender: TObject);
begin
  inherited;
  with dmmEmpresas do
  begin
    if ((unqryTablaG.State = dsInsert) or
        (unqryTablaG.State = dsEdit)) then
      unqryTablaG.Post;
    if ((unqrySeries.State = dsInsert) or
        (unqrySeries.State = dsEdit)) then
      unqrySeries.Post;
    unqrySeries.Insert;
  end;
end;

procedure TfrmMtoEmpresas.btnNuevaEmpresaClick(Sender: TObject);
begin
  inherited;
  if ( (dmmEmpresas.unqryTablaG.State = dsInsert) or
       (dmmEmpresas.unqryTablaG.State = dsEdit)) then
  begin
    dmmEmpresas.unqryTablaG.Post;
  end;
  dmmEmpresas.unqryTablaG.Insert;
  pcPantalla.Properties.ActivePage := tsFicha;
  tsFicha.SetFocus;
  pcPestana.ActivePageIndex := tsMasDatos.PageIndex;
  tsMasDatos.SetFocus;
  txtRAZONSOCIAL_EMPRESA.SetFocus;
end;

procedure TfrmMtoEmpresas.btnSeleccionarCerClick(Sender: TObject);
begin
  inherited;
  //
    if ( (dmmEmpresas.unqryTablaG.State = dsInsert) or
       (dmmEmpresas.unqryTablaG.State = dsEdit)) then
    dmmEmpresas.unqryTablaG.Post;
    IncorporarCertificados;
end;

procedure TfrmMtoEmpresas.btnValidarClick(Sender: TObject);
var
  sIBAN, sPref, sPref4:String;
  iLen:Integer;
  sErr:String;
  EsIBANErr:boolean;
  stErr:TStringList;
begin
  inherited;
  EsIBANErr := False;
  stErr := TStringList.Create;
  sIBAN := StringReplace(dsTablaG.DataSet.FieldByName('IBAN_EMP').Text,
                         ' ', '', [rfReplaceAll]);
  iLen := Length(sIBAN);
  sPref := (Copy(sIBAN, 1, 2));
  if ((sPref = 'ES') or (iLen = 20)) then
  begin
    TIBAN.ValidarCCC(sIBAN, stErr);
    sErr := stErr.Text;
    if (sErr <> '') then
    begin
      ShowMessage(sErr);
      EsIBANErr := True;
    end;
  end;
  if ((iLen = 20) and
      (StrToIntDef(sPref, 0) <> 0) and
      not(EsIBANErr)) then
  begin
    sPref4 := TIBAN.GenerarIBAN('ES', sIBAN);
    if (dsTablaG.State = dsBrowse) then
      dsTablaG.DataSet.Edit;
    dsTablaG.DataSet.FieldByName('IBAN_EMP').Text := sPref4 + sIBAN;
  end;
  if (not(EsIBANErr) and (StrToIntDef(sPref, 0) = 0)) then
  begin
    TIBAN.ValidarIBAN(sIBAN, stErr);
    sErr := stErr.Text;
    if (sErr <> '') then
    begin
      ShowMessage(sErr);
      EsIBANErr := True;
    end;
  end;
  if not(EsIBANErr) then
    ShowMessage('IBAN Validado OK');
  FreeAndNil(stErr);
end;

procedure TfrmMtoEmpresas.btnCargarColumnasClick(Sender: TObject);
begin
  inherited;
  GetSettingsColumn(tvRetenciones, Self.Name, Self.Owner);
end;

procedure TfrmMtoEmpresas.btnGrabarClick(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoEmpresas.chkAplicaRetencionesPropertiesChange(Sender: TObject);
begin
  inherited;
  if chkAplicaRetenciones.Checked = True then
    tsRetenciones.TabVisible := True
  else
    tsRetenciones.TabVisible := False;
end;

procedure TfrmMtoEmpresas.CrearTablaPrincipal;
begin
  inherited;
  dmmEmpresas := tdmDataModule as TdmEmpresas;
  tvRetenciones.DataController.DataSource := dmmEmpresas.dsRetenciones;
  pcPestana.ActivePage := tsMasDatos;
  tvSeries.DataController.DataSource := dmmEmpresas.dsSeries;
  cbbZonaIVA.Properties.ListSource := dmmEmpresas.dsIvas;
  tvFacturacion.DataController.DataSource := dmmEmpresas.dsFacturasEmpresas;
  tvLineasFacturacion.DataController.DataSource :=
                                           dmmEmpresas.dsFacturasLineasEmpresas;
  cbbPaises.Properties.ListSource := dmmEmpresas.dsPaises;
  Self.pkFieldName := 'CODIGO_EMP_EMP';
  // Carga perezosa de sub-pestañas detail (default = tsMasDatos, que
  // no usa query detail). Series/Retenciones/Historia se abren solo
  // cuando el usuario activa su pestaña.
  pcPestana.OnChange := PcPestanaChange;
end;

procedure TfrmMtoEmpresas.PcPestanaChange(Sender: TObject);
begin
  if not Assigned(dmmEmpresas) then Exit;
  if pcPestana.ActivePage = tsRetenciones then
    dmmEmpresas.AsegurarRetencionesAbierta
  else if pcPestana.ActivePage = tsSeries then
    dmmEmpresas.AsegurarSeriesAbierta
  else if pcPestana.ActivePage = tsHistoriaFacturacion then
    dmmEmpresas.AsegurarHistoriaFacturacionAbierta;
end;

procedure TfrmMtoEmpresas.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_EMPRESA.Enabled := True
  else
    txtCODIGO_EMPRESA.Enabled := False;
end;

procedure TfrmMtoEmpresas.btnIraArticuloClick(Sender: TObject);
var
  sCodArt: string;
  vw: TcxCustomGridView;
  dbView: TcxGridDBTableView;
  colArticulo: TcxGridDBColumn;
begin
  inherited;
  sCodArt := '';
  vw := cxgrdEmpresasFacturas.FocusedView;
  if (vw <> nil) and (vw is TcxGridDBTableView) then
  begin
    dbView := TcxGridDBTableView(vw);
    colArticulo := dbView.GetColumnByFieldName('CODIGO_ART_FACLIN');
    if Assigned(colArticulo) and
       Assigned(dbView.Controller.FocusedRecord) then
      sCodArt := VarToStr(
        dbView.Controller.FocusedRecord.Values[colArticulo.Index]);
  end;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

procedure TfrmMtoEmpresas.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  with tvFacturacion.DataController.DataSet do
  ShowMto(Self.Owner,
          'Clientes',
          FieldByName('CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoEmpresas.FormCreate(Sender: TObject);
begin
  inherited;
  chkAplicaRetencionesPropertiesChange(Sender);
end;

procedure TfrmMtoEmpresas.IncorporarCertificados;
var
  formulario:TfrmMtoModalEmpCer;
begin
  formulario := TfrmMtoModalEmpCer.Create(Self.Owner);
  try
    formulario.Name := 'frmMtoModalEmpCer';
    //formulario.Caption := 'Seleccione Tarifas a incorporar al artículo';
    //dmmArticulos.FillTarifas(formulario.lstTarifas);
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      IterateCheckedList(formulario.lstCertificates);
  finally
    FreeAndNil(formulario);
  end;
end;

procedure TfrmMtoEmpresas.IterateCheckedList(lst: TcxListView);
var
  item: TListItem;
begin
  with dmmEmpresas.unqryTablaG do
  begin
    item := lst.Items[lst.Selected.Index];
    Edit;
    FieldByName('CODIGO_CERTIFICADO_EMP').AsString :=
                                            item.SubItems[COLUMNA_CER_NROSERIE];
    FieldByName('TITULAR_CERTIFICADO_EMP').AsString :=
                                             item.SubItems[COLUMNA_CER_TITULAR];
    FieldByName('TIPO_CERTIFICADO_EMP').AsString := item.Caption;
    FieldByName('FECHA_HASTA_CERTIFICADO_EMP').AsString :=
                                          item.SubItems[COLUMNA_CER_FECHAHASTA];
    Post;
  end;
end;

procedure TfrmMtoEmpresas.ResetForm;
begin
  inherited;
  pcPestana.ActivePage := tsMasDatos;
end;

procedure TfrmMtoEmpresas.tsFichaEnter(Sender: TObject);
begin
  inherited;
  txtRAZONSOCIAL_EMPRESA.SetFocus;
end;

procedure TfrmMtoEmpresas.txtCODIGO_PAIS_EMPRESAPropertiesChange(
  Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) or (dsTablaG.State = dsEdit) then
  begin
    dsTablaG.DataSet.FieldByName('NOMBRE_PAI_EMP').AsString :=
                         dmmEmpresas.unqryPaises.FieldByName('NOMBRE').AsString;
  end;
end;
initialization
  ForceReferenceToClass(TfrmMtoEmpresas);
end.
