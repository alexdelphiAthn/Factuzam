{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddPreciosTar                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para anadir precios a SKUs en una o varias tarifas.                 }
{    Selecciona rango de fechas, SKUs y tarifas a aplicar.                     }
{******************************************************************************}
unit inMtoModalAddPreciosTar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  JvComponentBase, JvEnterTab,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxClasses,
  cxLocalization, cxContainer, cxEdit, cxButtons, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxCustomListBox, cxCheckListBox,
  inMtoModalAceptCancel, Vcl.ComCtrls, dxCore, cxDateUtils, cxCheckBox;

type
  TfrmMtoModalAddPreciosTar = class(TfrmModalAceptCancel)
    pnlFechas: TPanel;
    lblDesde: TLabel;
    dtpDesde: TcxDateEdit;
    lblHasta: TLabel;
    dtpHasta: TcxDateEdit;
    lblSkus: TLabel;
    chkSkus: TcxCheckListBox;
    lblTarifas: TLabel;
    chkTarifas: TcxCheckListBox;
    procedure FormCreate(Sender: TObject);
  public
    procedure CargarSkus(const ASkus: TStrings);
    procedure CargarTarifas(const ATarifas: TStrings);
    function FechaDesde: TDate;
    function TieneFechaHasta: Boolean;
    function FechaHasta: TDate;
    procedure ObtenerSkusSeleccionados(AOut: TStrings);
    procedure ObtenerTarifasSeleccionadas(AOut: TStrings);
  end;

implementation

{$R *.dfm}

procedure TfrmMtoModalAddPreciosTar.FormCreate(Sender: TObject);
begin
  inherited;
  dtpDesde.Date := Date;
  dtpHasta.Clear;
end;

procedure TfrmMtoModalAddPreciosTar.CargarSkus(const ASkus: TStrings);
var
  i: Integer;
begin
  chkSkus.Items.Clear;
  for i := 0 to ASkus.Count - 1 do
    chkSkus.Items.Add.Text := ASkus[i];
end;

procedure TfrmMtoModalAddPreciosTar.CargarTarifas(const ATarifas: TStrings);
var
  i: Integer;
begin
  chkTarifas.Items.Clear;
  for i := 0 to ATarifas.Count - 1 do
    chkTarifas.Items.Add.Text := ATarifas[i];
end;

function TfrmMtoModalAddPreciosTar.FechaDesde: TDate;
begin
  Result := dtpDesde.Date;
end;

function TfrmMtoModalAddPreciosTar.TieneFechaHasta: Boolean;
begin
  Result := not VarIsNull(dtpHasta.EditValue);
end;

function TfrmMtoModalAddPreciosTar.FechaHasta: TDate;
begin
  Result := dtpHasta.Date;
end;

procedure TfrmMtoModalAddPreciosTar.ObtenerSkusSeleccionados(AOut: TStrings);
var
  i: Integer;
begin
  AOut.Clear;
  for i := 0 to chkSkus.Items.Count - 1 do
    if chkSkus.Items[i].Checked then
      AOut.Add(chkSkus.Items[i].Text);
end;

procedure TfrmMtoModalAddPreciosTar.ObtenerTarifasSeleccionadas(AOut: TStrings);
var
  i: Integer;
begin
  AOut.Clear;
  for i := 0 to chkTarifas.Items.Count - 1 do
    if chkTarifas.Items[i].Checked then
      AOut.Add(chkTarifas.Items[i].Text);
end;

end.
