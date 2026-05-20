{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosProveedores                                  }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Vincula cada articulo con su proveedor principal del legacy y la         }
{    referencia que el proveedor usaba (Modelo en ocartp).                    }
{                                                                              }
{    Mapeo:                                                                    }
{      ocartp.Articulo   → fza_articulos_proveedores.CODIGO_ART_AP            }
{      ocartp.Proveedor  → fza_articulos_proveedores.CODIGO_PRV_AP            }
{      ocartp.Modelo     → fza_articulos_proveedores.REF_PROVEEDOR_AP         }
{      <constante>        → ESPROVEEDORPRINCIPAL_AP = 'S'                      }
{                                                                              }
{    Solo procesa articulos con Proveedor > 0. Si el proveedor no esta        }
{    migrado en fza_proveedores el INSERT no falla (no hay FK declarada);     }
{    el usuario tendra una fila huerfana que es facil de detectar luego.     }
{                                                                              }
{    Idempotente: PK (CODIGO_PRV_AP, CODIGO_ART_AP) + INSERT IGNORE en el     }
{    bulk insert.                                                              }
{******************************************************************************}
unit inLibMigArticulosProveedores;

interface

uses
  UMigEngine;

procedure MigrarArticulosProveedores(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarArticulosProveedores(Eng: TMigEngine;
                                      var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, Proveedor, ISNULL(Modelo, '''') AS Modelo ' +
    'FROM dbo.ocartp ' +
    'WHERE Proveedor IS NOT NULL AND Proveedor > 0 ' +
    '  AND LTRIM(RTRIM(Articulo)) <> '''' ' +
    'ORDER BY Proveedor, Articulo';
  cCols =
    'CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
    'ESPROVEEDORPRINCIPAL_AP, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                       TUniQuery;
  bulk:                       TBulkInsert;
  sArt, sProv, sModelo:       string;
  sFila, sAhora, sUser, sRef: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_proveedores',
                              cCols, 1000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp ' +
      'WHERE Proveedor IS NOT NULL AND Proveedor > 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt    := Trim(qSrc.FieldByName('Articulo').AsString);
      sProv   := IntToStr(qSrc.FieldByName('Proveedor').AsInteger);
      sModelo := Trim(qSrc.FieldByName('Modelo').AsString);
      if (sArt = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      if sModelo = '' then
        sRef := 'NULL'
      else
        sRef := ValorOrNull(sModelo);

      sFila := Format('%s, %s, %s, ''S'', %s, %s, %s, %s',
        [ValorOrNull(sProv), ValorOrNull(sArt), sRef,
         sAhora, sAhora, sUser, sUser]);
      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('art_prv', sArt, E.Message,
            Format('prv=%s modelo=%s', [sProv, sModelo]), '');
          raise;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
  end;
end;

end.
