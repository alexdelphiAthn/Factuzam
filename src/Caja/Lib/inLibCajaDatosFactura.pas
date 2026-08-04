{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaDatosFactura                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Datos de factura compartidos por caja, impresión y persistencia.          }
{******************************************************************************}
unit inLibCajaDatosFactura;

interface

uses
  Data.DB;

type
  TDatosCabeceraFactura = record
    Fecha: TDateTime;
    CodigoCliente: string;
    RazonSocialEmp: string;
    NifEmp: string;
    MovilEmp: string;
    EmailEmp: string;
    Direccion1Emp: string;
    Direccion2Emp: string;
    PoblacionEmp: string;
    ProvinciaEmp: string;
    CPostalEmp: string;
    CodigoPaisEmp: string;
    NombrePaisEmp: string;
    EsRetencionesEmp: string;
    GrupoZonaIvaEmp: string;
    RazonSocialCli: string;
    NifCli: string;
    MovilCli: string;
    EmailCli: string;
    Direccion1Cli: string;
    Direccion2Cli: string;
    PoblacionCli: string;
    ProvinciaCli: string;
    CPostalCli: string;
    CodigoPaisCli: string;
    NombrePaisCli: string;
    CodigoOficinaContable: string;
    CodigoOrganoGestor: string;
    CodigoUnidadTramitadora: string;
    CodigoIva: string;
    Tarifa: string;
    EsIvaRecargo: string;
    EsIvaExento: string;
    EsImpInclTarifa: string;
    PorcIvaN: Currency;
    TotalIvaN: Currency;
    PorcReN: Currency;
    TotalReN: Currency;
    BaseIN: Currency;
    PorcIvaR: Currency;
    TotalIvaR: Currency;
    PorcReR: Currency;
    TotalReR: Currency;
    BaseIR: Currency;
    PorcIvaS: Currency;
    TotalIvaS: Currency;
    PorcReS: Currency;
    TotalReS: Currency;
    BaseIS: Currency;
    PorcIvaE: Currency;
    TotalIvaE: Currency;
    PorcReE: Currency;
    TotalReE: Currency;
    BaseIE: Currency;
    TotalBases: Currency;
    TotalImpuestos: Currency;
    TotalRetencion: Currency;
    PorcRetencion: Currency;
    TotalLiquido: Currency;
    FormaPago: string;
    Comentarios: string;
  end;

function LeerCabeceraFactura(
  ADataSet: TDataSet): TDatosCabeceraFactura;

implementation

function LeerCabeceraFactura(
  ADataSet: TDataSet): TDatosCabeceraFactura;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := ADataSet.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := ADataSet.FindField(ANombre);
  end;
begin
  Result := Default(TDatosCabeceraFactura);
  Result.Fecha := FieldByName('FECHA_FAC').AsDateTime;
    Result.CodigoCliente := FieldByName('CODIGO_CLI_FAC').AsString;
    Result.RazonSocialEmp :=
      FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString;
    Result.NifEmp := FieldByName('NIF_EMPRESA_FAC').AsString;
    Result.MovilEmp := FieldByName('MOVIL_EMPRESA_FAC').AsString;
    Result.EmailEmp := FieldByName('EMAIL_EMPRESA_FAC').AsString;
    Result.Direccion1Emp :=
      FieldByName('DIRECCION1_EMPRESA_FAC').AsString;
    Result.Direccion2Emp :=
      FieldByName('DIRECCION2_EMPRESA_FAC').AsString;
    Result.PoblacionEmp :=
      FieldByName('POBLACION_EMPRESA_FAC').AsString;
    Result.ProvinciaEmp :=
      FieldByName('PROVINCIA_EMPRESA_FAC').AsString;
    Result.CPostalEmp :=
      FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString;
    Result.CodigoPaisEmp :=
      FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString;
    Result.NombrePaisEmp :=
      FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString;
    Result.EsRetencionesEmp :=
      FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString;
    Result.GrupoZonaIvaEmp :=
      FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
    Result.RazonSocialCli :=
      FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString;
    Result.NifCli := FieldByName('NIF_CLIENTE_FAC').AsString;
    Result.MovilCli := FieldByName('MOVIL_CLIENTE_FAC').AsString;
    Result.EmailCli := FieldByName('EMAIL_CLIENTE_FAC').AsString;
    Result.Direccion1Cli :=
      FieldByName('DIRECCION1_CLIENTE_FAC').AsString;
    Result.Direccion2Cli :=
      FieldByName('DIRECCION2_CLIENTE_FAC').AsString;
    Result.PoblacionCli :=
      FieldByName('POBLACION_CLIENTE_FAC').AsString;
    Result.ProvinciaCli :=
      FieldByName('PROVINCIA_CLIENTE_FAC').AsString;
    Result.CPostalCli :=
      FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString;
    Result.CodigoPaisCli :=
      FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString;
    Result.NombrePaisCli :=
      FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString;
    if FindField('CODIGO_OFICINA_CONTABLE_FAC') <> nil then
      Result.CodigoOficinaContable :=
        FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString;
    if FindField('CODIGO_ORGANO_GESTOR_FAC') <> nil then
      Result.CodigoOrganoGestor :=
        FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString;
    if FindField('CODIGO_UNIDAD_TRAMITADORA_FAC') <> nil then
      Result.CodigoUnidadTramitadora :=
        FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString;
    Result.CodigoIva := FieldByName('CODIGO_IVA_FAC').AsString;
    Result.Tarifa :=
      FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    Result.EsIvaRecargo :=
      FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString;
    Result.EsIvaExento :=
      FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString;
    Result.EsImpInclTarifa :=
      FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
    Result.PorcIvaN :=
      FieldByName('PORCENTAJE_IVAN_FAC').AsCurrency;
    Result.TotalIvaN := FieldByName('TOTAL_IVAN_FAC').AsCurrency;
    Result.PorcReN := FieldByName('PORCENTAJE_REN_FAC').AsCurrency;
    Result.TotalReN := FieldByName('TOTAL_REN_FAC').AsCurrency;
    Result.BaseIN := FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency;
    Result.PorcIvaR :=
      FieldByName('PORCENTAJE_IVAR_FAC').AsCurrency;
    Result.TotalIvaR := FieldByName('TOTAL_IVAR_FAC').AsCurrency;
    Result.PorcReR := FieldByName('PORCENTAJE_RER_FAC').AsCurrency;
    Result.TotalReR := FieldByName('TOTAL_RER_FAC').AsCurrency;
    Result.BaseIR := FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency;
    Result.PorcIvaS :=
      FieldByName('PORCENTAJE_IVAS_FAC').AsCurrency;
    Result.TotalIvaS := FieldByName('TOTAL_IVAS_FAC').AsCurrency;
    Result.PorcReS := FieldByName('PORCENTAJE_RES_FAC').AsCurrency;
    Result.TotalReS := FieldByName('TOTAL_RES_FAC').AsCurrency;
    Result.BaseIS := FieldByName('TOTAL_BASEI_IVAS_FAC').AsCurrency;
    Result.PorcIvaE :=
      FieldByName('PORCENTAJE_IVAE_FAC').AsCurrency;
    Result.TotalIvaE := FieldByName('TOTAL_IVAE_FAC').AsCurrency;
    Result.PorcReE := FieldByName('PORCENTAJE_REE_FAC').AsCurrency;
    Result.TotalReE := FieldByName('TOTAL_REE_FAC').AsCurrency;
    Result.BaseIE := FieldByName('TOTAL_BASEI_IVAE_FAC').AsCurrency;
    Result.TotalBases := FieldByName('TOTAL_BASES_FAC').AsCurrency;
    Result.TotalImpuestos :=
      FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
    Result.TotalRetencion :=
      FieldByName('TOTAL_RETENCION_FAC').AsCurrency;
    Result.PorcRetencion :=
      FieldByName('PORCENTAJE_RETENCION_FAC').AsCurrency;
    Result.TotalLiquido :=
      FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
  Result.FormaPago := FieldByName('FORMA_PAGO_FAC').AsString;
  Result.Comentarios := FieldByName('COMENTARIOS_FAC').AsString;
end;

end.
