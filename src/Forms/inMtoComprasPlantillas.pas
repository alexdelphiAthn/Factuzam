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
  Uni, MemDS, DBAccess, System.UITypes, cxGraphics, cxBlobEdit, cxDBLookupEdit,
  dxShellDialogs, JvComponentBase, JvEnterTab, cxLocalization, cxRadioGroup;

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

    // DataSets
    unqryPlantillas      : TUniQuery;
    unqryPlantillaProps  : TUniQuery;
    unqryPlantillaKits   : TUniQuery;
    unqryPlantillaKitsDet: TUniQuery;
    dsPlantillaProps     : TDataSource;
    dsPlantillaKits      : TDataSource;
    dsPlantillaKitsDet   : TDataSource;

    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAddPropClick(Sender: TObject);
    procedure btnDelPropClick(Sender: TObject);
    procedure btnAddKitClick(Sender: TObject);
    procedure btnDelKitClick(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoComprasPlantillas: TfrmMtoComprasPlantillas;

implementation

uses
  inLibWin, inLibUser, inLibGlobalVar;

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
begin
  inherited;
  unqryPlantillas.Connection       := oConn;
  unqryPlantillaProps.Connection   := oConn;
  unqryPlantillaKits.Connection    := oConn;
  unqryPlantillaKitsDet.Connection := oConn;
  unqryPlantillas.Open;
  unqryPlantillaProps.Open;
  unqryPlantillaKits.Open;
  unqryPlantillaKitsDet.Open;

  dsTablaG.DataSet := unqryPlantillas;
  tvProps.DataController.DataSource    := dsPlantillaProps;
  tvKits.DataController.DataSource     := dsPlantillaKits;
  tvKitsDet.DataController.DataSource  := dsPlantillaKitsDet;
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
  unqryPlantillaProps.Append;
end;

procedure TfrmMtoComprasPlantillas.btnDelPropClick(Sender: TObject);
begin
  inherited;
  if unqryPlantillaProps.IsEmpty then Exit;
  if MessageDlg('¿Borrar la propiedad?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    unqryPlantillaProps.Delete;
end;

procedure TfrmMtoComprasPlantillas.btnAddKitClick(Sender: TObject);
begin
  inherited;
  unqryPlantillaKits.Append;
end;

procedure TfrmMtoComprasPlantillas.btnDelKitClick(Sender: TObject);
begin
  inherited;
  if unqryPlantillaKits.IsEmpty then Exit;
  if MessageDlg('¿Borrar el kit?',
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    unqryPlantillaKits.Delete;
end;

initialization
  ForceReferenceToClass(TfrmMtoComprasPlantillas);
end.
