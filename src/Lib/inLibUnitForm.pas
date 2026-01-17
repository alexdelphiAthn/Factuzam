{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibUnitForm;

interface

uses
  System.Generics.Defaults, System.Generics.Collections, System.Contnrs,
  Classes, Windows, Forms, vcl.Menus, Controls, Uni,   System.SysUtils,
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
   public
     constructor Create(pCall,
                        pCaption,
                        pMenuItem,
                        pUnitForm,
                        pShortCut,
                        pDataUnit:string;
                        pOwn:TComponent);
     Property Call   : string read GetCall write SetCall;
     Property Caption   : string read GetCaption write SetCaption;
     Property UnitForm   : string read GetUnitForm write SetUnitForm;
     Property MenuItem   : string read GetMenuItem write SetMenuItem;
     Property mnMenuItem   : TMenuItem read GetmnMenuItem write SetmnMenuItem;
     Property ShortCut     : string read GetShortCut write SetShortCut;
     Property DataUnit     : string read GetDataUnit write SetDataUnit;
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
 end;


implementation

uses inMtoPrincipal;

{ TfzaForm }

constructor TfzaForm.Create(pCall,
                            pCaption,
                            pMenuItem,
                            pUnitForm,
                            pShortCut,
                            pDataUnit: string;
                            pOwn:TComponent  );
var
  frmOpen2:TfrmMtoPrincipal;
begin
  FCall := pCall;
  FCaption := pCaption;
  FUnitForm := pUnitForm;
  FMenuItem := pMenuITem;
  FShortCut := pShortCut;
  FDataUnit := pDataUnit;
  frmOpen2 := (pOwn as TfrmMtoPrincipal);
  FmnMenuItem := (frmOpen2.FindComponent(FMenuITem) as TMenuItem);
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
        ozaForm := TfzaForm.Create(FieldByName('CALL_WINF').AsString,
                                   FieldByName('CAPTION_WINF').AsString,
                                   FieldByName('MENUITEM_WINF').AsString,
                                   FieldByName('UNITF_WINF').AsString,
                                   FieldByName('SHORTCUT_WINF').AsString,
                                   FieldByName('DATAMODULE_WINF').AsString,
                                   Self.FOwner);
      end;
      FList.Add(ozaForm);
      qrySol.Next;
    end;
    qrySol.Close;
  finally
    qrySol.Free;
  end;
end;

constructor TfzaWinF.Create(Owner:TComponent);
begin
  FList := TObjectList<TfzaForm>.Create;
  FOwner := Owner;
end;

destructor TfzaWinF.Destroy;
begin
  //
  FList.Free;
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
