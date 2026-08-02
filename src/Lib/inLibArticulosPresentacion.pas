{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosPresentacion                                    }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones de la pantalla de articulos que no necesitan VCL ni BBDD:      }
{    estado del filtro de carga, verificacion de codigos de barras, lista de   }
{    SKU del alta de tarifas, etiquetas de origen y color hexadecimal.         }
{******************************************************************************}
unit inLibArticulosPresentacion;

interface

uses
  inLibArticulosFiltro,
  inLibArticulosPresentacionIntf;

type
  // Recuento de la verificacion de codigos de barras de un articulo.
  TResumenCodigosBarrasArticulo = record
    Ean13Correctos: Integer;
    Ean8Correctos: Integer;
    Invalidos: Integer;
    Omitidos: Integer;
    DetalleErrores: string;
  end;

// Traduccion entre el indice del combo de estado y el codigo de perfil.
function IndiceEstadoFiltroDesdeCodigo(const ACodigo: string): Integer;
function CodigoEstadoFiltroDesdeIndice(AIndice: Integer): string;
function EstadoFiltroArticulosDesdeIndice(
  AIndice: Integer): TEstadoFiltroArticulos;
// CSV con ';' de los valores marcados, en el orden recibido.
function ComponerCsvSeleccion(const AValores: TArray<string>): string;
// Recuento y detalle de los codigos de barras de un articulo.
function VerificarCodigosBarrasArticulo(
  const ACodigos: TCodigosBarrasArticulo): TResumenCodigosBarrasArticulo;
// Lista que ve el modal de alta de precios: la fila del articulo primero.
function ComponerListaSkusAltaTarifa(
  const ASkus: TArray<string>): TArray<string>;
// Texto visible de FUENTE_ATB ('A', 'C', 'G').
function EtiquetaFuenteAtributoBasico(const ACodigo: string): string;
// '#RRGGBB' -> componentes. False si el texto no es un hex valido.
function DescomponerHexAtributo(const AHex: string;
  out ARojo, AVerde, AAzul: Integer): Boolean;
function ComponerHexAtributo(ARojo, AVerde, AAzul: Integer): string;
// Luminancia percibida por debajo del umbral de texto blanco.
function EsColorOscuroAtributo(ARojo, AVerde, AAzul: Integer): Boolean;

implementation

uses
  System.SysUtils,
  inLibEAN13,
  inLibArticulosAltaTarifas,
  inLibMsgArticulos;

const
  // Prefijo de los codigos provisionales pendientes de rellenar.
  PREFIJO_CODIGO_PENDIENTE = '_FAB_';
  LONGITUD_HEX = 7;
  UMBRAL_LUMINANCIA_OSCURA = 128;

function IndiceEstadoFiltroDesdeCodigo(const ACodigo: string): Integer;
begin
  if SameText(ACodigo, 'T') then
    Result := 0
  else if SameText(ACodigo, 'N') then
    Result := 2
  else
    // 'S' o cualquier valor desconocido: solo activos.
    Result := 1;
end;

function CodigoEstadoFiltroDesdeIndice(AIndice: Integer): string;
begin
  case AIndice of
    0:
      Result := 'T';
    2:
      Result := 'N';
  else
    Result := 'S';
  end;
end;

function EstadoFiltroArticulosDesdeIndice(
  AIndice: Integer): TEstadoFiltroArticulos;
begin
  case AIndice of
    1:
      Result := efaActivos;
    2:
      Result := efaInactivos;
  else
    Result := efaTodos;
  end;
end;

function ComponerCsvSeleccion(const AValores: TArray<string>): string;
var
  iValor: Integer;
begin
  Result := '';
  for iValor := 0 to High(AValores) do
  begin
    if Result <> '' then
      Result := Result + ';';
    Result := Result + AValores[iValor];
  end;
end;

function VerificarCodigosBarrasArticulo(
  const ACodigos: TCodigosBarrasArticulo): TResumenCodigosBarrasArticulo;
var
  iFila: Integer;
  oFila: TCodigoBarrasSkuArticulo;
begin
  Result := Default(TResumenCodigosBarrasArticulo);
  for iFila := 0 to High(ACodigos) do
  begin
    oFila := ACodigos[iFila];
    // Los placeholders pendientes de rellenar no cuentan como error.
    if (oFila.Codigo = '') or
       (Pos(PREFIJO_CODIGO_PENDIENTE, oFila.Codigo) = 1) then
      Inc(Result.Omitidos)
    else if (Length(oFila.Codigo) = 13) and
            EsEAN13Valido(oFila.Codigo) then
      Inc(Result.Ean13Correctos)
    else if (Length(oFila.Codigo) = 8) and
            EsEAN8Valido(oFila.Codigo) then
      Inc(Result.Ean8Correctos)
    else
    begin
      Inc(Result.Invalidos);
      Result.DetalleErrores := Result.DetalleErrores + sLineBreak +
        Format(SErrorDetalleCodigoBarrasInvalido,
          [oFila.Codigo, oFila.Sku, oFila.Tipo, Length(oFila.Codigo)]);
    end;
  end;
end;

function ComponerListaSkusAltaTarifa(
  const ASkus: TArray<string>): TArray<string>;
var
  iSku: Integer;
  iDestino: Integer;
  sSku: string;
begin
  SetLength(Result, 1);
  // La fila del propio articulo siempre encabeza la lista del modal.
  Result[0] := cSkuFilaArticulo;
  for iSku := 0 to High(ASkus) do
  begin
    sSku := Trim(ASkus[iSku]);
    if sSku <> '' then
    begin
      iDestino := Length(Result);
      SetLength(Result, iDestino + 1);
      Result[iDestino] := sSku;
    end;
  end;
end;

function EtiquetaFuenteAtributoBasico(const ACodigo: string): string;
begin
  // 'A' = override por articulo, 'C' = conjunto del articulo, 'G' = global.
  if ACodigo = 'A' then
    Result := 'Artículo'
  else if ACodigo = 'C' then
    Result := 'Conjunto'
  else if ACodigo = 'G' then
    Result := 'Global'
  else
    Result := '';
end;

function DescomponerHexAtributo(const AHex: string;
  out ARojo, AVerde, AAzul: Integer): Boolean;
var
  sHex: string;
begin
  ARojo := 0;
  AVerde := 0;
  AAzul := 0;
  sHex := Trim(AHex);
  Result := (Length(sHex) = LONGITUD_HEX) and (sHex[1] = '#');
  if Result then
  begin
    try
      ARojo := StrToInt('$' + Copy(sHex, 2, 2));
      AVerde := StrToInt('$' + Copy(sHex, 4, 2));
      AAzul := StrToInt('$' + Copy(sHex, 6, 2));
    except
      on EConvertError do
        Result := False;
    end;
  end;
end;

function ComponerHexAtributo(ARojo, AVerde, AAzul: Integer): string;
begin
  Result := Format('#%.2X%.2X%.2X', [ARojo, AVerde, AAzul]);
end;

function EsColorOscuroAtributo(ARojo, AVerde, AAzul: Integer): Boolean;
var
  dLuminancia: Double;
begin
  dLuminancia := (ARojo * 0.299) + (AVerde * 0.587) + (AAzul * 0.114);
  Result := dLuminancia < UMBRAL_LUMINANCIA_OSCURA;
end;

end.
