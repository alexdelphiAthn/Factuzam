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
{    Captura de serie y rango de fechas para alta masiva de series por         }
{    empresa en todos los tipos de documento.                                  }
{******************************************************************************}
unit inMtoModalSeriesDocumentos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar,
  inMtoFrmBase;

type
  TfrmModalSeriesDocumentos = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblSerie: TcxLabel;
    txtSerie: TcxTextEdit;
    lblFechaDesde: TcxLabel;
    dteFechaDesde: TcxDateEdit;
    lblFechaHasta: TcxLabel;
    dteFechaHasta: TcxDateEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FSerie: string;
    FFechaDesde: TDateTime;
    FFechaHasta: TDateTime;
  public
    class function Ejecutar(AOwner: TComponent;
                            out ASerie: string;
                            out AFechaDesde: TDateTime;
                            out AFechaHasta: TDateTime): Boolean;
  end;

var
  frmModalSeriesDocumentos: TfrmModalSeriesDocumentos;

implementation

{$R *.dfm}

uses
  inLibMsg;

procedure ForceReferenceToClass(C: TClass);
begin
end;

class function TfrmModalSeriesDocumentos.Ejecutar(
  AOwner: TComponent;
  out ASerie: string;
  out AFechaDesde: TDateTime;
  out AFechaHasta: TDateTime): Boolean;
var
  frm: TfrmModalSeriesDocumentos;
begin
  Result := False;
  ASerie := '';
  AFechaDesde := 0;
  AFechaHasta := 0;
  frm := TfrmModalSeriesDocumentos.Create(AOwner);
  try
    if frm.ShowModal = mrOk then
    begin
      ASerie := frm.FSerie;
      AFechaDesde := frm.FFechaDesde;
      AFechaHasta := frm.FFechaHasta;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeriesDocumentos.FormCreate(Sender: TObject);
var
  iAnio: Word;
  iMes: Word;
  iDia: Word;
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
  DecodeDate(Date, iAnio, iMes, iDia);
  dteFechaDesde.EditValue := EncodeDate(iAnio, 1, 1);
  dteFechaHasta.EditValue := EncodeDate(iAnio, 12, 31);
end;

procedure TfrmModalSeriesDocumentos.actAceptarExecute(Sender: TObject);
var
  sSerie: string;
  dtDesde: TDateTime;
  dtHasta: TDateTime;
begin
  sSerie := Trim(txtSerie.Text);
  if sSerie = '' then
  begin
    MessageDlg(SErrorSerieDocumentoNoIndicada, mtWarning, [mbOk], 0);
    txtSerie.SetFocus;
  end
  else if VarIsNull(dteFechaDesde.EditValue) or
          VarIsEmpty(dteFechaDesde.EditValue) then
  begin
    MessageDlg(SErrorFechaInicioDocumentoNoIndicada,
               mtWarning, [mbOk], 0);
    dteFechaDesde.SetFocus;
  end
  else if VarIsNull(dteFechaHasta.EditValue) or
          VarIsEmpty(dteFechaHasta.EditValue) then
  begin
    MessageDlg(SErrorFechaFinDocumentoNoIndicada,
               mtWarning, [mbOk], 0);
    dteFechaHasta.SetFocus;
  end
  else
  begin
    dtDesde := VarToDateTime(dteFechaDesde.EditValue);
    dtHasta := VarToDateTime(dteFechaHasta.EditValue);
    if dtHasta < dtDesde then
    begin
      MessageDlg(SErrorRangoFechasDocumentoNoValido,
                 mtWarning, [mbOk], 0);
      dteFechaHasta.SetFocus;
    end
    else
    begin
      FSerie := sSerie;
      FFechaDesde := dtDesde;
      FFechaHasta := dtHasta;
      ModalResult := mrOk;
    end;
  end;
end;

procedure TfrmModalSeriesDocumentos.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
