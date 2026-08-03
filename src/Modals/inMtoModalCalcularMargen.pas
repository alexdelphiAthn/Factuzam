{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCalcularMargen                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para calcular el margen comercial de un articulo o SKU.             }
{    Persiste coste y precio de salida al aceptar.                             }
{******************************************************************************}
unit inMtoModalCalcularMargen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Uni, inMtoFrmBase, inLibMargenPersistenciaIntf,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxGraphics, cxStyles, cxLocalization,
  cxLabel, cxButtons, cxTextEdit, cxMaskEdit, cxCurrencyEdit,
  Vcl.Menus, dxCore, dxSkinsForm,
  JvComponentBase, JvEnterTab;

type
  TCalcularMargenResult = record
    Aceptado            : Boolean;
    PrecioCoste         : Double;
    PrecioSalidaFinal   : Double;
  end;

  TfrmModalCalcularMargen = class(TfrmBase)
    pnlBody: TPanel;
    pnlButtons: TPanel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;

    lblArticulo: TcxLabel;
    edtArticulo: TcxTextEdit;
    lblTarifa: TcxLabel;
    edtTarifa: TcxTextEdit;
    lblSku: TcxLabel;
    edtSku: TcxTextEdit;

    lblCoste: TcxLabel;
    edtCoste: TcxCurrencyEdit;

    lblMargen: TcxLabel;
    edtMargen: TcxCurrencyEdit;
    lblAjuste: TcxLabel;
    edtAjuste: TcxCurrencyEdit;
    lblMenos: TcxLabel;
    edtMenos: TcxCurrencyEdit;

    lblPrecioActual: TcxLabel;
    edtPrecioActual: TcxCurrencyEdit;
    lblPrecioCalc: TcxLabel;
    edtPrecioCalc: TcxCurrencyEdit;

    lblFormula: TcxLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure RecalcularPrecioSalida(Sender: TObject);

  private
    FCodigoUnicoArttar  : Integer;
    FCodigoArtArt       : string;
    FCodigoUnidadArttar : string;
    FResultado          : TCalcularMargenResult;
    FRepositorio        : IRepositorioMargen;

    function  CalcularPrecioSalida: Double;
    function  PersistirCambios(out AMensaje: string): Boolean;

  public
    class function Ejecutar(
      AOwner                    : TComponent;
      AConn                     : TUniConnection;
      ACodigoUnicoArttar        : Integer;
      const ACodigoArt          : string;
      const ACodigoUnidadArttar : string;
      const ADescArt            : string;
      const ACodigoTar          : string;
      const ANombreTar          : string;
      const ADescSku            : string;
      ACoste                    : Double;
      APrecioSalidaAct          : Double): TCalcularMargenResult;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos, UniDataConfiguracionPantalla;

// ============================================================================
//   API pública
// ============================================================================

class function TfrmModalCalcularMargen.Ejecutar(
  AOwner                    : TComponent;
  AConn                     : TUniConnection;
  ACodigoUnicoArttar        : Integer;
  const ACodigoArt          : string;
  const ACodigoUnidadArttar : string;
  const ADescArt            : string;
  const ACodigoTar          : string;
  const ANombreTar          : string;
  const ADescSku            : string;
  ACoste                    : Double;
  APrecioSalidaAct          : Double): TCalcularMargenResult;
var
  frm: TfrmModalCalcularMargen;
begin
  frm := TfrmModalCalcularMargen.Create(AOwner);
  try
    frm.FCodigoUnicoArttar  := ACodigoUnicoArttar;
    frm.FCodigoArtArt       := ACodigoArt;
    frm.FCodigoUnidadArttar := ACodigoUnidadArttar;
    ComponerConfiguracionPantalla(
      frm,
      AConn,
      frm.FRepositorio);

    frm.edtArticulo.Text   := ACodigoArt + ' - ' + ADescArt;
    frm.edtTarifa.Text     := ACodigoTar + ' - ' + ANombreTar;
    if Trim(ADescSku) = '' then
      frm.edtSku.Text := '(sin SKU)'
    else
      frm.edtSku.Text := ADescSku;

    frm.edtCoste.Value         := ACoste;
    frm.edtPrecioActual.Value  := APrecioSalidaAct;
    // Cálculo inverso: si hay coste y precio salida actuales, deduce el
    // margen implícito (con ajuste 0 y menos 0 como punto de partida) para
    // que el modal abra ya cuadrado con la situación actual.
    frm.edtAjuste.Value        := 0;
    frm.edtMenos.Value         := 0;
    if (ACoste > 0) and (APrecioSalidaAct > 0) then
      frm.edtMargen.Value := (APrecioSalidaAct / ACoste) * 100
    else
      frm.edtMargen.Value := 100;
    frm.RecalcularPrecioSalida(nil);

    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

// ============================================================================
//   Eventos
// ============================================================================

procedure TfrmModalCalcularMargen.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aceptado := False;
end;

procedure TfrmModalCalcularMargen.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmModalCalcularMargen.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalCalcularMargen.btnAceptarClick(Sender: TObject);
var
  msg: string;
begin
  inherited;

  if edtCoste.Value <= 0 then
  begin
    ShowMessage(SErrorPrecioCosteMargenNoValido);
    Exit;
  end;

  if edtMargen.Value <= 0 then
  begin
    ShowMessage(SErrorMargenNoValido);
    Exit;
  end;

  if edtAjuste.Value < 0 then
  begin
    ShowMessage(SErrorAjusteMargenNoValido);
    Exit;
  end;

  FResultado.PrecioCoste       := edtCoste.Value;
  FResultado.PrecioSalidaFinal := CalcularPrecioSalida;

  if FCodigoUnicoArttar > 0 then
  begin
    if not PersistirCambios(msg) then
    begin
      ShowMessage(SErrorGuardarCambiosMargen + msg);
      Exit;
    end;
  end;

  FResultado.Aceptado := True;
  Close;
end;

procedure TfrmModalCalcularMargen.RecalcularPrecioSalida(Sender: TObject);
begin
  edtPrecioCalc.Value := CalcularPrecioSalida;
end;

// ============================================================================
//   Cálculo
// ============================================================================

function TfrmModalCalcularMargen.CalcularPrecioSalida: Double;
var
  bruto, ajuste, menos: Double;
begin
  Result := 0;
  if edtCoste.Value <= 0 then Exit;
  if edtMargen.Value <= 0 then Exit;

  // precio = coste * margen / 100
  // margen 100 -> coste tal cual; 120 -> coste*1.20; 250 -> coste*2.50; 400 ->
  // coste*4
  bruto := edtCoste.Value * edtMargen.Value / 100;

  ajuste := edtAjuste.Value;
  if ajuste > 0 then
    // Redondea hacia arriba al siguiente múltiplo del ajuste
    bruto := Ceil(bruto / ajuste) * ajuste;

  menos := edtMenos.Value;
  bruto := bruto - menos;
  if bruto < 0 then
    bruto := 0;

  Result := Round(bruto * 100) / 100;
end;

// ============================================================================
//   Persistencia
// ============================================================================

function TfrmModalCalcularMargen.PersistirCambios(
  out AMensaje: string): Boolean;
var
  oSolicitud: TSolicitudPersistenciaMargen;
  oResultado: TResultadoPersistenciaMargen;
begin
  AMensaje := '';
  oSolicitud.CodigoUnicoTarifa := FCodigoUnicoArttar;
  oSolicitud.CodigoArticulo := FCodigoArtArt;
  oSolicitud.CodigoUnidad := FCodigoUnidadArttar;
  oSolicitud.Usuario := IdentidadSesion.Usuario;
  oSolicitud.PrecioCoste := FResultado.PrecioCoste;
  oSolicitud.PrecioSalida := FResultado.PrecioSalidaFinal;
  oResultado := FRepositorio.Guardar(oSolicitud);
  Result := oResultado.Guardado;
  if oResultado.FaltaProveedorPrincipal then
  begin
    AMensaje := SErrorProveedorPrincipalCosteNoAsignado;
  end
  else if oResultado.MensajeError <> '' then
  begin
    AMensaje := oResultado.MensajeError;
  end;
end;

end.
