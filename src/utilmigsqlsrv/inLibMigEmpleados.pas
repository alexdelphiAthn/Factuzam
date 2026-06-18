{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigEmpleados                                             }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los vendedores legacy de `dbo.ocemp` a `fza_empleados`.             }
{                                                                              }
{    fza_empleados es el maestro de vendedores/empleados de caja y no se       }
{    mezcla con fza_usuarios. Si el código ya existe, solo se rellenan campos  }
{    vacíos para conservar ajustes manuales o seeds ya existentes.             }
{******************************************************************************}
unit inLibMigEmpleados;

interface

uses
  UMigEngine;

procedure MigrarEmpleados(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni;

const
  cCamposDestino =
    'CODIGO_EMPL, NOMBRE_EMPL, RAZON_SOCIAL_EMPL, NIF_EMPL, ' +
    'DIRECCION_EMPL, DIRECCION2_EMPL, CODIGO_POSTAL_EMPL, ' +
    'POBLACION_EMPL, PROVINCIA_EMPL, TELEFONO_EMPL, TELEFONO2_EMPL, ' +
    'FAX_EMPL, EMAIL_EMPL, WEB_EMPL, IBAN_EMPL, BIC_EMPL, ' +
    'DIMINUTIVO_TICKET_EMPL, ESACTIVO_EMPL, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cInsertDst =
    'INSERT INTO fza_empleados (' + cCamposDestino + ') VALUES (' +
    ':CODIGO_EMPL, :NOMBRE_EMPL, :RAZON_SOCIAL_EMPL, :NIF_EMPL, ' +
    ':DIRECCION_EMPL, :DIRECCION2_EMPL, :CODIGO_POSTAL_EMPL, ' +
    ':POBLACION_EMPL, :PROVINCIA_EMPL, :TELEFONO_EMPL, :TELEFONO2_EMPL, ' +
    ':FAX_EMPL, :EMAIL_EMPL, :WEB_EMPL, :IBAN_EMPL, :BIC_EMPL, ' +
    ':DIMINUTIVO_TICKET_EMPL, :ESACTIVO_EMPL, ' +
    ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cUpdateDst =
    'UPDATE fza_empleados SET ' +
    'NOMBRE_EMPL = IF(' +
      '(LENGTH(TRIM(COALESCE(NOMBRE_EMPL, CHAR(32)))) = 0) OR ' +
      '(TRIM(NOMBRE_EMPL) = CODIGO_EMPL) OR ' +
      '(TRIM(NOMBRE_EMPL) = CONCAT(''Vendedor '', CODIGO_EMPL)), ' +
      ':NOMBRE_EMPL, NOMBRE_EMPL), ' +
    'RAZON_SOCIAL_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(RAZON_SOCIAL_EMPL, CHAR(32)))) = 0, ' +
      ':RAZON_SOCIAL_EMPL, RAZON_SOCIAL_EMPL), ' +
    'NIF_EMPL = IF(LENGTH(TRIM(COALESCE(NIF_EMPL, CHAR(32)))) = 0, ' +
      ':NIF_EMPL, NIF_EMPL), ' +
    'DIRECCION_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(DIRECCION_EMPL, CHAR(32)))) = 0, ' +
      ':DIRECCION_EMPL, DIRECCION_EMPL), ' +
    'DIRECCION2_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(DIRECCION2_EMPL, CHAR(32)))) = 0, ' +
      ':DIRECCION2_EMPL, DIRECCION2_EMPL), ' +
    'CODIGO_POSTAL_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(CODIGO_POSTAL_EMPL, CHAR(32)))) = 0, ' +
      ':CODIGO_POSTAL_EMPL, CODIGO_POSTAL_EMPL), ' +
    'POBLACION_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(POBLACION_EMPL, CHAR(32)))) = 0, ' +
      ':POBLACION_EMPL, POBLACION_EMPL), ' +
    'PROVINCIA_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(PROVINCIA_EMPL, CHAR(32)))) = 0, ' +
      ':PROVINCIA_EMPL, PROVINCIA_EMPL), ' +
    'TELEFONO_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(TELEFONO_EMPL, CHAR(32)))) = 0, ' +
      ':TELEFONO_EMPL, TELEFONO_EMPL), ' +
    'TELEFONO2_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(TELEFONO2_EMPL, CHAR(32)))) = 0, ' +
      ':TELEFONO2_EMPL, TELEFONO2_EMPL), ' +
    'FAX_EMPL = IF(LENGTH(TRIM(COALESCE(FAX_EMPL, CHAR(32)))) = 0, ' +
      ':FAX_EMPL, FAX_EMPL), ' +
    'EMAIL_EMPL = IF(LENGTH(TRIM(COALESCE(EMAIL_EMPL, CHAR(32)))) = 0, ' +
      ':EMAIL_EMPL, EMAIL_EMPL), ' +
    'WEB_EMPL = IF(LENGTH(TRIM(COALESCE(WEB_EMPL, CHAR(32)))) = 0, ' +
      ':WEB_EMPL, WEB_EMPL), ' +
    'IBAN_EMPL = IF(LENGTH(TRIM(COALESCE(IBAN_EMPL, CHAR(32)))) = 0, ' +
      ':IBAN_EMPL, IBAN_EMPL), ' +
    'BIC_EMPL = IF(LENGTH(TRIM(COALESCE(BIC_EMPL, CHAR(32)))) = 0, ' +
      ':BIC_EMPL, BIC_EMPL), ' +
    'DIMINUTIVO_TICKET_EMPL = IF(' +
      '(LENGTH(TRIM(COALESCE(DIMINUTIVO_TICKET_EMPL, CHAR(32)))) = 0) OR ' +
      '(TRIM(DIMINUTIVO_TICKET_EMPL) = CODIGO_EMPL), ' +
      ':DIMINUTIVO_TICKET_EMPL, DIMINUTIVO_TICKET_EMPL), ' +
    'ESACTIVO_EMPL = IF(' +
      'LENGTH(TRIM(COALESCE(ESACTIVO_EMPL, CHAR(32)))) = 0, ' +
      ':ESACTIVO_EMPL, ESACTIVO_EMPL) ' +
    'WHERE CODIGO_EMPL = :CODIGO_EMPL';

function Limitar(const sTexto: string; iMax: Integer): string;
begin
  Result := Copy(Trim(sTexto), 1, iMax);
end;

function DeducirActivo(const sEstado: string): string;
var
  s: string;
begin
  s := UpperCase(Trim(sEstado));
  if (s = 'B') or (s = 'N') then
    Result := 'N'
  else
    Result := 'S';
end;

procedure CargarCamposOcemp(Eng: TMigEngine; Campos: TStrings);
var
  q: TUniQuery;
begin
  q := NuevoQOrigen(Eng,
    'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''ocemp''');
  try
    q.Open;
    while not q.Eof do
    begin
      Campos.Values[UpperCase(q.FieldByName('COLUMN_NAME').AsString)] := 'S';
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

function CampoSelect(Campos: TStrings; const sCampo, sTipo: string): string;
begin
  if Campos.Values[UpperCase(sCampo)] = 'S' then
    Result := sCampo
  else
    Result := 'CAST(NULL AS ' + sTipo + ') AS ' + sCampo;
end;

function SQLSeleccionOcemp(Campos: TStrings): string;
begin
  Result :=
    'SELECT Empresa, ' +
    CampoSelect(Campos, 'RazonSocial', 'varchar(60)') + ', ' +
    CampoSelect(Campos, 'Nombre', 'varchar(60)') + ', ' +
    CampoSelect(Campos, 'NIF', 'varchar(15)') + ', ' +
    CampoSelect(Campos, 'Direccion1', 'varchar(60)') + ', ' +
    CampoSelect(Campos, 'Direccion2', 'varchar(60)') + ', ' +
    CampoSelect(Campos, 'CodPostal', 'varchar(10)') + ', ' +
    CampoSelect(Campos, 'Poblacion', 'varchar(30)') + ', ' +
    CampoSelect(Campos, 'Provincia', 'varchar(25)') + ', ' +
    CampoSelect(Campos, 'Telefono1', 'varchar(15)') + ', ' +
    CampoSelect(Campos, 'Telefono2', 'varchar(15)') + ', ' +
    CampoSelect(Campos, 'Fax', 'varchar(15)') + ', ' +
    CampoSelect(Campos, 'Email', 'varchar(50)') + ', ' +
    CampoSelect(Campos, 'Web', 'varchar(60)') + ', ' +
    CampoSelect(Campos, 'Estado', 'varchar(1)') + ', ' +
    CampoSelect(Campos, 'IBAN', 'varchar(35)') + ', ' +
    CampoSelect(Campos, 'BIC', 'varchar(11)') + ' ' +
    'FROM dbo.ocemp ORDER BY Empresa';
end;

procedure AsegurarEsquemaDestino(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_empleados'' ' +
      'AND COLUMN_NAME IN (''RAZON_SOCIAL_EMPL'', ''NIF_EMPL'', ' +
      '''DIRECCION2_EMPL'', ''CODIGO_POSTAL_EMPL'', ''POBLACION_EMPL'', ' +
      '''PROVINCIA_EMPL'', ''TELEFONO2_EMPL'', ''FAX_EMPL'', ' +
      '''EMAIL_EMPL'', ''WEB_EMPL'', ''IBAN_EMPL'', ''BIC_EMPL'')';
    q.Open;
    if q.FieldByName('N').AsInteger < 12 then
      raise Exception.Create(
        'Falta ejecutar DESARROLLOS EN CURSO/empleados_ampliar_ocemp.sql');
  finally
    q.Free;
  end;
end;

procedure AsignarParamsEmpleado(Q: TUniQuery; QSrc: TUniQuery;
  const sCod, sNombre, sDiminutivo: string);
begin
  Q.ParamByName('CODIGO_EMPL').AsString := sCod;
  Q.ParamByName('NOMBRE_EMPL').AsString := sNombre;
  Q.ParamByName('RAZON_SOCIAL_EMPL').AsString :=
    Limitar(QSrc.FieldByName('RazonSocial').AsString, 100);
  Q.ParamByName('NIF_EMPL').AsString :=
    Limitar(QSrc.FieldByName('NIF').AsString, 20);
  Q.ParamByName('DIRECCION_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Direccion1').AsString, 200);
  Q.ParamByName('DIRECCION2_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Direccion2').AsString, 200);
  Q.ParamByName('CODIGO_POSTAL_EMPL').AsString :=
    Limitar(QSrc.FieldByName('CodPostal').AsString, 10);
  Q.ParamByName('POBLACION_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Poblacion').AsString, 100);
  Q.ParamByName('PROVINCIA_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Provincia').AsString, 100);
  Q.ParamByName('TELEFONO_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Telefono1').AsString, 20);
  Q.ParamByName('TELEFONO2_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Telefono2').AsString, 20);
  Q.ParamByName('FAX_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Fax').AsString, 20);
  Q.ParamByName('EMAIL_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Email').AsString, 100);
  Q.ParamByName('WEB_EMPL').AsString :=
    Limitar(QSrc.FieldByName('Web').AsString, 200);
  Q.ParamByName('IBAN_EMPL').AsString :=
    Limitar(QSrc.FieldByName('IBAN').AsString, 35);
  Q.ParamByName('BIC_EMPL').AsString :=
    Limitar(QSrc.FieldByName('BIC').AsString, 11);
  Q.ParamByName('DIMINUTIVO_TICKET_EMPL').AsString := sDiminutivo;
  Q.ParamByName('ESACTIVO_EMPL').AsString :=
    DeducirActivo(QSrc.FieldByName('Estado').AsString);
end;

procedure MigrarEmpleados(Eng: TMigEngine; var Stats: TMigStats);
var
  Campos: TStringList;
  qSrc, qIns, qUpd, qChk: TUniQuery;
  sCod, sNombre, sDiminutivo, sNombreCorto: string;
begin
  AsegurarEsquemaDestino(Eng);
  Campos := TStringList.Create;
  qIns := TUniQuery.Create(nil);
  qUpd := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    Campos.CaseSensitive := False;
    CargarCamposOcemp(Eng, Campos);
    qSrc := NuevoQOrigen(Eng, SQLSeleccionOcemp(Campos));
    try
      qIns.Connection := Eng.ConDst;
      qIns.SQL.Text := cInsertDst;
      qUpd.Connection := Eng.ConDst;
      qUpd.SQL.Text := cUpdateDst;
      qChk.Connection := Eng.ConDst;
      qChk.SQL.Text :=
        'SELECT CODIGO_EMPL FROM fza_empleados WHERE CODIGO_EMPL = :c';
      Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocemp'));
      qSrc.Open;
      while not qSrc.Eof do
      begin
        Inc(Stats.Leidas);
        Eng.IncRow;
        sCod := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
        sNombre := Limitar(qSrc.FieldByName('Nombre').AsString, 100);
        if sNombre = '' then
          sNombre := Limitar(qSrc.FieldByName('RazonSocial').AsString, 100);
        if sNombre = '' then
          sNombre := 'Vendedor ' + sCod;
        sNombreCorto := Trim(qSrc.FieldByName('Nombre').AsString);
        if sNombreCorto = '' then
          sNombreCorto := Trim(qSrc.FieldByName('RazonSocial').AsString);
        sDiminutivo := Limitar(sNombreCorto, 10);
        qChk.Close;
        qChk.ParamByName('c').AsString := sCod;
        qChk.Open;
        if qChk.IsEmpty then
        begin
          AsignarParamsEmpleado(qIns, qSrc, sCod, sNombre, sDiminutivo);
          RellenarAuditoria(qIns, Eng.Usuario);
          qIns.ExecSQL;
          Inc(Stats.Insertadas);
        end
        else
        begin
          AsignarParamsEmpleado(qUpd, qSrc, sCod, sNombre, sDiminutivo);
          qUpd.ExecSQL;
          if qUpd.RowsAffected > 0 then
            Inc(Stats.Insertadas)
          else
            Inc(Stats.Saltadas);
        end;
        qSrc.Next;
      end;
    finally
      qSrc.Free;
    end;
  finally
    qChk.Free;
    qUpd.Free;
    qIns.Free;
    Campos.Free;
  end;
end;

end.
