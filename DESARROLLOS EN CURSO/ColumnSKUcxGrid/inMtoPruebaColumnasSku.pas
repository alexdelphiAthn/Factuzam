{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPruebaColumnasSku                                        }
{    Tipo:       Formulario (Mto de prueba)                                    }
{ Version:       0.2.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: banco de pruebas de los modos de entrada de       }
{    articulos, ahora heredando de TfrmMtoGen para ver el comportamiento       }
{    dentro del ciclo real de Factuzam (perfiles, permisos, etiquetas,         }
{    Lista/Ficha, EnterAsTab de TfrmBase...).                                  }
{                                                                              }
{      - Pestanya Ficha: radio Auto/SKU/Desglose + almacen + Construir +       }
{        grid de lineas (TClientDataSet en memoria).                           }
{      - Pestanya Lista: el mismo cds como tabla principal (dsTablaG).         }
{      - El EnterAsTab de la base se desactiva durante la edicion in-place     }
{        via OnEntrarEdicion / OnSalirEdicion del modo.                        }
{                                                                              }
{    Sin data module: CrearTablaPrincipal se sobreescribe SIN inherited        }
{    (el por defecto castea Owner a TfrmMtoPrincipal y fuera de fzam           }
{    lanzaria EInvalidCast).                                                   }
{******************************************************************************}
unit inMtoPruebaColumnasSku;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB, Datasnap.DBClient, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxMemo, cxRadioGroup,
  cxCheckBox, cxButtons,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxClasses, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations,
  inMtoGen,
  inLibColumnasSkuIntf, inLibColumnasSku, inLibGridTallasInline;

type
  TfrmMtoPruebaColumnasSku = class(TfrmMtoGen)
    pnlTop: TPanel;
    lblAlmacen: TcxLabel;
    txtAlmacen: TcxTextEdit;
    rgModo: TcxRadioGroup;
    btnConstruir: TcxButton;
    btnAddLinea: TcxButton;
    chkDistribuido: TcxCheckBox;
    lblEstado: TcxLabel;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    glLineas: TcxGridLevel;
    mLog: TcxMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConstruirClick(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
  private
    FCds: TClientDataSet;
    FDs: TDataSource;
    // "Cabecera" en memoria del documento de prueba (SERIE/NUMERO fijos
    // PRU/1): la necesita el gestor de tallas para la tabla de celdas.
    FCdsMaster: TClientDataSet;
    FDsMaster: TDataSource;
    // True tras limpiar las celdas PRU/1 (una vez por sesion).
    FCeldasLimpiadas: Boolean;
    FModo: IModoEntradaGrid;
    procedure CrearCdsLineas;
    procedure AnadirLineaVacia;
    // Max LINEA del cds + 1 (numeracion compartida con el des-pivote).
    function SiguienteLinea: Integer;
    // Deja UNA linea en blanco y siempre al final (el des-pivote
    // anyade lineas por detras y la vieja quedaba emparedada).
    procedure NormalizarLineaEnBlanco;
    // Al cambiar el almacen del documento, las lineas SIN almacen
    // (la de entrada en blanco incluida) adoptan el nuevo valor: la
    // linea en blanco nace antes de teclearlo y quedaba vacia.
    procedure txtAlmacenSalir(Sender: TObject);
    // Columnas propias del documento (Descripcion, Cantidad) sobre el
    // mismo View, DESPUES de que el modo cree las suyas.
    procedure AnadirColumnasHost;
    // Solo banco de pruebas: en desglose, las columnas de atributo nacen
    // ocultas (cada articulo tiene las suyas); aqui se precargan con los
    // atributos globales para verlas antes de resolver el primero.
    procedure MostrarColumnasAtributoGlobales;
    procedure ModoResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
    // Chivato de LogSes (gestor de tallas y adaptadores) al memo.
    procedure LogMsg(const S: string);
    // Salida del grid: restaura EnterAsTab y deja traza de su estado.
    procedure GridSalir(Sender: TObject);
  protected
    // Sin data module: la "tabla principal" del Mto es el cds en
    // memoria. NO llama a inherited: el por defecto hace
    // (Owner as TfrmMtoPrincipal) y fuera de fzam es EInvalidCast.
    procedure CrearTablaPrincipal; override;
    // Sin modo busqueda: la prueba abre siempre en la Ficha (edicion)
    // y se construye sola en el primer Show.
    procedure ResetForm; override;
    // KeyPreview de TfrmBase: F1 alterna el modo de columnas y Enter
    // en el grupo de radios salta al siguiente control (el radio se
    // traga el Enter y el JvEnterAsTab de la base no llega a verlo).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  end;

var
  frmMtoPruebaColumnasSku: TfrmMtoPruebaColumnasSku;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

procedure TfrmMtoPruebaColumnasSku.FormCreate(Sender: TObject);
begin
  // Ciclo completo de TfrmMtoGen (perfiles, permisos, etiquetas...);
  // dentro llama a nuestro CrearTablaPrincipal.
  inherited;
  tvLineas.DataController.DataSource := FDs;
  // Cualquier LogSes de la libreria de tallas vuelca al memo inferior
  // (mismo patron que la pestanya Log de inMtoComprasSesiones).
  inLibGlobalVar.oLogSesion := LogMsg;
  txtAlmacen.OnExit := txtAlmacenSalir;
  // Red de seguridad del EnterAsTab: al salir del GRID hacia
  // cualquier otro control se restaura siempre (los modos solo cubren
  // los movimientos de foco dentro del grid).
  cxgrdLineas.OnExit := GridSalir;
  lblEstado.Caption := 'Elige modo y pulsa Construir (pestaña Ficha)';
end;

procedure TfrmMtoPruebaColumnasSku.txtAlmacenSalir(Sender: TObject);
var
  bk: TBookmark;
begin
  if (FCds <> nil) and FCds.Active and (not FCds.IsEmpty) and
     (Trim(txtAlmacen.Text) <> '') then
  begin
    bk := FCds.GetBookmark;
    try
      FCds.First;
      while not FCds.Eof do
      begin
        if Trim(FCds.FieldByName('ALMACEN').AsString) = '' then
        begin
          FCds.Edit;
          FCds.FieldByName('ALMACEN').AsString :=
            Trim(txtAlmacen.Text);
          FCds.Post;
        end;
        FCds.Next;
      end;
      if FCds.BookmarkValid(bk) then
        FCds.GotoBookmark(bk);
    finally
      FCds.FreeBookmark(bk);
    end;
  end;
end;

procedure TfrmMtoPruebaColumnasSku.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna el modo de columnas (Auto -> SKU -> Desglose -> Tallas
  // horizontal -> Auto) y reconstruye. El DISTRIBUIDO no entra en el
  // ciclo: se activa desde la cabecera del documento (chkDistribuido).
  if (Key = VK_F1) and (Shift = []) then
  begin
    Key := 0;
    if rgModo.ItemIndex >= rgModo.Properties.Items.Count - 1 then
      rgModo.ItemIndex := 0
    else
      rgModo.ItemIndex := rgModo.ItemIndex + 1;
    btnConstruirClick(nil);
  end
  // Enter con el foco en el grupo de radios: el TcxRadioGroup consume
  // la tecla y el EnterAsTab nunca actua; lo convertimos en Tab.
  else if (Key = VK_RETURN) and rgModo.Focused then
  begin
    Key := 0;
    SelectNext(rgModo, True, True);
  end;
  inherited;
end;

procedure TfrmMtoPruebaColumnasSku.GridSalir(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  LogMsg('Grid.OnExit: EnterAsTab=' +
         BoolToStr(jvntrstb1.EnterAsTab, True));
end;

procedure TfrmMtoPruebaColumnasSku.LogMsg(const S: string);
begin
  if mLog <> nil then
    mLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + S);
end;

procedure TfrmMtoPruebaColumnasSku.FormDestroy(Sender: TObject);
begin
  // Desenganchar el View antes de soltar el modo (interface: se libera
  // al soltar la referencia).
  // Nadie debe volcar al memo durante la destruccion.
  inLibGlobalVar.oLogSesion := nil;
  tvLineas.OnInitEdit := nil;
  tvLineas.OnEditKeyDown := nil;
  tvLineas.OnEditing := nil;
  tvLineas.OnFocusedRecordChanged := nil;
  tvLineas.OnFocusedItemChanged := nil;
  tvLineas.ClearItems;
  FModo := nil;
  dsTablaG.DataSet := nil;
  FreeAndNil(FDs);
  FreeAndNil(FCds);
  inherited;
end;

procedure TfrmMtoPruebaColumnasSku.CrearTablaPrincipal;
begin
  if FCds = nil then
  begin
    CrearCdsLineas;
    FDs := TDataSource.Create(Self);
    FDs.DataSet := FCds;
    // Cabecera ficticia PRU/1 para la tabla de celdas de tallas.
    FCdsMaster := TClientDataSet.Create(Self);
    FCdsMaster.FieldDefs.Add('SERIE', ftString, 10);
    FCdsMaster.FieldDefs.Add('NUMERO', ftInteger);
    FCdsMaster.CreateDataSet;
    FCdsMaster.Append;
    FCdsMaster.FieldByName('SERIE').AsString := 'PRU';
    FCdsMaster.FieldByName('NUMERO').AsInteger := 1;
    FCdsMaster.Post;
    FDsMaster := TDataSource.Create(Self);
    FDsMaster.DataSet := FCdsMaster;
    AnadirLineaVacia;
  end;
  // La pestanya Lista del Mto muestra el mismo cds de lineas.
  dsTablaG.DataSet := FCds;
  if cxGrdDBTabPrin.ColumnCount = 0 then
    cxGrdDBTabPrin.DataController.CreateAllItems;
end;

procedure TfrmMtoPruebaColumnasSku.ResetForm;
begin
  // NO llama a inherited (el de la base fuerza tsLista, el "modo
  // busqueda"): aqui se entra siempre por la Ficha, en edicion.
  if pcPantalla.ActivePage <> tsFicha then
    pcPantalla.ActivePage := tsFicha;
  // Primer Show: construir solo con el modo del radio. Diferido con
  // ForceQueue porque durante el FormShow el grid aun no puede recibir
  // el foco (MostrarEditor lo necesita).
  if FModo = nil then
    TThread.ForceQueue(nil,
      procedure
      begin
        if (not (csDestroying in ComponentState)) and (FModo = nil) then
          btnConstruirClick(nil);
      end);
end;

procedure TfrmMtoPruebaColumnasSku.CrearCdsLineas;
var
  i: Integer;
begin
  // Lineas en memoria con la misma forma que el cds de un documento real
  // (mismos nombres que usa el grid de traspasos / caja).
  FCds := TClientDataSet.Create(Self);
  FCds.FieldDefs.Add('CODIGO_ART', ftString, 20);
  FCds.FieldDefs.Add('CODIGO_UNIDAD', ftString, 60);
  FCds.FieldDefs.Add('DESCRIPCION', ftString, 100);
  FCds.FieldDefs.Add('CANTIDAD', ftFloat);
  // Almacen de la LINEA (modelo compras): distribucion por almacen =
  // una linea horizontal por articulo+color+almacen.
  FCds.FieldDefs.Add('ALMACEN', ftString, 10);
  FCds.FieldDefs.Add('NUM_ATRIBUTOS', ftInteger);
  // Campos extra para el modo tallas en horizontal (pivote).
  FCds.FieldDefs.Add('LINEA', ftInteger);
  FCds.FieldDefs.Add('ID_AC_PIVOT', ftInteger);
  FCds.FieldDefs.Add('PRECIO', ftFloat);
  FCds.FieldDefs.Add('TOTAL_UNIDADES', ftFloat);
  FCds.FieldDefs.Add('TOTAL_LINEA', ftFloat);
  for i := 1 to 5 do
  begin
    FCds.FieldDefs.Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 30);
    FCds.FieldDefs.Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 30);
  end;
  FCds.CreateDataSet;
end;

procedure TfrmMtoPruebaColumnasSku.AnadirLineaVacia;
var
  iLinea: Integer;
begin
  // Numero de linea ANTES del Append: el escaneo mueve el cursor y en
  // dsInsert provocaria un Post implicito.
  iLinea := SiguienteLinea;
  FCds.Append;
  FCds.FieldByName('NUM_ATRIBUTOS').AsInteger := 0;
  FCds.FieldByName('CANTIDAD').AsFloat := 1;
  // Almacen por defecto de la linea = el "del documento" (edit de
  // arriba), como el fallback de cabecera de albaranes de compra.
  FCds.FieldByName('ALMACEN').AsString := Trim(txtAlmacen.Text);
  FCds.FieldByName('LINEA').AsInteger := iLinea;
  FCds.FieldByName('PRECIO').AsFloat := 1;
  FCds.Post;
end;

function TfrmMtoPruebaColumnasSku.SiguienteLinea: Integer;
var
  bk: TBookmark;
begin
  // Max LINEA del cds + 1 (el des-pivote de tallas tambien crea lineas
  // y un contador local se desincronizaria). Sin DisableControls: su
  // EnableControls resetea los Values[] no-bound de las tallas.
  Result := 1;
  if not FCds.IsEmpty then
  begin
    bk := FCds.GetBookmark;
    try
      FCds.First;
      while not FCds.Eof do
      begin
        if FCds.FieldByName('LINEA').AsInteger >= Result then
          Result := FCds.FieldByName('LINEA').AsInteger + 1;
        FCds.Next;
      end;
      if FCds.BookmarkValid(bk) then
        FCds.GotoBookmark(bk);
    finally
      FCds.FreeBookmark(bk);
    end;
  end;
end;

procedure TfrmMtoPruebaColumnasSku.NormalizarLineaEnBlanco;
var
  EvBorrado: TDataSetNotifyEvent;
  iPos: Integer;
begin
  // Borrado programatico: sin el guardian de confirmacion que TfrmMtoGen
  // engancha en BeforeDelete del dataset principal.
  EvBorrado := FCds.BeforeDelete;
  FCds.BeforeDelete := nil;
  try
    // Recorrido por RecNo: al borrar el ULTIMO registro el cursor cae
    // en el anterior (no en Eof) y un while-not-Eof reprocesaria filas.
    iPos := 1;
    while iPos <= FCds.RecordCount do
    begin
      FCds.RecNo := iPos;
      if Trim(FCds.FieldByName('CODIGO_ART').AsString) = '' then
      begin
        LogMsg(Format('Normalizar: borra linea %d (articulo vacio)',
                      [FCds.FieldByName('LINEA').AsInteger]));
        FCds.Delete;
      end
      else
        Inc(iPos);
    end;
  finally
    FCds.BeforeDelete := EvBorrado;
  end;
  AnadirLineaVacia;
end;

procedure TfrmMtoPruebaColumnasSku.btnAddLineaClick(Sender: TObject);
begin
  if FCds.State in [dsEdit, dsInsert] then
    FCds.Post;
  AnadirLineaVacia;
  if FModo <> nil then
    FModo.MostrarEditor;
end;

procedure TfrmMtoPruebaColumnasSku.btnConstruirClick(Sender: TObject);
const
  NOMBRES_MODO: array[TModoColumnasSku] of string =
    ('Auto', 'SKU (una columna)', 'Desglose (Art + Color + Talla)',
     'Tallas en horizontal');
var
  Cfg: TConfigColumnasSku;
  CfgTallas: TGridTallasConfig;
  i: Integer;
begin
  // Reconstruccion: desenganchar el View del modo anterior ANTES de
  // soltarlo. Su destructor libera el repositorio de editores y los
  // timers, y si el View conserva columnas (RepositoryItem) o eventos
  // (OnInitEdit / OnEditKeyDown / OnCustomDrawCell) apuntando al objeto
  // destruido, el siguiente repintado revienta con un AV.
  if FModo <> nil then
  begin
    if tvLineas.Controller.EditingController.IsEditing then
      try
        tvLineas.Controller.EditingController.HideEdit(False);
      except
        on E: EInvalidOperation do
          ;
      end;
    if FCds.State in [dsEdit, dsInsert] then
      FCds.Cancel;
    // El modo saliente convierte su estado al comun (tallas expande
    // celdas en lineas por SKU); en SKU/desglose no hace nada.
    FModo.Desmontar;
    // TODOS los eventos del View que los modos pueden enganchar: un
    // puntero a un modo destruido revienta con AV al primer foco.
    tvLineas.OnInitEdit := nil;
    tvLineas.OnEditKeyDown := nil;
    tvLineas.OnEditing := nil;
    tvLineas.OnFocusedRecordChanged := nil;
    tvLineas.OnFocusedItemChanged := nil;
    tvLineas.ClearItems;
    FModo := nil;
  end;
  Cfg.Conexion := oConn;
  Cfg.View := tvLineas;
  Cfg.Cds := FCds;
  Cfg.AlmacenStock := Trim(txtAlmacen.Text);
  // Formato distribuido (solo lo usa el modo tallas), como el check
  // ESFORMATO_DISTRIBUIDO_SES de sesiones de compra.
  Cfg.Distribuido := chkDistribuido.Checked;
  // Radios: 0=Auto, 1=SKU, 2=Tallas horizontal. El DESGLOSE no es
  // seleccionable: es el modo EFECTIVO al que resuelve Auto cuando el
  // documento tiene columnas de atributo (elegirlo a mano era
  // redundante). mcsDesglose sigue en el contrato como resultado.
  case rgModo.ItemIndex of
    1: Cfg.Modo := mcsSku;
    2: Cfg.Modo := mcsTallasInline;
  else
    Cfg.Modo := mcsAuto;
  end;
  Cfg.Campos.CodigoArt := 'CODIGO_ART';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD';
  Cfg.Campos.Descripcion := 'DESCRIPCION';
  Cfg.Campos.Cantidad := 'CANTIDAD';
  Cfg.Campos.Almacen := 'ALMACEN';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS';
  if Cfg.Modo = mcsSku then
    // En modo SKU el documento no desglosa atributos: campos vacios
    // (asi la deteccion Auto tambien elegiria mcsSku). El modo tallas
    // SI los usa: alli van el color y demas atributos no talla.
    for i := 1 to 5 do
    begin
      Cfg.Campos.AttrValor[i] := '';
      Cfg.Campos.AttrNombre[i] := '';
    end
  else
    for i := 1 to 5 do
    begin
      Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
      Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
    end;
  // La factoria decide (o respeta) el modo y devuelve el contrato. El
  // modo tallas necesita ademas la config del pivote (tabla de celdas
  // de prueba fza_prueba_skucel; ver prueba_columnas_sku.sql).
  if Cfg.Modo = mcsTallasInline then
  begin
    if not FCeldasLimpiadas then
    begin
      // Tabla de celdas de la prueba, RECREADA al primer Construir de
      // cada sesion (desechable): asi no acumula cantidades de pruebas
      // anteriores y siempre lleva el DDL vigente — ahora con almacen
      // por celda para el formato distribuido (clave con almacen; las
      // celdas no distribuidas usan almacen '').
      oConn.ExecSQL('DROP TABLE IF EXISTS fza_prueba_skucel');
      oConn.ExecSQL(
        'CREATE TABLE fza_prueba_skucel (' +
        ' SERIE_PSC VARCHAR(10) NOT NULL,' +
        ' NUMERO_PSC INT NOT NULL,' +
        ' LINEA_PSC INT NOT NULL,' +
        ' ID_FILA_PSC INT NOT NULL DEFAULT 1,' +
        ' CODIGO_ALM_PSC VARCHAR(10) NOT NULL DEFAULT '''',' +
        ' ID_AV_PIVOT_PSC INT NOT NULL,' +
        ' CANTIDAD_PSC DOUBLE NOT NULL DEFAULT 0,' +
        ' INSTANTE_ALTA DATETIME NULL,' +
        ' INSTANTE_MODIF DATETIME NULL,' +
        ' USUARIO_ALTA VARCHAR(50) NULL,' +
        ' USUARIO_MODIF VARCHAR(50) NULL,' +
        ' PRIMARY KEY (SERIE_PSC, NUMERO_PSC, LINEA_PSC, ID_FILA_PSC,' +
        '              CODIGO_ALM_PSC, ID_AV_PIVOT_PSC)' +
        ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4' +
        ' COLLATE=utf8mb4_spanish_ci');
      FCeldasLimpiadas := True;
      LogMsg('Tabla de celdas PRU/1 recreada (inicio de sesion)');
    end;
    CfgTallas.Usuario := oUser;
    CfgTallas.SourceMaster := FDsMaster;
    CfgTallas.SourceLineas := FDs;
    CfgTallas.FieldSerieMaster := 'SERIE';
    CfgTallas.FieldNumeroMaster := 'NUMERO';
    CfgTallas.FieldLinea := 'LINEA';
    CfgTallas.FieldConjuntoPivot := 'ID_AC_PIVOT';
    CfgTallas.FieldPrecioBase := 'PRECIO';
    CfgTallas.FieldTotalUds := 'TOTAL_UNIDADES';
    CfgTallas.FieldTotalLinea := 'TOTAL_LINEA';
    CfgTallas.TablaCeldas := 'fza_prueba_skucel';
    CfgTallas.FieldSerieCel := 'SERIE_PSC';
    CfgTallas.FieldNumeroCel := 'NUMERO_PSC';
    CfgTallas.FieldLineaCel := 'LINEA_PSC';
    CfgTallas.FieldFilaCel := 'ID_FILA_PSC';
    CfgTallas.FieldAvPivotCel := 'ID_AV_PIVOT_PSC';
    CfgTallas.FieldCantidadCel := 'CANTIDAD_PSC';
    // Almacen por celda: '' en tecleo/lecturas normales; el modal
    // distribuidor escribe almacenes concretos (formato distribuido).
    CfgTallas.FieldAlmacenCel := 'CODIGO_ALM_PSC';
    CfgTallas.IdFilaFijo := 1;
    // Tope acordado: 20 tallas. Sistemas mayores -> aviso del gestor y
    // la linea se queda sin pasar a horizontal.
    CfgTallas.MaxColumnas := 20;
    FModo := CrearModoEntradaGridTallas(Cfg, CfgTallas);
  end
  else
    FModo := CrearModoEntradaGrid(Cfg);
  FModo.OnResuelto := ModoResuelto;
  // EnterAsTab de TfrmBase fuera durante la edicion in-place: si no, el
  // Enter se convierte en Tab y no llega ni a la celda de SKU/articulo
  // ni al desplegable incremental ni a los combos de atributo.
  FModo.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FModo.OnSalirEdicion := RestaurarEnterAsTabTemporal;
  FModo.Construir;
  AnadirColumnasHost;
  if FModo.Modo = mcsDesglose then
    MostrarColumnasAtributoGlobales;
  // Modo edicion TODO el rato: editor in-place siempre visible en la
  // celda con foco y sin busqueda incremental de grid. EXCEPCION: en
  // tallas NO se fuerza AlwaysShowEditor — sesiones de compra no lo usa
  // y con el activo el ciclo persistir->recargar fila descoloca el
  // foco entre celdas de talla.
  tvLineas.OptionsBehavior.AlwaysShowEditor :=
    FModo.Modo <> mcsTallasInline;
  tvLineas.OptionsBehavior.ImmediateEditor := True;
  tvLineas.OptionsBehavior.IncSearch := False;
  tvLineas.OptionsData.Editing := True;
  // La linea en blanco, unica y al final, tras cualquier conversion.
  NormalizarLineaEnBlanco;
  lblEstado.Caption := 'Modo efectivo: ' + NOMBRES_MODO[FModo.Modo];
  pcPantalla.ActivePage := tsFicha;
  cxgrdLineas.SetFocus;
  FModo.MostrarEditor;
end;

procedure TfrmMtoPruebaColumnasSku.AnadirColumnasHost;
begin
  // Lo que haria un Mto real: sus columnas propias tras las del modo.
  with tvLineas.CreateColumn as TcxGridDBColumn do
  begin
    Caption := 'Descripción';
    DataBinding.FieldName := 'DESCRIPCION';
    Options.Editing := False;
    Width := 240;
  end;
  // Almacen de la linea, EDITABLE y visible en TODOS los modos: cada
  // partida muestra a que almacen pertenece (el des-pivote de tallas
  // distribuidas genera una linea por SKU y almacen).
  with tvLineas.CreateColumn as TcxGridDBColumn do
  begin
    Caption := 'Almacén';
    DataBinding.FieldName := 'ALMACEN';
    Width := 70;
  end;
  if FModo.Modo = mcsTallasInline then
  begin
    // Cantidad editable para lineas SIN sistema de tallas (servicios,
    // gastos...): sus celdas de talla no admiten cantidades.
    with tvLineas.CreateColumn as TcxGridDBColumn do
    begin
      Caption := 'Cantidad';
      DataBinding.FieldName := 'CANTIDAD';
      Width := 70;
    end;
    // En articulos con tallas la cantidad va por celda: se muestran
    // los totales que recalcula el gestor desde la tabla de celdas.
    with tvLineas.CreateColumn as TcxGridDBColumn do
    begin
      Caption := 'Total uds.';
      DataBinding.FieldName := 'TOTAL_UNIDADES';
      Options.Editing := False;
      Width := 70;
    end;
    with tvLineas.CreateColumn as TcxGridDBColumn do
    begin
      Caption := 'Total línea';
      DataBinding.FieldName := 'TOTAL_LINEA';
      Options.Editing := False;
      Width := 80;
    end;
  end
  else
    with tvLineas.CreateColumn as TcxGridDBColumn do
    begin
      Caption := 'Cantidad';
      DataBinding.FieldName := 'CANTIDAD';
      Width := 70;
    end;
end;

procedure TfrmMtoPruebaColumnasSku.MostrarColumnasAtributoGlobales;
var
  Qry: TUniQuery;
  i, iOrden: Integer;
  Col: TcxGridDBColumn;
begin
  // Nombres globales de atributos (mismo origen que el mapa de la
  // paleta), ordenados. Al resolver un articulo,
  // ActualizarColumnasAtributo re-rotula/oculta segun SUS atributos.
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text :=
      'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE,' +
      '       MIN(ORDEN_VA) AS ORDEN' +
      '  FROM fza_variaciones_atributos' +
      ' GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA)' +
      ' ORDER BY ORDEN, NOMBRE LIMIT 5';
    Qry.Open;
    iOrden := 1;
    while (not Qry.Eof) and (iOrden <= 5) do
    begin
      for i := 0 to tvLineas.ColumnCount - 1 do
      begin
        Col := tvLineas.Columns[i];
        if Col.Tag = iOrden then
        begin
          Col.Caption := Qry.FieldByName('NOMBRE').AsString;
          Col.Visible := True;
        end;
      end;
      Inc(iOrden);
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmMtoPruebaColumnasSku.ModoResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  if FModo.Modo = mcsTallasInline then
  begin
    // El adaptador ya fijo pivote y atributos (color) de la linea y
    // valido el tope de 20 tallas. La linea queda abierta para teclear
    // cantidades; nueva linea con el boton 'Añadir línea'.
    // Estado con diagnostico: pivote y color leidos de la linea.
    if FCds.FieldByName('ID_AC_PIVOT').AsInteger > 0 then
      lblEstado.Caption := Format(
        '%s [pivote=%d, %s=%s]: teclea cantidades por talla',
        [ACodArt, FCds.FieldByName('ID_AC_PIVOT').AsInteger,
         Trim(FCds.FieldByName('ATTR1_NOMBRE').AsString),
         Trim(FCds.FieldByName('ATTR1_VALOR').AsString)])
    else
      lblEstado.Caption := ACodArt +
        ' sin tallas (pivote=0): cantidad en la columna Cantidad';
  end
  else if ACompleto then
  begin
    // SKU cerrado: consolidar la linea y dejar otra vacia lista para
    // encadenar la siguiente entrada (tecleo o lector).
    if FCds.State in [dsEdit, dsInsert] then
      FCds.Post;
    lblEstado.Caption := 'Resuelto: ' + ASku + ' — ' + ADescripcion;
    AnadirLineaVacia;
    FModo.MostrarEditor;
  end
  else
    lblEstado.Caption := 'Falta color/talla de ' + ACodArt;
end;

end.
