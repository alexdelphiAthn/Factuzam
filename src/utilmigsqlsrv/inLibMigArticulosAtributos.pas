{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosAtributos                                    }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra las ASIGNACIONES de colores y tallas por artículo. Es decir, para  }
{    cada artículo del origen genera las filas que dicen "este artículo tiene  }
{    estos colores y/o estas tallas" en `fza_articulos_atributos_basicos`.    }
{                                                                              }
{    Mapeo:                                                                    }
{      dbo.ocartcol (Articulo, Color)  → fza_articulos_atributos_basicos       }
{                                       (CODIGO_ART_AAB, ID_AV_AAB)            }
{                                       enlazando con fza_atributos_valores    }
{                                       (ID_VA_AV='CO', AV=UPPER(color))      }
{                                                                              }
{      dbo.ocarttal (Articulo, Talla)  → fza_articulos_atributos_basicos       }
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
{    Idempotente: la PK (CODIGO_ART_AAB, ID_AV_AAB) ya descarta duplicados   }
{    con INSERT IGNORE. Aqui hacemos pre-check + INSERT para poder contar.   }
{******************************************************************************}
unit inLibMigArticulosAtributos;

interface

uses
  UMigEngine;

// Asigna los colores que cada artículo tiene en el legacy.
procedure MigrarArticulosColores(Eng: TMigEngine; var Stats: TMigStats);

// Asigna las tallas que cada artículo tiene en el legacy.
procedure MigrarArticulosTallas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  Data.DB, Uni;

const
  BATCH_SIZE = 5000;

// =========================================================================
//  Helpers locales: caches
// =========================================================================

procedure CargarMapaAV(Eng: TMigEngine; const sIdVa: string;
                       Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
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

procedure CargarMapaATB(Eng: TMigEngine; const sIdVa: string;
                        Mapa: TDictionary<string, Integer>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
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

procedure CargarAsignacionesVistas(Eng: TMigEngine;
                                    Conjunto: TDictionary<string,
                                                           Boolean>);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
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
function InsertarAsignacion(Eng: TMigEngine;
                             const sCodArt: string; iIdAv, iIdAtb: Integer;
                             const sUsuario: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_atributos_basicos ' +
      'WHERE CODIGO_ART_AAB = :a AND ID_AV_AAB = :v';
    qChk.ParamByName('a').AsString  := sCodArt;
    qChk.ParamByName('v').AsInteger := iIdAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
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

procedure MigrarArticulosColores(Eng: TMigEngine; var Stats: TMigStats);
const
  // Mismo criterio que SKUs/tarifas: codigo interno de ocartcol.Color.
  cSelectSrc =
    'SELECT ac.Articulo, ' +
    '       CASE ' +
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor ' +
    'FROM dbo.ocartcol ac ' +
    'WHERE LTRIM(RTRIM(ac.Articulo)) <> '''' ' +
    'ORDER BY ac.Articulo, ac.Color';
  cCols =
    'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                            TUniQuery;
  bulk:                            TBulkInsert;
  oAvMap, oAtbMap:                 TDictionary<string, Integer>;
  oAsigVistas:                     TDictionary<string, Boolean>;
  sArt, sDescColor, sAV, sCodAtb:  string;
  sFila, sAhora, sIdAtb, sUser:    string;
  sKey:                            string;
  iIdAv, iIdAtb:                   Integer;
begin
  Eng.Log('  cargando caches en memoria...');
  oAvMap      := TDictionary<string, Integer>.Create;
  oAtbMap     := TDictionary<string, Integer>.Create;
  oAsigVistas := TDictionary<string, Boolean>.Create;
  qSrc        := nil;
  bulk        := nil;
  try
    CargarMapaAV (Eng, 'CO', oAvMap);
    CargarMapaATB(Eng, 'CO', oAtbMap);
    CargarAsignacionesVistas(Eng, oAsigVistas);
    Eng.Log('  cache: %d colores AV, %d basicos, %d asignaciones',
            [oAvMap.Count, oAtbMap.Count, oAsigVistas.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    qSrc   := NuevoQOrigen(Eng, cSelectSrc);
    // UniDirectional: NO cachea las ~81k filas en memoria (solo lectura
    // hacia delante). Reduce la presion de memoria que, en paralelo con los
    // otros mappers pesados, puede provocar AccessViolation en el .exe 32b.
    qSrc.UniDirectional := True;
    bulk   := TBulkInsert.Create(Eng.ConDst,
                                  'fza_articulos_atributos_basicos',
                                  cCols, BATCH_SIZE);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartcol ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada, saliendo del mapper...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      if (sArt = '') or (sDescColor = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sAV := UpperCase(sDescColor);
      if not oAvMap.TryGetValue(sAV, iIdAv) then
      begin
        Inc(Stats.Errores);
        Eng.Log('  ! color "%s" no esta en fza_atributos_valores ' +
                '(articulo %s)', [sAV, sArt]);
        qSrc.Next;
        Continue;
      end;

      sCodAtb := NormalizarCodigoAtb(sDescColor);
      if oAtbMap.TryGetValue(sCodAtb, iIdAtb) then
        sIdAtb := IntToStr(iIdAtb)
      else
        sIdAtb := 'NULL';

      // Idempotencia: misma (CODIGO_ART, ID_AV) ya esta?
      sKey := sArt + '|' + IntToStr(iIdAv);
      if oAsigVistas.ContainsKey(sKey) then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sFila := Format('%s, %d, %s, %s, %s, %s, %s',
        [ValorOrNull(sArt), iIdAv, sIdAtb,
         sAhora, sAhora, sUser, sUser]);
      try
        bulk.Add(sFila);
        oAsigVistas.AddOrSetValue(sKey, True);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error bulk color "%s" art "%s": %s',
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

// =========================================================================
//  MigrarArticulosTallas  (ocarttal → fza_articulos_atributos_basicos)
// =========================================================================

procedure MigrarArticulosTallas(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, Talla ' +
    'FROM dbo.ocarttal ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(Talla))    <> '''' ' +
    'ORDER BY Articulo, Orden, Talla';
  cCols =
    'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                         TUniQuery;
  bulk:                         TBulkInsert;
  oAvMap, oAtbMap:              TDictionary<string, Integer>;
  oAsigVistas:                  TDictionary<string, Boolean>;
  sArt, sTalla, sAV, sCodAtb:   string;
  sFila, sAhora, sIdAtb, sUser: string;
  sKey:                         string;
  iIdAv, iIdAtb:                Integer;
begin
  Eng.Log('  cargando caches en memoria...');
  oAvMap      := TDictionary<string, Integer>.Create;
  oAtbMap     := TDictionary<string, Integer>.Create;
  oAsigVistas := TDictionary<string, Boolean>.Create;
  qSrc        := nil;
  bulk        := nil;
  try
    CargarMapaAV (Eng, 'TAL', oAvMap);
    CargarMapaATB(Eng, 'TAL', oAtbMap);
    CargarAsignacionesVistas(Eng, oAsigVistas);
    Eng.Log('  cache: %d tallas AV, %d basicos, %d asignaciones',
            [oAvMap.Count, oAtbMap.Count, oAsigVistas.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    qSrc   := NuevoQOrigen(Eng, cSelectSrc);
    // UniDirectional: NO cachea las ~266k filas en memoria (solo lectura
    // hacia delante). Reduce la presion de memoria que, en paralelo con los
    // otros mappers pesados, puede provocar AccessViolation en el .exe 32b.
    qSrc.UniDirectional := True;
    bulk   := TBulkInsert.Create(Eng.ConDst,
                                  'fza_articulos_atributos_basicos',
                                  cCols, BATCH_SIZE);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocarttal ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND LTRIM(RTRIM(Talla))    <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada, saliendo del mapper...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt   := Trim(qSrc.FieldByName('Articulo').AsString);
      sTalla := Trim(qSrc.FieldByName('Talla').AsString);
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
        Eng.Log('  ! talla "%s" no esta en fza_atributos_valores ' +
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
      if oAsigVistas.ContainsKey(sKey) then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sFila := Format('%s, %d, %s, %s, %s, %s, %s',
        [ValorOrNull(sArt), iIdAv, sIdAtb,
         sAhora, sAhora, sUser, sUser]);
      try
        bulk.Add(sFila);
        oAsigVistas.AddOrSetValue(sKey, True);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error en bulk talla "%s" art "%s": %s',
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

end.
