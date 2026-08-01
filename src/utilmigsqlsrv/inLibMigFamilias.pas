{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFamilias                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.4.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocniv` (SQL Server: jerarquía completa de niveles de           }
{    artículo del legacy) → `fza_articulos_familias`.                          }
{                                                                              }
{    Historial:                                                                }
{      v1.0  apuntaba a `dbo.ocartniv` — descartada (solo nombres de nivel).   }
{      v1.1  apuntaba a `dbo.oclwgrupo` — descartada (no es la tabla real).    }
{      v1.2  `dbo.ocniv` filtrando Nivel IN (hoja-2, hoja) y calculando el     }
{            padre como prefijo de longitud FIJA (Nivel-2 chars). Solo valía   }
{            cuando longitud_codigo == Nivel (Herreras: 2/4). Con códigos      }
{            como '101'→'1012203' (3 y 7 chars) el padre salía mal y los       }
{            niveles intermedios no se cargaban.                               }
{      v1.3  Carga TODA la jerarquía (todos los niveles con código) y deduce   }
{            el padre por PREFIJO real: el padre de un código es el código     }
{            EXISTENTE más largo que es prefijo estricto suyo. Ej: '101' es    }
{            padre de '1012203'. Cliente-agnóstico (2/4, 3/7, 1/3/5…).         }
{      v1.4  Tambien rellena CODIGO_SUBFAMILIA_FAM, la columna legacy          }
{            que LEE la UI (grid y campo "Familia Padre" de inMtoFamilias).    }
{            Sin ella la familia hijo mostraba el padre vacio aunque           }
{            CODIGO_PADRE_FAM estuviera bien (la UI no lee esa columna).       }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Codigo      (varchar 15)  → CODIGO_FAM_FAM                              }
{      <prefijo más largo>        → CODIGO_PADRE_FAM (NULL si es raíz)          }
{      Descripcion (varchar 100) → NOMBRE_FAM_FAM y DESCRIPCION_FAM            }
{      Estado='B'                 → ESACTIVO_FAM = 'N'  (otro caso → 'S')      }
{      <orden lectura>            → ORDEN_FAM     = 10, 20, 30...              }
{      hoja (sin hijos)           → ESCONTADOR_ART_FAM='S' (crea articulos);   }
{                                  las que tienen hijos son agrupadores ('N')  }
{      primera hoja               → ESDEFAULT_FAM='S'                          }
{      PAD_ART_FAM                → ancho del contador = len(articulo) -       }
{                                  len(familia) (por familia)                  }
{                                                                              }
{    Re-ejecutable: borra las familias migradas por este usuario y las         }
{    recrea (corrige una BBDD ya migrada con la jerarquía mal). El seed/demo   }
{    (otro USUARIO_ALTA) se conserva por el chequeo de código.                 }
{******************************************************************************}
unit inLibMigFamilias;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarFamilias(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB, Uni;

type
  TFamiliaNiv = record
    Cod, Desc, Estado, Padre: string;
  end;

// Padre = el codigo EXISTENTE mas largo que es prefijo estricto de sCod. Asi
// '1012203' tiene de padre '101' (y, si existiera '10122', ese seria antes
// que '101'). No depende de la longitud fija del nivel: cliente-agnostico.
function PadrePorPrefijo(const sCod: string;
  oExiste: TDictionary<string, Boolean>): string;
var
  i:        Integer;
  bHallado: Boolean;
begin
  Result   := '';
  bHallado := False;
  i        := Length(sCod) - 1;
  while (i >= 1) and not bHallado do
  begin
    if oExiste.ContainsKey(Copy(sCod, 1, i)) then
    begin
      Result   := Copy(sCod, 1, i);
      bHallado := True;
    end;
    Dec(i);
  end;
end;

function DeducirActivoFam(const sEstado: string): string;
begin
  if UpperCase(Trim(sEstado)) = 'B' then
    Result := 'N'
  else
    Result := 'S';
end;

procedure MigrarFamilias(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cInsertDst =
    'INSERT INTO fza_articulos_familias (' +
      'CODIGO_FAM_FAM, CODIGO_PADRE_FAM, CODIGO_SUBFAMILIA_FAM, ' +
      'ESACTIVO_FAM, ORDEN_FAM, ' +
      'ESDEFAULT_FAM, NOMBRE_FAM_FAM, DESCRIPCION_FAM, PAD_ART_FAM, ' +
      'CONTADOR_ART_FAM, ESCONTADOR_ART_FAM, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_FAM_FAM, :CODIGO_PADRE_FAM, :CODIGO_SUBFAMILIA_FAM, ' +
      ':ESACTIVO_FAM, :ORDEN_FAM, ' +
      ':ESDEFAULT_FAM, :NOMBRE_FAM_FAM, :DESCRIPCION_FAM, :PAD_ART_FAM, ' +
      ':CONTADOR_ART_FAM, :ESCONTADOR_ART_FAM, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk:     TUniQuery;
  oFams:                TList<TFamiliaNiv>;
  oExiste, oTieneHijos: TDictionary<string, Boolean>;
  fam:                  TFamiliaNiv;
  i:                    Integer;
  sCod, sPadre:         string;
  iArtLen, iOrden:      Integer;
  bEsHoja, bPrimero:    Boolean;
begin
  // Longitud mas comun del codigo de articulo numerico: con ella deducimos el
  // ancho del contador por familia (PAD_ART_FAM = len(articulo) - len(familia)).
  iArtLen := Eng.Datos.ContarOrigen(
    'SELECT TOP 1 LEN(LTRIM(RTRIM(Articulo))) FROM dbo.ocartp WITH (NOLOCK) ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(Articulo)) NOT LIKE ''%[^0-9]%'' ' +
    'GROUP BY LEN(LTRIM(RTRIM(Articulo))) ' +
    'ORDER BY COUNT(*) DESC');
  // Cargamos TODA la jerarquia de ocniv (todos los niveles con codigo). El
  // padre se decide por PREFIJO, no por longitud fija del nivel, asi que ya
  // no filtramos por Nivel ni dependemos de un nivel de hoja configurable:
  // cada cliente (codigos 2/4, 3/7, etc.) migra su jerarquia completa.
  // WITH (NOLOCK): lectura sucia, evita que el SELECT se quede colgado si otra
  // sesion tiene ocniv bloqueada (p.ej. SSMS en edicion). Es solo-lectura.
  qSrc := NuevoQOrigen(Eng,
    'SELECT Codigo, Descripcion, Estado FROM dbo.ocniv WITH (NOLOCK) ' +
    'WHERE LTRIM(RTRIM(Codigo)) <> '''' ' +
    'ORDER BY LEN(LTRIM(RTRIM(Codigo))), Codigo');
  oFams       := TList<TFamiliaNiv>.Create;
  oExiste     := TDictionary<string, Boolean>.Create;
  oTieneHijos := TDictionary<string, Boolean>.Create;
  qIns        := TUniQuery.Create(nil);
  qChk        := TUniQuery.Create(nil);
  try
    // Re-ejecutable: borramos las familias migradas por ESTE usuario y las
    // recreamos, asi una BBDD ya migrada con la jerarquia mal se corrige al
    // re-pasar. Los codigos no cambian, asi que los articulos (CODIGO_FAM_ART)
    // siguen apuntando bien. El seed/demo (otro USUARIO_ALTA) se conserva via
    // el chequeo de codigo de mas abajo.
    EjecutarSQL(Eng, 'DELETE FROM fza_articulos_familias WHERE ' +
      'USUARIO_ALTA = ' + ValorOrNull(Eng.Usuario));
    // 1) Cargar todas las familias en memoria + set de codigos existentes.
    qSrc.Open;
    while not qSrc.Eof do
    begin
      sCod := Trim(qSrc.FieldByName('Codigo').AsString);
      if sCod <> '' then
      begin
        fam.Cod    := sCod;
        fam.Desc   := Trim(qSrc.FieldByName('Descripcion').AsString);
        if fam.Desc = '' then
          fam.Desc := 'Familia ' + sCod;
        fam.Estado := qSrc.FieldByName('Estado').AsString;
        fam.Padre  := '';
        oFams.Add(fam);
        oExiste.AddOrSetValue(sCod, True);
      end;
      qSrc.Next;
    end;
    Eng.Progreso.EstablecerTotal(oFams.Count);
    // 2) Padre por prefijo y marcar quien tiene hijos (para saber las hojas).
    for i := 0 to oFams.Count - 1 do
    begin
      sPadre := PadrePorPrefijo(oFams[i].Cod, oExiste);
      if sPadre <> '' then
      begin
        fam       := oFams[i];
        fam.Padre := sPadre;
        oFams[i]  := fam;
        oTieneHijos.AddOrSetValue(sPadre, True);
      end;
    end;
    // 3) Insertar.
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_familias WHERE CODIGO_FAM_FAM = :c';
    iOrden   := 10;
    bPrimero := True;
    for i := 0 to oFams.Count - 1 do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      fam := oFams[i];
      // Hoja = no es prefijo (padre) de ninguna otra: crea articulos.
      bEsHoja := not oTieneHijos.ContainsKey(fam.Cod);
      qChk.ParamByName('c').AsString := fam.Cod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Registro.Log('  - familia "%s" ya existe, se omite', [fam.Cod]);
      end
      else
      begin
        qIns.ParamByName('CODIGO_FAM_FAM').AsString := fam.Cod;
        if fam.Padre <> '' then
          qIns.ParamByName('CODIGO_PADRE_FAM').AsString := fam.Padre
        else
          qIns.ParamByName('CODIGO_PADRE_FAM').Clear;
        // CODIGO_SUBFAMILIA_FAM: columna legacy que LEE la UI (grid y campo
        // "Familia Padre" de inMtoFamilias). Apunta al mismo padre que
        // CODIGO_PADRE_FAM; sin rellenarla la familia hijo mostraba el padre
        // vacio tras migrar aunque CODIGO_PADRE_FAM estuviera bien.
        if fam.Padre <> '' then
          qIns.ParamByName('CODIGO_SUBFAMILIA_FAM').AsString := fam.Padre
        else
          qIns.ParamByName('CODIGO_SUBFAMILIA_FAM').Clear;
        qIns.ParamByName('ESACTIVO_FAM').AsString :=
          DeducirActivoFam(fam.Estado);
        qIns.ParamByName('ORDEN_FAM').AsInteger := iOrden;
        if bPrimero and bEsHoja then
        begin
          qIns.ParamByName('ESDEFAULT_FAM').AsString := 'S';
          bPrimero := False;
        end
        else
          qIns.ParamByName('ESDEFAULT_FAM').AsString := 'N';
        qIns.ParamByName('NOMBRE_FAM_FAM').AsString  := fam.Desc;
        qIns.ParamByName('DESCRIPCION_FAM').AsString := fam.Desc;
        // Contador por familia: ancho = len(articulo) - len(familia). Si no se
        // puede deducir (sin codigos numericos o familia mas larga), 4.
        if iArtLen > Length(fam.Cod) then
          qIns.ParamByName('PAD_ART_FAM').AsInteger := iArtLen - Length(fam.Cod)
        else
          qIns.ParamByName('PAD_ART_FAM').AsInteger := 4;
        // Solo las hojas crean articulos directos; los agrupadores (con hijos)
        // llevan el contador desactivado.
        qIns.ParamByName('CONTADOR_ART_FAM').AsInteger := 0;
        if bEsHoja then
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
            Eng.Registro.Log('  ! error insertando familia "%s": %s',
                    [fam.Cod, E.Message]);
            raise;
          end;
        end;
      end;
      qChk.Close;
    end;
  finally
    qChk.Free;
    qIns.Free;
    qSrc.Free;
    oTieneHijos.Free;
    oExiste.Free;
    oFams.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'familias',
    'Familias de artículo',
    'dbo.ocniv (Nivel 2+4) → fza_articulos_familias',
    [],
    MigrarFamilias);

end.
