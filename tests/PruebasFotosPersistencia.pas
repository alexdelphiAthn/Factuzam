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
    procedure Edicion_GuardarReemplazaNombrePersistido;
    [Test]
    procedure Edicion_ErrorEscritura_NoSeConvierteEnExito;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Types,
  Vcl.Graphics,
  inLibParametrosIntf, inLibLicenciaAplicacion,
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
  TParametrosFotosFalsos = class(
    TInterfacedObject,
    IParametrosAplicacion)
  public
    DirectorioFotos: string;
    function GetString(
      const AKey: string;
      const ADefault: string = ''): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0): Integer;
    function GetPath(const ANombre: string): string;
    function Licencia: TResultadoLicenciaAplicacion;
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

function TParametrosFotosFalsos.GetString(
  const AKey, ADefault: string): string;
begin
  Result := ADefault;
end;

function TParametrosFotosFalsos.GetBool(
  const AKey: string; const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TParametrosFotosFalsos.GetInt(
  const AKey: string; const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosFotosFalsos.GetPath(
  const ANombre: string): string;
begin
  Result := DirectorioFotos;
end;

function TParametrosFotosFalsos.Licencia:
  TResultadoLicenciaAplicacion;
begin
  Result := Default(TResultadoLicenciaAplicacion);
end;

function CrearDirectorioTemporalFotos: string;
var
  oIdentificador: TGUID;
  sBase: string;
begin
  CreateGUID(oIdentificador);
  sBase := GetEnvironmentVariable('TEMP');
  if sBase = '' then
    sBase := GetCurrentDir;
  Result := IncludeTrailingPathDelimiter(sBase) +
    'FactuzamIA16F_' + GUIDToString(oIdentificador);
  ForceDirectories(Result);
end;

procedure CrearBmpPrueba(const ARuta: string);
var
  oBitmap: Vcl.Graphics.TBitmap;
begin
  oBitmap := Vcl.Graphics.TBitmap.Create;
  try
    oBitmap.SetSize(4, 4);
    oBitmap.Canvas.Brush.Color := clRed;
    oBitmap.Canvas.FillRect(Rect(0, 0, 4, 4));
    oBitmap.SaveToFile(ARuta);
  finally
    FreeAndNil(oBitmap);
  end;
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

procedure TPruebasFotosPersistencia.
  Consulta_SinMetadatos_DevuelveAusencia;
var
  oConsulta: TConsultaFotos;
  oFalso: TRepositorioConsultaFotosFalso;
  oRepositorio: IRepositorioConsultaFotos;
  oResultado: inLibFotosTipos.TFotoInfo;
begin
  oFalso := TRepositorioConsultaFotosFalso.Create;
  oRepositorio := oFalso;
  oConsulta := TConsultaFotos.Create;
  try
    oConsulta.AsignarServicios(nil, nil, oRepositorio);
    oResultado := oConsulta.Resolver('ART-1', 'ART-1/ROJO');
    Assert.IsFalse(oResultado.Encontrada);
    Assert.AreEqual(foSinFoto, oResultado.Origen);
  finally
    oConsulta.LiberarServicios;
    FreeAndNil(oConsulta);
    oRepositorio := nil;
  end;
end;

procedure TPruebasFotosPersistencia.
  Consulta_PriorizaSkuYUsaFallbackArticulo;
var
  oConsulta: TConsultaFotos;
  oFalso: TRepositorioConsultaFotosFalso;
  oRepositorio: IRepositorioConsultaFotos;
  oResultado: inLibFotosTipos.TFotoInfo;
begin
  oFalso := TRepositorioConsultaFotosFalso.Create;
  oRepositorio := oFalso;
  oFalso.TieneSku := True;
  oFalso.TieneArticulo := True;
  oFalso.FotoSku.CodigoArticulo := 'ART-1';
  oFalso.FotoSku.CodigoUnidad := 'ART-1/ROJO';
  oFalso.FotoSku.Nombre := 'sku_001';
  oFalso.FotoSku.Extension := 'png';
  oFalso.FotoArticulo.CodigoArticulo := 'ART-1';
  oFalso.FotoArticulo.Nombre := 'articulo_001';
  oFalso.FotoArticulo.Extension := 'jpg';
  oConsulta := TConsultaFotos.Create;
  try
    oConsulta.AsignarServicios(nil, nil, oRepositorio);
    oResultado := oConsulta.Resolver('ART-1', 'ART-1/ROJO');
    Assert.AreEqual(foSku, oResultado.Origen);
    Assert.AreEqual('sku_001', oResultado.NombreBase);
    oFalso.TieneSku := False;
    oResultado := oConsulta.Resolver('ART-1', 'ART-1/AZUL');
    Assert.AreEqual(foArticulo, oResultado.Origen);
    Assert.AreEqual('articulo_001', oResultado.NombreBase);
  finally
    oConsulta.LiberarServicios;
    FreeAndNil(oConsulta);
    oRepositorio := nil;
  end;
end;

procedure TPruebasFotosPersistencia.
  Edicion_GuardarReemplazaNombrePersistido;
var
  oAlmacenamiento: TAlmacenamientoFotos;
  oConsulta: TConsultaFotos;
  oEdicion: TEdicionFotos;
  oEdicionFalsa: TRepositorioEdicionFotosFalso;
  oRepositorioEdicion: IRepositorioEdicionFotos;
  oParametrosFalsos: TParametrosFotosFalsos;
  oParametros: IParametrosAplicacion;
  oResultado: inLibFotosTipos.TFotoInfo;
  sDirectorio: string;
  sOrigen: string;
begin
  oEdicionFalsa := TRepositorioEdicionFotosFalso.Create;
  oRepositorioEdicion := oEdicionFalsa;
  oEdicionFalsa.TieneFoto := True;
  oEdicionFalsa.FotoActual.Nombre := 'ART-1_ROJO_001';
  oParametrosFalsos := TParametrosFotosFalsos.Create;
  oParametros := oParametrosFalsos;
  sDirectorio := CrearDirectorioTemporalFotos;
  oParametrosFalsos.DirectorioFotos := sDirectorio;
  sOrigen := TPath.Combine(sDirectorio, 'origen.bmp');
  CrearBmpPrueba(sOrigen);
  oConsulta := TConsultaFotos.Create;
  oAlmacenamiento := TAlmacenamientoFotos.Create;
  oEdicion := TEdicionFotos.Create(oConsulta, oAlmacenamiento);
  try
    oAlmacenamiento.AsignarParametros(oParametros);
    oEdicion.AsignarRepositorio(oRepositorioEdicion);
    oResultado := oEdicion.Guardar(
      'ART-1', 'ART-1/ROJO', sOrigen, 'PRUEBAS');
    Assert.AreEqual('ART-1_ROJO_002', oResultado.NombreBase);
    Assert.AreEqual(
      'ART-1_ROJO_002', oEdicionFalsa.FotoGuardada.Nombre);
  finally
    oEdicion.LiberarServicios;
    oAlmacenamiento.LiberarServicios;
    FreeAndNil(oEdicion);
    FreeAndNil(oAlmacenamiento);
    FreeAndNil(oConsulta);
    oRepositorioEdicion := nil;
    oParametros := nil;
    if TDirectory.Exists(sDirectorio) then
      TDirectory.Delete(sDirectorio, True);
  end;
end;

procedure TPruebasFotosPersistencia.
  Edicion_ErrorEscritura_NoSeConvierteEnExito;
var
  oAlmacenamiento: TAlmacenamientoFotos;
  oConsulta: TConsultaFotos;
  oEdicion: TEdicionFotos;
  oEdicionFalsa: TRepositorioEdicionFotosFalso;
  oRepositorioEdicion: IRepositorioEdicionFotos;
  oParametrosFalsos: TParametrosFotosFalsos;
  oParametros: IParametrosAplicacion;
  sDirectorio: string;
  sNombreNuevo: string;
  sOrigen: string;
begin
  oEdicionFalsa := TRepositorioEdicionFotosFalso.Create;
  oRepositorioEdicion := oEdicionFalsa;
  oEdicionFalsa.TieneFoto := True;
  oEdicionFalsa.FotoActual.Nombre := 'ART-1_ROJO_001';
  oEdicionFalsa.FallarEscritura := True;
  oParametrosFalsos := TParametrosFotosFalsos.Create;
  oParametros := oParametrosFalsos;
  sDirectorio := CrearDirectorioTemporalFotos;
  oParametrosFalsos.DirectorioFotos := sDirectorio;
  sOrigen := TPath.Combine(sDirectorio, 'origen.bmp');
  CrearBmpPrueba(sOrigen);
  sNombreNuevo := 'ART-1_ROJO_002.png';
  oConsulta := TConsultaFotos.Create;
  oAlmacenamiento := TAlmacenamientoFotos.Create;
  oEdicion := TEdicionFotos.Create(oConsulta, oAlmacenamiento);
  try
    oAlmacenamiento.AsignarParametros(oParametros);
    oEdicion.AsignarRepositorio(oRepositorioEdicion);
    Assert.WillRaise(
      procedure
      begin
        oEdicion.Guardar(
          'ART-1', 'ART-1/ROJO', sOrigen, 'PRUEBAS');
      end,
      Exception);
    Assert.IsFalse(FileExists(TPath.Combine(
      TPath.Combine(sDirectorio, '300'), sNombreNuevo)));
    Assert.IsFalse(FileExists(TPath.Combine(
      TPath.Combine(sDirectorio, '600'), sNombreNuevo)));
    Assert.IsFalse(FileExists(TPath.Combine(
      TPath.Combine(sDirectorio, 'real'), sNombreNuevo)));
  finally
    oEdicion.LiberarServicios;
    oAlmacenamiento.LiberarServicios;
    FreeAndNil(oEdicion);
    FreeAndNil(oAlmacenamiento);
    FreeAndNil(oConsulta);
    oRepositorioEdicion := nil;
    oParametros := nil;
    if TDirectory.Exists(sDirectorio) then
      TDirectory.Delete(sDirectorio, True);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFotosPersistencia);

end.
