{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacturarAlbaranesFechas                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para facturar albaranes filtrando por serie y rango de fechas.      }
{    Permite agrupar por cliente al generar las facturas.                      }
{******************************************************************************}
unit inMtoModalFacturarAlbaranesFechas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCheckBox,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, dxSkinsCore, dxSkinBlue, cxContainer, cxMaskEdit,
  cxDropDownEdit, cxNavigator, cxPropertiesStore, dxSkinsForm,
  cxCalendar, cxDBData,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, UniDataAlbaranes, dxCore, cxDateUtils, Vcl.Menus;

type
  TfrmModalFacturarAlbaranesFechas = class(TfrmBase)
    pnlTop: TPanel;
    lblSerie: TcxLabel;
    edtSerie: TcxTextEdit;
    lblFechaDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblFechaHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    chkAgruparPorCliente: TcxCheckBox;
    btnBuscar: TcxButton;
    pnlMid: TPanel;
    cxgrdAlbaranes: TcxGrid;
    tvAlbaranes: TcxGridTableView;
    cxgrdlvlAlbaranes: TcxGridLevel;
    colSel: TcxGridColumn;
    colNumero: TcxGridColumn;
    colSerie: TcxGridColumn;
    colFecha: TcxGridColumn;
    colCliente: TcxGridColumn;
    colRazonSocial: TcxGridColumn;
    colTotal: TcxGridColumn;
    pnlBottom: TPanel;
    lblEstado: TcxLabel;
    btnSeleccionarTodos: TcxButton;
    btnFacturar: TcxButton;
    btnCerrar: TcxButton;
    qBuscar: TUniQuery;
    procedure FormCreate(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnSeleccionarTodosClick(Sender: TObject);
    procedure btnFacturarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    procedure CargarGrid;
  public
    dmmAlbaranes: TdmAlbaranes;
  end;

implementation

{$R *.dfm}

procedure TfrmModalFacturarAlbaranesFechas.FormCreate(Sender: TObject);
begin
  inherited;
  edtSerie.Text   := 'A1';
  dteDesde.Date   := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  dteHasta.Date   := Date;
  chkAgruparPorCliente.Checked := True;
  qBuscar.Connection := ConexionPrincipal;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnBuscarClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    lblEstado.Caption := 'Buscando albaranes...';
    Application.ProcessMessages;
    qBuscar.Close;
    qBuscar.SQL.Text :=
      'SELECT NUMERO_ALB, SERIE_ALB, FECHA_ALB, CODIGO_CLI_ALB, ' +
      '       RAZON_SOCIAL_CLIENTE_ALB, TOTAL_LIQUIDO_ALB ' +
      '  FROM fza_albaranes ' +
      ' WHERE SERIE_ALB   = :pSERIE ' +
      '   AND FECHA_ALB   BETWEEN :pDESDE AND :pHASTA ' +
      '   AND IFNULL(ESTADO_ALB, '''') <> ''FACTURADO'' ' +
      '   AND IFNULL(ESTADO_ALB, '''') <> ''CANCELADO'' ' +
      ' ORDER BY CODIGO_CLI_ALB, FECHA_ALB, NUMERO_ALB';
    qBuscar.ParamByName('pSERIE').AsString    := edtSerie.Text;
    qBuscar.ParamByName('pDESDE').AsDateTime  := dteDesde.Date;
    qBuscar.ParamByName('pHASTA').AsDateTime  := dteHasta.Date;
    qBuscar.Open;
    CargarGrid;
    lblEstado.Caption := Format('Albaranes encontrados: %d',
                                [tvAlbaranes.DataController.RecordCount]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalFacturarAlbaranesFechas.CargarGrid;
var
  i: Integer;
begin
  tvAlbaranes.DataController.RecordCount := 0;
  tvAlbaranes.DataController.RecordCount := qBuscar.RecordCount;
  qBuscar.First;
  i := 0;
  while not qBuscar.Eof do
  begin
    tvAlbaranes.DataController.Values[i, colSel.Index]         := True;
    tvAlbaranes.DataController.Values[i, colNumero.Index]      :=
      qBuscar.FieldByName('NUMERO_ALB').AsString;
    tvAlbaranes.DataController.Values[i, colSerie.Index]       :=
      qBuscar.FieldByName('SERIE_ALB').AsString;
    tvAlbaranes.DataController.Values[i, colFecha.Index]       :=
      qBuscar.FieldByName('FECHA_ALB').AsDateTime;
    tvAlbaranes.DataController.Values[i, colCliente.Index]     :=
      qBuscar.FieldByName('CODIGO_CLI_ALB').AsString;
    tvAlbaranes.DataController.Values[i, colRazonSocial.Index] :=
      qBuscar.FieldByName('RAZON_SOCIAL_CLIENTE_ALB').AsString;
    tvAlbaranes.DataController.Values[i, colTotal.Index]       :=
      qBuscar.FieldByName('TOTAL_LIQUIDO_ALB').AsCurrency;
    Inc(i);
    qBuscar.Next;
  end;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnSeleccionarTodosClick(
  Sender: TObject);
var
  i: Integer;
  bAlguno: Boolean;
begin
  bAlguno := False;
  for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
    if not Boolean(tvAlbaranes.DataController.Values[i, colSel.Index]) then
    begin
      bAlguno := True;
      Break;
    end;
  for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
    tvAlbaranes.DataController.Values[i, colSel.Index] := bAlguno;
end;

procedure TfrmModalFacturarAlbaranesFechas.btnFacturarClick(Sender: TObject);
var
  i, generadas: Integer;
  lst: TStringList;
  sNumAlb, sSerAlb: string;
begin
  if dmmAlbaranes = nil then
  begin
    ShowMessage('No hay datamodule de albaranes asignado.');
    Exit;
  end;
  lst := TStringList.Create;
  try
    for i := 0 to tvAlbaranes.DataController.RecordCount - 1 do
    begin
      if not Boolean(tvAlbaranes.DataController.Values[i, colSel.Index]) then
        Continue;
      sNumAlb :=
        VarToStr(tvAlbaranes.DataController.Values[i, colNumero.Index]);
      sSerAlb := VarToStr(tvAlbaranes.DataController.Values[i, colSerie.Index]);
      lst.Add(sSerAlb + '|' + sNumAlb);
    end;
    if lst.Count = 0 then
    begin
      ShowMessage('No hay albaranes seleccionados.');
      Exit;
    end;
    Screen.Cursor := crHourGlass;
    try
      lblEstado.Caption := Format('Creando borradores de %d albaranes...',
                                  [lst.Count]);
      Application.ProcessMessages;
      generadas := dmmAlbaranes.FacturarAlbaranesLista(lst,
                                                       chkAgruparPorCliente.Checked);
      lblEstado.Caption := Format('Generados %d borradores', [generadas]);
      ShowMessageFmt('Proceso finalizado. Borradores generados: %d.',
                     [generadas]);
      btnBuscarClick(nil);
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    FreeAndNil(lst);
  end;
end;

end.
