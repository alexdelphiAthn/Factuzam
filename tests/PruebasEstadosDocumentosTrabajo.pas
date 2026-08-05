{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasEstadosDocumentosTrabajo                               }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pruebas del ciclo de vida y filtros de Documentos de Trabajo.             }
{******************************************************************************}
unit PruebasEstadosDocumentosTrabajo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasEstadosDocumentosTrabajo = class
  public
    [Test]
    procedure Normalizar_ConvierteAbiertoYVacioEnCreado;
    [Test]
    procedure Estados_SoloAdmiteElCicloDefinido;
    [Test]
    procedure FiltrosSql_SeparanActivosCreadosYArchivados;
    [Test]
    procedure OrdenSql_EsFechaDescendenteConDesempatePorId;
  end;

implementation

uses
  inLibDocumentosTrabajoEstados;

procedure TPruebasEstadosDocumentosTrabajo.
  Normalizar_ConvierteAbiertoYVacioEnCreado;
begin
  Assert.AreEqual(ESTADO_DOCUMENTO_TRABAJO_CREADO,
                  NormalizarEstadoDocumentoTrabajo(''));
  Assert.AreEqual(ESTADO_DOCUMENTO_TRABAJO_CREADO,
                  NormalizarEstadoDocumentoTrabajo(' abierto '));
  Assert.AreEqual(ESTADO_DOCUMENTO_TRABAJO_ENVIADO,
                  NormalizarEstadoDocumentoTrabajo('enviado'));
end;

procedure TPruebasEstadosDocumentosTrabajo.
  Estados_SoloAdmiteElCicloDefinido;
begin
  Assert.IsTrue(EsEstadoDocumentoTrabajoValido('CREADO'));
  Assert.IsTrue(EsEstadoDocumentoTrabajoValido('ENVIADO'));
  Assert.IsTrue(EsEstadoDocumentoTrabajoValido('ARCHIVADO'));
  Assert.IsTrue(EsEstadoDocumentoTrabajoValido('ABIERTO'));
  Assert.IsFalse(EsEstadoDocumentoTrabajoValido('PENDIENTE'));
  Assert.IsTrue(EsDocumentoTrabajoCreado('ABIERTO'));
  Assert.IsTrue(EsDocumentoTrabajoEnviado('ENVIADO'));
  Assert.IsTrue(EsDocumentoTrabajoArchivado('ARCHIVADO'));
end;

procedure TPruebasEstadosDocumentosTrabajo.
  FiltrosSql_SeparanActivosCreadosYArchivados;
var
  sActivos: string;
  sArchivados: string;
  sCreados: string;
begin
  sActivos := CondicionSqlDocumentoTrabajoActivo('d.ESTADO_DTR');
  sCreados := CondicionSqlDocumentoTrabajoCreado('d.ESTADO_DTR');
  sArchivados := CondicionSqlDocumentoTrabajoArchivado('d.ESTADO_DTR');

  Assert.IsTrue(Pos('d.ESTADO_DTR', sActivos) > 0);
  Assert.IsTrue(Pos('<> ''ARCHIVADO''', sActivos) > 0);
  Assert.IsTrue(Pos('''CREADO'', ''ABIERTO''', sCreados) > 0);
  Assert.IsTrue(Pos('= ''ARCHIVADO''', sArchivados) > 0);
end;

procedure TPruebasEstadosDocumentosTrabajo.
  OrdenSql_EsFechaDescendenteConDesempatePorId;
begin
  Assert.AreEqual(
    ' ORDER BY d.INSTANTE_DOCUMENTO_DTR DESC, d.ID_DTR DESC',
    ClausulaOrdenSqlDocumentosTrabajo('d'));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasEstadosDocumentosTrabajo);

end.
