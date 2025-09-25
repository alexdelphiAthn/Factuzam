{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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

  public
    procedure ResetGridsProfile(sGrid, sForm, sPermisos:String);
  end;

var
  dmBase: TdmBase;
  oPerfilDic : TProfileDicc;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses  inLibGlobalVar, inMtoPrincipal2, inMtoGen;

{$R *.dfm}

procedure TdmBase.DataModuleCreate(Sender: TObject);
begin
  oPerfilDic := nil;
  unqryTablaG.Connection              := oConn;
  unqryPerfiles.Connection            := oConn;
  if (Owner is TfrmMtoGen) then
  begin
    if (GetPerfilValueDef((Owner as TfrmMtoGen).oPerfilDic,
                        'oGetSQLFromDB',
                        'False') = 'True') then
    begin
      GetFormUserProfile(oPerfilDic, Self.Name);
      LoadSQLFromProfile(Self, oPerfilDic);
    end;
    (Self.Owner as TfrmMtoGen).tdmDataModule := Self;
    (Self.Owner as TfrmMtoGen).dsTablaG.DataSet := unqryTablaG;
    unqryTablaG.Open;
  end;
end;

procedure TdmBase.DataModuleDestroy(Sender: TObject);
begin
  unqryTablaG.Close;
  unqryPerfiles.Close;
  if (oPerfilDic <> nil) then
    FreeAndNil(oPerfilDic);
//  oPerfilDic.Free;
end;

procedure TdmBase.ResetGridsProfile(sGrid, sForm, sPermisos: String);
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                       '      WHERE USUARIO_GRUPO_PERFILES = :user ' +
                       '        AND KEY_PERFILES = :form ' +
                       '        AND SUBKEY_PERFILES LIKE ' +
                                                        QuotedSTr(sGrid + '_%');
  unqrysol.ParamByName('user').AsString := sPermisos;
  unqrysol.ParamByName('form').AsString := sForm;
  unqrySol.Execute;
  unqrySol.Free;
end;

procedure TdmBase.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  odmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmBase.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  if (Self.Owner is TfrmMtoGen) then
    with (Self.Owner as TfrmMtoGen) do
    begin
      if tsFicha.TabVisible = true then
      begin
        pcPantalla.ActivePage := tsFicha;
      end;
    end;
end;

procedure TdmBase.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

end.
