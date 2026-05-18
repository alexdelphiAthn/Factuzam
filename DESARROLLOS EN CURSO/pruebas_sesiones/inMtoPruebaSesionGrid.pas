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
  UniDataComprasSesiones, cxBlobEdit, dxShellDialogs, cxRadioGroup, Vcl.Buttons;

const
  // Numero maximo de columnas de talla inline. 15 cubre con holgura los
  // conjuntos habituales (tallas ropa 38-46 = 5; calzado EU 36-46 = 11;
  // tallas niño/adulto extendidas hasta ~12). Si en algun escenario hace
  // falta mas, sube esta constante y anyade columnas en el DFM con el
  // mismo patron Tag = 1..N.
  CANT_TALLAS_MAX = 15;

type
  TPosConjunto = record
    IdAv  : Integer;
    Valor : string;
  end;
  TArrPosConjunto = TArray<TPosConjunto>;

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

    // ------------------------------------------------------------------
    // Eventos
    // ------------------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddLineaClick(Sender: TObject);
    procedure btnDelLineaClick(Sender: TObject);
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
    procedure dbcLinColorBasicoPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure dbcLinPrecioCompraPropertiesEditValueChanged(Sender: TObject);
    procedure dbcLinTallasPropertiesEditValueChanged(Sender: TObject);
  private
    FTallaColumns : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FConjuntoPos  : TDictionary<Integer, TArrPosConjunto>;
                    // ID_AC -> posiciones ordenadas (IdAv, Valor)
    FBasicosColor : TArray<string>;
    FBmpSwatch    : TBitmap;
    function  Dmm: TdmComprasSesiones;
    procedure CargarBasicosColor;
    procedure CrearColumnasTallas;
    procedure TallaCellEditValueChanged(Sender: TObject);
    function  GetPosicionesConjunto(AIdAc: Integer): TArrPosConjunto;
    function  MaxLongConjuntosSesion: Integer;
    procedure RecalcularColumnasTallasDocumento;
    procedure ActualizarCaptionsTallasLineaActiva;
    procedure CargarCantidadesTodasLineas;
    procedure CargarCantidadesUnaLinea(ARecordIndex: Integer; ALinea: Integer);
    procedure PersistirCantidad(ALinea, AIdAv: Integer; ACantidad: Double);
    procedure RefrescarTotalesLinea(ALinea: Integer);
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
  inMtoModalSelFamilia;

const
  fIdVaColor = 'CO';

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

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
                                                    Dmm.dsAtributosConjuntos;

  with Dmm do
  begin
    unqrySesionLin.MasterFields := 'SERIE_SES;NUMERO_SES';
    unqrySesionLin.MasterSource := dsTablaG;
    if not unqrySesionLin.Active then unqrySesionLin.Open;
    if not unqrySesionCel.Active then unqrySesionCel.Open;
  end;
  tvLineas.DataController.DataSource := Dmm.dsSesionLin;

  RecalcularColumnasTallasDocumento;
  CargarCantidadesTodasLineas;
end;

procedure TfrmMtoPruebaSesionGrid.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoPruebaSesionGrid.FormCreate(Sender: TObject);
begin
  inherited;
  FBmpSwatch    := TBitmap.Create;
  FConjuntoPos  := TDictionary<Integer, TArrPosConjunto>.Create;
  CargarBasicosColor;
  CrearColumnasTallas;
end;

procedure TfrmMtoPruebaSesionGrid.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FConjuntoPos);
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
  // OnEditValueChanged actualiza fza_compras_sesiones_celdas.
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
    // Unbound: sin DataBinding.FieldName, valor float en la cache del grid
    col.DataBinding.ValueTypeClass := TcxFloatValueType;
    curProps := TcxCurrencyEditProperties(
                  col.CreateProperties(TcxCurrencyEditProperties));
    curProps.DisplayFormat := '#,##0';
    curProps.OnEditValueChanged := TallaCellEditValueChanged;
    col.PropertiesClass := TcxCurrencyEditProperties;
    FTallaColumns[i] := col;
  end;
end;

function TfrmMtoPruebaSesionGrid.GetPosicionesConjunto(AIdAc: Integer)
  : TArrPosConjunto;
var
  q      : TUniQuery;
  arr    : TArrPosConjunto;
  i      : Integer;
  posReg : TPosConjunto;
begin
  // Devuelve la lista ordenada de (ID_AV, VALOR) del conjunto pivot
  // indicado. Cacheado en FConjuntoPos para no re-consultar en cada
  // refresco de la matriz.
  if AIdAc <= 0 then Exit(nil);
  if FConjuntoPos.TryGetValue(AIdAc, Result) then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT ACD.ID_AV_ACD, AV.AV AS VALOR ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :p ' +
      ' ORDER BY ACD.ORDEN_ACD, AV.AV';
    q.ParamByName('p').AsInteger := AIdAc;
    q.Open;
    SetLength(arr, q.RecordCount);
    i := 0;
    while not q.Eof do
    begin
      posReg.IdAv  := q.FieldByName('ID_AV_ACD').AsInteger;
      posReg.Valor := q.FieldByName('VALOR').AsString;
      arr[i] := posReg;
      Inc(i);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  FConjuntoPos.Add(AIdAc, arr);
  Result := arr;
end;

function TfrmMtoPruebaSesionGrid.MaxLongConjuntosSesion: Integer;
var
  q     : TUniQuery;
  arr   : TArrPosConjunto;
  iIdAc : Integer;
begin
  // Recorre los ID_AC_PIVOT_SESLIN distintos de la sesion en curso y
  // devuelve el numero maximo de valores entre ellos. Define cuantas
  // columnas TALLA se muestran en el grid.
  Result := 0;
  if Dmm.unqryTablaG.IsEmpty then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT DISTINCT ID_AC_PIVOT_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND ID_AC_PIVOT_SESLIN IS NOT NULL';
    q.ParamByName('s').AsString :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    while not q.Eof do
    begin
      iIdAc := q.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
      arr := GetPosicionesConjunto(iIdAc);
      if Length(arr) > Result then Result := Length(arr);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  if Result > CANT_TALLAS_MAX then Result := CANT_TALLAS_MAX;
end;

procedure TfrmMtoPruebaSesionGrid.RecalcularColumnasTallasDocumento;
var
  i, iMax : Integer;
begin
  // Muestra las primeras iMax columnas y oculta el resto. iMax = max
  // valores entre los conjuntos referenciados por alguna linea de la
  // sesion. Captions iniciales: 'Talla 1', 'Talla 2'... — se sobrescriben
  // al cambiar la fila activa con los valores del conjunto en curso.
  iMax := MaxLongConjuntosSesion;
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    if FTallaColumns[i] = nil then Continue;
    FTallaColumns[i].Visible := (i < iMax);
    if i < iMax then
      FTallaColumns[i].Caption := 'Talla ' + IntToStr(i + 1);
  end;
end;

procedure TfrmMtoPruebaSesionGrid.ActualizarCaptionsTallasLineaActiva;
var
  ds   : TDataSet;
  iAc  : Integer;
  arr  : TArrPosConjunto;
  i    : Integer;
begin
  // Cuando el foco entra en una linea, los rotulos de las columnas TALLA
  // se actualizan al conjunto de esa linea (las primeras N posiciones).
  // El resto queda con la caption generica 'Talla N+1' para indicar que
  // no aplica al sistema de la linea activa.
  ds := Dmm.unqrySesionLin;
  if (ds = nil) or ds.IsEmpty then Exit;
  iAc := ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  arr := GetPosicionesConjunto(iAc);
  for i := 0 to CANT_TALLAS_MAX - 1 do
  begin
    if FTallaColumns[i] = nil then Continue;
    if not FTallaColumns[i].Visible then Continue;
    if i < Length(arr) then
      FTallaColumns[i].Caption := arr[i].Valor
    else
      FTallaColumns[i].Caption := 'Talla ' + IntToStr(i + 1);
  end;
end;

procedure TfrmMtoPruebaSesionGrid.CargarCantidadesTodasLineas;
var
  i, iLinea : Integer;
  ds        : TDataSet;
begin
  // Recorre todas las lineas de la sesion y vuelca las cantidades de
  // fza_compras_sesiones_celdas a las celdas no-bound del grid.
  // Se llama al abrir la sesion y al cambiar de cabecera.
  if Dmm = nil then Exit;
  ds := Dmm.unqrySesionLin;
  if (ds = nil) or not ds.Active then Exit;
  for i := 0 to tvLineas.DataController.RecordCount - 1 do
  begin
    iLinea := tvLineas.DataController.Values[
                i,
                dbcLinCodArt.Index];  // truco: leemos por columna conocida
    // El metodo Values[record, colIdx] devuelve Variant; necesitamos
    // LINEA_SESLIN concretamente. Como las columnas talla son no-bound,
    // recurrimos al DataSet del record:
    if not ds.IsEmpty then
    begin
      // Mover el DataSet al record idx i y leer LINEA_SESLIN
      ds.RecNo := i + 1;
      iLinea := ds.FieldByName('LINEA_SESLIN').AsInteger;
      if iLinea > 0 then
        CargarCantidadesUnaLinea(i, iLinea);
    end;
  end;
end;

procedure TfrmMtoPruebaSesionGrid.CargarCantidadesUnaLinea(
  ARecordIndex: Integer; ALinea: Integer);
var
  q       : TUniQuery;
  iAc     : Integer;
  arr     : TArrPosConjunto;
  i       : Integer;
  iIdAv   : Integer;
  rCant   : Double;
begin
  // Lee las celdas existentes de la linea en SESCEL y las publica en
  // las columnas no-bound del grid por posicion (segun el orden del
  // conjunto pivot de esa misma linea).
  iAc := Dmm.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  arr := GetPosicionesConjunto(iAc);
  if Length(arr) = 0 then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT ID_AV_PIVOT_SESCEL, SUM(CANTIDAD_SESCEL) AS TOTAL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l ' +
      ' GROUP BY ID_AV_PIVOT_SESCEL';
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := ALinea;
    q.Open;
    while not q.Eof do
    begin
      iIdAv := q.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
      rCant := q.FieldByName('TOTAL').AsFloat;
      for i := 0 to High(arr) do
        if arr[i].IdAv = iIdAv then
        begin
          if FTallaColumns[i] <> nil then
            tvLineas.DataController.Values[
              ARecordIndex, FTallaColumns[i].Index] := rCant;
          Break;
        end;
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

// ===========================================================================
//   Persistencia de cantidades
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.PersistirCantidad(ALinea, AIdAv: Integer;
                                                   ACantidad: Double);
var
  q      : TUniQuery;
  sAlm   : string;
begin
  // Upsert en fza_compras_sesiones_celdas con ID_FILA = 1 (la prueba
  // trabaja con una fila por linea). Si ACantidad <= 0, borra la celda.
  // CODIGO_ALM_SESCEL = '' para usar el almacen de la cabecera al
  // materializar (la prueba no expone selector de almacen).
  if Dmm.unqryTablaG.IsEmpty then Exit;
  if ALinea <= 0 then Exit;
  if AIdAv <= 0 then Exit;
  sAlm := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    if ACantidad <= 0 then
    begin
      q.SQL.Text :=
        'DELETE FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :l AND ID_FILA_SES_SESCEL = 1 ' +
        '   AND ID_AV_PIVOT_SESCEL = :p AND CODIGO_ALM_SESCEL = :a';
    end
    else
    begin
      q.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
        '   ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL, CODIGO_ALM_SESCEL, ' +
        '   CANTIDAD_SESCEL, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:s, :n, :l, 1, :p, :a, :c, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_SESCEL = :c, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      q.ParamByName('c').AsFloat  := ACantidad;
      q.ParamByName('u').AsString := oUser;
    end;
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('p').AsInteger := AIdAv;
    q.ParamByName('a').AsString  := sAlm;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmMtoPruebaSesionGrid.RefrescarTotalesLinea(ALinea: Integer);
var
  q     : TUniQuery;
  rTot  : Double;
  rPr   : Double;
  ds    : TDataSet;
begin
  if Dmm.unqrySesionLin.IsEmpty then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) AS TOTAL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  :=
      Dmm.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      Dmm.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := ALinea;
    q.Open;
    rTot := q.FieldByName('TOTAL').AsFloat;
  finally
    FreeAndNil(q);
  end;
  ds := Dmm.unqrySesionLin;
  rPr := ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
  ds.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := rTot;
  ds.FieldByName('TOTAL_LINEA_SESLIN').AsFloat    := rTot * rPr;
  ds.Post;
end;

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
  if Dmm.unqryTablaG.State in [dsInsert, dsEdit] then
    Dmm.unqryTablaG.Post;
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
    PersistirCantidad(iLinea, -1, 0); // no hace nada; placeholder
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
  RecalcularColumnasTallasDocumento;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  frmSel : TfrmModalSelFamilia;
  ds     : TDataSet;
begin
  inherited;
  if (Key <> VK_F3) or (Shift <> []) then Exit;
  if not Assigned(AItem) then Exit;
  if AItem <> dbcLinFamilia then Exit;

  frmSel := TfrmModalSelFamilia.Create(Self);
  try
    if frmSel.ShowModal = mrOk then
    begin
      ds := Dmm.unqrySesionLin;
      if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;
      ds.FieldByName('CODIGO_FAM_SESLIN').AsString := frmSel.CodigoFamilia;
      if ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString = '' then
        ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString :=
                                                          frmSel.CodigoFamilia;
      if ds.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
        ds.FieldByName('DESCRIPCION_SESLIN').AsString := frmSel.NombreFamilia;
    end;
  finally
    FreeAndNil(frmSel);
  end;
  Key := 0;
end;

procedure TfrmMtoPruebaSesionGrid.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarCaptionsTallasLineaActiva;
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
begin
  inherited;
  Col := nil;
  if AViewInfo.GridRecord = nil then Exit;
  if AViewInfo.Item is TcxGridColumn then
    Col := TcxGridColumn(AViewInfo.Item);
  if Col <> dbcLinColorBasico then Exit;

  AvActual := VarToStr(AViewInfo.GridRecord.Values[Col.Index]);
  if Trim(AvActual) = '' then Exit;

  Info := Default(TInfoBasico);
  if not ObtenerInfoBasico(fIdVaColor, AvActual, Info) then Exit;
  if not Info.EsValido then Exit;
  if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info) then
    ADone := True;
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
  if Dmm.unqrySesionLin.State in [dsEdit, dsInsert] then
    Dmm.unqrySesionLin.Post;
  // El conjunto pivot de la linea ha cambiado: hay que recalcular el
  // max-del-documento y actualizar captions a las del nuevo conjunto.
  RecalcularColumnasTallasDocumento;
  ActualizarCaptionsTallasLineaActiva;
end;

// ===========================================================================
//   Edicion inline de celdas TALLA
// ===========================================================================

procedure TfrmMtoPruebaSesionGrid.TallaCellEditValueChanged(Sender: TObject);
var
  ed          : TcxCustomEdit;
  edController: TcxCustomGridTableController;
  iCol        : Integer;
  col         : TcxGridColumn;
  iLinea, iAc : Integer;
  arr         : TArrPosConjunto;
  iPos        : Integer;
  rCant       : Double;
  vEdit       : Variant;
begin
  inherited;
  if not (Sender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(Sender);
  ed.PostEditValue;

  edController := tvLineas.Controller;
  col := edController.FocusedColumn;
  if col = nil then Exit;
  iPos := col.Tag;  // posicion 1..N en el conjunto
  if (iPos < 1) or (iPos > CANT_TALLAS_MAX) then Exit;

  if Dmm.unqrySesionLin.IsEmpty then Exit;
  iLinea := Dmm.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  iAc    := Dmm.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  arr := GetPosicionesConjunto(iAc);
  if iPos > Length(arr) then Exit;       // posicion fuera del sistema

  vEdit := ed.EditValue;
  if VarIsNull(vEdit) or VarIsClear(vEdit) then
    rCant := 0
  else
    rCant := vEdit;

  PersistirCantidad(iLinea, arr[iPos - 1].IdAv, rCant);
  RefrescarTotalesLinea(iLinea);
end;

initialization
  ForceReferenceToClass(TfrmMtoPruebaSesionGrid);
end.
