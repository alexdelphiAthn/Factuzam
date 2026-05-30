{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoProveedores                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de proveedores.                                             }
{    CRUD sobre fza_proveedores con datos fiscales y comerciales.              }
{******************************************************************************}
unit inMtoProveedores;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen,
  dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  Vcl.Menus, cxContainer, dxSkinsForm, cxClasses, cxLocalization, cxDBNavigator,
  cxLabel, Vcl.StdCtrls, cxButtons, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  Vcl.ExtCtrls, UniDataConn, UniDataProveedores, Vcl.ToolWin,
  Vcl.ActnMan, Vcl.ActnCtrls, cxTextEdit, Vcl.Buttons, dxBevel, cxCurrencyEdit,
  cxCalendar, cxMaskEdit, cxDropDownEdit, cxDBEdit, dxGDIPlusClasses, cxImage,
  cxCustomListBox, cxCheckListBox, cxDBCheckListBox, cxCheckBox, cxMemo,
  inLibDevExp, inLibtb, cxBlobEdit, ClipBrd, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, System.Actions, Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls,
  cxSplitter, cxSpinEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoProveedores = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn;
    pnlCabFicha: TPanel;
    txtCODIGO_PROVEEDOR: TcxDBTextEdit;
    lblCodigo: TcxLabel;
    txtRAZONSOCIAL_PROVEEDOR: TcxDBTextEdit;
    lblRazonSocial: TcxLabel;
    txtNOMBRE_PROVEEDOR: TcxDBTextEdit;
    lblNombreComercial: TcxLabel;
    cxdbtxtdtTELEFONO2: TcxDBTextEdit;
    lblEmail: TcxLabel;
    cxdbtxtdtEMAIL: TcxDBTextEdit;
    lblNif: TcxLabel;
    cxdbtxtdtNIF: TcxDBTextEdit;
    cxdbtxtdtMOVIL_CLIENTE: TcxDBTextEdit;
    pnlDetailFicha: TPanel;
    pcPestanas: TcxPageControl;
    tsDomicilioFiscal: TcxTabSheet;
    cxdbtxtdt7: TcxDBTextEdit;
    lblDireccion1: TcxLabel;
    lblCodPostal: TcxLabel;
    cxdbtxtdt8: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    cxdbtxtdt9: TcxDBTextEdit;
    cxdbtxtdt10: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    cxdbtxtdt16: TcxDBTextEdit;
    lblPais: TcxLabel;
    cxdbtxtdtDireccion: TcxDBTextEdit;
    lblDireccion2: TcxLabel;
    tsMasDatos: TcxTabSheet;
    lblObservaciones: TcxLabel;
    lblReferencia: TcxLabel;
    cxdbtxtdtREFERENCIA_CLIENTE: TcxDBTextEdit;
    lblContacto: TcxLabel;
    cxdbtxtdtREFERENCIA_CLIENTE1: TcxDBTextEdit;
    cxdbtxtdtIBAN: TcxDBTextEdit;
    lblNroCuenta: TcxLabel;
    lblTelefonoContacto: TcxLabel;
    cxdbtxtdtCONTACTO_CLIENTE: TcxDBTextEdit;
    tsOtros: TcxTabSheet;
    pnl3: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    lblUsuarioAlta: TcxLabel;
    lblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxdbm2: TcxDBMemo;
    chkActivo: TcxDBCheckBox;
    cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    pnl6: TPanel;
    btnIraArticulo: TcxButton;
    pnl61: TPanel;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    cxgrdbclmnArticulosCODIGO_PROVEEDOR: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosCODIGO_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosDESCRIPCION_FAMILIA: TcxGridDBColumn;
    cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn;
    cxgrdbclmnArticulosPRECIO_ULT_COMPRA: TcxGridDBColumn;
    cxgrdbclmnArticulosFECHA_VALIDEZ: TcxGridDBColumn;
    cxgrdbclmnArticulosESPROVEEDORPRINCIPAL: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnArticulosINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnArticulosUSUARIOMODIF: TcxGridDBColumn;
    tsVentas: TcxTabSheet;
    cxgrdLinFac: TcxGrid;
    tvLinFac: TcxGridDBTableView;
    cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn;
    cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn;
    cxgrdlvlLinFac: TcxGridLevel;
    cxspltr1: TcxSplitter;
    lblTextoLegal11: TcxLabel;
    cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit;
    btnNuevoProveedor: TcxButton;
    dbcLinFacNOMBRE_TIPO_IVA: TcxGridDBColumn;
    dbcLinFacCODIGO_TARIFA_FACTURA_LINEA: TcxGridDBColumn;
    pnl62: TPanel;
    btnIraFactura: TcxButton;
    btnIraCliente: TcxButton;
    dbcLinFacCODIGO_CLIENTE_FACTURA: TcxGridDBColumn;
    btnExportar: TcxButton;
    btnIraArticuloVentas: TcxButton;
    ActionListProveedores: TActionList;
    actArticulos: TAction;
    actFacturas: TAction;
    actClientes: TAction;
    procedure btnGrabarClick(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure btnNuevoProveedorClick(Sender: TObject);
    procedure actFacturasExecute(Sender: TObject);
    procedure btnIraFacturaClick(Sender: TObject);
    procedure btnIraClienteClick(Sender: TObject);
    procedure actClientesExecute(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
    // Carga perezosa de sub-pestañas detail (Articulos, Ventas).
    procedure PcPestanasChange(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  dmmProveedores: TDMProveedores;
  frmMtoProveedores: TfrmMtoProveedores;

implementation

uses
  inLibWin,
  inLibUser,
  inLibShowMto,
  inLibFotos,
  inMtoPrincipal,
  inMtoArticulos,
  inMtoClientes,
  inMtoFacturasBase;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// El Mto de proveedores tiene articulo en dos pestanas: los articulos
// del proveedor (tsArticulos / tvArticulos) y las lineas de venta
// (tsVentas / tvLinFac). El articulo activo es el de la rejilla de la
// pestana visible; ambas rejillas exponen CODIGO_ART_ART.
procedure TfrmMtoProveedores.ResolverArtSkuActivo(out ACodArt,
                                                  ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  ds := nil;
  if pcPestanas.ActivePage = tsArticulos then
  begin
    if Assigned(tvArticulos.DataController.DataSource) then
      ds := tvArticulos.DataController.DataSource.DataSet;
  end
  else if pcPestanas.ActivePage = tsVentas then
  begin
    if Assigned(tvLinFac.DataController.DataSource) then
      ds := tvLinFac.DataController.DataSource.DataSet;
  end;
  if ds <> nil then
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
end;

// Enganchamos los dos datasets de articulo para que la foto flotante
// siga al cursor en cualquiera de las dos pestanas.
function TfrmMtoProveedores.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmProveedores) then
    Result := [dsTablaG, dmmProveedores.dsArticulos,
               dmmProveedores.dsLinFacturasArticulos]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoProveedores.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  with dmmProveedores do
  begin
    if ((pcPestanas.ActivePage = tsArticulos)) then
      ShowMto(Self.Owner,
              'Articulos',
              unqryArticulos.FieldByName('CODIGO_ART_ART').AsString)
    else
      if ((pcPestanas.ActivePage = tsVentas)) then
        ShowMto(Self.Owner,
                'Articulos',
             unqryLinFacturasArticulos.FieldByName('CODIGO_ART_ART').AsString);
  end;
end;

procedure TfrmMtoProveedores.btnIraClienteClick(Sender: TObject);
begin
  inherited;
  ShowMto(Self.Owner,
          'Clientes',
          dmmProveedores.unqryLinFacturasArticulos.FieldByName(
                                            'CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoProveedores.btnIraFacturaClick(Sender: TObject);
var
  sNroFactura, sSerieFactura:String;
begin
  inherited;
  sNroFactura := tvLinFac.DataController.DataSet.FieldByName(
                                                  'NUMERO_FAC_FACLIN').AsString;
  sSerieFactura := tvLinFac.DataController.DataSet.FieldByName(
                                                'SERIE_FAC_FACLIN').AsString;
  ShowMto(Self.Owner,
          'Facturas',
          sNroFactura +','+ sSerieFactura);
end;

procedure TfrmMtoProveedores.btnNuevoProveedorClick(Sender: TObject);
begin
  inherited;
  if ( (dmmProveedores.unqryTablaG.State = dsInsert) or
       (dmmProveedores.unqryTablaG.State = dsEdit)) then
  begin
    dmmProveedores.unqryTablaG.Post;
  end;
  dmmProveedores.unqryTablaG.Insert;
  tsFicha.SetFocus;
  pcPestanas.ActivePageIndex := tsDomicilioFiscal.PageIndex;
  txtRAZONSOCIAL_PROVEEDOR.SetFocus;
end;

procedure TfrmMtoProveedores.actClientesExecute(Sender: TObject);
begin
  inherited;
  //Control + K
    if (
      (pcPestanas.ActivePage = tsVentas)
     ) then
       btnIraClienteClick(Sender)
  else
    ShowMto(Self.Owner,
            'Clientes');
end;

procedure TfrmMtoProveedores.actFacturasExecute(Sender: TObject);
begin
  inherited;
  //Control + F
    if (
        (pcPestanas.ActivePage = tsVentas)) then
      btnIraFacturaClick(Sender)
    else
      ShowMto(Self.Owner,
              'Facturas');
end;

procedure TfrmMtoProveedores.actArticulosExecute(Sender: TObject);
begin
  inherited;
  // Control + R
  btnIraArticuloClick(Sender);
end;

procedure TfrmMtoProveedores.btnExportarClick(Sender: TObject);
begin
  inherited;
  ExportarExcel(cxgrdLinFac, 'Ventas de artículos por proveedor_' +
                     dsTablaG.DataSet.FieldByName('CODIGO_PRV_PRV').AsString);
end;

procedure TfrmMtoProveedores.btnGrabarClick(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoProveedores.CrearTablaPrincipal;
begin
  inherited;
  dmmProveedores := tdmDataModule as TdmProveedores;
  tvArticulos.DataController.DataSource := dmmProveedores.dsArticulos;
  tvLinFac.DataController.DataSource := dmmProveedores.dsLinFacturasArticulos;
  pcPestanas.ActivePage := tsDomicilioFiscal;
  pkFieldName := 'CODIGO_PRV_PRV';
  // Carga perezosa de sub-pestañas detail (default = tsDomicilioFiscal,
  // que no usa query detail). Articulos/Ventas se abren solo cuando
  // el usuario activa su pestaña.
  pcPestanas.OnChange := PcPestanasChange;
end;

procedure TfrmMtoProveedores.PcPestanasChange(Sender: TObject);
begin
  if not Assigned(dmmProveedores) then Exit;
  if pcPestanas.ActivePage = tsArticulos then
    dmmProveedores.AsegurarArticulosAbierta
  else if pcPestanas.ActivePage = tsVentas then
    dmmProveedores.AsegurarVentasAbierta;
end;

procedure TfrmMtoProveedores.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoProveedores.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtCODIGO_PROVEEDOR.Enabled := True
  else
  begin
    txtCODIGO_PROVEEDOR.Enabled := False;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoProveedores);
end.

