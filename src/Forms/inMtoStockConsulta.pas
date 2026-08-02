{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, fsStayOnTop)                            }
{ Version:       0.7.0                                                         }
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
{            "1 Colores"   -> lstColores (seleccion multiple de colores)       }
{            "2 Almacenes" -> lstAlmacenes (seleccion multiple de almacenes)   }
{        * pnlDer (alClient): pcVistas (alTop, 30px) con dos pestanas          }
{            "3 Por almacenes" -> grid con almacenes como filas                }
{            "4 Por colores"   -> grid con colores como filas                  }
{          y el TcxGrid (alClient) compartido. La pestana activa de pcVistas   }
{          determina el modo de pivote y se aplica como filtro cruzado el      }
{          seleccion opuesta.                                                  }
{                                                                              }
{    v0.6: "letrero" de propiedades por color — al PINCHAR un color, si ese    }
{    color tiene propiedades fijadas a nivel COLOR o SKU distintas a las del   }
{    articulo (temporada, material…), se cantan en un panel rojo bajo la       }
{    cabecera. Ver propiedades_por_unidad.md.                                  }
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
{    v0.7: botón "Op de Caja" para consultar en un modal las operaciones DE,   }
{    DV y VE del SKU seleccionado en una celda de talla.                       }
{******************************************************************************}
unit inMtoStockConsulta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus, Vcl.Imaging.pngimage,
  Data.DB,
  cxClasses, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxButtonEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCheckBox, cxListBox, cxCustomData, cxStyles,
  cxCurrencyEdit,
  cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxGraphics, cxLocalization,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxScrollbarAnnotations,
  dxDateRanges, cxMemo, cxControls, dxCoreGraphics, cxCustomListBox,
  cxRadioGroup, inLibLectorScanner, inLibDocumentosTrabajo,
  UniDataDocumentosTrabajoRepositorio, inLibFotos,
  inMtoFrmBase, inLibPermisosIntf,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaEntradaIntf;

const
  // Detector por velocidad de tecleo (codigo de barras + CR, sin STX/ETX).
  SCAN_VEL_MS   = 40;   // max. ms entre teclas para considerarlo lector
  SCAN_MIN_LONG = 4;    // longitud minima del codigo

type
  TContextoDependenciasStockConsulta = record
    Lector: TLectorScanner;
    Aplicacion: IAplicacionEntradaStock;
  end;

  TfrmStockConsulta = class(TfrmBase)
    pnlCabecera   : TPanel;
      btnOperacionesCaja: TcxButton;
      lblArt        : TcxLabel;
      btnArt        : TcxButtonEdit;
      lblDescr      : TcxLabel;
      lblInfo       : TcxLabel;
      lblLetreroTemp: TcxLabel;
      imgFoto       : TImage;
    pnlFiltros    : TPanel;
      lblEstado     : TcxLabel;
      cbbEstado     : TcxComboBox;
    pnlBody       : TPanel;
    pnlIzq        : TPanel;
    pcFiltros     : TcxPageControl;
    tsColores     : TcxTabSheet;
    lblColores    : TcxLabel;
    lstColores    : TcxListBox;
    tsAlmacenes   : TcxTabSheet;
    lblAlmacenes  : TcxLabel;
    lstAlmacenes  : TcxListBox;
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
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnArtPropertiesButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure btnOperacionesCajaClick(Sender: TObject);
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure lstAlmacenesClick(Sender: TObject);
    procedure lstColoresClick(Sender: TObject);
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
    FServiciosPersistencia: TServiciosStockConsulta;
    FResultadoPivote: IResultadoConsultaStock;
    FDs: TDataSource;
    FCodArt     : string;
    FCodSku     : string;
    // Propiedades fijadas a nivel COLOR o SKU (no solo temporada) que difieren
    // del nivel articulo, ya formateadas por color. Clave = nombre del color
    // (AV.AV), valor = texto "Prop: valor (color/SKU) · ...".
    FPropsPorColor : TDictionary<string, string>;
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
    FPopMenuStock   : TPopupMenu;
    FMenuAgregarDoc : TMenuItem;
    // Lectura con pistola a nivel de formulario (KeyPreview=True): trama
    // STX/ETX y deteccion por velocidad de tecleo. Resuelve el codigo SOLO
    // contra codigos de barras y carga el articulo via SetArticuloSku, este
    // donde este el foco.
    FDependencias: TContextoDependenciasStockConsulta;
    FTsFotos        : array[TDimensionFotos] of TcxTabSheet;
    FScrFotos       : TScrollBox;
    FBtnFiltroFoto1 : TcxButton;
    FBtnFiltroFoto2 : TcxButton;
    FFotosCargadas  : array[TDimensionFotos] of Boolean;
    FFotosArt       : array[TDimensionFotos] of string;
    FFotosFiltros   : array[TDimensionFotos] of TDimensionesFotos;
    FFotosFiltrosCache: array[TDimensionFotos] of TDimensionesFotos;
    FBtnHistAnterior: TcxButton;
    FBtnHistSiguiente: TcxButton;
    FHistorialArticulos: TStringList;
    FHistorialPos   : Integer;
    FMoviendoHistorial: Boolean;
    FSilenciarCambioVista: Boolean;
    FCbbCoincidencias: TcxComboBox;
    FCodigosCoincidencia: TStringList;
    FSkusCoincidencia: TStringList;
    FActualizandoArticulo: Boolean;
    FResolviendoEntrada: Boolean;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure AplicarLecturaCodigoBarras(const ACodigo: string);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    procedure PopMenuStockPopup(Sender: TObject);
    procedure MenuAgregarDocClick(Sender: TObject);
    procedure   PoblarComboEstados;
    procedure   GuardarModoUsuario;
    procedure   CargarModoUsuario;
    procedure   rbModoClick(Sender: TObject);
    procedure CargarAlmacenes;
    procedure CargarColores;
    procedure CargarPropsPorColor;
    procedure ActualizarLetreroColor;
    procedure AjustarFotoCabecera;
    procedure CargarFoto(const ACodUnidad: string);
    procedure CrearBotonesHistorial;
    procedure HistorialAnteriorClick(Sender: TObject);
    procedure HistorialSiguienteClick(Sender: TObject);
    procedure RegistrarArticuloHistorial(const ACodArt: string);
    procedure ActualizarBotonesHistorial;
    procedure CrearPestanasFotos;
    procedure InvalidarFotosRelacionadas;
    procedure MostrarVistaFotosRelacionadas(AVisible: Boolean);
    procedure LimpiarFotosRelacionadas;
    procedure MostrarMensajeFotosRelacionadas(const AMsg: string);
    procedure ConfigurarFiltrosFotos(ADimension: TDimensionFotos);
    procedure BotonFiltroFotosClick(Sender: TObject);
    procedure CargarFotosRelacionadasSiProcede;
    procedure CargarFotosRelacionadas(ADimension: TDimensionFotos);
    procedure PintarTarjetaRelacionada(AIndice: Integer;
              AColumnas: Integer; ADataSet: TDataSet;
              AFotos: TDictionary<string, TFotoInfo>);
    procedure TarjetaFotoDblClick(Sender: TObject);
    procedure NavegarArticuloRelacionado(const ACodArt: string);
    function  DimensionFotosActiva(out ADimension: TDimensionFotos): Boolean;
    function  NombreDimensionFotos(ADimension: TDimensionFotos): string;
    procedure CargarInfoCabecera;
    procedure CrearLeyenda;
    procedure SeleccionarEstadoLeyenda(AEstado: TEstadoStock);
    procedure LeyendaEstadoClick(Sender: TObject);
    procedure CrearEstilosEstado;
    function  EstadoActual: TEstadoStock;
    function  AlmacenesSeleccionadosLista: TArray<string>;
    function  ColoresSeleccionadosLista: TArray<string>;
    function  BuscarArticulo: string;
    function  TallasArticulo: TArray<TInfoColumna>;
    function  ResolverCodigoSkuDocumentoTrabajo(const AColor, ATalla: string;
              out ACodigoSku, AMensaje: string): Boolean;
    function  ResolverSkuCeldaOperacionesCaja(
              out ACodigoSku, AMensaje: string): Boolean;
    function  ResolverCeldaDocumentoTrabajo(out ALinea:
              TDocTrabajoLineaOrigen; out AMensaje: string): Boolean;
    procedure ReconstruirColumnas(const ATallas: TArray<TInfoColumna>;
                                   AEsColor: Boolean);
    procedure RecargarConsulta;
    procedure MostrarError(const AMsg: string);
    procedure btnArtKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure btnArtExit(Sender: TObject);
    procedure CrearComboCoincidencias;
    procedure MostrarComboCoincidencias(
              const ACoincidencias: TCoincidenciasEntradaStock;
              const AEntrada: string);
    procedure OcultarComboCoincidencias;
    procedure cbbCoincidenciasEditValueChanged(Sender: TObject);
    procedure cbbCoincidenciasExit(Sender: TObject);
    procedure cbbCoincidenciasKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure ResolverTextoArticulo(AMostrarError: Boolean);
  public
    procedure SetArticuloSku(const ACodArt, ACodSku: string);
  end;

/// Abre (o trae al frente) la consulta de stock con el (articulo, sku)
/// indicado. Mismo patron que inMtoFotoArticulo.MostrarFotoFlotante.
procedure MostrarStockConsulta(const ACodArt, ACodSku: string);
procedure DesvincularPerfilesStockConsulta;

implementation

uses
  System.StrUtils,
  inLibAtributosPaleta,
  inLibGenBusq, inLibUser,
  inLibArticulosValidadorIntf,
  inLibPerfilesUsuarioIntf,
  inLibStockCeldaDocumento,
  inLibStockConsultaInfo,
  inLibStockConsultaEntrada,
  inMtoStockConsultaEntradaVcl,
  UniDataStockConsultaInfo,
  inMtoModalOperacionesCajaSku, inLibMsgArticulos, inLibMsgCaja,
  inLibMsgComun, inLibMsgVentas,
  inLibDocumentosTrabajoPresentacion;

{$R *.dfm}

procedure InicializarEntradaStockVcl(
  AFormulario: TfrmStockConsulta;
  const AValidador: IArticulosValidador);
var
  Callbacks: TCallbacksEntradaStock;
  Adaptador: TAdaptadorEntradaStockVcl;
  Repositorio: IRepositorioEntradaStock;
  Vista: IVistaEntradaStock;
begin
  Callbacks := Default(TCallbacksEntradaStock);
  Callbacks.ResolverTexto :=
    function(const AEntrada: string): TCoincidenciasEntradaStock
    var
      iCoincidencia: Integer;
      ResultadoConsulta: IResultadoConsultaStock;
      Datos: TDataSet;
    begin
      SetLength(Result, 0);
      ResultadoConsulta := AFormulario.FServiciosPersistencia.Catalogos.
        ResolverTextoArticulo(AEntrada);
      Datos := ResultadoConsulta.DataSet;
      if Assigned(Datos) then
      begin
        SetLength(Result, Datos.RecordCount);
        Datos.First;
        iCoincidencia := 0;
        while not Datos.Eof do
        begin
          Result[iCoincidencia].CodigoArticulo :=
            Datos.FieldByName('CODIGO_PADRE').AsString;
          Result[iCoincidencia].CodigoSku :=
            Datos.FieldByName('CODIGO_SKU').AsString;
          Result[iCoincidencia].Descripcion :=
            Datos.FieldByName('DESCRIPCION_ART').AsString;
          Result[iCoincidencia].Proveedor :=
            Datos.FieldByName('PROVEEDOR').AsString;
          Result[iCoincidencia].ReferenciaProveedor :=
            Datos.FieldByName('REF_PROVEEDOR').AsString;
          Inc(iCoincidencia);
          Datos.Next;
        end;
        SetLength(Result, iCoincidencia);
      end;
    end;
  Callbacks.AplicarArticulo :=
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      AFormulario.SetArticuloSku(ACodigoArticulo, ACodigoSku);
    end;
  Callbacks.MostrarCoincidencias :=
    procedure(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string)
    begin
      AFormulario.MostrarComboCoincidencias(ACoincidencias, AEntrada);
    end;
  Callbacks.MostrarTextoNoEncontrado :=
    procedure(const AEntrada: string)
    begin
      AFormulario.MostrarError(Format(
        SErrorEntradaStockNoEncontrada,
        [AEntrada]));
    end;
  Callbacks.MostrarCodigoBarrasNoEncontrado :=
    procedure(const ACodigo: string)
    begin
      AFormulario.MostrarError(Format(
        SErrorCodigoBarrasStockNoEncontrado,
        [ACodigo]));
    end;
  Adaptador := TAdaptadorEntradaStockVcl.Create(Callbacks);
  Repositorio := Adaptador;
  Vista := Adaptador;
  AFormulario.FDependencias.Aplicacion := CrearAplicacionEntradaStock(
    Repositorio,
    AValidador,
    Vista);
end;

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
function BuscarStockConsulta: TfrmStockConsulta;
var
  Componente: TComponent;
begin
  Componente := Application.FindComponent('frmStockConsulta');
  if (Componente is TfrmStockConsulta) and
     not (csDestroying in Componente.ComponentState) then
    Result := TfrmStockConsulta(Componente)
  else
    Result := nil;
end;

procedure MostrarStockConsulta(const ACodArt, ACodSku: string);
var
  Formulario: TfrmStockConsulta;
begin
  Formulario := BuscarStockConsulta;
  if Formulario = nil then
    Formulario := TfrmStockConsulta.Create(Application);
  Formulario.SetArticuloSku(ACodArt, ACodSku);
  if Formulario.WindowState = wsMinimized then
    Formulario.WindowState := wsMaximized;
  // Mostrar CON foco para que ESC cierre la ventana sin tener que pinchar
  // antes. Antes se mostraba con SW_SHOWNOACTIVATE y devolvia el foco a la
  // ventana anterior, lo que dejaba la consulta imposible de cerrar con ESC.
  Formulario.Visible := True;
  Formulario.BringToFront;
  SetForegroundWindow(Formulario.Handle);
end;

procedure DesvincularPerfilesStockConsulta;
var
  Formulario: TfrmStockConsulta;
begin
  Formulario := BuscarStockConsulta;
  if Formulario <> nil then
    Formulario.AsignarPerfilesUsuario(
      CrearServiciosPerfilesUsuario(nil, nil, nil));
end;

procedure TfrmStockConsulta.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poDesigned;
  Self.FormStyle := fsStayOnTop;
  Self.WindowState := wsMaximized;
  // ESC cierra la ventana; KeyPreview para capturarlo aunque el foco este
  // en el grid o el combo. Tambien sirve al hook del lector de codigo de
  // barras (FormKeyPress / FormKeyDown), que captura la lectura venga de
  // donde venga el foco.
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  Self.OnKeyPress := FormKeyPress;
  Self.OnResize := FormResize;
  // Detector del lector. Modo "consumir": las teclas de la rafaga no llegan a
  // btnArt (evita disparar SetArticuloSku en cada tecla del escaneo).
  FDependencias.Lector := TLectorScanner.Create;
  FDependencias.Lector.UmbralMs := SCAN_VEL_MS;
  FDependencias.Lector.LongitudMinima := SCAN_MIN_LONG;
  FDependencias.Lector.ConsumirRafaga := True;
  FDependencias.Lector.OnCodigoLeido := LectorCodigoLeido;
  // Coste (ultimo precio de compra del proveedor) solo para quien tenga
  // permiso: TienePermiso devuelve True siempre a admin; al resto, oculto
  // por defecto salvo permiso explicito 'caja.verCoste'.
  FVerCoste := Assigned(Permisos) and
               Permisos.TienePermiso(
                 PERMISO_CAJA_VER_COSTE,
                 paDenegar);
  FServiciosPersistencia := ContextoRepositoriosPantalla.Articulos.
    CrearServiciosStockConsulta(
    ConexionPrincipal);
  InicializarEntradaStockVcl(
    Self,
    ContextoRepositoriosPantalla.Articulos.
      CrearValidadorArticulos(ConexionPrincipal));
  FDs := TDataSource.Create(Self);
  FDs.DataSet := nil;
  tvStock.DataController.DataSource := FDs;
  FColsDin := TList<TcxGridDBColumn>.Create;
  FPropsPorColor := TDictionary<string, string>.Create;
  FHistorialArticulos := TStringList.Create;
  FHistorialPos := -1;
  FCodigosCoincidencia := TStringList.Create;
  FSkusCoincidencia := TStringList.Create;
  CrearComboCoincidencias;
  btnArt.OnKeyDown := btnArtKeyDown;
  btnArt.OnExit := btnArtExit;
  CrearBotonesHistorial;
  // Letrero de aviso: oculto por defecto, rojo y en negrita para que "cante"
  // las propiedades propias del color (color/SKU) al pincharlo. El texto lo
  // rellena ActualizarLetreroColor.
  lblLetreroTemp.Transparent      := False;
  lblLetreroTemp.Style.Color      := $003C3CD8;  // rojo (BGR)
  lblLetreroTemp.Style.TextColor  := clWhite;
  lblLetreroTemp.Style.Font.Style := [fsBold];
  lblLetreroTemp.Style.Font.Color := clWhite;
  lblLetreroTemp.Visible          := False;
  // Custom-draw para pintar el cuadradito del color basico en la celda
  // del color, via la libreria inLibAtributosPaleta (que se encarga del
  // lookup contra fza_atributos_basicos por texto/codigo y la cache).
  tvStock.OnCustomDrawCell := tvStockCustomDrawCell;
  FPopMenuStock := TPopupMenu.Create(Self);
  FPopMenuStock.OnPopup := PopMenuStockPopup;
  FMenuAgregarDoc := TMenuItem.Create(FPopMenuStock);
  FMenuAgregarDoc.Caption := SCaptionAgregarDocumentoTrabajo;
  FMenuAgregarDoc.OnClick := MenuAgregarDocClick;
  FPopMenuStock.Items.Add(FMenuAgregarDoc);
  grdStock.PopupMenu := FPopMenuStock;
  // Lista paralela combo -> estado y radios de modo
  FEstadosCombo := TList<TEstadoStock>.Create;
  FrbSimplificado := TcxRadioButton.Create(Self);
  FrbSimplificado.Parent := pnlFiltros;
  FrbSimplificado.Caption := SCaptionModoSimplificado;
  FrbSimplificado.SetBounds(cbbEstado.Left + cbbEstado.Width + 16,
                            cbbEstado.Top, 110, 18);
  FrbSimplificado.GroupIndex := 1;
  FrbSimplificado.OnClick := rbModoClick;
  FrbDesglosado := TcxRadioButton.Create(Self);
  FrbDesglosado.Parent := pnlFiltros;
  FrbDesglosado.Caption := SCaptionModoDesglosado;
  FrbDesglosado.SetBounds(FrbSimplificado.Left + FrbSimplificado.Width + 4,
                          cbbEstado.Top, 110, 18);
  FrbDesglosado.GroupIndex := 1;
  FrbDesglosado.OnClick := rbModoClick;
  CargarModoUsuario;
  if FModoDesglosado then
    FrbDesglosado.Checked := True
  else
    FrbSimplificado.Checked := True;
  CrearPestanasFotos;
  PoblarComboEstados;
  cbbEstado.Style.TextColor := ColorEstado(esExistencias);
  pcVistas.ActivePage := tsPorAlmacen;
  pcFiltros.ActivePage := tsColores;
  CrearEstilosEstado;
  CrearLeyenda;
  CargarAlmacenes;
  AjustarFotoCabecera;
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
                       IdentidadSesion.Usuario,
                       IdentidadSesion.Grupo,
                       PerfilesLectura);
    FModoDesglosado := SameText(
      GetPerfilValueDef(dic, 'ModoDesglosado', 'N'), 'S');
  finally
    if dic <> nil then
      FreeAndNil(dic);
  end;
end;

procedure TfrmStockConsulta.GuardarModoUsuario;
begin
  if Assigned(PerfilesEscritura) then
    PerfilesEscritura.GrabarPerfil(
      IdentidadSesion.Usuario,
      'frmStockConsulta',
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
    lbl.Tag        := Ord(ESTADOS_LEYENDA[i]);
    lbl.Cursor     := crHandPoint;
    lbl.OnClick    := LeyendaEstadoClick;
    lbl.Top        := 5;
    lbl.Left       := x;
    x := x + lbl.Width + 14;
  end;
end;

procedure TfrmStockConsulta.SeleccionarEstadoLeyenda(
  AEstado: TEstadoStock);
var
  i: Integer;
  bModoCambiado: Boolean;
begin
  bModoCambiado := False;
  if (AEstado in [esEntradas, esSalidas]) and FModoDesglosado then
  begin
    FModoDesglosado := False;
    FrbSimplificado.Checked := True;
    PoblarComboEstados;
    GuardarModoUsuario;
    bModoCambiado := True;
  end
  else if (AEstado in [esVentas, esRegularizadas, esPrestadas]) and
          not FModoDesglosado then
  begin
    FModoDesglosado := True;
    FrbDesglosado.Checked := True;
    PoblarComboEstados;
    GuardarModoUsuario;
    bModoCambiado := True;
  end;
  i := 0;
  while (FEstadosCombo <> nil) and (i < FEstadosCombo.Count) and
        (FEstadosCombo[i] <> AEstado) do
    Inc(i);
  if (FEstadosCombo <> nil) and (i < FEstadosCombo.Count) then
  begin
    if cbbEstado.ItemIndex <> i then
      cbbEstado.ItemIndex := i
    else if bModoCambiado then
      RecargarConsulta;
  end
  else if bModoCambiado then
    RecargarConsulta;
end;

procedure TfrmStockConsulta.LeyendaEstadoClick(Sender: TObject);
begin
  if Sender is TLabel then
    SeleccionarEstadoLeyenda(TEstadoStock(TLabel(Sender).Tag));
end;

procedure TfrmStockConsulta.FormDestroy(Sender: TObject);
begin
  LimpiarFotosRelacionadas;
  FDependencias.Aplicacion := nil;
  FreeAndNil(FDependencias.Lector);
  FDs.DataSet := nil;
  FResultadoPivote := nil;
  FServiciosPersistencia.Catalogos := nil;
  FServiciosPersistencia.Pivote := nil;
  FreeAndNil(FDs);
  FreeAndNil(FColsDin);
  FreeAndNil(FEstadosCombo);
  FreeAndNil(FPropsPorColor);
  FreeAndNil(FHistorialArticulos);
  FreeAndNil(FCodigosCoincidencia);
  FreeAndNil(FSkusCoincidencia);
  FreeAndNil(FCbbCoincidencias);
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmStockConsulta.FormResize(Sender: TObject);
begin
  AjustarFotoCabecera;
end;

// ESC oculta la ventana flotante. KeyPreview=True (FormCreate) garantiza que
// el form vea la tecla aunque el foco este en el grid, el combo o un check.
procedure TfrmStockConsulta.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // El detector cierra la lectura por velocidad (rafaga + Enter rapido) y
  // consume el VK_RETURN si procede.
  FDependencias.Lector.KeyDown(Key, Shift);
  if (Key = VK_ESCAPE) and (FCbbCoincidencias <> nil) and
     FCbbCoincidencias.Visible then
  begin
    Key := 0;
    OcultarComboCoincidencias;
    if btnArt.CanFocus then
      btnArt.SetFocus;
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end;
end;

// Hook del lector a nivel de formulario: delegamos en TLectorScanner, que
// detecta la trama STX/ETX y la rafaga por velocidad. El codigo leido llega
// luego por OnCodigoLeido (LectorCodigoLeido).
procedure TfrmStockConsulta.FormKeyPress(Sender: TObject; var Key: Char);
begin
  FDependencias.Lector.KeyPress(Key);
end;

procedure TfrmStockConsulta.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  AplicarLecturaCodigoBarras(ACodigo);
end;

// Resuelve el codigo SOLO contra codigos de barras y carga el articulo/SKU en
// la consulta (igual que al teclear o buscar un articulo, pero a partir del
// codigo de barras leido).
procedure TfrmStockConsulta.AplicarLecturaCodigoBarras(const ACodigo: string);
begin
  if Assigned(FDependencias.Aplicacion) then
    FDependencias.Aplicacion.ProcesarCodigoBarras(ACodigo);
end;

procedure TfrmStockConsulta.CrearComboCoincidencias;
begin
  if FCbbCoincidencias = nil then
  begin
    FCbbCoincidencias := TcxComboBox.Create(Self);
    FCbbCoincidencias.Parent := pnlCabecera;
    FCbbCoincidencias.Visible := False;
    FCbbCoincidencias.Properties.DropDownListStyle := lsFixedList;
    FCbbCoincidencias.Properties.OnEditValueChanged :=
      cbbCoincidenciasEditValueChanged;
    FCbbCoincidencias.OnExit := cbbCoincidenciasExit;
    FCbbCoincidencias.OnKeyDown := cbbCoincidenciasKeyDown;
    FCbbCoincidencias.TabOrder := btnArt.TabOrder + 1;
  end;
end;

procedure TfrmStockConsulta.OcultarComboCoincidencias;
begin
  if FCbbCoincidencias <> nil then
  begin
    FCbbCoincidencias.DroppedDown := False;
    FCbbCoincidencias.Visible := False;
  end;
end;

procedure TfrmStockConsulta.MostrarComboCoincidencias(
  const ACoincidencias: TCoincidenciasEntradaStock;
  const AEntrada: string);
var
  sArt, sSku, sDesc, sPrv, sRef, sItem: string;
  iAncho, iFilas: Integer;
  Coincidencia: TCoincidenciaEntradaStock;
begin
  CrearComboCoincidencias;
  FCbbCoincidencias.Properties.Items.BeginUpdate;
  try
    FCbbCoincidencias.Properties.Items.Clear;
    FCodigosCoincidencia.Clear;
    FSkusCoincidencia.Clear;
    for Coincidencia in ACoincidencias do
    begin
      sArt := Coincidencia.CodigoArticulo;
      sSku := Coincidencia.CodigoSku;
      sDesc := Coincidencia.Descripcion;
      sPrv := Coincidencia.Proveedor;
      sRef := Coincidencia.ReferenciaProveedor;
      sItem := sArt;
      if Trim(sSku) <> '' then
        sItem := sItem + ' / ' + sSku;
      if Trim(sDesc) <> '' then
        sItem := sItem + ' - ' + sDesc;
      if Trim(sPrv) <> '' then
        sItem := sItem + ' - ' + sPrv;
      if Trim(sRef) <> '' then
        sItem := sItem + ' (ref. ' + sRef + ')';
      if FCodigosCoincidencia.IndexOf(sArt) < 0 then
      begin
        FCbbCoincidencias.Properties.Items.Add(sItem);
        FCodigosCoincidencia.Add(sArt);
        FSkusCoincidencia.Add(sSku);
      end;
    end;
  finally
    FCbbCoincidencias.Properties.Items.EndUpdate;
  end;
  if FCbbCoincidencias.Properties.Items.Count > 0 then
  begin
    iAncho := pnlCabecera.ClientWidth - btnArt.Left - 20;
    if iAncho > 620 then
      iAncho := 620;
    if iAncho < btnArt.Width then
      iAncho := btnArt.Width;
    FCbbCoincidencias.SetBounds(btnArt.Left,
                                btnArt.Top + btnArt.Height + 2,
                                iAncho,
                                btnArt.Height);
    iFilas := FCbbCoincidencias.Properties.Items.Count;
    if iFilas > 15 then
      iFilas := 15;
    FCbbCoincidencias.Properties.DropDownRows := iFilas;
    FCbbCoincidencias.ItemIndex := -1;
    FCbbCoincidencias.Hint := Format(SHintCoincidenciasPara, [AEntrada]);
    FCbbCoincidencias.Visible := True;
    FCbbCoincidencias.BringToFront;
    if FCbbCoincidencias.CanFocus then
      FCbbCoincidencias.SetFocus;
    FCbbCoincidencias.DroppedDown := True;
  end;
end;

procedure TfrmStockConsulta.cbbCoincidenciasEditValueChanged(Sender: TObject);
var
  i: Integer;
  sArt, sSku: string;
begin
  if (FCbbCoincidencias <> nil) and (not FResolviendoEntrada) then
  begin
    i := FCbbCoincidencias.ItemIndex;
    if (i >= 0) and (i < FCodigosCoincidencia.Count) then
    begin
      FResolviendoEntrada := True;
      try
        sArt := FCodigosCoincidencia[i];
        sSku := FSkusCoincidencia[i];
        OcultarComboCoincidencias;
        SetArticuloSku(sArt, sSku);
      finally
        FResolviendoEntrada := False;
      end;
    end;
  end;
end;

procedure TfrmStockConsulta.cbbCoincidenciasExit(Sender: TObject);
begin
  if not FResolviendoEntrada then
    OcultarComboCoincidencias;
end;

procedure TfrmStockConsulta.cbbCoincidenciasKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    OcultarComboCoincidencias;
    if btnArt.CanFocus then
      btnArt.SetFocus;
  end
  else if Key = VK_RETURN then
  begin
    Key := 0;
    if (FCbbCoincidencias.ItemIndex < 0) and
       (FCbbCoincidencias.Properties.Items.Count > 0) then
      FCbbCoincidencias.ItemIndex := 0
    else
      cbbCoincidenciasEditValueChanged(Sender);
  end;
end;

procedure TfrmStockConsulta.btnArtKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    ResolverTextoArticulo(True);
  end;
end;

procedure TfrmStockConsulta.btnArtExit(Sender: TObject);
begin
  if (not FResolviendoEntrada) and (not FActualizandoArticulo) then
    ResolverTextoArticulo(False);
end;

procedure TfrmStockConsulta.ResolverTextoArticulo(AMostrarError: Boolean);
begin
  if (not FActualizandoArticulo) and
     (not FResolviendoEntrada) and
     Assigned(FDependencias.Aplicacion) then
  begin
    FResolviendoEntrada := True;
    try
      FDependencias.Aplicacion.ProcesarTexto(
        btnArt.Text,
        FCodArt,
        AMostrarError);
    finally
      FResolviendoEntrada := False;
    end;
  end;
end;

procedure TfrmStockConsulta.PopMenuStockPopup(Sender: TObject);
var
  linea: TDocTrabajoLineaOrigen;
  sMsg : string;
begin
  FMenuAgregarDoc.Enabled := ResolverCeldaDocumentoTrabajo(linea, sMsg);
end;

procedure TfrmStockConsulta.MenuAgregarDocClick(Sender: TObject);
var
  linea: TDocTrabajoLineaOrigen;
  sMsg : string;
begin
  if ResolverCeldaDocumentoTrabajo(linea, sMsg) then
  begin
    try
      AgregarUnidadADocumentoTrabajo(
        Self,
        ConexionPrincipal,
        ContextoRepositoriosPantalla.Documentos.
          CrearRepositoriosDocumentosTrabajo(ConexionPrincipal),
        CrearInteraccionDocumentosTrabajoVcl,
        BusquedaVisual,
        ContextoSesion,
        ParametrosCaja,
        linea,
        ContextoRepositoriosPantalla.Articulos.CrearResolverArticulos(
          ConexionPrincipal));
    except
      on E: Exception do
      begin
        MostrarError(E.Message);
      end;
    end;
  end
  else
  begin
    Application.MessageBox(PChar(sMsg), PChar(STituloDocumentoTrabajo),
      MB_OK or MB_ICONINFORMATION or MB_TOPMOST or MB_SETFOREGROUND);
  end;
end;

function TfrmStockConsulta.ResolverCodigoSkuDocumentoTrabajo(
  const AColor, ATalla: string; out ACodigoSku, AMensaje: string): Boolean;
var
  iCount: Integer;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  iCount := FServiciosPersistencia.Catalogos.ResolverSku(
    FCodArt,
    AColor,
    ATalla,
    ACodigoSku);
  if iCount = 1 then
  begin
    Result := True;
  end
  else if iCount = 0 then
  begin
    AMensaje := SErrorSkuCeldaStockNoEncontrado;
  end
  else
  begin
    AMensaje := SErrorCeldaStockVariosSkus;
  end;
end;

function TfrmStockConsulta.ResolverSkuCeldaOperacionesCaja(
  out ACodigoSku, AMensaje: string): Boolean;
var
  rec     : TcxCustomGridRecord;
  col     : TcxGridDBColumn;
  sCampo  : string;
  sGrupo  : string;
  sColor  : string;
  sTalla  : string;
  iTalla  : Integer;
  colores : TArray<string>;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  rec := nil;
  col := nil;
  sCampo := '';
  sGrupo := '';
  sColor := '';
  sTalla := '';
  iTalla := -1;
  if Trim(FCodArt) = '' then
  begin
    AMensaje := SErrorArticuloStockNoSeleccionadoOperaciones;
  end;
  if AMensaje = '' then
  begin
    rec := tvStock.Controller.FocusedRecord;
    if rec = nil then
    begin
      AMensaje := SErrorCeldaTallaStockNoSeleccionada;
    end;
  end;
  if AMensaje = '' then
  begin
    if tvStock.Controller.FocusedColumn is TcxGridDBColumn then
    begin
      col := TcxGridDBColumn(tvStock.Controller.FocusedColumn);
    end
    else
    begin
      AMensaje := SErrorCeldaTallaStockNoSeleccionada;
    end;
  end;
  if AMensaje = '' then
  begin
    sCampo := col.DataBinding.FieldName;
    if StartsText('T', sCampo) and
       TryStrToInt(Copy(sCampo, 2, MaxInt), iTalla) and
       (iTalla >= 0) and (iTalla <= High(FColumnas)) then
    begin
      sTalla := FColumnas[iTalla].Codigo;
    end
    else if SameText(sCampo, 'TOTAL') and (Length(FColumnas) = 0) then
    begin
      sTalla := '';
    end
    else
    begin
      AMensaje := SErrorColumnaTallaStockNoSeleccionada;
    end;
  end;
  if (AMensaje = '') and (FColGrupo = nil) then
  begin
    AMensaje := SErrorFilaStockNoIdentificada;
  end;
  if AMensaje = '' then
  begin
    sGrupo := VarToStr(rec.Values[FColGrupo.Index]);
    if FEsModoColor then
    begin
      sColor := sGrupo;
    end
    else
    begin
      colores := ColoresSeleccionadosLista;
      if Length(colores) = 1 then
      begin
        sColor := colores[0];
      end
      else if (Length(colores) = 0) and
              (lstColores.Items.Count = 0) then
      begin
        sColor := '';
      end
      else
      begin
        AMensaje := SErrorColorStockNoUnico;
      end;
    end;
  end;
  if AMensaje = '' then
  begin
    Result := ResolverCodigoSkuDocumentoTrabajo(
                sColor, sTalla, ACodigoSku, AMensaje);
    if (not Result) and
       (Pos('varios SKUs', AMensaje) > 0) then
    begin
      AMensaje := SErrorTallaStockVariosSkus;
    end;
  end;
end;

procedure TfrmStockConsulta.btnOperacionesCajaClick(Sender: TObject);
var
  sCodigoSku : string;
  sMensaje   : string;
begin
  if ResolverSkuCeldaOperacionesCaja(sCodigoSku, sMensaje) then
  begin
    TfrmModalOperacionesCajaSku.Ejecutar(
      Self,
      ConexionPrincipal,
      sCodigoSku,
      lblDescr.Caption);
  end
  else
  begin
    Application.MessageBox(
      PChar(sMensaje),
      PChar(STituloOperacionesCajaStock),
      MB_OK or MB_ICONINFORMATION or MB_TOPMOST or MB_SETFOREGROUND);
  end;
end;

function TfrmStockConsulta.ResolverCeldaDocumentoTrabajo(
  out ALinea: TDocTrabajoLineaOrigen; out AMensaje: string): Boolean;
var
  rec      : TcxCustomGridRecord;
  col      : TcxGridDBColumn;
  vCantidad: Variant;
  i        : Integer;
  sSku     : string;
  Estado   : TEstadoCeldaStock;
  Celda    : TCeldaDocumentoResuelta;
  Linea    : TLineaCeldaStock;
begin
  Result := False;
  ALinea.Clear;
  AMensaje := '';
  // Aqui solo se lee el grid; las decisiones (guardas, talla, almacen
  // y color) viven en inLibStockCeldaDocumento.
  Estado := Default(TEstadoCeldaStock);
  Estado.CodigoArticulo := FCodArt;
  Estado.EsModoTodo := FEsModoTodo;
  Estado.EsModoColor := FEsModoColor;
  Estado.EstadoEsExistencias := EstadoActual = esExistencias;
  Estado.HayColoresEnLista := lstColores.Items.Count > 0;
  Estado.AlmacenesSeleccionados := AlmacenesSeleccionadosLista;
  Estado.ColoresSeleccionados := ColoresSeleccionadosLista;
  SetLength(Estado.Tallas, Length(FColumnas));
  for i := 0 to High(FColumnas) do
    Estado.Tallas[i] := FColumnas[i].Codigo;
  rec := tvStock.Controller.FocusedRecord;
  Estado.HayFila := rec <> nil;
  col := nil;
  if tvStock.Controller.FocusedColumn is TcxGridDBColumn then
  begin
    col := TcxGridDBColumn(tvStock.Controller.FocusedColumn);
    Estado.HayColumnaDeDatos := True;
    Estado.NombreCampo := col.DataBinding.FieldName;
  end;
  if Estado.HayFila and (FColEstado <> nil) then
    Estado.FilaEsExistencias :=
      StrToIntDef(VarToStr(rec.Values[FColEstado.Index]), -1) =
        Ord(esExistencias);
  if Estado.HayFila and (FColGrupo <> nil) then
  begin
    Estado.HayColumnaGrupo := True;
    Estado.Grupo := VarToStr(rec.Values[FColGrupo.Index]);
  end;
  Celda := ResolverCeldaStockParaDocumento(Estado);
  case Celda.Motivo of
    mcdSinArticulo:
      AMensaje := SErrorArticuloStockNoSeleccionadoDocumento;
    mcdEstadoNoExistencias:
      AMensaje := SErrorEstadoStockNoEsExistencias;
    mcdSinFila:
      AMensaje := SErrorCeldaStockNoSeleccionada;
    mcdSinColumnaCantidad:
      AMensaje := SErrorCeldaCantidadStockNoSeleccionada;
    mcdFilaNoExistencias:
      AMensaje := SErrorFilaExistenciasStockNoSeleccionada;
    mcdColumnaNoValida:
      AMensaje := SErrorColumnaStockDocumentoNoSeleccionada;
    mcdGrupoNoLeido:
      AMensaje := SErrorGrupoFilaStockNoLeido;
    mcdAlmacenNoUnico:
      AMensaje := SErrorAlmacenStockNoUnico;
    mcdColorNoUnico:
      AMensaje := SErrorColorStockUnidadNoUnico;
  end;
  if AMensaje = '' then
  begin
    if ResolverCodigoSkuDocumentoTrabajo(Celda.Color, Celda.Talla,
                                         sSku, AMensaje) then
    begin
      vCantidad := rec.Values[col.Index];
      if VarIsNull(vCantidad) or VarIsEmpty(vCantidad) then
        Linea := ComponerLineaCeldaStock(
          FCodArt, Celda.Almacen, sSku,
          Celda.Color, Celda.Talla, 0, True)
      else
        Linea := ComponerLineaCeldaStock(
          FCodArt, Celda.Almacen, sSku, Celda.Color, Celda.Talla,
          VarAsType(vCantidad, varDouble), False);
      ALinea.CodigoArticulo := Linea.CodigoArticulo;
      ALinea.CodigoSku := Linea.CodigoSku;
      ALinea.CodigoAlmacen := Linea.CodigoAlmacen;
      ALinea.DescripcionSku := Linea.DescripcionSku;
      ALinea.Origen := Linea.Origen;
      ALinea.CantidadStock := Linea.CantidadStock;
      ALinea.Cantidad := Linea.Cantidad;
      Result := True;
    end;
  end;
end;

// Muestra un mensaje de error por ENCIMA de la ventana. Como el form es
// fsStayOnTop, un dialogo normal saldria por detras y la app pareceria
// colgada; MB_TOPMOST + MB_SETFOREGROUND fuerzan el aviso al frente.
procedure TfrmStockConsulta.MostrarError(const AMsg: string);
begin
  Application.MessageBox(PChar(AMsg), PChar(STituloConsultaStock),
    MB_OK or MB_ICONERROR or MB_TOPMOST or MB_SETFOREGROUND);
end;

// ---------------------------------------------------------------------------
//  Almacenes (lista de seleccion multiple)
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CargarAlmacenes;
var
  bStd: Boolean;
  iItem: Integer;
  oResultado: IResultadoConsultaStock;
  q: TDataSet;
begin
  lstAlmacenes.Items.Clear;
  oResultado := FServiciosPersistencia.Catalogos.ConsultarAlmacenes;
  q := oResultado.DataSet;
  try
    while not q.Eof do
    begin
      iItem := lstAlmacenes.Items.Add(
        q.FieldByName('CODIGO_ALM_ALM').AsString + ' - ' +
        q.FieldByName('NOMBRE_ALM_ALM').AsString);
      bStd := (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDAR') or
              (q.FieldByName('TIPO_USO_ALM').AsString = 'ESTANDARD');
      lstAlmacenes.Selected[iItem] := bStd;
      q.Next;
    end;
  finally
    oResultado := nil;
  end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosLista: TArray<string>;
var
  i, p: Integer;
  s, sCod: string;
begin
  SetLength(Result, 0);
  for i := 0 to lstAlmacenes.Items.Count - 1 do
    if lstAlmacenes.Selected[i] then
    begin
      s := lstAlmacenes.Items[i];
      p := Pos(' - ', s);
      if p > 0 then sCod := Copy(s, 1, p - 1) else sCod := s;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := sCod;
    end;
end;

// ---------------------------------------------------------------------------
//  Colores del articulo (lista de seleccion multiple)
// ---------------------------------------------------------------------------
// Carga los AVs distintos de color (ID_VA_AV='CO') que aparecen en los SKUs
// activos del articulo. Si la entrada resolvio un SKU concreto, se selecciona
// solo su color; el usuario puede anadir despues los demas. Sin SKU o si este
// no permite resolver un color, se seleccionan todos como hasta ahora.
procedure TfrmStockConsulta.CargarColores;
var
  i                    : Integer;
  iItem                : Integer;
  bFiltrarPorSku       : Boolean;
  bEsColorSku          : Boolean;
  bColorSkuEncontrado  : Boolean;
  oResultado: IResultadoConsultaStock;
  q: TDataSet;
begin
  lstColores.Items.Clear;
  if Trim(FCodArt) = '' then Exit;
  bFiltrarPorSku := Trim(FCodSku) <> '';
  bColorSkuEncontrado := False;
  oResultado := FServiciosPersistencia.Catalogos.ConsultarColores(
    FCodArt,
    FCodSku);
  q := oResultado.DataSet;
  try
    while not q.Eof do
    begin
      iItem := lstColores.Items.Add(q.FieldByName('AV').AsString);
      bEsColorSku := bFiltrarPorSku and
                     (q.FieldByName('ES_COLOR_SKU').AsInteger = 1);
      lstColores.Selected[iItem] := (not bFiltrarPorSku) or bEsColorSku;
      if bEsColorSku then
        bColorSkuEncontrado := True;
      q.Next;
    end;
    if bFiltrarPorSku and not bColorSkuEncontrado then
    begin
      for i := 0 to lstColores.Items.Count - 1 do
        lstColores.Selected[i] := True;
    end;
  finally
    oResultado := nil;
  end;
end;

// ---------------------------------------------------------------------------
//  Propiedades propias por color (nivel COLOR / SKU)
// ---------------------------------------------------------------------------
// Las propiedades admiten nivel COLOR y SKU (propiedades_por_unidad.md): el
// color es el prefijo del SKU (CODIGO_UNIDAD_ARTPROP = 'ART/COLOR' =
// SUBSTRING_INDEX(sku,'/',2)) y el SKU el codigo completo ('ART/COLOR/TALLA').
// Recogemos, por color del articulo, TODAS las propiedades fijadas a nivel
// color o SKU cuyo valor DIFIERE del nivel articulo, ya formateadas, para
// "cantarlas" en el letrero al pinchar el color. El nivel SKU se marca y se
// deduplican entradas repetidas por varias tallas.
procedure TfrmStockConsulta.CargarPropsPorColor;
  // Valor mostrable segun tipo, igual que CargarInfoCabecera.
  function ValorProp(const ATipo, APv, ALibre: string): string;
  begin
    if SameText(ATipo, 'LISTA') then
      Result := Trim(APv)
    else if SameText(ATipo, 'BOOLEANO') then
    begin
      if Trim(ALibre) = '' then
        Result := ''
      else if SameText(Trim(ALibre), 'S') then
        Result := 'Sí'
      else
        Result := 'No';
    end
    else
      Result := Trim(ALibre);
  end;
var
  oResultado: IResultadoConsultaStock;
  q: TDataSet;
  sColor    : string;
  sValor    : string;
  sValorArt : string;
  sEntrada  : string;
  sAcum     : string;
begin
  FPropsPorColor.Clear;
  if Trim(FCodArt) = '' then Exit;
  oResultado := FServiciosPersistencia.Catalogos.
    ConsultarPropiedadesPorColor(FCodArt);
  q := oResultado.DataSet;
  try
    while not q.Eof do
    begin
      sColor    := q.FieldByName('COLOR').AsString;
      sValor    := ValorProp(q.FieldByName('TIPO').AsString,
                             q.FieldByName('PVTXT').AsString,
                             q.FieldByName('VLIBRE').AsString);
      sValorArt := ValorProp(q.FieldByName('TIPO').AsString,
                             q.FieldByName('PVA').AsString,
                             q.FieldByName('VLIBRE_ART').AsString);
      // Solo lo que aporta valor y difiere del nivel articulo.
      if (sValor <> '') and (not SameText(sValor, sValorArt)) then
      begin
        sEntrada := Format('%s: %s (%s)',
          [q.FieldByName('NOMBRE').AsString, sValor,
           IfThen(SameText(q.FieldByName('NIVEL').AsString, 'SKU'),
                  'SKU', 'color')]);
        if FPropsPorColor.TryGetValue(sColor, sAcum) then
        begin
          // Deduplicar: el mismo prop/valor puede repetirse por varias tallas.
          if Pos(sEntrada, sAcum) = 0 then
            FPropsPorColor[sColor] := sAcum + '   ·   ' + sEntrada;
        end
        else
          FPropsPorColor.Add(sColor, sEntrada);
      end;
      q.Next;
    end;
  finally
    oResultado := nil;
  end;
end;

// Recompone el letrero para el color sobre el que se acaba de pinchar (item
// con foco en la lista): si ese color tiene propiedades propias (nivel
// color/SKU) distintas a las del articulo, las "canta"; si no, oculta el
// letrero. Se llama al cambiar la seleccion (OnClick), que ademas actualiza
// la consulta.
procedure TfrmStockConsulta.ActualizarLetreroColor;
var
  iSel   : Integer;
  sColor : string;
  sProps : string;
begin
  if (FPropsPorColor = nil) or (lblLetreroTemp = nil) then Exit;
  iSel := lstColores.ItemIndex;
  if (iSel >= 0) and (iSel < lstColores.Items.Count) and
     FPropsPorColor.TryGetValue(lstColores.Items[iSel], sProps) then
  begin
    sColor := lstColores.Items[iSel];
    lblLetreroTemp.Caption := Format('  %s →   %s', [sColor, sProps]);
    lblLetreroTemp.Visible := True;
  end
  else
  begin
    lblLetreroTemp.Caption := '';
    lblLetreroTemp.Visible := False;
  end;
  AjustarFotoCabecera;
end;

function TfrmStockConsulta.ColoresSeleccionadosLista: TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to lstColores.Items.Count - 1 do
    if lstColores.Selected[i] then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := lstColores.Items[i];
    end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto + info de precios
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  sDescripcion: string;
  dim: TDimensionFotos;
  bArticuloEncontrado: Boolean;
begin
  FCodArt := ACodArt;
  FCodSku := ACodSku;
  FActualizandoArticulo := True;
  try
    btnArt.Text := ACodArt;
  finally
    FActualizandoArticulo := False;
  end;
  OcultarComboCoincidencias;
  InvalidarFotosRelacionadas;
  bArticuloEncontrado := False;
  if DimensionFotosActiva(dim) then
  begin
    FSilenciarCambioVista := True;
    try
      pcVistas.ActivePage := tsPorAlmacen;
    finally
      FSilenciarCambioVista := False;
    end;
  end;

  lblDescr.Caption := '';
  if Trim(ACodArt) <> '' then
  begin
    bArticuloEncontrado := FServiciosPersistencia.Catalogos.
      ObtenerDescripcionArticulo(ACodArt, sDescripcion);
    if bArticuloEncontrado then
      lblDescr.Caption := sDescripcion;
  end;

  // Errores de carga (foto / cabecera / colores) por encima de la ventana.
  try
    CargarFoto(FCodSku);
    CargarInfoCabecera;
    CargarColores;
    CargarPropsPorColor;
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  // El letrero arranca oculto: solo "canta" cuando el usuario pincha un color.
  lblLetreroTemp.Caption := '';
  lblLetreroTemp.Visible := False;
  AjustarFotoCabecera;
  if bArticuloEncontrado then
    RegistrarArticuloHistorial(ACodArt);
  ActualizarBotonesHistorial;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.AjustarFotoCabecera;
const
  MARGEN_FOTO       = 8;
  PORCENTAJE_INICIO = 55;
  ANCHO_TEXTO_MIN   = 480;
  ANCHO_FOTO_MIN    = 180;
var
  iIzquierda : Integer;
  iAlto      : Integer;
begin
  iIzquierda := pnlCabecera.ClientWidth * PORCENTAJE_INICIO div 100;
  if iIzquierda < ANCHO_TEXTO_MIN then
    iIzquierda := ANCHO_TEXTO_MIN;
  if iIzquierda > pnlCabecera.ClientWidth - ANCHO_FOTO_MIN then
    iIzquierda := pnlCabecera.ClientWidth - ANCHO_FOTO_MIN;
  iAlto := pnlCabecera.ClientHeight - (MARGEN_FOTO * 2);
  if lblLetreroTemp.Visible then
    iAlto := iAlto - lblLetreroTemp.Height;
  imgFoto.SetBounds(iIzquierda,
                    MARGEN_FOTO,
                    pnlCabecera.ClientWidth - iIzquierda - MARGEN_FOTO,
                    iAlto);
  lblInfo.Width := iIzquierda - lblInfo.Left - MARGEN_FOTO;
end;

procedure TfrmStockConsulta.CargarFoto(const ACodUnidad: string);
var
  info: TFotoInfo;
  ruta: string;
  png : TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if Trim(FCodArt) = '' then Exit;
  info := FotosArticulos.Resolver(FCodArt, ACodUnidad);
  // En la consulta de stock la foto dispone de una zona amplia: cargar
  // siempre la copia a resolucion real y ajustarla proporcionalmente.
  ruta := FotosArticulos.RutaFoto(info, frReal);
  if ruta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(ruta);
    imgFoto.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

procedure TfrmStockConsulta.CrearBotonesHistorial;
begin
  FBtnHistAnterior := TcxButton.Create(Self);
  FBtnHistAnterior.Parent := pnlCabecera;
  FBtnHistAnterior.Caption := '<';
  FBtnHistAnterior.Hint := SHintArticuloAnterior;
  FBtnHistAnterior.ShowHint := True;
  FBtnHistAnterior.SetBounds(btnArt.Left + btnArt.Width + 8,
                             btnArt.Top, 28, btnArt.Height);
  FBtnHistAnterior.OnClick := HistorialAnteriorClick;
  FBtnHistSiguiente := TcxButton.Create(Self);
  FBtnHistSiguiente.Parent := pnlCabecera;
  FBtnHistSiguiente.Caption := '>';
  FBtnHistSiguiente.Hint := SHintArticuloSiguiente;
  FBtnHistSiguiente.ShowHint := True;
  FBtnHistSiguiente.SetBounds(FBtnHistAnterior.Left +
                              FBtnHistAnterior.Width + 4,
                              btnArt.Top, 28, btnArt.Height);
  FBtnHistSiguiente.OnClick := HistorialSiguienteClick;
  ActualizarBotonesHistorial;
end;

procedure TfrmStockConsulta.HistorialAnteriorClick(Sender: TObject);
begin
  if (FHistorialArticulos <> nil) and (FHistorialPos > 0) then
  begin
    Dec(FHistorialPos);
    FMoviendoHistorial := True;
    try
      SetArticuloSku(FHistorialArticulos[FHistorialPos], '');
    finally
      FMoviendoHistorial := False;
      ActualizarBotonesHistorial;
    end;
  end;
end;

procedure TfrmStockConsulta.HistorialSiguienteClick(Sender: TObject);
begin
  if (FHistorialArticulos <> nil) and
     (FHistorialPos < FHistorialArticulos.Count - 1) then
  begin
    Inc(FHistorialPos);
    FMoviendoHistorial := True;
    try
      SetArticuloSku(FHistorialArticulos[FHistorialPos], '');
    finally
      FMoviendoHistorial := False;
      ActualizarBotonesHistorial;
    end;
  end;
end;

procedure TfrmStockConsulta.RegistrarArticuloHistorial(const ACodArt: string);
begin
  if (FHistorialArticulos <> nil) and (not FMoviendoHistorial) and
     (Trim(ACodArt) <> '') then
  begin
    if (FHistorialPos < 0) or
       (not SameText(FHistorialArticulos[FHistorialPos], ACodArt)) then
    begin
      while FHistorialArticulos.Count - 1 > FHistorialPos do
        FHistorialArticulos.Delete(FHistorialArticulos.Count - 1);
      FHistorialArticulos.Add(ACodArt);
      FHistorialPos := FHistorialArticulos.Count - 1;
    end;
  end;
end;

procedure TfrmStockConsulta.ActualizarBotonesHistorial;
begin
  if FBtnHistAnterior <> nil then
    FBtnHistAnterior.Enabled := (FHistorialArticulos <> nil) and
                                (FHistorialPos > 0);
  if FBtnHistSiguiente <> nil then
    FBtnHistSiguiente.Enabled := (FHistorialArticulos <> nil) and
                                 (FHistorialPos <
                                  FHistorialArticulos.Count - 1);
end;

function TfrmStockConsulta.NombreDimensionFotos(
  ADimension: TDimensionFotos): string;
begin
  case ADimension of
    dfFamilia:
      Result := 'Familia';
    dfProveedor:
      Result := 'Proveedor';
    dfTemporada:
      Result := 'Temporada';
  else
    Result := '';
  end;
end;

procedure TfrmStockConsulta.CrearPestanasFotos;
var
  dim: TDimensionFotos;
  ts : TcxTabSheet;
begin
  for dim := Low(TDimensionFotos) to High(TDimensionFotos) do
  begin
    ts := TcxTabSheet.Create(Self);
    ts.PageControl := pcVistas;
    case dim of
      dfFamilia:
        ts.Caption := SCaptionFotosMismaFamilia;
      dfProveedor:
        ts.Caption := SCaptionFotosMismoProveedor;
      dfTemporada:
        ts.Caption := SCaptionFotosMismaTemporada;
    end;
    FTsFotos[dim] := ts;
    FFotosCargadas[dim] := False;
    FFotosArt[dim] := '';
    FFotosFiltros[dim] := [];
    FFotosFiltrosCache[dim] := [];
  end;
  FScrFotos := TScrollBox.Create(Self);
  FScrFotos.Parent := pnlDer;
  FScrFotos.Align := alClient;
  FScrFotos.BorderStyle := bsNone;
  FScrFotos.Visible := False;
  FBtnFiltroFoto1 := TcxButton.Create(Self);
  FBtnFiltroFoto1.Parent := FScrFotos;
  FBtnFiltroFoto1.SetBounds(12, 10, 128, 26);
  FBtnFiltroFoto1.OnClick := BotonFiltroFotosClick;
  FBtnFiltroFoto2 := TcxButton.Create(Self);
  FBtnFiltroFoto2.Parent := FScrFotos;
  FBtnFiltroFoto2.SetBounds(148, 10, 128, 26);
  FBtnFiltroFoto2.OnClick := BotonFiltroFotosClick;
end;

procedure TfrmStockConsulta.InvalidarFotosRelacionadas;
var
  dim: TDimensionFotos;
begin
  for dim := Low(TDimensionFotos) to High(TDimensionFotos) do
  begin
    FFotosCargadas[dim] := False;
    FFotosArt[dim] := '';
  end;
end;

function TfrmStockConsulta.DimensionFotosActiva(
  out ADimension: TDimensionFotos): Boolean;
var
  dim: TDimensionFotos;
begin
  Result := False;
  for dim := Low(TDimensionFotos) to High(TDimensionFotos) do
    if pcVistas.ActivePage = FTsFotos[dim] then
    begin
      ADimension := dim;
      Result := True;
    end;
end;

procedure TfrmStockConsulta.MostrarVistaFotosRelacionadas(AVisible: Boolean);
begin
  if FScrFotos <> nil then
  begin
    grdStock.Visible := not AVisible;
    FScrFotos.Visible := AVisible;
    if AVisible then
      FScrFotos.BringToFront
    else
      grdStock.BringToFront;
  end
  else
    grdStock.Visible := True;
end;

procedure TfrmStockConsulta.LimpiarFotosRelacionadas;
var
  i  : Integer;
  ctl: TControl;
begin
  if FScrFotos <> nil then
    for i := FScrFotos.ControlCount - 1 downto 0 do
    begin
      ctl := FScrFotos.Controls[i];
      if (ctl <> FBtnFiltroFoto1) and (ctl <> FBtnFiltroFoto2) then
        ctl.Free;
    end;
end;

procedure TfrmStockConsulta.MostrarMensajeFotosRelacionadas(
  const AMsg: string);
var
  lbl: TcxLabel;
begin
  if FScrFotos <> nil then
  begin
    LimpiarFotosRelacionadas;
    lbl := TcxLabel.Create(FScrFotos);
    lbl.Parent := FScrFotos;
    lbl.SetBounds(16, 50, FScrFotos.ClientWidth - 32, 40);
    lbl.AutoSize := False;
    lbl.Caption := AMsg;
    lbl.Properties.WordWrap := True;
    lbl.Transparent := True;
  end;
end;

procedure TfrmStockConsulta.ConfigurarFiltrosFotos(
  ADimension: TDimensionFotos);
var
  filtro1: TDimensionFotos;
  filtro2: TDimensionFotos;
  procedure ConfigBoton(ABoton: TcxButton; AFiltro: TDimensionFotos);
  var
    sMarca: string;
  begin
    ABoton.Tag := Ord(AFiltro);
    if AFiltro in FFotosFiltros[ADimension] then
      sMarca := '[X] '
    else
      sMarca := '[ ] ';
    ABoton.Caption := sMarca + NombreDimensionFotos(AFiltro);
    ABoton.Visible := True;
  end;
begin
  case ADimension of
    dfFamilia:
      begin
        filtro1 := dfProveedor;
        filtro2 := dfTemporada;
      end;
    dfProveedor:
      begin
        filtro1 := dfFamilia;
        filtro2 := dfTemporada;
      end;
  else
    filtro1 := dfFamilia;
    filtro2 := dfProveedor;
  end;
  if (FBtnFiltroFoto1 <> nil) and (FBtnFiltroFoto2 <> nil) then
  begin
    ConfigBoton(FBtnFiltroFoto1, filtro1);
    ConfigBoton(FBtnFiltroFoto2, filtro2);
    FBtnFiltroFoto1.BringToFront;
    FBtnFiltroFoto2.BringToFront;
  end;
end;

procedure TfrmStockConsulta.BotonFiltroFotosClick(Sender: TObject);
var
  dim   : TDimensionFotos;
  filtro: TDimensionFotos;
begin
  if DimensionFotosActiva(dim) and (Sender is TcxButton) then
  begin
    filtro := TDimensionFotos(TcxButton(Sender).Tag);
    if filtro in FFotosFiltros[dim] then
      Exclude(FFotosFiltros[dim], filtro)
    else
      Include(FFotosFiltros[dim], filtro);
    FFotosCargadas[dim] := False;
    ConfigurarFiltrosFotos(dim);
    CargarFotosRelacionadas(dim);
  end;
end;

procedure TfrmStockConsulta.CargarFotosRelacionadasSiProcede;
var
  dim: TDimensionFotos;
begin
  if DimensionFotosActiva(dim) then
  begin
    ConfigurarFiltrosFotos(dim);
    if (not FFotosCargadas[dim]) or
       (not SameText(FFotosArt[dim], FCodArt)) or
       (FFotosFiltrosCache[dim] <> FFotosFiltros[dim]) then
      CargarFotosRelacionadas(dim);
  end;
end;

procedure TfrmStockConsulta.CargarFotosRelacionadas(
  ADimension: TDimensionFotos);
var
  oResultado: IResultadoConsultaStock;
  q: TDataSet;
  Solicitud: TSolicitudFotosRelacionadasStock;
  codigos : TList<string>;
  fotos   : TDictionary<string, TFotoInfo>;
  arr     : TArray<string>;
  i       : Integer;
  columnas: Integer;
begin
  LimpiarFotosRelacionadas;
  ConfigurarFiltrosFotos(ADimension);
  FFotosCargadas[ADimension] := False;
  FFotosArt[ADimension] := FCodArt;
  FFotosFiltrosCache[ADimension] := FFotosFiltros[ADimension];
  if Trim(FCodArt) = '' then
  begin
    MostrarMensajeFotosRelacionadas(
      SErrorArticuloStockNoSeleccionadoFotos);
    FFotosCargadas[ADimension] := True;
    end
    else
    begin
      Screen.Cursor := crHourGlass;
      codigos := TList<string>.Create;
      fotos := nil;
      try
      Solicitud.CodigoArticulo := FCodArt;
      Solicitud.Dimension := ADimension;
      Solicitud.Filtros := FFotosFiltros[ADimension];
      oResultado := FServiciosPersistencia.Catalogos.
        ConsultarFotosRelacionadas(Solicitud);
      q := oResultado.DataSet;
      if q.IsEmpty then
        MostrarMensajeFotosRelacionadas(
          SInfoArticulosRelacionadosStockNoDisponibles)
      else
      begin
        while not q.Eof do
        begin
          codigos.Add(q.FieldByName('CODIGO_ART_ART').AsString);
          q.Next;
        end;
        SetLength(arr, codigos.Count);
        for i := 0 to codigos.Count - 1 do
          arr[i] := codigos[i];
        fotos := FotosArticulos.ResolverArticulosLote(arr);
        q.First;
        columnas := (FScrFotos.ClientWidth - 12) div 176;
        if columnas < 1 then
          columnas := 1;
        i := 0;
        while not q.Eof do
        begin
          PintarTarjetaRelacionada(i, columnas, q, fotos);
          Inc(i);
          q.Next;
        end;
      end;
      FFotosCargadas[ADimension] := True;
    finally
      FreeAndNil(fotos);
      FreeAndNil(codigos);
      oResultado := nil;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmStockConsulta.PintarTarjetaRelacionada(AIndice: Integer;
  AColumnas: Integer; ADataSet: TDataSet;
  AFotos: TDictionary<string, TFotoInfo>);
const
  CAncho  = 164;
  CAlto   = 238;
  CMargen = 12;
  CTop    = 48;
var
  pnl       : TPanel;
  img       : TImage;
  lbl       : TLabel;
  lblStock  : TLabel;
  info      : TFotoInfo;
  png       : TPngImage;
  sArt      : string;
  sDescr    : string;
  sRuta     : string;
  sColores  : string;
  sTallas   : string;
  x         : Integer;
  y         : Integer;
  procedure PrepararDobleClick(AControl: TControl);
  begin
    AControl.Hint := sArt;
    AControl.ShowHint := True;
    AControl.Cursor := crHandPoint;
  end;
begin
  sArt := ADataSet.FieldByName('CODIGO_ART_ART').AsString;
  sDescr := ADataSet.FieldByName('DESCRIPCION_ART').AsString;
  sColores := Trim(ADataSet.FieldByName('COLORES').AsString);
  sTallas := Trim(ADataSet.FieldByName('TALLAS').AsString);
  if sColores = '' then
    sColores := 'sin color';
  if sTallas = '' then
    sTallas := 'sin talla';
  x := CMargen + (AIndice mod AColumnas) * (CAncho + CMargen);
  y := CTop + CMargen + (AIndice div AColumnas) * (CAlto + CMargen);
  pnl := TPanel.Create(FScrFotos);
  pnl.Parent := FScrFotos;
  pnl.SetBounds(x, y, CAncho, CAlto);
  pnl.BevelOuter := bvLowered;
  pnl.Color := clWindow;
  pnl.ParentBackground := False;
  PrepararDobleClick(pnl);
  pnl.OnDblClick := TarjetaFotoDblClick;
  sRuta := '';
  if (AFotos <> nil) and AFotos.TryGetValue(sArt, info) then
    sRuta := FotosArticulos.RutaFoto(info, frPx300);
  if sRuta <> '' then
  begin
    img := TImage.Create(pnl);
    img.Parent := pnl;
    img.SetBounds(8, 8, CAncho - 16, 118);
    img.Center := True;
    img.Proportional := True;
    img.Stretch := True;
    PrepararDobleClick(img);
    img.OnDblClick := TarjetaFotoDblClick;
    png := TPngImage.Create;
    try
      png.LoadFromFile(sRuta);
      img.Picture.Assign(png);
    finally
      FreeAndNil(png);
    end;
  end
  else
  begin
    lbl := TLabel.Create(pnl);
    lbl.Parent := pnl;
    lbl.SetBounds(8, 8, CAncho - 16, 118);
    lbl.AutoSize := False;
    lbl.Caption := sDescr;
    lbl.Alignment := taCenter;
    lbl.Layout := tlCenter;
    lbl.WordWrap := True;
    lbl.Transparent := False;
    lbl.Color := clWindow;
    lbl.Font.Color := clWindowText;
    PrepararDobleClick(lbl);
    lbl.OnDblClick := TarjetaFotoDblClick;
  end;
  lbl := TLabel.Create(pnl);
  lbl.Parent := pnl;
  lbl.SetBounds(8, 130, CAncho - 16, 38);
  lbl.AutoSize := False;
  lbl.Caption := sArt;
  lbl.Font.Style := [fsBold];
  lbl.Font.Color := clWindowText;
  lbl.WordWrap := True;
  lbl.Transparent := False;
  lbl.Color := clWindow;
  PrepararDobleClick(lbl);
  lbl.OnDblClick := TarjetaFotoDblClick;
  lblStock := TLabel.Create(pnl);
  lblStock.Parent := pnl;
  lblStock.SetBounds(8, 168, CAncho - 16, 62);
  lblStock.AutoSize := False;
  lblStock.Caption := Format(SCaptionColoresTallas,
                             [sColores, sTallas]);
  lblStock.Font.Height := -11;
  lblStock.Font.Color := clWindowText;
  lblStock.WordWrap := True;
  lblStock.Transparent := False;
  lblStock.Color := clWindow;
  PrepararDobleClick(lblStock);
  lblStock.OnDblClick := TarjetaFotoDblClick;
end;

procedure TfrmStockConsulta.TarjetaFotoDblClick(Sender: TObject);
begin
  if Sender is TControl then
    NavegarArticuloRelacionado(TControl(Sender).Hint);
end;

procedure TfrmStockConsulta.NavegarArticuloRelacionado(const ACodArt: string);
begin
  if Trim(ACodArt) <> '' then
    SetArticuloSku(ACodArt, '');
end;

// Pinta el bloque de info de la cabecera (propiedades + tarifas vigentes +
// proveedores). Las propiedades del articulo se listan todas, compactas y
// separadas por " · ". Las tarifas muestran la fila vigente hoy de cada
// tarifa (PVP, VENTA MAYOR…), ordenadas por ORDEN_TAR. Los proveedores van
// con el principal primero. Se ignoran tarifas/proveedores con SKU
// especifico — aqui solo mostramos el dato a nivel de articulo.
procedure TfrmStockConsulta.CargarInfoCabecera;
var
  Info: TInfoCabeceraStock;
begin
  lblInfo.Caption := '';
  if Trim(FCodArt) <> '' then
  begin
    Info := CargarInfoCabeceraStock(
      ConexionPrincipal, FCodArt);
    lblInfo.Caption := FormatearInfoCabeceraStock(
      Info, ParametrosCaja.TarifaDefecto, FVerCoste);
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
// En modo "Todo a la vez" hace UNION ALL de los estados con datos.
// Simplificado: existencias, entradas (total), salidas (total), pte. servir
// y pte. recibir. Desglosado: existencias + pendientes + los subtipos de
// entrada/salida, sin los totales esEntradas/esSalidas (serian redundantes
// con su propio desglose). esPrestadas es stub y siempre devuelve 0.
// ---------------------------------------------------------------------------
//  Build SQL pivote: rows=almacenes o colores, cols=tallas
// ---------------------------------------------------------------------------
// Las TALLAS van SIEMPRE como columnas dinamicas (T0..Tn-1). Las filas son
// almacenes seleccionados en lstAlmacenes (modo Por Almacen) o colores
// seleccionados en lstColores (modo Por Color). El filtro de la dimension
// "no activa" se
// aplica como filtro adicional sobre B:
//   * Por Color  -> almacenes se filtran ya en EstadoBaseSelect.
//   * Por Almacen-> los colores seleccionados se filtran en el JOIN ON.
// HEX viaja en la columna de filas para que el custom-draw del cuadradito
// pinte el swatch en modo Por Color; en Por Almacen queda vacio.
// ---------------------------------------------------------------------------
//  Reconstruir columnas dinamicas del grid
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
//  Tallas del articulo (columnas dinamicas del grid)
// ---------------------------------------------------------------------------
function TfrmStockConsulta.TallasArticulo: TArray<TInfoColumna>;
begin
  SetLength(Result, 0);
  if Trim(FCodArt) <> '' then
    Result := FServiciosPersistencia.Pivote.ListarTallas(
      FCodArt,
      ColoresSeleccionadosLista);
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
  if AEsColor then
    FColGrupo.Caption := SCaptionColColor
  else
    FColGrupo.Caption := SCaptionColAlmacen;
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
    FColEstado.Caption := SCaptionColEstado;
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
  colTotal.Caption := SCaptionColTotal;
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

  if PintarCeldaSwatchSiAplica(ConexionPrincipal, ACanvas, AViewInfo, nil) then
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
  bEsColor: Boolean;
  dim: TDimensionFotos;
  Solicitud: TSolicitudPivoteStock;
  tallas: TArray<TInfoColumna>;
begin
  FDs.DataSet := nil;
  FResultadoPivote := nil;
  if DimensionFotosActiva(dim) then
  begin
    MostrarVistaFotosRelacionadas(True);
    try
      CargarFotosRelacionadasSiProcede;
    except
      on E: Exception do
      begin
        MostrarError(E.Message);
      end;
    end;
  end
  else
  begin
    MostrarVistaFotosRelacionadas(False);
    bEsColor := pcVistas.ActivePage = tsPorColor;
    // Cursor de espera: el pivote en modo "Todos los estados" puede tardar y
    // bloquea el hilo de UI; al menos el usuario ve que esta trabajando y no
    // parece que la ventana se haya colgado.
    Screen.Cursor := crHourGlass;
    try
      try
        if Trim(FCodArt) = '' then
          SetLength(tallas, 0)
        else
          tallas := TallasArticulo;
        ReconstruirColumnas(tallas, bEsColor);
        Solicitud := Default(TSolicitudPivoteStock);
        Solicitud.CodigoArticulo := FCodArt;
        Solicitud.Estado := EstadoActual;
        Solicitud.ModoDesglosado := FModoDesglosado;
        Solicitud.PorColor := bEsColor;
        Solicitud.OcultarCeros := Assigned(ParametrosApp) and
          ParametrosApp.GetBool('appStockOcultarCeros', True);
        Solicitud.Almacenes := AlmacenesSeleccionadosLista;
        Solicitud.Colores := ColoresSeleccionadosLista;
        FResultadoPivote := FServiciosPersistencia.Pivote.Consultar(
          Solicitud,
          tallas);
        FDs.DataSet := FResultadoPivote.DataSet;
      except
        on E: Exception do
        begin
          FDs.DataSet := nil;
          FResultadoPivote := nil;
          // El error sale por encima de la ventana (fsStayOnTop).
          MostrarError(E.Message);
        end;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Busqueda de articulos (popup del boton "...")
// ---------------------------------------------------------------------------
// Lanza el buscador visual inyectado listando los
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
  oResultado: IResultadoConsultaStock;
  q: TDataSet;
begin
  Result := '';
  oResultado := FServiciosPersistencia.Catalogos.BuscarArticulos(
    ParametrosCaja.TarifaDefecto);
  q := oResultado.DataSet;
  try
    ConfigCampo(q.FindField('CODIGO_ART_ART'),  'Código',      '');
    ConfigCampo(q.FindField('DESCRIPCION_ART'), 'Descripción', '');
    ConfigCampo(q.FindField('DESCRIPCION_FAM'), 'Familia',     '');
    ConfigCampo(q.FindField('TEMPORADA'),       'Temporada',   '');
    ConfigCampo(q.FindField('PROVEEDOR'),       'Proveedor',   '');
    ConfigCampo(q.FindField('REF_PROVEEDOR'),   'Ref. proveedor', '');
    ConfigCampo(q.FindField('PRECIO_PVP'),      'PVP',         '#,##0.00 €');

    if BusquedaVisual.EjecutarBusquedaDataSet(
      'Búsqueda de Artículos',
      q,
      'frmMtoArtStockSearch') then
      Result := q.FieldByName('CODIGO_ART_ART').AsString;
  finally
    oResultado := nil;
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
  if (not FActualizandoArticulo) and (Trim(btnArt.Text) = '') then
    SetArticuloSku('', '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(Sender: TObject);
begin
  cbbEstado.Style.TextColor := ColorEstado(EstadoActual);
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstAlmacenesClick(Sender: TObject);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstColoresClick(Sender: TObject);
var
  iColor     : Integer;
  sCodUnidad : string;
begin
  ActualizarLetreroColor;
  sCodUnidad := FCodSku;
  iColor := lstColores.ItemIndex;
  if (iColor >= 0) and (iColor < lstColores.Items.Count) and
     lstColores.Selected[iColor] then
  begin
    // La clave ARTICULO/COLOR permite resolver primero la foto propia del
    // color y recurrir a la foto general del articulo cuando no exista.
    sCodUnidad := FCodArt + '/' + lstColores.Items[iColor];
  end;
  try
    CargarFoto(sCodUnidad);
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcVistasChange(Sender: TObject);
var
  dim: TDimensionFotos;
begin
  if not FSilenciarCambioVista then
  begin
    if DimensionFotosActiva(dim) then
    begin
      FFotosFiltros[dim] := [];
      FFotosCargadas[dim] := False;
    end;
    RecargarConsulta;
  end;
end;

end.
