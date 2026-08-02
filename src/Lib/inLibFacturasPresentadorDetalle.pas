{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasPresentadorDetalle                               }
{    Tipo:       Presentador (sin VCL)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de visibilidad del detalle de factura y del modo de entrada.       }
{******************************************************************************}
unit inLibFacturasPresentadorDetalle;

interface

type
  // Puerto estrecho sobre las columnas del detalle. Lo implementa el
  // adaptador VCL; el presentador nunca conoce la rejilla.
  IColumnasDetalleFactura = interface
    ['{4F1B7C02-9D5E-4A6B-8C31-2A7D9E63B510}']
    procedure MostrarColumnasCreacion(AVisible: Boolean);
    procedure MostrarColumnaSku(AVisible: Boolean);
    function SkuVisible: Boolean;
    function TotalLineas: Integer;
    function ArticuloLinea(AIndice: Integer): string;
  end;
  // Regla de negocio del SKU por linea: solo procede cuando el articulo
  // tiene variacion (tallas/colores) o aun no existe en la BBDD.
  IReglaSkuFactura = interface
    ['{9C6E0B44-1F27-45D8-9E0A-6B8F3C21D774}']
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
  end;
  TSituacionDetalleFactura = record
    ModoCreacion: Boolean;
    ContratoActivo: Boolean;
    Construyendo: Boolean;
  end;
  // Reconstruccion del contrato de entrada al navegar de factura.
  TDecisionModoEntradaFactura = (
    dmefNinguna,
    dmefConstruir,
    dmefDesempaquetar);
  TSituacionModoEntradaFactura = record
    Construido: Boolean;
    ClasicoNecesario: Boolean;
    ContratoActivo: Boolean;
    ModoTallas: Boolean;
    ModoSku: Boolean;
  end;
  TPresentadorDetalleFactura = class
  private
    FColumnas: IColumnasDetalleFactura;
    FRegla: IReglaSkuFactura;
    FReaplicando: Boolean;
  public
    constructor Create(
      const AColumnas: IColumnasDetalleFactura;
      const ARegla: IReglaSkuFactura);
    destructor Destroy; override;
    function DebeMostrarSku(const ACodigoArticulo: string): Boolean;
    procedure SincronizarColumnasCreacion(AModoCreacion: Boolean);
    procedure SincronizarColumnaSku(
      const ASituacion: TSituacionDetalleFactura);
    procedure Reaplicar(const ASituacion: TSituacionDetalleFactura);
    property Reaplicando: Boolean read FReaplicando;
  end;

function CrearSituacionDetalleFactura(
  AModoCreacion, AContratoActivo,
  AConstruyendo: Boolean): TSituacionDetalleFactura;
// El alta de articulos inline (Crear/Act Articulo) exige la presentacion
// clasica: el contrato de entrada rechaza articulos inexistentes.
function ModoCreacionFacturaSolicitado(
  ACabeceraEnModoCreacion, ACheckMarcado: Boolean): Boolean;
function DecidirModoEntradaFactura(
  const ASituacion: TSituacionModoEntradaFactura
): TDecisionModoEntradaFactura;

implementation

function CrearSituacionDetalleFactura(
  AModoCreacion, AContratoActivo,
  AConstruyendo: Boolean): TSituacionDetalleFactura;
begin
  Result := Default(TSituacionDetalleFactura);
  Result.ModoCreacion := AModoCreacion;
  Result.ContratoActivo := AContratoActivo;
  Result.Construyendo := AConstruyendo;
end;

function ModoCreacionFacturaSolicitado(
  ACabeceraEnModoCreacion, ACheckMarcado: Boolean): Boolean;
begin
  Result := ACabeceraEnModoCreacion or ACheckMarcado;
end;

function DecidirModoEntradaFactura(
  const ASituacion: TSituacionModoEntradaFactura
): TDecisionModoEntradaFactura;
var
  bClasicoConstruido: Boolean;
begin
  // Red de seguridad: con la apertura asincrona el detalle aun no estaba
  // abierto al crear la pantalla y la construccion inicial se saltaba.
  if not ASituacion.Construido then
    Result := dmefConstruir
  else
  begin
    bClasicoConstruido := not ASituacion.ContratoActivo;
    if (ASituacion.ClasicoNecesario <> bClasicoConstruido) or
       ((not ASituacion.ClasicoNecesario) and ASituacion.ModoTallas) then
      Result := dmefConstruir
    else if ASituacion.ContratoActivo and (not ASituacion.ModoSku) then
      // En desglose basta desempaquetar SKU->ATTR de las lineas nuevas.
      Result := dmefDesempaquetar
    else
      Result := dmefNinguna;
  end;
end;

constructor TPresentadorDetalleFactura.Create(
  const AColumnas: IColumnasDetalleFactura;
  const ARegla: IReglaSkuFactura);
begin
  inherited Create;
  FColumnas := AColumnas;
  FRegla := ARegla;
  FReaplicando := False;
end;

destructor TPresentadorDetalleFactura.Destroy;
begin
  FColumnas := nil;
  FRegla := nil;
  inherited;
end;

function TPresentadorDetalleFactura.DebeMostrarSku(
  const ACodigoArticulo: string): Boolean;
begin
  Result := Assigned(FRegla) and FRegla.DebeMostrarSku(ACodigoArticulo);
end;

procedure TPresentadorDetalleFactura.SincronizarColumnasCreacion(
  AModoCreacion: Boolean);
begin
  if Assigned(FColumnas) then
    FColumnas.MostrarColumnasCreacion(AModoCreacion);
end;

procedure TPresentadorDetalleFactura.SincronizarColumnaSku(
  const ASituacion: TSituacionDetalleFactura);
var
  bMostrar: Boolean;
  iLinea: Integer;
begin
  // Con un modo del contrato construido, la columna SKU es del modo.
  if Assigned(FColumnas) and (not ASituacion.ContratoActivo) then
  begin
    // La columna solo aparece si alguna linea la necesita (variacion /
    // varios SKUs / articulo nuevo) o la cabecera esta en modo creacion.
    bMostrar := ASituacion.ModoCreacion;
    iLinea := 0;
    while (not bMostrar) and (iLinea < FColumnas.TotalLineas) do
    begin
      bMostrar := DebeMostrarSku(FColumnas.ArticuloLinea(iLinea));
      Inc(iLinea);
    end;
    if FColumnas.SkuVisible <> bMostrar then
      FColumnas.MostrarColumnaSku(bMostrar);
  end;
end;

procedure TPresentadorDetalleFactura.Reaplicar(
  const ASituacion: TSituacionDetalleFactura);
begin
  // Durante la reconstruccion del modo las columnas estan muertas
  // (ClearItems) hasta que el adaptador las reasigna.
  if (not ASituacion.Construyendo) and (not FReaplicando) then
  begin
    FReaplicando := True;
    try
      // Columnas de creacion: solo en modo creacion de la cabecera.
      // SKU: solo si alguna linea lo necesita o hay modo creacion.
      // Estas reglas mandan sobre el perfil de usuario.
      SincronizarColumnasCreacion(ASituacion.ModoCreacion);
      SincronizarColumnaSku(ASituacion);
    finally
      FReaplicando := False;
    end;
  end;
end;

end.
