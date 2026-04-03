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
    function BuscarImpresoraPorPatrones(const Patrones: string): string;
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

function TfrmMtoPreviewTicket.BuscarImpresoraPorPatrones(const Patrones: string): string;
var
  ListaSubcadenas: TStringList;
  ListaImpresoras: TStringList;
  i, j: Integer;
  NombreImpresora, Subcadena: string;
  CoincideConTodos: Boolean;
  PatronesCoincidentes: Integer;
begin
  Result := '';
  ListaSubcadenas := nil;
  ListaImpresoras := nil;
  try
    // Separar los patrones de búsqueda
//    ListaSubcadenas := SepararSubcadenas(Patrones);
//    if ListaSubcadenas.Count = 0 then
//    begin
//      EscribirLog('No se especificaron patrones de búsqueda válidos');
//      Exit;
//    end;
//    EscribirLog('Patrones de búsqueda (debe coincidir con TODOS): ' + Patrones);
    for i := 0 to ListaSubcadenas.Count - 1 do
//      EscribirLog('  - Patrón ' + IntToStr(i + 1) + ': "' +                                                      ListaSubcadenas[i] + '"');
    // Obtener lista de impresoras instaladas
    ListaImpresoras := ObtenerListaImpresoras;
    if ListaImpresoras.Count = 0 then
    begin
//      EscribirLog('No hay impresoras disponibles para buscar');
      Exit;
    end;
    // Buscar la primera impresora que coincida con TODAS las subcadenas (AND)
    for i := 0 to ListaImpresoras.Count - 1 do
    begin
      NombreImpresora := ListaImpresoras[i];
//      EscribirLog('Evaluando impresora: ' + NombreImpresora);
      CoincideConTodos := True;
      PatronesCoincidentes := 0;
      // Verificar TODOS los patrones
      for j := 0 to ListaSubcadenas.Count - 1 do
      begin
        Subcadena := ListaSubcadenas[j];
        if Pos(UpperCase(Subcadena), UpperCase(NombreImpresora)) > 0 then
        begin
//          EscribirLog('  ✓ Coincide con patrón ' + IntToStr(j + 1) + ': "' +
//                                                               Subcadena + '"');
          Inc(PatronesCoincidentes);
        end
        else
        begin
//          EscribirLog('  ✗ NO coincide con patrón ' + IntToStr(j + 1) + ': "' +
//                                                               Subcadena + '"');
          CoincideConTodos := False;
        end;
      end;
      // Si coincide con TODOS los patrones, seleccionarla
      if CoincideConTodos then
      begin
        Result := NombreImpresora;
//        EscribirLog('  ✓✓✓ IMPRESORA SELECCIONADA (coincide con ' +
//        IntToStr(PatronesCoincidentes) + '/' + IntToStr(ListaSubcadenas.Count) +
//                                                                  ' patrones)');
//        EscribirLog('  → ' + Result);
        Exit;
      end
      else
//        EscribirLog('  ✗✗✗ Descartada (solo coincide con ' +
//                                          IntToStr(PatronesCoincidentes) + '/' +
//                                IntToStr(ListaSubcadenas.Count) + ' patrones)');
    end;
    if Result = '' then
//      EscribirLog('ADVERTENCIA: No se encontró ninguna impresora que coincida' +
//                  ' con TODOS los patrones');
  finally
    if Assigned(ListaSubcadenas) then
      ListaSubcadenas.Free;
    if Assigned(ListaImpresoras) then
      ListaImpresoras.Free;
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
