{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasGestorPerfilesMto                                     }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del gestor de perfiles de pantalla de mantenimientos.             }
{******************************************************************************}
unit PruebasGestorPerfilesMto;

interface

uses
  System.Generics.Collections, Vcl.Forms, Data.DB, DUnitX.TestFramework,
  cxLabel, inLibPerfilesUsuarioIntf, inLibGestorPerfilesMto;

type
  TServicioPerfilesPrueba = class(
    TInterfacedObject, IPerfilesUsuario)
  private
    FValores: TProfileDicc;
    FGrabados: TPerfilList;
    FEliminaciones: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DefinirValor(
      const ASubclave, AValor: string);
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    procedure PrecargarPerfilesUsuario;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    procedure ResincronizarPerfilFormulario(
      const AFormulario: string);
    procedure InvalidarCachePerfiles;
    property Grabados: TPerfilList read FGrabados;
    property Eliminaciones: Integer read FEliminaciones;
  end;

  [TestFixture]
  TPruebasGestorPerfilesMto = class
  private
    FFormulario: TForm;
    FDatos: TDataSource;
    FEtiqueta: TcxLabel;
    FServicioObjeto: TServicioPerfilesPrueba;
    FServicio: IPerfilesUsuario;
    FGestor: TGestorPerfilesMto;
    FReseteos: Integer;
    FBorradosGuias: Integer;
    FDescripcionEditable: Boolean;
    FUltimoGrid: string;
    procedure RecogerParticular(
      var APerfiles: TPerfilList;
      const APermisos: string);
    procedure ResetearGrid(
      const ANombreGrid, ANombreFormulario, APermisos: string);
    procedure BorrarGuias;
    function SolicitarDestino(
      const ADescripcion: string;
      ADescripcionEditable: Boolean;
      out APermisos: string): Boolean;
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Carga_ExponeValoresYAplicaCaption;
    [Test]
    procedure PerfilesComunes_GrabaSeisValores;
    [Test]
    procedure Construccion_IncluyeComunesYParticular;
    [Test]
    procedure Reset_RecorreGridsYBorraGuias;
  end;

implementation

uses
  System.SysUtils, cxGridDBTableView;

constructor TServicioPerfilesPrueba.Create;
begin
  inherited Create;
  FValores := TProfileDicc.Create;
  FGrabados := TPerfilList.Create;
  FEliminaciones := 0;
end;

destructor TServicioPerfilesPrueba.Destroy;
begin
  FreeAndNil(FGrabados);
  FreeAndNil(FValores);
  inherited;
end;

procedure TServicioPerfilesPrueba.DefinirValor(
  const ASubclave, AValor: string);
var
  oValor: TDictValue;
begin
  oValor.sValue := AValor;
  oValor.sValueText := '';
  FValores.AddOrSetValue(ASubclave, oValor);
end;

procedure TServicioPerfilesPrueba.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
var
  oItem: TPerfilItem;
begin
  oItem.UserGroup := AUsuarioGrupo;
  oItem.KeyPerfil := AClave;
  oItem.SubKey := ASubclave;
  oItem.Value := AValor;
  FGrabados.Add(oItem);
end;

procedure TServicioPerfilesPrueba.GrabarPerfiles(
  const APerfiles: TPerfilList);
var
  oItem: TPerfilItem;
begin
  for oItem in APerfiles do
    FGrabados.Add(oItem);
end;

procedure TServicioPerfilesPrueba.EliminarPerfil(
  const AUsuarioGrupo, AClave, ASubclave: string);
begin
  Inc(FEliminaciones);
end;

function TServicioPerfilesPrueba.ObtenerValorPerfil(
  const AClave, ASubclave, AValorPredeterminado: string): string;
var
  oValor: TDictValue;
begin
  Result := AValorPredeterminado;
  if FValores.TryGetValue(ASubclave, oValor) then
    Result := oValor.sValue;
end;

function TServicioPerfilesPrueba.ObtenerSubclavePerfil(
  const AClave, AValorPredeterminado: string): string;
begin
  Result := AValorPredeterminado;
end;

procedure TServicioPerfilesPrueba.PrecargarPerfilesUsuario;
begin
end;

function TServicioPerfilesPrueba.CargarPerfilFormulario(
  const AFormulario: string;
  out APerfil: TProfileDicc): Boolean;
begin
  Result := CargarPerfilFormulario(
    AFormulario, '', '', APerfil);
end;

function TServicioPerfilesPrueba.CargarPerfilFormulario(
  const AFormulario, AUsuario, AGrupo: string;
  out APerfil: TProfileDicc): Boolean;
var
  oPar: TPair<string, TDictValue>;
begin
  APerfil := TProfileDicc.Create;
  for oPar in FValores do
    APerfil.AddOrSetValue(oPar.Key, oPar.Value);
  Result := True;
end;

procedure TServicioPerfilesPrueba.ResincronizarPerfilFormulario(
  const AFormulario: string);
begin
end;

procedure TServicioPerfilesPrueba.InvalidarCachePerfiles;
begin
end;

procedure TPruebasGestorPerfilesMto.Preparar;
begin
  FFormulario := TForm.CreateNew(nil);
  FFormulario.Name := 'frmPrueba';
  FFormulario.Caption := 'Original';
  FDatos := TDataSource.Create(FFormulario);
  FEtiqueta := TcxLabel.Create(FFormulario);
  FServicioObjeto := TServicioPerfilesPrueba.Create;
  FServicio := FServicioObjeto;
  FReseteos := 0;
  FBorradosGuias := 0;
  FDescripcionEditable := False;
  FUltimoGrid := '';
  FGestor := TGestorPerfilesMto.Create(
    FFormulario, FDatos, FEtiqueta, FServicio,
    SolicitarDestino, RecogerParticular,
    ResetearGrid, BorrarGuias);
end;

procedure TPruebasGestorPerfilesMto.Limpiar;
begin
  FreeAndNil(FGestor);
  FServicio := nil;
  FServicioObjeto := nil;
  FreeAndNil(FFormulario);
end;

procedure TPruebasGestorPerfilesMto.RecogerParticular(
  var APerfiles: TPerfilList;
  const APermisos: string);
var
  oItem: TPerfilItem;
begin
  oItem.UserGroup := APermisos;
  oItem.KeyPerfil := FFormulario.Name;
  oItem.SubKey := 'Particular';
  oItem.Value := 'S';
  APerfiles.Add(oItem);
end;

procedure TPruebasGestorPerfilesMto.ResetearGrid(
  const ANombreGrid, ANombreFormulario, APermisos: string);
begin
  Inc(FReseteos);
  FUltimoGrid := ANombreGrid;
end;

procedure TPruebasGestorPerfilesMto.BorrarGuias;
begin
  Inc(FBorradosGuias);
end;

function TPruebasGestorPerfilesMto.SolicitarDestino(
  const ADescripcion: string;
  ADescripcionEditable: Boolean;
  out APermisos: string): Boolean;
begin
  FDescripcionEditable := ADescripcionEditable;
  APermisos := 'Grupo';
  Result := True;
end;

procedure TPruebasGestorPerfilesMto.
  Carga_ExponeValoresYAplicaCaption;
begin
  FServicioObjeto.DefinirValor(
    'Caption', 'Perfil activo');
  FServicioObjeto.DefinirValor(
    'oBusqGlobal', 'Grid');
  FEtiqueta.Caption := 'Tabla de diseño';
  FGestor.CargarPerfil('usuario', 'grupo');
  Assert.AreEqual(
    'Grid', FGestor.Valor('oBusqGlobal', 'Database'));
  Assert.AreEqual(
    'Predeterminado',
    FGestor.Valor('NoExiste', 'Predeterminado'));
  FGestor.AplicarEtiquetas;
  Assert.AreEqual('Perfil activo', FFormulario.Caption);
  Assert.AreEqual('Tabla de diseño', FEtiqueta.Caption);
end;

procedure TPruebasGestorPerfilesMto.
  PerfilesComunes_GrabaSeisValores;
begin
  FGestor.CargarPerfilesComunes;
  Assert.AreEqual(6, Integer(FServicioObjeto.Grabados.Count));
  Assert.AreEqual(
    'oRenameComponents',
    FServicioObjeto.Grabados[0].SubKey);
  Assert.AreEqual(
    'oGetSQLFromDB',
    FServicioObjeto.Grabados[5].SubKey);
  Assert.AreEqual(
    PERFIL_TODOS,
    FServicioObjeto.Grabados[5].UserGroup);
end;

procedure TPruebasGestorPerfilesMto.
  Construccion_IncluyeComunesYParticular;
var
  oPerfiles: TPerfilList;
begin
  FServicioObjeto.DefinirValor(
    'oBusqGlobal', 'Database');
  FGestor.CargarPerfil('usuario', 'grupo');
  oPerfiles := TPerfilList.Create;
  try
    FGestor.ConstruirPerfilesLayout(
      'Administradores', oPerfiles);
    Assert.AreEqual(7, Integer(oPerfiles.Count));
    Assert.AreEqual('Database', oPerfiles[2].Value);
    Assert.AreEqual('Particular', oPerfiles[6].SubKey);
    Assert.AreEqual(
      'Administradores', oPerfiles[6].UserGroup);
  finally
    FreeAndNil(oPerfiles);
  end;
end;

procedure TPruebasGestorPerfilesMto.
  Reset_RecorreGridsYBorraGuias;
var
  oGrid: TcxGridDBTableView;
begin
  oGrid := TcxGridDBTableView.Create(FFormulario);
  oGrid.Name := 'tvPrueba';
  FGestor.ResetearLayout('Reset Grids');
  Assert.AreEqual(1, FReseteos);
  Assert.AreEqual('tvPrueba', FUltimoGrid);
  Assert.AreEqual(1, FBorradosGuias);
  Assert.IsTrue(FDescripcionEditable);
end;

end.
