{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasTraducciones                                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del fallback, pseudoidioma, herencia y colecciones traducibles.   }
{******************************************************************************}
unit PruebasTraducciones;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasTraducciones = class
  public
    [Test]
    procedure Pseudoidioma_TraduceRaizYComponenteHeredados;
    [Test]
    procedure Pseudoidioma_NoDuplicaMarcadorYConservaVacios;
    [Test]
    procedure Pseudoidioma_TraduceColeccionDevExpress;
    [Test]
    procedure SinCatalogo_ConservaTextoPredeterminado;
    [Test]
    procedure Idioma_NormalizaVacioYGuionBajo;
    [Test]
    procedure Clave_UsaClaseConcretaYNombreComponente;
    [Test]
    procedure TextoInforme_PseudoidiomaSinCorchetes;
    [Test]
    procedure TextoInforme_SinCatalogoConservaTexto;
    [Test]
    procedure Idioma_PreservaEtiquetasCatalogadas;
    [Test]
    procedure AtajosPuros_NoSeTraducen;
    [Test]
    procedure CatalogoInyectado_TraduceClaveEInforme;
    [Test]
    procedure CatalogoInyectado_RecargaBajoDemanda;
    [Test]
    procedure IdiomaConfigurado_UsaLectorYNormaliza;
    [Test]
    procedure TraduccionLocal_DelegaEnPersistencia;
    [Test]
    procedure AdaptadoresSinConexion_DevuelvenEstadoNoDisponible;
    [Test]
    procedure FechaCatalana_UsaDiaYMesDelIdiomaActivo;
  end;

implementation

uses
  System.Classes, System.SysUtils,
  cxRadioGroup, Uni,
  inLibTraduccionesIntf,
  inLibTraducciones,
  inLibTraduccionesDescarga,
  inLibTraduccionesPersistenciaIntf,
  inLibTraduccionesDescargaPersistenciaIntf,
  UniDataTraduccionesRepositorio,
  UniDataTraduccionesDescargaRepositorio;

type
  TComponenteTextoPrueba = class(TComponent)
  private
    FCaption: string;
    FDisplayName: string;
    FHint: string;
    FNoDataToDisplayInfoText: string;
    FTitle: string;
  published
    property Caption: string read FCaption write FCaption;
    property DisplayName: string
      read FDisplayName write FDisplayName;
    property Hint: string read FHint write FHint;
    property NoDataToDisplayInfoText: string
      read FNoDataToDisplayInfoText
      write FNoDataToDisplayInfoText;
    property Title: string read FTitle write FTitle;
  end;

  TRaizBasePrueba = class(TComponenteTextoPrueba)
  end;

  TRaizHeredadaPrueba = class(TRaizBasePrueba)
  end;

  TLectorCatalogoTraduccionesPrueba = class(
    TInterfacedObject,
    ILectorCatalogoTraducciones)
  private
    FIdioma: string;
    FIdiomaBase: string;
    FLlamadas: Integer;
  public
    function Cargar(
      const AIdioma, AIdiomaBase: string): TCatalogoTraducciones;
    property Idioma: string read FIdioma;
    property IdiomaBase: string read FIdiomaBase;
    property Llamadas: Integer read FLlamadas;
  end;

  TLectorIdiomaConfiguradoPrueba = class(
    TInterfacedObject,
    ILectorIdiomaConfigurado)
  private
    FUsuario: string;
  public
    function Leer(const AUsuario: string): string;
    property Usuario: string read FUsuario;
  end;

  TInstaladorTraduccionesPrueba = class(
    TInterfacedObject,
    IInstaladorTraduccionesPersistencia)
  private
    FComprobaciones: Integer;
    FIdiomaConsultado: string;
    FInstalaciones: Integer;
  public
    procedure ComprobarDisponible;
    function DisponibleLocalmente(const AIdioma: string): Boolean;
    procedure Instalar(
      const AIdioma: string;
      const AScripts: TArray<TScriptInstalacionTraduccion>;
      AProgreso: TProgresoDescargaTraduccion);
    property IdiomaConsultado: string read FIdiomaConsultado;
  end;

function TLectorCatalogoTraduccionesPrueba.Cargar(
  const AIdioma, AIdiomaBase: string): TCatalogoTraducciones;
begin
  Inc(FLlamadas);
  FIdioma := AIdioma;
  FIdiomaBase := AIdiomaBase;
  Result := Default(TCatalogoTraducciones);
  SetLength(Result.Textos, 1);
  Result.Textos[0].Clave := Format('Prueba.%s', ['Saludo']);
  Result.Textos[0].Texto := 'Hello';
  SetLength(Result.TextosInforme, 1);
  Result.TextosInforme[0].TextoBase := 'Factura';
  Result.TextosInforme[0].TextoIdioma := 'Invoice';
end;

function TLectorIdiomaConfiguradoPrueba.Leer(
  const AUsuario: string): string;
begin
  FUsuario := AUsuario;
  Result := 'ca_ES';
end;

procedure TInstaladorTraduccionesPrueba.ComprobarDisponible;
begin
  Inc(FComprobaciones);
end;

function TInstaladorTraduccionesPrueba.DisponibleLocalmente(
  const AIdioma: string): Boolean;
begin
  FIdiomaConsultado := AIdioma;
  Result := SameText(AIdioma, IDIOMA_CATALAN);
end;

procedure TInstaladorTraduccionesPrueba.Instalar(
  const AIdioma: string;
  const AScripts: TArray<TScriptInstalacionTraduccion>;
  AProgreso: TProgresoDescargaTraduccion);
begin
  FIdiomaConsultado := AIdioma;
  Inc(FInstalaciones);
end;

procedure TPruebasTraducciones.
  Pseudoidioma_TraduceRaizYComponenteHeredados;
var
  Componente: TComponenteTextoPrueba;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Ventana';
    Componente := TComponenteTextoPrueba.Create(Raiz);
    Componente.Name := 'Texto';
    Componente.Caption := 'Aceptar';
    Componente.Hint := 'Ayuda';
    Componente.NoDataToDisplayInfoText := 'Sin datos';
    Componente.Title := 'Título';
    Componente.DisplayName := 'Visible';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      '[!! Ventana ~~~~ !!]',
      Raiz.Caption);
    Assert.AreEqual(
      '[!! Aceptar ~~~~ !!]',
      Componente.Caption);
    Assert.AreEqual(
      '[!! Ayuda ~~~~ !!]',
      Componente.Hint);
    Assert.AreEqual(
      '[!! Sin datos ~~~~ !!]',
      Componente.NoDataToDisplayInfoText);
    Assert.AreEqual(
      '[!! Título ~~~~ !!]',
      Componente.Title);
    Assert.AreEqual(
      '[!! Visible ~~~~ !!]',
      Componente.DisplayName);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Pseudoidioma_NoDuplicaMarcadorYConservaVacios;
var
  PrimeraAplicacion: string;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Caja';
    Raiz.Hint := '';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    PrimeraAplicacion := Raiz.Caption;
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      PrimeraAplicacion,
      Raiz.Caption);
    Assert.AreEqual(
      '',
      Raiz.Hint);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Pseudoidioma_TraduceColeccionDevExpress;
var
  Grupo: TcxRadioGroup;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Grupo := TcxRadioGroup.Create(Raiz);
    Grupo.Name := 'Grupo';
    Grupo.Properties.Items.Add.Caption := 'Primera';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      '[!! Primera ~~~~ !!]',
      Grupo.Properties.Items[0].Caption);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  SinCatalogo_ConservaTextoPredeterminado;
var
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'Original';
    Servicio := TServicioTraducciones.Create(
      nil,
      'en-GB');
    Assert.IsFalse(
      Servicio.ExisteTraduccion(
        'Prueba.Clave.Caption'));
    Assert.AreEqual(
      'Original',
      Servicio.Traducir(
        'Prueba.Clave.Caption',
        'Original'));
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      'Original',
      Raiz.Caption);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  Idioma_NormalizaVacioYGuionBajo;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    '');
  Assert.AreEqual(
    IDIOMA_ESPANOL,
    Servicio.Idioma);
  Servicio.EstablecerIdioma('en_GB');
  Assert.AreEqual(
    'en-GB',
    Servicio.Idioma);
  Servicio.EstablecerIdioma('  qps_ploc  ');
  Assert.AreEqual(
    IDIOMA_PSEUDO,
    Servicio.Idioma);
end;

procedure TPruebasTraducciones.
  Clave_UsaClaseConcretaYNombreComponente;
var
  Componente: TComponenteTextoPrueba;
  Raiz: TRaizHeredadaPrueba;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Componente := TComponenteTextoPrueba.Create(Raiz);
    Componente.Name := 'Texto';
    Assert.AreEqual(
      'PruebasTraducciones.TRaizHeredadaPrueba.Caption',
      ClaveTraduccionComponente(
        Raiz,
        Raiz,
        'Caption'));
    Assert.AreEqual(
      'PruebasTraducciones.TRaizHeredadaPrueba.Texto.Hint',
      ClaveTraduccionComponente(
        Raiz,
        Componente,
        'Hint'));
  finally
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  TextoInforme_PseudoidiomaSinCorchetes;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    IDIOMA_PSEUDO);
  Assert.AreEqual(
    'Factura ~~~~',
    Servicio.TraducirTextoInforme('Factura'));
  // Un memo formado solo por expresiones no se alarga.
  Assert.AreEqual(
    '[Ventas."TOTAL"]',
    Servicio.TraducirTextoInforme('[Ventas."TOTAL"]'));
  // Una segunda pasada no duplica el relleno.
  Assert.AreEqual(
    'Factura ~~~~',
    Servicio.TraducirTextoInforme(
      Servicio.TraducirTextoInforme('Factura')));
end;

procedure TPruebasTraducciones.
  TextoInforme_SinCatalogoConservaTexto;
var
  Servicio: IServicioTraducciones;
begin
  Servicio := TServicioTraducciones.Create(
    nil,
    'en-GB');
  Assert.AreEqual(
    'Factura',
    Servicio.TraducirTextoInforme('Factura'));
end;

procedure TPruebasTraducciones.
  Idioma_PreservaEtiquetasCatalogadas;
begin
  Assert.AreEqual(
    IDIOMA_CATALAN,
    NormalizarIdiomaAplicacion('ca_ES'));
  Assert.AreEqual(
    IDIOMA_INGLES,
    NormalizarIdiomaAplicacion('en-GB'));
  Assert.AreEqual(
    'fr-FR',
    NormalizarIdiomaAplicacion('fr-FR'));
  Assert.AreEqual(
    IDIOMA_PSEUDO,
    NormalizarIdiomaAplicacion(IDIOMA_PSEUDO));
end;

procedure TPruebasTraducciones.AtajosPuros_NoSeTraducen;
var
  Componente: TComponenteTextoPrueba;
  Raiz: TRaizHeredadaPrueba;
  Servicio: IServicioTraducciones;
begin
  Raiz := TRaizHeredadaPrueba.Create(nil);
  try
    Raiz.Caption := 'F12';
    Componente := TComponenteTextoPrueba.Create(Raiz);
    Componente.Name := 'Atajo';
    Componente.Caption := 'ESC';
    Servicio := TServicioTraducciones.Create(
      nil,
      IDIOMA_PSEUDO);
    Servicio.Aplicar(Raiz);
    Assert.AreEqual(
      'F12',
      Raiz.Caption);
    Assert.AreEqual(
      'ESC',
      Componente.Caption);
  finally
    Servicio := nil;
    FreeAndNil(Raiz);
  end;
end;

procedure TPruebasTraducciones.
  FechaCatalana_UsaDiaYMesDelIdiomaActivo;
var
  Fecha: TDateTime;
  Servicio: IServicioTraducciones;
  Texto: string;
begin
  Fecha := EncodeDate(2026, 8, 8);
  Servicio := TServicioTraducciones.Create(
    nil,
    IDIOMA_CATALAN);
  Texto := FormatearFechaHoraIdioma(
    'dddd d mmmm yyyy',
    Fecha,
    Servicio);
  Assert.AreEqual(
    'dissabte 8 agost 2026',
    LowerCase(Texto));
end;

procedure TPruebasTraducciones.CatalogoInyectado_TraduceClaveEInforme;
var
  oLector: TLectorCatalogoTraduccionesPrueba;
  oServicio: IServicioTraducciones;
begin
  oLector := TLectorCatalogoTraduccionesPrueba.Create;
  oServicio := TServicioTraducciones.Create(oLector, IDIOMA_INGLES);
  Assert.AreEqual(
    'Hello',
    oServicio.Traducir('Prueba.Saludo', 'Hola'));
  Assert.AreEqual(
    'Invoice',
    oServicio.TraducirTextoInforme('Factura'));
  Assert.AreEqual(IDIOMA_INGLES, oLector.Idioma);
  Assert.AreEqual(IDIOMA_ESPANOL, oLector.IdiomaBase);
end;

procedure TPruebasTraducciones.CatalogoInyectado_RecargaBajoDemanda;
var
  oLector: TLectorCatalogoTraduccionesPrueba;
  oServicio: IServicioTraducciones;
begin
  oLector := TLectorCatalogoTraduccionesPrueba.Create;
  oServicio := TServicioTraducciones.Create(oLector, IDIOMA_INGLES);
  Assert.IsTrue(oServicio.ExisteTraduccion('Prueba.Saludo'));
  Assert.AreEqual(1, oLector.Llamadas);
  oServicio.Recargar;
  Assert.AreEqual(1, oLector.Llamadas);
  Assert.IsTrue(oServicio.ExisteTraduccion('Prueba.Saludo'));
  Assert.AreEqual(2, oLector.Llamadas);
end;

procedure TPruebasTraducciones.IdiomaConfigurado_UsaLectorYNormaliza;
var
  oContrato: ILectorIdiomaConfigurado;
  oLector: TLectorIdiomaConfiguradoPrueba;
begin
  oLector := TLectorIdiomaConfiguradoPrueba.Create;
  oContrato := oLector;
  Assert.AreEqual(
    IDIOMA_CATALAN,
    ObtenerIdiomaConfigurado(oContrato, 'DEMO'));
  Assert.AreEqual('DEMO', oLector.Usuario);
end;

procedure TPruebasTraducciones.TraduccionLocal_DelegaEnPersistencia;
var
  oContrato: IInstaladorTraduccionesPersistencia;
  oInstalador: TInstaladorTraduccionesPrueba;
begin
  oInstalador := TInstaladorTraduccionesPrueba.Create;
  oContrato := oInstalador;
  Assert.IsTrue(
    TInstaladorTraducciones.DisponibleLocalmente(
      oContrato,
      IDIOMA_CATALAN));
  Assert.AreEqual(IDIOMA_CATALAN, oInstalador.IdiomaConsultado);
end;

procedure TPruebasTraducciones.
  AdaptadoresSinConexion_DevuelvenEstadoNoDisponible;
var
  oCatalogo: TCatalogoTraducciones;
  oInstalador: IInstaladorTraduccionesPersistencia;
  oLectorCatalogo: ILectorCatalogoTraducciones;
  oLectorIdioma: ILectorIdiomaConfigurado;
begin
  oLectorCatalogo := TLectorCatalogoTraduccionesUniDAC.Create(
    TUniConnection(nil));
  oCatalogo := oLectorCatalogo.Cargar(
    IDIOMA_CATALAN,
    IDIOMA_ESPANOL);
  Assert.AreEqual(NativeInt(0), Length(oCatalogo.Textos));
  Assert.AreEqual(NativeInt(0), Length(oCatalogo.TextosInforme));
  oLectorIdioma := TLectorIdiomaConfiguradoUniDAC.Create(nil);
  Assert.AreEqual('', oLectorIdioma.Leer('DEMO'));
  oInstalador := TInstaladorTraduccionesUniDAC.Create(nil);
  Assert.IsFalse(oInstalador.DisponibleLocalmente(IDIOMA_CATALAN));
end;

end.
