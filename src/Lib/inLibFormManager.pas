unit inLibFormManager;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.Controls, cxPC, System.Classes;

type
  TEmbeddedFormManager = class
  private
    FPageControl: TcxPageControl;
    FForms: TList<TForm>;
    procedure InternalCloseForm(AForm:TForm);
  public
    constructor Create(APageControl: TcxPageControl);
    destructor Destroy; override;
    procedure EmbedForm(AForm: TForm;
                        const ATitle: string;
                        ASelect: Boolean = True);
    function FindFormByCaption(const ATitle: string): TForm;
    function GetEnumerator: TList<TForm>.TEnumerator;
    procedure CloseFormByCaption(const ATitle: string);
    procedure CloseAll;
  end;

implementation

{ TEmbeddedFormManager }

constructor TEmbeddedFormManager.Create(APageControl: TcxPageControl);
begin
  inherited Create;
  FPageControl := APageControl;
  FForms := TList<TForm>.Create;
end;

destructor TEmbeddedFormManager.Destroy;
begin
  FForms.Free;
  inherited;
end;

procedure TEmbeddedFormManager.CloseAll;
begin
  // Iteramos al revés porque vamos a eliminar elementos de la lista
  while FForms.Count > 0 do
  begin
    InternalCloseForm(FForms.Last);
  end;
end;

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm;
                                         const ATitle: string;
                                         ASelect: Boolean);
var
  NewTab: TcxTabSheet;
begin
  AForm.BorderStyle := bsNone;
  NewTab := TcxTabSheet.Create(FPageControl.Owner);
  NewTab.PageControl := FPageControl;
  NewTab.Caption := ATitle;
  AForm.Parent := NewTab;
  AForm.SetBounds(0, 0, NewTab.ClientWidth, NewTab.ClientHeight);
  AForm.Align := alClient;
  AForm.Visible := True;
  AForm.Show;
  FForms.Add(AForm);
  if ASelect then
    FPageControl.ActivePage := NewTab;
end;

function TEmbeddedFormManager.FindFormByCaption(const ATitle: string): TForm;
var
  F: TForm;
begin
  Result := nil;
  for F in FForms do
  begin
    if (F.Parent is TcxTabSheet) and
       (TcxTabSheet(F.Parent).Caption = ATitle) then
      Exit(F);
  end;
end;

// Esto habilita la sintaxis "for .. in"
function TEmbeddedFormManager.GetEnumerator: TList<TForm>.TEnumerator;
begin
  Result := FForms.GetEnumerator;
end;

procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm);
var
  ParentTab: TcxTabSheet;
begin
  if AForm = nil then
    Exit;
  ParentTab := nil;
  if AForm.Parent is TcxTabSheet then
    ParentTab := TcxTabSheet(AForm.Parent);
  FForms.Remove(AForm);
  AForm.Free;
  if ParentTab <> nil then
    ParentTab.Free;
end;

procedure TEmbeddedFormManager.CloseFormByCaption(const ATitle: string);
var
  LForm: TForm;
begin
  LForm := FindFormByCaption(ATitle);
  if LForm <> nil then
    InternalCloseForm(LForm);
end;

end.
