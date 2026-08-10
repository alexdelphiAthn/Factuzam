{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasInformesOla4IA43                                      }
{    Tipo:       Pruebas de arquitectura (DUnitX)                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Impide reintroducir consultas o componentes UniDAC en los modales IA-43. }
{******************************************************************************}
unit PruebasInformesOla4IA43;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInformesOla4IA43 = class
  private
    function RaizRepositorio: string;
    procedure ComprobarModal(const ANombreUnidad: string);
  public
    [Test]
    procedure InformeEfectosPago_SinPersistenciaEnModal;
    [Test]
    procedure InformeFactura_SinPersistenciaEnModal;
    [Test]
    procedure InformeMultiFiltro_SinPersistenciaEnModal;
    [Test]
    procedure InformeRecibosFactura_SinPersistenciaEnModal;
    [Test]
    procedure InformeVerifactuDeclaracion_SinPersistenciaEnModal;
    [Test]
    procedure WizardEditar_SinPersistenciaEnModal;
    [Test]
    procedure InformeBalanceSinTallas_SinPersistenciaEnModal;
    [Test]
    procedure InformeBalanceTallas_SinPersistenciaEnModal;
    [Test]
    procedure InformeDocumentosProveedor_SinPersistenciaEnModal;
    [Test]
    procedure InformeMovimientosVentasArticulo_SinPersistenciaEnModal;
    [Test]
    procedure InformeEtiquetasArticulo_SinPersistenciaEnModal;
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

function TPruebasInformesOla4IA43.RaizRepositorio: string;
var
  i: Integer;
  sPadre: string;
begin
  Result := GetCurrentDir;
  i := 0;
  while (i < 12) and
        (not TFile.Exists(TPath.Combine(Result, 'fzam.dpr'))) do
  begin
    sPadre := TDirectory.GetParent(Result);
    if SameText(sPadre, Result) then
      i := 12
    else
    begin
      Result := sPadre;
      Inc(i);
    end;
  end;
  Assert.IsTrue(TFile.Exists(TPath.Combine(Result, 'fzam.dpr')),
    'No se localizo la raiz del repositorio');
end;

procedure TPruebasInformesOla4IA43.ComprobarModal(
  const ANombreUnidad: string);
var
  sDfm: string;
  sPas: string;
  sRuta: string;
begin
  sRuta := TPath.Combine(RaizRepositorio, 'src\Modals');
  sPas := TFile.ReadAllText(TPath.Combine(sRuta, ANombreUnidad + '.pas'));
  sDfm := TFile.ReadAllText(TPath.Combine(sRuta, ANombreUnidad + '.dfm'));
  Assert.IsTrue(Pos('TUniQuery.Create', sPas) = 0,
    ANombreUnidad + ' crea una consulta en la UI');
  Assert.IsTrue(Pos('SQL.Text', sPas) = 0,
    ANombreUnidad + ' asigna SQL.Text en la UI');
  Assert.IsTrue(Pos('TUniStoredProc.Create', sPas) = 0,
    ANombreUnidad + ' crea un procedimiento almacenado en la UI');
  Assert.IsTrue(Pos(': TUniQuery', sDfm) = 0,
    ANombreUnidad + ' conserva un TUniQuery en el DFM');
  Assert.IsTrue(Pos(': TUniTable', sDfm) = 0,
    ANombreUnidad + ' conserva un TUniTable en el DFM');
  Assert.IsTrue(Pos(': TUniStoredProc', sDfm) = 0,
    ANombreUnidad + ' conserva un TUniStoredProc en el DFM');
end;

procedure TPruebasInformesOla4IA43.
  InformeEfectosPago_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpEfectosPago');
end;

procedure TPruebasInformesOla4IA43.
  InformeFactura_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpFac');
end;

procedure TPruebasInformesOla4IA43.
  InformeMultiFiltro_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpMultiFiltro');
end;

procedure TPruebasInformesOla4IA43.
  InformeRecibosFactura_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpRecFac');
end;

procedure TPruebasInformesOla4IA43.
  InformeVerifactuDeclaracion_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalVerifactuDecl');
end;

procedure TPruebasInformesOla4IA43.
  WizardEditar_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalWizardEditar');
end;

procedure TPruebasInformesOla4IA43.
  InformeBalanceSinTallas_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpBalanceSinTallas');
end;

procedure TPruebasInformesOla4IA43.
  InformeBalanceTallas_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpBalanceTallas');
end;

procedure TPruebasInformesOla4IA43.
  InformeDocumentosProveedor_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpDocsProveedor');
end;

procedure TPruebasInformesOla4IA43.
  InformeMovimientosVentasArticulo_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalImpMovVentasArt');
end;

procedure TPruebasInformesOla4IA43.
  InformeEtiquetasArticulo_SinPersistenciaEnModal;
begin
  ComprobarModal('inMtoModalEtiqArt');
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInformesOla4IA43);

end.
