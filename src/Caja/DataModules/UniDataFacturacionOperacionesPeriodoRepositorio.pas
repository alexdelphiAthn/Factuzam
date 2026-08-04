{******************************************************************************}
{  Módulo: UniDataFacturacionOperacionesPeriodoRepositorio                    }
{  Tipo: Adaptador UniDAC                                                     }
{  Descripción: Materializa proformas VE y facturas fiscales TA por periodo.  }
{******************************************************************************}
unit UniDataFacturacionOperacionesPeriodoRepositorio;

interface

uses
  Uni, inLibParametrosIntf, inLibEmisionFiscalIntf,
  inLibFacturacionOperacionesPeriodoIntf,
  inLibFacturacionOperacionesPeriodoPersistenciaIntf;

function CrearServicioFacturacionOperacionesPeriodoUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal
): IServicioFacturacionOperacionesPeriodo;
function CrearRepositorioInformeFacturacionOperacionesPeriodoUniDAC(
  AConexion: TUniConnection
): IRepositorioInformeFacturacionOperacionesPeriodo;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  inLibFacturacionOperacionesPeriodo, inLibVerifactu,
  inLibMsgFacturacionOperacionesPeriodo,
  UniDataFacturacionOperacionesPeriodoSql;

const
  SQL_LIMPIAR_TEMPORAL = 'DELETE FROM tmp_facturacion_periodo';
  SQL_CONTAR_TEMPORAL =
    'SELECT COUNT(*) AS TOTAL FROM tmp_facturacion_periodo';
  SQL_LISTAR_GRUPOS =
    'SELECT TIPO_FACTURACION, CODIGO_EMP_DESTINO, ' +
    '       ID_CFPER_ANTERIOR, COUNT(*) AS OPERACIONES ' +
    '  FROM tmp_facturacion_periodo ' +
    ' GROUP BY TIPO_FACTURACION, CODIGO_EMP_DESTINO, ' +
    '          ID_CFPER_ANTERIOR ' +
    ' ORDER BY TIPO_FACTURACION, CODIGO_EMP_DESTINO, ' +
    '          ID_CFPER_ANTERIOR';
  SQL_ULTIMO_ID = 'SELECT LAST_INSERT_ID() AS ID';
  SQL_ACTUALIZAR_IMPORTES_OPERACION =
    'UPDATE fza_caja_facturacion_operaciones o ' +
    '  JOIN (SELECT l.ID_CFOP_CFLIN, SUM(l.TOTAL_LINEA_CFLIN) TOTAL ' +
    '          FROM fza_caja_facturacion_lineas l ' +
    '         GROUP BY l.ID_CFOP_CFLIN) x ' +
    '    ON x.ID_CFOP_CFLIN = o.ID_CFOP ' +
    '   SET o.IMPORTE_DOCUMENTO_CFOP = x.TOTAL, ' +
    '       o.INSTANTE_MODIF = NOW(), o.USUARIO_MODIF = :USUARIO ' +
    ' WHERE o.ID_CFPER_CFOP = :ID_DOCUMENTO';
  SQL_ASIGNAR_DOCUMENTO =
    'UPDATE fza_caja_facturaciones_periodo ' +
    '   SET SERIE_DOCUMENTO_CFPER = :SERIE, ' +
    '       NUMERO_DOCUMENTO_CFPER = :NUMERO, ' +
    '       ESTADO_PROCESO_CFPER = ''COMPLETADO'', ' +
    '       ESTADO_FISCAL_CFPER = :ESTADO_FISCAL, ' +
    '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_CFPER = :ID_DOCUMENTO';
  SQL_VALIDAR_SERIE =
    'SELECT COUNT(*) AS TOTAL FROM fza_empresas_series ' +
    ' WHERE CODIGO_EMP_SERIE = :EMPRESA AND SERIE_SERIE = :SERIE ' +
    '   AND TIPO_DOC_SERIE = ''FC'' AND SUBTIPO_SERIE = ''NORMAL'' ' +
    '   AND (FECHA_DESDE_SERIE IS NULL OR FECHA_DESDE_SERIE <= :FECHA) ' +
    '   AND (FECHA_HASTA_SERIE IS NULL OR FECHA_HASTA_SERIE >= :FECHA)';
  SQL_SERIE_DEFECTO =
    'SELECT SERIE_SERIE FROM fza_empresas_series ' +
    ' WHERE CODIGO_EMP_SERIE = :EMPRESA AND TIPO_DOC_SERIE = ''FC'' ' +
    '   AND SUBTIPO_SERIE = ''NORMAL'' ' +
    '   AND (FECHA_DESDE_SERIE IS NULL OR FECHA_DESDE_SERIE <= :FECHA) ' +
    '   AND (FECHA_HASTA_SERIE IS NULL OR FECHA_HASTA_SERIE >= :FECHA) ' +
    ' ORDER BY FECHA_DESDE_SERIE DESC, CODIGO_SERIE DESC LIMIT 1';
  SQL_DATOS_EMPRESA_DESTINO =
    'SELECT RAZON_SOCIAL_EMP, NIF_EMP, DIRECCION1_EMP, ' +
    '       CODIGO_PAI_EMP, NOMBRE_PAI_EMP ' +
    '  FROM fza_empresas WHERE CODIGO_EMP_EMP = :EMPRESA';
  SQL_RELACIONAR_RECTIFICATIVA =
    'INSERT INTO fza_facturas_relaciones (SERIE_FAC_FACREL, ' +
    '  NUMERO_FAC_FACREL, SERIE_FAC_ORIGEN_FACREL, ' +
    '  NUMERO_FAC_ORIGEN_FACREL, TIPO_RELACION_FACREL, ' +
    '  INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :SERIE, :NUMERO, SERIE_DOCUMENTO_CFPER, ' +
    '       NUMERO_DOCUMENTO_CFPER, ''RECTIFICA'', NOW(), NOW(), ' +
    '       :USUARIO, :USUARIO ' +
    '  FROM fza_caja_facturaciones_periodo ' +
    ' WHERE ID_CFPER = :ID_ORIGEN';
  SQL_MARCAR_FACTURA_RECTIFICADA =
    'UPDATE fza_facturas f JOIN fza_caja_facturaciones_periodo d ' +
    '    ON f.SERIE_FAC = d.SERIE_DOCUMENTO_CFPER ' +
    '   AND f.NUMERO_FAC = d.NUMERO_DOCUMENTO_CFPER ' +
    '   SET f.FASE_FAC = ''RECTIFICADA'', ' +
    '       f.SERIE_FAC_ABONO_FAC = :SERIE, ' +
    '       f.NUMERO_FAC_ABONO_FAC = :NUMERO, ' +
    '       f.INSTANTE_MODIF = NOW(), f.USUARIO_MODIF = :USUARIO ' +
    ' WHERE d.ID_CFPER = :ID_ORIGEN';

type
  TGrupoPendientePeriodo = record
    Tipo: string;
    EmpresaDestino: string;
    IdDocumentoAnterior: Int64;
    Operaciones: Integer;
  end;
  TGruposPendientesPeriodo = TArray<TGrupoPendientePeriodo>;
  TResultadoInformeFacturacionPeriodoUniDAC = class(
    TInterfacedObject,
    IResultadoInformeFacturacionOperacionesPeriodo)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;
  TRepositorioInformeFacturacionPeriodoUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeFacturacionOperacionesPeriodo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Consultar(
      const ASolicitud: TSolicitudInformeFacturacionOperacionesPeriodo
    ): IResultadoInformeFacturacionOperacionesPeriodo;
  end;
  TServicioFacturacionOperacionesPeriodoUniDAC = class(
    TInterfacedObject,
    IServicioFacturacionOperacionesPeriodo)
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FServicioEmision: IServicioEmisionFiscal;
    procedure AsignarPeriodo(
      AConsulta: TUniQuery;
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
    procedure PrepararTemporal(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
    procedure ValidarSolicitud(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
    procedure ValidarSerieFiscal(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
    procedure ValidarEmpresaDestino(const AEmpresa: string);
    function ContarTemporal: Integer;
    function CargarGrupos: TGruposPendientesPeriodo;
    function InsertarCabecera(
      const AGrupo: TGrupoPendientePeriodo;
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Int64;
    function InsertarOperaciones(
      AIdDocumento: Int64;
      const AGrupo: TGrupoPendientePeriodo;
      const AUsuario: string): Integer;
    function InsertarLineas(
      AIdDocumento: Int64;
      const AGrupo: TGrupoPendientePeriodo;
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Integer;
    procedure ActualizarTotales(
      AIdDocumento: Int64;
      const AUsuario: string);
    function ObtenerNumeroFiscal(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): string;
    procedure AsignarDocumento(
      AIdDocumento: Int64;
      const ASerie, ANumero, AEstadoFiscal, AUsuario: string);
    procedure CrearFacturaFiscal(
      AIdDocumento: Int64;
      const AGrupo: TGrupoPendientePeriodo;
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
    procedure ProcesarGrupo(
      const AGrupo: TGrupoPendientePeriodo;
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo;
      var AResultado: TResultadoFacturacionOperacionesPeriodo);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AServicioEmision: IServicioEmisionFiscal);
    destructor Destroy; override;
    function ObtenerSerieFiscalDefecto(
      const AEmpresa: string;
      AFecha: TDateTime): string;
    function ContarOperacionesPendientes(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Integer;
    function Procesar(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo
    ): TResultadoFacturacionOperacionesPeriodo;
  end;

constructor TResultadoInformeFacturacionPeriodoUniDAC.Create(
  AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TResultadoInformeFacturacionPeriodoUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TResultadoInformeFacturacionPeriodoUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioInformeFacturacionPeriodoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeFacturacionPeriodoUniDAC.Consultar(
  const ASolicitud: TSolicitudInformeFacturacionOperacionesPeriodo
): IResultadoInformeFacturacionOperacionesPeriodo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlConsultarInformeFacturacionPeriodo;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
    oConsulta.ParamByName('HASTA').AsDate := Trunc(ASolicitud.FechaHasta);
    oConsulta.Open;
    Result := TResultadoInformeFacturacionPeriodoUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TServicioFacturacionOperacionesPeriodoUniDAC.Create(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal);
begin
  inherited Create;
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  if not Assigned(AParametrosApp) then
  begin
    raise EArgumentNilException.Create('AParametrosApp');
  end;
  if not Assigned(AServicioEmision) then
  begin
    raise EArgumentNilException.Create('AServicioEmision');
  end;
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FServicioEmision := AServicioEmision;
end;

destructor TServicioFacturacionOperacionesPeriodoUniDAC.Destroy;
begin
  FServicioEmision := nil;
  FParametrosApp := nil;
  inherited;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.AsignarPeriodo(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
begin
  AConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
  AConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
  AConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
  AConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
  AConsulta.ParamByName('HASTA').AsDate := Trunc(ASolicitud.FechaHasta);
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.PrepararTemporal(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlCrearTemporalFacturacionPeriodo;
    oConsulta.Execute;
    oConsulta.SQL.Text := SQL_LIMPIAR_TEMPORAL;
    oConsulta.Execute;
    if ASolicitud.IncluirVentasContado then
    begin
      oConsulta.SQL.Text := SqlCargarVentasPendientesPeriodo;
      AsignarPeriodo(oConsulta, ASolicitud);
      oConsulta.Execute;
    end;
    if ASolicitud.IncluirTraspasosEmpresas then
    begin
      oConsulta.SQL.Text := SqlCargarTraspasosPendientesPeriodo;
      AsignarPeriodo(oConsulta, ASolicitud);
      oConsulta.Execute;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.ValidarSolicitud(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
var
  oValidacion: TValidacionFacturacionOperacionesPeriodo;
begin
  oValidacion := ValidarSolicitudFacturacionOperacionesPeriodo(ASolicitud);
  if not oValidacion.EsValida then
  begin
    raise EArgumentException.Create(oValidacion.Mensaje);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.ValidarSerieFiscal(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
var
  oConsulta: TUniQuery;
begin
  if ASolicitud.IncluirTraspasosEmpresas then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_VALIDAR_SERIE;
      oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
      oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieFiscal;
      oConsulta.ParamByName('FECHA').AsDate :=
        Trunc(ASolicitud.FechaDocumento);
      oConsulta.Open;
      if oConsulta.FieldByName('TOTAL').AsInteger <> 1 then
      begin
        raise EArgumentException.Create(
          SErrorSerieFiscalFacturacionPeriodoNoValida);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.ValidarEmpresaDestino(
  const AEmpresa: string);
var
  oConsulta: TUniQuery;
  bValida: Boolean;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_DATOS_EMPRESA_DESTINO;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    bValida := not oConsulta.IsEmpty;
    if bValida then
    begin
      bValida :=
        (Trim(oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString) <> '') and
        (Trim(oConsulta.FieldByName('NIF_EMP').AsString) <> '') and
        (Trim(oConsulta.FieldByName('DIRECCION1_EMP').AsString) <> '') and
        ((Trim(oConsulta.FieldByName('CODIGO_PAI_EMP').AsString) <> '') or
         (Trim(oConsulta.FieldByName('NOMBRE_PAI_EMP').AsString) <> ''));
    end;
    if not bValida then
    begin
      raise EArgumentException.Create(
        SErrorEmpresaDestinoFacturacionPeriodoInvalida);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.ContarTemporal: Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONTAR_TEMPORAL;
    oConsulta.Open;
    Result := oConsulta.FieldByName('TOTAL').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.CargarGrupos:
  TGruposPendientesPeriodo;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_GRUPOS;
    oConsulta.Open;
    i := 0;
    while not oConsulta.Eof do
    begin
      SetLength(Result, i + 1);
      Result[i].Tipo :=
        oConsulta.FieldByName('TIPO_FACTURACION').AsString;
      Result[i].EmpresaDestino :=
        oConsulta.FieldByName('CODIGO_EMP_DESTINO').AsString;
      Result[i].IdDocumentoAnterior :=
        oConsulta.FieldByName('ID_CFPER_ANTERIOR').AsLargeInt;
      Result[i].Operaciones :=
        oConsulta.FieldByName('OPERACIONES').AsInteger;
      Inc(i);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.InsertarCabecera(
  const AGrupo: TGrupoPendientePeriodo;
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlInsertarCabeceraFacturacionPeriodo;
    oConsulta.ParamByName('TIPO').AsString := AGrupo.Tipo;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('DESTINO').AsString := AGrupo.EmpresaDestino;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDate := Trunc(ASolicitud.FechaDesde);
    oConsulta.ParamByName('HASTA').AsDate := Trunc(ASolicitud.FechaHasta);
    oConsulta.ParamByName('FECHA_DOCUMENTO').AsDate :=
      Trunc(ASolicitud.FechaDocumento);
    if SameText(AGrupo.Tipo, 'VE') then
    begin
      oConsulta.ParamByName('ESTADO_FISCAL').AsString := 'NO_APLICA';
    end
    else
    begin
      oConsulta.ParamByName('ESTADO_FISCAL').AsString := 'DELEGADO';
    end;
    if AGrupo.IdDocumentoAnterior > 0 then
    begin
      oConsulta.ParamByName('ESAJUSTE').AsString := 'S';
    end
    else
    begin
      oConsulta.ParamByName('ESAJUSTE').AsString := 'N';
    end;
    oConsulta.ParamByName('ID_ORIGEN').AsLargeInt :=
      AGrupo.IdDocumentoAnterior;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := SQL_ULTIMO_ID;
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.InsertarOperaciones(
  AIdDocumento: Int64;
  const AGrupo: TGrupoPendientePeriodo;
  const AUsuario: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlInsertarOperacionesFacturacionPeriodo;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('TIPO').AsString := AGrupo.Tipo;
    oConsulta.ParamByName('DESTINO').AsString := AGrupo.EmpresaDestino;
    oConsulta.ParamByName('ID_ORIGEN').AsLargeInt :=
      AGrupo.IdDocumentoAnterior;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.InsertarLineas(
  AIdDocumento: Int64;
  const AGrupo: TGrupoPendientePeriodo;
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if SameText(AGrupo.Tipo, 'VE') then
    begin
      oConsulta.SQL.Text := SqlInsertarLineasVentaPeriodo;
    end
    else
    begin
      oConsulta.SQL.Text := SqlInsertarLineasTraspasoPeriodo;
      oConsulta.ParamByName('FECHA_DOCUMENTO').AsDate :=
        Trunc(ASolicitud.FechaDocumento);
    end;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    Result := Result + oConsulta.RowsAffected;
    if SameText(AGrupo.Tipo, 'VE') then
    begin
      oConsulta.SQL.Text := SqlInsertarLineasVentaRetiradasPeriodo;
    end
    else
    begin
      oConsulta.SQL.Text := SqlInsertarLineasTraspasoRetiradasPeriodo;
    end;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    Result := Result + oConsulta.RowsAffected;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.ActualizarTotales(
  AIdDocumento: Int64;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ACTUALIZAR_IMPORTES_OPERACION;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := SqlActualizarTotalesFacturacionPeriodo;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.ObtenerNumeroFiscal(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): string;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('pserie').AsString :=
      ASolicitud.SerieFiscal;
    oProcedimiento.ParamByName('pTipoDoc').AsString := 'FC';
    oProcedimiento.ParamByName('pEMPRESA_CONTADOR').AsString :=
      ASolicitud.Empresa;
    oProcedimiento.ParamByName('pUSUARIOMODIF').AsString :=
      ASolicitud.Usuario;
    oProcedimiento.Execute;
    Result := oProcedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.AsignarDocumento(
  AIdDocumento: Int64;
  const ASerie, ANumero, AEstadoFiscal, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_ASIGNAR_DOCUMENTO;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('ESTADO_FISCAL').AsString := AEstadoFiscal;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.CrearFacturaFiscal(
  AIdDocumento: Int64;
  const AGrupo: TGrupoPendientePeriodo;
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo);
var
  sNumero: string;
  oConsulta: TUniQuery;
  oSolicitudEmision: TSolicitudEmisionFiscal;
begin
  ValidarEmpresaDestino(AGrupo.EmpresaDestino);
  sNumero := ObtenerNumeroFiscal(ASolicitud);
  AsignarDocumento(
    AIdDocumento,
    ASolicitud.SerieFiscal,
    sNumero,
    'DELEGADO',
    ASolicitud.Usuario);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlInsertarFacturaTraspasoPeriodo;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieFiscal;
    oConsulta.ParamByName('NUMERO').AsString := sNumero;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
    begin
      raise Exception.Create(SErrorEmpresaDestinoFacturacionPeriodoInvalida);
    end;
    oConsulta.SQL.Text := SqlInsertarLineasFacturaTraspasoPeriodo;
    oConsulta.ParamByName('ID_DOCUMENTO').AsLargeInt := AIdDocumento;
    oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieFiscal;
    oConsulta.ParamByName('NUMERO').AsString := sNumero;
    oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
    oConsulta.Execute;
    if oConsulta.RowsAffected = 0 then
    begin
      raise Exception.Create(SErrorSinLineasFacturacionPeriodo);
    end;
    if AGrupo.IdDocumentoAnterior > 0 then
    begin
      oConsulta.SQL.Text := SQL_RELACIONAR_RECTIFICATIVA;
      oConsulta.ParamByName('ID_ORIGEN').AsLargeInt :=
        AGrupo.IdDocumentoAnterior;
      oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieFiscal;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
      oConsulta.Execute;
      oConsulta.SQL.Text := SQL_MARCAR_FACTURA_RECTIFICADA;
      oConsulta.ParamByName('ID_ORIGEN').AsLargeInt :=
        AGrupo.IdDocumentoAnterior;
      oConsulta.ParamByName('SERIE').AsString := ASolicitud.SerieFiscal;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('USUARIO').AsString := ASolicitud.Usuario;
      oConsulta.Execute;
    end;
    ValidarRequisitosFiscalesEmision(
      FParametrosApp,
      FConexion,
      ASolicitud.SerieFiscal,
      sNumero);
    oSolicitudEmision := TSolicitudEmisionFiscal.ParaAlta(
      ASolicitud.SerieFiscal,
      sNumero,
      ASolicitud.Usuario,
      'Factura TA por periodo encolada');
    FServicioEmision.Emitir(oSolicitudEmision);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioFacturacionOperacionesPeriodoUniDAC.ProcesarGrupo(
  const AGrupo: TGrupoPendientePeriodo;
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo;
  var AResultado: TResultadoFacturacionOperacionesPeriodo);
var
  iLineas: Integer;
  iOperaciones: Integer;
  nIdDocumento: Int64;
  sNumeroInterno: string;
  sSerieInterna: string;
begin
  nIdDocumento := InsertarCabecera(AGrupo, ASolicitud);
  iOperaciones := InsertarOperaciones(
    nIdDocumento,
    AGrupo,
    ASolicitud.Usuario);
  iLineas := InsertarLineas(nIdDocumento, AGrupo, ASolicitud);
  if (iOperaciones = 0) or (iLineas = 0) then
  begin
    raise Exception.Create(SErrorSinLineasFacturacionPeriodo);
  end;
  ActualizarTotales(nIdDocumento, ASolicitud.Usuario);
  if SameText(AGrupo.Tipo, 'VE') then
  begin
    sSerieInterna := 'PI' + FormatDateTime(
      'yyyy',
      ASolicitud.FechaDocumento);
    sNumeroInterno := Format('%.10d', [nIdDocumento]);
    AsignarDocumento(
      nIdDocumento,
      sSerieInterna,
      sNumeroInterno,
      'NO_APLICA',
      ASolicitud.Usuario);
    Inc(AResultado.DocumentosInternos);
  end
  else
  begin
    CrearFacturaFiscal(nIdDocumento, AGrupo, ASolicitud);
    Inc(AResultado.FacturasFiscales);
  end;
  if AGrupo.IdDocumentoAnterior > 0 then
  begin
    Inc(AResultado.Ajustes);
  end;
  Inc(AResultado.OperacionesProcesadas, iOperaciones);
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.
  ObtenerSerieFiscalDefecto(
  const AEmpresa: string;
  AFecha: TDateTime): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_SERIE_DEFECTO;
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('FECHA').AsDate := Trunc(AFecha);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('SERIE_SERIE').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.
  ContarOperacionesPendientes(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Integer;
begin
  ValidarSolicitud(ASolicitud);
  ValidarSerieFiscal(ASolicitud);
  PrepararTemporal(ASolicitud);
  Result := ContarTemporal;
end;

function TServicioFacturacionOperacionesPeriodoUniDAC.Procesar(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo
): TResultadoFacturacionOperacionesPeriodo;
var
  i: Integer;
  aGrupos: TGruposPendientesPeriodo;
begin
  Result := Default(TResultadoFacturacionOperacionesPeriodo);
  ValidarSolicitud(ASolicitud);
  ValidarSerieFiscal(ASolicitud);
  FConexion.StartTransaction;
  try
    try
      PrepararTemporal(ASolicitud);
      aGrupos := CargarGrupos;
      for i := Low(aGrupos) to High(aGrupos) do
      begin
        ProcesarGrupo(aGrupos[i], ASolicitud, Result);
      end;
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    aGrupos := nil;
  end;
end;

function CrearServicioFacturacionOperacionesPeriodoUniDAC(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AServicioEmision: IServicioEmisionFiscal
): IServicioFacturacionOperacionesPeriodo;
begin
  Result := TServicioFacturacionOperacionesPeriodoUniDAC.Create(
    AConexion,
    AParametrosApp,
    AServicioEmision);
end;

function CrearRepositorioInformeFacturacionOperacionesPeriodoUniDAC(
  AConexion: TUniConnection
): IRepositorioInformeFacturacionOperacionesPeriodo;
begin
  Result := TRepositorioInformeFacturacionPeriodoUniDAC.Create(AConexion);
end;

end.
