{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPropiedadesValores                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de valores de propiedades.                                    }
{    Mantenimiento de fza_propiedades_valores con su lookup de propiedad padre.}
{******************************************************************************}
unit UniDataPropiedadesValores;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  TdmPropiedadesValores = class(TdmBase)
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmPropiedadesValores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := ConexionPrincipal;
  if not unqryPropiedades.Active then
    unqryPropiedades.Open;
end;

initialization
  RegistrarDataModule(TdmPropiedadesValores);
  ForceReferenceToClass(TdmPropiedadesValores);
end.
