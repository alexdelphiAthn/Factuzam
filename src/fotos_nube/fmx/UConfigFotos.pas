{******************************************************************************}
{                                                                              }
{  Módulo:       UConfigFotos                                                  }
{    Tipo:       Librería (FMX, multiplataforma)                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Configuración persistente de la app de fotos a la nube. Se guarda en      }
{    un INI dentro del sandbox de la app (carpeta de documentos), de modo      }
{    que funciona igual en Android y en Windows sin depender de la BBDD.       }
{    Incluye la resolución máxima por defecto (1000 px) con la que se          }
{    reducen las fotos antes de enviarlas al webservice.                       }
{******************************************************************************}
unit UConfigFotos;

interface

uses
  System.SysUtils, System.IOUtils, System.IniFiles;

const
  // Resolución máxima por defecto (lado mayor, en píxeles). El usuario
  // puede cambiarla en la pantalla de configuración.
  cResolucionMaximaDefecto = 1000;
  // Tope de seguridad: nunca enviamos fotos por encima de este lado.
  cResolucionMaximaTope = 4000;

type
  // Configuración de conexión al webservice de fotos (fotosnube) y de
  // reducción de imagen. Persiste en INI local.
  TConfigFotos = class
  private
    FRutaIni: string;
    FUrl: string;
    FApiKey: string;
    FCliente: string;
    FSkuPorDefecto: string;
    FResolucionMaxima: Integer;
    function RutaIniPorDefecto: string;
    procedure SetResolucionMaxima(const AValor: Integer);
  public
    constructor Create(const ARutaIni: string = '');
    procedure Cargar;
    procedure Guardar;
    property Url: string read FUrl write FUrl;
    property ApiKey: string read FApiKey write FApiKey;
    property Cliente: string read FCliente write FCliente;
    property SkuPorDefecto: string read FSkuPorDefecto write FSkuPorDefecto;
    property ResolucionMaxima: Integer read FResolucionMaxima
      write SetResolucionMaxima;
    property RutaIni: string read FRutaIni;
  end;

implementation

const
  cSeccion = 'FotosNube';

{ TConfigFotos }

constructor TConfigFotos.Create(const ARutaIni: string);
begin
  inherited Create;
  if ARutaIni = '' then
    FRutaIni := RutaIniPorDefecto
  else
    FRutaIni := ARutaIni;
  FUrl := '';
  FApiKey := '';
  FCliente := '';
  FSkuPorDefecto := '';
  FResolucionMaxima := cResolucionMaximaDefecto;
end;

function TConfigFotos.RutaIniPorDefecto: string;
begin
  // En Android es el sandbox de la app; en Windows, la carpeta de
  // documentos del usuario. En ambos casos es escribible.
  Result := TPath.Combine(TPath.GetDocumentsPath, 'fotosnube.ini');
end;

procedure TConfigFotos.SetResolucionMaxima(const AValor: Integer);
begin
  // Saneamos el valor para evitar resoluciones absurdas o nulas.
  if AValor <= 0 then
    FResolucionMaxima := cResolucionMaximaDefecto
  else if AValor > cResolucionMaximaTope then
    FResolucionMaxima := cResolucionMaximaTope
  else
    FResolucionMaxima := AValor;
end;

procedure TConfigFotos.Cargar;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FRutaIni);
  try
    FUrl := Ini.ReadString(cSeccion, 'Url', FUrl);
    FApiKey := Ini.ReadString(cSeccion, 'ApiKey', FApiKey);
    FCliente := Ini.ReadString(cSeccion, 'Cliente', FCliente);
    FSkuPorDefecto := Ini.ReadString(cSeccion, 'Sku', FSkuPorDefecto);
    SetResolucionMaxima(Ini.ReadInteger(cSeccion, 'ResolucionMaxima',
      FResolucionMaxima));
  finally
    Ini.Free;
  end;
end;

procedure TConfigFotos.Guardar;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FRutaIni);
  try
    Ini.WriteString(cSeccion, 'Url', FUrl);
    Ini.WriteString(cSeccion, 'ApiKey', FApiKey);
    Ini.WriteString(cSeccion, 'Cliente', FCliente);
    Ini.WriteString(cSeccion, 'Sku', FSkuPorDefecto);
    Ini.WriteInteger(cSeccion, 'ResolucionMaxima', FResolucionMaxima);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

end.
