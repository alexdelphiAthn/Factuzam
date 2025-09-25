{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibtb;

interface

uses  SysUtils, Variants, DB, ADODB, ExtCtrls, DBCtrls, Controls, Grids,
      Classes, COMObj, ComCtrls, ExtActns, OleCtrls, Forms, inifiles, Uni,
      SQLBuilder4D, SQLBuilder4D.Parser, SQLBuilder4D.Parser.GaSQLParser,
      System.StrUtils, DCPrijndael, dcpbase64,DCPcrypt2, System.NetEncoding,
      inLibUser, Datasnap.Provider, Datasnap.DBClient, System.DateUtils,
      MidasLib,   Datasnap.Midas,   Soap.SOAPMidas, Datasnap.Win.MidasCon,
      inLibGlobalVar, Dialogs, vcl.consts, inLibMsg;

  type
  TStringArray = array of string;
  function EncriptAES(s:String):String;
  function EncriptAESPass(s:String; sPass:AnsiString):String;
  function DecriptAES(s:String):String;
  function DecriptAESPass(s:String; sPass:AnsiString):String;
  function EncryptData(Data: string; AKey:AnsiString; AIv: AnsiString): string;
  function DecryptData(Data: string; AKey: AnsiString; AIv: AnsiString): string;
  function SoloNumeros(S:String):String;
  function LetraNIF(DNI: String): Char;
  function CalculaDC(Banco, Cuenta: string):integer;
  function DevDC(sNcuenta:String):String;
  function TomarLetra(S: String):String;
  function SonNumeros(S:String):boolean;
  function NomEjecutable:String;
  function AnsiOccurs(const str: string; const substr: string): integer;
  function AnsiSplit(const str: string; const separator: string): TStringArray;
  function SoloLetraNIF(S:String):Char;
  procedure ComprobarNIF(sNIF:String);
  function leCadINI (clave, cadena : string; defecto : string) : string;
  function leCadINIDir (clave, cadena : string;
                        defecto : string; sDir:string) : string;
  function FileSinExtension(sFile: string):string;
  procedure esCadINI (clave, cadena, valor : string);
  procedure esCadINIDir (clave, cadena, valor, sDir : string);
  function CheckIBAN(iban: string): Boolean;
  procedure SetFilterSQL(var qryConsulta: TUniSQL);
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
  function SimbolosProhibidos(s:String):Boolean;
  procedure BusqDataBase(sqlConsulta: TUniQuery;
                        sBusqueda:String;
                        var ConsultaO:string);
//  function ExisteSerieEmpresa(sSerie,
//         sEmpresa,
//         sTipoDoc:string): Boolean;
  function ExistePeriodoUnico( qryData:TUniQuery;
                               fFechaIni,
                               fFechaFin:TField
                               ): boolean;
  function HayCoincidencia(str1, str2: string): string;

implementation

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

function SimbolosProhibidos(s:String):Boolean;
var
  sSimbolos:string;
  sError:string;
begin
  sSimbolos := odmPerfiles.GetKeySubKeyValueDefNoDic('inLibtb',
                                                   'oSimbolosProhibidos',
                                                   ',"'':/-+€%*');
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
    cipher.Free;
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

procedure SetFilterSQL(var qryConsulta: TUniSQL);
var
 sSQL:string;
begin
  sSQL := qryConsulta.SQL.Text;
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
    sConsulta := ConsultaO; //reseteo la consulta porque ha habido otras b�sq.
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

procedure esCadINI (clave, cadena, valor : string);
var
   sIniFile:string;
begin
  if (SameText(ParamStr(2), '')) then
    sIniFile := ExtractFilePath(ParamStr(0)) + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := ExtractFilePath(ParamStr(0)) + ParamStr(2);
  with tinifile.create (sIniFile) do
  try
    writeString (clave, cadena, valor);
  finally
    free;
  end;
end;

procedure esCadINIDir (clave, cadena, valor, sDir : string);
var
   sIniFile:string;
begin
  if SameText(ParamStr(3), '') then
    sIniFile := sDir + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := sDir + ParamStr(3);
  with tinifile.create (sIniFile) do
  try
    writeString (clave, cadena, valor);
  finally
    free;
  end;
end;

function FileSinExtension(sFile: string):string;
begin
 Result := ExtractFilePath(sFile) + copy(ExtractFileName(sFile), 1, pos(ExtractFileExt(sFile), ExtractFileName(sFile)) - 1);
end;

function leCadINI (clave, cadena : string; defecto : string) : string;
var
  sIniFile:string;
begin
  if ParamStr(2) = '' then
    sIniFile := ExtractFilePath(ParamStr(0)) + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := ExtractFilePath(ParamStr(0)) + ParamStr(2);
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
  sIniFile:string;
begin
  if ParamStr(3) = '' then
    sIniFile := sDir + FileSinExtension(ExtractFileName(ParamStr(0))) + '.ini'
  else
    sIniFile := sDir + ParamStr(3);
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

function LetraNIF(DNI: String): Char;
begin
  Result := Copy('TRWAGMYFPDXBNJZSQVHLCKET', StrToInt(DNI) mod 23 + 1, 1)[1];
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

function DevDC(sNcuenta:String):String;
var
  sBanco, sNumero:String;
begin
  if ((SonNumeros(sNcuenta)) and (Length(sNcuenta) = 20)) then
  begin
    sBanco:=Copy(sNcuenta, 1, 8);
    sNumero := Copy(sNcuenta, 11, 20);
    Result  := IntToStr(CalculaDC(sBanco, sNumero));
  end
  else
    Result := 'N�mero de Cuenta Inv�lido';
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
    Result := ' NIF No V�lido';
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

procedure ComprobarNIF(sNIF:String);
begin
  //si el primer digito no es un n�mero, es un CIF
  if (sNIF <> '') then
    if ( (sNIF[1] >= '0') and (sNIF[1] <= '9') ) then
      if ( SoloLetraNIF( sNIF ) <> TomarLetra( sNIF ) ) then
        Raise Exception.Create('Letra DNI Incorrecta. Correcta ' + TomarLetra(sNIF) );
end;

function CheckIBAN(iban: string): Boolean;

    function CalculateDigits(iban: string): Integer;
      function ChangeAlpha(input: string): string;
        // A -> 10, B -> 11, C -> 12 ...
      var
        a: Char;
      begin
        Result := input;
        for a := 'A' to 'Z' do
        begin
          Result := StringReplace(Result, a, IntToStr(Ord(a) - 55), [rfReplaceAll]);
        end;
      end;
    var
      v, l: Integer;
      alpha: string;
      number: Longint;
      rest: Integer;
    begin
      iban := UpperCase(iban);
      if Pos('IBAN', iban) > 0 then
        Delete(iban, Pos('IBAN', iban), 4);
      iban := iban + Copy(iban, 1, 4);
      Delete(iban, 1, 4);
      iban := ChangeAlpha(iban);
      v := 1;
      l := 9;
      rest := 0;
      alpha := '';
      try
        while v <= Length(iban) do
        begin
          if l > Length(iban) then
            l := Length(iban);
          alpha := alpha + Copy(iban, v, l);
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
  iban := StringReplace(iban, ' ', '', [rfReplaceAll]);
  if CalculateDigits(iban) = 1 then
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
// Versi�n ANSI
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
// Devuelve la cantidad de veces que una subcadena est� en una cadena
// Versi�n ANSI
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
    if assigned(cli) then
    begin
      cli.Close;
      FreeAndNil(cli);
//      if (Dsp <> nil) then
//        FreeAndNil(Dsp);
    end;
    Result := bFechaOrd;
  end
  else
    Result := true;
end;

end.
