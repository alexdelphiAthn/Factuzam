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
    btnEmitirEDoc: TcxButton;
    tsParametrosEDoc: TcxTabSheet;
    cxgrpbxParametrosEDoc: TcxGroupBox;
    lblCodigoOficinaContable: TcxLabel;
    txtCODIGO_OFICINA_CONTABLE_FACTURA: TcxDBTextEdit;
    lblCodigoOrganoGestor: TcxLabel;
    txtCODIGO_ORGANO_GESTOR_FACTURA: TcxDBTextEdit;
    lblCodigoUnidadTramitadora: TcxLabel;
    txtCODIGO_UNIDAD_TRAMITADORA_FACTURA: TcxDBTextEdit;
    lblNombrePersonaCliente: TcxLabel;
    txtNOMBRE_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit;
    lblApellidosPersonaCliente: TcxLabel;
    txtAPELLIDOS_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit;
    procedure btnEmitirEDocClick(Sender: TObject);
  public
    function NombreVistaListado: string; override;
    function TipoFacturaFiltro: string; override;
  end;

implementation

uses
  inLibFacturae,
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function CampoFacturaStr(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if ADataSet <> nil then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := Trim(oCampo.AsString);
  end;
end;

function NifPersonaFisicaFacturae(const ANif: string): Boolean;
var
  i: Integer;
  sNif: string;
  c: Char;
begin
  sNif := '';
  for i := 1 to Length(ANif) do
  begin
    c := UpCase(ANif[i]);
    if CharInSet(c, ['A'..'Z', '0'..'9']) then
      sNif := sNif + c;
  end;
  Result := (sNif <> '') and
            CharInSet(sNif[1], ['0'..'9', 'X', 'Y', 'Z']);
end;

function FaltanDatosPersonaFisicaFacturae(ADataSet: TDataSet): Boolean;
begin
  Result := NifPersonaFisicaFacturae(
    CampoFacturaStr(ADataSet, 'NIF_CLIENTE_FAC'));
  if Result then
    Result := (CampoFacturaStr(ADataSet,
                 'NOMBRE_PERSONA_CLIENTE_FAC') = '') or
              (CampoFacturaStr(ADataSet,
                 'APELLIDOS_PERSONA_CLIENTE_FAC') = '');
end;

procedure TfrmMtoFacturasNormal.btnEmitirEDocClick(Sender: TObject);
var
  oDialogo: TSaveDialog;
  oResultado: TFacturaeResultado;
  sSerie: string;
  sNumero: string;
begin
  if (dsTablaG.DataSet = nil) or
     (not dsTablaG.DataSet.Active) or
     dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage('Seleccione un borrador de venta mayor.');
    Abort;
  end;
  if (dsTablaG.DataSet.State = dsInsert) or
     (dsTablaG.DataSet.State = dsEdit) then
  begin
    ShowMessage('Guarde los cambios antes de emitir el eDoc.');
    Abort;
  end;
  if FaltanDatosPersonaFisicaFacturae(dsTablaG.DataSet) then
  begin
    pcPantalla.ActivePage := tsFicha;
    pcCab.ActivePage := tsParametrosEDoc;
    ShowMessage('El cliente tiene NIF/NIE de persona física.' + sLineBreak +
      'Rellene nombre y apellidos en Parámetros eDoc antes de emitir.');
    if txtNOMBRE_PERSONA_CLIENTE_FACTURA.CanFocus then
      txtNOMBRE_PERSONA_CLIENTE_FACTURA.SetFocus;
    Abort;
  end;
  sSerie := dsTablaG.DataSet.FieldByName('SERIE_FAC').AsString;
  sNumero := dsTablaG.DataSet.FieldByName('NUMERO_FAC').AsString;
  oDialogo := TSaveDialog.Create(Self);
  try
    oDialogo.Title := 'Emitir eDoc';
    oDialogo.Filter := 'Facturae firmado (*.xsig)|*.xsig|XML (*.xml)|*.xml';
    oDialogo.DefaultExt := 'xsig';
    oDialogo.FileName := NombreArchivoFacturae(sSerie, sNumero);
    if oDialogo.Execute then
    begin
      oResultado := EmitirFacturae(inLibGlobalVar.oConn, sSerie, sNumero,
        oDialogo.FileName);
      dsTablaG.DataSet.Refresh;
      ShowMessage('eDoc emitido correctamente:' + sLineBreak +
        oResultado.Archivo);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

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
