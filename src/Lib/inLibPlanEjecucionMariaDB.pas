{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPlanEjecucionMariaDB                                    }
{    Tipo:       Utilidad                                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       24/08/2026                                                   }
{                                                                              }
{  Descripción:                                                                }
{    Interpreta EXPLAIN/ANALYZE FORMAT=JSON de MariaDB y valida las sentencias }
{    SELECT que pueden utilizarse para obtener un plan de ejecución.           }
{******************************************************************************}
unit inLibPlanEjecucionMariaDB;

interface

uses
  System.SysUtils;

type
  TNodoPlanEjecucionMariaDB = record
    Id: Integer;
    PadreId: Integer;
    Nivel: Integer;
    Tipo: string;
    Titulo: string;
    Objeto: string;
    Acceso: string;
    Indice: string;
    Explicacion: string;
    RLoops: Double;
    Rows: Double;
    RRows: Double;
    RTotalTimeMs: Double;
    TieneRLoops: Boolean;
    TieneRows: Boolean;
    TieneRRows: Boolean;
    TieneRTotalTimeMs: Boolean;
  end;

  TPlanEjecucionMariaDB = record
    JsonOriginal: string;
    EsReal: Boolean;
    Nodos: TArray<TNodoPlanEjecucionMariaDB>;
  end;

function InterpretarPlanMariaDB(
  const AJson: string;
  AEsReal: Boolean): TPlanEjecucionMariaDB;

function NormalizarSelectParaPlan(const ASQL: string): string;

function ExtraerPrimeraSelectProcedimiento(
  const ADefinicion: string): string;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.JSON;

type
  TConstructorPlanMariaDB = class
  private
    FNodos: TList<TNodoPlanEjecucionMariaDB>;
    function AnadirNodo(
      const ATipo: string;
      AValor: TJSONValue;
      APadreId, ANivel: Integer): Integer;
    procedure CompletarNodo(
      var ANodo: TNodoPlanEjecucionMariaDB;
      const ATipo: string;
      AObjeto: TJSONObject);
    procedure ProcesarValor(
      AValor: TJSONValue;
      const AClave: string;
      APadreId, ANivel: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Construir(AValor: TJSONValue): TArray<TNodoPlanEjecucionMariaDB>;
  end;

function ValorObjeto(
  AObjeto: TJSONObject;
  const ANombre: string): TJSONValue;
begin
  Result := nil;
  if Assigned(AObjeto) then
    Result := AObjeto.GetValue(ANombre);
end;

function TextoValor(AValor: TJSONValue): string;
var
  i: Integer;
  oArray: TJSONArray;
begin
  Result := '';
  if not Assigned(AValor) or (AValor is TJSONNull) then
    Exit;

  if AValor is TJSONArray then
  begin
    oArray := TJSONArray(AValor);
    for i := 0 to oArray.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + TextoValor(oArray.Items[i]);
    end;
    Exit;
  end;

  if not (AValor is TJSONObject) then
    Result := AValor.Value;
end;

function TextoObjeto(
  AObjeto: TJSONObject;
  const ANombre: string): string;
begin
  Result := TextoValor(ValorObjeto(AObjeto, ANombre));
end;

function IntentarNumeroValor(
  AValor: TJSONValue;
  out ANumero: Double): Boolean;
var
  oFormato: TFormatSettings;
  sValor: string;
begin
  ANumero := 0;
  Result := Assigned(AValor) and not (AValor is TJSONNull);
  if not Result then
    Exit;

  sValor := Trim(AValor.Value);
  oFormato := TFormatSettings.Create;
  oFormato.DecimalSeparator := '.';
  oFormato.ThousandSeparator := #0;
  Result := TryStrToFloat(sValor, ANumero, oFormato);
end;

function IntentarNumeroObjeto(
  AObjeto: TJSONObject;
  const ANombre: string;
  out ANumero: Double): Boolean;
begin
  Result := IntentarNumeroValor(ValorObjeto(AObjeto, ANombre), ANumero);
end;

function TipoCanonico(const AClave: string): string;
var
  sClave: string;
begin
  sClave := LowerCase(AClave);
  if (sClave = 'range_checked_for_each_record') or
     (sClave = 'range-checked-for-each-record') or
     (sClave = 'range_checked') or
     (sClave = 'range-checked') then
    Result := 'range-checked'
  else
    Result := sClave;
end;

function EsTipoNodo(const ATipo: string): Boolean;
begin
  Result :=
    (ATipo = 'query_block') or
    (ATipo = 'nested_loop') or
    (ATipo = 'table') or
    (ATipo = 'filesort') or
    (ATipo = 'temporary_table') or
    (ATipo = 'materialized') or
    (ATipo = 'subqueries') or
    (ATipo = 'union_result') or
    (ATipo = 'block-nl-join') or
    (ATipo = 'expression_cache') or
    (ATipo = 'range-checked') or
    (ATipo = 'query_specifications') or
    (ATipo = 'read_sorted_file') or
    (ATipo = 'duplicates_removal') or
    (ATipo = 'grouping_operation') or
    (ATipo = 'ordering_operation') or
    (ATipo = 'window_functions_computation');
end;

function TituloTipo(
  const ATipo: string;
  AObjeto: TJSONObject): string;
var
  sDetalle: string;
begin
  if ATipo = 'query_block' then
  begin
    sDetalle := TextoObjeto(AObjeto, 'select_id');
    Result := 'Bloque SELECT';
    if sDetalle <> '' then
      Result := Result + ' ' + sDetalle;
  end
  else if ATipo = 'nested_loop' then
    Result := 'Bucle anidado'
  else if ATipo = 'table' then
  begin
    sDetalle := TextoObjeto(AObjeto, 'table_name');
    Result := 'Lectura de tabla';
    if sDetalle <> '' then
      Result := Result + ' ' + sDetalle;
  end
  else if ATipo = 'filesort' then
    Result := 'Ordenación (filesort)'
  else if ATipo = 'temporary_table' then
    Result := 'Tabla temporal'
  else if ATipo = 'materialized' then
    Result := 'Materialización'
  else if ATipo = 'subqueries' then
    Result := 'Subconsultas'
  else if ATipo = 'union_result' then
    Result := 'Resultado UNION'
  else if ATipo = 'block-nl-join' then
    Result := 'Unión por bloques (BNL)'
  else if ATipo = 'expression_cache' then
    Result := 'Caché de expresión'
  else if ATipo = 'range-checked' then
    Result := 'Índices evaluados por fila'
  else if ATipo = 'query_specifications' then
    Result := 'Ramas de UNION'
  else if ATipo = 'read_sorted_file' then
    Result := 'Lectura ordenada'
  else if ATipo = 'duplicates_removal' then
    Result := 'Eliminación de duplicados'
  else if ATipo = 'grouping_operation' then
    Result := 'Agrupación'
  else if ATipo = 'ordering_operation' then
    Result := 'Ordenación'
  else if ATipo = 'window_functions_computation' then
    Result := 'Funciones de ventana'
  else
    Result := ATipo;
end;

function ExplicacionAccesoTabla(const AAcceso: string): string;
begin
  if SameText(AAcceso, 'system') or SameText(AAcceso, 'const') then
    Result := 'MariaDB obtiene una sola fila constante.'
  else if SameText(AAcceso, 'eq_ref') then
    Result := 'Busca una única fila por índice por cada fila del nodo anterior.'
  else if SameText(AAcceso, 'ref') then
    Result := 'Busca por un índice no único usando un valor de referencia.'
  else if SameText(AAcceso, 'range') then
    Result := 'Recorre solamente un intervalo del índice.'
  else if SameText(AAcceso, 'index_merge') then
    Result := 'Combina los resultados de varios índices.'
  else if SameText(AAcceso, 'fulltext') then
    Result := 'Realiza una búsqueda mediante un índice FULLTEXT.'
  else if SameText(AAcceso, 'ref_or_null') then
    Result := 'Busca por índice y comprueba también las filas con valor NULL.'
  else if SameText(AAcceso, 'unique_subquery') then
    Result := 'Resuelve la subconsulta mediante una búsqueda única por índice.'
  else if SameText(AAcceso, 'index_subquery') then
    Result := 'Resuelve la subconsulta mediante una búsqueda por índice.'
  else if SameText(AAcceso, 'index') then
    Result := 'Recorre el índice completo.'
  else if SameText(AAcceso, 'ALL') then
    Result := 'Escanea todas las filas de la tabla.'
  else if AAcceso <> '' then
    Result := 'MariaDB utiliza el tipo de acceso ' + AAcceso + '.'
  else
    Result := 'Lee filas de la tabla para continuar el plan.';
end;

procedure AnadirDetalle(var ATexto: string; const ADetalle: string);
begin
  if ADetalle = '' then
    Exit;
  if ATexto <> '' then
    ATexto := ATexto + ' ';
  ATexto := ATexto + ADetalle;
end;

function ExplicacionTipo(
  const ATipo: string;
  AObjeto: TJSONObject): string;
var
  sDetalle: string;
begin
  if ATipo = 'query_block' then
    Result := 'Coordina las operaciones necesarias para producir el resultado de este SELECT.'
  else if ATipo = 'nested_loop' then
    Result := 'Por cada fila obtenida en un nodo se evalúa el siguiente nodo de la unión.'
  else if ATipo = 'table' then
    Result := ExplicacionAccesoTabla(TextoObjeto(AObjeto, 'access_type'))
  else if ATipo = 'filesort' then
  begin
    Result := 'Ordena las filas fuera del orden natural de un índice; puede usar memoria o disco.';
    sDetalle := TextoObjeto(AObjeto, 'sort_key');
    if sDetalle <> '' then
      AnadirDetalle(Result, 'Clave de ordenación: ' + sDetalle + '.');
  end
  else if ATipo = 'temporary_table' then
    Result := 'Materializa un resultado intermedio en una tabla temporal.'
  else if ATipo = 'materialized' then
    Result := 'Ejecuta una subconsulta y conserva su resultado para reutilizarlo.'
  else if ATipo = 'subqueries' then
    Result := 'Agrupa las subconsultas dependientes de este nodo.'
  else if ATipo = 'union_result' then
    Result := 'Combina los resultados producidos por las ramas de una UNION.'
  else if ATipo = 'block-nl-join' then
  begin
    Result := 'Guarda filas en un buffer y las compara por bloques con la siguiente entrada.';
    sDetalle := TextoObjeto(AObjeto, 'buffer_size');
    if sDetalle <> '' then
      AnadirDetalle(Result, 'Tamaño del buffer: ' + sDetalle + '.');
    sDetalle := TextoObjeto(AObjeto, 'join_type');
    if sDetalle <> '' then
      AnadirDetalle(Result, 'Tipo de unión: ' + sDetalle + '.');
  end
  else if ATipo = 'expression_cache' then
  begin
    Result := 'Memoriza resultados de una expresión o subconsulta repetida.';
    sDetalle := TextoObjeto(AObjeto, 'state');
    if sDetalle <> '' then
      AnadirDetalle(Result, 'Estado: ' + sDetalle + '.');
  end
  else if ATipo = 'range-checked' then
  begin
    Result := 'No hay un único índice fijado de antemano; MariaDB evalúa los índices disponibles para cada fila anterior.';
    sDetalle := TextoObjeto(AObjeto, 'keys');
    if sDetalle <> '' then
      AnadirDetalle(Result, 'Índices candidatos: ' + sDetalle + '.');
  end
  else if ATipo = 'query_specifications' then
    Result := 'Contiene las consultas individuales que forman la UNION.'
  else if ATipo = 'read_sorted_file' then
    Result := 'Lee el resultado producido por una operacion de ordenacion.'
  else if ATipo = 'duplicates_removal' then
    Result := 'Descarta filas duplicadas del resultado intermedio.'
  else if ATipo = 'grouping_operation' then
    Result := 'Agrupa filas para calcular agregados o resolver GROUP BY.'
  else if ATipo = 'ordering_operation' then
    Result := 'Ordena las filas para satisfacer ORDER BY.'
  else if ATipo = 'window_functions_computation' then
    Result := 'Calcula funciones de ventana sobre las filas de entrada.'
  else
    Result := 'Nodo del plan de ejecución de MariaDB.';

  sDetalle := TextoObjeto(AObjeto, 'attached_condition');
  if sDetalle <> '' then
    AnadirDetalle(Result, 'Condicion: ' + sDetalle + '.');
end;

{ TConstructorPlanMariaDB }

constructor TConstructorPlanMariaDB.Create;
begin
  inherited Create;
  FNodos := TList<TNodoPlanEjecucionMariaDB>.Create;
end;

destructor TConstructorPlanMariaDB.Destroy;
begin
  FNodos.Free;
  inherited Destroy;
end;

function TConstructorPlanMariaDB.AnadirNodo(
  const ATipo: string;
  AValor: TJSONValue;
  APadreId, ANivel: Integer): Integer;
var
  oObjeto: TJSONObject;
  oNodo: TNodoPlanEjecucionMariaDB;
begin
  oNodo := Default(TNodoPlanEjecucionMariaDB);
  oNodo.Id := Integer(FNodos.Count);
  oNodo.PadreId := APadreId;
  oNodo.Nivel := ANivel;
  oNodo.Tipo := ATipo;

  oObjeto := nil;
  if AValor is TJSONObject then
    oObjeto := TJSONObject(AValor);
  CompletarNodo(oNodo, ATipo, oObjeto);

  Result := oNodo.Id;
  FNodos.Add(oNodo);
end;

procedure TConstructorPlanMariaDB.CompletarNodo(
  var ANodo: TNodoPlanEjecucionMariaDB;
  const ATipo: string;
  AObjeto: TJSONObject);
var
  dOtroTiempo: Double;
  dTiempoTabla: Double;
  TieneOtroTiempo: Boolean;
  TieneTiempoTabla: Boolean;
begin
  ANodo.Titulo := TituloTipo(ATipo, AObjeto);
  ANodo.Objeto := TextoObjeto(AObjeto, 'table_name');
  ANodo.Acceso := TextoObjeto(AObjeto, 'access_type');
  if (ANodo.Acceso = '') and (ATipo = 'block-nl-join') then
    ANodo.Acceso := TextoObjeto(AObjeto, 'join_type');
  ANodo.Indice := TextoObjeto(AObjeto, 'key');
  ANodo.Explicacion := ExplicacionTipo(ATipo, AObjeto);

  ANodo.TieneRLoops := IntentarNumeroObjeto(
    AObjeto, 'r_loops', ANodo.RLoops);
  ANodo.TieneRows := IntentarNumeroObjeto(
    AObjeto, 'rows', ANodo.Rows);
  ANodo.TieneRRows := IntentarNumeroObjeto(
    AObjeto, 'r_rows', ANodo.RRows);
  ANodo.TieneRTotalTimeMs := IntentarNumeroObjeto(
    AObjeto, 'r_total_time_ms', ANodo.RTotalTimeMs);

  if not ANodo.TieneRTotalTimeMs then
  begin
    TieneTiempoTabla := IntentarNumeroObjeto(
      AObjeto, 'r_table_time_ms', dTiempoTabla);
    TieneOtroTiempo := IntentarNumeroObjeto(
      AObjeto, 'r_other_time_ms', dOtroTiempo);
    ANodo.TieneRTotalTimeMs := TieneTiempoTabla or TieneOtroTiempo;
    if ANodo.TieneRTotalTimeMs then
    begin
      ANodo.RTotalTimeMs := 0;
      if TieneTiempoTabla then
        ANodo.RTotalTimeMs := ANodo.RTotalTimeMs + dTiempoTabla;
      if TieneOtroTiempo then
        ANodo.RTotalTimeMs := ANodo.RTotalTimeMs + dOtroTiempo;
    end;
  end;
end;

function TConstructorPlanMariaDB.Construir(
  AValor: TJSONValue): TArray<TNodoPlanEjecucionMariaDB>;
begin
  FNodos.Clear;
  ProcesarValor(AValor, '', -1, 0);
  Result := FNodos.ToArray;
end;

procedure TConstructorPlanMariaDB.ProcesarValor(
  AValor: TJSONValue;
  const AClave: string;
  APadreId, ANivel: Integer);
var
  i: Integer;
  iNodoId: Integer;
  oArray: TJSONArray;
  oObjeto: TJSONObject;
  oPar: TJSONPair;
  sTipo: string;
begin
  if not Assigned(AValor) then
    Exit;

  sTipo := TipoCanonico(AClave);
  if EsTipoNodo(sTipo) then
  begin
    iNodoId := AnadirNodo(sTipo, AValor, APadreId, ANivel);
    APadreId := iNodoId;
    Inc(ANivel);
  end;

  if AValor is TJSONObject then
  begin
    oObjeto := TJSONObject(AValor);
    for i := 0 to oObjeto.Count - 1 do
    begin
      oPar := oObjeto.Pairs[i];
      if (oPar.JsonValue is TJSONObject) or
         (oPar.JsonValue is TJSONArray) then
        ProcesarValor(oPar.JsonValue, oPar.JsonString.Value,
          APadreId, ANivel);
    end;
  end
  else if AValor is TJSONArray then
  begin
    oArray := TJSONArray(AValor);
    for i := 0 to oArray.Count - 1 do
      if (oArray.Items[i] is TJSONObject) or
         (oArray.Items[i] is TJSONArray) then
        ProcesarValor(oArray.Items[i], '', APadreId, ANivel);
  end;
end;

function InterpretarPlanMariaDB(
  const AJson: string;
  AEsReal: Boolean): TPlanEjecucionMariaDB;
var
  oConstructor: TConstructorPlanMariaDB;
  oRaiz: TJSONValue;
  oRaizInterior: TJSONValue;
begin
  Result := Default(TPlanEjecucionMariaDB);
  Result.JsonOriginal := AJson;
  Result.EsReal := AEsReal;

  if Trim(AJson) = '' then
    raise EConvertError.Create('El plan de ejecución JSON está vacío.');

  oRaiz := TJSONObject.ParseJSONValue(AJson);
  if not Assigned(oRaiz) then
    raise EConvertError.Create('MariaDB no ha devuelto un JSON de plan valido.');
  try
    { Algunos componentes de acceso pueden devolver el JSON como una cadena JSON. }
    if oRaiz is TJSONString then
    begin
      oRaizInterior := TJSONObject.ParseJSONValue(oRaiz.Value);
      if not Assigned(oRaizInterior) then
        raise EConvertError.Create('La cadena devuelta no contiene un plan JSON valido.');
      try
        oConstructor := TConstructorPlanMariaDB.Create;
        try
          Result.Nodos := oConstructor.Construir(oRaizInterior);
        finally
          oConstructor.Free;
        end;
      finally
        oRaizInterior.Free;
      end;
    end
    else
    begin
      oConstructor := TConstructorPlanMariaDB.Create;
      try
        Result.Nodos := oConstructor.Construir(oRaiz);
      finally
        oConstructor.Free;
      end;
    end;
  finally
    oRaiz.Free;
  end;

  if Length(Result.Nodos) = 0 then
    raise EConvertError.Create(
      'El JSON no contiene nodos reconocibles de un plan de MariaDB.');
end;

function EsInicioPalabraSQL(ACaracter: Char): Boolean;
begin
  Result := CharInSet(ACaracter, ['A'..'Z', 'a'..'z', '_', '$']);
end;

function EsPartePalabraSQL(ACaracter: Char): Boolean;
begin
  Result := EsInicioPalabraSQL(ACaracter) or
    CharInSet(ACaracter, ['0'..'9']);
end;

function EsInicioComentarioGuion(
  const ASQL: string;
  APosicion: Integer): Boolean;
begin
  Result := (APosicion < Length(ASQL)) and
    (ASQL[APosicion] = '-') and
    (ASQL[APosicion + 1] = '-') and
    ((APosicion + 2 > Length(ASQL)) or
     (Ord(ASQL[APosicion + 2]) <= 32));
end;

procedure SaltarComentarioLinea(const ASQL: string; var APosicion: Integer);
begin
  while (APosicion <= Length(ASQL)) and
        not CharInSet(ASQL[APosicion], [#10, #13]) do
    Inc(APosicion);
end;

procedure SaltarComentarioBloque(
  const ASQL: string;
  var APosicion: Integer;
  ARechazarEjecutable: Boolean);
var
  EsEjecutable: Boolean;
begin
  EsEjecutable :=
    ((APosicion + 2 <= Length(ASQL)) and
     CharInSet(ASQL[APosicion + 2], ['!', '+'])) or
    ((APosicion + 3 <= Length(ASQL)) and
     CharInSet(ASQL[APosicion + 2], ['M', 'm']) and
     (ASQL[APosicion + 3] = '!'));
  if ARechazarEjecutable and EsEjecutable then
    raise EArgumentException.Create(
      'No se admiten comentarios ejecutables ni pistas /*+ */ en el SELECT.');

  Inc(APosicion, 2);
  while (APosicion + 1 <= Length(ASQL)) and
        not ((ASQL[APosicion] = '*') and (ASQL[APosicion + 1] = '/')) do
    Inc(APosicion);
  if APosicion + 1 > Length(ASQL) then
    raise EArgumentException.Create('El comentario SQL no está cerrado.');
  Inc(APosicion, 2);
end;

procedure SaltarLiteral(
  const ASQL: string;
  var APosicion: Integer;
  ADelimitador: Char);
begin
  Inc(APosicion);
  while APosicion <= Length(ASQL) do
  begin
    if (ASQL[APosicion] = '\') and (APosicion < Length(ASQL)) then
    begin
      Inc(APosicion, 2);
      Continue;
    end;
    if ASQL[APosicion] = ADelimitador then
    begin
      if (APosicion < Length(ASQL)) and
         (ASQL[APosicion + 1] = ADelimitador) then
      begin
        Inc(APosicion, 2);
        Continue;
      end;
      Inc(APosicion);
      Exit;
    end;
    Inc(APosicion);
  end;
  raise EArgumentException.Create('Hay una cadena o identificador SQL sin cerrar.');
end;

function NormalizarSelectParaPlan(const ASQL: string): string;
var
  EsPrimeraPalabra: Boolean;
  i: Integer;
  iFin: Integer;
  iInicio: Integer;
  iInicioSelect: Integer;
  iPuntoComa: Integer;
  sPalabra: string;
begin
  if Pos(#0, ASQL) > 0 then
    raise EArgumentException.Create('El SQL contiene un carácter nulo no válido.');
  if Pos('\', ASQL) > 0 then
    raise EArgumentException.Create(
      'No se admiten barras invertidas: su interpretación depende de ' +
      'NO_BACKSLASH_ESCAPES. Use comillas duplicadas en los literales.');

  i := 1;
  iInicioSelect := 0;
  iPuntoComa := 0;
  EsPrimeraPalabra := True;

  while i <= Length(ASQL) do
  begin
    if CharInSet(ASQL[i], [' ', #9, #10, #13]) then
    begin
      Inc(i);
      Continue;
    end;

    if EsInicioComentarioGuion(ASQL, i) then
    begin
      Inc(i, 2);
      SaltarComentarioLinea(ASQL, i);
      Continue;
    end;
    if ASQL[i] = '#' then
    begin
      Inc(i);
      SaltarComentarioLinea(ASQL, i);
      Continue;
    end;
    if (ASQL[i] = '/') and (i < Length(ASQL)) and
       (ASQL[i + 1] = '*') then
    begin
      SaltarComentarioBloque(ASQL, i, True);
      Continue;
    end;

    if iPuntoComa > 0 then
      raise EArgumentException.Create(
        'Solo se admite una sentencia SELECT sin instrucciones posteriores.');

    if CharInSet(ASQL[i], ['''', '"', '`']) then
    begin
      if EsPrimeraPalabra then
        raise EArgumentException.Create(
          'Antes de SELECT solo puede haber espacios o comentarios.');
      SaltarLiteral(ASQL, i, ASQL[i]);
      Continue;
    end;

    if ASQL[i] = ';' then
    begin
      iPuntoComa := i;
      Inc(i);
      Continue;
    end;

    if EsInicioPalabraSQL(ASQL[i]) then
    begin
      iInicio := i;
      Inc(i);
      while (i <= Length(ASQL)) and EsPartePalabraSQL(ASQL[i]) do
        Inc(i);
      sPalabra := Copy(ASQL, iInicio, i - iInicio);

      if EsPrimeraPalabra then
      begin
        if not SameText(sPalabra, 'SELECT') then
          raise EArgumentException.Create(
            'El plan solo admite una sentencia que comience por SELECT.');
        iInicioSelect := iInicio;
        EsPrimeraPalabra := False;
      end
      else if SameText(sPalabra, 'INTO') or
              SameText(sPalabra, 'OUTFILE') or
              SameText(sPalabra, 'DUMPFILE') then
        raise EArgumentException.Create(
          'No se admite SELECT INTO, OUTFILE ni DUMPFILE para obtener el plan.')
      else if SameText(sPalabra, 'UPDATE') or
              SameText(sPalabra, 'LOCK') or
              SameText(sPalabra, 'GET_LOCK') or
              SameText(sPalabra, 'RELEASE_LOCK') or
              SameText(sPalabra, 'RELEASE_ALL_LOCKS') or
              SameText(sPalabra, 'SLEEP') or
              SameText(sPalabra, 'BENCHMARK') or
              SameText(sPalabra, 'LOAD_FILE') or
              SameText(sPalabra, 'NEXTVAL') or
              SameText(sPalabra, 'SETVAL') or
              SameText(sPalabra, 'LAST_INSERT_ID') then
        raise EArgumentException.CreateFmt(
          'No se admite %s en una SELECT destinada al plan de ejecución.',
          [sPalabra]);
      Continue;
    end;

    if EsPrimeraPalabra then
      raise EArgumentException.Create(
        'Antes de SELECT solo puede haber espacios o comentarios.');
    if (ASQL[i] = ':') and (i < Length(ASQL)) and
       (ASQL[i + 1] = '=') then
      raise EArgumentException.Create(
        'No se admiten asignaciones de variables (:=) en la SELECT.');
    Inc(i);
  end;

  if EsPrimeraPalabra or (iInicioSelect = 0) then
    raise EArgumentException.Create('No se ha encontrado una sentencia SELECT.');

  if iPuntoComa > 0 then
    iFin := iPuntoComa - 1
  else
    iFin := Length(ASQL);
  Result := Trim(Copy(ASQL, iInicioSelect, iFin - iInicioSelect + 1));
  if Result = '' then
    raise EArgumentException.Create('La sentencia SELECT está vacía.');
end;

function BuscarPalabraSelect(
  const ASQL: string;
  var APosicion: Integer;
  out AInicio: Integer): Boolean;
var
  bInicioSentencia: Boolean;
  iInicio: Integer;
  sPalabra: string;
begin
  Result := False;
  AInicio := 0;
  bInicioSentencia := True;
  while APosicion <= Length(ASQL) do
  begin
    if CharInSet(ASQL[APosicion], [' ', #9, #10, #13]) then
    begin
      Inc(APosicion);
      Continue;
    end;
    if EsInicioComentarioGuion(ASQL, APosicion) then
    begin
      Inc(APosicion, 2);
      SaltarComentarioLinea(ASQL, APosicion);
      Continue;
    end;
    if ASQL[APosicion] = '#' then
    begin
      Inc(APosicion);
      SaltarComentarioLinea(ASQL, APosicion);
      Continue;
    end;
    if (ASQL[APosicion] = '/') and (APosicion < Length(ASQL)) and
       (ASQL[APosicion + 1] = '*') then
    begin
      SaltarComentarioBloque(ASQL, APosicion, False);
      Continue;
    end;
    if CharInSet(ASQL[APosicion], ['''', '"', '`']) then
    begin
      SaltarLiteral(ASQL, APosicion, ASQL[APosicion]);
      Continue;
    end;
    if EsInicioPalabraSQL(ASQL[APosicion]) then
    begin
      iInicio := APosicion;
      Inc(APosicion);
      while (APosicion <= Length(ASQL)) and
            EsPartePalabraSQL(ASQL[APosicion]) do
        Inc(APosicion);
      sPalabra := Copy(ASQL, iInicio, APosicion - iInicio);
      if SameText(sPalabra, 'SELECT') and bInicioSentencia then
      begin
        AInicio := iInicio;
        Exit(True);
      end;
      bInicioSentencia :=
        SameText(sPalabra, 'BEGIN') or
        SameText(sPalabra, 'THEN') or
        SameText(sPalabra, 'ELSE') or
        SameText(sPalabra, 'DO');
      Continue;
    end;
    if CharInSet(ASQL[APosicion], [';', ':']) then
      bInicioSentencia := True
    else
      bInicioSentencia := False;
    Inc(APosicion);
  end;
end;

function BuscarFinSentenciaSelect(
  const ASQL: string;
  AInicio: Integer;
  out AFin: Integer): Boolean;
var
  i: Integer;
begin
  i := AInicio;
  while i <= Length(ASQL) do
  begin
    if EsInicioComentarioGuion(ASQL, i) then
    begin
      Inc(i, 2);
      SaltarComentarioLinea(ASQL, i);
      Continue;
    end;
    if ASQL[i] = '#' then
    begin
      Inc(i);
      SaltarComentarioLinea(ASQL, i);
      Continue;
    end;
    if (ASQL[i] = '/') and (i < Length(ASQL)) and
       (ASQL[i + 1] = '*') then
    begin
      SaltarComentarioBloque(ASQL, i, False);
      Continue;
    end;
    if CharInSet(ASQL[i], ['''', '"', '`']) then
    begin
      SaltarLiteral(ASQL, i, ASQL[i]);
      Continue;
    end;
    if ASQL[i] = ';' then
    begin
      AFin := i - 1;
      Exit(True);
    end;
    Inc(i);
  end;
  AFin := Length(ASQL);
  Result := False;
end;

function ExtraerPrimeraSelectProcedimiento(
  const ADefinicion: string): string;
var
  i: Integer;
  iFin: Integer;
  iInicio: Integer;
  sCandidata: string;
begin
  Result := '';
  i := 1;
  while BuscarPalabraSelect(ADefinicion, i, iInicio) do
  begin
    if not BuscarFinSentenciaSelect(ADefinicion, iInicio, iFin) then
      Exit;

    sCandidata := Copy(ADefinicion, iInicio, iFin - iInicio + 1);
    try
      Result := NormalizarSelectParaPlan(sCandidata);
      Exit;
    except
      on E: EArgumentException do
      begin
        i := iFin + 2;
        Result := '';
      end;
    end;
  end;
end;

end.
