unit inLibFormManager;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.Controls, cxPC, System.Classes;

type
  TEmbeddedFormManager = class
  private
    FPageControl: TcxPageControl;
    // Lista interna para gestionar las instancias y permitir el bucle for..in
    FForms: TList<TForm>;
  public
    constructor Create(APageControl: TcxPageControl);
    destructor Destroy; override;

    // Método para incrustar un formulario
    procedure EmbedForm(AForm: TForm;
                        const ATitle: string;
                        ASelect: Boolean = True);

    // Método para buscar si ya existe
    function FindFormByCaption(const ATitle: string): TForm;

    // Soporte para "for Form in Manager do"
    function GetEnumerator: TList<TForm>.TEnumerator;
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

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm; const ATitle: string; ASelect: Boolean);
var
  NewTab: TcxTabSheet;
begin
  // 1. Preparar el formulario (Quitar bordes antes de nada)
  AForm.BorderStyle := bsNone;

  // 2. Crear la pestaña
  NewTab := TcxTabSheet.Create(FPageControl.Owner);
  NewTab.PageControl := FPageControl;
  NewTab.Caption := ATitle;

  // 3. EL PASO CRÍTICO: Asignar el Parent ANTES del Align
  AForm.Parent := NewTab;

  // 4. Forzar posición inicial (Truco para asegurar que el VCL refresque)
  AForm.SetBounds(0, 0, NewTab.ClientWidth, NewTab.ClientHeight);

  // 5. Ahora sí, activar el Align
  AForm.Align := alClient;

  // 6. Asegurar visibilidad
  AForm.Visible := True;
  AForm.Show;

  // Registrar en la lista
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
    // Asumimos que el caption del tab coincide o el del form
    if (F.Parent is TcxTabSheet) and (TcxTabSheet(F.Parent).Caption = ATitle) then
      Exit(F);
  end;
end;

// Esto habilita la sintaxis "for .. in"
function TEmbeddedFormManager.GetEnumerator: TList<TForm>.TEnumerator;
begin
  Result := FForms.GetEnumerator;
end;

end.
