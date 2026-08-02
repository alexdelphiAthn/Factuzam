{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosPresentacion                                  }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones de presentacion del grid de lineas de inventario: plan de      }
{    columnas de atributo, modo de entrada Auto/SKU/Tallas y calculos de       }
{    linea. Sin VCL, sin datasets y sin SQL: todo es funcion pura.             }
{******************************************************************************}
unit inLibInventariosPresentacion;

interface

uses
  inLibColumnasSkuIntf,
  inLibInventariosAplicacionIntf,
  inLibInventariosPresentacionIntf;

const
  // Cuadrado de color (18) + separacion (6) + margenes (10) + aire (10).
  MARGEN_SWATCH_INVENTARIO = 44;

type
  TConsultaNombresAtributosInventario = reference to function(
    const ACodigoArticulo: string): TArray<string>;

// Envuelve la lectura concreta de la definicion de atributos en el puerto
// que consume la presentacion de columnas.
function CrearLookupAtributosInventario(
  const AConsulta: TConsultaNombresAtributosInventario):
  IAtributosInventarioLookup;

// Columnas de atributo visibles segun los nombres disponibles.
function PlanColumnasAtributosInventario(
  const ANombres: TArray<string>;
  ANumeroVisibles: Integer): TPlanColumnasAtributosInventario;
// Traduce el estado del grid en la unica accion que debe ejecutarse.
function DecidirAccionColumnasInventario(
  const ASituacion: TSituacionColumnasInventario):
  TAccionColumnasInventario;
// El ancho de una columna de atributo solo crece, nunca encoge.
function AnchoColumnaAtributoInventario(
  AAnchoTexto, AAnchoActual: Integer): Integer;
// SKU cerrado: tantos separadores como atributos exige la linea.
function EsSkuCompletoInventario(
  const ASku: string; ANumeroAtributosRequeridos: Integer): Boolean;
// CODIGO_UNIDAD_INVLIN es NOT NULL: nunca puede quedar vacio.
function SkuEfectivoInventario(
  const ASkuGenerado, ACodigoArticulo: string): string;
function DiferenciaUnidadesInventario(
  AFisicas, ATeoricas: Currency): Currency;
function DiferenciaCosteInventario(
  AFisicas, ATeoricas, APrecioNuevo, APrecioActual: Currency): Currency;
// El ciclo de F1 en inventarios: solo Auto y SKU. Los modos de tallas en
// horizontal quedaron descartados porque cada linea lleva DOS cantidades
// (teorica y recuento) y una celda de pivote solo representa una.
function ModoEntradaInventarioSoportado(
  AModo: TModoColumnasSku): Boolean;
function ModoEntradaInventarioSiguiente(
  AModo: TModoColumnasSku): TModoColumnasSku;
function MuestraAtributosEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
function DesempaquetarAlCargarEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
function CaptionDetalleInventario(
  AModoDetectado: TModoColumnasSku): string;
// Mensaje para el usuario del resultado de resolver una entrada.
function MensajeErrorEntradaInventario(
  const AResultado: TResultadoEntradaInventario): string;
// Tooltip explicativo de las columnas clave del grid de lineas. Se
// resuelve por campo para seguir vivo tras el ClearItems del contrato.
function HintCeldaInventario(const ACampo: string): string;

implementation

uses
  System.SysUtils,
  inLibMsgArticulos;

type
  TLookupAtributosInventario = class(
    TInterfacedObject,
    IAtributosInventarioLookup)
  private
    FConsulta: TConsultaNombresAtributosInventario;
  public
    constructor Create(
      const AConsulta: TConsultaNombresAtributosInventario);
    function NombresAtributosArticulo(
      const ACodigoArticulo: string): TArray<string>;
  end;

constructor TLookupAtributosInventario.Create(
  const AConsulta: TConsultaNombresAtributosInventario);
begin
  inherited Create;
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  FConsulta := AConsulta;
end;

function TLookupAtributosInventario.NombresAtributosArticulo(
  const ACodigoArticulo: string): TArray<string>;
begin
  Result := FConsulta(ACodigoArticulo);
end;

function CrearLookupAtributosInventario(
  const AConsulta: TConsultaNombresAtributosInventario):
  IAtributosInventarioLookup;
begin
  Result := TLookupAtributosInventario.Create(AConsulta);
end;

function PlanColumnasAtributosInventario(
  const ANombres: TArray<string>;
  ANumeroVisibles: Integer): TPlanColumnasAtributosInventario;
var
  iColumna: Integer;
  iVisibles: Integer;
begin
  iVisibles := ANumeroVisibles;
  if iVisibles > MAX_ATRIBUTOS_INVENTARIO then
    iVisibles := MAX_ATRIBUTOS_INVENTARIO;
  if iVisibles < 0 then
    iVisibles := 0;
  for iColumna := 1 to MAX_ATRIBUTOS_INVENTARIO do
  begin
    if iColumna <= iVisibles then
    begin
      if iColumna <= Length(ANombres) then
        Result[iColumna].Caption := ANombres[iColumna - 1]
      else
        Result[iColumna].Caption := Format(SCaptionAtributoN, [iColumna]);
      Result[iColumna].Visible := True;
      Result[iColumna].Editable := True;
    end
    else
    begin
      Result[iColumna].Caption := '-';
      Result[iColumna].Visible := False;
      Result[iColumna].Editable := False;
    end;
  end;
end;

function DecidirAccionColumnasInventario(
  const ASituacion: TSituacionColumnasInventario):
  TAccionColumnasInventario;
begin
  // El orden reproduce el de la pantalla: el contrato de entrada manda
  // sobre todo lo demas y la memoizacion por articulo padre es la ultima
  // puerta antes de repintar.
  if ASituacion.ContratoConstruido then
    Result := aciNinguna
  else if not ASituacion.MostrarAtributos then
    Result := aciOcultarTodas
  else if not ASituacion.HayOrigenDeDatos then
    Result := aciOcultarTodas
  else if ASituacion.LineasEnEdicion then
    Result := aciColumnasDelArticulo
  else if ASituacion.MismoArticuloPadre then
    Result := aciNinguna
  else if not ASituacion.VistaAplicada then
    Result := aciColumnasDeLaVista
  else
    Result := aciSoloModoEntrada;
end;

function AnchoColumnaAtributoInventario(
  AAnchoTexto, AAnchoActual: Integer): Integer;
begin
  Result := AAnchoActual;
  if AAnchoActual < AAnchoTexto + MARGEN_SWATCH_INVENTARIO then
    Result := AAnchoTexto + MARGEN_SWATCH_INVENTARIO;
end;

function EsSkuCompletoInventario(
  const ASku: string; ANumeroAtributosRequeridos: Integer): Boolean;
var
  iCaracter: Integer;
  iSeparadores: Integer;
begin
  iSeparadores := 0;
  for iCaracter := 1 to Length(ASku) do
  begin
    if ASku[iCaracter] = '/' then
      Inc(iSeparadores);
  end;
  Result := (ANumeroAtributosRequeridos > 0) and
            (iSeparadores = ANumeroAtributosRequeridos);
end;

function SkuEfectivoInventario(
  const ASkuGenerado, ACodigoArticulo: string): string;
begin
  Result := ASkuGenerado;
  if Trim(ASkuGenerado) = '' then
    Result := ACodigoArticulo;
end;

function DiferenciaUnidadesInventario(
  AFisicas, ATeoricas: Currency): Currency;
begin
  Result := AFisicas - ATeoricas;
end;

function DiferenciaCosteInventario(
  AFisicas, ATeoricas, APrecioNuevo, APrecioActual: Currency): Currency;
begin
  Result := (AFisicas * APrecioNuevo) - (ATeoricas * APrecioActual);
end;

function ModoEntradaInventarioSoportado(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo in [mcsAuto, mcsSku];
end;

function ModoEntradaInventarioSiguiente(
  AModo: TModoColumnasSku): TModoColumnasSku;
begin
  // Ciclo real de la pantalla: Auto -> SKU -> Auto. Cualquier modo no
  // soportado vuelve al primero del ciclo.
  if AModo = mcsAuto then
    Result := mcsSku
  else
    Result := mcsAuto;
end;

function MuestraAtributosEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo <> mcsSku;
end;

function DesempaquetarAlCargarEnModoInventario(
  AModo: TModoColumnasSku): Boolean;
begin
  Result := AModo <> mcsSku;
end;

function CaptionDetalleInventario(
  AModoDetectado: TModoColumnasSku): string;
begin
  if AModoDetectado = mcsSku then
    Result := SCaptionTabDetalleInventarioSku
  else
    Result := SCaptionTabDetalleInventarioDesglose;
end;

function MensajeErrorEntradaInventario(
  const AResultado: TResultadoEntradaInventario): string;
begin
  Result := '';
  case AResultado.Error of
    eeiArticuloNoEncontrado:
      Result := SErrorArticuloInventarioNoEncontrado;
    eeiTipoArticuloSinStock:
      Result := Format(SErrorArticuloInventarioTipoSinStock,
        [AResultado.CodigoArticulo, AResultado.TipoArticulo]);
    eeiAtributosRequierenSku:
      Result := Format(SErrorArticuloInventarioAtributosSinSku,
        [AResultado.CodigoArticulo]);
    eeiLineasNoAbiertas:
      Result := SErrorLineasInventarioNoAbiertas;
    eeiLineaNoEditable:
      Result := SErrorLineaInventarioNoEditable;
  end;
end;

function HintCeldaInventario(const ACampo: string): string;
begin
  Result := '';
  if ACampo = 'CANTIDAD_TEORICA_INVLIN' then
    Result := 'Stock que el sistema cree que hay en el almacén'
  else if ACampo = 'CANTIDAD_FISICA_INVLIN' then
    Result := 'Lo que realmente has contado'
  else if ACampo = 'PRECIO_MEDIO_NUEVO_INVLIN' then
    Result := 'Precio Medio que tendrá el SKU tras aplicar el inventario'
  else if ACampo = 'UDS_REGULARIZADAS' then
    Result := 'Solo se rellena cuando el inventario está APLICADO';
end;

end.
