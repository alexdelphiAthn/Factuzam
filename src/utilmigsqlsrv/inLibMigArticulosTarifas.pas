{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosTarifas                                      }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los precios PVP (y otras tarifas) desde `dbo.ocarttap` →           }
{    `fza_articulos_tarifas`.                                                  }
{                                                                              }
{    `ocarttap` tiene PK (Articulo, Color, Tarifa, Serie). Filtramos Serie='A'}
{    (la principal del legacy) para no duplicar precios. Tomamos:              }
{      PrecioSalida    → PRECIO_SALIDA_ARTTAR  (PVP de etiqueta)              }
{      PrecioRebaja    → PRECIO_FINAL_ARTTAR  (precio efectivo si esta en     }
{                                              rebajas; si no, =PrecioSalida) }
{      PrecioSalida - PrecioRebaja  → PRECIO_DTO_ARTTAR                       }
{      PorDtoRebaja    → PORCENTAJE_DTO_ARTTAR                                 }
{      Margen          → PORCENTAJE_MARGEN_ARTTAR (si > 0)                    }
{                                                                              }
{    Mapeo de Tarifa (codigo numerico legacy → codigo destino):               }
{      1 → 'PVP'         (la tarifa principal de Herreras)                    }
{      2 → 'VENTAMAYOR'  (precio venta mayor)                                 }
{      n → IntToStr(n)   (resto se queda con su numero como texto)            }
{                                                                              }
{    CODIGO_UNIDAD_ARTTAR:                                                     }
{      Color vacio → ''  (precio del articulo entero)                         }
{      Color real  → "ARTICULO/CODIGO_COLOR_PROVEEDOR"                        }
{                                                                              }
{    Idempotente: bulk INSERT IGNORE pero la PK destino es auto-increment,   }
{    asi que en realidad NO ignora duplicados de mismo                        }
{    (CODIGO_ART, CODIGO_TAR, CODIGO_UNIDAD). Solucion: limpiar con           }
{    "Reset migr." entre corridas si quieres re-importar precios.             }
{******************************************************************************}
unit inLibMigArticulosTarifas;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarArticulosTarifas(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  Data.DB, Uni;

function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

// Mapa global Tarifa(int) -> CODIGO_TAR_ARTTAR(texto). Se rellena en
// AsegurarTarifasDestino y se consulta en el bucle. Asi cada cliente
// tiene su propio mapeo (PRUEBA, P.V.P., OTRA...) sin hardcodear.
var
  oMapaTarifas: TDictionary<Integer, string>;

// Sanitiza la Descripcion del legacy para que sirva como
// CODIGO_TAR_ARTTAR (mayusculas, sin espacios/puntos/comas).
// 'P.V.P.' -> 'PVP', 'VENTA MAYOR' -> 'VENTAMAYOR'.
function CodigoTarifaDesde(const sDescripcion: string;
                            iTarifa: Integer): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(sDescripcion) do
  begin
    c := sDescripcion[i];
    case c of
      'A'..'Z', '0'..'9', '_': Result := Result + c;
      'a'..'z':                Result := Result + UpCase(c);
      ' ', '-', '/':           Result := Result + '_';
      // puntos, comas y otros se descartan ('P.V.P.' -> 'PVP')
    end;
  end;
  if Result = '' then
    Result := Format('TAR%d', [iTarifa]);
  // CODIGO_TAR_ARTTAR es varchar(10) tanto en fza_tarifas como en
  // fza_articulos_tarifas: truncamos para evitar "Data too long". Como este
  // codigo alimenta oMapaTarifas (que usa MapearTarifa al insertar precios),
  // el valor truncado queda consistente en ambas tablas.
  if Length(Result) > 10 then
    Result := Copy(Result, 1, 10);
end;

// Lee `dbo.octar` (las tarifas reales del legacy) y por cada una
// crea (si no existe) una fila en `fza_tarifas` usando su descripcion
// como nombre y un codigo sanitizado como CODIGO_TAR_ARTTAR. Tambien
// rellena oMapaTarifas[iTarifa] -> sCodigoCanonico para que el bucle
// principal sepa que codigo usar al insertar precios.
procedure AsegurarTarifasDestino(Eng: IContextoMigracion);
const
  cSelectOctar =
    'SELECT Tarifa, Descripcion, IvaIncluido, Estado ' +
    'FROM dbo.octar ' +
    'ORDER BY Tarifa';
var
  qSrc, qChk, qIns:        TUniQuery;
  iTarifa:                 Integer;
  sDescripcion, sCodigo:   string;
  sIvaIncl, sActivo:       string;
  iOrden:                  Integer;
begin
  oMapaTarifas.Clear;
  qSrc := NuevoQOrigen(Eng, cSelectOctar);
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_tarifas WHERE CODIGO_TAR_ARTTAR = :c';
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   :=
      'INSERT INTO fza_tarifas (' +
        'CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, ORDEN_TAR, ' +
        'NOMBRE_TAR_TAR, ESIMP_INCL_TAR, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, ' +
        'USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:c, :a, :o, :n, :ii, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, ' +
              ':USUARIO_ALTA, :USUARIO_MODIF)';

    iOrden := 10;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      iTarifa      := qSrc.FieldByName('Tarifa').AsInteger;
      sDescripcion := Trim(qSrc.FieldByName('Descripcion').AsString);
      sCodigo      := CodigoTarifaDesde(sDescripcion, iTarifa);
      oMapaTarifas.AddOrSetValue(iTarifa, sCodigo);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCodigo;
      qChk.Open;
      if qChk.IsEmpty then
      begin
        sIvaIncl := Trim(qSrc.FieldByName('IvaIncluido').AsString);
        if (sIvaIncl = '') or (UpperCase(sIvaIncl) = 'S') then
          sIvaIncl := 'S' else sIvaIncl := 'N';
        sActivo := UpperCase(Trim(qSrc.FieldByName('Estado').AsString));
        if sActivo = 'B' then sActivo := 'N' else sActivo := 'S';

        qIns.ParamByName('c').AsString  := sCodigo;
        qIns.ParamByName('a').AsString  := sActivo;
        qIns.ParamByName('o').AsInteger := iOrden;
        qIns.ParamByName('n').AsString  := sDescripcion;
        qIns.ParamByName('ii').AsString := sIvaIncl;
        RellenarAuditoria(qIns, Eng.Usuario);
        qIns.ExecSQL;
        Eng.Registro.Log('  + tarifa %d "%s" -> codigo "%s" creada',
                [iTarifa, sDescripcion, sCodigo]);
        Inc(iOrden, 10);
      end;
      qSrc.Next;
    end;
  finally
    qIns.Free;
    qChk.Free;
    qSrc.Free;
  end;
end;

// Lookup por Tarifa(int) -> codigo destino. Si no se encuentra
// (raro: significaria que ocarttap referencia una Tarifa que no
// esta en octar), devolvemos IntToStr(iTarifa) como fallback.
function MapearTarifa(iTarifa: Integer): string;
begin
  if not oMapaTarifas.TryGetValue(iTarifa, Result) then
    Result := Format('TAR%d', [iTarifa]);
end;

function NumOrNull(fValor: Double): string;
begin
  if IsZero(fValor) then
    Result := 'NULL'
  else
    Result := FloatToStr(fValor,
      TFormatSettings.Create('en-US'));  // punto decimal
end;

procedure MigrarArticulosTarifas(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  // En el legacy ocarttap tiene filas por (Articulo, Color, Tarifa).
  // En la mayoria de articulos el precio es igual para todos los
  // colores (precio "padre"), pero a veces los colores difieren mas
  // de 0.10 EUR (p.ej. un color premium). Regla:
  //   - spread (MAX-MIN) <= 0.10 OR un solo color distinto
  //     -> una sola fila por (Articulo, Tarifa) a nivel articulo
  //     (CODIGO_UNIDAD_ARTTAR = '').
  //   - spread > 0.10 con multiples colores -> una fila por
  //     (Articulo, Tarifa, ColorNormalizado) con
  //     CODIGO_UNIDAD_ARTTAR = 'ARTICULO/COLOR' (primer atributo).
  //
  // ColorNormalizado: misma convencion que inLibMigArticulosSkus
  // (slot de color del CODIGO_UNIDAD_SKU). Asi el sufijo coincide
  // con el SKU si existiera. El '0' y '00' son colores reales en legacy.
  // Separamos el WITH (cCTE) del cuerpo (cBody) porque SQL Server NO
  // admite un CTE dentro de un subquery — la query del cursor usa
  // cCTE + cBody + cOrden, pero la del COUNT necesita poner el WITH
  // FUERA y meter solo cBody en SELECT COUNT(*) FROM (...).
  cCTE =
    'WITH norm AS ( ' +
    '  SELECT t.Articulo, t.Tarifa, ' +
    '         ISNULL(t.PrecioSalida, 0) AS PrecioSalida, ' +
    '         ISNULL(t.PrecioRebaja, 0) AS PrecioRebaja, ' +
    '         ISNULL(t.PorDtoRebaja, 0) AS PorDtoRebaja, ' +
    '         ISNULL(t.Margen, 0)       AS Margen, ' +
    // Usa el codigo interno de ocartcol.Color como suffix. El color de
    // tarifa solo queda como respaldo si no existe ficha de color.
    '         CASE ' +
    '           WHEN ac.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '           WHEN t.Color IS NOT NULL ' +
    '             AND LTRIM(RTRIM(t.Color)) <> '''' ' +
    '             THEN UPPER(LTRIM(RTRIM(t.Color))) ' +
    '           ELSE ''0'' ' +
    '         END AS ColorNorm ' +
    '  FROM dbo.ocarttap t WITH (NOLOCK) ' +
    '  LEFT JOIN dbo.ocartcol ac WITH (NOLOCK) ' +
    '         ON ac.Articulo = t.Articulo AND ac.Color = t.Color ' +
    '  LEFT JOIN dbo.occolor c WITH (NOLOCK) ' +
    '         ON c.ColorBasico = ac.ColorBasico ' +
    '  WHERE ISNULL(t.PrecioSalida, 0) > 0 ' +
    '    AND LTRIM(RTRIM(t.Articulo)) <> '''' ' +
    '), ' +
    'por_color AS ( ' +
    '  SELECT Articulo, Tarifa, ColorNorm, ' +
    '         MAX(PrecioSalida) AS PrecioSalida, ' +
    '         MAX(PrecioRebaja) AS PrecioRebaja, ' +
    '         MAX(PorDtoRebaja) AS PorDtoRebaja, ' +
    '         MAX(Margen)       AS Margen ' +
    '  FROM norm ' +
    '  GROUP BY Articulo, Tarifa, ColorNorm ' +
    '), ' +
    'spread AS ( ' +
    '  SELECT Articulo, Tarifa, ' +
    '         MIN(PrecioSalida) AS PrecioMin, ' +
    '         MAX(PrecioSalida) AS PrecioMax, ' +
    '         COUNT(*)          AS NColores ' +
    '  FROM por_color ' +
    '  GROUP BY Articulo, Tarifa ' +
    ') ';
  cBody =
    // Caso A: spread bajo o un solo color -> nivel articulo (MAX)
    'SELECT pc.Articulo, pc.Tarifa, ' +
    '       '''' AS DescColor, ' +
    '       MAX(pc.PrecioSalida) AS PrecioSalida, ' +
    '       MAX(pc.PrecioRebaja) AS PrecioRebaja, ' +
    '       MAX(pc.PorDtoRebaja) AS PorDtoRebaja, ' +
    '       MAX(pc.Margen)       AS Margen, ' +
    '       ''ARTICULO'' AS Granularidad ' +
    'FROM por_color pc ' +
    'INNER JOIN spread s ON s.Articulo = pc.Articulo ' +
    '                    AND s.Tarifa  = pc.Tarifa ' +
    'WHERE s.NColores <= 1 ' +
    '   OR (s.PrecioMax - s.PrecioMin) <= 0.10 ' +
    'GROUP BY pc.Articulo, pc.Tarifa ' +
    'UNION ALL ' +
    // Caso B: multiples colores y spread > 0.10 -> nivel color
    'SELECT pc.Articulo, pc.Tarifa, ' +
    '       pc.ColorNorm AS DescColor, ' +
    '       pc.PrecioSalida, pc.PrecioRebaja, pc.PorDtoRebaja, ' +
    '       pc.Margen, ' +
    '       ''COLOR'' AS Granularidad ' +
    'FROM por_color pc ' +
    'INNER JOIN spread s ON s.Articulo = pc.Articulo ' +
    '                    AND s.Tarifa  = pc.Tarifa ' +
    'WHERE s.NColores > 1 ' +
    '  AND (s.PrecioMax - s.PrecioMin) > 0.10';
  cSelectSrc = cCTE + cBody;
  cOrden = ' ORDER BY 1, 2, 3';
  cCols =
    'CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    'ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    'PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, ' +
    'PORCENTAJE_MARGEN_ARTTAR, FECHA_DESDE_ARTTAR, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                       TUniQuery;
  bulk:                       TBulkInsert;
  sArt, sCodTar, sGran:       string;
  sCodUnidad, sDescColor:     string;
  sFila, sAhora, sUser:       string;
  iTarifa:                    Integer;
  fSalida, fRebaja, fDto:     Double;
  fPorDto, fMargen:           Double;
  fFinal:                     Double;
begin
  // Sin esto la vista vi_articulos_tarifas (INNER JOIN a fza_tarifas)
  // descarta las filas cuyo CODIGO_TAR_ARTTAR no existe en el master.
  AsegurarTarifasDestino(Eng);

  qSrc := NuevoQOrigen(Eng, cSelectSrc + cOrden);
  bulk := TBulkInsert.Create(Eng.Datos.ConexionDestino, 'fza_articulos_tarifas',
                              cCols, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    // Total = filas que realmente devuelve la query origen. Envolvemos
    // el SELECT entero en COUNT(*) para que coincida 1:1 con las
    // iteraciones del cursor. Antes contabamos via raw t.Color y eso
    // sobreestimaba en casos en que varios codigos normalizan al mismo
    // ColorNorm (~1% de diferencia), dejando el progreso colgado en
    // 98% al terminar.
    // SQL Server NO admite WITH dentro de un subquery, asi que el
    // CTE queda fuera y solo el cuerpo (UNION ALL) va dentro del
    // SELECT COUNT(*) FROM (...).
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      cCTE + 'SELECT COUNT(*) FROM (' + cBody + ') AS Q'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      iTarifa    := qSrc.FieldByName('Tarifa').AsInteger;
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      sGran      := Trim(qSrc.FieldByName('Granularidad').AsString);
      fSalida    := qSrc.FieldByName('PrecioSalida').AsFloat;
      fRebaja    := qSrc.FieldByName('PrecioRebaja').AsFloat;
      fPorDto    := qSrc.FieldByName('PorDtoRebaja').AsFloat;
      fMargen    := qSrc.FieldByName('Margen').AsFloat;

      if sArt = '' then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sCodTar := MapearTarifa(iTarifa);
      // Granularidad la define la query origen:
      //   - ARTICULO: precio uniforme entre colores -> CODIGO_UNIDAD vacio
      //   - COLOR   : spread > 0.10 -> CODIGO_UNIDAD = ART/COLOR (primer
      //     atributo). Soportado por vi_articulos_tarifas (LEFT JOIN
      //     tolera valor sin match en fza_articulos_skus).
      if (sGran = 'COLOR') and (sDescColor <> '') then
        sCodUnidad := sArt + '/' + UpperCase(sDescColor)
      else
        sCodUnidad := '';

      // Calcular PRECIO_FINAL y DTO.
      // - Si PrecioRebaja > 0 y < PrecioSalida → ese es el final.
      // - Si no → final = salida (sin descuento) y limpiamos fPorDto: el
      //   legacy a veces trae PorDtoRebaja basura (típicamente 100) en
      //   filas sin rebaja real; si no lo reseteamos, queda almacenado
      //   en PORCENTAJE_DTO_ARTTAR y la pestaña Tarifas muestra "100 %"
      //   con PRECIO_DTO_ARTTAR vacío y PRECIO_FINAL = PRECIO_SALIDA
      //   (inconsistente). Saneo retroactivo:
      //   DESARROLLOS EN CURSO/tarifas_limpiar_porcentaje_dto_basura.sql
      if (fRebaja > 0) and (fRebaja < fSalida) then
      begin
        fFinal := fRebaja;
        fDto   := fSalida - fRebaja;
      end
      else
      begin
        fFinal  := fSalida;
        fDto    := 0;
        fPorDto := 0;
      end;

      // 14 columnas en cCols: el literal 'S' (ESACTIVO_ARTTAR) va
      // inline en el format y los otros 13 valores via %s.
      sFila := Format(
        '%s, %s, %s, ''S'', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
        [ValorOrNull(sArt),       // CODIGO_ART_ARTTAR
         ValorOrNull(sCodUnidad), // CODIGO_UNIDAD_ARTTAR
         ValorOrNull(sCodTar),    // CODIGO_TAR_ARTTAR
                                  // 'S' literal -> ESACTIVO_ARTTAR
         NumOrNull(fSalida),      // PRECIO_SALIDA_ARTTAR
         NumOrNull(fFinal),       // PRECIO_FINAL_ARTTAR
         NumOrNull(fDto),         // PRECIO_DTO_ARTTAR
         NumOrNull(fPorDto),      // PORCENTAJE_DTO_ARTTAR
         NumOrNull(fMargen),      // PORCENTAJE_MARGEN_ARTTAR
         '''' + FormatDateTime('yyyy-mm-dd', Now) + '''', // FECHA_DESDE
         sAhora,                  // INSTANTE_ALTA
         sAhora,                  // INSTANTE_MODIF
         sUser,                   // USUARIO_ALTA
         sUser]);                 // USUARIO_MODIF

      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.LogError('art_tarifa', sArt, E.Message,
            Format('tar=%s precio=%g gran=%s color=%s',
                   [sCodTar, fSalida, sGran, sDescColor]), '');
          raise;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'articulos_tarifas',
    'Precios PVP por artículo',
    'dbo.ocarttap → fza_articulos_tarifas',
    ['articulos'],
    MigrarArticulosTarifas);
  oMapaTarifas := TDictionary<Integer, string>.Create;
finalization
  oMapaTarifas.Free;

end.
