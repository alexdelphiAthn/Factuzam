{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesReglas                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de compra reutilizables que no dependen de formularios ni del      }
{    módulo de datos de sesiones.                                              }
{******************************************************************************}
unit inLibComprasSesionesReglas;

interface

uses
  Data.DB, Uni;

function ResolverCodigoFamilia(
  AConexion: TUniConnection;
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
function SanearColorSku(const ATexto: string): string;

implementation

uses
  System.SysUtils;

function ResolverCodigoFamilia(
  AConexion: TUniConnection;
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
var
  iContador: Integer;
  iLongitud: Integer;
  oConsulta: TUniQuery;
  sNumero: string;
begin
  Result := False;
  ACodigoGenerado := '';
  if Trim(ACodigoTecleado) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT CONTADOR_ART_FAM, ESCONTADOR_ART_FAM, ' +
        '       IFNULL(PAD_ART_FAM, 5) AS PAD_ART_FAM ' +
        '  FROM fza_articulos_familias ' +
        ' WHERE CODIGO_FAM_FAM = :p ' +
        '   AND ESACTIVO_FAM = ''S'' ' +
        ' FOR UPDATE';
      oConsulta.ParamByName('p').AsString := ACodigoTecleado;
      oConsulta.Open;
      if not oConsulta.IsEmpty and
         (oConsulta.FieldByName('ESCONTADOR_ART_FAM').AsString = 'S') then
      begin
        iContador :=
          oConsulta.FieldByName('CONTADOR_ART_FAM').AsInteger + 1;
        iLongitud := oConsulta.FieldByName('PAD_ART_FAM').AsInteger;
        if iLongitud < 1 then
          iLongitud := 5;
        oConsulta.Close;
        sNumero := IntToStr(iContador);
        while Length(sNumero) < iLongitud do
          sNumero := '0' + sNumero;
        ACodigoGenerado := ACodigoTecleado + sNumero;
        oConsulta.SQL.Text :=
          'UPDATE fza_articulos_familias SET ' +
          '  CONTADOR_ART_FAM = :c, ' +
          '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
          ' WHERE CODIGO_FAM_FAM = :p';
        oConsulta.ParamByName('c').AsInteger := iContador;
        oConsulta.ParamByName('u').AsString := AUsuario;
        oConsulta.ParamByName('p').AsString := ACodigoTecleado;
        oConsulta.ExecSQL;
        Result := True;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function SanearColorSku(const ATexto: string): string;
var
  cCaracter: Char;
  i: Integer;
  sParcial: string;
begin
  sParcial := UpperCase(Trim(ATexto));
  Result := '';
  for i := 1 to Length(sParcial) do
  begin
    cCaracter := sParcial[i];
    if cCaracter = ' ' then
      Result := Result + '-'
    else if CharInSet(
      cCaracter, ['A'..'Z', '0'..'9', '-', '_']) then
      Result := Result + cCaracter;
  end;
  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);
  while Pos('__', Result) > 0 do
    Result := StringReplace(Result, '__', '_', [rfReplaceAll]);
  while (Result <> '') and
        CharInSet(Result[1], ['-', '_']) do
    Delete(Result, 1, 1);
  while (Result <> '') and
        CharInSet(Result[Length(Result)], ['-', '_']) do
    Delete(Result, Length(Result), 1);
end;

end.
