{******************************************************************************}
{                                                                              }
{  Modulo:       inLibMigEfectosCompra                                         }
{    Tipo:       Libreria de migracion (sin formulario)                        }
{ Version:       1.0.0                                                         }
{                                                                              }
{  Descripcion:                                                                }
{    Importa cuentas de cargo, tipos de efecto, efectos de pago conciliados y  }
{    remesas de proveedores desde SQL Server a MariaDB.                        }
{                                                                              }
{    Origen legacy:                                                            }
{      dbo.ocbanrem  -> fza_empresas_bancos (por uso real en compras)          }
{      dbo.octipefe  -> fza_tipos_efecto                                       }
{      dbo.ocefepro  -> fza_efectos_compra                                     }
{      dbo.occobpro  -> agregado sobre fza_efectos_compra                      }
{      dbo.ocrempro  -> fza_remesas_compra                                     }
{                                                                              }
{    Claves documentales: misma convencion que facturas de compra.             }
{      SERIE  = '<Ejercicio>.<Serie>'                                          }
{      NUMERO = NroDoc/NroRemesa a 6 digitos                                   }
{******************************************************************************}
unit inLibMigEfectosCompra;

interface

uses
  UMigEngine;

procedure MigrarBancosEmpresa(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarTiposEfectoCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarEfectosCompra(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarRemesasCompra(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

const
  BATCH = 2000;

var
  fsEfectos: TFormatSettings;

function F(v: Double): string;
begin
  Result := FloatToStr(v, fsEfectos);
end;

function UnirValores(const aValores: array of string): string;
var
  i: Integer;
begin
  Result := '';
  for i := Low(aValores) to High(aValores) do
  begin
    if i > Low(aValores) then
      Result := Result + ', ';
    Result := Result + aValores[i];
  end;
end;

function FechaCampoASQL(q: TUniQuery; const sCampo: string): string;
begin
  Result := 'NULL';
  if (q.FindField(sCampo) <> nil) and not q.FieldByName(sCampo).IsNull then
    Result := DateTimeASQL(Trunc(q.FieldByName(sCampo).AsDateTime));
end;

function FechaHoraCampoASQL(q: TUniQuery; const sCampo: string): string;
begin
  Result := 'NULL';
  if (q.FindField(sCampo) <> nil) and not q.FieldByName(sCampo).IsNull then
    Result := DateTimeASQL(q.FieldByName(sCampo).AsDateTime);
end;

function TextoCampo(q: TUniQuery; const sCampo: string;
                    iLongitud: Integer): string;
begin
  Result := '';
  if q.FindField(sCampo) <> nil then
    Result := Trim(q.FieldByName(sCampo).AsString);
  if iLongitud > 0 then
    Result := Copy(Result, 1, iLongitud);
end;

function SerieDocumento(iEjercicio: Integer; const sSerie: string): string;
begin
  Result := Format('%d.%s', [iEjercicio, Trim(sSerie)]);
end;

function NumeroDocumento(iNumero: Integer): string;
begin
  Result := Format('%.6d', [iNumero]);
end;

function CodigoTipoEfecto(iTipo: Integer): string;
begin
  Result := '';
  if iTipo > 0 then
    Result := IntToStr(iTipo);
end;

function SoloLetrasNumeros(const sValor: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(sValor) do
  begin
    c := UpCase(sValor[i]);
    if CharInSet(c, ['A'..'Z']) or CharInSet(c, ['0'..'9']) then
      Result := Result + c;
  end;
end;

function CodigoBancoEmpresa(iEmpresa: Integer;
                            const sCuentaBanco: string): string;
var
  sCuenta: string;
  sEmpresa: string;
  iInicio: Integer;
begin
  Result := '';
  sCuenta := SoloLetrasNumeros(Trim(sCuentaBanco));
  if sCuenta <> '' then
  begin
    sEmpresa := Copy(Format('%.3d', [iEmpresa]), 1, 3);
    iInicio := Length(sCuenta) - 4;
    if iInicio < 1 then
      iInicio := 1;
    Result := sEmpresa + Copy(sCuenta, iInicio, 5);
    Result := Copy(Result, 1, 8);
  end;
end;

function EstadoBanco(const sEstado: string): string;
begin
  if UpperCase(Trim(sEstado)) = 'B' then
    Result := 'N'
  else
    Result := 'S';
end;

function EsTextoContado(const sDescripcion: string): Boolean;
var
  s: string;
begin
  s := UpperCase(Trim(sDescripcion));
  Result := (Pos('CONTADO', s) > 0) or
            (Pos('EFECTIVO', s) > 0) or
            (Pos('CAJA', s) > 0);
end;

function EsTextoDomiciliado(const sDescripcion: string): Boolean;
var
  s: string;
begin
  s := UpperCase(Trim(sDescripcion));
  Result := (Pos('RECIB', s) > 0) or
            (Pos('DOMIC', s) > 0) or
            (Pos('CONFIRM', s) > 0);
end;

function CodigoFormaPagoTexto(const sValor: string): string;
begin
  Result := Copy(Trim(sValor), 1, 20);
end;

function EsTextoBancoEmpresa(const sDescripcion: string): Boolean;
var
  s: string;
begin
  s := UpperCase(Trim(sDescripcion));
  Result := EsTextoDomiciliado(s) or
            (Pos('TRANSFER', s) > 0) or
            (Pos('GIRO', s) > 0) or
            (Pos('LETRA', s) > 0) or
            (Pos('PAGAR', s) > 0) or
            (Pos('TAL', s) > 0);
end;

function PlazosFormaPago(const sDescripcion: string): Integer;
var
  s: string;
begin
  s := UpperCase(Trim(sDescripcion));
  Result := 1;
  if (Pos('30', s) > 0) and (Pos('60', s) > 0) and
     (Pos('90', s) > 0) then
    Result := 3
  else if (Pos('30', s) > 0) and (Pos('60', s) > 0) then
    Result := 2;
end;

function DiasFormaPago(const sDescripcion: string): Integer;
var
  s: string;
begin
  s := UpperCase(Trim(sDescripcion));
  Result := 0;
  if Pos('30', s) > 0 then
    Result := 30
  else if Pos('60', s) > 0 then
    Result := 60
  else if Pos('90', s) > 0 then
    Result := 90;
end;

function EstadoEfecto(q: TUniQuery): string;
var
  fPendiente: Double;
  bRemesado: Boolean;
begin
  fPendiente := q.FieldByName('ImpPendiente').AsFloat;
  bRemesado := q.FieldByName('NroRemesa').AsInteger > 0;
  if (fPendiente <= 0.0001) or not q.FieldByName('FechaPago').IsNull then
    Result := 'PAGADO'
  else if bRemesado then
    Result := 'REMESADO'
  else
    Result := 'PENDIENTE';
end;

function EstadoRemesa(q: TUniQuery): string;
begin
  if not q.FieldByName('InstanteConta').IsNull then
    Result := 'CERRADA'
  else if not q.FieldByName('FechaCargo').IsNull then
    Result := 'PAGADA'
  else
    Result := 'ABIERTA';
end;

function TipoRemesa(q: TUniQuery): string;
var
  sNorma: string;
  sTipo: string;
begin
  sNorma := UpperCase(TextoCampo(q, 'Norma', 10));
  sTipo := UpperCase(TextoCampo(q, 'Tipo', 20));
  if sNorma <> '' then
    Result := 'NORMA' + sNorma
  else if sTipo <> '' then
    Result := sTipo
  else
    Result := 'NORMA34';
  Result := Copy(Result, 1, 20);
end;

procedure BorrarPorUsuario(Eng: TMigEngine; const sTabla: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := 'DELETE FROM ' + sTabla + ' WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

function ColumnaDestinoExiste(Eng: TMigEngine; const sTabla,
  sColumna: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = :tabla ' +
      'AND COLUMN_NAME = :columna';
    q.ParamByName('tabla').AsString := sTabla;
    q.ParamByName('columna').AsString := sColumna;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    q.Free;
  end;
end;

procedure AsegurarColumnaDestino(Eng: TMigEngine; const sTabla,
  sColumna, sAlter: string);
begin
  if not ColumnaDestinoExiste(Eng, sTabla, sColumna) then
    Eng.ConDst.ExecSQL(sAlter);
end;

procedure AsegurarEsquemaEfectosCompra(Eng: TMigEngine);
begin
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra', 'TIPO_PAGO_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `TIPO_PAGO_EFEC` varchar(50) NULL DEFAULT NULL ' +
    'AFTER `FECHA_PAGO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'REFERENCIA_PAGO_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `REFERENCIA_PAGO_EFEC` varchar(100) NULL DEFAULT NULL ' +
    'AFTER `TIPO_PAGO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'ENTIDAD_PAGO_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `ENTIDAD_PAGO_EFEC` varchar(100) NULL DEFAULT NULL ' +
    'AFTER `REFERENCIA_PAGO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra', 'ESCONCILIADO_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `ESCONCILIADO_EFEC` varchar(1) NULL DEFAULT ''N'' ' +
    'AFTER `ENTIDAD_PAGO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra', 'CODIGO_EMPBAN_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `CODIGO_EMPBAN_EFEC` varchar(8) NULL DEFAULT NULL ' +
    'AFTER `IBAN_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra', 'IBAN_EMP_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `IBAN_EMP_EFEC` varchar(34) NULL DEFAULT NULL ' +
    'AFTER `CODIGO_EMPBAN_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'REFERENCIA_DOCUMENTO_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `REFERENCIA_DOCUMENTO_EFEC` varchar(100) ' +
    'NULL DEFAULT NULL AFTER `DOC_EXTERNO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'SERIE_FACC_CONCILIACION_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `SERIE_FACC_CONCILIACION_EFEC` varchar(20) ' +
    'NULL DEFAULT NULL AFTER `REFERENCIA_DOCUMENTO_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'NUMERO_FACC_CONCILIACION_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `NUMERO_FACC_CONCILIACION_EFEC` varchar(20) ' +
    'NULL DEFAULT NULL AFTER `SERIE_FACC_CONCILIACION_EFEC`');
  AsegurarColumnaDestino(Eng, 'fza_efectos_compra',
    'NUMERO_EFEC_CONCILIACION_EFEC',
    'ALTER TABLE `fza_efectos_compra` ' +
    'ADD COLUMN `NUMERO_EFEC_CONCILIACION_EFEC` int(11) ' +
    'NULL DEFAULT NULL AFTER `NUMERO_FACC_CONCILIACION_EFEC`');
end;

procedure InsertarFormaPagoLegacy(qIns: TUniQuery; const sCodigo,
  sDescripcion, sUsuario: string; iOrden: Integer);
var
  sCod: string;
  sDesc: string;
begin
  sCod := CodigoFormaPagoTexto(sCodigo);
  sDesc := Copy(Trim(sDescripcion), 1, 100);
  if (sCod <> '') and (sDesc <> '') then
  begin
    qIns.ParamByName('cod').AsString := sCod;
    qIns.ParamByName('des').AsString := sDesc;
    qIns.ParamByName('orden').AsInteger := iOrden;
    qIns.ParamByName('plazos').AsInteger := PlazosFormaPago(sDesc);
    qIns.ParamByName('dias').AsInteger := DiasFormaPago(sDesc);
    if EsTextoContado(sDesc) then
      qIns.ParamByName('anticipo').AsInteger := 100
    else
      qIns.ParamByName('anticipo').AsInteger := 0;
    if EsTextoBancoEmpresa(sDesc) then
      qIns.ParamByName('banco').AsString := 'S'
    else
      qIns.ParamByName('banco').AsString := 'N';
    if EsTextoContado(sDesc) then
      qIns.ParamByName('contado').AsString := 'S'
    else
      qIns.ParamByName('contado').AsString := 'N';
    qIns.ParamByName('u').AsString := sUsuario;
    qIns.ExecSQL;
  end;
end;

procedure AsegurarFormasPagoLegacy(Eng: TMigEngine);
const
  cSqlIns =
    'INSERT INTO fza_formas_pago (CODIGO_FP_FP, ESACTIVO_FORMA_PAGO_FP, ' +
    'ORDEN_FORMA_PAGO_FP, DESCRIPCION_FORMA_PAGO_FP, ' +
    'N_PLAZOS_FORMA_PAGO_FP, N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP, ' +
    'PORCENTAJE_ANTICIPO_FORMA_PAGO_FP, ESVERBANCOEMPRESA_FORMA_PAGO_FP, ' +
    'CODIGO_FACTURAE_FP, ESCONTADO_FORMA_PAGO_FP, ESDEFAULT_FORMA_PAGO_FP, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, ''S'', :orden, :des, :plazos, :dias, :anticipo, ' +
    ':banco, ''01'', :contado, ''N'', NOW(), NOW(), :u, :u) ' +
    'ON DUPLICATE KEY UPDATE ESACTIVO_FORMA_PAGO_FP = ''S'', ' +
    'DESCRIPCION_FORMA_PAGO_FP = IF(USUARIO_ALTA = VALUES(USUARIO_ALTA) ' +
    'OR TRIM(COALESCE(DESCRIPCION_FORMA_PAGO_FP, '''')) = '''', ' +
    'VALUES(DESCRIPCION_FORMA_PAGO_FP), DESCRIPCION_FORMA_PAGO_FP), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  cSqlTipos =
    'SELECT Codigo, COALESCE(MAX(NULLIF(FormaPago, '''')), ' +
    '       MAX(Descripcion)) AS Descripcion FROM ( ' +
    'SELECT TipoEfecto AS Codigo, Descripcion, ' +
    '       CAST('''' AS varchar(100)) AS FormaPago ' +
    'FROM dbo.octipefe WHERE TipoEfecto > 0 ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.occli WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocpro WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocped WHERE TipoDoc = ''PP'' AND ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocalbpro WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocfacpro WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocpedcli WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocalbcli WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT TipoEfecto, CAST('''' AS varchar(100)), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocfaccli WHERE ISNULL(TipoEfecto, 0) > 0 ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    ') x GROUP BY Codigo ORDER BY Codigo';
  cSqlTextos =
    'SELECT Codigo, MAX(Descripcion) AS Descripcion FROM ( ' +
    'SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20) AS Codigo, ' +
    '       LTRIM(RTRIM(FormaPago)) AS Descripcion ' +
    'FROM dbo.occli WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocpro WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocped WHERE TipoDoc = ''PP'' ' +
    '  AND LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocalbpro WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocfacpro WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocpedcli WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocalbcli WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    'UNION ALL SELECT LEFT(LTRIM(RTRIM(FormaPago)), 20), ' +
    '       LTRIM(RTRIM(FormaPago)) ' +
    'FROM dbo.ocfaccli WHERE LTRIM(RTRIM(ISNULL(FormaPago, ''''))) <> '''' ' +
    ') x GROUP BY Codigo ORDER BY Codigo';
var
  qSrc: TUniQuery;
  qIns: TUniQuery;
  iProcesadas: Integer;
begin
  iProcesadas := 0;
  qSrc := nil;
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text := cSqlIns;
    qSrc := NuevoQOrigen(Eng, cSqlTipos);
    try
      qSrc.Open;
      while not qSrc.Eof do
      begin
        InsertarFormaPagoLegacy(qIns, qSrc.FieldByName('Codigo').AsString,
          qSrc.FieldByName('Descripcion').AsString, Eng.Usuario,
          qSrc.FieldByName('Codigo').AsInteger);
        Inc(iProcesadas);
        qSrc.Next;
      end;
    finally
      qSrc.Free;
    end;
    qSrc := NuevoQOrigen(Eng, cSqlTextos);
    try
      qSrc.Open;
      while not qSrc.Eof do
      begin
        InsertarFormaPagoLegacy(qIns, qSrc.FieldByName('Codigo').AsString,
          qSrc.FieldByName('Descripcion').AsString, Eng.Usuario,
          100 + iProcesadas);
        Inc(iProcesadas);
        qSrc.Next;
      end;
    finally
      qSrc.Free;
    end;
    Eng.Log('  formas pago documentos: catalogo legacy asegurado.');
  finally
    qIns.Free;
  end;
end;

procedure RecalcularRemesasDesdeEfectos(Eng: TMigEngine);
var
  sUser: string;
begin
  sUser := ValorOrNull(Eng.Usuario);
  Eng.ConDst.ExecSQL(
    'UPDATE fza_remesas_compra r ' +
    'LEFT JOIN ( ' +
    '  SELECT SERIE_REMC_EFEC, NUMERO_REMC_EFEC, ' +
    '         COUNT(*) AS NumEfectos, SUM(IMPORTE_EFEC) AS Total ' +
    '  FROM fza_efectos_compra ' +
    '  WHERE USUARIO_ALTA = ' + sUser + ' ' +
    '    AND SERIE_REMC_EFEC IS NOT NULL ' +
    '    AND NUMERO_REMC_EFEC IS NOT NULL ' +
    '  GROUP BY SERIE_REMC_EFEC, NUMERO_REMC_EFEC ' +
    ') e ON e.SERIE_REMC_EFEC = r.SERIE_REMC ' +
    '   AND e.NUMERO_REMC_EFEC = r.NUMERO_REMC ' +
    'SET r.CONTADOR_EFECTOS_REMC = ' +
    '      COALESCE(e.NumEfectos, r.CONTADOR_EFECTOS_REMC), ' +
    '    r.TOTAL_REMC = COALESCE(e.Total, r.TOTAL_REMC) ' +
    'WHERE r.USUARIO_ALTA = ' + sUser);
end;

procedure MigrarBancosEmpresa(Eng: TMigEngine; var Stats: TMigStats);
const
  cSel =
    'SELECT y.Empresa, y.CuentaBanco, y.OrdenCuenta, ' +
    '       ISNULL(br.Entidad, '''') AS Entidad, ' +
    '       ISNULL(br.Oficina, '''') AS Oficina, ' +
    '       ISNULL(br.DigitosControl, '''') AS DigitosControl, ' +
    '       ISNULL(br.NroCuenta, '''') AS NroCuenta, ' +
    '       ISNULL(br.IBAN, '''') AS IBAN, ' +
    '       ISNULL(br.Nombre, '''') AS Nombre, ' +
    '       ISNULL(br.Estado, '''') AS Estado ' +
    'FROM ( ' +
    '  SELECT x.Empresa, x.CuentaBanco, ' +
    '         ROW_NUMBER() OVER (PARTITION BY x.Empresa ' +
    '           ORDER BY x.CuentaBanco) AS OrdenCuenta ' +
    '  FROM ( ' +
    '    SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '    FROM dbo.ocfacpro ' +
    '    WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    '    UNION ' +
    '    SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '    FROM dbo.ocefepro ' +
    '    WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    '    UNION ' +
    '    SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '    FROM dbo.ocrempro ' +
    '    WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    '  ) x ' +
    ') y ' +
    'LEFT JOIN dbo.ocbanrem br ON br.CuentaBanco = y.CuentaBanco';
  cCount =
    'SELECT COUNT(*) FROM ( ' +
    '  SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '  FROM dbo.ocfacpro ' +
    '  WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    '  UNION ' +
    '  SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '  FROM dbo.ocefepro ' +
    '  WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    '  UNION ' +
    '  SELECT DISTINCT Empresa, LTRIM(RTRIM(CuentaBanco)) AS CuentaBanco ' +
    '  FROM dbo.ocrempro ' +
    '  WHERE LTRIM(RTRIM(ISNULL(CuentaBanco, ''''))) <> '''' ' +
    ') x';
  cCols =
    'CODIGO_EMPBAN, CODIGO_EMP_EMPBAN, NOMBRE_EMPBAN, CODIGO_BAN_EMPBAN, ' +
    'IBAN_EMPBAN, ENTIDAD_EMPBAN, OFICINA_EMPBAN, DIGITO_CONTROL_EMPBAN, ' +
    'CUENTA_EMPBAN, BIC_EMPBAN, ESDEFECTO_COBRO_EMPBAN, ' +
    'ESDEFECTO_PAGO_EMPBAN, ESACTIVO_EMPBAN, ORDEN_EMPBAN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  q: TUniQuery;
  b: TBulkInsert;
  sAhora: string;
  sUser: string;
  sCodigo: string;
  sNombre: string;
  sEsDefectoPago: string;
begin
  BorrarPorUsuario(Eng, 'fza_empresas_bancos');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  q := NuevoQOrigen(Eng, cSel);
  q.UniDirectional := True;
  b := TBulkInsert.Create(Eng.ConDst, 'fza_empresas_bancos', cCols, BATCH);
  try
    Eng.Log('  bancos empresa: cuentas de cargo usadas en compras...');
    Eng.SetTotal(Eng.ContarOrigen(cCount));
    q.Open;
    while not q.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCodigo := CodigoBancoEmpresa(q.FieldByName('Empresa').AsInteger,
                                    TextoCampo(q, 'CuentaBanco', 15));
      if sCodigo <> '' then
      begin
        sNombre := TextoCampo(q, 'Nombre', 100);
        if sNombre = '' then
          sNombre := 'Cuenta ' + TextoCampo(q, 'CuentaBanco', 15);
        if q.FieldByName('OrdenCuenta').AsInteger = 1 then
          sEsDefectoPago := 'S'
        else
          sEsDefectoPago := 'N';
        b.Add(UnirValores([
          ValorOrNull(sCodigo),
          ValorOrNull(IntToStr(q.FieldByName('Empresa').AsInteger)),
          ValorOrNull(sNombre),
          ValorOrNull(TextoCampo(q, 'Entidad', 4)),
          ValorOrNull(TextoCampo(q, 'IBAN', 34)),
          ValorOrNull(TextoCampo(q, 'Entidad', 4)),
          ValorOrNull(TextoCampo(q, 'Oficina', 4)),
          ValorOrNull(TextoCampo(q, 'DigitosControl', 2)),
          ValorOrNull(TextoCampo(q, 'NroCuenta', 10)),
          'NULL',
          ValorOrNull('N'),
          ValorOrNull(sEsDefectoPago),
          ValorOrNull(EstadoBanco(TextoCampo(q, 'Estado', 1))),
          IntToStr(q.FieldByName('OrdenCuenta').AsInteger),
          sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      end
      else
        Inc(Stats.Saltadas);
      q.Next;
    end;
    b.FlushPendiente;
  finally
    b.Free;
    q.Free;
  end;
  AsegurarFormasPagoLegacy(Eng);
end;

procedure MigrarTiposEfectoCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cSel =
    'SELECT TipoEfecto, Descripcion FROM dbo.octipefe';
  cCols =
    'CODIGO_TEFE, DESCRIPCION_TEFE, ESDOMICILIADO_TEFE, ' +
    'ESREMESABLE_TEFE, ORDEN_TEFE, ESACTIVO_TEFE, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  q: TUniQuery;
  b: TBulkInsert;
  sAhora: string;
  sUser: string;
  sDesc: string;
  sDomiciliado: string;
  sRemesable: string;
begin
  BorrarPorUsuario(Eng, 'fza_tipos_efecto');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  q := NuevoQOrigen(Eng, cSel);
  q.UniDirectional := True;
  b := TBulkInsert.Create(Eng.ConDst, 'fza_tipos_efecto', cCols, BATCH);
  try
    Eng.Log('  tipos efecto compra: catalogo octipefe...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.octipefe'));
    q.Open;
    while not q.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sDesc := TextoCampo(q, 'Descripcion', 100);
      if EsTextoContado(sDesc) then
      begin
        sDomiciliado := 'N';
        sRemesable := 'N';
      end
      else
      begin
        if EsTextoDomiciliado(sDesc) then
          sDomiciliado := 'S'
        else
          sDomiciliado := 'N';
        sRemesable := 'S';
      end;
      b.Add(UnirValores([
        ValorOrNull(IntToStr(q.FieldByName('TipoEfecto').AsInteger)),
        ValorOrNull(sDesc),
        ValorOrNull(sDomiciliado),
        ValorOrNull(sRemesable),
        IntToStr(q.FieldByName('TipoEfecto').AsInteger),
        ValorOrNull('S'),
        sAhora, sAhora, sUser, sUser]));
      Inc(Stats.Insertadas);
      q.Next;
    end;
    b.FlushPendiente;
  finally
    b.Free;
    q.Free;
  end;
end;

procedure MigrarEfectosCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelEfectos =
    'SELECT e.Empresa, e.Ejercicio, ISNULL(e.Serie, '''') AS Serie, ' +
    '       e.NroDoc, e.NroEfecto, ' +
    '       (SELECT MAX(e2.NroEfecto) FROM dbo.ocefepro e2 ' +
    '         WHERE e2.TipoDoc = ''FP'' AND e2.Empresa = e.Empresa ' +
    '           AND e2.Ejercicio = e.Ejercicio ' +
    '           AND ISNULL(e2.Serie, '''') = ISNULL(e.Serie, '''') ' +
    '           AND e2.NroDoc = e.NroDoc) AS MaxEfectoDoc, ' +
    '       ISNULL(e.Proveedor, 0) AS Proveedor, ' +
    '       ISNULL(f.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(f.NIF, '''') AS NIF, ' +
    '       ISNULL(e.TipoEfecto, ISNULL(f.TipoEfecto, 0)) AS TipoEfecto, ' +
    '       e.FechaEmision, e.FechaVto, e.FechaPago, p.FechaPagoCobro, ' +
    '       ISNULL(e.ImpEfecto, 0) AS ImpEfecto, ' +
    '       CASE WHEN e.ImpPendiente IS NULL THEN ISNULL(e.ImpEfecto, 0) ' +
    '            ELSE e.ImpPendiente END AS ImpPendiente, ' +
    '       ISNULL(e.EjercicioRem, 0) AS EjercicioRem, ' +
    '       ISNULL(e.SerieRem, '''') AS SerieRem, ' +
    '       ISNULL(e.NroRemesa, 0) AS NroRemesa, ' +
    '       ISNULL(e.Entidad, ISNULL(f.Entidad, '''')) AS Entidad, ' +
    '       ISNULL(e.Oficina, ISNULL(f.Oficina, '''')) AS Oficina, ' +
    '       ISNULL(e.DigitosControl, ISNULL(f.DigitosControl, '''')) ' +
    '         AS DigitosControl, ' +
    '       ISNULL(e.NroCuenta, ISNULL(f.NroCuenta, '''')) AS NroCuenta, ' +
    '       ISNULL(f.IBAN, '''') AS IBANProveedor, ' +
    '       ISNULL(e.CuentaBanco, ISNULL(f.CuentaBanco, '''')) AS CuentaBanco, ' +
    '       ISNULL(br.IBAN, '''') AS IBANEmpresa, ' +
    '       ISNULL(e.DocExterno, ISNULL(f.DocExterno, '''')) AS DocExterno, ' +
    '       ISNULL(p.TipoPago, 0) AS TipoPago, ' +
    '       ISNULL(p.DocumentoPago, '''') AS DocumentoPago, ' +
    '       ISNULL(p.CajaPago, 0) AS CajaPago, ' +
    '       CONVERT(varchar(1000), e.Observacion) AS Observacion ' +
    'FROM dbo.ocefepro e ' +
    'LEFT JOIN dbo.ocfacpro f ON f.Empresa = e.Empresa ' +
    '                         AND f.Ejercicio = e.Ejercicio ' +
    '                         AND f.Serie = e.Serie ' +
    '                         AND f.NroFactura = e.NroDoc ' +
    'LEFT JOIN dbo.ocbanrem br ON br.CuentaBanco = ' +
    '  ISNULL(e.CuentaBanco, ISNULL(f.CuentaBanco, '''')) ' +
    'LEFT JOIN ( ' +
    '  SELECT Empresa, Ejercicio, ISNULL(Serie, '''') AS Serie, NroDoc, ' +
    '         NroEfecto, MAX(FechaOpe) AS FechaPagoCobro, ' +
    '         MAX(ISNULL(TipoEfecto, 0)) AS TipoPago, ' +
    '         MAX(CONVERT(varchar(100), ISNULL(Documento, ''''))) ' +
    '           AS DocumentoPago, ' +
    '         MAX(ISNULL(Caja, 0)) AS CajaPago ' +
    '  FROM dbo.occobpro ' +
    '  WHERE TipoDoc = ''FP'' ' +
    '  GROUP BY Empresa, Ejercicio, ISNULL(Serie, ''''), NroDoc, NroEfecto ' +
    ') p ON p.Empresa = e.Empresa ' +
    '   AND p.Ejercicio = e.Ejercicio ' +
    '   AND p.Serie = ISNULL(e.Serie, '''') ' +
    '   AND p.NroDoc = e.NroDoc ' +
    '   AND p.NroEfecto = e.NroEfecto ' +
    'WHERE e.TipoDoc = ''FP'' ' +
    'ORDER BY e.Empresa, e.Ejercicio, ISNULL(e.Serie, ''''), ' +
    '         e.NroDoc, e.NroEfecto';
  cColsEfectos =
    'SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC, CODIGO_EMP_EFEC, ' +
    'CODIGO_PRV_EFEC, RAZON_SOCIAL_PRV_EFEC, NIF_PRV_EFEC, ' +
    'CODIGO_TEFE_EFEC, ESTADO_EFEC, ORDEN_PLAZO_EFEC, FECHA_EMISION_EFEC, ' +
    'FECHA_VENCIMIENTO_EFEC, FECHA_PAGO_EFEC, TIPO_PAGO_EFEC, ' +
    'REFERENCIA_PAGO_EFEC, ENTIDAD_PAGO_EFEC, ESCONCILIADO_EFEC, ' +
    'IMPORTE_EFEC, IMPORTE_PAGADO_EFEC, IMPORTE_PENDIENTE_EFEC, ' +
    'SERIE_REMC_EFEC, NUMERO_REMC_EFEC, ENTIDAD_EFEC, OFICINA_EFEC, ' +
    'DIGITO_CONTROL_EFEC, CUENTA_EFEC, IBAN_EFEC, CODIGO_EMPBAN_EFEC, ' +
    'IBAN_EMP_EFEC, DOC_EXTERNO_EFEC, REFERENCIA_DOCUMENTO_EFEC, ' +
    'SERIE_FACC_CONCILIACION_EFEC, NUMERO_FACC_CONCILIACION_EFEC, ' +
    'NUMERO_EFEC_CONCILIACION_EFEC, OBSERVACIONES_EFEC, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qEfe: TUniQuery;
  bEfe: TBulkInsert;
  sAhora: string;
  sUser: string;
  sSerieFac: string;
  sNumFac: string;
  sSerieRem: string;
  sNumRem: string;
  sCodBanco: string;
  sClaveDoc: string;
  sClaveActual: string;
  sEstadoPendiente: string;
  sFechaPago: string;
  sTipoPago: string;
  sReferenciaPago: string;
  sReferenciaDocumento: string;
  sEntidadPago: string;
  iNumEfecto: Integer;
  iSiguienteEfecto: Integer;
  fImporte: Double;
  fPendiente: Double;
  fPagado: Double;

  procedure AnyadirEfecto(ANumEfecto, AOrdenPlazo: Integer;
    const AEstado: string; AImporte, APagado, APendiente: Double;
    const AFechaPago, ATipoPago, AReferenciaPago, AEntidadPago,
    AEsConciliado: string);
  begin
    bEfe.Add(UnirValores([
      ValorOrNull(sSerieFac),
      ValorOrNull(sNumFac),
      IntToStr(ANumEfecto),
      ValorOrNull(IntToStr(qEfe.FieldByName('Empresa').AsInteger)),
      ValorOrNull(Trim(qEfe.FieldByName('Proveedor').AsString)),
      ValorOrNull(TextoCampo(qEfe, 'RazonSocial', 200)),
      ValorOrNull(TextoCampo(qEfe, 'NIF', 50)),
      ValorOrNull(CodigoTipoEfecto(
        qEfe.FieldByName('TipoEfecto').AsInteger)),
      ValorOrNull(AEstado),
      IntToStr(AOrdenPlazo),
      FechaCampoASQL(qEfe, 'FechaEmision'),
      FechaCampoASQL(qEfe, 'FechaVto'),
      AFechaPago,
      ATipoPago,
      AReferenciaPago,
      AEntidadPago,
      ValorOrNull(AEsConciliado),
      F(AImporte),
      F(APagado),
      F(APendiente),
      sSerieRem,
      sNumRem,
      ValorOrNull(TextoCampo(qEfe, 'Entidad', 4)),
      ValorOrNull(TextoCampo(qEfe, 'Oficina', 4)),
      ValorOrNull(TextoCampo(qEfe, 'DigitosControl', 2)),
      ValorOrNull(TextoCampo(qEfe, 'NroCuenta', 10)),
      ValorOrNull(TextoCampo(qEfe, 'IBANProveedor', 34)),
      ValorOrNull(sCodBanco),
      ValorOrNull(TextoCampo(qEfe, 'IBANEmpresa', 34)),
      ValorOrNull(TextoCampo(qEfe, 'DocExterno', 50)),
      ValorOrNull(sReferenciaDocumento),
      'NULL',
      'NULL',
      'NULL',
      ValorOrNull(TextoCampo(qEfe, 'Observacion', 1000)),
      sAhora, sAhora, sUser, sUser]));
    Inc(Stats.Insertadas);
  end;

begin
  AsegurarEsquemaEfectosCompra(Eng);
  BorrarPorUsuario(Eng, 'fza_efectos_compra');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  sClaveActual := '';
  iSiguienteEfecto := 1;
  qEfe := NuevoQOrigen(Eng, cSelEfectos);
  qEfe.UniDirectional := True;
  bEfe := TBulkInsert.Create(Eng.ConDst, 'fza_efectos_compra',
                             cColsEfectos, BATCH);
  try
    Eng.Log('  efectos compra: vencimientos conciliados (ocefepro)...');
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocefepro e WHERE e.TipoDoc = ''FP'''));
    qEfe.Open;
    while not qEfe.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerieFac := SerieDocumento(qEfe.FieldByName('Ejercicio').AsInteger,
                                  TextoCampo(qEfe, 'Serie', 2));
      sNumFac := NumeroDocumento(qEfe.FieldByName('NroDoc').AsInteger);
      sReferenciaDocumento := TextoCampo(qEfe, 'DocExterno', 100);
      if Trim(sReferenciaDocumento) = '' then
        sReferenciaDocumento := sSerieFac + '/' + sNumFac;
      sClaveDoc := sSerieFac + '|' + sNumFac;
      if sClaveDoc <> sClaveActual then
      begin
        sClaveActual := sClaveDoc;
        iSiguienteEfecto := qEfe.FieldByName('MaxEfectoDoc').AsInteger + 1;
      end;
      if qEfe.FieldByName('NroRemesa').AsInteger > 0 then
      begin
        sSerieRem := ValorOrNull(SerieDocumento(
          qEfe.FieldByName('EjercicioRem').AsInteger,
          TextoCampo(qEfe, 'SerieRem', 2)));
        sNumRem := ValorOrNull(
          NumeroDocumento(qEfe.FieldByName('NroRemesa').AsInteger));
        sEstadoPendiente := 'REMESADO';
      end
      else
      begin
        sSerieRem := 'NULL';
        sNumRem := 'NULL';
        sEstadoPendiente := 'PENDIENTE';
      end;
      sCodBanco := CodigoBancoEmpresa(qEfe.FieldByName('Empresa').AsInteger,
                                      TextoCampo(qEfe, 'CuentaBanco', 15));
      iNumEfecto := qEfe.FieldByName('NroEfecto').AsInteger;
      fImporte := qEfe.FieldByName('ImpEfecto').AsFloat;
      fPendiente := qEfe.FieldByName('ImpPendiente').AsFloat;
      if fPendiente < 0 then
        fPendiente := 0;
      if (fImporte > 0) and (fPendiente > fImporte) then
        fPendiente := fImporte;
      fPagado := fImporte - fPendiente;
      if fPagado < 0 then
        fPagado := 0;
      sFechaPago := FechaCampoASQL(qEfe, 'FechaPago');
      if sFechaPago = 'NULL' then
        sFechaPago := FechaCampoASQL(qEfe, 'FechaPagoCobro');
      sTipoPago := ValorOrNull(CodigoTipoEfecto(
        qEfe.FieldByName('TipoPago').AsInteger));
      if sTipoPago = 'NULL' then
        sTipoPago := ValorOrNull(CodigoTipoEfecto(
          qEfe.FieldByName('TipoEfecto').AsInteger));
      sReferenciaPago := ValorOrNull(TextoCampo(qEfe, 'DocumentoPago', 100));
      if qEfe.FieldByName('CajaPago').AsInteger > 0 then
        sEntidadPago := ValorOrNull('Caja ' + IntToStr(
          qEfe.FieldByName('CajaPago').AsInteger))
      else
        sEntidadPago := ValorOrNull(TextoCampo(qEfe, 'IBANEmpresa', 34));
      if (fPagado > 0.0001) and (fPendiente > 0.0001) then
      begin
        AnyadirEfecto(iNumEfecto, iNumEfecto, 'PAGADO',
          fPagado, fPagado, 0, sFechaPago, sTipoPago, sReferenciaPago,
          sEntidadPago, 'S');
        AnyadirEfecto(iSiguienteEfecto, iNumEfecto, sEstadoPendiente,
          fPendiente, 0, fPendiente, 'NULL', 'NULL', 'NULL', 'NULL', 'N');
        Inc(iSiguienteEfecto);
      end
      else if fPendiente <= 0.0001 then
        AnyadirEfecto(iNumEfecto, iNumEfecto, 'PAGADO',
          fImporte, fImporte, 0, sFechaPago, sTipoPago, sReferenciaPago,
          sEntidadPago, 'S')
      else
        AnyadirEfecto(iNumEfecto, iNumEfecto, EstadoEfecto(qEfe),
          fImporte, 0, fPendiente, 'NULL', 'NULL', 'NULL', 'NULL', 'N');
      qEfe.Next;
    end;
    bEfe.FlushPendiente;
  finally
    bEfe.Free;
    qEfe.Free;
  end;
  Eng.Log('  efectos compra: efectos parciales divididos sin tabla de pagos.');
end;

procedure MigrarRemesasCompra(Eng: TMigEngine; var Stats: TMigStats);
const
  cSel =
    'SELECT r.Empresa, r.Ejercicio, ISNULL(r.Serie, '''') AS Serie, ' +
    '       r.NroRemesa, ISNULL(r.Tipo, '''') AS Tipo, ' +
    '       ISNULL(r.Norma, '''') AS Norma, ' +
    '       ISNULL(r.CuentaBanco, '''') AS CuentaBanco, ' +
    '       ISNULL(r.NroEfectos, 0) AS NroEfectos, ' +
    '       ISNULL(r.ImpRemesa, 0) AS ImpRemesa, ' +
    '       ISNULL(r.ImpGastos, 0) AS ImpGastos, ' +
    '       ISNULL(r.ImpComision, 0) AS ImpComision, ' +
    '       r.FechaRem, r.FechaCargo, r.InstanteConta, ' +
    '       ISNULL(r.ArchivoRemesa, '''') AS ArchivoRemesa, ' +
    '       CONVERT(varchar(1000), r.Observacion) AS Observacion, ' +
    '       ISNULL(br.Entidad, '''') AS Entidad, ' +
    '       ISNULL(br.Oficina, '''') AS Oficina, ' +
    '       ISNULL(br.DigitosControl, '''') AS DigitosControl, ' +
    '       ISNULL(br.NroCuenta, '''') AS NroCuenta, ' +
    '       ISNULL(br.IBAN, '''') AS IBAN ' +
    'FROM dbo.ocrempro r ' +
    'LEFT JOIN dbo.ocbanrem br ON br.CuentaBanco = r.CuentaBanco';
  cCols =
    'NUMERO_REMC, SERIE_REMC, FECHA_REMC, ESTADO_REMC, CODIGO_EMP_REMC, ' +
    'TIPO_REMC, NORMA_REMC, ENTIDAD_REMC, OFICINA_REMC, ' +
    'DIGITO_CONTROL_REMC, CUENTA_REMC, IBAN_REMC, CONTADOR_EFECTOS_REMC, ' +
    'TOTAL_REMC, TOTAL_GASTOS_REMC, TOTAL_COMISION_REMC, FECHA_CARGO_REMC, ' +
    'ARCHIVO_REMC, OBSERVACIONES_REMC, INSTANTE_CONTABILIZACION_REMC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  q: TUniQuery;
  b: TBulkInsert;
  sAhora: string;
  sUser: string;
  sSerie: string;
  sNumero: string;
begin
  BorrarPorUsuario(Eng, 'fza_remesas_compra');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  q := NuevoQOrigen(Eng, cSel);
  q.UniDirectional := True;
  b := TBulkInsert.Create(Eng.ConDst, 'fza_remesas_compra', cCols, BATCH);
  try
    Eng.Log('  remesas compra: cabeceras (ocrempro)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocrempro'));
    q.Open;
    while not q.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(q.FieldByName('Ejercicio').AsInteger,
                               TextoCampo(q, 'Serie', 2));
      sNumero := NumeroDocumento(q.FieldByName('NroRemesa').AsInteger);
      b.Add(UnirValores([
        ValorOrNull(sNumero),
        ValorOrNull(sSerie),
        FechaCampoASQL(q, 'FechaRem'),
        ValorOrNull(EstadoRemesa(q)),
        ValorOrNull(IntToStr(q.FieldByName('Empresa').AsInteger)),
        ValorOrNull(TipoRemesa(q)),
        ValorOrNull(TextoCampo(q, 'Norma', 10)),
        ValorOrNull(TextoCampo(q, 'Entidad', 4)),
        ValorOrNull(TextoCampo(q, 'Oficina', 4)),
        ValorOrNull(TextoCampo(q, 'DigitosControl', 2)),
        ValorOrNull(TextoCampo(q, 'NroCuenta', 10)),
        ValorOrNull(TextoCampo(q, 'IBAN', 34)),
        IntToStr(q.FieldByName('NroEfectos').AsInteger),
        F(q.FieldByName('ImpRemesa').AsFloat),
        F(q.FieldByName('ImpGastos').AsFloat),
        F(q.FieldByName('ImpComision').AsFloat),
        FechaCampoASQL(q, 'FechaCargo'),
        ValorOrNull(TextoCampo(q, 'ArchivoRemesa', 200)),
        ValorOrNull(TextoCampo(q, 'Observacion', 1000)),
        FechaHoraCampoASQL(q, 'InstanteConta'),
        sAhora, sAhora, sUser, sUser]));
      Inc(Stats.Insertadas);
      q.Next;
    end;
    b.FlushPendiente;
  finally
    b.Free;
    q.Free;
  end;
  RecalcularRemesasDesdeEfectos(Eng);
  Eng.Log('  remesas compra: totales recalculados desde efectos enlazados.');
end;

initialization
  fsEfectos := TFormatSettings.Create('en-US');

end.
