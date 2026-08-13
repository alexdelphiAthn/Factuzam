{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaCatalogo                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Cliente directo de productos, combinaciones y stock de PrestaShop.        }
{******************************************************************************}
unit inLibPrestaCatalogo;

interface

uses
  inLibPrestaCatalogoIntf;

function CalcularClaveInstalacionPresta(
  const AUrlApi: string): string;
function CrearTransportePresta(const AUrlApi,
  AClaveApi: string): ITransporteAltaPresta;

type
  TClienteCatalogoPresta = class(TInterfacedObject,
    IClienteCatalogoPresta)
  private
    FTransporte: ITransportePresta;
    function SolicitarXml(const ARecurso: string): string;
    procedure EnviarParche(const ARecurso, AXml: string);
    function ResolverIdUnico(const AXml, AColeccion, AElemento,
      AIdentificacion, ARecurso: string): Integer;
  public
    constructor Create(const AUrlApi, AClaveApi: string); overload;
    constructor Create(
      const ATransporte: ITransportePresta); overload;
    function BuscarProductoUnico(const AReferencia: string;
      AIdTienda: Integer): Integer;
    function BuscarCombinacionUnica(const AReferencia: string;
      AIdProducto, AIdTienda: Integer): Integer;
    function ResolverStockDisponible(AIdProducto, AIdAtributo,
      AIdTienda: Integer): TStockDisponiblePresta;
    function LeerPrecioProducto(AIdProducto,
      AIdTienda: Integer): Double;
    function LeerImpactoPrecioCombinacion(AIdCombinacion,
      AIdTienda: Integer): Double;
    function LeerCantidadStock(AIdStockDisponible,
      AIdTienda: Integer): Integer;
    procedure ActualizarPrecioProducto(AIdProducto, AIdTienda: Integer;
      APrecio: Double);
    procedure ActualizarImpactoPrecioCombinacion(AIdCombinacion,
      AIdTienda: Integer; AImpacto: Double);
    procedure ActualizarCantidadStock(AIdStockDisponible,
      AIdTienda, ACantidad: Integer);
  end;

implementation

uses
  System.SysUtils, System.Hash, System.Math, System.NetEncoding,
  System.Net.URLClient, System.Variants, System.Generics.Collections,
  Xml.XMLIntf, Xml.XMLDoc, REST.Client, REST.Types,
  REST.Authenticator.Basic;

const
  CNombreProductos = 'products';
  CNombreProducto = 'product';
  CNombreCombinaciones = 'combinations';
  CNombreCombinacion = 'combination';
  CNombreStocks = 'stock_availables';
  CNombreStock = 'stock_available';
  CNamespaceXlink = 'http://www.w3.org/1999/xlink';

resourcestring
  SUrlApiPrestaVacia =
    'La URL de la API de PrestaShop no puede estar vacía.';
  SUrlApiPrestaInvalida =
    'La URL de la API de PrestaShop no es válida.';
  SUrlApiPrestaNoSegura =
    'La API de PrestaShop debe usar HTTPS.';
  SUrlApiPrestaConCredenciales =
    'La URL de la API de PrestaShop no puede contener credenciales.';
  SUrlApiPrestaConConsulta =
    'La URL de la API de PrestaShop no puede contener consulta ni ancla.';
  SClaveApiPrestaVacia =
    'La clave de la API de PrestaShop no puede estar vacía.';
  STransportePrestaNoAsignado =
    'El transporte de PrestaShop no está asignado.';
  SErrorTransportePresta =
    'No se pudo ejecutar %s sobre %s: %s.';
  SValorPrestaPositivo =
    '%s debe ser mayor que cero.';
  SValorPrestaNoNegativo =
    '%s no puede ser negativo.';
  SReferenciaPrestaVacia =
    'La referencia de PrestaShop no puede estar vacía.';
  SDecimalPrestaInvalido =
    '%s no contiene un decimal válido.';
  SCampoPrestaAusente =
    'falta el campo %s';
  SEnteroPrestaInvalido =
    'el campo %s no contiene un entero válido';
  SPrecioPrestaInvalido =
    'El precio de producto no puede ser negativo, infinito ni NaN.';
  SImpactoPrestaInvalido =
    'El impacto de precio no puede ser infinito ni NaN.';
  SXmlPrestaVacio =
    'el documento XML está vacío';
  SXmlPrestaNoValido =
    'el documento XML no se pudo interpretar';
  SNodoPrestaAusente =
    'falta el nodo %s';
  SRespuestaStockIncoherente =
    'el stock no corresponde al producto y atributo solicitados';

type
  TTransporteRestPresta = class(TInterfacedObject, ITransportePresta,
    ITransporteAltaPresta)
  private
    FCliente: TRESTClient;
    FSolicitud: TRESTRequest;
    FRespuesta: TRESTResponse;
    FAutenticador: THTTPBasicAuthenticator;
    function Ejecutar(AMetodo: TRESTRequestMethod;
      const ARecurso, AXml: string): TRespuestaHttpPresta;
  public
    constructor Create(const AUrlApi, AClaveApi: string);
    destructor Destroy; override;
    function EjecutarGet(
      const ARecurso: string): TRespuestaHttpPresta;
    function EjecutarPatch(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
    function EjecutarPostXml(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
    function EjecutarPostImagen(const ARecurso, ARutaImagen: string):
      TRespuestaHttpPresta;
  end;

function OcultarSecreto(const AMensaje, ASecreto: string): string;
begin
  Result := AMensaje;
  if ASecreto <> '' then
    Result := StringReplace(Result, ASecreto, '[oculta]',
      [rfReplaceAll, rfIgnoreCase]);
end;

function NormalizarUrlApi(const AUrlApi: string): string;
var
  bLocal: Boolean;
  oUri: TURI;
begin
  Result := Trim(AUrlApi);
  if Result = '' then
    raise EConfiguracionPrestaInvalida.Create(SUrlApiPrestaVacia);
  try
    oUri := TURI.Create(Result);
  except
    on E: Exception do
      raise EConfiguracionPrestaInvalida.Create(SUrlApiPrestaInvalida);
  end;
  bLocal := SameText(oUri.Host, 'localhost') or
    SameText(oUri.Host, '127.0.0.1');
  if (not SameText(oUri.Scheme, TURI.SCHEME_HTTPS)) and
     (not (SameText(oUri.Scheme, TURI.SCHEME_HTTP) and bLocal)) then
    raise EConfiguracionPrestaInvalida.Create(SUrlApiPrestaNoSegura);
  if (oUri.Host = '') then
    raise EConfiguracionPrestaInvalida.Create(SUrlApiPrestaInvalida);
  if (oUri.Username <> '') or (oUri.Password <> '') then
    raise EConfiguracionPrestaInvalida.Create(
      SUrlApiPrestaConCredenciales);
  if (oUri.Query <> '') or (oUri.Fragment <> '') then
    raise EConfiguracionPrestaInvalida.Create(SUrlApiPrestaConConsulta);
  while (Length(Result) > 0) and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function CalcularClaveInstalacionPresta(
  const AUrlApi: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(
    NormalizarUrlApi(AUrlApi)));
end;

function CrearTransportePresta(const AUrlApi,
  AClaveApi: string): ITransporteAltaPresta;
begin
  Result := TTransporteRestPresta.Create(AUrlApi, AClaveApi);
end;

procedure ComprobarPositivo(AValor: Integer; const ANombre: string);
begin
  if AValor <= 0 then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SValorPrestaPositivo, [ANombre]);
end;

procedure ComprobarNoNegativo(AValor: Integer; const ANombre: string);
begin
  if AValor < 0 then
    raise EConfiguracionPrestaInvalida.CreateFmt(
      SValorPrestaNoNegativo, [ANombre]);
end;

procedure ComprobarReferencia(const AReferencia: string);
begin
  if Trim(AReferencia) = '' then
    raise EConfiguracionPrestaInvalida.Create(SReferenciaPrestaVacia);
end;

procedure ComprobarPrecio(APrecio: Double);
begin
  if IsNan(APrecio) or IsInfinite(APrecio) or (APrecio < 0) then
    raise EConfiguracionPrestaInvalida.Create(SPrecioPrestaInvalido);
end;

procedure ComprobarImpacto(AImpacto: Double);
begin
  if IsNan(AImpacto) or IsInfinite(AImpacto) then
    raise EConfiguracionPrestaInvalida.Create(SImpactoPrestaInvalido);
end;

function CodificarFiltro(const AValor: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValor);
end;

function FormatearDecimal(AValor: Double): string;
begin
  Result := FormatFloat('0.000000', AValor,
    TFormatSettings.Invariant);
end;

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function CrearXmlParche(const AElemento, ACampo: string; AId: Integer;
  const AValor: string): string;
begin
  Result := '<?xml version="1.0" encoding="UTF-8"?>' + sLineBreak +
    '<prestashop xmlns:xlink="' + EscaparXml(CNamespaceXlink) + '">' +
    sLineBreak + '  <' + AElemento + '>' + sLineBreak +
    '    <id>' + EscaparXml(IntToStr(AId)) + '</id>' + sLineBreak +
    '    <' + ACampo + '>' + EscaparXml(AValor) + '</' + ACampo + '>' +
    sLineBreak + '  </' + AElemento + '>' + sLineBreak +
    '</prestashop>';
end;

function CargarDocumento(const AXml, ARecurso: string): IXMLDocument;
begin
  if Trim(AXml) = '' then
    raise ERespuestaPrestaInvalida.Create(ARecurso, SXmlPrestaVacio);
  Result := TXMLDocument.Create(nil);
  try
    Result.LoadFromXML(AXml);
    Result.Active := True;
  except
    on E: Exception do
      raise ERespuestaPrestaInvalida.Create(
        ARecurso, SXmlPrestaNoValido);
  end;
end;

function BuscarHijo(const ANodo: IXMLNode;
  const ANombre: string): IXMLNode;
begin
  Result := nil;
  if Assigned(ANodo) then
    Result := ANodo.ChildNodes.FindNode(ANombre);
end;

function HijoObligatorio(const ANodo: IXMLNode;
  const ANombre, ARecurso: string): IXMLNode;
begin
  Result := BuscarHijo(ANodo, ANombre);
  if not Assigned(Result) then
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SNodoPrestaAusente, [ANombre]));
end;

function TextoCampo(const ANodo: IXMLNode;
  const ACampo, ARecurso: string): string;
var
  oCampo: IXMLNode;
begin
  oCampo := BuscarHijo(ANodo, ACampo);
  if not Assigned(oCampo) then
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SCampoPrestaAusente, [ACampo]));
  Result := Trim(oCampo.Text);
end;

function EnteroTexto(const ATexto, ACampo,
  ARecurso: string): Integer;
begin
  if not TryStrToInt(Trim(ATexto), Result) then
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SEnteroPrestaInvalido, [ACampo]));
end;

function EnteroCampo(const ANodo: IXMLNode;
  const ACampo, ARecurso: string): Integer;
begin
  Result := EnteroTexto(TextoCampo(ANodo, ACampo, ARecurso),
    ACampo, ARecurso);
end;

function IdNodo(const ANodo: IXMLNode; const ARecurso: string): Integer;
var
  oId: IXMLNode;
  sId: string;
begin
  oId := BuscarHijo(ANodo, 'id');
  if Assigned(oId) then
    sId := oId.Text
  else if ANodo.HasAttribute('id') then
    sId := VarToStr(ANodo.Attributes['id'])
  else
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SCampoPrestaAusente, ['id']));
  Result := EnteroTexto(sId, 'id', ARecurso);
end;

function DecimalCampo(const ANodo: IXMLNode;
  const ACampo, ARecurso: string): Double;
var
  sValor: string;
begin
  sValor := TextoCampo(ANodo, ACampo, ARecurso);
  if not TryStrToFloat(sValor, Result, TFormatSettings.Invariant) then
    raise ERespuestaPrestaInvalida.Create(ARecurso,
      Format(SDecimalPrestaInvalido, [ACampo]));
end;

function NodoRecurso(const AXml, AElemento,
  ARecurso: string): IXMLNode;
var
  oDocumento: IXMLDocument;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  Result := HijoObligatorio(oDocumento.DocumentElement,
    AElemento, ARecurso);
end;

function LeerStocks(const AXml,
  ARecurso: string): TArray<TStockDisponiblePresta>;
var
  iIndice: Integer;
  iResultado: Integer;
  oColeccion: IXMLNode;
  oDocumento: IXMLDocument;
  oNodo: IXMLNode;
  rStock: TStockDisponiblePresta;
begin
  SetLength(Result, 0);
  oDocumento := CargarDocumento(AXml, ARecurso);
  oColeccion := HijoObligatorio(oDocumento.DocumentElement,
    CNombreStocks, ARecurso);
  iResultado := 0;
  for iIndice := 0 to oColeccion.ChildNodes.Count - 1 do
  begin
    oNodo := oColeccion.ChildNodes.Get(iIndice);
    if SameText(oNodo.NodeName, CNombreStock) then
    begin
      rStock.Id := IdNodo(oNodo, ARecurso);
      rStock.IdProducto := EnteroCampo(oNodo, 'id_product', ARecurso);
      rStock.IdAtributo := EnteroCampo(oNodo,
        'id_product_attribute', ARecurso);
      rStock.IdTienda := EnteroCampo(oNodo, 'id_shop', ARecurso);
      rStock.IdGrupoTiendas := EnteroCampo(oNodo,
        'id_shop_group', ARecurso);
      rStock.Cantidad := EnteroCampo(oNodo, 'quantity', ARecurso);
      SetLength(Result, iResultado + 1);
      Result[iResultado] := rStock;
      Inc(iResultado);
    end;
  end;
end;

function ElegirStock(const AStocks: TArray<TStockDisponiblePresta>;
  AIdProducto, AIdAtributo, AIdTienda: Integer;
  const AIdentificacion: string): TStockDisponiblePresta;
var
  iCantidadExacta: Integer;
  iIndice: Integer;
begin
  Result := Default(TStockDisponiblePresta);
  iCantidadExacta := 0;
  for iIndice := 0 to High(AStocks) do
  begin
    if (AStocks[iIndice].IdProducto <> AIdProducto) or
       (AStocks[iIndice].IdAtributo <> AIdAtributo) then
      raise ERespuestaPrestaInvalida.Create(
        CNombreStocks, SRespuestaStockIncoherente);
    if AStocks[iIndice].IdTienda = AIdTienda then
    begin
      Inc(iCantidadExacta);
      if iCantidadExacta = 1 then
        Result := AStocks[iIndice];
    end;
  end;
  // Un id_shop=0 solo es seguro tras comprobar share_stock. Este cliente
  // no hace esa comprobación y, por tanto, exige siempre la tienda exacta.
  if iCantidadExacta = 0 then
    raise ERecursoPrestaNoEncontrado.Create(
      CNombreStock, AIdentificacion);
  if iCantidadExacta > 1 then
    raise ERecursoPrestaAmbiguo.Create(
      CNombreStock, AIdentificacion, iCantidadExacta);
end;

{ TTransporteRestPresta }

constructor TTransporteRestPresta.Create(
  const AUrlApi, AClaveApi: string);
var
  sUrlApi: string;
begin
  inherited Create;
  if Trim(AClaveApi) = '' then
    raise EConfiguracionPrestaInvalida.Create(SClaveApiPrestaVacia);
  sUrlApi := NormalizarUrlApi(AUrlApi);
  FCliente := TRESTClient.Create(nil);
  FSolicitud := TRESTRequest.Create(nil);
  FRespuesta := TRESTResponse.Create(nil);
  FAutenticador := THTTPBasicAuthenticator.Create(nil);
  FCliente.BaseURL := sUrlApi;
  FCliente.Authenticator := FAutenticador;
  FCliente.RaiseExceptionOn500 := False;
  FAutenticador.Username := AClaveApi;
  FAutenticador.Password := '';
  FSolicitud.Client := FCliente;
  FSolicitud.Response := FRespuesta;
  FSolicitud.Accept := 'application/xml';
  FSolicitud.BodyCodePage := 65001;
  FSolicitud.ConnectTimeout := 10000;
  FSolicitud.ReadTimeout := 60000;
  FSolicitud.HandleRedirects := False;
  FSolicitud.URLAlreadyEncoded := True;
end;

destructor TTransporteRestPresta.Destroy;
begin
  if Assigned(FCliente) then
    FCliente.Authenticator := nil;
  if Assigned(FSolicitud) then
  begin
    FSolicitud.Client := nil;
    FSolicitud.Response := nil;
  end;
  FreeAndNil(FSolicitud);
  FreeAndNil(FRespuesta);
  FreeAndNil(FCliente);
  FreeAndNil(FAutenticador);
  inherited;
end;

function TTransporteRestPresta.Ejecutar(AMetodo: TRESTRequestMethod;
  const ARecurso, AXml: string): TRespuestaHttpPresta;
var
  sMetodo: string;
begin
  sMetodo := RESTRequestMethodToString(AMetodo);
  FRespuesta.ResetToDefaults;
  FSolicitud.Params.Clear;
  FSolicitud.ClearBody;
  FSolicitud.Resource := ARecurso;
  FSolicitud.Method := AMetodo;
  if AMetodo in [rmPATCH, rmPOST] then
    FSolicitud.AddBody(AXml, ctAPPLICATION_XML);
  try
    FSolicitud.Execute;
  except
    on E: Exception do
      raise ETransportePresta.CreateFmt(SErrorTransportePresta,
        [sMetodo, ARecurso,
         OcultarSecreto(E.Message, FAutenticador.Username)]);
  end;
  Result.EstadoHttp := FRespuesta.StatusCode;
  Result.TextoEstado := OcultarSecreto(FRespuesta.StatusText,
    FAutenticador.Username);
  Result.Contenido := FRespuesta.Content;
end;

function TTransporteRestPresta.EjecutarGet(
  const ARecurso: string): TRespuestaHttpPresta;
begin
  Result := Ejecutar(rmGET, ARecurso, '');
end;

function TTransporteRestPresta.EjecutarPatch(
  const ARecurso, AXml: string): TRespuestaHttpPresta;
begin
  Result := Ejecutar(rmPATCH, ARecurso, AXml);
end;

function TTransporteRestPresta.EjecutarPostXml(
  const ARecurso, AXml: string): TRespuestaHttpPresta;
begin
  Result := Ejecutar(rmPOST, ARecurso, AXml);
end;

function TTransporteRestPresta.EjecutarPostImagen(
  const ARecurso, ARutaImagen: string): TRespuestaHttpPresta;
var
  sMetodo: string;
begin
  sMetodo := RESTRequestMethodToString(rmPOST);
  FRespuesta.ResetToDefaults;
  FSolicitud.Params.Clear;
  FSolicitud.ClearBody;
  FSolicitud.Resource := ARecurso;
  FSolicitud.Method := rmPOST;
  FSolicitud.AddFile('image', ARutaImagen);
  try
    FSolicitud.Execute;
  except
    on E: Exception do
      raise ETransportePresta.CreateFmt(SErrorTransportePresta,
        [sMetodo, ARecurso,
         OcultarSecreto(E.Message, FAutenticador.Username)]);
  end;
  Result.EstadoHttp := FRespuesta.StatusCode;
  Result.TextoEstado := OcultarSecreto(FRespuesta.StatusText,
    FAutenticador.Username);
  Result.Contenido := FRespuesta.Content;
end;

{ TClienteCatalogoPresta }

constructor TClienteCatalogoPresta.Create(
  const AUrlApi, AClaveApi: string);
begin
  inherited Create;
  FTransporte := TTransporteRestPresta.Create(AUrlApi, AClaveApi);
end;

constructor TClienteCatalogoPresta.Create(
  const ATransporte: ITransportePresta);
begin
  inherited Create;
  if ATransporte = nil then
    raise EConfiguracionPrestaInvalida.Create(
      STransportePrestaNoAsignado);
  FTransporte := ATransporte;
end;

function TClienteCatalogoPresta.SolicitarXml(
  const ARecurso: string): string;
var
  rRespuesta: TRespuestaHttpPresta;
begin
  rRespuesta := FTransporte.EjecutarGet(ARecurso);
  if (rRespuesta.EstadoHttp < 200) or
     (rRespuesta.EstadoHttp >= 300) then
    raise EErrorHttpPresta.Create(rRespuesta.EstadoHttp,
      'GET', ARecurso);
  Result := rRespuesta.Contenido;
end;

procedure TClienteCatalogoPresta.EnviarParche(
  const ARecurso, AXml: string);
var
  rRespuesta: TRespuestaHttpPresta;
begin
  rRespuesta := FTransporte.EjecutarPatch(ARecurso, AXml);
  if (rRespuesta.EstadoHttp < 200) or
     (rRespuesta.EstadoHttp >= 300) then
    raise EErrorHttpPresta.Create(rRespuesta.EstadoHttp,
      'PATCH', ARecurso);
end;

function TClienteCatalogoPresta.ResolverIdUnico(const AXml,
  AColeccion, AElemento, AIdentificacion,
  ARecurso: string): Integer;
var
  iCantidad: Integer;
  iIndice: Integer;
  oColeccion: IXMLNode;
  oDocumento: IXMLDocument;
  oNodo: IXMLNode;
begin
  oDocumento := CargarDocumento(AXml, ARecurso);
  oColeccion := HijoObligatorio(oDocumento.DocumentElement,
    AColeccion, ARecurso);
  iCantidad := 0;
  Result := 0;
  for iIndice := 0 to oColeccion.ChildNodes.Count - 1 do
  begin
    oNodo := oColeccion.ChildNodes.Get(iIndice);
    if SameText(oNodo.NodeName, AElemento) then
    begin
      Inc(iCantidad);
      if iCantidad = 1 then
        Result := IdNodo(oNodo, ARecurso);
    end;
  end;
  if iCantidad = 0 then
    raise ERecursoPrestaNoEncontrado.Create(
      AElemento, AIdentificacion);
  if iCantidad > 1 then
    raise ERecursoPrestaAmbiguo.Create(
      AElemento, AIdentificacion, iCantidad);
end;

function TClienteCatalogoPresta.BuscarProductoUnico(
  const AReferencia: string; AIdTienda: Integer): Integer;
var
  sRecurso: string;
  sXml: string;
begin
  ComprobarReferencia(AReferencia);
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := CNombreProductos +
    '?filter[reference]=[' + CodificarFiltro(Trim(AReferencia)) + ']' +
    '&display=[id,reference]&id_shop=' + IntToStr(AIdTienda);
  sXml := SolicitarXml(sRecurso);
  Result := ResolverIdUnico(sXml, CNombreProductos, CNombreProducto,
    'reference=' + AReferencia, sRecurso);
end;

function TClienteCatalogoPresta.BuscarCombinacionUnica(
  const AReferencia: string; AIdProducto, AIdTienda: Integer): Integer;
var
  sIdentificacion: string;
  sRecurso: string;
  sXml: string;
begin
  ComprobarReferencia(AReferencia);
  ComprobarPositivo(AIdProducto, 'AIdProducto');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := CNombreCombinaciones +
    '?filter[reference]=[' + CodificarFiltro(Trim(AReferencia)) + ']' +
    '&filter[id_product]=[' + IntToStr(AIdProducto) + ']' +
    '&display=[id,id_product,reference]&id_shop=' +
    IntToStr(AIdTienda);
  sIdentificacion := Format('reference=%s, product=%d',
    [AReferencia, AIdProducto]);
  sXml := SolicitarXml(sRecurso);
  Result := ResolverIdUnico(sXml, CNombreCombinaciones,
    CNombreCombinacion, sIdentificacion, sRecurso);
end;

function TClienteCatalogoPresta.ResolverStockDisponible(
  AIdProducto, AIdAtributo,
  AIdTienda: Integer): TStockDisponiblePresta;
var
  aStocks: TArray<TStockDisponiblePresta>;
  sIdentificacion: string;
  sRecurso: string;
begin
  ComprobarPositivo(AIdProducto, 'AIdProducto');
  ComprobarNoNegativo(AIdAtributo, 'AIdAtributo');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := CNombreStocks +
    '?filter[id_product]=[' + IntToStr(AIdProducto) + ']' +
    '&filter[id_product_attribute]=[' + IntToStr(AIdAtributo) + ']' +
    '&filter[id_shop]=[' + IntToStr(AIdTienda) + ']' +
    '&display=[id,id_product,id_product_attribute,id_shop,' +
    'id_shop_group,quantity]&id_shop=' + IntToStr(AIdTienda);
  sIdentificacion := Format('product=%d, attribute=%d, shop=%d',
    [AIdProducto, AIdAtributo, AIdTienda]);
  aStocks := LeerStocks(SolicitarXml(sRecurso), sRecurso);
  Result := ElegirStock(aStocks, AIdProducto, AIdAtributo,
    AIdTienda, sIdentificacion);
end;

function TClienteCatalogoPresta.LeerPrecioProducto(
  AIdProducto, AIdTienda: Integer): Double;
var
  oProducto: IXMLNode;
  sRecurso: string;
begin
  ComprobarPositivo(AIdProducto, 'AIdProducto');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := Format('%s/%d?display=[id,price]&id_shop=%d',
    [CNombreProductos, AIdProducto, AIdTienda]);
  oProducto := NodoRecurso(SolicitarXml(sRecurso),
    CNombreProducto, sRecurso);
  Result := DecimalCampo(oProducto, 'price', sRecurso);
end;

function TClienteCatalogoPresta.LeerImpactoPrecioCombinacion(
  AIdCombinacion, AIdTienda: Integer): Double;
var
  oCombinacion: IXMLNode;
  sRecurso: string;
begin
  ComprobarPositivo(AIdCombinacion, 'AIdCombinacion');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := Format('%s/%d?display=[id,price]&id_shop=%d',
    [CNombreCombinaciones, AIdCombinacion, AIdTienda]);
  oCombinacion := NodoRecurso(SolicitarXml(sRecurso),
    CNombreCombinacion, sRecurso);
  Result := DecimalCampo(oCombinacion, 'price', sRecurso);
end;

function TClienteCatalogoPresta.LeerCantidadStock(
  AIdStockDisponible, AIdTienda: Integer): Integer;
var
  oStock: IXMLNode;
  sRecurso: string;
begin
  ComprobarPositivo(AIdStockDisponible, 'AIdStockDisponible');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := Format('%s/%d?display=[id,quantity]&id_shop=%d',
    [CNombreStocks, AIdStockDisponible, AIdTienda]);
  oStock := NodoRecurso(SolicitarXml(sRecurso),
    CNombreStock, sRecurso);
  Result := EnteroCampo(oStock, 'quantity', sRecurso);
end;

procedure TClienteCatalogoPresta.ActualizarPrecioProducto(
  AIdProducto, AIdTienda: Integer; APrecio: Double);
var
  sRecurso: string;
  sXml: string;
begin
  ComprobarPositivo(AIdProducto, 'AIdProducto');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  ComprobarPrecio(APrecio);
  sRecurso := Format('%s/%d?id_shop=%d',
    [CNombreProductos, AIdProducto, AIdTienda]);
  sXml := CrearXmlParche(CNombreProducto, 'price',
    AIdProducto, FormatearDecimal(APrecio));
  EnviarParche(sRecurso, sXml);
end;

procedure TClienteCatalogoPresta.ActualizarImpactoPrecioCombinacion(
  AIdCombinacion, AIdTienda: Integer; AImpacto: Double);
var
  sRecurso: string;
  sXml: string;
begin
  ComprobarPositivo(AIdCombinacion, 'AIdCombinacion');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  ComprobarImpacto(AImpacto);
  sRecurso := Format('%s/%d?id_shop=%d',
    [CNombreCombinaciones, AIdCombinacion, AIdTienda]);
  sXml := CrearXmlParche(CNombreCombinacion, 'price',
    AIdCombinacion, FormatearDecimal(AImpacto));
  EnviarParche(sRecurso, sXml);
end;

procedure TClienteCatalogoPresta.ActualizarCantidadStock(
  AIdStockDisponible, AIdTienda, ACantidad: Integer);
var
  sRecurso: string;
  sXml: string;
begin
  ComprobarPositivo(AIdStockDisponible, 'AIdStockDisponible');
  ComprobarPositivo(AIdTienda, 'AIdTienda');
  sRecurso := Format('%s/%d?id_shop=%d',
    [CNombreStocks, AIdStockDisponible, AIdTienda]);
  sXml := CrearXmlParche(CNombreStock, 'quantity',
    AIdStockDisponible, IntToStr(ACantidad));
  EnviarParche(sRecurso, sXml);
end;

end.
