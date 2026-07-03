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
{    las operaciones entre dos fechas para una empresa / almacén / caja. Las   }
{    ventas facturadas llevan nº de factura, nº de operación, fecha, líneas y  }
{    formas de pago. De forma opcional adjunta los traspasos salientes, los    }
{    ingresos por caja, los gastos por caja y las ventas a crédito (depósitos).}
{                                                                              }
{    Las ventas pueden acotarse a varias series de factura simplificada        }
{    (ASeries; vacío = todas). El agrupamiento (ACronologico) decide el orden: }
{    por tipo de documento (secciones con doble línea al romper el tipo) o por }
{    orden cronológico (operaciones intercaladas, cada una rotulada con su     }
{    tipo). En ambos modos hay una línea simple tras cada operación.           }
{                                                                              }
{    Si AImprimirQR es True y Verifactu está activo (envío PRE o PRO), añade   }
{    el QR tributario de cada venta. Si la impresora es 'DEBUG' abre el        }
{    preview (TFormVisualizador) en vez de mandar a la impresora física.       }
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
    // Render de una operación de traspaso saliente (cursor maestro posicionado):
    // cabecera (referencia + fecha) + almacén destino + detalle de artículos
    // (SKU, descripción, cantidad) de fza_movimientos_almacen. Con AValorar
    // (permiso caja.verCoste) añade el coste por línea y el total a coste, que
    // además devuelve.
    class function EscribirTraspasoOpe(ATicket: TTicketTermico;
                                       AConn: TUniConnection;
                                       AOpe: TUniQuery;
                                       AValorar: Boolean): Currency;
    // Render de una operación de ingreso (EC) o gasto (GC): referencia + fecha
    // + importe y el concepto. Devuelve el importe de la operación.
    class function EscribirIngresoGastoOpe(ATicket: TTicketTermico;
                                           AOpe: TUniQuery): Currency;
    // Render de una operación de depósito (DE = venta a crédito): por cada
    // depósito ligado a la operación, el cliente, el artículo (SKU +
    // descripción), la valoración (precio x cantidad), lo entregado a cuenta
    // (cobro del cliente) y el pendiente. Devuelve el total vendido y, en
    // ACobrado, lo entregado a cuenta.
    class function EscribirDepositoOpe(ATicket: TTicketTermico;
                                       AConn: TUniConnection;
                                       AOpe: TUniQuery;
                                       out ACobrado: Currency): Currency;
    // SQL del cursor maestro de operaciones (ventas multi-serie + tipos
    // opcionales), clasificadas por GRUPO. Lo comparten la impresión y el
    // volcado a Excel para que ambos muestren exactamente lo mismo.
    class function SQLOperaciones(const ASeries: TArray<string>;
                                  ACronologico, AIncluirTraspasos,
                                  AIncluirIngresos, AIncluirGastos,
                                  AIncluirCredito: Boolean): string;
    class procedure AsignarParamsOperaciones(AQuery: TUniQuery;
                                  const AEmpresa, AAlmacen, ACaja: string;
                                  AFechaDesde, AFechaHasta: TDate;
                                  const ASeries: TArray<string>);
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
                             const ASeries: TArray<string>;
                             AImprimirQR: Boolean = False;
                             const ANombreImpresora: string = 'DEBUG';
                             ACronologico: Boolean = False;
                             AIncluirTraspasos: Boolean = False;
                             AIncluirIngresos: Boolean = False;
                             AIncluirGastos: Boolean = False;
                             AIncluirCredito: Boolean = False);
    // Vuelca las mismas operaciones de la tira a una hoja de cálculo y la abre
    // en el visor de Excel (TfrmMtoPreviewExcel), con detalle por línea y el
    // mismo orden / agrupamiento que la impresión.
    class procedure ExportarExcel(AOwner: TComponent;
                                  AConn: TUniConnection;
                                  const AEmpresa, AAlmacen, ACaja: string;
                                  AFechaDesde, AFechaHasta: TDate;
                                  const ASeries: TArray<string>;
                                  ACronologico: Boolean = False;
                                  AIncluirTraspasos: Boolean = False;
                                  AIncluirIngresos: Boolean = False;
                                  AIncluirGastos: Boolean = False;
                                  AIncluirCredito: Boolean = False);
  end;

implementation

uses
  Vcl.Forms,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetGraphics,
  dxSpreadSheetTypes, dxSpreadSheetStyles, dxHashUtils,
  inMtoPreviewTicket, inLibDir, inLibFormatoDocumento, inLibVerifactu,
  inLibPermisos, inMtoPreviewExcel, inLibDevExcel;

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
end;

// =============================================================================
//   Render por operación (traspaso / ingreso-gasto / depósito)
// =============================================================================

class function TTiraCajaTicket.EscribirIngresoGastoOpe(
  ATicket: TTicketTermico; AOpe: TUniQuery): Currency;
var
  sRef, sConcepto: string;
  iMax: Integer;
begin
  Result := AOpe.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
  sConcepto := Trim(AOpe.FieldByName(
                 'CONCEPTO_GASTO_INGRESO_OPCAJA').AsString);
  // Fila 1: referencia (nº op + fecha) e importe a la derecha.
  sRef := 'Op.' + AOpe.FieldByName('NUMERO_OPERACION_OPCAJA').AsString + ' ' +
          FormatDateTime('dd/mm/yy hh:nn',
            AOpe.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
  iMax := N_CHAR_LIN - Length(FmtImp(Result)) - 1;
  if Length(sRef) > iMax then
    sRef := Copy(sRef, 1, iMax);
  ATicket.TextoColumnas(sRef, FmtImp(Result));
  // Fila 2: concepto descriptivo (gasto / ingreso), recortado.
  if sConcepto <> '' then
    ATicket.EscribirLinea(Copy(sConcepto, 1, N_CHAR_LIN));
end;

class function TTiraCajaTicket.EscribirTraspasoOpe(ATicket: TTicketTermico;
                                                   AConn: TUniConnection;
                                                   AOpe: TUniQuery;
                                                   AValorar: Boolean): Currency;
var
  Lin: TUniQuery;
  iMax: Integer;
  sEmp, sAlm, sCaja, sOpe, sRef, sDestino, sSku, sDesc, sIzq: string;
  dCantidad, dCosteUnit: Double;
begin
  Result   := 0;
  sEmp     := AOpe.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm     := AOpe.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja    := AOpe.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sOpe     := AOpe.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sDestino := Trim(AOpe.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString);
  // Referencia: documento formateado si lo tiene; si no, nº de operación.
  sRef := Trim(AOpe.FieldByName('SERIE_FAC_OPCAJA').AsString);
  if (sRef <> '') and
     (Trim(AOpe.FieldByName('NUMERO_FAC_OPCAJA').AsString) <> '') then
    sRef := FormatearDocumentoEmpresa(sEmp, sRef,
              AOpe.FieldByName('NUMERO_FAC_OPCAJA').AsString)
  else
    sRef := 'Op.' + sOpe;
  ATicket.Negrita(True);
  ATicket.EscribirLinea(sRef + ' ' +
    FormatDateTime('dd/mm/yy hh:nn',
      AOpe.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime));
  ATicket.Negrita(False);
  if sDestino <> '' then
    ATicket.EscribirLinea('  -> ' + sDestino);
  Lin := TUniQuery.Create(nil);
  try
    Lin.Connection := AConn;
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
    Lin.ParamByName('pEMP').AsString  := sEmp;
    Lin.ParamByName('pALM').AsString  := sAlm;
    Lin.ParamByName('pCAJA').AsString := sCaja;
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
      Result := Result + dCantidad * dCosteUnit;
      Lin.Next;
    end;
  finally
    FreeAndNil(Lin);
  end;
  if AValorar then
  begin
    ATicket.Negrita(True);
    ATicket.TextoColumnas('TOTAL TRASPASO (coste)', FmtImp(Result));
    ATicket.Negrita(False);
  end;
end;

class function TTiraCajaTicket.EscribirDepositoOpe(ATicket: TTicketTermico;
                                                   AConn: TUniConnection;
                                                   AOpe: TUniQuery;
                                                   out ACobrado: Currency)
                                                   : Currency;
var
  Q: TUniQuery;
  iMax: Integer;
  sEmp, sAlm, sCaja, sOpe, sCli, sCliNom, sSku, sDesc, sIzq: string;
  dCantidad: Double;
  dPrecio, dTotal, dAnticipo, dPendiente: Currency;
begin
  Result   := 0;
  ACobrado := 0;
  sEmp  := AOpe.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm  := AOpe.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja := AOpe.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sOpe  := AOpe.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  // Cabecera del depósito: referencia de operación + fecha.
  ATicket.Negrita(True);
  ATicket.EscribirLinea('Op.' + sOpe + ' ' +
    FormatDateTime('dd/mm/yy hh:nn',
      AOpe.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime));
  ATicket.Negrita(False);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    // Depósitos ligados a la operación. Un depósito = un SKU; una operación
    // puede tener varios. La valoración es PRECIO_VENTA_DEP x CANTIDAD;
    // IMPORTE_ANTICIPO_DEP es lo entregado a cuenta por el cliente.
    Q.SQL.Text :=
      ' SELECT d.CODIGO_CLI_DEP,                                         ' +
      '        COALESCE(c.RAZON_SOCIAL_CLI, '''') AS CLIENTE,            ' +
      '        d.CODIGO_UNIDAD_DEP,                                      ' +
      '        COALESCE(a.DESCRIPCION_ART, '''')   AS DESCRIPCION,       ' +
      '        d.PRECIO_VENTA_DEP,                                       ' +
      '        COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD,        ' +
      '        d.IMPORTE_ANTICIPO_DEP                                    ' +
      '   FROM fza_depositos_cliente d                                  ' +
      '   LEFT JOIN fza_clientes  c                                     ' +
      '     ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_DEP                       ' +
      '   LEFT JOIN fza_articulos a                                     ' +
      '     ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP                       ' +
      '  WHERE d.CODIGO_EMP_DEP        = :pEMP                           ' +
      '    AND d.CODIGO_ALM_DEP        = :pALM                           ' +
      '    AND d.CODIGO_CAJA_DEP       = :pCAJA                          ' +
      '    AND d.NUMERO_OPERACION_DEP  = :pOPE                           ' +
      '  ORDER BY d.ID_DEPOSITO_DEP                                      ';
    Q.ParamByName('pEMP').AsString  := sEmp;
    Q.ParamByName('pALM').AsString  := sAlm;
    Q.ParamByName('pCAJA').AsString := sCaja;
    Q.ParamByName('pOPE').AsString  := sOpe;
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
      Result   := Result + dTotal;
      ACobrado := ACobrado + dAnticipo;
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   SQL común del cursor maestro (lo comparten Imprimir y ExportarExcel)
// =============================================================================

class function TTiraCajaTicket.SQLOperaciones(const ASeries: TArray<string>;
  ACronologico, AIncluirTraspasos, AIncluirIngresos, AIncluirGastos,
  AIncluirCredito: Boolean): string;
var
  sCond, sLista, sSerieIn, sSQL: string;
  i: Integer;
begin
  // Placeholders de las series marcadas (vacío = todas).
  sSerieIn := '';
  for i := 0 to High(ASeries) do
  begin
    if sSerieIn <> '' then
      sSerieIn := sSerieIn + ',';
    sSerieIn := sSerieIn + ':pS' + IntToStr(i);
  end;
  // Condición de ventas facturadas (excluyendo los tipos de los bloques) más
  // los tipos opcionales marcados.
  sCond := ' (o.SERIE_FAC_OPCAJA IS NOT NULL                             ' +
           '  AND o.SERIE_FAC_OPCAJA <> ''''                             ' +
           '  AND o.TIPO_OPERACION_OPCAJA                                ' +
           '        NOT IN (''TR'',''AT'',''EC'',''GC'',''DE'') ';
  if sSerieIn <> '' then
    sCond := sCond + ' AND o.SERIE_FAC_OPCAJA IN (' + sSerieIn + ') ';
  sCond := sCond + ') ';
  sLista := '';
  if AIncluirTraspasos then
    sLista := sLista + ',''TR'',''AT''';
  if AIncluirIngresos then
    sLista := sLista + ',''EC''';
  if AIncluirGastos then
    sLista := sLista + ',''GC''';
  if AIncluirCredito then
    sLista := sLista + ',''DE''';
  if sLista <> '' then
  begin
    Delete(sLista, 1, 1);
    sCond := sCond + ' OR o.TIPO_OPERACION_OPCAJA IN (' + sLista + ') ';
  end;
  sSQL :=
    ' SELECT o.CODIGO_EMP_OPCAJA, o.CODIGO_ALM_OPCAJA,                 ' +
    '        o.CODIGO_CAJA_OPCAJA, o.NUMERO_OPERACION_OPCAJA,          ' +
    '        o.FECHA_OPERACION_OPCAJA, o.SERIE_FAC_OPCAJA,             ' +
    '        o.NUMERO_FAC_OPCAJA, o.IMPORTE_TOTAL_OPCAJA,              ' +
    '        o.CONCEPTO_GASTO_INGRESO_OPCAJA,                          ' +
    '        o.CODIGO_ALM_CONTRA_OPCAJA,                               ' +
    '        f.TOTAL_LIQUIDO_FAC, f.FECHA_FAC, f.NIF_EMPRESA_FAC,      ' +
    '        CASE                                                      ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA IN (''TR'',''AT'')         ' +
    '            THEN ''TRA''                                          ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''EC'' THEN ''ING''      ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''GC'' THEN ''GAS''      ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''DE'' THEN ''DEP''      ' +
    '          ELSE ''VEN'' END                       AS GRUPO,       ' +
    '        CASE                                                      ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA IN (''TR'',''AT'') THEN 2  ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''EC'' THEN 3            ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''GC'' THEN 4            ' +
    '          WHEN o.TIPO_OPERACION_OPCAJA = ''DE'' THEN 5            ' +
    '          ELSE 1 END                             AS GRUPO_ORDEN   ' +
    '   FROM fza_caja_operaciones o                                    ' +
    '   LEFT JOIN fza_facturas f                                       ' +
    '     ON f.CODIGO_EMP_FAC  = o.CODIGO_EMP_OPCAJA                   ' +
    '    AND f.CODIGO_ALM_FAC  = o.CODIGO_ALM_OPCAJA                   ' +
    '    AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA                  ' +
    '    AND f.SERIE_FAC       = o.SERIE_FAC_OPCAJA                    ' +
    '    AND f.NUMERO_FAC      = o.NUMERO_FAC_OPCAJA                   ' +
    '  WHERE o.CODIGO_EMP_OPCAJA   = :pEMP                             ' +
    '    AND o.CODIGO_ALM_OPCAJA   = :pALM                             ' +
    '    AND o.CODIGO_CAJA_OPCAJA  = :pCAJA                            ' +
    '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                      ' +
    '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                      ' +
    '    AND (' + sCond + ') ';
  if ACronologico then
    sSQL := sSQL +
      '  ORDER BY o.FECHA_OPERACION_OPCAJA, o.NUMERO_OPERACION_OPCAJA  '
  else
    sSQL := sSQL +
      '  ORDER BY GRUPO_ORDEN, o.FECHA_OPERACION_OPCAJA,               ' +
      '           o.NUMERO_OPERACION_OPCAJA                            ';
  Result := sSQL;
end;

class procedure TTiraCajaTicket.AsignarParamsOperaciones(AQuery: TUniQuery;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>);
var
  i: Integer;
begin
  AQuery.ParamByName('pEMP').AsString      := AEmpresa;
  AQuery.ParamByName('pALM').AsString      := AAlmacen;
  AQuery.ParamByName('pCAJA').AsString     := ACaja;
  AQuery.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
  AQuery.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
  for i := 0 to High(ASeries) do
    AQuery.ParamByName('pS' + IntToStr(i)).AsString := ASeries[i];
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
                                         const ASeries: TArray<string>;
                                         AImprimirQR: Boolean;
                                         const ANombreImpresora: string;
                                         ACronologico: Boolean;
                                         AIncluirTraspasos: Boolean;
                                         AIncluirIngresos: Boolean;
                                         AIncluirGastos: Boolean;
                                         AIncluirCredito: Boolean);
var
  Ope: TUniQuery;
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
  ComandosESC, RutaPDF, sSerieTxt: string;
  sGrupo, sPrevGrupo: string;
  i: Integer;
  bVerCoste: Boolean;
  dCobradoOp: Currency;
  nVen, nTra, nIng, nGas, nDep: Integer;
  totVen, totTra, totIng, totGas, totDepV, totDepC: Currency;

  // Rótulo corto del tipo, para el modo cronológico.
  function RotuloGrupo(const AG: string): string;
  begin
    if AG = 'TRA' then
      Result := 'TRASPASO'
    else if AG = 'ING' then
      Result := 'INGRESO'
    else if AG = 'GAS' then
      Result := 'GASTO'
    else if AG = 'DEP' then
      Result := 'DEPOSITO'
    else
      Result := 'VENTA';
  end;

  // Cabecera de sección (modo por tipo de documento).
  procedure CabeceraGrupo(const AG: string);
  begin
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    if AG = 'TRA' then
      Ticket.EscribirLinea('-TRASPASOS SALIENTES (ORIGEN)-')
    else if AG = 'ING' then
      Ticket.EscribirLinea('-INGRESOS POR CAJA-')
    else if AG = 'GAS' then
      Ticket.EscribirLinea('-GASTOS POR CAJA-')
    else if AG = 'DEP' then
      Ticket.EscribirLinea('-VENTAS A CREDITO (DEPOSITOS)-')
    else
      Ticket.EscribirLinea('-VENTAS FACTURADAS-');
    Ticket.Negrita(False);
    Ticket.Alinear(alIzquierda);
  end;

  // Pie / subtotal de un grupo según sus acumuladores.
  procedure SubtotalGrupo(const AG: string);
  begin
    if AG = 'TRA' then
    begin
      Ticket.TextoColumnas('TRASPASOS', IntToStr(nTra));
      if bVerCoste then
      begin
        Ticket.Negrita(True);
        Ticket.TextoColumnas('SUBTOTAL (coste)', FmtImp(totTra));
        Ticket.Negrita(False);
      end;
    end
    else if AG = 'ING' then
    begin
      Ticket.TextoColumnas('INGRESOS', IntToStr(nIng));
      Ticket.Negrita(True);
      Ticket.TextoColumnas('SUBTOTAL', FmtImp(totIng));
      Ticket.Negrita(False);
    end
    else if AG = 'GAS' then
    begin
      Ticket.TextoColumnas('GASTOS', IntToStr(nGas));
      Ticket.Negrita(True);
      Ticket.TextoColumnas('SUBTOTAL', FmtImp(totGas));
      Ticket.Negrita(False);
    end
    else if AG = 'DEP' then
    begin
      Ticket.TextoColumnas('DEPOSITOS', IntToStr(nDep));
      Ticket.Negrita(True);
      Ticket.TextoColumnas('SUBTOTAL VENTA', FmtImp(totDepV));
      Ticket.Negrita(False);
      if totDepC <> 0 then
        Ticket.TextoColumnas('SUBTOTAL COBRADO', FmtImp(totDepC));
    end
    else
    begin
      Ticket.TextoColumnas('OPERACIONES', IntToStr(nVen));
      Ticket.Negrita(True);
      Ticket.TextoColumnas('TOTAL VENTAS', FmtImp(totVen));
      Ticket.Negrita(False);
    end;
  end;

  // Render de la fila actual del cursor según su grupo, acumulando totales.
  procedure RenderFila(const AG: string);
  begin
    if AG = 'TRA' then
    begin
      totTra := totTra + EscribirTraspasoOpe(Ticket, AConn, Ope, bVerCoste);
      Inc(nTra);
    end
    else if AG = 'ING' then
    begin
      totIng := totIng + EscribirIngresoGastoOpe(Ticket, Ope);
      Inc(nIng);
    end
    else if AG = 'GAS' then
    begin
      totGas := totGas + EscribirIngresoGastoOpe(Ticket, Ope);
      Inc(nGas);
    end
    else if AG = 'DEP' then
    begin
      totDepV := totDepV + EscribirDepositoOpe(Ticket, AConn, Ope, dCobradoOp);
      totDepC := totDepC + dCobradoOp;
      Inc(nDep);
    end
    else
    begin
      EscribirOperacion(Ticket, AConn, Ope, AImprimirQR);
      totVen := totVen + Ope.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
      Inc(nVen);
    end;
  end;

begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  nVen   := 0;
  nTra   := 0;
  nIng   := 0;
  nGas   := 0;
  nDep   := 0;
  totVen   := 0;
  totTra   := 0;
  totIng   := 0;
  totGas   := 0;
  totDepV  := 0;
  totDepC  := 0;
  // Los traspasos solo se valoran (coste) si el usuario tiene permiso para ver
  // coste; el resto de bloques (ingresos, gastos, depósitos) siempre se valoran.
  bVerCoste := Assigned(oPermisos)
               and oPermisos.TienePermiso('caja.verCoste', False);
  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;
    EscribirCabeceraEmpresa(Ticket, AConn, AEmpresa);
    // Título: caja, rango exacto, series seleccionadas y modo de agrupamiento.
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(Format('-ARQUEO CAJA %s HORA %s-',
      [ACaja, FormatDateTime('hh:nn', Now)]));
    Ticket.EscribirLinea(Format('DEL %s',
      [FormatDateTime('dd/mm/yy hh:nn', AFechaDesde)]));
    Ticket.EscribirLinea(Format('AL  %s',
      [FormatDateTime('dd/mm/yy hh:nn', AFechaHasta)]));
    if Length(ASeries) = 0 then
      Ticket.EscribirLinea('TODAS LAS SERIES')
    else
    begin
      sSerieTxt := '';
      for i := 0 to High(ASeries) do
      begin
        if sSerieTxt <> '' then
          sSerieTxt := sSerieTxt + ', ';
        sSerieTxt := sSerieTxt + ASeries[i];
      end;
      Ticket.EscribirLinea('SERIES: ' + sSerieTxt);
    end;
    if ACronologico then
      Ticket.EscribirLinea('ORDEN: CRONOLOGICO')
    else
      Ticket.EscribirLinea('ORDEN: POR TIPO DE DOCUMENTO');
    Ticket.Negrita(False);
    Ticket.Alinear(alIzquierda);
    Ticket.SaltarLineas(1);
    // Cursor maestro: el mismo SQL (ventas multi-serie + tipos marcados) que
    // usa el volcado a Excel, para que ambos muestren exactamente lo mismo.
    Ope := TUniQuery.Create(nil);
    try
      Ope.Connection := AConn;
      Ope.SQL.Text := SQLOperaciones(ASeries, ACronologico,
                                     AIncluirTraspasos, AIncluirIngresos,
                                     AIncluirGastos, AIncluirCredito);
      AsignarParamsOperaciones(Ope, AEmpresa, AAlmacen, ACaja,
                               AFechaDesde, AFechaHasta, ASeries);
      Ope.Open;
      sPrevGrupo := '';
      while not Ope.Eof do
      begin
        sGrupo := Ope.FieldByName('GRUPO').AsString;
        if ACronologico then
        begin
          // Cada operación rotulada con su tipo, para saber qué es cada una.
          Ticket.Negrita(True);
          Ticket.EscribirLinea('[' + RotuloGrupo(sGrupo) + ']');
          Ticket.Negrita(False);
        end
        else
        begin
          // Cambio de tipo: cierra el grupo anterior (subtotal), lo rompe con
          // doble línea y abre la cabecera del nuevo grupo.
          if sGrupo <> sPrevGrupo then
          begin
            if sPrevGrupo <> '' then
            begin
              SubtotalGrupo(sPrevGrupo);
              Ticket.LineaSeparadora('=');
              Ticket.LineaSeparadora('=');
            end
            else
              Ticket.LineaSeparadora('=');
            CabeceraGrupo(sGrupo);
          end;
        end;
        RenderFila(sGrupo);
        // Línea simple tras cada operación, en ambos modos.
        Ticket.LineaSeparadora('-');
        sPrevGrupo := sGrupo;
        Ope.Next;
      end;
    finally
      FreeAndNil(Ope);
    end;
    // Cierre: subtotal del último grupo (por tipo) o resumen (cronológico).
    if (nVen + nTra + nIng + nGas + nDep) = 0 then
      Ticket.EscribirLinea('Sin operaciones')
    else if not ACronologico then
      SubtotalGrupo(sPrevGrupo)
    else
    begin
      Ticket.LineaSeparadora('=');
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      Ticket.EscribirLinea('-RESUMEN-');
      Ticket.Negrita(False);
      Ticket.Alinear(alIzquierda);
      if nVen > 0 then
        SubtotalGrupo('VEN');
      if nTra > 0 then
        SubtotalGrupo('TRA');
      if nIng > 0 then
        SubtotalGrupo('ING');
      if nGas > 0 then
        SubtotalGrupo('GAS');
      if nDep > 0 then
        SubtotalGrupo('DEP');
    end;
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

class procedure TTiraCajaTicket.ExportarExcel(AOwner: TComponent;
  AConn: TUniConnection; const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
  ACronologico: Boolean = False; AIncluirTraspasos: Boolean = False;
  AIncluirIngresos: Boolean = False; AIncluirGastos: Boolean = False;
  AIncluirCredito: Boolean = False);
const
  cTIPO  = 0;
  cFECHA = 1;
  cDOC   = 2;
  cREF   = 3;
  cSKU   = 4;
  cDESC  = 5;
  cCANT  = 6;
  cIMP   = 7;
  cCOB   = 8;
  cPEN   = 9;
var
  Frm: TfrmMtoPreviewExcel;
  Sheet: TdxSpreadSheetTableView;
  Ope: TUniQuery;
  r, i: Integer;
  bVerCoste: Boolean;
  sGrupo, sPrevGrupo, sSerieTxt: string;
  impVen, impTra, impIng, impGas, vtaDep, cobDep: Currency;
  nVen, nTra, nIng, nGas, nDep: Integer;

  // Importe con formato de moneda en una celda.
  procedure WMoney(ARow, ACol: Integer; const AValor: Currency);
  begin
    W(Sheet, ARow, ACol, AValor, False, ssahRight);
    Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode := '#,##0.00';
  end;

  // Documento formateado de la fila actual o, si no lo tiene, nº de operación.
  function RefDoc: string;
  begin
    if Trim(Ope.FieldByName('SERIE_FAC_OPCAJA').AsString) <> '' then
      Result := FormatearDocumentoEmpresa(
        Ope.FieldByName('CODIGO_EMP_OPCAJA').AsString,
        Ope.FieldByName('SERIE_FAC_OPCAJA').AsString,
        Ope.FieldByName('NUMERO_FAC_OPCAJA').AsString)
    else
      Result := 'Op.' + Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  end;

  function FechaOpe: string;
  begin
    Result := FormatDateTime('dd/mm/yyyy hh:nn',
      Ope.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
  end;

  procedure VolcarVenta;
  var
    Q: TUniQuery;
    sDoc: string;
  begin
    sDoc := RefDoc;
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        ' SELECT CODIGO_UNIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN,     ' +
        '        CANTIDAD_FACLIN, TOTAL_FACLIN                          ' +
        '   FROM fza_facturas_lineas                                    ' +
        '  WHERE CODIGO_EMP_FACLIN       = :pEMP                        ' +
        '    AND CODIGO_ALM_FACLIN       = :pALM                        ' +
        '    AND CODIGO_CAJA_FACLIN      = :pCAJA                       ' +
        '    AND NUMERO_OPERACION_FACLIN = :pOPE                        ' +
        '  ORDER BY LINEA_FACLIN                                        ';
      Q.ParamByName('pEMP').AsString  :=
        Ope.FieldByName('CODIGO_EMP_OPCAJA').AsString;
      Q.ParamByName('pALM').AsString  :=
        Ope.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      Q.ParamByName('pCAJA').AsString :=
        Ope.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      Q.ParamByName('pOPE').AsString  :=
        Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Q.Open;
      while not Q.Eof do
      begin
        W(Sheet, r, cTIPO,  'Venta');
        W(Sheet, r, cFECHA, FechaOpe);
        W(Sheet, r, cDOC,   sDoc);
        W(Sheet, r, cSKU,   Q.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
        W(Sheet, r, cDESC,
          Q.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString);
        W(Sheet, r, cCANT,  Q.FieldByName('CANTIDAD_FACLIN').AsFloat,
          False, ssahRight);
        WMoney(r, cIMP, Q.FieldByName('TOTAL_FACLIN').AsCurrency);
        impVen := impVen + Q.FieldByName('TOTAL_FACLIN').AsCurrency;
        Inc(r);
        Q.Next;
      end;
    finally
      FreeAndNil(Q);
    end;
    Inc(nVen);
  end;

  procedure VolcarTraspaso;
  var
    Q: TUniQuery;
    sDoc, sDest: string;
    dCant, dCoste: Double;
  begin
    sDoc  := RefDoc;
    sDest := Trim(Ope.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString);
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        ' SELECT m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV,                   ' +
        '        COALESCE(NULLIF(TRIM(m.DESCRIPCION_ARTICULO_MOV),''''),' +
        '                 a.DESCRIPCION_ART, '''') AS DESCRIPCION,      ' +
        '        m.PRECIO_COSTE_UNITARIO_MOV                            ' +
        '   FROM fza_movimientos_almacen m                             ' +
        '   LEFT JOIN fza_articulos a                                  ' +
        '     ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV                   ' +
        '  WHERE m.CODIGO_EMP_MOV           = :pEMP                    ' +
        '    AND m.CODIGO_ALM_DOC_MOV       = :pALM                    ' +
        '    AND m.CODIGO_CAJA_DOC_MOV      = :pCAJA                   ' +
        '    AND m.NUMERO_OPERACION_DOC_MOV = :pOPE                    ' +
        '    AND m.TIPO_MOV = ''S''                                   ' +
        '  ORDER BY m.LINEA_MOV                                       ';
      Q.ParamByName('pEMP').AsString  :=
        Ope.FieldByName('CODIGO_EMP_OPCAJA').AsString;
      Q.ParamByName('pALM').AsString  :=
        Ope.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      Q.ParamByName('pCAJA').AsString :=
        Ope.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      Q.ParamByName('pOPE').AsString  :=
        Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Q.Open;
      while not Q.Eof do
      begin
        dCant  := Q.FieldByName('CANTIDAD_MOV').AsFloat;
        dCoste := Q.FieldByName('PRECIO_COSTE_UNITARIO_MOV').AsFloat;
        W(Sheet, r, cTIPO,  'Traspaso');
        W(Sheet, r, cFECHA, FechaOpe);
        W(Sheet, r, cDOC,   sDoc);
        W(Sheet, r, cREF,   sDest);
        W(Sheet, r, cSKU,   Q.FieldByName('CODIGO_UNIDAD_MOV').AsString);
        W(Sheet, r, cDESC,  Q.FieldByName('DESCRIPCION').AsString);
        W(Sheet, r, cCANT,  dCant, False, ssahRight);
        if bVerCoste then
        begin
          WMoney(r, cIMP, dCant * dCoste);
          impTra := impTra + dCant * dCoste;
        end;
        Inc(r);
        Q.Next;
      end;
    finally
      FreeAndNil(Q);
    end;
    Inc(nTra);
  end;

  procedure VolcarIngresoGasto(const ATipo: string);
  var
    dImp: Currency;
  begin
    dImp := Ope.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
    W(Sheet, r, cTIPO,  ATipo);
    W(Sheet, r, cFECHA, FechaOpe);
    W(Sheet, r, cDOC,
      'Op.' + Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString);
    W(Sheet, r, cDESC,
      Trim(Ope.FieldByName('CONCEPTO_GASTO_INGRESO_OPCAJA').AsString));
    WMoney(r, cIMP, dImp);
    if ATipo = 'Ingreso' then
    begin
      impIng := impIng + dImp;
      Inc(nIng);
    end
    else
    begin
      impGas := impGas + dImp;
      Inc(nGas);
    end;
    Inc(r);
  end;

  procedure VolcarDeposito;
  var
    Q: TUniQuery;
    dCant: Double;
    dPre, dTot, dAnt: Currency;
  begin
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        ' SELECT d.CODIGO_CLI_DEP,                                      ' +
        '        COALESCE(c.RAZON_SOCIAL_CLI,'''') AS CLIENTE,          ' +
        '        d.CODIGO_UNIDAD_DEP,                                   ' +
        '        COALESCE(a.DESCRIPCION_ART,'''')  AS DESCRIPCION,      ' +
        '        d.PRECIO_VENTA_DEP,                                    ' +
        '        COALESCE(d.CANTIDAD_PENDIENTE_DEP,1) AS CANTIDAD,      ' +
        '        d.IMPORTE_ANTICIPO_DEP                                 ' +
        '   FROM fza_depositos_cliente d                               ' +
        '   LEFT JOIN fza_clientes  c                                  ' +
        '     ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_DEP                    ' +
        '   LEFT JOIN fza_articulos a                                  ' +
        '     ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP                    ' +
        '  WHERE d.CODIGO_EMP_DEP       = :pEMP                         ' +
        '    AND d.CODIGO_ALM_DEP       = :pALM                         ' +
        '    AND d.CODIGO_CAJA_DEP      = :pCAJA                        ' +
        '    AND d.NUMERO_OPERACION_DEP = :pOPE                         ' +
        '  ORDER BY d.ID_DEPOSITO_DEP                                   ';
      Q.ParamByName('pEMP').AsString  :=
        Ope.FieldByName('CODIGO_EMP_OPCAJA').AsString;
      Q.ParamByName('pALM').AsString  :=
        Ope.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      Q.ParamByName('pCAJA').AsString :=
        Ope.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      Q.ParamByName('pOPE').AsString  :=
        Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Q.Open;
      while not Q.Eof do
      begin
        dPre  := Q.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        dCant := Q.FieldByName('CANTIDAD').AsFloat;
        dAnt  := Q.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
        dTot  := dPre * dCant;
        W(Sheet, r, cTIPO,  'Crédito (depósito)');
        W(Sheet, r, cFECHA, FechaOpe);
        W(Sheet, r, cDOC,
          'Op.' + Ope.FieldByName('NUMERO_OPERACION_OPCAJA').AsString);
        W(Sheet, r, cREF,
          Trim(Q.FieldByName('CODIGO_CLI_DEP').AsString + ' ' +
               Q.FieldByName('CLIENTE').AsString));
        W(Sheet, r, cSKU,   Q.FieldByName('CODIGO_UNIDAD_DEP').AsString);
        W(Sheet, r, cDESC,  Q.FieldByName('DESCRIPCION').AsString);
        W(Sheet, r, cCANT,  dCant, False, ssahRight);
        WMoney(r, cIMP, dTot);
        WMoney(r, cCOB, dAnt);
        WMoney(r, cPEN, dTot - dAnt);
        vtaDep := vtaDep + dTot;
        cobDep := cobDep + dAnt;
        Inc(r);
        Q.Next;
      end;
    finally
      FreeAndNil(Q);
    end;
    Inc(nDep);
  end;

  // Título de sección (modo por tipo de documento).
  procedure TituloGrupo(const AG: string);
  begin
    if AG = 'TRA' then
      W(Sheet, r, cTIPO, 'TRASPASOS SALIENTES (ORIGEN)', True)
    else if AG = 'ING' then
      W(Sheet, r, cTIPO, 'INGRESOS POR CAJA', True)
    else if AG = 'GAS' then
      W(Sheet, r, cTIPO, 'GASTOS POR CAJA', True)
    else if AG = 'DEP' then
      W(Sheet, r, cTIPO, 'VENTAS A CREDITO (DEPOSITOS)', True)
    else
      W(Sheet, r, cTIPO, 'VENTAS FACTURADAS', True);
    Inc(r);
  end;

  // Subtotal de un grupo según sus acumuladores.
  procedure SubtotalGrupo(const AG: string);
  begin
    if AG = 'TRA' then
    begin
      W(Sheet, r, cDESC, 'SUBTOTAL TRASPASOS (coste)', True, ssahRight);
      if bVerCoste then
        WMoney(r, cIMP, impTra);
    end
    else if AG = 'ING' then
    begin
      W(Sheet, r, cDESC, 'SUBTOTAL INGRESOS', True, ssahRight);
      WMoney(r, cIMP, impIng);
    end
    else if AG = 'GAS' then
    begin
      W(Sheet, r, cDESC, 'SUBTOTAL GASTOS', True, ssahRight);
      WMoney(r, cIMP, impGas);
    end
    else if AG = 'DEP' then
    begin
      W(Sheet, r, cDESC, 'SUBTOTAL DEPOSITOS', True, ssahRight);
      WMoney(r, cIMP, vtaDep);
      WMoney(r, cCOB, cobDep);
    end
    else
    begin
      W(Sheet, r, cDESC, 'SUBTOTAL VENTAS', True, ssahRight);
      WMoney(r, cIMP, impVen);
    end;
    Inc(r);
  end;

  // Vuelca la fila actual del cursor según su grupo.
  procedure VolcarFila(const AG: string);
  begin
    if AG = 'TRA' then
      VolcarTraspaso
    else if AG = 'ING' then
      VolcarIngresoGasto('Ingreso')
    else if AG = 'GAS' then
      VolcarIngresoGasto('Gasto')
    else if AG = 'DEP' then
      VolcarDeposito
    else
      VolcarVenta;
  end;

begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  impVen := 0;
  impTra := 0;
  impIng := 0;
  impGas := 0;
  vtaDep := 0;
  cobDep := 0;
  nVen := 0;
  nTra := 0;
  nIng := 0;
  nGas := 0;
  nDep := 0;
  bVerCoste := Assigned(oPermisos)
               and oPermisos.TienePermiso('caja.verCoste', False);
  Frm := TfrmMtoPreviewExcel.Create(AOwner);
  try
    if Frm.dxSpreadSheet1.SheetCount = 0 then
      Frm.dxSpreadSheet1.AddSheet('Tira de Caja', TdxSpreadSheetTableView);
    Sheet := Frm.dxSpreadSheet1.ActiveSheetAsTable;
    if Sheet <> nil then
    begin
      Sheet.BeginUpdate;
      try
        // Cabecera informativa (caja, rango, series y orden).
        W(Sheet, 0, cTIPO, 'TIRA DE CAJA · CAJA ' + ACaja, True);
        W(Sheet, 1, cTIPO, 'DEL ' +
          FormatDateTime('dd/mm/yyyy hh:nn', AFechaDesde) + '  AL ' +
          FormatDateTime('dd/mm/yyyy hh:nn', AFechaHasta));
        if Length(ASeries) = 0 then
          sSerieTxt := 'TODAS LAS SERIES'
        else
        begin
          sSerieTxt := 'SERIES: ';
          for i := 0 to High(ASeries) do
          begin
            if i > 0 then
              sSerieTxt := sSerieTxt + ', ';
            sSerieTxt := sSerieTxt + ASeries[i];
          end;
        end;
        W(Sheet, 2, cTIPO, sSerieTxt);
        if ACronologico then
          W(Sheet, 3, cTIPO, 'ORDEN: CRONOLOGICO')
        else
          W(Sheet, 3, cTIPO, 'ORDEN: POR TIPO DE DOCUMENTO');
        // Cabecera de columnas.
        W(Sheet, 5, cTIPO,  'Tipo',            True);
        W(Sheet, 5, cFECHA, 'Fecha',           True);
        W(Sheet, 5, cDOC,   'Documento',       True);
        W(Sheet, 5, cREF,   'Cliente/Destino', True);
        W(Sheet, 5, cSKU,   'SKU',             True);
        W(Sheet, 5, cDESC,  'Descripción',     True);
        W(Sheet, 5, cCANT,  'Cantidad',        True, ssahRight);
        W(Sheet, 5, cIMP,   'Importe',         True, ssahRight);
        W(Sheet, 5, cCOB,   'Cobrado',         True, ssahRight);
        W(Sheet, 5, cPEN,   'Pendiente',       True, ssahRight);
        r := 6;
        Ope := TUniQuery.Create(nil);
        try
          Ope.Connection := AConn;
          Ope.SQL.Text := SQLOperaciones(ASeries, ACronologico,
                                         AIncluirTraspasos, AIncluirIngresos,
                                         AIncluirGastos, AIncluirCredito);
          AsignarParamsOperaciones(Ope, AEmpresa, AAlmacen, ACaja,
                                   AFechaDesde, AFechaHasta, ASeries);
          Ope.Open;
          sPrevGrupo := '';
          while not Ope.Eof do
          begin
            sGrupo := Ope.FieldByName('GRUPO').AsString;
            // Modo por tipo: subtotal del grupo anterior + título del nuevo.
            if (not ACronologico) and (sGrupo <> sPrevGrupo) then
            begin
              if sPrevGrupo <> '' then
              begin
                SubtotalGrupo(sPrevGrupo);
                Inc(r);
              end;
              TituloGrupo(sGrupo);
            end;
            VolcarFila(sGrupo);
            sPrevGrupo := sGrupo;
            Ope.Next;
          end;
        finally
          FreeAndNil(Ope);
        end;
        // Cierre: subtotal del último grupo (por tipo) o resumen (cronológico).
        if (nVen + nTra + nIng + nGas + nDep) = 0 then
          W(Sheet, r, cTIPO, 'Sin operaciones')
        else if not ACronologico then
          SubtotalGrupo(sPrevGrupo)
        else
        begin
          Inc(r);
          W(Sheet, r, cTIPO, 'RESUMEN', True);
          Inc(r);
          if nVen > 0 then
            SubtotalGrupo('VEN');
          if nTra > 0 then
            SubtotalGrupo('TRA');
          if nIng > 0 then
            SubtotalGrupo('ING');
          if nGas > 0 then
            SubtotalGrupo('GAS');
          if nDep > 0 then
            SubtotalGrupo('DEP');
        end;
      finally
        Sheet.EndUpdate;
      end;
      if AOwner is TForm then
        Frm.PopupParent := TForm(AOwner);
      Frm.DialogoGuardar.FileName := 'TiraCaja_' +
        FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now);
      Frm.ShowModal;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

end.
