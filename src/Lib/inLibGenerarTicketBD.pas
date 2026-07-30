{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketBD                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera tickets desde read models sin conocer UniDAC ni el esquema SQL.    }
{******************************************************************************}
unit inLibGenerarTicketBD;

interface

uses
  System.SysUtils, System.Classes, inLibFTicket,
  inLibUnidadesMedida, inLibDir, inLibParametrosIntf,
  inLibTicketsCajaIntf;

procedure ImprimirResguardoDeposito(
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False);
procedure ImprimirTicketDesdeBD(
  const AParametrosApp: IParametrosAplicacion;
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  ANumeroOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False;
  AImprimirCodigoBarras: Boolean = False);
procedure ImprimirRecordatorio(
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False);

implementation

uses
  inLibVerifactu, inLibFormatoDocumento,
  inLibPreviewTicket, inLibMsgCaja;

function LPAD(
  const AValue: string;
  ALength: Integer;
  const APadChar: Char = '0'): string;
var
  iLongitudActual: Integer;
begin
  iLongitudActual := Length(AValue);
  if iLongitudActual >= ALength then
    Result := AValue
  else
    Result := StringOfChar(APadChar, ALength - iLongitudActual) + AValue;
end;

procedure EscribirPieTicket(
  ATicket: TTicketTermico;
  const ALineas: TArray<string>);
var
  bHaEscrito: Boolean;
  i: Integer;
  sLinea: string;
begin
  bHaEscrito := False;
  if ATicket <> nil then
  begin
    for i := 0 to High(ALineas) do
    begin
      sLinea := Copy(Trim(ALineas[i]), 1, 42);
      if sLinea <> '' then
      begin
        if not bHaEscrito then
        begin
          ATicket.SaltarLineas(1);
          ATicket.Alinear(alCentro);
          bHaEscrito := True;
        end;
        ATicket.EscribirLinea(sLinea);
      end;
    end;
  end;
end;

type
  TGeneradorResguardoDeposito = class
  private
    FRepositorio: IRepositorioTicketsCaja;
    FContexto: TContextoOperacionTicketCaja;
    FNombreImpresora: string;
    FRutasPDF: TStrings;
    FSoloPDF: Boolean;
    FTicket: TTicketTermico;
    FNombreEmpresa: string;
    FFechaOperacion: TDateTime;
    FNuevosDepositos: TArray<TDepositoResguardoTicketCaja>;
    FTotalNuevos: Currency;
    FTotalEntregas: Currency;
    FTotalDevoluciones: Currency;
    FTotalDevueltos: Currency;
    procedure CargarCabecera;
    procedure EscribirTituloSeccion(const ATitulo: string);
    procedure EscribirCabecera;
    procedure EscribirDepositos(
      const ATitulo: string;
      ASaltarAntes: Boolean;
      const ADepositos: TArray<TDepositoResguardoTicketCaja>;
      var ATotal: Currency);
    procedure EscribirEntregas;
    procedure EscribirDevolucionEconomica;
    procedure EscribirResumen;
    procedure GenerarSalida;
    function HayMovimientos: Boolean;
    function TotalPagadoCaja: Currency;
  public
    constructor Create(
      const ARepositorio: IRepositorioTicketsCaja;
      const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
      AOperacion, ANombreImpresora: string;
      ARutasPDF: TStrings;
      ASoloPDF: Boolean);
    destructor Destroy; override;
    procedure Ejecutar;
  end;

constructor TGeneradorResguardoDeposito.Create(
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion, ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FContexto.Empresa := ACodigoEmpresa;
  FContexto.Almacen := ACodigoAlmacen;
  FContexto.Caja := ACodigoCaja;
  FContexto.Operacion := AOperacion;
  FNombreImpresora := ANombreImpresora;
  FRutasPDF := ARutasPDF;
  FSoloPDF := ASoloPDF;
  FTicket := TTicketTermico.Create(FNombreImpresora);
end;

destructor TGeneradorResguardoDeposito.Destroy;
begin
  FreeAndNil(FTicket);
  FRepositorio := nil;
  inherited;
end;

procedure TGeneradorResguardoDeposito.CargarCabecera;
var
  oEmpresa: TEmpresaResguardoTicketCaja;
  oFecha: TFechaResguardoTicketCaja;
begin
  FFechaOperacion := 0;
  oEmpresa := FRepositorio.ObtenerEmpresaResguardo(
    FContexto.Empresa);
  if oEmpresa.Encontrada then
    FNombreEmpresa := oEmpresa.RazonSocial;
  oFecha := FRepositorio.ObtenerFechaResguardo(FContexto);
  if oFecha.Encontrada then
    FFechaOperacion := oFecha.FechaOperacion;
end;

procedure TGeneradorResguardoDeposito.EscribirTituloSeccion(
  const ATitulo: string);
begin
  FTicket.LineaSeparadora('=');
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(ATitulo);
  FTicket.Negrita(False);
  FTicket.LineaSeparadora('-');
  FTicket.Alinear(alIzquierda);
end;

procedure TGeneradorResguardoDeposito.EscribirCabecera;
var
  sCodigoCliente: string;
begin
  sCodigoCliente := '';
  if Length(FNuevosDepositos) > 0 then
    sCodigoCliente := FNuevosDepositos[0].CodigoCliente;
  FTicket.Inicializar;
  FTicket.Alinear(alCentro);
  FTicket.Negrita(True);
  if FNombreEmpresa <> '' then
    FTicket.EscribirLinea(FNombreEmpresa);
  FTicket.SaltarLineas(1);
  FTicket.EscribirLinea('*** RESUMEN DE LA OPERACIÓN ***');
  FTicket.EscribirLinea('DEPÓSITOS Y ENTREGAS');
  FTicket.Negrita(False);
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alIzquierda);
  FTicket.TextoColumnas('CÓDIGO CLIENTE:', sCodigoCliente);
  FTicket.TextoColumnas(
    'FECHA:',
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaOperacion));
  FTicket.TextoColumnas('Nº OPERACIÓN:', FContexto.Operacion);
  FTicket.SaltarLineas(1);
end;

procedure TGeneradorResguardoDeposito.EscribirDepositos(
  const ATitulo: string;
  ASaltarAntes: Boolean;
  const ADepositos: TArray<TDepositoResguardoTicketCaja>;
  var ATotal: Currency);
var
  i: Integer;
begin
  if Length(ADepositos) > 0 then
  begin
    if ASaltarAntes then
      FTicket.SaltarLineas(1);
    EscribirTituloSeccion(ATitulo);
    for i := 0 to High(ADepositos) do
    begin
      ATotal := ATotal + ADepositos[i].TotalPvp;
      if ADepositos[i].Descripcion <> '' then
        FTicket.EscribirLinea(
          Copy(ADepositos[i].Descripcion, 1, 40));
      FTicket.EscribirLinea(ADepositos[i].CodigoUnidad);
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        'Valor Artículo: ' +
        FormatFloat('#,##0.00', ADepositos[i].TotalPvp) + ' €');
      FTicket.Alinear(alIzquierda);
    end;
    FTicket.SaltarLineas(1);
  end;
end;

procedure TGeneradorResguardoDeposito.EscribirEntregas;
var
  i: Integer;
  sConcepto: string;
  oEntregas: TArray<TEntregaResguardoTicketCaja>;
begin
  oEntregas := FRepositorio.ListarEntregasResguardo(FContexto);
  if Length(oEntregas) > 0 then
  begin
    EscribirTituloSeccion('ENTREGAS A CUENTA');
    for i := 0 to High(oEntregas) do
    begin
      FTotalEntregas := FTotalEntregas + oEntregas[i].Importe;
      sConcepto := '';
      if Trim(oEntregas[i].DescripcionArticulo) <> '' then
      begin
        if oEntregas[i].TipoOperacion = 'CB' then
          sConcepto := 'A cuenta: ' + oEntregas[i].DescripcionArticulo
        else if oEntregas[i].TipoOperacion = 'DE' then
          sConcepto := 'A cta. inicial: ' +
            oEntregas[i].DescripcionArticulo;
      end
      else
      begin
        if oEntregas[i].TipoOperacion = 'CB' then
          sConcepto := 'A cuenta para artículo pendiente'
        else if oEntregas[i].TipoOperacion = 'DE' then
          sConcepto := 'A cuenta inicial';
      end;
      FTicket.EscribirLinea(Copy(sConcepto, 1, 40));
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        FormatFloat('#,##0.00', oEntregas[i].Importe) + ' €');
      FTicket.Alinear(alIzquierda);
    end;
    FTicket.SaltarLineas(1);
  end;
end;

procedure TGeneradorResguardoDeposito.EscribirDevolucionEconomica;
var
  i: Integer;
  oDevoluciones: TArray<TDevolucionEconomicaTicketCaja>;
begin
  oDevoluciones :=
    FRepositorio.ListarDevolucionesEconomicasResguardo(FContexto);
  if Length(oDevoluciones) > 0 then
  begin
    EscribirTituloSeccion('DEVOLUCIÓN ECONÓMICA');
    for i := 0 to High(oDevoluciones) do
    begin
      FTotalDevoluciones :=
        FTotalDevoluciones + oDevoluciones[i].Importe;
      FTicket.EscribirLinea(
        Copy(oDevoluciones[i].TipoOperacion, 1, 40));
      FTicket.Alinear(alDerecha);
      FTicket.EscribirLinea(
        FormatFloat('#,##0.00', oDevoluciones[i].Importe) + ' €');
      FTicket.Alinear(alIzquierda);
    end;
  end;
end;

function TGeneradorResguardoDeposito.HayMovimientos: Boolean;
begin
  Result :=
    (FTotalNuevos <> 0) or
    (FTotalEntregas <> 0) or
    (FTotalDevoluciones <> 0) or
    (FTotalDevueltos <> 0);
end;

function TGeneradorResguardoDeposito.TotalPagadoCaja: Currency;
begin
  Result := FRepositorio.ObtenerTotalPagadoResguardo(FContexto);
end;

procedure TGeneradorResguardoDeposito.EscribirResumen;
var
  dTotalPagado: Currency;
begin
  dTotalPagado := TotalPagadoCaja;
  FTicket.LineaSeparadora('=');
  FTicket.SaltarLineas(1);
  FTicket.Alinear(alDerecha);
  if FTotalNuevos > 0 then
    FTicket.EscribirLinea(
      'TOTAL NUEVOS DEPÓSITOS: ' +
      FormatFloat('#,##0.00', FTotalNuevos) + ' €');
  if FTotalDevueltos <> 0 then
    FTicket.EscribirLinea(
      'TOTAL DEPÓSITOS DEVUELTOS: ' +
      FormatFloat('#,##0.00', FTotalDevueltos) + ' €');
  FTicket.EscribirLinea(
    'ANTICIPOS ENTREGADOS AHORA: ' +
    FormatFloat('#,##0.00', FTotalEntregas) + ' €');
  if FTotalDevoluciones < 0 then
    FTicket.EscribirLinea(
      'DEVUELTO EN ESTA OPERACIÓN: ' +
      FormatFloat('#,##0.00', FTotalDevoluciones) + ' €');
  FTicket.SaltarLineas(1);
  FTicket.Negrita(True);
  FTicket.EscribirLinea(
    'TOTAL PAGADO (TICKET + DEPÓSITOS): ' +
    FormatFloat('#,##0.00', dTotalPagado) + ' €');
  FTicket.Negrita(False);
  FTicket.SaltarLineas(2);
  FTicket.Alinear(alCentro);
  FTicket.EscribirLinea('Conforme, el cliente');
  FTicket.SaltarLineas(4);
  FTicket.LineaSeparadora('_');
  EscribirPieTicket(
    FTicket,
    FRepositorio.ListarPieTicket(FContexto.Empresa));
  FTicket.CortarPapel;
end;

procedure TGeneradorResguardoDeposito.GenerarSalida;
var
  sComandosEsc: string;
  sRutaFicheroPdf: string;
begin
  sComandosEsc := FTicket.ObtenerComandos;
  sRutaFicheroPdf :=
    GetUserFolderTickets + 'ResguardoDep_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
  ImprimirOPrevisualizarTicket(
    FTicket,
    sComandosEsc,
    sRutaFicheroPdf,
    FNombreImpresora,
    FSoloPDF);
  if (FRutasPDF <> nil) and FileExists(sRutaFicheroPdf) then
    FRutasPDF.Add(sRutaFicheroPdf);
end;

procedure TGeneradorResguardoDeposito.Ejecutar;
var
  oDepositosDevueltos: TArray<TDepositoResguardoTicketCaja>;
begin
  CargarCabecera;
  FNuevosDepositos :=
    FRepositorio.ListarNuevosDepositosResguardo(FContexto);
  EscribirCabecera;
  EscribirDepositos(
    'MOVIMIENTO DE DEPÓSITOS/PRÉSTAMOS',
    False,
    FNuevosDepositos,
    FTotalNuevos);
  EscribirEntregas;
  EscribirDevolucionEconomica;
  oDepositosDevueltos :=
    FRepositorio.ListarDepositosDevueltosResguardo(FContexto);
  EscribirDepositos(
    'DEVOLUCIÓN DE ARTÍCULOS',
    True,
    oDepositosDevueltos,
    FTotalDevueltos);
  if HayMovimientos then
  begin
    EscribirResumen;
    GenerarSalida;
  end;
end;

procedure ImprimirResguardoDeposito(
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  AOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
var
  oGenerador: TGeneradorResguardoDeposito;
begin
  if (Trim(AOperacion) <> '') and Assigned(ARepositorio) then
  begin
    oGenerador := TGeneradorResguardoDeposito.Create(
      ARepositorio,
      ACodigoEmpresa,
      ACodigoAlmacen,
      ACodigoCaja,
      AOperacion,
      ANombreImpresora,
      ARutasPDF,
      ASoloPDF);
    try
      oGenerador.Ejecutar;
    finally
      FreeAndNil(oGenerador);
    end;
  end;
end;

procedure ImprimirTicketDesdeBD(
  const AParametrosApp: IParametrosAplicacion;
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoAlmacen, ACodigoCaja,
  ANumeroOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean;
  AImprimirCodigoBarras: Boolean);
var
  bTieneFactura: Boolean;
  dFechaOperacion: TDateTime;
  dTotalCambio: Currency;
  i: Integer;
  sArt: string;
  sCodigoBarras: string;
  sComandosEsc: string;
  sDocumentoFac: string;
  sQrTexto: string;
  sRutaFicheroPdf: string;
  sUds: string;
  sUnidad: string;
  oCabecera: TCabeceraTicketCaja;
  oContexto: TContextoOperacionTicketCaja;
  oLineas: TArray<TLineaTicketCaja>;
  oPagos: TArray<TPagoTicketCaja>;
  oTicket: TTicketTermico;
  oVales: TArray<TValeTicketCaja>;
begin
  if not Assigned(ARepositorio) then
    raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  oContexto.Empresa := ACodigoEmpresa;
  oContexto.Almacen := ACodigoAlmacen;
  oContexto.Caja := ACodigoCaja;
  oContexto.Operacion := ANumeroOperacion;
  oCabecera := ARepositorio.ObtenerCabeceraTicket(oContexto);
  if not oCabecera.Encontrada then
    raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  dFechaOperacion := oCabecera.FechaOperacion;
  if (Frac(dFechaOperacion) = 0) and
     (oCabecera.InstanteAlta <> 0) then
    dFechaOperacion :=
      Trunc(dFechaOperacion) + Frac(oCabecera.InstanteAlta);
  bTieneFactura :=
    (oCabecera.SerieFactura <> '') and
    (oCabecera.NumeroFactura <> '');
  sDocumentoFac := FormatearDocumento(
    oCabecera.FormatoDocumento,
    oCabecera.SerieFactura,
    oCabecera.NumeroFactura);
  sQrTexto := '';
  if (not SinVerifactuActivo(AParametrosApp)) and bTieneFactura then
    sQrTexto := ConstruirUrlQR(
      AParametrosApp,
      oCabecera.NifEmpresaFactura,
      oCabecera.SerieFactura,
      oCabecera.NumeroFactura,
      oCabecera.FechaFactura,
      oCabecera.TotalLiquido);
  oTicket := TTicketTermico.Create(ANombreImpresora);
  try
    oTicket.Inicializar;
    if sQrTexto <> '' then
    begin
      oTicket.Alinear(alCentro);
      oTicket.SaltarLineas(1);
      oTicket.EscribirLinea('QR tributario:');
      oTicket.ImprimirQRNativo(sQrTexto, 6, 49);
      if VerifactuActivo(AParametrosApp) then
      begin
        oTicket.Alinear(alCentro);
        oTicket.EscribirLinea('VERI*FACTU - Factura verificable');
        oTicket.EscribirLinea('en la sede electrónica de la AEAT');
      end;
      oTicket.Alinear(alIzquierda);
    end;
    oTicket.SaltarLineas(1);
    oTicket.Negrita(True);
    if bTieneFactura then
      oTicket.EscribirLinea(
        'FACTURA SIMPLIFICADA Nro. ' + sDocumentoFac)
    else
      oTicket.EscribirLinea(
        'TICKET DE OPERACIÓN Nro. ' + ANumeroOperacion);
    oTicket.Negrita(False);
    oTicket.SaltarLineas(1);
    oTicket.Alinear(alCentro);
    oTicket.EscribirLinea(oCabecera.RazonSocialEmpresa);
    oTicket.EscribirLinea(oCabecera.DireccionEmpresa);
    oTicket.EscribirLinea(
      oCabecera.CodigoPostalEmpresa + ' ' +
      oCabecera.PoblacionEmpresa);
    oTicket.EscribirLinea(
      'CIF/NIF: ' + oCabecera.NifEmpresaFactura);
    if Trim(oCabecera.MovilEmpresa) <> '' then
      oTicket.EscribirLinea(
        'TELÉFONO: ' + oCabecera.MovilEmpresa);
    oTicket.SaltarLineas(1);
    oTicket.Alinear(alIzquierda);
    oTicket.TextoColumnas('OPERACIÓN NRO.', ANumeroOperacion);
    oTicket.SaltarLineas(1);
    oTicket.TextoColumnas(
      FormatDateTime('dd/mm/yyyy hh:nn', dFechaOperacion),
      LPAD(ACodigoEmpresa, 3) + ' Tda.' +
      LPAD(ACodigoAlmacen, 3) + '-' +
      LPAD(ACodigoCaja, 2));
    if bTieneFactura then
    begin
      oTicket.LineaSeparadora('-');
      oTicket.EscribirLinea(
        'Artículo/Sku                Uds    Total');
      oTicket.LineaSeparadora('-');
      oLineas := ARepositorio.ListarLineasTicket(
        oCabecera.SerieFactura,
        oCabecera.NumeroFactura);
      for i := 0 to High(oLineas) do
      begin
        sArt := Format(
          '%-26s',
          [Copy(oLineas[i].CodigoUnidad, 1, 26)]);
        sUnidad := oLineas[i].TipoCantidad;
        sUds := Format(
          '%4s',
          [oUnidades.Formatear(
            oLineas[i].Cantidad,
            sUnidad)]);
        oTicket.TextoColumnas(
          sArt + sUds,
          FormatFloat('#,##0.00', oLineas[i].Total) + ' €');
        oTicket.EscribirLinea(
          Copy(oLineas[i].Descripcion, 1, 42));
      end;
      oTicket.LineaSeparadora('-');
      oTicket.SaltarLineas(1);
      oTicket.Alinear(alIzquierda);
      oTicket.Negrita(True);
      oTicket.TextoColumnas(
        'A PAGAR',
        FormatFloat('#,##0.00', oCabecera.TotalLiquido) + ' €');
      oTicket.Negrita(False);
    end;
    oTicket.Alinear(alIzquierda);
    oTicket.Negrita(True);
    dTotalCambio := 0;
    oPagos := ARepositorio.ListarPagosTicket(oContexto);
    for i := 0 to High(oPagos) do
    begin
      dTotalCambio := dTotalCambio + oPagos[i].ImporteCambio;
      if oPagos[i].ImporteEntregado <> 0 then
        oTicket.TextoColumnas(
          UpperCase(oPagos[i].CodigoFormaPago),
          FormatFloat(
            '#,##0.00',
            oPagos[i].ImporteEntregado) + ' €');
    end;
    if dTotalCambio > 0 then
      oTicket.TextoColumnas(
        'CAMBIO EFECTIVO',
        FormatFloat('#,##0.00', dTotalCambio) + ' €');
    oTicket.Negrita(False);
    oVales := ARepositorio.ListarValesTicket(oContexto);
    for i := 0 to High(oVales) do
    begin
      oTicket.SaltarLineas(1);
      oTicket.Negrita(True);
      oTicket.TextoColumnas(
        'VALE EMITIDO A SU FAVOR',
        FormatFloat('#,##0.00', oVales[i].ImporteNominal) + ' €');
      if Length('CÓDIGO VALE EMITIDO: ' + oVales[i].Codigo) <= 42 then
        oTicket.TextoColumnas(
          'CÓDIGO VALE EMITIDO: ',
          oVales[i].Codigo)
      else
      begin
        oTicket.EscribirLinea('CÓDIGO VALE EMITIDO:');
        oTicket.EscribirLinea(oVales[i].Codigo);
      end;
      oTicket.Negrita(False);
    end;
    oTicket.SaltarLineas(1);
    if bTieneFactura then
    begin
      if oCabecera.TotalIvaNormal > 0 then
      begin
        oTicket.TextoColumnas(
          'BASE IMPONIBLE',
          FormatFloat('#,##0.00', oCabecera.BaseIvaNormal) + ' €');
        oTicket.TextoColumnas(
          Format(
            'TOTAL IVA(%.0f%%)',
            [oCabecera.PorcentajeIvaNormal]),
          FormatFloat('#,##0.00', oCabecera.TotalIvaNormal) + ' €');
      end;
      if oCabecera.TotalIvaReducido > 0 then
      begin
        oTicket.TextoColumnas(
          'BASE IMPONIBLE RED.',
          FormatFloat('#,##0.00', oCabecera.BaseIvaReducido) + ' €');
        oTicket.TextoColumnas(
          Format(
            'TOTAL IVA(%.0f%%)',
            [oCabecera.PorcentajeIvaReducido]),
          FormatFloat('#,##0.00', oCabecera.TotalIvaReducido) + ' €');
      end;
    end;
    oTicket.SaltarLineas(2);
    oTicket.Alinear(alCentro);
    oTicket.EscribirLinea(
      'LE ATENDIÓ: ' + oCabecera.DiminutivoVendedor);
    oTicket.EscribirLinea('IVA INCLUIDO');
    oTicket.EscribirLinea('GRACIAS POR SU VISITA');
    if Trim(oCabecera.TextoLegalEmpresa) <> '' then
    begin
      oTicket.SaltarLineas(1);
      oTicket.EscribirLinea(oCabecera.TextoLegalEmpresa);
    end;
    EscribirPieTicket(
      oTicket,
      ARepositorio.ListarPieTicket(ACodigoEmpresa));
    // Código de barras EAN-13 del ticket (parámetro de caja) para
    // localizarlo al escanear en devoluciones (F4)
    if AImprimirCodigoBarras and bTieneFactura then
    begin
      sCodigoBarras := ARepositorio.ObtenerCodigoBarrasTicket(
        oCabecera.SerieFactura, oCabecera.NumeroFactura);
      if sCodigoBarras <> '' then
      begin
        oTicket.SaltarLineas(1);
        oTicket.ImprimirEAN13Nativo(sCodigoBarras);
      end;
    end;
    oTicket.CortarPapel;
    oTicket.AbrirCajon;
    sComandosEsc := oTicket.ObtenerComandos;
    sRutaFicheroPdf :=
      GetUserFolderTickets + 'TicketBD_' +
      FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(
      oTicket,
      sComandosEsc,
      sRutaFicheroPdf,
      ANombreImpresora,
      ASoloPDF);
    if (ARutasPDF <> nil) and FileExists(sRutaFicheroPdf) then
      ARutasPDF.Add(sRutaFicheroPdf);
  finally
    FreeAndNil(oTicket);
  end;
end;

procedure ImprimirRecordatorio(
  const ARepositorio: IRepositorioTicketsCaja;
  const ACodigoEmpresa, ACodigoCliente: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
var
  dCantidad: Double;
  dPendiente: Currency;
  dTotalDeposito: Currency;
  dTotalPendienteCliente: Currency;
  i: Integer;
  j: Integer;
  sComandosEsc: string;
  sConcepto: string;
  sOrigen: string;
  sOrigenDeposito: string;
  sRutaFicheroPdf: string;
  oAnticipos: TArray<TAnticipoRecordatorioTicketCaja>;
  oDepositos: TArray<TDepositoPendienteTicketCaja>;
  oEmpresa: TEmpresaRecordatorioTicketCaja;
  oTicket: TTicketTermico;
begin
  if (Trim(ACodigoCliente) <> '') and Assigned(ARepositorio) then
  begin
    oDepositos :=
      ARepositorio.ListarDepositosPendientesRecordatorio(
        ACodigoCliente);
    if Length(oDepositos) > 0 then
    begin
      oEmpresa :=
        ARepositorio.ObtenerEmpresaRecordatorio(ACodigoEmpresa);
      oTicket := TTicketTermico.Create(ANombreImpresora);
      try
        oTicket.Inicializar;
        oTicket.Alinear(alCentro);
        oTicket.Negrita(True);
        oTicket.SaltarLineas(3);
        oTicket.EscribirLinea(
          'ESTADO DE SU CUENTA ENTREGAS/DEPÓSITOS');
        oTicket.EscribirLinea(
          FormatDateTime(
            'dddd, d "de" mmmm "de" yyyy, hh:nn',
            Now));
        oTicket.Negrita(False);
        oTicket.LineaSeparadora('-');
        oTicket.Alinear(alIzquierda);
        oTicket.Negrita(True);
        oTicket.EscribirLinea('EMPRESA:');
        oTicket.Negrita(False);
        oTicket.EscribirLinea(
          Format(
            '%-4s %s',
            [oEmpresa.Codigo, Copy(oEmpresa.RazonSocial, 1, 36)]));
        oTicket.Negrita(True);
        oTicket.EscribirLinea('CLIENTE:');
        oTicket.Negrita(False);
        oTicket.EscribirLinea(
          Format(
            '%-4s %s',
            [oDepositos[0].CodigoCliente,
             Copy(oDepositos[0].RazonSocialCliente, 1, 36)]));
        oTicket.LineaSeparadora('-');
        oTicket.EscribirLinea(
          Format(
            '%-14s %13s %13s',
            ['Fecha/Hora', 'Total', 'Pendiente']));
        oTicket.LineaSeparadora('-');
        dTotalPendienteCliente := 0;
        for i := 0 to High(oDepositos) do
        begin
          dCantidad := oDepositos[i].CantidadPendiente;
          if dCantidad = 0 then
            dCantidad := 1;
          dTotalDeposito :=
            oDepositos[i].PrecioVenta * dCantidad;
          dPendiente :=
            dTotalDeposito - oDepositos[i].ImporteAnticipo;
          dTotalPendienteCliente :=
            dTotalPendienteCliente + dPendiente;
          sOrigenDeposito := oDepositos[i].Empresa;
          if oDepositos[i].Almacen <> '' then
            sOrigenDeposito :=
              sOrigenDeposito + '/' + oDepositos[i].Almacen;
          if oDepositos[i].Caja <> '' then
            sOrigenDeposito :=
              sOrigenDeposito + '/' + oDepositos[i].Caja;
          oTicket.Alinear(alIzquierda);
          oTicket.EscribirLinea(
            Format(
              '%-14s %13s %13s',
              [FormatDateTime(
                 'dd/mm/yy HH:nn',
                 oDepositos[i].FechaCreacion),
               FormatFloat('#,##0.00 €', dTotalDeposito),
               FormatFloat('#,##0.00 €', dPendiente)]));
          oTicket.EscribirLinea(
            '  ' + Copy(oDepositos[i].CodigoUnidad, 1, 40));
          oTicket.EscribirLinea(
            '  ' + Copy(oDepositos[i].Descripcion, 1, 40));
          oTicket.EscribirLinea(
            '  RETIRADO EN (' + sOrigenDeposito + ')');
          oAnticipos :=
            ARepositorio.ListarAnticiposRecordatorio(
              oDepositos[i].IdDeposito);
          for j := 0 to High(oAnticipos) do
          begin
            sConcepto := '';
            if oAnticipos[j].TipoOperacion = 'DE' then
              sConcepto := '  > Entrega inicial'
            else if oAnticipos[j].TipoOperacion = 'CB' then
              sConcepto := '  > A cuenta';
            sOrigen := oAnticipos[j].Empresa;
            if oAnticipos[j].Almacen <> '' then
              sOrigen := sOrigen + '/' + oAnticipos[j].Almacen;
            if oAnticipos[j].Caja <> '' then
              sOrigen := sOrigen + '/' + oAnticipos[j].Caja;
            oTicket.Alinear(alIzquierda);
            oTicket.EscribirLinea(
              sConcepto + '  ' +
              FormatDateTime(
                'dd/mm/yy HH:nn',
                oAnticipos[j].FechaOperacion));
            oTicket.EscribirLinea(
              Format(
                '   %-10s %13s',
                ['(' + sOrigen + ')',
                 '-' + FormatFloat(
                   '#,##0.00',
                   oAnticipos[j].Importe) + ' €']));
            oTicket.Alinear(alDerecha);
          end;
          oTicket.SaltarLineas(1);
        end;
        oTicket.Alinear(alIzquierda);
        oTicket.LineaSeparadora('-');
        oTicket.Negrita(True);
        oTicket.TextoColumnas(
          'TOTAL PDTE. DE PAGO:',
          FormatFloat(
            '#,##0.00',
            dTotalPendienteCliente) + ' €');
        oTicket.Negrita(False);
        sComandosEsc := oTicket.ObtenerComandos;
        sRutaFicheroPdf :=
          GetUserFolderTickets + 'Recordatorio_' +
          FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
        ImprimirOPrevisualizarTicket(
          oTicket,
          sComandosEsc,
          sRutaFicheroPdf,
          ANombreImpresora,
          ASoloPDF);
        if (ARutasPDF <> nil) and FileExists(sRutaFicheroPdf) then
          ARutasPDF.Add(sRutaFicheroPdf);
      finally
        FreeAndNil(oTicket);
      end;
    end;
  end;
end;

end.
