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

uses
      DB, Classes, Uni,
      inLibPerfilesUsuarioIntf, inLibCadenas;

type
  TUpdateTotalEvent = procedure(Sender: TObject;
                                NuevoTotal: Currency) of object;
  TStringArray = inLibCadenas.TArrayCadenas;
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
  function AnsiOccurs(const str: string; const substr: string): integer;
  function AnsiSplit(const str: string; const separator: string): TStringArray;
  function SoloLetraNIF(S:String):Char;
  procedure ComprobarNIF(AsNIF:String);
  function CheckIBAN(Aiban: string): Boolean;
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

uses
  SysUtils, Variants,
  inLibCifrado, inLibConexionesUniDAC, inLibDatasets,
  inLibFacturas, inLibValoresAutomaticos,
  inLibMsg;

function KeyValuesToStr(const V: Variant): string;
begin
  Result := inLibDatasets.KeyValuesToStr(V);
end;

function StrToKeyValues(const S: string; const FieldNames: string): Variant;
begin
  Result := inLibDatasets.StrToKeyValues(
    S, FieldNames);
end;

function ExtraerTablaDeSQL(const aSQL: string): string;
begin
  Result := inLibDatasets.ExtraerTablaDeSQL(aSQL);
end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;
begin
  Result :=
    inLibDatasets.ObtenerClavePrimaria(ADataSet);
end;

procedure GrabarDatasets(AModule: TDataModule);
begin
  inLibDatasets.GrabarDatasets(AModule);
end;

procedure CancelarDatasets(AModule: TDataModule);
begin
  inLibDatasets.CancelarDatasets(AModule);
end;

function CheckOpenDatasets(AModule: TDataModule): Boolean;
begin
  Result :=
    inLibDatasets.CheckOpenDatasets(AModule);
end;

function HayCoincidencia(str1, str2: string): string;
begin
  Result := inLibCadenas.HayCoincidencia(
    str1, str2);
end;

function SimbolosProhibidos(
  const s: String;
  const APerfilesUsuario: IPerfilesUsuario): Boolean;
begin
  Result := inLibCadenas.SimbolosProhibidos(
    s, APerfilesUsuario);
end;

function AnsiSplit(const str: string;
                   const separator: string): TStringArray;
begin
  Result := inLibCadenas.SepararAnsi(
    str, separator);
end;

function AnsiOccurs(
  const str, substr: string): Integer;
begin
  Result := inLibCadenas.ContarOcurrenciasAnsi(
    str, substr);
end;

procedure ConstruirConexion(conUni: TUniConnection;
                            sUser,
                            sPassword,
                            sHostName,
                            sPort,
                            sDataBase: String);
begin
  inLibConexionesUniDAC.ConfigurarConexionMySQL(
    conUni,
    sUser,
    sPassword,
    sHostName,
    sPort,
    sDataBase);
end;

procedure ConstruirConexionConnect(conUni: TUniConnection;
                                   sUser,
                                   sPassword,
                                   sHostName,
                                   sPort,
                                   sDataBase: String);
begin
  inLibConexionesUniDAC.ConfigurarYConectarMySQL(
    conUni,
    sUser,
    sPassword,
    sHostName,
    sPort,
    sDataBase);
end;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
                                   const AEmpresa, ATipoDoc,
                                   AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSeriePropiaAlmacen(
    AConexion, AEmpresa, ATipoDoc, AAlmacen);
end;

function ObtenerSerieDefecto(AConexion: TUniConnection;
                             const AEmpresa, ATipoDoc: string;
                             const AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSerieDefecto(
    AConexion, AEmpresa, ATipoDoc, AAlmacen);
end;

procedure CargarSeriesEmpresa(AConexion: TUniConnection;
                              const AEmpresa, ATipoDoc: string;
                              AItems: TStrings);
begin
  inLibValoresAutomaticos.CargarSeriesEmpresa(
    AConexion, AEmpresa, ATipoDoc, AItems);
end;

function GetDefaultValue(AConexion: TUniConnection;
  const ATable, AField, AConditionField: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerValorPorDefecto(
    AConexion, ATable, AField, AConditionField);
end;

function ObtenerSiguienteContador(AConexion: TUniConnection;
                                  const ATipoDoc,
                                  AUsuario: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSiguienteContador(
    AConexion, ATipoDoc, AUsuario);
end;

procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
                                   AunqryDestino: TDataSet;
                                   const NombreTabla: string);
begin
  inLibValoresAutomaticos.AplicarValoresPorDefecto(
    AConexion, AunqryDestino, NombreTabla);
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
      raise Exception.CreateFmt(SErrorRecalcularTotalesFactura,
        [Totales.MensajeError]);
    if Assigned(EventoUpdateTotal) then
      EventoUpdateTotal(nil, Totales.Totales.TotalLiquido);
  finally
    FreeAndNil(Totales);
  end;
end;

function EncriptAESPass(s:String; sPass:AnsiString):String;
begin
  Result := inLibCifrado.CifrarAESConContrasena(
    s,
    sPass);
end;

function EncriptAES(s:String):String;
begin
  Result := inLibCifrado.CifrarAES(s);
end;

function DecriptAESPass(s:String; sPass:AnsiString):String;
begin
  Result := inLibCifrado.DescifrarAESConContrasena(
    s,
    sPass);
end;

function DecriptAES(s:String):String;
begin
  Result := inLibCifrado.DescifrarAES(s);
end;

function EncryptData(
  Data: string;
  AKey: AnsiString;
  AIv: AnsiString): string;
begin
  Result := inLibCifrado.CifrarDatosAES(
    Data,
    AKey,
    AIv);
end;

function DecryptData(
  Data: string;
  AKey: AnsiString;
  AIv: AnsiString): string;
begin
  Result := inLibCifrado.DescifrarDatosAES(
    Data,
    AKey,
    AIv);
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
    Result := SErrorNumeroCuentaInvalido;
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
    Result := SErrorNifNoValido;
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
        Raise Exception.CreateFmt(SErrorLetraDniIncorrecta,
          [TomarLetra(AsNIF)]);
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

function ExistePeriodoUnico(qryData:TUniQuery;
                            fFechaIni,
                            fFechaFin:TField): boolean;
begin
  Result := inLibDatasets.ExistePeriodoUnico(
    qryData, fFechaIni, fFechaFin);
end;

end.
