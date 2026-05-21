{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPruebaSesionGrid                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       0.2.0                                                         }
{   Fecha:       18/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Prueba 01 de la serie pruebas_sesiones: variante simplificada del Mto de  }
{    sesiones de compra con edicion INLINE de cantidades por talla.            }
{                                                                              }
{      - Cabecera: Empresa, Proveedor, Tarifa venta, Margen,                   }
{        Multiplo redondeo, Ajuste final.                                      }
{      - Una linea = un articulo. Columnas: Familia (F3 -> picker),            }
{        Codigo articulo (auto familia+contador), Descripcion, Color           }
{        (libre), Color basico (selector paleta), Pr. compra,                  }
{        Pr. venta (propuesto al teclear coste), Sistema tallas,               }
{        N columnas TALLA inline, Total tallas, Importe s/IVA.                 }
{                                                                              }
{    Las columnas TALLA son no-bound: su valor vive en                         }
{    tvLineas.DataController.Values y se sincroniza con                        }
{    fza_compras_sesiones_celdas via SQL. El numero de columnas visibles       }
{    = max valores entre los conjuntos referenciados en la sesion.             }
{    Los rotulos (captions) reflejan el sistema de la linea con foco.          }
{                                                                              }
{    Reutiliza:                                                                }
{      - TdmComprasSesiones (mapeado en fza_winforms).                         }
{      - inLibComprasSesiones.ResolverCodigoFamilia (atajo familia->codigo).   }
{      - inLibComprasSesiones.CalcularPrecioVenta (PVP propuesto).             }
{      - inLibAtributosPaleta.SeleccionarAvConPaleta (selector color           }
{        basico, mismo combo que el grid de inventarios).                      }
{      - TfrmModalSelFamilia (picker jerarquico, tecla F3).                    }
{                                                                              }
{    Documentado en                                                            }
{    DESARROLLOS EN CURSO/pruebas_sesiones/pruebas_sesiones.md.                }
{******************************************************************************}
unit inMtoPruebaSesionGrid;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.UITypes, System.Actions,
  Vcl.ActnList, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  cxClasses, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxDBEdit, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid, cxPC,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  cxDBNavigator, cxMemo, cxCheckBox, cxGroupBox, cxLocalization, cxGraphics,
  cxButtonEdit,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoGen,
  inLibGridTallasInline,
  UniDataComprasSesiones, cxBlobEdit, dxShellDialogs, cxRadioGroup, Vcl.Buttons,
  dxDateRanges;

const
  // Numero maximo de columnas de talla inline. Subido a 20 a peticion
  // de un cliente con sistemas extensos (rangos de calzado largos,
  // tallas internacionales niño+adulto, etc.).
  CANT_TALLAS_MAX = 20;

type
  // Los tipos TPosConjunto / TArrPosConjunto viven ahora en
  // inLibGridTallasInline (compartidos con futuros Mtos de Pedidos
  // / Albaranes / Facturas que reusen el patron).

  TfrmMtoPruebaSesionGrid = class(TfrmMtoGen)
    // ------------------------------------------------------------------
    // Columnas grid lista (tsLista, heredada)
    // ------------------------------------------------------------------
    dbcSerieSes              : TcxGridDBColumn;
    dbcNumeroSes             : TcxGridDBColumn;
    dbcFechaSes              : TcxGridDBColumn;
    dbcEstadoSes             : TcxGridDBColumn;
    dbcCodigoEmpSes          : TcxGridDBColumn;
    dbcCodigoPrvSes          : TcxGridDBColumn;
    dbcCodigoTarSes          : TcxGridDBColumn;
    dbcUsuarioAltaSes        : TcxGridDBColumn;

    // ------------------------------------------------------------------
    // Ficha — cabecera (settings)
    // ------------------------------------------------------------------
    gbCabecera               : TcxGroupBox;
    lblSerie                 : TcxLabel;
    txtSerie                 : TcxDBTextEdit;
    lblNumero                : TcxLabel;
    txtNumero                : TcxDBTextEdit;
    lblEstado                : TcxLabel;
    txtEstado                : TcxDBTextEdit;
    lblEmpresa               : TcxLabel;
    cbbEmpresa               : TcxDBLookupComboBox;
    lblProveedor             : TcxLabel;
    cbbProveedor             : TcxDBLookupComboBox;
    lblTarifa                : TcxLabel;
    cbbTarifa                : TcxDBLookupComboBox;
    lblMargen                : TcxLabel;
    spnMargen                : TcxDBSpinEdit;
    lblMultiploRedondeo      : TcxLabel;
    spnMultiploRedondeo      : TcxDBSpinEdit;
    lblAjusteFinal           : TcxLabel;
    spnAjusteFinal           : TcxDBSpinEdit;

    // ------------------------------------------------------------------
    // Ficha — botones de linea
    // ------------------------------------------------------------------
    pnlLineasTop             : TPanel;
    btnAddLinea              : TcxButton;
    btnDelLinea              : TcxButton;
    btnNuevoColor            : TcxButton;
    lblHint                  : TcxLabel;

    // ------------------------------------------------------------------
    // Ficha — grid de lineas con tallas inline
    // ------------------------------------------------------------------
    cxgrdLineas              : TcxGrid;
    tvLineas                 : TcxGridDBTableView;
    glLineas                 : TcxGridLevel;
    dbcLinFamilia            : TcxGridDBColumn;
    dbcLinCodArt             : TcxGridDBColumn;
    dbcLinRefPrv             : TcxGridDBColumn;
    dbcLinDescripcion        : TcxGridDBColumn;
    dbcLinColor              : TcxGridDBColumn;
    dbcLinColorBasico        : TcxGridDBColumn;
    dbcLinPrecioCompra       : TcxGridDBColumn;
    dbcLinPrecioVenta        : TcxGridDBColumn;
    dbcLinTallas             : TcxGridDBColumn;
    // dbcLinTalla01..15 se crean en runtime en FormCreate; ver
    // FTallaColumns. Mantenerlas en el DFM no aporta porque hay que
    // reconfigurarlas igualmente (Tag, Caption, OnEditValueChanged,
    // Properties).
    dbcLinTotalTallas        : TcxGridDBColumn;
    dbcLinImporteTotal       : TcxGridDBColumn;
    dbcLinNumero             : TcxGridDBColumn;

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
    procedure btnNuevoColorClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure tvLineasEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure dbcLinColorBasicoPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure dbcLinPrecioCompraPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinTallasPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinFamiliaPropertiesEditValueChanged(Sender: TObject);
    procedure cxgrdLineasEnter(Sender: TObject);
    procedure cxgrdLineasExit(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
  private
    FGestorTallas : TGestorGridTallas;     // mueve toda la logica reusable
                                           // de tallas pivotadas a la lib
    FTallaColumns : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FBasicosColor : TArray<string>;
    FQryConjuntosTallas : TUniQuery;
    FDsConjuntosTallas  : TDataSource;
    FBmpSwatch    : TBitmap;
    function  Dmm: TdmComprasSesiones;
    procedure CargarBasicosColor;
    procedure CrearColumnasTallas;
    procedure InicializarGestorTallas;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure unqrySesionLinAfterPostHook(DataSet: TDataSet);
    procedure ExpandirCodigoFamiliaActiva(const ACodigoFam: string;
                const ANombreFam: string = '');
    procedure ProponerPrecioVenta;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoPruebaSesionGrid: TfrmMtoPruebaSesionGrid;

implementation

uses
  inLibGlobalVar,
  inLibUser,
  inLibComprasSesiones,
  inLibAtributosPaleta,
  inMtoModalSelFamilia,
  inMtoModalImpSesion;

const
  fIdVaColor = 'CO';

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// ===========================================================================
//   TJvEnterAsTab — apagar mientras el grid tiene foco
// ===========================================================================
// TJvEnterAsTab heredado de TfrmBase convierte VK_RETURN en VK_TAB a nivel
// de mensaje. Lo apagamos al entrar al grid y reactivamos al salir, asi
// Enter navega celda a celda (combinado con FocusCellOnTab del grid).
// La logica vive en inLibGridTallasInline.ActivarEnterComoTab — funciona
// igual para cualquier Mto que use el patron.

procedure TfrmMtoPruebaSesionGrid.cxgrdLineasEnter(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, False);
end;

procedure TfrmMtoPruebaSesionGrid.cxgrdLineasExit(Sender: TObject);
begin
  inherited;
  inLibGridTallasInline.ActivarEnterComoTab(Self, True);
end;

procedure TfrmMtoPruebaSesionGrid.btnGrabarClick(Sender: TObject);
begin
  inherited;
  // Tras Grabar, cxGrid limpia los Values[] no-bound al redibujar el
  // row (los Posts del master/detail provocan re-fetch). Recargamos
  // las cantidades desde la tabla de celdas para que las celdas
  // talla vuelvan a mostrar lo que el usuario tecleo.
  if Assigned(FGestorTallas) then FGestorTallas.CargarCantidadesTodasLineas;
end;

// ===========================================================================
//   Bootstrapping
// ===========================================================================

function TfrmMtoPruebaSesionGrid.Dmm: TdmComprasSesiones;
begin
  Result := tdmDataModule as TdmComprasSesiones;
end;

procedure TfrmMtoPruebaSesionGrid.CrearTablaPrincipal;
begin
  inherited;
  if tdmDataModule = nil then Exit;
  pkFieldName := 'SERIE_SES;NUMERO_SES';

  cbbEmpresa.Properties.ListSource   := Dmm.dsEmpresas;
  cbbProveedor.Properties.ListSource := Dmm.dsProveedores;
  cbbTarifa.Properties.ListSource    := Dmm.dsTarifas;

  TcxLookupComboBoxProperties(dbcLinTallas.Properties).ListSource :=
                                                    FDsConjuntosTallas;

  with Dmm do
  begin
    unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesionLin.MasterSource := dsTablaG;
    // Hook AfterPost: cuando el usuario cambia de fila el dataset
    // hace Post automatico y cxGrid repinta la fila desde el dataset,
    // limpiando los Values[] no-bound. Re-publicamos las cantidades
    // de todas las lineas desde la cache de SESCEL.
    unqrySesionLin.AfterPost := unqrySesionLinAfterPostHook;
    if not unqrySesionLin.Active then unqrySesionLin.Open;
    if not unqrySesionCel.Active then unqrySesionCel.Open;
  end;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;

  InicializarGestorTallas;

  // Hook OnDataChange del master: cuando el usuario navega de una
  // sesion a otra (o se posiciona en la primera tras abrir el form),
  // re-cargamos las cantidades de tallas. Sin esto, las celdas no-bound
  // quedan vacias hasta que se Postea una linea, aunque los totales
  // (TOTAL_UNIDADES_SESLIN, bound) si se ven correctos.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;

  if Assigned(FGestorTallas) then
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.CargarCantidadesTodasLineas;
    // RecalcularMaxColumnas resetea los captions a "Talla N" generico.
    // Sin esta llamada, al abrir el form los rotulos se quedan asi hasta
    // que el usuario navega a una linea — la primera con foco no dispara
    // OnFocusedRecordChanged en algunos casos (master abierto antes de
    // cablear el hook, detail vacio, etc.). Forzamos el repintado al
    // sistema de la linea actual aqui.
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoPruebaSesionGrid.dsTablaGDataChangeHook(Sender: TObject;
                                                          Field: TField);
begin
  // Field = nil => cambio de record activo en el master (no es un cambio
  // puntual de un campo del registro actual). Es el momento de
  // recalcular columnas y volver a publicar las cantidades de las
  // lineas de esta sesion.
  if Field <> nil then Exit;
  if FGestorTallas = nil then Exit;
  FGestorTallas.InvalidarCache;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.CargarCantidadesTodasLineas;
  // Igual que en CrearTablaPrincipal: RecalcularMaxColumnas deja los
  // captions en "Talla N"; al navegar a otra sesion en el master el
  // OnFocusedRecordChanged del detail no siempre se dispara, asi que
  // refrescamos los rotulos al sistema de la linea activa.
  FGestorTallas.ActualizarCaptionsLineaActiva;
end;

procedure TfrmMtoPruebaSesionGrid.unqrySesionLinAfterPostHook(
                                                      DataSet: TDataSet);
begin
  // Cuando el usuario cambia de fila el dataset hace Post automatico:
  // cxGrid reacciona repintando la fila desde el dataset y eso borra
  // los Values[] no-bound (tallas) de la fila que abandona. Re-cargamos
  // las cantidades de todas las lineas desde SESCEL — el SELECT
  // agregado es barato y el BeginUpdate/EndUpdate del DataController
  // lo deja en una sola pasada.
  if Assigned(FGestorTallas) then
    FGestorTallas.CargarCantidadesTodasLineas;
end;

procedure TfrmMtoPruebaSesionGrid.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoPruebaSesionGrid.FormCreate(Sender: TObject);
begin
  // OJO: TODO lo que vaya a usar el `inherited` (que ejecuta
  // ProcesarPerfiles -> CrearTablaPrincipal -> abre unqrySesionLin -> el
  // grid dispara OnFocusedRecordChanged sobre el gestor de tallas) tiene
  // que estar creado ANTES del inherited.
  FBmpSwatch := TBitmap.Create;
  // Query propia del lookup "Sistema tallas": solo conjuntos del
  // atributo pivot (ID_VA_AC = 'TAL'), no colores ni otros ejes. Trae
  // ademas primera y ultima talla (ordenadas por ORDEN_ACD) para
  // mostrarlas como rango en el dropdown.
  FQryConjuntosTallas := TUniQuery.Create(Self);
  FQryConjuntosTallas.Connection := inLibGlobalVar.oConn;
  FQryConjuntosTallas.SQL.Text :=
    'SELECT AC.ID_AC, AC.NOMBRE_AC, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD, AV.AV LIMIT 1) AS PRIMERA, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD DESC, AV.AV DESC LIMIT 1) AS ULTIMA ' +
    '  FROM fza_atributos_conjuntos AC ' +
    ' WHERE AC.ESACTIVO_AC = ''S'' ' +
    '   AND AC.ID_VA_AC = ''TAL'' ' +
    ' ORDER BY AC.NOMBRE_AC';
  FQryConjuntosTallas.Open;
  FDsConjuntosTallas := TDataSource.Create(Self);
  FDsConjuntosTallas.DataSet := FQryConjuntosTallas;

  // CrearColumnasTallas debe correr antes de inherited (CrearTablaPrincipal,
  // lanzada desde inherited, llama a RecalcularMaxColumnas y
  // CargarCantidadesTodasLineas del gestor; si las columnas no existen
  // todavia ambos son no-op).
  CrearColumnasTallas;

  inherited;

  CargarBasicosColor;
end;

procedure TfrmMtoPruebaSesionGrid.FormDestroy(Sender: TObject);
begin
  // Cerrar la query del lookup y soltar la connection ANTES del
  // inherited: TfrmMtoGen.FormDestroy libera el DataModule y, por
  // los caminos de UniDAC, la oConn global puede quedar en estado
  // 'not connected' antes de que esta query (Owner=Self) sea
  // destruida automaticamente al final del proceso. Si la
  // destrucion automatica encuentra Active=True intenta cerrar el
  // cursor contra una conexion ya inactiva -> "Connection is not
  // connected".
  if Assigned(FQryConjuntosTallas) then
  begin
    try
      if FQryConjuntosTallas.Active then FQryConjuntosTallas.Close;
    except
      // Si la conexion ya cayo no podemos hacer nada util aqui.
    end;
    FQryConjuntosTallas.Connection := nil;
    FreeAndNil(FQryConjuntosTallas);
  end;
  FreeAndNil(FDsConjuntosTallas);
  FreeAndNil(FGestorTallas);
  FreeAndNil(FBmpSwatch);
  inherited;
end;

procedure TfrmMtoPruebaSesionGrid.CargarBasicosColor;
var
  q : TUniQuery;
  i : Integer;
begin
  SetLength(FBasicosColor, 0);
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
      ' WHERE ID_VA_ATB = :va AND ESACTIVO_ATB = ''S'' ' +
      ' ORDER BY ORDEN_ATB, NOMBRE_ATB';
    q.ParamByName('va').AsString := fIdVaColor;
    q.Open;
    SetLength(FBasicosColor, q.RecordCount);
    i := 0;
    while not q.Eof do
    begin
      FBasicosColor[i] := q.FieldByName('CODIGO_ATB').AsString;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

// ===========================================================================
//   Creacion y cache de columnas de talla
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.CrearColumnasTallas;
var
  i        : Integer;
  col      : TcxGridDBColumn;
  curProps : TcxCurrencyEditProperties;
  idxRefe  : Integer;
begin
  // Inserta CANT_TALLAS_MAX columnas no-bound entre dbcLinTallas (sistema
  // de tallas) y dbcLinTotalTallas. Cada columna persiste su valor en el
  // DataController.Values del cxGrid; cuando el usuario teclea, el
  // OnEditValueChanged delega en FGestorTallas.PersistirCeldaActiva,
  // que upsertea en la tabla de celdas y refresca totales.
  if not Assigned(dbcLinTotalTallas) then Exit;
  idxRefe := dbcLinTotalTallas.Index;
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    col := tvLineas.CreateColumn;
    col.Name        := 'dbcLinTalla' + Format('%.2d', [i + 1]);
    col.Index       := idxRefe + i;
    col.Caption     := '';
    col.Width       := 50;
    col.Tag         := i + 1;             // posicion 1..CANT_TALLAS_MAX
    col.Visible     := False;             // se hara visible segun max
    col.DataBinding.ValueTypeClass := TcxFloatValueType;
    col.PropertiesClass := TcxCurrencyEditProperties;
    curProps := TcxCurrencyEditProperties(col.Properties);
    curProps.DisplayFormat := '#,##0';
    // El handler se asigna en InicializarGestorTallas (necesita la
    // instancia del gestor para delegar). Aqui solo dejamos las
    // columnas listas con su Tag posicional.
    FTallaColumns[i] := col;
  end;
end;

procedure TfrmMtoPruebaSesionGrid.InicializarGestorTallas;
var
  cfg     : TGridTallasConfig;
  i       : Integer;
  arrCols : TArray<TcxGridDBColumn>;
begin
  // Cablea el gestor de tallas pivotadas (libreria reutilizable) con
  // los nombres de tabla/campos especificos de Sesiones de compra.
  // Si en el futuro se reusa este patron para Pedidos / Albaranes /
  // Facturas, basta crear otro form con los sufijos PEDLIN/PEDCEL,
  // ALBLIN/ALBCEL, etc. y la libreria hace lo mismo sin cambios.
  if FGestorTallas <> nil then FreeAndNil(FGestorTallas);
  if Dmm = nil then Exit;

  SetLength(arrCols, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
    arrCols[i] := FTallaColumns[i];

  cfg := Default(TGridTallasConfig);
  cfg.Conexion           := inLibGlobalVar.oConn;
  cfg.Usuario            := oUser;
  cfg.Grid               := tvLineas;
  cfg.SourceMaster       := dsTablaG;
  cfg.SourceLineas       := Dmm.dsSesionLin;
  cfg.ColumnasTallas     := arrCols;
  cfg.FieldSerieMaster   := 'SERIE_SES';
  cfg.FieldNumeroMaster  := 'NUMERO_SES';
  cfg.FieldLinea         := 'LINEA_SESLIN';
  cfg.FieldConjuntoPivot := 'ID_AC_PIVOT_SESLIN';
  cfg.FieldPrecioBase    := 'PRECIO_COMPRA_SESLIN';
  cfg.FieldTotalUds      := 'TOTAL_UNIDADES_SESLIN';
  cfg.FieldTotalLinea    := 'TOTAL_LINEA_SESLIN';
  cfg.TablaCeldas        := 'fza_compras_sesiones_celdas';
  cfg.FieldSerieCel      := 'SERIE_SES_SESCEL';
  cfg.FieldNumeroCel     := 'NUMERO_SES_SESCEL';
  cfg.FieldLineaCel      := 'LINEA_SES_SESCEL';
  cfg.FieldFilaCel       := 'ID_FILA_SES_SESCEL';
  cfg.FieldAvPivotCel    := 'ID_AV_PIVOT_SESCEL';
  cfg.FieldCantidadCel   := 'CANTIDAD_SESCEL';
  cfg.FieldAlmacenCel    := 'CODIGO_ALM_SESCEL';
  cfg.IdFilaFijo         := 1;
  cfg.MaxColumnas        := CANT_TALLAS_MAX;

  FGestorTallas := TGestorGridTallas.Create(cfg);

  // Hookear el OnEditValueChanged de cada columna talla al gestor.
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if FTallaColumns[i] <> nil then
      TcxCurrencyEditProperties(FTallaColumns[i].Properties).OnEditValueChanged
                                       := FGestorTallas.PersistirCeldaActiva;
end;

// Toda la logica reusable de tallas pivotadas (cache de conjuntos,
// maximo del documento, recalcular columnas, captions dinamicas,
// carga / persistencia de celdas, refresco de totales y validacion)
// vive ahora en inLibGridTallasInline.TGestorGridTallas — ver
// InicializarGestorTallas mas abajo. El form solo delega y mantiene
// la cabecera y los handlers especificos (familia, color, PVP).

// ===========================================================================
//   Lineas — alta, baja, navegacion
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.btnAddLineaClick(Sender: TObject);
begin
  inherited;
  if Dmm.unqryTablaG.IsEmpty then
  begin
    MessageDlg('Crea y graba la cabecera de la sesion antes de anadir lineas.',
               mtInformation, [mbOk], 0);
    Exit;
  end;
  // Si el master esta en dsInsert/dsEdit, hay que Postearlo primero para que
  // tenga SERIE_SES/NUMERO_SES (los rellena BeforePost via PRC_GET_NEXT_CONT).
  // Despues volvemos a ponerlo en Edit ANTES de Insert al detail: si el
  // AfterInsert del DM se encuentra el master en dsBrowse y llama a Edit,
  // la transicion del master rompe el dsInsert del detail master-detail y
  // las asignaciones de SERIE_SES_SESLIN, etc. revientan con
  // 'Dataset not in edit or insert mode'.
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  Dmm.unqryTablaG.Edit;
  Dmm.unqrySesionLin.Insert;
end;

procedure TfrmMtoPruebaSesionGrid.btnDelLineaClick(Sender: TObject);
var
  iLinea : Integer;
begin
  inherited;
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  if MessageDlg('Borrar la linea seleccionada?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  // Limpiar SESCEL de la linea antes de borrar la cabecera (no hay FK
  // cascade en BBDD; el patron es delete-on-app).
  if iLinea > 0 then
  begin
    // Borrado explicito de celdas de la linea
    with TUniQuery.Create(nil) do
    try
      Connection := inLibGlobalVar.oConn;
      SQL.Text :=
        'DELETE FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :l';
      ParamByName('s').AsString :=
        Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
      ParamByName('n').AsString :=
        Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
      ParamByName('l').AsInteger := iLinea;
      ExecSQL;
    finally
      Free;
    end;
  end;
  Dmm.unqrySesionLin.Delete;
  if Assigned(FGestorTallas) then FGestorTallas.RecalcularMaxColumnas;
end;

procedure TfrmMtoPruebaSesionGrid.btnImprimirClick(Sender: TObject);
var
  form     : TfrmPrintSesion;
  sSerie   : string;
  sNumero  : string;
begin
  inherited;
  if Dmm.unqryTablaG.IsEmpty then
  begin
    ShowMessage('No hay sesion activa que imprimir.');
    Exit;
  end;
  // Persistir cualquier edicion pendiente para que el report vea los
  // ultimos cambios (los TfrxDBDataset leen directamente de las vistas SQL).
  if Dmm.unqryTablaG.State in [dsEdit, dsInsert] then
    Dmm.unqryTablaG.Post;
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;

  sSerie  := Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  form := TfrmPrintSesion.Create(Application);
  try
    form.dmSesion       := Dmm;
    form.edtSerie.Text  := sSerie;
    form.edtNumero.Text := sNumero;
    form.ShowModal;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoPruebaSesionGrid.btnNuevoColorClick(Sender: TObject);
var
  ds                 : TDataSet;
  sFam, sCodArt      : string;
  sRefPrv, sDescr    : string;
  rPrCompra, rPrVenta: Double;
  iAcPivot           : Integer;
  rMargen            : Double;
  sTipoIva           : string;
  iSrcLinea, iNewLinea, iSiguiente : Integer;
  cantidades         : TArray<Double>;
  i, iSrcIdx         : Integer;
  arr                : TArrPosConjunto;
  v                  : Variant;
  q                  : TUniQuery;
begin
  inherited;
  // Duplica la linea activa con todos los datos comerciales (codigo,
  // familia, modelo prov., descripcion, precios, sistema de tallas) y
  // sus cantidades por talla, dejando vacios COLOR_TEXTO_SESLIN y
  // CODIGO_ATB_COLOR_SESLIN. Util cuando el cliente compra el mismo
  // articulo en varios colores: clic, cambias color, terminas.
  if FGestorTallas = nil then Exit;
  ds := Dmm.unqrySesionLin;
  if (ds = nil) or ds.IsEmpty then Exit;
  if Dmm.unqryTablaG.IsEmpty then Exit;

  // 1. Snapshot de los campos de la linea origen (incluido el record
  //    idx del cxGrid antes de mover nada).
  iSrcIdx    := tvLineas.Controller.FocusedRecordIndex;
  iSrcLinea  := ds.FieldByName('LINEA_SESLIN').AsInteger;
  sFam       := ds.FieldByName('CODIGO_FAM_SESLIN').AsString;
  sCodArt    := ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
  sRefPrv    := ds.FieldByName('REF_PRV_SESLIN').AsString;
  sDescr     := ds.FieldByName('DESCRIPCION_SESLIN').AsString;
  rPrCompra  := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  rPrVenta   := ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
  iAcPivot   := ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  rMargen    := ds.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  sTipoIva   := ds.FieldByName('TIPO_IVA_SESLIN').AsString;

  // 1b. Buscar la siguiente linea (LINEA_SESLIN minimo > origen). Si
  //     existe y hay hueco (>1), la nueva linea ira con el LINEA
  //     intermedio para quedar justo a continuacion en el grid (que
  //     ordena por LINEA). Si la origen es la ultima, dejamos el
  //     LINEA por defecto del AfterInsert (CONTADOR+10).
  iSiguiente := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN > :l';
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := iSrcLinea;
    q.Open;
    if not q.FieldByName('SIGUIENTE').IsNull then
      iSiguiente := q.FieldByName('SIGUIENTE').AsInteger;
  finally
    FreeAndNil(q);
  end;

  // 2. Snapshot de cantidades por talla desde Values[] del cxGrid.
  SetLength(cantidades, CANT_TALLAS_MAX);
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    cantidades[i] := 0;
    if FTallaColumns[i] = nil then Continue;
    if iSrcIdx < 0 then Continue;
    v := tvLineas.DataController.Values[iSrcIdx, FTallaColumns[i].Index];
    if (not VarIsNull(v)) and (not VarIsEmpty(v)) and VarIsNumeric(v) then
      cantidades[i] := v;
  end;

  // 3. Postear lo en edicion antes del Insert (mismo patron que
  //    btnAddLineaClick para no romper el master-detail).
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
  if ds.State in [dsEdit, dsInsert] then ds.Post;
  Dmm.unqryTablaG.Edit;

  // 4. Insert + asignacion de campos copiados (excepto color).
  ds.Insert;
  ds.FieldByName('CODIGO_FAM_SESLIN').AsString          := sFam;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := sCodArt;
  ds.FieldByName('REF_PRV_SESLIN').AsString             := sRefPrv;
  ds.FieldByName('DESCRIPCION_SESLIN').AsString         := sDescr;
  ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat        := rPrCompra;
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat         := rPrVenta;
  if iAcPivot > 0 then
    ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := iAcPivot;
  if rMargen > 0 then
    ds.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat := rMargen;
  if sTipoIva <> '' then
    ds.FieldByName('TIPO_IVA_SESLIN').AsString := sTipoIva;
  // Color y color basico se quedan vacios — los rellena el usuario.
  ds.FieldByName('COLOR_TEXTO_SESLIN').Clear;
  ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').Clear;
  // Sobreescribir LINEA_SESLIN si hay hueco para colocarse justo
  // detras de la origen (mantener cohesion visual entre las variantes
  // de color del mismo articulo).
  if (iSiguiente > 0) and ((iSiguiente - iSrcLinea) > 1) then
    ds.FieldByName('LINEA_SESLIN').AsInteger :=
      (iSrcLinea + iSiguiente) div 2;
  // (si la origen es la ultima, mantenemos el LINEA secuencial que
  //  asigno el AfterInsert del DM — CONTADOR_LINEAS_SES + 10).
  ds.Post;
  iNewLinea := ds.FieldByName('LINEA_SESLIN').AsInteger;

  // 5. Persistir cantidades para la nueva linea (mismo conjunto pivot).
  if iAcPivot > 0 then
  begin
    arr := FGestorTallas.GetPosicionesConjunto(iAcPivot);
    for i := 0 to High(arr) do
      if (i <= High(cantidades)) and (cantidades[i] > 0) then
        FGestorTallas.PersistirCantidad(iNewLinea, arr[i].IdAv, cantidades[i]);
  end;

  // 6. Refrescar Values[] de TODAS las lineas (incluida la nueva).
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.CargarCantidadesTodasLineas;

  // 7. Foco en la celda Color de la nueva linea.
  if ds.Locate('LINEA_SESLIN', iNewLinea, []) then
    tvLineas.Controller.FocusedRecordIndex := ds.RecNo - 1;
  tvLineas.Controller.FocusedColumn := dbcLinColor;
  if tvLineas.Controller.EditingController <> nil then
    tvLineas.Controller.EditingController.ShowEdit;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  frmSel : TfrmModalSelFamilia;
begin
  inherited;
  if (Key <> VK_F3) or (Shift <> []) then Exit;
  if not Assigned(AItem) then Exit;
  if AItem <> dbcLinFamilia then Exit;

  frmSel := TfrmModalSelFamilia.Create(Self);
  try
    if frmSel.ShowModal = mrOk then
      ExpandirCodigoFamiliaActiva(frmSel.CodigoFamilia, frmSel.NombreFamilia);
  finally
    FreeAndNil(frmSel);
  end;
  Key := 0;
end;

procedure TfrmMtoPruebaSesionGrid.dbcLinFamiliaPropertiesEditValueChanged(
  Sender: TObject);
var
  ed       : TcxCustomEdit;
  sNuevo   : string;
  sTent    : string;
begin
  inherited;
  if not (Sender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(Sender);
  ed.PostEditValue;

  // El usuario ha tecleado el codigo de familia directamente (sin F3).
  // Comportamos igual que el modal: si la familia tiene contador activo,
  // ResolverCodigoFamilia genera CODIGO_FAM+RELLENO. Si ya hay un codigo
  // tentativo expandido para esa misma familia ('BOLSOS00001' cuando
  // sNuevo='BOLSOS'), no consumimos otro contador.
  sNuevo := Trim(Dmm.unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString);
  if sNuevo = '' then Exit;
  sTent  := Dmm.unqrySesionLin.FieldByName(
                                    'CODIGO_ART_TENTATIVO_SESLIN').AsString;
  if (sTent <> '') and (Length(sTent) > Length(sNuevo))
     and SameText(Copy(sTent, 1, Length(sNuevo)), sNuevo) then
    Exit; // ya parece expandido para la familia actual
  ExpandirCodigoFamiliaActiva(sNuevo);
end;

procedure TfrmMtoPruebaSesionGrid.ExpandirCodigoFamiliaActiva(
  const ACodigoFam: string; const ANombreFam: string);
var
  ds         : TDataSet;
  sExpandido : string;
  sTentativo : string;
  sNombre    : string;
  q          : TUniQuery;
begin
  // Helper compartido por F3 y OnEditValueChanged de la columna Familia:
  // pone CODIGO_FAM_SESLIN, intenta expandir a CODIGO_ART_TENTATIVO via
  // ResolverCodigoFamilia (incrementa CONTADOR_ART_FAM) y prerellena la
  // descripcion con NOMBRE_FAM_FAM si esta vacia.
  if Trim(ACodigoFam) = '' then Exit;
  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_FAM_SESLIN').AsString := ACodigoFam;
  sTentativo := ACodigoFam;
  if ResolverCodigoFamilia(inLibGlobalVar.oConn, ACodigoFam, oUser,
                           sExpandido) then
    sTentativo := sExpandido;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := sTentativo;

  // Descripcion: si esta vacia, copiar NOMBRE_FAM_FAM. Si venimos del
  // modal F3 ya lo recibimos en ANombreFam (sin query). Si venimos de
  // tipeo manual la consulta puntual a fza_articulos_familias trae
  // el nombre para esta linea.
  if ds.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
  begin
    sNombre := ANombreFam;
    if sNombre = '' then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := inLibGlobalVar.oConn;
        q.SQL.Text :=
          'SELECT NOMBRE_FAM_FAM FROM fza_articulos_familias ' +
          ' WHERE CODIGO_FAM_FAM = :p';
        q.ParamByName('p').AsString := ACodigoFam;
        q.Open;
        if not q.IsEmpty then
          sNombre := q.FieldByName('NOMBRE_FAM_FAM').AsString;
      finally
        FreeAndNil(q);
      end;
    end;
    if sNombre <> '' then
      ds.FieldByName('DESCRIPCION_SESLIN').AsString := sNombre;
  end;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  if Assigned(FGestorTallas) then FGestorTallas.ActualizarCaptionsLineaActiva;
end;

// ===========================================================================
//   Color basico — selector con paleta
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.tvLineasInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  BE       : TcxButtonEdit;
  Btn      : TcxEditButton;
  AvActual : string;
  Info     : TInfoBasico;
begin
  inherited;
  // Estilo Excel: al entrar a una celda el contenido queda seleccionado,
  // asi una pulsacion lo sustituye y Tab/Enter lo deja como esta.
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
  if AItem <> dbcLinColorBasico then Exit;
  if not (AEdit is TcxButtonEdit) then Exit;
  BE := TcxButtonEdit(AEdit);
  if BE.Properties.Buttons.Count = 0 then Exit;
  Btn := BE.Properties.Buttons[0];

  AvActual := '';
  if Dmm.unqrySesionLin.Active and (not Dmm.unqrySesionLin.IsEmpty) then
    AvActual := Dmm.unqrySesionLin.FieldByName(
                                       'CODIGO_ATB_COLOR_SESLIN').AsString;

  Info := Default(TInfoBasico);
  if Trim(AvActual) <> '' then
    ObtenerInfoBasico(fIdVaColor, AvActual, Info);

  if Info.EsValido and PintarSwatchEnBitmap(FBmpSwatch, Info, 14) then
  begin
    Btn.Glyph.Assign(FBmpSwatch);
    Btn.Kind := bkGlyph;
  end
  else
    Btn.Kind := bkEllipsis;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  Col      : TcxGridColumn;
  Info     : TInfoBasico;
  AvActual : string;
  colAc    : TcxGridColumn;
  vAc      : Variant;
  iAc      : Integer;
  arr      : TArrPosConjunto;
begin
  inherited;
  Col := nil;
  if AViewInfo.GridRecord = nil then Exit;
  if AViewInfo.Item is TcxGridColumn then
    Col := TcxGridColumn(AViewInfo.Item);
  if Col = nil then Exit;

  // ---- Sombreado celdas talla fuera del conjunto de la fila ----
  // Cada fila puede tener un sistema de tallaje distinto. Las celdas
  // talla cuyo Tag (posicion 1..N) excede el tamanyo del conjunto pivot
  // de esa fila no aplican — las pintamos con un sombreado claro para
  // que el usuario vea que no son editables. El bloqueo de edicion
  // efectivo se hace en tvLineasEditing.
  if (Col.Tag >= 1) and (Col.Tag <= CANT_TALLAS_MAX) and
     (Col = FTallaColumns[Col.Tag - 1]) then
  begin
    colAc := tvLineas.GetColumnByFieldName('ID_AC_PIVOT_SESLIN');
    if colAc <> nil then
    begin
      vAc := AViewInfo.GridRecord.Values[colAc.Index];
      if (not VarIsNull(vAc)) and (not VarIsEmpty(vAc)) and VarIsNumeric(vAc) then
      begin
        iAc := vAc;
        if (iAc > 0) and Assigned(FGestorTallas) then
        begin
          arr := FGestorTallas.GetPosicionesConjunto(iAc);
          if Col.Tag > Length(arr) then
          begin
            // Posicion fuera del conjunto de esta fila → sombrear.
            ACanvas.Brush.Color := $00E8E8E8;  // gris claro
            ACanvas.FillRect(AViewInfo.Bounds);
            ADone := True;
            Exit;
          end;
        end;
      end;
    end;
  end;

  // ---- Swatch de color basico ----
  if Col <> dbcLinColorBasico then Exit;
  AvActual := VarToStr(AViewInfo.GridRecord.Values[Col.Index]);
  if Trim(AvActual) = '' then Exit;
  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico(fIdVaColor, AvActual, Info) then Exit;
  if not Info.EsValido then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info) then
    ADone := True;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  inherited;
  // Si la celda es una talla cuya posicion (Tag) excede el tamanyo
  // del conjunto pivot de la linea con foco, no permitir edicion. Asi
  // el usuario no puede teclear cantidades en celdas que no aplican
  // al sistema de tallaje de esa linea.
  if AItem = nil then Exit;
  if (AItem.Tag < 1) or (AItem.Tag > CANT_TALLAS_MAX) then Exit;
  if FGestorTallas = nil then Exit;
  if Dmm.unqrySesionLin.IsEmpty then Exit;

  iAc := Dmm.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  if iAc <= 0 then Exit;
  arr := FGestorTallas.GetPosicionesConjunto(iAc);
  if AItem.Tag > Length(arr) then
    AAllow := False;
end;

procedure TfrmMtoPruebaSesionGrid.dbcLinColorBasicoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  AvActual : string;
  AvNuevo  : string;
  ds       : TDataSet;
  Edit     : TWinControl;
  ScrPt    : TPoint;
  WidHint  : Integer;
begin
  if Length(FBasicosColor) = 0 then
  begin
    MessageDlg('No hay colores basicos cargados en fza_atributos_basicos ' +
               'para ID_VA=''CO''.', mtInformation, [mbOk], 0);
    Exit;
  end;

  ds := Dmm.unqrySesionLin;
  if ds.IsEmpty then Exit;
  AvActual := ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;

  ScrPt.X := -1; ScrPt.Y := -1;
  WidHint := 160;
  if Sender is TWinControl then
  begin
    Edit    := TWinControl(Sender);
    ScrPt   := Edit.ClientToScreen(Point(0, Edit.Height));
    WidHint := Edit.Width;
  end;

  if not SeleccionarAvConPaleta(fIdVaColor, FBasicosColor, AvActual,
                                AvNuevo, ScrPt.X, ScrPt.Y, WidHint) then
    Exit;

  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString := AvNuevo;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).EditValue := AvNuevo;
end;

// ===========================================================================
//   Auto-PVP
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.dbcLinPrecioCompraPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  ProponerPrecioVenta;
end;

procedure TfrmMtoPruebaSesionGrid.ProponerPrecioVenta;
var
  rCoste, rMargen, rMultiplo, rAjuste, rVenta : Double;
  ds                                          : TDataSet;
begin
  if Dmm.unqryTablaG.IsEmpty then Exit;
  if Dmm.unqrySesionLin.IsEmpty then Exit;

  ds := Dmm.unqrySesionLin;
  rCoste    := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  rMargen   := Dmm.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat;
  rMultiplo := Dmm.unqryTablaG.FieldByName('MULTIPLO_REDONDEO_SES').AsFloat;
  rAjuste   := Dmm.unqryTablaG.FieldByName('AJUSTE_FINAL_SES').AsFloat;

  rVenta := CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := rVenta;
end;

// ===========================================================================
//   Conjunto de tallas (Sistema tallas) cambia -> rebuild de cabeceras
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.dbcLinTallasPropertiesEditValueChanged(
  Sender: TObject);
begin
  inherited;
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).PostEditValue;
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  if FGestorTallas = nil then Exit;

  // Rechaza sistemas con mas valores que el maximo (mtError + clear)
  // ANTES de Postear/reasignar columnas. La validacion vive en la
  // libreria — un solo punto para todos los Mtos que usen el patron.
  if not FGestorTallas.ValidarSistemaSeleccionado then Exit;

  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;
  FGestorTallas.RecalcularMaxColumnas;
  FGestorTallas.ActualizarCaptionsLineaActiva;
end;

// La edicion de celdas talla (antiguo TallaCellEditValueChanged) se
// extrajo a TGestorGridTallas.PersistirCeldaActiva; el handler se
// engancha automaticamente en InicializarGestorTallas.

initialization
  ForceReferenceToClass(TfrmMtoPruebaSesionGrid);
end.
