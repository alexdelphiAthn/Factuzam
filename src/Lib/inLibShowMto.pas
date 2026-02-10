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
  system.math, System.IOUtils, inLibWin, cxPC, Types, Vcl.Consts,
  inLibFormManager;

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

procedure ShowMto(Owner: TComponent; sCall: String; sBusq: string = '');
var
  frmMain: TfrmMtoPrincipal;
  ofzaF: TfzaForm;
  TargetForm: TForm;
  ctx: TRttiContext;
  lType: TRttiType;
  FormClass: TFormBaseClass;
  frmGen: TfrmMtoGen;
  dmDat: TdmBase;
  sPkTab: String;
begin
  if not (Owner is TfrmMtoPrincipal) then Exit;
  frmMain := TfrmMtoPrincipal(Owner);
  if frmMain.FormManager = nil then
    frmMain.FormManager := TEmbeddedFormManager.Create(frmMain.pcPrincipal);
  ofzaF := frmMain.oFzaWinf.GetElement(sCall);
  if ofzaF = nil then
  begin
    ShowMessageFmt(SResWinFNotFnd, [sCall]);
    Exit;
  end;
  if (ofzaF.mnMenuItem <> nil) and (not ofzaF.mnMenuItem.Visible) then
  begin
    inLibLog.Log.LogWarning('Intento de acceso a menú oculto: ' + sCall);
    Exit;
  end;
  TargetForm := frmMain.FormManager.FindFormByCaption(ofzaF.Caption);
  if TargetForm = nil then
  begin
    ctx := TRttiContext.Create;
    try
      lType := ctx.FindType(ofzaF.UnitForm);
      if (lType <> nil) and (lType.IsInstance) then
      begin
        FormClass := TFormBaseClass(GetTypeData(lType.Handle)^.ClassType);
        TargetForm := FormClass.Create(frmMain);
        frmMain.FormManager.EmbedForm(TargetForm, ofzaF.Caption, True);
        inLibLog.Log.LogInfo('Pantalla abierta: ' + ofzaF.Caption);
      end
      else
      begin
        ShowMessageFmt(SClassRttiNotFnd, [ofzaF.UnitForm]);
        Exit;
      end;
    finally
      ctx.Free;
    end;
  end
  else
  begin
    if (TargetForm.Parent is TcxTabSheet) then
      (TargetForm.Parent as TcxTabSheet).PageControl.ActivePage :=
                                             (TargetForm.Parent as TcxTabSheet);
  end;
  if (sBusq <> '') and (TargetForm is TfrmMtoGen) then
  begin
    frmGen := TfrmMtoGen(TargetForm);
    if (frmGen.tdmDataModule <> nil) and (frmGen.tdmDataModule is TdmBase) then
    begin
      dmDat := TdmBase(frmGen.tdmDataModule);
      sPkTab := frmGen.pkFieldName;
      if not BuscarTabla(dmDat.unqryTablaG, sPkTab, sBusq) then
      begin
        ShowMessageFmt(SLocateNotFnd, [sBusq, ofzaF.Caption]);
      end
      else
      begin
        if (frmGen.tsFicha <> nil) and (frmGen.tsFicha.TabVisible) then
          frmGen.pcPantalla.ActivePage := frmGen.tsFicha;
        if frmGen.CanFocus then
          frmGen.SetFocus;
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
  Instance: TObject;
  NewDM: TDataModule;
begin
  Result := nil;
  if (pOwner.tdmDataModule <> nil) then
  begin
    Result := pOwner.tdmDataModule;
    Exit;
  end;
  ctx := TRttiContext.Create;
  try
    lType := ctx.FindType(sDataUnit);
    if (lType <> nil) and (lType is TRttiInstanceType) then
    begin
      DataModuleClass := TRttiInstanceType(lType).MetaclassType;
      if DataModuleClass.InheritsFrom(TDataModule) then
      begin
        Instance := DataModuleClass.NewInstance;
        NewDM := TDataModule(Instance);
        try
          NewDM.Create(pOwner);
          if NewDM is TdmBase then
          begin
             TdmBase(NewDM).FCurrentForm := pOwner;
             // 1. Aseguramos conexión
             if Assigned(pOwner.dsTablaG) then
               pOwner.dsTablaG.DataSet := TdmBase(NewDM).unqryTablaG;
              if (GetPerfilValueDef(pOwner.oPerfilDic,
                                    'oGetSQLFromDB',
                                    'False') = 'True') then
              begin
                GetFormUserProfile(TdmBase(NewDM).FoPerfilDic,
                                   TdmBase(NewDM).Name);
                LoadSQLFromProfile(TdmBase(NewDM), TdmBase(NewDM).FoPerfilDic);
              end;

             // 2. AHORA SÍ es seguro abrir.
             // El objeto está creado y asignado.
             try
               if not TdmBase(NewDM).unqryTablaG.Active then
                  TdmBase(NewDM).unqryTablaG.Open;
             except
               on E: Exception do
                 inLibLog.Log.LogError('Error al abrir tabla en ' + sDataUnit + ': ' + E.Message);
             end;
          end;
//          if NewDM is TdmBase then
//             TdmBase(NewDM).FCurrentForm := pOwner;
          pOwner.tdmDataModule := NewDM;
          Result := NewDM;
        except
          NewDM.Free;
          raise;
        end;
      end;
    end;
  finally
    ctx.Free;
  end;
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

end.
