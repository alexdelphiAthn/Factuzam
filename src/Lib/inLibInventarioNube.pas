{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventarioNube                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente del servidor de recuentos (PHP) desde Factuzam. Gemelo de         }
{    inLibFotosNube: THTTPClient + System.JSON, X-API-Key + carpeta_cliente,   }
{    parámetros comunes de la categoría "Servicios web".                      }
{      - EnviarInventario: manda la plantilla (cabecera + líneas + códigos de  }
{        barras) a inv_enviar.php. Devuelve el id_recuento del servidor.       }
{      - RecogerRecuento: trae los eventos de inv_recoger.php, los inserta en  }
{        fza_inventarios_recuentos (INVREC, idempotente por UUID) y devuelve   }
{        el agregado SKU=CANTIDAD para que el Mto lo cargue como físicas.       }
{******************************************************************************}
unit inLibInventarioNube;

interface

uses
  System.SysUtils, System.Classes, Uni, inLibParametrosIntf;

function InventarioNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;

function EnviarInventario(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AEmp, AAlm, ASerie, ANumero, ADescripcion, AModo: string;
  out AIdRecuento: Int64; out AMensaje: string): Boolean;

// Recoge el recuento del servidor: inserta los eventos en INVREC y deja en
// AAgregado la lista 'SKU=CANTIDAD' (lo que el Mto pasa a CargarDesdeListaSkus
// para rellenar CANTIDAD_FISICA_INVLIN). ANumEventos = eventos insertados.
function RecogerRecuento(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AEmp, AAlm, ASerie, ANumero, AUsuario: string; AIdRecuento: Int64;
  AAgregado: TStringList; out ANumEventos: Integer;
  out AMensaje: string): Boolean;

implementation

uses
  System.JSON, System.Generics.Collections, System.NetEncoding,
  System.Net.HttpClient, System.Net.URLClient,
  Data.DB,
  inLibFactuzamApi, inLibMsgArticulos;

// ============================================================================
//   Configuración y transporte
// ============================================================================

function InventarioNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
var
  faltan: TStringList;
begin
  AMensaje := '';
  faltan := TStringList.Create;
  try
    if TClienteFactuzamApi.UrlBase(AParametrosApp) = '' then
      faltan.Add(STextoParametroUrlInventarioNube);
    if TClienteFactuzamApi.Token(AParametrosApp) = '' then
      faltan.Add(STextoParametroTokenInventarioNube);
    if TClienteFactuzamApi.Referencia(AParametrosApp) = '' then
      faltan.Add(STextoParametroReferenciaInventarioNube);
    Result := faltan.Count = 0;
    if not Result then
      AMensaje := Format(SErrorParametrosInventarioNubeFaltantes,
        [faltan.Text]);
  finally
    FreeAndNil(faltan);
  end;
end;

function LeerStream(AStream: TStream): string;
var
  oSS: TStringStream;
begin
  oSS := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    if AStream.Size > 0 then
      oSS.CopyFrom(AStream, AStream.Size);
    Result := oSS.DataString;
  finally
    FreeAndNil(oSS);
  end;
end;

function MensajeError(const ABody: string; AStatus: Integer): string;
var
  jval, jmsg: TJSONValue;
begin
  Result := '';
  jval := TJSONObject.ParseJSONValue(ABody);
  try
    if jval <> nil then
    begin
      jmsg := jval.FindValue('message');
      if jmsg <> nil then
        Result := jmsg.Value;
    end;
  finally
    FreeAndNil(jval);
  end;
  if Result = '' then
    Result := Format(SErrorServidorInventarioNubeHttp, [AStatus]);
end;

function PostNube(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, ABody: string;
  out ARespuesta: string;
  out AMensaje: string): Integer;
var
  http: THTTPClient;
  req: TStringStream;
  resp: TMemoryStream;
  respHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  http := THTTPClient.Create;
  req := TStringStream.Create(ABody, TEncoding.UTF8);
  resp := TMemoryStream.Create;
  try
    http.CustomHeaders['X-API-Key'] :=
      TClienteFactuzamApi.Token(AParametrosApp);
    http.CustomHeaders['Content-Type'] := 'application/json';
    try
      respHttp := http.Post(
        TClienteFactuzamApi.ComponerUrl(AParametrosApp, ARuta),
        req,
        resp);
      Result := respHttp.StatusCode;
      ARespuesta := LeerStream(resp);
    except
      on E: Exception do
        AMensaje := Format(SErrorConexionServidorInventarioNube,
          [E.Message]);
    end;
  finally
    FreeAndNil(resp);
    FreeAndNil(req);
    FreeAndNil(http);
  end;
end;

function GetNube(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta: string;
  out ARespuesta: string;
  out AMensaje: string): Integer;
var
  http: THTTPClient;
  resp: TMemoryStream;
  respHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  http := THTTPClient.Create;
  resp := TMemoryStream.Create;
  try
    http.CustomHeaders['X-API-Key'] :=
      TClienteFactuzamApi.Token(AParametrosApp);
    try
      respHttp := http.Get(
        TClienteFactuzamApi.ComponerUrl(AParametrosApp, ARuta),
        resp);
      Result := respHttp.StatusCode;
      ARespuesta := LeerStream(resp);
    except
      on E: Exception do
        AMensaje := Format(SErrorConexionServidorInventarioNube,
          [E.Message]);
    end;
  finally
    FreeAndNil(resp);
    FreeAndNil(http);
  end;
end;

// ============================================================================
//   Enviar inventario (plantilla)
// ============================================================================

function EnviarInventario(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AEmp, AAlm, ASerie, ANumero, ADescripcion, AModo: string;
  out AIdRecuento: Int64; out AMensaje: string): Boolean;
var
  qry: TUniQuery;
  root, linea: TJSONObject;
  arr: TJSONArray;
  sBody, sResp: string;
  iStatus: Integer;
  respJson: TJSONValue;
begin
  Result := False;
  AIdRecuento := 0;
  AMensaje := '';
  if InventarioNubeConfigurado(AParametrosApp, AMensaje) then
  begin
    root := TJSONObject.Create;
    qry := TUniQuery.Create(nil);
    try
      root.AddPair(
        'carpeta_cliente',
        TClienteFactuzamApi.Referencia(AParametrosApp));
      root.AddPair('codigo_emp', AEmp);
      root.AddPair('codigo_alm', AAlm);
      root.AddPair('serie', ASerie);
      root.AddPair('numero', ANumero);
      root.AddPair('descripcion', ADescripcion);
      root.AddPair('modo', AModo);
      // Una fila por (línea, código de barras): el SKU se repite si tiene
      // varios códigos. El catálogo del servidor guarda una fila por código.
      qry.Connection := AConexion;
      qry.SQL.Text :=
        ' SELECT L.CODIGO_ART_INVLIN, L.CODIGO_UNIDAD_INVLIN,' +
        '        L.DESCRIPCION_ARTICULO_INVLIN, L.CANTIDAD_TEORICA_INVLIN,' +
        '        A.ESTRAZABLE_ART, CB.CODIGO_BARRAS_CB' +
        '   FROM fza_inventarios_lineas L' +
        '   LEFT JOIN fza_articulos A' +
        '          ON A.CODIGO_ART_ART = L.CODIGO_ART_INVLIN' +
        '   LEFT JOIN fza_codigos_barras CB' +
        '          ON CB.CODIGO_UNIDAD_CB = L.CODIGO_UNIDAD_INVLIN' +
        '  WHERE L.CODIGO_EMP_INVLIN = :E AND L.CODIGO_ALM_INVLIN = :A' +
        '    AND L.SERIE_INV_INVLIN = :S AND L.NUMERO_INV_INVLIN = :N';
      qry.ParamByName('E').AsString := AEmp;
      qry.ParamByName('A').AsString := AAlm;
      qry.ParamByName('S').AsString := ASerie;
      qry.ParamByName('N').AsString := ANumero;
      qry.Open;
      arr := TJSONArray.Create;
      while not qry.Eof do
      begin
        linea := TJSONObject.Create;
        linea.AddPair('codigo_articulo',
                      qry.FieldByName('CODIGO_ART_INVLIN').AsString);
        linea.AddPair('codigo_unidad',
                      qry.FieldByName('CODIGO_UNIDAD_INVLIN').AsString);
        linea.AddPair('descripcion',
                      qry.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString);
        linea.AddPair('codigo_barras',
                      qry.FieldByName('CODIGO_BARRAS_CB').AsString);
        linea.AddPair('cantidad_teorica',
          TJSONNumber.Create(qry.FieldByName('CANTIDAD_TEORICA_INVLIN').AsFloat));
        linea.AddPair('estrazable',
                      qry.FieldByName('ESTRAZABLE_ART').AsString);
        arr.AddElement(linea);
        qry.Next;
      end;
      root.AddPair('lineas', arr);
      sBody := root.ToString;
    finally
      FreeAndNil(qry);
      FreeAndNil(root);
    end;
    iStatus := PostNube(
      AParametrosApp,
      'inv_enviar.php',
      sBody,
      sResp,
      AMensaje);
    if iStatus = 200 then
    begin
      respJson := TJSONObject.ParseJSONValue(sResp);
      try
        if respJson is TJSONObject then
          AIdRecuento :=
            Trunc(TJSONObject(respJson).GetValue<Double>('id_recuento', 0));
      finally
        FreeAndNil(respJson);
      end;
      Result := AIdRecuento > 0;
      if not Result then
        AMensaje := SErrorInventarioNubeSinIdRecuento;
    end
    else if iStatus <> 0 then
      AMensaje := MensajeError(sResp, iStatus);
  end;
end;

// ============================================================================
//   Recoger recuento
// ============================================================================

function RecogerRecuento(
  const AParametrosApp: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AEmp, AAlm, ASerie, ANumero, AUsuario: string; AIdRecuento: Int64;
  AAgregado: TStringList; out ANumEventos: Integer;
  out AMensaje: string): Boolean;
var
  sResp: string;
  iStatus, i: Integer;
  respJson: TJSONValue;
  oRoot: TJSONObject;
  arrEv, arrAg: TJSONArray;
  oEv: TJSONObject;
  ins: TUniQuery;
  sCad: string;
begin
  Result := False;
  ANumEventos := 0;
  AMensaje := '';
  if AAgregado <> nil then
    AAgregado.Clear;
  if InventarioNubeConfigurado(AParametrosApp, AMensaje) then
  begin
    iStatus := GetNube(AParametrosApp, 'inv_recoger.php?id_recuento=' +
                       IntToStr(AIdRecuento) + '&marcar=1', sResp, AMensaje);
    if iStatus = 200 then
    begin
      respJson := TJSONObject.ParseJSONValue(sResp);
      ins := TUniQuery.Create(nil);
      try
        if respJson is TJSONObject then
        begin
          oRoot := TJSONObject(respJson);
          // 1) Insertar cada evento en INVREC (idempotente por UUID).
          ins.Connection := AConexion;
          ins.SQL.Text :=
            ' INSERT INTO fza_inventarios_recuentos' +
            '   (UUID_INVREC, CODIGO_EMP_INVREC, CODIGO_ALM_INVREC,' +
            '    SERIE_INV_INVREC, NUMERO_INV_INVREC, CODIGO_ART_INVREC,' +
            '    CODIGO_UNIDAD_INVREC, CODIGO_BARRAS_INVREC, CANTIDAD_INVREC,' +
            '    LOTE_INVREC, FECHA_CADUCIDAD_INVREC, INSTANTE_RECUENTO_INVREC,' +
            '    OPERARIO_INVREC, DISPOSITIVO_INVREC, ZONA_INVREC,' +
            '    ESANULADO_INVREC, INSTANTE_ALTA, USUARIO_ALTA)' +
            ' VALUES (:UUID, :E, :A, :S, :N, :ART, :SKU, :BAR, :CANT, :LOTE,' +
            '   :CAD, :INST, :OP, :DISP, :ZONA, ''N'', NOW(), :USU)' +
            ' ON DUPLICATE KEY UPDATE ID_INVREC = ID_INVREC';
          if oRoot.GetValue('eventos') is TJSONArray then
          begin
            arrEv := oRoot.GetValue('eventos') as TJSONArray;
            for i := 0 to arrEv.Count - 1 do
              if arrEv.Items[i] is TJSONObject then
              begin
                oEv := TJSONObject(arrEv.Items[i]);
                ins.ParamByName('UUID').AsString :=
                  oEv.GetValue<string>('uuid_evento', '');
                ins.ParamByName('E').AsString := AEmp;
                ins.ParamByName('A').AsString := AAlm;
                ins.ParamByName('S').AsString := ASerie;
                ins.ParamByName('N').AsString := ANumero;
                ins.ParamByName('ART').AsString :=
                  oEv.GetValue<string>('codigo_articulo', '');
                ins.ParamByName('SKU').AsString :=
                  oEv.GetValue<string>('codigo_unidad', '');
                ins.ParamByName('BAR').AsString :=
                  oEv.GetValue<string>('codigo_barras', '');
                ins.ParamByName('CANT').AsFloat :=
                  oEv.GetValue<Double>('cantidad', 0);
                ins.ParamByName('LOTE').AsString :=
                  oEv.GetValue<string>('lote', '');
                sCad := oEv.GetValue<string>('fecha_caducidad', '');
                if Trim(sCad) = '' then
                  ins.ParamByName('CAD').Clear
                else
                  ins.ParamByName('CAD').AsString := sCad;
                ins.ParamByName('INST').AsString :=
                  oEv.GetValue<string>('instante_recuento', '');
                ins.ParamByName('OP').AsString :=
                  oEv.GetValue<string>('operario', '');
                ins.ParamByName('DISP').AsString :=
                  oEv.GetValue<string>('dispositivo', '');
                ins.ParamByName('ZONA').AsString :=
                  oEv.GetValue<string>('zona', '');
                ins.ParamByName('USU').AsString := AUsuario;
                ins.ExecSQL;
                Inc(ANumEventos);
              end;
          end;
          // 2) Agregado SKU=CANTIDAD para CargarDesdeListaSkus.
          if (AAgregado <> nil) and (oRoot.GetValue('agregado') is TJSONArray) then
          begin
            arrAg := oRoot.GetValue('agregado') as TJSONArray;
            for i := 0 to arrAg.Count - 1 do
              if arrAg.Items[i] is TJSONObject then
                AAgregado.Add(
                  TJSONObject(arrAg.Items[i]).GetValue<string>('codigo_unidad',
                    '') + '=' +
                  FloatToStr(TJSONObject(arrAg.Items[i]).GetValue<Double>(
                    'cantidad', 0)));
          end;
          Result := True;
        end;
      finally
        FreeAndNil(ins);
        FreeAndNil(respJson);
      end;
    end
    else if iStatus <> 0 then
      AMensaje := MensajeError(sResp, iStatus);
  end;
end;

end.
