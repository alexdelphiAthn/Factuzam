{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocumentosTrabajo                                        }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       21/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Operaciones compartidas para Documentos de Trabajo.                       }
{    Permite agregar articulos/SKUs desde stock o desde formularios que ya     }
{    resuelven el articulo activo igual que Ctrl+U / Ctrl+F.                   }
{******************************************************************************}
unit inLibDocumentosTrabajo;

interface

uses
  System.SysUtils, System.Classes, Data.DB, DBAccess, Uni,
  inLibContextoSesionIntf, inLibParametrosIntf,
  inLibArticulosResolverIntf, inLibGenBusq;

type
  TResolverDocTrabajoArtSku = procedure(out ACodArt, ACodSku: string) of object;

  TDocTrabajoLineaOrigen = record
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoAlmacen: string;
    Lote: string;
    DescripcionArticulo: string;
    DescripcionSku: string;
    Origen: string;
    FechaCaducidad: TDateTime;
    CantidadStock: Double;
    Cantidad: Double;
    procedure Clear;
  end;
  ILecturasDocumentosTrabajo = interface
    ['{F3A03012-91E0-4BDA-B47F-53CE11A624B8}']
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
  end;
  IEscrituraDocumentosTrabajo = interface
    ['{B911B05D-E00B-41FC-9B22-C0BB317A3201}']
    function CrearDocumento(const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
  end;
  TRepositoriosDocumentosTrabajo = record
    Lecturas: ILecturasDocumentosTrabajo;
    Escritura: IEscrituraDocumentosTrabajo;
  end;
  TAccionDocumentoTrabajo = (
    adtCancelar,
    adtCrear,
    adtSeleccionar
  );
  IInteraccionDocumentosTrabajo = interface
    ['{6B74E0A2-0AA6-4E5B-9818-F706FB8F2A40}']
    function ElegirDestino: TAccionDocumentoTrabajo;
    function SolicitarTitulo(
      const ATituloPropuesto: string;
      out ATitulo: string): Boolean;
    procedure InformarUnidadAgregada;
  end;

function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const ARepositorios:
                                        TRepositoriosDocumentosTrabajo;
                                        const AInteraccion:
                                        IInteraccionDocumentosTrabajo;
                                        const ABusquedaVisual:
                                        IBusquedaVisual;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const AParametrosCaja:
                                        IParametrosCaja;
                                        const ALinea: TDocTrabajoLineaOrigen;
                                        const AResolverArticulos:
                                        IArticulosResolver):
                                        Boolean;
function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const ARepositorios:
                                                TRepositoriosDocumentosTrabajo;
                                                const AInteraccion:
                                                IInteraccionDocumentosTrabajo;
                                                const ABusquedaVisual:
                                                IBusquedaVisual;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                const AParametrosCaja:
                                                IParametrosCaja;
                                                AResolver:
                                                TResolverDocTrabajoArtSku;
                                                const AResolverArticulos:
                                                IArticulosResolver):
                                                Boolean;

implementation

uses
  Vcl.Forms,
  inLibMsgArticulos, inLibMsgVentas;

procedure TDocTrabajoLineaOrigen.Clear;
begin
  CodigoArticulo := '';
  CodigoSku := '';
  CodigoAlmacen := '';
  Lote := '';
  DescripcionArticulo := '';
  DescripcionSku := '';
  Origen := '';
  FechaCaducidad := 0;
  CantidadStock := 0;
  Cantidad := 0;
end;

function CrearDocumentoTrabajo(
                               const ARepositorio:
                               IEscrituraDocumentosTrabajo;
                               const AContextoSesion:
                               IContextoSesionAplicacion;
                               const ATitulo: string): Int64;
var
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  Result := 0;
  Identidad := AContextoSesion.Identidad;
  Ubicacion := AContextoSesion.Ubicacion;
  if ARepositorio <> nil then
    Result := ARepositorio.CrearDocumento(
      ATitulo,
      Ubicacion.Empresa,
      Ubicacion.Almacen,
      Identidad.Usuario);
end;

function SeleccionarDocumentoTrabajo(AOwner: TComponent;
                                     AConexion: TUniConnection;
                                     const ARepositorios:
                                     TRepositoriosDocumentosTrabajo;
                                     const AInteraccion:
                                     IInteraccionDocumentosTrabajo;
                                     const ABusquedaVisual:
                                     IBusquedaVisual;
                                     const AContextoSesion:
                                     IContextoSesionAplicacion;
                                     out AIdDtr: Int64): Boolean;
var
  Accion: TAccionDocumentoTrabajo;
  sTitulo: string;
  sId: string;
  sConsulta: string;
  frmParent: TCustomForm;
begin
  Result := False;
  AIdDtr := 0;
  frmParent := nil;
  if AOwner is TCustomForm then
  begin
    frmParent := TCustomForm(AOwner);
  end;
  Accion := adtCancelar;
  if Assigned(AInteraccion) then
  begin
    Accion := AInteraccion.ElegirDestino;
  end;
  if Accion = adtCrear then
  begin
    sTitulo := 'Documento de trabajo ' +
      FormatDateTime('dd/mm/yyyy hh:nn', Now);
    if Assigned(AInteraccion) and
       AInteraccion.SolicitarTitulo(sTitulo, sTitulo) then
    begin
      if Trim(sTitulo) <> '' then
      begin
        AIdDtr := CrearDocumentoTrabajo(
          ARepositorios.Escritura,
          AContextoSesion,
          Trim(sTitulo));
        Result := AIdDtr > 0;
      end;
    end;
  end
  else if Accion = adtSeleccionar then
  begin
    sConsulta := '';
    if ARepositorios.Lecturas <> nil then
      sConsulta := ARepositorios.Lecturas.ConsultaDocumentosAbiertos(
        AContextoSesion.Identidad.Usuario);
    if ABusquedaVisual.EjecutarBusqueda(AConexion,
                                       'Documentos de Trabajo abiertos',
                                       sConsulta, 'ID_DTR', sId,
                                       'frmBuscarDocumentosTrabajo',
                                       frmParent) then
    begin
      AIdDtr := StrToInt64Def(sId, 0);
      Result := AIdDtr > 0;
    end;
  end;
end;

procedure CompletarDatosArticulo(
                                 const ARepositorio:
                                 ILecturasDocumentosTrabajo;
                                 var ALinea: TDocTrabajoLineaOrigen);
begin
  if ARepositorio <> nil then
    ARepositorio.CompletarDatosArticulo(ALinea);
end;

procedure ResolverSkuSiEsUnico(
  const AResolverArticulos: IArticulosResolver;
  var ALinea: TDocTrabajoLineaOrigen);
var
  oDatos: TArticuloDatos;
begin
  if Assigned(AResolverArticulos) and
     (Trim(ALinea.CodigoArticulo) <> '') and
     (Trim(ALinea.CodigoSku) = '') then
  begin
    oDatos := AResolverArticulos.ResolverDatos(
      ALinea.CodigoArticulo,
      '',
      '',
      Date,
      ALinea.CodigoAlmacen);
    if oDatos.Encontrado and
       (not oDatos.RequiereSku) then
    begin
      ALinea.CodigoSku := oDatos.CodigoSku;
      if Trim(ALinea.DescripcionArticulo) = '' then
      begin
        ALinea.DescripcionArticulo :=
          oDatos.DescripcionArticulo;
      end;
      if Trim(ALinea.DescripcionSku) = '' then
      begin
        ALinea.DescripcionSku :=
          oDatos.DescripcionSku;
      end;
    end;
  end;
end;

procedure InsertarLineaDocumentoTrabajo(
                                        const ARepositorio:
                                        IEscrituraDocumentosTrabajo;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        AIdDtr: Int64;
                                        const ALinea:
                                        TDocTrabajoLineaOrigen);
begin
  if ARepositorio <> nil then
    ARepositorio.InsertarLinea(
      AIdDtr,
      ALinea,
      AContextoSesion.Identidad.Usuario);
end;

function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const ARepositorios:
                                        TRepositoriosDocumentosTrabajo;
                                        const AInteraccion:
                                        IInteraccionDocumentosTrabajo;
                                        const ABusquedaVisual:
                                        IBusquedaVisual;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const AParametrosCaja:
                                        IParametrosCaja;
                                        const ALinea: TDocTrabajoLineaOrigen;
                                        const AResolverArticulos:
                                        IArticulosResolver):
                                        Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
  iIdDtr: Int64;
begin
  Result := False;
  rLinea := ALinea;
  ResolverSkuSiEsUnico(
    AResolverArticulos,
    rLinea);
  if Trim(rLinea.CodigoArticulo) = '' then
  begin
    raise Exception.Create(SErrorArticuloDocumentoTrabajoNoActivo);
  end;
  if Trim(rLinea.CodigoSku) = '' then
  begin
    raise Exception.Create(SErrorArticuloDocumentoTrabajoVariosSkus);
  end;
  CompletarDatosArticulo(ARepositorios.Lecturas, rLinea);
  if Trim(rLinea.Origen) = '' then
  begin
    rLinea.Origen := 'MANUAL';
  end;
  if SeleccionarDocumentoTrabajo(
    AOwner, AConexion, ARepositorios, AInteraccion, ABusquedaVisual,
    AContextoSesion, iIdDtr) then
  begin
    InsertarLineaDocumentoTrabajo(
      ARepositorios.Escritura,
      AContextoSesion,
      iIdDtr,
      rLinea);
    if Assigned(AInteraccion) then
    begin
      AInteraccion.InformarUnidadAgregada;
    end;
    Result := True;
  end;
end;

function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const ARepositorios:
                                                TRepositoriosDocumentosTrabajo;
                                                const AInteraccion:
                                                IInteraccionDocumentosTrabajo;
                                                const ABusquedaVisual:
                                                IBusquedaVisual;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                const AParametrosCaja:
                                                IParametrosCaja;
                                                AResolver:
                                                TResolverDocTrabajoArtSku;
                                                const AResolverArticulos:
                                                IArticulosResolver):
                                                Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
begin
  rLinea.Clear;
  if Assigned(AResolver) then
  begin
    AResolver(rLinea.CodigoArticulo, rLinea.CodigoSku);
  end;
  rLinea.CodigoAlmacen := AContextoSesion.Ubicacion.Almacen;
  rLinea.CantidadStock := 0;
  rLinea.Cantidad := 1;
  rLinea.Origen := 'MTO';
  Result := AgregarUnidadADocumentoTrabajo(AOwner, AConexion,
    ARepositorios, AInteraccion,
    ABusquedaVisual, AContextoSesion, AParametrosCaja, rLinea,
    AResolverArticulos);
end;

end.
