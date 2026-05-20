{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFormasPago                                            }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.octipefe` (SQL Server, "Tipos de Efecto") → `fza_formas_pago`. }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      TipoEfecto     (int)        → CODIGO_FP_FP (varchar 20, texto)          }
{      Descripcion    (varchar 40) → DESCRIPCION_FORMA_PAGO_FP                 }
{      <constante>                  → ESACTIVO_FORMA_PAGO_FP   = 'S'           }
{      <fila inicial>               → ORDEN_FORMA_PAGO_FP      = orden lectura }
{      <constante>                  → N_PLAZOS_FORMA_PAGO_FP   = 1             }
{      <constante>                  → N_DIAS_ENTRE_PLAZOS_..._FP = 0           }
{      <constante>                  → ESDEFAULT_FORMA_PAGO_FP  = 'N'           }
{                                                                              }
{    Si la forma de pago ya existe en destino (mismo CODIGO_FP_FP) se SALTA    }
{    sin error y se contabiliza en Stats.Saltadas. Asi la migracion es        }
{    re-ejecutable.                                                            }
{******************************************************************************}
unit inLibMigFormasPago;

interface

uses
  UMigEngine;

procedure MigrarFormasPago(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarFormasPago(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT TipoEfecto, Descripcion ' +
    'FROM dbo.octipefe ' +
    'ORDER BY TipoEfecto';
  cInsertDst =
    'INSERT INTO fza_formas_pago (' +
      'CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ORDEN_FORMA_PAGO_FP, ' +
      'DESCRIPCION_FORMA_PAGO_FP, N_PLAZOS_FORMA_PAGO_FP, ' +
      'N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, ESDEFAULT_FORMA_PAGO_FP, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_FP_FP, :ESACTIVO_FORMA_PAGO_FP, :ORDEN_FORMA_PAGO_FP, ' +
      ':DESCRIPCION_FORMA_PAGO_FP, :N_PLAZOS_FORMA_PAGO_FP, ' +
      ':N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, :ESDEFAULT_FORMA_PAGO_FP, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk: TUniQuery;
  sCodFP, sDescripcion: string;
  iOrden: Integer;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;

    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_formas_pago WHERE CODIGO_FP_FP = :c';

    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.octipefe'));
    qSrc.Open;
    iOrden := 100;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCodFP        := IntToStr(qSrc.FieldByName('TipoEfecto').AsInteger);
      sDescripcion  := Trim(qSrc.FieldByName('Descripcion').AsString);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCodFP;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - ya existe forma pago "%s", se omite', [sCodFP]);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('CODIGO_FP_FP').AsString             := sCodFP;
      qIns.ParamByName('ESACTIVO_FORMA_PAGO_FP').AsString   := 'S';
      qIns.ParamByName('ORDEN_FORMA_PAGO_FP').AsInteger     := iOrden;
      qIns.ParamByName('DESCRIPCION_FORMA_PAGO_FP').AsString:= sDescripcion;
      qIns.ParamByName('N_PLAZOS_FORMA_PAGO_FP').AsInteger  := 1;
      qIns.ParamByName('N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP').AsInteger := 0;
      qIns.ParamByName('ESDEFAULT_FORMA_PAGO_FP').AsString  := 'N';
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
        Inc(iOrden, 10);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando "%s": %s', [sCodFP, E.Message]);
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
