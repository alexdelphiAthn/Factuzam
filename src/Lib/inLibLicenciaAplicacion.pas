{******************************************************************************}
{                                                                              }
{  Modulo:       inLibLicenciaAplicacion                                       }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       16/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Registro y validacion de la licencia local de Factuzam.                   }
{******************************************************************************}
unit inLibLicenciaAplicacion;

interface

uses
  SysUtils, Classes, Uni;

type
  TEstadoLicenciaAplicacion = (elaValida,
                               elaInvalida,
                               elaNoEncontrada,
                               elaSinNifEmpresa);

  TResultadoLicenciaAplicacion = record
    Comprobada: Boolean;
    BBDD: string;
    Estado: TEstadoLicenciaAplicacion;
    Mensaje: string;
    class function CrearNoComprobada:
      TResultadoLicenciaAplicacion; static;
    class function Crear(
      AComprobada: Boolean;
      const ABBDD: string;
      AEstado: TEstadoLicenciaAplicacion;
      const AMensaje: string): TResultadoLicenciaAplicacion; static;
  end;

const
  LIMITE_FACTURAS_DEMO_DIA     = 10;

function RutaIniLicenciaAplicacion: string;
function RegistrarLicenciaAplicacion(AConexion: TUniConnection;
                                     out ACodigo: string;
                                     out ANumeroNifs: Integer;
                                     out ADetalleNifs: string;
                                     out ARutaIni: string): Boolean;
function ComprobarLicenciaAplicacion(AConexion: TUniConnection;
                                     out AEstado: TEstadoLicenciaAplicacion;
                                     out AMensaje: string;
                                     out ACodigoEsperado: string;
                                     out ACodigoGuardado: string): Boolean;
function HayConmutadorRegistroLicencia: Boolean;
function EstadoLicenciaEsDemo(AEstado: TEstadoLicenciaAplicacion): Boolean;
function ContarFacturasDemoDia(AConexion: TUniConnection;
                               AFecha: TDateTime): Integer;
procedure ValidarLimiteDemoFacturas(AConexion: TUniConnection;
                                    AEstado: TEstadoLicenciaAplicacion;
                                    AFecha: TDateTime);

implementation

uses
  DB, MemDS, DBAccess, IniFiles, Math, System.Hash, inLibDir;

class function TResultadoLicenciaAplicacion.CrearNoComprobada:
  TResultadoLicenciaAplicacion;
begin
  Result := Crear(False, '', elaInvalida, '');
end;

class function TResultadoLicenciaAplicacion.Crear(
  AComprobada: Boolean;
  const ABBDD: string;
  AEstado: TEstadoLicenciaAplicacion;
  const AMensaje: string): TResultadoLicenciaAplicacion;
begin
  Result.Comprobada := AComprobada;
  Result.BBDD := ABBDD;
  Result.Estado := AEstado;
  Result.Mensaje := AMensaje;
end;

const
  CLAVE_MAESTRA_LICENCIA = 'Fzam_Tarabudillo_2026_Private!';
  SECCION_LICENCIA       = 'License';
  CLAVE_CODIGO           = 'Code';
  HASH_CONMUTADOR_REG    =
    '636846B83B12EC337655B2DBB30A4FDD0A38D7FF681C3A102C513614951F05F9';

function ParametroIniAplicacion: string;
begin
  Result := Trim(ParamStr(1));
  if (Result <> '') and CharInSet(Result[1], ['/', '-']) then
    Result := '';
end;

function NormalizarConmutador(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
  while (Result <> '') and CharInSet(Result[1], ['/', '-']) do
    Delete(Result, 1, 1);
end;

function HayConmutadorRegistroLicencia: Boolean;
var
  i: Integer;
  sParametro: string;
  sHash: string;
begin
  Result := False;
  i := 1;
  while (i <= ParamCount) and not Result do
  begin
    sParametro := NormalizarConmutador(ParamStr(i));
    if sParametro <> '' then
    begin
      sHash := THashSHA2.GetHashString(sParametro);
      Result := SameText(sHash, HASH_CONMUTADOR_REG);
    end;
    Inc(i);
  end;
end;

function EstadoLicenciaEsDemo(AEstado: TEstadoLicenciaAplicacion): Boolean;
begin
  Result := (AEstado = elaInvalida) or (AEstado = elaNoEncontrada);
end;

function ContarFacturasDemoDia(AConexion: TUniConnection;
                               AFecha: TDateTime): Integer;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL ' +
      '  FROM fza_facturas ' +
      ' WHERE FECHA_FAC = :FECHA';
    Qry.ParamByName('FECHA').AsDate := Trunc(AFecha);
    Qry.Open;
    Result := Qry.FieldByName('TOTAL').AsInteger;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure ValidarLimiteDemoFacturas(AConexion: TUniConnection;
                                    AEstado: TEstadoLicenciaAplicacion;
                                    AFecha: TDateTime);
var
  iFacturas: Integer;
begin
  if (AConexion <> nil) and AConexion.Connected and
     EstadoLicenciaEsDemo(AEstado) then
  begin
    iFacturas := ContarFacturasDemoDia(AConexion, AFecha);
    if iFacturas >= LIMITE_FACTURAS_DEMO_DIA then
    begin
      raise Exception.Create(
        'Límite DEMO.' + sLineBreak + sLineBreak +
        'Ya se han emitido ' + IntToStr(iFacturas) + ' facturas el día ' +
        FormatDateTime('dd/mm/yyyy', AFecha) + '.' + sLineBreak +
        'El límite de la copia DEMO es ' +
        IntToStr(LIMITE_FACTURAS_DEMO_DIA) + ' facturas al día.');
    end;
  end;
end;

function RutaIniLicenciaAplicacion: string;
var
  sParametroIni: string;
begin
  sParametroIni := ParametroIniAplicacion;
  if sParametroIni = '' then
    Result := IncludeTrailingPathDelimiter(GetUserFolder) +
              ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini')
  else
    Result := IncludeTrailingPathDelimiter(GetUserFolder) + sParametroIni;
end;

function NormalizarNifLicencia(const ANif: string): string;
begin
  Result := UpperCase(Trim(ANif));
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := StringReplace(Result, '.', '', [rfReplaceAll]);
end;

function GenerarCadenaNifs(ANifs: TStrings): string;
var
  i: Integer;
  ListaOrdenada: TStringList;
begin
  Result := '';
  ListaOrdenada := TStringList.Create;
  try
    ListaOrdenada.Sorted := True;
    ListaOrdenada.Duplicates := dupIgnore;
    for i := 0 to ANifs.Count - 1 do
    begin
      if NormalizarNifLicencia(ANifs[i]) <> '' then
        ListaOrdenada.Add(NormalizarNifLicencia(ANifs[i]));
    end;
    for i := 0 to ListaOrdenada.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + '|';
      Result := Result + ListaOrdenada[i];
    end;
  finally
    FreeAndNil(ListaOrdenada);
  end;
end;

function HashACodigoCorto(const AHash: string; ADigitos: Integer): string;
var
  i: Integer;
  iValor: Int64;
  sHex: string;
begin
  sHex := Copy(AHash, 1, 12);
  iValor := 0;
  for i := 1 to Length(sHex) do
  begin
    iValor := iValor * 16;
    case sHex[i] of
      '0'..'9':
        iValor := iValor + Ord(sHex[i]) - Ord('0');
      'A'..'F':
        iValor := iValor + Ord(sHex[i]) - Ord('A') + 10;
      'a'..'f':
        iValor := iValor + Ord(sHex[i]) - Ord('a') + 10;
    end;
  end;
  iValor := iValor mod Round(Power(10, ADigitos));
  Result := Format('%.' + IntToStr(ADigitos) + 'd', [iValor]);
end;

function GenerarCodigoLicencia(ANifs: TStrings): string;
var
  sHash: string;
  sNifs: string;
begin
  sNifs := GenerarCadenaNifs(ANifs);
  sHash := THashSHA2.GetHashString(sNifs + CLAVE_MAESTRA_LICENCIA);
  Result := HashACodigoCorto(sHash, 6);
end;

procedure CargarNifsEmpresas(AConexion: TUniConnection; ANifs: TStrings);
var
  Qry: TUniQuery;
  sNif: string;
begin
  ANifs.Clear;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConexion;
    Qry.SQL.Text :=
      'SELECT DISTINCT TRIM(NIF_EMP) AS NIF_EMP ' +
      '  FROM fza_empresas ' +
      ' WHERE IFNULL(TRIM(NIF_EMP), '''') <> '''' ' +
      ' ORDER BY NIF_EMP';
    Qry.Open;
    while not Qry.Eof do
    begin
      sNif := Trim(Qry.FieldByName('NIF_EMP').AsString);
      if sNif <> '' then
        ANifs.Add(sNif);
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function NifsComoTexto(ANifs: TStrings): string;
var
  i: Integer;
  Lista: TStringList;
begin
  Lista := TStringList.Create;
  try
    for i := 0 to ANifs.Count - 1 do
      Lista.Add(Format('%d. %s', [i + 1, ANifs[i]]));
    Result := Lista.Text;
  finally
    FreeAndNil(Lista);
  end;
end;

function LeerCodigoLicencia: string;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIniLicenciaAplicacion);
  try
    Result := Trim(Ini.ReadString(SECCION_LICENCIA, CLAVE_CODIGO, ''));
  finally
    FreeAndNil(Ini);
  end;
end;

procedure EscribirCodigoLicencia(const ACodigo: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIniLicenciaAplicacion);
  try
    Ini.WriteString(SECCION_LICENCIA, CLAVE_CODIGO, ACodigo);
  finally
    FreeAndNil(Ini);
  end;
end;

function RegistrarLicenciaAplicacion(AConexion: TUniConnection;
                                     out ACodigo: string;
                                     out ANumeroNifs: Integer;
                                     out ADetalleNifs: string;
                                     out ARutaIni: string): Boolean;
var
  Nifs: TStringList;
begin
  Result := False;
  ACodigo := '';
  ANumeroNifs := 0;
  ADetalleNifs := '';
  ARutaIni := RutaIniLicenciaAplicacion;
  Nifs := TStringList.Create;
  try
    CargarNifsEmpresas(AConexion, Nifs);
    ANumeroNifs := Nifs.Count;
    if ANumeroNifs = 0 then
      ADetalleNifs := 'No hay NIF de empresa configurado.'
    else
    begin
      ACodigo := GenerarCodigoLicencia(Nifs);
      ADetalleNifs := NifsComoTexto(Nifs);
      EscribirCodigoLicencia(ACodigo);
      Result := True;
    end;
  finally
    FreeAndNil(Nifs);
  end;
end;

function ComprobarLicenciaAplicacion(AConexion: TUniConnection;
                                     out AEstado: TEstadoLicenciaAplicacion;
                                     out AMensaje: string;
                                     out ACodigoEsperado: string;
                                     out ACodigoGuardado: string): Boolean;
var
  Nifs: TStringList;
begin
  Result := False;
  AEstado := elaInvalida;
  AMensaje := '';
  ACodigoEsperado := '';
  ACodigoGuardado := '';
  Nifs := TStringList.Create;
  try
    CargarNifsEmpresas(AConexion, Nifs);
    if Nifs.Count = 0 then
    begin
      AEstado := elaSinNifEmpresa;
      AMensaje := 'No hay NIF de empresa; no se exige licencia.';
      Result := True;
    end
    else
    begin
      ACodigoGuardado := LeerCodigoLicencia;
      ACodigoEsperado := GenerarCodigoLicencia(Nifs);
      if ACodigoGuardado = '' then
      begin
        AEstado := elaNoEncontrada;
        AMensaje := 'No se encontró licencia de aplicación.';
      end
      else if SameText(ACodigoGuardado, ACodigoEsperado) then
      begin
        AEstado := elaValida;
        AMensaje := 'Licencia de aplicación válida.';
        Result := True;
      end
      else
      begin
        AEstado := elaInvalida;
        AMensaje := 'La licencia de aplicación no coincide con los NIF ' +
                    'de empresa configurados.';
      end;
    end;
  finally
    FreeAndNil(Nifs);
  end;
end;

end.
