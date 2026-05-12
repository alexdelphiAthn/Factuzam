{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFTicket                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Composición y envío de tickets a impresoras térmicas ESC/POS.             }
{    Soporta fuentes, alineación, imágenes, corte de papel y apertura de cajón.}
{******************************************************************************}
unit inLibFTicket;

interface
uses
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,      // TBitmap de VCL
  Winapi.WinSpool;   // QUITAR Winapi.Windows de aquí
const
  N_CHAR_LIN = 42;
type
  TFuenteTermica = (ftRasterA, ftRasterB, ftRasterC);
  TAlineacion = (alIzquierda, alCentro, alDerecha);
  TTicketTermico = class
  private
    FComandos: TStringBuilder;
    FNombreImpresora: string;
    function ObtenerComandoFuente(Fuente: TFuenteTermica): string;
    function ObtenerComandoAlineacion(Alineacion: TAlineacion): string;
  public
    constructor Create(const NombreImpresora: string);
    destructor Destroy; override;
    procedure Inicializar;
    procedure ConfigurarEspanol;
    function ObtenerComandos: string;
    procedure SeleccionarFuente(Fuente: TFuenteTermica);
    procedure Alinear(Alineacion: TAlineacion);
    procedure Negrita(Activar: Boolean);
    procedure Subrayado(Activar: Boolean);
    procedure TamanoDoble(Ancho, Alto: Boolean);
    procedure EscribirLinea(const Texto: string);
    procedure EscribirTexto(const Texto: string);
    procedure SaltarLineas(CANTIDAD_ARTVIN: Integer);
    procedure LineaSeparadora(Caracter: Char = '-');
    procedure ImprimirImagen(Bitmap: Vcl.Graphics.TBitmap;
                             Escala: Integer = 3);
    procedure CortarPapel(Parcial: Boolean = False);
    procedure AbrirCajon;

    procedure TextoColumnas(const Izq, Der: string; Ancho: Integer=N_CHAR_LIN);
    procedure Imprimir;
    procedure Limpiar;
    procedure ImprimirQRNativo(const Texto: string;
                               TamanoModulo: Integer = 8;
                               NivelError: Integer = 48);
    property NombreImpresora: string read FNombreImpresora
                                     write FNombreImpresora;
  end;

  procedure EnviarComandoRAW(const NombreImpresora: string;
                             const Datos: string);

implementation

uses
  Winapi.Windows;

const
  ESC = #27;
  GS = #29;
  // Página de códigos 858 - Soporta español
  CMD_CODEPAGE_858 = ESC + 't' + #19;
  CMD_INICIALIZAR = ESC + '@';
  CMD_FUENTE_A = ESC + 'M' + #0;
  CMD_FUENTE_B = ESC + 'M' + #1;
  CMD_FUENTE_C = ESC + 'M' + #2;
  CMD_NEGRITA_ON = ESC + 'E' + #1;
  CMD_NEGRITA_OFF = ESC + 'E' + #0;
  CMD_SUBRAYADO_ON = ESC + '-' + #1;
  CMD_SUBRAYADO_OFF = ESC + '-' + #0;
  CMD_IZQUIERDA = ESC + 'a' + #0;
  CMD_CENTRO = ESC + 'a' + #1;
  CMD_DERECHA = ESC + 'a' + #2;
  CMD_TAMANO_NORMAL = GS + '!' + #0;
  CMD_CORTE_TOTAL = ESC + 'i';
  CMD_CORTE_PARCIAL = ESC + 'm';
  CMD_ABRIR_CAJON = ESC + 'p' + #0 + #50 + #250;

procedure TTicketTermico.ImprimirQRNativo(const Texto: string;
                                          TamanoModulo: Integer = 8;
                                          NivelError: Integer = 48);
var
  pL, pH: Byte;
  DataLength: Integer;
begin
  DataLength := Length(Texto) + 3;
  pL := DataLength mod 256;
  pH := DataLength div 256;
  Alinear(alCentro);
  // Usar #XX en lugar de GS + '(k' + Chr()...
  FComandos.Append(#29#40#107#4#0#49#65#50#0);
  FComandos.Append(#29#40#107#3#0#49#67 + Chr(TamanoModulo));
  FComandos.Append(#29#40#107#3#0#49#69 + Chr(NivelError));
  FComandos.Append(#29#40#107 + Chr(pL) + Chr(pH) + #49#80#48 + Texto);
  FComandos.Append(#29#40#107#3#0#49#81#48);
  FComandos.Append(#13#10);
  Alinear(alIzquierda);
end;

constructor TTicketTermico.Create(const NombreImpresora: string);
begin
  inherited Create;
  FNombreImpresora := NombreImpresora;
  FComandos := TStringBuilder.Create;
end;

destructor TTicketTermico.Destroy;
begin
  FComandos.Free;
  inherited;
end;

procedure TTicketTermico.Inicializar;
begin
  FComandos.Append(CMD_INICIALIZAR);
  ConfigurarEspanol;
end;

function TTicketTermico.ObtenerComandoFuente(Fuente: TFuenteTermica): string;
begin
  case Fuente of
    ftRasterA: Result := CMD_FUENTE_A;
    ftRasterB: Result := CMD_FUENTE_B;
    ftRasterC: Result := CMD_FUENTE_C;
  else
    Result := CMD_FUENTE_A;
  end;
end;

function TTicketTermico.ObtenerComandos: string;
begin
  Result := FComandos.ToString;
end;

function TTicketTermico.ObtenerComandoAlineacion(
  Alineacion: TAlineacion): string;
begin
  case Alineacion of
    alIzquierda: Result := CMD_IZQUIERDA;
    alCentro: Result := CMD_CENTRO;
    alDerecha: Result := CMD_DERECHA;
  else
    Result := CMD_IZQUIERDA;
  end;
end;
procedure TTicketTermico.SeleccionarFuente(Fuente: TFuenteTermica);
begin
  FComandos.Append(ObtenerComandoFuente(Fuente));
end;

procedure TTicketTermico.Alinear(Alineacion: TAlineacion);
begin
  FComandos.Append(ObtenerComandoAlineacion(Alineacion));
end;

procedure TTicketTermico.Negrita(Activar: Boolean);
begin
  if Activar then
    FComandos.Append(CMD_NEGRITA_ON)
  else
    FComandos.Append(CMD_NEGRITA_OFF);
end;

procedure TTicketTermico.Subrayado(Activar: Boolean);
begin
  if Activar then
    FComandos.Append(CMD_SUBRAYADO_ON)
  else
    FComandos.Append(CMD_SUBRAYADO_OFF);
end;
procedure TTicketTermico.TamanoDoble(Ancho, Alto: Boolean);
var
  Valor: Byte;
begin
  Valor := 0;
  if Ancho then
    Valor := Valor or $20;
  if Alto then
    Valor := Valor or $10;
  FComandos.Append(GS + '!' + Chr(Valor));
end;

procedure TTicketTermico.EscribirLinea(const Texto: string);
begin
  FComandos.Append(Texto + #13#10);
end;

procedure TTicketTermico.EscribirTexto(const Texto: string);
begin
  FComandos.Append(Texto);
end;

procedure TTicketTermico.SaltarLineas(CANTIDAD_ARTVIN: Integer);
begin
  FComandos.Append(ESC + 'd' + Chr(CANTIDAD_ARTVIN));
end;

procedure TTicketTermico.LineaSeparadora(Caracter: Char);
begin
  EscribirLinea(StringOfChar(Caracter, N_CHAR_LIN));
end;

procedure TTicketTermico.TextoColumnas(const Izq,
                                       Der: string;
                                       Ancho: Integer = N_CHAR_LIN);
var
  Espacios: Integer;
begin
  Espacios := Ancho - Length(Izq) - Length(Der);
  if Espacios < 1 then
    Espacios := 1;
  EscribirLinea(Izq + StringOfChar(' ', Espacios) + Der);
end;

procedure TTicketTermico.ImprimirImagen(Bitmap: Vcl.Graphics.TBitmap;
                                        Escala: Integer = 3);
var
  x, y: Integer;
  BitmapMono, BitmapEscalado: Vcl.Graphics.TBitmap;
  Color: TColor;
  BytesAncho: Integer;
  DatosImagen: TBytes;
  ByteIndex: Integer;
  xSrc, ySrc: Integer;
begin
  BitmapEscalado := Vcl.Graphics.TBitmap.Create;
  BitmapMono := Vcl.Graphics.TBitmap.Create;
  try
    // Escalar el bitmap original
    BitmapEscalado.Width := Bitmap.Width * Escala;
    BitmapEscalado.Height := Bitmap.Height * Escala;
    // Escalar p�xel por p�xel para mantener nitidez
    for y := 0 to BitmapEscalado.Height - 1 do
    begin
      ySrc := y div Escala;
      for x := 0 to BitmapEscalado.Width - 1 do
      begin
        xSrc := x div Escala;
        BitmapEscalado.Canvas.Pixels[x, y] := Bitmap.Canvas.Pixels[xSrc, ySrc];
      end;
    end;
    // Convertir a monocromo
    BitmapMono.Monochrome := True;
    BitmapMono.Width := BitmapEscalado.Width;
    BitmapMono.Height := BitmapEscalado.Height;
    BitmapMono.Canvas.Draw(0, 0, BitmapEscalado);
    BytesAncho := (BitmapMono.Width + 7) div 8;
    SetLength(DatosImagen, BytesAncho * BitmapMono.Height);
    // Convertir imagen a bytes
    for y := 0 to BitmapMono.Height - 1 do
    begin
      for x := 0 to BitmapMono.Width - 1 do
      begin
        Color := BitmapMono.Canvas.Pixels[x, y];
        if (Color and $FFFFFF) < $808080 then
        begin
          ByteIndex := y * BytesAncho + (x div 8);
          DatosImagen[ByteIndex] := DatosImagen[ByteIndex]
             or (128 shr (x mod 8));
        end;
      end;
    end;
    Alinear(alCentro);
    FComandos.Append(GS + 'v0' + Chr(0) +
                     Chr(Lo(BytesAncho)) + Chr(Hi(BytesAncho)) +
                     Chr(Lo(BitmapMono.Height)) + Chr(Hi(BitmapMono.Height)));
    for ByteIndex := 0 to High(DatosImagen) do
      FComandos.Append(Chr(DatosImagen[ByteIndex]));
    FComandos.Append(#13#10);
  finally
    BitmapMono.Free;
    BitmapEscalado.Free;
  end;
  Alinear(alIzquierda);
end;

procedure TTicketTermico.ConfigurarEspanol;
begin
  FComandos.Append(CMD_CODEPAGE_858);
end;

procedure TTicketTermico.CortarPapel(Parcial: Boolean);
begin
  if Parcial then
    FComandos.Append(CMD_CORTE_PARCIAL)
  else
    FComandos.Append(CMD_CORTE_TOTAL);
end;

procedure TTicketTermico.AbrirCajon;
begin
  FComandos.Append(CMD_ABRIR_CAJON);
end;

procedure TTicketTermico.Imprimir;
begin
  EnviarComandoRAW(FNombreImpresora, FComandos.ToString);
end;

procedure TTicketTermico.Limpiar;
begin
  FComandos.Clear;
end;

procedure EnviarComandoRAW(const NombreImpresora: string; const Datos: string);
var
  hPrinter: THandle;
  DocInfo: TDocInfo1;
  BytesEscritos: DWORD;
  DatosRaw: TBytes;
  F: TextFile;
  DebugFile: string;
  i: Integer;
  CP858: TEncoding;
//  CaracterStr: string;
//  BytesChar: TBytes;
begin
  // === MODO DEBUG ===
  if (NombreImpresora = 'DEBUG') or (NombreImpresora = '') then
  begin
    DebugFile := ExtractFilePath(ParamStr(0)) + 'ticket_escpos_debug_' +
                    ParamStr(1) + '_' + ParamStr(2) + '_' + ParamStr(3) +'.txt';
    AssignFile(F, DebugFile);
    FileMode := fmOpenRead or fmShareDenyNone;
    Rewrite(F);
    try
      WriteLn(F, '=== COMANDOS ESC/POS - DEBUG ===');
      WriteLn(F, 'Longitud total: ' + IntToStr(Length(Datos)) + ' bytes');
      WriteLn(F, '');
      WriteLn(F, '=== DUMP HEXADECIMAL ===');
      for i := 1 to Length(Datos) do
      begin
        Write(F, IntToHex(Ord(Datos[i]), 2) + ' ');
        if i mod 16 = 0 then WriteLn(F);
      end;
      WriteLn(F, '');
      WriteLn(F, '');
      WriteLn(F, '=== CONTENIDO LEGIBLE ===');
      for i := 1 to Length(Datos) do
      begin
        case Datos[i] of
          #27: Write(F, '<ESC>');
          #29: Write(F, '<GS>');
          #10: WriteLn(F, '<LF>');
          #13: Write(F, '<CR>');
          #0..#8, #11..#12, #14..#26, #28, #30..#31:
            Write(F, '<' + IntToHex(Ord(Datos[i]), 2) + '>');
        else
          Write(F, Datos[i]);
        end;
      end;
      WriteLn(F, '');
      WriteLn(F, '=== FIN DEBUG ===');
    finally
      CloseFile(F);
    end;
    Exit;
  end;
  // === IMPRESI�N REAL ===
  if not OpenPrinter(PChar(NombreImpresora), hPrinter, nil) then
    raise Exception.CreateFmt('No se pudo abrir la impresora: %s',
                              [NombreImpresora]);
  try
    DocInfo.pDocName := 'Ticket Fzam';
    DocInfo.pOutputFile := nil;
    DocInfo.pDatatype := 'RAW';
    if (StartDocPrinter(hPrinter, 1, @DocInfo) = 0) then
      raise Exception.Create('Error al iniciar documento');
    try
      if StartPagePrinter(hPrinter) then
      begin
        try
          CP858 := TEncoding.GetEncoding(858);
          try
            // Convertir el string completo a CP858 primero
            DatosRaw := CP858.GetBytes(Datos);
            // Ahora CORREGIR los bytes de comandos QR que CP858 pudo alterar
            // Recorrer buscando comandos GS ( k
            i := 0;
            while (i < Length(DatosRaw) - 4) do
            begin
              // Buscar secuencia: 1D 28 6B (GS ( k)
              if ((DatosRaw[i] = $1D) and
                 (DatosRaw[i+1] = $28) and
                 (DatosRaw[i+2] = $6B)) then
              begin
                // Los siguientes 2 bytes son pL y pH
                // Restaurarlos del string original
                //(�ndice i+1 porque Datos empieza en 1)
                if i+4 < Length(Datos) then
                begin
                  DatosRaw[i+3] := Ord(Datos[i+4]); // pL
                  DatosRaw[i+4] := Ord(Datos[i+5]); // pH
                end;
                // Saltar estos bytes procesados
                Inc(i, 5);
              end
              else
                Inc(i);
            end;
          finally
            CP858.Free;
          end;
          if not WritePrinter(hPrinter,
                              @DatosRaw[0],
                              Length(DatosRaw),
                              BytesEscritos) then
            raise Exception.Create('Error al escribir en impresora');
        finally
          EndPagePrinter(hPrinter);
        end;
      end;
      EndDocPrinter(hPrinter);
    except
      on E: Exception do
      begin
        EndDocPrinter(hPrinter);
        raise;
      end;
    end;
  finally
    ClosePrinter(hPrinter);
  end;
end;

end.
