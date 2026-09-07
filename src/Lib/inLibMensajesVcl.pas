{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMensajesVcl                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cuadros de mensaje propios de la aplicación: ShowMessage_fza,             }
{    ShowMessageFmt_fza, MessageDlg_fza y MessageBox_fza. Construyen el        }
{    diálogo clásico de la VCL (CreateMessageDialog) con la fuente             }
{    corporativa DejaVu Sans en lugar del TaskDialog del sistema, y            }
{    conservan los parámetros y resultados de las funciones originales:        }
{    mrXxx en MessageDlg_fza e IDXXX con indicadores MB_* en MessageBox_fza.   }
{******************************************************************************}
unit inLibMensajesVcl;

interface

uses
  Winapi.Windows, System.UITypes;

const
  NOMBRE_FUENTE_MENSAJES = 'DejaVu Sans';
  TAMANO_FUENTE_MENSAJES = 9;
  // Tipo de MessageBox que Winapi.Windows no declara.
  MB_CANCELTRYCONTINUE = $00000006;

// Sustituto de ShowMessage: sin icono y con el título de la aplicación.
procedure ShowMessage_fza(const AMensaje: string);
procedure ShowMessageFmt_fza(const AFormato: string;
  const AArgumentos: array of const);
// Sustitutos de MessageDlg: mismos parámetros y resultados (mrYes, mrNo...).
function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint): Integer; overload;
function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint;
  ABotonPorDefecto: TMsgDlgBtn): Integer; overload;
// Sustituto de Application.MessageBox: indicadores MB_OK, MB_YESNO,
// MB_ICONINFORMATION, MB_DEFBUTTON2... y resultados IDOK, IDYES, IDNO...
function MessageBox_fza(const ATexto, ATitulo: string;
  AIndicadores: Longint = MB_OK): Integer;

// Traducción entre los indicadores MB_* y el diálogo de la VCL. Públicas
// para poder probarlas sin mostrar ventanas.
function BotonesDeIndicadores(AIndicadores: Longint): TMsgDlgButtons;
function TipoDeIndicadores(AIndicadores: Longint): TMsgDlgType;
function BotonPorDefectoDeIndicadores(AIndicadores: Longint): TMsgDlgBtn;
function BotonPorDefectoDeBotones(ABotones: TMsgDlgButtons): TMsgDlgBtn;
function ResultadoDeMessageBox(AResultadoModal: Integer;
  AIndicadores: Longint): Integer;

implementation

uses
  System.SysUtils, Vcl.Forms, Vcl.Dialogs;

type
  TOrdenBotones = array of TMsgDlgBtn;

// Botones de cada tipo MB_* en el orden en que Windows los presenta; el
// índice de MB_DEFBUTTONn se refiere a ese orden.
function OrdenBotonesWindows(AIndicadores: Longint): TOrdenBotones;
begin
  case AIndicadores and MB_TYPEMASK of
    MB_OKCANCEL:
      Result := [mbOK, mbCancel];
    MB_ABORTRETRYIGNORE:
      Result := [mbAbort, mbRetry, mbIgnore];
    MB_YESNOCANCEL:
      Result := [mbYes, mbNo, mbCancel];
    MB_YESNO:
      Result := [mbYes, mbNo];
    MB_RETRYCANCEL:
      Result := [mbRetry, mbCancel];
    MB_CANCELTRYCONTINUE:
      Result := [mbCancel, mbRetry, mbIgnore];
  else
    Result := [mbOK];
  end;
end;

function BotonesDeIndicadores(AIndicadores: Longint): TMsgDlgButtons;
var
  oBoton: TMsgDlgBtn;
begin
  Result := [];
  for oBoton in OrdenBotonesWindows(AIndicadores) do
    Include(Result, oBoton);
end;

function TipoDeIndicadores(AIndicadores: Longint): TMsgDlgType;
begin
  // MB_ICONHAND agrupa STOP y ERROR; MB_ICONEXCLAMATION, WARNING;
  // MB_ICONASTERISK, INFORMATION.
  case AIndicadores and MB_ICONMASK of
    MB_ICONHAND:
      Result := mtError;
    MB_ICONQUESTION:
      Result := mtConfirmation;
    MB_ICONEXCLAMATION:
      Result := mtWarning;
    MB_ICONASTERISK:
      Result := mtInformation;
  else
    Result := mtCustom;
  end;
end;

function BotonPorDefectoDeIndicadores(AIndicadores: Longint): TMsgDlgBtn;
var
  aOrden: TOrdenBotones;
  iIndice: Integer;
begin
  aOrden := OrdenBotonesWindows(AIndicadores);
  iIndice := (AIndicadores and MB_DEFMASK) shr 8;
  if (iIndice < 0) or (iIndice > High(aOrden)) then
    iIndice := 0;
  Result := aOrden[iIndice];
end;

function BotonPorDefectoDeBotones(ABotones: TMsgDlgButtons): TMsgDlgBtn;
begin
  // Mismo criterio que MessageDlg de la VCL.
  if mbOK in ABotones then
    Result := mbOK
  else if mbYes in ABotones then
    Result := mbYes
  else
    Result := mbRetry;
end;

function ResultadoDeMessageBox(AResultadoModal: Integer;
  AIndicadores: Longint): Integer;
var
  bReintentarContinuar: Boolean;
  oBotones: TMsgDlgButtons;
begin
  oBotones := BotonesDeIndicadores(AIndicadores);
  bReintentarContinuar :=
    (AIndicadores and MB_TYPEMASK) = MB_CANCELTRYCONTINUE;
  case AResultadoModal of
    mrOk:
      Result := IDOK;
    mrAbort:
      Result := IDABORT;
    mrRetry:
      if bReintentarContinuar then
        Result := IDTRYAGAIN
      else
        Result := IDRETRY;
    mrIgnore:
      if bReintentarContinuar then
        Result := IDCONTINUE
      else
        Result := IDIGNORE;
    mrYes:
      Result := IDYES;
    mrNo:
      Result := IDNO;
  else
    // mrCancel: botón Cancelar, Escape o cierre de la ventana. Sin botón
    // Cancelar equivale al botón que la VCL asocia a Escape.
    if mbCancel in oBotones then
      Result := IDCANCEL
    else if mbNo in oBotones then
      Result := IDNO
    else if mbOK in oBotones then
      Result := IDOK
    else
      Result := IDCANCEL;
  end;
end;

function CrearDialogo(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; ABotonPorDefecto: TMsgDlgBtn;
  AContextoAyuda: Longint): TForm;
var
  iTamanoAnterior: Integer;
  sFuenteAnterior: string;
begin
  // CreateMessageDialog toma la fuente de Screen.MessageFont al crear el
  // formulario y dimensiona con ella el texto y los botones.
  sFuenteAnterior := Screen.MessageFont.Name;
  iTamanoAnterior := Screen.MessageFont.Size;
  Screen.MessageFont.Name := NOMBRE_FUENTE_MENSAJES;
  Screen.MessageFont.Size := TAMANO_FUENTE_MENSAJES;
  try
    Result := CreateMessageDialog(
      AMensaje, ATipo, ABotones, ABotonPorDefecto);
  finally
    Screen.MessageFont.Name := sFuenteAnterior;
    Screen.MessageFont.Size := iTamanoAnterior;
  end;
  Result.HelpContext := AContextoAyuda;
  Result.Position := poScreenCenter;
end;

function MostrarDialogo(ADialogo: TForm): Integer;
begin
  try
    Result := ADialogo.ShowModal;
  finally
    ADialogo.Free;
  end;
end;

procedure ShowMessage_fza(const AMensaje: string);
begin
  MostrarDialogo(CrearDialogo(AMensaje, mtCustom, [mbOK], mbOK, 0));
end;

procedure ShowMessageFmt_fza(const AFormato: string;
  const AArgumentos: array of const);
begin
  ShowMessage_fza(Format(AFormato, AArgumentos));
end;

function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint): Integer;
begin
  Result := MessageDlg_fza(AMensaje, ATipo, ABotones, AContextoAyuda,
    BotonPorDefectoDeBotones(ABotones));
end;

function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint;
  ABotonPorDefecto: TMsgDlgBtn): Integer;
begin
  Result := MostrarDialogo(CrearDialogo(
    AMensaje, ATipo, ABotones, ABotonPorDefecto, AContextoAyuda));
end;

function MessageBox_fza(const ATexto, ATitulo: string;
  AIndicadores: Longint): Integer;
var
  oDialogo: TForm;
begin
  oDialogo := CrearDialogo(ATexto, TipoDeIndicadores(AIndicadores),
    BotonesDeIndicadores(AIndicadores),
    BotonPorDefectoDeIndicadores(AIndicadores), 0);
  if ATitulo <> '' then
    oDialogo.Caption := ATitulo;
  if (AIndicadores and (MB_TOPMOST or MB_SYSTEMMODAL)) <> 0 then
    oDialogo.FormStyle := fsStayOnTop;
  // Mismo sonido que el MessageBox de Windows según el icono.
  if (AIndicadores and MB_ICONMASK) <> 0 then
    MessageBeep(AIndicadores and MB_ICONMASK);
  Result := ResultadoDeMessageBox(MostrarDialogo(oDialogo), AIndicadores);
end;

end.
