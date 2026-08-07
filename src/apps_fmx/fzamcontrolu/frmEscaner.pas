unit frmEscaner;

{
  Pantalla de escaneo de codigos EAN-13 con la camara para FzamControlU.

  Ajustado para Delphi 13 Florence:
  - Las firmas usan TClassicStringDynArray (System.Types) y
    TClassicPermissionStatusDynArray (System.Permissions), que son los
    tipos exactos que espera la sobrecarga anonimo de RequestPermissions.
}

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Permissions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Objects,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Media, FMX.Graphics,
  FMX.DialogService,
  {$IFDEF ANDROID}
  Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes,
  {$ENDIF}
  ZXing.ScanManager, ZXing.BarcodeFormat, ZXing.ReadResult;

type
  TCodigoEscaneadoEvent = procedure(const Codigo: string) of object;

  TFormEscaner = class(TForm)
    pnlTop: TPanel;
    btnCancelar: TButton;
    lblEstado: TLabel;
    imgPreview: TImage;
    pnlBottom: TPanel;
    btnCapturar: TButton;
    cam: TCameraComponent;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnCapturarClick(Sender: TObject);
    procedure camSampleBufferReady(Sender: TObject; const ATime: TMediaTime);
  private
    FOnCodigoEscaneado: TCodigoEscaneadoEvent;
    FScanManager: TScanManager;
    FBuscando: Boolean;
    FUltimoCodigo: string;
    procedure ActivarCamara;
    procedure DesactivarCamara;
    procedure DecodificarFrame;
    procedure ProcesarSampleBuffer;
    {$IFDEF ANDROID}
    procedure SinPermiso;
    {$ENDIF}
  public
    property OnCodigoEscaneado: TCodigoEscaneadoEvent
      read FOnCodigoEscaneado write FOnCodigoEscaneado;
  end;

var
  FormEscaner: TFormEscaner;

implementation

{$R *.fmx}

procedure TFormEscaner.FormShow(Sender: TObject);
begin
  FBuscando := False;
  FUltimoCodigo := '';
  lblEstado.Text := 'Apunta al codigo de barras';

  FScanManager := TScanManager.Create(TBarcodeFormat.EAN_13, nil);

  {$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.CAMERA)],
    procedure(const APermissions: TClassicStringDynArray;
              const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) >= 1) and
         (AGrantResults[0] = TPermissionStatus.Granted) then
        ActivarCamara
      else
        SinPermiso;
    end,
    procedure(const APermissions: TClassicStringDynArray;
              const APostRationaleProc: TProc)
    begin
      // Mostrar al usuario por que necesitamos la camara, y luego
      // llamar a APostRationaleProc para que aparezca el dialogo del SO
      TDialogService.ShowMessage(
        'Factuzam necesita acceso a la camara para escanear codigos.',
        procedure(const AResult: TModalResult)
        begin
          APostRationaleProc;
        end);
    end
  );
  {$ELSE}
  ActivarCamara;
  {$ENDIF}
end;

{$IFDEF ANDROID}
procedure TFormEscaner.SinPermiso;
begin
  lblEstado.Text := 'Sin permiso de camara';
  TDialogService.ShowMessage(
    'Factuzam necesita permiso de camara para escanear codigos.');
end;
{$ENDIF}

procedure TFormEscaner.ActivarCamara;
begin
  try
    cam.Kind := FMX.Media.TCameraKind.BackCamera;
    cam.Quality := FMX.Media.TVideoCaptureQuality.MediumQuality;
    cam.FocusMode := FMX.Media.TFocusMode.ContinuousAutoFocus;
    cam.Active := True;
  except
    on E: Exception do
      lblEstado.Text := 'Error camara: ' + E.Message;
  end;
end;

procedure TFormEscaner.DesactivarCamara;
begin
  if Assigned(cam) and cam.Active then
    cam.Active := False;
end;

procedure TFormEscaner.ProcesarSampleBuffer;
begin
  cam.SampleBufferToBitmap(imgPreview.Bitmap, True);
  if not FBuscando then
    DecodificarFrame;
end;

procedure TFormEscaner.camSampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  TThread.Synchronize(nil, ProcesarSampleBuffer);
end;

procedure TFormEscaner.DecodificarFrame;
var
  Resultado: TReadResult;
  Codigo: string;
begin
  if FBuscando then Exit;
  if (imgPreview.Bitmap = nil) or imgPreview.Bitmap.IsEmpty then Exit;

  FBuscando := True;
  try
    Resultado := nil;
    try
      Resultado := FScanManager.Scan(imgPreview.Bitmap);
      if Assigned(Resultado) then
      begin
        Codigo := Resultado.Text;
        if (Codigo <> '') and (Codigo <> FUltimoCodigo) then
        begin
          FUltimoCodigo := Codigo;
          lblEstado.Text := 'Codigo: ' + Codigo;

          if Assigned(FOnCodigoEscaneado) then
            FOnCodigoEscaneado(Codigo);

          DesactivarCamara;
          Close;
        end;
      end;
    finally
      Resultado.Free;
    end;
  finally
    FBuscando := False;
  end;
end;

procedure TFormEscaner.btnCapturarClick(Sender: TObject);
begin
  FBuscando := False;
  FUltimoCodigo := '';
  DecodificarFrame;

  if FUltimoCodigo = '' then
    lblEstado.Text := 'No detectado, prueba de nuevo';
end;

procedure TFormEscaner.btnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TFormEscaner.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DesactivarCamara;
  if Assigned(FScanManager) then
    FreeAndNil(FScanManager);
end;

end.
