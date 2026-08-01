unit UniDataDocumentosTrabajoRepositorio;

interface

uses
  Uni,
  inLibDocumentosTrabajo;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;

implementation

uses
  System.SysUtils, Data.DB, DBAccess;

type
  TRepositorioDocumentosTrabajo = class(
    TInterfacedObject,
    ILecturasDocumentosTrabajo,
    IEscrituraDocumentosTrabajo)
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
    function CrearDocumento(const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
  end;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection): TRepositoriosDocumentosTrabajo;
var
  Repositorio: TRepositorioDocumentosTrabajo;
begin
  Repositorio := TRepositorioDocumentosTrabajo.Create(AConexion);
  Result.Lecturas := Repositorio;
  Result.Escritura := Repositorio;
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

end.
