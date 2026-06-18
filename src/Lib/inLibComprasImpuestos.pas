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

procedure AplicarRecargoComprasEmpresa(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);

procedure AplicarPorcentajesRecargoCompra(AConn: TUniConnection;
  ACabecera: TDataSet; const ASufijoCabecera: string);

procedure CalcularTotalesDocumentoCompra(AConn: TUniConnection;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);

implementation

type
  TImportesTipoIvaCompra = record
    Base: Double;
    Iva : Double;
    Re  : Double;
  end;

const
  CODIGOS_IVA: array[0..3] of string = ('IVAN', 'IVAR', 'IVAS', 'IVAE');
  CODIGOS_RE : array[0..3] of string = ('REN', 'RER', 'RES', 'REE');

function CampoFloat(ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsFloat;
  end;
end;

function CampoString(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and not oCampo.IsNull then
      Result := oCampo.AsString;
  end;
end;

procedure PonerFloat(ADataSet: TDataSet; const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsFloat := AValor;
  end;
end;

procedure PonerString(ADataSet: TDataSet; const ACampo, AValor: string);
var
  oCampo: TField;
begin
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsString := AValor;
  end;
end;

function IndiceTipoIva(const ATipoIva: string): Integer;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoIva));
  Result := 0;
  if sTipo = 'R' then
    Result := 1
  else if sTipo = 'S' then
    Result := 2
  else if sTipo = 'E' then
    Result := 3;
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

procedure AplicarRecargoComprasEmpresa(AConn: TUniConnection;
  ACabecera: TDataSet; const ACampoEmpresa, ACampoRecargo: string);
var
  sEmpresa: string;
begin
  if Assigned(ACabecera) and
     (ACabecera.FindField(ACampoRecargo) <> nil) then
  begin
    if not (ACabecera.State in dsEditModes) then
      ACabecera.Edit;
    sEmpresa := CampoString(ACabecera, ACampoEmpresa);
    PonerString(ACabecera, ACampoRecargo,
                ObtenerRecargoComprasEmpresa(AConn, sEmpresa));
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
    sCodigoIva := CampoString(ACabecera, 'CODIGO_IVA_' + ASufijoCabecera);
    LeerPorcentajesRecargo(AConn, sCodigoIva, rRecN, rRecR, rRecS, rRecE);
    if not (ACabecera.State in dsEditModes) then
      ACabecera.Edit;
    PonerFloat(ACabecera, 'PORCENTAJE_REN_' + ASufijoCabecera, rRecN);
    PonerFloat(ACabecera, 'PORCENTAJE_RER_' + ASufijoCabecera, rRecR);
    PonerFloat(ACabecera, 'PORCENTAJE_RES_' + ASufijoCabecera, rRecS);
    PonerFloat(ACabecera, 'PORCENTAJE_REE_' + ASufijoCabecera, rRecE);
  end;
end;

procedure CalcularTotalesDocumentoCompra(AConn: TUniConnection;
  ACabecera, ALineas: TDataSet; const ASufijoCabecera,
  ACampoTotalLinea, ACampoTipoIvaLinea, ACampoPorcentajeIvaLinea: string);
var
  aImportes: array[0..3] of TImportesTipoIvaCompra;
  bk: TBookmark;
  iIndice: Integer;
  rTotal, rPorIva, rPorRe, rBase, rIva, rRe, rImp, rRet, rPorRet: Double;
  bAplicaRe: Boolean;
begin
  if Assigned(ACabecera) and Assigned(ALineas) and ALineas.Active then
  begin
    FillChar(aImportes, SizeOf(aImportes), 0);
    AplicarPorcentajesRecargoCompra(AConn, ACabecera, ASufijoCabecera);
    bAplicaRe :=
      UpperCase(CampoString(ACabecera,
        'ESIVA_RECARGO_COMPRAS_' + ASufijoCabecera)) = 'S';
    bk := ALineas.GetBookmark;
    try
      ALineas.DisableControls;
      ALineas.First;
      while not ALineas.Eof do
      begin
        iIndice := IndiceTipoIva(CampoString(ALineas, ACampoTipoIvaLinea));
        rTotal  := CampoFloat(ALineas, ACampoTotalLinea);
        rPorIva := CampoFloat(ALineas, ACampoPorcentajeIvaLinea);
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
      if ALineas.BookmarkValid(bk) then
        ALineas.GotoBookmark(bk);
      ALineas.FreeBookmark(bk);
      ALineas.EnableControls;
    end;
    if not (ACabecera.State in dsEditModes) then
      ACabecera.Edit;
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
    PonerFloat(ACabecera, 'TOTAL_BRUTO_' + ASufijoCabecera, rBase);
    PonerFloat(ACabecera, 'TOTAL_BASES_' + ASufijoCabecera, rBase);
    PonerFloat(ACabecera, 'TOTAL_IMPUESTOS_' + ASufijoCabecera, rImp);
    PonerFloat(ACabecera, 'TOTAL_RETENCION_' + ASufijoCabecera, rRet);
    PonerFloat(ACabecera, 'TOTAL_' + ASufijoCabecera, rBase + rImp);
    PonerFloat(ACabecera, 'TOTAL_LIQUIDO_' + ASufijoCabecera,
               rBase + rImp - rRet);
  end;
end;

end.
