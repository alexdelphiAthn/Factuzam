{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColumnasDocumento                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Creación, visibilidad y captions comunes de las columnas visuales de     }
{    talla y atributo usadas por los documentos de compra, incluida la carga  }
{    de nombres de atributo y la configuración compartida del gestor y el     }
{    pivote de tallas, el desmontaje y construcción del modo, su configuración}
{    base, las columnas host, el pivote por bandas, los atributos globales,  }
{    los hooks de ciclo de vida, la navegación, el modo y la foto activa.   }
{******************************************************************************}
unit inLibColumnasDocumento;

interface

uses
  System.Classes, Vcl.Forms, Data.DB, Uni, cxEdit,
  cxGridCustomTableView, cxGridDBTableView, inLibContextoSesionIntf,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibGridPivoteCompra,
  inLibGridPivoteVenta, inLibAnfitrionDatosIntf;

type
  TConfigPivoteDocumentoCompra = record
    Conexion: TUniConnection;
    ContextoSesion: IContextoSesionAplicacion;
    Usuario: string;
    Vista: TcxGridDBTableView;
    SourceMaster: TDataSource;
    SourceLineas: TDataSource;
    ConsultaLineas: TUniQuery;
    ColumnasTallas: TArray<TcxGridDBColumn>;
    ColColorPivot: TcxGridDBColumn;
    ColColorProveedorPivot: TcxGridDBColumn;
    PrefijoCabecera: string;
    PrefijoLinea: string;
    PrefijoCelda: string;
    NombreTablaDocumento: string;
    AplicarContextoPivote: Boolean;
    TieneCantidadRecibida: Boolean;
    CampoColorTexto: string;
  end;

  TColumnasHostDocumentoCompra = record
    ColLinea: TcxGridDBColumn;
    ColCantidad: TcxGridDBColumn;
    ColTipoCantidad: TcxGridDBColumn;
    ColPrecioCompra: TcxGridDBColumn;
  end;

  TConjuntoModosColumnasSku = set of TModoColumnasSku;

  TAccionDocumento = procedure of object;

procedure CrearColumnasTallasDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  AAncho: Integer; var AColumnas: array of TcxGridDBColumn);
procedure CrearColumnasAtributosDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  var AColumnas: array of TcxGridDBColumn;
  AOnGetDataText: TcxGridGetDataTextEvent = nil);
procedure DesmontarModoEntradaDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid);
procedure PrepararReconstruccionModoDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  var AColumnasTallas: array of TcxGridDBColumn;
  var AColumnasAtributos: array of TcxGridDBColumn;
  var AColColorPivot: TcxGridDBColumn);
function ConstruirModoEntradaDocumento(
  const AModoEntrada: IModoEntradaGrid;
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent;
  AModoSeleccionado: TModoColumnasSku;
  const AModosDegradables: TConjuntoModosColumnasSku;
  const AContextoLog: string): Boolean;
procedure ConfigurarColumnaBotonDocumento(
  AColumna: TcxGridDBColumn;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent = nil);
function ConfigurarColumnaBusquedaDocumento(
  AVista: TcxGridDBTableView; const ACampo: string;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent = nil): TcxGridDBColumn;
function CrearColumnaColorPivoteDocumento(
  AVista: TcxGridDBTableView; const ANombre: string;
  AAncho: Integer): TcxGridDBColumn;
procedure LiberarModoYGestoresDocumento(
  var AModoEntrada: IModoEntradaGrid;
  var APivote: TGridPivoteCompra;
  var AGestorTallas: TGestorGridTallas);
procedure ActualizarModoEntradaAlNavegarDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; AModo: TModoColumnasSku;
  AReconstruirTallas: Boolean;
  AConstruir, ADesempaquetar: TAccionDocumento);
procedure ActualizarFocoLineaDocumento(
  AGestorTallas: TGestorGridTallas;
  APivote: TGridPivoteCompra; AMostrarAtributos: Boolean;
  ACargarAtributos: TAccionDocumento);
procedure EntrarGridLineasDocumento(
  AFormulario: TForm; AConstruido, AReconstruir: Boolean;
  var AModoEntrada: IModoEntradaGrid;
  AAsegurarLinea, AConstruir: TAccionDocumento);
function CambiarModoEntradaDocumento(
  var AModo: TModoColumnasSku; ANuevoModo: TModoColumnasSku;
  AConstruir: TAccionDocumento): Boolean;
function ProcesarTeclaCambioModoDocumento(
  var ATecla: Word; AShift: TShiftState; AHabilitado: Boolean;
  var AModo: TModoColumnasSku;
  const ACiclo: array of TModoColumnasSku;
  AConstruir: TAccionDocumento): Boolean;
procedure PersistirPreferenciaPivoteDocumento(
  ADataSet: TDataSet; const ACampo: string; AActivo: Boolean);
procedure ResolverArtSkuActivoDocumento(
  AVista: TcxGridDBTableView; out ACodArt, ACodSku: string);
function DataSourcesParaFotoDocumento(
  ACabecera: TDataSource; AVista: TcxGridDBTableView):
  TArray<TDataSource>;
procedure ConfigurarTablaPrincipalDocumento(
  const AAnfitrion: IAnfitrionDatosDocumento; ACabecera: TDataSource;
  AVistaLineas: TcxGridDBTableView; ASourceLineas: TDataSource;
  const AConsultasDetalle: array of TUniQuery;
  var AClavePrincipal: string; const AClave: string);
function CrearConfigColumnasSkuDocumento(
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  AModo: TModoColumnasSku; const AAlmacenStock,
  APrefijoLinea: string): TConfigColumnasSku;
function CrearColumnaHostDocumento(
  AVista: TcxGridDBTableView; const ACaption, ACampo: string;
  AAncho: Integer; AEditable: Boolean): TcxGridDBColumn;
function CrearColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string): TColumnasHostDocumentoCompra;
function CrearConfigPivoteBandasDocumentoCompra(
  AConexion: TUniConnection; const AUsuario: string;
  ASourceMaster, ASourceLineas: TDataSource;
  const APrefijoCabecera, APrefijoLinea,
  ACampoPrecioBase: string;
  AMaxColumnas: Integer): TGridPivoteVentaConfig;
procedure EstablecerVisibilidadColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn; AVisible: Boolean);
function CaptionModoLineasDocumento(const ACaptionBase,
  ACaptionSinConstruir: string; AConstruido: Boolean;
  AModo: TModoColumnasSku; AUsaBandasSeparadas: Boolean): string;
procedure RestablecerCaptionsAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn);
procedure AplicarNombresAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn;
  const ANombres: array of string);
procedure AplicarNombresAtributosGlobalesDocumento(
  AVista: TcxGridDBTableView; const ANombres: array of string);
procedure MostrarColumnasAtributoGlobalesDocumento(
  AConexion: TUniConnection; AVista: TcxGridDBTableView);
procedure CargarCaptionsAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  const AColumnas: array of TcxGridDBColumn);
function CopiarColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn):
  TArray<TcxGridDBColumn>;
function CrearConfigTallasDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra): TGridTallasConfig;
function CrearConfigPivoteDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra;
  AGestor: TGestorGridTallas): TGridPivoteCompraConfig;
procedure ConfigurarEventosTallasDocumento(
  const AColumnas: array of TcxGridDBColumn;
  AOnEditValueChanged: TNotifyEvent;
  AOnValidate: TcxEditValidateEvent);

implementation

uses
  System.SysUtils, Winapi.Windows, cxDataStorage, cxButtonEdit,
  cxCurrencyEdit, inLibLog, inLibFotos, inLibMsgArticulos,
  inLibMsgComun;

procedure CrearColumnasTallasDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  AAncho: Integer; var AColumnas: array of TcxGridDBColumn);
var
  iIndice: Integer;
  oColumna: TcxGridDBColumn;
  oPropiedades: TcxCurrencyEditProperties;
begin
  if Assigned(AVista) then
  begin
    for iIndice := Low(AColumnas) to High(AColumnas) do
    begin
      oColumna := AVista.CreateColumn;
      oColumna.Name := APrefijoNombre + Format('%.2d', [iIndice + 1]);
      oColumna.Caption := '';
      oColumna.Width := AAncho;
      oColumna.Tag := iIndice + 1;
      oColumna.Visible := False;
      oColumna.DataBinding.ValueTypeClass := TcxFloatValueType;
      oColumna.PropertiesClass := TcxCurrencyEditProperties;
      oPropiedades := TcxCurrencyEditProperties(oColumna.Properties);
      oPropiedades.DisplayFormat := '#,##0';
      AColumnas[iIndice] := oColumna;
    end;
  end;
end;

procedure CrearColumnasAtributosDocumento(
  AVista: TcxGridDBTableView; const APrefijoNombre: string;
  var AColumnas: array of TcxGridDBColumn;
  AOnGetDataText: TcxGridGetDataTextEvent);
var
  iIndice: Integer;
  oColumna: TcxGridDBColumn;
begin
  if Assigned(AVista) then
  begin
    for iIndice := Low(AColumnas) to High(AColumnas) do
    begin
      oColumna := AVista.CreateColumn;
      oColumna.Name := APrefijoNombre + Format('%.2d', [iIndice + 1]);
      oColumna.Caption := '';
      oColumna.Width := 90;
      oColumna.Tag := -(iIndice + 1);
      oColumna.Visible := False;
      oColumna.Options.Editing := False;
      if Assigned(AOnGetDataText) then
        oColumna.OnGetDataText := AOnGetDataText;
      AColumnas[iIndice] := oColumna;
    end;
  end;
end;

procedure DesmontarModoEntradaDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid);
begin
  if Assigned(AVista) then
  begin
    if AVista.Controller.EditingController.IsEditing then
      try
        AVista.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          // Ruido del editor inplace durante el desmontaje.
          if inLibLog.Log() <> nil then
            inLibLog.Log.LogWarning(
              'DesmontarModoEntradaDocumento: HideEdit ignorado: ' +
              E.Message);
      end;
  end;
  if Assigned(ADataSet) and (ADataSet.State in dsEditModes) then
    ADataSet.Cancel;
  if Assigned(AModoEntrada) then
    AModoEntrada.Desmontar;
  if Assigned(AVista) then
  begin
    AVista.OnInitEdit := nil;
    AVista.OnEditKeyDown := nil;
    AVista.OnEditing := nil;
    AVista.OnFocusedRecordChanged := nil;
    AVista.OnFocusedItemChanged := nil;
    AVista.OnCustomDrawCell := nil;
    AVista.ClearItems;
  end;
  AModoEntrada := nil;
end;

procedure PrepararReconstruccionModoDocumento(
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  var AModoEntrada: IModoEntradaGrid;
  var AColumnasTallas: array of TcxGridDBColumn;
  var AColumnasAtributos: array of TcxGridDBColumn;
  var AColColorPivot: TcxGridDBColumn);
var
  iIndice: Integer;
begin
  DesmontarModoEntradaDocumento(AVista, ADataSet, AModoEntrada);
  for iIndice := Low(AColumnasTallas) to High(AColumnasTallas) do
    AColumnasTallas[iIndice] := nil;
  for iIndice := Low(AColumnasAtributos) to
    High(AColumnasAtributos) do
    AColumnasAtributos[iIndice] := nil;
  AColColorPivot := nil;
end;

function ConstruirModoEntradaDocumento(
  const AModoEntrada: IModoEntradaGrid;
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent;
  AModoSeleccionado: TModoColumnasSku;
  const AModosDegradables: TConjuntoModosColumnasSku;
  const AContextoLog: string): Boolean;
begin
  Result := True;
  AModoEntrada.OnResuelto := AOnResuelto;
  AModoEntrada.OnEntrarEdicion := AOnEntrarEdicion;
  AModoEntrada.OnSalirEdicion := AOnSalirEdicion;
  try
    AModoEntrada.Construir;
  except
    on E: Exception do
    begin
      if AModoSeleccionado in AModosDegradables then
      begin
        if inLibLog.Log() <> nil then
          inLibLog.Log.LogError(
            AContextoLog +
            ': fallo construyendo tallas horizontal, ' +
            'se degrada a SKU: ' + E.Message);
        Result := False;
      end
      else
        raise;
    end;
  end;
end;

procedure ConfigurarColumnaBotonDocumento(
  AColumna: TcxGridDBColumn;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent);
var
  oBoton: TcxEditButton;
  oPropiedades: TcxButtonEditProperties;
begin
  if Assigned(AColumna) then
  begin
    AColumna.PropertiesClass := TcxButtonEditProperties;
    AColumna.Options.ShowEditButtons := isebAlways;
    oPropiedades := TcxButtonEditProperties(AColumna.Properties);
    oPropiedades.Buttons.Clear;
    oBoton := oPropiedades.Buttons.Add;
    oBoton.Kind := bkEllipsis;
    oPropiedades.OnButtonClick := AOnButtonClick;
    oPropiedades.OnValidate := AOnValidate;
  end;
end;

function ConfigurarColumnaBusquedaDocumento(
  AVista: TcxGridDBTableView; const ACampo: string;
  AOnButtonClick: TcxEditButtonClickEvent;
  AOnValidate: TcxEditValidateEvent): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
    Result := AVista.GetColumnByFieldName(ACampo);
  ConfigurarColumnaBotonDocumento(
    Result, AOnButtonClick, AOnValidate);
end;

function CrearColumnaColorPivoteDocumento(
  AVista: TcxGridDBTableView; const ANombre: string;
  AAncho: Integer): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
  begin
    Result := AVista.CreateColumn;
    Result.Name := ANombre;
    Result.Caption := SCaptionColColor;
    Result.Width := AAncho;
    Result.Visible := False;
    Result.Options.Editing := True;
  end;
end;

procedure LiberarModoYGestoresDocumento(
  var AModoEntrada: IModoEntradaGrid;
  var APivote: TGridPivoteCompra;
  var AGestorTallas: TGestorGridTallas);
begin
  if Assigned(AModoEntrada) then
  begin
    try
      AModoEntrada.Desmontar;
    except
      // El cierre no debe quedar bloqueado por un desmontaje parcial.
      on E: Exception do
        if inLibLog.Log() <> nil then
          inLibLog.Log.LogWarning(
            'LiberarModoYGestoresDocumento: Desmontar fallo: ' +
            E.Message);
    end;
    AModoEntrada := nil;
  end;
  FreeAndNil(APivote);
  FreeAndNil(AGestorTallas);
end;

procedure ActualizarModoEntradaAlNavegarDocumento(
  AField: TField; ALineas: TDataSet; AMaster: TDataSource;
  AConstruido: Boolean; AModo: TModoColumnasSku;
  AReconstruirTallas: Boolean;
  AConstruir, ADesempaquetar: TAccionDocumento);
var
  bMasterEditable: Boolean;
begin
  bMasterEditable := Assigned(AMaster) and
    (AMaster.State in dsEditModes);
  if (AField = nil) and Assigned(ALineas) and ALineas.Active and
     (not bMasterEditable) then
  begin
    if (not AConstruido) or
       (AReconstruirTallas and (AModo = mcsTallasHorPed)) then
    begin
      if Assigned(AConstruir) then
        AConstruir;
    end
    else if (AModo = mcsAuto) and Assigned(ADesempaquetar) then
      ADesempaquetar;
  end;
end;

procedure ActualizarFocoLineaDocumento(
  AGestorTallas: TGestorGridTallas;
  APivote: TGridPivoteCompra; AMostrarAtributos: Boolean;
  ACargarAtributos: TAccionDocumento);
begin
  if Assigned(AGestorTallas) and Assigned(APivote) and
     APivote.Activo then
    AGestorTallas.ActualizarCaptionsLineaActiva;
  if AMostrarAtributos and Assigned(ACargarAtributos) then
    ACargarAtributos;
end;

procedure EntrarGridLineasDocumento(
  AFormulario: TForm; AConstruido, AReconstruir: Boolean;
  var AModoEntrada: IModoEntradaGrid;
  AAsegurarLinea, AConstruir: TAccionDocumento);
begin
  inLibGridTallasInline.ActivarEnterComoTab(
    AFormulario, False);
  if Assigned(AAsegurarLinea) then
    AAsegurarLinea;
  if (not AConstruido) or AReconstruir then
  begin
    if Assigned(AConstruir) then
      AConstruir;
    if Assigned(AAsegurarLinea) then
      AAsegurarLinea;
  end;
  if Assigned(AModoEntrada) then
    AModoEntrada.MostrarEditor;
end;

function CambiarModoEntradaDocumento(
  var AModo: TModoColumnasSku; ANuevoModo: TModoColumnasSku;
  AConstruir: TAccionDocumento): Boolean;
begin
  Result := AModo <> ANuevoModo;
  if Result then
  begin
    AModo := ANuevoModo;
    if Assigned(AConstruir) then
      AConstruir;
  end;
end;

function ProcesarTeclaCambioModoDocumento(
  var ATecla: Word; AShift: TShiftState; AHabilitado: Boolean;
  var AModo: TModoColumnasSku;
  const ACiclo: array of TModoColumnasSku;
  AConstruir: TAccionDocumento): Boolean;
var
  iIndice: Integer;
  ModoNuevo: TModoColumnasSku;
begin
  Result := (ATecla = VK_F1) and (AShift = []) and AHabilitado and
    (Length(ACiclo) > 0);
  if Result then
  begin
    ModoNuevo := ACiclo[0];
    for iIndice := Low(ACiclo) to High(ACiclo) do
    begin
      if AModo = ACiclo[iIndice] then
      begin
        if iIndice < High(ACiclo) then
          ModoNuevo := ACiclo[iIndice + 1];
      end;
    end;
    ATecla := 0;
    CambiarModoEntradaDocumento(AModo, ModoNuevo, AConstruir);
  end;
end;

procedure PersistirPreferenciaPivoteDocumento(
  ADataSet: TDataSet; const ACampo: string; AActivo: Boolean);
var
  oCampo: TField;
  sValor: string;
begin
  oCampo := nil;
  if Assigned(ADataSet) then
  begin
    if ADataSet.Active and (not ADataSet.IsEmpty) then
      oCampo := ADataSet.FindField(ACampo);
  end;
  if Assigned(oCampo) then
  begin
    if not (ADataSet.State in dsEditModes) then
      ADataSet.Edit;
    sValor := 'N';
    if AActivo then
      sValor := 'S';
    oCampo.AsString := sValor;
    ADataSet.Post;
  end;
end;

procedure ResolverArtSkuActivoDocumento(
  AVista: TcxGridDBTableView; out ACodArt, ACodSku: string);
var
  oDataSource: TDataSource;
begin
  ACodArt := '';
  ACodSku := '';
  oDataSource := nil;
  if Assigned(AVista) then
    oDataSource := AVista.DataController.DataSource;
  if Assigned(oDataSource) then
    inLibFotos.LeerArtSkuDeDataSet(
      oDataSource.DataSet, ACodArt, ACodSku);
end;

function DataSourcesParaFotoDocumento(
  ACabecera: TDataSource; AVista: TcxGridDBTableView):
  TArray<TDataSource>;
var
  oDetalle: TDataSource;
begin
  oDetalle := nil;
  if Assigned(AVista) then
    oDetalle := AVista.DataController.DataSource;
  if Assigned(oDetalle) then
    Result := [ACabecera, oDetalle]
  else
    Result := [ACabecera];
end;

procedure ConfigurarTablaPrincipalDocumento(
  const AAnfitrion: IAnfitrionDatosDocumento; ACabecera: TDataSource;
  AVistaLineas: TcxGridDBTableView; ASourceLineas: TDataSource;
  const AConsultasDetalle: array of TUniQuery;
  var AClavePrincipal: string; const AClave: string);
var
  iIndice: Integer;
begin
  if Assigned(AAnfitrion) and Assigned(ACabecera) then
  begin
    ACabecera.DataSet := AAnfitrion.ObtenerTablaPrincipal;
    AAnfitrion.AsignarMaestroCabecera(ACabecera);
  end;
  if Assigned(AVistaLineas) then
    AVistaLineas.DataController.DataSource := ASourceLineas;
  for iIndice := Low(AConsultasDetalle) to
    High(AConsultasDetalle) do
  begin
    if Assigned(AConsultasDetalle[iIndice]) then
      AConsultasDetalle[iIndice].MasterSource := ACabecera;
  end;
  if AClave <> '' then
    AClavePrincipal := AClave;
end;

function CrearConfigColumnasSkuDocumento(
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  AVista: TcxGridDBTableView; ADataSet: TDataSet;
  AModo: TModoColumnasSku; const AAlmacenStock,
  APrefijoLinea: string): TConfigColumnasSku;
var
  iIndice: Integer;
begin
  Result := Default(TConfigColumnasSku);
  Result.Conexion := AConexion;
  Result.ContextoSesion := AContextoSesion;
  Result.View := AVista;
  Result.Cds := ADataSet;
  Result.Modo := AModo;
  Result.AlmacenStock := AAlmacenStock;
  Result.Distribuido := False;
  Result.Campos.CodigoArt := 'CODIGO_ART_' + APrefijoLinea;
  Result.Campos.CodigoUnidad := 'CODIGO_UNIDAD_' + APrefijoLinea;
  Result.Campos.Descripcion :=
    'DESCRIPCION_ARTICULO_' + APrefijoLinea;
  Result.Campos.Cantidad := 'CANTIDAD_' + APrefijoLinea;
  Result.Campos.Almacen := 'CODIGO_ALMACEN_' + APrefijoLinea;
  Result.Campos.NumAtributos :=
    'NUM_ATRIBUTOS_' + APrefijoLinea;
  for iIndice := 1 to 5 do
  begin
    Result.Campos.AttrValor[iIndice] := 'ATTR' +
      IntToStr(iIndice) + '_VALOR_' + APrefijoLinea;
    Result.Campos.AttrNombre[iIndice] := 'ATTR' +
      IntToStr(iIndice) + '_NOMBRE_' + APrefijoLinea;
  end;
end;

function CrearColumnaHostDocumento(
  AVista: TcxGridDBTableView; const ACaption, ACampo: string;
  AAncho: Integer; AEditable: Boolean): TcxGridDBColumn;
begin
  Result := nil;
  if Assigned(AVista) then
  begin
    Result := AVista.CreateColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
end;

function CrearColumnasHostDocumentoCompra(
  AVista: TcxGridDBTableView; AModo: TModoColumnasSku;
  const APrefijoLinea: string): TColumnasHostDocumentoCompra;
begin
  Result := Default(TColumnasHostDocumentoCompra);
  Result.ColLinea := CrearColumnaHostDocumento(
    AVista, 'Línea', 'LINEA_' + APrefijoLinea, 60, False);
  CrearColumnaHostDocumento(AVista, 'Modelo prov.',
    'REF_PRV_' + APrefijoLinea, 130, True);
  CrearColumnaHostDocumento(AVista, 'Descripción',
    'DESCRIPCION_ARTICULO_' + APrefijoLinea, 260, False);
  if AModo <> mcsTallasHorPed then
  begin
    Result.ColCantidad := CrearColumnaHostDocumento(
      AVista, 'Cantidad', 'CANTIDAD_' + APrefijoLinea, 80, True);
    Result.ColTipoCantidad := CrearColumnaHostDocumento(
      AVista, '', 'TIPO_CANTIDAD_ARTICULO_' + APrefijoLinea,
      90, False);
  end;
  Result.ColPrecioCompra := CrearColumnaHostDocumento(
    AVista, 'Precio compra',
    'PRECIO_COMPRA_SIVA_ARTICULO_' + APrefijoLinea, 130, True);
  CrearColumnaHostDocumento(AVista, '% IVA',
    'PORCENTAJE_IVA_' + APrefijoLinea, 70, True);
  if AModo = mcsTallasHorPed then
    CrearColumnaHostDocumento(AVista, 'Total uds.',
      'TOTAL_' + APrefijoLinea, 100, False)
  else
    CrearColumnaHostDocumento(AVista, 'Total',
      'TOTAL_' + APrefijoLinea, 100, False);
  CrearColumnaHostDocumento(AVista, 'Almacén',
    'CODIGO_ALMACEN_' + APrefijoLinea, 90, True);
  if Assigned(Result.ColLinea) then
    Result.ColLinea.Index := 0;
end;

function CrearConfigPivoteBandasDocumentoCompra(
  AConexion: TUniConnection; const AUsuario: string;
  ASourceMaster, ASourceLineas: TDataSource;
  const APrefijoCabecera, APrefijoLinea,
  ACampoPrecioBase: string;
  AMaxColumnas: Integer): TGridPivoteVentaConfig;
begin
  Result := Default(TGridPivoteVentaConfig);
  Result.Conexion := AConexion;
  Result.Usuario := AUsuario;
  Result.SourceMaster := ASourceMaster;
  Result.SourceLineas := ASourceLineas;
  Result.FieldSerieMaster := 'SERIE_' + APrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + APrefijoCabecera;
  Result.FieldLinea := 'LINEA_' + APrefijoLinea;
  Result.FieldArt := 'CODIGO_ART_' + APrefijoLinea;
  Result.FieldSku := 'CODIGO_UNIDAD_' + APrefijoLinea;
  Result.FieldDescripcion :=
    'DESCRIPCION_ARTICULO_' + APrefijoLinea;
  Result.FieldTipoCantidad :=
    'TIPO_CANTIDAD_ARTICULO_' + APrefijoLinea;
  Result.FieldCantidadPedida := 'CANTIDAD_' + APrefijoLinea;
  Result.FieldPrecioBase := ACampoPrecioBase;
  Result.FieldAlmacen := 'CODIGO_ALMACEN_' + APrefijoLinea;
  Result.FieldAlmacenMaster :=
    'CODIGO_ALM_' + APrefijoCabecera;
  Result.MaxColumnas := AMaxColumnas;
end;

procedure EstablecerVisibilidadColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn; AVisible: Boolean);
var
  iIndice: Integer;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Visible := AVisible;
end;

function CaptionModoLineasDocumento(const ACaptionBase,
  ACaptionSinConstruir: string; AConstruido: Boolean;
  AModo: TModoColumnasSku; AUsaBandasSeparadas: Boolean): string;
begin
  Result := ACaptionSinConstruir;
  if AConstruido then
  begin
    Result := Format(SCaptionTabModoDesglose, [ACaptionBase]);
    if AModo = mcsSku then
      Result := Format(SCaptionTabModoSku, [ACaptionBase])
    else if AModo = mcsTallasHorPed then
    begin
      if AUsaBandasSeparadas then
        Result := Format(SCaptionTabModoTallasHorizBandas,
                         [ACaptionBase])
      else
        Result := Format(SCaptionTabModoTallasHoriz, [ACaptionBase]);
    end
    else if AUsaBandasSeparadas and (AModo = mcsTallasInline) then
      Result := Format(SCaptionTabModoTallasHoriz, [ACaptionBase]);
  end;
end;

procedure RestablecerCaptionsAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn);
var
  iIndice: Integer;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Caption :=
        Format(SCaptionAtributoN, [iIndice + 1]);
end;

procedure AplicarNombresAtributosDocumento(
  const AColumnas: array of TcxGridDBColumn;
  const ANombres: array of string);
var
  iIndice: Integer;
begin
  iIndice := 0;
  while (iIndice <= High(AColumnas)) and
        (iIndice <= High(ANombres)) do
  begin
    if Assigned(AColumnas[iIndice]) then
      AColumnas[iIndice].Caption := ANombres[iIndice];
    Inc(iIndice);
  end;
end;

procedure AplicarNombresAtributosGlobalesDocumento(
  AVista: TcxGridDBTableView; const ANombres: array of string);
var
  iColumna: Integer;
  iNombre: Integer;
  iOrden: Integer;
  oColumna: TcxGridDBColumn;
begin
  if Assigned(AVista) then
  begin
    iNombre := Low(ANombres);
    iOrden := 1;
    while iNombre <= High(ANombres) do
    begin
      for iColumna := 0 to AVista.ColumnCount - 1 do
      begin
        oColumna := AVista.Columns[iColumna];
        if oColumna.Tag = iOrden then
        begin
          oColumna.Caption := ANombres[iNombre];
          oColumna.Visible := True;
        end;
      end;
      Inc(iNombre);
      Inc(iOrden);
    end;
  end;
end;

procedure MostrarColumnasAtributoGlobalesDocumento(
  AConexion: TUniConnection; AVista: TcxGridDBTableView);
var
  aNombres: TArray<string>;
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  if Assigned(AConexion) and Assigned(AVista) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
        '       MIN(ORDEN_VA) AS ORDEN' +
        '  FROM fza_variaciones_atributos' +
        ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
        ' ORDER BY ORDEN, NOMBRE LIMIT 5';
      oConsulta.Open;
      SetLength(aNombres, 0);
      while (not oConsulta.Eof) and (Length(aNombres) < 5) do
      begin
        iIndice := Length(aNombres);
        SetLength(aNombres, iIndice + 1);
        aNombres[iIndice] :=
          oConsulta.FieldByName('NOMBRE').AsString;
        oConsulta.Next;
      end;
      AplicarNombresAtributosGlobalesDocumento(
        AVista, aNombres);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function LeerNombresAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  ACantidadMaxima: Integer): TArray<string>;
var
  iIndice: Integer;
  sArticulo: string;
begin
  SetLength(Result, 0);
  if Assigned(AConsulta) and Assigned(ALineas) and ALineas.Active and
     not ALineas.IsEmpty then
  begin
    sArticulo := ALineas.FieldByName(ACampoArticulo).AsString;
    if sArticulo <> '' then
    begin
      AConsulta.Close;
      try
        AConsulta.ParamByName('ARTICULO').AsString := sArticulo;
        AConsulta.Open;
        iIndice := 0;
        while (not AConsulta.Eof) and
              (iIndice < ACantidadMaxima) do
        begin
          SetLength(Result, iIndice + 1);
          Result[iIndice] :=
            AConsulta.FieldByName('NOMBRE_ATRIBUTO').AsString;
          Inc(iIndice);
          AConsulta.Next;
        end;
      finally
        AConsulta.Close;
      end;
    end;
  end;
end;

procedure CargarCaptionsAtributosDocumento(AConsulta: TUniQuery;
  ALineas: TDataSet; const ACampoArticulo: string;
  const AColumnas: array of TcxGridDBColumn);
var
  aNombres: TArray<string>;
begin
  if Assigned(AConsulta) then
  begin
    RestablecerCaptionsAtributosDocumento(AColumnas);
    aNombres := LeerNombresAtributosDocumento(AConsulta, ALineas,
      ACampoArticulo, Length(AColumnas));
    AplicarNombresAtributosDocumento(AColumnas, aNombres);
  end;
end;

function CopiarColumnasDocumento(
  const AColumnas: array of TcxGridDBColumn):
  TArray<TcxGridDBColumn>;
var
  iIndice: Integer;
begin
  SetLength(Result, Length(AColumnas));
  for iIndice := Low(AColumnas) to High(AColumnas) do
    Result[iIndice] := AColumnas[iIndice];
end;

function CrearConfigTallasDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra): TGridTallasConfig;
begin
  Result := Default(TGridTallasConfig);
  Result.Conexion := AConfig.Conexion;
  Result.ContextoSesion := AConfig.ContextoSesion;
  Result.Usuario := AConfig.Usuario;
  Result.Grid := AConfig.Vista;
  Result.SourceMaster := AConfig.SourceMaster;
  Result.SourceLineas := AConfig.SourceLineas;
  Result.ColumnasTallas := AConfig.ColumnasTallas;
  Result.FieldSerieMaster := 'SERIE_' + AConfig.PrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + AConfig.PrefijoCabecera;
  Result.FieldLinea := 'LINEA_' + AConfig.PrefijoLinea;
  Result.FieldConjuntoPivot := 'ID_AC_PIVOT_' + AConfig.PrefijoLinea;
  Result.FieldPrecioBase :=
    'PRECIO_COMPRA_SIVA_ARTICULO_' + AConfig.PrefijoLinea;
  Result.FieldTotalUds := 'TOTAL_UNIDADES_' + AConfig.PrefijoLinea;
  Result.FieldTotalLinea := 'TOTAL_' + AConfig.PrefijoLinea;
  Result.TablaCeldas := 'fza_' + AConfig.NombreTablaDocumento +
    '_compra_celdas';
  Result.FieldSerieCel := 'SERIE_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldNumeroCel := 'NUMERO_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldLineaCel := 'LINEA_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldFilaCel := 'ID_FILA_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoCelda;
  Result.FieldAvPivotCel := 'ID_AV_PIVOT_' + AConfig.PrefijoCelda;
  Result.FieldCantidadCel := 'CANTIDAD_' + AConfig.PrefijoCelda;
  Result.FieldAlmacenCel := 'CODIGO_ALM_' + AConfig.PrefijoCelda;
  Result.IdFilaFijo := 1;
  Result.MaxColumnas := Length(AConfig.ColumnasTallas);
end;

function CrearConfigPivoteDocumentoCompra(
  const AConfig: TConfigPivoteDocumentoCompra;
  AGestor: TGestorGridTallas): TGridPivoteCompraConfig;
var
  iCantidadCampos: Integer;
begin
  Result := Default(TGridPivoteCompraConfig);
  Result.Conexion := AConfig.Conexion;
  if AConfig.AplicarContextoPivote then
    Result.ContextoSesion := AConfig.ContextoSesion;
  Result.Grid := AConfig.Vista;
  Result.SourceMaster := AConfig.SourceMaster;
  Result.SourceLineas := AConfig.ConsultaLineas;
  Result.Gestor := AGestor;
  Result.ColColorPivot := AConfig.ColColorPivot;
  Result.ColColorProveedorPivot := AConfig.ColColorProveedorPivot;
  Result.ColumnasTallas := AConfig.ColumnasTallas;
  Result.MaxColumnasTallas := Length(AConfig.ColumnasTallas);
  Result.TablaLineas := 'fza_' + AConfig.NombreTablaDocumento +
    '_compra_lineas';
  Result.FieldSerieMaster := 'SERIE_' + AConfig.PrefijoCabecera;
  Result.FieldNumeroMaster := 'NUMERO_' + AConfig.PrefijoCabecera;
  Result.FieldSerieLin := 'SERIE_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoLinea;
  Result.FieldNumeroLin := 'NUMERO_' + AConfig.PrefijoCabecera + '_' +
    AConfig.PrefijoLinea;
  Result.FieldLinea := 'LINEA_' + AConfig.PrefijoLinea;
  Result.FieldArt := 'CODIGO_ART_' + AConfig.PrefijoLinea;
  Result.FieldSku := 'CODIGO_UNIDAD_' + AConfig.PrefijoLinea;
  Result.FieldCantidad := 'CANTIDAD_' + AConfig.PrefijoLinea;
  Result.FieldPrecioBase :=
    'PRECIO_COMPRA_SIVA_ARTICULO_' + AConfig.PrefijoLinea;
  Result.FieldTotalUds := 'TOTAL_UNIDADES_' + AConfig.PrefijoLinea;
  Result.FieldTotalLinea := 'TOTAL_' + AConfig.PrefijoLinea;
  if AConfig.TieneCantidadRecibida then
    Result.FieldCantidadRecibida :=
      'CANTIDAD_RECIBIDA_' + AConfig.PrefijoLinea;
  Result.FieldIdAcPivot := 'ID_AC_PIVOT_' + AConfig.PrefijoLinea;
  Result.FieldAlmacen := 'CODIGO_ALMACEN_' + AConfig.PrefijoLinea;
  Result.FieldAlmacenMaster := 'CODIGO_ALM_' + AConfig.PrefijoCabecera;
  Result.FieldColorTexto := AConfig.CampoColorTexto;
  iCantidadCampos := 3;
  if AConfig.TieneCantidadRecibida then
    iCantidadCampos := 4;
  SetLength(Result.CamposOcultosEnPivote, iCantidadCampos);
  Result.CamposOcultosEnPivote[0] :=
    'CODIGO_UNIDAD_' + AConfig.PrefijoLinea;
  Result.CamposOcultosEnPivote[1] :=
    'CANTIDAD_' + AConfig.PrefijoLinea;
  if AConfig.TieneCantidadRecibida then
  begin
    Result.CamposOcultosEnPivote[2] :=
      'CANTIDAD_RECIBIDA_' + AConfig.PrefijoLinea;
    Result.CamposOcultosEnPivote[3] :=
      'TOTAL_' + AConfig.PrefijoLinea;
  end
  else
    Result.CamposOcultosEnPivote[2] :=
      'TOTAL_' + AConfig.PrefijoLinea;
end;

procedure ConfigurarEventosTallasDocumento(
  const AColumnas: array of TcxGridDBColumn;
  AOnEditValueChanged: TNotifyEvent;
  AOnValidate: TcxEditValidateEvent);
var
  iIndice: Integer;
  oPropiedades: TcxCurrencyEditProperties;
begin
  for iIndice := Low(AColumnas) to High(AColumnas) do
  begin
    if Assigned(AColumnas[iIndice]) and
       (AColumnas[iIndice].Properties is
        TcxCurrencyEditProperties) then
    begin
      oPropiedades :=
        TcxCurrencyEditProperties(AColumnas[iIndice].Properties);
      oPropiedades.OnEditValueChanged := AOnEditValueChanged;
      oPropiedades.OnValidate := AOnValidate;
    end;
  end;
end;

end.
