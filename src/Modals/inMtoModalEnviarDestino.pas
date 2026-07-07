{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEnviarDestino                                       }
{    Tipo:       Modal                                                         }
{ Version:       1.0.0                                                        }
{   Fecha:       07/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal generico de destino de documento para el "Enviar a..." de           }
{    Documentos de Trabajo (y futuros): almacen y serie en combos              }
{    (fza_almacenes / fza_empresas_series por tipo de documento) y             }
{    numero editable (por defecto '0' = lo asigna el contador del Mto          }
{    destino al grabar).                                                       }
{******************************************************************************}
unit inMtoModalEnviarDestino;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtons;

type
  TfrmModalEnviarDestino = class(TForm)
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxComboBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxComboBox;
    lblNumero: TcxLabel;
    txtNumero: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
  public
    // Devuelve True si el usuario acepta; AAlm/ASerie/ANumero entran
    // como valores por defecto y salen con lo elegido.
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const ATitulo, AEmpresa,
                                  ATipoDocSerie: string;
                            var AAlm, ASerie, ANumero: string): Boolean;
  end;

implementation

{$R *.dfm}

class function TfrmModalEnviarDestino.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection; const ATitulo, AEmpresa,
  ATipoDocSerie: string; var AAlm, ASerie, ANumero: string): Boolean;
var
  frm: TfrmModalEnviarDestino;
  q: TUniQuery;
begin
  Result := False;
  frm := TfrmModalEnviarDestino.Create(AOwner);
  q := TUniQuery.Create(nil);
  try
    frm.Caption := ATitulo;
    q.Connection := AConn;
    // Almacenes (de la empresa si viene informada).
    q.SQL.Text :=
      'SELECT CODIGO_ALM_ALM FROM fza_almacenes ' +
      'WHERE (:EMP = '''' OR CODIGO_EMP_ALM = :EMP) ' +
      'ORDER BY CODIGO_ALM_ALM';
    q.ParamByName('EMP').AsString := AEmpresa;
    q.Open;
    while not q.Eof do
    begin
      frm.cbbAlmacen.Properties.Items.Add(
        q.FieldByName('CODIGO_ALM_ALM').AsString);
      q.Next;
    end;
    q.Close;
    frm.cbbAlmacen.ItemIndex :=
      frm.cbbAlmacen.Properties.Items.IndexOf(AAlm);
    if (frm.cbbAlmacen.ItemIndex < 0) and
       (frm.cbbAlmacen.Properties.Items.Count > 0) then
      frm.cbbAlmacen.ItemIndex := 0;
    // Series del tipo de documento destino, vigentes.
    q.SQL.Text :=
      'SELECT EMPSER FROM fza_empresas_series ' +
      'WHERE CODIGO_EMP_EMPSER = :EMP ' +
      '  AND TIPO_DOC_EMPSER = :TIPO ' +
      '  AND (FECHA_DESDE_EMPSER IS NULL OR ' +
      '       FECHA_DESDE_EMPSER <= NOW()) ' +
      '  AND (FECHA_HASTA_EMPSER IS NULL OR ' +
      '       FECHA_HASTA_EMPSER >= NOW()) ' +
      'ORDER BY EMPSER';
    q.ParamByName('EMP').AsString := AEmpresa;
    q.ParamByName('TIPO').AsString := ATipoDocSerie;
    q.Open;
    while not q.Eof do
    begin
      frm.cbbSerie.Properties.Items.Add(
        q.FieldByName('EMPSER').AsString);
      q.Next;
    end;
    q.Close;
    frm.cbbSerie.ItemIndex :=
      frm.cbbSerie.Properties.Items.IndexOf(ASerie);
    if (frm.cbbSerie.ItemIndex < 0) and
       (frm.cbbSerie.Properties.Items.Count > 0) then
      frm.cbbSerie.ItemIndex := 0;
    if ANumero = '' then
      frm.txtNumero.Text := '0'
    else
      frm.txtNumero.Text := ANumero;
    if frm.ShowModal = mrOk then
    begin
      AAlm := Trim(frm.cbbAlmacen.Text);
      ASerie := Trim(frm.cbbSerie.Text);
      ANumero := Trim(frm.txtNumero.Text);
      Result := (AAlm <> '') and (ASerie <> '') and (ANumero <> '');
      if not Result then
        ShowMessage('Almacén, serie y número son obligatorios.');
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(frm);
  end;
end;

end.
