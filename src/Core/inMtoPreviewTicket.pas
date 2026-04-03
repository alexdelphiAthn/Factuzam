unit inMtoPreviewTicket;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, dxCore, dxCoreClasses, dxHashUtils,
  Vcl.Menus, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSpreadSheet,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization, dxShellDialogs,
  System.Actions, Vcl.ActnList, inLibFaseCobro;

type
  TfrmMtoPreviewTicket = class(TfrmBase)
    Panel1: TPanel;
    btnGuardar: TcxButton;
    btnCerrar: TcxButton;
    DialogoGuardar: TdxSaveFileDialog;
    ActionList1: TActionList;
    actSalir: TAction;
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMtoPreviewTicket: TfrmMtoPreviewTicket;

procedure ImprimirT(FCodigoEmpresa,
                    FCodigoAlmacen,
                    FCodigoCaja,
                    NumeroGenerado: string;
                    DatosCobro: TDatosFaseCobro);

implementation

{$R *.dfm}

uses inLibFTicket,
     inlibCajaParam;

procedure ImprimirT(FCodigoEmpresa,
                    FCodigoAlmacen,
                    FCodigoCaja,
                    NumeroGenerado: string;
                    DatosCobro: TDatosFaseCobro);
var
  sNombreImpresora:String;
begin
  if DatosCobro.FRequiereFactura then
  begin
    sNombreImpresora:= oCajaParams.GetString('vgerDefPrinter', 'DEBUG');
    //'vgerDefPrinter vgerTipoImpresion';
  end;
end;



procedure TfrmMtoPreviewTicket.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnCerrarClick(Sender);
end;

procedure TfrmMtoPreviewTicket.btnCerrarClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmMtoPreviewTicket.btnGuardarClick(Sender: TObject);
begin
  inherited;
//  DialogoGuardar.DefaultExt := 'xlsx';
//  DialogoGuardar.Filter := 'Libro de Excel (*.xlsx)|*.xlsx';
//  if DialogoGuardar.Execute then
//    dxSpreadSheet1.SaveToFile(DialogoGuardar.FileName);
end;

procedure TfrmMtoPreviewTicket.FormShow(Sender: TObject);
begin
  inherited;
  Self.WindowState := wsMaximized;
end;


end.
