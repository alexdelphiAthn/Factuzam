{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasNormal                                           }
{    Tipo:       Formulario (Mto) descendiente                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de facturas NORMALES (venta mayor).                              }
{    Descendiente de TfrmMtoFacturasBase: solo cambia el filtro TIPO_FAC.      }
{    Las customizaciones de vista (columnas, anchos, orden) van en el .dfm     }
{    propio o en fza_usuarios_perfiles bajo la clave 'frmMtoFacturasNormal'.   }
{******************************************************************************}
unit inMtoFacturasNormal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFacturasBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, Data.DB, cxDBData, cxCalendar,
  cxCurrencyEdit, cxTextEdit, cxCheckBox, cxSpinEdit, cxButtonEdit,
  cxDropDownEdit, cxMemo, cxDBLookupComboBox, cxBlobEdit, cxContainer, cxEdit,
  Vcl.Menus, JvBaseDlg, JvCalc, Vcl.ExtCtrls, dxShellDialogs, System.Actions,
  Vcl.ActnList, JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls,
  cxRadioGroup, cxNavigator, cxDBNavigator, cxSplitter, cxGroupBox, cxDBLabel,
  cxDBEdit, cxImage, Vcl.Buttons, cxLookupEdit, cxDBLookupEdit, cxMaskEdit,
  cxLabel, cxButtons, cxGridBandedTableView, cxGridDBBandedTableView,
  cxGridLevel, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxClasses, cxGridCustomView, cxGrid, cxPC;

type
  TfrmMtoFacturasNormal = class(TfrmMtoFacturasBase)
  public
    function NombreVistaListado: string; override;
    function TipoFacturaFiltro: string; override;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TfrmMtoFacturasNormal.NombreVistaListado: string;
begin
  Result := 'vi_facturas_normales';
end;

function TfrmMtoFacturasNormal.TipoFacturaFiltro: string;
begin
  Result := 'NORMAL';
end;

initialization
  ForceReferenceToClass(TfrmMtoFacturasNormal);
end.
