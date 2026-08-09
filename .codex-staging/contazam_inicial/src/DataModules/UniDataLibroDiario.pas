{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLibroDiario                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia transaccional de asientos y apuntes del libro diario.        }
{******************************************************************************}
unit UniDataLibroDiario;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni, inLibContadoresIntf,
  inLibContabilidadTipos;

type
  TdmLibroDiario = class(TDataModule)
  private
    FConexion: TUniConnection;
    FEmpresa: string;
    FEjercicio: Integer;
    FContadores: IContadorDocumentos;
    FAsientos: TUniQuery;
    FLineas: TUniQuery;
    FContrapartidas: TUniQuery;
    procedure ConfigurarAsientos;
    procedure ConfigurarLineas;
    procedure AsientoCambiado(DataSet: TDataSet);
    procedure AntesDePublicarLinea(DataSet: TDataSet);
    procedure AntesDeEditarLinea(DataSet: TDataSet);
    procedure AntesDeEliminarLinea(DataSet: TDataSet);
    procedure CargarLineas;
    procedure ComprobarAsientoEditable;
    function BuscarDocumentosFaltantes: string;
    function LeerLineas: TArray<TLineaAsiento>;
    function SiguienteLinea: Integer;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      AEjercicio: Integer); reintroduce;
    destructor Destroy; override;
    procedure Abrir;
    procedure Actualizar;
    procedure CrearAsiento(
      AFecha: TDate;
      const AConcepto: string);
    procedure CrearLinea;
    procedure CargarContrapartidas(const ACuenta: string);
    function CerrarAsiento: TResultadoValidacionAsiento;
    procedure ReabrirAsiento;
    property Asientos: TUniQuery read FAsientos;
    property Lineas: TUniQuery read FLineas;
    property Contrapartidas: TUniQuery read FContrapartidas;
  end;

implementation

uses
  inLibValidacionAsientos, UniDataContadoresRepositorio;

constructor TdmLibroDiario.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited CreateNew(AOwner);
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
  FContadores := CrearRepositorioContadores(FConexion);
  FAsientos := TUniQuery.Create(Self);
  FAsientos.Connection := FConexion;
  FLineas := TUniQuery.Create(Self);
  FLineas.Connection := FConexion;
  FContrapartidas := TUniQuery.Create(Self);
  FContrapartidas.Connection := FConexion;
  FContrapartidas.ReadOnly := True;
  ConfigurarAsientos;
  ConfigurarLineas;
end;

function TdmLibroDiario.BuscarDocumentosFaltantes: string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if not FAsientos.IsEmpty then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT GROUP_CONCAT(DISTINCT L.DOCUMENTO_ASILIN ' +
        'ORDER BY L.DOCUMENTO_ASILIN SEPARATOR '', '') AS FALTANTES ' +
        'FROM cza_asientos_lineas L ' +
        'WHERE L.ID_ASI_ASILIN = :ID ' +
        'AND COALESCE(TRIM(L.DOCUMENTO_ASILIN), '''') <> '''' ' +
        'AND NOT EXISTS (' +
        '  SELECT 1 FROM cza_documentos D ' +
        '  WHERE D.CODIGO_EMP_DOC = :EMPRESA ' +
        '    AND D.EJERCICIO_DOC = :EJERCICIO ' +
        '    AND D.REFERENCIA_DOC = L.DOCUMENTO_ASILIN' +
        ')';
      oConsulta.ParamByName('ID').AsLargeInt :=
        FAsientos.FieldByName('ID_ASI').AsLargeInt;
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.Open;
      Result := oConsulta.FieldByName('FALTANTES').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmLibroDiario.CargarContrapartidas(const ACuenta: string);
begin
  FContrapartidas.Close;
  if Trim(ACuenta) <> '' then
  begin
    FContrapartidas.SQL.Text :=
      'SELECT S.CODIGO_CTA, C.NOMBRE_CTA, ' +
      '       SUM(S.PUNTUACION) AS RELEVANCIA, ' +
      '       GROUP_CONCAT(DISTINCT S.ORIGEN ' +
      '         ORDER BY S.ORIGEN SEPARATOR '', '') AS ORIGEN ' +
      'FROM (' +
      '  SELECT C2.CODIGO_CTA, 1000 + R.PRIORIDAD_REG AS PUNTUACION, ' +
      '         ''REGLA'' AS ORIGEN ' +
      '  FROM cza_reglas_contrapartida R ' +
      '  JOIN cza_cuentas C2 ON C2.CODIGO_EMP_CTA = R.CODIGO_EMP_REG ' +
      '   AND C2.EJERCICIO_CTA = R.EJERCICIO_REG ' +
      '   AND C2.CODIGO_CTA LIKE CONCAT(R.PREFIJO_DESTINO_REG, ''%'') ' +
      '   AND C2.ESIMPUTABLE_CTA = ''S'' AND C2.ESACTIVO_CTA = ''S'' ' +
      '  WHERE R.CODIGO_EMP_REG = :EMPRESA ' +
      '    AND R.EJERCICIO_REG = :EJERCICIO ' +
      '    AND :CUENTA LIKE CONCAT(R.PREFIJO_ORIGEN_REG, ''%'') ' +
      '    AND R.ESACTIVO_REG = ''S'' ' +
      '  UNION ALL ' +
      '  SELECT L2.CODIGO_CTA_ASILIN, COUNT(*) * 10, ''HISTÓRICO'' ' +
      '  FROM cza_asientos A ' +
      '  JOIN cza_asientos_lineas L1 ON L1.ID_ASI_ASILIN = A.ID_ASI ' +
      '  JOIN cza_asientos_lineas L2 ON L2.ID_ASI_ASILIN = A.ID_ASI ' +
      '   AND L2.ID_ASILIN <> L1.ID_ASILIN ' +
      '  WHERE A.CODIGO_EMP_ASI = :EMPRESA ' +
      '    AND A.EJERCICIO_ASI = :EJERCICIO ' +
      '    AND A.ESTADO_ASI <> ''ANULADO'' ' +
      '    AND L1.CODIGO_CTA_ASILIN = :CUENTA ' +
      '  GROUP BY L2.CODIGO_CTA_ASILIN' +
      ') S JOIN cza_cuentas C ON C.CODIGO_EMP_CTA = :EMPRESA ' +
      ' AND C.EJERCICIO_CTA = :EJERCICIO ' +
      ' AND C.CODIGO_CTA = S.CODIGO_CTA ' +
      'GROUP BY S.CODIGO_CTA, C.NOMBRE_CTA ' +
      'ORDER BY RELEVANCIA DESC, S.CODIGO_CTA LIMIT 12';
    FContrapartidas.ParamByName('EMPRESA').AsString := FEmpresa;
    FContrapartidas.ParamByName('EJERCICIO').AsInteger := FEjercicio;
    FContrapartidas.ParamByName('CUENTA').AsString := ACuenta;
    FContrapartidas.Open;
  end;
end;

procedure TdmLibroDiario.Abrir;
begin
  FAsientos.ParamByName('EMPRESA').AsString := FEmpresa;
  FAsientos.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  FAsientos.Open;
  CargarLineas;
end;

procedure TdmLibroDiario.Actualizar;
var
  iIdAsiento: Int64;
begin
  iIdAsiento := 0;
  if FAsientos.Active and (not FAsientos.IsEmpty) then
  begin
    iIdAsiento := FAsientos.FieldByName('ID_ASI').AsLargeInt;
  end;
  FLineas.Close;
  FAsientos.Close;
  Abrir;
  if iIdAsiento > 0 then
  begin
    FAsientos.Locate('ID_ASI', iIdAsiento, []);
  end;
end;

procedure TdmLibroDiario.AntesDeEditarLinea(DataSet: TDataSet);
begin
  ComprobarAsientoEditable;
end;

procedure TdmLibroDiario.AntesDeEliminarLinea(DataSet: TDataSet);
begin
  ComprobarAsientoEditable;
end;

procedure TdmLibroDiario.AntesDePublicarLinea(DataSet: TDataSet);
var
  oConsulta: TUniQuery;
begin
  ComprobarAsientoEditable;
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('ID_ASILIN').AsLargeInt :=
      FContadores.SiguienteNumero(
        'GLOBAL',
        0,
        'ID_APUNTE',
        '-');
    DataSet.FieldByName('ID_ASI_ASILIN').AsLargeInt :=
      FAsientos.FieldByName('ID_ASI').AsLargeInt;
    DataSet.FieldByName('LINEA_ASILIN').AsInteger := SiguienteLinea;
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString :=
      GetEnvironmentVariable('USERNAME');
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString :=
    GetEnvironmentVariable('USERNAME');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM cza_cuentas ' +
      'WHERE CODIGO_EMP_CTA = :EMPRESA ' +
      'AND EJERCICIO_CTA = :EJERCICIO ' +
      'AND CODIGO_CTA = :CUENTA ' +
      'AND ESIMPUTABLE_CTA = ''S'' AND ESACTIVO_CTA = ''S'' LIMIT 1';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
    oConsulta.ParamByName('CUENTA').AsString :=
      DataSet.FieldByName('CODIGO_CTA_ASILIN').AsString;
    oConsulta.Open;
    if oConsulta.IsEmpty then
    begin
      raise EDatabaseError.Create(
        'La cuenta indicada no existe o no admite apuntes.');
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmLibroDiario.AsientoCambiado(DataSet: TDataSet);
begin
  CargarLineas;
end;

procedure TdmLibroDiario.CargarLineas;
begin
  FLineas.Close;
  if FAsientos.Active and (not FAsientos.IsEmpty) then
  begin
    FLineas.ParamByName('ID_ASIENTO').AsLargeInt :=
      FAsientos.FieldByName('ID_ASI').AsLargeInt;
    FLineas.Open;
  end;
end;

function TdmLibroDiario.CerrarAsiento: TResultadoValidacionAsiento;
var
  oConsulta: TUniQuery;
begin
  if FLineas.State in dsEditModes then
  begin
    FLineas.Post;
  end;
  Result := TValidadorAsientos.Validar(LeerLineas);
  if Result.EsValido then
  begin
    Result.Mensaje := BuscarDocumentosFaltantes;
    if Result.Mensaje <> '' then
    begin
      Result.Estado := evaDocumentoNoArchivado;
      Result.Mensaje :=
        'Falta archivar el PDF de estas referencias: ' +
        Result.Mensaje + '.';
    end;
  end;
  if Result.EsValido then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'UPDATE cza_asientos SET ESTADO_ASI = ''CERRADO'', ' +
        'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
        'WHERE ID_ASI = :ID AND ESTADO_ASI = ''BORRADOR''';
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ParamByName('ID').AsLargeInt :=
        FAsientos.FieldByName('ID_ASI').AsLargeInt;
      oConsulta.ExecSQL;
    finally
      FreeAndNil(oConsulta);
    end;
    Actualizar;
  end;
end;

procedure TdmLibroDiario.ComprobarAsientoEditable;
begin
  if FAsientos.IsEmpty or
     (FAsientos.FieldByName('ESTADO_ASI').AsString <> 'BORRADOR') then
  begin
    raise EDatabaseError.Create(
      'Solo se pueden modificar asientos en borrador.');
  end;
end;

procedure TdmLibroDiario.ConfigurarAsientos;
begin
  FAsientos.ReadOnly := True;
  FAsientos.SQL.Text :=
    'SELECT ID_ASI, CODIGO_EMP_ASI, EJERCICIO_ASI, NUMERO_ASI, ' +
    '       FECHA_ASI, CONCEPTO_ASI, ESTADO_ASI, ' +
    '       SISTEMA_ORIGEN_ASI, TIPO_DOCUMENTO_ORIGEN_ASI, ' +
    '       CLAVE_DOCUMENTO_ORIGEN_ASI, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '       INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_asientos ' +
    ' WHERE CODIGO_EMP_ASI = :EMPRESA ' +
    '   AND EJERCICIO_ASI = :EJERCICIO ' +
    ' ORDER BY FECHA_ASI DESC, NUMERO_ASI DESC';
  FAsientos.AfterScroll := AsientoCambiado;
end;

procedure TdmLibroDiario.ConfigurarLineas;
begin
  FLineas.SQL.Text :=
    'SELECT ID_ASILIN, ID_ASI_ASILIN, LINEA_ASILIN, ' +
    '       CODIGO_CTA_ASILIN, CONCEPTO_ASILIN, ' +
    '       IMPORTE_DEBE_ASILIN, IMPORTE_HABER_ASILIN, ' +
    '       DOCUMENTO_ASILIN, CODIGO_TERCERO_ASILIN, ' +
    '       INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_asientos_lineas ' +
    ' WHERE ID_ASI_ASILIN = :ID_ASIENTO ' +
    ' ORDER BY LINEA_ASILIN';
  FLineas.SQLInsert.Text :=
    'INSERT INTO cza_asientos_lineas (' +
    'ID_ASILIN, ID_ASI_ASILIN, LINEA_ASILIN, CODIGO_CTA_ASILIN, ' +
    'CONCEPTO_ASILIN, IMPORTE_DEBE_ASILIN, IMPORTE_HABER_ASILIN, ' +
    'DOCUMENTO_ASILIN, CODIGO_TERCERO_ASILIN, INSTANTE_ALTA, ' +
    'USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) VALUES (' +
    ':ID_ASILIN, :ID_ASI_ASILIN, :LINEA_ASILIN, :CODIGO_CTA_ASILIN, ' +
    ':CONCEPTO_ASILIN, :IMPORTE_DEBE_ASILIN, :IMPORTE_HABER_ASILIN, ' +
    ':DOCUMENTO_ASILIN, :CODIGO_TERCERO_ASILIN, :INSTANTE_ALTA, ' +
    ':USUARIO_ALTA, :INSTANTE_MODIF, :USUARIO_MODIF)';
  FLineas.SQLUpdate.Text :=
    'UPDATE cza_asientos_lineas SET ' +
    'CODIGO_CTA_ASILIN = :CODIGO_CTA_ASILIN, ' +
    'CONCEPTO_ASILIN = :CONCEPTO_ASILIN, ' +
    'IMPORTE_DEBE_ASILIN = :IMPORTE_DEBE_ASILIN, ' +
    'IMPORTE_HABER_ASILIN = :IMPORTE_HABER_ASILIN, ' +
    'DOCUMENTO_ASILIN = :DOCUMENTO_ASILIN, ' +
    'CODIGO_TERCERO_ASILIN = :CODIGO_TERCERO_ASILIN, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_ASILIN = :Old_ID_ASILIN';
  FLineas.SQLDelete.Text :=
    'DELETE FROM cza_asientos_lineas ' +
    'WHERE ID_ASILIN = :Old_ID_ASILIN';
  FLineas.BeforeEdit := AntesDeEditarLinea;
  FLineas.BeforeDelete := AntesDeEliminarLinea;
  FLineas.BeforePost := AntesDePublicarLinea;
end;

procedure TdmLibroDiario.CrearAsiento(
  AFecha: TDate;
  const AConcepto: string);
var
  oConsulta: TUniQuery;
  iNumero: Int64;
  iIdAsiento: Int64;
begin
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      iNumero := FContadores.SiguienteNumero(
        FEmpresa,
        FEjercicio,
        'ASIENTO',
        '-');
      iIdAsiento := FContadores.SiguienteNumero(
        'GLOBAL',
        0,
        'ID_ASIENTO',
        '-');
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'INSERT INTO cza_asientos (' +
        'ID_ASI, CODIGO_EMP_ASI, EJERCICIO_ASI, NUMERO_ASI, FECHA_ASI, ' +
        'CONCEPTO_ASI, ESTADO_ASI, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'VALUES (:ID, :EMPRESA, :EJERCICIO, :NUMERO, :FECHA, ' +
        ':CONCEPTO, ''BORRADOR'', NOW(), :USUARIO)';
      oConsulta.ParamByName('ID').AsLargeInt := iIdAsiento;
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.ParamByName('NUMERO').AsLargeInt := iNumero;
      oConsulta.ParamByName('FECHA').AsDate := AFecha;
      oConsulta.ParamByName('CONCEPTO').AsString := AConcepto;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  Actualizar;
  FAsientos.Locate('ID_ASI', iIdAsiento, []);
end;

procedure TdmLibroDiario.CrearLinea;
begin
  ComprobarAsientoEditable;
  FLineas.Append;
  FLineas.FieldByName('IMPORTE_DEBE_ASILIN').AsCurrency := 0;
  FLineas.FieldByName('IMPORTE_HABER_ASILIN').AsCurrency := 0;
end;

destructor TdmLibroDiario.Destroy;
begin
  FContadores := nil;
  inherited;
end;

function TdmLibroDiario.LeerLineas: TArray<TLineaAsiento>;
var
  iIndice: Integer;
begin
  SetLength(Result, FLineas.RecordCount);
  iIndice := 0;
  FLineas.DisableControls;
  try
    FLineas.First;
    while not FLineas.Eof do
    begin
      Result[iIndice].Cuenta :=
        FLineas.FieldByName('CODIGO_CTA_ASILIN').AsString;
      Result[iIndice].Concepto :=
        FLineas.FieldByName('CONCEPTO_ASILIN').AsString;
      Result[iIndice].Debe :=
        FLineas.FieldByName('IMPORTE_DEBE_ASILIN').AsCurrency;
      Result[iIndice].Haber :=
        FLineas.FieldByName('IMPORTE_HABER_ASILIN').AsCurrency;
      Inc(iIndice);
      FLineas.Next;
    end;
  finally
    FLineas.EnableControls;
  end;
end;

procedure TdmLibroDiario.ReabrirAsiento;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'UPDATE cza_asientos SET ESTADO_ASI = ''BORRADOR'', ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_ASI = :ID AND ESTADO_ASI = ''CERRADO''';
    oConsulta.ParamByName('USUARIO').AsString :=
      GetEnvironmentVariable('USERNAME');
    oConsulta.ParamByName('ID').AsLargeInt :=
      FAsientos.FieldByName('ID_ASI').AsLargeInt;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
  Actualizar;
end;

function TdmLibroDiario.SiguienteLinea: Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COALESCE(MAX(LINEA_ASILIN), 0) + 10 AS SIGUIENTE ' +
      'FROM cza_asientos_lineas WHERE ID_ASI_ASILIN = :ID';
    oConsulta.ParamByName('ID').AsLargeInt :=
      FAsientos.FieldByName('ID_ASI').AsLargeInt;
    oConsulta.Open;
    Result := oConsulta.FieldByName('SIGUIENTE').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
