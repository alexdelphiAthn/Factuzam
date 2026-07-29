{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpOperacionesVenta                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.2.0                                                         }
{   Fecha:       29/07/2026                                                    }
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
  cxCalendar, cxLabel, cxButtons, cxClasses, cxLocalization, cxPC,
  cxCheckListBox, cxCheckBox, dxSkinsForm, dxCore, frxClass, frxDBSet,
  frxDesgn, frxExportXLSX,
  frxExportBaseDialog, frxExportPDF, frxSmartMemo, frLocalization,
  frLanguageSpanish, frxExportBaseImageSettingsDialog, frCoreClasses,
  JvComponentBase, JvEnterTab, Vcl.Menus, System.Actions, Vcl.ActnList;

type
  TfrmPrintOperacionesVenta = class(TfrmPrint)
    pcOpciones: TcxPageControl;
    tsUbicaciones: TcxTabSheet;
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
    lblUbicaciones: TcxLabel;
    clbUbicaciones: TcxCheckListBox;
    btnMarcarTodas: TcxButton;
    btnDesmarcarTodas: TcxButton;
    unqryVentasPrint: TUniQuery;
    dsVentasPrint: TDataSource;
    fxdsVentas: TfrxDBDataset;
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure btnDesmarcarTodasClick(Sender: TObject);
  private
    FAlmacenesUbicacion: TStringList;
    FCajasUbicacion: TStringList;
    FEmpresasUbicacion: TStringList;
    FInicializado: Boolean;
    FRestringido: Boolean;
    procedure AsegurarUbicacionSeleccionada;
    procedure AsignarParametrosUbicaciones(AQuery: TUniQuery);
    procedure CargarUbicaciones;
    function HexAColor(const AHex: string; out AColor: TColor): Boolean;
    function NumeroUbicacionesMarcadas: Integer;
    function SQLFiltroUbicaciones: string;
    function SQLListado(const AFiltroUbicaciones: string): string;
  protected
    procedure DoShow; override;
    procedure ReportBeforePrintConColor(
      Component: TfrxReportComponent);
  public
    procedure AfterReportLoaded; override;
    procedure preparar_consulta; override;
    destructor Destroy; override;
  end;

var
  frmPrintOperacionesVenta: TfrmPrintOperacionesVenta;

implementation

uses
  inLibFiltroUsuario, inLibRectificativas;

{$R *.dfm}

{ TfrmPrintOperacionesVenta }

procedure TfrmPrintOperacionesVenta.AsegurarUbicacionSeleccionada;
var
  i: Integer;
begin
  if not FRestringido then
  begin
    if NumeroUbicacionesMarcadas = 0 then
    begin
      for i := 0 to clbUbicaciones.Items.Count - 1 do
      begin
        if SameText(
             FEmpresasUbicacion[i],
             UbicacionSesion.Empresa) and
           SameText(
             FAlmacenesUbicacion[i],
             UbicacionSesion.Almacen) and
           SameText(
             FCajasUbicacion[i],
             UbicacionSesion.Caja) then
          clbUbicaciones.Items[i].State := cbsChecked;
      end;
    end;
    if (NumeroUbicacionesMarcadas = 0) and
       (clbUbicaciones.Items.Count > 0) then
      clbUbicaciones.Items[0].State := cbsChecked;
  end;
end;

procedure TfrmPrintOperacionesVenta.AsignarParametrosUbicaciones(
  AQuery: TUniQuery);
var
  i: Integer;
  nParametro: Integer;
  nMarcadas: Integer;
  sSufijo: string;
begin
  nMarcadas := NumeroUbicacionesMarcadas;
  if FRestringido or (nMarcadas = 0) then
  begin
    AQuery.ParamByName('pEMPRESA').AsString :=
      UbicacionSesion.Empresa;
    AQuery.ParamByName('pALMACEN').AsString :=
      UbicacionSesion.Almacen;
    AQuery.ParamByName('pCAJA').AsString :=
      UbicacionSesion.Caja;
  end
  else
  begin
    nParametro := 0;
    for i := 0 to clbUbicaciones.Items.Count - 1 do
    begin
      if clbUbicaciones.Items[i].State = cbsChecked then
      begin
        sSufijo := IntToStr(nParametro);
        AQuery.ParamByName('pEMPRESA' + sSufijo).AsString :=
          FEmpresasUbicacion[i];
        AQuery.ParamByName('pALMACEN' + sSufijo).AsString :=
          FAlmacenesUbicacion[i];
        AQuery.ParamByName('pCAJA' + sSufijo).AsString :=
          FCajasUbicacion[i];
        Inc(nParametro);
      end;
    end;
  end;
end;

procedure TfrmPrintOperacionesVenta.AfterReportLoaded;
begin
  inherited;
  frxrprt1.OnBeforePrint := ReportBeforePrintConColor;
end;

procedure TfrmPrintOperacionesVenta.btnDesmarcarTodasClick(
  Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsUnchecked;
end;

procedure TfrmPrintOperacionesVenta.btnMarcarTodasClick(Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsChecked;
end;

procedure TfrmPrintOperacionesVenta.CargarUbicaciones;
var
  item: TcxCheckListBoxItem;
  qry: TUniQuery;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
begin
  if FEmpresasUbicacion = nil then
    FEmpresasUbicacion := TStringList.Create;
  if FAlmacenesUbicacion = nil then
    FAlmacenesUbicacion := TStringList.Create;
  if FCajasUbicacion = nil then
    FCajasUbicacion := TStringList.Create;
  clbUbicaciones.Items.BeginUpdate;
  try
    clbUbicaciones.Items.Clear;
    FEmpresasUbicacion.Clear;
    FAlmacenesUbicacion.Clear;
    FCajasUbicacion.Clear;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'SELECT Empresa, NombreEmpresa, Almacen, ' +
        '       `NombreAlmacén`, Caja, NombreCaja ' +
        '  FROM vi_cajasdef ' +
        ' ORDER BY Empresa, Almacen, Caja';
      qry.Open;
      while not qry.Eof do
      begin
        sEmpresa := qry.FieldByName('Empresa').AsString;
        sAlmacen := qry.FieldByName('Almacen').AsString;
        sCaja := qry.FieldByName('Caja').AsString;
        item := clbUbicaciones.Items.Add;
        item.Text := Format(
          '%s - %s  |  %s - %s  |  %s - %s',
          [
            sEmpresa,
            qry.FieldByName('NombreEmpresa').AsString,
            sAlmacen,
            qry.FieldByName('NombreAlmacén').AsString,
            sCaja,
            qry.FieldByName('NombreCaja').AsString
          ]);
        item.State := cbsUnchecked;
        if SameText(sEmpresa, UbicacionSesion.Empresa) and
           SameText(sAlmacen, UbicacionSesion.Almacen) and
           SameText(sCaja, UbicacionSesion.Caja) then
          item.State := cbsChecked;
        FEmpresasUbicacion.Add(sEmpresa);
        FAlmacenesUbicacion.Add(sAlmacen);
        FCajasUbicacion.Add(sCaja);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  finally
    clbUbicaciones.Items.EndUpdate;
  end;
  AsegurarUbicacionSeleccionada;
end;

destructor TfrmPrintOperacionesVenta.Destroy;
begin
  FreeAndNil(FEmpresasUbicacion);
  FreeAndNil(FAlmacenesUbicacion);
  FreeAndNil(FCajasUbicacion);
  inherited;
end;

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
    FRestringido := RestriccionEmpAlmCajaActiva(
      ContextoSesion,
      ParametrosApp);
    pcOpciones.Visible := not FRestringido;
    tsUbicaciones.TabVisible := not FRestringido;
    if FRestringido then
    begin
      ClientWidth := 341;
      lblContexto.Caption := 'TPV restringido:';
    end
    else
    begin
      ClientWidth := 900;
      pcOpciones.ActivePage := tsUbicaciones;
      CargarUbicaciones;
    end;
    FInicializado := True;
  end;
end;

function TfrmPrintOperacionesVenta.HexAColor(
  const AHex: string;
  out AColor: TColor): Boolean;
var
  nAzul: Integer;
  nRojo: Integer;
  nVerde: Integer;
  sHex: string;
begin
  Result := False;
  sHex := Trim(AHex);
  if Copy(sHex, 1, 1) = '#' then
    Delete(sHex, 1, 1);
  if Length(sHex) = 6 then
  begin
    Result :=
      TryStrToInt('$' + Copy(sHex, 1, 2), nRojo) and
      TryStrToInt('$' + Copy(sHex, 3, 2), nVerde) and
      TryStrToInt('$' + Copy(sHex, 5, 2), nAzul);
    if Result then
      AColor := RGB(nRojo, nVerde, nAzul);
  end;
end;

function TfrmPrintOperacionesVenta.NumeroUbicacionesMarcadas: Integer;
var
  i: Integer;
begin
  Result := 0;
  if clbUbicaciones <> nil then
    for i := 0 to clbUbicaciones.Items.Count - 1 do
      if clbUbicaciones.Items[i].State = cbsChecked then
        Inc(Result);
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
  AsegurarUbicacionSeleccionada;
  unqryVentasPrint.Close;
  unqryVentasPrint.Connection := ConexionPrincipal;
  unqryVentasPrint.SQL.Text := SQLListado(SQLFiltroUbicaciones);
  AsignarParametrosUbicaciones(unqryVentasPrint);
  unqryVentasPrint.ParamByName('pDESDE').AsDateTime :=
    Trunc(dteDesde.Date);
  unqryVentasPrint.ParamByName('pHASTA').AsDateTime :=
    Trunc(dteHasta.Date);
  unqryVentasPrint.Open;
  fxdsVentas.UpdateBounds;
end;

procedure TfrmPrintOperacionesVenta.ReportBeforePrintConColor(
  Component: TfrxReportComponent);
var
  ColorBasico: TColor;
  MemoColorBasico: TfrxMemoView;
begin
  ReportBeforePrintConQR(Component);
  if (Component <> nil) and
     SameText(Component.Name, 'MemoColorBasico') and
     (Component is TfrxMemoView) then
  begin
    MemoColorBasico := TfrxMemoView(Component);
    if HexAColor(
         unqryVentasPrint.FieldByName(
           'HEX_COLOR_BASICO').AsString,
         ColorBasico) then
      MemoColorBasico.Color := ColorBasico
    else
      MemoColorBasico.Color := clWhite;
  end;
end;

function TfrmPrintOperacionesVenta.SQLFiltroUbicaciones: string;
var
  i: Integer;
  nParametro: Integer;
  nMarcadas: Integer;
  sSufijo: string;
begin
  nMarcadas := NumeroUbicacionesMarcadas;
  if FRestringido or (nMarcadas = 0) then
  begin
    Result :=
      '   AND o.CODIGO_EMP_OPCAJA = :pEMPRESA' + sLineBreak +
      '   AND o.CODIGO_ALM_OPCAJA = :pALMACEN' + sLineBreak +
      '   AND o.CODIGO_CAJA_OPCAJA = :pCAJA';
  end
  else
  begin
    Result := '   AND (';
    nParametro := 0;
    for i := 0 to clbUbicaciones.Items.Count - 1 do
    begin
      if clbUbicaciones.Items[i].State = cbsChecked then
      begin
        if nParametro > 0 then
          Result := Result + sLineBreak + '        OR ';
        sSufijo := IntToStr(nParametro);
        Result := Result +
          '(o.CODIGO_EMP_OPCAJA = :pEMPRESA' + sSufijo +
          ' AND o.CODIGO_ALM_OPCAJA = :pALMACEN' + sSufijo +
          ' AND o.CODIGO_CAJA_OPCAJA = :pCAJA' + sSufijo + ')';
        Inc(nParametro);
      end;
    end;
    Result := Result + ')';
  end;
end;

function TfrmPrintOperacionesVenta.SQLListado(
  const AFiltroUbicaciones: string): string;
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
    Anadir('       COALESCE(cb.HEX_COLOR_BASICO, '''')');
    Anadir('         AS HEX_COLOR_BASICO,');
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
    Anadir('    SELECT sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('             AS CODIGO_UNIDAD_SKU,');
    Anadir('           MAX(atb.HEX_ATB) AS HEX_COLOR_BASICO');
    Anadir('      FROM fza_atributos_sku sa');
    Anadir('      JOIN fza_articulos_skus sk');
    Anadir('        ON sk.CODIGO_UNIDAD_SKU =');
    Anadir('           sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('      JOIN fza_atributos_valores av');
    Anadir('        ON av.ID_AV = sa.ID_AV_SA');
    Anadir('       AND av.ID_VA_AV = ''CO''');
    Anadir('      JOIN fza_articulos_atributos_basicos aab');
    Anadir('        ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU');
    Anadir('       AND aab.ID_AV_AAB = av.ID_AV');
    Anadir('      JOIN fza_atributos_basicos atb');
    Anadir('        ON atb.ID_ATB = aab.ID_ATB_AAB');
    Anadir('     GROUP BY sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('  ) cb');
    Anadir('    ON cb.CODIGO_UNIDAD_SKU =');
    Anadir('       fl.CODIGO_UNIDAD_FACLIN');
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
    Anadir(AFiltroUbicaciones);
    Anadir('   AND o.FECHA_OPERACION_OPCAJA >= :pDESDE');
    Anadir('   AND o.FECHA_OPERACION_OPCAJA <');
    Anadir('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
    Anadir(SQLExcluirSimplificadaSustituida(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA'));
    Anadir(' ORDER BY FECHA_DIA, o.CODIGO_EMP_OPCAJA,');
    Anadir('          o.CODIGO_ALM_OPCAJA,');
    Anadir('          o.CODIGO_CAJA_OPCAJA,');
    Anadir('          o.NUMERO_OPERACION_OPCAJA, fl.LINEA_FACLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

end.
