unit inLibArticulosCodigosBarras;

{
  Caso de uso de generacion progresiva de codigos de barras por SKU.
  La primera ejecucion crea el EAN-13 principal y la siguiente prepara
  la fila vacia para el codigo del fabricante.
}

interface

uses
  inLibArticulosVariacionesIntf,
  inLibArticulosCodigosBarrasPersistenciaIntf;

type
  TResultadoCodigosBarrasArticulo = record
    PrincipalesGenerados: Integer;
    FilasFabricanteCreadas: Integer;
    SkusSinCambios: Integer;
    MarcadoresAntiguosEliminados: Integer;
  end;

function GenerarCodigosBarrasArticulo(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;

implementation

uses
  System.SysUtils,
  inLibArticulosVariaciones,
  inLibEAN13;

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
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AUsuario: string): string;
var
  sCodigoBase: string;
  sContador: string;
begin
  sContador := APersistencia.ObtenerSiguienteContador(
    cTipoContadorCodigoBarras, AUsuario);
  sContador := NormalizarContadorCodigoBarras(sContador);
  sCodigoBase := cPrefijoCodigoBarrasInterno + sContador;
  Result := sCodigoBase + CalcularDigitoEAN13(sCodigoBase);
end;

function GenerarCodigosBarrasArticulo(
  const APersistencia: IArticulosCodigosBarrasPersistencia;
  const AArticulosVariaciones: IArticulosVariaciones;
  const ACodigoArticulo, AUsuario: string;
  out AResultado: TResultadoCodigosBarrasArticulo): Boolean;
var
  aSkus: TArray<TEstadoCodigoBarrasSku>;
  bTransaccionPropia: Boolean;
  iIndice: Integer;
  sCodigoBarras: string;
begin
  Result := False;
  AResultado := Default(TResultadoCodigosBarrasArticulo);
  if (Trim(ACodigoArticulo) <> '') and Assigned(APersistencia) then
  begin
    bTransaccionPropia := not APersistencia.EnTransaccion;
    if bTransaccionPropia then
      APersistencia.IniciarTransaccion;
    try
      AsegurarSkuArticuloActivo(
        AArticulosVariaciones, ACodigoArticulo, AUsuario);
      AResultado.MarcadoresAntiguosEliminados :=
        APersistencia.EliminarMarcadoresAntiguos(ACodigoArticulo);
      aSkus := APersistencia.ConsultarSkusActivos(ACodigoArticulo);
      Result := Length(aSkus) > 0;
      for iIndice := 0 to High(aSkus) do
      begin
        if not aSkus[iIndice].TienePrincipal then
        begin
          sCodigoBarras := CrearCodigoBarrasInterno(
            APersistencia, AUsuario);
          APersistencia.InsertarCodigoPrincipal(
            aSkus[iIndice].CodigoSku, sCodigoBarras,
            cTipoCodigoBarrasInterno, AUsuario);
          Inc(AResultado.PrincipalesGenerados);
        end
        else if not aSkus[iIndice].TieneFilaFabricante then
        begin
          APersistencia.InsertarFilaFabricante(
            aSkus[iIndice].CodigoSku,
            cTipoCodigoBarrasInterno, AUsuario);
          Inc(AResultado.FilasFabricanteCreadas);
        end
        else
          Inc(AResultado.SkusSinCambios);
      end;
      if Result then
      begin
        if bTransaccionPropia and APersistencia.EnTransaccion then
          APersistencia.ConfirmarTransaccion;
      end
      else if bTransaccionPropia and APersistencia.EnTransaccion then
        APersistencia.RevertirTransaccion;
    except
      if bTransaccionPropia and APersistencia.EnTransaccion then
        APersistencia.RevertirTransaccion;
      raise;
    end;
  end;
end;

end.
