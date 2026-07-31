{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridPivoteCompraPersistenciaIntf                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del pivote de documentos de compra.                }
{******************************************************************************}
unit inLibGridPivoteCompraPersistenciaIntf;

interface

uses
  Data.DB, Uni;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioGridPivoteCompra = interface
    ['{E4AB84C4-D77E-4A31-8895-815211E2AFAB}']
    procedure Configurar(
      const ATablaLineas, ACampoSerie, ACampoNumero, ACampoLinea,
        ACampoArticulo, ACampoSku, ACampoCantidad,
        ACampoCantidadRecibida, ACampoIdConjunto, ACampoAlmacen,
        ACampoColorTexto: string;
      AMaximoColumnas: Integer);
    function BuscarColorBasico(
      const ACodigo: string;
      out AIdBasico: Integer;
      out ANombre: string): Boolean;
    function BuscarValorColor(
      const AValor: string;
      out AIdValor: Integer;
      out ATieneBasico: Boolean): Boolean;
    procedure VincularValorColor(
      AIdValor, AIdBasico: Integer;
      const AUsuario: string);
    function InsertarValorColor(
      const AValor, ADescripcion, AUsuario: string;
      AIdBasico: Integer): Integer;
    function BuscarArticulosSinSistema(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSistemasConExceso(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSkusFueraSistema(
      const ASerie, ANumero: string): TDataSet;
    function BuscarLineasPivote(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSku(
      const ACodigoArticulo: string;
      AIdTalla, AIdColor: Integer): string;
    function BuscarValorAtributo(AIdValor: Integer): string;
    procedure AsegurarSkuConAtributos(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor, AIdTalla: Integer);
    function BuscarTipoVariacion(
      const ACodigoArticulo: string): string;
    procedure AsegurarSkuColor(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor: Integer);
  end;
  TFabricaCrearRepositorioGridPivoteCompra = function(
    AConexion: TUniConnection): IRepositorioGridPivoteCompra;
  TFabricaRepositorioGridPivoteCompra = class
  private
    class var FFabrica: TFabricaCrearRepositorioGridPivoteCompra;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearRepositorioGridPivoteCompra);
    class function Crear(
      AConexion: TUniConnection): IRepositorioGridPivoteCompra;
  end;

implementation

uses
  System.SysUtils, inLibMsgCompras;

class procedure TFabricaRepositorioGridPivoteCompra.Registrar(
  AFabrica: TFabricaCrearRepositorioGridPivoteCompra);
begin
  FFabrica := AFabrica;
end;

class function TFabricaRepositorioGridPivoteCompra.Crear(
  AConexion: TUniConnection): IRepositorioGridPivoteCompra;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(
      SErrorPersistenciaGridPivoteCompraNoRegistrada);
  Result := FFabrica(AConexion);
end;

end.
