{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasFicha                                                  }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ficha de una línea de venta. En el listado no caben las diez columnas     }
{    con un tamaño legible en un móvil, así que el detalle completo se ve      }
{    aquí al tocar la fila. La UI se construye por código (sin .fmx).          }
{******************************************************************************}
unit fVentasFicha;

interface

uses
  System.Classes, FMX.Forms, FMX.Controls, FMX.Objects,
  VentasModelo;

type
  TfrmFicha = class(TForm)
  private
    FContenido: TControl;
    FFoto: TImage;
    procedure AgregarDato(const AEtiqueta, AValor: string);
    procedure AgregarSeparador;
    procedure Construir(const ALinea: TLineaVenta;
      const ARutaFoto: string);
    procedure OnCerrarClick(Sender: TObject);
  public
    class procedure Mostrar(AOwner: TComponent;
      const ALinea: TLineaVenta; const ARutaFoto: string);
  end;

implementation

uses
  System.SysUtils, System.Types, System.UITypes, System.IOUtils,
  FMX.Types, FMX.StdCtrls, FMX.Layouts, FMX.Graphics;

const
  cEtiquetaSku = 'SKU';
  cEtiquetaPvp = 'PVP';

resourcestring
  STituloDetalleVenta = 'Detalle de la venta';
  SBotonCerrarDetalleVenta = 'Cerrar';
  SEtiquetaFechaHora = 'Fecha y hora';
  SEtiquetaArticulo = 'Artículo';
  SEtiquetaColor = 'Color';
  SEtiquetaFamilia = 'Familia';
  SEtiquetaTemporada = 'Temporada';
  SEtiquetaProveedor = 'Proveedor';
  SEtiquetaCantidad = 'Cantidad';
  SEtiquetaPrecioCoste = 'Precio coste';
  SEtiquetaDescuento = 'Descuento';
  SEtiquetaPrecioVenta = 'Precio venta';
  SEtiquetaCosteTotal = 'Coste total';
  SEtiquetaTotalLinea = 'Total línea';
  SEtiquetaDocumento = 'Documento';
  SDetalleDocumentoLinea = '%s  línea %s';
  SEtiquetaEmpresa = 'Empresa';
  SEtiquetaEstado = 'Estado';
  SEstadoVentaAnulada = 'VENTA ANULADA';

function Moneda(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.00', AValor) + ' €';
end;

function Cantidad(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.###', AValor);
end;

{ Cada dato es una fila alineada arriba, así que se añaden en el mismo orden
  en que se quieren ver: la primera que se crea queda la primera. }
procedure TfrmFicha.AgregarDato(const AEtiqueta, AValor: string);
var
  lblEtiqueta: TLabel;
  lblValor: TLabel;
  layFila: TLayout;
begin
  layFila := TLayout.Create(Self);
  layFila.Parent := FContenido;
  layFila.Align := TAlignLayout.Top;
  layFila.Height := 34;
  layFila.Margins.Bottom := 2;
  lblEtiqueta := TLabel.Create(Self);
  lblEtiqueta.Parent := layFila;
  lblEtiqueta.Align := TAlignLayout.Left;
  lblEtiqueta.Width := 130;
  lblEtiqueta.Text := AEtiqueta;
  lblEtiqueta.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblEtiqueta.StyledSettings :=
    lblEtiqueta.StyledSettings - [TStyledSetting.FontColor];
  lblValor := TLabel.Create(Self);
  lblValor.Parent := layFila;
  lblValor.Align := TAlignLayout.Client;
  lblValor.Text := AValor;
  lblValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblValor.StyledSettings :=
    lblValor.StyledSettings - [TStyledSetting.Style];
end;

procedure TfrmFicha.AgregarSeparador;
var
  linSep: TLine;
begin
  linSep := TLine.Create(Self);
  linSep.Parent := FContenido;
  linSep.Align := TAlignLayout.Top;
  linSep.Height := 9;
  linSep.LineType := TLineType.Top;
  linSep.Margins.Bottom := 6;
end;

procedure TfrmFicha.Construir(const ALinea: TLineaVenta;
  const ARutaFoto: string);
var
  bHayFoto: Boolean;
  btnCerrar: TButton;
  lblTitulo: TLabel;
  scbDatos: TVertScrollBox;
begin
  Self.Caption := STituloDetalleVenta;
  btnCerrar := TButton.Create(Self);
  btnCerrar.Parent := Self;
  btnCerrar.Align := TAlignLayout.Bottom;
  btnCerrar.Height := 52;
  btnCerrar.Margins.Rect := RectF(12, 8, 12, 12);
  btnCerrar.Text := SBotonCerrarDetalleVenta;
  btnCerrar.OnClick := OnCerrarClick;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 52;
  lblTitulo.Margins.Rect := RectF(12, 10, 12, 0);
  lblTitulo.Text := ALinea.TituloLinea;
  lblTitulo.TextSettings.Font.Size := 19;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  lblTitulo.WordWrap := True;
  FFoto := TImage.Create(Self);
  FFoto.Parent := Self;
  FFoto.Align := TAlignLayout.Top;
  FFoto.Height := 190;
  FFoto.Margins.Rect := RectF(12, 6, 12, 6);
  FFoto.WrapMode := TImageWrapMode.Fit;
  bHayFoto := False;
  if (ARutaFoto <> '') and TFile.Exists(ARutaFoto) then
  begin
    // La caché la escribe otro hilo: un PNG corrupto no debe tumbar la ficha.
    try
      FFoto.Bitmap.LoadFromFile(ARutaFoto);
      bHayFoto := True;
    except
      bHayFoto := False;
    end;
  end;
  if not bHayFoto then
    FFoto.Height := 0;
  scbDatos := TVertScrollBox.Create(Self);
  scbDatos.Parent := Self;
  scbDatos.Align := TAlignLayout.Client;
  scbDatos.Margins.Rect := RectF(12, 0, 12, 0);
  FContenido := scbDatos;
  AgregarDato(SEtiquetaFechaHora, ALinea.Fecha + '  ' + ALinea.Hora);
  AgregarDato(SEtiquetaArticulo, ALinea.Articulo);
  AgregarDato(cEtiquetaSku, ALinea.Sku);
  AgregarDato(SEtiquetaColor, ALinea.Color);
  AgregarDato(SEtiquetaFamilia, ALinea.Familia);
  AgregarDato(SEtiquetaTemporada, ALinea.Temporada);
  AgregarDato(SEtiquetaProveedor, ALinea.Proveedor);
  AgregarSeparador;
  AgregarDato(SEtiquetaCantidad, Cantidad(ALinea.Cantidad));
  AgregarDato(SEtiquetaPrecioCoste, Moneda(ALinea.PrecioCoste));
  AgregarDato(cEtiquetaPvp, Moneda(ALinea.Pvp));
  AgregarDato(SEtiquetaDescuento,
    FormatFloat('#,##0.##', ALinea.PorcentajeDescuento) + ' %   (' +
    Moneda(ALinea.ImporteDescuento) + ')');
  AgregarDato(SEtiquetaPrecioVenta, Moneda(ALinea.PrecioVenta));
  AgregarDato(SEtiquetaCosteTotal, Moneda(ALinea.TotalCoste));
  AgregarDato(SEtiquetaTotalLinea, Moneda(ALinea.TotalLinea));
  AgregarSeparador;
  AgregarDato(SEtiquetaDocumento,
    Format(SDetalleDocumentoLinea, [ALinea.Documento, ALinea.Linea]));
  AgregarDato(SEtiquetaEmpresa, ALinea.Empresa);
  if ALinea.Anulada then
    AgregarDato(SEtiquetaEstado, SEstadoVentaAnulada);
end;

procedure TfrmFicha.OnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

class procedure TfrmFicha.Mostrar(AOwner: TComponent;
  const ALinea: TLineaVenta; const ARutaFoto: string);
var
  frm: TfrmFicha;
begin
  frm := TfrmFicha.CreateNew(AOwner);
  try
    frm.Construir(ALinea, ARutaFoto);
  except
    FreeAndNil(frm);
    raise;
  end;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      // Se libera fuera del propio callback: FMX sigue tocando el
      // formulario cuando este vuelve.
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.
