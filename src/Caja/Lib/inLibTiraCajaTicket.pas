{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTiraCajaTicket                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera e imprime la "tira de caja": una tira térmica con el desglose de   }
{    cada operación facturada (venta / devolución) entre dos fechas para una   }
{    misma empresa / almacén / caja. Por cada operación pinta el nº de         }
{    factura, el nº de operación, la fecha y hora, el almacén y la caja, las   }
{    líneas del ticket con su precio y, al final, las formas de pago y el      }
{    total de la operación. Formato resumido del ticket de venta.              }
{                                                                              }
{    Puede acotarse a una serie concreta (ASerie) o emitir todas (ASerie='').  }
{    Si AImprimirQR es True y Verifactu está activo (envío PRE o PRO), añade   }
{    el QR tributario de cada operación igual que el ticket de venta.          }
{                                                                              }
{    Si la impresora es 'DEBUG' abre el preview (TFormVisualizador) en vez de  }
{    mandar a la impresora física.                                            }
{******************************************************************************}
unit inLibTiraCajaTicket;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni,
  inLibFTicket;

type
  TTiraCajaTicket = class
  private
    class function FmtImp(AValor: Currency): string;
    class function LPad(const AValor: string; ALongitud: Integer): string;
    class function CentrarRelleno(const ATexto: string;
                                  ARelleno: Char): string;
    class procedure EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                            AConn: TUniConnection;
                                            const AEmpresa: string);
    class procedure EscribirLineasArticulos(ATicket: TTicketTermico;
                                            AConn: TUniConnection;
                                            const AEmpresa, AAlmacen,
                                                  ACaja, AOperacion: string);
    class procedure EscribirFormasPago(ATicket: TTicketTermico;
                                       AConn: TUniConnection;
                                       const AEmpresa, AAlmacen,
                                             ACaja, AOperacion: string);
    class procedure EscribirOperacion(ATicket: TTicketTermico;
                                      AConn: TUniConnection;
                                      AOpe: TUniQuery;
                                      AImprimirQR: Boolean);
  public
    // Series facturadas distintas en el rango para la caja (para preguntar
    // la serie cuando hay más de una). Devuelve [] si no hay operaciones.
    class function ObtenerSeries(AConn: TUniConnection;
                                 const AEmpresa, AAlmacen, ACaja: string;
                                 AFechaDesde, AFechaHasta: TDate)
                                 : TArray<string>;
    class procedure Imprimir(AConn: TUniConnection;
                             const AEmpresa, AAlmacen, ACaja: string;
                             AFechaDesde, AFechaHasta: TDate;
                             const ASerie: string = '';
                             AImprimirQR: Boolean = False;
                             const ANombreImpresora: string = 'DEBUG');
  end;

implementation

uses
  inMtoPreviewTicket, inLibDir, inLibFormatoDocumento, inLibVerifactu;

// =============================================================================
//   Helpers de formato
// =============================================================================

class function TTiraCajaTicket.FmtImp(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

class function TTiraCajaTicket.LPad(const AValor: string;
                                    ALongitud: Integer): string;
begin
  if Length(AValor) >= ALongitud then
    Result := AValor
  else
    Result := StringOfChar('0', ALongitud - Length(AValor)) + AValor;
end;

// Centra ATexto en N_CHAR_LIN columnas rellenando ambos lados con ARelleno,
// como en el ejemplo del nº de factura: _____Nº Fac.: 2026.CE.004227_____
class function TTiraCajaTicket.CentrarRelleno(const ATexto: string;
                                              ARelleno: Char): string;
var
  iLibre, iIzq: Integer;
begin
  if Length(ATexto) >= N_CHAR_LIN then
    Result := ATexto
  else
  begin
    iLibre := N_CHAR_LIN - Length(ATexto);
    iIzq   := iLibre div 2;
    Result := StringOfChar(ARelleno, iIzq) + ATexto +
              StringOfChar(ARelleno, iLibre - iIzq);
  end;
end;

// =============================================================================
//   Cabecera de empresa
// =============================================================================

class procedure TTiraCajaTicket.EscribirCabeceraEmpresa(
  ATicket: TTicketTermico; AConn: TUniConnection; const AEmpresa: string);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT RAZON_SOCIAL_EMP, NIF_EMP, DIRECCION1_EMP,                  ' +
      '        CODIGO_POSTAL_EMP, POBLACION_EMP, PROVINCIA_EMP             ' +
      '   FROM fza_empresas                                                ' +
      '  WHERE CODIGO_EMP_EMP = :pEMPRESA                                  ';
    Q.ParamByName('pEMPRESA').AsString := AEmpresa;
    Q.Open;
    if not Q.IsEmpty then
    begin
      ATicket.Alinear(alCentro);
      ATicket.Negrita(True);
      ATicket.EscribirLinea(Q.FieldByName('RAZON_SOCIAL_EMP').AsString);
      ATicket.Negrita(False);
      ATicket.EscribirLinea(Q.FieldByName('DIRECCION1_EMP').AsString);
      ATicket.EscribirLinea(
        Trim(Q.FieldByName('CODIGO_POSTAL_EMP').AsString + ' ' +
             Q.FieldByName('POBLACION_EMP').AsString));
      ATicket.EscribirLinea(Q.FieldByName('PROVINCIA_EMP').AsString);
      ATicket.EscribirLinea('CIF: ' + Q.FieldByName('NIF_EMP').AsString);
    end;
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   Líneas de artículos y formas de pago de una operación
// =============================================================================

class procedure TTiraCajaTicket.EscribirLineasArticulos(
  ATicket: TTicketTermico; AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string);
var
  Q: TUniQuery;
  sSku, sDesc, sIzq, sTot: string;
  dCant: Double;
  iMax: Integer;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT CODIGO_UNIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN,          ' +
      '        CANTIDAD_FACLIN, TOTAL_FACLIN                               ' +
      '   FROM fza_facturas_lineas                                         ' +
      '  WHERE CODIGO_EMP_FACLIN        = :pEMP                            ' +
      '    AND CODIGO_ALM_FACLIN        = :pALM                            ' +
      '    AND CODIGO_CAJA_FACLIN       = :pCAJA                           ' +
      '    AND NUMERO_OPERACION_FACLIN  = :pOPE                            ' +
      '  ORDER BY LINEA_FACLIN                                             ';
    Q.ParamByName('pEMP').AsString  := AEmpresa;
    Q.ParamByName('pALM').AsString  := AAlmacen;
    Q.ParamByName('pCAJA').AsString := ACaja;
    Q.ParamByName('pOPE').AsString  := AOperacion;
    Q.Open;
    while not Q.Eof do
    begin
      sSku  := Trim(Q.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
      sDesc := Trim(Q.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString);
      dCant := Q.FieldByName('CANTIDAD_FACLIN').AsFloat;
      sTot  := FmtImp(Q.FieldByName('TOTAL_FACLIN').AsCurrency);
      // Línea 1: SKU (con cantidad si no es 1 unidad) y el importe a la
      // derecha, igual que la primera línea de cada artículo en el ticket.
      if dCant <> 1 then
        sIzq := FormatFloat('0.##', dCant) + 'x ' + sSku
      else
        sIzq := sSku;
      iMax := N_CHAR_LIN - Length(sTot) - 1;
      if Length(sIzq) > iMax then
        sIzq := Copy(sIzq, 1, iMax);
      ATicket.TextoColumnas(sIzq, sTot);
      // Línea 2: descripción del artículo (como en el ticket de venta).
      if sDesc <> '' then
        ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TTiraCajaTicket.EscribirFormasPago(
  ATicket: TTicketTermico; AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string);
var
  Q: TUniQuery;
  dCambio: Currency;
begin
  dCambio := 0;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT p.CODIGO_FP_CFP,                                            ' +
      '        COALESCE(fp.DESCRIPCION_FORMA_PAGO_CFP,                     ' +
      '                 p.CODIGO_FP_CFP)            AS DESCR,              ' +
      '        p.IMPORTE_ENTREGADO_PAGO,                                   ' +
      '        p.IMPORTE_CAMBIO_PAGO                                       ' +
      '   FROM fza_caja_pagos p                                            ' +
      '   LEFT JOIN fza_caja_formas_pago fp                                ' +
      '     ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP                          ' +
      '  WHERE p.CODIGO_EMP_PAGO       = :pEMP                             ' +
      '    AND p.CODIGO_ALM_PAGO       = :pALM                             ' +
      '    AND p.CODIGO_CAJA_PAGO      = :pCAJA                            ' +
      '    AND p.NUMERO_OPERACION_PAGO = :pOPE                             ' +
      '  ORDER BY p.NUMERO_LINEA_PAGO                                      ';
    Q.ParamByName('pEMP').AsString  := AEmpresa;
    Q.ParamByName('pALM').AsString  := AAlmacen;
    Q.ParamByName('pCAJA').AsString := ACaja;
    Q.ParamByName('pOPE').AsString  := AOperacion;
    Q.Open;
    while not Q.Eof do
    begin
      dCambio := dCambio + Q.FieldByName('IMPORTE_CAMBIO_PAGO').AsCurrency;
      if Q.FieldByName('IMPORTE_ENTREGADO_PAGO').AsCurrency <> 0 then
        ATicket.TextoColumnas(
          UpperCase(Trim(Q.FieldByName('DESCR').AsString)),
          FmtImp(Q.FieldByName('IMPORTE_ENTREGADO_PAGO').AsCurrency));
      Q.Next;
    end;
    if dCambio > 0 then
      ATicket.TextoColumnas('CAMBIO', FmtImp(dCambio));
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   Bloque de una operación (cursor AOpe posicionado en la fila)
// =============================================================================

class procedure TTiraCajaTicket.EscribirOperacion(ATicket: TTicketTermico;
                                                  AConn: TUniConnection;
                                                  AOpe: TUniQuery;
                                                  AImprimirQR: Boolean);
var
  sEmp, sAlm, sCaja, sOpe, sSerie, sNumFac, sNif, sQR: string;
  dFechaOpe, dFechaFac: TDateTime;
  dLiquido: Currency;
begin
  sEmp      := AOpe.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm      := AOpe.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja     := AOpe.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sOpe      := AOpe.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  dFechaOpe := AOpe.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
  sSerie    := AOpe.FieldByName('SERIE_FAC_OPCAJA').AsString;
  sNumFac   := AOpe.FieldByName('NUMERO_FAC_OPCAJA').AsString;
  dLiquido  := AOpe.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
  dFechaFac := AOpe.FieldByName('FECHA_FAC').AsDateTime;
  sNif      := AOpe.FieldByName('NIF_EMPRESA_FAC').AsString;
  // Separador con el nº de factura formateado según la empresa.
  ATicket.Alinear(alIzquierda);
  ATicket.EscribirLinea(
    CentrarRelleno('Nº Fac.: ' +
                   FormatearDocumentoEmpresa(sEmp, sSerie, sNumFac), '_'));
  // Operación, fecha/hora, empresa y Tda.almacén-caja.
  ATicket.EscribirLinea(Format('%s %s %s Tda.%s-%s',
    [sOpe, FormatDateTime('dd/mm/yy hh:nn:ss', dFechaOpe),
     LPad(sEmp, 3), LPad(sAlm, 3), LPad(sCaja, 2)]));
  // Líneas del ticket con su precio.
  EscribirLineasArticulos(ATicket, AConn, sEmp, sAlm, sCaja, sOpe);
  // Total de la operación y formas de pago.
  ATicket.Negrita(True);
  ATicket.TextoColumnas('A PAGAR', FmtImp(dLiquido));
  ATicket.Negrita(False);
  EscribirFormasPago(ATicket, AConn, sEmp, sAlm, sCaja, sOpe);
  // QR tributario por operación si Verifactu está activo y se ha pedido.
  if AImprimirQR and (not SinVerifactuActivo)
     and (Trim(sSerie) <> '') and (Trim(sNumFac) <> '') then
  begin
    sQR := ConstruirUrlQR(sNif, sSerie, sNumFac, dFechaFac, dLiquido);
    if sQR <> '' then
    begin
      ATicket.Alinear(alCentro);
      // Nivel de corrección M (49) exigido por la AEAT para el QR.
      ATicket.ImprimirQRNativo(sQR, 6, 49);
      ATicket.Alinear(alIzquierda);
    end;
  end;
  ATicket.SaltarLineas(1);
end;

// =============================================================================
//   API pública
// =============================================================================

class function TTiraCajaTicket.ObtenerSeries(AConn: TUniConnection;
                                             const AEmpresa, AAlmacen,
                                                   ACaja: string;
                                             AFechaDesde, AFechaHasta: TDate)
                                             : TArray<string>;
var
  Q: TUniQuery;
begin
  SetLength(Result, 0);
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT DISTINCT o.SERIE_FAC_OPCAJA AS SERIE                      ' +
      '   FROM fza_caja_operaciones o                                    ' +
      '  WHERE o.CODIGO_EMP_OPCAJA   = :pEMP                             ' +
      '    AND o.CODIGO_ALM_OPCAJA   = :pALM                             ' +
      '    AND o.CODIGO_CAJA_OPCAJA  = :pCAJA                            ' +
      '    AND o.SERIE_FAC_OPCAJA   IS NOT NULL                          ' +
      '    AND o.SERIE_FAC_OPCAJA  <> ''''                               ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                      ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                      ' +
      '  ORDER BY o.SERIE_FAC_OPCAJA                                     ';
    Q.ParamByName('pEMP').AsString      := AEmpresa;
    Q.ParamByName('pALM').AsString      := AAlmacen;
    Q.ParamByName('pCAJA').AsString     := ACaja;
    Q.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
    Q.Open;
    while not Q.Eof do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Q.FieldByName('SERIE').AsString;
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TTiraCajaTicket.Imprimir(AConn: TUniConnection;
                                         const AEmpresa, AAlmacen,
                                               ACaja: string;
                                         AFechaDesde, AFechaHasta: TDate;
                                         const ASerie: string = '';
                                         AImprimirQR: Boolean = False;
                                         const ANombreImpresora: string
                                               = 'DEBUG');
var
  Ope: TUniQuery;
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
  ComandosESC, RutaPDF, sSQL: string;
  iOperaciones: Integer;
  dTotal: Currency;
begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  iOperaciones := 0;
  dTotal       := 0;
  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;
    EscribirCabeceraEmpresa(Ticket, AConn, AEmpresa);
    // Título: una sola caja y el rango exacto seleccionado por el usuario.
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(Format('-ARQUEO CAJA %s HORA %s-',
      [ACaja, FormatDateTime('hh:nn', Now)]));
    Ticket.EscribirLinea(Format('DEL %s',
      [FormatDateTime('dd/mm/yy hh:nn', AFechaDesde)]));
    Ticket.EscribirLinea(Format('AL  %s',
      [FormatDateTime('dd/mm/yy hh:nn', AFechaHasta)]));
    if Trim(ASerie) <> '' then
      Ticket.EscribirLinea('SERIE: ' + ASerie)
    else
      Ticket.EscribirLinea('TODAS LAS SERIES');
    Ticket.Negrita(False);
    Ticket.Alinear(alIzquierda);
    Ticket.SaltarLineas(1);
    // Operaciones facturadas del rango (ventas y devoluciones), opcionalmente
    // acotadas a una serie. Las que no tienen factura no llevan nº de factura
    // ni serie, así que quedan fuera de la tira.
    Ope := TUniQuery.Create(nil);
    try
      Ope.Connection := AConn;
      sSQL :=
        ' SELECT o.CODIGO_EMP_OPCAJA, o.CODIGO_ALM_OPCAJA,                 ' +
        '        o.CODIGO_CAJA_OPCAJA, o.NUMERO_OPERACION_OPCAJA,          ' +
        '        o.FECHA_OPERACION_OPCAJA, o.SERIE_FAC_OPCAJA,             ' +
        '        o.NUMERO_FAC_OPCAJA,                                      ' +
        '        f.TOTAL_LIQUIDO_FAC, f.FECHA_FAC, f.NIF_EMPRESA_FAC       ' +
        '   FROM fza_caja_operaciones o                                    ' +
        '   LEFT JOIN fza_facturas f                                       ' +
        '     ON f.SERIE_FAC  = o.SERIE_FAC_OPCAJA                         ' +
        '    AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA                        ' +
        '  WHERE o.CODIGO_EMP_OPCAJA   = :pEMP                             ' +
        '    AND o.CODIGO_ALM_OPCAJA   = :pALM                             ' +
        '    AND o.CODIGO_CAJA_OPCAJA  = :pCAJA                            ' +
        '    AND o.SERIE_FAC_OPCAJA   IS NOT NULL                          ' +
        '    AND o.SERIE_FAC_OPCAJA  <> ''''                               ' +
        '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                      ' +
        '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                      ';
      if Trim(ASerie) <> '' then
        sSQL := sSQL + ' AND o.SERIE_FAC_OPCAJA = :pSERIE ';
      sSQL := sSQL +
        '  ORDER BY o.FECHA_OPERACION_OPCAJA, o.NUMERO_OPERACION_OPCAJA    ';
      Ope.SQL.Text := sSQL;
      Ope.ParamByName('pEMP').AsString      := AEmpresa;
      Ope.ParamByName('pALM').AsString      := AAlmacen;
      Ope.ParamByName('pCAJA').AsString     := ACaja;
      Ope.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
      Ope.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
      if Trim(ASerie) <> '' then
        Ope.ParamByName('pSERIE').AsString := ASerie;
      Ope.Open;
      while not Ope.Eof do
      begin
        EscribirOperacion(Ticket, AConn, Ope, AImprimirQR);
        Inc(iOperaciones);
        dTotal := dTotal + Ope.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
        Ope.Next;
      end;
    finally
      FreeAndNil(Ope);
    end;
    // Resumen final de la tira.
    Ticket.LineaSeparadora('=');
    Ticket.TextoColumnas('OPERACIONES', IntToStr(iOperaciones));
    Ticket.Negrita(True);
    Ticket.TextoColumnas('TOTAL', FmtImp(dTotal));
    Ticket.Negrita(False);
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ticket.SaltarLineas(2);
    Ticket.CortarPapel;
    // Vista previa (DEBUG) o impresión real.
    ComandosESC := Ticket.ObtenerComandos;
    RutaPDF := GetUserFolderTickets + 'TiraCaja_' +
               FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    Preview := TFormVisualizador.Create(nil);
    try
      Preview.Hide;
      Preview.FRutaPDFReal := RutaPDF;
      Preview.CargarYMostrar(ComandosESC);
      Preview.ExportarAPDF(ComandosESC, RutaPDF);
      if UpperCase(ANombreImpresora) = 'DEBUG' then
        Preview.ShowModal
      else
        Ticket.Imprimir;
    finally
      FreeAndNil(Preview);
    end;
  finally
    FreeAndNil(Ticket);
  end;
end;

end.
