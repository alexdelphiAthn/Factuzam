{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosPropiedades                                  }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Crea la propiedad TEMPORADA y la asigna a cada articulo del legacy a    }
{    partir de `ocartp.Temporada` (varchar(5)). Esquema destino:               }
{                                                                              }
{    1. fza_propiedades: una fila con                                          }
{         CODIGO_PROP_ARTPROP = 'TEMPORADA'                                    }
{         NOMBRE_PROP_PROP   = 'Temporada'                                     }
{         TIPO_VALOR_PROP    = 'LISTA' (los valores van en fza_propiedades_   }
{                              valores y se referencian por ID)               }
{                                                                              }
{    2. fza_propiedades_valores: una fila por cada Temporada distinta de      }
{       ocartp (DISTINCT). Ej: '2026P', '2026O', 'PERM', etc.                  }
{                                                                              }
{    3. fza_articulos_propiedades: una fila por articulo con la temporada    }
{       que tenia en el legacy, enlazada por ID_PV_ARTPROP al valor.          }
{                                                                              }
{    Idempotente:                                                              }
{      - fza_propiedades: comprueba CODIGO_PROP_ARTPROP, si existe se salta. }
{      - fza_propiedades_valores: chequea (ID_PROP_PV, PV), idem.            }
{      - fza_articulos_propiedades: PK (CODIGO_ART_ART, CODIGO_PROP_ARTPROP) }
{        + INSERT IGNORE en el bulk.                                          }
{******************************************************************************}
unit inLibMigArticulosPropiedades;

interface

uses
  UMigEngine;

procedure MigrarArticulosPropiedades(Eng: TMigEngine;
                                      var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// =========================================================================
//  Helpers locales
// =========================================================================

procedure AsegurarPropiedadTemporada(Eng: TMigEngine);
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_propiedades ' +
      'WHERE CODIGO_PROP_ARTPROP = ''TEMPORADA''';
    qChk.Open;
    if not qChk.IsEmpty then Exit;
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_propiedades (' +
        'CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP, ' +
        'ESACTIVO_PROP, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (''TEMPORADA'', ''Temporada'', ''LISTA'', ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, ' +
              ':USUARIO_ALTA, :USUARIO_MODIF)';
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Eng.Log('  + propiedad TEMPORADA creada');
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Inserta un valor de propiedad si no existe ya. Devuelve True si
// inserto.
function InsertarValorPropiedad(Eng: TMigEngine;
                                 const sPV: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA'' AND PV = :v';
    qChk.ParamByName('v').AsString := sPV;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_propiedades_valores (' +
        'ID_PROP_PV, PV, ESACTIVO_PV, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (''TEMPORADA'', :v, ''S'', ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, ' +
              ':USUARIO_ALTA, :USUARIO_MODIF)';
    qIns.ParamByName('v').AsString := sPV;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

function BuscarIdPV(Eng: TMigEngine; const sPV: string): Integer;
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   :=
      'SELECT ID_PV_ARTPROP FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = ''TEMPORADA'' AND PV = :v LIMIT 1';
    q.ParamByName('v').AsString := sPV;
    q.Open;
    if q.IsEmpty then
      Result := 0
    else
      Result := q.FieldByName('ID_PV_ARTPROP').AsInteger;
  finally
    q.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarArticulosPropiedades(Eng: TMigEngine;
                                      var Stats: TMigStats);
const
  cSelectValores =
    'SELECT DISTINCT Temporada ' +
    'FROM dbo.ocartp ' +
    'WHERE LTRIM(RTRIM(ISNULL(Temporada, ''''))) <> '''' ' +
    'ORDER BY Temporada';
  cSelectAsign =
    'SELECT Articulo, Temporada ' +
    'FROM dbo.ocartp ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(ISNULL(Temporada, ''''))) <> '''' ' +
    'ORDER BY Articulo';
  cColsAP =
    'CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
    'INSTANTE_ALTA, USUARIO_ALTA';
var
  qVal, qSrc:                 TUniQuery;
  bulk:                       TBulkInsert;
  sTemp, sArt:                string;
  sFila, sAhora, sUser:       string;
  iIdPV:                      Integer;
begin
  AsegurarPropiedadTemporada(Eng);

  // 1. Volcar el catalogo de temporadas distintas
  qVal := NuevoQOrigen(Eng, cSelectValores);
  try
    qVal.Open;
    while not qVal.Eof do
    begin
      sTemp := Trim(qVal.FieldByName('Temporada').AsString);
      if sTemp <> '' then
      begin
        if InsertarValorPropiedad(Eng, sTemp) then
          Eng.Log('  + valor TEMPORADA "%s" creado', [sTemp]);
      end;
      qVal.Next;
    end;
  finally
    qVal.Free;
  end;

  // 2. Asignar la temporada a cada articulo (bulk insert)
  qSrc := NuevoQOrigen(Eng, cSelectAsign);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_propiedades',
                              cColsAP, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND LTRIM(RTRIM(ISNULL(Temporada, ''''))) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt  := Trim(qSrc.FieldByName('Articulo').AsString);
      sTemp := Trim(qSrc.FieldByName('Temporada').AsString);
      if (sArt = '') or (sTemp = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      iIdPV := BuscarIdPV(Eng, sTemp);
      if iIdPV = 0 then
      begin
        Inc(Stats.Errores);
        Eng.LogError('art_prop', sArt,
          Format('valor TEMPORADA "%s" no encontrado', [sTemp]),
          '', 'el paso de catalogo deberia haberlo creado');
        qSrc.Next;
        Continue;
      end;
      sFila := Format('%s, ''TEMPORADA'', %d, %s, %s',
        [ValorOrNull(sArt), iIdPV, sAhora, sUser]);
      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('art_prop', sArt, E.Message,
            Format('TEMPORADA=%s', [sTemp]), '');
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
