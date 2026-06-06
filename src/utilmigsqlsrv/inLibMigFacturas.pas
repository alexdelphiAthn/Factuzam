{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFacturas                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    FASE 2 de la migración de ventas: reconstruye el detalle de venta del     }
{    legacy como factura SIMPLIFICADA en Factuzam.                             }
{      occaj (venta)  → fza_facturas (una por operación de venta)              }
{      occajarp       → fza_facturas_lineas (una por línea)                    }
{                                                                              }
{    Solo procesa operaciones de VENTA: occaj.TipoDoc='VE' y Tipo<>'C'         }
{    (los cobros Tipo='C' no llevan detalle de artículo; los AL ya van a       }
{    depósito en inLibMigVentas; los TR/AT son traspasos).                     }
{                                                                              }
{    Numeración (determinista y trazable al legacy):                           }
{      SERIE_FAC  = '<Ejercicio>.<Serie>'      (p.ej. '2001.B1')               }
{      NUMERO_FAC = '<Almacen>-<Caja>-<Operacion>'                             }
{    Único por empresa/serie. En instalación multiempresa habría que           }
{    prefijar la empresa. Cada línea enlaza con su operación de caja           }
{    (NUMERO_OPERACION_FACLIN) y con su movimiento de almacén                  }
{    (NUMERO_MOV_FACLIN = 'MH'+NumeroMovArt, igual que inLibMigMovimientos).   }
{                                                                              }
{    IVA de cabecera (aproximado, primera versión): se trata la factura como   }
{    UNA banda de IVA "Normal" derivada del total y del % del legacy           }
{    (occaj.PorcenIva1): base = Neto/(1+%/100), cuota = Neto-base. Las líneas  }
{    sí llevan su IVA real por fila (occajarp.PorIva). El desglose fino en     }
{    bandas N/R/S/E y el estado fiscal/Verifactu se dejan para afinar.         }
{                                                                              }
{    Idempotente: al arrancar borra lo migrado por este usuario en             }
{    fza_facturas_lineas y fza_facturas y vuelve a insertar.                   }
{******************************************************************************}
unit inLibMigFacturas;

interface

uses
  UMigEngine;

procedure MigrarFacturas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// =========================================================================
//  Helpers locales (mismo criterio que SKUs / Movimientos / Ventas)
// =========================================================================

function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var
  u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var
  sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then
    sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then
    sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

// Artículo "genérico" del legacy ('0' o vacío) = línea de servicio/varios,
// sin SKU de stock.
function EsArticuloGenerico(const sArt: string): Boolean;
var
  s: string;
begin
  s := Trim(sArt);
  Result := (s = '') or (s = '0');
end;

procedure LimpiarMigracionPrevia(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := 'DELETE FROM fza_facturas_lineas WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_facturas WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Clasifica un % de IVA en banda Factuzam: 0=Normal, 1=Reducido,
// 2=Superreducido, 3=Exento. Umbrales pensados para cubrir los tipos
// históricos españoles (general 16/18/21, reducido 7/8/10, super 4, 0=exento).
function BandaIva(const rate: Double): Integer;
begin
  if rate <= 0 then
    Result := 3
  else if rate < 6 then
    Result := 2
  else if rate < 13 then
    Result := 1
  else
    Result := 0;
end;

// Rellena en la cabecera el desglose de IVA por bandas N/R/S/E a partir de
// las 4 bandas que el legacy trae en occaj (BaseImp/PorcenIva/CuotaIVA 1-4).
// Cada banda legacy se clasifica por su % (BandaIva) y se acumula. La cuota
// se calcula si el legacy no la trae (filas antiguas: CuotaIVA NULL). Si no
// hay bandas pero sí Neto, se deriva una banda única del total.
procedure FijarIvaCabecera(qSrc, qFac: TUniQuery; const fNeto: Double);
var
  aBase, aCuota, aRate: array[0..3] of Double;
  i, b:                 Integer;
  base, rate, cuota:    Double;
  fBases, fImp:         Double;
begin
  for b := 0 to 3 do
  begin
    aBase[b]  := 0;
    aCuota[b] := 0;
    aRate[b]  := 0;
  end;
  for i := 1 to 4 do
  begin
    base  := qSrc.FieldByName('BaseImp'  + IntToStr(i)).AsFloat;
    rate  := qSrc.FieldByName('PorcenIva' + IntToStr(i)).AsFloat;
    cuota := qSrc.FieldByName('CuotaIVA' + IntToStr(i)).AsFloat;
    if (base <> 0) or (cuota <> 0) then
    begin
      if (cuota = 0) and (rate > 0) then
        cuota := base * rate / 100;
      b := BandaIva(rate);
      aBase[b]  := aBase[b]  + base;
      aCuota[b] := aCuota[b] + cuota;
      if rate > aRate[b] then
        aRate[b] := rate;
    end;
  end;
  fBases := aBase[0] + aBase[1] + aBase[2] + aBase[3];
  fImp   := aCuota[0] + aCuota[1] + aCuota[2] + aCuota[3];
  // Fallback: sin bandas pero con total → una banda derivada del Neto.
  if (fBases = 0) and (fNeto <> 0) then
  begin
    rate := qSrc.FieldByName('PorcenIva1').AsFloat;
    if rate > 0 then
      base := fNeto / (1 + rate / 100)
    else
      base := fNeto;
    b := BandaIva(rate);
    aBase[b]  := base;
    aRate[b]  := rate;
    aCuota[b] := fNeto - base;
    fBases    := base;
    fImp      := fNeto - base;
  end;
  qFac.ParamByName('pivan').AsFloat  := aRate[0];
  qFac.ParamByName('tivan').AsFloat  := aCuota[0];
  qFac.ParamByName('basein').AsFloat := aBase[0];
  qFac.ParamByName('pivar').AsFloat  := aRate[1];
  qFac.ParamByName('tivar').AsFloat  := aCuota[1];
  qFac.ParamByName('basier').AsFloat := aBase[1];
  qFac.ParamByName('pivas').AsFloat  := aRate[2];
  qFac.ParamByName('tivas').AsFloat  := aCuota[2];
  qFac.ParamByName('baseis').AsFloat := aBase[2];
  qFac.ParamByName('pivae').AsFloat  := aRate[3];
  qFac.ParamByName('tivae').AsFloat  := aCuota[3];
  qFac.ParamByName('baseie').AsFloat := aBase[3];
  qFac.ParamByName('bases').AsFloat  := fBases;
  qFac.ParamByName('imp').AsFloat    := fImp;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarFacturas(Eng: TMigEngine; var Stats: TMigStats);
const
  cWhere =
    'WHERE c.TipoDoc = ''VE'' AND ISNULL(c.Tipo, '''') <> ''C''';
  cSelectSrc =
    'SELECT c.Empresa, c.Almacen, c.Caja, c.Operacion, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       c.Ejercicio, ISNULL(c.Serie, '''') AS Serie, ' +
    '       c.FechaOpe, c.Fecha, c.Vendedor AS VendedorCab, ' +
    '       ISNULL(c.Cliente, '''') AS Cliente, ' +
    '       ISNULL(c.Neto, 0) AS Neto, ' +
    '       ISNULL(c.BaseImp1, 0) AS BaseImp1, ' +
    '       ISNULL(c.PorcenIva1, 0) AS PorcenIva1, ' +
    '       ISNULL(c.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(c.BaseImp2, 0) AS BaseImp2, ' +
    '       ISNULL(c.PorcenIva2, 0) AS PorcenIva2, ' +
    '       ISNULL(c.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(c.BaseImp3, 0) AS BaseImp3, ' +
    '       ISNULL(c.PorcenIva3, 0) AS PorcenIva3, ' +
    '       ISNULL(c.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(c.BaseImp4, 0) AS BaseImp4, ' +
    '       ISNULL(c.PorcenIva4, 0) AS PorcenIva4, ' +
    '       ISNULL(c.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       l.NroLinea, l.Articulo, l.Talla, l.Vendedor AS VendedorLin, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.NetoSIva, 0) AS NetoSIva, ' +
    '       ISNULL(l.NetoCIva, 0) AS NetoCIva, ' +
    '       ISNULL(l.PorIva, 0) AS PorIva, ISNULL(l.PorDto, 0) AS PorDto, ' +
    '       ISNULL(l.NumeroMovArt, 0) AS NumeroMovArt, ' +
    '       ISNULL(l.Descripcion, '''') AS Descripcion, ' +
    '       CASE ' +
    '         WHEN co.Descripcion IS NULL ' +
    '           OR LTRIM(RTRIM(co.Descripcion)) = '''' ' +
    '           OR UPPER(LTRIM(RTRIM(co.Descripcion))) = ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '       END AS DescColor ' +
    'FROM dbo.occajarp l ' +
    'INNER JOIN dbo.occaj c ON c.Empresa = l.Empresa ' +
    '                      AND c.Almacen = l.Almacen ' +
    '                      AND c.Caja    = l.Caja ' +
    '                      AND c.Operacion = l.Operacion ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = c.Empresa ' +
    '                       AND alm.Almacen = c.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    cWhere + ' ' +
    'ORDER BY c.Empresa, c.Almacen, c.Caja, c.Operacion, l.NroLinea';
  cInsFac =
    'INSERT INTO fza_facturas ' +
    '  (NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, ESCONSOLIDADA_FAC, ' +
    '   CODIGO_EMP_FAC, CODIGO_CLI_FAC, ' +
    '   PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
    '   PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    '   PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    '   PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    '   TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, TOTAL_LIQUIDO_FAC, ' +
    '   FORMA_PAGO_FAC, CODIGO_CAJERO_FAC, CODIGO_ALM_FAC, CODIGO_CAJA_FAC, ' +
    '   NUMERO_OPERACION_FAC, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:num, :serie, :fecha, ''SIMPLIFICADA'', ''S'', ' +
    '        :emp, :cli, ' +
    '        :pivan, :tivan, :basein, ' +
    '        :pivar, :tivar, :basier, ' +
    '        :pivas, :tivas, :baseis, ' +
    '        :pivae, :tivae, :baseie, ' +
    '        :bases, :imp, :liq, ' +
    '        ''CONTADO'', :cajero, :alm, :caja, :numop, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cInsLin =
    'INSERT INTO fza_facturas_lineas ' +
    '  (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    '   LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    '   TIPO_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    '   DESCRIPCION_ARTICULO_FACLIN, PORCENTAJE_DTO_FACLIN, ' +
    '   PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    '   PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    '   TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, CODIGO_VENDEDOR_FACLIN, ' +
    '   CODIGO_ALM_FACLIN, CODIGO_CAJA_FACLIN, NUMERO_OPERACION_FACLIN, ' +
    '   NUMERO_MOV_FACLIN, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:num, :serie, :emp, :linea, :art, :uni, :tipoart, :cant, ' +
    '        :desc, :pdto, :psiva, ''N'', :piva, :pciva, ' +
    '        :total, :totalsiva, :vend, :alm, :caja, :numop, :nmov, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qFac, qLin:        TUniQuery;
  iEmp, iAlm, iCaja, iOpe: Integer;
  sEmp, sAlm, sNumOp:      string;
  sNumFac, sSerieFac:      string;
  sOpKey, sLastOpKey:      string;
  sArt, sUni, sTipoArt:    string;
  fNeto:                   Double;
  dtFecha:                 TDateTime;
begin
  LimpiarMigracionPrevia(Eng);
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qFac := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  try
    qFac.Connection := Eng.ConDst;   qFac.SQL.Text := cInsFac;
    qLin.Connection := Eng.ConDst;   qLin.SQL.Text := cInsLin;
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.occajarp l ' +
      'INNER JOIN dbo.occaj c ON c.Empresa = l.Empresa ' +
      '                      AND c.Almacen = l.Almacen ' +
      '                      AND c.Caja    = l.Caja ' +
      '                      AND c.Operacion = l.Operacion ' + cWhere));
    sLastOpKey := '';
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Facturas, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      iEmp  := qSrc.FieldByName('Empresa').AsInteger;
      iAlm  := qSrc.FieldByName('Almacen').AsInteger;
      iCaja := qSrc.FieldByName('Caja').AsInteger;
      iOpe  := qSrc.FieldByName('Operacion').AsInteger;
      sEmp  := IntToStr(iEmp);
      sAlm  := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      sNumOp    := Format('%.8d', [iOpe]);
      sSerieFac := Format('%d.%s', [qSrc.FieldByName('Ejercicio').AsInteger,
                     Trim(qSrc.FieldByName('Serie').AsString)]);
      sNumFac   := Format('%d-%d-%d', [iAlm, iCaja, iOpe]);
      // Cabecera: una por operación (primera línea que vemos del grupo).
      sOpKey := Format('%d|%d|%d|%d', [iEmp, iAlm, iCaja, iOpe]);
      if sOpKey <> sLastOpKey then
      begin
        sLastOpKey := sOpKey;
        if not qSrc.FieldByName('FechaOpe').IsNull then
          dtFecha := qSrc.FieldByName('FechaOpe').AsDateTime
        else if not qSrc.FieldByName('Fecha').IsNull then
          dtFecha := qSrc.FieldByName('Fecha').AsDateTime
        else
          dtFecha := Now;
        fNeto := qSrc.FieldByName('Neto').AsFloat;
        qFac.ParamByName('num').AsString    := sNumFac;
        qFac.ParamByName('serie').AsString  := sSerieFac;
        qFac.ParamByName('fecha').AsDateTime := Trunc(dtFecha);
        qFac.ParamByName('emp').AsString    := sEmp;
        if Trim(qSrc.FieldByName('Cliente').AsString) <> '' then
          qFac.ParamByName('cli').AsString  :=
            Trim(qSrc.FieldByName('Cliente').AsString)
        else
          qFac.ParamByName('cli').AsString  := '0';
        // Desglose de IVA por bandas N/R/S/E desde las bandas del legacy.
        FijarIvaCabecera(qSrc, qFac, fNeto);
        qFac.ParamByName('liq').AsFloat   := fNeto;
        qFac.ParamByName('cajero').AsString :=
          IntToStr(qSrc.FieldByName('VendedorCab').AsInteger);
        qFac.ParamByName('alm').AsString   := sAlm;
        qFac.ParamByName('caja').AsString  := IntToStr(iCaja);
        qFac.ParamByName('numop').AsString := sNumOp;
        RellenarAuditoria(qFac, Eng.Usuario);
        try
          qFac.ExecSQL;
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('factura', sSerieFac + '/' + sNumFac, E.Message,
              '', 'requiere Almacenes/Clientes migrados');
            raise;
          end;
        end;
      end;
      // Línea de factura desde la línea de caja.
      sArt := Trim(qSrc.FieldByName('Articulo').AsString);
      if EsArticuloGenerico(sArt) then
      begin
        sTipoArt := 'SERVICIO';
        sArt     := '';
        sUni     := '';
      end
      else
      begin
        sTipoArt := 'ESTANDAR';
        sUni     := ConstruirCodigoUnidad(sArt,
                      Trim(qSrc.FieldByName('DescColor').AsString),
                      Trim(qSrc.FieldByName('Talla').AsString));
      end;
      qLin.ParamByName('num').AsString   := sNumFac;
      qLin.ParamByName('serie').AsString := sSerieFac;
      qLin.ParamByName('emp').AsString   := sEmp;
      qLin.ParamByName('linea').AsString :=
        Format('%.4d', [qSrc.FieldByName('NroLinea').AsInteger]);
      if sArt <> '' then
        qLin.ParamByName('art').AsString := sArt
      else
        qLin.ParamByName('art').Clear;
      if sUni <> '' then
        qLin.ParamByName('uni').AsString := sUni
      else
        qLin.ParamByName('uni').Clear;
      qLin.ParamByName('tipoart').AsString := sTipoArt;
      qLin.ParamByName('cant').AsFloat  := qSrc.FieldByName('Cantidad').AsFloat;
      qLin.ParamByName('desc').AsString :=
        Copy(Trim(qSrc.FieldByName('Descripcion').AsString), 1, 100);
      qLin.ParamByName('pdto').AsFloat  := qSrc.FieldByName('PorDto').AsFloat;
      qLin.ParamByName('psiva').AsFloat := qSrc.FieldByName('PrecioSIva').AsFloat;
      qLin.ParamByName('piva').AsFloat  := qSrc.FieldByName('PorIva').AsFloat;
      qLin.ParamByName('pciva').AsFloat := qSrc.FieldByName('PrecioCIva').AsFloat;
      qLin.ParamByName('total').AsFloat := qSrc.FieldByName('NetoCIva').AsFloat;
      qLin.ParamByName('totalsiva').AsFloat :=
        qSrc.FieldByName('NetoSIva').AsFloat;
      qLin.ParamByName('vend').AsString :=
        IntToStr(qSrc.FieldByName('VendedorLin').AsInteger);
      qLin.ParamByName('alm').AsString   := sAlm;
      qLin.ParamByName('caja').AsString  := IntToStr(iCaja);
      qLin.ParamByName('numop').AsString := sNumOp;
      // Enlace al movimiento de almacén migrado (mismo prefijo 'MH').
      if qSrc.FieldByName('NumeroMovArt').AsInteger > 0 then
        qLin.ParamByName('nmov').AsString :=
          'MH' + Format('%.10d', [qSrc.FieldByName('NumeroMovArt').AsInteger])
      else
        qLin.ParamByName('nmov').Clear;
      RellenarAuditoria(qLin, Eng.Usuario);
      try
        qLin.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('factura_linea', sSerieFac + '/' + sNumFac,
            E.Message, Format('linea=%d',
              [qSrc.FieldByName('NroLinea').AsInteger]), '');
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qLin.Free;
    qFac.Free;
    qSrc.Free;
  end;
end;

end.
