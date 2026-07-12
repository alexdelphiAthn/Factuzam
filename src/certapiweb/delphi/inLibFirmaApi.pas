{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFirmaApi                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera y utiliza la identidad Ed25519 que autoriza nuevas APIs.           }
{******************************************************************************}

unit inLibFirmaApi;

interface

uses
  System.SysUtils;

type
  TIdentidadEmisora = record
    IdClave: string;
    ClavePublica: TBytes;
    ClavePrivada: TBytes;
  end;

  TFirmaApi = class
  private
    class function RutaIdentidad: string; static;
    class function GenerarIdentidad: TIdentidadEmisora; static;
    class procedure GuardarIdentidad(
      const AIdentidad: TIdentidadEmisora); static;
    class function CargarIdentidad: TIdentidadEmisora; static;
    class procedure ValidarIdentidad(
      const AIdentidad: TIdentidadEmisora); static;
  public
    class function CargarOCrearIdentidad: TIdentidadEmisora; static;
    class function Firmar(const AIdentidad: TIdentidadEmisora;
                          const AMensaje: TBytes): TBytes; static;
    class function GenerarNonce: string; static;
    class function HashSha256Hex(const ADatos: TBytes): string; static;
    class function Base64UrlCodificar(const ADatos: TBytes): string; static;
    class function Base64UrlDecodificar(
      const ATexto: string): TBytes; static;
    class procedure Limpiar(var ADatos: TBytes); static;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.JSON,
  System.NetEncoding,
  ClpDigestUtilities, ClpIDigest,
  ClpEd25519, ClpEd25519Parameters, ClpIEd25519Parameters,
  ClpISecureRandom, ClpSecureRandom,
  inLibProteccionWindows;

function BytesIguales(const A, B: TBytes): Boolean;
var
  i: Integer;
  bDiferencia: Byte;
begin
  Result := Length(A) = Length(B);
  bDiferencia := 0;
  if Result then
  begin
    for i := 0 to Length(A) - 1 do
      bDiferencia := bDiferencia or (A[i] xor B[i]);
    Result := bDiferencia = 0;
  end;
end;

class function TFirmaApi.RutaIdentidad: string;
var
  sBase: string;
begin
  sBase := GetEnvironmentVariable('APPDATA');
  if Trim(sBase) = '' then
    sBase := TPath.GetHomePath;
  Result := TPath.Combine(
    TPath.Combine(sBase, 'Factuzam'),
    TPath.Combine('CertApiWeb', 'identidad.json'));
end;

class function TFirmaApi.GenerarIdentidad: TIdentidadEmisora;
var
  oAleatorio: ISecureRandom;
  oPrivada: IEd25519PrivateKeyParameters;
  oPublica: IEd25519PublicKeyParameters;
begin
  oAleatorio := TSecureRandom.Create() as ISecureRandom;
  oPrivada := TEd25519PrivateKeyParameters.Create(oAleatorio)
              as IEd25519PrivateKeyParameters;
  oPublica := oPrivada.GeneratePublicKey();
  Result.ClavePrivada := oPrivada.GetEncoded();
  Result.ClavePublica := oPublica.GetEncoded();
  Result.IdClave := Copy(HashSha256Hex(Result.ClavePublica), 1, 16);
end;

class procedure TFirmaApi.GuardarIdentidad(
  const AIdentidad: TIdentidadEmisora);
var
  aProtegida: TBytes;
  oJson: TJSONObject;
  sRuta: string;
begin
  sRuta := RutaIdentidad;
  ForceDirectories(ExtractFileDir(sRuta));
  aProtegida := TProteccionWindows.Proteger(AIdentidad.ClavePrivada);
  try
    oJson := TJSONObject.Create;
    try
      oJson.AddPair('version', TJSONNumber.Create(1));
      oJson.AddPair('id_clave', AIdentidad.IdClave);
      oJson.AddPair('clave_publica',
                    Base64UrlCodificar(AIdentidad.ClavePublica));
      oJson.AddPair('clave_privada_protegida',
                    Base64UrlCodificar(aProtegida));
      TFile.WriteAllText(sRuta, oJson.ToJSON, TEncoding.UTF8);
    finally
      FreeAndNil(oJson);
    end;
  finally
    Limpiar(aProtegida);
  end;
end;

class function TFirmaApi.CargarIdentidad: TIdentidadEmisora;
var
  aProtegida: TBytes;
  oValor: TJSONValue;
  oJson: TJSONObject;
  sTexto: string;
begin
  sTexto := TFile.ReadAllText(RutaIdentidad, TEncoding.UTF8);
  oValor := TJSONObject.ParseJSONValue(sTexto);
  if not (oValor is TJSONObject) then
  begin
    FreeAndNil(oValor);
    raise Exception.Create('El fichero de identidad no contiene JSON válido.');
  end;
  oJson := TJSONObject(oValor);
  try
    Result.IdClave := oJson.GetValue<string>('id_clave');
    Result.ClavePublica := Base64UrlDecodificar(
      oJson.GetValue<string>('clave_publica'));
    aProtegida := Base64UrlDecodificar(
      oJson.GetValue<string>('clave_privada_protegida'));
    try
      Result.ClavePrivada := TProteccionWindows.Desproteger(aProtegida);
    finally
      Limpiar(aProtegida);
    end;
  finally
    FreeAndNil(oJson);
  end;
  ValidarIdentidad(Result);
end;

class procedure TFirmaApi.ValidarIdentidad(
  const AIdentidad: TIdentidadEmisora);
var
  aPublicaCalculada: TBytes;
  oPrivada: IEd25519PrivateKeyParameters;
begin
  if Length(AIdentidad.ClavePrivada) <> 32 then
    raise Exception.Create('La clave privada Ed25519 no tiene 32 bytes.');
  if Length(AIdentidad.ClavePublica) <> 32 then
    raise Exception.Create('La clave pública Ed25519 no tiene 32 bytes.');
  oPrivada := TEd25519PrivateKeyParameters.Create(
                AIdentidad.ClavePrivada) as IEd25519PrivateKeyParameters;
  aPublicaCalculada := oPrivada.GeneratePublicKey().GetEncoded();
  try
    if not BytesIguales(AIdentidad.ClavePublica, aPublicaCalculada) then
      raise Exception.Create('La clave pública no corresponde a la privada.');
    if AIdentidad.IdClave <>
       Copy(HashSha256Hex(AIdentidad.ClavePublica), 1, 16) then
      raise Exception.Create('El identificador de la clave no es válido.');
  finally
    Limpiar(aPublicaCalculada);
  end;
end;

class function TFirmaApi.CargarOCrearIdentidad: TIdentidadEmisora;
begin
  if FileExists(RutaIdentidad) then
    Result := CargarIdentidad
  else
  begin
    Result := GenerarIdentidad;
    GuardarIdentidad(Result);
  end;
end;

class function TFirmaApi.Firmar(
  const AIdentidad: TIdentidadEmisora;
  const AMensaje: TBytes): TBytes;
var
  oPrivada: IEd25519PrivateKeyParameters;
begin
  ValidarIdentidad(AIdentidad);
  oPrivada := TEd25519PrivateKeyParameters.Create(
                AIdentidad.ClavePrivada) as IEd25519PrivateKeyParameters;
  SetLength(Result, TEd25519PrivateKeyParameters.SignatureSize);
  oPrivada.Sign(TEd25519.TAlgorithm.Ed25519, nil, AMensaje, 0,
                Length(AMensaje), Result, 0);
end;

class function TFirmaApi.GenerarNonce: string;
var
  aNonce: TBytes;
  oAleatorio: ISecureRandom;
begin
  SetLength(aNonce, 16);
  oAleatorio := TSecureRandom.Create() as ISecureRandom;
  oAleatorio.NextBytes(aNonce);
  try
    Result := Base64UrlCodificar(aNonce);
  finally
    Limpiar(aNonce);
  end;
end;

class function TFirmaApi.HashSha256Hex(const ADatos: TBytes): string;
var
  aHash: TBytes;
  b: Byte;
  oDigest: IDigest;
begin
  Result := '';
  oDigest := TDigestUtilities.GetDigest('SHA-256');
  SetLength(aHash, oDigest.GetDigestSize());
  try
    oDigest.BlockUpdate(ADatos, 0, Length(ADatos));
    oDigest.DoFinal(aHash, 0);
    for b in aHash do
      Result := Result + LowerCase(IntToHex(b, 2));
  finally
    Limpiar(aHash);
  end;
end;

class function TFirmaApi.Base64UrlCodificar(
  const ADatos: TBytes): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(ADatos);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := StringReplace(Result, '+', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '', [rfReplaceAll]);
end;

class function TFirmaApi.Base64UrlDecodificar(
  const ATexto: string): TBytes;
var
  sBase64: string;
begin
  sBase64 := StringReplace(ATexto, '-', '+', [rfReplaceAll]);
  sBase64 := StringReplace(sBase64, '_', '/', [rfReplaceAll]);
  while (Length(sBase64) mod 4) <> 0 do
    sBase64 := sBase64 + '=';
  Result := TNetEncoding.Base64.DecodeStringToBytes(sBase64);
end;

class procedure TFirmaApi.Limpiar(var ADatos: TBytes);
begin
  if Length(ADatos) > 0 then
    FillChar(ADatos[0], Length(ADatos), 0);
  SetLength(ADatos, 0);
end;

end.
