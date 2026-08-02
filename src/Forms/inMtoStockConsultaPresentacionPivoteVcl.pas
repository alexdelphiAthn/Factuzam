{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionPivoteVcl                       }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presentadores del selector de estado (combo, radios de modo y leyenda) y  }
{    de la rejilla pivote de la consulta de stock. Reciben los controles, el   }
{    repositorio de pivote y cierres de reaccion; nunca el formulario.         }
{******************************************************************************}
unit inMtoStockConsultaPresentacionPivoteVcl;

interface

uses
  System.Classes, System.Generics.Collections, System.Variants,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Data.DB, Uni,
  cxClasses, cxControls, cxContainer, cxEdit, cxTextEdit,
  cxCurrencyEdit, cxDropDownEdit, cxGraphics, cxCustomData,
  cxData, cxDataStorage, cxDBData,
  cxGridCustomTableView, cxGridCustomView, cxGridDBTableView,
  cxGridTableView, cxRadioGroup, cxStyles,
  inLibStockCeldaDocumento,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaPresentacionEstados,
  inLibStockConsultaPresentacionPivote;

type
  TReaccionStockConsulta = reference to procedure;

  TPresentadorEstadosStock = class
  private
    FSeleccion: TSeleccionEstadosStock;
    FCombo: TcxComboBox;
    FRadioSimplificado: TcxRadioButton;
    FRadioDesglosado: TcxRadioButton;
    FPanelLeyenda: TWinControl;
    FAlRecargar: TReaccionStockConsulta;
    FAlGuardarModo: TReaccionStockConsulta;
    procedure RadioClick(Sender: TObject);
    procedure LeyendaClick(Sender: TObject);
    procedure CrearLeyenda;
  public
    constructor Create(
      AOwner: TComponent;
      ACombo: TcxComboBox;
      APanelModo: TWinControl;
      APanelLeyenda: TWinControl;
      AReferencia: TControl;
      const ACaptionSimplificado, ACaptionDesglosado: string;
      const AAlRecargar, AAlGuardarModo: TReaccionStockConsulta);
    destructor Destroy; override;
    procedure PoblarCombo;
    procedure AplicarModo(AModoDesglosado: Boolean);
    procedure MarcarModoEnRadios;
    procedure AplicarColorEstadoActual;
    function EstadoActual: TEstadoStock;
    function ModoDesglosado: Boolean;
  end;

  TPresentadorPivoteStock = class
  private
    FVista: TcxGridDBTableView;
    FOrigen: TDataSource;
    FRepositorio: IRepositorioPivoteStock;
    FConexion: TUniConnection;
    FResultado: IResultadoConsultaStock;
    FColumnas: TList<TcxGridDBColumn>;
    FColumnaGrupo: TcxGridDBColumn;
    FColumnaEstado: TcxGridDBColumn;
    FTallas: TArray<TInfoColumna>;
    FEstilos: array[TEstadoStock] of TcxStyle;
    FEsModoColor: Boolean;
    FEsModoTodo: Boolean;
    procedure CrearEstilos(AOwner: TComponent);
    procedure DibujarCelda(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure EstadoGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure TodoGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure ConfigurarColumnaDatos(AColumna: TcxGridDBColumn;
      AEstado: TEstadoStock);
    function ColumnaEnfocada: TcxGridDBColumn;
  public
    constructor Create(
      AOwner: TComponent;
      AVista: TcxGridDBTableView;
      const ARepositorio: IRepositorioPivoteStock;
      AConexion: TUniConnection);
    destructor Destroy; override;
    procedure Limpiar;
    procedure ReconstruirColumnas(
      const ATallas: TArray<TInfoColumna>;
      APorColor: Boolean; AEstado: TEstadoStock);
    procedure Consultar(const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>);
    function ListarTallas(const ACodigoArticulo: string;
      const AColores: TArray<string>): TArray<TInfoColumna>;
    procedure LeerCeldaEnfocada(var AEstado: TEstadoCeldaStock);
    function TallaEnfocada(out ATalla: string): Boolean;
    function GrupoEnfocado(out AGrupo: string): Boolean;
    function HayFilaEnfocada: Boolean;
    function HayColumnaEnfocada: Boolean;
    function CantidadEnfocada(out ACantidad: Double): Boolean;
    property EsModoColor: Boolean read FEsModoColor;
    property EsModoTodo: Boolean read FEsModoTodo;
    property Tallas: TArray<TInfoColumna> read FTallas;
  end;

implementation

uses
  System.SysUtils,
  inLibAtributosPaleta,
  inLibMsgArticulos;

const
  ANCHO_RADIO_MODO = 110;
  ALTO_RADIO_MODO = 18;
  SEPARACION_RADIO_MODO = 16;
  SEPARACION_ENTRE_RADIOS = 4;
  TOP_LEYENDA = 5;
  MARGEN_LEYENDA = 8;
  SEPARACION_LEYENDA = 14;
  FORMATO_CANTIDAD_STOCK = '#,##0.##;-#,##0.##;0';

constructor TPresentadorEstadosStock.Create(
  AOwner: TComponent;
  ACombo: TcxComboBox;
  APanelModo: TWinControl;
  APanelLeyenda: TWinControl;
  AReferencia: TControl;
  const ACaptionSimplificado, ACaptionDesglosado: string;
  const AAlRecargar, AAlGuardarModo: TReaccionStockConsulta);
begin
  inherited Create;
  FSeleccion := TSeleccionEstadosStock.Create;
  FCombo := ACombo;
  FPanelLeyenda := APanelLeyenda;
  FAlRecargar := AAlRecargar;
  FAlGuardarModo := AAlGuardarModo;
  FRadioSimplificado := TcxRadioButton.Create(AOwner);
  FRadioSimplificado.Parent := APanelModo;
  FRadioSimplificado.Caption := ACaptionSimplificado;
  FRadioSimplificado.SetBounds(
    AReferencia.Left + AReferencia.Width + SEPARACION_RADIO_MODO,
    AReferencia.Top, ANCHO_RADIO_MODO, ALTO_RADIO_MODO);
  FRadioSimplificado.GroupIndex := 1;
  FRadioSimplificado.OnClick := RadioClick;
  FRadioDesglosado := TcxRadioButton.Create(AOwner);
  FRadioDesglosado.Parent := APanelModo;
  FRadioDesglosado.Caption := ACaptionDesglosado;
  FRadioDesglosado.SetBounds(
    FRadioSimplificado.Left + FRadioSimplificado.Width +
      SEPARACION_ENTRE_RADIOS,
    AReferencia.Top, ANCHO_RADIO_MODO, ALTO_RADIO_MODO);
  FRadioDesglosado.GroupIndex := 1;
  FRadioDesglosado.OnClick := RadioClick;
  CrearLeyenda;
end;

destructor TPresentadorEstadosStock.Destroy;
begin
  FAlRecargar := nil;
  FAlGuardarModo := nil;
  FreeAndNil(FSeleccion);
  inherited Destroy;
end;

function TPresentadorEstadosStock.ModoDesglosado: Boolean;
begin
  Result := FSeleccion.ModoDesglosado;
end;

// Mapeo posicion del combo -> estado. Sin seleccion valida se asume
// existencias, que es el estado por defecto de la pantalla.
function TPresentadorEstadosStock.EstadoActual: TEstadoStock;
begin
  if (FCombo.ItemIndex >= 0) and
     (FCombo.ItemIndex < FSeleccion.Cuenta) then
    Result := FSeleccion.Estados[FCombo.ItemIndex]
  else
    Result := esExistencias;
end;

procedure TPresentadorEstadosStock.AplicarColorEstadoActual;
begin
  FCombo.Style.TextColor := TColor(ColorEstadoStock(EstadoActual));
end;

procedure TPresentadorEstadosStock.PoblarCombo;
var
  i: Integer;
begin
  FCombo.Properties.Items.BeginUpdate;
  try
    FCombo.Properties.Items.Clear;
    for i := 0 to FSeleccion.Cuenta - 1 do
      FCombo.Properties.Items.Add(
        NombreEstadoStockCorto(FSeleccion.Estados[i]));
  finally
    FCombo.Properties.Items.EndUpdate;
  end;
  FCombo.ItemIndex := 0;
end;

procedure TPresentadorEstadosStock.MarcarModoEnRadios;
begin
  if FSeleccion.ModoDesglosado then
    FRadioDesglosado.Checked := True
  else
    FRadioSimplificado.Checked := True;
end;

procedure TPresentadorEstadosStock.AplicarModo(AModoDesglosado: Boolean);
begin
  FSeleccion.FijarModo(AModoDesglosado);
  PoblarCombo;
end;

procedure TPresentadorEstadosStock.RadioClick(Sender: TObject);
begin
  FSeleccion.FijarModo(FRadioDesglosado.Checked);
  PoblarCombo;
  FAlGuardarModo();
  FAlRecargar();
end;

// Leyenda al pie: el nombre de cada estado en su color. Pinchar uno lo
// selecciona y, si hace falta, conmuta el modo para que ese estado exista
// en el combo.
procedure TPresentadorEstadosStock.CrearLeyenda;
var
  i: Integer;
  Etiqueta: TLabel;
  iIzquierda: Integer;
begin
  iIzquierda := MARGEN_LEYENDA;
  for i := Low(ESTADOS_LEYENDA_STOCK) to High(ESTADOS_LEYENDA_STOCK) do
  begin
    Etiqueta := TLabel.Create(FPanelLeyenda);
    Etiqueta.Parent := FPanelLeyenda;
    Etiqueta.AutoSize := True;
    Etiqueta.Font.Color :=
      TColor(ColorEstadoStock(ESTADOS_LEYENDA_STOCK[i]));
    Etiqueta.Font.Style := [fsBold];
    Etiqueta.Caption :=
      NombreEstadoStockCorto(ESTADOS_LEYENDA_STOCK[i]);
    Etiqueta.Tag := Ord(ESTADOS_LEYENDA_STOCK[i]);
    Etiqueta.Cursor := crHandPoint;
    Etiqueta.OnClick := LeyendaClick;
    Etiqueta.Top := TOP_LEYENDA;
    Etiqueta.Left := iIzquierda;
    iIzquierda := iIzquierda + Etiqueta.Width + SEPARACION_LEYENDA;
  end;
end;

procedure TPresentadorEstadosStock.LeyendaClick(Sender: TObject);
var
  Resultado: TResultadoLeyendaStock;
begin
  if Sender is TLabel then
  begin
    Resultado := FSeleccion.ResolverLeyenda(
      TEstadoStock(TLabel(Sender).Tag));
    if Resultado.ModoCambiado then
    begin
      MarcarModoEnRadios;
      PoblarCombo;
      FAlGuardarModo();
    end;
    if Resultado.Indice >= 0 then
    begin
      if FCombo.ItemIndex <> Resultado.Indice then
        FCombo.ItemIndex := Resultado.Indice
      else if Resultado.ModoCambiado then
        FAlRecargar();
    end
    else if Resultado.ModoCambiado then
      FAlRecargar();
  end;
end;

constructor TPresentadorPivoteStock.Create(
  AOwner: TComponent;
  AVista: TcxGridDBTableView;
  const ARepositorio: IRepositorioPivoteStock;
  AConexion: TUniConnection);
begin
  inherited Create;
  FVista := AVista;
  FRepositorio := ARepositorio;
  FConexion := AConexion;
  FColumnas := TList<TcxGridDBColumn>.Create;
  FOrigen := TDataSource.Create(AOwner);
  FOrigen.DataSet := nil;
  FVista.DataController.DataSource := FOrigen;
  FVista.OnCustomDrawCell := DibujarCelda;
  CrearEstilos(AOwner);
end;

destructor TPresentadorPivoteStock.Destroy;
begin
  if FOrigen <> nil then
    FOrigen.DataSet := nil;
  FResultado := nil;
  FRepositorio := nil;
  FConexion := nil;
  FreeAndNil(FColumnas);
  FreeAndNil(FOrigen);
  inherited Destroy;
end;

// Un estilo por estado con su TextColor. Es la via que respeta cxGrid:
// modificar AViewInfo.Params.TextColor en OnCustomDrawCell no surte
// efecto porque el render por defecto sobrescribe ese color.
procedure TPresentadorPivoteStock.CrearEstilos(AOwner: TComponent);
var
  Estado: TEstadoStock;
  Estilo: TcxStyle;
begin
  for Estado := Low(TEstadoStock) to High(TEstadoStock) do
  begin
    Estilo := TcxStyle.Create(AOwner);
    Estilo.AssignedValues := [svTextColor];
    Estilo.TextColor := TColor(ColorEstadoStock(Estado));
    FEstilos[Estado] := Estilo;
  end;
end;

procedure TPresentadorPivoteStock.Limpiar;
begin
  FOrigen.DataSet := nil;
  FResultado := nil;
end;

function TPresentadorPivoteStock.ListarTallas(
  const ACodigoArticulo: string;
  const AColores: TArray<string>): TArray<TInfoColumna>;
begin
  Result := FRepositorio.ListarTallas(ACodigoArticulo, AColores);
end;

procedure TPresentadorPivoteStock.Consultar(
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>);
begin
  FResultado := FRepositorio.Consultar(ASolicitud, ATallas);
  FOrigen.DataSet := FResultado.DataSet;
end;

procedure TPresentadorPivoteStock.ConfigurarColumnaDatos(
  AColumna: TcxGridDBColumn; AEstado: TEstadoStock);
begin
  AColumna.PropertiesClassName := 'TcxCurrencyEditProperties';
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat :=
    FORMATO_CANTIDAD_STOCK;
  TcxCurrencyEditProperties(
    AColumna.Properties).UseDisplayFormatWhenEditing := True;
  AColumna.HeaderAlignmentHorz := taCenter;
  AColumna.Options.Editing := False;
  AColumna.Options.Sorting := False;
  if FEsModoTodo then
    AColumna.Styles.OnGetContentStyle := TodoGetContentStyle
  else
    AColumna.Styles.Content := FEstilos[AEstado];
end;

// Las columnas del pivote son todas dinamicas: se liberan y se vuelven a
// crear en cada recarga a partir del mapa que decide inLib.
procedure TPresentadorPivoteStock.ReconstruirColumnas(
  const ATallas: TArray<TInfoColumna>;
  APorColor: Boolean; AEstado: TEstadoStock);
var
  Definiciones: TDefinicionesColumnasPivote;
  Definicion: TDefinicionColumnaPivote;
  Columna: TcxGridDBColumn;
  i: Integer;
  sTituloGrupo: string;
begin
  for i := FColumnas.Count - 1 downto 0 do
    FColumnas[i].Free;
  FColumnas.Clear;
  FColumnaGrupo := nil;
  FColumnaEstado := nil;
  FEsModoColor := APorColor;
  FEsModoTodo := AEstado = esTodoAlaVez;
  if APorColor then
    sTituloGrupo := SCaptionColColor
  else
    sTituloGrupo := SCaptionColAlmacen;
  Definiciones := DefinirColumnasPivoteStock(
    ATallas, APorColor, FEsModoTodo, sTituloGrupo,
    SCaptionColEstado, SCaptionColTotal);
  for Definicion in Definiciones do
  begin
    Columna := FVista.CreateColumn;
    Columna.Caption := Definicion.Titulo;
    Columna.DataBinding.FieldName := Definicion.Campo;
    Columna.Width := Definicion.Ancho;
    case Definicion.Clase of
      cpsGrupo:
        begin
          Columna.HeaderAlignmentHorz := taLeftJustify;
          Columna.Options.Sorting := False;
          FColumnaGrupo := Columna;
        end;
      cpsEstado:
        begin
          Columna.OnGetDisplayText := EstadoGetDisplayText;
          Columna.HeaderAlignmentHorz := taLeftJustify;
          Columna.Options.Sorting := False;
          Columna.Styles.OnGetContentStyle := TodoGetContentStyle;
          FColumnaEstado := Columna;
        end;
    else
      ConfigurarColumnaDatos(Columna, AEstado);
    end;
    FColumnas.Add(Columna);
  end;
  FTallas := Copy(ATallas);
end;

// Devuelve el estilo del estado de la fila para que en modo "Todo a la
// vez" cada fila se pinte con el color de su estado.
procedure TPresentadorPivoteStock.TodoGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  iEstado: Integer;
begin
  if (FColumnaEstado <> nil) and (ARecord <> nil) then
  begin
    iEstado := StrToIntDef(
      VarToStr(ARecord.Values[FColumnaEstado.Index]), -1);
    if EsEstadoStockValido(iEstado) then
      AStyle := FEstilos[TEstadoStock(iEstado)];
  end;
end;

// Convierte el ESTADO_NUM crudo en su nombre corto, para no meter
// cadenas de presentacion en el SQL del pivote.
procedure TPresentadorPivoteStock.EstadoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
var
  iEstado: Integer;
begin
  iEstado := StrToIntDef(AText, -1);
  if EsEstadoStockValido(iEstado) then
    AText := NombreEstadoStockCorto(TEstadoStock(iEstado));
end;

// Solo se pinta el cuadradito del color basico delante del texto en la
// columna de grupo del modo Por Color. El color del resto de celdas va
// por cxStyles.
procedure TPresentadorPivoteStock.DibujarCelda(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  ADone := False;
  if FEsModoColor and (FColumnaGrupo <> nil) and
     (AViewInfo.Item is TcxGridDBColumn) and
     (AViewInfo.Item = FColumnaGrupo) then
  begin
    if PintarCeldaSwatchSiAplica(FConexion, ACanvas, AViewInfo, nil) then
      ADone := True;
  end;
end;

function TPresentadorPivoteStock.ColumnaEnfocada: TcxGridDBColumn;
begin
  Result := nil;
  if FVista.Controller.FocusedColumn is TcxGridDBColumn then
    Result := TcxGridDBColumn(FVista.Controller.FocusedColumn);
end;

function TPresentadorPivoteStock.HayFilaEnfocada: Boolean;
begin
  Result := FVista.Controller.FocusedRecord <> nil;
end;

function TPresentadorPivoteStock.HayColumnaEnfocada: Boolean;
begin
  Result := ColumnaEnfocada <> nil;
end;

function TPresentadorPivoteStock.TallaEnfocada(
  out ATalla: string): Boolean;
var
  Columna: TcxGridDBColumn;
begin
  ATalla := '';
  Columna := ColumnaEnfocada;
  Result := (Columna <> nil) and
            TallaDeColumnaPivoteStock(
              Columna.DataBinding.FieldName, FTallas, ATalla);
end;

function TPresentadorPivoteStock.GrupoEnfocado(
  out AGrupo: string): Boolean;
var
  Registro: TcxCustomGridRecord;
begin
  AGrupo := '';
  Registro := FVista.Controller.FocusedRecord;
  Result := (Registro <> nil) and (FColumnaGrupo <> nil);
  if Result then
    AGrupo := VarToStr(Registro.Values[FColumnaGrupo.Index]);
end;

// Cantidad de la celda enfocada. Devuelve False cuando la celda esta
// vacia, para que el llamador la trate como stock cero.
function TPresentadorPivoteStock.CantidadEnfocada(
  out ACantidad: Double): Boolean;
var
  Columna: TcxGridDBColumn;
  Registro: TcxCustomGridRecord;
  vValor: Variant;
begin
  Result := False;
  ACantidad := 0;
  Columna := ColumnaEnfocada;
  Registro := FVista.Controller.FocusedRecord;
  if (Columna <> nil) and (Registro <> nil) then
  begin
    vValor := Registro.Values[Columna.Index];
    if not (VarIsNull(vValor) or VarIsEmpty(vValor)) then
    begin
      ACantidad := VarAsType(vValor, varDouble);
      Result := True;
    end;
  end;
end;

// Vuelca en el estado de celda todo lo que depende de la rejilla; las
// decisiones viven en inLibStockCeldaDocumento.
procedure TPresentadorPivoteStock.LeerCeldaEnfocada(
  var AEstado: TEstadoCeldaStock);
var
  Columna: TcxGridDBColumn;
  Registro: TcxCustomGridRecord;
  i: Integer;
begin
  AEstado.EsModoTodo := FEsModoTodo;
  AEstado.EsModoColor := FEsModoColor;
  SetLength(AEstado.Tallas, Length(FTallas));
  for i := 0 to High(FTallas) do
    AEstado.Tallas[i] := FTallas[i].Codigo;
  Registro := FVista.Controller.FocusedRecord;
  AEstado.HayFila := Registro <> nil;
  Columna := ColumnaEnfocada;
  if Columna <> nil then
  begin
    AEstado.HayColumnaDeDatos := True;
    AEstado.NombreCampo := Columna.DataBinding.FieldName;
  end;
  if AEstado.HayFila and (FColumnaEstado <> nil) then
    AEstado.FilaEsExistencias :=
      StrToIntDef(
        VarToStr(Registro.Values[FColumnaEstado.Index]), -1) =
        Ord(esExistencias);
  if AEstado.HayFila and (FColumnaGrupo <> nil) then
  begin
    AEstado.HayColumnaGrupo := True;
    AEstado.Grupo := VarToStr(Registro.Values[FColumnaGrupo.Index]);
  end;
end;

end.
