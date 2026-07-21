{******************************************************************************}
{                                                                              }
{  Módulo:       UPrincipal                                                    }
{    Tipo:       Formulario                                                    }
{ Versión:       1.1.0                                                         }
{   Fecha:       21/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Interfaz para crear credenciales API autorizadas mediante Ed25519.        }
{******************************************************************************}

unit UPrincipal;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  inLibFirmaApi;

type
  TfrmPrincipal = class(TForm)
    btnCopiarClavePublica: TButton;
    btnCopiarToken: TButton;
    btnCrearApi: TButton;
    edtIdClave: TEdit;
    edtReferencia: TEdit;
    edtUrl: TEdit;
    lblAmbitos: TLabel;
    lblAviso: TLabel;
    lblClavePublica: TLabel;
    lblIdClave: TLabel;
    lblReferencia: TLabel;
    lblResultado: TLabel;
    lblTitulo: TLabel;
    lblUrl: TLabel;
    mAmbitos: TMemo;
    mClavePublica: TMemo;
    mResultado: TMemo;
    procedure btnCopiarClavePublicaClick(Sender: TObject);
    procedure btnCopiarTokenClick(Sender: TObject);
    procedure btnCrearApiClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FIdentidad: TIdentidadEmisora;
    FUltimoToken: string;
    procedure CargarIdentidad;
    procedure MostrarResultado(const AMensaje, AToken: string);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Clipbrd, Vcl.Dialogs,
  inLibClienteApi;

{$R *.dfm}

procedure TfrmPrincipal.CargarIdentidad;
begin
  FIdentidad := TFirmaApi.CargarOCrearIdentidad;
  edtIdClave.Text := FIdentidad.IdClave;
  mClavePublica.Lines.Text :=
    TFirmaApi.Base64UrlCodificar(FIdentidad.ClavePublica);
end;

procedure TfrmPrincipal.MostrarResultado(
  const AMensaje, AToken: string);
begin
  FUltimoToken := AToken;
  mResultado.Clear;
  mResultado.Lines.Add(AMensaje);
  if AToken <> '' then
  begin
    mResultado.Lines.Add('');
    mResultado.Lines.Add('Token mostrado una sola vez:');
    mResultado.Lines.Add(AToken);
  end;
  btnCopiarToken.Enabled := AToken <> '';
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FUltimoToken := '';
  edtUrl.Text :=
    'https://webservice.veryverifactu.com/api/v1/admin/crear_api.php';
  mAmbitos.Lines.Text :=
    'prueba:leer' + sLineBreak +
    'ventas:leer' + sLineBreak +
    'ventas:escribir' + sLineBreak +
    'fotos:leer' + sLineBreak +
    'fotos:escribir' + sLineBreak +
    'sif:instalacion' + sLineBreak +
    'recuentos:leer' + sLineBreak +
    'recuentos:escribir' + sLineBreak +
    'correo:enviar';
  CargarIdentidad;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  TFirmaApi.Limpiar(FIdentidad.ClavePrivada);
  TFirmaApi.Limpiar(FIdentidad.ClavePublica);
  FUltimoToken := '';
end;

procedure TfrmPrincipal.btnCopiarClavePublicaClick(Sender: TObject);
begin
  Clipboard.AsText := mClavePublica.Lines.Text;
end;

procedure TfrmPrincipal.btnCopiarTokenClick(Sender: TObject);
begin
  if FUltimoToken <> '' then
    Clipboard.AsText := FUltimoToken;
end;

procedure TfrmPrincipal.btnCrearApiClick(Sender: TObject);
var
  oResultado: TResultCrearApi;
  sAmbitos: string;
begin
  if Trim(edtUrl.Text) = '' then
    MessageDlg('Indique la URL del servicio.', mtWarning, [mbOK], 0)
  else if Trim(edtReferencia.Text) = '' then
    MessageDlg('Indique un nombre de referencia.', mtWarning, [mbOK], 0)
  else
  begin
    btnCrearApi.Enabled := False;
    Screen.Cursor := crHourGlass;
    try
      sAmbitos := StringReplace(mAmbitos.Lines.Text, sLineBreak, ',',
                                [rfReplaceAll]);
      oResultado := TClienteApi.CrearApi(
        edtUrl.Text, edtReferencia.Text, sAmbitos, FIdentidad);
      MostrarResultado(oResultado.Mensaje, oResultado.Token);
    finally
      Screen.Cursor := crDefault;
      btnCrearApi.Enabled := True;
    end;
  end;
end;

end.
