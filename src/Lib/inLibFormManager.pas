{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormManager                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestor de formularios embebidos en un cxPageControl.                      }
{    Crea, selecciona y cierra ventanas hijas dentro del marco principal.      }
{******************************************************************************}
unit inLibFormManager;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.Controls, cxPC, System.Classes,
  winapi.Windows, winapi.Messages, System.SysUtils;

type
  TEmbeddedFormManager = class(TComponent)
  private
    FPageControl: TcxPageControl;
    FForms: TList<TForm>;
    procedure InternalCloseForm(AForm: TForm;
                                AForzar: Boolean = False);
  protected
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
  public

    constructor Create(APageControl: TcxPageControl); reintroduce;
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
  inherited Create(APageControl);   // Owner = PageControl para autoliberación
  FPageControl := APageControl;
  FForms := TList<TForm>.Create;
end;

procedure TEmbeddedFormManager.Notification(AComponent: TComponent;
                                            Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TForm) then
    FForms.Remove(TForm(AComponent));
end;

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm;
                                         const ATitle: string;
                                         ASelect: Boolean = True);
var
  NewTab: TcxTabSheet;
begin
  SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(False), 0);
  try
    AForm.BorderStyle := bsNone;
    NewTab := TcxTabSheet.Create(FPageControl);
    NewTab.PageControl := FPageControl;
    NewTab.Caption := ATitle + ' ';
    AForm.Parent := NewTab;
    AForm.SetBounds(0, 0, NewTab.ClientWidth, NewTab.ClientHeight);
    AForm.Align := alClient;
    FForms.Add(AForm);
    AForm.FreeNotification(Self);    // <-- CLAVE: nos avisarán si lo liberan
    if ASelect then
      FPageControl.ActivePage := NewTab;
  finally
    SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(True), 0);
    RedrawWindow(FPageControl.Handle, nil, 0,
                 RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
    AForm.Visible := True;
    AForm.Show;
  end;
end;

destructor TEmbeddedFormManager.Destroy;
begin
  FreeAndNil(FForms);
  inherited;
end;

procedure TEmbeddedFormManager.CloseAll;
var
  F: TForm;
begin
  while FForms.Count > 0 do
  begin
    F := FForms[FForms.Count - 1];
    InternalCloseForm(F, True);
  end;
end;

function TEmbeddedFormManager.FindFormByCaption(const ATitle: string): TForm;
var
  F: TForm;
begin
  Result := nil;
  for F in FForms do
  begin
    if (F.Parent is TcxTabSheet) and
       (Trim(TcxTabSheet(F.Parent).Caption) = Trim(ATitle)) then
      Exit(F);
  end;
end;

// Esto habilita la sintaxis "for .. in"
function TEmbeddedFormManager.GetEnumerator: TList<TForm>.TEnumerator;
begin
  Result := FForms.GetEnumerator;
end;

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

procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm;
                                                AForzar: Boolean);
var
  ParentTab: TWinControl;
begin
  if (AForm = nil) or (PPointer(AForm)^ = nil) then
    Exit;
  try
    if csDestroying in AForm.ComponentState then
    begin
      FForms.Remove(AForm);
      Exit;
    end;
    if (not AForzar) and (AForm is TfrmMtoGen) then
      with (AForm as TfrmMtoGen) do
      begin
        if pcPantalla.ActivePage = tsFicha then
        begin
          pcPantalla.ActivePage := tsLista;
          Exit;
        end;
      end;
    // Congela todo antes de tocar nada
    SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(False), 0);
    SendMessage(AForm.Handle, WM_SETREDRAW, WPARAM(False), 0);
    AForm.Hide;
    ParentTab := AForm.Parent;
    FForms.Remove(AForm);
    AForm.Parent := nil;
    // Release, no Free: difiere la destruccion a la cola de mensajes.
    // Un Free inline aqui (handler de WM_FREECONTROL / cierre con tareas
    // async vivas) podia liberar el form con mensajes aun pendientes.
    AForm.Release;
    if (ParentTab <> nil) and
       (ParentTab is TcxTabSheet) and
       not (csDestroying in ParentTab.ComponentState) then
      FreeAndNil(ParentTab);
  finally
    // Restaura y repinta de golpe
    SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(True), 0);
    RedrawWindow(FPageControl.Handle, nil, 0,
                 RDW_ERASE or RDW_FRAME or
                 RDW_INVALIDATE or RDW_ALLCHILDREN);
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
