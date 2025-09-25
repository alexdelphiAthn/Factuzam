{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataPerfiles;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Vcl.Dialogs, Classes, DB, MemDS, inLibUser,
  DBAccess, Uni, UniDataConn;
type
  TFieldsProfile = record
    pUSUARIO_GRUPO_PERFILES		  :String;
    pKEY_PERFILES               :String;
    pSUBKEY_PERFILES            :String;
    pVALUE_PERFILES             :String;
    pVALUE_TEXT_PERFILES        :String;
    //pTYPE_BLOB_PERFILES         :String;
    //pVALUE_BLOB_PERFILES        :Variant;
  end;

  TdmPerfiles = class(TDataModule)
    unqryPerfiles: TUniQuery;
    unstdGrabarPerfil: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GrabarPerfil(psuser, pskey, pssubkey, psvalue:string;
                           psValueText:WideString = '');
    procedure Assign_Profile_Dict(pskey:string; var oDict: TProfileUserDicc);

    procedure AddRecordToDict(fpProfile: TFieldsProfile;
                              var oDict : TProfileUserDicc);
    function GetKeySubKeyValueDefNoDic(skey, sSubKey, sDef: string): string;
  end;

var
  dmPerfiles: TdmPerfiles;

implementation

uses inLibGlobalVar, System.SysConst;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPerfiles.AddRecordToDict(fpProfile: TFieldsProfile;
                                      var oDict : TProfileUserDicc);
var
  dvValue: TDictValue;
  dukDictUser: TDictUserKey;
begin
  dukDictUser.sUser := inLibGlobalVar.oUser;
  dukDictUser.sGroup := inLibGlobalVar.oGroup;
  dukDictUser.sKey := fpProfile.pKEY_PERFILES;
  if ( (dukDictUser.sUser) = (fpProfile.pUSUARIO_GRUPO_PERFILES) ) then
    dukDictUser.oProperty := User;
  if ( (dukDictUser.sGroup) = (fpProfile.pUSUARIO_GRUPO_PERFILES) ) then
    dukDictUser.oProperty := Group;
  if ( (oAll) = (fpProfile.pUSUARIO_GRUPO_PERFILES) ) then
    dukDictUser.oProperty := All;
  dukDictUser.sSubkey := (fpProfile.pSUBKEY_PERFILES);
  dvValue.sValue := (fpProfile.pVALUE_PERFILES);
  dvValue.sValueText := fpProfile.pVALUE_TEXT_PERFILES;
  //oValue.typevalueblob := objFProfile.pTYPE_BLOB_PERFILES;
  //oValue.valueblob := objFProfile.pTYPE_BLOB_PERFILES;
  oDict.Add(dukDictUser,dvValue);
end;

procedure TdmPerfiles.Assign_Profile_Dict(pskey:string;
                                          var oDict: TProfileUserDicc);
var
  objFieldsProfile: TFieldsProfile;
begin
  oDict := TProfileUserDicc.Create;
  with unqryPerfiles do
  begin
    sql.Text :=  '  SELECT *  ' +
                 '    FROM fza_usuarios_perfiles ' +
                 '   WHERE (   USUARIO_GRUPO_PERFILES = :user ' +
                 '          OR USUARIO_GRUPO_PERFILES = :group' +
                 '          OR USUARIO_GRUPO_PERFILES = :todos)' +
                 '     AND KEY_PERFILES = :key ' +
                 '     AND TYPE_BLOB_PERFILES IS NULL ' +
                 'ORDER BY USUARIO_GRUPO_PERFILES, KEY_PERFILES';
    ParamByName('user').AsString := oUser;
    ParamByName('group').AsString := oGroup;
    ParamByName('key').AsString := pskey;
    ParamByName('todos').AsString := oAll;
    Open;
    First;
    while not Eof do
    begin
      objFieldsProfile.pUSUARIO_GRUPO_PERFILES:=
                                   FindField('USUARIO_GRUPO_PERFILES').AsString;
      objFieldsProfile.pKEY_PERFILES:=
                                             FindField('KEY_PERFILES').AsString;
      objFieldsProfile.pSUBKEY_PERFILES:=
                                          FindField('SUBKEY_PERFILES').AsString;
      objFieldsProfile.pVALUE_PERFILES:=
                                           FindField('VALUE_PERFILES').AsString;
      objFieldsProfile.pVALUE_TEXT_PERFILES         :=
                                  FindField('VALUE_TEXT_PERFILES').AsWideString;
      //objFieldsProfile.pTYPE_BLOB_PERFILES
      //:= FindField('TYPE_BLOB_PERFILES').AsVariant;
      //objFieldsProfile.pVALUE_BLOB_PERFILES
      //:= FindField('VALUE_BLOB_PERFILES').AsString;
      AddRecordToDict(objFieldsProfile, oDict);
      Next;
    end;
    Close;
  end;
end;

procedure TdmPerfiles.DataModuleCreate(Sender: TObject);
begin
  inherited;
//
end;

procedure TdmPerfiles.DataModuleDestroy(Sender: TObject);
begin
  //
end;

function TdmPerfiles.GetKeySubKeyValueDefNoDic(skey,
                                               sSubKey,
                                               sDef: string): string;
var
  bUser, bGroup, bAll:Boolean;
  sUserResult, sGroupResult, sAllResult:string;
begin
  bUser := False;
  bGroup := False;
  bAll := False;
with unqryPerfiles do
  begin
    Connection := oConn;
    Sql.Text :=  '  SELECT *  ' +
                 '    FROM fza_usuarios_perfiles ' +
                 '   WHERE  (   USUARIO_GRUPO_PERFILES = :user ' +
                  '          OR USUARIO_GRUPO_PERFILES = :group' +
                  '          OR USUARIO_GRUPO_PERFILES = :todos)' +
                 '     AND KEY_PERFILES = :key ' +
                 '     AND SUBKEY_PERFILES = :subkey ' +
                 '     AND TYPE_BLOB_PERFILES IS NULL ' +
                 'ORDER BY USUARIO_GRUPO_PERFILES, KEY_PERFILES';
    ParamByName('user').AsString := oUser;
    ParamByName('group').AsString := oGroup;
    ParamByName('key').AsString := skey;
    ParamByName('subkey').AsString := sSubKey;
    ParamByName('todos').AsString := oAll;
    Open;
    First;
    while not Eof do
    begin
      if (FindField('USUARIO_GRUPO_PERFILES').AsString = oUser) then
      begin
        bUser := True;
        sUserResult := FindField('VALUE_PERFILES').AsString
      end
      else
      begin
        if (FindField('USUARIO_GRUPO_PERFILES').AsString = oGroup) then
        begin
          sGroupResult := FindField('VALUE_PERFILES').AsString;
          bGroup := True;
        end
        else
        begin
          sAllResult := FindField('VALUE_PERFILES').AsString;
          bAll := True;
        end;
      end;
      Next;
    end;
  end;
  if bUser then
    Result:= sUserResult
  else
    if bGroup then
      Result := sGroupResult
    else
     if bAll then
       Result := sAllResult
     else
       Result := sDef;
end;

procedure TdmPerfiles.GrabarPerfil(psuser, pskey, pssubkey, psvalue: string;
                                   psValueText:WideString = '');
begin
  unstdGrabarPerfil.Connection := oConn;
  unstdGrabarPerfil.ParamByName('pUSUARIO').AsString := psuser;
  unstdGrabarPerfil.ParamByName('pKEY').AsString := pskey;
  unstdGrabarPerfil.ParamByName('pSUBKEY').AsString := pssubkey;
  unstdGrabarPerfil.ParamByName('pVALUE').AsString := psvalue;
  unstdGrabarPerfil.ParamByName('pVALUE_TEXT').AsWideString := psValueText;
  unstdGrabarPerfil.ParamByName('pUSUARIO_MODIF').AsString := oUser;
  unstdGrabarPerfil.Execute;
end;

procedure TdmPerfiles.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

end.
