{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMovVentasArtExcel                                        }
{    Tipo:       Librería                                                      }
{ Versión:       3.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel del informe "Movimientos de ventas por artículos y    }
{    fechas". Una fila por artículo/color cuando hay color, con las magnitudes }
{    periodo y los dos márgenes. Si el SP devuelve agrupaciones (GRUPO1..3),   }
{    dibuja una cabecera por grupo y una línea de TOTAL por corte (sumas de    }
{    las magnitudes base y porcentajes/márgenes recalculados a partir de esas  }
{    sumas, no sumando porcentajes).                                           }
{                                                                              }
{    v3.0 (Fase 4): recibe por separado escritura y formato; no depende del    }
{    guardado del libro ni de DevExpress. Ver                                  }
{    desacoplar_excel_hojacalculo.md.                                          }
{                                                                              }
{    Consume el resultado de PRC_GET_MOV_VENTAS_ART (mismo dataset filtrado    }
{    que alimenta el informe FastReport).                                      }
{******************************************************************************}
unit inLibMovVentasArtExcel;

interface

uses
  System.SysUtils, System.Variants, Data.DB, inLibHojaCalculoIntf;

procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet);

implementation

const
  COL_ART     = 0;                 // artículo (código + descripción)
  COL_UNIENT  = 1;
  COL_IMPENT  = 2;
  COL_UDSVTA  = 3;
  COL_IMPVTA  = 4;
  COL_IMPCOS  = 5;
  COL_BENEF   = 6;
  COL_PCTBNF  = 7;
  COL_VTAENT  = 8;
  COL_VENTENT = 9;
  COL_MARG1   = 10;
  COL_MARG2   = 11;
  COL_PCTVDTO = 12;
  COL_PCTVLAST = 13;
  COL_MAX     = COL_PCTVLAST;      // 13
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  FMT_PCT     = '#,##0.0';
  FMT_NUM_HZ  = '#,##0;-#,##0;';
  FMT_EUR_HZ  = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_TOTALES  = $00F2F2F2;
  CL_GRUPO_H  = $00EED7BD;
  CL_GRUPO_T  = $00F7EBDD;
  N_NIVELES   = 3;

type
  TAcum = record
    UniEnt: Double;
    ImpEnt: Double;
    UdsVta: Double;
    ImpVta: Double;
    ImpCos: Double;
    Benef: Double;
    VtaEnt: Double;
    procedure Reset;
    procedure Add(const Q: TDataSet);
  end;
  TExportadorMovVentasArt = class
  private
    FEscritor: IEscritorHojaCalculo;
    FFormateador: IFormateadorHojaCalculo;
    FDatos: TDataSet;
    FFila: Integer;
    FGrupoCodigos: array[1..N_NIVELES] of string;
    FGrupoEtiquetas: array[1..N_NIVELES] of string;
    FGrupoUsado: array[1..N_NIVELES] of Boolean;
    FGrupoAcumulado: array[1..N_NIVELES] of TAcum;
    FGrupoVentasPadre: array[1..N_NIVELES] of Double;
    FTotalAcumulado: TAcum;
    procedure EscribirValor(AColumna: Integer; const AValor: Variant;
      ANegrita: Boolean = False;
      AAlineacion: TAlineacionCelda = acIzquierda;
      const AFormato: string = '');
    procedure EscribirNumero(AColumna: Integer; AValor: Double;
      const AFormato: string; AOcultarCero: Boolean);
    function CampoTexto(const ANombre: string): string;
    function CampoNumero(const ANombre: string): Double;
    procedure EscribirCabeceraColumnas;
    procedure EscribirTotales(const AAcumulado: TAcum;
      const AEtiqueta: string; AColorFondo: Cardinal;
      AVentasUnidadesPadre: Double);
    procedure AbrirGrupo(ANivel: Integer);
    procedure EmitirResumenGrupo(ANivel: Integer);
    procedure DetectarAgrupaciones;
    procedure EscribirDetalle;
    procedure AcumularFila;
    procedure ProcesarDatos;
    procedure ConfigurarAnchos;
  public
    constructor Create(const AEscritor: IEscritorHojaCalculo;
      const AFormateador: IFormateadorHojaCalculo; ADatos: TDataSet);
    procedure Ejecutar;
  end;

procedure TAcum.Reset;
begin
  UniEnt := 0;
  ImpEnt := 0;
  UdsVta := 0;
  ImpVta := 0;
  ImpCos := 0;
  Benef := 0;
  VtaEnt := 0;
end;

procedure TAcum.Add(const Q: TDataSet);
begin
  UniEnt := UniEnt + Q.FieldByName('UNI_ENT_TOT').AsFloat;
  ImpEnt := ImpEnt + Q.FieldByName('IMP_ENT_TOT').AsFloat;
  UdsVta := UdsVta + Q.FieldByName('UDS_VENTA').AsFloat;
  ImpVta := ImpVta + Q.FieldByName('IMP_VENTA').AsFloat;
  ImpCos := ImpCos + Q.FieldByName('IMP_COSTE').AsFloat;
  Benef := Benef + Q.FieldByName('BENEFICIO').AsFloat;
  VtaEnt := VtaEnt + Q.FieldByName('VENTA_ENT').AsFloat;
end;

constructor TExportadorMovVentasArt.Create(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  ADatos: TDataSet);
begin
  inherited Create;
  FEscritor := AEscritor;
  FFormateador := AFormateador;
  FDatos := ADatos;
end;

procedure TExportadorMovVentasArt.EscribirValor(AColumna: Integer;
  const AValor: Variant; ANegrita: Boolean;
  AAlineacion: TAlineacionCelda; const AFormato: string);
begin
  FEscritor.Escribir(FFila, AColumna, AValor);
  if ANegrita then
    FFormateador.Negrita(FFila, AColumna);
  FFormateador.Alinear(FFila, AColumna, AAlineacion);
  if AFormato <> '' then
    FFormateador.AplicarFormato(FFila, AColumna, AFormato);
end;

procedure TExportadorMovVentasArt.EscribirNumero(AColumna: Integer;
  AValor: Double; const AFormato: string; AOcultarCero: Boolean);
begin
  if (not AOcultarCero) or (AValor <> 0) then
    EscribirValor(AColumna, AValor, False, acDerecha, AFormato);
end;

function TExportadorMovVentasArt.CampoTexto(const ANombre: string): string;
var
  oCampo: TField;
begin
  oCampo := FDatos.FindField(ANombre);
  if oCampo <> nil then
    Result := oCampo.AsString
  else
    Result := '';
end;

function TExportadorMovVentasArt.CampoNumero(
  const ANombre: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := FDatos.FindField(ANombre);
  if oCampo <> nil then
    Result := oCampo.AsFloat;
end;

procedure TExportadorMovVentasArt.EscribirCabeceraColumnas;
const
  TITULOS: array[0..COL_MAX] of string = (
    'Artículo', 'Uni.Ent.', 'Imp.Ent.', 'Uds Vta', 'Imp Venta',
    'Imp Coste', 'Beneficio', '% Bnf', 'Venta-Ent', 'VentEnt%',
    'Margen 1', 'Margen 2', '% Vdo', '% Vtas');
var
  iColumna: Integer;
begin
  for iColumna := 0 to COL_MAX do
  begin
    EscribirValor(iColumna, TITULOS[iColumna], True);
    if iColumna > COL_ART then
      FFormateador.Alinear(FFila, iColumna, acDerecha);
    if FEscritor.CeldaExiste(FFila, iColumna) then
    begin
      FFormateador.FondoCelda(FFila, iColumna, CL_CABECERA);
      FFormateador.BordeCelda(
        FFila, iColumna, lbInferior, ebFino);
    end;
  end;
end;

procedure TExportadorMovVentasArt.EscribirTotales(
  const AAcumulado: TAcum; const AEtiqueta: string;
  AColorFondo: Cardinal; AVentasUnidadesPadre: Double);
var
  iColumna: Integer;
begin
  EscribirValor(COL_ART, AEtiqueta, True);
  EscribirNumero(COL_UNIENT, AAcumulado.UniEnt, FMT_NUM_HZ, False);
  EscribirNumero(COL_IMPENT, AAcumulado.ImpEnt, FMT_EUR_HZ, False);
  EscribirNumero(COL_UDSVTA, AAcumulado.UdsVta, FMT_NUM_HZ, False);
  EscribirNumero(COL_IMPVTA, AAcumulado.ImpVta, FMT_EUR_HZ, False);
  EscribirNumero(COL_IMPCOS, AAcumulado.ImpCos, FMT_EUR_HZ, False);
  EscribirNumero(COL_BENEF, AAcumulado.Benef, FMT_EUR_HZ, False);
  if AAcumulado.ImpVta <> 0 then
    EscribirNumero(COL_PCTBNF,
      AAcumulado.Benef / AAcumulado.ImpVta * 100, FMT_PCT, False);
  EscribirNumero(COL_VTAENT, AAcumulado.VtaEnt, FMT_EUR_HZ, False);
  if AAcumulado.ImpEnt <> 0 then
  begin
    EscribirNumero(COL_VENTENT,
      AAcumulado.ImpVta / AAcumulado.ImpEnt * 100, FMT_PCT, False);
    EscribirNumero(COL_MARG2,
      AAcumulado.VtaEnt / AAcumulado.ImpEnt * 100, FMT_PCT, False);
  end;
  if AAcumulado.ImpCos <> 0 then
    EscribirNumero(COL_MARG1,
      AAcumulado.Benef / AAcumulado.ImpCos * 100, FMT_PCT, False);
  if AAcumulado.UniEnt <> 0 then
    EscribirNumero(COL_PCTVDTO,
      AAcumulado.UdsVta / AAcumulado.UniEnt * 100, FMT_PCT, False);
  if AVentasUnidadesPadre <> 0 then
    EscribirNumero(COL_PCTVLAST,
      AAcumulado.UdsVta / AVentasUnidadesPadre * 100, FMT_PCT, False);
  for iColumna := 0 to COL_MAX do
  begin
    if FEscritor.CeldaExiste(FFila, iColumna) then
    begin
      FFormateador.Negrita(FFila, iColumna);
      FFormateador.FondoCelda(FFila, iColumna, AColorFondo);
      FFormateador.BordeCelda(
        FFila, iColumna, lbSuperior, ebFino);
    end;
  end;
  Inc(FFila);
end;

procedure TExportadorMovVentasArt.AbrirGrupo(ANivel: Integer);
const
  CAMPOS_VENTAS_PADRE: array[1..N_NIVELES] of string = (
    'UDS_VENTA_GLOBAL', 'UDS_VENTA_G1', 'UDS_VENTA_G2');
var
  iColumna: Integer;
begin
  if FGrupoUsado[ANivel] then
  begin
    EscribirValor(COL_ART,
      StringOfChar(' ', (ANivel - 1) * 2) + FGrupoEtiquetas[ANivel],
      True);
    FFormateador.TamanoFuente(FFila, COL_ART, 12);
    for iColumna := 0 to COL_MAX do
    begin
      if FEscritor.CeldaExiste(FFila, iColumna) then
      begin
        FFormateador.FondoCelda(FFila, iColumna, CL_GRUPO_H);
        FFormateador.BordeCelda(
          FFila, iColumna, lbInferior, ebFino);
      end;
    end;
    Inc(FFila);
    EscribirCabeceraColumnas;
    Inc(FFila);
  end;
  FGrupoVentasPadre[ANivel] :=
    CampoNumero(CAMPOS_VENTAS_PADRE[ANivel]);
  FGrupoAcumulado[ANivel].Reset;
end;

procedure TExportadorMovVentasArt.EmitirResumenGrupo(ANivel: Integer);
begin
  if FGrupoUsado[ANivel] then
    EscribirTotales(FGrupoAcumulado[ANivel],
      'TOTAL ' + FGrupoEtiquetas[ANivel], CL_GRUPO_T,
      FGrupoVentasPadre[ANivel]);
  FGrupoAcumulado[ANivel].Reset;
end;

procedure TExportadorMovVentasArt.DetectarAgrupaciones;
var
  iNivel: Integer;
  iNivelCambio: Integer;
begin
  FGrupoUsado[1] := CampoTexto('GRUPO1_ETIQ') <> '';
  FGrupoUsado[2] := CampoTexto('GRUPO2_ETIQ') <> '';
  FGrupoUsado[3] := CampoTexto('GRUPO3_ETIQ') <> '';
  iNivelCambio := N_NIVELES + 1;
  for iNivel := 1 to N_NIVELES do
  begin
    if (iNivelCambio > N_NIVELES) and FGrupoUsado[iNivel] and
       (CampoTexto(Format('GRUPO%d_COD', [iNivel])) <>
        FGrupoCodigos[iNivel]) then
      iNivelCambio := iNivel;
  end;
  if iNivelCambio <= N_NIVELES then
  begin
    if FGrupoCodigos[1] <> #1 then
    begin
      for iNivel := N_NIVELES downto iNivelCambio do
        EmitirResumenGrupo(iNivel);
    end;
    for iNivel := iNivelCambio to N_NIVELES do
    begin
      FGrupoCodigos[iNivel] :=
        CampoTexto(Format('GRUPO%d_COD', [iNivel]));
      FGrupoEtiquetas[iNivel] :=
        CampoTexto(Format('GRUPO%d_ETIQ', [iNivel]));
      AbrirGrupo(iNivel);
    end;
  end;
end;

procedure TExportadorMovVentasArt.EscribirDetalle;
var
  sArticulo: string;
  sColor: string;
begin
  sArticulo := FDatos.FieldByName('CODIGO_ART_ART').AsString;
  sColor := Trim(CampoTexto('COLOR_ETIQUETA'));
  if sColor = '' then
    sColor := Trim(CampoTexto('COLOR'));
  if sColor <> '' then
    sArticulo := sArticulo + '  Color: ' + sColor;
  sArticulo := sArticulo + '  ' +
    FDatos.FieldByName('DESCRIPCION_ART').AsString;
  EscribirValor(COL_ART, sArticulo);
  EscribirNumero(COL_UNIENT,
    FDatos.FieldByName('UNI_ENT_TOT').AsFloat, FMT_NUM, True);
  EscribirNumero(COL_IMPENT,
    FDatos.FieldByName('IMP_ENT_TOT').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_UDSVTA,
    FDatos.FieldByName('UDS_VENTA').AsFloat, FMT_NUM, True);
  EscribirNumero(COL_IMPVTA,
    FDatos.FieldByName('IMP_VENTA').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_IMPCOS,
    FDatos.FieldByName('IMP_COSTE').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_BENEF,
    FDatos.FieldByName('BENEFICIO').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_PCTBNF,
    FDatos.FieldByName('PCT_BNFCO').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_VTAENT,
    FDatos.FieldByName('VENTA_ENT').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_VENTENT,
    FDatos.FieldByName('VENT_ENT').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_MARG1,
    FDatos.FieldByName('MARGEN1').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_MARG2,
    FDatos.FieldByName('MARGEN2').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_PCTVDTO,
    FDatos.FieldByName('PCT_VDTO').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_PCTVLAST,
    FDatos.FieldByName('PCT_VLAST').AsFloat, FMT_PCT, True);
end;

procedure TExportadorMovVentasArt.AcumularFila;
var
  iNivel: Integer;
begin
  FTotalAcumulado.Add(FDatos);
  for iNivel := 1 to N_NIVELES do
  begin
    if FGrupoUsado[iNivel] then
      FGrupoAcumulado[iNivel].Add(FDatos);
  end;
end;

procedure TExportadorMovVentasArt.ProcesarDatos;
var
  iNivel: Integer;
begin
  if (FDatos <> nil) and FDatos.Active and (not FDatos.IsEmpty) then
  begin
    FDatos.DisableControls;
    try
      FDatos.First;
      while not FDatos.Eof do
      begin
        DetectarAgrupaciones;
        EscribirDetalle;
        AcumularFila;
        Inc(FFila);
        FDatos.Next;
      end;
      if FGrupoCodigos[1] <> #1 then
      begin
        for iNivel := N_NIVELES downto 1 do
          EmitirResumenGrupo(iNivel);
      end;
      EscribirTotales(FTotalAcumulado, 'TOTAL GENERAL', CL_GRUPO_H,
        FTotalAcumulado.UdsVta);
      FFormateador.BordeCelda(
        FFila - 1, COL_ART, lbInferior, ebFino);
    finally
      FDatos.EnableControls;
    end;
  end;
end;

procedure TExportadorMovVentasArt.ConfigurarAnchos;
var
  iColumna: Integer;
begin
  FFormateador.AnchoColumna(COL_ART, 240);
  for iColumna := COL_UNIENT to COL_MAX do
    FFormateador.AnchoColumna(iColumna, 72);
end;

procedure TExportadorMovVentasArt.Ejecutar;
var
  iNivel: Integer;
begin
  FEscritor.NuevaHoja('Ventas');
  for iNivel := 1 to N_NIVELES do
  begin
    FGrupoCodigos[iNivel] := #1;
    FGrupoEtiquetas[iNivel] := '';
    FGrupoUsado[iNivel] := False;
    FGrupoAcumulado[iNivel].Reset;
    FGrupoVentasPadre[iNivel] := 0;
  end;
  FTotalAcumulado.Reset;
  FEscritor.IniciarLote;
  try
    FFila := 1;
    EscribirValor(
      COL_ART,
      'MOVIMIENTOS DE VENTAS POR ARTÍCULOS Y FECHAS',
      True);
    FFormateador.TamanoFuente(FFila, COL_ART, 14);
    Inc(FFila, 2);
    EscribirCabeceraColumnas;
    Inc(FFila);
    ProcesarDatos;
    ConfigurarAnchos;
  finally
    FEscritor.FinalizarLote;
  end;
end;

procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet);
var
  oExportador: TExportadorMovVentasArt;
begin
  oExportador := TExportadorMovVentasArt.Create(
    AEscritor, AFormateador, QDatos);
  try
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.
