unit UniDataDocumentosTrabajoRepositorio;

interface

uses
  Uni,
  inLibDocumentosTrabajo;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;

implementation

uses
  System.SysUtils, Data.DB, DBAccess, UniDataPedidosCompraPendientes,
  inLibMsgVentas;

const
  SQL_DESTINOS_COMPARTIR =
    'SELECT ''USUARIO'' AS TIPO, USUARIO_USU AS DESTINO ' +
    'FROM fza_usuarios WHERE COALESCE(ESACTIVO_USU, ''S'') = ''S'' ' +
    'UNION ALL SELECT ''GRUPO'' AS TIPO, GRUPO_USUGRP AS DESTINO ' +
    'FROM fza_usuarios_grupos ORDER BY TIPO, DESTINO';
  SQL_NOMBRES_ATRIBUTOS =
    'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE, ' +
    'MIN(ORDEN_VA) AS ORDEN FROM fza_variaciones_atributos ' +
    'GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA) ' +
    'ORDER BY ORDEN, NOMBRE LIMIT 5';
  SQL_CREAR_ALBARAN =
    'INSERT INTO fza_albaranes (NUMERO_ALB, SERIE_ALB, FECHA_ALB, ' +
    'ESTADO_ALB, CODIGO_EMP_ALB, CODIGO_ALM_ALB, CONTADOR_LINEAS_ALB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, CURDATE(), ''ABIERTO'', :EMP, :ALM, ' +
    'LPAD(COUNT(*) * 10, 8, ''0''), NOW(), NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_LINEAS_ALBARAN =
    'INSERT INTO fza_albaranes_lineas (NUMERO_ALB_ALBLIN, ' +
    'SERIE_ALB_ALBLIN, LINEA_ALBLIN, CODIGO_ART_ALBLIN, ' +
    'DESCRIPCION_ARTICULO_ALBLIN, CANTIDAD_ALBLIN, ' +
    'CODIGO_ALMACEN_ALBLIN, CODIGO_UNIDAD_ALBLIN, LOTE_ALBLIN, ' +
    'FECHA_CADUCIDAD_ALBLIN, DESCRIPCION_VARIACION_ALBLIN, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, ' +
    '4, ''0''), CODIGO_ART_DTL, LEFT(DESCRIPCION_ARTICULO_DTL, 100), ' +
    'CANTIDAD_DTL, :ALM, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'FECHA_CADUCIDAD_DTL, DESCRIPCION_UNIDAD_DTL, NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_FACTURA_VENTA =
    'INSERT INTO fza_facturas (NUMERO_FAC, SERIE_FAC, FECHA_FAC, ' +
    'ESCONSOLIDADA_FAC, TIPO_FAC, ESMUEVE_STOCK_FAC, FASE_FAC, ' +
    'CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
    'MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
    'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
    'PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
    'ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, CODIGO_CLI_FAC, ' +
    'TEXTO_LEGAL_EMPRESA_FAC, CONTADOR_LINEAS_FAC, CODIGO_ALM_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, CURDATE(), ''N'', ''NORMAL'', ''S'', ' +
    '''BORRADOR'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, E.ESRETENCIONES_EMP, ' +
    'E.GRUPO_ZONA_IVA_EMP, E.ESREGIMENESPECIALAGRICOLA_EMP, ''0'', ' +
    'E.TEXTO_LEGAL_FACTURA_EMP, LPAD((SELECT COUNT(*) * 10 FROM ' +
    'fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID), 8, ' +
    '''0''), :ALM, NOW(), NOW(), :USU, :USU FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_FACTURA_VENTA =
    'INSERT INTO fza_facturas_lineas (NUMERO_FAC_FACLIN, ' +
    'SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, LOTE_FACLIN, ' +
    'FECHA_CADUCIDAD_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    'CANTIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'DESCRIPCION_VARIACION_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    'TOTAL_FAC_SIVA_FACLIN, CODIGO_ALM_FACLIN, ' +
    'ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
    'ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
    'ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
    'ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
    'ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
    'NUM_ATRIBUTOS_FACLIN, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) SELECT :NUMERO, :SERIE, :EMP, ' +
    'LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'FECHA_CADUCIDAD_DTL, ''Uds'', CANTIDAD_DTL, ' +
    'LEFT(DESCRIPCION_ARTICULO_DTL, 100), DESCRIPCION_UNIDAD_DTL, ' +
    '''N'', 0, 0, 0, 0, 0, :ALM, ATTR1_VALOR_DTL, ' +
    'ATTR1_NOMBRE_DTL, ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ' +
    'ATTR3_VALOR_DTL, ATTR3_NOMBRE_DTL, ATTR4_VALOR_DTL, ' +
    'ATTR4_NOMBRE_DTL, ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, ' +
    'NUM_ATRIBUTOS_DTL, NOW(), NOW(), :USU, :USU FROM ' +
    'fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_PEDIDO_COMPRA =
    'INSERT INTO fza_pedidos_compra (NUMERO_PEDC, SERIE_PEDC, ' +
    'FECHA_PEDC, ESTADO_PEDC, CODIGO_EMP_PEDC, ' +
    'RAZON_SOCIAL_EMPRESA_PEDC, NIF_EMPRESA_PEDC, MOVIL_EMPRESA_PEDC, ' +
    'EMAIL_EMPRESA_PEDC, DIRECCION1_EMPRESA_PEDC, ' +
    'DIRECCION2_EMPRESA_PEDC, POBLACION_EMPRESA_PEDC, ' +
    'PROVINCIA_EMPRESA_PEDC, CODIGO_PAI_EMPRESA_PEDC, ' +
    'NOMBRE_PAI_EMPRESA_PEDC, CODIGO_POSTAL_EMPRESA_PEDC, ' +
    'CODIGO_PRV_PEDC, CODIGO_ALM_PEDC, ESIVA_RECARGO_COMPRAS_PEDC, ' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, CONTADOR_LINEAS_PEDC, ' +
    'COMENTARIOS_PEDC, ESPIVOTE_HORIZONTAL_PEDC, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) SELECT :NUMERO, ' +
    ':SERIE, CURDATE(), ''ABIERTO'', E.CODIGO_EMP_EMP, ' +
    'E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.MOVIL_EMP, E.EMAIL_EMP, ' +
    'E.DIRECCION1_EMP, E.DIRECCION2_EMP, E.POBLACION_EMP, ' +
    'E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
    'E.CODIGO_POSTAL_EMP, ''0'', :ALM, ' +
    'COALESCE(E.ESIVA_RECARGO_COMPRAS_EMP, ''N''), ''N'', ' +
    'LPAD((SELECT COUNT(*) * 10 FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID), 8, ''0''), ' +
    'CONCAT(''Desde doc. trabajo '', :ID), ''N'', NOW(), NOW(), ' +
    ':USU, :USU FROM fza_empresas E WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_PEDIDO_COMPRA =
    'INSERT INTO fza_pedidos_compra_lineas (' +
    'NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, ' +
    'CODIGO_ART_PEDCLIN, CODIGO_UNIDAD_PEDCLIN, ID_AC_PIVOT_PEDCLIN, ' +
    'DESCRIPCION_ARTICULO_PEDCLIN, TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
    'CANTIDAD_PEDCLIN, CANTIDAD_RECIBIDA_PEDCLIN, ' +
    'TOTAL_UNIDADES_PEDCLIN, TIPO_IVA_ARTICULO_PEDCLIN, ' +
    'PORCENTAJE_IVA_PEDCLIN, PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, TOTAL_PEDCLIN, ' +
    'CODIGO_ALMACEN_PEDCLIN, DESCRIPCION_VARIACION_PEDCLIN, ' +
    'ATTR1_VALOR_PEDCLIN, ATTR1_NOMBRE_PEDCLIN, ' +
    'ATTR2_VALOR_PEDCLIN, ATTR2_NOMBRE_PEDCLIN, ' +
    'ATTR3_VALOR_PEDCLIN, ATTR3_NOMBRE_PEDCLIN, ' +
    'ATTR4_VALOR_PEDCLIN, ATTR4_NOMBRE_PEDCLIN, ' +
    'ATTR5_VALOR_PEDCLIN, ATTR5_NOMBRE_PEDCLIN, ' +
    'NUM_ATRIBUTOS_PEDCLIN, CANTIDAD_A_RECIBIR_PEDCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, ' +
    'LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ID_AC_PIVOT_DTL, ' +
    'LEFT(DESCRIPCION_ARTICULO_DTL, 100), ''Uds'', CANTIDAD_DTL, 0, ' +
    'CANTIDAD_DTL, ''N'', 0, 0, 0, 0, :ALM, ' +
    'DESCRIPCION_UNIDAD_DTL, ATTR1_VALOR_DTL, ATTR1_NOMBRE_DTL, ' +
    'ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ATTR3_VALOR_DTL, ' +
    'ATTR3_NOMBRE_DTL, ATTR4_VALOR_DTL, ATTR4_NOMBRE_DTL, ' +
    'ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, NUM_ATRIBUTOS_DTL, 0, ' +
    'NOW(), NOW(), :USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_INVENTARIO =
    'INSERT INTO fza_inventarios (CODIGO_EMP_INV, CODIGO_ALM_INV, ' +
    'SERIE_INV, NUMERO_INV, TIPO_DOC_INV, FECHA_INV, ESTADO_INV, ' +
    'DESCRIPCION_INV, CONTADOR_LINEAS_INV, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :EMP, :ALM, :SERIE, :NUMERO, ''IN'', NOW(), ''ABIERTO'', ' +
    'CONCAT(''Desde doc. trabajo '', :ID), LPAD(COUNT(*), 8, ''0''), ' +
    'NOW(), NOW(), :USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_LINEAS_INVENTARIO =
    'INSERT INTO fza_inventarios_lineas (CODIGO_EMP_INVLIN, ' +
    'CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, NUMERO_INV_INVLIN, ' +
    'LINEA_INVLIN, CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN, ' +
    'LOTE_INVLIN, DESCRIPCION_ARTICULO_INVLIN, ' +
    'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
    'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
    'PRECIO_MEDIO_NUEVO_INVLIN, TOTAL_COSTE_DIFERENCIA_INVLIN, ' +
    'FECHA_RECUENTO_INVLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) SELECT :EMP, :ALM, :SERIE, :NUMERO, LINEA_DTL, ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'DESCRIPCION_ARTICULO_DTL, CANTIDAD_STOCK_DTL, CANTIDAD_DTL, ' +
    'CANTIDAD_DTL - CANTIDAD_STOCK_DTL, 0, 0, 0, NOW(), NOW(), ' +
    ':USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios (NOMBRE_TARC, FECHA_TARC, ' +
    'ESTADO_TARC, CODIGO_TAR_ORIGEN_TARC, CODIGO_TAR_DESTINO_TARC, ' +
    'INSTANTE_ALTA, USUARIO_ALTA) SELECT CONCAT(''Desde doc. trabajo '', ' +
    ':ID), CURDATE(), ''BORRADOR'', T.COD, T.COD, NOW(), :USU ' +
    'FROM (SELECT MIN(CODIGO_TAR_TAR) AS COD FROM fza_tarifas) T';
  SQL_CREAR_LINEAS_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, ESTADO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT DISTINCT :TARC, L.CODIGO_ART_DTL, '''', ' +
    'C.CODIGO_TAR_ORIGEN_TARC, C.CODIGO_TAR_DESTINO_TARC, ''S'', ' +
    '''PENDIENTE'', NOW(), :USU FROM fza_documentos_trabajo_lineas L ' +
    'JOIN fza_tarifas_cambios C ON C.CODIGO_TARC = :TARC ' +
    'WHERE L.ID_DTR_DTL = :ID';

type
  TConsultaDocumentoTrabajoUniDAC = class(
    TInterfacedObject,
    IConsultaDocumentoTrabajo)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioDocumentosTrabajo = class(
    TInterfacedObject,
    ILecturasDocumentosTrabajo,
    IEscrituraDocumentosTrabajo,
    IMaterializacionDocumentosTrabajo)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function SiguienteLinea(AIdDocumento: Int64): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
    function ConsultarDestinosCompartir: IConsultaDocumentoTrabajo;
    function ListarNombresAtributos:
      TNombresAtributosDocumentoTrabajo;
    function CrearDocumento(const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
    function SiguienteContador(
      const ASerie, ATipoDocumento, AEmpresa,
      AUsuario: string): string;
    function CrearAlbaran(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearFacturaVenta(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearPedidoCompra(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearInventario(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearSesionTarifa(
      AIdDocumento: Int64;
      const AUsuario: string): Int64;
  end;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
var
  Repositorio: TRepositorioDocumentosTrabajo;
begin
  Repositorio := TRepositorioDocumentosTrabajo.Create(AConexion);
  Result.Lecturas := Repositorio;
  Result.Escritura := Repositorio;
  Result.Materializacion := Repositorio;
end;

constructor TConsultaDocumentoTrabajoUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaDocumentoTrabajoUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaDocumentoTrabajoUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioDocumentosTrabajo.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioDocumentosTrabajo.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioDocumentosTrabajo.ConsultaDocumentosAbiertos(
  const AUsuario: string): string;
begin
  Result :=
    'SELECT ID_DTR, TITULO_DTR, USUARIO_DTR, ' +
    '       INSTANTE_DOCUMENTO_DTR, ESTADO_DTR ' +
    '  FROM fza_documentos_trabajo ' +
    ' WHERE ESTADO_DTR = ''ABIERTO'' ' +
    '   AND USUARIO_DTR = ' + QuotedStr(AUsuario) + ' ' +
    ' ORDER BY INSTANTE_DOCUMENTO_DTR DESC, ID_DTR DESC';
end;

function TRepositorioDocumentosTrabajo.ConsultarDestinosCompartir:
  IConsultaDocumentoTrabajo;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_DESTINOS_COMPARTIR;
    Consulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioDocumentosTrabajo.ListarNombresAtributos:
  TNombresAtributosDocumentoTrabajo;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_NOMBRES_ATRIBUTOS;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion] := Consulta.FieldByName('NOMBRE').AsString;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearDocumento(
  const ATitulo, AEmpresa, AAlmacen, AUsuario: string): Int64;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo ' +
      '  (TITULO_DTR, TIPO_DTR, ESTADO_DTR, CODIGO_EMP_DTR, ' +
      '   CODIGO_ALM_DTR, USUARIO_DTR, INSTANTE_DOCUMENTO_DTR, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:TITULO, ''GENERAL'', ''ABIERTO'', :EMPRESA, :ALMACEN, ' +
      '   :USUARIO, NOW(), NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    Consulta.ParamByName('TITULO').AsString := ATitulo;
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_ALTA').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_MODIF').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioDocumentosTrabajo.CompletarDatosArticulo(
  var ALinea: TDocTrabajoLineaOrigen);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT a.DESCRIPCION_ART, ' +
      '       (SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV ' +
      '               SEPARATOR '' / '') ' +
      '          FROM fza_atributos_sku sa ' +
      '          JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
      '         WHERE sa.CODIGO_UNIDAD_SKU_SA = :SKU) AS DESCRIPCION_SKU ' +
      '  FROM fza_articulos a ' +
      ' WHERE a.CODIGO_ART_ART = :ART';
    Consulta.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Consulta.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      if Trim(ALinea.DescripcionArticulo) = '' then
        ALinea.DescripcionArticulo :=
          Consulta.FieldByName('DESCRIPCION_ART').AsString;
      if Trim(ALinea.DescripcionSku) = '' then
        ALinea.DescripcionSku :=
          Consulta.FieldByName('DESCRIPCION_SKU').AsString;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.SiguienteLinea(
  AIdDocumento: Int64): string;
var
  Consulta: TUniQuery;
  Linea: Integer;
begin
  Linea := 1;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID_DTR';
    Consulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Linea := Consulta.FieldByName('LINEA').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
  Result := Format('%.8d', [Linea]);
end;

procedure TRepositorioDocumentosTrabajo.InsertarLinea(
  AIdDocumento: Int64;
  const ALinea: TDocTrabajoLineaOrigen;
  const AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo_lineas ' +
      '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
      '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
      '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
      '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
      '   ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD, ' +
      '   :DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(), ' +
      '   :ORIGEN, NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    Consulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('LINEA').AsString := SiguienteLinea(AIdDocumento);
    Consulta.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Consulta.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Consulta.ParamByName('ALM').AsString := ALinea.CodigoAlmacen;
    Consulta.ParamByName('LOTE').AsString := ALinea.Lote;
    if ALinea.FechaCaducidad = 0 then
      Consulta.ParamByName('CADUCIDAD').Clear
    else
      Consulta.ParamByName('CADUCIDAD').AsDate := ALinea.FechaCaducidad;
    Consulta.ParamByName('DESC_ART').AsString :=
      ALinea.DescripcionArticulo;
    Consulta.ParamByName('DESC_SKU').AsString := ALinea.DescripcionSku;
    Consulta.ParamByName('CANTIDAD_STOCK').AsFloat :=
      ALinea.CantidadStock;
    Consulta.ParamByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    Consulta.ParamByName('ORIGEN').AsString := ALinea.Origen;
    Consulta.ParamByName('USUARIO_ALTA').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_MODIF').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.SiguienteContador(
  const ASerie, ATipoDocumento, AEmpresa,
  AUsuario: string): string;
var
  Procedimiento: TUniStoredProc;
begin
  Result := '';
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'pserie', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'pEMPRESA_CONTADOR',
      ptInput);
    Procedimiento.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'pcont', ptOutput);
    Procedimiento.ParamByName('pserie').AsString := ASerie;
    Procedimiento.ParamByName('ptipodoc').AsString := ATipoDocumento;
    Procedimiento.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    Procedimiento.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearAlbaran(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_CREAR_ALBARAN;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ALM').AsString := AAlmacen;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := SQL_CREAR_LINEAS_ALBARAN;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('ALM').AsString := AAlmacen;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
    Result := Consulta.RowsAffected;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearFacturaVenta(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_FACTURA_VENTA;
      Consulta.ParamByName('NUMERO').AsString := ANumero;
      Consulta.ParamByName('SERIE').AsString := ASerie;
      Consulta.ParamByName('EMP').AsString := AEmpresa;
      Consulta.ParamByName('ALM').AsString := AAlmacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [AEmpresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_FACTURA_VENTA;
      Consulta.ParamByName('NUMERO').AsString := ANumero;
      Consulta.ParamByName('SERIE').AsString := ASerie;
      Consulta.ParamByName('EMP').AsString := AEmpresa;
      Consulta.ParamByName('ALM').AsString := AAlmacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearPedidoCompra(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_PEDIDO_COMPRA;
      Consulta.ParamByName('NUMERO').AsString := ANumero;
      Consulta.ParamByName('SERIE').AsString := ASerie;
      Consulta.ParamByName('EMP').AsString := AEmpresa;
      Consulta.ParamByName('ALM').AsString := AAlmacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [AEmpresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_PEDIDO_COMPRA;
      Consulta.ParamByName('NUMERO').AsString := ANumero;
      Consulta.ParamByName('SERIE').AsString := ASerie;
      Consulta.ParamByName('ALM').AsString := AAlmacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      GenerarPdteRecibirDesdePedidoInterno(
        FConexion,
        ASerie,
        ANumero,
        AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearInventario(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_CREAR_INVENTARIO;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ALM').AsString := AAlmacen;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := SQL_CREAR_LINEAS_INVENTARIO;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ALM').AsString := AAlmacen;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
    Result := Consulta.RowsAffected;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearSesionTarifa(
  AIdDocumento: Int64;
  const AUsuario: string): Int64;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_CREAR_SESION_TARIFA;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Consulta.Open;
    Result := Consulta.FieldByName('ID').AsLargeInt;
    Consulta.Close;
    Consulta.SQL.Text := SQL_CREAR_LINEAS_SESION_TARIFA;
    Consulta.ParamByName('TARC').AsLargeInt := Result;
    Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('USU').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

end.
