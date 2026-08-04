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
{    Recibe contratos de cálculo y lectura; no accede directamente a BBDD.    }
{                                                                              }
{    Si la impresora es 'DEBUG' abre el preview (TFormVisualizador) en vez de  }
{    mandar a la impresora física.                                             }
{******************************************************************************}
unit inLibArqueoTicket;

interface

uses
  System.SysUtils, System.Classes,
  inLibArqueoIntf,
  inLibArqueoTicketIntf,
  inLibArqueoPersistencia,
  inLibFTicket,
  inLibPreviewTicket,
  inLibDir,
  inLibContextoSesionIntf,
  inLibParametrosIntf,
  inLibMsgTickets;

type
  TArqueoTicket = class
  private
    class function FmtImp(AValor: Currency): string;
    class function FmtPorc(APorc: Currency): string;
    class procedure EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioArqueoTicket;
                                            const AEmpresa: string);
    class procedure EscribirContadores(ATicket: TTicketTermico;
                                       const ARepositorio:
                                       IRepositorioArqueoTicket;
                                       const AArqueo: TArqueoCaja);
    class procedure EscribirTotales(ATicket: TTicketTermico;
                                    const AArqueo: TArqueoCaja);
    class procedure EscribirDevolucionesPorFP(ATicket: TTicketTermico;
                                              const ARepositorio:
                                              IRepositorioArqueoTicket;
                                              const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSeccion(ATicket: TTicketTermico;
                                           const ARepositorio:
                                           IRepositorioArqueoTicket;
                                           const AParametrosCaja:
                                           IParametrosCaja;
                                           const AArqueo: TArqueoCaja);
    class procedure EscribirResumenTemporada(ATicket: TTicketTermico;
                                             const ARepositorio:
                                             IRepositorioArqueoTicket;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenEmpleado(ATicket: TTicketTermico;
                                            const ARepositorio:
                                            IRepositorioArqueoTicket;
                                            const AArqueo: TArqueoCaja);
    class procedure EscribirResumenFormaPago(ATicket: TTicketTermico;
                                             const ARepositorio:
                                             IRepositorioArqueoTicket;
                                             const AArqueo: TArqueoCaja);
    class procedure EscribirResumenSerie(ATicket: TTicketTermico;
                                         const ARepositorio:
                                         IRepositorioArqueoTicket;
                                         const AArqueo: TArqueoCaja);
  public
    class procedure Imprimir(const APreview: IPreviewTicket;
                             const ARepositorioArqueo:
                             IRepositorioArqueoCaja;
                             const ARepositorioTicket:
                             IRepositorioArqueoTicket;
                             const AParametrosCaja: IParametrosCaja;
                             const AEmpresa: string;
                             const AAlmacen: string;
                             const ACaja: string;
                             AFechaDesde: TDate;
                             AFechaHasta: TDate;
                             const ANombreImpresora: string = 'DEBUG';
                             ADuplicado: Boolean = False);
    class procedure ImprimirCierre(
      const APreview: IPreviewTicket;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AContextoSesion: IContextoSesionAplicacion;
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
      const APreview: IPreviewTicket;
      const ARepositorioArqueo: IRepositorioArqueoCaja;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AParametrosCaja: IParametrosCaja;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
      const ANombreImpresora: string = 'DEBUG');
    // Reimpresión (duplicado) del justificante de cierre reconstruido desde
    // fza_caja_arqueos + fza_caja_arqueos_recuento (sin recalcular nada).
    class procedure ImprimirCierreDesdeHistorico(
      const APreview: IPreviewTicket;
      const ARepositorioTicket: IRepositorioArqueoTicket;
      const AContextoSesion: IContextoSesionAplicacion;
      const AEmpresa, AAlmacen, ACaja: string;
      const ACodigoArqueo: string;
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
  // Un decimal: el arqueo queda más legible que con porcentajes enteros.
  Result := FormatFloat('0.0', APorc) + '%';
end;

// =============================================================================
//   Cabecera de empresa y título
// =============================================================================

class procedure TArqueoTicket.EscribirCabeceraEmpresa(ATicket: TTicketTermico;
                                                     const ARepositorio:
                                                     IRepositorioArqueoTicket;
                                                     const AEmpresa: string);
var
  oEmpresa: TEmpresaArqueoTicket;
begin
  oEmpresa := ARepositorio.ObtenerEmpresa(
    AEmpresa);
  if oEmpresa.Encontrada then
  begin
    ATicket.Alinear(alCentro);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(oEmpresa.RazonSocial);
    ATicket.Negrita(False);
    ATicket.EscribirLinea(oEmpresa.Direccion);
    ATicket.EscribirLinea(
      Trim(oEmpresa.CodigoPostal + ' ' + oEmpresa.Poblacion));
    ATicket.EscribirLinea(oEmpresa.Provincia);
    ATicket.EscribirLinea(
      Format(STicketCif, [oEmpresa.Nif]));
  end;
end;

// =============================================================================
//   Contadores: operaciones, unidades, primera/última operación
// =============================================================================

class procedure TArqueoTicket.EscribirContadores(ATicket: TTicketTermico;
                                                const ARepositorio:
                                                IRepositorioArqueoTicket;
                                                const AArqueo: TArqueoCaja);
var
  oContadores: TContadoresArqueoTicket;
begin
  oContadores := ARepositorio.ObtenerContadores(
    AArqueo);
  ATicket.Alinear(alIzquierda);
  if oContadores.Encontrado then
  begin
    ATicket.TextoColumnas(
      STicketPrimeraOperacion,
      oContadores.PrimeraOperacion);
    ATicket.TextoColumnas(
      STicketUltimaOperacion,
      oContadores.UltimaOperacion);
  end;
  ATicket.LineaSeparadora('-');
  ATicket.TextoColumnas(
    STicketOperaciones,
    IntToStr(AArqueo.CantidadVentas));
  if oContadores.Encontrado then
    ATicket.TextoColumnas(
      STicketUnidadesVenta,
      FmtImp(oContadores.Unidades));
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
  ATicket.EscribirLinea(STicketLineasArticulos);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(STicketBruto, FmtImp(AArqueo.BrutoLineas));

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketOperaciones);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketVentasNormales,
    FmtImp(AArqueo.VentasNormales));
  ATicket.TextoColumnas(
    STicketVentasPrestamos,
    FmtImp(AArqueo.VentasPrestamos));
  ATicket.TextoColumnas(
    STicketDevoluciones,
    FmtImp(AArqueo.Devoluciones));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketTotalVentas, FmtImp(AArqueo.TotalVentas));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketCobros);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketValesRecogidos,
    FmtImp(AArqueo.ValesRecogidos));
  ATicket.TextoColumnas(
    STicketValesEmitidos,
    FmtImp(AArqueo.ValesEmitidos));
  ATicket.TextoColumnas(
    STicketCobrosClientes,
    FmtImp(AArqueo.CobrosClientes));
  ATicket.TextoColumnas(
    STicketPendienteCobro,
    FmtImp(AArqueo.PendienteCobro));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketIngresosCaja, FmtImp(AArqueo.IngresosCaja));
  ATicket.Negrita(False);

  ATicket.SaltarLineas(1);
  ATicket.Negrita(True);
  ATicket.EscribirLinea(STicketEfectivo);
  ATicket.Negrita(False);
  ATicket.TextoColumnas(
    STicketEfectivoIngresos,
    FmtImp(AArqueo.EfectivoIngresos));
  ATicket.TextoColumnas(
    STicketEfectivoEntradas,
    FmtImp(AArqueo.EfectivoEntradas));
  ATicket.TextoColumnas(
    STicketEfectivoSalidas,
    FmtImp(AArqueo.EfectivoSalidas));
  ATicket.TextoColumnas(
    STicketEfectivoAnterior,
    FmtImp(AArqueo.EfectivoAnterior));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketEfectivoCaja, FmtImp(AArqueo.EfectivoCaja));
  ATicket.Negrita(False);
  ATicket.TextoColumnas(STicketOtrosIngresos, FmtImp(AArqueo.OtrosIngresos));
  ATicket.Negrita(True);
  ATicket.TextoColumnas(STicketSaldoRecontar, FmtImp(AArqueo.SaldoRecontar));
  ATicket.Negrita(False);
end;

class procedure TArqueoTicket.EscribirDevolucionesPorFP(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TDevolucionFormaPagoArqueo>;
  iLinea: Integer;
begin
  if AArqueo.Devoluciones <> 0 then
  begin
    aLineas := ARepositorio.ListarDevolucionesPorFormaPago(
      AArqueo);
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketDevolucionesClientes);
    ATicket.Negrita(False);
    ATicket.TextoColumnas(
      STicketNetoArticulos,
      FmtImp(AArqueo.Devoluciones));
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        '    ' + aLineas[iLinea].FormaPago,
        FmtImp(aLineas[iLinea].Importe));
      Inc(iLinea);
    end;
  end;
end;

// =============================================================================
//   Resúmenes
// =============================================================================

class procedure TArqueoTicket.EscribirResumenSeccion(ATicket: TTicketTermico;
                                                    const ARepositorio:
                                                    IRepositorioArqueoTicket;
                                                    const AParametrosCaja:
                                                    IParametrosCaja;
                                                    const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenSeccionArqueo>;
  dTotal: Currency;
  dPorc: Currency;
  sFamilia: string;
  sImporte: string;
  sPorc: string;
  iAnchoFamilia: Integer;
  iLinea: Integer;
begin
  if AArqueo.Neto <> 0 then
  begin
    dTotal := AArqueo.Neto;
    aLineas := ARepositorio.ListarResumenSeccion(
      AArqueo,
      AParametrosCaja.NivelesFamiliaArqueo);
    if Length(aLineas) > 0 then
    begin
      ATicket.SaltarLineas(1);
      ATicket.Negrita(True);
      ATicket.EscribirLinea(STicketResumenNetoSeccion);
      ATicket.Negrita(False);
      iLinea := 0;
      while iLinea < Length(aLineas) do
      begin
        dPorc := (aLineas[iLinea].Neto / dTotal) * 100;
        sFamilia := aLineas[iLinea].Familia;
        sPorc := FmtPorc(dPorc);
        sImporte := FmtImp(aLineas[iLinea].Neto);
        iAnchoFamilia :=
          N_CHAR_LIN - Length(sPorc) - Length(sImporte) - 3;
        if Length(sFamilia) > iAnchoFamilia then
        begin
          if iAnchoFamilia > 3 then
            sFamilia := Copy(
              sFamilia,
              1,
              iAnchoFamilia - 3) + '...'
          else
            sFamilia := Copy(sFamilia, 1, iAnchoFamilia);
        end;
        ATicket.TextoColumnas(
          sFamilia + ' ' + sPorc,
          sImporte);
        Inc(iLinea);
      end;
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenTemporada(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenTemporadaArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenTemporada(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasTemporada);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenTemporada,
          [Copy(aLineas[iLinea].Temporada, 1, 20),
           FormatFloat('0.##', aLineas[iLinea].Unidades)]),
        FmtImp(aLineas[iLinea].Neto));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenEmpleado(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenEmpleadoArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenEmpleado(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasEmpleado);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenEmpleado,
          [aLineas[iLinea].Empleado,
           aLineas[iLinea].Operaciones]),
        FmtImp(aLineas[iLinea].Neto));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenFormaPago(
  ATicket: TTicketTermico;
  const ARepositorio: IRepositorioArqueoTicket;
  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenFormaPagoArqueo>;
  iLinea: Integer;
begin
  aLineas := ARepositorio.ListarResumenFormaPago(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenFormaPago);
    ATicket.Negrita(False);
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      ATicket.TextoColumnas(
        Format(
          STicketFormatoResumenFormaPago,
          [aLineas[iLinea].Descripcion,
           aLineas[iLinea].Unidades]),
        FmtImp(aLineas[iLinea].Importe));
      Inc(iLinea);
    end;
  end;
end;

class procedure TArqueoTicket.EscribirResumenSerie(ATicket: TTicketTermico;
                                                  const ARepositorio:
                                                  IRepositorioArqueoTicket;
                                                  const AArqueo: TArqueoCaja);
var
  aLineas: TArray<TResumenSerieArqueo>;
  dBase, dCuota, dTotal, dPorc: Currency;
  iLinea: Integer;
begin
  // Una fila por serie. % IVA se calcula como tipo efectivo
  // (cuota / base * 100). Si la serie mezcla varios tipos de IVA la cifra
  // del % es la media ponderada, no un tipo concreto.
  aLineas := ARepositorio.ListarResumenSerie(
    AArqueo);
  if Length(aLineas) > 0 then
  begin
    ATicket.SaltarLineas(1);
    ATicket.Negrita(True);
    ATicket.EscribirLinea(STicketResumenVentasSerie);
    ATicket.Negrita(False);
    // El formato debe sumar exactamente N_CHAR_LIN (42) para que la columna
    // TOTAL acabe en el margen derecho, igual que el resto del ticket. Sin
    // espacio entre SERIE y BASE: la serie va a la izquierda y el importe a
    // la derecha, así no se pegan. 7+9+1+5+1+9+1+9 = 42.
    ATicket.EscribirLinea(
      Format(
        '%-7s%9s %5s %9s %9s',
        [STicketCabeceraSerie,
         STicketCabeceraBaseImponible,
         STicketCabeceraPorcentajeIva,
         STicketCabeceraCuota,
         STicketTotal]));
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      dBase := aLineas[iLinea].Base;
      dCuota := aLineas[iLinea].Cuota;
      dTotal := aLineas[iLinea].Total;
      if dBase <> 0 then
        dPorc := (dCuota / dBase) * 100
      else
        dPorc := 0;
      ATicket.EscribirLinea(
        Format('%-7s%9s %5s %9s %9s',
               [Copy(aLineas[iLinea].Serie, 1, 7),
                 FmtImp(dBase),
                FormatFloat('0.00', dPorc),
                FmtImp(dCuota),
                FmtImp(dTotal)]));
      Inc(iLinea);
    end;
  end;
end;

// =============================================================================
//   API pública
// =============================================================================

class procedure TArqueoTicket.Imprimir(
                                      const APreview: IPreviewTicket;
                                      const ARepositorioArqueo:
                                      IRepositorioArqueoCaja;
                                      const ARepositorioTicket:
                                      IRepositorioArqueoTicket;
                                      const AParametrosCaja:
                                      IParametrosCaja;
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
  Arqueo := ARepositorioArqueo.Calcular(
    AEmpresa,
    AAlmacen,
    ACaja,
    AFechaDesde,
    AFechaHasta);

  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;

    // Cabecera de empresa
    EscribirCabeceraEmpresa(
      Ticket,
      ARepositorioTicket,
      AEmpresa);

    // Título del arqueo
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(Format(STicketArqueoCaja, [ACaja]));
    Ticket.EscribirLinea(STicketPeriodoSeleccionado);
    Ticket.EscribirLinea(Format(STicketDesde,
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaDesde)]));
    Ticket.EscribirLinea(Format(STicketHasta,
      [FormatDateTime('dd/mm/yy hh:nn:ss', AFechaHasta)]));
    Ticket.Negrita(False);
    // Marca de reimpresión: el arqueo original ya se emitió en su día
    if ADuplicado then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketDuplicado);
      Ticket.Negrita(False);
    end;
    Ticket.SaltarLineas(1);

    // Contadores
    EscribirContadores(
      Ticket,
      ARepositorioTicket,
      Arqueo);

    // Totales
    EscribirTotales(Ticket, Arqueo);

    // Devoluciones desglosadas por forma de pago
    EscribirDevolucionesPorFP(
      Ticket,
      ARepositorioTicket,
      Arqueo);

    // Resúmenes
    EscribirResumenSeccion(
      Ticket,
      ARepositorioTicket,
      AParametrosCaja,
      Arqueo);
    EscribirResumenTemporada(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenEmpleado(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenFormaPago(
      Ticket,
      ARepositorioTicket,
      Arqueo);
    EscribirResumenSerie(
      Ticket,
      ARepositorioTicket,
      Arqueo);

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
    ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

// =============================================================================
//   Ticket de recuento (cierre Z grabado)
// =============================================================================

class procedure TArqueoTicket.ImprimirCierre(
  const APreview: IPreviewTicket;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AContextoSesion: IContextoSesionAplicacion;
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
    EscribirCabeceraEmpresa(
      Ticket,
      ARepositorioTicket,
      AArqueo.Empresa);
    { Título }
    Ticket.SaltarLineas(1);
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(
      Format(STicketCierreCaja, [AArqueo.Caja]));
    Ticket.Negrita(False);
    // Marca de reimpresión del justificante de cierre
    if ADuplicado then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketDuplicado);
      Ticket.Negrita(False);
    end;
    { Datos del cierre }
    Ticket.Alinear(alIzquierda);
    Ticket.EscribirLinea(STicketPeriodoCerrado);
    Ticket.TextoColumnas(STicketInicio,
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AArqueo.FechaDesde));
    Ticket.TextoColumnas(STicketFin,
      FormatDateTime('dd/mm/yyyy hh:nn:ss', AArqueo.FechaHasta));
    Ticket.TextoColumnas(STicketVentas,
      IntToStr(AArqueo.CantidadVentas));
    Ticket.TextoColumnas(STicketCierrePor,
      AContextoSesion.Identidad.Usuario);
    // Vendedor (empleado de caja) que estampa el cierre; los arqueos
    // grabados antes de exigirlo pueden venir sin él
    if AVendedor <> '' then
      Ticket.TextoColumnas(STicketVendedor, AVendedor);
    Ticket.LineaSeparadora('=');
    { Desglose de billetes y monedas }
    if ADesgloseBilletes <> '' then
    begin
      Ticket.Negrita(True);
      Ticket.EscribirLinea(STicketBilletesMonedas);
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
    Ticket.EscribirLinea(STicketEfectivoSistema);
    Ticket.Negrita(False);
    Ticket.TextoColumnas(STicketVentasSangrado,
      FmtImp(AArqueo.EfectivoIngresos));
    Ticket.TextoColumnas(STicketEntradasSangrado,
      FmtImp(AArqueo.EfectivoEntradas));
    Ticket.TextoColumnas(STicketGastosSangrado,
      FmtImp(AArqueo.EfectivoSalidas));
    Ticket.TextoColumnas(STicketAnteriorSangrado,
      FmtImp(AArqueo.EfectivoAnterior));
    Ticket.TextoColumnas(STicketTotalSangrado,
      FmtImp(AArqueo.EfectivoCaja));
    Ticket.LineaSeparadora;
    { Detalle por forma de pago: 3 columnas alineadas a la derecha
      sobre los 42 caracteres del ticket (14+14+14) }
    Ticket.Negrita(True);
    Ticket.EscribirLinea(STicketRecuento);
    Ticket.Negrita(False);
    Ticket.EscribirLinea(
      Format(
        '%14s%14s%14s',
        [STicketSistemaAbreviado,
         STicketRecuentoAbreviado,
         STicketDiferenciaAbreviada]));
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
    Ticket.TextoColumnas(STicketTotalSistema,
      FmtImp(ATotalSistema));
    Ticket.TextoColumnas(STicketTotalRecontado,
      FmtImp(ATotalRecuento));
    Ticket.TextoColumnas(STicketDiferencia,
      FmtImp(ADiferencia));
    Ticket.Negrita(False);
    Ticket.LineaSeparadora;
    { Retirada }
    if ARetirada > 0 then
    begin
      Ticket.TextoColumnas(STicketRetirada,
        FmtImp(ARetirada));
      Ticket.TextoColumnas(STicketDestinoSangrado,
        AConceptoRetirada);
    end;
    { Dejo para mañana }
    Ticket.Negrita(True);
    Ticket.TextoColumnas(STicketDejoCaja,
      FmtImp(AEfectivoDejado));
    Ticket.Negrita(False);
    { Observaciones }
    if AObservaciones <> '' then
    begin
      Ticket.LineaSeparadora;
      Ticket.EscribirLinea(
        Format(STicketObservaciones, [AObservaciones]));
    end;
    { Pie }
    Ticket.LineaSeparadora;
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(
      FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Ticket.EscribirLinea(STicketFirma);
    Ticket.SaltarLineas(2);
    Ticket.LineaSeparadora('.');
    Ticket.SaltarLineas(1);
    Ticket.CortarPapel;
    { Imprimir o previsualizar }
    ComandosESC := Ticket.ObtenerComandos;
    RutaPDF := GetUserFolderTickets + 'Recuento_' +
               FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(APreview, Ticket, ComandosESC, RutaPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

// =============================================================================
//   Reimpresión de duplicados desde el histórico (fza_caja_arqueos)
// =============================================================================

class procedure TArqueoTicket.ImprimirDesdeHistorico(
  const APreview: IPreviewTicket;
  const ARepositorioArqueo: IRepositorioArqueoCaja;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AParametrosCaja: IParametrosCaja;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  dFechaHasta: TDate;
  oRango: TRangoHistoricoArqueo;
begin
  oRango := ARepositorioTicket.ObtenerRangoHistorico(
    AEmpresa,
    AAlmacen,
    ACaja,
    ACodigoArqueo);
  // Los cierres antiguos guardaban fechas sin hora. Se mantienen como dia
  // completo; los nuevos cierres por horas conservan su datetime exacto.
  if oRango.Encontrado then
  begin
    dFechaHasta := oRango.FechaHasta;
    if (Frac(oRango.FechaDesde) = 0) and
       (Frac(dFechaHasta) = 0) then
      dFechaHasta := dFechaHasta + EncodeTime(23, 59, 59, 0);
    Imprimir(
      APreview,
      ARepositorioArqueo,
      ARepositorioTicket,
      AParametrosCaja,
      oRango.Empresa,
      oRango.Almacen,
      oRango.Caja,
      oRango.FechaDesde,
      dFechaHasta,
      ANombreImpresora,
      True);
  end;
end;

class procedure TArqueoTicket.ImprimirCierreDesdeHistorico(
  const APreview: IPreviewTicket;
  const ARepositorioTicket: IRepositorioArqueoTicket;
  const AContextoSesion: IContextoSesionAplicacion;
  const AEmpresa, AAlmacen, ACaja: string;
  const ACodigoArqueo: string;
  const ANombreImpresora: string = 'DEBUG');
var
  aLineas: TArray<TArqueoRecuentoLinea>;
  iLinea: Integer;
  oCierre: TCierreHistoricoArqueo;
begin
  oCierre := ARepositorioTicket.ObtenerCierreHistorico(
    AEmpresa,
    AAlmacen,
    ACaja,
    ACodigoArqueo);
  if oCierre.Encontrado then
  begin
    if (Frac(oCierre.Arqueo.FechaDesde) = 0) and
       (Frac(oCierre.Arqueo.FechaHasta) = 0) then
      oCierre.Arqueo.FechaHasta :=
        oCierre.Arqueo.FechaHasta + EncodeTime(23, 59, 59, 0);
    SetLength(aLineas, Length(oCierre.Lineas));
    iLinea := 0;
    while iLinea < Length(oCierre.Lineas) do
    begin
      aLineas[iLinea].CodigoFP :=
        oCierre.Lineas[iLinea].CodigoFormaPago;
      aLineas[iLinea].Descripcion :=
        oCierre.Lineas[iLinea].Descripcion;
      aLineas[iLinea].EsCajon :=
        oCierre.Lineas[iLinea].EsCajon;
      aLineas[iLinea].Sistema :=
        oCierre.Lineas[iLinea].Sistema;
      aLineas[iLinea].Recuento :=
        oCierre.Lineas[iLinea].Recuento;
      aLineas[iLinea].Diferencia :=
        oCierre.Lineas[iLinea].Diferencia;
      Inc(iLinea);
    end;
    ImprimirCierre(
      APreview,
      ARepositorioTicket,
      AContextoSesion,
      oCierre.Arqueo,
      aLineas,
      oCierre.TotalSistema,
      oCierre.TotalRecuento,
      oCierre.Diferencia,
      oCierre.Retirada,
      oCierre.ConceptoRetirada,
      oCierre.EfectivoDejado,
      oCierre.DesgloseBilletes,
      oCierre.Observaciones,
      oCierre.Vendedor,
      ANombreImpresora,
      True);
  end;
end;

end.
