{******************************************************************************}
{                                                                              }
{  Módulo:       RendimientoMotorFiscalVenta                                   }
{    Tipo:       Prueba de rendimiento                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mide el recálculo completo de facturas con distintos tamaños.             }
{******************************************************************************}
program RendimientoMotorFiscalVenta;

{$APPTYPE CONSOLE}

uses
  MidasLib,
  System.SysUtils, System.Diagnostics, Data.DB, Datasnap.DBClient,
  inLibFacturas in '..\src\Lib\inLibFacturas.pas',
  inLibMotorFiscalVenta in
    '..\src\Lib\inLibMotorFiscalVenta.pas';

const
  NUM_TAMANOS = 3;
  TAMANOS: array[0..NUM_TAMANOS - 1] of Integer =
    (20, 200, 2000);
  ITERACIONES: array[0..NUM_TAMANOS - 1] of Integer =
    (5000, 500, 50);
  ITERACIONES_LINEA = 100000;

type
  TMedicionRendimiento = record
    Milisegundos: Double;
    MicrosegundosPorLinea: Double;
    PostsPorRecalculo: Double;
  end;

  TContadorPosts = class
  private
    FNumeroPosts: Int64;
  public
    procedure ContarPost(DataSet: TDataSet);
    procedure Reiniciar;
    property NumeroPosts: Int64 read FNumeroPosts;
  end;

procedure TContadorPosts.ContarPost(DataSet: TDataSet);
begin
  Inc(FNumeroPosts);
end;

procedure TContadorPosts.Reiniciar;
begin
  FNumeroPosts := 0;
end;

procedure AgregarCampoTexto(ADataSet: TClientDataSet;
  const ANombre: string; ATamano: Integer = 100);
begin
  ADataSet.FieldDefs.Add(ANombre, ftString, ATamano);
end;

procedure AgregarCampoFloat(ADataSet: TClientDataSet;
  const ANombre: string);
begin
  ADataSet.FieldDefs.Add(ANombre, ftFloat);
end;

procedure DefinirCabecera(ACabecera: TClientDataSet);
const
  CAMPOS_TEXTO: array[0..18] of string = (
    'CODIGO_EMP_FAC',
    'TIPO_FAC',
    'RAZON_SOCIAL_EMPRESA_FAC',
    'CODIGO_CLI_FAC',
    'RAZON_SOCIAL_CLIENTE_FAC',
    'NIF_CLIENTE_FAC',
    'DIRECCION1_CLIENTE_FAC',
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC',
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC',
    'ESINTRACOMUNITARIO_CLIENTE_FAC',
    'ESVENTA_ACTIVO_FIJO_FAC',
    'ESRETENCIONES_CLIENTE_FAC',
    'ESRETENCIONES_EMPRESA_FAC',
    'ESIVA_EXENTO_CLIENTE_FAC',
    'ESIVA_RECARGO_CLIENTE_FAC',
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC',
    'ESAPLICA_RE_ZONA_IVA_FAC',
    'GRUPO_ZONA_IVA_EMPRESA_FAC',
    'CODIGO_IVA_FAC');
  CAMPOS_FLOAT: array[0..29] of string = (
    'PORCENTAJE_IVAN_FAC',
    'PORCENTAJE_IVAR_FAC',
    'PORCENTAJE_IVAS_FAC',
    'PORCENTAJE_IVAE_FAC',
    'PORCENTAJE_REN_FAC',
    'PORCENTAJE_RER_FAC',
    'PORCENTAJE_RES_FAC',
    'PORCENTAJE_REE_FAC',
    'PORCENTAJE_RETENCION_FAC',
    'TOTAL_BASEI_IVAN_FAC',
    'TOTAL_BASEI_IVAR_FAC',
    'TOTAL_BASEI_IVAS_FAC',
    'TOTAL_BASEI_IVAE_FAC',
    'TOTAL_BASES_FAC',
    'TOTAL_IMPUESTOS_FAC',
    'TOTAL_RETENCION_FAC',
    'TOTAL_LIQUIDO_FAC',
    'TOTAL_IVAN_FAC',
    'TOTAL_IVAR_FAC',
    'TOTAL_IVAS_FAC',
    'TOTAL_IVAE_FAC',
    'TOTAL_REN_FAC',
    'TOTAL_RER_FAC',
    'TOTAL_RES_FAC',
    'TOTAL_REE_FAC',
    'TOTAL_BRUTO_FAC',
    'TOTAL_DESCUENTOS_FAC',
    'TOTAL_FAC',
    'TOTAL_FAC_SIVA',
    'TOTAL_PRENDAS_FAC');
var
  iIndice: Integer;
begin
  for iIndice := Low(CAMPOS_TEXTO) to High(CAMPOS_TEXTO) do
    AgregarCampoTexto(ACabecera, CAMPOS_TEXTO[iIndice]);
  ACabecera.FieldDefs.Add('FECHA_FAC', ftDate);
  for iIndice := Low(CAMPOS_FLOAT) to High(CAMPOS_FLOAT) do
    AgregarCampoFloat(ACabecera, CAMPOS_FLOAT[iIndice]);
end;

procedure InicializarCabecera(ACabecera: TClientDataSet);
begin
  ACabecera.Append;
  ACabecera.FieldByName('FECHA_FAC').AsDateTime := Date;
  ACabecera.FieldByName('CODIGO_EMP_FAC').AsString := 'EMP';
  ACabecera.FieldByName('TIPO_FAC').AsString := 'NORMAL';
  ACabecera.FieldByName(
    'RAZON_SOCIAL_EMPRESA_FAC').AsString := 'Empresa';
  ACabecera.FieldByName('CODIGO_CLI_FAC').AsString := 'CLI';
  ACabecera.FieldByName(
    'RAZON_SOCIAL_CLIENTE_FAC').AsString := 'Cliente';
  ACabecera.FieldByName('NIF_CLIENTE_FAC').AsString := '12345678Z';
  ACabecera.FieldByName(
    'DIRECCION1_CLIENTE_FAC').AsString := 'Dirección';
  ACabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESINTRACOMUNITARIO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName('ESVENTA_ACTIVO_FIJO_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESRETENCIONES_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESRETENCIONES_EMPRESA_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESIVA_EXENTO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESIVA_RECARGO_CLIENTE_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString := 'N';
  ACabecera.FieldByName(
    'ESAPLICA_RE_ZONA_IVA_FAC').AsString := 'S';
  ACabecera.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat := 21;
  ACabecera.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat := 10;
  ACabecera.FieldByName('PORCENTAJE_IVAS_FAC').AsFloat := 4;
  ACabecera.FieldByName('PORCENTAJE_IVAE_FAC').AsFloat := 0;
  ACabecera.FieldByName('PORCENTAJE_REN_FAC').AsFloat := 5.2;
  ACabecera.FieldByName('PORCENTAJE_RER_FAC').AsFloat := 1.4;
  ACabecera.FieldByName('PORCENTAJE_RES_FAC').AsFloat := 0.5;
  ACabecera.FieldByName('PORCENTAJE_REE_FAC').AsFloat := 0;
  ACabecera.Post;
end;

procedure DefinirLineas(ALineas: TClientDataSet);
begin
  AgregarCampoTexto(ALineas, 'LINEA_FACLIN');
  AgregarCampoTexto(ALineas, 'CODIGO_ART_FACLIN');
  AgregarCampoTexto(ALineas, 'DESCRIPCION_ARTICULO_FACLIN');
  AgregarCampoTexto(ALineas, 'CODIGO_UNIDAD_FACLIN');
  ALineas.FieldDefs.Add(
    'NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger);
  AgregarCampoFloat(ALineas, 'CANTIDAD_FACLIN');
  AgregarCampoTexto(ALineas, 'ESIMP_INCL_TARIFA_FACLIN');
  AgregarCampoTexto(ALineas, 'TIPO_IVA_ARTICULO_FACLIN');
  AgregarCampoFloat(ALineas, 'PORCENTAJE_IVA_FACLIN');
  AgregarCampoFloat(ALineas, 'PRECIO_SALIDA_FACLIN');
  AgregarCampoFloat(ALineas, 'PORCENTAJE_DTO_FACLIN');
  AgregarCampoFloat(ALineas, 'PRECIO_DTO_FACLIN');
  AgregarCampoFloat(
    ALineas, 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN');
  AgregarCampoFloat(
    ALineas, 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN');
  AgregarCampoFloat(ALineas, 'TOTAL_FACLIN');
  AgregarCampoFloat(ALineas, 'TOTAL_FAC_SIVA_FACLIN');
end;

function TipoIvaPorIndice(AIndice: Integer): string;
begin
  case AIndice mod 4 of
    1:
      Result := 'R';
    2:
      Result := 'S';
    3:
      Result := 'E';
  else
    Result := 'N';
  end;
end;

function PorcentajeIvaPorTipo(const ATipoIva: string): Double;
begin
  if ATipoIva = 'R' then
    Result := 10
  else if ATipoIva = 'S' then
    Result := 4
  else if ATipoIva = 'E' then
    Result := 0
  else
    Result := 21;
end;

procedure AgregarLineas(ALineas: TClientDataSet; ACantidad: Integer);
var
  dPorcentaje: Double;
  iIndice: Integer;
  sTipoIva: string;
begin
  for iIndice := 0 to ACantidad - 1 do
  begin
    sTipoIva := TipoIvaPorIndice(iIndice);
    dPorcentaje := PorcentajeIvaPorTipo(sTipoIva);
    ALineas.Append;
    ALineas.FieldByName('LINEA_FACLIN').AsString :=
      Format('%.6d', [iIndice + 1]);
    ALineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
      Format('ART-%.6d', [iIndice + 1]);
    ALineas.FieldByName(
      'DESCRIPCION_ARTICULO_FACLIN').AsString := 'Artículo';
    ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
      Format('SKU-%.6d', [iIndice + 1]);
    ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 1;
    ALineas.FieldByName(
      'ESIMP_INCL_TARIFA_FACLIN').AsString := 'N';
    ALineas.FieldByName(
      'TIPO_IVA_ARTICULO_FACLIN').AsString := sTipoIva;
    ALineas.FieldByName(
      'PORCENTAJE_IVA_FACLIN').AsFloat := dPorcentaje;
    ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat := 10.23;
    ALineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat := 10.23;
    ALineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
      10.23 * (1 + dPorcentaje / 100);
    ALineas.Post;
  end;
end;

procedure ProcesarFactura(ACabecera, ALineas: TClientDataSet);
var
  oTotales: TFacturaTotales;
begin
  oTotales := TFacturaTotales.Create(nil, nil, ACabecera, ALineas);
  try
    if not oTotales.ProcesarFacturaCompleta then
      raise Exception.Create(oTotales.MensajeError);
  finally
    FreeAndNil(oTotales);
  end;
end;

function MedirFacturaCompleta(ACantidadLineas,
  AIteraciones: Integer): TMedicionRendimiento;
var
  Cronometro: TStopwatch;
  iIndice: Integer;
  oCabecera: TClientDataSet;
  oContador: TContadorPosts;
  oLineas: TClientDataSet;
begin
  oCabecera := TClientDataSet.Create(nil);
  oLineas := TClientDataSet.Create(nil);
  oContador := TContadorPosts.Create;
  try
    DefinirCabecera(oCabecera);
    DefinirLineas(oLineas);
    oCabecera.CreateDataSet;
    oLineas.CreateDataSet;
    InicializarCabecera(oCabecera);
    AgregarLineas(oLineas, ACantidadLineas);
    oLineas.AfterPost := oContador.ContarPost;
    ProcesarFactura(oCabecera, oLineas);
    oContador.Reiniciar;
    Cronometro := TStopwatch.StartNew;
    for iIndice := 1 to AIteraciones do
      ProcesarFactura(oCabecera, oLineas);
    Cronometro.Stop;
    Result.Milisegundos :=
      Cronometro.Elapsed.TotalMilliseconds;
    Result.PostsPorRecalculo :=
      oContador.NumeroPosts / AIteraciones;
    Cronometro := TStopwatch.StartNew;
    for iIndice := 1 to ITERACIONES_LINEA do
    begin
      if Odd(iIndice) then
      begin
        if not RecalcularLineaFactura(
          oLineas,
          oCabecera,
          'PRECIO_SALIDA_FACLIN',
          10.24) then
          raise Exception.Create('No se pudo recalcular la línea');
      end
      else
      begin
        if not RecalcularLineaFactura(
          oLineas,
          oCabecera,
          'PRECIO_SALIDA_FACLIN',
          10.23) then
          raise Exception.Create('No se pudo recalcular la línea');
      end;
    end;
    Cronometro.Stop;
    Result.MicrosegundosPorLinea :=
      Cronometro.Elapsed.TotalMilliseconds * 1000 /
      ITERACIONES_LINEA;
  finally
    oLineas.AfterPost := nil;
    FreeAndNil(oContador);
    FreeAndNil(oLineas);
    FreeAndNil(oCabecera);
  end;
end;

procedure Ejecutar;
var
  dMedia: Double;
  iIndice: Integer;
  Medicion: TMedicionRendimiento;
begin
  Writeln(
    'lineas;iteraciones;total_ms;media_ms;' +
    'linea_media_us;posts_por_recalculo');
  for iIndice := 0 to NUM_TAMANOS - 1 do
  begin
    Medicion := MedirFacturaCompleta(
      TAMANOS[iIndice], ITERACIONES[iIndice]);
    dMedia := Medicion.Milisegundos / ITERACIONES[iIndice];
    Writeln(Format('%d;%d;%.3f;%.3f;%.3f;%.3f',
      [TAMANOS[iIndice], ITERACIONES[iIndice],
       Medicion.Milisegundos, dMedia,
       Medicion.MicrosegundosPorLinea,
       Medicion.PostsPorRecalculo]));
  end;
end;

begin
  try
    Ejecutar;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
