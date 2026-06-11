{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosPropiedades                                  }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Crea la propiedad TEMPORADA y la asigna a cada articulo del legacy a    }
{    partir de `ocartp.Temporada` (codigo varchar(5), p.ej. '0', '1', '10'),  }
{    haciendo LEFT JOIN a `dbo.octem` para obtener la etiqueta legible        }
{    (`octem.Nombre`). Si el codigo no existe en octem, se usa el codigo raw }
{    como fallback. Esquema destino:                                          }
{                                                                              }
{    1. fza_propiedades: una fila con                                          }
{         CODIGO_PROP_ARTPROP = 'TEMPORADA'                                    }
{         NOMBRE_PROP_PROP   = 'Temporada'                                     }
{         TIPO_VALOR_PROP    = 'LISTA' (los valores van en fza_propiedades_   }
{                              valores y se referencian por ID)               }
{                                                                              }
{    2. fza_propiedades_valores: una fila por cada octem.Nombre distinto       }
{       referenciado por algun articulo. Ej: 'INDEFINIDA',                    }
{       'PRIM-VER 2014', 'OTÑO-INVI 2006', etc.                                }
{                                                                              }
{    3. fza_articulos_propiedades: una fila por articulo con la temporada    }
{       que tenia en el legacy, enlazada por ID_PV_ARTPROP al valor.          }
{                                                                              }
{    Segunda pasada (temporada por COLOR): ocartcol tiene su propia columna   }
{    Temporada a nivel (Articulo, Color). Para cada color cuya temporada     }
{    DIFIERE de la del articulo se escribe una fila extra en                  }
{    fza_articulos_propiedades con CODIGO_UNIDAD_ARTPROP = 'ART/COLOR' (el    }
{    prefijo del SKU, identico a SUBSTRING_INDEX(sku,'/',2)). Asi la vista    }
{    vi_articulos_propiedades_efectivas resuelve la temporada de color y cae  }
{    a la de articulo donde el color no la fija. Si el color coincide con el  }
{    articulo NO se escribe nada (la vista ya hereda). El catalogo de valores }
{    (paso 1) se nutre de ambas fuentes (ocartp y ocartcol).                  }
{                                                                              }
{    Idempotente:                                                              }
{      - fza_propiedades: comprueba CODIGO_PROP_ARTPROP, si existe se salta. }
{      - fza_propiedades_valores: chequea (ID_PROP_PV, PV), idem.            }
{      - fza_articulos_propiedades: PK (CODIGO_ART_ART, CODIGO_PROP_ARTPROP) }
{        + INSERT IGNORE en el bulk.                                          }
{******************************************************************************}
unit inLibMigArticulosPropiedades;

interface

uses
  UMigEngine;

procedure MigrarArticulosPropiedades(Eng: TMigEngine;
                                      var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni;

// =========================================================================
//  Helpers locales
// =========================================================================

// Filtro de "Temporada valida": acepta cualquier valor no-vacio tras
// Trim. En este cliente la Temporada en ocartp es un codigo corto
// numerico ('0', '1', '10', '11'...), asi que NO podemos exigir
// longitud minima 2 ni presencia de letras — descartariamos
// temporadas legitimas ('0' = permanente, '1' = primera, etc.).
function EsTemporadaValida(const s: string): Boolean;
begin
  Result := Trim(s) <> '';
end;

procedure AsegurarPropiedadTemporada(Eng: TMigEngine);
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_propiedades ' +
      'WHERE CODIGO_PROP_ARTPROP = ''TEMPORADA''';
    qChk.Open;
    if not qChk.IsEmpty then Exit;
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_propiedades (' +
        'CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP, ' +
        'ESACTIVO_PROP, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (''TEMPORADA'', ''Temporada'', ''LISTA'', ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, ' +
              ':USUARIO_ALTA, :USUARIO_MODIF)';
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Eng.Log('  + propiedad TEMPORADA creada');
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Inserta un valor de propiedad si no existe ya. Devuelve True si
// inserto.
function InsertarValorPropiedad(Eng: TMigEngine;
                                 const sPV: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA'' AND PV = :v';
    qChk.ParamByName('v').AsString := sPV;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_propiedades_valores (' +
        'ID_PROP_PV, PV, ESACTIVO_PV, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (''TEMPORADA'', :v, ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, ' +
              ':USUARIO_ALTA, :USUARIO_MODIF)';
    qIns.ParamByName('v').AsString := sPV;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

function BuscarIdPV(Eng: TMigEngine; const sPV: string): Integer;
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   :=
      'SELECT ID_PV_ARTPROP FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA'' AND PV = :v LIMIT 1';
    q.ParamByName('v').AsString := sPV;
    q.Open;
    if q.IsEmpty then
      Result := 0
    else
      Result := q.FieldByName('ID_PV_ARTPROP').AsInteger;
  finally
    q.Free;
  end;
end;

// Carga el catalogo de valores de TEMPORADA (PV -> ID_PV_ARTPROP) en
// memoria para resolver la temporada de cada color en O(1), sin un
// SELECT por fila (ocartcol puede traer decenas de miles de filas).
procedure CargarMapaPV(Eng: TMigEngine;
                       Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   :=
      'SELECT PV, ID_PV_ARTPROP FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA''';
    q.Open;
    while not q.Eof do
    begin
      Mapa.AddOrSetValue(
        Trim(q.FieldByName('PV').AsString),
        q.FieldByName('ID_PV_ARTPROP').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// =========================================================================
//  Segunda pasada: temporada por COLOR (ocartcol -> nivel color)
// =========================================================================
// Solo baja a nivel color (CODIGO_UNIDAD_ARTPROP = 'ART/COLOR') las
// temporadas de ocartcol que DIFIEREN de la del articulo (ocartp). Donde
// coinciden no se escribe nada: la vista efectiva ya hereda la de
// articulo. El segmento de color se calcula igual que el SKU para que
// 'ART/COLOR' case con SUBSTRING_INDEX(CODIGO_UNIDAD_SKU, '/', 2).
procedure AsignarTemporadasPorColor(Eng: TMigEngine;
                                    var Stats: TMigStats);
const
  // ColorSlot identico a inLibMigArticulosSkus / MigrarArticulosColores:
  // prefiere el Color del legacy, cae a la Descripcion del color basico
  // (occolor) y, si nada, '0'.
  cColorSlot =
    'CASE ' +
    '  WHEN ac.Color IS NOT NULL ' +
    '    AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '    THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '  WHEN c.Descripcion IS NOT NULL ' +
    '    AND UPPER(LTRIM(RTRIM(c.Descripcion))) <> ''INDEFINIDO'' ' +
    '    THEN UPPER(LTRIM(RTRIM(c.Descripcion))) ' +
    '  ELSE ''0'' ' +
    'END';
  // Temporada legible del color y del articulo, para comparar overrides.
  cPvColor = 'ISNULL(NULLIF(LTRIM(RTRIM(tc.Nombre)), ''''), ac.Temporada)';
  cPvArt   = 'ISNULL(NULLIF(LTRIM(RTRIM(tp.Nombre)), ''''), p.Temporada)';
  // FROM + WHERE comun a SELECT de datos y a COUNT(*). El filtro clave
  // es que la temporada de color difiera de la de articulo (incluye el
  // caso "articulo sin temporada, color con temporada").
  cFrom =
    'FROM dbo.ocartcol ac WITH (NOLOCK) ' +
    'LEFT JOIN dbo.occolor c WITH (NOLOCK) ' +
    '       ON c.ColorBasico = ac.ColorBasico ' +
    'LEFT JOIN dbo.octem tc WITH (NOLOCK) ' +
    '       ON tc.Temporada = ac.Temporada ' +
    'LEFT JOIN dbo.ocartp p WITH (NOLOCK) ' +
    '       ON p.Articulo = ac.Articulo ' +
    'LEFT JOIN dbo.octem tp WITH (NOLOCK) ' +
    '       ON tp.Temporada = p.Temporada ' +
    'WHERE LTRIM(RTRIM(ac.Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(ISNULL(ac.Temporada, ''''))) <> '''' ' +
    '  AND ' + cPvColor + ' <> ISNULL(' + cPvArt + ', '''')';
  cSelectSrc =
    'SELECT ac.Articulo, ' +
    '       ac.Articulo + ''/'' + ' + cColorSlot + ' AS CodUnidad, ' +
    '       ' + cPvColor + ' AS PV ' +
    cFrom + ' ' +
    'ORDER BY ac.Articulo, CodUnidad';
  cContar = 'SELECT COUNT(*) ' + cFrom;
  cColsAP =
    'CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP, ' +
    'ID_PV_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA';
var
  qSrc:                  TUniQuery;
  bulk:                  TBulkInsert;
  oPvMap:                TDictionary<string, Integer>;
  sArt, sCodUnidad, sPV: string;
  sFila, sAhora, sUser:  string;
  iIdPV:                 Integer;
begin
  Eng.Log('  2a pasada: temporada por color (ocartcol, solo overrides)...');
  oPvMap := TDictionary<string, Integer>.Create;
  qSrc   := nil;
  bulk   := nil;
  try
    CargarMapaPV(Eng, oPvMap);
    Eng.Log('  cache: %d valores de TEMPORADA', [oPvMap.Count]);
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    qSrc   := NuevoQOrigen(Eng, cSelectSrc);
    // UniDirectional: no cachea en memoria las filas de ocartcol.
    qSrc.UniDirectional := True;
    bulk   := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_propiedades',
                                  cColsAP, 5000);
    Eng.SetTotal(Eng.ContarOrigen(cContar));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en temporada-color, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sCodUnidad := Trim(qSrc.FieldByName('CodUnidad').AsString);
      sPV        := Trim(qSrc.FieldByName('PV').AsString);
      if (sArt = '') or (sCodUnidad = '')
      or (not EsTemporadaValida(sPV)) then
        Inc(Stats.Saltadas)
      else if not oPvMap.TryGetValue(sPV, iIdPV) then
      begin
        Inc(Stats.Errores);
        Eng.LogError('art_prop_color', sArt,
          Format('valor TEMPORADA "%s" no encontrado', [sPV]),
          Format('UNIDAD=%s', [sCodUnidad]),
          'el paso de catalogo deberia haberlo creado');
      end
      else
      begin
        sFila := Format('%s, ''TEMPORADA'', %s, %d, %s, %s',
          [ValorOrNull(sArt), ValorOrNull(sCodUnidad),
           iIdPV, sAhora, sUser]);
        try
          bulk.Add(sFila);
          Inc(Stats.Insertadas);
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('art_prop_color', sArt, E.Message,
              Format('UNIDAD=%s TEMPORADA=%s', [sCodUnidad, sPV]), '');
            raise;
          end;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
    oPvMap.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarArticulosPropiedades(Eng: TMigEngine;
                                      var Stats: TMigStats);
const
  // En el legacy ocartp.Temporada es un codigo corto (0, 1, 10, 11...)
  // que referencia a dbo.octem. dbo.octem.Nombre tiene la etiqueta
  // legible ('INDEFINIDA', 'PRIM-VER 2014', 'OTÑO-INVI 2006'...). Como
  // valor PV de la propiedad guardamos el Nombre (legible).
  // Si el codigo de ocartp no existe en octem o el Nombre es vacio,
  // usamos el codigo raw como fallback (no perdemos asignaciones).
  cExprNombre =
    'ISNULL(NULLIF(LTRIM(RTRIM(te.Nombre)), ''''), p.Temporada)';
  // Misma expresion pero para la temporada de color (ocartcol/tc).
  cExprNombreCol =
    'ISNULL(NULLIF(LTRIM(RTRIM(tc.Nombre)), ''''), ac.Temporada)';
  // El catalogo de valores se nutre de AMBAS fuentes: temporada de
  // articulo (ocartp) y temporada de color (ocartcol). UNION deduplica.
  cSelectValores =
    'SELECT PV FROM ( ' +
    '  SELECT DISTINCT ' + cExprNombre + ' AS PV ' +
    '  FROM dbo.ocartp p WITH (NOLOCK) ' +
    '  LEFT JOIN dbo.octem te WITH (NOLOCK) ' +
    '         ON te.Temporada = p.Temporada ' +
    '  WHERE LTRIM(RTRIM(ISNULL(p.Temporada, ''''))) <> '''' ' +
    '  UNION ' +
    '  SELECT DISTINCT ' + cExprNombreCol + ' AS PV ' +
    '  FROM dbo.ocartcol ac WITH (NOLOCK) ' +
    '  LEFT JOIN dbo.octem tc WITH (NOLOCK) ' +
    '         ON tc.Temporada = ac.Temporada ' +
    '  WHERE LTRIM(RTRIM(ISNULL(ac.Temporada, ''''))) <> '''' ' +
    ') U ' +
    'ORDER BY PV';
  cSelectAsign =
    'SELECT p.Articulo, ' + cExprNombre + ' AS PV ' +
    'FROM dbo.ocartp p WITH (NOLOCK) ' +
    'LEFT JOIN dbo.octem te WITH (NOLOCK) ' +
    '       ON te.Temporada = p.Temporada ' +
    'WHERE LTRIM(RTRIM(p.Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(ISNULL(p.Temporada, ''''))) <> '''' ' +
    'ORDER BY p.Articulo';
  cColsAP =
    'CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
    'INSTANTE_ALTA, USUARIO_ALTA';
var
  qVal, qSrc:                 TUniQuery;
  bulk:                       TBulkInsert;
  sTemp, sArt:                string;
  sFila, sAhora, sUser:       string;
  iIdPV:                      Integer;
begin
  AsegurarPropiedadTemporada(Eng);

  // 1. Volcar el catalogo de temporadas distintas
  qVal := NuevoQOrigen(Eng, cSelectValores);
  try
    qVal.Open;
    while not qVal.Eof do
    begin
      sTemp := Trim(qVal.FieldByName('PV').AsString);
      if EsTemporadaValida(sTemp) then
      begin
        if InsertarValorPropiedad(Eng, sTemp) then
          Eng.Log('  + valor TEMPORADA "%s" creado', [sTemp]);
      end;
      qVal.Next;
    end;
  finally
    qVal.Free;
  end;

  // 2. Asignar la temporada a cada articulo (bulk insert)
  qSrc := NuevoQOrigen(Eng, cSelectAsign);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_propiedades',
                              cColsAP, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp WITH (NOLOCK) ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND LTRIM(RTRIM(ISNULL(Temporada, ''''))) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt  := Trim(qSrc.FieldByName('Articulo').AsString);
      sTemp := Trim(qSrc.FieldByName('PV').AsString);
      if (sArt = '') or (not EsTemporadaValida(sTemp)) then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      iIdPV := BuscarIdPV(Eng, sTemp);
      if iIdPV = 0 then
      begin
        Inc(Stats.Errores);
        Eng.LogError('art_prop', sArt,
          Format('valor TEMPORADA "%s" no encontrado', [sTemp]),
          '', 'el paso de catalogo deberia haberlo creado');
        qSrc.Next;
        Continue;
      end;
      sFila := Format('%s, ''TEMPORADA'', %d, %s, %s',
        [ValorOrNull(sArt), iIdPV, sAhora, sUser]);
      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('art_prop', sArt, E.Message,
            Format('TEMPORADA=%s', [sTemp]), '');
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
  // Segunda pasada: temporada por color (overrides sobre ocartcol).
  // Comparte la transaccion del paso (la abre/cierra el motor).
  AsignarTemporadasPorColor(Eng, Stats);
end;

end.
