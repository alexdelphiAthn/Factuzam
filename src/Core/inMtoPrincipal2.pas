{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit inMtoPrincipal2;

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
  dxSkinWhiteprint, dxSkinXmas2008Blue;

const
  WM_FREECONTROL = WM_USER;
type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmOpenApp2 = class(TfrmBase)


  private
    //procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
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
    procedure sbCerrarClick(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure WMFreeControl(var Message: TMessage); message WM_FREECONTROL;
  private

    FException: boolean;
//    procedure AppException(Sender: TObject; E: Exception);
    procedure CopiaSeguridad;
    //procedure UpdateTitleFont;
  public
    { Public declarations }

    FDmConn: TdmConn;
    FdmDataPerfiles: TdmPerfiles;
    oFzaWinf : TfzaWinF;
  end;

var
  frmOpenApp2: TfrmOpenApp2;
  bIsConnected      : boolean;

implementation

uses inLibUser,
     inLibWin,
     inLibShowMto,
     inLibtb,
     inLibGlobalVar,
     inLibLog,
     inLibDir,
     inMtoSplash,
     inMtoModalGenFilter;

{$R *.dfm}

procedure TfrmOpenApp2.FormCreate(Sender: TObject);
var
  sDis              : string;
begin
//  Application.OnException := AppException;
  sDis := '';
  oMemoSQL := cxMemo1;
  //ShowMessage('CREANDO CONEXIÓN');
  inliblog.Log.LogInfo('Creando ventana principal');
  FdmConn := TdmConn.Create(Self);
  FdmConn.conUni.Connect;
  //ShowMessage('CREANDO PERFILES');
  FdmDataPerfiles := TdmPerfiles.Create(Self);
  odmPerfiles := FdmDataPerfiles;
  oConn := FdmConn.conUni;
  odmConn := FdmConn;
  ofrmMto2 := Self;
  //carga de todos los forms con sus propiedades y módulos de datos
  oFzaWinF := TfzaWinf.Create(Self);
  //ShowMessage('CARGANDO OBJETOS FORMS Y DATA EN MARIADB');
  oFzaWinF.Charge(oConn);
  dxstsbr1.Panels[1].Text := FdmConn.conUni.Server + ':'
    + IntToStr(fdmconn.conUni.Port)
    + ' (' + FdmConn.conUni.Database + ')';
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
  //  zqryPermisoMenu.Connection := FdmConn.ZconnGlent;
  //  zqryPermisoMenu.SQL.Text := 'SELECT Entidad, Menu, PermisoAcceso, PermisoListado, PermisoEscritura ' +
  //                         '  FROM glt_user_permisos ' +
  //                         ' WHERE Entidad = ' + QuotedStr(oUser) +
  //                         '    OR Entidad = ' + QuotedStr(oGroup) +
  //                         '  ORDER BY Menu, PermisoAcceso';
  //  zqryPermisoMenu.Open;
  //  SetPermisosMenu(mnMenuPrin, oUser, oGroup);
  //  zqryPermisoMenu.Close;

  //https://stackoverflow.com/questions/2750102/
  //how-can-i-change-the-fontsize-of-the-mainmenu-items-in-delphi
  //ShowMessage('ESTABLECIENDO FUENTES DE MENU');
  Screen.MenuFont.Name := 'Lucida Sans';
  Screen.MenuFont.Size := 13;
  //UpdateTitleFont;
//  https://www.tek-tips.com/viewthread.cfm?qid=1360646
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
      inliblog.Log.LogWarning('Error al establecer skin: ' + E.Message);
      // Continuar sin skin personalizado
    end;
  end;
    //SendMessage(Handle, WM_SETFONT,
    //CreateFont(-16, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET,
    //          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
    //          DEFAULT_PITCH or FF_DONTCARE, 'Lucida Sans'), 1);
  // Forzar redibujado
  //SetWindowPos(Handle, 0, 0, 0, 0, 0,
  //             SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
  inliblog.Log.LogInfo('Ventana principal creada');
end;

//procedure TfrmOpenApp2.UpdateTitleFont;
//var
//  hWnd: THandle;
//  DC: HDC;
//  TitleFont: HFONT;
//  LogFont: TLogFont;
//begin
//  hWnd := Self.Handle;
//  DC := GetWindowDC(hWnd);
//  try
//    ZeroMemory(@LogFont, SizeOf(LogFont));
//    with LogFont do
//    begin
//      lfHeight := -17;  // Tamaño de la fuente
//      lfWeight := FW_BOLD;  // Negrita
//      lfQuality := CLEARTYPE_QUALITY;
//      StrCopy(lfFaceName, 'Lucida Sans'); // Tipo de letra
//    end;
//
//    TitleFont := CreateFontIndirect(LogFont);
//    SendMessage(hwnd, WM_SETFONT, TitleFont, MAKELPARAM(1, 0));
//  finally
//    ReleaseDC(hWnd, DC);
//  end;
//
//  // Forzar redibujado
//  SetWindowPos(hWnd, 0, 0, 0, 0, 0,
//    SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or SWP_FRAMECHANGED);
//end;

procedure TfrmOpenApp2.FormDeactivate(Sender: TObject);
begin
  inherited;
  //FormPaint(Sender);
end;

procedure TfrmOpenApp2.FormPaint(Sender: TObject);
// var
//   LabelHeight, LabelWidth, LabelTop: Integer;
//   caption_height, border3d_y, button_width, border_thickness: Integer;
//   MyCanvas: TCanvas;
//   CaptionBarRect: TRect;
 begin
//   CaptionBarRect := Rect(0, 0, 0, 0);
//   MyCanvas := TCanvas.Create;
//   MyCanvas.Handle := GetWindowDC(frmOpenApp2.Handle);
//   border3d_y := GetSystemMetrics(SM_CYEDGE);
//   button_width := GetSystemMetrics(SM_CXSIZE);
//   border_thickness := GetSystemMetrics(SM_CYSIZEFRAME);
//   caption_height := GetSystemMetrics(SM_CYCAPTION);
//   LabelWidth := Self.Canvas.TextWidth(Self.Caption);
//   LabelHeight := Self.Canvas.TextHeight(Self.Caption);
//   LabelTop := LabelHeight - (caption_height div 2);
//   CaptionBarRect.Left := border_thickness + border3d_y + button_width;
//   CaptionBarRect.Right := Self.Width - (border_thickness + border3d_y)
// 		- (button_width * 4);
//   CaptionBarRect.Top := border_thickness + border3d_y;
//   CaptionBarRect.Bottom := caption_height;
//   if Self.Active then
//     MyCanvas.Brush.Color := clActiveCaption
//   else
//     MyCanvas.Brush.Color := clInActiveCaption;
//   MyCanvas.Brush.Style := bsSolid;
//   MyCanvas.FillRect(CaptionBarRect);
//   MyCanvas.Brush.Style := bsClear;
//   MyCanvas.Font.Color := clCaptionText;
//   MyCanvas.Font.Name := Self.Font.Name;
//   MyCanvas.Font.Size := Self.Font.Size;
//   MyCanvas.Font.Style := MyCanvas.Font.Style + [fsBold];
//   DrawText(MyCanvas.Handle, PChar(' ' + Self.Caption), Length(Self.Caption) + 1,
//     CaptionBarRect, DT_CENTER or DT_SINGLELINE or DT_VCENTER);
//   MyCanvas.Free;
end;

procedure TfrmOpenApp2.FormResize(Sender: TObject);
begin
  inherited;
  //FormPaint(Sender);
end;

procedure TfrmOpenApp2.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self,
            'Tarifas');
end;

//procedure TfrmOpenApp2.AppException(Sender: TObject; E: Exception);
//begin
  //OJO!!! DA PROBLEMAS!!!!
  //Log(oConn, oUser, E.Message, Sender, tlCritical, E.ClassName);
  //('ERROR de clase:' + E.ClassName + ' with Message: ' + E.Message);
  //Exit;
//end;

procedure TfrmOpenApp2.CopiasdeSeguridad1Click(Sender: TObject);
begin
  CopiaSeguridad;
end;

//validar iban online https://www.iban.com
//validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

procedure TfrmOpenApp2.CopiaSeguridad;
var
  iButtonSel:Integer;
  s         :string;
  MyText    :TStringlist;
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
      s:= 'DROP DATABASE IF EXISTS factuzam; ' + sLineBreak +
                       'CREATE DATABASE factuzam ' +
                       '  CHARACTER SET utf8mb4 ' +
                       '       COLLATE utf8mb4_spanish_ci; ' +  sLineBreak +
                       'USE factuzam;' + sLineBreak + sLineBreak + s;
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
      inliblog.Log.LogInfo('Copia de seguridad creada en ' +
                           saveDialog.FileName);
      MyText.Free;
      ShowMessage('La copia se guardó exitosamente');
    end;
  end;
end;

procedure TfrmOpenApp2.FormActivate(Sender: TObject);
begin
  inherited;
  //FormPaint(Sender);
end;

procedure TfrmOpenApp2.FormClose(Sender: TObject; var Action: TCloseAction);
var
  I:Integer;
begin
  inherited;
  try
    inliblog.Log.LogInfo('Cerrando ventana principal');
    tmr1.Enabled := False;
    FreeAndNil(oFzaWinf);
    for I := Pred(pcPrincipal.PageCount) downto 0 do
      TcxPageControlPropertiesAccess((pcPrincipal).Properties).DoCloseTab(I);
    //FdmDataPerfiles.unqryPerfiles.Close;
    if (FdmDataPerfiles <> nil) then
      FreeAndNil(FdmDataPerfiles);
    FreeAndNil(FdmConn);

    //Application.Terminate;
    //Application.ProcessMessages;
     // ExitProcess(0);

    //Halt;
  finally
    inliblog.Log.LogInfo('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

procedure TfrmOpenApp2.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmOpenApp2.FormShow(Sender: TObject);
begin
  //si ocurre una excepción durante la carga,
  //se fuerza el cierre de la ventana
  if FException then
  begin
    PostMessage(Handle, wm_Close, 0, 0);
    Exit;
  end;
end;

//procedure TfrmOpenApp2.WMNCCreate(var Msg: TWMNCCreate);
//var
//  NCMetrics: TNonClientMetrics;
//begin
//  inherited;
//
//  NCMetrics.cbSize := SizeOf(TNonClientMetrics);
//  if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, NCMetrics.cbSize, @NCMetrics, 0) then
//  begin
//    // Cambiamos el nombre de la fuente
//    StrPCopy(NCMetrics.lfCaptionFont.lfFaceName, Self.Font.Name);
//    // Opcional: cambiar el tamaño (negativo para indicar altura en pixels)
//    NCMetrics.lfCaptionFont.lfHeight := Self.Font.Height;
//    // Opcional: hacer la fuente negrita
//    NCMetrics.lfCaptionFont.lfWeight := FW_BOLD;
//
//    SystemParametersInfo(SPI_SETNONCLIENTMETRICS, NCMetrics.cbSize, @NCMetrics, SPIF_UPDATEINIFILE);
//  end;
//end;

function TfrmOpenApp2.IsShortCut(var Message: TWMKey): Boolean;
var
  Component:TComponent;
  ts:TcxTabSheet;
  I:Integer;
  iPageActive:Integer;
  bFound:Boolean;
  aShortCut:TList<integer>;
begin
  I := 0;
  Result := True;
  bFound := False;
  //Defino los posibles ShortCuts que envío desde TActionList
  //Mejor usar el respositorio de ventanas y añadir el shortcut en algún sitio
  if (GetKeyState(VK_CONTROL) < 0) then
  begin
    //Empiezo con la 'A' de la tabla ascii. Lo minimo será Control + 'A'
    if (Message.CharCode >= 65) then
    begin
      aShortCut := oFzaWinf.GetShortCutListOrd;
      if (  (aShortCut.Contains(Message.CharCode))
         ) then
      begin
        //Sólo proceso si hay ventanas abiertas
        if (Self.pcPrincipal.PageCount) > 0 then
        begin
          //Sólo proceso el TActionList de la propia ventana activa
          iPageActive := pcPrincipal.ActivePageIndex;
          ts := (Self.pcPrincipal.Pages[iPageActive] as TcxTabSheet);
          //Sólo proceso si estoy con una página que tiene un form dentro
          if (ts.Controls[0] is TForm) then
          begin
            while ( (I >= 0) and
                    (I < (ts.Controls[0] as TForm).ComponentCount - 1) and
                    (not(bFound)) )  do
            begin
              Component := (ts.Controls[0] as TForm).Components[I];
              if (Component is TActionList) then
              begin
                //Si el ShortCut está en este ActionList, lo proceso
                if TActionList(Component).IsShortCut(Message) then
                begin
                  bFound := True;
                  Result := False;
                  Break;
                end;
              end;
              Inc(I);
            end;
          end;
        end;
      end;
      FreeAndNil(aShortCut);
    end;
  end;
  if (bFound = False) then
    Result := inherited IsShortCut(Message);
end;

procedure TfrmOpenApp2.mnuEjecutarScriptClick(Sender: TObject);
//var
//  openDialog        : topendialog; // lo tenemos persistente
begin
  if (mnuEjecutarScript.Visible) then
  begin
//    opendialog := TOpenDialog.Create(Self);
    opendialog.Title := 'Cargar script';
    openDialog.InitialDir := GetCurrentDir;
    undmp1.Connection := FDmConn.conUni;
    if openDialog.Execute then
    begin
      try
        undmp1.RestoreFromFile(opendialog.FileName, TEncoding.UTF8);
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
//      FreeAndNil(opendialog);
    end;
  end;
end;

procedure TfrmOpenApp2.sbCerrarClick(Sender: TObject);
//var
//  I:Integer;
begin
  inherited;
//  i := EncuentraPagina(pcPrincipal, 'Facturas');
//  if i<>-1 then
//    TcxPageControlPropertiesAccess((pcPrincipal).Properties).DoCloseTab(i);
end;

procedure TfrmOpenApp2.tmr1Timer(Sender: TObject);
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
    end;
  if (FdmConn = nil) or (not bIsConnected) then
  begin
    dxstsbr1.Panels.Items[3].Text := '' + ADateStr + ' ' +
                                            ATimeStr + 'NO Conn';
    inliblog.Log.LogError('Se ha perdido la conexión con la BBDD');
  end;
end;

procedure TfrmOpenApp2.undmp1Error(Sender: TObject; E: Exception; SQL: string;
  var Action: TErrorAction);
begin
  inherited;
  ShowMessage('Ha habido incidencias');
  Action := eaAbort;
  //https://forums.devart.com/viewtopic.php?t=21244
  //Continúa a pesar de los errores, por ejemplo si hay filas duplicadas
  //if (EUniError(E).ErrorCode = 1062) then // ER_DUP_ENTRY
  //  Action := eaContinue;
end;

procedure TfrmOpenApp2.WMFreeControl(var Message: TMessage);
begin
//
  TObject(Message.LParam).Free;
end;

//procedure TfrmOpenApp2.WMNCPaint(var Message: TWMNCPaint);
//var
//  DC: HDC;
//  R: TRect;
//  Flags: Integer;
//  TitleBarHeight: Integer;
//  OldFont, NewFont: HFONT;
//  LogFont: TLogFont;
//begin
//  // Primero llamamos al comportamiento predeterminado
//  inherited;
//
//  // Obtenemos el DC de la parte no cliente de la ventana
//  DC := GetWindowDC(Handle);
//  try
//    // Configuramos la fuente que queremos usar
//    ZeroMemory(@LogFont, SizeOf(LogFont));
//    with LogFont do
//    begin
//      lfHeight := -17;  // Tamaño de la fuente
//      lfWeight := FW_BOLD;  // FW_NORMAL para normal, FW_BOLD para negrita
//      StrPCopy(lfFaceName, 'Lucida Sans');  // Nombre de la fuente
//      lfQuality := CLEARTYPE_QUALITY;
//    end;
//
//    NewFont := CreateFontIndirect(LogFont);
//    OldFont := SelectObject(DC, NewFont);
//
//    // Obtenemos el rectángulo de la ventana
//    GetWindowRect(Handle, R);
//    OffsetRect(R, -R.Left, -R.Top);
//
//    // Altura de la barra de título
//    TitleBarHeight := GetSystemMetrics(SM_CYCAPTION);
//
//    // Configuramos el color y modo de fondo
//    SetBkMode(DC, TRANSPARENT);
//    SetTextColor(DC, RGB(0, 0, 0));  // Color del texto (negro en este caso)
//
//    // Definimos el rectángulo para el texto
//    R.Bottom := TitleBarHeight;
//    R.Left := 25;  // Ajusta esto según necesites
//
//    // Dibujamos el texto
//    Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
//    DrawText(DC, PChar(Caption), -1, R, Flags);
//
//    // Limpiamos
//    SelectObject(DC, OldFont);
//    DeleteObject(NewFont);
//  finally
//    ReleaseDC(Handle, DC);
//  end;
//
//  Message.Result := 0;
//end;


procedure TfrmOpenApp2.mnuLisVentasClick(Sender: TObject);
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

procedure TfrmOpenApp2.mnuAcercadeClick(Sender: TObject);
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

procedure TfrmOpenApp2.mnuArticulosClick(Sender: TObject);
begin
  if (mnuArticulos.Visible) then
    ShowMto(Self, 'Articulos');
end;

procedure TfrmOpenApp2.mnuClientesClick(Sender: TObject);
begin
  if (mnuClientes.Visible) then
    ShowMto(Self,
            'Clientes');
end;

procedure TfrmOpenApp2.mnuContadoresClick(Sender: TObject);
begin
  if (mnuContadores.Visible) then
    ShowMto(Self,
            'Contadores');
end;

procedure TfrmOpenApp2.mnuFacturasClick(Sender: TObject);
begin
  if (mnuFacturas.Visible) then
    ShowMto(Self,
            'Facturas');
end;

procedure TfrmOpenApp2.mnuFamiliasClick(Sender: TObject);
begin
  if (mnuFamilias.Visible) then
    ShowMto(Self,
            'Familias');
end;

procedure TfrmOpenApp2.mnuGeneradorProcesosClick(Sender: TObject);
begin
  if (mnuGeneradorProcesos.Visible) then
    ShowMto(Self,
            'GeneradorProcesos');
end;

procedure TfrmOpenApp2.mnuGruposClick(Sender: TObject);
begin
  if (mnuGrupos.Visible) then
    ShowMto(Self,
            'Grupos');
end;

procedure TfrmOpenApp2.mnuGruposdeIVAClick(Sender: TObject);
begin
  if (mnuGruposdeIVA.Visible) then
    ShowMto(Self,
            'IvasGrupos');
end;

procedure TfrmOpenApp2.mnuIvasClick(Sender: TObject);
begin
  if (mnuIvas.Visible) then
    ShowMto(Self,
            'Ivas');
end;

procedure TfrmOpenApp2.mnuEmpresasClick(Sender: TObject);
begin
  if (mnuEmpresas.Visible) then
    ShowMto(Self,
            'Empresas');
end;

procedure TfrmOpenApp2.mnuPaisesClick(Sender: TObject);
begin
  inherited;
  if (mnuPaises.Visible) then
    ShowMto(Self,
            'Paises');
end;

procedure TfrmOpenApp2.mnuPerfilesClick(Sender: TObject);
begin
  if (mnuPerfiles.Visible) then
    ShowMto(Self,
            'UsuariosPerfiles');
end;

procedure TfrmOpenApp2.mnuFormasdepagoClick(Sender: TObject);
begin
  if mnuFormasdepago.Visible then
    ShowMto(Self,
            'FormasdePago');
end;

procedure TfrmOpenApp2.mnuProveedoresClick(Sender: TObject);
begin
  if (mnuProveedores.Visible) then
    ShowMto(Self,
            'Proveedores');
end;

procedure TfrmOpenApp2.mnuUsuariosClick(Sender: TObject);
begin
  if (mnuUsuarios.Visible) then
    ShowMto(Self,
            'Usuarios');
end;
end.
