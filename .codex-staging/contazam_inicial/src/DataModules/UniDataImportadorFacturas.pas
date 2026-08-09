{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataImportadorFacturas                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Importa facturas emitidas de Factuzam como asientos revisables.           }
{******************************************************************************}
unit UniDataImportadorFacturas;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni, inLibConfiguracion,
  inLibContadoresIntf, inLibContabilidadTipos;

type
  TdmImportadorFacturas = class(TDataModule)
  private
    FConexion: TUniConnection;
    FConfiguracion: TConfiguracionContazam;
    FBaseDatosFactuzam: string;
    FEmpresaFactuzam: string;
    FEjercicio: Integer;
    FPendientes: TUniQuery;
    FContadores: IContadorDocumentos;
    procedure CargarOrigenEmpresa;
    function CrearClaveOrigen: string;
    function LeerCuentaRol(const ARol: string): string;
    function InsertarAsiento(
      ANumero: Int64;
      const AClaveOrigen: string): Int64;
    procedure InsertarApunte(
      AIdAsiento: Int64;
      ALinea: Integer;
      const ACuenta: string;
      const AConcepto: string;
      AImporte: Currency;
      AEsDebe: Boolean);
    procedure RegistrarImportacion(
      AIdAsiento: Int64;
      const AClaveOrigen: string);
    procedure ImportarFacturaActual;
    procedure ComprobarCuadreFactura;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam;
      AEjercicio: Integer); reintroduce;
    destructor Destroy; override;
    procedure CargarPendientes(
      AFechaDesde: TDate;
      AFechaHasta: TDate);
    function ImportarPendientes: TResultadoImportacionFacturas;
    property Pendientes: TUniQuery read FPendientes;
  end;

implementation

uses
  System.Math, UniDataContadoresRepositorio;

constructor TdmImportadorFacturas.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam;
  AEjercicio: Integer);
var
  sSql: string;
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited CreateNew(AOwner);
  FConexion := AConexion;
  FConfiguracion := AConfiguracion;
  FEjercicio := AEjercicio;
  CargarOrigenEmpresa;
  FContadores := CrearRepositorioContadores(FConexion);
  FPendientes := TUniQuery.Create(Self);
  FPendientes.Connection := FConexion;
  FPendientes.ReadOnly := True;
  sSql :=
    'SELECT F.NUMERO_FAC, F.SERIE_FAC, F.FECHA_FAC, ' +
    '       F.CODIGO_EMP_FAC, F.CODIGO_CLI_FAC, ' +
    '       F.RAZON_SOCIAL_CLIENTE_FAC, F.NIF_CLIENTE_FAC, ' +
    '       COALESCE(F.TOTAL_BASES_FAC, 0) AS TOTAL_BASES_FAC, ' +
    '       COALESCE(F.TOTAL_IMPUESTOS_FAC, 0) ' +
    '         AS TOTAL_IMPUESTOS_FAC, ' +
    '       COALESCE(F.TOTAL_RETENCION_FAC, 0) ' +
    '         AS TOTAL_RETENCION_FAC, ' +
    '       COALESCE(F.TOTAL_LIQUIDO_FAC, 0) AS TOTAL_LIQUIDO_FAC ' +
    '  FROM `%s`.fza_facturas F ' +
    ' WHERE F.CODIGO_EMP_FAC = :EMPRESA_ORIGEN ' +
    '   AND F.FECHA_FAC BETWEEN :DESDE AND :HASTA ' +
    '   AND COALESCE(F.FASE_FAC, '''') <> ''BORRADOR'' ' +
    '   AND NOT EXISTS (' +
    '     SELECT 1 FROM cza_importaciones I ' +
    '      WHERE I.SISTEMA_ORIGEN_IMP = ''FACTUZAM'' ' +
    '        AND I.CODIGO_EMP_DESTINO_IMP = :EMPRESA_DESTINO ' +
    '        AND I.BASE_DATOS_ORIGEN_IMP = :BASE_DATOS_ORIGEN ' +
    '        AND I.TIPO_DOCUMENTO_ORIGEN_IMP = ''FACTURA_VENTA'' ' +
    '        AND I.CLAVE_DOCUMENTO_ORIGEN_IMP = CONCAT(' +
    '          F.CODIGO_EMP_FAC, ''|'', F.SERIE_FAC, ''|'', ' +
    '          F.NUMERO_FAC)) ' +
    ' ORDER BY F.FECHA_FAC, F.SERIE_FAC, F.NUMERO_FAC';
  FPendientes.SQL.Text := Format(
    sSql,
    [FBaseDatosFactuzam]);
end;

procedure TdmImportadorFacturas.CargarOrigenEmpresa;
var
  oConsulta: TUniQuery;
begin
  FBaseDatosFactuzam := FConfiguracion.BaseDatosFactuzam;
  FEmpresaFactuzam := FConfiguracion.EmpresaFactuzam;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT BASE_DATOS_FACTUZAM_EMP, CODIGO_EMP_FACTUZAM_EMP ' +
      'FROM cza_empresas WHERE CODIGO_EMP = :EMPRESA';
    oConsulta.ParamByName('EMPRESA').AsString :=
      FConfiguracion.Empresa;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      if oConsulta.FieldByName(
        'BASE_DATOS_FACTUZAM_EMP').AsString <> '' then
      begin
        FBaseDatosFactuzam := oConsulta.FieldByName(
          'BASE_DATOS_FACTUZAM_EMP').AsString;
      end;
      if oConsulta.FieldByName(
        'CODIGO_EMP_FACTUZAM_EMP').AsString <> '' then
      begin
        FEmpresaFactuzam := oConsulta.FieldByName(
          'CODIGO_EMP_FACTUZAM_EMP').AsString;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if not EsIdentificadorMariaDBValido(FBaseDatosFactuzam) then
  begin
    raise EConvertError.Create(
      'La base de datos Factuzam configurada en la empresa no es válida.');
  end;
end;

procedure TdmImportadorFacturas.CargarPendientes(
  AFechaDesde: TDate;
  AFechaHasta: TDate);
begin
  FPendientes.Close;
  FPendientes.ParamByName('EMPRESA_ORIGEN').AsString :=
    FEmpresaFactuzam;
  FPendientes.ParamByName('EMPRESA_DESTINO').AsString :=
    FConfiguracion.Empresa;
  FPendientes.ParamByName('BASE_DATOS_ORIGEN').AsString :=
    FBaseDatosFactuzam;
  FPendientes.ParamByName('DESDE').AsDate := AFechaDesde;
  FPendientes.ParamByName('HASTA').AsDate := AFechaHasta;
  FPendientes.Open;
end;

procedure TdmImportadorFacturas.ComprobarCuadreFactura;
var
  dDebe: Currency;
  dHaber: Currency;
begin
  dDebe := FPendientes.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency +
    FPendientes.FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
  dHaber := FPendientes.FieldByName('TOTAL_BASES_FAC').AsCurrency +
    FPendientes.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
  if not SameValue(dDebe, dHaber, 0.01) then
  begin
    raise EDatabaseError.CreateFmt(
      'La factura %s/%s no cuadra: Debe %.2f / Haber %.2f.',
      [FPendientes.FieldByName('SERIE_FAC').AsString,
       FPendientes.FieldByName('NUMERO_FAC').AsString,
       dDebe,
       dHaber]);
  end;
end;

function TdmImportadorFacturas.CrearClaveOrigen: string;
begin
  Result :=
    FPendientes.FieldByName('CODIGO_EMP_FAC').AsString + '|' +
    FPendientes.FieldByName('SERIE_FAC').AsString + '|' +
    FPendientes.FieldByName('NUMERO_FAC').AsString;
end;

destructor TdmImportadorFacturas.Destroy;
begin
  FContadores := nil;
  inherited;
end;

procedure TdmImportadorFacturas.ImportarFacturaActual;
var
  iIdAsiento: Int64;
  iNumero: Int64;
  iLinea: Integer;
  sClaveOrigen: string;
  sConcepto: string;
begin
  ComprobarCuadreFactura;
  sClaveOrigen := CrearClaveOrigen;
  sConcepto := Format(
    'Factura Factuzam %s/%s - %s',
    [FPendientes.FieldByName('SERIE_FAC').AsString,
     FPendientes.FieldByName('NUMERO_FAC').AsString,
     FPendientes.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString]);
  FConexion.StartTransaction;
  try
    iNumero := FContadores.SiguienteNumero(
      FConfiguracion.Empresa,
      FEjercicio,
      'ASIENTO',
      '-');
    iIdAsiento := InsertarAsiento(iNumero, sClaveOrigen);
    iLinea := 10;
    InsertarApunte(
      iIdAsiento,
      iLinea,
      LeerCuentaRol('CLIENTES'),
      sConcepto,
      FPendientes.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency,
      True);
    Inc(iLinea, 10);
    InsertarApunte(
      iIdAsiento,
      iLinea,
      LeerCuentaRol('RETENCIONES'),
      sConcepto,
      FPendientes.FieldByName('TOTAL_RETENCION_FAC').AsCurrency,
      True);
    Inc(iLinea, 10);
    InsertarApunte(
      iIdAsiento,
      iLinea,
      LeerCuentaRol('VENTAS'),
      sConcepto,
      FPendientes.FieldByName('TOTAL_BASES_FAC').AsCurrency,
      False);
    Inc(iLinea, 10);
    InsertarApunte(
      iIdAsiento,
      iLinea,
      LeerCuentaRol('IVA_REPERCUTIDO'),
      sConcepto,
      FPendientes.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency,
      False);
    RegistrarImportacion(iIdAsiento, sClaveOrigen);
    FConexion.Commit;
  except
    if FConexion.InTransaction then
    begin
      FConexion.Rollback;
    end;
    raise;
  end;
end;

function TdmImportadorFacturas.ImportarPendientes:
  TResultadoImportacionFacturas;
begin
  Result := Default(TResultadoImportacionFacturas);
  FPendientes.First;
  while not FPendientes.Eof do
  begin
    ImportarFacturaActual;
    Inc(Result.Importadas);
    FPendientes.Next;
  end;
end;

function TdmImportadorFacturas.InsertarAsiento(
  ANumero: Int64;
  const AClaveOrigen: string): Int64;
var
  oConsulta: TUniQuery;
begin
  Result := FContadores.SiguienteNumero(
    'GLOBAL',
    0,
    'ID_ASIENTO',
    '-');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO cza_asientos (' +
      'ID_ASI, CODIGO_EMP_ASI, EJERCICIO_ASI, NUMERO_ASI, FECHA_ASI, ' +
      'CONCEPTO_ASI, ESTADO_ASI, SISTEMA_ORIGEN_ASI, ' +
      'TIPO_DOCUMENTO_ORIGEN_ASI, CLAVE_DOCUMENTO_ORIGEN_ASI, ' +
      'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
      ':ID, :EMPRESA, :EJERCICIO, :NUMERO, :FECHA, :CONCEPTO, ' +
      '''BORRADOR'', ''FACTUZAM'', ''FACTURA_VENTA'', :CLAVE, ' +
      'NOW(), :USUARIO)';
    oConsulta.ParamByName('ID').AsLargeInt := Result;
    oConsulta.ParamByName('EMPRESA').AsString :=
      FConfiguracion.Empresa;
    oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
    oConsulta.ParamByName('NUMERO').AsLargeInt := ANumero;
    oConsulta.ParamByName('FECHA').AsDate :=
      FPendientes.FieldByName('FECHA_FAC').AsDateTime;
    oConsulta.ParamByName('CONCEPTO').AsString := Format(
      'Factura Factuzam %s/%s - %s',
      [FPendientes.FieldByName('SERIE_FAC').AsString,
       FPendientes.FieldByName('NUMERO_FAC').AsString,
       FPendientes.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString]);
    oConsulta.ParamByName('CLAVE').AsString := AClaveOrigen;
    oConsulta.ParamByName('USUARIO').AsString :=
      GetEnvironmentVariable('USERNAME');
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmImportadorFacturas.InsertarApunte(
  AIdAsiento: Int64;
  ALinea: Integer;
  const ACuenta: string;
  const AConcepto: string;
  AImporte: Currency;
  AEsDebe: Boolean);
var
  oConsulta: TUniQuery;
  iIdApunte: Int64;
  dDebe: Currency;
  dHaber: Currency;
begin
  if not SameValue(AImporte, 0, 0.0001) then
  begin
    iIdApunte := FContadores.SiguienteNumero(
      'GLOBAL',
      0,
      'ID_APUNTE',
      '-');
    dDebe := 0;
    dHaber := 0;
    if AEsDebe = (AImporte > 0) then
    begin
      dDebe := Abs(AImporte);
    end
    else
    begin
      dHaber := Abs(AImporte);
    end;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'INSERT INTO cza_asientos_lineas (' +
        'ID_ASILIN, ID_ASI_ASILIN, LINEA_ASILIN, ' +
        'CODIGO_CTA_ASILIN, ' +
        'CONCEPTO_ASILIN, IMPORTE_DEBE_ASILIN, ' +
        'IMPORTE_HABER_ASILIN, DOCUMENTO_ASILIN, ' +
        'CODIGO_TERCERO_ASILIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:ID_APUNTE, :ID, :LINEA, :CUENTA, :CONCEPTO, ' +
        ':DEBE, :HABER, ' +
        ':DOCUMENTO, :TERCERO, NOW(), :USUARIO)';
      oConsulta.ParamByName('ID_APUNTE').AsLargeInt := iIdApunte;
      oConsulta.ParamByName('ID').AsLargeInt := AIdAsiento;
      oConsulta.ParamByName('LINEA').AsInteger := ALinea;
      oConsulta.ParamByName('CUENTA').AsString := ACuenta;
      oConsulta.ParamByName('CONCEPTO').AsString := AConcepto;
      oConsulta.ParamByName('DEBE').AsCurrency := dDebe;
      oConsulta.ParamByName('HABER').AsCurrency := dHaber;
      oConsulta.ParamByName('DOCUMENTO').AsString := Format(
        '%s/%s',
        [FPendientes.FieldByName('SERIE_FAC').AsString,
         FPendientes.FieldByName('NUMERO_FAC').AsString]);
      oConsulta.ParamByName('TERCERO').AsString :=
        FPendientes.FieldByName('CODIGO_CLI_FAC').AsString;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TdmImportadorFacturas.LeerCuentaRol(
  const ARol: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_CTA_MAP FROM cza_mapeos_contables ' +
      'WHERE CODIGO_EMP_MAP = :EMPRESA ' +
      'AND EJERCICIO_MAP = :EJERCICIO ' +
      'AND ROL_MAP = :ROL AND ESACTIVO_MAP = ''S''';
    oConsulta.ParamByName('EMPRESA').AsString :=
      FConfiguracion.Empresa;
    oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
    oConsulta.ParamByName('ROL').AsString := ARol;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('CODIGO_CTA_MAP').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if Result = '' then
  begin
    raise EDatabaseError.CreateFmt(
      'No existe una cuenta activa para el rol contable %s.',
      [ARol]);
  end;
end;

procedure TdmImportadorFacturas.RegistrarImportacion(
  AIdAsiento: Int64;
  const AClaveOrigen: string);
var
  oConsulta: TUniQuery;
  iIdImportacion: Int64;
begin
  iIdImportacion := FContadores.SiguienteNumero(
    'GLOBAL',
    0,
    'ID_IMPORTACION',
    '-');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO cza_importaciones (' +
      'ID_IMP, CODIGO_EMP_DESTINO_IMP, SISTEMA_ORIGEN_IMP, ' +
      'BASE_DATOS_ORIGEN_IMP, ' +
      'TIPO_DOCUMENTO_ORIGEN_IMP, CLAVE_DOCUMENTO_ORIGEN_IMP, ' +
      'ID_ASI_IMP, ESTADO_IMP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:ID_IMPORTACION, :EMPRESA, ''FACTUZAM'', :BASE_DATOS, ' +
      '''FACTURA_VENTA'', :CLAVE, :ID, ''PENDIENTE_REVISION'', ' +
      'NOW(), :USUARIO)';
    oConsulta.ParamByName('ID_IMPORTACION').AsLargeInt :=
      iIdImportacion;
    oConsulta.ParamByName('EMPRESA').AsString :=
      FConfiguracion.Empresa;
    oConsulta.ParamByName('BASE_DATOS').AsString :=
      FBaseDatosFactuzam;
    oConsulta.ParamByName('CLAVE').AsString := AClaveOrigen;
    oConsulta.ParamByName('ID').AsLargeInt := AIdAsiento;
    oConsulta.ParamByName('USUARIO').AsString :=
      GetEnvironmentVariable('USERNAME');
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
