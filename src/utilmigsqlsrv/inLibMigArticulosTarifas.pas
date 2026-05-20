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
{      Color vacio o INDEFINIDO → ''  (precio del articulo entero)            }
{      Color real               → "ARTICULO/COLOR_NORMALIZADO"                }
{                                                                              }
{    Idempotente: bulk INSERT IGNORE pero la PK destino es auto-increment,   }
{    asi que en realidad NO ignora duplicados de mismo                        }
{    (CODIGO_ART, CODIGO_TAR, CODIGO_UNIDAD). Solucion: limpiar con           }
{    "Reset migr." entre corridas si quieres re-importar precios.             }
{******************************************************************************}
unit inLibMigArticulosTarifas;

interface

uses
  UMigEngine;

procedure MigrarArticulosTarifas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  Data.DB, Uni;

function EsColorVacio(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'INDEFINIDO') or (u = '00');
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
end;

// Lee `dbo.octar` (las tarifas reales del legacy) y por cada una
// crea (si no existe) una fila en `fza_tarifas` usando su descripcion
// como nombre y un codigo sanitizado como CODIGO_TAR_ARTTAR. Tambien
// rellena oMapaTarifas[iTarifa] -> sCodigoCanonico para que el bucle
// principal sepa que codigo usar al insertar precios.
procedure AsegurarTarifasDestino(Eng: TMigEngine);
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
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_tarifas WHERE CODIGO_TAR_ARTTAR = :c';
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_tarifas (' +
        'CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, ORDEN_TAR, ' +
        'NOMBRE_TAR_TAR, ESIMP_INCL_TAR, ESDEFAULT_TAR, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, ' +
        'USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:c, :a, :o, :n, :ii, ''N'', ' +
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
        Eng.Log('  + tarifa %d "%s" -> codigo "%s" creada',
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

procedure MigrarArticulosTarifas(Eng: TMigEngine; var Stats: TMigStats);
const
  // JOIN a occolor para resolver el nombre canonico del color
  // (mismo formato que CODIGO_UNIDAD_SKU). Filtramos Serie='A' y
  // PrecioSalida > 0 para descartar filas sin precio.
  cSelectSrc =
    'SELECT t.Articulo, ' +
    '       t.Color, ' +
    '       ISNULL(c.Descripcion, t.Color) AS DescColor, ' +
    '       t.Tarifa, ' +
    '       ISNULL(t.PrecioSalida, 0)  AS PrecioSalida, ' +
    '       ISNULL(t.PrecioRebaja, 0)  AS PrecioRebaja, ' +
    '       ISNULL(t.PorDtoRebaja, 0)  AS PorDtoRebaja, ' +
    '       ISNULL(t.Margen, 0)        AS Margen ' +
    'FROM dbo.ocarttap t ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = t.Articulo ' +
    '                         AND ac.Color    = t.Color ' +
    'LEFT JOIN dbo.occolor  c  ON c.ColorBasico = ac.ColorBasico ' +
    'WHERE ISNULL(t.PrecioSalida, 0) > 0 ' +
    '  AND LTRIM(RTRIM(t.Articulo)) <> '''' ' +
    'ORDER BY t.Articulo, t.Tarifa, t.Color';
  cCols =
    'CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    'ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    'PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, ' +
    'PORCENTAJE_MARGEN_ARTTAR, FECHA_DESDE_ARTTAR, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                       TUniQuery;
  bulk:                       TBulkInsert;
  sArt, sDescColor, sCodTar:  string;
  sCodUnidad:                 string;
  sFila, sAhora, sUser:       string;
  iTarifa:                    Integer;
  fSalida, fRebaja, fDto:     Double;
  fPorDto, fMargen:           Double;
  fFinal:                     Double;
begin
  // Sin esto la vista vi_articulos_tarifas (INNER JOIN a fza_tarifas)
  // descarta las filas cuyo CODIGO_TAR_ARTTAR no existe en el master.
  AsegurarTarifasDestino(Eng);

  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_tarifas',
                              cCols, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocarttap ' +
      'WHERE ISNULL(PrecioSalida, 0) > 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      iTarifa    := qSrc.FieldByName('Tarifa').AsInteger;
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

      // CODIGO_UNIDAD_ARTTAR: vacio si no hay color (precio del
      // articulo entero), si hay color es ARTICULO/COLOR.
      if EsColorVacio(sDescColor) then
        sCodUnidad := ''
      else
        sCodUnidad := sArt + '/' + UpperCase(sDescColor);

      // Calcular PRECIO_FINAL y DTO.
      // - Si PrecioRebaja > 0 y < PrecioSalida → ese es el final.
      // - Si no → final = salida (sin descuento).
      if (fRebaja > 0) and (fRebaja < fSalida) then
      begin
        fFinal := fRebaja;
        fDto   := fSalida - fRebaja;
      end
      else
      begin
        fFinal := fSalida;
        fDto   := 0;
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
          Eng.LogError('art_tarifa', sArt, E.Message,
            Format('tar=%s precio=%g color=%s',
                   [sCodTar, fSalida, sDescColor]), '');
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
  oMapaTarifas := TDictionary<Integer, string>.Create;
finalization
  oMapaTarifas.Free;

end.
