{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDistribucionTiendasIntf                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de la distribución de mercancía entre tiendas: unidades del     }
{    documento de trabajo, asignaciones origen-destino y propuestas de         }
{    traspaso. Sin VCL ni acceso a datos.                                      }
{******************************************************************************}
unit inLibDistribucionTiendasIntf;

interface

const
  ESTADO_PROPUESTA_TRASPASO_PENDIENTE = 'PENDIENTE';
  ESTADO_PROPUESTA_TRASPASO_CONFIRMADA = 'CONFIRMADA';
  // Serie con la que el traspaso de caja referencia a su propuesta
  // (SERIE_REF_ORIGEN_OPCAJA; el número es el identificador).
  SERIE_REFERENCIA_PROPUESTA_TRASPASO = 'PT';

type
  // Unidades que el documento de trabajo sitúa en un almacén, por SKU.
  TUnidadDocumentoDistribucion = record
    CodigoAlmacen: string;
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoSku: string;
    Color: string;
    Talla: string;
    OrdenTalla: Integer;
    Cantidad: Double;
  end;
  TUnidadesDocumentoDistribucion = TArray<TUnidadDocumentoDistribucion>;

  TAlmacenDistribucion = record
    Codigo: string;
    Nombre: string;
    Orden: Integer;
  end;
  TAlmacenesDistribucion = TArray<TAlmacenDistribucion>;

  // Unidades de un SKU que van de un origen a un destino. Lo confirmado
  // ya es un traspaso y no se puede rebajar; lo pendiente es editable.
  TAsignacionDistribucion = record
    AlmacenOrigen: string;
    AlmacenDestino: string;
    CodigoSku: string;
    CantidadConfirmada: Double;
    CantidadPendiente: Double;
  end;
  TAsignacionesDistribucion = TArray<TAsignacionDistribucion>;

  TStockDistribucion = record
    CodigoAlmacen: string;
    CodigoSku: string;
    Cantidad: Double;
  end;
  TStocksDistribucion = TArray<TStockDistribucion>;

  TDocumentoDistribucion = record
    IdDocumento: Int64;
    Titulo: string;
    Unidades: TUnidadesDocumentoDistribucion;
    Almacenes: TAlmacenesDistribucion;
    Asignaciones: TAsignacionesDistribucion;
    Stocks: TStocksDistribucion;
  end;

  TLineaPropuestaTraspaso = record
    CodigoArticulo: string;
    DescripcionArticulo: string;
    CodigoSku: string;
    Color: string;
    Talla: string;
    OrdenTalla: Integer;
    Cantidad: Double;
    CantidadTraspasada: Double;
  end;
  TLineasPropuestaTraspaso = TArray<TLineaPropuestaTraspaso>;

  TPropuestaTraspaso = record
    IdPropuesta: Int64;
    IdDocumento: Int64;
    TituloDocumento: string;
    Instante: TDateTime;
    Estado: string;
    AlmacenOrigen: string;
    NombreAlmacenOrigen: string;
    AlmacenDestino: string;
    NombreAlmacenDestino: string;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    NumeroOperacion: string;
    Lineas: TLineasPropuestaTraspaso;
    function EstaPendiente: Boolean;
    function TotalUnidades: Double;
  end;
  TPropuestasTraspaso = TArray<TPropuestaTraspaso>;

  TResultadoConfirmacionPropuesta = record
    Confirmada: Boolean;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    NumeroOperacion: string;
    // Motivo cuando una regla de negocio impide confirmarla.
    Mensaje: string;
  end;

  IRepositorioDistribucionTiendas = interface
    ['{6F3B7E0A-5C0F-4B7E-9A55-1B8B0B6D2C41}']
    function CargarDocumento(
      AIdDocumento: Int64): TDocumentoDistribucion;
    // Sincroniza las propuestas PENDIENTES del documento con lo asignado:
    // crea las que falten, actualiza sus líneas y retira las vacías.
    procedure GuardarPropuestas(
      AIdDocumento: Int64;
      const AAsignaciones: TAsignacionesDistribucion;
      const AUsuario: string);
    function ListarPropuestasDocumento(
      AIdDocumento: Int64): TPropuestasTraspaso;
    function ListarPropuestasPendientesOrigen(
      const AAlmacenOrigen: string): TPropuestasTraspaso;
    function LeerPropuesta(AIdPropuesta: Int64): TPropuestaTraspaso;
    function EliminarPropuestaPendiente(AIdPropuesta: Int64): Boolean;
  end;

  // Convierte una propuesta pendiente en un traspaso real.
  IConfirmadorPropuestasTraspaso = interface
    ['{0C1F0E55-7B6B-4A0C-8D6D-3D8C1C0B7E92}']
    function Confirmar(
      AIdPropuesta: Int64;
      AFecha: TDateTime): TResultadoConfirmacionPropuesta;
  end;

  TServiciosDistribucionTiendas = record
    Repositorio: IRepositorioDistribucionTiendas;
    Confirmador: IConfirmadorPropuestasTraspaso;
    procedure Validar;
  end;

implementation

uses
  System.SysUtils;

function TPropuestaTraspaso.EstaPendiente: Boolean;
begin
  Result := SameText(Estado, ESTADO_PROPUESTA_TRASPASO_PENDIENTE);
end;

function TPropuestaTraspaso.TotalUnidades: Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Lineas) do
  begin
    if EstaPendiente then
      Result := Result + Lineas[i].Cantidad
    else
      Result := Result + Lineas[i].CantidadTraspasada;
  end;
end;

procedure TServiciosDistribucionTiendas.Validar;
begin
  if not Assigned(Repositorio) then
    raise EArgumentNilException.Create('Repositorio');
  if not Assigned(Confirmador) then
    raise EArgumentNilException.Create('Confirmador');
end;

end.
