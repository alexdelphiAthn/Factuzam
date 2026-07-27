{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDocumentosTrabajo                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de Documentos de Trabajo.                                   }
{******************************************************************************}
unit inMtoDocumentosTrabajo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoGen, dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls,
  cxSplitter, cxCurrencyEdit, cxCalendar, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, cxListView, cxMaskEdit,
  cxDropDownEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, UniDataDocumentosTrabajo,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridTallasInline;

type
  TfrmMtoDocumentosTrabajo = class(TfrmMtoGen)
    pcAmbitoDTR: TcxPageControl;
    tsAmbitoPropiosDTR: TcxTabSheet;
    tsAmbitoCompartidosDTR: TcxTabSheet;
    colDtrId: TcxGridDBColumn;
    colDtrTitulo: TcxGridDBColumn;
    colDtrTipo: TcxGridDBColumn;
    colDtrEstado: TcxGridDBColumn;
    colDtrUsuario: TcxGridDBColumn;
    colDtrInstante: TcxGridDBColumn;
    colDtrEmpresa: TcxGridDBColumn;
    colDtrAlmacen: TcxGridDBColumn;
    splLineasDTR: TcxSplitter;
    pnlLineasDTR: TPanel;
    pnlAccionesDTR: TPanel;
    lblLineasDTR: TcxLabel;
    btnListadoDTR: TcxButton;
    btnCargarFiltrosDTR: TcxButton;
    btnCompartirDTR: TcxButton;
    btnImprimirEtiquetasDTR: TcxButton;
    pcDetalleDTR: TcxPageControl;
    tsLineasDTR: TcxTabSheet;
    tsCompartirDTR: TcxTabSheet;
    cxgrdLineasDTR: TcxGrid;
    tvLineasDTR: TcxGridDBTableView;
    colDtlLinea: TcxGridDBColumn;
    colDtlArticulo: TcxGridDBColumn;
    colDtlSku: TcxGridDBColumn;
    colDtlAlmacen: TcxGridDBColumn;
    colDtlDescripcionArticulo: TcxGridDBColumn;
    colDtlModelo: TcxGridDBColumn;
    colDtlFamilia: TcxGridDBColumn;
    colDtlProveedor: TcxGridDBColumn;
    colDtlTemporada: TcxGridDBColumn;
    colDtlDescripcionSku: TcxGridDBColumn;
    colDtlCantidadStock: TcxGridDBColumn;
    colDtlCantidad: TcxGridDBColumn;
    colDtlOrigen: TcxGridDBColumn;
    colDtlInstanteStock: TcxGridDBColumn;
    glLineasDTR: TcxGridLevel;
    cxgrdCompartidosDTR: TcxGrid;
    tvCompartidosDTR: TcxGridDBTableView;
    colDtcTipoDestino: TcxGridDBColumn;
    colDtcUsuarioGrupo: TcxGridDBColumn;
    colDtcPermiso: TcxGridDBColumn;
    colDtcAlta: TcxGridDBColumn;
    glCompartidosDTR: TcxGridLevel;
    btnEnviarADTR: TcxButton;
    pmEnviarDTR: TPopupMenu;
    miEnviarAlbaranDTR: TMenuItem;
    miEnviarTpvDTR: TMenuItem;
    miEnviarInventarioDTR: TMenuItem;
    miEnviarTarifasDTR: TMenuItem;
    procedure btnEnviarADTRClick(Sender: TObject);
    procedure miEnviarAlbaranDTRClick(Sender: TObject);
    procedure miEnviarTpvDTRClick(Sender: TObject);
    procedure miEnviarInventarioDTRClick(Sender: TObject);
    procedure miEnviarTarifasDTRClick(Sender: TObject);
    procedure btnListadoDTRClick(Sender: TObject);
    procedure btnCargarFiltrosDTRClick(Sender: TObject);
    procedure btnCompartirDTRClick(Sender: TObject);
    procedure btnImprimirEtiquetasDTRClick(Sender: TObject);
    procedure pcAmbitoDTRChange(Sender: TObject);
  private
    FIdEtiquetasDTR: Int64;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal. El
    // Construir hace ClearItems: las columnas del dfm mueren y las
    // propias se recrean en runtime (patron de inMtoInventarios).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostDTR;
    procedure MostrarColumnasAtributoGlobalesDTR;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure GridLineasEnterDTR(Sender: TObject);
    // "Enviar a...": comprueba documento grabado con lineas y deja los
    // posts hechos; devuelve el ID_DTR o 0 si no procede.
    function PrepararEnvio: Int64;
    procedure AplicarEstadoAmbito;
    procedure CargarAlmacenesEtiquetasDTR(ALV: TcxListView);
    procedure CrearDataSetEtiquetasDTR(ADmArt: TObject;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmDocumentosTrabajo: TdmDocumentosTrabajo;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoDocumentosTrabajo: TfrmMtoDocumentosTrabajo;

implementation

uses
  Uni, UniDataArticulos, inLibFotos, inLibGenBusq, inMtoModalEtiqArt,
  inMtoModalAddBlockDocumentoTrabajo,
  // Factoria del contrato + IdentidadSesion.Usuario para el gestor de tallas.
  inLibColumnasSku,
  // Modal de destino (almacen/serie/numero) del "Enviar a...".
  inMtoModalEnviarDestino,
  // Venta TPV abierta (frmMtoOpeCaja) para el volcado de SKUs.
  inMtoCajaOpe,
  // Listado del documento con una foto de 300 x 300 por línea.
  inMtoPreviewExcel, inLibDocumentosTrabajoExcel, inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoDocumentosTrabajo.CrearTablaPrincipal;
begin
  inherited;
  dmmDocumentosTrabajo := tdmDataModule as TdmDocumentosTrabajo;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsTablaG.DataSet := dmmDocumentosTrabajo.unqryTablaG;
    tvLineasDTR.DataController.DataSource := dmmDocumentosTrabajo.dsLineas;
    tvCompartidosDTR.DataController.DataSource :=
      dmmDocumentosTrabajo.dsCompartidos;
    AplicarEstadoAmbito;
  end;
  pkFieldName := 'ID_DTR';
  // Contrato de entrada: Auto por defecto; se construye al entrar en
  // el grid de lineas (las lineas abren en detail del master).
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  cxgrdLineasDTR.OnEnter := GridLineasEnterDTR;
  btnListadoDTR.Visible := PuedeExportar;
end;

procedure TfrmMtoDocumentosTrabajo.GridLineasEnterDTR(Sender: TObject);
begin
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if (FModoEntrada <> nil) and
     (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.Ambito = dtaPropios) then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoDocumentosTrabajo.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
  // lineas a la vista.
  if (Key = VK_F1) and (Shift = []) and
     (pcDetalleDTR.ActivePage = tsLineasDTR) then
  begin
    Key := 0;
    case FModoEntradaSel of
      mcsAuto: FModoEntradaSel := mcsSku;
      mcsSku: FModoEntradaSel := mcsTallasInline;
    else
      FModoEntradaSel := mcsAuto;
    end;
    ConstruirModoEntrada;
  end;
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  i: Integer;
  ds: TDataSet;
begin
  if (dmmDocumentosTrabajo = nil) or
     (csDestroying in ComponentState) then
    Exit;
  ds := dmmDocumentosTrabajo.unqryLineas;
  if not ds.Active then
    Exit;
  // Teardown del modo anterior (patron inventarios).
  if tvLineasDTR.Controller.EditingController.IsEditing then
    try
      tvLineasDTR.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        ;
    end;
  if ds.State in [dsEdit, dsInsert] then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
  tvLineasDTR.OnInitEdit := nil;
  tvLineasDTR.OnEditKeyDown := nil;
  tvLineasDTR.OnEditing := nil;
  tvLineasDTR.OnFocusedRecordChanged := nil;
  tvLineasDTR.OnFocusedItemChanged := nil;
  // Las columnas del modo saliente guardan handlers (OnGetProperties,
  // OnCustomDrawCell...) del objeto que se libera en la linea de abajo:
  // se eliminan ANTES de soltarlo para que ningun repintado llame a un
  // modo muerto (mismo AV que pedidos, 07/07/2026).
  tvLineasDTR.ClearItems;
  FModoEntrada := nil;
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _DTL; idempotente por linea).
  if FModoEntradaSel <> mcsSku then
    dmmDocumentosTrabajo.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.Conexion := dmmDocumentosTrabajo.unqryTablaG.Connection;
  Cfg.ContextoSesion := ContextoSesion;
  Cfg.View := tvLineasDTR;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock :=
    dsTablaG.DataSet.FieldByName('CODIGO_ALM_DTR').AsString;
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_DTL';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_DTL';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_DTL';
  Cfg.Campos.Cantidad := 'CANTIDAD_DTL';
  Cfg.Campos.Almacen := 'CODIGO_ALM_DTL';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_DTL';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_DTL';
    Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE_DTL';
  end;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasDTR;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmDocumentosTrabajo.dsLineas;
    // Clave SIMPLE del documento: ID_DTR hace de "serie" y el par
    // NUMERO queda vacio (soporte de numero opcional del gestor).
    CfgT.FieldSerieMaster := 'ID_DTR';
    CfgT.FieldNumeroMaster := '';
    CfgT.FieldLinea := 'LINEA_DTL';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_DTL';
    // Sin precio por linea: solo total de unidades (CANTIDAD_DTL).
    CfgT.FieldPrecioBase := '';
    CfgT.FieldTotalUds := 'CANTIDAD_DTL';
    CfgT.FieldTotalLinea := '';
    CfgT.TablaCeldas := 'fza_documentos_trabajo_celdas';
    CfgT.FieldSerieCel := 'ID_DTR_DTRCEL';
    CfgT.FieldNumeroCel := '';
    CfgT.FieldLineaCel := 'LINEA_DTRCEL';
    CfgT.FieldFilaCel := 'ID_FILA_DTRCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_DTRCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_DTRCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := 20;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  FModoEntrada.OnResuelto := ModoEntradaResuelto;
  FModoEntrada.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FModoEntrada.OnSalirEdicion := RestaurarEnterAsTabTemporal;
  // El flag ANTES del Construir: si aborta a medias, nadie debe tocar
  // las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  FModoEntrada.Construir;
  CrearColumnasHostDTR;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasDTR.Caption := 'Líneas [SKU]';
    mcsTallasInline: tsLineasDTR.Caption := 'Líneas [Tallas horiz.]';
  else
    begin
      tsLineasDTR.Caption := 'Líneas [Desglose]';
      MostrarColumnasAtributoGlobalesDTR;
    end;
  end;
  // El guardian de ambito (solo propietario edita) se conserva.
  AplicarEstadoAmbito;
end;

procedure TfrmMtoDocumentosTrabajo.CrearColumnasHostDTR;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasDTR.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
begin
  // Columnas propias del documento tras el ClearItems del contrato.
  Col('Almacén', 'CODIGO_ALM_DTL', 70, True);
  Col('Descripción', 'DESCRIPCION_ARTICULO_DTL', 200, False);
  Col('Modelo', 'REF_PROVEEDOR', 120, False);
  Col('Familia', 'DESCRIPCION_FAM', 160, False);
  Col('Proveedor', 'NOMBRE_PRV', 180, False);
  Col('Temporada', 'TEMPORADA_ART', 110, False);
  with Col('Stock', 'CANTIDAD_STOCK_DTL', 80, False) do
    HeaderAlignmentHorz := taRightJustify;
  with Col('Cantidad', 'CANTIDAD_DTL', 80,
           FModoEntradaSel <> mcsTallasInline) do
    HeaderAlignmentHorz := taRightJustify;
  Col('Origen', 'ORIGEN_DTL', 80, False);
  Col('Instante stock', 'INSTANTE_STOCK_DTL', 120, False);
end;

procedure TfrmMtoDocumentosTrabajo.MostrarColumnasAtributoGlobalesDTR;
var
  Qry: TUniQuery;
  i, iOrden: Integer;
  Col: TcxGridColumn;
begin
  // Nombres globales de atributos para ver Color/Talla desde el
  // principio (mismo helper que inventarios / banco de pruebas).
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
    Qry.SQL.Text :=
      'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
      '       MIN(ORDEN_VA) AS ORDEN' +
      '  FROM fza_variaciones_atributos' +
      ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
      ' ORDER BY ORDEN, NOMBRE LIMIT 5';
    Qry.Open;
    iOrden := 1;
    while (not Qry.Eof) and (iOrden <= 5) do
    begin
      for i := 0 to tvLineasDTR.ColumnCount - 1 do
      begin
        Col := tvLineasDTR.Columns[i];
        if Col.Tag = iOrden then
        begin
          Col.Caption := Qry.FieldByName('NOMBRE').AsString;
          Col.Visible := True;
        end;
      end;
      Inc(iOrden);
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ModoEntradaResuelto(const ACodArt,
  ASku, ADescripcion: string; ACompleto: Boolean);
begin
  // El BeforePost del data module rellena LINEA e INSTANTE_STOCK; la
  // cantidad por defecto de una lectura es 1 si venia a 0.
  if ACompleto and
     (dmmDocumentosTrabajo.unqryLineas.State in [dsEdit, dsInsert]) and
     (dmmDocumentosTrabajo.unqryLineas.FieldByName(
        'CANTIDAD_DTL').AsFloat = 0) and
     (FModoEntradaSel <> mcsTallasInline) then
    dmmDocumentosTrabajo.unqryLineas.FieldByName(
      'CANTIDAD_DTL').AsFloat := 1;
end;

procedure TfrmMtoDocumentosTrabajo.AplicarEstadoAmbito;
var
  bPropios: Boolean;
begin
  bPropios := True;
  if dmmDocumentosTrabajo <> nil then
  begin
    bPropios := dmmDocumentosTrabajo.Ambito = dtaPropios;
  end;
  cxGrdDBTabPrin.OptionsData.Editing := bPropios;
  tvLineasDTR.OptionsData.Editing := bPropios;
  tvCompartidosDTR.OptionsData.Editing := bPropios;
  btnCargarFiltrosDTR.Enabled := bPropios;
  btnCompartirDTR.Enabled := bPropios;
end;

procedure TfrmMtoDocumentosTrabajo.CargarAlmacenesEtiquetasDTR(
  ALV: TcxListView);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(FIdEtiquetasDTR, ALV);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearDataSetEtiquetasDTR(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt,
                                                  FIdEtiquetasDTR,
                                                  ACodTarifa,
                                                  AAlmacenesCsv,
                                                  AFecha);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnListadoDTRClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  dsCabecera: TDataSet;
  sId: string;
  sTitulo: string;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsCabecera := dmmDocumentosTrabajo.unqryTablaG;
    if (not dsCabecera.Active) or dsCabecera.IsEmpty then
    begin
      ShowMessage(
        'Seleccione un Documento de Trabajo antes de sacar el listado.');
    end
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dsCabecera.State in dsEditModes then
      begin
        dsCabecera.Post;
      end;
      if dsCabecera.FieldByName('ID_DTR').IsNull then
      begin
        ShowMessage(
          'Grabe el Documento de Trabajo antes de sacar el listado.');
      end
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
      begin
        ShowMessage(
          'El Documento de Trabajo no tiene líneas para el listado.');
      end
      else
      begin
        sId := dsCabecera.FieldByName('ID_DTR').AsString;
        sTitulo := Copy(dsCabecera.FieldByName('TITULO_DTR').AsString,
                        1, 60);
        fPreview := TfrmMtoPreviewExcel.Create(Self);
        try
          fPreview.PopupParent := Self;
          fPreview.DialogoGuardar.InitialDir :=
            ParametrosApp.GetPath('appDirExcel');
          fPreview.DialogoGuardar.FileName := SanitizeFileName(
            'Documento_trabajo_' + sId + '_' + sTitulo);
          Screen.Cursor := crHourGlass;
          try
            ExportarDocumentoTrabajoExcel(
              fPreview.dxSpreadSheet1,
              dsCabecera,
              dmmDocumentosTrabajo.unqryLineas);
          finally
            Screen.Cursor := crDefault;
          end;
          fPreview.ShowModal;
        finally
          FreeAndNil(fPreview);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCargarFiltrosDTRClick(Sender: TObject);
var
  ds: TDataSet;
  res: TAddBlockDocumentoTrabajoResult;
  sAlmacen: string;
  sTitulo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
    begin
      ShowMessage('Seleccione un Documento de Trabajo antes de cargar.');
    end
    else if dmmDocumentosTrabajo.Ambito <> dtaPropios then
    begin
      ShowMessage(
        'Solo el propietario puede cargar articulos en el documento.');
    end
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if ds.State in dsEditModes then
      begin
        ds.Post;
      end;
      if ds.FieldByName('ID_DTR').IsNull then
      begin
        ShowMessage('Grabe el Documento de Trabajo antes de cargar.');
      end
      else
      begin
        sAlmacen := ds.FieldByName('CODIGO_ALM_DTR').AsString;
        sTitulo := ds.FieldByName('TITULO_DTR').AsString;
        res := TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
          Self,
          dmmDocumentosTrabajo.unqryTablaG.Connection,
          ds.FieldByName('ID_DTR').AsLargeInt,
          sAlmacen,
          sTitulo);
        if res.Aceptado then
        begin
          pcDetalleDTR.ActivePage := tsLineasDTR;
          if dmmDocumentosTrabajo.unqryLineas.Active then
          begin
            dmmDocumentosTrabajo.unqryLineas.Close;
          end;
          dmmDocumentosTrabajo.unqryLineas.Open;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCompartirDTRClick(Sender: TObject);
var
  q: TUniQuery;
  sDestino: string;
  sTipo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (not dmmDocumentosTrabajo.unqryTablaG.Active) or
       (dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      ShowMessage('Seleccione un Documento de Trabajo antes de compartir.');
    end
    else
    begin
      q := TUniQuery.Create(nil);
      try
        q.SQL.Text :=
          'SELECT ''USUARIO'' AS TIPO, ' +
          '       USUARIO_USU AS DESTINO ' +
          '  FROM fza_usuarios ' +
          ' WHERE COALESCE(ESACTIVO_USU, ''S'') = ''S'' ' +
          ' UNION ALL ' +
          'SELECT ''GRUPO'' AS TIPO, ' +
          '       GRUPO_USUGRP AS DESTINO ' +
          '  FROM fza_usuarios_grupos ' +
          ' ORDER BY TIPO, DESTINO';
        if TBusquedaUtils.EjecutarBusqueda(
          ConexionPrincipal,
          'Compartir Documento de Trabajo',
                                           q,
                                           'frmBuscarCompartirDTR',
                                           Self) then
        begin
          sTipo := q.FieldByName('TIPO').AsString;
          sDestino := q.FieldByName('DESTINO').AsString;
          if dmmDocumentosTrabajo.CompartirDocumentoActual(sDestino,
                                                           sTipo) then
          begin
            ShowMessage('Documento compartido.');
          end
          else
          begin
            ShowMessage('El Documento de Trabajo ya estaba compartido.');
          end;
          pcDetalleDTR.ActivePage := tsCompartirDTR;
        end;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnImprimirEtiquetasDTRClick(
  Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
  dmArt: TdmArticulos;
  sTitulo: string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (dmmDocumentosTrabajo.unqryTablaG.Active) and
       (not dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dmmDocumentosTrabajo.unqryTablaG.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryTablaG.Post;
      end;
      if not dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').IsNull then
      begin
        FIdEtiquetasDTR := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'ID_DTR').AsLargeInt;
        sTitulo := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'TITULO_DTR').AsString;
        dmArt := TdmArticulos.Create(nil);
        try
          formulario := TfrmPrintEtiqArt.Create(Application);
          try
            formulario.DM := dmArt;
            formulario.Caption :=
              'Impresion de Etiquetas de Documento de Trabajo';
            formulario.TextoOrigenExterno := sTitulo;
            formulario.CargarAlmacenesExterno := CargarAlmacenesEtiquetasDTR;
            formulario.CrearDataSetExterno := CrearDataSetEtiquetasDTR;
            formulario.ShowModal;
          finally
            FreeAndNil(formulario);
          end;
        finally
          FreeAndNil(dmArt);
        end;
      end
      else
      begin
        ShowMessage(
          'Grabe el Documento de Trabajo antes de imprimir etiquetas.');
      end;
    end
    else
    begin
      ShowMessage(
        'Seleccione un Documento de Trabajo antes de imprimir etiquetas.');
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.PrepararEnvio: Int64;
var
  ds: TDataSet;
begin
  Result := 0;
  if dmmDocumentosTrabajo <> nil then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
      ShowMessage('Seleccione un Documento de Trabajo antes de enviar.')
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
        dmmDocumentosTrabajo.unqryLineas.Post;
      if ds.State in dsEditModes then
        ds.Post;
      if ds.FieldByName('ID_DTR').IsNull then
        ShowMessage('Grabe el Documento de Trabajo antes de enviar.')
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
        ShowMessage('El Documento de Trabajo no tiene lineas que enviar.')
      else
        Result := ds.FieldByName('ID_DTR').AsLargeInt;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnEnviarADTRClick(Sender: TObject);
var
  pt: TPoint;
begin
  // El area principal del boton tambien despliega el menu.
  pt := btnEnviarADTR.ClientToScreen(Point(0, btnEnviarADTR.Height));
  pmEnviarDTR.Popup(pt.X, pt.Y);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarAlbaranDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  q: TUniQuery;
  sp: TUniStoredProc;
  ds: TDataSet;
  sEmp, sAlm, sSerie, sNumero: string;
begin
  idDtr := PrepararEnvio;
  if idDtr <= 0 then
    Exit;
  ds := dmmDocumentosTrabajo.unqryTablaG;
  sEmp := ds.FieldByName('CODIGO_EMP_DTR').AsString;
  sAlm := ds.FieldByName('CODIGO_ALM_DTR').AsString;
  sSerie := '';
  sNumero := '0';
  if not TfrmModalEnviarDestino.Ejecutar(Self,
           dmmDocumentosTrabajo.unqryTablaG.Connection,
           'Enviar a albarán de venta', sEmp, 'AV',
           sAlm, sSerie, sNumero) then
    Exit;
  // Numero '0' = contador oficial de albaranes de venta (tipo 'AV').
  if sNumero = '0' then
  begin
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
      sp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString, 'pserie', ptInput);
      sp.Params.CreateParam(ftString, 'ptipodoc', ptInput);
      sp.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
      sp.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
      sp.Params.CreateParam(ftString, 'pcont', ptOutput);
      sp.ParamByName('pserie').AsString := sSerie;
      sp.ParamByName('ptipodoc').AsString := 'AV';
      sp.ParamByName('pEMPRESA_CONTADOR').AsString := sEmp;
      sp.ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
      sp.ExecProc;
      sNumero := sp.ParamByName('pcont').AsString;
    finally
      FreeAndNil(sp);
    end;
    if (sNumero = '') or (sNumero = '0') then
    begin
      ShowMessage('El contador de albaranes no ha devuelto numero ' +
                  'para la serie ' + sSerie + '.');
      Exit;
    end;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
    // Cabecera minima ABIERTA: cliente, fiscalidad y precios se
    // completan en el Mto de albaranes.
    q.SQL.Text :=
      'INSERT INTO fza_albaranes ' +
      ' (NUMERO_ALB, SERIE_ALB, FECHA_ALB, ESTADO_ALB, ' +
      '  CODIGO_EMP_ALB, CODIGO_ALM_ALB, CONTADOR_LINEAS_ALB, ' +
      '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :NUMERO, :SERIE, CURDATE(), ''ABIERTO'', :EMP, :ALM, ' +
      '       LPAD(COUNT(*) * 10, 8, ''0''), NOW(), NOW(), :USU, :USU ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID';
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('SERIE').AsString := sSerie;
    q.ParamByName('EMP').AsString := sEmp;
    q.ParamByName('ALM').AsString := sAlm;
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    // Lineas numeradas a paso 10 (convencion de albaranes) con
    // cantidad del documento; precios a 0 para revisar en el Mto.
    q.SQL.Text :=
      'INSERT INTO fza_albaranes_lineas ' +
      ' (NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, ' +
      '  CODIGO_ART_ALBLIN, DESCRIPCION_ARTICULO_ALBLIN, ' +
      '  CANTIDAD_ALBLIN, CODIGO_ALMACEN_ALBLIN, ' +
      '  CODIGO_UNIDAD_ALBLIN, LOTE_ALBLIN, FECHA_CADUCIDAD_ALBLIN, ' +
      '  DESCRIPCION_VARIACION_ALBLIN, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :NUMERO, :SERIE, ' +
      '       LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
      '       CODIGO_ART_DTL, LEFT(DESCRIPCION_ARTICULO_DTL, 100), ' +
      '       CANTIDAD_DTL, :ALM, ' +
      '       CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
      '       FECHA_CADUCIDAD_DTL, DESCRIPCION_UNIDAD_DTL, ' +
      '       NOW(), :USU, :USU ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID';
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('SERIE').AsString := sSerie;
    q.ParamByName('ALM').AsString := sAlm;
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    ShowMessage(Format(
      'Albarán de venta %s/%s creado ABIERTO con %d líneas.%s' +
      'Asigna cliente, tarifa y precios en el Mto de albaranes.',
      [sSerie, sNumero, q.RowsAffected, sLineBreak]));
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTpvDTRClick(Sender: TObject);
var
  idDtr: Int64;
  ds: TDataSet;
  Bm: TBookmark;
  iOk, iMal: Integer;
begin
  idDtr := PrepararEnvio;
  if idDtr <= 0 then
    Exit;
  // La venta TPV debe estar ABIERTA: el volcado usa su propio flujo
  // de resolucion (precios/tarifa/IVA de la operacion en curso).
  if (frmMtoOpeCaja = nil) or (not frmMtoOpeCaja.Visible) then
  begin
    ShowMessage('La venta TPV no está abierta.' + sLineBreak +
                'Abre Caja > Ventas y repite "Enviar a... > Venta ' +
                'TPV" para volcar los SKUs en la operación en curso.');
    Exit;
  end;
  ds := dmmDocumentosTrabajo.unqryLineas;
  iOk := 0;
  iMal := 0;
  Bm := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      if frmMtoOpeCaja.CargarSkuExterno(
           ds.FieldByName('CODIGO_UNIDAD_DTL').AsString,
           ds.FieldByName('CANTIDAD_DTL').AsFloat) then
        Inc(iOk)
      else
        Inc(iMal);
      ds.Next;
    end;
    if ds.BookmarkValid(Bm) then
      ds.GotoBookmark(Bm);
  finally
    ds.EnableControls;
    ds.FreeBookmark(Bm);
  end;
  frmMtoOpeCaja.BringToFront;
  if iMal = 0 then
    ShowMessage(Format('%d líneas volcadas a la venta TPV.', [iOk]))
  else
    ShowMessage(Format(
      '%d líneas volcadas a la venta TPV; %d no se han podido ' +
      'resolver (artículo inexistente o descatalogado).',
      [iOk, iMal]));
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarInventarioDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  q: TUniQuery;
  sp: TUniStoredProc;
  ds: TDataSet;
  sEmp, sAlm, sSerie, sNumero: string;
begin
  idDtr := PrepararEnvio;
  if idDtr <= 0 then
    Exit;
  ds := dmmDocumentosTrabajo.unqryTablaG;
  sEmp := ds.FieldByName('CODIGO_EMP_DTR').AsString;
  sAlm := ds.FieldByName('CODIGO_ALM_DTR').AsString;
  sSerie := '';
  // '0' = numero pendiente: el contador del Mto de inventarios asigna
  // el definitivo al grabar la cabecera.
  sNumero := '0';
  if not TfrmModalEnviarDestino.Ejecutar(Self,
           dmmDocumentosTrabajo.unqryTablaG.Connection,
           'Enviar a inventario', sEmp, 'IN',
           sAlm, sSerie, sNumero) then
    Exit;
  // Numero '0' = pedirlo al contador oficial (mismo SP que usa el Mto
  // de inventarios al grabar: PRC_GET_NEXT_CONT_FACT_SERIE).
  if sNumero = '0' then
  begin
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
      sp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString, 'pserie', ptInput);
      sp.Params.CreateParam(ftString, 'ptipodoc', ptInput);
      sp.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
      sp.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
      sp.Params.CreateParam(ftString, 'pcont', ptOutput);
      sp.ParamByName('pserie').AsString := sSerie;
      sp.ParamByName('ptipodoc').AsString := 'IN';
      sp.ParamByName('pEMPRESA_CONTADOR').AsString := sEmp;
      sp.ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
      sp.ExecProc;
      sNumero := sp.ParamByName('pcont').AsString;
    finally
      FreeAndNil(sp);
    end;
    if (sNumero = '') or (sNumero = '0') then
    begin
      ShowMessage('El contador de inventarios no ha devuelto numero ' +
                  'para la serie ' + sSerie + '.');
      Exit;
    end;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
    // Cabecera del inventario, ABIERTO, con los datos del documento.
    q.SQL.Text :=
      'INSERT INTO fza_inventarios ' +
      ' (CODIGO_EMP_INV, CODIGO_ALM_INV, SERIE_INV, NUMERO_INV, ' +
      '  TIPO_DOC_INV, FECHA_INV, ESTADO_INV, DESCRIPCION_INV, ' +
      '  CONTADOR_LINEAS_INV, INSTANTE_ALTA, INSTANTE_MODIF, ' +
      '  USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :EMP, :ALM, :SERIE, :NUMERO, ''IN'', NOW(), ''ABIERTO'', ' +
      '       CONCAT(''Desde doc. trabajo '', :ID), ' +
      '       LPAD(COUNT(*), 8, ''0''), NOW(), NOW(), :USU, :USU ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID';
    q.ParamByName('EMP').AsString := sEmp;
    q.ParamByName('ALM').AsString := sAlm;
    q.ParamByName('SERIE').AsString := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    // Lineas: fisica = cantidad del documento; teorica = snapshot de
    // stock. El boton "Recalcular teorico/PMP" del Mto de inventarios
    // deja despues los teoricos y PMPs oficiales.
    q.SQL.Text :=
      'INSERT INTO fza_inventarios_lineas ' +
      ' (CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, ' +
      '  NUMERO_INV_INVLIN, LINEA_INVLIN, CODIGO_ART_INVLIN, ' +
      '  CODIGO_UNIDAD_INVLIN, LOTE_INVLIN, ' +
      '  DESCRIPCION_ARTICULO_INVLIN, CANTIDAD_TEORICA_INVLIN, ' +
      '  CANTIDAD_FISICA_INVLIN, CANTIDAD_DIFERENCIA_INVLIN, ' +
      '  PRECIO_MEDIO_INVLIN, PRECIO_MEDIO_NUEVO_INVLIN, ' +
      '  TOTAL_COSTE_DIFERENCIA_INVLIN, FECHA_RECUENTO_INVLIN, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      // LINEA_DTL ya es unica y ordenada dentro del documento: se
      // reutiliza tal cual como numero de linea del inventario (sin
      // ROW_NUMBER, que exige MariaDB >= 10.2).
      'SELECT :EMP, :ALM, :SERIE, :NUMERO, LINEA_DTL, ' +
      '       CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
      '       DESCRIPCION_ARTICULO_DTL, CANTIDAD_STOCK_DTL, ' +
      '       CANTIDAD_DTL, CANTIDAD_DTL - CANTIDAD_STOCK_DTL, ' +
      '       0, 0, 0, NOW(), NOW(), :USU, :USU ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID';
    q.ParamByName('EMP').AsString := sEmp;
    q.ParamByName('ALM').AsString := sAlm;
    q.ParamByName('SERIE').AsString := sSerie;
    q.ParamByName('NUMERO').AsString := sNumero;
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    ShowMessage(Format(
      'Inventario %s/%s creado en almacén %s con %d líneas del ' +
      'documento.%sAbre Inventarios y usa "Recalcular teórico/PMP" ' +
      'para fijar teóricos y costes.',
      [sSerie, sNumero, sAlm, q.RowsAffected, sLineBreak]));
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTarifasDTRClick(
  Sender: TObject);
var
  idDtr, idTarc: Int64;
  q: TUniQuery;
begin
  idDtr := PrepararEnvio;
  if idDtr <= 0 then
    Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := dmmDocumentosTrabajo.unqryTablaG.Connection;
    // Sesion de cambios de tarifa en BORRADOR sobre la tarifa por
    // defecto (la primera); origen/destino y regla se retocan en el
    // propio Mto de sesiones de tarifas.
    q.SQL.Text :=
      'INSERT INTO fza_tarifas_cambios ' +
      ' (NOMBRE_TARC, FECHA_TARC, ESTADO_TARC, ' +
      '  CODIGO_TAR_ORIGEN_TARC, CODIGO_TAR_DESTINO_TARC, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT CONCAT(''Desde doc. trabajo '', :ID), CURDATE(), ' +
      '       ''BORRADOR'', T.COD, T.COD, NOW(), :USU ' +
      '  FROM (SELECT MIN(CODIGO_TAR_TAR) AS COD ' +
      '          FROM fza_tarifas) T';
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    q.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    q.Open;
    idTarc := q.FieldByName('ID').AsLargeInt;
    q.Close;
    // Una linea por ARTICULO distinto del documento (el Mto de
    // sesiones rellena precios actuales y nuevos al preparar).
    q.SQL.Text :=
      'INSERT INTO fza_tarifas_cambios_lineas ' +
      ' (CODIGO_TARC_TARCLIN, CODIGO_ART_TARCLIN, ' +
      '  CODIGO_UNIDAD_SKU_TARCLIN, CODIGO_TAR_ORIGEN_TARCLIN, ' +
      '  CODIGO_TAR_DESTINO_TARCLIN, ESAPLICAR_TARCLIN, ' +
      '  ESTADO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'SELECT DISTINCT :TARC, L.CODIGO_ART_DTL, '''', ' +
      '       C.CODIGO_TAR_ORIGEN_TARC, C.CODIGO_TAR_DESTINO_TARC, ' +
      '       ''S'', ''PENDIENTE'', NOW(), :USU ' +
      '  FROM fza_documentos_trabajo_lineas L ' +
      '  JOIN fza_tarifas_cambios C ON C.CODIGO_TARC = :TARC ' +
      ' WHERE L.ID_DTR_DTL = :ID';
    q.ParamByName('TARC').AsLargeInt := idTarc;
    q.ParamByName('ID').AsLargeInt := idDtr;
    q.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    q.ExecSQL;
    ShowMessage(Format(
      'Sesión de cambio de tarifas %d creada en BORRADOR con los ' +
      'artículos del documento.%sAbre "Cambios de tarifa" para ' +
      'elegir tarifas, regla de cálculo y aplicar.',
      [idTarc, sLineBreak]));
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.pcAmbitoDTRChange(Sender: TObject);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    if pcAmbitoDTR.ActivePage = tsAmbitoCompartidosDTR then
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaCompartidos);
    end
    else
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaPropios);
    end;
    AplicarEstadoAmbito;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ResolverArtSkuActivo(out ACodArt,
  ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) and
     (dmmDocumentosTrabajo.dsLineas.DataSet <> nil) then
  begin
    inLibFotos.LeerArtSkuDeDataSet(dmmDocumentosTrabajo.dsLineas.DataSet,
                                   ACodArt, ACodSku);
  end;
  if ACodArt = '' then
  begin
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  end;
end;

function TfrmMtoDocumentosTrabajo.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) then
  begin
    Result := [dsTablaG, dmmDocumentosTrabajo.dsLineas];
  end
  else
  begin
    Result := inherited DataSourcesParaFoto;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoDocumentosTrabajo);
end.
