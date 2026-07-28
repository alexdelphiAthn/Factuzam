{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorFiltrosMto                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del gestor de filtros guardados de los mantenimientos.            }
{******************************************************************************}
unit PruebasGestorFiltrosMto;

interface

uses
  System.Classes, Vcl.ExtCtrls, Vcl.Menus, DUnitX.TestFramework,
  Data.DB, Datasnap.DBClient, cxGridDBTableView, cxTextEdit,
  inLibGestorFiltrosMto;

type
  [TestFixture]
  TPruebasGestorFiltrosMto = class
  private
    FPropietario: TComponent;
    FDataSet: TClientDataSet;
    FDataSource: TDataSource;
    FVista: TcxGridDBTableView;
    FEditor: TcxTextEdit;
    FTemporizador: TTimer;
    FMenu: TPopupMenu;
    FGestor: TGestorFiltrosMto;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure BusquedaGlobal_ExtraeTextoComun;
    [Test]
    procedure BusquedaGlobal_RechazaTextosDistintos;
    [Test]
    procedure Serializacion_RestauraFiltroYEditor;
    [Test]
    procedure Captura_RestauraBusquedaGlobal;
    [Test]
    procedure Menu_SinServicioConservaAcciones;
  end;

implementation

uses
  System.SysUtils, cxFilter, inLibDevExp;

procedure TPruebasGestorFiltrosMto.Preparar;
var
  oColumna: TcxGridDBColumn;
begin
  FPropietario := TComponent.Create(nil);
  FPropietario.Name := 'frmPrueba';
  FDataSet := TClientDataSet.Create(nil);
  FDataSet.FieldDefs.Add('NOMBRE', ftString, 50);
  FDataSet.FieldDefs.Add('CODIGO', ftString, 20);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord(['Rojo', 'R']);
  FDataSource := TDataSource.Create(nil);
  FDataSource.DataSet := FDataSet;
  FVista := TcxGridDBTableView.Create(nil);
  FVista.Name := 'tvPrueba';
  FVista.DataController.DataSource := FDataSource;
  oColumna := FVista.CreateColumn;
  oColumna.DataBinding.FieldName := 'NOMBRE';
  oColumna := FVista.CreateColumn;
  oColumna.DataBinding.FieldName := 'CODIGO';
  FEditor := TcxTextEdit.Create(nil);
  FTemporizador := TTimer.Create(nil);
  FMenu := TPopupMenu.Create(nil);
  FGestor := TGestorFiltrosMto.Create(
    FPropietario, FVista, FEditor, FTemporizador,
    FMenu, nil, nil, nil);
end;

procedure TPruebasGestorFiltrosMto.Limpiar;
begin
  FreeAndNil(FGestor);
  FreeAndNil(FMenu);
  FreeAndNil(FTemporizador);
  FreeAndNil(FEditor);
  FVista.DataController.DataSource := nil;
  FreeAndNil(FVista);
  FDataSource.DataSet := nil;
  FreeAndNil(FDataSource);
  FreeAndNil(FDataSet);
  FreeAndNil(FPropietario);
end;

procedure TPruebasGestorFiltrosMto.
  BusquedaGlobal_ExtraeTextoComun;
begin
  BusqAllGrid(FVista, 'rojo');
  Assert.AreEqual('rojo', FGestor.ExtraerBusquedaGlobal);
end;

procedure TPruebasGestorFiltrosMto.
  BusquedaGlobal_RechazaTextosDistintos;
begin
  FVista.DataController.Filter.Root.Clear;
  FVista.DataController.Filter.Root.BoolOperatorKind := fboOr;
  FVista.DataController.Filter.Root.AddItem(
    FVista.Columns[0], foLike, '%rojo%', '%rojo%');
  FVista.DataController.Filter.Root.AddItem(
    FVista.Columns[1], foLike, '%azul%', '%azul%');
  FVista.DataController.Filter.Active := True;
  Assert.AreEqual('', FGestor.ExtraerBusquedaGlobal);
end;

procedure TPruebasGestorFiltrosMto.
  Serializacion_RestauraFiltroYEditor;
var
  sFiltroBase64: string;
begin
  BusqAllGrid(FVista, 'rojo');
  sFiltroBase64 := FGestor.SerializarActualBase64;
  BusqAllGrid(FVista, '');
  FEditor.Text := '';
  Assert.IsTrue(FVista.DataController.Filter.IsEmpty);
  FGestor.AplicarDesdeBase64(sFiltroBase64);
  Assert.IsFalse(FVista.DataController.Filter.IsEmpty);
  Assert.IsTrue(FVista.DataController.Filter.Active);
  Assert.AreEqual('rojo', FEditor.Text);
end;

procedure TPruebasGestorFiltrosMto.
  Captura_RestauraBusquedaGlobal;
begin
  FEditor.Text := 'rojo';
  FTemporizador.Enabled := True;
  FGestor.CapturarActual;
  Assert.IsFalse(FTemporizador.Enabled);
  Assert.AreEqual('rojo', FGestor.BusquedaCapturada);
  Assert.AreNotEqual('', FGestor.FiltroCapturadoBase64);
  FEditor.Text := 'azul';
  BusqAllGrid(FVista, 'azul');
  FGestor.RestaurarCapturado;
  Assert.AreEqual('rojo', FEditor.Text);
  Assert.AreEqual('rojo', FGestor.ExtraerBusquedaGlobal);
end;

procedure TPruebasGestorFiltrosMto.
  Menu_SinServicioConservaAcciones;
begin
  FGestor.CargarMenu;
  Assert.AreEqual(3, FMenu.Items.Count);
  Assert.AreEqual('-', FMenu.Items[0].Caption);
  Assert.AreEqual('Guardar filtro actual...',
    FMenu.Items[1].Caption);
  Assert.AreEqual('Gestionar y compartir filtros...',
    FMenu.Items[2].Caption);
end;

end.
