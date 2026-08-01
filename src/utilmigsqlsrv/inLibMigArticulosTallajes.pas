{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosTallajes                                     }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Asigna a cada articulo del legacy el SISTEMA DE TALLAS que tiene en      }
{    `ocartp.NroTallaje` → `fza_articulos_conjuntos_asign`.                   }
{                                                                              }
{    Sin esta asignacion, la pantalla de mantenimiento de articulos muestra   }
{    "— Sin conjunto —" en el desplegable de Talla y la generacion de SKUs    }
{    no sabe que tallas son las validas para el articulo.                     }
{                                                                              }
{    Prerequisito: inLibMigTallajes ya migro los conjuntos. Cada conjunto     }
{    se nombra "T<NroTallaje> - <Descripcion>" para identificarlo.            }
{                                                                              }
{    Mapeo:                                                                    }
{      ocartp.Articulo + ocartp.NroTallaje                                     }
{        →  fza_articulos_conjuntos_asign (CODIGO_ART_ACA, ID_AC_ACA,          }
{                                          ID_VA_ACA='TAL')                   }
{                                                                              }
{    Solo procesa articulos con NroTallaje > 0 y que exista en destino el     }
{    conjunto correspondiente.                                                 }
{                                                                              }
{    Idempotente: si la asignacion (CODIGO_ART, ID_VA='TAL') ya existe         }
{    se salta.                                                                 }
{******************************************************************************}
unit inLibMigArticulosTallajes;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarArticulosTallajes(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// Resuelve el ID_AC del conjunto que migramos para un NroTallaje
// concreto. Devuelve 0 si no se ha migrado el tallaje.
function ResolverConjunto(Eng: IContextoMigracion; iNroTallaje: Integer): Integer;
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    // Buscamos por prefijo "T<NroTallaje> -" que es como
    // inLibMigTallajes nombra los conjuntos.
    q.SQL.Text :=
      'SELECT ID_AC FROM fza_atributos_conjuntos ' +
      'WHERE ID_VAR_AC = ''TC'' AND ID_VA_AC = ''TAL'' ' +
      '  AND NOMBRE_AC LIKE :p ' +
      'LIMIT 1';
    q.ParamByName('p').AsString := Format('T%d - %%', [iNroTallaje]);
    q.Open;
    if q.IsEmpty then
      Result := 0
    else
      Result := q.FieldByName('ID_AC').AsInteger;
  finally
    q.Free;
  end;
end;

procedure MigrarArticulosTallajes(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, NroTallaje ' +
    'FROM dbo.ocartp ' +
    'WHERE NroTallaje IS NOT NULL ' +
    '  AND NroTallaje > 0 ' +
    '  AND LTRIM(RTRIM(Articulo)) <> '''' ' +
    'ORDER BY Articulo';
var
  qSrc, qChk, qIns:    TUniQuery;
  sArt:                string;
  iNroTallaje, iIdAc:  Integer;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_conjuntos_asign ' +
      'WHERE CODIGO_ART_ACA = :a AND ID_VA_ACA = ''TAL''';

    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   :=
      'INSERT INTO fza_articulos_conjuntos_asign (' +
        'CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
        'ESGENERACION_AUTO_ACA, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:a, :c, ''TAL'', 0, ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';

    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp ' +
      'WHERE NroTallaje IS NOT NULL AND NroTallaje > 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sArt        := Trim(qSrc.FieldByName('Articulo').AsString);
      iNroTallaje := qSrc.FieldByName('NroTallaje').AsInteger;

      iIdAc := ResolverConjunto(Eng, iNroTallaje);
      if iIdAc = 0 then
      begin
        Inc(Stats.Errores);
        Eng.Registro.LogError('art_tallaje', sArt,
          Format('NroTallaje %d no migrado en ' +
                 'fza_atributos_conjuntos', [iNroTallaje]),
          '', 'corre antes Tallajes (ocgrptal)');
        qSrc.Next;
        Continue;
      end;

      qChk.Close;
      qChk.ParamByName('a').AsString := sArt;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('a').AsString  := sArt;
      qIns.ParamByName('c').AsInteger := iIdAc;
      RellenarAuditoria(qIns, Eng.Usuario);
      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.LogError('art_tallaje', sArt, E.Message,
            Format('NroTallaje=%d ID_AC=%d', [iNroTallaje, iIdAc]), '');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qIns.Free;
    qChk.Free;
    qSrc.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'articulos_tallajes_asign',
    'Asignar sistema de tallas a artículo',
    'ocartp.NroTallaje → fza_articulos_conjuntos_asign',
    ['articulos', 'tallajes'],
    MigrarArticulosTallajes);

end.
