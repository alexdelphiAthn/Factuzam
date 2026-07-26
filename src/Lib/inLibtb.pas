{******************************************************************************}
{                                                                              }
{  Módulo:       inLibtb                                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caja de herramientas general del programa.                                }
{    Cifrado AES, cálculo de DC bancario, NIF, helpers de cadenas y ficheros.  }
{******************************************************************************}
unit inLibtb;

interface

uses  SysUtils, Variants, DB, ADODB, ExtCtrls, DBCtrls, Controls, Grids,
      Classes, COMObj, ComCtrls, ExtActns, OleCtrls, Forms, inifiles, Uni,
      SQLBuilder4D, SQLBuilder4D.Parser, SQLBuilder4D.Parser.GaSQLParser,
      System.StrUtils, DCPrijndael, dcpbase64,DCPcrypt2, System.NetEncoding,
      inLibUser, Datasnap.Provider, Datasnap.DBClient, System.DateUtils,
      MidasLib,   Datasnap.Midas,   Soap.SOAPMidas, Datasnap.Win.MidasCon,
      Dialogs, vcl.consts, inLibMsg, inLibFacturas,
      inLibPerfilesUsuarioIntf;

type
  TUpdateTotalEvent = procedure(Sender: TObject;
                                NuevoTotal: Currency) of object;
  TStringArray = array of string;
  function EncriptAES(s:String):String;
  function EncriptAESPass(s:String; sPass:AnsiString):String;
  function DecriptAES(s:String):String;
  function DecriptAESPass(s:String; sPass:AnsiString):String;
  function EncryptData(Data: string; AKey:AnsiString; AIv: AnsiString): string;
  function DecryptData(Data: string; AKey: AnsiString; AIv: AnsiString): string;
  function SoloNumeros(S:String):String;
  function LetraNIF(ADNI: String): Char;
  function CalculaDC(Banco, Cuenta: string):integer;
  function DevDC(AsNcuenta:String):String;
  function TomarLetra(S: String):String;
  function SonNumeros(S:String):boolean;
  function NomEjecutable:String;
  function AnsiOccurs(const str: string; const substr: string): integer;
  function AnsiSplit(const str: string; const separator: string): TStringArray;
  function SoloLetraNIF(S:String):Char;
  procedure ComprobarNIF(AsNIF:String);
  function leCadINI (clave, cadena : string; defecto : string) : string;
  function leCadINIDir (clave, cadena : string;
                        defecto : string; sDir:string) : string;
  function FileSinExtension(AsFile: string):string;
  procedure esCadINI (clave, cadena, valor : string);
  procedure esCadINIDir (clave, cadena, valor, sDir : string);
  function CheckIBAN(Aiban: string): Boolean;
  procedure SetFilterSQL(var AqryConsulta: TUniSQL);
  procedure ConstruirConexion(conUni:TUniConnection; sUser,
                                                sPassword,
                                                sHostName,
                                                sPort,
                                                sDataBase:String);
  procedure ConstruirConexionConnect(conUni:TUniConnection; sUser,
                                                sPassword,
                                                sHostName,
                                                sPort,
                                                sDataBase:String);
  function SimbolosProhibidos(
    const s: String;
    const APerfilesUsuario: IPerfilesUsuario): Boolean;
  procedure BusqDataBase(sqlConsulta: TUniQuery;
                        sBusqueda:String;
                        var ConsultaO:string);
  procedure BusqDataBaseMD(AqryMaster, AqryDetail: TUniQuery;
                         sBusqueda: String;
                         var sSQLOrigMaster, sSQLOrigDetail: String;
                         const sNombreTablaDetalle: String;
                         const sCondicionJoin: String);
  function ObtenerCadenaFiltro(AQuery: TUniQuery; sBusqueda: String): String;
  function ExistePeriodoUnico( qryData:TUniQuery;
                               fFechaIni,
                               fFechaFin:TField
                               ): boolean;
  function HayCoincidencia(str1, str2: string): string;
  procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
                                   AunqryDestino: TDataSet;
                                   const NombreTabla: string);
  function ObtenerSiguienteContador(AConexion: TUniConnection;
                                    const ATipoDoc,
                                    AUsuario: string): string;
  function GetDefaultValue(AConexion: TUniConnection;
                                 const ATable,
                                 AField,
                                 AConditionField: string): string;
  procedure ActualizarLineaFacturaGen(
                                    AConexion: TUniConnection;
                                    cdsLineas: TDataSet;
                                    cdsCabecera: TDataSet;
                                    const NombreCampo: string;
                                    const NuevoValor: Variant;
                                    EventoUpdateTotal: TUpdateTotalEvent = nil
                                   );

  function ObtenerSerieDefecto(AConexion: TUniConnection;
                               const AEmpresa, ATipoDoc: string;
                               const AAlmacen: string = ''): string;
  function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
                                     const AEmpresa, ATipoDoc,
                                     AAlmacen: string): string;
  procedure CargarSeriesEmpresa(AConexion: TUniConnection;
                                const AEmpresa, ATipoDoc: string;
                                AItems: TStrings);
  function CheckOpenDatasets(AModule: TDataModule): Boolean;
  procedure CancelarDatasets(AModule: TDataModule);
  procedure GrabarDatasets(AModule: TDataModule);
  function ObtenerClavePrimaria(ADataSet: TDataSet): string;
  function ExtraerTablaDeSQL(const aSQL: string): string;
  function StrToKeyValues(const S: string; const FieldNames: string): Variant;
  function KeyValuesToStr(const V: Variant): string;

implementation

// Convierte el valor (sea simple o un array de varios campos) a un texto para
// guardarlo
function KeyValuesToStr(const V: Variant): string;
var
  i: Integer;
begin
  Result := '';
  if VarIsNull(V) or VarIsEmpty(V) then Exit;

  // Si es una clave compuesta (Array)
  if VarIsArray(V) then
  begin
    for i := VarArrayLowBound(V, 1) to VarArrayHighBound(V, 1) do
    begin
      if Result <> '' then
        Result := Result + '|'; // Usamos el "pipe" (|) como separador
      Result := Result + VarToStr(V[i]);
    end;
  end
  else // Si es una clave simple
    Result := VarToStr(V);
end;

// Convierte el texto guardado de vuelta al formato que necesita el Locate
// (Variante simple o Array)
function StrToKeyValues(const S: string; const FieldNames: string): Variant;
var
  slCampos, slValores: TStringList;
  i: Integer;
begin
  // Si no hay punto y coma, es clave simple
  if Pos(';', FieldNames) = 0 then
  begin
    Result := S;
    Exit;
  end;

  // Es clave compuesta, reconstruimos el array
  slCampos := TStringList.Create;
  slValores := TStringList.Create;
  try
    slCampos.Delimiter := ';';
    slCampos.StrictDelimiter := True;
    slCampos.DelimitedText := FieldNames;

    slValores.Delimiter := '|';
    slValores.StrictDelimiter := True;
    slValores.DelimitedText := S;

    // Creamos un array de variantes del tamaño exacto de los campos clave
    Result := VarArrayCreate([0, slCampos.Count - 1], varVariant);

    for i := 0 to slCampos.Count - 1 do
    begin
      if i < slValores.Count then
        Result[i] := slValores[i]
      else
        Result[i] := Null; // Por seguridad, si falta algún valor
    end;
  finally
    FreeAndNil(slCampos);
    FreeAndNil(slValores);
  end;
end;

function ExtraerTablaDeSQL(const aSQL: string): string;
var
  sUp: string;
  iNivel, i, iIni, iEnd: Integer;
  bEncontrado: Boolean;
  // True si en la posicion p arranca la palabra clave FROM con limites de
  // palabra a ambos lados (asi no se confunde con sufijos tipo DATEFROM).
  function HayFromEn(p: Integer): Boolean;
  begin
    Result := (p + 3 <= Length(sUp)) and (Copy(sUp, p, 4) = 'FROM');
    if Result and (p > 1) and
       not CharInSet(sUp[p - 1], [' ', #9, #10, #13, '(', ')', ',']) then
      Result := False;
    if Result and (p + 4 <= Length(sUp)) and
       not CharInSet(sUp[p + 4], [' ', #9, #10, #13, '(']) then
      Result := False;
  end;
begin
  Result := '';
  // Sin Trim: las posiciones se calculan sobre sUp y el Copy final lee de
  // aSQL, por lo que ambas cadenas deben compartir los mismos indices.
  sUp := UpperCase(aSQL);
  // Buscamos el primer FROM a nivel 0 de parentesis. Asi se ignoran las
  // subconsultas del SELECT (p.ej. un (SELECT COUNT(*) FROM otra_tabla ...)
  // que calcula una columna): su FROM no es el de la tabla principal y
  // devolvia una PK ajena, reventando el grid con "Key Field not found".
  iNivel := 0;
  i := 1;
  iIni := 0;
  bEncontrado := False;
  while (i <= Length(sUp)) and not bEncontrado do
  begin
    if sUp[i] = '(' then
      Inc(iNivel)
    else if (sUp[i] = ')') and (iNivel > 0) then
      Dec(iNivel)
    else if (iNivel = 0) and HayFromEn(i) then
    begin
      iIni := i + 4;
      bEncontrado := True;
    end;
    Inc(i);
  end;
  if bEncontrado then
  begin
    // Saltar el hueco entre FROM y el nombre de la tabla.
    while (iIni <= Length(sUp)) and
          CharInSet(sUp[iIni], [' ', #9, #10, #13]) do
      Inc(iIni);
    iEnd := iIni;
    while (iEnd <= Length(sUp)) and
          not CharInSet(sUp[iEnd], [' ', #13, #10, #9, '(', ',', ';']) do
      Inc(iEnd);
    Result := Trim(Copy(aSQL, iIni, iEnd - iIni));
    if (Length(Result) >= 2) and (Result[1] = '`') then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;
end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;
var
  i: Integer;
  sTabla: string;
  qry: TUniQuery;
begin
  Result := '';
  if not Assigned(ADataSet) or not ADataSet.Active then
    Exit;
  // 1. Intento nativo UniDAC: KeyFields asignado manualmente
  if ADataSet is TUniQuery then
  begin
    Result := TUniQuery(ADataSet).KeyFields;
    if Result <> '' then
      Exit;
  end;
  // 2. ProviderFlags: campos marcados como clave primaria
  for i := 0 to ADataSet.FieldCount - 1 do
  begin
    if pfInKey in ADataSet.Fields[i].ProviderFlags then
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + ADataSet.Fields[i].FieldName;
    end;
  end;
  if Result <> '' then
    Exit;
  // 3. Fallback: consultar information_schema por la PK de la tabla
  if (ADataSet is TUniQuery) and
     Assigned(TUniQuery(ADataSet).Connection) then
  begin
    // Extraer nombre de tabla del SQL (busca FROM xxx)
    sTabla := ExtraerTablaDeSQL(TUniQuery(ADataSet).SQL.Text);
    if sTabla = '' then
      Exit;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := TUniQuery(ADataSet).Connection;
      qry.SQL.Text :=
        'SELECT COLUMN_NAME ' +
        '  FROM information_schema.KEY_COLUMN_USAGE ' +
        ' WHERE TABLE_SCHEMA = database() ' +
        '   AND TABLE_NAME = :TAB ' +
        '   AND CONSTRAINT_NAME = ''PRIMARY'' ' +
        ' ORDER BY ORDINAL_POSITION';
      qry.ParamByName('TAB').AsString := sTabla;
      qry.Open;
      while not qry.Eof do
      begin
        if Result <> '' then
          Result := Result + ';';
        Result := Result + qry.FieldByName('COLUMN_NAME').AsString;
        qry.Next;
      end;
      qry.Close;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure GrabarDatasets(AModule: TDataModule);
var
  i: Integer;
  LDataSet: TDataSet;
begin
  if AModule = nil then Exit;
  for i := 0 to AModule.ComponentCount - 1 do
  begin
    if AModule.Components[i] is TDataSet then
    begin
      LDataSet := TDataSet(AModule.Components[i]);
      if LDataSet.Active and (LDataSet.State in [dsEdit, dsInsert]) then
      begin
        LDataSet.Post;
      end;
    end;
  end;
end;

procedure CancelarDatasets(AModule: TDataModule);
var
  i: Integer;
  LDataSet: TDataSet;
begin
  if AModule = nil then Exit;
  for i := 0 to AModule.ComponentCount - 1 do
  begin
    if AModule.Components[i] is TDataSet then
    begin
      LDataSet := TDataSet(AModule.Components[i]);
      if LDataSet.Active and (LDataSet.State in [dsEdit, dsInsert]) then
      begin
        LDataSet.Cancel;
      end;
    end;
  end;
end;

function CheckOpenDatasets(AModule: TDataModule): Boolean;
var
  i: Integer;
  LDataSet: TDataSet;
begin
  Result := False;
  if AModule = nil then Exit;
  for i := 0 to AModule.ComponentCount - 1 do
  begin
    if AModule.Components[i] is TDataSet then
    begin
      LDataSet := TDataSet(AModule.Components[i]);
      if LDataSet.Active and (LDataSet.State in [dsEdit, dsInsert]) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

procedure ActualizarLineaFacturaGen(AConexion: TUniConnection;
                                    cdsLineas: TDataSet;
                                    cdsCabecera: TDataSet;
                                    const NombreCampo: string;
                                    const NuevoValor: Variant;
                                    EventoUpdateTotal: TUpdateTotalEvent = nil);
var
  Calculador: TLinFac;
  Totales: TFacturaTotales;
  ValorCurrency: Currency;
  TotalBruto, Diferencia: Currency;
begin
  if not Assigned(cdsLineas) or not cdsLineas.Active then
    Exit;
  if not cdsLineas.CanModify then
    Exit;
  if not (cdsLineas.State in [dsEdit, dsInsert]) then
    cdsLineas.Edit;
  ValorCurrency := StrToCurrDef(VarToStr(NuevoValor), 0);
  Calculador := TLinFac.Create(cdsLineas, cdsCabecera, True);
  try
    if SameText(NombreCampo, 'PRECIO_SALIDA_FACLIN') then
      Calculador.PrecioSal := ValorCurrency
    else if SameText(NombreCampo, 'CANTIDAD_FACLIN') then
      Calculador.Cant := ValorCurrency
    else if SameText(NombreCampo, 'PORCENTAJE_DTO_FACLIN') then
      Calculador.PorDto := ValorCurrency
    else if SameText(NombreCampo, 'PRECIO_DTO_FACLIN') then
      Calculador.Dto := ValorCurrency
    else if SameText(NombreCampo,
                                 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN') then
      Calculador.PreSiva := ValorCurrency
    else if SameText(NombreCampo,
                                 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN') then
      Calculador.PreCiva := ValorCurrency
    else if SameText(NombreCampo, 'TIPO_IVA_ARTICULO_FACLIN') then
      Calculador.TipoIva := VarToStr(NuevoValor) // El Tipo IVA es string
    else if SameText(NombreCampo, 'TOTAL_FACLIN') then
    begin
      // El usuario teclea el total liquido de la linea: calculamos el
      // descuento UNITARIO necesario para alcanzarlo (de ahi la division
      // por la cantidad) y dejamos que el calculador propague %, precios
      // y totales.
      TotalBruto := Calculador.PrecioSal * Calculador.Cant;
      if (TotalBruto <> 0) and (Calculador.Cant <> 0) then
        Diferencia := (TotalBruto - ValorCurrency) / Calculador.Cant
      else
        Diferencia := 0;
      Calculador.Dto := Diferencia;
    end
    else if SameText(NombreCampo, 'TOTAL_FAC_SIVA_FACLIN') then
    begin
      // Mismo criterio que TOTAL_FACLIN: el descuento se aplica por unidad.
      TotalBruto := Calculador.PrecioSal * Calculador.Cant;
      if (TotalBruto <> 0) and (Calculador.Cant <> 0) then
        Diferencia := (TotalBruto - ValorCurrency) / Calculador.Cant
      else
        Diferencia := 0;
      Calculador.Dto := Diferencia;
    end;
    // Volcamos al dataset el resultado del calculo (%, descuento, precios
    // y totales) para que ProcesarFacturaCompleta parta de estos valores
    // y no vuelva a derivar el descuento desde el precio anterior.
    Calculador.CopyToDataSetLin;
  finally
    FreeAndNil(Calculador);
  end;
  Totales := TFacturaTotales.Create(AConexion, cdsCabecera, cdsLineas);
  try
    // Un fallo del calculo no puede quedar silenciado: la linea se
    // grabaria con totales obsoletos o a cero. Se aborta la edicion.
    if not Totales.ProcesarFacturaCompleta then
      raise Exception.Create('Error al recalcular totales de la ' +
                             'factura: ' + Totales.MensajeError);
    if Assigned(EventoUpdateTotal) then
      EventoUpdateTotal(nil, Totales.Totales.TotalLiquido);
  finally
    FreeAndNil(Totales);
  end;
end;

// Serie ligada en exclusiva a un almacen (CODIGO_ALM_EMPSER = almacen)
// para la empresa + tipo de documento, vigente por fechas. Devuelve ''
// si el almacen no tiene serie propia. Es la pieza que usa el flujo
// "un documento por almacen": cada documento toma la serie de SU almacen.
function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
                                   const AEmpresa, ATipoDoc,
                                   AAlmacen: string): string;
var
  q: TUniQuery;
begin
  Result := '';
  if (Trim(AEmpresa) <> '') and (Trim(ATipoDoc) <> '') and
     (Trim(AAlmacen) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT EMPSER FROM fza_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER   = :tip ' +
        '   AND CODIGO_ALM_EMPSER = :alm ' +
        '   AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
        '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
        ' LIMIT 1';
      q.ParamByName('emp').AsString := AEmpresa;
      q.ParamByName('tip').AsString := ATipoDoc;
      q.ParamByName('alm').AsString := AAlmacen;
      q.Open;
      if not q.IsEmpty then
        Result := q.FieldByName('EMPSER').AsString;
    finally
      FreeAndNil(q);
    end;
  end;
end;

// Serie por defecto de la empresa para un tipo de documento. Si llega
// AAlmacen, la prioridad es: 1) serie propia del almacen
// (CODIGO_ALM_EMPSER = almacen), 2) serie generica (sin almacen). Sin
// AAlmacen se mantiene el comportamiento historico: primera serie del
// tipo, este o no ligada a un almacen.
function ObtenerSerieDefecto(AConexion: TUniConnection;
                             const AEmpresa, ATipoDoc: string;
                             const AAlmacen: string = ''): string;
var
  q: TUniQuery;
  sFiltroAlm: string;
begin
  Result := '';
  if (Trim(AEmpresa) <> '') and (Trim(ATipoDoc) <> '') then
  begin
    if Trim(AAlmacen) <> '' then
      Result := ObtenerSeriePropiaAlmacen(AConexion, AEmpresa, ATipoDoc,
        AAlmacen);
    if Result = '' then
    begin
      // Con almacen informado, la serie generica no puede ser una
      // ligada a OTRO almacen: se exige CODIGO_ALM_EMPSER vacio.
      sFiltroAlm := '';
      if Trim(AAlmacen) <> '' then
        sFiltroAlm := '   AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ';
      q := TUniQuery.Create(nil);
      try
        q.Connection := AConexion;
        q.SQL.Text :=
          'SELECT EMPSER FROM fza_empresas_series ' +
          ' WHERE CODIGO_EMP_EMPSER = :emp ' +
          '   AND TIPO_DOC_EMPSER   = :tip ' +
          '   AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
          '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
          sFiltroAlm +
          ' LIMIT 1';
        q.ParamByName('emp').AsString := AEmpresa;
        q.ParamByName('tip').AsString := ATipoDoc;
        q.Open;
        if not q.IsEmpty then
          Result := q.FieldByName('EMPSER').AsString;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

// Rellena AItems con las series vigentes de la empresa para el tipo de
// documento (genericas y ligadas a almacen). Alimenta los combos de
// serie de los modales: el usuario ve todas y puede cambiar la
// propuesta que acompanya al almacen.
procedure CargarSeriesEmpresa(AConexion: TUniConnection;
                              const AEmpresa, ATipoDoc: string;
                              AItems: TStrings);
var
  q: TUniQuery;
begin
  AItems.Clear;
  if (Trim(AEmpresa) <> '') and (Trim(ATipoDoc) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConexion;
      q.SQL.Text :=
        'SELECT DISTINCT EMPSER FROM fza_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER   = :tip ' +
        '   AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
        '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
        ' ORDER BY EMPSER';
      q.ParamByName('emp').AsString := AEmpresa;
      q.ParamByName('tip').AsString := ATipoDoc;
      q.Open;
      while not q.Eof do
      begin
        AItems.Add(q.FieldByName('EMPSER').AsString);
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function GetDefaultValue(AConexion: TUniConnection;
  const ATable, AField, AConditionField: string): string;
var
  unqry: TUniQuery;
begin
  Result := ''; // Valor por defecto inicial
  unqry := TUniQuery.Create(nil);
  try
    unqry.Connection := AConexion;
    unqry.SQL.Text := Format('SELECT %s FROM %s WHERE %s = %s LIMIT 1',
                             [AField, ATable, AConditionField, QuotedStr('S')]);
    unqry.Open;
    if not unqry.Eof then
      Result := unqry.Fields[0].AsString;
  finally
    FreeAndNil(unqry);
  end;
end;

function ObtenerSiguienteContador(AConexion: TUniConnection;
                                  const ATipoDoc,
                                  AUsuario: string): string;
var
  SP: TUniStoredProc;
begin
  Result := '';
  SP := TUniStoredProc.Create(nil);
  try
    SP.Connection := AConexion;
    SP.StoredProcName := 'PRC_GET_NEXT_CONT';
    SP.Params.Clear;
    SP.Params.CreateParam(ftString, 'pTipoDoc', ptInput).AsString := ATipoDoc;
    SP.Params.CreateParam(ftString, 'pUSUARIO_MODIF', ptInput).AsString :=
      AUsuario;
    SP.Params.CreateParam(ftString, 'pcont', ptOutput);
    try
      SP.Execute;
      Result := SP.Params.ParamByName('pcont').AsString;
    except
      on E: Exception do
        ShowMessage('Error al generar contador automático: ' + E.Message);
    end;
  finally
    FreeAndNil(SP);
  end;
end;

procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
                                   AunqryDestino: TDataSet;
                                   const NombreTabla: string);
var
  qryDefaults: TUniQuery; // O TFDQuery, según uses
begin
  if ((AunqryDestino.State <> dsInsert) and
      (AunqryDestino.State <> dsEdit)) then
    AunqryDestino.Edit;
  qryDefaults := TUniQuery.Create(nil);
  try
    qryDefaults.Connection := AConexion;
    // Buscamos todos los valores configurados para esa tabla específica
    qryDefaults.SQL.Text := 'SELECT CAMPO_OBJETIVO_DEF_VD, ' +
                            '       VALOR_DEF_VD, ' +
                            '       TIPO_DATO_DEF_VD ' +
                            '  FROM fza_valores_defecto ' +
                            ' WHERE TABLA_OBJETIVO_DEF_VD = ' +
                                                         QuotedStr(NombreTabla);
    qryDefaults.Open;
    while not qryDefaults.Eof do
    begin
      var oField := AunqryDestino.FindField(
                        qryDefaults.FieldByName(
                          'CAMPO_OBJETIVO_DEF_VD').AsString);
      if Assigned(oField) then
      begin
        var sValor := qryDefaults.FieldByName('VALOR_DEF_VD').AsString;
        var sTipo  := qryDefaults.FieldByName('TIPO_DATO_DEF_VD').AsString;
        if sTipo = 'INTEGER' then
          oField.AsInteger := StrToIntDef(sValor, 0)
        else if sTipo = 'FLOAT' then
          oField.AsFloat := StrToFloatDef(sValor, 0)
        else
          oField.AsString := sValor;
      end;
      qryDefaults.Next;
    end;
  finally
    FreeAndNil(qryDefaults);
  end;
end;

function HayCoincidencia(str1, str2: string): String;
var
  i, j: integer;
  sResul:string;
  coincidencia: boolean;
begin
  coincidencia := false;
  sResul := '';
  i := 1;
  while (i <= Length(str1)) and not coincidencia do
  begin
    j := 1;
    while (j <= Length(str2)) and not coincidencia do
    begin
      if str1[i] = str2[j] then
      begin
        coincidencia := true;
        sResul := str1[i];
      end;
      Inc(j);
    end;
    Inc(i);
  end;
  Result := sResul;
end;

function SimbolosProhibidos(
  const s: String;
  const APerfilesUsuario: IPerfilesUsuario): Boolean;
const
  SIMBOLOS_PREDETERMINADOS = 'ºª,="'':;·|.,¨{}~^][()/+€%*';
var
  sSimbolos:string;
  sError:string;
begin
  sSimbolos := SIMBOLOS_PREDETERMINADOS;
  if Assigned(APerfilesUsuario) then
    sSimbolos := APerfilesUsuario.ObtenerValorPerfil(
      'inLibtb',
      'oSimbolosProhibidos',
      SIMBOLOS_PREDETERMINADOS);
  sError := HayCoincidencia(s, sSimbolos);
  if sError <> '' then
    Result := True
  else
    Result := False;
end;

procedure ConstruirConexionConnect(conUni:TUniConnection;
                                   sUser,
                                   sPassword,
                                   sHostName,
                                   sPort,
                                   sDataBase:String);
begin
  with Conuni do
  begin
    sPassword := sPassword;
    ConnectString := 'Provider Name=MySQL;User ID=' + sUser + ';Password=' +
                     sPassword + ';Data Source=' + sHostName+
                     ';Database=' + sDataBase+ ';Login Prompt=False';
    Server := sHostName;
    Database := sDatabase;
    Username := sUser;
    Password := sPassword;
    Port := StrToIntDef(sPort, 3306);
    SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    if (Connected = False) then
    begin
      try
        Connect;
      except
        on E: Exception do
        begin
          ShowMessage(SConnFailBBDD + E.ClassName + ' Mensaje: ' + E.Message);
          raise;
          Exit;
        end;
      end;
    end;
  end;
end;

procedure ConstruirConexion(conUni:TUniConnection; sUser,
                                                   sPassword,
                                                   sHostName,
                                                   sPort,
                                                   sDataBase:String);
begin
  with Conuni do
  begin
    sPassword := sPassword;
    ConnectString := 'Provider Name=MySQL;User ID=' + sUser + ';Password=' +
                     sPassword + ';Data Source=' + sHostName+
                     ';Database=' + sDataBase+ ';Login Prompt=False';
    Server := sHostName;
    Database := sDatabase;
    Username := sUser;
    Password := sPassword;
    Port := StrToIntDef(sPort, 3306);
    SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
    SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
    SpecificOptions.Values['MySQL.Protocol'] := 'mpDefault';
    Pooling := True;
    PoolingOptions.ConnectionLifetime := 0;
    PoolingOptions.Validate := True;
    PoolingOptions.MinPoolSize := 3;
    PoolingOptions.MaxPoolSize := 20;
    SpecificOptions.Values['MySQL.Interactive'] := 'True';
    SpecificOptions.Values['ConnectionTimeout'] := '5';
    Options.LocalFailover := True;
    // Modo desconectado en la conexión principal, igual que las clonadas:
    // libera la conexión física entre operaciones y la reabre al vuelo, así
    // una conexión muerta del pool no propaga errores (antes iba en False).
    Options.DisconnectedMode := True;
    // SpecificOptions.Values['MySQL.Compress'] := 'True';
  end;
end;

function DecryptData(Data: string; AKey: AnsiString; AIv: AnsiString): string;
    function Base64DecodeBytes(Input: TBytes): TBytes;
    var
      ilen, rlen: integer;
    begin
      ilen := Length(Input);
      SetLength(result, (ilen div 4) * 3);
      rlen := Base64Decode(@Input[0], @result[0], ilen);
      SetLength(result, rlen);
    end;
var
  key, iv, src, dest: TBytes;
  cipher: TDCP_rijndael;
  slen, pad: integer;
begin
  try
    // Validar la longitud de los datos de entrada
    if Length(Data) = 0 then
      raise Exception.Create('Datos de entrada vacíos');
    key := TEncoding.ASCII.GetBytes(String(AKey));
    iv := TEncoding.ASCII.GetBytes(String(AIv));
    src := Base64DecodeBytes(TEncoding.UTF8.GetBytes(Data));
    //  Validar la longitud de los datos de entrada
    //  después de la decodificación Base64
    if Length(src) = 0 then
      raise Exception.Create('Error al decodificar Base64');
    cipher := TDCP_rijndael.Create(nil);
    try
      cipher.CipherMode := cmCBC;
      slen := Length(src);
  //    if slen mod cipher.BlockSize <> 0 then
  //      raise Exception.Create('Longitud de datos no válida');
      SetLength(dest, slen);
      cipher.Init(key[0], 256, @iv[0]); // DCP uses key size in BITS not BYTES
      cipher.Decrypt(src[0], dest[0], slen);
      // Validar la longitud de los datos después de la desencriptación
      if Length(dest) = 0 then
        raise Exception.Create('Error durante la desencriptación');
      pad := dest[slen - 1];
      SetLength(dest, slen - pad);
      Result := TEncoding.UTF8.GetString(dest);
    finally
      if (cipher <> nil) then
        FreeAndNil(cipher);
    end;
    except
  // Manejar cualquier excepción aquí
    on E: Exception do
      Exit;
  end;
end;

function EncryptData(Data: string; AKey: AnsiString; AIv: AnsiString): string;
    function Base64EncodeBytes(Input: TBytes): TBytes;
    var
      ilen: integer;
    begin
      ilen := Length(Input);
      SetLength(result, ((ilen + 2) div 3) * 4);
      Base64Encode(@Input[0], @result[0], ilen);
    end;
var
  cipher: TDCP_rijndael;
  key, iv, src, dest, b64: TBytes;
  index, slen, bsize, pad: integer;
begin
  key := TEncoding.ASCII.GetBytes(String(AKey));
  iv := TEncoding.ASCII.GetBytes(String(AIv));
  src := TEncoding.UTF8.GetBytes(Data);
  cipher := TDCP_rijndael.Create(nil);
  try
    cipher.CipherMode := cmCBC;
    slen := Length(src);
    bsize := (cipher.BlockSize div 8);
    pad := bsize - (slen mod bsize);
    Inc(slen, pad);
    SetLength(src, slen);
    for index := pad downto 1 do
    begin
      src[slen - index] := pad;
    end;
    SetLength(dest, slen);
    cipher.Init(key[0], 256, @iv[0]); // DCP uses key size in BITS not BYTES
    cipher.Encrypt(src[0], dest[0], slen);
    b64 := Base64EncodeBytes(dest);
    result := TEncoding.Default.GetString(b64);
  finally
    FreeAndNil(cipher);
  end;
end;

function EncriptAESPass(s:String; sPass:AnsiString):String;
var
   Adata: String;
   AKey, IV: AnsiString;
begin
  AKey := 'Key1234567890-1234567890-1234567' + sPass;
  IV := '12345678901234561234567890123456';
  Adata := EncryptData(s,akey,iv);
  Result := Adata;
end;

function EncriptAES(s:String):String;
var
   Adata:String;
   AKey, IV: AnsiString;
begin
  AKey := 'Key1234567890-1234567890-1234567';
  IV := '12345678901234561234567890123456';
  Adata := EncryptData(s,akey,iv);
  Result := Adata;
end;

function DecriptAESPass(s:String; sPass:AnsiString):String;
var
  Adata: String;
  AKey, IV : AnsiString;
begin
  AKey := ('Key1234567890-1234567890-1234567'+ sPass);
  IV := ('12345678901234561234567890123456');
  adata := decryptdata(s, akey, iv);
  Result := (Adata);
end;

function DecriptAES(s:String):String;
var
  Adata : String;
  AKey, IV : AnsiString;
begin
  AKey := ('Key1234567890-1234567890-1234567');
  IV := ('12345678901234561234567890123456');
  adata := decryptdata(s, akey, iv);
  Result := (Adata);
end;

procedure SetFilterSQL(var AqryConsulta: TUniSQL);
var
 sSQL:string;
begin
  sSQL := AqryConsulta.SQL.Text;
end;

function ObtenerCadenaFiltro(AQuery: TUniQuery; sBusqueda: String): String;
var
  i: Integer;
  sLike: string;
  // Variables para lógica de fecha/hora si la deseas conservar
//  bModoFecha: Boolean;
  sTextoBuscar: String;
begin
  Result := '';
  if sBusqueda = '' then Exit;
  // --- Lógica de limpieza (Fechas/Horas) que definimos antes ---
  sTextoBuscar := sBusqueda;
  // Aquí puedes poner tu IF de "//" o "::" si quieres limpiar sTextoBuscar
  // ...
  sLike := '';
  // Aseguramos que la query tenga info de campos (por si estaba cerrada)
  if not AQuery.Active then AQuery.FieldDefs.Update;
  for i := 0 to AQuery.FieldCount - 1 do
  begin
    if AQuery.Fields[i].DataType in [ftSmallint, ftInteger, ftWord, ftCurrency,
       ftBCD, ftLargeint, ftFMTBcd, ftLongWord, ftShortint, ftString,
       ftWideString, ftMemo, ftFmtMemo, ftWideMemo] then
    begin
       // Usamos FieldName. Si tu SQL tiene Joins y alias,
       //asegúrate que FieldName lo refleje
       // o pásale el alias a esta función.
       sLike := sLike + AQuery.Fields[i].FieldName + ' LIKE ' +
                QuotedStr('%' + sTextoBuscar + '%') + ' OR ';
    end;
  end;
  if sLike <> '' then
  begin
    // Quitamos el último " OR "
    sLike := LeftStr(sLike, Length(sLike) - 4);
    // Devolvemos entre paréntesis para proteger la lógica
    Result := '(' + sLike + ')';
  end;
end;

procedure BusqDataBaseMD(AqryMaster, AqryDetail: TUniQuery;
                         sBusqueda: String;
                         var sSQLOrigMaster, sSQLOrigDetail: String;
                         const sNombreTablaDetalle: String; // Ej: 'FACTURAS'
                         // Ej: 'FACTURAS.IDCLIENTE = CLIENTES.ID'
                         const sCondicionJoin: String);
var
  vParserMaster, vParserDetail: ISQLParserSelect;
  sFiltroMaster, sFiltroDetail: String;
  sCondicionFinalMaster: String;
  sCondicionExists: String;
begin
  // 1. Guardar/Restaurar SQL Original
  if sSQLOrigMaster = '' then sSQLOrigMaster := AqryMaster.SQL.Text;
  if sSQLOrigDetail = '' then sSQLOrigDetail := AqryDetail.SQL.Text;
  // Restauramos siempre antes de procesar para no acumular filtros
  AqryMaster.SQL.Text := sSQLOrigMaster;
  AqryDetail.SQL.Text := sSQLOrigDetail;
  if sBusqueda = '' then
  begin
    AqryMaster.Open;
    AqryDetail.Open;
    Exit;
  end;
  // 2. Obtener las cadenas de filtro (el texto LIKE ... OR ...)
  // Nota: Asegúrate que las queries estén abiertas o tengan FieldDefs
  // actualizados
  if not AqryMaster.Active then AqryMaster.Open;
  if not AqryDetail.Active then AqryDetail.Open;
  sFiltroMaster := ObtenerCadenaFiltro(AqryMaster, sBusqueda);
  sFiltroDetail := ObtenerCadenaFiltro(AqryDetail, sBusqueda);
  // 3. Configurar Parsers
  vParserMaster := TGaSQLParserFactory.Select(AqryMaster.SQL.Text);
  vParserDetail := TGaSQLParserFactory.Select(AqryDetail.SQL.Text);
  // ---------------------------------------------------------
  // A. APLICAR AL DETALLE (Solo sus campos)
  // ---------------------------------------------------------
  if sFiltroDetail <> '' then
  begin
    // Añadimos con AND al resto de condiciones que tenga el detalle
    vParserDetail.AddWhere(sFiltroDetail, pcAnd);
    AqryDetail.SQL.Text := vParserDetail.ToString;
  end;
  // ---------------------------------------------------------
  // B. APLICAR AL MAESTRO (Sus campos OR Exists Detalle)
  // ---------------------------------------------------------
  // Construimos el bloque EXISTS a mano
  sCondicionExists := '';
  if sFiltroDetail <> '' then
  begin
    sCondicionExists := Format('EXISTS (SELECT 1 FROM %s WHERE %s AND %s)',
                        [sNombreTablaDetalle, sCondicionJoin, sFiltroDetail]);
  end;
  // Combinamos: (FiltroMaestro) OR (FiltroExists)
  sCondicionFinalMaster := '';
  if (sFiltroMaster <> '') and (sCondicionExists <> '') then
    sCondicionFinalMaster :=
      '(' + sFiltroMaster + ' OR ' + sCondicionExists + ')'
  else if sFiltroMaster <> '' then
    sCondicionFinalMaster := sFiltroMaster
  else if sCondicionExists <> '' then
    sCondicionFinalMaster := sCondicionExists;
  if sCondicionFinalMaster <> '' then
  begin
    // Inyectamos al parser del maestro. El parser se encarga de WHERE/ORDER BY
    vParserMaster.AddWhere(sCondicionFinalMaster, pcAnd);
    AqryMaster.SQL.Text := vParserMaster.ToString;
  end;
  // 4. Reabrir con los nuevos SQLs
  AqryMaster.Open;
  AqryDetail.Open;
  // Liberar interfaces (aunque en Delphi moderno se liberan solas, es bueno
  // ponerlas a nil)
  vParserMaster := nil;
  vParserDetail := nil;
end;

procedure BusqDataBase(sqlConsulta: TUniQuery;
                       sBusqueda:String;
                       var ConsultaO:string);
var
  index:integer;
  vSQLParserSelect: ISQLParserSelect;
  sLike:string;
  sConsulta:string;
begin
  sConsulta :=  sqlConsulta.SQL.Text;
  if ( ConsultaO = '' ) then
    ConsultaO := sConsulta;
  if ( ConsultaO <> sConsulta ) then
  begin
    sConsulta := ConsultaO; //reseteo la consulta porque ha habido otras búsq.
    sqlConsulta.SQL.text := ConsultaO;
  end;
  if sBusqueda <> '' then
  begin
    vSQLParserSelect :=  TGaSQLParserFactory.Select(sConsulta);
    vSQLParserSelect.AddWhere('(1=1)', pcAnd);
    if sqlConsulta.Active = False then
      sqlConsulta.Active := True;
    for index := 0 to ( sqlConsulta.FieldCount - 1 ) do
    begin
      if ( (sqlConsulta.Fields[index].DataType in   [ftSmallint,
                                                      ftInteger,
                                                      ftWord,
                                                      ftCurrency,
                                                      ftBCD,
                                                      ftLargeint,
                                                      ftFMTBcd,
                                                      ftLongWord,
                                                      ftShortint,
                                                      ftString,
                                                      ftWideString,
                                                      ftMemo,
                                                      ftFmtMemo,
                                                      ftWideMemo] ) ) then
      begin
        sLike := sLike + sqlConsulta.Fields[index].FieldName + ' LIKE ' +
                 QuotedStr('%' + sBusqueda + '%') + ' Or ';
      end;
    end;
    sLike := LeftStr(sLike, Length(sLike) - 4 );
    vSQLParserSelect.AddWhere(sLike, pcAnd);
    sqlConsulta.SQL.text := vSQLParserSelect.ToString;
    vSQLParserSelect := nil;
  end;
  sqlConsulta.Open;
end;

function ParametroIniAplicacion: string;
begin
  Result := Trim(ParamStr(1));
  if (Result <> '') and CharInSet(Result[1], ['/', '-']) then
    Result := '';
end;

procedure esCadINI (clave, cadena, valor : string);
var
   sIniFile,
   sParametroIni:string;
begin
  sParametroIni := ParametroIniAplicacion;
  if (SameText(sParametroIni, '')) then
    sIniFile := ExtractFilePath(ParamStr(0))
      + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := ExtractFilePath(ParamStr(0)) + sParametroIni;
  with tinifile.create (sIniFile) do
  try
    writeString (clave, cadena, valor);
  finally
    free;
  end;
end;

procedure esCadINIDir (clave, cadena, valor, sDir : string);
var
   sIniFile,
   sParametroIni:string;
begin
  sParametroIni := ParametroIniAplicacion;
  if SameText(sParametroIni, '') then
    sIniFile := sDir + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := sDir + sParametroIni;
  with tinifile.create (sIniFile) do
  try
    writeString (clave, cadena, valor);
  finally
    free;
  end;
end;

function FileSinExtension(AsFile: string):string;
begin
  Result := ExtractFilePath(AsFile) + copy(ExtractFileName(AsFile), 1,
                        pos(ExtractFileExt(AsFile), ExtractFileName(AsFile)) - 1);
end;

function leCadINI (clave, cadena : string; defecto : string) : string;
var
  sIniFile,
  sParametroIni:string;
begin
  sParametroIni := ParametroIniAplicacion;
  if sParametroIni = '' then
    sIniFile := ExtractFilePath(ParamStr(0)) +
                         FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := ExtractFilePath(ParamStr(0)) + sParametroIni;
  with tinifile.create (sIniFile) do
  try
    result := readString (clave, cadena, defecto);
    if result = defecto then
      esCadINI(clave, cadena, defecto);
  finally
    free;
  end;
end;

function leCadINIDir (clave, cadena : string;
                      defecto : string;
                      sDir:string) : string;
var
  sIniFile,
  sParametroIni:string;
begin
  sParametroIni := ParametroIniAplicacion;
  if sParametroIni = '' then
    sIniFile := sDir + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := sDir + sParametroIni;
  with tinifile.create (sIniFile) do
  try
    result := readString (clave, cadena, defecto);
    if result = defecto then
      esCadINIDir(clave, cadena, defecto, sDir);
  finally
    free;
  end;
end;

function GetAppFolder:String;
begin
 result:= ExtractFilePath(Application.EXEName);
end;

procedure CrearFichBBDD(sDataSourc:String);
var
    ctCatalog :  Variant;
begin
  //if not(DirectoryExists(GetBBDDFolder) ) then
    //CrearBBDD
  ctCatalog := CreateOleObject('ADOX.Catalog');

  try
    ctCatalog.Create(sDataSourc);
  finally
  end;
end;

function LetraNIF(ADNI: String): Char;
begin
  Result := Copy('TRWAGMYFPDXBNJZSQVHLCKET', StrToInt(ADNI) mod 23 + 1, 1)[1];
end;

//Banco es numero de banco + sucursal 8 digitos y cuenta son 10
function CalculaDC(Banco, Cuenta: string):integer;
const
  Pesos: array[0..9] of integer=(6,3,7,9,10,5,8,4,2,1);
var
  n      : byte;
  iTemp  : integer;
begin
  iTemp:=0;
  for n := 0 to 7 do
     iTemp := iTemp + StrToInt(Copy(Banco, 8 - n, 1)) * Pesos[n];
  Result:=11 - iTemp Mod 11;
  if (Result > 9) then Result:=1-Result mod 10;
  iTemp:=0;
  For n := 0 to 9 do
     iTemp := iTemp + StrToInt(Copy(Cuenta, 10 - n, 1)) * Pesos[n];
  iTemp:=11 - iTemp mod 11;
  if (iTemp > 9) then iTemp:=1-iTemp mod 10;
  Result:=Result*10+iTemp;
end;

function DevDC(AsNcuenta:String):String;
var
  sBanco, sNumero:String;
begin
  if ((SonNumeros(AsNcuenta)) and (Length(AsNcuenta) = 20)) then
  begin
    sBanco:=Copy(AsNcuenta, 1, 8);
    sNumero := Copy(AsNcuenta, 11, 20);
    Result  := IntToStr(CalculaDC(sBanco, sNumero));
  end
  else
    Result := 'Número de Cuenta Inválido';
end;

function TomarLetra(S: String):String;
var
  SResul : String;
begin
  if ( (Length(S) = 8) and (SonNumeros(S)) ) then
    sResul := S
  else
  if (Length(S) >= 8) then
  begin
      sResul := SoloNumeros(S)
  end
  else
    sResul := '?';

  if (sResul <> '?') then
    Result := LetraNIF(sResul)
  else
    Result := ' NIF No Válido';
end;

function SoloLetraNIF(S:String):Char;
var
  L:String;
  i:Integer;
  bfound :boolean;
begin
  bfound := false;
  L := 'TRWAGMYFPDXBNJZSQVHLCKET';

  if Length(S) = 9 then
    for i := 1 to Length(L) do
    begin
      if (L[i] = S[9]) then
      begin
        bfound := true;
      end;
    end;

  if bfound then
    Result := S[9]
  else
    Result := #0;
end;

function SoloNumeros(S:String):String;
var
  i,j: Integer;
  N: String;
begin
  j := 1;
  N := StringOfChar('0', 8);
  for i := 1 to Length(S) do
    if ( (S[i] >= '0') and
     (S[i] <= '9') ) then
    begin
      N[j] := S[i];
      j := j + 1;
    end;
  Result := N;
end;

function SonNumeros(S:String):boolean;
var
  i : Integer;
  b : boolean;
begin
  b := True;
  for i := 1 to Length(S) do
    if ( (S[i]<'0') or (S[i]>'9') ) then
      b := False;
  Result := b;
end;

procedure ComprobarNIF(AsNIF:String);
begin
  //si el primer digito no es un número, es un CIF
  if (AsNIF <> '') then
    if ( (AsNIF[1] >= '0') and (AsNIF[1] <= '9') ) then
      if ( SoloLetraNIF( AsNIF ) <> TomarLetra( AsNIF ) ) then
        Raise Exception.Create('Letra DNI Incorrecta. Correcta ' + TomarLetra(
          AsNIF) );
end;

function CheckIBAN(Aiban: string): Boolean;

    function CalculateDigits(Aiban: string): Integer;
      function ChangeAlpha(input: string): string;
        // A -> 10, B -> 11, C -> 12 ...
      var
        a: Char;
      begin
        Result := input;
        for a := 'A' to 'Z' do
        begin
          Result := StringReplace(Result,
                                  a,
                                  IntToStr(Ord(a) - 55),
                                  [rfReplaceAll]);
        end;
      end;
    var
      v, l: Integer;
      alpha: string;
      number: Longint;
      rest: Integer;
    begin
      Aiban := UpperCase(Aiban);
      if Pos('IBAN', Aiban) > 0 then
        Delete(Aiban, Pos('IBAN', Aiban), 4);
      Aiban := Aiban + Copy(Aiban, 1, 4);
      Delete(Aiban, 1, 4);
      Aiban := ChangeAlpha(Aiban);
      v := 1;
      l := 9;
      rest := 0;
      alpha := '';
      try
        while v <= Length(Aiban) do
        begin
          if l > Length(Aiban) then
            l := Length(Aiban);
          alpha := alpha + Copy(Aiban, v, l);
          number := StrToInt(alpha);
          rest := number mod 97;
          v := v + l;
          alpha := IntToStr(rest);
          l := 9 - Length(alpha);
        end;
      except
        rest := 0;
      end;
      Result := rest;
    end;
begin
  Aiban := StringReplace(Aiban, ' ', '', [rfReplaceAll]);
  if CalculateDigits(Aiban) = 1 then
    Result := True
  else
    Result := False;
end;

function NomEjecutable:String;
begin
  //Result:= Copy( sName, 3, 255 );
end;

function AnsiSplit(const str: string;
                 const separator: string): TStringArray;
// Devuelve un arreglo con las partes de "str" separadas por
// "separator"
// Versión ANSI
var
 i, n: integer;
 p, q, s: PChar;
begin
 SetLength(Result, AnsiOccurs(str, separator)+1);
 p := PChar(str);
 s := PChar(separator);
 n := Length(separator);
 i := 0;
 repeat
   q := AnsiStrPos(p, s);
   if q = nil then q := AnsiStrScan(p, #0);
   SetString(Result[i], p, q - p);
   p := q + n;
   inc(i);
 until q^ = #0;
end;

function AnsiOccurs(const str: string; const substr: string): integer;
// Devuelve la cantidad de veces que una subcadena está en una cadena
// Versión ANSI
var
 p, q: PChar;
 n: integer;
begin
  Result := 0;
  n := Length(substr);
  if n = 0 then exit;
  q := PChar(Pointer(substr));
  p := PChar(Pointer(str));
  while p <> nil do begin
    p := AnsiStrPos(p, q);
    if p <> nil then begin
      inc(Result);
      inc(p, n);
    end;
  end;
end;

function ExistePeriodoUnico(qryData:TUniQuery;
                            fFechaIni,
                            fFechaFin:TField): boolean;
var
 Dsp: TDataSetProvider;
 cli: TClientDataset;
 bFechaOrd, bFechaFinNul, bFechaIniNul:Boolean;
 iCom,iCom2 : Integer;
 dtFechaIni, dtFechaFin:TDateTime;
 sFechaIni, sFechaFin : String;
begin
  // cli/Dsp SIN inicializar provocaban lecturas de basura de pila en los
  // Assigned() de abajo cuando la rama que los crea no se ejecutaba.
  cli := nil;
  Dsp := nil;
  sFechaIni := fFechaIni.FieldName;
  sFechaFin := fFechaFin.FieldName;
  bFechaOrd := True;
  bFechaFinNul := fFechaFin.Isnull;
  bFechaIniNul := fFechaIni.Isnull;
  dtFechaIni := fFechaIni.AsDateTime;
  dtFechaFin := fFechaFin.AsDateTime;
  if ((qryData.RecordCount) > 1) then
  begin
    if ( (not(bFechaFinNul)) and
         (CompareDate(dtFechaIni, dtFechaFin) > 0)
       ) then
    begin
      bFechaOrd := False;
    end;
    if bFechaIniNul and bFechaOrd then
    begin
      bFechaOrd := False;
    end;
    try
      if ((bFechaOrd)) then
      begin
        cli := TClientDataSet.Create(nil);
        Dsp := TDataSetProvider.Create(cli);
        Dsp.DataSet := qryData;
        cli.SetProvider(Dsp);
        cli.Open;
        cli.First;
      end;
      while ( (Assigned(cli)) and (not(cli.Eof)) and ((bFechaOrd))) do
      begin
        if (bFechaFinNul) then
        begin
          if (cli.FieldByName(sFechaFin).isnull) then
            bFechaOrd := False;
          // FECHA_HASTA tiene que ser menor que dFechaFin, sino dar error
          // Si hay dos fechas_fin null ha de dar error.
          if (bFechaOrd) then
          begin
            iCom := CompareDate(cli.FieldByName(sFechaFin).AsDateTime,
                                dtFechaIni);
            if ((iCom > 0)) then
              bFechaOrd := False;
          end;
        end;
          {CompareDate compares the date parts of two timestamps A and B
          and returns the following results:
          < 0
          if the day part of A is earlier than the day part of B.
          0
          if A and B are the on same day (times may differ) .
          > 0
          if the day part of A is later than the day part of B.}
        if ((bFechaFinNul = False) and (bFechaOrd = True)) then
        begin
          iCom := CompareDate(cli.FieldByName(sFechaIni).AsDateTime,
                              dtFechaFin);
          iCom2 := CompareDate(cli.FieldByName(sFechaFin).AsDateTime,
                               dtFechaIni);
          if ((iCom < 0) and (iCom2 > 0)) then
            bFechaOrd := False;
        end;
        cli.Next;
      end;
    finally
      if assigned(cli) then
      begin
        cli.Close;
        // Dsp tiene a cli como Owner: se libera con el.
        FreeAndNil(cli);
      end;
    end;
    Result := bFechaOrd;
  end
  else
    Result := true;
end;

end.
