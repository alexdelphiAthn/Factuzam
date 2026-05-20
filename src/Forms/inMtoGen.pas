{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGen                                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base de los mantenimientos de Factuzam.                        }
{    Define grid, navegador, edicion CRUD y comportamiento heredable.          }
{******************************************************************************}
unit inMtoGen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsCore,
  dxSkinsDefaultPainters, cxPC, cxControls,
  Vcl.ExtCtrls, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxNavigator, cxDBNavigator, Vcl.StdCtrls, Vcl.Buttons,
  cxContainer, cxEdit, cxLabel, Vcl.Menus, cxButtons,
  dxSkinsLookAndFeelPainter, cxStyles, dxSkinscxPCPainter,
  dxSkinsForm, cxCustomData, cxFilter, cxData, cxDataStorage, dxDateRanges,
  Data.DB, cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridDBDataDefinitions, cxGrid, dxmdaset,
  cxTextEdit, dxBevel,
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
  dxSkinXmas2008Blue, System.Generics.Collections, System.Actions, Vcl.ActnList;
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
    saveDialog: TdxSaveFileDialog;
    tmrBusqGlobal: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinDblClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure sbExportExcelClick(Sender: TObject);
    procedure btnCargarColumnasClick(Sender: TObject);
    procedure btnCargarCaptionsClick(Sender: TObject);
    procedure btnCargarVblesGlobClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rbGridClick(Sender: TObject);
    procedure rbBBDDClick(Sender: TObject);
    procedure pcPantallaPageChanging(Sender: TObject;
                                     NewPage: TcxTabSheet;
                                     var AllowChange: Boolean);
    procedure sbResetGridClick(Sender: TObject);
    procedure sbGrabarGridClick(Sender: TObject);
    procedure edtBusqGlobalPropertiesChange(Sender: TObject);
    procedure tmrBusqGlobalTimer(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSalirClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    // Conexion propia del Mto (Fase 1 multithreading). Se clona de `oConn`
    // global al crear el data module y se reasigna a todas las queries/SPs
    // via TdmBase.ReasignarConexion. Asi dos pestañas dejan de serializarse
    // sobre la misma TUniConnection — cada una agarra una conexion fisica
    // distinta del pool. Liberada en Destroy DESPUES del data module para
    // que los Close implicitos de las queries no queden colgando.
    FConn: TUniConnection;
    procedure CargarPerfilesComunes(sUser:string = 'Todos');
//    procedure CollectSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
//                                        const sName: string;
//                                        const sProfile: string;
//                                        AList: TPerfilList);
  protected
    // Clona los params relevantes de `oConn` global y devuelve una nueva
    // TUniConnection ya conectada (usa el pool de UniDAC). Los Mtos
    // especializados pueden override para variantes (p.ej. una replica
    // de solo-lectura), aunque por defecto basta el clon plano.
    function CrearConexionPropia: TUniConnection; virtual;
  public
    tdmDataModule:TObject;
    sDataModuleName:string;
    oPerfilDic : TProfileDicc;
    sUso:string;
    pkFieldName:string;
    tsFichCab:TcxTabSheet;
    tsFichBut:TcxTabSheet;
    procedure SimulateTabKey;
    procedure ProcesarPerfiles;
    procedure AplicarEtiquetas;     virtual;
    procedure CrearTablaPrincipal;  virtual;
    procedure ResetForm;  virtual;
    procedure AbrirPerfiles(bTabVisible:Boolean);
    procedure CargarPerfilesParticulares; virtual;
    // Resuelve los codigos ART y SKU del registro activo en `dsTablaG`.
    // Recorre la lista de alias habituales (CODIGO_ART_*, CODIGO_UNIDAD_*).
    // Los Mtos que necesiten otra fuente pueden sobreescribirlo (p.ej.
    // los que tienen el articulo activo en un sub-grid: facturas, pedidos,
    // albaranes, tarifas). Para esos casos basta llamar a
    // `inLibFotos.LeerArtSkuDeDataSet` pasando el DataSet del grid de
    // detalle.
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); virtual;
    // Lista de DataSources que la pantalla flotante de fotos debe
    // engancharse para refrescar al cambiar de registro activo. Default
    // = [dsTablaG]. Los Mtos con sub-grids (lineas, SKUs, stock,
    // movimientos...) lo sobreescriben para incluir tambien esos
    // DataSources, asi la foto sigue al cursor en cualquier pestaña.
    function DataSourcesParaFoto: TArray<TDataSource>; virtual;
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
     UniDataGen, uGenericIfThen, inMtoPrincipal,
     inLibFotos, inMtoFotoArticulo;

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
                     ' WHERE (KEY_USUPER = :NameFormModule)';
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
                          ' WHERE ((KEY_USUPER = :NameDataModule) ' +
                          '    OR  (KEY_USUPER = :NameFormModule)) ';
            ParamByName('NameDataModule').AsString := Self.Name;
            ParamByName('NameFormModule').AsString :=
                                                (tdmDataModule as TdmBase).Name;
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
  cxGrid: TcxCustomGridTableView;
  oDBCtrl: TcxGridDBDataController;
  oGrids: TList<TcxCustomGridTableView>;
begin
  if (DsTablaG.Dataset <> nil) then
    lblTablaOrigen.Caption :=
                GetTableNameFromQuery((dsTablaG.Dataset as TUNIQuery).SQL.Text);
  oGrids := TList<TcxCustomGridTableView>.Create;
  try
    for i := 0 to Self.ComponentCount - 1 do
      if Self.Components[i] is TcxCustomGridTableView then
        oGrids.Add(TcxCustomGridTableView(Self.Components[i]));
    if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oCreateItems', 'False')),
                'True') then
    begin
      for cxGrid in oGrids do
      begin
        if SameText(Trim(GetPerfilValueDef(oPerfilDic,
                          cxGrid.Name
                            + '__oCreateItems', 'False')), 'True') then
        begin
          oDBCtrl := GetDBDataController(cxGrid);
          if oDBCtrl <> nil then
          begin
            cxGrid.BeginUpdate;
            try
              oDBCtrl.CreateAllItems;
            finally
              cxGrid.EndUpdate;
            end;
          end;
        end;
      end;
    end;
    if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oApplyWidth', 'False')),
                'True') then
    begin
      for cxGrid in oGrids do
      begin
        // Segunda validación segura
        if SameText(Trim(GetPerfilValueDef(oPerfilDic,
                          cxGrid.Name + '__oApplyWidth', 'False')), 'True') then
        begin
          PonerAnchosTitulos(cxGrid, Self.Name, oPerfilDic);
          RestaurarFocoGrid(cxGrid, oPerfilDic);
        end;
      end;
    end;
  finally
    FreeAndNil(oGrids);
  end;
  Self.Caption := GetPerfilValueDef(oPerfilDic, 'Caption', Self.Caption);
  if SameText(Trim(GetPerfilValueDef(oPerfilDic, 'oRenameComponents', 'False')),
              'True') then
    SetLabelForm(Self, oPerfilDic);

end;

procedure TfrmMtoGen.btnCargarCaptionsClick(Sender: TObject);
begin
  inherited;
  CargarCaptions(Self, Self.Owner);
end;

procedure TfrmMtoGen.btnCargarColumnasClick(Sender: TObject);
var
  i:Integer;
  cxGrid : TcxCustomGridTableView;
begin
  inherited;
  for i:= 0 to Self.Componentcount - 1 do
  begin
      if (Self.Components[i] is TcxCustomGridTableView) then
    begin
      cxGrid := TcxCustomGridTableView(Self.Components[i]);
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
var
  ConnGrabar: TUniConnection;
begin
  inherited;
  if tdmDataModule = nil then
    Exit;
  // Si el Mto tiene conexion propia (Fase 1), la transaccion DEBE ir
  // contra ella: las queries del data module ya apuntan a FConn via
  // ReasignarConexion, asi que un StartTransaction sobre oConn no las
  // cubriria y el commit/rollback no afectaria a los ApplyUpdates.
  if Assigned(FConn) then
    ConnGrabar := FConn
  else
    ConnGrabar := oDmConn.conUni;
  Screen.Cursor := crHourGlass;
  try
    try
       if not ConnGrabar.InTransaction then
         ConnGrabar.StartTransaction;
      GrabarDatasets(tdmDataModule as TDataModule);
      if ConnGrabar.InTransaction then
        ConnGrabar.Commit;
      ShowMessage('Datos guardados correctamente');
    except
      on E: EAbort do
      begin
        // EAbort es la excepción silenciosa estándar (BeforePost que
        // llama a Abort cuando el dataset no debe persistirse por la
        // vía estándar, p. ej. vistas en JOIN que se actualizan a mano).
        // Cerramos la transacción y salimos sin mensaje.
        if ConnGrabar.InTransaction then
          ConnGrabar.Rollback;
      end;
      on E: Exception do
      begin
        if ConnGrabar.InTransaction then
          ConnGrabar.Rollback;
        raise Exception.Create('Error al grabar: ' + E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGen.btnSalirClick(Sender: TObject);
const
  WM_FREECONTROL = WM_USER + 1;
var
  ts: TcxTabSheet;
  formMain: TCustomForm;
begin
  inherited;
  if not (Self.Parent is TcxTabSheet) then
    Exit;
  if (tdmDataModule <> nil) and
     CheckOpenDatasets(tdmDataModule as TDataModule) then
  begin
    if Application.MessageBox('Hay datos no grabados. ' +
                              '¿Desea grabar los cambios?',
                              'Mensaje de Advertencia',
                              MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      btnGrabarClick(Sender);
      ShowMessage('Cambios grabados');
    end
    else
    begin
      CancelarDatasets(tdmDataModule as TDataModule);
      ShowMessage('Cambios revertidos/cancelados');
    end;
  end;
  if (Self.Parent is TcxTabSheet) then
  begin
    ts := TcxTabSheet(Self.Parent);
    formMain := Application.MainForm;
    PostMessage(formMain.Handle, WM_FREECONTROL, 0, LParam(ts));
  end;
end;

procedure TfrmMtoGen.sbGrabarGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar: Boolean;
  sPermisos: string;
  i: Integer;
  cxGrid: TcxCustomGridTableView;
  oList: TPerfilList;
  item: TPerfilItem;
begin
  inherited;
  bGuardar := False;

  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text   := Self.Name;
    formulario.edtDescripcion.Text    := 'Grabar Grids';
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
    begin
      bGuardar  := True;
      sPermisos := formulario.cbbPermisos.Text;
    end;
  finally
    FreeAndNil(formulario);
  end;

  if not bGuardar then Exit;

  Screen.Cursor := crHourGlass;
  (tdmDataModule as TdmBase).ResetGridsProfile('', Self.Name, sPermisos);
  oList := TPerfilList.Create;
  try
    // 1. Perfiles comunes
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    for var par in [
      TPair<string,string>.Create('oRenameComponents',
        GetPerfilValueDef(oPerfilDic, 'oRenameComponents', 'False')),
      TPair<string,string>.Create('oCreateItems',
        GetPerfilValueDef(oPerfilDic, 'oCreateItems',      'False')),
      TPair<string,string>.Create('oBusqGlobal',
        GetPerfilValueDef(oPerfilDic, 'oBusqGlobal',       'Grid')),
      TPair<string,string>.Create('oApplyWidth',       'True'),
      TPair<string,string>.Create('oMostrarPerfil',
        GetPerfilValueDef(oPerfilDic, 'oMostrarPerfil',    'False')),
      TPair<string,string>.Create('oGetSQLFromDB',
        GetPerfilValueDef(oPerfilDic, 'oGetSQLFromDB',     'False'))
    ] do
    begin
      item.SubKey := par.Key;
      item.Value  := par.Value;
      oList.Add(item);
    end;

    // 2. Ajustes de cada grid
    for i := 0 to Self.ComponentCount - 1 do
      if Self.Components[i] is TcxCustomGridTableView then
      begin
        cxGrid := TcxCustomGridTableView(Self.Components[i]);

        // reset sigue siendo su propia transacción (borra primero)


        item.SubKey := cxGrid.Name + '__oApplyWidth';
        item.Value  := 'True';
        oList.Add(item);

        item.SubKey := cxGrid.Name + '__oCreateItems';
        item.Value  := GetPerfilValueDef(oPerfilDic,
                                         cxGrid.Name + '__oCreateItems',
                                         'False');
        oList.Add(item);

        CollectSettingsColumnProfile(cxGrid, Self.Name, sPermisos, oList);
      end;
    oConn.StartTransaction;
    try
      odmPerfiles.GrabarPerfilesBatch(oList);
      // aquí puedes seguir llamando a GrabarPerfilDatam / CargarCaptions
      // si antes los refactorizas también para que acepten la lista
      oConn.Commit;
    except
      oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oList);
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGen.sbResetGridClick(Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  bGuardar: Boolean;
  sPermisos:String;
  i:Integer;
  cxGrid : TcxCustomGridTableView;
begin
  inherited;
  bGuardar := False;
  formulario := TfrmModalGenImpSave.Create(Self);
  try
    formulario.edtNombreOrigen.Text := Self.Name;
    formulario.edtDescripcion.Text := 'Reset Grids';
    formulario.ShowModal;
    if (formulario.sFicha = 'S') then
    begin
      bGuardar := True;
      sPermisos := formulario.cbbPermisos.Text;
    end;
  finally
    FreeAndNil(formulario);
  end;
  if bGuardar then
  begin
    for i:= 0 to Self.Componentcount - 1 do
    begin
      if (Self.Components[i] is TcxCustomGridTableView) then
      begin
        cxGrid := TcxCustomGridTableView(Self.Components[i]);
        (tdmDataModule as TdmBase).ResetGridsProfile(cxGrid.Name,
                                                     Self.Name,
                                                     sPermisos);
      end;
    end;
  end;
end;

procedure TfrmMtoGen.tsFichaShow(Sender: TObject);
var
  FocusControl: TWinControl;
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
    FocusControl := FindNextFocusableControl(tsFicha);
    if Assigned(FocusControl) then
    begin
      if FocusControl.CanFocus then
      begin
        FocusControl.SetFocus;
      end;
    end;
end;

procedure TfrmMtoGen.CargarPerfilesComunes(sUser:string = 'Todos');
begin
  with odmPerfiles do
  begin
    GrabarPerfil(sUser, Self.Name, 'oRenameComponents', 'False' );
    GrabarPerfil(sUser, Self.Name, 'oCreateItems', 'False' );
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
  if Self.Owner <> nil then
    sNameModule :=
     (Self.Owner as TfrmMtoPrincipal).oFzaWinf.GetDataModuleName(Self.UnitName +
                                                          '.' + Self.ClassName);
  if (sNameModule <> '') then
  begin
    tdmDataModule := CrearDataModule(sNameModule, Self);
    // Conexion propia del Mto: la creamos si todavia no existe y la
    // inyectamos en todas las queries/SPs del data module recien creado.
    // El DataModule sigue arrancando con `oConn` en su DoCreate, lo cual
    // es necesario para que el .dfm streaming no se queje; aqui hacemos
    // el switch antes de cualquier Open real.
    if FConn = nil then
    try
      FConn := CrearConexionPropia;
    except
      on E: Exception do
      begin
        inliblog.Log.LogError('No se pudo crear conexion propia para ' +
          Self.Name + ': ' + E.Message + '. Se sigue usando oConn global.');
        FConn := nil;
      end;
    end;
    if Assigned(FConn) then
      (tdmDataModule as TdmBase).ReasignarConexion(FConn);
  end;
  inherited;
end;

function TfrmMtoGen.CrearConexionPropia: TUniConnection;
begin
  Result := TUniConnection.Create(Self);
  try
    Result.LoginPrompt := False;
    Result.ProviderName := oConn.ProviderName;
    Result.Server       := oConn.Server;
    Result.Port         := oConn.Port;
    Result.Database     := oConn.Database;
    Result.Username     := oConn.Username;
    Result.Password     := oConn.Password;
    // Mismos ajustes que la conexion global (UniDataConn.connBeforeConnect).
    // Con los mismos params, las conexiones fisicas salen del mismo pool.
    Result.Pooling := True;
    Result.PoolingOptions.ConnectionLifetime := 0;
    Result.PoolingOptions.Validate := True;
    Result.SpecificOptions.Values['MySQL.Interactive'] := 'True';
    Result.SpecificOptions.Values['ConnectionTimeout'] := '30';
    Result.Options.LocalFailover    := True;
    Result.Options.DisconnectedMode := True;
    // Reusamos el handler de errores y el AfterConnect (timeout extendido)
    // de la conexion global para mantener comportamiento consistente.
    Result.OnError       := oConn.OnError;
    Result.AfterConnect  := oConn.AfterConnect;
    Result.Connect;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TfrmMtoGen.cxGrdDBTabPrinDblClick(Sender: TObject);
begin
  inherited;
  if (tsFicha.TabVisible = True) then
    pcPantalla.ActivePage := tsFicha;
end;

destructor TfrmMtoGen.Destroy;
begin
  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  if (oPerfilDic <> nil) then
    FreeAndNil(oPerfilDic);
  if (tdmDataModule <> nil) then
    FreeAndNil(tdmDataModule);
  // Liberar la conexion propia DESPUES del data module: las queries del
  // data module aun referencian FConn durante su destrucion para los Close
  // implicitos. Si soltamos antes, AVs garantizados.
  if Assigned(FConn) then
  begin
    try
      if FConn.Connected then
        FConn.Disconnect;
    except
      // Disconnect en pool no deberia fallar, pero si lo hace no queremos
      // que el destructor lance.
    end;
    FreeAndNil(FConn);
  end;
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                   Self.Caption + ' Cerrada');
  frmMtoGen := nil;
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
    end;
  end;
end;

procedure TfrmMtoGen.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  SendMessage(Self.Handle, WM_SETREDRAW, WPARAM(False), 0);
  // Si la pantalla flotante de fotos estaba enganchada a DataSources
  // de este Mto (vinculados con Ctrl+Alt+F), la desenganchamos antes
  // de que sus DataSources se liberen con el data module. Asi no
  // quedan punteros colgando en FHooksDataSource.
  if Assigned(frmFotoArticulo) then
    frmFotoArticulo.VincularDataSources([], nil);
  if Assigned(cxGrdDBTabPrin) then
    cxGrdDBTabPrin.DataController.DataSource := nil;

  if Assigned(tvPerfil) then
    tvPerfil.DataController.DataSource := nil;

  if Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  Action := caFree;
end;

procedure TfrmMtoGen.FormCreate(Sender: TObject);
var
  sModoBusq:String;
begin
  inherited;
  Self.HandleNeeded; //da problemas
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
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
  if (Key = VK_ESCAPE) then
  begin
    CancelarGrids(Owner);
    key := 0;
  end;
  if ((Key = VK_RETURN) and (ActiveControl = nil)) then
  begin
    key := 0;
    SimulateTabKey;
    Exit;
  end;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin

  end;
  if (Key = VK_DELETE) and (ssCtrl in Shift) then
  begin
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and not
       dsTablaG.DataSet.IsEmpty and (dsTablaG.State = dsBrowse) then
    begin
      if Application.MessageBox(
        '¿Estás seguro de que deseas eliminar este registro?',
                                'Confirmar eliminación',
                                MB_YESNO + MB_ICONWARNING) = ID_YES then
      begin
        dsTablaG.DataSet.Delete;
      end;
    end;
    Key := 0; // Evitamos que la pulsación se propague
    Exit;     // Salimos para no evaluar más condiciones
  end;
  // -------------------------------------------------------------------

  if (dsTablaG.State = dsBrowse) then
  begin
    if (Key = VK_PRIOR) then
    begin
      nvNavegador.Buttons.Prior.Click;
      Key := 0;
    end
    else if (Key = VK_NEXT) then
    begin
      nvNavegador.Buttons.Next.Click;
      Key := 0;
    end
    else if (Key = VK_INSERT) then
    begin
      dsTablaG.DataSet.Insert;
      Key := 0;
    end
    else if (Key = VK_HOME) then
    begin
      dsTablaG.DataSet.First;
      Key := 0;
    end
    else if (Key = VK_END) then
    begin
      dsTablaG.DataSet.Last;
      Key := 0;
    end
    else if (Key = VK_F2) then
    begin
      dsTablaG.DataSet.Edit;
      Key := 0;
    end;
  end;
  if (key = VK_F12) then
  begin
    if ((dsTablaG.State = dsEdit) or
        (dsTablaG.State = dsInsert)) then
      dsTablaG.DataSet.Post;
    key := 0;
  end;
  // Ctrl + Alt + F -> Foto del articulo / SKU activo
  if (Key = Ord('F')) and (ssCtrl in Shift) and (ssAlt in Shift) then
  begin
    var sArt: string := '';
    var sSku: string := '';
    ResolverArtSkuActivo(sArt, sSku);
    if sArt <> '' then
    begin
      MostrarFotoFlotante(Self, sArt, sSku);
      // Auto-refresh: la pantalla flotante se engancha a todos los
      // DataSources que el Mto declara en DataSourcesParaFoto (por
      // defecto solo dsTablaG; los Mtos con sub-grids sobreescriben
      // para incluir tambien esos data sources).
      if Assigned(frmFotoArticulo) then
        frmFotoArticulo.VincularDataSources(DataSourcesParaFoto,
                                            ResolverArtSkuActivo);
    end;
    Key := 0;
  end;
end;

procedure TfrmMtoGen.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dsTablaG <> nil) and (dsTablaG.DataSet <> nil) then
    inLibFotos.LeerArtSkuDeDataSet(dsTablaG.DataSet, ACodArt, ACodSku);
end;

function TfrmMtoGen.DataSourcesParaFoto: TArray<TDataSource>;
begin
  // Default: solo el data source principal. Los Mtos que tengan
  // sub-grids con articulo / SKU activo sobreescriben para anadir
  // tambien esos DataSources.
  Result := [dsTablaG];
end;

procedure TfrmMtoGen.SimulateTabKey;
var
  Inputs: array[0..1] of TInput;
begin
  ZeroMemory(@Inputs, SizeOf(Inputs));
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_TAB;
  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := VK_TAB;
  Inputs[1].ki.dwFlags := KEYEVENTF_KEYUP;
  SendInput(2, Inputs[0], SizeOf(TInput));
end;

procedure TfrmMtoGen.FormShow(Sender: TObject);
begin
  inherited;
  ResetForm;
  // Si la pantalla flotante de fotos ya esta abierta (el usuario
  // pulso Ctrl+Alt+F en otro Mto), la re-vinculamos a este. Si no
  // esta abierta, no la abrimos: que aparezca solo cuando el usuario
  // lo pida con Ctrl+Alt+F.
  if (Self.Owner is TfrmMtoPrincipal) then
    TfrmMtoPrincipal(Self.Owner).EngancharFotoAlMto(Self);
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
  inLibUser.GetFormUserProfile(oPerfilDic,
                               Self.Name,
                               inLibGlobalVar.oUser,
                               inLibGlobalVar.oGroup);
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
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
//  if edtBusqGlobal.CanFocus then
//    edtBusqGlobal.SetFocus;
end;

procedure TfrmMtoGen.edtBusqGlobalPropertiesChange(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  tmrBusqGlobal.Enabled := True;
end;

procedure TfrmMtoGen.tmrBusqGlobalTimer(Sender: TObject);
begin
  inherited;
  tmrBusqGlobal.Enabled := False;
  BusqAllGrid(cxGrdDBTabPrin,
              edtBusqGlobal.Text);
  if ((pcPantalla.ActivePage <> tsLista) and (tsLista.TabVisible = true)) then
    pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoGen.btnCancelarClick(Sender: TObject);
begin
  inherited;
  CancelarGrids(Owner);
end;

procedure TfrmMtoGen.sbExportExcelClick(Sender: TObject);
begin
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir :=  GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
  if ( saveDialog.Execute ) then
    ExportGridToXLSX(saveDialog.FileName, cxGrdPrincipal);
end;

initialization

finalization

end.
