{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasBusquedasCompra                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de los contratos comunes de búsqueda de compras.                  }
{******************************************************************************}
unit PruebasBusquedasCompra;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasBusquedasCompra = class
  public
    [Test]
    procedure Articulo_ConsultaPuertoYDevuelveSeleccion;
    [Test]
    procedure Sku_ConsultaPuertoYDevuelveSeleccion;
    [Test]
    procedure ValorTexto_ValidaEstadoYCampo;
  end;

implementation

uses
  System.SysUtils, Data.DB, Datasnap.DBClient, Uni, DBAccess, Vcl.Forms,
  inLibBusquedasCompra, inLibBusquedasCompraPersistenciaIntf,
  inLibGenBusq;

type
  TConsultaBusquedaCompraMemoria = class(
    TInterfacedObject,
    IConsultaBusquedaCompra)
  private
    FDatos: TClientDataSet;
  public
    constructor Create(const ACampo, AValor: string);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TBusquedasCompraPersistenciaMemoria = class(
    TInterfacedObject,
    IBusquedasCompraPersistencia)
  private
    FArticuloConsultado: string;
    FSkuConsultado: string;
  public
    function ConsultarArticulosProveedor(
      const ACodigoProveedor: string): IConsultaBusquedaCompra;
    function ConsultarSkusArticulo(
      const ACodigoArticulo: string): IConsultaBusquedaCompra;
    property ArticuloConsultado: string read FArticuloConsultado;
    property SkuConsultado: string read FSkuConsultado;
  end;

  TBusquedaVisualMemoria = class(TInterfacedObject, IBusquedaVisual)
  public
    function EjecutarBusqueda(AConexion: TUniConnection;
      const ACaption: string; ADataSet: TCustomDADataSet;
      const AName: string; AParentForm: TCustomForm = nil): Boolean;
      overload;
    function EjecutarBusquedaDataSet(const ACaption: string;
      ADataSet: TDataSet; const AName: string;
      AParentForm: TCustomForm = nil): Boolean;
    function EjecutarBusqueda(AConexion: TUniConnection;
      const ACaption, ASql, ACampoResultado: string;
      out AValorDevuelto: string; const AName: string;
      AParentForm: TCustomForm = nil): Boolean; overload;
  end;

constructor TConsultaBusquedaCompraMemoria.Create(
  const ACampo, AValor: string);
begin
  inherited Create;
  FDatos := TClientDataSet.Create(nil);
  FDatos.FieldDefs.Add(ACampo, ftString, 30);
  FDatos.CreateDataSet;
  FDatos.Append;
  FDatos.FieldByName(ACampo).AsString := AValor;
  FDatos.Post;
end;

destructor TConsultaBusquedaCompraMemoria.Destroy;
begin
  FDatos.Free;
  inherited;
end;

function TConsultaBusquedaCompraMemoria.DataSet: TDataSet;
begin
  Result := FDatos;
end;

function TBusquedasCompraPersistenciaMemoria.ConsultarArticulosProveedor(
  const ACodigoProveedor: string): IConsultaBusquedaCompra;
begin
  FArticuloConsultado := ACodigoProveedor;
  Result := TConsultaBusquedaCompraMemoria.Create(
    'CODIGO_ART_ART', 'ART1');
end;

function TBusquedasCompraPersistenciaMemoria.ConsultarSkusArticulo(
  const ACodigoArticulo: string): IConsultaBusquedaCompra;
begin
  FSkuConsultado := ACodigoArticulo;
  Result := TConsultaBusquedaCompraMemoria.Create(
    'CODIGO_UNIDAD_SKU', 'SKU1');
end;

function TBusquedaVisualMemoria.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption: string;
  ADataSet: TCustomDADataSet; const AName: string;
  AParentForm: TCustomForm): Boolean;
begin
  Result := False;
end;

function TBusquedaVisualMemoria.EjecutarBusquedaDataSet(
  const ACaption: string; ADataSet: TDataSet; const AName: string;
  AParentForm: TCustomForm): Boolean;
begin
  Result := Assigned(ADataSet) and ADataSet.Active and
    not ADataSet.IsEmpty;
end;

function TBusquedaVisualMemoria.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption, ASql,
  ACampoResultado: string; out AValorDevuelto: string;
  const AName: string; AParentForm: TCustomForm): Boolean;
begin
  AValorDevuelto := '';
  Result := False;
end;

procedure TPruebasBusquedasCompra.
  Articulo_ConsultaPuertoYDevuelveSeleccion;
var
  oPersistencia: TBusquedasCompraPersistenciaMemoria;
  oPuerto: IBusquedasCompraPersistencia;
begin
  oPersistencia := TBusquedasCompraPersistenciaMemoria.Create;
  oPuerto := oPersistencia;
  Assert.AreEqual('ART1', BuscarArticuloProveedorCompra(
    oPuerto, TBusquedaVisualMemoria.Create, ' PRV1 ',
    '', '', nil));
  Assert.AreEqual('PRV1', oPersistencia.ArticuloConsultado);
end;

procedure TPruebasBusquedasCompra.
  Sku_ConsultaPuertoYDevuelveSeleccion;
var
  oPersistencia: TBusquedasCompraPersistenciaMemoria;
  oPuerto: IBusquedasCompraPersistencia;
begin
  oPersistencia := TBusquedasCompraPersistenciaMemoria.Create;
  oPuerto := oPersistencia;
  Assert.AreEqual('SKU1', BuscarSkuArticuloCompra(
    oPuerto, TBusquedaVisualMemoria.Create, ' ART1 ',
    '', '', nil));
  Assert.AreEqual('ART1', oPersistencia.SkuConsultado);
end;

procedure TPruebasBusquedasCompra.
  ValorTexto_ValidaEstadoYCampo;
var
  oDataSet: TClientDataSet;
begin
  Assert.AreEqual('', ValorTextoDataSetCompra(nil, 'CODIGO'));
  oDataSet := TClientDataSet.Create(nil);
  try
    oDataSet.FieldDefs.Add('CODIGO', ftString, 20);
    oDataSet.CreateDataSet;
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
    oDataSet.Append;
    oDataSet.FieldByName('CODIGO').AsString := ' ART1 ';
    oDataSet.Post;
    Assert.AreEqual('ART1',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'INEXISTENTE'));
    oDataSet.Close;
    Assert.AreEqual('',
      ValorTextoDataSetCompra(oDataSet, 'CODIGO'));
  finally
    oDataSet.Free;
  end;
end;

end.
