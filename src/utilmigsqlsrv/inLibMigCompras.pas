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
{      dbo.ocreppro    (cab. devolución proveedor, 'RP')  → fza_devoluciones_compra
{      dbo.ocrepproart (líneas devolución proveedor)      → fza_devoluciones_compra_lineas
{      dbo.ocfacpro    (cab. factura proveedor)           → fza_facturas_compra
{      dbo.ocfacproart (líneas factura proveedor)         → fza_facturas_compra_lineas
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
{      - Albarán → pedido/factura: NUMERO/SERIE_* con la MISMA clave que genera}
{        este módulo ('<Ejercicio>.<Serie>' / número a 6).                     }
{                                                                              }
{    Clave Factuzam (PK NUMERO+SERIE):                                         }
{      SERIE  = '<Ejercicio>.<Serie>'   (p.ej. '2007.90')                      }
{      NUMERO = NroPedido / NroAlbaran / NroFactura a 6 dígitos                }
{                                                                              }
{    IVA: 4 bandas legacy (ImpBaseImp/PorIVA/CuotaIVA 1-4) clasificadas en     }
{    N/R/S/E por su %. Totales (bases/impuestos/líquido) del propio legacy.    }
{    Las lineas tambien clasifican TIPO_IVA_ARTICULO por su PorIVA, para que   }
{    facturas generadas desde albaran hereden la banda correcta.               }
{    El recargo de equivalencia (RE) no aplica a la cabecera de compra.        }
{                                                                              }
{    Forma de pago: se conserva el texto FormaPago si viene informado; si no, }
{    se guarda el codigo legacy TipoEfecto como fallback historico.            }
{                                                                              }
{    Idempotente: borra al arrancar lo migrado por el usuario y reinserta      }
{    (INSERT IGNORE por lotes para las líneas/cabeceras).                      }
{                                                                              }
{    NO genera stock: los movimientos de entrada/devolución ya entran por la   }
{    migración de Movimientos (ocmovarp). El enlace movimiento↔documento se    }
{    conserva solo a nivel documental pedido/albarán/devolución/factura.       }
{******************************************************************************}
unit inLibMigCompras;

interface

uses
  UMigEngine;

procedure MigrarPedidosCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarAlbaranesCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarDevolucionesCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarFacturasCompra(Eng: TMigEngine; var Stats: TMigStats);

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

function FechaCampoASQL(q: TUniQuery; const sCampo: string): string;
begin
  Result := 'NULL';
  if (q.FindField(sCampo) <> nil) and not q.FieldByName(sCampo).IsNull then
    Result := DateTimeASQL(Trunc(q.FieldByName(sCampo).AsDateTime));
end;

function UnirValores(const aValores: array of string): string;
var
  i: Integer;
begin
  Result := '';
  for i := Low(aValores) to High(aValores) do
  begin
    if i > Low(aValores) then
      Result := Result + ', ';
    Result := Result + aValores[i];
  end;
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

function TipoIvaArticuloCompra(const rate: Double): string;
begin
  case BandaIva(rate) of
    1:
      Result := 'R';
    2:
      Result := 'S';
    3:
      Result := 'E';
  else
    Result := 'N';
  end;
end;

function CodigoFormaPagoCompra(q: TUniQuery): string;
var
  iTipo: Integer;
  oCampoForma: TField;
begin
  Result := '';
  oCampoForma := q.FindField('FormaPago');
  if oCampoForma <> nil then
    Result := Copy(Trim(oCampoForma.AsString), 1, 20);
  if q.FindField('TipoEfecto') <> nil then
  begin
    if Result = '' then
    begin
      iTipo := q.FieldByName('TipoEfecto').AsInteger;
      if iTipo > 0 then
        Result := IntToStr(iTipo);
    end;
  end;
end;

type
  // Desglose de IVA de cabecera de compra por bandas N/R/S/E.
  TIvaCompra = record
    Pn, Bn, Tn: Double;
    Pr, Br, Tr: Double;
    Ps, Bs, Ts: Double;
    Pe, Be, Te: Double;
  end;

// Lee las 4 bandas legacy (ImpBaseImp/PorIVA/CuotaIVA 1-4) y las acumula por
// banda. Sirve para ocped y ocalbpro (mismos nombres de columna).
procedure CalcularIvaCompra(q: TUniQuery; var R: TIvaCompra);
var
  i, b:                Integer;
  base, rate, cuota:   Double;
  aRate, aBase, aCuota: array[0..3] of Double;
begin
  for b := 0 to 3 do
  begin
    aRate[b]  := 0;
    aBase[b]  := 0;
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
      aBase[b]  := aBase[b] + base;
      aCuota[b] := aCuota[b] + cuota;
      if rate > aRate[b] then
        aRate[b] := rate;
    end;
  end;
  R.Pn := aRate[0];
  R.Bn := aBase[0];
  R.Tn := aCuota[0];
  R.Pr := aRate[1];
  R.Br := aBase[1];
  R.Tr := aCuota[1];
  R.Ps := aRate[2];
  R.Bs := aBase[2];
  R.Ts := aCuota[2];
  R.Pe := aRate[3];
  R.Be := aBase[3];
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

procedure AsegurarEsquemaFacturasCompra(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_facturas_compra'' ' +
      'AND COLUMN_NAME = ''ID_PV_TEMPORADA_FACC''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/facturas_compra_temporada.sql');
  finally
    q.Free;
  end;
end;

procedure AsegurarEsquemaDevolucionesCompra(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
    q.Close;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra_lineas''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
    q.Close;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra'' ' +
      'AND COLUMN_NAME = ''ESPIVOTE_HORIZONTAL_DEVC''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
    q.Close;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra_lineas'' ' +
      'AND COLUMN_NAME = ''ID_AC_PIVOT_DEVCLIN''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
    q.Close;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra_lineas'' ' +
      'AND COLUMN_NAME = ''TOTAL_UNIDADES_DEVCLIN''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
    q.Close;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_devoluciones_compra_lineas'' ' +
      'AND COLUMN_NAME = ''REF_PRV_DEVCLIN''';
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/devoluciones_compra.sql');
  finally
    q.Free;
  end;
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
    '       ISNULL(p.TipoEfecto, 0) AS TipoEfecto, ' +
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
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' ' +
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
           ValorOrNull(CodigoFormaPagoCompra(qCab)) +
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
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(Format('%.4d', [qLin.FieldByName('Orden').AsInteger])),
           ValorOrNull(sArt), ValorOrNull(sUni),
           AcPivotToken(oMapTal, sArt),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Color').AsString), 1, 100)),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
           F(qLin.FieldByName('CantidadPedida').AsFloat),
           F(qLin.FieldByName('CantidadRecibida').AsFloat),
           ValorOrNull(TipoIvaArticuloCompra(qLin.FieldByName('PorIva').AsFloat)),
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
    '       ISNULL(a.TipoEfecto, 0) AS TipoEfecto, ' +
    '       ISNULL(a.FormaPago, '''') AS FormaPago, ' +
    '       a.EjercicioPedido, ISNULL(a.SeriePedido, '''') AS SeriePedido, ' +
    '       ISNULL(a.NroPedido, 0) AS NroPedido, ' +
    '       a.EjercicioFactura, ISNULL(a.SerieFactura, '''') AS SerieFactura, ' +
    '       ISNULL(a.NroFactura, 0) AS NroFactura, ' +
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
    '       l.EjercicioFactura, ISNULL(l.SerieFactura, '''') AS SerieFactura, ' +
    '       ISNULL(l.NroFactura, 0) AS NroFactura, ' +
    '       CASE ' +
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' ' +
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
    'SERIE_PED_ALBC, NUMERO_FAC_ALBC, SERIE_FAC_ALBC, CODIGO_EMP_ALBC, ' +
    'CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, ' +
    'NIF_PRV_ALBC, DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, POBLACION_PRV_ALBC, ' +
    'PROVINCIA_PRV_ALBC, CODIGO_POSTAL_PRV_ALBC, REF_PROVEEDOR_ALBC, ' +
    'CODIGO_ALM_ALBC, PORCENTAJE_IVAN_ALBC, TOTAL_IVAN_ALBC, PORCENTAJE_IVAR_ALBC, ' +
    'TOTAL_IVAR_ALBC, PORCENTAJE_IVAS_ALBC, TOTAL_IVAS_ALBC, PORCENTAJE_IVAE_ALBC, ' +
    'TOTAL_IVAE_ALBC, TOTAL_BASES_ALBC, TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC, ' +
    'FORMA_PAGO_ALBC, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, NUMERO_PEDC_ALBCLIN, ' +
    'SERIE_PEDC_ALBCLIN, CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, ' +
    'ID_AC_PIVOT_ALBCLIN, ' +
    'DESCRIPCION_ARTICULO_ALBCLIN, CANTIDAD_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
    'PORCENTAJE_IVA_ALBCLIN, PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ' +
    'REF_PRV_ALBCLIN, ESFACTURADA_ALBCLIN, NUMERO_FAC_ALBCLIN, ' +
    'SERIE_FAC_ALBCLIN, LINEA_FAC_ALBCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin:       TUniQuery;
  bCab, bLin:       TBulkInsert;
  oMapTal:          TDictionary<string, Integer>;
  sAhora, sUser:    string;
  sNum, sSerie, sAlm, sArt, sUni, sEstado, sNumPed, sSeriePed: string;
  sNumFac, sSerieFac, sEsFacturada: string;
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
      // Albarán histórico = mercancía YA recibida con su stock ya migrado.
      // Si el legacy lo trae facturado, conservamos el enlace documental.
      if qCab.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sEstado := 'FACTURADO';
        sNumFac := ValorOrNull(Format('%.6d',
                     [qCab.FieldByName('NroFactura').AsInteger]));
        sSerieFac := ValorOrNull(Format('%d.%s',
                       [qCab.FieldByName('EjercicioFactura').AsInteger,
                        Trim(qCab.FieldByName('SerieFactura').AsString)]));
      end
      else
      begin
        sEstado := 'CERRADO';
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
      end;
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
        bCab.Add(UnirValores([
           ValorOrNull(sNum), ValorOrNull(sSerie),
           DateTimeASQL(qCab.FieldByName('Fecha').AsDateTime),
           ValorOrNull(sEstado), sNumPed, sSeriePed, sNumFac, sSerieFac,
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
           ValorOrNull(CodigoFormaPagoCompra(qCab)),
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
      if qLin.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sEsFacturada := ValorOrNull('S');
        sNumFac := ValorOrNull(Format('%.6d',
                     [qLin.FieldByName('NroFactura').AsInteger]));
        sSerieFac := ValorOrNull(Format('%d.%s',
                       [qLin.FieldByName('EjercicioFactura').AsInteger,
                        Trim(qLin.FieldByName('SerieFactura').AsString)]));
      end
      else
      begin
        sEsFacturada := ValorOrNull('N');
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
      end;
      try
        bLin.Add(UnirValores([
           ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(Format('%.4d', [qLin.FieldByName('Orden').AsInteger])),
           sNumPed, sSeriePed,
           ValorOrNull(sArt), ValorOrNull(sUni),
           AcPivotToken(oMapTal, sArt),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
           F(qLin.FieldByName('Cantidad').AsFloat),
           ValorOrNull(TipoIvaArticuloCompra(qLin.FieldByName('PorIVA').AsFloat)),
           F(qLin.FieldByName('PorIVA').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat),
           ValorOrNull(sAlm),
           ValorOrNull(Trim(qLin.FieldByName('Modelo').AsString)),
           sEsFacturada, sNumFac, sSerieFac, 'NULL',
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

// =========================================================================
//  3. Devoluciones de compra (proveedor)
// =========================================================================

procedure MigrarDevolucionesCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cWhere = 'WHERE r.TipoDoc = ''RP''';
  cSelCab =
    'SELECT r.Empresa, r.Ejercicio, ISNULL(r.Serie, '''') AS Serie, ' +
    '       r.NroRep, r.Fecha, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(r.Almacen, 0) AS Almacen, ' +
    '       ISNULL(r.Proveedor, 0) AS Proveedor, ' +
    '       ISNULL(r.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(r.NIF, '''') AS NIF, ' +
    '       ISNULL(r.Direccion1, '''') AS Direccion1, ' +
    '       ISNULL(r.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(r.Poblacion, '''') AS Poblacion, ' +
    '       ISNULL(r.Provincia, '''') AS Provincia, ' +
    '       ISNULL(r.CodPostal, '''') AS CodPostal, ' +
    '       ISNULL(r.DocExterno, '''') AS DocExterno, ' +
    '       ISNULL(r.FormaEnvio, '''') AS FormaEnvio, ' +
    '       ISNULL(r.TipoEfecto, 0) AS TipoEfecto, ' +
    '       ISNULL(r.FormaPago, '''') AS FormaPago, ' +
    '       r.EjercicioPed, ISNULL(r.SeriePed, '''') AS SeriePed, ' +
    '       ISNULL(r.NroPedido, 0) AS NroPedido, ' +
    '       r.EjercicioFra, ISNULL(r.SerieFra, '''') AS SerieFra, ' +
    '       ISNULL(r.NroFactura, 0) AS NroFactura, ' +
    '       ISNULL(lc.MaxLinea, 0) AS MaxLinea, ' +
    '       ISNULL(r.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(r.PorIVA1, 0) AS PorIVA1, ISNULL(r.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(r.ImpBaseImp2, 0) AS ImpBaseImp2, ' +
    '       ISNULL(r.PorIVA2, 0) AS PorIVA2, ISNULL(r.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(r.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(r.PorIVA3, 0) AS PorIVA3, ISNULL(r.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(r.ImpBaseImp4, 0) AS ImpBaseImp4, ' +
    '       ISNULL(r.PorIVA4, 0) AS PorIVA4, ISNULL(r.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(r.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(r.TotalIVA, 0) AS TotalIVA, ' +
    '       ISNULL(r.ImpLiquido, 0) AS ImpLiquido, ' +
    '       ISNULL(CONVERT(varchar(2000), r.ObsRep), '''') AS ObsRep ' +
    'FROM dbo.ocreppro r ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = r.Empresa ' +
    '                       AND alm.Almacen = r.Almacen ' +
    'LEFT JOIN ( ' +
    '  SELECT Empresa, Ejercicio, Serie, NroRep, COUNT(*) * 10 AS MaxLinea ' +
    '  FROM dbo.ocrepproart ' +
    '  GROUP BY Empresa, Ejercicio, Serie, NroRep ' +
    ') lc ON lc.Empresa = r.Empresa ' +
    '    AND lc.Ejercicio = r.Ejercicio ' +
    '    AND lc.Serie = r.Serie ' +
    '    AND lc.NroRep = r.NroRep ' +
    cWhere;
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, ' +
    '       l.NroRep, l.Orden, l.Id, ' +
    '       ROW_NUMBER() OVER (PARTITION BY l.Empresa, l.Ejercicio, ' +
    '         l.Serie, l.NroRep ORDER BY l.Orden, l.Id) * 10 AS LineaFactuzam, ' +
    '       l.Articulo, l.Color, l.Talla, ' +
    '       ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, ' +
    '       ISNULL(l.Almacen, 0) AS AlmLin, ' +
    '       ISNULL(CONVERT(varchar(1000), l.Descripcion), '''') AS Descripcion, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ' +
    '       ISNULL(l.PorIVA, 0) AS PorIVA, ' +
    '       ISNULL(NULLIF(l.EjercicioPedido, 0), h.EjercicioPed) AS EjercicioPedido, ' +
    '       ISNULL(NULLIF(LTRIM(RTRIM(l.SeriePedido)), ''''), ' +
    '         ISNULL(h.SeriePed, '''')) AS SeriePedido, ' +
    '       ISNULL(NULLIF(l.NroPedido, 0), h.NroPedido) AS NroPedido, ' +
    '       ISNULL(l.IdPed, 0) AS IdPed, ' +
    '       ISNULL(p.Orden, 0) AS OrdenPedido, ' +
    '       h.EjercicioFra AS EjercicioFactura, ' +
    '       ISNULL(h.SerieFra, '''') AS SerieFactura, ' +
    '       ISNULL(h.NroFactura, 0) AS NroFactura, ' +
    '       CASE ' +
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor, ' +
    '       (SELECT TOP 1 ISNULL(ap.Modelo, '''') FROM dbo.ocartp ap ' +
    '         WHERE ap.Articulo = l.Articulo) AS Modelo ' +
    'FROM dbo.ocrepproart l ' +
    'INNER JOIN dbo.ocreppro h ON h.Empresa = l.Empresa ' +
    '                        AND h.Ejercicio = l.Ejercicio ' +
    '                        AND h.Serie = l.Serie ' +
    '                        AND h.NroRep = l.NroRep ' +
    'LEFT JOIN dbo.ocpedarp p ON p.Empresa = ISNULL(NULLIF(l.EmpresaPedido, 0), h.EmpresaPed) ' +
    '                        AND p.Ejercicio = ISNULL(NULLIF(l.EjercicioPedido, 0), h.EjercicioPed) ' +
    '                        AND p.Serie = ISNULL(NULLIF(LTRIM(RTRIM(l.SeriePedido)), ''''), ISNULL(h.SeriePed, '''')) ' +
    '                        AND p.NroPedido = ISNULL(NULLIF(l.NroPedido, 0), h.NroPedido) ' +
    '                        AND p.Id = l.IdPed ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    'WHERE h.TipoDoc = ''RP''';
  cColsCab =
    'NUMERO_DEVC, SERIE_DEVC, FECHA_DEVC, ESTADO_DEVC, NUMERO_PED_DEVC, ' +
    'SERIE_PED_DEVC, NUMERO_FAC_DEVC, SERIE_FAC_DEVC, CODIGO_EMP_DEVC, ' +
    'CODIGO_PRV_DEVC, RAZON_SOCIAL_PRV_DEVC, ' +
    'NIF_PRV_DEVC, DIRECCION1_PRV_DEVC, DIRECCION2_PRV_DEVC, POBLACION_PRV_DEVC, ' +
    'PROVINCIA_PRV_DEVC, CODIGO_POSTAL_PRV_DEVC, REF_PROVEEDOR_DEVC, ' +
    'CODIGO_ALM_DEVC, TRANSPORTISTA_DEVC, PORCENTAJE_IVAN_DEVC, TOTAL_IVAN_DEVC, ' +
    'PORCENTAJE_IVAR_DEVC, TOTAL_IVAR_DEVC, PORCENTAJE_IVAS_DEVC, TOTAL_IVAS_DEVC, ' +
    'PORCENTAJE_IVAE_DEVC, TOTAL_IVAE_DEVC, TOTAL_BASES_DEVC, ' +
    'TOTAL_IMPUESTOS_DEVC, TOTAL_LIQUIDO_DEVC, FORMA_PAGO_DEVC, ' +
    'CONTADOR_LINEAS_DEVC, COMENTARIOS_DEVC, OBSERVACIONES_DEVC, ' +
    'ESPIVOTE_HORIZONTAL_DEVC, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_DEVC_DEVCLIN, SERIE_DEVC_DEVCLIN, LINEA_DEVCLIN, ' +
    'NUMERO_PEDC_DEVCLIN, SERIE_PEDC_DEVCLIN, LINEA_PEDC_DEVCLIN, ' +
    'CODIGO_ART_DEVCLIN, CODIGO_UNIDAD_DEVCLIN, REF_PRV_DEVCLIN, ' +
    'ID_AC_PIVOT_DEVCLIN, DESCRIPCION_ARTICULO_DEVCLIN, CANTIDAD_DEVCLIN, ' +
    'TOTAL_UNIDADES_DEVCLIN, TIPO_IVA_ARTICULO_DEVCLIN, PORCENTAJE_IVA_DEVCLIN, ' +
    'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN, PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN, ' +
    'TOTAL_DEVCLIN, CODIGO_ALMACEN_DEVCLIN, DESCRIPCION_VARIACION_DEVCLIN, ' +
    'ESFACTURADA_DEVCLIN, NUMERO_FAC_DEVCLIN, SERIE_FAC_DEVCLIN, ' +
    'LINEA_FAC_DEVCLIN, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, ' +
    'USUARIO_MODIF';
var
  qCab, qLin:       TUniQuery;
  bCab, bLin:       TBulkInsert;
  oMapTal:          TDictionary<string, Integer>;
  sAhora, sUser:    string;
  sNum, sSerie, sAlm, sArt, sUni, sEstado, sNumPed, sSeriePed: string;
  sNumFac, sSerieFac, sEsFacturada, sLineaPed, sVar: string;
  iva:              TIvaCompra;
begin
  AsegurarEsquemaDevolucionesCompra(Eng);
  BorrarPorUsuario(Eng, 'fza_devoluciones_compra_lineas');
  BorrarPorUsuario(Eng, 'fza_devoluciones_compra');
  sAhora := DateTimeASQL(Now);
  sUser  := ValorOrNull(Eng.Usuario);
  // --- PASO 1: cabeceras (ocreppro) ---
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_devoluciones_compra',
                             cColsCab, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Log('  compras devolucion 1/2: cabeceras (ocreppro)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocreppro r ' + cWhere));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Devoluciones de compra...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qCab.FieldByName('Ejercicio').AsInteger,
                  Trim(qCab.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qCab.FieldByName('NroRep').AsInteger]);
      sAlm   := UpperCase(Trim(qCab.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qCab.FieldByName('Almacen').AsInteger);
      if qCab.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sEstado := 'FACTURADO';
        sNumFac := ValorOrNull(Format('%.6d',
                     [qCab.FieldByName('NroFactura').AsInteger]));
        sSerieFac := ValorOrNull(Format('%d.%s',
                       [qCab.FieldByName('EjercicioFra').AsInteger,
                        Trim(qCab.FieldByName('SerieFra').AsString)]));
      end
      else
      begin
        sEstado := 'CERRADO';
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
      end;
      if qCab.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed := ValorOrNull(Format('%.6d',
                     [qCab.FieldByName('NroPedido').AsInteger]));
        sSeriePed := ValorOrNull(Format('%d.%s',
                       [qCab.FieldByName('EjercicioPed').AsInteger,
                        Trim(qCab.FieldByName('SeriePed').AsString)]));
      end
      else
      begin
        sNumPed := 'NULL';
        sSeriePed := 'NULL';
      end;
      CalcularIvaCompra(qCab, iva);
      try
        bCab.Add(UnirValores([
           ValorOrNull(sNum), ValorOrNull(sSerie),
           FechaCampoASQL(qCab, 'Fecha'),
           ValorOrNull(sEstado), sNumPed, sSeriePed, sNumFac, sSerieFac,
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
           ValorOrNull(Trim(qCab.FieldByName('FormaEnvio').AsString)),
           F(iva.Pn), F(iva.Tn), F(iva.Pr), F(iva.Tr),
           F(iva.Ps), F(iva.Ts), F(iva.Pe), F(iva.Te),
           F(qCab.FieldByName('ImpBaseImp').AsFloat),
           F(qCab.FieldByName('TotalIVA').AsFloat),
           F(qCab.FieldByName('ImpLiquido').AsFloat),
           ValorOrNull(CodigoFormaPagoCompra(qCab)),
           ValorOrNull(Format('%.8d',
             [qCab.FieldByName('MaxLinea').AsInteger])),
           ValorOrNull(Copy(Trim(qCab.FieldByName('ObsRep').AsString), 1, 1000)),
           ValorOrNull(Copy(Trim(qCab.FieldByName('ObsRep').AsString), 1, 2000)),
           ValorOrNull('S'), sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('devolucion_compra', sSerie + '/' + sNum, E.Message,
            '', 'requiere Empresas/Almacenes/Proveedores migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
  end;
  // --- PASO 2: líneas (ocrepproart) ---
  oMapTal := TDictionary<string, Integer>.Create;
  CargarMapaTallaje(Eng, oMapTal);
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_devoluciones_compra_lineas',
                             cColsLin, BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  compras devolucion 2/2: lineas (ocrepproart)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocrepproart l ' +
      'INNER JOIN dbo.ocreppro h ON h.Empresa = l.Empresa ' +
      '   AND h.Ejercicio = l.Ejercicio AND h.Serie = l.Serie ' +
      '   AND h.NroRep = l.NroRep WHERE h.TipoDoc = ''RP'''));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de devolucion...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qLin.FieldByName('Ejercicio').AsInteger,
                  Trim(qLin.FieldByName('Serie').AsString)]);
      sNum   := Format('%.6d', [qLin.FieldByName('NroRep').AsInteger]);
      sArt   := Trim(qLin.FieldByName('Articulo').AsString);
      sUni   := ConstruirCodigoUnidad(sArt,
                  Trim(qLin.FieldByName('DescColor').AsString),
                  Trim(qLin.FieldByName('Talla').AsString));
      sAlm   := UpperCase(Trim(qLin.FieldByName('AbrevAlmLin').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      if qLin.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed := ValorOrNull(Format('%.6d',
                     [qLin.FieldByName('NroPedido').AsInteger]));
        sSeriePed := ValorOrNull(Format('%d.%s',
                       [qLin.FieldByName('EjercicioPedido').AsInteger,
                        Trim(qLin.FieldByName('SeriePedido').AsString)]));
        if qLin.FieldByName('OrdenPedido').AsInteger > 0 then
          sLineaPed := ValorOrNull(Format('%.4d',
                         [qLin.FieldByName('OrdenPedido').AsInteger]))
        else
          sLineaPed := 'NULL';
      end
      else
      begin
        sNumPed := 'NULL';
        sSeriePed := 'NULL';
        sLineaPed := 'NULL';
      end;
      if qLin.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sEsFacturada := ValorOrNull('S');
        sNumFac := ValorOrNull(Format('%.6d',
                     [qLin.FieldByName('NroFactura').AsInteger]));
        sSerieFac := ValorOrNull(Format('%d.%s',
                       [qLin.FieldByName('EjercicioFactura').AsInteger,
                        Trim(qLin.FieldByName('SerieFactura').AsString)]));
      end
      else
      begin
        sEsFacturada := ValorOrNull('N');
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
      end;
      sVar := Trim(qLin.FieldByName('DescColor').AsString);
      if Trim(qLin.FieldByName('Talla').AsString) <> '' then
      begin
        if sVar <> '' then
          sVar := sVar + ' / ';
        sVar := sVar + Trim(qLin.FieldByName('Talla').AsString);
      end;
      try
        bLin.Add(UnirValores([
           ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(Format('%.4d',
             [qLin.FieldByName('LineaFactuzam').AsInteger])),
           sNumPed, sSeriePed, sLineaPed,
           ValorOrNull(sArt), ValorOrNull(sUni),
           ValorOrNull(Trim(qLin.FieldByName('Modelo').AsString)),
           AcPivotToken(oMapTal, sArt),
           ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
           F(qLin.FieldByName('Cantidad').AsFloat),
           F(qLin.FieldByName('Cantidad').AsFloat),
           ValorOrNull(TipoIvaArticuloCompra(qLin.FieldByName('PorIVA').AsFloat)),
           F(qLin.FieldByName('PorIVA').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat),
           ValorOrNull(sAlm), ValorOrNull(Copy(sVar, 1, 100)),
           sEsFacturada, sNumFac, sSerieFac, 'NULL',
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('devolucion_compra_linea', sSerie + '/' + sNum,
            E.Message, Format('orden=%d', [qLin.FieldByName('Orden').AsInteger]),
            '');
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
    EnlazarEmpresaCompra(Eng, 'fza_devoluciones_compra', 'DEVC');
    Eng.Log('  devoluciones de compra: datos de empresa emisora rellenados.');
  end;
end;

procedure EnlazarAlbaranesDesdeFacturasCompra(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra a ' +
      'JOIN fza_facturas_compra_lineas l ' +
      '  ON l.NUMERO_ALBC_FACCLIN = a.NUMERO_ALBC ' +
      ' AND l.SERIE_ALBC_FACCLIN = a.SERIE_ALBC ' +
      'JOIN fza_facturas_compra f ' +
      '  ON f.NUMERO_FACC = l.NUMERO_FACC_FACCLIN ' +
      ' AND f.SERIE_FACC = l.SERIE_FACC_FACCLIN ' +
      'SET a.ESTADO_ALBC = ''FACTURADO'', ' +
      '    a.NUMERO_FAC_ALBC = f.NUMERO_FACC, ' +
      '    a.SERIE_FAC_ALBC = f.SERIE_FACC ' +
      'WHERE f.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra_lineas a ' +
      'JOIN fza_facturas_compra_lineas l ' +
      '  ON l.NUMERO_ALBC_FACCLIN = a.NUMERO_ALBC_ALBCLIN ' +
      ' AND l.SERIE_ALBC_FACCLIN = a.SERIE_ALBC_ALBCLIN ' +
      ' AND l.LINEA_ALBC_FACCLIN = a.LINEA_ALBCLIN ' +
      'JOIN fza_facturas_compra f ' +
      '  ON f.NUMERO_FACC = l.NUMERO_FACC_FACCLIN ' +
      ' AND f.SERIE_FACC = l.SERIE_FACC_FACCLIN ' +
      'SET a.ESFACTURADA_ALBCLIN = ''S'', ' +
      '    a.NUMERO_FAC_ALBCLIN = f.NUMERO_FACC, ' +
      '    a.SERIE_FAC_ALBCLIN = f.SERIE_FACC, ' +
      '    a.LINEA_FAC_ALBCLIN = l.LINEA_FACCLIN ' +
      'WHERE f.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text :=
      'UPDATE fza_facturas_compra f ' +
      'LEFT JOIN ( ' +
      '  SELECT NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN, ' +
      '         MAX(CAST(LINEA_FACCLIN AS UNSIGNED)) AS MAX_LINEA ' +
      '  FROM fza_facturas_compra_lineas ' +
      '  WHERE USUARIO_ALTA = :u ' +
      '  GROUP BY NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN ' +
      ') l ON l.NUMERO_FACC_FACCLIN = f.NUMERO_FACC ' +
      '   AND l.SERIE_FACC_FACCLIN = f.SERIE_FACC ' +
      'SET f.CONTADOR_LINEAS_FACC = LPAD(COALESCE(l.MAX_LINEA, 0), 8, ''0'') ' +
      'WHERE f.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// =========================================================================
//  4. Facturas de compra
// =========================================================================

procedure MigrarFacturasCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelCab =
    'SELECT f.Empresa, f.Ejercicio, ISNULL(f.Serie, '''') AS Serie, ' +
    '       f.NroFactura, f.Fecha, f.FechaValor, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(f.Almacen, 0) AS Almacen, ' +
    '       ISNULL(f.Proveedor, 0) AS Proveedor, ' +
    '       ISNULL(f.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(f.NIF, '''') AS NIF, ' +
    '       ISNULL(f.Direccion1, '''') AS Direccion1, ' +
    '       ISNULL(f.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(f.Poblacion, '''') AS Poblacion, ' +
    '       ISNULL(f.Provincia, '''') AS Provincia, ' +
    '       ISNULL(f.CodPostal, '''') AS CodPostal, ' +
    '       ISNULL(f.DocExterno, '''') AS DocExterno, ' +
    '       ISNULL(f.TipoEfecto, 0) AS TipoEfecto, ' +
    '       ISNULL(f.FormaPago, '''') AS FormaPago, ' +
    '       ISNULL(f.Entidad, '''') AS Entidad, ' +
    '       ISNULL(f.Oficina, '''') AS Oficina, ' +
    '       ISNULL(f.DigitosControl, '''') AS DigitosControl, ' +
    '       ISNULL(f.NroCuenta, '''') AS NroCuenta, ' +
    '       ISNULL(f.IBAN, '''') AS IBAN, ' +
    '       ISNULL(f.AgruparAlbaranes, '''') AS AgruparAlbaranes, ' +
    '       CONVERT(varchar(2000), f.ObsFactura) AS ObsFactura, ' +
    '       ISNULL(f.PorDtoComercial, 0) AS PorDtoComercial, ' +
    '       ISNULL(f.ImpDtoComercial, 0) AS ImpDtoComercial, ' +
    '       ISNULL(f.PorProntoPago, 0) AS PorProntoPago, ' +
    '       ISNULL(f.ImpProntoPago, 0) AS ImpProntoPago, ' +
    '       ISNULL(f.PorRappel, 0) AS PorRappel, ' +
    '       ISNULL(f.ImpRappel, 0) AS ImpRappel, ' +
    '       ISNULL(f.PorFinanciacion, 0) AS PorFinanciacion, ' +
    '       ISNULL(f.ImpFinanciacion, 0) AS ImpFinanciacion, ' +
    '       ISNULL(f.ImpPortes, 0) AS ImpPortes, ' +
    '       ISNULL(f.PorRetencion, 0) AS PorRetencion, ' +
    '       ISNULL(f.ImpRetencion, 0) AS ImpRetencion, ' +
    '       ISNULL(f.ImpBrutoLineas, 0) AS ImpBrutoLineas, ' +
    '       ISNULL(f.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(f.PorIVA1, 0) AS PorIVA1, ' +
    '       ISNULL(f.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(f.ImpBaseImp2, 0) AS ImpBaseImp2, ' +
    '       ISNULL(f.PorIVA2, 0) AS PorIVA2, ' +
    '       ISNULL(f.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(f.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(f.PorIVA3, 0) AS PorIVA3, ' +
    '       ISNULL(f.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(f.ImpBaseImp4, 0) AS ImpBaseImp4, ' +
    '       ISNULL(f.PorIVA4, 0) AS PorIVA4, ' +
    '       ISNULL(f.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(f.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(f.TotalIVA, 0) AS TotalIVA, ' +
    '       ISNULL(f.ImpFactura, 0) AS ImpFactura, ' +
    '       ISNULL(f.ImpLiquido, 0) AS ImpLiquido, ' +
    '       ISNULL(NULLIF(LTRIM(RTRIM(te.Nombre)), ''''), ' +
    '              ISNULL(f.Temporada, '''')) AS TemporadaNombre ' +
    'FROM dbo.ocfacpro f ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = f.Empresa ' +
    '                       AND alm.Almacen = f.Almacen ' +
    'LEFT JOIN dbo.octem te ON te.Temporada = f.Temporada';
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, l.Serie, l.NroFactura, l.Fila, ' +
    '       l.Orden, l.Id, ' +
    '       ROW_NUMBER() OVER (PARTITION BY l.Empresa, l.Ejercicio, ' +
    '         l.Serie, l.NroFactura ORDER BY l.Fila, l.Orden, l.Id) ' +
    '         * 10 AS LineaFactuzam, ' +
    '       l.Articulo, l.Color, l.Talla, ' +
    '       ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, ' +
    '       ISNULL(l.Almacen, 0) AS AlmLin, ' +
    '       ISNULL(l.Descripcion, '''') AS Descripcion, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ' +
    '       ISNULL(l.PorIVA, 0) AS PorIVA, ' +
    '       ISNULL(l.EjercicioAlbaran, 0) AS EjercicioAlbaran, ' +
    '       ISNULL(l.SerieAlbaran, '''') AS SerieAlbaran, ' +
    '       ISNULL(l.NroAlbaran, 0) AS NroAlbaran, ' +
    '       COALESCE(NULLIF(l.IdAlb, 0), l.Orden, 0) AS LineaAlbaran, ' +
    '       CASE ' +
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor, ' +
    '       (SELECT TOP 1 ISNULL(ap.Modelo, '''') FROM dbo.ocartp ap ' +
    '         WHERE ap.Articulo = l.Articulo) AS Modelo ' +
    'FROM dbo.ocfacproart l ' +
    'INNER JOIN dbo.ocfacpro f ON f.Empresa = l.Empresa ' +
    '                         AND f.Ejercicio = l.Ejercicio ' +
    '                         AND f.Serie = l.Serie ' +
    '                         AND f.NroFactura = l.NroFactura ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico';
  cColsCab =
    'NUMERO_FACC, SERIE_FACC, FECHA_FACC, FECHA_VALOR_FACC, ESTADO_FACC, ' +
    'DOC_EXTERNO_FACC, REF_PROVEEDOR_FACC, CODIGO_EMP_FACC, CODIGO_PRV_FACC, ' +
    'RAZON_SOCIAL_PRV_FACC, NIF_PRV_FACC, DIRECCION1_PRV_FACC, ' +
    'DIRECCION2_PRV_FACC, POBLACION_PRV_FACC, PROVINCIA_PRV_FACC, ' +
    'CODIGO_POSTAL_PRV_FACC, CODIGO_ALM_FACC, ESIVA_RECARGO_COMPRAS_FACC, ' +
    'PORCENTAJE_IVAN_FACC, TOTAL_BASEI_IVAN_FACC, TOTAL_IVAN_FACC, ' +
    'PORCENTAJE_REN_FACC, TOTAL_REN_FACC, PORCENTAJE_IVAR_FACC, ' +
    'TOTAL_BASEI_IVAR_FACC, TOTAL_IVAR_FACC, PORCENTAJE_RER_FACC, ' +
    'TOTAL_RER_FACC, PORCENTAJE_IVAS_FACC, TOTAL_BASEI_IVAS_FACC, ' +
    'TOTAL_IVAS_FACC, PORCENTAJE_RES_FACC, TOTAL_RES_FACC, ' +
    'PORCENTAJE_IVAE_FACC, TOTAL_BASEI_IVAE_FACC, TOTAL_IVAE_FACC, ' +
    'PORCENTAJE_REE_FACC, TOTAL_REE_FACC, PORCENTAJE_DTO_COMERCIAL_FACC, ' +
    'TOTAL_DTO_COMERCIAL_FACC, PORCENTAJE_PRONTO_PAGO_FACC, ' +
    'TOTAL_PRONTO_PAGO_FACC, PORCENTAJE_RAPPEL_FACC, TOTAL_RAPPEL_FACC, ' +
    'PORCENTAJE_FINANCIACION_FACC, TOTAL_FINANCIACION_FACC, ' +
    'TOTAL_PORTES_FACC, PORCENTAJE_RETENCION_FACC, TOTAL_RETENCION_FACC, ' +
    'TOTAL_BRUTO_FACC, TOTAL_BASES_FACC, TOTAL_IMPUESTOS_FACC, TOTAL_FACC, ' +
    'TOTAL_LIQUIDO_FACC, FORMA_PAGO_FACC, ID_PV_TEMPORADA_FACC, ' +
    'ESAGRUPAR_ALBARANES_FACC, ' +
    'ENTIDAD_FACC, OFICINA_FACC, DIGITO_CONTROL_FACC, CUENTA_FACC, ' +
    'IBAN_FACC, COMENTARIOS_FACC, OBSERVACIONES_FACC, ESPIVOTE_HORIZONTAL_FACC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_FACC_FACCLIN, SERIE_FACC_FACCLIN, LINEA_FACCLIN, ' +
    'NUMERO_ALBC_FACCLIN, SERIE_ALBC_FACCLIN, LINEA_ALBC_FACCLIN, ' +
    'CODIGO_ART_FACCLIN, CODIGO_UNIDAD_FACCLIN, REF_PRV_FACCLIN, ' +
    'ID_AC_PIVOT_FACCLIN, DESCRIPCION_ARTICULO_FACCLIN, CANTIDAD_FACCLIN, ' +
    'TOTAL_UNIDADES_FACCLIN, TIPO_IVA_ARTICULO_FACCLIN, ' +
    'PORCENTAJE_IVA_FACCLIN, PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_FACCLIN, TOTAL_FACCLIN, ' +
    'CODIGO_ALMACEN_FACCLIN, DESCRIPCION_VARIACION_FACCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin: TUniQuery;
  bCab, bLin: TBulkInsert;
  oMapTal, oMapTemp: TDictionary<string, Integer>;
  sAhora, sUser: string;
  sNum, sSerie, sAlm, sArt, sUni, sLinea, sDocExterno: string;
  sNumAlb, sSerieAlb, sLineaAlb, sVariacion, sAgrupar: string;
  iva: TIvaCompra;
  fTotal: Double;
begin
  AsegurarEsquemaFacturasCompra(Eng);
  BorrarPorUsuario(Eng, 'fza_facturas_compra_lineas');
  BorrarPorUsuario(Eng, 'fza_facturas_compra');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_facturas_compra', cColsCab,
                             BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  oMapTemp := TDictionary<string, Integer>.Create;
  try
    CargarMapaTemporada(Eng, oMapTemp);
    Eng.Log('  compras factura 1/2: cabeceras (ocfacpro)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocfacpro'));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en facturas de compra...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qCab.FieldByName('Ejercicio').AsInteger,
                  Trim(qCab.FieldByName('Serie').AsString)]);
      sNum := Format('%.6d', [qCab.FieldByName('NroFactura').AsInteger]);
      sAlm := UpperCase(Trim(qCab.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qCab.FieldByName('Almacen').AsInteger);
      sDocExterno := Trim(qCab.FieldByName('DocExterno').AsString);
      sAgrupar := UpperCase(Trim(qCab.FieldByName('AgruparAlbaranes').AsString));
      if sAgrupar <> 'S' then
        sAgrupar := 'N';
      CalcularIvaCompra(qCab, iva);
      fTotal := qCab.FieldByName('ImpLiquido').AsFloat;
      if fTotal = 0 then
        fTotal := qCab.FieldByName('ImpFactura').AsFloat;
      try
        bCab.Add(UnirValores([
          ValorOrNull(sNum), ValorOrNull(sSerie),
          FechaCampoASQL(qCab, 'Fecha'), FechaCampoASQL(qCab, 'FechaValor'),
          ValorOrNull('ABIERTA'),
          ValorOrNull(Copy(sDocExterno, 1, 50)),
          ValorOrNull(Copy(sDocExterno, 1, 50)),
          ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
          ValorOrNull(Trim(qCab.FieldByName('Proveedor').AsString)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('RazonSocial').AsString), 1, 200)),
          ValorOrNull(Trim(qCab.FieldByName('NIF').AsString)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion1').AsString), 1, 200)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Direccion2').AsString), 1, 200)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Poblacion').AsString), 1, 200)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Provincia').AsString), 1, 200)),
          ValorOrNull(Trim(qCab.FieldByName('CodPostal').AsString)),
          ValorOrNull(sAlm), ValorOrNull('N'),
          F(iva.Pn), F(iva.Bn), F(iva.Tn), F(0), F(0),
          F(iva.Pr), F(iva.Br), F(iva.Tr), F(0), F(0),
          F(iva.Ps), F(iva.Bs), F(iva.Ts), F(0), F(0),
          F(iva.Pe), F(iva.Be), F(iva.Te), F(0), F(0),
          F(qCab.FieldByName('PorDtoComercial').AsFloat),
          F(qCab.FieldByName('ImpDtoComercial').AsFloat),
          F(qCab.FieldByName('PorProntoPago').AsFloat),
          F(qCab.FieldByName('ImpProntoPago').AsFloat),
          F(qCab.FieldByName('PorRappel').AsFloat),
          F(qCab.FieldByName('ImpRappel').AsFloat),
          F(qCab.FieldByName('PorFinanciacion').AsFloat),
          F(qCab.FieldByName('ImpFinanciacion').AsFloat),
          F(qCab.FieldByName('ImpPortes').AsFloat),
          F(qCab.FieldByName('PorRetencion').AsFloat),
          F(qCab.FieldByName('ImpRetencion').AsFloat),
          F(qCab.FieldByName('ImpBrutoLineas').AsFloat),
          F(qCab.FieldByName('ImpBaseImp').AsFloat),
          F(qCab.FieldByName('TotalIVA').AsFloat),
          F(qCab.FieldByName('ImpFactura').AsFloat),
          F(fTotal), ValorOrNull(CodigoFormaPagoCompra(qCab)),
          TempPvToken(oMapTemp,
                      qCab.FieldByName('TemporadaNombre').AsString),
          ValorOrNull(sAgrupar),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Entidad').AsString), 1, 4)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('Oficina').AsString), 1, 4)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('DigitosControl').AsString), 1, 2)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('NroCuenta').AsString), 1, 10)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('IBAN').AsString), 1, 34)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('ObsFactura').AsString), 1, 1000)),
          ValorOrNull(Copy(Trim(qCab.FieldByName('ObsFactura').AsString), 1, 2000)),
          ValorOrNull('N'), sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('factura_compra', sSerie + '/' + sNum, E.Message, '',
            'requiere Empresas/Proveedores/Almacenes migrados');
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
  oMapTal := TDictionary<string, Integer>.Create;
  CargarMapaTallaje(Eng, oMapTal);
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_facturas_compra_lineas',
                             cColsLin, BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  compras factura 2/2: lineas (ocfacproart)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocfacproart'));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de factura de compra...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Format('%d.%s', [qLin.FieldByName('Ejercicio').AsInteger,
                  Trim(qLin.FieldByName('Serie').AsString)]);
      sNum := Format('%.6d', [qLin.FieldByName('NroFactura').AsInteger]);
      sLinea := Format('%.4d',
                 [qLin.FieldByName('LineaFactuzam').AsInteger]);
      sArt := Trim(qLin.FieldByName('Articulo').AsString);
      sUni := ConstruirCodigoUnidad(sArt,
                Trim(qLin.FieldByName('DescColor').AsString),
                Trim(qLin.FieldByName('Talla').AsString));
      sAlm := UpperCase(Trim(qLin.FieldByName('AbrevAlmLin').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      if qLin.FieldByName('NroAlbaran').AsInteger > 0 then
      begin
        sNumAlb := ValorOrNull(Format('%.6d',
                     [qLin.FieldByName('NroAlbaran').AsInteger]));
        sSerieAlb := ValorOrNull(Format('%d.%s',
                       [qLin.FieldByName('EjercicioAlbaran').AsInteger,
                        Trim(qLin.FieldByName('SerieAlbaran').AsString)]));
        if qLin.FieldByName('LineaAlbaran').AsInteger > 0 then
          sLineaAlb := ValorOrNull(Format('%.4d',
                         [qLin.FieldByName('LineaAlbaran').AsInteger]))
        else
          sLineaAlb := 'NULL';
      end
      else
      begin
        sNumAlb := 'NULL';
        sSerieAlb := 'NULL';
        sLineaAlb := 'NULL';
      end;
      sVariacion := Trim(qLin.FieldByName('DescColor').AsString) + '/' +
                    Trim(qLin.FieldByName('Talla').AsString);
      try
        bLin.Add(UnirValores([
          ValorOrNull(sNum), ValorOrNull(sSerie), ValorOrNull(sLinea),
          sNumAlb, sSerieAlb, sLineaAlb,
          ValorOrNull(sArt), ValorOrNull(sUni),
          ValorOrNull(Trim(qLin.FieldByName('Modelo').AsString)),
          AcPivotToken(oMapTal, sArt),
          ValorOrNull(Copy(Trim(qLin.FieldByName('Descripcion').AsString), 1, 100)),
          F(qLin.FieldByName('Cantidad').AsFloat),
          F(qLin.FieldByName('Cantidad').AsFloat),
          ValorOrNull(TipoIvaArticuloCompra(qLin.FieldByName('PorIVA').AsFloat)),
          F(qLin.FieldByName('PorIVA').AsFloat),
          F(qLin.FieldByName('PrecioSIva').AsFloat),
          F(qLin.FieldByName('PrecioCIva').AsFloat),
          F(qLin.FieldByName('ImpNetoSIva').AsFloat),
          ValorOrNull(sAlm), ValorOrNull(Copy(sVariacion, 1, 200)),
          sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('factura_compra_linea', sSerie + '/' + sNum, E.Message,
            Format('orden=%s', [sLinea]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
    Eng.Log('  facturas de compra: lineas enviadas a destino = %d.',
            [bLin.TotalInsertadas]);
  finally
    bLin.Free;
    qLin.Free;
    oMapTal.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaCompra(Eng, 'fza_facturas_compra', 'FACC');
    EnlazarAlbaranesDesdeFacturasCompra(Eng);
    Eng.Log('  facturas de compra: empresa, contadores y albaranes enlazados.');
  end;
end;

initialization
  fsCompras := TFormatSettings.Create('en-US');

end.
