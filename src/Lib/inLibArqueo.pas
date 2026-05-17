{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueo                                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculo del arqueo de caja (cierre Z) en vivo para un contexto            }
{    Empresa/Almacén/Caja y un rango de fechas. Devuelve un record             }
{    TArqueoCaja con todos los importes que pinta la pantalla F11.             }
{                                                                              }
{    Las formas de pago son N (EFE, TARJ, BONO, USD, BTC, ...). El reparto     }
{    entre "efectivo" y "otros" se hace dinámicamente leyendo                  }
{    fza_caja_formas_pago.ESABRE_CAJON_FORMA_PAGO_CFP, que es la marca         }
{    canónica de "esto va al cajón físico". El detalle por forma se devuelve   }
{    en PagosPorForma para poder pintar el desglose en la pantalla.            }
{                                                                              }
{    No persiste nada; la futura implementación del F5 Recuento usará          }
{    estos cálculos como punto de partida para grabar en fza_caja_arqueos.     }
{******************************************************************************}
unit inLibArqueo;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, Uni, DBAccess;

const
  // Tipos de operación en fza_caja_operaciones.TIPO_OPERACION_OPCAJA
  TipoOpVenta         = 'VE';
  TipoOpCobroCuenta   = 'CB';
  TipoOpEntradaCambio = 'EC';
  TipoOpGastoCaja     = 'GC';
  TipoOpDeposito      = 'DE';
  TipoOpValeRedimido  = 'VR';

type
  TArqueoPagoForma = record
    Codigo      : string;     // CODIGO_FP_CFP
    Descripcion : string;     // DESCRIPCION_FORMA_PAGO_CFP
    EsEfectivo  : Boolean;    // ESABRE_CAJON_FORMA_PAGO_CFP = 'S'
    Importe     : Currency;
  end;

  TArqueoCaja = record
    // Contexto
    Empresa, Almacen, Caja : string;
    FechaDesde, FechaHasta : TDate;

    // Contadores
    CantidadVentas         : Integer;
    CantidadOperaciones    : Integer;

    // Líneas de artículos (con IVA)
    BrutoLineas            : Currency;
    DescuentosLineas       : Currency;
    NetoLineas             : Currency;

    // Operaciones (cabecera)
    BrutoOperaciones       : Currency;
    DescuentosOperaciones  : Currency;
    PuntosRecogidos        : Currency;
    Neto                   : Currency;
    VentaCredito           : Currency;

    // Cobros
    ValesRecogidos         : Currency;
    ValesEmitidos          : Currency;
    CobrosClientes         : Currency;
    PendienteCobro         : Currency;
    IngresosCaja           : Currency;

    // Efectivo / otros (data-driven a partir de fza_caja_formas_pago)
    EfectivoIngresos       : Currency;       // suma de formas con cajón
    EfectivoEntradas       : Currency;
    EfectivoSalidas        : Currency;
    EfectivoAnterior       : Currency;
    EfectivoCaja           : Currency;
    OtrosIngresos          : Currency;       // suma de formas sin cajón
    SaldoRecontar          : Currency;
    PagosPorForma          : TArray<TArqueoPagoForma>;

    // Otros
    Depositos              : Currency;
    Encargos               : Currency;
  end;

  TArqueoCalculadora = class
  private
    class procedure CalcularContadores(AConn: TUniConnection;
                                       var AArqueo: TArqueoCaja);
    class procedure CalcularLineas(AConn: TUniConnection;
                                   var AArqueo: TArqueoCaja);
    class procedure CalcularOperaciones(AConn: TUniConnection;
                                        var AArqueo: TArqueoCaja);
    class procedure CalcularVales(AConn: TUniConnection;
                                  var AArqueo: TArqueoCaja);
    class procedure CalcularPagos(AConn: TUniConnection;
                                  var AArqueo: TArqueoCaja);
    class procedure CalcularDerivados(var AArqueo: TArqueoCaja);
  public
    class function Calcular(
      AConn                  : TUniConnection;
      const AEmpresa,
            AAlmacen, ACaja  : string;
      AFechaDesde,
      AFechaHasta            : TDate): TArqueoCaja;
  end;

implementation

uses
  System.DateUtils;

// =============================================================================
//   API pública
// =============================================================================

class function TArqueoCalculadora.Calcular(
  AConn                  : TUniConnection;
  const AEmpresa,
        AAlmacen, ACaja  : string;
  AFechaDesde,
  AFechaHasta            : TDate): TArqueoCaja;
begin
  // Record que se rellena por pasos. FillChar deja PagosPorForma a nil, que es
  // el valor válido de inicialización para un dynamic array.
  FillChar(Result, SizeOf(Result), 0);
  Result.Empresa    := AEmpresa;
  Result.Almacen    := AAlmacen;
  Result.Caja       := ACaja;
  Result.FechaDesde := AFechaDesde;
  Result.FechaHasta := AFechaHasta;

  if (not Assigned(AConn)) or (not AConn.Connected) then
    Exit;
  if (Trim(AEmpresa) = '') or (Trim(AAlmacen) = '') or (Trim(ACaja) = '') then
    Exit;

  CalcularContadores(AConn, Result);
  CalcularLineas(AConn, Result);
  CalcularOperaciones(AConn, Result);
  CalcularVales(AConn, Result);
  CalcularPagos(AConn, Result);
  CalcularDerivados(Result);
end;

// =============================================================================
//   Auxiliares privados
// =============================================================================

class procedure TArqueoCalculadora.CalcularContadores(AConn: TUniConnection;
                                                     var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                              ' +
      '   COUNT(DISTINCT CASE                                               ' +
      '                    WHEN TIPO_OPERACION_OPCAJA = :pTIPO_VE           ' +
      '                    THEN NUMERO_OPERACION_OPCAJA                     ' +
      '                  END)                                  AS VENTAS,   ' +
      '   COUNT(DISTINCT NUMERO_OPERACION_OPCAJA)              AS OPERAC    ' +
      '   FROM fza_caja_operaciones                                         ' +
      '  WHERE CODIGO_EMP_OPCAJA      = :pEMPRESA                           ' +
      '    AND CODIGO_ALM_OPCAJA      = :pALMACEN                           ' +
      '    AND CODIGO_CAJA_OPCAJA     = :pCAJA                              ' +
      '    AND FECHA_OP_DIA_OPCAJA   >= :pFDESDE                            ' +
      '    AND FECHA_OP_DIA_OPCAJA   <= :pFHASTA                            ';
    Query.ParamByName('pTIPO_VE').AsString  := TipoOpVenta;
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
    begin
      AArqueo.CantidadVentas      := Query.FieldByName('VENTAS').AsInteger;
      AArqueo.CantidadOperaciones := Query.FieldByName('OPERAC').AsInteger;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

class procedure TArqueoCalculadora.CalcularLineas(AConn: TUniConnection;
                                                  var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
begin
  // Suma de las líneas de las facturas asociadas a las ventas del rango. El
  // "bruto" es el total con IVA antes del descuento de línea
  // (PRECIO_SALIDA_FACLIN x CANTIDAD_FACLIN * (1 + IVA)). El descuento es la
  // diferencia con TOTAL_FACLIN.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(SUM(l.CANTIDAD_FACLIN                                    ' +
      '              * l.PRECIO_SALIDA_FACLIN                               ' +
      '              * (1 + COALESCE(l.PORCENTAJE_IVA_FACLIN, 0) / 100)),   ' +
      '            0)                                          AS BRUTO,    ' +
      '   COALESCE(SUM(l.TOTAL_FACLIN), 0)                     AS NETO_LIN  ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '   JOIN fza_facturas_lineas  l                                       ' +
      '     ON l.CODIGO_EMP_FACLIN        = o.CODIGO_EMP_OPCAJA             ' +
      '    AND l.CODIGO_ALM_FACLIN        = o.CODIGO_ALM_OPCAJA             ' +
      '    AND l.CODIGO_CAJA_FACLIN       = o.CODIGO_CAJA_OPCAJA            ' +
      '    AND l.NUMERO_OPERACION_FACLIN  = o.NUMERO_OPERACION_OPCAJA       ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA    = :pTIPO_VE                       ' +
      '    AND o.CODIGO_EMP_OPCAJA        = :pEMPRESA                       ' +
      '    AND o.CODIGO_ALM_OPCAJA        = :pALMACEN                       ' +
      '    AND o.CODIGO_CAJA_OPCAJA       = :pCAJA                          ' +
      '    AND o.FECHA_OP_DIA_OPCAJA     >= :pFDESDE                        ' +
      '    AND o.FECHA_OP_DIA_OPCAJA     <= :pFHASTA                        ';
    Query.ParamByName('pTIPO_VE').AsString  := TipoOpVenta;
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
    begin
      AArqueo.BrutoLineas      := Query.FieldByName('BRUTO').AsCurrency;
      AArqueo.NetoLineas       := Query.FieldByName('NETO_LIN').AsCurrency;
      AArqueo.DescuentosLineas := AArqueo.BrutoLineas - AArqueo.NetoLineas;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

class procedure TArqueoCalculadora.CalcularOperaciones(AConn: TUniConnection;
                                                       var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
begin
  // Neto = importe total de las operaciones de venta. El descuento global
  // (cabecera) es la diferencia entre el neto de líneas y el neto de
  // operaciones (las operaciones ya incluyen descuento global aplicado).
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(SUM(CASE                                                 ' +
      '                  WHEN TIPO_OPERACION_OPCAJA = :pTIPO_VE             ' +
      '                  THEN IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                             ' +
      '                END), 0)                              AS NETO,       ' +
      '   COALESCE(SUM(CASE                                                 ' +
      '                  WHEN TIPO_OPERACION_OPCAJA = :pTIPO_CB             ' +
      '                  THEN IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                             ' +
      '                END), 0)                              AS COBROS,     ' +
      '   COALESCE(SUM(CASE                                                 ' +
      '                  WHEN TIPO_OPERACION_OPCAJA = :pTIPO_EC             ' +
      '                  THEN IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                             ' +
      '                END), 0)                              AS ENTRADAS,   ' +
      '   COALESCE(SUM(CASE                                                 ' +
      '                  WHEN TIPO_OPERACION_OPCAJA = :pTIPO_GC             ' +
      '                  THEN IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                             ' +
      '                END), 0)                              AS SALIDAS,    ' +
      '   COALESCE(SUM(CASE                                                 ' +
      '                  WHEN TIPO_OPERACION_OPCAJA = :pTIPO_DE             ' +
      '                  THEN IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                             ' +
      '                END), 0)                              AS DEPOSIT     ' +
      '   FROM fza_caja_operaciones                                         ' +
      '  WHERE CODIGO_EMP_OPCAJA      = :pEMPRESA                           ' +
      '    AND CODIGO_ALM_OPCAJA      = :pALMACEN                           ' +
      '    AND CODIGO_CAJA_OPCAJA     = :pCAJA                              ' +
      '    AND FECHA_OP_DIA_OPCAJA   >= :pFDESDE                            ' +
      '    AND FECHA_OP_DIA_OPCAJA   <= :pFHASTA                            ';
    Query.ParamByName('pTIPO_VE').AsString  := TipoOpVenta;
    Query.ParamByName('pTIPO_CB').AsString  := TipoOpCobroCuenta;
    Query.ParamByName('pTIPO_EC').AsString  := TipoOpEntradaCambio;
    Query.ParamByName('pTIPO_GC').AsString  := TipoOpGastoCaja;
    Query.ParamByName('pTIPO_DE').AsString  := TipoOpDeposito;
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
    begin
      AArqueo.Neto             := Query.FieldByName('NETO').AsCurrency;
      AArqueo.CobrosClientes   := Query.FieldByName('COBROS').AsCurrency;
      AArqueo.EfectivoEntradas := Query.FieldByName('ENTRADAS').AsCurrency;
      AArqueo.EfectivoSalidas  := Query.FieldByName('SALIDAS').AsCurrency;
      AArqueo.Depositos        := Query.FieldByName('DEPOSIT').AsCurrency;
    end;

    // Operaciones — bruto y descuentos:
    // BrutoOperaciones es la suma neta de líneas (lo que aparece arriba a la
    // izquierda como "Bruto" de la sección Operaciones). El descuento global
    // es la diferencia con el Neto de operaciones.
    AArqueo.BrutoOperaciones      := AArqueo.NetoLineas;
    AArqueo.DescuentosOperaciones := AArqueo.NetoLineas - AArqueo.Neto;
    if AArqueo.DescuentosOperaciones < 0 then
      AArqueo.DescuentosOperaciones := 0;
  finally
    FreeAndNil(Query);
  end;
end;

class procedure TArqueoCalculadora.CalcularVales(AConn: TUniConnection;
                                                 var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
begin
  // Vales emitidos en la caja en el rango.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT COALESCE(SUM(IMPORTE_NOMINAL_VL), 0)            AS EMITIDOS  ' +
      '   FROM fza_caja_vales                                               ' +
      '  WHERE CODIGO_EMP_EMI_VL      = :pEMPRESA                           ' +
      '    AND CODIGO_ALM_EMI_VL      = :pALMACEN                           ' +
      '    AND CODIGO_CAJA_EMI_VL     = :pCAJA                              ' +
      '    AND DATE(FECHA_EMISION_VL) >= :pFDESDE                           ' +
      '    AND DATE(FECHA_EMISION_VL) <= :pFHASTA                           ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
      AArqueo.ValesEmitidos := Query.FieldByName('EMITIDOS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;

  // Vales recogidos (redimidos) en la caja en el rango.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT COALESCE(SUM(IMPORTE_REDIMIDO_VL), 0)           AS RECOGIDOS ' +
      '   FROM fza_caja_vales                                               ' +
      '  WHERE CODIGO_EMP_RED_VL        = :pEMPRESA                         ' +
      '    AND CODIGO_ALM_RED_VL        = :pALMACEN                         ' +
      '    AND CODIGO_CAJA_RED_VL       = :pCAJA                            ' +
      '    AND DATE(FECHA_REDENCION_VL) >= :pFDESDE                         ' +
      '    AND DATE(FECHA_REDENCION_VL) <= :pFHASTA                         ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
      AArqueo.ValesRecogidos := Query.FieldByName('RECOGIDOS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;
end;

class procedure TArqueoCalculadora.CalcularPagos(AConn: TUniConnection;
                                                 var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
  Forma: TArqueoPagoForma;
  Lista: TList<TArqueoPagoForma>;
begin
  // Importes entregados por forma de pago en el rango. Agrupado por código
  // y enriquecido con descripción + flag de "abre cajón" (= efectivo) desde
  // fza_caja_formas_pago. El reparto efectivo/otros lo decide la columna
  // ESABRE_CAJON_FORMA_PAGO_CFP, no códigos hardcoded — así si mañana se da
  // de alta otra forma "tipo caja" (otra divisa en efectivo, vale interno,
  // etc.) suma sola en el cubo de efectivo.
  Lista := TList<TArqueoPagoForma>.Create;
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConn;
      Query.SQL.Text :=
        ' SELECT                                                              ' +
        '   p.CODIGO_FP_CFP                                  AS CODIGO,       ' +
        '   COALESCE(fp.DESCRIPCION_FORMA_PAGO_CFP,                           ' +
        '            p.CODIGO_FP_CFP)                        AS DESCRIPCION,  ' +
        '   COALESCE(fp.ESABRE_CAJON_FORMA_PAGO_CFP, ''N'')  AS ESCAJON,      ' +
        '   COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO), 0)       AS IMPORTE       ' +
        '   FROM fza_caja_pagos        p                                      ' +
        '   JOIN fza_caja_operaciones  o                                      ' +
        '     ON o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO                ' +
        '    AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO                ' +
        '    AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO               ' +
        '    AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO          ' +
        '   LEFT JOIN fza_caja_formas_pago fp                                 ' +
        '     ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP                           ' +
        '  WHERE p.CODIGO_EMP_PAGO      = :pEMPRESA                           ' +
        '    AND p.CODIGO_ALM_PAGO      = :pALMACEN                           ' +
        '    AND p.CODIGO_CAJA_PAGO     = :pCAJA                              ' +
        '    AND o.FECHA_OP_DIA_OPCAJA >= :pFDESDE                            ' +
        '    AND o.FECHA_OP_DIA_OPCAJA <= :pFHASTA                            ' +
        '  GROUP BY p.CODIGO_FP_CFP,                                          ' +
        '           fp.DESCRIPCION_FORMA_PAGO_CFP,                            ' +
        '           fp.ESABRE_CAJON_FORMA_PAGO_CFP                            ' +
        '  ORDER BY ESCAJON DESC, p.CODIGO_FP_CFP                             ';
      Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
      Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
      Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
      Query.ParamByName('pFDESDE').AsDate     := AArqueo.FechaDesde;
      Query.ParamByName('pFHASTA').AsDate     := AArqueo.FechaHasta;
      Query.Open;
      while not Query.Eof do
      begin
        Forma.Codigo      := Query.FieldByName('CODIGO').AsString;
        Forma.Descripcion := Query.FieldByName('DESCRIPCION').AsString;
        Forma.EsEfectivo  := Query.FieldByName('ESCAJON').AsString = 'S';
        Forma.Importe     := Query.FieldByName('IMPORTE').AsCurrency;
        Lista.Add(Forma);
        if Forma.EsEfectivo then
          AArqueo.EfectivoIngresos := AArqueo.EfectivoIngresos + Forma.Importe
        else
          AArqueo.OtrosIngresos    := AArqueo.OtrosIngresos    + Forma.Importe;
        Query.Next;
      end;
    finally
      FreeAndNil(Query);
    end;
    AArqueo.PagosPorForma := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

class procedure TArqueoCalculadora.CalcularDerivados(var AArqueo: TArqueoCaja);
begin
  // Cobros — Ingresos caja: neto operaciones − vales recogidos
  //                         + vales emitidos + cobros clientes − pendiente
  AArqueo.IngresosCaja :=
      AArqueo.Neto
    - AArqueo.ValesRecogidos
    + AArqueo.ValesEmitidos
    + AArqueo.CobrosClientes
    - AArqueo.PendienteCobro;

  // Efectivo en caja: efectivo ingresos + entradas − salidas + anterior
  AArqueo.EfectivoCaja :=
      AArqueo.EfectivoIngresos
    + AArqueo.EfectivoEntradas
    - AArqueo.EfectivoSalidas
    + AArqueo.EfectivoAnterior;

  // Saldo a recontar: efectivo en caja + ingresos por formas no-caja
  // (tarjetas, bonos, divisa, cripto...).
  AArqueo.SaldoRecontar := AArqueo.EfectivoCaja + AArqueo.OtrosIngresos;
end;

end.
