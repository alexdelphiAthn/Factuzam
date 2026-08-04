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

function SepararValoresFiltroArticulos(
  const ACsv: string): TArray<string>;

implementation

uses
  System.SysUtils,
  System.Classes;

function SepararValoresFiltroArticulos(
  const ACsv: string): TArray<string>;
var
  Lista: TStringList;
  iIndice: Integer;
  sValor: string;
begin
  Result := nil;
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
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := sValor;
        end;
      end;
    finally
      FreeAndNil(Lista);
    end;
  end;
end;

end.
