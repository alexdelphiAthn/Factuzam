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
  frxExportXLSX,
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
  frLanguageSpanish, frxSmartMemo, inLibImpresionPersistenciaIntf;
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
    frxdsgnr1: TfrxDesigner;
    frxReportOrigen: TfrxReport;
    ActionList1: TActionList;
    actSalir: TAction;
    frLocalizationController1: TfrLocalizationController;
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
    FServiciosPersistencia: TServiciosPersistenciaImpresion;
    FRestauracionesGuias: TInterfaceList;
    FUltimaRutaPdf: string;
    // D22: True si frxrprt1 contiene un formato personalizado
    // cargado del BLOB; False si contiene la plantilla base.
    FInformeEsPersonalizado: Boolean;
    // D22: evita traducir dos veces el informe ya cargado.
    FInformeTraducido: Boolean;
    function ContextoFormatos: TContextoFormatosImpresion;
    function LeerBlobFormato(const aDescripcion: string;
                             aStream: TStream): Boolean;
    procedure GuardarBlobFormato(const aUsuario, aSubKey,
                                  aDescripcion: string;
                                  aStream: TStream;
                                  aInsertar: Boolean);
    // D22: traduce los textos visibles del informe cargado antes
    // de PrepareReport. No se invoca en el flujo de edicion para
    // no guardar textos traducidos en el BLOB del formato.
    procedure TraducirInformeActual;
    procedure PrepararSelectorFormato(
      ASelector: TfrmMtoModalGenImpEle;
      const AFormatoPredeterminado: string);
    procedure EliminarFormatoPredeterminado;
    procedure GuardarFormatoPredeterminado(const AFormato: string);
    procedure ActualizarFormatoPredeterminado(
      ASelector: TfrmMtoModalGenImpEle;
      const AFormatoAnterior: string);
    procedure SeleccionarFormato(
      const AFormatoPredeterminado: string;
      out AAccion: string);
    procedure CargarFormatoElegido(const AAccion: string);
  protected
    function TraducirContenidoInforme: Boolean; virtual;
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
procedure AjustarFormatoHorizontalTallas(AInforme: TfrxReport);

implementation

uses
  inMtoModalGenImpSave, inLibUser, inLibPathTokens,
  System.Generics.Collections, System.Rtti, inLibFotos, inLibVerifactu,
  inMtoModalInformesGuias, inMtoModalWizardEditar,
  inLibInformesGuiasCache, inLibMsgComun, inLibTraduccionesInforme,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

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
  if (Report <> nil) and (DM <> nil) then
  begin
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
      if Map.Count > 0 then
      begin
        Report.DataSets.Clear;
        for ds in Map.Values do
          Report.DataSets.Add(ds);
        for i := 0 to Report.AllObjects.Count - 1 do
        begin
          obj := TfrxComponent(Report.AllObjects[i]);
          rType := ctx.GetType(obj.ClassType);
          prop := rType.GetProperty('DataSet');
          if (prop <> nil) and prop.IsReadable and prop.IsWritable then
          begin
            curVal := prop.GetValue(obj);
            if not curVal.IsEmpty then
            begin
              curObj := curVal.AsObject;
              if (curObj is TfrxDBDataset) and
                 Map.TryGetValue(
                   TfrxDBDataset(curObj).UserName, newDs) and
                 (newDs <> curObj) then
                prop.SetValue(obj, newDs);
            end;
          end;
        end;
      end;
    finally
      ctx.Free;
      FreeAndNil(Map);
    end;
  end;
end;

procedure AjustarFormatoHorizontalTallas(AInforme: TfrxReport);
const
  ALTO_FILA_TOTALES = 26.45671;
  TOP_FILA_TOTALES = 3.77953;
var
  iTalla: Integer;
  mCampo: TfrxMemoView;
  mImporte: TfrxMemoView;
  oTalla: TfrxComponent;
  mTalla: TfrxMemoView;
  mTotalesFiscales: TfrxMemoView;
  mUnidades: TfrxMemoView;
  oImporte: TfrxComponent;
  oResumen: TfrxComponent;
  oTotalesFiscales: TfrxComponent;
  oUnidades: TfrxComponent;

  procedure AjustarCampoLinea(const ANombre: string;
    AAlturaFuente: Integer);
  var
    oCampo: TfrxComponent;
  begin
    oCampo := AInforme.FindObject(ANombre);
    if oCampo is TfrxMemoView then
    begin
      mCampo := TfrxMemoView(oCampo);
      mCampo.Font.Height := AAlturaFuente;
      mCampo.WordWrap := False;
      mCampo.Clipped := True;
    end;
  end;

  procedure AmpliarColumnaModelo(const ANombreModelo,
    ANombreDescripcion: string);
  const
    ANCHO_MODELO_PRIORITARIO = 80;
    ANCHO_MINIMO_DESCRIPCION = 100;
  var
    mDescripcion: TfrxMemoView;
    mModelo: TfrxMemoView;
    oDescripcion: TfrxComponent;
    oModelo: TfrxComponent;
    rAumento: Extended;
  begin
    oModelo := AInforme.FindObject(ANombreModelo);
    oDescripcion := AInforme.FindObject(ANombreDescripcion);
    if (oModelo is TfrxMemoView) and
       (oDescripcion is TfrxMemoView) then
    begin
      mModelo := TfrxMemoView(oModelo);
      mDescripcion := TfrxMemoView(oDescripcion);
      if (mModelo.Width < ANCHO_MODELO_PRIORITARIO) and
         (mDescripcion.Width > ANCHO_MINIMO_DESCRIPCION) and
         (Abs(mDescripcion.Left -
          (mModelo.Left + mModelo.Width)) < 1) then
      begin
        rAumento := ANCHO_MODELO_PRIORITARIO - mModelo.Width;
        if rAumento >
           (mDescripcion.Width - ANCHO_MINIMO_DESCRIPCION) then
          rAumento := mDescripcion.Width - ANCHO_MINIMO_DESCRIPCION;
        mModelo.Width := mModelo.Width + rAumento;
        mDescripcion.Left := mDescripcion.Left + rAumento;
        mDescripcion.Width := mDescripcion.Width - rAumento;
      end;
    end;
  end;
begin
  // Las guias horizontales reservan solo 26,5 puntos por talla. Incluso con
  // la correccion anterior a -12, valores como XXL/XXXL podian recortarse.
  // Se fuerza una sola linea tambien en formatos personalizados de la BBDD.
  if Assigned(AInforme) then
  begin
    for iTalla := 1 to 20 do
    begin
      oTalla := AInforme.FindObject(Format('GuiaT%.2d', [iTalla]));
      if oTalla is TfrxMemoView then
      begin
        mTalla := TfrxMemoView(oTalla);
        if mTalla.Width <= 30 then
        begin
          mTalla.Font.Height := -9;
          mTalla.WordWrap := False;
          mTalla.Clipped := True;
        end;
      end;
    end;

    // Se prioriza el modelo: gana espacio a la descripcion y conserva una
    // fuente mayor. Ningun campo puede invadir la fila siguiente.
    AmpliarColumnaModelo('HdrModelo', 'HdrDescr');
    AmpliarColumnaModelo('LinModelo', 'LinDescr');
    AjustarCampoLinea('LinModelo', -11);
    AjustarCampoLinea('LinDescr', -10);
    AjustarCampoLinea('LinColor', -10);

    // El total definitivo no es un pie de pagina: debe aparecer una sola vez,
    // despues de la ultima linea. Se mueve al resumen final incluso cuando el
    // formato procede de la BBDD; la numeracion permanece en PageFooter1.
    oResumen := AInforme.FindObject('ReportSummaryTotalesFiscales');
    oUnidades := AInforme.FindObject('MemoTotalUds');
    oImporte := AInforme.FindObject('MemoTotalImporte');
    oTotalesFiscales := AInforme.FindObject('MemoTotalesFiscales');
    if (oResumen is TfrxReportSummary) and
       (oUnidades is TfrxMemoView) and
       (oImporte is TfrxMemoView) then
    begin
      mUnidades := TfrxMemoView(oUnidades);
      mImporte := TfrxMemoView(oImporte);
      if (mUnidades.Parent <> oResumen) or
         (mImporte.Parent <> oResumen) then
      begin
        if (oTotalesFiscales is TfrxMemoView) and
           (oTotalesFiscales.Parent = oResumen) then
        begin
          mTotalesFiscales := TfrxMemoView(oTotalesFiscales);
          mTotalesFiscales.Top :=
            mTotalesFiscales.Top + ALTO_FILA_TOTALES;
        end;
        TfrxReportSummary(oResumen).Height :=
          TfrxReportSummary(oResumen).Height + ALTO_FILA_TOTALES;
        mUnidades.Parent := TfrxReportSummary(oResumen);
        mImporte.Parent := TfrxReportSummary(oResumen);
        mUnidades.Top := TOP_FILA_TOTALES;
        mImporte.Top := TOP_FILA_TOTALES;
      end;
    end;
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
  AjustarFormatoHorizontalTallas(frxrprt1);
end;

procedure TfrmPrint.ReportBeforePrintConQR(Component: TfrxReportComponent);
begin
  FotosArticulos.HandlerReportBeforePrint(Component);
  // Objetos que SÍ reciben el evento (QR/título en una banda de datos)
  SustituirQRVerifactuEnReport(ParametrosApp, Component);
  SustituirTituloFacturaEnReport(Component);
  // Vía fiable: al disparar la banda (la cabecera de página recibe el
  // evento aunque sus objetos sueltos no), rellenamos QR y título de
  // sus hijos con la factura activa
  AplicarVerifactuEnBanda(ParametrosApp, Component);
end;

procedure TfrmPrint.AbrirGuiasRuntime(
  aSoloUsadasEnReport: Boolean);
var
  arrGuias: TArray<TInformeGuiaItem>;
  sFormatoBuscado: string;
  sError: string;
  iGuia: Integer;
  iDataSet: Integer;
  oDataSetInforme: TfrxDBDataset;
  oDataSet: TDataSet;
  oRestauracion: IRestauracionDatasetInforme;
begin
  if not Assigned(FRestauracionesGuias) then
  begin
    FRestauracionesGuias := TInterfaceList.Create;
  end;
  CerrarGuiasRuntime;
  if Assigned(InformesGuiasCache) and
     InformesGuiasCache.Cargada then
  begin
    if (sElegido = '') or
       SameText(sElegido, 'Predeterminado') then
    begin
      sFormatoBuscado := '';
    end
    else
    begin
      sFormatoBuscado := sElegido;
    end;
    arrGuias := InformesGuiasCache.Obtener(
      Self.Name,
      sFormatoBuscado);
    for iGuia := 0 to High(arrGuias) do
    begin
      oDataSetInforme := nil;
      for iDataSet := 0 to frxrprt1.Datasets.Count - 1 do
      begin
        if (frxrprt1.Datasets[iDataSet].DataSet is TfrxDBDataset) and
           SameText(
             frxrprt1.Datasets[iDataSet].DataSet.UserName,
             arrGuias[iGuia].DatasetMaster) then
        begin
          oDataSetInforme := TfrxDBDataset(
            frxrprt1.Datasets[iDataSet].DataSet);
        end;
      end;
      if not Assigned(oDataSetInforme) then
      begin
        RegistroLog.RegistrarAviso(
          Format(
            'Guia ignorada: master "%s" no esta en el report de %s',
            [arrGuias[iGuia].DatasetMaster, Self.Name]));
      end
      else
      begin
        oDataSet := oDataSetInforme.DataSet;
        if not Assigned(oDataSet) and
           Assigned(oDataSetInforme.DataSource) then
        begin
          oDataSet := oDataSetInforme.DataSource.DataSet;
        end;
        if oDataSet is TClientDataSet then
        begin
          oDataSet := RelacionarClientDataSetConQuery(oDataSet);
        end;
        oRestauracion := FServiciosPersistencia.Enriquecedor.Enriquecer(
          oDataSet,
          arrGuias[iGuia],
          sError);
        if Assigned(oRestauracion) then
        begin
          FRestauracionesGuias.Add(oRestauracion);
          oDataSetInforme.FieldAliases.Clear;
          if Assigned(oDataSetInforme.DataSource) then
          begin
            var oOrigen := oDataSetInforme.DataSource;
            oDataSetInforme.DataSource := nil;
            oDataSetInforme.DataSource := oOrigen;
          end
          else if Assigned(oDataSetInforme.DataSet) then
          begin
            var oOrigenDatos := oDataSetInforme.DataSet;
            oDataSetInforme.DataSet := nil;
            oDataSetInforme.DataSet := oOrigenDatos;
          end;
        end
        else
        begin
          RegistroLog.RegistrarAviso(
            Format(
              'Guia ignorada (%s -> %s): %s',
              [
                arrGuias[iGuia].DatasetMaster,
                arrGuias[iGuia].Tabla,
                sError
              ]));
        end;
      end;
    end;
  end;
end;

procedure TfrmPrint.CerrarGuiasRuntime;
var
  iRestauracion: Integer;
  oRestauracion: IRestauracionDatasetInforme;
begin
  if Assigned(FRestauracionesGuias) then
  begin
    for iRestauracion := FRestauracionesGuias.Count - 1 downto 0 do
    begin
      oRestauracion := IRestauracionDatasetInforme(
        FRestauracionesGuias[iRestauracion]);
      try
        oRestauracion.Restaurar;
      except
        on E: Exception do
        begin
          RegistroLog.RegistrarError(
            'Restaurar dataset del informe fallo: ' + E.Message);
        end;
      end;
    end;
    FRestauracionesGuias.Clear;
  end;
end;
procedure TfrmPrint.ConsolidarGuiasParaFormato(
  const aFormato: string);
var
  oMemoria: TMemoryStream;
  oTexto: TStringList;
begin
  if (aFormato <> '') and
     not SameText(aFormato, 'Predeterminado') then
  begin
    oMemoria := TMemoryStream.Create;
    oTexto := TStringList.Create;
    try
      frxrprt1.SaveToStream(oMemoria);
      oMemoria.Position := 0;
      oTexto.LoadFromStream(oMemoria);
      FServiciosPersistencia.Guias.Consolidar(
        Self.Name,
        aFormato,
        IdentidadSesion.Usuario,
        oTexto.Text);
    finally
      FreeAndNil(oTexto);
      FreeAndNil(oMemoria);
    end;
    if Assigned(InformesGuiasCache) then
    begin
      InformesGuiasCache.Precargar;
    end;
  end;
end;
procedure TfrmPrint.EditarGuiasParaFormato(const aFormato: string;
                                            aReport: TfrxReport = nil);
var
  oForm: TfrmModalInformesGuias;
begin
  oForm := TfrmModalInformesGuias.Create(
    Self,
    FiltrosGuias);
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

  // El diseñador parte siempre de la consulta de diseño del data module.
  // Preparar_consulta necesita parámetros que pueden no estar informados.

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
  if iRespuesta <> mrCancel then
  begin
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
  arrFormatos: TFormatosImpresion;
  iFormato: Integer;
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
    arrFormatos := FServiciosPersistencia.Formatos.Listar(
      ContextoFormatos);
    for iFormato := 0 to High(arrFormatos) do
    begin
      form.lstFormatos.AddItem(
        arrFormatos[iFormato].Descripcion,
        nil);
    end;
    if form.lstFormatos.Count > 0 then
    begin
      form.lstFormatos.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmPrint.PrepararSelectorFormato(
  ASelector: TfrmMtoModalGenImpEle;
  const AFormatoPredeterminado: string);
var
  Indice: Integer;
begin
  CargarFormatos(ASelector);
  if AFormatoPredeterminado <> '' then
  begin
    ASelector.chkPredeterminado.Checked := True;
    if AFormatoPredeterminado <> 'Predeterminado' then
    begin
      for Indice := 0 to ASelector.lstFormatos.Count - 1 do
      begin
        if ASelector.lstFormatos.Items[Indice] =
           AFormatoPredeterminado then
        begin
          ASelector.lstFormatos.ItemIndex := Indice;
          Break;
        end;
      end;
    end;
  end;
  if ASelector.lstFormatos.Count > 0 then
    ASelector.ShowModal
  else
    ASelector.sFicha := 'O';
end;

procedure TfrmPrint.EliminarFormatoPredeterminado;
begin
  PerfilesEscritura.EliminarPerfil(
    IdentidadSesion.Usuario, Self.Name + '_default');
  PerfilesEscritura.EliminarPerfil(
    IdentidadSesion.Grupo, Self.Name + '_default');
  PerfilesEscritura.EliminarPerfil(oAll, Self.Name + '_default');
end;

procedure TfrmPrint.GuardarFormatoPredeterminado(
  const AFormato: string);
var
  Formulario: TfrmModalGenImpSave;
  Permisos: string;
begin
  Formulario := TfrmModalGenImpSave.Create(Self);
  try
    Formulario.edtNombreOrigen.Text := Self.Name;
    Formulario.edtDescripcion.Text := 'Predet: ' + AFormato;
    Formulario.edtDescripcion.Enabled := False;
    Formulario.ShowModal;
    if Formulario.sFicha = 'S' then
    begin
      Permisos := Formulario.cbbPermisos.Text;
      EliminarFormatoPredeterminado;
      PerfilesEscritura.GrabarPerfil(
        Permisos,
        Self.Name + '_default',
        AFormato,
        AFormato);
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmPrint.ActualizarFormatoPredeterminado(
  ASelector: TfrmMtoModalGenImpEle;
  const AFormatoAnterior: string);
begin
  if (ASelector.sFicha = 'S') or (ASelector.sFicha = 'O') then
  begin
    if ASelector.bPredeterminado then
    begin
      if sElegido <> AFormatoAnterior then
        GuardarFormatoPredeterminado(sElegido);
    end
    else if AFormatoAnterior <> '' then
      EliminarFormatoPredeterminado;
  end;
end;

procedure TfrmPrint.SeleccionarFormato(
  const AFormatoPredeterminado: string;
  out AAccion: string);
var
  Selector: TfrmMtoModalGenImpEle;
begin
  Selector := TfrmMtoModalGenImpEle.Create(Self, Self);
  try
    PrepararSelectorFormato(Selector, AFormatoPredeterminado);
    sElegido := Selector.sElegido;
    AAccion := Selector.sFicha;
    ActualizarFormatoPredeterminado(
      Selector, AFormatoPredeterminado);
  finally
    FreeAndNil(Selector);
  end;
end;

procedure TfrmPrint.CargarFormatoElegido(const AAccion: string);
var
  Flujo: TMemoryStream;
begin
  if AAccion = 'S' then
  begin
    Flujo := TMemoryStream.Create;
    try
      if LeerBlobFormato(sElegido, Flujo) then
      begin
        frxrprt1.LoadFromStream(Flujo);
        FInformeEsPersonalizado := True;
      end
      else
      begin
        frxrprt1.AssignAll(frxReportOrigen);
        FInformeEsPersonalizado := False;
      end;
      FInformeTraducido := False;
    finally
      FreeAndNil(Flujo);
    end;
  end
  else if AAccion = 'O' then
  begin
    frxrprt1.AssignAll(frxReportOrigen);
    FInformeEsPersonalizado := False;
    FInformeTraducido := False;
  end;
end;

procedure TfrmPrint.Consultar_Formularios(bForzarSeleccion: Boolean = False);
var
  sFichaAccion: string;
  sDefaultSubKey: string;
begin
    sElegido := '';
    sFichaAccion := '';
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
      SeleccionarFormato(sDefaultSubKey, sFichaAccion);
    CargarFormatoElegido(sFichaAccion);
end;

procedure TfrmPrint.DeleteForm(
  sElegido: String;
  form: TfrmMtoModalGenImpEle);
var
  sPropietario: string;
  iBotonSeleccionado: Integer;
begin
  sPropietario := FServiciosPersistencia.Formatos.ObtenerPropietario(
    Self.Name,
    sElegido);
  if not (
    (IdentidadSesion.GrupoRaiz = 'S') or
    (IdentidadSesion.Usuario = sPropietario) or
    (IdentidadSesion.Grupo = sPropietario)
  ) then
  begin
    ShowMessageFmt(
      SErrorPrivilegiosBorrarFormato,
      [sPropietario]);
  end
  else
  begin
    iBotonSeleccionado := MessageDlg(
      SPreguntaBorrarFormato,
      mtCustom,
      [mbYes, mbNo],
      0);
    if iBotonSeleccionado = mrYes then
    begin
      FServiciosPersistencia.Formatos.Eliminar(
        Self.Name,
        sElegido);
      if Assigned(CachePerfiles) then
      begin
        CachePerfiles.ResincronizarPerfilFormulario(Self.Name);
      end;
    end;
    CargarFormatos(form);
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
  CerrarGuiasRuntime;
  FreeAndNil(FRestauracionesGuias);
end;

function TfrmPrint.ContextoFormatos: TContextoFormatosImpresion;
begin
  Result.Informe := Self.Name;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.Grupo := IdentidadSesion.Grupo;
  Result.Todos := oAll;
end;

function TfrmPrint.LeerBlobFormato(
  const aDescripcion: string;
  aStream: TStream
): Boolean;
begin
  Result := FServiciosPersistencia.Formatos.Leer(
    ContextoFormatos,
    aDescripcion,
    aStream);
end;

procedure TfrmPrint.GuardarBlobFormato(
  const aUsuario, aSubKey, aDescripcion: string;
  aStream: TStream;
  aInsertar: Boolean);
var
  Solicitud: TSolicitudGuardarFormato;
begin
  Solicitud.Contexto := ContextoFormatos;
  Solicitud.UsuarioGrupo := aUsuario;
  Solicitud.Subclave := aSubKey;
  Solicitud.Descripcion := aDescripcion;
  Solicitud.Insertar := aInsertar;
  FServiciosPersistencia.Formatos.Guardar(
    Solicitud,
    aStream);
end;
procedure TfrmPrint.TraducirInformeActual;
begin
  if not FInformeTraducido then
  begin
    if TraducirContenidoInforme then
    begin
      TraducirInformeFastReport(
        frxrprt1,
        Self,
        Traducciones,
        FInformeEsPersonalizado);
    end;
    FInformeTraducido := True;
  end;
end;

function TfrmPrint.TraducirContenidoInforme: Boolean;
begin
  Result := True;
end;

procedure TfrmPrint.FormCreate(Sender: TObject);
var
  oContexto: TContextoImpresionVentasPantalla;
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
  CrearContextoVentasPantalla(
    ConexionPrincipal,
    oContexto);
  FServiciosPersistencia := oContexto.Persistencia;
  FRestauracionesGuias := TInterfaceList.Create;
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
      bExiste := FServiciosPersistencia.Formatos.Existe(
        ContextoFormatos,
        sDescripcion);
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
        // El repositorio decide entre alta y actualización.
        GuardarBlobFormato(sPermisos,
                           frxrprt1.Name + '_' + sDescripcion,
                           sDescripcion,
                           memStream,
                           not bExiste);
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
            RegistroLog.RegistrarError(
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
