unit AlbionPedidoParser;

interface

uses
  System.JSON;

type
  EAlbionPedidoParser = class(Exception);

  TAlbionPedidoParser = class
  public
    class function ConvertirArchivo(const ARutaJson: string): TJSONObject; static;
    class function ConvertirTexto(const AJson: string): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.DateUtils,
  System.Math,
  System.Generics.Collections;

type
  TTablaAzure = record
    Filas: Integer;
    Columnas: Integer;
    Celdas: TArray<TArray<string>>;
  end;

  TTablasAzure = TArray<TTablaAzure>;

  TTallaCantidad = record
    Talla: string;
    Cantidad: Integer;
  end;

  TLineaAlbion = class
  public
    Modelo: string;
    Descripcion: string;
    Color: string;
    Tallas: TList<TTallaCantidad>;
    Cantidad: Integer;
    Pvp: Double;
    PrecioUnitario: Double;
    Importe: Double;
    constructor Create;
    destructor Destroy; override;
  end;

const
  CProveedor = 'ALBION 1879, SL';

constructor TLineaAlbion.Create;
begin
  inherited Create;
  Tallas := TList<TTallaCantidad>.Create;
end;

destructor TLineaAlbion.Destroy;
begin
  Tallas.Free;
  inherited Destroy;
end;

function ValorJson(AObjeto: TJSONObject; const ANombre: string): TJSONValue;
begin
  if AObjeto = nil then
    Exit(nil);
  Result := AObjeto.GetValue(ANombre);
end;

function ObjetoJson(AObjeto: TJSONObject; const ANombre: string): TJSONObject;
var
  Valor: TJSONValue;
begin
  Valor := ValorJson(AObjeto, ANombre);
  if Valor is TJSONObject then
    Exit(TJSONObject(Valor));
  Result := nil;
end;

function ArrayJson(AObjeto: TJSONObject; const ANombre: string): TJSONArray;
var
  Valor: TJSONValue;
begin
  Valor := ValorJson(AObjeto, ANombre);
  if Valor is TJSONArray then
    Exit(TJSONArray(Valor));
  Result := nil;
end;

function CadenaJson(AObjeto: TJSONObject; const ANombre: string;
  const ADefecto: string = ''): string;
var
  Valor: TJSONValue;
begin
  Valor := ValorJson(AObjeto, ANombre);
  if (Valor = nil) or (Valor is TJSONNull) then
    Exit(ADefecto);
  Result := Valor.Value;
end;

function EnteroJson(AObjeto: TJSONObject; const ANombre: string;
  ADefecto: Integer = 0): Integer;
var
  Texto: string;
begin
  Texto := CadenaJson(AObjeto, ANombre, '');
  if not TryStrToInt(Texto, Result) then
    Result := ADefecto;
end;

function NormalizarEspacios(const ATexto: string): string;
var
  I: Integer;
  EsEspacio: Boolean;
  Constructor: TStringBuilder;
begin
  Constructor := TStringBuilder.Create;
  try
    EsEspacio := True;
    for I := 1 to Length(ATexto) do
    begin
      if CharInSet(ATexto[I], [#9, #10, #13, ' ']) then
      begin
        if not EsEspacio then
          Constructor.Append(' ');
        EsEspacio := True;
      end
      else
      begin
        Constructor.Append(ATexto[I]);
        EsEspacio := False;
      end;
    end;
    Result := Trim(Constructor.ToString);
  finally
    Constructor.Free;
  end;
end;

function Celda(const ATabla: TTablaAzure; AFila, AColumna: Integer): string;
begin
  if (AFila < 0) or (AFila >= ATabla.Filas) or
     (AColumna < 0) or (AColumna >= ATabla.Columnas) then
    Exit('');
  Result := ATabla.Celdas[AFila][AColumna];
end;

function LeerTablas(AAnalisis: TJSONObject): TTablasAzure;
var
  TablasJson: TJSONArray;
  TablaJson: TJSONObject;
  CeldasJson: TJSONArray;
  CeldaJson: TJSONObject;
  I, J, Fila, Columna: Integer;
begin
  SetLength(Result, 0);
  TablasJson := ArrayJson(AAnalisis, 'tables');
  if TablasJson = nil then
    Exit;

  SetLength(Result, TablasJson.Count);
  for I := 0 to TablasJson.Count - 1 do
  begin
    if not (TablasJson.Items[I] is TJSONObject) then
      Continue;

    TablaJson := TJSONObject(TablasJson.Items[I]);
    Result[I].Filas := EnteroJson(TablaJson, 'rowCount');
    Result[I].Columnas := EnteroJson(TablaJson, 'columnCount');
    SetLength(Result[I].Celdas, Result[I].Filas);
    for J := 0 to Result[I].Filas - 1 do
      SetLength(Result[I].Celdas[J], Result[I].Columnas);

    CeldasJson := ArrayJson(TablaJson, 'cells');
    if CeldasJson = nil then
      Continue;

    for J := 0 to CeldasJson.Count - 1 do
    begin
      if not (CeldasJson.Items[J] is TJSONObject) then
        Continue;
      CeldaJson := TJSONObject(CeldasJson.Items[J]);
      Fila := EnteroJson(CeldaJson, 'rowIndex', -1);
      Columna := EnteroJson(CeldaJson, 'columnIndex', -1);
      if (Fila >= 0) and (Fila < Result[I].Filas) and
         (Columna >= 0) and (Columna < Result[I].Columnas) then
        Result[I].Celdas[Fila][Columna] :=
          NormalizarEspacios(CadenaJson(CeldaJson, 'content'));
    end;
  end;
end;

function ContieneTodos(const ATexto: string;
  const ATerminos: array of string): Boolean;
var
  I: Integer;
begin
  for I := Low(ATerminos) to High(ATerminos) do
    if not ContainsText(ATexto, ATerminos[I]) then
      Exit(False);
  Result := True;
end;

function BuscarCelda(const ATablas: TTablasAzure;
  const ATerminos: array of string; out AIndiceTabla, AFila,
  AColumna: Integer): Boolean;
var
  T, F, C: Integer;
begin
  for T := 0 to High(ATablas) do
    for F := 0 to ATablas[T].Filas - 1 do
      for C := 0 to ATablas[T].Columnas - 1 do
        if ContieneTodos(Celda(ATablas[T], F, C), ATerminos) then
        begin
          AIndiceTabla := T;
          AFila := F;
          AColumna := C;
          Exit(True);
        end;

  AIndiceTabla := -1;
  AFila := -1;
  AColumna := -1;
  Result := False;
end;

function ValorDebajo(const ATablas: TTablasAzure;
  const ATerminos: array of string): string;
var
  T, F, C: Integer;
begin
  if BuscarCelda(ATablas, ATerminos, T, F, C) then
    Exit(Trim(Celda(ATablas[T], F + 1, C)));
  Result := '';
end;

function ValorDerecha(const ATablas: TTablasAzure;
  const ATerminos: array of string): string;
var
  T, F, C: Integer;
begin
  if BuscarCelda(ATablas, ATerminos, T, F, C) then
    Exit(Trim(Celda(ATablas[T], F, C + 1)));
  Result := '';
end;

function ValorDespuesEtiquetaEnLinea(const ATexto, AEtiqueta: string): string;
var
  Inicio, FinLinea: Integer;
begin
  Inicio := PosText(AEtiqueta, ATexto);
  if Inicio = 0 then
    Exit('');
  Inc(Inicio, Length(AEtiqueta));
  FinLinea := Inicio;
  while (FinLinea <= Length(ATexto)) and
        not CharInSet(ATexto[FinLinea], [#10, #13]) do
    Inc(FinLinea);
  Result := Trim(Copy(ATexto, Inicio, FinLinea - Inicio));
end;

function ExtraerDireccionProveedor(const ATexto: string): string;
var
  Inicio, Fin: Integer;
  Bloque: string;
begin
  Inicio := PosText(CProveedor, ATexto);
  if Inicio = 0 then
    Exit('');
  Inc(Inicio, Length(CProveedor));
  Fin := PosText('CIF:', ATexto);
  if (Fin = 0) or (Fin <= Inicio) then
    Fin := Length(ATexto) + 1;
  Bloque := Copy(ATexto, Inicio, Fin - Inicio);
  Result := NormalizarEspacios(Bloque);
end;

function FechaIso(const AFecha: string): string;
var
  Partes: TStringList;
  Dia, Mes, Anio: Integer;
  Fecha: TDateTime;
begin
  Result := '';
  Partes := TStringList.Create;
  try
    Partes.StrictDelimiter := True;
    Partes.Delimiter := '/';
    Partes.DelimitedText := Trim(AFecha);
    if Partes.Count <> 3 then
      Exit;
    if not TryStrToInt(Trim(Partes[0]), Dia) or
       not TryStrToInt(Trim(Partes[1]), Mes) or
       not TryStrToInt(Trim(Partes[2]), Anio) then
      Exit;
    if Anio < 100 then
    begin
      if Anio >= 70 then
        Inc(Anio, 1900)
      else
        Inc(Anio, 2000);
    end;
    if not TryEncodeDate(Anio, Mes, Dia, Fecha) then
      Exit;
    Result := FormatDateTime('yyyy"-"mm"-"dd', Fecha);
  finally
    Partes.Free;
  end;
end;

function LimpiarNumero(const ATexto: string): string;
var
  I: Integer;
  C: Char;
  Constructor: TStringBuilder;
begin
  Constructor := TStringBuilder.Create;
  try
    for I := 1 to Length(ATexto) do
    begin
      C := ATexto[I];
      if CharInSet(C, ['0'..'9', ',', '.', '-']) then
        Constructor.Append(C);
    end;
    Result := Constructor.ToString;
  finally
    Constructor.Free;
  end;
end;

function TryNumero(const ATexto: string; out AValor: Double): Boolean;
var
  Texto: string;
  PosComa, PosPunto: Integer;
  Formato: TFormatSettings;
begin
  Texto := LimpiarNumero(ATexto);
  if Texto = '' then
    Exit(False);

  PosComa := LastDelimiter(',', Texto);
  PosPunto := LastDelimiter('.', Texto);
  if (PosComa > 0) and (PosPunto > 0) then
  begin
    if PosComa > PosPunto then
    begin
      Texto := StringReplace(Texto, '.', '', [rfReplaceAll]);
      Texto := StringReplace(Texto, ',', '.', [rfReplaceAll]);
    end
    else
      Texto := StringReplace(Texto, ',', '', [rfReplaceAll]);
  end
  else if PosComa > 0 then
    Texto := StringReplace(Texto, ',', '.', [rfReplaceAll]);

  Formato := TFormatSettings.Create;
  Formato.DecimalSeparator := '.';
  Formato.ThousandSeparator := ',';
  Result := TryStrToFloat(Texto, AValor, Formato);
end;

function Numero(const ATexto: string; ADefecto: Double = 0): Double;
begin
  if not TryNumero(ATexto, Result) then
    Result := ADefecto;
end;

function Entero(const ATexto: string; ADefecto: Integer = 0): Integer;
var
  Valor: Double;
begin
  if TryNumero(ATexto, Valor) then
    Result := Round(Valor)
  else
    Result := ADefecto;
end;

function PareceModelo(const ATexto: string): Boolean;
var
  Texto: string;
begin
  Texto := Trim(ATexto);
  Result := (Length(Texto) >= 4) and (Length(Texto) <= 20) and
    (Pos('-', Texto) > 1) and (Pos(' ', Texto) = 0) and
    not ContainsText(Texto, 'PRE-');
end;

function QuitarParentesis(const ATexto: string): string;
begin
  Result := Trim(ATexto);
  Result := StringReplace(Result, '(', '', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '', [rfReplaceAll]);
end;

function QuitarEtiquetaPrecio(const ATexto: string): string;
var
  PosPrice, PosPrecio, Corte: Integer;
begin
  Result := Trim(ATexto);
  PosPrice := PosText('PRICE WS', Result);
  PosPrecio := PosText('PRECIO WS', Result);
  Corte := 0;
  if PosPrice > 0 then
    Corte := PosPrice;
  if (PosPrecio > 0) and ((Corte = 0) or (PosPrecio < Corte)) then
    Corte := PosPrecio;
  if Corte > 0 then
    Result := Trim(Copy(Result, 1, Corte - 1));

  while (Result <> '') and CharInSet(Result[Length(Result)], [' ', '/', '-', '\']) do
    Delete(Result, Length(Result), 1);
  if EndsText(' WS', Result) then
    Delete(Result, Length(Result) - 2, 3);
  Result := Trim(Result);
end;

function ColorPorModelo(const AModelo: string): string;
begin
  if EndsText('-F23', AModelo) then
    Exit('OLIVE BROWN');
  if EndsText('-675', AModelo) then
    Exit('PLATINO');
  if EndsText('-001', AModelo) or EndsText('-D01', AModelo) then
    Exit('BLACK');
  Result := '';
end;

function BuscarColumnaCabecera(const ATabla: TTablaAzure; AFila: Integer;
  const ATerminos: array of string): Integer;
var
  C: Integer;
begin
  for C := 0 to ATabla.Columnas - 1 do
    if ContieneTodos(Celda(ATabla, AFila, C), ATerminos) then
      Exit(C);
  Result := -1;
end;

function EsTablaDetalle(const ATabla: TTablaAzure; out AFilaCabecera,
  AColModelo: Integer): Boolean;
var
  F, C: Integer;
begin
  for F := 0 to ATabla.Filas - 1 do
    for C := 0 to ATabla.Columnas - 1 do
      if ContieneTodos(Celda(ATabla, F, C), ['Style', 'Modelo']) then
      begin
        AFilaCabecera := F;
        AColModelo := C;
        Exit(True);
      end;
  AFilaCabecera := -1;
  AColModelo := -1;
  Result := False;
end;

procedure AnadirAdvertencia(AAdvertencias: TList<string>; const ATexto: string);
begin
  if AAdvertencias.IndexOf(ATexto) < 0 then
    AAdvertencias.Add(ATexto);
end;

procedure ExtraerDetalleTabla(const ATabla: TTablaAzure;
  ALineas: TObjectList<TLineaAlbion>; AAdvertencias: TList<string>);
var
  FilaCabecera, ColModelo, ColDescripcion, ColCantidad, ColPvp,
  ColImporte, PrimeraFilaDatos, Fila, FilaFin, SiguienteFila,
  C, F, FilaPrecio, SumaTallas: Integer;
  TallasPorColumna: TArray<string>;
  Linea: TLineaAlbion;
  Parte, DescripcionAcumulada, Talla: string;
  TallaCantidad: TTallaCantidad;
  Valor: Double;
begin
  if not EsTablaDetalle(ATabla, FilaCabecera, ColModelo) then
    Exit;

  ColDescripcion := BuscarColumnaCabecera(ATabla, FilaCabecera,
    ['Article', 'Descrip']);
  ColCantidad := BuscarColumnaCabecera(ATabla, FilaCabecera, ['QTY']);
  ColPvp := BuscarColumnaCabecera(ATabla, FilaCabecera, ['PVP']);
  ColImporte := BuscarColumnaCabecera(ATabla, FilaCabecera, ['Importe']);

  if (ColDescripcion < 0) or (ColCantidad < 0) or (ColPvp < 0) or
     (ColImporte < 0) then
    raise EAlbionPedidoParser.Create(
      'La tabla de detalle de Albion no contiene todas las cabeceras esperadas.');

  PrimeraFilaDatos := -1;
  for F := FilaCabecera + 1 to ATabla.Filas - 1 do
    if PareceModelo(Celda(ATabla, F, ColModelo)) then
    begin
      PrimeraFilaDatos := F;
      Break;
    end;
  if PrimeraFilaDatos < 0 then
    Exit;

  SetLength(TallasPorColumna, ATabla.Columnas);
  for C := ColDescripcion + 1 to ColCantidad - 1 do
  begin
    Talla := '';
    for F := FilaCabecera + 1 to PrimeraFilaDatos - 1 do
      if (Pos('(', Celda(ATabla, F, C)) > 0) and
         (Pos(')', Celda(ATabla, F, C)) > 0) then
        Talla := QuitarParentesis(Celda(ATabla, F, C));
    TallasPorColumna[C] := Talla;
  end;

  Fila := PrimeraFilaDatos;
  while Fila < ATabla.Filas do
  begin
    if not PareceModelo(Celda(ATabla, Fila, ColModelo)) then
    begin
      Inc(Fila);
      Continue;
    end;

    FilaFin := ATabla.Filas - 1;
    for SiguienteFila := Fila + 1 to ATabla.Filas - 1 do
      if PareceModelo(Celda(ATabla, SiguienteFila, ColModelo)) then
      begin
        FilaFin := SiguienteFila - 1;
        Break;
      end;

    Linea := TLineaAlbion.Create;
    try
      Linea.Modelo := Trim(Celda(ATabla, Fila, ColModelo));
      Linea.Color := ColorPorModelo(Linea.Modelo);
      Linea.Cantidad := Entero(Celda(ATabla, Fila, ColCantidad));
      Linea.Pvp := Numero(Celda(ATabla, Fila, ColPvp));
      Linea.Importe := Numero(Celda(ATabla, Fila, ColImporte));

      SumaTallas := 0;
      for C := ColDescripcion + 1 to ColCantidad - 1 do
      begin
        if TallasPorColumna[C] = '' then
          Continue;
        TallaCantidad.Cantidad := Entero(Celda(ATabla, Fila, C));
        if TallaCantidad.Cantidad <= 0 then
          Continue;
        TallaCantidad.Talla := TallasPorColumna[C];
        Linea.Tallas.Add(TallaCantidad);
        Inc(SumaTallas, TallaCantidad.Cantidad);
      end;

      DescripcionAcumulada := '';
      FilaPrecio := -1;
      for F := Fila to FilaFin do
      begin
        Parte := Celda(ATabla, F, ColDescripcion);
        if (PosText('PRICE WS', Parte) > 0) or
           (PosText('PRECIO WS', Parte) > 0) then
          FilaPrecio := F;
        Parte := QuitarEtiquetaPrecio(Parte);
        if Parte <> '' then
        begin
          if DescripcionAcumulada <> '' then
            DescripcionAcumulada := DescripcionAcumulada + ' ';
          DescripcionAcumulada := DescripcionAcumulada + Parte;
        end;
      end;
      Linea.Descripcion := NormalizarEspacios(DescripcionAcumulada);

      if FilaPrecio >= 0 then
        for C := ColDescripcion + 1 to ColCantidad - 1 do
          if TryNumero(Celda(ATabla, FilaPrecio, C), Valor) then
          begin
            Linea.PrecioUnitario := Valor;
            Break;
          end;

      if SumaTallas <> Linea.Cantidad then
        AnadirAdvertencia(AAdvertencias, Format(
          'El modelo %s suma %d unidades por talla, pero QTY indica %d.',
          [Linea.Modelo, SumaTallas, Linea.Cantidad]));

      if Abs(RoundTo(Linea.PrecioUnitario * Linea.Cantidad, -2) -
         Linea.Importe) > 0.02 then
        AnadirAdvertencia(AAdvertencias, Format(
          'El importe del modelo %s no coincide con cantidad por precio.',
          [Linea.Modelo]));

      ALineas.Add(Linea);
      Linea := nil;
    finally
      Linea.Free;
    end;

    Fila := FilaFin + 1;
  end;
end;

procedure AnadirCadenaONulo(AObjeto: TJSONObject; const ANombre,
  AValor: string);
begin
  if AValor = '' then
    AObjeto.AddPair(ANombre, TJSONNull.Create)
  else
    AObjeto.AddPair(ANombre, AValor);
end;

function CrearSalida(const AAnalisis: TJSONObject; const ATablas: TTablasAzure;
  ALineas: TObjectList<TLineaAlbion>; AAdvertencias: TList<string>): TJSONObject;
var
  TextoCompleto, Cif, Telefono, Direccion, Referencia, FechaPedidoRaw,
  FechaEntregaRaw, FechaTopeRaw, CantidadDocumentoTexto, ImporteDocumentoTexto: string;
  ProveedorJson, LineaJson, TallaJson, TotalesJson, ValidacionJson: TJSONObject;
  DetalleJson, TallasJson, AdvertenciasJson: TJSONArray;
  Linea: TLineaAlbion;
  Talla: TTallaCantidad;
  CantidadCalculada, CantidadDocumento: Integer;
  ImporteCalculado, ImporteDocumento: Double;
  I: Integer;
  Cuadra: Boolean;
begin
  TextoCompleto := CadenaJson(AAnalisis, 'content');
  Cif := ValorDerecha(ATablas, ['CIF']);
  if Cif = '' then
    Cif := ValorDespuesEtiquetaEnLinea(TextoCompleto, 'CIF:');
  Telefono := ValorDerecha(ATablas, ['Tel']);
  if Telefono = '' then
    Telefono := ValorDespuesEtiquetaEnLinea(TextoCompleto, 'Tel:');
  Direccion := ExtraerDireccionProveedor(TextoCompleto);

  FechaPedidoRaw := ValorDebajo(ATablas, ['Date', 'Fecha']);
  Referencia := ValorDebajo(ATablas, ['Order', 'Pedido']);
  FechaEntregaRaw := ValorDebajo(ATablas, ['Ship Date', 'entrega']);
  FechaTopeRaw := ValorDebajo(ATablas, ['Last ship date']);

  CantidadDocumentoTexto := ValorDebajo(ATablas, ['Quantity', 'Cantidad']);
  ImporteDocumentoTexto := ValorDebajo(ATablas, ['Total']);
  CantidadDocumento := Entero(CantidadDocumentoTexto);
  ImporteDocumento := Numero(ImporteDocumentoTexto);

  if not ContainsText(TextoCompleto, CProveedor) then
    AnadirAdvertencia(AAdvertencias,
      'No se encontro la razon social esperada de Albion en el OCR.');
  if FechaIso(FechaPedidoRaw) = '' then
    AnadirAdvertencia(AAdvertencias, 'No se pudo interpretar fecha_pedido.');
  if FechaIso(FechaEntregaRaw) = '' then
    AnadirAdvertencia(AAdvertencias,
      'No se pudo interpretar fecha_prevista_entrega.');
  if FechaIso(FechaTopeRaw) = '' then
    AnadirAdvertencia(AAdvertencias, 'No se pudo interpretar fecha_tope.');

  CantidadCalculada := 0;
  ImporteCalculado := 0;
  for Linea in ALineas do
  begin
    Inc(CantidadCalculada, Linea.Cantidad);
    ImporteCalculado := ImporteCalculado + Linea.Importe;
  end;
  ImporteCalculado := RoundTo(ImporteCalculado, -2);

  if CantidadCalculada <> CantidadDocumento then
    AnadirAdvertencia(AAdvertencias, Format(
      'La suma de cantidades (%d) no coincide con el total del documento (%d).',
      [CantidadCalculada, CantidadDocumento]));
  if Abs(ImporteCalculado - ImporteDocumento) > 0.02 then
    AnadirAdvertencia(AAdvertencias,
      'La suma de importes no coincide con el total del documento.');
  if ALineas.Count = 0 then
    AnadirAdvertencia(AAdvertencias, 'No se extrajo ninguna linea de detalle.');

  Result := TJSONObject.Create;
  try
    ProveedorJson := TJSONObject.Create;
    ProveedorJson.AddPair('razon_social', CProveedor);
    AnadirCadenaONulo(ProveedorJson, 'direccion', Direccion);
    AnadirCadenaONulo(ProveedorJson, 'cif', Cif);
    AnadirCadenaONulo(ProveedorJson, 'telefono', Telefono);
    Result.AddPair('proveedor', ProveedorJson);

    AnadirCadenaONulo(Result, 'referencia_doc', Referencia);
    AnadirCadenaONulo(Result, 'fecha_pedido', FechaIso(FechaPedidoRaw));
    AnadirCadenaONulo(Result, 'fecha_tope', FechaIso(FechaTopeRaw));
    AnadirCadenaONulo(Result, 'fecha_prevista_entrega',
      FechaIso(FechaEntregaRaw));

    DetalleJson := TJSONArray.Create;
    Result.AddPair('detalle', DetalleJson);
    for Linea in ALineas do
    begin
      LineaJson := TJSONObject.Create;
      LineaJson.AddPair('modelo', Linea.Modelo);
      AnadirCadenaONulo(LineaJson, 'descripcion', Linea.Descripcion);
      AnadirCadenaONulo(LineaJson, 'color', Linea.Color);

      TallasJson := TJSONArray.Create;
      LineaJson.AddPair('tallas', TallasJson);
      for Talla in Linea.Tallas do
      begin
        TallaJson := TJSONObject.Create;
        TallaJson.AddPair('talla', Talla.Talla);
        TallaJson.AddPair('cantidad', TJSONNumber.Create(Talla.Cantidad));
        TallasJson.AddElement(TallaJson);
      end;

      LineaJson.AddPair('cantidad', TJSONNumber.Create(Linea.Cantidad));
      LineaJson.AddPair('precio_unitario',
        TJSONNumber.Create(Linea.PrecioUnitario));
      LineaJson.AddPair('pvp', TJSONNumber.Create(Linea.Pvp));
      LineaJson.AddPair('importe', TJSONNumber.Create(Linea.Importe));
      LineaJson.AddPair('moneda', 'EUR');
      DetalleJson.AddElement(LineaJson);
    end;

    TotalesJson := TJSONObject.Create;
    TotalesJson.AddPair('cantidad', TJSONNumber.Create(CantidadDocumento));
    TotalesJson.AddPair('importe', TJSONNumber.Create(ImporteDocumento));
    TotalesJson.AddPair('moneda', 'EUR');
    Result.AddPair('totales', TotalesJson);

    Cuadra := (AAdvertencias.Count = 0);
    ValidacionJson := TJSONObject.Create;
    ValidacionJson.AddPair('cuadra', TJSONBool.Create(Cuadra));
    ValidacionJson.AddPair('cantidad_calculada',
      TJSONNumber.Create(CantidadCalculada));
    ValidacionJson.AddPair('importe_calculado',
      TJSONNumber.Create(ImporteCalculado));
    AdvertenciasJson := TJSONArray.Create;
    for I := 0 to AAdvertencias.Count - 1 do
      AdvertenciasJson.Add(AAdvertencias[I]);
    ValidacionJson.AddPair('advertencias', AdvertenciasJson);
    Result.AddPair('validacion', ValidacionJson);
  except
    Result.Free;
    raise;
  end;
end;

class function TAlbionPedidoParser.ConvertirArchivo(
  const ARutaJson: string): TJSONObject;
var
  Codificacion: TEncoding;
  Contenido: string;
begin
  if not TFile.Exists(ARutaJson) then
    raise EAlbionPedidoParser.CreateFmt('No existe el archivo: %s', [ARutaJson]);
  Codificacion := TUTF8Encoding.Create(False);
  try
    Contenido := TFile.ReadAllText(ARutaJson, Codificacion);
  finally
    Codificacion.Free;
  end;
  Result := ConvertirTexto(Contenido);
end;

class function TAlbionPedidoParser.ConvertirTexto(
  const AJson: string): TJSONObject;
var
  RaizValor: TJSONValue;
  Raiz, Analisis: TJSONObject;
  Tablas: TTablasAzure;
  Lineas: TObjectList<TLineaAlbion>;
  Advertencias: TList<string>;
  I: Integer;
begin
  RaizValor := TJSONObject.ParseJSONValue(AJson);
  if not (RaizValor is TJSONObject) then
  begin
    RaizValor.Free;
    raise EAlbionPedidoParser.Create('La entrada no contiene un objeto JSON.');
  end;

  Raiz := TJSONObject(RaizValor);
  try
    if not SameText(CadenaJson(Raiz, 'status'), 'succeeded') then
      raise EAlbionPedidoParser.Create(
        'El analisis de Azure no tiene estado succeeded.');
    Analisis := ObjetoJson(Raiz, 'analyzeResult');
    if Analisis = nil then
      raise EAlbionPedidoParser.Create('Falta analyzeResult en el JSON de Azure.');

    Tablas := LeerTablas(Analisis);
    Lineas := TObjectList<TLineaAlbion>.Create(True);
    Advertencias := TList<string>.Create;
    try
      for I := 0 to High(Tablas) do
        ExtraerDetalleTabla(Tablas[I], Lineas, Advertencias);
      Result := CrearSalida(Analisis, Tablas, Lineas, Advertencias);
    finally
      Advertencias.Free;
      Lineas.Free;
    end;
  finally
    Raiz.Free;
  end;
end;

end.

