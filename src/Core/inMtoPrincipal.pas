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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics,
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
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar,
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
    // procedure FormDestroy(Sender: TObject);
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuAlmacenesClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure FormResize(Sender: TObject);

//    procedure actSalirExecute(Sender: TObject);

  private
    // procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
  published
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    SkinController1: TdxSkinController;
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
    mnuFormasdePago: TMenuItem;
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
    procedure mnuFormasdepagoClick(Sender: TObject);
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
    FLogMemo: TcxMemo; 
    // procedure AppException(Sender: TObject; E: Exception);
    function CopiaSeguridad: Boolean;
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
  inMtoCajaMenu,
  inMtoCajaParam,
  inMtoModalGenFilter,
  inLibCajaParam,
  System.RegularExpressions;

{$R *.dfm}

procedure TfrmMtoPrincipal.LogFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  FLogForm := nil;
  FLogMemo := nil;
end;

procedure TfrmMtoPrincipal.ScriptBeforeExecute(Sender: TObject; var SQL: string; var Omit: Boolean);
begin
  if Assigned(FLogMemo) then
  begin
    FLogMemo.Lines.Add('Ejecutando: ' + Trim(SQL));
    Application.ProcessMessages; 
  end;
  
  // Iniciamos el cronómetro justo antes de que la BD reciba la sentencia
  FStopwatch := TStopwatch.StartNew; 
end;

procedure TfrmMtoPrincipal.ScriptAfterExecute(Sender: TObject; SQL: string);
begin
  // Detenemos el cronómetro lo antes posible
  FStopwatch.Stop; 

  if Assigned(FLogMemo) then
  begin
    // Usamos Format para que quede limpio: Filas afectadas y el tiempo en milisegundos
    FLogMemo.Lines.Add(Format('  [OK] Filas afectadas: %d | Tiempo: %d ms', 
                             [(Sender as TUniScript).RowsAffected, FStopwatch.ElapsedMilliseconds]));
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
  // \b indica "límite de palabra" para asegurar que es el comando exacto.
  // Buscamos ignorando mayúsculas o minúsculas.
  Patron := '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b';
  Result := TRegEx.IsMatch(ASQL, Patron, [roIgnoreCase]);
end;

procedure TfrmMtoPrincipal.UniScript1Error(Sender: TObject; E: Exception;
                                  SQL: string; var Action: TErrorAction);
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

  // Aquí podemos registrar el error en un log o preguntar al usuario
  Respuesta := MessageDlg(
    'Ocurrió un error ejecutando la siguiente sentencia:' + sLineBreak +
    SQL + sLineBreak + sLineBreak +
    'Detalle del error: ' + E.Message + sLineBreak + sLineBreak +
    '¿Deseas ignorar el error y continuar con el script?',
    mtError, [mbYes, mbNo], 0);

  if Respuesta = mrYes then
    Action := eaContinue  // Ignora la sentencia fallida y continúa con la número 3
  else
    Action := eaFail;     // Detiene el script y pasa al bloque "except" principal
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
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
  // LA MAGIA DE LA OPTIMIZACIÓN:
  // Solo se asigna (y por tanto se repinta en pantalla) si el usuario
  // acaba de pulsar o soltar una de las teclas.
  if jvStatusBar1.Panels[0].Text <> EstadoTeclas then
    jvStatusBar1.Panels[0].Text := EstadoTeclas;
end;
procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
var
  sDis: string;
begin
  // Application.OnException := AppException;
  Application.OnIdle := ApplicationEvents1Idle;
  sDis := '';
  oMemoSQL := cxMemo1;
  inLibLog.Log.LogInfo('Creando ventana principal');
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FDmConn := TdmConn.Create(Self);
  FDmConn.conUni.Connect;
  FdmDataPerfiles := TdmPerfiles.Create(Self);
  odmPerfiles := FdmDataPerfiles;
  oConn := FDmConn.conUni;
  odmConn := FDmConn;
  ofrmMto2 := Self;
  // carga de todos los forms con sus propiedades y módulos de datos
  oFzaWinf := TfzaWinF.Create(Self);
  oFzaWinf.Charge(oConn);
  oCajaParams.Inicializar(oUser, oGroup);
//  dxstsbr1.Panels[1].Text := FDmConn.conUni.Server + ':' +
//    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
//  if oRootGroup = 'S' then
//    sDis := ' ✪';
//  dxstsbr1.Panels[2].Text := oUser + '  (' + oGroup + ') : ' + sDis + ' : ';
//  dxstsbr1.Panels[3].Text := oEmpresa + '\' +  oAlmacen + '\' + oCaja;

  jvStatusBar1.Panels[1].Text := FDmConn.conUni.Server + ':' +
    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
  if oRootGroup = 'S' then
    sDis := ' ✪';
  jvStatusBar1.Panels[2].Text := oUser + '  (' + oGroup + ') : ' + sDis + ' : ';
  jvStatusBar1.Panels[3].Text := oEmpresa + '\' +  oAlmacen + '\' + oCaja;

  Self.Caption := oAppName + ' ' + oVersion;
  pnlPPBottom.Visible := False;

  cxMemo1.Visible := False;
{$IFDEF DEBUG}
  pnlPPBottom.Visible := True;
  cxMemo1.Visible := True;
{$ENDIF }
  // Log(FdmConn.ConUni, oUSer, 'Entrando en el software', Self);
  // zqryPermisoMenu.Connection := FdmConn.ZconnGlent;
  // zqryPermisoMenu.SQL.Text := 'SELECT Entidad, Menu, PermisoAcceso,
  //PermisoListado, PermisoEscritura ' +
  // '  FROM glt_user_permisos ' +
  // ' WHERE Entidad = ' + QuotedStr(oUser) +
  // '    OR Entidad = ' + QuotedStr(oGroup) +
  // '  ORDER BY Menu, PermisoAcceso';
  // zqryPermisoMenu.Open;
  // SetPermisosMenu(mnMenuPrin, oUser, oGroup);
  // zqryPermisoMenu.Close;

  // https://stackoverflow.com/questions/2750102/
  // how-can-i-change-the-fontsize-of-the-mainmenu-items-in-delphi
  // ShowMessage('ESTABLECIENDO FUENTES DE MENU');
  Screen.MenuFont.Name := 'Lucida Sans';
  Screen.MenuFont.Size := 13;
  // https://www.tek-tips.com/viewthread.cfm?qid=1360646
  try
    if Assigned(LookAndFeelController1) and Assigned(SkinController1) then
    begin
      if DarkModeIsEnabled then
      begin
        LookAndFeelController1.SkinName := 'MetropolisDark';
        SkinController1.SkinName := 'MetropolisDark';
      end
      else
      begin
        LookAndFeelController1.SkinName := 'Office2007Pink';
        SkinController1.SkinName := 'Office2007Pink';
      end;
    end;
  except
    on E: Exception do
    begin
      inLibLog.Log.LogWarning('Error al establecer skin: ' + E.Message);
      // Continuar sin skin personalizado
    end;
  end;
  inLibLog.Log.LogInfo('Ventana principal creada');
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  inherited;
  jvStatusBar1.Panels[1].Width := jvStatusBar1.ClientWidth -
                                  jvStatusBar1.Panels[0].Width -
                                  jvStatusBar1.Panels[2].Width -
                                  jvStatusBar1.Panels[3].Width -
                                  jvStatusBar1.Panels[4].Width - 20;
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

//procedure TfrmMtoPrincipal.actSalirExecute(Sender: TObject);
//begin
//  inherited;
//  if (pcPrincipal.PageCount = 0) then
//  begin
//    Self.Close;
//  end;
//end;

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
  saveDialog.DefaultFolder := GetCurrentDir;
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
                              FormatDateTime('_dd_mm_yyyy_HH_nn', Now) + '.sql';
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
    Provider := TMySQLMetadataProvider.Create(FDmConn.conUni, FDmConn.conUni.Database);
    Helpers := TMySQLHelpers.Create;
    Writer := TScriptWriter.Create(saveDialog.FileName);

    try
      try
        Engine := TDBBackupEngine.Create(Provider, Writer, Helpers, Options, IncludeTables, ExcludeTables);
        try
          // 3. Ejecutar el backup
          Engine.GenerateBackup;

          inLibLog.Log.LogInfo('Copia de seguridad creada en ' + saveDialog.FileName);
          ShowMessage('La copia se guardó exitosamente.');
          
          // Si llegamos hasta aquí sin errores, el backup fue un éxito
          Result := True; 
        finally
          Engine.Free;
        end;
      except
        on E: Exception do
        begin
          // Si algo falla al guardar (ej. disco lleno, sin permisos), lo capturamos
          inLibLog.Log.LogError('Fallo al crear copia de seguridad: ' + E.Message);
          ShowMessage('No se pudo crear la copia de seguridad.' + sLineBreak + E.Message);
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
      on E: Exception do inLibLog.Log.LogError('Error en CloseAll: ' + E.Message);
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
  end
  else
  begin
    // Si hay formularios abiertos, podrías decidir si dejar cerrar
    // directamente o pedir cerrar primero las pestañas.
//    CanClose := True;
  end;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  // si ocurre una excepción durante la carga,
  // se fuerza el cierre de la ventana
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

//procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
//begin
//  if (mnuEjecutarScript.Visible) then
//  begin
//    openDialog.Title := 'Cargar script';
//    openDialog.InitialDir := GetCurrentDir;
//    undmp1.Connection := FDmConn.conUni;
//    if openDialog.Execute then
//    begin
//      try
//        undmp1.RestoreFromFile(openDialog.FileName, TEncoding.UTF8);
//        ShowMessage('El script se ejecutó exitosamente');
//      except
//        on E: Exception do
//        begin
//          ShowMessage('Hubo problemas al ejecutar el script. E:' + E.ClassName +
//            ' Mensaje:' + E.Message);
//          raise;
//          Exit;
//        end;
//      end;
//    end;
//  end;
//end;

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
  openDialog.DefaultFolder := ExtractFilePath(Application.ExeName);
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
      // NoPreprocess es crucial para que no falle con los DELIMITER de MySQL
//      SqlScript.nopre := True;
      // Cargamos el archivo en la propiedad SQL
      SqlScript.SQL.LoadFromFile(openDialog.FileName, TEncoding.UTF8);
      if ContieneDDL(SqlScript.SQL.Text) then
      begin
        var Respuesta := MessageDlg(
          'ATENCIÓN: El script contiene sentencias DDL (modifican la estructura de la base de datos).' + sLineBreak +
          'En MySQL/MariaDB, estos cambios provocan un guardado automático y NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
          '¿Deseas realizar una copia de seguridad antes de continuar?',
            mtWarning, [mbYes, mbNo, mbCancel], 0);
        case Respuesta of
          mrYes:
            begin
              if not CopiaSeguridad then
              begin
                ShowMessage('Operación cancelada. El script no se ejecutará por seguridad.');
                Exit; 
              end;
            end;
          mrCancel:
            Exit; // El usuario se arrepiente, abortamos todo
          //mrNo: // El usuario es valiente y decide continuar sin copia
        end;
      end;
      try
        FLogForm := TForm.Create(Self);
        FLogForm.Caption := 'Progreso de Ejecución del Script';
        FLogForm.Width := 750;
        FLogForm.Height := 500;
        FLogForm.Position := poMainFormCenter;
        FLogForm.OnClose := LogFormClose; // Para que se destruya al cerrar

        FLogMemo := TcxMemo.Create(FLogForm);
        FLogMemo.Parent := FLogForm;
        FLogMemo.Align := alClient;       
        FLogMemo.Properties.ScrollBars := TScrollstyle.ssBoth;
        FLogMemo.Properties.ReadOnly := True;
        FLogMemo.style.Font.Name := 'Consolas'; // Fuente monoespaciada ideal para SQL
        FLogMemo.style.Font.Size := 10;
        FLogMemo.Properties.WordWrap := False; // Para que no corte las sentencias largas

        FLogMemo.Lines.Add('--- INICIO DE EJECUCIÓN DEL SCRIPT ---');
        FLogMemo.Lines.Add('Archivo: ' + ExtractFileName(openDialog.FileName));
        FLogMemo.Lines.Add('--------------------------------------------------');

        // Mostramos la ventana de forma no modal para poder actualizarla
        FLogForm.Show;
        SqlScript.Execute;
        FdmConn.conUni.Commit; 
        ShowMessage('El script se ejecutó exitosamente');
      except
          on E: Exception do
          begin
            FdmConn.conUni.Rollback;
            inLibLog.Log.LogError('Error al ejecutar el script: ' + E.Message);
            ShowMessage('Hubo problemas al ejecutar el script. E:' + E.ClassName +
              ' Mensaje:' + E.Message);
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
var
  frmMtoMenuCaja: TfrmMtoMenuCaja;
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    try
      frmMtoMenuCaja := TfrmMtoMenuCaja.Create(Self);
      frmMtoMenuCaja.ShowModal;
    finally
      FreeAndNil(frmMtoMenuCaja);
    end;
  end;
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
    ShowMto(Self, 'Facturas', '', true);
end;

procedure TfrmMtoPrincipal.mnuFamiliasClick(Sender: TObject);
begin
  if (mnuFamilias.Visible) then
    ShowMto(Self, 'Familias');
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

procedure TfrmMtoPrincipal.mnuFormasdepagoClick(Sender: TObject);
begin
  if mnuFormasdePago.Visible then
    ShowMto(Self, 'FormasdePago');
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

end.
