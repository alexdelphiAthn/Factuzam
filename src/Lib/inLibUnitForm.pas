{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUnitForm                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro de formularios y atajos del programa.                            }
{    Asocia menú, unit, data module y shortcut con cada formulario disponible. }
{******************************************************************************}
unit inLibUnitForm;

interface

uses
  System.Generics.Defaults, System.Generics.Collections, System.Contnrs,
  Classes, Windows, Forms, vcl.Menus, Controls, Data.DB, Uni,
  System.SysUtils,
  System.StrUtils, inLibUser, Vcl.Buttons, Types;

type

 TfzaForm = class
   private
     FCall:string;
     FCaption:string;
     FUnitForm:string;
     FMenuItem:string;
     FShortCut:string;
     FDataUnit:string;
     FNumVentanas:Integer;
     FmnMenuItem:TMenuItem;
     function GetCall:string;
     procedure SetCall(Value:string);
     function GetCaption:string;
     procedure SetCaption(Value:string);
     function GetUnitForm:string;
     procedure SetUnitForm(Value:string);
     function GetMenuItem:string;
     procedure SetMenuItem(Value:string);
     function GetShortCut:string;
     procedure SetShortCut(Value:string);
     function GetmnMenuItem:TMenuItem;
     procedure SetmnMenuItem(Value:TMenuItem);
     function GetDataUnit: string;
     procedure SetDataUnit(const Value: string);
     function GetNumVentanas: Integer;
     procedure SetNumVentanas(const Value: Integer);
   public
     constructor Create(ACall,
                        ACaption,
                        AMenuItem,
                        AUnitForm,
                        AShortCut,
                        ADataUnit:string;
                        ANumVentanas:Integer;
                        AOwn:TComponent);
     Property Call   : string read GetCall write SetCall;
     Property Caption   : string read GetCaption write SetCaption;
     Property UnitForm   : string read GetUnitForm write SetUnitForm;
     Property MenuItem   : string read GetMenuItem write SetMenuItem;
     Property mnMenuItem   : TMenuItem read GetmnMenuItem write SetmnMenuItem;
     Property ShortCut     : string read GetShortCut write SetShortCut;
     Property DataUnit     : string read GetDataUnit write SetDataUnit;
     Property NumVentanas  : Integer read GetNumVentanas write SetNumVentanas;
   private
 end;

 TfzaWinF = class(TObject)
 private
   FList:TObjectList<TfzaForm>;
   FOwner:TComponent;
 public
   constructor Create(Owner:TComponent);
   destructor Destroy; override;
   procedure Charge(nConn:TUniConnection);
   function GetDataModuleName(sUnitName:string):String;
   function GetElement(sCall:string):TfzaForm;
   function GetShortCutListOrd:TList<integer>;
   function GetShortCutListString:string;
   function Count: Integer;
   function Item(AIndex: Integer): TfzaForm;
   // Codigo de permiso de un item de menu. Si el item esta registrado
   // (mnMenuItem) devuelve 'menu.<CALL>'; si no, 'menu.<Name>' para que
   // tambien sea controlable. '' si el item no tiene Name. Lo usan la
   // pantalla de permisos y AplicarPermisosMenu (misma regla en ambos).
   function CodigoMenu(AItem: TMenuItem): string;
 end;


implementation

uses inMtoPrincipal;

{ TfzaForm }

constructor TfzaForm.Create(ACall,
                            ACaption,
                            AMenuItem,
                            AUnitForm,
                            AShortCut,
                            ADataUnit: string;
                            ANumVentanas: Integer;
                            AOwn:TComponent  );
var
  frmOpen2:TfrmMtoPrincipal;
begin
  FCall := ACall;
  FCaption := ACaption;
  FUnitForm := AUnitForm;
  FMenuItem := AMenuItem;
  FShortCut := AShortCut;
  FDataUnit := ADataUnit;
  if ANumVentanas < 1 then
    FNumVentanas := 1
  else
    FNumVentanas := ANumVentanas;
  frmOpen2 := (AOwn as TfrmMtoPrincipal);
  FmnMenuItem := (frmOpen2.FindComponent(FMenuItem) as TMenuItem);
end;

function TfzaForm.GetCall: string;
begin
  Result := FCall;
end;

function TfzaForm.GetCaption: string;
begin
  Result := FCaption;
end;

function TfzaForm.GetDataUnit: string;
begin
  Result := FDataUnit;
end;

function TfzaForm.GetMenuItem: string;
begin
  Result := FMenuItem;
end;

function TfzaForm.GetNumVentanas: Integer;
begin
  Result := FNumVentanas;
end;

function TfzaForm.GetmnMenuItem: TMenuItem;
begin
  Result := FmnMenuItem;
end;

function TfzaForm.GetShortCut: string;
begin
  Result := FShortCut;
end;

function TfzaForm.GetUnitForm: string;
begin
  Result := FUnitForm;
end;

procedure TfzaForm.SetCall(Value: string);
begin
  FCall := Value;
end;

procedure TfzaForm.SetCaption(Value: string);
begin
  Fcaption := Value;
end;

procedure TfzaForm.SetDataUnit(const Value: string);
begin
  FDataUnit := Value;
end;

procedure TfzaForm.SetMenuItem(Value: string);
begin
  FMenuItem := Value;
end;

procedure TfzaForm.SetNumVentanas(const Value: Integer);
begin
  if Value < 1 then
    FNumVentanas := 1
  else
    FNumVentanas := Value;
end;

procedure TfzaForm.SetmnMenuItem(Value: TMenuItem);
begin
  FmnMenuItem := Value;
end;

procedure TfzaForm.SetShortCut(Value: string);
begin
  FShortCut := Value;
end;

procedure TfzaForm.SetUnitForm(Value: string);
begin
  FUnitForm := Value;
end;

{ TfzaWinF }

procedure TfzaWinF.Charge(nConn: TUniConnection);
var
  qrySol: TUniQuery;
  ozaForm:TfzaForm;
  fldNumVent: TField;
  iNumVent: Integer;
begin
  qrySol := TUniQuery.Create(nil);
  try
    qrySol.Connection := nConn;
    qrySol.SQL.Text := 'SELECT * FROM fza_winforms';
    qrySol.Open;
    while not qrySol.Eof  do
    begin
      With qrySol do
      begin
        fldNumVent := FindField('NUM_VENTANAS_WINF');
        if (fldNumVent <> nil) and (not fldNumVent.IsNull) then
          iNumVent := fldNumVent.AsInteger
        else
          iNumVent := 1;
        ozaForm := TfzaForm.Create(FieldByName('CALL_WINF').AsString,
                                   FieldByName('CAPTION_WINF').AsString,
                                   FieldByName('MENUITEM_WINF').AsString,
                                   FieldByName('UNITF_WINF').AsString,
                                   FieldByName('SHORTCUT_WINF').AsString,
                                   FieldByName('DATAMODULE_WINF').AsString,
                                   iNumVent,
                                   Self.FOwner);
      end;
      FList.Add(ozaForm);
      qrySol.Next;
    end;
    qrySol.Close;
  finally
    FreeAndNil(qrySol);
  end;
end;

function TfzaWinF.Count: Integer;
begin
  Result := FList.Count;
end;

function TfzaWinF.Item(AIndex: Integer): TfzaForm;
begin
  Result := FList[AIndex];
end;

function TfzaWinF.CodigoMenu(AItem: TMenuItem): string;
var
  i: Integer;
  sCall: string;
begin
  sCall := '';
  for i := 0 to FList.Count - 1 do
    if (sCall = '') and (FList[i].mnMenuItem = AItem) then
      sCall := FList[i].Call;
  if sCall <> '' then
    Result := 'menu.' + sCall
  else if AItem.Name <> '' then
    Result := 'menu.' + AItem.Name
  else
    Result := '';
end;

constructor TfzaWinF.Create(Owner:TComponent);
begin
  FList := TObjectList<TfzaForm>.Create;
  FOwner := Owner;
end;

destructor TfzaWinF.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

function TfzaWinF.GetDataModuleName(sUnitName: string): String;
var
  ofzaForm:TfzaForm;
begin
  Result := '';
  for ofzaForm in FList do
  begin
    if ofzaForm.UnitForm.Contains(sUnitName) then
    begin
      Result := ofzaForm.DataUnit;
      Exit;
    end;
  end;
end;

function TfzaWinF.GetElement(sCall: string): TfzaForm;
var
  ofzaForm:TfzaForm;
begin
  Result := nil;
  for ofzaForm in FList do
  begin
    if ofzaForm.Call = sCall then
    begin
      Result := ofzaForm;
      Exit;
    end;
  end;
end;

function TfzaWinF.GetShortCutListOrd: TList<Integer>;
var
  aList: TList<Integer>;
  ofzaForm: TfzaForm;
  sc: TShortCut;
begin
  aList := TList<Integer>.Create;
  for ofzaForm in FList do
  begin
    if Trim(ofzaForm.ShortCut) = '' then Continue;
    try
      // TextToShortCut hace toda la magia.
      // Convierte 'Ctrl+F1' en el entero correcto (ej: 16496)
      // Convierte 'F5' en el entero correcto (ej: 116)
      sc := TextToShortCut(ofzaForm.ShortCut);
      if sc <> 0 then
        aList.Add(sc);
    except
      // Si hay un texto mal formado en la BD,
      //lo ignoramos para no romper el programa
    end;
  end;
  Result := aList;
end;

function TfzaWinF.GetShortCutListString: string;
var
  sList:string;
  ofzaForm:TfzaForm;
begin
  sList := '';
  for ofzaForm in FList do
  begin
    if (Length(ofzaForm.ShortCut) = 1) then
      sList := sList + ofzaForm.ShortCut[1] + ' ';
  end;
  Result := sList;
end;

end.
