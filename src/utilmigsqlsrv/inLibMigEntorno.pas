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
{      2. Series actuales por empresa → fza_empresas_series                  }
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
  UMigEngine, UMigCatalogo;

procedure MigrarEntornoCajas(const Eng: IContextoMigracion; var Stats: TMigStats);
procedure MigrarEntornoSeries(const Eng: IContextoMigracion; var Stats: TMigStats);
procedure MigrarEntornoContadores(const Eng: IContextoMigracion; var Stats: TMigStats);
procedure MigrarEntornoContadoresFamilia(const Eng: IContextoMigracion; var Stats: TMigStats);
procedure AjustarContadoresDestino(Eng: IContextoMigracion);
procedure MigrarAjusteContadores(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni;

// =========================================================================
//  1. Cajas de almacén  (dbo.occajas → fza_almacenes_cajas)
// =========================================================================

procedure MigrarEntornoCajas(const Eng: IContextoMigracion; var Stats: TMigStats);
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
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   := cInsert;
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen('SELECT COUNT(*) FROM dbo.occajas'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
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
          Eng.Registro.LogError('caja', sAlm + '/' + sCaja, E.Message, '',
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
//  2. Series actuales por empresa
// =========================================================================

procedure MigrarEntornoSeries(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  // La serie vigente se deduce de los contadores del ultimo ejercicio. Si
  // hubiera varias, se toma la usada por mas tipos documentales. ocseract no
  // interviene porque describe configuracion legacy por almacen, no las
  // series operativas que necesita actualmente Factuzam.
  cSelectActual =
    'WITH Series AS (' +
    ' SELECT Empresa, Ejercicio, LTRIM(RTRIM(Serie)) AS Serie, ' +
    '        ROW_NUMBER() OVER (PARTITION BY Empresa ' +
    '          ORDER BY Ejercicio DESC, COUNT(*) DESC, ' +
    '                   LTRIM(RTRIM(Serie))) AS Posicion ' +
    ' FROM dbo.occtador ' +
    ' WHERE Ejercicio > 0 AND LTRIM(RTRIM(ISNULL(Serie, ''''))) <> '''' ' +
    ' GROUP BY Empresa, Ejercicio, LTRIM(RTRIM(Serie))' +
    ') SELECT Empresa, Ejercicio, Serie FROM Series WHERE Posicion = 1 ' +
    'ORDER BY Empresa';
  cSelectTipos =
    'SELECT DISTINCT TIPO_DOC FROM (' +
    ' SELECT CODIGO_TIPO_DOCUMENTO_TD AS TIPO_DOC ' +
    ' FROM fza_tipos_documentos ' +
    ' WHERE TRIM(COALESCE(CODIGO_TIPO_DOCUMENTO_TD, '''')) <> '''' ' +
    ' UNION SELECT TIPO_DOC_CON FROM fza_contadores ' +
    ' WHERE TRIM(COALESCE(TIPO_DOC_CON, '''')) <> '''' ' +
    ' UNION SELECT TIPO_DOC_EMPSER FROM fza_empresas_series ' +
    ' WHERE TRIM(COALESCE(TIPO_DOC_EMPSER, '''')) <> '''' ' +
    ') Tipos ORDER BY TIPO_DOC';
  cSelectExiste =
    'SELECT 1 FROM fza_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :emp AND TIPO_DOC_EMPSER = :tipo ' +
    '  AND EMPSER = :serie ' +
    '  AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ' +
    '  AND IFNULL(CODIGO_CAJA_EMPSER, '''') = '''' ' +
    '  AND IFNULL(SUBTIPO_EMPSER, '''') = :subtipo ' +
    '  AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= :hasta) ' +
    '  AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= :desde) ' +
    'LIMIT 1';
  cInsert =
    'INSERT INTO fza_empresas_series ' +
    '  (CODIGO_SERIE_EMPSER, CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER, ' +
    '   CODIGO_CAJA_EMPSER, EMPSER, TIPO_DOC_EMPSER, SUBTIPO_EMPSER, ' +
    '   FECHA_DESDE_EMPSER, FECHA_HASTA_EMPSER, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :emp, NULL, NULL, :serie, :tipo, ' +
    '        NULLIF(:subtipo, ''''), :desde, :hasta, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qTipos, qExiste, qIns, qContador: TUniQuery;
  oTipos: TStringList;
  sSerieBase, sSerie, sEmp, sTipo, sSubtipo, sCodigo: string;
  dtDesde, dtHasta: TDateTime;
  iEjercicio, iTipo, iTotalEmpresa, iDigitos: Integer;
  iSiguienteCodigo: Int64;

  procedure PrepararContadorSeries;
  begin
    qContador.SQL.Text :=
      'SELECT CON, NUM_DIGITOS_CON FROM fza_contadores ' +
      'WHERE TIPO_DOC_CON = ''ES'' AND EMPRESA_CON = ''-'' ' +
      '  AND DEFAULT_CON = ''S'' LIMIT 1 FOR UPDATE';
    qContador.Open;
    if qContador.IsEmpty then
    begin
      qContador.Close;
      qContador.SQL.Text :=
        'INSERT INTO fza_contadores ' +
        '(TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
        ' ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, INSTANTE_MODIF, ' +
        ' USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (''ES'', ''-'', ''-'', 1, 3, ''S'', ''S'', NOW(), NOW(), ' +
        '        :usuario, :usuario)';
      qContador.ParamByName('usuario').AsString := Eng.Usuario;
      qContador.ExecSQL;
      iSiguienteCodigo := 1;
      iDigitos := 3;
    end
    else
    begin
      iSiguienteCodigo := qContador.FieldByName('CON').AsLargeInt;
      iDigitos := qContador.FieldByName('NUM_DIGITOS_CON').AsInteger;
      qContador.Close;
    end;
    qContador.SQL.Text :=
      'SELECT COALESCE(MAX(CASE ' +
      ' WHEN CODIGO_SERIE_EMPSER REGEXP ''^[0-9]+$'' ' +
      ' THEN CAST(CODIGO_SERIE_EMPSER AS UNSIGNED) END), 0) + 1 AS SIG ' +
      'FROM fza_empresas_series';
    qContador.Open;
    if qContador.FieldByName('SIG').AsLargeInt > iSiguienteCodigo then
      iSiguienteCodigo := qContador.FieldByName('SIG').AsLargeInt;
    qContador.Close;
    if iDigitos < 3 then
      iDigitos := 3;
  end;

  procedure GuardarContadorSeries;
  begin
    qContador.SQL.Text :=
      'UPDATE fza_contadores SET CON = :contador, USUARIO_MODIF = :usuario ' +
      'WHERE TIPO_DOC_CON = ''ES'' AND EMPRESA_CON = ''-'' ' +
      '  AND DEFAULT_CON = ''S''';
    qContador.ParamByName('contador').AsLargeInt := iSiguienteCodigo;
    qContador.ParamByName('usuario').AsString := Eng.Usuario;
    qContador.ExecSQL;
  end;

  function ObtenerCodigoSerie: string;
  begin
    Result := Format('%.*d', [iDigitos, iSiguienteCodigo]);
    Inc(iSiguienteCodigo);
  end;

  procedure CrearSerieActual;
  begin
    Inc(Stats.Leidas);
    Eng.Progreso.Avanzar;
    qExiste.Close;
    qExiste.ParamByName('emp').AsString := sEmp;
    qExiste.ParamByName('tipo').AsString := sTipo;
    qExiste.ParamByName('serie').AsString := sSerie;
    qExiste.ParamByName('subtipo').AsString := sSubtipo;
    qExiste.ParamByName('desde').AsDateTime := dtDesde;
    qExiste.ParamByName('hasta').AsDateTime := dtHasta;
    qExiste.Open;
    if not qExiste.IsEmpty then
      Inc(Stats.Saltadas)
    else
    begin
      sCodigo := ObtenerCodigoSerie;
      qIns.ParamByName('cod').AsString := Copy(sCodigo, 1, 10);
      qIns.ParamByName('emp').AsString := Copy(sEmp, 1, 10);
      qIns.ParamByName('serie').AsString := Copy(sSerie, 1, 12);
      qIns.ParamByName('tipo').AsString := Copy(sTipo, 1, 2);
      qIns.ParamByName('subtipo').AsString := Copy(sSubtipo, 1, 20);
      qIns.ParamByName('desde').AsDateTime := dtDesde;
      qIns.ParamByName('hasta').AsDateTime := dtHasta;
      RellenarAuditoria(qIns, Eng.Usuario);
      qIns.ExecSQL;
      Inc(Stats.Insertadas);
    end;
    qExiste.Close;
  end;
begin
  qSrc := NuevoQOrigen(Eng, cSelectActual);
  qTipos := TUniQuery.Create(nil);
  qExiste := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  qContador := TUniQuery.Create(nil);
  oTipos := TStringList.Create;
  try
    qTipos.Connection := Eng.Datos.ConexionDestino;
    qTipos.SQL.Text := cSelectTipos;
    qExiste.Connection := Eng.Datos.ConexionDestino;
    qExiste.SQL.Text := cSelectExiste;
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text := cInsert;
    qContador.Connection := Eng.Datos.ConexionDestino;
    qTipos.Open;
    while not qTipos.Eof do
    begin
      oTipos.Add(Trim(qTipos.FieldByName('TIPO_DOC').AsString));
      qTipos.Next;
    end;
    qTipos.Close;
    qSrc.Open;
    qSrc.Last;
    iTotalEmpresa := qSrc.RecordCount;
    qSrc.First;
    Eng.Progreso.EstablecerTotal(iTotalEmpresa * (oTipos.Count + 3));
    PrepararContadorSeries;
    while not qSrc.Eof do
    begin
      sEmp := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
      iEjercicio := qSrc.FieldByName('Ejercicio').AsInteger;
      sSerieBase := Trim(qSrc.FieldByName('Serie').AsString);
      dtDesde := EncodeDate(iEjercicio, 1, 1);
      dtHasta := EncodeDate(iEjercicio, 12, 31);
      for iTipo := 0 to oTipos.Count - 1 do
      begin
        sTipo := oTipos[iTipo];
        sSubtipo := '';
        sSerie := Format('%d.%s', [iEjercicio, sSerieBase]);
        CrearSerieActual;
        if sTipo = 'FC' then
        begin
          sSubtipo := 'NORMAL';
          sSerie := Format('%d.%sN', [iEjercicio, sSerieBase]);
          CrearSerieActual;
          sSubtipo := 'SIMPLIFICADA';
          sSerie := Format('%d.%s', [iEjercicio, sSerieBase]);
          CrearSerieActual;
          sSubtipo := 'RECTIFICATIVA';
          sSerie := Format('%d.%sR', [iEjercicio, sSerieBase]);
          CrearSerieActual;
        end;
      end;
      qSrc.Next;
    end;
    GuardarContadorSeries;
  finally
    oTipos.Free;
    qContador.Free;
    qIns.Free;
    qExiste.Free;
    qTipos.Free;
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
procedure LimpiarContadoresPrevios(Eng: IContextoMigracion);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    q.SQL.Text   := 'DELETE FROM fza_contadores WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure MigrarEntornoContadores(const Eng: IContextoMigracion; var Stats: TMigStats);
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
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   := cInsert;
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM (SELECT TipoDoc, Empresa, Ejercicio, Serie ' +
      'FROM dbo.occtador WHERE LTRIM(RTRIM(Serie)) <> '''' ' +
      '  AND LTRIM(RTRIM(TipoDoc)) <> '''' ' +
      'GROUP BY TipoDoc, Empresa, Ejercicio, Serie) t'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
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
            Eng.Registro.LogError('contador', sTipo + '/' + sSerieCon, E.Message,
              '', '');
          end;
        end;
      end;
      qSrc.Next;
    end;
    if oOmitidos.Count > 0 then
      Eng.Registro.Log('  contadores: %d tipos legacy omitidos (fuera de catalogo): %s',
              [oOmitidos.Count, oOmitidos.CommaText]);
  finally
    qIns.Free;
    qSrc.Free;
    oOmitidos.Free;
  end;
end;

// Recalcula el siguiente numero desde los documentos ya importados. Nunca
// reduce un contador existente: permite repetir el ajuste sin pisar numeros
// que la aplicacion haya reservado despues de la migracion.
procedure AjustarContadoresDestino(Eng: IContextoMigracion);
var
  q: TUniQuery;

  procedure AjustarContadorDocumentos(const sTipo, sTabla, sEmpresa,
    sSerie, sNumero: string; const iDigitos: Integer);
  begin
    q.SQL.Text := Format(
      'INSERT INTO fza_contadores (' +
      ' TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
      ' ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, INSTANTE_MODIF, ' +
      ' USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :tipo, TRIM(%s), TRIM(%s), ' +
      '       MAX(CAST(TRIM(%s) AS UNSIGNED)) + 1, ' +
      '       GREATEST(:digitos, MAX(CHAR_LENGTH(TRIM(%s)))), ' +
      '       ''S'', ''N'', NOW(), NOW(), :usuario, :usuario ' +
      '  FROM %s ' +
      ' WHERE TRIM(COALESCE(%s, '''')) <> '''' ' +
      '   AND TRIM(COALESCE(%s, '''')) <> '''' ' +
      '   AND TRIM(COALESCE(%s, '''')) REGEXP ''^[0-9]+$'' ' +
      ' GROUP BY TRIM(%s), TRIM(%s) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' CON = GREATEST(CON, VALUES(CON)), ' +
      ' NUM_DIGITOS_CON = GREATEST(NUM_DIGITOS_CON, ' +
      '                            VALUES(NUM_DIGITOS_CON)), ' +
      ' ESACTIVO_CON = ''S'', INSTANTE_MODIF = NOW(), ' +
      ' USUARIO_MODIF = VALUES(USUARIO_MODIF)',
      [sEmpresa, sSerie, sNumero, sNumero, sTabla, sEmpresa, sSerie,
       sNumero, sEmpresa, sSerie]);
    q.ParamByName('tipo').AsString := sTipo;
    q.ParamByName('digitos').AsInteger := iDigitos;
    q.ParamByName('usuario').AsString := Eng.Usuario;
    q.ExecSQL;
  end;

  procedure AjustarContadorOperaciones;
  begin
    q.SQL.Text :=
      'INSERT INTO fza_contadores (' +
      ' TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
      ' ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, INSTANTE_MODIF, ' +
      ' USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT ''OV'', TRIM(CODIGO_EMP_OPCAJA), ''OV'', ' +
      '       MAX(CAST(TRIM(NUMERO_OPERACION_OPCAJA) AS UNSIGNED)) + 1, ' +
      '       GREATEST(8, MAX(CHAR_LENGTH(TRIM(NUMERO_OPERACION_OPCAJA)))), ' +
      '       ''S'', ''N'', NOW(), NOW(), :usuario, :usuario ' +
      '  FROM fza_caja_operaciones ' +
      ' WHERE TRIM(COALESCE(CODIGO_EMP_OPCAJA, '''')) <> '''' ' +
      '   AND TRIM(COALESCE(NUMERO_OPERACION_OPCAJA, '''')) ' +
      '       REGEXP ''^[0-9]+$'' ' +
      ' GROUP BY TRIM(CODIGO_EMP_OPCAJA) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' CON = GREATEST(CON, VALUES(CON)), ' +
      ' NUM_DIGITOS_CON = GREATEST(NUM_DIGITOS_CON, ' +
      '                            VALUES(NUM_DIGITOS_CON)), ' +
      ' ESACTIVO_CON = ''S'', INSTANTE_MODIF = NOW(), ' +
      ' USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    q.ParamByName('usuario').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text :=
      'UPDATE fza_contadores c ' +
      'JOIN (SELECT TRIM(CODIGO_EMP_OPCAJA) AS EMPRESA, ' +
      '             MAX(CAST(TRIM(NUMERO_OPERACION_OPCAJA) AS UNSIGNED)) + 1 ' +
      '               AS SIGUIENTE ' +
      '        FROM fza_caja_operaciones ' +
      '       WHERE TRIM(COALESCE(CODIGO_EMP_OPCAJA, '''')) <> '''' ' +
      '         AND TRIM(COALESCE(NUMERO_OPERACION_OPCAJA, '''')) ' +
      '             REGEXP ''^[0-9]+$'' ' +
      '       GROUP BY TRIM(CODIGO_EMP_OPCAJA)) o ' +
      '  ON o.EMPRESA = c.EMPRESA_CON ' +
      ' SET c.CON = GREATEST(c.CON, o.SIGUIENTE), ' +
      '     c.NUM_DIGITOS_CON = GREATEST(c.NUM_DIGITOS_CON, 8), ' +
      '     c.INSTANTE_MODIF = NOW(), c.USUARIO_MODIF = :usuario ' +
      'WHERE c.TIPO_DOC_CON = ''OV''';
    q.ParamByName('usuario').AsString := Eng.Usuario;
    q.ExecSQL;
  end;

  procedure AjustarContadorGlobal(const sTipo, sTabla, sNumero: string;
    const iDigitos: Integer);
  begin
    q.SQL.Text := Format(
      'INSERT INTO fza_contadores (' +
      ' TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
      ' ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, INSTANTE_MODIF, ' +
      ' USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :tipo, ''-'', ''-'', ' +
      '       MAX(CAST(TRIM(%s) AS UNSIGNED)) + 1, ' +
      '       GREATEST(:digitos, MAX(CHAR_LENGTH(TRIM(%s)))), ' +
      '       ''S'', ''S'', NOW(), NOW(), :usuario, :usuario ' +
      '  FROM %s ' +
      ' WHERE TRIM(COALESCE(%s, '''')) REGEXP ''^[0-9]+$'' ' +
      'HAVING COUNT(*) > 0 ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' CON = GREATEST(CON, VALUES(CON)), ' +
      ' NUM_DIGITOS_CON = GREATEST(NUM_DIGITOS_CON, ' +
      '                            VALUES(NUM_DIGITOS_CON)), ' +
      ' ESACTIVO_CON = ''S'', DEFAULT_CON = ''S'', ' +
      ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = VALUES(USUARIO_MODIF)',
      [sNumero, sNumero, sTabla, sNumero]);
    q.ParamByName('tipo').AsString := sTipo;
    q.ParamByName('digitos').AsInteger := iDigitos;
    q.ParamByName('usuario').AsString := Eng.Usuario;
    q.ExecSQL;
  end;

begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.Datos.ConexionDestino;
    AjustarContadorOperaciones;
    AjustarContadorDocumentos('FC', 'fza_facturas', 'CODIGO_EMP_FAC',
      'SERIE_FAC', 'NUMERO_FAC', 6);
    AjustarContadorDocumentos('PE', 'fza_pedidos', 'CODIGO_EMP_PED',
      'SERIE_PED', 'NUMERO_PED', 6);
    AjustarContadorDocumentos('AV', 'fza_albaranes', 'CODIGO_EMP_ALB',
      'SERIE_ALB', 'NUMERO_ALB', 6);
    AjustarContadorDocumentos('PC', 'fza_pedidos_compra', 'CODIGO_EMP_PEDC',
      'SERIE_PEDC', 'NUMERO_PEDC', 6);
    AjustarContadorDocumentos('AB', 'fza_albaranes_compra', 'CODIGO_EMP_ALBC',
      'SERIE_ALBC', 'NUMERO_ALBC', 6);
    AjustarContadorDocumentos('DC', 'fza_devoluciones_compra',
      'CODIGO_EMP_DEVC', 'SERIE_DEVC', 'NUMERO_DEVC', 6);
    AjustarContadorDocumentos('FP', 'fza_facturas_compra', 'CODIGO_EMP_FACC',
      'SERIE_FACC', 'NUMERO_FACC', 6);
    AjustarContadorDocumentos('IN', 'fza_inventarios', 'CODIGO_EMP_INV',
      'SERIE_INV', 'NUMERO_INV', 6);
    AjustarContadorGlobal('CL', 'fza_clientes', 'CODIGO_CLI_CLI', 3);
    AjustarContadorGlobal('CO', 'fza_clientes', 'ORDEN_CLI', 3);
    AjustarContadorGlobal('PV', 'fza_proveedores', 'CODIGO_PRV_PRV', 3);
    AjustarContadorGlobal('PO', 'fza_proveedores', 'ORDEN_PRV', 3);
    AjustarContadorGlobal('EM', 'fza_empresas', 'CODIGO_EMP_EMP', 3);
    AjustarContadorGlobal('EO', 'fza_empresas', 'ORDEN_EMP', 3);
    Eng.Registro.Log('  contadores ajustados desde los documentos ya importados.');
  finally
    q.Free;
  end;
end;

procedure MigrarAjusteContadores(const Eng: IContextoMigracion; var Stats: TMigStats);
begin
  Eng.Progreso.EstablecerTotal(1);
  AjustarContadoresDestino(Eng);
  Inc(Stats.Leidas);
  Inc(Stats.Insertadas);
  Eng.Progreso.Avanzar;
end;

// =========================================================================
//  4. Contador por familia  (dbo.ocnivnro → fza_articulos_familias)
// =========================================================================

procedure MigrarEntornoContadoresFamilia(const Eng: IContextoMigracion;
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
    qUpd.Connection := Eng.Datos.ConexionDestino;
    qUpd.SQL.Text   := cUpdate;
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM (SELECT DISTINCT LTRIM(RTRIM(Codigo)) AS C ' +
      'FROM dbo.ocnivnro WHERE LTRIM(RTRIM(Codigo)) <> '''') t'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
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
          Eng.Registro.LogError('contador_familia', sCod, E.Message, '',
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

initialization
  RegistrarMigracion(
    'entorno_contadores',
    'Contadores (occtador)',
    'dbo.occtador -> fza_contadores',
    ['empresas'],
    MigrarEntornoContadores);
  RegistrarMigracion(
    'ajuste_contadores',
    'Ajustar contadores desde datos importados',
    'tablas MariaDB importadas -> fza_contadores',
    ['enlace_mov_facturas'],
    MigrarAjusteContadores);
  RegistrarMigracion(
    'entorno_contadores_familia',
    'Contador por familia (ocnivnro)',
    'dbo.ocnivnro -> fza_articulos_familias.CONTADOR_ART_FAM',
    ['familias'],
    MigrarEntornoContadoresFamilia);
  RegistrarMigracion(
    'entorno_cajas',
    'Cajas de almacen (occajas)',
    'dbo.occajas -> fza_almacenes_cajas',
    ['almacenes'],
    MigrarEntornoCajas);
  RegistrarMigracion(
    'entorno_series',
    'Series actuales por empresa',
    'occtador + tipos Factuzam -> fza_empresas_series',
    ['empresas', 'entorno_contadores'],
    MigrarEntornoSeries);

end.
