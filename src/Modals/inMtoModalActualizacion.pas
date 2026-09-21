{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalActualizacion                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Muestra el progreso de comprobar, instalar y revertir una versión.        }
{******************************************************************************}
unit inMtoModalActualizacion;

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxProgressBar,
  inMtoFrmBase,
  inLibActualizacionEstado,
  inLibActualizacionIntf,
  inLibActualizacionProceso,
  inLibActualizacionScriptsLectura,
  inLibActualizacionScripts,
  inLibAnfitrionMtoIntf,
  inLibParametrosIntf,
  inLibVentanaEspera;

const
  cMensajeEjecutarActualizacion = WM_APP + 121;

type
  TfrmModalActualizacion = class(TfrmBase)
    lblTitulo: TcxLabel;
    lblEstado: TcxLabel;
    prgProceso: TcxProgressBar;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    FAnfitrion: IAnfitrionMantenimiento;
    FContexto: TContextoActualizacion;
    FIniciado: Boolean;
    FModo: TModoPantallaActualizacion;
    FProcesando: Boolean;
    FResultado: TResultadoActualizacion;
    function TextoScriptsFaltantes(
      const AFaltantes: TArray<TScriptFaltante>): string;
    function TextoEstadoReversion(
      const AEstado: TEstadoActualizacion): string;
    function CrearInteraccion: TInteraccionActualizacion;
    procedure EjecutarProceso;
    procedure MensajeEjecutarActualizacion(
      var AMensaje: TMessage); message cMensajeEjecutarActualizacion;
  protected
    procedure DoCreate; override;
  public
    procedure Progreso(const ATexto: string; APorcentaje: Integer);
    function ConfirmarInstalacion(
      const AManifiesto: TManifiestoActualizacion): Boolean;
    function DecidirScripts(
      const AFaltantes: TArray<TScriptFaltante>;
      AHayVersionNueva: Boolean):
      TDecisionScriptsActualizacion;
    function CrearVentanaProceso(const ATitulo: string): IVentanaEspera;
    function CrearVentanaEsperaPantalla: IVentanaEspera;
    function SolicitarCopiaPrevia(out ARutaCopia: string): Boolean;
    function ConfirmarReversion(
      const AEstado: TEstadoActualizacion): Boolean;
    function ConsultarRestaurarCopia(
      const ASinRollback: TArray<string>;
      const ARutaCopia: string): Boolean;
    class function Ejecutar(
      AOwner: TComponent;
      const AAnfitrion: IAnfitrionMantenimiento;
      const AParametros: IParametrosAplicacion;
      AConexion: TUniConnection;
      const AVersionInstalada: string;
      AModo: TModoPantallaActualizacion;
      out AResultado: TResultadoActualizacion): Boolean;
  end;

implementation

uses
  System.IOUtils,
  inLibActualizacionServicio,
  inLibMensajesVcl,
  inLibMsgIntegraciones,
  inMtoModalMensajeTexto;

{$R *.dfm}

class function TfrmModalActualizacion.Ejecutar(
  AOwner: TComponent;
  const AAnfitrion: IAnfitrionMantenimiento;
  const AParametros: IParametrosAplicacion;
  AConexion: TUniConnection;
  const AVersionInstalada: string;
  AModo: TModoPantallaActualizacion;
  out AResultado: TResultadoActualizacion): Boolean;
var
  oFormulario: TfrmModalActualizacion;
begin
  oFormulario := TfrmModalActualizacion.Create(AOwner);
  try
    oFormulario.FAnfitrion := AAnfitrion;
    oFormulario.FModo := AModo;
    oFormulario.FProcesando := True;
    oFormulario.FContexto.Conexion := AConexion;
    oFormulario.FContexto.VersionInstalada := AVersionInstalada;
    oFormulario.FContexto.RutaEjecutable := ExpandFileName(ParamStr(0));
    oFormulario.FContexto.Servicio := CrearServicioActualizaciones(
      AParametros,
      oFormulario.Progreso);
    oFormulario.ShowModal;
    AResultado := oFormulario.FResultado;
    Result := AResultado.Ok;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalActualizacion.DoCreate;
begin
  inherited;
  // FormCreate de TfrmBase traduce el Caption por la jerarquía de clases:
  // sin clave propia dejaría 'frmBase'. El modo todavía no está asignado,
  // así que el título definitivo se pone en FormShow.
  Caption := STituloComprobarActualizaciones;
end;

procedure TfrmModalActualizacion.Progreso(
  const ATexto: string;
  APorcentaje: Integer);
begin
  lblEstado.Caption := ATexto;
  if APorcentaje < 0 then
  begin
    // Sin porcentaje conocido: se avanza un poco para que se vea vivo.
    if prgProceso.Position < 90 then
      prgProceso.Position := prgProceso.Position + 5;
  end
  else if APorcentaje > 100 then
    prgProceso.Position := 100
  else
    prgProceso.Position := APorcentaje;
  Update;
  Application.ProcessMessages;
end;

function TfrmModalActualizacion.ConfirmarInstalacion(
  const AManifiesto: TManifiestoActualizacion): Boolean;
var
  sTexto: string;
begin
  sTexto := Format(
    SDetalleActualizacionDisponible,
    [FContexto.VersionInstalada,
     AManifiesto.Version,
     AManifiesto.Fecha,
     FormatFloat('#,##0', AManifiesto.Ejecutable.Tamano),
     FormatFloat('#,##0', AManifiesto.Ejecutable.TamanoDescarga),
     Length(AManifiesto.Auxiliares),
     AManifiesto.Notas]);
  TfrmModalMensajeTexto.Mostrar(Self, sTexto);
  Result := MessageDlg_fza(
    Format(SPreguntaInstalarActualizacion, [AManifiesto.Version]),
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

function TfrmModalActualizacion.TextoScriptsFaltantes(
  const AFaltantes: TArray<TScriptFaltante>): string;
var
  iIndice: Integer;
begin
  Result := SDetalleScriptsFaltantes;
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
    Result := Result + sLineBreak +
      Format(
        SLineaScriptFaltante,
        [AFaltantes[iIndice].Orden,
         AFaltantes[iIndice].Nombre,
         AFaltantes[iIndice].Objeto]);
end;

function TfrmModalActualizacion.DecidirScripts(
  const AFaltantes: TArray<TScriptFaltante>;
  AHayVersionNueva: Boolean):
  TDecisionScriptsActualizacion;
var
  sPregunta: string;
begin
  TfrmModalMensajeTexto.Mostrar(Self, TextoScriptsFaltantes(AFaltantes));
  // Sin versión nueva no hay que salir del programa al terminar, así que
  // no se advierte de ello.
  if AHayVersionNueva then
    sPregunta := SPreguntaAplicarScriptsAhora
  else
    sPregunta := SPreguntaAplicarScriptsAhoraMismaVersion;
  if MessageDlg_fza(
       Format(sPregunta, [Length(AFaltantes)]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes then
    Result := dsaAhora
  else
    Result := dsaAplazar;
end;

// La misma ventana que el generador de procesos: cronómetro, se puede
// apartar y enseña el script que se está ejecutando.
function TfrmModalActualizacion.CrearVentanaProceso(
  const ATitulo: string): IVentanaEspera;
begin
  Result := CrearVentanaProcesoSegundoPlano(
    Self.BoundsRect,
    Self.CurrentPPI,
    ATitulo);
end;

// La espera en movimiento de lo que tarda sin poder decir cuánto: mirar
// qué le falta a la base y las descargas. Vigila la ventana principal: si
// se minimiza el programa este modal se va con ella y la espera también,
// en vez de quedarse sola sobre el escritorio; al restaurarlo vuelven.
function TfrmModalActualizacion.CrearVentanaEsperaPantalla: IVentanaEspera;
begin
  Result := CrearVentanaEspera(
    Self.BoundsRect,
    Self.CurrentPPI,
    Application.MainFormHandle);
end;

function TfrmModalActualizacion.SolicitarCopiaPrevia(
  out ARutaCopia: string): Boolean;
begin
  ARutaCopia := '';
  Result := Assigned(FAnfitrion);
  if not Result then
    MessageDlg_fza(
      SErrorAnfitrionCopiaPreviaNoDisponible,
      mtError,
      [mbOk],
      0)
  else
  begin
    MessageDlg_fza(SAvisoCopiaPreviaObligatoria, mtInformation, [mbOk], 0);
    Result := FAnfitrion.CrearCopiaPreviaActualizacion(ARutaCopia);
  end;
end;

function TfrmModalActualizacion.TextoEstadoReversion(
  const AEstado: TEstadoActualizacion): string;
var
  iIndice: Integer;
begin
  Result := Format(
    SDetalleReversionActualizacion,
    [AEstado.VersionDestino,
     AEstado.VersionOrigen,
     AEstado.Instante,
     Length(AEstado.Ejecutables),
     Length(AEstado.Aplicados)]);
  for iIndice := Low(AEstado.Aplicados) to High(AEstado.Aplicados) do
    Result := Result + sLineBreak +
      Format(
        SLineaScriptRevertible,
        [AEstado.Aplicados[iIndice].Nombre,
         AEstado.Aplicados[iIndice].Resultado,
         AEstado.Aplicados[iIndice].RutaRollback]);
  if AEstado.RutaCopiaPrevia <> '' then
    Result := Result + sLineBreak + sLineBreak +
      Format(SLineaCopiaPreviaReversion, [AEstado.RutaCopiaPrevia]);
end;

function TfrmModalActualizacion.ConfirmarReversion(
  const AEstado: TEstadoActualizacion): Boolean;
begin
  TfrmModalMensajeTexto.Mostrar(Self, TextoEstadoReversion(AEstado));
  Result := MessageDlg_fza(
    Format(SPreguntaRevertirActualizacion, [AEstado.VersionOrigen]),
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
end;

function TfrmModalActualizacion.ConsultarRestaurarCopia(
  const ASinRollback: TArray<string>;
  const ARutaCopia: string): Boolean;
var
  iIndice: Integer;
  sTexto: string;
begin
  sTexto := SDetalleScriptsSinRollback;
  for iIndice := Low(ASinRollback) to High(ASinRollback) do
    sTexto := sTexto + sLineBreak + '  ' + ASinRollback[iIndice];
  TfrmModalMensajeTexto.Mostrar(Self, sTexto);
  Result := (Trim(ARutaCopia) <> '') and TFile.Exists(ARutaCopia) and
    (MessageDlg_fza(
       Format(SPreguntaRestaurarCopiaPrevia, [ARutaCopia]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes);
  if (Trim(ARutaCopia) = '') or not TFile.Exists(ARutaCopia) then
    MessageDlg_fza(
      SAvisoSinCopiaPreviaParaRevertir,
      mtWarning,
      [mbOk],
      0);
end;

function TfrmModalActualizacion.CrearInteraccion:
  TInteraccionActualizacion;
begin
  Result.Progreso := Progreso;
  Result.ConfirmarInstalacion := ConfirmarInstalacion;
  Result.DecidirScripts := DecidirScripts;
  Result.SolicitarCopiaPrevia := SolicitarCopiaPrevia;
  Result.ConfirmarReversion := ConfirmarReversion;
  Result.ConsultarRestaurarCopia := ConsultarRestaurarCopia;
  Result.CrearVentanaProceso := CrearVentanaProceso;
  Result.CrearVentanaEspera := CrearVentanaEsperaPantalla;
end;

procedure TfrmModalActualizacion.EjecutarProceso;
var
  Interaccion: TInteraccionActualizacion;
begin
  try
    Interaccion := CrearInteraccion;
    case FModo of
      mpaComprobar:
        FResultado := ComprobarEInstalarActualizacion(
          FContexto,
          Interaccion);
      mpaAplicarPendientes:
        FResultado := AplicarScriptsPendientesActualizacion(
          FContexto.Conexion,
          Interaccion);
      mpaRevertir:
        FResultado := RevertirActualizacion(FContexto, Interaccion);
    end;
    Progreso(SInfoProcesoActualizacionTerminado, 100);
  except
    on E: Exception do
    begin
      FResultado.Ok := False;
      FResultado.Mensaje := E.Message;
      RegistroLog.RegistrarError(
        'Actualización de la aplicación: ' + E.Message);
    end;
  end;
  FProcesando := False;
  if FResultado.Ok then
    ModalResult := mrOk
  else
    ModalResult := mrCancel;
end;

procedure TfrmModalActualizacion.FormCloseQuery(
  Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not FProcesando;
end;

procedure TfrmModalActualizacion.FormShow(Sender: TObject);
begin
  if not FIniciado then
  begin
    FIniciado := True;
    if FModo = mpaRevertir then
      Caption := STituloRevertirActualizacion
    else
      Caption := STituloComprobarActualizaciones;
    lblTitulo.Caption := Caption;
    PostMessage(Handle, cMensajeEjecutarActualizacion, 0, 0);
  end;
end;

procedure TfrmModalActualizacion.MensajeEjecutarActualizacion(
  var AMensaje: TMessage);
begin
  EjecutarProceso;
end;

end.
