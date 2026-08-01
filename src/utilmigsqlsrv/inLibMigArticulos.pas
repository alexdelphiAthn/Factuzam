{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulos                                             }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocartp` (SQL Server, cabecera de artículo) → `fza_articulos`.  }
{                                                                              }
{    Mapeo origen → destino (resumen):                                         }
{      Articulo                  → CODIGO_ART_ART                              }
{      DescripcionLarga/Corta    → DESCRIPCION_ART                             }
{      Familia                   → CODIGO_FAM_ART                              }
{      TipoIva (int)             → TIPO_IVA_ART (char(2): "N" por defecto)     }
{      Estado                    → ESACTIVO_ART (Estado='B' → 'N', resto 'S')  }
{      Tipo                      → TIPO_ART ('S'→SERVICIO, 'K'→KIT, resto      }
{                                  ESTANDAR)                                   }
{      HayColores + HayTallas    → ESVARIACION_ART y TIPO_VARIACION_ART        }
{      (sin equivalente directo) → TIPO_CANTIDAD_ART = 'Uds'                   }
{                                                                              }
{    Idempotente: si el artículo ya existe (mismo CODIGO_ART_ART) se salta.   }
{******************************************************************************}
unit inLibMigArticulos;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarArticulos(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarArticulos(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, DescripcionCorta, DescripcionLarga, Familia, ' +
    '       TipoIva, Estado, Tipo, HayColores, HayTallas ' +
    'FROM dbo.ocartp ' +
    'ORDER BY Articulo';
  cInsertDst =
    'INSERT INTO fza_articulos (' +
      'CODIGO_ART_ART, ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, ' +
      'CODIGO_FAM_ART, TIPO_IVA_ART, ESACTIVO_FIJO_ART, ' +
      'TIPO_CANTIDAD_ART, ESVARIACION_ART, ESTRAZABLE_ART, ' +
      'TIPO_VARIACION_ART, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_ART_ART, :ESACTIVO_ART, :TIPO_ART, :DESCRIPCION_ART, ' +
      ':CODIGO_FAM_ART, :TIPO_IVA_ART, :ESACTIVO_FIJO_ART, ' +
      ':TIPO_CANTIDAD_ART, :ESVARIACION_ART, :ESTRAZABLE_ART, ' +
      ':TIPO_VARIACION_ART, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';

  function DeducirTipo(const sTipo: string): string;
  var s: string;
  begin
    s := UpperCase(Trim(sTipo));
    if s = 'S' then Exit('SERVICIO');
    if s = 'K' then Exit('KIT');
    Result := 'ESTANDAR';
  end;

  function DeducirTipoVariacion(bColores, bTallas: Boolean): string;
  begin
    if bColores and bTallas then Exit('TC');
    if bColores             then Exit('C');
    if bTallas              then Exit('T');
    Result := '';
  end;

var
  qSrc, qIns, qChk: TUniQuery;
  sCod, sDesc, sFam, sTipoVar: string;
  bColores, bTallas:           Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos WHERE CODIGO_ART_ART = :c';

    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen('SELECT COUNT(*) FROM dbo.ocartp'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sCod := Trim(qSrc.FieldByName('Articulo').AsString);
      if sCod = '' then
      begin
        Inc(Stats.Saltadas);
        Eng.Registro.Log('  - articulo con codigo vacio, se omite');
        qSrc.Next;
        Continue;
      end;

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Registro.Log('  - articulo "%s" ya existe, se omite', [sCod]);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      sDesc := Trim(qSrc.FieldByName('DescripcionLarga').AsString);
      if sDesc = '' then
        sDesc := Trim(qSrc.FieldByName('DescripcionCorta').AsString);
      if sDesc = '' then
        sDesc := sCod;
      sFam     := Trim(qSrc.FieldByName('Familia').AsString);
      bColores := BoolSN(qSrc.FieldByName('HayColores').AsString) = 'S';
      bTallas  := BoolSN(qSrc.FieldByName('HayTallas').AsString)  = 'S';
      sTipoVar := DeducirTipoVariacion(bColores, bTallas);

      qIns.ParamByName('CODIGO_ART_ART').AsString := sCod;
      // En origen Estado='B' es baja, resto activo.
      if UpperCase(Trim(qSrc.FieldByName('Estado').AsString)) = 'B' then
        qIns.ParamByName('ESACTIVO_ART').AsString := 'N'
      else
        qIns.ParamByName('ESACTIVO_ART').AsString := 'S';
      qIns.ParamByName('TIPO_ART').AsString :=
        DeducirTipo(qSrc.FieldByName('Tipo').AsString);
      qIns.ParamByName('DESCRIPCION_ART').AsString := sDesc;
      if sFam <> '' then
        qIns.ParamByName('CODIGO_FAM_ART').AsString := sFam
      else
        qIns.ParamByName('CODIGO_FAM_ART').Clear;
      // TIPO_IVA_ART en destino es char(2). En origen es int. Como por
      // defecto la tarifa "normal" se identifica con 'N', dejamos 'N' y
      // que el usuario reasigne despues si hay reducidos.
      qIns.ParamByName('TIPO_IVA_ART').AsString  := 'N';
      qIns.ParamByName('ESACTIVO_FIJO_ART').AsString := 'N';
      qIns.ParamByName('TIPO_CANTIDAD_ART').AsString := 'Uds';
      if bColores or bTallas then
        qIns.ParamByName('ESVARIACION_ART').AsString := 'S'
      else
        qIns.ParamByName('ESVARIACION_ART').AsString := 'N';
      qIns.ParamByName('ESTRAZABLE_ART').AsString := 'N';
      if sTipoVar <> '' then
        qIns.ParamByName('TIPO_VARIACION_ART').AsString := sTipoVar
      else
        qIns.ParamByName('TIPO_VARIACION_ART').Clear;
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Registro.Log('  ! error insertando articulo "%s": %s',
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

initialization
  RegistrarMigracion(
    'articulos',
    'Artículos',
    'dbo.ocartp → fza_articulos',
    ['familias'],
    MigrarArticulos);

end.
