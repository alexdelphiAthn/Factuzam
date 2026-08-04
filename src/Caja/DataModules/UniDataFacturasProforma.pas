{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasProforma                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de documentos generados y empresas disponibles.                 }
{******************************************************************************}
unit UniDataFacturasProforma;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibFacturasProformaIntf;

type
  TdmFacturasProforma = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    procedure ConfigurarConsultas;
  public
    unqryEmpresas: TUniQuery;
    dsEmpresas   : TDataSource;
    procedure AbrirDetalles; override;
    function CrearRepositorio: IRepositorioFacturasProforma;
    procedure RefrescarDocumentos;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  UniDataFacturasProformaRepositorio;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmFacturasProforma.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas := TUniQuery.Create(Self);
  dsEmpresas := TDataSource.Create(Self);
  dsEmpresas.DataSet := unqryEmpresas;
  ConfigurarConsultas;
end;

procedure TdmFacturasProforma.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsEmpresas) then
    dsEmpresas.DataSet := nil;
  if Assigned(unqryEmpresas) and unqryEmpresas.Active then
    unqryEmpresas.Close;
  inherited;
end;

procedure TdmFacturasProforma.ConfigurarConsultas;
begin
  unqryTablaG.SQL.Text :=
    'SELECT CONCAT(''VE-'', P.ID_PROCAJ) AS CLAVE_DOCUMENTO, ' +
    '       ''VE'' AS TIPO_DOCUMENTO, P.SERIE_PROCAJ AS SERIE_DOCUMENTO, ' +
    '       P.ID_FACPER_PROCAJ AS ID_PERIODO, ' +
    '       FP.ESTADO_FACPER AS ESTADO_PERIODO, ' +
    '       P.NUMERO_PROCAJ AS NUMERO_DOCUMENTO, ' +
    '       P.FECHA_PROCAJ AS FECHA_DOCUMENTO, ' +
    '       COALESCE(FP.FECHA_DESDE_FACPER, ' +
    '                P.FECHA_DESDE_PROCAJ) AS FECHA_DESDE, ' +
    '       COALESCE(FP.FECHA_HASTA_FACPER, ' +
    '                P.FECHA_HASTA_PROCAJ) AS FECHA_HASTA, ' +
    '       P.CODIGO_EMP_PROCAJ AS CODIGO_EMPRESA, ' +
    '       E.RAZON_SOCIAL_EMP AS EMPRESA_DESTINO, ' +
    '       P.ESTADO_PROCAJ AS ESTADO_DOCUMENTO, ' +
    '       P.TOTAL_BASE_PROCAJ AS TOTAL_BASE, ' +
    '       P.TOTAL_IMPUESTOS_PROCAJ AS TOTAL_IMPUESTOS, ' +
    '       P.TOTAL_PROCAJ AS TOTAL_DOCUMENTO, ' +
    '       (SELECT COUNT(DISTINCT L.ID_OPCAJA_PROCLIN) ' +
    '          FROM fza_proformas_caja_lineas L ' +
    '         WHERE L.ID_PROCAJ_PROCLIN = P.ID_PROCAJ) ' +
    '         AS CANTIDAD_OPERACIONES ' +
    '  FROM fza_proformas_caja P ' +
    '  LEFT JOIN fza_empresas E ' +
    '    ON E.CODIGO_EMP_EMP = P.CODIGO_EMP_PROCAJ ' +
    '  LEFT JOIN fza_facturacion_caja_periodos FP ' +
    '    ON FP.ID_FACPER = P.ID_FACPER_PROCAJ ' +
    'UNION ALL ' +
    'SELECT CONCAT(''TA-'', MIN(M.ID_FACOP)) AS CLAVE_DOCUMENTO, ' +
    '       ''TA'' AS TIPO_DOCUMENTO, ' +
    '       M.SERIE_FAC_FACOP AS SERIE_DOCUMENTO, ' +
    '       MIN(M.ID_FACPER_FACOP) AS ID_PERIODO, ' +
    '       MIN(FP.ESTADO_FACPER) AS ESTADO_PERIODO, ' +
    '       M.NUMERO_FAC_FACOP AS NUMERO_DOCUMENTO, ' +
    '       F.FECHA_FAC AS FECHA_DOCUMENTO, ' +
    '       COALESCE(MIN(FP.FECHA_DESDE_FACPER), ' +
    '                MIN(DATE(O.FECHA_OPERACION_OPCAJA))) AS FECHA_DESDE, ' +
    '       COALESCE(MAX(FP.FECHA_HASTA_FACPER), ' +
    '                MAX(DATE(O.FECHA_OPERACION_OPCAJA))) AS FECHA_HASTA, ' +
    '       M.CODIGO_EMP_ORIGEN_FACOP AS CODIGO_EMPRESA, ' +
    '       E.RAZON_SOCIAL_EMP AS EMPRESA_DESTINO, ' +
    '       M.ESTADO_FACOP AS ESTADO_DOCUMENTO, ' +
    '       F.TOTAL_BASES_FAC AS TOTAL_BASE, ' +
    '       F.TOTAL_IMPUESTOS_FAC AS TOTAL_IMPUESTOS, ' +
    '       F.TOTAL_LIQUIDO_FAC AS TOTAL_DOCUMENTO, ' +
    '       COUNT(DISTINCT M.ID_OPCAJA_FACOP) AS CANTIDAD_OPERACIONES ' +
    '  FROM fza_facturas_operaciones_caja M ' +
    '  JOIN fza_facturas F ' +
    '    ON F.SERIE_FAC = M.SERIE_FAC_FACOP ' +
    '   AND F.NUMERO_FAC = M.NUMERO_FAC_FACOP ' +
    '  JOIN fza_caja_operaciones O ' +
    '    ON O.ID_OPCAJA = M.ID_OPCAJA_FACOP ' +
    '  LEFT JOIN fza_empresas E ' +
    '    ON E.CODIGO_EMP_EMP = M.CODIGO_EMP_DESTINO_FACOP ' +
    '  LEFT JOIN fza_facturacion_caja_periodos FP ' +
    '    ON FP.ID_FACPER = M.ID_FACPER_FACOP ' +
    ' GROUP BY M.SERIE_FAC_FACOP, M.NUMERO_FAC_FACOP, F.FECHA_FAC, ' +
    '          M.CODIGO_EMP_ORIGEN_FACOP, E.RAZON_SOCIAL_EMP, ' +
    '          M.ESTADO_FACOP, F.TOTAL_BASES_FAC, ' +
    '          F.TOTAL_IMPUESTOS_FAC, F.TOTAL_LIQUIDO_FAC ' +
    ' ORDER BY FECHA_DOCUMENTO DESC, TIPO_DOCUMENTO, ' +
    '          SERIE_DOCUMENTO, NUMERO_DOCUMENTO DESC';
  unqryTablaG.KeyFields := 'CLAVE_DOCUMENTO';
  unqryTablaG.ReadOnly := True;
  unqryEmpresas.SQL.Text :=
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP ' +
    '  FROM fza_empresas ' +
    ' WHERE ESACTIVO_EMP = ''S'' ' +
    ' ORDER BY ORDEN_EMP, RAZON_SOCIAL_EMP';
  unqryEmpresas.ReadOnly := True;
end;

procedure TdmFacturasProforma.AbrirDetalles;
begin
  inherited;
  if not unqryEmpresas.Active then
    unqryEmpresas.Open;
end;

function TdmFacturasProforma.CrearRepositorio:
  IRepositorioFacturasProforma;
begin
  Result := TRepositorioFacturasProformaUniDAC.Create(
    unqryTablaG.Connection);
end;

procedure TdmFacturasProforma.RefrescarDocumentos;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh;
end;

initialization
  RegistrarDataModule(TdmFacturasProforma);
  ForceReferenceToClass(TdmFacturasProforma);
end.
