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
  dxSkinXmas2008Blue, System.Generics.Collections, System.Actions, Vcl.ActnList,
  System.Threading;
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
    alMtoGen: TActionList;
    actEliminarRegistro: TAction;
    actRegistroAnterior: TAction;
    actRegistroSiguiente: TAction;
    actInsertarRegistro: TAction;
    actPrimerRegistro: TAction;
    actUltimoRegistro: TAction;
    actEditarRegistro: TAction;
    actGrabarRegistro: TAction;
    actFotoArticulo: TAction;
    actConsultaStock: TAction;
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
    procedure actEliminarRegistroExecute(Sender: TObject);
    procedure actEliminarRegistroUpdate(Sender: TObject);
    procedure actNavBrowseUpdate(Sender: TObject);
    procedure actRegistroAnteriorExecute(Sender: TObject);
    procedure actRegistroSiguienteExecute(Sender: TObject);
    procedure actInsertarRegistroExecute(Sender: TObject);
    procedure actPrimerRegistroExecute(Sender: TObject);
    procedure actUltimoRegistroExecute(Sender: TObject);
    procedure actEditarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroExecute(Sender: TObject);
    procedure actGrabarRegistroUpdate(Sender: TObject);
    procedure actFotoArticuloExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
  private
    // Conexion propia del Mto (Fase 1 multithreading). Se clona de `oConn`
    // global al crear el data module y se reasigna a todas las queries/SPs
    // via TdmBase.ReasignarConexion. Asi dos pestañas dejan de serializarse
    // sobre la misma TUniConnection — cada una agarra una conexion fisica
    // distinta del pool. Liberada en Destroy DESPUES del data module para
    // que los Close implicitos de las queries no queden colgando.
    FConn: TUniConnection;
    // Overlay para Fase 2 (background): panel que cubre el Mto entero
    // mientras corre una tarea en thread. Otros tabs siguen interactivos
    // porque cada Mto vive embebido en su propio TcxTabSheet.
    FOverlayOcupado: TPanel;
    FTareasEnCurso: Integer;
    // Lista de ITask vivos para poder esperarlos en Destroy. Sin esto,
    // cerrar un tab mientras un Open async sigue ejecutando provoca AV:
    // el thread accederia a la TUniQuery / FConn ya liberadas. La lista
    // se crea lazy en EjecutarEnBackground y se libera en Destroy
    // despues del WaitForAll.
    FTareasActivas: TList<ITask>;
    // Popup de selector de columnas (boton derecho en grid)
    FPopMenuColumnas: TPopupMenu;
    FSqlOriginalTablaG: string;
    FCamposGuia: TStringList;
    procedure PopMenuColumnasPopup(Sender: TObject);
    procedure PopMenuColumnaClick(Sender: TObject);
    procedure PopMenuNuevaGuiaClick(Sender: TObject);
    procedure BorrarGuiasGrid;
    procedure AplicarGuiasGrid(AQuery: TUniQuery);
    procedure CargarPerfilesComunes(sUser:string = 'Todos');
//    procedure CollectSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
//                                        const sName: string;
//                                        const sProfile: string;
//                                        AList: TPerfilList);
  protected
    // Indica si las teclas de navegacion (PgUp, PgDn, Home, End, Ins, F2)
    // deben activar las acciones del TActionList base. Los Mtos con
    // editores multilinea (SynEdit, etc.) sobreescriben para devolver
    // False cuando el editor tiene el foco.
    function PermitirNavegacionTeclas: Boolean; virtual;
    // Clona los params relevantes de `oConn` global y devuelve una nueva
    // TUniConnection ya conectada (usa el pool de UniDAC). Los Mtos
    // especializados pueden override para variantes (p.ej. una replica
    // de solo-lectura), aunque por defecto basta el clon plano.
    function CrearConexionPropia: TUniConnection; virtual;
    // Crea/oculta el overlay "Procesando..." sobre este Mto. Reentrante:
    // varias llamadas a Bloquear=True solo muestran el overlay una vez,
    // y solo se oculta cuando todas se compensan con un False.
    procedure BloquearTabPorOcupado(Bloquear: Boolean);
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
    // Hook que cada Mto puede sobreescribir para añadir entradas extra al
    // batch que sbGrabarGridClick volcara en fza_usuarios_perfiles (por
    // ejemplo: filtros de carga del Mto, opciones particulares...). Recibe
    // la lista de perfiles ya iniciada con KeyPerfil = Self.Name y
    // UserGroup = sPermisos: solo hay que rellenar SubKey + Value y
    // hacer Add. Por defecto no anyade nada.
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); virtual;
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
    // Ejecuta `AccionBG` en un thread aparte (TTask.Run del RTL). Mientras
    // corre, este Mto queda bloqueado con overlay "Procesando...", pero
    // los demas tabs siguen 100% interactivos. Al terminar (OK o
    // excepcion) se invoca `AlTerminar` en el main thread: el parametro
    // es '' si todo fue bien, o el mensaje de la excepcion si hubo fallo.
    // OJO: `AccionBG` NO puede tocar la UI ni datasets vinculados a
    // grids. Solo operaciones BBDD puras (ExecProc, ExecSQL, calculos).
    procedure EjecutarEnBackground(AccionBG: TProc;
                                   AlTerminar: TProc<string>);
    // Carga inicial de la lista principal (unqryTablaG) en thread. El
    // grid se suelta del DataSource antes del Open y se revincula cuando
    // termina, evitando que cxGrid acceda al dataset durante el fetch.
    // Si la query ya esta activa o no hay data module, no hace nada.
    procedure AbrirTablaPrincipalAsync;
    // Variante sincrona (comportamiento clasico): bloquea hasta tener
    // los datos. La usa ShowMto cuando se invoca con parametro de
    // busqueda — BuscarTabla.Locate necesita la query activa al volver.
    procedure AbrirTablaPrincipalSincrono;
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
     inLibFotos, inMtoFotoArticulo, inMtoStockConsulta,
     inLibGridColumnChooser, inMtoModalGridGuias,
     inLibInformesGuiasCache,
     System.Diagnostics,   // TStopwatch para cronometrar carga inicial
     Vcl.ComCtrls;         // TProgressBar marquee en overlay de carga
     // System.Threading ya esta en el interface (para TList<ITask>).

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
  // El dataset puede ser TUniQuery (mantenimientos normales) o
  // TUniStoredProc (formularios de busqueda lanzados con un SP, p.ej.
  // F3 en caja -> BuscarArticulo -> PRC_BUSQUEDA_ARTICULOS). Si es
  // stored proc no hay tabla origen que mostrar: usamos el nombre del
  // SP. Antes hacia 'as TUniQuery' a secas y reventaba con EInvalidCast.
  if (DsTablaG.Dataset <> nil) then
  begin
    if DsTablaG.Dataset is TUniQuery then
      lblTablaOrigen.Caption :=
        GetTableNameFromQuery(TUniQuery(DsTablaG.Dataset).SQL.Text)
    else if DsTablaG.Dataset is TUniStoredProc then
      lblTablaOrigen.Caption := TUniStoredProc(DsTablaG.Dataset).StoredProcName
    else
      lblTablaOrigen.Caption := '';
  end;
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

    // 3. Perfiles particulares del Mto (hook para descendientes — por
    // ejemplo TfrmMtoArticulos lo usa para grabar los filtros de carga
    // de la pestanya Lista).
    RecogerPerfilesParticulares(oList, sPermisos);

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
    // Borrar guias de grid asociadas al layout
    BorrarGuiasGrid;
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

procedure TfrmMtoGen.RecogerPerfilesParticulares(var oList: TPerfilList;
                                                 const sPermisos: string);
begin
  // Por defecto el Mto no anyade nada. Los descendientes (p.ej.
  // TfrmMtoArticulos) sobreescriben este metodo para volcar entradas
  // adicionales al batch del sbGrabarGridClick.
end;

procedure TfrmMtoGen.CrearTablaPrincipal;
var
  sNameModule: string;
  swTotal, swTramo: TStopwatch;
  msCrearDM, msFConn, msReasignar: Int64;
begin
  swTotal := TStopwatch.StartNew;
  msCrearDM := 0; msFConn := 0; msReasignar := 0;
  tdmDataModule := nil;
  sNameModule := '';
  if Self.Owner <> nil then
    sNameModule :=
     (Self.Owner as TfrmMtoPrincipal).oFzaWinf.GetDataModuleName(Self.UnitName +
                                                          '.' + Self.ClassName);
  if (sNameModule <> '') then
  begin
    swTramo := TStopwatch.StartNew;
    tdmDataModule := CrearDataModule(sNameModule, Self);
    msCrearDM := swTramo.ElapsedMilliseconds;
    // Conexion propia del Mto: la creamos si todavia no existe y la
    // inyectamos en todas las queries/SPs del data module recien creado.
    // El DataModule sigue arrancando con `oConn` en su DoCreate, lo cual
    // es necesario para que el .dfm streaming no se queje; aqui hacemos
    // el switch antes de cualquier Open real.
    if FConn = nil then
    try
      swTramo := TStopwatch.StartNew;
      FConn := CrearConexionPropia;
      msFConn := swTramo.ElapsedMilliseconds;
    except
      on E: Exception do
      begin
        inliblog.Log.LogError('No se pudo crear conexion propia para ' +
          Self.Name + ': ' + E.Message + '. Se sigue usando oConn global.');
        FConn := nil;
      end;
    end;
    if Assigned(FConn) then
    begin
      swTramo := TStopwatch.StartNew;
      (tdmDataModule as TdmBase).ReasignarConexion(FConn);
      msReasignar := swTramo.ElapsedMilliseconds;
    end;
  end;
  inherited;
  inLibLog.Log.LogPerf(Self.Name + '.CrearTablaPrincipal',
    Format('CrearDM=%d ms | FConn.Connect=%d ms | ReasignarConexion=%d ms',
           [msCrearDM, msFConn, msReasignar]),
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.BloquearTabPorOcupado(Bloquear: Boolean);
var
  lblTexto: TLabel;
  bar: TProgressBar;
begin
  if Bloquear then
  begin
    Inc(FTareasEnCurso);
    if FOverlayOcupado = nil then
    begin
      FOverlayOcupado := TPanel.Create(Self);
      FOverlayOcupado.Parent := Self;
      // SetBounds + Anchors en vez de alClient: alClient compite con
      // otros controles alineados del Mto (pcPantalla, pButtonRightBar...)
      // y a veces el overlay quedaba con altura cero (no se veia nada).
      // Cubrimos manualmente todo el form y nos anclamos a los 4 bordes
      // para seguir el resize.
      FOverlayOcupado.SetBounds(0, 0, Self.ClientWidth, Self.ClientHeight);
      FOverlayOcupado.Anchors := [akLeft, akTop, akRight, akBottom];
      FOverlayOcupado.BevelOuter := bvNone;
      FOverlayOcupado.Color := $00F5E6CC;   // azul-crema claro, contrasta
      FOverlayOcupado.ParentBackground := False;
      FOverlayOcupado.Caption := '';

      // Label y barra los posicionamos con SetBounds (no alClient) para
      // que coexistan sin taparse — alClient en el label se comeria el
      // espacio de la barra.
      lblTexto := TLabel.Create(FOverlayOcupado);
      lblTexto.Parent := FOverlayOcupado;
      lblTexto.AutoSize := False;
      lblTexto.SetBounds(0,
                         (FOverlayOcupado.ClientHeight div 2) - 40,
                         FOverlayOcupado.ClientWidth,
                         30);
      lblTexto.Anchors := [akLeft, akTop, akRight];
      lblTexto.Alignment := taCenter;
      lblTexto.Layout := tlCenter;
      lblTexto.Caption := 'Cargando datos, espera por favor...';
      lblTexto.Font.Style := [fsBold];
      lblTexto.Font.Size := 11;
      lblTexto.Font.Color := clNavy;
      lblTexto.Transparent := True;

      // Barra "marquee": animacion continua sin necesitar %. La pinta
      // el message pump del main thread, asi que solo se ve cuando hay
      // pump corriendo (= camino async). Para el camino sincrono el
      // cursor global Screen.Cursor = crHourGlass cubre el feedback.
      bar := TProgressBar.Create(FOverlayOcupado);
      bar.Parent := FOverlayOcupado;
      bar.SetBounds((FOverlayOcupado.ClientWidth div 2) - 150,
                    (FOverlayOcupado.ClientHeight div 2) + 5,
                    300, 18);
      bar.Anchors := [];
      bar.Style := pbstMarquee;
      bar.MarqueeInterval := 30;
    end;
    // Asegurar que cubre el form aunque haya cambiado de tamaño desde
    // la ultima vez.
    FOverlayOcupado.SetBounds(0, 0, Self.ClientWidth, Self.ClientHeight);
    FOverlayOcupado.BringToFront;
    FOverlayOcupado.Visible := True;
    Self.Cursor := crHourGlass;
  end
  else
  begin
    if FTareasEnCurso > 0 then
      Dec(FTareasEnCurso);
    if (FTareasEnCurso = 0) and Assigned(FOverlayOcupado) then
    begin
      FOverlayOcupado.Visible := False;
      Self.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoGen.EjecutarEnBackground(AccionBG: TProc;
                                          AlTerminar: TProc<string>);
var
  LTask: ITask;
begin
  if not Assigned(AccionBG) then
    Exit;
  if FTareasActivas = nil then
    FTareasActivas := TList<ITask>.Create;
  BloquearTabPorOcupado(True);
  LTask := TTask.Run(
    procedure
    var
      LErrMsg: string;
    begin
      LErrMsg := '';
      try
        AccionBG();
      except
        on E: Exception do
        begin
          // Logueamos el error real (con tipo) y propagamos solo el
          // mensaje al callback. Si necesitaramos el tipo de excepcion
          // tendriamos que envolverlo en una clase wrapper; para el
          // piloto basta con el mensaje.
          inLibLog.Log.LogError('[EjecutarEnBackground] ' +
            E.ClassName + ': ' + E.Message);
          LErrMsg := E.Message;
          if LErrMsg = '' then
            LErrMsg := E.ClassName;
        end;
      end;
      TThread.Queue(nil,
        procedure
        begin
          try
            // Quitar esta tarea de la lista ANTES del callback (si el
            // callback lanza otra task, no queremos contar esta vez).
            // Si el form se esta destruyendo, FTareasActivas puede ser nil.
            if Assigned(FTareasActivas) then
              FTareasActivas.Remove(LTask);
            // Tambien comprobamos csDestroying: si el form se cerro
            // mientras la tarea corria, no hay UI que actualizar y los
            // componentes (FOverlayOcupado, dsTablaG...) ya estan
            // liberados.
            if not (csDestroying in ComponentState) then
            begin
              // OJO: el overlay se quita DESPUES del callback. Asi el
              // usuario no puede interactuar mientras AlTerminar
              // ejecuta trabajo pesado (p. ej. AbrirDetalles abre 11
              // queries detalle). Si lo quitamos antes, eventos del
              // form (cambio de cursor, click en pestaña, ...) se
              // disparan con queries aun cerradas -> "Cannot perform
              // operation on closed dataset".
              try
                if Assigned(AlTerminar) then
                  AlTerminar(LErrMsg);
              finally
                BloquearTabPorOcupado(False);
              end;
            end;
          except
            on E: Exception do
              inLibLog.Log.LogError(
                '[EjecutarEnBackground.AlTerminar] ' +
                E.ClassName + ': ' + E.Message);
          end;
        end);
    end);
  FTareasActivas.Add(LTask);
end;

procedure TfrmMtoGen.AbrirTablaPrincipalAsync;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  yaActiva: Boolean;
begin
  if (tdmDataModule = nil) or not (tdmDataModule is TdmBase) then
    Exit;
  dmDat := TdmBase(tdmDataModule);
  unqry := dmDat.unqryTablaG;
  if unqry = nil then
    Exit;
  // unqryTablaG puede llegar abierta por el DFM streaming (Active=True
  // en su DFM, es lo habitual para que componentes del form puedan
  // resolver el field 'CODIGO_ART_ART' en CrearTablaPrincipal). En ese
  // caso saltamos su Open pero seguimos para abrir AbrirDetalles, que
  // es donde realmente esta el grueso de la carga.
  yaActiva := unqry.Active;
  // Soltamos el grid del DataSource solo si vamos a (re)abrir. Si la
  // query ya esta activa con datos, mantener el grid vinculado evita
  // un parpadeo "<No hay datos a mostrar>" innecesario.
  if (not yaActiva) and Assigned(dsTablaG) then
    dsTablaG.DataSet := nil;
  sw := TStopwatch.StartNew;
  EjecutarEnBackground(
    procedure
    begin
      // Solo la lista principal en thread. Es rapido (~8 ms en
      // vi_articulos). Probamos a meter AbrirDetalles aqui tambien
      // pero los cxDBLookupComboBox (cbbFamilia y cia) se cuelgan al
      // recibir notificacion de Active=True desde un thread aparte —
      // DevExpress NO es thread-safe ni siquiera con TDataSource.Enabled
      // = False.
      if not unqry.Active then
        unqry.Open;
    end,
    procedure(ErrMsg: string)
    begin
      // El form puede haberse cerrado mientras carga (otro tab, btnSalir,
      // cierre de app). En csDestroying los componentes ya pueden estar
      // liberados; salir limpio sin tocar nada.
      if csDestroying in ComponentState then
        Exit;
      if ErrMsg = '' then
        inLibLog.Log.LogPerf('Carga/async', Self.Name + ' | OK',
          sw.ElapsedMilliseconds)
      else
      begin
        inLibLog.Log.LogPerf('Carga/async',
          Self.Name + ' | error=' + ErrMsg,
          sw.ElapsedMilliseconds);
        // No mostramos ShowMessage aqui — molesta si pasa al abrir
        // varios tabs en cadena. El error queda en el log.
        Exit;
      end;
      // (a) Detalles en MAIN thread con overlay aun visible. Bloquea
      // el main thread mientras corre (no podemos evitarlo: DevExpress
      // no permite operaciones de dataset en thread sin colgarse), pero
      // el usuario ve "Cargando datos..." y el overlay esta arriba;
      // otros tabs siguieron interactivos hasta que entramos aqui.
      if Assigned(dmDat) then
        try
          dmDat.AbrirDetalles;
        except
          on E: Exception do
            inLibLog.Log.LogError(
              '[AbrirDetalles] ' + Self.Name + ': ' + E.Message);
        end;
      // (b) Enriquecer query con guias de grid (LEFT JOIN runtime)
      AplicarGuiasGrid(unqry);
      // (c) Revincular grid solo si lo soltamos antes (yaActiva = False).
      // Si la query ya estaba activa al entrar, dsTablaG.DataSet sigue
      // apuntando al original y no tocamos.
      if (not yaActiva) and Assigned(dsTablaG) and Assigned(unqry) then
        dsTablaG.DataSet := unqry;
      // (d) Reactivar TDataSource del DM (los hayamos desactivado o no
      // en AbrirDetalles) y disparar AfterScroll del stock.
      if Assigned(dmDat) then
        try
          dmDat.ReactivarControlesTrasAbrir;
        except
          on E: Exception do
            inLibLog.Log.LogError(
              '[ReactivarControlesTrasAbrir] ' + Self.Name + ': ' + E.Message);
        end;
    end);
end;

procedure TfrmMtoGen.AbrirTablaPrincipalSincrono;
var
  dmDat: TdmBase;
  unqry: TUniQuery;
  sw: TStopwatch;
  CursorPrev: TCursor;
begin
  if (tdmDataModule = nil) or not (tdmDataModule is TdmBase) then
    Exit;
  dmDat := TdmBase(tdmDataModule);
  unqry := dmDat.unqryTablaG;
  if unqry = nil then
    Exit;
  // Modo sincrono: la UI esta congelada durante el Open. Forzamos cursor
  // de reloj global (Screen.Cursor) para que el usuario sepa que la app
  // esta ocupada — no muerta. Self.Cursor solo afecta cuando el raton
  // esta sobre el form; Screen.Cursor lo cambia en toda la pantalla.
  CursorPrev := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  sw := TStopwatch.StartNew;
  try
    try
      if not unqry.Active then
        unqry.Open;
      // Sin abrir los detalles, los grids master/detail se quedan en
      // blanco aunque la BBDD tenga datos (la query detalle no esta
      // Active y MasterSource solo refresca params, no la activa). La
      // version async ya lo hace en su callback; en sync hay que
      // llamarlo aqui para que ShowMto(...,'<busqueda>') muestre las
      // lineas/celdas tras Locate sobre el master.
      dmDat.AbrirDetalles;
      // Enriquecer con guias de grid (LEFT JOIN runtime)
      AplicarGuiasGrid(unqry);
      inLibLog.Log.LogPerf('Carga/sync', Self.Name + ' | OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf('Carga/sync',
          Self.Name + ' | error=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
    end;
  finally
    Screen.Cursor := CursorPrev;
  end;
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
  // ANTES de liberar nada relacionado con BBDD (data module, FConn),
  // esperar a que terminen las tareas en background. Si quedaran tareas
  // vivas accederian a TUniQuery / TUniConnection ya liberadas → AV.
  // Timeout 5s: si MySQL no responde en 5s preferimos asumir tarea muerta
  // antes que dejar la app colgada cerrando un tab.
  if Assigned(FTareasActivas) then
  begin
    try
      if FTareasActivas.Count > 0 then
        TTask.WaitForAll(FTareasActivas.ToArray, 5000);
    except
      // WaitForAll puede lanzar si alguna tarea fallo — lo ignoramos
      // porque solo queremos drenar, no propagar.
    end;
    FreeAndNil(FTareasActivas);
  end;
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
  sModoBusq: String;
  swTotal, swTramo: TStopwatch;
  msProcesarPerfiles: Int64;
begin
  swTotal := TStopwatch.StartNew;
  inherited;
  Self.HandleNeeded; //da problemas
  inliblog.Log.LogInfo('Ventana de mantenimiento: ' +
                                                     Self.Caption + ' Abierta');
  tsFichCab := nil;
  tsFichBut := nil;
  FCamposGuia := nil;
  FSqlOriginalTablaG := '';
  Self.Position  := poScreenCenter;
  // Popup de columnas: boton derecho en el grid principal
  FPopMenuColumnas := TPopupMenu.Create(Self);
  FPopMenuColumnas.OnPopup := PopMenuColumnasPopup;
  cxgrdPrincipal.PopupMenu := FPopMenuColumnas;
  swTramo := TStopwatch.StartNew;
  ProcesarPerfiles;
  msProcesarPerfiles := swTramo.ElapsedMilliseconds;
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
  inLibLog.Log.LogPerf(Self.Name + '.FormCreate',
    'ProcesarPerfiles=' + IntToStr(msProcesarPerfiles) + ' ms',
    swTotal.ElapsedMilliseconds);
end;

procedure TfrmMtoGen.BorrarGuiasGrid;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'DELETE FROM fza_informes_guias ' +
      ' WHERE INFORME_INFGUI = :INF';
    qry.ParamByName('INF').AsString := 'GRID:' + Self.Name;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
  // Invalidar cache para que la proxima apertura no use guias borradas
  if oInfGuiasCache <> nil then
    oInfGuiasCache.Invalidar;
end;

procedure TfrmMtoGen.AplicarGuiasGrid(AQuery: TUniQuery);
var
  guiaResult: TGridGuiaResult;
  i: Integer;
  col: TcxGridDBColumn;
  sField: string;
  bYaExiste: Boolean;
  j: Integer;
begin
  if AQuery = nil then
    Exit;
  guiaResult := EnriquecerQueryConGuias(Self.Name, AQuery);
  try
    if not guiaResult.Exito then
    begin
      FreeAndNil(guiaResult.CamposNuevos);
      Exit;
    end;
    if guiaResult.CamposNuevos.Count = 0 then
    begin
      FreeAndNil(guiaResult.CamposNuevos);
      Exit;
    end;
    FSqlOriginalTablaG := guiaResult.SqlOriginal;
    // Reabrir query con SQL enriquecido
    try
      AQuery.Open;
    except
      on E: Exception do
      begin
        inLibLog.Log.LogError(
          'AplicarGuiasGrid: error al reabrir query: ' + E.Message);
        FreeAndNil(guiaResult.CamposNuevos);
        Exit;
      end;
    end;
    // Crear columnas dinamicas en el grid para los campos nuevos
    cxGrdDBTabPrin.BeginUpdate;
    try
      for i := 0 to guiaResult.CamposNuevos.Count - 1 do
      begin
        sField := guiaResult.CamposNuevos[i];
        // No duplicar si ya existe
        bYaExiste := False;
        for j := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
          if SameText(
            (cxGrdDBTabPrin.Columns[j] as TcxGridDBColumn)
              .DataBinding.FieldName, sField) then
          begin
            bYaExiste := True;
            Break;
          end;
        if bYaExiste then
          Continue;
        col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
        col.DataBinding.FieldName := sField;
        col.Caption := sField;
        // Por defecto ocultas; el perfil las mostrara si el usuario
        // las activo previamente con Alt+F12
        col.Visible := False;
      end;
    finally
      cxGrdDBTabPrin.EndUpdate;
    end;
    // Re-aplicar perfil para que las columnas de guia recuperen
    // visibilidad/ancho/caption guardados por el usuario
    if oPerfilDic <> nil then
      PonerAnchosTitulos(cxGrdDBTabPrin, Self.Name, oPerfilDic);
    // Guardar lista de campos guia para limpieza
    FreeAndNil(FCamposGuia);
    FCamposGuia := TStringList.Create;
    FCamposGuia.Assign(guiaResult.CamposNuevos);
  finally
    FreeAndNil(guiaResult.CamposNuevos);
  end;
end;

// ============================================================================
// Popup de selector de columnas (boton derecho en grid)
// ============================================================================

procedure TfrmMtoGen.PopMenuColumnasPopup(Sender: TObject);
var
  i: Integer;
  col: TcxGridDBColumn;
  mi, miSep, miGuia: TMenuItem;
  sCaption: string;
begin
  FPopMenuColumnas.Items.Clear;
  // Items por cada columna del grid principal
  for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
  begin
    col := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
    if col.DataBinding.FieldName = '' then
      Continue;
    mi := TMenuItem.Create(FPopMenuColumnas);
    sCaption := col.Caption;
    if sCaption = '' then
      sCaption := col.DataBinding.FieldName;
    mi.Caption := sCaption;
    mi.Checked := col.Visible;
    mi.AutoCheck := False;
    mi.Tag := i;
    mi.OnClick := PopMenuColumnaClick;
    FPopMenuColumnas.Items.Add(mi);
  end;
  // Separador + "Nueva guia..."
  miSep := TMenuItem.Create(FPopMenuColumnas);
  miSep.Caption := '-';
  FPopMenuColumnas.Items.Add(miSep);
  miGuia := TMenuItem.Create(FPopMenuColumnas);
  miGuia.Caption := 'Nueva guía...';
  miGuia.OnClick := PopMenuNuevaGuiaClick;
  FPopMenuColumnas.Items.Add(miGuia);
end;

procedure TfrmMtoGen.PopMenuColumnaClick(Sender: TObject);
var
  mi: TMenuItem;
  col: TcxGridDBColumn;
begin
  mi := TMenuItem(Sender);
  if (mi.Tag >= 0) and (mi.Tag < cxGrdDBTabPrin.ColumnCount) then
  begin
    col := cxGrdDBTabPrin.Columns[mi.Tag] as TcxGridDBColumn;
    col.Visible := not col.Visible;
  end;
end;

procedure TfrmMtoGen.PopMenuNuevaGuiaClick(Sender: TObject);
var
  frm: TfrmModalGridGuias;
  oDS: TDataSet;
  guiaResult: TGridGuiaResult;
  camposElegidos: TStringList;
  i: Integer;
  col: TcxGridDBColumn;
begin
  // Abrir mantenimiento de guias del grid
  frm := TfrmModalGridGuias.Create(Application);
  try
    frm.sFormulario := Self.Name;
    oDS := nil;
    if Assigned(dsTablaG) and Assigned(dsTablaG.DataSet) then
      oDS := dsTablaG.DataSet;
    frm.FDataSet := oDS;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
  // Recargar cache de guias
  if oInfGuiasCache <> nil then
  begin
    oInfGuiasCache.Invalidar;
    oInfGuiasCache.Precargar;
  end;
  // Enriquecer query si hay guias nuevas
  if (tdmDataModule <> nil) and (tdmDataModule is TdmBase) then
  begin
    var unqry := TdmBase(tdmDataModule).unqryTablaG;
    if (unqry <> nil) and (unqry.Active) then
    begin
      // Restaurar SQL original si ya estaba enriquecido
      if FSqlOriginalTablaG <> '' then
      begin
        unqry.Close;
        unqry.SQL.Text := FSqlOriginalTablaG;
      end;
      guiaResult := EnriquecerQueryConGuias(Self.Name, unqry);
      try
        if guiaResult.Exito and (guiaResult.CamposNuevos.Count > 0) then
        begin
          FSqlOriginalTablaG := guiaResult.SqlOriginal;
          // Dejar elegir columnas al usuario
          camposElegidos := ElegirColumnasNuevas(Self,
                                                 guiaResult.CamposNuevos);
          try
            // Reabrir query con SQL enriquecido
            unqry.Open;
            // Crear columnas dinamicas en el grid
            cxGrdDBTabPrin.BeginUpdate;
            try
              for i := 0 to guiaResult.CamposNuevos.Count - 1 do
              begin
                col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
                col.DataBinding.FieldName :=
                  guiaResult.CamposNuevos[i];
                col.Caption := guiaResult.CamposNuevos[i];
                col.Visible :=
                  camposElegidos.IndexOf(guiaResult.CamposNuevos[i]) >= 0;
              end;
            finally
              cxGrdDBTabPrin.EndUpdate;
            end;
            // Guardar nombres de campos guia para limpieza
            FreeAndNil(FCamposGuia);
            FCamposGuia := TStringList.Create;
            FCamposGuia.Assign(guiaResult.CamposNuevos);
          finally
            FreeAndNil(camposElegidos);
          end;
        end
        else
        begin
          // No hay guias o fallo: reabrir con SQL original si lo cerramos
          if not unqry.Active then
            unqry.Open;
        end;
      finally
        FreeAndNil(guiaResult.CamposNuevos);
      end;
    end;
  end;
end;

procedure TfrmMtoGen.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  // ESC -> cancelar grids en edicion
  if (Key = VK_ESCAPE) then
  begin
    CancelarGrids(Owner);
    Key := 0;
  end;
  // RETURN sin control activo -> simular Tab
  if ((Key = VK_RETURN) and (ActiveControl = nil)) then
  begin
    Key := 0;
    SimulateTabKey;
    Exit;
  end;
  // Alt+F12 -> Guardar layout (equivalente al botón sbGrabarGrid)
  if (Key = VK_F12) and (ssAlt in Shift) and not (ssCtrl in Shift) then
  begin
    sbGrabarGridClick(nil);
    Key := 0;
    Exit;
  end;
  // Ctrl+F12 -> Resetear layout (equivalente al botón sbResetGrid)
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    sbResetGridClick(nil);
    Key := 0;
  end;
end;

// ---------------------------------------------------------------------------
// Acciones del TActionList base (alMtoGen)
// Sustituyen al antiguo FormKeyDown para que inMtoPrincipal.IsShortCut
// enrute siempre al formulario activo en la pestaña correcta.
// ---------------------------------------------------------------------------

function TfrmMtoGen.PermitirNavegacionTeclas: Boolean;
begin
  Result := True;
end;

procedure TfrmMtoGen.actNavBrowseUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse) and
    PermitirNavegacionTeclas;
end;

procedure TfrmMtoGen.actEliminarRegistroUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    not dsTablaG.DataSet.IsEmpty and
    (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoGen.actEliminarRegistroExecute(Sender: TObject);
begin
  if Application.MessageBox(
    '¿Estás seguro de que deseas eliminar este registro?',
    'Confirmar eliminación',
    MB_YESNO + MB_ICONWARNING) = ID_YES then
    dsTablaG.DataSet.Delete;
end;

procedure TfrmMtoGen.actRegistroAnteriorExecute(Sender: TObject);
begin
  nvNavegador.Buttons.Prior.Click;
end;

procedure TfrmMtoGen.actRegistroSiguienteExecute(Sender: TObject);
begin
  nvNavegador.Buttons.Next.Click;
end;

procedure TfrmMtoGen.actInsertarRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.Insert;
end;

procedure TfrmMtoGen.actPrimerRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.First;
end;

procedure TfrmMtoGen.actUltimoRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.Last;
end;

procedure TfrmMtoGen.actEditarRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.Edit;
end;

procedure TfrmMtoGen.actGrabarRegistroUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    ((dsTablaG.State = dsEdit) or (dsTablaG.State = dsInsert));
end;

procedure TfrmMtoGen.actGrabarRegistroExecute(Sender: TObject);
begin
  dsTablaG.DataSet.Post;
end;

procedure TfrmMtoGen.actFotoArticuloExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  sArt := '';
  sSku := '';
  ResolverArtSkuActivo(sArt, sSku);
  if sArt <> '' then
  begin
    MostrarFotoFlotante(Self, sArt, sSku);
    if Assigned(frmFotoArticulo) then
      frmFotoArticulo.VincularDataSources(DataSourcesParaFoto,
                                          ResolverArtSkuActivo);
  end;
end;

procedure TfrmMtoGen.actConsultaStockExecute(Sender: TObject);
var
  sArt: string;
  sSku: string;
begin
  sArt := '';
  sSku := '';
  ResolverArtSkuActivo(sArt, sSku);
  inMtoStockConsulta.MostrarStockConsulta(Self, sArt, sSku);
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
