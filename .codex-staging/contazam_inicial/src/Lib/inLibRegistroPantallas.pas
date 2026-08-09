{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRegistroPantallas                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Registro explícito de clases de pantalla, propiedad de la composición.    }
{******************************************************************************}
unit inLibRegistroPantallas;

interface

uses
  System.Classes, System.Generics.Collections, Uni, inMtoFrmBase,
  inLibConfiguracion, inLibSeguridadIntf, inLibLogIntf;

type
  TClasePantallaContazam = class of TfrmBase;

  TRegistroPantallasContazam = class
  private
    FClases: TDictionary<Integer, TClasePantallaContazam>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Registrar(
      AClave: Integer;
      AClase: TClasePantallaContazam);
    function Crear(
      AClave: Integer;
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam;
      const ASeguridad: IServicioSeguridadContazam;
      const ARegistroLog: IRegistroLogContazam): TfrmBase;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms;

constructor TRegistroPantallasContazam.Create;
begin
  inherited;
  FClases := TDictionary<Integer, TClasePantallaContazam>.Create;
end;

function TRegistroPantallasContazam.Crear(
  AClave: Integer;
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam;
  const ASeguridad: IServicioSeguridadContazam;
  const ARegistroLog: IRegistroLogContazam): TfrmBase;
var
  oClase: TClasePantallaContazam;
begin
  if not FClases.TryGetValue(AClave, oClase) then
  begin
    raise EInvalidOpException.CreateFmt(
      'No existe una pantalla registrada con la clave %d.',
      [AClave]);
  end;
  Result := oClase.Create(AOwner);
  try
    Result.FormStyle := fsMDIChild;
    Result.AsignarSeguridad(ASeguridad);
    Result.AsignarRegistroLog(ARegistroLog);
    Result.Inicializar(AConexion, AConfiguracion);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

destructor TRegistroPantallasContazam.Destroy;
begin
  FreeAndNil(FClases);
  inherited;
end;

procedure TRegistroPantallasContazam.Registrar(
  AClave: Integer;
  AClase: TClasePantallaContazam);
begin
  if AClase = nil then
  begin
    raise EArgumentNilException.Create('AClase');
  end;
  FClases.AddOrSetValue(AClave, AClase);
end;

end.
