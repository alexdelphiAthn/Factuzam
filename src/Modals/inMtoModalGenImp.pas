{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenImp                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal generico de impresion basado en FastReport.                         }
{    Base reutilizable para los modales de impresion especificos.              }
{******************************************************************************}
unit inMtoModalGenImp;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoFrmBase, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  dxSkinsCore, dxSkinBlue, frxClass, frxDBSet, StdCtrls, cxButtons, DB,
  DBClient, cxControls, cxContainer, cxEdit, cxTextEdit, cxLabel, frxExportPDF,
  ExtCtrls, ComCtrls, dxCore, cxDateUtils, cxMaskEdit, cxDropDownEdit,
  cxCalendar, frxDesgn, cxGroupBox, cxRadioGroup, frxExportBaseDialog,
  frxExportXLSX, MemDS, DBAccess, Uni, UniDataConn,
  inLibGlobalVar, inMtoPrincipal, inMtoModalGenImpEle, cxStyles, dxSkinsForm,
  cxClasses, cxLocalization, Vcl.Menus, System.UITypes, JvComponentBase,
  JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinsDefaultPainters, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue, System.Actions, Vcl.ActnList,
  frxExportBaseImageSettingsDialog, frCoreClasses,
  frLocalization, frxBarcode,
  frLanguageSpanish, frxSmartMemo;
type
  TfrmPrint = class(TfrmBase)
    pnl1: TPanel;
    btnPDF: TcxButton;
    btnImprimir: TcxButton;
    btnVistaPreliminar: TcxButton;
    btnSalir: TcxButton;
    frxrprt1: TfrxReport;
    frxpdfxprtPedWeb: TfrxPDFExport;
    btnEditar: TcxButton;
    frxlsxprtExcel: TfrxXLSXExport;
    btnExcel: TcxButton;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    frxdsgnr1: TfrxDesigner;
    frxReportOrigen: TfrxReport;
    ActionList1: TActionList;
    actSalir: TAction;
    frLocalizationController1: TfrLocalizationController;
    unqryInformesGuias: TUniQuery;
    procedure btnImprimirClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure btnVistaPreliminarClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    function frxdsgnr1SaveReport(Report: TfrxReport; SaveAs: Boolean): Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actSalirExecute(Sender: TObject);
  private
    sElegido:String;
    // Cuando el usuario entra por Editar, fijamos el nombre del formato
    // al inicio del flujo (en btnEditarClick) en sElegido. Esta flag
    // indica al frxdsgnr1SaveReport que NO debe presentar el modal de
    // guardado: el nombre del formato ya esta decidido y el guardar va
    // directo a fza_usuarios_perfiles con sElegido y FScopePerfilFijado.
    FFormatoFijado: Boolean;
    FScopePerfilFijado: string;
    // Componentes creados dinamicamente al abrir guias runtime. Se
    // liberan en CerrarGuiasRuntime / FormClose.
    FGuiasRuntime: TList;
  public
    procedure CargarFormatos(form:TfrmMtoModalGenImpEle);
    procedure DeleteForm(sElegido:String;form:TfrmMtoModalGenImpEle);
    procedure preparar_consulta; virtual; abstract;
    procedure AfterReportLoaded; virtual;
    procedure Consultar_Formularios(bForzarSeleccion: Boolean = False);
    // Crea en runtime un dataset auxiliar por cada guia configurada en
    // fza_informes_guias para Self.Name, enlazandolo MasterSource-style
    // al frxDBDataset master y exponiendolo al frxrprt1.
    //   aSoloUsadasEnReport = True : solo se abren las guias cuyo
    //                                CODIGO_INFGUI aparece referenciado
    //                                en el .frx (modo impresion).
    //   aSoloUsadasEnReport = False: se abren todas las guias activas
    //                                (modo edicion del diseñador).
    procedure AbrirGuiasRuntime(aSoloUsadasEnReport: Boolean);
    procedure CerrarGuiasRuntime;
    // Lanza el modal de mantenimiento de guias para Self.Name y un
    // formato concreto (vacio o 'Predeterminado' = global). Si se pasa
    // un report el modal muestra ademas la lista de datasets (cabecera y
    // detalle) con sus campos como ayuda visual al rellenar las guias.
    procedure EditarGuiasParaFormato(const aFormato: string;
                                     aReport: TfrxReport = nil);
    // Al guardar un formato personalizado del .frx, clona en
    // fza_informes_guias las guias globales referenciadas en el report
    // para que queden tambien atadas a ese formato. Idempotente.
    procedure ConsolidarGuiasParaFormato(const aFormato: string);
  end;

procedure RebindReportDataSetsByDataModule(Report: TfrxReport;
                                           DM: TDataModule);

implementation

uses
  inMtoModalGenImpSave, inLibUser, inLibPathTokens, inLibAppParam,
  System.Generics.Collections, System.Rtti, inLibFotos,
  inMtoModalInformesGuias, inMtoModalWizardEditar, inLibLog;

{$R *.dfm}

procedure RebindReportDataSetsByDataModule(Report: TfrxReport;
                                           DM: TDataModule);
var
  Map: TDictionary<string, TfrxDBDataset>;
  i: Integer;
  comp: TComponent;
  ds: TfrxDBDataset;
  obj: TfrxComponent;
  ctx: TRttiContext;
  rType: TRttiType;
  prop: TRttiProperty;
  curVal: TValue;
  curObj: TObject;
  newDs: TfrxDBDataset;
begin
  if (Report = nil) or (DM = nil) then Exit;
  Map := TDictionary<string, TfrxDBDataset>.Create;
  ctx := TRttiContext.Create;
  try
    for i := 0 to DM.ComponentCount - 1 do
    begin
      comp := DM.Components[i];
      if (comp is TfrxDBDataset) and
         (TfrxDBDataset(comp).UserName <> '') then
        Map.AddOrSetValue(TfrxDBDataset(comp).UserName,
                          TfrxDBDataset(comp));
    end;
    if Map.Count = 0 then Exit;
    Report.DataSets.Clear;
    for ds in Map.Values do
      Report.DataSets.Add(ds);
    for i := 0 to Report.AllObjects.Count - 1 do
    begin
      obj := TfrxComponent(Report.AllObjects[i]);
      rType := ctx.GetType(obj.ClassType);
      prop := rType.GetProperty('DataSet');
      if (prop = nil) or (not prop.IsReadable) or
         (not prop.IsWritable) then Continue;
      curVal := prop.GetValue(obj);
      if curVal.IsEmpty then Continue;
      curObj := curVal.AsObject;
      if (curObj is TfrxDBDataset) and
         Map.TryGetValue(TfrxDBDataset(curObj).UserName, newDs) and
         (newDs <> curObj) then
        prop.SetValue(obj, newDs);
    end;
  finally
    ctx.Free;
    FreeAndNil(Map);
  end;
end;

procedure TfrmPrint.AfterReportLoaded;
begin
  // Hook para descendientes: re-enlazar DataSets del informe.
  // Aqui ademas sustituimos los TfrxPictureView llamados foto300 /
  // foto600 / fotoReal por la foto resuelta del par (articulo, sku) que
  // vive en la banda padre del componente.
  SustituirFotosEnReport(frxrprt1);
end;

procedure TfrmPrint.AbrirGuiasRuntime(aSoloUsadasEnReport: Boolean);
var
  sCodigo, sDatasetMaster, sTipo, sTabla, sSql, sMaster, sDetail: string;
  oDsMaster: TfrxDBDataset;
  oUni: TUniQuery;
  oDs:  TDataSource;
  oFrx: TfrxDBDataset;
  i: Integer;
  bUsada: Boolean;
  memReport: TMemoryStream;
  oStrReport: TStringList;
  sReport: string;
begin
  // Garantiza la lista; tambien permite llamar a CerrarGuiasRuntime sin
  // estado previo.
  if FGuiasRuntime = nil then
    FGuiasRuntime := TList.Create
  else
    CerrarGuiasRuntime;

  unqryInformesGuias.Close;
  unqryInformesGuias.ParamByName('INF').AsString := Self.Name;
  // sElegido lleva el VALUE_USUPER del formato cargado en
  // Consultar_Formularios. Si vale '' o 'Predeterminado' el usuario
  // esta sobre el .frx base del informe, asi que pedimos solo las
  // guias globales (FORMATO_INFGUI = ''). Para cualquier otro valor
  // la condicion del SQL admite tambien las guias atadas a ese formato.
  if (sElegido = '') or SameText(sElegido, 'Predeterminado') then
    unqryInformesGuias.ParamByName('FMT').AsString := ''
  else
    unqryInformesGuias.ParamByName('FMT').AsString := sElegido;
  unqryInformesGuias.Open;
  if unqryInformesGuias.IsEmpty then
  begin
    unqryInformesGuias.Close;
    Exit;
  end;

  // En modo "solo usadas" serializamos el report a texto y buscamos las
  // referencias por nombre de dataset. FastReport las escribe en forma
  // de Dataset="<UserName>" para los componentes vinculados y como
  // <UserName."Campo"> en los memos. Con un Pos sobre la cadena
  // serializada cubrimos ambos casos.
  sReport := '';
  if aSoloUsadasEnReport then
  begin
    memReport := TMemoryStream.Create;
    oStrReport := TStringList.Create;
    try
      frxrprt1.SaveToStream(memReport);
      memReport.Position := 0;
      oStrReport.LoadFromStream(memReport);
      sReport := oStrReport.Text;
    finally
      FreeAndNil(oStrReport);
      FreeAndNil(memReport);
    end;
  end;

  unqryInformesGuias.First;
  while not unqryInformesGuias.Eof do
  begin
    sCodigo        := unqryInformesGuias.FieldByName('CODIGO_INFGUI').AsString;
    sDatasetMaster := unqryInformesGuias.FieldByName(
                                      'DATASET_MASTER_INFGUI').AsString;
    sTipo          := UpperCase(unqryInformesGuias.FieldByName(
                                                 'TIPO_INFGUI').AsString);
    sTabla         := unqryInformesGuias.FieldByName('TABLA_INFGUI').AsString;
    sSql           := unqryInformesGuias.FieldByName('SQL_INFGUI').AsString;
    sMaster        := unqryInformesGuias.FieldByName(
                                      'MASTER_FIELDS_INFGUI').AsString;
    sDetail        := unqryInformesGuias.FieldByName(
                                      'DETAIL_FIELDS_INFGUI').AsString;
    try
      bUsada := True;
      if aSoloUsadasEnReport then
        bUsada := (Pos('"' + sCodigo + '"',   sReport) > 0) or
                  (Pos('<' + sCodigo + '."',  sReport) > 0) or
                  (Pos('[' + sCodigo + '."',  sReport) > 0);

      if bUsada then
      begin
        // 1) Localizar el frxDBDataset master por UserName.
        //    frxrprt1.Datasets[i].DataSet es TfrxDataSet (la base);
        //    nosotros necesitamos el TfrxDBDataset (envuelve un
        //    TDataSet de Delphi y expone .DataSet).
        oDsMaster := nil;
        for i := 0 to frxrprt1.Datasets.Count - 1 do
          if (frxrprt1.Datasets[i].DataSet is TfrxDBDataset) and
             SameText(frxrprt1.Datasets[i].DataSet.UserName,
                      sDatasetMaster) then
          begin
            oDsMaster := TfrxDBDataset(frxrprt1.Datasets[i].DataSet);
            Break;
          end;
        if (oDsMaster = nil) or (oDsMaster.DataSet = nil) then
        begin
          inLibLog.Log.LogWarning(Format(
            'Guia %s ignorada: dataset master "%s" no encontrado en %s',
            [sCodigo, sDatasetMaster, Self.Name]));
          unqryInformesGuias.Next;
          Continue;
        end;

        // 2) Crear los tres componentes encadenados.
        oUni := TUniQuery.Create(Self);
        oUni.Connection := oConn;
        oDs := TDataSource.Create(Self);
        oDs.DataSet := oDsMaster.DataSet;
        oFrx := TfrxDBDataset.Create(Self);
        oFrx.UserName := sCodigo;
        oFrx.DataSet  := oUni;

        // 3) Configurar SQL + master/detail.
        if sTipo = 'SQL' then
        begin
          oUni.SQL.Text := sSql;
          // Para SQL libre, los DETAIL_FIELDS llevan el nombre de los
          // parametros que el master rellena en cada cursor.
          oUni.MasterSource := oDs;
          oUni.MasterFields := sMaster;
          oUni.DetailFields := sDetail;
        end
        else
        begin
          oUni.SQL.Text := 'select * from ' + sTabla;
          oUni.MasterSource := oDs;
          oUni.MasterFields := sMaster;
          oUni.DetailFields := sDetail;
        end;

        oUni.Open;

        // 4) Registrar en el report y en la lista interna.
        frxrprt1.Datasets.Add(oFrx);
        FGuiasRuntime.Add(oFrx);
        FGuiasRuntime.Add(oDs);
        FGuiasRuntime.Add(oUni);
      end;
    except
      on E: Exception do
        inLibLog.Log.LogError(
          Format('Guia %s fallo al abrir en %s: %s',
                 [sCodigo, Self.Name, E.Message]));
    end;
    unqryInformesGuias.Next;
  end;
  unqryInformesGuias.Close;
end;

procedure TfrmPrint.CerrarGuiasRuntime;
var
  i, j: Integer;
  obj: TObject;
begin
  if FGuiasRuntime = nil then Exit;
  for i := FGuiasRuntime.Count - 1 downto 0 do
  begin
    obj := TObject(FGuiasRuntime[i]);
    if obj is TfrxDBDataset then
    begin
      // Quitar del report el item que apunta a este TfrxDBDataset.
      // Comparamos como TfrxDataSet (clase base) para que el
      // compilador no requiera un cast contravariante.
      for j := frxrprt1.Datasets.Count - 1 downto 0 do
        if frxrprt1.Datasets[j].DataSet = TfrxDataSet(obj) then
        begin
          frxrprt1.Datasets.Delete(j);
          Break;
        end;
    end;
    obj.Free;
  end;
  FGuiasRuntime.Clear;
end;

procedure TfrmPrint.ConsolidarGuiasParaFormato(const aFormato: string);
var
  qrySrc, qryChk, qryIns: TUniQuery;
  mem: TMemoryStream;
  stl: TStringList;
  sReport, sCodigo: string;
begin
  // Para 'Predeterminado' o vacio no hay nada que atar: las guias se
  // quedan en su nivel global y los proximos Editar siguen viendolas.
  if (aFormato = '') or SameText(aFormato, 'Predeterminado') then Exit;

  // Serializa el .frx que acabamos de guardar para detectar referencias.
  mem := TMemoryStream.Create;
  stl := TStringList.Create;
  try
    frxrprt1.SaveToStream(mem);
    mem.Position := 0;
    stl.LoadFromStream(mem);
    sReport := stl.Text;
  finally
    FreeAndNil(stl);
    FreeAndNil(mem);
  end;

  qrySrc := TUniQuery.Create(nil);
  qryChk := TUniQuery.Create(nil);
  qryIns := TUniQuery.Create(nil);
  try
    qrySrc.Connection := oConn;
    qrySrc.SQL.Text :=
      'select CODIGO_INFGUI from fza_informes_guias ' +
      ' where INFORME_INFGUI = :INF and FORMATO_INFGUI = ''''';
    qrySrc.ParamByName('INF').AsString := Self.Name;
    qrySrc.Open;

    qryChk.Connection := oConn;
    qryChk.SQL.Text :=
      'select 1 from fza_informes_guias ' +
      ' where INFORME_INFGUI = :INF ' +
      '   and FORMATO_INFGUI = :FMT ' +
      '   and CODIGO_INFGUI = :COD';

    qryIns.Connection := oConn;
    qryIns.SQL.Text :=
      'insert into fza_informes_guias (' +
      '  CODIGO_INFGUI, INFORME_INFGUI, FORMATO_INFGUI, ' +
      '  DATASET_MASTER_INFGUI, TIPO_INFGUI, TABLA_INFGUI, ' +
      '  SQL_INFGUI, MASTER_FIELDS_INFGUI, DETAIL_FIELDS_INFGUI, ' +
      '  ORDEN_INFGUI, ESACTIVO_INFGUI, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA' +
      ') select ' +
      '  CODIGO_INFGUI, INFORME_INFGUI, :FMT, ' +
      '  DATASET_MASTER_INFGUI, TIPO_INFGUI, TABLA_INFGUI, ' +
      '  SQL_INFGUI, MASTER_FIELDS_INFGUI, DETAIL_FIELDS_INFGUI, ' +
      '  ORDEN_INFGUI, ESACTIVO_INFGUI, ' +
      '  now(), :USU ' +
      ' from fza_informes_guias ' +
      ' where INFORME_INFGUI = :INF ' +
      '   and FORMATO_INFGUI = '''' ' +
      '   and CODIGO_INFGUI = :COD';

    while not qrySrc.Eof do
    begin
      sCodigo := qrySrc.FieldByName('CODIGO_INFGUI').AsString;
      if (Pos('"' + sCodigo + '"',   sReport) > 0) or
         (Pos('<' + sCodigo + '."',  sReport) > 0) or
         (Pos('[' + sCodigo + '."',  sReport) > 0) then
      begin
        qryChk.Close;
        qryChk.ParamByName('INF').AsString := Self.Name;
        qryChk.ParamByName('FMT').AsString := aFormato;
        qryChk.ParamByName('COD').AsString := sCodigo;
        qryChk.Open;
        if qryChk.IsEmpty then
        begin
          qryIns.ParamByName('FMT').AsString := aFormato;
          qryIns.ParamByName('USU').AsString := oUser;
          qryIns.ParamByName('INF').AsString := Self.Name;
          qryIns.ParamByName('COD').AsString := sCodigo;
          qryIns.Execute;
        end;
        qryChk.Close;
      end;
      qrySrc.Next;
    end;
  finally
    FreeAndNil(qryIns);
    FreeAndNil(qryChk);
    FreeAndNil(qrySrc);
  end;
end;

procedure TfrmPrint.EditarGuiasParaFormato(const aFormato: string;
                                            aReport: TfrxReport = nil);
var
  oForm: TfrmModalInformesGuias;
begin
  oForm := TfrmModalInformesGuias.Create(Self);
  try
    oForm.sInforme := Self.Name;
    // Si el formato es 'Predeterminado' tratamos al usuario como si
    // estuviera trabajando sobre el .frx base: las guias nuevas son
    // globales por defecto. Para cualquier otro formato se atan a el.
    if SameText(aFormato, 'Predeterminado') then
      oForm.sFormatoSugerido := ''
    else
      oForm.sFormatoSugerido := aFormato;
    oForm.FReport := aReport;
    oForm.ShowModal;
  finally
    FreeAndNil(oForm);
  end;
end;

procedure TfrmPrint.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnSalirClick(Sender);
end;

procedure TfrmPrint.btnEditarClick(Sender: TObject);
var
  oWiz: TfrmModalWizardEditar;
  memStream: TMemoryStream;
  bAceptado: Boolean;
begin
  inherited;
  Self.Hide;

  // NO llamamos Preparar_consulta aqui — el convenio del proyecto es
  // dejar siempre una consulta valida en el SQL.Text del TUniQuery
  // del data module (consulta de diseño). Si invocaramos
  // Preparar_consulta antes del wizard, el SQL.Text quedaria
  // sobrescrito con la version runtime que necesita parametros
  // (serie/nro/fechas) que el usuario quiza no ha rellenado al
  // entrar a Editar, y el wizard no podria enumerar campos. La
  // llamada a Preparar_consulta se hace despues, antes de abrir
  // el diseñador, envuelta en try/except por la misma razon.

  // AfterReportLoaded re-enlaza los datasets del informe via
  // RebindReportDataSetsByDataModule. Lo hacemos antes de abrir el
  // wizard para que el paso 2 del wizard pueda enumerar los
  // TfrxDBDataset reales (cabecera + detalle) con sus campos.
  AfterReportLoaded;

  // Wizard de 2 pasos: 1) elegir/crear formato + permiso, 2) ver
  // datasets del informe y configurar guias. Al finalizar, sFormato y
  // sScope quedan fijados, asi el guardado posterior del .frx desde el
  // diseñador no tiene que volver a preguntar.
  bAceptado := False;
  oWiz := TfrmModalWizardEditar.Create(Self);
  try
    oWiz.sInforme := Self.Name;
    oWiz.FReport  := frxrprt1;
    oWiz.ShowModal;
    if oWiz.sFicha = 'S' then
    begin
      sElegido           := oWiz.sFormato;
      FScopePerfilFijado := oWiz.sScope;
      FFormatoFijado     := True;
      bAceptado          := True;

      // Cargar el .frx que corresponda al formato elegido. Si existe en
      // fza_usuarios_perfiles cargamos el BLOB; si es nuevo partimos
      // del .frx base (frxReportOrigen).
      if oWiz.bExiste then
      begin
        unqryPerfiles.Close;
        unqryPerfiles.Open;
        memStream := TMemoryStream.Create;
        try
          if unqryPerfiles.Locate('VALUE_USUPER', sElegido, []) then
          begin
            TBlobField(unqryPerfiles.FieldByName(
                                'VALUE_BLOB_USUPER')).SaveToStream(memStream);
            memStream.Position := 0;
            frxrprt1.LoadFromStream(memStream);
          end
          else
            frxrprt1.AssignAll(frxReportOrigen);
        finally
          FreeAndNil(memStream);
        end;
      end
      else
        frxrprt1.AssignAll(frxReportOrigen);

      // Re-enlazar datasets despues de cargar/asignar el report (el
      // LoadFromStream resetea Datasets de la version guardada).
      AfterReportLoaded;
    end;
  finally
    FreeAndNil(oWiz);
  end;

  if bAceptado then
  begin
    // En edicion abrimos TODAS las guias activas del informe / formato
    // (no solo las referenciadas) para que aparezcan en el arbol de
    // datasets del diseñador y el usuario pueda arrastrarlas al .frx.
    AbrirGuiasRuntime(False);
    try
      frxrprt1.PrepareReport(True);
      frxrprt1.DesignReport();
    finally
      CerrarGuiasRuntime;
      FFormatoFijado := False;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.btnExcelClick(Sender: TObject);
begin
  inherited;
  Preparar_consulta;
  Self.Hide;
  Consultar_Formularios;
  if (sElegido <> '') then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    try
      frxrprt1.PrepareReport(True);
      frxlsxprtExcel.DefaultPath := oAppParams.GetPath('appDirExcel');
      frxrprt1.Export(frxlsxprtExcel);
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.btnImprimirClick(Sender: TObject);
begin
  Preparar_consulta;
  Self.Hide;
  Consultar_Formularios;
    if (sElegido <> '') then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    try
      frxrprt1.PrepareReport(True);
      frxrprt1.Print;
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.btnSalirClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPrint.btnPDFClick(Sender: TObject);
begin
  Preparar_consulta;
  Self.Hide;
  Consultar_Formularios;
    if (sElegido <> '') then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    try
      frxrprt1.PrepareReport(True);
      frxpdfxprtPedWeb.DefaultPath := oAppParams.GetPath('appDirPDF');
      frxrprt1.Export(frxpdfxprtPedWeb);
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.btnVistaPreliminarClick(Sender: TObject);
begin
  Preparar_consulta;
  Self.Hide;
  Consultar_Formularios;
  if (sElegido <> '') then
  begin
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    try
      frxrprt1.ShowReport;
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.CargarFormatos(form:TfrmMtoModalGenImpEle);
begin
   with unqryPerfiles do
  begin
    Refresh;
    if (unqryPerfiles.RecordCount > 0) then
    begin
      First;
      Form.lstFormatos.Clear;
      while not Eof do
      begin
        form.lstFormatos.AddItem(FieldByName('VALUE_USUPER').AsString, nil);
        Next;
      end;
      form.lstFormatos.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmPrint.Consultar_Formularios(bForzarSeleccion: Boolean = False);
var
  form: TfrmMtoModalGenImpEle;
  formularioSave: TfrmModalGenImpSave;
  sDescripcion, sPermisos: string;
  memStream: TMemoryStream;
  sFichaAccion: string;
  sDefaultSubKey: string;
  i: Integer;
begin
  with unqryPerfiles do
  begin
    sElegido := '';
    sFichaAccion := '';
    unqryPerfiles.Close;
    unqryPerfiles.Open;
    sDefaultSubKey := odmPerfiles.GetProfileSubKey(Self.Name + '_default', '');
    if (not bForzarSeleccion) and (sDefaultSubKey <> '') then
    begin
      sElegido := sDefaultSubKey;
      if sElegido = 'Predeterminado' then
        sFichaAccion := 'O'
      else
        sFichaAccion := 'S';
    end
    else
    begin
      form := TfrmMtoModalGenImpEle.Create(Self);
      try
        CargarFormatos(form);
        if sDefaultSubKey <> '' then
        begin
          form.chkPredeterminado.Checked := True; // Marcamos el check
          if sDefaultSubKey <> 'Predeterminado' then
          begin
            for i := 0 to form.lstFormatos.Count - 1 do
            begin
              if form.lstFormatos.Items[i] = sDefaultSubKey then
              begin
                form.lstFormatos.ItemIndex := i;
                Break;
              end;
            end;
          end;
        end;
        if (RecordCount > 0) then
          form.ShowModal
        else
          form.sFicha := 'O';
        sElegido := form.sElegido;
        sFichaAccion := form.sFicha;
        if (sFichaAccion = 'S') or (sFichaAccion = 'O') then
        begin
          if form.bPredeterminado then
          begin
            if sElegido <> sDefaultSubKey then
            begin
              formularioSave := TfrmModalGenImpSave.Create(Self);
              try
                formularioSave.edtNombreOrigen.Text := Self.Name;
                formularioSave.edtDescripcion.Text := 'Predet: ' + sElegido;
                formularioSave.edtDescripcion.Enabled := False;
                formularioSave.ShowModal;
                if formularioSave.sFicha = 'S' then
                begin
                  sPermisos := formularioSave.cbbPermisos.Text;
                  // Borramos cualquier regla anterior para evitar duplicados
                  odmPerfiles.DeleteProfile(oUser, Self.Name + '_default');
                  odmPerfiles.DeleteProfile(oGroup, Self.Name + '_default');
                  odmPerfiles.DeleteProfile(oAll, Self.Name + '_default');
                  odmPerfiles.GrabarPerfil(sPermisos,
                                           Self.Name + '_default',
                                           sElegido,
                                           sElegido);
                end;
              finally
                FreeAndNil(formularioSave);
              end;
            end;
          end
          else
          begin
            if sDefaultSubKey <> '' then
            begin
              odmPerfiles.DeleteProfile(oUser, Self.Name + '_default');
              odmPerfiles.DeleteProfile(oGroup, Self.Name + '_default');
              odmPerfiles.DeleteProfile(oAll, Self.Name + '_default');
            end;
          end;
        end;
      finally
        FreeAndNil(form);
      end;
    end;
    if sFichaAccion = 'S' then
    begin
      sDescripcion := sElegido;
      memStream := TMemoryStream.Create;
      try
        if unqryPerfiles.Locate('VALUE_USUPER', sDescripcion, []) then
        begin
          TBlobField(unqryPerfiles.FieldByName(
                                'VALUE_BLOB_USUPER')).SaveToStream(memStream);
          memStream.Position := 0;
          frxrprt1.LoadFromStream(memStream);
        end
        else
        begin
           frxrprt1.AssignAll(frxReportOrigen);
        end;
      finally
        FreeAndNil(memStream);
      end;
    end
    else if (sFichaAccion = 'O') then
    begin
      frxrprt1.AssignAll(frxReportOrigen);
    end;
  end;
end;

procedure TfrmPrint.DeleteForm(sElegido: String; form:TfrmMtoModalGenImpEle);
var
  unqrySol:TUniQuery;
  sUserProp:string;
  iButtonSel:Integer;
begin
  unqrySol := TUniQuery.Create(nil);
  try
    unqrySol.Connection := oConn;
    unqrySol.SQL.Text := 'SELECT USUARIO_GRUPO_USUPER ' +
                         '  FROM fza_usuarios_perfiles ' +
                         ' WHERE KEY_USUPER = :NombreReport ' +
                         '   AND VALUE_USUPER = :Descripcion ';
    unqrySol.ParamByName('NombreReport').AsString := Self.Name;
    unqrySol.ParamByName('Descripcion').AsString := sElegido;
    unqrySol.Open;
    sUserProp := unqrySol.FindField('USUARIO_GRUPO_USUPER').AsString;
    if not((inLibGlobalVar.orootGroup = 'S') or
        (oUser = sUserProp) or
        (oGroup = sUserProp)) then
      ShowMessageFmt('No tiene privilegios suficientes ' +
                     'para borrar el formato de %s. '+
                     'Consulte con el Administrador', [sUserProp])
    else
    begin
      iButtonSel := MessageDlg('¿Está seguro de borrar el formato?',
                               mtCustom,[mbYes,mbNo], 0);
      if (iButtonSel = mrYes) then
      begin
        unqrySol.SQL.Text := 'DELETE  ' +
                             '  FROM fza_usuarios_perfiles ' +
                             ' WHERE KEY_USUPER = :NombreReport ' +
                             '   AND VALUE_USUPER = :Descripcion ';
        unqrySol.ParamByName('NombreReport').AsString := Self.Name;
        unqrySol.ParamByName('Descripcion').AsString := sElegido;
        unqrySol.Execute;
      end;
      CargarFormatos(form);
    end;
  finally
    FreeAndNil(unqrySol);
  end;
end;

procedure TfrmPrint.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
  unqryPerfiles.Close;
  CerrarGuiasRuntime;
  FreeAndNil(FGuiasRuntime);
end;

procedure TfrmPrint.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  unqryPerfiles.ParamByName('FormName').AsString := Self.Name;
  unqryPerfiles.ParamByName('Usuario').AsString := oUser;
  unqryPerfiles.ParamByName('Grupo').AsString := oGroup;
  unqryPerfiles.ParamByName('Todos').AsString := oAll;
  unqryPerfiles.Open;
  FGuiasRuntime := TList.Create;
end;

function TfrmPrint.frxdsgnr1SaveReport(Report: TfrxReport;
  SaveAs: Boolean): Boolean;
var
  memStream:TMemoryStream;
  formulario: TfrmModalGenImpSave;
  bGuardar : Boolean;
  sDescripcion, sPermisos : string;
begin
  Result := False;
  bGuardar := False;
  if FFormatoFijado then
  begin
    // El nombre y permiso del formato ya estan decididos por el wizard
    // de btnEditarClick — no volvemos a preguntar al usuario.
    bGuardar     := True;
    sDescripcion := sElegido;
    sPermisos    := FScopePerfilFijado;
    if sPermisos = '' then sPermisos := oUser;
  end
  else
  begin
    formulario := TfrmModalGenImpSave.Create(Application);
    try
      formulario.edtNombreOrigen.Text := Self.Name;
      formulario.edtDescripcion.Text := sElegido;
      formulario.ShowModal;
      if (formulario.sFicha = 'S') then
      begin
        bGuardar := True;
        sDescripcion := formulario.edtDescripcion.Text;
        sPermisos := formulario.cbbPermisos.Text;
      end;
    finally
      FreeAndNil(formulario);
    end;
  end;
  if bGuardar then
  begin
    memStream:=TMemoryStream.Create;
    try
      frxrprt1.SaveToStream(memStream);
      memStream.Position:=0;
      if unqryPerfiles.Locate('VALUE_USUPER',sDescripcion, []) then
      begin
        if FFormatoFijado then
          // El wizard ya advirtio al usuario de que el formato existia.
          unqryPerfiles.Edit
        else if ( Application.MessageBox( 'El informe ya existe. ' +
                                    '¿Desea reemplazar el informe?',
                                    'Mensaje Advertencia',
                                    MB_YESNO ) = ID_YES ) then
          unqryPerfiles.Edit
        else
          bGuardar := False;
      end
      else
        unqryPerfiles.Insert;
      if (bGuardar) then
      begin
        unqryPerfiles.FieldByName('USUARIO_GRUPO_USUPER').AsString :=
                                                                      sPermisos;
        unqryPerfiles.FieldByName('KEY_USUPER').AsString := Self.Name;
        unqryPerfiles.FieldByName('SUBKEY_USUPER').AsString := frxrprt1.Name +
                                                             '_' + sDescripcion;
        unqryPerfiles.FieldByName('VALUE_USUPER').AsString := sDescripcion;
        unqryPerfiles.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
        unqryPerfiles.FieldByName('USUARIO_MODIF').AsString := oUser;
        unqryPerfiles.FieldByName('USUARIO_ALTA').AsString := oUser;
        TBlobField(unqryPerfiles.FieldByName('VALUE_BLOB_USUPER')).
                                                      LoadFromStream(memStream);
        //https://forums.devart.com/viewtopic.php?t=19115
        unqryPerfiles.Post;
        // Atar las guias referenciadas por este .frx al formato recien
        // guardado: clona en fza_informes_guias las que existian como
        // globales para que el formato quede autocontenido.
        try
          ConsolidarGuiasParaFormato(sDescripcion);
        except
          on E: Exception do
            inLibLog.Log.LogError(
              Format('Consolidacion de guias fallo para %s/%s: %s',
                     [Self.Name, sDescripcion, E.Message]));
        end;
        Result := True;
      end
      else
        Result := False;
    finally
      FreeAndNil(memStream);
      //https://forum.fast-report.com/en/categories/fastreport-vcl-6
    end;
  end;
end;
end.
