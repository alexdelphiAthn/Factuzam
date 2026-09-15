{******************************************************************************}
{                                                                              }
{                    Módulo: UniDataPresupuestosConversion                     }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataPresupuestosConversion;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni, inLibPresupuestosIntf;

function ConvertirPresupuestoUniDAC(AOwner: TComponent;
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto):
  TResultadoConversionPresupuesto;

implementation

uses
  System.SysUtils, Data.DB,
  inLibDocumento, inLibDocumentoIntf,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataAlbaranes;

function ResolverSerieDestino(AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto): string;
var
  oConsulta: TUniQuery;
  sTipo, sEmpresa: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_EMP_PRE, SERIE_DESTINO_PRE FROM fza_presupuestos ' +
      'WHERE SERIE_PRE = :SERIE AND NUMERO_PRE = :NUMERO FOR UPDATE';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.Numero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise Exception.Create(SErrorPresupuestoNoExiste);
    Result := oConsulta.FieldByName('SERIE_DESTINO_PRE').AsString;
    if Result = '' then
    begin
      sEmpresa := oConsulta.FieldByName('CODIGO_EMP_PRE').AsString;
      sTipo := CrearConfiguracionDocumento(
        TipoDestinoPresupuesto(ASolicitud.Destino), sdVenta).TipoContador;
      Result := ObtenerSerieDefecto(AConexion, sEmpresa, sTipo);
      if Result = '' then
        raise Exception.CreateFmt(
          SErrorSerieDestinoPresupuesto,
          [sTipo, sEmpresa]);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CopiarPresupuesto(AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto;
  var AResultado: TResultadoConversionPresupuesto);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_PRE_CONVERTIR(:SERIE, :NUMERO, :TIPO, ' +
      ':DESTINO, :USUARIO, @PRE_NUMERO_DESTINO)';
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ASolicitud.Numero;
    oConsulta.ParamByName('TIPO').AsString := CrearConfiguracionDocumento(
      AResultado.TipoDocumento, sdVenta).TipoContador;
    oConsulta.ParamByName('DESTINO').AsString := AResultado.Serie;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT @PRE_NUMERO_DESTINO AS NUMERO';
    oConsulta.Open;
    AResultado.Numero := oConsulta.FieldByName('NUMERO').AsString;
    if AResultado.Numero = '' then
      raise Exception.Create(SErrorDestinoPresupuestoNoCreado);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure SincronizarAlbaran(AOwner: TComponent;
  const AResultado: TResultadoConversionPresupuesto);
var
  oAlbaran: TdmAlbaranes;
begin
  oAlbaran := TdmAlbaranes.Create(AOwner);
  try
    oAlbaran.unqryTablaG.SQL.Text :=
      'SELECT NUMERO_ALB, SERIE_ALB, CODIGO_EMP_ALB, CODIGO_CLI_ALB, ' +
      'CODIGO_ALM_ALB, INSTANTE_MOVIMIENTO_ALB, FECHA_ALB ' +
      'FROM fza_albaranes WHERE SERIE_ALB = :SERIE ' +
      'AND NUMERO_ALB = :NUMERO';
    oAlbaran.unqryTablaG.ParamByName('SERIE').AsString := AResultado.Serie;
    oAlbaran.unqryTablaG.ParamByName('NUMERO').AsString := AResultado.Numero;
    oAlbaran.unqryTablaG.Open;
    oAlbaran.GenerarMovimientosSalida;
  finally
    FreeAndNil(oAlbaran);
  end;
end;

function ConvertirPresupuestoUniDAC(AOwner: TComponent;
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudConversionPresupuesto):
  TResultadoConversionPresupuesto;
begin
  if AConexion.InTransaction then
    raise Exception.Create(
      SErrorOperacionPendientePresupuesto);
  Result := Default(TResultadoConversionPresupuesto);
  Result.TipoDocumento := TipoDestinoPresupuesto(ASolicitud.Destino);
  Result.Pantalla := PantallaDestinoPresupuesto(ASolicitud.Destino);
  AConexion.StartTransaction;
  try
    Result.Serie := ResolverSerieDestino(AConexion, ASolicitud);
    CopiarPresupuesto(AConexion, ASolicitud, Result);
    if ASolicitud.Destino = dpAlbaran then
      SincronizarAlbaran(AOwner, Result);
    AConexion.Commit;
  except
    if AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

end.
