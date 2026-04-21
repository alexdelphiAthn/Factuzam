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
    TPerfilItem = record
    UserGroup: string;
    KeyPerfil: string;
    SubKey: string;
    Value: string;
  end;
  TPerfilList = TList<TPerfilItem>;
  TdmPerfiles = class(TDataModule)
    unqryPerfiles: TUniQuery;
    unstdGrabarPerfil: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
public
    // Métodos existentes mejorados
    procedure GrabarPerfil(psuser, pskey, pssubkey, psvalue: string; psValueText: WideString = '');
    procedure GrabarPerfilesBatch(const AItems: TPerfilList);
    procedure Assign_Profile_Dict(pskey: string; var oDict: TProfileUserDicc);
    procedure AddRecordToDict(fpProfile: TFieldsProfile; var oDict: TProfileUserDicc);
    function GetKeySubKeyValueDefNoDic(skey, sSubKey, sDef: string): string;

    // NUEVOS MÉTODOS para centralizar lógica y evitar SQL en los formularios
    function GetProfileSubKey(sKey: string; sDef: string = ''): string;
    procedure DeleteProfile(sUserGroup, sKey: string; sSubKey: string = '');
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

procedure TdmPerfiles.DeleteProfile(sUserGroup, sKey: string; sSubKey: string = '');
var
  unqryDelete: TUniQuery;
begin
  unqryDelete := TUniQuery.Create(nil);
  try
    unqryDelete.Connection := oConn;
    unqryDelete.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                            ' WHERE USUARIO_GRUPO_PERFILES = :UserGroup ' +
                            '   AND KEY_PERFILES = :Key';

    // Si pasamos un SubKey, lo añadimos a la condición de borrado
    if sSubKey <> '' then
      unqryDelete.SQL.Add(' AND SUBKEY_PERFILES = :SubKey');

    unqryDelete.ParamByName('UserGroup').AsString := sUserGroup;
    unqryDelete.ParamByName('Key').AsString := sKey;
    if sSubKey <> '' then
      unqryDelete.ParamByName('SubKey').AsString := sSubKey;

    unqryDelete.Execute;
  finally
    unqryDelete.Free;
  end;
end;

function TdmPerfiles.GetKeySubKeyValueDefNoDic(skey, sSubKey, sDef: string): string;
begin
  Result := sDef;
  with unqryPerfiles do
  begin
    Close;
    // Delegamos la jerarquía al motor SQL. El que quede primero será el de mayor prioridad.
    SQL.Text := '  SELECT VALUE_PERFILES ' +
                '    FROM fza_usuarios_perfiles ' +
                '   WHERE KEY_PERFILES = :key ' +
                '     AND SUBKEY_PERFILES = :subkey ' +
                '     AND USUARIO_GRUPO_PERFILES IN (:user, :group, :todos) ' +
                '     AND TYPE_BLOB_PERFILES IS NULL ' +
                'ORDER BY CASE USUARIO_GRUPO_PERFILES ' +
                '            WHEN :user THEN 1 ' +
                '            WHEN :group THEN 2 ' +
                '            WHEN :todos THEN 3 ' +
                '         END';
    ParamByName('user').AsString := oUser;
    ParamByName('group').AsString := oGroup;
    ParamByName('todos').AsString := oAll;
    ParamByName('key').AsString := skey;
    ParamByName('subkey').AsString := sSubKey;
    Open;

    // Como está ordenado por prioridad, si hay registros, el primero es el correcto
    if not IsEmpty then
      Result := FieldByName('VALUE_PERFILES').AsString;

    Close;
  end;
end;

function TdmPerfiles.GetProfileSubKey(sKey: string; sDef: string = ''): string;
begin
  Result := sDef;
  with unqryPerfiles do
  begin
    Close;
    SQL.Text := '  SELECT SUBKEY_PERFILES ' +
                '    FROM fza_usuarios_perfiles ' +
                '   WHERE KEY_PERFILES = :key ' +
                '     AND USUARIO_GRUPO_PERFILES IN (:user, :group, :todos) ' +
                'ORDER BY CASE USUARIO_GRUPO_PERFILES ' +
                '            WHEN :user THEN 1 ' +
                '            WHEN :group THEN 2 ' +
                '            WHEN :todos THEN 3 ' +
                '         END';
    ParamByName('key').AsString := sKey;
    ParamByName('user').AsString := oUser;
    ParamByName('group').AsString := oGroup;
    ParamByName('todos').AsString := oAll;
    Open;

    if not IsEmpty then
      Result := FieldByName('SUBKEY_PERFILES').AsString;

    Close;
  end;
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

procedure TdmPerfiles.GrabarPerfilesBatch(const AItems: TPerfilList);
const
  BATCH_SIZE = 500;
var
  i, iStart, iEnd: Integer;
  sSQL: TStringBuilder;
  qry: TUniQuery;
  sUsuarioActual: string;
begin
  if (AItems = nil) or (AItems.Count = 0) then Exit;

  // El usuario que está grabando, para USUARIOALTA / USUARIOMODIF
  sUsuarioActual := inLibGlobalVar.oUser;

  qry := TUniQuery.Create(nil);
  sSQL := TStringBuilder.Create;
  try
    qry.Connection := oConn;

    iStart := 0;
    while iStart < AItems.Count do
    begin
      iEnd := iStart + BATCH_SIZE - 1;
      if iEnd >= AItems.Count then
        iEnd := AItems.Count - 1;

      sSQL.Clear;
      sSQL.Append(
        'INSERT INTO fza_usuarios_perfiles ' +
        '(USUARIO_GRUPO_PERFILES, KEY_PERFILES, SUBKEY_PERFILES, VALUE_PERFILES, ' +
        ' INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
        'VALUES ');

      for i := iStart to iEnd do
      begin
        if i > iStart then sSQL.Append(',');
        sSQL.AppendFormat(
          '(:u%d, :k%d, :s%d, :v%d, CURRENT_TIMESTAMP, :ua, :ua)',
          [i, i, i, i]);
      end;

      sSQL.Append(
        ' ON DUPLICATE KEY UPDATE ' +
        '  VALUE_PERFILES = VALUES(VALUE_PERFILES), ' +
        '  USUARIOMODIF   = VALUES(USUARIOMODIF)');

      qry.SQL.Text := sSQL.ToString;
      qry.ParamByName('ua').AsString := sUsuarioActual;

      for i := iStart to iEnd do
      begin
        qry.ParamByName(Format('u%d', [i])).AsString := AItems[i].UserGroup;
        qry.ParamByName(Format('k%d', [i])).AsString := AItems[i].KeyPerfil;
        qry.ParamByName(Format('s%d', [i])).AsString := AItems[i].SubKey;
        qry.ParamByName(Format('v%d', [i])).AsString := AItems[i].Value;
      end;

      qry.Execute;
      iStart := iEnd + 1;
    end;
  finally
    sSQL.Free;
    qry.Free;
  end;
end;

procedure TdmPerfiles.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

end.
