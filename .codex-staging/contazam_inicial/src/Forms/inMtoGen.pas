{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGen                                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Base visual mínima para mantenimientos tabulares de Contazam.             }
{******************************************************************************}
unit inMtoGen;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  Vcl.StdCtrls,
  inMtoFrmBase, cxGrid, cxGridDBTableView, cxGridLevel,
  cxButtons, cxDBNavigator, cxPC, inLibConfiguracion,
  inLibPerfilesVentana, Uni;

type
  TfrmMtoGen = class(TfrmBase)
  private
    FPanelSuperior: TPanel;
    FBtnActualizar: TButton;
    FDataSource: TDataSource;
    FGridPrincipal: TcxGrid;
    FVistaPrincipal: TcxGridDBTableView;
    FNivelPrincipal: TcxGridLevel;
    FNavegador: TcxDBNavigator;
    FLblEstado: TLabel;
    FPaginas: TcxPageControl;
    FPestanaLista: TcxTabSheet;
    FPestanaFicha: TcxTabSheet;
    FContenedorFicha: TScrollBox;
    FTemporizadorPerfil: TTimer;
    FGestorPerfiles: TGestorPerfilesVentana;
    FBtnGrabarVentana: TcxButton;
    FBtnResetearVentana: TcxButton;
    FFichaCreada: Boolean;
    FPerfilRestaurado: Boolean;
    FHayPerfil: Boolean;
    procedure ActualizarClick(Sender: TObject);
    procedure CrearCampoFicha(AField: TField; var APosicionY: Integer);
    procedure CrearFicha;
    procedure MostrarFicha(Sender: TObject);
    procedure RestaurarPerfilDiferido(Sender: TObject);
    procedure GrabarVentanaClick(Sender: TObject);
    procedure ResetearVentanaClick(Sender: TObject);
    procedure GrabarVentana;
    procedure ResetearVentana;
  protected
    property BtnActualizar: TButton read FBtnActualizar;
    property DataSource: TDataSource read FDataSource;
    property GridPrincipal: TcxGrid read FGridPrincipal;
    property VistaPrincipal: TcxGridDBTableView read FVistaPrincipal;
    property Navegador: TcxDBNavigator read FNavegador;
    property PanelSuperior: TPanel read FPanelSuperior;
    property LblEstado: TLabel read FLblEstado;
    property Paginas: TcxPageControl read FPaginas;
    property PestanaLista: TcxTabSheet read FPestanaLista;
    property PestanaFicha: TcxTabSheet read FPestanaFicha;
    procedure AsignarDataSet(ADataSet: TDataSet);
    procedure AjustarVistaPrincipal;
    procedure ActualizarDatos; virtual;
    procedure DoShow; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.UITypes, Vcl.Dialogs,
  cxLabel, cxTextEdit, cxMemo, cxDBEdit, inLibGridDevExpress,
  UniDataPerfilesVentana;

constructor TfrmMtoGen.Create(AOwner: TComponent);
begin
  inherited;
  Width := 1100;
  Height := 700;
  FDataSource := TDataSource.Create(Self);
  FPanelSuperior := TPanel.Create(Self);
  FPanelSuperior.Parent := Self;
  FPanelSuperior.Align := alTop;
  FPanelSuperior.Height := 45;
  FPanelSuperior.BevelOuter := bvNone;
  FBtnActualizar := TButton.Create(Self);
  FBtnActualizar.Parent := FPanelSuperior;
  FBtnActualizar.AlignWithMargins := True;
  FBtnActualizar.Left := 8;
  FBtnActualizar.Top := 8;
  FBtnActualizar.Width := 100;
  FBtnActualizar.Caption := 'Actualizar';
  FBtnActualizar.OnClick := ActualizarClick;
  FBtnGrabarVentana := TcxButton.Create(Self);
  FBtnGrabarVentana.Parent := FPanelSuperior;
  FBtnGrabarVentana.SetBounds(710, 8, 178, 29);
  FBtnGrabarVentana.Anchors := [akTop, akRight];
  FBtnGrabarVentana.Caption := 'Grabar ventana (Alt+F12)';
  FBtnGrabarVentana.OnClick := GrabarVentanaClick;
  FBtnResetearVentana := TcxButton.Create(Self);
  FBtnResetearVentana.Parent := FPanelSuperior;
  FBtnResetearVentana.SetBounds(896, 8, 190, 29);
  FBtnResetearVentana.Anchors := [akTop, akRight];
  FBtnResetearVentana.Caption := 'Resetear ventana (Ctrl+F12)';
  FBtnResetearVentana.OnClick := ResetearVentanaClick;
  FNavegador := TcxDBNavigator.Create(Self);
  FNavegador.Parent := FPanelSuperior;
  FNavegador.Left := 120;
  FNavegador.Top := 8;
  FNavegador.Width := 260;
  FNavegador.Height := 27;
  FNavegador.DataSource := FDataSource;
  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := FPanelSuperior;
  FLblEstado.Left := 395;
  FLblEstado.Top := 14;
  FLblEstado.Caption := '';
  FPaginas := TcxPageControl.Create(Self);
  FPaginas.Name := 'pcPantalla';
  FPaginas.Parent := Self;
  FPaginas.Align := alClient;
  FPestanaLista := TcxTabSheet.Create(FPaginas);
  FPestanaLista.Name := 'tsLista';
  FPestanaLista.Caption := 'Lista';
  FPestanaLista.PageControl := FPaginas;
  FPestanaFicha := TcxTabSheet.Create(FPaginas);
  FPestanaFicha.Name := 'tsFicha';
  FPestanaFicha.Caption := 'Ficha';
  FPestanaFicha.PageControl := FPaginas;
  FPaginas.ActivePage := FPestanaLista;
  FContenedorFicha := TScrollBox.Create(Self);
  FContenedorFicha.Name := 'scbFicha';
  FContenedorFicha.Parent := FPestanaFicha;
  FContenedorFicha.Align := alClient;
  FContenedorFicha.BorderStyle := bsNone;
  FContenedorFicha.VertScrollBar.Tracking := True;
  FGridPrincipal := CrearGridContazam(
    Self,
    FPestanaLista,
    FDataSource,
    True,
    FVistaPrincipal,
    FNivelPrincipal);
  FGridPrincipal.Name := 'cxgrdPrincipal';
  FVistaPrincipal.Name := 'cxGrdDBTabPrin';
  FNivelPrincipal.Name := 'glPrincipal';
  FVistaPrincipal.OnDblClick := MostrarFicha;
  FTemporizadorPerfil := TTimer.Create(Self);
  FTemporizadorPerfil.Enabled := False;
  FTemporizadorPerfil.Interval := 60;
  FTemporizadorPerfil.OnTimer := RestaurarPerfilDiferido;
end;

procedure TfrmMtoGen.CrearCampoFicha(
  AField: TField;
  var APosicionY: Integer);
var
  bSoloLectura: Boolean;
  oEditorMemo: TcxDBMemo;
  oEditorTexto: TcxDBTextEdit;
  oEtiqueta: TcxLabel;
begin
  oEtiqueta := TcxLabel.Create(Self);
  oEtiqueta.Name := 'lblFicha_' + AField.FieldName;
  oEtiqueta.Parent := FContenedorFicha;
  oEtiqueta.SetBounds(24, APosicionY + 4, 205, 24);
  oEtiqueta.Caption := AField.DisplayLabel;
  oEtiqueta.Transparent := True;
  bSoloLectura := AField.ReadOnly or
    (FDataSource.DataSet = nil) or
    not FDataSource.DataSet.CanModify;
  if AField.DataType in [ftMemo, ftWideMemo] then
  begin
    oEditorMemo := TcxDBMemo.Create(Self);
    oEditorMemo.Name := 'mFicha_' + AField.FieldName;
    oEditorMemo.Parent := FContenedorFicha;
    oEditorMemo.SetBounds(240, APosicionY, 560, 78);
    oEditorMemo.DataBinding.DataSource := FDataSource;
    oEditorMemo.DataBinding.DataField := AField.FieldName;
    oEditorMemo.Properties.ReadOnly := bSoloLectura;
    Inc(APosicionY, 90);
  end
  else
  begin
    oEditorTexto := TcxDBTextEdit.Create(Self);
    oEditorTexto.Name := 'txtFicha_' + AField.FieldName;
    oEditorTexto.Parent := FContenedorFicha;
    oEditorTexto.SetBounds(240, APosicionY, 560, 28);
    oEditorTexto.DataBinding.DataSource := FDataSource;
    oEditorTexto.DataBinding.DataField := AField.FieldName;
    oEditorTexto.Properties.ReadOnly := bSoloLectura;
    Inc(APosicionY, 38);
  end;
end;

procedure TfrmMtoGen.CrearFicha;
var
  iCampo: Integer;
  iPosicionY: Integer;
  oCampo: TField;
begin
  if not FFichaCreada and (FDataSource.DataSet <> nil) and
    FDataSource.DataSet.Active then
  begin
    iPosicionY := 20;
    for iCampo := 0 to FDataSource.DataSet.FieldCount - 1 do
    begin
      oCampo := FDataSource.DataSet.Fields[iCampo];
      if not (oCampo.DataType in
        [ftBlob, ftGraphic, ftOraBlob, ftBytes, ftVarBytes]) then
      begin
        CrearCampoFicha(oCampo, iPosicionY);
      end;
    end;
    FContenedorFicha.VertScrollBar.Range := iPosicionY + 20;
    FFichaCreada := True;
  end;
end;

destructor TfrmMtoGen.Destroy;
begin
  FreeAndNil(FGestorPerfiles);
  inherited;
end;

procedure TfrmMtoGen.DoShow;
begin
  inherited;
  CrearFicha;
  if not FPerfilRestaurado then
  begin
    FTemporizadorPerfil.Enabled := False;
    FTemporizadorPerfil.Enabled := True;
  end;
end;

procedure TfrmMtoGen.GrabarVentana;
begin
  if (FGestorPerfiles <> nil) and
    (MessageDlg(
      '¿Quieres grabar esta ventana y sus columnas para tu usuario?',
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes) then
  begin
    try
      FGestorPerfiles.Guardar(
        Self,
        FVistaPrincipal,
        FPaginas);
      FPerfilRestaurado := True;
      FHayPerfil := True;
      ShowMessage('Ventana grabada. Se aplicará al volver a abrirla.');
    except
      on E: Exception do
      begin
        if RegistroLog <> nil then
        begin
          RegistroLog.RegistrarExcepcion(
            'Grabar ventana ' + ClassName,
            E);
        end;
        MessageDlg(
          'No se pudo grabar la ventana.' + sLineBreak + E.Message,
          mtError,
          [mbOK],
          0);
      end;
    end;
  end;
end;

procedure TfrmMtoGen.GrabarVentanaClick(Sender: TObject);
begin
  GrabarVentana;
end;

procedure TfrmMtoGen.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
var
  oRepositorio: TRepositorioPerfilesVentana;
begin
  inherited;
  oRepositorio := TRepositorioPerfilesVentana.Create(
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.UsuarioAplicacion);
  FGestorPerfiles := TGestorPerfilesVentana.Create(oRepositorio);
end;

procedure TfrmMtoGen.KeyDown(
  var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if (Key = VK_F12) and (ssAlt in Shift) and
    not (ssCtrl in Shift) then
  begin
    GrabarVentana;
    Key := 0;
  end
  else if (Key = VK_F12) and (ssCtrl in Shift) and
    not (ssAlt in Shift) then
  begin
    ResetearVentana;
    Key := 0;
  end;
end;

procedure TfrmMtoGen.MostrarFicha(Sender: TObject);
begin
  CrearFicha;
  FPaginas.ActivePage := FPestanaFicha;
end;

procedure TfrmMtoGen.ResetearVentana;
begin
  if (FGestorPerfiles <> nil) and
    (MessageDlg(
      '¿Quieres resetear la ventana y recuperar sus columnas originales?',
      mtConfirmation,
      [mbYes, mbNo],
      0) = mrYes) then
  begin
    try
      FGestorPerfiles.Resetear(
        Self,
        FVistaPrincipal);
      FPaginas.ActivePage := FPestanaLista;
      FPerfilRestaurado := True;
      FHayPerfil := False;
      ShowMessage('Ventana reseteada.');
    except
      on E: Exception do
      begin
        if RegistroLog <> nil then
        begin
          RegistroLog.RegistrarExcepcion(
            'Resetear ventana ' + ClassName,
            E);
        end;
        MessageDlg(
          'No se pudo resetear la ventana.' + sLineBreak + E.Message,
          mtError,
          [mbOK],
          0);
      end;
    end;
  end;
end;

procedure TfrmMtoGen.ResetearVentanaClick(Sender: TObject);
begin
  ResetearVentana;
end;

procedure TfrmMtoGen.RestaurarPerfilDiferido(Sender: TObject);
begin
  FTemporizadorPerfil.Enabled := False;
  if (FGestorPerfiles <> nil) and not FPerfilRestaurado then
  begin
    try
      FHayPerfil := FGestorPerfiles.Restaurar(
        Self,
        FVistaPrincipal,
        FPaginas);
    except
      on E: Exception do
      begin
        if RegistroLog <> nil then
        begin
          RegistroLog.RegistrarExcepcion(
            'Restaurar ventana ' + ClassName,
            E);
        end;
      end;
    end;
    FPerfilRestaurado := True;
  end;
end;

procedure TfrmMtoGen.ActualizarClick(Sender: TObject);
begin
  ActualizarDatos;
end;

procedure TfrmMtoGen.ActualizarDatos;
begin
  if FDataSource.DataSet <> nil then
  begin
    FDataSource.DataSet.Close;
    FDataSource.DataSet.Open;
    AjustarVistaPrincipal;
  end;
end;

procedure TfrmMtoGen.AsignarDataSet(ADataSet: TDataSet);
begin
  FDataSource.DataSet := ADataSet;
  AjustarVistaPrincipal;
end;

procedure TfrmMtoGen.AjustarVistaPrincipal;
begin
  if Visible then
  begin
    if FPerfilRestaurado and FHayPerfil and
      (FGestorPerfiles <> nil) then
    begin
      FHayPerfil := FGestorPerfiles.Restaurar(
        Self,
        FVistaPrincipal,
        FPaginas);
    end
    else
    begin
      AjustarColumnasContazam(FVistaPrincipal);
    end;
  end;
end;

end.

