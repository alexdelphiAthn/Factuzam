{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosPrestaShopEscrituras                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                               }
{    Escritura atómica de cabecera, líneas y mensajes de PrestaShop.          }
{******************************************************************************}
unit UniDataPedidosPrestaShopEscrituras;

interface

uses
  Uni,
  inLibLogIntf,
  inLibPresta;

type
  TEntradaPedidoPrestaShop = record
    Pedido: TOrder;
    Numero: string;
    Serie: string;
    CodigoCliente: string;
    Empresa: string;
    Almacen: string;
    CodigosArticulo: TArray<string>;
  end;
  TPedidosPrestaShopEscrituras = class
  private
    FConexion: TUniConnection;
    FRegistroLog: IRegistroLog;
    FUsuario: string;
    procedure ConfigurarCabecera(AConsulta: TUniQuery);
    procedure AsignarCabecera(
      AConsulta: TUniQuery;
      const AEntrada: TEntradaPedidoPrestaShop);
    procedure ConfigurarLineas(AConsulta: TUniQuery);
    procedure InsertarLineas(
      AConsulta: TUniQuery;
      const AEntrada: TEntradaPedidoPrestaShop);
    procedure ConfigurarMensajes(AConsulta: TUniQuery);
    procedure InsertarMensajes(
      AConsulta: TUniQuery;
      APedido: TOrder);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog);
    procedure Ejecutar(const AEntrada: TEntradaPedidoPrestaShop);
  end;

implementation

uses
  System.SysUtils;

constructor TPedidosPrestaShopEscrituras.Create(
  AConexion: TUniConnection;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FUsuario := AUsuario;
  FRegistroLog := ARegistroLog;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarCabecera(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos (NUMERO_PED, SERIE_PED, FECHA_PED, ' +
    ' ESTADO_PED, CODIGO_EMP_PED, CODIGO_ALM_PED, CODIGO_CLI_PED, ' +
    ' IDPS_PED, FECHAPS_PED, REFERENCIAPS_PED, ' +
    ' FORMAPAGOPS_PED, TRANSPORTISTAPS_PED, ESTADOPEDIDOPS_PED, ' +
    ' EMAIL_CLIENTE_PED, NIF_CLIENTE_PED, ' +
    ' NOMBRE_CLI_ENVIO_PED, MOVIL_CLIENTE_ENVIO_PED, ' +
    ' DIRECCION1_CLIENTE_ENVIO_PED, DIRECCION2_CLIENTE_ENVIO_PED, ' +
    ' POBLACION_CLIENTE_ENVIO_PED, PROVINCIA_CLIENTE_ENVIO_PED, ' +
    ' CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
    ' RAZON_SOCIAL_CLIENTE_FISCAL_PED, MOVIL_CLIENTE_FISCAL_PED, ' +
    ' DIRECCION1_CLIENTE_FISCAL_PED, DIRECCION2_CLIENTE_FISCAL_PED, ' +
    ' POBLACION_CLIENTE_FISCAL_PED, PROVINCIA_CLIENTE_FISCAL_PED, ' +
    ' CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
    ' TOTAL_LIQUIDO_PED, TOTAL_PAGADOREALPS_PED, ' +
    ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :FECHA, :ESTADO, :CODEMP, :CODALM, ' +
    ' :CODCLI, :IDPS, :FECHAPS, :REFPS, :FORMAPAGO, :TRANSP, ' +
    ' :ESTADOPS, :EMAILCLI, :NIFCLI, :NOMENV, :MOVENV, :DIR1ENV, ' +
    ' :DIR2ENV, :POBLENV, :PROVENV, :CPENV, :RSFIS, :MOVFIS, ' +
    ' :DIR1FIS, :DIR2FIS, :POBLFIS, :PROVFIS, :CPFIS, :TOTAL, ' +
    ' :PAGADO, NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.AsignarCabecera(
  AConsulta: TUniQuery;
  const AEntrada: TEntradaPedidoPrestaShop);
var
  oPedido: TOrder;
begin
  oPedido := AEntrada.Pedido;
  AConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
  AConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
  AConsulta.ParamByName('FECHA').AsDateTime := Date;
  AConsulta.ParamByName('ESTADO').AsString := 'IMPORTADO';
  AConsulta.ParamByName('CODEMP').AsString := AEntrada.Empresa;
  AConsulta.ParamByName('CODALM').AsString := AEntrada.Almacen;
  AConsulta.ParamByName('CODCLI').AsString := AEntrada.CodigoCliente;
  AConsulta.ParamByName('IDPS').AsString := oPedido.idPedido;
  AConsulta.ParamByName('FECHAPS').AsString := oPedido.FechaCreacion;
  AConsulta.ParamByName('REFPS').AsString := oPedido.ReferenciaCliente;
  AConsulta.ParamByName('FORMAPAGO').AsString := oPedido.FormaPago;
  AConsulta.ParamByName('TRANSP').AsString := oPedido.Transportista;
  AConsulta.ParamByName('ESTADOPS').AsString := oPedido.EstadoPedido;
  AConsulta.ParamByName('EMAILCLI').AsString := oPedido.custMail;
  AConsulta.ParamByName('NIFCLI').AsString := oPedido.DniDel;
  AConsulta.ParamByName('NOMENV').AsString :=
    oPedido.FirstnameDel + ' ' + oPedido.LastNameDel;
  AConsulta.ParamByName('MOVENV').AsString := oPedido.PhoneDel;
  AConsulta.ParamByName('DIR1ENV').AsString := oPedido.Address1Del;
  AConsulta.ParamByName('DIR2ENV').AsString := oPedido.Address2Del;
  AConsulta.ParamByName('POBLENV').AsString := oPedido.CityDel;
  AConsulta.ParamByName('PROVENV').AsString := oPedido.NameStateDel;
  AConsulta.ParamByName('CPENV').AsString := oPedido.PostcodeDel;
  AConsulta.ParamByName('RSFIS').AsString := oPedido.CompanyBil;
  AConsulta.ParamByName('MOVFIS').AsString := oPedido.PhoneBil;
  AConsulta.ParamByName('DIR1FIS').AsString := oPedido.Address1Bil;
  AConsulta.ParamByName('DIR2FIS').AsString := oPedido.Address2Bil;
  AConsulta.ParamByName('POBLFIS').AsString := oPedido.CityBil;
  AConsulta.ParamByName('PROVFIS').AsString := oPedido.NameStateBil;
  AConsulta.ParamByName('CPFIS').AsString := oPedido.PostcodeBil;
  AConsulta.ParamByName('TOTAL').AsCurrency := oPedido.TotalPedCIVA;
  AConsulta.ParamByName('PAGADO').AsCurrency := oPedido.TotalPagadoReal;
  AConsulta.ParamByName('USU').AsString := FUsuario;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarLineas(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos_lineas (NUMERO_PED_PEDLIN, ' +
    ' SERIE_PED_PEDLIN, LINEA_PEDLIN, IDLINEAPS_PEDLIN, ' +
    ' IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, IDATRIBPRODPS_PEDLIN, ' +
    ' CODIGO_ART_PEDLIN, CODBAR_ART_PEDLIN, ' +
    ' DESCRIPCION_ARTICULO_PEDLIN, CANTIDAD_PEDLIN, ' +
    ' CANTIDAD_ENTREGADA_PEDLIN, CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    ' CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
    ' CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    ' PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, TOTAL_PEDLIN, ' +
    ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:NUMERO, :SERIE, :LIN, :IDLPS, :IDPPS, :REFPROD, ' +
    ' :IDATRIB, :CODART, :EAN13, :DESCR, :CANT, 0, 0, :CANT, ''N'', ' +
    ' :CODALM, :PSIVA, :PCIVA, :TOT, NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.InsertarLineas(
  AConsulta: TUniQuery;
  const AEntrada: TEntradaPedidoPrestaShop);
var
  i: Integer;
  oLinea: TLineaPed;
  dCantidad: Double;
begin
  for i := 0 to AEntrada.Pedido.LineasPedido.Count - 1 do
  begin
    oLinea := AEntrada.Pedido.LineasPedido[i];
    dCantidad := StrToFloatDef(oLinea.sCantidad, 1);
    AConsulta.ParamByName('NUMERO').AsString := AEntrada.Numero;
    AConsulta.ParamByName('SERIE').AsString := AEntrada.Serie;
    AConsulta.ParamByName('LIN').AsString := Format('%.4d', [(i + 1) * 10]);
    AConsulta.ParamByName('IDLPS').AsString := oLinea.idLinea;
    AConsulta.ParamByName('IDPPS').AsString := oLinea.idProducto;
    AConsulta.ParamByName('REFPROD').AsString := oLinea.sRefProd;
    AConsulta.ParamByName('IDATRIB').AsString := oLinea.sRefAtrib;
    AConsulta.ParamByName('CODART').AsString :=
      AEntrada.CodigosArticulo[i];
    AConsulta.ParamByName('EAN13').AsString := oLinea.sCodEAN13;
    AConsulta.ParamByName('DESCR').AsString := oLinea.sDescripcion;
    AConsulta.ParamByName('CANT').AsFloat := dCantidad;
    AConsulta.ParamByName('CODALM').AsString := AEntrada.Almacen;
    AConsulta.ParamByName('PSIVA').AsCurrency := oLinea.cPrecioSIVA;
    AConsulta.ParamByName('PCIVA').AsCurrency := oLinea.cPrecioCIVA;
    AConsulta.ParamByName('TOT').AsCurrency := oLinea.cPrecioCIVA * dCantidad;
    AConsulta.ParamByName('USU').AsString := FUsuario;
    AConsulta.Execute;
  end;
end;

procedure TPedidosPrestaShopEscrituras.ConfigurarMensajes(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_pedidos_mensajes (IDPS_MENSAJES_PEDMSG, ' +
    ' IDMENSAJEPS_PEDMSG, IDEMPLEADOPS_PEDMSG, MENSAJEPS_PEDMSG, ' +
    ' FECHAPS_PEDMSG, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:HILO, :IDM, :IDE, :MSG, :FECHA, NOW(), :USU, :USU)';
end;

procedure TPedidosPrestaShopEscrituras.InsertarMensajes(
  AConsulta: TUniQuery;
  APedido: TOrder);
var
  oMensaje: TMensaje;
begin
  for oMensaje in APedido.MensajesPedido.LMensajes do
  begin
    AConsulta.ParamByName('HILO').AsString :=
      APedido.MensajesPedido.idCustomer_Threat;
    AConsulta.ParamByName('IDM').AsString := oMensaje.idMensaje;
    AConsulta.ParamByName('IDE').AsString := oMensaje.idEmpleado;
    AConsulta.ParamByName('MSG').AsString := oMensaje.Texto;
    AConsulta.ParamByName('FECHA').AsDateTime := oMensaje.InstanteMsg;
    AConsulta.ParamByName('USU').AsString := FUsuario;
    try
      AConsulta.Execute;
    except
      on E: Exception do
      begin
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarInformacion(
            'ImportarPedidoPrestaShop: mensaje ' + oMensaje.idMensaje +
            ' omitido: ' + E.Message);
      end;
    end;
  end;
end;

procedure TPedidosPrestaShopEscrituras.Ejecutar(
  const AEntrada: TEntradaPedidoPrestaShop);
var
  oCabecera: TUniQuery;
  oLineas: TUniQuery;
  oMensajes: TUniQuery;
  EsTransaccionPropia: Boolean;
begin
  oCabecera := nil;
  oLineas := nil;
  oMensajes := nil;
  try
    oCabecera := TUniQuery.Create(nil);
    oLineas := TUniQuery.Create(nil);
    oMensajes := TUniQuery.Create(nil);
    oCabecera.Connection := FConexion;
    oLineas.Connection := FConexion;
    oMensajes.Connection := FConexion;
    ConfigurarCabecera(oCabecera);
    ConfigurarLineas(oLineas);
    ConfigurarMensajes(oMensajes);
    EsTransaccionPropia := not FConexion.InTransaction;
    if EsTransaccionPropia then
      FConexion.StartTransaction;
    try
      AsignarCabecera(oCabecera, AEntrada);
      oCabecera.Execute;
      InsertarLineas(oLineas, AEntrada);
      InsertarMensajes(oMensajes, AEntrada.Pedido);
      if EsTransaccionPropia then
        FConexion.Commit;
    except
      if EsTransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oMensajes);
    FreeAndNil(oLineas);
    FreeAndNil(oCabecera);
  end;
end;

end.
