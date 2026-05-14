{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosBasicos                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del catálogo de atributos básicos (fza_atributos_basicos).    }
{    Provee la query principal y un lookup de variaciones/atributos para que   }
{    al alta el usuario elija de un combo el ID_VA_ATB (CO, TAL, TEMP…).       }
{******************************************************************************}
unit UniDataAtributosBasicos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmAtributosBasicos = class(TdmBase)
    unqryAtributosLookup: TUniQuery;
    dsAtributosLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmAtributosBasicos: TdmAtributosBasicos;

implementation

uses
  inMtoAtributosBasicos, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosBasicos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryAtributosLookup.Connection := oConn;
  unqryAtributosLookup.Open;
end;

procedure TdmAtributosBasicos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(DataSet.FieldByName('ID_VA_ATB').AsString) = '' then
    raise Exception.Create(
      'Indica el atributo (CO para color, TAL para talla, etc.).');
  if Trim(DataSet.FieldByName('CODIGO_ATB').AsString) = '' then
    raise Exception.Create('El código del atributo básico es obligatorio.');
  if Trim(DataSet.FieldByName('NOMBRE_ATB').AsString) = '' then
    raise Exception.Create('El nombre del atributo básico es obligatorio.');
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

initialization
  ForceReferenceToClass(TdmAtributosBasicos);
end.
