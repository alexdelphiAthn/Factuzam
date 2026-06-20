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
    // Bloque simple (ingresos EC / gastos GC): una fila por operación del rango
    // cuyo TIPO_OPERACION_OPCAJA está en AFiltroTipos (lista ya entrecomillada
    // para el IN, ej. '''EC'''). AMostrarContra pinta el almacén destino;
    // AValorar imprime importes y subtotal. Devuelve el subtotal acumulado.
    class function EscribirBloque(ATicket: TTicketTermico;
                                  AConn: TUniConnection;
                                  const AEmpresa, AAlmacen, ACaja: string;
                                  AFechaDesde, AFechaHasta: TDate;
                                  const ATitulo, AFiltroTipos: string;
                                  AMostrarContra, AValorar: Boolean): Currency;
    // Bloque de traspasos salientes (TR/AT con origen propio): por operación,
    // cabecera + almacén destino + detalle de artículos (SKU, descripción,
    // cantidad) de fza_movimientos_almacen. AValorar (solo con permiso
    // caja.verCoste) añade el coste por línea, el total por operación y el
    // subtotal del bloque.
    class procedure EscribirBloqueTraspasos(ATicket: TTicketTermico;
                                            AConn: TUniConnection;
                                            const AEmpresa, AAlmacen,
                                                  ACaja: string;
                                            AFechaDesde, AFechaHasta: TDate;
                                            AValorar: Boolean);
    // Bloque de ventas a crédito (depósitos DE): por depósito de
    // fza_depositos_cliente creado en el rango, el cliente, el artículo (SKU +
    // descripción), la valoración (precio x cantidad), lo entregado a cuenta
    // (cobro del cliente) y el pendiente, con subtotales de venta y cobrado.
    class procedure EscribirBloqueCredito(ATicket: TTicketTermico;
                                          AConn: TUniConnection;
                                          const AEmpresa, AAlmacen,
                                                ACaja: string;
                                          AFechaDesde, AFechaHasta: TDate);
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
                             const ANombreImpresora: string = 'DEBUG';
                             AIncluirTraspasos: Boolean = False;
                             AIncluirIngresos: Boolean = False;
                             AIncluirGastos: Boolean = False;
                             AIncluirCredito: Boolean = False);
  end;

implementation

uses
  inMtoPreviewTicket, inLibDir, inLibFormatoDocumento, inLibVerifactu,
  inLibPermisos;

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
//   Bloque opcional de operaciones (traspasos / ingresos / gastos / crédito)
// =============================================================================

class function TTiraCajaTicket.EscribirBloque(ATicket: TTicketTermico;
                                              AConn: TUniConnection;
                                              const AEmpresa, AAlmacen,
                                                    ACaja: string;
                                              AFechaDesde, AFechaHasta: TDate;
                                              const ATitulo,
                                                    AFiltroTipos: string;
                                              AMostrarContra,
                                              AValorar: Boolean): Currency;
var
  Q: TUniQuery;
  iFilas: Integer;
  sIzq, sDoc, sConcepto, sDestino: string;
  dImporte: Currency;
begin
  Result := 0;
  iFilas := 0;
  // Cabecera del bloque siempre, para dejar constancia aunque salga vacío.
  ATicket.LineaSeparadora('=');
  ATicket.Alinear(alCentro);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(ATitulo);
  ATicket.Negrita(False);
  ATicket.Alinear(alIzquierda);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    // El filtro de tipos va embebido (constantes internas, sin entrada de
    // usuario). No se acota por serie: son movimientos de caja del periodo,
    // no ligados a la serie de facturación de las ventas.
    Q.SQL.Text :=
      ' SELECT NUMERO_OPERACION_OPCAJA, FECHA_OPERACION_OPCAJA,            ' +
      '        SERIE_FAC_OPCAJA, NUMERO_FAC_OPCAJA,                        ' +
      '        IMPORTE_TOTAL_OPCAJA, CONCEPTO_GASTO_INGRESO_OPCAJA,        ' +
      '        CODIGO_ALM_CONTRA_OPCAJA                                    ' +
      '   FROM fza_caja_operaciones                                       ' +
      '  WHERE CODIGO_EMP_OPCAJA      = :pEMP                             ' +
      '    AND CODIGO_ALM_OPCAJA      = :pALM                             ' +
      '    AND CODIGO_CAJA_OPCAJA     = :pCAJA                            ' +
      '    AND FECHA_OPERACION_OPCAJA >= :pFDESDE                         ' +
      '    AND FECHA_OPERACION_OPCAJA <= :pFHASTA                         ' +
      '    AND TIPO_OPERACION_OPCAJA IN (' + AFiltroTipos + ')            ' +
      '  ORDER BY FECHA_OPERACION_OPCAJA, NUMERO_OPERACION_OPCAJA         ';
    Q.ParamByName('pEMP').AsString      := AEmpresa;
    Q.ParamByName('pALM').AsString      := AAlmacen;
    Q.ParamByName('pCAJA').AsString     := ACaja;
    Q.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
    Q.Open;
    while not Q.Eof do
    begin
      dImporte  := Q.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
      sConcepto := Trim(Q.FieldByName(
                     'CONCEPTO_GASTO_INGRESO_OPCAJA').AsString);
      sDestino  := Trim(Q.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString);
      // Referencia: nº de documento formateado si lo tiene; si no, nº de op.
      sDoc := Trim(Q.FieldByName('SERIE_FAC_OPCAJA').AsString);
      if (sDoc <> '') and
         (Trim(Q.FieldByName('NUMERO_FAC_OPCAJA').AsString) <> '') then
        sDoc := FormatearDocumentoEmpresa(AEmpresa, sDoc,
                  Q.FieldByName('NUMERO_FAC_OPCAJA').AsString)
      else
        sDoc := 'Op.' + Q.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      // Fila 1: referencia + fecha/hora; importe a la derecha si se valora.
      sIzq := sDoc + ' ' +
              FormatDateTime('dd/mm/yy hh:nn',
                Q.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
      if Length(sIzq) > N_CHAR_LIN then
        sIzq := Copy(sIzq, 1, N_CHAR_LIN);
      if AValorar then
        ATicket.TextoColumnas(sIzq, FmtImp(dImporte))
      else
        ATicket.EscribirLinea(sIzq);
      // Fila 2: destino del traspaso (almacén contra), cuando aplica.
      if AMostrarContra and (sDestino <> '') then
        ATicket.EscribirLinea('  -> ' + sDestino);
      // Fila 3: concepto descriptivo (gasto / ingreso / depósito), recortado.
      if sConcepto <> '' then
        ATicket.EscribirLinea(Copy(sConcepto, 1, N_CHAR_LIN));
      Result := Result + dImporte;
      Inc(iFilas);
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
  // Pie del bloque: nº de operaciones y, si se valora, el subtotal.
  if iFilas = 0 then
  begin
    ATicket.EscribirLinea('Sin movimientos');
    Result := 0;
  end
  else
  begin
    ATicket.TextoColumnas('OPERACIONES', IntToStr(iFilas));
    if AValorar then
    begin
      ATicket.Negrita(True);
      ATicket.TextoColumnas('SUBTOTAL', FmtImp(Result));
      ATicket.Negrita(False);
    end;
  end;
end;

class procedure TTiraCajaTicket.EscribirBloqueTraspasos(
  ATicket: TTicketTermico; AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; AValorar: Boolean);
var
  Ope, Lin: TUniQuery;
  iFilas, iMax: Integer;
  sRef, sDestino, sOpe, sSku, sDesc, sIzq: string;
  dCantidad, dCosteUnit: Double;
  dTotalOpe, dSubtotal: Currency;
begin
  iFilas    := 0;
  dSubtotal := 0;
  ATicket.LineaSeparadora('=');
  ATicket.Alinear(alCentro);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('-TRASPASOS SALIENTES (ORIGEN)-');
  ATicket.Negrita(False);
  ATicket.Alinear(alIzquierda);
  Ope := TUniQuery.Create(nil);
  Lin := TUniQuery.Create(nil);
  try
    Ope.Connection := AConn;
    Lin.Connection := AConn;
    // Operaciones de traspaso salientes de esta caja (origen = almacén propio).
    Ope.SQL.Text :=
      ' SELECT NUMERO_OPERACION_OPCAJA, FECHA_OPERACION_OPCAJA,            ' +
      '        SERIE_FAC_OPCAJA, NUMERO_FAC_OPCAJA,                        ' +
      '        CODIGO_ALM_CONTRA_OPCAJA                                    ' +
      '   FROM fza_caja_operaciones                                       ' +
      '  WHERE CODIGO_EMP_OPCAJA      = :pEMP                             ' +
      '    AND CODIGO_ALM_OPCAJA      = :pALM                             ' +
      '    AND CODIGO_CAJA_OPCAJA     = :pCAJA                            ' +
      '    AND FECHA_OPERACION_OPCAJA >= :pFDESDE                         ' +
      '    AND FECHA_OPERACION_OPCAJA <= :pFHASTA                         ' +
      '    AND TIPO_OPERACION_OPCAJA IN (''TR'', ''AT'')                  ' +
      '  ORDER BY FECHA_OPERACION_OPCAJA, NUMERO_OPERACION_OPCAJA         ';
    Ope.ParamByName('pEMP').AsString      := AEmpresa;
    Ope.ParamByName('pALM').AsString      := AAlmacen;
    Ope.ParamByName('pCAJA').AsString     := ACaja;
    Ope.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
    Ope.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
    Ope.Open;
    // Detalle de artículos: las salidas del origen (TIPO_MOV='S') de la op. La
    // descripción usa la denormalizada del movimiento y, si viene vacía, cae a
    // la del artículo (fza_articulos por CODIGO_ART_MOV), para que siempre haya
    // SKU y descripción.
    Lin.SQL.Text :=
      ' SELECT m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV,                       ' +
      '        COALESCE(NULLIF(TRIM(m.DESCRIPCION_ARTICULO_MOV), ''''),   ' +
      '                 a.DESCRIPCION_ART, '''')        AS DESCRIPCION,   ' +
      '        m.PRECIO_COSTE_UNITARIO_MOV                                ' +
      '   FROM fza_movimientos_almacen m                                 ' +
      '   LEFT JOIN fza_articulos a                                      ' +
      '     ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV                       ' +
      '  WHERE m.CODIGO_EMP_MOV           = :pEMP                        ' +
      '    AND m.CODIGO_ALM_DOC_MOV       = :pALM                        ' +
      '    AND m.CODIGO_CAJA_DOC_MOV      = :pCAJA                       ' +
      '    AND m.NUMERO_OPERACION_DOC_MOV = :pOPE                        ' +
      '    AND m.TIPO_MOV = ''S''                                       ' +
      '  ORDER BY m.LINEA_MOV                                           ';
    while not Ope.Eof do
    begin
      sOpe     := Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      sDestino := Trim(Ope.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString);
      // Referencia: documento formateado si lo tiene; si no, nº de operación.
      sRef := Trim(Ope.FieldByName('SERIE_FAC_OPCAJA').AsString);
      if (sRef <> '') and
         (Trim(Ope.FieldByName('NUMERO_FAC_OPCAJA').AsString) <> '') then
        sRef := FormatearDocumentoEmpresa(AEmpresa, sRef,
                  Ope.FieldByName('NUMERO_FAC_OPCAJA').AsString)
      else
        sRef := 'Op.' + sOpe;
      ATicket.Negrita(True);
      ATicket.EscribirLinea(sRef + ' ' +
        FormatDateTime('dd/mm/yy hh:nn',
          Ope.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime));
      ATicket.Negrita(False);
      if sDestino <> '' then
        ATicket.EscribirLinea('  -> ' + sDestino);
      dTotalOpe := 0;
      Lin.Close;
      Lin.ParamByName('pEMP').AsString  := AEmpresa;
      Lin.ParamByName('pALM').AsString  := AAlmacen;
      Lin.ParamByName('pCAJA').AsString := ACaja;
      Lin.ParamByName('pOPE').AsString  := sOpe;
      Lin.Open;
      while not Lin.Eof do
      begin
        sSku       := Trim(Lin.FieldByName('CODIGO_UNIDAD_MOV').AsString);
        sDesc      := Trim(Lin.FieldByName('DESCRIPCION').AsString);
        dCantidad  := Lin.FieldByName('CANTIDAD_MOV').AsFloat;
        dCosteUnit := Lin.FieldByName('PRECIO_COSTE_UNITARIO_MOV').AsFloat;
        sIzq := FormatFloat('0.##', dCantidad) + 'x ' + sSku;
        // SKU con cantidad; el coste a la derecha solo si hay permiso.
        if AValorar then
        begin
          iMax := N_CHAR_LIN - Length(FmtImp(dCantidad * dCosteUnit)) - 1;
          if Length(sIzq) > iMax then
            sIzq := Copy(sIzq, 1, iMax);
          ATicket.TextoColumnas(sIzq, FmtImp(dCantidad * dCosteUnit));
        end
        else
          ATicket.EscribirLinea(Copy(sIzq, 1, N_CHAR_LIN));
        if sDesc <> '' then
          ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
        dTotalOpe := dTotalOpe + Currency(dCantidad * dCosteUnit);
        Lin.Next;
      end;
      Lin.Close;
      if AValorar then
      begin
        ATicket.Negrita(True);
        ATicket.TextoColumnas('TOTAL TRASPASO (coste)', FmtImp(dTotalOpe));
        ATicket.Negrita(False);
      end;
      dSubtotal := dSubtotal + dTotalOpe;
      Inc(iFilas);
      Ope.Next;
    end;
  finally
    FreeAndNil(Lin);
    FreeAndNil(Ope);
  end;
  // Pie del bloque.
  if iFilas = 0 then
    ATicket.EscribirLinea('Sin movimientos')
  else
  begin
    ATicket.TextoColumnas('TRASPASOS', IntToStr(iFilas));
    if AValorar then
    begin
      ATicket.Negrita(True);
      ATicket.TextoColumnas('SUBTOTAL (coste)', FmtImp(dSubtotal));
      ATicket.Negrita(False);
    end;
  end;
end;

class procedure TTiraCajaTicket.EscribirBloqueCredito(
  ATicket: TTicketTermico; AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate);
var
  Q: TUniQuery;
  iFilas, iMax: Integer;
  sCli, sCliNom, sSku, sDesc, sIzq: string;
  dCantidad: Double;
  dPrecio, dTotal, dAnticipo, dPendiente: Currency;
  dSubVenta, dSubCobrado: Currency;
begin
  iFilas      := 0;
  dSubVenta   := 0;
  dSubCobrado := 0;
  ATicket.LineaSeparadora('=');
  ATicket.Alinear(alCentro);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('-VENTAS A CREDITO (DEPOSITOS)-');
  ATicket.Negrita(False);
  ATicket.Alinear(alIzquierda);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    // Depósitos creados en el rango por esta caja. Un depósito = un SKU. La
    // valoración es PRECIO_VENTA_DEP x CANTIDAD; IMPORTE_ANTICIPO_DEP es lo
    // entregado a cuenta por el cliente hasta la fecha.
    Q.SQL.Text :=
      ' SELECT d.NUMERO_OPERACION_DEP, d.FECHA_CREACION_DEP,              ' +
      '        d.CODIGO_CLI_DEP,                                          ' +
      '        COALESCE(c.RAZON_SOCIAL_CLI, '''') AS CLIENTE,             ' +
      '        d.CODIGO_UNIDAD_DEP,                                       ' +
      '        COALESCE(a.DESCRIPCION_ART, '''')   AS DESCRIPCION,        ' +
      '        d.PRECIO_VENTA_DEP,                                        ' +
      '        COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD,         ' +
      '        d.IMPORTE_ANTICIPO_DEP                                     ' +
      '   FROM fza_depositos_cliente d                                   ' +
      '   LEFT JOIN fza_clientes  c                                      ' +
      '     ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_DEP                        ' +
      '   LEFT JOIN fza_articulos a                                      ' +
      '     ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP                        ' +
      '  WHERE d.CODIGO_EMP_DEP      = :pEMP                             ' +
      '    AND d.CODIGO_ALM_DEP      = :pALM                             ' +
      '    AND d.CODIGO_CAJA_DEP     = :pCAJA                            ' +
      '    AND d.FECHA_CREACION_DEP >= :pFDESDE                          ' +
      '    AND d.FECHA_CREACION_DEP <= :pFHASTA                          ' +
      '  ORDER BY d.FECHA_CREACION_DEP, d.NUMERO_OPERACION_DEP           ';
    Q.ParamByName('pEMP').AsString      := AEmpresa;
    Q.ParamByName('pALM').AsString      := AAlmacen;
    Q.ParamByName('pCAJA').AsString     := ACaja;
    Q.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
    Q.Open;
    while not Q.Eof do
    begin
      sCli      := Trim(Q.FieldByName('CODIGO_CLI_DEP').AsString);
      sCliNom   := Trim(Q.FieldByName('CLIENTE').AsString);
      sSku      := Trim(Q.FieldByName('CODIGO_UNIDAD_DEP').AsString);
      sDesc     := Trim(Q.FieldByName('DESCRIPCION').AsString);
      dPrecio   := Q.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
      dCantidad := Q.FieldByName('CANTIDAD').AsFloat;
      dAnticipo := Q.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
      dTotal    := dPrecio * dCantidad;
      dPendiente := dTotal - dAnticipo;
      // Cabecera del depósito: referencia de operación + fecha.
      ATicket.Negrita(True);
      ATicket.EscribirLinea('Op.' +
        Q.FieldByName('NUMERO_OPERACION_DEP').AsString + ' ' +
        FormatDateTime('dd/mm/yy hh:nn',
          Q.FieldByName('FECHA_CREACION_DEP').AsDateTime));
      ATicket.Negrita(False);
      ATicket.EscribirLinea(Copy('Cli: ' + Trim(sCli + ' ' + sCliNom),
                                 1, N_CHAR_LIN));
      // Artículo: SKU con cantidad y valoración (precio x cantidad).
      sIzq := FormatFloat('0.##', dCantidad) + 'x ' + sSku;
      iMax := N_CHAR_LIN - Length(FmtImp(dTotal)) - 1;
      if Length(sIzq) > iMax then
        sIzq := Copy(sIzq, 1, iMax);
      ATicket.TextoColumnas(sIzq, FmtImp(dTotal));
      if sDesc <> '' then
        ATicket.EscribirLinea(Copy(sDesc, 1, N_CHAR_LIN));
      // Cobro del cliente (entregado a cuenta) y pendiente.
      if dAnticipo <> 0 then
        ATicket.TextoColumnas('  Entregado a cuenta', FmtImp(dAnticipo));
      ATicket.TextoColumnas('  Pendiente', FmtImp(dPendiente));
      dSubVenta   := dSubVenta   + dTotal;
      dSubCobrado := dSubCobrado + dAnticipo;
      Inc(iFilas);
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
  // Pie del bloque: nº de depósitos, total vendido a crédito y total cobrado.
  if iFilas = 0 then
    ATicket.EscribirLinea('Sin movimientos')
  else
  begin
    ATicket.TextoColumnas('DEPOSITOS', IntToStr(iFilas));
    ATicket.Negrita(True);
    ATicket.TextoColumnas('SUBTOTAL VENTA', FmtImp(dSubVenta));
    ATicket.Negrita(False);
    if dSubCobrado <> 0 then
      ATicket.TextoColumnas('SUBTOTAL COBRADO', FmtImp(dSubCobrado));
  end;
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
                                               = 'DEBUG';
                                         AIncluirTraspasos: Boolean = False;
                                         AIncluirIngresos: Boolean = False;
                                         AIncluirGastos: Boolean = False;
                                         AIncluirCredito: Boolean = False);
var
  Ope: TUniQuery;
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
  ComandosESC, RutaPDF, sSQL: string;
  iOperaciones: Integer;
  dTotal: Currency;
  bVerCoste: Boolean;
begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  iOperaciones := 0;
  dTotal       := 0;
  // Los traspasos solo se valoran (importes + subtotal) si el usuario tiene
  // permiso para ver coste; en caso contrario salen sin importe.
  bVerCoste := Assigned(oPermisos)
               and oPermisos.TienePermiso('caja.verCoste', False);
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
    // Resumen final de las ventas facturadas (no incluye los bloques aparte).
    Ticket.LineaSeparadora('=');
    Ticket.TextoColumnas('OPERACIONES', IntToStr(iOperaciones));
    Ticket.Negrita(True);
    Ticket.TextoColumnas('TOTAL', FmtImp(dTotal));
    Ticket.Negrita(False);
    // Bloques opcionales adjuntos, cada uno con su propio subtotal. Se acotan
    // al mismo rango y caja. Traspasos y depósitos llevan detalle de artículos;
    // ingresos (EC) y gastos (GC) son una fila por operación. Los traspasos
    // solo se valoran con permiso (bVerCoste).
    if AIncluirTraspasos then
      EscribirBloqueTraspasos(Ticket, AConn, AEmpresa, AAlmacen, ACaja,
                              AFechaDesde, AFechaHasta, bVerCoste);
    if AIncluirIngresos then
      EscribirBloque(Ticket, AConn, AEmpresa, AAlmacen, ACaja,
                     AFechaDesde, AFechaHasta,
                     '-INGRESOS POR CAJA-', '''EC''',
                     False, True);
    if AIncluirGastos then
      EscribirBloque(Ticket, AConn, AEmpresa, AAlmacen, ACaja,
                     AFechaDesde, AFechaHasta,
                     '-GASTOS POR CAJA-', '''GC''',
                     False, True);
    if AIncluirCredito then
      EscribirBloqueCredito(Ticket, AConn, AEmpresa, AAlmacen, ACaja,
                            AFechaDesde, AFechaHasta);
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
