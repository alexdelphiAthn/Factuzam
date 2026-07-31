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
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
   inLibUser, inLibCadenas, inLibValoresAutomaticos;

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

implementation

uses
  inLibMsgComun;

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
  sCodigo, sDescripcion: string;
  unqrySol: TUniQuery;
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('DESCRIPCION_IVA_IVAGRP').AsString) = '') then
    Abort;
  with unqryTablaG do
  begin
    sCodigo := Trim(FindField('IVA_IVAGRP').AsString);
    sDescripcion := Trim(FindField('DESCRIPCION_IVA_IVAGRP').AsString);
    if (sDescripcion = '') or
       SimbolosProhibidos(sDescripcion, PerfilesLectura) then
      raise ERangeError.CreateFmt(SErrorDescripcionGrupoIva,
                                  [sDescripcion]);
    if (sCodigo = '') or
       SimbolosProhibidos(sCodigo, PerfilesLectura) then
      raise ERangeError.CreateFmt(SErrorCodigoGrupoIva,
                                  [sCodigo]);
    if (FindField('ESDEFAULT_IVA_IVAGRP').AsString = 'S') then
    begin
      unqrySol := TUniQuery.Create(nil);
      try
        unqrySol.Connection := ConexionPrincipal;
        unqrySol.SQL.Text := 'SELECT ESDEFAULT_IVA_IVAGRP ' +
                             '  FROM vi_ivas_grupos ' +
                             ' WHERE ESDEFAULT_IVA_IVAGRP = ' + QuotedStr('S');
        if (DataSet.State = dsEdit) then
          unqrySol.SQL.Text := unqrySol.SQL.Text +
                               ' AND IVA_IVAGRP <> ' + sCodigo;
        unqrySol.Open;
        if (unqrySol.RecordCount > 0) then
          raise EDataBaseError.Create(SErrorDosGruposIvaPredeterminados);
      finally
        FreeAndNil(unqrySol);
      end;
    end;
    GetCodigoAutoIvaGrupo;
  end;
end;

procedure TdmIvasGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
end;

procedure TdmIvasGrupos.GetCodigoAutoIvaGrupo;
begin

  if unqryTablaG.FindField('IVA_IVAGRP').AsString = '0' then
  begin
    unqryTablaG.FindField('IVA_IVAGRP').AsString :=
                          inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'IG',
                                                   IdentidadSesion.Usuario);
  end;
end;

initialization
  RegistrarDataModule(TdmIvasGrupos);
  ForceReferenceToClass(TdmIvasGrupos);
end.
