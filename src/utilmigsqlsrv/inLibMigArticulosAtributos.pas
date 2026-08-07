{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosAtributos                                    }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.1.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra las ASIGNACIONES de colores y tallas por artículo. Es decir, para  }
{    cada artículo del origen genera las filas que dicen "este artículo tiene  }
{    estos colores y/o estas tallas" en `fza_articulos_atributos_basicos`.    }
{                                                                              }
{    Mapeo:                                                                    }
{      dbo.ocartcol                    → fza_articulos_atributos_basicos       }
{        Color                         → valor proveedor / SKU                 }
{        Descripcion                   → DESCRIPCION_AAB                       }
{        ColorBasico → occolor         → ID_ATB_AAB                            }
{                                       enlazando con fza_atributos_valores    }
{                                       (ID_VA_AV='CO', AV=UPPER(color))      }
{                                                                              }
{      dbo.ocarttal (Articulo, Talla)  → fza_articulos_atributos_basicos       }
{        Orden                         → ORDEN_AAB (orden por artículo)       }
{                                       (ID_VA_AV='TAL', AV=UPPER(talla))     }
{                                                                              }
{    Pre-requisito: deben estar migrados antes los CATALOGOS MAESTROS de      }
{    colores y tallas (inLibMigAtributos). En el orquestador del UI van por   }
{    delante.                                                                  }
{                                                                              }
{    El campo `ID_ATB_AAB` (atributo basico canonico) lo dejamos NULL si no   }
{    encontramos coincidencia exacta por (ID_VA, NormalizarCodigoAtb). Mejor  }
{    NULL que un valor inventado.                                              }
{                                                                              }
{    Volumetria: con 52k articulos y multiples colores/tallas por articulo    }
{    se generan facilmente >300k filas. Usamos batchs por dominio y           }
{    transacciones (las controla el motor). El INSERT individual va por       }
{    parametros para que sea rapido sin SQL Injection.                        }
{                                                                              }
{    Idempotente: la PK (CODIGO_ART_AAB, ID_AV_AAB) descarta duplicados. En  }
{    tallas se hace UPSERT para sincronizar ORDEN_AAB al repetir la migración. }
{******************************************************************************}
unit inLibMigArticulosAtributos;

interface

uses
  UMigEngine, UMigCatalogo;

// Asigna los colores que cada artículo tiene en el legacy.
procedure MigrarArticulosColores(const Eng: IContextoMigracion; var Stats: TMigStats);

// Asigna las tallas que cada artículo tiene en el legacy.
procedure MigrarArticulosTallas(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni;

const
  BATCH_SIZE = 5000;

// =========================================================================
//  Helpers locales: caches
// =========================================================================

procedure CargarMapaAV(Eng: IContextoMigracion; const sIdVa: string;
                       Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    // ORDER BY ID_AV DESC + AddOrSetValue (gana la ultima fila) => MIN(ID_AV)
    // canonico, igual que BuscarIdAV / los SKUs, para que con AV duplicados
    // todos los paths apunten al mismo valor.
    q.SQL.Text   :=
      'SELECT AV, ID_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :v ' +
      'ORDER BY ID_AV DESC';
    q.ParamByName('v').AsString := sIdVa;
    q.Open;
    while not q.Eof do
    begin
      Mapa.AddOrSetValue(
        UpperCase(Trim(q.FieldByName('AV').AsString)),
        q.FieldByName('ID_AV').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

procedure CargarMapaATB(Eng: IContextoMigracion; const sIdVa: string;
                        Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    q.SQL.Text   :=
      'SELECT CODIGO_ATB, ID_ATB FROM fza_atributos_basicos ' +
      'WHERE ID_VA_ATB = :v';
    q.ParamByName('v').AsString := sIdVa;
    q.Open;
    while not q.Eof do
    begin
      Mapa.AddOrSetValue(
        Trim(q.FieldByName('CODIGO_ATB').AsString),
        q.FieldByName('ID_ATB').AsInteger);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

procedure CargarAsignacionesVistas(Eng: IContextoMigracion;
                                    Conjunto: TDictionary<string,
                                                           Boolean>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    q.SQL.Text   :=
      'SELECT CONCAT(CODIGO_ART_AAB, ''|'', ID_AV_AAB) ' +
      'FROM fza_articulos_atributos_basicos';
    q.Open;
    while not q.Eof do
    begin
      Conjunto.AddOrSetValue(q.Fields[0].AsString, True);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

// Inserta una fila en fza_articulos_atributos_basicos si no existe.
// Devuelve True si insertó.
function InsertarAsignacion(Eng: IContextoMigracion;
                             const sCodArt: string; iIdAv, iIdAtb: Integer;
                             const sUsuario: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_atributos_basicos ' +
      'WHERE CODIGO_ART_AAB = :a AND ID_AV_AAB = :v';
    qChk.ParamByName('a').AsString  := sCodArt;
    qChk.ParamByName('v').AsInteger := iIdAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   :=
      'INSERT INTO fza_articulos_atributos_basicos (' +
        'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:a, :v, :b, :ia, :im, :ua, :um)';
    qIns.ParamByName('a').AsString  := sCodArt;
    qIns.ParamByName('v').AsInteger := iIdAv;
    if iIdAtb > 0 then
      qIns.ParamByName('b').AsInteger := iIdAtb
    else
      qIns.ParamByName('b').Clear;
    qIns.ParamByName('ia').AsDateTime := Now;
    qIns.ParamByName('im').AsDateTime := Now;
    qIns.ParamByName('ua').AsString   := sUsuario;
    qIns.ParamByName('um').AsString   := sUsuario;
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// =========================================================================
//  MigrarArticulosColores  (ocartcol → fza_articulos_atributos_basicos)
// =========================================================================

procedure MigrarArticulosColores(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  // El valor del SKU es el codigo interno de ocartcol.Color. La descripcion
  // y el color basico son especificos de cada articulo: un mismo codigo de
  // proveedor puede representar colores distintos en articulos diferentes.
  cSelectSrc =
    'SELECT ac.Articulo, ' +
    '       CASE ' +
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS ValorColor, ' +
    '       LTRIM(RTRIM(ISNULL(ac.Descripcion, ''''))) AS DescripcionColor, ' +
    '       CASE ' +
    '         WHEN c.Descripcion IS NOT NULL ' +
    '           AND LTRIM(RTRIM(c.Descripcion)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(c.Descripcion))) ' +
    '         WHEN ac.ColorBasico IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.ColorBasico)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.ColorBasico))) ' +
    '         ELSE '''' ' +
    '       END AS ColorBasico ' +
    'FROM dbo.ocartcol ac ' +
    'LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    'WHERE LTRIM(RTRIM(ac.Articulo)) <> '''' ' +
    'ORDER BY ac.Articulo, ac.Color';
  cCols =
    'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, DESCRIPCION_AAB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cUpsert =
    'ON DUPLICATE KEY UPDATE ' +
    'ID_ATB_AAB = VALUES(ID_ATB_AAB), ' +
    'DESCRIPCION_AAB = VALUES(DESCRIPCION_AAB), ' +
    'INSTANTE_MODIF = VALUES(INSTANTE_MODIF), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
var
  qSrc:                            TUniQuery;
  bulk:                            TBulkInsert;
  oAvMap, oAtbMap:                 TDictionary<string, Integer>;
  sArt, sValorColor, sAV:          string;
  sColorBasico, sDescripcionColor: string;
  sCodAtb:                         string;
  sFila, sAhora, sIdAtb, sUser:    string;
  iIdAv, iIdAtb:                   Integer;
begin
  Eng.Registro.Log('  cargando caches en memoria...');
  oAvMap      := TDictionary<string, Integer>.Create;
  oAtbMap     := TDictionary<string, Integer>.Create;
  qSrc        := nil;
  bulk        := nil;
  try
    CargarMapaAV (Eng, 'CO', oAvMap);
    CargarMapaATB(Eng, 'CO', oAtbMap);
    Eng.Registro.Log('  cache: %d colores AV y %d basicos',
            [oAvMap.Count, oAtbMap.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    qSrc   := NuevoQOrigen(Eng, cSelectSrc);
    // UniDirectional: NO cachea las ~81k filas en memoria (solo lectura
    // hacia delante). Reduce la presion de memoria que, en paralelo con los
    // otros mappers pesados, puede provocar AccessViolation en el .exe 32b.
    qSrc.UniDirectional := True;
    bulk   := TBulkInsert.Create(Eng.Datos.ConexionDestino,
                                  'fza_articulos_atributos_basicos',
                                  cCols, BATCH_SIZE, cUpsert);
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartcol ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.Cancelacion.EstaCancelada then
      begin
        Eng.Registro.Log('  Cancelacion detectada, saliendo del mapper...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sArt              := Trim(qSrc.FieldByName('Articulo').AsString);
      sValorColor       := Trim(qSrc.FieldByName('ValorColor').AsString);
      sDescripcionColor := Trim(qSrc.FieldByName('DescripcionColor').AsString);
      sColorBasico      := Trim(qSrc.FieldByName('ColorBasico').AsString);
      if (sArt = '') or (sValorColor = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sAV := UpperCase(sValorColor);
      if not oAvMap.TryGetValue(sAV, iIdAv) then
      begin
        Inc(Stats.Errores);
        Eng.Registro.Log('  ! color "%s" no esta en fza_atributos_valores ' +
                '(articulo %s)', [sAV, sArt]);
        qSrc.Next;
        Continue;
      end;

      sIdAtb := 'NULL';
      if sColorBasico <> '' then
      begin
        sCodAtb := NormalizarCodigoAtb(sColorBasico);
        if oAtbMap.TryGetValue(sCodAtb, iIdAtb) then
          sIdAtb := IntToStr(iIdAtb);
      end;

      sFila := Format('%s, %d, %s, %s, %s, %s, %s, %s',
        [ValorOrNull(sArt), iIdAv, sIdAtb,
         ValorOrNull(sDescripcionColor),
         sAhora, sAhora, sUser, sUser]);
      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.Log('  ! error bulk color "%s" art "%s": %s',
                  [sAV, sArt, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
    oAtbMap.Free;
    oAvMap.Free;
  end;
end;

// =========================================================================
//  MigrarArticulosTallas  (ocarttal → fza_articulos_atributos_basicos)
// =========================================================================

procedure MigrarArticulosTallas(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, Talla, ISNULL(Orden, 9000) AS OrdenTalla ' +
    'FROM dbo.ocarttal ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(Talla))    <> '''' ' +
    'ORDER BY Articulo, Orden, Talla';
  cCols =
    'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ORDEN_AAB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cUpsert =
    'ON DUPLICATE KEY UPDATE ' +
    'ORDEN_AAB = VALUES(ORDEN_AAB), ' +
    'INSTANTE_MODIF = VALUES(INSTANTE_MODIF), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
var
  qSrc:                         TUniQuery;
  bulk:                         TBulkInsert;
  oAvMap, oAtbMap:              TDictionary<string, Integer>;
  oAsigVistas:                  TDictionary<string, Boolean>;
  sArt, sTalla, sAV, sCodAtb:   string;
  sFila, sAhora, sIdAtb, sUser: string;
  sKey:                         string;
  iIdAv, iIdAtb, iOrdenTalla:   Integer;
  bExistia:                     Boolean;
begin
  Eng.Registro.Log('  cargando caches en memoria...');
  oAvMap      := TDictionary<string, Integer>.Create;
  oAtbMap     := TDictionary<string, Integer>.Create;
  oAsigVistas := TDictionary<string, Boolean>.Create;
  qSrc        := nil;
  bulk        := nil;
  try
    CargarMapaAV (Eng, 'TAL', oAvMap);
    CargarMapaATB(Eng, 'TAL', oAtbMap);
    CargarAsignacionesVistas(Eng, oAsigVistas);
    Eng.Registro.Log('  cache: %d tallas AV, %d basicos, %d asignaciones',
            [oAvMap.Count, oAtbMap.Count, oAsigVistas.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    qSrc   := NuevoQOrigen(Eng, cSelectSrc);
    // UniDirectional: NO cachea las ~266k filas en memoria (solo lectura
    // hacia delante). Reduce la presion de memoria que, en paralelo con los
    // otros mappers pesados, puede provocar AccessViolation en el .exe 32b.
    qSrc.UniDirectional := True;
    bulk   := TBulkInsert.Create(Eng.Datos.ConexionDestino,
                                  'fza_articulos_atributos_basicos',
                                  cCols, BATCH_SIZE, cUpsert);
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocarttal ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND LTRIM(RTRIM(Talla))    <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.Cancelacion.EstaCancelada then
      begin
        Eng.Registro.Log('  Cancelacion detectada, saliendo del mapper...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sArt        := Trim(qSrc.FieldByName('Articulo').AsString);
      sTalla      := Trim(qSrc.FieldByName('Talla').AsString);
      iOrdenTalla := qSrc.FieldByName('OrdenTalla').AsInteger;
      if (sArt = '') or (sTalla = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sAV := UpperCase(sTalla);
      if not oAvMap.TryGetValue(sAV, iIdAv) then
      begin
        Inc(Stats.Errores);
        Eng.Registro.Log('  ! talla "%s" no esta en fza_atributos_valores ' +
                '(articulo %s)', [sAV, sArt]);
        qSrc.Next;
        Continue;
      end;

      sCodAtb := NormalizarCodigoAtb(sTalla);
      if oAtbMap.TryGetValue(sCodAtb, iIdAtb) then
        sIdAtb := IntToStr(iIdAtb)
      else
        sIdAtb := 'NULL';

      sKey := sArt + '|' + IntToStr(iIdAv);
      bExistia := oAsigVistas.ContainsKey(sKey);

      sFila := Format('%s, %d, %s, %d, %s, %s, %s, %s',
        [ValorOrNull(sArt), iIdAv, sIdAtb, iOrdenTalla,
         sAhora, sAhora, sUser, sUser]);
      try
        bulk.Add(sFila);
        if bExistia then
          Inc(Stats.Saltadas)
        else
        begin
          oAsigVistas.AddOrSetValue(sKey, True);
          Inc(Stats.Insertadas);
        end;
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.Log('  ! error en bulk talla "%s" art "%s": %s',
                  [sAV, sArt, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
    oAsigVistas.Free;
    oAtbMap.Free;
    oAvMap.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'articulos_colores',
    'Colores por artículo',
    'dbo.ocartcol → atributos básicos de artículo',
    ['articulos', 'colores_maestros'],
    MigrarArticulosColores);
  RegistrarMigracion(
    'articulos_tallas',
    'Tallas por artículo',
    'dbo.ocarttal → atributos básicos de artículo',
    ['articulos', 'tallas_maestras'],
    MigrarArticulosTallas);

end.
