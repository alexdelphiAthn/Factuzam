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
  inLibGlobalVar, inMtoModalGenImpEle, cxStyles, dxSkinsForm,
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
  TfrmPrint = class(TfrmBase, IEliminadorFormatoImpresion)
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
    FUltimaRutaPdf: string;
    // D22: True si frxrprt1 contiene un formato personalizado
    // cargado del BLOB; False si contiene la plantilla base.
    FInformeEsPersonalizado: Boolean;
    // D22: evita traducir dos veces el informe ya cargado.
    FInformeTraducido: Boolean;
    // Lee el .frx serializado en VALUE_BLOB_USUPER de la fila identificada
    // por (Self.Name, aDescripcion) — una vez localizada en unqryPerfiles
    // por Locate. La query principal ya no trae el BLOB (cientos de KB)
    // por performance; este helper hace el unico round-trip necesario y
    // vuelca el contenido en aStream. Devuelve True si se ha cargado.
    function LeerBlobFormato(const aDescripcion: string;
                             aStream: TStream): Boolean;
    // Persiste el .frx (aStream) en fza_usuarios_perfiles via SQL directo,
    // sin pasar por unqryPerfiles (que no expone el campo BLOB). Decide
    // INSERT vs UPDATE segun PK (USUARIO_GRUPO_USUPER, KEY_USUPER,
    // SUBKEY_USUPER). Usado por frxdsgnr1SaveReport.
    procedure GuardarBlobFormato(const aUsuario, aSubKey,
                                  aDescripcion: string;
                                  aStream: TStream;
                                  aInsertar: Boolean);
    // D22: traduce los textos visibles del informe cargado antes
    // de PrepareReport. No se invoca en el flujo de edicion para
    // no guardar textos traducidos en el BLOB del formato.
    procedure TraducirInformeActual;
  protected
    procedure PdfExportado(const ARuta: string); virtual;
    property FormatoElegido: string read sElegido;
  public
    procedure CargarFormatos(form:TfrmMtoModalGenImpEle);
    procedure DeleteForm(sElegido:String;form:TfrmMtoModalGenImpEle);
    procedure EliminarFormatoImpresion(
      const ANombre: string;
      ASelector: TObject);
    procedure preparar_consulta; virtual; abstract;
    procedure AfterReportLoaded; virtual;
    // OnBeforePrint del report: encadena la sustitución de fotos
    // (foto300/foto600/fotoReal) con la del QR tributario Verifactu
    // ('qrverifactu') en cada iteración del informe
    procedure ReportBeforePrintConQR(Component: TfrxReportComponent);
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
    // Exporta sin diálogo el formato que el usuario acaba de seleccionar.
    function ExportarPdfActual(const ARuta: string): Boolean;
    property UltimaRutaPdf: string read FUltimaRutaPdf;
    // NUEVOS HOOKS PARA SOPORTE DE CLIENTDATASETS:
    function RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet; virtual;
    procedure OnGuiasAplicadas; virtual;
  end;

procedure RebindReportDataSetsByDataModule(Report: TfrxReport;
                                           DM: TDataModule);

implementation

uses
  inMtoModalGenImpSave, inLibUser, inLibPathTokens,
  System.Generics.Collections, System.Rtti, inLibFotos, inLibVerifactu,
  inMtoModalInformesGuias, inMtoModalWizardEditar, inLibLog,
  inLibInformesGuiasCache, inLibMsgComun, inLibTraduccionesInforme;

{$R *.dfm}

function TfrmPrint.RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet;
begin
  Result := aCDS; // Por defecto devuelve el mismo
end;

procedure TfrmPrint.OnGuiasAplicadas;
begin
  // Vacío por defecto en la clase base
end;

procedure TfrmPrint.PdfExportado(const ARuta: string);
begin
  FUltimaRutaPdf := ARuta;
end;

function RutaPdfExportado(AExportador: TfrxPDFExport): string;
begin
  Result := AExportador.FileName;
  if ExtractFilePath(Result) = '' then
    Result := IncludeTrailingPathDelimiter(AExportador.DefaultPath) + Result;
  if SameText(ExtractFileExt(Result), '') then
    Result := Result + '.pdf';
  if not FileExists(Result) then
    Result := '';
end;

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
  // Aqui ademas enganchamos el OnBeforePrint del Report para que en
  // cada iteracion FastReport refresque los TfrxPictureView llamados
  // foto300 / foto600 / fotoReal con la foto del registro activo de la
  // banda padre (necesario en etiquetas y otros informes iterativos) y
  // el llamado 'qrverifactu' con el QR tributario de la factura.
  frxrprt1.OnBeforePrint := ReportBeforePrintConQR;
end;

procedure TfrmPrint.ReportBeforePrintConQR(Component: TfrxReportComponent);
begin
  oFotos.HandlerReportBeforePrint(Component);
  // Objetos que SÍ reciben el evento (QR/título en una banda de datos)
  SustituirQRVerifactuEnReport(ParametrosApp, Component);
  SustituirTituloFacturaEnReport(Component);
  // Vía fiable: al disparar la banda (la cabecera de página recibe el
  // evento aunque sus objetos sueltos no), rellenamos QR y título de
  // sus hijos con la factura activa
  AplicarVerifactuEnBanda(ParametrosApp, Component);
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
  i, k, nPares, iSuf, iGuia: Integer;
  sSqlActual, sSqlNuevo, sCol, sAlias, sOn, sSelectExt: string;
  setCamposMaster: TStringList;
  arrMaster, arrDetail: TArray<string>;
  arrGuias: TArray<TInformeGuiaItem>;
  sFormatoBuscado: string;
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
  // Las guías se sirven del colaborador precargado al iniciar sesión.
  if not Assigned(InformesGuiasCache) or
     (not InformesGuiasCache.Cargada) then
    Exit;
  if (sElegido = '') or SameText(sElegido, 'Predeterminado') then
    sFormatoBuscado := ''
  else
    sFormatoBuscado := sElegido;
  arrGuias := InformesGuiasCache.Obtener(
    Self.Name,
    sFormatoBuscado);
  if Length(arrGuias) = 0 then
    Exit;
  qryColsExt := TUniQuery.Create(nil);
  try
    qryColsExt.Connection := ConexionPrincipal;
    qryColsExt.SQL.Text :=
      'select COLUMN_NAME from information_schema.COLUMNS ' +
      ' where TABLE_SCHEMA = database() and TABLE_NAME = :TAB ' +
      ' order by ORDINAL_POSITION';
    for iGuia := 0 to High(arrGuias) do
    begin
      sDatasetMaster := arrGuias[iGuia].DatasetMaster;
      sTabla         := arrGuias[iGuia].Tabla;
      sMaster        := arrGuias[iGuia].MasterFields;
      sDetail        := arrGuias[iGuia].DetailFields;
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
          Continue;
        end;
        oDS := dsMaster.DataSet;
        if (oDS = nil) and (dsMaster.DataSource <> nil) then
          oDS := dsMaster.DataSource.DataSet;
        if (oDS <> nil) and (oDS is TClientDataSet) then
          oDS := RelacionarClientDataSetConQuery(oDS);
        if (oDS = nil) or not (oDS is TUniQuery) then
        begin
          inLibLog.Log.LogWarning(Format(
            'Guia ignorada: master %s no es TUniQuery', [sDatasetMaster]));
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
          Continue;

        // 3) Inferir los campos ACTUALES del master (envoltorio
        //    WHERE 1=0 con parametros copiados del original).
        setCamposMaster := TStringList.Create;
        setCamposMaster.CaseSensitive := False;
        setCamposMaster.Sorted := True;
        setCamposMaster.Duplicates := dupIgnore;
        try
          qryTmp := TUniQuery.Create(nil);
          try
            qryTmp.Connection := ConexionPrincipal;
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
            Continue;

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
          // Equivalente programatico al "Update Fields" del diseñador
          // FastReport. El .frx guarda en FieldAliases del TfrxDBDataset
          // la lista estatica de campos conocidos al guardar; al
          // recargar el informe, FastReport tira de esa lista y no ve
          // los campos que añade el LEFT JOIN. Vaciarla obliga a leer
          // los campos dinamicamente del TUniQuery enriquecido en el
          // siguiente PrepareReport.
          try
            dsMaster.FieldAliases.Clear;
          except
            // Con alias viejos el disenyador mostrara la lista antigua.
            on E: Exception do
              inLibLog.Log.LogWarning(
                'GenImp: FieldAliases.Clear fallo: ' + E.Message);
          end;
          // FastReport cachea internamente los Fields de TfrxDBDataset:
          // al diseñar despues de un cambio de SQL los campos nuevos no
          // aparecen hasta pulsar "Update Fields". Forzamos el
          // reescaneo asignando nil + valor original al binding.
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
            // Si la version de FastReport no acepta el truco, no es
            // critico: solo significa que el usuario tendra que pulsar
            // Update Fields manualmente.
            on E: Exception do
              inLibLog.Log.LogWarning(
                'GenImp: reenganche del dataset FastReport fallo: ' +
                E.Message);
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
    end;
  finally
    FreeAndNil(qryColsExt);
  end;
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
    qrySrc.Connection := ConexionPrincipal;
    qrySrc.SQL.Text :=
      'select CODIGO_INFGUI from fza_informes_guias ' +
      ' where INFORME_INFGUI = :INF and FORMATO_INFGUI = ''''';
    qrySrc.ParamByName('INF').AsString := Self.Name;
    qrySrc.Open;

    qryChk.Connection := ConexionPrincipal;
    qryChk.SQL.Text :=
      'select 1 from fza_informes_guias ' +
      ' where INFORME_INFGUI = :INF ' +
      '   and FORMATO_INFGUI = :FMT ' +
      '   and CODIGO_INFGUI = :COD';

    qryIns.Connection := ConexionPrincipal;
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
          qryIns.ParamByName('USU').AsString := IdentidadSesion.Usuario;
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
  // Si ConsolidarGuiasParaFormato inserto nuevas filas en fza_informes_guias,
  // refrescamos el cache para que el proximo AbrirGuiasRuntime las vea.
  if Assigned(InformesGuiasCache) then
    InformesGuiasCache.Precargar;
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
    // El usuario pudo dar de alta / modificar / borrar guias en el modal:
    // refrescamos el cache para que el proximo Imprimir / PDF lo vea.
    if Assigned(InformesGuiasCache) then
      InformesGuiasCache.Precargar;
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
  iRespuesta: Integer;
begin
  inherited;
  Self.Hide;

  // NO llamamos Preparar_consulta aqui — el convenio del proyecto es
  // dejar siempre una consulta valida en el SQL.Text del TUniQuery
  // del data module (consulta de diseño). Si invocaramos
  // Preparar_consulta antes del wizard, el SQL.Text quedaria
  // sobrescrito con la version runtime que necesita parametros que
  // el usuario quiza no ha rellenado al entrar a Editar.

  // AfterReportLoaded re-enlaza los datasets del informe via
  // RebindReportDataSetsByDataModule. Lo necesitamos en ambas ramas
  // (wizard y clasico) para que los TfrxDBDataset esten visibles.
  AfterReportLoaded;

  // Preguntamos al usuario si quiere entrar al wizard para añadir o
  // editar campos extra (guias) de tablas / vistas externas. Si dice
  // que no, vamos directos al flujo clasico de edicion (Consultar_
  // Formularios + DesignReport). Cancelar sale sin abrir el diseñador.
  iRespuesta := MessageDlg(
    SPreguntaEditarCamposExtraInforme,
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if iRespuesta = mrCancel then
  begin
    Self.Show;
    Exit;
  end;

  bAceptado := False;

  if iRespuesta = mrYes then
  begin
    // Flujo wizard: 1) elegir/crear formato + permiso, 2) configurar
    // guias. Al finalizar, sFormato y sScope quedan fijados y el
    // guardado posterior del .frx no vuelve a preguntar el nombre.
    oWiz := TfrmModalWizardEditar.Create(Self);
    try
      oWiz.sInforme := Self.Name;
      oWiz.FReport  := frxrprt1;
      oWiz.ShowModal;
      // El wizard puede haber dado de alta / editado guias: refresco cache.
      if Assigned(InformesGuiasCache) then
        InformesGuiasCache.Precargar;
      if oWiz.sFicha = 'S' then
      begin
        sElegido           := oWiz.sFormato;
        FScopePerfilFijado := oWiz.sScope;
        FFormatoFijado     := True;
        bAceptado          := True;

        // Cargar el .frx del formato elegido. Si existe lo cargamos
        // del BLOB (query lazy en LeerBlobFormato); si no existe o el
        // BLOB esta vacio partimos del .frx base.
        if oWiz.bExiste then
        begin
          memStream := TMemoryStream.Create;
          try
            if LeerBlobFormato(sElegido, memStream) then
            begin
              frxrprt1.LoadFromStream(memStream);
              FInformeEsPersonalizado := True;
            end
            else
            begin
              frxrprt1.AssignAll(frxReportOrigen);
              FInformeEsPersonalizado := False;
            end;
            FInformeTraducido := False;
          finally
            FreeAndNil(memStream);
          end;
        end
        else
        begin
          frxrprt1.AssignAll(frxReportOrigen);
          FInformeEsPersonalizado := False;
          FInformeTraducido := False;
        end;

        // Re-enlazar datasets despues de cargar/asignar el report.
        AfterReportLoaded;
      end;
    finally
      FreeAndNil(oWiz);
    end;
  end
  else  // iRespuesta = mrNo
  begin
    // Flujo clasico: elegir un formato existente (o usar el original)
    // y abrir el diseñador. Las guias ya configuradas se aplican
    // igualmente; lo unico que NO se hace es entrar al wizard de
    // creacion/edicion de guias. Al guardar el .frx el modal de
    // "Guardar Objeto Editado" sale como siempre.
    Consultar_Formularios(True);
    bAceptado := sElegido <> '';
  end;

  if bAceptado then
  begin
    // Abrimos las guias activas del informe / formato (asi el usuario
    // las ve en el arbol de datasets del diseñador y los campos extra
    // estan disponibles para arrastrar al .frx).
    AbrirGuiasRuntime(False);
    // Los informes basados en TClientDataSet deben copiar de nuevo los
    // campos añadidos a la consulta física antes de abrir el diseñador.
    OnGuiasAplicadas;
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
    OnGuiasAplicadas;
    TraducirInformeActual;
    try
      frxrprt1.PrepareReport(True);
      frxlsxprtExcel.DefaultPath := ParametrosApp.GetPath('appDirExcel');
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
    OnGuiasAplicadas;
    TraducirInformeActual;
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
    OnGuiasAplicadas;
    TraducirInformeActual;
    try
      frxrprt1.PrepareReport(True);
      frxpdfxprtPedWeb.DefaultPath := ParametrosApp.GetPath('appDirPDF');
      frxrprt1.Export(frxpdfxprtPedWeb);
      PdfExportado(RutaPdfExportado(frxpdfxprtPedWeb));
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

function TfrmPrint.ExportarPdfActual(const ARuta: string): Boolean;
var
  bMostrarDialogo: Boolean;
  sDirectorioPrevio: string;
  sFicheroPrevio: string;
begin
  Result := False;
  if (sElegido <> '') and (Trim(ARuta) <> '') then
  begin
    Preparar_consulta;
    AfterReportLoaded;
    AbrirGuiasRuntime(True);
    OnGuiasAplicadas;
    TraducirInformeActual;
    bMostrarDialogo := frxpdfxprtPedWeb.ShowDialog;
    sDirectorioPrevio := frxpdfxprtPedWeb.DefaultPath;
    sFicheroPrevio := frxpdfxprtPedWeb.FileName;
    try
      frxrprt1.PrepareReport(True);
      frxpdfxprtPedWeb.ShowDialog := False;
      frxpdfxprtPedWeb.DefaultPath := ExtractFilePath(ARuta);
      frxpdfxprtPedWeb.FileName := ARuta;
      frxrprt1.Export(frxpdfxprtPedWeb);
      Result := FileExists(ARuta);
      if Result then
        PdfExportado(ARuta);
    finally
      frxpdfxprtPedWeb.ShowDialog := bMostrarDialogo;
      frxpdfxprtPedWeb.DefaultPath := sDirectorioPrevio;
      frxpdfxprtPedWeb.FileName := sFicheroPrevio;
      CerrarGuiasRuntime;
    end;
  end;
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
    OnGuiasAplicadas;
    TraducirInformeActual;
    try
      // Los demas botones (Imprimir/PDF/Excel/Editar) hacen
      // PrepareReport(True) antes; Vista Preliminar tenia ShowReport
      // pelado y FastReport reutilizaba la preparacion previa, sin
      // los campos enriquecidos por las guias.
      frxrprt1.PrepareReport(True);
      frxrprt1.ShowReport;
    finally
      CerrarGuiasRuntime;
    end;
  end;
  Self.Show;
end;

procedure TfrmPrint.CargarFormatos(form:TfrmMtoModalGenImpEle);
var
  perfilDic: TProfileDicc;
  kvp: TPair<string, TDictValue>;
begin
  // Servimos la lista de formatos desde el cache precargado al login
  // (PrecargarPerfilesUsuario). Asi no se va a BBDD a refrescar; el BLOB
  // del .frx se carga lazy cuando el usuario elige un formato concreto.
  form.lstFormatos.Clear;
  if Assigned(PerfilesLectura) and
     PerfilesLectura.CargarPerfilFormulario(Self.Name, perfilDic) then
  try
    for kvp in perfilDic do
      form.lstFormatos.AddItem(kvp.Value.sValue, nil);
    if form.lstFormatos.Count > 0 then
      form.lstFormatos.ItemIndex := 0;
  finally
    FreeAndNil(perfilDic);
  end
  else
  begin
    // Fallback: si la precarga fallo (FCachePrecargada=False) tiramos del
    // TUniQuery como antes. No es lo esperado en operacion normal.
    with unqryPerfiles do
    begin
      Refresh;
      if RecordCount > 0 then
      begin
        First;
        while not Eof do
        begin
          form.lstFormatos.AddItem(FieldByName('VALUE_USUPER').AsString, nil);
          Next;
        end;
        form.lstFormatos.ItemIndex := 0;
      end;
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
    sDefaultSubKey := PerfilesLectura.ObtenerSubclavePerfil(
      Self.Name + '_default',
      '');
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
      form := TfrmMtoModalGenImpEle.Create(Self, Self);
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
                  PerfilesEscritura.EliminarPerfil(
                    IdentidadSesion.Usuario,
                    Self.Name + '_default');
                  PerfilesEscritura.EliminarPerfil(
                    IdentidadSesion.Grupo,
                    Self.Name + '_default');
                  PerfilesEscritura.EliminarPerfil(
                    oAll,
                    Self.Name + '_default');
                  PerfilesEscritura.GrabarPerfil(
                    sPermisos,
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
              PerfilesEscritura.EliminarPerfil(
                IdentidadSesion.Usuario,
                Self.Name + '_default');
              PerfilesEscritura.EliminarPerfil(
                IdentidadSesion.Grupo,
                Self.Name + '_default');
              PerfilesEscritura.EliminarPerfil(
                oAll,
                Self.Name + '_default');
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
        // El BLOB del .frx no viene en unqryPerfiles (query solo de
        // metadatos por performance); LeerBlobFormato hace el unico
        // round-trip necesario para esta seleccion.
        if LeerBlobFormato(sDescripcion, memStream) then
        begin
          frxrprt1.LoadFromStream(memStream);
          FInformeEsPersonalizado := True;
        end
        else
        begin
          frxrprt1.AssignAll(frxReportOrigen);
          FInformeEsPersonalizado := False;
        end;
        FInformeTraducido := False;
      finally
        FreeAndNil(memStream);
      end;
    end
    else if (sFichaAccion = 'O') then
    begin
      frxrprt1.AssignAll(frxReportOrigen);
      FInformeEsPersonalizado := False;
      FInformeTraducido := False;
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
    unqrySol.Connection := ConexionPrincipal;
    unqrySol.SQL.Text := 'SELECT USUARIO_GRUPO_USUPER ' +
                         '  FROM fza_usuarios_perfiles ' +
                         ' WHERE KEY_USUPER = :NombreReport ' +
                         '   AND VALUE_USUPER = :Descripcion ';
    unqrySol.ParamByName('NombreReport').AsString := Self.Name;
    unqrySol.ParamByName('Descripcion').AsString := sElegido;
    unqrySol.Open;
    sUserProp := unqrySol.FindField('USUARIO_GRUPO_USUPER').AsString;
    if not((IdentidadSesion.GrupoRaiz = 'S') or
        (IdentidadSesion.Usuario = sUserProp) or
        (IdentidadSesion.Grupo = sUserProp)) then
      ShowMessageFmt(SErrorPrivilegiosBorrarFormato, [sUserProp])
    else
    begin
      iButtonSel := MessageDlg(SPreguntaBorrarFormato,
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
        // Refrescamos cache para que CargarFormatos no vea el borrado.
        if Assigned(CachePerfiles) then
          CachePerfiles.ResincronizarPerfilFormulario(Self.Name);
      end;
      CargarFormatos(form);
    end;
  finally
    FreeAndNil(unqrySol);
  end;
end;

procedure TfrmPrint.EliminarFormatoImpresion(
  const ANombre: string;
  ASelector: TObject);
begin
  if ASelector is TfrmMtoModalGenImpEle then
    DeleteForm(ANombre, TfrmMtoModalGenImpEle(ASelector));
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

function TfrmPrint.LeerBlobFormato(const aDescripcion: string;
                                    aStream: TStream): Boolean;
var
  qry: TUniQuery;
  fld: TBlobField;
begin
  Result := False;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT VALUE_BLOB_USUPER FROM fza_usuarios_perfiles ' +
      ' WHERE KEY_USUPER     = :FormName ' +
      '   AND VALUE_USUPER   = :Descripcion ' +
      '   AND (USUARIO_GRUPO_USUPER = :Usuario OR ' +
      '        USUARIO_GRUPO_USUPER = :Grupo   OR ' +
      '        USUARIO_GRUPO_USUPER = :Todos) ' +
      ' LIMIT 1';
    qry.ParamByName('FormName').AsString    := Self.Name;
    qry.ParamByName('Descripcion').AsString := aDescripcion;
    qry.ParamByName('Usuario').AsString     := IdentidadSesion.Usuario;
    qry.ParamByName('Grupo').AsString       := IdentidadSesion.Grupo;
    qry.ParamByName('Todos').AsString       := oAll;
    qry.Open;
    if qry.IsEmpty then
      Exit;
    fld := TBlobField(qry.FieldByName('VALUE_BLOB_USUPER'));
    if fld.IsNull then
      Exit;
    fld.SaveToStream(aStream);
    aStream.Position := 0;
    Result := True;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmPrint.GuardarBlobFormato(const aUsuario, aSubKey,
                                        aDescripcion: string;
                                        aStream: TStream;
                                        aInsertar: Boolean);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    if aInsertar then
      qry.SQL.Text :=
        'INSERT INTO fza_usuarios_perfiles (' +
        '  USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER, ' +
        '  VALUE_USUPER, VALUE_BLOB_USUPER, ' +
        '  INSTANTE_ALTA, INSTANTE_MODIF, ' +
        '  USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (' +
        '  :USU, :KEY, :SUB, ' +
        '  :VAL, :BLOB, ' +
        '  NOW(), NOW(), ' +
        '  :USUACT, :USUACT)'
    else
      qry.SQL.Text :=
        'UPDATE fza_usuarios_perfiles SET ' +
        '  VALUE_USUPER      = :VAL, ' +
        '  VALUE_BLOB_USUPER = :BLOB, ' +
        '  INSTANTE_MODIF    = NOW(), ' +
        '  USUARIO_MODIF     = :USUACT ' +
        ' WHERE USUARIO_GRUPO_USUPER = :USU ' +
        '   AND KEY_USUPER           = :KEY ' +
        '   AND SUBKEY_USUPER        = :SUB';
    qry.ParamByName('USU').AsString    := aUsuario;
    qry.ParamByName('KEY').AsString    := Self.Name;
    qry.ParamByName('SUB').AsString    := aSubKey;
    qry.ParamByName('VAL').AsString    := aDescripcion;
    qry.ParamByName('USUACT').AsString := IdentidadSesion.Usuario;
    aStream.Position := 0;
    qry.ParamByName('BLOB').LoadFromStream(aStream, ftBlob);
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmPrint.TraducirInformeActual;
begin
  if not FInformeTraducido then
  begin
    TraducirInformeFastReport(
      frxrprt1,
      Self,
      Traducciones,
      FInformeEsPersonalizado);
    FInformeTraducido := True;
  end;
end;

procedure TfrmPrint.FormCreate(Sender: TObject);
begin
  inherited;
  if Width > Screen.WorkAreaWidth then
    Width := Screen.WorkAreaWidth;
  if Height > Screen.WorkAreaHeight then
    Height := Screen.WorkAreaHeight;
  pnl1.Visible := True;
  pnl1.Align := alRight;
  pnl1.BringToFront;
  Self.Position := poScreenCenter;
  unqryPerfiles.ParamByName('FormName').AsString := Self.Name;
  unqryPerfiles.ParamByName('Usuario').AsString := IdentidadSesion.Usuario;
  unqryPerfiles.ParamByName('Grupo').AsString := IdentidadSesion.Grupo;
  unqryPerfiles.ParamByName('Todos').AsString := oAll;
  unqryPerfiles.KeyFields := 'KEY_USUPER;VALUE_USUPER';
  unqryPerfiles.Open;
  FGuiasRuntime := TList.Create;
end;

function TfrmPrint.frxdsgnr1SaveReport(Report: TfrxReport;
  SaveAs: Boolean): Boolean;
var
  memStream:TMemoryStream;
  formulario: TfrmModalGenImpSave;
  bGuardar, bExiste : Boolean;
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
    if sPermisos = '' then sPermisos := IdentidadSesion.Usuario;
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
      Report.SaveToStream(memStream);
      memStream.Position:=0;
      // Locate sigue siendo util: la query trae metadatos suficientes
      // (VALUE_USUPER) para decidir INSERT vs UPDATE sin pedir el BLOB.
      bExiste := unqryPerfiles.Locate('VALUE_USUPER', sDescripcion, []);
      // Si FFormatoFijado=True el wizard ya advirtio al usuario y vamos
      // directos al UPDATE. En modo normal preguntamos confirmacion antes
      // de sobreescribir un formato existente.
      if bExiste and (not FFormatoFijado) then
      begin
        if Application.MessageBox(PChar(SPreguntaReemplazarInforme),
                                  PChar(STituloAdvertenciaInforme),
                                  MB_YESNO) <> ID_YES then
          bGuardar := False;
      end;
      if (bGuardar) then
      begin
        // Persistir via SQL directo: unqryPerfiles ya no expone el campo
        // VALUE_BLOB_USUPER, asi que el flujo Insert/Edit + Post del
        // dataset no sirve para el BLOB. GuardarBlobFormato hace el
        // INSERT o UPDATE (segun bExiste) con un unico round-trip.
        GuardarBlobFormato(sPermisos,
                           frxrprt1.Name + '_' + sDescripcion,
                           sDescripcion,
                           memStream,
                           not bExiste);
        // Refrescamos unqryPerfiles para que CargarFormatos vea el alta
        // / edicion en la proxima invocacion sin un Close+Open implicito.
        unqryPerfiles.Close;
        unqryPerfiles.Open;
        // Refrescamos el cache de perfiles del form (lo usa CargarFormatos)
        // para que la lista de formatos refleje el alta inmediatamente.
        if Assigned(CachePerfiles) then
          CachePerfiles.ResincronizarPerfilFormulario(Self.Name);
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
    end;
  end;
end;
end.
