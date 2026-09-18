{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionScripts                                     }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Averigua qué scripts de esquema faltan en esta base y los aplica.         }
{******************************************************************************}
unit inLibActualizacionScripts;

interface

uses
  Uni,
  inLibActualizacionScriptsLectura;

type
  TScriptFaltante = inLibActualizacionScriptsLectura.TScriptFaltante;

// Lee un .sql sin dar por hecho que viene en UTF-8: los scripts antiguos
// pueden estar en la pagina de codigos del equipo.
function LeerTextoScriptSql(const ARuta: string): string;
function ConsultarScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string;
  out AFaltantes: TArray<TScriptFaltante>;
  out AError: string): Boolean;
// Ejecuta el contenido de ARutaSql comprobando antes su huella SHA-256.
function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;

implementation

uses
  System.Hash,
  System.IOUtils,
  System.SysUtils,
  UniScript,
  inLibMsgIntegraciones;

function LeerTextoScriptSql(const ARuta: string): string;
var
  aDatos: TBytes;
  iPreambulo: Integer;
  oCodificacion: TEncoding;
begin
  aDatos := TFile.ReadAllBytes(ARuta);
  oCodificacion := nil;
  iPreambulo := TEncoding.GetBufferEncoding(
    aDatos,
    oCodificacion,
    TEncoding.UTF8);
  try
    Result := oCodificacion.GetString(
      aDatos,
      iPreambulo,
      Length(aDatos) - iPreambulo);
  except
    on E: EEncodingError do
      Result := TEncoding.ANSI.GetString(aDatos);
  end;
end;

function ConsultarScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string;
  out AFaltantes: TArray<TScriptFaltante>;
  out AError: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AFaltantes := nil;
  AError := '';
  if not Assigned(AConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if Trim(ASqlComprobacion) = '' then
    AError := SErrorComprobacionScriptsVacia
  else
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text := ASqlComprobacion;
        oConsulta.Open;
        AFaltantes := LeerScriptsFaltantes(oConsulta);
        Result := True;
      except
        on E: Exception do
          AError := E.ClassName + ': ' + E.Message;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;
var
  oScript: TUniScript;
  sContenido: string;
  sHuella: string;
begin
  Result := False;
  AError := '';
  if not Assigned(AConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if not TFile.Exists(ARutaSql) then
    AError := Format(SErrorScriptActualizacionAusente, [ARutaSql])
  else
  begin
    try
      sHuella := LowerCase(THashSHA2.GetHashStringFromFile(ARutaSql));
      if (Trim(ASha256) <> '') and not SameText(sHuella, Trim(ASha256)) then
        AError := SErrorHuellaScriptActualizacionNoCoincide
      else
      begin
        sContenido := LeerTextoScriptSql(ARutaSql);
        if Trim(sContenido) = '' then
          AError := Format(SErrorScriptActualizacionVacio, [ARutaSql])
        else
        begin
          oScript := TUniScript.Create(nil);
          try
            oScript.Connection := AConexion;
            oScript.SQL.Text := sContenido;
            oScript.Execute;
            Result := True;
          finally
            oScript.Free;
          end;
        end;
      end;
    except
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
