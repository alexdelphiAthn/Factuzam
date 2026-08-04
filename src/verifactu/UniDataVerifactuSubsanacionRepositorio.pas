{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVerifactuSubsanacionRepositorio                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Encola subsanaciones limitadas a registros aceptados con errores.         }
{******************************************************************************}
unit UniDataVerifactuSubsanacionRepositorio;
interface
uses
  Uni,
  inLibVerifactuSubsanacionIntf;
function CrearServicioVerifactuSubsanacionUniDAC(
  AConexion: TUniConnection): IServicioVerifactuSubsanacion;
implementation
uses
  System.SysUtils,
  inLibMsgVerifactu,
  inLibParametrosIntf,
  inLibVentasWsCola,
  inLibVerifactu,
  UniDataVentasWsCola;
type
  TServicioVerifactuSubsanacionUniDAC = class(
    TInterfacedObject,
    IServicioVerifactuSubsanacion)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure Encolar(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AUsuario, ASerie, ANumero, AMotivo: string);
  end;
function CrearServicioVerifactuSubsanacionUniDAC(
  AConexion: TUniConnection): IServicioVerifactuSubsanacion;
begin
  Result := TServicioVerifactuSubsanacionUniDAC.Create(AConexion);
end;
constructor TServicioVerifactuSubsanacionUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;
procedure TServicioVerifactuSubsanacionUniDAC.Encolar(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AUsuario, ASerie, ANumero, AMotivo: string);
var
  Qry: TUniQuery;
begin
  if Trim(AMotivo) = '' then
    raise Exception.Create(SErrorIncidenciaMotivoObligatorio);
  ValidarRequisitosFiscalesEmision(
    AParametrosApp,
    FConexion,
    ASerie,
    ANumero);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      ' INSERT INTO fza_verifactu_cola ' +
      ' (SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, ' +
      '  TIPO_OPERACION_VFCOLA, ESTADO_VFCOLA, ' +
      '  CONTADOR_INTENTOS_VFCOLA, MOTIVO_VFCOLA, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA) ' +
      ' SELECT c.SERIE_FAC_FACCON, c.NUMERO_FAC_FACCON, ' +
      '        ''SUBSANACION'', ''PENDIENTE'', 0, :MOTIVO, ' +
      '        NOW(), :USUARIO ' +
      ' FROM fza_facturas_consolidaciones c ' +
      ' WHERE c.SERIE_FAC_FACCON = :SERIE ' +
      '   AND c.NUMERO_FAC_FACCON = :NUMERO ' +
      '   AND c.ESTADO_FACCON = ''VERIFACTU_ACEPT_ERR'' ' +
      ' ORDER BY c.ID_FACCON DESC LIMIT 1 ' +
      ' ON DUPLICATE KEY UPDATE ' +
      '  CONTADOR_INTENTOS_VFCOLA = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    0, CONTADOR_INTENTOS_VFCOLA), ' +
      '  INSTANTE_PROXIMO_INTENTO_VFCOLA = ' +
      '    IF(ESTADO_VFCOLA = ''ERROR'', NULL, ' +
      '       INSTANTE_PROXIMO_INTENTO_VFCOLA), ' +
      '  MENSAJE_ERROR_VFCOLA = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    NULL, MENSAJE_ERROR_VFCOLA), ' +
      '  MOTIVO_VFCOLA = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    :MOTIVO, MOTIVO_VFCOLA), ' +
      '  INSTANTE_MODIF = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    NOW(), INSTANTE_MODIF), ' +
      '  USUARIO_MODIF = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    :USUARIO, USUARIO_MODIF), ' +
      '  ESTADO_VFCOLA = IF(ESTADO_VFCOLA = ''ERROR'', ' +
      '    ''PENDIENTE'', ESTADO_VFCOLA)';
    Qry.ParamByName('SERIE').AsString := ASerie;
    Qry.ParamByName('NUMERO').AsString := ANumero;
    Qry.ParamByName('MOTIVO').AsString := Trim(AMotivo);
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.Execute;
    if Qry.RowsAffected = 0 then
      raise Exception.Create(SErrorIncidenciaEncolarSubsanacion);
  finally
    FreeAndNil(Qry);
  end;
  TVentasWsCola.RegistrarFactura(
    AParametrosCaja,
    CrearRepositorioVentasWsColaUniDAC(FConexion),
    AUsuario,
    ASerie,
    ANumero,
    'SUBSANACION');
end;
end.
