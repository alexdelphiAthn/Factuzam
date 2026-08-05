{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasValidacionCabecera                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas puras para validar la cabecera de una factura.                     }
{******************************************************************************}
unit inLibFacturasValidacionCabecera;

interface

type
  TDatosValidacionCabeceraFactura = record
    Serie: string;
    Numero: string;
    TipoFactura: string;
    Fase: string;
    RazonSocialCliente: string;
    RazonSocialEmpresa: string;
    CodigoPaisCliente: string;
    NombrePaisCliente: string;
    CodigoPaisEmpresa: string;
    NombrePaisEmpresa: string;
    NifCliente: string;
    NifEmpresa: string;
    TieneFecha: Boolean;
    Fecha: TDateTime;
    UltimaFechaSerie: TDateTime;
    SeriePerteneceOtraEmpresa: Boolean;
    ControlarCronologia: Boolean;
  end;

function EsCabeceraFacturaValidable(
  const ADatos: TDatosValidacionCabeceraFactura): Boolean;
procedure ValidarIdentidadCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
procedure ValidarCoherenciaCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
procedure ValidarNumeroCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
function FechaCabeceraFacturaEsFutura(
  const ADatos: TDatosValidacionCabeceraFactura;
  AFechaActual: TDateTime): Boolean;

implementation

uses
  System.SysUtils,
  inLibDocumentoFiscal,
  inLibFacturasServiciosIntf,
  inLibMsgFacturas,
  inLibMsgVentas;

function EsFacturaSimplificada(
  const ADatos: TDatosValidacionCabeceraFactura): Boolean;
begin
  Result := SameText(ADatos.TipoFactura, 'SIMPLIFICADA');
end;

function EsCabeceraFacturaValidable(
  const ADatos: TDatosValidacionCabeceraFactura): Boolean;
begin
  Result := not EsFacturaSimplificada(ADatos) and
    (SameText(ADatos.Fase, 'BORRADOR') or
     (Trim(ADatos.Fase) = ''));
end;

procedure ValidarIdentidadCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
begin
  if ADatos.SeriePerteneceOtraEmpresa then
  begin
    raise EValidacionFactura.Create(
      SErrorSerieFacturaOtraEmpresa,
      cvfSerie);
  end;
  if (ADatos.RazonSocialCliente = '') and
     not EsFacturaSimplificada(ADatos) then
  begin
    raise EValidacionFactura.Create(
      SErrorRazonSocialClienteBorrador,
      cvfRazonSocialCliente);
  end;
  if ADatos.RazonSocialEmpresa = '' then
  begin
    raise EValidacionFactura.Create(
      SErrorRazonSocialEmpresaBorrador,
      cvfRazonSocialEmpresa);
  end;
  if ADatos.Serie = '' then
  begin
    raise EValidacionFactura.Create(
      SErrorSerieBorradorObligatoria,
      cvfSerie);
  end;
  if ((ADatos.CodigoPaisCliente = '') or
      (ADatos.CodigoPaisEmpresa = '')) and
     not EsFacturaSimplificada(ADatos) then
  begin
    raise EValidacionFactura.Create(
      SErrorPaisClienteEmpresaBorrador,
      cvfPais);
  end;
  if EsCabeceraFacturaValidable(ADatos) and
     not ADatos.TieneFecha then
  begin
    raise EValidacionFactura.Create(
      SErrorFechaBorradorObligatoria,
      cvfFecha);
  end;
end;

procedure ValidarCoherenciaCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
begin
  if EsCabeceraFacturaValidable(ADatos) then
  begin
    if PaisEsEspana(
         ADatos.CodigoPaisCliente,
         ADatos.NombrePaisCliente) and
       not DocumentoFiscalValido(ADatos.NifCliente) then
    begin
      raise EValidacionFactura.Create(
        Format(
          SErrorNifClienteFactura,
          [MensajeDocumentoFiscalInvalido(ADatos.NifCliente)]),
        cvfNifCliente);
    end;
    if PaisEsEspana(
         ADatos.CodigoPaisEmpresa,
         ADatos.NombrePaisEmpresa) and
       not DocumentoFiscalValido(ADatos.NifEmpresa) then
    begin
      raise EValidacionFactura.Create(
        Format(
          SErrorNifEmpresaFactura,
          [MensajeDocumentoFiscalInvalido(ADatos.NifEmpresa)]),
        cvfNifEmpresa);
    end;
    if ADatos.ControlarCronologia and
       (ADatos.UltimaFechaSerie > 0) and
       (ADatos.Fecha < ADatos.UltimaFechaSerie) then
    begin
      raise EValidacionFactura.Create(
        Format(
          SErrorFechaFacturaAnteriorSerie,
          [FormatDateTime('dd/mm/yyyy', ADatos.Fecha),
           FormatDateTime(
             'dd/mm/yyyy', ADatos.UltimaFechaSerie)]),
        cvfFecha);
    end;
  end;
end;

procedure ValidarNumeroCabeceraFactura(
  const ADatos: TDatosValidacionCabeceraFactura);
begin
  if EsCabeceraFacturaValidable(ADatos) and
     ((Trim(ADatos.Numero) = '') or
      (ADatos.Numero = '0')) then
  begin
    raise EValidacionFactura.Create(
      Format(SErrorAsignarNumeroFactura, [ADatos.Serie]),
      cvfSerie);
  end;
end;

function FechaCabeceraFacturaEsFutura(
  const ADatos: TDatosValidacionCabeceraFactura;
  AFechaActual: TDateTime): Boolean;
begin
  Result := EsCabeceraFacturaValidable(ADatos) and
    ADatos.TieneFecha and
    (ADatos.Fecha > AFechaActual);
end;

end.
