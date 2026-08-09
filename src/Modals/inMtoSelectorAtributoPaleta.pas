{ SPDX-License-Identifier: MPL-2.0 }
{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSelectorAtributoPaleta                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selector desplegable común de valores de atributo con paleta de color.   }
{    Hereda de TfrmBase para conservar la fuente, traducción y servicios       }
{    visuales comunes en Caja, traspasos, inventarios y documentos.            }
{******************************************************************************}
unit inMtoSelectorAtributoPaleta;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Uni, inMtoFrmBase, inLibAtributosPaletaIntf;

type
  TfrmSelectorAtributoPaleta = class(TfrmBase)
    lstValores: TListBox;
    procedure FormShowSelector(Sender: TObject);
    procedure FormDeactivateSelector(Sender: TObject);
    procedure FormKeyDownSelector(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lstValoresDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure lstValoresMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lstValoresKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FConexion: TUniConnection;
    FLecturas: ILecturasAtributosPaleta;
    FIdVa: string;
    FValores: TArray<string>;
    FShown: Boolean;
    FInfoArticulo: TDictionary<string, TInfoBasico>;
    procedure CargarPaletaArticulo(const ACodArt, AIdVa: string);
  public
    constructor CreateConOpciones(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const ALecturas: ILecturasAtributosPaleta;
      const AIdVa: string;
      const AValores: array of string;
      const AValorActual: string;
      AScreenLeft, AScreenTop, AWidthHint: Integer;
      const ACodArt: string);
    destructor Destroy; override;
    function Ejecutar(out AValor: string): Boolean;
  end;

implementation

uses
  inLibAtributosPaleta;

{$R *.dfm}

constructor TfrmSelectorAtributoPaleta.CreateConOpciones(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const ALecturas: ILecturasAtributosPaleta;
  const AIdVa: string;
  const AValores: array of string;
  const AValorActual: string;
  AScreenLeft, AScreenTop, AWidthHint: Integer;
  const ACodArt: string);
const
  ANCHO_MIN = 80;
  ALTO_MAX = 360;
  EXTRA_W = 40;
  PADD_LISTA = 4;
  ALTO_FILA_MIN = 22;
var
  Bmp: TBitmap;
  i: Integer;
  IndiceSeleccionado: Integer;
  MaxTextW: Integer;
  W: Integer;
  H: Integer;
  AltoFuente: Integer;
  FormularioPadre: TCustomForm;
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FLecturas := ALecturas;
  FIdVa := AIdVa;
  FShown := False;
  FInfoArticulo := TDictionary<string, TInfoBasico>.Create;

  // El formulario base aporta la tipografía y el resto de condiciones
  // comunes. El listbox no fija una fuente propia: la hereda del formulario.
  lstValores.ParentFont := True;
  // En este selector, Intro confirma el valor en lugar de avanzar el foco.
  jvntrstb1.EnterAsTab := False;

  FormularioPadre := nil;
  if AOwner is TCustomForm then
    FormularioPadre := TCustomForm(AOwner)
  else if Screen.ActiveForm <> nil then
    FormularioPadre := Screen.ActiveForm;
  if FormularioPadre <> nil then
  begin
    PopupParent := FormularioPadre;
    PopupMode := pmExplicit;
  end
  else
    PopupMode := pmAuto;

  CargarPaletaArticulo(ACodArt, AIdVa);
  SetLength(FValores, Length(AValores));
  IndiceSeleccionado := -1;
  for i := 0 to High(AValores) do
  begin
    FValores[i] := AValores[i];
    lstValores.Items.Add(AValores[i]);
    if (IndiceSeleccionado < 0) and
       SameText(AValores[i], AValorActual) then
      IndiceSeleccionado := i;
  end;
  if (IndiceSeleccionado < 0) and (lstValores.Items.Count > 0) then
    IndiceSeleccionado := 0;
  if IndiceSeleccionado >= 0 then
    lstValores.ItemIndex := IndiceSeleccionado;
  ActiveControl := lstValores;

  MaxTextW := 0;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(lstValores.Font);
    AltoFuente := Bmp.Canvas.TextHeight('Ág') + 6;
    if AltoFuente < ALTO_FILA_MIN then
      AltoFuente := ALTO_FILA_MIN;
    lstValores.ItemHeight := AltoFuente;
    for i := 0 to High(AValores) do
    begin
      W := Bmp.Canvas.TextWidth(AValores[i]);
      if W > MaxTextW then
        MaxTextW := W;
    end;
  finally
    Bmp.Free;
  end;

  W := MaxTextW + EXTRA_W;
  if W < AWidthHint then
    W := AWidthHint;
  if W < ANCHO_MIN then
    W := ANCHO_MIN;
  Width := W;

  H := Length(AValores) * lstValores.ItemHeight + PADD_LISTA;
  if H > ALTO_MAX then
    H := ALTO_MAX;
  Height := H;

  if (AScreenLeft >= 0) and (AScreenTop >= 0) then
  begin
    Left := AScreenLeft;
    Top := AScreenTop;
  end
  else
    Position := poScreenCenter;
end;

destructor TfrmSelectorAtributoPaleta.Destroy;
begin
  FreeAndNil(FInfoArticulo);
  inherited;
end;

procedure TfrmSelectorAtributoPaleta.CargarPaletaArticulo(
  const ACodArt, AIdVa: string);
var
  Valor: TValorPaletaArticulo;
  Valores: TArray<TValorPaletaArticulo>;
  sAv: string;
begin
  if (Trim(ACodArt) <> '') and (FLecturas <> nil) then
  begin
    Valores := FLecturas.ListarPaletaArticulo(
      FConexion,
      ACodArt,
      AIdVa);
    for Valor in Valores do
    begin
      sAv := UpperCase(Trim(Valor.Valor));
      if Valor.Info.EsValido and (sAv <> '') then
        FInfoArticulo.AddOrSetValue(sAv, Valor.Info);
    end;
  end;
end;

function TfrmSelectorAtributoPaleta.Ejecutar(out AValor: string): Boolean;
begin
  AValor := '';
  Result := ShowModal = mrOk;
  if Result then
  begin
    Result := (lstValores.ItemIndex >= 0) and
      (lstValores.ItemIndex < Length(FValores));
    if Result then
      AValor := FValores[lstValores.ItemIndex];
  end;
end;

procedure TfrmSelectorAtributoPaleta.FormShowSelector(Sender: TObject);
begin
  FShown := True;
end;

procedure TfrmSelectorAtributoPaleta.FormDeactivateSelector(Sender: TObject);
begin
  if FShown and (ModalResult = mrNone) then
    ModalResult := mrCancel;
end;

procedure TfrmSelectorAtributoPaleta.FormKeyDownSelector(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

procedure TfrmSelectorAtributoPaleta.lstValoresDrawItem(
  Control: TWinControl; Index: Integer; ARect: TRect;
  State: TOwnerDrawState);
const
  LADO = 16;
  MARGEN_IZQ = 8;
  HUECO_TEXTO = 8;
var
  Av: string;
  Info: TInfoBasico;
  Cuadrado: TRect;
  TextRect: TRect;
  Alto: Integer;
  Top: Integer;
  HayColor: Boolean;
begin
  if (Index >= 0) and (Index < lstValores.Items.Count) then
  begin
    Av := lstValores.Items[Index];
    if odSelected in State then
      lstValores.Canvas.Brush.Color := clHighlight
    else
      lstValores.Canvas.Brush.Color := clWindow;
    lstValores.Canvas.FillRect(ARect);
    HayColor := FInfoArticulo.TryGetValue(UpperCase(Trim(Av)), Info);
    if (not HayColor) and (Trim(FIdVa) <> '') then
      HayColor := ObtenerInfoBasico(FConexion, FIdVa, Av, Info);
    if not HayColor then
      HayColor := BuscarInfoBasicoEnArticulo(
        FConexion,
        Av,
        ObtenerMapaAtributosGlobal(FConexion),
        Info);
    if HayColor then
    begin
      Alto := ARect.Bottom - ARect.Top;
      if Alto > LADO then
        Top := ARect.Top + (Alto - LADO) div 2
      else
        Top := ARect.Top;
      Cuadrado := Rect(
        ARect.Left + MARGEN_IZQ,
        Top,
        ARect.Left + MARGEN_IZQ + LADO,
        Top + LADO);
      lstValores.Canvas.Brush.Style := bsSolid;
      lstValores.Canvas.Brush.Color := Info.Color;
      lstValores.Canvas.FillRect(Cuadrado);
      lstValores.Canvas.Brush.Style := bsClear;
      lstValores.Canvas.Pen.Color := clBlack;
      lstValores.Canvas.Pen.Width := 1;
      lstValores.Canvas.Rectangle(Cuadrado);
      lstValores.Canvas.Brush.Style := bsSolid;
      TextRect := Rect(
        Cuadrado.Right + HUECO_TEXTO,
        ARect.Top,
        ARect.Right,
        ARect.Bottom);
    end
    else
      TextRect := Rect(
        ARect.Left + MARGEN_IZQ,
        ARect.Top,
        ARect.Right,
        ARect.Bottom);
    if odSelected in State then
      lstValores.Canvas.Font.Color := clHighlightText
    else
      lstValores.Canvas.Font.Color := clWindowText;
    lstValores.Canvas.Brush.Style := bsClear;
    Winapi.Windows.DrawText(
      lstValores.Canvas.Handle,
      PChar(Av),
      -1,
      TextRect,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    lstValores.Canvas.Brush.Style := bsSolid;
    if odFocused in State then
      lstValores.Canvas.DrawFocusRect(ARect);
  end;
end;

procedure TfrmSelectorAtributoPaleta.lstValoresMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Indice: Integer;
begin
  if Button = mbLeft then
  begin
    Indice := lstValores.ItemAtPos(Point(X, Y), True);
    if Indice >= 0 then
    begin
      lstValores.ItemIndex := Indice;
      ModalResult := mrOk;
    end;
  end;
end;

procedure TfrmSelectorAtributoPaleta.lstValoresKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (lstValores.ItemIndex >= 0) then
  begin
    ModalResult := mrOk;
    Key := 0;
  end;
end;

end.
