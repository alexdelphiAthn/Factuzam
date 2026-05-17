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
                             const ANombreImpresora: string = 'DEBUG');
  end;

implementation

// =============================================================================
//   Helpers de formato
// =============================================================================

class function TArqueoTicket.FmtImp(AValor: Currency): string;
begin
  Result := FormatFloat(',0.00', AValor);
end;

class function TArqueoTicket.FmtPorc(APorc: Currency): string;
begin
  Result := FormatFloat('0', APorc) + '%';
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
      '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
      '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ';
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
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                            ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                            ' +
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
begin
  if AArqueo.Neto = 0 then Exit;
  dTotal := AArqueo.Neto;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      ' SELECT                                                              ' +
      '   CASE                                                              ' +
      '     WHEN p.NOMBRE_FAM_FAM IS NOT NULL                               ' +
      '     THEN CONCAT(p.NOMBRE_FAM_FAM, ''-'', f.NOMBRE_FAM_FAM)          ' +
      '     ELSE COALESCE(f.NOMBRE_FAM_FAM, l.NOMBRE_FAM_FACLIN,            ' +
      '                   l.CODIGO_FAM_FACLIN, a.CODIGO_FAM_ART,            ' +
      '                   ''(sin familia)'')                                ' +
      '   END                                       AS FAMILIA,             ' +
      '   COUNT(*)                                  AS UDS,                 ' +
      '   COALESCE(SUM(l.TOTAL_FACLIN), 0)          AS NETO                 ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '   JOIN fza_facturas_lineas  l                                       ' +
      '     ON l.CODIGO_EMP_FACLIN        = o.CODIGO_EMP_OPCAJA             ' +
      '    AND l.CODIGO_ALM_FACLIN        = o.CODIGO_ALM_OPCAJA             ' +
      '    AND l.CODIGO_CAJA_FACLIN       = o.CODIGO_CAJA_OPCAJA            ' +
      '    AND l.NUMERO_OPERACION_FACLIN  = o.NUMERO_OPERACION_OPCAJA       ' +
      '   LEFT JOIN fza_articulos a                                         ' +
      '     ON a.CODIGO_ART_ART = l.CODIGO_ART_FACLIN                       ' +
      '   LEFT JOIN fza_articulos_familias f                                ' +
      '     ON f.CODIGO_FAM_FAM = COALESCE(l.CODIGO_FAM_FACLIN,             ' +
      '                                    a.CODIGO_FAM_ART)                ' +
      '   LEFT JOIN fza_articulos_familias p                                ' +
      '     ON p.CODIGO_FAM_FAM = f.CODIGO_SUBFAMILIA_FAM                   ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
      '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
      '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
      '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
      '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ' +
      '  GROUP BY FAMILIA                                                   ' +
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
    ATicket.EscribirLinea('RESUMEN NETO POR SECCIÓN');
    ATicket.Negrita(False);
    while not Q.Eof do
    begin
      if dTotal <> 0 then
        dPorc := (Q.FieldByName('NETO').AsCurrency / dTotal) * 100
      else
        dPorc := 0;
      ATicket.TextoColumnas(
        Q.FieldByName('FAMILIA').AsString + ' ' + FmtPorc(dPorc),
        FmtImp(Q.FieldByName('NETO').AsCurrency));
      Q.Next;
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
      '   COALESCE(o.CODIGO_EMPLEADO_OPCAJA, ''?'')   AS EMPLEADO,          ' +
      '   COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA)  AS OPS,                ' +
      '   COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0)   AS NETO                ' +
      '   FROM fza_caja_operaciones o                                       ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA   = ''VE''                           ' +
      '    AND o.CODIGO_EMP_OPCAJA       = :pEMPRESA                        ' +
      '    AND o.CODIGO_ALM_OPCAJA       = :pALMACEN                        ' +
      '    AND o.CODIGO_CAJA_OPCAJA      = :pCAJA                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA    >= :pFDESDE                         ' +
      '    AND o.FECHA_OPERACION_OPCAJA    <= :pFHASTA                         ' +
      '  GROUP BY o.CODIGO_EMPLEADO_OPCAJA                                  ' +
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
      '    AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE                            ' +
      '    AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA                            ' +
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
      '     ON f.SERIE_FAC  = o.SERIE_FAC_OPCAJA                            ' +
      '    AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA                           ' +
      '  WHERE o.TIPO_OPERACION_OPCAJA = ''VE''                             ' +
      '    AND o.CODIGO_EMP_OPCAJA     = :pEMPRESA                          ' +
      '    AND o.CODIGO_ALM_OPCAJA     = :pALMACEN                          ' +
      '    AND o.CODIGO_CAJA_OPCAJA    = :pCAJA                             ' +
      '    AND o.FECHA_OPERACION_OPCAJA  >= :pFDESDE                           ' +
      '    AND o.FECHA_OPERACION_OPCAJA  <= :pFHASTA                           ' +
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
    ATicket.EscribirLinea(Format('%-7s %9s %5s %9s %9s',
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
        Format('%-7s %9s %5s %9s %9s',
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
                                      const ANombreImpresora: string = 'DEBUG');
var
  Arqueo: TArqueoCaja;
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
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
    Ticket.EscribirLinea(Format('DÍAS %s   %s',
      [FormatDateTime('dd/mm/yy', AFechaDesde),
       FormatDateTime('dd/mm/yy', AFechaHasta)]));
    Ticket.Negrita(False);
    Ticket.SaltarLineas(1);

    // Contadores
    EscribirContadores(Ticket, AConn, Arqueo);

    // Totales
    EscribirTotales(Ticket, Arqueo);

    // Devoluciones desglosadas por forma de pago
    EscribirDevolucionesPorFP(Ticket, AConn, Arqueo);

    // Resúmenes
    EscribirResumenSeccion(Ticket, AConn, Arqueo);
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
    Preview := TFormVisualizador.Create(nil);
    try
      Preview.Hide;
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
