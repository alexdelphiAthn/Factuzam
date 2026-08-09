{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSeguridad                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Gestión global de usuarios, grupos, permisos, alcance y auditoría.        }
{******************************************************************************}
unit inMtoSeguridad;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB, Vcl.Controls,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Uni, inMtoFrmBase,
  inLibConfiguracion, UniDataSeguridadMantenimiento, cxGrid,
  cxGridDBTableView, cxGridLevel, cxDBNavigator;

type
  TfrmMtoSeguridad = class(TfrmBase)
  private
    FDataModule: TdmSeguridadMantenimiento;
    FPanelSuperior: TPanel;
    FPaginas: TPageControl;
    FLblInformacion: TLabel;
    FBtnActualizar: TButton;
    FVistas: TList<TcxGridDBTableView>;
    procedure ActualizarClick(Sender: TObject);
    procedure AjustarVistas;
    procedure CrearPestana(
      const ATitulo: string;
      ADataSet: TDataSet;
      AEditable: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils, inLibGridDevExpress;

constructor TfrmMtoSeguridad.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Usuarios, grupos, permisos y alcance';
  Width := 1220;
  Height := 760;
  FVistas := TList<TcxGridDBTableView>.Create;
  FPanelSuperior := TPanel.Create(Self);
  FPanelSuperior.Parent := Self;
  FPanelSuperior.Align := alTop;
  FPanelSuperior.Height := 72;
  FPanelSuperior.BevelOuter := bvNone;
  FBtnActualizar := TButton.Create(Self);
  FBtnActualizar.Parent := FPanelSuperior;
  FBtnActualizar.SetBounds(10, 8, 100, 29);
  FBtnActualizar.Caption := 'Actualizar';
  FBtnActualizar.OnClick := ActualizarClick;
  FLblInformacion := TLabel.Create(Self);
  FLblInformacion.Parent := FPanelSuperior;
  FLblInformacion.SetBounds(125, 10, 1060, 50);
  FLblInformacion.WordWrap := True;
  FLblInformacion.AutoSize := False;
  FPaginas := TPageControl.Create(Self);
  FPaginas.Parent := Self;
  FPaginas.Align := alClient;
end;

procedure TfrmMtoSeguridad.ActualizarClick(Sender: TObject);
begin
  FDataModule.Abrir;
  AjustarVistas;
end;

procedure TfrmMtoSeguridad.AjustarVistas;
var
  oVista: TcxGridDBTableView;
begin
  if Visible then
  begin
    for oVista in FVistas do
    begin
      AjustarColumnasContazam(oVista);
    end;
  end;
end;

procedure TfrmMtoSeguridad.CrearPestana(
  const ATitulo: string;
  ADataSet: TDataSet;
  AEditable: Boolean);
var
  oPestana: TTabSheet;
  oOrigen: TDataSource;
  oNavegador: TcxDBNavigator;
  oNivel: TcxGridLevel;
  oVista: TcxGridDBTableView;
begin
  oPestana := TTabSheet.Create(FPaginas);
  oPestana.PageControl := FPaginas;
  oPestana.Caption := ATitulo;
  oOrigen := TDataSource.Create(Self);
  oOrigen.DataSet := ADataSet;
  if AEditable then
  begin
    oNavegador := TcxDBNavigator.Create(Self);
    oNavegador.Parent := oPestana;
    oNavegador.Align := alTop;
    oNavegador.Height := 30;
    oNavegador.DataSource := oOrigen;
  end;
  CrearGridContazam(
    Self,
    oPestana,
    oOrigen,
    AEditable,
    oVista,
    oNivel);
  FVistas.Add(oVista);
end;

destructor TfrmMtoSeguridad.Destroy;
begin
  FreeAndNil(FDataModule);
  FreeAndNil(FVistas);
  inherited;
end;

procedure TfrmMtoSeguridad.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  Seguridad.ExigirPermisoGlobal('SEGURIDAD', 'ADMINISTRAR');
  FDataModule := TdmSeguridadMantenimiento.Create(
    nil,
    AConexion,
    Seguridad.UsuarioActual);
  CrearPestana('Usuarios', FDataModule.Usuarios, True);
  CrearPestana('Grupos', FDataModule.Grupos, True);
  CrearPestana('Usuarios por grupo', FDataModule.Membresias, True);
  CrearPestana('Permisos y alcance', FDataModule.Permisos, True);
  CrearPestana('Auditoría de listados', FDataModule.Auditoria, False);
  FLblInformacion.Caption :=
    'Usuario actual: ' + Seguridad.UsuarioActual +
    '. Cada permiso combina RECURSO, ACCION y ALCANCE. ' +
    'GLOBAL usa empresa *; EMPRESA usa su código. ' +
    'En los listados las acciones son CONSULTAR y EXPORTAR; ' +
    'puede utilizar * como recurso o acción.';
  FDataModule.Abrir;
  AjustarVistas;
end;

end.
