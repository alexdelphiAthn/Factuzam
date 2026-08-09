program CargarDatosDemostracion;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  Data.DB,
  Uni,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibContadoresIntf in
    '..\src\Lib\inLibContadoresIntf.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataContadoresRepositorio in
    '..\src\DataModules\UniDataContadoresRepositorio.pas',
  UniDataArchivoDocumental in
    '..\src\DataModules\UniDataArchivoDocumental.pas';

const
  EmpresaDemo = '001';
  EjercicioDemo = 2026;
  OrigenDemo = 'DEMO';

type
  TLineaDemo = record
    Cuenta: string;
    Concepto: string;
    Debe: Currency;
    Haber: Currency;
    Documento: string;
  end;

function CrearLinea(
  const ACuenta: string;
  const AConcepto: string;
  ADebe: Currency;
  AHaber: Currency;
  const ADocumento: string = ''): TLineaDemo;
begin
  Result := Default(TLineaDemo);
  Result.Cuenta := ACuenta;
  Result.Concepto := AConcepto;
  Result.Debe := ADebe;
  Result.Haber := AHaber;
  Result.Documento := ADocumento;
end;

procedure EjecutarSql(
  AConexion: TUniConnection;
  const ASql: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure PrepararEmpresa(AConexion: TUniConnection);
begin
  EjecutarSql(
    AConexion,
    'UPDATE cza_empresas SET ' +
    'RAZON_SOCIAL_EMP = ''Empresa de pruebas Contazam'', ' +
    'INSTANTE_MODIF = NOW(), USUARIO_MODIF = ''DEMO'' ' +
    'WHERE CODIGO_EMP = ''001''');
  EjecutarSql(
    AConexion,
    'INSERT IGNORE INTO cza_ejercicios (' +
    'CODIGO_EMP_EJE, EJERCICIO_EJE, FECHA_INICIO_EJE, ' +
    'FECHA_FIN_EJE, ESTADO_EJE, ESACTIVO_EJE, ' +
    'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
    '''001'', 2026, ''2026-01-01'', ''2026-12-31'', ' +
    '''ABIERTO'', ''S'', NOW(), ''DEMO'')');
  EjecutarSql(
    AConexion,
    'INSERT IGNORE INTO cza_contadores (' +
    'TIPO_DOCUMENTO_CON, CODIGO_EMP_CON, EJERCICIO_CON, ' +
    'SERIE_CON, CONTADOR_CON, NUMERO_DIGITOS_CON, ' +
    'ESACTIVO_CON, ESDEFECTO_CON, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (''ASIENTO'', ''001'', 2026, ''-'', ''00000000'', 8, ' +
    '''S'', ''S'', NOW(), ''DEMO'')');
  EjecutarSql(
    AConexion,
    'INSERT IGNORE INTO cza_cuentas (' +
    'CODIGO_EMP_CTA, EJERCICIO_CTA, CODIGO_CTA, ' +
    'CODIGO_CTA_PADRE_CTA, NOMBRE_CTA, NIVEL_CTA, TIPO_CTA, ' +
    'NATURALEZA_CTA, ESIMPUTABLE_CTA, ESACTIVO_CTA, ORDEN_CTA, ' +
    'INSTANTE_ALTA, USUARIO_ALTA) SELECT ''001'', 2026, ' +
    'CODIGO_MOD, CODIGO_PADRE_MOD, NOMBRE_MOD, NIVEL_MOD, TIPO_MOD, ' +
    'NATURALEZA_MOD, ESIMPUTABLE_MOD, ''S'', ORDEN_MOD, ' +
    'NOW(), ''DEMO'' FROM cza_cuentas_modelo ' +
    'WHERE ESACTIVO_MOD = ''S''');
end;

function ExisteAsiento(
  AConexion: TUniConnection;
  const AClave: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT ID_ASI FROM cza_asientos ' +
      'WHERE CODIGO_EMP_ASI = :EMPRESA ' +
      'AND EJERCICIO_ASI = :EJERCICIO ' +
      'AND SISTEMA_ORIGEN_ASI = :ORIGEN ' +
      'AND CLAVE_DOCUMENTO_ORIGEN_ASI = :CLAVE';
    oConsulta.ParamByName('EMPRESA').AsString := EmpresaDemo;
    oConsulta.ParamByName('EJERCICIO').AsInteger := EjercicioDemo;
    oConsulta.ParamByName('ORIGEN').AsString := OrigenDemo;
    oConsulta.ParamByName('CLAVE').AsString := AClave;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure AsegurarAsiento(
  AConexion: TUniConnection;
  AContadores: IContadorDocumentos;
  const AClave: string;
  AFecha: TDate;
  const AConcepto: string;
  const AEstado: string;
  const ALineas: array of TLineaDemo);
var
  iIdAsiento: Int64;
  iIdLinea: Int64;
  iLinea: Integer;
  iNumero: Int64;
  oConsulta: TUniQuery;
begin
  if not ExisteAsiento(AConexion, AClave) then
  begin
    AConexion.StartTransaction;
    oConsulta := TUniQuery.Create(nil);
    try
      try
        iIdAsiento := AContadores.SiguienteNumero(
          'GLOBAL',
          0,
          'ID_ASIENTO',
          '-');
        iNumero := AContadores.SiguienteNumero(
          EmpresaDemo,
          EjercicioDemo,
          'ASIENTO',
          '-');
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'INSERT INTO cza_asientos (' +
          'ID_ASI, CODIGO_EMP_ASI, EJERCICIO_ASI, NUMERO_ASI, ' +
          'FECHA_ASI, CONCEPTO_ASI, ESTADO_ASI, ' +
          'SISTEMA_ORIGEN_ASI, TIPO_DOCUMENTO_ORIGEN_ASI, ' +
          'CLAVE_DOCUMENTO_ORIGEN_ASI, INSTANTE_ALTA, USUARIO_ALTA) ' +
          'VALUES (:ID, :EMPRESA, :EJERCICIO, :NUMERO, :FECHA, ' +
          ':CONCEPTO, :ESTADO, :ORIGEN, ''ASIENTO_PRUEBA'', ' +
          ':CLAVE, NOW(), ''DEMO'')';
        oConsulta.ParamByName('ID').AsLargeInt := iIdAsiento;
        oConsulta.ParamByName('EMPRESA').AsString := EmpresaDemo;
        oConsulta.ParamByName('EJERCICIO').AsInteger := EjercicioDemo;
        oConsulta.ParamByName('NUMERO').AsLargeInt := iNumero;
        oConsulta.ParamByName('FECHA').AsDate := AFecha;
        oConsulta.ParamByName('CONCEPTO').AsString := AConcepto;
        oConsulta.ParamByName('ESTADO').AsString := AEstado;
        oConsulta.ParamByName('ORIGEN').AsString := OrigenDemo;
        oConsulta.ParamByName('CLAVE').AsString := AClave;
        oConsulta.ExecSQL;
        oConsulta.SQL.Text :=
          'INSERT INTO cza_asientos_lineas (' +
          'ID_ASILIN, ID_ASI_ASILIN, LINEA_ASILIN, ' +
          'CODIGO_CTA_ASILIN, CONCEPTO_ASILIN, ' +
          'IMPORTE_DEBE_ASILIN, IMPORTE_HABER_ASILIN, ' +
          'DOCUMENTO_ASILIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
          'VALUES (:ID, :ASIENTO, :LINEA, :CUENTA, :CONCEPTO, ' +
          ':DEBE, :HABER, :DOCUMENTO, NOW(), ''DEMO'')';
        for iLinea := Low(ALineas) to High(ALineas) do
        begin
          iIdLinea := AContadores.SiguienteNumero(
            'GLOBAL',
            0,
            'ID_APUNTE',
            '-');
          oConsulta.ParamByName('ID').AsLargeInt := iIdLinea;
          oConsulta.ParamByName('ASIENTO').AsLargeInt := iIdAsiento;
          oConsulta.ParamByName('LINEA').AsInteger := iLinea + 1;
          oConsulta.ParamByName('CUENTA').AsString :=
            ALineas[iLinea].Cuenta;
          oConsulta.ParamByName('CONCEPTO').AsString :=
            ALineas[iLinea].Concepto;
          oConsulta.ParamByName('DEBE').AsCurrency :=
            ALineas[iLinea].Debe;
          oConsulta.ParamByName('HABER').AsCurrency :=
            ALineas[iLinea].Haber;
          oConsulta.ParamByName('DOCUMENTO').AsString :=
            ALineas[iLinea].Documento;
          oConsulta.ExecSQL;
        end;
        AConexion.Commit;
      except
        if AConexion.InTransaction then
        begin
          AConexion.Rollback;
        end;
        raise;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure AsegurarDocumento(AConexion: TUniConnection);
var
  oArchivo: TdmArchivoDocumental;
  oConsulta: TUniQuery;
  sPdf: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT ID_DOC FROM cza_documentos ' +
      'WHERE CODIGO_EMP_DOC = ''001'' AND EJERCICIO_DOC = 2026 ' +
      'AND REFERENCIA_DOC = ''DEMO-FAC-VENTA-001''';
    oConsulta.Open;
    if oConsulta.IsEmpty then
    begin
      oArchivo := TdmArchivoDocumental.Create(
        nil,
        AConexion,
        EmpresaDemo,
        EjercicioDemo);
      try
        oArchivo.Abrir;
        sPdf := TPath.Combine(
          GetCurrentDir,
          'fixtures\documento_prueba.pdf');
        oArchivo.ImportarPdf(
          sPdf,
          'DEMO-FAC-VENTA-001',
          'Factura de venta archivada para demostración');
      finally
        FreeAndNil(oArchivo);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CargarAsientos(
  AConexion: TUniConnection;
  AContadores: IContadorDocumentos);
begin
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-001', EncodeDate(2026, 1, 2),
    'Aportación inicial de capital', 'CERRADO', [
      CrearLinea('572000000000', 'Ingreso en banco', 3000, 0),
      CrearLinea('100000000000', 'Capital social', 0, 3000)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-002', EncodeDate(2026, 1, 5),
    'Compra de material de oficina', 'CERRADO', [
      CrearLinea('629000000000', 'Material de oficina', 100, 0),
      CrearLinea('472000000000', 'IVA soportado', 21, 0),
      CrearLinea('410000000000', 'Proveedor pendiente', 0, 121)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-003', EncodeDate(2026, 1, 10),
    'Factura de servicios a cliente', 'CERRADO', [
      CrearLinea(
        '430000000000', 'Cliente', 1210, 0, 'DEMO-FAC-VENTA-001'),
      CrearLinea(
        '705000000000', 'Servicios', 0, 1000, 'DEMO-FAC-VENTA-001'),
      CrearLinea(
        '477000000000', 'IVA repercutido', 0, 210,
        'DEMO-FAC-VENTA-001')
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-004', EncodeDate(2026, 1, 20),
    'Cobro de la factura del cliente', 'CERRADO', [
      CrearLinea('572000000000', 'Ingreso bancario', 1210, 0),
      CrearLinea('430000000000', 'Cancelación cliente', 0, 1210)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-005', EncodeDate(2026, 1, 25),
    'Pago al proveedor de oficina', 'CERRADO', [
      CrearLinea('410000000000', 'Cancelación proveedor', 121, 0),
      CrearLinea('572000000000', 'Salida bancaria', 0, 121)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-006', EncodeDate(2026, 1, 31),
    'Nómina y seguros sociales de enero', 'CERRADO', [
      CrearLinea('640000000000', 'Sueldos y salarios', 1500, 0),
      CrearLinea('642000000000', 'Seguridad Social empresa', 480, 0),
      CrearLinea('476000000000', 'Seguridad Social acreedora', 0, 480),
      CrearLinea('475100000000', 'Retención IRPF', 0, 225),
      CrearLinea('465000000000', 'Remuneración pendiente', 0, 1275)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-007', EncodeDate(2026, 2, 5),
    'Pago de nómina e impuestos', 'CERRADO', [
      CrearLinea('465000000000', 'Pago neto nómina', 1275, 0),
      CrearLinea('475100000000', 'Pago retención IRPF', 225, 0),
      CrearLinea('476000000000', 'Pago Seguridad Social', 480, 0),
      CrearLinea('572000000000', 'Salida bancaria', 0, 1980)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-008', EncodeDate(2026, 2, 15),
    'Comisiones bancarias', 'CERRADO', [
      CrearLinea('626000000000', 'Servicio bancario', 20, 0),
      CrearLinea('472000000000', 'IVA soportado', 4.20, 0),
      CrearLinea('572000000000', 'Cargo bancario', 0, 24.20)
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-009', EncodeDate(2026, 3, 5),
    'Borrador descuadrado de mobiliario', 'BORRADOR', [
      CrearLinea(
        '216000000000', 'Mobiliario', 800, 0, 'DEMO-PROFORMA-001'),
      CrearLinea(
        '472000000000', 'IVA soportado', 168, 0, 'DEMO-PROFORMA-001'),
      CrearLinea(
        '410000000000', 'Proveedor', 0, 900, 'DEMO-PROFORMA-001')
    ]);
  AsegurarAsiento(
    AConexion, AContadores, 'DEMO-010', EncodeDate(2026, 3, 10),
    'Borrador de factura importada', 'BORRADOR', [
      CrearLinea(
        '430000000000', 'Cliente', 605, 0, 'DEMO-BORRADOR-VENTA-001'),
      CrearLinea(
        '705000000000', 'Servicios', 0, 500,
        'DEMO-BORRADOR-VENTA-001'),
      CrearLinea(
        '477000000000', 'IVA repercutido', 0, 105,
        'DEMO-BORRADOR-VENTA-001')
    ]);
end;

procedure ValidarResultado(AConexion: TUniConnection);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS ASIENTOS, ' +
      'SUM(ESTADO_ASI = ''CERRADO'') AS CERRADOS, ' +
      'SUM(ESTADO_ASI = ''BORRADOR'') AS BORRADORES ' +
      'FROM cza_asientos WHERE CODIGO_EMP_ASI = ''001'' ' +
      'AND EJERCICIO_ASI = 2026 AND SISTEMA_ORIGEN_ASI = ''DEMO''';
    oConsulta.Open;
    if oConsulta.FieldByName('ASIENTOS').AsInteger <> 10 then
    begin
      raise Exception.Create(
        'No se han creado los diez asientos de demostración.');
    end;
    Writeln(
      'ASIENTOS=', oConsulta.FieldByName('ASIENTOS').AsString,
      ' CERRADOS=', oConsulta.FieldByName('CERRADOS').AsString,
      ' BORRADORES=', oConsulta.FieldByName('BORRADORES').AsString);
    oConsulta.Close;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL FROM cza_asientos_lineas L ' +
      'JOIN cza_asientos A ON A.ID_ASI = L.ID_ASI_ASILIN ' +
      'WHERE A.CODIGO_EMP_ASI = ''001'' AND A.EJERCICIO_ASI = 2026 ' +
      'AND A.SISTEMA_ORIGEN_ASI = ''DEMO''';
    oConsulta.Open;
    if oConsulta.FieldByName('TOTAL').AsInteger <> 30 then
    begin
      raise Exception.Create(
        'Los asientos no contienen los treinta apuntes previstos.');
    end;
    Writeln('APUNTES=', oConsulta.FieldByName('TOTAL').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure EjecutarCarga;
var
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oContadores: IContadorDocumentos;
begin
  oConfiguracion := Default(TConfiguracionContazam);
  oConfiguracion.Servidor := '127.0.0.1';
  oConfiguracion.Puerto := 3306;
  oConfiguracion.Usuario := 'root';
  oConfiguracion.Contrasena := GetEnvironmentVariable(
    'CONTAZAM_DB_PASSWORD');
  oConfiguracion.BaseDatos := 'contazam';
  if not SameText(oConfiguracion.BaseDatos, 'contazam') then
  begin
    raise Exception.Create(
      'La carga de demostración solo puede ejecutarse en contazam.');
  end;
  oConexion := TdmConexion.Create(nil, oConfiguracion);
  try
    PrepararEmpresa(oConexion.Conexion);
    oContadores := CrearRepositorioContadores(oConexion.Conexion);
    AsegurarDocumento(oConexion.Conexion);
    CargarAsientos(oConexion.Conexion, oContadores);
    ValidarResultado(oConexion.Conexion);
    oContadores := nil;
  finally
    FreeAndNil(oConexion);
  end;
end;

begin
  try
    EjecutarCarga;
    Writeln('DATOS_DEMOSTRACION=OK');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
