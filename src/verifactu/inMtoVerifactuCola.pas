{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuCola                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       13/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de envíos Verifactu.                                                 }
{    Consulta del estado de fza_verifactu_cola (pendientes, enviadas y         }
{    errores del envío de registros de facturación a la AEAT). La cola la      }
{    alimenta el sistema (inLibVerifactuCola): aquí solo se edita el estado    }
{    (e intentos / próximo intento) en el grid, sin insertar ni borrar filas   }
{    y sin ficha de detalle. Ctrl+Alt+F / Ctrl+Mayús+F y el botón lateral      }
{    "Ir a Documento" saltan a la factura, normal o simplificada, resuelta     }
{    automáticamente según su TIPO_FAC.                                        }
{******************************************************************************}
unit inMtoVerifactuCola;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuCola,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, System.Actions, Vcl.ActnList;

type
  TfrmMtoVerifactuCola = class(TfrmMtoGen)
    cxGrdDBTabPrinID_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinCONTADOR_INTENTOS_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_PROXIMO_INTENTO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ENVIO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinMENSAJE_ERROR_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    btnIrADocumento: TcxButton;
    // Salta a la factura de la fila activa (lo dispara el botón lateral y los
    // atajos Ctrl+Alt+F / Ctrl+Mayús+F). ResolverCallFactura mira el TIPO_FAC
    // en fza_facturas y abre Facturas o FacturasSimplif según corresponda, así
    // se llega a la correcta sin saber el tipo de antemano.
    procedure btnIrADocumentoClick(Sender: TObject);
  private
    dmmVerifactuCola: TdmVerifactuCola;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoVerifactuCola: TfrmMtoVerifactuCola;

implementation

uses
  inLibWin, inMtoPrincipal, inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuCola }

procedure TfrmMtoVerifactuCola.CrearTablaPrincipal;
var
  actDoc: TAction;
begin
  inherited;
  dmmVerifactuCola := tdmDataModule as TdmVerifactuCola;
  pkFieldName := 'ID_VFCOLA';
  // La cola la alimenta el sistema (inLibVerifactuCola.EncolarFactura) y el
  // data module solo define SQLUpdate (estado / intentos / próximo intento):
  // no se permite insertar ni borrar filas a mano, solo editar el estado.
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  // Anular también los atajos heredados Ins (insertar) y Ctrl+Supr (borrar).
  actInsertarRegistro.ShortCut  := 0;
  actInsertarRegistro.OnExecute := nil;
  actEliminarRegistro.ShortCut  := 0;
  actEliminarRegistro.OnExecute := nil;
  // Atajos "Ir a Documento" creados en código y colgados de alMtoGen (lo
  // recorre inMtoPrincipal.IsShortCut). Dos acciones para los dos atajos:
  // Ctrl+Alt+F y Ctrl+Mayús+F. Ambas reusan el handler del botón lateral.
  actDoc := TAction.Create(Self);
  actDoc.ActionList := alMtoGen;
  actDoc.ShortCut   := ShortCut(Ord('F'), [ssCtrl, ssAlt]);
  actDoc.OnExecute  := btnIrADocumentoClick;
  actDoc := TAction.Create(Self);
  actDoc.ActionList := alMtoGen;
  actDoc.ShortCut   := ShortCut(Ord('F'), [ssCtrl, ssShift]);
  actDoc.OnExecute  := btnIrADocumentoClick;
end;

procedure TfrmMtoVerifactuCola.btnIrADocumentoClick(Sender: TObject);
var
  sSerie, sNumero, sCall: string;
  ds: TDataSet;
begin
  inherited;
  ds := dsTablaG.DataSet;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
  begin
    sSerie  := ds.FieldByName('SERIE_FAC_VFCOLA').AsString;
    sNumero := ds.FieldByName('NUMERO_FAC_VFCOLA').AsString;
    sCall   := ResolverCallFactura(ConexionPrincipal,sNumero, sSerie);
    ShowMto(Self.Owner, sCall, sNumero + ',' + sSerie);
  end;
end;

procedure TfrmMtoVerifactuCola.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoVerifactuCola);
end.
