{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesReversion                              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de la reversión de una sesión de compra materializada.       }
{******************************************************************************}
unit UniDataComprasSesionesReversion;

interface

uses
  inLibComprasSesionesLecturasIntf,
  UniDataComprasSesiones;

function ValidarReversionSesion(
  ADM: TdmComprasSesiones;
  out AMensajeError: string): Boolean;
procedure EjecutarReversionSesion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasReversionMaterializacion;
  const AUsuario: string);

implementation

uses
  System.SysUtils,
  Data.DB, DBAccess, Uni,
  inLibLog,
  inLibMsgCompras;
// Aviso de paso omitido o degradado: rastro en el log tecnico y en la
// pestania Log de la pantalla de sesiones cuando esta activa.
procedure AvisoPaso(ADM: TdmComprasSesiones; const ATexto: string);
begin
  Log.LogWarning('inLibComprasSesionesMaterializar: ' + ATexto);
  if Assigned(ADM) and Assigned(ADM.ContextoSesion) then
    ADM.ContextoSesion.LogSesion('  AVISO: ' + ATexto);
end;

type
  TTablasReversion = record
    TieneDocumentos: Boolean;
    TienePendienteRecibir: Boolean;
    TienePedidos: Boolean;
    TieneLineasPedido: Boolean;
    TieneAlbaranes: Boolean;
  end;

procedure EjecutarSqlSesion(AQuery: TUniQuery; const ASql,
                            ASerieSesion, ANumeroSesion: string);
begin
  AQuery.SQL.Text := ASql;
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ExecSQL;
end;

procedure ConsultarTablasReversion(
                                   const ALecturas:
                                   ILecturasReversionMaterializacion;
                                   out ATablas: TTablasReversion);
begin
  ATablas.TieneDocumentos :=
    ALecturas.ExisteTabla('fza_compras_sesiones_documentos');
  ATablas.TienePendienteRecibir :=
    ALecturas.ExisteTabla('fza_articulos_pdte_recibir');
  ATablas.TienePedidos :=
    ALecturas.ExisteTabla('fza_pedidos_compra');
  ATablas.TieneLineasPedido :=
    ALecturas.ExisteTabla('fza_pedidos_compra_lineas');
  ATablas.TieneAlbaranes :=
    ALecturas.ExisteTabla('fza_albaranes_compra') and
    ALecturas.ExisteTabla('fza_albaranes_compra_lineas');
end;

function ValidarReversionSesion(ADM: TdmComprasSesiones;
                                out AMensajeError: string): Boolean;
begin
  Result := False;
  if ADM = nil then
    AMensajeError := SErrorDataModuleSesionNoInicializado
  else if ADM.unqryTablaG.IsEmpty then
    AMensajeError := SErrorSesionCompraNoActiva
  else if
    ADM.unqryTablaG.FieldByName('ESTADO_SES').AsString <> 'CERRADA' then
    AMensajeError := SErrorSesionNoCerradaParaRevertir
  else
    Result := True;
end;

procedure BorrarAlbaranSesion(ADM: TdmComprasSesiones;
                              AQuery: TUniQuery;
                              const ASerieAlbaran,
                              ANumeroAlbaran: string;
                              ATieneAlbaranes: Boolean);
begin
  if ANumeroAlbaran <> '' then
  begin
    if ATieneAlbaranes then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_albaranes_compra_lineas ' +
        ' WHERE NUMERO_ALBC_ALBCLIN = :nalb ' +
        '   AND SERIE_ALBC_ALBCLIN = :salb';
      AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
      AQuery.ParamByName('salb').AsString := ASerieAlbaran;
      AQuery.ExecSQL;
      AQuery.SQL.Text :=
        'DELETE FROM fza_albaranes_compra ' +
        ' WHERE NUMERO_ALBC = :nalb AND SERIE_ALBC = :salb';
      AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
      AQuery.ParamByName('salb').AsString := ASerieAlbaran;
      AQuery.ExecSQL;
    end
    else
      AvisoPaso(ADM,
        '0j omitido: fza_albaranes_compra(_lineas) no existe');
  end;
end;

procedure BorrarDocumentosSesion(ADM: TdmComprasSesiones;
                                 AQuery: TUniQuery;
                                 const ASerieSesion,
                                 ANumeroSesion: string;
                                 ATieneDocumentos: Boolean);
begin
  if ATieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE FROM fza_compras_sesiones_documentos ' +
      ' WHERE SERIE_SES_SESDOC = :s ' +
      '   AND NUMERO_SES_SESDOC = :n',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '0j-bis omitido: fza_compras_sesiones_documentos no existe');
end;

procedure BorrarMovimientosAlbaran(AQuery: TUniQuery;
                                   const ASerieAlbaran,
                                   ANumeroAlbaran: string);
begin
  if (ANumeroAlbaran <> '') and (ASerieAlbaran <> '') then
  begin
    AQuery.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :salb, :nalb)';
    AQuery.ParamByName('t').AsString := 'AC';
    AQuery.ParamByName('salb').AsString := ASerieAlbaran;
    AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
    AQuery.ExecSQL;
  end;
end;

procedure BorrarMovimientosHuerfanos(ADM: TdmComprasSesiones;
                                     const ALecturas:
                                     ILecturasReversionMaterializacion;
                                     AQuery: TUniQuery);
var
  oMovimientos: TArray<string>;
  iMovimiento: Integer;
begin
  oMovimientos := ALecturas.ConsultarMovimientosHuerfanos(
    ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString,
    ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString);
  for iMovimiento := 0 to High(oMovimientos) do
  begin
    AQuery.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE(:m)';
    AQuery.ParamByName('m').AsString := oMovimientos[iMovimiento];
    AQuery.ExecSQL;
  end;
end;

procedure BorrarPedidosSesion(ADM: TdmComprasSesiones;
                              AQuery: TUniQuery;
                              const ASerieSesion,
                              ANumeroSesion,
                              ASeriePedido: string;
                              const ATablas: TTablasReversion);
begin
  if ATablas.TienePendienteRecibir and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PDR FROM fza_articulos_pdte_recibir PDR ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PDR.SERIE_DOC_PDR ' +
      '   AND D.NUMERO_SESDOC = PDR.NUMERO_DOC_PDR ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.1 omitido: falta fza_articulos_pdte_recibir ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TieneLineasPedido and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PEDL FROM fza_pedidos_compra_lineas PEDL ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PEDL.SERIE_PEDC_PEDCLIN ' +
      '   AND D.NUMERO_SESDOC = PEDL.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.2 omitido: falta fza_pedidos_compra_lineas ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TienePedidos and ATablas.TieneDocumentos then
    EjecutarSqlSesion(AQuery,
      'DELETE PED FROM fza_pedidos_compra PED ' +
      '  JOIN fza_compras_sesiones_documentos D ' +
      '    ON D.SERIE_SESDOC = PED.SERIE_PEDC ' +
      '   AND D.NUMERO_SESDOC = PED.NUMERO_PEDC ' +
      ' WHERE D.SERIE_SES_SESDOC = :s ' +
      '   AND D.NUMERO_SES_SESDOC = :n ' +
      '   AND D.TIPO_DOC_SESDOC = ''PEDC''',
      ASerieSesion, ANumeroSesion)
  else
    AvisoPaso(ADM,
      '1b.3 omitido: falta fza_pedidos_compra ' +
      'o fza_compras_sesiones_documentos');
  if ATablas.TienePendienteRecibir then
  begin
    AQuery.SQL.Text :=
      'DELETE FROM fza_articulos_pdte_recibir ' +
      ' WHERE NUMERO_DOC_PDR = :n ' +
      '   AND (SERIE_DOC_PDR = :ses ' +
      '        OR (:sped <> '''' AND SERIE_DOC_PDR = :sped))';
    AQuery.ParamByName('n').AsString := ANumeroSesion;
    AQuery.ParamByName('ses').AsString := ASerieSesion;
    AQuery.ParamByName('sped').AsString := ASeriePedido;
    AQuery.ExecSQL;
  end
  else
    AvisoPaso(ADM,
      '1b.4 omitido: fza_articulos_pdte_recibir no existe');
end;

procedure ReabrirSesion(AQuery: TUniQuery;
                        const ASerieSesion,
                        ANumeroSesion,
                        AUsuario: string);
begin
  AQuery.SQL.Text :=
    'UPDATE fza_compras_sesiones SET ' +
    '  ESTADO_SES = ''BORRADOR'', ' +
    '  INSTANTE_MATERIALIZA_SES = NULL, ' +
    '  USUARIO_MATERIALIZA_SES = NULL, ' +
    '  SERIE_PEDC_SES = NULL, ' +
    '  NUMERO_PEDC_SES = NULL, ' +
    '  SERIE_ALBC_SES = NULL, ' +
    '  NUMERO_ALBC_SES = NULL, ' +
    '  MENSAJE_ERROR_SES = NULL, ' +
    '  INSTANTE_MODIF = NOW(), ' +
    '  USUARIO_MODIF = :u ' +
    ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';
  AQuery.ParamByName('s').AsString := ASerieSesion;
  AQuery.ParamByName('n').AsString := ANumeroSesion;
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
end;


procedure EjecutarReversionSesion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasReversionMaterializacion;
  const AUsuario: string);
var
  conn: TUniConnection;
  sSerieSes: string;
  sNumSes: string;
  q: TUniQuery;
  Tablas: TTablasReversion;
begin
  conn := ADM.ConexionPrincipal;
  sSerieSes :=
    ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumSes :=
    ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  ConsultarTablasReversion(ALecturas, Tablas);
  q := TUniQuery.Create(nil);
  try
    q.Connection := conn;
    BorrarAlbaranSesion(
      ADM,
      q,
      ADM.unqryTablaG.FieldByName(
        'SERIE_ALBC_SES').AsString,
      ADM.unqryTablaG.FieldByName(
        'NUMERO_ALBC_SES').AsString,
      Tablas.TieneAlbaranes);
    BorrarDocumentosSesion(
      ADM,
      q,
      sSerieSes,
      sNumSes,
      Tablas.TieneDocumentos);
    BorrarMovimientosAlbaran(
      q,
      ADM.unqryTablaG.FieldByName(
        'SERIE_ALBC_SES').AsString,
      ADM.unqryTablaG.FieldByName(
        'NUMERO_ALBC_SES').AsString);
    BorrarMovimientosHuerfanos(ADM, ALecturas, q);
    BorrarPedidosSesion(
      ADM,
      q,
      sSerieSes,
      sNumSes,
      ADM.unqryTablaG.FieldByName(
        'SERIE_PEDC_SES').AsString,
      Tablas);
    ReabrirSesion(
      q,
      sSerieSes,
      sNumSes,
      AUsuario);
  finally
    FreeAndNil(q);
  end;
end;

end.
