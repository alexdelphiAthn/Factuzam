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
  inLibPresta;

type
  TPrestaConn = class
  private
    FBaseURL: string;
    FApiKey:  string;
    FClient:  TRESTClient;
    FRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FAuth: THTTPBasicAuthenticator;
    procedure DoRequest(const sResource:string);
  public
    constructor Create(const aBaseURL, aApiKey:string);
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
                              aLista:TPrestaPedidoResumenList):Boolean;

implementation

uses
  inLibScanDateTime;

{ TPrestaConn }

constructor TPrestaConn.Create(const aBaseURL, aApiKey: string);
begin
  inherited Create;
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
  FRequest.Free;
  FResponse.Free;
  FClient.Free;
  FAuth.Free;
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

function TPrestaConn.CargarPedido(const sIdPedido: string): TOrder;
var
  XMLDoc: IXMLDocument;
  xmlNode, xmlNodeOrder, xmlNodeOrders,
  xmlNodeCustomers, xmlNodeCustomer,
  xmlNodeAddresses, xmlNodeAddress,
  xmlNodeStates, xmlNodeState,
  xmlNodeOrderStates, xmlNodeOrderState,
  xmlNodeAssociations, xmlNodeRows,
  xmlNodeCarriers, xmlNodeCarrier,
  xmlNodeCustomerThreads, xmlNodeCustomerThread,
  xmlNodeCustomerThreadAssoc,
  xmlNodeMessages, xmlNodeMessage: IXMLNode;
  sId, sIdCli, sDirIn, sDirDe, sNom, sApell, sEmail,
  sidAdress, sFecha, sIdTransportista, sIdEstadoPedido,
  sTransportista, sEstadoPedido, sFirstname, sLastname,
  sAddress1, sAddress2, sPostcode, sCity, sPhone,
  sPhone_mobile, sDni, sCompany, sVat_number,
  sId_state, sFormaPago,
  sTotalPedidoSIVA, sTotalPedidoCIVA,
  sTotalProductosSIVA, sTotalProductosCIVA,
  sPagadoReal, sTotalPortesSIVA, sTotalPortesCIVA,
  sReferenciaPedido, sNameState: string;
begin
  Result := TOrder.Create;

  // 1) Datos generales del pedido
  DoRequest('/orders/?display=full&filter[id]=[' + sIdPedido + ']');
  XMLDoc := newXMLDocument;
  XMLDoc.LoadFromXML(FResponse.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;
  xmlNodeOrders := xmlNode.ChildNodes['orders'];
  xmlNodeOrder  := xmlNodeOrders.ChildNodes['order'];
  sId := xmlNodeOrder.ChildNodes['id'].Text;
  sIdCli := xmlNodeOrder.ChildNodes['id_customer'].Text;
  sDirDe := xmlNodeOrder.ChildNodes['id_address_delivery'].Text;
  sDirIn := xmlNodeOrder.ChildNodes['id_address_invoice'].Text;
  Result.idPedido := sId;

  // 2) Datos del cliente
  DoRequest('/customers/?display=[firstname,lastname,email]&filter[id]=[' + sIdCli + ']');
  XMLDoc.LoadFromXML(FResponse.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;
  xmlNodeCustomers := xmlNode.ChildNodes['customers'];
  xmlNodeCustomer  := xmlNodeCustomers.ChildNodes['customer'];
  sNom   := xmlNodeCustomer.ChildNodes['firstname'].Text;
  sApell := xmlNodeCustomer.ChildNodes['lastname'].Text;
  sEmail := xmlNodeCustomer.ChildNodes['email'].Text;
  Result.custName := sNom + ' ' + sApell;
  Result.custMail := sEmail;

  // 3) Dirección de envío
  DoRequest('/addresses/?display=[id,firstname,lastname,address1,address2,' +
            'postcode,city,phone,phone_mobile,dni,id_state,company,vat_number]' +
            '&filter[id]=[' + sDirDe + ']');
  XMLDoc.LoadFromXML(FResponse.Content);
  XMLDoc.Active := True;
  xmlNode := XMLDoc.DocumentElement;
  xmlNodeAddresses := xmlNode.ChildNodes['addresses'];
  xmlNodeAddress   := xmlNodeAddresses.ChildNodes['address'];
  sidAdress     := xmlNodeAddress.ChildNodes['id'].Text;
  sId_state     := xmlNodeAddress.ChildNodes['id_state'].Text;
  sFirstname    := xmlNodeAddress.ChildNodes['firstname'].Text;
  sLastname     := xmlNodeAddress.ChildNodes['lastname'].Text;
  sAddress1     := xmlNodeAddress.ChildNodes['address1'].Text;
  sAddress2     := xmlNodeAddress.ChildNodes['address2'].Text;
  sPostcode     := xmlNodeAddress.ChildNodes['postcode'].Text;
  sCity         := xmlNodeAddress.ChildNodes['city'].Text;
  sPhone        := xmlNodeAddress.ChildNodes['phone'].Text;
  sPhone_mobile := xmlNodeAddress.ChildNodes['phone_mobile'].Text;
  sDni          := xmlNodeAddress.ChildNodes['dni'].Text;
  sCompany      := xmlNodeAddress.ChildNodes['company'].Text;
  if Assigned(xmlNodeAddress.ChildNodes.FindNode('vatnumber')) then
    sVat_number := xmlNodeAddress.ChildNodes['vatnumber'].Text
  else if Assigned(xmlNodeAddress.ChildNodes.FindNode('vat_number')) then
    sVat_number := xmlNodeAddress.ChildNodes['vat_number'].Text
  else
    sVat_number := '';
  with Result do
  begin
    idAddressDel  := sidAdress;
    FirstnameDel  := sFirstname;
    LastNameDel   := sLastname;
    Address1Del   := sAddress1;
    Address2Del   := sAddress2;
    PostcodeDel   := sPostcode;
    CityDel       := sCity;
    PhoneDel      := sPhone;
    Phone_moDel   := sPhone_mobile;
    DniDel        := sDni;
    CompanyDel    := sCompany;
    Vat_numberDel := sVat_number;
  end;
  if (sId_state <> '0') and (sId_state <> '') then
  begin
    DoRequest('/states/?display=[id,name]&filter[id]=[' + sId_state + ']');
    XMLDoc.LoadFromXML(FResponse.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;
    xmlNodeStates := xmlNode.ChildNodes['states'];
    xmlNodeState  := xmlNodeStates.ChildNodes['state'];
    sNameState    := xmlNodeState.ChildNodes['name'].Text;
    Result.NameStateDel := sNameState;
  end;

  // 4) Dirección de facturación
  if (sDirIn = sDirDe) then
  begin
    Result.SameAddress := True;
    Result.PutAdressDelinbil;
  end
  else
  begin
    Result.SameAddress := False;
    DoRequest('/addresses/?display=[id,firstname,lastname,address1,address2,' +
              'postcode,city,phone,phone_mobile,dni,id_state,company,vat_number]' +
              '&filter[id]=[' + sDirIn + ']');
    XMLDoc.LoadFromXML(FResponse.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;
    xmlNodeAddresses := xmlNode.ChildNodes['addresses'];
    xmlNodeAddress   := xmlNodeAddresses.ChildNodes['address'];
    sidAdress     := xmlNodeAddress.ChildNodes['id'].Text;
    sId_state     := xmlNodeAddress.ChildNodes['id_state'].Text;
    sFirstname    := xmlNodeAddress.ChildNodes['firstname'].Text;
    sLastname     := xmlNodeAddress.ChildNodes['lastname'].Text;
    sAddress1     := xmlNodeAddress.ChildNodes['address1'].Text;
    sAddress2     := xmlNodeAddress.ChildNodes['address2'].Text;
    sPostcode     := xmlNodeAddress.ChildNodes['postcode'].Text;
    sCity         := xmlNodeAddress.ChildNodes['city'].Text;
    sPhone        := xmlNodeAddress.ChildNodes['phone'].Text;
    sPhone_mobile := xmlNodeAddress.ChildNodes['phone_mobile'].Text;
    sDni          := xmlNodeAddress.ChildNodes['dni'].Text;
    sCompany      := xmlNodeAddress.ChildNodes['company'].Text;
    if Assigned(xmlNodeAddress.ChildNodes.FindNode('vat_number')) then
      sVat_number := xmlNodeAddress.ChildNodes['vat_number'].Text
    else if Assigned(xmlNodeAddress.ChildNodes.FindNode('vatnumber')) then
      sVat_number := xmlNodeAddress.ChildNodes['vatnumber'].Text
    else
      sVat_number := '';
    with Result do
    begin
      idAddressBil  := sidAdress;
      FirstnameBil  := sFirstname;
      LastNameBil   := sLastname;
      Address1Bil   := sAddress1;
      Address2Bil   := sAddress2;
      PostcodeBil   := sPostcode;
      CityBil       := sCity;
      PhoneBil      := sPhone;
      Phone_moBil   := sPhone_mobile;
      DniBil        := sDni;
      CompanyBil    := sCompany;
      Vat_numberBil := sVat_number;
    end;
    if (sId_state <> '0') and (sId_state <> '') then
    begin
      DoRequest('/states/?display=[id,name]&filter[id]=[' + sId_state + ']');
      XMLDoc.LoadFromXML(FResponse.Content);
      XMLDoc.Active := True;
      xmlNode := XMLDoc.DocumentElement;
      xmlNodeStates := xmlNode.ChildNodes['states'];
      xmlNodeState  := xmlNodeStates.ChildNodes['state'];
      sNameState    := xmlNodeState.ChildNodes['name'].Text;
      Result.NameStateBil := sNameState;
    end;
  end;

  // 5) Cabecera económica
  sIdTransportista    := xmlNodeOrder.ChildNodes['id_carrier'].Text;
  sIdEstadoPedido     := xmlNodeOrder.ChildNodes['current_state'].Text;
  sFecha              := xmlNodeOrder.ChildNodes['date_add'].Text;
  sFormaPago          := xmlNodeOrder.ChildNodes['payment'].Text;
  sTotalPedidoCIVA    := xmlNodeOrder.ChildNodes['total_paid_tax_incl'].Text;
  sTotalPedidoSIVA    := xmlNodeOrder.ChildNodes['total_paid_tax_excl'].Text;
  sPagadoReal         := xmlNodeOrder.ChildNodes['total_paid_real'].Text;
  sTotalProductosSIVA := xmlNodeOrder.ChildNodes['total_products'].Text;
  sTotalProductosCIVA := xmlNodeOrder.ChildNodes['total_products_wt'].Text;
  sTotalPortesCIVA    := xmlNodeOrder.ChildNodes['total_shipping_tax_incl'].Text;
  sTotalPortesSIVA    := xmlNodeOrder.ChildNodes['total_shipping_tax_excl'].Text;
  sReferenciaPedido   := xmlNodeOrder.ChildNodes['reference'].Text;
  with Result do
  begin
    FechaCreacion     := sFecha;
    FormaPago         := sFormaPago;
    TotalPedCIVA      := StrToFloatDef(StringReplace(sTotalPedidoCIVA, '.', ',', []), 0);
    TotalPedSIVA      := StrToFloatDef(StringReplace(sTotalPedidoSIVA, '.', ',', []), 0);
    TotalPagadoReal   := StrToFloatDef(StringReplace(sPagadoReal, '.', ',', []), 0);
    TotalProdSIVA     := StrToFloatDef(StringReplace(sTotalProductosSIVA, '.', ',', []), 0);
    TotalProdCIVA     := StrToFloatDef(StringReplace(sTotalProductosCIVA, '.', ',', []), 0);
    TotalPortesCIVA   := StrToFloatDef(StringReplace(sTotalPortesCIVA, '.', ',', []), 0);
    TotalPortesSIVA   := StrToFloatDef(StringReplace(sTotalPortesSIVA, '.', ',', []), 0);
    ReferenciaCliente := sReferenciaPedido;
  end;

  // 6) Transportista
  if (sIdTransportista <> '') and (sIdTransportista <> '0') then
  begin
    DoRequest('/carriers/?display=[name]&filter[id]=[' + sIdTransportista + ']');
    XMLDoc.LoadFromXML(FResponse.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;
    xmlNodeCarriers := xmlNode.ChildNodes['carriers'];
    xmlNodeCarrier  := xmlNodeCarriers.ChildNodes['carrier'];
    sTransportista  := xmlNodeCarrier.ChildNodes['name'].Text;
    Result.Transportista := sTransportista;
  end;

  // 7) Estado del pedido
  if (sIdEstadoPedido <> '') and (sIdEstadoPedido <> '0') then
  begin
    DoRequest('/order_states/?display=[name]&filter[id]=[' + sIdEstadoPedido + ']');
    XMLDoc.LoadFromXML(FResponse.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;
    xmlNodeOrderStates := xmlNode.ChildNodes['order_states'];
    xmlNodeOrderState  := xmlNodeOrderStates.ChildNodes['order_state'];
    xmlNodeOrderState  := xmlNodeOrderState.ChildNodes['name'];
    xmlNode := xmlNodeOrderState.ChildNodes['language'];
    if Assigned(xmlNode) then
      sEstadoPedido := xmlNode.Text
    else
      sEstadoPedido := xmlNodeOrderState.Text;
    Result.EstadoPedido := sEstadoPedido;
  end;

  // 8) Líneas
  xmlNodeAssociations := xmlNodeOrder.ChildNodes['associations'];
  if Assigned(xmlNodeAssociations) then
  begin
    xmlNodeRows := xmlNodeAssociations.ChildNodes['order_rows'];
    if Assigned(xmlNodeRows) then
    begin
      xmlNode := xmlNodeRows.ChildNodes['order_row'];
      while Assigned(xmlNode) and (xmlNode.NodeName = 'order_row') do
      begin
        var lp: TLineaPed;
        lp.idLinea     := xmlNode.ChildNodes['id'].Text;
        lp.idProducto  := xmlNode.ChildNodes['product_id'].Text;
        lp.sCantidad   := xmlNode.ChildNodes['product_quantity'].Text;
        lp.sDescripcion := xmlNode.ChildNodes['product_name'].Text;
        lp.sRefAtrib   := xmlNode.ChildNodes['product_attribute_id'].Text;
        lp.sRefProd    := xmlNode.ChildNodes['product_reference'].Text;
        lp.sCodEAN13   := xmlNode.ChildNodes['product_ean13'].Text;
        var sPCIVA := xmlNode.ChildNodes['unit_price_tax_incl'].Text;
        var sPSIVA := xmlNode.ChildNodes['unit_price_tax_excl'].Text;
        lp.cPrecioCIVA := StrToFloatDef(StringReplace(sPCIVA, '.', ',', []), 0);
        lp.cPrecioSIVA := StrToFloatDef(StringReplace(sPSIVA, '.', ',', []), 0);
        Result.LineasPedido.Add(lp);
        xmlNode := xmlNode.NextSibling;
      end;
    end;
  end;

  // 9) Mensajes
  try
    DoRequest('/customer_threads/?display=full&filter[id_order]=[' + sId + ']');
    XMLDoc.LoadFromXML(FResponse.Content);
    XMLDoc.Active := True;
    xmlNode := XMLDoc.DocumentElement;
    xmlNodeCustomerThreads := xmlNode.ChildNodes['customer_threads'];
    if Assigned(xmlNodeCustomerThreads) and
       Assigned(xmlNodeCustomerThreads.ChildNodes.FindNode('customer_thread')) then
    begin
      xmlNodeCustomerThread := xmlNodeCustomerThreads.ChildNodes['customer_thread'];
      Result.MensajesPedido.Estado := xmlNodeCustomerThread.ChildNodes['status'].Text;
      Result.MensajesPedido.idCustomer_Threat :=
                                xmlNodeCustomerThread.ChildNodes['id'].Text;
      DoRequest('/customer_messages/?display=full&filter[id_customer_thread]=[' +
                Result.MensajesPedido.idCustomer_Threat + ']');
      XMLDoc.LoadFromXML(FResponse.Content);
      XMLDoc.Active := True;
      xmlNode := XMLDoc.DocumentElement;
      xmlNodeMessages := xmlNode.ChildNodes['customer_messages'];
      if Assigned(xmlNodeMessages) then
      begin
        xmlNodeMessage := xmlNodeMessages.ChildNodes['customer_message'];
        while Assigned(xmlNodeMessage) and (xmlNodeMessage.NodeName = 'customer_message') do
        begin
          var tm: TMensaje;
          tm.idMensaje   := xmlNodeMessage.ChildNodes['id'].Text;
          tm.Texto       := xmlNodeMessage.ChildNodes['message'].Text;
          tm.idEmpleado  := xmlNodeMessage.ChildNodes['id_employee'].Text;
          tm.InstanteMsg := scandatetimernof('yyyy-mm-dd hh:nn:ss',
                                  xmlNodeMessage.ChildNodes['date_add'].Text);
          Result.MensajesPedido.LMensajes.Add(tm);
          xmlNodeMessage := xmlNodeMessage.NextSibling;
        end;
      end;
    end;
  except
    // Si el pedido no tiene hilos de mensajes, ignoramos.
  end;
end;

{ Función auxiliar }

function ListarPedidosResumen(const aBaseURL, aApiKey:string;
                              aLista:TPrestaPedidoResumenList):Boolean;
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
  Conn := TPrestaConn.Create(aBaseURL, aApiKey);
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
          Ord.Free;
        end;
      except
        on E: Exception do
          // Saltar pedidos individuales con error sin abortar el lote
          ;
      end;
    end;
    Result := True;
  finally
    Conn.Free;
  end;
end;

end.
