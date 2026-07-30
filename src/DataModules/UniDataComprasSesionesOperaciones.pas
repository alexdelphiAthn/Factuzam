{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesOperaciones                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de las operaciones de las sesiones de compra.            }
{******************************************************************************}
unit UniDataComprasSesionesOperaciones;

interface

uses
  System.SysUtils, System.Classes,
  DBAccess, Uni,
  UniDataComprasSesiones, inLibGridTallasInline, inLibComprasSesionesIntf,
  Data.DB;

// Comprueba que el kit del proveedor se puede aplicar sobre la linea con
// foco: sesion activa, linea con numero, sistema de tallas asignado, kit
// existente y tallaje del kit IGUAL al de la linea (ID_AC_TALLAS_PRVKIT =
// ID_AC_PIVOT_SESLIN). Con False, AResumen lleva la advertencia para el
// usuario. Lo usan AplicarKitProveedorALinea y el form antes de abrir el
// distribuidor en modo kit (formato distribuido).
function ValidarKitSobreLineaActual(ADM: TdmComprasSesiones;
                                     const ACodigoPrv, ACodigoKit: string;
                                     out AResumen: string): Boolean;

// Aplica un kit del proveedor (fza_proveedores_kits_det) sobre la linea
// con foco de la sesion. REGLA: el tallaje del kit (ID_AC_TALLAS_PRVKIT)
// debe COINCIDIR con el de la linea (ID_AC_PIVOT_SESLIN); si no coincide
// (o el kit no tiene sistema) devuelve False con la advertencia en
// AResumen y no aplica nada. Si coincide, cada VALOR_DESTINO_PRVKITD se
// casa por texto contra los valores del sistema para mapear su columna y
// se persiste con el mismo UPSERT que el tecleo manual en la celda
// (PersistirCantidad; cantidad 0 borra la celda). NO repinta el grid:
// tras un True el form debe RefrescarTotalesLineaActual +
// CargarCantidadesUnaLinea.
// Devuelve False si no se aplico nada; AResumen lleva el motivo o, con
// True, el detalle de tallas sin correspondencia (vacio si caso todo).
function AplicarKitProveedorALinea(ADM: TdmComprasSesiones;
                                    AGestor: TGestorGridTallas;
                                    const ACodigoPrv, ACodigoKit: string;
                                    out AResumen: string): Boolean;

function  ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;

// Recorre TODAS las reglas de validacion y deja una linea por
// incidencia en AIncidencias. Devuelve True si no hay ninguna (sesion
// lista para materializar). El form usa esto para abrir un modal con
// la lista en lugar del mensaje unico de ValidarSesion.
function ValidarSesionDetallado(ADM: TdmComprasSesiones;
                                 AIncidencias: TStrings): Boolean;

// Normaliza duplicados intra-sesion: para cada CODIGO_ART_TENTATIVO que
// aparece en >1 lineas, deja la primera (LINEA_SESLIN minimo) tal cual
// y marca las demas con ESDUPLICADO_SESLIN='S', ACCION='REUSAR',
// CODIGO_ART_REUSAR=el mismo codigo, para que la materializacion solo
// haga INSERT en fza_articulos una vez (la primera) y las variantes
// del mismo articulo (distinto color/SKU) reusen la cabecera. Devuelve
// el numero de lineas marcadas. Idempotente: si todas estan ya
// resueltas, devuelve 0.
function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;

// Si ACodigoTecleado coincide exactamente con una familia que tiene el
// contador activo (ESCONTADOR_ART_FAM = 'S'), genera el siguiente codigo
// de articulo (FAMILIA + relleno de PAD_ART_FAM digitos del CONTADOR_ART_FAM
// incrementado), incrementa el contador en fza_articulos_familias y
// devuelve True con ACodigoGenerado lleno.
// Si no es una familia, o la familia no tiene contador activo, devuelve
// False y ACodigoGenerado queda vacio.
function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;

// ---------------------------------------------------------------------------
// Reutilizacion de articulos ya existentes en una sesion (ACCION=REUSAR)
// ---------------------------------------------------------------------------
// Busca un articulo existente que case con lo que el usuario teclea, por
// dos vias:
//   1. CODIGO_ART_ART exacto (cualquier proveedor)
//   2. REF_PROVEEDOR_AP exacto en fza_articulos_proveedores para
//      ACodigoProveedor (proveedor de la cabecera de la sesion)
// La preferencia normal es CODIGO_ART > REF_PROVEEDOR. Si ASoloRefProveedor
// es True, solo se busca por REF_PROVEEDOR_AP del proveedor de cabecera.
// ACodigoArticuloPreferido desambigua referencias repetidas elegidas desde
// el desplegable de "Modelo prov.".
function ResolverDuplicadoSesion(AConn: TUniConnection;
                                  const ACodigoBuscado,
                                        ACodigoProveedor: string;
                                  ASoloRefProveedor: Boolean = False;
                                  const ACodigoArticuloPreferido: string = '')
                                  : TResolverDuplicadoSesion;

// Busca una linea anterior del MISMO documento de sesion que ya tenga el
// mismo modelo de proveedor o el mismo codigo de articulo. Se usa durante
// la edicion para copiar familia, descripcion, tallaje y precios antes de
// materializar, igual que si el articulo ya existiera en fza_articulos.
function ResolverDuplicadoIntraSesion(AConn: TUniConnection;
                                       const ASerieSes, ANumSes: string;
                                       ALineaActual: Integer;
                                       const AModelo, ACodigoArt: string)
                                       : TResolverDuplicadoSesion;

// Aplica el resultado de ResolverDuplicadoSesion a la linea de sesion
// activa (debe estar en dsEdit o dsInsert):
//   - ACCION_DUPLICADO_SESLIN = 'REUSAR'
//   - CODIGO_ART_REUSAR_SESLIN / CODIGO_ART_TENTATIVO_SESLIN = CodigoArt
//   - DESCRIPCION_SESLIN, CODIGO_FAM_SESLIN, ID_AC_PIVOT_SESLIN,
//     ID_VA_PIVOT_SESLIN, ID_AC_FILA_SESLIN, ID_VA_FILA_SESLIN,
//     TIPO_LINEA_SESLIN, TIPO_ART_SESLIN, ESTRAZABLE_SESLIN,
//     TIPO_IVA_SESLIN, TIPO_CANTIDAD_SESLIN, CODIGO_VAR_SESLIN,
//     PRECIO_COMPRA_SESLIN, PRECIO_VENTA_SESLIN, REF_PRV_SESLIN
//     (si el origen NO es REF y hay RefProveedor del proveedor de la
//     cabecera).
procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);

function ConsultarCodigosBasicosActivos(AConn: TUniConnection;
  const AIdVariacion: string): TArray<string>;
function ObtenerNombreFamiliaSesion(AConn: TUniConnection;
  const ACodigoFamilia: string): string;
procedure BorrarCeldasLineaSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
procedure CopiarCeldasDistribuidasSesion(AConn: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);

implementation

uses
  System.StrUtils,
  inLibComprasSesionesReglas,
  inLibMsgArticulos, inLibMsgCompras;

function ConsultarCodigosBasicosActivos(AConn: TUniConnection;
  const AIdVariacion: string): TArray<string>;
var
  Consulta: TUniQuery;
  iIndice: Integer;
begin
  Result := nil;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConn;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
      ' WHERE ID_VA_ATB = :va AND ESACTIVO_ATB = ''S'' ' +
      ' ORDER BY ORDEN_ATB, NOMBRE_ATB';
    Consulta.ParamByName('va').AsString := AIdVariacion;
    Consulta.Open;
    SetLength(Result, Consulta.RecordCount);
    iIndice := 0;
    while not Consulta.Eof do
    begin
      Result[iIndice] := Consulta.FieldByName('CODIGO_ATB').AsString;
      Inc(iIndice);
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function ObtenerNombreFamiliaSesion(AConn: TUniConnection;
  const ACodigoFamilia: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConn;
    Consulta.SQL.Text :=
      'SELECT NOMBRE_FAM_FAM FROM fza_articulos_familias ' +
      ' WHERE CODIGO_FAM_FAM = :codigo';
    Consulta.ParamByName('codigo').AsString := ACodigoFamilia;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('NOMBRE_FAM_FAM').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure BorrarCeldasLineaSesion(AConn: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConn;
    Consulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s ' +
      '   AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure CopiarCeldasDistribuidasSesion(AConn: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
var
  Consulta: TUniQuery;
  bTxOwned: Boolean;
begin
  bTxOwned := not AConn.InTransaction;
  if bTxOwned then
    AConn.StartTransaction;
  try
    BorrarCeldasLineaSesion(
      AConn, ASerie, ANumero, ALineaDestino);
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConn;
      Consulta.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, ' +
        '   LINEA_SES_SESCEL, ID_FILA_SES_SESCEL, ' +
        '   CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, ' +
        '   CANTIDAD_SESCEL, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'SELECT SERIE_SES_SESCEL, NUMERO_SES_SESCEL, :ldst, ' +
        '       ID_FILA_SES_SESCEL, ' +
        '       IFNULL(NULLIF(CODIGO_ALM_SESCEL, ''''), :alm_cab), ' +
        '       ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL, ' +
        '       NOW(), :u, NOW(), :u ' +
        '  FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s ' +
        '   AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :lsrc ' +
        '   AND CANTIDAD_SESCEL > 0';
      Consulta.ParamByName('s').AsString := ASerie;
      Consulta.ParamByName('n').AsString := ANumero;
      Consulta.ParamByName('lsrc').AsInteger := ALineaOrigen;
      Consulta.ParamByName('ldst').AsInteger := ALineaDestino;
      Consulta.ParamByName('alm_cab').AsString := AAlmacenCabecera;
      Consulta.ParamByName('u').AsString := AUsuario;
      Consulta.ExecSQL;
      Consulta.SQL.Text :=
        'UPDATE fza_compras_sesiones_lineas ' +
        '   SET TOTAL_UNIDADES_SESLIN = ' +
        '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
        '            FROM fza_compras_sesiones_celdas ' +
        '           WHERE SERIE_SES_SESCEL = :s ' +
        '             AND NUMERO_SES_SESCEL = :n ' +
        '             AND LINEA_SES_SESCEL = :l), ' +
        '       TOTAL_LINEA_SESLIN = ' +
        '         (SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) ' +
        '            FROM fza_compras_sesiones_celdas ' +
        '           WHERE SERIE_SES_SESCEL = :s ' +
        '             AND NUMERO_SES_SESCEL = :n ' +
        '             AND LINEA_SES_SESCEL = :l) * ' +
        '         PRECIO_COMPRA_SESLIN, ' +
        '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
        ' WHERE SERIE_SES_SESLIN = :s ' +
        '   AND NUMERO_SES_SESLIN = :n ' +
        '   AND LINEA_SESLIN = :l';
      Consulta.ParamByName('s').AsString := ASerie;
      Consulta.ParamByName('n').AsString := ANumero;
      Consulta.ParamByName('l').AsInteger := ALineaDestino;
      Consulta.ParamByName('u').AsString := AUsuario;
      Consulta.ExecSQL;
    finally
      FreeAndNil(Consulta);
    end;
    if bTxOwned and AConn.InTransaction then
      AConn.Commit;
  except
    if bTxOwned and AConn.InTransaction then
      AConn.Rollback;
    raise;
  end;
end;
function ValidarKitSobreLineaActual(ADM: TdmComprasSesiones;
                                     const ACodigoPrv, ACodigoKit: string;
                                     out AResumen: string): Boolean;
var
  q       : TUniQuery;
  iLinea  : Integer;
  iAc     : Integer;
  iAcKit  : Integer;
  sNomKit : string;
  sNomLin : string;
begin
  Result   := False;
  AResumen := '';
  if (ADM = nil) or ADM.unqryTablaG.IsEmpty then
    AResumen := SErrorSesionCompraNoActiva
  else if ADM.unqrySesionLin.IsEmpty then
    AResumen := SErrorLineaArticuloSesionNoSeleccionada
  else
  begin
    iLinea := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    iAc    := ADM.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    if iLinea <= 0 then
      AResumen := SErrorLineaSesionSinNumero
    else if iAc <= 0 then
      AResumen := SErrorSistemaTallasLineaSesionObligatorio
    else
    begin
      // El tallaje del kit DEBE coincidir con el de la linea; si no, se
      // advierte y no se aplica nada (evita volcar curvas de un sistema
      // sobre otro aunque compartan algun valor de talla).
      q := TUniQuery.Create(nil);
      try
        q.Connection := ADM.ConexionPrincipal;
        q.SQL.Text :=
          'SELECT K.ID_AC_TALLAS_PRVKIT, ' +
          '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
          '    WHERE ID_AC = K.ID_AC_TALLAS_PRVKIT) AS NOMBRE_TALLAS_KIT, ' +
          '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
          '    WHERE ID_AC = :ac) AS NOMBRE_TALLAS_LIN ' +
          '  FROM fza_proveedores_kits K ' +
          ' WHERE K.CODIGO_PRV_PRVKIT = :prv ' +
          '   AND K.CODIGO_PRVKIT = :kit';
        q.ParamByName('ac').AsInteger := iAc;
        q.ParamByName('prv').AsString := ACodigoPrv;
        q.ParamByName('kit').AsString := ACodigoKit;
        q.Open;
        if q.IsEmpty then
          AResumen := Format(SErrorKitProveedorNoExiste,
                             [ACodigoKit, ACodigoPrv])
        else
        begin
          iAcKit  := q.FieldByName('ID_AC_TALLAS_PRVKIT').AsInteger;
          sNomKit := Trim(q.FieldByName('NOMBRE_TALLAS_KIT').AsString);
          sNomLin := Trim(q.FieldByName('NOMBRE_TALLAS_LIN').AsString);
          if sNomKit = '' then
            sNomKit := IntToStr(iAcKit);
          if sNomLin = '' then
            sNomLin := IntToStr(iAc);
          if iAcKit <= 0 then
            AResumen := Format(SErrorKitSinSistemaTallas, [ACodigoKit])
          else if iAcKit <> iAc then
            AResumen := Format(SErrorTallajeKitNoCoincide,
              [sNomKit, sNomLin])
          else
            Result := True;
        end;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

function AplicarKitProveedorALinea(ADM: TdmComprasSesiones;
                                    AGestor: TGestorGridTallas;
                                    const ACodigoPrv, ACodigoKit: string;
                                    out AResumen: string): Boolean;
var
  q          : TUniQuery;
  arr        : TArrPosConjunto;
  iLinea     : Integer;
  iAc        : Integer;
  i          : Integer;
  bCasada    : Boolean;
  iAplicadas : Integer;
  sValor     : string;
  rCant      : Double;
  sSinCasar  : string;
begin
  Result   := False;
  AResumen := '';
  if AGestor = nil then
    AResumen := SErrorGestorTallasNoInicializado
  else if ValidarKitSobreLineaActual(ADM, ACodigoPrv, ACodigoKit,
                                     AResumen) then
  begin
    iLinea     := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    iAc        := ADM.unqrySesionLin.FieldByName(
                                            'ID_AC_PIVOT_SESLIN').AsInteger;
    arr        := AGestor.GetPosicionesConjunto(iAc);
    iAplicadas := 0;
    sSinCasar  := '';
    q := TUniQuery.Create(nil);
    try
      q.Connection := ADM.ConexionPrincipal;
      q.SQL.Text :=
        'SELECT VALOR_DESTINO_PRVKITD, CANTIDAD_PRVKITD ' +
        '  FROM fza_proveedores_kits_det ' +
        ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
        '   AND CODIGO_PRVKIT_PRVKITD = :kit ' +
        ' ORDER BY ORDEN_PRVKITD, VALOR_DESTINO_PRVKITD';
      q.ParamByName('prv').AsString := ACodigoPrv;
      q.ParamByName('kit').AsString := ACodigoKit;
      q.Open;
      if q.IsEmpty then
        AResumen := Format(SErrorKitSinTallasDefinidas, [ACodigoKit])
      else
      begin
        while not q.Eof do
        begin
          sValor  := Trim(q.FieldByName('VALOR_DESTINO_PRVKITD').AsString);
          rCant   := q.FieldByName('CANTIDAD_PRVKITD').AsFloat;
          bCasada := False;
          // El tallaje ya se ha validado; el casado por texto mapea
          // cada talla del kit a su columna (ID_AV) en la linea.
          for i := 0 to High(arr) do
          begin
            if SameText(Trim(arr[i].Valor), sValor) then
            begin
              AGestor.PersistirCantidad(iLinea, arr[i].IdAv, rCant);
              bCasada := True;
              Inc(iAplicadas);
              Break;
            end;
          end;
          if (not bCasada) and (rCant > 0) then
          begin
            if sSinCasar <> '' then
              sSinCasar := sSinCasar + ', ';
            sSinCasar := sSinCasar + Format('%s (%g)', [sValor, rCant]);
          end;
          q.Next;
        end;
      end;
    finally
      FreeAndNil(q);
    end;
    if iAplicadas > 0 then
    begin
      Result := True;
      if sSinCasar <> '' then
        AResumen := Format(SAvisoTallasKitSinCorrespondencia, [sSinCasar]);
    end
    else if AResumen = '' then
      AResumen := SErrorTallasKitSinCorrespondencia;
  end;
end;

function ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;
var
  inc: TStringList;
begin
  // ValidarSesion (legacy) ahora delega en el validador detallado y
  // devuelve solo la primera incidencia como string. El form prefiere
  // llamar a ValidarSesionDetallado para mostrar todas.
  inc := TStringList.Create;
  try
    Result := ValidarSesionDetallado(ADM, inc);
    if Result then AError := ''
    else if inc.Count > 0 then AError := inc[0]
    else AError := SErrorSesionIncidenciasSinDetalle;
  finally
    FreeAndNil(inc);
  end;
end;

function ValidarSesionDetallado(ADM: TdmComprasSesiones;
                                 AIncidencias: TStrings): Boolean;
var
  q: TUniQuery;
  sSerie, sNum: string;

  procedure AnadirInc(const ALinea: Integer;
                       const ATipo, AMensaje: string);
  var
    sLin: string;
  begin
    if ALinea > 0 then sLin := Format(STextoLineaIncidenciaSesion, [ALinea])
    else sLin := STextoCabeceraIncidenciaSesion;
    AIncidencias.Add(Format(SFormatoIncidenciaSesion,
      [ATipo, sLin, AMensaje]));
  end;

begin
  Result := True;
  if AIncidencias = nil then Exit;
  AIncidencias.Clear;
  if ADM.unqryTablaG.IsEmpty then
  begin
    AIncidencias.Add(SErrorSesionInactivaIncidencia);
    Exit(False);
  end;

  sSerie := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNum   := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;

  // ---- Cabecera ----
  if Trim(ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString) = '' then
    AnadirInc(0, STipoIncidenciaCabecera, SErrorEmpresaSesionFaltante);
  if Trim(ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString) = '' then
    AnadirInc(0, STipoIncidenciaCabecera, SErrorProveedorSesionFaltante);
  // Si la cabecera marca generar albaran, exigimos almacen
  if (ADM.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S')
     and (Trim(ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString) = '')
  then
    AnadirInc(0, STipoIncidenciaCabecera,
        SErrorAlmacenSesionFaltante);

  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;

    // ---- Hay al menos una linea ----
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      AnadirInc(0, STipoIncidenciaCabecera, SErrorSesionSinLineas);
    q.Close;

    // ---- Duplicados intra-sesion sin resolver (mismo CODIGO_ART_TENTATIVO
    //      en >1 lineas, alguna sin ACCION=REUSAR). La materializacion
    //      reventaria al hacer INSERT del segundo articulo con la misma
    //      PK CODIGO_ART_ART. El form auto-normaliza con
    //      NormalizarDuplicadosIntraSesion antes de validar, asi que esto
    //      es defensivo: si por algun camino llega sin normalizar, lo
    //      detectamos aqui antes que MySQL.
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       G.PRIMERA, G.N ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN (SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '               CODIGO_ART_TENTATIVO_SESLIN, ' +
      '               MIN(LINEA_SESLIN) AS PRIMERA, ' +
      '               COUNT(*)          AS N ' +
      '          FROM fza_compras_sesiones_lineas ' +
      '         WHERE SERIE_SES_SESLIN = :s ' +
      '           AND NUMERO_SES_SESLIN = :n ' +
      '           AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
      '           AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '         GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '                  CODIGO_ART_TENTATIVO_SESLIN ' +
      '        HAVING COUNT(*) > 1) AS G ' +
      '    ON G.SERIE_SES_SESLIN            = L.SERIE_SES_SESLIN ' +
      '   AND G.NUMERO_SES_SESLIN           = L.NUMERO_SES_SESLIN ' +
      '   AND G.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      ' WHERE L.SERIE_SES_SESLIN  = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'') ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicadoInterno,
          Format(SErrorCodigoDuplicadoInternoSesion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  q.FieldByName('PRIMERA').AsInteger]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas con codigo duplicado externo sin accion resuelta
    //      (CODIGO_ART_TENTATIVO ya existe en fza_articulos y el usuario
    //      no eligio REUSAR ni RENOMBRAR). ----
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN, ' +
      '       A.ESACTIVO_ART ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  LEFT JOIN fza_articulos A ' +
      '         ON A.CODIGO_ART_ART = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.ESDUPLICADO_SESLIN = ''S'' ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''') ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicado,
          Format(SErrorCodigoDuplicadoSesion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  IfThen(q.FieldByName('ESACTIVO_ART').AsString = 'N',
                         STextoArticuloInactivoSesion, '')]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas sin CODIGO_ART_TENTATIVO_SESLIN ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (CODIGO_ART_TENTATIVO_SESLIN IS NULL ' +
      '        OR TRIM(CODIGO_ART_TENTATIVO_SESLIN) = '''') ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCodigo,
          SErrorLineaSesionSinCodigo);
      q.Next;
    end;
    q.Close;

    // ---- Lineas sin descripcion ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (DESCRIPCION_SESLIN IS NULL ' +
      '        OR TRIM(DESCRIPCION_SESLIN) = '''') ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDescripcion,
          Format(SErrorLineaSesionSinDescripcion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas MATRIZ sin celdas con cantidad > 0 ----
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_celdas C ' +
      '                    WHERE C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
      '                      AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
      '                      AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
      '                      AND C.CANTIDAD_SESCEL > 0) ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCantidades,
          Format(SErrorLineaMatrizSinCantidades,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  q.FieldByName('DESCRIPCION_SESLIN').AsString]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas MATRIZ sin ID_AC_PIVOT (sistema de tallas) ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '   AND (ID_AC_PIVOT_SESLIN IS NULL OR ID_AC_PIVOT_SESLIN = 0) ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaSistemaTallas,
          Format(SErrorLineaMatrizSinSistemaTallas,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString]));
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;

  Result := AIncidencias.Count = 0;
end;
// Resolver codigo de familia -> codigo de articulo autogenerado
// ---------------------------------------------------------------------------

function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;
begin
  Result := inLibComprasSesionesReglas.ResolverCodigoFamilia(
    AConn, ACodigoTecleado, AUsuario, ACodigoGenerado);
end;

// ---------------------------------------------------------------------------
// Reutilizacion de articulos ya existentes (ACCION_DUPLICADO=REUSAR)
// ---------------------------------------------------------------------------

function ResolverDuplicadoSesion(AConn: TUniConnection;
                                  const ACodigoBuscado,
                                        ACodigoProveedor: string;
                                  ASoloRefProveedor: Boolean;
                                  const ACodigoArticuloPreferido: string)
                                  : TResolverDuplicadoSesion;
var
  q          : TUniQuery;
  sCod       : string;
  sPrv       : string;
  sCodArtPref: string;
begin
  // El registro empieza a cero (Encontrado=False).
  Result := Default(TResolverDuplicadoSesion);
  sCod := Trim(ACodigoBuscado);
  sPrv := Trim(ACodigoProveedor);
  sCodArtPref := Trim(ACodigoArticuloPreferido);
  if sCod = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Match exacto por CODIGO_ART_ART. Trae todos los campos que
    //    necesitamos para inicializar la linea.
    if not ASoloRefProveedor then
    begin
      q.SQL.Text :=
        'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
        '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
        '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
        '       a.TIPO_VARIACION_ART, ' +
        '       f.NOMBRE_FAM_FAM, ' +
        '       (SELECT aca.ID_AC_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA = ''TAL'' ' +
        '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
        '       (SELECT aca.ID_VA_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA = ''TAL'' ' +
        '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
        '       (SELECT aca.ID_AC_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_AC_FILA, ' +
        '       (SELECT aca.ID_VA_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_VA_FILA, ' +
        '       (SELECT ap.PRECIO_ULT_COMPRA_AP ' +
        '          FROM fza_articulos_proveedores ap ' +
        '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
        '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
        '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
        '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
        '         AS PRECIO_ULT_COMPRA, ' +
        '       (SELECT ap.REF_PROVEEDOR_AP ' +
        '          FROM fza_articulos_proveedores ap ' +
        '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
        '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
        '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
        '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
        '         AS REF_PROVEEDOR ' +
        '  FROM fza_articulos a ' +
        '  LEFT JOIN fza_articulos_familias f ' +
        '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
        ' WHERE a.CODIGO_ART_ART = :art ' +
        '   AND a.ESACTIVO_ART = ''S''';
      q.ParamByName('art').AsString := sCod;
      q.ParamByName('prv').AsString := sPrv;
      q.Open;
      if not q.IsEmpty then
      begin
        Result.Encontrado     := True;
        Result.Origen         := 'ART';
        Result.CodigoArt      := q.FieldByName('CODIGO_ART_ART').AsString;
        Result.DescripcionArt := q.FieldByName('DESCRIPCION_ART').AsString;
        Result.CodigoFam      := q.FieldByName('CODIGO_FAM_ART').AsString;
        Result.NombreFam      := q.FieldByName('NOMBRE_FAM_FAM').AsString;
        Result.IdAcPivot      := q.FieldByName('ID_AC_PIVOT').AsInteger;
        Result.IdVaPivot      := q.FieldByName('ID_VA_PIVOT').AsString;
        Result.IdAcFila       := q.FieldByName('ID_AC_FILA').AsInteger;
        Result.IdVaFila       := q.FieldByName('ID_VA_FILA').AsString;
        Result.TipoVariacion  :=
          q.FieldByName('TIPO_VARIACION_ART').AsString;
        Result.EsVariacion    :=
          q.FieldByName('ESVARIACION_ART').AsString = 'S';
        Result.EsTrazable     :=
          q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        Result.TipoArt        := q.FieldByName('TIPO_ART').AsString;
        Result.TipoIva        := q.FieldByName('TIPO_IVA_ART').AsString;
        Result.TipoCantidad   := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
        Result.UltimoCoste    := q.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
        Result.RefProveedor   := q.FieldByName('REF_PROVEEDOR').AsString;
        Exit;
      end;
      q.Close;
    end;

    if sPrv = '' then Exit;

    // 2. Match por REF_PROVEEDOR_AP del proveedor de la cabecera. Si hay
    //    multiples articulos con la misma referencia para el mismo
    //    proveedor (no esta forzado por PK), el codigo elegido desde el
    //    desplegable desambigua. Si no viene, tomamos el principal o el
    //    primero por orden alfabetico.
    q.SQL.Text :=
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
      '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
      '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
      '       a.TIPO_VARIACION_ART, ' +
      '       f.NOMBRE_FAM_FAM, ' +
      '       ap.PRECIO_ULT_COMPRA_AP AS PRECIO_ULT_COMPRA, ' +
      '       ap.REF_PROVEEDOR_AP    AS REF_PROVEEDOR, ' +
      '       (SELECT aca.ID_AC_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '           AND aca.ID_VA_ACA = ''TAL'' ' +
      '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
      '       (SELECT aca.ID_VA_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '           AND aca.ID_VA_ACA = ''TAL'' ' +
      '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
      '       (SELECT aca.ID_AC_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '            AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_AC_FILA, ' +
      '       (SELECT aca.ID_VA_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '            AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_VA_FILA ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
      '                       AND a.ESACTIVO_ART = ''S'' ' +
      '  LEFT JOIN fza_articulos_familias f ' +
      '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
      ' WHERE ap.CODIGO_PRV_AP    = :prv ' +
      '   AND ap.REF_PROVEEDOR_AP = :ref ' +
      '   AND (:artpref = '''' OR ap.CODIGO_ART_AP = :artpref) ' +
      ' ORDER BY (ap.CODIGO_ART_AP = :artpref) DESC, ' +
      '          ap.ESPROVEEDORPRINCIPAL_AP DESC, a.CODIGO_ART_ART ' +
      ' LIMIT 1';
    q.ParamByName('prv').AsString := sPrv;
    q.ParamByName('ref').AsString := sCod;
    q.ParamByName('artpref').AsString := sCodArtPref;
    q.Open;
    if q.IsEmpty then Exit;

    Result.Encontrado     := True;
    Result.Origen         := 'REF';
    Result.CodigoArt      := q.FieldByName('CODIGO_ART_ART').AsString;
    Result.DescripcionArt := q.FieldByName('DESCRIPCION_ART').AsString;
    Result.CodigoFam      := q.FieldByName('CODIGO_FAM_ART').AsString;
    Result.NombreFam      := q.FieldByName('NOMBRE_FAM_FAM').AsString;
    Result.IdAcPivot      := q.FieldByName('ID_AC_PIVOT').AsInteger;
    Result.IdVaPivot      := q.FieldByName('ID_VA_PIVOT').AsString;
    Result.IdAcFila       := q.FieldByName('ID_AC_FILA').AsInteger;
    Result.IdVaFila       := q.FieldByName('ID_VA_FILA').AsString;
    Result.TipoVariacion  := q.FieldByName('TIPO_VARIACION_ART').AsString;
    Result.EsVariacion    :=
                        q.FieldByName('ESVARIACION_ART').AsString = 'S';
    Result.EsTrazable     :=
                        q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
    Result.TipoArt        := q.FieldByName('TIPO_ART').AsString;
    Result.TipoIva        := q.FieldByName('TIPO_IVA_ART').AsString;
    Result.TipoCantidad   := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
    Result.UltimoCoste    := q.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
    Result.RefProveedor   := q.FieldByName('REF_PROVEEDOR').AsString;
  finally
    FreeAndNil(q);
  end;
end;

function ResolverDuplicadoIntraSesion(AConn: TUniConnection;
                                       const ASerieSes, ANumSes: string;
                                       ALineaActual: Integer;
                                       const AModelo, ACodigoArt: string)
                                       : TResolverDuplicadoSesion;
var
  q       : TUniQuery;
  sSerie  : string;
  sNumero : string;
  sModelo : string;
  sCodigo : string;
begin
  Result := Default(TResolverDuplicadoSesion);
  sSerie := Trim(ASerieSes);
  sNumero := Trim(ANumSes);
  sModelo := Trim(AModelo);
  sCodigo := Trim(ACodigoArt);
  if AConn = nil then
    Exit;
  if (sSerie = '') or (sNumero = '') then
    Exit;
  if (sModelo = '') and (sCodigo = '') then
    Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN, L.CODIGO_FAM_SESLIN, ' +
      '       L.TIPO_LINEA_SESLIN, L.TIPO_ART_SESLIN, ' +
      '       L.TIPO_IVA_SESLIN, L.TIPO_CANTIDAD_SESLIN, ' +
      '       L.ESTRAZABLE_SESLIN, L.CODIGO_VAR_SESLIN, ' +
      '       L.ID_VA_PIVOT_SESLIN, L.ID_AC_PIVOT_SESLIN, ' +
      '       L.ID_VA_FILA_SESLIN, L.ID_AC_FILA_SESLIN, ' +
      '       L.PRECIO_COMPRA_SESLIN, L.PRECIO_VENTA_SESLIN, ' +
      '       L.REF_PRV_SESLIN, L.LINEA_SESLIN, ' +
      '       L.COLOR_TEXTO_SESLIN, L.CODIGO_ATB_COLOR_SESLIN, ' +
      '       L.PORCENTAJE_MARGEN_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      ' WHERE L.SERIE_SES_SESLIN = :serie ' +
      '   AND L.NUMERO_SES_SESLIN = :numero ' +
      '   AND L.LINEA_SESLIN <> :linea ' +
      '   AND TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '   AND ((:modelo <> '''' ' +
      '         AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
      '        OR (:codigo <> '''' ' +
      '            AND (TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) = :codigo ' +
      '                 OR TRIM(COALESCE(L.CODIGO_ART_REUSAR_SESLIN, '''')) ' +
      '                    = :codigo))) ' +
      ' ORDER BY CASE WHEN (:modelo <> '''' ' +
      '                 AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
      '               THEN 0 ELSE 1 END, ' +
      '          L.LINEA_SESLIN ' +
      ' LIMIT 1';
    q.ParamByName('serie').AsString := sSerie;
    q.ParamByName('numero').AsString := sNumero;
    q.ParamByName('linea').AsInteger := ALineaActual;
    q.ParamByName('modelo').AsString := sModelo;
    q.ParamByName('codigo').AsString := sCodigo;
    q.Open;
    if q.IsEmpty then
      Exit;
    Result.Encontrado := True;
    Result.Origen := 'SES';
    Result.CodigoArt :=
      q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
    Result.DescripcionArt := q.FieldByName('DESCRIPCION_SESLIN').AsString;
    Result.CodigoFam := q.FieldByName('CODIGO_FAM_SESLIN').AsString;
    Result.IdAcPivot := q.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    Result.IdVaPivot := q.FieldByName('ID_VA_PIVOT_SESLIN').AsString;
    Result.IdAcFila := q.FieldByName('ID_AC_FILA_SESLIN').AsInteger;
    Result.IdVaFila := q.FieldByName('ID_VA_FILA_SESLIN').AsString;
    Result.TipoVariacion := q.FieldByName('CODIGO_VAR_SESLIN').AsString;
    Result.TipoArt := q.FieldByName('TIPO_ART_SESLIN').AsString;
    Result.TipoIva := q.FieldByName('TIPO_IVA_SESLIN').AsString;
    Result.TipoCantidad := q.FieldByName('TIPO_CANTIDAD_SESLIN').AsString;
    Result.EsTrazable := q.FieldByName('ESTRAZABLE_SESLIN').AsString = 'S';
    Result.EsVariacion :=
      SameText(q.FieldByName('TIPO_LINEA_SESLIN').AsString, 'MATRIZ');
    Result.UltimoCoste := q.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
    Result.PrecioVenta := q.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
    Result.RefProveedor := q.FieldByName('REF_PRV_SESLIN').AsString;
    // Datos extra de la linea origen para la copia completa opcional.
    Result.LineaOrigen := q.FieldByName('LINEA_SESLIN').AsInteger;
    Result.ColorTexto := q.FieldByName('COLOR_TEXTO_SESLIN').AsString;
    Result.CodigoAtbColor :=
      q.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
    Result.MargenPorcentaje :=
      q.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

// Devuelve el PVP "padre" (CODIGO_UNIDAD_ARTTAR='') del articulo en la
// tarifa indicada; si no hay tarifa o esa fila no existe, cae a cualquier
// tarifa activa del articulo. 0 si el articulo no tiene tarifa. Se usa para
// proponer en la linea el PVP anterior como referencia al reusar un modelo
// ya existente (el usuario solo lo cambia si el documento trae otro precio).
function ObtenerPvpArticulo(AConn: TUniConnection;
                            const ACodArt, ACodTar: string): Double;
var
  q: TUniQuery;
begin
  Result := 0;
  if Trim(ACodArt) = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT t.PRECIO_FINAL_ARTTAR ' +
      '  FROM fza_articulos_tarifas t ' +
      ' WHERE t.CODIGO_ART_ARTTAR    = :art ' +
      '   AND t.CODIGO_UNIDAD_ARTTAR = '''' ' +
      '   AND (t.ESACTIVO_ARTTAR = ''S'' ' +
      '        OR t.CODIGO_TAR_ARTTAR = :tar) ' +
      ' ORDER BY (t.CODIGO_TAR_ARTTAR = :tar) DESC, ' +
      '          t.ESACTIVO_ARTTAR DESC, ' +
      '          t.FECHA_DESDE_ARTTAR DESC, ' +
      '          t.CODIGO_UNICO_ARTTAR DESC ' +
      ' LIMIT 1';
    q.ParamByName('art').AsString := ACodArt;
    q.ParamByName('tar').AsString := ACodTar;
    q.Open;
    if not q.IsEmpty then
      Result := q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);
var
  ds: TDataSet;
  sTipoLinea: string;
  sTar: string;
  rPvp: Double;
begin
  if not AResul.Encontrado then Exit;
  if ADM = nil then Exit;
  ds := ADM.unqrySesionLin;
  if ds = nil then Exit;
  if ds.IsEmpty then Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;

  // Marca REUSAR + codigo del articulo a reutilizar.
  ds.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
  ds.FieldByName('ACCION_DUPLICADO_SESLIN').AsString  := 'REUSAR';
  ds.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString := AResul.CodigoArt;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := AResul.CodigoArt;

  // Datos del articulo. No machacamos descripcion si el usuario ya
  // tecleo algo (>0 caracteres distinto) — pero al ser REUSAR del
  // mismo articulo, la descripcion oficial es la del maestro: la
  // sobrescribimos siempre.
  ds.FieldByName('DESCRIPCION_SESLIN').AsString := AResul.DescripcionArt;
  if AResul.CodigoFam <> '' then
    ds.FieldByName('CODIGO_FAM_SESLIN').AsString := AResul.CodigoFam;
  if AResul.TipoArt <> '' then
    ds.FieldByName('TIPO_ART_SESLIN').AsString := AResul.TipoArt;
  if AResul.TipoIva <> '' then
    ds.FieldByName('TIPO_IVA_SESLIN').AsString := AResul.TipoIva;
  if AResul.TipoCantidad <> '' then
    ds.FieldByName('TIPO_CANTIDAD_SESLIN').AsString := AResul.TipoCantidad;
  if AResul.TipoVariacion <> '' then
    ds.FieldByName('CODIGO_VAR_SESLIN').AsString := AResul.TipoVariacion;
  ds.FieldByName('ESTRAZABLE_SESLIN').AsString :=
                                 IfThen(AResul.EsTrazable, 'S', 'N');

  // TIPO_LINEA segun ESVARIACION.
  if AResul.EsVariacion then sTipoLinea := 'MATRIZ' else sTipoLinea := 'ESCALAR';
  ds.FieldByName('TIPO_LINEA_SESLIN').AsString := sTipoLinea;

  // Ejes de variacion (pivot=tallas, fila=color).
  if AResul.IdAcPivot > 0 then
    ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := AResul.IdAcPivot;
  if AResul.IdVaPivot <> '' then
    ds.FieldByName('ID_VA_PIVOT_SESLIN').AsString := AResul.IdVaPivot;
  if AResul.IdAcFila > 0 then
    ds.FieldByName('ID_AC_FILA_SESLIN').AsInteger := AResul.IdAcFila;
  if AResul.IdVaFila <> '' then
    ds.FieldByName('ID_VA_FILA_SESLIN').AsString := AResul.IdVaFila;

  // Coste del proveedor del modelo resuelto. Se sobrescribe siempre para
  // no dejar valores de un modelo anterior en la misma linea.
  ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := AResul.UltimoCoste;

  // PVP de referencia: precio de la tarifa de venta de la cabecera para el
  // articulo reusado. Tambien se sobrescribe siempre para que al cambiar
  // de modelo no sobreviva el precio del articulo anterior.
  if AResul.Origen = 'SES' then
    ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := AResul.PrecioVenta
  else
  begin
    sTar := '';
    rPvp := 0;
    if (ADM.unqryTablaG <> nil) and (not ADM.unqryTablaG.IsEmpty) then
    begin
      sTar := Trim(ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString);
      rPvp := ObtenerPvpArticulo(ADM.unqryTablaG.Connection,
                                 AResul.CodigoArt, sTar);
    end;
    ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := rPvp;
  end;

  // Si el match vino por CODIGO_ART y conocemos la REF del proveedor
  // de la cabecera, rellenamos REF_PRV_SESLIN para la traza.
  // Si el match vino por REF, el campo ya lleva lo que el usuario
  // tecleo (y coincide con lo que hay en la BBDD).
  if (AResul.Origen = 'ART') and (AResul.RefProveedor <> '') and
     (Trim(ds.FieldByName('REF_PRV_SESLIN').AsString) = '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
  if (AResul.Origen = 'SES') and (AResul.RefProveedor <> '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
end;

function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;
var
  q : TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // Para cada (CODIGO_ART_TENTATIVO_SESLIN) que aparece >1 veces en la
    // sesion, dejamos la primera linea (LINEA_SESLIN minimo) intacta y
    // marcamos el resto como REUSAR del mismo codigo. Asi InsertarArticulo
    // solo se ejecuta una vez por codigo durante la materializacion y las
    // demas lineas (variantes color/SKU) comparten la cabecera del
    // articulo en fza_articulos.
    //
    // Solo tocamos lineas que NO tienen ACCION_DUPLICADO ya resuelta
    // (NULL / vacia / distinta de REUSAR) — respetamos elecciones del
    // usuario (p. ej. si decidio RENOMBRAR alguna ya estara con su
    // codigo final distinto, no entra en este grupo).
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones_lineas L ' +
      '  JOIN ( ' +
      '       SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '              CODIGO_ART_TENTATIVO_SESLIN, ' +
      '              MIN(LINEA_SESLIN) AS PRIMERA, ' +
      '              COUNT(*)          AS N ' +
      '         FROM fza_compras_sesiones_lineas ' +
      '        WHERE SERIE_SES_SESLIN = :s ' +
      '          AND NUMERO_SES_SESLIN = :n ' +
      '          AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
      '          AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '        GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '                 CODIGO_ART_TENTATIVO_SESLIN ' +
      '       HAVING COUNT(*) > 1 ' +
      '  ) AS G ' +
      '    ON G.SERIE_SES_SESLIN            = L.SERIE_SES_SESLIN ' +
      '   AND G.NUMERO_SES_SESLIN           = L.NUMERO_SES_SESLIN ' +
      '   AND G.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      '   SET L.ESDUPLICADO_SESLIN       = ''S'', ' +
      '       L.ACCION_DUPLICADO_SESLIN  = ''REUSAR'', ' +
      '       L.CODIGO_ART_REUSAR_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.USUARIO_MODIF            = :u, ' +
      '       L.INSTANTE_MODIF           = NOW() ' +
      ' WHERE L.SERIE_SES_SESLIN  = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
    q.ParamByName('s').AsString := ASerieSes;
    q.ParamByName('n').AsString := ANumSes;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
    Result := q.RowsAffected;
  finally
    FreeAndNil(q);
  end;
end;

end.
