{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPropuestasTraspasoConfirmador                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Confirma una propuesta de traspaso sin pasar por la pantalla de caja:     }
{    carga sus líneas en el data module de traspasos y graba el traspaso de    }
{    siempre (operación de caja más par salida-entrada). La propuesta queda    }
{    confirmada en la misma transacción.                                       }
{******************************************************************************}
unit UniDataPropuestasTraspasoConfirmador;

interface

uses
  System.Classes, Uni,
  inLibContextoSesionIntf,
  inLibDistribucionTiendasIntf;

// APropietarioSesion proporciona el contexto de sesión al data module de
// traspasos (cualquier TdmBase o TfrmBase). AUbicacion es la de la sesión:
// si su almacén es el origen de la propuesta, se usa su caja.
function CrearConfirmadorPropuestasTraspasoUniDAC(
  APropietarioSesion: TComponent;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioDistribucionTiendas;
  const AUbicacion: TUbicacionSesion): IConfirmadorPropuestasTraspaso;

implementation

uses
  System.SysUtils, Data.DB,
  inLibMsgDistribucionTiendas,
  UniDataTraspaso;

type
  TConfirmadorPropuestasTraspasoUniDAC = class(
    TInterfacedObject,
    IConfirmadorPropuestasTraspaso)
  private
    FPropietarioSesion: TComponent;
    FConexion: TUniConnection;
    FRepositorio: IRepositorioDistribucionTiendas;
    FUbicacion: TUbicacionSesion;
    function EmpresaDeAlmacen(const AAlmacen: string): string;
    function CajaDeAlmacen(const AAlmacen: string): string;
    function TieneUnidades(const APropuesta: TPropuestaTraspaso): Boolean;
    procedure CargarLineas(
      ADatos: TdmTraspaso;
      const APropuesta: TPropuestaTraspaso);
    function GrabarTraspaso(
      const APropuesta: TPropuestaTraspaso;
      const AEmpresa, ACaja: string;
      AFecha: TDateTime): TResultadoConfirmacionPropuesta;
  public
    constructor Create(
      APropietarioSesion: TComponent;
      AConexion: TUniConnection;
      const ARepositorio: IRepositorioDistribucionTiendas;
      const AUbicacion: TUbicacionSesion);
    function Confirmar(
      AIdPropuesta: Int64;
      AFecha: TDateTime): TResultadoConfirmacionPropuesta;
  end;

function CrearConfirmadorPropuestasTraspasoUniDAC(
  APropietarioSesion: TComponent;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioDistribucionTiendas;
  const AUbicacion: TUbicacionSesion): IConfirmadorPropuestasTraspaso;
begin
  Result := TConfirmadorPropuestasTraspasoUniDAC.Create(
    APropietarioSesion, AConexion, ARepositorio, AUbicacion);
end;

constructor TConfirmadorPropuestasTraspasoUniDAC.Create(
  APropietarioSesion: TComponent;
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioDistribucionTiendas;
  const AUbicacion: TUbicacionSesion);
begin
  if APropietarioSesion = nil then
    raise EArgumentNilException.Create('APropietarioSesion');
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  inherited Create;
  FPropietarioSesion := APropietarioSesion;
  FConexion := AConexion;
  FRepositorio := ARepositorio;
  FUbicacion := AUbicacion;
end;

function TConfirmadorPropuestasTraspasoUniDAC.EmpresaDeAlmacen(
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ALM.CODIGO_EMP_ALM ' +
      '  FROM fza_almacenes ALM ' +
      ' WHERE ALM.CODIGO_ALM_ALM = :ALMACEN';
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CODIGO_EMP_ALM').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// La operación de caja necesita una caja del almacén de origen: la de la
// sesión si está en ese almacén; si no, la primera que tenga asignada.
function TConfirmadorPropuestasTraspasoUniDAC.CajaDeAlmacen(
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if SameText(Trim(FUbicacion.Almacen), Trim(AAlmacen)) then
    Result := Trim(FUbicacion.Caja);
  if Result = '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT ALMCAJ.CODIGO_CAJA_ALMCAJ ' +
        '  FROM fza_almacenes_cajas ALMCAJ ' +
        ' WHERE ALMCAJ.CODIGO_ALM_ALMCAJ = :ALMACEN ' +
        ' ORDER BY ALMCAJ.CODIGO_CAJA_ALMCAJ ' +
        ' LIMIT 1';
      oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('CODIGO_CAJA_ALMCAJ').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TConfirmadorPropuestasTraspasoUniDAC.TieneUnidades(
  const APropuesta: TPropuestaTraspaso): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(APropuesta.Lineas) do
  begin
    if APropuesta.Lineas[i].Cantidad > 0 then
      Result := True;
  end;
end;

procedure TConfirmadorPropuestasTraspasoUniDAC.CargarLineas(
  ADatos: TdmTraspaso;
  const APropuesta: TPropuestaTraspaso);
var
  i: Integer;
  iLinea: Integer;
  oLineas: TDataSet;
begin
  oLineas := ADatos.cdsLineas;
  iLinea := 0;
  for i := 0 to High(APropuesta.Lineas) do
  begin
    if APropuesta.Lineas[i].Cantidad > 0 then
    begin
      Inc(iLinea, 10);
      oLineas.Append;
      oLineas.FieldByName('LINEA').AsString := Format('%.4d', [iLinea]);
      oLineas.FieldByName('CODIGO_ART').AsString :=
        APropuesta.Lineas[i].CodigoArticulo;
      oLineas.FieldByName('CODIGO_UNIDAD').AsString :=
        APropuesta.Lineas[i].CodigoSku;
      oLineas.FieldByName('DESCRIPCION').AsString :=
        Copy(APropuesta.Lineas[i].DescripcionArticulo, 1, 100);
      oLineas.FieldByName('CANTIDAD').AsFloat :=
        APropuesta.Lineas[i].Cantidad;
      oLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
        ADatos.ObtenerCosteMedio(
          APropuesta.Lineas[i].CodigoSku, APropuesta.AlmacenOrigen);
      oLineas.Post;
    end;
  end;
end;

// Un rechazo de negocio (stock insuficiente, SKU inactivo, propuesta ya
// confirmada por otro usuario) no es un fallo: se devuelve su motivo.
function TConfirmadorPropuestasTraspasoUniDAC.GrabarTraspaso(
  const APropuesta: TPropuestaTraspaso;
  const AEmpresa, ACaja: string;
  AFecha: TDateTime): TResultadoConfirmacionPropuesta;
var
  oDatos: TdmTraspaso;
  sNumeroOperacion: string;
begin
  Result := Default(TResultadoConfirmacionPropuesta);
  oDatos := TdmTraspaso.Create(FPropietarioSesion, FConexion);
  try
    oDatos.PrepararNuevo(
      mtTraspaso, AEmpresa, APropuesta.AlmacenOrigen, ACaja, AFecha);
    CargarLineas(oDatos, APropuesta);
    oDatos.VincularPropuesta(APropuesta.IdPropuesta);
    try
      Result.Confirmada := oDatos.GrabarTraspaso(
        APropuesta.AlmacenDestino, sNumeroOperacion);
      Result.NumeroOperacion := sNumeroOperacion;
      Result.TipoDocumento := oDatos.UltimoDocumentoGrabado.TipoDocumento;
      Result.SerieDocumento :=
        oDatos.UltimoDocumentoGrabado.SerieDocumento;
      Result.NumeroDocumento :=
        oDatos.UltimoDocumentoGrabado.NumeroDocumento;
    except
      on E: EValidacionTraspaso do
        Result.Mensaje := E.Message;
    end;
  finally
    FreeAndNil(oDatos);
  end;
end;

function TConfirmadorPropuestasTraspasoUniDAC.Confirmar(
  AIdPropuesta: Int64;
  AFecha: TDateTime): TResultadoConfirmacionPropuesta;
var
  Propuesta: TPropuestaTraspaso;
  sCaja: string;
begin
  Result := Default(TResultadoConfirmacionPropuesta);
  Propuesta := FRepositorio.LeerPropuesta(AIdPropuesta);
  if not Propuesta.EstaPendiente then
    Result.Mensaje := Format(SInfoPropuestaYaNoPendiente, [AIdPropuesta])
  else if not TieneUnidades(Propuesta) then
    Result.Mensaje := Format(
      SErrorPropuestaTraspasoSinLineas, [AIdPropuesta])
  else
  begin
    sCaja := CajaDeAlmacen(Propuesta.AlmacenOrigen);
    if sCaja = '' then
      Result.Mensaje := Format(
        SErrorPropuestaTraspasoSinCaja, [Propuesta.AlmacenOrigen])
    else
      Result := GrabarTraspaso(
        Propuesta,
        EmpresaDeAlmacen(Propuesta.AlmacenOrigen),
        sCaja,
        AFecha);
  end;
end;

end.
