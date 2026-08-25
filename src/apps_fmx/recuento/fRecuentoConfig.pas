{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoConfig                                               }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de configuración: URL del servidor, carpeta de cliente, operario }
{    y alta del dispositivo (obtiene el token). UI por código (sin .fmx).      }
{******************************************************************************}
unit fRecuentoConfig;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Types,
  FMX.DialogService,
  RecuentoConfig, RecuentoApi;

type
  TfrmConfig = class(TForm)
  private
    FUrl, FCarpeta, FOperario, FDispositivo, FClave: TEdit;
    function NuevoEdit(const ATitulo, AValor: string): TEdit;
    procedure Construir;
    procedure VolcarAConfig;
    procedure OnGuardarClick(Sender: TObject);
    procedure OnRegistrarClick(Sender: TObject);
    procedure OnVolverClick(Sender: TObject);
  public
    class procedure EditarAsync(AOwner: TComponent; ACallback: TProc);
  end;

implementation

const
  cSeparadorRuta = '/';

resourcestring
  STituloConfiguracionRecuento = 'Configuración';
  SBotonVolverConfiguracion = 'Volver';
  SBotonGuardarConfiguracion = 'Guardar';
  SBotonRegistrarDispositivo = 'Registrar disp.';
  SEtiquetaClaveAlta = 'Clave de alta';
  SEtiquetaNombreDispositivo = 'Nombre del dispositivo';
  SEtiquetaOperario = 'Operario';
  SEtiquetaCarpetaCliente = 'Carpeta de cliente';
  SEtiquetaUrlServidor = 'URL del servidor (acaba en %s)';
  SInfoConfiguracionGuardada = 'Configuración guardada';
  SInfoDispositivoRegistrado = 'Dispositivo registrado correctamente';
  SErrorRegistrarDispositivo = 'No se pudo registrar: %s';

function TfrmConfig.NuevoEdit(const ATitulo, AValor: string): TEdit;
var
  lbl: TLabel;
  edt: TEdit;
begin
  lbl := TLabel.Create(Self);
  lbl.Parent := Self;
  lbl.Align := TAlignLayout.Top;
  lbl.Height := 24;
  lbl.Text := ATitulo;
  edt := TEdit.Create(Self);
  edt.Parent := Self;
  edt.Align := TAlignLayout.Top;
  edt.Height := 40;
  edt.Margins.Bottom := 8;
  edt.Text := AValor;
  Result := edt;
end;

procedure TfrmConfig.Construir;
var
  layBotones: TLayout;
  btnRegistrar, btnGuardar, btnVolver: TButton;
begin
  Self.Caption := STituloConfiguracionRecuento;
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 56;
  btnVolver := TButton.Create(Self);
  btnVolver.Parent := layBotones;
  btnVolver.Align := TAlignLayout.Left;
  btnVolver.Width := 110;
  btnVolver.Text := SBotonVolverConfiguracion;
  btnVolver.OnClick := OnVolverClick;
  btnGuardar := TButton.Create(Self);
  btnGuardar.Parent := layBotones;
  btnGuardar.Align := TAlignLayout.Left;
  btnGuardar.Width := 110;
  btnGuardar.Text := SBotonGuardarConfiguracion;
  btnGuardar.OnClick := OnGuardarClick;
  btnRegistrar := TButton.Create(Self);
  btnRegistrar.Parent := layBotones;
  btnRegistrar.Align := TAlignLayout.Right;
  btnRegistrar.Width := 150;
  btnRegistrar.Text := SBotonRegistrarDispositivo;
  btnRegistrar.OnClick := OnRegistrarClick;
  // Los edits se apilan por Align=Top en orden inverso de creación, así que
  // creamos primero el último (clave) para que quede abajo del bloque.
  FClave       := NuevoEdit(SEtiquetaClaveAlta, '');
  FDispositivo := NuevoEdit(SEtiquetaNombreDispositivo, oConfig.Dispositivo);
  FOperario    := NuevoEdit(SEtiquetaOperario, oConfig.Operario);
  FCarpeta     := NuevoEdit(SEtiquetaCarpetaCliente, oConfig.Carpeta);
  FUrl         := NuevoEdit(Format(SEtiquetaUrlServidor, [cSeparadorRuta]),
    oConfig.UrlBase);
end;

procedure TfrmConfig.VolcarAConfig;
begin
  oConfig.UrlBase     := Trim(FUrl.Text);
  oConfig.Carpeta     := Trim(FCarpeta.Text);
  oConfig.Operario    := Trim(FOperario.Text);
  oConfig.Dispositivo := Trim(FDispositivo.Text);
  oConfig.Guardar;
end;

procedure TfrmConfig.OnGuardarClick(Sender: TObject);
begin
  VolcarAConfig;
  TDialogService.ShowMessage(SInfoConfiguracionGuardada);
end;

procedure TfrmConfig.OnRegistrarClick(Sender: TObject);
var
  oApi: TRecuentoApi;
  sToken: string;
begin
  VolcarAConfig;
  // TODO: mover esta llamada de red a un hilo (TTask) para no bloquear la UI.
  oApi := TRecuentoApi.Create;
  try
    if oApi.RegistrarDispositivo(Trim(FDispositivo.Text),
         Trim(FOperario.Text), Trim(FClave.Text), sToken) then
    begin
      oConfig.Token := sToken;
      oConfig.Guardar;
      TDialogService.ShowMessage(SInfoDispositivoRegistrado);
    end
    else
      TDialogService.ShowMessage(
        Format(SErrorRegistrarDispositivo, [oApi.UltimoError]));
  finally
    FreeAndNil(oApi);
  end;
end;

procedure TfrmConfig.OnVolverClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

class procedure TfrmConfig.EditarAsync(AOwner: TComponent; ACallback: TProc);
var
  frm: TfrmConfig;
begin
  frm := TfrmConfig.CreateNew(AOwner);
  frm.Construir;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if Assigned(ACallback) then
        ACallback();
      frm.Free;
    end);
end;

end.
