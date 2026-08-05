{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionTallas                        }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Edicion de tallas de la sesion de compra: columnas inline no-bound,       }
{    catalogo de sistemas de tallaje, selector, pintado de celdas, bloqueo     }
{    de posiciones que no aplican y salto al distribuidor por almacen.         }
{    El calculo y la persistencia de celdas siguen en TGestorGridTallas.       }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionTallas;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Variants,
  System.UITypes,
  System.Generics.Collections,
  Data.DB,
  Uni,
  Vcl.Controls,
  cxGraphics,
  cxEdit,
  cxButtonEdit,
  cxCurrencyEdit,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibContextoSesionIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibGridTallasInline;

type
  TEntornoTallasSesion = record
    Conexion: TUniConnection;
    ContextoSesion: IContextoSesionAplicacion;
    Usuario: string;
    Contenedor: TWinControl;
    Vista: TcxGridDBTableView;
    ColumnaSelector: TcxGridDBColumn;
    FuenteCabecera: TDataSource;
    MaxColumnas: Integer;
    FijarTallajeDefecto: TProc<Integer>;
    RefrescarTotalesSesion: TProc;
    RepositorioDistribuidor: IRepositorioDistribuidor;
  end;

  TCoordinadorTallasSesion = class
  private
    FEntorno: TEntornoTallasSesion;
    FOpciones: TArray<TOpcionConjuntoTalla>;
    FNombres: TDictionary<Integer, string>;
    FColumnas: TArray<TcxGridDBColumn>;
    FGestor: TGestorGridTallas;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    procedure AbrirCatalogoConjuntos;
    procedure VolcarCatalogoConjuntos;
    procedure CeldaTallaCambiada(ASender: TObject);
    function PuedeElegirSistema: Boolean;
    procedure AplicarSistemaElegido(ASender: TObject; AIdNuevo: Integer);
    function EsColumnaTalla(AItem: TObject; out APosicion: Integer): Boolean;
    function EsFormatoDistribuido: Boolean;
    function DispararBotonColumnaActiva: Boolean;
    function EditorActivo: TcxCustomEdit;
    function SombrearCeldaFueraDeConjunto(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      APosicion: Integer): Boolean;
    function DibujarNombreSistema(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
  public
    constructor Create(const AEntorno: TEntornoTallasSesion);
    destructor Destroy; override;
    // Crea las columnas inline. Debe correr ANTES del inherited del
    // formulario: la apertura del detalle ya recalcula el maximo.
    procedure CrearColumnas;
    // Coloca el bloque de tallas justo detras de la columna selector.
    procedure ReindexarColumnas(AIndiceBase: Integer);
    // Cablea el gestor de tallas con los datasets de la sesion. Se
    // invoca cuando el data module ya esta disponible.
    procedure ConfigurarDatos(ACabecera: TDataSet; ALineas: TDataSet;
      AFuenteLineas: TDataSource);
    procedure AbrirSelector(ASender: TObject;
      const ABusquedaInicial: string = '');
    procedure AbrirDistribuidor(const ACodigoKit: string = '');
    // Teclas dentro del editor in-place. True = tecla consumida.
    function ProcesarTeclaEditor(AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit; var AKey: Word;
      AShift: TShiftState): Boolean;
    // Teclas a nivel de formulario (KeyPreview). True = consumida.
    function ProcesarTeclaFormulario(var AKey: Word;
      AShift: TShiftState): Boolean;
    // True si la celda ya queda pintada por este colaborador.
    function DibujarCelda(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
    procedure AjustarPermisoEdicion(AItem: TcxCustomGridTableItem;
      var AAllow: Boolean);
    property Gestor: TGestorGridTallas read FGestor;
    property Columnas: TArray<TcxGridDBColumn> read FColumnas;
  end;

implementation

uses
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Graphics,
  cxDataStorage,
  inLibComprasSesionesPresentacion,
  inLibMsgCompras,
  inMtoModalDistribuidor,
  UniDataComprasSesionesPresentacionRepositorio,
  UniDataModoTallas;

const
  // Ancho minimo del popup del selector de sistema de tallaje.
  cAnchoSelectorTallas = 380;
  // Gris claro de las posiciones que no aplican al conjunto de la fila.
  cColorCeldaInactiva = $00E8E8E8;

constructor TCoordinadorTallasSesion.Create(
  const AEntorno: TEntornoTallasSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Vista) then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if AEntorno.MaxColumnas <= 0 then
    raise EArgumentException.Create('AEntorno.MaxColumnas');
  FEntorno := AEntorno;
  FNombres := TDictionary<Integer, string>.Create;
  SetLength(FColumnas, FEntorno.MaxColumnas);
  AbrirCatalogoConjuntos;
  VolcarCatalogoConjuntos;
end;

destructor TCoordinadorTallasSesion.Destroy;
begin
  FreeAndNil(FGestor);
  FreeAndNil(FNombres);
  inherited Destroy;
end;

// Solo conjuntos del atributo pivot (ID_VA_AC = 'TAL'), con primera y
// ultima talla para mostrarlas como rango en el selector.
procedure TCoordinadorTallasSesion.AbrirCatalogoConjuntos;
begin
  FOpciones := ListarConjuntosTallasUniDAC(FEntorno.Conexion);
end;

// Vuelca el catalogo a las opciones del selector y al diccionario
// ID_AC -> NOMBRE_AC que usa el pintado de la celda.
procedure TCoordinadorTallasSesion.VolcarCatalogoConjuntos;
var
  iOpcion: Integer;
begin
  FNombres.Clear;
  for iOpcion := 0 to Length(FOpciones) - 1 do
  begin
    FNombres.AddOrSetValue(
      FOpciones[iOpcion].IdAc,
      FOpciones[iOpcion].Nombre);
  end;
end;

// Patron heredado de inMtoCajaOpe: BeginUpdate + CreateColumn y asignar
// Index al final. Predefinirlas en el DFM disparaba RLINK32.
procedure TCoordinadorTallasSesion.CrearColumnas;
var
  iColumna: Integer;
  Columna: TcxGridDBColumn;
  iIndiceBase: Integer;
begin
  iIndiceBase := FEntorno.ColumnaSelector.Index;
  FEntorno.Vista.BeginUpdate;
  try
    for iColumna := 0 to FEntorno.MaxColumnas - 1 do
    begin
      Columna := FEntorno.Vista.CreateColumn;
      Columna.Name := Format('dbcLinTalla%2.2d', [iColumna + 1]);
      Columna.Tag := iColumna + 1;
      Columna.Caption := '';
      Columna.Visible := False;
      Columna.Width := 50;
      Columna.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(Columna.Properties).DisplayFormat :=
        '#,##0';
      Columna.HeaderAlignmentHorz := taCenter;
      TcxCurrencyEditProperties(
        Columna.Properties).Alignment.Horz := taCenter;
      // ValueTypeClass no es serializable en DFM: solo runtime.
      Columna.DataBinding.ValueTypeClass := TcxFloatValueType;
      Columna.Index := iIndiceBase + iColumna + 1;
      FColumnas[iColumna] := Columna;
    end;
  finally
    FEntorno.Vista.EndUpdate;
  end;
end;

procedure TCoordinadorTallasSesion.ReindexarColumnas(
  AIndiceBase: Integer);
var
  iColumna: Integer;
begin
  for iColumna := 0 to High(FColumnas) do
  begin
    if Assigned(FColumnas[iColumna]) then
      FColumnas[iColumna].Index := AIndiceBase + iColumna + 1;
  end;
end;

// Cablea el gestor reutilizable con los nombres de tabla y campos
// especificos de Sesiones de compra.
procedure TCoordinadorTallasSesion.ConfigurarDatos(ACabecera: TDataSet;
  ALineas: TDataSet; AFuenteLineas: TDataSource);
var
  Configuracion: TGridTallasConfig;
  iColumna: Integer;
begin
  FCabecera := ACabecera;
  FLineas := ALineas;
  FreeAndNil(FGestor);
  Configuracion := Default(TGridTallasConfig);
  Configuracion.Conexion := FEntorno.Conexion;
  Configuracion.ContextoSesion := FEntorno.ContextoSesion;
  Configuracion.Usuario := FEntorno.Usuario;
  Configuracion.Grid := FEntorno.Vista;
  Configuracion.SourceMaster := FEntorno.FuenteCabecera;
  Configuracion.SourceLineas := AFuenteLineas;
  Configuracion.ColumnasTallas := FColumnas;
  Configuracion.FieldSerieMaster := 'SERIE_SES';
  Configuracion.FieldNumeroMaster := 'NUMERO_SES';
  Configuracion.FieldLinea := 'LINEA_SESLIN';
  Configuracion.FieldConjuntoPivot := 'ID_AC_PIVOT_SESLIN';
  Configuracion.FieldPrecioBase := 'PRECIO_COMPRA_SESLIN';
  Configuracion.FieldTotalUds := 'TOTAL_UNIDADES_SESLIN';
  Configuracion.FieldTotalLinea := 'TOTAL_LINEA_SESLIN';
  Configuracion.TablaCeldas := 'fza_compras_sesiones_celdas';
  Configuracion.FieldSerieCel := 'SERIE_SES_SESCEL';
  Configuracion.FieldNumeroCel := 'NUMERO_SES_SESCEL';
  Configuracion.FieldLineaCel := 'LINEA_SES_SESCEL';
  Configuracion.FieldFilaCel := 'ID_FILA_SES_SESCEL';
  Configuracion.FieldAvPivotCel := 'ID_AV_PIVOT_SESCEL';
  Configuracion.FieldCantidadCel := 'CANTIDAD_SESCEL';
  Configuracion.FieldAlmacenCel := 'CODIGO_ALM_SESCEL';
  Configuracion.IdFilaFijo := 1;
  Configuracion.MaxColumnas := FEntorno.MaxColumnas;
  Configuracion.Persistencia := CrearPersistenciaGridTallasInline(
    FEntorno.Conexion,
    CrearConfigPersistenciaTallasInline(Configuracion));
  FGestor := TGestorGridTallas.Create(Configuracion);
  for iColumna := 0 to High(FColumnas) do
  begin
    if Assigned(FColumnas[iColumna]) then
      TcxCurrencyEditProperties(
        FColumnas[iColumna].Properties).OnEditValueChanged :=
        CeldaTallaCambiada;
  end;
end;

procedure TCoordinadorTallasSesion.CeldaTallaCambiada(ASender: TObject);
begin
  if Assigned(FGestor) then
  begin
    FGestor.PersistirCeldaActiva(ASender);
    if Assigned(FEntorno.RefrescarTotalesSesion) then
      FEntorno.RefrescarTotalesSesion();
    // El refresco de totales repinta el grid y borra los Values[] no
    // ligados: hay que volver a publicar las cantidades.
    FGestor.CargarCantidadesTodasLineas;
  end;
end;

function TCoordinadorTallasSesion.EsFormatoDistribuido: Boolean;
begin
  Result := Assigned(FCabecera) and (not FCabecera.IsEmpty) and
            (FCabecera.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

function TCoordinadorTallasSesion.PuedeElegirSistema: Boolean;
begin
  Result := Assigned(FLineas) and (not FLineas.IsEmpty);
  if Result and SameText(FLineas.FieldByName(
       'ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR') then
  begin
    // Al reusar un modelo el sistema queda fijado al del articulo:
    // cambiarlo descuadraria los SKU ya creados.
    MessageDlg(SErrorCambiarSistemaTallasModeloExistente,
               mtInformation, [mbOk], 0);
    Result := False;
  end;
end;

procedure TCoordinadorTallasSesion.AplicarSistemaElegido(
  ASender: TObject; AIdNuevo: Integer);
begin
  if not (FLineas.State in [dsEdit, dsInsert]) then
    FLineas.Edit;
  FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := AIdNuevo;
  if ASender is TcxCustomEdit then
    TcxCustomEdit(ASender).EditValue := AIdNuevo;
  // El sistema elegido a mano pasa a ser el defecto del DOCUMENTO para
  // la proxima linea nueva.
  if Assigned(FEntorno.FijarTallajeDefecto) then
    FEntorno.FijarTallajeDefecto(AIdNuevo);
  if Assigned(FGestor) then
  begin
    if FGestor.ValidarSistemaSeleccionado then
    begin
      FGestor.RecalcularMaxColumnas;
      FGestor.ActualizarCaptionsLineaActiva;
    end
    else if ASender is TcxCustomEdit then
      TcxCustomEdit(ASender).EditValue := Null;
  end;
end;

// Listbox owner-drawn sin marco con las columnas Sistema / Desde /
// Hasta, posicionado justo debajo del editor.
procedure TCoordinadorTallasSesion.AbrirSelector(ASender: TObject;
  const ABusquedaInicial: string);
var
  iActual: Integer;
  iNuevo: Integer;
  Punto: TPoint;
  iAncho: Integer;
  Editor: TWinControl;
begin
  if Length(FOpciones) = 0 then
    MessageDlg(SErrorSistemasTallasSesionNoDisponibles,
               mtInformation, [mbOk], 0)
  else if PuedeElegirSistema then
  begin
    iActual := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    Punto.X := -1;
    Punto.Y := -1;
    iAncho := cAnchoSelectorTallas;
    if ASender is TWinControl then
    begin
      Editor := TWinControl(ASender);
      Punto := Editor.ClientToScreen(Point(0, Editor.Height));
      iAncho := Editor.Width;
      if iAncho < cAnchoSelectorTallas then
        iAncho := cAnchoSelectorTallas;
    end;
    if SeleccionarConjuntoTalla(FOpciones, iActual, iNuevo,
         Punto.X, Punto.Y, iAncho, ABusquedaInicial) then
      AplicarSistemaElegido(ASender, iNuevo);
  end;
end;

// Formato distribuido: las cantidades viven por almacen, asi que la
// edicion inline se sustituye por el modal distribuidor.
procedure TCoordinadorTallasSesion.AbrirDistribuidor(
  const ACodigoKit: string);
var
  Modal: TfrmModalDistribuidor;
  iLinea: Integer;
  iConjunto: Integer;
begin
  iLinea := 0;
  iConjunto := 0;
  if Assigned(FLineas) and (not FLineas.IsEmpty) then
  begin
    iLinea := FLineas.FieldByName('LINEA_SESLIN').AsInteger;
    iConjunto := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  end;
  if (iLinea > 0) and (iConjunto > 0) then
  begin
    // Persistir la edicion pendiente para que el modal vea el estado
    // consistente de la linea (en particular ID_AC_PIVOT_SESLIN).
    if FLineas.State in [dsEdit, dsInsert] then
      FLineas.Post;
    Modal := TfrmModalDistribuidor.Create(
      Application,
      FEntorno.RepositorioDistribuidor);
    // Evitamos el caFree heredado para poder liberar a mano sin riesgo
    // de doble liberacion.
    Modal.OnClose := nil;
    try
      Modal.Preparar(FEntorno.Conexion, FEntorno.Usuario,
        FCabecera.FieldByName('SERIE_SES').AsString,
        FCabecera.FieldByName('NUMERO_SES').AsString,
        iLinea, iConjunto,
        Trim(FCabecera.FieldByName('CODIGO_PRV_SES').AsString),
        ACodigoKit);
      Modal.ShowModal;
      if Modal.Confirmado then
      begin
        // ORDEN CRITICO: el Refresh resetea el DataController y borra
        // los Values[] no-bound, asi que la recarga de cantidades va
        // DESPUES del Refresh.
        if Assigned(FGestor) then
          FGestor.RefrescarTotalesLineaActual;
        FLineas.Refresh;
        if Assigned(FGestor) then
        begin
          FGestor.InvalidarCache;
          FGestor.CargarCantidadesTodasLineas;
        end;
        if Assigned(FEntorno.RefrescarTotalesSesion) then
          FEntorno.RefrescarTotalesSesion();
      end;
    finally
      FreeAndNil(Modal);
    end;
  end;
end;

function TCoordinadorTallasSesion.EsColumnaTalla(AItem: TObject;
  out APosicion: Integer): Boolean;
var
  Columna: TcxGridColumn;
begin
  Result := False;
  APosicion := 0;
  if AItem is TcxGridColumn then
  begin
    Columna := TcxGridColumn(AItem);
    if (Columna.Tag >= 1) and (Columna.Tag <= Length(FColumnas)) and
       (Columna = FColumnas[Columna.Tag - 1]) then
    begin
      APosicion := Columna.Tag;
      Result := True;
    end;
  end;
end;

// Cada fila puede tener un sistema distinto: las posiciones que exceden
// el conjunto de esa fila se sombrean. El bloqueo efectivo de edicion
// lo hace AjustarPermisoEdicion.
function TCoordinadorTallasSesion.SombrearCeldaFueraDeConjunto(
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  APosicion: Integer): Boolean;
var
  ColumnaConjunto: TcxGridColumn;
  vConjunto: Variant;
  iConjunto: Integer;
  Posiciones: TArrPosConjunto;
begin
  Result := False;
  ColumnaConjunto := FEntorno.Vista.GetColumnByFieldName(
    'ID_AC_PIVOT_SESLIN');
  if (ColumnaConjunto <> nil) and Assigned(FGestor) then
  begin
    vConjunto := AViewInfo.GridRecord.Values[ColumnaConjunto.Index];
    if (not VarIsNull(vConjunto)) and (not VarIsEmpty(vConjunto)) and
       VarIsNumeric(vConjunto) then
    begin
      iConjunto := vConjunto;
      if iConjunto > 0 then
      begin
        Posiciones := FGestor.GetPosicionesConjunto(iConjunto);
        if APosicion > Length(Posiciones) then
        begin
          ACanvas.Brush.Color := cColorCeldaInactiva;
          ACanvas.FillRect(AViewInfo.Bounds);
          Result := True;
        end;
      end;
    end;
  end;
end;

// La columna selector esta bound al ID numerico: pintamos el NOMBRE_AC
// para que la celda muestre el nombre legible.
function TCoordinadorTallasSesion.DibujarNombreSistema(
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  vConjunto: Variant;
  iConjunto: Integer;
  sNombre: string;
  Rectangulo: TRect;
begin
  sNombre := '';
  vConjunto := AViewInfo.GridRecord.Values[AViewInfo.Item.Index];
  if (not VarIsNull(vConjunto)) and (not VarIsEmpty(vConjunto)) and
     VarIsNumeric(vConjunto) then
  begin
    iConjunto := vConjunto;
    if (iConjunto <= 0) or
       (not FNombres.TryGetValue(iConjunto, sNombre)) then
      sNombre := '';
  end;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AViewInfo.Params.Color;
  ACanvas.FillRect(AViewInfo.Bounds);
  if sNombre <> '' then
  begin
    Rectangulo := AViewInfo.Bounds;
    Inc(Rectangulo.Left, 4);
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(sNombre, Rectangulo,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    ACanvas.Brush.Style := bsSolid;
  end;
  Result := True;
end;

function TCoordinadorTallasSesion.DibujarCelda(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  iPosicion: Integer;
begin
  Result := False;
  if AViewInfo.GridRecord <> nil then
  begin
    if EsColumnaTalla(AViewInfo.Item, iPosicion) then
      Result := SombrearCeldaFueraDeConjunto(
        ACanvas, AViewInfo, iPosicion)
    else if AViewInfo.Item = FEntorno.ColumnaSelector then
      Result := DibujarNombreSistema(ACanvas, AViewInfo);
  end;
end;

procedure TCoordinadorTallasSesion.AjustarPermisoEdicion(
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  iPosicion: Integer;
  iConjunto: Integer;
  Posiciones: TArrPosConjunto;
begin
  if EsColumnaTalla(AItem, iPosicion) and Assigned(FGestor) and
     Assigned(FLineas) and (not FLineas.IsEmpty) then
  begin
    iConjunto := FLineas.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    if iConjunto > 0 then
    begin
      Posiciones := FGestor.GetPosicionesConjunto(iConjunto);
      if iPosicion > Length(Posiciones) then
        AAllow := False
      else if EsFormatoDistribuido then
      begin
        // El grid principal muestra la SUMA por talla: el reparto por
        // almacen se hace en el distribuidor.
        AAllow := False;
        AbrirDistribuidor;
      end;
    end;
  end;
end;

function TCoordinadorTallasSesion.EditorActivo: TcxCustomEdit;
begin
  Result := nil;
  if FEntorno.Vista.Controller.EditingController <> nil then
  begin
    FEntorno.Vista.Controller.EditingController.ShowEdit;
    Result := FEntorno.Vista.Controller.EditingController.Edit;
  end;
end;

// Ctrl+Enter sobre una columna 'editbutton' dispara el click de su
// primer boton, igual que pulsar el ellipsis.
function TCoordinadorTallasSesion.DispararBotonColumnaActiva: Boolean;
var
  Activo: TWinControl;
  Columna: TcxGridColumn;
  Propiedades: TcxButtonEditProperties;
begin
  Result := False;
  Columna := nil;
  Activo := Screen.ActiveControl;
  if (Activo <> nil) and
     ((Activo = FEntorno.Contenedor) or
      FEntorno.Contenedor.ContainsControl(Activo)) then
    Columna := FEntorno.Vista.Controller.FocusedColumn;
  if (Columna <> nil) and
     (Columna.Properties is TcxButtonEditProperties) then
  begin
    Propiedades := TcxButtonEditProperties(Columna.Properties);
    if (Propiedades.Buttons.Count > 0) and
       Assigned(Propiedades.OnButtonClick) then
    begin
      Propiedades.OnButtonClick(EditorActivo, 0);
      Result := True;
    end;
  end;
end;

function TCoordinadorTallasSesion.ProcesarTeclaEditor(
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var AKey: Word;
  AShift: TShiftState): Boolean;
var
  sBusqueda: string;
  Propiedades: TcxButtonEditProperties;
begin
  Result := False;
  sBusqueda := TextoBusquedaTallaje(AKey, AShift);
  if (AItem = FEntorno.ColumnaSelector) and (sBusqueda <> '') then
  begin
    AbrirSelector(AEdit, sBusqueda);
    AKey := 0;
    Result := True;
  end
  // Red de seguridad por si el Ctrl+Enter llega ya dentro del editor.
  else if (AKey = VK_RETURN) and (AShift = [ssCtrl]) and
          (AItem is TcxGridColumn) and
          (TcxGridColumn(AItem).Properties is TcxButtonEditProperties) then
  begin
    Propiedades := TcxButtonEditProperties(
      TcxGridColumn(AItem).Properties);
    if (Propiedades.Buttons.Count > 0) and
       Assigned(Propiedades.OnButtonClick) then
    begin
      Propiedades.OnButtonClick(AEdit, 0);
      AKey := 0;
      Result := True;
    end;
  end;
end;

function TCoordinadorTallasSesion.ProcesarTeclaFormulario(var AKey: Word;
  AShift: TShiftState): Boolean;
var
  Activo: TWinControl;
  Columna: TcxGridColumn;
  Editor: TcxCustomEdit;
  sBusqueda: string;
begin
  Result := False;
  Columna := nil;
  Activo := Screen.ActiveControl;
  if (Activo <> nil) and
     ((Activo = FEntorno.Contenedor) or
      FEntorno.Contenedor.ContainsControl(Activo)) then
    Columna := FEntorno.Vista.Controller.FocusedColumn;
  sBusqueda := TextoBusquedaTallaje(AKey, AShift);
  if (sBusqueda <> '') and (Columna = FEntorno.ColumnaSelector) then
  begin
    Editor := EditorActivo;
    if Editor <> nil then
      AbrirSelector(Editor, sBusqueda)
    else
      AbrirSelector(Activo, sBusqueda);
    AKey := 0;
    Result := True;
  end
  // Ctrl+Enter abre el selector de la columna editbutton enfocada antes
  // de que la navegacion Enter->Tab del grid mueva el foco.
  else if (AKey = VK_RETURN) and (AShift = [ssCtrl]) and
          DispararBotonColumnaActiva then
  begin
    AKey := 0;
    Result := True;
  end;
end;

end.
