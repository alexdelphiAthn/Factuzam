{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasEfectos                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona la persistencia de efectos y recibos de facturas de venta.       }
{******************************************************************************}
unit inLibFacturasEfectos;

interface

uses
  Uni, inLibFacturasServiciosIntf;

type
  TServicioEfectosFactura = class(
    TInterfacedObject,
    IServicioEfectosFactura)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
  end;

implementation

uses
  System.SysUtils, Data.DB;

constructor TServicioEfectosFactura.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TServicioEfectosFactura.EstamparBancoRecibos(
  const ASerie, ANumero, ACodigoBanco, AIban: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'UPDATE fza_recibos ' +
      '   SET CODIGO_EMPBAN_REC = :banco, ' +
      '       IBAN_EMP_REC = :iban ' +
      ' WHERE SERIE_FAC_REC = :serie ' +
      '   AND NUMERO_FAC_REC = :numero';
    Qry.ParamByName('banco').AsString := ACodigoBanco;
    Qry.ParamByName('iban').AsString := AIban;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ExecSQL;
  finally
    FreeAndNil(Qry);
  end;
end;

function TServicioEfectosFactura.BancoDefectoCliente(
  const ACodigoCliente: string): string;
var
  Qry: TUniQuery;
begin
  Result := '';
  if (ACodigoCliente <> '') and
     (ACodigoCliente <> '0') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := FConexion;
      Qry.SQL.Text :=
        'SELECT CODIGO_EMPBAN_CLI ' +
        '  FROM fza_clientes ' +
        ' WHERE CODIGO_CLI_CLI = :cliente';
      Qry.ParamByName('cliente').AsString := ACodigoCliente;
      Qry.Open;
      if not Qry.IsEmpty then
        Result := Qry.FieldByName('CODIGO_EMPBAN_CLI').AsString;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

function TServicioEfectosFactura.Generar(
  const ASerie, ANumero, AUsuario,
  ACodigoBanco, AIban: string): Integer;
var
  Procedimiento: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_EFV_GENERAR_DESDE_FACTURA';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'p_CODIGO_EMPBAN',
      ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_IBAN_EMP', ptInput);
    Procedimiento.Params.CreateParam(
      ftInteger,
      'p_RESULTADO',
      ptOutput);
    Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
    Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
    Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    Procedimiento.ParamByName('p_CODIGO_EMPBAN').AsString :=
      ACodigoBanco;
    Procedimiento.ParamByName('p_IBAN_EMP').AsString := AIban;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TServicioEfectosFactura.RegistrarCobro(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  AFecha: TDateTime;
  AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  Procedimiento: TUniStoredProc;
begin
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_EFV_CONCILIAR_COBRO';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    Procedimiento.Params.CreateParam(ftInteger, 'p_NUM_EFV', ptInput);
    Procedimiento.Params.CreateParam(ftDate, 'p_FECHA', ptInput);
    Procedimiento.Params.CreateParam(ftFloat, 'p_IMPORTE', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_TIPO', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_REFERENCIA', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_ENTIDAD', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(
      ftInteger,
      'p_RESULTADO',
      ptOutput);
    Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
    Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
    Procedimiento.ParamByName('p_NUM_EFV').AsInteger := ANumeroEfecto;
    Procedimiento.ParamByName('p_FECHA').AsDateTime := AFecha;
    Procedimiento.ParamByName('p_IMPORTE').AsFloat := AImporte;
    Procedimiento.ParamByName('p_TIPO').AsString := ATipo;
    Procedimiento.ParamByName('p_REFERENCIA').AsString := AReferencia;
    Procedimiento.ParamByName('p_ENTIDAD').AsString := '';
    Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TServicioEfectosFactura.CambiarEstado(
  const ASerie, ANumero, AUsuario: string;
  ANumeroEfecto: Integer;
  const AEstado: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'UPDATE fza_efectos_venta ' +
      '   SET ESTADO_EFV = :estado, ' +
      '       FECHA_COBRO_EFV = CASE ' +
      '         WHEN :estado = ''PENDIENTE'' THEN NULL ' +
      '         WHEN :estado = ''DEVUELTO'' THEN NULL ' +
      '         ELSE FECHA_COBRO_EFV END, ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC_EFV = :serie ' +
      '   AND NUMERO_FAC_EFV = :numero ' +
      '   AND NUMERO_EFV = :efecto ' +
      '   AND COALESCE(IMPORTE_COBRADO_EFV, 0) <= 0.0001 ' +
      '   AND COALESCE(ESCONCILIADO_EFV, ''N'') <> ''S''';
    Qry.ParamByName('estado').AsString := UpperCase(Trim(AEstado));
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('efecto').AsInteger := ANumeroEfecto;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    FreeAndNil(Qry);
  end;
end;

end.
