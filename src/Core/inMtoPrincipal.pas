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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, dxBarBuiltInMenu, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls, DADump, UniDump,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, dxStatusBar, inMtoFrmBase, UniDataConn,
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
  dxSkinWhiteprint, dxSkinXmas2008Blue, inLibFormManager, System.Actions;

const
  WM_FREECONTROL = WM_USER;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(TfrmBase)
    mnuCaja: TMenuItem;
    mnuMenuCaja: TMenuItem;
    mnuAlmacenes: TMenuItem;
    // procedure FormDestroy(Sender: TObject);
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuAlmacenesClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
//    procedure actSalirExecute(Sender: TObject);

  private
    // procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
  published
    undmp1: TUniDump;
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    SkinController1: TdxSkinController;
    EditStyleController: TcxEditStyleController;
    LookAndFeelController1: TcxLookAndFeelController;
    dxstsbr1: TdxStatusBar;
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
    openDialog: TdxOpenFileDialog;
    saveDialog: TdxSaveFileDialog;
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
    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_USER + 1;
  private

    FException: Boolean;
    // procedure AppException(Sender: TObject; E: Exception);
    procedure CopiaSeguridad;
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
  inMtoModalGenFilter;

{$R *.dfm}

procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
var
  sDis: string;
begin
  // Application.OnException := AppException;
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
  dxstsbr1.Panels[1].Text := FDmConn.conUni.Server + ':' +
    IntToStr(FDmConn.conUni.Port) + ' (' + FDmConn.conUni.Database + ')';
  if oRootGroup = 'S' then
    sDis := ' ✪';
  dxstsbr1.Panels[2].Text := oUser + '  (' + oGroup + ') : ' + sDis + ' : ';
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

procedure TfrmMtoPrincipal.CopiaSeguridad;
var
  iButtonSel: Integer;
  s: string;
  MyText: TStringlist;
begin
  iButtonSel := 0;
  saveDialog.Title := 'Guardar copia de seguridad';
  saveDialog.InitialDir := GetCurrentDir;
  savedialog.FileName := 'copiaseguridad' + FormatDateTime('_dd_mm', Now) +
                                                                         '.sql';
  undmp1.Connection := FDmConn.conUni;
  if (saveDialog.Execute) then
  begin
    if FileExists(savedialog.FileName) then
    begin
      iButtonSel := MessageDlg('¿Desea reemplazar el fichero existente?',
        mtCustom, [mbYes, mbNo], 0);
    end;
    if ((iButtonSel = mrYes) or (not FileExists(saveDialog.FileName))) then
    begin
      s:= 'DROP DATABASE IF EXISTS '+ FDmConn.conUni.Database +'; ' + sLineBreak +
                       'CREATE DATABASE ' + FDmConn.conUni.Database + ' ' +
                       '  CHARACTER SET utf8mb4 ' +
                       '       COLLATE utf8mb4_spanish_ci; ' +  sLineBreak +
                       'USE '+FDmConn.conUni.Database+';' + sLineBreak + sLineBreak + s;
      //undmp1.SpecificOptions.Values['UseExtSyntax'] := 'False';
      //To make TUniDump component generate an INSERT statement for each row
      //La anterior orden genera un insert por cada fila.
      undmp1.Backup;
      s := s + undmp1.SQL.Text;
      s := StringReplace(s, 'DEFINER=`'+ oConn.Username +
                            '`@`localhost`', '', [rfReplaceAll, rfIgnoreCase]);
      MyText := TStringlist.Create;
      MyText.Text := s;
      saveDialog.InitialDir := GetUserDeskFolder;
      MyText.SaveToFile(saveDialog.FileName, TEncoding.UTF8);
      inLibLog.Log.LogInfo('Copia de seguridad creada en ' +
        saveDialog.FileName);
      MyText.Free;
      ShowMessage('La copia se guardó exitosamente');
    end;
  end;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  // FormPaint(Sender);
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
var
  I: Integer;
begin
  inherited;
  try
    inLibLog.Log.LogInfo('Cerrando ventana principal');
    tmr1.Enabled := False;
    FreeAndNil(oFzaWinf);
    if FormManager <> nil then
      FormManager.CloseAll;
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
  if (Message.CharCode = VK_ESCAPE) then
  begin
    if (pcPrincipal.PageCount = 0) then
    begin
      Self.Close;
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

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
begin
  if (mnuEjecutarScript.Visible) then
  begin
    openDialog.Title := 'Cargar script';
    openDialog.InitialDir := GetCurrentDir;
    undmp1.Connection := FDmConn.conUni;
    if openDialog.Execute then
    begin
      try
        undmp1.RestoreFromFile(openDialog.FileName, TEncoding.UTF8);
        ShowMessage('El script se ejecutó exitosamente');
      except
        on E: Exception do
        begin
          ShowMessage('Hubo problemas al ejecutar el script. E:' + E.ClassName +
            ' Mensaje:' + E.Message);
          raise;
          Exit;
        end;
      end;
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
      dxstsbr1.Panels.Items[3].Text := '' + ADateStr + ' ' + ATimeStr + ' Conn';
    end
    else
      bIsConnected := False;
  if (FDmConn = nil) or (not bIsConnected) then
  begin
    dxstsbr1.Panels.Items[3].Text := '' + ADateStr + ' ' + ATimeStr + 'NO Conn';
    inLibLog.Log.LogError('Se ha perdido la conexión con la BBDD');
  end;
end;

procedure TfrmMtoPrincipal.undmp1Error(Sender: TObject; E: Exception;
  SQL: string; var Action: TErrorAction);
begin
  inherited;
  ShowMessage('Ha habido incidencias');
  Action := eaAbort;
  // https://forums.devart.com/viewtopic.php?t=21244
  // Continúa a pesar de los errores, por ejemplo si hay filas duplicadas
  // if (EUniError(E).ErrorCode = 1062) then // ER_DUP_ENTRY
  // Action := eaContinue;
end;

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

//procedure TfrmMtoPrincipal.WMFreeControl(var Message: TMessage);
//begin
//  TObject(Message.LParam).Free;
//end;

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
