{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteVentaCalculo                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculo puro del pivote de venta (fascículo V1 del anexo SRP): claves     }
{    de grupo y celda, líneas de vista por banda, pendientes, ajuste de        }
{    "a albaranar" y rótulos de banda/tipo de cantidad. Sin VCL, sin           }
{    DevExpress, sin UniDAC y sin datasets: todo probable con DUnitX.          }
{******************************************************************************}
unit inLibPivoteVentaCalculo;

interface

uses
  System.SysUtils;

type
  // Banda visual de un grupo del pivote: Pedido / A albaranar /
  // Pendiente. En documentos de banda única solo se usa bpvPedida.
  TBandaPivoteVenta = (bpvPedida, bpvEntregada, bpvPendiente);

const
  // Id de atributo talla reservado para la celda "sin talla" del grupo.
  ID_AV_SIN_TALLA_PIVOTE = 0;
  // Multiplicador de la clave de celda: linea base * base + id talla.
  BASE_CLAVE_CELDA_PIVOTE = 100000;

// Clave del grupo artículo+color+precio. Una línea sin talla resoluble
// recibe fila propia (sufijo '|L'+línea): fusionarla machacaría varias
// líneas sin SKU del mismo artículo en la celda 'Cantidad'.
function ClaveGrupoPivoteVenta(const AArticulo: string;
                               AColorAv: Integer; APrecio: Double;
                               ATallaAv: Integer;
                               const ALinea: string): string;
// Clave de celda del pivote (linea base, id de talla).
function ClaveCeldaPivoteVenta(ALineaBase, AIdAv: Int64): Int64;
function LineaBaseDesdeClaveCelda(AClave: Int64): Integer;
function TallaAvDesdeClaveCelda(AClave: Int64): Integer;
// Línea "de vista" que representa a un grupo en una banda concreta.
function LineaVistaBandaPivoteVenta(ALineaBase: Integer;
                                    ABanda: TBandaPivoteVenta): Integer;
// Clave estable de un conjunto virtual por lista de tallas: dos grupos
// con las mismas tallas comparten conjunto y captions.
function ClaveConjuntoVirtualPivoteVenta(
  const AIdsTalla: TArray<Integer>): string;
// Pendiente base = pedida - entregada, nunca negativo.
function PendienteBasePivoteVenta(APedida, AEntregada: Double): Double;
// Pendiente visual = pendiente base - a albaranar, nunca negativo.
function PendientePivoteVenta(APedida, AEntregada,
                              AAAlbaranar: Double): Double;
// Normaliza "a albaranar" al rango [0..pendiente base]. Un resultado
// cero deja la celda sin cantidad de servicio (equivale a la retirada
// de la caché de a-albaranar del monolito).
function AjustarAAlbaranarPivoteVenta(APedida, AEntregada,
                                      AAAlbaranar: Double): Double;
function EsTipoCantidadPredeterminadoPivote(
  const AValor: string): Boolean;
function TextoBandaPivoteVenta(ABanda: TBandaPivoteVenta;
                               ABandaUnica: Boolean;
                               const ATextoAAlbaranar: string): string;
function TextoTipoCantidadPivoteVenta(const ATipoCantidad: string;
                                      ABanda: TBandaPivoteVenta;
                                      ABandaUnica: Boolean;
                                      const ATextoAAlbaranar: string)
                                      : string;
// Prefijo artículo/color de un SKU compuesto ART/COLOR/TALLA.
function PrefijoSkuTallaPivoteVenta(const ASku: string): string;

implementation

function ClaveGrupoPivoteVenta(const AArticulo: string;
  AColorAv: Integer; APrecio: Double; ATallaAv: Integer;
  const ALinea: string): string;
begin
  Result := AArticulo + '|' + IntToStr(AColorAv) + '|' +
    FloatToStrF(APrecio, ffGeneral, 15, 4);
  if ATallaAv <= 0 then
    Result := Result + '|L' + ALinea;
end;

function ClaveCeldaPivoteVenta(ALineaBase, AIdAv: Int64): Int64;
begin
  Result := (ALineaBase * BASE_CLAVE_CELDA_PIVOTE) + AIdAv;
end;

function LineaBaseDesdeClaveCelda(AClave: Int64): Integer;
begin
  Result := Integer(AClave div BASE_CLAVE_CELDA_PIVOTE);
end;

function TallaAvDesdeClaveCelda(AClave: Int64): Integer;
begin
  Result := Integer(AClave mod BASE_CLAVE_CELDA_PIVOTE);
end;

function LineaVistaBandaPivoteVenta(ALineaBase: Integer;
  ABanda: TBandaPivoteVenta): Integer;
begin
  Result := (ALineaBase * 10) + Ord(ABanda);
end;

function ClaveConjuntoVirtualPivoteVenta(
  const AIdsTalla: TArray<Integer>): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(AIdsTalla) do
    Result := Result + IntToStr(AIdsTalla[i]) + ',';
end;

function PendienteBasePivoteVenta(APedida, AEntregada: Double): Double;
begin
  Result := APedida - AEntregada;
  if Result < 0 then
    Result := 0;
end;

function PendientePivoteVenta(APedida, AEntregada,
  AAAlbaranar: Double): Double;
begin
  Result := PendienteBasePivoteVenta(APedida, AEntregada) - AAAlbaranar;
  if Result < 0 then
    Result := 0;
end;

function AjustarAAlbaranarPivoteVenta(APedida, AEntregada,
  AAAlbaranar: Double): Double;
var
  rMax: Double;
begin
  Result := AAAlbaranar;
  rMax := PendienteBasePivoteVenta(APedida, AEntregada);
  if Result > rMax then
    Result := rMax;
  if Result < 0 then
    Result := 0;
end;

function EsTipoCantidadPredeterminadoPivote(
  const AValor: string): Boolean;
var
  sValor: string;
begin
  sValor := Trim(AValor);
  Result := (sValor = '') or SameText(sValor, 'Uds') or
            SameText(sValor, 'Ud') or SameText(sValor, 'Unidad') or
            SameText(sValor, 'Unidades') or SameText(sValor, 'Cantidad');
end;

function TextoBandaPivoteVenta(ABanda: TBandaPivoteVenta;
  ABandaUnica: Boolean; const ATextoAAlbaranar: string): string;
begin
  if ABandaUnica then
    Result := 'Cantidad'
  else
    case ABanda of
      bpvPedida:
        Result := 'Pedido';
      bpvEntregada:
        begin
          Result := ATextoAAlbaranar;
          if Result = '' then
            Result := 'A albaranar';
        end;
    else
      Result := 'Pendiente';
    end;
end;

function TextoTipoCantidadPivoteVenta(const ATipoCantidad: string;
  ABanda: TBandaPivoteVenta; ABandaUnica: Boolean;
  const ATextoAAlbaranar: string): string;
var
  sTipoCantidad: string;
begin
  sTipoCantidad := ATipoCantidad;
  if sTipoCantidad = '' then
    sTipoCantidad := 'Uds';
  if ABandaUnica then
    Result := sTipoCantidad
  else
  begin
    Result := TextoBandaPivoteVenta(ABanda, ABandaUnica,
                                    ATextoAAlbaranar);
    if not EsTipoCantidadPredeterminadoPivote(sTipoCantidad) then
      Result := Result + ' - ' + sTipoCantidad;
  end;
end;

function PrefijoSkuTallaPivoteVenta(const ASku: string): string;
var
  iPos: Integer;
begin
  Result := '';
  iPos := LastDelimiter('/', ASku);
  if iPos > 1 then
    Result := Copy(ASku, 1, iPos - 1);
end;

end.
