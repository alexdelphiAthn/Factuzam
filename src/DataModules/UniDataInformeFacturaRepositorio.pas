unit UniDataInformeFacturaRepositorio;

interface

uses
  Uni, inLibInformeFacturaPersistenciaIntf;

function CrearPreparadorInformeFacturaUniDAC(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery): IPreparadorInformeFactura;

implementation

uses
  Data.DB;

type
  TPreparadorInformeFacturaUniDAC = class(
    TInterfacedObject,
    IPreparadorInformeFactura)
  private
    FConsultaFactura: TUniQuery;
    FConsultaLineas: TUniQuery;
    procedure PrepararActual(const ACriterios: TCriteriosInformeFactura);
    procedure PrepararRango(const ACriterios: TCriteriosInformeFactura);
  public
    constructor Create(
      AConsultaFactura: TUniQuery;
      AConsultaLineas: TUniQuery);
    procedure Preparar(const ACriterios: TCriteriosInformeFactura);
  end;

function SQLCamposOperacionCaja: string;
begin
  Result :=
    ', OC.ID_OPCAJA_FACOP AS ID_OPERACION_CAJA_FACTURA, ' +
    'CONCAT(''TA '', OC.NUMERO_OPERACION_OPCAJA, '' / ID '', ' +
    'OC.ID_OPCAJA_FACOP) AS DOCUMENTO_OPERACION_CAJA, ' +
    'OC.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION_CAJA, ' +
    'CASE WHEN OC.ID_OPCAJA_FACOP IS NULL THEN ''N'' ELSE ''S'' END ' +
    'AS ESFACTURA_TA_CAJA ';
end;

function SQLJoinOperacionCaja: string;
begin
  Result :=
    'LEFT JOIN (SELECT FO.ID_OPCAJA_FACOP, FO.SERIE_FAC_FACOP, ' +
    'FO.NUMERO_FAC_FACOP, O.NUMERO_OPERACION_OPCAJA, ' +
    'O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
    'O.CODIGO_CAJA_OPCAJA, COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)) AS FECHA_OPERACION_OPCAJA ' +
    'FROM fza_facturas_operaciones_caja FO ' +
    'INNER JOIN fza_caja_operaciones O ' +
    'ON O.ID_OPCAJA = FO.ID_OPCAJA_FACOP ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'') OC ' +
    'ON OC.SERIE_FAC_FACOP = L.SERIE_FAC_FACLIN ' +
    'AND OC.NUMERO_FAC_FACOP = L.NUMERO_FAC_FACLIN ' +
    'AND OC.CODIGO_EMP_OPCAJA = L.CODIGO_EMP_FACLIN ' +
    'AND OC.CODIGO_ALM_OPCAJA = L.CODIGO_ALM_FACLIN ' +
    'AND OC.CODIGO_CAJA_OPCAJA = L.CODIGO_CAJA_FACLIN ' +
    'AND OC.NUMERO_OPERACION_OPCAJA = ' +
    'L.NUMERO_OPERACION_FACLIN ';
end;

constructor TPreparadorInformeFacturaUniDAC.Create(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery);
begin
  inherited Create;
  FConsultaFactura := AConsultaFactura;
  FConsultaLineas := AConsultaLineas;
end;

procedure TPreparadorInformeFacturaUniDAC.PrepararActual(
  const ACriterios: TCriteriosInformeFactura);
begin
  FConsultaFactura.Close;
  FConsultaFactura.Params.Clear;
  FConsultaFactura.SQL.Text :=
    'SELECT * FROM vi_FACTURAS_print ' +
    'WHERE NUMERO_FAC = :numfac AND SERIE_FAC = :serie';
  FConsultaFactura.Params.ParamByName('numfac').Value := ACriterios.Numero;
  FConsultaFactura.Params.ParamByName('serie').Value := ACriterios.Serie;
  FConsultaFactura.Open;
  FConsultaLineas.Close;
  FConsultaLineas.Params.Clear;
  FConsultaLineas.SQL.Text :=
    'SELECT L.*, CASE ' +
    'WHEN COALESCE(CHAR_LENGTH(TRIM(L.CODIGO_UNIDAD_FACLIN)), 0) > 0 ' +
    'THEN CONCAT(L.CODIGO_UNIDAD_FACLIN, CHAR(32), ' +
    'L.DESCRIPCION_ARTICULO_FACLIN) ' +
    'ELSE L.DESCRIPCION_ARTICULO_FACLIN ' +
    'END AS DESCRIPCION_PRINT_FACLIN ' +
    SQLCamposOperacionCaja +
    'FROM fza_facturas_lineas L ' +
    SQLJoinOperacionCaja +
    'WHERE L.NUMERO_FAC_FACLIN = :numfac ' +
    'AND L.SERIE_FAC_FACLIN = :serie ' +
    'ORDER BY OC.FECHA_OPERACION_OPCAJA, OC.ID_OPCAJA_FACOP, ' +
    'L.LINEA_FACLIN';
  FConsultaLineas.Params.ParamByName('numfac').Value := ACriterios.Numero;
  FConsultaLineas.Params.ParamByName('serie').Value := ACriterios.Serie;
  FConsultaLineas.Open;
end;

procedure TPreparadorInformeFacturaUniDAC.PrepararRango(
  const ACriterios: TCriteriosInformeFactura);
begin
  FConsultaFactura.Close;
  FConsultaFactura.Params.Clear;
  FConsultaFactura.SQL.Text :=
    'SELECT * FROM VI_FACTURAS_PRINT ' +
    'WHERE FECHA_FAC >= :fecha_ini AND FECHA_FAC <= :fecha_fin ' +
    'ORDER BY NUMERO_FAC';
  FConsultaFactura.Params.ParamByName('fecha_ini').Value :=
    ACriterios.FechaDesde;
  FConsultaFactura.Params.ParamByName('fecha_fin').Value :=
    ACriterios.FechaHasta;
  FConsultaFactura.Open;
  FConsultaLineas.Close;
  FConsultaLineas.Params.Clear;
  FConsultaLineas.SQL.Text :=
    'SELECT L.*, CASE ' +
    'WHEN COALESCE(CHAR_LENGTH(TRIM(L.CODIGO_UNIDAD_FACLIN)), 0) > 0 ' +
    'THEN CONCAT(L.CODIGO_UNIDAD_FACLIN, CHAR(32), ' +
    'L.DESCRIPCION_ARTICULO_FACLIN) ' +
    'ELSE L.DESCRIPCION_ARTICULO_FACLIN ' +
    'END AS DESCRIPCION_PRINT_FACLIN ' +
    SQLCamposOperacionCaja +
    'FROM fza_facturas_lineas L ' +
    SQLJoinOperacionCaja +
    'INNER JOIN vi_FACTURAS_print F ' +
    'ON F.NUMERO_FAC = L.NUMERO_FAC_FACLIN ' +
    'AND F.SERIE_FAC = L.SERIE_FAC_FACLIN ' +
    'WHERE F.FECHA_FAC >= :fecha_ini ' +
    'AND F.FECHA_FAC <= :fecha_fin ' +
    'ORDER BY L.NUMERO_FAC_FACLIN, L.SERIE_FAC_FACLIN, ' +
    'OC.FECHA_OPERACION_OPCAJA, OC.ID_OPCAJA_FACOP, ' +
    'L.LINEA_FACLIN';
  FConsultaLineas.Params.ParamByName('fecha_ini').DataType := ftDate;
  FConsultaLineas.Params.ParamByName('fecha_ini').Value :=
    ACriterios.FechaDesde;
  FConsultaLineas.Params.ParamByName('fecha_fin').DataType := ftDate;
  FConsultaLineas.Params.ParamByName('fecha_fin').Value :=
    ACriterios.FechaHasta;
  FConsultaLineas.Open;
end;

procedure TPreparadorInformeFacturaUniDAC.Preparar(
  const ACriterios: TCriteriosInformeFactura);
begin
  if ACriterios.FacturaActual then
    PrepararActual(ACriterios)
  else
    PrepararRango(ACriterios);
end;

function CrearPreparadorInformeFacturaUniDAC(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery): IPreparadorInformeFactura;
begin
  Result := TPreparadorInformeFacturaUniDAC.Create(
    AConsultaFactura,
    AConsultaLineas);
end;

end.
