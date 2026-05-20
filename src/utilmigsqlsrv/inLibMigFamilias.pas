{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFamilias                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.1.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.oclwgrupo` (SQL Server: catálogo de grupos/familias de         }
{    artículo, con código de 4 caracteres tipo "0101", "0308"...) →            }
{    `fza_articulos_familias`.                                                 }
{                                                                              }
{    NOTA: la primera versión apuntaba a `dbo.ocartniv` pero esa tabla solo    }
{    define los NIVELES de la jerarquía (SECCION=2 chars, FAMILIA=4 chars),    }
{    no las familias reales. Los códigos de familia que cita `ocartp.Familia`  }
{    (formato 4 dígitos) viven en `oclwgrupo`.                                 }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Grupo       (varchar 4)   → CODIGO_FAM_FAM                              }
{      Descripcion (varchar 60)  → NOMBRE_FAM_FAM y DESCRIPCION_FAM            }
{      <constante>                → ESACTIVO_FAM    = 'S'                       }
{      <fila inicial>             → ESDEFAULT_FAM   = 'S' (primera), 'N' resto }
{      <orden lectura>            → ORDEN_FAM       = 10, 20, 30...            }
{                                                                              }
{    El código de familia se conserva tal cual ("0101" → "0101"), de modo      }
{    que `fza_articulos.CODIGO_FAM_ART = ocartp.Familia` cuadra directamente   }
{    sin transformación.                                                       }
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
  cSelectSrc =
    'SELECT Grupo, Descripcion ' +
    'FROM dbo.oclwgrupo ' +
    'WHERE LTRIM(RTRIM(Grupo)) <> '''' ' +
    'ORDER BY Grupo';
  cInsertDst =
    'INSERT INTO fza_articulos_familias (' +
      'CODIGO_FAM_FAM, ESACTIVO_FAM, ORDEN_FAM, ESDEFAULT_FAM, ' +
      'NOMBRE_FAM_FAM, DESCRIPCION_FAM, PAD_ART_FAM, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_FAM_FAM, :ESACTIVO_FAM, :ORDEN_FAM, :ESDEFAULT_FAM, ' +
      ':NOMBRE_FAM_FAM, :DESCRIPCION_FAM, :PAD_ART_FAM, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk:  TUniQuery;
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
      sCod         := Trim(qSrc.FieldByName('Grupo').AsString);
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
      qIns.ParamByName('ESACTIVO_FAM').AsString    := 'S';
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
