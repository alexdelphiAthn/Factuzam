unit UniDataGenerarTicketRepositorio;

interface

uses
  Uni,
  inLibGenerarTicketIntf;

function CrearLecturasImpresionTicket(
  AConexion: TUniConnection): ILecturasImpresionTicket;

implementation

uses
  System.SysUtils, Data.DB, DBAccess;

const
  CAMPOS_PIE_TICKET_CAJA: array[0..3] of string = (
    'TEXTO_PIE_TICKET_CAJA_1_EMP',
    'TEXTO_PIE_TICKET_CAJA_2_EMP',
    'TEXTO_PIE_TICKET_CAJA_3_EMP',
    'TEXTO_PIE_TICKET_CAJA_4_EMP');

type
  TLecturasImpresionTicket = class(
    TInterfacedObject,
    ILecturasImpresionTicket)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function CamposPieDisponibles: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarPieCaja(
      const ACodigoEmpresa: string): TArray<string>;
    function ObtenerDiminutivoVendedor(
      const ACodigoEmpleado: string): string;
    function ObtenerCodigoBarras(
      const ASerie, ANumero: string): string;
  end;

function CrearLecturasImpresionTicket(
  AConexion: TUniConnection): ILecturasImpresionTicket;
begin
  Result := TLecturasImpresionTicket.Create(AConexion);
end;

constructor TLecturasImpresionTicket.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLecturasImpresionTicket.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TLecturasImpresionTicket.CamposPieDisponibles: Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if (FConexion <> nil) and FConexion.Connected then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_empresas'' ' +
        '   AND COLUMN_NAME IN (''TEXTO_PIE_TICKET_CAJA_1_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_2_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_3_EMP'', ' +
        '                       ''TEXTO_PIE_TICKET_CAJA_4_EMP'')';
      Consulta.Open;
      Result := Consulta.FieldByName('N').AsInteger = 4;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TLecturasImpresionTicket.ListarPieCaja(
  const ACodigoEmpresa: string): TArray<string>;
var
  Consulta: TUniQuery;
  Lineas: TArray<string>;
  Indice: Integer;
begin
  Result := nil;
  if (Trim(ACodigoEmpresa) <> '') and CamposPieDisponibles then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT TEXTO_PIE_TICKET_CAJA_1_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_2_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_3_EMP, ' +
        '       TEXTO_PIE_TICKET_CAJA_4_EMP ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :EMP';
      Consulta.ParamByName('EMP').AsString := ACodigoEmpresa;
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        SetLength(Lineas, Length(CAMPOS_PIE_TICKET_CAJA));
        for Indice := Low(CAMPOS_PIE_TICKET_CAJA) to
          High(CAMPOS_PIE_TICKET_CAJA) do
          Lineas[Indice] := Consulta.FieldByName(
            CAMPOS_PIE_TICKET_CAJA[Indice]).AsString;
        Result := Lineas;
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TLecturasImpresionTicket.ObtenerDiminutivoVendedor(
  const ACodigoEmpleado: string): string;
var
  Consulta: TUniQuery;
begin
  Result := ACodigoEmpleado;
  if (Trim(ACodigoEmpleado) <> '') and (FConexion <> nil) and
     FConexion.Connected then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT DIMINUTIVO_TICKET_EMPL' +
        '  FROM fza_empleados' +
        ' WHERE CODIGO_EMPL = :COD';
      Consulta.ParamByName('COD').AsString := ACodigoEmpleado;
      Consulta.Open;
      if (not Consulta.IsEmpty) and
         (Trim(Consulta.FieldByName(
           'DIMINUTIVO_TICKET_EMPL').AsString) <> '') then
        Result := Trim(Consulta.FieldByName(
          'DIMINUTIVO_TICKET_EMPL').AsString);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function TLecturasImpresionTicket.ObtenerCodigoBarras(
  const ASerie, ANumero: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') and
     (FConexion <> nil) and FConexion.Connected then
  begin
    Consulta := NuevaConsulta;
    try
      Consulta.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_facturas'' ' +
        '   AND COLUMN_NAME = ''CODIGO_BARRAS_FAC''';
      Consulta.Open;
      if Consulta.FieldByName('N').AsInteger > 0 then
      begin
        Consulta.Close;
        Consulta.SQL.Text :=
          'SELECT CODIGO_BARRAS_FAC ' +
          '  FROM fza_facturas ' +
          ' WHERE SERIE_FAC = :SERIE ' +
          '   AND NUMERO_FAC = :NUMERO';
        Consulta.ParamByName('SERIE').AsString := ASerie;
        Consulta.ParamByName('NUMERO').AsString := ANumero;
        Consulta.Open;
        if not Consulta.IsEmpty then
          Result := Trim(
            Consulta.FieldByName('CODIGO_BARRAS_FAC').AsString);
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

end.
