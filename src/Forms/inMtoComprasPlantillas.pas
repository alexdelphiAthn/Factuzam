{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit inMtoComprasPlantillas;

{
  Formulario para gestionar plantillas globales reutilizables de
  cabecera de sesión de compra (fza_compras_plantillas + _props + _kits
  + _kits_det).

  Permite:
   - Listar plantillas existentes (filtrables por proveedor, familia).
   - Crear/editar una plantilla manualmente.
   - Importar la configuración de una sesión existente como plantilla
     nueva (botón "Guardar como plantilla" en el form de sesiones; aquí
     sólo se mantiene la plantilla resultante).
   - Aplicar plantilla al crear sesión nueva: este formulario no aplica;
     la aplicación se hace desde el Mto consumidor (inMtoComprasSesiones
     u otros que se construyan sobre el patron inLibGridTallasInline)
     invocando inLibComprasSesiones.AplicarPlantilla cuando se integre.
}

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.Buttons,
  inMtoGen,
  dxSkinsCore, dxSkinBlue, dxSkinsForm,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, DB, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupComboBox,
  cxCheckBox, cxGroupBox, cxNavigator, cxDBNavigator,
  dxDateRanges, dxScrollbarAnnotations, dxBevel,
  System.UITypes, cxGraphics, cxBlobEdit, cxDBLookupEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, cxRadioGroup,
  inLibComprasPantallaIntf;

type
  TfrmMtoComprasPlantillas = class(TfrmMtoGen)
    // Lista
    dbcCodigoSespl       : TcxGridDBColumn;
    dbcNombreSespl       : TcxGridDBColumn;
    dbcCodigoPrvSespl    : TcxGridDBColumn;
    dbcCodigoFamSespl    : TcxGridDBColumn;
    dbcEsactivaSespl     : TcxGridDBColumn;

    // Ficha
    pcPlantilla          : TcxPageControl;
    tsDatos              : TcxTabSheet;
    tsPropsPlantilla     : TcxTabSheet;
    tsKitsPlantilla      : TcxTabSheet;

    gbDatos              : TcxGroupBox;
    lblCodigo            : TcxLabel;
    txtCodigo            : TcxDBTextEdit;
    lblNombre            : TcxLabel;
    txtNombre            : TcxDBTextEdit;
    lblDescripcion       : TcxLabel;
    txtDescripcion       : TcxDBTextEdit;
    lblProveedor         : TcxLabel;
    cbbProveedor         : TcxDBLookupComboBox;
    lblFamilia           : TcxLabel;
    cbbFamilia           : TcxDBLookupComboBox;
    lblVariacion         : TcxLabel;
    cbbVariacion         : TcxDBLookupComboBox;
    lblConjPivot         : TcxLabel;
    cbbConjuntoPivot     : TcxDBLookupComboBox;
    lblConjFila          : TcxLabel;
    cbbConjuntoFila      : TcxDBLookupComboBox;
    chkVarFija           : TcxDBCheckBox;
    chkActiva            : TcxDBCheckBox;

    cxgrdProps           : TcxGrid;
    tvProps              : TcxGridDBTableView;
    glProps              : TcxGridLevel;
    dbcPropsCodigo       : TcxGridDBColumn;
    dbcPropsFijo         : TcxGridDBColumn;
    dbcPropsValor        : TcxGridDBColumn;
    btnAddProp           : TcxButton;
    btnDelProp           : TcxButton;

    cxgrdKits            : TcxGrid;
    tvKits               : TcxGridDBTableView;
    glKits               : TcxGridLevel;
    cxgrdKitsDet         : TcxGrid;
    tvKitsDet            : TcxGridDBTableView;
    glKitsDet            : TcxGridLevel;
    dbcKitsCodigo        : TcxGridDBColumn;
    dbcKitsNombre        : TcxGridDBColumn;
    dbcKitsDetValor      : TcxGridDBColumn;
    dbcKitsDetCantidad   : TcxGridDBColumn;
    btnAddKit            : TcxButton;
    btnDelKit            : TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAddPropClick(Sender: TObject);
    procedure btnDelPropClick(Sender: TObject);
    procedure btnAddKitClick(Sender: TObject);
    procedure btnDelKitClick(Sender: TObject);
  private
    FPersistenciaPlantillas: IPersistenciaPlantillasCompraPantalla;
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inLibUser, inLibMsgCompras,
  UniDataComprasPantallaComposicion;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoComprasPlantillas.CrearTablaPrincipal;
begin
  inherited;
  pkFieldName := 'CODIGO_SESPL';
end;

procedure TfrmMtoComprasPlantillas.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoComprasPlantillas.FormCreate(Sender: TObject);
var
  oEntrada: TEntradaComposicionComprasPantalla;
  oServicios: TServiciosComprasPantalla;
begin
  inherited;
  oEntrada := Default(TEntradaComposicionComprasPantalla);
  oEntrada.Tipo := tccPlantillas;
  oEntrada.Conexion := ConexionPrincipal;
  oEntrada.MaestroPlantillas := dsTablaG;
  oServicios := ComponerComprasPantalla(nil, oEntrada);
  FPersistenciaPlantillas := oServicios.Plantillas;
  dsTablaG.DataSet := FPersistenciaPlantillas.DataSetPlantillas;
  tvProps.DataController.DataSource :=
    FPersistenciaPlantillas.DataSourcePropiedades;
  tvKits.DataController.DataSource :=
    FPersistenciaPlantillas.DataSourceKits;
  tvKitsDet.DataController.DataSource :=
    FPersistenciaPlantillas.DataSourceDetalleKits;
  FPersistenciaPlantillas.Abrir;
end;

destructor TfrmMtoComprasPlantillas.Destroy;
begin
  FPersistenciaPlantillas := nil;
  inherited;
end;

procedure TfrmMtoComprasPlantillas.btnGrabarClick(Sender: TObject);
begin
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  inherited;
end;

procedure TfrmMtoComprasPlantillas.btnAddPropClick(Sender: TObject);
begin
  inherited;
  FPersistenciaPlantillas.AnadirPropiedad;
end;

procedure TfrmMtoComprasPlantillas.btnDelPropClick(Sender: TObject);
begin
  inherited;
  if not FPersistenciaPlantillas.DataSourcePropiedades.DataSet.IsEmpty then
  begin
    if MessageDlg(SPreguntaBorrarPropiedadPlantillaCompra,
                  mtConfirmation,
                  [mbYes, mbNo],
                  0) = mrYes then
      FPersistenciaPlantillas.BorrarPropiedad;
  end;
end;

procedure TfrmMtoComprasPlantillas.btnAddKitClick(Sender: TObject);
begin
  inherited;
  FPersistenciaPlantillas.AnadirKit;
end;

procedure TfrmMtoComprasPlantillas.btnDelKitClick(Sender: TObject);
begin
  inherited;
  if not FPersistenciaPlantillas.DataSourceKits.DataSet.IsEmpty then
  begin
    if MessageDlg(SPreguntaBorrarKitPlantillaCompra,
                  mtConfirmation,
                  [mbYes, mbNo],
                  0) = mrYes then
      FPersistenciaPlantillas.BorrarKit;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoComprasPlantillas);
  ForceReferenceToClass(TfrmMtoComprasPlantillas);
end.
