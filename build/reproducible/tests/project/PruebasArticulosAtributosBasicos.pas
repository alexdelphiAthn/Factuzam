{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasArticulosAtributosBasicos                             }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los códigos globales y ad-hoc de atributos básicos.            }
{******************************************************************************}
unit PruebasArticulosAtributosBasicos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasArticulosAtributosBasicos = class
  public
    [Test]
    procedure Global_NormalizaEspacios;
    [Test]
    procedure AdHoc_IncluyeArticulo;
    [Test]
    procedure Codigo_SeTruncaACienCaracteres;
    [Test]
    procedure AsegurarBasico_MaterializaValorYGuardaOverride;
    [Test]
    procedure GuardarOverride_NuloConservaBloqueoExplicito;
    [Test]
    procedure GuardarDescripcion_ConservaBasicoResuelto;
    [Test]
    procedure Constructor_ExigeRepositorio;
    [Test]
    procedure EtiquetaFuente_TraduceOrigenDelBasico;
    [Test]
    procedure Hex_DescomponeYRecomponeElColor;
    [Test]
    procedure Hex_RechazaTextoQueNoEsColor;
    [Test]
    procedure Hex_DecideElColorDelTextoPorLuminancia;
  end;

implementation

uses
  System.SysUtils,
  inLibArticulosAtributosBasicosIntf,
  inLibArticulosAtributosBasicos,
  inLibArticulosPresentacion;

type
  TRepositorioAtributosBasicosFalso = class(
    TInterfacedObject,
    IRepositorioAtributosBasicosSku)
  public
    LlamadasAsegurarValor: Integer;
    LlamadasAsegurarBasico: Integer;
    LlamadasGuardarOverride: Integer;
    LlamadasGuardarDescripcion: Integer;
    IdValorDevuelto: Integer;
    IdBasicoDevuelto: Integer;
    UltimoCodigoBasico: string;
    UltimoIdValor: Integer;
    UltimoIdBasico: TEnteroOpcional;
    UltimaDescripcion: TCadenaOpcional;
    function BuscarCodigoActivo(
      const AIdVariacion, ATexto: string;
      out ACodigo: string): Boolean;
    function AsegurarValorSku(
      const ACodigoSku, AIdVariacion, AValor,
      AUsuario: string): Integer;
    function AsegurarAtributoBasico(
      const AIdVariacion, ACodigo, ANombre,
      AUsuario: string): Integer;
    procedure GuardarOverride(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const AUsuario: string);
    procedure ActualizarNombre(
      AIdBasico: Integer;
      const ANombre, AUsuario: string);
    procedure ActualizarValorNumerico(
      AIdBasico: Integer;
      const AValor: TRealOpcional;
      const AUsuario: string);
    procedure ActualizarUnidad(
      AIdBasico: Integer;
      const AUnidad, AUsuario: string);
    procedure GuardarDescripcion(
      const ACodigoArticulo: string;
      AIdValor: Integer;
      const AIdBasico: TEnteroOpcional;
      const ADescripcion: TCadenaOpcional;
      const AUsuario: string);
    procedure ActualizarHex(
      AIdBasico: Integer;
      const AHex, AUsuario: string);
  end;

function CrearContextoAtributo: TContextoAtributoBasicoSku;
begin
  Result := Default(TContextoAtributoBasicoSku);
  Result.CodigoArticulo := 'ART1';
  Result.CodigoSku := 'SKU1';
  Result.IdVariacion := 'CO';
  Result.ValorAtributo := 'AZUL MARINO';
  Result.Usuario := 'PRUEBAS';
end;

function TRepositorioAtributosBasicosFalso.BuscarCodigoActivo(
  const AIdVariacion, ATexto: string;
  out ACodigo: string): Boolean;
begin
  ACodigo := '';
  Result := False;
end;

function TRepositorioAtributosBasicosFalso.AsegurarValorSku(
  const ACodigoSku, AIdVariacion, AValor,
  AUsuario: string): Integer;
begin
  Inc(LlamadasAsegurarValor);
  Result := IdValorDevuelto;
end;

function TRepositorioAtributosBasicosFalso.AsegurarAtributoBasico(
  const AIdVariacion, ACodigo, ANombre,
  AUsuario: string): Integer;
begin
  Inc(LlamadasAsegurarBasico);
  UltimoCodigoBasico := ACodigo;
  Result := IdBasicoDevuelto;
end;

procedure TRepositorioAtributosBasicosFalso.GuardarOverride(
  const ACodigoArticulo: string;
  AIdValor: Integer;
  const AIdBasico: TEnteroOpcional;
  const AUsuario: string);
begin
  Inc(LlamadasGuardarOverride);
  UltimoIdValor := AIdValor;
  UltimoIdBasico := AIdBasico;
end;

procedure TRepositorioAtributosBasicosFalso.ActualizarNombre(
  AIdBasico: Integer;
  const ANombre, AUsuario: string);
begin
end;

procedure TRepositorioAtributosBasicosFalso.ActualizarValorNumerico(
  AIdBasico: Integer;
  const AValor: TRealOpcional;
  const AUsuario: string);
begin
end;

procedure TRepositorioAtributosBasicosFalso.ActualizarUnidad(
  AIdBasico: Integer;
  const AUnidad, AUsuario: string);
begin
end;

procedure TRepositorioAtributosBasicosFalso.GuardarDescripcion(
  const ACodigoArticulo: string;
  AIdValor: Integer;
  const AIdBasico: TEnteroOpcional;
  const ADescripcion: TCadenaOpcional;
  const AUsuario: string);
begin
  Inc(LlamadasGuardarDescripcion);
  UltimoIdValor := AIdValor;
  UltimoIdBasico := AIdBasico;
  UltimaDescripcion := ADescripcion;
end;

procedure TRepositorioAtributosBasicosFalso.ActualizarHex(
  AIdBasico: Integer;
  const AHex, AUsuario: string);
begin
end;

procedure TPruebasArticulosAtributosBasicos.Global_NormalizaEspacios;
begin
  Assert.AreEqual(
    'AZUL_MARINO',
    ComponerCodigoAtributoBasico(
      aabGlobal, 'ART1', 'AZUL MARINO'));
end;

procedure TPruebasArticulosAtributosBasicos.AdHoc_IncluyeArticulo;
begin
  Assert.AreEqual(
    'AD_ART1_AZUL_MARINO',
    ComponerCodigoAtributoBasico(
      aabAdHoc, 'ART1', 'AZUL MARINO'));
end;

procedure TPruebasArticulosAtributosBasicos.
  Codigo_SeTruncaACienCaracteres;
var
  sCodigo: string;
begin
  sCodigo := ComponerCodigoAtributoBasico(
    aabAdHoc, 'ART1', StringOfChar('A', 120));
  Assert.AreEqual(100, Length(sCodigo));
  Assert.IsTrue(Pos('AD_ART1_', sCodigo) = 1);
end;

procedure TPruebasArticulosAtributosBasicos.
  AsegurarBasico_MaterializaValorYGuardaOverride;
var
  iIdBasico: Integer;
  oContexto: TContextoAtributoBasicoSku;
  oGestor: IGestorAtributosBasicosSku;
  oRepositorio: TRepositorioAtributosBasicosFalso;
begin
  oContexto := CrearContextoAtributo;
  oRepositorio := TRepositorioAtributosBasicosFalso.Create;
  oRepositorio.IdValorDevuelto := 41;
  oRepositorio.IdBasicoDevuelto := 73;
  oGestor := TGestorAtributosBasicosSku.Create(oRepositorio);
  iIdBasico := oGestor.AsegurarBasico(
    oContexto,
    aabAdHoc);
  Assert.AreEqual(73, iIdBasico);
  Assert.AreEqual(1, oRepositorio.LlamadasAsegurarValor);
  Assert.AreEqual(1, oRepositorio.LlamadasAsegurarBasico);
  Assert.AreEqual('AD_ART1_AZUL_MARINO',
                  oRepositorio.UltimoCodigoBasico);
  Assert.AreEqual(1, oRepositorio.LlamadasGuardarOverride);
  Assert.AreEqual(41, oRepositorio.UltimoIdValor);
  Assert.IsTrue(oRepositorio.UltimoIdBasico.TieneValor);
  Assert.AreEqual(73, oRepositorio.UltimoIdBasico.Valor);
end;

procedure TPruebasArticulosAtributosBasicos.
  GuardarOverride_NuloConservaBloqueoExplicito;
var
  oContexto: TContextoAtributoBasicoSku;
  oGestor: IGestorAtributosBasicosSku;
  oRepositorio: TRepositorioAtributosBasicosFalso;
begin
  oContexto := CrearContextoAtributo;
  oContexto.IdValor := 22;
  oRepositorio := TRepositorioAtributosBasicosFalso.Create;
  oGestor := TGestorAtributosBasicosSku.Create(oRepositorio);
  oGestor.GuardarOverride(oContexto, EnteroNulo);
  Assert.AreEqual(0, oRepositorio.LlamadasAsegurarValor);
  Assert.AreEqual(1, oRepositorio.LlamadasGuardarOverride);
  Assert.AreEqual(22, oRepositorio.UltimoIdValor);
  Assert.IsFalse(oRepositorio.UltimoIdBasico.TieneValor);
end;

procedure TPruebasArticulosAtributosBasicos.
  GuardarDescripcion_ConservaBasicoResuelto;
var
  oContexto: TContextoAtributoBasicoSku;
  oGestor: IGestorAtributosBasicosSku;
  oRepositorio: TRepositorioAtributosBasicosFalso;
begin
  oContexto := CrearContextoAtributo;
  oContexto.IdValor := 22;
  oRepositorio := TRepositorioAtributosBasicosFalso.Create;
  oGestor := TGestorAtributosBasicosSku.Create(oRepositorio);
  oGestor.GuardarDescripcion(
    oContexto,
    EnteroConValor(73),
    CadenaConValor('Azul de la colección'));
  Assert.AreEqual(1, oRepositorio.LlamadasGuardarDescripcion);
  Assert.IsTrue(oRepositorio.UltimoIdBasico.TieneValor);
  Assert.AreEqual(73, oRepositorio.UltimoIdBasico.Valor);
  Assert.IsTrue(oRepositorio.UltimaDescripcion.TieneValor);
  Assert.AreEqual('Azul de la colección',
                  oRepositorio.UltimaDescripcion.Valor);
end;

procedure TPruebasArticulosAtributosBasicos.Constructor_ExigeRepositorio;
begin
  Assert.WillRaise(
    procedure
    begin
      TGestorAtributosBasicosSku.Create(nil);
    end,
    EArgumentNilException);
end;

procedure TPruebasArticulosAtributosBasicos.
  EtiquetaFuente_TraduceOrigenDelBasico;
begin
  Assert.AreEqual('Artículo', EtiquetaFuenteAtributoBasico('A'));
  Assert.AreEqual('Conjunto', EtiquetaFuenteAtributoBasico('C'));
  Assert.AreEqual('Global', EtiquetaFuenteAtributoBasico('G'));
  Assert.AreEqual('', EtiquetaFuenteAtributoBasico(''));
  Assert.AreEqual('', EtiquetaFuenteAtributoBasico('X'));
end;

procedure TPruebasArticulosAtributosBasicos.
  Hex_DescomponeYRecomponeElColor;
var
  iRojo, iVerde, iAzul: Integer;
begin
  Assert.IsTrue(DescomponerHexAtributo('#1A2B3C', iRojo, iVerde, iAzul));
  Assert.AreEqual($1A, iRojo);
  Assert.AreEqual($2B, iVerde);
  Assert.AreEqual($3C, iAzul);
  Assert.AreEqual('#1A2B3C', ComponerHexAtributo(iRojo, iVerde, iAzul));
  // El valor llega del grid con espacios: se normaliza antes de leerlo.
  Assert.IsTrue(DescomponerHexAtributo('  #FFFFFF ', iRojo, iVerde, iAzul));
  Assert.AreEqual(255, iRojo);
end;

procedure TPruebasArticulosAtributosBasicos.
  Hex_RechazaTextoQueNoEsColor;
var
  iRojo, iVerde, iAzul: Integer;
begin
  Assert.IsFalse(DescomponerHexAtributo('', iRojo, iVerde, iAzul));
  Assert.IsFalse(DescomponerHexAtributo('AZUL', iRojo, iVerde, iAzul));
  Assert.IsFalse(DescomponerHexAtributo('#12345', iRojo, iVerde, iAzul));
  Assert.IsFalse(DescomponerHexAtributo('1A2B3C7', iRojo, iVerde, iAzul));
  Assert.IsFalse(DescomponerHexAtributo('#GG0000', iRojo, iVerde, iAzul));
end;

procedure TPruebasArticulosAtributosBasicos.
  Hex_DecideElColorDelTextoPorLuminancia;
begin
  Assert.IsTrue(EsColorOscuroAtributo(0, 0, 0));
  Assert.IsTrue(EsColorOscuroAtributo(0, 0, 255));
  Assert.IsFalse(EsColorOscuroAtributo(255, 255, 255));
  Assert.IsFalse(EsColorOscuroAtributo(0, 255, 0));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasArticulosAtributosBasicos);

end.
