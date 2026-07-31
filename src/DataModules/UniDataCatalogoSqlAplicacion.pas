{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCatalogoSqlAplicacion                                  }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone el registro completo de definiciones SQL de la aplicación.        }
{******************************************************************************}
unit UniDataCatalogoSqlAplicacion;

interface

uses
  inLibCatalogoSqlIntf,
  inLibPerfilesUsuarioIntf;

function CrearRegistroDefinicionesSqlAplicacion:
  IRegistroDefinicionesSql;
procedure CrearCatalogoSqlAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  AActivo: Boolean;
  out ACatalogo: ICatalogoSql;
  out AIncidencias: IRegistroIncidenciasSql);

implementation

uses
  System.SysUtils,
  inLibCatalogoSqlRegistro,
  inLibCatalogoSqlIncidencias,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlAdmin,
  inLibLog,
  UniDataComprasSesionesMaterializacionRepositorio,
  UniDataComprasSesionesRepositorio,
  UniDataFacturasRepositorio,
  UniDataCajaConsultasRepositorio,
  UniDataArticulosResolverRepositorio,
  UniDataArticulosValidadorRepositorio,
  UniDataArticulosAtributosRepositorio,
  UniDataTraspasoTicketRepositorio,
  UniDataArqueoRepositorio,
  UniDataArqueoTicketRepositorio,
  UniDataTiraCajaTicketRepositorio,
  UniDataTicketsCajaRepositorio;

resourcestring
  SErrorCatalogoSqlAplicacion =
    'No se pudo cargar el catálogo SQL compartido. ' +
    'Se usará el SQL base. Error=%s';

function CrearRegistroDefinicionesSqlAplicacion:
  IRegistroDefinicionesSql;
var
  oRegistro: TRegistroDefinicionesSql;
begin
  oRegistro := TRegistroDefinicionesSql.Create;
  oRegistro.AgregarRango(
    TRepositorioComprasSesiones.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioLecturasMaterializacionComprasSesiones.
      DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioFacturas.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioConsultasCaja.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioArticulosResolver.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioArticulosValidador.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioArticulosAtributos.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioTraspasoTicket.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioArqueoCaja.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioArqueoTicket.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioTiraCajaTicket.DefinicionesSql);
  oRegistro.AgregarRango(
    TRepositorioTicketsCaja.DefinicionesSql);
  Result := oRegistro;
end;

procedure CrearCatalogoSqlAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const APerfilesEscritura: IEscritorPerfilesUsuario;
  AActivo: Boolean;
  out ACatalogo: ICatalogoSql;
  out AIncidencias: IRegistroIncidenciasSql);
var
  oAdministrador: TAdministradorSqlPerfiles;
  oPerfil: TProfileDicc;
  oRegistro: IRegistroDefinicionesSql;
begin
  ACatalogo := nil;
  AIncidencias := TRegistroIncidenciasSql.Create;
  oPerfil := nil;
  if AActivo and
     Assigned(APerfilesLectura) and
     Assigned(APerfilesEscritura) then
  begin
    try
      oRegistro :=
        CrearRegistroDefinicionesSqlAplicacion;
      oAdministrador := TAdministradorSqlPerfiles.Create(
        APerfilesLectura,
        APerfilesEscritura);
      try
        oAdministrador.PublicarCatalogo(
          oRegistro);
      finally
        FreeAndNil(oAdministrador);
      end;
      APerfilesLectura.CargarPerfilFormulario(
        CLAVE_PERFIL_CATALOGO_SQL,
        PERFIL_TODOS,
        PERFIL_TODOS,
        oPerfil);
    except
      on E: Exception do
      begin
        FreeAndNil(oPerfil);
        if Log() <> nil then
          Log.LogError(
            Format(
              SErrorCatalogoSqlAplicacion,
              [E.Message]));
      end;
    end;
  end;
  try
    ACatalogo := TCatalogoSqlPerfiles.Create(
      oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
end;

end.
