{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasListado                                                }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla principal: ventas de un día, con foto, y el total del día en     }
{    cabecera. Al tocar una línea se abre la ficha con todos los campos.       }
{    La UI se construye por código (sin .fmx).                                 }
{******************************************************************************}
unit fVentasListado;

interface

uses
  System.Classes, System.SysUtils, System.Threading,
  System.Generics.Collections,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.Layouts,
  FMX.Types, FMX.Graphics, FMX.ListBox,
  VentasApi, VentasModelo;

type
  TfrmListado = class(TForm)
  private
    FApi: TVentasApi;
    FBuscar: TEdit;
    FCargando: Boolean;
    FColCoste: TLayout;
    FColMargen: TLayout;
    FFecha: TDate;
    FFotos: TObjectDictionary<string, TBitmap>;
    FGeneracion: Integer;
    FLblEstado: TLabel;
    FLblFecha: TLabel;
    FLineas: TArrLineaVenta;
    FLista: TListBox;
    FTareaDatos: ITask;
    FTareaFotos: ITask;
    FTotalesDia: TTotalesVenta;
    FTruncado: Boolean;
    FValorCoste: TLabel;
    FValorDescuento: TLabel;
    FValorMargen: TLabel;
    FValorVenta: TLabel;
    FVisibles: TArray<Integer>;
    function CasaFiltro(const ALinea: TLineaVenta;
      const ATexto: string): Boolean;
    function CrearFila(const ALinea: TLineaVenta;
      AIndice: Integer): TListBoxItem;
    function FotoDeCache(const AClave: string): TBitmap;
    function GeneracionActual: Integer;
    function NuevaFicha(AParent: TFmxObject; const ATitulo: string;
      out AValor: TLabel): TLayout;
    function RutaCacheFoto(const AClave: string): string;
    function TotalesDeVisibles: TTotalesVenta;
    procedure CargarDia;
    procedure ConstruirCabecera;
    procedure ConstruirTotales;
    procedure DescargarFotosEnSegundoPlano(AGeneracion: Integer);
    procedure EsperarTareas;
    procedure MostrarTotales(const ATotales: TTotalesVenta;
      AFiltrado: Boolean);
    procedure OnAyerClick(Sender: TObject);
    procedure OnBuscarCambia(Sender: TObject);
    procedure OnConfigClick(Sender: TObject);
    procedure OnFechaClick(Sender: TObject);
    procedure OnLineaClick(const Sender: TCustomListBox;
      const AItem: TListBoxItem);
    procedure OnMananaClick(Sender: TObject);
    procedure PintarLista;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmListado: TfrmListado;

implementation

uses
  System.Types, System.UITypes, System.DateUtils, System.IOUtils,
  System.Hash, System.SyncObjs,
  FMX.Objects, FMX.Dialogs,
  VentasConfig, fVentasConfig, fVentasFicha;

const
  // Alto de fila y lado mayor de la miniatura. La foto se guarda en caché ya
  // reducida: una de 300 px descomprimida ocupa unos 360 KB, y repetirla en
  // cada fila se comería la memoria del móvil.
  cAltoFila = 92;
  cLadoMini = 152;

function Moneda(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.00', AValor) + ' €';
end;

constructor TfrmListado.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FApi := TVentasApi.Create;
  FFotos := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  FFecha := Date;
  FGeneracion := 0;
  FCargando := False;
  FTruncado := False;
  Self.Caption := 'Ventas del día';
  ConstruirCabecera;
  ConstruirTotales;
  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := Self;
  FLblEstado.Align := TAlignLayout.Bottom;
  FLblEstado.Height := 30;
  FLblEstado.Margins.Rect := RectF(14, 0, 14, 4);
  FLblEstado.Text := '';
  FBuscar := TEdit.Create(Self);
  FBuscar.Parent := Self;
  FBuscar.Align := TAlignLayout.Top;
  FBuscar.Height := 44;
  FBuscar.Margins.Rect := RectF(12, 4, 12, 6);
  FBuscar.TextPrompt := 'Buscar por descripción, SKU, familia…';
  FBuscar.OnChangeTracking := OnBuscarCambia;
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
  FLista.ItemHeight := cAltoFila;
  FLista.ShowScrollBars := True;
  FLista.OnItemClick := OnLineaClick;
  if oConfig.EstaConfigurado then
    CargarDia
  else
    // La configuración no puede abrirse desde el constructor: el formulario
    // principal todavía no está mostrado. Se deja encolada para cuando el
    // bucle de mensajes esté en marcha.
    TThread.ForceQueue(nil,
      procedure
      begin
        OnConfigClick(nil);
      end);
end;

{ Antes de soltar nada hay que asegurarse de que no queda ningún hilo usando
  FApi ni métodos de este formulario, y de drenar lo que ya se hubiera
  encolado hacia el hilo principal. }
destructor TfrmListado.Destroy;
begin
  TInterlocked.Increment(FGeneracion);
  EsperarTareas;
  CheckSynchronize(0);
  FreeAndNil(FApi);
  inherited;
  // Después de inherited: la lista ya no existe y nadie referencia los
  // bitmaps de la caché.
  FreeAndNil(FFotos);
end;

procedure TfrmListado.EsperarTareas;
var
  aTareas: TArray<ITask>;
begin
  SetLength(aTareas, 0);
  if Assigned(FTareaDatos) then
    aTareas := aTareas + [FTareaDatos];
  if Assigned(FTareaFotos) then
    aTareas := aTareas + [FTareaFotos];
  if Length(aTareas) > 0 then
  begin
    try
      TTask.WaitForAll(aTareas, 8000);
    except
      // Una tarea que ya falló no debe impedir cerrar la aplicación.
    end;
  end;
  FTareaDatos := nil;
  FTareaFotos := nil;
end;

{ Lectura del contador con barrera: lo escribe el hilo principal y lo leen
  los hilos de fondo en cada vuelta. }
function TfrmListado.GeneracionActual: Integer;
begin
  Result := TInterlocked.CompareExchange(FGeneracion, 0, 0);
end;

procedure TfrmListado.ConstruirCabecera;
var
  btnAyer: TButton;
  btnConfig: TButton;
  btnManana: TButton;
  layFecha: TLayout;
begin
  layFecha := TLayout.Create(Self);
  layFecha.Parent := Self;
  layFecha.Align := TAlignLayout.Top;
  layFecha.Height := 56;
  btnAyer := TButton.Create(Self);
  btnAyer.Parent := layFecha;
  btnAyer.Align := TAlignLayout.Left;
  btnAyer.Width := 56;
  btnAyer.Margins.Rect := RectF(12, 8, 0, 8);
  btnAyer.Text := '◀';
  btnAyer.OnClick := OnAyerClick;
  btnConfig := TButton.Create(Self);
  btnConfig.Parent := layFecha;
  btnConfig.Align := TAlignLayout.Right;
  btnConfig.Width := 56;
  btnConfig.Margins.Rect := RectF(0, 8, 12, 8);
  btnConfig.Text := '⚙';
  btnConfig.OnClick := OnConfigClick;
  btnManana := TButton.Create(Self);
  btnManana.Parent := layFecha;
  btnManana.Align := TAlignLayout.Right;
  btnManana.Width := 56;
  btnManana.Margins.Rect := RectF(0, 8, 4, 8);
  btnManana.Text := '▶';
  btnManana.OnClick := OnMananaClick;
  FLblFecha := TLabel.Create(Self);
  FLblFecha.Parent := layFecha;
  FLblFecha.Align := TAlignLayout.Client;
  FLblFecha.TextSettings.HorzAlign := TTextAlign.Center;
  FLblFecha.TextSettings.Font.Size := 17;
  FLblFecha.TextSettings.Font.Style := [TFontStyle.fsBold];
  FLblFecha.StyledSettings := [];
  FLblFecha.OnClick := OnFechaClick;
  FLblFecha.HitTest := True;
end;

{ Cada dato del panel superior es una columna con rótulo pequeño arriba y
  cifra grande debajo. }
function TfrmListado.NuevaFicha(AParent: TFmxObject; const ATitulo: string;
  out AValor: TLabel): TLayout;
var
  lblTitulo: TLabel;
begin
  Result := TLayout.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Left;
  Result.Width := 96;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Result;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 20;
  lblTitulo.Text := ATitulo;
  lblTitulo.TextSettings.Font.Size := 12;
  lblTitulo.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblTitulo.TextSettings.HorzAlign := TTextAlign.Center;
  lblTitulo.StyledSettings := [];
  AValor := TLabel.Create(Self);
  AValor.Parent := Result;
  AValor.Align := TAlignLayout.Client;
  AValor.Text := '—';
  AValor.TextSettings.Font.Size := 16;
  AValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  AValor.TextSettings.HorzAlign := TTextAlign.Center;
  AValor.StyledSettings := [];
end;

procedure TfrmListado.ConstruirTotales;
var
  layTotales: TLayout;
  scbTotales: THorzScrollBox;
begin
  layTotales := TLayout.Create(Self);
  layTotales.Parent := Self;
  layTotales.Align := TAlignLayout.Top;
  layTotales.Height := 66;
  layTotales.Margins.Rect := RectF(8, 2, 8, 2);
  // En pantallas estrechas las cuatro cifras no caben: se dejan en un
  // scroll horizontal en vez de encogerlas hasta hacerlas ilegibles.
  scbTotales := THorzScrollBox.Create(Self);
  scbTotales.Parent := layTotales;
  scbTotales.Align := TAlignLayout.Client;
  scbTotales.ShowScrollBars := False;
  NuevaFicha(scbTotales, 'VENTA', FValorVenta);
  FColCoste := NuevaFicha(scbTotales, 'COSTE', FValorCoste);
  FColMargen := NuevaFicha(scbTotales, 'MARGEN', FValorMargen);
  NuevaFicha(scbTotales, 'DESCUENTO', FValorDescuento);
end;

procedure TfrmListado.MostrarTotales(const ATotales: TTotalesVenta;
  AFiltrado: Boolean);
var
  sEstado: string;
begin
  FValorVenta.Text := Moneda(ATotales.TotalVenta);
  FValorCoste.Text := Moneda(ATotales.TotalCoste);
  FValorMargen.Text := Moneda(ATotales.TotalMargen) + sLineBreak +
    FormatFloat('#,##0.0', ATotales.PorcentajeMargen) + ' %';
  FValorDescuento.Text := Moneda(ATotales.TotalDescuento);
  FColCoste.Visible := oConfig.MostrarMargen;
  FColMargen.Visible := oConfig.MostrarMargen;
  sEstado := IntToStr(ATotales.Lineas) + ' líneas · ' +
    FormatFloat('#,##0.###', ATotales.Unidades) + ' uds';
  if AFiltrado then
    sEstado := sEstado + '  (filtrado)';
  if FTruncado and not AFiltrado then
    sEstado := sEstado + '  ·  se muestran solo las ' +
      IntToStr(Length(FLineas)) + ' primeras';
  FLblEstado.Text := sEstado;
end;

procedure TfrmListado.CargarDia;
var
  iGeneracion: Integer;
  oFiltro: TFiltroLineas;
begin
  if not FCargando then
  begin
    FCargando := True;
    TInterlocked.Increment(FGeneracion);
    iGeneracion := GeneracionActual;
    FLblFecha.Text := FormatDateTime('dddd, d "de" mmmm', FFecha);
    FLblEstado.Text := 'Consultando…';
    FLista.Clear;
    oFiltro := Default(TFiltroLineas);
    oFiltro.Fecha := FormatDateTime('yyyy-mm-dd', FFecha);
    oFiltro.Limite := 1000;
    FTareaDatos := TTask.Run(
      procedure
      var
        bOk: Boolean;
        oRespuesta: TRespuestaLineas;
        sError: string;
      begin
        // Cualquier fallo tiene que llegar a la UI: si la tarea muriese sin
        // encolar nada, FCargando se quedaría en True para siempre y la app
        // no volvería a consultar.
        bOk := False;
        oRespuesta := Default(TRespuestaLineas);
        sError := '';
        try
          bOk := FApi.ConsultarLineas(oFiltro, oRespuesta);
          sError := FApi.UltimoError;
        except
          on E: Exception do
          begin
            bOk := False;
            sError := E.Message;
          end;
        end;
        TThread.Queue(nil,
          procedure
          begin
            if iGeneracion = GeneracionActual then
            begin
              FCargando := False;
              if bOk then
              begin
                FLineas := oRespuesta.Lineas;
                FTotalesDia := oRespuesta.Totales;
                FTruncado := oRespuesta.Devueltas < oRespuesta.TotalLineas;
                PintarLista;
                DescargarFotosEnSegundoPlano(iGeneracion);
              end
              else
              begin
                SetLength(FLineas, 0);
                FTotalesDia := Default(TTotalesVenta);
                FTruncado := False;
                PintarLista;
                FLblEstado.Text := sError;
              end;
            end;
          end);
      end);
  end;
end;

function TfrmListado.CasaFiltro(const ALinea: TLineaVenta;
  const ATexto: string): Boolean;
var
  sBolsa: string;
begin
  Result := ATexto = '';
  if not Result then
  begin
    sBolsa := ALinea.Descripcion + ' ' + ALinea.Sku + ' ' +
      ALinea.Familia + ' ' + ALinea.Temporada + ' ' + ALinea.Proveedor +
      ' ' + ALinea.Color + ' ' + ALinea.Documento;
    // Con la configuración regional, para que "camison" case con "CAMISÓN".
    Result := Pos(ATexto,
      UpperCase(sBolsa, TLocaleOptions.loUserLocale)) > 0;
  end;
end;

function TfrmListado.TotalesDeVisibles: TTotalesVenta;
var
  iIndice: Integer;
  oLinea: TLineaVenta;
begin
  Result := Default(TTotalesVenta);
  for iIndice in FVisibles do
  begin
    oLinea := FLineas[iIndice];
    Inc(Result.Lineas);
    Result.Unidades := Result.Unidades + oLinea.Cantidad;
    Result.TotalVenta := Result.TotalVenta + oLinea.TotalLinea;
    Result.TotalVentaSiva := Result.TotalVentaSiva + oLinea.TotalLineaSiva;
    Result.TotalCoste := Result.TotalCoste + oLinea.TotalCoste;
    Result.TotalDescuento :=
      Result.TotalDescuento + oLinea.ImporteDescuento;
  end;
  Result.TotalMargen := Result.TotalVentaSiva - Result.TotalCoste;
  if Result.TotalVentaSiva <> 0 then
    Result.PorcentajeMargen :=
      Result.TotalMargen / Result.TotalVentaSiva * 100;
end;

{ Los bitmaps los guarda el formulario, no los items: varias líneas del
  mismo artículo comparten uno y así se carga del disco una sola vez. }
function TfrmListado.FotoDeCache(const AClave: string): TBitmap;
var
  iAlto: Integer;
  iAncho: Integer;
  oBitmap: TBitmap;
  oMini: TBitmap;
  sRuta: string;
begin
  Result := nil;
  if not FFotos.TryGetValue(AClave, Result) then
  begin
    sRuta := RutaCacheFoto(AClave);
    if TFile.Exists(sRuta) then
    begin
      oBitmap := TBitmap.Create;
      try
        try
          oBitmap.LoadFromFile(sRuta);
          // Se reduce guardando la proporción: CreateThumbnail estira si se
          // le dan las dos medidas a lo bruto.
          if oBitmap.Width >= oBitmap.Height then
          begin
            iAncho := cLadoMini;
            iAlto := Round(oBitmap.Height * cLadoMini / oBitmap.Width);
          end
          else
          begin
            iAlto := cLadoMini;
            iAncho := Round(oBitmap.Width * cLadoMini / oBitmap.Height);
          end;
          if iAncho < 1 then
            iAncho := 1;
          if iAlto < 1 then
            iAlto := 1;
          oMini := oBitmap.CreateThumbnail(iAncho, iAlto);
          FFotos.Add(AClave, oMini);
          Result := oMini;
        except
          // PNG corrupto o a medio escribir: se descarta sin romper la lista.
          Result := nil;
        end;
      finally
        FreeAndNil(oBitmap);
      end;
    end;
  end;
end;

{ Cada fila lleva miniatura y tres líneas: descripción, la terna
  familia / temporada / proveedor, y abajo hora y SKU con el importe a la
  derecha. Se compone a mano porque las apariencias de serie de FMX solo
  dan dos líneas de texto. }
function TfrmListado.CrearFila(const ALinea: TLineaVenta;
  AIndice: Integer): TListBoxItem;
var
  imgFoto: TImage;
  layPie: TLayout;
  layTexto: TLayout;
  lblClasif: TLabel;
  lblImporte: TLabel;
  lblPie: TLabel;
  lblTitulo: TLabel;
  oFoto: TBitmap;
  sClasif: string;
  sImporte: string;
  sPie: string;

  procedure Agregar(const ATrozo: string; var ADestino: string);
  begin
    if Trim(ATrozo) <> '' then
    begin
      if ADestino <> '' then
        ADestino := ADestino + '  ·  ';
      ADestino := ADestino + Trim(ATrozo);
    end;
  end;

begin
  Result := TListBoxItem.Create(FLista);
  Result.Parent := FLista;
  Result.Height := cAltoFila;
  Result.Text := '';
  Result.Tag := AIndice;
  imgFoto := TImage.Create(Result);
  imgFoto.Parent := Result;
  imgFoto.Align := TAlignLayout.Left;
  imgFoto.Width := 84;
  imgFoto.Margins.Rect := RectF(4, 6, 0, 6);
  imgFoto.WrapMode := TImageWrapMode.Fit;
  imgFoto.HitTest := False;
  oFoto := FotoDeCache(ALinea.ClaveFoto);
  if Assigned(oFoto) then
    imgFoto.Bitmap.Assign(oFoto);
  layTexto := TLayout.Create(Result);
  layTexto.Parent := Result;
  layTexto.Align := TAlignLayout.Client;
  layTexto.Margins.Rect := RectF(8, 8, 10, 8);
  layTexto.HitTest := False;
  lblTitulo := TLabel.Create(Result);
  lblTitulo.Parent := layTexto;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 24;
  lblTitulo.Text := ALinea.TituloLinea;
  lblTitulo.TextSettings.Font.Size := 15;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  lblTitulo.HitTest := False;
  sClasif := '';
  Agregar(ALinea.Familia, sClasif);
  Agregar(ALinea.Temporada, sClasif);
  Agregar(ALinea.Proveedor, sClasif);
  lblClasif := TLabel.Create(Result);
  lblClasif.Parent := layTexto;
  lblClasif.Align := TAlignLayout.Top;
  lblClasif.Height := 22;
  lblClasif.Text := sClasif;
  lblClasif.TextSettings.Font.Size := 13;
  lblClasif.StyledSettings := [TStyledSetting.FontColor];
  lblClasif.HitTest := False;
  layPie := TLayout.Create(Result);
  layPie.Parent := layTexto;
  layPie.Align := TAlignLayout.Top;
  layPie.Height := 22;
  layPie.HitTest := False;
  sImporte := Moneda(ALinea.TotalLinea);
  if ALinea.ImporteDescuento > 0 then
    sImporte := sImporte + '  −' +
      FormatFloat('#,##0.##', ALinea.PorcentajeDescuento) + '%';
  lblImporte := TLabel.Create(Result);
  lblImporte.Parent := layPie;
  lblImporte.Align := TAlignLayout.Right;
  lblImporte.Width := 150;
  lblImporte.Text := sImporte;
  lblImporte.TextSettings.Font.Size := 14;
  lblImporte.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblImporte.TextSettings.HorzAlign := TTextAlign.Trailing;
  lblImporte.StyledSettings := [];
  lblImporte.HitTest := False;
  sPie := '';
  Agregar(ALinea.Hora, sPie);
  Agregar(ALinea.Sku, sPie);
  lblPie := TLabel.Create(Result);
  lblPie.Parent := layPie;
  lblPie.Align := TAlignLayout.Client;
  lblPie.Text := sPie;
  lblPie.TextSettings.Font.Size := 12;
  lblPie.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblPie.StyledSettings := [];
  lblPie.HitTest := False;
end;

procedure TfrmListado.PintarLista;
var
  bFiltrado: Boolean;
  iLinea: Integer;
  oLinea: TLineaVenta;
  sTexto: string;
begin
  sTexto := UpperCase(Trim(FBuscar.Text), TLocaleOptions.loUserLocale);
  bFiltrado := sTexto <> '';
  SetLength(FVisibles, 0);
  FLista.BeginUpdate;
  try
    FLista.Clear;
    for iLinea := 0 to High(FLineas) do
    begin
      oLinea := FLineas[iLinea];
      if CasaFiltro(oLinea, sTexto) then
      begin
        FVisibles := FVisibles + [iLinea];
        CrearFila(oLinea, iLinea);
      end;
    end;
  finally
    FLista.EndUpdate;
  end;
  if bFiltrado then
    MostrarTotales(TotalesDeVisibles, True)
  else
    MostrarTotales(FTotalesDia, False);
end;

function TfrmListado.RutaCacheFoto(const AClave: string): string;
begin
  // TPath cualificado: FMX.Objects declara otro TPath (la figura vectorial)
  // que tapa al de System.IOUtils.
  Result := System.IOUtils.TPath.Combine(oConfig.RutaCacheFotos,
    THashMD5.GetHashString(AClave) + '.png');
end;

{ Las fotos se piden una sola vez por artículo y color, después de pintar la
  lista, para que el listado salga de inmediato aunque la red vaya lenta. }
procedure TfrmListado.DescargarFotosEnSegundoPlano(AGeneracion: Integer);
var
  aClaves: TArray<string>;
  aDestinos: TArray<string>;
  aRutas: TArray<string>;
  iGeneracion: Integer;
  iLinea: Integer;
  oLinea: TLineaVenta;
  sClaves: TStringList;
begin
  // La generación se copia a una local: las closures anidadas capturan
  // variables del método, no sus parámetros.
  iGeneracion := AGeneracion;
  SetLength(aClaves, 0);
  SetLength(aRutas, 0);
  SetLength(aDestinos, 0);
  sClaves := TStringList.Create;
  try
    sClaves.Sorted := True;
    sClaves.Duplicates := dupIgnore;
    for iLinea := 0 to High(FLineas) do
    begin
      oLinea := FLineas[iLinea];
      if (oLinea.FotoRuta <> '') and
         (sClaves.IndexOf(oLinea.ClaveFoto) < 0) and
         not TFile.Exists(RutaCacheFoto(oLinea.ClaveFoto)) then
      begin
        sClaves.Add(oLinea.ClaveFoto);
        aClaves := aClaves + [oLinea.ClaveFoto];
        aRutas := aRutas + [oLinea.FotoRuta];
        // La ruta de destino se resuelve aquí, en el hilo principal: el de
        // fondo no debe tocar métodos del formulario.
        aDestinos := aDestinos + [RutaCacheFoto(oLinea.ClaveFoto)];
      end;
    end;
  finally
    FreeAndNil(sClaves);
  end;
  if Length(aRutas) > 0 then
  begin
    FTareaFotos := TTask.Run(
      procedure
      var
        iDescargadas: Integer;
        iPendiente: Integer;
        oApi: TVentasApi;
        sErrorFoto: string;
      begin
        iDescargadas := 0;
        iPendiente := 0;
        sErrorFoto := '';
        try
          // API propia del hilo: THTTPClient no se comparte entre hilos.
          oApi := TVentasApi.Create;
          try
            // Se corta en cuanto cambia la generación: el usuario ya está
            // mirando otro día y estas fotos ya no interesan.
            while (iPendiente <= High(aRutas)) and
                  (iGeneracion = GeneracionActual) do
            begin
              if oApi.DescargarFoto(aRutas[iPendiente],
                                    aDestinos[iPendiente]) then
                Inc(iDescargadas)
              else if sErrorFoto = '' then
                sErrorFoto := oApi.UltimoError;
              Inc(iPendiente);
            end;
          finally
            FreeAndNil(oApi);
          end;
        except
          on E: Exception do
            if sErrorFoto = '' then
              sErrorFoto := E.Message;
        end;
        // Si no ha entrado ninguna foto se dice por qué: casi siempre es
        // que la credencial no lleva el ámbito fotos:leer (403) o que ese
        // artículo no tiene foto subida al servidor (404).
        TThread.Queue(nil,
          procedure
          begin
            if iGeneracion = GeneracionActual then
            begin
              if iDescargadas > 0 then
                PintarLista;
              if (iDescargadas = 0) and (sErrorFoto <> '') then
                FLblEstado.Text := FLblEstado.Text + '  ·  fotos: ' +
                  sErrorFoto;
            end;
          end);
      end);
  end;
end;

procedure TfrmListado.OnAyerClick(Sender: TObject);
begin
  // Mientras hay una consulta en marcha no se mueve la fecha: si no, el
  // rótulo y FFecha se desincronizarían.
  if not FCargando then
  begin
    FFecha := IncDay(FFecha, -1);
    CargarDia;
  end;
end;

procedure TfrmListado.OnMananaClick(Sender: TObject);
begin
  if not FCargando then
  begin
    FFecha := IncDay(FFecha, 1);
    CargarDia;
  end;
end;

procedure TfrmListado.OnFechaClick(Sender: TObject);
begin
  if (not FCargando) and (FFecha <> Date) then
  begin
    FFecha := Date;
    CargarDia;
  end;
end;

procedure TfrmListado.OnBuscarCambia(Sender: TObject);
begin
  PintarLista;
end;

procedure TfrmListado.OnConfigClick(Sender: TObject);
begin
  TfrmConfig.EditarAsync(Self,
    procedure(AGuardado: Boolean)
    begin
      if AGuardado and oConfig.EstaConfigurado then
        CargarDia;
    end);
end;

procedure TfrmListado.OnLineaClick(const Sender: TCustomListBox;
  const AItem: TListBoxItem);
var
  iLinea: Integer;
begin
  if Assigned(AItem) then
  begin
    iLinea := Integer(AItem.Tag);
    if (iLinea >= 0) and (iLinea <= High(FLineas)) then
      TfrmFicha.Mostrar(Self, FLineas[iLinea],
        RutaCacheFoto(FLineas[iLinea].ClaveFoto));
  end;
end;

end.
