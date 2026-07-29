{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasReapertura                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reabre un borrador fiscal pendiente y aparca su alta en la cola.          }
{******************************************************************************}
unit inLibFacturasReapertura;

interface

uses
  Uni, inLibParametrosIntf, inLibFacturasServiciosIntf;

function CrearServicioReaperturaBorrador(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioReaperturaBorrador;

implementation

uses
  System.SysUtils, Data.DB, inLibMsg, inLibVerifactu,
  inLibVentasWsCola;

type
  TDatosReaperturaBorrador = record
    Encontrada: Boolean;
    Consolidada: Boolean;
    Fase: string;
    EstadoCola: string;
  end;
  TServicioReaperturaBorrador = class(
    TInterfacedObject,
    IServicioReaperturaBorrador)
  private
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FConexion: TUniConnection;
    function CargarDatos(
      const ASerie, ANumero: string;
      ABloquear: Boolean): TDatosReaperturaBorrador;
    function Evaluar(
      const ASerie, ANumero: string;
      const ADatos: TDatosReaperturaBorrador
    ): TResultadoOperacionFactura;
    procedure AparcarAlta(
      const ASerie, ANumero, AUsuario: string);
    procedure ActualizarFactura(
      const ASerie, ANumero, AUsuario: string);
    procedure RegistrarEventos(
      const ASerie, ANumero, AUsuario: string);
  public
    constructor Create(
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      AConexion: TUniConnection);
    function Validar(
      const ASerie, ANumero: string
    ): TResultadoOperacionFactura;
    procedure Reabrir(
      const ASerie, ANumero, AUsuario: string);
  end;

constructor TServicioReaperturaBorrador.Create(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FConexion := AConexion;
end;

function TServicioReaperturaBorrador.CargarDatos(
  const ASerie, ANumero: string;
  ABloquear: Boolean): TDatosReaperturaBorrador;
var
  Qry: TUniQuery;
begin
  Result := Default(TDatosReaperturaBorrador);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'SELECT FASE_FAC, ESCONSOLIDADA_FAC ' +
      '  FROM fza_facturas ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero';
    if ABloquear then
      Qry.SQL.Add(' FOR UPDATE');
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.Open;
    Result.Encontrada := not Qry.IsEmpty;
    if Result.Encontrada then
    begin
      Result.Fase := Qry.FieldByName('FASE_FAC').AsString;
      Result.Consolidada := SameText(
        Qry.FieldByName('ESCONSOLIDADA_FAC').AsString,
        'S');
    end;
    Qry.Close;
    if Result.Encontrada and
       (not Result.Consolidada) and
       (Trim(Result.Fase) <> '') and
       (not SameText(Result.Fase, 'BORRADOR')) then
    begin
      Qry.SQL.Text :=
        'SELECT ESTADO_VFCOLA ' +
        '  FROM fza_verifactu_cola ' +
        ' WHERE SERIE_FAC_VFCOLA = :serie ' +
        '   AND NUMERO_FAC_VFCOLA = :numero ' +
        '   AND TIPO_OPERACION_VFCOLA = ''ALTA''';
      if ABloquear then
        Qry.SQL.Add(' FOR UPDATE');
      Qry.ParamByName('serie').AsString := ASerie;
      Qry.ParamByName('numero').AsString := ANumero;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        Result.EstadoCola :=
          Qry.FieldByName('ESTADO_VFCOLA').AsString;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function TServicioReaperturaBorrador.Evaluar(
  const ASerie, ANumero: string;
  const ADatos: TDatosReaperturaBorrador
): TResultadoOperacionFactura;
begin
  if not ADatos.Encontrada then
  begin
    Result := TResultadoOperacionFactura.Error(
      SErrorBorradorListaNoSeleccionado);
  end
  else
  begin
    Result := EvaluarReaperturaBorrador(
      ASerie,
      ANumero,
      ADatos.Fase,
      ADatos.EstadoCola,
      ADatos.Consolidada);
  end;
end;

procedure TServicioReaperturaBorrador.AparcarAlta(
  const ASerie, ANumero, AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'UPDATE fza_verifactu_cola ' +
      '   SET ESTADO_VFCOLA = ''ERROR'', ' +
      '       CONTADOR_INTENTOS_VFCOLA = 999999, ' +
      '       MENSAJE_ERROR_VFCOLA = ''Lanzamiento anulado ' +
      'por el usuario: borrador devuelto a BORRADOR'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC_VFCOLA = :serie ' +
      '   AND NUMERO_FAC_VFCOLA = :numero ' +
      '   AND TIPO_OPERACION_VFCOLA = ''ALTA''';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TServicioReaperturaBorrador.ActualizarFactura(
  const ASerie, ANumero, AUsuario: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FConexion;
    Qry.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET FASE_FAC = ''BORRADOR'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE SERIE_FAC = :serie ' +
      '   AND NUMERO_FAC = :numero ' +
      '   AND ESCONSOLIDADA_FAC <> ''S''';
    Qry.ParamByName('serie').AsString := ASerie;
    Qry.ParamByName('numero').AsString := ANumero;
    Qry.ParamByName('usuario').AsString := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TServicioReaperturaBorrador.RegistrarEventos(
  const ASerie, ANumero, AUsuario: string);
begin
  RegistrarEventoVerifactu(
    FParametrosApp,
    FConexion,
    AUsuario,
    cEventoVerifactuInfo,
    'Lanzamiento anulado: borrador devuelto a BORRADOR',
    '',
    ASerie,
    ANumero);
  TVentasWsCola.RegistrarEventoSeguro(
    FParametrosCaja,
    FConexion,
    AUsuario,
    'VENTA_REABIERTA',
    ASerie,
    ANumero);
end;

function TServicioReaperturaBorrador.Validar(
  const ASerie, ANumero: string
): TResultadoOperacionFactura;
var
  Datos: TDatosReaperturaBorrador;
begin
  Datos := CargarDatos(ASerie, ANumero, False);
  Result := Evaluar(ASerie, ANumero, Datos);
end;

procedure TServicioReaperturaBorrador.Reabrir(
  const ASerie, ANumero, AUsuario: string);
var
  Datos: TDatosReaperturaBorrador;
  ResultadoValidacion: TResultadoOperacionFactura;
  TransaccionPropia: Boolean;
begin
  TransaccionPropia := not FConexion.InTransaction;
  if TransaccionPropia then
    FConexion.StartTransaction;
  try
    Datos := CargarDatos(ASerie, ANumero, True);
    ResultadoValidacion := Evaluar(ASerie, ANumero, Datos);
    if not ResultadoValidacion.Exito then
    begin
      raise EReaperturaBorrador.Create(
        ResultadoValidacion.Mensaje);
    end;
    if Datos.EstadoCola <> '' then
      AparcarAlta(ASerie, ANumero, AUsuario);
    ActualizarFactura(ASerie, ANumero, AUsuario);
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Commit;
  except
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
  RegistrarEventos(ASerie, ANumero, AUsuario);
end;

function CrearServicioReaperturaBorrador(
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  AConexion: TUniConnection
): IServicioReaperturaBorrador;
begin
  Result := TServicioReaperturaBorrador.Create(
    AParametrosApp,
    AParametrosCaja,
    AConexion);
end;

end.
