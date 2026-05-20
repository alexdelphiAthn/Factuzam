{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFamilias                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocartniv` (SQL Server, "Niveles" usados como familias de       }
{    artículo en el legacy) → `fza_articulos_familias`.                        }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Nivel       (int)         → CODIGO_FAM_FAM (texto, padding 3)           }
{      Descripcion (varchar 15)  → DESCRIPCION_FAM                             }
{      Nombre      (varchar 15)  → NOMBRE_FAM_FAM                              }
{      <constante>                → ESACTIVO_FAM    = 'S'                       }
{      <fila inicial>             → ESDEFAULT_FAM   = 'S' (primera), 'N' resto }
{      <orden lectura>            → ORDEN_FAM       = 10, 20, 30...            }
{                                                                              }
{    Genera el código de familia en formato 3 dígitos (001, 002...) para que   }
{    encaje con el resto del esquema destino (que usa varchar(20) y suele      }
{    valores cortos).                                                          }
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
    'SELECT Nivel, Descripcion, Nombre ' +
    'FROM dbo.ocartniv ' +
    'ORDER BY Nivel';
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
  qSrc, qIns, qChk:    TUniQuery;
  sCod, sNombre, sDsc: string;
  iOrden, iNivel:      Integer;
  bPrimero:            Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_familias ' +
      'WHERE CODIGO_FAM_FAM = :c';

    iOrden   := 10;
    bPrimero := True;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      iNivel  := qSrc.FieldByName('Nivel').AsInteger;
      sCod    := Format('%.3d', [iNivel]);
      sNombre := Trim(qSrc.FieldByName('Nombre').AsString);
      sDsc    := Trim(qSrc.FieldByName('Descripcion').AsString);
      if sNombre = '' then sNombre := sDsc;
      if sNombre = '' then sNombre := 'Familia ' + sCod;
      if sDsc    = '' then sDsc    := sNombre;

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - familia "%s" ya existe, se omite', [sCod]);
        qChk.Close;
        bPrimero := False;  // ya hay una familia, no marcamos default nueva
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
      qIns.ParamByName('NOMBRE_FAM_FAM').AsString  := sNombre;
      qIns.ParamByName('DESCRIPCION_FAM').AsString := sDsc;
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
