{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFamilias                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.2.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocniv` (SQL Server: jerarquía completa de niveles de           }
{    artículo del legacy) → `fza_articulos_familias`.                          }
{                                                                              }
{    Historial:                                                                }
{      v1.0  apuntaba a `dbo.ocartniv` — descartada, solo define los nombres   }
{            de los niveles (2 filas: "SECCION"=2, "FAMILIA"=4).               }
{      v1.1  apuntaba a `dbo.oclwgrupo` — descartada, no es la tabla real.    }
{      v1.2  apunta a `dbo.ocniv` que contiene los registros reales:          }
{              - Nivel=2 (12 filas): SECCIONES, código 2 chars (01, 02…)      }
{              - Nivel=4 (181 filas): FAMILIAS, código 4 chars (0101, 0308…)  }
{              - Nivel=1 (1 fila): outlier, se ignora.                         }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Codigo      (varchar 15)  → CODIGO_FAM_FAM                              }
{      Descripcion (varchar 100) → NOMBRE_FAM_FAM y DESCRIPCION_FAM            }
{      Estado='B'                 → ESACTIVO_FAM = 'N'  (otro caso → 'S')      }
{      <orden lectura>            → ORDEN_FAM     = 10, 20, 30...              }
{      Nivel=2 (SECCION 2 chars)  → ESDEFAULT_FAM='N' (las dejamos como        }
{                                  marker padre, no las usa ningún articulo)   }
{      Primera Nivel=4 leída      → ESDEFAULT_FAM='S' (la que articulos        }
{                                                     mostraran por defecto)   }
{                                                                              }
{    Filtro: `Nivel IN (2, 4)`. Saltamos Nivel=1 (1 outlier) y los registros   }
{    sin código. El código se conserva literal — `ocartp.Familia` ya guarda    }
{    el mismo formato 4 chars, así que `CODIGO_FAM_ART` cuadra sin            }
{    transformación con `CODIGO_FAM_FAM`.                                      }
{                                                                              }
{    Idempotente: si la familia ya existe (mismo CODIGO_FAM_FAM) se salta.    }
{******************************************************************************}
unit inLibMigFamilias;

interface

uses
  UMigEngine;

procedure MigrarFamilias(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarFamilias(Eng: TMigEngine; var Stats: TMigStats);
const
  // Filtramos Nivel=2 (seccion) y Nivel=4 (familia). Ordenamos por
  // longitud descendente para que se inserten primero las familias
  // reales (4 chars) y la "primera leida" — la que marcamos como
  // ESDEFAULT_FAM='S' — sea una familia real, no una seccion.
  // El filtro de niveles y el padding se construyen dinamicamente a
  // partir de Eng.NivelFamiliasHoja (ver mas abajo). Esto permite que
  // distintos clientes legacy con convenciones diferentes (Nivel=3,
  // Nivel=5, etc.) se migren sin tocar codigo.
  cInsertDst =
    'INSERT INTO fza_articulos_familias (' +
      'CODIGO_FAM_FAM, CODIGO_PADRE_FAM, ESACTIVO_FAM, ORDEN_FAM, ' +
      'ESDEFAULT_FAM, NOMBRE_FAM_FAM, DESCRIPCION_FAM, PAD_ART_FAM, ' +
      'CONTADOR_ART_FAM, ESCONTADOR_ART_FAM, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_FAM_FAM, :CODIGO_PADRE_FAM, :ESACTIVO_FAM, :ORDEN_FAM, ' +
      ':ESDEFAULT_FAM, :NOMBRE_FAM_FAM, :DESCRIPCION_FAM, :PAD_ART_FAM, ' +
      ':CONTADOR_ART_FAM, :ESCONTADOR_ART_FAM, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';

  function DeducirActivo(const sEstado: string): string;
  var s: string;
  begin
    s := UpperCase(Trim(sEstado));
    if s = 'B' then
      Result := 'N'
    else
      Result := 'S';
  end;

var
  qSrc, qIns, qChk:   TUniQuery;
  sCod, sDescripcion: string;
  sCodPadre:          string;
  sSelectSrc:         string;
  iNivel, iNivelHoja: Integer;
  iNivelDet:          Integer;
  iLenHoja, iLenPadre:Integer;
  iPad:               Integer;
  iOrden:             Integer;
  bPrimero:           Boolean;
begin
  iNivelHoja := Eng.NivelFamiliasHoja;  // pista (default 4)
  // Auto-deteccion del nivel "hoja" real: el ocniv de cada cliente puede
  // usar niveles 2/4 (Herreras) o 1/3/5 u otros. Si el nivel configurado no
  // tiene filas, tomamos el nivel MAXIMO con codigo como hoja. Sin esto el
  // filtro no casa con ningun nivel, salen 0 familias y la barra se queda en
  // "0 / ? (contando...)" (parece colgada, pero el total es 0).
  if Eng.ContarOrigen(Format(
       'SELECT COUNT(*) FROM dbo.ocniv WITH (NOLOCK) WHERE Nivel = %d',
       [iNivelHoja])) = 0 then
  begin
    iNivelDet := Eng.ContarOrigen(
      'SELECT ISNULL(MAX(Nivel), 0) FROM dbo.ocniv WITH (NOLOCK) ' +
      'WHERE LTRIM(RTRIM(Codigo)) <> ''''');
    if iNivelDet > 0 then
    begin
      Eng.Log('  familias: nivel %d sin filas; uso nivel hoja detectado %d',
              [iNivelHoja, iNivelDet]);
      iNivelHoja := iNivelDet;
    end;
  end;
  iLenHoja   := iNivelHoja;             // codigo Nivel=hoja -> N chars
  iLenPadre  := iNivelHoja - 2;         // Nivel=hoja-2 -> N-2 chars (seccion)
  if iLenPadre < 1 then iLenPadre := 1;
  // El ancho del contador por familia (PAD_ART_FAM) ya NO es un parametro
  // del migrador: se deduce de la longitud REAL de los codigos de articulo
  // numericos del legacy menos la longitud del codigo de familia. Ej:
  // articulo '101010006' (9 chars) menos familia '10101' (5) = 4 digitos de
  // contador. Si no se puede deducir (sin codigos numericos), 4 por defecto.
  iPad := Eng.ContarOrigen(
    'SELECT TOP 1 LEN(LTRIM(RTRIM(Articulo))) FROM dbo.ocartp WITH (NOLOCK) ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(Articulo)) NOT LIKE ''%[^0-9]%'' ' +
    'GROUP BY LEN(LTRIM(RTRIM(Articulo))) ' +
    'ORDER BY COUNT(*) DESC') - iLenHoja;
  if iPad < 1 then
    iPad := 4;
  Eng.Log('  familias: ancho de contador por familia deducido = %d', [iPad]);
  // Migramos los dos niveles: el "hoja" y su seccion padre. Si el
  // legacy usa otra convencion, el setting NivelFamiliasHoja lo
  // ajusta y aqui derivamos los dos niveles afectados.
  // WITH (NOLOCK): lectura sucia. Sin esto el COUNT/SELECT sobre ocniv se
  // queda colgado ("contando...") si otra sesion tiene la tabla bloqueada
  // (p.ej. SSMS abierto en edicion). Es una migracion de solo-lectura.
  sSelectSrc :=
    Format('SELECT Codigo, Nivel, Descripcion, Estado ' +
           'FROM dbo.ocniv WITH (NOLOCK) ' +
           'WHERE Nivel IN (%d, %d) ' +
           '  AND LTRIM(RTRIM(Codigo)) <> '''' ' +
           'ORDER BY CASE WHEN Nivel = %d THEN 0 ELSE 1 END, Codigo',
           [iNivelHoja - 2, iNivelHoja, iNivelHoja]);

  qSrc := NuevoQOrigen(Eng, sSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_familias WHERE CODIGO_FAM_FAM = :c';

    Eng.SetTotal(Eng.ContarOrigen(
      Format('SELECT COUNT(*) FROM dbo.ocniv WITH (NOLOCK) ' +
             'WHERE Nivel IN (%d, %d)',
             [iNivelHoja - 2, iNivelHoja])));
    iOrden   := 10;
    bPrimero := True;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCod         := Trim(qSrc.FieldByName('Codigo').AsString);
      iNivel       := qSrc.FieldByName('Nivel').AsInteger;
      sDescripcion := Trim(qSrc.FieldByName('Descripcion').AsString);
      if sCod = '' then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      if sDescripcion = '' then
        sDescripcion := 'Familia ' + sCod;

      // Jerarquia: las familias Nivel=hoja tienen como padre la
      // seccion Nivel=hoja-2 cuyo codigo coincide con los primeros
      // chars de la familia hoja. Ej (default hoja=4): '1401' (FALDA
      // INMACULADA) tiene padre '14' (UNIFORME INMACULADA CONCEP.).
      if (iNivel = iNivelHoja) and (Length(sCod) >= iLenHoja) then
        sCodPadre := Copy(sCod, 1, iLenPadre)
      else
        sCodPadre := '';

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - familia "%s" ya existe, se omite', [sCod]);
        qChk.Close;
        bPrimero := False;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('CODIGO_FAM_FAM').AsString  := sCod;
      if sCodPadre <> '' then
        qIns.ParamByName('CODIGO_PADRE_FAM').AsString := sCodPadre
      else
        qIns.ParamByName('CODIGO_PADRE_FAM').Clear;
      qIns.ParamByName('ESACTIVO_FAM').AsString    :=
        DeducirActivo(qSrc.FieldByName('Estado').AsString);
      qIns.ParamByName('ORDEN_FAM').AsInteger      := iOrden;
      if bPrimero then
        qIns.ParamByName('ESDEFAULT_FAM').AsString := 'S'
      else
        qIns.ParamByName('ESDEFAULT_FAM').AsString := 'N';
      bPrimero := False;
      qIns.ParamByName('NOMBRE_FAM_FAM').AsString  := sDescripcion;
      qIns.ParamByName('DESCRIPCION_FAM').AsString := sDescripcion;
      qIns.ParamByName('PAD_ART_FAM').AsInteger    := iPad;
      // Solo las familias del nivel "hoja" (parametrizado) crean
      // articulos directos. Las secciones padre son agrupadores: el
      // contador queda desactivado por defecto.
      qIns.ParamByName('CONTADOR_ART_FAM').AsInteger := 0;
      if iNivel = iNivelHoja then
        qIns.ParamByName('ESCONTADOR_ART_FAM').AsString := 'S'
      else
        qIns.ParamByName('ESCONTADOR_ART_FAM').AsString := 'N';
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
        Inc(iOrden, 10);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando familia "%s": %s',
                  [sCod, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qChk.Free;
    qIns.Free;
    qSrc.Free;
  end;
end;

end.
