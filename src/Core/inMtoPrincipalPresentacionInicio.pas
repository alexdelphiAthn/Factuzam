{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipalPresentacionInicio                             }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presenta el splash, tema, título y fondo de la ventana principal.        }
{******************************************************************************}
unit inMtoPrincipalPresentacionInicio;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ExtCtrls,
  cxLookAndFeels,
  cxPC,
  cxLabel,
  dxSkinsForm,
  inLibParametrosIntf,
  inLibLogIntf,
  inLibTraduccionesIntf;

type
  TPresentacionInicioPrincipal = class
  private
    FOwner: TComponent;
    FPagina: TcxPageControl;
    FImagenFondo: TImage;
    FLookAndFeel: TcxLookAndFeelController;
    FSkin: TdxSkinController;
    FRegistroLog: IRegistroLog;
    FSplash: TForm;
    FInstanteSplash: TDateTime;
    FNombre: TcxLabel;
    FVersion: TcxLabel;
    procedure AplicarTema(
      const AParametros: IParametrosAplicacion);
    procedure CrearEtiquetas(const AVersion: string);
    procedure CargarFondo;
    function CargarFondoRecurso: Boolean;
    function CargarFondoDisco: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      APagina: TcxPageControl;
      AImagenFondo: TImage;
      ALookAndFeel: TcxLookAndFeelController;
      ASkin: TdxSkinController;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure MostrarSplash;
    procedure AplicarTraduccionesSplash(
      const ATraducciones: IServicioTraducciones);
    procedure Configurar(
      const AParametros: IParametrosAplicacion;
      const AVersion: string);
    procedure CentrarFondo;
    procedure ActualizarFondo;
    procedure CerrarSplash(AMinimoMs: Integer);
    procedure AplicarTitulo(
      AFormulario: TForm;
      AEsDemo: Boolean;
      const AAplicacion, AVersion: string);
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  inLibDir,
  inLibMsgComun,
  inLibWin,
  inMtoSplash;

constructor TPresentacionInicioPrincipal.Create(
  AOwner: TComponent;
  APagina: TcxPageControl;
  AImagenFondo: TImage;
  ALookAndFeel: TcxLookAndFeelController;
  ASkin: TdxSkinController;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FOwner := AOwner;
  FPagina := APagina;
  FImagenFondo := AImagenFondo;
  FLookAndFeel := ALookAndFeel;
  FSkin := ASkin;
  FRegistroLog := ARegistroLog;
end;

destructor TPresentacionInicioPrincipal.Destroy;
begin
  FreeAndNil(FSplash);
  FreeAndNil(FNombre);
  FreeAndNil(FVersion);
  FRegistroLog := nil;
  inherited;
end;

procedure TPresentacionInicioPrincipal.MostrarSplash;
begin
  FreeAndNil(FSplash);
  FInstanteSplash := Now;
  try
    FSplash := TfrmSplash.Create(nil, FRegistroLog);
    FSplash.FormStyle := fsStayOnTop;
    TfrmSplash(FSplash).btnAceptar.Visible := False;
    FSplash.Show;
    Application.ProcessMessages;
  except
    FreeAndNil(FSplash);
  end;
end;

procedure TPresentacionInicioPrincipal.AplicarTraduccionesSplash(
  const ATraducciones: IServicioTraducciones);
begin
  if Assigned(ATraducciones) and Assigned(FSplash) then
    ATraducciones.Aplicar(FSplash);
end;

procedure TPresentacionInicioPrincipal.AplicarTema(
  const AParametros: IParametrosAplicacion);
var
  sPaleta: string;
  sTema: string;
begin
  if Assigned(FLookAndFeel) and Assigned(FSkin) then
  begin
    try
      sTema := AParametros.GetString('appTema');
      if sTema = '' then
        if DarkModeIsEnabled then
          sTema := 'MetropolisDark'
        else
          sTema := 'Office2007Pink';
      FLookAndFeel.SkinName := sTema;
      FSkin.SkinName := sTema;
      sPaleta := AParametros.GetString('appPaleta');
      if sPaleta <> '' then
        TcxRootLookAndFeel.Instance.SkinPaletteName := sPaleta;
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'Error al establecer skin: ' + E.Message);
    end;
  end;
end;

procedure TPresentacionInicioPrincipal.Configurar(
  const AParametros: IParametrosAplicacion;
  const AVersion: string);
begin
  AplicarTema(AParametros);
  CargarFondo;
  FImagenFondo.Parent := FPagina;
  FImagenFondo.Anchors := [akTop, akRight];
  FImagenFondo.Proportional := True;
  FImagenFondo.Stretch := True;
  FImagenFondo.Center := True;
  FImagenFondo.BringToFront;
  CrearEtiquetas(AVersion);
  CentrarFondo;
  ActualizarFondo;
end;

procedure TPresentacionInicioPrincipal.CrearEtiquetas(
  const AVersion: string);
begin
  FreeAndNil(FNombre);
  FreeAndNil(FVersion);
  FNombre := TcxLabel.Create(FOwner);
  FNombre.Parent := FPagina;
  FNombre.Caption := 'Alejandro Laorden Hidalgo';
  FNombre.AutoSize := False;
  FNombre.Style.Font.Name := 'Lucida Sans';
  FNombre.Style.Font.Height := -17;
  FNombre.Style.Font.Style := [fsBold];
  FNombre.Properties.Alignment.Horz := taCenter;
  FNombre.Transparent := True;
  FVersion := TcxLabel.Create(FOwner);
  FVersion.Parent := FPagina;
  FVersion.Caption := Format(SCaptionVersion, [AVersion]);
  FVersion.AutoSize := False;
  FVersion.Style.Font.Name := 'Lucida Sans';
  FVersion.Style.Font.Height := -14;
  FVersion.Properties.Alignment.Horz := taCenter;
  FVersion.Transparent := True;
end;

procedure TPresentacionInicioPrincipal.CentrarFondo;
var
  iAlto: Integer;
  iAltoCliente: Integer;
  iAncho: Integer;
  iAnchoCliente: Integer;
  iCentroX: Integer;
  iCentroY: Integer;
begin
  if Assigned(FImagenFondo) then
  begin
    iAnchoCliente := FPagina.ClientWidth;
    iAltoCliente := FPagina.ClientHeight;
    iAncho := iAnchoCliente div 3;
    if iAncho > 380 then
      iAncho := 380;
    if iAncho < 180 then
      iAncho := 180;
    iAlto := Round(iAncho * 130 / 520);
    iCentroX := (iAnchoCliente - iAncho) div 2;
    iCentroY := (iAltoCliente - iAlto - 80) div 2;
    if iCentroY < 20 then
      iCentroY := 20;
    FImagenFondo.Anchors := [];
    FImagenFondo.SetBounds(
      iCentroX, iCentroY, iAncho, iAlto);
    if Assigned(FNombre) then
      FNombre.SetBounds(
        0, iCentroY + iAlto + 8, iAnchoCliente, 26);
    if Assigned(FVersion) then
      FVersion.SetBounds(
        0, iCentroY + iAlto + 38, iAnchoCliente, 20);
  end;
end;

procedure TPresentacionInicioPrincipal.ActualizarFondo;
var
  bDebeVerse: Boolean;
begin
  bDebeVerse :=
    (FPagina.PageCount = 0) and
    Assigned(FImagenFondo.Picture.Graphic);
  if FImagenFondo.Visible <> bDebeVerse then
    FImagenFondo.Visible := bDebeVerse;
  if Assigned(FNombre) and
     (FNombre.Visible <> bDebeVerse) then
    FNombre.Visible := bDebeVerse;
  if Assigned(FVersion) and
     (FVersion.Visible <> bDebeVerse) then
    FVersion.Visible := bDebeVerse;
end;

function TPresentacionInicioPrincipal.CargarFondoRecurso: Boolean;
var
  oPng: TPngImage;
  oRecurso: TResourceStream;
begin
  Result := False;
  oPng := nil;
  oRecurso := nil;
  try
    try
      oRecurso := TResourceStream.Create(
        HInstance, 'FONDO', RT_RCDATA);
      oPng := TPngImage.Create;
      oPng.LoadFromStream(oRecurso);
      FImagenFondo.Picture.Assign(oPng);
      FRegistroLog.RegistrarInformacion(
        'CargarFondoLogo: OK desde recurso FONDO (' +
        IntToStr(oRecurso.Size) + ' bytes)');
      Result := True;
    except
      on E: Exception do
        FRegistroLog.RegistrarInformacion(
          'CargarFondoLogo: recurso FONDO no disponible (' +
          E.Message + '); pruebo disco');
    end;
  finally
    FreeAndNil(oPng);
    FreeAndNil(oRecurso);
  end;
end;

function TPresentacionInicioPrincipal.CargarFondoDisco: Boolean;
const
  RUTAS: array[0..1] of string = (
    'fondo.png',
    '..\..\fondo.png');
var
  i: Integer;
  sBase: string;
  sRuta: string;
begin
  Result := False;
  sBase := inLibDir.DirApp;
  FRegistroLog.RegistrarInformacion(
    'CargarFondoLogo: base="' + sBase + '"');
  i := 0;
  while (i <= High(RUTAS)) and (not Result) do
  begin
    sRuta := sBase + RUTAS[i];
    if FileExists(sRuta) then
    begin
      try
        FImagenFondo.Picture.LoadFromFile(sRuta);
        Result := True;
        FRegistroLog.RegistrarInformacion(
          'CargarFondoLogo: OK desde "' + sRuta + '"');
      except
        on E: Exception do
          FRegistroLog.RegistrarAviso(
            'No se pudo cargar fondo ' + sRuta + ': ' + E.Message);
      end;
    end
    else
      FRegistroLog.RegistrarInformacion(
        'CargarFondoLogo: no existe "' + sRuta + '"');
    Inc(i);
  end;
end;

procedure TPresentacionInicioPrincipal.CargarFondo;
var
  bCargado: Boolean;
begin
  bCargado := CargarFondoRecurso;
  if not bCargado then
    CargarFondoDisco;
end;

procedure TPresentacionInicioPrincipal.CerrarSplash(
  AMinimoMs: Integer);
var
  iEsperaMs: Integer;
  iTranscurridoMs: Integer;
begin
  if Assigned(FSplash) then
  begin
    iTranscurridoMs := Round(
      (Now - FInstanteSplash) * 86400000);
    if iTranscurridoMs < AMinimoMs then
    begin
      iEsperaMs := AMinimoMs - iTranscurridoMs;
      Application.ProcessMessages;
      Sleep(iEsperaMs);
    end;
    try
      FSplash.Close;
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'Principal: cierre del splash de inicio falló: ' +
          E.Message);
    end;
    FreeAndNil(FSplash);
  end;
end;

procedure TPresentacionInicioPrincipal.AplicarTitulo(
  AFormulario: TForm;
  AEsDemo: Boolean;
  const AAplicacion, AVersion: string);
var
  sTitulo: string;
begin
  if AEsDemo then
    sTitulo := AAplicacion + ' DEMO ' + AVersion
  else
    sTitulo := AAplicacion + ' ' + AVersion;
  AFormulario.Caption := sTitulo;
  Application.Title := sTitulo;
end;

end.
