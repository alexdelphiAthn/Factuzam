unit inLibLectorScanner;
{ Detector reutilizable de lector de codigo de barras a nivel de formulario.
  Encapsula las dos formas de deteccion que estaban duplicadas en caja,
  consulta de stock y traspasos, para poder incorporarlas a cualquier
  mantenimiento nuevo sin volver a copiar el codigo:
    1) Trama STX(#2) + codigo + ETX(#3): el lector envuelve el codigo. Las
       teclas se consumen para no ensuciar el control con foco. Si el lector
       remata la trama con un CR, ese Enter tambien se consume (llega en la
       misma rafaga que el ETX) para que no pulse el boton con foco ni salte
       de campo.
    2) Por VELOCIDAD de tecleo (codigo de barras + CR, sin STX/ETX): el lector
       teclea en rafaga. Medimos la cadencia (ms entre teclas) con GetTickCount;
       si el Enter llega igual de rapido tras una rafaga lo bastante larga, lo
       tratamos como una lectura.
  El procesado del codigo es responsabilidad del formulario (evento
  OnCodigoLeido): la unidad solo DETECTA. El procesado se difiere fuera del
  flujo de teclas con una ventana oculta propia (AllocateHWnd), de modo que el
  formulario no necesita declarar su propio mensaje WM_USER ni su manejador.
  Para incorporarlo a un mantenimiento basta con: crear la instancia en el
  OnCreate, asignar OnCodigoLeido, llamar a KeyDown/KeyPress desde los eventos
  OnKeyDown/OnKeyPress del form (que debe tener KeyPreview := True) y liberar la
  instancia en el OnDestroy.
  El Enter que cierra la lectura conviene entregarlo ademas desde OnShortCut
  del form (AtajoTeclado): ese evento se dispara en CN_KEYDOWN, ANTES que
  CM_DIALOGKEY (jvEnterTab convierte Enter en Tab) y que el boton con foco
  (Enter = clic), que de otro modo se quedan con la tecla sin que OnKeyDown
  llegue a verla cuando el foco no esta en una rejilla. }

interface
uses
  Windows, Messages, Classes, Controls;
type
  // El form resuelve y aplica el codigo leido (logica de negocio).
  TEventoCodigoLeido = procedure(Sender: TObject;
                                 const ACodigo: string) of object;
  // Consultas opcionales para afinar el detector por velocidad cuando hay una
  // rejilla editable de por medio.
  TConsultaBooleana = function: Boolean of object;
  TConsultaControl  = function(AControl: TControl): Boolean of object;
  TLectorScanner = class(TObject)
  private
    // --- Configuracion (la puebla el formulario tras crear la instancia) -----
    FActivo: Boolean;
    FUmbralMs: Cardinal;
    FLongitudMinima: Integer;
    FConsumirRafaga: Boolean;
    FOmitirEnRejilla: Boolean;
    // --- Estado interno del detector
    // ------------------------------------------
    FHandle: HWND;
    FLeyendoTrama: Boolean;
    FBufferTrama: string;
    FBufferVel: string;
    FTick: Cardinal;
    FEnterConsumido: Boolean;
    FControl: TWinControl;
    FTextoPrevio: string;
    FInicioChar: Char;
    FEsperaEco: Boolean;
    FRejillaEditaba: Boolean;
    FCodigoPend: string;
    // ETX recibido y todavia sin ninguna otra tecla: el siguiente Enter, si
    // llega en la misma rafaga (hora del mensaje), es el CR del lector.
    FTramaCerrada: Boolean;
    FTiempoTrama: Cardinal;
    // --- Eventos
    // ---------------------------------------------------------------
    FOnCodigoLeido: TEventoCodigoLeido;
    FOnLecturaIniciada: TNotifyEvent;
    FOnRejillaEditando: TConsultaBooleana;
    FOnEsControlRejilla: TConsultaControl;
    procedure WndProc(var Msg: TMessage);
    procedure CapturarControl;
    procedure RestaurarControl;
    function EsControlRejilla(AControl: TControl): Boolean;
    function EnRejilla: Boolean;
    function CerrarLecturaConEnter: Boolean;
  protected
    // Relojes sustituibles en pruebas: cadencia de tecleo (GetTickCount) y
    // hora en que Windows encolo la tecla en curso (GetMessageTime).
    function TiempoActual: Cardinal; virtual;
    function TiempoMensaje: Cardinal; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // Se invocan desde OnKeyDown / OnKeyPress del formulario (KeyPreview=True).
    procedure KeyDown(var Key: Word; Shift: TShiftState);
    procedure KeyPress(var Key: Char);
    // Se invoca desde OnShortCut del formulario. True si el Enter cierra una
    // lectura (rafaga rapida o CR que el lector envia tras ETX) y se ha
    // consumido: el form debe marcar Handled para que no llegue a jvEnterTab
    // ni al control con foco.
    function AtajoTeclado(var AMensaje: TWMKey): Boolean;
    // True mientras se acumula una trama STX/ETX (lo consulta el form para,
    // p.ej., no relanzar su timer de busqueda incremental).
    property LeyendoTrama: Boolean read FLeyendoTrama;
    // Activa el detector por VELOCIDAD. La trama STX/ETX actua siempre.
    property Activo: Boolean read FActivo write FActivo;
    // Cadencia maxima (ms) entre teclas para considerarlas rafaga del lector.
    property UmbralMs: Cardinal read FUmbralMs write FUmbralMs;
    // Longitud minima del codigo para aceptar la rafaga como lectura.
    property LongitudMinima: Integer read FLongitudMinima
                                     write FLongitudMinima;
    // True: las teclas rapidas de la rafaga se consumen (no llegan al control,
    // util si el control dispara logica costosa en cada cambio). False: se
    // dejan pasar y se restaura el texto previo del control al cerrar.
    property ConsumirRafaga: Boolean read FConsumirRafaga
                                     write FConsumirRafaga;
    // True: el detector por velocidad permanece pasivo si el foco esta en la
    // rejilla (la lectura en celda la resuelve otro mecanismo). Requiere
    // OnEsControlRejilla.
    property OmitirEnRejilla: Boolean read FOmitirEnRejilla
                                      write FOmitirEnRejilla;
    property OnCodigoLeido: TEventoCodigoLeido read FOnCodigoLeido
                                               write FOnCodigoLeido;
    property OnLecturaIniciada: TNotifyEvent read FOnLecturaIniciada
                                             write FOnLecturaIniciada;
    property OnRejillaEditando: TConsultaBooleana read FOnRejillaEditando
                                                  write FOnRejillaEditando;
    property OnEsControlRejilla: TConsultaControl read FOnEsControlRejilla
                                                  write FOnEsControlRejilla;
  end;

implementation

uses
  Forms, SysUtils, cxTextEdit, cxEdit;
const
  // Mensaje interno para diferir el procesado fuera del KeyPress/KeyDown.
  WM_LECTOR_PROCESAR = WM_USER + 200;
  // Maximo de ms (hora de mensaje) entre el ETX y el Enter para tratar ese
  // Enter como el CR con que el lector remata la trama. Se mide con la hora
  // en que Windows encolo cada tecla, asi que no le afecta lo que tarde el
  // formulario en procesar el codigo entre medias.
  MS_CR_TRAS_TRAMA = 300;

constructor TLectorScanner.Create;
begin
  inherited Create;
  FHandle := Classes.AllocateHWnd(WndProc);
  FActivo := True;
  FUmbralMs := 40;
  FLongitudMinima := 4;
  FConsumirRafaga := False;
  FOmitirEnRejilla := False;
end;

destructor TLectorScanner.Destroy;
begin
  if FHandle <> 0 then
    Classes.DeallocateHWnd(FHandle);
  inherited Destroy;
end;

function TLectorScanner.TiempoActual: Cardinal;
begin
  Result := GetTickCount;
end;

function TLectorScanner.TiempoMensaje: Cardinal;
begin
  Result := Cardinal(GetMessageTime);
end;

// Recibe el mensaje diferido y dispara el procesado de negocio ya fuera del
// flujo de teclas (cxGrid / jvEnterTab han terminado de procesar la tecla).
procedure TLectorScanner.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_LECTOR_PROCESAR then
  begin
    if (FCodigoPend <> '') and Assigned(FOnCodigoLeido) then
    begin
      FOnCodigoLeido(Self, FCodigoPend);
      FCodigoPend := '';
    end;
  end
  else
    Msg.Result := DefWindowProc(FHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

// True si el control es (o esta dentro de) la rejilla que el form declara como
// suya. Sin callback no hay rejilla -> False.
function TLectorScanner.EsControlRejilla(AControl: TControl): Boolean;
begin
  if Assigned(FOnEsControlRejilla) then
    Result := FOnEsControlRejilla(AControl)
  else
    Result := False;
end;

function TLectorScanner.EnRejilla: Boolean;
begin
  Result := EsControlRejilla(Screen.ActiveControl);
end;

// Guarda el control con foco y su texto al iniciar una rafaga, para poder
// restaurarlo si la lectura entro con el foco fuera de la rejilla. Se llama en
// KeyPress (KeyPreview), antes de que el control reciba el caracter.
procedure TLectorScanner.CapturarControl;
begin
  FControl := Screen.ActiveControl;
  FTextoPrevio := '';
  if (FControl <> nil) and (FControl is TcxCustomTextEdit) then
    FTextoPrevio := TcxCustomTextEdit(FControl).Text;
end;

procedure TLectorScanner.RestaurarControl;
begin
  if (FControl <> nil) and (FControl is TcxCustomTextEdit)
     and (not EsControlRejilla(FControl)) then
  begin
    TcxCustomTextEdit(FControl).Text := FTextoPrevio;
    // El cambio de foco al cerrar la lectura es ASINCRONO: para cuando el
    // control pierde el foco, el flag de escaneo del form ya no esta activo y
    // el cxEdit validaria su contenido al salir (p.ej. "el codigo de cliente
    // no existe"). Marcandolo como NO modificado, ni el OnExit ni la
    // validacion interna del cxEdit se disparan al perder el foco.
    TcxCustomEdit(FControl).EditModified := False;
  end;
  FControl := nil;
  FTextoPrevio := '';
end;

// Acumula la rafaga y la cadencia; la decision final (rafaga + Enter rapido) se
// toma en KeyDown / AtajoTeclado, para adelantarse al editor del grid y a
// jvEnterTab.
procedure TLectorScanner.KeyPress(var Key: Char);
var
  ahora, delta: Cardinal;
begin
  if Key = #2 then
  begin
    // Inicio de trama STX: empezamos a acumular y avisamos al form (timers...).
    FLeyendoTrama := True;
    FTramaCerrada := False;
    FBufferTrama := '';
    FBufferVel := '';
    FEsperaEco := False;
    Key := #0;
    if Assigned(FOnLecturaIniciada) then
      FOnLecturaIniciada(Self);
  end
  else if FLeyendoTrama then
  begin
    if Key = #3 then
    begin
      FLeyendoTrama := False;
      // El Enter que llegue en la misma rafaga que este ETX es del lector.
      FTramaCerrada := True;
      FTiempoTrama := TiempoMensaje;
      Key := #0;
      if Trim(FBufferTrama) <> '' then
      begin
        FCodigoPend := Trim(FBufferTrama);
        PostMessage(FHandle, WM_LECTOR_PROCESAR, 0, 0);
      end;
      FBufferTrama := '';
    end
    else
    begin
      FBufferTrama := FBufferTrama + Key;
      Key := #0;
    end;
  end
  else
  begin
    if FEnterConsumido and (Key = #13) then
    begin
      // El #13 del Enter ya consumido en KeyDown: lo tragamos, este o no
      // activo el detector por velocidad (tambien cubre el CR tras ETX).
      FEnterConsumido := False;
      Key := #0;
    end
    else
      FTramaCerrada := False;
    if FActivo and (not (FOmitirEnRejilla and EnRejilla)) then
    begin
      // --- Detector por velocidad de tecleo
      // -------------------------------------
      ahora := TiempoActual;
      delta := ahora - FTick;
      FTick := ahora;
      if Key = #0 then
        // Tecla ya consumida: no altera la rafaga.
        FEsperaEco := FEsperaEco
      else if Key >= ' ' then
      begin
        if delta <= FUmbralMs then
        begin
          // Tecla rapida: forma parte de la rafaga del lector.
          if FConsumirRafaga then
          begin
            FBufferVel := FBufferVel + Key;
            Key := #0;
          end
          else if FEsperaEco and (Key = FInicioChar) then
            // Anti-eco: descartamos el reenvio del 1er caracter que hace el
            // cxGrid al arrancar la edicion de la celda.
            FEsperaEco := False
          else
          begin
            FEsperaEco := False;
            FBufferVel := FBufferVel + Key;
          end;
        end
        else
        begin
          // Primer caracter (lento): posible inicio de rafaga.
          FBufferVel := Key;
          if FConsumirRafaga then
            // No se consume (podria ser manual) ni se captura el control.
            FEsperaEco := False
          else
          begin
            CapturarControl;
            FInicioChar := Key;
            FEsperaEco := EsControlRejilla(FControl) and (not FRejillaEditaba);
          end;
        end;
      end
      else
      begin
        FBufferVel := '';
        FEsperaEco := False;
      end;
    end;
  end;
end;

// Decide si el Enter que acaba de llegar pertenece al lector y, en ese caso,
// cierra la lectura: CR inmediatamente posterior a una trama STX/ETX (solo se
// descarta) o rafaga rapida acumulada por el detector de velocidad (se
// encamina al procesado). True si el Enter debe consumirse.
function TLectorScanner.CerrarLecturaConEnter: Boolean;
var
  delta: Cardinal;
begin
  Result := False;
  if FTramaCerrada then
  begin
    FTramaCerrada := False;
    Result := (TiempoMensaje - FTiempoTrama) <= MS_CR_TRAS_TRAMA;
  end;
  if (not Result) and FActivo
     and (not (FOmitirEnRejilla and EnRejilla)) then
  begin
    delta := TiempoActual - FTick;
    if (Length(FBufferVel) >= FLongitudMinima) and (delta <= FUmbralMs) then
    begin
      FCodigoPend := Trim(FBufferVel);
      FBufferVel := '';
      if not FConsumirRafaga then
        RestaurarControl;
      PostMessage(FHandle, WM_LECTOR_PROCESAR, 0, 0);
      Result := True;
    end;
  end;
  if Result then
    FEnterConsumido := True;
end;

// Cierra el detector por velocidad: si hay rafaga acumulada y el Enter llega
// igual de rapido, lo tratamos como lectura y lo encaminamos al procesado.
procedure TLectorScanner.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // Reseteamos en cada tecla el flag de "Enter ya consumido" (solo vive de
  // forma transitoria entre el VK_RETURN consumido y su #13 de KeyPress).
  FEnterConsumido := False;
  // Estado de edicion de la rejilla ANTES de esta tecla (KeyPreview corre antes
  // que el KeyDown de la rejilla): lo usa el anti-eco del modo restaurar.
  if Assigned(FOnRejillaEditando) then
    FRejillaEditaba := FOnRejillaEditando()
  else
    FRejillaEditaba := False;
  if Key = VK_RETURN then
  begin
    if CerrarLecturaConEnter then
      Key := 0;
  end
  else
    FTramaCerrada := False;
end;

// Misma decision que KeyDown, pero desde OnShortCut (CN_KEYDOWN): el Enter se
// consume antes de que CM_DIALOGKEY lo convierta en Tab o de que el boton con
// foco lo tome como clic. Si se consume, Windows no genera el #13 de KeyPress
// ni el OnKeyDown, asi que no hay doble procesado.
function TLectorScanner.AtajoTeclado(var AMensaje: TWMKey): Boolean;
begin
  Result := False;
  if AMensaje.CharCode = VK_RETURN then
  begin
    Result := CerrarLecturaConEnter;
    if Result then
      AMensaje.CharCode := 0;
  end;
end;

end.
