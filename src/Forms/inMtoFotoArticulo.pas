{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFotoArticulo                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.2.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario flotante (no modal, top-most) que muestra la foto del          }
{    articulo o SKU activo en la pantalla que lo invoca con Ctrl+Alt+F.        }
{    Render por GDI (TImage + Vcl.Imaging.PngImage).                           }
{                                                                              }
{    UI con panel de controles desplegable: por defecto solo se ve la imagen   }
{    y un boton pequeno arriba (▼ Controles). Al pulsarlo se estira hacia     }
{    abajo el panel con resolucion, cambiar foto, rotar y quitar; un nuevo    }
{    click lo encoge. F11 hace lo mismo desde teclado.                         }
{                                                                              }
{    Alt+F12 guarda la geometria de la ventana (igual patron que               }
{    inMtoConsultaOpe), via TLayoutSaver. FormShow restaura.                   }
{                                                                              }
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
  inLibFotos, inLibLayoutForm, inLibAppParam, System.UITypes,
  Vcl.Menus, cxControls, cxMaskEdit;

type
  /// Firma del callback que la pantalla usa para repreguntar al Mto
  /// padre cual es el par (articulo, sku) activo cada vez que cambia
  /// el registro.
  TResolverArtSkuProc =
    procedure(out ACodArt, ACodSku: string) of object;

  TfrmFotoArticulo = class(TfrmBase)
    pnlTop           : TPanel;
    btnToggle        : TcxButton;
    lblOrigen        : TcxLabel;
    pnlControles     : TPanel;
    rgResolucion     : TcxRadioGroup;
    lblNivel         : TcxLabel;
    cbbNivelSku      : TcxComboBox;
    btnCambiarArt    : TcxButton;
    btnCambiarSku    : TcxButton;
    btnQuitar        : TcxButton;
    btnRotarIzq      : TcxButton;
    btnRotarDer      : TcxButton;
    pnlImage         : TPanel;
    imgFoto          : TImage;
    dlgAbrirFoto     : TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure rgResolucionPropertiesEditValueChanged(Sender: TObject);
    procedure btnToggleClick(Sender: TObject);
    procedure btnCambiarArtClick(Sender: TObject);
    procedure btnCambiarSkuClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnRotarIzqClick(Sender: TObject);
    procedure btnRotarDerClick(Sender: TObject);
  private
    FCodigoArt              : string;
    FCodigoSku              : string;
    FUltimaInfo             : TFotoInfo;
    // Persistencia de geometria (igual patron que inMtoConsultaOpe).
    FLayoutLoader           : TLayoutLoader;
    // Auto-refresh: TDataSource del Mto invocante y handler previo del
    // OnDataChange para encadenarlo y poder restaurarlo al cerrar.
    FPadreDataSource        : TDataSource;
    FPadreResolver          : TResolverArtSkuProc;
    FPrevDataChangeHandler  : TDataChangeEvent;
    procedure CargarFotoActual;
    function  ResolucionElegida: TFotoResolucion;
    procedure RellenarNivelesSku;
    function  ClaveNivelSeleccionado: string;
    procedure DesengancharDataChange;
    procedure OnPadreDataChange(Sender: TObject; Field: TField);
    procedure ToggleControles;
    procedure AjustarBotonToggle;
    procedure GuardarLayout;
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
  // poDesigned (no poScreenCenter) para que Left/Top guardados con
  // Alt+F12 no sean sobrescritos al mostrarse el form. Si no hay
  // layout guardado, FormShow centra manualmente.
  Self.Position    := poDesigned;
  Self.FormStyle   := fsStayOnTop;
  Self.KeyPreview  := True;       // para que FormKeyDown vea Alt+F12 / F11
  rgResolucion.ItemIndex := 0;    // 300 por defecto
  FUltimaInfo.Clear;
  FPadreDataSource := nil;
  FPadreResolver   := nil;
  FPrevDataChangeHandler := nil;
  // Por defecto el panel de controles esta encogido.
  pnlControles.Visible := False;
  AjustarBotonToggle;
end;

procedure TfrmFotoArticulo.FormShow(Sender: TObject);
begin
  inherited;
  // Restaura geometria (Left/Top/Width/Height/WindowState) si el
  // usuario la guardo previamente con Alt+F12. Si no hay layout,
  // centramos manualmente en pantalla.
  FLayoutLoader := TLayoutLoader.Create(Self.Name);
  if FLayoutLoader.Disponible then
    FLayoutLoader.RestaurarGeometria(Self)
  else
  begin
    Self.Left := (Screen.Width  - Self.Width)  div 2;
    Self.Top  := (Screen.Height - Self.Height) div 2;
  end;
end;

procedure TfrmFotoArticulo.FormDestroy(Sender: TObject);
begin
  if Assigned(FLayoutLoader) then
    FreeAndNil(FLayoutLoader);
  inherited;
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

procedure TfrmFotoArticulo.FormKeyDown(Sender: TObject; var Key: Word;
                                       Shift: TShiftState);
begin
  inherited;
  // Alt + F12 -> guardar geometria (igual patron que inMtoConsultaOpe).
  if (Key = VK_F12) and (ssAlt in Shift) then
  begin
    GuardarLayout;
    Key := 0;
    Exit;
  end;
  // F11 -> mostrar / ocultar panel de controles (alternativa al boton).
  if Key = VK_F11 then
  begin
    ToggleControles;
    Key := 0;
  end;
end;

procedure TfrmFotoArticulo.GuardarLayout;
var
  saver: TLayoutSaver;
begin
  saver := TLayoutSaver.Create(Self.Name);
  try
    saver.GuardarGeometria(Self);
    saver.PreguntarYGrabar('Foto del artículo / SKU');
  finally
    FreeAndNil(saver);
  end;
end;

// ---------------------------------------------------------------------
//   Panel de controles: estirar / encoger
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.ToggleControles;
begin
  pnlControles.Visible := not pnlControles.Visible;
  AjustarBotonToggle;
end;

procedure TfrmFotoArticulo.AjustarBotonToggle;
begin
  if pnlControles.Visible then
    btnToggle.Caption := '▲ Controles'
  else
    btnToggle.Caption := '▼ Controles';
end;

procedure TfrmFotoArticulo.btnToggleClick(Sender: TObject);
begin
  inherited;
  ToggleControles;
end;

// ---------------------------------------------------------------------
//   Resolucion / carga / etiqueta
// ---------------------------------------------------------------------

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
  // Reflejamos en el caption (titulo de la ventana) solo el codigo del
  // articulo o SKU activo: tanto el contexto como el icono de la
  // barra de tareas ya identifican que es una pantalla de fotos.
  if ACodSku <> '' then
    Self.Caption := ACodSku
  else
    Self.Caption := ACodArt;
  RellenarNivelesSku;
  CargarFotoActual;
end;

procedure TfrmFotoArticulo.RellenarNivelesSku;
// El combo se llena de mas especifico (SKU completo) a menos
// (1 atributo). El indice por defecto lo dicta `appNumAtributosFoto`:
// si vale N, se selecciona el nivel cuya clave incluye N segmentos
// despues del articulo; si N >= total de atributos del SKU, gana el
// SKU completo.
var
  prefijos      : TArray<string>;
  i             : Integer;
  iNumAtribsCfg : Integer;
  iSegmentos    : Integer;
  iIdxDefault   : Integer;
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
    if cbbNivelSku.Properties.Items.Count = 0 then Exit;

    // Default: nivel con `appNumAtributosFoto` atributos. La cantidad
    // de segmentos del SKU completo = numero de '/' + 1 = articulo +
    // N atributos. El prefijo cuyo numero de '/' = appNumAtributosFoto
    // es el que tiene exactamente esa cantidad de atributos.
    iNumAtribsCfg := oAppParams.GetInt('appNumAtributosFoto', 1);
    iIdxDefault   := 0;
    for i := 0 to cbbNivelSku.Properties.Items.Count - 1 do
    begin
      // Numero de atributos = numero de '/' en la clave
      iSegmentos := 0;
      var sCl: string := cbbNivelSku.Properties.Items[i];
      for var c: Char in sCl do
        if c = '/' then Inc(iSegmentos);
      if iSegmentos = iNumAtribsCfg then
      begin
        iIdxDefault := i;
        Break;
      end;
    end;
    cbbNivelSku.ItemIndex := iIdxDefault;
  finally
    cbbNivelSku.Properties.Items.EndUpdate;
  end;
end;

function TfrmFotoArticulo.ClaveNivelSeleccionado: string;
begin
  // Aunque el panel de controles este colapsado, el combo conserva
  // su ItemIndex; usamos siempre el valor del combo si tiene items.
  if (cbbNivelSku.Properties.Items.Count > 0) and
     (cbbNivelSku.ItemIndex >= 0) then
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

// ---------------------------------------------------------------------
//   Botones: cambiar / quitar / rotar
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.btnCambiarArtClick(Sender: TObject);
begin
  inherited;
  if FCodigoArt = '' then
  begin
    ShowMessage('No hay artículo activo.');
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  try
    oFotos.Guardar(FCodigoArt, '', dlgAbrirFoto.FileName);
  except
    on E: Exception do
    begin
      ShowMessage('No se pudo guardar la foto: ' + E.Message);
      Exit;
    end;
  end;
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
  if sClave = '' then
  begin
    ShowMessage('No hay nivel de atributos seleccionado en el combo.');
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  try
    oFotos.Guardar(FCodigoArt, sClave, dlgAbrirFoto.FileName);
  except
    on E: Exception do
    begin
      ShowMessage('No se pudo guardar la foto: ' + E.Message);
      Exit;
    end;
  end;
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
