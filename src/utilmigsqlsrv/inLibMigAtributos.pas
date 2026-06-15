{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigAtributos                                             }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.1.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los CATÁLOGOS MAESTROS de colores y tallas del ERP "Herreras"      }
{    hacia el modelo de atributos de Factuzam. No toca las asignaciones por    }
{    artículo (de eso se encarga `inLibMigArticulosAtributos`).                }
{                                                                              }
{    Mapeo:                                                                    }
{      `dbo.occolor`         (catálogo de colores) →                           }
{          - fza_atributos_valores con ID_VA_AV = 'CO'                         }
{          - fza_atributos_basicos con ID_VA_ATB = 'CO' (HEX en #RRGGBB)       }
{                                                                              }
{      SELECT DISTINCT Talla FROM dbo.ocarttal →                               }
{          - fza_atributos_valores con ID_VA_AV = 'TAL'                        }
{          - fza_atributos_basicos con ID_VA_ATB = 'TAL'                       }
{                                                                              }
{    Prerequisito: tiene que existir la variación 'TC' en `fza_variaciones`    }
{    y los dos atributos ('CO','TAL') en `fza_variaciones_atributos`. Si no    }
{    están, las creamos antes de empezar (idempotente).                        }
{                                                                              }
{    Idempotente: la combinación (ID_VA_AV, AV) es única, si existe se salta.  }
{    El programador puede re-ejecutar con seguridad.                           }
{******************************************************************************}
unit inLibMigAtributos;

interface

uses
  UMigEngine;

// Migrador maestro: colores (dbo.occolor → fza_atributos_valores + basicos)
procedure MigrarColoresMaestros(Eng: TMigEngine; var Stats: TMigStats);

// Migrador maestro: tallas (DISTINCT de dbo.ocarttal → fza_atributos_valores)
procedure MigrarTallasMaestras(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB, Uni;

// =========================================================================
//  Helpers comunes
// =========================================================================

// Convierte un entero RGB (R + G*256 + B*65536, formato Windows) a '#RRGGBB'.
// Si el valor es 0 o NULL devuelve cadena vacía.
function ColorIntAHex(iValor: Integer): string;
var
  iR, iG, iB: Integer;
begin
  if iValor <= 0 then Exit('');
  iR := iValor and $FF;
  iG := (iValor shr 8)  and $FF;
  iB := (iValor shr 16) and $FF;
  Result := Format('#%.2X%.2X%.2X', [iR, iG, iB]);
end;

// Asegura que existe la variación 'TC' y sus dos atributos.
procedure AsegurarVariacionTC(Eng: TMigEngine);
var qIns: TUniQuery;
begin
  // Race-safe: INSERT IGNORE en lugar de SELECT+INSERT, porque
  // wave 0 corre colores_maestros y tallas_maestras en paralelo y
  // ambos llaman aqui. El patron check-then-insert da
  // "Duplicate entry 'TC' for key PRIMARY" cuando los dos workers
  // pasan el SELECT simultaneamente.
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;

    // fza_variaciones: 'TC'
    qIns.SQL.Text :=
      'INSERT IGNORE INTO fza_variaciones (' +
        'CODIGO_VAR, NOMBRE_VAR, ESACTIVO_VAR, ORDEN_VAR, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (''TC'', ''TALLAS Y COLORES'', ''S'', 1, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    if qIns.RowsAffected > 0 then Eng.Log('  + creada variacion TC');

    // fza_variaciones_atributos: ('TC','CO') y ('TC','TAL')
    qIns.SQL.Text :=
      'INSERT IGNORE INTO fza_variaciones_atributos (' +
        'ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA, NOMBRE_VISIBLE_VA) ' +
      'VALUES (''TC'', ''CO'', ''Color'', 1, ''Paleta'')';
    qIns.ExecSQL;
    if qIns.RowsAffected > 0 then Eng.Log('  + creado eje variacion TC/CO');

    qIns.SQL.Text :=
      'INSERT IGNORE INTO fza_variaciones_atributos (' +
        'ID_VAR_VA, ID_ATB_VA, NOMBRE_VA, ORDEN_VA, NOMBRE_VISIBLE_VA) ' +
      'VALUES (''TC'', ''TAL'', ''Talla'', 2, ''Sistema de tallas'')';
    qIns.ExecSQL;
    if qIns.RowsAffected > 0 then Eng.Log('  + creado eje variacion TC/TAL');
  finally
    qIns.Free;
  end;
end;

// Inserta una fila en fza_atributos_valores si no existe la pareja
// (ID_VA_AV, AV). Devuelve True si insertó, False si ya existía.
function InsertarValorAtributo(Eng: TMigEngine; const sIdVa, sAv,
                                sDescripcion: string; iOrden: Integer): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :v AND AV = :av';
    qChk.ParamByName('v').AsString  := sIdVa;
    qChk.ParamByName('av').AsString := sAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_atributos_valores (' +
        'ID_VA_AV, AV, ORDEN_AV, DESCRIPCION_AV, ESACTIVO_AV, ' +
        'FACTOR_CONVERSION_AV, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:v, :av, :o, :d, ''S'', 1, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('v').AsString  := sIdVa;
    qIns.ParamByName('av').AsString := sAv;
    qIns.ParamByName('o').AsInteger := iOrden;
    qIns.ParamByName('d').AsString  := sDescripcion;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Inserta una fila en fza_atributos_basicos si no existe la pareja
// (ID_VA_ATB, CODIGO_ATB).
procedure InsertarAtributoBasico(Eng: TMigEngine;
                                  const sIdVa, sCodigo, sNombre,
                                  sDescripcion, sHex: string; iOrden: Integer;
                                  const sActivo: string = 'S');
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_atributos_basicos ' +
      'WHERE ID_VA_ATB = :v AND CODIGO_ATB = :c';
    qChk.ParamByName('v').AsString := sIdVa;
    qChk.ParamByName('c').AsString := sCodigo;
    qChk.Open;
    if not qChk.IsEmpty then Exit;
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_atributos_basicos (' +
        'ID_VA_ATB, CODIGO_ATB, NOMBRE_ATB, DESCRIPCION_ATB, HEX_ATB, ' +
        'ORDEN_ATB, ESACTIVO_ATB, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:v, :c, :n, :d, :h, :o, :ea, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('v').AsString := sIdVa;
    qIns.ParamByName('c').AsString := sCodigo;
    qIns.ParamByName('n').AsString := sNombre;
    qIns.ParamByName('d').AsString := sDescripcion;
    if sHex <> '' then
      qIns.ParamByName('h').AsString := sHex
    else
      qIns.ParamByName('h').Clear;
    qIns.ParamByName('o').AsInteger := iOrden;
    qIns.ParamByName('ea').AsString := sActivo;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// NormalizarCodigoAtb se ha movido a UMigEngine para reutilizarla.
// Aqui se elimina la copia local — la firma esta exportada por el motor.
{$IFDEF NUNCA_DEFINIDO}
function NormalizarCodigoAtbLOCAL(const s: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    c := s[i];
    case c of
      'A'..'Z', '0'..'9', '_': Result := Result + c;
      'a'..'z':                Result := Result + UpCase(c);
      ' ', '-', '/', '.':      Result := Result + '_';
    else
      // resto fuera (acentos, comas, etc.)
    end;
  end;
  if Result = '' then Result := 'X';
end;
{$ENDIF}

// =========================================================================
//  Migrador COLORES MAESTROS
// =========================================================================

procedure MigrarColoresMaestros(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT ColorBasico, Descripcion, ColorPaleta, Estado ' +
    'FROM dbo.occolor ' +
    'ORDER BY ColorBasico';
var
  qSrc, qExist:               TUniQuery;
  bulkCol:                    TBulkInsert;
  oColExist:                  TDictionary<string, Boolean>;
  sCodOrigen, sCodAtb, sDesc: string;
  sHex, sAhora, sUser:        string;
  sActivo:                    string;
  iColorRGB, iOrden:          Integer;
  bInsertoValor:              Boolean;
begin
  AsegurarVariacionTC(Eng);

  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.occolor'));
    qSrc.Open;
    iOrden := 10;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCodOrigen := Trim(qSrc.FieldByName('ColorBasico').AsString);
      sDesc      := Trim(qSrc.FieldByName('Descripcion').AsString);
      if qSrc.FieldByName('ColorPaleta').IsNull then
        iColorRGB := 0
      else
        iColorRGB := qSrc.FieldByName('ColorPaleta').AsInteger;
      sHex       := ColorIntAHex(iColorRGB);
      // En origen Estado='B' es baja; el resto (incl. 'A') es activo.
      if UpperCase(Trim(qSrc.FieldByName('Estado').AsString)) = 'B' then
        sActivo := 'N'
      else
        sActivo := 'S';

      if (sCodOrigen = '') and (sDesc = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      // Si la Descripcion es vacia o el placeholder 'INDEFINIDO',
      // usar el codigo legacy (ColorBasico, p.ej. '0', '00'). En el
      // legacy '0' y '00' son colores reales — la convencion es
      // consistente con SKUs/tarifas/articulos_colores.
      if (sDesc = '') or (UpperCase(sDesc) = 'INDEFINIDO') then
        sDesc := sCodOrigen;

      // El AV (valor visible) es la descripcion en mayusculas; lo
      // usamos como clave dentro de ID_VA='CO'. El CODIGO_ATB usa el
      // mismo pero normalizado.
      sCodAtb := NormalizarCodigoAtb(sDesc);

      bInsertoValor := InsertarValorAtributo(Eng, 'CO',
                                              UpperCase(sDesc),
                                              'Color ' + sDesc,
                                              iOrden);
      InsertarAtributoBasico(Eng, 'CO', sCodAtb, sDesc,
                              'Color ' + sDesc + ' (legacy ' +
                              sCodOrigen + ')', sHex, iOrden, sActivo);
      if bInsertoValor then
      begin
        Inc(Stats.Insertadas);
        Inc(iOrden, 10);
      end
      else
        Inc(Stats.Saltadas);
      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;

  // Segunda pasada: el color que usan SKUs/movimientos/tarifas/etc. es el
  // TEXTO del proveedor (ac.Color, ver el CASE de slot), asi que TODO color
  // de ocartcol debe existir como valor de atributo — no solo los que el JOIN
  // a occolor deja fuera. Tomamos ac.Color en crudo (DISTINCT, mayusculas),
  // que es justo lo que produce el slot cuando ac.Color no es vacio. Sin
  // esto, articulos_colores/skus fallan con
  //   "color X no esta en fza_atributos_valores".
  // Solo ocartcol (no ocartbap): los colores de los barcodes son un
  // SUBCONJUNTO de los de ocartcol, asi que basta y es mucho mas ligero.
  // RENDIMIENTO: precargamos en memoria los colores ya existentes (1 consulta)
  // e insertamos los nuevos en LOTE. Antes se hacia un SELECT de comprobacion
  // por cada color (miles): tardaba minutos y, con la transaccion abierta,
  // bloqueaba el resto de la migracion (Lock wait timeout en tallas).
  Eng.Log('  segunda pasada: colores del proveedor (ac.Color) de ocartcol...');
  oColExist := TDictionary<string, Boolean>.Create;
  qExist    := TUniQuery.Create(nil);
  bulkCol   := TBulkInsert.Create(Eng.ConDst, 'fza_atributos_valores',
    'ID_VA_AV, AV, ORDEN_AV, DESCRIPCION_AV, ESACTIVO_AV, ' +
    'FACTOR_CONVERSION_AV, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF', 500);
  qSrc := NuevoQOrigen(Eng,
    'SELECT DISTINCT UPPER(LTRIM(RTRIM(ac.Color))) AS DescColor ' +
    'FROM dbo.ocartcol ac ' +
    'WHERE LTRIM(RTRIM(ISNULL(ac.Color, ''''))) <> '''' ' +
    'ORDER BY DescColor');
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    // Set O(1) con los colores ya existentes (incluye los de la 1a pasada).
    qExist.Connection := Eng.ConDst;
    qExist.SQL.Text   :=
      'SELECT AV FROM fza_atributos_valores WHERE ID_VA_AV = ''CO''';
    qExist.Open;
    while not qExist.Eof do
    begin
      oColExist.AddOrSetValue(
        UpperCase(Trim(qExist.FieldByName('AV').AsString)), True);
      qExist.Next;
    end;
    qExist.Close;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      sDesc := Trim(qSrc.FieldByName('DescColor').AsString);
      if (sDesc <> '') and (not oColExist.ContainsKey(sDesc)) then
      begin
        oColExist.AddOrSetValue(sDesc, True);
        bulkCol.Add(Format(
          '''CO'', %s, %d, %s, ''S'', 1, %s, %s, %s, %s',
          [ValorOrNull(sDesc), iOrden,
           ValorOrNull('Color ' + sDesc + ' (proveedor)'),
           sAhora, sAhora, sUser, sUser]));
        Inc(iOrden, 10);
        Inc(Stats.Insertadas);
      end;
      qSrc.Next;
    end;
    bulkCol.FlushPendiente;
  finally
    bulkCol.Free;
    qSrc.Free;
    qExist.Free;
    oColExist.Free;
  end;
end;

// =========================================================================
//  Migrador TALLAS MAESTRAS (DISTINCT de ocarttal.Talla)
// =========================================================================

procedure MigrarTallasMaestras(Eng: TMigEngine; var Stats: TMigStats);
const
  // UNION de DOS fuentes:
  //   - ocarttal: tallas que algun articulo tiene asignadas
  //   - ocgrptalnor: tallas que aparecen en la DEFINICION de algun
  //     tallaje (puede haber tallas en el catalogo de tallajes que
  //     ningun articulo use directamente, como las del tallaje CINTOS:
  //     65/70/75/80/85... si ningun cinturon esta migrado todavia)
  // Sin el UNION, las tallas "exoticas" no estarian en
  // fza_atributos_valores y la migracion de tallajes y de
  // articulos_tallas fallaria con "no esta en fza_atributos_valores".
  // ORDEN: las tallas se numeran (ORDEN_AV = 10,20,30...) en el orden
  // que tienen en el tallaje del legacy (ocgrptalnor.Columna), NO
  // alfabeticamente. El ORDER BY Talla anterior volcaba ORDEN_AV como
  // L,M,S,XL... y dejaba las tallas desordenadas en SKUs, dropdowns y
  // descripciones (GROUP_CONCAT ... ORDER BY ORDEN_AV). Tomamos
  // MIN(Columna): si una talla esta en varios tallajes gana su primera
  // posicion; las que solo estan en ocarttal (ningun tallaje las
  // define) reciben 9000 y caen al final, desempatadas por nombre.
  cSelectSrc =
    'SELECT X.Talla, MIN(X.Orden) AS Orden FROM (' +
    '  SELECT LTRIM(RTRIM(Talla)) AS Talla, ISNULL(Columna, 9000) AS Orden ' +
    '    FROM dbo.ocgrptalnor ' +
    '   WHERE LTRIM(RTRIM(Talla)) <> '''' ' +
    '  UNION ALL ' +
    '  SELECT LTRIM(RTRIM(Talla)) AS Talla, 9000 AS Orden ' +
    '    FROM dbo.ocarttal ' +
    '   WHERE LTRIM(RTRIM(Talla)) <> '''' ' +
    ') X ' +
    'GROUP BY X.Talla ' +
    'ORDER BY MIN(X.Orden), X.Talla';
  cCount =
    'SELECT COUNT(*) FROM (' +
    '  SELECT LTRIM(RTRIM(Talla)) AS Talla FROM dbo.ocarttal ' +
    '   WHERE LTRIM(RTRIM(Talla)) <> '''' ' +
    '  UNION ' +
    '  SELECT LTRIM(RTRIM(Talla)) AS Talla FROM dbo.ocgrptalnor ' +
    '   WHERE LTRIM(RTRIM(Talla)) <> '''' ' +
    ') Y';
var
  qSrc:           TUniQuery;
  sTalla, sCodAtb: string;
  iOrden:         Integer;
  bInsertoValor:  Boolean;
begin
  AsegurarVariacionTC(Eng);

  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.SetTotal(Eng.ContarOrigen(cCount));
    qSrc.Open;
    iOrden := 10;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sTalla := Trim(qSrc.FieldByName('Talla').AsString);
      if sTalla = '' then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      sCodAtb := NormalizarCodigoAtb(sTalla);

      bInsertoValor := InsertarValorAtributo(Eng, 'TAL',
                                              UpperCase(sTalla),
                                              'Talla ' + sTalla,
                                              iOrden);
      InsertarAtributoBasico(Eng, 'TAL', sCodAtb, sTalla,
                              'Talla ' + sTalla, '', iOrden);
      if bInsertoValor then
      begin
        Inc(Stats.Insertadas);
        Inc(iOrden, 10);
      end
      else
        Inc(Stats.Saltadas);
      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

end.
