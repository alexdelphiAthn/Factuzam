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
{    articulo o SKU activo en la pantalla que lo invoca con Ctrl+F.        }
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
  System.Classes, System.StrUtils, System.Generics.Collections, Data.DB,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Imaging.PngImage, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  inMtoFrmBase, cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit, cxLabel,
  cxDropDownEdit, cxRadioGroup, cxGroupBox, cxButtons,
  JvComponentBase, JvEnterTab,
  Vcl.Menus, cxControls, cxMaskEdit,
  inLibFotos, inLibFotosNube, inLibLayoutForm,
  System.UITypes;

type
  TResolverArtSkuProc =
    procedure(out ACodArt, ACodSku: string) of object;

  TfrmFotoArticulo = class(TfrmBase)
    pnlTop           : TPanel;
    btnToggle        : TcxButton;
    btnDescargarNube : TcxButton;
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
    btnLayout        : TcxButton;
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
    procedure btnDescargarNubeClick(Sender: TObject);
    procedure btnCambiarArtClick(Sender: TObject);
    procedure btnCambiarSkuClick(Sender: TObject);
    procedure btnQuitarClick(Sender: TObject);
    procedure btnRotarIzqClick(Sender: TObject);
    procedure btnRotarDerClick(Sender: TObject);
    procedure btnLayoutClick(Sender: TObject);
  private
    FCodigoArt              : string;
    FCodigoSku              : string;
    FUltimaInfo             : TFotoInfo;
    // Persistencia de geometria (igual patron que inMtoConsultaOpe).
    FLayoutLoader           : TLayoutLoader;
    // Auto-refresh: lista de DataSources del Mto invocante con el
    // handler previo de OnDataChange por cada uno (para poder
    // restaurarlos al cerrar / re-vincular). Cuando cualquiera dispara
    // OnDataChange(Field = nil) se recarga la foto via FPadreResolver.
    FHooksDataSource        : TList<TPair<TDataSource, TDataChangeEvent>>;
    FPadreResolver          : TResolverArtSkuProc;
    FGpImagen               : TGPImage;
    FRutaFotoActual         : string;
    procedure CargarFotoActual;
    function  ResolucionElegida: TFotoResolucion;
    procedure RellenarNivelesSku;
    function  ClaveNivelSeleccionado: string;
    procedure DesengancharDataChange;
    procedure DesengancharDataSource(ADataSource: TDataSource);
    procedure OnPadreDataChange(Sender: TObject; Field: TField);
    procedure DescargarFotosDeNube;
    procedure PintarFotoGDIPlus;
    procedure RestaurarGeometriaGuardada;
  protected
    procedure Resize; override;
    // Auto-limpieza si alguno de los DataSources hookeados se libera
    // antes que nosotros (al cerrar el Mto que los poseia). Usa el
    // mecanismo nativo FreeNotification de la VCL.
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure ToggleControles;
    procedure AjustarBotonToggle;
    procedure GuardarLayout;
  public
    /// Carga la foto del par (articulo, sku). Llamar tras Create o cuando
    /// se quiera refrescar (al cambiar el registro activo).
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
    /// Engancha la pantalla a uno o varios DataSources del Mto
    /// invocante para auto-refresh cuando cambie el registro activo
    /// en cualquiera de ellos. `AResolver` se invoca tras cada cambio
    /// para obtener el nuevo par (articulo, sku). Pasar un array vacio
    /// desengancha todo. Cada DataSource conserva su handler previo
    /// encadenado, asi no se pisa logica del Mto.
    procedure VincularDataSources(const ADataSources: array of TDataSource;
                                  AResolver: TResolverArtSkuProc);
    /// Atajo retro-compatible: equivale a VincularDataSources con un
    /// solo DataSource. Se mantiene por los call sites que aun usan
    /// la firma vieja.
    procedure VincularMtoPadre(ADataSource: TDataSource;
                               AResolver: TResolverArtSkuProc);
    property CodigoArt: string read FCodigoArt;
    property CodigoSku: string read FCodigoSku;
  end;

var
  frmFotoArticulo: TfrmFotoArticulo;

/// Atajo: abre `frmFotoArticulo` (lo crea si no existe) y carga el par
/// pasado. Si el formulario ya estaba abierto, lo refresca y lo trae al
/// frente. Llamar desde el handler de Ctrl+F de los Mtos.
procedure MostrarFotoFlotante(AOwner: TComponent;
                              const ACodArt, ACodSku: string);

implementation

uses
  inLibMsg;

{$R *.dfm}

procedure TfrmFotoArticulo.FormCreate(Sender: TObject);
var
  loaderRes: TLayoutLoader;
begin
  inherited;
  // poDesigned (no poScreenCenter) para que Left/Top guardados con
  // Alt+F12 no sean sobrescritos al mostrarse el form. Si no hay
  // layout guardado, FormShow centra manualmente.
  Self.Position    := poDesigned;
  Self.FormStyle   := fsStayOnTop;
  // KeyPreview procesa teclas cuando la flotante esta activa (tras
  // click directo del usuario). El auto-show usa SW_SHOWNOACTIVATE
  // para no robar el foco al Mto, pero una vez el usuario clicka un
  // boton o el combo, la ventana se activa normalmente y necesita
  // procesar F11 / Alt+F12.
  Self.KeyPreview  := True;
  // Restaura la resolución elegida guardada con el layout (default 'real').
  loaderRes := TLayoutLoader.Create(Self.Name, ContextoSesion, PerfilesUsuario);
  try
    if loaderRes.Disponible then
      rgResolucion.ItemIndex :=
        StrToIntDef(loaderRes.RestaurarValor('Resolucion', '2'), 2)
    else
      rgResolucion.ItemIndex := 2;
  finally
    loaderRes.Free;
  end;
  FUltimaInfo.Clear;
  FHooksDataSource := TList<TPair<TDataSource, TDataChangeEvent>>.Create;
  FPadreResolver   := nil;
  FGpImagen        := nil;
  // El bitmap GDI+ ya viene al tamaño del control; que TImage NO lo reescale
  // (si no, al cambiar el area -p.ej. colapsar el panel de controles- la foto
  // sale pequeña hasta el siguiente repintado).
  imgFoto.Stretch      := False;
  imgFoto.Proportional := False;
  imgFoto.Center       := False;
  // Por defecto el panel de controles esta encogido.
  pnlControles.Visible := False;
  AjustarBotonToggle;
end;

procedure TfrmFotoArticulo.FormShow(Sender: TObject);
begin
  inherited;
  RestaurarGeometriaGuardada;
  // En el PRIMER show, imgFoto aun no tiene su tamano final cuando se pinto la
  // foto (sale en blanco). Diferimos un repintado a cuando el layout cuaje.
  TThread.ForceQueue(nil,
    procedure
    begin
      if Assigned(frmFotoArticulo) and frmFotoArticulo.Visible then
        frmFotoArticulo.PintarFotoGDIPlus;
    end);
end;

procedure TfrmFotoArticulo.RestaurarGeometriaGuardada;
begin
  // Restaura geometria (Left/Top/Width/Height/WindowState) si el usuario la
  // guardo con Alt+F12. Se llama desde FormShow y desde MostrarFotoFlotante
  // (antes de mostrar) para que el tamaño se aplique de forma fiable aunque
  // la ventana se muestre con SW_SHOWNOACTIVATE. Si no hay layout, centra.
  if not Assigned(FLayoutLoader) then
    FLayoutLoader := TLayoutLoader.Create(Self.Name, ContextoSesion, PerfilesUsuario);
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
  DesengancharDataChange;
  FreeAndNil(FGpImagen);
  FreeAndNil(FHooksDataSource);
  if Assigned(FLayoutLoader) then
    FreeAndNil(FLayoutLoader);
  // Vaciamos explicitamente los strings que vivian en la instancia.
  // En un mundo perfecto, el destructor del form ya los suelta cuando
  // libera sus propios campos; pero algunos detectores de leak (FastMM)
  // ven los strings interceptados antes de que la VCL libere el
  // componente padre y los reportan como huerfanos. Limpiarlos aqui
  // es belt-and-braces.
  if Assigned(cbbNivelSku) then
    cbbNivelSku.Properties.Items.Clear;
  if Assigned(lblOrigen) then lblOrigen.Caption := '';
  Self.Caption := '';
  FCodigoArt   := '';
  FCodigoSku   := '';
  FUltimaInfo.Clear;
  // Si la instancia que se destruye es la singleton global, anulamos
  // la variable para que el siguiente Ctrl+F cree una limpia.
  // (FormClose tambien lo hace, pero si el Owner libera el form sin
  // pasar por OnClose -- p.ej. al cerrar la app -- caemos aqui igual.)
  if Self = frmFotoArticulo then
    frmFotoArticulo := nil;
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
    // Cerramos pero conservamos la referencia: el siguiente Ctrl+F
    // crea una nueva instancia limpia.
    Action := caFree;
    frmFotoArticulo := nil;
  end;
end;

procedure TfrmFotoArticulo.FormKeyDown(Sender: TObject; var Key: Word;
                                       Shift: TShiftState);
begin
  inherited;
  // Alt+F12 -> guardar geometria
  if (Key = VK_F12) and (ssAlt in Shift) and not (ssCtrl in Shift) then
  begin
    GuardarLayout;
    Key := 0;
    Exit;
  end;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    ResetearLayout(Self.Name, PerfilesUsuario);
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
  saver := TLayoutSaver.Create(Self.Name, PerfilesUsuario);
  try
    saver.GuardarGeometria(Self);
    saver.GuardarValor('Resolucion', IntToStr(rgResolucion.ItemIndex));
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
  // Reencajar la foto: al cambiar la visibilidad del panel, imgFoto cambia de
  // tamaño pero el Resize del form no salta (la ventana no cambia de tamaño).
  PintarFotoGDIPlus;
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

procedure TfrmFotoArticulo.btnDescargarNubeClick(Sender: TObject);
begin
  inherited;
  DescargarFotosDeNube;
end;

procedure TfrmFotoArticulo.DescargarFotosDeNube;
var
  archivos                   : TArray<string>;
  sMsg, sFile, sClave, sColor: string;
  iBarra                     : Integer;
  bOK                        : Boolean;
begin
  // Descarga del servidor (download_foto.php) las fotos del articulo
  // actual, las descomprime en appDirFotos y borra el ZIP. Integra la foto
  // al nivel que muestra el combo (por defecto la profundidad de
  // appNumAtributosFoto, p.ej. articulo/color), igual que "Cambiar foto
  // del grupo": el color es el ultimo segmento del nivel y se elige el PNG
  // de ese color. Los demas PNG (y el temporal) se borran tras integrar.
  if FCodigoArt = '' then
    ShowMessage(SErrorFotoArticuloNoActivoDescargar)
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      bOK := DescargarFotosArticulo(
        ParametrosApp,
        FCodigoArt,
        archivos,
        sMsg);
    finally
      Screen.Cursor := crDefault;
    end;
    if not bOK then
      ShowMessage(Format(SErrorDescargarFotosArticulo,
                         [FCodigoArt, sMsg]))
    else
    begin
      sClave := ClaveNivelSeleccionado;
      iBarra := LastDelimiter('/', sClave);
      if iBarra > 0 then
        sColor := Copy(sClave, iBarra + 1, MaxInt)
      else
        sColor := '';
      sFile := ElegirFotoNubePorColor(archivos, sColor);
      if sFile <> '' then
      begin
        // Sentinela COLOR=NONE: si el PNG no es por color, lo guardamos a
        // nivel articulo (CODIGO_UNIDAD = ''); si no, al nivel del combo.
        if Pos('_NONE_', UpperCase(ExtractFileName(sFile))) > 0 then
          oFotos.Guardar(FCodigoArt, '', sFile, IdentidadSesion.Usuario)
        else
          oFotos.Guardar(FCodigoArt, sClave, sFile,
            IdentidadSesion.Usuario);
      end;
      // Re-resolver y refrescar la imagen que se muestra ahora mismo.
      SetArticuloSku(FCodigoArt, FCodigoSku);
      // Borrar los PNG temporales extraidos (no dejar huerfanos).
      LimpiarDescargaTemporal(archivos);
      ShowMessage(Format(SInfoFotosArticuloDescargadas,
                         [Length(archivos), FCodigoArt]));
    end;
  end;
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
    iNumAtribsCfg := ParametrosApp.GetInt('appNumAtributosFoto', 1);
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
begin
  FreeAndNil(FGpImagen);
  FRutaFotoActual := '';
  imgFoto.Picture.Assign(nil);
  if not FUltimaInfo.Encontrada then Exit;
  FRutaFotoActual := oFotos.RutaFoto(FUltimaInfo, ResolucionElegida);
  if FRutaFotoActual = '' then Exit;
  // Las tres copias son PNG. Cargamos via GDI+ y pintamos con remuestreo
  // bicubico de alta calidad (escala a la medida del control sin pixelar).
  FGpImagen := TGPImage.Create(FRutaFotoActual);
  if (FGpImagen = nil) or (FGpImagen.GetLastStatus <> Ok) then
  begin
    FreeAndNil(FGpImagen);
    Exit;
  end;
  PintarFotoGDIPlus;
end;

procedure TfrmFotoArticulo.PintarFotoGDIPlus;
var
  bmp    : TBitmap;
  gpGfx  : TGPGraphics;
  cw, ch, iw, ih, dw, dh, dx, dy: Integer;
  rEscala: Double;
begin
  if FGpImagen = nil then Exit;
  cw := imgFoto.Width;
  ch := imgFoto.Height;
  iw := Integer(FGpImagen.GetWidth);
  ih := Integer(FGpImagen.GetHeight);
  if (cw < 1) or (ch < 1) or (iw < 1) or (ih < 1) then Exit;
  // Encaje proporcional dentro del control, centrado (sin recortar).
  if (cw / iw) <= (ch / ih) then
    rEscala := cw / iw
  else
    rEscala := ch / ih;
  dw := Round(iw * rEscala);
  if dw < 1 then dw := 1;
  dh := Round(ih * rEscala);
  if dh < 1 then dh := 1;
  dx := (cw - dw) div 2;
  dy := (ch - dh) div 2;
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(cw, ch);
    bmp.Canvas.Brush.Color := clBtnFace;
    bmp.Canvas.FillRect(Rect(0, 0, cw, ch));
    gpGfx := TGPGraphics.Create(bmp.Canvas.Handle);
    try
      gpGfx.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      gpGfx.SetPixelOffsetMode(PixelOffsetModeHighQuality);
      gpGfx.SetSmoothingMode(SmoothingModeHighQuality);
      gpGfx.DrawImage(FGpImagen, dx, dy, dw, dh);
    finally
      gpGfx.Free;
    end;
    imgFoto.Picture.Assign(bmp);
  finally
    bmp.Free;
  end;
end;

procedure TfrmFotoArticulo.Resize;
begin
  inherited;
  PintarFotoGDIPlus;
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
    ShowMessage(SErrorFotoArticuloNoActivo);
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  try
    oFotos.Guardar(FCodigoArt, '', dlgAbrirFoto.FileName,
      IdentidadSesion.Usuario);
  except
    on E: Exception do
    begin
      ShowMessage(Format(SErrorGuardarFotoArticulo, [E.Message]));
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
    ShowMessage(SErrorFotoSkuNoActivo);
    Exit;
  end;
  sClave := ClaveNivelSeleccionado;
  if sClave = '' then
  begin
    ShowMessage(SErrorNivelAtributosFotoNoSeleccionado);
    Exit;
  end;
  if not dlgAbrirFoto.Execute then Exit;
  try
    oFotos.Guardar(FCodigoArt, sClave, dlgAbrirFoto.FileName,
      IdentidadSesion.Usuario);
  except
    on E: Exception do
    begin
      ShowMessage(Format(SErrorGuardarFotoArticulo, [E.Message]));
      Exit;
    end;
  end;
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnQuitarClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  if MessageDlg(SPreguntaEliminarFotoActual, mtConfirmation,
                [mbYes, mbNo], 0) <> mrYes then Exit;
  // Borramos exactamente la fila que resolvio (articulo, prefijo o SKU)
  oFotos.Eliminar(FCodigoArt, FUltimaInfo.ClaveResuelta);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnRotarIzqClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  oFotos.Rotar(FCodigoArt, FCodigoSku, False,
    IdentidadSesion.Usuario);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnRotarDerClick(Sender: TObject);
begin
  inherited;
  if not FUltimaInfo.Encontrada then Exit;
  oFotos.Rotar(FCodigoArt, FCodigoSku, True,
    IdentidadSesion.Usuario);
  SetArticuloSku(FCodigoArt, FCodigoSku);
end;

procedure TfrmFotoArticulo.btnLayoutClick(Sender: TObject);
begin
  inherited;
  // Equivalente a Alt+F12. Como el auto-show no activa la ventana,
  // hasta que el usuario no clicke algo el shortcut no llega aqui;
  // este boton explicito siempre funciona.
  GuardarLayout;
end;

// ---------------------------------------------------------------------
//   Auto-refresh: hook al dsTablaG del Mto padre
// ---------------------------------------------------------------------

procedure TfrmFotoArticulo.VincularDataSources(
  const ADataSources: array of TDataSource;
  AResolver: TResolverArtSkuProc);
var
  ds: TDataSource;
begin
  DesengancharDataChange;
  FPadreResolver := AResolver;
  if FHooksDataSource = nil then
    FHooksDataSource :=
      TList<TPair<TDataSource, TDataChangeEvent>>.Create;
  for ds in ADataSources do
  begin
    if ds = nil then Continue;
    FHooksDataSource.Add(
      TPair<TDataSource, TDataChangeEvent>.Create(ds, ds.OnDataChange));
    ds.OnDataChange := OnPadreDataChange;
    // VCL nos avisara con Notification(opRemove) cuando este
    // DataSource se libere, asi podemos limpiar el hook a tiempo
    // (p.ej. cuando se cierra el Mto que lo posee).
    ds.FreeNotification(Self);
  end;
end;

procedure TfrmFotoArticulo.DesengancharDataSource(ADataSource: TDataSource);
var
  i: Integer;
begin
  if (ADataSource = nil) or (FHooksDataSource = nil) then Exit;
  for i := FHooksDataSource.Count - 1 downto 0 do
    if FHooksDataSource[i].Key = ADataSource then
    begin
      // Restauramos el handler previo si el DataSource sigue vivo.
      // Si el DataSource se esta liberando (lo descubrimos via
      // Notification), no tocamos el OnDataChange — ya esta muerto.
      FHooksDataSource.Delete(i);
    end;
end;

procedure TfrmFotoArticulo.Notification(AComponent: TComponent;
                                        Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TDataSource) then
    DesengancharDataSource(TDataSource(AComponent));
end;

procedure TfrmFotoArticulo.VincularMtoPadre(
  ADataSource: TDataSource; AResolver: TResolverArtSkuProc);
begin
  // Atajo retro-compatible: delega en VincularDataSources con un solo
  // DataSource.
  VincularDataSources([ADataSource], AResolver);
end;

procedure TfrmFotoArticulo.DesengancharDataChange;
var
  pair: TPair<TDataSource, TDataChangeEvent>;
begin
  if Assigned(FHooksDataSource) then
  begin
    for pair in FHooksDataSource do
      if Assigned(pair.Key) then
      begin
        pair.Key.OnDataChange := pair.Value;
        pair.Key.RemoveFreeNotification(Self);
      end;
    FHooksDataSource.Clear;
  end;
  FPadreResolver := nil;
end;

procedure TfrmFotoArticulo.OnPadreDataChange(Sender: TObject; Field: TField);
var
  sArt, sSku : string;
  pair       : TPair<TDataSource, TDataChangeEvent>;
begin
  // Encadenamos al handler previo (si lo habia) del DataSource que
  // disparo, para no romper logica existente del Mto.
  if Assigned(FHooksDataSource) then
    for pair in FHooksDataSource do
      if (pair.Key = Sender) and Assigned(pair.Value) then
      begin
        pair.Value(Sender, Field);
        Break;
      end;
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
var
  hwndPrev: HWND;
begin
  // Capturamos el foreground window ANTES de mostrar la flotante,
  // asi podemos devolverle el foco despues (clave para que el Mto
  // no pierda el teclado cuando la ventana se auto-abre).
  hwndPrev := GetForegroundWindow;
  if frmFotoArticulo = nil then
    // Owner = Application, no el Mto que llama: la pantalla sobrevive
    // a cierres de Mtos y se libera de forma ordenada al terminar la
    // app (de lo contrario quedan colgando los hooks y los strings
    // del combo + FUltimaInfo cuando el Mto se libera primero).
    frmFotoArticulo := TfrmFotoArticulo.Create(Application);
  frmFotoArticulo.SetArticuloSku(ACodArt, ACodSku);
  if not frmFotoArticulo.Visible then
  begin
    // Restaurar tamaño/posición guardados ANTES de mostrar, de forma fiable
    // (sin depender de que OnShow dispare con SW_SHOWNOACTIVATE).
    frmFotoArticulo.RestaurarGeometriaGuardada;
    // SW_SHOWNOACTIVATE: muestra la ventana SIN activarla. A
    // diferencia de TForm.Show (que termina llamando SetActiveWindow
    // y roba el teclado al Mto), aqui la flotante aparece encima por
    // ser fsStayOnTop pero el foco se queda en quien lo tenia.
    // Sincronizamos Visible a mano porque ShowWindow no lo hace.
    ShowWindow(frmFotoArticulo.Handle, SW_SHOWNOACTIVATE);
    frmFotoArticulo.Visible := True;
  end;
  // Belt-and-braces: si por algun motivo el foreground cambio
  // (algunas combinaciones Windows/VCL activan igual), lo devolvemos.
  // Cuando el usuario clicka DIRECTAMENTE sobre la flotante (boton,
  // combo, radio), la activacion es normal: WM_MOUSEACTIVATE default
  // -> MA_ACTIVATE y los controles funcionan.
  if (hwndPrev <> 0) and IsWindow(hwndPrev) and
     (hwndPrev <> frmFotoArticulo.Handle) and
     (GetForegroundWindow = frmFotoArticulo.Handle) then
    SetForegroundWindow(hwndPrev);
end;

initialization
  frmFotoArticulo := nil;

finalization
  // Red de seguridad: si la instancia singleton sigue viva al cerrar
  // la app (p.ej. el owner aun no la libero), la liberamos aqui para
  // que ningun string asociado quede huerfano en el reporte de leaks.
  if Assigned(frmFotoArticulo) then
    FreeAndNil(frmFotoArticulo);

end.
