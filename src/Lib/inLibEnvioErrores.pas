{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEnvioErrores                                             }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara las evidencias y envía incidencias al servicio central.           }
{******************************************************************************}
unit inLibEnvioErrores;

interface

uses
  inLibContextoSesionIntf,
  inLibCopiasSeguridadIntf,
  inLibEnvioErroresIntf,
  inLibLogIntf,
  inLibParametrosIntf;

function CrearServicioEnvioErrores(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const ARepositorioCopias: IRepositorioCopiasSeguridad
): IServicioEnvioErrores;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.Mime,
  System.SysUtils,
  System.Zip,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  inLibFactuzamApi,
  inLibGlobalVar,
  inLibLicenciaAplicacion,
  inLibMsgComun,
  inLibWin;

const
  cUrlEnvioErroresDefecto =
    'https://webservice.veryverifactu.com/error.php';
  cMaximoLogAdjunto = 8 * 1024 * 1024;
  cMaximoCopiaAdjunta = 200 * 1024 * 1024;
  cPrintWindowContenidoCompleto = 2;

type
  TServicioEnvioErrores = class(
    TInterfacedObject,
    IServicioEnvioErrores)
  private
    FContextoSesion: IContextoSesionAplicacion;
    FParametros: IParametrosAplicacion;
    FRegistroLog: IRegistroLog;
    FRepositorioCopias: IRepositorioCopiasSeguridad;
    function CapturarPantallazo: string;
    function CopiarLogReciente(const ARutaOrigen: string): string;
    function CrearRutaTemporal(const AExtension: string): string;
    function LeerRespuesta(const AContenido: string;
      AEstadoHttp: Integer): TResultadoEnvioError;
    function UrlEnvio: string;
    procedure AnadirCampos(
      AFormulario: TMultipartFormData;
      const AEvidencia: TEvidenciaError;
      const AContacto: TContactoError);
    procedure AnadirArchivos(
      AFormulario: TMultipartFormData;
      const AEvidencia: TEvidenciaError);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametros: IParametrosAplicacion;
      const ARegistroLog: IRegistroLog;
      const ARepositorioCopias: IRepositorioCopiasSeguridad);
    function Preparar(
      const AClaseError, AMensajeError,
      ADetalleError: string): TEvidenciaError;
    function Enviar(
      const AEvidencia: TEvidenciaError;
      const AContacto: TContactoError): TResultadoEnvioError;
    function PrepararCopiaSeguridad(
      var AEvidencia: TEvidenciaError;
      const AContrasena: string;
      out AError: string): Boolean;
    procedure DescartarCopiaSeguridad(
      var AEvidencia: TEvidenciaError);
    procedure ActivarDiagnosticoCompleto;
    procedure Limpiar(var AEvidencia: TEvidenciaError);
  end;

function ImprimirVentana(
  AVentana: HWND;
  ADC: HDC;
  AOpciones: UINT): BOOL; stdcall;
  external user32 name 'PrintWindow';

function CrearServicioEnvioErrores(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const ARepositorioCopias: IRepositorioCopiasSeguridad
): IServicioEnvioErrores;
begin
  Result := TServicioEnvioErrores.Create(
    AContextoSesion,
    AParametros,
    ARegistroLog,
    ARepositorioCopias);
end;

constructor TServicioEnvioErrores.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const ARepositorioCopias: IRepositorioCopiasSeguridad);
begin
  inherited Create;
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametros) then
    raise EArgumentNilException.Create('AParametros');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  if not Assigned(ARepositorioCopias) then
    raise EArgumentNilException.Create('ARepositorioCopias');
  FContextoSesion := AContextoSesion;
  FParametros := AParametros;
  FRegistroLog := ARegistroLog;
  FRepositorioCopias := ARepositorioCopias;
end;

function TServicioEnvioErrores.CrearRutaTemporal(
  const AExtension: string): string;
var
  Identificador: TGUID;
  sIdentificador: string;
begin
  CreateGUID(Identificador);
  sIdentificador := GUIDToString(Identificador);
  sIdentificador := StringReplace(
    sIdentificador,
    '{',
    '',
    [rfReplaceAll]);
  sIdentificador := StringReplace(
    sIdentificador,
    '}',
    '',
    [rfReplaceAll]);
  Result := TPath.Combine(
    TPath.GetTempPath,
    'Factuzam_Error_' + sIdentificador + AExtension);
end;

function TServicioEnvioErrores.CapturarPantallazo: string;
var
  Bitmap: TBitmap;
  DCVentana: HDC;
  Formulario: TCustomForm;
  Png: TPngImage;
  Rectangulo: TRect;
  bCapturado: Boolean;
begin
  Result := '';
  Formulario := Application.MainForm;
  if Assigned(Formulario) and
     IsWindow(Formulario.Handle) and
     GetWindowRect(Formulario.Handle, Rectangulo) then
  begin
    Bitmap := TBitmap.Create;
    Png := TPngImage.Create;
    try
      Bitmap.PixelFormat := pf24bit;
      Bitmap.SetSize(
        Rectangulo.Right - Rectangulo.Left,
        Rectangulo.Bottom - Rectangulo.Top);
      bCapturado := ImprimirVentana(
        Formulario.Handle,
        Bitmap.Canvas.Handle,
        cPrintWindowContenidoCompleto);
      if not bCapturado then
      begin
        DCVentana := GetDC(0);
        try
          bCapturado := BitBlt(
            Bitmap.Canvas.Handle,
            0,
            0,
            Bitmap.Width,
            Bitmap.Height,
            DCVentana,
            Rectangulo.Left,
            Rectangulo.Top,
            SRCCOPY);
        finally
          ReleaseDC(0, DCVentana);
        end;
      end;
      if bCapturado then
      begin
        Result := CrearRutaTemporal('.png');
        Png.Assign(Bitmap);
        Png.SaveToFile(Result);
      end;
    finally
      FreeAndNil(Png);
      FreeAndNil(Bitmap);
    end;
  end;
end;

function TServicioEnvioErrores.CopiarLogReciente(
  const ARutaOrigen: string): string;
var
  FlujoDestino: TFileStream;
  FlujoOrigen: TFileStream;
  iBytes: Int64;
begin
  Result := '';
  if FileExists(ARutaOrigen) then
  begin
    Result := CrearRutaTemporal('.log');
    FlujoOrigen := TFileStream.Create(
      ARutaOrigen,
      fmOpenRead or fmShareDenyNone);
    try
      FlujoDestino := TFileStream.Create(Result, fmCreate);
      try
        iBytes := FlujoOrigen.Size;
        if iBytes > cMaximoLogAdjunto then
        begin
          FlujoOrigen.Position :=
            FlujoOrigen.Size - cMaximoLogAdjunto;
          iBytes := cMaximoLogAdjunto;
        end;
        FlujoDestino.CopyFrom(FlujoOrigen, iBytes);
      finally
        FreeAndNil(FlujoDestino);
      end;
    finally
      FreeAndNil(FlujoOrigen);
    end;
  end;
end;

function TServicioEnvioErrores.Preparar(
  const AClaseError, AMensajeError,
  ADetalleError: string): TEvidenciaError;
begin
  Result.ClaseError := AClaseError;
  Result.MensajeError := AMensajeError;
  Result.DetalleError := ADetalleError;
  Result.RutaPantallazo := '';
  Result.RutaLog := '';
  Result.RutaCopiaSeguridad := '';
  Result.Log := FRegistroLog.ObtenerEvidencias;
  try
    Result.RutaPantallazo := CapturarPantallazo;
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo preparar el pantallazo del error: ' +
        E.Message);
  end;
  try
    Result.RutaLog := CopiarLogReciente(
      Result.Log.RutaArchivo);
  except
    on E: Exception do
      FRegistroLog.RegistrarAviso(
        'No se pudo preparar el LOG del error: ' + E.Message);
  end;
end;

function TServicioEnvioErrores.PrepararCopiaSeguridad(
  var AEvidencia: TEvidenciaError;
  const AContrasena: string;
  out AError: string): Boolean;
var
  ResultadoCopia: TResultadoCopiaSeguridad;
  RutaCifrada: string;
  RutaZip: string;
  Zip: TZipFile;
begin
  Result := False;
  AError := '';
  RutaCifrada := '';
  RutaZip := '';
  try
    RutaCifrada := CrearRutaTemporal('.crypt');
    RutaZip := CrearRutaTemporal('.zip');
    ResultadoCopia := FRepositorioCopias.CrearCopiaProtegida(
      RutaCifrada,
      AContrasena,
      nil,
      AError);
    if ResultadoCopia = rcsCompletada then
    begin
      Zip := TZipFile.Create;
      try
        Zip.Open(RutaZip, zmWrite);
        Zip.Add(
          RutaCifrada,
          'copia_seguridad_factuzam.crypt');
        Zip.Close;
      finally
        FreeAndNil(Zip);
      end;
      if TFile.GetSize(RutaZip) > cMaximoCopiaAdjunta then
      begin
        AError := Format(
          'La copia supera el límite de %d MiB.',
          [cMaximoCopiaAdjunta div 1024 div 1024]);
      end
      else
      begin
        DescartarCopiaSeguridad(AEvidencia);
        AEvidencia.RutaCopiaSeguridad := RutaZip;
        RutaZip := '';
        Result := True;
      end;
    end
    else if AError = '' then
      AError := 'No se pudo crear la copia de seguridad protegida.';
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
  if (RutaCifrada <> '') and FileExists(RutaCifrada) then
    DeleteFile(RutaCifrada);
  if (RutaZip <> '') and FileExists(RutaZip) then
    DeleteFile(RutaZip);
end;

function BooleanoServicio(AValor: Boolean): string;
begin
  if AValor then
    Result := 'S'
  else
    Result := 'N';
end;

function EstadoLicenciaServicio(
  AEstado: TEstadoLicenciaAplicacion): string;
begin
  case AEstado of
    elaValida:
      Result := 'VALIDA';
    elaInvalida:
      Result := 'INVALIDA';
    elaNoEncontrada:
      Result := 'NO_ENCONTRADA';
    elaSinNifEmpresa:
      Result := 'SIN_NIF_EMPRESA';
  else
    Result := 'DESCONOCIDA';
  end;
end;

procedure TServicioEnvioErrores.AnadirCampos(
  AFormulario: TMultipartFormData;
  const AEvidencia: TEvidenciaError;
  const AContacto: TContactoError);
var
  bCopiaSeguridad: Boolean;
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  bCopiaSeguridad := FileExists(
    AEvidencia.RutaCopiaSeguridad);
  Identidad := FContextoSesion.Identidad;
  Ubicacion := FContextoSesion.Ubicacion;
  AFormulario.AddField('version', oVersion);
  AFormulario.AddField('aplicacion', oAppName);
  AFormulario.AddField(
    'referencia_cliente',
    TClienteFactuzamApi.Referencia(FParametros));
  AFormulario.AddField('usuario', Identidad.Usuario);
  AFormulario.AddField('grupo', Identidad.Grupo);
  AFormulario.AddField('empresa', Ubicacion.Empresa);
  AFormulario.AddField('almacen', Ubicacion.Almacen);
  AFormulario.AddField('caja', Ubicacion.Caja);
  AFormulario.AddField('equipo', GetComputerName);
  if EstadoLicenciaEsDemo(FParametros.Licencia.Estado) then
    AFormulario.AddField('modo_licencia', 'DEMO')
  else
    AFormulario.AddField('modo_licencia', 'REGISTRADA');
  AFormulario.AddField(
    'estado_licencia',
    EstadoLicenciaServicio(FParametros.Licencia.Estado));
  AFormulario.AddField('email', Trim(AContacto.Email));
  AFormulario.AddField('telefono', Trim(AContacto.Telefono));
  AFormulario.AddField('descripcion', AContacto.Descripcion);
  AFormulario.AddField('clase_error', AEvidencia.ClaseError);
  AFormulario.AddField('mensaje_error', AEvidencia.MensajeError);
  AFormulario.AddField('detalle_error', AEvidencia.DetalleError);
  if bCopiaSeguridad then
  begin
    AFormulario.AddField('tipo_evidencia', 'COPIA_SEGURIDAD');
    AFormulario.AddField('log_sql', 'N');
    AFormulario.AddField('log_rendimiento', 'N');
    AFormulario.AddField('log_avanzado', 'N');
    AFormulario.AddField('log_completo', 'N');
  end
  else
  begin
    AFormulario.AddField('tipo_evidencia', 'LOG');
    AFormulario.AddField(
      'log_sql',
      BooleanoServicio(AEvidencia.Log.SQLActivo));
    AFormulario.AddField(
      'log_rendimiento',
      BooleanoServicio(AEvidencia.Log.RendimientoActivo));
    AFormulario.AddField(
      'log_avanzado',
      BooleanoServicio(AEvidencia.Log.AvanzadoActivo));
    AFormulario.AddField(
      'log_completo',
      BooleanoServicio(AEvidencia.Log.Completo));
  end;
end;

procedure TServicioEnvioErrores.AnadirArchivos(
  AFormulario: TMultipartFormData;
  const AEvidencia: TEvidenciaError);
begin
  if FileExists(AEvidencia.RutaPantallazo) then
  begin
    AFormulario.AddFile(
      'pantallazo',
      AEvidencia.RutaPantallazo,
      'image/png');
  end;
  if FileExists(AEvidencia.RutaCopiaSeguridad) then
  begin
    AFormulario.AddFile(
      'copia_seguridad',
      AEvidencia.RutaCopiaSeguridad,
      'application/zip');
  end
  else if FileExists(AEvidencia.RutaLog) then
  begin
    AFormulario.AddFile(
      'log',
      AEvidencia.RutaLog,
      'text/plain');
  end;
end;

function JsonTexto(
  AJson: TJSONObject;
  const ANombre: string): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  Valor := AJson.GetValue(ANombre);
  if Valor is TJSONString then
    Result := Valor.Value;
end;

function TServicioEnvioErrores.LeerRespuesta(
  const AContenido: string;
  AEstadoHttp: Integer): TResultadoEnvioError;
var
  Json: TJSONObject;
  Valor: TJSONValue;
begin
  Result.Ok := (AEstadoHttp >= 200) and
               (AEstadoHttp < 300);
  Result.EstadoHttp := AEstadoHttp;
  Result.Referencia := '';
  Result.TokenSeguimiento := '';
  Result.UrlSeguimiento := '';
  Result.Mensaje := Format(
    SErrorRespuestaEnvioError,
    [AEstadoHttp]);
  Valor := TJSONObject.ParseJSONValue(AContenido);
  if Valor is TJSONObject then
  begin
    Json := TJSONObject(Valor);
    try
      Result.Referencia := JsonTexto(Json, 'referencia');
      Result.TokenSeguimiento :=
        JsonTexto(Json, 'token_seguimiento');
      Result.UrlSeguimiento :=
        JsonTexto(Json, 'url_seguimiento');
      if JsonTexto(Json, 'message') <> '' then
        Result.Mensaje := JsonTexto(Json, 'message');
    finally
      FreeAndNil(Json);
    end;
  end
  else
    FreeAndNil(Valor);
end;

function TServicioEnvioErrores.UrlEnvio: string;
begin
  Result := Trim(FParametros.GetString('appErroresUrl', ''));
  if Result = '' then
    Result := cUrlEnvioErroresDefecto;
end;

function TServicioEnvioErrores.Enviar(
  const AEvidencia: TEvidenciaError;
  const AContacto: TContactoError): TResultadoEnvioError;
var
  Formulario: TMultipartFormData;
  Http: THTTPClient;
  Respuesta: TStringStream;
  ResultadoHttp: IHTTPResponse;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Referencia := '';
  Result.TokenSeguimiento := '';
  Result.UrlSeguimiento := '';
  Result.Mensaje := SErrorNoSePudoEnviarError;
  if EmailSoporteValido(AContacto.Email) and
     TelefonoSoporteValido(AContacto.Telefono) then
  begin
    Http := THTTPClient.Create;
    Formulario := TMultipartFormData.Create;
    Respuesta := TStringStream.Create('', TEncoding.UTF8);
    try
      try
        Http.ConnectionTimeout := 15000;
        if FileExists(AEvidencia.RutaCopiaSeguridad) then
          Http.ResponseTimeout := 600000
        else
          Http.ResponseTimeout := 60000;
        Http.CustomHeaders['User-Agent'] :=
          oAppName + '/' + oVersion;
        AnadirCampos(Formulario, AEvidencia, AContacto);
        AnadirArchivos(Formulario, AEvidencia);
        ResultadoHttp := Http.Post(
          UrlEnvio,
          Formulario,
          Respuesta);
        Result := LeerRespuesta(
          Respuesta.DataString,
          ResultadoHttp.StatusCode);
      except
        on E: Exception do
          Result.Mensaje := E.Message;
      end;
    finally
      FreeAndNil(Respuesta);
      FreeAndNil(Formulario);
      FreeAndNil(Http);
    end;
  end
  else
    Result.Mensaje := SErrorContactoEnvioErrorNoValido;
end;

procedure TServicioEnvioErrores.ActivarDiagnosticoCompleto;
begin
  FRegistroLog.ActivarDiagnosticoCompleto;
end;

procedure BorrarTemporal(const ARuta: string);
begin
  if (ARuta <> '') and FileExists(ARuta) then
    DeleteFile(ARuta);
end;

procedure TServicioEnvioErrores.DescartarCopiaSeguridad(
  var AEvidencia: TEvidenciaError);
begin
  BorrarTemporal(AEvidencia.RutaCopiaSeguridad);
  AEvidencia.RutaCopiaSeguridad := '';
end;

procedure TServicioEnvioErrores.Limpiar(
  var AEvidencia: TEvidenciaError);
begin
  BorrarTemporal(AEvidencia.RutaPantallazo);
  BorrarTemporal(AEvidencia.RutaLog);
  DescartarCopiaSeguridad(AEvidencia);
  AEvidencia.RutaPantallazo := '';
  AEvidencia.RutaLog := '';
end;

end.
