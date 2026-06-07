{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoMovimientosAlmacen                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de movimientos de almacen.                                  }
{    Entradas, salidas y traspasos entre almacenes.                            }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista.        }
{******************************************************************************}
unit inMtoMovimientosAlmacen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, Vcl.ComCtrls,
  UniDataMovimientosAlmacen, UniDataPerfiles, MemDS, DBAccess, Uni,
  cxCheckBox, cxCheckComboBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs, System.Actions, Vcl.ActnList;

type
  TfrmMtoMovimientosAlmacen = class(TfrmMtoGen)
    cxGrdDBTabPrinNUMERO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_MOVIMIENTO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_COSTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_MEDIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PROVEEDOR_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLOTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CADUCIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    colMovTipoCantidad: TcxGridDBColumn;
    ActionList1: TActionList;
    Action1: TAction;
    btnIraArticulo: TcxButton;
    pnlFiltros: TPanel;
    btnToggleFiltros: TcxButton;
    pnlContFiltros: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    procedure Action1Execute(Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnToggleFiltrosClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Guarda contra reentrada mientras inicializamos los combos desde el
    // perfil (si no, cada marca dispara una reapertura del SQL).
    FFiltrosCargando: Boolean;
    // La carga inicial con barra de progreso se hace una sola vez.
    FCargaInicialHecha: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    dmmMovimientosAlmacen: TdmMovimientosAlmacen;
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function  ConstruirWhereMovimientos: string;
    function  ConstruirSqlMovimientos: string;
    function  ContarMovimientos: Integer;
    procedure AplicarFiltrosMovimientos;
    procedure AbrirConProgreso;
    procedure MostrarProgresoCarga(const AMax: Integer);
    procedure ActualizarProgresoCarga(const APos, AMax: Integer);
    procedure OcultarProgresoCarga;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

var
  frmMtoMovimientosAlmacen: TfrmMtoMovimientosAlmacen;

implementation

uses
  inLibWin, inLibUser, inMtoPrincipal, inLibShowMto, inLibGridCantidad;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoMovimientosAlmacen }

procedure TfrmMtoMovimientosAlmacen.Action1Execute(Sender: TObject);
begin
  inherited;
    btnIraArticuloClick(Sender)
end;

procedure TfrmMtoMovimientosAlmacen.btnIraArticuloClick(Sender: TObject);
var
  sCodArt: string;
  vw: TcxCustomGridView;
  dbView: TcxGridDBTableView;
  colArticulo: TcxGridDBColumn;
begin
  inherited;
  sCodArt := '';
  vw := cxGrdPrincipal.FocusedView;
  if (vw <> nil) and (vw is TcxGridDBTableView) then
  begin
    dbView := TcxGridDBTableView(vw);
    colArticulo := dbView.GetColumnByFieldName('CODIGO_ART_MOV');
    if Assigned(colArticulo) and
       Assigned(dbView.Controller.FocusedRecord) then
      sCodArt := VarToStr(
        dbView.Controller.FocusedRecord.Values[colArticulo.Index]);
  end;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

procedure TfrmMtoMovimientosAlmacen.CrearTablaPrincipal;
begin
  inherited;
  dmmMovimientosAlmacen := tdmDataModule as TdmMovimientosAlmacen;
  // Cantidad del movimiento con decimales segun la unidad del articulo.
  VincularCantidadGrid(
    cxGrdDBTabPrin.GetColumnByFieldName('CANTIDAD_MOV'),
    cxGrdDBTabPrin.GetColumnByFieldName('TIPO_CANTIDAD_ART'));
  pkFieldName := 'NUMERO_MOV';
  // Persiana de filtros de carga: arranca colapsada (igual que el Mto de
  // articulos); se despliega al pulsar la cabecera.
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := #9654'  Filtros de carga';
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. NO
  // abrimos aqui: la query esta Active=False en su .dfm y la apertura con
  // barra de progreso se hace en ResetForm, ya con el form visible.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  if Assigned(dmmMovimientosAlmacen) and
     Assigned(dmmMovimientosAlmacen.unqryTablaG) then
    dmmMovimientosAlmacen.unqryTablaG.SQL.Text := ConstruirSqlMovimientos;
end;

procedure TfrmMtoMovimientosAlmacen.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales (la de busqueda Ctrl+A la maneja PrepararBusquedaExterna).
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.CargarAnyosFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmMovimientosAlmacen.unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_MOV) AS ANYO ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE FECHA_MOV IS NOT NULL ' +
      ' ORDER BY ANYO DESC';
    qry.Open;
    while not qry.Eof do
    begin
      item := ccbFiltroAnyo.Properties.Items.Add;
      item.Description := qry.FieldByName('ANYO').AsString;
      if item.Description = sAnyoActual then
        bExisteActual := True;
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
  // El año en curso es el valor por defecto: lo añadimos aunque no tenga
  // movimientos todavia para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.CargarAlmacenesFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
begin
  ccbFiltroAlmacen.Properties.Items.Clear;
  if FCodigosAlmacen = nil then
    FCodigosAlmacen := TStringList.Create
  else
    FCodigosAlmacen.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmMovimientosAlmacen.unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    qry.Open;
    while not qry.Eof do
    begin
      item := ccbFiltroAlmacen.Properties.Items.Add;
      item.Description := qry.FieldByName('CODIGO_ALM_ALM').AsString +
                          ' - ' + qry.FieldByName('NOMBRE_ALM_ALM').AsString;
      FCodigosAlmacen.Add(qry.FieldByName('CODIGO_ALM_ALM').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoMovimientosAlmacen.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  FFiltrosCargando := True;
  try
    // Por defecto: año en curso marcado; ningun almacen marcado (= todos).
    sAnyosCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAnyos',
                                   IntToStr(YearOf(Date)));
    sAlmCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacenes', '');
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sAnyosCsv;
      for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      begin
        if lst.IndexOf(ccbFiltroAnyo.Properties.Items[i].Description) >= 0 then
          ccbFiltroAnyo.States[i] := cbsChecked
        else
          ccbFiltroAnyo.States[i] := cbsUnchecked;
      end;
      lst.DelimitedText := sAlmCsv;
      for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      begin
        if (i < FCodigosAlmacen.Count) and
           (lst.IndexOf(FCodigosAlmacen[i]) >= 0) then
          ccbFiltroAlmacen.States[i] := cbsChecked
        else
          ccbFiltroAlmacen.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosCargando := False;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  if Assigned(ccbFiltroAnyo) then
  begin
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    sAnyos := '';
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
    begin
      if ccbFiltroAnyo.States[i] = cbsChecked then
      begin
        if sAnyos <> '' then
          sAnyos := sAnyos + ';';
        sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
      end;
    end;
    item.SubKey := 'oFiltroAnyos';
    item.Value := sAnyos;
    oList.Add(item);
    sAlmacenes := '';
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
    begin
      if (ccbFiltroAlmacen.States[i] = cbsChecked) and
         (i < FCodigosAlmacen.Count) then
      begin
        if sAlmacenes <> '' then
          sAlmacenes := sAlmacenes + ';';
        sAlmacenes := sAlmacenes + FCodigosAlmacen[i];
      end;
    end;
    item.SubKey := 'oFiltroAlmacenes';
    item.Value := sAlmacenes;
    oList.Add(item);
  end;
end;

function TfrmMtoMovimientosAlmacen.ConstruirWhereMovimientos: string;
var
  sAnyos, sAlm: string;
  i: Integer;
begin
  // Años marcados -> IN sobre YEAR(m.FECHA_MOV). Sin nada marcado = todos.
  sAnyos := '';
  for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
  begin
    if ccbFiltroAnyo.States[i] = cbsChecked then
    begin
      if sAnyos <> '' then
        sAnyos := sAnyos + ', ';
      sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
    end;
  end;
  // Almacenes marcados -> IN de codigos sobre m.CODIGO_ALM_MOV.
  sAlm := '';
  for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
  begin
    if (ccbFiltroAlmacen.States[i] = cbsChecked) and
       (i < FCodigosAlmacen.Count) then
    begin
      if sAlm <> '' then
        sAlm := sAlm + ', ';
      sAlm := sAlm + QuotedStr(FCodigosAlmacen[i]);
    end;
  end;
  Result := ' WHERE 1 = 1';
  if sAnyos <> '' then
    Result := Result + ' AND YEAR(m.FECHA_MOV) IN (' + sAnyos + ')';
  if sAlm <> '' then
    Result := Result + ' AND m.CODIGO_ALM_MOV IN (' + sAlm + ')';
end;

function TfrmMtoMovimientosAlmacen.ConstruirSqlMovimientos: string;
begin
  // Conserva el JOIN con articulos (TIPO_CANTIDAD_ART) que usa el grid para
  // pintar la cantidad con los decimales correctos.
  Result := 'SELECT m.*, a.TIPO_CANTIDAD_ART ' +
            'FROM fza_movimientos_almacen m ' +
            'LEFT JOIN fza_articulos a ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV' +
            ConstruirWhereMovimientos +
            ' ORDER BY m.FECHA_MOV DESC';
end;

function TfrmMtoMovimientosAlmacen.ContarMovimientos: Integer;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmMovimientosAlmacen.unqryTablaG.Connection;
    qry.SQL.Text := 'SELECT COUNT(*) AS N FROM fza_movimientos_almacen m' +
                    ConstruirWhereMovimientos;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.Fields[0].AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoMovimientosAlmacen.AplicarFiltrosMovimientos;
var
  qry: TUniQuery;
  sSql: string;
begin
  if Assigned(dmmMovimientosAlmacen) and
     Assigned(dmmMovimientosAlmacen.unqryTablaG) then
  begin
    qry := dmmMovimientosAlmacen.unqryTablaG;
    sSql := ConstruirSqlMovimientos;
    if Trim(qry.SQL.Text) <> Trim(sSql) then
    begin
      qry.SQL.Text := sSql;
      AbrirConProgreso;
    end;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
var
  qry: TUniQuery;
  nTotal, nLeidos: Integer;
  cursorPrev: TCursor;
begin
  if Assigned(dmmMovimientosAlmacen) and
     Assigned(dmmMovimientosAlmacen.unqryTablaG) then
  begin
    qry := dmmMovimientosAlmacen.unqryTablaG;
    cursorPrev := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    MostrarProgresoCarga(0);
    // FetchRows define el tamaño de bloque; al recorrer, UniDAC trae los
    // registros por bloques (FetchAll por defecto es False) y vamos
    // avanzando la barra. DisableControls evita que el grid fuerce el
    // fetch completo de golpe. FetchRows solo se puede fijar con la query
    // cerrada, asi que lo dejamos puesto (no se restaura).
    qry.DisableControls;
    try
      nTotal := ContarMovimientos;
      if Assigned(FbarProgreso) then
      begin
        if nTotal > 0 then
          FbarProgreso.Max := nTotal
        else
          FbarProgreso.Max := 1;
      end;
      qry.Close;
      qry.FetchRows := TAM_BLOQUE;
      qry.Open;
      nLeidos := 0;
      qry.First;
      while not qry.Eof do
      begin
        Inc(nLeidos);
        if (nLeidos mod 200) = 0 then
          ActualizarProgresoCarga(nLeidos, nTotal);
        qry.Next;
      end;
      qry.First;
    finally
      qry.EnableControls;
      OcultarProgresoCarga;
      Screen.Cursor := cursorPrev;
    end;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.MostrarProgresoCarga(const AMax: Integer);
begin
  if FPnlProgreso = nil then
  begin
    FPnlProgreso := TPanel.Create(Self);
    FPnlProgreso.Parent := Self;
    FPnlProgreso.BevelOuter := bvLowered;
    FPnlProgreso.ParentBackground := False;
    FPnlProgreso.Color := clWindow;
    FPnlProgreso.Width := 340;
    FPnlProgreso.Height := 96;
    FlblProgreso := TcxLabel.Create(Self);
    FlblProgreso.Parent := FPnlProgreso;
    FlblProgreso.Left := 16;
    FlblProgreso.Top := 18;
    FlblProgreso.Style.Font.Style := [fsBold];
    FbarProgreso := TProgressBar.Create(Self);
    FbarProgreso.Parent := FPnlProgreso;
    FbarProgreso.Left := 16;
    FbarProgreso.Top := 52;
    FbarProgreso.Width := 308;
    FbarProgreso.Height := 22;
  end;
  FbarProgreso.Min := 0;
  if AMax > 0 then
    FbarProgreso.Max := AMax
  else
    FbarProgreso.Max := 1;
  FbarProgreso.Position := 0;
  FlblProgreso.Caption := 'Cargando movimientos...';
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmMtoMovimientosAlmacen.ActualizarProgresoCarga(const APos,
                                                            AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := 'Cargando movimientos: ' +
                            FormatFloat('#,##0', APos) + ' / ' +
                            FormatFloat('#,##0', AMax);
    Application.ProcessMessages;
  end;
end;

procedure TfrmMtoMovimientosAlmacen.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

procedure TfrmMtoMovimientosAlmacen.btnToggleFiltrosClick(Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  pnlContFiltros.Visible := not pnlContFiltros.Visible;
  if pnlContFiltros.Visible then
  begin
    pnlFiltros.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltros.Caption := #9660'  Filtros de carga';
  end
  else
  begin
    pnlFiltros.Height := ALTO_CABECERA;
    btnToggleFiltros.Caption := #9654'  Filtros de carga';
  end;
end;

procedure TfrmMtoMovimientosAlmacen.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosMovimientos;
end;

procedure TfrmMtoMovimientosAlmacen.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosMovimientos;
end;

procedure TfrmMtoMovimientosAlmacen.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+A): sin filtros de carga para localizar el
  // movimiento sea del año/almacen que sea.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  if Assigned(dmmMovimientosAlmacen) and
     Assigned(dmmMovimientosAlmacen.unqryTablaG) then
    dmmMovimientosAlmacen.unqryTablaG.SQL.Text := ConstruirSqlMovimientos;
  pnlContFiltros.Visible := False;
  pnlFiltros.Height := 22;
  btnToggleFiltros.Caption := #9654'  Filtros de carga';
  inherited;
end;

procedure TfrmMtoMovimientosAlmacen.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  pnlFiltros.Visible := False;
end;

procedure TfrmMtoMovimientosAlmacen.FormDestroy(Sender: TObject);
begin
  inherited;
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  ForceReferenceToClass(TfrmMtoMovimientosAlmacen);
end.
