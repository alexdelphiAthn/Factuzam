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
  inLibFTicket, inLibParametrosIntf;

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
    class procedure EscribirOperacion(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      ATicket: TTicketTermico;
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
    class procedure Imprimir(
                             const AParametrosApp: IParametrosAplicacion;
                             AConn: TUniConnection;
                             const AEmpresa, AAlmacen, ACaja: string;
                             AFechaDesde, AFechaHasta: TDate;
                             const ASeries: TArray<string>;
                             AImprimirQR: Boolean = False;
                             const ANombreImpresora: string = 'DEBUG';
                             ACronologico: Boolean = False;
                             AIncluirTraspasos: Boolean = False;
                             AIncluirIngresos: Boolean = False;
                             AIncluirGastos: Boolean = False;
                             AIncluirCredito: Boolean = False;
                             AValorarTraspasos: Boolean = False);
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
                                  AIncluirCredito: Boolean = False;
                                  AValorarTraspasos: Boolean = False);
  end;

implementation

uses
  Vcl.Forms,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetGraphics,
  dxSpreadSheetTypes, dxSpreadSheetStyles, dxHashUtils,
  inLibPreviewTicket, inLibDir, inLibFormatoDocumento, inLibVerifactu,
  inLibPreviewExcel, inLibDevExcel, inLibRectificativas;

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

class procedure TTiraCajaTicket.EscribirOperacion(
                                                   const AParametrosApp:
                                                   IParametrosAplicacion;
                                                   ATicket: TTicketTermico;
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
                   FormatearDocumentoEmpresa(AConn, sEmp, sSerie, sNumFac),
                   '_'));
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
  if AImprimirQR and (not SinVerifactuActivo(AParametrosApp))
     and (Trim(sSerie) <> '') and (Trim(sNumFac) <> '') then
  begin
    sQR := ConstruirUrlQR(AParametrosApp, sNif, sSerie, sNumFac,
      dFechaFac, dLiquido);
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
    sRef := FormatearDocumentoEmpresa(AConn, sEmp, sRef,
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
    SQLExcluirSimplificadaSustituida(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
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
      SQLExcluirSimplificadaSustituida(
        'o.CODIGO_EMP_OPCAJA',
        'o.SERIE_FAC_OPCAJA',
        'o.NUMERO_FAC_OPCAJA') +
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

class procedure TTiraCajaTicket.Imprimir(
                                         const AParametrosApp:
                                         IParametrosAplicacion;
                                         AConn: TUniConnection;
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
                                         AIncluirCredito: Boolean;
                                         AValorarTraspasos: Boolean);
var
  Ope: TUniQuery;
  Ticket: TTicketTermico;
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
      EscribirOperacion(AParametrosApp, Ticket, AConn, Ope, AImprimirQR);
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
  bVerCoste := AValorarTraspasos;
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
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

const
  COL_EXCEL_TIPO = 0;
  COL_EXCEL_FECHA = 1;
  COL_EXCEL_DOCUMENTO = 2;
  COL_EXCEL_REFERENCIA = 3;
  COL_EXCEL_SKU = 4;
  COL_EXCEL_DESCRIPCION = 5;
  COL_EXCEL_CANTIDAD = 6;
  COL_EXCEL_IMPORTE = 7;
  COL_EXCEL_COBRADO = 8;
  COL_EXCEL_PENDIENTE = 9;
  SQL_EXCEL_VENTAS =
    ' SELECT CODIGO_UNIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN,     ' +
    '        CANTIDAD_FACLIN, TOTAL_FACLIN                          ' +
    '   FROM fza_facturas_lineas                                    ' +
    '  WHERE CODIGO_EMP_FACLIN       = :pEMP                        ' +
    '    AND CODIGO_ALM_FACLIN       = :pALM                        ' +
    '    AND CODIGO_CAJA_FACLIN      = :pCAJA                       ' +
    '    AND NUMERO_OPERACION_FACLIN = :pOPE                        ' +
    '  ORDER BY LINEA_FACLIN                                        ';
  SQL_EXCEL_TRASPASOS =
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
  SQL_EXCEL_DEPOSITOS =
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

type
  TExportadorTiraCajaExcel = class
  private
    FPropietario: TComponent;
    FConexion: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaDesde: TDate;
    FFechaHasta: TDate;
    FSeries: TArray<string>;
    FCronologico: Boolean;
    FIncluirTraspasos: Boolean;
    FIncluirIngresos: Boolean;
    FIncluirGastos: Boolean;
    FIncluirCredito: Boolean;
    FVerCoste: Boolean;
    FPreview: TSesionPreviewExcel;
    FHoja: TdxSpreadSheetTableView;
    FOperacion: TUniQuery;
    FFila: Integer;
    FImporteVentas: Currency;
    FImporteTraspasos: Currency;
    FImporteIngresos: Currency;
    FImporteGastos: Currency;
    FVentaDepositos: Currency;
    FCobroDepositos: Currency;
    FNumeroVentas: Integer;
    FNumeroTraspasos: Integer;
    FNumeroIngresos: Integer;
    FNumeroGastos: Integer;
    FNumeroDepositos: Integer;
    function TextoOperacion(const ACampo: string): string;
    function ReferenciaDocumento: string;
    function FechaOperacion: string;
    function TextoSeries: string;
    function CrearConsultaDetalle(const ASql: string): TUniQuery;
    procedure AsignarParametrosDetalle(AQuery: TUniQuery);
    procedure EscribirMoneda(AFila, AColumna: Integer; AValor: Currency);
    procedure EscribirCabecera;
    procedure VolcarVenta;
    procedure VolcarTraspaso;
    procedure VolcarIngresoGasto(const ATipo: string);
    procedure VolcarDeposito;
    procedure EscribirTituloGrupo(const AGrupo: string);
    procedure EscribirSubtotalGrupo(const AGrupo: string);
    procedure VolcarFila(const AGrupo: string);
    procedure ProcesarOperaciones;
    procedure EscribirCierre(const AUltimoGrupo: string);
  public
    constructor Create(APropietario: TComponent; AConexion: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
      ACronologico, AIncluirTraspasos, AIncluirIngresos,
      AIncluirGastos, AIncluirCredito, AVerCoste: Boolean);
    procedure Ejecutar;
  end;

constructor TExportadorTiraCajaExcel.Create(APropietario: TComponent;
  AConexion: TUniConnection; const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
  ACronologico, AIncluirTraspasos, AIncluirIngresos,
  AIncluirGastos, AIncluirCredito, AVerCoste: Boolean);
begin
  inherited Create;
  FPropietario := APropietario;
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFechaDesde := AFechaDesde;
  FFechaHasta := AFechaHasta;
  FSeries := ASeries;
  FCronologico := ACronologico;
  FIncluirTraspasos := AIncluirTraspasos;
  FIncluirIngresos := AIncluirIngresos;
  FIncluirGastos := AIncluirGastos;
  FIncluirCredito := AIncluirCredito;
  FVerCoste := AVerCoste;
end;

function TExportadorTiraCajaExcel.TextoOperacion(
  const ACampo: string): string;
begin
  Result := FOperacion.FieldByName(ACampo).AsString;
end;

function TExportadorTiraCajaExcel.ReferenciaDocumento: string;
begin
  if Trim(TextoOperacion('SERIE_FAC_OPCAJA')) <> '' then
    Result := FormatearDocumentoEmpresa(FConexion,
      TextoOperacion('CODIGO_EMP_OPCAJA'),
      TextoOperacion('SERIE_FAC_OPCAJA'),
      TextoOperacion('NUMERO_FAC_OPCAJA'))
  else
    Result := 'Op.' + TextoOperacion('NUMERO_OPERACION_OPCAJA');
end;

function TExportadorTiraCajaExcel.FechaOperacion: string;
begin
  Result := FormatDateTime('dd/mm/yyyy hh:nn',
    FOperacion.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
end;

function TExportadorTiraCajaExcel.TextoSeries: string;
var
  iSerie: Integer;
begin
  if Length(FSeries) = 0 then
    Result := 'TODAS LAS SERIES'
  else
  begin
    Result := 'SERIES: ';
    for iSerie := 0 to High(FSeries) do
    begin
      if iSerie > 0 then
        Result := Result + ', ';
      Result := Result + FSeries[iSerie];
    end;
  end;
end;

procedure TExportadorTiraCajaExcel.AsignarParametrosDetalle(
  AQuery: TUniQuery);
begin
  AQuery.ParamByName('pEMP').AsString :=
    TextoOperacion('CODIGO_EMP_OPCAJA');
  AQuery.ParamByName('pALM').AsString :=
    TextoOperacion('CODIGO_ALM_OPCAJA');
  AQuery.ParamByName('pCAJA').AsString :=
    TextoOperacion('CODIGO_CAJA_OPCAJA');
  AQuery.ParamByName('pOPE').AsString :=
    TextoOperacion('NUMERO_OPERACION_OPCAJA');
end;

function TExportadorTiraCajaExcel.CrearConsultaDetalle(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := FConexion;
    Result.SQL.Text := ASql;
    AsignarParametrosDetalle(Result);
    Result.Open;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TExportadorTiraCajaExcel.EscribirMoneda(
  AFila, AColumna: Integer; AValor: Currency);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode := '#,##0.00';
end;

procedure TExportadorTiraCajaExcel.EscribirCabecera;
begin
  W(FHoja, 0, COL_EXCEL_TIPO, 'TIRA DE CAJA · CAJA ' + FCaja, True);
  W(FHoja, 1, COL_EXCEL_TIPO, 'DEL ' +
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaDesde) + '  AL ' +
    FormatDateTime('dd/mm/yyyy hh:nn', FFechaHasta));
  W(FHoja, 2, COL_EXCEL_TIPO, TextoSeries);
  if FCronologico then
    W(FHoja, 3, COL_EXCEL_TIPO, 'ORDEN: CRONOLOGICO')
  else
    W(FHoja, 3, COL_EXCEL_TIPO, 'ORDEN: POR TIPO DE DOCUMENTO');
  W(FHoja, 5, COL_EXCEL_TIPO, 'Tipo', True);
  W(FHoja, 5, COL_EXCEL_FECHA, 'Fecha', True);
  W(FHoja, 5, COL_EXCEL_DOCUMENTO, 'Documento', True);
  W(FHoja, 5, COL_EXCEL_REFERENCIA, 'Cliente/Destino', True);
  W(FHoja, 5, COL_EXCEL_SKU, 'SKU', True);
  W(FHoja, 5, COL_EXCEL_DESCRIPCION, 'Descripción', True);
  W(FHoja, 5, COL_EXCEL_CANTIDAD, 'Cantidad', True, ssahRight);
  W(FHoja, 5, COL_EXCEL_IMPORTE, 'Importe', True, ssahRight);
  W(FHoja, 5, COL_EXCEL_COBRADO, 'Cobrado', True, ssahRight);
  W(FHoja, 5, COL_EXCEL_PENDIENTE, 'Pendiente', True, ssahRight);
  FFila := 6;
end;

procedure TExportadorTiraCajaExcel.VolcarVenta;
var
  oDetalle: TUniQuery;
  sDocumento: string;
begin
  sDocumento := ReferenciaDocumento;
  oDetalle := CrearConsultaDetalle(SQL_EXCEL_VENTAS);
  try
    while not oDetalle.Eof do
    begin
      W(FHoja, FFila, COL_EXCEL_TIPO, 'Venta');
      W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
      W(FHoja, FFila, COL_EXCEL_DOCUMENTO, sDocumento);
      W(FHoja, FFila, COL_EXCEL_SKU,
        oDetalle.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
      W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
        oDetalle.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString);
      W(FHoja, FFila, COL_EXCEL_CANTIDAD,
        oDetalle.FieldByName('CANTIDAD_FACLIN').AsFloat,
        False, ssahRight);
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE,
        oDetalle.FieldByName('TOTAL_FACLIN').AsCurrency);
      FImporteVentas := FImporteVentas +
        oDetalle.FieldByName('TOTAL_FACLIN').AsCurrency;
      Inc(FFila);
      oDetalle.Next;
    end;
  finally
    FreeAndNil(oDetalle);
  end;
  Inc(FNumeroVentas);
end;

procedure TExportadorTiraCajaExcel.VolcarTraspaso;
var
  dCantidad, dCoste: Double;
  oDetalle: TUniQuery;
  sDestino, sDocumento: string;
begin
  sDocumento := ReferenciaDocumento;
  sDestino := Trim(TextoOperacion('CODIGO_ALM_CONTRA_OPCAJA'));
  oDetalle := CrearConsultaDetalle(SQL_EXCEL_TRASPASOS);
  try
    while not oDetalle.Eof do
    begin
      dCantidad := oDetalle.FieldByName('CANTIDAD_MOV').AsFloat;
      dCoste := oDetalle.FieldByName(
        'PRECIO_COSTE_UNITARIO_MOV').AsFloat;
      W(FHoja, FFila, COL_EXCEL_TIPO, 'Traspaso');
      W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
      W(FHoja, FFila, COL_EXCEL_DOCUMENTO, sDocumento);
      W(FHoja, FFila, COL_EXCEL_REFERENCIA, sDestino);
      W(FHoja, FFila, COL_EXCEL_SKU,
        oDetalle.FieldByName('CODIGO_UNIDAD_MOV').AsString);
      W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
        oDetalle.FieldByName('DESCRIPCION').AsString);
      W(FHoja, FFila, COL_EXCEL_CANTIDAD, dCantidad, False, ssahRight);
      if FVerCoste then
      begin
        EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dCantidad * dCoste);
        FImporteTraspasos := FImporteTraspasos + dCantidad * dCoste;
      end;
      Inc(FFila);
      oDetalle.Next;
    end;
  finally
    FreeAndNil(oDetalle);
  end;
  Inc(FNumeroTraspasos);
end;

procedure TExportadorTiraCajaExcel.VolcarIngresoGasto(
  const ATipo: string);
var
  dImporte: Currency;
begin
  dImporte := FOperacion.FieldByName(
    'IMPORTE_TOTAL_OPCAJA').AsCurrency;
  W(FHoja, FFila, COL_EXCEL_TIPO, ATipo);
  W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
  W(FHoja, FFila, COL_EXCEL_DOCUMENTO,
    'Op.' + TextoOperacion('NUMERO_OPERACION_OPCAJA'));
  W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
    Trim(TextoOperacion('CONCEPTO_GASTO_INGRESO_OPCAJA')));
  EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dImporte);
  if ATipo = 'Ingreso' then
  begin
    FImporteIngresos := FImporteIngresos + dImporte;
    Inc(FNumeroIngresos);
  end
  else
  begin
    FImporteGastos := FImporteGastos + dImporte;
    Inc(FNumeroGastos);
  end;
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.VolcarDeposito;
var
  dAnticipo, dPrecio, dTotal: Currency;
  dCantidad: Double;
  oDetalle: TUniQuery;
begin
  oDetalle := CrearConsultaDetalle(SQL_EXCEL_DEPOSITOS);
  try
    while not oDetalle.Eof do
    begin
      dPrecio := oDetalle.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
      dCantidad := oDetalle.FieldByName('CANTIDAD').AsFloat;
      dAnticipo := oDetalle.FieldByName(
        'IMPORTE_ANTICIPO_DEP').AsCurrency;
      dTotal := dPrecio * dCantidad;
      W(FHoja, FFila, COL_EXCEL_TIPO, 'Crédito (depósito)');
      W(FHoja, FFila, COL_EXCEL_FECHA, FechaOperacion);
      W(FHoja, FFila, COL_EXCEL_DOCUMENTO,
        'Op.' + TextoOperacion('NUMERO_OPERACION_OPCAJA'));
      W(FHoja, FFila, COL_EXCEL_REFERENCIA,
        Trim(oDetalle.FieldByName('CODIGO_CLI_DEP').AsString + ' ' +
          oDetalle.FieldByName('CLIENTE').AsString));
      W(FHoja, FFila, COL_EXCEL_SKU,
        oDetalle.FieldByName('CODIGO_UNIDAD_DEP').AsString);
      W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
        oDetalle.FieldByName('DESCRIPCION').AsString);
      W(FHoja, FFila, COL_EXCEL_CANTIDAD, dCantidad, False, ssahRight);
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE, dTotal);
      EscribirMoneda(FFila, COL_EXCEL_COBRADO, dAnticipo);
      EscribirMoneda(FFila, COL_EXCEL_PENDIENTE, dTotal - dAnticipo);
      FVentaDepositos := FVentaDepositos + dTotal;
      FCobroDepositos := FCobroDepositos + dAnticipo;
      Inc(FFila);
      oDetalle.Next;
    end;
  finally
    FreeAndNil(oDetalle);
  end;
  Inc(FNumeroDepositos);
end;

procedure TExportadorTiraCajaExcel.EscribirTituloGrupo(
  const AGrupo: string);
begin
  if AGrupo = 'TRA' then
    W(FHoja, FFila, COL_EXCEL_TIPO,
      'TRASPASOS SALIENTES (ORIGEN)', True)
  else if AGrupo = 'ING' then
    W(FHoja, FFila, COL_EXCEL_TIPO, 'INGRESOS POR CAJA', True)
  else if AGrupo = 'GAS' then
    W(FHoja, FFila, COL_EXCEL_TIPO, 'GASTOS POR CAJA', True)
  else if AGrupo = 'DEP' then
    W(FHoja, FFila, COL_EXCEL_TIPO,
      'VENTAS A CREDITO (DEPOSITOS)', True)
  else
    W(FHoja, FFila, COL_EXCEL_TIPO, 'VENTAS FACTURADAS', True);
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.EscribirSubtotalGrupo(
  const AGrupo: string);
begin
  if AGrupo = 'TRA' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      'SUBTOTAL TRASPASOS (coste)', True, ssahRight);
    if FVerCoste then
      EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteTraspasos);
  end
  else if AGrupo = 'ING' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      'SUBTOTAL INGRESOS', True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteIngresos);
  end
  else if AGrupo = 'GAS' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      'SUBTOTAL GASTOS', True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteGastos);
  end
  else if AGrupo = 'DEP' then
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      'SUBTOTAL DEPOSITOS', True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FVentaDepositos);
    EscribirMoneda(FFila, COL_EXCEL_COBRADO, FCobroDepositos);
  end
  else
  begin
    W(FHoja, FFila, COL_EXCEL_DESCRIPCION,
      'SUBTOTAL VENTAS', True, ssahRight);
    EscribirMoneda(FFila, COL_EXCEL_IMPORTE, FImporteVentas);
  end;
  Inc(FFila);
end;

procedure TExportadorTiraCajaExcel.VolcarFila(const AGrupo: string);
begin
  if AGrupo = 'TRA' then
    VolcarTraspaso
  else if AGrupo = 'ING' then
    VolcarIngresoGasto('Ingreso')
  else if AGrupo = 'GAS' then
    VolcarIngresoGasto('Gasto')
  else if AGrupo = 'DEP' then
    VolcarDeposito
  else
    VolcarVenta;
end;

procedure TExportadorTiraCajaExcel.ProcesarOperaciones;
var
  sGrupo, sGrupoAnterior: string;
begin
  sGrupoAnterior := '';
  FOperacion := TUniQuery.Create(nil);
  try
    FOperacion.Connection := FConexion;
    FOperacion.SQL.Text := TTiraCajaTicket.SQLOperaciones(
      FSeries, FCronologico, FIncluirTraspasos, FIncluirIngresos,
      FIncluirGastos, FIncluirCredito);
    TTiraCajaTicket.AsignarParamsOperaciones(FOperacion,
      FEmpresa, FAlmacen, FCaja, FFechaDesde, FFechaHasta, FSeries);
    FOperacion.Open;
    while not FOperacion.Eof do
    begin
      sGrupo := TextoOperacion('GRUPO');
      if (not FCronologico) and (sGrupo <> sGrupoAnterior) then
      begin
        if sGrupoAnterior <> '' then
        begin
          EscribirSubtotalGrupo(sGrupoAnterior);
          Inc(FFila);
        end;
        EscribirTituloGrupo(sGrupo);
      end;
      VolcarFila(sGrupo);
      sGrupoAnterior := sGrupo;
      FOperacion.Next;
    end;
    EscribirCierre(sGrupoAnterior);
  finally
    FreeAndNil(FOperacion);
  end;
end;

procedure TExportadorTiraCajaExcel.EscribirCierre(
  const AUltimoGrupo: string);
begin
  if (FNumeroVentas + FNumeroTraspasos + FNumeroIngresos +
      FNumeroGastos + FNumeroDepositos) = 0 then
    W(FHoja, FFila, COL_EXCEL_TIPO, 'Sin operaciones')
  else if not FCronologico then
    EscribirSubtotalGrupo(AUltimoGrupo)
  else
  begin
    Inc(FFila);
    W(FHoja, FFila, COL_EXCEL_TIPO, 'RESUMEN', True);
    Inc(FFila);
    if FNumeroVentas > 0 then
      EscribirSubtotalGrupo('VEN');
    if FNumeroTraspasos > 0 then
      EscribirSubtotalGrupo('TRA');
    if FNumeroIngresos > 0 then
      EscribirSubtotalGrupo('ING');
    if FNumeroGastos > 0 then
      EscribirSubtotalGrupo('GAS');
    if FNumeroDepositos > 0 then
      EscribirSubtotalGrupo('DEP');
  end;
end;

procedure TExportadorTiraCajaExcel.Ejecutar;
begin
  FPreview := TPreviewExcel.Crear(FPropietario);
  try
    if FPreview.HojaCalculo.SheetCount = 0 then
      FPreview.HojaCalculo.AddSheet(
        'Tira de Caja', TdxSpreadSheetTableView);
    FHoja := FPreview.HojaCalculo.ActiveSheetAsTable;
    if FHoja <> nil then
    begin
      FHoja.BeginUpdate;
      try
        EscribirCabecera;
        ProcesarOperaciones;
      finally
        FHoja.EndUpdate;
      end;
      if FPropietario is TForm then
        FPreview.AsignarPopupParent(TForm(FPropietario));
      FPreview.AsignarNombreArchivo('TiraCaja_' +
        FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now));
      FPreview.Mostrar;
    end;
  finally
    FreeAndNil(FPreview);
  end;
end;

class procedure TTiraCajaTicket.ExportarExcel(AOwner: TComponent;
  AConn: TUniConnection; const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate; const ASeries: TArray<string>;
  ACronologico: Boolean; AIncluirTraspasos: Boolean;
  AIncluirIngresos: Boolean; AIncluirGastos: Boolean;
  AIncluirCredito: Boolean; AValorarTraspasos: Boolean);
var
  oExportador: TExportadorTiraCajaExcel;
begin
  if (AConn <> nil) and AConn.Connected then
  begin
    oExportador := TExportadorTiraCajaExcel.Create(
      AOwner, AConn, AEmpresa, AAlmacen, ACaja, AFechaDesde, AFechaHasta,
      ASeries, ACronologico, AIncluirTraspasos, AIncluirIngresos,
      AIncluirGastos, AIncluirCredito, AValorarTraspasos);
    try
      oExportador.Ejecutar;
    finally
      FreeAndNil(oExportador);
    end;
  end;
end;

end.
