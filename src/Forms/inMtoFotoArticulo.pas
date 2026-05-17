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
  System.Classes, System.StrUtils, Data.DB,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Imaging.PngImage,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit, cxLabel,
  cxDropDownEdit, cxRadioGroup, cxGroupBox, cxButtons,
  JvComponentBase, JvEnterTab,
  inLibFotos;

type
  /// Firma del callback que la pantalla usa para repreguntar al Mto
  /// padre cual es el par (articulo, sku) activo cada vez que cambia
  /// el registro.
  TResolverArtSkuProc =
    procedure(out ACodArt, ACodSku: string) of object;

  TfrmFotoArticulo = class(TfrmBase)
    pnlTop          : TPanel;
    rgResolucion    : TcxRadioGroup;
    lblOrigen       : TcxLabel;
    lblNivel        : TcxLabel;
    cbbNivelSku     : TcxComboBox;
    pnlImage        : TPanel;
    imgFoto         : TImage;
    btnCambiarArt   : TcxButton;
    btnCambiarSku   : TcxButton;
    btnQuitar       : TcxButton;
    btnRotarIzq     : TcxButton;
    btnRotarDer     : TcxButton;
    dlgAbrirFoto    : TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure rgResolucionPropertiesEditValueChanged(Sender: TObject);
    procedure btnCambiarArtClick(Sender: TObject);
    procedure btnCambiarSkuClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnRotarIzqClick(Sender: TObject);
    procedure btnRotarDerClick(Sender: TObject);
  private
    FCodigoArt              : string;
    FCodigoSku              : string;
    FUltimaInfo             : TFotoInfo;
    // Auto-refresh: TDataSource del Mto invocante y handler previo del
    // OnDataChange para encadenarlo y poder restaurarlo al cerrar.
    FPadreDataSource        : TDataSource;
    FPadreResolver          : TResolverArtSkuProc;
    FPrevDataChangeHandler  : TDataChangeEvent;
    procedure CargarFotoActual;
    function ResolucionElegida: TFotoResolucion;
    procedure RellenarNivelesSku;
    function ClaveNivelSeleccionado: string;
    procedure DesengancharDataChange;
    procedure OnPadreDataChange(Sender: TObject; Field: TField);
  public
    /// Carga la foto del par (articulo, sku). Llamar tras Create o cuando
    /// se quiera refrescar (al cambiar el registro activo).
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
    /// Engancha la pantalla al `dsTablaG` del Mto invocante para
    /// auto-refresh cuando cambie el registro activo. `AResolver` se
    /// invoca tras cada cambio de registro para obtener el nuevo par
    /// (articulo, sku). Pasar `nil` a `ADataSource` desengancha.
    procedure VincularMtoPadre(ADataSource: TDataSource;
                               AResolver: TResolverArtSkuProc);
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
  FPadreDataSource := nil;
  FPadreResolver   := nil;
  FPrevDataChangeHandler := nil;
end;

procedure TfrmFotoArticulo.FormClose(Sender: TObject;
                                     var Action: TCloseAction);
begin
  inherited;
  DesengancharDataChange;
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
    foSku        : lblOrigen.Caption := 'Foto del SKU: ' + ACodSku;
    foSkuPrefijo : lblOrigen.Caption := 'Foto heredada del grupo: ' +
                                        FUltimaInfo.ClaveResuelta;
    foArticulo   : lblOrigen.Caption := 'Foto heredada del artículo: ' +
                                        ACodArt;
    foSinFoto    : lblOrigen.Caption := 'Sin foto para ' + ACodArt +
                                        IfThen(ACodSku <> '',
                                               ' / ' + ACodSku, '');
  end;
  RellenarNivelesSku;
  CargarFotoActual;
end;

procedure TfrmFotoArticulo.RellenarNivelesSku;
var
  prefijos : TArray<string>;
  i        : Integer;
begin
  cbbNivelSku.Properties.Items.BeginUpdate;
  try
    cbbNivelSku.Properties.Items.Clear;
    if FCodigoSku = '' then
    begin
      lblNivel.Visible    := False;
      cbbNivelSku.Visible := False;
      Exit;
    end;
    lblNivel.Visible    := True;
    cbbNivelSku.Visible := True;
    prefijos := GenerarPrefijosSku(FCodigoSku);
    for i := 0 to High(prefijos) do
      cbbNivelSku.Properties.Items.Add(prefijos[i]);
    if cbbNivelSku.Properties.Items.Count > 0 then
      cbbNivelSku.ItemIndex := 0;  // por defecto: SKU completo
  finally
    cbbNivelSku.Properties.Items.EndUpdate;
  end;
end;

function TfrmFotoArticulo.ClaveNivelSeleccionado: string;
begin
  if (cbbNivelSku.Visible) and (cbbNivelSku.ItemIndex >= 0) then
    Result := cbbNivelSku.Properties.Items[cbbNivelSku.ItemIndex]
  else
    Result := FCodigoSku;
end;

procedure TfrmFotoArticulo.CargarFotoActual;
var
  sRuta : string;
  png   : TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if not FUltimaInfo.Encontrada then Exit;
  sRuta := oFotos.RutaFoto(FUltimaInfo, ResolucionElegida);
  if sRuta = '' then Exit;
  // Las tres copias son siempre PNG.
  png := TPngImage.Create;
  try
    png.LoadFromFile(sRuta);
    imgFoto.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
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
var
  sClave: string;
begin
  inherited;
  if FCodigoSku = '' then
  begin
    ShowMessage('No hay SKU activo. Usa "Cambiar foto del artículo".');
    Exit;
  end;
  sClave := ClaveNivelSeleccionado;
  if not dlgAbrirFoto.Execute then Exit;
  oFotos.Guardar(FCodigoArt, sClave, dlgAbrirFoto.FileName);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnQuitarClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  if MessageDlg('¿Eliminar la foto actual?', mtConfirmation,
                [mbYes, mbNo], 0) <> mrYes then Exit;
  // Borramos exactamente la fila que resolvio (articulo, prefijo o SKU)
  oFotos.Eliminar(FCodigoArt, FUltimaInfo.ClaveResuelta);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnRotarIzqClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  oFotos.Rotar(FCodigoArt, FCodigoSku, False);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnRotarDerClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  oFotos.Rotar(FCodigoArt, FCodigoSku, True);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

// ---------------------------------------------------------------------
//   Auto-refresh: hook al dsTablaG del Mto padre
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.VincularMtoPadre(
  ADataSource: TDataSource; AResolver: TResolverArtSkuProc);
begin
  DesengancharDataChange;
  FPadreDataSource := ADataSource;
  FPadreResolver   := AResolver;
  if Assigned(FPadreDataSource) then
  begin
    FPrevDataChangeHandler  := FPadreDataSource.OnDataChange;
    FPadreDataSource.OnDataChange := OnPadreDataChange;
  end;
end;

procedure TfrmFotoArticulo.DesengancharDataChange;
begin
  if Assigned(FPadreDataSource) then
    FPadreDataSource.OnDataChange := FPrevDataChangeHandler;
  FPadreDataSource := nil;
  FPadreResolver   := nil;
  FPrevDataChangeHandler := nil;
end;

procedure TfrmFotoArticulo.OnPadreDataChange(Sender: TObject; Field: TField);
var
  sArt, sSku: string;
begin
  // Encadenamos al handler previo (si lo habia) para no romper logica
  // existente del Mto.
  if Assigned(FPrevDataChangeHandler) then
    FPrevDataChangeHandler(Sender, Field);
  // Solo refrescamos cuando cambia el registro activo (Field = nil),
  // no en cada cambio de columna.
  if (Field = nil) and Assigned(FPadreResolver) then
  begin
    FPadreResolver(sArt, sSku);
    if (sArt <> FCodigoArt) or (sSku <> FCodigoSku) then
      SetArticuloSku(sArt, sSku);
  end;
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
