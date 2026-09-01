{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesCodigoArticulo                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Evalúa la fórmula configurable del código de artículo de una sesión.      }
{******************************************************************************}
unit inLibComprasSesionesCodigoArticulo;

interface

uses
  System.SysUtils;

const
  CLAVE_FORMULA_CODIGO_ARTICULO_SESION =
    'appFormulaCodigoArticuloSesion';
  FORMULA_CODIGO_ARTICULO_SESION_DEFECTO =
    '{CodFamilia}{ContadorFamilia}';
  FORMULA_CODIGO_ARTICULO_MODELO_PROVEEDOR =
    '{ModeloProv}-{CodProv}';
  LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION = 20;

type
  EFormulaCodigoArticuloSesion = class(Exception);

  TValoresFormulaCodigoArticuloSesion = record
    CodFamilia: string;
    ContadorFamilia: string;
    ModeloProv: string;
    CodProv: string;
  end;

  TFormulaCodigoArticuloSesion = class sealed
  private
    class function EsParametroValido(
      const AParametro: string): Boolean; static;
    class function Sustituir(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
    class function UsaParametro(
      const AFormula, AParametro: string): Boolean; static;
    class function ValorParametro(
      const AParametro: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
  public
    class function Normalizar(const AFormula: string): string; static;
    class procedure Validar(const AFormula: string); static;
    class function UsaContadorFamilia(
      const AFormula: string): Boolean; static;
    class function UsaDatosFamilia(
      const AFormula: string): Boolean; static;
    class function UsaModeloProveedor(
      const AFormula: string): Boolean; static;
    class function UsaCodigoProveedor(
      const AFormula: string): Boolean; static;
    class function PuedeEvaluar(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): Boolean; static;
    class function Evaluar(
      const AFormula: string;
      const AValores: TValoresFormulaCodigoArticuloSesion): string; static;
  end;

implementation

uses
  System.StrUtils,
  inLibMsgCompras;

class function TFormulaCodigoArticuloSesion.Normalizar(
  const AFormula: string): string;
begin
  Result := Trim(AFormula);
  if Result = '' then
    Result := FORMULA_CODIGO_ARTICULO_SESION_DEFECTO;
end;

class function TFormulaCodigoArticuloSesion.EsParametroValido(
  const AParametro: string): Boolean;
begin
  Result := SameText(AParametro, 'CodFamilia') or
            SameText(AParametro, 'ContadorFamilia') or
            SameText(AParametro, 'ModeloProv') or
            SameText(AParametro, 'CodProv');
end;

class function TFormulaCodigoArticuloSesion.UsaParametro(
  const AFormula, AParametro: string): Boolean;
begin
  Validar(AFormula);
  Result := ContainsText(
    Normalizar(AFormula),
    '{' + AParametro + '}');
end;

class function TFormulaCodigoArticuloSesion.ValorParametro(
  const AParametro: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
begin
  Result := '';
  if SameText(AParametro, 'CodFamilia') then
    Result := AValores.CodFamilia
  else if SameText(AParametro, 'ContadorFamilia') then
    Result := AValores.ContadorFamilia
  else if SameText(AParametro, 'ModeloProv') then
    Result := AValores.ModeloProv
  else if SameText(AParametro, 'CodProv') then
    Result := AValores.CodProv;
  Result := Trim(Result);
end;

class procedure TFormulaCodigoArticuloSesion.Validar(
  const AFormula: string);
var
  iFin: Integer;
  iPosicion: Integer;
  iParametros: Integer;
  sFormula: string;
  sParametro: string;
begin
  sFormula := Normalizar(AFormula);
  iParametros := 0;
  iPosicion := 1;
  while iPosicion <= Length(sFormula) do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      if iFin = 0 then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      if (sParametro = '') or
         (Pos('{', sParametro) > 0) then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      if not EsParametroValido(sParametro) then
        raise EFormulaCodigoArticuloSesion.CreateFmt(
          SErrorFormulaCodigoArticuloParametro,
          [sParametro]);
      Inc(iParametros);
      iPosicion := iFin + 1;
    end
    else
    begin
      if sFormula[iPosicion] = '}' then
        raise EFormulaCodigoArticuloSesion.Create(
          SErrorFormulaCodigoArticuloLlaves);
      Inc(iPosicion);
    end;
  end;
  if iParametros = 0 then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloSinParametros);
end;

class function TFormulaCodigoArticuloSesion.UsaContadorFamilia(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'ContadorFamilia');
end;

class function TFormulaCodigoArticuloSesion.UsaDatosFamilia(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'CodFamilia') or
            UsaContadorFamilia(AFormula);
end;

class function TFormulaCodigoArticuloSesion.UsaModeloProveedor(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'ModeloProv');
end;

class function TFormulaCodigoArticuloSesion.UsaCodigoProveedor(
  const AFormula: string): Boolean;
begin
  Result := UsaParametro(AFormula, 'CodProv');
end;

class function TFormulaCodigoArticuloSesion.PuedeEvaluar(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): Boolean;
var
  iFin: Integer;
  iPosicion: Integer;
  sFormula: string;
  sParametro: string;
begin
  Validar(AFormula);
  Result := True;
  sFormula := Normalizar(AFormula);
  iPosicion := 1;
  while (iPosicion <= Length(sFormula)) and Result do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      Result := ValorParametro(sParametro, AValores) <> '';
      iPosicion := iFin + 1;
    end
    else
      Inc(iPosicion);
  end;
end;

class function TFormulaCodigoArticuloSesion.Sustituir(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
var
  iFin: Integer;
  iPosicion: Integer;
  sFormula: string;
  sParametro: string;
begin
  Result := '';
  sFormula := Normalizar(AFormula);
  iPosicion := 1;
  while iPosicion <= Length(sFormula) do
  begin
    if sFormula[iPosicion] = '{' then
    begin
      iFin := PosEx('}', sFormula, iPosicion + 1);
      sParametro := Copy(
        sFormula,
        iPosicion + 1,
        iFin - iPosicion - 1);
      Result := Result + ValorParametro(sParametro, AValores);
      iPosicion := iFin + 1;
    end
    else
    begin
      Result := Result + sFormula[iPosicion];
      Inc(iPosicion);
    end;
  end;
  Result := Trim(Result);
end;

class function TFormulaCodigoArticuloSesion.Evaluar(
  const AFormula: string;
  const AValores: TValoresFormulaCodigoArticuloSesion): string;
begin
  Validar(AFormula);
  if not PuedeEvaluar(AFormula, AValores) then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloDatos);
  Result := Sustituir(AFormula, AValores);
  if Result = '' then
    raise EFormulaCodigoArticuloSesion.Create(
      SErrorFormulaCodigoArticuloResultadoVacio);
  if Length(Result) > LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION then
    raise EFormulaCodigoArticuloSesion.CreateFmt(
      SErrorFormulaCodigoArticuloLongitud,
      [Result, Length(Result), LONGITUD_MAXIMA_CODIGO_ARTICULO_SESION]);
end;

end.
