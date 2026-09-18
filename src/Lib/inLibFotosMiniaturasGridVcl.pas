{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosMiniaturasGridVcl                                   }
{    Tipo:       Presentador VCL                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Columna de rejilla que pinta la tira de miniaturas (fotos a 300 px) del   }
{    artículo / SKU de cada fila. Recibe la vista y el servicio de fotos;      }
{    nunca el formulario.                                                      }
{******************************************************************************}
unit inLibFotosMiniaturasGridVcl;

interface

uses
  System.Generics.Collections,
  Vcl.Graphics,
  cxGraphics, cxGridCustomTableView, cxGridCustomView,
  cxGridDBTableView, cxGridTableView,
  inLibFotos;

const
  // Medidas a 96 ppp: la clase las escala al PPI real de la rejilla.
  cLadoMiniaturaGrid    = 40;
  cMargenMiniaturaGrid  = 3;
  cHuecoMiniaturaGrid   = 3;
  cAnchoRestoMiniaturas = 20;
  cMaximoMiniaturasGrid = 3;
  // Topes de las cachés: al superarlos se vacían enteras (no hay LRU; el
  // coste de rehacerlas es una consulta por artículo).
  cMaximoCacheRutas      = 500;
  cMaximoCacheMiniaturas = 300;

type
  // Añade a la vista una columna sin campo que dibuja hasta AMaximo
  // miniaturas por fila y un "+N" con las que no caben.
  //
  // El evento de dibujo se dispara en cada repintado, asi que ni consulta
  // la base de datos ni lee disco: cachea las rutas por artículo|SKU y los
  // bitmaps ya escalados por ruta y lado. Se engancha al OnCustomDrawCell
  // de su propia columna, de modo que no pisa el evento de la vista.
  //
  // La vista debe tener una columna ligada a ACampoArticulo (y otra a
  // ACampoSku si se pasa); si no, la celda queda vacía.
  TTiraMiniaturasFotosGrid = class
  private
    FVista         : TcxGridDBTableView;
    FColumna       : TcxGridDBColumn;
    FFotos         : TFotosArticulos;
    FCampoArticulo : string;
    FCampoSku      : string;
    FLado          : Integer;
    FMaximo        : Integer;
    FRutas         : TDictionary<string, TArray<string>>;
    FMiniaturas    : TObjectDictionary<string, Vcl.Graphics.TBitmap>;
    function Escalar(AValor96Ppp: Integer): Integer;
    function ValorColumna(ARegistro: TcxCustomGridRecord;
      const ACampo: string): string;
    function RutasDeRegistro(
      ARegistro: TcxCustomGridRecord): TArray<string>;
    function Miniatura(const ARuta: string;
      ALado: Integer): Vcl.Graphics.TBitmap;
    procedure ConfigurarColumna(const ANombre, ATitulo: string);
    procedure AjustarAltoFila;
    procedure DibujarCelda(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  public
    constructor Create(AVista: TcxGridDBTableView;
      AFotos: TFotosArticulos;
      const ANombre, ATitulo, ACampoArticulo, ACampoSku: string;
      ALado: Integer = cLadoMiniaturaGrid;
      AMaximo: Integer = cMaximoMiniaturasGrid);
    destructor Destroy; override;
    // Tira las cachés: se llama cuando se recarga la pantalla, para que una
    // foto añadida o rotada desde otro sitio se vea sin reabrir.
    procedure Limpiar;
    property Columna: TcxGridDBColumn read FColumna;
  end;

implementation

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.SysUtils, System.Types, System.Variants,
  Vcl.Imaging.PngImage;

constructor TTiraMiniaturasFotosGrid.Create(AVista: TcxGridDBTableView;
  AFotos: TFotosArticulos;
  const ANombre, ATitulo, ACampoArticulo, ACampoSku: string;
  ALado: Integer;
  AMaximo: Integer);
begin
  inherited Create;
  FVista := AVista;
  FFotos := AFotos;
  FCampoArticulo := ACampoArticulo;
  FCampoSku := ACampoSku;
  FLado := ALado;
  if FLado < 1 then
    FLado := cLadoMiniaturaGrid;
  FMaximo := AMaximo;
  if FMaximo < 1 then
    FMaximo := 1;
  FRutas := TDictionary<string, TArray<string>>.Create;
  FMiniaturas := TObjectDictionary<string,
    Vcl.Graphics.TBitmap>.Create([doOwnsValues]);
  ConfigurarColumna(ANombre, ATitulo);
  AjustarAltoFila;
end;

destructor TTiraMiniaturasFotosGrid.Destroy;
begin
  // La columna pertenece a la vista y puede sobrevivir a este objeto: hay
  // que soltar el evento antes de liberar las caches que usa.
  if Assigned(FColumna) then
    FColumna.OnCustomDrawCell := nil;
  FFotos := nil;
  FreeAndNil(FMiniaturas);
  FreeAndNil(FRutas);
  inherited Destroy;
end;

procedure TTiraMiniaturasFotosGrid.ConfigurarColumna(
  const ANombre, ATitulo: string);
begin
  FColumna := FVista.CreateColumn;
  if ANombre <> '' then
    FColumna.Name := ANombre;
  FColumna.Caption := ATitulo;
  // Columna sin campo: nada que ordenar, agrupar, filtrar ni editar (y la
  // exportacion a Excel la salta por no tener FieldName).
  FColumna.Options.Editing := False;
  FColumna.Options.Filtering := False;
  FColumna.Options.Grouping := False;
  FColumna.Options.Sorting := False;
  FColumna.HeaderAlignmentHorz := taCenter;
  FColumna.Width := Escalar(
    2 * cMargenMiniaturaGrid +
    FMaximo * FLado +
    (FMaximo - 1) * cHuecoMiniaturaGrid +
    cAnchoRestoMiniaturas);
  FColumna.OnCustomDrawCell := DibujarCelda;
end;

procedure TTiraMiniaturasFotosGrid.AjustarAltoFila;
var
  iAlto: Integer;
begin
  iAlto := Escalar(FLado + 2 * cMargenMiniaturaGrid);
  if FVista.OptionsView.DataRowHeight < iAlto then
    FVista.OptionsView.DataRowHeight := iAlto;
end;

function TTiraMiniaturasFotosGrid.Escalar(AValor96Ppp: Integer): Integer;
var
  iPpp: Integer;
begin
  iPpp := USER_DEFAULT_SCREEN_DPI;
  if (FVista <> nil) and (FVista.Site <> nil) then
    iPpp := FVista.Site.CurrentPPI;
  Result := MulDiv(AValor96Ppp, iPpp, USER_DEFAULT_SCREEN_DPI);
end;

procedure TTiraMiniaturasFotosGrid.Limpiar;
begin
  FMiniaturas.Clear;
  FRutas.Clear;
end;

function TTiraMiniaturasFotosGrid.ValorColumna(
  ARegistro: TcxCustomGridRecord; const ACampo: string): string;
var
  oColumna: TcxGridDBColumn;
begin
  Result := '';
  if (ACampo <> '') and Assigned(ARegistro) then
  begin
    oColumna := FVista.GetColumnByFieldName(ACampo);
    if Assigned(oColumna) then
      Result := Trim(VarToStr(ARegistro.Values[oColumna.Index]));
  end;
end;

function TTiraMiniaturasFotosGrid.RutasDeRegistro(
  ARegistro: TcxCustomGridRecord): TArray<string>;
var
  aFotos    : TArray<TFotoInfo>;
  sArticulo : string;
  sClave    : string;
  sRuta     : string;
  sSku      : string;
  iFoto     : Integer;
  iRutas    : Integer;
begin
  SetLength(Result, 0);
  if not Assigned(FFotos) then
    Exit;
  sArticulo := ValorColumna(ARegistro, FCampoArticulo);
  if sArticulo = '' then
    Exit;
  sSku := ValorColumna(ARegistro, FCampoSku);
  sClave := sArticulo + '|' + sSku;
  if not FRutas.TryGetValue(sClave, Result) then
  begin
    SetLength(Result, 0);
    iRutas := 0;
    try
      aFotos := FFotos.ResolverColeccion(sArticulo, sSku);
      SetLength(Result, Length(aFotos));
      for iFoto := 0 to High(aFotos) do
      begin
        sRuta := FFotos.RutaFoto(aFotos[iFoto], frPx300);
        if sRuta <> '' then
        begin
          Result[iRutas] := sRuta;
          Inc(iRutas);
        end;
      end;
    except
      // Un fallo de consulta no puede repetirse en cada repintado ni
      // tumbar la rejilla: se cachea la fila como "sin fotos".
      iRutas := 0;
    end;
    SetLength(Result, iRutas);
    if FRutas.Count >= cMaximoCacheRutas then
      FRutas.Clear;
    FRutas.Add(sClave, Result);
  end;
end;

function TTiraMiniaturasFotosGrid.Miniatura(const ARuta: string;
  ALado: Integer): Vcl.Graphics.TBitmap;
var
  oDestino   : Vcl.Graphics.TBitmap;
  oGdi       : TGPGraphics;
  oGdiOrigen : TGPBitmap;
  oOrigen    : Vcl.Graphics.TBitmap;
  oPng       : TPngImage;
  sClave     : string;
  iAlto      : Integer;
  iAncho     : Integer;
begin
  sClave := ARuta + '|' + IntToStr(ALado);
  if not FMiniaturas.TryGetValue(sClave, Result) then
  begin
    Result := nil;
    try
      oPng := TPngImage.Create;
      try
        oPng.LoadFromFile(ARuta);
        // Escalado conservando la proporcion dentro del cuadrado pedido.
        if oPng.Width >= oPng.Height then
        begin
          iAncho := ALado;
          iAlto := MulDiv(oPng.Height, ALado, oPng.Width);
        end
        else
        begin
          iAlto := ALado;
          iAncho := MulDiv(oPng.Width, ALado, oPng.Height);
        end;
        if iAncho < 1 then
          iAncho := 1;
        if iAlto < 1 then
          iAlto := 1;
        oOrigen := Vcl.Graphics.TBitmap.Create;
        oDestino := Vcl.Graphics.TBitmap.Create;
        try
          oOrigen.PixelFormat := pf32bit;
          oOrigen.SetSize(oPng.Width, oPng.Height);
          oOrigen.Canvas.Brush.Color := clWhite;
          oOrigen.Canvas.FillRect(
            Rect(0, 0, oPng.Width, oPng.Height));
          oOrigen.Canvas.Draw(0, 0, oPng);
          oDestino.PixelFormat := pf32bit;
          oDestino.SetSize(iAncho, iAlto);
          oDestino.Canvas.Brush.Color := clWhite;
          oDestino.Canvas.FillRect(Rect(0, 0, iAncho, iAlto));
          // GDI+ para el remuestreo: un StretchDraw de GDI deja escalones
          // muy visibles al bajar de 300 px a 40.
          oGdiOrigen := TGPBitmap.Create(oOrigen.Handle, 0);
          try
            oGdi := TGPGraphics.Create(oDestino.Canvas.Handle);
            try
              oGdi.SetInterpolationMode(
                InterpolationModeHighQualityBicubic);
              oGdi.SetPixelOffsetMode(PixelOffsetModeHighQuality);
              oGdi.SetSmoothingMode(SmoothingModeHighQuality);
              oGdi.DrawImage(oGdiOrigen, 0, 0, iAncho, iAlto);
            finally
              FreeAndNil(oGdi);
            end;
          finally
            FreeAndNil(oGdiOrigen);
          end;
          Result := oDestino;
          oDestino := nil;
        finally
          FreeAndNil(oOrigen);
          FreeAndNil(oDestino);
        end;
      finally
        FreeAndNil(oPng);
      end;
    except
      // Una foto ilegible se cachea como nula: la celda la salta y no se
      // reintenta en cada repintado.
      FreeAndNil(Result);
    end;
    FMiniaturas.Add(sClave, Result);
  end;
end;

procedure TTiraMiniaturasFotosGrid.DibujarCelda(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  aRutas   : TArray<string>;
  oMini    : Vcl.Graphics.TBitmap;
  rCelda   : TRect;
  rResto   : TRect;
  sResto   : string;
  iCentro  : Integer;
  iHueco   : Integer;
  iIzq     : Integer;
  iLado    : Integer;
  iMiniatura : Integer;
  iVisibles  : Integer;
begin
  if (ACanvas = nil) or (AViewInfo = nil) or
     (AViewInfo.GridRecord = nil) then
    Exit;
  rCelda := AViewInfo.Bounds;
  // Params.Color respeta seleccion y foco; a partir de aqui la celda la
  // pintamos nosotros entera (sin texto).
  ACanvas.FillRect(rCelda, AViewInfo.Params.Color);
  ADone := True;
  if FMiniaturas.Count >= cMaximoCacheMiniaturas then
    FMiniaturas.Clear;
  aRutas := RutasDeRegistro(AViewInfo.GridRecord);
  if Length(aRutas) = 0 then
    Exit;
  iLado := Escalar(FLado);
  // Si el usuario ha bajado el alto de fila, la miniatura se achica con el.
  if iLado > rCelda.Height - 2 * Escalar(cMargenMiniaturaGrid) then
    iLado := rCelda.Height - 2 * Escalar(cMargenMiniaturaGrid);
  if iLado < 1 then
    Exit;
  iHueco := Escalar(cHuecoMiniaturaGrid);
  iVisibles := Length(aRutas);
  if iVisibles > FMaximo then
    iVisibles := FMaximo;
  iIzq := rCelda.Left + Escalar(cMargenMiniaturaGrid);
  iCentro := (rCelda.Top + rCelda.Bottom) div 2;
  for iMiniatura := 0 to iVisibles - 1 do
  begin
    oMini := Miniatura(aRutas[iMiniatura], iLado);
    if Assigned(oMini) then
      ACanvas.Canvas.Draw(
        iIzq + (iLado - oMini.Width) div 2,
        iCentro - oMini.Height div 2,
        oMini);
    Inc(iIzq, iLado + iHueco);
  end;
  if Length(aRutas) > iVisibles then
  begin
    sResto := '+' + IntToStr(Length(aRutas) - iVisibles);
    rResto := Rect(iIzq, rCelda.Top, rCelda.Right, rCelda.Bottom);
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    ACanvas.Font.Color := AViewInfo.Params.TextColor;
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(sResto, rResto,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_NOPREFIX);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

end.
