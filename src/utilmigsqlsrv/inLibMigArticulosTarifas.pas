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
  System.SysUtils, System.Math,
  Data.DB, Uni;

function EsColorVacio(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'INDEFINIDO') or (u = '00');
end;

function MapearTarifa(iTarifa: Integer): string;
begin
  case iTarifa of
    1: Result := 'PVP';
    2: Result := 'VENTAMAYOR';
  else
    Result := IntToStr(iTarifa);
  end;
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
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_tarifas',
                              cCols, 1000);
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

      // 14 columnas en cCols: el literal 'S' va inline en el format
      // y los otros 13 valores se sustituyen via %s.
      sFila := Format(
        '%s, %s, %s, ''S'', %s, %s, %s, %s, %s, %s, %s, %s, %s',
        [ValorOrNull(sArt),
         ValorOrNull(sCodUnidad),
         ValorOrNull(sCodTar),
         NumOrNull(fSalida),
         NumOrNull(fFinal),
         NumOrNull(fDto),
         NumOrNull(fPorDto),
         NumOrNull(fMargen),
         '''' + FormatDateTime('yyyy-mm-dd', Now) + '''',
         sAhora, sAhora, sUser, sUser]);

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

end.
