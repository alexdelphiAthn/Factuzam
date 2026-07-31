unit inLibArticulosCodigosBarras;

{
  Caso de uso de generacion progresiva de codigos de barras por SKU.
  La primera ejecucion crea el EAN-13 principal y la siguiente prepara
  la fila vacia para el codigo del fabricante.
}

interface

uses
  Uni, inLibArticulosVariacionesIntf;

type
  TResultadoCodigosBarrasArticulo = record
    PrincipalesGenerados: Integer;
    FilasFabricanteCreadas: Integer;
    SkusSinCambios: Integer;
    MarcadoresAntiguosEliminados: Integer;
  end;

function GenerarCodigosBarrasArticulo(
  AConexion: TUniConnection;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;

implementation

uses
  System.SysUtils,
  Data.DB,
  DBAccess,
  inLibArticulosVariaciones,
  inLibEAN13,
  inLibValoresAutomaticos;

const
  cTipoContadorCodigoBarras = 'BA';
  cPrefijoCodigoBarrasInterno = '21';
  cDigitosContadorCodigoBarras = 10;
  cTipoCodigoBarrasInterno = 'EAN13';

function NormalizarContadorCodigoBarras(
  const AContador: string): string;
begin
  if Length(AContador) > cDigitosContadorCodigoBarras then
    Result := Copy(
      AContador,
      Length(AContador) - cDigitosContadorCodigoBarras + 1,
      cDigitosContadorCodigoBarras)
  else
    Result := StringOfChar(
      '0',
      cDigitosContadorCodigoBarras - Length(AContador)) +
      AContador;
end;

function CrearCodigoBarrasInterno(
  AConexion: TUniConnection;
  const AUsuario: string): string;
var
  sContador: string;
  sCodigoBase: string;
begin
  sContador := ObtenerSiguienteContador(
    AConexion, cTipoContadorCodigoBarras, AUsuario);
  sContador := NormalizarContadorCodigoBarras(sContador);
  sCodigoBase := cPrefijoCodigoBarrasInterno + sContador;
  Result := sCodigoBase + CalcularDigitoEAN13(sCodigoBase);
end;

procedure InsertarCodigoPrincipal(
  AConsulta: TUniQuery;
  const ACodigoSku, ACodigoBarras, AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_codigos_barras ' +
    '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
    '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES (:codigo, :sku, :tipo, ''S'', ' +
    '        CURRENT_TIMESTAMP, :usuario, :usuario)';
  AConsulta.ParamByName('codigo').AsString := ACodigoBarras;
  AConsulta.ParamByName('sku').AsString := ACodigoSku;
  AConsulta.ParamByName('tipo').AsString := cTipoCodigoBarrasInterno;
  AConsulta.ParamByName('usuario').AsString := AUsuario;
  AConsulta.ExecSQL;
end;

procedure InsertarFilaCodigoFabricante(
  AConsulta: TUniQuery;
  const ACodigoSku, AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_codigos_barras ' +
    '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
    '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES ('''', :sku, ''EAN13'', ''N'', ' +
    '        CURRENT_TIMESTAMP, :usuario, :usuario)';
  AConsulta.ParamByName('sku').AsString := ACodigoSku;
  AConsulta.ParamByName('usuario').AsString := AUsuario;
  AConsulta.ExecSQL;
end;

function GenerarCodigosBarrasArticulo(
  AConexion: TUniConnection;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;
var
  ConsultaSkus: TUniQuery;
  ConsultaCambio: TUniQuery;
  bTxOwned: Boolean;
  sCodigoSku: string;
  sCodigoBarras: string;
begin
  Result := False;
  AResultado.PrincipalesGenerados := 0;
  AResultado.FilasFabricanteCreadas := 0;
  AResultado.SkusSinCambios := 0;
  AResultado.MarcadoresAntiguosEliminados := 0;
  if ACodigoArticulo <> '' then
  begin
    bTxOwned := not AConexion.InTransaction;
    if bTxOwned then
      AConexion.StartTransaction;
    try
      AsegurarSkuArticuloActivo(
        AArticulosVariaciones, ACodigoArticulo, AUsuario);
      ConsultaSkus := TUniQuery.Create(nil);
      ConsultaCambio := TUniQuery.Create(nil);
      try
        ConsultaSkus.Connection := AConexion;
        ConsultaCambio.Connection := AConexion;
        ConsultaCambio.SQL.Text :=
          'DELETE CB FROM fza_codigos_barras CB ' +
          '  JOIN fza_articulos_skus SKU ' +
          '    ON SKU.CODIGO_UNIDAD_SKU = CB.CODIGO_UNIDAD_CB ' +
          ' WHERE SKU.CODIGO_ART_SKU = :art ' +
          '   AND LEFT(CB.CODIGO_BARRAS_CB, 5) = ''_FAB_''';
        ConsultaCambio.ParamByName('art').AsString := ACodigoArticulo;
        ConsultaCambio.ExecSQL;
        AResultado.MarcadoresAntiguosEliminados :=
          ConsultaCambio.RowsAffected;
        ConsultaSkus.SQL.Text :=
          'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
          '       (SELECT COUNT(*) FROM fza_codigos_barras P ' +
          '         WHERE P.CODIGO_UNIDAD_CB = SKU.CODIGO_UNIDAD_SKU ' +
          '           AND P.ESPRINCIPAL_CB = ''S'') AS NUM_PRIN, ' +
          '       (SELECT COUNT(*) FROM fza_codigos_barras V ' +
          '         WHERE V.CODIGO_UNIDAD_CB = SKU.CODIGO_UNIDAD_SKU ' +
          '           AND COALESCE(V.CODIGO_BARRAS_CB, '''') = '''') ' +
          '         AS NUM_EMPTY ' +
          '  FROM fza_articulos_skus SKU ' +
          ' WHERE SKU.CODIGO_ART_SKU = :art ' +
          '   AND SKU.ESACTIVO_SKU = ''S''';
        ConsultaSkus.ParamByName('art').AsString := ACodigoArticulo;
        ConsultaSkus.Open;
        Result := not ConsultaSkus.IsEmpty;
        while not ConsultaSkus.Eof do
        begin
          sCodigoSku :=
            ConsultaSkus.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          if ConsultaSkus.FieldByName('NUM_PRIN').AsInteger = 0 then
          begin
            sCodigoBarras := CrearCodigoBarrasInterno(
              AConexion, AUsuario);
            InsertarCodigoPrincipal(
              ConsultaCambio, sCodigoSku, sCodigoBarras, AUsuario);
            Inc(AResultado.PrincipalesGenerados);
          end
          else if ConsultaSkus.FieldByName('NUM_EMPTY').AsInteger = 0 then
          begin
            InsertarFilaCodigoFabricante(
              ConsultaCambio, sCodigoSku, AUsuario);
            Inc(AResultado.FilasFabricanteCreadas);
          end
          else
            Inc(AResultado.SkusSinCambios);
          ConsultaSkus.Next;
        end;
      finally
        FreeAndNil(ConsultaCambio);
        FreeAndNil(ConsultaSkus);
      end;
      if Result then
      begin
        if bTxOwned and AConexion.InTransaction then
          AConexion.Commit;
      end
      else if bTxOwned and AConexion.InTransaction then
        AConexion.Rollback;
    except
      if bTxOwned and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  end;
end;

end.
