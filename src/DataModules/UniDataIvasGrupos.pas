{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataIvasGrupos                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de grupos de IVA.                                             }
{    Mantenimiento de fza_ivas_grupos para la clasificación fiscal por zonas.  }
{******************************************************************************}
unit UniDataIvasGrupos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
   inLibUser, UniDataConn, inLibtb;

type
  TdmIvasGrupos = class(TdmBase)
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoIvaGrupo;
  end;

//var
//  dmIvasGrupos: TdmIvasGrupos;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvasGrupos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FindField('IVA_IVAGRP').AsString := '0';
    FindField('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString := 'N';
    FindField('ESIVAAGRICOLA_IVA_IVAGRP').AsString := 'N';
    FindField('ESAPLICA_RE_IVA_IVAGRP').AsString := 'S';
    FindField('ESDEFAULT_IVA_IVAGRP').AsString := 'N';
    FindField('PALABRA_REPORTS_IVA_IVAGRP').AsString := 'IVA';
  end;
end;

procedure TdmIvasGrupos.unqryTablaGBeforePost(DataSet: TDataSet);
var
 sCodigo,
 sDescripcion:String;
 bError : Boolean;
 unqrySol : TUniQuery;
begin
  inherited;
  bError := False;
  with unqryTablaG do
  begin
    sCodigo := Trim(FindField('IVA_IVAGRP').AsString);
    sDescripcion := Trim(FindField('DESCRIPCION_IVA_IVAGRP').AsString);
    if ((sDescripcion = '') or (SimbolosProhibidos(sDescripcion))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                   'para el campo Descripción de Grupos de IVA',
                                                                [sDescripcion]);
      bError := True;
    end;
    if ((sCodigo = '') or
        (SimbolosProhibidos(sCodigo))
       ) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                        'para el campo Código de Grupos de IVA',
                                                                     [sCodigo]);
      bError := True;
    end;
    if (bError = False) then
    begin
      if (FindField('ESDEFAULT_IVA_IVAGRP').AsString = 'S') then
      begin
        unqrySol := TUniQuery.Create(nil);
        unqrySol.Connection := oConn;
        unqrySol.SQL.Text := 'SELECT ESDEFAULT_IVA_IVAGRP ' +
                             '  FROM vi_ivas_grupos ' +
                             ' WHERE ESDEFAULT_IVA_IVAGRP = ' + QuotedStr('S');
        if (DataSet.State = dsEdit) then
        begin
          unqrySol.SQL.Text := unqrySol.SQL.Text +
                               ' AND IVA_IVAGRP <> ' + sCodigo;
        end;
        unqrySol.Open;
        if (unqrySol.RecordCount > 0) then
        begin
          raise EDataBaseError.Create('No es posible marcar dos grupos de IVA'+
                                      ' como Grupo de IVA por Defecto');
          bError := True;
        end;
        unqrySol.Close;
        FreeAndNil(unqrySol);
      end;
    end;
    if bError then
      Abort
    else
      GetCodigoAutoIvaGrupo;
  end;
end;

procedure TdmIvasGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
//  unstrdprcContador.Connection := oConn;
end;

procedure TdmIvasGrupos.GetCodigoAutoIvaGrupo;
begin

  if unqryTablaG.FindField('IVA_IVAGRP').AsString = '0' then
  begin
    unqryTablaG.FindField('IVA_IVAGRP').AsString :=
                                                 ObtenerSiguienteContador('IG');
//    with unstrdprcContador do
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
//      ParamByName('pUSUARIO_MODIF').AsString := oUser;
//      ParamByName('ptipodoc').AsString :=  'IG';
//      ExecProc;
//      unqryTablaG.FindField('IVA_IVAGRP').AsString :=
//                                                  ParamByName('pcont').AsString;
//    end;
  end;
end;

initialization
  ForceReferenceToClass(TdmIvasGrupos);
end.
