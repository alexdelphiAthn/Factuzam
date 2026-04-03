unit inLibGenerarTicket;

interface
uses
  System.SysUtils, System.Classes, Data.DB,
  UniDataCaja,
  inLibFTicket,        // Donde está tu TTicketTermico
  inMtoPreviewTicket,  // Donde está tu TFormVisualizador
  inLibFaseCobro;      // Para TDatosFaseCobro

  procedure ImprimirT(const ACodigoEmpresa,
                            ACodigoAlmacen,
                            ACodigoCaja,
                            ANumeroGenerado: string;
                            DatosCobro: TDatosFaseCobro);

implementation


uses
  inLibDir;

procedure ImprimirT(const ACodigoEmpresa,
                          ACodigoAlmacen,
                          ACodigoCaja,
                          ANumeroGenerado: string;
                          DatosCobro: TDatosFaseCobro);
var
  Ticket: TTicketTermico;
  Cab: TDatosCabeceraFactura;
  Lin: TDatosLineaFactura;
  dLin:TDataSet;
  NombreImpresora: string;
  ModoQR, QRTexto: string;
  CantidadTotal: Double;
  ComandosESC, RutaFicheroPDF: string;
  FormPreview: TFormVisualizador;

  // Función anidada original para rellenar con ceros (LPAD)
  function LPAD(const AValue: string; ALength: Integer; const APadChar: Char = '0'): string;
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
  // 1. OBTENER CONFIGURACIONES
  // (Sustituye esto por las lecturas reales de tu configuración, ej. oCajaParams)
  NombreImpresora := 'DEBUG';
  ModoQR := 'NATIVO';
  QRTexto := 'http://hacienda.com'; // <--- Añadir la generación del texto QR
  Cab := leerCabecera(DatosCobro.TotalesFactura.Cabecera);
  dLin := DatosCobro.TotalesFactura.Lineas;
  Ticket := TTicketTermico.Create(NombreImpresora);
  try
    Ticket.Inicializar;
    // === QR AL PRINCIPIO ===
    Ticket.Alinear(alCentro);
    Ticket.SaltarLineas(1);

    if ModoQR = 'IE' then
    begin
      // Modo IMAGEN: Descomentar si usas la generación de Bitmap
      // QRBitmap := GenerarQRCode(QRTexto, 4);
      // if Assigned(QRBitmap) then ...
    end
    else
    begin
      // Modo NATIVO: Comando ESC/POS directo a la impresora
      Ticket.ImprimirQRNativo(QRTexto, 6);
    end;
    Ticket.SaltarLineas(1);

    // === ENCABEZADO TICKET ===
    Ticket.Negrita(True);
    Ticket.EscribirLinea('  FACTURA SIMPLIFICADA Nro. ' + ANumeroGenerado);
    Ticket.Negrita(False);
    Ticket.SaltarLineas(1);

    // === DATOS EMPRESA ===
    Ticket.Alinear(alCentro);
//    Ticket.SaltarLineas(1);

    // === DATOS EMPRESA ===
//    Ticket.Alinear(alIzquierda);
    Ticket.EscribirLinea('        ' + Cab.RazonSocialEmp);
    Ticket.EscribirLinea('        ' + Cab.Direccion1Emp);
    Ticket.EscribirLinea('        ' + Cab.CPostalEmp + ' ' + Cab.PoblacionEmp);
    Ticket.EscribirLinea('        ' + 'CIF/NIF: ' + Cab.NifEmp);
    if Trim(Cab.MovilEmp) <> '' then
      Ticket.EscribirLinea('        ' + 'TELÉFONO: ' + Cab.MovilEmp);
    Ticket.SaltarLineas(1);
    // Formatear línea de operación y tienda
    Ticket.Alinear(alIzquierda);
    Ticket.EscribirLinea('Venta ' + FormatDateTime('dd/mm/yyyy', Cab.Fecha) +
                         ' ' + FormatDateTime('hh:nn', Now) + ' ' +
                         LPAD(ACodigoEmpresa, 3) + ' Tda.' +
                         LPAD(ACodigoAlmacen, 3) + '-' + LPAD(ACodigoCaja, 2));
    // === ARTÍCULOS ===
    Ticket.LineaSeparadora('-');
    Ticket.EscribirLinea('Artículo/Color/Tall  Uds   Total');
    Ticket.LineaSeparadora('-');
    CantidadTotal := 0;
    dLin.DisableControls;
    try
      dLin.First;
      while not dLin.Eof do
      begin
        Lin := LeerLineaActual(dLin);

        // Nota: En TDatosLineaFactura ya no tienes campos separados "color" y "talla".
        // Si tu código Sku (ej: ZAP/ROJO/42) lo contiene, puedes ajustarlo con Copy, o extraerlo de los ATTR.
        // Aquí uso una aproximación directa extrayendo los primeros 8 chars del artículo.
        var Art := Format('%-14s', [Copy(Lin.Sku, 1, 29)]);
//        var Col := Format('%-9s',  ['']);
//        var Tal := Format('%-6s',  ['']); // <--- Ajustar si lees la talla de Lin.Sku
        var Des := Format('%-38s', [Copy(Lin.Descripcion, 1, 38)]);
        var Pre := Format('%7.2f', [Lin.TotalCIva]); // Total bruto línea (con IVA)
        var Uds := Format('%-2s',  [FloatToStr(Lin.Cantidad)]);
        Ticket.TextoColumnas(Art + Uds, Pre + ' €');
        Ticket.EscribirLinea(Des);
        CantidadTotal := CantidadTotal + Lin.Cantidad;
        dLin.Next;
      end;
    finally
      dLin.EnableControls;
    end;
    Ticket.LineaSeparadora('-');
    Ticket.SaltarLineas(1);
    // === TOTALES ===
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
                                                 'DESCRIPCION_FORMAP').AsString;
      var FPAmount := DatosCobro.MemTablePagos.FieldByName(
                                                   'IMPORTE_ENTREGADO').AsFloat;
      if FPAmount > 0.001 then
        Ticket.TextoColumnas(UpperCase(FPName),
                                             Format('%.2f', [FPAmount]) + ' €');
      DatosCobro.MemTablePagos.Next;
    end;
    if DatosCobro.ImporteCambio > 0 then
      Ticket.TextoColumnas('CAMBIO', Format('%.2f',
                                            [DatosCobro.ImporteCambio]) + ' €');
    Ticket.Negrita(False);
    if DatosCobro.ImporteValeEmitido > 0 then
    begin
      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);
      Ticket.TextoColumnas('VALE EMITIDO A SU FAVOR', Format('%.2f',
                                       [DatosCobro.ImporteValeEmitido]) + ' €');
      Ticket.Negrita(False);
    end;
    Ticket.TextoColumnas('CANTIDAD DE ARTICULOS', Format('%.2f',
                                                          [CantidadTotal]), 42);
    Ticket.SaltarLineas(1);
    // Mostrar desglose de base e IVA (N = Normal, R = Reducido, etc.)
    if Cab.TotalIvaN > 0 then
    begin
      Ticket.TextoColumnas('BASE IMPONIBLE', Format('%.2f', [Cab.BaseIN]) +
                                                                          ' €');
      Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [Cab.PorcIvaN]),
                                        Format('%.2f', [Cab.TotalIvaN]) + ' €');
    end;
    if Cab.TotalIvaR > 0 then
    begin
      Ticket.TextoColumnas('BASE IMPONIBLE RED.', Format('%.2f', [Cab.BaseIR]) +
                                                                          ' €');
      Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [Cab.PorcIvaR]),
                                        Format('%.2f', [Cab.TotalIvaR]) + ' €');
    end;
    // === PIE DE TICKET ===
    Ticket.SaltarLineas(2);
    Ticket.Alinear(alCentro);
    // Si tienes el nombre del cajero puedes cruzarlo,
    //por ahora imprimimos el código
    Ticket.EscribirLinea('LE ATENDIÓ: ' +
                                 DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                             'CODIGO_CAJERO_FACTURA').AsString);
    Ticket.EscribirLinea('IVA INCLUIDO');
    Ticket.EscribirLinea('GRACIAS POR SU VISITA');
    // Puedes cargar las líneas personalizadas aquí de tu configuración
    // Ticket.EscribirLinea(sCustomLine1);
    Ticket.SaltarLineas(1);
    Ticket.EscribirLinea('');
    Ticket.SaltarLineas(3);
    Ticket.CortarPapel;
    Ticket.AbrirCajon;
    ComandosESC := Ticket.ObtenerComandos;
    if UpperCase(NombreImpresora) = 'DEBUG' then
    begin
      RutaFicheroPDF := GetUserFolderTickets + 'Ticket_' +
                        FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      FormPreview := TFormVisualizador.Create(nil);
      try
        FormPreview.CargarYMostrar(ComandosESC);
        FormPreview.ExportarAPDF(ComandosESC, RutaFicheroPDF);
        FormPreview.ShowModal;
      finally
        FormPreview.Free;
      end;
    end
    else
    begin
      // Modo Normal: Enviar RAW a la cola de impresión de Windows
      Ticket.Imprimir;
    end;

  finally
    Ticket.Free;
  end;
end;

end.
