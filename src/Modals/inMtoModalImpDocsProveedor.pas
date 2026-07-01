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
{    Modal de impresion del "Listado de documentos proveedor". Lista           }
{    cabeceras de pedidos, albaranes, facturas y devoluciones de compra,       }
{    con filtros de fechas, almacen destino, temporada, proveedor, tipo y      }
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
    FclbTipos: TcxCheckListBox;
    FclbSeries: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarTiposDocumento;
    procedure CargarSeriesDocumento;
    function SQLListado: string;
    function CSVTipos: string;
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
  Result := [frFechas, frAlmacenes, frProveedores, frTemporadas];
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
  FclbTipos := CrearTabChecklist('Tipos doc.');
  CargarTiposDocumento;
  FclbSeries := CrearTabChecklist('Series doc.');
  CargarSeriesDocumento;
end;

procedure TfrmPrintDocsProveedor.CargarTiposDocumento;

  procedure Agregar(const ACod, AEtiq: string);
  var
    item: TcxCheckListBoxItem;
  begin
    item := FclbTipos.Items.Add;
    item.Text := ACod + ' - ' + AEtiq;
    item.State := cbsUnchecked;
  end;

begin
  if FclbTipos <> nil then
  begin
    FclbTipos.Items.Clear;
    Agregar('PED', 'Pedidos');
    Agregar('ALB', 'Albaranes');
    Agregar('FAC', 'Facturas');
    Agregar('DEV', 'Devoluciones');
  end;
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

function TfrmPrintDocsProveedor.CSVTipos: string;
begin
  Result := SeleccionadosCSV(FclbTipos);
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
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTMP').AsString := CSVTemporadas;
    ParamByName('pTIP').AsString := CSVTipos;
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
    Add('       D.CODIGO_ALM AS CODIGO_ALM_DOC,');
    Add('       D.TEMPORADA AS TEMPORADA_DOC,');
    Add('       D.CANTIDAD_DOC,');
    Add('       D.BASE_DOC AS TOTAL_BASES_DOC,');
    Add('       D.IVA_DOC AS TOTAL_IVA_DOC,');
    Add('       D.RE_DOC AS TOTAL_RE_DOC,');
    Add('       D.LIQUIDO_DOC AS TOTAL_LIQUIDO_DOC');
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
    Add('         COALESCE(NULLIF(P.CODIGO_ALM_PEDC, ''''), '''') AS CODIGO_ALM,');
    Add('         COALESCE(TP.PV, SDT.TEMPORADA, '''') AS TEMPORADA,');
    Add('         COALESCE(CAST(NULLIF(P.CONTADOR_LINEAS_PEDC, '''')');
    Add('                  AS DECIMAL(18,6)), 0) / 10 AS CANTIDAD_DOC,');
    Add('         COALESCE(P.TOTAL_BASES_PEDC, 0) AS BASE_DOC,');
    Add('         COALESCE(P.TOTAL_IVAN_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_IVAR_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_IVAS_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_IVAE_PEDC, 0) AS IVA_DOC,');
    Add('         COALESCE(P.TOTAL_REN_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_RER_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_RES_PEDC, 0)');
    Add('           + COALESCE(P.TOTAL_REE_PEDC, 0) AS RE_DOC,');
    Add('         COALESCE(P.TOTAL_LIQUIDO_PEDC, 0) AS LIQUIDO_DOC');
    Add('    FROM fza_pedidos_compra P');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Add('             SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Add('        FROM fza_compras_sesiones_documentos SD');
    Add('        JOIN fza_compras_sesiones S');
    Add('          ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('         AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('        LEFT JOIN fza_propiedades_valores T');
    Add('          ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('         AND T.ID_PROP_PV = ''TEMPORADA''');
    Add('       GROUP BY SD.TIPO_DOC_SESDOC,');
    Add('                SD.SERIE_SESDOC,');
    Add('                SD.NUMERO_SESDOC');
    Add('    ) SDT');
    Add('      ON SDT.TIPO_DOC_SESDOC = ''PEDC''');
    Add('     AND SDT.SERIE_SESDOC = P.SERIE_PEDC');
    Add('     AND SDT.NUMERO_SESDOC = P.NUMERO_PEDC');
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
    Add('         COALESCE(NULLIF(A.CODIGO_ALM_ALBC, ''''), '''') AS CODIGO_ALM,');
    Add('         COALESCE(TP.PV, SDT.TEMPORADA, '''') AS TEMPORADA,');
    Add('         COALESCE(CAST(NULLIF(A.CONTADOR_LINEAS_ALBC, '''')');
    Add('                  AS DECIMAL(18,6)), 0) / 10 AS CANTIDAD_DOC,');
    Add('         COALESCE(A.TOTAL_BASES_ALBC, 0) AS BASE_DOC,');
    Add('         COALESCE(A.TOTAL_IVAN_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_IVAR_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_IVAS_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_IVAE_ALBC, 0) AS IVA_DOC,');
    Add('         COALESCE(A.TOTAL_REN_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_RER_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_RES_ALBC, 0)');
    Add('           + COALESCE(A.TOTAL_REE_ALBC, 0) AS RE_DOC,');
    Add('         COALESCE(A.TOTAL_LIQUIDO_ALBC, 0) AS LIQUIDO_DOC');
    Add('    FROM fza_albaranes_compra A');
    Add('    LEFT JOIN fza_pedidos_compra P');
    Add('      ON P.SERIE_PEDC = A.SERIE_PED_ALBC');
    Add('     AND P.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Add('             SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Add('        FROM fza_compras_sesiones_documentos SD');
    Add('        JOIN fza_compras_sesiones S');
    Add('          ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('         AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('        LEFT JOIN fza_propiedades_valores T');
    Add('          ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('         AND T.ID_PROP_PV = ''TEMPORADA''');
    Add('       GROUP BY SD.TIPO_DOC_SESDOC,');
    Add('                SD.SERIE_SESDOC,');
    Add('                SD.NUMERO_SESDOC');
    Add('    ) SDT');
    Add('      ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Add('     AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Add('     AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
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
    Add('         COALESCE(NULLIF(F.CODIGO_ALM_FACC, ''''), '''') AS CODIGO_ALM,');
    Add('         COALESCE(TF.PV, FT.TEMPORADA, '''') AS TEMPORADA,');
    Add('         COALESCE(CAST(NULLIF(F.CONTADOR_LINEAS_FACC, '''')');
    Add('                  AS DECIMAL(18,6)), 0) / 10 AS CANTIDAD_DOC,');
    Add('         COALESCE(F.TOTAL_BASES_FACC, 0) AS BASE_DOC,');
    Add('         COALESCE(F.TOTAL_IVAN_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_IVAR_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_IVAS_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_IVAE_FACC, 0) AS IVA_DOC,');
    Add('         COALESCE(F.TOTAL_REN_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_RER_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_RES_FACC, 0)');
    Add('           + COALESCE(F.TOTAL_REE_FACC, 0) AS RE_DOC,');
    Add('         COALESCE(F.TOTAL_LIQUIDO_FACC, 0) AS LIQUIDO_DOC');
    Add('    FROM fza_facturas_compra F');
    Add('    LEFT JOIN fza_propiedades_valores TF');
    Add('      ON TF.ID_PV_ARTPROP = F.ID_PV_TEMPORADA_FACC');
    Add('     AND TF.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT A.SERIE_FAC_ALBC, A.NUMERO_FAC_ALBC,');
    Add('             MAX(COALESCE(TP.PV, SDT.TEMPORADA)) AS TEMPORADA');
    Add('        FROM fza_albaranes_compra A');
    Add('        LEFT JOIN fza_pedidos_compra P');
    Add('          ON P.SERIE_PEDC = A.SERIE_PED_ALBC');
    Add('         AND P.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Add('        LEFT JOIN fza_propiedades_valores TP');
    Add('          ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('         AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('        LEFT JOIN (');
    Add('          SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Add('                 SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Add('            FROM fza_compras_sesiones_documentos SD');
    Add('            JOIN fza_compras_sesiones S');
    Add('              ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('             AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('            LEFT JOIN fza_propiedades_valores T');
    Add('              ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('             AND T.ID_PROP_PV = ''TEMPORADA''');
    Add('           GROUP BY SD.TIPO_DOC_SESDOC,');
    Add('                    SD.SERIE_SESDOC,');
    Add('                    SD.NUMERO_SESDOC');
    Add('        ) SDT');
    Add('          ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Add('         AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Add('         AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
    Add('       WHERE IFNULL(A.SERIE_FAC_ALBC, '''') <> ''''');
    Add('         AND IFNULL(A.NUMERO_FAC_ALBC, '''') <> ''''');
    Add('       GROUP BY A.SERIE_FAC_ALBC,');
    Add('                A.NUMERO_FAC_ALBC');
    Add('    ) FT');
    Add('      ON FT.SERIE_FAC_ALBC = F.SERIE_FACC');
    Add('     AND FT.NUMERO_FAC_ALBC = F.NUMERO_FACC');
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
    Add('         COALESCE(NULLIF(V.CODIGO_ALM_DEVC, ''''), '''') AS CODIGO_ALM,');
    Add('         COALESCE(TP.PV, FT.TEMPORADA, '''') AS TEMPORADA,');
    Add('         -COALESCE(CAST(NULLIF(V.CONTADOR_LINEAS_DEVC, '''')');
    Add('                   AS DECIMAL(18,6)), 0) / 10 AS CANTIDAD_DOC,');
    Add('         -COALESCE(V.TOTAL_BASES_DEVC, 0) AS BASE_DOC,');
    Add('         -(COALESCE(V.TOTAL_IVAN_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_IVAR_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_IVAS_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_IVAE_DEVC, 0)) AS IVA_DOC,');
    Add('         -(COALESCE(V.TOTAL_REN_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_RER_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_RES_DEVC, 0)');
    Add('           + COALESCE(V.TOTAL_REE_DEVC, 0)) AS RE_DOC,');
    Add('         -COALESCE(V.TOTAL_LIQUIDO_DEVC, 0) AS LIQUIDO_DOC');
    Add('    FROM fza_devoluciones_compra V');
    Add('    LEFT JOIN fza_pedidos_compra P');
    Add('      ON P.SERIE_PEDC = V.SERIE_PED_DEVC');
    Add('     AND P.NUMERO_PEDC = V.NUMERO_PED_DEVC');
    Add('    LEFT JOIN fza_propiedades_valores TP');
    Add('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Add('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Add('    LEFT JOIN (');
    Add('      SELECT A.SERIE_FAC_ALBC, A.NUMERO_FAC_ALBC,');
    Add('             MAX(COALESCE(TPA.PV, SDT.TEMPORADA)) AS TEMPORADA');
    Add('        FROM fza_albaranes_compra A');
    Add('        LEFT JOIN fza_pedidos_compra PA');
    Add('          ON PA.SERIE_PEDC = A.SERIE_PED_ALBC');
    Add('         AND PA.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Add('        LEFT JOIN fza_propiedades_valores TPA');
    Add('          ON TPA.ID_PV_ARTPROP = PA.ID_PV_TEMPORADA_PEDC');
    Add('         AND TPA.ID_PROP_PV = ''TEMPORADA''');
    Add('        LEFT JOIN (');
    Add('          SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Add('                 SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Add('            FROM fza_compras_sesiones_documentos SD');
    Add('            JOIN fza_compras_sesiones S');
    Add('              ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Add('             AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Add('            LEFT JOIN fza_propiedades_valores T');
    Add('              ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Add('             AND T.ID_PROP_PV = ''TEMPORADA''');
    Add('           GROUP BY SD.TIPO_DOC_SESDOC,');
    Add('                    SD.SERIE_SESDOC,');
    Add('                    SD.NUMERO_SESDOC');
    Add('        ) SDT');
    Add('          ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Add('         AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Add('         AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
    Add('       WHERE IFNULL(A.SERIE_FAC_ALBC, '''') <> ''''');
    Add('         AND IFNULL(A.NUMERO_FAC_ALBC, '''') <> ''''');
    Add('       GROUP BY A.SERIE_FAC_ALBC,');
    Add('                A.NUMERO_FAC_ALBC');
    Add('    ) FT');
    Add('      ON FT.SERIE_FAC_ALBC = V.SERIE_FAC_DEVC');
    Add('     AND FT.NUMERO_FAC_ALBC = V.NUMERO_FAC_DEVC');
    Add('   WHERE V.FECHA_DEVC >= :pDESDE');
    Add('     AND V.FECHA_DEVC <= :pHASTA');
    Add('       ) D');
    Add(' WHERE D.TEMPORADA <> ''''');
    Add('   AND (:pTIP = '''' OR FIND_IN_SET(D.TIPO_DOC, :pTIP))');
    Add('   AND (:pSER = '''' OR FIND_IN_SET(D.SERIE_DOC, :pSER))');
    Add('   AND (:pALM = '''' OR FIND_IN_SET(D.CODIGO_ALM, :pALM))');
    Add('   AND (:pPRV = '''' OR FIND_IN_SET(D.CODIGO_PRV, :pPRV))');
    Add('   AND (:pTMP = '''' OR FIND_IN_SET(D.TEMPORADA, :pTMP))');
    Add(' ORDER BY D.ORDEN_TIPO_DOC,');
    Add('          D.TIPO_DOC,');
    Add('          D.RAZON_SOCIAL_PRV,');
    Add('          D.CODIGO_PRV,');
    Add('          D.FECHA_DOC,');
    Add('          D.SERIE_DOC,');
    Add('          D.NUMERO_DOC');
    Result := sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

end.
