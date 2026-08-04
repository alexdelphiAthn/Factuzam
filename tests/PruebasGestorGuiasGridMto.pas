{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorGuiasGridMto                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del gestor de guías y columnas de mantenimientos.                 }
{******************************************************************************}
unit PruebasGestorGuiasGridMto;

interface

uses
  Vcl.Forms, Vcl.Menus, DUnitX.TestFramework, cxGrid,
  cxGridDBTableView, inLibGestorGuiasGridMto,
  inLibGuiasGridPersistenciaIntf, inLibInformesGuiasCache;

type
  TPersistenciaGuiasPrueba = class(
    TInterfacedObject,
    IPersistenciaGuiasGrid)
  private
    FBorrados: Integer;
    FUltimoInforme: string;
  public
    function Enriquecer(
      const ASqlOriginal: string;
      const AParametros: TArray<TParametroConsultaGuia>;
      const AGuias: TArray<TInformeGuiaItem>
    ): TResultadoEnriquecimientoGuias;
    procedure Borrar(const AInforme: string);
    procedure GuardarColumnasVisibles(
      const AInforme, AColumnas: string);
    property Borrados: Integer read FBorrados;
    property UltimoInforme: string read FUltimoInforme;
  end;

  [TestFixture]
  TPruebasGestorGuiasGridMto = class
  private
    FFormulario: TForm;
    FGrid: TcxGrid;
    FVista: TcxGridDBTableView;
    FColumnaNormal: TcxGridDBColumn;
    FColumnaGuia: TcxGridDBColumn;
    FGestor: TGestorGuiasGridMto;
    FPersistenciaObjeto: TPersistenciaGuiasPrueba;
    FPersistencia: IPersistenciaGuiasGrid;
    function BuscarItemRaiz(
      const ACaption: string): TMenuItem;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Listas_CopianEstadoRecibido;
    [Test]
    procedure Visibilidad_RespetaSeleccionGuardada;
    [Test]
    procedure Menu_AgrupaColumnasGuiaPorTabla;
    [Test]
    procedure Alternar_InvierteVisibilidad;
    [Test]
    procedure Limpiar_EliminaSoloColumnasGuia;
    [Test]
    procedure Borrar_DelegaEnPersistenciaSinConexion;
  end;

implementation

uses
  System.SysUtils, System.Classes;

function TPersistenciaGuiasPrueba.Enriquecer(
  const ASqlOriginal: string;
  const AParametros: TArray<TParametroConsultaGuia>;
  const AGuias: TArray<TInformeGuiaItem>
): TResultadoEnriquecimientoGuias;
begin
  Result := Default(TResultadoEnriquecimientoGuias);
end;

procedure TPersistenciaGuiasPrueba.Borrar(
  const AInforme: string);
begin
  Inc(FBorrados);
  FUltimoInforme := AInforme;
end;

procedure TPersistenciaGuiasPrueba.GuardarColumnasVisibles(
  const AInforme, AColumnas: string);
begin
  FUltimoInforme := AInforme;
end;

procedure TPruebasGestorGuiasGridMto.Preparar;
begin
  FFormulario := TForm.CreateNew(nil);
  FFormulario.Name := 'frmPrueba';
  FGrid := TcxGrid.Create(FFormulario);
  FVista := TcxGridDBTableView.Create(FFormulario);
  FColumnaNormal :=
    FVista.CreateColumn as TcxGridDBColumn;
  FColumnaNormal.DataBinding.FieldName := 'CODIGO';
  FColumnaNormal.Caption := 'Código';
  FColumnaNormal.Visible := True;
  FColumnaGuia :=
    FVista.CreateColumn as TcxGridDBColumn;
  FColumnaGuia.DataBinding.FieldName := 'EXTRA';
  FColumnaGuia.Caption := 'Dato extra';
  FColumnaGuia.Visible := True;
  FGestor := TGestorGuiasGridMto.Create(
    FFormulario, FGrid, FVista, nil,
    nil, nil, nil);
  FPersistenciaObjeto := TPersistenciaGuiasPrueba.Create;
  FPersistencia := FPersistenciaObjeto;
  FGestor.AsignarPersistencia(FPersistencia);
end;

procedure TPruebasGestorGuiasGridMto.Limpiar;
begin
  FreeAndNil(FGestor);
  FPersistencia := nil;
  FPersistenciaObjeto := nil;
  FreeAndNil(FFormulario);
end;

function TPruebasGestorGuiasGridMto.BuscarItemRaiz(
  const ACaption: string): TMenuItem;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while (Result = nil) and
        (i < FGestor.Menu.Items.Count) do
  begin
    if FGestor.Menu.Items[i].Caption = ACaption then
      Result := FGestor.Menu.Items[i];
    Inc(i);
  end;
end;

procedure TPruebasGestorGuiasGridMto.
  Listas_CopianEstadoRecibido;
var
  oCampos: TStringList;
  oTablas: TStringList;
  oVisibles: TStringList;
begin
  oCampos := TStringList.Create;
  oTablas := TStringList.Create;
  oVisibles := TStringList.Create;
  try
    oCampos.Add('EXTRA');
    oTablas.Values['EXTRA'] := 'tabla_ext';
    oVisibles.Add('EXTRA');
    FGestor.ActualizarListas(
      oCampos, oTablas, oVisibles);
  finally
    FreeAndNil(oVisibles);
    FreeAndNil(oTablas);
    FreeAndNil(oCampos);
  end;
  Assert.AreEqual(
    1, Integer(FGestor.CamposGuia.Count));
  Assert.AreEqual(
    'tabla_ext',
    FGestor.CamposGuiaTabla.Values['EXTRA']);
  Assert.AreEqual(
    1, Integer(FGestor.ColumnasVisibles.Count));
end;

procedure TPruebasGestorGuiasGridMto.
  Visibilidad_RespetaSeleccionGuardada;
var
  oCampos: TStringList;
  oTablas: TStringList;
  oVisibles: TStringList;
begin
  oCampos := TStringList.Create;
  oTablas := TStringList.Create;
  oVisibles := TStringList.Create;
  try
    oCampos.Add('EXTRA');
    oTablas.Values['EXTRA'] := 'tabla_ext';
    FGestor.ActualizarListas(
      oCampos, oTablas, oVisibles);
    FGestor.ReaplicarVisibilidad;
    Assert.IsFalse(FColumnaGuia.Visible);
    Assert.IsTrue(FColumnaNormal.Visible);
    oVisibles.Add('EXTRA');
    FGestor.ActualizarListas(
      oCampos, oTablas, oVisibles);
    FGestor.ReaplicarVisibilidad;
    Assert.IsTrue(FColumnaGuia.Visible);
  finally
    FreeAndNil(oVisibles);
    FreeAndNil(oTablas);
    FreeAndNil(oCampos);
  end;
end;

procedure TPruebasGestorGuiasGridMto.
  Menu_AgrupaColumnasGuiaPorTabla;
var
  oCampos: TStringList;
  oTablas: TStringList;
  oVisibles: TStringList;
  oSubmenu: TMenuItem;
begin
  oCampos := TStringList.Create;
  oTablas := TStringList.Create;
  oVisibles := TStringList.Create;
  try
    oCampos.Add('EXTRA');
    oTablas.Values['EXTRA'] := 'tabla_ext';
    oVisibles.Add('EXTRA');
    FGestor.ActualizarListas(
      oCampos, oTablas, oVisibles);
  finally
    FreeAndNil(oVisibles);
    FreeAndNil(oTablas);
    FreeAndNil(oCampos);
  end;
  FGestor.ConstruirMenu;
  oSubmenu := BuscarItemRaiz(
    'Guía: tabla_ext');
  Assert.IsTrue(Assigned(oSubmenu));
  Assert.AreEqual(1, oSubmenu.Count);
  Assert.AreEqual(
    'Dato extra', oSubmenu.Items[0].Caption);
  Assert.IsTrue(Assigned(
    BuscarItemRaiz('Código')));
  Assert.IsTrue(Assigned(
    BuscarItemRaiz('Renombrar columna...')));
  Assert.IsTrue(Assigned(
    BuscarItemRaiz('Nueva guía...')));
end;

procedure TPruebasGestorGuiasGridMto.
  Alternar_InvierteVisibilidad;
begin
  Assert.IsTrue(FColumnaNormal.Visible);
  FGestor.AlternarColumna(0);
  Assert.IsFalse(FColumnaNormal.Visible);
  FGestor.AlternarColumna(0);
  Assert.IsTrue(FColumnaNormal.Visible);
end;

procedure TPruebasGestorGuiasGridMto.
  Limpiar_EliminaSoloColumnasGuia;
var
  oCampos: TStringList;
  oTablas: TStringList;
  oVisibles: TStringList;
begin
  oCampos := TStringList.Create;
  oTablas := TStringList.Create;
  oVisibles := TStringList.Create;
  try
    oCampos.Add('EXTRA');
    FGestor.ActualizarListas(
      oCampos, oTablas, oVisibles);
  finally
    FreeAndNil(oVisibles);
    FreeAndNil(oTablas);
    FreeAndNil(oCampos);
  end;
  FGestor.LimpiarColumnasGuia;
  Assert.AreEqual(1, FVista.ColumnCount);
  Assert.AreEqual(
    'CODIGO',
    FVista.Columns[0].DataBinding.FieldName);
  Assert.AreEqual(
    0, Integer(FGestor.CamposGuia.Count));
end;

procedure TPruebasGestorGuiasGridMto.
  Borrar_DelegaEnPersistenciaSinConexion;
begin
  FGestor.BorrarGuias;
  Assert.AreEqual(1, FPersistenciaObjeto.Borrados);
  Assert.AreEqual(
    'GRID:frmPrueba', FPersistenciaObjeto.UltimoInforme);
end;

end.
