{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, fsStayOnTop)                            }
{ Version:       0.5.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta de stock invocable con Ctrl+U desde cualquier mantenimiento      }
{    que herede de TfrmMtoGen. Al abrirse pre-carga el articulo / SKU activo   }
{    via TfrmMtoGen.ResolverArtSkuActivo.                                      }
{                                                                              }
{    Layout (estilo OdaGest+):                                                 }
{      - Cabecera (pnlCabecera): boton de busqueda de articulo + descripcion   }
{        + bloque de info (temporada, tarifas, proveedores) + foto.            }
{      - Filtros (pnlFiltros): combo "Estado del stock".                       }
{      - Cuerpo (pnlBody): split horizontal con un TSplitter.                  }
{        * pnlIzq (alLeft, 280px): pcFiltros con dos pestanas                  }
{            "1 Colores"   -> clbColores (checklist de AVs de color)           }
{            "2 Almacenes" -> clbAlmacenes (checklist de almacenes activos)    }
{        * pnlDer (alClient): pcVistas (alTop, 30px) con dos pestanas          }
{            "3 Por almacenes" -> grid con almacenes como filas                }
{            "4 Por colores"   -> grid con colores como filas                  }
{          y el TcxGrid (alClient) compartido. La pestana activa de pcVistas   }
{          determina el modo de pivote y se aplica como filtro cruzado el      }
{          checklist opuesto.                                                  }
{                                                                              }
{    v0.5: estado "Todo a la vez" en el combo + colores por estado. Cada      }
{    estado pinta las celdas de datos con un color distintivo (azul para      }
{    existencias, rojo para ventas, naranja para pte. recibir, etc.) y el     }
{    combo seleccionado refleja ese color. En modo "Todo a la vez" el grid    }
{    desdobla cada fila de grupo (almacen o color) en una fila por estado    }
{    con datos, pintando cada fila en el color de su estado.                  }
{    v0.4: split horizontal estilo OdaGest+ — checklist a la izquierda,        }
{    pestanas de vista pivote arriba del grid a la derecha. Tabs numeradas     }
{    1/2/3/4 como en el original.                                              }
{    v0.3: temporada en cabecera, formato de tarifas/proveedores depurado,     }
{    layout reorganizado: checklist de almacenes movido a la pestana Por       }
{    Almacen y checklist nuevo de colores en la pestana Por Color.             }
{    v0.2: pivote dinamico, colores con swatch en cabecera, panel de           }
{    precios/proveedores. Estado "Prestadas" sigue siendo stub.                }
{******************************************************************************}
unit inMtoStockConsulta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Data.DB, DBAccess, Uni,
  cxClasses, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxButtonEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCheckBox, cxCheckListBox, cxCustomData, cxStyles,
  cxCurrencyEdit,
  cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxGraphics, cxLocalization,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxScrollbarAnnotations,
  dxDateRanges, cxMemo, cxControls, dxCoreGraphics, cxCustomListBox,
  cxRadioGroup;

const
  // Procesado diferido de una lectura con pistola (fuera del propio evento de
  // tecla, para no reentrar en el control que la esta procesando).
  WM_PROCESAR_SCANNER_STOCK = WM_USER + 77;
  // Detector por velocidad de tecleo (codigo de barras + CR, sin STX/ETX).
  SCAN_VEL_MS   = 40;   // max. ms entre teclas para considerarlo lector
  SCAN_MIN_LONG = 4;    // longitud minima del codigo

type
  TEstadoStock = (
    esExistencias,
    esEntradas,            // total de entradas (suma acumulados ENT)
    esSalidas,             // total de salidas  (suma acumulados SAL)
    esVentas,              // VE (SAL)
    esRegularizadas,       // IN (ENT)
    esEntradaTraspaso,     // TR/AT (ENT)
    esSalidaTraspaso,      // TR/AT (SAL)
    esPdteRecibir,
    esPdteServir,
    esPrestadas,           // stub
    esTodoAlaVez,
    // Desglosado:
    esEntradaCompra,       // AC (ENT)
    esEntradaDeposito,     // DP (ENT) - incluye préstamo
    esSalidaDeposito,      // DP (SAL)
    esSalidaAlbVenta,      // AV (SAL)
    esEntradaAlbEntrada    // AE (ENT)
  );

  TInfoColumna = record
    Codigo : string;     // CODIGO_ALM o AV del color
    Texto  : string;     // Caption a mostrar
    Hex    : string;     // HEX (solo para color, '' si no)
    EsColor: Boolean;
  end;

  TfrmStockConsulta = class(TForm)
    pnlCabecera   : TPanel;
      lblArt        : TcxLabel;
      btnArt        : TcxButtonEdit;
      lblDescr      : TcxLabel;
      lblInfo       : TcxLabel;
      imgFoto       : TImage;
    pnlFiltros    : TPanel;
      lblEstado     : TcxLabel;
      cbbEstado     : TcxComboBox;
    pnlBody       : TPanel;
    pnlIzq        : TPanel;
    pcFiltros     : TcxPageControl;
    tsColores     : TcxTabSheet;
    lblColores    : TcxLabel;
    clbColores    : TcxCheckListBox;
    tsAlmacenes   : TcxTabSheet;
    lblAlmacenes  : TcxLabel;
    clbAlmacenes  : TcxCheckListBox;
    splVert       : TSplitter;
    pnlDer        : TPanel;
    pcVistas      : TcxPageControl;
    tsPorAlmacen  : TcxTabSheet;
    tsPorColor    : TcxTabSheet;
    grdStock      : TcxGrid;
    tvStock       : TcxGridDBTableView;
    glStock       : TcxGridLevel;
    pnlLeyenda    : TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnArtPropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure clbAlmacenesClickCheck(Sender: TObject; AIndex: Integer;
              APrevState, ANewState: TcxCheckBoxState);
    procedure clbColoresClickCheck(Sender: TObject; AIndex: Integer;
              APrevState, ANewState: TcxCheckBoxState);
    procedure pcVistasChange(Sender: TObject);
    procedure tvStockCustomDrawCell(Sender: TcxCustomGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
              var ADone: Boolean);
    procedure ColEstadoGetDisplayText(Sender: TcxCustomGridTableItem;
              ARecord: TcxCustomGridRecord; var AText: string);
    procedure ColTodoGetContentStyle(Sender: TcxCustomGridTableView;
              ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
              var AStyle: TcxStyle);
  private
    FQry        : TUniQuery;
    FDs         : TDataSource;
    FCodArt     : string;
    FCodSku     : string;
    FColumnas   : TArray<TInfoColumna>;  // Tallas (columnas dinamicas)
    FColsDin    : TList<TcxGridDBColumn>;
    FColGrupo   : TcxGridDBColumn;       // nombre de la fila (color o alm)
    FColEstado  : TcxGridDBColumn;       // nombre del estado (solo en Todo a la vez)
    FEsModoColor: Boolean;
    FEsModoTodo : Boolean;               // estado=esTodoAlaVez en la ultima recarga
    FStyEstado  : array[TEstadoStock] of TcxStyle; // un estilo por estado
    FEstadosCombo : TList<TEstadoStock>; // mapeo combo.ItemIndex -> estado
    FModoDesglosado : Boolean;
    FVerCoste       : Boolean;   // permiso para ver el coste (precio compra)
    FrbSimplificado : TcxRadioButton;
    FrbDesglosado   : TcxRadioButton;
    // Lectura con pistola a nivel de formulario (KeyPreview=True): trama
    // STX/ETX y deteccion por velocidad de tecleo. Resuelve el codigo SOLO
    // contra codigos de barras y carga el articulo via SetArticuloSku, este
    // donde este el foco.
    FScanBuffer     : string;
    FLeyendoScanner : Boolean;
    FScanVelBuffer  : string;
    FScanVelTick    : Cardinal;
    FScanVelComido  : Boolean;
    FCodigoScanPend : string;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure AplicarLecturaCodigoBarras(const ACodigo: string);
    procedure WMProcesarScannerStock(var Msg: TMessage);
                                       message WM_PROCESAR_SCANNER_STOCK;
    procedure   PoblarComboEstados;
    procedure   GuardarModoUsuario;
    procedure   CargarModoUsuario;
    procedure   rbModoClick(Sender: TObject);
    procedure CargarAlmacenes;
    procedure CargarColores;
    procedure CargarFoto;
    procedure CargarInfoCabecera;
    procedure CrearLeyenda;
    procedure CrearEstilosEstado;
    function  EstadoActual: TEstadoStock;
    function  AlmacenesSeleccionadosSQL: string;  // 'CODA','CODB' o NULL
    function  AlmacenesSeleccionadosLista: TArray<string>;
    function  ColoresSeleccionadosSQL: string;    // 'CO1','CO2' o NULL
    function  ColoresSeleccionadosLista: TArray<string>;
    function  BuscarArticulo: string;
    function  TallasArticulo: TArray<TInfoColumna>;
    function  ConstruirSQLPivot(const ATallas: TArray<TInfoColumna>;
                                 AEsColor: Boolean): string;
    function  EstadoBaseSelect: string;  // CTE/source segun estado
    function  EstadoBaseSelectFor(AEstado: TEstadoStock): string;
    procedure ReconstruirColumnas(const ATallas: TArray<TInfoColumna>;
                                   AEsColor: Boolean);
    procedure RecargarConsulta;
    procedure MostrarError(const AMsg: string);
  public
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
  end;

var
  frmStockConsulta: TfrmStockConsulta;

/// Abre (o trae al frente) la consulta de stock con el (articulo, sku)
/// indicado. Mismo patron que inMtoFotoArticulo.MostrarFotoFlotante.
procedure MostrarStockConsulta(AOwner: TComponent;
                               const ACodArt, ACodSku: string);

implementation

uses
  System.StrUtils,
  inLibGlobalVar, inLibAppParam, inLibFotos, inLibAtributosPaleta,
  inLibGenBusq, inLibUser, UniDataPerfiles, inLibPermisos,
  inLibArticulosValidador;

{$R *.dfm}

// ---------------------------------------------------------------------------
//  Colores por estado del stock (texto en las celdas / combo seleccionado)
// ---------------------------------------------------------------------------
// Misma idea que la leyenda inferior de OdaGest+: cada estado tiene un
// color distintivo. Las celdas de datos del grid se pintan con el color
// del estado activo, y en modo "Todo a la vez" cada fila se colorea con
// el color de su estado. Los valores BGR siguen el orden de Delphi
// ($00BBGGRR), por eso el naranja sale como $000080FF.
function ColorEstado(AEstado: TEstadoStock): TColor;
begin
  case AEstado of
    esExistencias:        Result := clNavy;
    esEntradas:           Result := clGreen;
    esSalidas:            Result := clMaroon;
    esVentas:             Result := clRed;
    esEntradaTraspaso:    Result := clTeal;
    esSalidaTraspaso:     Result := clPurple;
    esRegularizadas:      Result := clPurple;
    esPdteRecibir:        Result := $000080FF;
    esPdteServir:         Result := clTeal;
    esPrestadas:          Result := clGray;
    esEntradaCompra:      Result := $00008000;  // verde oscuro
    esEntradaDeposito:    Result := $00CC9900;  // ámbar
    esSalidaDeposito:     Result := $0099CCFF;  // amarillo claro
    esSalidaAlbVenta:     Result := $000000C0;  // rojo oscuro
    esEntradaAlbEntrada:  Result := $0000C000;  // verde claro
  else
    Result := clBlack;
  end;
end;

function NombreEstadoCorto(AEstado: TEstadoStock): string;
begin
  case AEstado of
    esExistencias:        Result := 'Existencias';
    esEntradas:           Result := 'Entradas';
    esSalidas:            Result := 'Salidas';
    esVentas:             Result := 'Ventas';
    esRegularizadas:      Result := 'Regulariz.';
    esEntradaTraspaso:    Result := 'Ent. traspaso';
    esSalidaTraspaso:     Result := 'Sal. traspaso';
    esPdteRecibir:        Result := 'Pte. recibir';
    esPdteServir:         Result := 'Pte. servir';
    esPrestadas:          Result := 'Prestadas';
    esTodoAlaVez:         Result := 'Todos los estados';
    esEntradaCompra:      Result := 'Ent. compra';
    esEntradaDeposito:    Result := 'Ent. depósito';
    esSalidaDeposito:     Result := 'Sal. depósito';
    esSalidaAlbVenta:     Result := 'Alb. venta';
    esEntradaAlbEntrada:  Result := 'Alb. entrada';
  else
    Result := '';
  end;
end;

// ---------------------------------------------------------------------------
//  Funcion publica de apertura
// ---------------------------------------------------------------------------
procedure MostrarStockConsulta(AOwner: TComponent;
                               const ACodArt, ACodSku: string);
begin
  if frmStockConsulta = nil then
    frmStockConsulta := TfrmStockConsulta.Create(Application);
  frmStockConsulta.SetArticuloSku(ACodArt, ACodSku);
  if frmStockConsulta.WindowState = wsMinimized then
    frmStockConsulta.WindowState := wsNormal;
  // Mostrar CON foco para que ESC cierre la ventana sin tener que pinchar
  // antes. Antes se mostraba con SW_SHOWNOACTIVATE y devolvia el foco a la
  // ventana anterior, lo que dejaba la consulta imposible de cerrar con ESC.
  frmStockConsulta.Visible := True;
  frmStockConsulta.BringToFront;
  SetForegroundWindow(frmStockConsulta.Handle);
end;

// ---------------------------------------------------------------------------
//  Form
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.FormCreate(Sender: TObject);
begin
  Self.Position := poDesigned;
  Self.FormStyle := fsStayOnTop;
  // ESC cierra la ventana; KeyPreview para capturarlo aunque el foco este
  // en el grid o el combo. Tambien sirve al hook del lector de codigo de
  // barras (FormKeyPress / FormKeyDown), que captura la lectura venga de
  // donde venga el foco.
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  Self.OnKeyPress := FormKeyPress;
  // Coste (ultimo precio de compra del proveedor) solo para quien tenga
  // permiso: TienePermiso devuelve True siempre a admin; al resto, oculto
  // por defecto salvo permiso explicito 'caja.verCoste'.
  FVerCoste := Assigned(oPermisos) and
               oPermisos.TienePermiso('caja.verCoste', False);
  FQry := TUniQuery.Create(Self);
  FQry.Connection := inLibGlobalVar.oConn;
  FDs  := TDataSource.Create(Self);
  FDs.DataSet := FQry;
  tvStock.DataController.DataSource := FDs;
  FColsDin := TList<TcxGridDBColumn>.Create;
  // Custom-draw para pintar el cuadradito del color basico en la celda
  // del color, via la libreria inLibAtributosPaleta (que se encarga del
  // lookup contra fza_atributos_basicos por texto/codigo y la cache).
  tvStock.OnCustomDrawCell := tvStockCustomDrawCell;

  // Lista paralela combo -> estado y radios de modo
  FEstadosCombo := TList<TEstadoStock>.Create;
  FrbSimplificado := TcxRadioButton.Create(Self);
  FrbSimplificado.Parent := pnlFiltros;
  FrbSimplificado.Caption := 'Simplificado';
  FrbSimplificado.SetBounds(cbbEstado.Left + cbbEstado.Width + 16,
                            cbbEstado.Top, 110, 18);
  FrbSimplificado.GroupIndex := 1;
  FrbSimplificado.OnClick := rbModoClick;
  FrbDesglosado := TcxRadioButton.Create(Self);
  FrbDesglosado.Parent := pnlFiltros;
  FrbDesglosado.Caption := 'Desglosado';
  FrbDesglosado.SetBounds(FrbSimplificado.Left + FrbSimplificado.Width + 4,
                          cbbEstado.Top, 110, 18);
  FrbDesglosado.GroupIndex := 1;
  FrbDesglosado.OnClick := rbModoClick;
  CargarModoUsuario;
  if FModoDesglosado then
    FrbDesglosado.Checked := True
  else
    FrbSimplificado.Checked := True;
  PoblarComboEstados;
  cbbEstado.Style.TextColor := ColorEstado(esExistencias);

  pcVistas.ActivePage := tsPorAlmacen;
  pcFiltros.ActivePage := tsColores;
  CrearEstilosEstado;
  CrearLeyenda;
  CargarAlmacenes;
end;

procedure TfrmStockConsulta.PoblarComboEstados;
  procedure AddEstado(AEstado: TEstadoStock);
  begin
    cbbEstado.Properties.Items.Add(NombreEstadoCorto(AEstado));
    FEstadosCombo.Add(AEstado);
  end;
begin
  cbbEstado.Properties.Items.BeginUpdate;
  try
    cbbEstado.Properties.Items.Clear;
    FEstadosCombo.Clear;
    AddEstado(esExistencias);
    // Los totales agregados de entradas/salidas solo en modo simplificado;
    // en desglosado se sustituyen por sus subtipos para no mezclar el
    // agregado con su propio desglose.
    if not FModoDesglosado then
    begin
      AddEstado(esEntradas);
      AddEstado(esSalidas);
    end;
    AddEstado(esPdteServir);
    AddEstado(esPdteRecibir);
    AddEstado(esTodoAlaVez);
    if FModoDesglosado then
    begin
      AddEstado(esEntradaCompra);
      AddEstado(esEntradaTraspaso);
      AddEstado(esSalidaTraspaso);
      AddEstado(esEntradaDeposito);
      AddEstado(esSalidaDeposito);
      AddEstado(esVentas);
      AddEstado(esRegularizadas);
      AddEstado(esSalidaAlbVenta);
      AddEstado(esEntradaAlbEntrada);
      AddEstado(esPrestadas);
    end;
  finally
    cbbEstado.Properties.Items.EndUpdate;
  end;
  cbbEstado.ItemIndex := 0;
end;

procedure TfrmStockConsulta.rbModoClick(Sender: TObject);
begin
  FModoDesglosado := FrbDesglosado.Checked;
  PoblarComboEstados;
  GuardarModoUsuario;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.CargarModoUsuario;
var
  dic: TProfileDicc;
begin
  dic := nil;
  try
    GetFormUserProfile(dic, 'frmStockConsulta',
                       inLibGlobalVar.oUser, inLibGlobalVar.oGroup);
    FModoDesglosado := SameText(
      GetPerfilValueDef(dic, 'ModoDesglosado', 'N'), 'S');
  finally
    if dic <> nil then
      FreeAndNil(dic);
  end;
end;

procedure TfrmStockConsulta.GuardarModoUsuario;
begin
  if odmPerfiles <> nil then
    odmPerfiles.GrabarPerfil(inLibGlobalVar.oUser, 'frmStockConsulta',
                             'ModoDesglosado',
                             IfThen(FModoDesglosado, 'S', 'N'));
end;

// Crea un TcxStyle por estado con su TextColor. Los asignamos como
// Styles.Content de las columnas de datos en modo normal y se usan via
// OnGetContentStyle en modo "Todo a la vez" para pintar cada fila en
// el color de su estado. La via Styles.Content es la que respeta cxGrid
// — modificar AViewInfo.Params.TextColor en OnCustomDrawCell no surte
// efecto porque el render por defecto sobrescribe ese color.
procedure TfrmStockConsulta.CrearEstilosEstado;
var
  est: TEstadoStock;
  sty: TcxStyle;
begin
  for est := Low(TEstadoStock) to High(TEstadoStock) do
  begin
    sty := TcxStyle.Create(Self);
    sty.AssignedValues := [svTextColor];
    sty.TextColor      := ColorEstado(est);
    FStyEstado[est]    := sty;
  end;
end;

// ---------------------------------------------------------------------------
//  Leyenda al pie del formulario: nombre de cada estado en su color, igual
//  que la leyenda inferior de OdaGest+. Se construye dinamicamente con
//  TLabels para que añadir un estado nuevo se reduzca a tocar ColorEstado
//  y NombreEstadoCorto.
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CrearLeyenda;
const
  ESTADOS_LEYENDA: array[0..7] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas, esVentas, esRegularizadas,
    esPdteRecibir, esPdteServir, esPrestadas);
var
  i: Integer;
  lbl: TLabel;
  x: Integer;
begin
  x := 8;
  for i := Low(ESTADOS_LEYENDA) to High(ESTADOS_LEYENDA) do
  begin
    lbl := TLabel.Create(pnlLeyenda);
    lbl.Parent     := pnlLeyenda;
    lbl.AutoSize   := True;
    lbl.Font.Color := ColorEstado(ESTADOS_LEYENDA[i]);
    lbl.Font.Style := [fsBold];
    lbl.Caption    := NombreEstadoCorto(ESTADOS_LEYENDA[i]);
    lbl.Top        := 5;
    lbl.Left       := x;
    x := x + lbl.Width + 14;
  end;
end;

procedure TfrmStockConsulta.FormDestroy(Sender: TObject);
begin
  if Assigned(FQry) then
  begin
    if FQry.Active then FQry.Close;
    FreeAndNil(FQry);
  end;
  FreeAndNil(FDs);
  FreeAndNil(FColsDin);
  FreeAndNil(FEstadosCombo);
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

// ESC oculta la ventana flotante. KeyPreview=True (FormCreate) garantiza que
// el form vea la tecla aunque el foco este en el grid, el combo o un check.
procedure TfrmStockConsulta.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  delta: Cardinal;
begin
  // Solo activo de forma transitoria entre el VK_RETURN consumido como lectura
  // y su #13 de KeyPress; lo reseteamos en cada tecla para que no se quede
  // obsoleto y se trague un Enter normal.
  FScanVelComido := False;
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end
  else if Key = VK_RETURN then
  begin
    // Cierre del detector por velocidad: si el buffer es una rafaga del lector
    // y el Enter llega igual de rapido, lo tratamos como codigo de barras.
    delta := GetTickCount - FScanVelTick;
    if (Length(FScanVelBuffer) >= SCAN_MIN_LONG) and (delta <= SCAN_VEL_MS) then
    begin
      FCodigoScanPend := Trim(FScanVelBuffer);
      FScanVelBuffer  := '';
      FScanVelComido  := True;  // tragaremos el #13 que vendra por KeyPress
      Key := 0;
      PostMessage(Handle, WM_PROCESAR_SCANNER_STOCK, 0, 0);
    end;
  end;
end;

// Hook del lector a nivel de formulario. Trama STX/ETX (teclas consumidas) y
// deteccion por velocidad (la rafaga rapida se consume para no disparar el
// EditValueChanged de btnArt en cada tecla; el primer caracter, lento, no se
// consume para no romper el tecleo manual). La decision final del detector por
// velocidad se cierra en FormKeyDown (VK_RETURN).
procedure TfrmStockConsulta.FormKeyPress(Sender: TObject; var Key: Char);
var
  ahora, delta: Cardinal;
begin
  if Key = #2 then
  begin
    FLeyendoScanner := True;
    FScanBuffer := '';
    FScanVelBuffer := '';
    Key := #0;
    Exit;
  end;
  if FLeyendoScanner then
  begin
    if Key = #3 then
    begin
      FLeyendoScanner := False;
      Key := #0;
      if Trim(FScanBuffer) <> '' then
      begin
        FCodigoScanPend := Trim(FScanBuffer);
        PostMessage(Handle, WM_PROCESAR_SCANNER_STOCK, 0, 0);
      end;
      FScanBuffer := '';
    end
    else
    begin
      FScanBuffer := FScanBuffer + Key;
      Key := #0;
    end;
    Exit;
  end;
  // Detector por velocidad de tecleo.
  ahora := GetTickCount;
  delta := ahora - FScanVelTick;
  FScanVelTick := ahora;
  if FScanVelComido and (Key = #13) then
  begin
    FScanVelComido := False;
    Key := #0;
    Exit;
  end;
  if Key >= ' ' then
  begin
    if delta <= SCAN_VEL_MS then
    begin
      // Tecla rapida (parte de la rafaga): la acumulamos y la consumimos para
      // que no llegue a btnArt y dispare SetArticuloSku en cada pulsacion.
      FScanVelBuffer := FScanVelBuffer + Key;
      Key := #0;
    end
    else
      // Primer caracter (lento): no se consume; podria ser tecleo manual.
      FScanVelBuffer := Key;
  end
  else
    FScanVelBuffer := '';
end;

procedure TfrmStockConsulta.WMProcesarScannerStock(var Msg: TMessage);
begin
  if FCodigoScanPend <> '' then
  begin
    AplicarLecturaCodigoBarras(FCodigoScanPend);
    FCodigoScanPend := '';
  end;
end;

// Resuelve el codigo SOLO contra codigos de barras y carga el articulo/SKU en
// la consulta (igual que al teclear o buscar un articulo, pero a partir del
// codigo de barras leido).
procedure TfrmStockConsulta.AplicarLecturaCodigoBarras(const ACodigo: string);
var
  Validador  : TArticulosValidador;
  Resolucion : TArtResolucionEntrada;
begin
  Validador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  try
    Resolucion := Validador.ResolverCodigoBarras(ACodigo);
  finally
    FreeAndNil(Validador);
  end;
  if Resolucion.Encontrado then
    SetArticuloSku(Resolucion.CodigoArticulo, Resolucion.CodigoSku)
  else
    MostrarError('Código de barras no encontrado: ' + ACodigo);
end;

// Muestra un mensaje de error por ENCIMA de la ventana. Como el form es
// fsStayOnTop, un dialogo normal saldria por detras y la app pareceria
// colgada; MB_TOPMOST + MB_SETFOREGROUND fuerzan el aviso al frente.
procedure TfrmStockConsulta.MostrarError(const AMsg: string);
begin
  Application.MessageBox(PChar(AMsg), 'Consulta de stock',
    MB_OK or MB_ICONERROR or MB_TOPMOST or MB_SETFOREGROUND);
end;

// ---------------------------------------------------------------------------
//  Almacenes (check-list)
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CargarAlmacenes;
var
  q   : TUniQuery;
  item: TcxCheckListBoxItem;
  bStd: Boolean;
begin
  clbAlmacenes.Items.Clear;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM, TIPO_USO_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    q.Open;
    while not q.Eof do
    begin
      item := clbAlmacenes.Items.Add;
      item.Text := q.FieldByName('CODIGO_ALM_ALM').AsString + ' - ' +
                   q.FieldByName('NOMBRE_ALM_ALM').AsString;
      bStd := (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDAR') or
              (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDARD');
      if bStd then item.State := cbsChecked else item.State := cbsUnchecked;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosLista: TArray<string>;
var
  i, p: Integer;
  s, sCod: string;
begin
  SetLength(Result, 0);
  for i := 0 to clbAlmacenes.Items.Count - 1 do
    if clbAlmacenes.Items[i].State = cbsChecked then
    begin
      s := clbAlmacenes.Items[i].Text;
      p := Pos(' - ', s);
      if p > 0 then sCod := Copy(s, 1, p - 1) else sCod := s;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := sCod;
    end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosSQL: string;
var
  alms: TArray<string>;
  i: Integer;
begin
  alms := AlmacenesSeleccionadosLista;
  if Length(alms) = 0 then
  begin
    Result := 'NULL';
    Exit;
  end;
  Result := '';
  for i := 0 to High(alms) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + QuotedStr(alms[i]);
  end;
end;

// ---------------------------------------------------------------------------
//  Colores del articulo (check-list de la pestana "Por Color")
// ---------------------------------------------------------------------------
// Carga los AVs distintos de color (ID_VA_AV='CO') que aparecen en los SKUs
// activos del articulo. Por defecto todos marcados; el usuario puede
// desmarcar para filtrar las filas (modo Por Color) o las cantidades
// agregadas (modo Por Almacen).
procedure TfrmStockConsulta.CargarColores;
var
  q   : TUniQuery;
  item: TcxCheckListBoxItem;
begin
  clbColores.Items.Clear;
  if Trim(FCodArt) = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // GROUP BY AV.AV para deduplicar por nombre de color: en
    // fza_atributos_valores puede haber varios ID_AV con el mismo texto
    // (ej. NEGRO con ID_AV=100 y otro NEGRO con otro ID_AV/ORDEN_AV).
    // En el checklist y en el grid los queremos como UNA sola entrada.
    q.SQL.Text :=
      'SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_atributos_sku SA ' +
      '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      ' WHERE SKU.CODIGO_ART_SKU = :art ' +
      '   AND AV.ID_VA_AV = ''CO'' ' +
      ' GROUP BY AV.AV ' +
      ' ORDER BY MIN(AV.ORDEN_AV), AV.AV';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    while not q.Eof do
    begin
      item := clbColores.Items.Add;
      item.Text  := q.FieldByName('AV').AsString;
      item.State := cbsChecked;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmStockConsulta.ColoresSeleccionadosLista: TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to clbColores.Items.Count - 1 do
    if clbColores.Items[i].State = cbsChecked then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := clbColores.Items[i].Text;
    end;
end;

function TfrmStockConsulta.ColoresSeleccionadosSQL: string;
var
  cols: TArray<string>;
  i: Integer;
begin
  cols := ColoresSeleccionadosLista;
  if Length(cols) = 0 then
  begin
    Result := 'NULL';
    Exit;
  end;
  Result := '';
  for i := 0 to High(cols) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + QuotedStr(cols[i]);
  end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto + info de precios
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  q: TUniQuery;
begin
  FCodArt := ACodArt;
  FCodSku := ACodSku;
  btnArt.Text := ACodArt;

  lblDescr.Caption := '';
  if Trim(ACodArt) <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := inLibGlobalVar.oConn;
      q.SQL.Text :=
        'SELECT DESCRIPCION_ART FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :p';
      q.ParamByName('p').AsString := ACodArt;
      q.Open;
      if not q.IsEmpty then
        lblDescr.Caption := q.FieldByName('DESCRIPCION_ART').AsString;
    finally
      FreeAndNil(q);
    end;
  end;

  // Errores de carga (foto / cabecera / colores) por encima de la ventana.
  try
    CargarFoto;
    CargarInfoCabecera;
    CargarColores;
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.CargarFoto;
var
  info: TFotoInfo;
  ruta: string;
  png : TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if Trim(FCodArt) = '' then Exit;
  info := inLibFotos.oFotos.Resolver(FCodArt, FCodSku);
  ruta := inLibFotos.oFotos.RutaFoto(info, frPx300);
  if ruta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(ruta);
    imgFoto.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

// Pinta el bloque de info de la cabecera (propiedades + tarifas vigentes +
// proveedores). Las propiedades del articulo se listan todas, compactas y
// separadas por " · ". Las tarifas muestran la fila vigente hoy de cada
// tarifa (PVP, VENTA MAYOR…), ordenadas por ORDEN_TAR. Los proveedores van
// con el principal primero. Se ignoran tarifas/proveedores con SKU
// especifico — aqui solo mostramos el dato a nivel de articulo.
procedure TfrmStockConsulta.CargarInfoCabecera;
var
  q : TUniQuery;
  sb: TStringList;
  sLinea: string;
  sProps: string;
  sTipo : string;
  sValor: string;
begin
  lblInfo.Caption := '';
  if Trim(FCodArt) = '' then Exit;

  sb := TStringList.Create;
  q  := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;

    // ---- Propiedades del articulo (todas las activas) ----
    // El valor mostrado depende del tipo: LISTA -> texto del valor en
    // fza_propiedades_valores; BOOLEANO -> Si/No; resto (TEXTO/NUMERO) ->
    // VALOR_LIBRE_ARTPROP. Se listan compactas separadas por " · ".
    q.SQL.Text :=
      'SELECT P.NOMBRE_PROP_PROP, P.TIPO_VALOR_PROP, ' +
      '       AP.VALOR_LIBRE_ARTPROP, PV.PV ' +
      '  FROM fza_articulos_propiedades AP ' +
      '  JOIN fza_propiedades P ' +
      '    ON P.CODIGO_PROP_ARTPROP = AP.CODIGO_PROP_ARTPROP ' +
      '  LEFT JOIN fza_propiedades_valores PV ' +
      '    ON PV.ID_PV_ARTPROP = AP.ID_PV_ARTPROP ' +
      ' WHERE AP.CODIGO_ART_ART = :art ' +
      '   AND IFNULL(P.ESACTIVO_PROP, ''S'') = ''S'' ' +
      ' ORDER BY P.NOMBRE_PROP_PROP';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    sProps := '';
    while not q.Eof do
    begin
      sTipo := q.FieldByName('TIPO_VALOR_PROP').AsString;
      if SameText(sTipo, 'LISTA') then
        sValor := Trim(q.FieldByName('PV').AsString)
      else if SameText(sTipo, 'BOOLEANO') then
        sValor := IfThen(SameText(Trim(
                    q.FieldByName('VALOR_LIBRE_ARTPROP').AsString), 'S'),
                    'Sí', 'No')
      else
        sValor := Trim(q.FieldByName('VALOR_LIBRE_ARTPROP').AsString);
      if sValor <> '' then
      begin
        if sProps <> '' then
          sProps := sProps + '   ·   ';
        sProps := sProps +
                  q.FieldByName('NOMBRE_PROP_PROP').AsString + ': ' + sValor;
      end;
      q.Next;
    end;
    q.Close;
    if sProps <> '' then
      sb.Add(sProps);

    // ---- Tarifas vigentes del articulo (sin SKU especifico) ----
    // Por cada tarifa (PVP, VENTA MAYOR…) se coge la fila vigente hoy:
    // activa, FECHA_DESDE nula o <= hoy y FECHA_HASTA nula o >= hoy. Si hay
    // varias vigentes para la misma tarifa, gana la de FECHA_DESDE mas
    // reciente (subconsulta correlada por CODIGO_UNICO_ARTTAR).
    q.SQL.Text :=
      'SELECT AT.CODIGO_TAR_ARTTAR, T.NOMBRE_TAR_TAR, ' +
      '       AT.PRECIO_FINAL_ARTTAR ' +
      '  FROM fza_articulos_tarifas AT ' +
      '  LEFT JOIN fza_tarifas T ' +
      '    ON T.CODIGO_TAR_ARTTAR = AT.CODIGO_TAR_ARTTAR ' +
      ' WHERE AT.CODIGO_ART_ARTTAR = :art ' +
      '   AND IFNULL(AT.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
      '   AND AT.ESACTIVO_ARTTAR = ''S'' ' +
      '   AND (AT.FECHA_DESDE_ARTTAR IS NULL ' +
      '        OR AT.FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
      '   AND (AT.FECHA_HASTA_ARTTAR IS NULL ' +
      '        OR AT.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
      '   AND AT.CODIGO_UNICO_ARTTAR = ( ' +
      '         SELECT AT2.CODIGO_UNICO_ARTTAR ' +
      '           FROM fza_articulos_tarifas AT2 ' +
      '          WHERE AT2.CODIGO_ART_ARTTAR = AT.CODIGO_ART_ARTTAR ' +
      '            AND IFNULL(AT2.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
      '            AND AT2.CODIGO_TAR_ARTTAR = AT.CODIGO_TAR_ARTTAR ' +
      '            AND AT2.ESACTIVO_ARTTAR = ''S'' ' +
      '            AND (AT2.FECHA_DESDE_ARTTAR IS NULL ' +
      '                 OR AT2.FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
      '            AND (AT2.FECHA_HASTA_ARTTAR IS NULL ' +
      '                 OR AT2.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
      '          ORDER BY AT2.FECHA_DESDE_ARTTAR DESC, ' +
      '                   AT2.CODIGO_UNICO_ARTTAR DESC ' +
      '          LIMIT 1) ' +
      ' ORDER BY COALESCE(T.ORDEN_TAR, 999999), T.NOMBRE_TAR_TAR';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    if not q.IsEmpty then
      sb.Add('');
    while not q.Eof do
    begin
      sb.Add(Format('%s%s: %s',
        [IfThen(SameText(q.FieldByName('CODIGO_TAR_ARTTAR').AsString,
                oAppParams.GetString('appTarifaDefecto', 'PVP')),
                'Tarifa por defecto - ', ''),
         IfThen(Trim(q.FieldByName('NOMBRE_TAR_TAR').AsString) <> '',
                q.FieldByName('NOMBRE_TAR_TAR').AsString,
                q.FieldByName('CODIGO_TAR_ARTTAR').AsString),
         FormatFloat('#,##0.00', q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat)
         + ' '#8364]));
      q.Next;
    end;
    q.Close;

    // ---- Proveedores ----
    q.SQL.Text :=
      'SELECT AP.CODIGO_PRV_AP, P.RAZON_SOCIAL_PRV, ' +
      '       AP.REF_PROVEEDOR_AP, AP.PRECIO_ULT_COMPRA_AP, ' +
      '       AP.ESPROVEEDORPRINCIPAL_AP ' +
      '  FROM fza_articulos_proveedores AP ' +
      '  LEFT JOIN fza_proveedores P ' +
      '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
      ' WHERE AP.CODIGO_ART_AP = :art ' +
      ' ORDER BY AP.ESPROVEEDORPRINCIPAL_AP DESC, P.RAZON_SOCIAL_PRV';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    if not q.IsEmpty then
      sb.Add('');
    while not q.Eof do
    begin
      sLinea := Format('%s%s%s',
        [IfThen(q.FieldByName('ESPROVEEDORPRINCIPAL_AP').AsString = 'S',
                'Proveedor ppal. - ', 'Proveedor - '),
         IfThen(Trim(q.FieldByName('RAZON_SOCIAL_PRV').AsString) <> '',
                q.FieldByName('RAZON_SOCIAL_PRV').AsString,
                q.FieldByName('CODIGO_PRV_AP').AsString),
         IfThen(Trim(q.FieldByName('REF_PROVEEDOR_AP').AsString) <> '',
                ' (ref ' + q.FieldByName('REF_PROVEEDOR_AP').AsString + ')',
                '')]);
      // El coste (ultimo precio de compra) solo si hay permiso de verlo.
      if FVerCoste then
        sLinea := sLinea + ': ' +
          FormatFloat('#,##0.00',
                      q.FieldByName('PRECIO_ULT_COMPRA_AP').AsFloat) + ' '#8364;
      sb.Add(sLinea);
      q.Next;
    end;

    lblInfo.Caption := sb.Text;
  finally
    FreeAndNil(q);
    FreeAndNil(sb);
  end;
end;

// ---------------------------------------------------------------------------
//  Estado: base SELECT (que va dentro del SUM(CASE WHEN ...))
// ---------------------------------------------------------------------------
// Devuelve un subselect que produce filas (CODIGO_UNIDAD_SKU, COLOR,
// TALLA, ALM, CANTIDAD). El pivote SQL exterior agrupa por TALLA y mete
// CASE-WHEN por COLOR o ALM en cada columna.
// Subselect base parametrizado por estado. Cada bloque devuelve filas con
// el mismo shape (CODIGO_UNIDAD_SKU, COLOR_AV, TALLA_AV, ALM,
// CANTIDAD) + un literal ESTADO_NUM que identifica el estado origen para
// que en modo "Todo a la vez" podamos hacer UNION ALL y agrupar tambien
// por ESTADO_NUM en el pivote exterior.
// Expresión del campo CANTIDAD (lectura directa del acumulado en
// fza_articulos_stockactual). Para esPdteRecibir/esPrestadas se gestiona
// en EstadoBaseSelectFor con una rama propia.
function CampoCantidadStock(AEstado: TEstadoStock): string;
begin
  case AEstado of
    esExistencias:        Result := 'STK.CANTIDAD_STK';
    esEntradas:           Result :=
      'STK.CANTIDAD_ENT_COMPRA_STK + STK.CANTIDAD_ENT_TRASPASO_STK + ' +
      'STK.CANTIDAD_ENT_DEPOSITO_STK + STK.CANTIDAD_ENT_REGULAR_STK + ' +
      'STK.CANTIDAD_ENT_ALBENTRADA_STK';
    esSalidas:            Result :=
      'STK.CANTIDAD_SAL_TRASPASO_STK + STK.CANTIDAD_SAL_DEPOSITO_STK + ' +
      'STK.CANTIDAD_SAL_VENTA_STK + STK.CANTIDAD_SAL_ALBVENTA_STK';
    esVentas:             Result := 'STK.CANTIDAD_SAL_VENTA_STK';
    esRegularizadas:      Result := 'STK.CANTIDAD_ENT_REGULAR_STK';
    esEntradaTraspaso:    Result := 'STK.CANTIDAD_ENT_TRASPASO_STK';
    esSalidaTraspaso:     Result := 'STK.CANTIDAD_SAL_TRASPASO_STK';
    esEntradaCompra:      Result := 'STK.CANTIDAD_ENT_COMPRA_STK';
    esEntradaDeposito:    Result := 'STK.CANTIDAD_ENT_DEPOSITO_STK';
    esSalidaDeposito:     Result := 'STK.CANTIDAD_SAL_DEPOSITO_STK';
    esSalidaAlbVenta:     Result := 'STK.CANTIDAD_SAL_ALBVENTA_STK';
    esEntradaAlbEntrada:  Result := 'STK.CANTIDAD_ENT_ALBENTRADA_STK';
    esPdteServir:         Result := 'STK.CANTIDAD_PTE_SERVIR_STK';
  else
    Result := '0';
  end;
end;

function TfrmStockConsulta.EstadoBaseSelectFor(AEstado: TEstadoStock): string;
const
  // Columnas de atributos del SKU. El color y la talla salen de un JOIN a la
  // derivada agregada ATR (ver sAtrJoin), no de subconsultas correladas por
  // fila: asi se calculan de una pasada y no se multiplican por cada estado
  // del UNION ALL. MAX() porque ATR es 1:1 con el SKU (cumple
  // ONLY_FULL_GROUP_BY sin tocar el GROUP BY).
  CSelSku =
    'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
    '       MAX(ATR.COLOR_AV) AS COLOR_AV, ' +
    '       MAX(ATR.TALLA_AV) AS TALLA_AV, ';
var
  sAlms, sEstadoNum, sCampo, sAtrJoin: string;
begin
  sAlms      := AlmacenesSeleccionadosSQL;
  sEstadoNum := IntToStr(Ord(AEstado));
  // Color y talla de cada SKU del articulo, calculados una sola vez.
  // MAX(CASE...) deduplica si un SKU tuviera varios atributos del mismo tipo
  // (equivale al LIMIT 1 anterior). Antes esto eran dos subconsultas
  // correladas evaluadas por fila y repetidas en cada estado del UNION, que
  // es lo que disparaba el tiempo del pivote "Todos los estados".
  sAtrJoin :=
    '  LEFT JOIN (SELECT SKU2.CODIGO_UNIDAD_SKU, ' +
    '          MAX(CASE WHEN AV2.ID_VA_AV =  ''CO'' THEN AV2.AV END) AS COLOR_AV, ' +
    '          MAX(CASE WHEN AV2.ID_VA_AV <> ''CO'' THEN AV2.AV END) AS TALLA_AV ' +
    '     FROM fza_articulos_skus SKU2 ' +
    '     LEFT JOIN fza_atributos_sku SA2 ' +
    '       ON SA2.CODIGO_UNIDAD_SKU_SA = SKU2.CODIGO_UNIDAD_SKU ' +
    '     LEFT JOIN fza_atributos_valores AV2 ON AV2.ID_AV = SA2.ID_AV_SA ' +
    '    WHERE SKU2.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
    '    GROUP BY SKU2.CODIGO_UNIDAD_SKU) ATR ' +
    '    ON ATR.CODIGO_UNIDAD_SKU = SKU.CODIGO_UNIDAD_SKU ';
  if AEstado = esPdteRecibir then
    // Pdte. recibir: viene de tabla aparte, no del acumulado.
    Result := CSelSku +
      '       PDR.CODIGO_ALM_PDR AS ALM, ' +
      '       SUM(PDR.CANTIDAD_PDR) AS CANTIDAD, ' +
      '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_articulos_pdte_recibir PDR ' +
      '    ON PDR.CODIGO_UNIDAD_PDR = SKU.CODIGO_UNIDAD_SKU ' +
      sAtrJoin +
      ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
      '   AND PDR.CODIGO_ALM_PDR IN (' + sAlms + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, PDR.CODIGO_ALM_PDR'
  else if (AEstado = esPrestadas) or (AEstado = esTodoAlaVez) then
    // esPrestadas: stub. esTodoAlaVez: lo agrega EstadoBaseSelect.
    Result :=
      'SELECT ''''       AS CODIGO_UNIDAD_SKU, ' +
      '       NULL       AS COLOR_AV, ' +
      '       NULL       AS TALLA_AV, ' +
      '       ''''       AS ALM, ' +
      '       0          AS CANTIDAD, ' +
      '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
      '  FROM dual WHERE 0'
  else
  begin
    // Resto: lectura directa del acumulado en fza_articulos_stockactual.
    sCampo := CampoCantidadStock(AEstado);
    Result := CSelSku +
      '       STK.CODIGO_ALM_STK AS ALM, ' +
      '       SUM(' + sCampo + ') AS CANTIDAD, ' +
      '       ' + sEstadoNum + ' AS ESTADO_NUM ' +
      '  FROM fza_articulos_skus SKU ' +
      '  JOIN fza_articulos_stockactual STK ' +
      '    ON STK.CODIGO_UNIDAD_STK = SKU.CODIGO_UNIDAD_SKU ' +
      sAtrJoin +
      ' WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
      '   AND STK.CODIGO_ALM_STK IN (' + sAlms + ') ' +
      ' GROUP BY SKU.CODIGO_UNIDAD_SKU, STK.CODIGO_ALM_STK';
  end;
end;

// En modo "Todo a la vez" hace UNION ALL de los estados con datos.
// Simplificado: existencias, entradas (total), salidas (total), pte. servir
// y pte. recibir. Desglosado: existencias + pendientes + los subtipos de
// entrada/salida, sin los totales esEntradas/esSalidas (serian redundantes
// con su propio desglose). esPrestadas es stub y siempre devuelve 0.
function TfrmStockConsulta.EstadoBaseSelect: string;
const
  // Modo simplificado: solo totales y pendientes
  ESTADOS_TODO_SIMPLE: array[0..4] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas,
    esPdteServir, esPdteRecibir);
  // Modo desglosado: subtipos en vez de los totales esEntradas/esSalidas
  ESTADOS_TODO_FULL: array[0..12] of TEstadoStock = (
    esExistencias,
    esPdteServir, esPdteRecibir,
    esEntradaCompra,
    esEntradaTraspaso, esSalidaTraspaso,
    esEntradaDeposito, esSalidaDeposito,
    esVentas, esRegularizadas,
    esSalidaAlbVenta, esEntradaAlbEntrada,
    esPrestadas);
var
  i: Integer;
  est: TEstadoStock;
begin
  if EstadoActual <> esTodoAlaVez then
  begin
    Result := EstadoBaseSelectFor(EstadoActual);
    Exit;
  end;
  Result := '';
  if FModoDesglosado then
  begin
    for i := Low(ESTADOS_TODO_FULL) to High(ESTADOS_TODO_FULL) do
    begin
      est := ESTADOS_TODO_FULL[i];
      if Result <> '' then Result := Result + ' UNION ALL ';
      Result := Result + '(' + EstadoBaseSelectFor(est) + ')';
    end;
  end
  else
  begin
    for i := Low(ESTADOS_TODO_SIMPLE) to High(ESTADOS_TODO_SIMPLE) do
    begin
      est := ESTADOS_TODO_SIMPLE[i];
      if Result <> '' then Result := Result + ' UNION ALL ';
      Result := Result + '(' + EstadoBaseSelectFor(est) + ')';
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Build SQL pivote: rows=almacenes o colores, cols=tallas
// ---------------------------------------------------------------------------
// Las TALLAS van SIEMPRE como columnas dinamicas (T0..Tn-1). Las filas son
// almacenes marcados en clbAlmacenes (modo Por Almacen) o colores marcados
// en clbColores (modo Por Color). El filtro de la dimension "no activa" se
// aplica como filtro adicional sobre B:
//   * Por Color  -> almacenes se filtran ya en EstadoBaseSelect.
//   * Por Almacen-> los colores marcados se filtran en el JOIN ON B.COLOR_AV.
// HEX viaja en la columna de filas para que el custom-draw del cuadradito
// pinte el swatch en modo Por Color; en Por Almacen queda vacio.
function TfrmStockConsulta.ConstruirSQLPivot(
  const ATallas: TArray<TInfoColumna>; AEsColor: Boolean): string;
var
  sBase, sCols, sOuter, sJoin, sGroup, sOrder, sWhere: string;
  sFiltroColores: string;
  sExtraSel, sExtraGroup, sExtraOrder: string;
  bEsTodo: Boolean;
  i: Integer;
  alms: TArray<string>;
begin
  sBase   := EstadoBaseSelect;
  bEsTodo := EstadoActual = esTodoAlaVez;
  sCols   := '';
  for i := 0 to High(ATallas) do
    sCols := sCols + Format(', SUM(CASE WHEN B.TALLA_AV = %s THEN B.CANTIDAD ELSE 0 END) AS T%d',
                            [QuotedStr(ATallas[i].Codigo), i]);
  sFiltroColores := ColoresSeleccionadosSQL;

  // En modo "Todo a la vez" el pivote agrupa ademas por ESTADO_NUM:
  // cada fila de grupo (almacen o color) se desdobla en una fila por
  // estado con datos. Los grupos sin ningun dato (LEFT JOIN sin match)
  // se descartan filtrando B.ESTADO_NUM IS NOT NULL — sino saldria una
  // fila con ESTADO_NUM=NULL por cada grupo vacio.
  if bEsTodo then
  begin
    sExtraSel   := ', B.ESTADO_NUM AS ESTADO_NUM';
    sExtraGroup := ', B.ESTADO_NUM';
    sExtraOrder := ', B.ESTADO_NUM';
  end
  else
  begin
    sExtraSel   := '';
    sExtraGroup := '';
    sExtraOrder := '';
  end;

  if AEsColor then
  begin
    // Filas = colores marcados en clbColores. Dedupe por AV.AV (varios
    // ID_AV pueden compartir el mismo nombre de color).
    sOuter :=
      '(SELECT AV.AV, MIN(AV.ORDEN_AV) AS ORDEN_AV, ' +
      '        MIN(AV.ID_ATB_AV) AS ID_ATB_AV ' +
      '   FROM fza_articulos_skus SKU ' +
      '   JOIN fza_atributos_sku SA ' +
      '     ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
      '   JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
      '  WHERE SKU.CODIGO_ART_SKU = ' + QuotedStr(FCodArt) +
      '    AND AV.ID_VA_AV = ''CO''' +
      '    AND AV.AV IN (' + sFiltroColores + ') ' +
      '  GROUP BY AV.AV) C';
    sJoin :=
      ' LEFT JOIN fza_atributos_basicos ATB ON ATB.ID_ATB = C.ID_ATB_AV ' +
      ' LEFT JOIN (' + sBase + ') B ON B.COLOR_AV = C.AV';
    if bEsTodo then
      sWhere := ' WHERE B.ESTADO_NUM IS NOT NULL '
    else
      sWhere := '';
    sGroup := ' GROUP BY C.AV, ATB.HEX_ATB, C.ORDEN_AV' + sExtraGroup;
    sOrder := ' ORDER BY C.ORDEN_AV, C.AV' + sExtraOrder;
    Result :=
      'SELECT C.AV AS GRUPO, COALESCE(ATB.HEX_ATB, '''') AS HEX, ' +
      '       C.ORDEN_AV AS ORDEN' + sExtraSel + sCols +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM ' + sOuter + sJoin + sWhere + sGroup + sOrder;
  end
  else
  begin
    // Filas = almacenes marcados. Filtro de colores se aplica al
    // subselect B via JOIN ON.
    alms := AlmacenesSeleccionadosLista;
    if Length(alms) = 0 then
    begin
      Result := 'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN' +
                IfThen(bEsTodo, ', 0 AS ESTADO_NUM', '') +
                sCols + ', 0 AS TOTAL FROM dual WHERE 0';
      Exit;
    end;
    Result :=
      'SELECT ALM.CODIGO_ALM_ALM AS GRUPO, '''' AS HEX, ' +
      '       ALM.ORDEN_ALM AS ORDEN' + sExtraSel + sCols +
      ', SUM(B.CANTIDAD) AS TOTAL ' +
      '  FROM fza_almacenes ALM ' +
      '  LEFT JOIN (' + sBase + ') B ' +
      '    ON B.ALM = ALM.CODIGO_ALM_ALM ' +
      '   AND B.COLOR_AV IN (' + sFiltroColores + ') ' +
      ' WHERE ALM.CODIGO_ALM_ALM IN (' + AlmacenesSeleccionadosSQL + ') ' +
      IfThen(bEsTodo, '   AND B.ESTADO_NUM IS NOT NULL ', '') +
      ' GROUP BY ALM.CODIGO_ALM_ALM, ALM.ORDEN_ALM' + sExtraGroup + ' ' +
      ' ORDER BY ALM.ORDEN_ALM, ALM.CODIGO_ALM_ALM' + sExtraOrder;
  end;
end;

// ---------------------------------------------------------------------------
//  Reconstruir columnas dinamicas del grid
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
//  Tallas del articulo (columnas dinamicas del grid)
// ---------------------------------------------------------------------------
function TfrmStockConsulta.TallasArticulo: TArray<TInfoColumna>;
var
  q: TUniQuery;
  inf: TInfoColumna;
  iAcPivot: Integer;
begin
  SetLength(Result, 0);
  if Trim(FCodArt) = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;

    // 1. Conjunto pivot (tallas) asignado al articulo. Si la asignacion
    //    tiene varios candidatos no-color, cogemos el primero por
    //    ID_VA_ACA. Si el articulo no tiene asignacion, fallback en (2).
    q.SQL.Text :=
      'SELECT ID_AC_ACA FROM fza_articulos_conjuntos_asign ' +
      ' WHERE CODIGO_ART_ACA = :art ' +
      '   AND ID_VA_ACA <> ''CO'' ' +
      ' ORDER BY ID_VA_ACA LIMIT 1';
    q.ParamByName('art').AsString := FCodArt;
    q.Open;
    iAcPivot := 0;
    if not q.IsEmpty then iAcPivot := q.FieldByName('ID_AC_ACA').AsInteger;
    q.Close;

    if iAcPivot > 0 then
    begin
      // 1b. Todas las tallas del conjunto, en orden. Salen TODAS aunque
      //     algunas no tengan SKUs/stock — el pivote las muestra a 0.
      q.SQL.Text :=
        'SELECT AV.AV, AV.ORDEN_AV ' +
        '  FROM fza_atributos_conjuntos_det ACD ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
        ' WHERE ACD.ID_AC_ACD = :ac ' +
        ' ORDER BY ACD.ORDEN_ACD, AV.AV';
      q.ParamByName('ac').AsInteger := iAcPivot;
    end
    else
    begin
      // 2. Fallback: tallas presentes en SKUs del articulo (puede ser
      //    incompleto pero al menos muestra lo que hay).
      q.SQL.Text :=
        'SELECT DISTINCT AV.AV, AV.ORDEN_AV ' +
        '  FROM fza_articulos_skus SKU ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        ' WHERE SKU.CODIGO_ART_SKU = :art ' +
        '   AND AV.ID_VA_AV <> ''CO'' ' +
        ' ORDER BY AV.ORDEN_AV, AV.AV';
      q.ParamByName('art').AsString := FCodArt;
    end;
    q.Open;
    while not q.Eof do
    begin
      inf := Default(TInfoColumna);
      inf.Codigo  := q.FieldByName('AV').AsString;
      inf.Texto   := q.FieldByName('AV').AsString;
      inf.Hex     := '';
      inf.EsColor := False;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := inf;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function HexAColor(const AHex: string; out AColor: TColor): Boolean;
var
  s: string;
begin
  Result := False;
  AColor := clBlack;
  s := AHex;
  if (Length(s) > 0) and (s[1] = '#') then Delete(s, 1, 1);
  if Length(s) <> 6 then Exit;
  AColor := RGB(StrToIntDef('$' + Copy(s, 1, 2), 0),
                StrToIntDef('$' + Copy(s, 3, 2), 0),
                StrToIntDef('$' + Copy(s, 5, 2), 0));
  Result := True;
end;

procedure TfrmStockConsulta.ReconstruirColumnas(
  const ATallas: TArray<TInfoColumna>; AEsColor: Boolean);
var
  i: Integer;
  col, colTotal: TcxGridDBColumn;
begin
  // Borrar columnas dinamicas anteriores (no hay columnas fijas: todo
  // se crea en este metodo y se libera al volver a llamar).
  for i := FColsDin.Count - 1 downto 0 do
    FColsDin[i].Free;
  FColsDin.Clear;
  FColGrupo    := nil;
  FColEstado   := nil;
  FEsModoColor := AEsColor;
  FEsModoTodo  := EstadoActual = esTodoAlaVez;

  // Columna principal de fila: nombre del color o codigo del almacen.
  // En modo Por Color, tvStockCustomDrawCell pinta el cuadradito del
  // color basico a la izquierda del texto, via inLibAtributosPaleta.
  // En modo Por Almacen, se muestra el codigo del almacen plano.
  FColGrupo := tvStock.CreateColumn;
  if AEsColor then FColGrupo.Caption := 'Color'
  else             FColGrupo.Caption := 'Almacén';
  FColGrupo.DataBinding.FieldName := 'GRUPO';
  if AEsColor then
    FColGrupo.Width := 150  // espacio extra para el cuadradito
  else
    FColGrupo.Width := 130;
  FColGrupo.HeaderAlignmentHorz := taLeftJustify;
  FColGrupo.Options.Sorting := False;
  FColsDin.Add(FColGrupo);

  // Columna "Estado" — solo en modo Todo a la vez. Bindeada al campo
  // numerico ESTADO_NUM pero el texto visible lo pinta el OnGetDisplayText
  // a traves de NombreEstadoCorto (asi evitamos meter strings en el SQL).
  if FEsModoTodo then
  begin
    FColEstado := tvStock.CreateColumn;
    FColEstado.Caption := 'Estado';
    FColEstado.DataBinding.FieldName := 'ESTADO_NUM';
    FColEstado.OnGetDisplayText := ColEstadoGetDisplayText;
    FColEstado.Width := 110;
    FColEstado.HeaderAlignmentHorz := taLeftJustify;
    FColEstado.Options.Sorting := False;
    FColEstado.Styles.OnGetContentStyle := ColTodoGetContentStyle;
    FColsDin.Add(FColEstado);
  end;

  // Tallas: columnas dinamicas T0..Tn-1.
  for i := 0 to High(ATallas) do
  begin
    col := tvStock.CreateColumn;
    col.Caption := ATallas[i].Texto;
    col.DataBinding.FieldName := Format('T%d', [i]);
    col.PropertiesClassName := 'TcxCurrencyEditProperties';
    TcxCurrencyEditProperties(col.Properties).DisplayFormat := '#,##0.##;-#,##0.##;0';
    TcxCurrencyEditProperties(col.Properties).UseDisplayFormatWhenEditing := True;
    col.HeaderAlignmentHorz := taCenter;
    col.Width := 60;
    col.Options.Editing := False;
    col.Options.Sorting := False;
    if FEsModoTodo then
      col.Styles.OnGetContentStyle := ColTodoGetContentStyle
    else
      col.Styles.Content := FStyEstado[EstadoActual];
    FColsDin.Add(col);
  end;

  // Total al final.
  colTotal := tvStock.CreateColumn;
  colTotal.Caption := 'Total';
  colTotal.DataBinding.FieldName := 'TOTAL';
  colTotal.PropertiesClassName := 'TcxCurrencyEditProperties';
  TcxCurrencyEditProperties(colTotal.Properties).DisplayFormat := '#,##0.##;-#,##0.##;0';
  TcxCurrencyEditProperties(colTotal.Properties).UseDisplayFormatWhenEditing := True;
  colTotal.HeaderAlignmentHorz := taCenter;
  colTotal.Width := 70;
  colTotal.Options.Editing := False;
  colTotal.Options.Sorting := False;
  if FEsModoTodo then
    colTotal.Styles.OnGetContentStyle := ColTodoGetContentStyle
  else
    colTotal.Styles.Content := FStyEstado[EstadoActual];
  FColsDin.Add(colTotal);

  FColumnas := Copy(ATallas);
end;

// Handler del Styles.OnGetContentStyle de cada columna de datos en modo
// "Todo a la vez": devuelve el estilo correspondiente al ESTADO_NUM de
// la fila, asi cada fila se pinta con el color de su estado. Si el
// ESTADO_NUM esta fuera de rango (no deberia pasar) deja el estilo a
// nil para que cxGrid use el por defecto.
procedure TfrmStockConsulta.ColTodoGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  iEstNum: Integer;
begin
  if (FColEstado = nil) or (ARecord = nil) then Exit;
  iEstNum := StrToIntDef(
               VarToStr(ARecord.Values[FColEstado.Index]), -1);
  if (iEstNum >= Ord(Low(TEstadoStock))) and
     (iEstNum <= Ord(High(TEstadoStock))) then
    AStyle := FStyEstado[TEstadoStock(iEstNum)];
end;

// ---------------------------------------------------------------------------
//  Custom-draw de la columna Color en modo Por Color: delega en la libreria
//  inLibAtributosPaleta.PintarCeldaSwatchSiAplica, que ya hace el lookup
//  contra fza_atributos_basicos (incluido el matching por texto cuando el
//  AV no tiene ID_ATB_AV) y pinta el cuadradito a la izquierda + el texto
//  desplazado a la derecha. Misma libreria que usa caja/inventarios.
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.tvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  ADone := False;
  // Solo nos interesa pintar el cuadradito de color delante del texto
  // en la columna de fila Color (modo Por Color). El coloreado del
  // texto del resto de celdas se hace via cxStyles (Styles.Content en
  // modo normal y Styles.OnGetContentStyle en modo Todo a la vez), no
  // por OnCustomDrawCell — modificar AViewInfo.Params.TextColor aqui
  // no surte efecto en el render por defecto.
  if not FEsModoColor then Exit;
  if FColGrupo = nil then Exit;
  if not (AViewInfo.Item is TcxGridDBColumn) then Exit;
  if AViewInfo.Item <> FColGrupo then Exit;

  if PintarCeldaSwatchSiAplica(ACanvas, AViewInfo, nil) then
    ADone := True;
end;

// Convierte el ESTADO_NUM crudo (int) en su nombre corto. Se asigna a
// FColEstado.OnGetDisplayText en ReconstruirColumnas para que la celda
// muestre "Existencias" en vez de "0", "Ventas" en vez de "3", etc.
procedure TfrmStockConsulta.ColEstadoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
var
  i: Integer;
begin
  i := StrToIntDef(AText, -1);
  if (i >= Ord(Low(TEstadoStock))) and (i <= Ord(High(TEstadoStock))) then
    AText := NombreEstadoCorto(TEstadoStock(i));
end;

// ---------------------------------------------------------------------------
//  Cuadradito de color en la cabecera: pintamos las celdas de datos de
//  la columna con el HEX como background (sustituye al custom-draw del
//  header, que dependia de un API de DevExpress no portable). El
//  usuario reconoce el color por la franja de fondo de su columna.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
//  RecargarConsulta
// ---------------------------------------------------------------------------
function TfrmStockConsulta.EstadoActual: TEstadoStock;
begin
  // Mapeo basado en la lista paralela poblada por PoblarComboEstados,
  // que cambia según el modo Simplificado/Desglosado.
  if (FEstadosCombo <> nil) and
     (cbbEstado.ItemIndex >= 0) and
     (cbbEstado.ItemIndex < FEstadosCombo.Count) then
    Result := FEstadosCombo[cbbEstado.ItemIndex]
  else
    Result := esExistencias;
end;

procedure TfrmStockConsulta.RecargarConsulta;
var
  tallas  : TArray<TInfoColumna>;
  bEsColor: Boolean;
begin
  if FQry.Active then FQry.Close;
  bEsColor := pcVistas.ActivePage = tsPorColor;
  // Cursor de espera: el pivote en modo "Todos los estados" puede tardar y
  // bloquea el hilo de UI; al menos el usuario ve que esta trabajando y no
  // parece que la ventana se haya colgado.
  Screen.Cursor := crHourGlass;
  try
    try
      if Trim(FCodArt) = '' then
      begin
        ReconstruirColumnas([], bEsColor);
        FQry.SQL.Text := 'SELECT '''' AS GRUPO, '''' AS HEX, 0 AS ORDEN, ' +
                         '0 AS TOTAL FROM dual WHERE 0';
      end
      else
      begin
        tallas := TallasArticulo;
        ReconstruirColumnas(tallas, bEsColor);
        FQry.SQL.Text := ConstruirSQLPivot(tallas, bEsColor);
      end;
      FQry.Open;
    except
      on E: Exception do
      begin
        if FQry.Active then
          FQry.Close;
        // El error sale por encima de la ventana (fsStayOnTop).
        MostrarError(E.Message);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// ---------------------------------------------------------------------------
//  Busqueda de articulos (popup del boton "...")
// ---------------------------------------------------------------------------
// Lanza TfrmMtoSearch (via TBusquedaUtils.EjecutarBusqueda) listando los
// articulos activos con columnas Codigo / Descripcion / Familia / Temporada
// / Proveedor ppal. / PVP. El PVP se calcula con una correlated subquery
// para garantizar UNA fila por articulo (en vez de unirse a
// fza_articulos_tarifas que da N filas si el articulo tiene varias
// tarifas). Mismo patron que TfrmMtoOpeCaja.BuscarArticulo pero sin filtro
// por tarifa/fecha (la consulta de stock es generica). Layout persistido
// bajo el Name 'frmMtoArtStockSearch' (independiente del de caja).
function TfrmStockConsulta.BuscarArticulo: string;

  procedure ConfigCampo(F: TField; const ALabel, AFormat: string);
  begin
    if F = nil then Exit;
    if ALabel <> '' then F.DisplayLabel := ALabel;
    if AFormat = '' then Exit;
    if F is TFloatField then
      TFloatField(F).DisplayFormat := AFormat
    else if F is TBCDField then
      TBCDField(F).DisplayFormat := AFormat
    else if F is TFMTBCDField then
      TFMTBCDField(F).DisplayFormat := AFormat;
  end;

var
  q: TUniQuery;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT'                                                       + sLineBreak +
      '    a.CODIGO_ART_ART,'                                        + sLineBreak +
      '    a.DESCRIPCION_ART,'                                       + sLineBreak +
      '    f.DESCRIPCION_FAM,'                                       + sLineBreak +
      '    pv.PV                      AS TEMPORADA,'                 + sLineBreak +
      '    p.RAZON_SOCIAL_PRV         AS PROVEEDOR,'                 + sLineBreak +
      '    (SELECT t.PRECIO_FINAL_ARTTAR'                            + sLineBreak +
      '       FROM fza_articulos_tarifas t'                          + sLineBreak +
      '       JOIN fza_tarifas tt'                                   + sLineBreak +
      '         ON tt.CODIGO_TAR_ARTTAR = t.CODIGO_TAR_ARTTAR'       + sLineBreak +
      '      WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART'           + sLineBreak +
      '        AND IFNULL(t.CODIGO_UNIDAD_ARTTAR, '''') = '''''      + sLineBreak +
      '        AND t.ESACTIVO_ARTTAR = ''S'''                        + sLineBreak +
      '        AND tt.CODIGO_TAR_ARTTAR = ' +
      QuotedStr(oAppParams.GetString('appTarifaDefecto', 'PVP'))  + sLineBreak +
      '      LIMIT 1)                 AS PRECIO_PVP'                 + sLineBreak +
      'FROM fza_articulos a'                                         + sLineBreak +
      'LEFT JOIN fza_articulos_familias f'                           + sLineBreak +
      '       ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART'                + sLineBreak +
      'LEFT JOIN fza_articulos_propiedades ap'                       + sLineBreak +
      '       ON ap.CODIGO_ART_ART = a.CODIGO_ART_ART'               + sLineBreak +
      '      AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'''             + sLineBreak +
      'LEFT JOIN fza_propiedades_valores pv'                         + sLineBreak +
      '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'                + sLineBreak +
      'LEFT JOIN fza_articulos_proveedores aprv'                     + sLineBreak +
      '       ON aprv.CODIGO_ART_AP = a.CODIGO_ART_ART'              + sLineBreak +
      '      AND aprv.ESPROVEEDORPRINCIPAL_AP = ''S'''               + sLineBreak +
      'LEFT JOIN fza_proveedores p'                                  + sLineBreak +
      '       ON p.CODIGO_PRV_PRV = aprv.CODIGO_PRV_AP'              + sLineBreak +
      'WHERE a.ESACTIVO_ART = ''S'''                                 + sLineBreak +
      'ORDER BY a.CODIGO_ART_ART';

    q.Open;
    ConfigCampo(q.FindField('CODIGO_ART_ART'),  'Código',      '');
    ConfigCampo(q.FindField('DESCRIPCION_ART'), 'Descripción', '');
    ConfigCampo(q.FindField('DESCRIPCION_FAM'), 'Familia',     '');
    ConfigCampo(q.FindField('TEMPORADA'),       'Temporada',   '');
    ConfigCampo(q.FindField('PROVEEDOR'),       'Proveedor',   '');
    ConfigCampo(q.FindField('PRECIO_PVP'),      'PVP',         '#,##0.00 €');

    if TBusquedaUtils.EjecutarBusqueda('Búsqueda de Artículos',
                                       q,
                                       'frmMtoArtStockSearch') then
      Result := q.FieldByName('CODIGO_ART_ART').AsString;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
//  Events
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.btnArtPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var
  sCodigo: string;
begin
  sCodigo := BuscarArticulo;
  if sCodigo <> '' then
    SetArticuloSku(sCodigo, '');
end;

procedure TfrmStockConsulta.btnArtPropertiesEditValueChanged(Sender: TObject);
begin
  SetArticuloSku(Trim(btnArt.Text), '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(Sender: TObject);
begin
  cbbEstado.Style.TextColor := ColorEstado(EstadoActual);
  RecargarConsulta;
end;

procedure TfrmStockConsulta.clbAlmacenesClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.clbColoresClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcVistasChange(Sender: TObject);
begin
  RecargarConsulta;
end;

initialization
  frmStockConsulta := nil;

end.
