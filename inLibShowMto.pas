{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibShowMto;

interface

uses
  System.Generics.Defaults, System.Generics.Collections, System.Contnrs,
  Classes, Windows, Forms, Menus, Controls, Uni,   System.SysUtils, UniDataGen,
  Vcl.Dialogs, ShellAPI, System.Rtti, System.TypInfo, System.Variants,
  System.StrUtils, inLibUser, Vcl.Buttons, inlibGlobalVar, inMtoGen,
  system.math, System.IOUtils, inLibWin, cxPC, Types, Vcl.Consts;

type
  TFormBaseClass = class of TForm;
  function BuscarTabla(Query: TUniQuery;
                       const ClavePrimaria,
                       Valores: string):Boolean;
  procedure ShowMto(Owner: TComponent;
                    sCall:String;
                    sBusq:string = '');
  function CrearDataModule(sDataUnit:String;var pOwner:TfrmMtoGen):TdmBase;

implementation

 uses
      inLibMsg,
      inMtoPrincipal2,
      inLibLog,
      inLibUnitForm;

procedure ShowMto (Owner:TComponent;
                   sCall:String;
                   sBusq:string = '');
var
  frmOpen2: TfrmOpenApp2;
  iAbiertaPes : integer;
  sTitle :string;
  tsNew: TcxTabSheet;
  ctx:TRttiContext;
  lType:TRttiType;
  f,val : TValue;
  prop: TRttiProperty;
  dmDat: TdmBase;
  frmGen:TfrmMtoGen;
  sUnidadTipo:String;
  sDataUnit:String;
  sPkTab:String;
  mMenu : TMenuItem;
  ofzaF: TfzaForm;
begin
  frmOpen2 := (Owner as TfrmOpenApp2);
  ofzaF := frmOpen2.oFzaWinf.GetElement(sCall);
  if ofzaF = nil then
  begin
    ShowMessageFmt(SResWinFNotFnd, [sCall]);
    Exit;
  end;
  mMenu := ofzaF.mnMenuItem;
  sTitle := ofzaf.Caption;
  sUnidadTipo := ofzaf.UnitForm;
  sDataUnit := ofzaf.DataUnit;
  if (mMenu.Visible) then
  begin
    iAbiertaPes := EncuentraPagina(frmOpen2.pcPrincipal, sTitle);
    if (iAbiertaPes = -1) then
    begin
      tsNew := TcxTabSheet.Create(frmOpen2.pcPrincipal);
      tsNew.PageControl := frmOpen2.pcPrincipal;
      ctx := TRttiContext.Create;
      try
        //https://stackoverflow.com/questions/10613094/
        //how-can-i-make-sure-rtti-is-available-for-a-
        //class-without-instantiating-it/10613212#10613212
        lType:= ctx.FindType(sUnidadTipo);
        if (lType<>nil) then
        begin
          f:= TFormBaseClass(
                         GetTypeData(lType.Handle)^.ClassType).Create(frmOpen2);
          //f:= t.GetMethod('Create').Invoke(t.MetaclassType,[nil]);
          tsNew.Caption := sTitle;
          inLibLog.Log.LogInfo('Abriendo Pantalla Mto: '+ sTitle);
          prop := lType.GetProperty('Parent');
          prop.SetValue(f.asObject, (tsNew as TObject));
          prop := lType.GetProperty('Align');
          val := TValue.From<TAlign>(alClient);
          prop.SetValue(f.asObject, val);
        end
        else
        begin
          ShowMessageFmt(SClassRttiNotFnd, [sUnidadTipo]);
        end;
        //https://stackoverflow.com/questions/14742505/
        //how-do-i-intantiate-a-class-from-its-trttitype
      finally
        ctx.Free;
      end;
      iAbiertaPes := EncuentraPagina(frmOpen2.pcPrincipal, sTitle);
    end;
    if (iAbiertaPes <> -1) then
        frmOpen2.pcPrincipal.ActivePageIndex := iAbiertaPes;
    if (iAbiertaPes <> -1) and (sBusq <> '') then
    begin
      //existe el formulario en la pestaña, entonces si hay búsqueda de dato
      tsNew := frmOpen2.pcPrincipal.Pages[iAbiertaPes];
      if (tsNew.Controls[0] is TfrmMtoGen) then
      begin
        frmGen := (tsNew.Controls[0] as TfrmMtoGen);
        sPkTab := frmGen.pkFieldName;
        dmDat := frmGen.tdmDataModule;
        if not BuscarTabla(dmDat.unqryTablaG, sPkTab, sBusq)  then
          ShowMessageFmt(SLocateNotFnd, [sBusq, sTitle])
        else
        begin
          if (frmGen.tsFicha.TabVisible = True) then
            frmGen.pcPantalla.ActivePage := frmGen.tsFicha;
        end;
      end;
    end;
  end;
end;

//https://stackoverflow.com/questions/14742505/
// how-do-i-instantiate-a-class-from-its-trttitype
function CrearDataModule(sDataUnit:String; var pOwner:TfrmMtoGen):TdmBase;
type
  TDataMBaseClass = class of TDataModule;
var
  ctx: TRttiContext;
  lType: TRttiType;
  f: TValue;
begin
  ctx := TRttiContext.Create;
  Result := nil;
  try
    lType:= ctx.FindType(sDataUnit);
    if (lType<>nil) then
    begin
      f:= TDataMBaseClass(GetTypeData(lType.Handle)^.ClassType).Create(pOwner);
      begin
        Result := (f.AsObject as TdmBase);
      end;
    end;
  finally
    ctx.Free;
  end;
end;

function BuscarTabla(Query: TUniQuery;
                     const ClavePrimaria,
                     Valores: string):Boolean;
var
  ValArr: TArray<string>;
  bIsOnlyOne:boolean;
  I:integer;
  miArray: array of Variant;
begin
  bIsOnlyOne := false;
  Result := False;
  ValArr := Valores.Split([',']);
  if Length(ValArr) = 1 then
    bIsOnlyOne := True
  else
  begin
    SetLength(miarray, Length(ValArr));
    for i := 0 to Length(ValArr) - 1 do
      miarray[i] := Trim(ValArr[i]);
  end;
  if Query.Active then
  begin
    Query.Refresh;
    if bIsonlyOne then
    begin
      if Query.Locate(ClavePrimaria, Valores, []) then
        Result := True;
    end
    else
    begin
      if Query.Locate(ClavePrimaria, miArray, []) then
      begin
        Finalize(ValArr);
        Finalize(miArray);
        Result := True;
      end;
    end;
  end;
end;

end.
