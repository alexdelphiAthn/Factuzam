unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, cxDBData, cxClasses, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, cxDropDownEdit,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox;

type
  TfrmMtoOpeCaja = class(TForm)
    pnlUp1: TPanel;
    pnlCli1: TPanel;
    btEdtEmpleado: TcxButtonEdit;
    lblFecha: TcxLabel;
    Panel1: TPanel;
    btF12: TcxButton;
    btF3: TcxButton;
    btF6: TcxButton;
    btF5: TcxButton;
    btF7: TcxButton;
    lblCobro: TcxLabel;
    lblBuscar: TcxLabel;
    lblTarifa: TcxLabel;
    lblIndIVA: TcxLabel;
    lblOtro: TcxLabel;
    Panel2: TPanel;
    grdLineasVenta: TcxGrid;
    tvLineasCaja: TcxGridDBTableView;
    grdLineasVentaLv1: TcxGridLevel;
    tvEmpleado: TcxGridDBColumn;
    tvArtículo: TcxGridDBColumn;
    tvDescripción: TcxGridDBColumn;
    tvUds: TcxGridDBColumn;
    tvPrecioUni: TcxGridDBColumn;
    tvDescuento: TcxGridDBColumn;
    tvDescuentoMenos: TcxGridDBColumn;
    tvTotal: TcxGridDBColumn;
    lblTotal: TcxLabel;
    btF8: TcxButton;
    lblEliminar: TcxLabel;
    lblNombreEmpresa: TcxLabel;
    cxLabel8: TcxLabel;
    btedtCliente: TcxButtonEdit;
    lblfechaCaja: TcxLabel;
    Timer1: TTimer;
    cmbEmpleados: TcxLookupComboBox;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMtoOpeCaja: TfrmMtoOpeCaja;

implementation

{$R *.dfm}

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  lblFechaCaja.Caption := FormatDateTime( 'hh:nn:ss dddd d mmmm yyyy', Now);
end;

end.
