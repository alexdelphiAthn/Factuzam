{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigEntorno                                               }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    "Ajuste del entorno": migra la configuración operativa del legacy a       }
{    Factuzam para que la instalación migrada quede lista para funcionar.      }
{    Cuatro piezas, cada una un dominio independiente del migrador:            }
{                                                                              }
{      1. Cajas de almacén   dbo.occajas   → fza_almacenes_cajas              }
{      2. Series por empresa  dbo.ocseract  → fza_empresas_series             }
{      3. Contadores          dbo.occtador  → fza_contadores                  }
{      4. Contador por familia dbo.ocnivnro → fza_articulos_familias          }
{                                            (CONTADOR_ART_FAM)                 }
{                                                                              }
{    No requiere cambios de esquema (las cuatro tablas destino ya existen).    }
{                                                                              }
{    Decisiones de mapeo (acordadas con el usuario):                           }
{      - Contadores: fza_contadores se indexa por (TipoDoc, Empresa, Serie),  }
{        sin almacén/caja/ejercicio. Consolidamos el almacén/caja con el       }
{        contador MÁXIMO y metemos el ejercicio en la serie                    }
{        ('<Ejercicio>.<Serie>', p.ej. '2025.A1', igual que las facturas).     }
{        Los contadores globales del legacy (Serie='-') van con                }
{        EMPRESA='-' y SERIE='-'.                                              }
{      - Solo se migran los tipos de documento que existen en el catálogo      }
{        fza_tipos_documentos (VE, AL, AT, TR, FC, FP, IN, MV, CL, PV, PC,     }
{        AE). El resto se omite y se registra en el log.                       }
{      - Contador por familia: se toma de ocnivnro.Contador (el contador real  }
{        del legacy), no de una heurística. El código de familia de ocnivnro   }
{        coincide literalmente con CODIGO_FAM_FAM (la migración de familias    }
{        conserva ocniv.Codigo).                                               }
{******************************************************************************}
unit inLibMigEntorno;

interface

uses
  UMigEngine;

procedure MigrarEntornoCajas(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarEntornoSeries(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarEntornoContadores(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarEntornoContadoresFamilia(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni;

// =========================================================================
//  1. Cajas de almacén  (dbo.occajas → fza_almacenes_cajas)
// =========================================================================

procedure MigrarEntornoCajas(Eng: TMigEngine; var Stats: TMigStats);
const
  // Una fila por caja física (incluida la caja 99 "central/virtual"). El
  // nombre del almacén lo da ocalm.Abreviatura, igual que en el resto de la
  // migración, para que CODIGO_ALM cuadre con operaciones/movimientos.
  cSelect =
    'SELECT cj.Empresa, cj.Almacen, cj.Caja, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(cj.Nombre, '''') AS Nombre ' +
    'FROM dbo.occajas cj ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = cj.Empresa ' +
    '                       AND alm.Almacen = cj.Almacen';
  // fza_almacenes_cajas no tiene columnas de auditoría: solo 3 columnas.
  cInsert =
    'INSERT IGNORE INTO fza_almacenes_cajas ' +
    '  (CODIGO_ALM_ALMCAJ, CODIGO_CAJA_ALMCAJ, DESCRIPCION_ALMCAJ) ' +
    'VALUES (:alm, :caja, :desc)';
var
  qSrc, qIns:        TUniQuery;
  sAlm, sCaja, sDesc: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelect);
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsert;
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.occajas'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sAlm := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qSrc.FieldByName('Almacen').AsInteger);
      sCaja := IntToStr(qSrc.FieldByName('Caja').AsInteger);
      sDesc := Trim(qSrc.FieldByName('Nombre').AsString);
      if sDesc = '' then
        sDesc := Format('Alm: %s - Caja: %s', [sAlm, sCaja]);
      qIns.ParamByName('alm').AsString  := Copy(sAlm, 1, 10);
      qIns.ParamByName('caja').AsString := Copy(sCaja, 1, 10);
      qIns.ParamByName('desc').AsString := Copy(sDesc, 1, 100);
      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('caja', sAlm + '/' + sCaja, E.Message, '',
            'la caja requiere que el almacen ya este migrado');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qIns.Free;
    qSrc.Free;
  end;
end;

// =========================================================================
//  2. Series por empresa  (dbo.ocseract → fza_empresas_series)
// =========================================================================

procedure MigrarEntornoSeries(Eng: TMigEngine; var Stats: TMigStats);
const
  // ocseract asigna a CADA tipo de documento la misma serie por tienda
  // (almacén 11→A1, 21→E1, 44→K1, 51→G1...). Con DISTINCT colapsamos a una
  // sola serie por (empresa, almacén): el INSERT IGNORE descarta repetidas.
  // TIPO_DOC queda a NULL (la serie sirve para cualquier tipo).
  cSelect =
    'SELECT DISTINCT sr.Empresa, sr.Almacen, ' +
    '       LTRIM(RTRIM(sr.SerieCIva)) AS Serie, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm ' +
    'FROM dbo.ocseract sr ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = sr.Empresa ' +
    '                       AND alm.Almacen = sr.Almacen ' +
    'WHERE LTRIM(RTRIM(sr.SerieCIva)) <> ''''';
  cInsert =
    'INSERT IGNORE INTO fza_empresas_series ' +
    '  (CODIGO_SERIE_EMPSER, CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER, ' +
    '   CODIGO_CAJA_EMPSER, EMPSER, TIPO_DOC_EMPSER, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :emp, :alm, NULL, :ser, NULL, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns:    TUniQuery;
  sSerie, sEmp, sAlm: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelect);
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsert;
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM (SELECT DISTINCT Empresa, Almacen, SerieCIva ' +
      'FROM dbo.ocseract WHERE LTRIM(RTRIM(SerieCIva)) <> '''') t'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := Trim(qSrc.FieldByName('Serie').AsString);
      sEmp   := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
      sAlm   := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(qSrc.FieldByName('Almacen').AsInteger);
      // CODIGO_SERIE_EMPSER (PK, varchar 10) = la serie; EMPSER = la serie
      // (varchar 12). En este legacy la serie es única por tienda.
      qIns.ParamByName('cod').AsString := Copy(sSerie, 1, 10);
      qIns.ParamByName('emp').AsString := Copy(sEmp, 1, 10);
      qIns.ParamByName('alm').AsString := Copy(sAlm, 1, 10);
      qIns.ParamByName('ser').AsString := Copy(sSerie, 1, 12);
      RellenarAuditoria(qIns, Eng.Usuario);
      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('serie', sSerie, E.Message, 'emp=' + sEmp, '');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qIns.Free;
    qSrc.Free;
  end;
end;

// =========================================================================
//  3. Contadores  (dbo.occtador → fza_contadores)
// =========================================================================

// Mapea el tipo de documento del legacy al del catálogo fza_tipos_documentos.
// Solo los tipos con equivalente claro; el resto devuelve '' (se omite).
function MapearTipoContador(const sTipo: string): string;
var
  t: string;
begin
  t := UpperCase(Trim(sTipo));
  if (t = 'VE') or (t = 'AL') or (t = 'AT') or (t = 'TR')
  or (t = 'FC') or (t = 'FP') or (t = 'IN') or (t = 'MV')
  or (t = 'CL') or (t = 'PV') or (t = 'PC') or (t = 'AE') then
    Result := t
  else
    Result := '';
end;

// Borra los contadores creados por una corrida previa de este usuario, para
// que el dominio sea re-ejecutable (no usa INSERT IGNORE porque queremos
// REFRESCAR el valor del contador, no conservar el viejo).
procedure LimpiarContadoresPrevios(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := 'DELETE FROM fza_contadores WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure MigrarEntornoContadores(Eng: TMigEngine; var Stats: TMigStats);
const
  // Agrupamos por (TipoDoc, Empresa, Ejercicio, Serie) tomando el contador
  // MÁXIMO: así consolidamos las dimensiones almacén/caja que el destino no
  // tiene. Usamos Contador (no ContadorCalculado, que viene NULL en años
  // recientes). Excluimos series vacías.
  cSelect =
    'SELECT LTRIM(RTRIM(TipoDoc)) AS TipoDoc, Empresa, Ejercicio, ' +
    '       LTRIM(RTRIM(Serie)) AS Serie, MAX(ISNULL(Contador,0)) AS MaxCon ' +
    'FROM dbo.occtador ' +
    'WHERE LTRIM(RTRIM(Serie)) <> '''' ' +
    '  AND LTRIM(RTRIM(TipoDoc)) <> '''' ' +
    'GROUP BY LTRIM(RTRIM(TipoDoc)), Empresa, Ejercicio, LTRIM(RTRIM(Serie))';
  cInsert =
    'INSERT IGNORE INTO fza_contadores ' +
    '  (TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
    '   ESACTIVO_CON, DEFAULT_CON, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:td, :emp, :ser, :con, :dig, ''S'', :def, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns:                   TUniQuery;
  sTipoLeg, sTipo:              string;
  sSerieLeg, sSerieCon, sEmpCon, sDef: string;
  iEjercicio, iDig:             Integer;
  iMaxCon:                      Int64;
  bGlobal:                      Boolean;
  oOmitidos:                    TStringList;
begin
  LimpiarContadoresPrevios(Eng);
  oOmitidos := TStringList.Create;
  oOmitidos.Sorted     := True;
  oOmitidos.Duplicates := dupIgnore;
  qSrc := NuevoQOrigen(Eng, cSelect);
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsert;
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM (SELECT TipoDoc, Empresa, Ejercicio, Serie ' +
      'FROM dbo.occtador WHERE LTRIM(RTRIM(Serie)) <> '''' ' +
      '  AND LTRIM(RTRIM(TipoDoc)) <> '''' ' +
      'GROUP BY TipoDoc, Empresa, Ejercicio, Serie) t'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sTipoLeg   := Trim(qSrc.FieldByName('TipoDoc').AsString);
      sTipo      := MapearTipoContador(sTipoLeg);
      sSerieLeg  := Trim(qSrc.FieldByName('Serie').AsString);
      iEjercicio := qSrc.FieldByName('Ejercicio').AsInteger;
      iMaxCon    := qSrc.FieldByName('MaxCon').AsLargeInt;
      if sTipo = '' then
      begin
        // Tipo fuera del catálogo Factuzam: lo registramos y seguimos.
        oOmitidos.Add(sTipoLeg);
        Inc(Stats.Saltadas);
      end
      else
      begin
        bGlobal := (sSerieLeg = '-');
        if bGlobal then
        begin
          sEmpCon   := '-';
          sSerieCon := '-';
          sDef      := 'S';
        end
        else
        begin
          sEmpCon   := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
          sSerieCon := Format('%d.%s', [iEjercicio, sSerieLeg]);
          sDef      := 'N';
        end;
        // Ancho de dígitos: al menos 6, o lo que pida el propio contador.
        iDig := Length(IntToStr(iMaxCon)) + 1;
        if iDig < 6 then
          iDig := 6;
        qIns.ParamByName('td').AsString    := sTipo;
        qIns.ParamByName('emp').AsString   := Copy(sEmpCon, 1, 10);
        qIns.ParamByName('ser').AsString   := Copy(sSerieCon, 1, 12);
        qIns.ParamByName('con').AsLargeInt := iMaxCon;
        qIns.ParamByName('dig').AsInteger  := iDig;
        qIns.ParamByName('def').AsString   := sDef;
        RellenarAuditoria(qIns, Eng.Usuario);
        try
          qIns.ExecSQL;
          Inc(Stats.Insertadas);
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('contador', sTipo + '/' + sSerieCon, E.Message,
              '', '');
          end;
        end;
      end;
      qSrc.Next;
    end;
    if oOmitidos.Count > 0 then
      Eng.Log('  contadores: %d tipos legacy omitidos (fuera de catalogo): %s',
              [oOmitidos.Count, oOmitidos.CommaText]);
  finally
    qIns.Free;
    qSrc.Free;
    oOmitidos.Free;
  end;
end;

// =========================================================================
//  4. Contador por familia  (dbo.ocnivnro → fza_articulos_familias)
// =========================================================================

procedure MigrarEntornoContadoresFamilia(Eng: TMigEngine;
                                         var Stats: TMigStats);
const
  // ocnivnro.Codigo = familia hoja; ocnivnro.Contador = último número de
  // artículo emitido en esa familia. Tomamos MAX por si hay varias filas
  // (empresa/almacén). El código coincide literal con CODIGO_FAM_FAM.
  cSelect =
    'SELECT LTRIM(RTRIM(Codigo)) AS Codigo, ' +
    '       MAX(ISNULL(Contador,0)) AS MaxCon ' +
    'FROM dbo.ocnivnro ' +
    'WHERE LTRIM(RTRIM(Codigo)) <> '''' ' +
    'GROUP BY LTRIM(RTRIM(Codigo))';
  cUpdate =
    'UPDATE fza_articulos_familias ' +
    'SET CONTADOR_ART_FAM = :con, ESCONTADOR_ART_FAM = ''S'', ' +
    '    INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
    'WHERE CODIGO_FAM_FAM = :cod';
var
  qSrc, qUpd: TUniQuery;
  sCod:       string;
  iCon:       Int64;
begin
  qSrc := NuevoQOrigen(Eng, cSelect);
  qUpd := TUniQuery.Create(nil);
  try
    qUpd.Connection := Eng.ConDst;
    qUpd.SQL.Text   := cUpdate;
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM (SELECT DISTINCT LTRIM(RTRIM(Codigo)) AS C ' +
      'FROM dbo.ocnivnro WHERE LTRIM(RTRIM(Codigo)) <> '''') t'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCod := Trim(qSrc.FieldByName('Codigo').AsString);
      iCon := qSrc.FieldByName('MaxCon').AsLargeInt;
      qUpd.ParamByName('con').AsLargeInt := iCon;
      qUpd.ParamByName('u').AsString     := Eng.Usuario;
      qUpd.ParamByName('cod').AsString   := sCod;
      try
        qUpd.ExecSQL;
        // RowsAffected 0 = la familia no se migró (no existe en destino).
        if qUpd.RowsAffected > 0 then
          Inc(Stats.Insertadas)
        else
          Inc(Stats.Saltadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('contador_familia', sCod, E.Message, '',
            'requiere que las Familias ya esten migradas');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qUpd.Free;
    qSrc.Free;
  end;
end;

end.
