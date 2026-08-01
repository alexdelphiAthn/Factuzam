{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAplicacionArticuloCompra                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores UniDAC del caso de uso de artículos en líneas de compra.      }
{******************************************************************************}
unit UniDataAplicacionArticuloCompra;

interface

uses
  Data.DB, Uni, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf, inLibAplicacionArticuloCompraIntf;

function CrearRepositorioLecturasArticuloCompraUniDAC(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver):
  IRepositorioLecturasArticuloCompra;
function CrearPuertoLineaArticuloCompraUniDAC(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet): IPuertoLineaArticuloCompra;
function RecogerEntradaArticuloCompra(
  const ACodigoIntroducido: string;
  ACabecera: TDataSet;
  ATipoDocumento: TTipoDocumentoArticuloCompra;
  APivoteActivo: Boolean): TEntradaAplicacionArticuloCompra;

implementation

uses
  System.SysUtils, inLibComprasImpuestos;

type
  TRepositorioLecturasArticuloCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioLecturasArticuloCompra)
  private
    FConexion: TUniConnection;
    FValidador: IArticulosValidador;
    FResolver: IArticulosResolver;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AValidador: IArticulosValidador;
      const AResolver: IArticulosResolver);
    function ResolverEntrada(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverDatos(
      const ACodigoArticulo, ACodigoSku: string;
      const AFecha: TDateTime;
      const ACodigoAlmacen,
      ACodigoProveedor: string): TArticuloDatos;
    function ResolverUltimoCoste(
      const ACodigoArticulo,
      ACodigoProveedor: string): TArticuloCoste;
    function BuscarConjuntoPivote(
      const ACodigoArticulo: string): Integer;
    function BuscarModeloProveedor(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
  end;

  TPuertoLineaArticuloCompraUniDAC = class(
    TInterfacedObject,
    IPuertoLineaArticuloCompra)
  private
    FConexion: TUniConnection;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    procedure LimpiarCampo(const ACampo: string);
    procedure PonerFloat(const ACampo: string; AValor: Double);
    procedure PonerInteger(const ACampo: string; AValor: Integer);
    procedure PonerString(const ACampo, AValor: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      ACabecera, ALineas: TDataSet);
    function PrepararLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      out ACantidadActual: Double): Boolean;
    procedure AplicarLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      const ALinea: TLineaArticuloCompra);
  end;

function CampoString(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := Trim(oCampo.AsString);
  end;
end;

function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := Date;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.IsNull) then
      Result := oCampo.AsDateTime;
  end;
end;

function CrearRepositorioLecturasArticuloCompraUniDAC(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver):
  IRepositorioLecturasArticuloCompra;
begin
  Result := TRepositorioLecturasArticuloCompraUniDAC.Create(
    AConexion,
    AValidador,
    AResolver);
end;

function CrearPuertoLineaArticuloCompraUniDAC(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet): IPuertoLineaArticuloCompra;
begin
  Result := TPuertoLineaArticuloCompraUniDAC.Create(
    AConexion,
    ACabecera,
    ALineas);
end;

function RecogerEntradaArticuloCompra(
  const ACodigoIntroducido: string;
  ACabecera: TDataSet;
  ATipoDocumento: TTipoDocumentoArticuloCompra;
  APivoteActivo: Boolean): TEntradaAplicacionArticuloCompra;
var
  oConfiguracion: TConfiguracionCamposArticuloCompra;
begin
  oConfiguracion := ConfiguracionCamposArticuloCompra(ATipoDocumento);
  Result := Default(TEntradaAplicacionArticuloCompra);
  Result.CodigoIntroducido := ACodigoIntroducido;
  Result.CodigoProveedor := CampoString(
    ACabecera,
    oConfiguracion.CampoProveedorCabecera);
  Result.CodigoAlmacen := CampoString(
    ACabecera,
    oConfiguracion.CampoAlmacenCabecera);
  Result.PreferenciaPivoteHorizontal := CampoString(
    ACabecera,
    oConfiguracion.CampoPreferenciaPivoteCabecera);
  Result.Fecha := CampoFecha(
    ACabecera,
    oConfiguracion.CampoFechaCabecera);
  Result.PivoteActivo := APivoteActivo;
end;

constructor TRepositorioLecturasArticuloCompraUniDAC.Create(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if AValidador = nil then
    raise EArgumentNilException.Create('AValidador');
  if AResolver = nil then
    raise EArgumentNilException.Create('AResolver');
  inherited Create;
  FConexion := AConexion;
  FValidador := AValidador;
  FResolver := AResolver;
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverEntrada(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := FValidador.Resolver(AEntrada);
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverDatos(
  const ACodigoArticulo, ACodigoSku: string;
  const AFecha: TDateTime;
  const ACodigoAlmacen,
  ACodigoProveedor: string): TArticuloDatos;
begin
  Result := FResolver.ResolverDatos(
    ACodigoArticulo,
    ACodigoSku,
    '',
    AFecha,
    ACodigoAlmacen,
    ACodigoProveedor);
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverUltimoCoste(
  const ACodigoArticulo,
  ACodigoProveedor: string): TArticuloCoste;
begin
  Result := FResolver.ResolverUltimoCoste(
    ACodigoArticulo,
    ACodigoProveedor,
    '');
end;

function TRepositorioLecturasArticuloCompraUniDAC.BuscarConjuntoPivote(
  const ACodigoArticulo: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ACA.ID_AC_ACA ' +
      '  FROM fza_articulos_conjuntos_asign ACA ' +
      ' WHERE ACA.CODIGO_ART_ACA = :art ' +
      '   AND ACA.ID_VA_ACA <> ''CO'' ' +
      ' ORDER BY ACA.ID_VA_ACA ' +
      ' LIMIT 1';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioLecturasArticuloCompraUniDAC.BuscarModeloProveedor(
  const ACodigoArticulo,
  ACodigoProveedor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT AP.REF_PROVEEDOR_AP ' +
      '  FROM fza_articulos_proveedores AP ' +
      ' WHERE AP.CODIGO_ART_AP = :art ' +
      '   AND COALESCE(TRIM(AP.REF_PROVEEDOR_AP), '''') <> '''' ' +
      ' ORDER BY CASE WHEN AP.CODIGO_PRV_AP = :prv THEN 0 ELSE 1 END, ' +
      '          CASE AP.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ' +
      '               ELSE 1 END, ' +
      '          AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP ' +
      ' LIMIT 1';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.ParamByName('prv').AsString := ACodigoProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('REF_PROVEEDOR_AP').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TPuertoLineaArticuloCompraUniDAC.Create(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ACabecera) then
    raise EArgumentNilException.Create('ACabecera');
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  inherited Create;
  FConexion := AConexion;
  FCabecera := ACabecera;
  FLineas := ALineas;
end;

procedure TPuertoLineaArticuloCompraUniDAC.LimpiarCampo(
  const ACampo: string);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.Clear;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerFloat(
  const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsFloat := AValor;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerInteger(
  const ACampo: string;
  AValor: Integer);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsInteger := AValor;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerString(
  const ACampo,
  AValor: string);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsString := AValor;
  end;
end;

function TPuertoLineaArticuloCompraUniDAC.PrepararLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  out ACantidadActual: Double): Boolean;
var
  oCampoCantidad: TField;
begin
  ACantidadActual := 0;
  Result := Assigned(FLineas) and FLineas.Active;
  if Result then
  begin
    if FLineas.IsEmpty then
      FLineas.Append;
    if not (FLineas.State in dsEditModes) then
      FLineas.Edit;
    Result := FLineas.State in dsEditModes;
    if Result then
    begin
      oCampoCantidad := FLineas.FindField(AConfiguracion.CampoCantidad);
      if oCampoCantidad <> nil then
        ACantidadActual := oCampoCantidad.AsFloat;
    end;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.AplicarLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  const ALinea: TLineaArticuloCompra);
begin
  PonerString(AConfiguracion.CampoCodigoArticulo,
              ALinea.CodigoArticulo);
  PonerString(AConfiguracion.CampoCodigoSku, ALinea.CodigoSku);
  PonerString(AConfiguracion.CampoReferenciaProveedor,
              ALinea.ReferenciaProveedor);
  PonerString(AConfiguracion.CampoCodigoFamilia,
              ALinea.CodigoFamilia);
  PonerString(AConfiguracion.CampoNombreFamilia,
              ALinea.NombreFamilia);
  PonerString(AConfiguracion.CampoDescripcionArticulo,
              ALinea.DescripcionArticulo);
  PonerString(AConfiguracion.CampoTipoCantidad, ALinea.TipoCantidad);
  PonerString(AConfiguracion.CampoTipoIva, ALinea.TipoIva);
  if ALinea.AsignarAlmacen then
    PonerString(AConfiguracion.CampoAlmacenLinea,
                ALinea.CodigoAlmacen);
  if ALinea.IdConjuntoPivote > 0 then
    PonerInteger(AConfiguracion.CampoIdConjuntoPivote,
                 ALinea.IdConjuntoPivote)
  else
    LimpiarCampo(AConfiguracion.CampoIdConjuntoPivote);
  if ALinea.AsignarCantidad then
    PonerFloat(AConfiguracion.CampoCantidad, ALinea.Cantidad);
  if ALinea.AsignarTotalUnidades then
    PonerFloat(AConfiguracion.CampoTotalUnidades,
               ALinea.TotalUnidades);
  PonerFloat(AConfiguracion.CampoPrecioCompra, ALinea.PrecioCompra);
  PonerFloat(AConfiguracion.CampoTotal, ALinea.Total);
  PrepararLineaFiscalCompra(
    FConexion,
    FCabecera,
    FLineas,
    AConfiguracion.SufijoCabecera,
    AConfiguracion.SufijoLinea,
    AConfiguracion.CampoTotal);
end;

end.
