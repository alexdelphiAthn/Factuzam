{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaConsultasRepositorio                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas de lectura utilizadas por la operativa de caja.                 }
{******************************************************************************}
unit inLibCajaConsultasRepositorio;

interface

uses
  Data.DB, Uni, inLibCajaVentaIntf;

type
  TConsultaCaja = class(
    TInterfacedObject,
    IResultadoConsultaCaja)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;
  TRepositorioConsultasCaja = class(
    TInterfacedObject,
    IRepositorioConsultasCaja)
  private
    FConexion: TUniConnection;
    function EjecutarConsulta(
      const ASql: string): IResultadoConsultaCaja;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarStock(
      const ACodigoArticulo: string): IResultadoConsultaCaja;
    function ConsultarClientes: IResultadoConsultaCaja;
    function ConsultarEmpleados: IResultadoConsultaCaja;
    function BuscarEmpleado(
      const ATexto: string;
      out AEmpleado: TEmpleadoCaja): Boolean;
    function ObtenerCliente(
      const ACodigo: string;
      out ACliente: TClienteCaja): Boolean;
    function ConsultarCabeceraFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarLineasFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
  end;

implementation

uses
  System.SysUtils;

constructor TConsultaCaja.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TConsultaCaja.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TConsultaCaja.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioConsultasCaja.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioConsultasCaja.EjecutarConsulta(
  const ASql: string): IResultadoConsultaCaja;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := ASql;
    Consulta.Open;
    Result := TConsultaCaja.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioConsultasCaja.ConsultarStock(
  const ACodigoArticulo: string): IResultadoConsultaCaja;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'CALL PRC_GET_CAJA_STOCK_PIVOTADO(:ARTICULO)';
    Consulta.ParamByName('ARTICULO').AsString :=
      ACodigoArticulo;
    Consulta.Open;
    Result := TConsultaCaja.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioConsultasCaja.ConsultarClientes:
  IResultadoConsultaCaja;
begin
  Result := EjecutarConsulta(
    'SELECT CODIGO_CLI_CLI AS `Código`, ' +
    'RAZON_SOCIAL_CLI AS `Razón Social`, ' +
    'NIF_CLI AS `NIF Cliente`, ' +
    'MOVIL_CLI AS `Teléfono Cliente`, ' +
    'ESPERMITE_DEUDA_CLI AS `Cuenta Crédito`, ' +
    'TOTAL_LIMITE_CREDITO_CLI AS `Límite Crédito`, ' +
    'TOTAL_DEUDA_CLI AS `Deuda Usada` ' +
    'FROM fza_clientes ' +
    'WHERE ESACTIVO_CLI = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_CLI');
end;

function TRepositorioConsultasCaja.ConsultarEmpleados:
  IResultadoConsultaCaja;
begin
  Result := EjecutarConsulta(
    'SELECT CODIGO_EMPL AS `Código de Empleado`, ' +
    'DIMINUTIVO_TICKET_EMPL AS `Nombre de Empleado` ' +
    'FROM fza_empleados ' +
    'WHERE ESACTIVO_EMPL = ''S'' ' +
    'AND CODIGO_EMPL IS NOT NULL ' +
    'ORDER BY CODIGO_EMPL');
end;

function TRepositorioConsultasCaja.BuscarEmpleado(
  const ATexto: string;
  out AEmpleado: TEmpleadoCaja): Boolean;
var
  Consulta: TUniQuery;
begin
  AEmpleado := Default(TEmpleadoCaja);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT CODIGO_EMPL, DIMINUTIVO_TICKET_EMPL ' +
      'FROM fza_empleados ' +
      'WHERE ESACTIVO_EMPL = ''S'' ' +
      'AND CODIGO_EMPL IS NOT NULL ';
    if Trim(ATexto) <> '' then
    begin
      Consulta.SQL.Add(
        'AND (CODIGO_EMPL LIKE :TOKEN ' +
        'OR DIMINUTIVO_TICKET_EMPL LIKE :TOKEN)');
      Consulta.ParamByName('TOKEN').AsString :=
        '%' + Trim(ATexto) + '%';
    end;
    Consulta.SQL.Add(
      'ORDER BY CODIGO_EMPL ASC LIMIT 1');
    Consulta.Open;
    Result := not Consulta.IsEmpty;
    if Result then
    begin
      AEmpleado.Codigo :=
        Consulta.FieldByName('CODIGO_EMPL').AsString;
      AEmpleado.Nombre :=
        Consulta.FieldByName(
          'DIMINUTIVO_TICKET_EMPL').AsString;
    end;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioConsultasCaja.ObtenerCliente(
  const ACodigo: string;
  out ACliente: TClienteCaja): Boolean;
var
  Consulta: TUniQuery;
begin
  ACliente := Default(TClienteCaja);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, EMAIL_CLI, ' +
      'DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, ' +
      'PROVINCIA_CLI, CODIGO_POSTAL_CLI, CODIGO_PAI_CLI, ' +
      'NOMBRE_PAI_CLI, ESIVA_RECARGO_CLI, ' +
      'CODIGO_OFICINA_CONTABLE_CLI, CODIGO_ORGANO_GESTOR_CLI, ' +
      'CODIGO_UNIDAD_TRAMITADORA_CLI, ESIVA_EXENTO_CLI, ' +
      'ESREGIMENESPECIALAGRICOLA_CLI, ESRETENCIONES_CLI, ' +
      'ESINTRACOMUNITARIO_CLI, CODIGO_FP_CLI, ' +
      'TARIFA_ARTICULO_CLI, ESPERMITE_DEUDA_CLI ' +
      'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CODIGO';
    Consulta.ParamByName('CODIGO').AsString := ACodigo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
    if Result then
    begin
      ACliente.Codigo := ACodigo;
      ACliente.RazonSocial :=
        Consulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      ACliente.Nif :=
        Consulta.FieldByName('NIF_CLI').AsString;
      ACliente.Movil :=
        Consulta.FieldByName('MOVIL_CLI').AsString;
      ACliente.Email :=
        Consulta.FieldByName('EMAIL_CLI').AsString;
      ACliente.Direccion1 :=
        Consulta.FieldByName('DIRECCION1_CLI').AsString;
      ACliente.Direccion2 :=
        Consulta.FieldByName('DIRECCION2_CLI').AsString;
      ACliente.Poblacion :=
        Consulta.FieldByName('POBLACION_CLI').AsString;
      ACliente.Provincia :=
        Consulta.FieldByName('PROVINCIA_CLI').AsString;
      ACliente.CodigoPostal :=
        Consulta.FieldByName('CODIGO_POSTAL_CLI').AsString;
      ACliente.CodigoPais :=
        Consulta.FieldByName('CODIGO_PAI_CLI').AsString;
      ACliente.NombrePais :=
        Consulta.FieldByName('NOMBRE_PAI_CLI').AsString;
      ACliente.EsIvaRecargo :=
        Consulta.FieldByName('ESIVA_RECARGO_CLI').AsString;
      ACliente.CodigoOficinaContable :=
        Consulta.FieldByName(
          'CODIGO_OFICINA_CONTABLE_CLI').AsString;
      ACliente.CodigoOrganoGestor :=
        Consulta.FieldByName(
          'CODIGO_ORGANO_GESTOR_CLI').AsString;
      ACliente.CodigoUnidadTramitadora :=
        Consulta.FieldByName(
          'CODIGO_UNIDAD_TRAMITADORA_CLI').AsString;
      ACliente.EsIvaExento :=
        Consulta.FieldByName('ESIVA_EXENTO_CLI').AsString;
      ACliente.EsRegimenEspecialAgricola :=
        Consulta.FieldByName(
          'ESREGIMENESPECIALAGRICOLA_CLI').AsString;
      ACliente.EsRetenciones :=
        Consulta.FieldByName('ESRETENCIONES_CLI').AsString;
      ACliente.EsIntracomunitario :=
        Consulta.FieldByName(
          'ESINTRACOMUNITARIO_CLI').AsString;
      ACliente.CodigoFormaPago :=
        Consulta.FieldByName('CODIGO_FP_CLI').AsString;
      ACliente.TarifaArticulo :=
        Consulta.FieldByName('TARIFA_ARTICULO_CLI').AsString;
      ACliente.EsPermiteDeuda :=
        Consulta.FieldByName('ESPERMITE_DEUDA_CLI').AsString;
    end;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioConsultasCaja.ConsultarCabeceraFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT * FROM fza_facturas ' +
      'WHERE SERIE_FAC = :SERIE ' +
      'AND NUMERO_FAC = :NUMERO';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := TConsultaCaja.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioConsultasCaja.ConsultarLineasFactura(
  const ASerie, ANumero: string): IResultadoConsultaCaja;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT * FROM fza_facturas_lineas ' +
      'WHERE SERIE_FAC_FACLIN = :SERIE ' +
      'AND NUMERO_FAC_FACLIN = :NUMERO ' +
      'ORDER BY LINEA_FACLIN';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := TConsultaCaja.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

end.
