{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoArchivoDocumental                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta, alta, apertura y exportación del archivo documental PDF.       }
{******************************************************************************}
unit inMtoArchivoDocumental;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Dialogs, inMtoFrmBase, inLibConfiguracion, Uni,
  UniDataArchivoDocumental, cxGrid, cxGridDBTableView, cxGridLevel;

type
  TfrmMtoArchivoDocumental = class(TfrmBase)
  private
    FDataModule: TdmArchivoDocumental;
    FDataSource: TDataSource;
    FPnlBotones: TPanel;
    FBtnAnadir: TButton;
    FBtnAbrir: TButton;
    FBtnGuardarCopia: TButton;
    FBtnActualizar: TButton;
    FGrid: TcxGrid;
    FVista: TcxGridDBTableView;
    FNivel: TcxGridLevel;
    FDialogoAbrir: TOpenDialog;
    FDialogoGuardar: TSaveDialog;
    procedure AnadirClick(Sender: TObject);
    procedure AbrirClick(Sender: TObject);
    procedure GuardarCopiaClick(Sender: TObject);
    procedure ActualizarClick(Sender: TObject);
    procedure CrearInterfaz;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.IOUtils,
  inLibGridDevExpress;

constructor TfrmMtoArchivoDocumental.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Archivo documental PDF';
  Width := 1180;
  Height := 720;
  CrearInterfaz;
end;

procedure TfrmMtoArchivoDocumental.AbrirClick(Sender: TObject);
var
  sCarpetaTemporal: string;
  sRutaTemporal: string;
begin
  sCarpetaTemporal := TPath.Combine(TPath.GetTempPath, 'Contazam');
  ForceDirectories(sCarpetaTemporal);
  sRutaTemporal := TPath.Combine(
    sCarpetaTemporal,
    ChangeFileExt(TPath.GetRandomFileName, '.pdf'));
  FDataModule.GuardarCopiaActual(sRutaTemporal);
  if ShellExecute(
       Handle,
       'open',
       PChar(sRutaTemporal),
       nil,
       nil,
       SW_SHOWNORMAL) <= 32 then
  begin
    raise EOSError.Create(
      'Windows no ha podido abrir el visor PDF predeterminado.');
  end;
end;

procedure TfrmMtoArchivoDocumental.ActualizarClick(Sender: TObject);
begin
  FDataModule.Actualizar;
  AjustarColumnasContazam(FVista);
end;

procedure TfrmMtoArchivoDocumental.AnadirClick(Sender: TObject);
var
  sDescripcion: string;
  sReferencia: string;
begin
  if FDialogoAbrir.Execute then
  begin
    sReferencia := '';
    if InputQuery(
         'Referencia contable',
         'Referencia que se escribirá en el asiento:',
         sReferencia) and
       (Trim(sReferencia) <> '') then
    begin
      sDescripcion := '';
      InputQuery(
        'Descripción',
        'Descripción opcional del documento:',
        sDescripcion);
      FDataModule.ImportarPdf(
        FDialogoAbrir.FileName,
        sReferencia,
        sDescripcion);
      AjustarColumnasContazam(FVista);
    end;
  end;
end;

procedure TfrmMtoArchivoDocumental.CrearInterfaz;
begin
  FDataSource := TDataSource.Create(Self);
  FDialogoAbrir := TOpenDialog.Create(Self);
  FDialogoAbrir.Filter := 'Documentos PDF (*.pdf)|*.pdf';
  FDialogoAbrir.Options := [ofFileMustExist, ofPathMustExist];
  FDialogoGuardar := TSaveDialog.Create(Self);
  FDialogoGuardar.Filter := 'Documentos PDF (*.pdf)|*.pdf';
  FDialogoGuardar.DefaultExt := 'pdf';
  FPnlBotones := TPanel.Create(Self);
  FPnlBotones.Parent := Self;
  FPnlBotones.Align := alTop;
  FPnlBotones.Height := 48;
  FPnlBotones.BevelOuter := bvNone;
  FBtnAnadir := TButton.Create(Self);
  FBtnAnadir.Parent := FPnlBotones;
  FBtnAnadir.SetBounds(8, 9, 120, 29);
  FBtnAnadir.Caption := 'Añadir PDF';
  FBtnAnadir.OnClick := AnadirClick;
  FBtnAbrir := TButton.Create(Self);
  FBtnAbrir.Parent := FPnlBotones;
  FBtnAbrir.SetBounds(136, 9, 120, 29);
  FBtnAbrir.Caption := 'Abrir PDF';
  FBtnAbrir.OnClick := AbrirClick;
  FBtnGuardarCopia := TButton.Create(Self);
  FBtnGuardarCopia.Parent := FPnlBotones;
  FBtnGuardarCopia.SetBounds(264, 9, 130, 29);
  FBtnGuardarCopia.Caption := 'Guardar copia';
  FBtnGuardarCopia.OnClick := GuardarCopiaClick;
  FBtnActualizar := TButton.Create(Self);
  FBtnActualizar.Parent := FPnlBotones;
  FBtnActualizar.SetBounds(402, 9, 100, 29);
  FBtnActualizar.Caption := 'Actualizar';
  FBtnActualizar.OnClick := ActualizarClick;
  FGrid := CrearGridContazam(
    Self,
    Self,
    FDataSource,
    False,
    FVista,
    FNivel);
  FVista.OnDblClick := AbrirClick;
end;

destructor TfrmMtoArchivoDocumental.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoArchivoDocumental.GuardarCopiaClick(Sender: TObject);
begin
  FDialogoGuardar.FileName := FDataModule.NombreArchivoActual;
  if FDialogoGuardar.Execute then
  begin
    FDataModule.GuardarCopiaActual(FDialogoGuardar.FileName);
  end;
end;

procedure TfrmMtoArchivoDocumental.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FDataModule := TdmArchivoDocumental.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  FDataSource.DataSet := FDataModule.Documentos;
  FDataModule.Abrir;
end;

end.
