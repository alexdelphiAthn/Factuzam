{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridPivoteVenta                                          }
{    Tipo:       Libreria                                                      }
{ Version:       0.2.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modo de grid "Tallas en horizontal" para pedidos de venta. No             }
{    consolida ni des-pivota datos: cada celda apunta a una linea real y       }
{    el pivot solo filtra/publica cantidades sobre columnas no-bound.          }
{    Tras el anexo SRP (fasciculos V1-V5), esta unidad es el coordinador       }
{    de IModoEntradaGrid: el calculo puro vive en inLibPivoteVentaCalculo,     }
{    el estado en inLibPivoteVentaModelo, el SQL en UniDataPivoteVenta y       }
{    la capa visual en inLibGridPivoteVentaPresentacion.                       }
{******************************************************************************}
unit inLibGridPivoteVenta;

interface

uses
  System.Classes, System.Generics.Collections, Data.DB, Uni,
  inLibColumnasSkuIntf, inLibPivoteVentaCalculo,
  inLibPivoteVentaComposicionIntf, inLibPivoteVentaIntf;
type
  // Alias de compatibilidad: la banda se declara en el calculo puro y
  // los consumidores siguen usandola desde esta unidad.
  TBandaPivoteVenta = inLibPivoteVentaCalculo.TBandaPivoteVenta;

const
  bpvPedida = inLibPivoteVentaCalculo.bpvPedida;
  bpvEntregada = inLibPivoteVentaCalculo.bpvEntregada;
  bpvPendiente = inLibPivoteVentaCalculo.bpvPendiente;

type
  TCrearLineaPivoteVentaEvent = procedure(
    const ACodigoSku: string) of object;
  TBandaPivoteVentaEvent = procedure(
    ABanda: TBandaPivoteVenta) of object;

  IPivoteVentaAlbaranar = interface
    ['{8CB98D4C-21BC-47F3-8D83-8E39E876F873}']
    function MarcarTodoAAlbaranar: Integer;
    function VolcarAAlbaranar(ALineas: TList<TPair<string, Currency>>;
                              out AAlmacenComun: string;
                              out AAlmacenUnico: Boolean): Integer;
    procedure LimpiarAAlbaranar;
  end;

  // Borrado del grupo activo del pivote. Una fila del grid en modo
  // tallas horizontales representa un GRUPO articulo+color+precio con
  // varias lineas SKU reales (una por talla): el host debe invocar esto
  // desde su boton "Borrar linea" cuando el modo esta activo, porque un
  // Delete simple sobre el dataset solo elimina la linea representante
  // y el grupo "reaparece" al recargar el pivote.
  IPivoteVentaBorrarGrupo = interface
    ['{B3D1C0AA-4F5E-4C2B-9A77-0E61D8A3C512}']
    // Borra TODAS las lineas reales del grupo con foco. Devuelve el
    // numero de lineas borradas (0 si no hay grupo bajo el foco).
    function BorrarGrupoActual: Integer;
  end;

  TGridPivoteVentaConfig = record
    Conexion              : TUniConnection;
    Usuario               : string;
    SourceMaster          : TDataSource;
    SourceLineas          : TDataSource;
    FieldSerieMaster      : string;
    FieldNumeroMaster     : string;
    FieldLinea            : string;
    FieldArt              : string;
    FieldSku              : string;
    FieldDescripcion      : string;
    FieldTipoCantidad     : string;
    FieldCantidadPedida   : string;
    FieldCantidadEntregada: string;
    FieldCantidadAAlbaranar: string;
    FieldPrecioBase       : string;
    FieldAlmacen          : string;
    FieldAlmacenMaster    : string;
    MaxColumnas           : Integer;
    // Documento con UNA sola cantidad por linea (facturas de venta):
    // cada grupo articulo+color+precio pinta UNA fila (banda pedida,
    // rotulada 'Cantidad') en vez de las tres bandas Pedido /
    // A albaranar / Pendiente de pedidos.
    BandaUnica            : Boolean;
    // Rotulo de la banda de servicio ('A albaranar' por defecto;
    // pedidos de compra la rotulan 'A recibir').
    TextoBandaAAlbaranar  : string;
    // Campo de la COPIA VISUAL que recibe la suma de UNIDADES del
    // grupo. Solo aplica con BandaUnica: el importe de la linea
    // representante descuadraba con la suma de las celdas (el importe
    // del documento ya vive en el pie de totales).
    FieldTotalUdsGrupo    : string;
    // Puerto de persistencia del pivote (V2). Lo compone el formulario
    // consumidor con CrearRepositorioPivoteVenta (UniDataPivoteVenta).
    Repositorios          : TRepositoriosPivoteVenta;
    OnCrearLineaSku       : TCrearLineaPivoteVentaEvent;
    OnBandaCambiada       : TBandaPivoteVentaEvent;
  end;
function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;

implementation

uses
  Winapi.Windows, System.StrUtils, System.SysUtils, System.Variants,
  System.UITypes,
  Vcl.Dialogs,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibLogIntf,
  inLibGridPivoteVentaPresentacion, inLibGridPivoteVentaVista,
  inLibMsgArticulos,
  inLibLineaSku, inLibModoTallasModelo, inLibMsgVentas,
  inLibPivoteVentaModelo;

type
  TRegistroPivoteVenta = class
  private
    FRegistroLog: IRegistroLog;
  public
    constructor Create(const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure RegistrarInfo(const AMensaje: string);
    procedure RegistrarAdvertencia(const AMensaje: string);
  end;

  TEstadoGridPivoteVenta = record
    GuardandoCantidad: Boolean;
    EntradaCancelada: Boolean;
  end;

  TGridPivoteVenta = class(TInterfacedObject, IModoEntradaGrid,
                           IPivoteVentaAlbaranar,
                           IPivoteVentaBorrarGrupo)
  private
    FConfig           : TConfigColumnasSku;
    FCfg              : TGridPivoteVentaConfig;
    FRepositorio      : IRepositorioEdicionPivoteVenta;
    FModelo           : TModeloPivoteVenta;
    FPresentacion     : TPresentacionPivoteVenta;
    FRegistroEventos  : TRegistroPivoteVenta;
    FOnResuelto       : TSkuResueltoEvent;
    FOnEntrarEdicion  : TNotifyEvent;
    FOnSalirEdicion   : TNotifyEvent;
    FEstado           : TEstadoGridPivoteVenta;
    function CdsLineas: TDataSet;
    function CampoTexto(ADs: TDataSet; const ACampo: string): string;
    function CampoFloat(ADs: TDataSet; const ACampo: string): Double;
    procedure PonerTexto(ADs: TDataSet; const ACampo,
                         AValor: string);
    procedure PonerFloat(ADs: TDataSet; const ACampo: string;
                         AValor: Double);
    procedure PrepararLineaSku(ADs: TDataSet;
                               const AArticulo, ASku: string);
    // Sincroniza el flag de guardado con la presentacion para que los
    // validadores inplace no reentren durante una escritura.
    procedure PonerGuardando(AGuardando: Boolean);
    function ObtenerCamposLinea(ADs: TDataSet)
                                : TCamposEntradaLineaPivote;
    procedure RecargarYPublicar;
    procedure CargarCachePivot;
    function LocalizarLineaSku(const ASku: string; APrecio: Double;
                               ATienePrecio: Boolean;
                               out ALinea: string): Boolean;
    function ResolverSkuCelda(AClave: Int64;
                              out ASku: string): Boolean;
    function CrearLineaDesdeCelda(AClave: Int64; ACantidad: Double;
                                  out ALineaReal: string): Boolean;
    procedure PersistirCantidadCelda(AClave: Int64; AValor: Double;
                                     ABanda: TBandaPivoteVenta);
    // Borra las lineas SKU reales del grupo ALineaBase (sin recargar
    // el pivote). Devuelve el numero de lineas borradas.
    function BorrarLineasGrupo(ALineaBase: Integer): Integer;
    // Compone un SKU semilla para abrir el grupo horizontal. La talla
    // se toma en silencio; los atributos no pivotados pueden pedir valor.
    function ElegirSkuHorizontal(const ACodArt: string): string;
    // Callbacks tipados de la presentacion.
    procedure AlRecargar(Sender: TObject);
    procedure AlEditarCantidad(AClave: Int64; AValor: Double;
                               ABanda: TBandaPivoteVenta);
    function AlResolverEntradaEditor(const AEntrada: string;
                                     out ATextoLinea: string;
                                     out ACancelada: Boolean): Boolean;
    function AlBuscarArticulo: Boolean;
    function AlBorrarGrupo(ALineaBase: Integer): Integer;
    procedure AlLineaFocada(ALineaBase: Integer);
    procedure AlEntrarEdicion(Sender: TObject);
    procedure AlSalirEdicion(Sender: TObject);
  public
    constructor Create(const AConfig: TConfigColumnasSku;
                       const ACfgPivote: TGridPivoteVentaConfig);
    destructor Destroy; override;
    procedure Construir(
      AOnResuelto: TSkuResueltoEvent;
      AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
    procedure Desmontar;
    procedure MostrarEditor;
    function MarcarTodoAAlbaranar: Integer;
    function VolcarAAlbaranar(ALineas: TList<TPair<string, Currency>>;
                              out AAlmacenComun: string;
                              out AAlmacenUnico: Boolean): Integer;
    procedure LimpiarAAlbaranar;
    function BorrarGrupoActual: Integer;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;
constructor TRegistroPivoteVenta.Create(
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
end;
destructor TRegistroPivoteVenta.Destroy;
begin
  FRegistroLog := nil;
  inherited;
end;
procedure TRegistroPivoteVenta.RegistrarInfo(const AMensaje: string);
begin
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarInformacion(AMensaje);
end;
procedure TRegistroPivoteVenta.RegistrarAdvertencia(
  const AMensaje: string);
begin
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(AMensaje);
end;
function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;
begin
  Result := TGridPivoteVenta.Create(AConfig, ACfgPivote);
end;

constructor TGridPivoteVenta.Create(const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig);
var
  oCfgPres: TConfigPresentacionPivoteVenta;
  oCallbacks: TCallbacksPresentacionPivoteVenta;
begin
  inherited Create;
  FConfig := AConfig;
  FRegistroEventos := TRegistroPivoteVenta.Create(FConfig.RegistroLog);
  FConfig.Modo := mcsTallasHorPed;
  FCfg := ACfgPivote;
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := 20;
  FRepositorio := FCfg.Repositorios.Edicion;
  if ((FRepositorio = nil) or (FCfg.Repositorios.Modelo = nil)) and
     Assigned(FConfig.RegistroLog) then
    // Sin puerto compuesto, el pivote pierde SKU, conjuntos y alta de
    // SKU: el consumidor debe pasar CrearRepositorioPivoteVenta.
    FConfig.RegistroLog.RegistrarAviso(
      'GridPivoteVenta: config sin Repositorio; las resoluciones de ' +
      'SKU y conjuntos quedaran vacias.');
  FModelo := TModeloPivoteVenta.Create(FCfg.Repositorios.Modelo,
    FCfg.BandaUnica, FCfg.TextoBandaAAlbaranar);
  oCfgPres := Default(TConfigPresentacionPivoteVenta);
  oCfgPres.Conexion := FCfg.Conexion;
  oCfgPres.View := FConfig.View;
  oCfgPres.SourceLineas := FCfg.SourceLineas;
  oCfgPres.CdsFallback := FConfig.Cds;
  oCfgPres.CampoArticuloHost := FConfig.Campos.CodigoArt;
  oCfgPres.FieldLinea := FCfg.FieldLinea;
  oCfgPres.FieldArt := FCfg.FieldArt;
  oCfgPres.FieldSku := FCfg.FieldSku;
  oCfgPres.FieldTotalUdsGrupo := FCfg.FieldTotalUdsGrupo;
  oCfgPres.MaxColumnas := FCfg.MaxColumnas;
  oCfgPres.BandaUnica := FCfg.BandaUnica;
  oCallbacks := Default(TCallbacksPresentacionPivoteVenta);
  oCallbacks.AlRecargar := AlRecargar;
  oCallbacks.AlEditarCantidad := AlEditarCantidad;
  oCallbacks.AlResolverEntradaEditor := AlResolverEntradaEditor;
  oCallbacks.AlBuscarArticulo := AlBuscarArticulo;
  oCallbacks.AlBorrarGrupo := AlBorrarGrupo;
  oCallbacks.AlLineaFocada := AlLineaFocada;
  oCallbacks.AlEntrarEdicion := AlEntrarEdicion;
  oCallbacks.AlSalirEdicion := AlSalirEdicion;
  oCallbacks.AlLogInfo := FRegistroEventos.RegistrarInfo;
  oCallbacks.AlLogWarning := FRegistroEventos.RegistrarAdvertencia;
  FPresentacion := TPresentacionPivoteVenta.Create(oCfgPres,
    oCallbacks, FModelo);
end;
destructor TGridPivoteVenta.Destroy;
begin
  // La presentación restaura sus eventos antes de liberar el modelo.
  FreeAndNil(FPresentacion);
  FreeAndNil(FModelo);
  FreeAndNil(FRegistroEventos);
  inherited;
end;

function TGridPivoteVenta.CdsLineas: TDataSet;
begin
  Result := nil;
  if FCfg.SourceLineas <> nil then
    Result := FCfg.SourceLineas.DataSet;
  if Result = nil then
    Result := FConfig.Cds;
end;

function TGridPivoteVenta.CampoTexto(ADs: TDataSet;
  const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if (ADs <> nil) and (ACampo <> '') then
  begin
    oCampo := ADs.FindField(ACampo);
    if oCampo <> nil then
      Result := Trim(oCampo.AsString);
  end;
end;

function TGridPivoteVenta.CampoFloat(ADs: TDataSet;
  const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  if (ADs <> nil) and (ACampo <> '') then
  begin
    oCampo := ADs.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.AsFloat;
  end;
end;

procedure TGridPivoteVenta.PonerTexto(ADs: TDataSet;
  const ACampo, AValor: string);
var
  oCampo: TField;
begin
  if (ADs <> nil) and (ACampo <> '') then
  begin
    oCampo := ADs.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsString := AValor;
  end;
end;

procedure TGridPivoteVenta.PonerFloat(ADs: TDataSet;
  const ACampo: string; AValor: Double);
var
  oCampo: TField;
begin
  if (ADs <> nil) and (ACampo <> '') then
  begin
    oCampo := ADs.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.ReadOnly) then
      oCampo.AsFloat := AValor;
  end;
end;

procedure TGridPivoteVenta.PrepararLineaSku(ADs: TDataSet;
  const AArticulo, ASku: string);
var
  sArticulo, sSku: string;
  iSeparador: Integer;
begin
  if (ADs <> nil) and (ADs.State in dsEditModes) then
  begin
    sArticulo := Trim(AArticulo);
    sSku := Trim(ASku);
    if sArticulo = '' then
      sArticulo := CampoTexto(ADs, FConfig.Campos.CodigoArt);
    if sArticulo = '' then
      sArticulo := CampoTexto(ADs, FCfg.FieldArt);
    if sArticulo = '' then
    begin
      iSeparador := Pos('/', sSku);
      if iSeparador > 1 then
        sArticulo := Copy(sSku, 1, iSeparador - 1)
      else
        sArticulo := sSku;
    end;
    SincronizarCamposLineaSku(ADs, FConfig.Campos,
      sArticulo, sSku, FConfig.LookupAtributos);
    PonerTexto(ADs, FCfg.FieldArt, sArticulo);
    PonerTexto(ADs, FCfg.FieldSku, sSku);
  end;
end;

procedure TGridPivoteVenta.PonerGuardando(AGuardando: Boolean);
begin
  FEstado.GuardandoCantidad := AGuardando;
  if FPresentacion <> nil then
    FPresentacion.EdicionSuspendida := AGuardando;
end;

function TGridPivoteVenta.ObtenerCamposLinea(ADs: TDataSet)
  : TCamposEntradaLineaPivote;
begin
  Result := Default(TCamposEntradaLineaPivote);
  Result.Sku := CampoTexto(ADs, FCfg.FieldSku);
  Result.SkuAlternativo := CampoTexto(ADs, 'CODIGO_UNIDAD_PEDLIN');
  Result.CodigoBarras := CampoTexto(ADs, 'CODBAR_ART_PEDLIN');
  Result.CodigoProdPs := CampoTexto(ADs, 'CODIGOPRODPS_PEDLIN');
  Result.Articulo := CampoTexto(ADs, FCfg.FieldArt);
end;

procedure TGridPivoteVenta.Construir(
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
begin
  FOnResuelto := AOnResuelto;
  FOnEntrarEdicion := AOnEntrarEdicion;
  FOnSalirEdicion := AOnSalirEdicion;
  // Cada montaje del modo repuebla las posiciones de conjuntos, igual
  // que la recreacion del gestor en la version monolitica.
  FModelo.InvalidarPosiciones;
  FPresentacion.Montar;
end;

procedure TGridPivoteVenta.Desmontar;
begin
  FPresentacion.Desmontar;
end;

procedure TGridPivoteVenta.MostrarEditor;
begin
  RecargarYPublicar;
  if not FPresentacion.EnfocarEditorArticulo then
    AlBuscarArticulo;
end;

procedure TGridPivoteVenta.RecargarYPublicar;
var
  oDs: TDataSet;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active then
  begin
    CargarCachePivot;
    FPresentacion.PublicarTodo;
  end;
end;

procedure TGridPivoteVenta.CargarCachePivot;
var
  oDs: TDataSet;
  oBm: TBookmark;
  oDatos: TDatosLineaPivoteVenta;
  oGrupo: TGrupoPivoteVenta;
  aSinConjunto: TArray<Integer>;
  sSku: string;
  oInfo: TInfoSkuPivoteVenta;
  iLineaRepr, i: Integer;
  bFiltrado, bGrupoNuevo: Boolean;
begin
  FModelo.IniciarCarga;
  oDs := CdsLineas;
  // El pivote usa un borrador visual propio. Una inserción real vacía
  // heredada del host impediría recorrer las líneas ya existentes y
  // haría que la vista publicase únicamente la línea 0000.
  if FPresentacion.EsInsercionVacia(oDs) then
    oDs.Cancel;
  if (oDs <> nil) and oDs.Active and (not oDs.IsEmpty) and
     (not FPresentacion.EsInsercionVacia(oDs)) then
  begin
    oBm := oDs.GetBookmark;
    bFiltrado := oDs.Filtered;
    FPresentacion.RecargaSuspendida := True;
    oDs.DisableControls;
    try
      oDs.Filtered := False;
      oDs.First;
      while not oDs.Eof do
      begin
        oDatos := Default(TDatosLineaPivoteVenta);
        oDatos.Articulo := CampoTexto(oDs, FCfg.FieldArt);
        oDatos.LineaTexto := CampoTexto(oDs, FCfg.FieldLinea);
        oDatos.Linea := StrToIntDef(oDatos.LineaTexto, 0);
        oDatos.Precio := CampoFloat(oDs, FCfg.FieldPrecioBase);
        if (oDatos.Articulo <> '') and (oDatos.Linea > 0) then
        begin
          FModelo.ResolverInfoLinea(ObtenerCamposLinea(oDs), sSku,
                                    oInfo);
          oDatos.Sku := sSku;
          oDatos.Info := oInfo;
          oDatos.TipoCantidad :=
            CampoTexto(oDs, FCfg.FieldTipoCantidad);
          oDatos.Pedida :=
            CampoFloat(oDs, FCfg.FieldCantidadPedida);
          oDatos.Entregada :=
            CampoFloat(oDs, FCfg.FieldCantidadEntregada);
          oDatos.AAlbaranar :=
            CampoFloat(oDs, FCfg.FieldCantidadAAlbaranar);
          oDatos.Almacen := CampoTexto(oDs, FCfg.FieldAlmacen);
          if FModelo.RegistrarLinea(oDatos, iLineaRepr,
                                    bGrupoNuevo) then
            if bGrupoNuevo and Assigned(FConfig.RegistroLog) then
              // Traza de diagnostico (fase de integracion).
              FConfig.RegistroLog.RegistrarInformacion(Format(
                'PivVenta.Cache: repr=%d art=%s tallaAv=%d sku=%s',
                [iLineaRepr, oDatos.Articulo, oInfo.TallaAv, sSku]));
        end;
        oDs.Next;
      end;
      if oDs.BookmarkValid(oBm) then
        oDs.GotoBookmark(oBm);
      oDs.Filtered := bFiltrado;
    finally
      oDs.EnableControls;
      oDs.FreeBookmark(oBm);
      FPresentacion.RecargaSuspendida := False;
    end;
    FModelo.CompletarCarga;
    aSinConjunto := FModelo.GruposSinConjunto;
    for i := 0 to High(aSinConjunto) do
      if Assigned(FConfig.RegistroLog) and
         FModelo.Grupo(aSinConjunto[i], oGrupo) then
        // Error DOCUMENTADO: sin conjunto (ni real ni virtual) que
        // cubra las tallas del grupo, sus celdas no tienen columna
        // donde pintarse.
        FConfig.RegistroLog.RegistrarAviso(Format(
          'PivVenta.Cache: NINGUN conjunto global cubre las %d ' +
          'tallas del grupo repr=%d (art=%s); sus cantidades no se ' +
          'pintaran en columnas de talla. Revisar ' +
          'fza_atributos_conjuntos / fza_atributos_sku del articulo.',
          [Length(oGrupo.Tallas), aSinConjunto[i], oGrupo.Articulo]));
  end;
end;

function TGridPivoteVenta.LocalizarLineaSku(const ASku: string;
  APrecio: Double; ATienePrecio: Boolean;
  out ALinea: string): Boolean;
var
  oDs: TDataSet;
  oBm: TBookmark;
  oInfo: TInfoSkuPivoteVenta;
  sSkuLin: string;
  rPrecioLin: Double;
  bFiltrado: Boolean;
begin
  Result := False;
  ALinea := '';
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active and (Trim(ASku) <> '') then
  begin
    oBm := oDs.GetBookmark;
    bFiltrado := oDs.Filtered;
    oDs.DisableControls;
    try
      oDs.Filtered := False;
      oDs.First;
      while (not Result) and (not oDs.Eof) do
      begin
        FModelo.ResolverInfoLinea(ObtenerCamposLinea(oDs), sSkuLin,
                                  oInfo);
        if SameText(sSkuLin, Trim(ASku)) then
        begin
          rPrecioLin := CampoFloat(oDs, FCfg.FieldPrecioBase);
          Result := (not ATienePrecio) or
                    (Abs(rPrecioLin - APrecio) < 0.005);
          if Result then
            ALinea := CampoTexto(oDs, FCfg.FieldLinea);
        end;
        if not Result then
          oDs.Next;
      end;
      // Si se encontro, el cursor queda en la linea localizada; solo
      // se restaura la posicion original cuando no hubo coincidencia.
      if (not Result) and oDs.BookmarkValid(oBm) then
        oDs.GotoBookmark(oBm);
      oDs.Filtered := bFiltrado;
    finally
      oDs.EnableControls;
      oDs.FreeBookmark(oBm);
    end;
  end;
end;

function TGridPivoteVenta.ResolverSkuCelda(AClave: Int64;
  out ASku: string): Boolean;
var
  oCelda: TCeldaPivoteVenta;
  oGrupo: TGrupoPivoteVenta;
  iLineaRepr, iTallaAv: Integer;
  sTalla: string;
begin
  ASku := '';
  if FModelo.Celda(AClave, oCelda) then
    ASku := oCelda.Sku;
  Result := Trim(ASku) <> '';
  if (not Result) and (FRepositorio <> nil) then
  begin
    iLineaRepr := LineaBaseDesdeClaveCelda(AClave);
    iTallaAv := TallaAvDesdeClaveCelda(AClave);
    FModelo.Grupo(iLineaRepr, oGrupo);
    if (oGrupo.Articulo <> '') and (iTallaAv > 0) then
    begin
      ASku := FRepositorio.BuscarSkuActivoPorAtributos(
        oGrupo.Articulo, iTallaAv, oGrupo.ColorAv);
      Result := Trim(ASku) <> '';
      if not Result then
      begin
        // Alta de SKU al vuelo: prefijo del grupo + talla, con sus
        // atributos de color y talla (INSERT IGNORE idempotente).
        sTalla := FRepositorio.DescripcionTalla(iTallaAv);
        if (oGrupo.SkuPrefijo <> '') and (Trim(sTalla) <> '') then
        begin
          ASku := oGrupo.SkuPrefijo + '/' + sTalla;
          FRepositorio.CrearSkuConAtributos(ASku, oGrupo.Articulo,
            oGrupo.VarSku, oGrupo.ColorAv, iTallaAv);
          Result := True;
        end;
      end;
    end;
  end;
end;

function TGridPivoteVenta.CrearLineaDesdeCelda(AClave: Int64;
  ACantidad: Double; out ALineaReal: string): Boolean;
var
  oDs: TDataSet;
  sSku: string;
  bFiltrado: Boolean;
begin
  Result := False;
  ALineaReal := '';
  oDs := CdsLineas;
  if (ACantidad > 0) and (oDs <> nil) and oDs.Active and
     ResolverSkuCelda(AClave, sSku) then
  begin
    bFiltrado := oDs.Filtered;
    oDs.DisableControls;
    PonerGuardando(True);
    try
      oDs.Filtered := False;
      oDs.Append;
      try
        if Assigned(FCfg.OnCrearLineaSku) then
          FCfg.OnCrearLineaSku(sSku);
        if not (oDs.State in dsEditModes) then
          oDs.Edit;
        PrepararLineaSku(oDs, '', sSku);
        PonerFloat(oDs, FCfg.FieldCantidadPedida, ACantidad);
        PonerFloat(oDs, FCfg.FieldCantidadEntregada, 0);
        PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar, 0);
        oDs.Post;
        ALineaReal := CampoTexto(oDs, FCfg.FieldLinea);
        Result := ALineaReal <> '';
      except
        if oDs.State in dsEditModes then
          oDs.Cancel;
        raise;
      end;
      oDs.Filtered := bFiltrado;
    finally
      PonerGuardando(False);
      oDs.EnableControls;
    end;
  end;
end;

procedure TGridPivoteVenta.PersistirCantidadCelda(AClave: Int64;
  AValor: Double; ABanda: TBandaPivoteVenta);
var
  oDs: TDataSet;
  oCelda: TCeldaPivoteVenta;
  sLineaReal: string;
  iLineaFoco: Integer;
  rPedida, rEntregada, rPendBase: Double;
  bFiltrado, bBorrar: Boolean;
begin
  if not FEstado.GuardandoCantidad then
  begin
    oDs := CdsLineas;
    iLineaFoco := LineaBaseDesdeClaveCelda(AClave);
    PonerGuardando(True);
    try
      if FModelo.Celda(AClave, oCelda) then
      begin
        sLineaReal := oCelda.Linea;
        bFiltrado := oDs.Filtered;
        oDs.DisableControls;
        try
          oDs.Filtered := False;
          if oDs.Locate(FCfg.FieldLinea, sLineaReal, []) then
          begin
            rPedida := CampoFloat(oDs, FCfg.FieldCantidadPedida);
            rEntregada :=
              CampoFloat(oDs, FCfg.FieldCantidadEntregada);
            if ABanda = bpvPedida then
            begin
              bBorrar := (AValor <= 0) and (rEntregada <= 0);
              if bBorrar then
                bBorrar := MessageDlg(
                  SPreguntaEliminarLineaSkuCantidadCero,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes;
              if bBorrar then
                oDs.Delete
              else
              begin
                if not (oDs.State in dsEditModes) then
                  oDs.Edit;
                PonerFloat(oDs, FCfg.FieldCantidadPedida, AValor);
                if rEntregada > AValor then
                  PonerFloat(oDs, FCfg.FieldCantidadEntregada,
                             AValor);
                oDs.Post;
              end;
            end
            else if ABanda = bpvEntregada then
            begin
              if AValor < 0 then
                AValor := 0;
              rPendBase := PendienteBasePivoteVenta(rPedida,
                                                    rEntregada);
              if AValor > rPendBase then
              begin
                MessageBeep(MB_ICONWARNING);
                AValor := rPendBase;
              end;
              if not (oDs.State in dsEditModes) then
                oDs.Edit;
              PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar, AValor);
              oDs.Post;
            end
            else
            begin
              if AValor < 0 then
                AValor := 0;
              rPendBase := PendienteBasePivoteVenta(rPedida,
                                                    rEntregada);
              if AValor > rPendBase then
              begin
                MessageBeep(MB_ICONWARNING);
                AValor := rPendBase;
              end;
              if not (oDs.State in dsEditModes) then
                oDs.Edit;
              PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar,
                         rPendBase - AValor);
              oDs.Post;
            end;
          end;
          oDs.Filtered := bFiltrado;
          LocalizarLineaRealPivote(oDs, FCfg.FieldLinea, iLineaFoco);
        finally
          oDs.EnableControls;
        end;
      end
      else if ABanda = bpvPedida then
        CrearLineaDesdeCelda(AClave, AValor, sLineaReal)
      else
        MessageDlg(SInfoLineaPedidoTallaNoExiste,
                   mtInformation, [mbOk], 0);
    finally
      PonerGuardando(False);
    end;
    RecargarYPublicar;
  end;
end;

function TGridPivoteVenta.BorrarLineasGrupo(
  ALineaBase: Integer): Integer;
var
  oDs: TDataSet;
  aLineas: TArray<string>;
  i: Integer;
  bFiltrado: Boolean;
begin
  Result := 0;
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active and (ALineaBase > 0) then
  begin
    // Lineas reales del grupo: una por talla (o la unica "sin talla").
    aLineas := FModelo.LineasRealesDeGrupo(ALineaBase);
    if Length(aLineas) > 0 then
    begin
      // Soltar la insercion vacia auto-anadida (o cualquier edicion a
      // medias) antes de mover el cursor por el dataset real.
      if oDs.State in dsEditModes then
        oDs.Cancel;
      bFiltrado := oDs.Filtered;
      oDs.DisableControls;
      PonerGuardando(True);
      try
        oDs.Filtered := False;
        for i := 0 to High(aLineas) do
          if oDs.Locate(FCfg.FieldLinea, aLineas[i], []) then
          begin
            // Delete linea a linea (NO SQL directo): el BeforeDelete
            // del data module ajusta el stock pendiente por linea.
            oDs.Delete;
            Inc(Result);
          end;
        oDs.Filtered := bFiltrado;
      finally
        PonerGuardando(False);
        oDs.EnableControls;
      end;
    end;
  end;
end;

function TGridPivoteVenta.BorrarGrupoActual: Integer;
begin
  Result := BorrarLineasGrupo(FPresentacion.LineaBaseFocada);
  if Result > 0 then
    RecargarYPublicar;
end;

function TGridPivoteVenta.MarcarTodoAAlbaranar: Integer;
var
  oDs: TDataSet;
  rPend, rPedida, rEntregada: Double;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active and
     (oDs.FindField(FCfg.FieldCantidadAAlbaranar) <> nil) then
  begin
    Result := 0;
    if oDs.State in dsEditModes then
      oDs.Post;
    bFiltrado := oDs.Filtered;
    sLineaFoco := CampoTexto(oDs, FCfg.FieldLinea);
    oDs.DisableControls;
    try
      oDs.Filtered := False;
      oDs.First;
      while not oDs.Eof do
      begin
        rPedida := CampoFloat(oDs, FCfg.FieldCantidadPedida);
        rEntregada := CampoFloat(oDs, FCfg.FieldCantidadEntregada);
        rPend := PendienteBasePivoteVenta(rPedida, rEntregada);
        if not (oDs.State in dsEditModes) then
          oDs.Edit;
        PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar, rPend);
        oDs.Post;
        if rPend > 0 then
          Inc(Result);
        oDs.Next;
      end;
      oDs.Filtered := bFiltrado;
      if sLineaFoco <> '' then
        oDs.Locate(FCfg.FieldLinea, sLineaFoco, []);
    finally
      oDs.EnableControls;
    end;
    RecargarYPublicar;
  end
  else
  begin
    Result := FModelo.MarcarTodoAAlbaranarEnCache;
    FPresentacion.PublicarCantidadesPivot;
  end;
  FPresentacion.RefrescarSite;
end;

function TGridPivoteVenta.VolcarAAlbaranar(
  ALineas: TList<TPair<string, Currency>>;
  out AAlmacenComun: string; out AAlmacenUnico: Boolean): Integer;
begin
  Result := FModelo.VolcarAAlbaranar(ALineas, AAlmacenComun,
                                     AAlmacenUnico);
end;

procedure TGridPivoteVenta.LimpiarAAlbaranar;
var
  oDs: TDataSet;
  bFiltrado: Boolean;
  sLineaFoco: string;
begin
  FModelo.LimpiarAAlbaranarEnCache;
  oDs := CdsLineas;
  if (oDs <> nil) and oDs.Active and
     (oDs.FindField(FCfg.FieldCantidadAAlbaranar) <> nil) then
  begin
    if oDs.State in dsEditModes then
      oDs.Post;
    bFiltrado := oDs.Filtered;
    sLineaFoco := CampoTexto(oDs, FCfg.FieldLinea);
    oDs.DisableControls;
    try
      oDs.Filtered := False;
      oDs.First;
      while not oDs.Eof do
      begin
        if CampoFloat(oDs, FCfg.FieldCantidadAAlbaranar) <> 0 then
        begin
          if not (oDs.State in dsEditModes) then
            oDs.Edit;
          PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar, 0);
          oDs.Post;
        end;
        oDs.Next;
      end;
      oDs.Filtered := bFiltrado;
      if sLineaFoco <> '' then
        oDs.Locate(FCfg.FieldLinea, sLineaFoco, []);
    finally
      oDs.EnableControls;
    end;
    RecargarYPublicar;
  end
  else
    FPresentacion.PublicarCantidadesPivot;
  FPresentacion.RefrescarSite;
end;

function EsAtributoColor(
  const AAtributo: TArticuloAtributo): Boolean;
begin
  Result := ContainsText(AAtributo.NombreAtributo, 'COLOR') or
    SameText(AAtributo.IdAtributo, 'CO') or
    StartsText('COL', AAtributo.IdAtributo);
end;

function IdValorSeleccionado(
  const AValores: TArray<TArticuloAtributoValor>;
  const AValor: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(AValores) do
    if SameText(AValores[i].Valor, AValor) then
      Result := AValores[i].IdValor;
end;

function SeleccionarValorHorizontal(
  const ASelector: IPresentacionAtributosSku;
  const AAtributo: TArticuloAtributo;
  const AValores: TArray<TArticuloAtributoValor>;
  AEsTalla, AEsColor: Boolean;
  const AAnclaje: TAnclajeSelectorAtributo;
  out AValor: string): Boolean;
var
  aValoresTexto: TArray<string>;
  i: Integer;
  oSelectorAnclado: ISelectorValorAtributoAnclado;
begin
  Result := Length(AValores) > 0;
  AValor := '';
  if Result then
  begin
    if AEsTalla or (Length(AValores) = 1) then
      AValor := AValores[0].Valor
    else
    begin
      SetLength(aValoresTexto, Length(AValores));
      for i := 0 to High(AValores) do
        aValoresTexto[i] := AValores[i].Valor;
      if AEsColor and AAnclaje.Valido and
         Supports(ASelector, ISelectorValorAtributoAnclado,
           oSelectorAnclado) then
        Result := oSelectorAnclado.SeleccionarEn(
          AAtributo.NombreAtributo, aValoresTexto,
          AAnclaje, AValor)
      else
        Result := Assigned(ASelector) and ASelector.Seleccionar(
          AAtributo.NombreAtributo, aValoresTexto, AValor);
    end;
  end;
end;

function BuscarSkuSemillaCompatible(
  const ARepositorio: IRepositorioEdicionPivoteVenta;
  const AArticulo: string;
  const ATallas: TArray<TArticuloAtributoValor>;
  AColorAv: Integer): string;
var
  i: Integer;
begin
  Result := '';
  i := 0;
  while (i < Length(ATallas)) and (Result = '') do
  begin
    Result := ARepositorio.BuscarSkuActivoPorAtributos(
      AArticulo, ATallas[i].IdValor, AColorAv);
    Inc(i);
  end;
end;

function TGridPivoteVenta.ElegirSkuHorizontal(
  const ACodArt: string): string;
var
  oLookup: IArticulosAtributosLookup;
  aAtribs: TArray<TArticuloAtributo>;
  aAvs: TArray<TArticuloAtributoValor>;
  aTallas: TArray<TArticuloAtributoValor>;
  oAnclajeColor: TAnclajeSelectorAtributo;
  sAvNuevo: string;
  i, iColorAv, j: Integer;
  bCancelado, bEsColor, bEsTalla, bSoloColorTalla: Boolean;
begin
  // La talla es la dimensión de las columnas: se resuelve en silencio
  // una variante real compatible y nunca se pregunta en este modo.
  Result := '';
  oLookup := FConfig.LookupAtributos;
  if not Assigned(oLookup) then
    raise Exception.Create(SErrorLookupAtributosNoInyectado);
  try
    aAtribs := oLookup.ObtenerAtributos(ACodArt);
    if Length(aAtribs) = 0 then
      ShowMessage(Format(SAvisoArticuloSinAtributos, [ACodArt]))
    else
    begin
      Result := ACodArt;
      bCancelado := False;
      bSoloColorTalla := True;
      iColorAv := 0;
      aTallas := nil;
      oAnclajeColor := Default(TAnclajeSelectorAtributo);
      FPresentacion.ObtenerAnclajeColor(oAnclajeColor);
      i := 0;
      while (i < Length(aAtribs)) and (not bCancelado) do
      begin
        // Solo AVs presentes en SKUs del articulo (no el conjunto).
        aAvs := oLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        bEsTalla := TModeloTallas.EsAtributoTalla(aAtribs[i]);
        bEsColor := EsAtributoColor(aAtribs[i]);
        bSoloColorTalla := bSoloColorTalla and
          (bEsTalla or bEsColor);
        if bEsTalla then
        begin
          SetLength(aTallas, Length(aAvs));
          for j := 0 to High(aAvs) do
            aTallas[j] := aAvs[j];
        end;
        // Los atributos no pivotados, como el color, siguen definiendo
        // el grupo horizontal y pueden necesitar selección.
        bCancelado := not SeleccionarValorHorizontal(
          FConfig.Servicios.Paleta, aAtribs[i], aAvs,
          bEsTalla, bEsColor, oAnclajeColor, sAvNuevo);
        if not bCancelado then
        begin
          Result := Result + '/' + sAvNuevo;
          if bEsColor then
            iColorAv := IdValorSeleccionado(aAvs, sAvNuevo);
        end;
        Inc(i);
      end;
      if bCancelado then
        Result := ''
      else if bSoloColorTalla and (FRepositorio <> nil) and
              (Length(aTallas) > 0) then
        Result := BuscarSkuSemillaCompatible(
          FRepositorio, ACodArt, aTallas, iColorAv);
    end;
  finally
    oLookup := nil;
  end;
end;

function TGridPivoteVenta.ResolverEntrada(
  const AEntrada: string): Boolean;
var
  oValidador: IArticulosValidador;
  oRes: TArtResolucionEntrada;
  oDs: TDataSet;
  sSku, sLinea: string;
  rPrecio: Double;
  bPrecio, bLineaVacia, bSeguir, bSemillaHorizontal: Boolean;
begin
  Result := False;
  FEstado.EntradaCancelada := False;
  if Trim(AEntrada) <> '' then
  begin
    oValidador := FConfig.ValidadorArticulos;
    if not Assigned(oValidador) then
      raise Exception.Create(SErrorValidadorArticulosNoInyectado);
    try
      oRes := oValidador.Resolver(Trim(AEntrada));
    finally
      oValidador := nil;
    end;
    if oRes.Encontrado then
    begin
      bSeguir := True;
      bSemillaHorizontal := False;
      sSku := oRes.CodigoSku;
      if (sSku = '') and oRes.RequiereSku then
      begin
        // El artículo padre abre un grupo: la talla se resuelve en
        // silencio porque el usuario la introduce en sus columnas.
        FPresentacion.MostrarArticuloProvisional(
          oRes.CodigoArticulo);
        sSku := ElegirSkuHorizontal(oRes.CodigoArticulo);
        bSemillaHorizontal := sSku <> '';
        if sSku = '' then
        begin
          FPresentacion.MostrarArticuloProvisional('');
          FEstado.EntradaCancelada := True;
          bSeguir := False;
        end;
      end;
      if bSeguir then
      begin
        if sSku = '' then
          sSku := oRes.CodigoArticulo;
        rPrecio := 0;
        bPrecio := False;
        if Assigned(FConfig.ObtenerPrecioSku) then
        begin
          rPrecio := FConfig.ObtenerPrecioSku(oRes.CodigoArticulo,
                                              sSku);
          bPrecio := True;
        end;
        oDs := CdsLineas;
        if LocalizarLineaSku(sSku, rPrecio, bPrecio, sLinea) then
        begin
          oDs.Filtered := False;
          if not bSemillaHorizontal then
          begin
            if not (oDs.State in dsEditModes) then
              oDs.Edit;
            PonerFloat(oDs, FCfg.FieldCantidadPedida,
              CampoFloat(oDs, FCfg.FieldCantidadPedida) + 1);
            oDs.Post;
          end;
        end
        else
        begin
          if Assigned(FCfg.OnCrearLineaSku) then
          begin
            if oDs.Filtered then
              oDs.Filtered := False;
            bLineaVacia := (oDs.State = dsInsert) and
              (CampoTexto(oDs, FCfg.FieldArt) = '') and
              (CampoTexto(oDs, FCfg.FieldSku) = '');
            if not bLineaVacia then
              oDs.Append;
            FCfg.OnCrearLineaSku(sSku);
            if oDs.State in dsEditModes then
            begin
              PrepararLineaSku(oDs, oRes.CodigoArticulo, sSku);
              if bSemillaHorizontal then
              begin
                // La fila enlazada sostiene el grupo hasta que se edita
                // una talla; totales y movimientos ignoran cantidades cero.
                PonerFloat(oDs, FCfg.FieldCantidadPedida, 0);
                PonerFloat(oDs, FCfg.FieldCantidadEntregada, 0);
                PonerFloat(oDs, FCfg.FieldCantidadAAlbaranar, 0);
              end;
              oDs.Post;
            end;
          end;
        end;
        FPresentacion.FinalizarAlta;
        RecargarYPublicar;
        Result := True;
      end;
    end
    else
      ShowMessage(Format(SErrorArticuloSkuNoEncontrado,
                         [Trim(AEntrada)]));
  end;
end;

procedure TGridPivoteVenta.AlRecargar(Sender: TObject);
begin
  RecargarYPublicar;
end;

procedure TGridPivoteVenta.AlEditarCantidad(AClave: Int64;
  AValor: Double; ABanda: TBandaPivoteVenta);
begin
  PersistirCantidadCelda(AClave, AValor, ABanda);
end;

function TGridPivoteVenta.AlResolverEntradaEditor(
  const AEntrada: string; out ATextoLinea: string;
  out ACancelada: Boolean): Boolean;
begin
  Result := ResolverEntrada(AEntrada);
  ACancelada := FEstado.EntradaCancelada;
  if ACancelada then
    ATextoLinea := ''
  else
    ATextoLinea := CampoTexto(CdsLineas, FCfg.FieldArt);
end;

function TGridPivoteVenta.AlBuscarArticulo: Boolean;
var
  sArticulo: string;
begin
  Result := False;
  if (FRepositorio <> nil) and
     FRepositorio.ElegirArticuloDesdeBusqueda(FConfig.AlmacenStock,
                                              sArticulo) then
    Result := ResolverEntrada(sArticulo);
end;

function TGridPivoteVenta.AlBorrarGrupo(ALineaBase: Integer): Integer;
begin
  Result := BorrarLineasGrupo(ALineaBase);
end;

procedure TGridPivoteVenta.AlLineaFocada(ALineaBase: Integer);
begin
  LocalizarLineaRealPivote(CdsLineas, FCfg.FieldLinea, ALineaBase);
end;

procedure TGridPivoteVenta.AlEntrarEdicion(Sender: TObject);
begin
  if Assigned(FOnEntrarEdicion) then
    FOnEntrarEdicion(Sender);
end;

procedure TGridPivoteVenta.AlSalirEdicion(Sender: TObject);
begin
  if Assigned(FOnSalirEdicion) then
    FOnSalirEdicion(Sender);
end;

end.
