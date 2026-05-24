{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPerfiles                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de perfiles de usuario.                                       }
{    Lectura y grabación de fza_perfiles para preferencias de usuario y grupo. }
{******************************************************************************}
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
    FCachePerfilesForm: TObjectDictionary<string, TProfileDicc>;
    FCachePrecargada: Boolean;
    function ClonarPerfilDicc(AOrigen: TProfileDicc): TProfileDicc;
    function CargarPerfilFormDesdeDB(const AFormName: string): TProfileDicc;
  public
    // Métodos existentes mejorados
    procedure GrabarPerfil(psuser,
                           pskey,
                           pssubkey,
                           psvalue: string;
                           psValueText: WideString = '');
    procedure GrabarPerfilesBatch(const AItems: TPerfilList);
    procedure Assign_Profile_Dict(pskey: string; var oDict: TProfileUserDicc);
    procedure AddRecordToDict(fpProfile: TFieldsProfile;
                              var oDict: TProfileUserDicc);
    function GetKeySubKeyValueDefNoDic(skey, sSubKey, sDef: string): string;

    // NUEVOS MÉTODOS para centralizar lógica y evitar SQL en los formularios
    function GetProfileSubKey(sKey: string; sDef: string = ''): string;
    procedure DeleteProfile(sUserGroup, sKey: string; sSubKey: string = '');

    // Caché en memoria de perfiles de formulario (KEY_USUPER -> SUBKEY -> Value)
    // resueltos por prioridad user > group > Todos. Se precarga al login para
    // que GetFormUserProfile no llame a PRC_GETPERFILFORMULARIO en cada apertura.
    procedure PrecargarPerfilesUsuario;
    function ObtenerPerfilFormCache(const AFormName: string;
                                    out APerfilDic: TProfileDicc): Boolean;
    procedure ResincronizarCachePerfilForm(const AFormName: string);
    procedure InvalidarCachePerfiles;
    property CachePrecargada: Boolean read FCachePrecargada;
  end;

var
  dmPerfiles: TdmPerfiles;

implementation

uses inLibGlobalVar, inLibLog, System.SysConst;

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
                 '   WHERE (   USUARIO_GRUPO_USUPER = :user ' +
                 '          OR USUARIO_GRUPO_USUPER = :group' +
                 '          OR USUARIO_GRUPO_USUPER = :todos)' +
                 '     AND KEY_USUPER = :key ' +
                 '     AND TYPE_BLOB_USUPER IS NULL ' +
                 'ORDER BY USUARIO_GRUPO_USUPER, KEY_USUPER';
    ParamByName('user').AsString := oUser;
    ParamByName('group').AsString := oGroup;
    ParamByName('key').AsString := pskey;
    ParamByName('todos').AsString := oAll;
    Open;
    First;
    while not Eof do
    begin
      objFieldsProfile.pUSUARIO_GRUPO_PERFILES:=
                                   FindField('USUARIO_GRUPO_USUPER').AsString;
      objFieldsProfile.pKEY_PERFILES:=
                                             FindField('KEY_USUPER').AsString;
      objFieldsProfile.pSUBKEY_PERFILES:=
                                          FindField('SUBKEY_USUPER').AsString;
      objFieldsProfile.pVALUE_PERFILES:=
                                           FindField('VALUE_USUPER').AsString;
      objFieldsProfile.pVALUE_TEXT_PERFILES         :=
                                  FindField('VALUE_TEXT_USUPER').AsWideString;
      //objFieldsProfile.pTYPE_BLOB_PERFILES
      //:= FindField('TYPE_BLOB_USUPER').AsVariant;
      //objFieldsProfile.pVALUE_BLOB_PERFILES
      //:= FindField('VALUE_BLOB_USUPER').AsString;
      AddRecordToDict(objFieldsProfile, oDict);
      Next;
    end;
    Close;
  end;
end;

procedure TdmPerfiles.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FCachePerfilesForm := TObjectDictionary<string, TProfileDicc>.Create(
    [doOwnsValues]);
  FCachePrecargada := False;
end;

procedure TdmPerfiles.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FCachePerfilesForm);
end;

function TdmPerfiles.ClonarPerfilDicc(AOrigen: TProfileDicc): TProfileDicc;
var
  oPair: TPair<string, TDictValue>;
begin
  Result := TProfileDicc.Create;
  if AOrigen = nil then Exit;
  for oPair in AOrigen do
    Result.AddOrSetValue(oPair.Key, oPair.Value);
end;

function TdmPerfiles.CargarPerfilFormDesdeDB(
                                   const AFormName: string): TProfileDicc;
var
  qry: TUniQuery;
  v: TDictValue;
begin
  Result := TProfileDicc.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    // Mismo criterio de resolución que PRC_GETPERFILFORMULARIO: por cada
    // SUBKEY queda la fila con USUARIO_GRUPO de mayor prioridad. Lo conseguimos
    // ordenando ascendente por prioridad (Todos -> Group -> User) e iterando
    // con AddOrSetValue: la última asignación, que es la de mayor prioridad,
    // sobreescribe a las anteriores.
    qry.SQL.Text :=
      'SELECT SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER ' +
      '  FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER = :key ' +
      '   AND USUARIO_GRUPO_USUPER IN (:u, :g, :a) ' +
      ' ORDER BY SUBKEY_USUPER, ' +
      '          CASE USUARIO_GRUPO_USUPER ' +
      '            WHEN :a THEN 1 ' +
      '            WHEN :g THEN 2 ' +
      '            WHEN :u THEN 3 ' +
      '          END';
    qry.ParamByName('key').AsString := AFormName;
    qry.ParamByName('u').AsString   := oUser;
    qry.ParamByName('g').AsString   := oGroup;
    qry.ParamByName('a').AsString   := oAll;
    qry.Open;
    while not qry.Eof do
    begin
      v.sValue     := qry.FieldByName('VALUE_USUPER').AsString;
      v.sValueText := qry.FieldByName('VALUE_TEXT_USUPER').AsWideString;
      Result.AddOrSetValue(qry.FieldByName('SUBKEY_USUPER').AsString, v);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmPerfiles.PrecargarPerfilesUsuario;
var
  qry: TUniQuery;
  sKeyForm, sSubKey: string;
  v: TDictValue;
  PerfilDic: TProfileDicc;
  iFilas, iForms: Integer;
begin
  Log.LogInfo(Format('PrecargarPerfilesUsuario: INICIO ' +
                     'oUser="%s" oGroup="%s" oAll="%s" ' +
                     'oConnAssigned=%s oConnConnected=%s',
                     [oUser, oGroup, oAll,
                      BoolToStr(oConn <> nil, True),
                      BoolToStr((oConn <> nil) and oConn.Connected, True)]));
  FCachePerfilesForm.Clear;
  FCachePrecargada := False;
  if (oConn = nil) or (not oConn.Connected) then
  begin
    Log.LogWarning('PrecargarPerfilesUsuario: ABORTADA, oConn no disponible. ' +
                   'FCachePrecargada queda False');
    Exit;
  end;
  iFilas := 0;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text :=
        'SELECT KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER ' +
        '  FROM fza_usuarios_perfiles ' +
        ' WHERE USUARIO_GRUPO_USUPER IN (:u, :g, :a) ' +
        ' ORDER BY KEY_USUPER, SUBKEY_USUPER, ' +
        '          CASE USUARIO_GRUPO_USUPER ' +
        '            WHEN :a THEN 1 ' +
        '            WHEN :g THEN 2 ' +
        '            WHEN :u THEN 3 ' +
        '          END';
      qry.ParamByName('u').AsString := oUser;
      qry.ParamByName('g').AsString := oGroup;
      qry.ParamByName('a').AsString := oAll;
      qry.Open;
      while not qry.Eof do
      begin
        sKeyForm := qry.FieldByName('KEY_USUPER').AsString;
        sSubKey  := qry.FieldByName('SUBKEY_USUPER').AsString;
        v.sValue     := qry.FieldByName('VALUE_USUPER').AsString;
        v.sValueText := qry.FieldByName('VALUE_TEXT_USUPER').AsWideString;
        if not FCachePerfilesForm.TryGetValue(sKeyForm, PerfilDic) then
        begin
          PerfilDic := TProfileDicc.Create;
          FCachePerfilesForm.Add(sKeyForm, PerfilDic);
        end;
        PerfilDic.AddOrSetValue(sSubKey, v);
        Inc(iFilas);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    FCachePrecargada := True;
    iForms := FCachePerfilesForm.Count;
    Log.LogInfo(Format('PrecargarPerfilesUsuario: OK ' +
                       'filas=%d forms_distintos=%d FCachePrecargada=True',
                       [iFilas, iForms]));
    // Listar los forms cacheados para saber exactamente qué se precargó
    for sKeyForm in FCachePerfilesForm.Keys do
      Log.LogInfo(Format('PrecargarPerfilesUsuario: cache form="%s" claves=%d',
                         [sKeyForm, FCachePerfilesForm[sKeyForm].Count]));
  except
    // Si la precarga falla, dejamos FCachePrecargada=False para que los
    // callers (GetFormUserProfile) caigan al camino SQL/SP anterior y la
    // app siga funcionando.
    on E: Exception do
    begin
      FCachePerfilesForm.Clear;
      Log.LogError(Format('PrecargarPerfilesUsuario: EXCEPCION %s: %s ' +
                          'filas_leidas_antes_fallo=%d. ' +
                          'FCachePrecargada queda False, cache vacio',
                          [E.ClassName, E.Message, iFilas]));
    end;
  end;
end;

function TdmPerfiles.ObtenerPerfilFormCache(const AFormName: string;
                                       out APerfilDic: TProfileDicc): Boolean;
var
  Cached: TProfileDicc;
begin
  APerfilDic := nil;
  Result := False;
  if not FCachePrecargada then
  begin
    Log.LogWarning(Format('ObtenerPerfilFormCache: form="%s" cache NO precargado ' +
                          '(FCachePrecargada=False), devuelve False', [AFormName]));
    Exit;
  end;
  // Servimos siempre un clon: el caller (TLayoutLoader, etc.) hace
  // FreeAndNil de FPerfil en su Destroy. Si devolviéramos la referencia
  // cacheada, la siguiente apertura del mismo form crashearía.
  if FCachePerfilesForm.TryGetValue(AFormName, Cached) then
  begin
    APerfilDic := ClonarPerfilDicc(Cached);
    Log.LogInfo(Format('ObtenerPerfilFormCache: form="%s" HIT claves=%d',
                       [AFormName, Cached.Count]));
  end
  else
  begin
    APerfilDic := TProfileDicc.Create;
    Log.LogWarning(Format('ObtenerPerfilFormCache: form="%s" MISS ' +
                          '(precargado pero sin entrada), devuelve dicc vacio ' +
                          'con Result=True', [AFormName]));
  end;
  Result := True;
end;

procedure TdmPerfiles.ResincronizarCachePerfilForm(const AFormName: string);
var
  Nuevo: TProfileDicc;
begin
  if not FCachePrecargada then
  begin
    Log.LogWarning(Format('ResincronizarCachePerfilForm: form="%s" ' +
                          'cache no precargado, ignorado', [AFormName]));
    Exit;
  end;
  Nuevo := CargarPerfilFormDesdeDB(AFormName);
  if Nuevo.Count > 0 then
  begin
    FCachePerfilesForm.AddOrSetValue(AFormName, Nuevo);
    Log.LogInfo(Format('ResincronizarCachePerfilForm: form="%s" actualizado ' +
                       'claves=%d', [AFormName, Nuevo.Count]));
  end
  else
  begin
    FreeAndNil(Nuevo);
    FCachePerfilesForm.Remove(AFormName);
    Log.LogInfo(Format('ResincronizarCachePerfilForm: form="%s" sin filas, ' +
                       'eliminado del cache', [AFormName]));
  end;
end;

procedure TdmPerfiles.InvalidarCachePerfiles;
begin
  Log.LogInfo('InvalidarCachePerfiles: limpio cache y marco no precargado');
  FCachePerfilesForm.Clear;
  FCachePrecargada := False;
end;

procedure TdmPerfiles.DeleteProfile(sUserGroup,
                                    sKey: string;
                                    sSubKey: string = '');
var
  unqryDelete: TUniQuery;
begin
  unqryDelete := TUniQuery.Create(nil);
  try
    unqryDelete.Connection := oConn;
    unqryDelete.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                            ' WHERE USUARIO_GRUPO_USUPER = :UserGroup ' +
                            '   AND KEY_USUPER = :Key';

    // Si pasamos un SubKey, lo añadimos a la condición de borrado
    if sSubKey <> '' then
      unqryDelete.SQL.Add(' AND SUBKEY_USUPER = :SubKey');

    unqryDelete.ParamByName('UserGroup').AsString := sUserGroup;
    unqryDelete.ParamByName('Key').AsString := sKey;
    if sSubKey <> '' then
      unqryDelete.ParamByName('SubKey').AsString := sSubKey;

    unqryDelete.Execute;
  finally
    FreeAndNil(unqryDelete);
  end;
  ResincronizarCachePerfilForm(sKey);
end;

function TdmPerfiles.GetKeySubKeyValueDefNoDic(skey,
                                               sSubKey,
                                               sDef: string): string;
begin
  Result := sDef;
  with unqryPerfiles do
  begin
    Close;
    // Delegamos la jerarquía al motor SQL. El que quede primero será el de
    // mayor prioridad.
    SQL.Text := '  SELECT VALUE_USUPER ' +
                '    FROM fza_usuarios_perfiles ' +
                '   WHERE KEY_USUPER = :key ' +
                '     AND SUBKEY_USUPER = :subkey ' +
                '     AND USUARIO_GRUPO_USUPER IN (:user, :group, :todos) ' +
                '     AND TYPE_BLOB_USUPER IS NULL ' +
                'ORDER BY CASE USUARIO_GRUPO_USUPER ' +
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

    // Como está ordenado por prioridad, si hay registros, el primero es el
    // correcto
    if not IsEmpty then
      Result := FieldByName('VALUE_USUPER').AsString;

    Close;
  end;
end;

function TdmPerfiles.GetProfileSubKey(sKey: string; sDef: string = ''): string;
begin
  Result := sDef;
  with unqryPerfiles do
  begin
    Close;
    SQL.Text := '  SELECT SUBKEY_USUPER ' +
                '    FROM fza_usuarios_perfiles ' +
                '   WHERE KEY_USUPER = :key ' +
                '     AND USUARIO_GRUPO_USUPER IN (:user, :group, :todos) ' +
                'ORDER BY CASE USUARIO_GRUPO_USUPER ' +
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
      Result := FieldByName('SUBKEY_USUPER').AsString;

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
  unstdGrabarPerfil.ParamByName('pVALUE_TEXT').AsString := psValueText;
  unstdGrabarPerfil.ParamByName('pUSUARIO_MODIF').AsString := oUser;
  unstdGrabarPerfil.Execute;
  ResincronizarCachePerfilForm(pskey);
end;

procedure TdmPerfiles.GrabarPerfilesBatch(const AItems: TPerfilList);
const
  BATCH_SIZE = 500;
var
  i, iStart, iEnd: Integer;
  sSQL: TStringBuilder;
  qry: TUniQuery;
  sUsuarioActual: string;
  oClavesAfectadas: TList<string>;
  sClave: string;
begin
  if (AItems = nil) or (AItems.Count = 0) then Exit;

  // El usuario que está grabando, para USUARIO_ALTA / USUARIO_MODIF
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
        '(USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, VALUE_USUPER, ' +
        ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
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
        '  VALUE_USUPER = VALUES(VALUE_USUPER), ' +
        '  USUARIO_MODIF   = VALUES(USUARIO_MODIF)');

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
    FreeAndNil(sSQL);
    FreeAndNil(qry);
  end;

  // Resincronizar la caché solo para las KEY tocadas
  oClavesAfectadas := TList<string>.Create;
  try
    for i := 0 to AItems.Count - 1 do
      if oClavesAfectadas.IndexOf(AItems[i].KeyPerfil) < 0 then
        oClavesAfectadas.Add(AItems[i].KeyPerfil);
    for sClave in oClavesAfectadas do
      ResincronizarCachePerfilForm(sClave);
  finally
    FreeAndNil(oClavesAfectadas);
  end;
end;

procedure TdmPerfiles.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

end.
