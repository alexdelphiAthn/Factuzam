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
  inLibColumnasSkuIntf, inLibPivoteVentaCalculo, inLibPivoteVentaIntf;

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
    Repositorio           : IRepositorioPivoteVenta;
    OnCrearLineaSku       : TCrearLineaPivoteVentaEvent;
    OnBandaCambiada       : TBandaPivoteVentaEvent;
  end;
function CrearModoEntradaGridPivoteVenta(
  const AConfig: TConfigColumnasSku;
  const ACfgPivote: TGridPivoteVentaConfig): IModoEntradaGrid;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Variants, System.UITypes,
  Vcl.Dialogs,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibAtributosPaleta, inLibGridPivoteVentaPresentacion,
  inLibGridPivoteVentaVista, inLibLog, inLibMsgArticulos,
  inLibMsgVentas, inLibPivoteVentaModelo;

type
  TGridPivoteVenta = class(TInterfacedObject, IModoEntradaGrid,
                           IPivoteVentaAlbaranar,
                           IPivoteVentaBorrarGrupo)
  private
    FConfig           : TConfigColumnasSku;
    FCfg              : TGridPivoteVentaConfig;
    FRepositorio      : IRepositorioPivoteVenta;
    FModelo           : TModeloPivoteVenta;
    FPresentacion     : TPresentacionPivoteVenta;
    FOnResuelto       : TSkuResueltoEvent;
    FOnEntrarEdicion  : TNotifyEvent;
    FOnSalirEdicion   : TNotifyEvent;
    FGuardandoCantidad: Boolean;
    // Cancela la validación si el usuario abandona la paleta de variación.
    FEntradaCancelada : Boolean;
    function CdsLineas: TDataSet;
    function CampoTexto(ADs: TDataSet; const ACampo: string): string;
    function CampoFloat(ADs: TDataSet; const ACampo: string): Double;
    procedure PonerFloat(ADs: TDataSet; const ACampo: string;
                         AValor: Double);
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
    // Pide color/talla con la paleta de swatches (mismo selector que
    // el modo SKU vertical) y compone el SKU completo ART/COLOR/TALLA.
    // Devuelve '' si el usuario cancela.
    function ElegirSkuConPaleta(const ACodArt: string): string;
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

procedure RegistrarInfoPivoteVenta(const AMensaje: string);
begin
  if Log() <> nil then
    Log.LogInfo(AMensaje);
end;

procedure RegistrarWarningPivoteVenta(const AMensaje: string);
begin
  if Log() <> nil then
    Log.LogWarning(AMensaje);
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
  FConfig.Modo := mcsTallasHorPed;
  FCfg := ACfgPivote;
  if FCfg.MaxColumnas <= 0 then
    FCfg.MaxColumnas := 20;
  FRepositorio := FCfg.Repositorio;
  if (FRepositorio = nil) and (Log() <> nil) then
    // Sin puerto compuesto, el pivote pierde SKU, conjuntos y alta de
    // SKU: el consumidor debe pasar CrearRepositorioPivoteVenta.
    Log.LogWarning(
      'GridPivoteVenta: config sin Repositorio; las resoluciones de ' +
      'SKU y conjuntos quedaran vacias.');
  FModelo := TModeloPivoteVenta.Create(FRepositorio, FCfg.BandaUnica,
                                       FCfg.TextoBandaAAlbaranar);
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
  oCallbacks.AlLogInfo := RegistrarInfoPivoteVenta;
  oCallbacks.AlLogWarning := RegistrarWarningPivoteVenta;
  FPresentacion := TPresentacionPivoteVenta.Create(oCfgPres,
    oCallbacks, FModelo);
end;

destructor TGridPivoteVenta.Destroy;
begin
  // La presentacion restaura eventos y vista temporal en su propio
  // destructor; despues puede liberarse el modelo.
  FreeAndNil(FPresentacion);
  FreeAndNil(FModelo);
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

procedure TGridPivoteVenta.PonerGuardando(AGuardando: Boolean);
begin
  FGuardandoCantidad := AGuardando;
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
            if bGrupoNuevo and (Log() <> nil) then
              // Traza de diagnostico (fase de integracion).
              Log.LogInfo(Format(
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
      if (Log() <> nil) and
         FModelo.Grupo(aSinConjunto[i], oGrupo) then
        // Error DOCUMENTADO: sin conjunto (ni real ni virtual) que
        // cubra las tallas del grupo, sus celdas no tienen columna
        // donde pintarse.
        Log.LogWarning(Format(
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
  if not FGuardandoCantidad then
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

function TGridPivoteVenta.ElegirSkuConPaleta(
  const ACodArt: string): string;
var
  oLookup: IArticulosAtributosLookup;
  aAtribs: TArray<TArticuloAtributo>;
  aAvs: TArray<TArticuloAtributoValor>;
  aAvsStr: TArray<string>;
  oMapa: TDictionary<string, string>;
  sIdVa, sAvNuevo: string;
  i, j: Integer;
  bCancelado: Boolean;
begin
  // Mismo flujo que TModoEntradaSku.ElegirSkuConPaleta (modo
  // vertical): un selector por atributo (Color, Talla, ...); si el
  // articulo solo referencia un AV en sus SKUs, se fija sin preguntar.
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
      i := 0;
      while (i < Length(aAtribs)) and (not bCancelado) do
      begin
        // Solo AVs presentes en SKUs del articulo (no el conjunto).
        aAvs := oLookup.ObtenerAvsEnSkus(ACodArt, i + 1);
        if Length(aAvs) = 0 then
          bCancelado := True
        else if Length(aAvs) = 1 then
          Result := Result + '/' + aAvs[0].Valor
        else
        begin
          SetLength(aAvsStr, Length(aAvs));
          for j := 0 to High(aAvs) do
            aAvsStr[j] := aAvs[j].Valor;
          sIdVa := '';
          oMapa := ObtenerMapaAtributosGlobal(FCfg.Conexion);
          if oMapa <> nil then
            oMapa.TryGetValue(
              UpperCase(Trim(aAtribs[i].NombreAtributo)), sIdVa);
          // Paleta de swatches auto-centrada (-1,-1), como caja e
          // inventarios.
          if SeleccionarAvConPaleta(FCfg.Conexion, sIdVa, aAvsStr,
                                    '', sAvNuevo, -1, -1, 160) then
            Result := Result + '/' + sAvNuevo
          else
            bCancelado := True;
        end;
        Inc(i);
      end;
      if bCancelado then
        Result := '';
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
  bPrecio, bLineaVacia, bSeguir: Boolean;
begin
  Result := False;
  FEntradaCancelada := False;
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
      sSku := oRes.CodigoSku;
      if (sSku = '') and oRes.RequiereSku then
      begin
        // Coincidio el articulo padre y tiene variaciones: pedir
        // COLOR (y talla) con la paleta y componer el SKU completo.
        // Antes se seguia con el codigo pelado y la linea nacia sin
        // color.
        sSku := ElegirSkuConPaleta(oRes.CodigoArticulo);
        if sSku = '' then
        begin
          FEntradaCancelada := True;
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
          if not (oDs.State in dsEditModes) then
            oDs.Edit;
          PonerFloat(oDs, FCfg.FieldCantidadPedida,
            CampoFloat(oDs, FCfg.FieldCantidadPedida) + 1);
          oDs.Post;
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
              oDs.Post;
          end;
        end;
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
  ACancelada := FEntradaCancelada;
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
