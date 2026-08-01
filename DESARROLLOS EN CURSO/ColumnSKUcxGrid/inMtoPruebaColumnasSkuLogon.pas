{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPruebaColumnasSkuLogon                                   }
{    Tipo:       Formulario (logon de prueba)                                  }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: logon minimo para el proyecto independiente.      }
{    Pide servidor / puerto / BBDD / usuario / contrasena, conecta via         }
{    UniDAC (provider MySQL, vale para MariaDB) y deja la conexion en          }
{    inLibGlobalVar.oConn, que es donde la esperan el formulario de prueba     }
{    y las librerias reutilizadas (paleta, lookup...).                         }
{                                                                              }
{    Los datos se recuerdan en ColumnSKUcxGridTest.ini junto al exe.           }
{    ATENCION: la contrasena se guarda en claro; es una herramienta de         }
{    prueba, no distribuir.                                                    }
{******************************************************************************}
unit inMtoPruebaColumnasSkuLogon;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IniFiles, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Uni, UniProvider, MySQLUniProvider,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxSpinEdit,
  cxButtons;

type
  TfrmMtoPruebaColumnasSkuLogon = class(TForm)
    lblServidor: TcxLabel;
    txtServidor: TcxTextEdit;
    lblPuerto: TcxLabel;
    spnPuerto: TcxSpinEdit;
    lblBaseDatos: TcxLabel;
    txtBaseDatos: TcxTextEdit;
    lblUsuario: TcxLabel;
    txtUsuario: TcxTextEdit;
    lblPassword: TcxLabel;
    txtPassword: TcxTextEdit;
    btnConectar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
  private
    function RutaIni: string;
    procedure CargarIni;
    procedure GuardarIni;
  public
    // Muestra el logon, conecta y deja inLibGlobalVar.oConn lista.
    // Devuelve False si el usuario cancela.
    class function ConectarBBDD: Boolean;
  end;

var
  frmMtoPruebaColumnasSkuLogon: TfrmMtoPruebaColumnasSkuLogon;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

type
  // Duenyo del handler AfterConnect: debe sobrevivir al logon (el form
  // se libera al cerrar el modal) porque UniDAC re-dispara el evento en
  // cada reconexion y en las conexiones clonadas internas, igual que el
  // conUniAfterConnect del TdmConn de fzam.
  TGestorConexionPrueba = class
  public
    procedure ConexionAfterConnect(Sender: TObject);
  end;

var
  oGestorConexion: TGestorConexionPrueba;

procedure TGestorConexionPrueba.ConexionAfterConnect(Sender: TObject);
var
  Con: TUniConnection;
begin
  if Sender is TUniConnection then
  begin
    Con := TUniConnection(Sender);
    // Colacion de la sesion = la de la BBDD (utf8mb4_spanish_ci). Sin
    // esto la sesion queda en utf8mb3 y cualquier comparacion contra
    // las columnas spanish_ci lanza el #42000 / [1267]. Se reaplica en
    // CADA conexion (tambien clones y reconexiones), como en fzam.
    try
      Con.ExecSQL('SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
    except
      on E: Exception do
        ;
    end;
  end;
end;

class function TfrmMtoPruebaColumnasSkuLogon.ConectarBBDD: Boolean;
var
  Frm: TfrmMtoPruebaColumnasSkuLogon;
begin
  Frm := TfrmMtoPruebaColumnasSkuLogon.Create(nil);
  try
    Result := Frm.ShowModal = mrOk;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmMtoPruebaColumnasSkuLogon.FormCreate(Sender: TObject);
begin
  CargarIni;
end;

function TfrmMtoPruebaColumnasSkuLogon.RutaIni: string;
begin
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

procedure TfrmMtoPruebaColumnasSkuLogon.CargarIni;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIni);
  try
    txtServidor.Text := Ini.ReadString('CONEXION', 'SERVIDOR',
                                       'localhost');
    spnPuerto.Value := Ini.ReadInteger('CONEXION', 'PUERTO', 3306);
    txtBaseDatos.Text := Ini.ReadString('CONEXION', 'BBDD', 'factuzam');
    txtUsuario.Text := Ini.ReadString('CONEXION', 'USUARIO', 'root');
    txtPassword.Text := Ini.ReadString('CONEXION', 'PASSWORD', '');
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TfrmMtoPruebaColumnasSkuLogon.GuardarIni;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(RutaIni);
  try
    Ini.WriteString('CONEXION', 'SERVIDOR', Trim(txtServidor.Text));
    Ini.WriteInteger('CONEXION', 'PUERTO',
                     StrToIntDef(VarToStr(spnPuerto.Value), 3306));
    Ini.WriteString('CONEXION', 'BBDD', Trim(txtBaseDatos.Text));
    Ini.WriteString('CONEXION', 'USUARIO', Trim(txtUsuario.Text));
    // En claro a proposito: herramienta de prueba local.
    Ini.WriteString('CONEXION', 'PASSWORD', txtPassword.Text);
  finally
    FreeAndNil(Ini);
  end;
end;

procedure TfrmMtoPruebaColumnasSkuLogon.btnConectarClick(Sender: TObject);
var
  Conn: TUniConnection;
begin
  // La conexion pertenece a Application: vive lo que dure la prueba.
  Conn := TUniConnection.Create(Application);
  try
    Conn.ProviderName := 'MySQL';
    Conn.Server := Trim(txtServidor.Text);
    Conn.Port := StrToIntDef(VarToStr(spnPuerto.Value), 3306);
    Conn.Database := Trim(txtBaseDatos.Text);
    Conn.Username := Trim(txtUsuario.Text);
    Conn.Password := txtPassword.Text;
    Conn.LoginPrompt := False;
    // Unicode como en produccion (TdmConn de fzam).
    Conn.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    Conn.SpecificOptions.Values['MySQL.Interactive'] := 'True';
    Conn.SpecificOptions.Values['ConnectionTimeout'] := '30';
    // El SET NAMES vive en AfterConnect para que se reaplique en cada
    // reconexion / conexion clonada de UniDAC (ver TGestorConexionPrueba).
    Conn.AfterConnect := oGestorConexion.ConexionAfterConnect;
    Conn.Connect;
    oConn := Conn;
    // Identidad minima de sesion para el ciclo de TfrmMtoGen (perfiles
    // via PRC_GETPERFILFORMULARIO, permisos, restricciones): usuario del
    // logon y comportamiento de root para no recortar nada en la prueba.
    oUser := Trim(txtUsuario.Text);
    oGroup := oUser;
    orootGroup := 'S';
    GuardarIni;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      FreeAndNil(Conn);
      MessageDlg('No se pudo conectar:' + sLineBreak + E.Message,
                 mtError, [mbOK], 0);
    end;
  end;
end;

initialization
  oGestorConexion := TGestorConexionPrueba.Create;

finalization
  FreeAndNil(oGestorConexion);

end.
