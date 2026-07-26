{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVentasImpuestos                                          }
{    Tipo:       Libreria (sin formulario)                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       26/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Calculo fiscal comun de documentos de venta. Agrupa bases e impuestos     }
{    por tipo de IVA y respeta los campos disponibles en cada documento.       }
{******************************************************************************}
unit inLibVentasImpuestos;

interface

uses
  System.SysUtils, Data.DB, DBAccess, Uni;

procedure AplicarPorcentajesIvaVenta(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera: string);

function PorcentajeIvaDocumentoVenta(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;

procedure PrepararLineaFiscalVenta(AConn: TUniConnection;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);

procedure CalcularTotalesDocumentoVenta(AConn: TUniConnection;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);

// Numero total de prendas del documento: suma CANTIDAD_<sufijo linea> de
// todas las lineas reales (ignora el filtro visual del pivote de tallas).
// No requiere que exista un campo TOTAL_PRENDAS_xxx en la cabecera; el
// formulario lo muestra directamente en un label de la pestana Totales.
function TotalPrendasLineasVenta(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string): Double;

implementation

uses inLibImpuestosComun;

type
  TImportesTipoIvaVenta = record
    Base: Double;
    Iva : Double;
    Re  : Double;
  end;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');



function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := Date;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsDateTime;
  end;
end;





function EsSi(ADataSet: TDataSet; const ACampo: string): Boolean;
begin
  Result := UpperCase(Trim(CampoString(ADataSet, ACampo))) = 'S';
end;






function LeerPorcentajeRetencionEmpresa(AConn: TUniConnection;
  const ACodigoEmp: string; AFecha: TDateTime): Double;
var
  q: TUniQuery;
begin
  Result := 0;
  if (AConn <> nil) and (Trim(ACodigoEmp) <> '') and
     (Trim(ACodigoEmp) <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT IFNULL(PORCENTAJE_EMPRET, 0) AS PORCENTAJE ' +
        '  FROM fza_empresas_retenciones ' +
        ' WHERE CODIGO_EMP_EMPRET = :empresa ' +
        '   AND FECHA_DESDE_EMPRET <= :fecha ' +
        '   AND (FECHA_HASTA_EMPRET >= :fecha ' +
        '        OR FECHA_HASTA_EMPRET IS NULL) ' +
        ' LIMIT 1';
      q.ParamByName('empresa').AsString := ACodigoEmp;
      q.ParamByName('fecha').AsDateTime := AFecha;
      q.Open;
      if not q.Eof then
        Result := q.FieldByName('PORCENTAJE').AsFloat;
    finally
      FreeAndNil(q);
    end;
  end;
end;



function PorcentajeReCabecera(ACabecera: TDataSet;
  const ASufijoCabecera, ATipoIva: string): Double;
var
  iIndice: Integer;
begin
  iIndice := IndiceTipoIva(ATipoIva);
  Result := CampoFloat(ACabecera,
    'PORCENTAJE_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera);
end;

function PorcentajeIvaDocumentoVenta(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera, ATipoIva: string): Double;
var
  bEncontrado: Boolean;
  iIndice: Integer;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  Result := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera, ATipoIva);
  iIndice := IndiceTipoIva(ATipoIva);
  bEncontrado := False;
  sCodigoIva := Trim(CampoString(ACabecera,
    'CODIGO_IVA_' + ASufijoCabecera));
  if (sCodigoIva <> '') and (sCodigoIva <> '0') then
    bEncontrado := LeerPorcentajesIvaPorCodigo(AConn, sCodigoIva,
      rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
  if not bEncontrado then
  begin
    sEmpresa := CampoString(ACabecera,
      'CODIGO_EMP_' + ASufijoCabecera);
    bEncontrado := LeerPorcentajesIvaPorEmpresa(AConn, sEmpresa,
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


function ClienteExento(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := EsSi(ACabecera, 'ESIVA_EXENTO_CLIENTE_' + ASufijoCabecera) or
            EsSi(ACabecera,
                 'ESINTRACOMUNITARIO_CLIENTE_' + ASufijoCabecera);
end;

function AplicaRecargoVenta(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := EsSi(ACabecera, 'ESIVA_RECARGO_CLIENTE_' + ASufijoCabecera);
  if CampoString(ACabecera,
     'ESAPLICA_RE_ZONA_IVA_' + ASufijoCabecera) = 'N' then
    Result := False;
end;

function TieneDatosClienteRetencion(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
var
  sNif, sRazon, sDireccion: string;
begin
  sNif := Trim(CampoString(ACabecera,
    'NIF_CLIENTE_' + ASufijoCabecera));
  sRazon := Trim(CampoString(ACabecera,
    'RAZON_SOCIAL_CLIENTE_' + ASufijoCabecera));
  if sRazon = '' then
    sRazon := Trim(CampoString(ACabecera,
      'RAZON_SOCIAL_CLIENTE_FISCAL_' + ASufijoCabecera));
  sDireccion := Trim(CampoString(ACabecera,
    'DIRECCION1_CLIENTE_' + ASufijoCabecera));
  if sDireccion = '' then
    sDireccion := Trim(CampoString(ACabecera,
      'DIRECCION1_CLIENTE_FISCAL_' + ASufijoCabecera));
  Result := (sNif <> '') and (sRazon <> '') and (sDireccion <> '');
end;

function CalcularRetencionVenta(AConn: TUniConnection; ACabecera: TDataSet;
  const ASufijoCabecera: string; ABase, AImpuestos: Double): Double;
var
  rBaseRetencion, rPorRetencion: Double;
  bAplicaCliente, bAplicaEmpresa, bActivoFijo, bAgricolaEmpresa: Boolean;
  sEmpresa: string;
  dFecha: TDateTime;
begin
  Result := 0;
  bAplicaCliente := EsSi(ACabecera,
    'ESRETENCIONES_CLIENTE_' + ASufijoCabecera);
  bAplicaEmpresa := EsSi(ACabecera,
    'ESRETENCIONES_EMPRESA_' + ASufijoCabecera);
  bActivoFijo := EsSi(ACabecera,
    'ESVENTA_ACTIVO_FIJO_' + ASufijoCabecera);
  bAgricolaEmpresa := EsSi(ACabecera,
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_' + ASufijoCabecera);
  rPorRetencion := CampoFloat(ACabecera,
    'PORCENTAJE_RETENCION_' + ASufijoCabecera);
  if bAplicaCliente and bAplicaEmpresa and
     TieneDatosClienteRetencion(ACabecera, ASufijoCabecera) and
     not (bActivoFijo and bAgricolaEmpresa) then
  begin
    if rPorRetencion = 0 then
    begin
      sEmpresa := CampoString(ACabecera,
        'CODIGO_EMP_' + ASufijoCabecera);
      dFecha := CampoFecha(ACabecera, 'FECHA_' + ASufijoCabecera);
      rPorRetencion := LeerPorcentajeRetencionEmpresa(AConn,
        sEmpresa, dFecha);
      PonerFloat(ACabecera,
        'PORCENTAJE_RETENCION_' + ASufijoCabecera, rPorRetencion);
    end;
    if EsSi(ACabecera, 'ESIRPF_IMP_INCL_ZONA_IVA_' + ASufijoCabecera) then
      rBaseRetencion := ABase + AImpuestos
    else
      rBaseRetencion := ABase;
    Result := rBaseRetencion * rPorRetencion / 100;
  end
  else if bActivoFijo and bAgricolaEmpresa then
    PonerFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera, 0);
end;

procedure AplicarPorcentajesIvaVenta(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera: string);
var
  bEncontrado: Boolean;
  rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE: Double;
  sCodigoIva, sEmpresa: string;
begin
  if Assigned(ACabecera) then
  begin
    sCodigoIva := Trim(CampoString(ACabecera,
      'CODIGO_IVA_' + ASufijoCabecera));
    bEncontrado := False;
    if (sCodigoIva <> '') and (sCodigoIva <> '0') then
      bEncontrado := LeerPorcentajesIvaPorCodigo(AConn, sCodigoIva,
        rIvaN, rIvaR, rIvaS, rIvaE, rRecN, rRecR, rRecS, rRecE);
    if not bEncontrado then
    begin
      sEmpresa := CampoString(ACabecera,
        'CODIGO_EMP_' + ASufijoCabecera);
      bEncontrado := LeerPorcentajesIvaPorEmpresa(AConn, sEmpresa,
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
    end;
  end;
end;

procedure PrepararLineaFiscalVenta(AConn: TUniConnection;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);
var
  rCantidad, rFactorIva, rPorIva, rPrecioCiva, rPrecioSiva: Double;
  bImpuestosIncluidos: Boolean;
  sArticulo, sCampoTipo, sTipoArt, sTipoIva: string;
begin
  if Assigned(ACabecera) and Assigned(ALinea) and ALinea.Active then
  begin
    sCampoTipo := 'TIPO_IVA_ARTICULO_' + ASufijoLinea;
    sArticulo := CampoString(ALinea, 'CODIGO_ART_' + ASufijoLinea);
    sTipoIva := NormalizarTipoIva(CampoString(ALinea, sCampoTipo));
    if ClienteExento(ACabecera, ASufijoCabecera) then
      sTipoIva := 'E'
    else
    begin
      sTipoArt := ObtenerTipoIvaArticulo(AConn, sArticulo);
      if sTipoArt <> '' then
        sTipoIva := sTipoArt;
    end;
    rPorIva := PorcentajeIvaDocumentoVenta(AConn, ACabecera,
      ASufijoCabecera, sTipoIva);
    if ClienteExento(ACabecera, ASufijoCabecera) then
      rPorIva := 0;
    rCantidad := CampoFloat(ALinea, 'CANTIDAD_' + ASufijoLinea);
    rFactorIva := 1 + rPorIva / 100;
    bImpuestosIncluidos := EsSi(ALinea,
      'ESIMP_INCL_TARIFA_' + ASufijoLinea);
    if bImpuestosIncluidos then
    begin
      // El PVP de una tarifa con impuestos es el precio maestro.
      rPrecioCiva := CampoFloat(ALinea,
        'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea);
      rPrecioSiva := rPrecioCiva;
      if rFactorIva <> 0 then
        rPrecioSiva := rPrecioCiva / rFactorIva;
    end
    else
    begin
      // En una tarifa sin impuestos la base es el precio maestro.
      rPrecioSiva := CampoFloat(ALinea,
        'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea);
      rPrecioCiva := rPrecioSiva * rFactorIva;
    end;
    if not (ALinea.State in dsEditModes) then
      ALinea.Edit;
    PonerString(ALinea, sCampoTipo, sTipoIva);
    PonerFloat(ALinea, 'PORCENTAJE_IVA_' + ASufijoLinea, rPorIva);
    PonerFloat(ALinea, 'PRECIO_VENTA_SIVA_ARTICULO_' + ASufijoLinea,
      rPrecioSiva);
    PonerFloat(ALinea, 'PRECIO_VENTA_CIVA_ARTICULO_' + ASufijoLinea,
      rPrecioCiva);
    PonerFloat(ALinea, ACampoTotalLinea, rCantidad * rPrecioSiva);
  end;
end;

procedure CalcularTotalesDocumentoVenta(AConn: TUniConnection;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  aImportes: array[0..3] of TImportesTipoIvaVenta;
  bk: TBookmark;
  iIndice: Integer;
  rTotal, rPorIva, rPorRe, rBase, rIva, rRe, rImp, rRet: Double;
  sArticulo, sSufijoLinea, sTipoArt, sTipoIva, sTipoLinea: string;
  bAplicaRe, bClienteExento, bFiltroActivo: Boolean;
begin
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    FillChar(aImportes, SizeOf(aImportes), 0);
    AplicarPorcentajesIvaVenta(AConn, ACabecera, ASufijoCabecera);
    sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
    bAplicaRe := AplicaRecargoVenta(ACabecera, ASufijoCabecera);
    bClienteExento := ClienteExento(ACabecera, ASufijoCabecera);
    bk := ALineas.GetBookmark;
    bFiltroActivo := ALineas.Filtered;
    try
      ALineas.DisableControls;
      if bFiltroActivo then
        ALineas.Filtered := False;
      ALineas.First;
      while not ALineas.Eof do
      begin
        sTipoLinea := CampoString(ALineas, ACampoTipoIvaLinea);
        sTipoIva := NormalizarTipoIva(sTipoLinea);
        if bClienteExento then
          sTipoIva := 'E'
        else if sSufijoLinea <> '' then
        begin
          sArticulo := CampoString(ALineas, 'CODIGO_ART_' + sSufijoLinea);
          sTipoArt := ObtenerTipoIvaArticulo(AConn, sArticulo);
          if sTipoArt <> '' then
            sTipoIva := sTipoArt;
        end;
        iIndice := IndiceTipoIva(sTipoIva);
        rTotal := CampoFloat(ALineas, ACampoTotalLinea);
        rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
        if rPorIva = 0 then
          rPorIva := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera,
            sTipoIva);
        if bClienteExento then
          rPorIva := 0;
        rPorRe := PorcentajeReCabecera(ACabecera, ASufijoCabecera,
          sTipoIva);
        aImportes[iIndice].Base := aImportes[iIndice].Base + rTotal;
        aImportes[iIndice].Iva := aImportes[iIndice].Iva +
          (rTotal * rPorIva / 100);
        if bAplicaRe then
          aImportes[iIndice].Re := aImportes[iIndice].Re +
            (rTotal * rPorRe / 100);
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
    rBase := 0;
    rIva := 0;
    rRe := 0;
    for iIndice := 0 to 3 do
    begin
      PonerFloat(ACabecera,
        'TOTAL_BASEI_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
        aImportes[iIndice].Base);
      PonerFloat(ACabecera,
        'TOTAL_' + CODIGOS_IVA[iIndice] + '_' + ASufijoCabecera,
        aImportes[iIndice].Iva);
      PonerFloat(ACabecera,
        'TOTAL_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera,
        aImportes[iIndice].Re);
      rBase := rBase + aImportes[iIndice].Base;
      rIva := rIva + aImportes[iIndice].Iva;
      rRe := rRe + aImportes[iIndice].Re;
    end;
    rImp := rIva + rRe;
    rRet := CalcularRetencionVenta(AConn, ACabecera, ASufijoCabecera,
      rBase, rImp);
    PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera, rBase);
    PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera, rBase);
    PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera, rImp);
    PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera, rRet);
    PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera, rBase + rImp);
    PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
      rBase + rImp - rRet);
  end;
end;

function TotalPrendasLineasVenta(ALineas: TDataSet;
  const ACampoTipoIvaLinea: string): Double;
var
  bk: TBookmark;
  sSufijoLinea: string;
  bFiltroActivo: Boolean;
begin
  Result := 0;
  if not (Assigned(ALineas) and ALineas.Active) then
    Exit;
  // Con una linea en insercion/edicion NO se recorre: el First haria
  // CheckBrowseMode y cancelaria la linea a medio insertar, dejando
  // que el AfterInsert siguiera con el dataset ya en browse ('Dataset
  // not in edit or insert mode' al anadir linea, 09/07/26). El total
  // se refresca en el siguiente AfterPost.
  if ALineas.State in dsEditModes then
    Exit;
  sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
  if sSufijoLinea = '' then
    Exit;
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
      Result := Result + CampoFloat(ALineas, 'CANTIDAD_' + sSufijoLinea);
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

end.
