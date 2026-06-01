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
  TipoOpDevolucion    = 'DV';
  TipoOpCobroCuenta   = 'CB';
  TipoOpEntradaCambio = 'EC';
  TipoOpGastoCaja     = 'GC';
  TipoOpDeposito      = 'DE';
  TipoOpValeRedimido  = 'VR';

  // Estado de depósito (fza_depositos_cliente.ESTADO_DEP)
  EstadoDepositoAbierto = 'PENDIENTE';

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
    Neto                   : Currency;       // total de VE en el rango (signed)
    Prestamos              : Currency;       // SUM TIPO='DE' (depósitos)
    Devoluciones           : Currency;       // ABS de VE < 0 (devoluc. de venta)
    VentasNormales         : Currency;       // VE > 0 sin DE en la misma op
    VentasPrestamos        : Currency;       // = Prestamos - CobrosClientes
    TotalVentas            : Currency;       // = VN + VP - Devoluciones

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
  end;

  TArqueoCalculadora = class
  private
    class procedure CalcularContadores(AConn: TUniConnection;
                                       var AArqueo: TArqueoCaja);
    class procedure CalcularLineas(AConn: TUniConnection;
                                   var AArqueo: TArqueoCaja);
    class procedure CalcularOperaciones(AConn: TUniConnection;
                                        var AArqueo: TArqueoCaja);
    class procedure CalcularDepositos(AConn: TUniConnection;
                                      var AArqueo: TArqueoCaja);
    class procedure CalcularVales(AConn: TUniConnection;
                                  var AArqueo: TArqueoCaja);
    class procedure CalcularPagos(AConn: TUniConnection;
                                  var AArqueo: TArqueoCaja);
    class procedure CalcularEfectivoAnterior(AConn: TUniConnection;
                                              var AArqueo: TArqueoCaja);
    class procedure CalcularDerivados(var AArqueo: TArqueoCaja);
  public
    class function Calcular(AConn          : TUniConnection;
                            const AEmpresa : string;
                            const AAlmacen : string;
                            const ACaja    : string;
                            AFechaDesde    : TDate;
                            AFechaHasta    : TDate): TArqueoCaja;
  end;

implementation

uses
  System.DateUtils;

// =============================================================================
//   API pública
// =============================================================================

class function TArqueoCalculadora.Calcular(AConn          : TUniConnection;
                                           const AEmpresa : string;
                                           const AAlmacen : string;
                                           const ACaja    : string;
                                           AFechaDesde    : TDate;
                                           AFechaHasta    : TDate): TArqueoCaja;
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
  CalcularDepositos(AConn, Result);
  CalcularVales(AConn, Result);
  CalcularPagos(AConn, Result);
  CalcularEfectivoAnterior(AConn, Result);
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
      '    AND FECHA_OPERACION_OPCAJA   >= :pFDESDE                            ' +
      '    AND FECHA_OPERACION_OPCAJA   <= :pFHASTA                            ';
    Query.ParamByName('pTIPO_VE').AsString  := TipoOpVenta;
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
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
      '    AND o.FECHA_OPERACION_OPCAJA     >= :pFDESDE                        ' +
      '    AND o.FECHA_OPERACION_OPCAJA     <= :pFHASTA                        ';
    Query.ParamByName('pTIPO_VE').AsString  := TipoOpVenta;
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
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
  // Esquema de cálculo:
  //   - Neto              = SUM IMPORTE_TOTAL_OPCAJA WHERE TIPO='VE' (signed,
  //                         se mantiene como cifra interna).
  //   - VentasNormales    = VE > 0 sin DE en la misma operación.
  //   - Devoluciones      = ABS(SUM TIPO='DV')  ← canónico, no VE < 0.
  //
  // Préstamos y CobrosClientes NO se calculan aquí: se sacan en
  // CalcularDepositos directamente de fza_depositos_cliente, que tiene
  // el saldo correcto (PRECIO_VENTA_DEP × CANTIDAD para el valor de la
  // mercancía, IMPORTE_ANTICIPO_DEP para lo ya cobrado).
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                                ' +
      '   COALESCE(SUM(CASE                                                   ' +
      '                  WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_VE             ' +
      '                  THEN o.IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                               ' +
      '                END), 0)                              AS NETO,         ' +
      '   COALESCE(SUM(CASE                                                   ' +
      '                  WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_VE             ' +
      '                   AND o.IMPORTE_TOTAL_OPCAJA > 0                      ' +
      '                   AND NOT EXISTS                                      ' +
      '                       (SELECT 1 FROM fza_caja_operaciones o2          ' +
      '                         WHERE o2.CODIGO_EMP_OPCAJA                    ' +
      '                                  = o.CODIGO_EMP_OPCAJA                ' +
      '                           AND o2.CODIGO_ALM_OPCAJA                    ' +
      '                                  = o.CODIGO_ALM_OPCAJA                ' +
      '                           AND o2.CODIGO_CAJA_OPCAJA                   ' +
      '                                  = o.CODIGO_CAJA_OPCAJA               ' +
      '                           AND o2.NUMERO_OPERACION_OPCAJA              ' +
      '                                  = o.NUMERO_OPERACION_OPCAJA          ' +
      '                           AND o2.TIPO_OPERACION_OPCAJA                ' +
      '                                  = :pTIPO_DE)                         ' +
      '                  THEN o.IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                               ' +
      '                END), 0)                              AS V_NORMALES,   ' +
      '   ABS(COALESCE(SUM(CASE                                               ' +
      '                  WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_DV             ' +
      '                  THEN o.IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                               ' +
      '                END), 0))                             AS V_DEVOL,      ' +
      '   COALESCE(SUM(CASE                                                   ' +
      '                  WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_EC             ' +
      '                  THEN o.IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                               ' +
      '                END), 0)                              AS ENTRADAS,     ' +
      '   COALESCE(SUM(CASE                                                   ' +
      '                  WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_GC             ' +
      '                  THEN o.IMPORTE_TOTAL_OPCAJA                          ' +
      '                  ELSE 0                                               ' +
      '                END), 0)                              AS SALIDAS       ' +
      '   FROM fza_caja_operaciones o                                         ' +
      '  WHERE o.CODIGO_EMP_OPCAJA      = :pEMPRESA                           ' +
      '    AND o.CODIGO_ALM_OPCAJA      = :pALMACEN                           ' +
      '    AND o.CODIGO_CAJA_OPCAJA     = :pCAJA                              ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                           ';
    Query.ParamByName('pTIPO_VE').AsString      := TipoOpVenta;
    Query.ParamByName('pTIPO_DV').AsString      := TipoOpDevolucion;
    Query.ParamByName('pTIPO_EC').AsString      := TipoOpEntradaCambio;
    Query.ParamByName('pTIPO_GC').AsString      := TipoOpGastoCaja;
    Query.ParamByName('pTIPO_DE').AsString      := TipoOpDeposito;
    Query.ParamByName('pEMPRESA').AsString      := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString      := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString         := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
    begin
      AArqueo.Neto             := Query.FieldByName('NETO').AsCurrency;
      AArqueo.VentasNormales   := Query.FieldByName('V_NORMALES').AsCurrency;
      AArqueo.Devoluciones     := Query.FieldByName('V_DEVOL').AsCurrency;
      AArqueo.EfectivoEntradas := Query.FieldByName('ENTRADAS').AsCurrency;
      AArqueo.EfectivoSalidas  := Query.FieldByName('SALIDAS').AsCurrency;
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

class procedure TArqueoCalculadora.CalcularDepositos(AConn: TUniConnection;
                                                    var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
begin
  // Métricas de depósitos basadas en el PERÍODO (no snapshot actual),
  // para que un arqueo de una temporada pasada siga siendo correcto
  // aunque los depósitos de entonces estén cerrados hoy:
  //
  //   - Préstamos      = SUM(PRECIO_VENTA_DEP × CANTIDAD_PENDIENTE_DEP)
  //                      de los depósitos cuya FECHA_CREACION_DEP cae
  //                      en el rango. Da el valor de la mercancía
  //                      comprometida en el período (independiente del
  //                      ESTADO_DEP actual).
  //
  //   - CobrosClientes = SUM(IMPORTE_TOTAL_OPCAJA) de las operaciones
  //                      CB+ y DE+ ligadas a un depósito
  //                      (ID_DEPOSITO_OPCAJA no nulo) que ocurrieron en
  //                      el rango. Es el flujo real de efectivo entrado
  //                      como anticipo durante el período, igual de
  //                      válido para arqueos pasados o actuales.

  // 1) Préstamos: valor de los depósitos creados en el período.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(SUM(d.PRECIO_VENTA_DEP                                   ' +
      '              * COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1)), 0)           ' +
      '                                              AS PRESTAMOS           ' +
      '   FROM fza_depositos_cliente d                                      ' +
      '  WHERE d.CODIGO_EMP_DEP        = :pEMPRESA                          ' +
      '    AND d.CODIGO_ALM_DEP        = :pALMACEN                          ' +
      '    AND d.CODIGO_CAJA_DEP       = :pCAJA                             ' +
      '    AND d.FECHA_CREACION_DEP   >= :pFDESDE                           ' +
      '    AND d.FECHA_CREACION_DEP   <= :pFHASTA                           ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime := AArqueo.FechaHasta;
    Query.Open;
    if not Query.Eof then
      AArqueo.Prestamos := Query.FieldByName('PRESTAMOS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;

  // 2) Cobros clientes: anticipos cobrados (CB+ y DE+ ligados a depósito)
  //    en el período.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0)   AS COBROS              ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '  WHERE o.CODIGO_EMP_OPCAJA      = :pEMPRESA                         ' +
      '    AND o.CODIGO_ALM_OPCAJA      = :pALMACEN                         ' +
      '    AND o.CODIGO_CAJA_OPCAJA     = :pCAJA                            ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                         ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                         ' +
      '    AND o.TIPO_OPERACION_OPCAJA IN (:pTIPO_CB, :pTIPO_DE)             ' +
      '    AND o.IMPORTE_TOTAL_OPCAJA  > 0                                  ' +
      '    AND o.ID_DEPOSITO_OPCAJA   IS NOT NULL                           ' +
      '    AND o.ID_DEPOSITO_OPCAJA  <> ''''                                ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime := AArqueo.FechaHasta;
    Query.ParamByName('pTIPO_CB').AsString  := TipoOpCobroCuenta;
    Query.ParamByName('pTIPO_DE').AsString  := TipoOpDeposito;
    Query.Open;
    if not Query.Eof then
      AArqueo.CobrosClientes := Query.FieldByName('COBROS').AsCurrency;
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
      '    AND FECHA_EMISION_VL       >= :pFDESDE                           ' +
      '    AND FECHA_EMISION_VL       <  DATE_ADD(:pFHASTA, INTERVAL 1 DAY) ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
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
      '    AND FECHA_REDENCION_VL       >= :pFDESDE                         ' +
      '    AND FECHA_REDENCION_VL       <  DATE_ADD(:pFHASTA, INTERVAL 1 DAY) ';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
    Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
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
      // Partimos de TODAS las formas de pago activas y LEFT JOIN a los
      // pagos del periodo. Asi las que no tuvieron movimiento aparecen
      // con importe 0 y el usuario puede rellenar el recuento.
      Query.SQL.Text :=
        ' SELECT                                                              ' +
        '   fp.CODIGO_FP_CFP                              AS CODIGO,          ' +
        '   fp.DESCRIPCION_FORMA_PAGO_CFP                 AS DESCRIPCION,     ' +
        '   fp.ESABRE_CAJON_FORMA_PAGO_CFP                AS ESCAJON,         ' +
        '   COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO), 0)    AS IMPORTE          ' +
        '   FROM fza_caja_formas_pago fp                                      ' +
        '   LEFT JOIN fza_caja_pagos p                                        ' +
        '     ON p.CODIGO_FP_CFP = fp.CODIGO_FP_CFP                           ' +
        '    AND p.CODIGO_EMP_PAGO  = :pEMPRESA                               ' +
        '    AND p.CODIGO_ALM_PAGO  = :pALMACEN                               ' +
        '    AND p.CODIGO_CAJA_PAGO = :pCAJA                                  ' +
        '   LEFT JOIN fza_caja_operaciones o                                  ' +
        '     ON o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO                ' +
        '    AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO                ' +
        '    AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO               ' +
        '    AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO          ' +
        '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                         ' +
        '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                         ' +
        '  WHERE fp.ESACTIVO_FORMA_PAGO_CFP = ''S''                            ' +
        '  GROUP BY fp.CODIGO_FP_CFP,                                         ' +
        '           fp.DESCRIPCION_FORMA_PAGO_CFP,                            ' +
        '           fp.ESABRE_CAJON_FORMA_PAGO_CFP                            ' +
        '  ORDER BY ESCAJON DESC, fp.CODIGO_FP_CFP                            ';
      Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
      Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
      Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
      Query.ParamByName('pFDESDE').AsDateTime     := AArqueo.FechaDesde;
      Query.ParamByName('pFHASTA').AsDateTime     := AArqueo.FechaHasta;
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

class procedure TArqueoCalculadora.CalcularEfectivoAnterior(
  AConn: TUniConnection; var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
  bExiste: Boolean;
begin
  { Comprobar primero si la columna existe (migración pendiente). El
    evento OnError de la conexión UniDAC propaga la excepción antes
    de que un except local la capture, así que hay que evitar el
    SELECT sobre una columna inexistente. }
  bExiste := False;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      'SELECT COUNT(*) AS N' +
      '  FROM INFORMATION_SCHEMA.COLUMNS' +
      ' WHERE TABLE_SCHEMA = DATABASE()' +
      '   AND TABLE_NAME   = ''fza_caja_arqueos''' +
      '   AND COLUMN_NAME  = ''EFECTIVO_DEJADO_CAJA_ARQ''';
    Query.Open;
    bExiste := (not Query.Eof)
               and (Query.FieldByName('N').AsInteger > 0);
  finally
    FreeAndNil(Query);
  end;
  if not bExiste then
    Exit;
  { La columna existe: buscar el último arqueo CERRADO de la misma
    caja anterior a este rango. }
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      'SELECT EFECTIVO_DEJADO_CAJA_ARQ' +
      '  FROM fza_caja_arqueos' +
      ' WHERE CODIGO_EMP_ARQ  = :pEMPRESA' +
      '   AND CODIGO_ALM_ARQ  = :pALMACEN' +
      '   AND CODIGO_CAJA_ARQ = :pCAJA' +
      '   AND FASE_ARQ        = ''CERRADO''' +
      '   AND FECHA_HASTA_ARQ < :pFDESDE' +
      ' ORDER BY FECHA_HASTA_ARQ DESC' +
      ' LIMIT 1';
    Query.ParamByName('pEMPRESA').AsString  := AArqueo.Empresa;
    Query.ParamByName('pALMACEN').AsString  := AArqueo.Almacen;
    Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
    Query.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
    Query.Open;
    if not Query.Eof then
      AArqueo.EfectivoAnterior :=
        Query.FieldByName('EFECTIVO_DEJADO_CAJA_ARQ').AsCurrency;
  finally
    FreeAndNil(Query);
  end;
end;

class procedure TArqueoCalculadora.CalcularDerivados(var AArqueo: TArqueoCaja);
begin
  // Ventas a préstamo = valor de la mercancía comprometida en el período
  // (no el pendiente). Si el cliente ha entregado anticipos, esa parte
  // ya está cobrada pero la venta "comprometida" sigue siendo el total.
  AArqueo.VentasPrestamos := AArqueo.Prestamos;

  // Pendiente de cobro = lo que el cliente aún debe entregar para retirar
  // la mercancía = Préstamos − Cobros clientes.
  AArqueo.PendienteCobro := AArqueo.Prestamos - AArqueo.CobrosClientes;

  // Total Ventas = ventas normales + ventas a préstamo − devoluciones.
  AArqueo.TotalVentas :=
      AArqueo.VentasNormales
    + AArqueo.VentasPrestamos
    - AArqueo.Devoluciones;

  // Efectivo en caja: efectivo ingresos + entradas − salidas + anterior
  AArqueo.EfectivoCaja :=
      AArqueo.EfectivoIngresos
    + AArqueo.EfectivoEntradas
    - AArqueo.EfectivoSalidas
    + AArqueo.EfectivoAnterior;

  // Saldo a recontar: efectivo en caja + ingresos por formas no-caja
  // (tarjetas, bonos, divisa, cripto...).
  AArqueo.SaldoRecontar := AArqueo.EfectivoCaja + AArqueo.OtrosIngresos;

  // Ingresos caja: en este primer paso lo unificamos con SaldoRecontar
  // (fix C). La fórmula teórica "Neto − Prestamos − VR + VE + CC − Pendiente"
  // arrastra los desajustes del flujo de caja real (consumos de anticipo,
  // tipos DV vs VE…) y daba cifras irreales. La suma directa de los pagos
  // entregados (fza_caja_pagos) es la única cifra fiable hasta que se
  // implemente el cuadre cruzado con F5 Recuento.
  AArqueo.IngresosCaja := AArqueo.SaldoRecontar;
end;

end.
