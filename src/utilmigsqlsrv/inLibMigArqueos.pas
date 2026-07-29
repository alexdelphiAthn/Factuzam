{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArqueos                                               }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los arqueos / cierres Z del legacy → fza_caja_arqueos (cabecera)    }
{    + fza_caja_arqueos_recuento (recuento por forma de pago).                 }
{      Origen:  dbo.ocarqueonew (una fila por cierre de caja y día).           }
{                                                                              }
{    CODIGO_ARQ = '<YYYYMMDD>-<emp>-<almAbrev>-<caja>' (único por caja/día).   }
{    FASE_ARQ   = 'CERRADO' (los históricos ya están cerrados).                }
{                                                                              }
{    Recuento: se generan 2 líneas por arqueo a partir de los importes del     }
{    legacy: 'EFE' (sistema=ImpEfeTeo, recuento=ImpEfeCdo, dif=ImpDescuadre) y  }
{    'TARJ' (sistema=ImpTarjeta, dif=ImpDescuadreTarjeta) si hay tarjeta. El    }
{    legacy agrega todas las tarjetas en ImpTarjeta, así que aquí la línea de   }
{    recuento va a la 'TARJ' genérica (no a las TARJ<n> por tipo).             }
{                                                                              }
{    Idempotente: PK CODIGO_ARQ + UNIQUE (CODIGO_ARQ, CODIGO_FP) con INSERT     }
{    IGNORE; re-ejecutar no duplica.                                           }
{******************************************************************************}
unit inLibMigArqueos;
interface
uses
  UMigEngine, UMigCatalogo;
procedure MigrarArqueos(const Eng: IContextoMigracion; var Stats: TMigStats);
implementation
uses
  System.SysUtils,
  Data.DB, Uni;
procedure MigrarArqueos(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cSel =
    'SELECT a.Empresa, a.Almacen, a.Caja, a.Fecha, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(a.Vendedor, 0) AS Vendedor, ' +
    '       ISNULL(a.NroVentas, 0) AS NroVentas, ' +
    '       ISNULL(a.ImpLineasCdo, 0) AS ImpLineasCdo, ' +
    '       ISNULL(a.ImpDtoLineasCdo, 0) AS ImpDtoLineasCdo, ' +
    '       ISNULL(a.ImpBrutoCdo, 0) AS ImpBrutoCdo, ' +
    '       ISNULL(a.ImpDtoCdo, 0) AS ImpDtoCdo, ' +
    '       ISNULL(a.ImpNetoCdo, 0) AS ImpNetoCdo, ' +
    '       ISNULL(a.ImpAlbaranCdo, 0) AS ImpAlbaranCdo, ' +
    '       ISNULL(a.ImpValeRcgdo, 0) AS ImpValeRcgdo, ' +
    '       ISNULL(a.ImpValeEmitido, 0) AS ImpValeEmitido, ' +
    '       ISNULL(a.ImpCobroCli, 0) AS ImpCobroCli, ' +
    '       ISNULL(a.ImpPendiente, 0) AS ImpPendiente, ' +
    '       ISNULL(a.ImpRecaudado, 0) AS ImpRecaudado, ' +
    '       ISNULL(a.ImpEfectivo, 0) AS ImpEfectivo, ' +
    '       ISNULL(a.ImpEfeEntrada, 0) AS ImpEfeEntrada, ' +
    '       ISNULL(a.ImpEfeSalida, 0) AS ImpEfeSalida, ' +
    '       ISNULL(a.ImpEfeAnt, 0) AS ImpEfeAnt, ' +
    '       ISNULL(a.ImpEfeTeo, 0) AS ImpEfeTeo, ' +
    '       ISNULL(a.ImpEfeTeoMasTar, 0) AS ImpEfeTeoMasTar, ' +
    '       ISNULL(a.ImpEfeCdo, 0) AS ImpEfeCdo, ' +
    '       ISNULL(a.ImpTarjeta, 0) AS ImpTarjeta, ' +
    '       ISNULL(a.ImpDescuadre, 0) AS ImpDescuadre, ' +
    '       ISNULL(a.ImpDescuadreTarjeta, 0) AS ImpDescuadreTarjeta, ' +
    '       ISNULL(a.ImpEfeFin, 0) AS ImpEfeFin, ' +
    '       ISNULL(a.ImpDeposito, 0) AS ImpDeposito, ' +
    '       ISNULL(a.ImpEncargo, 0) AS ImpEncargo, ' +
    '       ISNULL(a.Observacion, '''') AS Observacion ' +
    'FROM dbo.ocarqueonew a ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = a.Empresa ' +
    '                       AND alm.Almacen = a.Almacen ' +
    'ORDER BY a.Empresa, a.Almacen, a.Caja, a.Fecha';
  cInsCab =
    'INSERT IGNORE INTO fza_caja_arqueos ' +
    '  (CODIGO_ARQ, CODIGO_EMP_ARQ, CODIGO_ALM_ARQ, CODIGO_CAJA_ARQ, ' +
    '   FECHA_DESDE_ARQ, FECHA_HASTA_ARQ, FASE_ARQ, CODIGO_EMPLEADO_ARQ, ' +
    '   CANTIDAD_VENTAS_ARQ, CANTIDAD_OPERACIONES_ARQ, ' +
    '   TOTAL_BRUTO_LINEAS_ARQ, TOTAL_DESCUENTOS_LINEAS_ARQ, ' +
    '   TOTAL_BRUTO_OPERACIONES_ARQ, TOTAL_DESCUENTOS_OPERACIONES_ARQ, ' +
    '   TOTAL_NETO_ARQ, TOTAL_VENTAS_ARQ, TOTAL_VENTA_CREDITO_ARQ, ' +
    '   TOTAL_VALES_RECOGIDOS_ARQ, TOTAL_VALES_EMITIDOS_ARQ, ' +
    '   TOTAL_COBROS_CLIENTES_ARQ, TOTAL_PENDIENTE_COBRO_ARQ, ' +
    '   TOTAL_INGRESOS_CAJA_ARQ, TOTAL_EFECTIVO_INGRESOS_ARQ, ' +
    '   TOTAL_EFECTIVO_ENTRADAS_ARQ, TOTAL_EFECTIVO_SALIDAS_ARQ, ' +
    '   TOTAL_EFECTIVO_ANTERIOR_ARQ, TOTAL_EFECTIVO_CAJA_ARQ, ' +
    '   TOTAL_OTROS_INGRESOS_ARQ, TOTAL_SALDO_RECONTAR_ARQ, ' +
    '   TOTAL_RECUENTO_ARQ, DIFERENCIA_TOTAL_ARQ, EFECTIVO_DEJADO_CAJA_ARQ, ' +
    '   TOTAL_DEPOSITOS_ARQ, TOTAL_ENCARGOS_ARQ, OBSERVACIONES_ARQ, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :emp, :alm, :caja, :fdesde, :fhasta, ''CERRADO'', :empl, ' +
    '        :nventas, :nventas, :blin, :dlin, :bope, :dope, :neto, :ventas, ' +
    '        :credito, :valrec, :valemi, :cobrocli, :pdtecobro, :ingcaja, ' +
    '        :efeing, :efeent, :efesal, :efeant, :efecaja, :otros, ' +
    '        :saldorec, :recuento, :diftotal, :efedejado, :deposito, ' +
    '        :encargo, :obs, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cInsRec =
    'INSERT IGNORE INTO fza_caja_arqueos_recuento ' +
    '  (CODIGO_ARQ_ARQR, CODIGO_FP_CFP_ARQR, DESCRIPCION_FP_ARQR, ' +
    '   ESCAJON_ARQR, IMPORTE_SISTEMA_ARQR, IMPORTE_RECUENTO_ARQR, ' +
    '   DIFERENCIA_ARQR, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    '   USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :fp, :desc, :cajon, :sistema, :recuento, :dif, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qCab, qRec: TUniQuery;
  iEmp, iAlm, iCaja, iVend: Integer;
  sEmp, sAlm, sCaja, sCod:  string;
  dtFecha:                  TDateTime;
  fTarjeta, fDescTar:       Double;
  procedure AddRecuento(const sFp, sDesc, sCajon: string;
    fSistema, fRecuento, fDif: Double);
  begin
    qRec.ParamByName('cod').AsString      := sCod;
    qRec.ParamByName('fp').AsString       := sFp;
    qRec.ParamByName('desc').AsString     := sDesc;
    qRec.ParamByName('cajon').AsString    := sCajon;
    qRec.ParamByName('sistema').AsFloat   := fSistema;
    qRec.ParamByName('recuento').AsFloat  := fRecuento;
    qRec.ParamByName('dif').AsFloat       := fDif;
    RellenarAuditoria(qRec, Eng.Usuario);
    qRec.ExecSQL;
  end;
begin
  qCab := TUniQuery.Create(nil);
  qRec := TUniQuery.Create(nil);
  qSrc := NuevoQOrigen(Eng, cSel);
  qSrc.UniDirectional := True;
  try
    qCab.Connection := Eng.Datos.ConexionDestino;   qCab.SQL.Text := cInsCab;
    qRec.Connection := Eng.Datos.ConexionDestino;   qRec.SQL.Text := cInsRec;
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen('SELECT COUNT(*) FROM dbo.ocarqueonew'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      iEmp  := qSrc.FieldByName('Empresa').AsInteger;
      iAlm  := qSrc.FieldByName('Almacen').AsInteger;
      iCaja := qSrc.FieldByName('Caja').AsInteger;
      iVend := qSrc.FieldByName('Vendedor').AsInteger;
      sEmp  := IntToStr(iEmp);
      sAlm  := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      sCaja   := IntToStr(iCaja);
      dtFecha := Trunc(qSrc.FieldByName('Fecha').AsDateTime);
      // CODIGO_ARQ unico por caja y dia.
      sCod := Format('%s-%s-%s-%s',
        [FormatDateTime('yyyymmdd', dtFecha), sEmp, sAlm, sCaja]);
      // --- Cabecera ---
      qCab.ParamByName('cod').AsString     := sCod;
      qCab.ParamByName('emp').AsString     := sEmp;
      qCab.ParamByName('alm').AsString     := sAlm;
      qCab.ParamByName('caja').AsString    := sCaja;
      qCab.ParamByName('fdesde').AsDateTime := dtFecha;
      qCab.ParamByName('fhasta').AsDateTime := dtFecha;
      if iVend > 0 then
        qCab.ParamByName('empl').AsString := IntToStr(iVend)
      else
        qCab.ParamByName('empl').Clear;
      qCab.ParamByName('nventas').AsInteger := qSrc.FieldByName('NroVentas').AsInteger;
      qCab.ParamByName('blin').AsFloat      := qSrc.FieldByName('ImpLineasCdo').AsFloat;
      qCab.ParamByName('dlin').AsFloat      := qSrc.FieldByName('ImpDtoLineasCdo').AsFloat;
      qCab.ParamByName('bope').AsFloat      := qSrc.FieldByName('ImpBrutoCdo').AsFloat;
      qCab.ParamByName('dope').AsFloat      := qSrc.FieldByName('ImpDtoCdo').AsFloat;
      qCab.ParamByName('neto').AsFloat      := qSrc.FieldByName('ImpNetoCdo').AsFloat;
      qCab.ParamByName('ventas').AsFloat    := qSrc.FieldByName('ImpNetoCdo').AsFloat;
      qCab.ParamByName('credito').AsFloat   := qSrc.FieldByName('ImpAlbaranCdo').AsFloat;
      qCab.ParamByName('valrec').AsFloat    := qSrc.FieldByName('ImpValeRcgdo').AsFloat;
      qCab.ParamByName('valemi').AsFloat    := qSrc.FieldByName('ImpValeEmitido').AsFloat;
      qCab.ParamByName('cobrocli').AsFloat  := qSrc.FieldByName('ImpCobroCli').AsFloat;
      qCab.ParamByName('pdtecobro').AsFloat := qSrc.FieldByName('ImpPendiente').AsFloat;
      qCab.ParamByName('ingcaja').AsFloat   := qSrc.FieldByName('ImpRecaudado').AsFloat;
      qCab.ParamByName('efeing').AsFloat    := qSrc.FieldByName('ImpEfectivo').AsFloat;
      qCab.ParamByName('efeent').AsFloat    := qSrc.FieldByName('ImpEfeEntrada').AsFloat;
      qCab.ParamByName('efesal').AsFloat    := qSrc.FieldByName('ImpEfeSalida').AsFloat;
      qCab.ParamByName('efeant').AsFloat    := qSrc.FieldByName('ImpEfeAnt').AsFloat;
      qCab.ParamByName('efecaja').AsFloat   := qSrc.FieldByName('ImpEfeTeo').AsFloat;
      fTarjeta := qSrc.FieldByName('ImpTarjeta').AsFloat;
      fDescTar := qSrc.FieldByName('ImpDescuadreTarjeta').AsFloat;
      qCab.ParamByName('otros').AsFloat     := fTarjeta;
      qCab.ParamByName('saldorec').AsFloat  := qSrc.FieldByName('ImpEfeTeoMasTar').AsFloat;
      qCab.ParamByName('recuento').AsFloat  := qSrc.FieldByName('ImpEfeCdo').AsFloat;
      qCab.ParamByName('diftotal').AsFloat  := qSrc.FieldByName('ImpDescuadre').AsFloat;
      qCab.ParamByName('efedejado').AsFloat := qSrc.FieldByName('ImpEfeFin').AsFloat;
      qCab.ParamByName('deposito').AsFloat  := qSrc.FieldByName('ImpDeposito').AsFloat;
      qCab.ParamByName('encargo').AsFloat   := qSrc.FieldByName('ImpEncargo').AsFloat;
      qCab.ParamByName('obs').AsString      :=
        Copy(Trim(qSrc.FieldByName('Observacion').AsString), 1, 500);
      RellenarAuditoria(qCab, Eng.Usuario);
      try
        qCab.ExecSQL;
        Inc(Stats.Insertadas);
        // --- Recuento por forma de pago ---
        // Efectivo: sistema=teorico, recuento=contado, diferencia=descuadre.
        AddRecuento('EFE', 'Efectivo', 'S',
          qSrc.FieldByName('ImpEfeTeo').AsFloat,
          qSrc.FieldByName('ImpEfeCdo').AsFloat,
          qSrc.FieldByName('ImpDescuadre').AsFloat);
        // Tarjeta (genérica): solo si hubo importe o descuadre de tarjeta.
        if (fTarjeta <> 0) or (fDescTar <> 0) then
          AddRecuento('TARJ', 'Tarjeta', 'N',
            fTarjeta, fTarjeta + fDescTar, fDescTar);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.LogError('arqueo', sCod, E.Message, '',
            'requiere ocarqueonew en el origen');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qRec.Free;
    qCab.Free;
    qSrc.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'arqueos',
    'Arqueos / cierres Z (ocarqueonew)',
    'dbo.ocarqueonew → arqueos y recuentos',
    ['ventas'],
    MigrarArqueos);

end.
