{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspasoTicketRepositorio                             }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas de solicitudes y traspasos utilizadas por los tickets de caja.  }
{******************************************************************************}
unit UniDataTraspasoTicketRepositorio;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni,
  inLibTraspasoTicketIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioTraspasoTicket = class(
    TInterfacedObject,
    IRepositorioTraspasoTicket)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ObtenerSolicitud(
      const ANumero, ASerie: string):
      TSolicitudTraspasoTicket;
    function ListarLineasSolicitud(
      const ANumero, ASerie, AOrigen, ADestino: string):
      TArray<TLineaSolicitudTraspasoTicket>;
    function ObtenerStock(
      const AAlmacen, ASku: string): Double;
    function ObtenerTraspasoHistorico(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TTraspasoTicketHistorico;
    function ListarLineasTraspaso(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TArray<TLineaTraspasoTicket>;
  end;

implementation

uses
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

const
  SQL_SOLICITUD =
    'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL, ' +
    'CODIGO_EMPLEADO_TRSOL, ESTADO_TRSOL, FECHA_TRSOL ' +
    'FROM fza_traspasos_solicitudes ' +
    'WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  SQL_LINEAS_SOLICITUD =
    'SELECT L.CODIGO_UNIDAD_TRSOLLIN AS SKU, ' +
    'COALESCE(L.DESCRIPCION_ARTICULO_TRSOLLIN, '''') AS DESCRIPCION, ' +
    'L.CANTIDAD_PEDIDA_TRSOLLIN AS PED, ' +
    '(SELECT COALESCE(SUM(S.CANTIDAD_STK),0) ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :ORI ' +
    'AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN) AS STK_ORI, ' +
    '(SELECT COALESCE(SUM(S.CANTIDAD_STK),0) ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :DES ' +
    'AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN) AS STK_DES ' +
    'FROM fza_traspasos_solicitudes_lineas L ' +
    'WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM ' +
    'AND L.SERIE_TRSOL_TRSOLLIN = :SER ORDER BY L.LINEA_TRSOLLIN';
  SQL_STOCK =
    'SELECT COALESCE(SUM(S.CANTIDAD_STK),0) AS STOCK ' +
    'FROM fza_articulos_stockactual S ' +
    'WHERE S.CODIGO_ALM_STK = :ALM AND S.CODIGO_UNIDAD_STK = :SKU';
  SQL_TRASPASO_HISTORICO =
    'SELECT o.SERIE_FAC_OPCAJA, o.NUMERO_FAC_OPCAJA, ' +
    'o.CODIGO_ALM_OPCAJA, o.CODIGO_ALM_CONTRA_OPCAJA, ' +
    'o.CODIGO_EMPLEADO_OPCAJA, ' +
    'COALESCE(e.FORMATO_DOCUMENTO_EMP, ''Serie.NroDocumento'') ' +
    'AS FORMATO_DOCUMENTO_EMP FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_empresas e ' +
    'ON e.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :ALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    'AND o.NUMERO_OPERACION_OPCAJA = :NUMOP';
  SQL_LINEAS_TRASPASO =
    'SELECT CODIGO_UNIDAD_MOV, CANTIDAD_MOV, ' +
    'COALESCE(DESCRIPCION_ARTICULO_MOV, '''') AS DESCRIPCION ' +
    'FROM fza_movimientos_almacen ' +
    'WHERE CODIGO_EMP_MOV = :EMP AND CODIGO_ALM_DOC_MOV = :ALM ' +
    'AND CODIGO_CAJA_DOC_MOV = :CAJA ' +
    'AND NUMERO_OPERACION_DOC_MOV = :NUMOP AND TIPO_MOV = ''S'' ' +
    'ORDER BY LINEA_MOV';

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioTraspasoTicket',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TRepositorioTraspasoTicket.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioTraspasoTicket.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 5);
  Result[0] := DefinicionSql(
    'ObtenerSolicitud',
    SQL_SOLICITUD,
    'NUM,SER',
    'CODIGO_ALM_ORIGEN_TRSOL,CODIGO_ALM_DESTINO_TRSOL,' +
    'CODIGO_EMPLEADO_TRSOL,ESTADO_TRSOL,FECHA_TRSOL');
  Result[1] := DefinicionSql(
    'ListarLineasSolicitud',
    SQL_LINEAS_SOLICITUD,
    'ORI,DES,NUM,SER',
    'SKU,DESCRIPCION,PED,STK_ORI,STK_DES');
  Result[2] := DefinicionSql(
    'ObtenerStock',
    SQL_STOCK,
    'ALM,SKU',
    'STOCK');
  Result[3] := DefinicionSql(
    'ObtenerTraspasoHistorico',
    SQL_TRASPASO_HISTORICO,
    'EMP,ALM,CAJA,NUMOP',
    'SERIE_FAC_OPCAJA,NUMERO_FAC_OPCAJA,CODIGO_ALM_OPCAJA,' +
    'CODIGO_ALM_CONTRA_OPCAJA,CODIGO_EMPLEADO_OPCAJA,' +
    'FORMATO_DOCUMENTO_EMP');
  Result[4] := DefinicionSql(
    'ListarLineasTraspaso',
    SQL_LINEAS_TRASPASO,
    'EMP,ALM,CAJA,NUMOP',
    'CODIGO_UNIDAD_MOV,CANTIDAD_MOV,DESCRIPCION');
end;

function TRepositorioTraspasoTicket.ObtenerSolicitud(
  const ANumero, ASerie: string):
  TSolicitudTraspasoTicket;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := Default(TSolicitudTraspasoTicket);
  oDefinicion := DefinicionesSql[0];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('NUM').AsString := ANumero;
        oQuery.ParamByName('SER').AsString := ASerie;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result.Existe := not oQuery.IsEmpty;
    if Result.Existe then
    begin
      Result.Origen :=
        oQuery.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      Result.Destino :=
        oQuery.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
      Result.Empleado :=
        oQuery.FieldByName('CODIGO_EMPLEADO_TRSOL').AsString;
      Result.Estado :=
        oQuery.FieldByName('ESTADO_TRSOL').AsString;
      Result.Fecha :=
        oQuery.FieldByName('FECHA_TRSOL').AsDateTime;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ListarLineasSolicitud(
  const ANumero, ASerie, AOrigen, ADestino: string):
  TArray<TLineaSolicitudTraspasoTicket>;
var
  oDefinicion: TDefinicionSql;
  oLinea: TLineaSolicitudTraspasoTicket;
  oLineas: TList<TLineaSolicitudTraspasoTicket>;
  oQuery: TUniQuery;
begin
  oLineas := TList<TLineaSolicitudTraspasoTicket>.Create;
  oQuery := TUniQuery.Create(nil);
  try
    oDefinicion := DefinicionesSql[1];
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('NUM').AsString := ANumero;
        oQuery.ParamByName('SER').AsString := ASerie;
        oQuery.ParamByName('ORI').AsString := AOrigen;
        oQuery.ParamByName('DES').AsString := ADestino;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    while not oQuery.Eof do
    begin
      oLinea := Default(TLineaSolicitudTraspasoTicket);
      oLinea.Sku := oQuery.FieldByName('SKU').AsString;
      oLinea.Descripcion :=
        oQuery.FieldByName('DESCRIPCION').AsString;
      oLinea.CantidadPedida :=
        oQuery.FieldByName('PED').AsFloat;
      oLinea.StockOrigen :=
        oQuery.FieldByName('STK_ORI').AsFloat;
      oLinea.StockDestino :=
        oQuery.FieldByName('STK_DES').AsFloat;
      oLineas.Add(oLinea);
      oQuery.Next;
    end;
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oQuery);
    FreeAndNil(oLineas);
  end;
end;

function TRepositorioTraspasoTicket.ObtenerStock(
  const AAlmacen, ASku: string): Double;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := 0;
  oDefinicion := DefinicionesSql[2];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('SKU').AsString := ASku;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    if not oQuery.IsEmpty then
      Result := oQuery.FieldByName('STOCK').AsFloat;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ObtenerTraspasoHistorico(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  TTraspasoTicketHistorico;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  Result := Default(TTraspasoTicketHistorico);
  oDefinicion := DefinicionesSql[3];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('EMP').AsString := AEmpresa;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('CAJA').AsString := ACaja;
        oQuery.ParamByName('NUMOP').AsString := ANumeroOperacion;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result.Existe := not oQuery.IsEmpty;
    if Result.Existe then
    begin
      Result.Serie :=
        oQuery.FieldByName('SERIE_FAC_OPCAJA').AsString;
      Result.NumeroDocumento :=
        oQuery.FieldByName('NUMERO_FAC_OPCAJA').AsString;
      Result.FormatoDocumento :=
        oQuery.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
      Result.Origen :=
        oQuery.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      Result.Destino :=
        oQuery.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString;
      Result.Empleado :=
        oQuery.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioTraspasoTicket.ListarLineasTraspaso(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string):
  TArray<TLineaTraspasoTicket>;
var
  oDefinicion: TDefinicionSql;
  oLinea: TLineaTraspasoTicket;
  oLineas: TList<TLineaTraspasoTicket>;
  oQuery: TUniQuery;
begin
  oLineas := TList<TLineaTraspasoTicket>.Create;
  oQuery := TUniQuery.Create(nil);
  try
    oDefinicion := DefinicionesSql[4];
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        oQuery.ParamByName('EMP').AsString := AEmpresa;
        oQuery.ParamByName('ALM').AsString := AAlmacen;
        oQuery.ParamByName('CAJA').AsString := ACaja;
        oQuery.ParamByName('NUMOP').AsString := ANumeroOperacion;
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    while not oQuery.Eof do
    begin
      oLinea := Default(TLineaTraspasoTicket);
      oLinea.Sku :=
        oQuery.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      oLinea.Cantidad :=
        oQuery.FieldByName('CANTIDAD_MOV').AsFloat;
      oLinea.Descripcion :=
        oQuery.FieldByName('DESCRIPCION').AsString;
      oLineas.Add(oLinea);
      oQuery.Next;
    end;
    Result := oLineas.ToArray;
  finally
    FreeAndNil(oQuery);
    FreeAndNil(oLineas);
  end;
end;

end.
