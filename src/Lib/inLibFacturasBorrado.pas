{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasBorrado                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y ejecuta el borrado transaccional de una factura de venta.        }
{******************************************************************************}
unit inLibFacturasBorrado;

interface

uses
  Uni, inLibFacturasServiciosIntf;

type
  TServicioBorradoFactura = class(
    TInterfacedObject,
    IServicioBorradoFactura)
  private
    FConexion: TUniConnection;
    FTransaccionPropia: Boolean;
    function TablaEfectosExiste: Boolean;
    function TieneEfectosCobrados(
      const ASerie, ANumero: string): Boolean;
    procedure BorrarEfectos(
      const ASerie, ANumero: string);
    procedure BorrarLineas(
      const ASerie, ANumero: string);
    procedure BorrarRecibos(
      const ASerie, ANumero: string);
    procedure BorrarMovimientos(
      const ASerie, ANumero: string);
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function Validar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    function Preparar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    procedure Confirmar;
    procedure Revertir;
  end;

implementation

uses
  System.SysUtils, inLibVerifactuCola;

constructor TServicioBorradoFactura.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FTransaccionPropia := False;
end;

destructor TServicioBorradoFactura.Destroy;
begin
  Revertir;
  inherited;
end;

function TServicioBorradoFactura.TablaEfectosExiste: Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM INFORMATION_SCHEMA.TABLES ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''fza_efectos_venta''';
    Qry.Open;
    Result := Qry.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

function TServicioBorradoFactura.TieneEfectosCobrados(
  const ASerie, ANumero: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if TablaEfectosExiste then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_efectos_venta ' +
        ' WHERE SERIE_FAC_EFV = :serie ' +
        '   AND NUMERO_FAC_EFV = :numero ' +
        '   AND (COALESCE(IMPORTE_COBRADO_EFV, 0) > 0.0001 ' +
        '    OR COALESCE(ESCONCILIADO_EFV, ''N'') = ''S'' ' +
        '    OR COALESCE(SERIE_REMV_EFV, '''') <> '''' ' +
        '    OR COALESCE(NUMERO_REMV_EFV, '''') <> '''' ' +
        '    OR COALESCE(ESTADO_EFV, '''') IN ' +
        '       (''COBRADO'', ''REMESADO'', ''CONCILIADO''))';
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.Open;
      Result := Qry.FieldByName('N').AsInteger > 0;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TServicioBorradoFactura.Validar(
  const ASerie, ANumero, AFase: string
): TResultadoBorradoFactura;
var
  bTieneEfectosCobrados: Boolean;
begin
  bTieneEfectosCobrados := False;
  if (Trim(AFase) = '') or SameText(AFase, 'BORRADOR') then
  begin
    bTieneEfectosCobrados :=
      TieneEfectosCobrados(ASerie, ANumero);
  end;
  Result := EvaluarBorradoFactura(
    AFase,
    bTieneEfectosCobrados);
end;

procedure TServicioBorradoFactura.BorrarEfectos(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  if TablaEfectosExiste then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'DELETE FROM fza_efectos_venta ' +
        ' WHERE SERIE_FAC_EFV = :serie ' +
        '   AND NUMERO_FAC_EFV = :numero';
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TServicioBorradoFactura.BorrarLineas(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'DELETE FROM fza_facturas_lineas ' +
      ' WHERE SERIE_FAC_FACLIN = :serie ' +
      '   AND NUMERO_FAC_FACLIN = :numero';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TServicioBorradoFactura.BorrarRecibos(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'DELETE FROM fza_recibos ' +
      ' WHERE SERIE_FAC_REC = :serie ' +
      '   AND NUMERO_FAC_REC = :numero';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TServicioBorradoFactura.BorrarMovimientos(
  const ASerie, ANumero: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    TVerifactuCola.BorrarMovimientosFactura(
      Qry,
      ASerie,
      ANumero);
  finally
    FreeAndNil(Qry);
  end;
end;

function TServicioBorradoFactura.Preparar(
  const ASerie, ANumero, AFase: string
): TResultadoBorradoFactura;
begin
  FTransaccionPropia := not FConexion.InTransaction;
  if FTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := Validar(ASerie, ANumero, AFase);
    if Result.Permitido then
    begin
      BorrarEfectos(ASerie, ANumero);
      BorrarLineas(ASerie, ANumero);
      BorrarRecibos(ASerie, ANumero);
      BorrarMovimientos(ASerie, ANumero);
    end
    else
    begin
      Revertir;
    end;
  except
    Revertir;
    raise;
  end;
end;

procedure TServicioBorradoFactura.Confirmar;
begin
  if FTransaccionPropia then
  begin
    FConexion.Commit;
    FTransaccionPropia := False;
  end;
end;

procedure TServicioBorradoFactura.Revertir;
begin
  if FTransaccionPropia then
  begin
    if Assigned(FConexion) and FConexion.InTransaction then
      FConexion.Rollback;
    FTransaccionPropia := False;
  end;
end;

end.
