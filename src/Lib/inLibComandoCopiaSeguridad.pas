{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComandoCopiaSeguridad                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Interpreta y valida el comando de copia de seguridad no interactiva.      }
{******************************************************************************}
unit inLibComandoCopiaSeguridad;

interface

uses
  System.SysUtils;

type
  TErrorComandoCopiaSeguridad = (
    eccsNinguno,
    eccsSintaxis,
    eccsRuta,
    eccsExtension,
    eccsClave
  );
  TClavesPredeterminadasCopiaSeguridad = record
    ClaveCifrada: string;
    Contrasena: string;
  end;
  TSolicitudComandoCopiaSeguridad = record
    EsComando: Boolean;
    EsValida: Boolean;
    Error: TErrorComandoCopiaSeguridad;
    RutaDestino: string;
    RutaRegistro: string;
    Contrasena: string;
  end;

function EsComandoCopiaSeguridad(
  const AParametros: TArray<string>
): Boolean;
function EsSintaxisComandoCopiaSeguridadValida(
  const AParametros: TArray<string>
): Boolean;
function ResolverPlantillaCopiaSeguridad(
  const APlantilla: string;
  AInstante: TDateTime
): string;
function CodificarClaveCifradaParaRuta(
  const AClaveCifrada: string
): string;
function InterpretarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad
): TSolicitudComandoCopiaSeguridad;

implementation

uses
  System.Character,
  System.StrUtils,
  inLibCifrado;

const
  CONMUTADOR_COPIA_SEGURIDAD = 'copiaseguridad';
  MARCADOR_CLAVE = 'CLAVE';
  MAXIMA_LONGITUD_RUTA = 259;
  DIAS_SEMANA: array[1..7] of string = (
    'domingo',
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado'
  );

function NormalizarConmutador(const AParametro: string): string;
begin
  Result := Trim(AParametro);
  while (Result <> '') and
        CharInSet(Result[1], ['/', '-']) do
  begin
    Delete(Result, 1, 1);
  end;
end;

function EsComandoCopiaSeguridad(
  const AParametros: TArray<string>): Boolean;
begin
  Result := Length(AParametros) > 0;
  if Result then
  begin
    Result := SameText(
      NormalizarConmutador(AParametros[0]),
      CONMUTADOR_COPIA_SEGURIDAD);
  end;
end;

function EsSintaxisComandoCopiaSeguridadValida(
  const AParametros: TArray<string>): Boolean;
begin
  Result := EsComandoCopiaSeguridad(AParametros) and
            (Length(AParametros) >= 2) and
            (Length(AParametros) <= 3);
  if Result then
    Result := Trim(AParametros[1]) <> '';
  if Result and (Length(AParametros) = 3) then
    Result := Trim(AParametros[2]) <> '';
end;

function EsCaracterIdentificador(ACaracter: Char): Boolean;
begin
  Result := ACaracter.IsLetterOrDigit;
end;

function ReemplazarTokenDelimitado(
  const ATexto, AToken, AValor: string): string;
var
  bDelimitadoDespues: Boolean;
  bDelimitadoAntes: Boolean;
  iPosicion: Integer;
  iSiguiente: Integer;
begin
  Result := ATexto;
  iSiguiente := 1;
  iPosicion := PosEx(AToken, Result, iSiguiente);
  while iPosicion > 0 do
  begin
    bDelimitadoAntes := (iPosicion = 1) or
      not EsCaracterIdentificador(Result[iPosicion - 1]);
    bDelimitadoDespues :=
      (iPosicion + Length(AToken) > Length(Result)) or
      not EsCaracterIdentificador(
        Result[iPosicion + Length(AToken)]);
    if bDelimitadoAntes and bDelimitadoDespues then
    begin
      Delete(Result, iPosicion, Length(AToken));
      Insert(AValor, Result, iPosicion);
      iSiguiente := iPosicion + Length(AValor);
    end
    else
      iSiguiente := iPosicion + Length(AToken);
    iPosicion := PosEx(AToken, Result, iSiguiente);
  end;
end;

function ReemplazarToken(
  const ATexto, AToken, AValor: string): string;
begin
  Result := StringReplace(
    ATexto,
    '{' + AToken + '}',
    AValor,
    [rfReplaceAll]);
  Result := ReemplazarTokenDelimitado(
    Result,
    AToken,
    AValor);
end;

function ResolverPlantillaCopiaSeguridad(
  const APlantilla: string;
  AInstante: TDateTime): string;
var
  iAnio: Word;
  iDia: Word;
  iMes: Word;
  sAnio: string;
  sDia: string;
  sDiaSemana: string;
  sMes: string;
begin
  DecodeDate(AInstante, iAnio, iMes, iDia);
  sDiaSemana := DIAS_SEMANA[DayOfWeek(AInstante)];
  sDia := Format('%.2d', [iDia]);
  sMes := Format('%.2d', [iMes]);
  sAnio := Format('%.4d', [iAnio]);
  Result := ReemplazarToken(
    APlantilla,
    'DIASEMANA',
    sDiaSemana);
  Result := ReemplazarToken(Result, 'DIAMES', sDia);
  Result := ReemplazarToken(Result, 'AÑO', sAnio);
  Result := StringReplace(
    Result,
    '{ANO}',
    sAnio,
    [rfReplaceAll]);
  Result := ReemplazarToken(Result, 'MES', sMes);
end;

function CodificarClaveCifradaParaRuta(
  const AClaveCifrada: string): string;
begin
  Result := StringReplace(
    AClaveCifrada,
    '%',
    '%25',
    [rfReplaceAll]);
  Result := StringReplace(Result, '+', '%2B', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '%2F', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '%3D', [rfReplaceAll]);
end;

function DecodificarClaveCifradaDeRuta(
  const AClaveCifrada: string): string;
begin
  Result := ReplaceText(AClaveCifrada, '%3D', '=');
  Result := ReplaceText(Result, '%2F', '/');
  Result := ReplaceText(Result, '%2B', '+');
  Result := ReplaceText(Result, '%25', '%');
end;

function IntentarExtraerMarcadorClave(
  const ARuta: string;
  out AMarcador, ARutaRegistro: string): Boolean;
var
  iFinMarcador: Integer;
  sNombre: string;
  sNombreRegistro: string;
begin
  AMarcador := '';
  ARutaRegistro := ARuta;
  Result := False;
  sNombre := ExtractFileName(ARuta);
  if (sNombre <> '') and (sNombre[1] = '_') then
  begin
    iFinMarcador := PosEx('_', sNombre, 2);
    Result := iFinMarcador > 2;
    if Result then
    begin
      AMarcador := Copy(sNombre, 2, iFinMarcador - 2);
      sNombreRegistro := '_***_' +
        Copy(sNombre, iFinMarcador + 1, MaxInt);
      ARutaRegistro := ExtractFilePath(ARuta) +
        sNombreRegistro;
    end;
  end;
end;

function SustituirMarcadorClave(
  const ARuta, AClaveCifrada: string): string;
var
  iFinMarcador: Integer;
  sNombre: string;
begin
  sNombre := ExtractFileName(ARuta);
  iFinMarcador := PosEx('_', sNombre, 2);
  Result := ExtractFilePath(ARuta) + '_' +
    CodificarClaveCifradaParaRuta(AClaveCifrada) + '_' +
    Copy(sNombre, iFinMarcador + 1, MaxInt);
end;

function ContieneCaracterRutaNoValido(const ARuta: string): Boolean;
var
  cCaracter: Char;
  iIndice: Integer;
begin
  Result := False;
  for iIndice := 1 to Length(ARuta) do
  begin
    cCaracter := ARuta[iIndice];
    if (Ord(cCaracter) < 32) or
       CharInSet(cCaracter, ['<', '>', '"', '|', '?', '*', '/']) then
    begin
      Result := True;
    end;
  end;
end;

function EsRutaAbsolutaWindows(const ARuta: string): Boolean;
var
  bRutaUnidad: Boolean;
  bRutaUnc: Boolean;
begin
  bRutaUnidad := (Length(ARuta) >= 3) and
    CharInSet(UpCase(ARuta[1]), ['A'..'Z']) and
    (ARuta[2] = ':') and IsPathDelimiter(ARuta, 3);
  bRutaUnc := StartsText('\\', ARuta) and
    not StartsText('\\?\', ARuta) and
    not StartsText('\\.\', ARuta);
  Result := bRutaUnidad or bRutaUnc;
end;

function ContieneFlujoAlternativo(const ARuta: string): Boolean;
var
  sRutaSinUnidad: string;
begin
  sRutaSinUnidad := ARuta;
  if (Length(sRutaSinUnidad) >= 2) and
     (sRutaSinUnidad[2] = ':') then
  begin
    Delete(sRutaSinUnidad, 1, 2);
  end;
  Result := Pos(':', sRutaSinUnidad) > 0;
end;

function ValidarRutaDestino(
  const ARuta: string): TErrorComandoCopiaSeguridad;
var
  sDirectorio: string;
  sNombre: string;
begin
  Result := eccsNinguno;
  sDirectorio := ExtractFilePath(ARuta);
  sNombre := ExtractFileName(ARuta);
  if (ARuta = '') or
     (sDirectorio = '') or
     (sNombre = '') or
     (Length(ARuta) > MAXIMA_LONGITUD_RUTA) or
     (Length(sNombre) > 255) or
     not EsRutaAbsolutaWindows(ARuta) or
     ContieneCaracterRutaNoValido(ARuta) or
     ContieneFlujoAlternativo(ARuta) then
  begin
    Result := eccsRuta;
  end
  else if not SameText(ExtractFileExt(ARuta), '.crypt') then
    Result := eccsExtension;
end;

function ObtenerClaveCifradaSolicitud(
  AContrasenaExplicita: Boolean;
  const AContrasena, AClavePredeterminada: string): string;
begin
  if AContrasenaExplicita then
    Result := CifrarAES(AContrasena)
  else
    Result := AClavePredeterminada;
end;

procedure AplicarMarcadorLiteral(
  AContrasenaExplicita: Boolean;
  const AClavePredeterminada: string;
  var ASolicitud: TSolicitudComandoCopiaSeguridad;
  out AClaveCifrada: string);
begin
  AClaveCifrada := ObtenerClaveCifradaSolicitud(
    AContrasenaExplicita,
    ASolicitud.Contrasena,
    AClavePredeterminada);
  if (ASolicitud.Contrasena <> '') and
     (AClaveCifrada <> '') then
  begin
    ASolicitud.RutaDestino := ReemplazarToken(
      ASolicitud.RutaDestino,
      MARCADOR_CLAVE,
      CodificarClaveCifradaParaRuta(AClaveCifrada));
  end;
end;

procedure AplicarMarcadorCifrado(
  AContrasenaExplicita: Boolean;
  const AMarcador: string;
  var ASolicitud: TSolicitudComandoCopiaSeguridad;
  out AClaveCifrada: string);
begin
  if AContrasenaExplicita then
    AClaveCifrada := CifrarAES(ASolicitud.Contrasena)
  else
  begin
    AClaveCifrada := DecodificarClaveCifradaDeRuta(AMarcador);
    ASolicitud.Contrasena := DescifrarAES(AClaveCifrada);
  end;
  if (ASolicitud.Contrasena <> '') and
     (AClaveCifrada <> '') then
  begin
    ASolicitud.RutaDestino := SustituirMarcadorClave(
      ASolicitud.RutaDestino,
      AClaveCifrada);
  end;
end;

procedure ResolverClaveSolicitud(
  const AParametros: TArray<string>;
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad;
  var ASolicitud: TSolicitudComandoCopiaSeguridad);
var
  bContrasenaExplicita: Boolean;
  bMarcadorLiteral: Boolean;
  bTieneMarcador: Boolean;
  sClaveCifrada: string;
  sMarcador: string;
  sRutaRegistroLiteral: string;
begin
  bContrasenaExplicita := Length(AParametros) = 3;
  if bContrasenaExplicita then
    ASolicitud.Contrasena := AParametros[2]
  else
    ASolicitud.Contrasena := AClavesPredeterminadas.Contrasena;
  sRutaRegistroLiteral := ReemplazarToken(
    ASolicitud.RutaDestino,
    MARCADOR_CLAVE,
    '***');
  bMarcadorLiteral :=
    sRutaRegistroLiteral <> ASolicitud.RutaDestino;
  bTieneMarcador := False;
  if bMarcadorLiteral then
    ASolicitud.RutaRegistro := sRutaRegistroLiteral
  else
  begin
    bTieneMarcador := IntentarExtraerMarcadorClave(
      ASolicitud.RutaDestino,
      sMarcador,
      ASolicitud.RutaRegistro);
  end;
  sClaveCifrada := '';
  if bMarcadorLiteral then
  begin
    AplicarMarcadorLiteral(
      bContrasenaExplicita,
      AClavesPredeterminadas.ClaveCifrada,
      ASolicitud,
      sClaveCifrada);
  end
  else if bTieneMarcador then
  begin
    AplicarMarcadorCifrado(
      bContrasenaExplicita,
      sMarcador,
      ASolicitud,
      sClaveCifrada);
  end;
  if ASolicitud.Contrasena = '' then
    ASolicitud.Error := eccsClave;
  if (bMarcadorLiteral or bTieneMarcador) and
     (sClaveCifrada = '') then
    ASolicitud.Error := eccsClave;
end;

function InterpretarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const AClavesPredeterminadas:
    TClavesPredeterminadasCopiaSeguridad
): TSolicitudComandoCopiaSeguridad;
begin
  Result := Default(TSolicitudComandoCopiaSeguridad);
  Result.EsComando := EsComandoCopiaSeguridad(AParametros);
  if Result.EsComando then
  begin
    if EsSintaxisComandoCopiaSeguridadValida(AParametros) then
    begin
      Result.RutaDestino := ResolverPlantillaCopiaSeguridad(
        Trim(AParametros[1]),
        AInstante);
      Result.RutaRegistro := Result.RutaDestino;
      ResolverClaveSolicitud(
        AParametros,
        AClavesPredeterminadas,
        Result);
      if Result.Error = eccsNinguno then
        Result.Error := ValidarRutaDestino(Result.RutaDestino);
      Result.EsValida := Result.Error = eccsNinguno;
    end
    else
      Result.Error := eccsSintaxis;
  end;
end;

end.
