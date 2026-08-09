{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLibroDiario                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Edición y cierre controlado de asientos del libro diario.                 }
{******************************************************************************}
unit inMtoLibroDiario;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, inMtoFrmBase, inLibConfiguracion, Uni,
  UniDataLibroDiario, cxGrid, cxGridDBTableView, cxGridLevel;

type
  TfrmMtoLibroDiario = class(TfrmBase)
  private
    FDataModule: TdmLibroDiario;
    FDsAsientos: TDataSource;
    FDsLineas: TDataSource;
    FDsContrapartidas: TDataSource;
    FPnlBotones: TPanel;
    FBtnNuevoAsiento: TButton;
    FBtnNuevaLinea: TButton;
    FBtnCerrarAsiento: TButton;
    FBtnReabrirAsiento: TButton;
    FBtnActualizar: TButton;
    FGridAsientos: TcxGrid;
    FGridLineas: TcxGrid;
    FGridContrapartidas: TcxGrid;
    FVistaAsientos: TcxGridDBTableView;
    FVistaLineas: TcxGridDBTableView;
    FVistaContrapartidas: TcxGridDBTableView;
    FNivelAsientos: TcxGridLevel;
    FNivelLineas: TcxGridLevel;
    FNivelContrapartidas: TcxGridLevel;
    FSeparador: TSplitter;
    FSeparadorContrapartidas: TSplitter;
    FPnlContrapartidas: TPanel;
    FLblContrapartidas: TLabel;
    FBtnUsarContrapartida: TButton;
    FPnlEstado: TPanel;
    FLblEstado: TLabel;
    FActualizandoEstado: Boolean;
    procedure NuevoAsientoClick(Sender: TObject);
    procedure NuevaLineaClick(Sender: TObject);
    procedure CerrarAsientoClick(Sender: TObject);
    procedure ReabrirAsientoClick(Sender: TObject);
    procedure ActualizarClick(Sender: TObject);
    procedure AsientoCambiado(Sender: TObject; Field: TField);
    procedure LineaCambiada(Sender: TObject; Field: TField);
    procedure UsarContrapartidaClick(Sender: TObject);
    procedure CrearInterfaz;
    procedure ActualizarEstado;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs,
  inLibContabilidadTipos, inLibGridDevExpress;

constructor TfrmMtoLibroDiario.Create(AOwner: TComponent);
begin
  inherited;
  Caption := 'Libro diario';
  Width := 1200;
  Height := 760;
  CrearInterfaz;
end;

procedure TfrmMtoLibroDiario.ActualizarClick(Sender: TObject);
begin
  FDataModule.Actualizar;
  AjustarColumnasContazam(FVistaAsientos);
  AjustarColumnasContazam(FVistaLineas);
  AjustarColumnasContazam(FVistaContrapartidas);
end;

procedure TfrmMtoLibroDiario.ActualizarEstado;
var
  dDebe: Currency;
  dHaber: Currency;
  oMarca: TBookmark;
  bTieneMarca: Boolean;
begin
  if not FActualizandoEstado then
  begin
    FActualizandoEstado := True;
    try
      dDebe := 0;
      dHaber := 0;
      if FDataModule.Lineas.Active then
      begin
        bTieneMarca := not FDataModule.Lineas.IsEmpty;
        if bTieneMarca then
        begin
          oMarca := FDataModule.Lineas.Bookmark;
        end;
        FDataModule.Lineas.DisableControls;
        try
          FDataModule.Lineas.First;
          while not FDataModule.Lineas.Eof do
          begin
            dDebe := dDebe + FDataModule.Lineas.FieldByName(
              'IMPORTE_DEBE_ASILIN').AsCurrency;
            dHaber := dHaber + FDataModule.Lineas.FieldByName(
              'IMPORTE_HABER_ASILIN').AsCurrency;
            FDataModule.Lineas.Next;
          end;
          if bTieneMarca and
            FDataModule.Lineas.BookmarkValid(oMarca) then
          begin
            FDataModule.Lineas.Bookmark := oMarca;
          end;
        finally
          FDataModule.Lineas.EnableControls;
        end;
      end;
      FLblEstado.Caption := Format(
        'Debe: %.2f €   Haber: %.2f €   Diferencia: %.2f €',
        [dDebe, dHaber, dDebe - dHaber]);
    finally
      FActualizandoEstado := False;
    end;
  end;
end;

procedure TfrmMtoLibroDiario.AsientoCambiado(
  Sender: TObject;
  Field: TField);
begin
  ActualizarEstado;
end;

procedure TfrmMtoLibroDiario.CerrarAsientoClick(Sender: TObject);
var
  oResultado: TResultadoValidacionAsiento;
begin
  oResultado := FDataModule.CerrarAsiento;
  if oResultado.EsValido then
  begin
    MessageDlg(
      'El asiento está cuadrado y se ha cerrado.',
      mtInformation,
      [mbOK],
      0);
  end
  else
  begin
    MessageDlg(oResultado.Mensaje, mtWarning, [mbOK], 0);
  end;
  ActualizarEstado;
end;

procedure TfrmMtoLibroDiario.CrearInterfaz;
begin
  FDsAsientos := TDataSource.Create(Self);
  FDsLineas := TDataSource.Create(Self);
  FDsContrapartidas := TDataSource.Create(Self);
  FPnlBotones := TPanel.Create(Self);
  FPnlBotones.Parent := Self;
  FPnlBotones.Align := alTop;
  FPnlBotones.Height := 48;
  FPnlBotones.BevelOuter := bvNone;
  FBtnNuevoAsiento := TButton.Create(Self);
  FBtnNuevoAsiento.Parent := FPnlBotones;
  FBtnNuevoAsiento.SetBounds(8, 9, 120, 29);
  FBtnNuevoAsiento.Caption := 'Nuevo asiento';
  FBtnNuevoAsiento.OnClick := NuevoAsientoClick;
  FBtnNuevaLinea := TButton.Create(Self);
  FBtnNuevaLinea.Parent := FPnlBotones;
  FBtnNuevaLinea.SetBounds(136, 9, 110, 29);
  FBtnNuevaLinea.Caption := 'Añadir apunte';
  FBtnNuevaLinea.OnClick := NuevaLineaClick;
  FBtnCerrarAsiento := TButton.Create(Self);
  FBtnCerrarAsiento.Parent := FPnlBotones;
  FBtnCerrarAsiento.SetBounds(254, 9, 110, 29);
  FBtnCerrarAsiento.Caption := 'Cerrar asiento';
  FBtnCerrarAsiento.OnClick := CerrarAsientoClick;
  FBtnReabrirAsiento := TButton.Create(Self);
  FBtnReabrirAsiento.Parent := FPnlBotones;
  FBtnReabrirAsiento.SetBounds(372, 9, 120, 29);
  FBtnReabrirAsiento.Caption := 'Reabrir asiento';
  FBtnReabrirAsiento.OnClick := ReabrirAsientoClick;
  FBtnActualizar := TButton.Create(Self);
  FBtnActualizar.Parent := FPnlBotones;
  FBtnActualizar.SetBounds(500, 9, 100, 29);
  FBtnActualizar.Caption := 'Actualizar';
  FBtnActualizar.OnClick := ActualizarClick;
  FPnlEstado := TPanel.Create(Self);
  FPnlEstado.Parent := Self;
  FPnlEstado.Align := alBottom;
  FPnlEstado.Height := 38;
  FPnlEstado.BevelOuter := bvLowered;
  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := FPnlEstado;
  FLblEstado.Left := 12;
  FLblEstado.Top := 10;
  FGridAsientos := CrearGridContazam(
    Self,
    Self,
    FDsAsientos,
    False,
    FVistaAsientos,
    FNivelAsientos);
  FGridAsientos.Align := alTop;
  FGridAsientos.Height := 280;
  FSeparador := TSplitter.Create(Self);
  FSeparador.Parent := Self;
  FSeparador.Align := alTop;
  FGridLineas := CrearGridContazam(
    Self,
    Self,
    FDsLineas,
    True,
    FVistaLineas,
    FNivelLineas);
  FSeparadorContrapartidas := TSplitter.Create(Self);
  FSeparadorContrapartidas.Parent := Self;
  FSeparadorContrapartidas.Align := alRight;
  FPnlContrapartidas := TPanel.Create(Self);
  FPnlContrapartidas.Parent := Self;
  FPnlContrapartidas.Align := alRight;
  FPnlContrapartidas.Width := 360;
  FPnlContrapartidas.Caption := '';
  FLblContrapartidas := TLabel.Create(Self);
  FLblContrapartidas.Parent := FPnlContrapartidas;
  FLblContrapartidas.SetBounds(10, 10, 320, 34);
  FLblContrapartidas.Caption :=
    'Contrapartidas sugeridas por reglas y uso histórico';
  FBtnUsarContrapartida := TButton.Create(Self);
  FBtnUsarContrapartida.Parent := FPnlContrapartidas;
  FBtnUsarContrapartida.SetBounds(10, 43, 170, 29);
  FBtnUsarContrapartida.Caption := 'Añadir seleccionada';
  FBtnUsarContrapartida.OnClick := UsarContrapartidaClick;
  FGridContrapartidas := CrearGridContazam(
    Self,
    FPnlContrapartidas,
    FDsContrapartidas,
    False,
    FVistaContrapartidas,
    FNivelContrapartidas);
  FGridContrapartidas.Align := alBottom;
  FGridContrapartidas.Height := 390;
  FVistaContrapartidas.OnDblClick := UsarContrapartidaClick;
end;

destructor TfrmMtoLibroDiario.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoLibroDiario.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  FDataModule := TdmLibroDiario.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  FDataModule.Abrir;
  LineaCambiada(FDsLineas, nil);
  FDsAsientos.DataSet := FDataModule.Asientos;
  FDsLineas.DataSet := FDataModule.Lineas;
  FDsContrapartidas.DataSet := FDataModule.Contrapartidas;
  FDsAsientos.OnDataChange := AsientoCambiado;
  FDsLineas.OnDataChange := LineaCambiada;
  ActualizarEstado;
  RegistroLog.RegistrarInformacion(
    'Libro diario inicializado correctamente.');
end;

procedure TfrmMtoLibroDiario.LineaCambiada(
  Sender: TObject;
  Field: TField);
var
  sCuenta: string;
begin
  if not FActualizandoEstado then
  begin
    sCuenta := '';
    if FDataModule.Lineas.Active and
       (not FDataModule.Lineas.IsEmpty) then
    begin
      sCuenta := FDataModule.Lineas.FieldByName(
        'CODIGO_CTA_ASILIN').AsString;
    end;
    FDataModule.CargarContrapartidas(sCuenta);
    if Visible then
    begin
      AjustarColumnasContazam(FVistaContrapartidas);
    end;
    ActualizarEstado;
  end;
end;

procedure TfrmMtoLibroDiario.NuevaLineaClick(Sender: TObject);
begin
  FDataModule.CrearLinea;
  FGridLineas.SetFocus;
end;

procedure TfrmMtoLibroDiario.NuevoAsientoClick(Sender: TObject);
var
  sConcepto: string;
begin
  sConcepto := '';
  if InputQuery('Nuevo asiento', 'Concepto:', sConcepto) and
     (Trim(sConcepto) <> '') then
  begin
    FDataModule.CrearAsiento(Date, sConcepto);
    FDataModule.CrearLinea;
    FGridLineas.SetFocus;
  end;
end;

procedure TfrmMtoLibroDiario.ReabrirAsientoClick(Sender: TObject);
begin
  if MessageDlg(
       '¿Quieres reabrir el asiento cerrado para corregirlo?',
       mtConfirmation,
       [mbYes, mbNo],
       0) = mrYes then
  begin
    FDataModule.ReabrirAsiento;
  end;
end;

procedure TfrmMtoLibroDiario.UsarContrapartidaClick(Sender: TObject);
var
  sConcepto: string;
  sCuenta: string;
begin
  if FDataModule.Contrapartidas.Active and
     (not FDataModule.Contrapartidas.IsEmpty) then
  begin
    sCuenta := FDataModule.Contrapartidas.FieldByName(
      'CODIGO_CTA').AsString;
    sConcepto := '';
    if FDataModule.Lineas.Active and
       (not FDataModule.Lineas.IsEmpty) then
    begin
      sConcepto := FDataModule.Lineas.FieldByName(
        'CONCEPTO_ASILIN').AsString;
      if FDataModule.Lineas.State in dsEditModes then
      begin
        FDataModule.Lineas.Post;
      end;
    end;
    FDataModule.CrearLinea;
    FDataModule.Lineas.FieldByName(
      'CODIGO_CTA_ASILIN').AsString := sCuenta;
    FDataModule.Lineas.FieldByName(
      'CONCEPTO_ASILIN').AsString := sConcepto;
    FGridLineas.SetFocus;
  end;
end;

end.
