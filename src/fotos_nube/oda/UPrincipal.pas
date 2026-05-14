unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.NetEncoding, System.Hash, System.SyncObjs,
  System.Generics.Collections, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Mask, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  System.Net.HttpClient, System.Net.URLClient, System.Net.Mime,
  // UniDAC
  Uni, UniProvider, SQLServerUniProvider, DBAccess,
  // OmniThreadLibrary
  OtlCommon, OtlTask, OtlTaskControl, OtlParallel, OtlSync,
  // Worker
  UFotoUploader;

type
  TFotoJob = record
    Articulo : string;
    Color    : string;
    Indice   : Integer;
    Archivo  : string;     // ruta sin prefijo, tal cual viene de la BD
    SHA1     : string;     // SHA1 del archivo LOCAL (ya calculado)
  end;

  TJobList = TList<TFotoJob>;

  TForm1 = class(TForm)
    pcMain: TPageControl;
    tsSubir: TTabSheet;
    tsVer: TTabSheet;
    tsBatch: TTabSheet;

    // --- Pestaña Subir ---
    edUrl: TLabeledEdit;
    edKey: TLabeledEdit;
    edCarpetaCliente: TLabeledEdit;
    edNombre: TLabeledEdit;
    edArchivo: TLabeledEdit;
    btnSel: TButton;
    btnSubir: TButton;
    mLogs: TMemo;

    // --- Pestaña Ver ---
    edUrlVer: TLabeledEdit;
    edKeyVer: TLabeledEdit;
    edCarpetaClienteVer: TLabeledEdit;
    edNombreVer: TLabeledEdit;
    cbResolucion: TComboBox;
    lblResolucion: TLabel;
    btnVer: TButton;
    imgFoto: TImage;
    mLogsVer: TMemo;

    // --- Pestaña Batch ---
    edUrlBatch: TLabeledEdit;
    edUrlListBatch: TLabeledEdit;
    edKeyBatch: TLabeledEdit;
    edCarpetaClienteBatch: TLabeledEdit;
    edPrefijoLocal: TLabeledEdit;
    edSqlServer: TLabeledEdit;
    edSqlDatabase: TLabeledEdit;
    edSqlUser: TLabeledEdit;
    edSqlPassword: TLabeledEdit;
    chkSqlWindowsAuth: TCheckBox;
    lblConcurrencia: TLabel;
    cbConcurrencia: TComboBox;
    btnLanzar: TButton;
    btnCancelar: TButton;
    pbBatch: TProgressBar;
    lblBatchStatus: TLabel;
    mLogsBatch: TMemo;

    procedure btnSelClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnVerClick(Sender: TObject);
    procedure btnLanzarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure HTTPValidateServerCertificate(const Sender: TObject;
      const ARequest: TURLRequest; const Certificate: TCertificate;
      var Accepted: Boolean);
  private
    FBatchJobs    : TJobList;       // solo lo que toca subir
    FBatchCancel  : IOmniCancellationToken;
    FBatchTotal   : Integer;
    FBatchOK      : Integer;
    FBatchSkipped : Integer;        // contadas en pre-filtrado
    FBatchError   : Integer;
    FBatchRunning : Boolean;
    procedure LogBatch(const S: string);
    procedure ActualizarProgreso;
    procedure ProcesarResultado(const R: TFotoUploadResult);
    procedure BatchTerminado;
    function ObtenerInventarioServidor(const Url, ApiKey, Carpeta: string;
                                       Inv: TDictionary<string,string>;
                                       out ErrorMsg: string): Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// ----------------------------------------------------------------------
procedure TForm1.HTTPValidateServerCertificate(const Sender: TObject;
  const ARequest: TURLRequest; const Certificate: TCertificate;
  var Accepted: Boolean);
begin
  Accepted := True;
end;

// ----------------------------------------------------------------------
procedure TForm1.FormCreate(Sender: TObject);
begin
  cbConcurrencia.Items.Clear;
  cbConcurrencia.Items.Add('5');
  cbConcurrencia.Items.Add('10');
  cbConcurrencia.Items.Add('15');
  cbConcurrencia.Items.Add('20');
  cbConcurrencia.ItemIndex := 0;

  btnCancelar.Enabled := False;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBatchRunning then
  begin
    if MessageDlg('Hay una subida masiva en curso. ¿Cancelar y salir?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if Assigned(FBatchCancel) then
        FBatchCancel.Signal;
      while FBatchRunning do
      begin
        Sleep(50);
        Application.ProcessMessages;
      end;
      CanClose := True;
    end
    else
      CanClose := False;
  end
  else
    CanClose := True;

  if CanClose then
    FreeAndNil(FBatchJobs);
end;

// ----------------------------------------------------------------------
// Pestaña SUBIR (sin cambios)
// ----------------------------------------------------------------------
procedure TForm1.btnSelClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Filter :=
      'Imágenes (*.jpg;*.jpeg;*.png;*.gif;*.webp)|*.jpg;*.jpeg;*.png;*.gif;*.webp|' +
      'Todos los archivos (*.*)|*.*';
    if OpenDlg.Execute then
      edArchivo.Text := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

procedure TForm1.btnSubirClick(Sender: TObject);
var
  HTTP: THTTPClient;
  Form: TMultipartFormData;
  Res: IHTTPResponse;
  Response: TStringStream;
begin
  if not FileExists(edArchivo.Text) then
  begin
    mLogs.Lines.Add('Archivo no existe: ' + edArchivo.Text);
    Exit;
  end;
  if Trim(edCarpetaCliente.Text) = '' then
  begin
    mLogs.Lines.Add('Falta la carpeta_cliente.');
    Exit;
  end;
  if Trim(edNombre.Text) = '' then
  begin
    mLogs.Lines.Add('Falta el nombre.');
    Exit;
  end;

  HTTP := THTTPClient.Create;
  Form := TMultipartFormData.Create;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key'] := edKey.Text;

    Form.AddField('nombre',          edNombre.Text);
    Form.AddField('carpeta_cliente', edCarpetaCliente.Text);
    Form.AddFile ('imagen',          edArchivo.Text);

    mLogs.Lines.Add('POST ' + edUrl.Text);
    Res := HTTP.Post(edUrl.Text, Form, Response);

    mLogs.Lines.Add(Format('HTTP %d %s', [Res.StatusCode, Res.StatusText]));
    mLogs.Lines.Add('--- Respuesta ---');
    mLogs.Lines.Add(Response.DataString);
    mLogs.Lines.Add('');
  finally
    Response.Free;
    Form.Free;
    HTTP.Free;
  end;
end;

// ----------------------------------------------------------------------
// Pestaña VER (sin cambios)
// ----------------------------------------------------------------------
procedure TForm1.btnVerClick(Sender: TObject);

  function CalcularSHA1Stream(Stream: TStream): string;
  const
    BUFFER_SIZE = 64 * 1024;
  var
    Hash: THashSHA1;
    Buffer: TBytes;
    BytesRead: Integer;
  begin
    Hash := THashSHA1.Create;
    SetLength(Buffer, BUFFER_SIZE);
    Stream.Position := 0;
    repeat
      BytesRead := Stream.Read(Buffer[0], BUFFER_SIZE);
      if BytesRead > 0 then
        Hash.Update(Buffer[0], BytesRead);
    until BytesRead = 0;
    Result := Hash.HashAsString;
  end;

var
  HTTP: THTTPClient;
  Res: IHTTPResponse;
  Stream: TMemoryStream;
  ErrStream: TStringStream;
  PNG: TPngImage;
  Url, Nombre, Resolucion, Carpeta: string;
  HashLocal, HashServer: string;
begin
  Nombre     := Trim(edNombreVer.Text);
  Resolucion := Trim(cbResolucion.Text);
  Carpeta    := Trim(edCarpetaClienteVer.Text);

  if (Nombre = '') or (Resolucion = '') or (Carpeta = '') then
  begin
    mLogsVer.Lines.Add('Falta nombre, resolución o carpeta_cliente.');
    Exit;
  end;

  Url := edUrlVer.Text +
         '?nombre='          + TNetEncoding.URL.Encode(Nombre) +
         '&resolucion='      + TNetEncoding.URL.Encode(Resolucion) +
         '&carpeta_cliente=' + TNetEncoding.URL.Encode(Carpeta);

  HTTP   := THTTPClient.Create;
  Stream := TMemoryStream.Create;
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := edKeyVer.Text;

    mLogsVer.Lines.Add('GET ' + Url);
    Res := HTTP.Get(Url, Stream);
    mLogsVer.Lines.Add(Format('HTTP %d %s', [Res.StatusCode, Res.StatusText]));

    if Res.StatusCode <> 200 then
    begin
      Stream.Position := 0;
      ErrStream := TStringStream.Create('', TEncoding.UTF8);
      try
        ErrStream.CopyFrom(Stream, 0);
        mLogsVer.Lines.Add('Respuesta: ' + ErrStream.DataString);
      finally
        ErrStream.Free;
      end;
      Exit;
    end;

    HashServer := LowerCase(Trim(Res.HeaderValue['X-Content-SHA1']));
    if HashServer <> '' then
    begin
      HashLocal := LowerCase(CalcularSHA1Stream(Stream));
      if HashLocal <> HashServer then
      begin
        mLogsVer.Lines.Add('¡SHA1 no coincide! Imagen corrupta o alterada.');
        Exit;
      end;
      mLogsVer.Lines.Add('SHA1 verificado: ' + HashServer);
    end;

    Stream.Position := 0;
    PNG := TPngImage.Create;
    try
      PNG.LoadFromStream(Stream);
      imgFoto.Picture.Assign(PNG);
    finally
      PNG.Free;
    end;

    mLogsVer.Lines.Add('Imagen cargada correctamente.');
    mLogsVer.Lines.Add('');
  finally
    Stream.Free;
    HTTP.Free;
  end;
end;

// ----------------------------------------------------------------------
// Pestaña BATCH
// ----------------------------------------------------------------------

procedure TForm1.LogBatch(const S: string);
begin
  mLogsBatch.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

procedure TForm1.ActualizarProgreso;
var
  Hecho: Integer;
begin
  Hecho := FBatchOK + FBatchError;
  pbBatch.Position := Hecho;
  lblBatchStatus.Caption := Format(
    'Subidas %d/%d  |  OK: %d  |  Errores: %d  |  Saltadas previas: %d',
    [Hecho, FBatchTotal, FBatchOK, FBatchError, FBatchSkipped]);
end;

procedure TForm1.ProcesarResultado(const R: TFotoUploadResult);
var
  Linea: string;
begin
  case R.Status of
    fusOK:    Inc(FBatchOK);
    fusError: Inc(FBatchError);
  end;

  case R.Status of
    fusOK:
      Linea := Format('[OK]   %s / %s #%d  %s',
                      [R.Articulo, R.Color, R.Indice, R.Archivo]);
    fusError:
      Linea := Format('[ERR]  %s / %s #%d  %s  ->  %s',
                      [R.Articulo, R.Color, R.Indice, R.Archivo, R.Mensaje]);
  end;

  LogBatch(Linea);
  ActualizarProgreso;
end;

procedure TForm1.BatchTerminado;
begin
  LogBatch(Format(
    '== FIN ==  OK: %d   Errores: %d   (Saltadas en pre-filtro: %d)   Total subidas intentadas: %d',
    [FBatchOK, FBatchError, FBatchSkipped, FBatchTotal]));
  btnLanzar.Enabled   := True;
  btnCancelar.Enabled := False;
  FBatchRunning       := False;
  FBatchCancel        := nil;
  FreeAndNil(FBatchJobs);
end;

// ----------------------------------------------------------------------
// Llama a listar_fotos.php y devuelve un diccionario:
//   nombre (p.ej. "A1234_ROJO_1")  ->  osha1 (SHA1 del archivo local
//   original con que se subió, vacío si no se registró).
// Solo nos interesa el osha1 para decidir si saltar o no.
// ----------------------------------------------------------------------
function TForm1.ObtenerInventarioServidor(
  const Url, ApiKey, Carpeta: string;
  Inv: TDictionary<string,string>;
  out ErrorMsg: string): Boolean;
var
  HTTP    : THTTPClient;
  Res     : IHTTPResponse;
  Stream  : TStringStream;
  FullUrl : string;
  Root    : TJSONObject;
  Fotos   : TJSONArray;
  Item    : TJSONValue;
  Obj     : TJSONObject;
  V       : TJSONValue;
  Nombre  : string;
  OSha1   : string;
begin
  Result   := False;
  ErrorMsg := '';

  FullUrl := Url + '?carpeta_cliente=' + TNetEncoding.URL.Encode(Carpeta);

  HTTP   := THTTPClient.Create;
  Stream := TStringStream.Create('', TEncoding.UTF8);
  try
    HTTP.OnValidateServerCertificate := HTTPValidateServerCertificate;
    HTTP.CustomHeaders['X-API-Key']  := ApiKey;
    HTTP.ConnectionTimeout := 15000;
    HTTP.ResponseTimeout   := 60000;

    try
      Res := HTTP.Get(FullUrl, Stream);
    except
      on E: Exception do
      begin
        ErrorMsg := E.Message;
        Exit;
      end;
    end;

    if Res.StatusCode <> 200 then
    begin
      ErrorMsg := Format('HTTP %d: %s',
                  [Res.StatusCode, Copy(Stream.DataString, 1, 300)]);
      Exit;
    end;

    Root := TJSONObject.ParseJSONValue(Stream.DataString) as TJSONObject;
    if Root = nil then
    begin
      ErrorMsg := 'JSON inválido';
      Exit;
    end;
    try
      V := Root.GetValue('fotos');
      if not (V is TJSONArray) then
      begin
        ErrorMsg := 'Sin array "fotos"';
        Exit;
      end;
      Fotos := TJSONArray(V);
      for Item in Fotos do
      begin
        if not (Item is TJSONObject) then Continue;
        Obj := TJSONObject(Item);

        V := Obj.GetValue('nombre');
        if V = nil then Continue;
        Nombre := V.Value;

        OSha1 := '';
        V := Obj.GetValue('osha1');
        if V <> nil then
          OSha1 := LowerCase(V.Value);

        Inv.AddOrSetValue(Nombre, OSha1);
      end;
      Result := True;
    finally
      Root.Free;
    end;
  finally
    Stream.Free;
    HTTP.Free;
  end;
end;

procedure TForm1.btnLanzarClick(Sender: TObject);
var
  Conn       : TUniConnection;
  Query      : TUniQuery;
  Job        : TFotoJob;
  Cfg        : TFotoUploadConfig;
  N          : Integer;
  Total      : Integer;
  Inventario : TDictionary<string,string>;
  ErrorMsg   : string;
  Nombre     : string;
  Archivo    : string;
  OSha1Srv   : string;
  SHA1Local  : string;
  TotalSql   : Integer;
  Faltantes  : Integer;
  Saltadas   : Integer;
  NoExisten  : Integer;
begin
  if FBatchRunning then
  begin
    LogBatch('Ya hay una subida en curso.');
    Exit;
  end;

  // ---- Validar parámetros ----
  Cfg.UrlUpload      := Trim(edUrlBatch.Text);
  Cfg.ApiKey         := Trim(edKeyBatch.Text);
  Cfg.CarpetaCliente := Trim(edCarpetaClienteBatch.Text);
  Cfg.PrefijoLocal   := Trim(edPrefijoLocal.Text);

  if (Cfg.UrlUpload = '') or (Trim(edUrlListBatch.Text) = '') or
     (Cfg.CarpetaCliente = '') or (Cfg.PrefijoLocal = '') then
  begin
    LogBatch('Faltan parámetros de configuración.');
    Exit;
  end;

  N := StrToIntDef(cbConcurrencia.Text, 5);
  if N < 1 then N := 1;
  if N > 50 then N := 50;

  mLogsBatch.Clear;
  FBatchOK      := 0;
  FBatchSkipped := 0;
  FBatchError   := 0;
  FBatchTotal   := 0;

  // ----------------------------------------------------------
  // PASO 1: inventario del servidor
  // ----------------------------------------------------------
  LogBatch('Pidiendo inventario al servidor...');
  Inventario := TDictionary<string,string>.Create;
  try
    if not ObtenerInventarioServidor(Trim(edUrlListBatch.Text),
                                     Cfg.ApiKey,
                                     Cfg.CarpetaCliente,
                                     Inventario,
                                     ErrorMsg) then
    begin
      LogBatch('No se pudo obtener inventario: ' + ErrorMsg);
      LogBatch('Abortando para no resubir lo que pueda ya existir.');
      Inventario.Free;
      Exit;
    end;
    LogBatch(Format('Inventario: %d fotos en servidor.', [Inventario.Count]));

    // ----------------------------------------------------------
    // PASO 2: SELECT en SQL Server
    // ----------------------------------------------------------
    FreeAndNil(FBatchJobs);
    FBatchJobs := TJobList.Create;

    Conn  := TUniConnection.Create(nil);
    Query := TUniQuery.Create(nil);
    try
      Conn.ProviderName := 'SQL Server';
      Conn.Server       := Trim(edSqlServer.Text);
      Conn.Database     := Trim(edSqlDatabase.Text);
      if chkSqlWindowsAuth.Checked then
        Conn.SpecificOptions.Values['AuthenticationType'] := 'auWindows'
      else
      begin
        Conn.Username := Trim(edSqlUser.Text);
        Conn.Password := edSqlPassword.Text;
      end;

      LogBatch('Conectando a SQL Server...');
      try
        Conn.Connect;
      except
        on E: Exception do
        begin
          LogBatch('Error conectando: ' + E.Message);
          FreeAndNil(FBatchJobs);
          Exit;
        end;
      end;

      Query.Connection := Conn;
      Query.SQL.Text :=
        'SELECT articulo, color, ArchivoFoto ' +
        'FROM ocartcol ' +
        'WHERE ArchivoFoto IS NOT NULL AND ArchivoFoto <> '''' ' +
        '  AND articulo IN (SELECT articulo FROM ocartacp WHERE UnidadesStock > 0)';
      try
        Query.Open;
      except
        on E: Exception do
        begin
          LogBatch('Error en SELECT: ' + E.Message);
          FreeAndNil(FBatchJobs);
          Exit;
        end;
      end;

      // ----------------------------------------------------------
      // PASO 3: filtrar contra el inventario
      // ----------------------------------------------------------
      TotalSql  := 0;
      Saltadas  := 0;
      NoExisten := 0;
      Faltantes := 0;

      while not Query.Eof do
      begin
        Inc(TotalSql);

        Job.Articulo := Trim(Query.FieldByName('articulo').AsString);
        Job.Color    := Trim(Query.FieldByName('color').AsString);
        Job.Indice   := 1;
        Job.Archivo  := Trim(Query.FieldByName('ArchivoFoto').AsString);

        if (Job.Articulo = '') or (Job.Color = '') or (Job.Archivo = '') then
        begin
          Query.Next;
          Continue;
        end;

        // Nombre interno que tendrá en el servidor
        Nombre := Job.Articulo + '_' + Job.Color + '_' + IntToStr(Job.Indice);

        // Ruta local con prefijo
        Archivo := Cfg.PrefijoLocal;
        if (Archivo <> '') and (Archivo[Length(Archivo)] <> PathDelim) then
          Archivo := Archivo + PathDelim;
        Archivo := Archivo + Job.Archivo;

        if not FileExists(Archivo) then
        begin
          Inc(NoExisten);
          LogBatch('[!] Falta local: ' + Archivo);
          Query.Next;
          Continue;
        end;

        // SHA1 del archivo local actual
        try
          SHA1Local := CalcularSHA1Archivo(Archivo);
        except
          on E: Exception do
          begin
            LogBatch('[!] Error SHA1 local de ' + Archivo + ': ' + E.Message);
            Inc(FBatchError);
            Query.Next;
            Continue;
          end;
        end;

        // ¿Está ya en el servidor con el mismo SHA1 de origen?
        if Inventario.TryGetValue(Nombre, OSha1Srv) and
           (OSha1Srv <> '') and (OSha1Srv = SHA1Local) then
        begin
          Inc(Saltadas);
          Query.Next;
          Continue;
        end;

        // Hay que subirla
        Job.SHA1 := SHA1Local;
        FBatchJobs.Add(Job);
        Inc(Faltantes);

        Query.Next;
      end;
    finally
      Query.Free;
      Conn.Free;
    end;
  finally
    Inventario.Free;
  end;

  FBatchSkipped := Saltadas;

  LogBatch(Format('SQL: %d filas  |  Saltadas (ya estaban): %d  |  Sin archivo local: %d  |  A subir: %d',
                  [TotalSql, Saltadas, NoExisten, Faltantes]));

  Total := FBatchJobs.Count;
  if Total = 0 then
  begin
    LogBatch('No hay nada que subir.');
    ActualizarProgreso;
    FreeAndNil(FBatchJobs);
    Exit;
  end;

  FBatchTotal      := Total;
  pbBatch.Min      := 0;
  pbBatch.Max      := Total;
  pbBatch.Position := 0;
  ActualizarProgreso;

  btnLanzar.Enabled   := False;
  btnCancelar.Enabled := True;
  FBatchRunning       := True;
  FBatchCancel        := CreateOmniCancellationToken;

  // ----------------------------------------------------------
  // PASO 4: lanzar pool OTL solo con lo que toca subir
  // ----------------------------------------------------------
  Parallel.ForEach(0, Total - 1)
    .NumTasks(N)
    .CancelWith(FBatchCancel)
    .NoWait
    .OnStop(
      procedure (const task: IOmniTask)
      begin
        TThread.Queue(nil,
          procedure
          begin
            BatchTerminado;
          end);
      end)
    .Execute(
      procedure (const index: Integer)
      var
        LocalJob: TFotoJob;
        R: TFotoUploadResult;
      begin
        if FBatchCancel.IsSignalled then
          Exit;

        LocalJob := FBatchJobs[index];

        try
          R := SubirFoto(Cfg,
                         LocalJob.Articulo,
                         LocalJob.Color,
                         LocalJob.Indice,
                         LocalJob.Archivo,
                         LocalJob.SHA1);
        except
          on E: Exception do
          begin
            R := Default(TFotoUploadResult);
            R.Articulo := LocalJob.Articulo;
            R.Color    := LocalJob.Color;
            R.Indice   := LocalJob.Indice;
            R.Archivo  := LocalJob.Archivo;
            R.Status   := fusError;
            R.Mensaje  := 'Excepción: ' + E.Message;
          end;
        end;

        TThread.Queue(nil,
          procedure
          begin
            ProcesarResultado(R);
          end);
      end);
end;

procedure TForm1.btnCancelarClick(Sender: TObject);
begin
  if Assigned(FBatchCancel) then
  begin
    FBatchCancel.Signal;
    LogBatch('Cancelación solicitada...');
    btnCancelar.Enabled := False;
  end;
end;

end.
