{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigIvasGrupos                                            }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocgrpiva` (SQL Server, "Grupos de IVA") →                      }
{    `fza_ivas_grupos`.                                                        }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Grupo          (int)        → IVA_IVAGRP (varchar 10, texto)            }
{      Descripcion    (varchar 40) → DESCRIPCION_IVA_IVAGRP                    }
{      <constante>                  → CODIGO_PAI_IVA_IVAGRP   = 'ES'           }
{      <constante>                  → NOMBRE_PAI_IVA_IVAGRP   = 'España'       }
{      <constante>                  → ESAPLICA_RE_IVA_IVAGRP  = 'S'            }
{      <fila inicial>               → ESDEFAULT_IVA_IVAGRP    = 'S' / 'N'      }
{      <constante>                  → PALABRA_REPORTS_IVA_IVAGRP = 'IVA'       }
{                                                                              }
{    El primer grupo migrado se marca como ESDEFAULT='S', el resto 'N'.        }
{    Idempotente: si IVA_IVAGRP ya existe, salta sin error.                    }
{******************************************************************************}
unit inLibMigIvasGrupos;

interface

uses
  UMigEngine;

procedure MigrarIvasGrupos(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarIvasGrupos(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Grupo, Descripcion ' +
    'FROM dbo.ocgrpiva ' +
    'ORDER BY Grupo';
  cInsertDst =
    'INSERT INTO fza_ivas_grupos (' +
      'IVA_IVAGRP, CODIGO_PAI_IVA_IVAGRP, NOMBRE_PAI_IVA_IVAGRP, ' +
      'DESCRIPCION_IVA_IVAGRP, ESIRPF_IMP_INCL_IVA_IVAGRP, ' +
      'ESIVAAGRICOLA_IVA_IVAGRP, ESAPLICA_RE_IVA_IVAGRP, ' +
      'ESDEFAULT_IVA_IVAGRP, PALABRA_REPORTS_IVA_IVAGRP, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':IVA_IVAGRP, :CODIGO_PAI_IVA_IVAGRP, :NOMBRE_PAI_IVA_IVAGRP, ' +
      ':DESCRIPCION_IVA_IVAGRP, :ESIRPF_IMP_INCL_IVA_IVAGRP, ' +
      ':ESIVAAGRICOLA_IVA_IVAGRP, :ESAPLICA_RE_IVA_IVAGRP, ' +
      ':ESDEFAULT_IVA_IVAGRP, :PALABRA_REPORTS_IVA_IVAGRP, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk: TUniQuery;
  sCodGrp:          string;
  bPrimero:         Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_ivas_grupos WHERE IVA_IVAGRP = :c';

    bPrimero := True;
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      sCodGrp := IntToStr(qSrc.FieldByName('Grupo').AsInteger);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCodGrp;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - grupo IVA "%s" ya existe, se omite', [sCodGrp]);
        qChk.Close;
        bPrimero := False;  // un grupo ya existe, no marcamos default
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('IVA_IVAGRP').AsString               := sCodGrp;
      qIns.ParamByName('CODIGO_PAI_IVA_IVAGRP').AsString    := 'ES';
      qIns.ParamByName('NOMBRE_PAI_IVA_IVAGRP').AsString    := 'España';
      qIns.ParamByName('DESCRIPCION_IVA_IVAGRP').AsString   :=
        Trim(qSrc.FieldByName('Descripcion').AsString);
      qIns.ParamByName('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString := 'N';
      qIns.ParamByName('ESIVAAGRICOLA_IVA_IVAGRP').AsString   := 'N';
      qIns.ParamByName('ESAPLICA_RE_IVA_IVAGRP').AsString     := 'S';
      if bPrimero then
        qIns.ParamByName('ESDEFAULT_IVA_IVAGRP').AsString := 'S'
      else
        qIns.ParamByName('ESDEFAULT_IVA_IVAGRP').AsString := 'N';
      bPrimero := False;
      qIns.ParamByName('PALABRA_REPORTS_IVA_IVAGRP').AsString := 'IVA';
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando grupo "%s": %s', [sCodGrp, E.Message]);
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
