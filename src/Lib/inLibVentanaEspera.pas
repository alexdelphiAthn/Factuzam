{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentanaEspera                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ventana de espera con barra en movimiento continuo que vive en un hilo    }
{    propio, de modo que sigue animándose aunque el hilo principal esté        }
{    bloqueado en una consulta o preparando un informe. Solo usa la API de     }
{    Windows: ningún control VCL se toca desde el hilo de la ventana.          }
{    Incluye la espera de una tarea que atiende los mensajes que otros hilos   }
{    envían al principal (SendMessage, Synchronize) sin despachar la entrada.  }
{******************************************************************************}
unit inLibVentanaEspera;

interface

uses
  Winapi.Windows, System.Threading;

const
  // Clase de ventana registrada; permite a las pruebas localizarla.
  cClaseVentanaEspera = 'FactuzamVentanaEspera';

type
  // Contrato de la ventana de espera. Se usa desde el hilo principal y
  // ninguna llamada bloquea: solo envían mensajes al hilo de la ventana.
  IVentanaEspera = interface
    ['{7C1E1B7E-2C0B-4C4B-9F8E-5A0F6D5B2E31}']
    // Muestra la ventana con la fase indicada (o cambia la fase si ya
    // está visible), limpia el detalle y olvida una cancelación previa.
    procedure Mostrar(const AFase: string);
    // Cambia la línea de detalle ("Página 3. Seleccionando artículo...").
    procedure ActualizarDetalle(const ADetalle: string);
    // Habilita o deshabilita el botón Cancelar.
    procedure PermitirCancelar(APermitir: Boolean);
    // True si el usuario ha pulsado Cancelar desde el último Mostrar.
    function Cancelado: Boolean;
    // Oculta la ventana y descarta las pulsaciones de teclado y ratón
    // acumuladas mientras el hilo principal estaba ocupado.
    procedure Ocultar;
  end;

// Crea la ventana (oculta) centrada sobre AReferencia, en coordenadas de
// pantalla, con las medidas escaladas a APixelesPorPulgada. Liberar la
// interfaz cierra la ventana y termina su hilo.
function CrearVentanaEspera(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer): IVentanaEspera;

// Espera a que termine ATarea sin despachar teclado ni ratón (no hay
// reentrada en la pantalla) pero atendiendo lo que otros hilos piden al
// principal: SendMessage a sus ventanas (el monitor SQL escribe en un memo
// desde el hilo de la consulta) y Synchronize/Queue. Un WaitForAll a secas
// se queda bloqueado con esas peticiones pendientes.
procedure EsperarTareaAtendiendoMensajes(const ATarea: ITask);

implementation

uses
  Winapi.Messages, Winapi.CommCtrl, Winapi.MultiMon, System.SysUtils,
  System.Classes, System.Math, System.SyncObjs, inLibMsgComun;

const
  WM_ESPERA_MOSTRAR = WM_APP + 1;
  WM_ESPERA_OCULTAR = WM_APP + 2;
  WM_ESPERA_FASE = WM_APP + 3;
  WM_ESPERA_DETALLE = WM_APP + 4;
  WM_ESPERA_CANCELABLE = WM_APP + 5;
  WM_ESPERA_CERRAR = WM_APP + 6;
  ID_BOTON_CANCELAR = 1;
  PIXELES_POR_PULGADA_BASE = 96;
  PUNTOS_FUENTE = 13;
  NOMBRE_FUENTE = 'Lucida Sans';
  // Medidas a 96 ppp; se escalan a los ppp indicados al crear la ventana.
  ANCHO_VENTANA = 460;
  ALTO_VENTANA = 156;
  MARGEN_HORIZONTAL = 24;
  ARRIBA_FASE = 18;
  ALTO_FASE = 24;
  ARRIBA_DETALLE = 46;
  ALTO_DETALLE = 22;
  ARRIBA_BARRA = 80;
  ALTO_BARRA = 20;
  ARRIBA_BOTON = 112;
  ANCHO_BOTON = 100;
  ALTO_BOTON = 28;
  INTERVALO_MARQUEE_MS = 30;
  ESPERA_CREACION_MS = 3000;
  ESPERA_CIERRE_MS = 3000;
  INTERVALO_SONDEO_TAREA_MS = 20;

type
  // Hilo propietario de la ventana: crea la clase, la ventana y sus
  // controles, y bombea sus mensajes hasta recibir WM_ESPERA_CERRAR.
  THiloVentanaEspera = class(TThread)
  private
    FReferencia: TRect;
    FPixelesPorPulgada: Integer;
    FVentana: HWND;
    FBarra: HWND;
    FBoton: HWND;
    FFuente: HFONT;
    FFuenteNegrita: HFONT;
    FFase: string;
    FDetalle: string;
    FCancelado: Integer;
    FCreada: TEvent;
    function Escalar(AValor: Integer): Integer;
    function CrearVentana: Boolean;
    procedure CrearFuentes;
    procedure CrearControles;
    procedure Colocar;
    procedure LiberarFuentes;
    procedure Pintar;
    procedure PintarTexto(
      AContexto: HDC;
      AFuente: HFONT;
      AArriba, AAlto: Integer;
      const ATexto: string);
    procedure CambiarTexto(var ADestino: string; ALParam: LPARAM);
    procedure InvalidarTextos;
    procedure Cancelar;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AReferencia: TRect;
      APixelesPorPulgada: Integer);
    destructor Destroy; override;
    function Procesar(
      AVentana: HWND;
      AMensaje: UINT;
      AWParam: WPARAM;
      ALParam: LPARAM): LRESULT;
    function EstaCancelado: Boolean;
    procedure ReiniciarCancelacion;
    property Creada: TEvent read FCreada;
    property Ventana: HWND read FVentana;
  end;

  TVentanaEspera = class(TInterfacedObject, IVentanaEspera)
  private
    FHilo: THiloVentanaEspera;
    function VentanaLista: HWND;
    procedure Enviar(AMensaje: UINT; AWParam: WPARAM);
    procedure EnviarTexto(AMensaje: UINT; const ATexto: string);
    procedure CerrarHilo;
  public
    constructor Create(
      const AReferencia: TRect;
      APixelesPorPulgada: Integer);
    destructor Destroy; override;
    procedure Mostrar(const AFase: string);
    procedure ActualizarDetalle(const ADetalle: string);
    procedure PermitirCancelar(APermitir: Boolean);
    function Cancelado: Boolean;
    procedure Ocultar;
  end;

// Procedimiento de ventana: delega en el hilo guardado en los datos de
// usuario de la ventana desde WM_NCCREATE.
function VentanaEsperaWndProc(
  AVentana: HWND;
  AMensaje: UINT;
  AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  oHilo: THiloVentanaEspera;
begin
  if AMensaje = WM_NCCREATE then
    SetWindowLongPtr(AVentana, GWLP_USERDATA,
      LONG_PTR(PCreateStruct(ALParam)^.lpCreateParams));
  oHilo := THiloVentanaEspera(
    Pointer(GetWindowLongPtr(AVentana, GWLP_USERDATA)));
  if oHilo <> nil then
    Result := oHilo.Procesar(AVentana, AMensaje, AWParam, ALParam)
  else
    Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
end;

// Vacía la cola de teclado y ratón del hilo que llama. Devuelve cuántos
// mensajes se han descartado.
function DescartarEntradaPendiente: Integer;
var
  oMensaje: TMsg;
begin
  Result := 0;
  while PeekMessage(oMensaje, 0, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE) do
    Inc(Result);
  while PeekMessage(oMensaje, 0, WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE) do
    Inc(Result);
end;

{ THiloVentanaEspera }

constructor THiloVentanaEspera.Create(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer);
begin
  inherited Create(True);
  FReferencia := AReferencia;
  FPixelesPorPulgada := Max(APixelesPorPulgada, PIXELES_POR_PULGADA_BASE);
  FCreada := TEvent.Create(nil, True, False, '');
end;

destructor THiloVentanaEspera.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FCreada);
end;

function THiloVentanaEspera.Escalar(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, FPixelesPorPulgada, PIXELES_POR_PULGADA_BASE);
end;

function THiloVentanaEspera.CrearVentana: Boolean;
var
  oClase: TWndClassEx;
begin
  FillChar(oClase, SizeOf(oClase), 0);
  oClase.cbSize := SizeOf(oClase);
  oClase.lpfnWndProc := @VentanaEsperaWndProc;
  oClase.hInstance := HInstance;
  oClase.hCursor := LoadCursor(0, IDC_WAIT);
  oClase.hbrBackground := HBRUSH(COLOR_BTNFACE + 1);
  oClase.lpszClassName := cClaseVentanaEspera;
  if (RegisterClassEx(oClase) = 0) and
     (GetLastError <> ERROR_CLASS_ALREADY_EXISTS) then
    Result := False
  else
  begin
    FVentana := CreateWindowEx(
      WS_EX_TOPMOST or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE,
      cClaseVentanaEspera, '', WS_POPUP or WS_BORDER,
      0, 0, Escalar(ANCHO_VENTANA), Escalar(ALTO_VENTANA),
      0, 0, HInstance, Pointer(Self));
    Result := FVentana <> 0;
  end;
end;

procedure THiloVentanaEspera.CrearFuentes;
var
  oFuente: TLogFont;
begin
  FillChar(oFuente, SizeOf(oFuente), 0);
  oFuente.lfHeight := -MulDiv(PUNTOS_FUENTE, FPixelesPorPulgada, 72);
  oFuente.lfWeight := FW_NORMAL;
  oFuente.lfCharSet := DEFAULT_CHARSET;
  oFuente.lfQuality := CLEARTYPE_QUALITY;
  StrPLCopy(oFuente.lfFaceName, NOMBRE_FUENTE, LF_FACESIZE - 1);
  FFuente := CreateFontIndirect(oFuente);
  oFuente.lfWeight := FW_BOLD;
  FFuenteNegrita := CreateFontIndirect(oFuente);
end;

procedure THiloVentanaEspera.LiberarFuentes;
begin
  if FFuente <> 0 then
    DeleteObject(FFuente);
  if FFuenteNegrita <> 0 then
    DeleteObject(FFuenteNegrita);
  FFuente := 0;
  FFuenteNegrita := 0;
end;

procedure THiloVentanaEspera.CrearControles;
var
  oControles: TInitCommonControlsEx;
begin
  oControles.dwSize := SizeOf(oControles);
  oControles.dwICC := ICC_PROGRESS_CLASS;
  InitCommonControlsEx(oControles);
  FBarra := CreateWindowEx(0, PROGRESS_CLASS, '',
    WS_CHILD or WS_VISIBLE or PBS_MARQUEE,
    0, 0, 0, 0, FVentana, 0, HInstance, nil);
  SendMessage(FBarra, PBM_SETMARQUEE, 1, INTERVALO_MARQUEE_MS);
  FBoton := CreateWindowEx(0, 'BUTTON', PChar(SCaptionCancelar),
    WS_CHILD or WS_VISIBLE or WS_DISABLED or BS_PUSHBUTTON,
    0, 0, 0, 0, FVentana, HMENU(ID_BOTON_CANCELAR), HInstance, nil);
  SendMessage(FBoton, WM_SETFONT, WPARAM(FFuente), 1);
end;

procedure THiloVentanaEspera.Colocar;
var
  iAncho: Integer;
  iAlto: Integer;
  iIzquierda: Integer;
  iArriba: Integer;
  oMonitor: TMonitorInfo;
begin
  iAncho := Escalar(ANCHO_VENTANA);
  iAlto := Escalar(ALTO_VENTANA);
  iIzquierda := FReferencia.Left + (FReferencia.Width - iAncho) div 2;
  iArriba := FReferencia.Top + (FReferencia.Height - iAlto) div 2;
  oMonitor.cbSize := SizeOf(oMonitor);
  if GetMonitorInfo(
       MonitorFromRect(@FReferencia, MONITOR_DEFAULTTONEAREST),
       @oMonitor) then
  begin
    iIzquierda := Max(oMonitor.rcWork.Left,
      Min(iIzquierda, oMonitor.rcWork.Right - iAncho));
    iArriba := Max(oMonitor.rcWork.Top,
      Min(iArriba, oMonitor.rcWork.Bottom - iAlto));
  end;
  SetWindowPos(FVentana, HWND_TOPMOST, iIzquierda, iArriba, iAncho, iAlto,
    SWP_NOACTIVATE);
  MoveWindow(FBarra, Escalar(MARGEN_HORIZONTAL), Escalar(ARRIBA_BARRA),
    iAncho - 2 * Escalar(MARGEN_HORIZONTAL), Escalar(ALTO_BARRA), True);
  MoveWindow(FBoton, (iAncho - Escalar(ANCHO_BOTON)) div 2,
    Escalar(ARRIBA_BOTON), Escalar(ANCHO_BOTON), Escalar(ALTO_BOTON), True);
end;

procedure THiloVentanaEspera.PintarTexto(
  AContexto: HDC;
  AFuente: HFONT;
  AArriba, AAlto: Integer;
  const ATexto: string);
var
  oRect: TRect;
  hAnterior: HGDIOBJ;
begin
  GetClientRect(FVentana, oRect);
  oRect.Left := Escalar(MARGEN_HORIZONTAL);
  oRect.Right := oRect.Right - Escalar(MARGEN_HORIZONTAL);
  oRect.Top := AArriba;
  oRect.Bottom := AArriba + AAlto;
  hAnterior := SelectObject(AContexto, AFuente);
  try
    DrawText(AContexto, PChar(ATexto), Length(ATexto), oRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
  finally
    SelectObject(AContexto, hAnterior);
  end;
end;

procedure THiloVentanaEspera.Pintar;
var
  oPintado: TPaintStruct;
  hContexto: HDC;
begin
  hContexto := BeginPaint(FVentana, oPintado);
  try
    FillRect(hContexto, oPintado.rcPaint, GetSysColorBrush(COLOR_BTNFACE));
    SetBkMode(hContexto, TRANSPARENT);
    SetTextColor(hContexto, GetSysColor(COLOR_BTNTEXT));
    PintarTexto(hContexto, FFuenteNegrita,
      Escalar(ARRIBA_FASE), Escalar(ALTO_FASE), FFase);
    PintarTexto(hContexto, FFuente,
      Escalar(ARRIBA_DETALLE), Escalar(ALTO_DETALLE), FDetalle);
  finally
    EndPaint(FVentana, oPintado);
  end;
end;

procedure THiloVentanaEspera.InvalidarTextos;
var
  oRect: TRect;
begin
  GetClientRect(FVentana, oRect);
  oRect.Bottom := Escalar(ARRIBA_BARRA);
  InvalidateRect(FVentana, @oRect, False);
end;

procedure THiloVentanaEspera.CambiarTexto(
  var ADestino: string;
  ALParam: LPARAM);
var
  pTexto: PChar;
begin
  pTexto := PChar(ALParam);
  if pTexto <> nil then
  begin
    ADestino := pTexto;
    StrDispose(pTexto);
  end
  else
    ADestino := '';
  InvalidarTextos;
end;

procedure THiloVentanaEspera.Cancelar;
begin
  AtomicExchange(FCancelado, 1);
  EnableWindow(FBoton, False);
  FDetalle := SCaptionCancelandoOperacion;
  InvalidarTextos;
end;

function THiloVentanaEspera.EstaCancelado: Boolean;
begin
  Result := AtomicCmpExchange(FCancelado, 0, 0) <> 0;
end;

procedure THiloVentanaEspera.ReiniciarCancelacion;
begin
  AtomicExchange(FCancelado, 0);
end;

function THiloVentanaEspera.Procesar(
  AVentana: HWND;
  AMensaje: UINT;
  AWParam: WPARAM;
  ALParam: LPARAM): LRESULT;
begin
  Result := 0;
  case AMensaje of
    WM_NCCREATE:
      begin
        FVentana := AVentana;
        Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
      end;
    WM_CREATE:
      begin
        CrearFuentes;
        CrearControles;
        Colocar;
      end;
    WM_PAINT:
      Pintar;
    WM_COMMAND:
      if (LoWord(AWParam) = ID_BOTON_CANCELAR) and
         (HiWord(AWParam) = BN_CLICKED) then
        Cancelar;
    WM_ESPERA_MOSTRAR:
      ShowWindow(AVentana, SW_SHOWNOACTIVATE);
    WM_ESPERA_OCULTAR:
      ShowWindow(AVentana, SW_HIDE);
    WM_ESPERA_FASE:
      CambiarTexto(FFase, ALParam);
    WM_ESPERA_DETALLE:
      CambiarTexto(FDetalle, ALParam);
    WM_ESPERA_CANCELABLE:
      EnableWindow(FBoton, AWParam <> 0);
    WM_ESPERA_CERRAR:
      DestroyWindow(AVentana);
    WM_DESTROY:
      PostQuitMessage(0);
  else
    Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
  end;
end;

procedure THiloVentanaEspera.Execute;
var
  oMensaje: TMsg;
begin
  NameThreadForDebugging('VentanaEspera');
  try
    if CrearVentana then
    begin
      FCreada.SetEvent;
      while GetMessage(oMensaje, 0, 0, 0) do
      begin
        TranslateMessage(oMensaje);
        DispatchMessage(oMensaje);
      end;
    end;
  finally
    LiberarFuentes;
    FCreada.SetEvent;
  end;
end;

{ TVentanaEspera }

constructor TVentanaEspera.Create(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer);
begin
  inherited Create;
  FHilo := THiloVentanaEspera.Create(AReferencia, APixelesPorPulgada);
  FHilo.Start;
end;

destructor TVentanaEspera.Destroy;
begin
  if FHilo <> nil then
  begin
    CerrarHilo;
    FreeAndNil(FHilo);
  end;
  inherited Destroy;
end;

function TVentanaEspera.VentanaLista: HWND;
begin
  Result := 0;
  if (FHilo <> nil) and
     (FHilo.Creada.WaitFor(ESPERA_CREACION_MS) = wrSignaled) then
    Result := FHilo.Ventana;
end;

procedure TVentanaEspera.Enviar(AMensaje: UINT; AWParam: WPARAM);
var
  hVentana: HWND;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
    PostMessage(hVentana, AMensaje, AWParam, 0);
end;

procedure TVentanaEspera.EnviarTexto(AMensaje: UINT; const ATexto: string);
var
  hVentana: HWND;
  pTexto: PChar;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
  begin
    pTexto := StrNew(PChar(ATexto));
    if not PostMessage(hVentana, AMensaje, 0, LPARAM(pTexto)) then
      StrDispose(pTexto);
  end;
end;

procedure TVentanaEspera.CerrarHilo;
var
  hVentana: HWND;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
    PostMessage(hVentana, WM_ESPERA_CERRAR, 0, 0);
  if WaitForSingleObject(FHilo.Handle, ESPERA_CIERRE_MS) <> WAIT_OBJECT_0 then
    PostThreadMessage(FHilo.ThreadID, WM_QUIT, 0, 0);
end;

procedure TVentanaEspera.Mostrar(const AFase: string);
begin
  if FHilo <> nil then
    FHilo.ReiniciarCancelacion;
  EnviarTexto(WM_ESPERA_FASE, AFase);
  EnviarTexto(WM_ESPERA_DETALLE, '');
  Enviar(WM_ESPERA_MOSTRAR, 0);
end;

procedure TVentanaEspera.ActualizarDetalle(const ADetalle: string);
begin
  EnviarTexto(WM_ESPERA_DETALLE, ADetalle);
end;

procedure TVentanaEspera.PermitirCancelar(APermitir: Boolean);
begin
  Enviar(WM_ESPERA_CANCELABLE, WPARAM(Ord(APermitir)));
end;

function TVentanaEspera.Cancelado: Boolean;
begin
  Result := (FHilo <> nil) and FHilo.EstaCancelado;
end;

procedure TVentanaEspera.Ocultar;
begin
  Enviar(WM_ESPERA_OCULTAR, 0);
  DescartarEntradaPendiente;
end;

function CrearVentanaEspera(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer): IVentanaEspera;
begin
  Result := TVentanaEspera.Create(AReferencia, APixelesPorPulgada);
end;

procedure EsperarTareaAtendiendoMensajes(const ATarea: ITask);
var
  oMensaje: TMsg;
begin
  if Assigned(ATarea) then
    while not (ATarea.Status in [TTaskStatus.Completed,
      TTaskStatus.Canceled, TTaskStatus.Exception]) do
    begin
      // PeekMessage sin extraer entrega los SendMessage de otros hilos.
      PeekMessage(oMensaje, 0, 0, 0, PM_NOREMOVE);
      CheckSynchronize(INTERVALO_SONDEO_TAREA_MS);
    end;
end;

end.
