{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeleccionarBanco                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selección manual de la cuenta bancaria de la empresa al generar un        }
{    efecto de pago (compras, uso PAGO/cargo) o un recibo de cobro (ventas,    }
{    uso COBRO/ingreso). Lista las cuentas activas de la empresa desde         }
{    vi_empresas_bancos y preselecciona la marcada por defecto según el uso.   }
{    Si la empresa no tiene cuentas, informa y deja seguir sin banco.          }
{******************************************************************************}
unit inMtoModalSeleccionarBanco;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid;

type
  // Uso de la cuenta: cobro (ingreso de ventas) o pago (cargo de compras).
  TUsoBancoEmpresa = (ubeCobro, ubePago);

  TSeleccionBancoResult = record
    Aceptado:      Boolean;
    CodigoEmpban:  string;
    Iban:          string;
    Entidad:       string;
    Oficina:       string;
    DigitoControl: string;
    Cuenta:        string;
    Nombre:        string;
    NombreBanco:   string;
  end;

  TfrmModalSeleccionarBanco = class(TfrmBase)
    pnlInfo:      TPanel;
    lblInfo:      TcxLabel;
    pnlGrid:      TPanel;
    cxgrdBancos:  TcxGrid;
    tvBancos:     TcxGridDBTableView;
    lvlBancos:    TcxGridLevel;
    colNombre:    TcxGridDBColumn;
    colIban:      TcxGridDBColumn;
    colBanco:     TcxGridDBColumn;
    colCobro:     TcxGridDBColumn;
    colPago:      TcxGridDBColumn;
    pnlButton:    TPanel;
    btnCancelar:  TcxButton;
    btnAceptar:   TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure tvBancosDblClick(Sender: TObject);
  private
    // Campos primero (E2169).
    FConn:      TUniConnection;
    FQry:       TUniQuery;
    FDs:        TDataSource;
    FEmpresa:   string;
    FUso:       TUsoBancoEmpresa;
    FResultado: TSeleccionBancoResult;
    procedure CargarCuentas;
  public
    class function Ejecutar(
      AOwner               : TComponent;
      AConn                : TUniConnection;
      const ACodigoEmpresa : string;
      AUso                 : TUsoBancoEmpresa;
      const APreferEmpban  : string = ''): TSeleccionBancoResult;
  end;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalSeleccionarBanco.Ejecutar(
  AOwner               : TComponent;
  AConn                : TUniConnection;
  const ACodigoEmpresa : string;
  AUso                 : TUsoBancoEmpresa;
  const APreferEmpban  : string): TSeleccionBancoResult;
var
  frm: TfrmModalSeleccionarBanco;
begin
  frm := TfrmModalSeleccionarBanco.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := ACodigoEmpresa;
    frm.FUso     := AUso;
    frm.CargarCuentas;
    if frm.FQry.IsEmpty then
    begin
      // Sin cuentas activas: se informa y se sigue sin banco asignado.
      ShowMessage('La empresa no tiene cuentas bancarias activas. ' +
                  'El documento se generará sin banco de empresa asignado.');
      frm.FResultado.Aceptado := True;
    end
    else
    begin
      // Pre-selecciona el banco por defecto del proveedor/cliente si se pasa
      // y pertenece a la empresa; si no, queda el ESDEFECTO segun el uso.
      if (APreferEmpban <> '') then
        frm.FQry.Locate('CODIGO_EMPBAN', APreferEmpban, []);
      frm.ShowModal;
    end;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeleccionarBanco.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aceptado := False;
  FQry := TUniQuery.Create(Self);
  FDs  := TDataSource.Create(Self);
  FDs.DataSet := FQry;
  tvBancos.DataController.DataSource := FDs;
end;

procedure TfrmModalSeleccionarBanco.CargarCuentas;
var
  sColDef: string;
begin
  if not Assigned(FConn) then
    FConn := oConn;
  if FUso = ubePago then
  begin
    sColDef := 'ESDEFECTO_PAGO_EMPBAN';
    lblInfo.Caption := 'Cuenta de la empresa para el PAGO (cargo) de los ' +
                       'efectos:';
  end
  else
  begin
    sColDef := 'ESDEFECTO_COBRO_EMPBAN';
    lblInfo.Caption := 'Cuenta de la empresa para el COBRO (ingreso) de los ' +
                       'recibos:';
  end;
  FQry.Close;
  FQry.Connection := FConn;
  // La cuenta por defecto del uso queda la primera (DESC) -> preseleccionada.
  FQry.SQL.Text :=
    'SELECT * ' +
    '  FROM vi_empresas_bancos ' +
    ' WHERE CODIGO_EMP_EMPBAN = :emp ' +
    '   AND COALESCE(ESACTIVO_EMPBAN, ''S'') = ''S'' ' +
    ' ORDER BY ' + sColDef + ' DESC, NOMBRE_EMPBAN';
  FQry.ParamByName('emp').AsString := FEmpresa;
  FQry.Open;
end;

procedure TfrmModalSeleccionarBanco.btnAceptarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := True;
  if not FQry.IsEmpty then
  begin
    FResultado.CodigoEmpban  := FQry.FieldByName('CODIGO_EMPBAN').AsString;
    FResultado.Iban          := FQry.FieldByName('IBAN_EMPBAN').AsString;
    FResultado.Entidad       := FQry.FieldByName('ENTIDAD_EMPBAN').AsString;
    FResultado.Oficina       := FQry.FieldByName('OFICINA_EMPBAN').AsString;
    FResultado.DigitoControl :=
                          FQry.FieldByName('DIGITO_CONTROL_EMPBAN').AsString;
    FResultado.Cuenta        := FQry.FieldByName('CUENTA_EMPBAN').AsString;
    FResultado.Nombre        := FQry.FieldByName('NOMBRE_EMPBAN').AsString;
    FResultado.NombreBanco   :=
                          FQry.FieldByName('NOMBRE_BAN_VIEW_EMPBAN').AsString;
  end;
  ModalResult := mrOk;
end;

procedure TfrmModalSeleccionarBanco.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := False;
  ModalResult := mrCancel;
end;

procedure TfrmModalSeleccionarBanco.tvBancosDblClick(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

initialization
  ForceReferenceToClass(TfrmModalSeleccionarBanco);
end.
