{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOperacionesHist                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de operaciones de caja.                                         }
{    Consulta de tickets y operaciones realizadas en el TPV.                   }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista.        }
{******************************************************************************}
unit inMtoCajaOperacionesHist;

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
  UniDataCajaOperacionesHist, UniDataPerfiles, MemDS, DBAccess, Uni,
  cxCheckBox, cxCheckComboBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs;

type
  TfrmMtoCajaOperacionesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_DEVOLUCION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_DEVUELTO_ACUM_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_REF_ORIGEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_REF_ORIGEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinMOTIVO_DEVOLUCION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_CONTRA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinES_TRASPASO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARQUEO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    pnlFiltrosCaja: TPanel;
    btnToggleFiltrosCaja: TcxButton;
    pnlContFiltrosCaja: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure btnToggleFiltrosCajaClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Guarda contra reentrada: bloquea el OnCloseUp de los combos mientras
    // inicializamos sus estados desde el perfil (si no, cada marca dispara
    // una reapertura del SQL).
    FFiltrosCargando: Boolean;
    // La carga inicial con barra de progreso se hace una sola vez (en el
    // primer Show); las siguientes aperturas son por cambio de filtro.
    FCargaInicialHecha: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items: el combo
    // muestra "código - nombre" pero el filtro usa solo el código.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente la primera vez).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    dmmCajaOperacionesHist: TdmCajaOperacionesHist;
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function  ConstruirWhereOperaciones: string;
    function  ConstruirSqlOperaciones: string;
    function  ContarOperaciones: Integer;
    procedure AplicarFiltrosOperaciones;
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
  frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist;

implementation

uses
  inLibWin, inLibUser, inMtoPrincipal, inMtoModalImpOperaciones;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaOperacionesHist }

procedure TfrmMtoCajaOperacionesHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintOperaciones;
begin
  inherited;
  // Informe A4 horizontal (FastReport) de las operaciones de caja. El
  // usuario filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintOperaciones.Create(Application);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaOperacionesHist := tdmDataModule as TdmCajaOperacionesHist;
  pkFieldName := 'CODIGO_EMP_OPCAJA;CODIGO_ALM_OPCAJA;' +
                 'CODIGO_CAJA_OPCAJA;NUMERO_OPERACION_OPCAJA';
  // Persiana de filtros de carga: arranca colapsada (igual que el Mto de
  // articulos); se despliega al pulsar la cabecera.
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. NO
  // abrimos aqui: la query esta Active=False en su .dfm y la apertura con
  // barra de progreso se hace en ResetForm, ya con el form visible.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
    dmmCajaOperacionesHist.unqryTablaG.SQL.Text := ConstruirSqlOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales. En la instancia de busqueda (Ctrl+A) la apertura la maneja
  // PrepararBusquedaExterna + AbrirTablaPrincipalSincrono.
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAnyosFiltro;
var
  qry: TUniQuery;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  // Años distintos presentes en el historico (descendente). Es un unico
  // escaneo que devuelve pocas filas, mucho mas barato que traer la tabla
  // entera, y permite ofrecer al usuario solo los años con datos.
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_OPERACION_OPCAJA) AS ANYO ' +
      '  FROM fza_caja_operaciones ' +
      ' WHERE FECHA_OPERACION_OPCAJA IS NOT NULL ' +
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
  // El año en curso es el valor por defecto del filtro: lo añadimos aunque
  // todavia no tenga operaciones para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAlmacenesFiltro;
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
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
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

procedure TfrmMtoCajaOperacionesHist.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  // FFiltrosCargando evita que cada asignacion de States dispare el
  // OnCloseUp y reabra el SQL mientras inicializamos.
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

procedure TfrmMtoCajaOperacionesHist.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  // Volcamos los filtros al batch de sbGrabarGridClick para que se graben
  // junto al resto de preferencias del Mto, respetando el ambito elegido.
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

function TfrmMtoCajaOperacionesHist.ConstruirWhereOperaciones: string;
var
  sAnyos, sAlm: string;
  i: Integer;
begin
  // Años marcados -> lista IN sobre YEAR(FECHA_OPERACION_OPCAJA). Si no hay
  // ninguno marcado no se filtra por año (salen todos).
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
  // Almacenes marcados -> lista IN de codigos. Sin nada marcado = todos.
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
    Result := Result +
              ' AND YEAR(FECHA_OPERACION_OPCAJA) IN (' + sAnyos + ')';
  if sAlm <> '' then
    Result := Result + ' AND CODIGO_ALM_OPCAJA IN (' + sAlm + ')';
end;

function TfrmMtoCajaOperacionesHist.ConstruirSqlOperaciones: string;
begin
  Result := 'SELECT * FROM fza_caja_operaciones' +
            ConstruirWhereOperaciones +
            ' ORDER BY FECHA_OPERACION_OPCAJA DESC';
end;

function TfrmMtoCajaOperacionesHist.ContarOperaciones: Integer;
var
  qry: TUniQuery;
begin
  // Total de filas con el filtro activo: alimenta el Max de la barra de
  // progreso para que avance "segun el nro de registros".
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := dmmCajaOperacionesHist.unqryTablaG.Connection;
    qry.SQL.Text := 'SELECT COUNT(*) AS N FROM fza_caja_operaciones' +
                    ConstruirWhereOperaciones;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.Fields[0].AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarFiltrosOperaciones;
var
  qry: TUniQuery;
  sSql: string;
begin
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    qry := dmmCajaOperacionesHist.unqryTablaG;
    sSql := ConstruirSqlOperaciones;
    if Trim(qry.SQL.Text) <> Trim(sSql) then
    begin
      qry.SQL.Text := sSql;
      AbrirConProgreso;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
var
  qry: TUniQuery;
  nTotal, nLeidos, nFetchRowsPrev: Integer;
  cursorPrev: TCursor;
begin
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    qry := dmmCajaOperacionesHist.unqryTablaG;
    cursorPrev := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    // Mostramos el overlay antes del COUNT para que el usuario tenga
    // feedback tambien durante el conteo previo.
    MostrarProgresoCarga(0);
    // FetchRows define el tamaño de bloque; al recorrer, UniDAC trae los
    // registros por bloques (FetchAll por defecto es False) y vamos
    // avanzando la barra. Un FetchRows grande evita miles de round-trips
    // (el valor por defecto de 25 seria lento). DisableControls evita que
    // el grid fuerce el fetch completo y nos quite el progreso.
    nFetchRowsPrev := qry.FetchRows;
    qry.DisableControls;
    try
      nTotal := ContarOperaciones;
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
      qry.FetchRows := nFetchRowsPrev;
      qry.EnableControls;
      OcultarProgresoCarga;
      Screen.Cursor := cursorPrev;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.MostrarProgresoCarga(const AMax: Integer);
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
  FlblProgreso.Caption := 'Cargando operaciones...';
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmMtoCajaOperacionesHist.ActualizarProgresoCarga(const APos,
                                                             AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := 'Cargando operaciones: ' +
                            FormatFloat('#,##0', APos) + ' / ' +
                            FormatFloat('#,##0', AMax);
    Application.ProcessMessages;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

procedure TfrmMtoCajaOperacionesHist.btnToggleFiltrosCajaClick(
                                                            Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  // Persiana: alterna visibilidad y altura del contenedor de filtros.
  pnlContFiltrosCaja.Visible := not pnlContFiltrosCaja.Visible;
  if pnlContFiltrosCaja.Visible then
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltrosCaja.Caption := #9660'  Filtros de carga';
  end
  else
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA;
    btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+A): sin filtros de carga, asi el Locate
  // encuentra la operacion sea del año/almacen que sea. Reseteamos los
  // combos y el SQL antes de que inherited añada el WHERE de la PK.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
    dmmCajaOperacionesHist.unqryTablaG.SQL.Text := ConstruirSqlOperaciones;
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := #9654'  Filtros de carga';
  inherited;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  // La instancia de busqueda llega directa a la ficha; el panel de filtros
  // de carga no aplica.
  pnlFiltrosCaja.Visible := False;
end;

procedure TfrmMtoCajaOperacionesHist.FormDestroy(Sender: TObject);
begin
  inherited;
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaOperacionesHist);
end.
