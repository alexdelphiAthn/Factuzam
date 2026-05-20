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
  cSelectSrc =
    'SELECT Codigo, Nivel, Descripcion, Estado ' +
    'FROM dbo.ocniv ' +
    'WHERE Nivel IN (2, 4) ' +
    '  AND LTRIM(RTRIM(Codigo)) <> '''' ' +
    'ORDER BY CASE WHEN Nivel = 4 THEN 0 ELSE 1 END, Codigo';
  cInsertDst =
    'INSERT INTO fza_articulos_familias (' +
      'CODIGO_FAM_FAM, ESACTIVO_FAM, ORDEN_FAM, ESDEFAULT_FAM, ' +
      'NOMBRE_FAM_FAM, DESCRIPCION_FAM, PAD_ART_FAM, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_FAM_FAM, :ESACTIVO_FAM, :ORDEN_FAM, :ESDEFAULT_FAM, ' +
      ':NOMBRE_FAM_FAM, :DESCRIPCION_FAM, :PAD_ART_FAM, ' +
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
  iOrden:             Integer;
  bPrimero:           Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_familias WHERE CODIGO_FAM_FAM = :c';

    iOrden   := 10;
    bPrimero := True;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      sCod         := Trim(qSrc.FieldByName('Codigo').AsString);
      sDescripcion := Trim(qSrc.FieldByName('Descripcion').AsString);
      if sCod = '' then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      if sDescripcion = '' then
        sDescripcion := 'Familia ' + sCod;

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
      qIns.ParamByName('PAD_ART_FAM').AsInteger    := 5;
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
