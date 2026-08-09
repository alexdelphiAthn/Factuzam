{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLiterales                                              }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resuelve textos por idioma con fallback estable al español de España.   }
{******************************************************************************}
unit inLibLiterales;

interface

uses
  inLibLiteralesIntf;

const
  IDIOMA_CONTAZAM_POR_DEFECTO = 'es-ES';

function CrearServicioLiterales(
  const ARepositorio: IRepositorioLiterales;
  const AIdioma: string): IServicioLiterales;
function NormalizarIdioma(const AIdioma: string): string;
function TextoCampoAmigable(const ACampo: string): string;

implementation

uses
  System.SysUtils;

type
  TServicioLiterales = class(TInterfacedObject, IServicioLiterales)
  private
    FIdioma: string;
    FRepositorio: IRepositorioLiterales;
  public
    constructor Create(
      const ARepositorio: IRepositorioLiterales;
      const AIdioma: string);
    function IdiomaActual: string;
    function Resolver(
      const AContexto: string;
      const AClave: string;
      const ATextoPorDefecto: string = ''): string;
  end;

function CrearServicioLiterales(
  const ARepositorio: IRepositorioLiterales;
  const AIdioma: string): IServicioLiterales;
begin
  Result := TServicioLiterales.Create(ARepositorio, AIdioma);
end;

function NormalizarIdioma(const AIdioma: string): string;
var
  iGuion: Integer;
  sIdioma: string;
  sRegion: string;
begin
  sIdioma := LowerCase(
    StringReplace(Trim(AIdioma), '_', '-', [rfReplaceAll]));
  if sIdioma = '' then
  begin
    Result := IDIOMA_CONTAZAM_POR_DEFECTO;
  end
  else
  begin
    iGuion := Pos('-', sIdioma);
    if iGuion > 0 then
    begin
      sRegion := UpperCase(Copy(sIdioma, iGuion + 1, MaxInt));
      Result := Copy(sIdioma, 1, iGuion) + sRegion;
    end
    else
    begin
      Result := sIdioma;
    end;
  end;
end;

function TextoCampoAmigable(const ACampo: string): string;
var
  sTexto: string;
begin
  sTexto := LowerCase(
    StringReplace(Trim(ACampo), '_', ' ', [rfReplaceAll]));
  if sTexto = '' then
  begin
    Result := '';
  end
  else
  begin
    Result := UpperCase(Copy(sTexto, 1, 1)) +
      Copy(sTexto, 2, MaxInt);
  end;
end;

constructor TServicioLiterales.Create(
  const ARepositorio: IRepositorioLiterales;
  const AIdioma: string);
begin
  if ARepositorio = nil then
  begin
    raise EArgumentNilException.Create('ARepositorio');
  end;
  inherited Create;
  FRepositorio := ARepositorio;
  FIdioma := NormalizarIdioma(AIdioma);
end;

function TServicioLiterales.IdiomaActual: string;
begin
  Result := FIdioma;
end;

function TServicioLiterales.Resolver(
  const AContexto: string;
  const AClave: string;
  const ATextoPorDefecto: string): string;
var
  bEncontrado: Boolean;
  sClave: string;
  sContexto: string;
  sTexto: string;
begin
  sContexto := UpperCase(Trim(AContexto));
  sClave := UpperCase(Trim(AClave));
  bEncontrado := False;
  if (sContexto <> '') and (sClave <> '') then
  begin
    bEncontrado := FRepositorio.Buscar(
      sContexto,
      sClave,
      FIdioma,
      sTexto);
    bEncontrado := bEncontrado and (Trim(sTexto) <> '');
    if (not bEncontrado) and
       (not SameText(FIdioma, IDIOMA_CONTAZAM_POR_DEFECTO)) then
    begin
      bEncontrado := FRepositorio.Buscar(
        sContexto,
        sClave,
        IDIOMA_CONTAZAM_POR_DEFECTO,
        sTexto);
      bEncontrado := bEncontrado and (Trim(sTexto) <> '');
    end;
  end;
  if bEncontrado then
  begin
    Result := sTexto;
  end
  else if ATextoPorDefecto <> '' then
  begin
    Result := ATextoPorDefecto;
  end
  else
  begin
    Result := TextoCampoAmigable(sClave);
  end;
end;

end.
