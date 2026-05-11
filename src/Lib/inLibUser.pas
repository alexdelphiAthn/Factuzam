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
function GetPerfilValue(var oPerfilDic: TProfileDicc; sSubKey: string): string;
function GetPerfilValueText(var oPerfilDic: TProfileDicc; sSubKey: string):
                                                                     WideString;
procedure FilterProfileUserGroup(var oPerfilUserDic: TProfileUserDicc;
                                 var oPerfilDic: TProfileDicc);
procedure GetFormUserProfile(var oPerfilDic: TProfileDicc;
                             sFormName: string); overload;
function GetPerfilSubKeyValueDef( var oPerfilDic: TProfileDicc;
                                  sSubKey: string;
                                  sSubSubKey: string;
                                  sValueDef: string): string;
function GetPerfilValueTextDef( var oPerfilDic: TProfileDicc;
                                sSubKey: string;
                                sValueDef: WideString): WideString;
function GetPerfilValueDef( var oPerfilDic: TProfileDicc;
                            sSubKey: string;
                            sValueDef: string): string;
procedure GetDictionaryKeySubKey( var oPerfilDic: TProfileDicc;
                                var oPerfilKeySub: TList<TComponent_Prop_Value>;
                                sFieldName,
                                sColumnName,
                                sGridViewName: string);
procedure GetFormUserProfile(var oPerfilDic: TProfileDicc;
                           const sFormName, sUsuario, sGrupo: string); overload;

//  procedure AbrirPerfiles(bTabVisible:Boolean; unqryPerfiles:TUniQuery; Sender:TComponent);

implementation

uses
  inLibDir, inLibWin,
  inLibGlobalVar;

// Dentro de inLibUser.pas
procedure GetFormUserProfile(var oPerfilDic: TProfileDicc;
  const sFormName, sUsuario, sGrupo: string);
var
  oDictValue: TDictValue;
  qPerfil: TUniQuery;
begin
  oPerfilDic := TProfileDicc.Create;
  oPerfilDic.Clear;
  qPerfil := TUniQuery.Create(nil);
  try
    qPerfil.Connection := inLibGlobalVar.oConn;
    qPerfil.SQL.Text := 'CALL PRC_GETPERFILFORMULARIO(:u, :g, :f)';
    qPerfil.Params[0].AsString := sUsuario;
    qPerfil.Params[1].AsString := sGrupo;
    qPerfil.Params[2].AsString := sFormName;
    qPerfil.Open;
    while not qPerfil.Eof do
    begin
      oDictValue.sValue := qPerfil.FieldByName('VALUE_USUPER').AsString;
      oDictValue.sValueText :=
                        qPerfil.FieldByName('VALUE_TEXT_USUPER').AsWideString;
      oPerfilDic.AddOrSetValue(qPerfil.FieldByName('SUBKEY_USUPER').AsString,
                               oDictValue);
      qPerfil.Next;
    end;
  finally
    qPerfil.Free;
  end;
end;

procedure FilterProfileUserGroup(var oPerfilUserDic: TProfileUserDicc;
  var oPerfilDic: TProfileDicc);
var
  oPerfilUserDicCopy: TProfileUserDicc;
  oDictUKey,
    oDictUKeyCopy   : TDictUserKey;
  oDictValue        : TDictValue;
  //Stopwatch         : TStopwatch;   // PARA MEDIR EL RENDIMIENTO DEL HASH
  //Elapsed           : TTimeSpan;
begin
  //Stopwatch := TStopwatch.StartNew;
  oPerfilUserDic.TrimExcess;
  oPerfilDic := TProfileDicc.Create;
  oPerfilUserDicCopy := TProfileUserDicc.Create
    (
      oPerfilUserDic,
      TEqualityComparer<TDictUserKey>.Construct
    (
    function(const Left, Right: TDictUserKey): Boolean
    begin
      Result := (Left.sUser = Right.sUser) and
        (Left.sGroup = Right.sGroup) and
        (Left.sKey = Right.sKey) and
        (Left.sSubKey = Right.sSubKey) and
        (Left.oProperty = Right.oProperty);
    end,
    function(const Value: TDictUserKey): Integer
    begin
      Result := Length(Value.sKey); //este hash da un mayor rendimiento ~35 ms
    end
    )
      );
  for oDictUKey in oPerfilUserDic.Keys do
  begin
    oDictUKeyCopy := oDictUKey;
    oPerfilUserDic.TryGetValue(oDictUKey, oDictValue);
    if (oDictUKey.oProperty = User) then
      //si hay user, no me lo pienso y lo inserto
    begin
      oPerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue);
    end
    else if (oDictUKey.oProperty = Group) then
      //si hay grupo, busco el mismo key-subkey para user
    begin
      oDictUKeyCopy.oProperty := User;
      if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
        //si no hay user con el mismo key, lo a�ado
        oPerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue);
      //a�ado al perfil por defecto para el grupo
    end
    else if (oDictUKey.oProperty = All) then
      //si hay todos, y no hay user o grupo, a�ado
    begin
      oDictUKeyCopy.oProperty := User;
      if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
      begin
        oDictUKeyCopy.oProperty := Group;
        if (not (oPerfilUserDicCopy.ContainsKey(oDictUKeyCopy))) then
          oPerfilDic.AddOrSetValue(oDictUKey.sSubkey, oDictValue)
            //a�ado al perfil por defecto
      end;
    end;
  end;
  oPerfilUserDicCopy.Free;
  //Elapsed := Stopwatch.Elapsed;
  //ShowMessage(Elapsed.TotalMilliseconds.ToString);
end;

procedure GetFormUserProfile(var oPerfilDic: TProfileDicc; sFormName: string);
var
  oPerfilUserDic    : TProfileUserDicc;
begin
  odmPerfiles.Assign_Profile_Dict(sFormName, oPerfilUserDic);
  FilterProfileUserGroup(oPerfilUserDic, oPerfilDic);
  FreeAndNil(oPerfilUserDic);
end;

// Dentro de inLibUser.pas
function GetPerfilValue(var oPerfilDic: TPRofileDicc;
  sSubKey: string): string;
var
  oDictValue: TDictValue;
begin
  oPerfilDic.TryGetValue(sSubKey, oDictValue);
  Result:= oDictValue.sValue;
end;

procedure GetDictionaryKeySubKey(var oPerfilDic: TProfileDicc;
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
  for oDictKey in oPerfilDic.Keys do
  begin
    oPerfilDic.TryGetValue(oDictKey, oDictValue);
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

function GetPerfilSubKeyValueDef(var oPerfilDic: TPRofileDicc;
  sSubKey: string;
  sSubSubKey: string;
  sValueDef: string): string;
var
  oDictValue        : TDictValue;
begin
  sSubKey := sSubKey + '_' + sSubSubKey;
  if oPerfilDic.ContainsKey(sSubKey) then
  begin
    oPerfilDic.TryGetValue(sSubKey,
      oDictValue);
    Result := oDictValue.sValue;
  end
  else
    Result := sValueDef;
end;

function GetPerfilValueText(var oPerfilDic: TPRofileDicc;
  sSubKey: string): WideString;
var
  oDictValue        : TDictValue;
begin
  oPerfilDic.TryGetValue(sSubKey,
    oDictValue);
  Result := oDictValue.sValueText;
end;

function GetPerfilValueTextDef(var oPerfilDic: TPRofileDicc;
  sSubKey: string;
  sValueDef: WideString): WideString;
var
  oDictValue        : TDictValue;
begin
  if ((oPerfilDic <> nil) and (oPerfilDic.Count > 0)) then
  begin
    oPerfilDic.TrimExcess;
    if oPerfilDic.ContainsKey(sSubKey) then
    begin
      oPerfilDic.TryGetValue(sSubKey,
        oDictValue);
      Result := oDictValue.sValueText;
    end
    else
      Result := sValueDef;
  end
  else
    Result := sValueDef;
end;

function GetPerfilValueDef(var oPerfilDic: TProfileDicc;
  sSubKey: string;
  sValueDef: string): string;
var
  oDictValue        : TDictValue;
begin
  if oPerfilDic.ContainsKey(sSubKey) then
  begin
    oPerfilDic.TryGetValue(sSubKey,
      oDictValue);
    Result := oDictValue.sValue;
  end
  else
    Result := sValueDef;
end;

end.

