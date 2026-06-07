{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigCompras                                               }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Importa la cadena de COMPRAS del legacy a Factuzam:                       }
{      dbo.ocped       (cab. pedido compra, TipoDoc 'PP') → fza_pedidos_compra }
{      dbo.ocpedarp    (líneas pedido)                    → fza_pedidos_compra_lineas
{      dbo.ocalbpro    (cab. albarán entrada, TipoDoc 'AE') → fza_albaranes_compra
{      dbo.ocalbproarp (líneas albarán)                   → fza_albaranes_compra_lineas
{                                                                              }
{    Modelo PLANO (decisión del usuario): una línea Factuzam por cada fila     }
{    del legacy (un SKU concreto Articulo/Color/Talla), con su almacén en la   }
{    propia línea. NO se generan celdas (`*_celdas`, la rejilla pivotada de    }
{    tallas) — la distribución queda en el almacén de cada línea; las celdas   }
{    se dejan para una migración futura con distribución.                      }
{                                                                              }
{    Enlaces:                                                                  }
{      - Cabecera ← proveedor: los datos del proveedor ya vienen               }
{        denormalizados en ocped/ocalbpro (RazonSocial, NIF, dirección…), se   }
{        copian tal cual a las columnas *_PRV_*.                               }
{      - Cabecera ← empresa emisora: se rellena al final desde fza_empresas    }
{        (igual que en facturas de venta).                                     }
{      - Albarán → pedido: NUMERO/SERIE_PED_ALBC con la MISMA clave que genera }
{        este módulo para el pedido ('<Ejercicio>.<Serie>' / NroPedido a 6).   }
{                                                                              }
{    Clave Factuzam (PK NUMERO+SERIE):                                         }
{      SERIE  = '<Ejercicio>.<Serie>'   (p.ej. '2007.90')                      }
{      NUMERO = NroPedido / NroAlbaran a 6 dígitos                             }
{                                                                              }
{    IVA: 4 bandas legacy (ImpBaseImp/PorIVA/CuotaIVA 1-4) clasificadas en     }
{    N/R/S/E por su %. Totales (bases/impuestos/líquido) del propio legacy.    }
{    El recargo de equivalencia (RE) no aplica a la cabecera de compra.        }
{                                                                              }
{    Idempotente: borra al arrancar lo migrado por el usuario y reinserta      }
{    (INSERT IGNORE por lotes para las líneas/cabeceras).                      }
{                                                                              }
{    NO genera stock: los movimientos de entrada ya entran por la migración    }
{    de Movimientos (ocmovarp). El enlace movimiento↔albarán (REF_MOV) se      }
{    deja pendiente (la línea de albarán no guarda NUMERO_MOV).                }
{******************************************************************************}
unit inLibMigCompras;

interface

uses
  UMigEngine;

procedure MigrarPedidosCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarAlbaranesCompra(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni;

const
  BATCH = 2000;

var
  // Formato numérico con punto decimal para los literales SQL.
  fsCompras: TFormatSettings;

// =========================================================================
//  Helpers compartidos
// =========================================================================

function F(v: Double): string;
begin
  Result := FloatToStr(v, fsCompras);
end;

function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// SKU ARTICULO/COLOR/TALLA con placeholders, idéntico al resto de la
// migración (para que las líneas referencien los mismos SKUs).
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then
    sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then
    sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

// Clasifica un % de IVA en banda Factuzam: 0=Normal,1=Reducido,2=Super,3=Exento.
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

type
  // Desglose de IVA de cabecera de compra por bandas N/R/S/E (sólo % y cuota;
  // la cabecera de compra no guarda base por banda ni RE).
  TIvaCompra = record
    Pn, Tn, Pr, Tr, Ps, Ts, Pe, Te: Double;
  end;

// Lee las 4 bandas legacy (ImpBaseImp/PorIVA/CuotaIVA 1-4) y las acumula por
// banda. Sirve para ocped y ocalbpro (mismos nombres de columna).
procedure CalcularIvaCompra(q: TUniQuery; var R: TIvaCompra);
var
  i, b:                Integer;
  base, rate, cuota:   Double;
  aRate, aCuota:       array[0..3] of Double;
begin
  for b := 0 to 3 do
  begin
    aRate[b]  := 0;
    aCuota[b] := 0;
  end;
  for i := 1 to 4 do
  begin
    base  := q.FieldByName('ImpBaseImp' + IntToStr(i)).AsFloat;
    rate  := q.FieldByName('PorIVA' + IntToStr(i)).AsFloat;
    cuota := q.FieldByName('CuotaIVA' + IntToStr(i)).AsFloat;
    if (base <> 0) or (cuota <> 0) then
    begin
      if (cuota = 0) and (rate > 0) then
        cuota := base * rate / 100;
      b := BandaIva(rate);
      aCuota[b] := aCuota[b] + cuota;
      if rate > aRate[b] then
        aRate[b] := rate;
    end;
  end;
  R.Pn := aRate[0];
  R.Tn := aCuota[0];
  R.Pr := aRate[1];
  R.Tr := aCuota[1];
  R.Ps := aRate[2];
  R.Ts := aCuota[2];
  R.Pe := aRate[3];
  R.Te := aCuota[3];
end;

// Borra las filas creadas por este usuario en una tabla destino (re-ejecutable).
procedure BorrarPorUsuario(Eng: TMigEngine; const sTabla: string);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := 'DELETE FROM ' + sTabla + ' WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Rellena los datos de empresa emisora denormalizados desde fza_empresas.
// sCab = tabla cabecera; sSuf = sufijo de columna (PEDC / ALBC).
procedure EnlazarEmpresaCompra(Eng: TMigEngine; const sTabla, sSuf: string);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      Format(
      'UPDATE %0:s f ' +
      'JOIN fza_empresas e ON e.CODIGO_EMP_EMP = f.CODIGO_EMP_%1:s ' +
      'SET f.RAZON_SOCIAL_EMPRESA_%1:s = e.RAZON_SOCIAL_EMP, ' +
      '    f.NIF_EMPRESA_%1:s          = e.NIF_EMP, ' +
      '    f.MOVIL_EMPRESA_%1:s        = e.MOVIL_EMP, ' +
      '    f.EMAIL_EMPRESA_%1:s        = e.EMAIL_EMP, ' +
      '    f.DIRECCION1_EMPRESA_%1:s   = e.DIRECCION1_EMP, ' +
      '    f.DIRECCION2_EMPRESA_%1:s   = e.DIRECCION2_EMP, ' +
      '    f.POBLACION_EMPRESA_%1:s    = e.POBLACION_EMP, ' +
      '    f.PROVINCIA_EMPRESA_%1:s    = e.PROVINCIA_EMP, ' +
      '    f.CODIGO_POSTAL_EMPRESA_%1:s = e.CODIGO_POSTAL_EMP ' +
      'WHERE f.USUARIO_ALTA = :u', [sTabla, sSuf]);
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Estado del pedido según lo recibido frente a lo pedido.
function EstadoPedido(fPed, fRcbda: Double): string;
begin
  if fRcbda <= 0 then
    Result := 'ABIERTO'
  else if fRcbda < fPed then
    Result := 'PARCIAL'
  else
    Result := 'RECIBIDO';
end;

// Mapa articulo -> ID_AC del tallaje (conjunto pivote de tallas), desde
// fza_articulos_conjuntos_asign. Cada linea lleva ese ID_AC_PIVOT para que
// el Mto ofrezca la rejilla de "tallas en horizontal" — igual que hace la
// materializacion nativa de una sesion de compra, que tambien guarda una
// linea por SKU (no celdas) con su ID_AC_PIVOT.
procedure CargarMapaTallaje(Eng: TMigEngine;
                            oMap: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT CODIGO_ART_ACA, ID_AC_ACA FROM fza_articulos_conjuntos_asign ' +
      'WHERE ID_VA_ACA = ''TAL''';
    q.Open;
    while not q.Eof do
    begin
      oMap.AddOrSetValue(
        UpperCase(Trim(q.FieldByName('CODIGO_ART_ACA').AsString)),
        q.FieldByName('ID_AC_ACA').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// Token SQL del ID_AC_PIVOT de un articulo: el numero si tiene tallaje, NULL
// si no (articulo escalar sin tallas).
function AcPivotToken(oMap: TDictionary<string, Integer>;
                      const sArt: string): string;
var iIdAc: Integer;
begin
  if oMap.TryGetValue(UpperCase(Trim(sArt)), iIdAc) and (iIdAc > 0) then
    Result := IntToStr(iIdAc)
  else
    Result := 'NULL';
end;

// Mapa de valores de la propiedad TEMPORADA: NOMBRE (UPPER) -> ID_PV_ARTPROP,
// para enlazar la temporada de la cabecera del pedido con su valor de catalogo.
procedure CargarMapaTemporada(Eng: TMigEngine;
                              oMap: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT PV, ID_PV_ARTPROP FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA''';
    q.Open;
    while not q.Eof do
    begin
      oMap.AddOrSetValue(
        UpperCase(Trim(q.FieldByName('PV').AsString)),
        q.FieldByName('ID_PV_ARTPROP').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// Token SQL del ID_PV de TEMPORADA por su nombre: el numero si existe, NULL si
// el documento no trae temporada o no esta en el catalogo de propiedades.
function TempPvToken(oMap: TDictionary<string, Integer>;
                     const sNombre: string): string;
var iId: Integer;
begin
  if (Trim(sNombre) <> '')
  and oMap.TryGetValue(UpperCase(Trim(sNombre)), iId) and (iId > 0) then
    Result := IntToStr(iId)
  else
    Result := 'NULL';
end;

// =========================================================================
//  1. Pedidos de compra
// =========================================================================

procedure MigrarPedidosCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cWhere = 'WHERE p.TipoDoc = ''PP''';
  cSelCab =
    'SELECT p.Empresa, p.Ejercicio, ISNULL(p.Serie, '''') AS Serie, ' +
    '       p.NroPedido, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       p.FechaPedido, p.FechaNecesaria, ' +
    '       ISNULL(p.Proveedor, '''') AS Proveedor, ' +
    '       ISNULL(p.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(p.NIF, '''') AS NIF, ' +
    '       ISNULL(p.Direccion1, '''') AS Direccion1, ' +
    '       ISNULL(p.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(p.Poblacion, '''') AS Poblacion, ' +
    '       ISNULL(p.Provincia, '''') AS Provincia, ' +
    '       ISNULL(p.CodPostal, '''') AS CodPostal, ' +
    '       ISNULL(p.DocExterno, '''') AS DocExterno, ' +
    '       ISNULL(p.FormaPago, '''') AS FormaPago, ' +
    '       ISNULL(p.CantidadPed, 0) AS CantidadPed, ' +
    '       ISNULL(p.CantidadRcbda, 0) AS CantidadRcbda, ' +
    '       ISNULL(p.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(p.PorIVA1, 0) AS PorIVA1, ISNULL(p.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(p.ImpBaseImp2, 0) AS ImpBaseImp2, ' +
    '       ISNULL(p.PorIVA2, 0) AS PorIVA2, ISNULL(p.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(p.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(p.PorIVA3, 0) AS PorIVA3, ISNULL(p.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(p.ImpBaseImp4, 0) AS ImpBaseImp4, ' +
    '       ISNULL(p.PorIVA4, 0) AS PorIVA4, ISNULL(p.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(p.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(p.TotalIVA, 0) AS TotalIVA, ' +
    '       ISNULL(p.ImpPedido, 0) AS ImpPedido, ' +
    '       ISNULL(NULLIF(LTRIM(RTRIM(te.Nombre)), ''''), ' +
    '              ISNULL(p.Temporada, '''')) AS TemporadaNombre ' +
    'FROM dbo.ocped p ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = p.Empresa ' +
    '                       AND alm.Almacen = p.Almacen ' +
    'LEFT JOIN dbo.octem te ON te.Temporada = p.Temporada ' +
    cWhere;
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, ' +
    '       l.NroPedido, l.Orden, l.Articulo, l.Color, l.Talla, ' +
    '       ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, l.Almacen AS AlmLin, ' +
    '       ISNULL(l.Descripcion, '''') AS Descripcion, ' +
    '       ISNULL(l.CantidadPedida, 0) AS CantidadPedida, ' +
    '       ISNULL(l.CantidadRecibida, 0) AS CantidadRecibida, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ' +
    '       ISNULL(l.PorIva, 0) AS PorIva, ' +
    '       CASE ' +
    '         WHEN co.Descripcion IS NULL ' +
    '           OR LTRIM(RTRIM(co.Descripcion)) = '''' ' +
    '           OR UPPER(LTRIM(RTRIM(co.Descripcion))) = ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '       END AS DescColor, ' +
    '       (SELECT TOP 1 ISNULL(ap.Modelo, '''') FROM dbo.ocartp ap ' +
    '         WHERE ap.Articulo = l.Articulo) AS Modelo ' +
    'FROM dbo.ocpedarp l ' +
    'INNER JOIN dbo.ocped p ON p.Empresa = l.Empresa ' +
    '                      AND p.Ejercicio = l.Ejercicio ' +
    '                      AND p.Serie = l.Serie ' +
    '                      AND p.NroPedido = l.NroPedido ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    'WHERE p.TipoDoc = ''PP''';
  cColsCab =
    'NUMERO_PEDC, SERIE_PEDC, FECHA_PEDC, FECHA_PREVISTA_PEDC, ESTADO_PEDC, ' +
    'CODIGO_EMP_PEDC, CODIGO_PRV_PEDC, RAZON_SOCIAL_PRV_PEDC, NIF_PRV_PEDC, ' +
    'DIRECCION1_PRV_PEDC, DIRECCION2_PRV_PEDC, POBLACION_PRV_PEDC, ' +
    'PROVINCIA_PRV_PEDC, CODIGO_POSTAL_PRV_PEDC, REF_PROVEEDOR_PEDC, ' +
    'CODIGO_ALM_PEDC, PORCENTAJE_IVAN_PEDC, TOTAL_IVAN_PEDC, ' +
    'PORCENTAJE_IVAR_PEDC, TOTAL_IVAR_PEDC, PORCENTAJE_IVAS_PEDC, ' +
    'TOTAL_IVAS_PEDC, PORCENTAJE_IVAE_PEDC, TOTAL_IVAE_PEDC, TOTAL_BASES_PEDC, ' +
    'TOTAL_IMPUESTOS_PEDC, TOTAL_LIQUIDO_PEDC, FORMA_PAGO_PEDC, ' +
    'ID_PV_TEMPORADA_PEDC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, CODIGO_ART_PEDCLIN, ' +
    'CODIGO_UNIDAD_PEDCLIN, ID_AC_PIVOT_PEDCLIN, COLOR_TEXTO_PEDCLIN, ' +
    'DESCRIPCION_ARTICULO_PEDCLIN, ' +
    'CANTIDAD_PEDCLIN, CANTIDAD_RECIBIDA_PEDCLIN, TIPO_IVA_ARTICULO_PEDCLIN, ' +
    'PORCENTAJE_IVA_PEDCLIN, PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, TOTAL_PEDCLIN, CODIGO_ALMACEN_PEDCLIN, ' +
    'REF_PRV_PEDCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin:        TUniQuery;
  bCab, bLin:        TBulkInsert;
  oMapTal, oMapTemp: TDictionary<string, Integer>;
  sAhora, sUser:     string;
  sNum, sSerie, sAlm, sArt, sUni: string;
  iva:               TIvaCompra;
begin
  BorrarPorUsuario(Eng, 'fza_pedidos_compra_lineas');
  BorrarPorUsuario(Eng, 'fza_pedidos_compra');
  sAhora := DateTimeASQL(Now);
  sUser  := ValorOrNull(Eng.Usuario);
  qCab := nil; qLin := nil; bCab := nil; bLin := nil;
  // --- PASO 1: cabeceras (ocped) ---
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_pedidos_compra', cColsCab, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  oMapTemp := TDictionary<string, Integer>.Create;
  CargarMapaTemporada(Eng, oMapTemp);
  try
    Eng.Log('  compras 1/2: cabeceras de pedido (ocped)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocped p ' + cWhere));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Pedidos de compra...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qCab.FieldByName('Ejercicio').AsInteger,
                  Trim(qCab.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qCab.FieldByName('NroPedido').AsInteger]);
      sAlm   := UpperCase(Trim(qCab.FieldByName('AbrevAlm').AsString));
      CalcularIvaCompra(qCab, iva);
      try
        bCab.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           DateTimeASQL(qCab.FieldByName('FechaPedido').AsDateTime),
           DateTimeASQL(qCab.FieldByName('FechaNecesaria').AsDateTime),
           ValorOrNull(EstadoPedido(qCab.FieldByName('CantidadPed').AsFloat,
                       qCab.FieldByName('CantidadRcbda').AsFloat)),
           ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
           ValorOrNull(Trim(qCab.FieldByName('Proveedor').AsString)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('RazonSocial').AsString), 1, 200)),
           ValorOrNull(Trim(qCab.FieldByName('NIF').AsString)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion1').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion2').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Poblacion').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Provincia').AsString), 1, 200)),
           ValorOrNull(Trim(qCab.FieldByName('CodPostal').AsString)),
           ValorOrNull(Trim(qCab.FieldByName('DocExterno').AsString)),
           ValorOrNull(sAlm),
           F(iva.Pn), F(iva.Tn), F(iva.Pr), F(iva.Tr),
           F(iva.Ps), F(iva.Ts), F(iva.Pe), F(iva.Te),
           F(qCab.FieldByName('ImpBaseImp').AsFloat),
           F(qCab.FieldByName('TotalIVA').AsFloat),
           F(qCab.FieldByName('ImpPedido').AsFloat),
           ValorOrNull(Copy(Trim(qCab.FieldByName('FormaPago').AsString), 1, 200)) +
             ', ' + TempPvToken(oMapTemp,
                                qCab.FieldByName('TemporadaNombre').AsString),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('pedido_compra', sSerie + '/' + sNum, E.Message, '',
            'requiere Empresas/Almacenes migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
    oMapTemp.Free;
  end;
  // --- PASO 2: líneas (ocpedarp) ---
  oMapTal := TDictionary<string, Integer>.Create;
  CargarMapaTallaje(Eng, oMapTal);
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_pedidos_compra_lineas',
                             cColsLin, BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  compras 2/2: lineas de pedido (ocpedarp)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocpedarp l ' +
      'INNER JOIN dbo.ocped p ON p.Empresa = l.Empresa ' +
      '   AND p.Ejercicio = l.Ejercicio AND p.Serie = l.Serie ' +
      '   AND p.NroPedido = l.NroPedido WHERE p.TipoDoc = ''PP'''));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de pedido...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qLin.FieldByName('Ejercicio').AsInteger,
                  Trim(qLin.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qLin.FieldByName('NroPedido').AsInteger]);
      sArt   := Trim(qLin.FieldByName('Articulo').AsString);
      sUni   := ConstruirCodigoUnidad(sArt,
                  Trim(qLin.FieldByName('DescColor').AsString),
                  Trim(qLin.FieldByName('Talla').AsString));
      sAlm   := UpperCase(Trim(qLin.FieldByName('AbrevAlmLin').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      try
        bLin.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ''N'', %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(Format('%.4d', [qLin.FieldByName('Orden').AsInteger])),
           ValorOrNull(sArt), ValorOrNull(sUni),
           AcPivotToken(oMapTal, sArt),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Color').AsString), 1, 100)),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
           F(qLin.FieldByName('CantidadPedida').AsFloat),
           F(qLin.FieldByName('CantidadRecibida').AsFloat),
           F(qLin.FieldByName('PorIva').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat),
           ValorOrNull(sAlm) +
             ', ' + ValorOrNull(Trim(qLin.FieldByName('Modelo').AsString)),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('pedido_compra_linea', sSerie + '/' + sNum, E.Message,
            Format('orden=%d', [qLin.FieldByName('Orden').AsInteger]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
  finally
    bLin.Free;
    qLin.Free;
    oMapTal.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaCompra(Eng, 'fza_pedidos_compra', 'PEDC');
    Eng.Log('  pedidos de compra: datos de empresa emisora rellenados.');
  end;
end;

// =========================================================================
//  2. Albaranes de compra (entrada)
// =========================================================================

procedure MigrarAlbaranesCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cWhere = 'WHERE a.TipoDoc = ''AE''';
  cSelCab =
    'SELECT a.Empresa, a.Ejercicio, ISNULL(a.Serie, '''') AS Serie, ' +
    '       a.NroAlbaran, a.Fecha, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(a.Proveedor, '''') AS Proveedor, ' +
    '       ISNULL(a.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(a.NIF, '''') AS NIF, ' +
    '       ISNULL(a.Direccion1, '''') AS Direccion1, ' +
    '       ISNULL(a.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(a.Poblacion, '''') AS Poblacion, ' +
    '       ISNULL(a.Provincia, '''') AS Provincia, ' +
    '       ISNULL(a.CodPostal, '''') AS CodPostal, ' +
    '       ISNULL(a.DocExterno, '''') AS DocExterno, ' +
    '       a.EjercicioPedido, ISNULL(a.SeriePedido, '''') AS SeriePedido, ' +
    '       ISNULL(a.NroPedido, 0) AS NroPedido, ' +
    '       ISNULL(a.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(a.PorIVA1, 0) AS PorIVA1, ISNULL(a.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(a.ImpBaseImp2, 0) AS ImpBaseImp2, ' +
    '       ISNULL(a.PorIVA2, 0) AS PorIVA2, ISNULL(a.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(a.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(a.PorIVA3, 0) AS PorIVA3, ISNULL(a.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(a.ImpBaseImp4, 0) AS ImpBaseImp4, ' +
    '       ISNULL(a.PorIVA4, 0) AS PorIVA4, ISNULL(a.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(a.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(a.TotalIVA, 0) AS TotalIVA, ' +
    '       ISNULL(a.ImpAlbaran, 0) AS ImpAlbaran ' +
    'FROM dbo.ocalbpro a ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = a.Empresa ' +
    '                       AND alm.Almacen = a.Almacen ' +
    cWhere;
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, ' +
    '       l.NroAlbaran, l.Orden, l.Articulo, l.Color, l.Talla, ' +
    '       ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, l.Almacen AS AlmLin, ' +
    '       ISNULL(l.Descripcion, '''') AS Descripcion, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ' +
    '       ISNULL(l.PorIVA, 0) AS PorIVA, ' +
    '       l.EjercicioPedido, ISNULL(l.SeriePedido, '''') AS SeriePedido, ' +
    '       ISNULL(l.NroPedido, 0) AS NroPedido, ' +
    '       CASE ' +
    '         WHEN co.Descripcion IS NULL ' +
    '           OR LTRIM(RTRIM(co.Descripcion)) = '''' ' +
    '           OR UPPER(LTRIM(RTRIM(co.Descripcion))) = ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '       END AS DescColor, ' +
    '       (SELECT TOP 1 ISNULL(ap.Modelo, '''') FROM dbo.ocartp ap ' +
    '         WHERE ap.Articulo = l.Articulo) AS Modelo ' +
    'FROM dbo.ocalbproarp l ' +
    'INNER JOIN dbo.ocalbpro a ON a.Empresa = l.Empresa ' +
    '                        AND a.Ejercicio = l.Ejercicio ' +
    '                        AND a.Serie = l.Serie ' +
    '                        AND a.NroAlbaran = l.NroAlbaran ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    'WHERE a.TipoDoc = ''AE''';
  cColsCab =
    'NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC, NUMERO_PED_ALBC, ' +
    'SERIE_PED_ALBC, CODIGO_EMP_ALBC, CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, ' +
    'NIF_PRV_ALBC, DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, POBLACION_PRV_ALBC, ' +
    'PROVINCIA_PRV_ALBC, CODIGO_POSTAL_PRV_ALBC, REF_PROVEEDOR_ALBC, ' +
    'CODIGO_ALM_ALBC, PORCENTAJE_IVAN_ALBC, TOTAL_IVAN_ALBC, PORCENTAJE_IVAR_ALBC, ' +
    'TOTAL_IVAR_ALBC, PORCENTAJE_IVAS_ALBC, TOTAL_IVAS_ALBC, PORCENTAJE_IVAE_ALBC, ' +
    'TOTAL_IVAE_ALBC, TOTAL_BASES_ALBC, TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, NUMERO_PEDC_ALBCLIN, ' +
    'SERIE_PEDC_ALBCLIN, CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, ' +
    'ID_AC_PIVOT_ALBCLIN, ' +
    'DESCRIPCION_ARTICULO_ALBCLIN, CANTIDAD_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
    'PORCENTAJE_IVA_ALBCLIN, PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
    'REF_PRV_ALBCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin:       TUniQuery;
  bCab, bLin:       TBulkInsert;
  oMapTal:          TDictionary<string, Integer>;
  sAhora, sUser:    string;
  sNum, sSerie, sAlm, sArt, sUni, sEstado, sNumPed, sSeriePed: string;
  iva:              TIvaCompra;
begin
  BorrarPorUsuario(Eng, 'fza_albaranes_compra_lineas');
  BorrarPorUsuario(Eng, 'fza_albaranes_compra');
  sAhora := DateTimeASQL(Now);
  sUser  := ValorOrNull(Eng.Usuario);
  // --- PASO 1: cabeceras (ocalbpro) ---
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_albaranes_compra', cColsCab, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Log('  compras albaran 1/2: cabeceras (ocalbpro)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocalbpro a ' + cWhere));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Albaranes de compra...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qCab.FieldByName('Ejercicio').AsInteger,
                  Trim(qCab.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qCab.FieldByName('NroAlbaran').AsInteger]);
      sAlm   := UpperCase(Trim(qCab.FieldByName('AbrevAlm').AsString));
      // Albarán histórico = mercancía YA recibida con su stock ya migrado
      // (dominio Movimientos). El Mto de compras maneja ABIERTO↔CERRADO
      // (CERRADO = stock generado), así que lo dejamos CERRADO. No usamos
      // FACTURADO: no migramos facturas de compra en esta pasada y dejaría
      // una referencia de factura colgando.
      sEstado := 'CERRADO';
      // Enlace al pedido (si lo hay), con la MISMA clave que el pedido migrado.
      if qCab.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed   := ValorOrNull(Format('%.6d',
                       [qCab.FieldByName('NroPedido').AsInteger]));
        sSeriePed := ValorOrNull(Format('%d.%s',
                       [qCab.FieldByName('EjercicioPedido').AsInteger,
                        Trim(qCab.FieldByName('SeriePedido').AsString)]));
      end
      else
      begin
        sNumPed   := 'NULL';
        sSeriePed := 'NULL';
      end;
      CalcularIvaCompra(qCab, iva);
      try
        bCab.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           DateTimeASQL(qCab.FieldByName('Fecha').AsDateTime),
           ValorOrNull(sEstado), sNumPed, sSeriePed,
           ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
           ValorOrNull(Trim(qCab.FieldByName('Proveedor').AsString)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('RazonSocial').AsString), 1, 200)),
           ValorOrNull(Trim(qCab.FieldByName('NIF').AsString)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion1').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion2').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Poblacion').AsString), 1, 200)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('Provincia').AsString), 1, 200)),
           ValorOrNull(Trim(qCab.FieldByName('CodPostal').AsString)),
           ValorOrNull(Trim(qCab.FieldByName('DocExterno').AsString)),
           ValorOrNull(sAlm),
           F(iva.Pn), F(iva.Tn), F(iva.Pr), F(iva.Tr),
           F(iva.Ps), F(iva.Ts), F(iva.Pe), F(iva.Te),
           F(qCab.FieldByName('ImpBaseImp').AsFloat),
           F(qCab.FieldByName('TotalIVA').AsFloat),
           F(qCab.FieldByName('ImpAlbaran').AsFloat),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('albaran_compra', sSerie + '/' + sNum, E.Message, '',
            'requiere Empresas/Almacenes migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
  end;
  // --- PASO 2: líneas (ocalbproarp) ---
  oMapTal := TDictionary<string, Integer>.Create;
  CargarMapaTallaje(Eng, oMapTal);
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_albaranes_compra_lineas',
                             cColsLin, BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  compras albaran 2/2: lineas (ocalbproarp)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocalbproarp l ' +
      'INNER JOIN dbo.ocalbpro a ON a.Empresa = l.Empresa ' +
      '   AND a.Ejercicio = l.Ejercicio AND a.Serie = l.Serie ' +
      '   AND a.NroAlbaran = l.NroAlbaran WHERE a.TipoDoc = ''AE'''));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de albaran...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qLin.FieldByName('Ejercicio').AsInteger,
                  Trim(qLin.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qLin.FieldByName('NroAlbaran').AsInteger]);
      sArt   := Trim(qLin.FieldByName('Articulo').AsString);
      sUni   := ConstruirCodigoUnidad(sArt,
                  Trim(qLin.FieldByName('DescColor').AsString),
                  Trim(qLin.FieldByName('Talla').AsString));
      sAlm   := UpperCase(Trim(qLin.FieldByName('AbrevAlmLin').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      if qLin.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed   := ValorOrNull(Format('%.6d',
                       [qLin.FieldByName('NroPedido').AsInteger]));
        sSeriePed := ValorOrNull(Format('%d.%s',
                       [qLin.FieldByName('EjercicioPedido').AsInteger,
                        Trim(qLin.FieldByName('SeriePedido').AsString)]));
      end
      else
      begin
        sNumPed   := 'NULL';
        sSeriePed := 'NULL';
      end;
      try
        bLin.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ''N'', %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(Format('%.4d', [qLin.FieldByName('Orden').AsInteger])),
           sNumPed, sSeriePed,
           ValorOrNull(sArt), ValorOrNull(sUni),
           AcPivotToken(oMapTal, sArt),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
           F(qLin.FieldByName('Cantidad').AsFloat),
           F(qLin.FieldByName('PorIVA').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat),
           ValorOrNull(sAlm) +
             ', ' + ValorOrNull(Trim(qLin.FieldByName('Modelo').AsString)),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('albaran_compra_linea', sSerie + '/' + sNum, E.Message,
            Format('orden=%d', [qLin.FieldByName('Orden').AsInteger]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
  finally
    bLin.Free;
    qLin.Free;
    oMapTal.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaCompra(Eng, 'fza_albaranes_compra', 'ALBC');
    Eng.Log('  albaranes de compra: datos de empresa emisora rellenados.');
  end;
end;

initialization
  fsCompras := TFormatSettings.Create('en-US');

end.
