{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaStock                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y aplica la política de disponibilidad para ventas de caja.      }
{******************************************************************************}
unit inLibCajaStock;

interface

uses
  Data.DB, Uni, inLibParametrosIntf, inLibCajaVentaIntf;

type
  TPoliticaStockVenta = class(TInterfacedObject, IPoliticaStockVenta)
  private
    FConexion: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    procedure ConsultarExistencia(
      const ACodigoSku: string;
      out AExiste, AActivo: Boolean);
    function ConsultarCantidad(
      const ACodigoSku, ACodigoAlmacen: string): Double;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AParametrosCaja: IParametrosCaja);
    function Validar(
      const ACodigoSku, ACodigoAlmacen: string
    ): TResultadoPoliticaStockVenta;
  end;

implementation

uses
  System.SysUtils, inLibMsg;

constructor TPoliticaStockVenta.Create(
  AConexion: TUniConnection;
  const AParametrosCaja: IParametrosCaja);
begin
  inherited Create;
  FConexion := AConexion;
  FParametrosCaja := AParametrosCaja;
end;

procedure TPoliticaStockVenta.ConsultarExistencia(
  const ACodigoSku: string;
  out AExiste, AActivo: Boolean);
var
  Qry: TUniQuery;
begin
  AExiste := False;
  AActivo := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT ESACTIVO_SKU FROM fza_articulos_skus ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    Qry.ParamByName('SKU').AsString := ACodigoSku;
    Qry.Open;
    AExiste := not Qry.IsEmpty;
    if AExiste then
      AActivo := Qry.FieldByName('ESACTIVO_SKU').AsString = 'S';
  finally
    FreeAndNil(Qry);
  end;
end;

function TPoliticaStockVenta.ConsultarCantidad(
  const ACodigoSku, ACodigoAlmacen: string): Double;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    if Trim(ACodigoAlmacen) <> '' then
    begin
      Qry.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU ' +
        '   AND CODIGO_ALM_STK = :ALM';
      Qry.ParamByName('ALM').AsString := ACodigoAlmacen;
    end
    else
    begin
      Qry.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS QTY ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU';
    end;
    Qry.ParamByName('SKU').AsString := ACodigoSku;
    Qry.Open;
    Result := Qry.FieldByName('QTY').AsFloat;
  finally
    FreeAndNil(Qry);
  end;
end;

function TPoliticaStockVenta.Validar(
  const ACodigoSku, ACodigoAlmacen: string
): TResultadoPoliticaStockVenta;
var
  Entrada: TEntradaPoliticaStockVenta;
  sCodigoSku: string;
  sMensajeStock: string;
begin
  Entrada := Default(TEntradaPoliticaStockVenta);
  Entrada.Existe := True;
  Entrada.Activo := True;
  sCodigoSku := Trim(ACodigoSku);
  if sCodigoSku <> '' then
  begin
    Entrada.VerificarExistencia :=
      FParametrosCaja.GetBool('vgerChkExistOnly', True);
    if Entrada.VerificarExistencia then
    begin
      ConsultarExistencia(
        sCodigoSku,
        Entrada.Existe,
        Entrada.Activo);
    end;
    Entrada.BloquearSinStock :=
      FParametrosCaja.GetBool('vgerChkStockOnly', False);
    sMensajeStock := Trim(
      FParametrosCaja.GetString('vgerAvisoStockWarning', ''));
    Entrada.VerificarStock :=
      Entrada.BloquearSinStock or (sMensajeStock <> '');
    if Entrada.VerificarStock and
       ((not Entrada.VerificarExistencia) or
        (Entrada.Existe and Entrada.Activo)) then
    begin
      Entrada.CantidadDisponible :=
        ConsultarCantidad(sCodigoSku, ACodigoAlmacen);
    end;
    Result := EvaluarPoliticaStockVenta(Entrada);
    case Result.Motivo of
      msvSkuNoExiste:
        Result.Mensaje := Format(
          SErrorSkuVentaCajaNoExiste,
          [sCodigoSku]);
      msvSkuInactivo:
        Result.Mensaje := Format(
          SErrorSkuVentaCajaNoActivo,
          [sCodigoSku]);
      msvSinStock:
        begin
          Result.Mensaje := sMensajeStock;
          if Result.Mensaje = '' then
            Result.Mensaje := SErrorArticuloVentaCajaSinStock;
        end;
    end;
  end
  else
  begin
    Result.Permitida := True;
    Result.Motivo := msvNinguno;
    Result.Mensaje := '';
  end;
end;

end.
