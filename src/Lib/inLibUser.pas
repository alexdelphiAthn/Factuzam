{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUser                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión de perfiles de usuario y grupo.                                   }
{    Diccionarios de propiedades por usuario y filtros de carga.               }
{******************************************************************************}
unit inLibUser;

interface

uses Windows, Classes, System.Hash, System.Generics.Collections,
  System.SysUtils, Generics.Defaults, ShlObj, Uni, System.diagnostics,
  System.TimeSpan, vcl.dialogs;

type
  TProperty = (User, Group, All);
  TDictUserKey = record
    sUser: string;
    sGroup: string;
    oProperty: TProperty;
    sKey: string;
    sSubkey: string;
  end;
  TComponent_Prop_Value = record
    sKey: string;
    sSubkey: string;
    sValue: string;
  end;
  TDictValue = record
    sValue: string;
    sValueText: WideString;
  end;
  TProfileUserDicc = TDictionary<TDictUserKey, TDictValue>;
  TProfileDicc = TDictionary<string, TDictValue>;
function GetPerfilValue(var APerfilDic: TProfileDicc; ASubKey: string): string;
function GetPerfilValueText(var APerfilDic: TProfileDicc; ASubKey: string):
                                                                     WideString;
procedure FilterProfileUserGroup(var APerfilUserDic: TProfileUserDicc;
                                 var APerfilDic: TProfileDicc);
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
                             AFormName: string); overload;
function GetPerfilSubKeyValueDef( var APerfilDic: TProfileDicc;
                                  ASubKey: string;
                                  sSubSubKey: string;
                                  sValueDef: string): string;
function GetPerfilValueTextDef( var APerfilDic: TProfileDicc;
                                ASubKey: string;
                                sValueDef: WideString): WideString;
function GetPerfilValueDef( var APerfilDic: TProfileDicc;
                            ASubKey: string;
                            sValueDef: string): string;
procedure GetDictionaryKeySubKey( var APerfilDic: TProfileDicc;
                                var oPerfilKeySub: TList<TComponent_Prop_Value>;
                                sFieldName,
                                sColumnName,
                                sGridViewName: string);
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
                           const AFormName, sUsuario, sGrupo: string); overload;

// procedure AbrirPerfiles(bTabVisible:Boolean; unqryPerfiles:TUniQuery;
// Sender:TComponent);

implementation

uses
  inLibDir, inLibWin,
  inLibGlobalVar;

// Dentro de inLibUser.pas
procedure GetFormUserProfile(var APerfilDic: TProfileDicc;
  const AFormName, sUsuario, sGrupo: string);
var
  oDictValue: TDictValue;
  qPerfil: TUniQuery;
begin
  APerfilDic := TProfileDicc.Create;
  APerfilDic.Clear;
  qPerfil := TUniQuery.Create(nil);
  try
    qPerfil.Connection := inLibGlobalVar.oConn;
    qPerfil.SQL.Text := 'CALL PRC_GETPERFILFORMULARIO(:u, :g, :f)';
    qPerfil.Params[0].AsString := sUsuario;
    qPerfil.Params[1].AsString := sGrupo;
    qPerfil.Params[2].AsString := AFormName;
    qPerfil.Open;
    while not qPerfil.Eof do
    begin
      oDictValue.sValue := qPerfil.FieldByName('VALUE_USUPER').AsString;
      oDictValue.sValueText :=
                        qPerfil.FieldByName('VALUE_TEXT_USUPER').AsWideString;
      APerfilDic.AddOrSetValue(qPerfil.FieldByName('SUBKEY_USUPER').AsString,
                               oDictValue);
      qPerfil.Next;
    end;
  finally
    FreeAndNil(qPerfil);
  end;
end;

procedure FilterProfileUserGroup(var APerfilUserDic: TProfileUserDicc;
  var APerfilDic: TProfileDicc);
var
  oPerfilUserDicCopy: TProfileUserDicc;
  oDictUKey,
    oDictUKeyCopy   : TDictUserKey;
  oDictValue        : TDictValue;
  //Stopwatch         : TStopwatch;   // PARA MEDIR EL RENDIMIENTO DEL HASH
  //Elapsed           : TTimeSpan;
begin
  //Stopwatch := TStopwatch.StartNew;
  APerfilUserDic.TrimExcess;
  APerfilDic := TProfileDicc.Create;
  oPerfilUserDicCopy := TProfileUserDicc.Create
    (
      APerfilUserDic,
      TEqualityComparer<TDictUserKey>.Construct
    (
    function(const Left, Right: TDictUserKey): Boolean
    begin
      Result := (Left.sUser = Right.sUser) and
        (Left.sGroup = Right.sGroup) and
        (Left.sKey = Right.sKey) and
        (Left.ASubKey = Right.ASubKey) and
        (Left.oProperty = Right.oProperty);
    end,
    function(const Value: TDictUserKey): Integer
    begin
      Result := Length(Value.sKey); //este hash da un mayor rendimiento ~35 ms
    end
    )
      );
  for oDictUKey in APerfilUserDic.Keys do
  begin
    oDictUKeyCopy := oDictUKey;
    APerfilUserDic.TryGetValue(oDictUKey, oDictValue);
    if (oDictUKey.oProperty = User) then
      //si hay user, no me lo pienso y lo inserto
    begin
      APerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue);
    end
    else if (oDictUKey.oProperty = Group) then
      //si hay grupo, busco el mismo key-subkey para user
    begin
      oDictUKeyCopy.oProperty := User;
      if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
        //si no hay user con el mismo key, lo añado
        APerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue);
      //añado al perfil por defecto para el grupo
    end
    else if (oDictUKey.oProperty = All) then
      //si hay todos, y no hay user o grupo, añado
    begin
      oDictUKeyCopy.oProperty := User;
      if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
      begin
        oDictUKeyCopy.oProperty := Group;
        if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
          APerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue)
            //añado al perfil por defecto
      end;
    end;
  end;
  FreeAndNil(oPerfilUserDicCopy);
  //Elapsed := Stopwatch.Elapsed;
  //ShowMessage(Elapsed.TotalMilliseconds.ToString);
end;

procedure GetFormUserProfile(var APerfilDic: TProfileDicc; AFormName: string);
var
  oPerfilUserDic    : TProfileUserDicc;
begin
  odmPerfiles.Assign_Profile_Dict(AFormName, oPerfilUserDic);
  FilterProfileUserGroup(oPerfilUserDic, APerfilDic);
  FreeAndNil(oPerfilUserDic);
end;

// Dentro de inLibUser.pas
function GetPerfilValue(var APerfilDic: TPRofileDicc;
  ASubKey: string): string;
var
  oDictValue: TDictValue;
begin
  APerfilDic.TryGetValue(ASubKey, oDictValue);
  Result:= oDictValue.sValue;
end;

procedure GetDictionaryKeySubKey(var APerfilDic: TProfileDicc;
                                var oPerfilKeySub: TList<TComponent_Prop_Value>;
                                sFieldName,
                                sColumnName,
                                sGridViewName: string);
var
  oDictValue        : TDictValue;
  oDictKey          : string;
  iLastDelimiter    : Integer;
  pCPV              : TComponent_Prop_Value;
  sProperty         : string;
begin
  for oDictKey in APerfilDic.Keys do
  begin
    APerfilDic.TryGetValue(oDictKey, oDictValue);
    if (Pos(sFieldName, oDictKey) > 0) then
    begin
      iLastDelimiter := LastDelimiter('_', oDictKey) + 1;
      sProperty := Copy(oDictKey, iLastDelimiter, Length(oDictKey) -
        iLastDelimiter + 1);
      pCPV.sKey := sColumnName;
      pCPV.sSubkey := sProperty;
      pCPV.sValue := oDictValue.sValue;
      oPerfilKeySub.Add(pCPV);
    end;
  end;
end;

function GetPerfilSubKeyValueDef(var APerfilDic: TPRofileDicc;
  ASubKey: string;
  sSubSubKey: string;
  sValueDef: string): string;
var
  oDictValue        : TDictValue;
begin
  ASubKey := ASubKey + '_' + sSubSubKey;
  if APerfilDic.ContainsKey(ASubKey) then
  begin
    APerfilDic.TryGetValue(ASubKey,
      oDictValue);
    Result := oDictValue.sValue;
  end
  else
    Result := sValueDef;
end;

function GetPerfilValueText(var APerfilDic: TPRofileDicc;
  ASubKey: string): WideString;
var
  oDictValue        : TDictValue;
begin
  APerfilDic.TryGetValue(ASubKey,
    oDictValue);
  Result := oDictValue.sValueText;
end;

function GetPerfilValueTextDef(var APerfilDic: TPRofileDicc;
  ASubKey: string;
  sValueDef: WideString): WideString;
var
  oDictValue        : TDictValue;
begin
  if ((APerfilDic <> nil) and (APerfilDic.Count > 0)) then
  begin
    APerfilDic.TrimExcess;
    if APerfilDic.ContainsKey(ASubKey) then
    begin
      APerfilDic.TryGetValue(ASubKey,
        oDictValue);
      Result := oDictValue.sValueText;
    end
    else
      Result := sValueDef;
  end
  else
    Result := sValueDef;
end;

function GetPerfilValueDef(var APerfilDic: TProfileDicc;
  ASubKey: string;
  sValueDef: string): string;
var
  oDictValue        : TDictValue;
begin
  if APerfilDic.ContainsKey(ASubKey) then
  begin
    APerfilDic.TryGetValue(ASubKey,
      oDictValue);
    Result := oDictValue.sValue;
  end
  else
    Result := sValueDef;
end;

end.

