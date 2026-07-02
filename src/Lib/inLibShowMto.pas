{******************************************************************************}
{                                                                              }
{  Módulo:       inLibShowMto                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Apertura genérica de formularios de mantenimiento.                        }
{    Resuelve el formulario por nombre y crea su data module asociado.         }
{******************************************************************************}
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
  function BuscarTabla(AQuery: TUniQuery;
                       const AClavePrimaria,
                       AValoresBusqueda: string):Boolean;
  procedure ShowMto(AOwner: TComponent;
                    ACall:String;
                    ABusq:string = '');
  function ResolverCallFactura(const ANumero, ASerie: string): string;
  function CrearDataModule(ADataUnit:String;var AOwnerForm:TfrmMtoGen):TObject;

implementation

 uses
      inLibMsg,
      inMtoPrincipal,
      inLibLog,
      inLibUnitForm;

procedure ShowMto(AOwner: TComponent;
                  ACall: String;
                  ABusq:string = '');
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
  iNum : Integer;
  iForm: Integer;
  NewCaption: string;
  bEncontrado: Boolean;
  bBusquedaTemporal: Boolean;
begin
  if not (AOwner is TfrmMtoPrincipal) then Exit;
  frmMain := TfrmMtoPrincipal(AOwner);
  if frmMain.WindowState = wsMinimized then
    frmMain.WindowState := wsMaximized;
  for iForm := 0 to Screen.FormCount - 1 do
  begin
    if (Screen.Forms[iForm].ClassName = 'TfrmMtoMenuCaja') and
       (Screen.Forms[iForm].WindowState <> wsMinimized) then
      Screen.Forms[iForm].WindowState := wsMinimized;
  end;
  if frmMain.FormManager = nil then
    frmMain.FormManager := TEmbeddedFormManager.Create(frmMain.pcPrincipal);
  ofzaF := frmMain.oFzaWinf.GetElement(ACall);
  if ofzaF = nil then
  begin
    ShowMessageFmt(SResWinFNotFnd, [ACall]);
    Exit;
  end;
  if (ofzaF.mnMenuItem <> nil) and (not ofzaF.mnMenuItem.Visible) then
  begin
    inLibLog.Log.LogWarning('Intento de acceso a menú oculto: ' + ACall);
    Exit;
  end;
  NewCaption := ofzaF.Caption;
  if ofzaF.NumVentanas > 1 then
  begin
    if ABusq <> '' then
    begin
      // Ctrl+A: la instancia 1 es la de búsquedas (filtro Todos).
      // Si no existe la creamos; si existe la reutilizamos.
      NewCaption := ofzaF.Caption + ' 1';
      TargetForm := frmMain.FormManager.FindFormByCaption(NewCaption);
    end
    else
    begin
      // Apertura normal del usuario: empieza en la 2 para dejar la 1
      // reservada como instancia de búsqueda.
      iNum := 2;
      NewCaption := ofzaF.Caption + ' ' + IntToStr(iNum);
      while (iNum <= ofzaF.NumVentanas) and
            (frmMain.FormManager.FindFormByCaption(NewCaption) <> nil) do
      begin
        Inc(iNum);
        NewCaption := ofzaF.Caption + ' ' + IntToStr(iNum);
      end;
      if iNum > ofzaF.NumVentanas then
        TargetForm := frmMain.FormManager.FindFormByCaption(
                                                  ofzaF.Caption + ' 2')
      else
        TargetForm := nil;
    end;
  end
  else
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
        TargetForm.Hide;
        bBusquedaTemporal := False;
        // Si es la instancia 1 (reservada para busquedas), marcar el flag
        // y recortar el layout antes de embeber: sin Lista, sin Busqueda,
        // sin Precarga, sin Exportar a Excel; navegador con solo Insert/
        // Delete/Edit/Post/Cancel. Asi el Show muestra ya la UI reducida.
        if (TargetForm is TfrmMtoGen) and (ABusq <> '') then
        begin
          TfrmMtoGen(TargetForm).EsInstanciaBusqueda := True;
          if (ofzaF.NumVentanas > 1) and
             (NewCaption = ofzaF.Caption + ' 1') then
            TfrmMtoGen(TargetForm).AplicarLayoutInstanciaBusqueda
          else
            bBusquedaTemporal := True;
        end;
        try
          frmMain.FormManager.EmbedForm(TargetForm, NewCaption, True);
        finally
          if bBusquedaTemporal and (TargetForm is TfrmMtoGen) then
            TfrmMtoGen(TargetForm).EsInstanciaBusqueda := False;
        end;
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
  // Carga inicial de la lista principal:
  // - Sin parametro de busqueda: async, asi el tab aparece de inmediato y
  //   se rellena en background mientras la UI sigue respondiendo. El
  //   resto de tabs siguen totalmente interactivos durante el fetch.
  // - Con parametro de busqueda: sincrono, porque BuscarTabla.Locate
  //   (mas abajo) necesita la query activa al volver.
  if TargetForm is TfrmMtoGen then
  begin
    // Busqueda externa: filtrar a la clave recibida antes del Open.
    // Evita precargas completas y filtros de usuario/pantalla que oculten
    // la factura localizada desde otra pantalla.
    if ABusq <> '' then
      TfrmMtoGen(TargetForm).PrepararBusquedaExterna(ABusq);
    if ABusq <> '' then
      TfrmMtoGen(TargetForm).AbrirTablaPrincipalSincrono
    else
      TfrmMtoGen(TargetForm).AbrirTablaPrincipalAsync;
  end;
  if (ABusq <> '') and (TargetForm is TfrmMtoGen) then
  begin
    frmGen := TfrmMtoGen(TargetForm);
    if (frmGen.tdmDataModule <> nil) and (frmGen.tdmDataModule is TdmBase) then
    begin
      dmDat := TdmBase(frmGen.tdmDataModule);
      sPkTab := frmGen.pkFieldName;
      bEncontrado := BuscarTabla(dmDat.unqryTablaG, sPkTab, ABusq);
      if not bEncontrado then
        ShowMessageFmt(SLocateNotFnd, [ABusq, ofzaF.Caption]);
      if bEncontrado then
      begin
        if (frmGen.tsFicha <> nil) and (frmGen.tsFicha.TabVisible) then
          frmGen.pcPantalla.ActivePage := frmGen.tsFicha;
        if frmGen.CanFocus then
          frmGen.SetFocus;
      end;
    end;
  end;
end;

function CrearDataModule(ADataUnit: String; var AOwnerForm: TfrmMtoGen): TObject;
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
  if (AOwnerForm.tdmDataModule <> nil) then
  begin
    Result := AOwnerForm.tdmDataModule;
    Exit;
  end;
  ctx := TRttiContext.Create;
  try
    lType := ctx.FindType(ADataUnit);
    if (lType <> nil) and (lType is TRttiInstanceType) then
    begin
      DataModuleClass := TRttiInstanceType(lType).MetaclassType;
      if DataModuleClass.InheritsFrom(TDataModule) then
      begin
        Instance := DataModuleClass.NewInstance;
        NewDM := TDataModule(Instance);
        try
          NewDM.Create(AOwnerForm);
          if NewDM is TdmBase then
          begin
             TdmBase(NewDM).FCurrentForm := AOwnerForm;
             // Asignamos el DataSet al DataSource del form. La query aun
             // esta cerrada — el Open lo dispara ShowMto despues, sincrono
             // o async segun haya parametro de busqueda. Mientras tanto el
             // grid mostrara "<No hay datos a mostrar>" un instante.
             if Assigned(AOwnerForm.dsTablaG) then
               AOwnerForm.dsTablaG.DataSet := TdmBase(NewDM).unqryTablaG;
              if (GetPerfilValueDef(AOwnerForm.oPerfilDic,
                                    'oGetSQLFromDB',
                                    'False') = 'True') then
              begin
                GetFormUserProfile(TdmBase(NewDM).FoPerfilDic,
                                   TdmBase(NewDM).Name);
                LoadSQLFromProfile(TdmBase(NewDM), TdmBase(NewDM).FoPerfilDic);
              end;
          end;
//          if NewDM is TdmBase then
//             TdmBase(NewDM).FCurrentForm := AOwnerForm;
          AOwnerForm.tdmDataModule := NewDM;
          Result := NewDM;
        except
          FreeAndNil(NewDM);
          raise;
        end;
      end;
    end;
  finally
    ctx.Free;
  end;
end;

function ResolverCallFactura(const ANumero, ASerie: string): string;
var
  qry: TUniQuery;
  sTipo: string;
begin
  Result := 'Facturas';
  if (oConn = nil) or (not oConn.Connected) then
    Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT TIPO_FAC FROM fza_facturas' +
      ' WHERE NUMERO_FAC = :NUM AND SERIE_FAC = :SER';
    qry.ParamByName('NUM').AsString := ANumero;
    qry.ParamByName('SER').AsString := ASerie;
    qry.Open;
    if not qry.IsEmpty then
    begin
      sTipo := qry.FieldByName('TIPO_FAC').AsString;
      if SameText(sTipo, 'SIMPLIFICADA') then
        Result := 'FacturasSimplif';
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function BuscarTabla(AQuery: TUniQuery;
                     const AClavePrimaria,
                     AValoresBusqueda: string):Boolean;
var
  ValArr: TArray<string>;
  bIsOnlyOne:boolean;
  I:integer;
  miArray: array of Variant;
begin
  bIsOnlyOne := false;
  Result := False;
  ValArr := AValoresBusqueda.Split([',']);
  if Length(ValArr) = 1 then
    bIsOnlyOne := True
  else
  begin
    SetLength(miarray, Length(ValArr));
    for i := 0 to Length(ValArr) - 1 do
      miarray[i] := Trim(ValArr[i]);
  end;
  if AQuery.Active then
  begin
    if bIsonlyOne then
    begin
      if AQuery.Locate(AClavePrimaria, AValoresBusqueda, []) then
        Result := True;
    end
    else
    begin
      if AQuery.Locate(AClavePrimaria, miArray, []) then
      begin
        Finalize(ValArr);
        Finalize(miArray);
        Result := True;
      end;
    end;
  end;
end;

end.
