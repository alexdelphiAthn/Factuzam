{******************************************************************************}
{                                                                              }
{  Renderizado VCL del editor de lineas de caja.                               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorLineasRender;

interface

uses
  Uni, cxGraphics, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView;

type
  TContextoRenderEditorLineasCajaVcl = record
    Conexion: TUniConnection;
    ColumnaArticulo: TcxGridDBColumn;
  end;
  TRenderEditorLineasCajaVcl = class
  private
    FContexto: TContextoRenderEditorLineasCajaVcl;
  public
    constructor Create(
      const AContexto: TContextoRenderEditorLineasCajaVcl);
    procedure DibujarCeldaLinea(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure DibujarCeldaStock(
      Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Generics.Collections,
  cxGridCustomView, inLibAtributosPaleta;

constructor TRenderEditorLineasCajaVcl.Create(
  const AContexto: TContextoRenderEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

procedure TRenderEditorLineasCajaVcl.DibujarCeldaLinea(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
var
  Info: TInfoBasico;
  Mapa: TDictionary<string, string>;
  Articulo: string;
  IdValorAtributo: string;
  Texto: string;
begin
  if Assigned(AViewInfo) and Assigned(AViewInfo.Item) and
     Assigned(AViewInfo.GridRecord) and
     (AViewInfo.Item.Tag >= 1) and
     (AViewInfo.Item.Tag <= 5) then
  begin
    Articulo := VarToStr(AViewInfo.GridRecord.Values[
      FContexto.ColumnaArticulo.Index]);
    Texto := AViewInfo.Text;
    Mapa := ObtenerMapaAtributosGlobal(FContexto.Conexion);
    IdValorAtributo := '';
    if Assigned(Mapa) and
       (AViewInfo.Item is TcxGridColumn) then
      Mapa.TryGetValue(
        UpperCase(Trim(TcxGridColumn(AViewInfo.Item).Caption)),
        IdValorAtributo);
    if ObtenerInfoBasicoArticulo(
         FContexto.Conexion,
         Articulo,
         IdValorAtributo,
         Texto,
         Info) then
      ADone := PintarCeldaConCuadradoColor(
        ACanvas,
        AViewInfo,
        Info,
        Texto);
  end;
  if (not ADone) and PintarCeldaSwatchSiAplica(
       FContexto.Conexion,
       ACanvas,
       AViewInfo,
       nil) then
    ADone := True;
end;

procedure TRenderEditorLineasCajaVcl.DibujarCeldaStock(
  Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  if Assigned(AViewInfo) and Assigned(AViewInfo.Item) and
     (AViewInfo.Item.VisibleIndex = 0) and
     PintarCeldaSwatchSiAplica(
       FContexto.Conexion,
       ACanvas,
       AViewInfo,
       nil) then
    ADone := True;
end;

end.
