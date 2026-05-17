{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFotoArticulo                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario flotante (no modal, top-most) que muestra la foto del          }
{    articulo o SKU activo en la pantalla que lo invoca con Ctrl+Alt+F.        }
{    Permite cambiar entre las resoluciones 300, 600 o real.                   }
{    La carga del bitmap se hace via GDI (TImage + Vcl.Imaging.PngImage).      }
{    Para uso dentro de un formulario modal existe el wrapper                  }
{    `inMtoModalFotoArticulo.TfrmModalFotoArticulo`.                           }
{******************************************************************************}
unit inMtoFotoArticulo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.StrUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Imaging.PngImage, Vcl.Imaging.Jpeg,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxRadioGroup,
  cxGroupBox, cxButtons, JvComponentBase, JvEnterTab,
  inLibFotos;

type
  TfrmFotoArticulo = class(TfrmBase)
    pnlTop          : TPanel;
    rgResolucion    : TcxRadioGroup;
    lblOrigen       : TcxLabel;
    pnlImage        : TPanel;
    imgFoto         : TImage;
    btnCambiarArt   : TcxButton;
    btnCambiarSku   : TcxButton;
    btnQuitar       : TcxButton;
    dlgAbrirFoto    : TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rgResolucionPropertiesEditValueChanged(Sender: TObject);
    procedure btnCambiarArtClick(Sender: TObject);
    procedure btnCambiarSkuClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
  private
    FCodigoArt    : string;
    FCodigoSku    : string;
    FUltimaInfo   : TFotoInfo;
    procedure CargarFotoActual;
    function ResolucionElegida: TFotoResolucion;
  public
    /// Carga la foto del par (articulo, sku). Llamar tras Create o cuando
    /// se quiera refrescar (al cambiar el registro activo).
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
    property CodigoArt: string read FCodigoArt;
    property CodigoSku: string read FCodigoSku;
  end;

var
  frmFotoArticulo: TfrmFotoArticulo;

/// Atajo: abre `frmFotoArticulo` (lo crea si no existe) y carga el par
/// pasado. Si el formulario ya estaba abierto, lo refresca y lo trae al
/// frente. Llamar desde el handler de Ctrl+Alt+F de los Mtos.
procedure MostrarFotoFlotante(AOwner: TComponent;
                              const ACodArt, ACodSku: string);

implementation

{$R *.dfm}

procedure TfrmFotoArticulo.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position    := poScreenCenter;
  Self.FormStyle   := fsStayOnTop;
  rgResolucion.ItemIndex := 0;  // 300 por defecto
  FUltimaInfo.Clear;
end;

procedure TfrmFotoArticulo.FormClose(Sender: TObject;
                                     var Action: TCloseAction);
begin
  inherited;
  if Self <> frmFotoArticulo then
    Action := caFree
  else
  begin
    // Cerramos pero conservamos la referencia: el siguiente Ctrl+Alt+F
    // crea una nueva instancia limpia.
    Action := caFree;
    frmFotoArticulo := nil;
  end;
end;

function TfrmFotoArticulo.ResolucionElegida: TFotoResolucion;
begin
  case rgResolucion.ItemIndex of
    0: Result := frPx300;
    1: Result := frPx600;
    2: Result := frReal;
  else
    Result := frPx300;
  end;
end;

procedure TfrmFotoArticulo.SetArticuloSku(const ACodArt, ACodSku: string);
begin
  FCodigoArt := ACodArt;
  FCodigoSku := ACodSku;
  FUltimaInfo := oFotos.Resolver(ACodArt, ACodSku);
  case FUltimaInfo.Origen of
    foSku       : lblOrigen.Caption := 'Foto del SKU: ' + ACodSku;
    foArticulo  : lblOrigen.Caption := 'Foto heredada del artículo: ' + ACodArt;
    foSinFoto   : lblOrigen.Caption := 'Sin foto para ' + ACodArt +
                                       IfThen(ACodSku <> '', ' / ' + ACodSku);
  end;
  CargarFotoActual;
end;

procedure TfrmFotoArticulo.CargarFotoActual;
var
  sRuta : string;
  sExt  : string;
  png   : TPngImage;
  jpg   : TJPEGImage;
begin
  imgFoto.Picture.Assign(nil);
  if not FUltimaInfo.Encontrada then Exit;

  sRuta := oFotos.RutaFoto(FUltimaInfo, ResolucionElegida);
  if sRuta = '' then Exit;

  sExt := LowerCase(ExtractFileExt(sRuta));
  if sExt = '.png' then
  begin
    png := TPngImage.Create;
    try
      png.LoadFromFile(sRuta);
      imgFoto.Picture.Assign(png);
    finally
      FreeAndNil(png);
    end;
  end
  else if (sExt = '.jpg') or (sExt = '.jpeg') then
  begin
    jpg := TJPEGImage.Create;
    try
      jpg.LoadFromFile(sRuta);
      imgFoto.Picture.Assign(jpg);
    finally
      FreeAndNil(jpg);
    end;
  end
  else
    imgFoto.Picture.LoadFromFile(sRuta);
end;

procedure TfrmFotoArticulo.rgResolucionPropertiesEditValueChanged(
                                                          Sender: TObject);
begin
  inherited;
  CargarFotoActual;
end;

procedure TfrmFotoArticulo.btnCambiarArtClick(Sender: TObject);
begin
  inherited;
  if FCodigoArt = '' then
  begin
    ShowMessage('No hay artículo activo.');
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  oFotos.Guardar(FCodigoArt, '', dlgAbrirFoto.FileName);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnCambiarSkuClick(Sender: TObject);
begin
  inherited;
  if FCodigoSku = '' then
  begin
    ShowMessage('No hay SKU activo. Usa "Cambiar foto del artículo".');
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  oFotos.Guardar(FCodigoArt, FCodigoSku, dlgAbrirFoto.FileName);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnQuitarClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  if MessageDlg('¿Eliminar la foto actual?', mtConfirmation,
                [mbYes, mbNo], 0) <> mrYes then Exit;
  case FUltimaInfo.Origen of
    foSku       : oFotos.Eliminar(FCodigoArt, FCodigoSku);
    foArticulo  : oFotos.Eliminar(FCodigoArt, '');
  end;
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure MostrarFotoFlotante(AOwner: TComponent;
                              const ACodArt, ACodSku: string);
begin
  if frmFotoArticulo = nil then
    frmFotoArticulo := TfrmFotoArticulo.Create(AOwner);
  frmFotoArticulo.SetArticuloSku(ACodArt, ACodSku);
  if not frmFotoArticulo.Visible then
    frmFotoArticulo.Show
  else
  begin
    frmFotoArticulo.BringToFront;
    if frmFotoArticulo.CanFocus then
      frmFotoArticulo.SetFocus;
  end;
end;

end.
