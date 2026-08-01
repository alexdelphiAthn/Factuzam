{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocumentosTrabajoPresentacion                            }
{    Tipo:       Presentacion                                                  }
{ Version:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adaptador VCL para las decisiones visuales de documentos de trabajo.      }
{******************************************************************************}
unit inLibDocumentosTrabajoPresentacion;

interface

uses
  inLibDocumentosTrabajo;

function CrearInteraccionDocumentosTrabajoVcl:
  IInteraccionDocumentosTrabajo;

implementation

uses
  Winapi.Windows, Vcl.Dialogs, Vcl.Forms,
  inLibMsgVentas;

type
  TInteraccionDocumentosTrabajoVcl = class(
    TInterfacedObject,
    IInteraccionDocumentosTrabajo
  )
  public
    function ElegirDestino: TAccionDocumentoTrabajo;
    function SolicitarTitulo(
      const ATituloPropuesto: string;
      out ATitulo: string): Boolean;
    procedure InformarUnidadAgregada;
  end;

function CrearInteraccionDocumentosTrabajoVcl:
  IInteraccionDocumentosTrabajo;
begin
  Result := TInteraccionDocumentosTrabajoVcl.Create;
end;

function TInteraccionDocumentosTrabajoVcl.ElegirDestino:
  TAccionDocumentoTrabajo;
var
  Respuesta: Integer;
begin
  Respuesta := Application.MessageBox(
    PWideChar(SPreguntaCrearDocumentoTrabajo),
    PWideChar(STituloAgregarDocumentoTrabajo),
    MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON2);
  if Respuesta = IDYES then
  begin
    Result := adtCrear;
  end
  else if Respuesta = IDNO then
  begin
    Result := adtSeleccionar;
  end
  else
  begin
    Result := adtCancelar;
  end;
end;

procedure TInteraccionDocumentosTrabajoVcl.InformarUnidadAgregada;
begin
  Application.MessageBox(
    PWideChar(SInfoUnidadAgregadaDocumentoTrabajo),
    PWideChar(STituloDocumentoTrabajo),
    MB_OK + MB_ICONINFORMATION);
end;

function TInteraccionDocumentosTrabajoVcl.SolicitarTitulo(
  const ATituloPropuesto: string;
  out ATitulo: string): Boolean;
begin
  ATitulo := ATituloPropuesto;
  Result := InputQuery(
    STituloNuevoDocumentoTrabajo,
    SSolicitudTituloDocumentoTrabajo,
    ATitulo);
end;

end.
