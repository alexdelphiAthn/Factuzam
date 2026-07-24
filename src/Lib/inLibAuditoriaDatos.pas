{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAuditoriaDatos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio que completa los campos estándar de auditoría de un dataset.     }
{******************************************************************************}
unit inLibAuditoriaDatos;

interface

uses
  Data.DB,
  inLibAuditoriaDatosIntf,
  inLibContextoSesionIntf;

type
  TServicioAuditoriaDatos = class(
    TInterfacedObject,
    IServicioAuditoriaDatos
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    function GetUsuario: string;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion
    ); overload;
    constructor Create(const AUsuario: string); overload;
    procedure Actualizar(DataSet: TDataSet);
  end;

implementation

uses
  System.SysUtils,
  inLibContextoSesion;

constructor TServicioAuditoriaDatos.Create(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  inherited Create;
  FContextoSesion := AContextoSesion;
end;

constructor TServicioAuditoriaDatos.Create(const AUsuario: string);
begin
  Create(
    TContextoSesionAplicacion.Create(
      TIdentidadSesion.Crear(AUsuario, '', ''),
      TUbicacionSesion.Crear('', '', '')));
end;

function TServicioAuditoriaDatos.GetUsuario: string;
begin
  Result := '';
  if Assigned(FContextoSesion) then
    Result := FContextoSesion.Identidad.Usuario;
end;

procedure TServicioAuditoriaDatos.Actualizar(DataSet: TDataSet);
var
  Usuario: string;
begin
  Usuario := GetUsuario;
  if Assigned(DataSet) and
     (DataSet.State in dsEditModes) then
  begin
    if DataSet.FindField('USUARIO_MODIF') <> nil then
      DataSet.FieldByName('USUARIO_MODIF').AsString := Usuario;
    if DataSet.State = dsInsert then
    begin
      if DataSet.FindField('INSTANTE_ALTA') <> nil then
        DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
      if DataSet.FindField('USUARIO_ALTA') <> nil then
        DataSet.FieldByName('USUARIO_ALTA').AsString := Usuario;
      if DataSet.FindField('INSTANTE_MODIF') <> nil then
        DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
    end;
  end;
end;

end.
