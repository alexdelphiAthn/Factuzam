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

type
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

function TRepositorioInformeMovimientosVentasArticuloUniDAC.Preparar(
  const ACriterios: TCriteriosInformeMovimientosVentasArticulo
): IResultadoInformeMovimientosVentasArticulo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'CALL PRC_GET_MOV_VENTAS_ART(' +
      ':pDESDE, :pHASTA, :pINICMP, :pALM, :pFAM, :pPRV, :pTMP, :pART, ' +
      ':pN1, :pN2, :pN3, :pNFAM, :pSOLOVEN)';
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
