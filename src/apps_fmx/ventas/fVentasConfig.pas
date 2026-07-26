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
    FEdtUrl: TEdit;
    FGuardado: Boolean;
    procedure Construir;
    function NuevoCampo(const AEtiqueta, AValor: string;
      AOculto: Boolean): TEdit;
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

function TfrmConfig.NuevoCampo(const AEtiqueta, AValor: string;
  AOculto: Boolean): TEdit;
var
  lblEtiqueta: TLabel;
begin
  lblEtiqueta := TLabel.Create(Self);
  lblEtiqueta.Parent := Self;
  lblEtiqueta.Align := TAlignLayout.Top;
  lblEtiqueta.Height := 26;
  lblEtiqueta.Margins.Rect := RectF(14, 10, 14, 0);
  lblEtiqueta.Text := AEtiqueta;
  Result := TEdit.Create(Self);
  Result.Parent := Self;
  Result.Align := TAlignLayout.Top;
  Result.Height := 44;
  Result.Margins.Rect := RectF(14, 0, 14, 0);
  Result.Text := AValor;
  Result.Password := AOculto;
end;

procedure TfrmConfig.Construir;
var
  btnCancelar: TButton;
  btnGuardar: TButton;
  layBotones: TLayout;
  lblTitulo: TLabel;
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
  lblTitulo.Height := 44;
  lblTitulo.Margins.Rect := RectF(14, 12, 14, 0);
  lblTitulo.Text := 'Conexión con el webservice';
  lblTitulo.TextSettings.Font.Size := 19;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  FEdtUrl := NuevoCampo('URL base de la API', oConfig.UrlBase, False);
  FEdtToken := NuevoCampo('Token de la credencial', oConfig.Token, True);
  FEdtReferencia := NuevoCampo('Referencia de la instalación',
    oConfig.Referencia, False);
  FChkMargen := TCheckBox.Create(Self);
  FChkMargen.Parent := Self;
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
