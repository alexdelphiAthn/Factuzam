{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpOperacionesVenta                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Listado de operaciones de venta del TPV, agrupado por fecha y caja.       }
{    Detalla artículos, variantes, importes, vendedor y formas de pago.        }
{******************************************************************************}
unit inMtoModalImpOperacionesVenta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, MemDS, DBAccess, Uni,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, cxButtons, cxClasses, cxLocalization, dxSkinsForm,
  dxCore, frxClass, frxDBSet, frxDesgn, frxExportXLSX,
  frxExportBaseDialog, frxExportPDF, frxSmartMemo, frLocalization,
  frLanguageSpanish, frxExportBaseImageSettingsDialog, frCoreClasses,
  JvComponentBase, JvEnterTab, Vcl.Menus, System.Actions, Vcl.ActnList;

type
  TfrmPrintOperacionesVenta = class(TfrmPrint)
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblContexto: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    edtAlmacen: TcxTextEdit;
    lblCaja: TcxLabel;
    edtCaja: TcxTextEdit;
    unqryVentasPrint: TUniQuery;
    dsVentasPrint: TDataSource;
    fxdsVentas: TfrxDBDataset;
  private
    FInicializado: Boolean;
    function SQLListado: string;
  protected
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintOperacionesVenta: TfrmPrintOperacionesVenta;

implementation

uses
  inLibRectificativas;

{$R *.dfm}

{ TfrmPrintOperacionesVenta }

procedure TfrmPrintOperacionesVenta.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    dteHasta.Date := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    edtAlmacen.Text := UbicacionSesion.Almacen;
    edtCaja.Text := UbicacionSesion.Caja;
    FInicializado := True;
  end;
end;

procedure TfrmPrintOperacionesVenta.preparar_consulta;
begin
  inherited;
  if dteDesde.Date <= 0 then
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
  if dteHasta.Date <= 0 then
    dteHasta.Date := Date;
  if dteHasta.Date < dteDesde.Date then
    dteHasta.Date := dteDesde.Date;
  unqryVentasPrint.Close;
  unqryVentasPrint.Connection := ConexionPrincipal;
  unqryVentasPrint.SQL.Text := SQLListado;
  unqryVentasPrint.ParamByName('pEMPRESA').AsString := edtEmpresa.Text;
  unqryVentasPrint.ParamByName('pALMACEN').AsString := edtAlmacen.Text;
  unqryVentasPrint.ParamByName('pCAJA').AsString := edtCaja.Text;
  unqryVentasPrint.ParamByName('pDESDE').AsDateTime :=
    Trunc(dteDesde.Date);
  unqryVentasPrint.ParamByName('pHASTA').AsDateTime :=
    Trunc(dteHasta.Date);
  unqryVentasPrint.Open;
  fxdsVentas.UpdateBounds;
end;

function TfrmPrintOperacionesVenta.SQLListado: string;
var
  slSQL: TStringList;

  procedure Anadir(const ALinea: string);
  begin
    slSQL.Add(ALinea);
  end;

begin
  slSQL := TStringList.Create;
  try
    Anadir('SELECT DATE(o.FECHA_OPERACION_OPCAJA) AS FECHA_DIA,');
    Anadir('       DATE(:pDESDE) AS FECHA_DESDE,');
    Anadir('       DATE(:pHASTA) AS FECHA_HASTA,');
    Anadir('       o.CODIGO_EMP_OPCAJA,');
    Anadir('       o.CODIGO_ALM_OPCAJA,');
    Anadir('       o.CODIGO_CAJA_OPCAJA,');
    Anadir('       CONCAT(o.CODIGO_EMP_OPCAJA, ''/'',');
    Anadir('              o.CODIGO_ALM_OPCAJA, ''/'',');
    Anadir('              o.CODIGO_CAJA_OPCAJA) AS CLAVE_CAJA,');
    Anadir('       o.NUMERO_OPERACION_OPCAJA,');
    Anadir('       fl.LINEA_FACLIN,');
    Anadir('       fl.CODIGO_ART_FACLIN AS ARTICULO,');
    Anadir('       COALESCE(');
    Anadir('         NULLIF(CASE');
    Anadir('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR1_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR2_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR3_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR4_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR5_VALOR_FACLIN');
    Anadir('           ELSE ''''');
    Anadir('         END, ''''),');
    Anadir('         CASE');
    Anadir('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
    Anadir('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
    Anadir('                               ''/'', '''')) >= 1');
    Anadir('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
    Anadir('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 2),');
    Anadir('                    ''/'', -1)');
    Anadir('           ELSE ''''');
    Anadir('         END, '''') AS COLOR,');
    Anadir('       COALESCE(');
    Anadir('         NULLIF(CASE');
    Anadir('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR1_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR2_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR3_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR4_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR5_VALOR_FACLIN');
    Anadir('           ELSE ''''');
    Anadir('         END, ''''),');
    Anadir('         CASE');
    Anadir('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
    Anadir('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
    Anadir('                               ''/'', '''')) >= 2');
    Anadir('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
    Anadir('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 3),');
    Anadir('                    ''/'', -1)');
    Anadir('           ELSE ''''');
    Anadir('         END, '''') AS TALLA,');
    Anadir('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
    Anadir('                ap.CODIGO_PRV_AP, '''') AS PROVEEDOR,');
    Anadir('       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS MODELO,');
    Anadir('       fl.DESCRIPCION_ARTICULO_FACLIN AS DESCRIPCION,');
    Anadir('       COALESCE(fl.CANTIDAD_FACLIN, 0) AS CANTIDAD,');
    Anadir('       COALESCE(fl.CANTIDAD_FACLIN, 0) *');
    Anadir('       COALESCE(fl.PRECIO_SALIDA_FACLIN,');
    Anadir('                fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, 0)');
    Anadir('         AS BRUTO,');
    Anadir('       COALESCE(fl.PORCENTAJE_DTO_FACLIN, 0)');
    Anadir('         AS PORCENTAJE_DTO,');
    Anadir('       COALESCE(fl.TOTAL_FACLIN, 0) AS NETO_ARTICULO,');
    Anadir('       COALESCE(');
    Anadir('         pg.INGRESOS_OPERACION * fl.TOTAL_FACLIN /');
    Anadir('         NULLIF(o.IMPORTE_TOTAL_OPCAJA, 0), 0) AS INGRESOS,');
    Anadir('       COALESCE(NULLIF(fl.CODIGO_VENDEDOR_FACLIN, ''''),');
    Anadir('                o.CODIGO_EMPLEADO_OPCAJA, '''') AS VENDEDOR,');
    Anadir('       COALESCE(pg.FORMAS_PAGO, '''') AS FORMA_PAGO,');
    Anadir('       CONCAT_WS(''.'', o.CODIGO_EMP_OPCAJA,');
    Anadir('                 o.TIPO_OPERACION_OPCAJA,');
    Anadir('                 o.SERIE_FAC_OPCAJA,');
    Anadir('                 o.NUMERO_FAC_OPCAJA) AS DOCUMENTO');
    Anadir('  FROM fza_caja_operaciones o');
    Anadir('  JOIN fza_facturas_lineas fl');
    Anadir('    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA');
    Anadir('   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA');
    Anadir('   AND fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA');
    Anadir('  LEFT JOIN fza_articulos_proveedores ap');
    Anadir('    ON ap.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
    Anadir('   AND ap.CODIGO_PRV_AP =');
    Anadir('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
    Anadir('         (SELECT apx.CODIGO_PRV_AP');
    Anadir('            FROM fza_articulos_proveedores apx');
    Anadir('           WHERE apx.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
    Anadir('           ORDER BY CASE');
    Anadir('             WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
    Anadir('             THEN 0 ELSE 1');
    Anadir('           END, apx.FECHA_VALIDEZ_AP DESC,');
    Anadir('           apx.CODIGO_PRV_AP');
    Anadir('           LIMIT 1))');
    Anadir('  LEFT JOIN (');
    Anadir('    SELECT p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
    Anadir('           p.CODIGO_CAJA_PAGO, p.NUMERO_OPERACION_PAGO,');
    Anadir('           GROUP_CONCAT(DISTINCT p.CODIGO_FP_CFP');
    Anadir('             ORDER BY p.CODIGO_FP_CFP SEPARATOR '', '')');
    Anadir('             AS FORMAS_PAGO,');
    Anadir('           SUM(p.IMPORTE_ENTREGADO_PAGO -');
    Anadir('               p.IMPORTE_CAMBIO_PAGO) AS INGRESOS_OPERACION');
    Anadir('      FROM fza_caja_pagos p');
    Anadir('     GROUP BY p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
    Anadir('              p.CODIGO_CAJA_PAGO,');
    Anadir('              p.NUMERO_OPERACION_PAGO');
    Anadir('  ) pg');
    Anadir('    ON pg.CODIGO_EMP_PAGO = o.CODIGO_EMP_OPCAJA');
    Anadir('   AND pg.CODIGO_ALM_PAGO = o.CODIGO_ALM_OPCAJA');
    Anadir('   AND pg.CODIGO_CAJA_PAGO = o.CODIGO_CAJA_OPCAJA');
    Anadir('   AND pg.NUMERO_OPERACION_PAGO =');
    Anadir('       o.NUMERO_OPERACION_OPCAJA');
    Anadir(' WHERE o.TIPO_OPERACION_OPCAJA = ''VE''');
    Anadir('   AND o.CODIGO_EMP_OPCAJA = :pEMPRESA');
    Anadir('   AND o.CODIGO_ALM_OPCAJA = :pALMACEN');
    Anadir('   AND o.CODIGO_CAJA_OPCAJA = :pCAJA');
    Anadir('   AND o.FECHA_OPERACION_OPCAJA >= :pDESDE');
    Anadir('   AND o.FECHA_OPERACION_OPCAJA <');
    Anadir('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
    Anadir(SQLExcluirSimplificadaSustituida(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA'));
    Anadir(' ORDER BY FECHA_DIA, o.CODIGO_CAJA_OPCAJA,');
    Anadir('          o.NUMERO_OPERACION_OPCAJA, fl.LINEA_FACLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

end.
