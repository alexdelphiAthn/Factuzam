unit UniDataInformeRecibosFacturaRepositorio;

interface

uses
  Uni, inLibInformeRecibosFacturaPersistenciaIntf;

function CrearPreparadorInformeRecibosFacturaUniDAC(
  AConsultaRecibos: TUniQuery): IPreparadorInformeRecibosFactura;

implementation

uses
  inLibFormatoDocumento;

type
  TPreparadorInformeRecibosFacturaUniDAC = class(
    TInterfacedObject,
    IPreparadorInformeRecibosFactura)
  private
    FConsultaRecibos: TUniQuery;
  public
    constructor Create(AConsultaRecibos: TUniQuery);
    procedure Preparar(
      const ACriterios: TCriteriosInformeRecibosFactura);
  end;

constructor TPreparadorInformeRecibosFacturaUniDAC.Create(
  AConsultaRecibos: TUniQuery);
begin
  inherited Create;
  FConsultaRecibos := AConsultaRecibos;
end;

procedure TPreparadorInformeRecibosFacturaUniDAC.Preparar(
  const ACriterios: TCriteriosInformeRecibosFactura);
begin
  FConsultaRecibos.Close;
  FConsultaRecibos.Params.Clear;
  FConsultaRecibos.SQL.Text :=
    'SELECT r.*, ' +
    ExpresionSqlFormatoDocumento(
      'emp.FORMATO_DOCUMENTO_EMP',
      'r.SERIE_FAC_REC',
      'r.NUMERO_FAC_REC') +
    ' AS DOCUMENTO_FACTURA_FORMATO ' +
    'FROM vi_recibos r ' +
    'LEFT JOIN fza_facturas fac ' +
    'ON fac.SERIE_FAC = r.SERIE_FAC_REC ' +
    'AND fac.NUMERO_FAC = r.NUMERO_FAC_REC ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC ' +
    'WHERE NUMERO_FAC_REC = :numfac ' +
    'AND SERIE_FAC_REC = :serie ';
  if ACriterios.ReciboActual then
    FConsultaRecibos.SQL.Add('AND NUMERO_PLAZO_REC = :recibo');
  FConsultaRecibos.Params.ParamByName('numfac').AsString :=
    ACriterios.NumeroFactura;
  FConsultaRecibos.Params.ParamByName('serie').AsString := ACriterios.Serie;
  if ACriterios.ReciboActual then
    FConsultaRecibos.Params.ParamByName('recibo').AsString :=
      ACriterios.NumeroRecibo;
  FConsultaRecibos.Open;
end;

function CrearPreparadorInformeRecibosFacturaUniDAC(
  AConsultaRecibos: TUniQuery): IPreparadorInformeRecibosFactura;
begin
  Result := TPreparadorInformeRecibosFacturaUniDAC.Create(AConsultaRecibos);
end;

end.
