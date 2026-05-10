{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Modal: Calcular margen comercial                }
{       (a partir del precio de coste, margen y         }
{        ajustes de redondeo, calcula el precio de      }
{        salida y lo persiste en el artículo-tarifa)    }
{                                                       }
{*******************************************************}

unit inMtoModalCalcularMargen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxGraphics, cxStyles, cxLocalization,
  cxLabel, cxButtons, cxTextEdit, cxMaskEdit,
  cxCurrencyEdit,
  Vcl.Menus, dxCore, dxSkinsForm,
  JvComponentBase, JvEnterTab;

type
  TCalcularMargenResult = record
    Aceptado              : Boolean;
    PorcentajeMargen      : Double;
    ValorMultiploAjuste   : Double;
    ValorMenosAjuste      : Double;
    PrecioSalidaCalculado : Double;
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
    lblMultiplo: TcxLabel;
    edtMultiplo: TcxCurrencyEdit;
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
    FConn               : TUniConnection;
    FCodigoUnicoArttar  : Integer;
    FResultado          : TCalcularMargenResult;

    function  CalcularPrecioSalida: Double;
    function  PersistirCambios(out AMensaje: string): Boolean;

  public
    class function Ejecutar(
      AOwner             : TComponent;
      AConn              : TUniConnection;
      ACodigoUnicoArttar : Integer;
      const ACodigoArt   : string;
      const ADescArt     : string;
      const ACodigoTar   : string;
      const ANombreTar   : string;
      const ADescSku     : string;
      ACoste             : Double;
      APrecioSalidaAct   : Double;
      APorcenMargenIni   : Double;
      AMultiploIni       : Double;
      AMenosIni          : Double): TCalcularMargenResult;
  end;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

// ============================================================================
//   API pública
// ============================================================================

class function TfrmModalCalcularMargen.Ejecutar(
  AOwner             : TComponent;
  AConn              : TUniConnection;
  ACodigoUnicoArttar : Integer;
  const ACodigoArt   : string;
  const ADescArt     : string;
  const ACodigoTar   : string;
  const ANombreTar   : string;
  const ADescSku     : string;
  ACoste             : Double;
  APrecioSalidaAct   : Double;
  APorcenMargenIni   : Double;
  AMultiploIni       : Double;
  AMenosIni          : Double): TCalcularMargenResult;
var
  frm: TfrmModalCalcularMargen;
begin
  frm := TfrmModalCalcularMargen.Create(AOwner);
  try
    frm.FConn              := AConn;
    frm.FCodigoUnicoArttar := ACodigoUnicoArttar;

    frm.edtArticulo.Text   := ACodigoArt + ' - ' + ADescArt;
    frm.edtTarifa.Text     := ACodigoTar + ' - ' + ANombreTar;
    if ADescSku = '' then
      frm.edtSku.Text := '(sin SKU)'
    else
      frm.edtSku.Text := ADescSku;

    frm.edtCoste.Value         := ACoste;
    frm.edtPrecioActual.Value  := APrecioSalidaAct;
    frm.edtMargen.Value        := APorcenMargenIni;
    frm.edtMultiplo.Value      := AMultiploIni;
    frm.edtMenos.Value         := AMenosIni;
    frm.RecalcularPrecioSalida(nil);

    frm.ShowModal;
    Result := frm.FResultado;
  finally
    frm.Free;
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
    ShowMessage('No se puede calcular el margen: el precio de coste debe ser distinto de cero.');
    Exit;
  end;

  if edtMargen.Value < 0 then
  begin
    ShowMessage('El margen no puede ser negativo.');
    Exit;
  end;

  if edtMultiplo.Value < 0 then
  begin
    ShowMessage('El múltiplo de ajuste no puede ser negativo.');
    Exit;
  end;

  FResultado.PorcentajeMargen      := edtMargen.Value;
  FResultado.ValorMultiploAjuste   := edtMultiplo.Value;
  FResultado.ValorMenosAjuste      := edtMenos.Value;
  FResultado.PrecioSalidaCalculado := CalcularPrecioSalida;

  if FCodigoUnicoArttar > 0 then
  begin
    if not PersistirCambios(msg) then
    begin
      ShowMessage('No se han podido guardar los cambios: ' + msg);
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
  bruto, multiplo, menos: Double;
begin
  Result := 0;
  if edtCoste.Value <= 0 then Exit;

  // precio = coste * (1 + margen/100)
  // Si margen = 120: coste*2.20  (duplica + 20 %)
  // Si margen = 100: coste*2     (duplica)
  // Si margen = 50:  coste*1.5
  bruto := edtCoste.Value * (1 + edtMargen.Value / 100);

  multiplo := edtMultiplo.Value;
  if multiplo > 0 then
    bruto := Round(bruto / multiplo) * multiplo;

  menos := edtMenos.Value;
  bruto := bruto - menos;
  if bruto < 0 then
    bruto := 0;

  Result := Round(bruto * 100) / 100;
end;

// ============================================================================
//   Persistencia
// ============================================================================

function TfrmModalCalcularMargen.PersistirCambios(out AMensaje: string): Boolean;
var
  upd: TUniQuery;
begin
  Result   := False;
  AMensaje := '';

  upd := TUniQuery.Create(nil);
  try
    upd.Connection := FConn;
    upd.SQL.Text :=
      'UPDATE fza_articulos_tarifas SET ' +
      '  PORCENTAJE_MARGEN_ARTTAR     = :p_margen, ' +
      '  VALOR_MULTIPLO_AJUSTE_ARTTAR = :p_multiplo, ' +
      '  VALOR_MENOS_AJUSTE_ARTTAR    = :p_menos, ' +
      '  PRECIO_SALIDA_ARTTAR         = :p_salida, ' +
      '  USUARIO_MODIF                = :p_usuario, ' +
      '  INSTANTE_MODIF               = NOW() ' +
      'WHERE CODIGO_UNICO_ARTTAR = :p_unico';

    upd.ParamByName('p_margen').AsFloat   := FResultado.PorcentajeMargen;
    upd.ParamByName('p_multiplo').AsFloat := FResultado.ValorMultiploAjuste;
    upd.ParamByName('p_menos').AsFloat    := FResultado.ValorMenosAjuste;
    upd.ParamByName('p_salida').AsFloat   := FResultado.PrecioSalidaCalculado;
    upd.ParamByName('p_usuario').AsString := oUser;
    upd.ParamByName('p_unico').AsInteger  := FCodigoUnicoArttar;

    try
      upd.Execute;
      Result := True;
    except
      on E: Exception do
        AMensaje := E.Message;
    end;
  finally
    upd.Free;
  end;
end;

end.
