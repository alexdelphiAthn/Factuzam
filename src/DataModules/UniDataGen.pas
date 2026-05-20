{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGen                                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module base de los mantenimientos (TdmBase).                         }
{    Provee unqryTablaG y servicios comunes (perfiles, GetOwnerForm) que       }
{    heredan los Mtos.                                                         }
{******************************************************************************}
unit UniDataGen;

interface

uses
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, inLibWin;

type
  TdmBase = class(TDataModule)
    unqryTablaG: TUniQuery;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
  private
    function GetCurrentForm: TComponent;
    procedure SetCurrentForm(const Value: TComponent);
  protected
    procedure DoCreate; reintroduce; virtual;
    function GetOwnerForm<T: TComponent>: T;
    function HasOwnerForm: Boolean;
  public
    property CurrentForm: TComponent read GetCurrentForm write SetCurrentForm;
    procedure ResetGridsProfile(sGrid, sForm, sPermisos:String);
    // Reasigna la conexion (TUniConnection) de todos los datasets/SQL del
    // data module a `NewConn`. Lo usa TfrmMtoGen tras crear el data module
    // para que cada pestaña use una conexion propia del pool en lugar de
    // la global `oConn` (asi dos tabs no se serializan a nivel de conexion).
    procedure ReasignarConexion(NewConn: TUniConnection);
  public
    FCurrentForm: TComponent;
    FoPerfilDic: TProfileDicc;
  end;

//var
//  dmBase: TdmBase;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses  inLibGlobalVar, inMtoPrincipal, inMtoGen;

{$R *.dfm}

procedure TdmBase.DoCreate;
begin
  FoPerfilDic := nil;
  unqryTablaG.Connection := oConn;
  unqryPerfiles.Connection := oConn;
end;

procedure TdmBase.DataModuleCreate(Sender: TObject);
begin
  DoCreate;
end;

procedure TdmBase.DataModuleDestroy(Sender: TObject);
begin
  unqryTablaG.Close;
  unqryPerfiles.Close;
  if (FoPerfilDic <> nil) then
    FreeAndNil(FoPerfilDic);
//  oPerfilDic.Free;
end;

function TdmBase.GetCurrentForm: TComponent;
begin
  Result := FCurrentForm;
end;

procedure TdmBase.SetCurrentForm(const Value: TComponent);
begin
  FCurrentForm := Value;
end;

function TdmBase.GetOwnerForm<T>: T;
begin
  Result := nil;
  if Assigned(FCurrentForm) and (FCurrentForm is T) then
    Result := T(FCurrentForm)
  else if (Self.Owner <> nil) and (Self.Owner is T) then
    Result := T(Self.Owner);
end;

function TdmBase.HasOwnerForm: Boolean;
begin
  Result := Assigned(FCurrentForm) and
            not (csDestroying in FCurrentForm.ComponentState);
end;

procedure TdmBase.ReasignarConexion(NewConn: TUniConnection);
var
  i: Integer;
  Comp: TComponent;
  ds: TCustomDADataSet;
  sql: TCustomDASQL;
begin
  if NewConn = nil then
    Exit;
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    // TUniQuery, TUniTable, TUniStoredProc heredan de TCustomDADataSet.
    if Comp is TCustomDADataSet then
    begin
      ds := TCustomDADataSet(Comp);
      if ds.Active then
        ds.Close;
      ds.Connection := NewConn;
    end
    // TUniSQL, TUniScript heredan de TCustomDASQL.
    else if Comp is TCustomDASQL then
    begin
      sql := TCustomDASQL(Comp);
      sql.Connection := NewConn;
    end;
  end;
end;

procedure TdmBase.ResetGridsProfile(sGrid, sForm, sPermisos: String);
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                       '      WHERE USUARIO_GRUPO_USUPER = :user ' +
                       '        AND KEY_USUPER = :form ';
//                       '        AND SUBKEY_USUPER LIKE ' +
//                                                      QuotedSTr(sGrid + '_%');
  unqrysol.ParamByName('user').AsString := sPermisos;
  unqrysol.ParamByName('form').AsString := sForm;
  unqrySol.Execute;
  FreeAndNil(unqrySol);
end;

procedure TdmBase.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  odmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmBase.unqryTablaGBeforeInsert(DataSet: TDataSet);
var
  LForm: TfrmMtoGen;
begin
  LForm := GetOwnerForm<TfrmMtoGen>;
  if Assigned(LForm) then
  begin
    if LForm.tsFicha.TabVisible then
       LForm.pcPantalla.ActivePage := LForm.tsFicha;
  end;
end;

procedure TdmBase.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

end.
