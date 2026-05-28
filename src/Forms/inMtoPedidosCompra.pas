{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPedidosCompra                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento de pedidos de COMPRA.                                       }
{    Cabecera + lineas sobre fza_pedidos_compra. Espejo simplificado del       }
{    Mto de albaranes de compra, adaptado a un documento que NO mueve         }
{    stock fisico: en su lugar deposita el compromiso en                       }
{    fza_articulos_pdte_recibir.                                               }
{                                                                              }
{    Boton "Crear albaran" abre el modal selector de almacen y, al             }
{    aceptar, llama a inLibPedidosCompra.CrearAlbaranDesdePedido para         }
{    generar un albaran con las lineas pendientes del almacen elegido y       }
{    disparar los movimientos via inLibAlbaranesCompraMovimientos.            }
{******************************************************************************}
unit inMtoPedidosCompra;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni,
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
  UniDataPedidosCompra;

type
  TfrmMtoPedidosCompra = class(TfrmMtoGen)
    pnlTopFicha:         TPanel;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcPedido:            TcxPageControl;
    tsLineasPedido:      TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    pnlBottomTotales:    TPanel;
    cxgrdLineasPedido:   TcxGrid;
    tvLineasPedido:      TcxGridDBTableView;
    cxgrdlvlLineasPedido: TcxGridLevel;

    // Cabecera
    lblNroPedido:    TcxLabel;
    txtNUMERO_PEDC:  TcxDBTextEdit;
    lblSeriePedido:  TcxLabel;
    txtSERIE_PEDC:   TcxDBTextEdit;
    lblFechaPedido:  TcxLabel;
    dteFECHA_PEDC:   TcxDBDateEdit;
    lblFechaPrevista:TcxLabel;
    dteFECHA_PREVISTA_PEDC: TcxDBDateEdit;
    lblEstadoPedido: TcxLabel;
    txtESTADO_PEDC:  TcxDBTextEdit;
    lblCodigoEmpresa:   TcxLabel;
    btnCODIGO_EMP_PEDC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    btnCODIGO_PRV_PEDC: TcxDBButtonEdit;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_PEDC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    txtCODIGO_ALM_PEDC: TcxDBTextEdit;

    // Totales
    lblTotalBases:           TcxLabel;
    curTOTAL_BASES_PEDC:     TcxDBCurrencyEdit;
    lblTotalImpuestos:       TcxLabel;
    curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit;
    lblTotalLiquido:         TcxLabel;
    curTOTAL_LIQUIDO_PEDC:   TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de accion
    btnAnadirLinea:   TcxButton;
    btnBorrarLinea:   TcxButton;
    btnCrearAlbaran:  TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
  private
  public
    dmmPedidosCompra: TdmPedidosCompra;
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoPedidosCompra: TfrmMtoPedidosCompra;

implementation

uses
  inLibGlobalVar,
  inLibPedidosCompra,
  inMtoModalSelAlmacenPedido;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoPedidosCompra.FormCreate(Sender: TObject);
begin
  inherited;
end;

procedure TfrmMtoPedidosCompra.CrearTablaPrincipal;
begin
  inherited;
  // El padre (TfrmMtoGen.CrearTablaPrincipal -> CrearDataModule) ya creo
  // la instancia del DM via RTTI desde fza_winforms. Fallback Create por
  // si la entrada en fza_winforms no esta presente (BBDD sin migracion).
  dmmPedidosCompra := (tdmDataModule as TdmPedidosCompra);
  if not Assigned(dmmPedidosCompra) then
  begin
    dmmPedidosCompra := TdmPedidosCompra.Create(Self);
    dsTablaG.DataSet := dmmPedidosCompra.unqryTablaG;
    tdmDataModule := dmmPedidosCompra;
  end;
  tvLineasPedido.DataController.DataSource :=
    dmmPedidosCompra.dsPedidosCompraLineas;
  dmmPedidosCompra.unqryPedidosCompraLineas.MasterSource := dsTablaG;
  pkFieldName := 'SERIE_PEDC;NUMERO_PEDC';
end;

procedure TfrmMtoPedidosCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidosCompra.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoPedidosCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  dmmPedidosCompra.unqryPedidosCompraLineas.Append;
end;

procedure TfrmMtoPedidosCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg('Esta seguro de que desea eliminar esta linea?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmPedidosCompra.unqryPedidosCompraLineas.Delete;
end;

procedure TfrmMtoPedidosCompra.btnCrearAlbaranClick(Sender: TObject);
var
  form: TfrmModalSelAlmacenPedido;
  sSerie, sNumero, sNumAlb, sMsg: string;
  bOk: Boolean;
  bTxOwned: Boolean;
begin
  inherited;
  if dmmPedidosCompra = nil then Exit;
  if dmmPedidosCompra.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay pedido activo del que crear albaran.');
    Exit;
  end;
  // Persistir cualquier cambio pendiente para que el modal y la
  // generacion vean el ultimo estado.
  if dmmPedidosCompra.unqryTablaG.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryTablaG.Post;
  if dmmPedidosCompra.unqryPedidosCompraLineas.State in [dsEdit, dsInsert] then
    dmmPedidosCompra.unqryPedidosCompraLineas.Post;
  sSerie  := dmmPedidosCompra.unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := dmmPedidosCompra.unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  form := TfrmModalSelAlmacenPedido.Create(Application);
  try
    form.SeriePedc := sSerie;
    form.NumPedc   := sNumero;
    form.ShowModal;
    if not form.Aceptado then Exit;
    if Trim(form.CodigoAlmacen) = '' then Exit;

    bTxOwned := not inLibGlobalVar.oConn.InTransaction;
    if bTxOwned then inLibGlobalVar.oConn.StartTransaction;
    try
      bOk := inLibPedidosCompra.CrearAlbaranDesdePedido(
              inLibGlobalVar.oConn, sSerie, sNumero, form.CodigoAlmacen,
              sSerie, oUser, sNumAlb, sMsg);
      if bOk then
      begin
        if bTxOwned then inLibGlobalVar.oConn.Commit;
        ShowMessage(sMsg);
        // Refrescar el pedido en pantalla para ver CANTIDAD_RECIBIDA
        // actualizada y nuevo ESTADO_PEDC.
        dmmPedidosCompra.unqryTablaG.Refresh;
        dmmPedidosCompra.unqryPedidosCompraLineas.Refresh;
      end
      else
      begin
        if bTxOwned then inLibGlobalVar.oConn.Rollback;
        MessageDlg(sMsg, mtWarning, [mbOk], 0);
      end;
    except
      on E: Exception do
      begin
        if bTxOwned and inLibGlobalVar.oConn.InTransaction then
          inLibGlobalVar.oConn.Rollback;
        MessageDlg('Error al crear el albaran: ' + E.Message,
                   mtError, [mbOk], 0);
      end;
    end;
  finally
    FreeAndNil(form);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoPedidosCompra);
end.
