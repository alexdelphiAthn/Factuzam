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
                       ValoresBusqueda: string):Boolean;
  procedure ShowMto(Owner: TComponent;
                    sCall:String;
                    sBusq:string = '');
  function CrearDataModule(sDataUnit:String;var pOwner:TfrmMtoGen):TObject;

implementation

 uses
      inLibMsg,
      inMtoPrincipal,
      inLibLog,
      inLibUnitForm;
 var
   GlobalDataModules: TObjectDictionary<string, TDataModule>;

procedure ShowMto (Owner:TComponent;
                   sCall:String;
                   sBusq:string = '');
var
  frmOpen2: TfrmMtoPrincipal;
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
  frmOpen2 := (Owner as TfrmMtoPrincipal);
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
        lType:= ctx.FindType(sUnidadTipo);
        if (lType<>nil) then
        begin
          f:= TFormBaseClass(
                         GetTypeData(lType.Handle)^.ClassType).Create(frmOpen2);
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
      finally
        //ctx.Free;
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
        dmDat := (frmGen.tdmDataModule as TdmBase);
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

function CrearDataModule(sDataUnit: String; var pOwner: TfrmMtoGen): TObject;
type
  TDataMBaseClass = class of TDataModule;
var
  ctx: TRttiContext;
  lType: TRttiType;
  DataModuleClass: TClass;
  CacheKey: string;
  DataModule: TDataModule;
  InstanceType: TRttiInstanceType;
  Instance: TObject;
begin
  Result := nil;
  CacheKey := sDataUnit + '_' + IntToStr(NativeInt(pOwner));
  if not GlobalDataModules.TryGetValue(CacheKey, DataModule) then
  begin
    ctx := TRttiContext.Create;
    try
      lType := ctx.FindType(sDataUnit);
      if (lType <> nil) and (lType is TRttiInstanceType) then
      begin
        InstanceType := TRttiInstanceType(lType);
        DataModuleClass := InstanceType.MetaclassType;
        if DataModuleClass.InheritsFrom(TdmBase) then
        begin
          Instance := DataModuleClass.NewInstance;
          try
            TdmBase(Instance).FCurrentForm := pOwner;
            TDataModule(Instance).Create(nil);
            DataModule := TDataModule(Instance);
          except
            Instance.Free;
            raise;
          end;
        end
        else
        begin
          DataModule := TDataMBaseClass(DataModuleClass).Create(nil);
        end;
        if Assigned(DataModule) then
          GlobalDataModules.Add(CacheKey, DataModule);
      end;
    finally
      ctx.Free;
    end;
  end
  else
  begin
    if Assigned(DataModule) and (DataModule is TdmBase) then
      TdmBase(DataModule).CurrentForm := pOwner;
  end;
  Result := DataModule;
end;

function BuscarTabla(Query: TUniQuery;
                     const ClavePrimaria,
                     ValoresBusqueda: string):Boolean;
var
  ValArr: TArray<string>;
  bIsOnlyOne:boolean;
  I:integer;
  miArray: array of Variant;
begin
  bIsOnlyOne := false;
  Result := False;
  ValArr := ValoresBusqueda.Split([',']);
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
      if Query.Locate(ClavePrimaria, ValoresBusqueda, []) then
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

initialization
  GlobalDataModules := TObjectDictionary<string,
                                         TDataModule>.Create([doOwnsValues]);
//
//finalization
//  GlobalDataModules.Free;

end.
