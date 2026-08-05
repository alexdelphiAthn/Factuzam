{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de traspasos entre almacenes (TPV, F3 del menú de caja).        }
{    Tres modos en una barra superior: Traspaso (origen propio -> destino      }
{    ESTANDAR), Solicitar (pido a otro almacén) y Atender (sirvo una           }
{    solicitud que me han hecho). F12 con ticket / F11 sin ticket.             }
{    Ver DESARROLLOS EN CURSO/traspasos_caja.md.                               }
{******************************************************************************}
unit inMtoTraspasoOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, inMtoFrmBase, cxGraphics,
  cxControls,
  cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit,
  cxButtonEdit, cxSpinEdit, cxDropDownEdit, cxButtons, cxClasses, cxGridLevel,
  cxGridCustomTableView, cxGridCustomView, cxGridTableView, cxGridDBTableView,
  cxGrid, cxSplitter, Vcl.Imaging.PngImage, System.Generics.Collections,
  Data.DB, Datasnap.DBClient, UniDataTraspaso,
  inLibTraspasoTicket, inLibGridArticulos, inLibArticulosValidadorIntf,
  inLibPermisosIntf, inLibGenBusq, inLibFotos, inLibAtributosPaleta,
  Vcl.Menus, dxCoreGraphics, JvComponentBase, JvEnterTab,
  cxLocalization, inLibLectorScanner, cxStyles, cxDBData, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, inLibCajaVentaIntf, inLibCajaVentanasIntf,
  inLibTraspasoOpePersistenciaIntf, inLibArticulosAtributosIntf,
  inLibTraspasoTicketIntf, inLibCajaPantallaInyeccion;

type
  TfrmMtoOpeTraspaso = class(TfrmBase, ITraspasoCaja)
    pnlModos: TPanel;
    btnModoTraspaso: TcxButton;
    btnModoSolicitar: TcxButton;
    btnModoAtender: TcxButton;
    pnlTop: TPanel;
    lblOrigen: TcxLabel;
    txtOrigen: TcxTextEdit;
    lblDestino: TcxLabel;
    cboDestino: TcxComboBox;
    lblEmpleado: TcxLabel;
    txtEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    pnlCentro: TPanel;
    pnlBottom: TPanel;
    lblTotal: TcxLabel;
    btnF11: TcxButton;
    btnF12: TcxButton;
    // Rejillas y panel de stock sacados al dfm (antes se creaban en codigo):
    // la rejilla de lineas (FGrid/FView) y la de stock pivotado
    // (FStockGrid/FStockView) dentro de FStockPanel, con la foto del articulo
    // (FFotoImg) y los splitters. Las columnas siguen creandose en runtime.
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    lvlLineas: TcxGridLevel;
    FStockPanel: TPanel;
    FFotoPanel: TPanel;
    FFotoImg: TImage;
    FFotoSplitter: TcxSplitter;
    FStockGrid: TcxGrid;
    FStockView: TcxGridDBTableView;
    lvlStock: TcxGridLevel;
    FStockSplitter: TcxSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
                          Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnModoClick(Sender: TObject);
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure txtEmpleadoExit(Sender: TObject);
    procedure txtEmpleadoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure cboDestinoPropertiesChange(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    FGridCtrl: TGridArticulosLineas;
    FComboCodigos: TStringList;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFecha: TDateTime;
    FModo: TModoTraspaso;
    FVerCoste: Boolean;
    FStockDatos: TDataSet;
    FStockDs: TDataSource;
    FNavDs: TDataSource;
    FColUds: TcxGridDBColumn;
    FColPedidas: TcxGridDBColumn;
    FColMotivo: TcxGridDBColumn;
    FQModalSolic: TDataSet;
    FConsultaStock: IResultadoConsultaCaja;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioPersistencia: IRepositorioTraspasoOpe;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributosArticulos: IArticulosAtributosLookup;
    FRepositorioTraspasoTicket: IRepositorioTraspasoTicket;
    // Lectura con pistola a nivel de FORMULARIO (igual que inMtoCajaOpe): la
    // mecanica (trama STX/ETX + rafaga por velocidad) la lleva TLectorScanner.
    // En modo "consumir" y pasivo dentro de la rejilla (ahi resuelve la celda
    // via inLibGridArticulos); el detector por velocidad cubre el foco fuera.
    FLector: TLectorScanner;
    procedure ValidarDependencias;
    procedure AgregarLineaExterna(
      const ALinea: TLineaCargaTraspaso;
      var ANumeroLinea: Integer);
    procedure CargarLineasExternas(
      const ALineas: TLineasCargaTraspaso);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    function  LectorEsControlRejilla(AControl: TControl): Boolean;
    procedure ProcesarLecturaScanner(const ACodigo: string);
    function ConsolidarSiExiste(const ASku: string): Boolean;
    procedure ConstruirGrid;
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
    procedure AsegurarLineaNueva;
    procedure EnfocarSegunModo;
    procedure AbrirModalSolicitudes;
    procedure ModalImprimirClick(Sender: TObject);
    procedure CerrarSolicitudCargada;
    procedure DenegarSolicitudCargada;
    procedure AbrirMisPeticiones;
    procedure AplicarModo(AModo: TModoTraspaso);
    procedure CargarCombo;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    procedure ActualizarTotal;
    procedure QuitarLinea;
    procedure EjecutarTraspaso(AConTicket: Boolean);
    procedure EjecutarTraspasoInterno(AConTicket: Boolean);
    procedure EnviarSolicitud;
    function EmpleadoValido: Boolean;
    procedure BuscarEmpleado;
    // Consulta rapida de stock (banda inferior, igual que inMtoCajaOpe): una
    // rejilla pivotada (almacenes en filas, tallas en columnas) + foto del
    // articulo enfocado. Se refresca al resolver un SKU o al cambiar de linea.
    procedure ConstruirPanelStock;
    procedure ConsultarStock(const ACodigo: string);
    procedure RefrescarFotoStock(const ACodArt, ACodSku: string);
    procedure ActualizarStockYFoto;
    procedure NavDataChange(Sender: TObject; Field: TField);
    procedure StockViewCustomDrawCell(Sender: TcxCustomGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
              var ADone: Boolean);
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion); reintroduce; overload;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasTraspasoCaja); reintroduce;
      overload;
    function FormularioTraspaso: TCustomForm;
    procedure PrepararValores(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                               ACaja: string; AFecha: TDateTime);
    procedure PrepararCargaExterna(
      AModo: TModoVentanaTraspaso;
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime;
      const ALineas: TLineasCargaTraspaso);
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja, inLibMsgComun, UniDataModoTallas,
  UniDataGridArticulosRepositorio;

constructor TfrmMtoOpeTraspaso.Create(AOwner: TComponent);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasTraspasoCaja);
begin
  ADependencias.Validar;
  FRepositorioConsultas := ADependencias.Consultas;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FValidadorArticulos := ADependencias.ValidadorArticulos;
  FLookupAtributosArticulos := ADependencias.AtributosArticulos;
  FRepositorioTraspasoTicket := ADependencias.Ticket;
  inherited Create(AOwner, APermisos);
end;

procedure TfrmMtoOpeTraspaso.ValidarDependencias;
var
  Dependencias: TDependenciasTraspasoCaja;
begin
  Dependencias.Consultas := FRepositorioConsultas;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.ValidadorArticulos := FValidadorArticulos;
  Dependencias.AtributosArticulos := FLookupAtributosArticulos;
  Dependencias.Ticket := FRepositorioTraspasoTicket;
  Dependencias.Validar;
end;

procedure TfrmMtoOpeTraspaso.FormCreate(Sender: TObject);
begin
  inherited;
  ValidarDependencias;
  KeyPreview := True;
  // Detector del lector de codigo de barras (trama STX/ETX + rafaga por
  // velocidad). Modo "consumir" y pasivo en la rejilla: la lectura en la celda
  // de articulo la resuelve inLibGridArticulos; el detector por velocidad solo
  // actua con el foco fuera de la rejilla.
  FLector := TLectorScanner.Create;
  FLector.ConsumirRafaga := True;
  FLector.OmitirEnRejilla := True;
  FLector.OnCodigoLeido := LectorCodigoLeido;
  FLector.OnEsControlRejilla := LectorEsControlRejilla;
  FComboCodigos := TStringList.Create;
  FDatos := TdmTraspaso.Create(Self, ConexionPrincipal);
  // Coste/importe solo para administrador: TienePermiso devuelve True siempre a
  // admin; al resto, oculto por defecto (default False) salvo permiso explicito
  // 'caja.verCoste'. Sin sistema de permisos, oculto.
  FVerCoste := Assigned(Permisos) and
               Permisos.TienePermiso(
                 PERMISO_CAJA_VER_COSTE,
                 paDenegar);
  // Los labels los pone transparentes TfrmBase.FormCreate (via inherited).
  ConstruirGrid;
  ConstruirPanelStock;
  // Elegir una solicitud en el desplegable (modo Atender) la carga sola.
  cboDestino.Properties.OnChange := cboDestinoPropertiesChange;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLector);
  // Evitar callbacks de stock/foto durante el desmontaje.
  if Assigned(FNavDs) then
    FNavDs.OnDataChange := nil;
  if Assigned(FStockDs) then
    FStockDs.DataSet := nil;
  FStockDatos := nil;
  FConsultaStock := nil;
  FRepositorioTraspasoTicket := nil;
  FLookupAtributosArticulos := nil;
  FValidadorArticulos := nil;
  FRepositorioConsultas := nil;
  FRepositorioPersistencia := nil;
  FreeAndNil(FGridCtrl);
  FreeAndNil(FComboCodigos);
  // FDatos y los componentes runtime (grid/foto/datasources) los libera el
  // Owner (Self) automáticamente.
  inherited;
end;

procedure TfrmMtoOpeTraspaso.FormShow(Sender: TObject);
begin
  // Foco inicial segun el modo. En Traspaso dejamos el grid en modo edicion
  // (editor de articulo abierto) para poder escanear directamente sin pulsar
  // Enter; el almacen destino trae su valor por defecto y se valida al grabar.
  EnfocarSegunModo;
end;

procedure TfrmMtoOpeTraspaso.ConstruirGrid;
var
  Campos: TCamposGridArt;
  Col: TcxGridDBColumn;
  i: Integer;
begin
  // FGrid/FView/lvlLineas viven ya en el dfm; aqui solo se cablea el origen de
  // datos (el cds esta en un data module creado en runtime) y se construyen las
  // columnas: primero las dinamicas (articulo + tallas/colores, via la
  // controladora, que hace ClearItems) y despues las fijas del traspaso, para
  // respetar ese orden.
  FView.DataController.DataSource := FDatos.dsLineas;
  FView.OptionsData.Editing := True;
  FView.OptionsData.Inserting := True;
  FView.OptionsData.Deleting := True;
  FView.OptionsView.GroupByBox := False;
  Campos.CodigoArt := 'CODIGO_ART';
  Campos.CodigoUnidad := 'CODIGO_UNIDAD';
  Campos.Descripcion := 'DESCRIPCION';
  Campos.Cantidad := 'CANTIDAD';
  Campos.NumAtributos := 'NUM_ATRIBUTOS';
  for i := 1 to 5 do
  begin
    Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
    Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
  end;
  // La controladora crea la columna de artículo + las de talla/color.
  FGridCtrl := TGridArticulosLineas.Create(
    ConexionPrincipal,
    FView,
    FDatos.cdsLineas,
    Campos,
    ContextoSesion,
    BusquedaVisual,
    CrearBusquedaSkusTallas(ConexionPrincipal),
    CrearConsultaArticulosGridUniDAC(ConexionPrincipal),
    FValidadorArticulos,
    FLookupAtributosArticulos,
    RegistroLog);
  FGridCtrl.OnResuelto := GridResuelto;
  FGridCtrl.Construir;
  // Columnas propias del traspaso.
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColDescripcionTraspaso;
  Col.DataBinding.FieldName := 'DESCRIPCION';
  Col.Options.Editing := False;
  Col.Width := 200;
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColUdsTraspaso;
  Col.DataBinding.FieldName := 'CANTIDAD';
  Col.Width := 50;
  // Al atender pasa a ser "lo que sirvo" (editable); 0 = denegar esa linea.
  FColUds := Col;
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColCosteTraspaso;
  Col.DataBinding.FieldName := 'PRECIO_COSTE';
  Col.Options.Editing := False;
  Col.Width := 70;
  // Oculta el coste a empleados sin permiso (el valor se sigue calculando y
  // guardando en el movimiento; solo se oculta de la vista).
  Col.Visible := FVerCoste;
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColStockOrigenTraspaso;
  Col.DataBinding.FieldName := 'STOCK_ORIGEN';
  Col.Options.Editing := False;
  Col.Width := 70;
  // Columnas que solo se usan al ATENDER (ocultas en traspaso/solicitar; las
  // muestra AplicarModo): lo pedido (referencia) y el motivo si se deniega.
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColPedidasTraspaso;
  Col.DataBinding.FieldName := 'CANTIDAD_PEDIDA';
  Col.Options.Editing := False;
  Col.Width := 60;
  Col.Visible := False;
  FColPedidas := Col;
  Col := FView.CreateColumn;
  Col.Caption := SCaptionColMotivoRechazoTraspaso;
  Col.DataBinding.FieldName := 'MOTIVO';
  Col.Width := 180;
  Col.Visible := False;
  FColMotivo := Col;
end;

procedure TfrmMtoOpeTraspaso.ConstruirPanelStock;
begin
  // El panel de stock, los splitters, la foto y la rejilla pivotada viven ya en
  // el dfm (FStockPanel/FFotoPanel/FFotoImg/FStockGrid/FStockView). Aqui solo
  // queda lo que no se puede fijar en diseno: las opciones de la vista, el
  // dibujo del swatch y el cableado de datos (la rejilla cuelga de una query y
  // un data module creados en runtime).
  FStockView.OptionsData.Editing := False;
  FStockView.OptionsData.Inserting := False;
  FStockView.OptionsData.Deleting := False;
  FStockView.OptionsSelection.CellSelect := False;
  FStockView.OptionsView.GroupByBox := False;
  FStockView.OptionsView.ColumnAutoWidth := True;
  FStockView.OptionsCustomize.ColumnFiltering := False;
  FStockView.OnCustomDrawCell := StockViewCustomDrawCell;
  FStockDs := TDataSource.Create(Self);
  FStockView.DataController.DataSource := FStockDs;
  // Refrescar stock+foto al moverse por las lineas (cambio de registro).
  FNavDs := TDataSource.Create(Self);
  FNavDs.DataSet := FDatos.cdsLineas;
  FNavDs.OnDataChange := NavDataChange;
end;

procedure TfrmMtoOpeTraspaso.ConsultarStock(const ACodigo: string);
var
  i: Integer;
  Mapa: TDictionary<string, string>;
  Fld: TField;
  bTodoCero: Boolean;
begin
  // Misma logica que inMtoCajaOpe.ConsultarStock: abrir el SP, construir las
  // columnas dinamicas, alinear cabeceras y ajustar anchos (con swatch en la
  // primera columna). Se omiten los cronometros de perf.
  if (ACodigo <> '') and Assigned(FStockView) then
  begin
    FStockDs.DataSet := nil;
    FConsultaStock := FRepositorioConsultas.ConsultarStock(ACodigo);
    FStockDatos := FConsultaStock.DataSet;
    FStockDs.DataSet := FStockDatos;
    FStockView.BeginUpdate;
    try
      FStockView.ClearItems;
      if not FStockDatos.IsEmpty then
      begin
        FStockView.DataController.CreateAllItems;
        for i := 0 to FStockView.ColumnCount - 1 do
        begin
          if i <= 1 then
            FStockView.Columns[i].HeaderAlignmentHorz := taLeftJustify
          else
            FStockView.Columns[i].HeaderAlignmentHorz := taRightJustify;
        end;
      end;
    finally
      FStockView.EndUpdate;
    end;
    if FStockDatos.Active and (not FStockDatos.IsEmpty) then
    begin
      FStockView.BeginUpdate;
      try
        try
          FStockView.ApplyBestFit;
        except
          // ApplyBestFit puede fallar si no hay columnas; lo ignoramos.
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'TraspasoOpe: ApplyBestFit del stock ignorado: ' +
              E.Message);
        end;
        // La primera columna (codigo CODART/COLOR) lleva swatch de color: le
        // sumamos el ancho del cuadradito para que no recorte el texto.
        Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
        if (Mapa <> nil) and (Mapa.Count > 0) and
           (FStockView.ColumnCount > 0) then
          AjustarAnchoColumnaParaSwatch(
            ConexionPrincipal,
            FStockView.Columns[0],
            Mapa);
        // Mostrar solo las tallas con existencias: ocultamos las columnas de
        // talla que esten a cero en todos los almacenes (el SP devuelve una
        // columna por cada talla del articulo, tenga o no stock). No se tocan
        // Codigo/Almacen (texto) ni el Total.
        FStockDatos.DisableControls;
        try
          for i := 0 to FStockView.ColumnCount - 1 do
          begin
            Fld := FStockDatos.FindField(
              FStockView.Columns[i].DataBinding.FieldName);
            if (Fld <> nil) and
               (Fld.DataType in [ftSmallint, ftInteger, ftWord, ftLargeint,
                ftFloat, ftCurrency, ftBCD, ftFMTBcd]) and
               (not SameText(Fld.FieldName, 'Total')) and
               (not SameText(Fld.FieldName, 'Stock_Total')) and
               (not SameText(Fld.FieldName, 'Stock Total')) then
            begin
              bTodoCero := True;
              FStockDatos.First;
              while (not FStockDatos.Eof) and bTodoCero do
              begin
                if Fld.AsFloat <> 0 then
                  bTodoCero := False;
                FStockDatos.Next;
              end;
              if bTodoCero then
                FStockView.Columns[i].Visible := False;
            end;
          end;
          FStockDatos.First;
        finally
          FStockDatos.EnableControls;
        end;
      finally
        FStockView.EndUpdate;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.RefrescarFotoStock(const ACodArt, ACodSku: string);
var
  info: TFotoInfo;
  sRuta: string;
  png: TPngImage;
begin
  if Assigned(FFotoImg) then
  begin
    FFotoImg.Picture.Assign(nil);
    if ACodArt <> '' then
    begin
      info := FotosArticulos.Resolver(ACodArt, ACodSku);
      sRuta := FotosArticulos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        png := TPngImage.Create;
        try
          png.LoadFromFile(sRuta);
          FFotoImg.Picture.Assign(png);
        finally
          FreeAndNil(png);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ActualizarStockYFoto;
var
  sArt, sSku: string;
begin
  if (FDatos = nil) or (FDatos.cdsLineas = nil) or
     (not FDatos.cdsLineas.Active) or FDatos.cdsLineas.IsEmpty then
  begin
    // Sin lineas: vaciar stock y foto.
    RefrescarFotoStock('', '');
    if Assigned(FStockDs) then
      FStockDs.DataSet := nil;
    FStockDatos := nil;
    FConsultaStock := nil;
    if Assigned(FStockView) then
      FStockView.ClearItems;
  end
  else
  begin
    sArt := Trim(FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // Consultamos por el articulo padre para ver todas las tallas/colores en
    // todos los almacenes; la foto usa el SKU concreto si existe. Si la linea
    // esta en blanco (linea nueva tras resolver) dejamos lo ultimo mostrado en
    // vez de parpadear a vacio.
    if sArt <> '' then
    begin
      ConsultarStock(sArt);
      RefrescarFotoStock(sArt, sSku);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.NavDataChange(Sender: TObject; Field: TField);
begin
  // Solo al cambiar de registro (Field = nil), no en cada cambio de columna.
  if Field = nil then
    ActualizarStockYFoto;
end;

procedure TfrmMtoOpeTraspaso.StockViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // El swatch de color solo aplica a la primera columna visible (Codigo, que
  // lleva "CODART/COLOR"). En las demas (almacen, tallas) el texto — p.ej. el
  // "0" de una talla — podia colar como valor de atributo y pintar cuadraditos
  // donde no toca. Mismo criterio que la rejilla de stock de caja.
  if (AViewInfo <> nil) and (AViewInfo.Item <> nil) and
     (AViewInfo.Item.VisibleIndex = 0) and
     PintarCeldaSwatchSiAplica(ConexionPrincipal,ACanvas, AViewInfo, nil) then
    ADone := True;
end;

procedure TfrmMtoOpeTraspaso.GridResuelto(const ACodArt, ASku,
                                          ADescripcion: string;
                                          ACompleto: Boolean);
var
  sAlmacenOrigen, sKey: string;
begin
  if not ACompleto then
    ActualizarTotal
  else
  begin
    // Punto comun de resolucion (escaneo Codigo+CR via celda, STX/ETX o
    // teclado). Si la SKU/articulo ya esta en otra linea, sumamos alli y
    // descartamos esta (consolidacion, como en caja). La clave es lo que se
    // acaba de guardar en CODIGO_UNIDAD de la linea actual.
    sKey := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    if (sKey <> '') and ConsolidarSiExiste(sKey) then
    begin
      // Descartamos la linea recien resuelta para no duplicar. Cancel si sigue
      // en edicion; si el clon ya la dejo grabada con esa misma SKU, la
      // borramos (mismo patron que caja). Luego garantizamos una linea blanca.
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
        FDatos.cdsLineas.Cancel;
      if (not FDatos.cdsLineas.IsEmpty) and
         (Trim(FDatos.cdsLineas.FieldByName(
           'CODIGO_UNIDAD').AsString) = sKey) then
        FDatos.cdsLineas.Delete;
      AsegurarLineaNueva;
      ActualizarTotal;
    end
    else
    begin
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
      begin
        sAlmacenOrigen :=
          FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
        FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
          FDatos.ObtenerCosteMedio(ASku, sAlmacenOrigen);
        FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
          FDatos.ObtenerStock(ASku, sAlmacenOrigen);
      end;
      ActualizarTotal;
      ConsultarStock(ACodArt);
      RefrescarFotoStock(ACodArt, ASku);
      // Otra linea en blanco para seguir metiendo (solo traspaso/solicitar).
      if FModo <> mtAtender then
        AsegurarLineaNueva;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.PrepararValores(AModo: TModoTraspaso;
                          const AEmpresa, AAlmacen, ACaja: string;
                          AFecha: TDateTime);
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFecha := AFecha;
  AplicarModo(AModo);
  // Empleado responsable por defecto desde parametros de caja (igual que
  // inMtoCajaOpe): si esta activado, se rellena al abrir la pantalla.
  if Assigned(ParametrosCaja) and
     ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False) then
  begin
    txtEmpleado.Text :=
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', '');
    if Trim(txtEmpleado.Text) <> '' then
      txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.FormularioTraspaso: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmMtoOpeTraspaso.AgregarLineaExterna(
  const ALinea: TLineaCargaTraspaso;
  var ANumeroLinea: Integer);
var
  iAtributo: Integer;
  sAlmacenOrigen: string;
begin
  if (Trim(ALinea.CodigoSku) <> '') and
     FDatos.cdsLineas.Locate(
       'CODIGO_UNIDAD',
       ALinea.CodigoSku,
       []) then
  begin
    FDatos.cdsLineas.Edit;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat + ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end
  else
  begin
    Inc(ANumeroLinea, 10);
    sAlmacenOrigen :=
      FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.FieldByName('LINEA').AsString :=
      Format('%.4d', [ANumeroLinea]);
    FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString :=
      ALinea.CodigoArticulo;
    FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
      ALinea.CodigoSku;
    FDatos.cdsLineas.FieldByName('DESCRIPCION').AsString :=
      ALinea.Descripcion;
    FDatos.cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger :=
      ALinea.NumeroAtributos;
    for iAtributo := 1 to 5 do
    begin
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_VALOR', [iAtributo])).AsString :=
        ALinea.ValoresAtributos[iAtributo];
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_NOMBRE', [iAtributo])).AsString :=
        ALinea.NombresAtributos[iAtributo];
    end;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
      FDatos.ObtenerCosteMedio(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      FDatos.ObtenerStock(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end;
end;

procedure TfrmMtoOpeTraspaso.CargarLineasExternas(
  const ALineas: TLineasCargaTraspaso);
var
  Linea: TLineaCargaTraspaso;
  NumeroLinea: Integer;
  iMaxAtributos: Integer;
  sArticuloAtributos: string;
begin
  NumeroLinea := 0;
  iMaxAtributos := 0;
  sArticuloAtributos := '';
  FDatos.cdsLineas.EmptyDataSet;
  FDatos.cdsLineas.DisableControls;
  try
    for Linea in ALineas do
    begin
      AgregarLineaExterna(Linea, NumeroLinea);
      if Linea.NumeroAtributos > iMaxAtributos then
      begin
        iMaxAtributos := Linea.NumeroAtributos;
        sArticuloAtributos := Linea.CodigoArticulo;
      end;
    end;
  finally
    FDatos.cdsLineas.EnableControls;
  end;
  if iMaxAtributos > 0 then
    FGridCtrl.MostrarColumnasAtributosArticulo(sArticuloAtributos);
  AsegurarLineaNueva;
  ActualizarTotal;
end;

procedure TfrmMtoOpeTraspaso.PrepararCargaExterna(
  AModo: TModoVentanaTraspaso;
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDateTime;
  const ALineas: TLineasCargaTraspaso);
var
  ModoTraspaso: TModoTraspaso;
begin
  if AModo = mvtPeticion then
    ModoTraspaso := mtSolicitar
  else
    ModoTraspaso := mtTraspaso;
  PrepararValores(
    ModoTraspaso,
    AEmpresa,
    AAlmacen,
    ACaja,
    AFecha);
  CargarLineasExternas(ALineas);
end;

procedure TfrmMtoOpeTraspaso.AplicarModo(AModo: TModoTraspaso);
var
  i: Integer;
begin
  FModo := AModo;
  FDatos.PrepararNuevo(AModo, FEmpresa, FAlmacen, FCaja, FFecha);
  txtOrigen.Text := FAlmacen;
  // El buscador/desplegable de SKU muestra el stock del almacen origen y
  // ordena por stock (los que tienen, primero). Recarga al cambiar de modo.
  FGridCtrl.AlmacenStock :=
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  btnF11.Visible := AModo <> mtSolicitar;
  // Edicion del grid por modo. Al teclear lineas (traspaso / solicitar) todo el
  // grid es editable. Al atender, las lineas vienen de la solicitud: solo se
  // editan las uds a servir y, si se deniega (0), el motivo; el resto
  // bloqueado.
  FView.OptionsData.Inserting := AModo <> mtAtender;
  FView.OptionsData.Deleting := AModo <> mtAtender;
  FView.OptionsData.Editing := True;
  for i := 0 to FView.ColumnCount - 1 do
  begin
    if AModo = mtAtender then
      FView.Columns[i].Options.Editing :=
        (FView.Columns[i] = FColUds) or (FView.Columns[i] = FColMotivo)
    else
      FView.Columns[i].Options.Editing := True;
  end;
  // Pedidas/Motivo solo al atender; "Uds" pasa a "Sirvo" para dejar claro que
  // ahi se teclea lo que se sirve (0 = denegar la linea).
  if Assigned(FColPedidas) then
    FColPedidas.Visible := AModo = mtAtender;
  if Assigned(FColMotivo) then
    FColMotivo.Visible := AModo = mtAtender;
  if Assigned(FColUds) then
  begin
    if AModo = mtAtender then
      FColUds.Caption := SCaptionColSirvoTraspaso
    else
      FColUds.Caption := SCaptionColUdsTraspaso;
  end;
  // Captions con tilde en literal: este .pas va en UTF-8 con BOM (igual que
  // inMtoCajaMenu.pas) para que el compilador las lea bien.
  case AModo of
    mtTraspaso:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ConTicket;
    end;
    mtSolicitar:
    begin
      lblOrigen.Caption := SCaptionAlmacenDestino;
      lblDestino.Caption := SCaptionAlmacenOrigen;
      btnF12.Caption := SCaptionF12EnviarSolicitud;
    end;
    mtAtender:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ServirConTicket;
    end;
  end;
  CargarCombo;
  cboDestino.ItemIndex := -1;
  // Sin NewItemRow: dejamos una linea en blanco para teclear (estilo Excel);
  // al completar un SKU el grid anyade otra (GridResuelto). Al atender no.
  if AModo <> mtAtender then
    AsegurarLineaNueva;
  ActualizarTotal;
  EnfocarSegunModo;
end;

procedure TfrmMtoOpeTraspaso.AsegurarLineaNueva;
begin
  // Deja una linea en blanco al final para teclear/escanear el siguiente
  // articulo en el grid (sustituye a la NewItemRow).
  if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
    FDatos.cdsLineas.Post;
  if FDatos.cdsLineas.IsEmpty or
     (Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '') then
  begin
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.Post;
  end;
end;

procedure TfrmMtoOpeTraspaso.FormKeyPress(Sender: TObject; var Key: Char);
begin
  // Toda la deteccion (trama STX/ETX + rafaga por velocidad) la lleva el
  // lector; el codigo leido llega luego por OnCodigoLeido.
  FLector.KeyPress(Key);
end;

procedure TfrmMtoOpeTraspaso.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  ProcesarLecturaScanner(ACodigo);
end;

// El lector permanece pasivo si el foco esta en la rejilla de lineas (ahi la
// lectura la resuelve inLibGridArticulos a nivel de celda).
function TfrmMtoOpeTraspaso.LectorEsControlRejilla(AControl: TControl): Boolean;
var
  C: TControl;
begin
  Result := False;
  C := AControl;
  while (C <> nil) and (not Result) do
  begin
    if C = FGrid then
      Result := True;
    C := C.Parent;
  end;
end;

procedure TfrmMtoOpeTraspaso.ProcesarLecturaScanner(const ACodigo: string);
begin
  // Alta por lectura de pistola con framing STX/ETX. La consolidacion (sumar
  // si la SKU ya esta) la hace GridResuelto, que es el punto comun para todas
  // las vias de resolucion (celda Codigo+CR, STX/ETX o teclado).
  if (Trim(ACodigo) <> '') and Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and FDatos.cdsLineas.Active then
  begin
    AsegurarLineaNueva;
    FDatos.cdsLineas.Last;
    FGridCtrl.ResolverEntrada(Trim(ACodigo));
    // Dejamos el grid enfocado y el editor de articulo abierto para encadenar
    // lecturas sin tener que pulsar Enter (el grid queda en modo edicion).
    if (FGrid <> nil) and FGrid.CanFocus then
      FGrid.SetFocus;
    FGridCtrl.MostrarEditorArticulo;
  end;
end;

function TfrmMtoOpeTraspaso.ConsolidarSiExiste(const ASku: string): Boolean;
var
  Clon: TClientDataSet;
begin
  // Si la SKU ya esta en una linea, le sumamos 1 a la cantidad y no creamos
  // otra (mismo comportamiento que caja). Clon para no mover el cursor visible.
  Result := False;
  if Trim(ASku) <> '' then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(FDatos.cdsLineas, True);
      Clon.First;
      while (not Clon.Eof) and (not Result) do
      begin
        // Saltamos la linea actual (la que se acaba de resolver) por RecNo:
        // solo sumamos sobre OTRA linea con la misma SKU ya grabada.
        if (Clon.FieldByName('CODIGO_UNIDAD').AsString = ASku) and
           (Clon.RecNo <> FDatos.cdsLineas.RecNo) then
        begin
          Clon.Edit;
          Clon.FieldByName('CANTIDAD').AsFloat :=
            Clon.FieldByName('CANTIDAD').AsFloat + 1;
          Clon.Post;
          ActualizarTotal;
          Result := True;
        end;
        Clon.Next;
      end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.EnfocarSegunModo;
begin
  // Solicitar: foco en ALMACEN ORIGEN (a quien pido = cboDestino). Atender:
  // abre el modal de solicitudes abiertas. Traspaso: a teclear en el grid.
  // Solo si el form ya es visible: AplicarModo se llama tambien desde
  // PrepararValores (antes del ShowModal), y enfocar/abrir modal sobre una
  // ventana invisible lanza EInvalidOperation.
  if Showing then
  begin
    case FModo of
      mtSolicitar:
        if cboDestino.CanFocus then
          cboDestino.SetFocus;
      mtAtender:
        AbrirModalSolicitudes;
      mtTraspaso:
        if (FGrid <> nil) and FGrid.CanFocus then
        begin
          FGrid.SetFocus;
          if FGridCtrl <> nil then
            FGridCtrl.MostrarEditorArticulo;
        end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnModoClick(Sender: TObject);
begin
  AplicarModo(TModoTraspaso((Sender as TComponent).Tag));
end;

procedure TfrmMtoOpeTraspaso.CargarCombo;
begin
  cboDestino.Properties.Items.Clear;
  FComboCodigos.Clear;
  // En Atender la solicitud se elige por el modal (F8); el desplegable solo
  // lista almacenes destino en Traspaso/Solicitar.
  if FModo <> mtAtender then
    CargarAlmacenesDestino;
end;

procedure TfrmMtoOpeTraspaso.CargarAlmacenesDestino;
var
  Almacenes: TAlmacenesDestinoTraspaso;
  Almacen: TAlmacenDestinoTraspaso;
begin
  // Destinos: cualquier almacen ESTANDAR activo salvo el propio.
  Almacenes := FRepositorioPersistencia.ListarAlmacenesDestino(FAlmacen);
  for Almacen in Almacenes do
  begin
    FComboCodigos.Add(Almacen.Codigo);
    cboDestino.Properties.Items.Add(
      Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
end;

function TfrmMtoOpeTraspaso.DestinoSeleccionado: string;
var
  sTexto, sCodigo: string;
  i, iSep: Integer;
begin
  if (cboDestino.ItemIndex >= 0) and
     (cboDestino.ItemIndex < FComboCodigos.Count) then
    Result := FComboCodigos[cboDestino.ItemIndex]
  else
  begin
    Result := '';
    sTexto := Trim(cboDestino.Text);
    i := 0;
    while (i < cboDestino.Properties.Items.Count) and
          (i < FComboCodigos.Count) and (Result = '') do
    begin
      if SameText(sTexto, Trim(cboDestino.Properties.Items[i])) then
      begin
        cboDestino.ItemIndex := i;
        Result := FComboCodigos[i];
      end;
      Inc(i);
    end;
    if (Result = '') and (sTexto <> '') then
    begin
      iSep := Pos(' - ', sTexto);
      if iSep > 0 then
        sCodigo := Trim(Copy(sTexto, 1, iSep - 1))
      else
        sCodigo := sTexto;
      i := 0;
      while (i < FComboCodigos.Count) and (Result = '') do
      begin
        if SameText(sCodigo, FComboCodigos[i]) then
        begin
          cboDestino.ItemIndex := i;
          Result := FComboCodigos[i];
        end;
        Inc(i);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ActualizarTotal;
var
  cTotal: Currency;
  bm: TBookmark;
begin
  cTotal := 0;
  if not FDatos.cdsLineas.IsEmpty then
  begin
    FDatos.cdsLineas.DisableControls;
    bm := FDatos.cdsLineas.GetBookmark;
    try
      FDatos.cdsLineas.First;
      while not FDatos.cdsLineas.Eof do
      begin
        cTotal := cTotal +
          FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
          FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
        FDatos.cdsLineas.Next;
      end;
    finally
      FDatos.cdsLineas.GotoBookmark(bm);
      FDatos.cdsLineas.FreeBookmark(bm);
      FDatos.cdsLineas.EnableControls;
    end;
  end;
  // Sin permiso de ver coste, no se muestra el importe (revela coste).
  if FVerCoste then
    lblTotal.Caption := Format(SCaptionImporteTraspaso, [cTotal])
  else
    lblTotal.Caption := '';
end;

procedure TfrmMtoOpeTraspaso.cboDestinoPropertiesChange(Sender: TObject);
begin
  // En Atender la solicitud se elige en el modal (F8), no por el desplegable.
  // Aqui no se hace nada; el combo solo se usa en Traspaso/Solicitar.
end;

procedure TfrmMtoOpeTraspaso.AbrirModalSolicitudes;
var
  Dlg: TForm;
  Grid: TcxGrid;
  View: TcxGridDBTableView;
  Ds: TDataSource;
  pnlBot: TPanel;
  btnAt, btnNo, btnImp, btnSalir: TButton;
  sNum, sSer, sFld: string;
  iRes, i: Integer;
begin
  // Modal de solicitudes PENDIENTES que me toca atender. Tres acciones:
  //   Atender    -> trae la peticion con las cantidades pedidas (editables).
  //   No atender -> trae la peticion y la deniega entera (pide motivo).
  //   Imprimir   -> saca el ticket de la peticion seleccionada (sin cerrar).
  // Se construye en codigo (sin .dfm) porque el buscador generico no admite
  // botones de accion. FQModalSolic vive durante el modal para el boton
  // Imprimir y se libera al final.
  FQModalSolic := FDatos.QuerySolicitudesAbiertas;
  try
    if not FQModalSolic.Active then
      FQModalSolic.Open;
    if FQModalSolic.IsEmpty then
      ShowMessage(SErrorSolicitudesTraspasoPendientesNoEncontradas)
    else
    begin
      Dlg := TForm.CreateNew(Self);
      try
        Dlg.Caption := STituloSolicitudesPendientesAtender;
        Dlg.Position := poOwnerFormCenter;
        Dlg.BorderStyle := bsDialog;
        Dlg.ClientWidth := 760;
        Dlg.ClientHeight := 440;
        pnlBot := TPanel.Create(Dlg);
        pnlBot.Parent := Dlg;
        pnlBot.Align := alBottom;
        pnlBot.Height := 60;
        pnlBot.BevelOuter := bvNone;
        Grid := TcxGrid.Create(Dlg);
        Grid.Parent := Dlg;
        Grid.Align := alClient;
        View := Grid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
        Grid.Levels.Add.GridView := View;
        Ds := TDataSource.Create(Dlg);
        Ds.DataSet := FQModalSolic;
        View.DataController.DataSource := Ds;
        View.OptionsData.Editing := False;
        View.OptionsData.Inserting := False;
        View.OptionsData.Deleting := False;
        View.OptionsSelection.CellSelect := False;
        View.OptionsView.GroupByBox := False;
        View.OptionsView.ColumnAutoWidth := True;
        View.DataController.CreateAllItems;
        // Titulos legibles para las columnas conocidas de la consulta.
        for i := 0 to View.ColumnCount - 1 do
        begin
          sFld := View.Columns[i].DataBinding.FieldName;
          if SameText(sFld, 'NUMERO_TRSOL') then
            View.Columns[i].Caption := SCaptionColNumeroSolicitud
          else if SameText(sFld, 'SERIE_TRSOL') then
            View.Columns[i].Caption := SCaptionColSerieSolicitud
          else if SameText(sFld, 'FECHA_TRSOL') then
            View.Columns[i].Caption := SCaptionColFechaSolicitud
          else if SameText(sFld, 'CODIGO_ALM_DESTINO_TRSOL') then
            View.Columns[i].Caption := SCaptionColPideAlmacen
          else if SameText(sFld, 'ESTADO_TRSOL') then
            View.Columns[i].Caption := SCaptionColEstadoSolicitud
          else if SameText(sFld, 'LINEAS_PEND_TRSOL') then
            View.Columns[i].Caption := SCaptionColLineasSolicitud;
        end;
        btnAt := TButton.Create(Dlg);
        btnAt.Parent := pnlBot;
        btnAt.SetBounds(14, 12, 160, 36);
        btnAt.Caption := SCaptionAtender;
        btnAt.ModalResult := mrYes;
        btnAt.Default := True;
        btnNo := TButton.Create(Dlg);
        btnNo.Parent := pnlBot;
        btnNo.SetBounds(186, 12, 160, 36);
        btnNo.Caption := SCaptionNoAtender;
        btnNo.ModalResult := mrNo;
        btnImp := TButton.Create(Dlg);
        btnImp.Parent := pnlBot;
        btnImp.SetBounds(358, 12, 160, 36);
        btnImp.Caption := SCaptionImprimir;
        btnImp.OnClick := ModalImprimirClick;
        btnSalir := TButton.Create(Dlg);
        btnSalir.Parent := pnlBot;
        btnSalir.SetBounds(606, 12, 140, 36);
        btnSalir.Caption := SCaptionSalir;
        btnSalir.Cancel := True;
        btnSalir.ModalResult := mrCancel;
        Dlg.ActiveControl := Grid;
        iRes := Dlg.ShowModal;
        // La rejilla navega el dataset, asi que la fila enfocada es el registro
        // actual del query. Lo leemos antes de liberar el dialogo.
        sNum := FQModalSolic.FieldByName('NUMERO_TRSOL').AsString;
        sSer := FQModalSolic.FieldByName('SERIE_TRSOL').AsString;
      finally
        FreeAndNil(Dlg);
      end;
      if (sNum <> '') and ((iRes = mrYes) or (iRes = mrNo)) then
      begin
        if FDatos.CargarSolicitud(sNum, sSer) then
        begin
          txtOrigen.Text :=
            FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
          // No atender: arranca con todo a 0 (denegar por defecto). El usuario
          // pone el motivo por linea y, si quiere, sube alguna cantidad para
          // servirla, y confirma con F12 (que reparte servido/denegado).
          // Atender: arranca con las cantidades pedidas.
          if iRes = mrNo then
          begin
            FDatos.cdsLineas.DisableControls;
            try
              FDatos.cdsLineas.First;
              while not FDatos.cdsLineas.Eof do
              begin
                if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
                   <> '' then
                begin
                  FDatos.cdsLineas.Edit;
                  FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
                  FDatos.cdsLineas.Post;
                end;
                FDatos.cdsLineas.Next;
              end;
            finally
              FDatos.cdsLineas.EnableControls;
            end;
          end;
          ActualizarTotal;
        end
        else
          ShowMessage(SErrorCargarSolicitudTraspaso);
      end;
    end;
  finally
    FreeAndNil(FQModalSolic);
  end;
end;

procedure TfrmMtoOpeTraspaso.ModalImprimirClick(Sender: TObject);
var
  sNum, sSer: string;
begin
  // Imprime el ticket de la solicitud seleccionada en el modal, sin cerrarlo.
  if Assigned(FQModalSolic) and FQModalSolic.Active and
     (not FQModalSolic.IsEmpty) then
  begin
    sNum := FQModalSolic.FieldByName('NUMERO_TRSOL').AsString;
    sSer := FQModalSolic.FieldByName('SERIE_TRSOL').AsString;
    if sNum <> '' then
      TTraspasoTicket.ImprimirSolicitud(
        PreviewTicket,
        FRepositorioTraspasoTicket,
        sNum,
        sSer,
        ParametrosCaja.ImpresoraCaja);
  end;
end;

procedure TfrmMtoOpeTraspaso.CerrarSolicitudCargada;
begin
  // Cierra la solicitud cargada (parcial) dejando lineas sin atender. Solo
  // tiene sentido en modo Atender con una solicitud traida.
  if FModo = mtAtender then
  begin
    if Trim(
      FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
      ShowMessage(SErrorSolicitudTraspasoCerrarNoCargada)
    else if MessageDlg(SPreguntaCerrarSolicitudTraspaso,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if FDatos.CerrarSolicitud then
      begin
        ShowMessage(SInfoSolicitudTraspasoCerrada);
        AplicarModo(mtAtender);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.DenegarSolicitudCargada;
var
  sMotivo: string;
begin
  // Deniega TODA la solicitud cargada (atajo F4): pide un motivo, lo marca en
  // cada linea (servir 0) y la resuelve como DENEGADO TOTAL sin mover stock. El
  // solicitante lo vera en su historico (F7). Para denegar solo algunas
  // lineas,// sirve unas con cantidad y deja otras a 0 con su motivo,y pulsa
  // F12.
  if FModo <> mtAtender then
    ShowMessage(SErrorDenegarSolicitudTraspasoModoNoValido)
  else if Trim(FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
    ShowMessage(SErrorSolicitudTraspasoDenegarNoCargada)
  else
  begin
    sMotivo := '';
    if InputQuery(STituloDenegarSolicitudTraspaso,
                  SSolicitudMotivoRechazoTraspaso, sMotivo) then
    begin
      if Trim(sMotivo) = '' then
        ShowMessage(SErrorMotivoDenegacionTraspasoNoIndicado)
      else
      begin
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              FDatos.cdsLineas.Edit;
              FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
              FDatos.cdsLineas.FieldByName('MOTIVO').AsString := sMotivo;
              FDatos.cdsLineas.Post;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        try
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        except
          // Validaciones de negocio: aviso normal (EValidacionTraspaso).
          on E: EValidacionTraspaso do
            ShowMessage(E.Message);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.AbrirMisPeticiones;
var
  Datos: TDataSet;
begin
  // Historico (solo consulta) de las peticiones que YO he hecho (soy el
  // destino que pide): numero,serie,fecha,a quien pedi (origen) y estado,//
  // para saber si se han servido/denegado. Reutiliza el buscador de
  // solicitudes; los titulos los pone el formateador (fza_config_campos).
  Datos := FDatos.QueryMisPeticiones(FAlmacen);
  try
    BusquedaVisual.EjecutarBusquedaDataSet(
      'Mis peticiones',
      Datos,
      'frmMtoSolicitudesSearch');
  finally
    FreeAndNil(Datos);
  end;
end;

procedure TfrmMtoOpeTraspaso.EnviarSolicitud;
var
  sNum, sSer, sOrigen: string;
begin
  if EmpleadoValido then
  begin
    sOrigen := DestinoSeleccionado;
    if sOrigen = '' then
      ShowMessage(SErrorAlmacenOrigenSolicitudNoSeleccionado)
    else
    begin
      try
        if FDatos.GrabarSolicitud(sOrigen, sNum, sSer) then
        begin
          ShowMessage(Format(SInfoSolicitudTraspasoEnviada, [sSer, sNum]));
          // Ticket de la solicitud: cada SKU con stock origen / destino.
          TTraspasoTicket.ImprimirSolicitud(
                                            PreviewTicket,
                                            FRepositorioTraspasoTicket,
                                            sNum, sSer,
                                            ParametrosCaja.ImpresoraCaja);
          AplicarModo(mtSolicitar);
        end;
      except
        // Validaciones de negocio: aviso normal (vease EValidacionTraspaso).
        on E: EValidacionTraspaso do
          ShowMessage(E.Message);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoExit(Sender: TObject);
var
  sCod, sNom: string;
begin
  if Trim(txtEmpleado.Text) = '' then
    lblEmpleadoNombre.Caption := ''
  else if FDatos.ValidarEmpleado(Trim(txtEmpleado.Text), sCod, sNom) then
    lblEmpleadoNombre.Caption := sNom
  else
    lblEmpleadoNombre.Caption := SCaptionEmpleadoNoEncontrado;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoButtonClick(Sender: TObject;
                                                    AButtonIndex: Integer);
begin
  // El boton "..." del editor abre el buscador de empleados.
  BuscarEmpleado;
end;

procedure TfrmMtoOpeTraspaso.BuscarEmpleado;
var
  Consulta: IResultadoConsultaCaja;
  Datos: TDataSet;
begin
  // Buscador de empleados (mismos datos y rejilla que la caja). Al elegir
  // uno,// su codigo va al campo y se valida para mostrar el nombre.
  Consulta := FRepositorioConsultas.ConsultarEmpleados;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       'Buscar empleado',
       Datos,
       'frmMtoEmpCajSearch') then
  begin
    txtEmpleado.Text := Datos.Fields[0].AsString;
    txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.EmpleadoValido: Boolean;
var
  sCod, sNom: string;
begin
  if Trim(txtEmpleado.Text) = '' then
  begin
    ShowMessage(SErrorEmpleadoTraspasoNoIndicado);
    Result := False;
  end
  else if FDatos.ValidarEmpleado(Trim(txtEmpleado.Text), sCod, sNom) then
  begin
    lblEmpleadoNombre.Caption := sNom;
    if FDatos.cdsCabecera.State = dsBrowse then
      FDatos.cdsCabecera.Edit;
    FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString := sCod;
    FDatos.cdsCabecera.Post;
    Result := True;
  end
  else
  begin
    ShowMessage(Format(SErrorEmpleadoTraspasoNoEncontrado,
      [txtEmpleado.Text]));
    Result := False;
  end;
end;

// Envoltorio de la grabación: las validaciones de negocio del data module
// (stock insuficiente, líneas incompletas...) llegan como
// EValidacionTraspaso y se muestran como aviso normal, no como error no
// controlado.
procedure TfrmMtoOpeTraspaso.EjecutarTraspaso(AConTicket: Boolean);
begin
  try
    EjecutarTraspasoInterno(AConTicket);
  except
    on E: EValidacionTraspaso do
      ShowMessage(E.Message);
  end;
end;

procedure TfrmMtoOpeTraspaso.EjecutarTraspasoInterno(AConTicket: Boolean);
var
  sNumOp, sDestino, sOrigen, sEmpleado, sNumSol, sSerSol: string;
  iServidas: Integer;
  bFaltaMotivo: Boolean;
begin
  if EmpleadoValido then
  begin
    // Origen y empleado se capturan ya (la cabecera los tiene); el ticket se
    // imprime ANTES de AplicarModo, que reinicia el cds.
    sOrigen := FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    sEmpleado := FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
    if FModo = mtAtender then
    begin
      sDestino :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      sNumSol := FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString;
      sSerSol := FDatos.cdsCabecera.FieldByName('SERIE_SOL').AsString;
      if sDestino = '' then
        ShowMessage(SErrorSolicitudTraspasoAtenderNoCargada)
      else
      begin
        // Reparto por linea: cuenta lo que se sirve (CANTIDAD>0) y exige motivo
        // en las que se deniegan (servir 0).
        iServidas := 0;
        bFaltaMotivo := False;
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              if FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
                Inc(iServidas)
              else if Trim(FDatos.cdsLineas.FieldByName('MOTIVO').AsString)
                      = '' then
                bFaltaMotivo := True;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        if bFaltaMotivo then
          ShowMessage(SErrorMotivoLineasTraspasoNoIndicado)
        else if iServidas > 0 then
        begin
          // Hay algo que servir: traspaso de lo servido; lo denegado queda
          // registrado con su motivo. Estado COMPLETADO TOTAL/PARCIAL.
          if FDatos.GrabarTraspaso(sDestino, sNumOp, sNumSol, sSerSol) then
          begin
            ShowMessage(Format(SInfoSolicitudTraspasoAtendida, [sNumOp]));
            if AConTicket then
              TTraspasoTicket.ImprimirTraspaso(
                PreviewTicket,
                FRepositorioTraspasoTicket,
                sNumOp,
                sOrigen,
                sDestino,
                sEmpleado, FDatos.cdsLineas, ParametrosCaja.ImpresoraCaja);
            AplicarModo(mtAtender);
          end;
        end
        else if MessageDlg(SPreguntaDenegarPeticionTraspasoCompleta,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          // Todo a 0: denegacion total (con el motivo por linea), sin traspaso.
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        end;
      end;
    end
    else
    begin
      sDestino := DestinoSeleccionado;
      if sDestino = '' then
        ShowMessage(SErrorAlmacenDestinoTraspasoNoSeleccionado)
      else if FDatos.GrabarTraspaso(sDestino, sNumOp) then
      begin
        ShowMessage(Format(SInfoTraspasoGrabado, [sNumOp]));
        if AConTicket then
          TTraspasoTicket.ImprimirTraspaso(
            PreviewTicket,
            FRepositorioTraspasoTicket,
            sNumOp,
            sOrigen,
            sDestino,
            sEmpleado, FDatos.cdsLineas, ParametrosCaja.ImpresoraCaja);
        AplicarModo(mtTraspaso);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.QuitarLinea;
begin
  // Borra la linea enfocada del grid (F3). No se borra al atender: las
  // lineas vienen de la solicitud.
  if (FModo <> mtAtender) and (not FDatos.cdsLineas.IsEmpty) then
  begin
    FDatos.cdsLineas.Delete;
    ActualizarTotal;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnF11Click(Sender: TObject);
begin
  if FModo <> mtSolicitar then
    EjecutarTraspaso(False);
end;

procedure TfrmMtoOpeTraspaso.btnF12Click(Sender: TObject);
begin
  if FModo = mtSolicitar then
    EnviarSolicitud
  else
    EjecutarTraspaso(True);
end;

procedure TfrmMtoOpeTraspaso.FormKeyDown(Sender: TObject; var Key: Word;
                                         Shift: TShiftState);
begin
  // El lector cierra la lectura por velocidad (rafaga + Enter rapido) y consume
  // el VK_RETURN si procede, antes de la gestion de teclas de funcion.
  FLector.KeyDown(Key, Shift);
  case Key of
    VK_F3:
      QuitarLinea;
    VK_F4:
      DenegarSolicitudCargada;
    VK_F6:
      AplicarModo(mtSolicitar);
    VK_F7:
      AbrirMisPeticiones;
    VK_F8:
      if FModo = mtAtender then
        AbrirModalSolicitudes
      else
        AplicarModo(mtAtender);
    // F9 queda reservada en caja para abrir el cajon; cerrar la solicitud
    // cargada pasa de F9 a F10.
    VK_F10:
      CerrarSolicitudCargada;
    VK_F11:
      btnF11Click(nil);
    VK_F12:
      btnF12Click(nil);
    VK_ESCAPE:
      Close;
  end;
end;

end.
