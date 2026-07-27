{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicket                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación e impresión de tickets de venta en caja.                       }
{    Compone el ticket a partir de los datos de la operación y lo imprime.     }
{******************************************************************************}
unit inLibGenerarTicket;

interface
uses
  System.SysUtils, System.Classes, Data.DB, Uni,
  UniDataCaja,
  inLibFTicket,        // Donde está tu TTicketTermico
  inLibFaseCobro,      // Para TDatosFaseCobro
  inLibParametrosIntf;

  procedure ImprimirT(const AParametrosApp: IParametrosAplicacion;
                      AConexion: TUniConnection;
                      const ACodigoEmpresa,
                            ACodigoAlmacen,
                            ACodigoCaja,
                            ANumeroGenerado: string;
                            DatosCobro: TDatosFaseCobro;
                            NombreImpresora:string = 'DEBUG';
                            ASinPrecios: Boolean = False;
                            AFechaOperacion: TDateTime = 0;
                            ARutasPDF: TStrings = nil);

  // Diminutivo de ticket del empleado (fza_empleados) a partir de su
  // codigo. Si no se resuelve, devuelve el propio codigo recibido.
  function ObtenerDiminutivoVendedor(AConexion: TUniConnection;
    const ACodigo: string): string;
  // Escribe las cuatro lineas configurables del pie de caja de la empresa.
  // Cada linea se limita al ancho real del ticket termico (42 caracteres).
  procedure EscribirPieTicketCaja(AConexion: TUniConnection;
                                  ATicket: TTicketTermico;
                                  const ACodigoEmpresa: string);

implementation

uses
  inLibDir, inLibUnidadesMedida, inLibVerifactu, inLibFormatoDocumento,
  // Previsualizador de tickets (ImprimirOPrevisualizarTicket). Unica
  // dependencia inMto* viva de esta libreria; pendiente de extraer en B4.
  inMtoPreviewTicket;

const
  CAMPOS_PIE_TICKET_CAJA: array[0..3] of string = (
    'TEXTO_PIE_TICKET_CAJA_1_EMP',
    'TEXTO_PIE_TICKET_CAJA_2_EMP',
    'TEXTO_PIE_TICKET_CAJA_3_EMP',
    'TEXTO_PIE_TICKET_CAJA_4_EMP');

function CamposPieTicketCajaDisponibles(
  AConexion: TUniConnection): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  if (AConexion <> nil) and AConexion.Connected then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConexion;
      qry.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_empresas'' ' +
        '   AND COLUMN_NAME IN (''TEXTO_PIE_TICKET_CAJA_1_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_2_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_3_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_4_EMP'')';
      qry.Open;
      Result := qry.FieldByName('N').AsInteger = 4;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure EscribirPieTicketCaja(AConexion: TUniConnection;
                                ATicket: TTicketTermico;
                                const ACodigoEmpresa: string);
var
  qry: TUniQuery;
  i: Integer;
  sLinea: string;
  EsHaEscrito: Boolean;
begin
  EsHaEscrito := False;
  if (ATicket <> nil) and (Trim(ACodigoEmpresa) <> '') and
     CamposPieTicketCajaDisponibles(AConexion) then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConexion;
      qry.SQL.Text :=
        'SELECT TEXTO_PIE_TICKET_CAJA_1_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_2_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_3_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_4_EMP ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :EMP';
      qry.ParamByName('EMP').AsString := ACodigoEmpresa;
      qry.Open;
      if not qry.IsEmpty then
      begin
        for i := Low(CAMPOS_PIE_TICKET_CAJA) to
                 High(CAMPOS_PIE_TICKET_CAJA) do
        begin
          sLinea := Copy(Trim(qry.FieldByName(
            CAMPOS_PIE_TICKET_CAJA[i]).AsString), 1, N_CHAR_LIN);
          if sLinea <> '' then
          begin
            if not EsHaEscrito then
            begin
              ATicket.SaltarLineas(1);
              ATicket.Alinear(alCentro);
              EsHaEscrito := True;
            end;
            ATicket.EscribirLinea(sLinea);
          end;
        end;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

// Cruza el codigo de empleado (CODIGO_CAJERO_FAC) con su diminutivo de
// ticket en fza_empleados. Si no hay conexion o no se encuentra, devuelve
// el codigo recibido para no dejar el dato en blanco.
function ObtenerDiminutivoVendedor(AConexion: TUniConnection;
  const ACodigo: string): string;
var
  qry: TUniQuery;
begin
  Result := ACodigo;
  if (Trim(ACodigo) <> '') and (AConexion <> nil) and AConexion.Connected then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConexion;
      qry.SQL.Text :=
        'SELECT DIMINUTIVO_TICKET_EMPL' +
        '  FROM fza_empleados' +
        ' WHERE CODIGO_EMPL = :COD';
      qry.ParamByName('COD').AsString := ACodigo;
      qry.Open;
      if (not qry.IsEmpty) and
         (Trim(qry.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString) <> '') then
        Result := Trim(qry.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString);
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure ImprimirT(const AParametrosApp: IParametrosAplicacion;
                    AConexion: TUniConnection;
                    const ACodigoEmpresa,
                          ACodigoAlmacen,
                          ACodigoCaja,
                          ANumeroGenerado: string;
                          DatosCobro: TDatosFaseCobro;
                          NombreImpresora:string = 'DEBUG';
                          ASinPrecios: Boolean = False;
                          AFechaOperacion: TDateTime = 0;
                          ARutasPDF: TStrings = nil);
var
  Ticket: TTicketTermico;
  Cab: TDatosCabeceraFactura;
  dLin: TDataSet;
  QRTexto: string;
  ComandosESC, RutaFicheroPDF: string;
  sDocumento: string;
  dtFechaOperacion: TDateTime;

  function LPAD(const AValue: string;
                ALength: Integer;
                const APadChar: Char = '0'): string;
  var
    CurrentLength: Integer;
  begin
    CurrentLength := Length(AValue);
    if CurrentLength >= ALength then
      Result := AValue
    else
      Result := StringOfChar(APadChar, ALength - CurrentLength) + AValue;
  end;

begin
  if not DatosCobro.FRequiereFactura then
    Exit;
//  NombreImpresora := 'DEBUG';
  Cab := leerCabecera(DatosCobro.TotalesFactura.Cabecera);
  dtFechaOperacion := AFechaOperacion;
  if dtFechaOperacion = 0 then
    dtFechaOperacion := Now;
  dLin := DatosCobro.TotalesFactura.Lineas;
  sDocumento := FormatearDocumentoDataSet(AConexion,
    DatosCobro.TotalesFactura.Cabecera, 'SERIE_FAC', 'NUMERO_FAC');
  // QR tributario fiscal: URL de cotejo/remisión AEAT generada en local.
  // El ticket regalo (sin precios) no lleva QR ni datos fiscales.
  QRTexto := '';
  if (not SinVerifactuActivo(AParametrosApp)) and (not ASinPrecios) then
    QRTexto := ConstruirUrlQR(AParametrosApp,
                 Cab.NifEmp,
                 DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                                     'SERIE_FAC').AsString,
                 DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                                     'NUMERO_FAC').AsString,
                 Cab.Fecha,
                 Cab.TotalLiquido);
  Ticket := TTicketTermico.Create(NombreImpresora);
  try
    Ticket.Inicializar;
    // === QR TRIBUTARIO AL PRINCIPIO (modo fiscal activo) ===
    if QRTexto <> '' then
    begin
      Ticket.Alinear(alCentro);
      Ticket.SaltarLineas(1);
      Ticket.EscribirLinea('QR tributario:');
      // Nivel de corrección M (49) exigido por la AEAT para el QR
      Ticket.ImprimirQRNativo(QRTexto, 6, 49);
      if VerifactuActivo(AParametrosApp) then
      begin
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea('VERI*FACTU - Factura verificable');
        Ticket.EscribirLinea('en la sede electrónica de la AEAT');
      end;
      Ticket.Alinear(alIzquierda);
    end;
    Ticket.SaltarLineas(1);
    Ticket.Negrita(True);
    if ASinPrecios then
      Ticket.EscribirLinea('TICKET REGALO Nro. ' + sDocumento)
    else
      Ticket.EscribirLinea('FACTURA SIMPLIFICADA Nro. ' + sDocumento);
    Ticket.Negrita(False);
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(Cab.RazonSocialEmp);
    Ticket.EscribirLinea(Cab.Direccion1Emp);
    Ticket.EscribirLinea(Cab.CPostalEmp + ' ' + Cab.PoblacionEmp);
    Ticket.EscribirLinea('CIF/NIF: ' + Cab.NifEmp);
    if Trim(Cab.MovilEmp) <> '' then
      Ticket.EscribirLinea('TELÉFONO: ' + Cab.MovilEmp);
    Ticket.SaltarLineas(1);
    // Formatear línea de operación y tienda
    Ticket.Alinear(alIzquierda);
    Ticket.TextoColumnas('OPERACIÓN NRO.', ANumeroGenerado);
    Ticket.SaltarLineas(1);
    Ticket.TextoColumnas(FormatDateTime('dd/mm/yyyy hh:nn',
                         dtFechaOperacion),
                         LPAD(ACodigoEmpresa, 3) + ' Tda.' +
                         LPAD(ACodigoAlmacen, 3) + '-' + LPAD(ACodigoCaja, 2));
    // === ARTÍCULOS ===
    Ticket.LineaSeparadora('-');
    Ticket.EscribirLinea('Artículo/Sku                Uds    Total');
    Ticket.LineaSeparadora('-');
    dLin.DisableControls;
    try
      dLin.First;
      while not dLin.Eof do
      begin
        var sArt := Format('%-26s', [Copy(dLin.FieldByName(
                              'CODIGO_UNIDAD_FACLIN').AsString, 1, 26)]);
        var sUni := '';
        if dLin.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN') <> nil then
          sUni := dLin.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
        var sUds := Format('%4s',
             [oUnidades.Formatear(
                dLin.FieldByName('CANTIDAD_FACLIN').AsFloat, sUni)]);
        var Des := Format('%-38s', [Copy(dLin.FieldByName(
                            'DESCRIPCION_ARTICULO_FACLIN').AsString, 1, 38)]);
        if ASinPrecios then
          Ticket.EscribirLinea(sArt + sUds)
        else
        begin
          var sPre := FormatFloat('#,##0.00',
                      dLin.FieldByName('TOTAL_FACLIN').AsCurrency) + ' €';
          Ticket.TextoColumnas(sArt + sUds, sPre);
        end;
        Ticket.EscribirLinea(Copy(dLin.FieldByName(
                        'DESCRIPCION_ARTICULO_FACLIN').AsString, 1, 42));
//        CantidadTotal := CantidadTotal +
//                           dLin.FieldByName('CANTIDAD_FACLIN').AsFloat;
        dLin.Next;
      end;
    finally
      dLin.EnableControls;
    end;
    Ticket.LineaSeparadora('-');
    Ticket.SaltarLineas(1);
    // === TOTALES === (el ticket regalo no lleva importes ni pagos)
    if not ASinPrecios then
    begin
    Ticket.Alinear(alIzquierda);
    Ticket.Negrita(True);
    if DatosCobro.ImporteDescuentoGlobal > 0 then
    begin
      Ticket.TextoColumnas('SUMA', Format('%.2f',
                [Cab.TotalLiquido + DatosCobro.ImporteDescuentoGlobal]) + ' €');
      Ticket.TextoColumnas('DESCUENTO', Format('-%.2f',
                                   [DatosCobro.ImporteDescuentoGlobal]) + ' €');
    end;
    if DatosCobro.ImporteValeRecogido > 0 then
      Ticket.TextoColumnas('VALE RECOGIDO', Format('-%.2f',
                                      [DatosCobro.ImporteValeRecogido]) + ' €');
    Ticket.TextoColumnas('A PAGAR', Format('%.2f', [Cab.TotalLiquido]) + ' €');
    Ticket.Negrita(False);
    Ticket.Alinear(alIzquierda);
    Ticket.Negrita(True);
    DatosCobro.MemTablePagos.First;
    while not DatosCobro.MemTablePagos.Eof do
    begin
      var FPName := DatosCobro.MemTablePagos.FieldByName(
                                                 'DESCRIPCION_FORMA_PAGO_CFP').AsString;
      var FPAmount := DatosCobro.MemTablePagos.FieldByName(
                                                   'IMPORTE_ENTREGADO').AsFloat;
      if FPAmount > 0.001 then
        Ticket.TextoColumnas(UpperCase(FPName),
                                             Format('%.2f', [FPAmount]) + ' €');
      DatosCobro.MemTablePagos.Next;
    end;
    if DatosCobro.ImporteCambio > 0 then
      Ticket.TextoColumnas('CAMBIO EFECTIVO', Format('%.2f',
                                            [DatosCobro.ImporteCambio]) + ' €');
    Ticket.Negrita(False);
    if DatosCobro.ImporteValeEmitido > 0 then
    begin
      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);
      Ticket.TextoColumnas('VALE EMITIDO A SU FAVOR', Format('%.2f',
                                       [DatosCobro.ImporteValeEmitido]) + ' €');
      // Si el codigo no cabe junto a la etiqueta (ancho 42), va en
      // una linea propia debajo.
      if Length('CÓDIGO VALE EMITIDO: ' +
                DatosCobro.CodigoValeEmitido) <= 42 then
        Ticket.TextoColumnas('CÓDIGO VALE EMITIDO: ',
                             DatosCobro.CodigoValeEmitido)
      else
      begin
        Ticket.EscribirLinea('CÓDIGO VALE EMITIDO:');
        Ticket.EscribirLinea(DatosCobro.CodigoValeEmitido);
      end;
      Ticket.Negrita(False);
    end;
//    Ticket.TextoColumnas('CANTIDAD DE ARTICULOS', Format('%.2f',
//                                                        [CantidadTotal]), 42);
    Ticket.SaltarLineas(1);
    // Mostrar desglose de base e IVA (N = Normal, R = Reducido, etc.)
    if Abs(Cab.TotalIvaN) > 0.001 then
    begin
      Ticket.TextoColumnas('BASE IMPONIBLE', Format('%.2f', [Cab.BaseIN]) +
                                                                          ' €');
      Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [Cab.PorcIvaN]),
                                        Format('%.2f', [Cab.TotalIvaN]) + ' €');
    end;
    if Abs(Cab.TotalIvaR) > 0 then
    begin
      Ticket.TextoColumnas('BASE IMPONIBLE RED.', Format('%.2f', [Cab.BaseIR]) +
                                                                          ' €');
      Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [Cab.PorcIvaR]),
                                        Format('%.2f', [Cab.TotalIvaR]) + ' €');
    end;
    end;
    // === PIE DE TICKET ===
    Ticket.SaltarLineas(2);
    Ticket.Alinear(alCentro);
    // Mostramos el diminutivo de ticket del vendedor (fza_empleados) en
    // lugar de su codigo de empleado.
    var sVendedor := ObtenerDiminutivoVendedor(AConexion,
          DatosCobro.TotalesFactura.Cabecera.FieldByName(
            'CODIGO_CAJERO_FAC').AsString);
    Ticket.EscribirLinea('LE ATENDIÓ: ' + sVendedor);
    if not ASinPrecios then
      Ticket.EscribirLinea('IVA INCLUIDO');
    Ticket.EscribirLinea('GRACIAS POR SU VISITA');
    EscribirPieTicketCaja(AConexion, Ticket, ACodigoEmpresa);
    Ticket.SaltarLineas(1);
    Ticket.EscribirLinea('');
    Ticket.SaltarLineas(3);
    Ticket.CortarPapel;
    Ticket.AbrirCajon;
    ComandosESC := Ticket.ObtenerComandos;
    // Sufijo para que el regalo no pise el PDF del fiscal del mismo
    // segundo
    var sSufijoPDF := '';
    if ASinPrecios then
      sSufijoPDF := '_regalo';
    RutaFicheroPDF := GetUserFolderTickets + 'Ticket_' +
                        FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) +
                        sSufijoPDF + '.pdf';
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaFicheroPDF,
                                 NombreImpresora);
    if (ARutasPDF <> nil) and FileExists(RutaFicheroPDF) then
      ARutasPDF.Add(RutaFicheroPDF);
  finally
    FreeAndNil(Ticket);
  end;
end;

end.
