{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRegistroPantallas                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro central de clases de pantallas y data modules. Sustituye a la   }
{    resolución por RTTI (ctx.FindType sobre el texto de fza_winforms): las   }
{    clases se registran por código (inMtoCatalogoPantallas) y se resuelven   }
{    por su nombre cualificado 'Unidad.TClase'. Un nombre mal escrito en la   }
{    BBDD deja de ser un fallo en runtime: se detecta al arrancar con         }
{    TfzaWinF.ComprobarRegistradas.                                           }
{******************************************************************************}
unit inLibRegistroPantallas;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Vcl.Forms;

// Registra una clase de formulario por su QualifiedClassName
// ('inMtoClientes.TfrmMtoClientes'). El identificador lo comprueba el
// compilador: aquí no hay cadenas que puedan divergir del código.
procedure RegistrarPantalla(AClase: TFormClass);

// Registra una clase de data module por su QualifiedClassName
// ('UniDataClientes.TdmClientes').
procedure RegistrarDataModule(AClase: TComponentClass);

// Clase registrada para el nombre cualificado (UNITF_WINF); nil si no
// hay ninguna. Comparación sin distinguir mayúsculas.
function ClasePantalla(const ANombre: string): TFormClass;

// Clase registrada para el nombre cualificado (DATAMODULE_WINF); nil si
// no hay ninguna.
function ClaseDataModule(const ANombre: string): TComponentClass;

implementation

var
  oPantallas: TDictionary<string, TFormClass>;
  oDataModules: TDictionary<string, TComponentClass>;

procedure RegistrarPantalla(AClase: TFormClass);
begin
  oPantallas.AddOrSetValue(UpperCase(AClase.QualifiedClassName), AClase);
end;

procedure RegistrarDataModule(AClase: TComponentClass);
begin
  oDataModules.AddOrSetValue(UpperCase(AClase.QualifiedClassName), AClase);
end;

function ClasePantalla(const ANombre: string): TFormClass;
begin
  if not oPantallas.TryGetValue(UpperCase(Trim(ANombre)), Result) then
    Result := nil;
end;

function ClaseDataModule(const ANombre: string): TComponentClass;
begin
  if not oDataModules.TryGetValue(UpperCase(Trim(ANombre)), Result) then
    Result := nil;
end;

initialization
  oPantallas := TDictionary<string, TFormClass>.Create;
  oDataModules := TDictionary<string, TComponentClass>.Create;

finalization
  FreeAndNil(oPantallas);
  FreeAndNil(oDataModules);

end.
