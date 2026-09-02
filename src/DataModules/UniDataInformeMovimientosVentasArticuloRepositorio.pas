unit UniDataInformeMovimientosVentasArticuloRepositorio;

interface

uses
  Uni, inLibInformeMovimientosVentasArticuloPersistenciaIntf;

function CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
  AConexion: TUniConnection):
  IRepositorioInformeMovimientosVentasArticulo;

implementation

uses
  System.SysUtils, Data.DB;

const
  FILAS_POR_BLOQUE_INFORME = 1000;

type
  TUniQueryMovimientosVentasArticulo = class(TUniQuery);

  TResultadoInformeMovimientosVentasArticuloUniDAC = class(
    TInterfacedObject,
    IResultadoInformeMovimientosVentasArticulo)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioInformeMovimientosVentasArticuloUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeMovimientosVentasArticulo)
  private
    FConexion: TUniConnection;
    function CodigoOrden(AOrden: TOrdenMovVentasArt): string;
  public
    constructor Create(AConexion: TUniConnection);
    function Preparar(
      const ACriterios: TCriteriosInformeMovimientosVentasArticulo
    ): IResultadoInformeMovimientosVentasArticulo;
  end;

constructor TResultadoInformeMovimientosVentasArticuloUniDAC.Create(
  ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoInformeMovimientosVentasArticuloUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TResultadoInformeMovimientosVentasArticuloUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioInformeMovimientosVentasArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeMovimientosVentasArticuloUniDAC.CodigoOrden(
  AOrden: TOrdenMovVentasArt): string;
begin
  case AOrden of
    omvaArticuloDescripcion:
      Result := 'AD';
    omvaUnidadesEntrada:
      Result := 'UE';
    omvaImporteEntrada:
      Result := 'IE';
    omvaUnidadesVenta:
      Result := 'UV';
    omvaImporteVenta:
      Result := 'IV';
    omvaImporteCoste:
      Result := 'IC';
    omvaBeneficio:
      Result := 'IB';
    omvaPorcentajeBeneficio:
      Result := 'PB';
    omvaVentaEntrada:
      Result := 'VC';
    omvaPorcentajeVentaEntrada:
      Result := 'VE';
    omvaMargen1:
      Result := 'M1';
    omvaMargen2:
      Result := 'M2';
    omvaPorcentajeVendido:
      Result := 'VD';
    omvaPorcentajeVentas:
      Result := 'PV';
  else
    Result := '';
  end;
end;

function TRepositorioInformeMovimientosVentasArticuloUniDAC.Preparar(
  const ACriterios: TCriteriosInformeMovimientosVentasArticulo
): IResultadoInformeMovimientosVentasArticulo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.FetchRows := FILAS_POR_BLOQUE_INFORME;
    TUniQueryMovimientosVentasArticulo(oConsulta).FetchAll := True;
    oConsulta.SQL.Text :=
      'CALL PRC_GET_MOV_VENTAS_ART(' +
      ':pDESDE, :pHASTA, :pINICMP, :pALM, :pFAM, :pPRV, :pTMP, :pART, ' +
      ':pN1, :pN2, :pN3, :pNFAM, :pSOLOVEN, :pCONIMP, :pORDEN, ' +
      ':pORDENDESC, :pENTGLOBAL)';
    oConsulta.ParamByName('pDESDE').AsDateTime := ACriterios.FechaDesde;
    oConsulta.ParamByName('pHASTA').AsDateTime := ACriterios.FechaHasta;
    if ACriterios.UsarInicioCompras then
      oConsulta.ParamByName('pINICMP').AsDateTime :=
        ACriterios.InicioCompras
    else
      oConsulta.ParamByName('pINICMP').Clear;
    oConsulta.ParamByName('pALM').AsString := ACriterios.Almacenes;
    oConsulta.ParamByName('pFAM').AsString := ACriterios.Familias;
    oConsulta.ParamByName('pPRV').AsString := ACriterios.Proveedores;
    oConsulta.ParamByName('pTMP').AsString := ACriterios.Temporadas;
    oConsulta.ParamByName('pART').AsString := ACriterios.Articulos;
    oConsulta.ParamByName('pN1').AsString := ACriterios.Nivel1;
    oConsulta.ParamByName('pN2').AsString := ACriterios.Nivel2;
    oConsulta.ParamByName('pN3').AsString := ACriterios.Nivel3;
    oConsulta.ParamByName('pNFAM').AsInteger := ACriterios.NivelFamilia;
    if ACriterios.SoloVentas then
      oConsulta.ParamByName('pSOLOVEN').AsString := 'S'
    else
      oConsulta.ParamByName('pSOLOVEN').AsString := 'N';
    if ACriterios.ConImpuestos then
      oConsulta.ParamByName('pCONIMP').AsString := 'S'
    else
      oConsulta.ParamByName('pCONIMP').AsString := 'N';
    if ACriterios.UsarOrden then
      oConsulta.ParamByName('pORDEN').AsString :=
        CodigoOrden(ACriterios.Orden)
    else
      oConsulta.ParamByName('pORDEN').AsString := '';
    if ACriterios.OrdenDescendente then
      oConsulta.ParamByName('pORDENDESC').AsString := 'S'
    else
      oConsulta.ParamByName('pORDENDESC').AsString := 'N';
    if ACriterios.EntradasGlobales then
      oConsulta.ParamByName('pENTGLOBAL').AsString := 'S'
    else
      oConsulta.ParamByName('pENTGLOBAL').AsString := 'N';
    oConsulta.Open;
    Result :=
      TResultadoInformeMovimientosVentasArticuloUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
  AConexion: TUniConnection):
  IRepositorioInformeMovimientosVentasArticulo;
begin
  Result :=
    TRepositorioInformeMovimientosVentasArticuloUniDAC.Create(AConexion);
end;

end.
