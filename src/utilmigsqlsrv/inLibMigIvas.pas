{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigIvas                                                  }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.octipiva` (SQL Server, "Tipos de IVA con histórico") →         }
{    `fza_ivas`.                                                               }
{                                                                              }
{    El origen guarda una fila por (TipoIva, Fecha, PorIVA) — un porcentaje    }
{    por tipo y fecha. El destino guarda una fila por CODIGO_IVA con 4        }
{    porcentajes (NORMAL / REDUCIDO / SUPERREDUCIDO / EXENTO) y sus RE,        }
{    válida en un rango de fechas.                                             }
{                                                                              }
{    Estrategia: para cada (TipoIva, Fecha) tomamos el primer porcentaje y     }
{    su RE asociado y lo colocamos en NORMAL. Las columnas reducido / súper    }
{    / exento las dejamos a 0. El usuario tendrá que afinar después si lo     }
{    necesita — el dato fino no existe en el origen.                           }
{                                                                              }
{    Idempotente: agrupa por (TipoIva, Fecha) y verifica que CODIGO_IVA no     }
{    exista antes de insertar.                                                 }
{******************************************************************************}
unit inLibMigIvas;

interface

uses
  UMigEngine;

procedure MigrarIvas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarIvas(Eng: TMigEngine; var Stats: TMigStats);
const
  // Para cada (TipoIva, Fecha) tomamos el porcentaje "principal" como el de
  // mayor PorIVA. Asi NORMAL queda con el % general (21%, 10%...) y no con
  // el de Exento (0).
  cSelectSrc =
    'SELECT TipoIva, Fecha, MAX(PorIVA) AS PorIVA, ' +
    '       MAX(ISNULL(PorRe, 0)) AS PorRE ' +
    'FROM dbo.octipiva ' +
    'GROUP BY TipoIva, Fecha ' +
    'ORDER BY TipoIva, Fecha';
  cInsertDst =
    'INSERT INTO fza_ivas (' +
      'CODIGO_IVA, IVA_IVAGRP, DESCRIPCION_IVA_IVAGRP, ' +
      'PORCENTAJE_EXENTO_IVA, PORCENTAJE_EXENTO_RE_IVA, ' +
      'PORCENTAJE_NORMAL_IVA, PORCENTAJE_NORMAL_RE_IVA, ' +
      'PORCENTAJE_REDUCIDO_IVA, PORCENTAJE_REDUCIDO_RE_IVA, ' +
      'PORCENTAJE_SUPERREDUCIDO_IVA, PORCENTAJE_SUPERREDUCIDO_RE_IVA, ' +
      'FECHA_DESDE_IVA, FECHA_HASTA_IVA, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_IVA, :IVA_IVAGRP, :DESCRIPCION_IVA_IVAGRP, ' +
      '0, 0, ' +
      ':PORCENTAJE_NORMAL_IVA, :PORCENTAJE_NORMAL_RE_IVA, ' +
      '0, 0, 0, 0, ' +
      ':FECHA_DESDE_IVA, NULL, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk: TUniQuery;
  iTipo: Integer;
  sCodIva: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   := 'SELECT 1 FROM fza_ivas WHERE CODIGO_IVA = :c';

    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      iTipo   := qSrc.FieldByName('TipoIva').AsInteger;
      // El destino guarda histórico por tabla, no por fila. Para no perder
      // versiones, generamos CODIGO_IVA = TipoIva-AAAAMMDD.
      sCodIva := Format('%d-%s',
        [iTipo,
         FormatDateTime('yyyymmdd', qSrc.FieldByName('Fecha').AsDateTime)]);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCodIva;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - IVA "%s" ya existe, se omite', [sCodIva]);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('CODIGO_IVA').AsString             := sCodIva;
      // Heuristica: el primer grupo IVA migrado es '1' (España Peninsula).
      // Asumimos que casi todo el histórico cae en ese grupo. El usuario
      // tendrá que reasignar IVAs portugueses / canarios manualmente.
      qIns.ParamByName('IVA_IVAGRP').AsString             := '1';
      qIns.ParamByName('DESCRIPCION_IVA_IVAGRP').AsString :=
        Format('IVA tipo %d desde %s', [iTipo,
          FormatDateTime('dd/mm/yyyy', qSrc.FieldByName('Fecha').AsDateTime)]);
      qIns.ParamByName('PORCENTAJE_NORMAL_IVA').AsFloat    :=
        qSrc.FieldByName('PorIVA').AsFloat;
      qIns.ParamByName('PORCENTAJE_NORMAL_RE_IVA').AsFloat :=
        qSrc.FieldByName('PorRE').AsFloat;
      qIns.ParamByName('FECHA_DESDE_IVA').AsDateTime       :=
        qSrc.FieldByName('Fecha').AsDateTime;
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando IVA "%s": %s', [sCodIva, E.Message]);
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
