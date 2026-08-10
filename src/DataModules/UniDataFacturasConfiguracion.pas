{******************************************************************************}
{                                                                              }
{  Configuracion de persistencia de las consultas de facturas.                 }
{                                                                              }
{******************************************************************************}
unit UniDataFacturasConfiguracion;

interface

uses
  Uni;

procedure ConfigurarPersistenciaCabeceraFactura(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
procedure ConfigurarPersistenciaLineasFactura(
  AConexion: TUniConnection;
  ALineas: TUniQuery);

implementation

uses
  System.Classes,
  System.SysUtils,
  inLibSqlSeguro;

const
  CAMPOS_COMPLEJOS_CABECERA: array[0..1] of string = (
    'DOCUMENTO_FAC',
    'XML_FAC'
  );

procedure QuitarCampoComplejoCabecera(
  ALista: TStrings;
  const ACampo: string);
var
  sCampoSql: string;
  sSQL: string;
begin
  if ALista <> nil then
  begin
    sCampoSql := DelimitarIdentificadorSql(
      ACampo,
      CAMPOS_COMPLEJOS_CABECERA);
    sSQL := ALista.Text;
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql + ' = :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    ALista.Text := sSQL;
  end;
end;

procedure PrepararCabeceraSinCamposComplejos(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
var
  ColumnasPermitidas: TStringList;
  i: Integer;
  qCampos: TUniQuery;
  sCampo: string;
  sCampos: string;
begin
  sCampos := '';
  if AConexion <> nil then
  begin
    ColumnasPermitidas := TStringList.Create;
    qCampos := TUniQuery.Create(nil);
    try
      qCampos.Connection := AConexion;
      qCampos.SQL.Text := 'SHOW COLUMNS FROM vi_facturas';
      qCampos.Open;
      while not qCampos.Eof do
      begin
        sCampo := qCampos.FieldByName('Field').AsString;
        ColumnasPermitidas.Add(sCampo);
        qCampos.Next;
      end;
      i := 0;
      while i < ColumnasPermitidas.Count do
      begin
        sCampo := ColumnasPermitidas[i];
        if (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[0])) and
           (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[1])) then
        begin
          if sCampos <> '' then
            sCampos := sCampos + ', ';
          sCampos := sCampos + DelimitarIdentificadorSql(
            sCampo,
            ColumnasPermitidas);
        end;
        Inc(i);
      end;
    finally
      FreeAndNil(qCampos);
      FreeAndNil(ColumnasPermitidas);
    end;
    if sCampos <> '' then
      ACabecera.SQL.Text :=
        'SELECT ' + sCampos + ' FROM vi_facturas ' +
        ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC';
  end;
  QuitarCampoComplejoCabecera(ACabecera.SQLInsert, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLInsert, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLUpdate, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLUpdate, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLLock, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLLock, 'XML_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLRefresh, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(ACabecera.SQLRefresh, 'XML_FAC');
end;

function ColumnasSkuLineasAplicadas(AConexion: TUniConnection): Boolean;
var
  qCol: TUniQuery;
begin
  Result := False;
  if AConexion <> nil then
  begin
    qCol := TUniQuery.Create(nil);
    try
      try
        qCol.Connection := AConexion;
        qCol.SQL.Text :=
          'SELECT COUNT(*) AS N ' +
          '  FROM INFORMATION_SCHEMA.COLUMNS ' +
          ' WHERE TABLE_SCHEMA = DATABASE() ' +
          '   AND TABLE_NAME = ''fza_facturas_lineas'' ' +
          '   AND COLUMN_NAME IN (''ATTR1_VALOR_FACLIN'', ' +
          '                       ''NUM_ATRIBUTOS_FACLIN'')';
        qCol.Open;
        Result := qCol.FieldByName('N').AsInteger = 2;
      except
        // Sin migracion se conservan los SQL del DFM.
        Result := False;
      end;
    finally
      FreeAndNil(qCol);
    end;
  end;
end;

procedure ConfigurarPersistenciaCabeceraFactura(
  AConexion: TUniConnection;
  ACabecera: TUniQuery);
begin
  ACabecera.Connection := AConexion;
  ACabecera.KeyFields := 'NUMERO_FAC;SERIE_FAC';
  ACabecera.SQLDelete.Text :=
    'DELETE FROM fza_facturas ' + sLineBreak +
    'WHERE NUMERO_FAC = :Old_NUMERO_FAC ' + sLineBreak +
    '  AND SERIE_FAC = :Old_SERIE_FAC';
  PrepararCabeceraSinCamposComplejos(AConexion, ACabecera);
end;

procedure ConfigurarInsercionLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLInsert.Text :=
      'INSERT INTO fza_facturas_lineas ' +
      ' (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
      '  CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, CODIGO_FAM_FACLIN, ' +
      '  NOMBRE_FAM_FACLIN, PRECIO_ULT_COMPRA_FACLIN, CODIGO_PRV_FACLIN, ' +
      '  RAZON_SOCIAL_PROVEEDOR_FACLIN, ESPROVEEDORPRINCIPAL_FACLIN, ' +
      '  FECHA_ENTREGA_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '  ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
      '  CODIGO_TAR_FACLIN, CANTIDAD_FACLIN, PRECIO_SALIDA_FACLIN, ' +
      '  PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
      '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
      '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
      '  TOTAL_FAC_SIVA_FACLIN, ' +
      '  ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
      '  ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
      '  ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
      '  ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
      '  ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
      '  NUM_ATRIBUTOS_FACLIN, ' +
      '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      ' (:NUMERO_FAC_FACLIN, :SERIE_FAC_FACLIN, :LINEA_FACLIN, ' +
      '  :CODIGO_ART_FACLIN, :CODIGO_UNIDAD_FACLIN, :CODIGO_FAM_FACLIN, ' +
      '  :NOMBRE_FAM_FACLIN, :PRECIO_ULT_COMPRA_FACLIN, ' +
      '  :CODIGO_PRV_FACLIN, :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
      '  :ESPROVEEDORPRINCIPAL_FACLIN, :FECHA_ENTREGA_FACLIN, ' +
      '  :TIPO_CANTIDAD_ARTICULO_FACLIN, :ESIMP_INCL_TARIFA_FACLIN, ' +
      '  :TIPO_IVA_ARTICULO_FACLIN, :DESCRIPCION_ARTICULO_FACLIN, ' +
      '  :DESCRIPCION_VARIACION_FACLIN, :CODIGO_TAR_FACLIN, ' +
      '  :CANTIDAD_FACLIN, :PRECIO_SALIDA_FACLIN, :PORCENTAJE_DTO_FACLIN, ' +
      '  :PRECIO_DTO_FACLIN, :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '  :PORCENTAJE_IVA_FACLIN, :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '  :TOTAL_FACLIN, :TOTAL_FAC_SIVA_FACLIN, ' +
      '  :ATTR1_VALOR_FACLIN, :ATTR1_NOMBRE_FACLIN, ' +
      '  :ATTR2_VALOR_FACLIN, :ATTR2_NOMBRE_FACLIN, ' +
      '  :ATTR3_VALOR_FACLIN, :ATTR3_NOMBRE_FACLIN, ' +
      '  :ATTR4_VALOR_FACLIN, :ATTR4_NOMBRE_FACLIN, ' +
      '  :ATTR5_VALOR_FACLIN, :ATTR5_NOMBRE_FACLIN, ' +
      '  :NUM_ATRIBUTOS_FACLIN, ' +
      '  :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)';
end;

procedure ConfigurarActualizacionLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLUpdate.Text :=
      'UPDATE fza_facturas_lineas SET ' +
      '  NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN, ' +
      '  SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN, ' +
      '  LINEA_FACLIN = :LINEA_FACLIN, ' +
      '  CODIGO_ART_FACLIN = :CODIGO_ART_FACLIN, ' +
      '  CODIGO_UNIDAD_FACLIN = :CODIGO_UNIDAD_FACLIN, ' +
      '  CODIGO_FAM_FACLIN = :CODIGO_FAM_FACLIN, ' +
      '  NOMBRE_FAM_FACLIN = :NOMBRE_FAM_FACLIN, ' +
      '  PRECIO_ULT_COMPRA_FACLIN = :PRECIO_ULT_COMPRA_FACLIN, ' +
      '  CODIGO_PRV_FACLIN = :CODIGO_PRV_FACLIN, ' +
      '  RAZON_SOCIAL_PROVEEDOR_FACLIN = :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
      '  ESPROVEEDORPRINCIPAL_FACLIN = :ESPROVEEDORPRINCIPAL_FACLIN, ' +
      '  FECHA_ENTREGA_FACLIN = :FECHA_ENTREGA_FACLIN, ' +
      '  TIPO_CANTIDAD_ARTICULO_FACLIN = :TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '  ESIMP_INCL_TARIFA_FACLIN = :ESIMP_INCL_TARIFA_FACLIN, ' +
      '  TIPO_IVA_ARTICULO_FACLIN = :TIPO_IVA_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_ARTICULO_FACLIN = :DESCRIPCION_ARTICULO_FACLIN, ' +
      '  DESCRIPCION_VARIACION_FACLIN = :DESCRIPCION_VARIACION_FACLIN, ' +
      '  CODIGO_TAR_FACLIN = :CODIGO_TAR_FACLIN, ' +
      '  CANTIDAD_FACLIN = :CANTIDAD_FACLIN, ' +
      '  PRECIO_SALIDA_FACLIN = :PRECIO_SALIDA_FACLIN, ' +
      '  PORCENTAJE_DTO_FACLIN = :PORCENTAJE_DTO_FACLIN, ' +
      '  PRECIO_DTO_FACLIN = :PRECIO_DTO_FACLIN, ' +
      '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN = ' +
      '    :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '  PORCENTAJE_IVA_FACLIN = :PORCENTAJE_IVA_FACLIN, ' +
      '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN = ' +
      '    :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '  TOTAL_FACLIN = :TOTAL_FACLIN, ' +
      '  TOTAL_FAC_SIVA_FACLIN = :TOTAL_FAC_SIVA_FACLIN, ' +
      '  ATTR1_VALOR_FACLIN = :ATTR1_VALOR_FACLIN, ' +
      '  ATTR1_NOMBRE_FACLIN = :ATTR1_NOMBRE_FACLIN, ' +
      '  ATTR2_VALOR_FACLIN = :ATTR2_VALOR_FACLIN, ' +
      '  ATTR2_NOMBRE_FACLIN = :ATTR2_NOMBRE_FACLIN, ' +
      '  ATTR3_VALOR_FACLIN = :ATTR3_VALOR_FACLIN, ' +
      '  ATTR3_NOMBRE_FACLIN = :ATTR3_NOMBRE_FACLIN, ' +
      '  ATTR4_VALOR_FACLIN = :ATTR4_VALOR_FACLIN, ' +
      '  ATTR4_NOMBRE_FACLIN = :ATTR4_NOMBRE_FACLIN, ' +
      '  ATTR5_VALOR_FACLIN = :ATTR5_VALOR_FACLIN, ' +
      '  ATTR5_NOMBRE_FACLIN = :ATTR5_NOMBRE_FACLIN, ' +
      '  NUM_ATRIBUTOS_FACLIN = :NUM_ATRIBUTOS_FACLIN, ' +
      '  INSTANTE_MODIF = :INSTANTE_MODIF, ' +
      '  INSTANTE_ALTA = :INSTANTE_ALTA, ' +
      '  USUARIO_ALTA = :USUARIO_ALTA, ' +
      '  USUARIO_MODIF = :USUARIO_MODIF ' +
      'WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
      '  AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
      '  AND LINEA_FACLIN = :Old_LINEA_FACLIN';
end;

procedure ConfigurarLecturaBloqueoLineasFactura(ALineas: TUniQuery);
begin
  ALineas.SQLRefresh.Text :=
      'SELECT * FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN ' +
      '   AND SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN ' +
      '   AND LINEA_FACLIN = :LINEA_FACLIN';
    ALineas.SQLLock.Text :=
      'SELECT * FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
      '   AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
      '   AND LINEA_FACLIN = :Old_LINEA_FACLIN ' +
      ' FOR UPDATE';
end;

procedure ConfigurarPersistenciaLineasFactura(
  AConexion: TUniConnection;
  ALineas: TUniQuery);
begin
  ALineas.Connection := AConexion;
  if ColumnasSkuLineasAplicadas(AConexion) then
  begin
    ConfigurarInsercionLineasFactura(ALineas);
    ConfigurarActualizacionLineasFactura(ALineas);
    ConfigurarLecturaBloqueoLineasFactura(ALineas);
  end;
end;

end.
