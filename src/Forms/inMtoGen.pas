{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoGen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsCore,
  dxSkinsDefaultPainters, cxPC, dxDockControl, cxControls, dxDockPanel,
  Vcl.ExtCtrls, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxNavigator, cxDBNavigator, Vcl.StdCtrls, Vcl.Buttons,
  cxContainer, cxEdit, cxLabel, dxBarBuiltInMenu, Vcl.Menus, cxButtons,
  dxSkinsLookAndFeelPainter, cxStyles, dxSkinscxPCPainter, inMtoPrincipal,
  dxSkinsForm, cxCustomData, cxFilter, cxData, cxDataStorage, dxDateRanges,
  Data.DB, cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, dxmdaset, cxTextEdit, dxBevel,
  inLibDevExp, cxGridExportLink, inLibUser, System.UITypes, UniDataPerfiles,
  Uni, inLibDir, inLibtb, Data.DBCommon, inLibWin, UniDataConn, cxBlobEdit,
  dxCore, dxScrollbarAnnotations, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs, dxSkinBlue, cxDBEdit, dxSkinBasic, dxSkinBlack,
  dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
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
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, System.Generics.Collections;
type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  THackWinControl = class(TWinControl);
  TfrmMtoGen = class(TfrmBase)
    pButtonPage: TPanel;
    pButtonRightBar: TPanel;
    pButtonBDStat: TPanel;
    pButtonGen: TPanel;
    pnStateDataSet: TPanel;
    lblEditMode: TcxLabel;
    pcPantalla: TcxPageControl;
    tsLista: TcxTabSheet;
    tsFicha: TcxTabSheet;
    btnGrabar: TcxButton;
    btnCancelar: TcxButton;
    cxGrdDBTabPrin: TcxGridDBTableView;
    cxGrdLvPrin: TcxGridLevel;
    cxgrdPrincipal: TcxGrid;
    dsTablaG: TDataSource;
    pnlTopPage: TPanel;
    pnlTopGrid: TPanel;
    sbExportExcel: TSpeedButton;
    edtBusqGlobal: TcxTextEdit;
    nvNavegador: TcxDBNavigator;
    lblTextoaBuscar: TcxLabel;
    tsPerfil: TcxTabSheet;
    pnlPerfilTop: TPanel;
    edtPerfilBusq: TcxTextEdit;
    lblTextoaBuscarPerfil: TcxLabel;
    pnlPerfilDetail: TPanel;
    cxgrdPerfil: TcxGrid;
    tvPerfil: TcxGridDBTableView;
    cxgrdlvlPerfil: TcxGridLevel;
    btnCargarColumnas: TcxButton;
    btnCargarCaptions: TcxButton;
    btnCargarVblesGlob: TcxButton;
    tvPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    tvPerfilKEY_PERFILES: TcxGridDBColumn;
    tvPerfilSUBKEY_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn;
    tvPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn;
    tvPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn;
    rbBBDD: TcxRadioButton;
    rbGrid: TcxRadioButton;
    sbGrabarGrid: TSpeedButton;
    sbResetGrid: TSpeedButton;
    pnlDataSetName: TPanel;
    lblTablaOrigen: TcxLabel;
    btnBusq: TcxButton;
    saveDialog: TdxSaveFileDialog;
    procedure FormCreate(Sender: TObject);
    //procedure btnSalirClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure sbExportExcelClick(Sender: TObject);
    procedure btnCargarColumnasClick(Sender: TObject);
    procedure btnCargarCaptionsClick(Sender: TObject);
    procedure btnCargarVblesGlobClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rbGridClick(Sender: TObject);
    procedure rbBBDDClick(Sender: TObject);
//    procedure edtPerfilBusqKeyPress(Sender: TObject; var Key: Char);
    procedure pcPantallaPageChanging(Sender: TObject; NewPage: TcxTabSheet;
      var AllowChange: Boolean);
    procedure sbResetGridClick(Sender: TObject);
    procedure sbGrabarGridClick(Sender: TObject);
    procedure btnBusqClick(Sender: TObject);
//    procedure pcPantallaChange(Sender: TObject);
    procedure pcPantallaEnter(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSalirClick(Sender: TObject);
    //procedure FormKeyPress(Sender: TObject; var Key: Char);
//    procedure edtBusqGlobalPropertiesValidate(Sender: TObject;
//     var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    //procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
//  procedure ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
  private
    procedure CargarPerfilesComunes(sUser:string = 'Todos');
    procedure SimulateTabKey;
  public
    tdmDataModule:TObject;
    sDataModuleName:string;
    oPerfilDic : TProfileDicc;
    sUso:string;
    pkFieldName:string;
    tsFichCab:TcxTabSheet;
    tsFichBut:TcxTabSheet;
    procedure ProcesarPerfiles;
    procedure AplicarEtiquetas;     virtual;
    procedure CrearTablaPrincipal;  virtual;
    procedure ResetForm;  virtual;
    procedure AbrirPerfiles(bTabVisible:Boolean);
    procedure CargarPerfilesParticulares; virtual;
//    constructor CreateWithDataModule(AOwner: TComponent; ADataModule: TdmBase);
  public
    destructor Destroy; override;
  end;
var
  frmMtoGen: TfrmMtoGen;
  sConsultaO:string;
  sConsultaP:string;

implementation

{$R *.dfm}

uses inMtoGenSearch,
     inLibGlobalVar,
     inLibShowMto,
     inLibLog,
     inMtoModalGenImpSave,
     UniDataGen;

{https://stackoverflow.com/questions/3979298/
 how-to-simulate-an-ondestroy-event-on-a-tframe-in-delphi}

//procedure TfrmMtoGen.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
//var
//  Message: TMessage absolute Msg;
//  Shift: TShiftState;
//begin
//  Handled := False;
//  if ActiveControl is TCustomEdit then
//  begin
//    Shift := KeyDataToShiftState(Msg.KeyData);
//    // add more cases if needed
//    Handled := (Shift = [ssCtrl]) and
//               (Msg.CharCode in [Ord('F'), Ord('A'), Ord('E'), Ord('K')]);
//    if Handled then
//      TCustomEdit(ActiveControl).DefaultHandler(Message);
//  end;
//  //else if ActiveControl is ... then ... // add more cases as needed
//end;

procedure TfrmMtoGen.AbrirPerfiles(bTabVisible:Boolean);
begin
  if (bTabVisible = true) then
  begin
    if (tdmDataModule = nil) then //es caja de busqueda modal
    begin
      with (Self as TfrmMtoSearch).unqryPerfiles do
      begin
        Connection := oConn;
        if ((Pos('Nothing', SQL.Text) > 0) or
            (Trim(SQL.Text) = '')
           ) then
        begin
          SQL.Text :='SELECT * '+
                     '  FROM fza_usuarios_perfiles ' +
                     ' WHERE (KEY_PERFILES = :NameFormModule)';
          ParamByName('NameFormModule').AsString := Self.Name;
        end;
        if (Active = false) then
          Open;
      end;
    end
    else //es modulo mantenimiento
      begin
        with (tdmDataModule as TdmBase).unqryPerfiles do
        begin
          tvPerfil.DataController.DataSource :=
                                          (tdmDataModule as TdmBase).dsPerfiles;
          Connection := oConn;
          if ( (Pos('Nothing', SQL.Text) > 0) or
               (Trim(SQL.Text) = '') or
               (Pos(':NameDataModule', SQL.Text ) > 0)
             ) then
          begin
            SQL.Text :=   'SELECT * '+
                          '  FROM fza_usuarios_perfiles ' +
                          ' WHERE ((KEY_PERFILES = :NameDataModule) ' +
                          '    OR  (KEY_PERFILES = :NameFormModule)) ';
            ParamByName('NameDataModule').AsString := Self.Name;
            ParamByName('NameFormModule').AsString := (tdmDataModule as TdmBase).Name;
          end;
          if (Active = false) then
            Open;
        end;
      end;
  end;
end;

procedure TfrmMtoGen.AplicarEtiquetas;
var
  i:integer;
  cComponent : TComponent;
  cxGrid: TcxGridDBTableView;
begin
  if (DsTablaG.Dataset <> nil) then
    lblTablaOrigen.Caption :=
                GetTableNameFromQuery((dsTablaG.Dataset as TUNIQuery).SQL.Text);
  if (StrToBool(GetPerfilValueDef(oPerfilDic, 'oCreateItems', 'False'))) then
  begin
   for cComponent in (Self as TComponent) do
   begin
     if cComponent.ClassNameis('TcxGridDBTableView') then
     begin
      if ((GetPerfilValueDef(oPerfilDic, 'oApplyWidth', 'False')) = 'True') then
       begin
         cxGrid := (cComponent as TcxGridDBTableView);
         cxGrid.ClearItems;
         cxGrid.DataController.CreateAllItems;
         cxGrid.ApplyBestFit();
       end;
     end;
   end;
  end;
  if ((GetPerfilValueDef(oPerfilDic, 'oApplyWidth', 'False')) = 'True') then
  begin
    for i:= 0 to Self.Componentcount - 1 do
    begin
      if (Self.Components[i].ClassNameis('TcxGridDBTableView')) then
      begin
        cxGrid := (Self.Components[i] as TcxGridDBTableView);
        if ((GetPerfilValueDef(oPerfilDic, cxGrid.Name + '__oApplyWidth',
                               'False')) = 'True') then
        begin
          PonerAnchosTitulos(cxGrid,
                             Self.Name,
                             oPerfilDic);
        end;
      end;
    end;
  end;
  //if ((GetPerfilValueDef(oPerfilDic, 'oApplySkin', 'False')) = 'True') then
//  SetSkin(GetPerfilValue(oPerfilDic, 'oSkin'));
  Self.Caption := GetPerfilValueDef(oPerfilDic, 'Caption', Self.Caption);
  if ((GetPerfilValueDef(oPerfilDic,
                         'oRenameComponents', 'False')) = 'True') then
    SetLabelForm(Self, oPerfilDic);
  tsPerfil.TabVisible :=
            StrToBool(GetPerfilValueDef(oPerfilDic, 'oMostrarPerfil', 'False'));
  {$IFDEF DEBUG}
    tsPerfil.TabVisible := True;
  {$ENDIF }
  if (tsPerfil.TabVisible = true) then
    AbrirPerfiles(tsPerfil.TabVisible);
end;

procedure TfrmMtoGen.btnCargarCaptionsClick(Sender: TObject);
begin
  inherited;
  CargarCaptions(Self, Self.Owner);
end;

procedure TfrmMtoGen.btnCargarColumnasClick(Sender: TObject);
var
  i:Integer;
  cxGrid : TcxGridDBTableView;
begin
  inherited;
  for i:= 0 to Self.Componentcount - 1 do
  begin
      if (Self.Components[i].ClassNameis('TcxGridDBTableView')) then
    begin
      cxGrid := (Self.Components[i] as TcxGridDBTableView);
      GetSettingsColumn(cxGrid, Self.Name, Self.Owner);
    end;
  end;
end;

procedure TfrmMtoGen.btnCargarVblesGlobClick(Sender: TObject);
begin
  inherited;
  CargarPerfilesComunes;
  CargarPerfilesParticulares;
end;

procedure TfrmMtoGen.btnGrabarClick(Sender: TObject);
begin
  inherited;
  Screen.Cursor := crHourGlass;
  GrabarGrids(Self);
  if oDmConn.conUni.InTransaction = True then
    oDmConn.conUni.Commit;
  Screen.Cursor := crDefault;
end;

procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
const
  WM_FREECONTROL = WM_USER;
var
  ts : TcxTabSheet;
  formP:TForm;
  //bCancelar:Boolean;
begin
  inherited;
//  bCancelar := True;
  if ( CheckOpenGrids(Self) ) then
  begin
     if ( Application.MessageBox( 'Hay datos no grabados. ¿Desea cancelar'+
                                  ' la entrada de datos?',
                                 'Mensaje de Advertencia',
                                 MB_YESNO ) = ID_YES ) then
     begin
       dsTablaG.Dataset.Cancel;
       Exit;
       //bCancelar := True;
     end
     else
     begin
       //bCancelar := False;
       btnGrabarClick(Sender);
     end;
  end;
  // NO liberar el DataModule manualmente
  // Se liberará automáticamente cuando se destruya el formulario (Self)
  // porque se creó con Owner = Self
  // Simplemente asignar nil a la referencia
  tdmDataModule := nil;
  ts := parent as TcxTabSheet;
  formP:=(ts.Parent.Parent.Parent as TForm);
  PostMessage(formP.Handle, WM_FREECONTROL, 0, LParam(ts));
end;

procedure TfrmMtoGen.sbGrabarGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar, IsSavingGrid: Boolean;
  sPermisos, sSavingGrid:String;
  i:Integer;
  cxGrid : TcxGridDBTableView;
begin
  inherited;
  //Grabar Grid
  bGuardar := False;
  formulario := TfrmModalGenImpSave.Create(Application);
  formulario.edtDescripcion.Enabled := False;
  formulario.edtNombreOrigen.Text := Self.Name;
  formulario.edtDescripcion.Text := 'Grabar Grids';
  formulario.ShowModal;
  if (formulario.sFicha = 'S') then
  begin
    bGuardar := True;
    sPermisos := formulario.cbbPermisos.Text;
  end;
  FreeAndNil(formulario);
  if bGuardar then
  begin
    CargarPerfilesComunes(sPermisos);
    if (tdmDataModule <> nil) then
      GrabarPerfilDatam((tdmDataModule as TdmBase), Self.Owner, sPermisos);
    CargarCaptions(Self, Self.Owner, sPermisos);
    if Not(GetPerfilValueDef(oPerfilDic, 'oApplyWidth', 'False') = 'True') then
    begin
        odmPerfiles.GrabarPerfil(sPermisos, Self.Name, 'oApplyWidth', 'True');
    end;
    for i:= 0 to Self.Componentcount - 1 do
    begin
        if (Self.Components[i].ClassNameis('TcxGridDBTableView')) then
        begin
          cxGrid := (Self.Components[i] as TcxGridDBTableView);
        // Hay que resetear aquí los registros que contengan el grid en perfiles
          (tdmDataModule as TdmBase).ResetGridsProfile(cxGrid.Name, Self.Name, sPermisos);
          IsSavingGrid := (GetPerfilValueDef(oPerfilDic,
                                             cxGrid.Name + '__' + 'oApplyWidth',
                                             'False') = 'True');
          if IsSavingGrid then
            sSavingGrid := 'True'
          else
            sSavingGrid := 'False';
          odmPerfiles.GrabarPerfil(sPermisos,
                                   Self.Name,
                                   cxGrid.Name + '__' +'oApplyWidth',
                                   sSavingGrid);
          GetSettingsColumnProfile(cxGrid, Self.Name, Self.Owner, sPermisos);
        end;
    end;
  end;
end;

procedure TfrmMtoGen.sbResetGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar: Boolean;
  sPermisos:String;
  i:Integer;
  cxGrid : TcxGridDBTableView;
begin
  inherited;
  //Grabar Grid
  bGuardar := False;
  formulario := TfrmModalGenImpSave.Create(Self);
  formulario.edtNombreOrigen.Text := Self.Name;
  formulario.edtDescripcion.Text := 'Reset Grids';
  formulario.ShowModal;
  if (formulario.sFicha = 'S') then
  begin
    bGuardar := True;
    sPermisos := formulario.cbbPermisos.Text;
  end;
  FreeAndNil(formulario);
  if bGuardar then
  begin
    for i:= 0 to Self.Componentcount - 1 do
    begin
        if (Self.Components[i].ClassNameis('TcxGridDBTableView')) then
      begin
        cxGrid := (Self.Components[i] as TcxGridDBTableView);
        (tdmDataModule as TdmBase).ResetGridsProfile(cxGrid.Name, Self.Name, sPermisos);
      end;
    end;
  end;
end;

procedure TfrmMtoGen.tsFichaShow(Sender: TObject);
var
  FocusControl: TWinControl;
//  ControlList: TStringList;
//  procedure AddControlInfo(AControl: TControl; ALevel: Integer);
//  var
//    I: Integer;
//    Indent: string;
//  begin
//    Indent := StringOfChar(' ', ALevel * 2);
//    if AControl is TWinControl then
//    begin
////      ControlList.Add(Format('%s%s (TabOrder: %d, CanFocus: %s)',
////        [Indent, AControl.Name, TWinControl(AControl).TabOrder,
////         BoolToStr(TWinControl(AControl).CanFocus, True)]));
//
//      for I := 0 to TWinControl(AControl).ControlCount - 1 do
//        AddControlInfo(TWinControl(AControl).Controls[I], ALevel + 1);
//    end;
//    //else
//    //  ControlList.Add(Format('%s%s (Not a TWinControl)',
//    //                         [Indent, AControl.Name]));
//  end;
  function FindNextFocusableControl(AParent: TWinControl): TWinControl;
  var
    I: Integer;
    Control: TControl;
    MinTabOrder: Integer;
  begin
    Result := nil;
    MinTabOrder := High(Integer);
    for I := 0 to AParent.ControlCount - 1 do
    begin
      Control := AParent.Controls[I];
      if (Control is TWinControl) and
         not (Control is TPanel) and          // Excluir TPanels
         not (Control is TcxPageControl) and  // Excluir TcxPageControl
         not (Control is TcxTabSheet) and     // Excluir TcxTabSheet
         TWinControl(Control).CanFocus and
         (TWinControl(Control).TabOrder > AParent.TabOrder) and
         (TWinControl(Control).TabOrder < MinTabOrder) then
      begin
        Result := TWinControl(Control);
        MinTabOrder := Result.TabOrder;
      end;
      if (Control is TWinControl) and
         (TWinControl(Control).ControlCount > 0) then
      begin
        Control := FindNextFocusableControl(TWinControl(Control));
        if Assigned(Control) and
           (TWinControl(Control).TabOrder > AParent.TabOrder) and
           (TWinControl(Control).TabOrder < MinTabOrder) then
        begin
          Result := TWinControl(Control);
          MinTabOrder := Result.TabOrder;
        end;
      end;
    end;
  end;
begin
  //ControlList := TStringList.Create;
//  try
    //AddControlInfo(tsFicha, 0);
    //ShowMessage('Controles en tsFicha:' + sLineBreak + ControlList.Text);
    FocusControl := FindNextFocusableControl(tsFicha);
    if Assigned(FocusControl) then
    begin
      if FocusControl.CanFocus then
      begin
        FocusControl.SetFocus;
        //ShowMessage('Foco establecido en: ' + FocusControl.Name +
        //           ' (TabOrder: ' + IntToStr(FocusControl.TabOrder) + ')');
      end;
    end;
    if edtBusqGlobal.CanFocus then
      edtBusqGlobal.SetFocus;
//    else
//    ShowMessage('No se encontró un control focusable después de la pestaña.');
//  finally
//    ControlList.Free;
//  end;
end;

procedure TfrmMtoGen.CargarPerfilesComunes(sUser:string = 'Todos');
begin
  with odmPerfiles do
  begin
    GrabarPerfil(sUser, Self.Name, 'oRenameComponents', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oCreateItems', 'True' );
    GrabarPerfil(sUser, Self.Name, 'oBusqGlobal', 'Grid' );
    GrabarPerfil(sUser, Self.Name, 'oApplyWidth', 'True' );
    GrabarPerfil(sUser, Self.Name, 'oMostrarPerfil', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oGetSQLFromDB', 'False' );
  end;
end;

procedure TfrmMtoGen.CargarPerfilesParticulares;
begin
  if (tdmDataModule <> nil) then
    GrabarPerfilDatam((tdmDataModule as TdmBase), Self.Owner);
end;

procedure TfrmMtoGen.CrearTablaPrincipal;
var
  sNameModule:string;
begin
  tdmDataModule := nil;
  sNameModule := '';
  sNameModule :=
     (Self.Owner as TfrmMtoPrincipal).oFzaWinf.GetDataModuleName(Self.UnitName +
                                                          '.' + Self.ClassName);
  if (sNameModule <> '') then
    tdmDataModule := CrearDataModule(sNameModule, Self);
  inherited;
end;

procedure TfrmMtoGen.cxGrdDBTabPrinDblClick(Sender: TObject);
begin
  inherited;
  if (tsFicha.TabVisible = True) then
    pcPantalla.ActivePage := tsFicha;
end;

//Desgraciadamente la pestaña al cerrar no llama nunca a Close, hay que poner
//el cierre de variables en Destroy
destructor TfrmMtoGen.Destroy;
begin
  if (oPerfilDic <> nil) then
    FreeAndNil(oPerfilDic);
  if (tdmDataModule <> nil) then
    FreeAndNil(tdmDataModule);
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                   Self.Caption + ' Cerrada');
  //FDataModules.Free;
  inherited;
end;

procedure TfrmMtoGen.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.Dataset <> nil) then
  begin
    if (dsTablaG.DataSet.State = dsInsert) then
    begin
      lblEditMode.Caption := 'Insertando';
    end;
    if (dsTablaG.DataSet.State = dsEdit) then
    begin
      lblEditMode.Caption := 'Editando';
    end;
    if (dsTablaG.DataSet.State = dsBrowse) then
    begin
      lblEditMode.Caption := 'Navegando';
    end;
      if (dsTablaG.DataSet.State = dsInactive) then
    begin
      lblEditMode.Caption := 'Inactivo';
      //Self.Close;
    end;
  end;
end;

//procedure TfrmMtoGen.edtPerfilBusqKeyPress(Sender: TObject; var Key: Char);
//begin
//  inherited;
////    BusqDataBase((tdmdatamodule.unqryPerfiles as TUniQuery),
////                 edtPerfilBusq.Text,
////                 sConsultaP);
//end;

procedure TfrmMtoGen.FormCreate(Sender: TObject);
var
  sModoBusq:String;
begin
  inherited;
  //FDataModules := TDictionary<TClass, TdmBase>.Create;
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
  //Application.ProcessMessages;
  tsFichCab := nil;
  tsFichBut := nil;
  Self.Position  := poScreenCenter;
  ProcesarPerfiles;
  sModoBusq := GetPerfilValueDef(oPerfilDic, 'oBusqGlobal', 'Database');
  if sModoBusq = 'DataBase' then
  begin
    rbBBDD.Checked := true;
    rbGrid.Checked := false;
  end
  else
  begin
    rbBBDD.Checked := false;
    rbGrid.Checked := true;
  end;
end;

procedure TfrmMtoGen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if ((Key = VK_RETURN) and (ActiveControl = nil)) then
    begin
      key := 0;
      SimulateTabKey;
    end;
end;

procedure TfrmMtoGen.SimulateTabKey;
var
  Inputs: array[0..1] of TInput;
begin
  // Prepare the input array
  ZeroMemory(@Inputs, SizeOf(Inputs));
  // Simulate Tab key press
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_TAB;
  // Simulate Tab key release
  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := VK_TAB;
  Inputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  // Send the input
  SendInput(2, Inputs[0], SizeOf(TInput));
end;

procedure TfrmMtoGen.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if (Key = VK_ESCAPE) then
  begin
    CancelarGrids(Owner);
    if ((pcPantalla.ActivePage = tsFicha)) then
        pcPantalla.ActivePage := tsLista;
//      else
//        if ( (dsTablaG.State = dsBrowse) and
//             (pcPantalla.ActivePage = tsLista)
//           ) then
//          if ( Application.MessageBox( '¿Desea abandonar la ficha?',
//                                   'Mensaje Advertencia',
//                                   MB_YESNO ) = ID_YES ) then
//         Close;
  end;
  if (dsTablaG.State = dsBrowse) then
  begin
    if (Key = VK_PRIOR) then
       nvNavegador.Buttons.Prior.Click;
    if (Key = VK_NEXT) then
       nvNavegador.Buttons.Next.Click;
    if (Key = VK_INSERT) then
      dsTablaG.DataSet.Insert;
    if (key = VK_HOME) then
      dsTablaG.DataSet.First;
    if (key = VK_END) then
      dsTablaG.DataSet.Last;
    if (key = VK_F2) then
      dsTablaG.DataSet.Edit;
  end;
    if (key = VK_F12) then
      if ((dsTablaG.State = dsEdit) or
          (dsTablaG.State = dsInsert)) then
        dsTablaG.DataSet.Post;
//  if ((Key = VK_RETURN) and (Shift <> [ssCtrl])) then
//    Perform(CM_DIALOGKEY, VK_TAB, 0);
end;

procedure TfrmMtoGen.FormShow(Sender: TObject);
begin
  inherited;
  if (tsLista.TabVisible = true) then
    pcPantalla.ActivePage := tsLista;
  ResetForm;
end;

procedure TfrmMtoGen.pcPantallaEnter(Sender: TObject);
begin
  inherited;
  //
end;

procedure TfrmMtoGen.pcPantallaPageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);

begin
  inherited;
  if ( (not NewPage.Visible) and
       (not NewPage.Enabled) and
       (NewPage.Name = 'tsFicha')) then
      AllowChange := False;
end;

procedure TfrmMtoGen.ProcesarPerfiles;
begin
  inLibUser.GetFormUserProfile(oPerfilDic, Self.Name);
  CrearTablaPrincipal;
  AplicarEtiquetas;
end;

procedure TfrmMtoGen.rbBBDDClick(Sender: TObject);
begin
  inherited;
  if (rbBBDD.Checked = true) then
    rbGrid.Checked := false
  else
    rbGrid.Checked := true;
end;

procedure TfrmMtoGen.rbGridClick(Sender: TObject);
begin
  inherited;
  if rbGrid.Checked = true then
    rbBBDD.Checked := false
  else
    rbBBDD.Checked := true;
end;

procedure TfrmMtoGen.ResetForm;
begin
  if edtBusqGlobal.CanFocus then
    edtBusqGlobal.SetFocus;
end;

procedure TfrmMtoGen.btnBusqClick(Sender: TObject);
//var
//  sBusq:string;
begin
  inherited;
//  if (rbBBDD.Checked = true) then
//    sBusq := 'Database'
//  else
//    sBusq := 'Grid';
//  if ( sBusq = 'Grid') then
//  begin
    //filtro del grid de Developer Express
    BusqAllGrid(cxGrdDBTabPrin,
                edtBusqGlobal.Text);
//  end
//  else
//    begin
//      //filtro desde la consulta sql, añadiendo las opc de búsqueda al sql
//      BusqDataBase( (dsTablaG.DataSet  as TUniQuery),
//                     edtBusqGlobal.Text,
//                     sConsultaO);
//    end;
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoGen.btnCancelarClick(Sender: TObject);
begin
  inherited;
  //Screen.Cursor := crHourGlass;
  CancelarGrids(Owner);
  //Screen.Cursor := crDefault;
end;

procedure TfrmMtoGen.sbExportExcelClick(Sender: TObject);
//var
//  saveDialog : tsavedialog;
begin
//  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir :=  GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
  if ( saveDialog.Execute ) then
    ExportGridToXLSX(saveDialog.FileName, cxGrdPrincipal);
//  saveDialog.Free;
end;

//procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
//var
//  i:Integer;
//  ts : TcxTabSheet;
//  pc:TcxPageControl;
//begin
//  inherited;
//  if (dsTablaG.DataSet <> nil) then
//    if ( dsTablaG.DataSet.State = dsInsert ) or
//       ( dsTablaG.DataSet.State = dsEdit ) then
//    begin
//       if ( Application.MessageBox( '¿Desea cancelar la entrada de datos?',
//                                   'Mensaje Advertencia',
//                                   MB_YESNO ) = ID_YES ) then
////         Close;
//    end;
//    ts := parent as TcxTabSheet;
//    pc := ts.PageControl;//else
//    i := EncuentraPagina(pc, 'Facturas');
//    if i<>-1 then
//       TcxPageControlPropertiesAccess((pc).Properties).DoCloseTab(i);
//end;

initialization

finalization
//  if oPerfilDic <> nil then
//    Sleep(0);

end.
