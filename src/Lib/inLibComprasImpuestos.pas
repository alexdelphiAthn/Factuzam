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
  System.SysUtils, Data.DB, DBAccess, Uni;

function ObtenerRecargoComprasEmpresa(AConn: TUniConnection;
  const ACodigoEmp: string): string;

function ObtenerIvaExentoIntracomunitarioProveedor(AConn: TUniConnection;
  const ACodigoPrv: string): string;

procedure AplicarRecargoComprasEmpresa(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);

procedure AplicarIvaExentoIntracomunitarioProveedor(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);

procedure AplicarPorcentajesIvaCompra(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure AplicarPorcentajesRecargoCompra(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure PrepararLineaFiscalCompra(AConn: TUniConnection;
  ACabecera, ALinea: TDataSet; const ASufijoCabecera, ASufijoLinea,
  ACampoTotalLinea: string);

procedure CalcularTotalesDocumentoCompra(AConn: TUniConnection;
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

uses inLibImpuestosComun;

type
  TImportesTipoIvaCompra = record
    Base: Double;
    Iva : Double;
    Re  : Double;
  end;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');



function DocumentoCompraExentoIntracomunitario(ACabecera: TDataSet;
  const ASufijoCabecera: string): Boolean;
begin
  Result := UpperCase(Trim(CampoString(ACabecera,
    'ESIVA_EXENTO_INTRACOMUNITARIO_' + ASufijoCabecera))) = 'S';
end;












function PorcentajeIvaDocumentoCompra(AConn: TUniConnection;
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

function ObtenerRecargoComprasEmpresa(AConn: TUniConnection;
  const ACodigoEmp: string): string;
var
  q: TUniQuery;
begin
  Result := 'N';
  if (AConn <> nil) and (Trim(ACodigoEmp) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT IFNULL(ESIVA_RECARGO_COMPRAS_EMP, ''N'') AS RECARGO ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :emp';
      q.ParamByName('emp').AsString := ACodigoEmp;
      q.Open;
      if not q.Eof then
        Result := q.FieldByName('RECARGO').AsString;
    finally
      FreeAndNil(q);
    end;
  end;
  if Result <> 'S' then
    Result := 'N';
end;

function ObtenerIvaExentoIntracomunitarioProveedor(AConn: TUniConnection;
  const ACodigoPrv: string): string;
var
  q: TUniQuery;
begin
  Result := 'N';
  if (AConn <> nil) and (Trim(ACodigoPrv) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT IFNULL(ESIVA_EXENTO_INTRACOMUNITARIO_PRV, ''N'') ' +
        '       AS EXENTO ' +
        '  FROM fza_proveedores ' +
        ' WHERE CODIGO_PRV_PRV = :prv';
      q.ParamByName('prv').AsString := ACodigoPrv;
      q.Open;
      if not q.Eof then
        Result := q.FieldByName('EXENTO').AsString;
    finally
      FreeAndNil(q);
    end;
  end;
  if Result <> 'S' then
    Result := 'N';
end;

procedure AplicarRecargoComprasEmpresa(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);
var
  sEmpresa: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoRecargo) <> nil) then
  begin
    sEmpresa := CampoString(ACabecera, ACampoEmpresa);
    PonerString(ACabecera, ACampoRecargo,
                ObtenerRecargoComprasEmpresa(AConn, sEmpresa));
  end;
end;

procedure AplicarIvaExentoIntracomunitarioProveedor(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoProveedor, ACampoExento: string);
var
  sProveedor: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoExento) <> nil) then
  begin
    sProveedor := CampoString(ACabecera, ACampoProveedor);
    PonerString(ACabecera, ACampoExento,
      ObtenerIvaExentoIntracomunitarioProveedor(AConn, sProveedor));
  end;
end;

procedure AplicarPorcentajesIvaCompra(AConn: TUniConnection;
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
      end
      else
        AplicarPorcentajesRecargoCompra(AConn, ACabecera, ASufijoCabecera);
    end
  end;
end;

procedure LeerPorcentajesRecargo(AConn: TUniConnection;
  const ACodigoIva: string; out ARecargoNormal, ARecargoReducido,
  ARecargoSuper, ARecargoExento: Double);
var
  q: TUniQuery;
begin
  ARecargoNormal  := 0;
  ARecargoReducido:= 0;
  ARecargoSuper   := 0;
  ARecargoExento  := 0;
  if (AConn <> nil) and (Trim(ACodigoIva) <> '') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := AConn;
      q.SQL.Text :=
        'SELECT IFNULL(PORCENTAJE_NORMAL_RE_IVA, 0) AS REN, ' +
        '       IFNULL(PORCENTAJE_REDUCIDO_RE_IVA, 0) AS RER, ' +
        '       IFNULL(PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) AS RES, ' +
        '       IFNULL(PORCENTAJE_EXENTO_RE_IVA, 0) AS REE ' +
        '  FROM fza_ivas ' +
        ' WHERE CODIGO_IVA = :iva';
      q.ParamByName('iva').AsString := ACodigoIva;
      q.Open;
      if not q.Eof then
      begin
        ARecargoNormal   := q.FieldByName('REN').AsFloat;
        ARecargoReducido := q.FieldByName('RER').AsFloat;
        ARecargoSuper    := q.FieldByName('RES').AsFloat;
        ARecargoExento   := q.FieldByName('REE').AsFloat;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure AplicarPorcentajesRecargoCompra(AConn: TUniConnection;
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
      LeerPorcentajesRecargo(AConn, sCodigoIva, rRecN, rRecR, rRecS,
        rRecE);
    end;
    PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera, rRecN);
    PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera, rRecR);
    PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera, rRecS);
    PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera, rRecE);
  end;
end;

procedure PrepararLineaFiscalCompra(AConn: TUniConnection;
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
      sTipoArt := ObtenerTipoIvaArticulo(AConn, sArticulo);
      if sTipoArt <> '' then
        sTipoIva := sTipoArt;
    end;
    // No editar la cabecera desde el BeforePost de la linea: UniDAC
    // fuerza CheckBrowseMode del detalle y reentra en este mismo Post.
    rPorIva := PorcentajeIvaDocumentoCompra(AConn, ACabecera,
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

procedure CalcularTotalesDocumentoCompra(AConn: TUniConnection;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  aImportes: array[0..3] of TImportesTipoIvaCompra;
  bk: TBookmark;
  iIndice: Integer;
  rTotal, rTotalBruto, rPorIva, rPorRe, rBase, rIva, rRe, rImp,
  rRet, rPorRet, rBruto, rDtoComercial, rDtoFinanciero,
  rFactorComercial: Double;
  sArticulo, sSufijoLinea, sTipoArt, sTipoIva, sTipoLinea: string;
  bAplicaRe: Boolean;
  bExento: Boolean;
  bFiltroActivo: Boolean;
begin
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    FillChar(aImportes, SizeOf(aImportes), 0);
    rBruto := 0;
    AplicarPorcentajesIvaCompra(AConn, ACabecera, ASufijoCabecera);
    sSufijoLinea := SufijoLineaFiscalDesdeCampo(ACampoTipoIvaLinea);
    bExento := DocumentoCompraExentoIntracomunitario(ACabecera,
      ASufijoCabecera);
    bAplicaRe :=
      (not bExento) and
      (UpperCase(CampoString(ACabecera,
        'ESIVA_RECARGO_COMPRAS_' + ASufijoCabecera)) = 'S');
    bk := ALineas.GetBookmark;
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
          sTipoArt := ObtenerTipoIvaArticulo(AConn, sArticulo);
          if sTipoArt <> '' then
            sTipoIva := sTipoArt;
        end;
        iIndice := IndiceTipoIva(sTipoIva);
        rTotalBruto := CampoFloat(ALineas, ACampoTotalLinea);
        rTotal := rTotalBruto * rFactorComercial;
        rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
        if bExento then
          rPorIva := 0
        else if rPorIva = 0 then
          rPorIva := PorcentajeIvaCabecera(ACabecera, ASufijoCabecera,
            sTipoIva);
        rPorRe  := CampoFloat(ACabecera,
          'PORCENTAJE_' + CODIGOS_RE[iIndice] + '_' + ASufijoCabecera);
        aImportes[iIndice].Base := aImportes[iIndice].Base + rTotal;
        aImportes[iIndice].Iva  := aImportes[iIndice].Iva +
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
    rIva  := 0;
    rRe   := 0;
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
      rIva  := rIva + aImportes[iIndice].Iva;
      rRe   := rRe + aImportes[iIndice].Re;
    end;
    rImp := rIva + rRe;
    rPorRet := CampoFloat(ACabecera,
      'PORCENTAJE_RETENCION_' + ASufijoCabecera);
    rRet := rBase * rPorRet / 100;
    PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera, rBruto);
    PonerFloat(ACabecera, 'TOTAL_DTO_COMERCIAL_' + ASufijoCabecera,
      rDtoComercial);
    PonerFloat(ACabecera, 'TOTAL_DTO_FINANCIERO_' + ASufijoCabecera,
      rDtoFinanciero);
    PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera, rBase);
    PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera, rImp);
    PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera, rRet);
    PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera, rBase + rImp);
    PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
               rBase + rImp - rRet - rDtoFinanciero);
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
  if not (Assigned(ALineas) and ALineas.Active) then
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

end.
