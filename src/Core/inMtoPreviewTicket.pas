{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPreviewTicket                                            }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Previsualizador de tickets ESC/POS con exportación a PDF.                 }
{    Interpreta los comandos de la impresora y renderiza el ticket en pantalla.}
{******************************************************************************}
unit inMtoPreviewTicket;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, System.Math, DelphiZXingQRCode, inLibFTicket;
type
  TFormVisualizador = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel1: TPanel;
    btnCerrar: TButton;
    btnImprimir: TButton;
    btnPDF: TButton;
    btnPNG: TButton;
    SaveDialog1: TSaveDialog;
    btnImprimirTicket: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnPDFClick(Sender: TObject);
    procedure btnPNGClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnImprimirTicketClick(Sender: TObject);
  private
    FCanvas: TCanvas;
    FCurrentY: Integer;
    FFuenteActual: Integer; // 0=A(12x24), 1=B(9x17), 2=C(7x14)
    FNegrita: Boolean;
    FSubrayado: Boolean;
    FAlineacion: Integer; // 0=Izq, 1=Centro, 2=Derecha
    FTamanoAncho: Integer; // Multiplicador ancho (1-8)
    FTamanoAlto: Integer; // Multiplicador alto (1-8)
    FInverso: Boolean;
    FQRTexto: string;
    FQRTamanoModulo: Integer;
    FQRNivelError: Integer;
    procedure ProcesarComandosESCPOS(const Comandos: string);
    procedure ImprimirTexto(const Texto: string);
    procedure ImprimirImagenRaster(const Datos: string; Ancho, Alto: Integer);
    procedure NuevaLinea;
    procedure AjustarFuente;
    function ObtenerAltoLinea: Integer;
    procedure DibujarQRCode;

  public
    FComandos: string;
    FRutaPDFReal: string;
    procedure ExportarAPDF(const Comandos: string; const RutaArchivo: string);
    procedure CargarYMostrar(const Comandos: string);
    procedure GuardarPNG(const ARuta: string);
    procedure ImprimirEnImpresora;
  end;

procedure VisualizarTicket(const Comandos: string);

var
  FormVisualizador:TFormVisualizador;

implementation

{$R *.dfm}

uses
  SynPdf, inLibDir, Vcl.Imaging.PngImage, Vcl.Printers, System.IOUtils;

const
  ANCHO_PAPEL_MM = 80;
  DPI = 203;
  ANCHO_PAPEL_PIXELS = 576; // Estándar real de 80mm
  ANCHO_PAPEL_PIXELS_PDF = 594;
  MARGEN_PIXELS = 8;
  // Tamaños de fuentes en pixels (aproximado)
  FUENTE_A_ANCHO = 12;
  FUENTE_A_ALTO = 24;
  FUENTE_B_ANCHO = 9;
  FUENTE_B_ALTO = 17;
  FUENTE_C_ANCHO = 7;
  FUENTE_C_ALTO = 14;

procedure TFormVisualizador.ExportarAPDF(const Comandos: string;
                                         const RutaArchivo: string);
var
  Pdf: TPdfDocumentGDI;
  Metafile: TMetafile;
  MetaCanvas: TMetafileCanvas;
  CanvasBackup: TCanvas;
  AlturaReal: Integer;
  MargenH: Integer;   // margen horizontal
  MargenV: Integer;   // margen inferior
  PageW, PageH: Integer;
begin
  AlturaReal := Image1.Picture.Bitmap.Height;
  MargenH    := 20;   // margen izq y der en puntos PDF
  MargenV    := 40;   // margen inferior
  // Página = contenido + márgenes laterales
  PageW := ANCHO_PAPEL_PIXELS_PDF + (MargenH * 2);
  PageH := AlturaReal + MargenV;
  Pdf := TPdfDocumentGDI.Create;
  Metafile := TMetafile.Create;
  try
    Metafile.Width    := ANCHO_PAPEL_PIXELS_PDF;
    Metafile.Height   := AlturaReal;
    Metafile.MMWidth  := MulDiv(ANCHO_PAPEL_PIXELS_PDF, 2540, DPI);
    Metafile.MMHeight := MulDiv(AlturaReal, 2540, DPI);
    MetaCanvas := TMetafileCanvas.Create(Metafile, 0);
    CanvasBackup := FCanvas;
    FCanvas := MetaCanvas;
    try
      FCurrentY     := MARGEN_PIXELS;
      FFuenteActual := 0;
      FNegrita      := False;
      FSubrayado    := False;
      FAlineacion   := 0;
      FTamanoAncho  := 1;
      FTamanoAlto   := 1;
      FInverso      := False;
      FQRTexto      := '';
      MetaCanvas.Brush.Color := clWhite;
      MetaCanvas.FillRect(Rect(0, 0, ANCHO_PAPEL_PIXELS_PDF, AlturaReal));
      ProcesarComandosESCPOS(Comandos);
    finally
      FreeAndNil(MetaCanvas);
      FCanvas := CanvasBackup;
    end;
    Pdf.DefaultPaperSize  := psUserDefined;
    Pdf.DefaultPageWidth  := PageW;
    Pdf.DefaultPageHeight := PageH;
    Pdf.AddPage;
    // El contenido ocupa exactamente ANCHO_PAPEL_PIXELS_PDF,
    // desplazado MargenH puntos desde la izquierda
    PlayEnhMetaFile(Pdf.VCLCanvas.Handle,
                    Metafile.Handle,
                    Rect(MargenH,           // izquierda
                         0,                 // arriba
                         MargenH + ANCHO_PAPEL_PIXELS_PDF,  // derecha exacta
                         AlturaReal));      // abajo sin comprimir
    Pdf.SaveToFile(RutaArchivo);
  finally
    FreeAndNil(Metafile);
    FreeAndNil(Pdf);
  end;
end;

procedure VisualizarTicket(const Comandos: string);
var
  Form: TFormVisualizador;
begin
  Form := TFormVisualizador.Create(nil);
  try
    Form.FComandos := Comandos;
    Form.CargarYMostrar(Comandos);
    // Generar PDF antes del ShowModal (funciona siempre en este punto)
//    Form.FRutaPDFTemporal := GetUserFolderTickets + '_preview_tmp.pdf';
//    Form.ExportarAPDF(Comandos, Form.FRutaPDFTemporal);
    Form.ShowModal;
  finally
    FreeAndNil(Form);
  end;
end;

procedure TFormVisualizador.DibujarQRCode;
var
  QRCode: TDelphiZXIngQRCode;
  Row, Column: Integer;
  Scale: Integer;
  QRBitmap: TBitmap;
  x, y: Integer;
  StartX: Integer;
  QRWidth, QRHeight: Integer;
begin
  if FQRTexto <> '' then
  begin
    QRCode := TDelphiZXIngQRCode.Create;
    QRBitmap := TBitmap.Create;
    try
      // Nivel ESC/POS: 48=L, 49=M, 50=Q, 51=H.
      case FQRNivelError of
        49:
          QRCode.ErrorCorrectionLevel := qreM;
        50:
          QRCode.ErrorCorrectionLevel := qreQ;
        51:
          QRCode.ErrorCorrectionLevel := qreH;
      else
        QRCode.ErrorCorrectionLevel := qreL;
      end;
      QRCode.Encoding := TQRCodeEncoding(qrUTF8NoBOM);
      QRCode.QuietZone := 1;
      QRCode.Data := FQRTexto;
      // Escala basada en el tamaño del módulo.
      Scale := FQRTamanoModulo div 2;
      if Scale < 2 then
        Scale := 2;
      QRBitmap.Width := QRCode.Columns * Scale;
      QRBitmap.Height := QRCode.Rows * Scale;
      QRBitmap.PixelFormat := pf24bit;
      QRBitmap.Canvas.Brush.Color := clWhite;
      QRBitmap.Canvas.FillRect(Rect(0, 0, QRBitmap.Width, QRBitmap.Height));
      QRBitmap.Canvas.Brush.Color := clBlack;
      for Row := 0 to QRCode.Rows - 1 do
      begin
        for Column := 0 to QRCode.Columns - 1 do
        begin
          if QRCode.IsBlack[Row, Column] then
          begin
            x := Column * Scale;
            y := Row * Scale;
            QRBitmap.Canvas.FillRect(Rect(x, y, x + Scale, y + Scale));
          end;
        end;
      end;
      QRWidth := QRBitmap.Width;
      QRHeight := QRBitmap.Height;
      case FAlineacion of
        1:
          StartX := (ANCHO_PAPEL_PIXELS - QRWidth) div 2;
        2:
          StartX := ANCHO_PAPEL_PIXELS - QRWidth - MARGEN_PIXELS;
      else
        StartX := MARGEN_PIXELS;
      end;
      FCanvas.Draw(StartX, FCurrentY, QRBitmap);
      FCurrentY := FCurrentY + QRHeight;
    finally
      FreeAndNil(QRBitmap);
      FreeAndNil(QRCode);
    end;
  end;
end;

procedure TFormVisualizador.ImprimirImagenRaster(const Datos: string;
                                                 Ancho, Alto: Integer);
var
  X, Y: Integer;
  ByteIndex, BitIndex: Integer;
  StartX: Integer;
begin
  // Verificar que tenemos suficientes datos
  if Length(Datos) = 0 then
  begin
    FCurrentY := FCurrentY + Alto;
    Exit;
  end;
  // Calcular posición X según alineación
  case FAlineacion of
    1: StartX := (ANCHO_PAPEL_PIXELS - Ancho) div 2; // Centro
    2: StartX := ANCHO_PAPEL_PIXELS - Ancho - MARGEN_PIXELS; // Derecha
  else
    StartX := MARGEN_PIXELS; // Izquierda
  end;
  // Asegurarnos de no salirnos de los límites
  if StartX < 0 then StartX := 0;
  if StartX + Ancho > ANCHO_PAPEL_PIXELS then
    Ancho := ANCHO_PAPEL_PIXELS - StartX;
  for Y := 0 to Alto - 1 do
  begin
    for X := 0 to Ancho - 1 do
    begin
      ByteIndex := (X div 8) + 1;
      BitIndex := 7 - (X mod 8);
      if (ByteIndex <= Length(Datos)) and (ByteIndex > 0) then
      begin
        if ((Ord(Datos[ByteIndex]) and (1 shl BitIndex)) <> 0) then
        begin
          if (StartX + X < ANCHO_PAPEL_PIXELS) and
             (FCurrentY + Y < Image1.Picture.Bitmap.Height) then
            FCanvas.Pixels[StartX + X, FCurrentY + Y] := clBlack;
        end;
      end;
    end;
  end;
  FCurrentY := FCurrentY + Alto;
end;

procedure TFormVisualizador.FormCreate(Sender: TObject);
begin
  KeyPreview := True;
  Self.ClientWidth := ANCHO_PAPEL_PIXELS + 30;
  Image1.Picture.Bitmap.Width := ANCHO_PAPEL_PIXELS;
  Image1.Picture.Bitmap.Height := 2000; // Altura inicial
  Image1.Width := ANCHO_PAPEL_PIXELS;
  Image1.Height := 2000;
  FCanvas := Image1.Picture.Bitmap.Canvas;
  // Fondo blanco (papel)
  FCanvas.Brush.Color := clWhite;
  FCanvas.FillRect(Rect(0,
                        0,
                        Image1.Picture.Bitmap.Width,
                        Image1.Picture.Bitmap.Height));
  // DIBUJAR BORDE DEL PAPEL PARA DEBUG
  FCanvas.Pen.Color := clRed;
  FCanvas.Pen.Width := 1;
  FCanvas.Rectangle(0, 0, ANCHO_PAPEL_PIXELS, Image1.Picture.Bitmap.Height);
  // Estado inicial
  FCurrentY := MARGEN_PIXELS;
  FFuenteActual := 0;
  FNegrita := False;
  FSubrayado := False;
  FAlineacion := 0; // Izquierda
  FTamanoAncho := 1;
  FTamanoAlto := 1;
  FInverso := False;
  FQRTexto := '';
  FQRTamanoModulo := 8;
  FQRNivelError := 48;
end;

procedure TFormVisualizador.FormDestroy(Sender: TObject);
begin
  // Limpieza automática
end;

procedure TFormVisualizador.CargarYMostrar(const Comandos: string);
begin
  ProcesarComandosESCPOS(Comandos);
  FComandos := Comandos;
  // Ajustar altura de la imagen al contenido
  Image1.Picture.Bitmap.Height := FCurrentY + 50;
  Image1.Height := FCurrentY + 50;
end;

procedure TFormVisualizador.ProcesarComandosESCPOS(const Comandos: string);
var
  i: Integer;
  BufferTexto: string;
  function LeerByte: Byte;
  begin
    Inc(i);
    if i <= Length(Comandos) then
      Result := Ord(Comandos[i])
    else
      Result := 0;
  end;
  function LeerWord: Word;
  var
    Lo, Hi: Byte;
  begin
    Lo := LeerByte;
    Hi := LeerByte;
    Result := Lo + (Hi shl 8);
  end;
begin
  i := 1;
  BufferTexto := '';
  while i <= Length(Comandos) do
  begin
    case Comandos[i] of
      #27: // ESC
        begin
          Inc(i);
          if i > Length(Comandos) then Break;
          case Comandos[i] of
            '@': // Inicializar
              begin
                FFuenteActual := 0;
                FNegrita := False;
                FSubrayado := False;
                FAlineacion := 0;
                FTamanoAncho := 1;
                FTamanoAlto := 1;
                FInverso := False;
              end;
            'M', 'm': // Seleccionar fuente
              begin
                FFuenteActual := LeerByte;
                if FFuenteActual > 2 then FFuenteActual := 1;
              end;
            'E': // Negrita on/off
              begin
                FNegrita := LeerByte <> 0;
              end;
            '-': // Subrayado on/off
              begin
                var Modo := LeerByte;
                FSubrayado := Modo <> 0;
              end;
            'a': // Alineación
              begin
                FAlineacion := LeerByte;
                if FAlineacion > 2 then FAlineacion := 0;
              end;
            'd': // Saltar n líneas
              begin
                if BufferTexto <> '' then
                begin
                  ImprimirTexto(BufferTexto);
                  BufferTexto := '';
                end;
                var Lineas := LeerByte;
                FCurrentY := FCurrentY + (Lineas * ObtenerAltoLinea);
              end;
            '*': // Gráficos raster
              begin
                if BufferTexto <> '' then
                begin
                  ImprimirTexto(BufferTexto);
                  BufferTexto := '';
                end;
                var Modo := LeerByte;
                var Ancho := LeerWord;
                var BytesPorLinea := (Ancho + 7) div 8;
                // Leer datos de imagen (una línea)
                var DatosImagen := '';
                for var j := 1 to BytesPorLinea do
                  DatosImagen := DatosImagen + Char(LeerByte);
                ImprimirImagenRaster(DatosImagen, Ancho, 1);
              end;
            'i': // Cortar papel
              begin
                // Visual: dibujar línea de corte
                FCanvas.Pen.Color := clGray;
                FCanvas.Pen.Style := psDash;
                FCanvas.MoveTo(0, FCurrentY + 10);
                FCanvas.LineTo(ANCHO_PAPEL_PIXELS, FCurrentY + 10);
                FCurrentY := FCurrentY + 20;
              end;
            'p': // Abrir cajón (ignorar)
              begin
                Inc(i, 3); // Saltar parámetros
              end;
          end;
        end;
      #29: // GS
        begin
          Inc(i);
          if i > Length(Comandos) then Break;
          case Comandos[i] of
            '!': // Tamaño de carácter
              begin
                var Valor := LeerByte;
                FTamanoAncho := (Valor and $0F) + 1;
                FTamanoAlto := ((Valor shr 4) and $07) + 1;
                if FTamanoAncho > 8 then FTamanoAncho := 1;
                if FTamanoAlto > 8 then FTamanoAlto := 1;
              end;
            'B': // Modo blanco/negro invertido
              begin
                FInverso := LeerByte <> 0;
              end;
             '(': // Comandos función (incluye QR)
              begin
                Inc(i);
                if i > Length(Comandos) then Break;
                if Comandos[i] = 'k' then // Comando QR
                begin
                  var pL := LeerByte;
                  var pH := LeerByte;
                  var DataLength := pL + (pH * 256);
                  var Fn := LeerByte; // Función
                  var Cn := LeerByte; // Código de función
                  case Cn of
                    65: // 'A' - Seleccionar modelo (ignorar)
                      begin
                        for var j := 1 to DataLength - 2 do
                          LeerByte;
                      end;
                    67: // 'C' - Tamaño del módulo
                      begin
                        FQRTamanoModulo := LeerByte;
                        for var j := 1 to DataLength - 3 do
                          LeerByte;
                      end;
                    69: // 'E' - Nivel de corrección de errores
                      begin
                        FQRNivelError := LeerByte;
                        for var j := 1 to DataLength - 3 do
                          LeerByte;
                      end;
                    80: // 'P' - Almacenar datos
                      begin
                        // Leer el texto del QR
                        //(saltar primeros 3 bytes de cabecera)
                        LeerByte; // Saltar byte adicional
                        FQRTexto := '';
                        for var j := 1 to DataLength - 3 do
                          FQRTexto := FQRTexto + Char(LeerByte);
                      end;
                    81: // 'Q' - Imprimir QR
                      begin
                        for var j := 1 to DataLength - 2 do
                          LeerByte;
                        // Imprimir texto pendiente
                        if BufferTexto <> '' then
                        begin
                          ImprimirTexto(BufferTexto);
                          BufferTexto := '';
                        end;
                        // Dibujar el QR
                        DibujarQRCode;
                        FQRTexto := ''; // Limpiar después de imprimir
                      end;
                  else
                    // Comando desconocido, saltar datos
                    for var j := 1 to DataLength - 2 do
                      LeerByte;
                  end;
                end
                else
                begin
                  // Otro comando con paréntesis, saltar
                  var pL := LeerByte;
                  var pH := LeerByte;
                  var DataLength := pL + (pH * 256);
                  for var j := 1 to DataLength do
                    LeerByte;
                end;
              end;
            'v': // Imprimir imagen raster (formato GS v 0)
              begin
                Inc(i);
                if i > Length(Comandos) then Break;
                if Comandos[i] = '0' then
                begin
                  var Modo := LeerByte;
                  var AnchoBytes := LeerWord;
                  var Alto := LeerWord;
                  if BufferTexto <> '' then
                  begin
                    ImprimirTexto(BufferTexto);
                    BufferTexto := '';
                  end;
                  // Leer datos completos de imagen
                  var DatosImagen := '';
                  for var j := 1 to AnchoBytes * Alto do
                    DatosImagen := DatosImagen + Char(LeerByte);
                  // Procesar imagen completa
                  var AnchoPixels := AnchoBytes * 8;
                  var X, Y: Integer;
                  var StartX: Integer;
                  // Calcular posición X según alineación
                  case FAlineacion of
                    1: StartX := (ANCHO_PAPEL_PIXELS - AnchoPixels) div 2;
                    2: StartX := ANCHO_PAPEL_PIXELS - AnchoPixels -
                                 MARGEN_PIXELS; // Derecha
                  else
                    StartX := MARGEN_PIXELS; // Izquierda
                  end;
                  for Y := 0 to Alto - 1 do
                  begin
                    for X := 0 to AnchoPixels - 1 do
                    begin
                      var ByteIndex := Y * AnchoBytes + (X div 8);
                      var BitIndex := 7 - (X mod 8);
                      if (ByteIndex < Length(DatosImagen)) and
                         ((Ord(DatosImagen[ByteIndex + 1]) and
                         (1 shl BitIndex)) <> 0) then
                      begin
                        FCanvas.Pixels[StartX + X, FCurrentY + Y] := clBlack;
                      end;
                    end;
                  end;
                  FCurrentY := FCurrentY + Alto;
                end;
              end;
          end;
        end;
      #10: // LF - Nueva línea
        begin
          if BufferTexto <> '' then
          begin
            ImprimirTexto(BufferTexto);
            BufferTexto := '';
          end;
          NuevaLinea;
        end;
      #13: // CR - Retorno de carro (ignorar en este contexto)
        begin
          // Normalmente se ignora
        end;
      #9: // TAB
        begin
          BufferTexto := BufferTexto + '    '; // 4 espacios
        end;
    else
      // Caracteres imprimibles
      if Ord(Comandos[i]) >= 32 then
          BufferTexto := BufferTexto + Comandos[i];
    end;
    Inc(i);
  end;
  // Imprimir texto restante
  if BufferTexto <> '' then
    ImprimirTexto(BufferTexto);
end;

procedure TFormVisualizador.AjustarFuente;
var
  LogFont: TLogFont;
  AlturaPixels: Integer;
begin
  // 1. Determinar altura en PIXELES reales (no puntos)
  // Fuente A suele ser 24px alto, B 17px alto
  case FFuenteActual of
    0: AlturaPixels := 24; // Fuente A (12x24)
    1: AlturaPixels := 17; // Fuente B (9x17)
    2: AlturaPixels := 14; // Fuente C
  else
    AlturaPixels := 17;
  end;
  // Aplicar multiplicadores de tamaño ESC/POS
  AlturaPixels := AlturaPixels * FTamanoAlto;
  // 2. Obtener la estructura LogFont actual del Canvas
  if GetObject(FCanvas.Font.Handle, SizeOf(TLogFont), @LogFont) = 0 then
  begin
    // Fallback si falla, llenamos lo básico
    FillChar(LogFont, SizeOf(LogFont), 0);
    StrPCopy(LogFont.lfFaceName, 'Courier New');
  end;
  // 3. Configuración CRÍTICA para nitidez
  LogFont.lfHeight := -AlturaPixels;
  LogFont.lfWidth  := 0;
  // Fuerza a NO usar suavizado (bordes duros, como la impresora térmica)
  LogFont.lfQuality := NONANTIALIASED_QUALITY;
  // Peso de la fuente (Negrita)
  if FNegrita then
    LogFont.lfWeight := FW_BOLD
  else
    LogFont.lfWeight := FW_NORMAL;
  // Subrayado
  if FSubrayado then
    LogFont.lfUnderline := 1
  else
    LogFont.lfUnderline := 0;
  // Nombre de la fuente (Courier New o Consolas van bien para monoespaciado)
  StrPCopy(LogFont.lfFaceName, 'Consolas');
  // 4. Asignar la nueva fuente al Canvas
  FCanvas.Font.Handle := CreateFontIndirect(LogFont);
  FCanvas.Font.Color := clBlack;
  FCanvas.Brush.Style := bsClear;
end;

function TFormVisualizador.ObtenerAltoLinea: Integer;
begin
  case FFuenteActual of
    0: Result := FUENTE_A_ALTO;
    1: Result := FUENTE_B_ALTO;
    2: Result := FUENTE_C_ALTO;
  else
    Result := FUENTE_B_ALTO;
  end;
  Result := Result * FTamanoAlto;
end;

procedure TFormVisualizador.ImprimirTexto(const Texto: string);
var
  X: Integer;
  TextoWidth: Integer;
begin
  if Texto = '' then Exit;
  AjustarFuente;
  // Windows nos dice el ancho real exacto de la frase
  TextoWidth := FCanvas.TextWidth(Texto);
  case FAlineacion of
    0: X := MARGEN_PIXELS;
    1: X := (ANCHO_PAPEL_PIXELS - TextoWidth) div 2;
    2: X := ANCHO_PAPEL_PIXELS - TextoWidth - MARGEN_PIXELS;
  else
    X := MARGEN_PIXELS;
  end;
  if FInverso then
  begin
    FCanvas.Brush.Style := bsSolid;
    FCanvas.Brush.Color := clBlack;
    FCanvas.Font.Color := clWhite;
  end
  else
  begin
    FCanvas.Brush.Style := bsClear;
    FCanvas.Font.Color := clBlack;
  end;
  FCanvas.TextOut(X, FCurrentY, Texto);
  FCanvas.Brush.Style := bsClear;
end;

procedure TFormVisualizador.NuevaLinea;
begin
  FCurrentY := FCurrentY + ObtenerAltoLinea;
end;

procedure TFormVisualizador.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
    VK_F6:
      btnPNGClick(nil);
    VK_F7:
      btnPDFClick(nil);
    VK_F8:
      btnImprimirClick(nil);
  end;
  Key := 0;
end;

procedure TFormVisualizador.GuardarPNG(const ARuta: string);
var
  png: TPngImage;
begin
  png := TPngImage.Create;
  try
    png.Assign(Image1.Picture.Bitmap);
    png.SaveToFile(ARuta);
  finally
    FreeAndNil(png);
  end;
end;

procedure TFormVisualizador.ImprimirEnImpresora;
var
  pd: TPrintDialog;
  bmp: TBitmap;
  AnchoImp, AltoImp: Integer;
  MargenIzq, MargenSup: Integer;
  DPI_X, DPI_Y: Integer;
begin
  // Copiar imagen a pf24bit y enviar a impresora con diálogo
  pd := TPrintDialog.Create(Self);
  try
    if pd.Execute then
    begin
      bmp := TBitmap.Create;
      try
        bmp.PixelFormat := pf24bit;
        bmp.Width := Image1.Picture.Bitmap.Width;
        bmp.Height := FCurrentY + 10;
        bmp.Canvas.Brush.Color := clWhite;
        bmp.Canvas.FillRect(Rect(0, 0, bmp.Width, bmp.Height));
        bmp.Canvas.Draw(0, 0, Image1.Picture.Bitmap);

        Printer.BeginDoc;
        try
          // 1. Obtener los puntos por pulgada (DPI) de la impresora seleccionada
          DPI_X := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
          DPI_Y := GetDeviceCaps(Printer.Handle, LOGPIXELSY);

          // 2. Calcular los márgenes (1 cm). 1 pulgada = 2.54 cm
          MargenIzq := Round((1.0 / 2.54) * DPI_X);
          MargenSup := Round((1.0 / 2.54) * DPI_Y);

          // 3. Calcular el ancho y alto a imprimir
          AnchoImp := Printer.PageWidth div 2;
          AltoImp := MulDiv(bmp.Height, AnchoImp, bmp.Width);

          // 4. Dibujar desplazando el rectángulo inicial a las coordenadas del margen
          Printer.Canvas.StretchDraw(
            Rect(MargenIzq, MargenSup, MargenIzq + AnchoImp, MargenSup + AltoImp),
            bmp);
        finally
          Printer.EndDoc;
        end;
      finally
        FreeAndNil(bmp);
      end;
    end;
  finally
    FreeAndNil(pd);
  end;
end;

procedure TFormVisualizador.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

procedure TFormVisualizador.btnImprimirClick(Sender: TObject);
begin
  ImprimirEnImpresora;
end;

procedure TFormVisualizador.btnImprimirTicketClick(Sender: TObject);
var
  pd: TPrintDialog;
  NombreImpresoraElegida: string;
begin
  if FComandos = '' then
  begin
    ShowMessage('No hay comandos ESC/POS para enviar a la impresora.');
    Exit;
  end;

  // 1. Mostrar diálogo para elegir la impresora
  pd := TPrintDialog.Create(Self);
  try
    if not pd.Execute then
      Exit; // Si el usuario cancela, salimos

    // Obtener el nombre exacto de la impresora seleccionada
    NombreImpresoraElegida := Printer.Printers[Printer.PrinterIndex];
  finally
    FreeAndNil(pd);
  end;

  // 2. Usar tu librería para enviar el ticket de forma nativa
  try
    EnviarComandoRAW(NombreImpresoraElegida, FComandos);
    ShowMessage('Ticket enviado correctamente a: ' + NombreImpresoraElegida);
  except
    on E: Exception do
      ShowMessage('Error al imprimir: ' + E.Message);
  end;
end;

procedure TFormVisualizador.btnPDFClick(Sender: TObject);
var
  sSrc: string;
begin
  sSrc := FRutaPDFReal;
  if (sSrc = '') or (not FileExists(sSrc)) then
  begin
    ShowMessage('No se encuentra el PDF original para copiar.');
    Exit;
  end;
  SaveDialog1.Filter := 'PDF|*.pdf';
  SaveDialog1.DefaultExt := 'pdf';
  SaveDialog1.FileName := ExtractFileName(sSrc);
  if SaveDialog1.Execute then
  begin
    TFile.Copy(sSrc, SaveDialog1.FileName, True);
    ShowMessage('PDF guardado en: ' + SaveDialog1.FileName);
  end;
end;

procedure TFormVisualizador.btnPNGClick(Sender: TObject);
begin
  SaveDialog1.Filter := 'PNG|*.png';
  SaveDialog1.DefaultExt := 'png';
  SaveDialog1.FileName := 'Ticket_' +
    FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.png';
  if SaveDialog1.Execute then
  begin
    GuardarPNG(SaveDialog1.FileName);
    ShowMessage('PNG guardado en: ' + SaveDialog1.FileName);
  end;
end;

end.
