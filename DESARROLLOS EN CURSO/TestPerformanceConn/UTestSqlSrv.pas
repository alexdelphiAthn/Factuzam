{******************************************************************************}
{                                                                              }
{  Módulo:       UTestSqlSrv                                                   }
{    Tipo:       Formulario VCL (test)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Banco de pruebas independiente para comparar los modos de acceso del      }
{    provider SQL Server de UniDAC:                                            }
{                                                                              }
{      - prDirect       : protocolo TDS por sockets. NO usa COM / OLE DB.      }
{      - prNativeDirect : cliente nativo OLE DB. EXIGE CoInitialize /          }
{                         CoUninitialize en el hilo que abre la conexión.      }
{                                                                              }
{    Cada operación (conectar / lanzar SQL / desconectar) se cronometra con    }
{    TStopwatch y se muestra en milisegundos, para medir y comparar el coste   }
{    de cada modo. Proyecto suelto: sin relación con la migración ni con la    }
{    aplicación principal.                                                     }
{******************************************************************************}
unit UTestSqlSrv;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Classes, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB, Uni, DBAccess, SQLServerUniProvider;

const
  // Valores del SpecificOption "Provider" del provider SQL Server de
  // UniDAC. prDirect habla TDS por sockets (sin COM); prNativeDirect usa
  // el OLE DB nativo y necesita COM inicializado en el hilo.
  cProviderDirect       = 'prDirect';
  cProviderNativeDirect = 'prNativeDirect';

type
  TfrmTestSqlSrv = class(TForm)
    gbConexion:              TGroupBox;
    lblServidor:             TLabel;
    edtServidor:             TEdit;
    lblPuerto:               TLabel;
    edtPuerto:               TEdit;
    lblBase:                 TLabel;
    edtBase:                 TEdit;
    lblUsuario:              TLabel;
    edtUsuario:              TEdit;
    lblClave:                TLabel;
    edtClave:                TEdit;
    chkAutWindows:           TCheckBox;
    pnlBotones:              TPanel;
    btnConectarDirect:       TButton;
    btnConectarNativeDirect: TButton;
    btnLanzarSQL:            TButton;
    btnDesconectar:          TButton;
    pnlTiempo:               TPanel;
    lblTiempo:               TLabel;
    lblEstado:               TLabel;
    gbSQL:                   TGroupBox;
    memoSQL:                 TMemo;
    gbLog:                   TGroupBox;
    memoLog:                 TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConectarDirectClick(Sender: TObject);
    procedure btnConectarNativeDirectClick(Sender: TObject);
    procedure btnLanzarSQLClick(Sender: TObject);
    procedure btnDesconectarClick(Sender: TObject);
  private
    // Campos primero (E2169): conexión única reutilizada en ambos modos,
    // flag de COM inicializado y descripción del modo activo.
    FConn:        TUniConnection;
    FComIniciado: Boolean;
    FModoActual:  string;
    procedure Conectar(const AProvider, ADescripcion: string;
                       AUsaCom: Boolean);
    procedure Desconectar;
    procedure Log(const ATexto: string);
    procedure MostrarTiempo(const AOperacion: string; AMs: Double);
    procedure ActualizarBotones;
  end;

var
  frmTestSqlSrv: TfrmTestSqlSrv;

implementation

{$R *.dfm}

// ===========================================================================
//   Ciclo de vida del formulario
// ===========================================================================

procedure TfrmTestSqlSrv.FormCreate(Sender: TObject);
begin
  // Conexión única; el provider concreto (prDirect / prNativeDirect) se
  // fija en cada conexión vía SpecificOptions.
  FConn := TUniConnection.Create(Self);
  FConn.ProviderName := 'SQL Server';
  FConn.LoginPrompt  := False;
  FComIniciado := False;
  FModoActual  := '';
  ActualizarBotones;
  Log('Listo. Rellena la conexión y pulsa un modo.');
end;

procedure TfrmTestSqlSrv.FormDestroy(Sender: TObject);
begin
  // Cierra y equilibra COM si quedó conectado en modo native.
  Desconectar;
end;

// ===========================================================================
//   Conexión / desconexión cronometradas
// ===========================================================================

procedure TfrmTestSqlSrv.Conectar(const AProvider, ADescripcion: string;
                                  AUsaCom: Boolean);
var
  oReloj:  TStopwatch;
  EsError: Boolean;
  sError:  string;
begin
  // Limpia cualquier conexión previa (y su COM) antes de cambiar de modo.
  Desconectar;
  FConn.Server   := Trim(edtServidor.Text);
  FConn.Port     := StrToIntDef(Trim(edtPuerto.Text), 1433);
  FConn.Database := Trim(edtBase.Text);
  if chkAutWindows.Checked then
  begin
    FConn.SpecificOptions.Values['Authentication'] := 'auWindows';
    FConn.Username := '';
    FConn.Password := '';
  end
  else
  begin
    FConn.SpecificOptions.Values['Authentication'] := 'auServer';
    FConn.Username := Trim(edtUsuario.Text);
    FConn.Password := edtClave.Text;
  end;
  // Modo de acceso del provider (prDirect / prNativeDirect).
  FConn.SpecificOptions.Values['Provider'] := AProvider;
  // prNativeDirect = OLE DB nativo: COM debe estar inicializado en este
  // hilo o UniDAC lanza "CoInitialize has not been called".
  if AUsaCom then
  begin
    CoInitialize(nil);
    FComIniciado := True;
  end;
  EsError := False;
  sError  := '';
  oReloj  := TStopwatch.StartNew;
  try
    FConn.Open;
  except
    on E: Exception do
    begin
      EsError := True;
      sError  := E.Message;
    end;
  end;
  oReloj.Stop;
  if EsError then
  begin
    // Deshacemos el CoInitialize para no dejar COM descompensado.
    if FComIniciado then
    begin
      CoUninitialize;
      FComIniciado := False;
    end;
    Log('ERROR al conectar (' + ADescripcion + '): ' + sError);
    MessageDlg('No se pudo conectar en modo ' + ADescripcion + ':' +
               sLineBreak + sError, mtError, [mbOK], 0);
  end
  else
  begin
    FModoActual := ADescripcion;
    Log('Conectado en modo ' + ADescripcion + '.');
    MostrarTiempo('Conexión ' + ADescripcion,
                  oReloj.Elapsed.TotalMilliseconds);
  end;
  ActualizarBotones;
end;

procedure TfrmTestSqlSrv.Desconectar;
var
  oReloj:    TStopwatch;
  EsAbierta: Boolean;
begin
  EsAbierta := Assigned(FConn) and FConn.Connected;
  if EsAbierta then
  begin
    oReloj := TStopwatch.StartNew;
    FConn.Close;
    oReloj.Stop;
    Log('Desconectado (modo ' + FModoActual + ').');
    MostrarTiempo('Desconexión', oReloj.Elapsed.TotalMilliseconds);
  end;
  // Equilibra el CoInitialize del modo native.
  if FComIniciado then
  begin
    CoUninitialize;
    FComIniciado := False;
  end;
  FModoActual := '';
  ActualizarBotones;
end;

// ===========================================================================
//   Lanzar SQL cronometrada
// ===========================================================================

procedure TfrmTestSqlSrv.btnLanzarSQLClick(Sender: TObject);
var
  oQuery:     TUniQuery;
  oReloj:     TStopwatch;
  sSQL:       string;
  iFilas:     Integer;
  EsConsulta: Boolean;
begin
  sSQL := Trim(memoSQL.Lines.Text);
  if not (Assigned(FConn) and FConn.Connected) then
    MessageDlg('No hay conexión abierta. Conecta primero.',
               mtWarning, [mbOK], 0)
  else if sSQL = '' then
    MessageDlg('Escribe una SQL para lanzar.', mtWarning, [mbOK], 0)
  else
  begin
    // SELECT -> abrir y recorrer; cualquier otra -> ExecSQL.
    EsConsulta := UpperCase(Copy(sSQL, 1, 6)) = 'SELECT';
    oQuery := TUniQuery.Create(nil);
    try
      oQuery.Connection := FConn;
      oQuery.SQL.Text   := sSQL;
      iFilas := 0;
      oReloj := TStopwatch.StartNew;
      try
        if EsConsulta then
        begin
          oQuery.Open;
          // Recorremos todo el resultset para medir el proceso completo.
          while not oQuery.Eof do
          begin
            Inc(iFilas);
            oQuery.Next;
          end;
        end
        else
        begin
          oQuery.ExecSQL;
          iFilas := oQuery.RowsAffected;
        end;
        oReloj.Stop;
        Log(Format('SQL OK (%s): %d filas.', [FModoActual, iFilas]));
        MostrarTiempo('Consulta ' + FModoActual,
                      oReloj.Elapsed.TotalMilliseconds);
      except
        on E: Exception do
        begin
          oReloj.Stop;
          Log('ERROR en SQL: ' + E.Message);
          MessageDlg('Error al lanzar la SQL:' + sLineBreak + E.Message,
                     mtError, [mbOK], 0);
        end;
      end;
    finally
      FreeAndNil(oQuery);
    end;
  end;
end;

// ===========================================================================
//   Handlers de botones
// ===========================================================================

procedure TfrmTestSqlSrv.btnConectarDirectClick(Sender: TObject);
begin
  // prDirect: protocolo TDS por sockets, sin COM.
  Conectar(cProviderDirect, cProviderDirect, False);
end;

procedure TfrmTestSqlSrv.btnConectarNativeDirectClick(Sender: TObject);
begin
  // prNativeDirect: OLE DB nativo, con CoInitialize / CoUninitialize.
  Conectar(cProviderNativeDirect, cProviderNativeDirect, True);
end;

procedure TfrmTestSqlSrv.btnDesconectarClick(Sender: TObject);
begin
  Desconectar;
end;

// ===========================================================================
//   Utilidades de UI
// ===========================================================================

procedure TfrmTestSqlSrv.Log(const ATexto: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + ATexto);
end;

procedure TfrmTestSqlSrv.MostrarTiempo(const AOperacion: string;
                                       AMs: Double);
begin
  lblTiempo.Caption := Format('%s: %.3f ms', [AOperacion, AMs]);
  Log(Format('  > %s: %.3f ms', [AOperacion, AMs]));
end;

procedure TfrmTestSqlSrv.ActualizarBotones;
var
  EsConectado: Boolean;
begin
  EsConectado := Assigned(FConn) and FConn.Connected;
  btnConectarDirect.Enabled       := not EsConectado;
  btnConectarNativeDirect.Enabled := not EsConectado;
  btnLanzarSQL.Enabled            := EsConectado;
  btnDesconectar.Enabled          := EsConectado;
  if EsConectado then
    lblEstado.Caption := 'Estado: CONECTADO (' + FModoActual + ')'
  else
    lblEstado.Caption := 'Estado: desconectado';
end;

end.
