{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionPedidoOriginal                }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presenta las paginas TIFF del pedido original asociado a una sesion.      }
{    Encapsula carga, navegacion, zoom y arrastre sin conocer el formulario.   }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionPedidoOriginal;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  cxButtons,
  cxLabel;

type
  TObtenerSesionPedidoOriginal = reference to function(
    out ASerie, ANumero: string): Boolean;

  TEntornoVisorPedidoOriginalSesion = record
    Contenedor: TScrollBox;
    Imagen: TImage;
    EtiquetaPagina: TcxLabel;
    BotonAnterior: TcxButton;
    BotonSiguiente: TcxButton;
    BotonAlejar: TcxButton;
    BotonAcercar: TcxButton;
    BotonAjustar: TcxButton;
    BotonZoomReal: TcxButton;
    ObtenerDirectorio: TFunc<string>;
    ObtenerSesion: TObtenerSesionPedidoOriginal;
  end;

  TVisorPedidoOriginalSesion = class
  private
    FEntorno: TEntornoVisorPedidoOriginalSesion;
    FPaginas: TArray<string>;
    FIndicePagina: Integer;
    FZoom: Double;
    FImagenOriginal: TPicture;
    FArrastrando: Boolean;
    FEventosConectados: Boolean;
    FInicioArrastre: TPoint;
    FInicioScroll: TPoint;
    procedure ConectarEventos;
    procedure DesconectarEventos;
    procedure MostrarPagina(AConservarVista: Boolean = False);
    procedure AplicarZoom(AZoom: Double);
    procedure Ajustar;
    procedure CambiarPagina(ADesplazamiento: Integer);
    procedure PaginaAnteriorClick(Sender: TObject);
    procedure PaginaSiguienteClick(Sender: TObject);
    procedure AlejarClick(Sender: TObject);
    procedure AcercarClick(Sender: TObject);
    procedure AjustarClick(Sender: TObject);
    procedure ZoomRealClick(Sender: TObject);
    procedure ImagenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImagenMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ImagenMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ContenedorMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  public
    constructor Create(const AEntorno: TEntornoVisorPedidoOriginalSesion);
    destructor Destroy; override;
    procedure Cargar;
    procedure CargarSiVacio;
    function CantidadPaginas: Integer;
  end;

function LimitarZoomPedidoOriginal(AZoom: Double): Double;
function ResolverIndicePedidoOriginal(AIndiceActual, ADesplazamiento,
  ACantidadPaginas: Integer): Integer;

implementation

uses
  inLibArchivosPedidoSesion;

function LimitarZoomPedidoOriginal(AZoom: Double): Double;
begin
  Result := AZoom;
  if Result < 0.10 then
    Result := 0.10;
  if Result > 5 then
    Result := 5;
end;

function ResolverIndicePedidoOriginal(AIndiceActual, ADesplazamiento,
  ACantidadPaginas: Integer): Integer;
var
  iCandidato: Integer;
begin
  Result := AIndiceActual;
  iCandidato := AIndiceActual + ADesplazamiento;
  if (iCandidato >= 0) and (iCandidato < ACantidadPaginas) then
    Result := iCandidato;
end;

procedure ValidarEntornoVisorPedidoOriginal(
  const AEntorno: TEntornoVisorPedidoOriginalSesion);
begin
  if not Assigned(AEntorno.Contenedor) then
    raise EArgumentNilException.Create('AEntorno.Contenedor');
  if not Assigned(AEntorno.Imagen) then
    raise EArgumentNilException.Create('AEntorno.Imagen');
  if not Assigned(AEntorno.EtiquetaPagina) then
    raise EArgumentNilException.Create('AEntorno.EtiquetaPagina');
  if not Assigned(AEntorno.BotonAnterior) then
    raise EArgumentNilException.Create('AEntorno.BotonAnterior');
  if not Assigned(AEntorno.BotonSiguiente) then
    raise EArgumentNilException.Create('AEntorno.BotonSiguiente');
  if not Assigned(AEntorno.BotonAlejar) then
    raise EArgumentNilException.Create('AEntorno.BotonAlejar');
  if not Assigned(AEntorno.BotonAcercar) then
    raise EArgumentNilException.Create('AEntorno.BotonAcercar');
  if not Assigned(AEntorno.BotonAjustar) then
    raise EArgumentNilException.Create('AEntorno.BotonAjustar');
  if not Assigned(AEntorno.BotonZoomReal) then
    raise EArgumentNilException.Create('AEntorno.BotonZoomReal');
  if not Assigned(AEntorno.ObtenerDirectorio) then
    raise EArgumentNilException.Create('AEntorno.ObtenerDirectorio');
  if not Assigned(AEntorno.ObtenerSesion) then
    raise EArgumentNilException.Create('AEntorno.ObtenerSesion');
end;

constructor TVisorPedidoOriginalSesion.Create(
  const AEntorno: TEntornoVisorPedidoOriginalSesion);
begin
  inherited Create;
  ValidarEntornoVisorPedidoOriginal(AEntorno);
  FEntorno := AEntorno;
  FImagenOriginal := TPicture.Create;
  FZoom := 1;
  ConectarEventos;
end;

destructor TVisorPedidoOriginalSesion.Destroy;
begin
  DesconectarEventos;
  FreeAndNil(FImagenOriginal);
  inherited Destroy;
end;

procedure TVisorPedidoOriginalSesion.ConectarEventos;
begin
  FEntorno.BotonAnterior.OnClick := PaginaAnteriorClick;
  FEntorno.BotonSiguiente.OnClick := PaginaSiguienteClick;
  FEntorno.BotonAlejar.OnClick := AlejarClick;
  FEntorno.BotonAcercar.OnClick := AcercarClick;
  FEntorno.BotonAjustar.OnClick := AjustarClick;
  FEntorno.BotonZoomReal.OnClick := ZoomRealClick;
  FEntorno.Imagen.OnMouseDown := ImagenMouseDown;
  FEntorno.Imagen.OnMouseMove := ImagenMouseMove;
  FEntorno.Imagen.OnMouseUp := ImagenMouseUp;
  FEntorno.Contenedor.OnMouseWheel := ContenedorMouseWheel;
  FEventosConectados := True;
end;

procedure TVisorPedidoOriginalSesion.DesconectarEventos;
begin
  if FEventosConectados then
  begin
    FEntorno.BotonAnterior.OnClick := nil;
    FEntorno.BotonSiguiente.OnClick := nil;
    FEntorno.BotonAlejar.OnClick := nil;
    FEntorno.BotonAcercar.OnClick := nil;
    FEntorno.BotonAjustar.OnClick := nil;
    FEntorno.BotonZoomReal.OnClick := nil;
    FEntorno.Imagen.OnMouseDown := nil;
    FEntorno.Imagen.OnMouseMove := nil;
    FEntorno.Imagen.OnMouseUp := nil;
    FEntorno.Contenedor.OnMouseWheel := nil;
    FEventosConectados := False;
  end;
end;

procedure TVisorPedidoOriginalSesion.Cargar;
var
  sNumero: string;
  sSerie: string;
begin
  FPaginas := nil;
  FIndicePagina := 0;
  FImagenOriginal.Assign(nil);
  FEntorno.Imagen.Picture.Assign(nil);
  if FEntorno.ObtenerSesion(sSerie, sNumero) then
    FPaginas := ListarPaginasPedidoSesion(
      FEntorno.ObtenerDirectorio(),
      sSerie,
      sNumero);
  MostrarPagina;
end;

procedure TVisorPedidoOriginalSesion.CargarSiVacio;
begin
  if Length(FPaginas) = 0 then
    Cargar;
end;

function TVisorPedidoOriginalSesion.CantidadPaginas: Integer;
begin
  Result := Length(FPaginas);
end;

procedure TVisorPedidoOriginalSesion.MostrarPagina(
  AConservarVista: Boolean);
var
  iScrollHorizontal: Integer;
  iScrollVertical: Integer;
  oImagen: TWICImage;
  rZoomAnterior: Double;
  sFichero: string;
begin
  rZoomAnterior := FZoom;
  iScrollHorizontal := FEntorno.Contenedor.HorzScrollBar.Position;
  iScrollVertical := FEntorno.Contenedor.VertScrollBar.Position;
  FEntorno.Imagen.Picture.Assign(nil);
  FImagenOriginal.Assign(nil);
  if (FIndicePagina >= 0) and
     (FIndicePagina <= High(FPaginas)) then
  begin
    sFichero := FPaginas[FIndicePagina];
    if FileExists(sFichero) then
    begin
      oImagen := TWICImage.Create;
      try
        oImagen.LoadFromFile(sFichero);
        FImagenOriginal.Assign(oImagen);
        FEntorno.Imagen.Picture.Assign(FImagenOriginal);
      finally
        oImagen.Free;
      end;
      if AConservarVista then
      begin
        AplicarZoom(rZoomAnterior);
        FEntorno.Contenedor.HorzScrollBar.Position := iScrollHorizontal;
        FEntorno.Contenedor.VertScrollBar.Position := iScrollVertical;
      end
      else
        Ajustar;
    end;
  end;
  if Length(FPaginas) = 0 then
    FEntorno.EtiquetaPagina.Caption := 'Sin páginas TIFF importadas'
  else
    FEntorno.EtiquetaPagina.Caption := Format(
      'Página %d de %d · %.0f%%',
      [FIndicePagina + 1, Length(FPaginas), FZoom * 100]);
  FEntorno.BotonAnterior.Enabled := FIndicePagina > 0;
  FEntorno.BotonSiguiente.Enabled :=
    FIndicePagina < High(FPaginas);
end;

procedure TVisorPedidoOriginalSesion.AplicarZoom(AZoom: Double);
begin
  FZoom := LimitarZoomPedidoOriginal(AZoom);
  if Assigned(FImagenOriginal.Graphic) and
     (not FImagenOriginal.Graphic.Empty) then
  begin
    FEntorno.Imagen.Width := Round(FImagenOriginal.Width * FZoom);
    FEntorno.Imagen.Height := Round(FImagenOriginal.Height * FZoom);
    if FEntorno.Imagen.Width < FEntorno.Contenedor.ClientWidth then
      FEntorno.Imagen.Left :=
        (FEntorno.Contenedor.ClientWidth - FEntorno.Imagen.Width) div 2
    else
      FEntorno.Imagen.Left := 0;
    if FEntorno.Imagen.Height < FEntorno.Contenedor.ClientHeight then
      FEntorno.Imagen.Top :=
        (FEntorno.Contenedor.ClientHeight - FEntorno.Imagen.Height) div 2
    else
      FEntorno.Imagen.Top := 0;
    FEntorno.EtiquetaPagina.Caption := Format(
      'Página %d de %d · %.0f%%',
      [FIndicePagina + 1, Length(FPaginas), FZoom * 100]);
  end;
end;

procedure TVisorPedidoOriginalSesion.Ajustar;
var
  rAlto: Double;
  rAncho: Double;
  rZoom: Double;
begin
  if Assigned(FImagenOriginal.Graphic) and
     (FImagenOriginal.Width > 0) and
     (FImagenOriginal.Height > 0) then
  begin
    rAncho := (FEntorno.Contenedor.ClientWidth - 16) /
      FImagenOriginal.Width;
    rAlto := (FEntorno.Contenedor.ClientHeight - 16) /
      FImagenOriginal.Height;
    rZoom := rAncho;
    if rAlto < rZoom then
      rZoom := rAlto;
    AplicarZoom(rZoom);
  end;
end;

procedure TVisorPedidoOriginalSesion.CambiarPagina(
  ADesplazamiento: Integer);
var
  iNueva: Integer;
begin
  iNueva := ResolverIndicePedidoOriginal(
    FIndicePagina,
    ADesplazamiento,
    Length(FPaginas));
  if iNueva <> FIndicePagina then
  begin
    FIndicePagina := iNueva;
    MostrarPagina(True);
  end;
end;

procedure TVisorPedidoOriginalSesion.PaginaAnteriorClick(Sender: TObject);
begin
  CambiarPagina(-1);
end;

procedure TVisorPedidoOriginalSesion.PaginaSiguienteClick(Sender: TObject);
begin
  CambiarPagina(1);
end;

procedure TVisorPedidoOriginalSesion.AlejarClick(Sender: TObject);
begin
  AplicarZoom(FZoom / 1.20);
end;

procedure TVisorPedidoOriginalSesion.AcercarClick(Sender: TObject);
begin
  AplicarZoom(FZoom * 1.20);
end;

procedure TVisorPedidoOriginalSesion.AjustarClick(Sender: TObject);
begin
  Ajustar;
end;

procedure TVisorPedidoOriginalSesion.ZoomRealClick(Sender: TObject);
begin
  AplicarZoom(1);
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FArrastrando := True;
    FInicioArrastre := FEntorno.Imagen.ClientToScreen(Point(X, Y));
    FInicioScroll := Point(
      FEntorno.Contenedor.HorzScrollBar.Position,
      FEntorno.Contenedor.VertScrollBar.Position);
    FEntorno.Imagen.Cursor := crSizeAll;
  end;
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  PuntoActual: TPoint;
begin
  if FArrastrando and (ssLeft in Shift) then
  begin
    PuntoActual := FEntorno.Imagen.ClientToScreen(Point(X, Y));
    FEntorno.Contenedor.HorzScrollBar.Position :=
      FInicioScroll.X - (PuntoActual.X - FInicioArrastre.X);
    FEntorno.Contenedor.VertScrollBar.Position :=
      FInicioScroll.Y - (PuntoActual.Y - FInicioArrastre.Y);
  end
  else if FArrastrando then
    FArrastrando := False;
end;

procedure TVisorPedidoOriginalSesion.ImagenMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FArrastrando := False;
    FEntorno.Imagen.Cursor := crHandPoint;
  end;
end;

procedure TVisorPedidoOriginalSesion.ContenedorMouseWheel(
  Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta > 0 then
    AplicarZoom(FZoom * 1.10)
  else if WheelDelta < 0 then
    AplicarZoom(FZoom / 1.10);
  Handled := True;
end;

end.
