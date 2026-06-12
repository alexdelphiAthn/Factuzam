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
  System.SysUtils, System.Classes, Data.DB,
  UniDataCaja,
  inLibFTicket,        // Donde está tu TTicketTermico
  inMtoPreviewTicket,  // Donde está tu TFormVisualizador
  inLibFaseCobro;      // Para TDatosFaseCobro

  procedure ImprimirT(const ACodigoEmpresa,
                            ACodigoAlmacen,
                            ACodigoCaja,
                            ANumeroGenerado: string;
                            DatosCobro: TDatosFaseCobro;
                            NombreImpresora:string = 'DEBUG');

implementation

uses
  inLibDir, inLibUnidadesMedida, inLibVerifactu;

procedure ImprimirT(const ACodigoEmpresa,
                          ACodigoAlmacen,
                          ACodigoCaja,
                          ANumeroGenerado: string;
                          DatosCobro: TDatosFaseCobro;
                          NombreImpresora:string = 'DEBUG');
var
  Ticket: TTicketTermico;
  Cab: TDatosCabeceraFactura;
  dLin: TDataSet;
  QRTexto: string;
  ComandosESC, RutaFicheroPDF: string;
  FormPreview: TFormVisualizador;

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
  dLin := DatosCobro.TotalesFactura.Lineas;
  // QR tributario Verifactu: URL de cotejo en la AEAT generada en local
  QRTexto := '';
  if VerifactuActivo then
    QRTexto := ConstruirUrlQR(
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
    // === QR TRIBUTARIO AL PRINCIPIO (solo con Verifactu activo) ===
    if QRTexto <> '' then
    begin
      Ticket.Alinear(alCentro);
      Ticket.SaltarLineas(1);
      Ticket.EscribirLinea('QR tributario:');
      // Nivel de corrección M (49) exigido por la AEAT para el QR
      Ticket.ImprimirQRNativo(QRTexto, 6, 49);
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea('VERI*FACTU - Factura verificable');
      Ticket.EscribirLinea('en la sede electrónica de la AEAT');
      Ticket.Alinear(alIzquierda);
    end;
    Ticket.SaltarLineas(1);
    Ticket.Negrita(True);
    Ticket.EscribirLinea('FACTURA SIMPLIFICADA Nro. ' +
      DatosCobro.TotalesFactura.Cabecera.FieldByName('SERIE_FAC').AsString +
      '\' +
      DatosCobro.TotalesFactura.Cabecera.FieldByName('NUMERO_FAC').AsString);
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
    Ticket.TextoColumnas(FormatDateTime('dd/mm/yyyy', Cab.Fecha) +
                         ' ' + FormatDateTime('hh:nn', Now),
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
        var sPre := FormatFloat('#,##0.00',
                    dLin.FieldByName('TOTAL_FACLIN').AsCurrency) + ' €';
        Ticket.TextoColumnas(sArt + sUds, sPre);
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
      Ticket.TextoColumnas('CÓDIGO VALE EMITIDO: ',
                                                 DatosCobro.CodigoValeEmitido );
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
    // === PIE DE TICKET ===
    Ticket.SaltarLineas(2);
    Ticket.Alinear(alCentro);
    // Si tienes el nombre del cajero puedes cruzarlo,
    //por ahora imprimimos el código
    Ticket.EscribirLinea('LE ATENDIÓ: ' +
                                 DatosCobro.TotalesFactura.Cabecera.FieldByName(
                                             'CODIGO_CAJERO_FAC').AsString);
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
    RutaFicheroPDF := GetUserFolderTickets + 'Ticket_' +
                        FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    FormPreview := TFormVisualizador.Create(nil);
    FormPreview.Hide;
    try
      FormPreview.CargarYMostrar(ComandosESC);
      FormPreview.ExportarAPDF(ComandosESC, RutaFicheroPDF);
      if UpperCase(NombreImpresora) = 'DEBUG' then
      begin
        FormPreview.ShowModal;
      end
      else
      begin
        Ticket.Imprimir;
      end;
    finally
      FreeAndNil(FormPreview);
    end;
  finally
    FreeAndNil(Ticket);
  end;
end;

end.
