{******************************************************************************}
{                                                                              }
{  Módulo:       DoblesModoTallas                                              }
{    Tipo:       Pruebas (dobles)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Dobles en memoria de los puertos del modo tallas: persistencia de         }
{    celdas, líneas del documento y catálogo de atributos. Permiten probar     }
{    el modelo y las conversiones sin BBDD, sin controles y sin UniDAC.        }
{******************************************************************************}
unit DoblesModoTallas;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibArticulosAtributosIntf, inLibModoTallasIntf;

type
  TCeldaMemoria = record
    Linea: Integer;
    Almacen: string;
    IdAv: Integer;
    ValorTalla: string;
    Cantidad: Double;
  end;
  TLineaMemoria = record
    Numero: Integer;
    Articulo: string;
    Sku: string;
    Almacen: string;
    Cantidad: Double;
    Precio: Double;
    TieneAlmacen: Boolean;
    TienePrecio: Boolean;
    TieneCantidad: Boolean;
    Valores: TValoresAttrTallas;
    Nombres: TValoresAttrTallas;
    ConjuntoTalla: Integer;
    Descripcion: string;
    Borrada: Boolean;
  end;
  // Persistencia de celdas en memoria. Registra las operaciones para
  // que la prueba compruebe QUE se llamo y con que datos.
  TPersistenciaTallasMemoria = class(TInterfacedObject,
                                     IPersistenciaModoTallas)
  private
    FCeldas: TList<TCeldaMemoria>;
    FConjuntoPorAvs: Integer;
    FConjuntosQueCubren: TList<Integer>;
    FAlmacenEstandar: string;
    FEnTransaccion: Boolean;
    FConfirmaciones: Integer;
    FReversiones: Integer;
    FInicios: Integer;
    FMigradas: Integer;
    FBorradoDocumento: Boolean;
    FFallarAlSumar: Boolean;
    function IndiceCelda(ALinea, AIdAv: Integer;
      const AAlmacen: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AnyadirCelda(ALinea, AIdAv: Integer;
      const AValorTalla, AAlmacen: string; ACantidad: Double);
    function TotalCeldas: Double;
    function ContarCeldas: Integer;
    function CeldaEn(AIndice: Integer): TCeldaMemoria;
    function ConsultarTotalesPorLinea: TArray<TTotalLineaTallas>;
    function ConsultarCeldasDocumento: TArray<TCeldaTallas>;
    function ConsultarCeldasLinea(ALinea: Integer): TArray<TCeldaTallas>;
    function LineaTieneCeldas(ALinea: Integer): Boolean;
    procedure SumarEnCelda(ALinea, AIdAv: Integer; ACantidad: Double;
      const AAlmacen: string);
    procedure MoverCeldasALinea(AOrigen, ADestino: Integer);
    function MigrarCeldasFormato(ADistribuido: Boolean;
      const AAlmacenDefecto: string): Integer;
    procedure BorrarCeldasDocumento;
    function BuscarConjuntoParaAvs(
      const AIdsValores: TArray<Integer>): Integer;
    function ConjuntoCubreAvs(AIdConjunto: Integer;
      const AIdsValores: TArray<Integer>): Boolean;
    function PrimerAlmacenEstandar: string;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure MarcarTransaccionActiva;
    procedure RevertirTransaccion;
    property AlmacenEstandar: string read FAlmacenEstandar
                                     write FAlmacenEstandar;
    property ConjuntoPorAvs: Integer read FConjuntoPorAvs
                                     write FConjuntoPorAvs;
    property ConjuntosQueCubren: TList<Integer> read FConjuntosQueCubren;
    property Confirmaciones: Integer read FConfirmaciones;
    property Reversiones: Integer read FReversiones;
    property Inicios: Integer read FInicios;
    property Migradas: Integer read FMigradas write FMigradas;
    property BorradoDocumento: Boolean read FBorradoDocumento;
    property FallarAlSumar: Boolean read FFallarAlSumar
                                    write FFallarAlSumar;
  end;
  // Lineas del documento en memoria.
  TLineasTallasMemoria = class(TInterfacedObject,
                               ILineasDocumentoTallas)
  private
    FLineas: TList<TLineaMemoria>;
    FPosicion: Integer;
    FProfundidad: Integer;
    FPostsNotificados: Integer;
    FCreadas: Integer;
    FActualizadas: Integer;
    function IndiceDeLinea(ALinea: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AnyadirLinea(const ALinea: TLineaMemoria);
    function LineaPorNumero(ALinea: Integer): TLineaMemoria;
    function Contar: Integer;
    function LineaEn(AIndice: Integer): TLineaMemoria;
    function HayLineas: Boolean;
    function MaximaLinea: Integer;
    function LeerDatosLinea(ALinea: Integer): TDatosLineaExpansion;
    function CantidadesPorLinea: TArray<TCantidadLineaTallas>;
    procedure ActualizarLineaExpandida(const ACelda: TCeldaTallas;
      const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
    procedure CrearLineaExpandida(ANuevaLinea: Integer;
      const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
      const ASku, AAlmacen: string);
    function ContarLineas: Integer;
    procedure PosicionarEn(APosicion: Integer);
    function LeerLineaActual: TLineaDocumentoTallas;
    procedure EscribirLineaActual(const ADatos: TEscrituraLineaTallas);
    procedure BorrarLineaActual;
    procedure IrAlPrimero;
    procedure SuspenderRefrescoVisual;
    procedure ReanudarRefrescoVisual;
    procedure CancelarEdicionPendiente;
    procedure ConfirmarEdicionPendiente;
    function LocalizarLineaConsolidable(ADistribuido: Boolean;
      const AArticulo, AAlmacen: string;
      const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
      APrecio: Double): Boolean;
    procedure AltaLineaResuelta(const ADatos: TAltaLineaTallas);
    function NumeroLineaActual: Integer;
    function AlmacenLineaActual(const ADefecto: string): string;
    function ConjuntoPivotActual: Integer;
    procedure IrALineaEnBlanco;
    procedure RefrescarTotales(
      const ATotales: TArray<TTotalLineaTallas>);
    procedure IniciarProceso;
    procedure TerminarProceso;
    procedure NotificarPostsSilenciados;
    property Profundidad: Integer read FProfundidad;
    property PostsNotificados: Integer read FPostsNotificados;
    property Creadas: Integer read FCreadas;
    property Actualizadas: Integer read FActualizadas;
  end;
  // Catalogo de atributos en memoria.
  TLookupAtributosMemoria = class(TInterfacedObject,
                                  IArticulosAtributosLookup)
  private
    FAtributos: TDictionary<string, TArray<TArticuloAtributo>>;
    FValores: TDictionary<string, TArray<TArticuloAtributoValor>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DefinirAtributos(const ACodigoArticulo: string;
      const AAtributos: TArray<TArticuloAtributo>);
    procedure DefinirValores(const ACodigoArticulo: string;
      AOrden: Integer;
      const AValores: TArray<TArticuloAtributoValor>);
    function ObtenerAtributos(const ACodigoArticulo: string)
      : TArray<TArticuloAtributo>;
    function ObtenerPropiedades(const ACodigoArticulo: string)
      : TArray<TArticuloPropiedad>;
    function ObtenerAtributosDeSku(const ACodigoSku: string)
      : TArray<TArticuloAtributoValor>;
    function ObtenerAvsEnSkus(const ACodigoArticulo: string;
      AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
  end;
  // Selector que devuelve siempre un valor fijo.
  TSelectorAvFijo = class(TInterfacedObject, ISelectorValorAtributo)
  private
    FValor: string;
    FAcepta: Boolean;
    FLlamadas: Integer;
  public
    constructor Create(const AValor: string; AAcepta: Boolean);
    function Seleccionar(const ANombreAtributo: string;
      const AValores: TArray<string>; out AValor: string): Boolean;
    property Llamadas: Integer read FLlamadas;
  end;

function Atributo(const AId, ANombre: string;
  AIdConjunto: Integer): TArticuloAtributo;
function ValorAtributo(AIdValor: Integer;
  const AValor: string): TArticuloAtributoValor;

implementation

function Atributo(const AId, ANombre: string;
  AIdConjunto: Integer): TArticuloAtributo;
begin
  Result := Default(TArticuloAtributo);
  Result.IdAtributo := AId;
  Result.NombreAtributo := ANombre;
  Result.IdConjunto := AIdConjunto;
end;

function ValorAtributo(AIdValor: Integer;
  const AValor: string): TArticuloAtributoValor;
begin
  Result := Default(TArticuloAtributoValor);
  Result.IdValor := AIdValor;
  Result.Valor := AValor;
  Result.EsActivo := True;
end;

constructor TPersistenciaTallasMemoria.Create;
begin
  inherited Create;
  FCeldas := TList<TCeldaMemoria>.Create;
  FConjuntosQueCubren := TList<Integer>.Create;
  FAlmacenEstandar := 'ALM1';
end;

destructor TPersistenciaTallasMemoria.Destroy;
begin
  FreeAndNil(FConjuntosQueCubren);
  FreeAndNil(FCeldas);
  inherited;
end;

function TPersistenciaTallasMemoria.IndiceCelda(ALinea, AIdAv: Integer;
  const AAlmacen: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FCeldas.Count - 1 do
  begin
    if (FCeldas[i].Linea = ALinea) and (FCeldas[i].IdAv = AIdAv) and
       SameText(FCeldas[i].Almacen, AAlmacen) then
      Result := i;
  end;
end;

procedure TPersistenciaTallasMemoria.AnyadirCelda(ALinea,
  AIdAv: Integer; const AValorTalla, AAlmacen: string;
  ACantidad: Double);
var
  Celda: TCeldaMemoria;
begin
  Celda.Linea := ALinea;
  Celda.IdAv := AIdAv;
  Celda.ValorTalla := AValorTalla;
  Celda.Almacen := AAlmacen;
  Celda.Cantidad := ACantidad;
  FCeldas.Add(Celda);
end;

function TPersistenciaTallasMemoria.TotalCeldas: Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FCeldas.Count - 1 do
    Result := Result + FCeldas[i].Cantidad;
end;

function TPersistenciaTallasMemoria.ContarCeldas: Integer;
begin
  Result := FCeldas.Count;
end;

function TPersistenciaTallasMemoria.CeldaEn(
  AIndice: Integer): TCeldaMemoria;
begin
  Result := FCeldas[AIndice];
end;

function TPersistenciaTallasMemoria.ConsultarTotalesPorLinea
  : TArray<TTotalLineaTallas>;
var
  Totales: TDictionary<Integer, Double>;
  Par: TPair<Integer, Double>;
  rAcumulado: Double;
  i, iTotal: Integer;
begin
  Result := nil;
  Totales := TDictionary<Integer, Double>.Create;
  try
    for i := 0 to FCeldas.Count - 1 do
    begin
      rAcumulado := 0;
      Totales.TryGetValue(FCeldas[i].Linea, rAcumulado);
      Totales.AddOrSetValue(FCeldas[i].Linea,
                            rAcumulado + FCeldas[i].Cantidad);
    end;
    iTotal := 0;
    for Par in Totales do
    begin
      SetLength(Result, iTotal + 1);
      Result[iTotal].Linea := Par.Key;
      Result[iTotal].Total := Par.Value;
      Inc(iTotal);
    end;
  finally
    FreeAndNil(Totales);
  end;
end;

function TPersistenciaTallasMemoria.ConsultarCeldasDocumento
  : TArray<TCeldaTallas>;
var
  i, iTotal: Integer;
begin
  Result := nil;
  iTotal := 0;
  for i := 0 to FCeldas.Count - 1 do
  begin
    if FCeldas[i].Cantidad > 0 then
    begin
      SetLength(Result, iTotal + 1);
      Result[iTotal].Linea := FCeldas[i].Linea;
      Result[iTotal].Almacen := FCeldas[i].Almacen;
      Result[iTotal].IdAv := FCeldas[i].IdAv;
      Result[iTotal].ValorTalla := FCeldas[i].ValorTalla;
      Result[iTotal].Cantidad := FCeldas[i].Cantidad;
      Inc(iTotal);
    end;
  end;
end;

function TPersistenciaTallasMemoria.ConsultarCeldasLinea(
  ALinea: Integer): TArray<TCeldaTallas>;
var
  i, iTotal: Integer;
begin
  Result := nil;
  iTotal := 0;
  for i := 0 to FCeldas.Count - 1 do
  begin
    if FCeldas[i].Linea = ALinea then
    begin
      SetLength(Result, iTotal + 1);
      Result[iTotal].Linea := FCeldas[i].Linea;
      Result[iTotal].Almacen := FCeldas[i].Almacen;
      Result[iTotal].IdAv := FCeldas[i].IdAv;
      Result[iTotal].ValorTalla := FCeldas[i].ValorTalla;
      Result[iTotal].Cantidad := FCeldas[i].Cantidad;
      Inc(iTotal);
    end;
  end;
end;

function TPersistenciaTallasMemoria.LineaTieneCeldas(
  ALinea: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FCeldas.Count - 1 do
  begin
    if FCeldas[i].Linea = ALinea then
      Result := True;
  end;
end;

procedure TPersistenciaTallasMemoria.SumarEnCelda(ALinea,
  AIdAv: Integer; ACantidad: Double; const AAlmacen: string);
var
  iIndice: Integer;
  Celda: TCeldaMemoria;
begin
  if FFallarAlSumar then
    raise Exception.Create('Fallo inyectado al sumar en celda');
  iIndice := IndiceCelda(ALinea, AIdAv, AAlmacen);
  if iIndice >= 0 then
  begin
    Celda := FCeldas[iIndice];
    Celda.Cantidad := Celda.Cantidad + ACantidad;
    FCeldas[iIndice] := Celda;
  end
  else
    AnyadirCelda(ALinea, AIdAv, '', AAlmacen, ACantidad);
end;

procedure TPersistenciaTallasMemoria.MoverCeldasALinea(AOrigen,
  ADestino: Integer);
var
  Celdas: TArray<TCeldaTallas>;
  i: Integer;
begin
  Celdas := ConsultarCeldasLinea(AOrigen);
  for i := 0 to High(Celdas) do
    SumarEnCelda(ADestino, Celdas[i].IdAv, Celdas[i].Cantidad,
                 Celdas[i].Almacen);
  for i := FCeldas.Count - 1 downto 0 do
  begin
    if FCeldas[i].Linea = AOrigen then
      FCeldas.Delete(i);
  end;
end;

function TPersistenciaTallasMemoria.MigrarCeldasFormato(
  ADistribuido: Boolean; const AAlmacenDefecto: string): Integer;
begin
  Result := FMigradas;
end;

procedure TPersistenciaTallasMemoria.BorrarCeldasDocumento;
begin
  FBorradoDocumento := True;
  FCeldas.Clear;
end;

function TPersistenciaTallasMemoria.BuscarConjuntoParaAvs(
  const AIdsValores: TArray<Integer>): Integer;
begin
  Result := 0;
  if Length(AIdsValores) > 0 then
    Result := FConjuntoPorAvs;
end;

function TPersistenciaTallasMemoria.ConjuntoCubreAvs(
  AIdConjunto: Integer; const AIdsValores: TArray<Integer>): Boolean;
begin
  Result := FConjuntosQueCubren.IndexOf(AIdConjunto) >= 0;
end;

function TPersistenciaTallasMemoria.PrimerAlmacenEstandar: string;
begin
  Result := FAlmacenEstandar;
end;

function TPersistenciaTallasMemoria.EnTransaccion: Boolean;
begin
  Result := FEnTransaccion;
end;

procedure TPersistenciaTallasMemoria.IniciarTransaccion;
begin
  Inc(FInicios);
  FEnTransaccion := True;
end;

procedure TPersistenciaTallasMemoria.ConfirmarTransaccion;
begin
  Inc(FConfirmaciones);
  FEnTransaccion := False;
end;

procedure TPersistenciaTallasMemoria.MarcarTransaccionActiva;
begin
  FEnTransaccion := True;
end;

procedure TPersistenciaTallasMemoria.RevertirTransaccion;
begin
  Inc(FReversiones);
  FEnTransaccion := False;
end;

constructor TLineasTallasMemoria.Create;
begin
  inherited Create;
  FLineas := TList<TLineaMemoria>.Create;
  FPosicion := 0;
end;

destructor TLineasTallasMemoria.Destroy;
begin
  FreeAndNil(FLineas);
  inherited;
end;

function TLineasTallasMemoria.IndiceDeLinea(ALinea: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FLineas.Count - 1 do
  begin
    if FLineas[i].Numero = ALinea then
      Result := i;
  end;
end;

procedure TLineasTallasMemoria.AnyadirLinea(
  const ALinea: TLineaMemoria);
begin
  FLineas.Add(ALinea);
end;

function TLineasTallasMemoria.LineaPorNumero(
  ALinea: Integer): TLineaMemoria;
var
  iIndice: Integer;
begin
  Result := Default(TLineaMemoria);
  iIndice := IndiceDeLinea(ALinea);
  if iIndice >= 0 then
    Result := FLineas[iIndice];
end;

function TLineasTallasMemoria.Contar: Integer;
begin
  Result := FLineas.Count;
end;

function TLineasTallasMemoria.LineaEn(
  AIndice: Integer): TLineaMemoria;
begin
  Result := FLineas[AIndice];
end;

function TLineasTallasMemoria.HayLineas: Boolean;
begin
  Result := FLineas.Count > 0;
end;

function TLineasTallasMemoria.MaximaLinea: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FLineas.Count - 1 do
  begin
    if FLineas[i].Numero > Result then
      Result := FLineas[i].Numero;
  end;
end;

function TLineasTallasMemoria.LeerDatosLinea(
  ALinea: Integer): TDatosLineaExpansion;
var
  iIndice: Integer;
begin
  Result := Default(TDatosLineaExpansion);
  Result.Numero := ALinea;
  Result.Primera := True;
  Result.OrdenTalla := -1;
  iIndice := IndiceDeLinea(ALinea);
  Result.Encontrada := iIndice >= 0;
  if Result.Encontrada then
  begin
    FPosicion := iIndice + 1;
    Result.Articulo := FLineas[iIndice].Articulo;
    Result.Descripcion := FLineas[iIndice].Descripcion;
    Result.Almacen := FLineas[iIndice].Almacen;
    Result.Precio := FLineas[iIndice].Precio;
    Result.Valores := FLineas[iIndice].Valores;
    Result.Nombres := FLineas[iIndice].Nombres;
  end;
end;

function TLineasTallasMemoria.CantidadesPorLinea
  : TArray<TCantidadLineaTallas>;
var
  i: Integer;
begin
  SetLength(Result, FLineas.Count);
  for i := 0 to FLineas.Count - 1 do
  begin
    Result[i].Linea := FLineas[i].Numero;
    Result[i].Cantidad := FLineas[i].Cantidad;
  end;
end;

procedure TLineasTallasMemoria.ActualizarLineaExpandida(
  const ACelda: TCeldaTallas; const ADatos: TDatosLineaExpansion;
  const ASku, AAlmacen: string);
var
  iIndice: Integer;
  Linea: TLineaMemoria;
begin
  Inc(FActualizadas);
  iIndice := IndiceDeLinea(ADatos.Numero);
  if iIndice >= 0 then
  begin
    Linea := FLineas[iIndice];
    Linea.Sku := ASku;
    Linea.Almacen := AAlmacen;
    Linea.Cantidad := ACelda.Cantidad;
    Linea.TieneCantidad := True;
    Linea.ConjuntoTalla := 0;
    FLineas[iIndice] := Linea;
  end;
end;

procedure TLineasTallasMemoria.CrearLineaExpandida(
  ANuevaLinea: Integer; const ACelda: TCeldaTallas;
  const ADatos: TDatosLineaExpansion; const ASku, AAlmacen: string);
var
  Linea: TLineaMemoria;
begin
  Inc(FCreadas);
  Linea := Default(TLineaMemoria);
  Linea.Numero := ANuevaLinea;
  Linea.Articulo := ADatos.Articulo;
  Linea.Descripcion := ADatos.Descripcion;
  Linea.Sku := ASku;
  Linea.Almacen := AAlmacen;
  Linea.Precio := ADatos.Precio;
  Linea.Cantidad := ACelda.Cantidad;
  Linea.TieneCantidad := True;
  Linea.Valores := ADatos.Valores;
  Linea.Nombres := ADatos.Nombres;
  FLineas.Add(Linea);
end;

function TLineasTallasMemoria.ContarLineas: Integer;
begin
  Result := FLineas.Count;
end;

procedure TLineasTallasMemoria.PosicionarEn(APosicion: Integer);
begin
  FPosicion := APosicion;
end;

function TLineasTallasMemoria.LeerLineaActual: TLineaDocumentoTallas;
var
  Linea: TLineaMemoria;
begin
  Result := Default(TLineaDocumentoTallas);
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
  begin
    Linea := FLineas[FPosicion - 1];
    Result.Numero := Linea.Numero;
    Result.Articulo := Linea.Articulo;
    Result.Sku := Linea.Sku;
    Result.Almacen := Linea.Almacen;
    Result.Cantidad := Linea.Cantidad;
    Result.Precio := Linea.Precio;
    Result.TieneAlmacen := Linea.TieneAlmacen;
    Result.TienePrecio := Linea.TienePrecio;
    Result.TieneCantidad := Linea.TieneCantidad;
  end;
end;

procedure TLineasTallasMemoria.EscribirLineaActual(
  const ADatos: TEscrituraLineaTallas);
var
  Linea: TLineaMemoria;
begin
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
  begin
    Linea := FLineas[FPosicion - 1];
    Linea.Almacen := ADatos.Almacen;
    Linea.Valores := ADatos.Valores;
    Linea.Nombres := ADatos.Nombres;
    Linea.ConjuntoTalla := ADatos.ConjuntoTalla;
    if ADatos.PonerCantidadCero then
      Linea.Cantidad := 0;
    FLineas[FPosicion - 1] := Linea;
  end;
end;

procedure TLineasTallasMemoria.BorrarLineaActual;
begin
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
    FLineas.Delete(FPosicion - 1);
end;

procedure TLineasTallasMemoria.IrAlPrimero;
begin
  FPosicion := 1;
end;

procedure TLineasTallasMemoria.SuspenderRefrescoVisual;
begin
  // Sin controles en memoria.
end;

procedure TLineasTallasMemoria.ReanudarRefrescoVisual;
begin
  // Sin controles en memoria.
end;

procedure TLineasTallasMemoria.CancelarEdicionPendiente;
begin
  // Sin dataset en memoria.
end;

procedure TLineasTallasMemoria.ConfirmarEdicionPendiente;
begin
  // Sin dataset en memoria.
end;

function TLineasTallasMemoria.LocalizarLineaConsolidable(
  ADistribuido: Boolean; const AArticulo, AAlmacen: string;
  const AValores: TValoresAttrTallas; ATienePrecio: Boolean;
  APrecio: Double): Boolean;
var
  i, j: Integer;
  bCoincide: Boolean;
begin
  Result := False;
  for i := 0 to FLineas.Count - 1 do
  begin
    if not Result then
    begin
      bCoincide := SameText(FLineas[i].Articulo, AArticulo);
      if bCoincide and (not ADistribuido) then
        bCoincide := SameText(FLineas[i].Almacen, AAlmacen);
      for j := 1 to 5 do
        if bCoincide then
          bCoincide := SameText(FLineas[i].Valores[j], AValores[j]);
      if bCoincide and ATienePrecio then
        bCoincide := Abs(FLineas[i].Precio - APrecio) < 0.005;
      if bCoincide then
      begin
        FPosicion := i + 1;
        Result := True;
      end;
    end;
  end;
end;

procedure TLineasTallasMemoria.AltaLineaResuelta(
  const ADatos: TAltaLineaTallas);
var
  Linea: TLineaMemoria;
begin
  Linea := Default(TLineaMemoria);
  Linea.Numero := MaximaLinea + 1;
  Linea.Articulo := ADatos.Articulo;
  Linea.Descripcion := ADatos.Descripcion;
  Linea.Almacen := ADatos.Almacen;
  Linea.Valores := ADatos.Valores;
  Linea.Nombres := ADatos.Nombres;
  Linea.ConjuntoTalla := ADatos.ConjuntoTalla;
  Linea.Precio := ADatos.Precio;
  Linea.TienePrecio := ADatos.TienePrecio;
  FLineas.Add(Linea);
  FPosicion := FLineas.Count;
end;

function TLineasTallasMemoria.NumeroLineaActual: Integer;
begin
  Result := 0;
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
    Result := FLineas[FPosicion - 1].Numero;
end;

function TLineasTallasMemoria.AlmacenLineaActual(
  const ADefecto: string): string;
begin
  Result := '';
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
  begin
    Result := FLineas[FPosicion - 1].Almacen;
    if Result = '' then
      Result := ADefecto;
  end;
end;

function TLineasTallasMemoria.ConjuntoPivotActual: Integer;
begin
  Result := 0;
  if (FPosicion >= 1) and (FPosicion <= FLineas.Count) then
    Result := FLineas[FPosicion - 1].ConjuntoTalla;
end;

procedure TLineasTallasMemoria.IrALineaEnBlanco;
begin
  FPosicion := 1;
end;

procedure TLineasTallasMemoria.RefrescarTotales(
  const ATotales: TArray<TTotalLineaTallas>);
begin
  // La prueba comprueba el calculo, no el volcado visual.
end;

procedure TLineasTallasMemoria.IniciarProceso;
begin
  Inc(FProfundidad);
end;

procedure TLineasTallasMemoria.TerminarProceso;
begin
  if FProfundidad > 0 then
    Dec(FProfundidad);
end;

procedure TLineasTallasMemoria.NotificarPostsSilenciados;
begin
  Inc(FPostsNotificados);
end;

constructor TLookupAtributosMemoria.Create;
begin
  inherited Create;
  FAtributos :=
    TDictionary<string, TArray<TArticuloAtributo>>.Create;
  FValores :=
    TDictionary<string, TArray<TArticuloAtributoValor>>.Create;
end;

destructor TLookupAtributosMemoria.Destroy;
begin
  FreeAndNil(FValores);
  FreeAndNil(FAtributos);
  inherited;
end;

procedure TLookupAtributosMemoria.DefinirAtributos(
  const ACodigoArticulo: string;
  const AAtributos: TArray<TArticuloAtributo>);
begin
  FAtributos.AddOrSetValue(UpperCase(ACodigoArticulo), AAtributos);
end;

procedure TLookupAtributosMemoria.DefinirValores(
  const ACodigoArticulo: string; AOrden: Integer;
  const AValores: TArray<TArticuloAtributoValor>);
begin
  FValores.AddOrSetValue(
    UpperCase(ACodigoArticulo) + '#' + IntToStr(AOrden), AValores);
end;

function TLookupAtributosMemoria.ObtenerAtributos(
  const ACodigoArticulo: string): TArray<TArticuloAtributo>;
begin
  Result := nil;
  FAtributos.TryGetValue(UpperCase(ACodigoArticulo), Result);
end;

function TLookupAtributosMemoria.ObtenerPropiedades(
  const ACodigoArticulo: string): TArray<TArticuloPropiedad>;
begin
  Result := nil;
end;

function TLookupAtributosMemoria.ObtenerAtributosDeSku(
  const ACodigoSku: string): TArray<TArticuloAtributoValor>;
begin
  Result := nil;
end;

function TLookupAtributosMemoria.ObtenerAvsEnSkus(
  const ACodigoArticulo: string;
  AOrdenAtributo: Integer): TArray<TArticuloAtributoValor>;
begin
  Result := nil;
  FValores.TryGetValue(
    UpperCase(ACodigoArticulo) + '#' + IntToStr(AOrdenAtributo),
    Result);
end;

constructor TSelectorAvFijo.Create(const AValor: string;
  AAcepta: Boolean);
begin
  inherited Create;
  FValor := AValor;
  FAcepta := AAcepta;
end;

function TSelectorAvFijo.Seleccionar(const ANombreAtributo: string;
  const AValores: TArray<string>; out AValor: string): Boolean;
begin
  Inc(FLlamadas);
  AValor := FValor;
  Result := FAcepta;
end;

end.
