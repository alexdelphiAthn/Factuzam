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
{      NUMERO_FAC = NroDoc (nº de factura del legacy, correlativo por Serie)   }
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
  UMigEngine, UMigCatalogo;

procedure MigrarFacturas(const Eng: IContextoMigracion; var Stats: TMigStats);
// Enlace masivo movimiento->factura (REF_MOV) como dominio APARTE: se saco
// de los dominios de facturas para que NO bloquee la importacion de las
// facturas. Cubre simplificadas y normales en un solo UPDATE. Corre el
// ultimo en su grafo de dependencias; si se cancela, las facturas ya estan.
procedure MigrarEnlaceMovimientosFacturas(const Eng: IContextoMigracion;
                                          var Stats: TMigStats);

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

procedure LimpiarMigracionPrevia(Eng: IContextoMigracion);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    q.SQL.Text :=
      'DELETE l FROM fza_facturas_lineas l ' +
      'JOIN fza_facturas f ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN ' +
      '                    AND f.SERIE_FAC = l.SERIE_FAC_FACLIN ' +
      'WHERE l.USUARIO_ALTA = :u ' +
      '  AND f.USUARIO_ALTA = :u ' +
      '  AND COALESCE(f.TIPO_FAC, '''') = ''SIMPLIFICADA''';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_facturas ' +
      'WHERE USUARIO_ALTA = :u ' +
      '  AND COALESCE(TIPO_FAC, '''') = ''SIMPLIFICADA''';
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

// Desglose de IVA por bandas N/R/S/E calculado a partir de las 4 bandas que
// el legacy trae en occaj (BaseImp/PorcenIva/CuotaIVA 1-4). Cada banda legacy
// se clasifica por su % (BandaIva) y se acumula. La cuota se calcula si el
// legacy no la trae (filas antiguas: CuotaIVA NULL). Si no hay bandas pero sí
// Neto, se deriva una banda única del total. Devuelve el resultado en un
// record para poder formatearlo en el INSERT masivo.
type
  TIvaCab = record
    Pivan, Tivan, Basein, Pren, Tren: Double;  // banda Normal
    Pivar, Tivar, Basier, Prer, Trer: Double;  // banda Reducido
    Pivas, Tivas, Baseis, Pres, Tres: Double;  // banda Superreducido
    Pivae, Tivae, Baseie, Pree, Tree: Double;  // banda Exento
    Bases, Imp:                       Double;  // base y total impuestos
  end;
procedure CalcularIvaCabecera(qSrc: TUniQuery; const fNeto: Double;
                              var R: TIvaCab);
var
  aBase, aCuota, aRate:    array[0..3] of Double;
  aReCuota, aReRate:       array[0..3] of Double;
  i, b:                    Integer;
  base, rate, cuota:       Double;
  porcRe, cuotaRe:         Double;
  fBases, fImp, fReTot:    Double;
begin
  for b := 0 to 3 do
  begin
    aBase[b]    := 0;
    aCuota[b]   := 0;
    aRate[b]    := 0;
    aReCuota[b] := 0;
    aReRate[b]  := 0;
  end;
  for i := 1 to 4 do
  begin
    base    := qSrc.FieldByName('BaseImp'   + IntToStr(i)).AsFloat;
    rate    := qSrc.FieldByName('PorcenIva' + IntToStr(i)).AsFloat;
    cuota   := qSrc.FieldByName('CuotaIVA'  + IntToStr(i)).AsFloat;
    porcRe  := qSrc.FieldByName('PorcenRecargo' + IntToStr(i)).AsFloat;
    cuotaRe := qSrc.FieldByName('CuotaRE'   + IntToStr(i)).AsFloat;
    if (base <> 0) or (cuota <> 0) then
    begin
      if (cuota = 0) and (rate > 0) then
        cuota := base * rate / 100;
      if (cuotaRe = 0) and (porcRe > 0) then
        cuotaRe := base * porcRe / 100;
      // El recargo de equivalencia (RE) cae en la misma banda que su IVA.
      b := BandaIva(rate);
      aBase[b]    := aBase[b]    + base;
      aCuota[b]   := aCuota[b]   + cuota;
      aReCuota[b] := aReCuota[b] + cuotaRe;
      if rate > aRate[b] then
        aRate[b] := rate;
      if porcRe > aReRate[b] then
        aReRate[b] := porcRe;
    end;
  end;
  fBases := aBase[0] + aBase[1] + aBase[2] + aBase[3];
  fImp   := aCuota[0] + aCuota[1] + aCuota[2] + aCuota[3];
  fReTot := aReCuota[0] + aReCuota[1] + aReCuota[2] + aReCuota[3];
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
  R.Pivan  := aRate[0];
  R.Tivan  := aCuota[0];
  R.Basein := aBase[0];
  R.Pren   := aReRate[0];
  R.Tren   := aReCuota[0];
  R.Pivar  := aRate[1];
  R.Tivar  := aCuota[1];
  R.Basier := aBase[1];
  R.Prer   := aReRate[1];
  R.Trer   := aReCuota[1];
  R.Pivas  := aRate[2];
  R.Tivas  := aCuota[2];
  R.Baseis := aBase[2];
  R.Pres   := aReRate[2];
  R.Tres   := aReCuota[2];
  R.Pivae  := aRate[3];
  R.Tivae  := aCuota[3];
  R.Baseie := aBase[3];
  R.Pree   := aReRate[3];
  R.Tree   := aReCuota[3];
  R.Bases  := fBases;
  // TOTAL_IMPUESTOS = IVA + RE de todas las bandas.
  R.Imp    := fImp + fReTot;
end;

// =========================================================================
//  Enlaces post-insercion (empresa emisora, flags y referencia de
//  movimientos). Corren al final, ya con cabeceras, lineas y movimientos
//  presentes (por eso facturas va en una wave posterior a movimientos).
// =========================================================================
procedure EnlazarFacturas(Eng: IContextoMigracion);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    // 1) Datos de la EMPRESA EMISORA denormalizados en la cabecera (estaban
    //    vacios) + flags por defecto a 'N' (fecha entrega, descripcion
    //    ampliada, crear articulos). LEFT JOIN: si la empresa no se migro,
    //    los datos quedan NULL pero los flags se fijan igual.
    q.SQL.Text :=
      'UPDATE fza_facturas f ' +
      'LEFT JOIN fza_empresas e ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_FAC ' +
      'SET f.ESFECHADEENTREGA_FAC      = ''N'', ' +
      '    f.ESDESCRIPCIONES_AMP_FAC   = ''N'', ' +
      '    f.ESCREARARTICULOS_FAC      = ''N'', ' +
      // Venta detalle: el cliente no tiene IRPF/retencion (en el esquema la
      // columna trae DEFAULT 'S'; en este tipo de negocio nunca aplica).
      '    f.ESRETENCIONES_CLIENTE_FAC = ''N'', ' +
      '    f.RAZON_SOCIAL_EMPRESA_FAC  = e.RAZON_SOCIAL_EMP, ' +
      '    f.NIF_EMPRESA_FAC           = e.NIF_EMP, ' +
      '    f.MOVIL_EMPRESA_FAC         = e.MOVIL_EMP, ' +
      '    f.EMAIL_EMPRESA_FAC         = e.EMAIL_EMP, ' +
      '    f.DIRECCION1_EMPRESA_FAC    = e.DIRECCION1_EMP, ' +
      '    f.DIRECCION2_EMPRESA_FAC    = e.DIRECCION2_EMP, ' +
      '    f.POBLACION_EMPRESA_FAC     = e.POBLACION_EMP, ' +
      '    f.PROVINCIA_EMPRESA_FAC     = e.PROVINCIA_EMP, ' +
      '    f.CODIGO_POSTAL_EMPRESA_FAC = e.CODIGO_POSTAL_EMP ' +
      'WHERE f.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    Eng.Registro.Log('  facturas: datos de empresa emisora y flags (N) rellenados.');
    // 1b) Datos del CLIENTE denormalizados en la cabecera (razon social,
    //     NIF, contacto y direccion), desde fza_clientes. JOIN (no LEFT):
    //     las facturas a publico/anonimo (cliente '0' o inexistente) no
    //     casan y quedan con los datos de cliente vacios, que es lo correcto
    //     para un ticket simplificado sin cliente nominal.
    q.SQL.Text :=
      'UPDATE fza_facturas f ' +
      'JOIN fza_clientes c ON c.CODIGO_CLI_CLI = f.CODIGO_CLI_FAC ' +
      'SET f.RAZON_SOCIAL_CLIENTE_FAC  = c.RAZON_SOCIAL_CLI, ' +
      '    f.NIF_CLIENTE_FAC           = c.NIF_CLI, ' +
      '    f.MOVIL_CLIENTE_FAC         = c.MOVIL_CLI, ' +
      '    f.EMAIL_CLIENTE_FAC         = c.EMAIL_CLI, ' +
      '    f.DIRECCION1_CLIENTE_FAC    = c.DIRECCION1_CLI, ' +
      '    f.DIRECCION2_CLIENTE_FAC    = c.DIRECCION2_CLI, ' +
      '    f.POBLACION_CLIENTE_FAC     = c.POBLACION_CLI, ' +
      '    f.PROVINCIA_CLIENTE_FAC     = c.PROVINCIA_CLI, ' +
      '    f.CODIGO_POSTAL_CLIENTE_FAC = c.CODIGO_POSTAL_CLI ' +
      'WHERE f.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    Eng.Registro.Log('  facturas: datos de cliente rellenados.');
    // El enlace MOVIMIENTO -> FACTURA (UPDATE masivo sobre
    // fza_movimientos_almacen) ya NO se hace aqui: vive en el dominio
    // independiente MigrarEnlaceMovimientosFacturas, que corre el ultimo para
    // no bloquear la importacion de las facturas.
  finally
    q.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarFacturas(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cWhere =
    'WHERE c.TipoDoc = ''VE'' AND ISNULL(c.Tipo, '''') <> ''C''';
  cSelCab =
    'SELECT c.Empresa, c.Almacen, c.Caja, c.Operacion, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       c.Ejercicio, ISNULL(c.Serie, '''') AS Serie, ' +
    '       c.FechaOpe, c.Fecha, c.Vendedor AS VendedorCab, ' +
    '       ISNULL(c.NroDoc, 0) AS NroDoc, ' +
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
    '       ISNULL(c.PorcenRecargo1, 0) AS PorcenRecargo1, ' +
    '       ISNULL(c.CuotaRE1, 0) AS CuotaRE1, ' +
    '       ISNULL(c.PorcenRecargo2, 0) AS PorcenRecargo2, ' +
    '       ISNULL(c.CuotaRE2, 0) AS CuotaRE2, ' +
    '       ISNULL(c.PorcenRecargo3, 0) AS PorcenRecargo3, ' +
    '       ISNULL(c.CuotaRE3, 0) AS CuotaRE3, ' +
    '       ISNULL(c.PorcenRecargo4, 0) AS PorcenRecargo4, ' +
    '       ISNULL(c.CuotaRE4, 0) AS CuotaRE4 ' +
    'FROM dbo.occaj c ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = c.Empresa ' +
    '                       AND alm.Almacen = c.Almacen ' +
    cWhere;
  cSelLin =
    'SELECT c.Empresa, c.Almacen, c.Caja, c.Operacion, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       c.Ejercicio, ISNULL(c.Serie, '''') AS Serie, ' +
    '       ISNULL(c.NroDoc, 0) AS NroDoc, ' +
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
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE ''0'' ' +
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
    cWhere;
  cColsFac =
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, ESCONSOLIDADA_FAC, ' +
    'CODIGO_EMP_FAC, CODIGO_CLI_FAC, ' +
    'PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
    'PORCENTAJE_REN_FAC, TOTAL_REN_FAC, ' +
    'PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    'PORCENTAJE_RER_FAC, TOTAL_RER_FAC, ' +
    'PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, TOTAL_BASEI_IVAS_FAC, ' +
    'PORCENTAJE_RES_FAC, TOTAL_RES_FAC, ' +
    'PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    'PORCENTAJE_REE_FAC, TOTAL_REE_FAC, ' +
    'TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, TOTAL_LIQUIDO_FAC, ' +
    'FORMA_PAGO_FAC, CODIGO_CAJERO_FAC, CODIGO_ALM_FAC, CODIGO_CAJA_FAC, ' +
    'NUMERO_OPERACION_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
    'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
    'TIPO_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
    'DESCRIPCION_ARTICULO_FACLIN, PORCENTAJE_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    'TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, CODIGO_VENDEDOR_FACLIN, ' +
    'CODIGO_ALM_FACLIN, CODIGO_CAJA_FACLIN, NUMERO_OPERACION_FACLIN, ' +
    'NUMERO_MOV_FACLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin:              TUniQuery;
  bulkFac, bulkLin:        TBulkInsert;
  fs:                      TFormatSettings;
  iEmp, iAlm, iCaja, iOpe: Integer;
  iNroDoc:                 Integer;
  sEmp, sAlm, sNumOp:      string;
  sNumFac, sSerieFac:      string;
  sArt, sUni, sTipoArt:    string;
  sCli, sLinea, sNmov:     string;
  sAhora, sUser, sFecha:   string;
  sFila:                   string;
  iva:                     TIvaCab;
  fNeto:                   Double;
  dtFecha:                 TDateTime;
  // Formateo numérico con punto decimal (en-US) para los literales SQL.
  function F(v: Double): string;
  begin
    Result := FloatToStr(v, fs);
  end;
begin
  fs := TFormatSettings.Create('en-US');
  LimpiarMigracionPrevia(Eng);
  sAhora := DateTimeASQL(Now);
  sUser  := ValorOrNull(Eng.Usuario);
  // DOS PASADAS, sin ORDER BY. El ORDER BY que agrupaba las líneas por
  // operación obligaba a SQL Server a ORDENAR ~774k filas anchas del JOIN
  // occaj⨝occajarp ANTES de devolver la primera fila: el .Open del cursor
  // se quedaba "petado" en 0/N varios minutos. Separando cabeceras (occaj,
  // una por operación, sin agrupar) de líneas (occajarp, cada una
  // independiente) ningún cursor ordena y la barra avanza desde la fila 1.
  // --- PASO 1: cabeceras (occaj → fza_facturas) ---
  bulkFac := TBulkInsert.Create(Eng.Datos.ConexionDestino, 'fza_facturas', cColsFac, 2000);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Registro.Log('  facturas 1/2: cabeceras (occaj)...');
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.occaj c ' + cWhere));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.Cancelacion.EstaCancelada then
      begin
        Eng.Registro.Log('  Cancelacion detectada en Facturas (cabeceras)...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      iEmp  := qCab.FieldByName('Empresa').AsInteger;
      iAlm  := qCab.FieldByName('Almacen').AsInteger;
      iCaja := qCab.FieldByName('Caja').AsInteger;
      iOpe  := qCab.FieldByName('Operacion').AsInteger;
      iNroDoc := qCab.FieldByName('NroDoc').AsInteger;
      sEmp  := IntToStr(iEmp);
      sAlm  := UpperCase(Trim(qCab.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      sNumOp    := Format('%.8d', [iOpe]);
      sSerieFac := Format('%d.%s', [qCab.FieldByName('Ejercicio').AsInteger,
                     Trim(qCab.FieldByName('Serie').AsString)]);
      // NUMERO_FAC = NroDoc: en occaj el nº de FACTURA es NroDoc (correlativo
      // por Serie para las ventas), NO la Operacion (id interno) ni un
      // compuesto con Almacen/Caja. SERIE_FAC = Ejercicio.Serie discrimina, asi
      // (CODIGO_EMP, SERIE, NUMERO) identifica la factura. Debe coincidir con
      // SERIE/NUMERO_FAC_OPCAJA de Ventas (mismo NroDoc).
      sNumFac   := IntToStr(iNroDoc);
      if not qCab.FieldByName('FechaOpe').IsNull then
        dtFecha := qCab.FieldByName('FechaOpe').AsDateTime
      else if not qCab.FieldByName('Fecha').IsNull then
        dtFecha := qCab.FieldByName('Fecha').AsDateTime
      else
        dtFecha := Now;
      sFecha := DateTimeASQL(Trunc(dtFecha));
      fNeto  := qCab.FieldByName('Neto').AsFloat;
      sCli   := Trim(qCab.FieldByName('Cliente').AsString);
      if sCli = '' then
        sCli := '0';
      // Desglose de IVA por bandas N/R/S/E desde las bandas del legacy.
      CalcularIvaCabecera(qCab, fNeto, iva);
      // 39 columnas en cColsFac. TIPO_FAC ('SIMPLIFICADA'),
      // ESCONSOLIDADA_FAC ('S') y FORMA_PAGO_FAC ('CONTADO') son literales.
      sFila := Format(
        '%s, %s, %s, ''SIMPLIFICADA'', ''S'', %s, %s, ' +
        '%s, %s, %s, %s, %s, ' +
        '%s, %s, %s, %s, %s, ' +
        '%s, %s, %s, %s, %s, ' +
        '%s, %s, %s, %s, %s, ' +
        '%s, %s, %s, ' +
        '''CONTADO'', %s, %s, %s, %s, ' +
        '%s, %s, %s, %s',
        [ValorOrNull(sNumFac), ValorOrNull(sSerieFac), sFecha,
         ValorOrNull(sEmp), ValorOrNull(sCli),
         F(iva.Pivan), F(iva.Tivan), F(iva.Basein),
         F(iva.Pren),  F(iva.Tren),
         F(iva.Pivar), F(iva.Tivar), F(iva.Basier),
         F(iva.Prer),  F(iva.Trer),
         F(iva.Pivas), F(iva.Tivas), F(iva.Baseis),
         F(iva.Pres),  F(iva.Tres),
         F(iva.Pivae), F(iva.Tivae), F(iva.Baseie),
         F(iva.Pree),  F(iva.Tree),
         F(iva.Bases), F(iva.Imp),  F(fNeto),
         ValorOrNull(IntToStr(qCab.FieldByName('VendedorCab').AsInteger)),
         ValorOrNull(sAlm), ValorOrNull(IntToStr(iCaja)),
         ValorOrNull(sNumOp),
         sAhora, sAhora, sUser, sUser]);
      try
        bulkFac.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.LogError('factura', sSerieFac + '/' + sNumFac, E.Message,
            '', 'requiere Almacenes/Clientes migrados');
        end;
      end;
      qCab.Next;
    end;
    bulkFac.FlushPendiente;
  finally
    bulkFac.Free;
    qCab.Free;
  end;
  // --- PASO 2: líneas (occajarp → fza_facturas_lineas) ---
  bulkLin := TBulkInsert.Create(Eng.Datos.ConexionDestino, 'fza_facturas_lineas',
                                cColsLin, 2000);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Registro.Log('  facturas 2/2: lineas (occajarp)...');
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.occajarp l ' +
      'INNER JOIN dbo.occaj c ON c.Empresa = l.Empresa ' +
      '                      AND c.Almacen = l.Almacen ' +
      '                      AND c.Caja    = l.Caja ' +
      '                      AND c.Operacion = l.Operacion ' + cWhere));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.Cancelacion.EstaCancelada then
      begin
        Eng.Registro.Log('  Cancelacion detectada en Facturas (lineas)...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      iEmp  := qLin.FieldByName('Empresa').AsInteger;
      iAlm  := qLin.FieldByName('Almacen').AsInteger;
      iCaja := qLin.FieldByName('Caja').AsInteger;
      iOpe  := qLin.FieldByName('Operacion').AsInteger;
      iNroDoc := qLin.FieldByName('NroDoc').AsInteger;
      sEmp  := IntToStr(iEmp);
      sAlm  := UpperCase(Trim(qLin.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      sNumOp    := Format('%.8d', [iOpe]);
      sSerieFac := Format('%d.%s', [qLin.FieldByName('Ejercicio').AsInteger,
                     Trim(qLin.FieldByName('Serie').AsString)]);
      // NUMERO_FAC = NroDoc (igual que la cabecera) para que la linea enlace
      // con su factura. NroDoc llega del JOIN a occaj (occajarp no lo tiene).
      sNumFac   := IntToStr(iNroDoc);
      sArt := Trim(qLin.FieldByName('Articulo').AsString);
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
                      Trim(qLin.FieldByName('DescColor').AsString),
                      Trim(qLin.FieldByName('Talla').AsString));
      end;
      sLinea := Format('%.4d', [qLin.FieldByName('NroLinea').AsInteger]);
      // Enlace al movimiento de almacén migrado (mismo prefijo 'MH').
      if qLin.FieldByName('NumeroMovArt').AsInteger > 0 then
        sNmov := 'MH' + Format('%.10d',
                   [qLin.FieldByName('NumeroMovArt').AsInteger])
      else
        sNmov := '';
      // 25 columnas en cColsLin. TIPO_IVA_ARTICULO_FACLIN es literal 'N'.
      sFila := Format(
        '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ''N'', ' +
        '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
        [ValorOrNull(sNumFac), ValorOrNull(sSerieFac), ValorOrNull(sEmp),
         ValorOrNull(sLinea), ValorOrNull(sArt), ValorOrNull(sUni),
         ValorOrNull(sTipoArt),
         F(qLin.FieldByName('Cantidad').AsFloat),
         ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString),
                          1, 100)),
         F(qLin.FieldByName('PorDto').AsFloat),
         F(qLin.FieldByName('PrecioSIva').AsFloat),
         F(qLin.FieldByName('PorIva').AsFloat),
         F(qLin.FieldByName('PrecioCIva').AsFloat),
         F(qLin.FieldByName('NetoCIva').AsFloat),
         F(qLin.FieldByName('NetoSIva').AsFloat),
         ValorOrNull(IntToStr(qLin.FieldByName('VendedorLin').AsInteger)),
         ValorOrNull(sAlm), ValorOrNull(IntToStr(iCaja)),
         ValorOrNull(sNumOp), ValorOrNull(sNmov),
         sAhora, sAhora, sUser, sUser]);
      try
        bulkLin.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.LogError('factura_linea', sSerieFac + '/' + sNumFac,
            E.Message, Format('linea=%d',
              [qLin.FieldByName('NroLinea').AsInteger]), '');
        end;
      end;
      qLin.Next;
    end;
    bulkLin.FlushPendiente;
  finally
    bulkLin.Free;
    qLin.Free;
  end;
  // Persistimos cabeceras y lineas ANTES del post-proceso. Si un enlace
  // fallara dentro de la transaccion del dominio arrastraria un ROLLBACK que
  // dejaba fza_facturas VACIA; con el commit previo las facturas quedan
  // guardadas pase lo que pase. El enlace pesado (movimientos) ya no esta
  // aqui: corre en su propio dominio al final.
  Eng.Datos.ConexionDestino.Commit;
  if not Eng.Cancelacion.EstaCancelada then
  begin
    try
      EnlazarFacturas(Eng);
    except
      on E: Exception do
        Eng.Registro.LogError('facturas_enlace', '', E.Message, '',
          'enlace post-insercion fallido; las facturas YA estan guardadas');
    end;
  end;
  // Dejamos una transaccion activa para el Commit final del motor.
  Eng.Datos.ConexionDestino.StartTransaction;
end;

// =========================================================================
//  Enlace movimiento -> factura (dominio independiente, corre EL ULTIMO)
// =========================================================================
//  Rellena en fza_movimientos_almacen (1) las columnas *_DOC_REF_MOV de
//  trazabilidad para todas las facturas y (2) el documento propio *_DOC_MOV
//  (SERIE/NUMERO/LINEA) de las SIMPLIFICADAS, que es lo que lee la pestana
//  "Movimientos" de la factura. Es un UPDATE masivo sobre la tabla mas grande
//  del sistema; por eso se saco
//  de los dominios de facturas (bloqueaba la importacion) a un dominio propio
//  que corre el ultimo. Cubre simplificadas y normales en una sola pasada
//  (cualquier linea migrada con NUMERO_MOV_FACLIN). Es idempotente y
//  cancelable: si se interrumpe, las facturas YA estan importadas y este
//  enlace se puede relanzar solo.
procedure MigrarEnlaceMovimientosFacturas(const Eng: IContextoMigracion;
                                          var Stats: TMigStats);
var
  q: TUniQuery;
begin
  // Salimos de la transaccion del dominio: trabajamos en autocommit para no
  // mantener un bloqueo gigante durante todo el UPDATE.
  Eng.Datos.ConexionDestino.Commit;
  try
    // Indice que permite conducir desde la linea (pocas filas) y resolver el
    // movimiento por su PK (NUMERO_MOV), en vez de escanear toda la tabla de
    // movimientos.
    AsegurarIndice(Eng, 'fza_facturas_lineas', 'IDX_FACLIN_NUMMOV',
      '`NUMERO_MOV_FACLIN`');
    q := TUniQuery.Create(nil);
    try
      q.Connection := Eng.Datos.ConexionDestino;
      // SOLO SIMPLIFICADAS: en el ticket la venta ES la factura, asi que el
      // movimiento le pertenece. En venta mayor NO se toca, porque el stock se
      // mueve en el ALBARAN (su pestana usa TIPO_DOC_REF_MOV='AV'); reasignarlo
      // a la factura rompería el enlace del albaran.
      // Se fija el documento PROPIO del movimiento (*_DOC_MOV): la pestana
      // "Movimientos" de la factura (unqryMovimientosFac) filtra por
      // TIPO_DOC_MOV IN ('FC','VE') AND SERIE_DOC_MOV = SERIE_FAC AND
      // NUMERO_DOC_MOV = NUMERO_FAC. La migracion de movimientos ya guarda
      // SERIE_DOC_MOV con ejercicio ('2026.A1'), igual que SERIE_FAC. Este
      // enlace lo reafirma desde la linea de factura y rellena LINEA_MOV
      // para que la pestana muestre los movimientos de la simplificada.
      // TIPO_DOC_MOV se deja como esta ('VE', ya aceptado por la pestana)
      // para no alterar el calculo de stock.
      // Se rellenan tambien las columnas *_DOC_REF_MOV (trazabilidad / rejilla
      // de movimientos del articulo). STRAIGHT_JOIN conduce desde la linea.
      Eng.Registro.Log('  enlazando movimientos con su factura simplificada...');
      q.SQL.Text :=
        'UPDATE fza_facturas_lineas l ' +
        'STRAIGHT_JOIN fza_facturas f ' +
        '  ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN ' +
        ' AND f.SERIE_FAC = l.SERIE_FAC_FACLIN ' +
        'STRAIGHT_JOIN fza_movimientos_almacen m ' +
        '  ON m.NUMERO_MOV = l.NUMERO_MOV_FACLIN ' +
        'SET m.SERIE_DOC_MOV      = l.SERIE_FAC_FACLIN, ' +
        '    m.NUMERO_DOC_MOV     = l.NUMERO_FAC_FACLIN, ' +
        '    m.LINEA_MOV          = l.LINEA_FACLIN, ' +
        '    m.TIPO_DOC_REF_MOV   = ''FC'', ' +
        '    m.SERIE_DOC_REF_MOV  = l.SERIE_FAC_FACLIN, ' +
        '    m.NUMERO_DOC_REF_MOV = l.NUMERO_FAC_FACLIN, ' +
        '    m.LINEA_REF_MOV      = l.LINEA_FACLIN ' +
        'WHERE l.USUARIO_ALTA = :u ' +
        '  AND COALESCE(f.TIPO_FAC, '''') = ''SIMPLIFICADA'' ' +
        '  AND l.NUMERO_MOV_FACLIN IS NOT NULL ' +
        '  AND l.NUMERO_MOV_FACLIN <> ''''';
      q.ParamByName('u').AsString := Eng.Usuario;
      q.ExecSQL;
      Inc(Stats.Insertadas);
      Eng.Registro.Log('  movimientos de simplificadas enlazados a su factura.');
    finally
      q.Free;
    end;
  except
    on E: Exception do
    begin
      Inc(Stats.Errores);
      Eng.Registro.LogError('enlace_mov_facturas', '', E.Message, '',
        'las facturas YA estan importadas; este enlace es idempotente y se '
        + 'puede relanzar solo');
    end;
  end;
  // Dejamos una transaccion activa para el Commit final del motor.
  Eng.Datos.ConexionDestino.StartTransaction;
end;

initialization
  RegistrarMigracion(
    'facturas',
    'Facturas de venta (occajarp)',
    'dbo.occaj/occajarp → facturas y líneas',
    ['ventas', 'movimientos'],
    MigrarFacturas);
  RegistrarMigracion(
    'enlace_mov_facturas',
    'Enlace movimientos <-> facturas',
    'líneas de factura → movimientos de almacén',
    ['facturas', 'facturas_venta_mayor', 'remesas_compra',
     'vales', 'arqueos'],
    MigrarEnlaceMovimientosFacturas);

end.
