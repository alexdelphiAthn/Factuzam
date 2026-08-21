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
  const ALecturas: ILecturasReversionMaterializacion;
  out AMensajeError: string): Boolean;
procedure EjecutarReversionSesion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasReversionMaterializacion;
  const AUsuario: string);
implementation

uses
  System.SysUtils,
  Data.DB, DBAccess, Uni,
  inLibMsgCompras;
// Aviso de paso omitido o degradado: rastro en el log tecnico y en la
// pestania Log de la pantalla de sesiones cuando esta activa.
procedure AvisoPaso(ADM: TdmComprasSesiones; const ATexto: string);
begin
  if Assigned(ADM) then
  begin
    ADM.RegistroLog.RegistrarAviso(
      'inLibComprasSesionesMaterializar: ' + ATexto);
    if Assigned(ADM.ContextoSesion) then
      ADM.ContextoSesion.LogSesion('  AVISO: ' + ATexto);
  end;
end;

type
  TTablasReversion = record
    TieneDocumentos: Boolean;
    TienePendienteRecibir: Boolean;
    TienePedidos: Boolean;
    TieneLineasPedido: Boolean;
    TieneCeldasPedido: Boolean;
    TieneAlbaranes: Boolean;
    TieneCeldasAlbaran: Boolean;
    TieneStockActual: Boolean;
  end;
  TReferenciasSesionReversion = record
    NumeroAlbaran: string;
    NumeroPedido: string;
    NumeroSesion: string;
    SerieAlbaran: string;
    SeriePedido: string;
    SerieSesion: string;
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
  ATablas.TieneCeldasPedido :=
    ALecturas.ExisteTabla('fza_pedidos_compra_celdas');
  ATablas.TieneAlbaranes :=
    ALecturas.ExisteTabla('fza_albaranes_compra') and
    ALecturas.ExisteTabla('fza_albaranes_compra_lineas');
  ATablas.TieneCeldasAlbaran :=
    ALecturas.ExisteTabla('fza_albaranes_compra_celdas');
  ATablas.TieneStockActual :=
    ALecturas.ExisteTabla('fza_articulos_stockactual');
end;

function TextoDocumento(
  const ADocumento: TDocumentoReversionMaterializacion): string;
begin
  Result := ADocumento.Serie + '/' + ADocumento.Numero;
end;

function ContieneDocumento(
  const ADocumentos: TDocumentosReversionMaterializacion;
  const ATipo, ASerie, ANumero: string): Boolean;
var
  iDocumento: Integer;
begin
  Result := False;
  iDocumento := 0;
  while (iDocumento < Length(ADocumentos)) and (not Result) do
  begin
    Result := SameText(ADocumentos[iDocumento].Tipo, ATipo) and
      SameText(ADocumentos[iDocumento].Serie, ASerie) and
      SameText(ADocumentos[iDocumento].Numero, ANumero);
    Inc(iDocumento);
  end;
end;

procedure AnadirDocumento(
  var ADocumentos: TDocumentosReversionMaterializacion;
  const ATipo, ASerie, ANumero: string);
var
  iDocumento: Integer;
begin
  if (ASerie <> '') and (ANumero <> '') and
     (not ContieneDocumento(ADocumentos, ATipo, ASerie, ANumero)) then
  begin
    iDocumento := Length(ADocumentos);
    SetLength(ADocumentos, iDocumento + 1);
    ADocumentos[iDocumento].Tipo := ATipo;
    ADocumentos[iDocumento].Serie := ASerie;
    ADocumentos[iDocumento].Numero := ANumero;
  end;
end;

procedure AnadirDetalle(var ADetalles: string; const ADetalle: string);
begin
  if ADetalles <> '' then
    ADetalles := ADetalles + sLineBreak;
  ADetalles := ADetalles + ADetalle;
end;

procedure ValidarReferenciaCabecera(
  var ADocumentos: TDocumentosReversionMaterializacion;
  const ATipo, ASerie, ANumero: string;
  ATieneMapa: Boolean;
  var AIncidencias: string);
begin
  if (ASerie = '') <> (ANumero = '') then
    AnadirDetalle(
      AIncidencias,
      Format(
        SIncidenciaReversionDocumentoIncompleto,
        [ATipo, ASerie, ANumero]))
  else if (ASerie <> '') and (ANumero <> '') then
  begin
    if not ATieneMapa then
      AnadirDocumento(ADocumentos, ATipo, ASerie, ANumero)
    else if not ContieneDocumento(
      ADocumentos,
      ATipo,
      ASerie,
      ANumero) then
      AnadirDetalle(
        AIncidencias,
        Format(
          SIncidenciaReversionReferenciaSinMapa,
          [ATipo, ASerie + '/' + ANumero]));
  end;
end;

function ObtenerDocumentosReversion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasReversionMaterializacion;
  ATieneDocumentos: Boolean;
  const AReferencias: TReferenciasSesionReversion;
  out AIncidencias: string): TDocumentosReversionMaterializacion;
var
  bTieneMapa: Boolean;
  iDocumento: Integer;
begin
  Result := nil;
  AIncidencias := '';
  if ATieneDocumentos then
    Result := ALecturas.ConsultarDocumentosSesion(
      AReferencias.SerieSesion,
      AReferencias.NumeroSesion)
  else
    AvisoPaso(ADM,
      'lectura de documentos omitida: ' +
      'fza_compras_sesiones_documentos no existe');
  bTieneMapa := Length(Result) > 0;
  for iDocumento := 0 to High(Result) do
  begin
    if (not SameText(Result[iDocumento].Tipo, 'ALBC')) and
       (not SameText(Result[iDocumento].Tipo, 'PEDC')) then
      AnadirDetalle(
        AIncidencias,
        Format(
          SIncidenciaReversionTipoDocumento,
          [Result[iDocumento].Tipo,
           TextoDocumento(Result[iDocumento])]));
    if (Result[iDocumento].Serie = '') or
       (Result[iDocumento].Numero = '') then
      AnadirDetalle(
        AIncidencias,
        Format(
          SIncidenciaReversionDocumentoIncompleto,
          [Result[iDocumento].Tipo,
           Result[iDocumento].Serie,
           Result[iDocumento].Numero]));
  end;
  ValidarReferenciaCabecera(
    Result,
    'ALBC',
    AReferencias.SerieAlbaran,
    AReferencias.NumeroAlbaran,
    bTieneMapa,
    AIncidencias);
  ValidarReferenciaCabecera(
    Result,
    'PEDC',
    AReferencias.SeriePedido,
    AReferencias.NumeroPedido,
    bTieneMapa,
    AIncidencias);
end;

function ConsultarDocumentosCompartidos(
  ADM: TdmComprasSesiones;
  const ADocumentos: TDocumentosReversionMaterializacion;
  const AReferencias: TReferenciasSesionReversion): string;
var
  iDocumento: Integer;
  q: TUniQuery;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT CONCAT(SERIE_SES_SESDOC, ''/'', ' +
      '              NUMERO_SES_SESDOC) AS SESION ' +
      '  FROM fza_compras_sesiones_documentos ' +
      ' WHERE TIPO_DOC_SESDOC = :t ' +
      '   AND SERIE_SESDOC = :sd AND NUMERO_SESDOC = :nd ' +
      '   AND (SERIE_SES_SESDOC <> :ss ' +
      '     OR NUMERO_SES_SESDOC <> :ns) ' +
      ' ORDER BY SERIE_SES_SESDOC, NUMERO_SES_SESDOC ' +
      ' LIMIT 10 FOR UPDATE';
    for iDocumento := 0 to High(ADocumentos) do
    begin
      q.Close;
      q.ParamByName('t').AsString := ADocumentos[iDocumento].Tipo;
      q.ParamByName('sd').AsString := ADocumentos[iDocumento].Serie;
      q.ParamByName('nd').AsString := ADocumentos[iDocumento].Numero;
      q.ParamByName('ss').AsString := AReferencias.SerieSesion;
      q.ParamByName('ns').AsString := AReferencias.NumeroSesion;
      q.Open;
      while not q.Eof do
      begin
        AnadirDetalle(
          Result,
          Format(
            SIncidenciaReversionDocumentoCompartido,
            [ADocumentos[iDocumento].Tipo,
             TextoDocumento(ADocumentos[iDocumento]),
             q.FieldByName('SESION').AsString]));
        q.Next;
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function ConsultarDependenciasReversion(
  const ALecturas: ILecturasReversionMaterializacion;
  const ADocumentos: TDocumentosReversionMaterializacion): string;
var
  aAlbaranes: TDocumentosReversionMaterializacion;
  aReferencias: TArray<string>;
  iDocumento: Integer;
  iReferencia: Integer;
  sDocumento: string;
begin
  Result := '';
  for iDocumento := 0 to High(ADocumentos) do
  begin
    sDocumento := TextoDocumento(ADocumentos[iDocumento]);
    if SameText(ADocumentos[iDocumento].Tipo, 'ALBC') then
    begin
      aReferencias := ALecturas.ConsultarFacturasCompraAlbaran(
        ADocumentos[iDocumento].Serie,
        ADocumentos[iDocumento].Numero);
      for iReferencia := 0 to High(aReferencias) do
        AnadirDetalle(
          Result,
          Format(
            SIncidenciaReversionFacturaCompra,
            [sDocumento, aReferencias[iReferencia]]));
      aReferencias := ALecturas.ConsultarSalidasPosterioresAlbaran(
        ADocumentos[iDocumento].Serie,
        ADocumentos[iDocumento].Numero);
      for iReferencia := 0 to High(aReferencias) do
        AnadirDetalle(
          Result,
          Format(
            SIncidenciaReversionSalidaPosterior,
            [sDocumento, aReferencias[iReferencia]]));
    end
    else if SameText(ADocumentos[iDocumento].Tipo, 'PEDC') then
    begin
      aAlbaranes := ALecturas.ConsultarAlbaranesPedido(
        ADocumentos[iDocumento].Serie,
        ADocumentos[iDocumento].Numero);
      for iReferencia := 0 to High(aAlbaranes) do
      begin
        if not ContieneDocumento(
          ADocumentos,
          'ALBC',
          aAlbaranes[iReferencia].Serie,
          aAlbaranes[iReferencia].Numero) then
          AnadirDetalle(
            Result,
            Format(
              SIncidenciaReversionPedidoRecibido,
              [sDocumento, TextoDocumento(aAlbaranes[iReferencia])]));
      end;
    end;
  end;
end;

function BloquearSesionCerrada(
  ADM: TdmComprasSesiones;
  const ASerie, ANumero: string;
  out AReferencias: TReferenciasSesionReversion): Boolean;
var
  q: TUniQuery;
begin
  AReferencias.NumeroAlbaran := '';
  AReferencias.NumeroPedido := '';
  AReferencias.NumeroSesion := ANumero;
  AReferencias.SerieAlbaran := '';
  AReferencias.SeriePedido := '';
  AReferencias.SerieSesion := ASerie;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT ESTADO_SES, SERIE_ALBC_SES, NUMERO_ALBC_SES, ' +
      '       SERIE_PEDC_SES, NUMERO_PEDC_SES ' +
      '  FROM fza_compras_sesiones ' +
      ' WHERE SERIE_SES = :s AND NUMERO_SES = :n ' +
      ' FOR UPDATE';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    Result := (not q.IsEmpty) and
      SameText(q.FieldByName('ESTADO_SES').AsString, 'CERRADA');
    if Result then
    begin
      AReferencias.SerieAlbaran :=
        q.FieldByName('SERIE_ALBC_SES').AsString;
      AReferencias.NumeroAlbaran :=
        q.FieldByName('NUMERO_ALBC_SES').AsString;
      AReferencias.SeriePedido :=
        q.FieldByName('SERIE_PEDC_SES').AsString;
      AReferencias.NumeroPedido :=
        q.FieldByName('NUMERO_PEDC_SES').AsString;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure ConsumirBloqueo(AQuery: TUniQuery);
begin
  AQuery.Open;
  while not AQuery.Eof do
    AQuery.Next;
  AQuery.Close;
end;

procedure BloquearDocumentosReversion(
  ADM: TdmComprasSesiones;
  const ADocumentos: TDocumentosReversionMaterializacion;
  const ATablas: TTablasReversion);
var
  iDocumento: Integer;
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    for iDocumento := 0 to High(ADocumentos) do
    begin
      if SameText(ADocumentos[iDocumento].Tipo, 'ALBC') and
         ATablas.TieneAlbaranes then
      begin
        q.SQL.Text :=
          'SELECT SERIE_ALBC FROM fza_albaranes_compra ' +
          ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n ' +
          ' FOR UPDATE';
        q.ParamByName('s').AsString := ADocumentos[iDocumento].Serie;
        q.ParamByName('n').AsString := ADocumentos[iDocumento].Numero;
        ConsumirBloqueo(q);
        if ATablas.TieneStockActual then
        begin
          q.SQL.Text :=
            'SELECT S.CODIGO_ALM_STK, S.CODIGO_UNIDAD_STK, ' +
            '       S.LOTE_STK ' +
            '  FROM fza_articulos_stockactual S ' +
            '  JOIN fza_movimientos_almacen M ' +
            '    ON M.CODIGO_ALM_MOV = S.CODIGO_ALM_STK ' +
            '   AND M.CODIGO_UNIDAD_MOV = S.CODIGO_UNIDAD_STK ' +
            '   AND IFNULL(M.LOTE_MOV, '''') = S.LOTE_STK ' +
            ' WHERE M.TIPO_DOC_MOV = ''AC'' ' +
            '   AND M.TIPO_MOV = ''E'' ' +
            '   AND IFNULL(M.ESACTIVO_MOV, ''S'') = ''S'' ' +
            '   AND M.SERIE_DOC_MOV = :s ' +
            '   AND M.NUMERO_DOC_MOV = :n ' +
            ' ORDER BY S.CODIGO_ALM_STK, S.CODIGO_UNIDAD_STK, ' +
            '          S.LOTE_STK FOR UPDATE';
          q.ParamByName('s').AsString := ADocumentos[iDocumento].Serie;
          q.ParamByName('n').AsString := ADocumentos[iDocumento].Numero;
          ConsumirBloqueo(q);
        end;
      end
      else if SameText(ADocumentos[iDocumento].Tipo, 'PEDC') and
              ATablas.TienePedidos then
      begin
        q.SQL.Text :=
          'SELECT SERIE_PEDC FROM fza_pedidos_compra ' +
          ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n ' +
          ' FOR UPDATE';
        q.ParamByName('s').AsString := ADocumentos[iDocumento].Serie;
        q.ParamByName('n').AsString := ADocumentos[iDocumento].Numero;
        ConsumirBloqueo(q);
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function ValidarReversionSesion(
  ADM: TdmComprasSesiones;
  const ALecturas: ILecturasReversionMaterializacion;
  out AMensajeError: string): Boolean;
var
  oDocumentos: TDocumentosReversionMaterializacion;
  Referencias: TReferenciasSesionReversion;
  sDependencias: string;
  sNumeroSesion: string;
  sSerieSesion: string;
  Tablas: TTablasReversion;
begin
  Result := False;
  AMensajeError := '';
  if ADM = nil then
    AMensajeError := SErrorDataModuleSesionNoInicializado
  else if ADM.unqryTablaG.IsEmpty then
    AMensajeError := SErrorSesionCompraNoActiva
  else if not Assigned(ALecturas) then
    AMensajeError := SErrorDataModuleSesionNoInicializado
  else if
    ADM.unqryTablaG.FieldByName('ESTADO_SES').AsString <> 'CERRADA' then
    AMensajeError := SErrorSesionNoCerradaParaRevertir
  else
  begin
    sSerieSesion :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    sNumeroSesion :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    if not BloquearSesionCerrada(
      ADM,
      sSerieSesion,
      sNumeroSesion,
      Referencias) then
      AMensajeError := SErrorSesionNoCerradaParaRevertir
    else
    begin
      ConsultarTablasReversion(ALecturas, Tablas);
      oDocumentos := ObtenerDocumentosReversion(
        ADM,
        ALecturas,
        Tablas.TieneDocumentos,
        Referencias,
        sDependencias);
      if (sDependencias = '') and Tablas.TieneDocumentos then
        sDependencias := ConsultarDocumentosCompartidos(
          ADM,
          oDocumentos,
          Referencias);
      if sDependencias = '' then
      begin
        BloquearDocumentosReversion(ADM, oDocumentos, Tablas);
        sDependencias := ConsultarDependenciasReversion(
          ALecturas,
          oDocumentos);
      end;
      if sDependencias <> '' then
        AMensajeError := Format(
          SErrorReversionSesionConIncidencias,
          [sDependencias])
      else
        Result := True;
    end;
  end;
end;

procedure BorrarAlbaranSesion(ADM: TdmComprasSesiones;
                              AQuery: TUniQuery;
                              const ASerieAlbaran,
                              ANumeroAlbaran: string;
                              const ATablas: TTablasReversion);
begin
  if ANumeroAlbaran <> '' then
  begin
    if ATablas.TieneAlbaranes then
    begin
      if ATablas.TieneCeldasAlbaran then
      begin
        AQuery.SQL.Text :=
          'DELETE FROM fza_albaranes_compra_celdas ' +
          ' WHERE NUMERO_ALBC_ALBCCEL = :nalb ' +
          '   AND SERIE_ALBC_ALBCCEL = :salb';
        AQuery.ParamByName('nalb').AsString := ANumeroAlbaran;
        AQuery.ParamByName('salb').AsString := ASerieAlbaran;
        AQuery.ExecSQL;
      end;
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

procedure BorrarPedidosSesion(ADM: TdmComprasSesiones;
                               AQuery: TUniQuery;
                               const ASeriePedido,
                               ANumeroPedido: string;
                               const ATablas: TTablasReversion);
begin
  if ANumeroPedido <> '' then
  begin
    if ATablas.TienePendienteRecibir then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_articulos_pdte_recibir ' +
        ' WHERE SERIE_DOC_PDR = :s AND NUMERO_DOC_PDR = :n';
      AQuery.ParamByName('s').AsString := ASeriePedido;
      AQuery.ParamByName('n').AsString := ANumeroPedido;
      AQuery.ExecSQL;
    end
    else
      AvisoPaso(ADM,
        'borrado de pendientes omitido: ' +
        'fza_articulos_pdte_recibir no existe');
    if ATablas.TieneCeldasPedido then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_pedidos_compra_celdas ' +
        ' WHERE SERIE_PEDC_PEDCCEL = :s ' +
        '   AND NUMERO_PEDC_PEDCCEL = :n';
      AQuery.ParamByName('s').AsString := ASeriePedido;
      AQuery.ParamByName('n').AsString := ANumeroPedido;
      AQuery.ExecSQL;
    end;
    if ATablas.TieneLineasPedido then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_pedidos_compra_lineas ' +
        ' WHERE SERIE_PEDC_PEDCLIN = :s ' +
        '   AND NUMERO_PEDC_PEDCLIN = :n';
      AQuery.ParamByName('s').AsString := ASeriePedido;
      AQuery.ParamByName('n').AsString := ANumeroPedido;
      AQuery.ExecSQL;
    end
    else
      AvisoPaso(ADM,
        'borrado de lineas omitido: ' +
        'fza_pedidos_compra_lineas no existe');
    if ATablas.TienePedidos then
    begin
      AQuery.SQL.Text :=
        'DELETE FROM fza_pedidos_compra ' +
        ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n';
      AQuery.ParamByName('s').AsString := ASeriePedido;
      AQuery.ParamByName('n').AsString := ANumeroPedido;
      AQuery.ExecSQL;
    end
    else
      AvisoPaso(ADM,
        'borrado de pedido omitido: fza_pedidos_compra no existe');
  end;
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
  iDocumento: Integer;
  oDocumentos: TDocumentosReversionMaterializacion;
  Referencias: TReferenciasSesionReversion;
  sIncidencias: string;
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
  if not BloquearSesionCerrada(
    ADM,
    sSerieSes,
    sNumSes,
    Referencias) then
    raise Exception.Create(SErrorSesionNoCerradaParaRevertir);
  ConsultarTablasReversion(ALecturas, Tablas);
  oDocumentos := ObtenerDocumentosReversion(
    ADM,
    ALecturas,
    Tablas.TieneDocumentos,
    Referencias,
    sIncidencias);
  if (sIncidencias = '') and Tablas.TieneDocumentos then
    sIncidencias := ConsultarDocumentosCompartidos(
      ADM,
      oDocumentos,
      Referencias);
  if sIncidencias = '' then
  begin
    BloquearDocumentosReversion(ADM, oDocumentos, Tablas);
    sIncidencias := ConsultarDependenciasReversion(
      ALecturas,
      oDocumentos);
  end;
  if sIncidencias <> '' then
    raise Exception.Create(
      Format(
        SErrorReversionSesionConIncidencias,
        [sIncidencias]));
  q := TUniQuery.Create(nil);
  try
    q.Connection := conn;
    for iDocumento := 0 to High(oDocumentos) do
    begin
      if SameText(oDocumentos[iDocumento].Tipo, 'ALBC') then
      begin
        BorrarMovimientosAlbaran(
          q,
          oDocumentos[iDocumento].Serie,
          oDocumentos[iDocumento].Numero);
        BorrarAlbaranSesion(
          ADM,
          q,
          oDocumentos[iDocumento].Serie,
          oDocumentos[iDocumento].Numero,
          Tablas);
      end;
    end;
    for iDocumento := 0 to High(oDocumentos) do
    begin
      if SameText(oDocumentos[iDocumento].Tipo, 'PEDC') then
        BorrarPedidosSesion(
          ADM,
          q,
          oDocumentos[iDocumento].Serie,
          oDocumentos[iDocumento].Numero,
          Tablas);
    end;
    BorrarDocumentosSesion(
      ADM,
      q,
      sSerieSes,
      sNumSes,
      Tablas.TieneDocumentos);
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
