{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigDumpEsqueleto                                         }
{    Tipo:       Librería sin formulario                                       }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Vuelca a un fichero .sql el ESQUELETO de una BBDD Factuzam viva:          }
{      - CREATE TABLE de todas las tablas `fza_*` (estructura completa,        }
{        via SHOW CREATE TABLE → fiel al estado actual del esquema).           }
{      - CREATE VIEW de las vistas `vi_*`.                                     }
{      - CREATE PROCEDURE de los procedimientos `PRC_*` / `FN_*`.              }
{      - DATOS de tablas SISTEMA (paises, ivas_tipos, winforms,                }
{        metadatos, generadorprocesos, config_campos, ivas_zonas...).         }
{        Las tablas de negocio (articulos, clientes, facturas, etc.) se        }
{        crean vacias — eso es lo que rellena el migrador.                     }
{                                                                              }
{    El resultado es un .sql cargable con `mysql < esqueleto.sql` o vía        }
{    `dmMig.CargarEsquemaDestino`. Pensado para refrescar el esqueleto         }
{    cada vez que cambia el esquema (que es a menudo).                         }
{                                                                              }
{    NOTA: no genera `INSERT` de tablas grandes ni de las que llenará el       }
{    migrador. La lista TABLAS_SISTEMA esta hardcodeada al final del           }
{    fichero — si añades una tabla seed nueva, registrala alli.                }
{******************************************************************************}
unit inLibMigDumpEsqueleto;

interface

uses
  System.Classes, System.SysUtils,
  Data.DB, Uni,
  UMigEngine;

type
  TLogEsqueleto = reference to procedure(const sMensaje: string);

// Vuelca el esqueleto de la BBDD a la que apunta `Con` en `sRutaSalida`.
// Devuelve el numero de tablas + vistas + procedures volcados.
function DumpEsqueleto(Con: TUniConnection; const sRutaSalida: string;
                       OnLog: TLogEsqueleto): Integer;

implementation

uses
  System.Generics.Collections, System.StrUtils;

// Lista de tablas cuyo CONTENIDO se incluye en el esqueleto. El resto
// de tablas se crean vacias. Mantener ordenado alfabeticamente y
// documentado.
function TablasSistema: TArray<string>;
begin
  Result := [
    'fza_config_campos',      // configuracion de campos UI
    'fza_generadorprocesos',  // workflows / procesos automatizables
    'fza_ivas_tipos',         // N/R/S/E (las 4 letras fijas)
    'fza_ivas_zonas',         // zonas IVA (peninsula, intracom...)
    'fza_metadatos',          // metadatos del sistema
    'fza_paises',             // catalogo ISO de paises
    'fza_winforms'            // registro de pantallas para menu/Ctrl+X
  ];
end;

function EsTablaSistema(const sTabla: string): Boolean;
var s: string;
begin
  for s in TablasSistema do
    if SameText(s, sTabla) then Exit(True);
  Result := False;
end;

// Escapa un string para usarlo dentro de un literal SQL ' ... '
// segun reglas MySQL/MariaDB.
function EscaparLiteralSQL(const s: string): string;
var i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    case s[i] of
      '''': Result := Result + '''''';
      '\':  Result := Result + '\\';
      #0:   Result := Result + '\0';
      #10:  Result := Result + '\n';
      #13:  Result := Result + '\r';
      #26:  Result := Result + '\Z';
    else
      Result := Result + s[i];
    end;
end;

// Devuelve la representacion SQL de un campo (NULL, numero, 'literal',
// fecha 'YYYY-MM-DD HH:MM:SS', etc.) para usar en un INSERT.
function ValorSQL(F: TField): string;
begin
  if F.IsNull then Exit('NULL');
  case F.DataType of
    ftSmallint, ftInteger, ftWord, ftLargeint,
    ftFloat, ftCurrency, ftBCD, ftFMTBcd:
      Result := F.AsString;  // numero, sin comillas
    ftBoolean:
      if F.AsBoolean then Result := '1' else Result := '0';
    ftDate:
      Result := QuotedStr(FormatDateTime('yyyy-mm-dd', F.AsDateTime));
    ftTime:
      Result := QuotedStr(FormatDateTime('hh:nn:ss', F.AsDateTime));
    ftDateTime, ftTimeStamp:
      Result := QuotedStr(
        FormatDateTime('yyyy-mm-dd hh:nn:ss', F.AsDateTime));
  else
    // Tratamiento generico de texto / blob → escapar
    Result := '''' + EscaparLiteralSQL(F.AsString) + '''';
  end;
end;

procedure AddLine(Strs: TStringList; const s: string);
begin
  Strs.Add(s);
end;

function EsCaracterIdentificadorSQL(c: Char): Boolean;
begin
  Result := ((c >= 'a') and (c <= 'z')) or
            ((c >= 'A') and (c <= 'Z')) or
            ((c >= '0') and (c <= '9')) or
            (c = '_');
end;

function ContieneIdentificadorSQL(const sTexto, sIdentificador: string):
  Boolean;
var
  sTextoNorm: string;
  sIdNorm:    string;
  iPos:       Integer;
  iLen:       Integer;
  bInicio:    Boolean;
  bFin:       Boolean;
begin
  Result := False;
  sTextoNorm := LowerCase(sTexto);
  sIdNorm := LowerCase(sIdentificador);
  iLen := Length(sIdNorm);
  iPos := PosEx(sIdNorm, sTextoNorm, 1);
  while iPos > 0 do
  begin
    bInicio := (iPos = 1) or
      (not EsCaracterIdentificadorSQL(sTextoNorm[iPos - 1]));
    bFin := (iPos + iLen > Length(sTextoNorm)) or
      (not EsCaracterIdentificadorSQL(sTextoNorm[iPos + iLen]));
    if bInicio and bFin then
    begin
      Result := True;
    end;
    if not Result then
    begin
      iPos := PosEx(sIdNorm, sTextoNorm, iPos + iLen);
    end
    else
      iPos := 0;
  end;
end;

function DDLReferenciaVista(const sDDL, sVista: string): Boolean;
begin
  Result := ContainsText(sDDL, '`' + sVista + '`') or
            ContainsText(sDDL, '"' + sVista + '"') or
            ContieneIdentificadorSQL(sDDL, sVista);
end;

procedure OrdenarVistasPorDependencias(const oNombres: TStringList;
                                       const oDDL:
                                         TDictionary<string, string>;
                                       oOrden: TStringList);
var
  oPendientes: TStringList;
  i, j:        Integer;
  bAgregado:   Boolean;
  bDepende:    Boolean;
  sNombre:     string;
  sDep:        string;
  sDDL:        string;
begin
  oPendientes := TStringList.Create;
  try
    oPendientes.Assign(oNombres);
    oPendientes.Sort;
    while oPendientes.Count > 0 do
    begin
      bAgregado := False;
      i := 0;
      while i < oPendientes.Count do
      begin
        sNombre := oPendientes[i];
        bDepende := False;
        if oDDL.TryGetValue(sNombre, sDDL) then
        begin
          for j := 0 to oPendientes.Count - 1 do
          begin
            sDep := oPendientes[j];
            if not SameText(sDep, sNombre) then
            begin
              if DDLReferenciaVista(sDDL, sDep) then
              begin
                bDepende := True;
              end;
            end;
          end;
        end;
        if not bDepende then
        begin
          oOrden.Add(sNombre);
          oPendientes.Delete(i);
          bAgregado := True;
        end
        else
          Inc(i);
      end;
      if not bAgregado then
      begin
        oOrden.Add(oPendientes[0]);
        oPendientes.Delete(0);
      end;
    end;
  finally
    oPendientes.Free;
  end;
end;

// Vuelca CREATE TABLE usando SHOW CREATE TABLE de MySQL (fiel al
// estado real de la tabla, incluidos indices, FK, comentarios...).
procedure VolcarCreateTable(Con: TUniConnection; const sTabla: string;
                            oOut: TStringList);
var qShow: TUniQuery;
    sDDL:  string;
begin
  qShow := TUniQuery.Create(nil);
  try
    qShow.Connection := Con;
    qShow.SQL.Text   := Format('SHOW CREATE TABLE `%s`', [sTabla]);
    qShow.Open;
    if qShow.IsEmpty then Exit;
    sDDL := qShow.Fields[1].AsString;
    AddLine(oOut, '');
    AddLine(oOut, '-- ---------------------------------------------');
    AddLine(oOut, Format('-- Tabla: %s', [sTabla]));
    AddLine(oOut, '-- ---------------------------------------------');
    AddLine(oOut, Format('DROP TABLE IF EXISTS `%s`;', [sTabla]));
    AddLine(oOut, sDDL + ';');
  finally
    qShow.Free;
  end;
end;

// Vuelca los INSERT de una tabla (solo para las tablas de sistema).
procedure VolcarDatos(Con: TUniConnection; const sTabla: string;
                      oOut: TStringList);
var
  qData:               TUniQuery;
  sCols, sVals, sLine: string;
  i:                   Integer;
  iCount:              Integer;
begin
  qData := TUniQuery.Create(nil);
  try
    qData.Connection := Con;
    qData.SQL.Text   := Format('SELECT * FROM `%s`', [sTabla]);
    qData.Open;
    if qData.IsEmpty then Exit;

    // Construir lista de columnas
    sCols := '';
    for i := 0 to qData.Fields.Count - 1 do
    begin
      if sCols <> '' then sCols := sCols + ', ';
      sCols := sCols + '`' + qData.Fields[i].FieldName + '`';
    end;

    AddLine(oOut, '');
    AddLine(oOut, Format('-- Datos seed de %s', [sTabla]));
    iCount := 0;
    while not qData.Eof do
    begin
      sVals := '';
      for i := 0 to qData.Fields.Count - 1 do
      begin
        if sVals <> '' then sVals := sVals + ', ';
        sVals := sVals + ValorSQL(qData.Fields[i]);
      end;
      sLine := Format('INSERT INTO `%s` (%s) VALUES (%s);',
                      [sTabla, sCols, sVals]);
      AddLine(oOut, sLine);
      Inc(iCount);
      qData.Next;
    end;
    AddLine(oOut, Format('-- %d filas', [iCount]));
  finally
    qData.Free;
  end;
end;

// Vuelca las vistas vi_*
procedure VolcarVistas(Con: TUniConnection; oOut: TStringList;
                       OnLog: TLogEsqueleto; var iCount: Integer);
var
  qList, qShow: TUniQuery;
  oNombres:     TStringList;
  oOrden:       TStringList;
  oDDL:         TDictionary<string, string>;
  sNombre:      string;
  sDDL:         string;
  i:            Integer;
begin
  qList := TUniQuery.Create(nil);
  qShow := TUniQuery.Create(nil);
  oNombres := TStringList.Create;
  oOrden := TStringList.Create;
  oDDL := TDictionary<string, string>.Create;
  try
    qList.Connection := Con;
    qList.SQL.Text   :=
      'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'ORDER BY TABLE_NAME';
    qList.Open;
    qShow.Connection := Con;
    while not qList.Eof do
    begin
      sNombre := qList.Fields[0].AsString;
      qShow.Close;
      qShow.SQL.Text := Format('SHOW CREATE VIEW `%s`', [sNombre]);
      qShow.Open;
      if not qShow.IsEmpty then
      begin
        sDDL := qShow.Fields[1].AsString;
        oNombres.Add(sNombre);
        oDDL.Add(sNombre, sDDL);
      end;
      qList.Next;
    end;
    OrdenarVistasPorDependencias(oNombres, oDDL, oOrden);
    if oOrden.Count > 0 then
    begin
      AddLine(oOut, '');
      AddLine(oOut, '-- ---------------------------------------------');
      AddLine(oOut, '-- Limpieza de vistas');
      AddLine(oOut, '-- ---------------------------------------------');
      for i := oOrden.Count - 1 downto 0 do
        AddLine(oOut, Format('DROP VIEW IF EXISTS `%s`;', [oOrden[i]]));
      for i := 0 to oOrden.Count - 1 do
      begin
        sNombre := oOrden[i];
        if oDDL.TryGetValue(sNombre, sDDL) then
        begin
          AddLine(oOut, '');
          AddLine(oOut, '-- ---------------------------------------------');
          AddLine(oOut, Format('-- Vista: %s', [sNombre]));
          AddLine(oOut, '-- ---------------------------------------------');
          AddLine(oOut, sDDL + ';');
          Inc(iCount);
          if Assigned(OnLog) then
            OnLog('  vista: ' + sNombre);
        end;
      end;
    end;
  finally
    oDDL.Free;
    oOrden.Free;
    oNombres.Free;
    qShow.Free;
    qList.Free;
  end;
end;

// Vuelca procedures y funciones almacenadas
procedure VolcarRutinas(Con: TUniConnection; oOut: TStringList;
                        OnLog: TLogEsqueleto; var iCount: Integer);
var qList, qShow: TUniQuery;
    sNombre, sTipo, sDDL, sShowCmd: string;
    iColDDL: Integer;
begin
  qList := TUniQuery.Create(nil);
  qShow := TUniQuery.Create(nil);
  try
    qList.Connection := Con;
    qList.SQL.Text   :=
      'SELECT ROUTINE_NAME, ROUTINE_TYPE ' +
      'FROM INFORMATION_SCHEMA.ROUTINES ' +
      'WHERE ROUTINE_SCHEMA = DATABASE() ' +
      'ORDER BY ROUTINE_TYPE, ROUTINE_NAME';
    qList.Open;
    qShow.Connection := Con;
    while not qList.Eof do
    begin
      sNombre := qList.Fields[0].AsString;
      sTipo   := UpperCase(qList.Fields[1].AsString);
      if sTipo = 'PROCEDURE' then
      begin
        sShowCmd := Format('SHOW CREATE PROCEDURE `%s`', [sNombre]);
        iColDDL  := 2;  // SHOW CREATE PROCEDURE: col 0=name 1=mode 2=DDL
      end
      else
      begin
        sShowCmd := Format('SHOW CREATE FUNCTION `%s`', [sNombre]);
        iColDDL  := 2;
      end;
      qShow.Close;
      qShow.SQL.Text := sShowCmd;
      qShow.Open;
      if not qShow.IsEmpty then
      begin
        sDDL := qShow.Fields[iColDDL].AsString;
        AddLine(oOut, '');
        AddLine(oOut, '-- ---------------------------------------------');
        AddLine(oOut, Format('-- %s: %s', [sTipo, sNombre]));
        AddLine(oOut, '-- ---------------------------------------------');
        AddLine(oOut, Format('DROP %s IF EXISTS `%s`;', [sTipo, sNombre]));
        AddLine(oOut, 'DELIMITER $$');
        AddLine(oOut, sDDL + '$$');
        AddLine(oOut, 'DELIMITER ;');
        Inc(iCount);
        if Assigned(OnLog) then
          OnLog(Format('  %s: %s', [LowerCase(sTipo), sNombre]));
      end;
      qList.Next;
    end;
  finally
    qShow.Free;
    qList.Free;
  end;
end;

// =========================================================================
//  Funcion principal
// =========================================================================

function DumpEsqueleto(Con: TUniConnection; const sRutaSalida: string;
                       OnLog: TLogEsqueleto): Integer;
var
  qTablas:  TUniQuery;
  oOut:      TStringList;
  sTabla:   string;
  iCount:   Integer;
begin
  iCount := 0;
  if not Con.Connected then Con.Open;

  oOut := TStringList.Create;
  qTablas := TUniQuery.Create(nil);
  try
    // Cabecera del fichero
    AddLine(oOut, '-- =================================================');
    AddLine(oOut, '-- ESQUELETO Factuzam generado dinamicamente');
    AddLine(oOut, '-- Generado: ' +
            FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    AddLine(oOut, '-- BBDD origen: ' + Con.Database);
    AddLine(oOut, '-- =================================================');
    AddLine(oOut, '');
    AddLine(oOut, 'SET FOREIGN_KEY_CHECKS = 0;');
    AddLine(oOut, 'SET SQL_MODE = ''NO_AUTO_VALUE_ON_ZERO'';');
    AddLine(oOut, '');

    // Listar todas las tablas fza_*
    qTablas.Connection := Con;
    qTablas.SQL.Text   :=
      'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = ''BASE TABLE'' ' +
      'ORDER BY TABLE_NAME';
    qTablas.Open;

    // Volcar CREATE de cada tabla y, si es sistema, sus datos.
    while not qTablas.Eof do
    begin
      sTabla := qTablas.Fields[0].AsString;
      VolcarCreateTable(Con, sTabla, oOut);
      if EsTablaSistema(sTabla) then
      begin
        VolcarDatos(Con, sTabla, oOut);
        if Assigned(OnLog) then
          OnLog(Format('  tabla + datos: %s', [sTabla]));
      end
      else if Assigned(OnLog) then
        OnLog(Format('  tabla (vacia): %s', [sTabla]));
      Inc(iCount);
      qTablas.Next;
    end;

    // Vistas y rutinas
    VolcarVistas(Con, oOut, OnLog, iCount);
    VolcarRutinas(Con, oOut, OnLog, iCount);

    AddLine(oOut, '');
    AddLine(oOut, 'SET FOREIGN_KEY_CHECKS = 1;');
    AddLine(oOut, '-- Fin del esqueleto.');

    oOut.SaveToFile(sRutaSalida, TEncoding.UTF8);
    Result := iCount;
  finally
    qTablas.Free;
    oOut.Free;
  end;
end;

end.
