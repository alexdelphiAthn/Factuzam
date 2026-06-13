{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuLog                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Log Verifactu.                                                            }
{    Consulta del registro de eventos del subsistema Verifactu                 }
{    (fza_verifactu_eventos): envíos, errores y cadena de hashes.              }
{******************************************************************************}
unit inMtoVerifactuLog;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuLog,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoVerifactuLog = class(TfrmMtoGen)
    cxGrdDBTabPrinID_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIMESTAMP_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_EVENTO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDATOS_ADICIONALES_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinVERSION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_ANTERIOR_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_PROPIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinFIRMA_DIGITAL_LOG: TcxGridDBColumn;
  private
    dmmVerifactuLog: TdmVerifactuLog;
    FBtnIrDoc: TcxButton;
    procedure btnIrDocumentoClick(Sender: TObject);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoVerifactuLog: TfrmMtoVerifactuLog;

implementation

uses
  inLibWin, inMtoPrincipal, inLibShowMto, Vcl.ActnList;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuLog }

procedure TfrmMtoVerifactuLog.CrearTablaPrincipal;
var
  oAct: TAction;
begin
  inherited;
  dmmVerifactuLog := tdmDataModule as TdmVerifactuLog;
  pkFieldName := 'ID_LOG';
  // El registro Verifactu es inalterable: sin alta, edicion ni borrado.
  // Se anula tambien el OnUpdate de las acciones; si no, lo reactivarian
  // en cada ciclo de la ActionList y volverian a quedar habilitadas.
  actInsertarRegistro.OnUpdate := nil;
  actInsertarRegistro.Enabled  := False;
  actEditarRegistro.OnUpdate   := nil;
  actEditarRegistro.Enabled    := False;
  actGrabarRegistro.OnUpdate   := nil;
  actGrabarRegistro.Enabled    := False;
  actEliminarRegistro.OnUpdate := nil;
  actEliminarRegistro.Enabled  := False;
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Edit.Visible   := False;
  nvNavegador.Buttons.Post.Visible   := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  cxGrdDBTabPrin.OptionsData.Editing   := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting  := False;
  cxGrdDBTabPrin.OptionsData.Appending := False;
  // "Ir a Documento": boton + atajos Ctrl+Shift+F / Ctrl+Alt+F que abren
  // la factura de la linea de registro activa (via accion en alMtoGen)
  if not Assigned(FBtnIrDoc) then
  begin
    oAct := TAction.Create(Self);
    oAct.ActionList := alMtoGen;
    oAct.Caption    := 'Ir a Documento';
    oAct.ShortCut   := TextToShortCut('Ctrl+Shift+F');
    oAct.SecondaryShortCuts.Add('Ctrl+Alt+F');
    oAct.OnExecute  := btnIrDocumentoClick;
    FBtnIrDoc := TcxButton.Create(Self);
    FBtnIrDoc.Parent := pButtonGen;
    FBtnIrDoc.Left   := -1;
    FBtnIrDoc.Top    := 8;
    FBtnIrDoc.Width  := 138;
    FBtnIrDoc.Height := 34;
    FBtnIrDoc.Action := oAct;
  end;
end;

procedure TfrmMtoVerifactuLog.btnIrDocumentoClick(Sender: TObject);
var
  ds: TDataSet;
begin
  ds := dsTablaG.DataSet;
  if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    IrADocumentoFactura(ds.FieldByName('NUMERO_FAC_LOG').AsString,
                        ds.FieldByName('SERIE_FAC_LOG').AsString);
end;

procedure TfrmMtoVerifactuLog.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoVerifactuLog);
end.
