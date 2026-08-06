{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFotosPersistencia                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica contratos, fallback y edición de fotos sin usar una BBDD.        }
{******************************************************************************}
unit PruebasFotosPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFotosPersistencia = class
  public
    [Test]
    procedure ServiciosVacios_NoAsignanNingunPuerto;
    [Test]
    procedure PrefijosSku_OrdenaDeMasAMenosEspecifico;
    [Test]
    procedure Almacenamiento_ComponeNombreCanonico;
    [Test]
    procedure Fachada_SinServicios_SePuedeLiberar;
    [Test]
    procedure Consulta_SinMetadatos_DevuelveAusencia;
    [Test]
    procedure Consulta_PriorizaSkuYUsaFallbackArticulo;
    [Test]
    procedure Edicion_RotacionReemplazaNombrePersistido;
    [Test]
    procedure Edicion_ErrorEscritura_NoSeConvierteEnExito;
  end;

implementation

uses
  System.SysUtils,
  inLibFotosPersistenciaIntf, inLibFotosAlmacenamiento,
  inLibFotosConsulta, inLibFotosEdicion, inLibFotosTipos,
  inLibFotos;

type
  TRepositorioConsultaFotosFalso = class(
    TInterfacedObject,
    IRepositorioConsultaFotos)
  public
    TieneSku: Boolean;
    TieneArticulo: Boolean;
    TienePrimeraUnidad: Boolean;
    FotoSku: TMetadatosFotoPersistida;
    FotoArticulo: TMetadatosFotoPersistida;
    FotoPrimeraUnidad: TMetadatosFotoPersistida;
    FotosLote: TArray<TMetadatosFotoPersistida>;
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>):
      TArray<TMetadatosFotoPersistida>;
  end;
  TRepositorioEdicionFotosFalso = class(
    TInterfacedObject,
    IRepositorioEdicionFotos)
  public
    FotoActual: TMetadatosFotoPersistida;
    FotoGuardada: TMetadatosFotoPersistida;
    NombreActualizado: string;
    TieneFoto: Boolean;
    FallarEscritura: Boolean;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string);
  end;

function TRepositorioConsultaFotosFalso.BuscarFotoPorUnidades(
  const ACodigoArticulo: string;
  const AUnidades: TArray<string>;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  AMetadatos := FotoSku;
  Result := TieneSku;
end;

function TRepositorioConsultaFotosFalso.BuscarFotoArticulo(
  const ACodigoArticulo: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  AMetadatos := FotoArticulo;
  Result := TieneArticulo;
end;

function TRepositorioConsultaFotosFalso.BuscarPrimeraFotoUnidad(
  const ACodigoArticulo: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  AMetadatos := FotoPrimeraUnidad;
  Result := TienePrimeraUnidad;
end;

function TRepositorioConsultaFotosFalso.BuscarFotosArticulos(
  const ACodigosArticulo: TArray<string>):
  TArray<TMetadatosFotoPersistida>;
begin
  Result := FotosLote;
end;

function TRepositorioEdicionFotosFalso.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  AMetadatos := FotoActual;
  Result := TieneFoto;
end;

procedure TRepositorioEdicionFotosFalso.GuardarFoto(
  const AMetadatos: TMetadatosFotoPersistida;
  const AUsuario: string);
begin
  if FallarEscritura then
    raise Exception.Create('Error de escritura simulado');
  FotoGuardada := AMetadatos;
end;

procedure TRepositorioEdicionFotosFalso.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
begin
  if FallarEscritura then
    raise Exception.Create('Error de escritura simulado');
  NombreActualizado := ANombre;
end;

function TRepositorioEdicionFotosFalso.BuscarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string): string;
begin
  Result := FotoActual.Nombre;
end;

procedure TRepositorioEdicionFotosFalso.EliminarFoto(
  const ACodigoArticulo, ACodigoUnidad: string);
begin
  TieneFoto := False;
end;

procedure TPruebasFotosPersistencia.
  ServiciosVacios_NoAsignanNingunPuerto;
var
  Repositorios: TRepositoriosFotos;
begin
  Repositorios := Default(TRepositoriosFotos);
  Assert.IsFalse(Assigned(Repositorios.Consulta));
  Assert.IsFalse(Assigned(Repositorios.Edicion));
  Assert.IsFalse(Assigned(Repositorios.Sesion));
end;

procedure TPruebasFotosPersistencia.
  PrefijosSku_OrdenaDeMasAMenosEspecifico;
var
  Prefijos: TArray<string>;
begin
  Prefijos := GenerarPrefijosSku('BLUS-SEDA/BLANCO/L');
  Assert.AreEqual(2, Integer(Length(Prefijos)));
  Assert.AreEqual('BLUS-SEDA/BLANCO/L', Prefijos[0]);
  Assert.AreEqual('BLUS-SEDA/BLANCO', Prefijos[1]);
end;

procedure TPruebasFotosPersistencia.
  Almacenamiento_ComponeNombreCanonico;
var
  oAlmacenamiento: TAlmacenamientoFotos;
  sClave         : string;
  sNombre        : string;
begin
  oAlmacenamiento := TAlmacenamientoFotos.Create;
  try
    sClave := oAlmacenamiento.ClaveNombre(
      'BLUS-SEDA', 'BLUS-SEDA/BLANCO:L');
    sNombre := oAlmacenamiento.ComponerNombre(sClave, 7);
    Assert.AreEqual('BLUS-SEDA_BLANCO_L_007', sNombre);
    Assert.AreEqual(7, oAlmacenamiento.ExtraerIndice(sNombre));
    Assert.AreEqual('jpeg',
      oAlmacenamiento.ExtensionOrigen('foto.JPEG'));
  finally
    FreeAndNil(oAlmacenamiento);
  end;
end;

procedure TPruebasFotosPersistencia.
  Fachada_SinServicios_SePuedeLiberar;
var
  oFotos: TFotosArticulos;
begin
  oFotos := TFotosArticulos.Create;
  FreeAndNil(oFotos);
  Assert.IsFalse(Assigned(oFotos));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosPersistencia);

end.
