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
    procedure CloseFormByCaption(const ATitle:string);
    procedure CloseActiveForm;
    procedure CloseAll;
  end;

implementation

uses inMtoGen;

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
//  while FForms.Count > 0 do
//  begin
//    InternalCloseForm(FForms.Last);
//  end;
  FForms.Clear;
end;

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm;
                                         const ATitle: string;
                                         ASelect: Boolean);
var
  NewTab: TcxTabSheet;
begin
  AForm.BorderStyle := bsNone;
  NewTab := TcxTabSheet.Create(FPageControl);
  NewTab.PageControl := FPageControl;
//  NewTab := TcxTabSheet.Create(FPageControl.Owner);
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

(*procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm);
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
end; *)

procedure TEmbeddedFormManager.CloseActiveForm;
var
  ActiveSheet: TcxTabSheet;
  I: Integer;
  F: TForm;
begin
  ActiveSheet := FPageControl.ActivePage;
  if ActiveSheet = nil then Exit;

  // Buscamos qué formulario tiene como Parent a esta ActiveSheet
  for I := FForms.Count - 1 downto 0 do
  begin
    F := FForms[I];
    if F.Parent = ActiveSheet then
    begin
      InternalCloseForm(F);
      Break;
    end;
  end;
end;

procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm);
var
  ParentTab: TWinControl;
begin
  // Verificación triple de seguridad
  if (AForm = nil) or (PPointer(AForm)^ = nil) then
    Exit;

  try
    // Si el formulario ya se está destruyendo por el Owner (Delphi),
    // solo lo quitamos de nuestra lista y salimos.
    if (csDestroying in AForm.ComponentState) then
    begin
      FForms.Remove(AForm);
      Exit;
    end;
    with (Aform as TfrmMtoGen) do
    if pcPantalla.ActivePage = tsFicha then
    begin
      pcPantalla.ActivePage := tsLista;
      Exit;
    end;
    ParentTab := AForm.Parent;

    // Quitamos de la lista PRIMERO
    FForms.Remove(AForm);

    // Solo ponemos a nil si el Form está "sano"
    AForm.Parent := nil;
    AForm.Free;

    // Liberamos la pestaña si procede
    if (ParentTab <> nil) and (ParentTab is TcxTabSheet) then
    begin
      if not (csDestroying in ParentTab.ComponentState) then
        ParentTab.Free;
    end;
  except
    // Si falla, al menos lo sacamos de la lista para que el bucle no se bloquee
    FForms.Remove(AForm);
  end;
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
