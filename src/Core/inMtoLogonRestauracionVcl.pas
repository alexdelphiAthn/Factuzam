{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLogonRestauracionVcl                                    }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge la restauración solicitada desde la pantalla de conexión.          }
{******************************************************************************}
unit inMtoLogonRestauracionVcl;

interface

uses
  Vcl.Dialogs,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexionIntf;

type
  TEstablecerContrasenaConexion = reference to procedure(
    const AContrasena: string);
  TMostrarPreparacionRestauracion = reference to procedure;
  TContextoLogonRestauracionVcl = record
    Dialogo: TFileOpenDialog;
    CasoUso: ICasoUsoRestauracionConexion;
    Host: string;
    Puerto: string;
    BaseDatos: string;
    Usuario: string;
    OnPrepararWorker: TPrepararWorkerRestauracionEvent;
    OnProgreso: TProgresoCopiaSeguridadEvent;
    OnFinalizar: TFinalizarCopiaSeguridadEvent;
    EstablecerContrasena: TEstablecerContrasenaConexion;
    MostrarPreparacion: TMostrarPreparacionRestauracion;
  end;
  TCoordinadorLogonRestauracionVcl = class
  private
    class procedure ConfigurarDialogo(
      ADialogo: TFileOpenDialog); static;
  public
    class procedure Ejecutar(
      const AContexto: TContextoLogonRestauracionVcl); static;
  end;

implementation

uses
  System.SysUtils,
  inLibDir,
  inLibMsgComun,
  inLibMsgConfiguracion;

class procedure TCoordinadorLogonRestauracionVcl.ConfigurarDialogo(
  ADialogo: TFileOpenDialog);
var
  oTipoFichero: TFileTypeItem;
begin
  ADialogo.Title := STituloCargarCopiaSeguridad;
  ADialogo.FileTypes.Clear;
  oTipoFichero := ADialogo.FileTypes.Add;
  oTipoFichero.DisplayName := SCaptionFiltroCopiasSqlEncriptadas;
  oTipoFichero.FileMask := '*.sql;*.crypt';
  oTipoFichero := ADialogo.FileTypes.Add;
  oTipoFichero.DisplayName := SCaptionFiltroTodosArchivos;
  oTipoFichero.FileMask := '*.*';
  ADialogo.DefaultExtension := 'sql';
  ADialogo.DefaultFolder := GetUserDeskFolder;
end;

class procedure TCoordinadorLogonRestauracionVcl.Ejecutar(
  const AContexto: TContextoLogonRestauracionVcl);
var
  oSolicitud: TSolicitudRestauracionConexion;
  sContrasena: string;
begin
  sContrasena := InputBox(SGetPassBBDD, '', '');
  AContexto.EstablecerContrasena(sContrasena);
  ConfigurarDialogo(AContexto.Dialogo);
  if AContexto.Dialogo.Execute then
  begin
    oSolicitud := Default(TSolicitudRestauracionConexion);
    oSolicitud.Host := AContexto.Host;
    oSolicitud.Puerto := StrToIntDef(AContexto.Puerto, 3306);
    oSolicitud.BaseDatos := AContexto.BaseDatos;
    oSolicitud.Usuario := AContexto.Usuario;
    oSolicitud.ContrasenaConexion := sContrasena;
    oSolicitud.RutaFichero := AContexto.Dialogo.FileName;
    if SameText(
         ExtractFileExt(oSolicitud.RutaFichero),
         '.crypt') then
      oSolicitud.ContrasenaCopia := sContrasena;
    AContexto.MostrarPreparacion();
    AContexto.CasoUso.Ejecutar(
      oSolicitud,
      AContexto.OnPrepararWorker,
      AContexto.OnProgreso,
      AContexto.OnFinalizar);
  end
  else
    ShowMessage(SCargaScriptCancelada);
end;

end.
