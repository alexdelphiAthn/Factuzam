{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGeneradorProcesos                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del generador de procesos.                                    }
{    Maneja fza_generador_procesos: metadatos, estructura, contenido y         }
{    ejecución de comandos.                                                    }
{******************************************************************************}
unit UniDataGeneradorProcesos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn, SynEdit;

type
  TdmGeneradorProcesos = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryMetadatos: TUniQuery;
    dsMetadatos: TDataSource;
    dsEstructura: TDataSource;
    unqryEstructura: TUniQuery;
    dsContenido: TDataSource;
    unqryContenido: TUniQuery;
    unstrdprcRefresh: TUniStoredProc;
    unqryVista: TUniQuery;
    dsVista: TDataSource;
    unqryCommand: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterScroll(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoGeneradorProcesos;
    //procedure GetCodigoAutoRetencion;
  end;

implementation

uses
  inMtoGeneradorProcesos, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmGeneradorProcesos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_GENERADOR_PROCESO_GP').AsString := '0';
  // Foco al editor SQL tras insertar
  with GetOwnerForm<TfrmMtoGeneradorProcesos> do
  begin
    pcPantalla.ActivePage := tsFicha;
    pcPestana.ActivePage := tsSQL;
    if DBSynEdit1.CanFocus then
      DBSynEdit1.SetFocus;
  end;
end;

procedure TdmGeneradorProcesos.unqryTablaGAfterScroll(DataSet: TDataSet);
begin
  inherited;
//  (GetOwnerForm<TfrmMtoGeneradorProcesos>).SynEdit1.Text :=
// DataSet.FieldByName('PROCESO_GENERADOR_PROCESO_GP').AsString;
  (GetOwnerForm<TfrmMtoGeneradorProcesos>).SynEdit1StatusChange(nil, [scAll]);
end;

procedure TdmGeneradorProcesos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryMetadatos.Connection := oConn;
  unqryEstructura.Connection := oConn;
  unqryContenido.Connection := oConn;
  unstrdprcRefresh.Connection := oConn;
  unqryCommand.Connection := oConn;
end;

procedure TdmGeneradorProcesos.GetCodigoAutoGeneradorProcesos;
begin
  if unqryTablaG.FindField('CODIGO_GENERADOR_PROCESO_GP').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := IdentidadSesion.Usuario;
      ParamByName('ptipodoc').AsString :=  'GP';
      ExecProc;
      unqryTablaG.FindField('CODIGO_GENERADOR_PROCESO_GP').AsString :=
        ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmGeneradorProcesos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoGeneradorProcesos;
//  DataSet.FieldByName('PROCESO_GENERADOR_PROCESO_GP').AsString :=
//     (GetOwnerForm<TfrmMtoGeneradorProcesos>).SynEdit1.Text;
end;

initialization
  ForceReferenceToClass(TdmGeneradorProcesos);
end.
