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
    // Por cada TUniQuery que modificamos al aplicar guias, guardamos el
    // SQL.Text original aqui (objeto = TUniQuery, string = SQL previo)
    // para poder restaurarlo en CerrarGuiasRuntime. Asi el data module
    // queda igual que como vino tras el cierre del modal.
    FSqlOriginales: TStringList;
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

  procedure CopiarParametros(src, dst: TUniQuery);
  var
    k: Integer;
    pSrc: TUniParam;
  begin
    for k := 0 to dst.Params.Count - 1 do
    begin
      pSrc := src.Params.FindParam(dst.Params[k].Name);
      if pSrc <> nil then
        dst.Params[k].Value := pSrc.Value
      else
        dst.Params[k].Clear;
    end;
  end;

  function SplitFields(const aStr: string): TArray<string>;
  var
    sl: TStringList;
    k: Integer;
  begin
    sl := TStringList.Create;
    try
      sl.StrictDelimiter := True;
      sl.Delimiter := ';';
      sl.DelimitedText := aStr;
      SetLength(Result, sl.Count);
      for k := 0 to sl.Count - 1 do
        Result[k] := Trim(sl[k]);
    finally
      FreeAndNil(sl);
    end;
  end;

var
  sDatasetMaster, sTabla, sMaster, sDetail: string;
  dsMaster: TfrxDBDataset;
  oDS: TDataSet;
  uniMaster, qryColsExt, qryTmp: TUniQuery;
  i, k, nPares, iSuf: Integer;
  sSqlActual, sSqlNuevo, sCol, sAlias, sOn, sSelectExt: string;
  setCamposMaster: TStringList;
  arrMaster, arrDetail: TArray<string>;
begin
  // Asegurar listas internas. CerrarGuiasRuntime tambien las gestiona.
  if FGuiasRuntime = nil then
    FGuiasRuntime := TList.Create
  else
    CerrarGuiasRuntime;
  if FSqlOriginales = nil then
    FSqlOriginales := TStringList.Create;

  // El parametro aSoloUsadasEnReport queda como referencia historica:
  // ahora cada guia enriquece el SQL del TUniQuery del master con un
  // LEFT JOIN, asi que los campos extra son nativos del master en el
  // .frx (`[<UserName>."CAMPO"]`) y no hay datasets paralelos que
  // filtrar.

  unqryInformesGuias.Close;
  unqryInformesGuias.ParamByName('INF').AsString := Self.Name;
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

  qryColsExt := TUniQuery.Create(nil);
  try
    qryColsExt.Connection := oConn;
    qryColsExt.SQL.Text :=
      'select COLUMN_NAME from information_schema.COLUMNS ' +
      ' where TABLE_SCHEMA = database() and TABLE_NAME = :TAB ' +
      ' order by ORDINAL_POSITION';

    unqryInformesGuias.First;
    while not unqryInformesGuias.Eof do
    begin
      sDatasetMaster := unqryInformesGuias.FieldByName(
                                       'DATASET_MASTER_INFGUI').AsString;
      sTabla         := unqryInformesGuias.FieldByName(
                                       'TABLA_INFGUI').AsString;
      sMaster        := unqryInformesGuias.FieldByName(
                                       'MASTER_FIELDS_INFGUI').AsString;
      sDetail        := unqryInformesGuias.FieldByName(
                                       'DETAIL_FIELDS_INFGUI').AsString;
      try
        // 1) Localizar el TfrxDBDataset por UserName y resolver
        //    TDataSet (DataSet directo o via DataSource).
        dsMaster := nil;
        for i := 0 to frxrprt1.Datasets.Count - 1 do
          if (frxrprt1.Datasets[i].DataSet is TfrxDBDataset) and
             SameText(frxrprt1.Datasets[i].DataSet.UserName,
                      sDatasetMaster) then
          begin
            dsMaster := TfrxDBDataset(frxrprt1.Datasets[i].DataSet);
            Break;
          end;
        if dsMaster = nil then
        begin
          inLibLog.Log.LogWarning(Format(
            'Guia ignorada: master "%s" no esta en el report de %s',
            [sDatasetMaster, Self.Name]));
          unqryInformesGuias.Next;
          Continue;
        end;
        oDS := dsMaster.DataSet;
        if (oDS = nil) and (dsMaster.DataSource <> nil) then
          oDS := dsMaster.DataSource.DataSet;
        if (oDS = nil) or not (oDS is TUniQuery) then
        begin
          inLibLog.Log.LogWarning(Format(
            'Guia ignorada: master %s no es TUniQuery', [sDatasetMaster]));
          unqryInformesGuias.Next;
          Continue;
        end;
        uniMaster := TUniQuery(oDS);

        // 2) Guardar SQL.Text original si es la primera vez que tocamos
        //    este TUniQuery. CerrarGuiasRuntime lo restaurara.
        if FSqlOriginales.IndexOfObject(uniMaster) < 0 then
          FSqlOriginales.AddObject(uniMaster.SQL.Text, uniMaster);

        // Limpieza robusta: quitamos whitespace y ';' finales en
        // bucle, asi cubrimos casos en que el SQL original termina con
        // ';' + #13#10 / espacios (caso real de unqryLinFacPrint).
        sSqlActual := TrimRight(uniMaster.SQL.Text);
        while (sSqlActual <> '') and
              (sSqlActual[Length(sSqlActual)] = ';') do
        begin
          SetLength(sSqlActual, Length(sSqlActual) - 1);
          sSqlActual := TrimRight(sSqlActual);
        end;
        if sSqlActual = '' then
        begin
          unqryInformesGuias.Next;
          Continue;
        end;

        // 3) Inferir los campos ACTUALES del master (envoltorio
        //    WHERE 1=0 con parametros copiados del original).
        setCamposMaster := TStringList.Create;
        setCamposMaster.CaseSensitive := False;
        setCamposMaster.Sorted := True;
        setCamposMaster.Duplicates := dupIgnore;
        try
          qryTmp := TUniQuery.Create(nil);
          try
            qryTmp.Connection := oConn;
            qryTmp.SQL.Text :=
              'select * from (' + sSqlActual + ') X_GUIAS where 1=0';
            CopiarParametros(uniMaster, qryTmp);
            qryTmp.Open;
            for k := 0 to qryTmp.FieldCount - 1 do
              setCamposMaster.Add(qryTmp.Fields[k].FieldName);
            qryTmp.Close;
          finally
            FreeAndNil(qryTmp);
          end;

          // 4) Leer columnas de la tabla externa y resolver alias por
          //    colision (CODIGO_ART -> CODIGO_ART1, CODIGO_ART2...).
          sSelectExt := '';
          qryColsExt.Close;
          qryColsExt.ParamByName('TAB').AsString := sTabla;
          qryColsExt.Open;
          while not qryColsExt.Eof do
          begin
            sCol := qryColsExt.FieldByName('COLUMN_NAME').AsString;
            sAlias := sCol;
            if setCamposMaster.IndexOf(sAlias) >= 0 then
            begin
              iSuf := 1;
              while setCamposMaster.IndexOf(sCol + IntToStr(iSuf)) >= 0 do
                Inc(iSuf);
              sAlias := sCol + IntToStr(iSuf);
            end;
            setCamposMaster.Add(sAlias);
            if sSelectExt <> '' then sSelectExt := sSelectExt + ', ';
            sSelectExt := sSelectExt +
              'EXT_GUIA.' + sCol + ' AS ' + sAlias;
            qryColsExt.Next;
          end;
          qryColsExt.Close;

          // 5) Componer ON clause con master/detail fields.
          arrMaster := SplitFields(sMaster);
          arrDetail := SplitFields(sDetail);
          nPares := Length(arrMaster);
          if Length(arrDetail) < nPares then nPares := Length(arrDetail);
          sOn := '';
          for k := 0 to nPares - 1 do
          begin
            if (Trim(arrMaster[k]) = '') or (Trim(arrDetail[k]) = '') then
              Continue;
            if sOn <> '' then sOn := sOn + ' AND ';
            sOn := sOn + 'EXT_GUIA.' + arrDetail[k] + ' = M_GUIA.' +
                          arrMaster[k];
          end;
          if (sOn = '') or (sSelectExt = '') then
          begin
            unqryInformesGuias.Next;
            Continue;
          end;

          // 6) Componer SQL enriquecido y aplicarlo. Los parametros se
          //    mantienen porque solo cambia SQL.Text.
          sSqlNuevo :=
            'SELECT M_GUIA.*, ' + sSelectExt + ' ' +
            'FROM (' + sSqlActual + ') M_GUIA ' +
            'LEFT JOIN ' + sTabla + ' EXT_GUIA ON ' + sOn;
          uniMaster.Close;
          uniMaster.SQL.Text := sSqlNuevo;
          // Reabrir el master con el SQL enriquecido para que el report
          // disponga de los nuevos campos al iterar. Los parametros se
          // mantienen porque solo cambia SQL.Text.
          try
            uniMaster.Open;
          except
            on E: Exception do
              inLibLog.Log.LogError(
                Format('Apertura del master enriquecido (%s) fallo: %s',
                       [sDatasetMaster, E.Message]));
          end;
          // FastReport cachea internamente los Fields de TfrxDBDataset:
          // al diseñar despues de un cambio de SQL los campos nuevos no
          // aparecen hasta pulsar "Update Fields". Lanzamos dos
          // estrategias en cadena para evitar tener que pulsarlo:
          //   1) Asignar nil + valor original al binding (DataSource /
          //      DataSet) — fuerza a TfrxDBDataset a re-leer la lista
          //      de campos del TDataSet.
          //   2) Close+Open del propio TfrxDBDataset — equivale al
          //      "Update Fields" del diseñador.
          try
            if dsMaster.DataSource <> nil then
            begin
              var dsOld := dsMaster.DataSource;
              dsMaster.DataSource := nil;
              dsMaster.DataSource := dsOld;
            end
            else if dsMaster.DataSet <> nil then
            begin
              var dOld := dsMaster.DataSet;
              dsMaster.DataSet := nil;
              dsMaster.DataSet := dOld;
            end;
          except
          end;
          try
            dsMaster.Close;
            dsMaster.Open;
          except
          end;
        finally
          FreeAndNil(setCamposMaster);
        end;
      except
        on E: Exception do
          inLibLog.Log.LogError(
            Format('Guia (%s -> %s) fallo: %s',
                   [sDatasetMaster, sTabla, E.Message]));
      end;
      unqryInformesGuias.Next;
    end;
  finally
    FreeAndNil(qryColsExt);
  end;
  unqryInformesGuias.Close;
end;

procedure TfrmPrint.CerrarGuiasRuntime;
var
  k, j: Integer;
  obj: TObject;
  uniMaster: TUniQuery;
  bEraAbierto: Boolean;
begin
  // 1) Restaurar el SQL.Text original de los TUniQuery enriquecidos.
  //    Conservamos abierto si lo estaba; si Open falla con el SQL
  //    original (raro pero posible), logueamos y seguimos.
  if FSqlOriginales <> nil then
  begin
    for k := 0 to FSqlOriginales.Count - 1 do
    begin
      uniMaster := TUniQuery(FSqlOriginales.Objects[k]);
      if uniMaster = nil then Continue;
      try
        bEraAbierto := uniMaster.Active;
        uniMaster.Close;
        uniMaster.SQL.Text := FSqlOriginales[k];
        if bEraAbierto then
          uniMaster.Open;
      except
        on E: Exception do
          inLibLog.Log.LogError(
            'Restaurar SQL del master fallo: ' + E.Message);
      end;
    end;
    FSqlOriginales.Clear;
  end;

  // 2) Limpiar componentes auxiliares que pudieran quedar de versiones
  //    anteriores del runtime (datasets paralelos). En el modelo actual
  //    FGuiasRuntime no se rellena, pero por defensa borramos lo que
  //    haya.
  if FGuiasRuntime <> nil then
  begin
    for k := FGuiasRuntime.Count - 1 downto 0 do
    begin
      obj := TObject(FGuiasRuntime[k]);
      if obj is TfrxDBDataset then
        for j := frxrprt1.Datasets.Count - 1 downto 0 do
          if frxrprt1.Datasets[j].DataSet = TfrxDataSet(obj) then
          begin
            frxrprt1.Datasets.Delete(j);
            Break;
          end;
      obj.Free;
    end;
    FGuiasRuntime.Clear;
  end;
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
      // Sin un PrepareReport(True) explicito FastReport puede tirar de
      // su cache de campos / paginas previa y no ver los campos que
      // las guias acaban de añadir al master. El resto de botones
      // (Imprimir, PDF, Excel, Editar) ya hacen PrepareReport antes;
      // Vista Preliminar tenia ShowReport pelado.
      frxrprt1.PrepareReport(True);
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
  FreeAndNil(FSqlOriginales);
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
