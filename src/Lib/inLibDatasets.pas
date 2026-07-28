{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDatasets                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de claves, metadata y estado de datasets.                      }
{******************************************************************************}
unit inLibDatasets;

interface

uses
  System.Variants, System.Classes, Data.DB, Uni;

function KeyValuesToStr(const AValores: Variant): string;
function StrToKeyValues(
  const AValor, ACampos: string): Variant;
function ExtraerTablaDeSQL(const ASql: string): string;
function ObtenerClavePrimaria(ADataSet: TDataSet): string;
procedure GrabarDatasets(AModulo: TDataModule);
procedure CancelarDatasets(AModulo: TDataModule);
function CheckOpenDatasets(AModulo: TDataModule): Boolean;
function ExistePeriodoUnico(
  AConsulta: TUniQuery;
  ACampoFechaInicio: TField;
  ACampoFechaFin: TField): Boolean;

implementation

uses
  System.SysUtils, System.DateUtils,
  Datasnap.Provider, Datasnap.DBClient;

function KeyValuesToStr(const AValores: Variant): string;
var
  i: Integer;
begin
  Result := '';
  if not VarIsNull(AValores) and
     not VarIsEmpty(AValores) then
  begin
    if VarIsArray(AValores) then
    begin
      for i := VarArrayLowBound(AValores, 1) to
        VarArrayHighBound(AValores, 1) do
      begin
        if Result <> '' then
          Result := Result + '|';
        Result := Result + VarToStr(AValores[i]);
      end;
    end
    else
      Result := VarToStr(AValores);
  end;
end;

function StrToKeyValues(
  const AValor, ACampos: string): Variant;
var
  i: Integer;
  oCampos: TStringList;
  oValores: TStringList;
begin
  if Pos(';', ACampos) = 0 then
    Result := AValor
  else
  begin
    oCampos := TStringList.Create;
    oValores := TStringList.Create;
    try
      oCampos.Delimiter := ';';
      oCampos.StrictDelimiter := True;
      oCampos.DelimitedText := ACampos;
      oValores.Delimiter := '|';
      oValores.StrictDelimiter := True;
      oValores.DelimitedText := AValor;
      Result := VarArrayCreate(
        [0, oCampos.Count - 1], varVariant);
      for i := 0 to oCampos.Count - 1 do
      begin
        if i < oValores.Count then
          Result[i] := oValores[i]
        else
          Result[i] := Null;
      end;
    finally
      FreeAndNil(oCampos);
      FreeAndNil(oValores);
    end;
  end;
end;

function ExtraerTablaDeSQL(const ASql: string): string;
var
  bEncontrado: Boolean;
  i: Integer;
  iFin: Integer;
  iInicio: Integer;
  iNivel: Integer;
  sMayusculas: string;

  function HayFromEn(APosicion: Integer): Boolean;
  begin
    Result :=
      (APosicion + 3 <= Length(sMayusculas)) and
      (Copy(sMayusculas, APosicion, 4) = 'FROM');
    if Result and
       (APosicion > 1) and
       not CharInSet(
         sMayusculas[APosicion - 1],
         [' ', #9, #10, #13, '(', ')', ',']) then
      Result := False;
    if Result and
       (APosicion + 4 <= Length(sMayusculas)) and
       not CharInSet(
         sMayusculas[APosicion + 4],
         [' ', #9, #10, #13, '(']) then
      Result := False;
  end;

begin
  Result := '';
  sMayusculas := UpperCase(ASql);
  iNivel := 0;
  i := 1;
  iInicio := 0;
  bEncontrado := False;
  while (i <= Length(sMayusculas)) and
        not bEncontrado do
  begin
    if sMayusculas[i] = '(' then
      Inc(iNivel)
    else if (sMayusculas[i] = ')') and
            (iNivel > 0) then
      Dec(iNivel)
    else if (iNivel = 0) and
            HayFromEn(i) then
    begin
      iInicio := i + 4;
      bEncontrado := True;
    end;
    Inc(i);
  end;
  if bEncontrado then
  begin
    while (iInicio <= Length(sMayusculas)) and
          CharInSet(
            sMayusculas[iInicio],
            [' ', #9, #10, #13]) do
      Inc(iInicio);
    iFin := iInicio;
    while (iFin <= Length(sMayusculas)) and
          not CharInSet(
            sMayusculas[iFin],
            [' ', #13, #10, #9, '(', ',', ';']) do
      Inc(iFin);
    Result := Trim(
      Copy(ASql, iInicio, iFin - iInicio));
    if (Length(Result) >= 2) and
       (Result[1] = '`') then
      Result := Copy(
        Result, 2, Length(Result) - 2);
  end;
end;

function ObtenerClavePrimaria(ADataSet: TDataSet): string;
var
  i: Integer;
  oConsulta: TUniQuery;
  sTabla: string;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    if ADataSet is TUniQuery then
      Result := TUniQuery(ADataSet).KeyFields;
    if Result = '' then
    begin
      for i := 0 to ADataSet.FieldCount - 1 do
      begin
        if pfInKey in
           ADataSet.Fields[i].ProviderFlags then
        begin
          if Result <> '' then
            Result := Result + ';';
          Result :=
            Result + ADataSet.Fields[i].FieldName;
        end;
      end;
    end;
    if (Result = '') and
       (ADataSet is TUniQuery) and
       Assigned(TUniQuery(ADataSet).Connection) then
    begin
      sTabla := ExtraerTablaDeSQL(
        TUniQuery(ADataSet).SQL.Text);
      if sTabla <> '' then
      begin
        oConsulta := TUniQuery.Create(nil);
        try
          oConsulta.Connection :=
            TUniQuery(ADataSet).Connection;
          oConsulta.SQL.Text :=
            'SELECT COLUMN_NAME ' +
            '  FROM information_schema.KEY_COLUMN_USAGE ' +
            ' WHERE TABLE_SCHEMA = database() ' +
            '   AND TABLE_NAME = :TAB ' +
            '   AND CONSTRAINT_NAME = ''PRIMARY'' ' +
            ' ORDER BY ORDINAL_POSITION';
          oConsulta.ParamByName(
            'TAB').AsString := sTabla;
          oConsulta.Open;
          while not oConsulta.Eof do
          begin
            if Result <> '' then
              Result := Result + ';';
            Result := Result +
              oConsulta.FieldByName(
                'COLUMN_NAME').AsString;
            oConsulta.Next;
          end;
          oConsulta.Close;
        finally
          FreeAndNil(oConsulta);
        end;
      end;
    end;
  end;
end;

procedure GrabarDatasets(AModulo: TDataModule);
var
  i: Integer;
  oDataSet: TDataSet;
begin
  if Assigned(AModulo) then
  begin
    for i := 0 to AModulo.ComponentCount - 1 do
    begin
      if AModulo.Components[i] is TDataSet then
      begin
        oDataSet :=
          TDataSet(AModulo.Components[i]);
        if oDataSet.Active and
           (oDataSet.State in
             [dsEdit, dsInsert]) then
          oDataSet.Post;
      end;
    end;
  end;
end;

procedure CancelarDatasets(AModulo: TDataModule);
var
  i: Integer;
  oDataSet: TDataSet;
begin
  if Assigned(AModulo) then
  begin
    for i := 0 to AModulo.ComponentCount - 1 do
    begin
      if AModulo.Components[i] is TDataSet then
      begin
        oDataSet :=
          TDataSet(AModulo.Components[i]);
        if oDataSet.Active and
           (oDataSet.State in
             [dsEdit, dsInsert]) then
          oDataSet.Cancel;
      end;
    end;
  end;
end;

function CheckOpenDatasets(
  AModulo: TDataModule): Boolean;
var
  i: Integer;
  oDataSet: TDataSet;
begin
  Result := False;
  i := 0;
  while Assigned(AModulo) and
        (i < AModulo.ComponentCount) and
        not Result do
  begin
    if AModulo.Components[i] is TDataSet then
    begin
      oDataSet :=
        TDataSet(AModulo.Components[i]);
      Result :=
        oDataSet.Active and
        (oDataSet.State in [dsEdit, dsInsert]);
    end;
    Inc(i);
  end;
end;

function ExistePeriodoUnico(
  AConsulta: TUniQuery;
  ACampoFechaInicio: TField;
  ACampoFechaFin: TField): Boolean;
var
  bFechasOrdenadas: Boolean;
  bFechaFinNula: Boolean;
  bFechaInicioNula: Boolean;
  dFechaFin: TDateTime;
  dFechaInicio: TDateTime;
  iComparacionFin: Integer;
  iComparacionInicio: Integer;
  oCliente: TClientDataSet;
  oProveedor: TDataSetProvider;
  sCampoFechaFin: string;
  sCampoFechaInicio: string;
begin
  oCliente := nil;
  sCampoFechaInicio := ACampoFechaInicio.FieldName;
  sCampoFechaFin := ACampoFechaFin.FieldName;
  bFechasOrdenadas := True;
  bFechaFinNula := ACampoFechaFin.IsNull;
  bFechaInicioNula := ACampoFechaInicio.IsNull;
  dFechaInicio := ACampoFechaInicio.AsDateTime;
  dFechaFin := ACampoFechaFin.AsDateTime;
  if AConsulta.RecordCount > 1 then
  begin
    if not bFechaFinNula and
       (CompareDate(
         dFechaInicio, dFechaFin) > 0) then
      bFechasOrdenadas := False;
    if bFechaInicioNula and
       bFechasOrdenadas then
      bFechasOrdenadas := False;
    try
      if bFechasOrdenadas then
      begin
        oCliente := TClientDataSet.Create(nil);
        oProveedor :=
          TDataSetProvider.Create(oCliente);
        oProveedor.DataSet := AConsulta;
        oCliente.SetProvider(oProveedor);
        oCliente.Open;
        oCliente.First;
      end;
      while Assigned(oCliente) and
            not oCliente.Eof and
            bFechasOrdenadas do
      begin
        if bFechaFinNula then
        begin
          if oCliente.FieldByName(
               sCampoFechaFin).IsNull then
            bFechasOrdenadas := False;
          if bFechasOrdenadas then
          begin
            iComparacionInicio := CompareDate(
              oCliente.FieldByName(
                sCampoFechaFin).AsDateTime,
              dFechaInicio);
            if iComparacionInicio > 0 then
              bFechasOrdenadas := False;
          end;
        end;
        if not bFechaFinNula and
           bFechasOrdenadas then
        begin
          iComparacionInicio := CompareDate(
            oCliente.FieldByName(
              sCampoFechaInicio).AsDateTime,
            dFechaFin);
          iComparacionFin := CompareDate(
            oCliente.FieldByName(
              sCampoFechaFin).AsDateTime,
            dFechaInicio);
          if (iComparacionInicio < 0) and
             (iComparacionFin > 0) then
            bFechasOrdenadas := False;
        end;
        oCliente.Next;
      end;
    finally
      if Assigned(oCliente) then
      begin
        oCliente.Close;
        FreeAndNil(oCliente);
      end;
    end;
    Result := bFechasOrdenadas;
  end
  else
    Result := True;
end;

end.
