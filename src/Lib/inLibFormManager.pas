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
  winapi.Windows, winapi.Messages, System.SysUtils,
  inLibVentanaEmbebidaIntf;

type
  TEmbeddedFormManager = class(TComponent)
  private
    FPageControl: TcxPageControl;
    FForms: TList<TForm>;
    // Identidad estable de cada ventana (CALL[#instancia]); el caption
    // queda solo como texto visible de la pestania.
    FClaves: TDictionary<string, TForm>;
    FContratos: TDictionary<TForm, IMantenimientoEmbebido>;
    procedure InternalCloseForm(AForm: TForm;
                                AForzar: Boolean = False;
                                ALiberarAhora: Boolean = False);
    procedure QuitarClave(AForm: TForm);
  protected
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
  public

    constructor Create(APageControl: TcxPageControl); reintroduce;
    destructor Destroy; override;
    procedure EmbedForm(AForm: TForm;
                         const AMantenimiento: IMantenimientoEmbebido;
                         const ATitle: string;
                         const AClave: string = '';
                         ASelect: Boolean = True);
    function FindFormByCaption(const ATitle: string): TForm;
    // Ventana registrada con esa clave; nil si no hay ninguna.
    function FormPorClave(const AClave: string): TForm;
    // Formulario embebido en la pestania activa; nil si no hay ninguno.
    function FormActivo: TForm;
    // Clave con la que se registro un formulario; '' si no esta.
    function ClaveDeForm(AForm: TForm): string;
    function MantenimientoDeForm(
      AForm: TForm): IMantenimientoEmbebido;
    function GetEnumerator: TList<TForm>.TEnumerator;
    procedure CloseFormByCaption(const ATitle:string);
    procedure CloseActiveForm;
    procedure CloseAll;
  end;

implementation

{ TEmbeddedFormManager }

constructor TEmbeddedFormManager.Create(APageControl: TcxPageControl);
begin
  inherited Create(APageControl);   // Owner = PageControl para autoliberación
  FPageControl := APageControl;
  FForms := TList<TForm>.Create;
  FClaves := TDictionary<string, TForm>.Create;
  FContratos := TDictionary<TForm, IMantenimientoEmbebido>.Create;
end;

procedure TEmbeddedFormManager.Notification(AComponent: TComponent;
                                            Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TForm) then
  begin
    FForms.Remove(TForm(AComponent));
    QuitarClave(TForm(AComponent));
    FContratos.Remove(TForm(AComponent));
  end;
end;

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm;
                                         const AMantenimiento:
                                           IMantenimientoEmbebido;
                                         const ATitle: string;
                                         const AClave: string = '';
                                         ASelect: Boolean = True);
var
  NewTab: TcxTabSheet;
begin
  if AClave <> '' then
    FClaves.AddOrSetValue(AClave, AForm);
  FContratos.AddOrSetValue(AForm, AMantenimiento);
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
  FreeAndNil(FContratos);
  FreeAndNil(FForms);
  FreeAndNil(FClaves);
  inherited;
end;

procedure TEmbeddedFormManager.CloseAll;
var
  F: TForm;
begin
  while FForms.Count > 0 do
  begin
    F := FForms[FForms.Count - 1];
    // Durante el apagado los servicios deben sobrevivir a los formularios.
    InternalCloseForm(F, True, True);
  end;
end;

function TEmbeddedFormManager.FindFormByCaption(const ATitle: string): TForm;
var
  F: TForm;
begin
  Result := nil;
  for F in FForms do
  begin
    if (Result = nil) and (F.Parent is TcxTabSheet) and
       (Trim(TcxTabSheet(F.Parent).Caption) = Trim(ATitle)) then
      Result := F;
  end;
end;

function TEmbeddedFormManager.FormPorClave(const AClave: string): TForm;
begin
  if not FClaves.TryGetValue(AClave, Result) then
    Result := nil;
end;

function TEmbeddedFormManager.FormActivo: TForm;
var
  ts: TcxTabSheet;
begin
  Result := nil;
  if (FPageControl <> nil) and (FPageControl.ActivePage <> nil) then
  begin
    ts := FPageControl.ActivePage;
    if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      Result := TForm(ts.Controls[0]);
  end;
end;

function TEmbeddedFormManager.ClaveDeForm(AForm: TForm): string;
var
  sClave: string;
begin
  Result := '';
  for sClave in FClaves.Keys do
  begin
    if FClaves[sClave] = AForm then
    begin
      Result := sClave;
      Break;
    end;
  end;
end;

function TEmbeddedFormManager.MantenimientoDeForm(
  AForm: TForm): IMantenimientoEmbebido;
begin
  if not FContratos.TryGetValue(AForm, Result) then
    Result := nil;
end;

procedure TEmbeddedFormManager.QuitarClave(AForm: TForm);
var
  sClave: string;
begin
  for sClave in FClaves.Keys do
  begin
    if FClaves[sClave] = AForm then
    begin
      FClaves.Remove(sClave);
      Break;
    end;
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
  if ActiveSheet <> nil then
  begin
    // Se busca el formulario alojado en la pestaña activa.
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
end;

procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm;
                                                AForzar: Boolean;
                                                ALiberarAhora: Boolean);
var
  ParentTab: TWinControl;
  oMantenimiento: IMantenimientoEmbebido;
  bInterceptar: Boolean;
begin
  if (AForm <> nil) and (PPointer(AForm)^ <> nil) then
  begin
    try
      if csDestroying in AForm.ComponentState then
        FForms.Remove(AForm)
      else
      begin
        bInterceptar := False;
        if (not AForzar) and
           FContratos.TryGetValue(AForm, oMantenimiento) then
          bInterceptar := oMantenimiento.InterceptarCierre;
        if not bInterceptar then
        begin
          SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(False), 0);
          SendMessage(AForm.Handle, WM_SETREDRAW, WPARAM(False), 0);
          AForm.Hide;
          ParentTab := AForm.Parent;
          FForms.Remove(AForm);
          QuitarClave(AForm);
          FContratos.Remove(AForm);
          AForm.Parent := nil;
          if ALiberarAhora then
            FreeAndNil(AForm)
          else
            AForm.Release;
          if (ParentTab <> nil) and (ParentTab is TcxTabSheet) and
             not (csDestroying in ParentTab.ComponentState) then
            FreeAndNil(ParentTab);
        end;
      end;
    finally
      SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(True), 0);
      RedrawWindow(FPageControl.Handle, nil, 0,
        RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
    end;
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
