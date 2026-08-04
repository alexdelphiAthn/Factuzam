{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMetadatosBBDDRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Acceso UniDAC al catálogo de metadatos de la base de datos.               }
{******************************************************************************}
unit UniDataMetadatosBBDDRepositorio;

interface

uses
  Uni,
  inLibMetadatosBBDDIntf;

function CrearCatalogoMetadatosBBDDUniDAC(
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoMetadatosBBDD;

implementation

uses
  System.SysUtils;

type
  TCatalogoMetadatosBBDDUniDAC = class(
    TInterfacedObject,
    ICatalogoMetadatosBBDD)
  private
    FContenido: TUniQuery;
    FEstructura: TUniQuery;
    FMetadatos: TUniQuery;
    FRefresco: TUniStoredProc;
    function IdentificadorSeguro(const AValor: string): string;
  public
    constructor Create(
      AMetadatos, AEstructura, AContenido: TUniQuery;
      ARefresco: TUniStoredProc);
    procedure Refrescar(const ABaseDatos: string);
    function CargarEstructura(
      const ATipo, ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
  end;

constructor TCatalogoMetadatosBBDDUniDAC.Create(
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc);
begin
  inherited Create;
  if not Assigned(AMetadatos) then
    raise EArgumentNilException.Create('AMetadatos');
  if not Assigned(AEstructura) then
    raise EArgumentNilException.Create('AEstructura');
  if not Assigned(AContenido) then
    raise EArgumentNilException.Create('AContenido');
  if not Assigned(ARefresco) then
    raise EArgumentNilException.Create('ARefresco');
  FMetadatos := AMetadatos;
  FEstructura := AEstructura;
  FContenido := AContenido;
  FRefresco := ARefresco;
end;

function TCatalogoMetadatosBBDDUniDAC.IdentificadorSeguro(
  const AValor: string): string;
var
  i: Integer;
begin
  Result := Trim(AValor);
  if Result = '' then
    raise EArgumentException.Create(
      'El identificador no puede estar vacío');
  for i := 1 to Length(Result) do
  begin
    if not CharInSet(
      Result[i],
      ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      raise EArgumentException.CreateFmt(
        'Identificador de base de datos no válido: %s',
        [Result]);
  end;
end;

procedure TCatalogoMetadatosBBDDUniDAC.Refrescar(
  const ABaseDatos: string);
begin
  FRefresco.ParamByName('pDATABASENAME').AsString := ABaseDatos;
  FRefresco.ExecProc;
  if FMetadatos.Active then
    FMetadatos.Refresh
  else
    FMetadatos.Open;
end;

function TCatalogoMetadatosBBDDUniDAC.CargarEstructura(
  const ATipo, ANombre: string): string;
var
  sCampoResultado: string;
begin
  Result := '';
  FEstructura.Close;
  if ATipo = '1' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create Table';
  end
  else if ATipo = '2' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create View';
  end
  else if ATipo = '3' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create Procedure';
  end
  else
    sCampoResultado := '';
  if sCampoResultado <> '' then
  begin
    FEstructura.Open;
    Result := FEstructura.FieldByName(sCampoResultado).AsString;
  end;
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarContenido(
  const ANombre: string);
begin
  FContenido.Close;
  FContenido.SQL.Text := 'SELECT * FROM ' +
    IdentificadorSeguro(ANombre);
  FContenido.Open;
end;

function CrearCatalogoMetadatosBBDDUniDAC(
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoMetadatosBBDD;
begin
  Result := TCatalogoMetadatosBBDDUniDAC.Create(
    AMetadatos,
    AEstructura,
    AContenido,
    ARefresco);
end;

end.
