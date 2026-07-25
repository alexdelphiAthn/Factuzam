{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoIntf                                          }
{    Tipo:       Librería (interfaces)                                         }
{ Versión:       1.1.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de escritura y lectura de hojas de cálculo, independientes del    }
{    motor concreto (DevExpress, OOXML, doble de prueba). Los exportadores     }
{    de dominio dependen de estas interfaces y no del control TdxSpreadSheet.  }
{    v1.1 (Fase 2): el puerto crece con las operaciones que usa un            }
{    exportador real (formato, fondo, borde por lado, tamaño de fuente,        }
{    negrita, ancho de columna, lote y existencia de celda).                   }
{******************************************************************************}
unit inLibHojaCalculoIntf;

interface

uses
  System.Variants;

type
  // Alineación horizontal neutra (el adaptador la mapea a ssah*).
  TAlineacionCelda = (acIzquierda, acCentro, acDerecha);
  // Grosor de borde neutro (el adaptador lo mapea a
  // TdxSpreadSheetCellBorderStyle).
  TEstiloBorde = (ebNinguno, ebFino, ebMedio, ebGrueso);
  // Lado de una celda para bordes sueltos (el adaptador lo mapea a TcxBorder).
  TLadoBorde = (lbSuperior, lbInferior, lbIzquierdo, lbDerecho);
  // Puerto de escritura. Índices de fila y columna en base 0. El color es un
  // TColor codificado como Cardinal ($00BBGGRR) para no depender de la VCL.
  IEscritorHojaCalculo = interface
    ['{4584B695-CCB6-4AE2-A94B-33F28A5D8EDD}']
    // Limpia el libro y crea una hoja nueva con ese nombre; queda activa.
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
  end;
  // Puerto de lectura: ruta de importación (leer celdas por índice, base 0).
  ILectorHojaCalculo = interface
    ['{C29FE431-5335-4F32-8DA2-9EE7CE5EAAFD}']
    function LeerCelda(AFila, ACol: Integer): Variant;
    function UltimaFila: Integer;
    function UltimaColumna: Integer;
  end;

implementation

end.
