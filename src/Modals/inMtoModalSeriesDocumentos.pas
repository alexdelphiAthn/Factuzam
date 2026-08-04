{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeriesDocumentos                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Captura de ubicación y serie tokenizada para el alta masiva de series   }
{    de empresa en todos los tipos de documento.                              }
{******************************************************************************}
unit inMtoModalSeriesDocumentos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ActnList, System.Actions, Data.DB,
  DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  inMtoFrmBase;

type
  TfrmModalSeriesDocumentos = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxLookupComboBox;
    lblCaja: TcxLabel;
    cbbCaja: TcxLookupComboBox;
    lblSerieTokenizada: TcxLabel;
    txtSerieTokenizada: TcxTextEdit;
    lblLeyendaTokens: TcxLabel;
    lblLeyendaSubtipos: TcxLabel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryCajas: TUniQuery;
    dsCajas: TDataSource;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
  private
    FAlmacen: string;
    FCaja: string;
    FSerieTokenizada: string;
    procedure CargarCajas;
    function EsSerieTokenizadaValida(
      const ASerieTokenizada: string): Boolean;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      out AAlmacen: string;
      out ACaja: string;
      out ASerieTokenizada: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibCadenas, inLibMsgComun;

procedure ForceReferenceToClass(C: TClass);
begin
end;

class function TfrmModalSeriesDocumentos.Ejecutar(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  out AAlmacen: string;
  out ACaja: string;
  out ASerieTokenizada: string): Boolean;
var
  frm: TfrmModalSeriesDocumentos;
begin
  Result := False;
  AAlmacen := '';
  ACaja := '';
  ASerieTokenizada := '';
  frm := TfrmModalSeriesDocumentos.Create(AOwner);
  try
    frm.unqryAlmacenes.Connection := AConexion;
    frm.unqryCajas.Connection := AConexion;
    frm.unqryAlmacenes.ParamByName('EMPRESA').AsString := AEmpresa;
    frm.unqryAlmacenes.Open;
    if not frm.unqryAlmacenes.IsEmpty then
    begin
      frm.cbbAlmacen.EditValue := frm.unqryAlmacenes.FieldByName(
        'CODIGO_ALM_ALM').AsString;
    end;
    if frm.ShowModal = mrOk then
    begin
      AAlmacen := frm.FAlmacen;
      ACaja := frm.FCaja;
      ASerieTokenizada := frm.FSerieTokenizada;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeriesDocumentos.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalSeriesDocumentos.actAceptarExecute(Sender: TObject);
var
  sAlmacen: string;
  sCaja: string;
  sSerieTokenizada: string;
begin
  sAlmacen := Trim(VarToStr(cbbAlmacen.EditValue));
  sCaja := Trim(VarToStr(cbbCaja.EditValue));
  sSerieTokenizada := Trim(txtSerieTokenizada.Text);
  if sAlmacen = '' then
  begin
    MessageDlg(
      SErrorAlmacenSerieTokenizadaNoIndicado,
      mtWarning,
      [mbOk],
      0);
    cbbAlmacen.SetFocus;
  end
  else if sCaja = '' then
  begin
    MessageDlg(
      SErrorCajaSerieTokenizadaNoIndicada,
      mtWarning,
      [mbOk],
      0);
    cbbCaja.SetFocus;
  end
  else if sSerieTokenizada = '' then
  begin
    MessageDlg(
      SErrorSerieDocumentoNoIndicada,
      mtWarning,
      [mbOk],
      0);
    txtSerieTokenizada.SetFocus;
  end
  else if not EsSerieTokenizadaValida(sSerieTokenizada) then
  begin
    MessageDlg(
      Format(SErrorSerieTokenizadaEmpresa, [sSerieTokenizada]),
      mtWarning,
      [mbOk],
      0);
    txtSerieTokenizada.SetFocus;
  end
  else
  begin
    FAlmacen := sAlmacen;
    FCaja := sCaja;
    FSerieTokenizada := sSerieTokenizada;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalSeriesDocumentos.CargarCajas;
var
  sAlmacen: string;
begin
  sAlmacen := Trim(VarToStr(cbbAlmacen.EditValue));
  cbbCaja.EditValue := Null;
  unqryCajas.Close;
  if sAlmacen <> '' then
  begin
    unqryCajas.ParamByName('ALMACEN').AsString := sAlmacen;
    unqryCajas.Open;
    if not unqryCajas.IsEmpty then
    begin
      cbbCaja.EditValue := unqryCajas.FieldByName(
        'CODIGO_CAJA_ALMCAJ').AsString;
    end;
  end;
end;

procedure TfrmModalSeriesDocumentos.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  CargarCajas;
end;

function TfrmModalSeriesDocumentos.EsSerieTokenizadaValida(
  const ASerieTokenizada: string): Boolean;
var
  iDias: Integer;
  iEjercicios: Integer;
  iMeses: Integer;
  iTrimestres: Integer;
begin
  iEjercicios := ContarOcurrenciasAnsi(ASerieTokenizada, 'yyyy');
  iTrimestres := ContarOcurrenciasAnsi(ASerieTokenizada, 'q');
  iMeses := ContarOcurrenciasAnsi(ASerieTokenizada, 'mm');
  iDias := ContarOcurrenciasAnsi(ASerieTokenizada, 'dd');
  Result := (iEjercicios <= 1) and
            (iTrimestres <= 1) and
            (iMeses <= 1) and
            (iDias <= 1) and
            (iEjercicios + iTrimestres + iMeses + iDias > 0);
end;

procedure TfrmModalSeriesDocumentos.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
