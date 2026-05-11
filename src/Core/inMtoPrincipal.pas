unit inMtoPrincipal;

{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipal                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    Principal de entrada al programa donde está el menú con todas las opcio-  }
{    nes disponibles. Guarda estructuras como Conexión a BBDD.                 }
{******************************************************************************}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, SynEditHighlighter,
  SynHighlighterSQL,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, inMtoFrmBase, UniDataConn,
  UniDataPerfiles, cxLocalization, Vcl.Buttons, inLibUnitForm, JvMenus,
  System.UITypes, DAScript, Uni, dxShellDialogs, dxSkinsCore, dxSkinBlue,
  JvComponentBase, JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue, inLibFormManager, System.Actions,
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar, SynEdit,
  Backup.Engine, Backup.Types, Providers_MySQL, Providers_MySQL_Helpers,
  ScriptWriters, Core_Interfaces, Core_Helpers, UniScript, System.Diagnostics;

const
  WM_FREECONTROL = WM_USER;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(TfrmBase)
    mnuCaja: TMenuItem;
    mnuMenuCaja: TMenuItem;
    mnuAlmacenes: TMenuItem;
    mnuCajaParam: TMenuItem;
    JvStatusBar1: TJvStatusBar;
    saveDialog: TFileSaveDialog;
    openDialog: TFileOpenDialog;
    mnuParmetrosdeEntorno: TMenuItem;
    N2: TMenuItem;
    Compras1: TMenuItem;
    FormasdePagoCaja1: TMenuItem;
    mnuFormaPagoVenta: TMenuItem;
    Pedidos1: TMenuItem;
    Albaranes1: TMenuItem;
    Facturas1: TMenuItem;
    Sesiones1: TMenuItem;
    CrearArtculosyunpedidoounalbarn1: TMenuItem;
    Formasdepago2: TMenuItem;
    dxSkinController1: TdxSkinController;
    mnuAlmacen: TMenuItem;
    Movimientosdealmacn1: TMenuItem;
    mnuInventarios: TMenuItem;
    mnuPropiedades: TMenuItem;
    mnuVariaciones: TMenuItem;
    mnuAtributosConjuntos: TMenuItem;
    mnuCajaPagosHist: TMenuItem;
    mnuCajaValesHist: TMenuItem;
    mnuCajaOperacionesHist: TMenuItem;
    mnuDepositosCliente: TMenuItem;
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuAlmacenesClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuFormaPagoVentaClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
    procedure mnuInventariosClick(Sender: TObject);
    procedure mnuPropiedadesClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVariacionesClick(Sender: TObject);
    procedure mnuAtributosConjuntosClick(Sender: TObject);
    procedure mnuCajaPagosHistClick(Sender: TObject);
    procedure mnuCajaValesHistClick(Sender: TObject);
    procedure mnuCajaOperacionesHistClick(Sender: TObject);
    procedure Movimientosdealmacn1Click(Sender: TObject);
    procedure mnuDepositosClienteClick(Sender: TObject);
  published
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    EditStyleController: TcxEditStyleController;
    LookAndFeelController1: TcxLookAndFeelController;
    Panel1: TPanel;
    pcPrincipal: TcxPageControl;
    pnlPPBottom: TPanel;
    cxMemo1: TcxMemo;
    jvMnMenuPrin: TJvMainMenu;
    Archivo1: TMenuItem;
    Ventas1: TMenuItem;
    Utilidades1: TMenuItem;
    Ayuda1: TMenuItem;
    mnuEmpresas: TMenuItem;
    mnuClientes: TMenuItem;
    mnuProveedores: TMenuItem;
    mnuArticulos: TMenuItem;
    mnuFacturas: TMenuItem;
    ablasAuxiliares1: TMenuItem;
    mnuTarifas: TMenuItem;
    mnuFamilias: TMenuItem;
    Salir1: TMenuItem;
    mnuGruposdeIVA: TMenuItem;
    mnuIvas: TMenuItem;
    mnuContadores: TMenuItem;
    mnuPaises: TMenuItem;
    N1: TMenuItem;
    UsuariosGruposyPerfiles1: TMenuItem;
    HacerCopiadeSeguridad1: TMenuItem;
    mnuEjecutarScript: TMenuItem;
    mnuGeneradorProcesos: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuGrupos: TMenuItem;
    mnuPerfiles: TMenuItem;
    Acercade1: TMenuItem;
    Listados1: TMenuItem;
    mnuLisVentas: TMenuItem;
    mnuPedidosVenta: TMenuItem;
    mnuAlbaranesVenta: TMenuItem;
    procedure mnuPedidosVentaClick(Sender: TObject);
    procedure mnuAlbaranesVentaClick(Sender: TObject);
    procedure mnuEmpresasClick(Sender: TObject);
    procedure mnuClientesClick(Sender: TObject);
    procedure mnuProveedoresClick(Sender: TObject);
    procedure mnuArticulosClick(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnuFamiliasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure mnuFacturasClick(Sender: TObject);
    procedure mnuGruposdeIVAClick(Sender: TObject);
    procedure mnuIvasClick(Sender: TObject);
    procedure mnuContadoresClick(Sender: TObject);
    procedure mnuUsuariosClick(Sender: TObject);
    procedure mnuGruposClick(Sender: TObject);
    procedure mnuPerfilesClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure mnuGeneradorProcesosClick(Sender: TObject);
    procedure mnuPaisesClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
//    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
//      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_USER + 1;
    procedure LogFormClose(Sender: TObject; var Action: TCloseAction);
  private
    FIdleCount: Integer;
    FException: Boolean;
    FStopwatch: TStopwatch;
    FLogForm: TForm;
    FLogMemo: TSynEdit;
    FSavedNCM: TNonClientMetrics;
    FSavedNCMValid: Boolean;
    // procedure AppException(Sender: TObject; E: Exception);
    function CopiaSeguridad: Boolean;
//    procedure SetMenuFont(const AFontName: string; ASize: Integer);
    procedure SetSystemMenuFont(const AFontName: string; ASize: Integer);
    function ContieneDDL(const ASQL: string): Boolean;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure UniScript1Error(Sender: TObject; E: Exception; SQL: string;
                              var Action: TErrorAction);
    procedure ScriptAfterExecute(Sender: TObject;
                                 SQL: string);
    procedure ScriptBeforeExecute(Sender: TObject;
                                  var SQL: string;
                                  var Omit: Boolean);
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
    FDmConn: TdmConn;
    FdmDataPerfiles: TdmPerfiles;
    oFzaWinf: TfzaWinF;
  end;

var
  frmMtoPrincipal: TfrmMtoPrincipal;
  bIsConnected: Boolean;

implementation

uses inLibUser,
  inLibWin,
  inLibShowMto,
  inLibtb,
  inLibGlobalVar,
  inLibLog,
  inLibDir,
  inMtoSplash,
  inMtoAppParam,
  inMtoCajaMenu,
  inMtoCajaParam,
  inMtoModalGenFilter,
  inMtoModalScriptLog,
  inLibCajaParam,
  inLibAppParam,
  inLibBuscarImpresora,
  System.RegularExpressions;

{$R *.dfm}

procedure TfrmMtoPrincipal.LogFormClose(Sender: TObject;
                                        var Action: TCloseAction);
begin
  Action := caFree;
  FLogForm := nil;
  FLogMemo := nil;
end;

procedure TfrmMtoPrincipal.ScriptBeforeExecute(Sender: TObject;
                                               var SQL: string;
                                               var Omit: Boolean);
var
  TempList: TStringList;
begin
  FLogMemo.Lines.Add(' -- Ejecutando (' +
                                   FormatDateTime('hh:nn:ss.zzz', Now) + '): ');
  TempList := TStringList.Create;
  try
    TempList.Text := SQL;
    FLogMemo.Lines.AddStrings(TempList);
  finally
    TempList.Free;
  end;
  FLogMemo.SelStart := Length(FLogMemo.Text);
  SendMessage(FLogMemo.Handle, EM_SCROLLCARET, 0, 0);
  Application.ProcessMessages;
  FStopwatch := TStopwatch.StartNew;
end;

procedure TfrmMtoPrincipal.ScriptAfterExecute(Sender: TObject; SQL: string);
begin
  FStopwatch.Stop;
  if Assigned(FLogMemo) then
  begin
    FLogMemo.Lines.Add(Format(' -- [OK] Filas afectadas: %d | Tiempo: %d ms',
                              [(Sender as TUniScript).RowsAffected,
                              FStopwatch.ElapsedMilliseconds]));
    FLogMemo.Lines.Add('--------------------------------------------------');
    FLogMemo.SelStart := Length(FLogMemo.Text);
    SendMessage(FLogMemo.Handle, EM_SCROLLCARET, 0, 0);
    Application.ProcessMessages;
  end;
end;

function TfrmMtoPrincipal.ContieneDDL(const ASQL: string): Boolean;
var
  Patron: string;
begin
  Patron := '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b';
  Result := TRegEx.IsMatch(ASQL, Patron, [roIgnoreCase]);
end;

procedure TfrmMtoPrincipal.UniScript1Error(Sender: TObject;
                                           E: Exception;
                                           SQL: string;
                                           var Action: TErrorAction);
var
  Respuesta: Integer;
begin
  if Assigned(FLogMemo) then
  begin
    FStopwatch.Stop;
    FLogMemo.Lines.Add('  [ERROR] ' + E.Message + Format(' Tiempo: %d ms',
                                   [FStopwatch.ElapsedMilliseconds]));
    FLogMemo.Lines.Add('--------------------------------------------------');
    FLogMemo.SelStart := Length(FLogMemo.Text);
    SendMessage(FLogMemo.Handle, EM_SCROLLCARET, 0, 0);
    Application.ProcessMessages;
  end;
  var MsgCorta := E.Message;
  if Length(MsgCorta) > 200 then
    MsgCorta := Copy(MsgCorta, 1, 200) + '...';
  Respuesta := MessageDlg(
    'Ocurrió un error ejecutando el script.' +  sLineBreak +
    'Detalle del error: ' + MsgCorta + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?',
    mtError, [mbYes, mbNo], 0);
  if Respuesta = mrYes then
    Action := eaContinue
  else
    Action := eaFail;
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject;
                                                  var Done: Boolean);
var
  EstadoTeclas: string;
begin
  EstadoTeclas := '';
  if (GetKeyState(VK_CAPITAL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'CAPS  ';
  if (GetKeyState(VK_NUMLOCK) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'NUM  ';
  if (GetKeyState(VK_SCROLL) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'SCRL  ';
  if (GetKeyState(VK_INSERT) and 1) <> 0 then
    EstadoTeclas := EstadoTeclas + 'OVR'
  else
    EstadoTeclas := EstadoTeclas + 'INS';
  EstadoTeclas := Trim(EstadoTeclas);
  if jvStatusBar1.Panels[0].Text <> EstadoTeclas then
    jvStatusBar1.Panels[0].Text := EstadoTeclas;
end;

procedure TfrmMtoPrincipal.SetSystemMenuFont(const AFontName: string;
                                             ASize: Integer);
var
  NCM: TNonClientMetrics;
begin
  NCM.cbSize := SizeOf(TNonClientMetrics);
  if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(NCM), @NCM, 0) then
  begin
    StringToWideChar(AFontName, NCM.lfMenuFont.lfFaceName, LF_FACESIZE);
    NCM.lfMenuFont.lfHeight := -MulDiv(ASize,
                                       GetDeviceCaps(GetDC(0),
                                                     LOGPIXELSY),
                                       72);
    NCM.lfMenuFont.lfWeight := FW_NORMAL;
    SystemParametersInfo(SPI_SETNONCLIENTMETRICS,
                         SizeOf(NCM),
                         @NCM,
                         SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
  end;
end;


procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
var
  sDis: string;

  procedure AplicarTema;
  var
    sTema: string;
  begin
    if not (Assigned(LookAndFeelController1) and
            Assigned(dxSkinController1)) then
      Exit;
    try
      sTema := oAppParams.GetString('appTema');
      if sTema = '' then
      begin
        if DarkModeIsEnabled then
          sTema := 'MetropolisDark'
        else
          sTema := 'Office2007Pink';
      end;
      LookAndFeelController1.SkinName := sTema;
      dxSkinController1.SkinName      := sTema;
    except
      on E: Exception do
        inLibLog.Log.LogWarning('Error al establecer skin: ' + E.Message);
    end;
  end;

begin
  FSavedNCMValid := False;
  Application.OnIdle := ApplicationEvents1Idle;
  sDis := '';
  oMemoSQL := cxMemo1;
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FDmConn     := TdmConn.Create(Self);
  FDmConn.conUni.Connect;
  tmr1Timer(Sender);
  FdmDataPerfiles := TdmPerfiles.Create(Self);
  odmPerfiles     := FdmDataPerfiles;
  oConn           := FDmConn.conUni;
  odmConn         := FDmConn;
  ofrmMto2        := Self;
  oFzaWinf := TfzaWinF.Create(Self);
  oFzaWinf.Charge(oConn);
  oCajaParams.InicializarParametrosCaja(oUser, oGroup);
  oAppParams.InicializarParametrosApp(oUser, oGroup);
  oNomImpresoraCaja := GetImpresoraCaja;
  jvStatusBar1.Panels[1].Text := FDmConn.conUni.Server + ':' +
    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
  if oRootGroup = 'S' then
    sDis := ' ✪';
  jvStatusBar1.Panels[2].Text := oUser + ' (' + oGroup + ') ' + sDis;
  jvStatusBar1.Panels[3].Text := oEmpresa + '\' + oAlmacen + '\' + oCaja;
  Self.Caption := oAppName + ' ' + oVersion;
  pnlPPBottom.Visible := False;
  cxMemo1.Visible     := False;
{$IFDEF DEBUG}
  pnlPPBottom.Visible := True;
  cxMemo1.Visible     := True;
{$ENDIF}
  AplicarTema;
  inLibLog.Log.LogInfo('Arranque del sistema');
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
begin
  CopiaSeguridad;
end;

// validar iban online https://www.iban.com
// validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

function TfrmMtoPrincipal.CopiaSeguridad: Boolean;
var
  Options: TBackupOptions;
  Provider: IDBMetadataProvider;
  Helpers: IDBHelpers;
  Writer: IScriptWriter;
  Engine: TDBBackupEngine;
  IncludeTables, ExcludeTables: TStringList;
begin
  // Asumimos por defecto que no se completará (ej. el usuario cancela)
  Result := False;

  // Configuración del diálogo
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.DefaultExtension := 'sql';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  //saveDialog.FileTypes.Add(); := 'Archivos SQL (*.sql)|*.sql';
  saveDialog.FileName := 'copiaseguridad' +
                           FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now) + '.sql';
  if saveDialog.Execute then
  begin
    // 1. Configurar Opciones de la librería
    Options.WithData := True;
    Options.WithTriggers := True;
    Options.WithProcedures := True;
    Options.WithFunctions := True;
    Options.WithViews := True;
    Options.DropTablesFirst := True;
    Options.UseTransactions := True;
    Options.ExtendedInsert   := True;
    Options.ExtendedInsertRows := 500;
    IncludeTables := TStringList.Create;
    ExcludeTables := TStringList.Create;
    // 2. Inicializar el Provider
    Provider := TMySQLMetadataProvider.Create(FDmConn.conUni,
                                              FDmConn.conUni.Database);
    Helpers := TMySQLHelpers.Create;
    Writer := TScriptWriter.Create(saveDialog.FileName);
    try
      try
        Engine := TDBBackupEngine.Create(Provider,
                                         Writer,
                                         Helpers,
                                         Options,
                                         IncludeTables,
                                         ExcludeTables);
        try
          Engine.GenerateBackup;
          inLibLog.Log.LogInfo('Copia de seguridad creada en ' +
                                                           saveDialog.FileName);
          ShowMessage('La copia se guardó exitosamente.');
          Result := True;
        finally
          Engine.Free;
        end;
      except
        on E: Exception do
        begin
          inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' +
                                                                     E.Message);
          ShowMessage('No se pudo crear la copia de seguridad.' + sLineBreak +
                                                                     E.Message);
          Result := False;
        end;
      end;
    finally
      IncludeTables.Free;
      ExcludeTables.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  // FormPaint(Sender);
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
//var
//  I: Integer;
begin
  inherited;
  try
    inLibLog.Log.LogInfo('Cerrando ventana principal');
    tmr1.Enabled := False;
    if Assigned(FormManager) then
    try
      FormManager.CloseAll;
    except
      on E: Exception do inLibLog.Log.LogError('Error en CloseAll: ' +
                                                                     E.Message);
    end;
    FreeAndNil(oFzaWinf);
    if (FdmDataPerfiles <> nil) then
      FreeAndNil(FdmDataPerfiles);
    FreeAndNil(FDmConn);
  finally
    inLibLog.Log.LogInfo('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

procedure TfrmMtoPrincipal.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  if (pcPrincipal.PageCount = 0) then
  begin
    if MessageDlg('¿Quiere salir de la aplicación Fzam?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      CanClose := False; // Cancela el cierre
    end
    else
    begin
      CanClose := True;  // Permite el cierre
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  if FException then
  begin
    PostMessage(Handle, wm_Close, 0, 0);
    Exit;
  end;
end;

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;

  function GetKeyShiftState: TShiftState;
  begin
    Result := [];
    if GetKeyState(VK_SHIFT) < 0 then
      Include(Result, ssShift);
    if GetKeyState(VK_CONTROL) < 0 then
      Include(Result, ssCtrl);
    if GetKeyState(VK_MENU) < 0 then
      Include(Result, ssAlt);
  end;

var
  Component: TComponent;
  ActiveForm: TCustomForm;
  ts: TcxTabSheet;
  I: Integer;
  iPageActive: Integer;
  bFound: Boolean;
  aShortCutList: TList<Integer>;
  CurrentShortCut: TShortCut;
  ShiftState: TShiftState;
begin
  if (Message.CharCode = VK_F4) and (HiWord(Message.KeyData) and KF_ALTDOWN <> 0) then
  begin
    Self.Close;
    Result := True;
    Exit;
  end;
  if (Message.CharCode = VK_ESCAPE) then
  begin
    if Application.ModalLevel > 0 then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if Assigned(Screen.ActiveForm) and
       (Screen.ActiveForm <> Self) and
       (Screen.ActiveForm.Parent = nil) then
    begin
      Result := inherited IsShortCut(Message);
      Exit;
    end;
    if (pcPrincipal.PageCount = 0) then
    begin
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
      Result := True;
      Exit;
    end
    else
    begin
      FormManager.CloseActiveForm;
      Result := True;
      Exit;
    end;
  end;
  ActiveForm := Screen.ActiveForm;
  if Assigned(ActiveForm) and
     (ActiveForm <> Self) and
     (ActiveForm.Parent = nil) then
  begin
    Result := False;
    for I := 0 to ActiveForm.ComponentCount - 1 do
    begin
      Component := ActiveForm.Components[I];
      if Component is TActionList then
      begin
        if TActionList(Component).IsShortCut(Message) then
        begin
          Result := True;
          Break;
        end;
      end;
    end;
    Exit;
  end;
  I := 0;
  Result := True;
  bFound := False;
  ShiftState := GetKeyShiftState;
  CurrentShortCut := Vcl.Menus.ShortCut(Message.CharCode, ShiftState);
  aShortCutList := oFzaWinf.GetShortCutListOrd;
  try
    if (aShortCutList.Contains(CurrentShortCut)) then
    begin
      if (Self.pcPrincipal.PageCount) > 0 then
      begin
        iPageActive := pcPrincipal.ActivePageIndex;
        ts := (Self.pcPrincipal.Pages[iPageActive] as TcxTabSheet);
        if (ts.Controls[0] is TForm) then
        begin
          while ((I >= 0) and
                 (I < (ts.Controls[0] as TForm).ComponentCount) and
                 (not(bFound))) do
          begin
            Component := (ts.Controls[0] as TForm).Components[I];
            if (Component is TActionList) then
            begin
              if TActionList(Component).IsShortCut(Message) then
              begin
                bFound := True;
                Result := True;
                Break;
              end;
            end;
            Inc(I);
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(aShortCutList);
  end;
  if (not bFound) then
    Result := inherited IsShortCut(Message);
end;

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
var
  SqlScript: TUniScript;
begin
  if not mnuEjecutarScript.Visible then
    Exit;
  openDialog.Title := 'Cargar script';
  openDialog.FileTypes.Clear;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivos SQL';
    FileMask := '*.sql';
  end;
  with openDialog.FileTypes.Add do
  begin
    DisplayName := 'Todos los archivos';
    FileMask := '*.*';
  end;
  openDialog.DefaultExtension := 'sql';
  openDialog.DefaultFolder := oAppParams.GetPath('appDirCopiasSeguridad');
  if openDialog.Execute then
  begin
    SqlScript := TUniScript.Create(nil);
    SqlScript.OnError := UniScript1Error;
    SqlScript.BeforeExecute := ScriptBeforeExecute;
    SqlScript.AfterExecute := ScriptAfterExecute;
    try
      SqlScript.Connection := FDmConn.conUni;
      if FdmConn.conuni.InTransaction then
        FdmConn.conuni.Commit;
      FdmConn.conUni.StartTransaction;
      SqlScript.SQL.LoadFromFile(openDialog.FileName, TEncoding.UTF8);
      if ContieneDDL(SqlScript.SQL.Text) then
      begin
        var Respuesta := MessageDlg(
          'ATENCIÓN: El script contiene sentencias DDL (modifican la ' +
          'estructura de la base de datos).' + sLineBreak +
          'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
          'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
          '¿Deseas realizar una copia de seguridad antes de continuar?',
            mtWarning, [mbYes, mbNo, mbCancel], 0);
        case Respuesta of
          mrYes:
            begin
              if not CopiaSeguridad then
              begin
                ShowMessage('Operación cancelada. El script no se ejecutará.');
                Exit;
              end;
            end;
          mrCancel:
            Exit; // El usuario se arrepiente, abortamos todo
          //mrNo: // El usuario es valiente y decide continuar sin copia
        end;
      end;
      try
        var LogFrm := TfrmMtoModalScriptLog.Create(Self);
        FLogForm := LogFrm;
        FLogForm.OnClose := LogFormClose;
        FLogMemo := LogFrm.LogMemo;
        FLogMemo.Lines.Add('-- INICIO DE EJECUCIÓN DEL SCRIPT --');
        FLogMemo.Lines.Add('-- Archivo: ' +
                                          ExtractFileName(openDialog.FileName));
        FLogMemo.Lines.Add('-------------------------------------------------');
        FLogForm.Show;
        SqlScript.Execute;
        FdmConn.conUni.Commit;
        ShowMessage('El script se ejecutó exitosamente');
      except
          on E: Exception do
          begin
            FdmConn.conUni.Rollback;
            inLibLog.Log.LogError('Error al ejecutar el script: ' + E.Message);
            ShowMessage('Hubo problemas al ejecutar el script. E:' +
                                                                   E.ClassName +
              ' Mensaje:' + Copy(E.Message, 1, 200));
            raise;
          end;
      end;
    finally
      SqlScript.Free;
    end;
  end;
end;

procedure TfrmMtoPrincipal.tmr1Timer(Sender: TObject);
var
  ADateStr          : string;
  ATimeStr          : string;
begin
  bIsConnected := False;
  ADateStr := DateToStr(Now);
  ATimeStr := FormatDateTime('hh:mm', Now);
  if FDmConn <> nil then
    if FDmConn.conUni.Connected then
    begin
      bIsConnected := True;
      jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
    end
    else
      bIsConnected := False;
  if (FDmConn = nil) or (not bIsConnected) then
  begin
    jvStatusBar1.Panels[4].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
    inLibLog.Log.LogError('Se ha perdido la conexión con la BBDD');
  end;

//  if FDmConn <> nil then
//    if FDmConn.conUni.Connected then
//    begin
//      bIsConnected := True;
//      dxstsbr1.Panels.Items[4].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
//    end
//    else
//      bIsConnected := False;
//  if (FDmConn = nil) or (not bIsConnected) then
//  begin
//    dxstsbr1.Panels.Items[4].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
//    inLibLog.Log.LogError('Se ha perdido la conexión con la BBDD');
//  end;
end;

//procedure TfrmMtoPrincipal.undmp1Error(Sender: TObject; E: Exception;
//  SQL: string; var Action: TErrorAction);
//begin
//  inherited;
//  ShowMessage('Ha habido incidencias');
//  Action := eaAbort;
//  // https://forums.devart.com/viewtopic.php?t=21244
//  // Continúa a pesar de los errores, por ejemplo si hay filas duplicadas
//  // if (EUniError(E).ErrorCode = 1062) then // ER_DUP_ENTRY
//  // Action := eaContinue;
//end;

procedure TfrmMtoPrincipal.WMFreeControl(var Msg: TMessage);
var
  TabACerrar: TcxTabSheet;
begin
  TabACerrar := TcxTabSheet(Msg.LParam);
  if FormManager <> nil then
  begin
    FormManager.CloseFormByCaption(TabACerrar.Caption);
  end
  else
  begin
    TabACerrar.Free;
  end;
end;

procedure TfrmMtoPrincipal.mnuLisVentasClick(Sender: TObject);
var
  frmModalGenFilter: TfrmModalGenFilter;
begin
  inherited;
  try
    frmModalGenFilter := TfrmModalGenFilter.Create(Self);
    frmModalGenFilter.ShowModal;
  finally
    FreeAndNil(frmModalGenFilter);
  end;
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if not mnuMenuCaja.Visible then Exit;
  if Assigned(frmMtoMenuCaja) then
  begin
    if frmMtoMenuCaja.WindowState = wsMinimized then
      frmMtoMenuCaja.WindowState := wsNormal;
    frmMtoMenuCaja.BringToFront;
  end
  else
  begin
    frmMtoMenuCaja := TfrmMtoMenuCaja.Create(Application);
    frmMtoMenuCaja.Show;
  end;
  Self.WindowState := wsMinimized;
end;

procedure TfrmMtoPrincipal.mnuAcercadeClick(Sender: TObject);
var
  frmSplash: TfrmSplash;
begin
  inherited;
  try
    frmSplash := TfrmSplash.Create(Self);
    frmSplash.ShowModal;
  finally
    FreeAndNil(frmSplash);
  end;
end;

procedure TfrmMtoPrincipal.mnuAlmacenesClick(Sender: TObject);
begin
  inherited;
  if mnuAlmacenes.Visible then
    ShowMto(Self, 'Almacenes');
end;

procedure TfrmMtoPrincipal.mnuArticulosClick(Sender: TObject);
begin
  if (mnuArticulos.Visible) then
    ShowMto(Self, 'Articulos');
end;

procedure TfrmMtoPrincipal.mnuCajaParamClick(Sender: TObject);
var
  frmMtoCajaParam: TfrmMtoCajaParam;
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    try
      frmMtoCajaParam := TfrmMtoCajaParam.Create(Self);
      frmMtoCajaParam.ShowModal;
    finally
      FreeAndNil(frmMtoCajaParam);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuClientesClick(Sender: TObject);
begin
  if (mnuClientes.Visible) then
    ShowMto(Self, 'Clientes');
end;

procedure TfrmMtoPrincipal.mnuContadoresClick(Sender: TObject);
begin
  if (mnuContadores.Visible) then
    ShowMto(Self, 'Contadores');
end;

procedure TfrmMtoPrincipal.mnuFacturasClick(Sender: TObject);
begin
  if (mnuFacturas.Visible) then
    ShowMto(Self, 'Facturas');
end;

procedure TfrmMtoPrincipal.mnuFamiliasClick(Sender: TObject);
begin
  if (mnuFamilias.Visible) then
    ShowMto(Self, 'Familias');
end;

procedure TfrmMtoPrincipal.mnuFormaPagoVentaClick(Sender: TObject);
begin
  inherited;
  if mnuFormaPagoVenta.Visible then
    ShowMto(Self, 'FormasdePago');
end;

procedure TfrmMtoPrincipal.mnuPedidosVentaClick(Sender: TObject);
begin
  inherited;
  if mnuPedidosVenta.Visible then
    ShowMto(Self, 'Pedidos');
end;

procedure TfrmMtoPrincipal.mnuAlbaranesVentaClick(Sender: TObject);
begin
  inherited;
  if mnuAlbaranesVenta.Visible then
    ShowMto(Self, 'Albaranes');
end;

procedure TfrmMtoPrincipal.mnuGeneradorProcesosClick(Sender: TObject);
begin
  if (mnuGeneradorProcesos.Visible) then
    ShowMto(Self, 'GeneradorProcesos');
end;

procedure TfrmMtoPrincipal.mnuGruposClick(Sender: TObject);
begin
  if (mnuGrupos.Visible) then
    ShowMto(Self, 'Grupos');
end;

procedure TfrmMtoPrincipal.mnuGruposdeIVAClick(Sender: TObject);
begin
  if (mnuGruposdeIVA.Visible) then
    ShowMto(Self, 'IvasGrupos');
end;

procedure TfrmMtoPrincipal.mnuInventariosClick(Sender: TObject);
begin
  inherited;
  if mnuInventarios.Visible then
    ShowMto(Self, 'Inventarios');
end;

procedure TfrmMtoPrincipal.mnuIvasClick(Sender: TObject);
begin
  if (mnuIvas.Visible) then
    ShowMto(Self, 'Ivas');
end;

procedure TfrmMtoPrincipal.mnuEmpresasClick(Sender: TObject);
begin
  if (mnuEmpresas.Visible) then
    ShowMto(Self,
            'Empresas');
end;

procedure TfrmMtoPrincipal.mnuPaisesClick(Sender: TObject);
begin
  inherited;
  if (mnuPaises.Visible) then
    ShowMto(Self, 'Paises');
end;

procedure TfrmMtoPrincipal.mnuPerfilesClick(Sender: TObject);
begin
  if (mnuPerfiles.Visible) then
    ShowMto(Self,
            'UsuariosPerfiles');
end;

procedure TfrmMtoPrincipal.mnuProveedoresClick(Sender: TObject);
begin
  if (mnuProveedores.Visible) then
    ShowMto(Self, 'Proveedores');
end;

procedure TfrmMtoPrincipal.mnuUsuariosClick(Sender: TObject);
begin
  if (mnuUsuarios.Visible) then
    ShowMto(Self, 'Usuarios');
end;

procedure TfrmMtoPrincipal.mnuParmetrosdeEntornoClick(Sender: TObject);
var
    frmMtoAppParam: TfrmMtoAppParam;
begin
  inherited;
  try
    frmMtoAppParam := TfrmMtoAppParam.Create(Self);
    frmMtoAppParam.ShowModal;
  finally
    FreeAndNil(frmMtoAppParam);
  end;
end;

procedure TfrmMtoPrincipal.mnuPropiedadesClick(Sender: TObject);
begin
  if (mnuPropiedades.Visible) then
    ShowMto(Self, 'Propiedades');
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVariacionesClick(Sender: TObject);
begin
  if (mnuVariaciones.Visible) then
    ShowMto(Self, 'Variaciones');
end;

procedure TfrmMtoPrincipal.mnuAtributosConjuntosClick(Sender: TObject);
begin
  if (mnuAtributosConjuntos.Visible) then
    ShowMto(Self, 'AtributosConjuntos');
end;

procedure TfrmMtoPrincipal.mnuCajaPagosHistClick(Sender: TObject);
begin
  if (mnuCajaPagosHist.Visible) then
    ShowMto(Self, 'CajaPagosHist');
end;

procedure TfrmMtoPrincipal.mnuCajaValesHistClick(Sender: TObject);
begin
  if (mnuCajaValesHist.Visible) then
    ShowMto(Self, 'CajaValesHist');
end;

procedure TfrmMtoPrincipal.mnuCajaOperacionesHistClick(Sender: TObject);
begin
  if (mnuCajaOperacionesHist.Visible) then
    ShowMto(Self, 'CajaOperacionesHist');
end;

procedure TfrmMtoPrincipal.Movimientosdealmacn1Click(Sender: TObject);
begin
  if (Movimientosdealmacn1.Visible) then
    ShowMto(Self, 'MovimientosAlmacen');
end;

procedure TfrmMtoPrincipal.mnuDepositosClienteClick(Sender: TObject);
begin
  if (mnuDepositosCliente.Visible) then
    ShowMto(Self, 'DepositosCliente');
end;

end.
