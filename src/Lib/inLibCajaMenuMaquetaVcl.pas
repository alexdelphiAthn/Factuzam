{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaMenuMaquetaVcl                                       }
{    Tipo:       Librería (maquetación VCL)                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Disposición del menú de caja pensada para caber en 800x600:               }
{      - fila de tres tarjetas grandes (operaciones principales),              }
{      - fila de tres tarjetas compactas (operaciones secundarias),            }
{      - calendario, reloj, fecha, indicador de actividad y tarjeta de salida, }
{      - barra inferior con empresa, almacén y caja.                           }
{    Todo en píxeles lógicos a 96 ppp, escalados al PPI del formulario.        }
{******************************************************************************}
unit inLibCajaMenuMaquetaVcl;

interface

uses
  Vcl.Controls, Vcl.Forms, cxLabel, inLibCajaMenuTarjetaVcl;

type
  TControlesMenuCaja = record
    Logo: TControl;
    Calendario: TWinControl;
    Reloj: TControl;
    Fecha: TcxLabel;
    Empresa: TcxLabel;
    Indicador: TControl;
    /// Tres grandes, tres compactas y la de salir, en ese orden.
    Tarjetas: TArray<TTarjetaMenuCaja>;
  end;

/// Coloca los controles y ajusta ClientWidth/ClientHeight del formulario.
procedure MaquetarMenuCaja(AFormulario: TCustomForm;
  const AControles: TControlesMenuCaja);

/// Quita el tema visual al calendario nativo de Windows y le aplica los
/// colores del skin (con tema, Windows ignora MCM_SETCOLOR).
procedure AplicarColoresCalendario(ACalendario: TWinControl);

implementation

uses
  System.Types, System.Math, Winapi.Windows, Winapi.CommCtrl, Winapi.UxTheme,
  Vcl.Graphics, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxEdit;

const
  // Con el marco más ancho de los skins la ventana queda en unos 786 px.
  ANCHO_CLIENTE   = 752;
  MARGEN          = 16;
  HUECO           = 10;
  ANCHO_LOGO      = 64;
  ALTO_GRANDE     = 116;
  ALTO_COMPACTA   = 56;
  ALTO_EMPRESA    = 34;
  LADO_RELOJ_MIN  = 150;
  LADO_RELOJ_MAX  = 168;
  LADO_INDICADOR  = 44;
  FUENTE_MENU     = 'Source Sans 3';

procedure AplicarColoresCalendario(ACalendario: TWinControl);
var
  oPainter: TcxCustomLookAndFeelPainter;
  cFondo, cTexto, cAcento: TColor;
  hCal: HWND;
begin
  oPainter := RootLookAndFeel.Painter;
  cFondo := ColorToRGB(oPainter.DefaultControlColor);
  cTexto := ColorToRGB(oPainter.DefaultControlTextColor);
  cAcento := ColorToRGB(oPainter.DefaultSelectionColor);
  hCal := ACalendario.Handle;
  SetWindowTheme(hCal, '', '');
  // Sin tema, el control nativo se dibuja con un borde 3D claro.
  SetWindowLong(hCal, GWL_EXSTYLE,
    GetWindowLong(hCal, GWL_EXSTYLE) and not WS_EX_CLIENTEDGE);
  // El círculo rojo de "hoy" es del estilo clásico y desentona.
  SetWindowLong(hCal, GWL_STYLE,
    (GetWindowLong(hCal, GWL_STYLE) and not WS_BORDER) or MCS_NOTODAYCIRCLE);
  SetWindowPos(hCal, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
    SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
  SendMessage(hCal, MCM_SETCOLOR, MCSC_BACKGROUND, cFondo);
  SendMessage(hCal, MCM_SETCOLOR, MCSC_MONTHBK,
    ColorToRGB(dxGetMiddleRGB(cTexto, cFondo, 7)));
  SendMessage(hCal, MCM_SETCOLOR, MCSC_TEXT, cTexto);
  SendMessage(hCal, MCM_SETCOLOR, MCSC_TITLEBK, cAcento);
  SendMessage(hCal, MCM_SETCOLOR, MCSC_TITLETEXT,
    ColorToRGB(oPainter.DefaultSelectionTextColor));
  SendMessage(hCal, MCM_SETCOLOR, MCSC_TRAILINGTEXT,
    ColorToRGB(dxGetMiddleRGB(cTexto, cFondo, 40)));
  InvalidateRect(hCal, nil, True);
end;

procedure EstilarEtiqueta(AEtiqueta: TcxLabel; AAlto: Integer;
  AAlineacionVertical: TcxEditVertAlignment);
begin
  AEtiqueta.AutoSize := False;
  AEtiqueta.Transparent := True;
  AEtiqueta.ParentFont := False;
  AEtiqueta.Style.BorderStyle := ebsNone;
  AEtiqueta.Style.Shadow := False;
  AEtiqueta.Style.Font.Name := FUENTE_MENU;
  AEtiqueta.Style.Font.Style := [fsBold];
  AEtiqueta.Style.Font.Height := -AAlto;
  AEtiqueta.Style.TextColor := RootLookAndFeel.Painter.DefaultControlTextColor;
  AEtiqueta.Properties.LabelEffect := cxleNormal;
  AEtiqueta.Properties.LabelStyle := cxlsNormal;
  AEtiqueta.Properties.LineOptions.Visible := False;
  AEtiqueta.Properties.WordWrap := True;
  AEtiqueta.Properties.Alignment.Vert := AAlineacionVertical;
end;

procedure MaquetarMenuCaja(AFormulario: TCustomForm;
  const AControles: TControlesMenuCaja);
var
  iPPI: Integer;
  iX0, iAnchoRejilla, iAnchoCol, iY, iAltoInfo, iLadoReloj, iCol,
    iFondoInfo: Integer;
  rMinimo: TRect;

  function S(AValor: Integer): Integer;
  begin
    Result := MulDiv(AValor, iPPI, 96);
  end;

  function XCol(AIndice: Integer): Integer;
  begin
    Result := iX0 + AIndice * (iAnchoCol + S(HUECO));
  end;

begin
  Assert(Length(AControles.Tarjetas) = 7);
  iPPI := AFormulario.CurrentPPI;
  AFormulario.ClientWidth := S(ANCHO_CLIENTE);

  iX0 := S(MARGEN + ANCHO_LOGO + 14);
  iAnchoRejilla := S(ANCHO_CLIENTE - MARGEN) - iX0;
  iAnchoCol := (iAnchoRejilla - 2 * S(HUECO)) div 3;

  // Filas de tarjetas
  iY := S(MARGEN);
  for iCol := 0 to 2 do
  begin
    AControles.Tarjetas[iCol].Estilo := etcGrande;
    AControles.Tarjetas[iCol].SetBounds(XCol(iCol), iY, iAnchoCol,
      S(ALTO_GRANDE));
  end;
  Inc(iY, S(ALTO_GRANDE + HUECO));
  for iCol := 0 to 2 do
  begin
    AControles.Tarjetas[3 + iCol].Estilo := etcCompacta;
    AControles.Tarjetas[3 + iCol].SetBounds(XCol(iCol), iY, iAnchoCol,
      S(ALTO_COMPACTA));
  end;
  Inc(iY, S(ALTO_COMPACTA + 18));

  // Calendario: tamaño mínimo que pide el control nativo (ya sin tema).
  AplicarColoresCalendario(AControles.Calendario);
  if SendMessage(AControles.Calendario.Handle, MCM_GETMINREQRECT, 0,
    LPARAM(@rMinimo)) <> 0 then
    AControles.Calendario.SetBounds(XCol(0), iY,
      Max(rMinimo.Width, iAnchoCol), rMinimo.Height)
  else
    AControles.Calendario.SetBounds(XCol(0), iY, iAnchoCol, S(170));
  iAltoInfo := Max(AControles.Calendario.Height, S(LADO_RELOJ_MIN));

  // Reloj centrado en la columna central
  iLadoReloj := Min(Min(iAltoInfo, iAnchoCol), S(LADO_RELOJ_MAX));
  AControles.Reloj.SetBounds(XCol(1) + (iAnchoCol - iLadoReloj) div 2,
    iY + (iAltoInfo - iLadoReloj) div 2, iLadoReloj, iLadoReloj);

  // Fecha arriba y salir abajo en la tercera columna
  EstilarEtiqueta(AControles.Fecha, S(22), taTopJustify);
  AControles.Fecha.SetBounds(XCol(2) + S(4), iY, iAnchoCol - S(4), S(64));
  AControles.Tarjetas[6].Estilo := etcCompacta;
  AControles.Tarjetas[6].SetBounds(XCol(2), iY + iAltoInfo - S(ALTO_COMPACTA),
    iAnchoCol, S(ALTO_COMPACTA));
  iFondoInfo := iY + iAltoInfo;

  // Indicador de actividad centrado entre la fecha y la tarjeta de salida
  AControles.Indicador.SetBounds(
    XCol(2) + (iAnchoCol - S(LADO_INDICADOR)) div 2,
    (AControles.Fecha.BoundsRect.Bottom +
     AControles.Tarjetas[6].Top - S(LADO_INDICADOR)) div 2,
    S(LADO_INDICADOR), S(LADO_INDICADOR));

  // Logo a lo alto de toda la zona de tarjetas e información
  AControles.Logo.SetBounds(S(MARGEN), S(MARGEN), S(ANCHO_LOGO),
    iFondoInfo - S(MARGEN));

  // Barra inferior
  EstilarEtiqueta(AControles.Empresa, S(17), taVCenter);
  AControles.Empresa.Properties.LineOptions.Visible := True;
  AControles.Empresa.Properties.LineOptions.Alignment := cxllaTop;
  AControles.Empresa.SetBounds(S(MARGEN), iFondoInfo + S(14),
    S(ANCHO_CLIENTE - 2 * MARGEN), S(ALTO_EMPRESA));

  AFormulario.ClientHeight := AControles.Empresa.BoundsRect.Bottom + S(10);
end;

end.
