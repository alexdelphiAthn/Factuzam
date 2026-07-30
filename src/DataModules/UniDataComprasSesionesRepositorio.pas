{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesRepositorio                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Repositorio UniDAC y composición de los adaptadores de compras.           }
{******************************************************************************}
unit UniDataComprasSesionesRepositorio;

interface

uses
  Uni, inLibCatalogoSqlIntf, inLibComprasSesionesIntf,
  UniDataComprasSesiones;

type
  TRepositorioComprasSesiones = class(
    TInterfacedObject,
    IRepositorioComprasSesiones)
  private
    FConexion: TUniConnection;
    FDataModule: TdmComprasSesiones;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    procedure AsegurarDataModule;
    function EjecutarObtenerSiguienteLinea(
      const ASql, ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function EjecutarConsultarCantidadesLinea(
      const ASql, ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
  public
    constructor Create(
      AConexion: TUniConnection;
      ADataModule: TdmComprasSesiones;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    procedure AplicarDuplicadoEnLinea(
      const AResultado: TResolverDuplicadoSesion);
    procedure BorrarCeldasLinea(
      const ASerie, ANumero: string;
      ALinea: Integer);
    procedure CopiarCeldasDistribuidas(
      const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
      ALineaOrigen, ALineaDestino: Integer);
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ConsultarCodigosBasicosActivos(
      const AIdVariacion: string): TArray<string>;
    function ObtenerNombreFamilia(
      const ACodigoFamilia: string): string;
    function ResolverCodigoFamilia(
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean;
    function ResolverDuplicado(
      const ACodigoBuscado, ACodigoProveedor: string;
      ASoloRefProveedor: Boolean;
      const ACodigoArticuloPreferido: string):
      TResolverDuplicadoSesion;
    function ResolverDuplicadoIntraSesion(
      const ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function NormalizarDuplicadosIntraSesion(
      const AUsuario, ASerie, ANumero: string): Integer;
    function ValidarSesionDetallado:
      TIncidenciasSesionCompra;
    function EjecutarMaterializacion(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    function RevertirMaterializacion(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  inLibCatalogoSqlEjecucion,
  UniDataComprasSesionesMaterializar,
  UniDataComprasSesionesOperaciones;

const
  SQL_SIGUIENTE_LINEA =
    'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND LINEA_SESLIN > :l';
  SQL_CANTIDADES_LINEA =
    'SELECT ID_AV_PIVOT_SESCEL, ' +
    '       SUM(CANTIDAD_SESCEL) AS TOTAL ' +
    '  FROM fza_compras_sesiones_celdas ' +
    ' WHERE SERIE_SES_SESCEL = :s ' +
    '   AND NUMERO_SES_SESCEL = :n ' +
    '   AND LINEA_SES_SESCEL = :l ' +
    ' GROUP BY ID_AV_PIVOT_SESCEL';

function DefinicionSiguienteLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerSiguienteLinea',
    SQL_SIGUIENTE_LINEA,
    's,n,l',
    'SIGUIENTE',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionCantidadesLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarCantidadesLinea',
    SQL_CANTIDADES_LINEA,
    's,n,l',
    'ID_AV_PIVOT_SESCEL,TOTAL',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

constructor TRepositorioComprasSesiones.Create(
  AConexion: TUniConnection;
  ADataModule: TdmComprasSesiones;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FDataModule := ADataModule;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

procedure TRepositorioComprasSesiones.AsegurarDataModule;
begin
  if not Assigned(FDataModule) then
    raise EInvalidOperation.Create(
      'El repositorio requiere el contexto de la sesión de compra');
end;

class function TRepositorioComprasSesiones.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 2);
  Result[0] := DefinicionSiguienteLinea;
  Result[1] := DefinicionCantidadesLinea;
end;

procedure TRepositorioComprasSesiones.AplicarDuplicadoEnLinea(
  const AResultado: TResolverDuplicadoSesion);
begin
  AsegurarDataModule;
  UniDataComprasSesionesOperaciones.AplicarDuplicadoEnLinea(
    FDataModule,
    AResultado);
end;

procedure TRepositorioComprasSesiones.BorrarCeldasLinea(
  const ASerie, ANumero: string;
  ALinea: Integer);
begin
  UniDataComprasSesionesOperaciones.BorrarCeldasLineaSesion(
    FConexion,
    ASerie,
    ANumero,
    ALinea);
end;

procedure TRepositorioComprasSesiones.CopiarCeldasDistribuidas(
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
begin
  UniDataComprasSesionesOperaciones.CopiarCeldasDistribuidasSesion(
    FConexion,
    ASerie,
    ANumero,
    AAlmacenCabecera,
    AUsuario,
    ALineaOrigen,
    ALineaDestino);
end;

function TRepositorioComprasSesiones.ConsultarCodigosBasicosActivos(
  const AIdVariacion: string): TArray<string>;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ConsultarCodigosBasicosActivos(
      FConexion,
      AIdVariacion);
end;

function TRepositorioComprasSesiones.ObtenerNombreFamilia(
  const ACodigoFamilia: string): string;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ObtenerNombreFamiliaSesion(
      FConexion,
      ACodigoFamilia);
end;

function TRepositorioComprasSesiones.ResolverCodigoFamilia(
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ResolverCodigoFamilia(
      FConexion,
      ACodigoTecleado,
      AUsuario,
      ACodigoGenerado);
end;

function TRepositorioComprasSesiones.ResolverDuplicado(
  const ACodigoBuscado, ACodigoProveedor: string;
  ASoloRefProveedor: Boolean;
  const ACodigoArticuloPreferido: string):
  TResolverDuplicadoSesion;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ResolverDuplicadoSesion(
      FConexion,
      ACodigoBuscado,
      ACodigoProveedor,
      ASoloRefProveedor,
      ACodigoArticuloPreferido);
end;

function TRepositorioComprasSesiones.ResolverDuplicadoIntraSesion(
  const ASerie, ANumero: string;
  ALineaActual: Integer;
  const AModelo, ACodigoArticulo: string):
  TResolverDuplicadoSesion;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ResolverDuplicadoIntraSesion(
      FConexion,
      ASerie,
      ANumero,
      ALineaActual,
      AModelo,
      ACodigoArticulo);
end;

function TRepositorioComprasSesiones.NormalizarDuplicadosIntraSesion(
  const AUsuario, ASerie, ANumero: string): Integer;
begin
  Result :=
    UniDataComprasSesionesOperaciones.NormalizarDuplicadosIntraSesion(
      FConexion,
      AUsuario,
      ASerie,
      ANumero);
end;

function TRepositorioComprasSesiones.ValidarSesionDetallado:
  TIncidenciasSesionCompra;
var
  iIncidencia: Integer;
  oIncidencias: TStringList;
begin
  AsegurarDataModule;
  Result := nil;
  oIncidencias := TStringList.Create;
  try
    UniDataComprasSesionesOperaciones.ValidarSesionDetallado(
      FDataModule,
      oIncidencias);
    SetLength(Result, oIncidencias.Count);
    for iIncidencia := 0 to oIncidencias.Count - 1 do
      Result[iIncidencia] := oIncidencias[iIncidencia];
  finally
    FreeAndNil(oIncidencias);
  end;
end;

function TRepositorioComprasSesiones.EjecutarMaterializacion(
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  AsegurarDataModule;
  Result :=
    UniDataComprasSesionesMaterializar.EjecutarMaterializacionSesion(
      FDataModule,
      AParametros,
      AResultado);
end;

function TRepositorioComprasSesiones.RevertirMaterializacion(
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  AsegurarDataModule;
  Result :=
    UniDataComprasSesionesMaterializar.RevertirMaterializacion(
      FDataModule,
      AUsuario,
      AMensajeError);
end;

function TRepositorioComprasSesiones.EjecutarObtenerSiguienteLinea(
  const ASql, ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALineaActual;
    oConsulta.Open;
    if not oConsulta.FieldByName('SIGUIENTE').IsNull then
      Result := oConsulta.FieldByName(
        'SIGUIENTE').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarConsultarCantidadesLinea(
  const ASql, ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].IdValorPivot :=
        oConsulta.FieldByName(
          'ID_AV_PIVOT_SESCEL').AsInteger;
      Result[iIndice].Cantidad :=
        oConsulta.FieldByName('TOTAL').AsFloat;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.ObtenerSiguienteLinea(
  const ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oDefinicion: TDefinicionSql;
  iSiguiente: Integer;
begin
  oDefinicion := DefinicionSiguienteLinea;
  iSiguiente := 0;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      iSiguiente := EjecutarObtenerSiguienteLinea(
        ASql,
        ASerie,
        ANumero,
        ALineaActual);
    end,
    FIncidenciasSql);
  Result := iSiguiente;
end;

function TRepositorioComprasSesiones.ConsultarCantidadesLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  oCantidades: TCantidadesPivotSesion;
  oDefinicion: TDefinicionSql;
begin
  oDefinicion := DefinicionCantidadesLinea;
  oCantidades := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oCantidades := EjecutarConsultarCantidadesLinea(
        ASql,
        ASerie,
        ANumero,
        ALinea);
    end,
    FIncidenciasSql);
  Result := oCantidades;
end;

end.
