{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDistribucionTiendas                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Modelo puro de la distribución entre tiendas. Las unidades del            }
{    documento de trabajo están en sus almacenes de origen; al indicar las     }
{    unidades de una tienda se descuentan del origen que más tenga (o del      }
{    fijado), respetando el mínimo en origen y lo ya confirmado. Incluye el    }
{    reparto automático parametrizable. Sin VCL ni acceso a datos.             }
{******************************************************************************}
unit inLibDistribucionTiendas;

interface

uses
  System.Generics.Collections,
  inLibDistribucionTiendasIntf;

type
  TCriterioRepartoAutomatico = (
    craOrdenAlmacen,
    craMenorStock
  );

  TParametrosRepartoAutomatico = record
    // Vacío: todas las tiendas que no sean origen del SKU.
    Destinos: TArray<string>;
    // Unidades de cada SKU que como mucho recibe una tienda; 0 = sin tope.
    MaximoPorDestino: Double;
    // No se envía a la tienda cuyo stock más lo asignado ya lo alcanza;
    // 0 = no se mira el stock.
    StockObjetivo: Double;
    Criterio: TCriterioRepartoAutomatico;
  end;

  TOpcionesOrigenDistribucion = record
    // Vacío: se descuenta del origen con más unidades.
    AlmacenFijado: string;
    // Unidades de cada SKU que se quedan sin repartir en cada origen.
    MinimoEnOrigen: Double;
  end;

  TMotivoAsignacionParcial = (
    mapNinguno,
    mapSinUnidades,
    mapSueloConfirmado,
    mapEsOrigen,
    mapSkuDesconocido
  );

  TResultadoAsignacion = record
    CantidadAplicada: Double;
    Motivo: TMotivoAsignacionParcial;
    function Completa: Boolean;
  end;

  // Fila del maestro: artículo y color.
  TGrupoDistribucion = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    Color: string;
    UnidadesDocumento: Double;
    UnidadesRepartidas: Double;
    function UnidadesPorRepartir: Double;
  end;
  TGruposDistribucion = TArray<TGrupoDistribucion>;

  // Columna del detalle: una talla (SKU) del grupo.
  TColumnaDistribucion = record
    CodigoSku: string;
    Talla: string;
    OrdenTalla: Integer;
  end;
  TColumnasDistribucion = TArray<TColumnaDistribucion>;

  TInfoSkuDistribucion = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoSku: string;
    Color: string;
    Talla: string;
    OrdenTalla: Integer;
  end;

  TDistribucionTiendas = class
  private
    FAlmacenes: TList<TAlmacenDistribucion>;
    FOrdenAlmacen: TDictionary<string, Integer>;
    FSkus: TList<TInfoSkuDistribucion>;
    FIndiceSku: TDictionary<string, Integer>;
    FOrigenesSku: TObjectDictionary<string, TList<string>>;
    FUnidadesOrigen: TDictionary<string, Double>;
    FRestanteOrigen: TDictionary<string, Double>;
    FRecibidoDestino: TDictionary<string, Double>;
    FConfirmadoDestino: TDictionary<string, Double>;
    FStock: TDictionary<string, Double>;
    FAsignaciones: TList<TAsignacionDistribucion>;
    FIndiceAsignacion: TDictionary<string, Integer>;
    FOpciones: TOpcionesOrigenDistribucion;
    FModificado: Boolean;
    procedure CargarAlmacenes(const AAlmacenes: TAlmacenesDistribucion);
    procedure AsegurarAlmacen(const ACodigo: string);
    procedure CargarUnidades(
      const AUnidades: TUnidadesDocumentoDistribucion);
    procedure RegistrarSku(const AUnidad: TUnidadDocumentoDistribucion);
    procedure RegistrarOrigen(const AAlmacen, ASku: string);
    procedure CargarAsignaciones(
      const AAsignaciones: TAsignacionesDistribucion);
    procedure CargarStocks(const AStocks: TStocksDistribucion);
    function OrdenDeAlmacen(const AAlmacen: string): Integer;
    procedure SumarEnDiccionario(
      ADiccionario: TDictionary<string, Double>;
      const AClave: string; ACantidad: Double);
    function IndiceAsignacion(
      const AOrigen, ADestino, ASku: string): Integer;
    function AsegurarAsignacion(
      const AOrigen, ADestino, ASku: string): Integer;
    procedure SumarPendiente(
      const AOrigen, ADestino, ASku: string; ACantidad: Double);
    function PendienteDe(const AOrigen, ADestino, ASku: string): Double;
    function DisponibleEnOrigen(const AOrigen, ASku: string): Double;
    function ElegirOrigenParaTomar(const ASku: string): string;
    function ElegirOrigenParaDevolver(
      const ADestino, ASku: string): string;
    function TomarDeOrigenes(
      const ADestino, ASku: string; ACantidad: Double): Double;
    procedure DevolverAOrigenes(
      const ADestino, ASku: string; ACantidad: Double);
    function DestinoAdmitido(
      const AParametros: TParametrosRepartoAutomatico;
      const AAlmacen, ASku: string): Boolean;
    function HuecoEnDestino(
      const AParametros: TParametrosRepartoAutomatico;
      const AAlmacen, ASku: string): Double;
    function ElegirDestinoAutomatico(
      const AParametros: TParametrosRepartoAutomatico;
      const ASku: string): string;
    function RepartirSkuAutomaticamente(
      const AParametros: TParametrosRepartoAutomatico;
      const ASku: string): Double;
  public
    constructor Create(const ADocumento: TDocumentoDistribucion);
    destructor Destroy; override;
    function Almacenes: TAlmacenesDistribucion;
    function Grupos: TGruposDistribucion;
    function Columnas(
      const ACodigoArticulo, AColor: string): TColumnasDistribucion;
    function ConoceSku(const ASku: string): Boolean;
    function EsOrigen(const AAlmacen, ASku: string): Boolean;
    // Valor de la celda: lo que queda en un origen o lo que recibe un
    // destino (confirmado más pendiente).
    function UnidadesEnAlmacen(const AAlmacen, ASku: string): Double;
    function UnidadesConfirmadas(const AAlmacen, ASku: string): Double;
    function UnidadesDocumento(const AAlmacen, ASku: string): Double;
    function Stock(const AAlmacen, ASku: string): Double;
    function FijarUnidadesDestino(
      const AAlmacen, ASku: string;
      ACantidad: Double): TResultadoAsignacion;
    function RepartirAutomaticamente(
      const AParametros: TParametrosRepartoAutomatico): Double;
    procedure QuitarPendientes;
    function Asignaciones: TAsignacionesDistribucion;
    // Cierto si algún origen tiene repartidas más unidades de las que el
    // documento le atribuye (se rebajó el documento después de repartir).
    function HayOrigenExcedido: Boolean;
    procedure MarcarGuardado;
    property Opciones: TOpcionesOrigenDistribucion
      read FOpciones write FOpciones;
    property Modificado: Boolean read FModificado;
  end;

const
  TOLERANCIA_UNIDADES_DISTRIBUCION = 0.000001;

function ClaveGrupoDistribucion(
  const ACodigoArticulo, AColor: string): string;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Defaults;

const
  SEPARADOR_CLAVE = #9;
  PASO_UNIDAD = 1.0;

function Normalizar(const ATexto: string): string;
begin
  Result := AnsiUpperCase(Trim(ATexto));
end;

function ClaveAlmacenSku(const AAlmacen, ASku: string): string;
begin
  Result := Normalizar(AAlmacen) + SEPARADOR_CLAVE + Normalizar(ASku);
end;

function ClaveAsignacion(const AOrigen, ADestino, ASku: string): string;
begin
  Result := Normalizar(AOrigen) + SEPARADOR_CLAVE +
    Normalizar(ADestino) + SEPARADOR_CLAVE + Normalizar(ASku);
end;

function ClaveGrupoDistribucion(
  const ACodigoArticulo, AColor: string): string;
begin
  Result := Normalizar(ACodigoArticulo) + SEPARADOR_CLAVE +
    Normalizar(AColor);
end;

function EsPositiva(ACantidad: Double): Boolean;
begin
  Result := ACantidad > TOLERANCIA_UNIDADES_DISTRIBUCION;
end;

function TResultadoAsignacion.Completa: Boolean;
begin
  Result := Motivo = mapNinguno;
end;

function TGrupoDistribucion.UnidadesPorRepartir: Double;
begin
  Result := UnidadesDocumento - UnidadesRepartidas;
end;

// ===========================================================================
//   Carga del documento
// ===========================================================================

constructor TDistribucionTiendas.Create(
  const ADocumento: TDocumentoDistribucion);
begin
  inherited Create;
  FAlmacenes := TList<TAlmacenDistribucion>.Create;
  FOrdenAlmacen := TDictionary<string, Integer>.Create;
  FSkus := TList<TInfoSkuDistribucion>.Create;
  FIndiceSku := TDictionary<string, Integer>.Create;
  FOrigenesSku := TObjectDictionary<string, TList<string>>.Create(
    [doOwnsValues]);
  FUnidadesOrigen := TDictionary<string, Double>.Create;
  FRestanteOrigen := TDictionary<string, Double>.Create;
  FRecibidoDestino := TDictionary<string, Double>.Create;
  FConfirmadoDestino := TDictionary<string, Double>.Create;
  FStock := TDictionary<string, Double>.Create;
  FAsignaciones := TList<TAsignacionDistribucion>.Create;
  FIndiceAsignacion := TDictionary<string, Integer>.Create;
  FOpciones := Default(TOpcionesOrigenDistribucion);
  CargarAlmacenes(ADocumento.Almacenes);
  CargarUnidades(ADocumento.Unidades);
  CargarAsignaciones(ADocumento.Asignaciones);
  CargarStocks(ADocumento.Stocks);
  FModificado := False;
end;

destructor TDistribucionTiendas.Destroy;
begin
  FreeAndNil(FIndiceAsignacion);
  FreeAndNil(FAsignaciones);
  FreeAndNil(FStock);
  FreeAndNil(FConfirmadoDestino);
  FreeAndNil(FRecibidoDestino);
  FreeAndNil(FRestanteOrigen);
  FreeAndNil(FUnidadesOrigen);
  FreeAndNil(FOrigenesSku);
  FreeAndNil(FIndiceSku);
  FreeAndNil(FSkus);
  FreeAndNil(FOrdenAlmacen);
  FreeAndNil(FAlmacenes);
  inherited Destroy;
end;

procedure TDistribucionTiendas.CargarAlmacenes(
  const AAlmacenes: TAlmacenesDistribucion);
var
  i: Integer;
begin
  for i := 0 to High(AAlmacenes) do
  begin
    if not FOrdenAlmacen.ContainsKey(Normalizar(AAlmacenes[i].Codigo)) then
    begin
      FOrdenAlmacen.Add(
        Normalizar(AAlmacenes[i].Codigo), FAlmacenes.Count);
      FAlmacenes.Add(AAlmacenes[i]);
    end;
  end;
end;

// Un origen del documento que no venga en el catálogo (inactivo o de otro
// tipo de uso) tiene que verse igualmente: si no, sus unidades se pierden.
procedure TDistribucionTiendas.AsegurarAlmacen(const ACodigo: string);
var
  Almacen: TAlmacenDistribucion;
begin
  if not FOrdenAlmacen.ContainsKey(Normalizar(ACodigo)) then
  begin
    Almacen := Default(TAlmacenDistribucion);
    Almacen.Codigo := Trim(ACodigo);
    Almacen.Nombre := Trim(ACodigo);
    Almacen.Orden := MaxInt;
    FOrdenAlmacen.Add(Normalizar(ACodigo), FAlmacenes.Count);
    FAlmacenes.Add(Almacen);
  end;
end;

procedure TDistribucionTiendas.RegistrarSku(
  const AUnidad: TUnidadDocumentoDistribucion);
var
  Info: TInfoSkuDistribucion;
begin
  if not FIndiceSku.ContainsKey(Normalizar(AUnidad.CodigoSku)) then
  begin
    Info := Default(TInfoSkuDistribucion);
    Info.CodigoArticulo := Trim(AUnidad.CodigoArticulo);
    Info.DescripcionArticulo := Trim(AUnidad.DescripcionArticulo);
    Info.CodigoSku := Trim(AUnidad.CodigoSku);
    Info.Color := Trim(AUnidad.Color);
    Info.Talla := Trim(AUnidad.Talla);
    Info.OrdenTalla := AUnidad.OrdenTalla;
    FIndiceSku.Add(Normalizar(AUnidad.CodigoSku), FSkus.Count);
    FSkus.Add(Info);
  end;
end;

procedure TDistribucionTiendas.RegistrarOrigen(
  const AAlmacen, ASku: string);
var
  Origenes: TList<string>;
begin
  if not FOrigenesSku.TryGetValue(Normalizar(ASku), Origenes) then
  begin
    Origenes := TList<string>.Create;
    FOrigenesSku.Add(Normalizar(ASku), Origenes);
  end;
  if Origenes.IndexOf(Normalizar(AAlmacen)) < 0 then
    Origenes.Add(Normalizar(AAlmacen));
end;

procedure TDistribucionTiendas.CargarUnidades(
  const AUnidades: TUnidadesDocumentoDistribucion);
var
  i: Integer;
  sClave: string;
  dAnterior: Double;
begin
  for i := 0 to High(AUnidades) do
  begin
    if (Trim(AUnidades[i].CodigoSku) <> '') and
       (Trim(AUnidades[i].CodigoAlmacen) <> '') and
       EsPositiva(AUnidades[i].Cantidad) then
    begin
      AsegurarAlmacen(AUnidades[i].CodigoAlmacen);
      RegistrarSku(AUnidades[i]);
      RegistrarOrigen(AUnidades[i].CodigoAlmacen, AUnidades[i].CodigoSku);
      sClave := ClaveAlmacenSku(
        AUnidades[i].CodigoAlmacen, AUnidades[i].CodigoSku);
      if not FUnidadesOrigen.TryGetValue(sClave, dAnterior) then
        dAnterior := 0;
      FUnidadesOrigen.AddOrSetValue(
        sClave, dAnterior + AUnidades[i].Cantidad);
      FRestanteOrigen.AddOrSetValue(
        sClave, dAnterior + AUnidades[i].Cantidad);
    end;
  end;
end;

// Solo cuentan las asignaciones coherentes con el documento: el SKU tiene
// que seguir en él y el origen tiene que seguir siéndolo.
procedure TDistribucionTiendas.CargarAsignaciones(
  const AAsignaciones: TAsignacionesDistribucion);
var
  i: Integer;
  iIndice: Integer;
  Asignacion: TAsignacionDistribucion;
  sClaveOrigen: string;
  sClaveDestino: string;
begin
  for i := 0 to High(AAsignaciones) do
  begin
    if ConoceSku(AAsignaciones[i].CodigoSku) and
       EsOrigen(AAsignaciones[i].AlmacenOrigen,
         AAsignaciones[i].CodigoSku) and
       not EsOrigen(AAsignaciones[i].AlmacenDestino,
         AAsignaciones[i].CodigoSku) then
    begin
      AsegurarAlmacen(AAsignaciones[i].AlmacenDestino);
      iIndice := AsegurarAsignacion(
        AAsignaciones[i].AlmacenOrigen,
        AAsignaciones[i].AlmacenDestino,
        AAsignaciones[i].CodigoSku);
      Asignacion := FAsignaciones[iIndice];
      Asignacion.CantidadConfirmada := Asignacion.CantidadConfirmada +
        Max(AAsignaciones[i].CantidadConfirmada, 0);
      Asignacion.CantidadPendiente := Asignacion.CantidadPendiente +
        Max(AAsignaciones[i].CantidadPendiente, 0);
      FAsignaciones[iIndice] := Asignacion;
      sClaveOrigen := ClaveAlmacenSku(
        AAsignaciones[i].AlmacenOrigen, AAsignaciones[i].CodigoSku);
      FRestanteOrigen[sClaveOrigen] := FRestanteOrigen[sClaveOrigen] -
        Max(AAsignaciones[i].CantidadConfirmada, 0) -
        Max(AAsignaciones[i].CantidadPendiente, 0);
      sClaveDestino := ClaveAlmacenSku(
        AAsignaciones[i].AlmacenDestino, AAsignaciones[i].CodigoSku);
      SumarEnDiccionario(FConfirmadoDestino, sClaveDestino,
        Max(AAsignaciones[i].CantidadConfirmada, 0));
      SumarEnDiccionario(FRecibidoDestino, sClaveDestino,
        Max(AAsignaciones[i].CantidadConfirmada, 0) +
        Max(AAsignaciones[i].CantidadPendiente, 0));
    end;
  end;
end;

procedure TDistribucionTiendas.CargarStocks(
  const AStocks: TStocksDistribucion);
var
  i: Integer;
  sClave: string;
  dAnterior: Double;
begin
  for i := 0 to High(AStocks) do
  begin
    sClave := ClaveAlmacenSku(
      AStocks[i].CodigoAlmacen, AStocks[i].CodigoSku);
    if not FStock.TryGetValue(sClave, dAnterior) then
      dAnterior := 0;
    FStock.AddOrSetValue(sClave, dAnterior + AStocks[i].Cantidad);
  end;
end;

// ===========================================================================
//   Consultas
// ===========================================================================

function TDistribucionTiendas.Almacenes: TAlmacenesDistribucion;
begin
  Result := FAlmacenes.ToArray;
end;

function TDistribucionTiendas.OrdenDeAlmacen(
  const AAlmacen: string): Integer;
begin
  if not FOrdenAlmacen.TryGetValue(Normalizar(AAlmacen), Result) then
    Result := MaxInt;
end;

function TDistribucionTiendas.ConoceSku(const ASku: string): Boolean;
begin
  Result := FIndiceSku.ContainsKey(Normalizar(ASku));
end;

function TDistribucionTiendas.EsOrigen(
  const AAlmacen, ASku: string): Boolean;
begin
  Result := FUnidadesOrigen.ContainsKey(ClaveAlmacenSku(AAlmacen, ASku));
end;

function TDistribucionTiendas.UnidadesDocumento(
  const AAlmacen, ASku: string): Double;
begin
  if not FUnidadesOrigen.TryGetValue(
    ClaveAlmacenSku(AAlmacen, ASku), Result) then
    Result := 0;
end;

function TDistribucionTiendas.Stock(const AAlmacen, ASku: string): Double;
begin
  if not FStock.TryGetValue(ClaveAlmacenSku(AAlmacen, ASku), Result) then
    Result := 0;
end;

procedure TDistribucionTiendas.SumarEnDiccionario(
  ADiccionario: TDictionary<string, Double>;
  const AClave: string; ACantidad: Double);
var
  dAnterior: Double;
begin
  if not ADiccionario.TryGetValue(AClave, dAnterior) then
    dAnterior := 0;
  dAnterior := dAnterior + ACantidad;
  if Abs(dAnterior) < TOLERANCIA_UNIDADES_DISTRIBUCION then
    dAnterior := 0;
  ADiccionario.AddOrSetValue(AClave, dAnterior);
end;

function TDistribucionTiendas.UnidadesConfirmadas(
  const AAlmacen, ASku: string): Double;
begin
  if not FConfirmadoDestino.TryGetValue(
    ClaveAlmacenSku(AAlmacen, ASku), Result) then
    Result := 0;
end;

function TDistribucionTiendas.UnidadesEnAlmacen(
  const AAlmacen, ASku: string): Double;
var
  sClave: string;
begin
  sClave := ClaveAlmacenSku(AAlmacen, ASku);
  if not FRestanteOrigen.TryGetValue(sClave, Result) and
     not FRecibidoDestino.TryGetValue(sClave, Result) then
    Result := 0;
end;

function TDistribucionTiendas.Grupos: TGruposDistribucion;
var
  Indices: TDictionary<string, Integer>;
  Lista: TList<TGrupoDistribucion>;
  Grupo: TGrupoDistribucion;
  Origenes: TList<string>;
  i, j, iGrupo: Integer;
  sClave: string;
  dDocumento, dRestante: Double;
begin
  Indices := TDictionary<string, Integer>.Create;
  Lista := TList<TGrupoDistribucion>.Create;
  try
    for i := 0 to FSkus.Count - 1 do
    begin
      sClave := ClaveGrupoDistribucion(
        FSkus[i].CodigoArticulo, FSkus[i].Color);
      if not Indices.TryGetValue(sClave, iGrupo) then
      begin
        Grupo := Default(TGrupoDistribucion);
        Grupo.CodigoArticulo := FSkus[i].CodigoArticulo;
        Grupo.DescripcionArticulo := FSkus[i].DescripcionArticulo;
        Grupo.Color := FSkus[i].Color;
        iGrupo := Lista.Count;
        Indices.Add(sClave, iGrupo);
        Lista.Add(Grupo);
      end;
      Grupo := Lista[iGrupo];
      Origenes := FOrigenesSku[Normalizar(FSkus[i].CodigoSku)];
      for j := 0 to Origenes.Count - 1 do
      begin
        sClave := ClaveAlmacenSku(Origenes[j], FSkus[i].CodigoSku);
        dDocumento := FUnidadesOrigen[sClave];
        dRestante := FRestanteOrigen[sClave];
        Grupo.UnidadesDocumento := Grupo.UnidadesDocumento + dDocumento;
        Grupo.UnidadesRepartidas := Grupo.UnidadesRepartidas +
          (dDocumento - dRestante);
      end;
      Lista[iGrupo] := Grupo;
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
    FreeAndNil(Indices);
  end;
end;

function TDistribucionTiendas.Columnas(
  const ACodigoArticulo, AColor: string): TColumnasDistribucion;
var
  Lista: TList<TColumnaDistribucion>;
  Columna: TColumnaDistribucion;
  i: Integer;
  sClave: string;
begin
  sClave := ClaveGrupoDistribucion(ACodigoArticulo, AColor);
  Lista := TList<TColumnaDistribucion>.Create;
  try
    for i := 0 to FSkus.Count - 1 do
    begin
      if ClaveGrupoDistribucion(
           FSkus[i].CodigoArticulo, FSkus[i].Color) = sClave then
      begin
        Columna.CodigoSku := FSkus[i].CodigoSku;
        Columna.Talla := FSkus[i].Talla;
        Columna.OrdenTalla := FSkus[i].OrdenTalla;
        Lista.Add(Columna);
      end;
    end;
    Lista.Sort(TComparer<TColumnaDistribucion>.Construct(
      function(const AIzquierda,
        ADerecha: TColumnaDistribucion): Integer
      begin
        Result := CompareValue(AIzquierda.OrdenTalla, ADerecha.OrdenTalla);
        if Result = 0 then
          Result := AnsiCompareText(AIzquierda.Talla, ADerecha.Talla);
        if Result = 0 then
          Result := AnsiCompareText(
            AIzquierda.CodigoSku, ADerecha.CodigoSku);
      end));
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

// ===========================================================================
//   Asignaciones
// ===========================================================================

function TDistribucionTiendas.IndiceAsignacion(
  const AOrigen, ADestino, ASku: string): Integer;
begin
  if not FIndiceAsignacion.TryGetValue(
    ClaveAsignacion(AOrigen, ADestino, ASku), Result) then
    Result := -1;
end;

function TDistribucionTiendas.AsegurarAsignacion(
  const AOrigen, ADestino, ASku: string): Integer;
var
  Asignacion: TAsignacionDistribucion;
begin
  Result := IndiceAsignacion(AOrigen, ADestino, ASku);
  if Result < 0 then
  begin
    Asignacion := Default(TAsignacionDistribucion);
    Asignacion.AlmacenOrigen := FAlmacenes[OrdenDeAlmacen(AOrigen)].Codigo;
    Asignacion.AlmacenDestino :=
      FAlmacenes[OrdenDeAlmacen(ADestino)].Codigo;
    Asignacion.CodigoSku :=
      FSkus[FIndiceSku[Normalizar(ASku)]].CodigoSku;
    Result := FAsignaciones.Count;
    FIndiceAsignacion.Add(
      ClaveAsignacion(AOrigen, ADestino, ASku), Result);
    FAsignaciones.Add(Asignacion);
  end;
end;

function TDistribucionTiendas.PendienteDe(
  const AOrigen, ADestino, ASku: string): Double;
var
  iIndice: Integer;
begin
  Result := 0;
  iIndice := IndiceAsignacion(AOrigen, ADestino, ASku);
  if iIndice >= 0 then
    Result := FAsignaciones[iIndice].CantidadPendiente;
end;

procedure TDistribucionTiendas.SumarPendiente(
  const AOrigen, ADestino, ASku: string; ACantidad: Double);
var
  iIndice: Integer;
  Asignacion: TAsignacionDistribucion;
  sClaveOrigen: string;
begin
  iIndice := AsegurarAsignacion(AOrigen, ADestino, ASku);
  Asignacion := FAsignaciones[iIndice];
  Asignacion.CantidadPendiente := Asignacion.CantidadPendiente + ACantidad;
  if Abs(Asignacion.CantidadPendiente) <
     TOLERANCIA_UNIDADES_DISTRIBUCION then
    Asignacion.CantidadPendiente := 0;
  FAsignaciones[iIndice] := Asignacion;
  sClaveOrigen := ClaveAlmacenSku(AOrigen, ASku);
  FRestanteOrigen[sClaveOrigen] :=
    FRestanteOrigen[sClaveOrigen] - ACantidad;
  SumarEnDiccionario(
    FRecibidoDestino, ClaveAlmacenSku(ADestino, ASku), ACantidad);
  FModificado := True;
end;

function TDistribucionTiendas.DisponibleEnOrigen(
  const AOrigen, ASku: string): Double;
begin
  Result := 0;
  if EsOrigen(AOrigen, ASku) then
    Result := FRestanteOrigen[ClaveAlmacenSku(AOrigen, ASku)] -
      Max(FOpciones.MinimoEnOrigen, 0);
  if Result < 0 then
    Result := 0;
end;

// El origen del que se descuenta: el fijado o, si no hay, el que más
// unidades disponibles tenga (a igualdad, el primero del catálogo).
function TDistribucionTiendas.ElegirOrigenParaTomar(
  const ASku: string): string;
var
  Origenes: TList<string>;
  i: Integer;
  dMejor, dDisponible: Double;
begin
  Result := '';
  dMejor := 0;
  if FOrigenesSku.TryGetValue(Normalizar(ASku), Origenes) then
  begin
    for i := 0 to Origenes.Count - 1 do
    begin
      if (Trim(FOpciones.AlmacenFijado) = '') or
         SameText(Origenes[i], Normalizar(FOpciones.AlmacenFijado)) then
      begin
        dDisponible := DisponibleEnOrigen(Origenes[i], ASku);
        if EsPositiva(dDisponible) and
           ((Result = '') or
            (dDisponible > dMejor + TOLERANCIA_UNIDADES_DISTRIBUCION) or
            (SameValue(dDisponible, dMejor,
               TOLERANCIA_UNIDADES_DISTRIBUCION) and
             (OrdenDeAlmacen(Origenes[i]) < OrdenDeAlmacen(Result)))) then
        begin
          Result := Origenes[i];
          dMejor := dDisponible;
        end;
      end;
    end;
  end;
end;

// Al rebajar una tienda, las unidades vuelven al origen que menos tenga.
function TDistribucionTiendas.ElegirOrigenParaDevolver(
  const ADestino, ASku: string): string;
var
  Origenes: TList<string>;
  i: Integer;
  dMenor, dRestante: Double;
begin
  Result := '';
  dMenor := 0;
  if FOrigenesSku.TryGetValue(Normalizar(ASku), Origenes) then
  begin
    for i := 0 to Origenes.Count - 1 do
    begin
      if EsPositiva(PendienteDe(Origenes[i], ADestino, ASku)) then
      begin
        dRestante := FRestanteOrigen[ClaveAlmacenSku(Origenes[i], ASku)];
        if (Result = '') or
           (dRestante < dMenor - TOLERANCIA_UNIDADES_DISTRIBUCION) then
        begin
          Result := Origenes[i];
          dMenor := dRestante;
        end;
      end;
    end;
  end;
end;

// Unidad a unidad, para que con varios orígenes se vaya compensando.
function TDistribucionTiendas.TomarDeOrigenes(
  const ADestino, ASku: string; ACantidad: Double): Double;
var
  sOrigen: string;
  dFalta, dPaso: Double;
begin
  Result := 0;
  dFalta := ACantidad;
  sOrigen := ElegirOrigenParaTomar(ASku);
  while EsPositiva(dFalta) and (sOrigen <> '') do
  begin
    dPaso := Min(dFalta,
      Min(PASO_UNIDAD, DisponibleEnOrigen(sOrigen, ASku)));
    SumarPendiente(sOrigen, ADestino, ASku, dPaso);
    Result := Result + dPaso;
    dFalta := dFalta - dPaso;
    sOrigen := ElegirOrigenParaTomar(ASku);
  end;
end;

procedure TDistribucionTiendas.DevolverAOrigenes(
  const ADestino, ASku: string; ACantidad: Double);
var
  sOrigen: string;
  dFalta, dPaso: Double;
begin
  dFalta := ACantidad;
  sOrigen := ElegirOrigenParaDevolver(ADestino, ASku);
  while EsPositiva(dFalta) and (sOrigen <> '') do
  begin
    dPaso := Min(dFalta,
      Min(PASO_UNIDAD, PendienteDe(sOrigen, ADestino, ASku)));
    SumarPendiente(sOrigen, ADestino, ASku, -dPaso);
    dFalta := dFalta - dPaso;
    sOrigen := ElegirOrigenParaDevolver(ADestino, ASku);
  end;
end;

function TDistribucionTiendas.FijarUnidadesDestino(
  const AAlmacen, ASku: string;
  ACantidad: Double): TResultadoAsignacion;
var
  dDeseada, dSuelo, dActual, dTomado: Double;
begin
  Result.Motivo := mapNinguno;
  if not ConoceSku(ASku) then
    Result.Motivo := mapSkuDesconocido
  else if EsOrigen(AAlmacen, ASku) then
    Result.Motivo := mapEsOrigen
  else
  begin
    AsegurarAlmacen(AAlmacen);
    dDeseada := Max(ACantidad, 0);
    dSuelo := UnidadesConfirmadas(AAlmacen, ASku);
    if dDeseada < dSuelo - TOLERANCIA_UNIDADES_DISTRIBUCION then
    begin
      dDeseada := dSuelo;
      Result.Motivo := mapSueloConfirmado;
    end;
    dActual := UnidadesEnAlmacen(AAlmacen, ASku);
    if dDeseada > dActual + TOLERANCIA_UNIDADES_DISTRIBUCION then
    begin
      dTomado := TomarDeOrigenes(AAlmacen, ASku, dDeseada - dActual);
      if dTomado < (dDeseada - dActual) -
         TOLERANCIA_UNIDADES_DISTRIBUCION then
        Result.Motivo := mapSinUnidades;
    end
    else if dDeseada < dActual - TOLERANCIA_UNIDADES_DISTRIBUCION then
      DevolverAOrigenes(AAlmacen, ASku, dActual - dDeseada);
  end;
  if Result.Motivo = mapSkuDesconocido then
    Result.CantidadAplicada := 0
  else
    Result.CantidadAplicada := UnidadesEnAlmacen(AAlmacen, ASku);
end;

procedure TDistribucionTiendas.QuitarPendientes;
var
  i: Integer;
  Asignacion: TAsignacionDistribucion;
begin
  for i := 0 to FAsignaciones.Count - 1 do
  begin
    Asignacion := FAsignaciones[i];
    if EsPositiva(Asignacion.CantidadPendiente) then
      SumarPendiente(
        Asignacion.AlmacenOrigen,
        Asignacion.AlmacenDestino,
        Asignacion.CodigoSku,
        -Asignacion.CantidadPendiente);
  end;
end;

function TDistribucionTiendas.Asignaciones: TAsignacionesDistribucion;
var
  Lista: TList<TAsignacionDistribucion>;
  i: Integer;
begin
  Lista := TList<TAsignacionDistribucion>.Create;
  try
    for i := 0 to FAsignaciones.Count - 1 do
    begin
      if EsPositiva(FAsignaciones[i].CantidadPendiente) or
         EsPositiva(FAsignaciones[i].CantidadConfirmada) then
        Lista.Add(FAsignaciones[i]);
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TDistribucionTiendas.HayOrigenExcedido: Boolean;
var
  dRestante: Double;
begin
  Result := False;
  for dRestante in FRestanteOrigen.Values do
  begin
    if dRestante < -TOLERANCIA_UNIDADES_DISTRIBUCION then
      Result := True;
  end;
end;

procedure TDistribucionTiendas.MarcarGuardado;
begin
  FModificado := False;
end;

// ===========================================================================
//   Reparto automático
// ===========================================================================

function TDistribucionTiendas.DestinoAdmitido(
  const AParametros: TParametrosRepartoAutomatico;
  const AAlmacen, ASku: string): Boolean;
var
  i: Integer;
begin
  Result := not EsOrigen(AAlmacen, ASku);
  if Result and (Length(AParametros.Destinos) > 0) then
  begin
    Result := False;
    for i := 0 to High(AParametros.Destinos) do
    begin
      if SameText(Normalizar(AParametros.Destinos[i]),
           Normalizar(AAlmacen)) then
        Result := True;
    end;
  end;
end;

// Unidades que todavía admite la tienda según el tope y el stock objetivo.
function TDistribucionTiendas.HuecoEnDestino(
  const AParametros: TParametrosRepartoAutomatico;
  const AAlmacen, ASku: string): Double;
var
  dAsignado: Double;
begin
  Result := MaxDouble;
  dAsignado := UnidadesEnAlmacen(AAlmacen, ASku);
  if EsPositiva(AParametros.MaximoPorDestino) then
    Result := Min(Result, AParametros.MaximoPorDestino - dAsignado);
  if EsPositiva(AParametros.StockObjetivo) then
    Result := Min(Result,
      AParametros.StockObjetivo - Stock(AAlmacen, ASku) - dAsignado);
  if Result < 0 then
    Result := 0;
end;

// Por orden: la tienda que menos lleva asignado (ronda). Por menor stock:
// la que menos tendría contando lo asignado. A igualdad, la primera.
function TDistribucionTiendas.ElegirDestinoAutomatico(
  const AParametros: TParametrosRepartoAutomatico;
  const ASku: string): string;
var
  i: Integer;
  dMejor, dValor: Double;
begin
  Result := '';
  dMejor := 0;
  for i := 0 to FAlmacenes.Count - 1 do
  begin
    if DestinoAdmitido(AParametros, FAlmacenes[i].Codigo, ASku) and
       EsPositiva(HuecoEnDestino(
         AParametros, FAlmacenes[i].Codigo, ASku)) then
    begin
      dValor := UnidadesEnAlmacen(FAlmacenes[i].Codigo, ASku);
      if AParametros.Criterio = craMenorStock then
        dValor := dValor + Stock(FAlmacenes[i].Codigo, ASku);
      if (Result = '') or
         (dValor < dMejor - TOLERANCIA_UNIDADES_DISTRIBUCION) then
      begin
        Result := FAlmacenes[i].Codigo;
        dMejor := dValor;
      end;
    end;
  end;
end;

function TDistribucionTiendas.RepartirSkuAutomaticamente(
  const AParametros: TParametrosRepartoAutomatico;
  const ASku: string): Double;
var
  sOrigen, sDestino: string;
  dPaso: Double;
begin
  Result := 0;
  sOrigen := ElegirOrigenParaTomar(ASku);
  sDestino := ElegirDestinoAutomatico(AParametros, ASku);
  while (sOrigen <> '') and (sDestino <> '') do
  begin
    dPaso := Min(PASO_UNIDAD, DisponibleEnOrigen(sOrigen, ASku));
    dPaso := Min(dPaso, HuecoEnDestino(AParametros, sDestino, ASku));
    SumarPendiente(sOrigen, sDestino, ASku, dPaso);
    Result := Result + dPaso;
    sOrigen := ElegirOrigenParaTomar(ASku);
    sDestino := ElegirDestinoAutomatico(AParametros, ASku);
  end;
end;

// Añade sobre lo ya asignado: lo tecleado a mano se respeta.
function TDistribucionTiendas.RepartirAutomaticamente(
  const AParametros: TParametrosRepartoAutomatico): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FSkus.Count - 1 do
    Result := Result + RepartirSkuAutomaticamente(
      AParametros, FSkus[i].CodigoSku);
end;

end.
