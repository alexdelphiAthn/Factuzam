{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataIvas                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de tipos de IVA.                                              }
{    Mantenimiento de fza_ivas y zonas de IVA asociadas.                       }
{******************************************************************************}
unit UniDataIvas;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
   inLibUser, vcl.dialogs;

type
  TdmIvas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryZonasIVA: TUniQuery;
    dsZonas: TDataSource;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
  private
    function ExisteGrupoZonaIVA(sCodigoGrupo:String):Boolean;
    { Private declarations }
  public
    procedure GetCodigoAutoIva;
    procedure AbrirDetalles; override;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibCadenas, inLibDatasets, inLibLog, System.Diagnostics,
  inLibMsgComun;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FindField('CODIGO_IVA').AsString := '0';
    FindField('IVA_IVAGRP').AsString := '0';
    FindField('PORCENTAJE_EXENTO_IVA').AsString := '0';
    FindField('PORCENTAJE_EXENTO_RE_IVA').AsString := '0';
    FindField('PORCENTAJE_NORMAL_IVA').AsString := '0';
    FindField('PORCENTAJE_NORMAL_RE_IVA').AsString := '0';
    FindField('PORCENTAJE_REDUCIDO_IVA').AsString := '0';
    FindField('PORCENTAJE_REDUCIDO_RE_IVA').AsString := '0';
    FindField('PORCENTAJE_SUPERREDUCIDO_IVA').AsString := '0';
    FindField('PORCENTAJE_SUPERREDUCIDO_RE_IVA').AsString := '0';
    FindField('FECHA_DESDE_IVA').AsDateTime := Now;
  end;
end;

procedure TdmIvas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sCodigo :String;
  bError  : Boolean;
  unqrySol: TUniQuery;
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('CODIGO_IVA').AsString) = '') then
    Abort;
  bError := False;
  with unqryTablaG do
  begin
    sCodigo := Trim(FindField('CODIGO_IVA').AsString);
    if (sCodigo = '') or
       SimbolosProhibidos(sCodigo, PerfilesUsuario) then
    begin
      ShowMessageFmt(SErrorCodigoIva, [sCodigo]);
      bError := True;
    end;
    if ((FindField('IVA_IVAGRP').AsString = '0') or
        (not ExisteGrupoZonaIVA(FindField('IVA_IVAGRP').AsString))) then
    begin
      ShowMessageFmt(SErrorGrupoIvaNoExiste,
                     [FindField('IVA_IVAGRP').AsString]);
      bError := True;
    end;
    if (not(bError)) then
    begin
      with unqryTablaG do
      begin
        if (not(bError)) then
        begin
          unqrySol := TUniQuery.Create(nil);
          unqrySol.Connection := ConexionPrincipal;
          unqrySol.SQL.Text := 'SELECT * ' +
                               '  FROM vi_ivas ' +
                               ' WHERE IVA_IVAGRP = :IVA_IVAGRP';
          unqrySol.ParamByName('IVA_IVAGRP').AsString :=
                                           FindField('IVA_IVAGRP').AsString;
          unqrySol.Open;
        end;
        if ((not(bError)) and
             not(ExistePeriodoUnico(unqrySol,
                                    FindField('FECHA_DESDE_IVA'),
                                    FindField('FECHA_HASTA_IVA')))) then
        begin
          raise ERangeError.CreateFmt(SErrorRangoFechasIva,
            [FindField('DESCRIPCION_IVA_IVAGRP').AsString]);
        end;
      end;
      if (assigned(unqrySol)) then
      begin
        unqrySol.Close;
        FreeAndNil(unqrySol);
      end;
    end;
  end;
  if bError then
    Abort
  else
    GetCodigoAutoIva;
end;

procedure TdmIvas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := ConexionPrincipal;
  unqryZonasIVA.Connection := ConexionPrincipal;
  // unqryZonasIVA.Open movido a AbrirDetalles.
end;

procedure TdmIvas.AbrirDetalles;
var
  swQ: TStopwatch;
begin
  inherited;
  if unqryZonasIVA.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryZonasIVA.Open;
    inLibLog.Log.LogPerf('Ivas.AbrirDetalles',
      'unqryZonasIVA OK', swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Ivas.AbrirDetalles',
        'unqryZonasIVA ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

function TdmIvas.ExisteGrupoZonaIVA(sCodigoGrupo: String): Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := ConexionPrincipal;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM fza_ivas_grupos ' +
                       ' WHERE IVA_IVAGRP = :IVA_IVAGRP';
  unqrySol.ParamByName('IVA_IVAGRP').AsString := sCodigoGrupo;
  unqrySol.Open;
  if unqrySol.RecordCount = 0 then
    Result := False
  else
    Result := True;
  FreeAndNil(unqrySol);
end;

procedure TdmIvas.GetCodigoAutoIva;
begin
  if unqryTablaG.FindField('CODIGO_IVA').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := IdentidadSesion.Usuario;
      ParamByName('ptipodoc').AsString :=  'IV';
      ExecProc;
      unqryTablaG.FindField('CODIGO_IVA').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

initialization
  ForceReferenceToClass(TdmIvas);
end.
