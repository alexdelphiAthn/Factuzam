unit inLibMenuBarraIconos;

{
  Painter para TJvMainMenu que, ademas de todo lo que hace el painter
  estandar de JVCL, dibuja el icono de los items de primer nivel (la barra).

  JVCL omite a proposito la imagen en los items raiz
  (TJvCustomMenuItemPainter.Paint: "The image will not be drawn for root
  menu items"). Aqui se aprovecha que DrawItemText es virtual y que, para
  los items raiz, recibe el rectangulo completo del item y centra el texto
  en el; se reserva sitio en Measure, se dibuja el icono a la izquierda y
  se deja que el inherited centre el texto en lo que queda.

  Uso, en el OnCreate del formulario principal, ANTES de asignar Images:

    FPainterMenu := TJvMenuBarIconPainter.Create(Self);
    jvMnMenuPrin.ItemPainter := FPainterMenu;   // pone Style := msItemPainter
    jvMnMenuPrin.TextMargin := 8;               // 35 deja huecos enormes
}

interface

uses
  System.Classes, System.Types, Winapi.Windows, Vcl.Menus, JvMenus;

type
  TJvMenuBarIconPainter = class(TJvStandardMenuItemPainter)
  private
    FItemActual: TMenuItem;
    FEstadoActual: TMenuOwnerDrawState;
    FEspacio: Integer;
    function EsRaiz(AItem: TMenuItem): Boolean;
  protected
    procedure DrawItemText(ARect: TRect; const Text: string;
      Flags: Longint); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Measure(Item: TMenuItem; var Width, Height: Integer); override;
    procedure Paint(Item: TMenuItem; ItemRect: TRect;
      State: TMenuOwnerDrawState); override;
  published
    /// Pixeles entre el icono y el texto en los items de la barra.
    property Espacio: Integer read FEspacio write FEspacio default 6;
  end;

implementation

constructor TJvMenuBarIconPainter.Create(AOwner: TComponent);
begin
  inherited;
  FEspacio := 6;
end;

function TJvMenuBarIconPainter.EsRaiz(AItem: TMenuItem): Boolean;
begin
  Result := (AItem <> nil) and not IsPopup(AItem);
end;

procedure TJvMenuBarIconPainter.Measure(Item: TMenuItem;
  var Width, Height: Integer);
begin
  // inherited llama a PreparePaint, que es quien resuelve FImageIndex,
  // asi que UseImages solo es fiable despues de esta linea.
  inherited;
  if EsRaiz(Item) and UseImages then
  begin
    Inc(Width, ImageWidth + FEspacio);
    if Height < ImageHeight + 4 then
      Height := ImageHeight + 4;
  end;
end;

procedure TJvMenuBarIconPainter.Paint(Item: TMenuItem; ItemRect: TRect;
  State: TMenuOwnerDrawState);
begin
  // FItem y FState del ancestro son privados; se guardan aqui para
  // tenerlos disponibles en DrawItemText.
  FItemActual := Item;
  FEstadoActual := State;
  try
    inherited;
  finally
    FItemActual := nil;
  end;
end;

procedure TJvMenuBarIconPainter.DrawItemText(ARect: TRect;
  const Text: string; Flags: Longint);
var
  Borde, X, Y: Integer;
begin
  if EsRaiz(FItemActual) and UseImages then
  begin
    // Mitad del margen a cada lado, icono pegado al margen izquierdo,
    // texto centrado en lo que queda (que es justo su anchura).
    Borde := TextMargin div 2;
    X := ARect.Left + Borde;
    Y := ARect.Top + ((ARect.Bottom - ARect.Top) - ImageHeight) div 2;

    if mdDisabled in FEstadoActual then
      DrawDisabledImage(X, Y)
    else
      DrawEnabledImage(X, Y);

    ARect.Left := X + ImageWidth + FEspacio;
    Dec(ARect.Right, Borde);
  end;
  inherited DrawItemText(ARect, Text, Flags);
end;

end.
