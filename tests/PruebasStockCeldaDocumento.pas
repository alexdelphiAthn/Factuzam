{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasStockCeldaDocumento                                    }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fija el comportamiento de las reglas de la celda de stock para el         }
{    documento de trabajo, extraidas de                                        }
{    TfrmStockConsulta.ResolverCeldaDocumentoTrabajo. Sin VCL y sin BBDD.      }
{******************************************************************************}
unit PruebasStockCeldaDocumento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasStockCeldaDocumento = class
  public
    // --- guardas ---
    [Test]
    procedure Guarda_SinArticulo;
    [Test]
    procedure Guarda_EstadoNoExistenciasEnModoNormal;
    [Test]
    procedure Guarda_ModoTodoIgnoraElEstadoDelCombo;
    [Test]
    procedure Guarda_SinFilaEnfocada;
    [Test]
    procedure Guarda_SinColumnaDeDatos;
    [Test]
    procedure Guarda_FilaNoExistenciasEnModoTodo;

    // --- talla segun la columna ---
    [Test]
    procedure Talla_ColumnaTConIndiceValido;
    [Test]
    procedure Talla_ColumnaTFueraDeRango;
    [Test]
    procedure Talla_ColumnaTSinNumero;
    [Test]
    procedure Talla_TotalSinTallasEsValida;
    [Test]
    procedure Talla_TotalConTallasNoVale;
    [Test]
    procedure Talla_TotalEnMinusculasTambienVale;

    // --- grupo, almacen y color ---
    [Test]
    procedure Grupo_SinColumnaGrupoBloquea;
    [Test]
    procedure ModoColor_AlmacenUnicoResuelve;
    [Test]
    procedure ModoColor_VariosAlmacenesBloquean;
    [Test]
    procedure ModoAlmacen_ColorUnicoResuelve;
    [Test]
    procedure ModoAlmacen_SinColoresNiListaResuelveVacio;
    [Test]
    procedure ModoAlmacen_SinSeleccionConListaBloquea;
    [Test]
    procedure ModoAlmacen_VariosColoresBloquean;

    // --- composicion de la linea ---
    [Test]
    procedure Linea_CantidadNulaViajaComoCero;
    [Test]
    procedure Linea_CamposYOrigen;
    [Test]
    procedure Linea_DescripcionSkuSoloConColorOTalla;
  end;

implementation

uses
  System.SysUtils,
  inLibStockCeldaDocumento;

function EstadoBase: TEstadoCeldaStock;
begin
  Result := Default(TEstadoCeldaStock);
  Result.CodigoArticulo := 'ART1';
  Result.EstadoEsExistencias := True;
  Result.HayFila := True;
  Result.HayColumnaDeDatos := True;
  Result.HayColumnaGrupo := True;
  Result.NombreCampo := 'T0';
  Result.Tallas := ['38', '40', '42'];
  Result.Grupo := 'ALM1';
  Result.ColoresSeleccionados := ['ROJO'];
end;

{ --- guardas --- }

procedure TPruebasStockCeldaDocumento.Guarda_SinArticulo;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.CodigoArticulo := '   ';
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdSinArticulo);
end;

procedure TPruebasStockCeldaDocumento.
  Guarda_EstadoNoExistenciasEnModoNormal;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.EstadoEsExistencias := False;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo =
      mcdEstadoNoExistencias);
end;

procedure TPruebasStockCeldaDocumento.
  Guarda_ModoTodoIgnoraElEstadoDelCombo;
var
  E: TEstadoCeldaStock;
begin
  // En modo "Todo a la vez" manda la fila, no el combo de estado.
  E := EstadoBase;
  E.EsModoTodo := True;
  E.EstadoEsExistencias := False;
  E.FilaEsExistencias := True;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdNinguno);
end;

procedure TPruebasStockCeldaDocumento.Guarda_SinFilaEnfocada;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.HayFila := False;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdSinFila);
end;

procedure TPruebasStockCeldaDocumento.Guarda_SinColumnaDeDatos;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.HayColumnaDeDatos := False;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo =
      mcdSinColumnaCantidad);
end;

procedure TPruebasStockCeldaDocumento.
  Guarda_FilaNoExistenciasEnModoTodo;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.EsModoTodo := True;
  E.FilaEsExistencias := False;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo =
      mcdFilaNoExistencias);
end;

{ --- talla segun la columna --- }

procedure TPruebasStockCeldaDocumento.Talla_ColumnaTConIndiceValido;
var
  E: TEstadoCeldaStock;
  R: TCeldaDocumentoResuelta;
begin
  E := EstadoBase;
  E.NombreCampo := 'T2';
  R := ResolverCeldaStockParaDocumento(E);
  Assert.IsTrue(R.Motivo = mcdNinguno);
  Assert.AreEqual('42', R.Talla);
end;

procedure TPruebasStockCeldaDocumento.Talla_ColumnaTFueraDeRango;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.NombreCampo := 'T3';
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdColumnaNoValida);
end;

procedure TPruebasStockCeldaDocumento.Talla_ColumnaTSinNumero;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.NombreCampo := 'TX';
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdColumnaNoValida);
end;

procedure TPruebasStockCeldaDocumento.Talla_TotalSinTallasEsValida;
var
  E: TEstadoCeldaStock;
  R: TCeldaDocumentoResuelta;
begin
  // Articulo sin desglose por tallas: la celda valida es TOTAL.
  E := EstadoBase;
  E.Tallas := nil;
  E.NombreCampo := 'TOTAL';
  R := ResolverCeldaStockParaDocumento(E);
  Assert.IsTrue(R.Motivo = mcdNinguno);
  Assert.AreEqual('', R.Talla);
end;

procedure TPruebasStockCeldaDocumento.Talla_TotalConTallasNoVale;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.NombreCampo := 'TOTAL';
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdColumnaNoValida);
end;

procedure TPruebasStockCeldaDocumento.
  Talla_TotalEnMinusculasTambienVale;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.Tallas := nil;
  E.NombreCampo := 'total';
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdNinguno);
end;

{ --- grupo, almacen y color --- }

procedure TPruebasStockCeldaDocumento.Grupo_SinColumnaGrupoBloquea;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.HayColumnaGrupo := False;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdGrupoNoLeido);
end;

procedure TPruebasStockCeldaDocumento.ModoColor_AlmacenUnicoResuelve;
var
  E: TEstadoCeldaStock;
  R: TCeldaDocumentoResuelta;
begin
  E := EstadoBase;
  E.EsModoColor := True;
  E.Grupo := 'ROJO';
  E.AlmacenesSeleccionados := ['ALM1'];
  R := ResolverCeldaStockParaDocumento(E);
  Assert.IsTrue(R.Motivo = mcdNinguno);
  Assert.AreEqual('ROJO', R.Color);
  Assert.AreEqual('ALM1', R.Almacen);
end;

procedure TPruebasStockCeldaDocumento.
  ModoColor_VariosAlmacenesBloquean;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.EsModoColor := True;
  E.AlmacenesSeleccionados := ['ALM1', 'ALM2'];
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdAlmacenNoUnico);
end;

procedure TPruebasStockCeldaDocumento.ModoAlmacen_ColorUnicoResuelve;
var
  E: TEstadoCeldaStock;
  R: TCeldaDocumentoResuelta;
begin
  E := EstadoBase;
  R := ResolverCeldaStockParaDocumento(E);
  Assert.IsTrue(R.Motivo = mcdNinguno);
  Assert.AreEqual('ALM1', R.Almacen);
  Assert.AreEqual('ROJO', R.Color);
end;

procedure TPruebasStockCeldaDocumento.
  ModoAlmacen_SinColoresNiListaResuelveVacio;
var
  E: TEstadoCeldaStock;
  R: TCeldaDocumentoResuelta;
begin
  // Articulo sin colores: la lista esta vacia y no hay seleccion.
  E := EstadoBase;
  E.ColoresSeleccionados := nil;
  E.HayColoresEnLista := False;
  R := ResolverCeldaStockParaDocumento(E);
  Assert.IsTrue(R.Motivo = mcdNinguno);
  Assert.AreEqual('', R.Color);
end;

procedure TPruebasStockCeldaDocumento.
  ModoAlmacen_SinSeleccionConListaBloquea;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.ColoresSeleccionados := nil;
  E.HayColoresEnLista := True;
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdColorNoUnico);
end;

procedure TPruebasStockCeldaDocumento.ModoAlmacen_VariosColoresBloquean;
var
  E: TEstadoCeldaStock;
begin
  E := EstadoBase;
  E.ColoresSeleccionados := ['ROJO', 'AZUL'];
  Assert.IsTrue(
    ResolverCeldaStockParaDocumento(E).Motivo = mcdColorNoUnico);
end;

{ --- composicion de la linea --- }

procedure TPruebasStockCeldaDocumento.Linea_CantidadNulaViajaComoCero;
var
  L: TLineaCeldaStock;
begin
  L := ComponerLineaCeldaStock('ART1', 'ALM1', 'SKU1', 'ROJO', '40',
                               99, True);
  Assert.AreEqual(Double(0), L.CantidadStock, 0.0001);
  Assert.AreEqual(Double(0), L.Cantidad, 0.0001);
end;

procedure TPruebasStockCeldaDocumento.Linea_CamposYOrigen;
var
  L: TLineaCeldaStock;
begin
  L := ComponerLineaCeldaStock('ART1', 'ALM1', 'SKU1', 'ROJO', '40',
                               3.5, False);
  Assert.AreEqual('ART1', L.CodigoArticulo);
  Assert.AreEqual('ALM1', L.CodigoAlmacen);
  Assert.AreEqual('SKU1', L.CodigoSku);
  Assert.AreEqual('CTRL_U', L.Origen);
  Assert.AreEqual(Double(3.5), L.CantidadStock, 0.0001);
  Assert.AreEqual(Double(3.5), L.Cantidad, 0.0001);
  Assert.AreEqual('ROJO 40', L.DescripcionSku);
end;

procedure TPruebasStockCeldaDocumento.
  Linea_DescripcionSkuSoloConColorOTalla;
begin
  Assert.AreEqual('',
    ComponerLineaCeldaStock('ART1', 'ALM1', '', '', '',
                            1, False).DescripcionSku);
  Assert.AreEqual('40',
    ComponerLineaCeldaStock('ART1', 'ALM1', '', '', '40',
                            1, False).DescripcionSku);
  Assert.AreEqual('ROJO',
    ComponerLineaCeldaStock('ART1', 'ALM1', '', 'ROJO', '',
                            1, False).DescripcionSku);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasStockCeldaDocumento);

end.
