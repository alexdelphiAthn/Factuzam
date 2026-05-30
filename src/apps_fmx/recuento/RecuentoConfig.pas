{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoConfig                                                }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Configuración local de la app (URL del servidor, carpeta de cliente,      }
{    token del dispositivo, operario). Se persiste en un INI en el directorio  }
{    de documentos de la app. Singleton global oConfig.                        }
{******************************************************************************}
unit RecuentoConfig;

interface

uses
  System.SysUtils, System.IOUtils, System.IniFiles;

type
  TRecuentoConfig = class
  private
    FUrlBase    : string;
    FCarpeta    : string;
    FToken      : string;
    FOperario   : string;
    FDispositivo: string;
    function RutaIni: string;
  public
    constructor Create;
    procedure Cargar;
    procedure Guardar;
    function EstaConfigurado: Boolean;
    property UrlBase: string read FUrlBase write FUrlBase;
    property Carpeta: string read FCarpeta write FCarpeta;
    property Token: string read FToken write FToken;
    property Operario: string read FOperario write FOperario;
    property Dispositivo: string read FDispositivo write FDispositivo;
  end;

var
  oConfig: TRecuentoConfig;

implementation

constructor TRecuentoConfig.Create;
begin
  inherited Create;
  FUrlBase     := '';
  FCarpeta     := '';
  FToken       := '';
  FOperario    := '';
  FDispositivo := '';
  Cargar;
end;

function TRecuentoConfig.RutaIni: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'recuento.ini');
end;

procedure TRecuentoConfig.Cargar;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    FUrlBase     := oIni.ReadString('servidor', 'url', '');
    FCarpeta     := oIni.ReadString('servidor', 'carpeta', '');
    FToken       := oIni.ReadString('servidor', 'token', '');
    FOperario    := oIni.ReadString('dispositivo', 'operario', '');
    FDispositivo := oIni.ReadString('dispositivo', 'nombre', '');
  finally
    FreeAndNil(oIni);
  end;
end;

procedure TRecuentoConfig.Guardar;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    oIni.WriteString('servidor', 'url', FUrlBase);
    oIni.WriteString('servidor', 'carpeta', FCarpeta);
    oIni.WriteString('servidor', 'token', FToken);
    oIni.WriteString('dispositivo', 'operario', FOperario);
    oIni.WriteString('dispositivo', 'nombre', FDispositivo);
    oIni.UpdateFile;
  finally
    FreeAndNil(oIni);
  end;
end;

function TRecuentoConfig.EstaConfigurado: Boolean;
begin
  // Para operar hace falta servidor + carpeta + token de dispositivo.
  Result := (Trim(FUrlBase) <> '') and
            (Trim(FCarpeta) <> '') and
            (Trim(FToken) <> '');
end;

initialization
  oConfig := TRecuentoConfig.Create;

finalization
  FreeAndNil(oConfig);

end.
