{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpArqueos                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de arqueos de caja (FastReport).         }
{    Informe A4 horizontal con los principales números de cada cierre. El      }
{    usuario puede retocar el formato con el diseñador (botón Editar) y         }
{    guardarlo como formato propio igual que el resto de informes.             }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo.        }
{******************************************************************************}
unit inMtoModalImpArqueos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxButtonEdit,
  cxDateUtils,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibGlobalVar;

type
  TfrmPrintArqueos = class(TfrmPrint)
    unqryArqueosPrint: TUniQuery;
    dsArqueosPrint: TDataSource;
    fxdsArqueos: TfrxDBDataset;
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblCajaTit: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    bedAlmacen: TcxButtonEdit;
    lblCaja: TcxLabel;
    bedCaja: TcxButtonEdit;
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedCajaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    // Fija los valores por defecto (rango de fechas y empresa/almacen/caja
    // del usuario) una sola vez al abrir; evita pisarlos en el ciclo
    // Hide/Show que hacen los botones del padre (Imprimir / PDF / etc.).
    FInicializado: Boolean;
    // Abre el selector estandar de caja (inMtoModalCajDef sobre la vista
    // vi_cajasdef) acotado a la empresa del usuario y vuelca el almacen y
    // la caja elegidos en bedAlmacen / bedCaja.
    procedure SeleccionarAlmacenCaja;
  protected
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintArqueos: TfrmPrintArqueos;

implementation

{$R *.dfm}

uses
  inMtoModalCajDef;

{ TfrmPrintArqueos }

procedure TfrmPrintArqueos.DoShow;
begin
  inherited;
  // Por defecto: rango del primer dia del mes en curso hasta hoy, y la
  // empresa / almacen / caja activos del usuario. El usuario puede ampliar
  // las fechas y cambiar almacen / caja con el boton '...' antes de imprimir.
  if not FInicializado then
  begin
    dteDesde.Date   := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date   := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    bedAlmacen.Text := UbicacionSesion.Almacen;
    bedCaja.Text    := UbicacionSesion.Caja;
    FInicializado   := True;
  end;
end;

procedure TfrmPrintArqueos.SeleccionarAlmacenCaja;
var
  frm: TfrmMtoModalCajDef;
begin
  // No se permite cambiar de empresa: acotamos el selector a la empresa
  // del usuario. De la fila elegida tomamos almacen y caja.
  frm := TfrmMtoModalCajDef.Create(Self);
  try
    frm.qrySeleccion.Connection := oConn;
    frm.qrySeleccion.SQL.Text :=
      ' SELECT * FROM vi_cajasdef WHERE Empresa = :pEMP ' +
      ' ORDER BY Almacen, Caja ';
    frm.qrySeleccion.ParamByName('pEMP').AsString := edtEmpresa.Text;
    frm.qrySeleccion.Open;
    // Cierra el cronometro SQL antes de entrar en el selector modal.
    CerrarMonitorSQLPendiente;
    frm.sEmpresa := edtEmpresa.Text;
    frm.sAlmacen := bedAlmacen.Text;
    frm.sCaja    := bedCaja.Text;
    // Este modal es fsStayOnTop (heredado de TfrmPrint); si no nos
    // ocultamos, el selector saldria por detras. Mismo patron que usa el
    // padre al abrir el selector de formatos (Self.Hide / Self.Show).
    Self.Hide;
    try
      frm.ShowModal;
      if frm.sFicha = 'S' then
      begin
        bedAlmacen.Text := frm.qrySeleccion.FieldByName('Almacen').AsString;
        bedCaja.Text    := frm.qrySeleccion.FieldByName('Caja').AsString;
      end;
    finally
      Self.Show;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmPrintArqueos.bedAlmacenPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintArqueos.bedCajaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintArqueos.preparar_consulta;
begin
  inherited;
  // Filtro por empresa / almacen / caja y por el dia de inicio del arqueo.
  // FECHA_DESDE_ARQ es datetime, asi que el limite superior va abierto al
  // dia siguiente para que el filtro de fecha simple incluya todo el dia.
  with unqryArqueosPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      ' SELECT *                                                          ' +
      '   FROM fza_caja_arqueos                                           ' +
      '  WHERE CODIGO_EMP_ARQ  = :pEMP                                    ' +
      '    AND CODIGO_ALM_ARQ  = :pALM                                    ' +
      '    AND CODIGO_CAJA_ARQ = :pCAJA                                   ' +
      '    AND FECHA_DESDE_ARQ >= :pDESDE                                 ' +
      '    AND FECHA_DESDE_ARQ < DATE_ADD(:pHASTA, INTERVAL 1 DAY)        ' +
      '  ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC                   ';
    ParamByName('pEMP').AsString     := edtEmpresa.Text;
    ParamByName('pALM').AsString     := bedAlmacen.Text;
    ParamByName('pCAJA').AsString    := bedCaja.Text;
    ParamByName('pDESDE').AsDateTime := dteDesde.Date;
    ParamByName('pHASTA').AsDateTime := dteHasta.Date;
    Open;
  end;
  fxdsArqueos.UpdateBounds;
end;

end.
