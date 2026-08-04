{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataImpuestosRepositorio                                  }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC para las lecturas fiscales de documentos.                }
{******************************************************************************}
unit UniDataImpuestosRepositorio;

interface

uses
  Uni, inLibImpuestosLecturasIntf;

function CrearLecturasImpuestos(
  AConexion: TUniConnection): ILecturasImpuestos;

implementation

uses
  System.SysUtils;

type
  TLecturasImpuestos = class(TInterfacedObject, ILecturasImpuestos)
  private
    FConexion: TUniConnection;
    function CrearConsulta: TUniQuery;
    procedure CargarPorcentajes(AConsulta: TUniQuery;
      out APorcentajes: TPorcentajesImpuestos);
  public
    constructor Create(AConexion: TUniConnection);
    function LeerPorCodigo(const ACodigoIva: string;
      out APorcentajes: TPorcentajesImpuestos): Boolean;
    function LeerPorEmpresa(const ACodigoEmpresa: string;
      out APorcentajes: TPorcentajesImpuestos): Boolean;
    function LeerTipoIvaArticulo(
      const ACodigoArticulo: string): string;
    function LeerRecargoComprasEmpresa(
      const ACodigoEmpresa: string): Boolean;
    function LeerExentoIntracomunitarioProveedor(
      const ACodigoProveedor: string): Boolean;
    function LeerRetencionEmpresa(const ACodigoEmpresa: string;
      AFecha: TDateTime): Double;
  end;

function CrearLecturasImpuestos(
  AConexion: TUniConnection): ILecturasImpuestos;
begin
  Result := nil;
  if Assigned(AConexion) then
    Result := TLecturasImpuestos.Create(AConexion);
end;

constructor TLecturasImpuestos.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLecturasImpuestos.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

procedure TLecturasImpuestos.CargarPorcentajes(
  AConsulta: TUniQuery;
  out APorcentajes: TPorcentajesImpuestos);
begin
  APorcentajes := Default(TPorcentajesImpuestos);
  APorcentajes.CodigoIva :=
    AConsulta.FieldByName('CODIGO_IVA').AsString;
  APorcentajes.IvaNormal := AConsulta.FieldByName('IVAN').AsFloat;
  APorcentajes.IvaReducido := AConsulta.FieldByName('IVAR').AsFloat;
  APorcentajes.IvaSuperReducido :=
    AConsulta.FieldByName('IVAS').AsFloat;
  APorcentajes.IvaExento := AConsulta.FieldByName('IVAE').AsFloat;
  APorcentajes.RecargoNormal := AConsulta.FieldByName('REN').AsFloat;
  APorcentajes.RecargoReducido :=
    AConsulta.FieldByName('RER').AsFloat;
  APorcentajes.RecargoSuperReducido :=
    AConsulta.FieldByName('RES').AsFloat;
  APorcentajes.RecargoExento := AConsulta.FieldByName('REE').AsFloat;
end;

function TLecturasImpuestos.LeerPorCodigo(
  const ACodigoIva: string;
  out APorcentajes: TPorcentajesImpuestos): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  APorcentajes := Default(TPorcentajesImpuestos);
  if (Trim(ACodigoIva) <> '') and (Trim(ACodigoIva) <> '0') then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT CODIGO_IVA, ' +
        '       IFNULL(PORCENTAJE_NORMAL_IVA, 0) AS IVAN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_IVA, 0) AS IVAR, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_IVA, 0) AS IVAS, ' +
        '       IFNULL(PORCENTAJE_EXENTO_IVA, 0) AS IVAE, ' +
        '       IFNULL(PORCENTAJE_NORMAL_RE_IVA, 0) AS REN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_RE_IVA, 0) AS RER, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) AS RES, ' +
        '       IFNULL(PORCENTAJE_EXENTO_RE_IVA, 0) AS REE ' +
        '  FROM fza_ivas ' +
        ' WHERE CODIGO_IVA = :IVA';
      oConsulta.ParamByName('IVA').AsString := ACodigoIva;
      oConsulta.Open;
      Result := not oConsulta.Eof;
      if Result then
        CargarPorcentajes(oConsulta, APorcentajes);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturasImpuestos.LeerPorEmpresa(
  const ACodigoEmpresa: string;
  out APorcentajes: TPorcentajesImpuestos): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  APorcentajes := Default(TPorcentajesImpuestos);
  if (Trim(ACodigoEmpresa) <> '') and
     (Trim(ACodigoEmpresa) <> '0') then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
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
        ' WHERE CODIGO_EMP_EMP = :EMPRESA ' +
        '   AND ESDEFAULT_IVA_IVAGRP = ''S'' ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
      oConsulta.Open;
      Result := not oConsulta.Eof;
      if Result then
        CargarPorcentajes(oConsulta, APorcentajes);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturasImpuestos.LeerTipoIvaArticulo(
  const ACodigoArticulo: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Trim(ACodigoArticulo) <> '' then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT TIPO_IVA_ART ' +
        '  FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :ARTICULO';
      oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := UpperCase(Trim(
          oConsulta.FieldByName('TIPO_IVA_ART').AsString));
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturasImpuestos.LeerRecargoComprasEmpresa(
  const ACodigoEmpresa: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Trim(ACodigoEmpresa) <> '' then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT IFNULL(ESIVA_RECARGO_COMPRAS_EMP, ''N'') AS RECARGO ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :EMPRESA';
      oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('RECARGO').AsString = 'S';
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturasImpuestos.LeerExentoIntracomunitarioProveedor(
  const ACodigoProveedor: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Trim(ACodigoProveedor) <> '' then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT IFNULL(' +
        '  ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''N'') AS EXENTO ' +
        '  FROM fza_proveedores ' +
        ' WHERE CODIGO_PRV_PRV = :PROVEEDOR';
      oConsulta.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('EXENTO').AsString = 'S';
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TLecturasImpuestos.LeerRetencionEmpresa(
  const ACodigoEmpresa: string; AFecha: TDateTime): Double;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if (Trim(ACodigoEmpresa) <> '') and
     (Trim(ACodigoEmpresa) <> '0') then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT IFNULL(PORCENTAJE_EMPRET, 0) AS PORCENTAJE ' +
        '  FROM fza_empresas_retenciones ' +
        ' WHERE CODIGO_EMP_EMPRET = :EMPRESA ' +
        '   AND FECHA_DESDE_EMPRET <= :FECHA ' +
        '   AND (FECHA_HASTA_EMPRET >= :FECHA ' +
        '        OR FECHA_HASTA_EMPRET IS NULL) ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
      oConsulta.ParamByName('FECHA').AsDateTime := AFecha;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('PORCENTAJE').AsFloat;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

end.
