{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigEmpleados                                             }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los vendedores de dbo.ocven a fza_empleados. El diminutivo que     }
{    muestra caja y se imprime en el ticket procede de ocven.Abreviatura.      }
{    dbo.ocemp no interviene: contiene empresas, no empleados.                 }
{******************************************************************************}
unit inLibMigEmpleados;

interface

uses
  UMigEngine, UMigCatalogo;

procedure MigrarEmpleados(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

const
  cSelect =
    'SELECT Vendedor, Nombre, Direccion1, Direccion2, CodPostal, ' +
    '       Poblacion, Provincia, NIF, Telefono1, Telefono2, ' +
    '       TelefonoMovil, Fax, Email, IBAN, Abreviatura, Estado ' +
    'FROM dbo.ocven ORDER BY Vendedor';
  cInsert =
    'INSERT INTO fza_empleados (' +
    ' CODIGO_EMPL, NOMBRE_EMPL, RAZON_SOCIAL_EMPL, NIF_EMPL, ' +
    ' DIRECCION_EMPL, DIRECCION2_EMPL, CODIGO_POSTAL_EMPL, ' +
    ' POBLACION_EMPL, PROVINCIA_EMPL, TELEFONO_EMPL, TELEFONO2_EMPL, ' +
    ' FAX_EMPL, EMAIL_EMPL, WEB_EMPL, IBAN_EMPL, BIC_EMPL, ' +
    ' DIMINUTIVO_TICKET_EMPL, ESACTIVO_EMPL, ' +
    ' INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
    ' :codigo, :nombre, NULL, :nif, :direccion, :direccion2, :cp, ' +
    ' :poblacion, :provincia, :telefono, :telefono2, :fax, :email, ' +
    ' NULL, :iban, NULL, :diminutivo, :activo, ' +
    ' :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cUpdate =
    'UPDATE fza_empleados SET ' +
    ' NOMBRE_EMPL = :nombre, ' +
    ' RAZON_SOCIAL_EMPL = NULL, ' +
    ' NIF_EMPL = NULLIF(:nif, ''''), ' +
    ' DIRECCION_EMPL = NULLIF(:direccion, ''''), ' +
    ' DIRECCION2_EMPL = NULLIF(:direccion2, ''''), ' +
    ' CODIGO_POSTAL_EMPL = NULLIF(:cp, ''''), ' +
    ' POBLACION_EMPL = NULLIF(:poblacion, ''''), ' +
    ' PROVINCIA_EMPL = NULLIF(:provincia, ''''), ' +
    ' TELEFONO_EMPL = NULLIF(:telefono, ''''), ' +
    ' TELEFONO2_EMPL = NULLIF(:telefono2, ''''), ' +
    ' FAX_EMPL = NULLIF(:fax, ''''), ' +
    ' EMAIL_EMPL = NULLIF(:email, ''''), ' +
    ' IBAN_EMPL = NULLIF(:iban, ''''), ' +
    ' DIMINUTIVO_TICKET_EMPL = :diminutivo, ' +
    ' ESACTIVO_EMPL = :activo, ' +
    ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :usuario_modif ' +
    'WHERE CODIGO_EMPL = :codigo';

function Limitar(const sTexto: string; iMaximo: Integer): string;
begin
  Result := Copy(Trim(sTexto), 1, iMaximo);
end;

function DeducirActivo(const sEstado: string): string;
var
  sValor: string;
begin
  sValor := UpperCase(Trim(sEstado));
  if (sValor = 'B') or (sValor = 'N') then
    Result := 'N'
  else
    Result := 'S';
end;

procedure AsignarParametros(Q, QOrigen: TUniQuery; const sCodigo: string);
var
  sNombre, sDiminutivo, sTelefono: string;
begin
  sNombre := Limitar(QOrigen.FieldByName('Nombre').AsString, 100);
  if sNombre = '' then
    sNombre := 'Vendedor ' + sCodigo;
  sDiminutivo := Limitar(QOrigen.FieldByName('Abreviatura').AsString, 10);
  if sDiminutivo = '' then
    sDiminutivo := Limitar(sNombre, 10);
  sTelefono := Limitar(QOrigen.FieldByName('TelefonoMovil').AsString, 20);
  if sTelefono = '' then
    sTelefono := Limitar(QOrigen.FieldByName('Telefono1').AsString, 20);
  Q.ParamByName('codigo').AsString := sCodigo;
  Q.ParamByName('nombre').AsString := sNombre;
  Q.ParamByName('nif').AsString :=
    Limitar(QOrigen.FieldByName('NIF').AsString, 20);
  Q.ParamByName('direccion').AsString :=
    Limitar(QOrigen.FieldByName('Direccion1').AsString, 200);
  Q.ParamByName('direccion2').AsString :=
    Limitar(QOrigen.FieldByName('Direccion2').AsString, 200);
  Q.ParamByName('cp').AsString :=
    Limitar(QOrigen.FieldByName('CodPostal').AsString, 10);
  Q.ParamByName('poblacion').AsString :=
    Limitar(QOrigen.FieldByName('Poblacion').AsString, 100);
  Q.ParamByName('provincia').AsString :=
    Limitar(QOrigen.FieldByName('Provincia').AsString, 100);
  Q.ParamByName('telefono').AsString := sTelefono;
  Q.ParamByName('telefono2').AsString :=
    Limitar(QOrigen.FieldByName('Telefono2').AsString, 20);
  Q.ParamByName('fax').AsString :=
    Limitar(QOrigen.FieldByName('Fax').AsString, 20);
  Q.ParamByName('email').AsString :=
    Limitar(QOrigen.FieldByName('Email').AsString, 100);
  Q.ParamByName('iban').AsString :=
    Limitar(QOrigen.FieldByName('IBAN').AsString, 35);
  Q.ParamByName('diminutivo').AsString := sDiminutivo;
  Q.ParamByName('activo').AsString :=
    DeducirActivo(QOrigen.FieldByName('Estado').AsString);
end;

procedure MigrarEmpleados(const Eng: IContextoMigracion; var Stats: TMigStats);
var
  qOrigen, qInsertar, qActualizar, qExiste, qLimpiar: TUniQuery;
  sCodigo: string;
begin
  qOrigen := NuevoQOrigen(Eng, cSelect);
  qInsertar := TUniQuery.Create(nil);
  qActualizar := TUniQuery.Create(nil);
  qExiste := TUniQuery.Create(nil);
  qLimpiar := TUniQuery.Create(nil);
  try
    qInsertar.Connection := Eng.Datos.ConexionDestino;
    qInsertar.SQL.Text := cInsert;
    qActualizar.Connection := Eng.Datos.ConexionDestino;
    qActualizar.SQL.Text := cUpdate;
    qExiste.Connection := Eng.Datos.ConexionDestino;
    qExiste.SQL.Text :=
      'SELECT 1 FROM fza_empleados WHERE CODIGO_EMPL = :codigo';
    // Elimina filas creadas por versiones anteriores del dominio, incluida
    // la empresa que se insertaba erroneamente como empleado.
    qLimpiar.Connection := Eng.Datos.ConexionDestino;
    qLimpiar.SQL.Text :=
      'DELETE FROM fza_empleados WHERE USUARIO_ALTA = :usuario';
    qLimpiar.ParamByName('usuario').AsString := Eng.Usuario;
    qLimpiar.ExecSQL;
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen('SELECT COUNT(*) FROM dbo.ocven'));
    qOrigen.Open;
    while not qOrigen.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      sCodigo := IntToStr(qOrigen.FieldByName('Vendedor').AsInteger);
      qExiste.Close;
      qExiste.ParamByName('codigo').AsString := sCodigo;
      qExiste.Open;
      if qExiste.IsEmpty then
      begin
        AsignarParametros(qInsertar, qOrigen, sCodigo);
        RellenarAuditoria(qInsertar, Eng.Usuario);
        qInsertar.ExecSQL;
        Inc(Stats.Insertadas);
      end
      else
      begin
        AsignarParametros(qActualizar, qOrigen, sCodigo);
        qActualizar.ParamByName('usuario_modif').AsString := Eng.Usuario;
        qActualizar.ExecSQL;
        Inc(Stats.Saltadas);
      end;
      qOrigen.Next;
    end;
  finally
    qLimpiar.Free;
    qExiste.Free;
    qActualizar.Free;
    qInsertar.Free;
    qOrigen.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'empleados',
    'Empleados / vendedores (ocven)',
    'dbo.ocven → fza_empleados (Abreviatura → diminutivo de caja)',
    [],
    MigrarEmpleados);

end.
