{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImpuestosComun                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades fiscales compartidas por compras y ventas: lectura y           }
{    escritura tolerante de campos, normalización de tipos de IVA y            }
{    lectura de porcentajes por código de IVA o por empresa.                   }
{    Extraída de inLibComprasImpuestos / inLibVentasImpuestos, donde           }
{    estas 14 funciones vivían duplicadas byte a byte.                         }
{******************************************************************************}
unit inLibImpuestosComun;

interface

uses
  System.SysUtils, Data.DB, DBAccess, Uni;

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
function CampoString(ADataSet: TDataSet; const ACampo: string): string;
function CampoFloatDifiere(ADataSet: TDataSet; const ACampo: string;
  AValor: Double): Boolean;
function CampoStringDifiere(ADataSet: TDataSet; const ACampo,
  AValor: string): Boolean;
procedure PonerFloat(ADataSet: TDataSet; const ACampo: string;
  AValor: Double);
procedure PonerString(ADataSet: TDataSet; const ACampo, AValor: string);
function TipoIvaValido(const ATipoIva: string): Boolean;
function NormalizarTipoIva(const ATipoIva: string): string;
function IndiceTipoIva(const ATipoIva: string): Integer;
function LeerPorcentajesIvaPorCodigo(AConn: TUniConnection;
  const ACodigoIva: string; out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double): Boolean;
function LeerPorcentajesIvaPorEmpresa(AConn: TUniConnection;
  const ACodigoEmp: string; out ACodigoIva: string; out AIvaN, AIvaR,
  AIvaS, AIvaE, ARecN, ARecR, ARecS, ARecE: Double): Boolean;
function ObtenerTipoIvaArticulo(AConn: TUniConnection;
  const ACodigoArt: string): string;
function PorcentajeIvaCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
function SufijoLineaFiscalDesdeCampo(const ACampoTipoIva: string): string;

implementation

const
  // Copia privada: el orden define el indice de tipo de IVA (N/R/S/E)
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsFloat;
  end;
end;

function CampoString(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsString;
  end;
end;

function CampoFloatDifiere(ADataSet: TDataSet; const ACampo: string;
  AValor: Double): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.IsNull or (Abs(oCampo.AsFloat - AValor) > 0.000001);
  end;
end;

function CampoStringDifiere(ADataSet: TDataSet; const ACampo,
  AValor: string): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := oCampo.IsNull or (oCampo.AsString <> AValor);
  end;
end;

procedure PonerFloat(ADataSet: TDataSet; const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and CampoFloatDifiere(ADataSet, ACampo, AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      oCampo.AsFloat := AValor;
    end;
  end;
end;

procedure PonerString(ADataSet: TDataSet; const ACampo, AValor: string);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and CampoStringDifiere(ADataSet, ACampo, AValor) then
    begin
      if not (ADataSet.State in dsEditModes) then
        ADataSet.Edit;
      oCampo.AsString := AValor;
    end;
  end;
end;

function TipoIvaValido(const ATipoIva: string): Boolean;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoIva));
  Result := (sTipo = 'N') or (sTipo = 'R') or (sTipo = 'S') or
            (sTipo = 'E');
end;

function NormalizarTipoIva(const ATipoIva: string): string;
begin
  Result := UpperCase(Trim(ATipoIva));
  if not TipoIvaValido(Result) then
    Result := 'N';
end;

function IndiceTipoIva(const ATipoIva: string): Integer;
var
  sTipo: string;
begin
  sTipo := NormalizarTipoIva(ATipoIva);
  Result := 0;
  if sTipo = 'R' then
    Result := 1
  else if sTipo = 'S' then
    Result := 2
  else if sTipo = 'E' then
    Result := 3;
end;

function LeerPorcentajesIvaPorCodigo(AConn: TUniConnection;
  const ACodigoIva: string; out AIvaN, AIvaR, AIvaS, AIvaE,
  ARecN, ARecR, ARecS, ARecE: Double): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  AIvaN := 0;
  AIvaR := 0;
  AIvaS := 0;
  AIvaE := 0;
  ARecN := 0;
  ARecR := 0;
  ARecS := 0;
  ARecE := 0;
  if (AConn <> nil) and (Trim(ACodigoIva) <> '') and
     (Trim(ACodigoIva) <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT IFNULL(PORCENTAJE_NORMAL_IVA, 0) AS IVAN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_IVA, 0) AS IVAR, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_IVA, 0) AS IVAS, ' +
        '       IFNULL(PORCENTAJE_EXENTO_IVA, 0) AS IVAE, ' +
        '       IFNULL(PORCENTAJE_NORMAL_RE_IVA, 0) AS REN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_RE_IVA, 0) AS RER, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) AS RES, ' +
        '       IFNULL(PORCENTAJE_EXENTO_RE_IVA, 0) AS REE ' +
        '  FROM fza_ivas ' +
        ' WHERE CODIGO_IVA = :iva';
      q.ParamByName('iva').AsString := ACodigoIva;
      q.Open;
      Result := not q.Eof;
      if Result then
      begin
        AIvaN := q.FieldByName('IVAN').AsFloat;
        AIvaR := q.FieldByName('IVAR').AsFloat;
        AIvaS := q.FieldByName('IVAS').AsFloat;
        AIvaE := q.FieldByName('IVAE').AsFloat;
        ARecN := q.FieldByName('REN').AsFloat;
        ARecR := q.FieldByName('RER').AsFloat;
        ARecS := q.FieldByName('RES').AsFloat;
        ARecE := q.FieldByName('REE').AsFloat;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function LeerPorcentajesIvaPorEmpresa(AConn: TUniConnection;
  const ACodigoEmp: string; out ACodigoIva: string; out AIvaN, AIvaR,
  AIvaS, AIvaE, ARecN, ARecR, ARecS, ARecE: Double): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  ACodigoIva := '';
  AIvaN := 0;
  AIvaR := 0;
  AIvaS := 0;
  AIvaE := 0;
  ARecN := 0;
  ARecR := 0;
  ARecS := 0;
  ARecE := 0;
  if (AConn <> nil) and (Trim(ACodigoEmp) <> '') and
     (Trim(ACodigoEmp) <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT CODIGO_IVA, ' +
        '       IFNULL(PORCENTAJE_NORMAL_IVA, 0) AS IVAN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_IVA, 0) AS IVAR, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_IVA, 0) AS IVAS, ' +
        '       IFNULL(PORCENTAJE_EXENTO_IVA, 0) AS IVAE, ' +
        '       IFNULL(PORCENTAJE_NORMAL_RE_IVA, 0) AS REN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_RE_IVA, 0) AS RER, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) AS RES, ' +
        '       IFNULL(PORCENTAJE_EXENTO_RE_IVA, 0) AS REE ' +
        '  FROM vi_ivas_empresa ' +
        ' WHERE CODIGO_EMP_EMP = :emp ' +
        '   AND ESDEFAULT_IVA_IVAGRP = ''S'' ' +
        ' LIMIT 1';
      q.ParamByName('emp').AsString := ACodigoEmp;
      q.Open;
      Result := not q.Eof;
      if Result then
      begin
        ACodigoIva := q.FieldByName('CODIGO_IVA').AsString;
        AIvaN := q.FieldByName('IVAN').AsFloat;
        AIvaR := q.FieldByName('IVAR').AsFloat;
        AIvaS := q.FieldByName('IVAS').AsFloat;
        AIvaE := q.FieldByName('IVAE').AsFloat;
        ARecN := q.FieldByName('REN').AsFloat;
        ARecR := q.FieldByName('RER').AsFloat;
        ARecS := q.FieldByName('RES').AsFloat;
        ARecE := q.FieldByName('REE').AsFloat;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function ObtenerTipoIvaArticulo(AConn: TUniConnection;
  const ACodigoArt: string): string;
var
  q: TUniQuery;
begin
  Result := '';
  if (AConn <> nil) and (Trim(ACodigoArt) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT TIPO_IVA_ART ' +
        '  FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :art';
      q.ParamByName('art').AsString := ACodigoArt;
      q.Open;
      if not q.Eof then
        Result := UpperCase(Trim(q.FieldByName('TIPO_IVA_ART').AsString));
    finally
      FreeAndNil(q);
    end;
  end;
  if not TipoIvaValido(Result) then
    Result := '';
end;

function PorcentajeIvaCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
var
  iIndice: Integer;
begin
  iIndice := IndiceTipoIva(ATipoIva);
  Result := CampoFloat(ACabecera,
    'PORCENTAJE_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera);
end;

function SufijoLineaFiscalDesdeCampo(const ACampoTipoIva: string): string;
const
  PREFIJO = 'TIPO_IVA_ARTICULO_';
begin
  Result := '';
  if Pos(PREFIJO, ACampoTipoIva) = 1 then
    Result := Copy(ACampoTipoIva, Length(PREFIJO) + 1, MaxInt);
end;

end.
