{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSplash                                                   }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Este formulario es un formulario de información sobre el autor.           }
{    No tiene ningún propósito funcional, pero es importante agradecer a quien }
{    te ha dado una mano.                                                      }
{******************************************************************************}
unit inMtoSplash;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, jpeg, StdCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, JvExControls,
  JvAnimatedImage, JvGIFCtrl, cxTextEdit, cxHyperLinkEdit, Vcl.Menus, cxButtons,
  Vcl.Imaging.pngimage;

type
  TfrmSplash = class(TForm)
    Panel1: TPanel;
    Panel3: TPanel;
    cxLabel1: TcxLabel;
    hlEmail: TcxHyperLinkEdit;
    cxLabel2: TcxLabel;
    btnAceptar: TcxButton;
    Panel2: TPanel;
    procedure JvGIFAnimator1Click(Sender: TObject);
    procedure cxLabel1Click(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FlblNombre:  TcxLabel;
    FlblVersion: TcxLabel;
    FimgLogo:    TImage;
  public
    { Public declarations }
  end;
var
  frmSplash: TfrmSplash;

implementation

uses
  inLibGlobalVar, inLibDir, inLibLog;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmSplash.cxLabel1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.JvGIFAnimator1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.btnAceptarClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.FormCreate(Sender: TObject);
const
  CNombre: string = 'Alejandro Laorden Hidalgo';
  CEmail:  string = 'alejandro.laorden@protonmail.com';
  CRutas:  array[0..3] of string = (
    'fondo.png',
    '..\..\fondo.png',
    'logo_art\icon-256.png',
    '..\..\logo_art\icon-256.png'
  );
var
  sBase, sRuta: string;
  i: Integer;
  bCargado: Boolean;
  oRes: TResourceStream;
  oPng: TPngImage;
begin
  // El email del .dfm se sobreescribe en runtime para no quedar atado al
  // valor cableado (que ademas en versiones antiguas era una direccion
  // de batch antigua).
  hlEmail.Text := CEmail;
  // Sustituimos el GIF heredado del .dfm por el logo (fondo.png) cargado
  // en runtime. Primero intentamos el recurso RCDATA 'FONDO' embebido en
  // el .exe (via {$R fondo.res} en fzam.dpr); si no, caemos a fichero
  // suelto con las mismas rutas que TfrmMtoPrincipal.CargarFondoLogo. Si
  // no se encuentra de ningun modo, dejamos el GIF heredado para no
  // quedarnos con un area en blanco.
  bCargado := False;
  FimgLogo := TImage.Create(Self);
  FimgLogo.Parent := Panel1;
  FimgLogo.SetBounds(Panel2.Left, Panel2.Top,
                     Panel2.Width, Panel2.Height);
  FimgLogo.Proportional := True;
  FimgLogo.Stretch      := True;
  FimgLogo.Center       := True;
  try
    oRes := TResourceStream.Create(HInstance, 'FONDO', RT_RCDATA);
    try
      oPng := TPngImage.Create;
      try
        oPng.LoadFromStream(oRes);
        FimgLogo.Picture.Assign(oPng);
        bCargado := True;
      finally
        oPng.Free;
      end;
    finally
      oRes.Free;
    end;
  except
    // Recurso no presente (build sin fondo.res); seguimos a disco.
  end;
  if not bCargado then
  begin
    sBase := inLibDir.DirApp;
    for i := 0 to High(CRutas) do
    begin
      sRuta := sBase + CRutas[i];
      if FileExists(sRuta) then
      try
        FimgLogo.Picture.LoadFromFile(sRuta);
        bCargado := True;
        Break;
      except
        on E: Exception do
          inLibLog.Log.LogWarning('Splash: no se pudo cargar ' + sRuta +
                                  ': ' + E.Message);
      end;
    end;
  end;
//  if bCargado then
//    JvGIFAnimator1.Visible := False
//  else
//  begin
//    FreeAndNil(FimgLogo);
//    inLibLog.Log.LogWarning(
//      'Splash: no se encontro fondo (recurso ni fichero); GIF heredado.');
//  end;
  // Nombre del autor superpuesto al GIF (banda inferior del area de
  // imagen, justo encima del panel de creditos).
  FlblNombre := TcxLabel.Create(Self);
  FlblNombre.Parent  := Panel1;
  FlblNombre.Caption := CNombre;
  FlblNombre.AutoSize := False;
  FlblNombre.SetBounds(0, 295, Panel1.Width, 22);
  FlblNombre.Properties.Alignment.Horz := taCenter;
  // Asignar cualquier propiedad de Style.Font activa IsFontAssigned
  // automaticamente; no hay que tocarla en runtime (es read-only).
  FlblNombre.Style.Font.Name   := 'Lucida Sans';
  FlblNombre.Style.Font.Height := -16;
  FlblNombre.Style.Font.Style  := [fsBold];
  FlblNombre.Transparent := True;
  // Version dinamica, leida de inLibGlobalVar para evitar drift entre
  // splash y about.
  FlblVersion := TcxLabel.Create(Self);
  FlblVersion.Parent  := Panel1;
  FlblVersion.Caption := 'Versión ' + oVersion;
  FlblVersion.AutoSize := False;
  FlblVersion.SetBounds(0, 316, Panel1.Width, 18);
  FlblVersion.Properties.Alignment.Horz := taCenter;
  FlblVersion.Style.Font.Name   := 'Lucida Sans';
  FlblVersion.Style.Font.Height := -12;
  FlblVersion.Style.Font.Style  := [];
  FlblVersion.Transparent := True;
end;

initialization
  ForceReferenceToClass(TfrmSplash);

end.
