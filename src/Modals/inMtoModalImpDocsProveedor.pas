{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpDocsProveedor                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       20/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion del "Listado de documentos proveedor". Agrupa lineas   }
{    de pedidos, albaranes, facturas y devoluciones de compra por documento,   }
{    con filtros de fechas, almacen destino, temporada, proveedor, familia y   }
{    serie de documento. La temporada se toma solo de cabeceras de pedido o    }
{    de la sesion de compra que genero el documento; no se consulta la ficha   }
{    ni las propiedades del articulo.                                          }
{******************************************************************************}
unit inMtoModalImpDocsProveedor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel,
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses, inLibGlobalVar,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization;

type
  TfrmPrintDocsProveedor = class(TfrmPrintMultiFiltro)
    unqryDocsProveedorPrint: TUniQuery;
    fxdsDocsProveedor: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FclbSeries: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarSeriesDocumento;
    function SQLListado: string;
    function CSVSeries: string;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    function SQLFiltroProveedores: string; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

var
  frmPrintDocsProveedor: TfrmPrintDocsProveedor;

implementation

{$R *.dfm}

{ TfrmPrintDocsProveedor }

function TfrmPrintDocsProveedor.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas];
end;

function TfrmPrintDocsProveedor.SQLFiltroProveedores: string;
begin
  Result :=
    'SELECT p.CODIGO_PRV_PRV AS COD, p.RAZON_SOCIAL_PRV AS NOM ' +
    '  FROM fza_proveedores p ' +
    ' WHERE EXISTS (SELECT 1 FROM fza_pedidos_compra d ' +
    '                WHERE d.CODIGO_PRV_PEDC = p.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_albaranes_compra d ' +
    '                WHERE d.CODIGO_PRV_ALBC = p.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_facturas_compra d ' +
    '                WHERE d.CODIGO_PRV_FACC = p.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_devoluciones_compra d ' +
    '                WHERE d.CODIGO_PRV_DEVC = p.CODIGO_PRV_PRV) ' +
    ' ORDER BY p.RAZON_SOCIAL_PRV, p.CODIGO_PRV_PRV';
end;

procedure TfrmPrintDocsProveedor.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

procedure TfrmPrintDocsProveedor.CrearControlesPropios;
begin
  FclbSeries := CrearTabChecklist('Series doc.');
  CargarSeriesDocumento;
end;

procedure TfrmPrintDocsProveedor.CargarSeriesDocumento;
var
  item: TcxCheckListBoxItem;
  q: TUniQuery;
begin
  if FclbSeries <> nil then
  begin
    FclbSeries.Items.Clear;
    q := TUniQuery.Create(nil);
    try
      q.Connection := oConn;
      q.SQL.Text :=
        'SELECT SERIE AS COD FROM (' +
        ' SELECT SERIE_PEDC AS SERIE FROM fza_pedidos_compra ' +
        ' UNION SELECT SERIE_ALBC FROM fza_albaranes_compra ' +
        ' UNION SELECT SERIE_FACC FROM fza_facturas_compra ' +
        ' UNION SELECT SERIE_DEVC FROM fza_devoluciones_compra) S ' +
        'WHERE COALESCE(SERIE, '''') <> '''' ORDER BY SERIE';
      q.Open;
      while not q.Eof do
      begin
        item := FclbSeries.Items.Add;
        item.Text := q.FieldByName('COD').AsString;
        item.State := cbsUnchecked;
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TfrmPrintDocsProveedor.CSVSeries: string;
begin
  Result := SeleccionadosCSV(FclbSeries);
end;

procedure TfrmPrintDocsProveedor.preparar_consulta;
begin
  inherited;
  with unqryDocsProveedorPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text := SQLListado;
    ParamByName('pDESDE').AsDateTime := FechaDesde;
    ParamByName('pHASTA').AsDateTime := FechaHasta;
    ParamByName('pALM').AsString := CSVAlmacenes;
    ParamByName('pFAM').AsString := CSVFamilias;
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTMP').AsString := CSVTemporadas;
    ParamByName('pSER').AsString := CSVSeries;
    Open;
  end;
  fxdsDocsProveedor.UpdateBounds;
end;

procedure TfrmPrintDocsProveedor.AfterReportLoaded;
begin
  inherited;
  fxdsDocsProveedor.DataSet := unqryDocsProveedorPrint;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsDocsProveedor);
end;

function TfrmPrintDocsProveedor.SQLListado: string;
var
  sl: TStringList;

  procedure Add(const S: string);
  begin
    sl.Add(S);
  end;

begin
  sl := TStringList.Create;
  try
    Add('SELECT D.TIPO_DOC,');
    Add('       D.TIPO_DOC_NOMBRE,');
    Add('       D.ORDEN_TIPO_DOC,');
    Add('       D.CODIGO_PRV,');
    Add('       D.RAZON_SOCIAL_PRV,');
    Add('       D.SERIE_DOC,');
    Add('       D.NUMERO_DOC,');
    Add('       CONCAT(D.SERIE_DOC, ''.'', D.NUMERO_DOC) AS DOCUMENTO_DOC,');
    Add('       D.REF_PROVEEDOR_DOC,');
    Add('       D.FECHA_DOC,');
    Add('       D.ESTADO_DOC,');
    Add('       GROUP_CONCAT(DISTINCT NULLIF(D.CODIGO_ALM, '''')');
    Add('                    SEPARATOR '', '') AS CODIGO_ALM_DOC,');
    Add('       GROUP_CONCAT(DISTINCT D.TEMPORADA');
    Add('                    SEPARATOR '', '') AS TEMPORADA_DOC,');
    Add('       SUM(D.CANTIDAD_DOC) AS CANTIDAD_DOC,');
    Add('       SUM(D.BASE_DOC) AS TOTAL_BASES_DOC,');
    Add('       SUM(D.IVA_DOC) AS TOTAL_IVA_DOC,');
    Add('       SUM(D.RE_DOC) AS TOTAL_RE_DOC,');
    Add('       SUM(D.BASE_DOC + D.IVA_DOC + D.RE_DOC)');
    Add('         AS TOTAL_LIQUIDO_DOC');
    Add('  FROM (');
    Add('  SELECT ''PED'' AS TIPO_DOC,');
    Add('         ''Pedido'' AS TIPO_DOC_NOMBRE,');
    Add('         1 AS ORDEN_TIPO_DOC,');
    Add('         P.CODIGO_PRV_PEDC AS CODIGO_PRV,');
    Add('         COALESCE(NULLIF(P.RAZON_SOCIAL_PRV_PEDC, ''''),');
    Add('                  P.CODIGO_PRV_PEDC) AS RAZON_SOCIAL_PRV,');
    Add('         P.SERIE_PEDC AS SERIE_DOC,');
    Add('         P.NUMERO_PEDC AS NUMERO_DOC,');
    Add('         P.REF_PROVEEDOR_PEDC AS REF_PROVEEDOR_DOC,');
    Add('         P.FECHA_PEDC AS FECHA_DOC,');
    Add('         P.ESTADO_PEDC AS ESTADO_DOC,');
    Add('         COALESCE(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''),');
    Add('                  NULLIF(P.CODIGO_ALM_PEDC, ''''), '''')');
    Add('           AS CODIGO_ALM,');
    Add('         L.CODIGO_FAM_PEDCLIN AS CODIGO_FAM,');
    Add('         COALESCE(TP.PV, TS.PV, '''') AS TEMPORADA,');
    Add('         COALESCE(NULLIF(L.TOTAL_UNIDADES_PEDCLIN, 0),');
    Add('                  L.CANTIDAD_PEDCLIN, 0) AS CANTIDAD_DOC,');
    Add('         COALESCE(L.TOTAL_PEDCLIN, 0) AS BASE_DOC,');
    Add('         COALESCE(L.TOTAL_PEDCLIN, 0)');
    Add('           * COALESCE(L.PORCENTAJE_IVA_PEDCLIN, 0) / 100');
    Add('           AS IVA_DOC,');
    Add('         CASE WHEN IFNULL(P.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S''');
    Add('              THEN CASE IFNULL(L.TIPO_IVA_ARTICULO_PEDCLIN, '''')');
    Add('                   WHEN ''N'' THEN COALESCE(L.TOTAL_PEDCLIN, 0)');
    Add('                     * COALESCE(P.PORCENTAJE_REN_PEDC, 0) / 100');
    Add('                   WHEN ''R'' THEN COALESCE(L.TOTAL_PEDCLIN, 0)');
    Add('                     * COALESCE(P.PORCENTAJE_RER_PEDC, 0) / 100');
    Add('                   WHEN ''S'' THEN COALESCE(L.TOTAL_PEDCLIN, 0)');
    Add('                     * COALESCE(P.PORCENTAJE_RES_PEDC, 0) / 100');
    Add('                   WHEN ''E'' THEN COALESCE(L.TOTAL_PEDCLIN, 0)');
    Add('                     * COALESCE(P.PORCENTAJE_REE_PEDC, 0) / 100');
    Add('                   ELSE 0 END');
    Add('              ELSE 0 END AS RE_DOC');
    Add('    FROM fza_pedidos_compra P');
    Add('    JOIN fza_pedidos_compra_lineas L');
    Add('      ON L.SERIE_PEDC_PEDCLIN = P.SERIE_PEDC');
    Add('     AND L.NUMERO_PEDC_PEDCLIN = P.NUMERO_PEDC');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT DISTINCT TIPO_DOC_SESDOC, SERIE_SESDOC,');
    Add('             NUMERO_SESDOC, SERIE_SES_SESDOC, NUMERO_SES_SESDOC');
    Add('        FROM fza_compras_sesiones_documentos');
    Add('    ) SD');
    Add('      ON SD.TIPO_DOC_SESDOC = ''PEDC''');
    Add('     AND SD.SERIE_SESDOC = P.SERIE_PEDC');
    Add('     AND SD.NUMERO_SESDOC = P.NUMERO_PEDC');
    Add('    LEFT JOIN fza_compras_sesiones S');
    Add('      ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('     AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('    LEFT JOIN fza_propiedades_valores TS');
    Add('      ON TS.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('     AND TS.ID_PROP_PV = ''TEMPORADA''');
    Add('   WHERE P.FECHA_PEDC >= :pDESDE');
    Add('     AND P.FECHA_PEDC <= :pHASTA');
    Add('  UNION ALL');
    Add('  SELECT ''ALB'' AS TIPO_DOC,');
    Add('         ''Albaran'' AS TIPO_DOC_NOMBRE,');
    Add('         2 AS ORDEN_TIPO_DOC,');
    Add('         A.CODIGO_PRV_ALBC AS CODIGO_PRV,');
    Add('         COALESCE(NULLIF(A.RAZON_SOCIAL_PRV_ALBC, ''''),');
    Add('                  A.CODIGO_PRV_ALBC) AS RAZON_SOCIAL_PRV,');
    Add('         A.SERIE_ALBC AS SERIE_DOC,');
    Add('         A.NUMERO_ALBC AS NUMERO_DOC,');
    Add('         A.REF_PROVEEDOR_ALBC AS REF_PROVEEDOR_DOC,');
    Add('         A.FECHA_ALBC AS FECHA_DOC,');
    Add('         A.ESTADO_ALBC AS ESTADO_DOC,');
    Add('         COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''),');
    Add('                  NULLIF(A.CODIGO_ALM_ALBC, ''''), '''')');
    Add('           AS CODIGO_ALM,');
    Add('         L.CODIGO_FAM_ALBCLIN AS CODIGO_FAM,');
    Add('         COALESCE(TP.PV, TS.PV, '''') AS TEMPORADA,');
    Add('         COALESCE(NULLIF(L.TOTAL_UNIDADES_ALBCLIN, 0),');
    Add('                  L.CANTIDAD_ALBCLIN, 0) AS CANTIDAD_DOC,');
    Add('         COALESCE(L.TOTAL_ALBCLIN, 0) AS BASE_DOC,');
    Add('         COALESCE(L.TOTAL_ALBCLIN, 0)');
    Add('           * COALESCE(L.PORCENTAJE_IVA_ALBCLIN, 0) / 100');
    Add('           AS IVA_DOC,');
    Add('         CASE WHEN IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S''');
    Add('              THEN CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, '''')');
    Add('                   WHEN ''N'' THEN COALESCE(L.TOTAL_ALBCLIN, 0)');
    Add('                     * COALESCE(A.PORCENTAJE_REN_ALBC, 0) / 100');
    Add('                   WHEN ''R'' THEN COALESCE(L.TOTAL_ALBCLIN, 0)');
    Add('                     * COALESCE(A.PORCENTAJE_RER_ALBC, 0) / 100');
    Add('                   WHEN ''S'' THEN COALESCE(L.TOTAL_ALBCLIN, 0)');
    Add('                     * COALESCE(A.PORCENTAJE_RES_ALBC, 0) / 100');
    Add('                   WHEN ''E'' THEN COALESCE(L.TOTAL_ALBCLIN, 0)');
    Add('                     * COALESCE(A.PORCENTAJE_REE_ALBC, 0) / 100');
    Add('                   ELSE 0 END');
    Add('              ELSE 0 END AS RE_DOC');
    Add('    FROM fza_albaranes_compra A');
    Add('    JOIN fza_albaranes_compra_lineas L');
    Add('      ON L.SERIE_ALBC_ALBCLIN = A.SERIE_ALBC');
    Add('     AND L.NUMERO_ALBC_ALBCLIN = A.NUMERO_ALBC');
    Add('    LEFT JOIN fza_pedidos_compra P');
    Add('      ON P.SERIE_PEDC = COALESCE(NULLIF(A.SERIE_PED_ALBC, ''''),');
    Add('                             NULLIF(L.SERIE_PEDC_ALBCLIN, ''''))');
    Add('     AND P.NUMERO_PEDC = COALESCE(NULLIF(A.NUMERO_PED_ALBC, ''''),');
    Add('                              NULLIF(L.NUMERO_PEDC_ALBCLIN, ''''))');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT DISTINCT TIPO_DOC_SESDOC, SERIE_SESDOC,');
    Add('             NUMERO_SESDOC, SERIE_SES_SESDOC, NUMERO_SES_SESDOC');
    Add('        FROM fza_compras_sesiones_documentos');
    Add('    ) SD');
    Add('      ON SD.TIPO_DOC_SESDOC = ''ALBC''');
    Add('     AND SD.SERIE_SESDOC = A.SERIE_ALBC');
    Add('     AND SD.NUMERO_SESDOC = A.NUMERO_ALBC');
    Add('    LEFT JOIN fza_compras_sesiones S');
    Add('      ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('     AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('    LEFT JOIN fza_propiedades_valores TS');
    Add('      ON TS.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('     AND TS.ID_PROP_PV = ''TEMPORADA''');
    Add('   WHERE A.FECHA_ALBC >= :pDESDE');
    Add('     AND A.FECHA_ALBC <= :pHASTA');
    Add('  UNION ALL');
    Add('  SELECT ''FAC'' AS TIPO_DOC,');
    Add('         ''Factura'' AS TIPO_DOC_NOMBRE,');
    Add('         3 AS ORDEN_TIPO_DOC,');
    Add('         F.CODIGO_PRV_FACC AS CODIGO_PRV,');
    Add('         COALESCE(NULLIF(F.RAZON_SOCIAL_PRV_FACC, ''''),');
    Add('                  F.CODIGO_PRV_FACC) AS RAZON_SOCIAL_PRV,');
    Add('         F.SERIE_FACC AS SERIE_DOC,');
    Add('         F.NUMERO_FACC AS NUMERO_DOC,');
    Add('         COALESCE(NULLIF(F.DOC_EXTERNO_FACC, ''''),');
    Add('                  F.REF_PROVEEDOR_FACC) AS REF_PROVEEDOR_DOC,');
    Add('         F.FECHA_FACC AS FECHA_DOC,');
    Add('         F.ESTADO_FACC AS ESTADO_DOC,');
    Add('         COALESCE(NULLIF(L.CODIGO_ALMACEN_FACCLIN, ''''),');
    Add('                  NULLIF(F.CODIGO_ALM_FACC, ''''),');
    Add('                  NULLIF(A.CODIGO_ALM_ALBC, ''''), '''')');
    Add('           AS CODIGO_ALM,');
    Add('         L.CODIGO_FAM_FACCLIN AS CODIGO_FAM,');
    Add('         COALESCE(TP.PV, TS.PV, '''') AS TEMPORADA,');
    Add('         COALESCE(NULLIF(L.TOTAL_UNIDADES_FACCLIN, 0),');
    Add('                  L.CANTIDAD_FACCLIN, 0) AS CANTIDAD_DOC,');
    Add('         COALESCE(L.TOTAL_FACCLIN, 0) AS BASE_DOC,');
    Add('         COALESCE(L.TOTAL_FACCLIN, 0)');
    Add('           * COALESCE(L.PORCENTAJE_IVA_FACCLIN, 0) / 100');
    Add('           AS IVA_DOC,');
    Add('         CASE WHEN IFNULL(F.ESIVA_RECARGO_COMPRAS_FACC, ''N'') = ''S''');
    Add('              THEN CASE IFNULL(L.TIPO_IVA_ARTICULO_FACCLIN, '''')');
    Add('                   WHEN ''N'' THEN COALESCE(L.TOTAL_FACCLIN, 0)');
    Add('                     * COALESCE(F.PORCENTAJE_REN_FACC, 0) / 100');
    Add('                   WHEN ''R'' THEN COALESCE(L.TOTAL_FACCLIN, 0)');
    Add('                     * COALESCE(F.PORCENTAJE_RER_FACC, 0) / 100');
    Add('                   WHEN ''S'' THEN COALESCE(L.TOTAL_FACCLIN, 0)');
    Add('                     * COALESCE(F.PORCENTAJE_RES_FACC, 0) / 100');
    Add('                   WHEN ''E'' THEN COALESCE(L.TOTAL_FACCLIN, 0)');
    Add('                     * COALESCE(F.PORCENTAJE_REE_FACC, 0) / 100');
    Add('                   ELSE 0 END');
    Add('              ELSE 0 END AS RE_DOC');
    Add('    FROM fza_facturas_compra F');
    Add('    JOIN fza_facturas_compra_lineas L');
    Add('      ON L.SERIE_FACC_FACCLIN = F.SERIE_FACC');
    Add('     AND L.NUMERO_FACC_FACCLIN = F.NUMERO_FACC');
    Add('    LEFT JOIN fza_albaranes_compra A');
    Add('      ON A.SERIE_ALBC = L.SERIE_ALBC_FACCLIN');
    Add('     AND A.NUMERO_ALBC = L.NUMERO_ALBC_FACCLIN');
    Add('    LEFT JOIN fza_albaranes_compra_lineas AL');
    Add('      ON AL.SERIE_ALBC_ALBCLIN = L.SERIE_ALBC_FACCLIN');
    Add('     AND AL.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_FACCLIN');
    Add('     AND AL.LINEA_ALBCLIN = L.LINEA_ALBC_FACCLIN');
    Add('    LEFT JOIN fza_pedidos_compra P');
    Add('      ON P.SERIE_PEDC = COALESCE(NULLIF(A.SERIE_PED_ALBC, ''''),');
    Add('                             NULLIF(AL.SERIE_PEDC_ALBCLIN, ''''))');
    Add('     AND P.NUMERO_PEDC = COALESCE(NULLIF(A.NUMERO_PED_ALBC, ''''),');
    Add('                              NULLIF(AL.NUMERO_PEDC_ALBCLIN, ''''))');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT DISTINCT TIPO_DOC_SESDOC, SERIE_SESDOC,');
    Add('             NUMERO_SESDOC, SERIE_SES_SESDOC, NUMERO_SES_SESDOC');
    Add('        FROM fza_compras_sesiones_documentos');
    Add('    ) SD');
    Add('      ON SD.TIPO_DOC_SESDOC = ''ALBC''');
    Add('     AND SD.SERIE_SESDOC = A.SERIE_ALBC');
    Add('     AND SD.NUMERO_SESDOC = A.NUMERO_ALBC');
    Add('    LEFT JOIN fza_compras_sesiones S');
    Add('      ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('     AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('    LEFT JOIN fza_propiedades_valores TS');
    Add('      ON TS.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('     AND TS.ID_PROP_PV = ''TEMPORADA''');
    Add('   WHERE F.FECHA_FACC >= :pDESDE');
    Add('     AND F.FECHA_FACC <= :pHASTA');
    Add('  UNION ALL');
    Add('  SELECT ''DEV'' AS TIPO_DOC,');
    Add('         ''Devolucion'' AS TIPO_DOC_NOMBRE,');
    Add('         4 AS ORDEN_TIPO_DOC,');
    Add('         V.CODIGO_PRV_DEVC AS CODIGO_PRV,');
    Add('         COALESCE(NULLIF(V.RAZON_SOCIAL_PRV_DEVC, ''''),');
    Add('                  V.CODIGO_PRV_DEVC) AS RAZON_SOCIAL_PRV,');
    Add('         V.SERIE_DEVC AS SERIE_DOC,');
    Add('         V.NUMERO_DEVC AS NUMERO_DOC,');
    Add('         V.REF_PROVEEDOR_DEVC AS REF_PROVEEDOR_DOC,');
    Add('         V.FECHA_DEVC AS FECHA_DOC,');
    Add('         V.ESTADO_DEVC AS ESTADO_DOC,');
    Add('         COALESCE(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''),');
    Add('                  NULLIF(V.CODIGO_ALM_DEVC, ''''), '''')');
    Add('           AS CODIGO_ALM,');
    Add('         L.CODIGO_FAM_DEVCLIN AS CODIGO_FAM,');
    Add('         COALESCE(TP.PV, TS.PV, '''') AS TEMPORADA,');
    Add('         -COALESCE(NULLIF(L.TOTAL_UNIDADES_DEVCLIN, 0),');
    Add('                   L.CANTIDAD_DEVCLIN, 0) AS CANTIDAD_DOC,');
    Add('         -COALESCE(L.TOTAL_DEVCLIN, 0) AS BASE_DOC,');
    Add('         -COALESCE(L.TOTAL_DEVCLIN, 0)');
    Add('           * COALESCE(L.PORCENTAJE_IVA_DEVCLIN, 0) / 100');
    Add('           AS IVA_DOC,');
    Add('         CASE WHEN IFNULL(V.ESIVA_RECARGO_COMPRAS_DEVC, ''N'') = ''S''');
    Add('              THEN CASE IFNULL(L.TIPO_IVA_ARTICULO_DEVCLIN, '''')');
    Add('                   WHEN ''N'' THEN -COALESCE(L.TOTAL_DEVCLIN, 0)');
    Add('                     * COALESCE(V.PORCENTAJE_REN_DEVC, 0) / 100');
    Add('                   WHEN ''R'' THEN -COALESCE(L.TOTAL_DEVCLIN, 0)');
    Add('                     * COALESCE(V.PORCENTAJE_RER_DEVC, 0) / 100');
    Add('                   WHEN ''S'' THEN -COALESCE(L.TOTAL_DEVCLIN, 0)');
    Add('                     * COALESCE(V.PORCENTAJE_RES_DEVC, 0) / 100');
    Add('                   WHEN ''E'' THEN -COALESCE(L.TOTAL_DEVCLIN, 0)');
    Add('                     * COALESCE(V.PORCENTAJE_REE_DEVC, 0) / 100');
    Add('                   ELSE 0 END');
    Add('              ELSE 0 END AS RE_DOC');
    Add('    FROM fza_devoluciones_compra V');
    Add('    JOIN fza_devoluciones_compra_lineas L');
    Add('      ON L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC');
    Add('     AND L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC');
    Add('    LEFT JOIN fza_pedidos_compra P');
    Add('      ON P.SERIE_PEDC = COALESCE(NULLIF(V.SERIE_PED_DEVC, ''''),');
    Add('                             NULLIF(L.SERIE_PEDC_DEVCLIN, ''''))');
    Add('     AND P.NUMERO_PEDC = COALESCE(NULLIF(V.NUMERO_PED_DEVC, ''''),');
    Add('                              NULLIF(L.NUMERO_PEDC_DEVCLIN, ''''))');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT DISTINCT TIPO_DOC_SESDOC, SERIE_SESDOC,');
    Add('             NUMERO_SESDOC, SERIE_SES_SESDOC, NUMERO_SES_SESDOC');
    Add('        FROM fza_compras_sesiones_documentos');
    Add('    ) SD');
    Add('      ON SD.TIPO_DOC_SESDOC = ''DEVC''');
    Add('     AND SD.SERIE_SESDOC = V.SERIE_DEVC');
    Add('     AND SD.NUMERO_SESDOC = V.NUMERO_DEVC');
    Add('    LEFT JOIN fza_compras_sesiones S');
    Add('      ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('     AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('    LEFT JOIN fza_propiedades_valores TS');
    Add('      ON TS.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('     AND TS.ID_PROP_PV = ''TEMPORADA''');
    Add('   WHERE V.FECHA_DEVC >= :pDESDE');
    Add('     AND V.FECHA_DEVC <= :pHASTA');
    Add('       ) D');
    Add(' WHERE D.TEMPORADA <> ''''');
    Add('   AND (:pSER = '''' OR FIND_IN_SET(D.SERIE_DOC, :pSER))');
    Add('   AND (:pALM = '''' OR FIND_IN_SET(D.CODIGO_ALM, :pALM))');
    Add('   AND (:pFAM = '''' OR FIND_IN_SET(D.CODIGO_FAM, :pFAM))');
    Add('   AND (:pPRV = '''' OR FIND_IN_SET(D.CODIGO_PRV, :pPRV))');
    Add('   AND (:pTMP = '''' OR FIND_IN_SET(D.TEMPORADA, :pTMP))');
    Add(' GROUP BY D.TIPO_DOC,');
    Add('          D.TIPO_DOC_NOMBRE,');
    Add('          D.ORDEN_TIPO_DOC,');
    Add('          D.CODIGO_PRV,');
    Add('          D.RAZON_SOCIAL_PRV,');
    Add('          D.SERIE_DOC,');
    Add('          D.NUMERO_DOC,');
    Add('          D.REF_PROVEEDOR_DOC,');
    Add('          D.FECHA_DOC,');
    Add('          D.ESTADO_DOC');
    Add(' ORDER BY D.RAZON_SOCIAL_PRV,');
    Add('          D.CODIGO_PRV,');
    Add('          D.FECHA_DOC,');
    Add('          D.ORDEN_TIPO_DOC,');
    Add('          D.SERIE_DOC,');
    Add('          D.NUMERO_DOC');
    Result := sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

end.
