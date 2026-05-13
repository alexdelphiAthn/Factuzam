{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEtiqArt                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       12/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de etiquetas de articulo / SKU.                        }
{    Permite elegir tarifa, fecha de aplicacion y uno o varios almacenes       }
{    para filtrar el stock que entra en la impresion.                          }
{    Persiste la geometria del formulario via inLibLayoutForm.                 }
{******************************************************************************}
unit inMtoModalEtiqArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni, frxExportXLSX, frxClass,
  frxExportBaseDialog, frxExportPDF, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, Vcl.ExtCtrls, dxSkinsCore, dxSkinBlue, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxLabel, cxGroupBox,
  cxRadioGroup, cxDropDownEdit, cxDateUtils, cxCalendar, cxListView,
  cxCheckBox, ComCtrls, UniDataArticulos, inMtoArticulos, inLibLayoutForm,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization, frLanguageSpanish,
  dxCore, System.Actions, Vcl.ActnList, frxExportBaseImageSettingsDialog,
  frCoreClasses;

type
  TfrmPrintEtiqArt = class(TfrmPrint)
    pnlOpciones: TPanel;
    cxlblTarifa: TcxLabel;
    cbbTarifa: TcxComboBox;
    cxlblFecha: TcxLabel;
    dtFechaAplicacion: TcxDateEdit;
    cxlblAlmacenes: TcxLabel;
    lvAlmacenes: TcxListView;
    cxlblArticulo: TcxLabel;
    edtCodArt: TcxTextEdit;
    chkSoloEsteArt: TcxCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FCodigosTarifa: TStringList;
    FLayout: TLayoutLoader;
    procedure RestaurarLayout;
    procedure GuardarLayout;
    function ObtenerCodigoTarifa: string;
    function ObtenerAlmacenesCsv: string;
  public
    procedure preparar_consulta; override;
  end;

var
  frmPrintEtiqArt: TfrmPrintEtiqArt;

implementation

{$R *.dfm}

procedure TfrmPrintEtiqArt.FormCreate(Sender: TObject);
var
  Idx: Integer;
begin
  inherited;
  FCodigosTarifa := TStringList.Create;
  FLayout        := TLayoutLoader.Create(Self.Name);
  // Carga tarifas en cbbTarifa y deja seleccionada la marcada por defecto.
  Idx := -1;
  dmmArticulos.CargarTarifasEtiquetas(cbbTarifa.Properties.Items,
                                      FCodigosTarifa, Idx);
  if Idx >= 0 then
    cbbTarifa.ItemIndex := Idx;
  // Carga almacenes activos en la lista multi-seleccion.
  dmmArticulos.CargarAlmacenesEtiquetas(lvAlmacenes);
  dtFechaAplicacion.Date := Date;
end;

procedure TfrmPrintEtiqArt.FormShow(Sender: TObject);
begin
  inherited;
  RestaurarLayout;
end;

procedure TfrmPrintEtiqArt.FormDestroy(Sender: TObject);
begin
  FLayout.Free;
  FCodigosTarifa.Free;
  inherited;
end;

procedure TfrmPrintEtiqArt.FormKeyDown(Sender: TObject; var Key: Word;
                                                        Shift: TShiftState);
begin
  // Alt+F12 dispara la grabacion de la personalizacion, igual que en
  // inMtoConsultaOpe.
  if (Key = VK_F12) and (ssAlt in Shift) then
    GuardarLayout;
end;

procedure TfrmPrintEtiqArt.RestaurarLayout;
begin
  if not FLayout.Disponible then Exit;
  FLayout.RestaurarGeometria(Self);
end;

procedure TfrmPrintEtiqArt.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(Self.Name);
  try
    Layout.GuardarGeometria(Self);
    if Layout.PreguntarYGrabar('Personalizacion Impresion Etiquetas Articulo')
      then ShowMessage('Layout guardado.');
  finally
    Layout.Free;
  end;
end;

function TfrmPrintEtiqArt.ObtenerCodigoTarifa: string;
begin
  Result := '';
  if (cbbTarifa.ItemIndex >= 0) and
     (cbbTarifa.ItemIndex < FCodigosTarifa.Count) then
    Result := FCodigosTarifa[cbbTarifa.ItemIndex];
end;

function TfrmPrintEtiqArt.ObtenerAlmacenesCsv: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lvAlmacenes.Items.Count - 1 do
    if lvAlmacenes.Items[i].Checked then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + lvAlmacenes.Items[i].Caption;
    end;
end;

procedure TfrmPrintEtiqArt.preparar_consulta;
var
  sCodArt: string;
begin
  if ObtenerCodigoTarifa = '' then
  begin
    ShowMessage('Seleccione una tarifa antes de imprimir.');
    Abort;
  end;
  // chkSoloEsteArt limita a un unico articulo. Si esta sin marcar la consulta
  // ataca a todos los articulos activos del catalogo.
  sCodArt := '';
  if chkSoloEsteArt.Checked then
    sCodArt := Trim(edtCodArt.Text);
  dmmArticulos.CrearDataSetEtiquetasArt(sCodArt,
                                        ObtenerCodigoTarifa,
                                        ObtenerAlmacenesCsv,
                                        dtFechaAplicacion.Date);
end;

end.
