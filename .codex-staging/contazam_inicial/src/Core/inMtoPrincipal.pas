{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipal                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ventana MDI principal y menú único de la aplicación Contazam.             }
{******************************************************************************}
unit inMtoPrincipal;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.Menus,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics, Uni, inMtoFrmBase,
  inLibConfiguracion, inLibRegistroPantallas, Vcl.AppEvnts,
  inLibErroresAplicacion;

const
  PantallaPlanContable = 1;
  PantallaLibroDiario = 2;
  PantallaLibroMayor = 3;
  PantallaContadores = 4;
  PantallaImportarFacturas = 5;
  PantallaEmpresas = 6;
  PantallaEjercicios = 7;
  PantallaArchivoDocumental = 8;
  PantallaListados = 9;
  PantallaSeguridad = 10;

type
  TfrmMtoPrincipal = class(TfrmBase)
  private
    FRegistro: TRegistroPantallasContazam;
    FConfiguracionActiva: TConfiguracionContazam;
    FMenuPrincipal: TMainMenu;
    FMenuContazam: TMenuItem;
    FPnlInicio: TPanel;
    FLblTitulo: TLabel;
    FLblDescripcion: TLabel;
    FPnlContexto: TPanel;
    FLblEmpresa: TLabel;
    FLblEjercicio: TLabel;
    FCbbEmpresa: TComboBox;
    FCbbEjercicio: TComboBox;
    FClavesEmpresas: TStringList;
    FClavesEjercicios: TStringList;
    FAppEvents: TApplicationEvents;
    FGestorErrores: IGestorErroresContazam;
    procedure AppException(Sender: TObject; E: Exception);
    procedure CrearMenu;
    procedure CrearPresentacionInicio;
    procedure CrearSelectorEmpresa;
    procedure CargarEmpresas;
    procedure CargarEjercicios;
    procedure EmpresaCambiada(Sender: TObject);
    procedure EjercicioCambiado(Sender: TObject);
    procedure AnadirOpcionMenu(
      const ATitulo: string;
      AClave: Integer);
    procedure MenuPantallaClick(Sender: TObject);
    procedure MenuSalirClick(Sender: TObject);
    function RecursoPantalla(AClave: Integer): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
    procedure ConfigurarRegistro(
      ARegistro: TRegistroPantallasContazam);
  end;

implementation

procedure TfrmMtoPrincipal.AppException(
  Sender: TObject;
  E: Exception);
begin
  FGestorErrores.Gestionar(Sender, E);
end;

constructor TfrmMtoPrincipal.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Contazam';
  Width := 1280;
  Height := 800;
  Position := poScreenCenter;
  FormStyle := fsMDIForm;
  WindowState := wsMaximized;
  CrearMenu;
  CrearSelectorEmpresa;
  CrearPresentacionInicio;
end;

procedure TfrmMtoPrincipal.AnadirOpcionMenu(
  const ATitulo: string;
  AClave: Integer);
var
  oItem: TMenuItem;
begin
  oItem := TMenuItem.Create(FMenuPrincipal);
  oItem.Caption := ATitulo;
  oItem.Tag := AClave;
  oItem.OnClick := MenuPantallaClick;
  FMenuContazam.Add(oItem);
end;

procedure TfrmMtoPrincipal.ConfigurarRegistro(
  ARegistro: TRegistroPantallasContazam);
begin
  if ARegistro = nil then
  begin
    raise EArgumentNilException.Create('ARegistro');
  end;
  FRegistro := ARegistro;
end;

procedure TfrmMtoPrincipal.CrearMenu;
var
  oSeparador: TMenuItem;
  oSalir: TMenuItem;
begin
  FMenuPrincipal := TMainMenu.Create(Self);
  Menu := FMenuPrincipal;
  FMenuContazam := TMenuItem.Create(FMenuPrincipal);
  FMenuContazam.Caption := '&Contazam';
  FMenuPrincipal.Items.Add(FMenuContazam);
  AnadirOpcionMenu('Empresas', PantallaEmpresas);
  AnadirOpcionMenu('Ejercicios', PantallaEjercicios);
  AnadirOpcionMenu('Plan contable', PantallaPlanContable);
  AnadirOpcionMenu('Libro diario', PantallaLibroDiario);
  AnadirOpcionMenu('Libro mayor', PantallaLibroMayor);
  AnadirOpcionMenu('Contadores', PantallaContadores);
  AnadirOpcionMenu(
    'Archivo documental PDF',
    PantallaArchivoDocumental);
  AnadirOpcionMenu(
    'Importar facturas de Factuzam',
    PantallaImportarFacturas);
  AnadirOpcionMenu('Listados básicos', PantallaListados);
  AnadirOpcionMenu(
    'Usuarios, grupos y permisos',
    PantallaSeguridad);
  oSeparador := TMenuItem.Create(FMenuPrincipal);
  oSeparador.Caption := '-';
  FMenuContazam.Add(oSeparador);
  oSalir := TMenuItem.Create(FMenuPrincipal);
  oSalir.Caption := 'Salir';
  oSalir.OnClick := MenuSalirClick;
  FMenuContazam.Add(oSalir);
end;

procedure TfrmMtoPrincipal.CargarEjercicios;
var
  oConsulta: TUniQuery;
  iSeleccion: Integer;
begin
  FClavesEjercicios.Clear;
  FCbbEjercicio.Items.BeginUpdate;
  try
    FCbbEjercicio.Items.Clear;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := Conexion;
      oConsulta.SQL.Text :=
        'SELECT EJERCICIO_EJE FROM cza_ejercicios ' +
        'WHERE CODIGO_EMP_EJE = :EMPRESA AND ESACTIVO_EJE = ''S'' ' +
        'ORDER BY EJERCICIO_EJE DESC';
      oConsulta.ParamByName('EMPRESA').AsString :=
        FConfiguracionActiva.Empresa;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        FClavesEjercicios.Add(
          oConsulta.FieldByName('EJERCICIO_EJE').AsString);
        FCbbEjercicio.Items.Add(
          oConsulta.FieldByName('EJERCICIO_EJE').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    FCbbEjercicio.Items.EndUpdate;
  end;
  iSeleccion := FClavesEjercicios.IndexOf(
    IntToStr(FConfiguracionActiva.Ejercicio));
  if (iSeleccion < 0) and (FCbbEjercicio.Items.Count > 0) then
  begin
    iSeleccion := 0;
  end;
  FCbbEjercicio.ItemIndex := iSeleccion;
  EjercicioCambiado(FCbbEjercicio);
end;

procedure TfrmMtoPrincipal.CargarEmpresas;
var
  oConsulta: TUniQuery;
  iSeleccion: Integer;
begin
  FClavesEmpresas.Clear;
  FCbbEmpresa.Items.BeginUpdate;
  try
    FCbbEmpresa.Items.Clear;
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := Conexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_EMP, RAZON_SOCIAL_EMP FROM cza_empresas ' +
        'WHERE ESACTIVO_EMP = ''S'' ORDER BY ORDEN_EMP, CODIGO_EMP';
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        FClavesEmpresas.Add(oConsulta.FieldByName('CODIGO_EMP').AsString);
        FCbbEmpresa.Items.Add(
          oConsulta.FieldByName('CODIGO_EMP').AsString + ' - ' +
          oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    FCbbEmpresa.Items.EndUpdate;
  end;
  iSeleccion := FClavesEmpresas.IndexOf(FConfiguracionActiva.Empresa);
  if (iSeleccion < 0) and (FCbbEmpresa.Items.Count > 0) then
  begin
    iSeleccion := 0;
  end;
  FCbbEmpresa.ItemIndex := iSeleccion;
  EmpresaCambiada(FCbbEmpresa);
end;

procedure TfrmMtoPrincipal.CrearSelectorEmpresa;
begin
  FClavesEmpresas := TStringList.Create;
  FClavesEjercicios := TStringList.Create;
  FPnlContexto := TPanel.Create(Self);
  FPnlContexto.Parent := Self;
  FPnlContexto.Align := alTop;
  FPnlContexto.Height := 46;
  FPnlContexto.BevelOuter := bvNone;
  FLblEmpresa := TLabel.Create(Self);
  FLblEmpresa.Parent := FPnlContexto;
  FLblEmpresa.SetBounds(12, 14, 60, 20);
  FLblEmpresa.Caption := 'Empresa';
  FCbbEmpresa := TComboBox.Create(Self);
  FCbbEmpresa.Parent := FPnlContexto;
  FCbbEmpresa.SetBounds(75, 9, 330, 28);
  FCbbEmpresa.Style := csDropDownList;
  FCbbEmpresa.OnChange := EmpresaCambiada;
  FLblEjercicio := TLabel.Create(Self);
  FLblEjercicio.Parent := FPnlContexto;
  FLblEjercicio.SetBounds(425, 14, 65, 20);
  FLblEjercicio.Caption := 'Ejercicio';
  FCbbEjercicio := TComboBox.Create(Self);
  FCbbEjercicio.Parent := FPnlContexto;
  FCbbEjercicio.SetBounds(492, 9, 100, 28);
  FCbbEjercicio.Style := csDropDownList;
  FCbbEjercicio.OnChange := EjercicioCambiado;
end;

destructor TfrmMtoPrincipal.Destroy;
begin
  if RegistroLog <> nil then
  begin
    RegistroLog.RegistrarInformacion('Cierre de la ventana principal.');
  end;
  FGestorErrores := nil;
  FreeAndNil(FClavesEjercicios);
  FreeAndNil(FClavesEmpresas);
  inherited;
end;

procedure TfrmMtoPrincipal.EjercicioCambiado(Sender: TObject);
begin
  if FCbbEjercicio.ItemIndex >= 0 then
  begin
    FConfiguracionActiva.Ejercicio := StrToInt(
      FClavesEjercicios[FCbbEjercicio.ItemIndex]);
  end;
end;

procedure TfrmMtoPrincipal.EmpresaCambiada(Sender: TObject);
begin
  if FCbbEmpresa.ItemIndex >= 0 then
  begin
    FConfiguracionActiva.Empresa :=
      FClavesEmpresas[FCbbEmpresa.ItemIndex];
    CargarEjercicios;
  end;
end;

procedure TfrmMtoPrincipal.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FConfiguracionActiva := AConfiguracion;
  FGestorErrores := CrearGestorErroresContazam(RegistroLog);
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;
  RegistroLog.RegistrarInformacion(
    'Captura global de excepciones activada.');
  CargarEmpresas;
  RegistroLog.RegistrarInformacion('Ventana principal inicializada.');
end;

procedure TfrmMtoPrincipal.CrearPresentacionInicio;
begin
  FPnlInicio := TPanel.Create(Self);
  FPnlInicio.Parent := Self;
  FPnlInicio.Align := alClient;
  FPnlInicio.BevelOuter := bvNone;
  FPnlInicio.Color := $00F4F1EC;
  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := FPnlInicio;
  FLblTitulo.Left := 64;
  FLblTitulo.Top := 72;
  FLblTitulo.Font.Name := 'Lucida Sans';
  FLblTitulo.Font.Size := 28;
  FLblTitulo.Font.Style := [fsBold];
  FLblTitulo.Caption := 'Contazam';
  FLblDescripcion := TLabel.Create(Self);
  FLblDescripcion.Parent := FPnlInicio;
  FLblDescripcion.Left := 68;
  FLblDescripcion.Top := 135;
  FLblDescripcion.Font.Size := 12;
  FLblDescripcion.Caption :=
    'Contabilidad básica, separada de Factuzam y preparada para importar.';
end;

procedure TfrmMtoPrincipal.MenuPantallaClick(Sender: TObject);
var
  oFormulario: TfrmBase;
  iClave: Integer;
begin
  if FRegistro = nil then
  begin
    raise EInvalidOpException.Create(
      'El registro de pantallas no está configurado.');
  end;
  iClave := TMenuItem(Sender).Tag;
  Seguridad.ExigirPermiso(
    RecursoPantalla(iClave),
    'ABRIR',
    FConfiguracionActiva.Empresa);
  FPnlInicio.Visible := False;
  try
    RegistroLog.RegistrarInformacion(
      'Abriendo pantalla ' + RecursoPantalla(iClave) +
      ' para empresa ' + FConfiguracionActiva.Empresa + '.');
    oFormulario := FRegistro.Crear(
      iClave,
      Application,
      Conexion,
      FConfiguracionActiva,
      Seguridad,
      RegistroLog);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarExcepcion(
        'Apertura de ' + RecursoPantalla(iClave),
        E);
      FPnlInicio.Visible := True;
      raise;
    end;
  end;
  oFormulario.Show;
  oFormulario.BringToFront;
end;

function TfrmMtoPrincipal.RecursoPantalla(AClave: Integer): string;
begin
  case AClave of
    PantallaPlanContable:
      Result := 'PLAN_CONTABLE';
    PantallaLibroDiario:
      Result := 'LIBRO_DIARIO';
    PantallaLibroMayor:
      Result := 'LIBRO_MAYOR';
    PantallaContadores:
      Result := 'CONTADORES';
    PantallaImportarFacturas:
      Result := 'IMPORTACION_FACTURAS';
    PantallaEmpresas:
      Result := 'EMPRESAS';
    PantallaEjercicios:
      Result := 'EJERCICIOS';
    PantallaArchivoDocumental:
      Result := 'ARCHIVO_DOCUMENTAL';
    PantallaListados:
      Result := 'LISTADOS';
    PantallaSeguridad:
      Result := 'SEGURIDAD';
  else
    Result := 'PANTALLA';
  end;
end;

procedure TfrmMtoPrincipal.MenuSalirClick(Sender: TObject);
begin
  Close;
end;

end.
