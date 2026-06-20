{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigVentasMayor                                           }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Importa la cadena de VENTA MAYOR del legacy a Factuzam:                   }
{      dbo.ocpedcli    → fza_pedidos + fza_pedidos_lineas                      }
{      dbo.ocalbcli    → fza_albaranes + fza_albaranes_lineas                  }
{      dbo.ocfaccli    → fza_facturas + fza_facturas_lineas                    }
{                                                                              }
{    Modelo PLANO: una línea por cada fila legacy, conservando el SKU           }
{    Articulo/Color/Talla en albaranes y facturas. En pedidos no hay columna   }
{    CODIGO_UNIDAD_PEDLIN, por eso el SKU se guarda en CODIGOPRODPS_PEDLIN.    }
{                                                                              }
{    Clave Factuzam:                                                           }
{      SERIE  = '<Ejercicio>.<Serie>'                                          }
{      NUMERO = NroPedido / NroAlbaran / NroFactura a 6 dígitos                }
{                                                                              }
{    IVA: 4 bandas legacy clasificadas en N/R/S/E por porcentaje. Las líneas   }
{    también clasifican TIPO_IVA_ARTICULO_* por su PorIVA.                     }
{******************************************************************************}
unit inLibMigVentasMayor;

interface

uses
  UMigEngine;

procedure MigrarPedidosVentaMayor(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarAlbaranesVentaMayor(Eng: TMigEngine; var Stats: TMigStats);
procedure MigrarFacturasVentaMayor(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

const
  BATCH = 2000;

var
  fsVentasMayor: TFormatSettings;

type
  TIvaVentaMayor = record
    Pn, Tn, Bn, Rn, Trn: Double;
    Pr, Tr, Br, Rr, Trr: Double;
    Ps, Ts, Bs, Rs, Trs: Double;
    Pe, Te, Be, Re, Tre: Double;
    Bases, Impuestos:   Double;
  end;

// =========================================================================
//  Helpers compartidos
// =========================================================================

function F(v: Double): string;
begin
  Result := FloatToStr(v, fsVentasMayor);
end;

function TextoCampo(q: TUniQuery; const sCampo: string;
                    iMax: Integer = 0): string;
begin
  Result := '';
  if q.FindField(sCampo) <> nil then
    Result := Trim(q.FieldByName(sCampo).AsString);
  if (iMax > 0) and (Length(Result) > iMax) then
    Result := Copy(Result, 1, iMax);
end;

function FechaCampoASQL(q: TUniQuery; const sCampo: string): string;
begin
  Result := 'NULL';
  if (q.FindField(sCampo) <> nil) and not q.FieldByName(sCampo).IsNull then
    Result := DateTimeASQL(Trunc(q.FieldByName(sCampo).AsDateTime));
end;

function SerieDocumento(iEjercicio: Integer; const sSerie: string): string;
begin
  Result := Format('%d.%s', [iEjercicio, Trim(sSerie)]);
end;

function NumeroDocumento(iNumero: Integer): string;
begin
  Result := Format('%.6d', [iNumero]);
end;

function LineaPedido(iLinea: Integer): string;
begin
  Result := Format('%.3d', [iLinea]);
end;

function LineaDocumento(iLinea: Integer): string;
begin
  Result := Format('%.4d', [iLinea]);
end;

function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var
  u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var
  sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then
    sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then
    sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

function NombreClienteDocumento(q: TUniQuery): string;
begin
  Result := TextoCampo(q, 'RazonSocial', 200);
  if Result = '' then
    Result := TextoCampo(q, 'Nombre', 200);
end;

function CodigoFormaPagoVentaMayor(q: TUniQuery): string;
var
  iTipo: Integer;
begin
  Result := '';
  if q.FindField('TipoEfecto') <> nil then
  begin
    iTipo := q.FieldByName('TipoEfecto').AsInteger;
    if iTipo > 0 then
      Result := IntToStr(iTipo);
  end;
  if Result = '' then
    Result := TextoCampo(q, 'FormaPago', 200);
end;

function CodigoTarifaVentaMayor(q: TUniQuery): string;
var
  iTarifa: Integer;
begin
  Result := '';
  if q.FindField('Tarifa') <> nil then
  begin
    iTarifa := q.FieldByName('Tarifa').AsInteger;
    if iTarifa > 0 then
      Result := IntToStr(iTarifa);
  end;
end;

function BandaIva(const rate: Double): Integer;
begin
  if rate <= 0 then
    Result := 3
  else if rate < 6 then
    Result := 2
  else if rate < 13 then
    Result := 1
  else
    Result := 0;
end;

function TipoIvaArticulo(const rate: Double): string;
begin
  case BandaIva(rate) of
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

procedure AcumularIva(var R: TIvaVentaMayor; iBanda: Integer;
                      fBase, fPorIva, fCuotaIva, fPorRe,
                      fCuotaRe: Double);
begin
  case iBanda of
    1:
      begin
        R.Br := R.Br + fBase;
        R.Tr := R.Tr + fCuotaIva;
        R.Trr := R.Trr + fCuotaRe;
        if fPorIva > R.Pr then
          R.Pr := fPorIva;
        if fPorRe > R.Rr then
          R.Rr := fPorRe;
      end;
    2:
      begin
        R.Bs := R.Bs + fBase;
        R.Ts := R.Ts + fCuotaIva;
        R.Trs := R.Trs + fCuotaRe;
        if fPorIva > R.Ps then
          R.Ps := fPorIva;
        if fPorRe > R.Rs then
          R.Rs := fPorRe;
      end;
    3:
      begin
        R.Be := R.Be + fBase;
        R.Te := R.Te + fCuotaIva;
        R.Tre := R.Tre + fCuotaRe;
        if fPorIva > R.Pe then
          R.Pe := fPorIva;
        if fPorRe > R.Re then
          R.Re := fPorRe;
      end;
  else
    begin
      R.Bn := R.Bn + fBase;
      R.Tn := R.Tn + fCuotaIva;
      R.Trn := R.Trn + fCuotaRe;
      if fPorIva > R.Pn then
        R.Pn := fPorIva;
      if fPorRe > R.Rn then
        R.Rn := fPorRe;
    end;
  end;
end;

procedure CalcularIvaVentaMayor(q: TUniQuery; var R: TIvaVentaMayor);
var
  i: Integer;
  fBase, fPorIva, fCuotaIva, fPorRe, fCuotaRe: Double;
begin
  FillChar(R, SizeOf(R), 0);
  for i := 1 to 4 do
  begin
    fBase := q.FieldByName('ImpBaseImp' + IntToStr(i)).AsFloat;
    fPorIva := q.FieldByName('PorIVA' + IntToStr(i)).AsFloat;
    fCuotaIva := q.FieldByName('CuotaIVA' + IntToStr(i)).AsFloat;
    fPorRe := q.FieldByName('PorRE' + IntToStr(i)).AsFloat;
    fCuotaRe := q.FieldByName('CuotaRE' + IntToStr(i)).AsFloat;
    if (fBase <> 0) or (fCuotaIva <> 0) or (fCuotaRe <> 0) then
    begin
      if (fCuotaIva = 0) and (fPorIva > 0) then
        fCuotaIva := fBase * fPorIva / 100;
      if (fCuotaRe = 0) and (fPorRe > 0) then
        fCuotaRe := fBase * fPorRe / 100;
      AcumularIva(R, BandaIva(fPorIva), fBase, fPorIva, fCuotaIva,
                  fPorRe, fCuotaRe);
    end;
  end;
  R.Bases := R.Bn + R.Br + R.Bs + R.Be;
  R.Impuestos := R.Tn + R.Tr + R.Ts + R.Te +
                 R.Trn + R.Trr + R.Trs + R.Tre;
end;

function EstadoPedidoVenta(fPedido, fServido: Double): string;
begin
  if fServido <= 0 then
    Result := 'ABIERTO'
  else if fServido < fPedido then
    Result := 'PARCIAL'
  else
    Result := 'ENTREGADO';
end;

function EsLineaEntregada(fCantidad, fServida: Double): string;
begin
  if (fCantidad > 0) and (fServida >= fCantidad) then
    Result := 'S'
  else
    Result := 'N';
end;

function EstadoAlbaranVenta(q: TUniQuery): string;
begin
  if q.FieldByName('NroFactura').AsInteger > 0 then
    Result := 'FACTURADO'
  else
    Result := 'ABIERTO';
end;

function TipoFacturaVentaMayor(q: TUniQuery): string;
begin
  Result := 'NORMAL';
  if (q.FindField('NroAbono') <> nil)
  and (q.FieldByName('NroAbono').AsInteger > 0) then
    Result := 'RECTIFICATIVA';
  if (q.FindField('NroFraRctva') <> nil)
  and (q.FieldByName('NroFraRctva').AsInteger > 0) then
    Result := 'RECTIFICATIVA';
end;

function CodigoMovimientoVenta(q: TUniQuery): string;
begin
  Result := '';
  if (q.FindField('NumeroMovArt') <> nil)
  and (q.FieldByName('NumeroMovArt').AsInteger > 0) then
    Result := 'MH' + Format('%.10d', [q.FieldByName('NumeroMovArt').AsInteger]);
end;

procedure BorrarPorUsuario(Eng: TMigEngine; const sTabla: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := 'DELETE FROM ' + sTabla + ' WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure LimpiarFacturasVentaMayor(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'DELETE l FROM fza_facturas_lineas l ' +
      'JOIN fza_facturas f ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN ' +
      '                    AND f.SERIE_FAC = l.SERIE_FAC_FACLIN ' +
      'WHERE l.USUARIO_ALTA = :u ' +
      '  AND f.USUARIO_ALTA = :u ' +
      '  AND COALESCE(f.TIPO_FAC, '''') <> ''SIMPLIFICADA''';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_facturas ' +
      'WHERE USUARIO_ALTA = :u ' +
      '  AND COALESCE(TIPO_FAC, '''') <> ''SIMPLIFICADA''';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure EnlazarEmpresaVentaMayor(Eng: TMigEngine; const sTabla,
                                   sSuf: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := Format(
      'UPDATE %0:s d ' +
      'JOIN fza_empresas e ON e.CODIGO_EMP_EMP = d.CODIGO_EMP_%1:s ' +
      'SET d.RAZON_SOCIAL_EMPRESA_%1:s = e.RAZON_SOCIAL_EMP, ' +
      '    d.NIF_EMPRESA_%1:s = e.NIF_EMP, ' +
      '    d.MOVIL_EMPRESA_%1:s = e.MOVIL_EMP, ' +
      '    d.EMAIL_EMPRESA_%1:s = e.EMAIL_EMP, ' +
      '    d.DIRECCION1_EMPRESA_%1:s = e.DIRECCION1_EMP, ' +
      '    d.DIRECCION2_EMPRESA_%1:s = e.DIRECCION2_EMP, ' +
      '    d.POBLACION_EMPRESA_%1:s = e.POBLACION_EMP, ' +
      '    d.PROVINCIA_EMPRESA_%1:s = e.PROVINCIA_EMP, ' +
      '    d.CODIGO_POSTAL_EMPRESA_%1:s = e.CODIGO_POSTAL_EMP ' +
      'WHERE d.USUARIO_ALTA = :u', [sTabla, sSuf]);
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure EnlazarClientesVentaMayor(Eng: TMigEngine; const sTabla,
                                    sSuf: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := Format(
      'UPDATE %0:s d ' +
      'JOIN fza_clientes c ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_%1:s ' +
      'SET d.ESIVA_RECARGO_CLIENTE_%1:s = COALESCE(c.ESIVA_RECARGO_CLI, ''N''), ' +
      '    d.ESIVA_EXENTO_CLIENTE_%1:s = COALESCE(c.ESIVA_EXENTO_CLI, ''N''), ' +
      '    d.TARIFA_ARTICULO_CLIENTE_%1:s = COALESCE(NULLIF(d.TARIFA_ARTICULO_CLIENTE_%1:s, ''''), c.TARIFA_ARTICULO_CLI), ' +
      '    d.ESINTRACOMUNITARIO_CLIENTE_%1:s = COALESCE(c.ESINTRACOMUNITARIO_CLI, ''N'') ' +
      'WHERE d.USUARIO_ALTA = :u', [sTabla, sSuf]);
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure AjustarRetencionesVentaMayor(Eng: TMigEngine; const sTabla,
                                       sSuf: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := Format(
      'UPDATE %0:s d ' +
      'SET d.ESRETENCIONES_CLIENTE_%1:s = ' +
      'CASE WHEN COALESCE(d.PORCENTAJE_RETENCION_%1:s, 0) <> 0 ' +
      '       OR COALESCE(d.TOTAL_RETENCION_%1:s, 0) <> 0 ' +
      '     THEN ''S'' ELSE ''N'' END ' +
      'WHERE d.USUARIO_ALTA = :u', [sTabla, sSuf]);
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure EnlazarClienteAlbaranVenta(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'UPDATE fza_albaranes d ' +
      'JOIN fza_clientes c ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_ALB ' +
      'SET d.ESIVA_RECARGO_CLIENTE_ALB = COALESCE(c.ESIVA_RECARGO_CLI, ''N''), ' +
      '    d.ESIVA_EXENTO_CLIENTE_ALB = COALESCE(c.ESIVA_EXENTO_CLI, ''N''), ' +
      '    d.ESINTRACOMUNITARIO_CLIENTE_ALB = COALESCE(c.ESINTRACOMUNITARIO_CLI, ''N''), ' +
      '    d.TARIFA_ARTICULO_CLIENTE_ALB = COALESCE(NULLIF(d.TARIFA_ARTICULO_CLIENTE_ALB, ''''), c.TARIFA_ARTICULO_CLI) ' +
      'WHERE d.USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

procedure EnlazarLineasFacturaVentaMayor(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'UPDATE fza_movimientos_almacen m ' +
      'JOIN fza_facturas_lineas l ON l.NUMERO_MOV_FACLIN = m.NUMERO_MOV ' +
      'JOIN fza_facturas f ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN ' +
      '                    AND f.SERIE_FAC = l.SERIE_FAC_FACLIN ' +
      'SET m.TIPO_DOC_REF_MOV = ''FC'', ' +
      '    m.SERIE_DOC_REF_MOV = l.SERIE_FAC_FACLIN, ' +
      '    m.NUMERO_DOC_REF_MOV = l.NUMERO_FAC_FACLIN, ' +
      '    m.LINEA_REF_MOV = l.LINEA_FACLIN, ' +
      '    m.LINEA_MOV = l.LINEA_FACLIN ' +
      'WHERE l.USUARIO_ALTA = :u ' +
      '  AND COALESCE(f.TIPO_FAC, '''') <> ''SIMPLIFICADA'' ' +
      '  AND l.NUMERO_MOV_FACLIN IS NOT NULL ' +
      '  AND l.NUMERO_MOV_FACLIN <> ''''';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// =========================================================================
//  1. Pedidos de venta mayor
// =========================================================================

procedure MigrarPedidosVentaMayor(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelCab =
    'SELECT p.Empresa, p.Ejercicio, ISNULL(p.Serie, '''') AS Serie, ' +
    '       p.NroPedido, ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       p.FechaPedido, p.FechaNecesaria, ISNULL(p.Cliente, '''') AS Cliente, ' +
    '       ISNULL(p.Nombre, '''') AS Nombre, ISNULL(p.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(p.NIF, '''') AS NIF, ISNULL(p.Telefono1, '''') AS Telefono1, ' +
    '       ISNULL(p.Direccion1, '''') AS Direccion1, ISNULL(p.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(p.Poblacion, '''') AS Poblacion, ISNULL(p.Provincia, '''') AS Provincia, ' +
    '       ISNULL(p.CodPostal, '''') AS CodPostal, ISNULL(p.FormaEnvio, '''') AS FormaEnvio, ' +
    '       ISNULL(p.TipoEfecto, 0) AS TipoEfecto, ISNULL(p.FormaPago, '''') AS FormaPago, ' +
    '       ISNULL(p.Tarifa, 0) AS Tarifa, ISNULL(p.PorRetencion, 0) AS PorRetencion, ' +
    '       ISNULL(p.ImpRetencion, 0) AS ImpRetencion, ISNULL(p.CantidadPed, 0) AS CantidadPed, ' +
    '       ISNULL(p.CantidadServida, 0) AS CantidadServida, ISNULL(p.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(p.PorIVA1, 0) AS PorIVA1, ISNULL(p.PorRE1, 0) AS PorRE1, ' +
    '       ISNULL(p.CuotaIVA1, 0) AS CuotaIVA1, ISNULL(p.CuotaRE1, 0) AS CuotaRE1, ' +
    '       ISNULL(p.ImpBaseImp2, 0) AS ImpBaseImp2, ISNULL(p.PorIVA2, 0) AS PorIVA2, ' +
    '       ISNULL(p.PorRE2, 0) AS PorRE2, ISNULL(p.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(p.CuotaRE2, 0) AS CuotaRE2, ISNULL(p.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(p.PorIVA3, 0) AS PorIVA3, ISNULL(p.PorRE3, 0) AS PorRE3, ' +
    '       ISNULL(p.CuotaIVA3, 0) AS CuotaIVA3, ISNULL(p.CuotaRE3, 0) AS CuotaRE3, ' +
    '       ISNULL(p.ImpBaseImp4, 0) AS ImpBaseImp4, ISNULL(p.PorIVA4, 0) AS PorIVA4, ' +
    '       ISNULL(p.PorRE4, 0) AS PorRE4, ISNULL(p.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(p.CuotaRE4, 0) AS CuotaRE4, ISNULL(p.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(p.TotalIVA, 0) AS TotalIVA, ISNULL(p.ImpPedido, 0) AS ImpPedido, ' +
    '       ISNULL(p.ImpLiquido, 0) AS ImpLiquido, ISNULL(p.DocExterno, '''') AS DocExterno, ' +
    '       CONVERT(varchar(2000), p.ObsPedido) AS ObsPedido ' +
    'FROM dbo.ocpedcli p ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = p.Empresa ' +
    '                       AND alm.Almacen = p.Almacen';
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, l.NroPedido, ' +
    '       l.Orden, l.Articulo, l.Color, l.Talla, ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, ' +
    '       l.Almacen AS AlmLin, ISNULL(l.Descripcion, '''') AS Descripcion, ' +
    '       ISNULL(l.CantidadPedida, 0) AS CantidadPedida, ISNULL(l.CantidadServida, 0) AS CantidadServida, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.PorDto, 0) AS PorDto, ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ' +
    '       ISNULL(l.PorIva, 0) AS PorIva, CASE ' +
    '         WHEN l.Color IS NOT NULL AND LTRIM(RTRIM(l.Color)) <> '''' THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' END AS DescColor ' +
    'FROM dbo.ocpedcliart l ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico';
  cColsCab =
    'NUMERO_PED, SERIE_PED, FECHA_PED, ESCONSOLIDADO_PED, ESTADO_PED, ' +
    'FECHA_ENTREGA_PED, CODIGO_EMP_PED, CODIGO_CLI_PED, NIF_CLIENTE_PED, ' +
    'REFERENCIAPS_PED, FORMAPAGOPS_PED, TRANSPORTISTAPS_PED, ' +
    'NOMBRE_CLI_ENVIO_PED, MOVIL_CLIENTE_ENVIO_PED, DIRECCION1_CLIENTE_ENVIO_PED, ' +
    'DIRECCION2_CLIENTE_ENVIO_PED, POBLACION_CLIENTE_ENVIO_PED, ' +
    'PROVINCIA_CLIENTE_ENVIO_PED, CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
    'RAZON_SOCIAL_CLIENTE_FISCAL_PED, MOVIL_CLIENTE_FISCAL_PED, ' +
    'DIRECCION1_CLIENTE_FISCAL_PED, DIRECCION2_CLIENTE_FISCAL_PED, ' +
    'POBLACION_CLIENTE_FISCAL_PED, PROVINCIA_CLIENTE_FISCAL_PED, ' +
    'CODIGO_POSTAL_CLIENTE_FISCAL_PED, TARIFA_ARTICULO_CLIENTE_PED, ' +
    'ESIMP_INCL_TARIFA_CLIENTE_PED, PORCENTAJE_IVAN_PED, TOTAL_IVAN_PED, ' +
    'PORCENTAJE_REN_PED, TOTAL_REN_PED, TOTAL_BASEI_IVAN_PED, ' +
    'PORCENTAJE_IVAR_PED, TOTAL_IVAR_PED, PORCENTAJE_RER_PED, TOTAL_RER_PED, ' +
    'TOTAL_BASEI_IVAR_PED, PORCENTAJE_IVAS_PED, TOTAL_IVAS_PED, ' +
    'PORCENTAJE_RES_PED, TOTAL_RES_PED, TOTAL_BASEI_IVAS_PED, ' +
    'PORCENTAJE_IVAE_PED, TOTAL_IVAE_PED, PORCENTAJE_REE_PED, TOTAL_REE_PED, ' +
    'TOTAL_BASEI_IVAE_PED, TOTAL_BASES_PED, TOTAL_IMPUESTOS_PED, ' +
    'FORMA_PAGO_PED, PORCENTAJE_RETENCION_PED, TOTAL_RETENCION_PED, ' +
    'TOTAL_LIQUIDO_PED, COMENTARIOS_PED, OBSERVACIONES_PED, ' +
    'ESCREARARTICULOS_PED, ESDESCRIPCIONES_AMP_PED, ESFECHADEENTREGA_PED, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_PED_PEDLIN, SERIE_PED_PEDLIN, LINEA_PEDLIN, CODIGOPRODPS_PEDLIN, ' +
    'IDATRIBPRODPS_PEDLIN, CODIGO_ART_PEDLIN, DESCRIPCION_ARTICULO_PEDLIN, ' +
    'ESIMP_INCL_TARIFA_PEDLIN, TIPO_IVA_ARTICULO_PEDLIN, CANTIDAD_PEDLIN, ' +
    'CANTIDAD_ENTREGADA_PEDLIN, CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
    'CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, PORCENTAJE_IVA_PEDLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, TOTAL_PEDLIN, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin: TUniQuery;
  bCab, bLin: TBulkInsert;
  sAhora, sUser, sSerie, sNum, sAlm, sCli, sNombre: string;
  sArt, sSku, sLinea, sVariacion: string;
  iva: TIvaVentaMayor;
  fCant, fServida, fPendiente, fTotal: Double;
begin
  BorrarPorUsuario(Eng, 'fza_pedidos_lineas');
  BorrarPorUsuario(Eng, 'fza_pedidos');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_pedidos', cColsCab, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Log('  venta mayor pedidos 1/2: cabeceras (ocpedcli)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocpedcli'));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en pedidos de venta mayor...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qCab.FieldByName('Ejercicio').AsInteger,
                                qCab.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qCab.FieldByName('NroPedido').AsInteger);
      sAlm := UpperCase(TextoCampo(qCab, 'AbrevAlm', 10));
      sCli := TextoCampo(qCab, 'Cliente', 20);
      sNombre := NombreClienteDocumento(qCab);
      CalcularIvaVentaMayor(qCab, iva);
      fTotal := qCab.FieldByName('ImpLiquido').AsFloat;
      if fTotal = 0 then
        fTotal := qCab.FieldByName('ImpPedido').AsFloat;
      try
        bCab.Add(Format(
          '%s, %s, %s, ''S'', %s, %s, %s, %s, %s, NULL, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, ''N'', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, ''N'', ''N'', ''N'', %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie), FechaCampoASQL(qCab, 'FechaPedido'),
           ValorOrNull(EstadoPedidoVenta(qCab.FieldByName('CantidadPed').AsFloat,
                                          qCab.FieldByName('CantidadServida').AsFloat)),
           FechaCampoASQL(qCab, 'FechaNecesaria'),
           ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
           ValorOrNull(sCli), ValorOrNull(TextoCampo(qCab, 'NIF', 50)),
           ValorOrNull(CodigoFormaPagoVentaMayor(qCab)),
           ValorOrNull(TextoCampo(qCab, 'FormaEnvio', 200)),
           ValorOrNull(sNombre), ValorOrNull(TextoCampo(qCab, 'Telefono1', 40)),
           ValorOrNull(TextoCampo(qCab, 'Direccion1', 200)),
           ValorOrNull(TextoCampo(qCab, 'Direccion2', 200)),
           ValorOrNull(TextoCampo(qCab, 'Poblacion', 200)),
           ValorOrNull(TextoCampo(qCab, 'Provincia', 200)),
           ValorOrNull(TextoCampo(qCab, 'CodPostal', 15)),
           ValorOrNull(sNombre), ValorOrNull(TextoCampo(qCab, 'Telefono1', 40)),
           ValorOrNull(TextoCampo(qCab, 'Direccion1', 200)),
           ValorOrNull(TextoCampo(qCab, 'Direccion2', 200)),
           ValorOrNull(TextoCampo(qCab, 'Poblacion', 200)),
           ValorOrNull(TextoCampo(qCab, 'Provincia', 200)),
           ValorOrNull(TextoCampo(qCab, 'CodPostal', 15)),
           ValorOrNull(CodigoTarifaVentaMayor(qCab)),
           F(iva.Pn), F(iva.Tn), F(iva.Rn), F(iva.Trn), F(iva.Bn),
           F(iva.Pr), F(iva.Tr), F(iva.Rr), F(iva.Trr), F(iva.Br),
           F(iva.Ps), F(iva.Ts), F(iva.Rs), F(iva.Trs), F(iva.Bs),
           F(iva.Pe), F(iva.Te), F(iva.Re), F(iva.Tre), F(iva.Be),
           F(iva.Bases), F(iva.Impuestos),
           ValorOrNull(CodigoFormaPagoVentaMayor(qCab)),
           F(qCab.FieldByName('PorRetencion').AsFloat),
           F(qCab.FieldByName('ImpRetencion').AsFloat), F(fTotal),
           ValorOrNull(TextoCampo(qCab, 'ObsPedido', 1000)),
           ValorOrNull(TextoCampo(qCab, 'DocExterno', 2000)),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('pedido_venta', sSerie + '/' + sNum, E.Message, '',
            'requiere Empresas/Clientes migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
  end;
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_pedidos_lineas', cColsLin,
                             BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  venta mayor pedidos 2/2: lineas (ocpedcliart)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocpedcliart'));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de pedido venta...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qLin.FieldByName('Ejercicio').AsInteger,
                                qLin.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qLin.FieldByName('NroPedido').AsInteger);
      sLinea := LineaPedido(qLin.FieldByName('Orden').AsInteger);
      sArt := TextoCampo(qLin, 'Articulo', 20);
      sSku := ConstruirCodigoUnidad(sArt, TextoCampo(qLin, 'DescColor', 25),
                                    TextoCampo(qLin, 'Talla', 7));
      sAlm := UpperCase(TextoCampo(qLin, 'AbrevAlmLin', 10));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      fCant := qLin.FieldByName('CantidadPedida').AsFloat;
      fServida := qLin.FieldByName('CantidadServida').AsFloat;
      fPendiente := fCant - fServida;
      if fPendiente < 0 then
        fPendiente := 0;
      sVariacion := TextoCampo(qLin, 'DescColor', 25) + '/' +
                    TextoCampo(qLin, 'Talla', 7);
      try
        bLin.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, ''N'', %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie), ValorOrNull(sLinea),
           ValorOrNull(sSku), ValorOrNull(sVariacion), ValorOrNull(sArt),
           ValorOrNull(TextoCampo(qLin, 'Descripcion', 100)),
           ValorOrNull(TipoIvaArticulo(qLin.FieldByName('PorIva').AsFloat)),
           F(fCant), F(fServida), F(fPendiente),
           ValorOrNull(EsLineaEntregada(fCant, fServida)), ValorOrNull(sAlm),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PorIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('pedido_venta_linea', sSerie + '/' + sNum, E.Message,
            Format('linea=%s', [sLinea]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
  finally
    bLin.Free;
    qLin.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaVentaMayor(Eng, 'fza_pedidos', 'PED');
    EnlazarClientesVentaMayor(Eng, 'fza_pedidos', 'PED');
    AjustarRetencionesVentaMayor(Eng, 'fza_pedidos', 'PED');
    Eng.Log('  pedidos venta mayor: empresa y flags de cliente rellenados.');
  end;
end;

// =========================================================================
//  2. Albaranes de venta mayor
// =========================================================================

procedure MigrarAlbaranesVentaMayor(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelCab =
    'SELECT a.Empresa, a.Ejercicio, ISNULL(a.Serie, '''') AS Serie, a.NroAlbaran, ' +
    '       a.Fecha, ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ISNULL(a.Cliente, '''') AS Cliente, ' +
    '       ISNULL(a.Nombre, '''') AS Nombre, ISNULL(a.RazonSocial, '''') AS RazonSocial, ' +
    '       ISNULL(a.NIF, '''') AS NIF, ISNULL(a.Telefono1, '''') AS Telefono1, ' +
    '       ISNULL(a.Direccion1, '''') AS Direccion1, ISNULL(a.Direccion2, '''') AS Direccion2, ' +
    '       ISNULL(a.Poblacion, '''') AS Poblacion, ISNULL(a.Provincia, '''') AS Provincia, ' +
    '       ISNULL(a.CodPostal, '''') AS CodPostal, ISNULL(a.FormaEnvio, '''') AS FormaEnvio, ' +
    '       ISNULL(a.TipoEfecto, 0) AS TipoEfecto, ISNULL(a.FormaPago, '''') AS FormaPago, ' +
    '       ISNULL(a.Tarifa, 0) AS Tarifa, a.EjercicioPedido, ISNULL(a.SeriePedido, '''') AS SeriePedido, ' +
    '       ISNULL(a.NroPedido, 0) AS NroPedido, a.EjercicioFactura, ISNULL(a.SerieFactura, '''') AS SerieFactura, ' +
    '       ISNULL(a.NroFactura, 0) AS NroFactura, ISNULL(a.ImpBaseImp1, 0) AS ImpBaseImp1, ' +
    '       ISNULL(a.PorIVA1, 0) AS PorIVA1, ISNULL(a.PorRE1, 0) AS PorRE1, ' +
    '       ISNULL(a.CuotaIVA1, 0) AS CuotaIVA1, ISNULL(a.CuotaRE1, 0) AS CuotaRE1, ' +
    '       ISNULL(a.ImpBaseImp2, 0) AS ImpBaseImp2, ISNULL(a.PorIVA2, 0) AS PorIVA2, ' +
    '       ISNULL(a.PorRE2, 0) AS PorRE2, ISNULL(a.CuotaIVA2, 0) AS CuotaIVA2, ' +
    '       ISNULL(a.CuotaRE2, 0) AS CuotaRE2, ISNULL(a.ImpBaseImp3, 0) AS ImpBaseImp3, ' +
    '       ISNULL(a.PorIVA3, 0) AS PorIVA3, ISNULL(a.PorRE3, 0) AS PorRE3, ' +
    '       ISNULL(a.CuotaIVA3, 0) AS CuotaIVA3, ISNULL(a.CuotaRE3, 0) AS CuotaRE3, ' +
    '       ISNULL(a.ImpBaseImp4, 0) AS ImpBaseImp4, ISNULL(a.PorIVA4, 0) AS PorIVA4, ' +
    '       ISNULL(a.PorRE4, 0) AS PorRE4, ISNULL(a.CuotaIVA4, 0) AS CuotaIVA4, ' +
    '       ISNULL(a.CuotaRE4, 0) AS CuotaRE4, ISNULL(a.ImpBaseImp, 0) AS ImpBaseImp, ' +
    '       ISNULL(a.ImpAlbaran, 0) AS ImpAlbaran, ISNULL(a.ImpLiquido, 0) AS ImpLiquido, ' +
    '       CONVERT(varchar(2000), a.ObsAlbaran) AS ObsAlbaran ' +
    'FROM dbo.ocalbcli a ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = a.Empresa ' +
    '                       AND alm.Almacen = a.Almacen';
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, l.NroAlbaran, ' +
    '       l.Orden, l.Articulo, l.Color, l.Talla, ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, ' +
    '       l.Almacen AS AlmLin, ISNULL(l.Descripcion, '''') AS Descripcion, ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ISNULL(l.PorIVA, 0) AS PorIVA, ' +
    '       l.EjercicioPedido, ISNULL(l.SeriePedido, '''') AS SeriePedido, ISNULL(l.NroPedido, 0) AS NroPedido, ' +
    '       ISNULL(pl.Orden, ISNULL(l.IdPed, 0)) AS OrdenPedido, l.EjercicioFactura, ' +
    '       ISNULL(l.SerieFactura, '''') AS SerieFactura, ISNULL(l.NroFactura, 0) AS NroFactura, ' +
    '       CASE WHEN l.Color IS NOT NULL AND LTRIM(RTRIM(l.Color)) <> '''' THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '            WHEN co.Descripcion IS NOT NULL AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '            ELSE ''0'' END AS DescColor ' +
    'FROM dbo.ocalbcliart l ' +
    'LEFT JOIN dbo.ocpedcliart pl ON pl.Empresa = l.EmpresaPedido ' +
    '                            AND pl.Ejercicio = l.EjercicioPedido ' +
    '                            AND pl.Serie = l.SeriePedido ' +
    '                            AND pl.NroPedido = l.NroPedido ' +
    '                            AND pl.Id = l.IdPed ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico';
  cColsCab =
    'NUMERO_ALB, SERIE_ALB, FECHA_ALB, ESCONSOLIDADO_ALB, ESTADO_ALB, ' +
    'NUMERO_PED_ALB, SERIE_PED_ALB, NUMERO_FAC_ALB, SERIE_FAC_ALB, ' +
    'CODIGO_EMP_ALB, CODIGO_CLI_ALB, RAZON_SOCIAL_CLIENTE_ALB, NIF_CLIENTE_ALB, ' +
    'MOVIL_CLIENTE_ALB, DIRECCION1_CLIENTE_ALB, DIRECCION2_CLIENTE_ALB, ' +
    'POBLACION_CLIENTE_ALB, PROVINCIA_CLIENTE_ALB, CODIGO_POSTAL_CLIENTE_ALB, ' +
    'NOMBRE_CLI_ENVIO_ALB, MOVIL_CLIENTE_ENVIO_ALB, DIRECCION1_CLIENTE_ENVIO_ALB, ' +
    'DIRECCION2_CLIENTE_ENVIO_ALB, POBLACION_CLIENTE_ENVIO_ALB, ' +
    'PROVINCIA_CLIENTE_ENVIO_ALB, CODIGO_POSTAL_CLIENTE_ENVIO_ALB, ' +
    'TRANSPORTISTA_ALB, TARIFA_ARTICULO_CLIENTE_ALB, ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
    'PORCENTAJE_IVAN_ALB, TOTAL_IVAN_ALB, PORCENTAJE_IVAR_ALB, TOTAL_IVAR_ALB, ' +
    'PORCENTAJE_IVAS_ALB, TOTAL_IVAS_ALB, PORCENTAJE_IVAE_ALB, TOTAL_IVAE_ALB, ' +
    'TOTAL_BASES_ALB, TOTAL_IMPUESTOS_ALB, TOTAL_LIQUIDO_ALB, FORMA_PAGO_ALB, ' +
    'COMENTARIOS_ALB, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, NUMERO_PED_ALBLIN, ' +
    'SERIE_PED_ALBLIN, LINEA_PED_ALBLIN, CODIGO_ART_ALBLIN, DESCRIPCION_ARTICULO_ALBLIN, ' +
    'TIPO_IVA_ARTICULO_ALBLIN, PORCENTAJE_IVA_ALBLIN, PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, TOTAL_ALBLIN, CODIGO_ALMACEN_ALBLIN, ' +
    'ESFACTURADA_ALBLIN, NUMERO_FAC_ALBLIN, SERIE_FAC_ALBLIN, LINEA_FAC_ALBLIN, ' +
    'CODIGO_UNIDAD_ALBLIN, DESCRIPCION_VARIACION_ALBLIN, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin: TUniQuery;
  bCab, bLin: TBulkInsert;
  sAhora, sUser, sSerie, sNum, sCli, sNombre, sNumPed, sSeriePed: string;
  sNumFac, sSerieFac, sLineaFac, sAlm, sArt, sSku, sLinea, sLineaPed: string;
  sFacturada: string;
  iva: TIvaVentaMayor;
  fTotal: Double;
begin
  BorrarPorUsuario(Eng, 'fza_albaranes_lineas');
  BorrarPorUsuario(Eng, 'fza_albaranes');
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_albaranes', cColsCab, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Log('  venta mayor albaranes 1/2: cabeceras (ocalbcli)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocalbcli'));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en albaranes de venta mayor...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qCab.FieldByName('Ejercicio').AsInteger,
                                qCab.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qCab.FieldByName('NroAlbaran').AsInteger);
      sCli := TextoCampo(qCab, 'Cliente', 20);
      sNombre := NombreClienteDocumento(qCab);
      if qCab.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed := ValorOrNull(NumeroDocumento(qCab.FieldByName('NroPedido').AsInteger));
        sSeriePed := ValorOrNull(SerieDocumento(qCab.FieldByName('EjercicioPedido').AsInteger,
                                                qCab.FieldByName('SeriePedido').AsString));
      end
      else
      begin
        sNumPed := 'NULL';
        sSeriePed := 'NULL';
      end;
      if qCab.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sNumFac := ValorOrNull(NumeroDocumento(qCab.FieldByName('NroFactura').AsInteger));
        sSerieFac := ValorOrNull(SerieDocumento(qCab.FieldByName('EjercicioFactura').AsInteger,
                                                qCab.FieldByName('SerieFactura').AsString));
      end
      else
      begin
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
      end;
      CalcularIvaVentaMayor(qCab, iva);
      fTotal := qCab.FieldByName('ImpLiquido').AsFloat;
      if fTotal = 0 then
        fTotal := qCab.FieldByName('ImpAlbaran').AsFloat;
      try
        bCab.Add(Format(
          '%s, %s, %s, ''S'', %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, ''N'', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie), FechaCampoASQL(qCab, 'Fecha'),
           ValorOrNull(EstadoAlbaranVenta(qCab)), sNumPed, sSeriePed,
           sNumFac, sSerieFac,
           ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
           ValorOrNull(sCli), ValorOrNull(sNombre),
           ValorOrNull(TextoCampo(qCab, 'NIF', 50)),
           ValorOrNull(TextoCampo(qCab, 'Telefono1', 40)),
           ValorOrNull(TextoCampo(qCab, 'Direccion1', 200)),
           ValorOrNull(TextoCampo(qCab, 'Direccion2', 200)),
           ValorOrNull(TextoCampo(qCab, 'Poblacion', 200)),
           ValorOrNull(TextoCampo(qCab, 'Provincia', 200)),
           ValorOrNull(TextoCampo(qCab, 'CodPostal', 15)),
           ValorOrNull(sNombre), ValorOrNull(TextoCampo(qCab, 'Telefono1', 40)),
           ValorOrNull(TextoCampo(qCab, 'Direccion1', 200)),
           ValorOrNull(TextoCampo(qCab, 'Direccion2', 200)),
           ValorOrNull(TextoCampo(qCab, 'Poblacion', 200)),
           ValorOrNull(TextoCampo(qCab, 'Provincia', 200)),
           ValorOrNull(TextoCampo(qCab, 'CodPostal', 15)),
           ValorOrNull(TextoCampo(qCab, 'FormaEnvio', 200)),
           ValorOrNull(CodigoTarifaVentaMayor(qCab)),
           F(iva.Pn), F(iva.Tn), F(iva.Pr), F(iva.Tr),
           F(iva.Ps), F(iva.Ts), F(iva.Pe), F(iva.Te),
           F(iva.Bases), F(iva.Impuestos), F(fTotal),
           ValorOrNull(CodigoFormaPagoVentaMayor(qCab)),
           ValorOrNull(TextoCampo(qCab, 'ObsAlbaran', 1000)),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('albaran_venta', sSerie + '/' + sNum, E.Message, '',
            'requiere Empresas/Clientes migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
  end;
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_albaranes_lineas', cColsLin,
                             BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  venta mayor albaranes 2/2: lineas (ocalbcliart)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocalbcliart'));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de albaran venta...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qLin.FieldByName('Ejercicio').AsInteger,
                                qLin.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qLin.FieldByName('NroAlbaran').AsInteger);
      sLinea := LineaDocumento(qLin.FieldByName('Orden').AsInteger);
      sArt := TextoCampo(qLin, 'Articulo', 20);
      sSku := ConstruirCodigoUnidad(sArt, TextoCampo(qLin, 'DescColor', 25),
                                    TextoCampo(qLin, 'Talla', 7));
      sAlm := UpperCase(TextoCampo(qLin, 'AbrevAlmLin', 10));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      if qLin.FieldByName('NroPedido').AsInteger > 0 then
      begin
        sNumPed := ValorOrNull(NumeroDocumento(qLin.FieldByName('NroPedido').AsInteger));
        sSeriePed := ValorOrNull(SerieDocumento(qLin.FieldByName('EjercicioPedido').AsInteger,
                                                qLin.FieldByName('SeriePedido').AsString));
        sLineaPed := ValorOrNull(LineaPedido(qLin.FieldByName('OrdenPedido').AsInteger));
      end
      else
      begin
        sNumPed := 'NULL';
        sSeriePed := 'NULL';
        sLineaPed := 'NULL';
      end;
      if qLin.FieldByName('NroFactura').AsInteger > 0 then
      begin
        sFacturada := 'S';
        sNumFac := ValorOrNull(NumeroDocumento(qLin.FieldByName('NroFactura').AsInteger));
        sSerieFac := ValorOrNull(SerieDocumento(qLin.FieldByName('EjercicioFactura').AsInteger,
                                                qLin.FieldByName('SerieFactura').AsString));
        sLineaFac := ValorOrNull(sLinea);
      end
      else
      begin
        sFacturada := 'N';
        sNumFac := 'NULL';
        sSerieFac := 'NULL';
        sLineaFac := 'NULL';
      end;
      try
        bLin.Add(Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie), ValorOrNull(sLinea),
           sNumPed, sSeriePed, sLineaPed, ValorOrNull(sArt),
           ValorOrNull(TextoCampo(qLin, 'Descripcion', 100)),
           ValorOrNull(TipoIvaArticulo(qLin.FieldByName('PorIVA').AsFloat)),
           F(qLin.FieldByName('PorIVA').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat), ValorOrNull(sAlm),
           ValorOrNull(sFacturada), sNumFac, sSerieFac, sLineaFac, ValorOrNull(sSku),
           ValorOrNull(TextoCampo(qLin, 'DescColor', 25) + '/' +
                       TextoCampo(qLin, 'Talla', 7)),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('albaran_venta_linea', sSerie + '/' + sNum, E.Message,
            Format('linea=%s', [sLinea]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
  finally
    bLin.Free;
    qLin.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaVentaMayor(Eng, 'fza_albaranes', 'ALB');
    EnlazarClienteAlbaranVenta(Eng);
    Eng.Log('  albaranes venta mayor: empresa y flags de cliente rellenados.');
  end;
end;

// =========================================================================
//  3. Facturas de venta mayor
// =========================================================================

procedure MigrarFacturasVentaMayor(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelCab =
    'SELECT f.Empresa, f.Ejercicio, ISNULL(f.Serie, '''') AS Serie, f.NroFactura, ' +
    '       f.Fecha, ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ISNULL(f.Almacen, 0) AS Almacen, ' +
    '       ISNULL(f.Cliente, '''') AS Cliente, ISNULL(f.Nombre, '''') AS Nombre, ' +
    '       ISNULL(f.RazonSocial, '''') AS RazonSocial, ISNULL(f.NIF, '''') AS NIF, ' +
    '       ISNULL(f.Telefono1, '''') AS Telefono1, ISNULL(f.Direccion1, '''') AS Direccion1, ' +
    '       ISNULL(f.Direccion2, '''') AS Direccion2, ISNULL(f.Poblacion, '''') AS Poblacion, ' +
    '       ISNULL(f.Provincia, '''') AS Provincia, ISNULL(f.CodPostal, '''') AS CodPostal, ' +
    '       ISNULL(f.TipoEfecto, 0) AS TipoEfecto, ISNULL(f.FormaPago, '''') AS FormaPago, ' +
    '       ISNULL(f.Tarifa, 0) AS Tarifa, ISNULL(f.Vendedor, 0) AS Vendedor, ' +
    '       ISNULL(f.PorRetencion, 0) AS PorRetencion, ISNULL(f.ImpRetencion, 0) AS ImpRetencion, ' +
    '       ISNULL(f.NroAbono, 0) AS NroAbono, ISNULL(f.NroFraRctva, 0) AS NroFraRctva, ' +
    '       ISNULL(f.Caja, 0) AS Caja, ISNULL(f.Operacion, 0) AS Operacion, ' +
    '       ISNULL(f.ImpBaseImp1, 0) AS ImpBaseImp1, ISNULL(f.PorIVA1, 0) AS PorIVA1, ' +
    '       ISNULL(f.PorRE1, 0) AS PorRE1, ISNULL(f.CuotaIVA1, 0) AS CuotaIVA1, ' +
    '       ISNULL(f.CuotaRE1, 0) AS CuotaRE1, ISNULL(f.ImpBaseImp2, 0) AS ImpBaseImp2, ' +
    '       ISNULL(f.PorIVA2, 0) AS PorIVA2, ISNULL(f.PorRE2, 0) AS PorRE2, ' +
    '       ISNULL(f.CuotaIVA2, 0) AS CuotaIVA2, ISNULL(f.CuotaRE2, 0) AS CuotaRE2, ' +
    '       ISNULL(f.ImpBaseImp3, 0) AS ImpBaseImp3, ISNULL(f.PorIVA3, 0) AS PorIVA3, ' +
    '       ISNULL(f.PorRE3, 0) AS PorRE3, ISNULL(f.CuotaIVA3, 0) AS CuotaIVA3, ' +
    '       ISNULL(f.CuotaRE3, 0) AS CuotaRE3, ISNULL(f.ImpBaseImp4, 0) AS ImpBaseImp4, ' +
    '       ISNULL(f.PorIVA4, 0) AS PorIVA4, ISNULL(f.PorRE4, 0) AS PorRE4, ' +
    '       ISNULL(f.CuotaIVA4, 0) AS CuotaIVA4, ISNULL(f.CuotaRE4, 0) AS CuotaRE4, ' +
    '       ISNULL(f.ImpBaseImp, 0) AS ImpBaseImp, ISNULL(f.ImpFactura, 0) AS ImpFactura, ' +
    '       ISNULL(f.ImpLiquido, 0) AS ImpLiquido, CONVERT(varchar(2000), f.ObsFactura) AS ObsFactura ' +
    'FROM dbo.ocfaccli f ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = f.Empresa ' +
    '                       AND alm.Almacen = f.Almacen';
  cSelLin =
    'SELECT l.Empresa, l.Ejercicio, ISNULL(l.Serie, '''') AS Serie, l.NroFactura, ' +
    '       l.Orden, l.Articulo, l.Color, l.Talla, ISNULL(alml.Abreviatura, '''') AS AbrevAlmLin, ' +
    '       l.Almacen AS AlmLin, ISNULL(l.Descripcion, '''') AS Descripcion, ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       ISNULL(l.PrecioSIva, 0) AS PrecioSIva, ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.PorDto, 0) AS PorDto, ISNULL(l.ImpNetoCIva, 0) AS ImpNetoCIva, ' +
    '       ISNULL(l.ImpNetoSIva, 0) AS ImpNetoSIva, ISNULL(l.PorIVA, 0) AS PorIVA, ' +
    '       ISNULL(l.NumeroMovArt, 0) AS NumeroMovArt, CASE ' +
    '         WHEN l.Color IS NOT NULL AND LTRIM(RTRIM(l.Color)) <> '''' THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         WHEN co.Descripcion IS NOT NULL AND UPPER(LTRIM(RTRIM(co.Descripcion))) <> ''INDEFINIDO'' THEN UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '         ELSE ''0'' END AS DescColor ' +
    'FROM dbo.ocfaccliart l ' +
    'LEFT JOIN dbo.ocalm alml ON alml.Empresa = l.Empresa ' +
    '                        AND alml.Almacen = l.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico';
  cColsFac =
    'NUMERO_FAC, SERIE_FAC, FECHA_FAC, ESCONSOLIDADA_FAC, TIPO_FAC, ' +
    'ESMUEVE_STOCK_FAC, CODIGO_EMP_FAC, CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, ' +
    'NIF_CLIENTE_FAC, MOVIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
    'POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, CODIGO_POSTAL_CLIENTE_FAC, ' +
    'TARIFA_ARTICULO_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
    'PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, TOTAL_REN_FAC, ' +
    'TOTAL_BASEI_IVAN_FAC, PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, ' +
    'PORCENTAJE_RER_FAC, TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
    'PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, TOTAL_RES_FAC, ' +
    'TOTAL_BASEI_IVAS_FAC, PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, ' +
    'PORCENTAJE_REE_FAC, TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
    'TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, FORMA_PAGO_FAC, ' +
    'PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC, TOTAL_LIQUIDO_FAC, ' +
    'COMENTARIOS_FAC, ESCREARARTICULOS_FAC, ESDESCRIPCIONES_AMP_FAC, ' +
    'ESFECHADEENTREGA_FAC, CODIGO_CAJERO_FAC, CODIGO_ALM_FAC, CODIGO_CAJA_FAC, ' +
    'NUMERO_OPERACION_FAC, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  cColsLin =
    'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, TIPO_ARTICULO_FACLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_FACLIN, CANTIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'DESCRIPCION_VARIACION_FACLIN, ESIMP_INCL_TARIFA_FACLIN, PORCENTAJE_DTO_FACLIN, ' +
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN, TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, TOTAL_FAC_SIVA_FACLIN, ' +
    'CODIGO_ALM_FACLIN, NUMERO_MOV_FACLIN, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF';
var
  qCab, qLin: TUniQuery;
  bCab, bLin: TBulkInsert;
  sAhora, sUser, sSerie, sNum, sCli, sNombre, sAlm, sCaja, sOpe: string;
  sArt, sSku, sLinea, sMov, sVariacion: string;
  iva: TIvaVentaMayor;
  fTotal: Double;
begin
  LimpiarFacturasVentaMayor(Eng);
  sAhora := DateTimeASQL(Now);
  sUser := ValorOrNull(Eng.Usuario);
  bCab := TBulkInsert.Create(Eng.ConDst, 'fza_facturas', cColsFac, BATCH);
  qCab := NuevoQOrigen(Eng, cSelCab);
  qCab.UniDirectional := True;
  try
    Eng.Log('  venta mayor facturas 1/2: cabeceras (ocfaccli)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocfaccli'));
    qCab.Open;
    while not qCab.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en facturas de venta mayor...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qCab.FieldByName('Ejercicio').AsInteger,
                                qCab.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qCab.FieldByName('NroFactura').AsInteger);
      sCli := TextoCampo(qCab, 'Cliente', 20);
      sNombre := NombreClienteDocumento(qCab);
      sAlm := UpperCase(TextoCampo(qCab, 'AbrevAlm', 10));
      if sAlm = '' then
        sAlm := IntToStr(qCab.FieldByName('Almacen').AsInteger);
      sCaja := '';
      if qCab.FieldByName('Caja').AsInteger > 0 then
        sCaja := IntToStr(qCab.FieldByName('Caja').AsInteger);
      sOpe := '';
      if qCab.FieldByName('Operacion').AsInteger > 0 then
        sOpe := Format('%.8d', [qCab.FieldByName('Operacion').AsInteger]);
      CalcularIvaVentaMayor(qCab, iva);
      fTotal := qCab.FieldByName('ImpLiquido').AsFloat;
      if fTotal = 0 then
        fTotal := qCab.FieldByName('ImpFactura').AsFloat;
      try
        bCab.Add(Format(
          '%s, %s, %s, ''S'', %s, ''N'', %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, ''N'', %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, ''N'', ''N'', ''N'', %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie), FechaCampoASQL(qCab, 'Fecha'),
           ValorOrNull(TipoFacturaVentaMayor(qCab)),
           ValorOrNull(IntToStr(qCab.FieldByName('Empresa').AsInteger)),
           ValorOrNull(sCli), ValorOrNull(sNombre),
           ValorOrNull(TextoCampo(qCab, 'NIF', 50)),
           ValorOrNull(TextoCampo(qCab, 'Telefono1', 40)),
           ValorOrNull(TextoCampo(qCab, 'Direccion1', 200)),
           ValorOrNull(TextoCampo(qCab, 'Direccion2', 200)),
           ValorOrNull(TextoCampo(qCab, 'Poblacion', 200)),
           ValorOrNull(TextoCampo(qCab, 'Provincia', 200)),
           ValorOrNull(TextoCampo(qCab, 'CodPostal', 15)),
           ValorOrNull(CodigoTarifaVentaMayor(qCab)),
           F(iva.Pn), F(iva.Tn), F(iva.Rn), F(iva.Trn), F(iva.Bn),
           F(iva.Pr), F(iva.Tr), F(iva.Rr), F(iva.Trr), F(iva.Br),
           F(iva.Ps), F(iva.Ts), F(iva.Rs), F(iva.Trs), F(iva.Bs),
           F(iva.Pe), F(iva.Te), F(iva.Re), F(iva.Tre), F(iva.Be),
           F(iva.Bases), F(iva.Impuestos),
           ValorOrNull(CodigoFormaPagoVentaMayor(qCab)),
           F(qCab.FieldByName('PorRetencion').AsFloat),
           F(qCab.FieldByName('ImpRetencion').AsFloat), F(fTotal),
           ValorOrNull(TextoCampo(qCab, 'ObsFactura', 1000)),
           ValorOrNull(IntToStr(qCab.FieldByName('Vendedor').AsInteger)),
           ValorOrNull(sAlm), ValorOrNull(sCaja), ValorOrNull(sOpe),
           sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('factura_venta_mayor', sSerie + '/' + sNum, E.Message,
            '', 'requiere Empresas/Clientes migrados');
        end;
      end;
      qCab.Next;
    end;
    bCab.FlushPendiente;
  finally
    bCab.Free;
    qCab.Free;
  end;
  bLin := TBulkInsert.Create(Eng.ConDst, 'fza_facturas_lineas', cColsLin,
                             BATCH);
  qLin := NuevoQOrigen(Eng, cSelLin);
  qLin.UniDirectional := True;
  try
    Eng.Log('  venta mayor facturas 2/2: lineas (ocfaccliart)...');
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocfaccliart'));
    qLin.Open;
    while not qLin.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en lineas de factura venta mayor...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sSerie := SerieDocumento(qLin.FieldByName('Ejercicio').AsInteger,
                                qLin.FieldByName('Serie').AsString);
      sNum := NumeroDocumento(qLin.FieldByName('NroFactura').AsInteger);
      sLinea := LineaDocumento(qLin.FieldByName('Orden').AsInteger);
      sArt := TextoCampo(qLin, 'Articulo', 20);
      sSku := ConstruirCodigoUnidad(sArt, TextoCampo(qLin, 'DescColor', 25),
                                    TextoCampo(qLin, 'Talla', 7));
      sAlm := UpperCase(TextoCampo(qLin, 'AbrevAlmLin', 10));
      if sAlm = '' then
        sAlm := IntToStr(qLin.FieldByName('AlmLin').AsInteger);
      sMov := CodigoMovimientoVenta(qLin);
      sVariacion := TextoCampo(qLin, 'DescColor', 25) + '/' +
                    TextoCampo(qLin, 'Talla', 7);
      try
        bLin.Add(Format(
          '%s, %s, %s, %s, %s, %s, ''ESTANDAR'', ''Uds'', %s, %s, %s, ' +
          '''N'', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',
          [ValorOrNull(sNum), ValorOrNull(sSerie),
           ValorOrNull(IntToStr(qLin.FieldByName('Empresa').AsInteger)),
           ValorOrNull(sLinea), ValorOrNull(sArt), ValorOrNull(sSku),
           F(qLin.FieldByName('Cantidad').AsFloat),
           ValorOrNull(TextoCampo(qLin, 'Descripcion', 100)),
           ValorOrNull(sVariacion), F(qLin.FieldByName('PorDto').AsFloat),
           F(qLin.FieldByName('PrecioSIva').AsFloat),
           ValorOrNull(TipoIvaArticulo(qLin.FieldByName('PorIVA').AsFloat)),
           F(qLin.FieldByName('PorIVA').AsFloat),
           F(qLin.FieldByName('PrecioCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoCIva').AsFloat),
           F(qLin.FieldByName('ImpNetoSIva').AsFloat), ValorOrNull(sAlm),
           ValorOrNull(sMov), sAhora, sAhora, sUser, sUser]));
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('factura_venta_mayor_linea', sSerie + '/' + sNum,
            E.Message, Format('linea=%s', [sLinea]), '');
        end;
      end;
      qLin.Next;
    end;
    bLin.FlushPendiente;
  finally
    bLin.Free;
    qLin.Free;
  end;
  if not Eng.IsCancelado then
  begin
    EnlazarEmpresaVentaMayor(Eng, 'fza_facturas', 'FAC');
    EnlazarClientesVentaMayor(Eng, 'fza_facturas', 'FAC');
    AjustarRetencionesVentaMayor(Eng, 'fza_facturas', 'FAC');
    EnlazarLineasFacturaVentaMayor(Eng);
    Eng.Log('  facturas venta mayor: empresa, cliente y movimientos enlazados.');
  end;
end;

initialization
  fsVentasMayor := TFormatSettings.Create('en-US');

end.
