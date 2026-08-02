{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaImporter                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Importador de pedidos desde la API REST de PrestaShop.                    }
{    Conexión autenticada, listado y carga de pedidos completos.               }
{******************************************************************************}
unit inLibPrestaImporter;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  XMLIntf, XMLDoc, REST.Client, REST.Types, system.Variants,
  REST.Authenticator.Basic,
  inLibPresta, inLibLogIntf;

type
  TPrestaConn = class
  private
    FBaseURL: string;
    FApiKey:  string;
    FClient:  TRESTClient;
    FRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FAuth: THTTPBasicAuthenticator;
    FRegistroLog: IRegistroLog;
    procedure DoRequest(const sResource:string);
  public
    constructor Create(const aBaseURL, aApiKey:string;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    function ListarPedidosResumen(out idsCsv:string):Integer;
    function CargarPedido(const sIdPedido:string):TOrder;
    property Response: TRESTResponse read FResponse;
  end;

  TPrestaPedidoResumen = record
    IdPedido: string;
    Referencia: string;
    Fecha: string;
    Cliente: string;
    Total: string;
    Estado: string;
  end;

  TPrestaPedidoResumenList = TList<TPrestaPedidoResumen>;

function ListarPedidosResumen(const aBaseURL, aApiKey:string;
  aLista:TPrestaPedidoResumenList;
  const ARegistroLog: IRegistroLog):Boolean;

implementation

uses
  inLibScanDateTime;

type
  TDestinoDireccionPresta = (ddpEntrega, ddpFacturacion);

  TCargaPedidoPresta = class
  private
    FConexion: TPrestaConn;
    FDocumento: IXMLDocument;
    FPedido: TOrder;
    FNodoPedido: IXMLNode;
    FIdPedido: string;
    FIdCliente: string;
    FIdDireccionEntrega: string;
    FIdDireccionFacturacion: string;
    FIdTransportista: string;
    FIdEstadoPedido: string;
    function SolicitarNodo(const Recurso, Coleccion,
      Elemento: string): IXMLNode;
    function LeerImporte(const Nodo: IXMLNode;
      const Campo: string): Currency;
    function LeerNif(const Nodo: IXMLNode;
      const PrimerNombre, SegundoNombre: string): string;
    procedure CargarPedidoBase(const IdPedido: string);
    procedure CargarCliente;
    procedure AsignarDireccion(const Nodo: IXMLNode;
      const Nif: string; Destino: TDestinoDireccionPresta);
    procedure CargarProvincia(const IdProvincia: string;
      Destino: TDestinoDireccionPresta);
    procedure CargarDireccion(const IdDireccion: string;
      Destino: TDestinoDireccionPresta);
    procedure CargarDirecciones;
    procedure CargarCabeceraEconomica;
    procedure CargarTransportista;
    procedure CargarEstadoPedido;
    procedure CargarLineas;
    procedure CargarMensajesHilo(const IdHilo: string);
    procedure CargarMensajes;
  public
    constructor Create(Conexion: TPrestaConn);
    destructor Destroy; override;
    function Ejecutar(const IdPedido: string): TOrder;
  end;

{ TPrestaConn }

constructor TPrestaConn.Create(const aBaseURL, aApiKey: string;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  FBaseURL := aBaseURL;
  FApiKey  := aApiKey;
  FClient   := TRESTClient.Create(nil);
  FRequest  := TRESTRequest.Create(nil);
  FResponse := TRESTResponse.Create(nil);
  FAuth     := THTTPBasicAuthenticator.Create(nil);
  FClient.BaseURL       := aBaseURL;
  FClient.Authenticator := FAuth;
  FAuth.Username        := aApiKey;
  FAuth.Password        := '';
  FRequest.Client   := FClient;
  FRequest.Response := FResponse;
end;

destructor TPrestaConn.Destroy;
begin
  FreeAndNil(FRequest);
  FreeAndNil(FResponse);
  FreeAndNil(FClient);
  FreeAndNil(FAuth);
  inherited;
end;

procedure TPrestaConn.DoRequest(const sResource: string);
begin
  FRequest.Resource := sResource;
  FRequest.Method   := rmGet;
  FRequest.Execute;
end;

function TPrestaConn.ListarPedidosResumen(out idsCsv: string): Integer;
var
  XmlDoc: IXMLDocument;
  Node, NodeOrders: IXMLNode;
  i: Integer;
begin
  Result := 0;
  idsCsv := '';
  DoRequest('/orders');
  XmlDoc := TXMLDocument.Create(nil);
  XmlDoc.LoadFromXML(FResponse.Content);
  XmlDoc.Active := True;
  Node := XmlDoc.DocumentElement;
  NodeOrders := Node.ChildNodes['orders'];
  if not Assigned(NodeOrders) then Exit;
  for i := 0 to NodeOrders.ChildNodes.Count - 1 do
  begin
    Node := NodeOrders.ChildNodes.Get(i);
    if Node.HasAttribute('id') then
    begin
      if (idsCsv <> '') then
        idsCsv := idsCsv + ',';
      idsCsv := idsCsv + VarToStr(Node.Attributes['id']);
      Inc(Result);
    end;
  end;
end;

{ TCargaPedidoPresta }

constructor TCargaPedidoPresta.Create(Conexion: TPrestaConn);
begin
  inherited Create;
  FConexion := Conexion;
  FDocumento := NewXMLDocument;
  FPedido := TOrder.Create;
end;

destructor TCargaPedidoPresta.Destroy;
begin
  FreeAndNil(FPedido);
  FDocumento := nil;
  inherited;
end;

function TCargaPedidoPresta.SolicitarNodo(const Recurso, Coleccion,
  Elemento: string): IXMLNode;
var
  Nodo: IXMLNode;
begin
  FConexion.DoRequest(Recurso);
  FDocumento.LoadFromXML(FConexion.Response.Content);
  FDocumento.Active := True;
  Nodo := FDocumento.DocumentElement;
  Nodo := Nodo.ChildNodes[Coleccion];
  Result := Nodo.ChildNodes[Elemento];
end;

function TCargaPedidoPresta.LeerImporte(const Nodo: IXMLNode;
  const Campo: string): Currency;
var
  Texto: string;
begin
  Texto := Nodo.ChildNodes[Campo].Text;
  Result := StrToFloatDef(StringReplace(Texto, '.', ',', []), 0);
end;

function TCargaPedidoPresta.LeerNif(const Nodo: IXMLNode;
  const PrimerNombre, SegundoNombre: string): string;
begin
  if Assigned(Nodo.ChildNodes.FindNode(PrimerNombre)) then
    Result := Nodo.ChildNodes[PrimerNombre].Text
  else if Assigned(Nodo.ChildNodes.FindNode(SegundoNombre)) then
    Result := Nodo.ChildNodes[SegundoNombre].Text
  else
    Result := '';
end;

procedure TCargaPedidoPresta.CargarPedidoBase(const IdPedido: string);
begin
  FNodoPedido := SolicitarNodo(
    '/orders/?display=full&filter[id]=[' + IdPedido + ']',
    'orders', 'order');
  FIdPedido := FNodoPedido.ChildNodes['id'].Text;
  FIdCliente := FNodoPedido.ChildNodes['id_customer'].Text;
  FIdDireccionEntrega :=
    FNodoPedido.ChildNodes['id_address_delivery'].Text;
  FIdDireccionFacturacion :=
    FNodoPedido.ChildNodes['id_address_invoice'].Text;
  FPedido.idPedido := FIdPedido;
end;

procedure TCargaPedidoPresta.CargarCliente;
var
  Nodo: IXMLNode;
begin
  Nodo := SolicitarNodo(
    '/customers/?display=[firstname,lastname,email]&filter[id]=[' +
    FIdCliente + ']', 'customers', 'customer');
  FPedido.custName := Nodo.ChildNodes['firstname'].Text + ' ' +
    Nodo.ChildNodes['lastname'].Text;
  FPedido.custMail := Nodo.ChildNodes['email'].Text;
end;

procedure TCargaPedidoPresta.AsignarDireccion(const Nodo: IXMLNode;
  const Nif: string; Destino: TDestinoDireccionPresta);
begin
  if Destino = ddpEntrega then
  begin
    FPedido.idAddressDel := Nodo.ChildNodes['id'].Text;
    FPedido.FirstnameDel := Nodo.ChildNodes['firstname'].Text;
    FPedido.LastNameDel := Nodo.ChildNodes['lastname'].Text;
    FPedido.Address1Del := Nodo.ChildNodes['address1'].Text;
    FPedido.Address2Del := Nodo.ChildNodes['address2'].Text;
    FPedido.PostcodeDel := Nodo.ChildNodes['postcode'].Text;
    FPedido.CityDel := Nodo.ChildNodes['city'].Text;
    FPedido.PhoneDel := Nodo.ChildNodes['phone'].Text;
    FPedido.Phone_moDel := Nodo.ChildNodes['phone_mobile'].Text;
    FPedido.DniDel := Nodo.ChildNodes['dni'].Text;
    FPedido.CompanyDel := Nodo.ChildNodes['company'].Text;
    FPedido.Vat_numberDel := Nif;
  end
  else
  begin
    FPedido.idAddressBil := Nodo.ChildNodes['id'].Text;
    FPedido.FirstnameBil := Nodo.ChildNodes['firstname'].Text;
    FPedido.LastNameBil := Nodo.ChildNodes['lastname'].Text;
    FPedido.Address1Bil := Nodo.ChildNodes['address1'].Text;
    FPedido.Address2Bil := Nodo.ChildNodes['address2'].Text;
    FPedido.PostcodeBil := Nodo.ChildNodes['postcode'].Text;
    FPedido.CityBil := Nodo.ChildNodes['city'].Text;
    FPedido.PhoneBil := Nodo.ChildNodes['phone'].Text;
    FPedido.Phone_moBil := Nodo.ChildNodes['phone_mobile'].Text;
    FPedido.DniBil := Nodo.ChildNodes['dni'].Text;
    FPedido.CompanyBil := Nodo.ChildNodes['company'].Text;
    FPedido.Vat_numberBil := Nif;
  end;
end;

procedure TCargaPedidoPresta.CargarProvincia(const IdProvincia: string;
  Destino: TDestinoDireccionPresta);
var
  Nodo: IXMLNode;
  Nombre: string;
begin
  if (IdProvincia <> '0') and (IdProvincia <> '') then
  begin
    Nodo := SolicitarNodo(
      '/states/?display=[id,name]&filter[id]=[' + IdProvincia + ']',
      'states', 'state');
    Nombre := Nodo.ChildNodes['name'].Text;
    if Destino = ddpEntrega then
      FPedido.NameStateDel := Nombre
    else
      FPedido.NameStateBil := Nombre;
  end;
end;

procedure TCargaPedidoPresta.CargarDireccion(const IdDireccion: string;
  Destino: TDestinoDireccionPresta);
var
  Nodo: IXMLNode;
  IdProvincia: string;
  Nif: string;
begin
  Nodo := SolicitarNodo(
    '/addresses/?display=[id,firstname,lastname,address1,address2,' +
    'postcode,city,phone,phone_mobile,dni,id_state,company,vat_number]' +
    '&filter[id]=[' + IdDireccion + ']', 'addresses', 'address');
  IdProvincia := Nodo.ChildNodes['id_state'].Text;
  if Destino = ddpEntrega then
    Nif := LeerNif(Nodo, 'vatnumber', 'vat_number')
  else
    Nif := LeerNif(Nodo, 'vat_number', 'vatnumber');
  AsignarDireccion(Nodo, Nif, Destino);
  CargarProvincia(IdProvincia, Destino);
end;

procedure TCargaPedidoPresta.CargarDirecciones;
begin
  CargarDireccion(FIdDireccionEntrega, ddpEntrega);
  if FIdDireccionFacturacion = FIdDireccionEntrega then
  begin
    FPedido.SameAddress := True;
    FPedido.PutAdressDelinbil;
  end
  else
  begin
    FPedido.SameAddress := False;
    CargarDireccion(FIdDireccionFacturacion, ddpFacturacion);
  end;
end;

procedure TCargaPedidoPresta.CargarCabeceraEconomica;
begin
  FIdTransportista := FNodoPedido.ChildNodes['id_carrier'].Text;
  FIdEstadoPedido := FNodoPedido.ChildNodes['current_state'].Text;
  FPedido.FechaCreacion := FNodoPedido.ChildNodes['date_add'].Text;
  FPedido.FormaPago := FNodoPedido.ChildNodes['payment'].Text;
  FPedido.TotalPedCIVA :=
    LeerImporte(FNodoPedido, 'total_paid_tax_incl');
  FPedido.TotalPedSIVA :=
    LeerImporte(FNodoPedido, 'total_paid_tax_excl');
  FPedido.TotalPagadoReal :=
    LeerImporte(FNodoPedido, 'total_paid_real');
  FPedido.TotalProdSIVA :=
    LeerImporte(FNodoPedido, 'total_products');
  FPedido.TotalProdCIVA :=
    LeerImporte(FNodoPedido, 'total_products_wt');
  FPedido.TotalPortesCIVA :=
    LeerImporte(FNodoPedido, 'total_shipping_tax_incl');
  FPedido.TotalPortesSIVA :=
    LeerImporte(FNodoPedido, 'total_shipping_tax_excl');
  FPedido.ReferenciaCliente := FNodoPedido.ChildNodes['reference'].Text;
end;

procedure TCargaPedidoPresta.CargarTransportista;
var
  Nodo: IXMLNode;
begin
  if (FIdTransportista <> '') and (FIdTransportista <> '0') then
  begin
    Nodo := SolicitarNodo(
      '/carriers/?display=[name]&filter[id]=[' + FIdTransportista + ']',
      'carriers', 'carrier');
    FPedido.Transportista := Nodo.ChildNodes['name'].Text;
  end;
end;

procedure TCargaPedidoPresta.CargarEstadoPedido;
var
  Nodo: IXMLNode;
  NodoNombre: IXMLNode;
  NodoIdioma: IXMLNode;
begin
  if (FIdEstadoPedido <> '') and (FIdEstadoPedido <> '0') then
  begin
    Nodo := SolicitarNodo(
      '/order_states/?display=[name]&filter[id]=[' +
      FIdEstadoPedido + ']', 'order_states', 'order_state');
    NodoNombre := Nodo.ChildNodes['name'];
    NodoIdioma := NodoNombre.ChildNodes['language'];
    if Assigned(NodoIdioma) then
      FPedido.EstadoPedido := NodoIdioma.Text
    else
      FPedido.EstadoPedido := NodoNombre.Text;
  end;
end;

procedure TCargaPedidoPresta.CargarLineas;
var
  Nodo: IXMLNode;
  NodoAsociaciones: IXMLNode;
  NodoLineas: IXMLNode;
  Linea: TLineaPed;
  PrecioConIva: string;
  PrecioSinIva: string;
begin
  NodoAsociaciones := FNodoPedido.ChildNodes['associations'];
  if Assigned(NodoAsociaciones) then
  begin
    NodoLineas := NodoAsociaciones.ChildNodes['order_rows'];
    if Assigned(NodoLineas) then
    begin
      Nodo := NodoLineas.ChildNodes['order_row'];
      while Assigned(Nodo) and (Nodo.NodeName = 'order_row') do
      begin
        Linea.idLinea := Nodo.ChildNodes['id'].Text;
        Linea.idProducto := Nodo.ChildNodes['product_id'].Text;
        Linea.sCantidad := Nodo.ChildNodes['product_quantity'].Text;
        Linea.sDescripcion := Nodo.ChildNodes['product_name'].Text;
        Linea.sRefAtrib := Nodo.ChildNodes['product_attribute_id'].Text;
        Linea.sRefProd := Nodo.ChildNodes['product_reference'].Text;
        Linea.sCodEAN13 := Nodo.ChildNodes['product_ean13'].Text;
        PrecioConIva := Nodo.ChildNodes['unit_price_tax_incl'].Text;
        PrecioSinIva := Nodo.ChildNodes['unit_price_tax_excl'].Text;
        Linea.cPrecioCIVA := StrToFloatDef(
          StringReplace(PrecioConIva, '.', ',', []), 0);
        Linea.cPrecioSIVA := StrToFloatDef(
          StringReplace(PrecioSinIva, '.', ',', []), 0);
        FPedido.LineasPedido.Add(Linea);
        Nodo := Nodo.NextSibling;
      end;
    end;
  end;
end;

procedure TCargaPedidoPresta.CargarMensajesHilo(const IdHilo: string);
var
  Nodo: IXMLNode;
  NodoMensajes: IXMLNode;
  Mensaje: TMensaje;
begin
  NodoMensajes := SolicitarNodo(
    '/customer_messages/?display=full&filter[id_customer_thread]=[' +
    IdHilo + ']', 'customer_messages', 'customer_message');
  Nodo := NodoMensajes;
  while Assigned(Nodo) and (Nodo.NodeName = 'customer_message') do
  begin
    Mensaje.idMensaje := Nodo.ChildNodes['id'].Text;
    Mensaje.Texto := Nodo.ChildNodes['message'].Text;
    Mensaje.idEmpleado := Nodo.ChildNodes['id_employee'].Text;
    Mensaje.InstanteMsg := scandatetimernof(
      'yyyy-mm-dd hh:nn:ss', Nodo.ChildNodes['date_add'].Text);
    FPedido.MensajesPedido.LMensajes.Add(Mensaje);
    Nodo := Nodo.NextSibling;
  end;
end;

procedure TCargaPedidoPresta.CargarMensajes;
var
  NodoHilo: IXMLNode;
  NodoHilos: IXMLNode;
begin
  FConexion.DoRequest(
    '/customer_threads/?display=full&filter[id_order]=[' +
    FIdPedido + ']');
  FDocumento.LoadFromXML(FConexion.Response.Content);
  FDocumento.Active := True;
  NodoHilos := FDocumento.DocumentElement.ChildNodes['customer_threads'];
  if Assigned(NodoHilos) and
     Assigned(NodoHilos.ChildNodes.FindNode('customer_thread')) then
  begin
    NodoHilo := NodoHilos.ChildNodes['customer_thread'];
    FPedido.MensajesPedido.Estado :=
      NodoHilo.ChildNodes['status'].Text;
    FPedido.MensajesPedido.idCustomer_Threat :=
      NodoHilo.ChildNodes['id'].Text;
    CargarMensajesHilo(FPedido.MensajesPedido.idCustomer_Threat);
  end;
end;

function TCargaPedidoPresta.Ejecutar(const IdPedido: string): TOrder;
begin
  CargarPedidoBase(IdPedido);
  CargarCliente;
  CargarDirecciones;
  CargarCabeceraEconomica;
  CargarTransportista;
  CargarEstadoPedido;
  CargarLineas;
  try
    CargarMensajes;
  except
    // Los pedidos sin hilos de mensajes son válidos.
    on E: Exception do
      if Assigned(FConexion.FRegistroLog) then
        FConexion.FRegistroLog.RegistrarAviso(
        'PrestaImporter: mensajes del pedido ' + IdPedido +
        ' omitidos: ' + E.Message);
  end;
  Result := FPedido;
  FPedido := nil;
end;

function TPrestaConn.CargarPedido(const sIdPedido: string): TOrder;
var
  Carga: TCargaPedidoPresta;
begin
  Carga := TCargaPedidoPresta.Create(Self);
  try
    Result := Carga.Ejecutar(sIdPedido);
  finally
    FreeAndNil(Carga);
  end;
end;

{ Función auxiliar }

function ListarPedidosResumen(const aBaseURL, aApiKey:string;
  aLista:TPrestaPedidoResumenList;
  const ARegistroLog: IRegistroLog):Boolean;
var
  Conn: TPrestaConn;
  Ord:  TOrder;
  ids:  string;
  arr:  TArray<string>;
  i:    Integer;
  res:  TPrestaPedidoResumen;
begin
  Result := False;
  if aLista = nil then Exit;
  aLista.Clear;
  Conn := TPrestaConn.Create(aBaseURL, aApiKey, ARegistroLog);
  try
    Conn.ListarPedidosResumen(ids);
    if ids = '' then Exit;
    arr := ids.Split([',']);
    for i := 0 to High(arr) do
    begin
      try
        Ord := Conn.CargarPedido(arr[i]);
        try
          res.IdPedido   := Ord.idPedido;
          res.Referencia := Ord.ReferenciaCliente;
          res.Fecha      := Ord.FechaCreacion;
          res.Cliente    := Ord.custName;
          res.Total      := CurrToStrF(Ord.TotalPedCIVA, ffNumber, 2);
          res.Estado     := Ord.EstadoPedido;
          aLista.Add(res);
        finally
          FreeAndNil(Ord);
        end;
      except
        // Saltar pedidos individuales con error sin abortar el lote.
        on E: Exception do
          if Assigned(ARegistroLog) then
            ARegistroLog.RegistrarError(
            'PrestaImporter: pedido ' + arr[i] + ' omitido: ' +
            E.Message);
      end;
    end;
    Result := True;
  finally
    FreeAndNil(Conn);
  end;
end;

end.
