{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoRestauracionCopiasVcl                                   }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge y presenta la restauración iniciada por la pantalla principal.     }
{******************************************************************************}
unit inMtoRestauracionCopiasVcl;

interface

uses
  System.Classes,
  Vcl.Dialogs,
  inLibOperacionesAplicacionIntf;

type
  TComprobarDDLRestauracion = reference to function(
    const ASQL: string): Boolean;
  TCrearCopiaPreviaRestauracion = reference to function: Boolean;
  TContextoRestauracionCopiasVcl = record
    Owner: TComponent;
    Dialogo: TFileOpenDialog;
    CasoUso: ICasoUsoCopiasSeguridad;
    RutaCopias: string;
    Visible: Boolean;
    ComprobarDDL: TComprobarDDLRestauracion;
    CrearCopiaPrevia: TCrearCopiaPreviaRestauracion;
  end;
  TCoordinadorRestauracionCopiasVcl = class
  private
    class procedure ConfigurarDialogo(
      const AContexto: TContextoRestauracionCopiasVcl); static;
    class function SolicitarOrigen(
      const AContexto: TContextoRestauracionCopiasVcl;
      out ARutaFichero, AContrasena: string): Boolean; static;
    class function LeerCabeceraSql(
      const ARutaFichero: string): string; static;
    class function ConfirmarCopiaPrevia(
      const AContexto: TContextoRestauracionCopiasVcl;
      const ARutaFichero: string): Boolean; static;
  public
    class procedure Ejecutar(
      const AContexto: TContextoRestauracionCopiasVcl); static;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  inMtoModalContrasenaCopia,
  inLibCopiasSeguridadIntf,
  inLibMsgComun,
  inLibMsgConfiguracion;

class procedure TCoordinadorRestauracionCopiasVcl.ConfigurarDialogo(
  const AContexto: TContextoRestauracionCopiasVcl);
var
  bEsAdministrador: Boolean;
  oTipoFichero: TFileTypeItem;
begin
  bEsAdministrador := AContexto.CasoUso.ModoCreacionCopia =
    mpcTextoPlano;
  AContexto.Dialogo.Title := STituloRestaurarCopiaEjecutarScript;
  AContexto.Dialogo.FileTypes.Clear;
  oTipoFichero := AContexto.Dialogo.FileTypes.Add;
  if bEsAdministrador then
  begin
    oTipoFichero.DisplayName := SCaptionFiltroCopiasSqlCifradas;
    oTipoFichero.FileMask := '*.sql;*.crypt';
    AContexto.Dialogo.DefaultExtension := 'sql';
  end
  else
  begin
    oTipoFichero.DisplayName := SCaptionFiltroCopiasScriptsCifrados;
    oTipoFichero.FileMask := '*.crypt';
    AContexto.Dialogo.DefaultExtension := 'crypt';
  end;
  AContexto.Dialogo.DefaultFolder := AContexto.RutaCopias;
  AContexto.Dialogo.Options := AContexto.Dialogo.Options +
    [fdoStrictFileTypes, fdoFileMustExist];
end;

class function TCoordinadorRestauracionCopiasVcl.SolicitarOrigen(
  const AContexto: TContextoRestauracionCopiasVcl;
  out ARutaFichero, AContrasena: string): Boolean;
begin
  ARutaFichero := '';
  AContrasena := '';
  ConfigurarDialogo(AContexto);
  Result := AContexto.Dialogo.Execute;
  if Result then
  begin
    ARutaFichero := AContexto.Dialogo.FileName;
    Result := AContexto.CasoUso.PuedeRestaurar(ARutaFichero);
    if not Result then
      ShowMessage(SErrorTipoRestauracionNoPermitido)
    else if AContexto.CasoUso.RequiereContrasena(
              ARutaFichero) then
      Result := TfrmModalContrasenaCopia.SolicitarExistente(
        AContexto.Owner,
        AContrasena);
  end;
end;

class function TCoordinadorRestauracionCopiasVcl.LeerCabeceraSql(
  const ARutaFichero: string): string;
var
  aBytes: TBytes;
  iBytesALeer: Int64;
  oFichero: TFileStream;
begin
  oFichero := TFileStream.Create(
    ARutaFichero,
    fmOpenRead or fmShareDenyNone);
  try
    iBytesALeer := oFichero.Size;
    if iBytesALeer > 65536 then
      iBytesALeer := 65536;
    SetLength(aBytes, iBytesALeer);
    oFichero.ReadBuffer(aBytes, iBytesALeer);
    Result := TEncoding.UTF8.GetString(aBytes);
  finally
    FreeAndNil(oFichero);
  end;
end;

class function TCoordinadorRestauracionCopiasVcl.ConfirmarCopiaPrevia(
  const AContexto: TContextoRestauracionCopiasVcl;
  const ARutaFichero: string): Boolean;
var
  bCifrada: Boolean;
  bRequiereCopia: Boolean;
  iRespuesta: Integer;
  sPregunta: string;
begin
  bCifrada := AContexto.CasoUso.RequiereContrasena(ARutaFichero);
  bRequiereCopia := bCifrada;
  sPregunta := SPreguntaCopiaAntesRestaurarCifrada;
  if not bCifrada then
  begin
    bRequiereCopia := AContexto.ComprobarDDL(
      LeerCabeceraSql(ARutaFichero));
    sPregunta := SPreguntaCopiaSeguridadAntesDDL;
  end;
  Result := True;
  if bRequiereCopia then
  begin
    iRespuesta := MessageDlg(
      sPregunta,
      mtWarning,
      [mbYes, mbNo, mbCancel],
      0);
    case iRespuesta of
      mrYes:
        Result := AContexto.CrearCopiaPrevia();
      mrCancel:
        Result := False;
    end;
    if not Result then
      ShowMessage(SInfoScriptCancelado);
  end;
end;

class procedure TCoordinadorRestauracionCopiasVcl.Ejecutar(
  const AContexto: TContextoRestauracionCopiasVcl);
var
  bContinuar: Boolean;
  sContrasena: string;
  sRutaFichero: string;
begin
  if AContexto.Visible then
  begin
    bContinuar := SolicitarOrigen(
      AContexto,
      sRutaFichero,
      sContrasena);
    if bContinuar then
      bContinuar := ConfirmarCopiaPrevia(
        AContexto,
        sRutaFichero);
    if bContinuar then
      AContexto.CasoUso.IniciarRestauracion(
        sRutaFichero,
        sContrasena);
  end;
end;

end.
