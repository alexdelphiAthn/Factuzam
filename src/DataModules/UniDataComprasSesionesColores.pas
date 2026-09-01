{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesColores                                }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve y persiste colores al materializar sesiones de compra.           }
{******************************************************************************}
unit UniDataComprasSesionesColores;

interface

uses
  Uni,
  inLibComprasSesionesLecturasIntf;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AColorTexto, ACodigoAtbColor, AUsuario: string;
  out AValor: string): Integer; overload;
function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AColorTexto, ACodigoAtbColor, AUsuario: string;
  out AValor: string;
  out AIdColorBasico: Integer): Integer; overload;

implementation

uses
  System.SysUtils,
  inLibComprasSesionesReglas,
  inLibMsgCompras;

function ResolverIdColorBasico(
  const ALecturas: ILecturasArticulosMaterializacion;
  const ACodigoAtbColor: string): Integer;
begin
  Result := 0;
  if Trim(ACodigoAtbColor) <> '' then
  begin
    Result := ALecturas.ObtenerIdColorBasico(ACodigoAtbColor);
    if Result = 0 then
      raise Exception.CreateFmt(
        SErrorColorBasicoMaterializacionNoExiste,
        [ACodigoAtbColor]);
  end;
end;

function BuscarValorColor(
  const ALecturas: ILecturasArticulosMaterializacion;
  const AValor: string;
  out ATieneColorBasico: Boolean;
  out AIdColorBasico: Integer): Integer;
var
  oValor: TValorColorMaterializacion;
begin
  oValor := ALecturas.BuscarValorColor(AValor);
  Result := oValor.IdValor;
  ATieneColorBasico := oValor.TieneColorBasico;
  AIdColorBasico := oValor.IdColorBasico;
end;

procedure AsignarColorBasicoAValor(
  AQuery: TUniQuery;
  AIdValor, AIdColorBasico: Integer);
begin
  AQuery.SQL.Text :=
    'UPDATE fza_atributos_valores ' +
    '   SET ID_ATB_AV = :ia ' +
    ' WHERE ID_AV = :idav';
  AQuery.ParamByName('ia').AsInteger := AIdColorBasico;
  AQuery.ParamByName('idav').AsInteger := AIdValor;
  AQuery.ExecSQL;
end;

function CrearValorColor(
  AQuery: TUniQuery;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AValor, ADescripcion, AUsuario: string;
  AIdColorBasico: Integer): Integer;
var
  oValor: TValorColorMaterializacion;
begin
  if AIdColorBasico > 0 then
  begin
    AQuery.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, DESCRIPCION_AV, ID_ATB_AV, ' +
      '   ESACTIVO_AV, ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (''CO'', :v, :d, :ia, ''S'', 0, ' +
      '        NOW(), :u, NOW(), :u)';
    AQuery.ParamByName('ia').AsInteger := AIdColorBasico;
  end
  else
    AQuery.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, DESCRIPCION_AV, ESACTIVO_AV, ORDEN_AV, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (''CO'', :v, :d, ''S'', 0, NOW(), :u, NOW(), :u)';
  AQuery.ParamByName('v').AsString := AValor;
  AQuery.ParamByName('d').AsString := Trim(ADescripcion);
  AQuery.ParamByName('u').AsString := AUsuario;
  AQuery.ExecSQL;
  oValor := ALecturas.BuscarValorColor(AValor);
  Result := oValor.IdValor;
end;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AColorTexto, ACodigoAtbColor, AUsuario: string;
  out AValor: string): Integer;
var
  iIdColorBasico: Integer;
begin
  Result := ResolverIdAvColorLinea(
    AConn,
    ALecturas,
    AColorTexto,
    ACodigoAtbColor,
    AUsuario,
    AValor,
    iIdColorBasico);
end;

function ResolverIdAvColorLinea(
  AConn: TUniConnection;
  const ALecturas: ILecturasArticulosMaterializacion;
  const AColorTexto, ACodigoAtbColor, AUsuario: string;
  out AValor: string;
  out AIdColorBasico: Integer): Integer;
var
  q                 : TUniQuery;
  sValor            : string;
  iIdColorGlobal    : Integer;
  bTieneColorBasico : Boolean;
begin
  Result := 0;
  AValor := '';
  AIdColorBasico := 0;
  sValor := SanearColorSku(AColorTexto);
  if sValor = '' then
    sValor := SanearColorSku(ACodigoAtbColor);
  if sValor <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      AIdColorBasico :=
        ResolverIdColorBasico(ALecturas, ACodigoAtbColor);
      Result := BuscarValorColor(
        ALecturas, sValor, bTieneColorBasico,
        iIdColorGlobal);
      if AIdColorBasico = 0 then
        AIdColorBasico := iIdColorGlobal;
      if Result = 0 then
        Result := CrearValorColor(
          q, ALecturas, sValor, AColorTexto, AUsuario,
          AIdColorBasico)
      else if (not bTieneColorBasico) and
              (AIdColorBasico > 0) then
        AsignarColorBasicoAValor(
          q, Result, AIdColorBasico);
      if Result > 0 then
        AValor := sValor;
    finally
      FreeAndNil(q);
    end;
  end;
end;

end.
