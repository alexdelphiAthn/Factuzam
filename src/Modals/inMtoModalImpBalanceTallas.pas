{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpBalanceTallas                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Balance de almacén por tallas" (FastReport).      }
{    Informe A4 horizontal con la foto del artículo, agrupado por familia y    }
{    artículo, con las tallas como columnas y los colores/estados como         }
{    bandas. Se apoya en el SP PRC_GET_BALANCE_ALMACEN_TALLAS (ver             }
{    DESARROLLOS EN CURSO/balance_almacen_tallas.sql).                         }
{                                                                              }
{    Dos modos: entre fechas (con nivel simplificado / desglosado) o por       }
{    acumulados. El usuario filtra además por almacén y familia.               }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo.        }
{******************************************************************************}
unit inMtoModalImpBalanceTallas;

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
  cxDateUtils, cxRadioGroup, Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm,
  cxClasses, cxLocalization, JvComponentBase, JvEnterTab, System.Actions,
  Vcl.ActnList, frxSmartMemo, frLocalization, frLanguageSpanish,
  frxExportBaseImageSettingsDialog, frCoreClasses, inLibGlobalVar;

type
  TfrmPrintBalanceTallas = class(TfrmPrint)
    unqryBalancePrint: TUniQuery;
    dsBalancePrint: TDataSource;
    fxdsBalance: TfrxDBDataset;
    rgModo: TcxRadioGroup;
    rgDetalle: TcxRadioGroup;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblAlmacen: TcxLabel;
    bedAlmacen: TcxButtonEdit;
    lblFamilia: TcxLabel;
    bedFamilia: TcxButtonEdit;
    procedure rgModoPropertiesEditValueChanged(Sender: TObject);
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedFamiliaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    // Fija los valores por defecto una sola vez al abrir; evita pisarlos en
    // el ciclo Hide/Show que hacen los botones del padre (Imprimir/PDF...).
    FInicializado: Boolean;
    // Habilita/inhabilita fechas y nivel de detalle según el modo (las
    // fechas y el desglosado solo aplican a "Entre fechas").
    procedure ActualizarHabilitacion;
  protected
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintBalanceTallas: TfrmPrintBalanceTallas;

implementation

{$R *.dfm}

uses
  System.StrUtils, inLibAppParam, inLibGenBusq;

{ TfrmPrintBalanceTallas }

procedure TfrmPrintBalanceTallas.DoShow;
begin
  inherited;
  // Por defecto: entre fechas, simplificado, del primer día del mes en curso
  // hasta hoy, todos los almacenes y todas las familias.
  if not FInicializado then
  begin
    dteDesde.Date       := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date       := Date;
    rgModo.ItemIndex    := 0;
    rgDetalle.ItemIndex := 0;
    FInicializado       := True;
    ActualizarHabilitacion;
  end;
end;

procedure TfrmPrintBalanceTallas.ActualizarHabilitacion;
var
  bFechas: Boolean;
begin
  bFechas := rgModo.ItemIndex = 0;
  dteDesde.Enabled  := bFechas;
  dteHasta.Enabled  := bFechas;
  rgDetalle.Enabled := bFechas;
end;

procedure TfrmPrintBalanceTallas.rgModoPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarHabilitacion;
end;

procedure TfrmPrintBalanceTallas.bedAlmacenPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  q: TUniQuery;
begin
  // Selección de un almacén activo. Vacío = todos (el SP usa todos los
  // almacenes estándar cuando el parámetro llega vacío).
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    q.Open;
    if TBusquedaUtils.EjecutarBusqueda('Selección de almacén', q,
                                       'frmBalanceTallasAlmSearch') then
      bedAlmacen.Text := q.FieldByName('CODIGO_ALM_ALM').AsString;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPrintBalanceTallas.bedFamiliaPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  q: TUniQuery;
begin
  // Selección de una familia. Vacío = todas.
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT CODIGO_FAM_FAM, DESCRIPCION_FAM ' +
      '  FROM fza_articulos_familias ' +
      ' WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
      ' ORDER BY ORDEN_FAM, CODIGO_FAM_FAM';
    q.Open;
    if TBusquedaUtils.EjecutarBusqueda('Selección de familia', q,
                                       'frmBalanceTallasFamSearch') then
      bedFamilia.Text := q.FieldByName('CODIGO_FAM_FAM').AsString;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPrintBalanceTallas.preparar_consulta;
begin
  inherited;
  // Llamada al SP que devuelve el balance ya pivotado por talla y
  // desdoblado en bandas. La tarifa de valoración de salidas/ventas es la
  // tarifa por defecto del entorno.
  with unqryBalancePrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      'CALL PRC_GET_BALANCE_ALMACEN_TALLAS(' +
      ':pMODO, :pDESDE, :pHASTA, :pALM, :pFAM, :pTAR, :pDESG)';
    if rgModo.ItemIndex = 0 then
      ParamByName('pMODO').AsString := 'F'
    else
      ParamByName('pMODO').AsString := 'A';
    ParamByName('pDESDE').AsDateTime := dteDesde.Date;
    ParamByName('pHASTA').AsDateTime := dteHasta.Date;
    ParamByName('pALM').AsString     := Trim(bedAlmacen.Text);
    ParamByName('pFAM').AsString     := Trim(bedFamilia.Text);
    ParamByName('pTAR').AsString     :=
      oAppParams.GetString('appTarifaDefecto', 'PVP');
    if (rgModo.ItemIndex = 0) and (rgDetalle.ItemIndex = 1) then
      ParamByName('pDESG').AsString := 'S'
    else
      ParamByName('pDESG').AsString := 'N';
    Open;
  end;
  fxdsBalance.UpdateBounds;
end;

end.
