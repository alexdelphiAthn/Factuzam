{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoFalso                                         }
{    Tipo:       Doble de prueba                                               }
{ Versión:       1.1.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación en memoria de IEscritorHojaCalculo e ILectorHojaCalculo.   }
{    Registra celdas (valor, estilo, formato, fondo, bordes), combinaciones,   }
{    cuadros y anchos para poder afirmar sobre ellos en las pruebas, sin       }
{    DevExpress ni UI. Oráculo de las pruebas de snapshot de los exportadores. }
{    v1.1 (Fase 2): cubre la superficie ampliada del puerto.                   }
{******************************************************************************}
unit inLibHojaCalculoFalso;

interface

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  inLibHojaCalculoIntf;

type
  TCeldaFalsa = record
    Valor: Variant;
    Negrita: Boolean;
    Alineacion: TAlineacionCelda;
    Formato: string;
    EsFormula: Boolean;
    Formula: string;
    TamFuente: Integer;
    Fondo: Cardinal;
    BordeSup: TEstiloBorde;
    BordeInf: TEstiloBorde;
    BordeIzq: TEstiloBorde;
    BordeDer: TEstiloBorde;
  end;
  TCombinacionFalsa = record
    Fila: Integer;
    Col: Integer;
    NumFilas: Integer;
    NumCols: Integer;
  end;
  TCuadroFalso = record
    F1: Integer;
    C1: Integer;
    F2: Integer;
    C2: Integer;
    Estilo: TEstiloBorde;
  end;
  TEscritorHojaCalculoFalso = class(TInterfacedObject,
    IEscritorHojaCalculo, ILectorHojaCalculo)
  private
    FCeldas: TDictionary<Int64, TCeldaFalsa>;
    FAnchos: TDictionary<Integer, Integer>;
    FCombinaciones: TList<TCombinacionFalsa>;
    FCuadros: TList<TCuadroFalso>;
    FRutaGuardada: string;
    FMaxFila: Integer;
    FMaxCol: Integer;
    FHojaActual: string;
    FNumHojas: Integer;
    FNivelLote: Integer;
    function Clave(AFila, ACol: Integer): Int64;
    function ObtenerCelda(AFila, ACol: Integer): TCeldaFalsa;
    procedure GuardarCelda(AFila, ACol: Integer; const ACelda: TCeldaFalsa);
  public
    constructor Create;
    destructor Destroy; override;
    // IEscritorHojaCalculo
    procedure NuevaHoja(const ANombre: string);
    procedure IniciarLote;
    procedure FinalizarLote;
    procedure Escribir(AFila, ACol: Integer; const AValor: Variant;
      ANegrita: Boolean = False;
      AAlineacion: TAlineacionCelda = acIzquierda;
      const AFormato: string = '');
    procedure EscribirFormula(AFila, ACol: Integer; const AFormula: string;
      const AFormato: string = '');
    procedure Combinar(AFila, ACol, ANumFilas, ANumCols: Integer);
    procedure DibujarCuadro(AF1, AC1, AF2, AC2: Integer;
      AEstilo: TEstiloBorde);
    procedure BordeCelda(AFila, ACol: Integer; ALado: TLadoBorde;
      AEstilo: TEstiloBorde);
    procedure FondoCelda(AFila, ACol: Integer; AColor: Cardinal);
    procedure Negrita(AFila, ACol: Integer; AActivar: Boolean = True);
    procedure TamanoFuente(AFila, ACol: Integer; ATamano: Integer);
    procedure AnchoColumna(ACol: Integer; AAncho: Integer);
    function CeldaExiste(AFila, ACol: Integer): Boolean;
    procedure Guardar(const ARuta: string);
    // ILectorHojaCalculo
    function LeerCelda(AFila, ACol: Integer): Variant;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
    // Consultas para pruebas
    function TieneCelda(AFila, ACol: Integer): Boolean;
    function Valor(AFila, ACol: Integer): Variant;
    function EsNegrita(AFila, ACol: Integer): Boolean;
    function Alineacion(AFila, ACol: Integer): TAlineacionCelda;
    function Formato(AFila, ACol: Integer): string;
    function EsFormula(AFila, ACol: Integer): Boolean;
    function Formula(AFila, ACol: Integer): string;
    function TamFuente(AFila, ACol: Integer): Integer;
    function Fondo(AFila, ACol: Integer): Cardinal;
    function Borde(AFila, ACol: Integer; ALado: TLadoBorde): TEstiloBorde;
    function AnchoDe(ACol: Integer): Integer;
    function NumCombinaciones: Integer;
    function NumCuadros: Integer;
    function RutaGuardada: string;
    function HojaActual: string;
    function NumHojas: Integer;
    procedure Precargar(AFila, ACol: Integer; const AValor: Variant);
  end;

implementation

constructor TEscritorHojaCalculoFalso.Create;
begin
  inherited Create;
  FCeldas := TDictionary<Int64, TCeldaFalsa>.Create;
  FAnchos := TDictionary<Integer, Integer>.Create;
  FCombinaciones := TList<TCombinacionFalsa>.Create;
  FCuadros := TList<TCuadroFalso>.Create;
  FMaxFila := -1;
  FMaxCol := -1;
  FNumHojas := 0;
  FHojaActual := '';
  FNivelLote := 0;
end;

destructor TEscritorHojaCalculoFalso.Destroy;
begin
  FreeAndNil(FCuadros);
  FreeAndNil(FCombinaciones);
  FreeAndNil(FAnchos);
  FreeAndNil(FCeldas);
  inherited Destroy;
end;

function TEscritorHojaCalculoFalso.Clave(AFila, ACol: Integer): Int64;
begin
  Result := Int64(AFila) * 1000000 + ACol;
end;

function TEscritorHojaCalculoFalso.ObtenerCelda(
  AFila, ACol: Integer): TCeldaFalsa;
begin
  if not FCeldas.TryGetValue(Clave(AFila, ACol), Result) then
  begin
    Result.Valor := Null;
    Result.Negrita := False;
    Result.Alineacion := acIzquierda;
    Result.Formato := '';
    Result.EsFormula := False;
    Result.Formula := '';
    Result.TamFuente := 0;
    Result.Fondo := 0;
    Result.BordeSup := ebNinguno;
    Result.BordeInf := ebNinguno;
    Result.BordeIzq := ebNinguno;
    Result.BordeDer := ebNinguno;
  end;
end;

procedure TEscritorHojaCalculoFalso.GuardarCelda(AFila, ACol: Integer;
  const ACelda: TCeldaFalsa);
begin
  FCeldas.AddOrSetValue(Clave(AFila, ACol), ACelda);
  if AFila > FMaxFila then
    FMaxFila := AFila;
  if ACol > FMaxCol then
    FMaxCol := ACol;
end;

procedure TEscritorHojaCalculoFalso.NuevaHoja(const ANombre: string);
begin
  // Hoja fresca: se limpia lo registrado (modela un libro de una hoja).
  FCeldas.Clear;
  FCombinaciones.Clear;
  FCuadros.Clear;
  FAnchos.Clear;
  FMaxFila := -1;
  FMaxCol := -1;
  FHojaActual := ANombre;
  Inc(FNumHojas);
end;

procedure TEscritorHojaCalculoFalso.IniciarLote;
begin
  Inc(FNivelLote);
end;

procedure TEscritorHojaCalculoFalso.FinalizarLote;
begin
  if FNivelLote > 0 then
    Dec(FNivelLote);
end;

procedure TEscritorHojaCalculoFalso.Escribir(AFila, ACol: Integer;
  const AValor: Variant; ANegrita: Boolean; AAlineacion: TAlineacionCelda;
  const AFormato: string);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.Valor := AValor;
  oCelda.Negrita := ANegrita;
  oCelda.Alineacion := AAlineacion;
  oCelda.Formato := AFormato;
  oCelda.EsFormula := False;
  oCelda.Formula := '';
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.EscribirFormula(AFila, ACol: Integer;
  const AFormula: string; const AFormato: string);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.Valor := Null;
  oCelda.Alineacion := acDerecha;
  oCelda.Formato := AFormato;
  oCelda.EsFormula := True;
  oCelda.Formula := AFormula;
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.Combinar(AFila, ACol, ANumFilas,
  ANumCols: Integer);
var
  oComb: TCombinacionFalsa;
begin
  oComb.Fila := AFila;
  oComb.Col := ACol;
  oComb.NumFilas := ANumFilas;
  oComb.NumCols := ANumCols;
  FCombinaciones.Add(oComb);
end;

procedure TEscritorHojaCalculoFalso.DibujarCuadro(AF1, AC1, AF2,
  AC2: Integer; AEstilo: TEstiloBorde);
var
  oCuadro: TCuadroFalso;
begin
  oCuadro.F1 := AF1;
  oCuadro.C1 := AC1;
  oCuadro.F2 := AF2;
  oCuadro.C2 := AC2;
  oCuadro.Estilo := AEstilo;
  FCuadros.Add(oCuadro);
end;

procedure TEscritorHojaCalculoFalso.BordeCelda(AFila, ACol: Integer;
  ALado: TLadoBorde; AEstilo: TEstiloBorde);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  case ALado of
    lbSuperior:
      oCelda.BordeSup := AEstilo;
    lbInferior:
      oCelda.BordeInf := AEstilo;
    lbIzquierdo:
      oCelda.BordeIzq := AEstilo;
  else
    oCelda.BordeDer := AEstilo;
  end;
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.FondoCelda(AFila, ACol: Integer;
  AColor: Cardinal);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.Fondo := AColor;
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.Negrita(AFila, ACol: Integer;
  AActivar: Boolean);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.Negrita := AActivar;
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.TamanoFuente(AFila, ACol: Integer;
  ATamano: Integer);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.TamFuente := ATamano;
  GuardarCelda(AFila, ACol, oCelda);
end;

procedure TEscritorHojaCalculoFalso.AnchoColumna(ACol: Integer;
  AAncho: Integer);
begin
  FAnchos.AddOrSetValue(ACol, AAncho);
end;

function TEscritorHojaCalculoFalso.CeldaExiste(AFila, ACol: Integer): Boolean;
begin
  Result := FCeldas.ContainsKey(Clave(AFila, ACol));
end;

procedure TEscritorHojaCalculoFalso.Guardar(const ARuta: string);
begin
  FRutaGuardada := ARuta;
end;

function TEscritorHojaCalculoFalso.LeerCelda(AFila, ACol: Integer): Variant;
begin
  Result := ObtenerCelda(AFila, ACol).Valor;
end;

function TEscritorHojaCalculoFalso.UltimaFila: Integer;
begin
  Result := FMaxFila;
end;

function TEscritorHojaCalculoFalso.UltimaColumna: Integer;
begin
  Result := FMaxCol;
end;

function TEscritorHojaCalculoFalso.TieneCelda(AFila, ACol: Integer): Boolean;
begin
  Result := FCeldas.ContainsKey(Clave(AFila, ACol));
end;

function TEscritorHojaCalculoFalso.Valor(AFila, ACol: Integer): Variant;
begin
  Result := ObtenerCelda(AFila, ACol).Valor;
end;

function TEscritorHojaCalculoFalso.EsNegrita(AFila, ACol: Integer): Boolean;
begin
  Result := ObtenerCelda(AFila, ACol).Negrita;
end;

function TEscritorHojaCalculoFalso.Alineacion(
  AFila, ACol: Integer): TAlineacionCelda;
begin
  Result := ObtenerCelda(AFila, ACol).Alineacion;
end;

function TEscritorHojaCalculoFalso.Formato(AFila, ACol: Integer): string;
begin
  Result := ObtenerCelda(AFila, ACol).Formato;
end;

function TEscritorHojaCalculoFalso.EsFormula(AFila, ACol: Integer): Boolean;
begin
  Result := ObtenerCelda(AFila, ACol).EsFormula;
end;

function TEscritorHojaCalculoFalso.Formula(AFila, ACol: Integer): string;
begin
  Result := ObtenerCelda(AFila, ACol).Formula;
end;

function TEscritorHojaCalculoFalso.TamFuente(AFila, ACol: Integer): Integer;
begin
  Result := ObtenerCelda(AFila, ACol).TamFuente;
end;

function TEscritorHojaCalculoFalso.Fondo(AFila, ACol: Integer): Cardinal;
begin
  Result := ObtenerCelda(AFila, ACol).Fondo;
end;

function TEscritorHojaCalculoFalso.Borde(AFila, ACol: Integer;
  ALado: TLadoBorde): TEstiloBorde;
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  case ALado of
    lbSuperior:
      Result := oCelda.BordeSup;
    lbInferior:
      Result := oCelda.BordeInf;
    lbIzquierdo:
      Result := oCelda.BordeIzq;
  else
    Result := oCelda.BordeDer;
  end;
end;

function TEscritorHojaCalculoFalso.AnchoDe(ACol: Integer): Integer;
begin
  if not FAnchos.TryGetValue(ACol, Result) then
    Result := 0;
end;

function TEscritorHojaCalculoFalso.NumCombinaciones: Integer;
begin
  Result := FCombinaciones.Count;
end;

function TEscritorHojaCalculoFalso.NumCuadros: Integer;
begin
  Result := FCuadros.Count;
end;

function TEscritorHojaCalculoFalso.RutaGuardada: string;
begin
  Result := FRutaGuardada;
end;

function TEscritorHojaCalculoFalso.HojaActual: string;
begin
  Result := FHojaActual;
end;

function TEscritorHojaCalculoFalso.NumHojas: Integer;
begin
  Result := FNumHojas;
end;

procedure TEscritorHojaCalculoFalso.Precargar(AFila, ACol: Integer;
  const AValor: Variant);
var
  oCelda: TCeldaFalsa;
begin
  oCelda := ObtenerCelda(AFila, ACol);
  oCelda.Valor := AValor;
  GuardarCelda(AFila, ACol, oCelda);
end;

end.
