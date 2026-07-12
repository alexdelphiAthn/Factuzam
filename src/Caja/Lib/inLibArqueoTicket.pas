{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoTicket                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera e imprime el ticket de resumen del arqueo de caja (cierre Z).      }
{    Sigue el formato del ejemplo `src/otras pruebas/arqueos/recuento.txt`:    }
{    cabecera con empresa, contadores, líneas, operaciones, cobros, efectivo,  }
{    devoluciones y resúmenes por sección, empleado y forma de pago.           }
{                                                                              }
{    Uso:                                                                      }
{      TArqueoTicket.Imprimir(oConn, sEmp, sAlm, sCaja, dDesde, dHasta, 'P1'); }
{                                                                              }
{    Si la impresora es 'DEBUG' abre el preview (TFormVisualizador) en vez de  }
{    mandar a la impresora física.                                             }
{******************************************************************************}
unit inLibArqueoTicket;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni,
  inLibArqueo,
  inLibArqueoPersistencia,
  inLibFTicket,
  inMtoPreviewTicket,
  inLibDir;

type
  TArqueoTicket = class
  private
    class function FmtImp(AValor: Currency): string;
    class function FmtPorc(APorc: Currency): string;
    class procedure EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                            AConn: TUniConnection;
                                            const AEmpresa: string);
    class procedure EscribirContadores(ATicket: TTicketTermico;
                                       AConn: TUniConnection;
                                       const AArqueo: TArqueoCaja);
    class procedure EscribirTotales(ATicket: TTicketTermico;
                                    const AArqueo: TArqueoCaja);
    class procedure EscribirDevolucionesPorFP(ATicket: TTicketTermico;
                                              AConn: TUniConnection;
                                              const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSeccion(ATicket: TTicketTermico;
                                           AConn: TUniConnection;
                                           const AArqueo: TArqueoCaja);
    class procedure EscribirResumenTemporada(ATicket: TTicketTermico;
                                             AConn: TUniConnection;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenEmpleado(ATicket: TTicketTermico;
                                            AConn: TUniConnection;
                                            const AArqueo: TArqueoCaja);
    class procedure EscribirResumenFormaPago(ATicket: TTicketTermico;
                                             AConn: TUniConnection;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSerie(ATicket: TTicketTermico;
                                         AConn: TUniConnection;
                                         const AArqueo: TArqueoCaja);
  public
    class procedure Imprimir(AConn: TUniConnection;
                             const AEmpresa: string;
                             const AAlmacen: string;
                             const ACaja: string;
                             AFechaDesde: TDate;
                             AFechaHasta: TDate;
                             const ANombreImpresora: string = 'DEBUG';
                             ADuplicado: Boolean = False);
    class procedure ImprimirCierre(
      AConn: TUniConnection;
      const AArqueo: TArqueoCaja;
      const ALineas: TArray<TArqueoRecuentoLinea>;
      ATotalSistema: Currency;
      ATotalRecuento: Currency;
      ADiferencia: Currency;
      ARetirada: Currency;
      const AConceptoRetirada: string;
      AEfectivoDejado: Currency;
      const ADesgloseBilletes: string;
      const AObservaciones: string;
      const AVendedor: string;
      const ANombreImpresora: string = 'DEBUG';
      ADuplicado: Boolean = False);
    // Reimpresión (duplicado) del ticket de arqueo a partir de un arqueo ya
    // grabado en fza_caja_arqueos. Recalcula la tira en vivo (las operaciones
    // del rango son inmutables tras el cierre) y la marca como DUPLICADO.
    class procedure ImprimirDesdeHistorico(
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
      const ANombreImpresora: string = 'DEBUG');
    // Reimpresión (duplicado) del justificante de cierre reconstruido desde
    // fza_caja_arqueos + fza_caja_arqueos_recuento (sin recalcular nada).
    class procedure ImprimirCierreDesdeHistorico(
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
      const ANombreImpresora: string = 'DEBUG');
  end;

implementation

uses
  inLibGlobalVar, inLibCajaParam;

// =============================================================================
//   Helpers de formato
// =============================================================================

class function TArqueoTicket.FmtImp(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

class function TArqueoTicket.FmtPorc(APorc: Currency): string;
begin
  // Un decimal: el arqueo queda más legible que con porcentajes enteros.
  Result := FormatFloat('0.0', APorc) + '%';
end;

// =============================================================================
//   Cabecera de empresa y título
// =============================================================================

class procedure TArqueoTicket.EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                                     AConn: TUniConnection;
                                                     const AEmpresa: string);
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
//   Contadores: operaciones, unidades, primera/última operación
// =============================================================================

class procedure TArqueoTicket.EscribirContadores(ATicket: TTicketTermico;
                                                AConn: TUniConnection;
                                                const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(MIN(o.NUMERO_OPERACION_OPCAJA), '''')      AS PRIMERA,   ' +
      '   COALESCE(MAX(o.NUMERO_OPERACION_OPCAJA), '''')      AS ULTIMA,    ' +
      '   COALESCE(SUM(l.CANTIDAD_FACLIN), 0)                 AS UDS        ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '   LEFT JOIN fza_facturas_lineas l                                   ' +
      '     ON l.CODIGO_EMP_FACLIN        = o.CODIGO_EMP_OPCAJA             ' +
      '    AND l.CODIGO_ALM_FACLIN        = o.CODIGO_ALM_OPCAJA             ' +
      '    AND l.CODIGO_CAJA_FACLIN       = o.CODIGO_CAJA_OPCAJA            ' +
      '    AND l.NUMERO_OPERACION_FACLIN  = o.NUMERO_OPERACION_OPCAJA       ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
      '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
      '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
      '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA';
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    ATicket.Alinear(alIzquierda);
    if not Q.IsEmpty then
    begin
      ATicket.TextoColumnas('Primera operación:',
                            Q.FieldByName('PRIMERA').AsString);
      ATicket.TextoColumnas('Última operación:',
                            Q.FieldByName('ULTIMA').AsString);
    end;
    ATicket.LineaSeparadora('-');
    ATicket.TextoColumnas('OPERACIONES',
                          IntToStr(AArqueo.CantidadVentas));
    if not Q.IsEmpty then
      ATicket.TextoColumnas('UNIDADES VTA.',
                            FmtImp(Q.FieldByName('UDS').AsCurrency));
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   Bloques principales: líneas, operaciones, cobros, devoluciones
// =============================================================================

class procedure TArqueoTicket.EscribirTotales(ATicket: TTicketTermico;
                                              const AArqueo: TArqueoCaja);
begin
  ATicket.Alinear(alIzquierda);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('LÍNEAS DE ARTÍCULOS');
  ATicket.Negrita(False);
  ATicket.TextoColumnas('  BRUTO',           FmtImp(AArqueo.BrutoLineas));

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('OPERACIONES');
  ATicket.Negrita(False);
  ATicket.TextoColumnas('  Ventas Normales',  FmtImp(AArqueo.VentasNormales));
  ATicket.TextoColumnas('+ Ventas Préstamos', FmtImp(AArqueo.VentasPrestamos));
  ATicket.TextoColumnas('− Devoluciones',     FmtImp(AArqueo.Devoluciones));
  ATicket.Negrita(True);
  ATicket.TextoColumnas('= TOTAL VENTAS',     FmtImp(AArqueo.TotalVentas));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('COBROS');
  ATicket.Negrita(False);
  ATicket.TextoColumnas('  Vales recogidos',   FmtImp(AArqueo.ValesRecogidos));
  ATicket.TextoColumnas('+ Vales emitidos',    FmtImp(AArqueo.ValesEmitidos));
  ATicket.TextoColumnas('+ Cobros clientes',   FmtImp(AArqueo.CobrosClientes));
  ATicket.TextoColumnas('− Pendiente cobro',   FmtImp(AArqueo.PendienteCobro));
  ATicket.Negrita(True);
  ATicket.TextoColumnas('= Ingresos caja',     FmtImp(AArqueo.IngresosCaja));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea('EFECTIVO');
  ATicket.Negrita(False);
  ATicket.TextoColumnas('  Eftvo. ingresos',   FmtImp(AArqueo.EfectivoIngresos));
  ATicket.TextoColumnas('+ Efectivo entradas', FmtImp(AArqueo.EfectivoEntradas));
  ATicket.TextoColumnas('− Efectivo salidas',  FmtImp(AArqueo.EfectivoSalidas));
  ATicket.TextoColumnas('+ Efectivo anterior', FmtImp(AArqueo.EfectivoAnterior));
  ATicket.Negrita(True);
  ATicket.TextoColumnas('= Efectivo en caja',  FmtImp(AArqueo.EfectivoCaja));
  ATicket.Negrita(False);
  ATicket.TextoColumnas('+ Otros (tarj/...)',  FmtImp(AArqueo.OtrosIngresos));
  ATicket.Negrita(True);
  ATicket.TextoColumnas('= SALDO RECONTAR',    FmtImp(AArqueo.SaldoRecontar));
  ATicket.Negrita(False);
end;

class procedure TArqueoTicket.EscribirDevolucionesPorFP(ATicket: TTicketTermico;
                                                       AConn: TUniConnection;
                                                       const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
begin
  if AArqueo.Devoluciones = 0 then Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   p.CODIGO_FP_CFP                          AS FP,                   ' +
      '   ABS(COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO), 0)) AS IMPORTE        ' +
      '   FROM fza_caja_pagos        p                                      ' +
      '   JOIN fza_caja_operaciones  o                                      ' +
      '     ON o.CODIGO_EMP_OPCAJA       = p.CODIGO_EMP_PAGO                ' +
      '    AND o.CODIGO_ALM_OPCAJA       = p.CODIGO_ALM_PAGO                ' +
      '    AND o.CODIGO_CAJA_OPCAJA      = p.CODIGO_CAJA_PAGO               ' +
      '    AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO          ' +
      '  WHERE p.CODIGO_EMP_PAGO      = :pEMPRESA                           ' +
      '    AND p.CODIGO_ALM_PAGO      = :pALMACEN                           ' +
      '    AND p.CODIGO_CAJA_PAGO     = :pCAJA                              ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
      '    AND o.TIPO_OPERACION_OPCAJA = ''DV''                             ' +
      '  GROUP BY p.CODIGO_FP_CFP                                           ' +
      '  ORDER BY p.CODIGO_FP_CFP                                           ';
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea('DEVOLUCIONES CLIENTES');
    ATicket.Negrita(False);
    ATicket.TextoColumnas('  NETO ARTÍCULOS', FmtImp(AArqueo.Devoluciones));
    while not Q.Eof do
    begin
      ATicket.TextoColumnas('    ' + Q.FieldByName('FP').AsString,
                            FmtImp(Q.FieldByName('IMPORTE').AsCurrency));
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   Resúmenes
// =============================================================================

class procedure TArqueoTicket.EscribirResumenSeccion(ATicket: TTicketTermico;
                                                    AConn: TUniConnection;
                                                    const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
  dTotal: Currency;
  dPorc: Currency;
  sFamilia: string;
  sImporte: string;
  sPorc: string;
  iAnchoFamilia: Integer;
begin
  if AArqueo.Neto = 0 then Exit;
  dTotal := AArqueo.Neto;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    // Niveles de familia a desglosar según Parámetros de Caja.
    Q.SQL.Text := TArqueoCalculadora.SQLResumenSeccion(NivelesFamiliaArqueo);
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    if Q.IsEmpty then Exit;
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea('RESUMEN NETO POR SECCIÓN');
    ATicket.Negrita(False);
    while not Q.Eof do
    begin
      if dTotal <> 0 then
        dPorc := (Q.FieldByName('NETO').AsCurrency / dTotal) * 100
      else
        dPorc := 0;
      sFamilia := Q.FieldByName('FAMILIA').AsString;
      sPorc := FmtPorc(dPorc);
      sImporte := FmtImp(Q.FieldByName('NETO').AsCurrency);
      // Reserva un espacio antes del porcentaje y dos antes del importe.
      iAnchoFamilia := N_CHAR_LIN - Length(sPorc) - Length(sImporte) - 3;
      if Length(sFamilia) > iAnchoFamilia then
      begin
        if iAnchoFamilia > 3 then
          sFamilia := Copy(sFamilia, 1, iAnchoFamilia - 3) + '...'
        else
          sFamilia := Copy(sFamilia, 1, iAnchoFamilia);
      end;
      ATicket.TextoColumnas(sFamilia + ' ' + sPorc, sImporte);
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TArqueoTicket.EscribirResumenTemporada(
  ATicket: TTicketTermico;
  AConn: TUniConnection;
  const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := TArqueoCalculadora.SQLResumenTemporada;
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime := AArqueo.FechaHasta;
    Q.Open;
    if not Q.IsEmpty then
    begin
      ATicket.SaltarLineas(1);
      ATicket.Negrita(True);
      ATicket.EscribirLinea('RESUMEN VENTAS POR TEMPORADA');
      ATicket.Negrita(False);
      while not Q.Eof do
      begin
        ATicket.TextoColumnas(
          Format('%-20s %s uds',
                 [Copy(Q.FieldByName('TEMPORADA').AsString, 1, 20),
                  FormatFloat('0.##', Q.FieldByName('UDS').AsFloat)]),
          FmtImp(Q.FieldByName('NETO').AsCurrency));
        Q.Next;
      end;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TArqueoTicket.EscribirResumenEmpleado(ATicket: TTicketTermico;
                                                     AConn: TUniConnection;
                                                     const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   COALESCE(e.DIMINUTIVO_TICKET_EMPL,                                ' +
      '            o.CODIGO_EMPLEADO_OPCAJA, ''?'') AS EMPLEADO,            ' +
      '   COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA)  AS OPS,                ' +
      '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0)   AS NETO                ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '   LEFT JOIN fza_empleados e                                         ' +
      '     ON e.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA                     ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
      '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
      '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
      '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
      '  GROUP BY o.CODIGO_EMPLEADO_OPCAJA, e.DIMINUTIVO_TICKET_EMPL        ' +
      '  ORDER BY NETO DESC                                                 ';
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    if Q.IsEmpty then Exit;
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea('RESUMEN VENTAS POR EMPLEADO');
    ATicket.Negrita(False);
    while not Q.Eof do
    begin
      ATicket.TextoColumnas(
        Format('%-12s  %3d ops',
               [Q.FieldByName('EMPLEADO').AsString,
                Q.FieldByName('OPS').AsInteger]),
        FmtImp(Q.FieldByName('NETO').AsCurrency));
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TArqueoTicket.EscribirResumenFormaPago(ATicket: TTicketTermico;
                                                      AConn: TUniConnection;
                                                      const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   p.CODIGO_FP_CFP                                  AS FP,           ' +
      '   COALESCE(fp.DESCRIPCION_FORMA_PAGO_CFP,                           ' +
      '            p.CODIGO_FP_CFP)                        AS DESCR,        ' +
      '   COUNT(*)                                         AS UDS,          ' +
      '   COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO), 0)       AS IMP           ' +
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
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
      '  GROUP BY p.CODIGO_FP_CFP, fp.DESCRIPCION_FORMA_PAGO_CFP            ' +
      '  ORDER BY IMP DESC                                                  ';
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    if Q.IsEmpty then Exit;
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea('RESUMEN POR FORMA DE PAGO');
    ATicket.Negrita(False);
    while not Q.Eof do
    begin
      ATicket.TextoColumnas(
        Format('%-12s  %3d uds', [Q.FieldByName('DESCR').AsString,
                                  Q.FieldByName('UDS').AsInteger]),
        FmtImp(Q.FieldByName('IMP').AsCurrency));
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TArqueoTicket.EscribirResumenSerie(ATicket: TTicketTermico;
                                                  AConn: TUniConnection;
                                                  const AArqueo: TArqueoCaja);
var
  Q: TUniQuery;
  dBase, dCuota, dTotal, dPorc: Currency;
begin
  // Una fila por serie. % IVA se calcula como tipo efectivo
  // (cuota / base * 100). Si la serie mezcla varios tipos de IVA la cifra
  // del % es la media ponderada, no un tipo concreto.
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   f.SERIE_FAC                              AS SERIE,                ' +
      '   COALESCE(SUM(f.TOTAL_BASES_FAC), 0)      AS BASE,                 ' +
      '   COALESCE(SUM(f.TOTAL_IMPUESTOS_FAC), 0)  AS CUOTA,                ' +
      '   COALESCE(SUM(f.TOTAL_LIQUIDO_FAC), 0)    AS TOTAL                 ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '   JOIN fza_facturas f                                               ' +
      '     ON f.CODIGO_EMP_FAC  = o.CODIGO_EMP_OPCAJA                      ' +
      '    AND f.CODIGO_ALM_FAC  = o.CODIGO_ALM_OPCAJA                      ' +
      '    AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA                     ' +
      '    AND f.SERIE_FAC       = o.SERIE_FAC_OPCAJA                       ' +
      '    AND f.NUMERO_FAC      = o.NUMERO_FAC_OPCAJA                      ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA = ''VE''                             ' +
      '    AND o.CODIGO_EMP_OPCAJA     = :pEMPRESA                          ' +
      '    AND o.CODIGO_ALM_OPCAJA     = :pALMACEN                          ' +
      '    AND o.CODIGO_CAJA_OPCAJA    = :pCAJA                             ' +
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                          ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                          ' +
      '  GROUP BY f.SERIE_FAC                                               ' +
      '  ORDER BY f.SERIE_FAC                                               ';
    Q.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
    Q.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
    Q.ParamByName('pCAJA').AsString    := AArqueo.Caja;
    Q.ParamByName('pFDESDE').AsDateTime    := AArqueo.FechaDesde;
    Q.ParamByName('pFHASTA').AsDateTime    := AArqueo.FechaHasta;
    Q.Open;
    if Q.IsEmpty then Exit;
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea('RESUMEN VENTAS POR SERIE');
    ATicket.Negrita(False);
    // El formato debe sumar exactamente N_CHAR_LIN (42) para que la columna
    // TOTAL acabe en el margen derecho, igual que el resto del ticket. Sin
    // espacio entre SERIE y BASE: la serie va a la izquierda y el importe a
    // la derecha, así no se pegan. 7+9+1+5+1+9+1+9 = 42.
    ATicket.EscribirLinea(Format('%-7s%9s %5s %9s %9s',
                                 ['SE', 'BASE IMP', '%IVA', 'CUOTA', 'TOTAL']));
    while not Q.Eof do
    begin
      dBase  := Q.FieldByName('BASE').AsCurrency;
      dCuota := Q.FieldByName('CUOTA').AsCurrency;
      dTotal := Q.FieldByName('TOTAL').AsCurrency;
      if dBase <> 0 then
        dPorc := (dCuota / dBase) * 100
      else
        dPorc := 0;
      ATicket.EscribirLinea(
        Format('%-7s%9s %5s %9s %9s',
               [Copy(Q.FieldByName('SERIE').AsString, 1, 7),
                FmtImp(dBase),
                FormatFloat('0.00', dPorc),
                FmtImp(dCuota),
                FmtImp(dTotal)]));
      Q.Next;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

// =============================================================================
//   API pública
// =============================================================================

class procedure TArqueoTicket.Imprimir(AConn: TUniConnection;
                                      const AEmpresa: string;
                                      const AAlmacen: string;
                                      const ACaja: string;
                                      AFechaDesde: TDate;
                                      AFechaHasta: TDate;
                                      const ANombreImpresora: string = 'DEBUG';
                                      ADuplicado: Boolean = False);
var
  Arqueo: TArqueoCaja;
  Ticket: TTicketTermico;
  ComandosESC, RutaPDF: string;
begin
  if (AConn = nil) or (not AConn.Connected) then Exit;

  Arqueo := TArqueoCalculadora.Calcular(AConn, AEmpresa, AAlmacen, ACaja,
                                        AFechaDesde, AFechaHasta);

  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;

    // Cabecera de empresa
    EscribirCabeceraEmpresa(Ticket, AConn, AEmpresa);

    // Título del arqueo
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(Format('ARQUEO CAJA %s', [ACaja]));
    Ticket.EscribirLinea('PERIODO SELECCIONADO');
    Ticket.EscribirLinea(Format('DESDE %s',
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaDesde)]));
    Ticket.EscribirLinea(Format('HASTA %s',
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaHasta)]));
    Ticket.Negrita(False);
    // Marca de reimpresión: el arqueo original ya se emitió en su día
    if ADuplicado then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea('*** DUPLICADO ***');
      Ticket.Negrita(False);
    end;
    Ticket.SaltarLineas(1);

    // Contadores
    EscribirContadores(Ticket, AConn, Arqueo);

    // Totales
    EscribirTotales(Ticket, Arqueo);

    // Devoluciones desglosadas por forma de pago
    EscribirDevolucionesPorFP(Ticket, AConn, Arqueo);

    // Resúmenes
    EscribirResumenSeccion(Ticket, AConn, Arqueo);
    EscribirResumenTemporada(Ticket, AConn, Arqueo);
    EscribirResumenEmpleado(Ticket, AConn, Arqueo);
    EscribirResumenFormaPago(Ticket, AConn, Arqueo);
    EscribirResumenSerie(Ticket, AConn, Arqueo);

    // Pie
    Ticket.SaltarLineas(1);
    Ticket.LineaSeparadora('-');
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ticket.SaltarLineas(2);
    Ticket.CortarPapel;

    // Vista previa o impresión real
    ComandosESC := Ticket.ObtenerComandos;
    RutaPDF := GetUserFolderTickets + 'Arqueo_' +
               FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

// =============================================================================
//   Ticket de recuento (cierre Z grabado)
// =============================================================================

class procedure TArqueoTicket.ImprimirCierre(
  AConn: TUniConnection;
  const AArqueo: TArqueoCaja;
  const ALineas: TArray<TArqueoRecuentoLinea>;
  ATotalSistema: Currency;
  ATotalRecuento: Currency;
  ADiferencia: Currency;
  ARetirada: Currency;
  const AConceptoRetirada: string;
  AEfectivoDejado: Currency;
  const ADesgloseBilletes: string;
  const AObservaciones: string;
  const AVendedor: string;
  const ANombreImpresora: string = 'DEBUG';
  ADuplicado: Boolean = False);
var
  Ticket: TTicketTermico;
  ComandosESC, RutaPDF: string;
  i: Integer;
  slBilletes: TStringList;
  sPar, sDenom, sUds: string;
  iPos: Integer;
begin
  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;
    EscribirCabeceraEmpresa(Ticket, AConn, AArqueo.Empresa);
    { Título }
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea('CIERRE DE CAJA ' + AArqueo.Caja);
    Ticket.Negrita(False);
    // Marca de reimpresión del justificante de cierre
    if ADuplicado then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea('*** DUPLICADO ***');
      Ticket.Negrita(False);
    end;
    { Datos del cierre }
    Ticket.Alinear(alIzquierda);
    Ticket.EscribirLinea('PERIODO CERRADO');
    Ticket.TextoColumnas('Inicio:',
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AArqueo.FechaDesde));
    Ticket.TextoColumnas('Fin:',
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AArqueo.FechaHasta));
    Ticket.TextoColumnas('Ventas:',
      IntToStr(AArqueo.CantidadVentas));
    Ticket.TextoColumnas('Cierre por:',
      inLibGlobalVar.oUser);
    // Vendedor (empleado de caja) que estampa el cierre; los arqueos
    // grabados antes de exigirlo pueden venir sin él
    if AVendedor <> '' then
      Ticket.TextoColumnas('Vendedor:', AVendedor);
    Ticket.LineaSeparadora('=');
    { Desglose de billetes y monedas }
    if ADesgloseBilletes <> '' then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea('BILLETES Y MONEDAS');
      Ticket.Negrita(False);
      slBilletes := TStringList.Create;
      try
        slBilletes.Delimiter := ';';
        slBilletes.DelimitedText := ADesgloseBilletes;
        for i := 0 to slBilletes.Count - 1 do
        begin
          sPar := slBilletes[i];
          iPos := Pos(':', sPar);
          if iPos > 0 then
          begin
            sDenom := Copy(sPar, 1, iPos - 1);
            sUds   := Copy(sPar, iPos + 1, MaxInt);
            if StrToIntDef(sUds, 0) > 0 then
              Ticket.TextoColumnas(
                '  ' + sDenom + ' EUR x ' + sUds,
                FmtImp(StrToFloatDef(sDenom, 0) *
                        StrToIntDef(sUds, 0)));
          end;
        end;
      finally
        FreeAndNil(slBilletes);
      end;
      Ticket.LineaSeparadora;
    end;
    { Efectivo sistema (desglose) }
    Ticket.Negrita(True);
    Ticket.EscribirLinea('EFECTIVO SISTEMA');
    Ticket.Negrita(False);
    Ticket.TextoColumnas('  Ventas:',
      FmtImp(AArqueo.EfectivoIngresos));
    Ticket.TextoColumnas('  + Entradas:',
      FmtImp(AArqueo.EfectivoEntradas));
    Ticket.TextoColumnas('  - Gastos:',
      FmtImp(AArqueo.EfectivoSalidas));
    Ticket.TextoColumnas('  + Anterior:',
      FmtImp(AArqueo.EfectivoAnterior));
    Ticket.TextoColumnas('  = Total:',
      FmtImp(AArqueo.EfectivoCaja));
    Ticket.LineaSeparadora;
    { Detalle por forma de pago: 3 columnas alineadas a la derecha
      sobre los 42 caracteres del ticket (14+14+14) }
    Ticket.Negrita(True);
    Ticket.EscribirLinea('RECUENTO');
    Ticket.Negrita(False);
    Ticket.EscribirLinea(Format('%14s%14s%14s', ['Sist.', 'Rec.', 'Dif.']));
    for i := 0 to High(ALineas) do
    begin
      Ticket.EscribirLinea(ALineas[i].Descripcion);
      Ticket.EscribirLinea(
        Format('%14s%14s%14s',
               [FmtImp(ALineas[i].Sistema),
                FmtImp(ALineas[i].Recuento),
                FmtImp(ALineas[i].Diferencia)]));
    end;
    Ticket.LineaSeparadora('=');
    { Totales }
    Ticket.Negrita(True);
    Ticket.TextoColumnas('TOTAL SISTEMA:',
      FmtImp(ATotalSistema));
    Ticket.TextoColumnas('TOTAL RECONTADO:',
      FmtImp(ATotalRecuento));
    Ticket.TextoColumnas('DIFERENCIA:',
      FmtImp(ADiferencia));
    Ticket.Negrita(False);
    Ticket.LineaSeparadora;
    { Retirada }
    if ARetirada > 0 then
    begin
      Ticket.TextoColumnas('RETIRADA:',
        FmtImp(ARetirada));
      Ticket.TextoColumnas('  Destino:',
        AConceptoRetirada);
    end;
    { Dejo para mañana }
    Ticket.Negrita(True);
    Ticket.TextoColumnas('DEJO EN CAJA:',
      FmtImp(AEfectivoDejado));
    Ticket.Negrita(False);
    { Observaciones }
    if AObservaciones <> '' then
    begin
      Ticket.LineaSeparadora;
      Ticket.EscribirLinea('Obs: ' + AObservaciones);
    end;
    { Pie }
    Ticket.LineaSeparadora;
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(
      FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ticket.EscribirLinea('Firma:');
    Ticket.SaltarLineas(2);
    Ticket.LineaSeparadora('.');
    Ticket.SaltarLineas(1);
    Ticket.CortarPapel;
    { Imprimir o previsualizar }
    ComandosESC := Ticket.ObtenerComandos;
    RutaPDF := GetUserFolderTickets + 'Recuento_' +
               FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

// =============================================================================
//   Reimpresión de duplicados desde el histórico (fza_caja_arqueos)
// =============================================================================

class procedure TArqueoTicket.ImprimirDesdeHistorico(
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  Q: TUniQuery;
  sEmp, sAlm, sCaja: string;
  dDesde, dHasta: TDate;
  bOk: Boolean;
begin
  if (AConn = nil) or (not AConn.Connected) then Exit;
  bOk    := False;
  dDesde := 0;
  dHasta := 0;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT CODIGO_EMP_ARQ, CODIGO_ALM_ARQ, CODIGO_CAJA_ARQ,             ' +
      '        FECHA_DESDE_ARQ, FECHA_HASTA_ARQ                             ' +
      '   FROM fza_caja_arqueos                                            ' +
      '  WHERE CODIGO_ARQ      = :pARQ                                      ' +
      '    AND CODIGO_EMP_ARQ  = :pEMP                                      ' +
      '    AND CODIGO_ALM_ARQ  = :pALM                                      ' +
      '    AND CODIGO_CAJA_ARQ = :pCAJA                                     ';
    Q.ParamByName('pARQ').AsString := ACodigoArqueo;
    Q.ParamByName('pEMP').AsString := AEmpresa;
    Q.ParamByName('pALM').AsString := AAlmacen;
    Q.ParamByName('pCAJA').AsString := ACaja;
    Q.Open;
    if not Q.IsEmpty then
    begin
      sEmp   := Q.FieldByName('CODIGO_EMP_ARQ').AsString;
      sAlm   := Q.FieldByName('CODIGO_ALM_ARQ').AsString;
      sCaja  := Q.FieldByName('CODIGO_CAJA_ARQ').AsString;
      dDesde := Q.FieldByName('FECHA_DESDE_ARQ').AsDateTime;
      dHasta := Q.FieldByName('FECHA_HASTA_ARQ').AsDateTime;
      bOk    := True;
    end;
  finally
    FreeAndNil(Q);
  end;
  // Los cierres antiguos guardaban fechas sin hora. Se mantienen como dia
  // completo; los nuevos cierres por horas conservan su datetime exacto.
  if bOk then
  begin
    if (Frac(dDesde) = 0) and (Frac(dHasta) = 0) then
      dHasta := dHasta + EncodeTime(23, 59, 59, 0);
    Imprimir(AConn, sEmp, sAlm, sCaja,
             dDesde, dHasta,
             ANombreImpresora, True);
  end;
end;

class procedure TArqueoTicket.ImprimirCierreDesdeHistorico(
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  Q: TUniQuery;
  Arqueo: TArqueoCaja;
  Lineas: TArray<TArqueoRecuentoLinea>;
  dTotalSistema, dTotalRecuento, dDiferencia: Currency;
  dRetirada, dEfectivoDejado: Currency;
  sConcepto, sDesglose, sObs: string;
  sVendedor, sNombreVendedor: string;
  bOk: Boolean;
begin
  if (AConn = nil) or (not AConn.Connected) then Exit;
  bOk := False;
  dTotalSistema   := 0;
  dTotalRecuento  := 0;
  dDiferencia     := 0;
  dRetirada       := 0;
  dEfectivoDejado := 0;
  // Cabecera del arqueo: solo se rellenan los campos que usa ImprimirCierre.
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT a.*,                                                       ' +
      '        COALESCE(e.NOMBRE_EMPL, e.DIMINUTIVO_TICKET_EMPL,          ' +
      '                 '''') AS NOMBRE_VENDEDOR                          ' +
      '   FROM fza_caja_arqueos a                                         ' +
      '   LEFT JOIN fza_empleados e                                       ' +
      '     ON e.CODIGO_EMPL = a.CODIGO_EMPLEADO_ARQ                      ' +
      '  WHERE a.CODIGO_ARQ      = :pARQ                                  ' +
      '    AND a.CODIGO_EMP_ARQ  = :pEMP                                  ' +
      '    AND a.CODIGO_ALM_ARQ  = :pALM                                  ' +
      '    AND a.CODIGO_CAJA_ARQ = :pCAJA                                 ';
    Q.ParamByName('pARQ').AsString := ACodigoArqueo;
    Q.ParamByName('pEMP').AsString := AEmpresa;
    Q.ParamByName('pALM').AsString := AAlmacen;
    Q.ParamByName('pCAJA').AsString := ACaja;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Arqueo.Empresa        := Q.FieldByName('CODIGO_EMP_ARQ').AsString;
      Arqueo.Almacen        := Q.FieldByName('CODIGO_ALM_ARQ').AsString;
      Arqueo.Caja           := Q.FieldByName('CODIGO_CAJA_ARQ').AsString;
      Arqueo.FechaDesde     := Q.FieldByName('FECHA_DESDE_ARQ').AsDateTime;
      Arqueo.FechaHasta     := Q.FieldByName('FECHA_HASTA_ARQ').AsDateTime;
      Arqueo.CantidadVentas := Q.FieldByName('CANTIDAD_VENTAS_ARQ').AsInteger;
      Arqueo.EfectivoIngresos :=
        Q.FieldByName('TOTAL_EFECTIVO_INGRESOS_ARQ').AsCurrency;
      Arqueo.EfectivoEntradas :=
        Q.FieldByName('TOTAL_EFECTIVO_ENTRADAS_ARQ').AsCurrency;
      Arqueo.EfectivoSalidas  :=
        Q.FieldByName('TOTAL_EFECTIVO_SALIDAS_ARQ').AsCurrency;
      Arqueo.EfectivoAnterior :=
        Q.FieldByName('TOTAL_EFECTIVO_ANTERIOR_ARQ').AsCurrency;
      Arqueo.EfectivoCaja     :=
        Q.FieldByName('TOTAL_EFECTIVO_CAJA_ARQ').AsCurrency;
      sObs := Q.FieldByName('OBSERVACIONES_ARQ').AsString;
      // Vendedor estampado al cerrar; arqueos antiguos pueden no llevarlo
      sVendedor       := Trim(Q.FieldByName('CODIGO_EMPLEADO_ARQ').AsString);
      sNombreVendedor := Trim(Q.FieldByName('NOMBRE_VENDEDOR').AsString);
      if (sVendedor <> '') and (sNombreVendedor <> '') then
        sVendedor := sVendedor + ' - ' + sNombreVendedor;
      // Columnas añadidas por arqueo_recuento.sql: leer contra FindField por
      // si la BBDD todavía no tiene la migración del cierre Z aplicada.
      if Q.FindField('TOTAL_RECUENTO_ARQ') <> nil then
        dTotalRecuento := Q.FieldByName('TOTAL_RECUENTO_ARQ').AsCurrency;
      if Q.FindField('DIFERENCIA_TOTAL_ARQ') <> nil then
        dDiferencia := Q.FieldByName('DIFERENCIA_TOTAL_ARQ').AsCurrency;
      dTotalSistema := dTotalRecuento - dDiferencia;
      if Q.FindField('IMPORTE_RETIRADA_ARQ') <> nil then
        dRetirada := Q.FieldByName('IMPORTE_RETIRADA_ARQ').AsCurrency;
      if Q.FindField('CONCEPTO_RETIRADA_ARQ') <> nil then
        sConcepto := Q.FieldByName('CONCEPTO_RETIRADA_ARQ').AsString;
      if Q.FindField('EFECTIVO_DEJADO_CAJA_ARQ') <> nil then
        dEfectivoDejado := Q.FieldByName('EFECTIVO_DEJADO_CAJA_ARQ').AsCurrency;
      if Q.FindField('DESGLOSE_BILLETES_ARQ') <> nil then
        sDesglose := Q.FieldByName('DESGLOSE_BILLETES_ARQ').AsString;
      if (Frac(Arqueo.FechaDesde) = 0) and
         (Frac(Arqueo.FechaHasta) = 0) then
        Arqueo.FechaHasta :=
          Arqueo.FechaHasta + EncodeTime(23, 59, 59, 0);
      bOk := True;
    end;
  finally
    FreeAndNil(Q);
  end;
  if bOk then
  begin
    // Detalle por forma de pago grabado en el cierre.
    Q := TUniQuery.Create(nil);
    try
      Q.Connection := AConn;
      Q.SQL.Text :=
        ' SELECT CODIGO_FP_CFP_ARQR, DESCRIPCION_FP_ARQR, ESCAJON_ARQR,     ' +
        '        IMPORTE_SISTEMA_ARQR, IMPORTE_RECUENTO_ARQR, DIFERENCIA_ARQR' +
        '   FROM fza_caja_arqueos_recuento                                  ' +
        '  WHERE CODIGO_ARQ_ARQR = :pARQ                                    ' +
        '  ORDER BY ESCAJON_ARQR DESC, CODIGO_FP_CFP_ARQR                   ';
      Q.ParamByName('pARQ').AsString := ACodigoArqueo;
      Q.Open;
      while not Q.Eof do
      begin
        SetLength(Lineas, Length(Lineas) + 1);
        Lineas[High(Lineas)].CodigoFP    :=
          Q.FieldByName('CODIGO_FP_CFP_ARQR').AsString;
        Lineas[High(Lineas)].Descripcion :=
          Q.FieldByName('DESCRIPCION_FP_ARQR').AsString;
        Lineas[High(Lineas)].EsCajon     :=
          Q.FieldByName('ESCAJON_ARQR').AsString;
        Lineas[High(Lineas)].Sistema     :=
          Q.FieldByName('IMPORTE_SISTEMA_ARQR').AsCurrency;
        Lineas[High(Lineas)].Recuento    :=
          Q.FieldByName('IMPORTE_RECUENTO_ARQR').AsCurrency;
        Lineas[High(Lineas)].Diferencia  :=
          Q.FieldByName('DIFERENCIA_ARQR').AsCurrency;
        Q.Next;
      end;
    finally
      FreeAndNil(Q);
    end;
    ImprimirCierre(AConn, Arqueo, Lineas,
                   dTotalSistema, dTotalRecuento, dDiferencia,
                   dRetirada, sConcepto, dEfectivoDejado,
                   sDesglose, sObs, sVendedor, ANombreImpresora, True);
  end;
end;

end.
