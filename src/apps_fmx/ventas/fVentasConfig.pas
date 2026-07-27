{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasConfig                                                 }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de configuración: URL de la API, token de la credencial y        }
{    referencia de la instalación. La UI se construye por código (sin .fmx).   }
{******************************************************************************}
unit fVentasConfig;

interface

uses
  System.Classes, System.SysUtils,
  FMX.Forms, FMX.Controls, FMX.Edit, FMX.StdCtrls;

type
  TfrmConfig = class(TForm)
  private
    FChkMargen: TCheckBox;
    FEdtReferencia: TEdit;
    FEdtToken: TEdit;
    FContenido: TControl;
    FEdtUrl: TEdit;
    FGuardado: Boolean;
    procedure Construir;
    function NuevoCampo(const AEtiqueta, APista, AValor,
      APrompt: string; AOculto: Boolean): TEdit;
    procedure OnCancelarClick(Sender: TObject);
    procedure OnGuardarClick(Sender: TObject);
  public
    class procedure EditarAsync(AOwner: TComponent;
      ACallback: TProc<Boolean>);
  end;

implementation

uses
  System.Types, System.UITypes, FMX.Types, FMX.Layouts,
  VentasConfig;

{ Cada campo son tres controles apilados: rótulo en negrita, una línea de
  ayuda en gris que dice qué va ahí, y la caja. Los tres van alineados
  arriba, así que el orden en que se crean es el orden en que se ven. }
function TfrmConfig.NuevoCampo(const AEtiqueta, APista, AValor,
  APrompt: string; AOculto: Boolean): TEdit;
var
  lblEtiqueta: TLabel;
  lblPista: TLabel;
begin
  lblEtiqueta := TLabel.Create(Self);
  lblEtiqueta.Parent := FContenido;
  lblEtiqueta.Align := TAlignLayout.Top;
  lblEtiqueta.Height := 24;
  lblEtiqueta.Margins.Rect := RectF(14, 16, 14, 0);
  lblEtiqueta.Text := AEtiqueta;
  lblEtiqueta.TextSettings.Font.Size := 15;
  lblEtiqueta.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblEtiqueta.StyledSettings := [TStyledSetting.FontColor];
  lblPista := TLabel.Create(Self);
  lblPista.Parent := FContenido;
  lblPista.Align := TAlignLayout.Top;
  lblPista.Height := 34;
  lblPista.Margins.Rect := RectF(14, 0, 14, 4);
  lblPista.Text := APista;
  lblPista.TextSettings.Font.Size := 12;
  lblPista.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblPista.TextSettings.WordWrap := True;
  lblPista.StyledSettings := [];
  Result := TEdit.Create(Self);
  Result.Parent := FContenido;
  Result.Align := TAlignLayout.Top;
  Result.Height := 46;
  Result.Margins.Rect := RectF(14, 0, 14, 0);
  Result.Text := AValor;
  Result.TextPrompt := APrompt;
  Result.Password := AOculto;
end;

procedure TfrmConfig.Construir;
var
  btnCancelar: TButton;
  btnGuardar: TButton;
  layBotones: TLayout;
  lblTitulo: TLabel;
  scbCampos: TVertScrollBox;
begin
  Self.Caption := 'Configuración';
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 64;
  btnCancelar := TButton.Create(Self);
  btnCancelar.Parent := layBotones;
  btnCancelar.Align := TAlignLayout.Left;
  btnCancelar.Width := 150;
  btnCancelar.Margins.Rect := RectF(14, 8, 0, 12);
  btnCancelar.Text := 'Cancelar';
  btnCancelar.OnClick := OnCancelarClick;
  btnGuardar := TButton.Create(Self);
  btnGuardar.Parent := layBotones;
  btnGuardar.Align := TAlignLayout.Right;
  btnGuardar.Width := 150;
  btnGuardar.Margins.Rect := RectF(0, 8, 14, 12);
  btnGuardar.Text := 'Guardar';
  btnGuardar.OnClick := OnGuardarClick;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 38;
  lblTitulo.Margins.Rect := RectF(14, 12, 14, 0);
  lblTitulo.Text := 'Conexión con el webservice';
  lblTitulo.TextSettings.Font.Size := 19;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  // Con el teclado abierto la pantalla se queda sin sitio, así que los
  // campos van en un scroll y los botones se quedan fijos abajo.
  scbCampos := TVertScrollBox.Create(Self);
  scbCampos.Parent := Self;
  scbCampos.Align := TAlignLayout.Client;
  FContenido := scbCampos;
  FEdtUrl := NuevoCampo(
    'URL de la API',
    'Dirección del webservice, terminada en /api/v1/',
    oConfig.UrlBase,
    'https://webservice.veryverifactu.com/api/v1/',
    False);
  FEdtToken := NuevoCampo(
    'Token de la credencial',
    'El que dio CertApiWeb al crear la API. Solo se enseña una vez, ' +
    'así que si se ha perdido hay que crear otra credencial.',
    oConfig.Token,
    'fza_...',
    True);
  FEdtReferencia := NuevoCampo(
    'Referencia de cliente',
    'Nombre de la instalación, el mismo que tiene configurado ' +
    'Factuzam. Distingue mayúsculas de minúsculas.',
    oConfig.Referencia,
    'MI-TIENDA',
    False);
  FChkMargen := TCheckBox.Create(Self);
  FChkMargen.Parent := FContenido;
  FChkMargen.Align := TAlignLayout.Top;
  FChkMargen.Height := 44;
  FChkMargen.Margins.Rect := RectF(14, 14, 14, 0);
  FChkMargen.Text := 'Mostrar coste y margen';
  FChkMargen.IsChecked := oConfig.MostrarMargen;
end;

procedure TfrmConfig.OnGuardarClick(Sender: TObject);
begin
  oConfig.UrlBase := Trim(FEdtUrl.Text);
  oConfig.Token := Trim(FEdtToken.Text);
  oConfig.Referencia := Trim(FEdtReferencia.Text);
  oConfig.MostrarMargen := FChkMargen.IsChecked;
  oConfig.Guardar;
  FGuardado := True;
  ModalResult := mrOk;
end;

procedure TfrmConfig.OnCancelarClick(Sender: TObject);
begin
  FGuardado := False;
  ModalResult := mrCancel;
end;

class procedure TfrmConfig.EditarAsync(AOwner: TComponent;
  ACallback: TProc<Boolean>);
var
  frm: TfrmConfig;
  oCallback: TProc<Boolean>;
begin
  // El callback se copia a una local: las closures capturan variables del
  // método, no sus parámetros.
  oCallback := ACallback;
  frm := TfrmConfig.CreateNew(AOwner);
  frm.FGuardado := False;
  frm.Construir;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    var
      bGuardado: Boolean;
    begin
      bGuardado := frm.FGuardado;
      // El formulario NO se libera aquí: FMX lo sigue tocando cuando este
      // callback vuelve, y liberarlo en medio corrompe la memoria.
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
      if Assigned(oCallback) then
        oCallback(bGuardado);
    end);
end;

end.
