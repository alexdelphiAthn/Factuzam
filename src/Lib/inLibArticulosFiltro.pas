unit inLibArticulosFiltro;

{
  Construccion pura del filtro de carga de articulos. No conoce controles
  ni datasets, por lo que se puede caracterizar con pruebas unitarias.
}

interface

type
  TEstadoFiltroArticulos = (
    efaTodos,
    efaActivos,
    efaInactivos
  );

  TFiltroArticulos = record
    Estado: TEstadoFiltroArticulos;
    SoloConStock: Boolean;
    TemporadasCsv: string;
    ProveedoresCsv: string;
    FamiliasCsv: string;
  end;

function ConvertirCsvEnListaSql(const ACsv: string): string;
function ConstruirWhereFiltroArticulos(
  const AFiltro: TFiltroArticulos): string;
function ConstruirSqlFiltroArticulos(
  const AFiltro: TFiltroArticulos): string;

implementation

uses
  System.SysUtils,
  System.Classes;

function ConvertirCsvEnListaSql(const ACsv: string): string;
var
  Lista: TStringList;
  iIndice: Integer;
  sValor: string;
begin
  Result := '';
  if Trim(ACsv) <> '' then
  begin
    Lista := TStringList.Create;
    try
      Lista.Delimiter := ';';
      Lista.StrictDelimiter := True;
      Lista.DelimitedText := ACsv;
      for iIndice := 0 to Lista.Count - 1 do
      begin
        sValor := Trim(Lista[iIndice]);
        if sValor <> '' then
        begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + QuotedStr(sValor);
        end;
      end;
    finally
      FreeAndNil(Lista);
    end;
  end;
end;

procedure AgregarFiltroLista(
  AConstructor: TStringBuilder;
  const ACampo, ACsv: string);
var
  sLista: string;
begin
  sLista := ConvertirCsvEnListaSql(ACsv);
  if sLista <> '' then
    AConstructor.AppendLine(
      '  AND ' + ACampo + ' IN (' + sLista + ')');
end;

function ConstruirWhereFiltroArticulos(
  const AFiltro: TFiltroArticulos): string;
var
  Generador: TStringBuilder;
begin
  Generador := TStringBuilder.Create;
  try
    Generador.AppendLine('WHERE 1 = 1');
    case AFiltro.Estado of
      efaActivos:
        Generador.AppendLine(
          '  AND vi_articulos.ESACTIVO_ART = ''S''');
      efaInactivos:
        Generador.AppendLine(
          '  AND vi_articulos.ESACTIVO_ART = ''N''');
    end;
    if AFiltro.SoloConStock then
      Generador.AppendLine(
        '  AND EXISTS (SELECT 1 FROM fza_articulos_skus sk ' +
        ' JOIN fza_articulos_stockactual stk ' +
        '   ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU ' +
        ' WHERE sk.CODIGO_ART_SKU = ' +
        'vi_articulos.CODIGO_ART_ART ' +
        '   AND stk.CANTIDAD_STK > 0)');
    AgregarFiltroLista(
      Generador,
      'vi_articulos.TEMPORADA_ART',
      AFiltro.TemporadasCsv);
    AgregarFiltroLista(
      Generador,
      'vi_articulos.CODIGO_PRV_AP',
      AFiltro.ProveedoresCsv);
    AgregarFiltroLista(
      Generador,
      'vi_articulos.CODIGO_FAM_ART',
      AFiltro.FamiliasCsv);
    Result := Generador.ToString;
  finally
    FreeAndNil(Generador);
  end;
end;

function ConstruirSqlFiltroArticulos(
  const AFiltro: TFiltroArticulos): string;
begin
  Result :=
    'SELECT * FROM vi_articulos' + sLineBreak +
    ConstruirWhereFiltroArticulos(AFiltro) +
    'ORDER BY vi_articulos.ORDEN_ART';
end;

end.
