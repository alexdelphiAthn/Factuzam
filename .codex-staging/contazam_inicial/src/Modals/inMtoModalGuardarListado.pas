{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGuardarListado                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Solicita nombre y alcance al guardar un formato FastReport derivado.     }
{******************************************************************************}
unit inMtoModalGuardarListado;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, inMtoFrmBase, cxButtons,
  cxDropDownEdit, cxLabel, cxMemo, cxTextEdit,
  inLibListadosDerivadosIntf;

type
  TfrmModalGuardarListado = class(TfrmBase)
  private
    FAlcances: TArray<TAlcanceListadoDerivado>;
    FBtnCancelar: TcxButton;
    FBtnGuardar: TcxButton;
    FCbbAlcance: TcxComboBox;
    FLblAlcance: TcxLabel;
    FLblDescripcion: TcxLabel;
    FLblInformacion: TcxLabel;
    FLblNombre: TcxLabel;
    FMDescripcion: TcxMemo;
    FTxtNombre: TcxTextEdit;
    procedure AnadirAlcance(
      const ATexto: string;
      const AAlcance: TAlcanceListadoDerivado);
    procedure GuardarClick(Sender: TObject);
    procedure SeleccionarAlcance(
      const AAlcance: TAlcanceListadoDerivado);
  public
    constructor Create(AOwner: TComponent); override;
    function Alcance: TAlcanceListadoDerivado;
    function Descripcion: string;
    function Nombre: string;
    procedure Preparar(
      const AUsuario: string;
      const AEmpresa: string;
      const AGrupos: TGruposListadoDerivado;
      const AListado: TListadoDerivado);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, cxEdit;

constructor TfrmModalGuardarListado.Create(AOwner: TComponent);
begin
  inherited;
  BorderIcons := [biSystemMenu];
  BorderStyle := bsDialog;
  Caption := 'Guardar listado derivado';
  ClientWidth := 590;
  ClientHeight := 325;
  FTxtNombre := TcxTextEdit.Create(Self);
  FTxtNombre.Parent := Self;
  FTxtNombre.SetBounds(25, 52, 540, 27);
  FTxtNombre.Properties.MaxLength := 100;
  FLblNombre := TcxLabel.Create(Self);
  FLblNombre.Parent := Self;
  FLblNombre.SetBounds(20, 25, 200, 22);
  FLblNombre.Caption := 'Nombre del formato';
  FLblNombre.Properties.Transparent := True;
  FMDescripcion := TcxMemo.Create(Self);
  FMDescripcion.Parent := Self;
  FMDescripcion.SetBounds(25, 112, 540, 70);
  FMDescripcion.Properties.MaxLength := 255;
  FLblDescripcion := TcxLabel.Create(Self);
  FLblDescripcion.Parent := Self;
  FLblDescripcion.SetBounds(20, 85, 200, 22);
  FLblDescripcion.Caption := 'Descripción';
  FLblDescripcion.Properties.Transparent := True;
  FCbbAlcance := TcxComboBox.Create(Self);
  FCbbAlcance.Parent := Self;
  FCbbAlcance.SetBounds(25, 217, 350, 27);
  FCbbAlcance.Properties.DropDownListStyle := lsFixedList;
  FLblAlcance := TcxLabel.Create(Self);
  FLblAlcance.Parent := Self;
  FLblAlcance.SetBounds(20, 190, 200, 22);
  FLblAlcance.Caption := 'Quién puede utilizarlo';
  FLblAlcance.Properties.Transparent := True;
  FLblInformacion := TcxLabel.Create(Self);
  FLblInformacion.Parent := Self;
  FLblInformacion.SetBounds(25, 250, 540, 38);
  FLblInformacion.AutoSize := False;
  FLblInformacion.Caption :=
    'El diseño FR3 se guarda en binario en la base de datos y cada ' +
    'modificación conserva una versión auditable.';
  FLblInformacion.Properties.Transparent := True;
  FLblInformacion.Properties.WordWrap := True;
  FBtnGuardar := TcxButton.Create(Self);
  FBtnGuardar.Parent := Self;
  FBtnGuardar.SetBounds(390, 210, 85, 34);
  FBtnGuardar.Caption := 'Guardar';
  FBtnGuardar.OnClick := GuardarClick;
  FBtnCancelar := TcxButton.Create(Self);
  FBtnCancelar.Parent := Self;
  FBtnCancelar.SetBounds(480, 210, 85, 34);
  FBtnCancelar.Caption := 'Cancelar';
  FBtnCancelar.ModalResult := mrCancel;
end;

procedure TfrmModalGuardarListado.AnadirAlcance(
  const ATexto: string;
  const AAlcance: TAlcanceListadoDerivado);
var
  iIndice: Integer;
begin
  iIndice := Length(FAlcances);
  SetLength(FAlcances, iIndice + 1);
  FAlcances[iIndice] := AAlcance;
  FCbbAlcance.Properties.Items.Add(ATexto);
end;

function TfrmModalGuardarListado.Alcance: TAlcanceListadoDerivado;
begin
  if (FCbbAlcance.ItemIndex < 0) or
    (FCbbAlcance.ItemIndex >= Length(FAlcances)) then
  begin
    raise EInvalidOpException.Create(
      'Selecciona el alcance del listado derivado.');
  end;
  Result := FAlcances[FCbbAlcance.ItemIndex];
end;

function TfrmModalGuardarListado.Descripcion: string;
begin
  Result := Trim(FMDescripcion.Text);
end;

procedure TfrmModalGuardarListado.GuardarClick(Sender: TObject);
begin
  if Trim(FTxtNombre.Text) = '' then
  begin
    MessageDlg(
      'Escribe un nombre para el listado derivado.',
      mtWarning,
      [mbOK],
      0);
    FTxtNombre.SetFocus;
  end
  else if FCbbAlcance.ItemIndex < 0 then
  begin
    MessageDlg(
      'Selecciona quién puede utilizar el listado.',
      mtWarning,
      [mbOK],
      0);
    FCbbAlcance.SetFocus;
  end
  else
  begin
    ModalResult := mrOk;
  end;
end;

function TfrmModalGuardarListado.Nombre: string;
begin
  Result := Trim(FTxtNombre.Text);
end;

procedure TfrmModalGuardarListado.Preparar(
  const AUsuario: string;
  const AEmpresa: string;
  const AGrupos: TGruposListadoDerivado;
  const AListado: TListadoDerivado);
var
  oAlcance: TAlcanceListadoDerivado;
  sGrupo: string;
begin
  SetLength(FAlcances, 0);
  FCbbAlcance.Properties.Items.Clear;
  oAlcance := Default(TAlcanceListadoDerivado);
  oAlcance.Alcance := 'USUARIO';
  oAlcance.Usuario := UpperCase(Trim(AUsuario));
  AnadirAlcance('Solo el usuario ' + AUsuario, oAlcance);
  for sGrupo in AGrupos do
  begin
    oAlcance := Default(TAlcanceListadoDerivado);
    oAlcance.Alcance := 'GRUPO';
    oAlcance.Grupo := UpperCase(Trim(sGrupo));
    AnadirAlcance('Grupo ' + sGrupo, oAlcance);
  end;
  oAlcance := Default(TAlcanceListadoDerivado);
  oAlcance.Alcance := 'EMPRESA';
  oAlcance.Empresa := UpperCase(Trim(AEmpresa));
  AnadirAlcance('Empresa ' + AEmpresa, oAlcance);
  oAlcance := Default(TAlcanceListadoDerivado);
  oAlcance.Alcance := 'GLOBAL';
  oAlcance.Empresa := '*';
  AnadirAlcance('Todas las empresas', oAlcance);
  FTxtNombre.Text := AListado.Nombre;
  FMDescripcion.Text := AListado.Descripcion;
  FCbbAlcance.ItemIndex := 0;
  if AListado.Id <> 0 then
  begin
    SeleccionarAlcance(AListado.Alcance);
  end;
end;

procedure TfrmModalGuardarListado.SeleccionarAlcance(
  const AAlcance: TAlcanceListadoDerivado);
var
  bEncontrado: Boolean;
  iIndice: Integer;
begin
  bEncontrado := False;
  iIndice := 0;
  while (iIndice < Length(FAlcances)) and not bEncontrado do
  begin
    bEncontrado :=
      SameText(FAlcances[iIndice].Alcance, AAlcance.Alcance) and
      SameText(FAlcances[iIndice].Empresa, AAlcance.Empresa) and
      SameText(FAlcances[iIndice].Grupo, AAlcance.Grupo) and
      SameText(FAlcances[iIndice].Usuario, AAlcance.Usuario);
    if not bEncontrado then
    begin
      Inc(iIndice);
    end;
  end;
  if bEncontrado then
  begin
    FCbbAlcance.ItemIndex := iIndice;
  end;
end;

end.
