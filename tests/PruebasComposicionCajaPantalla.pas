{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComposicionCajaPantalla                               }
{    Tipo:       Pruebas DUnitX                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza composición, ficha y transacción de históricos de Caja.      }
{******************************************************************************}
unit PruebasComposicionCajaPantalla;

interface

uses
  DUnitX.TestFramework,
  inLibPerfilesUsuarioIntf,
  inLibCajaPantallaHistoricosIntf;

type
  [TestFixture]
  TPruebasComposicionCajaPantalla = class
  public
    [Test]
    procedure FichaDetalle_ConservaSieteSeccionesYOchoVistas;
    [Test]
    procedure FichaDetalle_ConservaCamposCriticos;
    [Test]
    procedure Historicos_ConfirmaAlGrabar;
    [Test]
    procedure Historicos_RevierteYPropagaElError;
    [Test]
    procedure Composicion_RechazaContextoAusente;
  end;

implementation

uses
  System.SysUtils,
  inLibCajaPantallaHistoricos,
  inLibCajaPantallaDetalleHistorico,
  UniDataCajaPantallaComposicion;

type
  TUnidadTrabajoPerfilesCajaFalsa = class(
    TInterfacedObject,
    IUnidadTrabajoPerfilesCaja)
  private
    FInicios: Integer;
    FConfirmaciones: Integer;
    FReversiones: Integer;
  public
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
    property Inicios: Integer read FInicios;
    property Confirmaciones: Integer read FConfirmaciones;
    property Reversiones: Integer read FReversiones;
  end;

  TEscritorPerfilesCajaFalso = class(
    TInterfacedObject,
    IEscritorPerfilesUsuario)
  private
    FDebeFallar: Boolean;
    FGrabaciones: Integer;
  public
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    property DebeFallar: Boolean read FDebeFallar write FDebeFallar;
    property Grabaciones: Integer read FGrabaciones;
  end;

procedure TUnidadTrabajoPerfilesCajaFalsa.Iniciar;
begin
  Inc(FInicios);
end;

procedure TUnidadTrabajoPerfilesCajaFalsa.Confirmar;
begin
  Inc(FConfirmaciones);
end;

procedure TUnidadTrabajoPerfilesCajaFalsa.Revertir;
begin
  Inc(FReversiones);
end;

procedure TEscritorPerfilesCajaFalso.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
begin
  Inc(FGrabaciones);
end;

procedure TEscritorPerfilesCajaFalso.GrabarPerfiles(
  const APerfiles: TPerfilList);
begin
  Inc(FGrabaciones);
  if FDebeFallar then
    raise EAbort.Create('Fallo de escritura simulado.');
end;

procedure TEscritorPerfilesCajaFalso.EliminarPerfil(
  const AUsuarioGrupo, AClave, ASubclave: string);
begin
  Inc(FGrabaciones);
end;

procedure TPruebasComposicionCajaPantalla.
  FichaDetalle_ConservaSieteSeccionesYOchoVistas;
var
  aModelo: TModeloFichaDetalleCaja;
  i: Integer;
  iVistas: Integer;
begin
  aModelo := CargarModeloFichaDetalleCaja;
  iVistas := 0;
  for i := 0 to High(aModelo) do
    Inc(iVistas, Length(aModelo[i].Vistas));
  Assert.AreEqual(7, Integer(Length(aModelo)));
  Assert.AreEqual(8, iVistas);
  Assert.AreEqual('Operación', aModelo[0].Titulo);
  Assert.AreEqual('Borrador', aModelo[6].Titulo);
end;

procedure TPruebasComposicionCajaPantalla.
  FichaDetalle_ConservaCamposCriticos;
var
  aModelo: TModeloFichaDetalleCaja;
  bImporteOperacion: Boolean;
  bTotalFactura: Boolean;
  i: Integer;
  j: Integer;
  k: Integer;
begin
  aModelo := CargarModeloFichaDetalleCaja;
  bImporteOperacion := False;
  bTotalFactura := False;
  for i := 0 to High(aModelo) do
  begin
    for j := 0 to High(aModelo[i].Vistas) do
    begin
      for k := 0 to High(aModelo[i].Vistas[j].Columnas) do
      begin
        if aModelo[i].Vistas[j].Columnas[k].Campo =
           'IMPORTE_TOTAL_OPCAJA' then
          bImporteOperacion := True;
        if aModelo[i].Vistas[j].Columnas[k].Campo = 'TOTAL_FACLIN' then
          bTotalFactura := True;
      end;
    end;
  end;
  Assert.IsTrue(bImporteOperacion);
  Assert.IsTrue(bTotalFactura);
end;

procedure TPruebasComposicionCajaPantalla.Historicos_ConfirmaAlGrabar;
var
  oEscritor: TEscritorPerfilesCajaFalso;
  oGrabador: IGrabadorPerfilesHistoricoCaja;
  oPerfiles: TPerfilList;
  oUnidad: TUnidadTrabajoPerfilesCajaFalsa;
begin
  oUnidad := TUnidadTrabajoPerfilesCajaFalsa.Create;
  oEscritor := TEscritorPerfilesCajaFalso.Create;
  oGrabador := TGrabadorPerfilesHistoricoCaja.Create(oUnidad, oEscritor);
  oPerfiles := TPerfilList.Create;
  try
    oGrabador.Grabar(oPerfiles);
    Assert.AreEqual(1, oUnidad.Inicios);
    Assert.AreEqual(1, oEscritor.Grabaciones);
    Assert.AreEqual(1, oUnidad.Confirmaciones);
    Assert.AreEqual(0, oUnidad.Reversiones);
  finally
    FreeAndNil(oPerfiles);
    oGrabador := nil;
  end;
end;

procedure TPruebasComposicionCajaPantalla.
  Historicos_RevierteYPropagaElError;
var
  bErrorPropagado: Boolean;
  oEscritor: TEscritorPerfilesCajaFalso;
  oGrabador: IGrabadorPerfilesHistoricoCaja;
  oPerfiles: TPerfilList;
  oUnidad: TUnidadTrabajoPerfilesCajaFalsa;
begin
  oUnidad := TUnidadTrabajoPerfilesCajaFalsa.Create;
  oEscritor := TEscritorPerfilesCajaFalso.Create;
  oEscritor.DebeFallar := True;
  oGrabador := TGrabadorPerfilesHistoricoCaja.Create(oUnidad, oEscritor);
  oPerfiles := TPerfilList.Create;
  bErrorPropagado := False;
  try
    try
      oGrabador.Grabar(oPerfiles);
    except
      on E: EAbort do
        bErrorPropagado := True;
    end;
    Assert.IsTrue(bErrorPropagado);
    Assert.AreEqual(1, oUnidad.Inicios);
    Assert.AreEqual(0, oUnidad.Confirmaciones);
    Assert.AreEqual(1, oUnidad.Reversiones);
  finally
    FreeAndNil(oPerfiles);
    oGrabador := nil;
  end;
end;

procedure TPruebasComposicionCajaPantalla.
  Composicion_RechazaContextoAusente;
var
  bErrorPropagado: Boolean;
begin
  bErrorPropagado := False;
  try
    ComponerCajaPantalla(nil);
  except
    on E: Exception do
      bErrorPropagado := True;
  end;
  Assert.IsTrue(bErrorPropagado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComposicionCajaPantalla);

end.
