{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasSimplif                                          }
{    Tipo:       Formulario (Mto) descendiente                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de facturas SIMPLIFICADAS (caja / tickets).                      }
{    Descendiente de TfrmMtoFacturasBase: consulta vi_facturas_simplificadas   }
{    en el listado y deja TIPO_FAC = 'SIMPLIFICADA' por defecto al insertar.   }
{    Customizaciones de vista (columnas, anchos, orden) en el .dfm propio o    }
{    en fza_usuarios_perfiles bajo la clave 'frmMtoFacturasSimplif'.           }
{******************************************************************************}
unit inMtoFacturasSimplif;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFacturasBase;

type
  TfrmMtoFacturasSimplif = class(TfrmMtoFacturasBase)
  public
    function NombreVistaListado: string; override;
    function TipoFacturaFiltro: string; override;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TfrmMtoFacturasSimplif.NombreVistaListado: string;
begin
  Result := 'vi_facturas_simplificadas';
end;

function TfrmMtoFacturasSimplif.TipoFacturaFiltro: string;
begin
  Result := 'SIMPLIFICADA';
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasSimplif);
end.
