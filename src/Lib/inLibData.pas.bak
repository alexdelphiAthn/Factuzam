unit inLibData;

interface
uses
  Uni,inLibGlobalVar, System.SysUtils;

function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;

implementation

function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
var
  QryAlm: TUniQuery;
begin
  Result := '';
  QryAlm := TUniQuery.Create(nil);
  try
    // Usamos la conexión global del sistema
    QryAlm.Connection := inLibGlobalVar.oConn;
    QryAlm.SQL.Text :=
      'SELECT CODIGO_ALMACEN_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE CODIGO_EMPRESA_ALM = :EMP ' +
      '   AND ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''DEPÓSITO'' ' + // <-- Usando tu flag real
      ' LIMIT 1';
    QryAlm.ParamByName('EMP').AsString := AEmpresa;
    QryAlm.Open;
    if not QryAlm.IsEmpty then
      Result := QryAlm.FieldByName('CODIGO_ALMACEN_ALM').AsString
    else
      // Lanzamos excepción para que la transacción de caja se detenga si hay un error de configuración
      raise Exception.Create('No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ''DEPÓSITO'') activo para la empresa ' + AEmpresa + '.');
  finally
    QryAlm.Free;
  end;
end;


end.
