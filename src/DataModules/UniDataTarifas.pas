{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifas                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de tarifas.                                                   }
{    Mantenimiento de fza_tarifas y consulta de fza_articulos_tarifas          }
{    asociados.                                                                }
{******************************************************************************}
unit UniDataTarifas;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser;

type
  TdmTarifas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosTarifas: TUniQuery;
    dsArticulosTarifas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoFamilia;
    //procedure GetCodigoAutoRetencion;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString := '0';
end;

procedure TdmTarifas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryArticulosTarifas.Connection := ConexionPrincipal;
  unqryArticulosTarifas.Open;
end;

procedure TdmTarifas.GetCodigoAutoFamilia;
begin
  if unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString = '0' then
  begin
    unstrdprcContador.Params.Clear;
    unstrdprcContador.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    unstrdprcContador.Params.CreateParam(ftInteger, 'pcont', ptOutput);
    unstrdprcContador.Params.CreateParam(
      ftInteger, 'pUSUARIO_MODIF', ptInput);
    unstrdprcContador.ParamByName('pUSUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcContador.ParamByName('ptipodoc').AsString := 'TF';
    unstrdprcContador.ExecProc;
    unqryTablaG.FindField('CODIGO_TAR_ARTTAR').AsString :=
      unstrdprcContador.ParamByName('pcont').AsString;
  end;
end;

procedure TdmTarifas.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoFamilia;
end;

initialization
  RegistrarDataModule(TdmTarifas);
  ForceReferenceToClass(TdmTarifas);
end.
