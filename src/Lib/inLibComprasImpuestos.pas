{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasImpuestos                                         }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Calculo fiscal comun de documentos de compra. El precio de compra de      }
{    linea se mantiene siempre sin IVA; la marca de recargo de equivalencia    }
{    solo afecta al desglose de impuestos y al coste/PMP de movimientos.       }
{******************************************************************************}
unit inLibComprasImpuestos;

interface

uses
  System.SysUtils, Data.DB, inLibImpuestosLecturasIntf;

function ObtenerRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string): string;

function ObtenerIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  const ACodigoPrv: string): string;

procedure AplicarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);

procedure AplicarIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);

procedure AplicarPorcentajesIvaCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure AplicarPorcentajesRecargoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure PrepararLineaFiscalCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);

procedure CalcularTotalesDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);

// Numero total de prendas del documento: suma CANTIDAD_<sufijo linea> de
// todas las lineas reales (ignora el filtro visual del pivote de tallas).
// Si se indica ACampoTotalUnidades, la linea aporta ese campo cuando no
// es NULL (misma regla COALESCE que las vistas de cabecera: respeta el
// agregado de las lineas consolidadas del pivote antiguo).
// No requiere que exista un campo TOTAL_PRENDAS_xxx en la cabecera; el
// formulario lo muestra directamente en un label de la pestana Totales.
function TotalPrendasLineasCompra(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string;
  const ACampoTotalUnidades: string = ''): Double;

implementation

uses
  inLibImpuestosComun, inLibMotorFiscalVenta;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');



function DocumentoCompraExentoIntracomunitario(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := UpperCase(Trim(CampoString(ACabecera,
    'ESIVA_EXENTO_INTRACOMUNITARIO_' + ASufijoCabecera))) = 'S';
end;












function PorcentajeIvaDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;
var
  bEncontrado: Boolean;
  iIndice: Integer;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if DocumentoCompraExentoIntracomunitario(ACabecera, ASufijoCabecera) then
    Result := 0
  else
  begin
    Result := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera, ATipoIva);
    iIndice := IndiceTipoIva(ATipoIva);
    bEncontrado := False;
    sCodigoIva := Trim(CampoString(ACabecera,
      'CODIGO_IVA_' + ASufijoCabecera));
    if (sCodigoIva <> '') and (sCodigoIva <> '0') then
      bEncontrado := LeerPorcentajesIvaPorCodigo(ALecturas, sCodigoIva,
        rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
    if not bEncontrado then
    begin
      sEmpresa := CampoString(ACabecera,
        'CODIGO_EMP_' + ASufijoCabecera);
      bEncontrado := LeerPorcentajesIvaPorEmpresa(ALecturas, sEmpresa,
        sCodigoIva, rIvaN, rIvaR, rIvaS, rIvaE,
        rRecN, rRecR, rRecS, rRecE);
    end;
    if bEncontrado then
    begin
      if iIndice = 0 then
        Result := rIvaN
      else if iIndice = 1 then
        Result := rIvaR
      else if iIndice = 2 then
        Result := rIvaS
      else
        Result := rIvaE;
    end;
  end;
end;


function ImporteDescuentoGlobalCompra(ACabecera: TDataSet;
  const ASufijoCabecera, AConcepto: string; ABase: Double): Double;
var
  rPorcentaje, rTotal: Double;
begin
  Result := 0;
  if ABase > 0 then
  begin
    rPorcentaje := CampoFloat(ACabecera,
      'PORCENTAJE_DTO_' + AConcepto + '_' + ASufijoCabecera);
    rTotal := CampoFloat(ACabecera,
      'TOTAL_DTO_' + AConcepto + '_' + ASufijoCabecera);
    if Abs(rPorcentaje) > 0.000001 then
      rTotal := ABase * rPorcentaje / 100;
    if rTotal < 0 then
      rTotal := 0;
    if rTotal > ABase then
      rTotal := ABase;
    Result := rTotal;
  end;
end;

function FactorDescuentoComercialCompra(ATotalBruto,
  ADescuentoComercial: Double): Double;
begin
  Result := 1;
  if ATotalBruto > 0 then
  begin
    Result := 1 - ADescuentoComercial / ATotalBruto;
    if Result < 0 then
      Result := 0;
  end;
end;

function ObtenerRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  const ACodigoEmp: string): string;
begin
  Result := 'N';
  if Assigned(ALecturas) and
     ALecturas.LeerRecargoComprasEmpresa(ACodigoEmp) then
    Result := 'S';
end;

function ObtenerIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  const ACodigoPrv: string): string;
begin
  Result := 'N';
  if Assigned(ALecturas) and
     ALecturas.LeerExentoIntracomunitarioProveedor(ACodigoPrv) then
    Result := 'S';
end;

procedure AplicarRecargoComprasEmpresa(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);
var
  sEmpresa: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoRecargo) <> nil) then
  begin
    sEmpresa := CampoString(ACabecera, ACampoEmpresa);
    PonerString(ACabecera, ACampoRecargo,
                ObtenerRecargoComprasEmpresa(ALecturas, sEmpresa));
  end;
end;

procedure AplicarIvaExentoIntracomunitarioProveedor(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);
var
  sProveedor: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoExento) <> nil) then
  begin
    sProveedor := CampoString(ACabecera, ACampoProveedor);
    PonerString(ACabecera, ACampoExento,
      ObtenerIvaExentoIntracomunitarioProveedor(
        ALecturas, sProveedor));
  end;
end;

procedure AplicarPorcentajesIvaCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  bEncontrado: Boolean;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if Assigned(ACabecera) then
  begin
    if DocumentoCompraExentoIntracomunitario(ACabecera, ASufijoCabecera) then
    begin
      PonerFloat(ACabecera, 'PORCENTAJE_IVAN_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAR_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAS_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_IVAE_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera,
                 0);
      PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera,
                 0);
    end
    else
    begin
      sCodigoIva := Trim(CampoString(ACabecera,
        'CODIGO_IVA_' + ASufijoCabecera));
      bEncontrado := False;
      if (sCodigoIva <> '') and (sCodigoIva <> '0') then
        bEncontrado := LeerPorcentajesIvaPorCodigo(
          ALecturas, sCodigoIva,
          rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
      if not bEncontrado then
      begin
        sEmpresa := CampoString(ACabecera,
          'CODIGO_EMP_' + ASufijoCabecera);
        bEncontrado := LeerPorcentajesIvaPorEmpresa(
          ALecturas, sEmpresa,
          sCodigoIva, rIvaN, rIvaR, rIvaS, rIvaE,
          rRecN, rRecR, rRecS, rRecE);
      end;
      if bEncontrado then
      begin
        PonerString(ACabecera, 'CODIGO_IVA_' + ASufijoCabecera,
                    sCodigoIva);
        PonerFloat(ACabecera, 'PORCENTAJE_IVAN_' + ASufijoCabecera,
                   rIvaN);
        PonerFloat(ACabecera, 'PORCENTAJE_IVAR_' + ASufijoCabecera,
                   rIvaR);
        PonerFloat(ACabecera, 'PORCENTAJE_IVAS_' + ASufijoCabecera,
                   rIvaS);
        PonerFloat(ACabecera, 'PORCENTAJE_IVAE_' + ASufijoCabecera,
                   rIvaE);
        PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera,
                   rRecN);
        PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera,
                   rRecR);
        PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera,
                   rRecS);
        PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera,
                   rRecE);
      end
      else
        AplicarPorcentajesRecargoCompra(
          ALecturas, ACabecera, ASufijoCabecera);
    end
  end;
end;

procedure LeerPorcentajesRecargo(
  const ALecturas: ILecturasImpuestos;
  const ACodigoIva: string; out ARecargoNormal, ARecargoReducido,
  ARecargoSuper, ARecargoExento: Double);
var
  rIvaExento: Double;
  rIvaNormal: Double;
  rIvaReducido: Double;
  rIvaSuper: Double;
begin
  ARecargoNormal  := 0;
  ARecargoReducido:= 0;
  ARecargoSuper   := 0;
  ARecargoExento  := 0;
  LeerPorcentajesIvaPorCodigo(ALecturas, ACodigoIva,
    rIvaNormal, rIvaReducido, rIvaSuper, rIvaExento,
    ARecargoNormal, ARecargoReducido, ARecargoSuper,
    ARecargoExento);
end;

procedure AplicarPorcentajesRecargoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva: string;
begin
  if Assigned(ACabecera) then
  begin
    if DocumentoCompraExentoIntracomunitario(ACabecera, ASufijoCabecera) then
    begin
      rRecN := 0;
      rRecR := 0;
      rRecS := 0;
      rRecE := 0;
    end
    else
    begin
      sCodigoIva := CampoString(ACabecera,
        'CODIGO_IVA_' + ASufijoCabecera);
      LeerPorcentajesRecargo(ALecturas, sCodigoIva,
        rRecN, rRecR, rRecS,
        rRecE);
    end;
    PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera, rRecN);
    PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera, rRecR);
    PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera, rRecS);
    PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera, rRecE);
  end;
end;

procedure PrepararLineaFiscalCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);
var
  rCantidad, rPorIva, rPrecioSiva: Double;
  sArticulo, sCampoTipo, sTipoArt, sTipoIva: string;
begin
  if Assigned(ACabecera) and Assigned(ALinea) and ALinea.Active then
  begin
    sCampoTipo := 'TIPO_IVA_ARTICULO_' + ASufijoLinea;
    sArticulo := CampoString(ALinea, 'CODIGO_ART_' + ASufijoLinea);
    sTipoIva := NormalizarTipoIva(CampoString(ALinea, sCampoTipo));
    if DocumentoCompraExentoIntracomunitario(ACabecera, ASufijoCabecera) then
      sTipoIva := 'E'
    else
    begin
      sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
      if sTipoArt <> '' then
        sTipoIva := sTipoArt;
    end;
    // No editar la cabecera desde el BeforePost de la linea: UniDAC
    // fuerza CheckBrowseMode del detalle y reentra en este mismo Post.
    rPorIva := PorcentajeIvaDocumentoCompra(ALecturas, ACabecera,
      ASufijoCabecera, sTipoIva);
    rCantidad := CampoFloat(ALinea, 'CANTIDAD_' + ASufijoLinea);
    rPrecioSiva := CampoFloat(ALinea,
      'PRECIO_COMPRA_SIVA_ARTICULO_' + ASufijoLinea);
    if not (ALinea.State in dsEditModes) then
      ALinea.Edit;
    PonerString(ALinea, sCampoTipo, sTipoIva);
    PonerFloat(ALinea, 'PORCENTAJE_IVA_' + ASufijoLinea, rPorIva);
    PonerFloat(ALinea, 'PRECIO_COMPRA_CIVA_ARTICULO_' + ASufijoLinea,
      rPrecioSiva * (1 + rPorIva / 100));
    PonerFloat(ALinea, ACampoTotalLinea, rCantidad * rPrecioSiva);
  end;
end;

procedure AgregarLineaMotorFiscalCompra(
  var ALineas: TLineasMotorFiscalVenta;
  const ATipoIva: string;
  ABase, ABruto, APorcentajeIva, APorcentajeRecargo: Double);
var
  iIndice: Integer;
begin
  iIndice := Length(ALineas);
  SetLength(ALineas, iIndice + 1);
  ALineas[iIndice] := Default(TLineaMotorFiscalVenta);
  ALineas[iIndice].TipoIva := ATipoIva;
  ALineas[iIndice].Base := ABase;
  ALineas[iIndice].TotalConIva :=
    ABase + (ABase * APorcentajeIva / 100);
  ALineas[iIndice].PorcentajeIva := APorcentajeIva;
  ALineas[iIndice].PorcentajeRecargo := APorcentajeRecargo;
  ALineas[iIndice].Bruto := ABruto;
  ALineas[iIndice].Descuento := ABruto - ABase;
end;

function ResultadoTipoIvaCompra(
  const AResultado: TResultadoMotorFiscalVenta;
  AIndice: Integer): TResultadoTipoIvaVenta;
begin
  Result := AResultado.Normal;
  if AIndice = 1 then
    Result := AResultado.Reducido
  else if AIndice = 2 then
    Result := AResultado.SuperReducido
  else if AIndice = 3 then
    Result := AResultado.Exento;
end;

procedure EscribirResultadoMotorFiscalCompra(
  ACabecera: TDataSet; const ASufijoCabecera: string;
  const AResultado: TResultadoMotorFiscalVenta;
  ADescuentoComercial, ADescuentoFinanciero: Double);
var
  iIndice: Integer;
  oTipo: TResultadoTipoIvaVenta;
begin
  for iIndice := 0 to 3 do
  begin
    oTipo := ResultadoTipoIvaCompra(AResultado, iIndice);
    PonerFloat(ACabecera,
      'TOTAL_BASEI_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
      oTipo.Base);
    PonerFloat(ACabecera,
      'TOTAL_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
      oTipo.ImporteIva);
    PonerFloat(ACabecera,
      'TOTAL_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera,
      oTipo.ImporteRecargo);
  end;
  PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera,
    AResultado.TotalBruto);
  PonerFloat(ACabecera, 'TOTAL_DTO_COMERCIAL_' + ASufijoCabecera,
    ADescuentoComercial);
  PonerFloat(ACabecera, 'TOTAL_DTO_FINANCIERO_' + ASufijoCabecera,
    ADescuentoFinanciero);
  PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera,
    AResultado.TotalBases);
  PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera,
    AResultado.TotalImpuestos);
  PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera,
    AResultado.TotalRetencion);
  PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera,
    AResultado.TotalConImpuestos);
  PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
    AResultado.TotalLiquido - ADescuentoFinanciero);
end;

procedure CalcularTotalesDocumentoCompra(
  const ALecturas: ILecturasImpuestos;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  aLineasMotor: TLineasMotorFiscalVenta;
  oConfiguracion: TConfiguracionMotorFiscalVenta;
  oResultado: TResultadoMotorFiscalVenta;
  oMarcador: TBookmark;
  iIndice: Integer;
  rTotal, rTotalBruto, rPorIva, rPorRe, rPorRet, rBruto,
  rDtoComercial, rDtoFinanciero, rFactorComercial: Double;
  sArticulo, sSufijoLinea, sTipoArt, sTipoIva, sTipoLinea: string;
  bAplicaRe: Boolean;
  bExento: Boolean;
  bFiltroActivo: Boolean;
begin
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    SetLength(aLineasMotor, 0);
    rBruto := 0;
    AplicarPorcentajesIvaCompra(
      ALecturas, ACabecera, ASufijoCabecera);
    sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
    bExento := DocumentoCompraExentoIntracomunitario(ACabecera,
      ASufijoCabecera);
    bAplicaRe :=
      (not bExento) and
      (UpperCase(CampoString(ACabecera,
        'ESIVA_RECARGO_COMPRAS_' + ASufijoCabecera)) = 'S');
    oMarcador := ALineas.GetBookmark;
    bFiltroActivo := ALineas.Filtered;
    try
      ALineas.DisableControls;
      // El pivote de tallas filtra visualmente las lineas representantes.
      // Los totales fiscales deben sumar siempre todas las lineas reales.
      if bFiltroActivo then
        ALineas.Filtered := False;
      ALineas.First;
      while not ALineas.Eof do
      begin
        rBruto := rBruto + CampoFloat(ALineas, ACampoTotalLinea);
        ALineas.Next;
      end;
      rDtoComercial := ImporteDescuentoGlobalCompra(ACabecera,
        ASufijoCabecera, 'COMERCIAL', rBruto);
      rFactorComercial := FactorDescuentoComercialCompra(rBruto,
        rDtoComercial);
      rDtoFinanciero := ImporteDescuentoGlobalCompra(ACabecera,
        ASufijoCabecera, 'FINANCIERO', rBruto - rDtoComercial);
      ALineas.First;
      while not ALineas.Eof do
      begin
        sTipoLinea := CampoString(ALineas, ACampoTipoIvaLinea);
        if Trim(sTipoLinea) = '' then
          sTipoLinea := CampoString(ACabecera,
            'TIPO_IVA_' + ASufijoCabecera);
        sTipoIva := NormalizarTipoIva(sTipoLinea);
        if bExento then
          sTipoIva := 'E'
        else if sSufijoLinea <> '' then
        begin
          sArticulo := CampoString(ALineas, 'CODIGO_ART_' + sSufijoLinea);
          sTipoArt := ObtenerTipoIvaArticulo(ALecturas, sArticulo);
          if sTipoArt <> '' then
            sTipoIva := sTipoArt;
        end;
        rTotalBruto := CampoFloat(ALineas, ACampoTotalLinea);
        rTotal := rTotalBruto * rFactorComercial;
        rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
        if bExento then
          rPorIva := 0
        else if rPorIva = 0 then
          rPorIva := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera,
            sTipoIva);
        iIndice := IndiceTipoIva(sTipoIva);
        rPorRe := CampoFloat(ACabecera,
          'PORCENTAJE_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera);
        AgregarLineaMotorFiscalCompra(aLineasMotor, sTipoIva,
          rTotal, rTotalBruto, rPorIva, rPorRe);
        ALineas.Next;
      end;
    finally
      if bFiltroActivo then
        ALineas.Filtered := True;
      if ALineas.BookmarkValid(oMarcador) then
        ALineas.GotoBookmark(oMarcador);
      ALineas.FreeBookmark(oMarcador);
      ALineas.EnableControls;
    end;
    rPorRet := CampoFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera);
    oConfiguracion := Default(TConfiguracionMotorFiscalVenta);
    oConfiguracion.AplicaRecargo := bAplicaRe;
    oConfiguracion.AplicaRetencion := Abs(rPorRet) > 0.000001;
    oConfiguracion.ClienteConDatosFiscales := True;
    oConfiguracion.PorcentajeRetencion := rPorRet;
    oResultado := CalcularTotalesMotorFiscalVenta(
      aLineasMotor, oConfiguracion);
    EscribirResultadoMotorFiscalCompra(ACabecera, ASufijoCabecera,
      oResultado, rDtoComercial, rDtoFinanciero);
  end;
end;

function TotalPrendasLineasCompra(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string;
  const ACampoTotalUnidades: string): Double;
var
  bk: TBookmark;
  oCampoUds: TField;
  rCantidadLinea: Double;
  sSufijoLinea: string;
  bFiltroActivo: Boolean;
begin
  Result := 0;
  if Assigned(ALineas) and ALineas.Active then
  begin
    sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
    if sSufijoLinea <> '' then
    begin
  bk := ALineas.GetBookmark;
  bFiltroActivo := ALineas.Filtered;
  try
    ALineas.DisableControls;
    // El pivote de tallas filtra visualmente las lineas representantes.
    // El total de prendas debe sumar siempre todas las lineas reales.
    if bFiltroActivo then
      ALineas.Filtered := False;
    ALineas.First;
    while not ALineas.Eof do
    begin
      rCantidadLinea := CampoFloat(ALineas, 'CANTIDAD_' + sSufijoLinea);
      // Regla COALESCE de la vista: TOTAL_UNIDADES manda si no es NULL.
      if ACampoTotalUnidades <> '' then
      begin
        oCampoUds := ALineas.FindField(ACampoTotalUnidades);
        if (oCampoUds <> nil) and (not oCampoUds.IsNull) then
          rCantidadLinea := oCampoUds.AsFloat;
      end;
      Result := Result + rCantidadLinea;
      ALineas.Next;
    end;
  finally
    if bFiltroActivo then
      ALineas.Filtered := True;
    if ALineas.BookmarkValid(bk) then
      ALineas.GotoBookmark(bk);
    ALineas.FreeBookmark(bk);
    ALineas.EnableControls;
  end;
    end;
  end;
end;

end.
