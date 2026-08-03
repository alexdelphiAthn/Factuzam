{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsulta                                            }
{    Tipo:       Formulario (flotante, fsStayOnTop)                            }
{ Version:       0.8.0                                                         }
{   Fecha:       02/08/2026                                                    }
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
{      - Filtros (pnlFiltros): combo "Estado del stock" + modo.                }
{      - Cuerpo (pnlBody): split horizontal con un TSplitter.                  }
{        * pnlIzq (alLeft, 280px): pcFiltros con las pestanas de colores y     }
{          almacenes (seleccion multiple).                                     }
{        * pnlDer (alClient): pcVistas con las pestanas de pivote (por         }
{          almacenes / por colores) y las de fotos relacionadas, mas el        }
{          TcxGrid compartido.                                                 }
{                                                                              }
{    v0.8: el formulario queda como capa de vista. El estado explicito vive    }
{    en TEstadoVistaStockConsulta y el comportamiento en presentadores:        }
{    entrada por texto y codigo de barras, historial, coincidencias, fotos     }
{    relacionadas, estados/leyenda y rejilla pivote. Los adaptadores de        }
{    persistencia se resuelven una sola vez en la composicion de la pantalla   }
{    (inMtoStockConsultaPresentacionComposicion) y ningun evento vuelve a      }
{    descubrir repositorios.                                                   }
{    v0.7: boton "Op de Caja" para consultar en un modal las operaciones DE,   }
{    DV y VE del SKU seleccionado en una celda de talla.                       }
{    v0.6: letrero de propiedades por color (nivel COLOR / SKU).               }
{    v0.5: estado "Todo a la vez" y colores por estado.                        }
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
  inLibFotos,
  inMtoFrmBase, inLibPermisosIntf,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaPresentacionPropiedades,
  inLibStockConsultaPresentacionVista,
  inMtoStockConsultaPresentacionArticuloVcl,
  inMtoStockConsultaPresentacionComposicion,
  inMtoStockConsultaPresentacionFotosVcl,
  inMtoStockConsultaPresentacionPivoteVcl;

const
  // Detector por velocidad de tecleo (codigo de barras + CR, sin STX/ETX).
  SCAN_VEL_MS   = 40;   // max. ms entre teclas para considerarlo lector
  SCAN_MIN_LONG = 4;    // longitud minima del codigo

type
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
    procedure FormKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure btnArtPropertiesButtonClick(Sender: TObject;
              AButtonIndex: Integer);
    procedure btnArtPropertiesEditValueChanged(Sender: TObject);
    procedure btnOperacionesCajaClick(Sender: TObject);
    procedure cbbEstadoPropertiesEditValueChanged(Sender: TObject);
    procedure lstAlmacenesClick(Sender: TObject);
    procedure lstColoresClick(Sender: TObject);
    procedure pcVistasChange(Sender: TObject);
  private
    FDependencias: TContextoDependenciasStockConsulta;
    FVista: TEstadoVistaStockConsulta;
    FEstados: TPresentadorEstadosStock;
    FPivote: TPresentadorPivoteStock;
    FFotos: TPresentadorFotosRelacionadasStock;
    FHistorial: TPresentadorHistorialStock;
    FCoincidencias: TPresentadorCoincidenciasStock;
    FPropsPorColor: TPropiedadesPorColorStock;
    FPopMenuStock: TPopupMenu;
    FMenuAgregarDoc: TMenuItem;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure LectorCodigoLeido(Sender: TObject;
              const ACodigo: string);
    procedure PopMenuStockPopup(Sender: TObject);
    procedure MenuAgregarDocClick(Sender: TObject);
    procedure CrearPresentadores;
    procedure GuardarModoUsuario;
    function  ModoDesglosadoDeUsuario: Boolean;
    procedure CargarAlmacenes;
    procedure CargarColores;
    procedure CargarPropsPorColor;
    procedure ActualizarLetreroColor;
    procedure AjustarFotoCabecera;
    procedure CargarFoto(const ACodUnidad: string);
    procedure CargarInfoCabecera;
    function  AlmacenesSeleccionadosLista: TArray<string>;
    function  ColoresSeleccionadosLista: TArray<string>;
    function  BuscarArticulo: string;
    function  ResolverCodigoSkuDocumentoTrabajo(
              const AColor, ATalla: string;
              out ACodigoSku, AMensaje: string): Boolean;
    function  ResolverSkuCeldaOperacionesCaja(
              out ACodigoSku, AMensaje: string): Boolean;
    function  ResolverCeldaDocumentoTrabajo(
              out ALinea: TDocTrabajoLineaOrigen;
              out AMensaje: string): Boolean;
    procedure RecargarConsulta;
    procedure MostrarError(const AMsg: string);
    procedure btnArtKeyDown(Sender: TObject; var Key: Word;
              Shift: TShiftState);
    procedure btnArtExit(Sender: TObject);
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
  inLibGenBusq, inLibUser,
  inLibPerfilesUsuarioIntf,
  inLibStockCeldaDocumento,
  inLibStockConsultaInfo,
  inLibStockConsultaEntrada,
  inLibStockConsultaPresentacionPivote,
  inMtoStockConsultaEntradaVcl,
  inMtoModalOperacionesCajaSku, inLibMsgArticulos, inLibMsgCaja,
  inLibMsgComun, inLibMsgVentas,
  inLibDocumentosTrabajoPresentacion;

{$R *.dfm}

const
  CAMPO_ALMACEN_CODIGO = 'CODIGO_ALM_ALM';
  CAMPO_ALMACEN_NOMBRE = 'NOMBRE_ALM_ALM';
  CAMPO_ALMACEN_TIPO_USO = 'TIPO_USO_ALM';
  CAMPO_COLOR_AV = 'AV';
  CAMPO_ES_COLOR_SKU = 'ES_COLOR_SKU';
  SEPARADOR_ALMACEN = ' - ';
  PERFIL_STOCK_CONSULTA = 'frmStockConsulta';
  PERFIL_MODO_DESGLOSADO = 'ModoDesglosado';
  LAYOUT_BUSQUEDA_ARTICULOS = 'frmMtoArtStockSearch';

// Traduce el motivo de bloqueo de la celda a su mensaje. Las reglas viven
// en inLibStockCeldaDocumento; aqui solo se les pone texto.
function MensajeCeldaStock(AMotivo: TMotivoCeldaDocumento): string;
begin
  case AMotivo of
    mcdSinArticulo:
      Result := SErrorArticuloStockNoSeleccionadoDocumento;
    mcdEstadoNoExistencias:
      Result := SErrorEstadoStockNoEsExistencias;
    mcdSinFila:
      Result := SErrorCeldaStockNoSeleccionada;
    mcdSinColumnaCantidad:
      Result := SErrorCeldaCantidadStockNoSeleccionada;
    mcdFilaNoExistencias:
      Result := SErrorFilaExistenciasStockNoSeleccionada;
    mcdColumnaNoValida:
      Result := SErrorColumnaStockDocumentoNoSeleccionada;
    mcdGrupoNoLeido:
      Result := SErrorGrupoFilaStockNoLeido;
    mcdAlmacenNoUnico:
      Result := SErrorAlmacenStockNoUnico;
    mcdColorNoUnico:
      Result := SErrorColorStockUnidadNoUnico;
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

// ---------------------------------------------------------------------------
//  Ciclo de vida
// ---------------------------------------------------------------------------
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
  // Coste (ultimo precio de compra del proveedor) solo para quien tenga
  // permiso: TienePermiso devuelve True siempre a admin; al resto, oculto
  // por defecto salvo permiso explicito 'caja.verCoste'.
  FVista.Limpiar;
  FVista.VerCoste := Assigned(Permisos) and
                     Permisos.TienePermiso(
                       PERMISO_CAJA_VER_COSTE,
                       paDenegar);
  // Unico punto de la pantalla que resuelve adaptadores de persistencia:
  // el resto del contexto de dependencias lo completan el lector y los
  // presentadores.
  FDependencias := CrearContextoStockConsulta(
    Self,
    ConexionPrincipal);
  // Detector del lector. Modo "consumir": las teclas de la rafaga no llegan
  // a btnArt (evita disparar SetArticuloSku en cada tecla del escaneo).
  FDependencias.Lector := TLectorScanner.Create;
  FDependencias.Lector.UmbralMs := SCAN_VEL_MS;
  FDependencias.Lector.LongitudMinima := SCAN_MIN_LONG;
  FDependencias.Lector.ConsumirRafaga := True;
  FDependencias.Lector.OnCodigoLeido := LectorCodigoLeido;
  CrearPresentadores;
  CargarAlmacenes;
  AjustarFotoCabecera;
end;

// Compone los colaboradores de la pantalla en el orden que exige la vista:
// primero la rejilla y la entrada, despues las pestanas de fotos y por
// ultimo el selector de estado, que ya dispara la primera recarga.
procedure TfrmStockConsulta.CrearPresentadores;
var
  Callbacks: TCallbacksVistaEntradaStock;
begin
  FPivote := TPresentadorPivoteStock.Create(
    Self, tvStock, FDependencias.Pivote, ConexionPrincipal);
  Callbacks := Default(TCallbacksVistaEntradaStock);
  Callbacks.AplicarArticulo :=
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      SetArticuloSku(ACodigoArticulo, ACodigoSku);
    end;
  Callbacks.MostrarCoincidencias :=
    procedure(const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string)
    begin
      FCoincidencias.Mostrar(
        ACoincidencias,
        Format(SHintCoincidenciasPara, [AEntrada]));
    end;
  Callbacks.MostrarTextoNoEncontrado :=
    procedure(const AEntrada: string)
    begin
      MostrarError(Format(
        SErrorEntradaStockNoEncontrada, [AEntrada]));
    end;
  Callbacks.MostrarCodigoBarrasNoEncontrado :=
    procedure(const ACodigo: string)
    begin
      MostrarError(Format(
        SErrorCodigoBarrasStockNoEncontrado, [ACodigo]));
    end;
  FDependencias.Entrada := CrearAplicacionEntradaStock(
    CrearRepositorioEntradaStock(FDependencias.Catalogos),
    FDependencias.Validador,
    CrearVistaEntradaStock(Callbacks));
  FPropsPorColor := TPropiedadesPorColorStock.Create;
  FHistorial := TPresentadorHistorialStock.Create(
    Self, pnlCabecera, btnArt,
    SHintArticuloAnterior, SHintArticuloSiguiente,
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      SetArticuloSku(ACodigoArticulo, ACodigoSku);
    end);
  FCoincidencias := TPresentadorCoincidenciasStock.Create(
    Self, pnlCabecera, btnArt,
    procedure(const ACodigoArticulo, ACodigoSku: string)
    begin
      FVista.ResolviendoEntrada := True;
      try
        FCoincidencias.Ocultar;
        SetArticuloSku(ACodigoArticulo, ACodigoSku);
      finally
        FVista.ResolviendoEntrada := False;
      end;
    end,
    function: Boolean
    begin
      Result := FVista.AdmiteSeleccionCoincidencia;
    end);
  btnArt.OnKeyDown := btnArtKeyDown;
  btnArt.OnExit := btnArtExit;
  // Letrero de aviso: oculto por defecto, rojo y en negrita para que "cante"
  // las propiedades propias del color (color/SKU) al pincharlo.
  lblLetreroTemp.Transparent      := False;
  lblLetreroTemp.Style.Color      := $003C3CD8;  // rojo (BGR)
  lblLetreroTemp.Style.TextColor  := clWhite;
  lblLetreroTemp.Style.Font.Style := [fsBold];
  lblLetreroTemp.Style.Font.Color := clWhite;
  lblLetreroTemp.Visible          := False;
  FPopMenuStock := TPopupMenu.Create(Self);
  FPopMenuStock.OnPopup := PopMenuStockPopup;
  FMenuAgregarDoc := TMenuItem.Create(FPopMenuStock);
  FMenuAgregarDoc.Caption := SCaptionAgregarDocumentoTrabajo;
  FMenuAgregarDoc.OnClick := MenuAgregarDocClick;
  FPopMenuStock.Items.Add(FMenuAgregarDoc);
  grdStock.PopupMenu := FPopMenuStock;
  FFotos := TPresentadorFotosRelacionadasStock.Create(
    Self, pcVistas, pnlDer, grdStock,
    SCaptionFotosMismaFamilia, SCaptionFotosMismoProveedor,
    SCaptionFotosMismaTemporada,
    FDependencias.Catalogos, FotosArticulos,
    procedure(const ACodigoArticulo: string)
    begin
      if Trim(ACodigoArticulo) <> '' then
        SetArticuloSku(ACodigoArticulo, '');
    end);
  FEstados := TPresentadorEstadosStock.Create(
    Self, cbbEstado, pnlFiltros, pnlLeyenda, cbbEstado,
    SCaptionModoSimplificado, SCaptionModoDesglosado,
    procedure
    begin
      RecargarConsulta;
    end,
    procedure
    begin
      GuardarModoUsuario;
    end);
  FEstados.AplicarModo(ModoDesglosadoDeUsuario);
  FEstados.MarcarModoEnRadios;
  FEstados.AplicarColorEstadoActual;
  pcVistas.ActivePage := tsPorAlmacen;
  pcFiltros.ActivePage := tsColores;
end;

procedure TfrmStockConsulta.FormDestroy(Sender: TObject);
begin
  if FPivote <> nil then
    FPivote.Limpiar;
  FreeAndNil(FFotos);
  FreeAndNil(FPivote);
  FreeAndNil(FEstados);
  FreeAndNil(FHistorial);
  FreeAndNil(FCoincidencias);
  FreeAndNil(FPropsPorColor);
  FDependencias.Liberar;
end;

procedure TfrmStockConsulta.FormClose(Sender: TObject;
  var Action: TCloseAction);
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
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    if not FCoincidencias.CerrarConEscape then
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

// Resuelve el codigo SOLO contra codigos de barras y carga el articulo/SKU
// en la consulta, igual que al teclear o buscar un articulo.
procedure TfrmStockConsulta.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  if Assigned(FDependencias.Entrada) then
    FDependencias.Entrada.ProcesarCodigoBarras(ACodigo);
end;

// ---------------------------------------------------------------------------
//  Entrada de articulo por texto
// ---------------------------------------------------------------------------
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
  ResolverTextoArticulo(False);
end;

procedure TfrmStockConsulta.ResolverTextoArticulo(AMostrarError: Boolean);
begin
  if FVista.AdmiteResolverEntrada and Assigned(FDependencias.Entrada) then
  begin
    FVista.ResolviendoEntrada := True;
    try
      FDependencias.Entrada.ProcesarTexto(
        btnArt.Text,
        FVista.CodigoArticulo,
        AMostrarError);
    finally
      FVista.ResolviendoEntrada := False;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Menu contextual: agregar la celda a un documento de trabajo
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.PopMenuStockPopup(Sender: TObject);
var
  Linea: TDocTrabajoLineaOrigen;
  sMensaje: string;
begin
  FMenuAgregarDoc.Enabled := ResolverCeldaDocumentoTrabajo(
    Linea, sMensaje);
end;

procedure TfrmStockConsulta.MenuAgregarDocClick(Sender: TObject);
var
  Linea: TDocTrabajoLineaOrigen;
  sMensaje: string;
begin
  if ResolverCeldaDocumentoTrabajo(Linea, sMensaje) then
  begin
    try
      AgregarUnidadADocumentoTrabajo(
        Self,
        ConexionPrincipal,
        FDependencias.DocumentosTrabajo,
        CrearInteraccionDocumentosTrabajoVcl,
        BusquedaVisual,
        ContextoSesion,
        ParametrosCaja,
        Linea,
        FDependencias.ResolverArticulos);
    except
      on E: Exception do
        MostrarError(E.Message);
    end;
  end
  else
  begin
    Application.MessageBox(PChar(sMensaje),
      PChar(STituloDocumentoTrabajo),
      MB_OK or MB_ICONINFORMATION or MB_TOPMOST or MB_SETFOREGROUND);
  end;
end;

function TfrmStockConsulta.ResolverCodigoSkuDocumentoTrabajo(
  const AColor, ATalla: string; out ACodigoSku, AMensaje: string): Boolean;
var
  iCoincidencias: Integer;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  iCoincidencias := FDependencias.Catalogos.ResolverSku(
    FVista.CodigoArticulo,
    AColor,
    ATalla,
    ACodigoSku);
  if iCoincidencias = 1 then
    Result := True
  else if iCoincidencias = 0 then
    AMensaje := SErrorSkuCeldaStockNoEncontrado
  else
    AMensaje := SErrorCeldaStockVariosSkus;
end;

function TfrmStockConsulta.ResolverCeldaDocumentoTrabajo(
  out ALinea: TDocTrabajoLineaOrigen; out AMensaje: string): Boolean;
var
  Estado: TEstadoCeldaStock;
  Celda: TCeldaDocumentoResuelta;
  Linea: TLineaCeldaStock;
  dCantidad: Double;
  bHayCantidad: Boolean;
  sSku: string;
begin
  Result := False;
  ALinea.Clear;
  // Aqui solo se lee el grid; las decisiones (guardas, talla, almacen
  // y color) viven en inLibStockCeldaDocumento.
  Estado := Default(TEstadoCeldaStock);
  Estado.CodigoArticulo := FVista.CodigoArticulo;
  Estado.EstadoEsExistencias := FEstados.EstadoActual = esExistencias;
  Estado.HayColoresEnLista := lstColores.Items.Count > 0;
  Estado.AlmacenesSeleccionados := AlmacenesSeleccionadosLista;
  Estado.ColoresSeleccionados := ColoresSeleccionadosLista;
  FPivote.LeerCeldaEnfocada(Estado);
  Celda := ResolverCeldaStockParaDocumento(Estado);
  AMensaje := MensajeCeldaStock(Celda.Motivo);
  if AMensaje = '' then
  begin
    if ResolverCodigoSkuDocumentoTrabajo(Celda.Color, Celda.Talla,
                                         sSku, AMensaje) then
    begin
      bHayCantidad := FPivote.CantidadEnfocada(dCantidad);
      Linea := ComponerLineaCeldaStock(
        FVista.CodigoArticulo, Celda.Almacen, sSku,
        Celda.Color, Celda.Talla, dCantidad, not bHayCantidad);
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

// ---------------------------------------------------------------------------
//  Operaciones de caja del SKU de la celda enfocada
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ResolverSkuCeldaOperacionesCaja(
  out ACodigoSku, AMensaje: string): Boolean;
var
  Colores: TArray<string>;
  sColor: string;
  sGrupo: string;
  sTalla: string;
begin
  Result := False;
  ACodigoSku := '';
  AMensaje := '';
  sColor := '';
  sTalla := '';
  sGrupo := '';
  if not FVista.HayArticulo then
    AMensaje := SErrorArticuloStockNoSeleccionadoOperaciones
  else if not FPivote.HayFilaEnfocada then
    AMensaje := SErrorCeldaTallaStockNoSeleccionada
  else if not FPivote.HayColumnaEnfocada then
    AMensaje := SErrorCeldaTallaStockNoSeleccionada
  else if not FPivote.TallaEnfocada(sTalla) then
    AMensaje := SErrorColumnaTallaStockNoSeleccionada
  else if not FPivote.GrupoEnfocado(sGrupo) then
    AMensaje := SErrorFilaStockNoIdentificada;
  if AMensaje = '' then
  begin
    if FPivote.EsModoColor then
      sColor := sGrupo
    else
    begin
      // En vista por almacenes la celda solo identifica un SKU si el
      // filtro de colores deja uno solo, o si el articulo no tiene color.
      Colores := ColoresSeleccionadosLista;
      if Length(Colores) = 1 then
        sColor := Colores[0]
      else if (Length(Colores) = 0) and
              (lstColores.Items.Count = 0) then
        sColor := ''
      else
        AMensaje := SErrorColorStockNoUnico;
    end;
  end;
  if AMensaje = '' then
  begin
    Result := ResolverCodigoSkuDocumentoTrabajo(
                sColor, sTalla, ACodigoSku, AMensaje);
    if (not Result) and
       SameText(AMensaje, SErrorCeldaStockVariosSkus) then
      AMensaje := SErrorTallaStockVariosSkus;
  end;
end;

procedure TfrmStockConsulta.btnOperacionesCajaClick(Sender: TObject);
var
  sCodigoSku: string;
  sMensaje: string;
begin
  if ResolverSkuCeldaOperacionesCaja(sCodigoSku, sMensaje) then
    TfrmModalOperacionesCajaSku.Ejecutar(
      Self,
      ConexionPrincipal,
      sCodigoSku,
      lblDescr.Caption)
  else
    Application.MessageBox(
      PChar(sMensaje),
      PChar(STituloOperacionesCajaStock),
      MB_OK or MB_ICONINFORMATION or MB_TOPMOST or MB_SETFOREGROUND);
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
//  Perfil de usuario: modo simplificado / desglosado
// ---------------------------------------------------------------------------
function TfrmStockConsulta.ModoDesglosadoDeUsuario: Boolean;
var
  Perfil: TProfileDicc;
begin
  Perfil := nil;
  try
    GetFormUserProfile(Perfil, PERFIL_STOCK_CONSULTA,
                       IdentidadSesion.Usuario,
                       IdentidadSesion.Grupo,
                       PerfilesLectura);
    Result := SameText(
      GetPerfilValueDef(Perfil, PERFIL_MODO_DESGLOSADO, 'N'), 'S');
  finally
    if Perfil <> nil then
      FreeAndNil(Perfil);
  end;
end;

procedure TfrmStockConsulta.GuardarModoUsuario;
begin
  if Assigned(PerfilesEscritura) then
    PerfilesEscritura.GrabarPerfil(
      IdentidadSesion.Usuario,
      PERFIL_STOCK_CONSULTA,
      PERFIL_MODO_DESGLOSADO,
      IfThen(FEstados.ModoDesglosado, 'S', 'N'));
end;

// ---------------------------------------------------------------------------
//  Almacenes y colores (listas de seleccion multiple)
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.CargarAlmacenes;
var
  bEstandar: Boolean;
  iItem: Integer;
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  lstAlmacenes.Items.Clear;
  Resultado := FDependencias.Catalogos.ConsultarAlmacenes;
  Datos := Resultado.DataSet;
  try
    while not Datos.Eof do
    begin
      iItem := lstAlmacenes.Items.Add(
        Datos.FieldByName(CAMPO_ALMACEN_CODIGO).AsString +
        SEPARADOR_ALMACEN +
        Datos.FieldByName(CAMPO_ALMACEN_NOMBRE).AsString);
      bEstandar :=
        (Datos.FieldByName(CAMPO_ALMACEN_TIPO_USO).AsString =
         'ESTANDAR') or
        (Datos.FieldByName(CAMPO_ALMACEN_TIPO_USO).AsString =
         'ESTANDARD');
      lstAlmacenes.Selected[iItem] := bEstandar;
      Datos.Next;
    end;
  finally
    Resultado := nil;
  end;
end;

function TfrmStockConsulta.AlmacenesSeleccionadosLista: TArray<string>;
var
  i: Integer;
  iSeparador: Integer;
  sItem: string;
  sCodigo: string;
begin
  SetLength(Result, 0);
  for i := 0 to lstAlmacenes.Items.Count - 1 do
    if lstAlmacenes.Selected[i] then
    begin
      sItem := lstAlmacenes.Items[i];
      iSeparador := Pos(SEPARADOR_ALMACEN, sItem);
      if iSeparador > 0 then
        sCodigo := Copy(sItem, 1, iSeparador - 1)
      else
        sCodigo := sItem;
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := sCodigo;
    end;
end;

// Carga los AVs distintos de color (ID_VA_AV='CO') que aparecen en los SKUs
// activos del articulo. Si la entrada resolvio un SKU concreto, se selecciona
// solo su color; el usuario puede anadir despues los demas. Sin SKU o si este
// no permite resolver un color, se seleccionan todos.
procedure TfrmStockConsulta.CargarColores;
var
  i: Integer;
  iItem: Integer;
  bFiltrarPorSku: Boolean;
  bEsColorSku: Boolean;
  bColorSkuEncontrado: Boolean;
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  lstColores.Items.Clear;
  if FVista.HayArticulo then
  begin
    bFiltrarPorSku := Trim(FVista.CodigoSku) <> '';
    bColorSkuEncontrado := False;
    Resultado := FDependencias.Catalogos.ConsultarColores(
      FVista.CodigoArticulo,
      FVista.CodigoSku);
    Datos := Resultado.DataSet;
    try
      while not Datos.Eof do
      begin
        iItem := lstColores.Items.Add(
          Datos.FieldByName(CAMPO_COLOR_AV).AsString);
        bEsColorSku := bFiltrarPorSku and
          (Datos.FieldByName(CAMPO_ES_COLOR_SKU).AsInteger = 1);
        lstColores.Selected[iItem] :=
          (not bFiltrarPorSku) or bEsColorSku;
        if bEsColorSku then
          bColorSkuEncontrado := True;
        Datos.Next;
      end;
      if bFiltrarPorSku and (not bColorSkuEncontrado) then
      begin
        for i := 0 to lstColores.Items.Count - 1 do
          lstColores.Selected[i] := True;
      end;
    finally
      Resultado := nil;
    end;
  end;
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
//  Propiedades propias por color (nivel COLOR / SKU)
// ---------------------------------------------------------------------------
// Las propiedades admiten nivel COLOR y SKU (propiedades_por_unidad.md). El
// filtrado y el formato viven en inLibStockConsultaPresentacionPropiedades;
// aqui solo se traduce el dataset a registros de dominio.
procedure TfrmStockConsulta.CargarPropsPorColor;
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
  Propiedad: TPropiedadColorStock;
begin
  FPropsPorColor.Limpiar;
  if FVista.HayArticulo then
  begin
    Resultado := FDependencias.Catalogos.ConsultarPropiedadesPorColor(
      FVista.CodigoArticulo);
    Datos := Resultado.DataSet;
    try
      while not Datos.Eof do
      begin
        Propiedad := Default(TPropiedadColorStock);
        Propiedad.Color := Datos.FieldByName('COLOR').AsString;
        Propiedad.Nombre := Datos.FieldByName('NOMBRE').AsString;
        Propiedad.Nivel := Datos.FieldByName('NIVEL').AsString;
        Propiedad.TipoValor := Datos.FieldByName('TIPO').AsString;
        Propiedad.ValorLista := Datos.FieldByName('PVTXT').AsString;
        Propiedad.ValorLibre := Datos.FieldByName('VLIBRE').AsString;
        Propiedad.ValorListaArticulo :=
          Datos.FieldByName('PVA').AsString;
        Propiedad.ValorLibreArticulo :=
          Datos.FieldByName('VLIBRE_ART').AsString;
        FPropsPorColor.Agregar(Propiedad);
        Datos.Next;
      end;
    finally
      Resultado := nil;
    end;
  end;
end;

// Recompone el letrero para el color sobre el que se acaba de pinchar: si
// tiene propiedades propias distintas a las del articulo, las "canta"; si
// no, oculta el letrero.
procedure TfrmStockConsulta.ActualizarLetreroColor;
var
  iSeleccion: Integer;
  sColor: string;
begin
  if (FPropsPorColor <> nil) and (lblLetreroTemp <> nil) then
  begin
    sColor := '';
    iSeleccion := lstColores.ItemIndex;
    if (iSeleccion >= 0) and (iSeleccion < lstColores.Items.Count) then
      sColor := lstColores.Items[iSeleccion];
    if (sColor <> '') and FPropsPorColor.TieneColor(sColor) then
    begin
      lblLetreroTemp.Caption := LetreroPropiedadesColorStock(
        sColor, FPropsPorColor.TextoDe(sColor));
      lblLetreroTemp.Visible := True;
    end
    else
    begin
      lblLetreroTemp.Caption := '';
      lblLetreroTemp.Visible := False;
    end;
    AjustarFotoCabecera;
  end;
end;

// ---------------------------------------------------------------------------
//  Carga de articulo / SKU + foto + info de cabecera
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.SetArticuloSku(const ACodArt, ACodSku: string);
var
  sDescripcion: string;
  Dimension: TDimensionFotos;
  bArticuloEncontrado: Boolean;
begin
  FVista.FijarArticulo(ACodArt, ACodSku);
  FVista.ActualizandoArticulo := True;
  try
    btnArt.Text := ACodArt;
  finally
    FVista.ActualizandoArticulo := False;
  end;
  FCoincidencias.Ocultar;
  FFotos.FijarArticulo(ACodArt);
  bArticuloEncontrado := False;
  // Cambiar de articulo con una pestana de fotos activa devuelve la vista
  // al pivote, que es lo que el usuario espera ver del articulo nuevo.
  if FFotos.DimensionActiva(Dimension) then
  begin
    FVista.SilenciandoCambioVista := True;
    try
      pcVistas.ActivePage := tsPorAlmacen;
    finally
      FVista.SilenciandoCambioVista := False;
    end;
  end;
  lblDescr.Caption := '';
  if FVista.HayArticulo then
  begin
    bArticuloEncontrado :=
      FDependencias.Catalogos.ObtenerDescripcionArticulo(
        ACodArt, sDescripcion);
    if bArticuloEncontrado then
      lblDescr.Caption := sDescripcion;
  end;
  // Errores de carga (foto / cabecera / colores) por encima de la ventana.
  try
    CargarFoto(FVista.CodigoSku);
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
    FHistorial.Registrar(ACodArt);
  FHistorial.ActualizarBotones;
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

// En la consulta de stock la foto dispone de una zona amplia: se carga
// siempre la copia a resolucion real y se ajusta proporcionalmente.
procedure TfrmStockConsulta.CargarFoto(const ACodUnidad: string);
var
  Info: TFotoInfo;
  sRuta: string;
  Png: TPngImage;
begin
  imgFoto.Picture.Assign(nil);
  if FVista.HayArticulo then
  begin
    Info := FotosArticulos.Resolver(FVista.CodigoArticulo, ACodUnidad);
    sRuta := FotosArticulos.RutaFoto(Info, frReal);
    if sRuta <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.LoadFromFile(sRuta);
        imgFoto.Picture.Assign(Png);
      finally
        FreeAndNil(Png);
      end;
    end;
  end;
end;

// Bloque de info de la cabecera (propiedades + tarifas vigentes +
// proveedores). El formato lo decide inLibStockConsultaInfo.
procedure TfrmStockConsulta.CargarInfoCabecera;
begin
  lblInfo.Caption := '';
  if FVista.HayArticulo then
    lblInfo.Caption := FormatearInfoCabeceraStock(
      FDependencias.InfoCabecera.Cargar(FVista.CodigoArticulo),
      ParametrosCaja.TarifaDefecto,
      FVista.VerCoste);
end;

// ---------------------------------------------------------------------------
//  Recarga del pivote
// ---------------------------------------------------------------------------
procedure TfrmStockConsulta.RecargarConsulta;
var
  bPorColor: Boolean;
  Dimension: TDimensionFotos;
  Solicitud: TSolicitudPivoteStock;
  Tallas: TArray<TInfoColumna>;
begin
  FPivote.Limpiar;
  if FFotos.DimensionActiva(Dimension) then
  begin
    FFotos.MostrarVista(True);
    try
      FFotos.CargarSiProcede;
    except
      on E: Exception do
        MostrarError(E.Message);
    end;
  end
  else
  begin
    FFotos.MostrarVista(False);
    bPorColor := pcVistas.ActivePage = tsPorColor;
    // Cursor de espera: el pivote en modo "Todos los estados" puede tardar y
    // bloquea el hilo de UI; al menos el usuario ve que esta trabajando.
    Screen.Cursor := crHourGlass;
    try
      try
        SetLength(Tallas, 0);
        if FVista.HayArticulo then
          Tallas := FPivote.ListarTallas(
            FVista.CodigoArticulo, ColoresSeleccionadosLista);
        FPivote.ReconstruirColumnas(
          Tallas, bPorColor, FEstados.EstadoActual);
        Solicitud := ComponerSolicitudPivoteStock(
          FVista.CodigoArticulo,
          FEstados.EstadoActual,
          FEstados.ModoDesglosado,
          bPorColor,
          Assigned(ParametrosApp) and
            ParametrosApp.GetBool('appStockOcultarCeros', True),
          AlmacenesSeleccionadosLista,
          ColoresSeleccionadosLista);
        FPivote.Consultar(Solicitud, Tallas);
      except
        on E: Exception do
        begin
          // El error sale por encima de la ventana (fsStayOnTop).
          FPivote.Limpiar;
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
// Lanza el buscador visual inyectado con las columnas Codigo / Descripcion /
// Familia / Temporada / Proveedor ppal. / PVP. Layout persistido bajo el
// Name 'frmMtoArtStockSearch' (independiente del de caja).
function TfrmStockConsulta.BuscarArticulo: string;
  procedure ConfigCampo(ACampo: TField; const ATitulo, AFormato: string);
  begin
    if ACampo <> nil then
    begin
      if ATitulo <> '' then
        ACampo.DisplayLabel := ATitulo;
      if AFormato <> '' then
      begin
        if ACampo is TFloatField then
          TFloatField(ACampo).DisplayFormat := AFormato
        else if ACampo is TBCDField then
          TBCDField(ACampo).DisplayFormat := AFormato
        else if ACampo is TFMTBCDField then
          TFMTBCDField(ACampo).DisplayFormat := AFormato;
      end;
    end;
  end;
var
  Resultado: IResultadoConsultaStock;
  Datos: TDataSet;
begin
  Result := '';
  Resultado := FDependencias.Catalogos.BuscarArticulos(
    ParametrosCaja.TarifaDefecto);
  Datos := Resultado.DataSet;
  try
    ConfigCampo(Datos.FindField('CODIGO_ART_ART'),  'Código',      '');
    ConfigCampo(Datos.FindField('DESCRIPCION_ART'), 'Descripción', '');
    ConfigCampo(Datos.FindField('DESCRIPCION_FAM'), 'Familia',     '');
    ConfigCampo(Datos.FindField('TEMPORADA'),       'Temporada',   '');
    ConfigCampo(Datos.FindField('PROVEEDOR'),       'Proveedor',   '');
    ConfigCampo(Datos.FindField('REF_PROVEEDOR'),   'Ref. proveedor', '');
    ConfigCampo(Datos.FindField('PRECIO_PVP'),      'PVP', '#,##0.00 €');
    if BusquedaVisual.EjecutarBusquedaDataSet(
      'Búsqueda de Artículos',
      Datos,
      LAYOUT_BUSQUEDA_ARTICULOS) then
      Result := Datos.FieldByName('CODIGO_ART_ART').AsString;
  finally
    Resultado := nil;
  end;
end;

// ---------------------------------------------------------------------------
//  Eventos de la vista
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

procedure TfrmStockConsulta.btnArtPropertiesEditValueChanged(
  Sender: TObject);
begin
  if FVista.AdmiteCambioTextoArticulo and (Trim(btnArt.Text) = '') then
    SetArticuloSku('', '');
end;

procedure TfrmStockConsulta.cbbEstadoPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEstados.AplicarColorEstadoActual;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstAlmacenesClick(Sender: TObject);
begin
  RecargarConsulta;
end;

procedure TfrmStockConsulta.lstColoresClick(Sender: TObject);
var
  iColor: Integer;
  sCodUnidad: string;
begin
  ActualizarLetreroColor;
  sCodUnidad := FVista.CodigoSku;
  iColor := lstColores.ItemIndex;
  // La clave ARTICULO/COLOR permite resolver primero la foto propia del
  // color y recurrir a la foto general del articulo cuando no exista.
  if (iColor >= 0) and (iColor < lstColores.Items.Count) and
     lstColores.Selected[iColor] then
    sCodUnidad := FVista.ClaveUnidadColor(lstColores.Items[iColor]);
  try
    CargarFoto(sCodUnidad);
  except
    on E: Exception do
      MostrarError(E.Message);
  end;
  RecargarConsulta;
end;

procedure TfrmStockConsulta.pcVistasChange(Sender: TObject);
begin
  if FVista.AdmiteCambioVista then
  begin
    FFotos.ReiniciarDimensionActiva;
    RecargarConsulta;
  end;
end;

end.
