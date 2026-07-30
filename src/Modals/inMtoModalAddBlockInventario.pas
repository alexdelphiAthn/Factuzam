{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockInventario                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de carga masiva de SKUs en un inventario.                           }
{    Hereda de AddBlockBase y aplica filtros propios de inventario.            }
{******************************************************************************}
unit inMtoModalAddBlockInventario;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxClasses, cxContainer, cxEdit,
  cxLabel, cxButtons, cxTextEdit, cxCheckBox, cxRadioGroup,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inMtoModalAddBlockBase, cxLookAndFeelPainters, Vcl.Menus, cxFilter,
  cxCustomData, cxStyles, dxScrollbarAnnotations, cxTL, cxMaskEdit, cxDBData,
  cxCurrencyEdit, Vcl.ComCtrls, dxCore, cxDateUtils, JvComponentBase,
  JvEnterTab, cxLocalization, cxSplitter, cxSpinEdit, cxDropDownEdit,
  cxCalendar, cxCustomListBox, cxCheckListBox, cxGroupBox, cxInplaceContainer,
  cxDBTL, cxTLData, cxPC;

type
  TAddBlockInventarioResult = record
    Aceptado          : Boolean;
    NumLineas         : Integer;        // SKUs (lineas) insertadas
    NumArticulos      : Integer;        // articulos distintos cubiertos
    ArticulosCodigos  : TArray<string>;
    Empresa, Almacen, Serie, Nro: string;
  end;

  TfrmModalAddBlockInventario = class(TfrmModalAddBlockBase)
    lblInventarioInfo: TcxLabel;
    lblNotaCarga: TcxLabel;

    // Columnas extra del preview
    colPrevSkusConStock: TcxGridDBColumn;
    colPrevPMPActual: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);

  protected
    FResultadoInv : TAddBlockInventarioResult;
    FEmpresa, FAlmacen, FSerie, FNro: string;

    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    override;
    function  ColumnasSelectExtra: string; override;
    function  SubquerYaCargado: string; override;
    function  WhereExcluirYaCargados: string; override;
    procedure VincularParametrosExtra(AQry: TUniQuery); override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;

    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean; override;

  private
    function  ProximoNumeroLinea: Integer;
    procedure InsertarSkusConStockDelArticulo(AIns: TUniQuery;
                                              const ACodigoArticulo: string;
                                              var ALineaActual: Integer;
                                              var ANumLineas: Integer;
                                              const AUsuario: string);

  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const AEmpresa, AAlmacen, ASerie,
                                  ANro: string): TAddBlockInventarioResult;
    property ResultadoInv: TAddBlockInventarioResult read FResultadoInv;
  end;

implementation

{$R *.dfm}

uses
  inLibUser, inLibMsgArticulos;

class function TfrmModalAddBlockInventario.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ASerie, ANro: string): TAddBlockInventarioResult;
var
  frm: TfrmModalAddBlockInventario;
  i  : Integer;
begin
  frm := TfrmModalAddBlockInventario.Create(AOwner);
  try
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FSerie   := ASerie;
    frm.FNro     := ANro;
    frm.Inicializar(AConn);

    // Pre-marcar el almacen del inventario en la pestana de stock.
    // En inventario el filtro de stock se aplica SIEMPRE en el almacen
    // del propio inventario.
    for i := 0 to frm.chkLstAlmacenes.Items.Count - 1 do
      if (frm.chkLstAlmacenes.Items[i].ItemObject is TStringList) and
         (TStringList(frm.chkLstAlmacenes.Items[i].ItemObject).Count > 0) and
         (TStringList(
           frm.chkLstAlmacenes.Items[i].ItemObject)[0] = AAlmacen) then
      begin
        frm.chkLstAlmacenes.Items[i].Checked := True;
        Break;
      end;

    frm.lblInventarioInfo.Caption :=
      Format(SCaptionInventarioDestino,
             [AEmpresa, AAlmacen, ASerie, ANro]);

    frm.ShowModal;
    Result := frm.FResultadoInv;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockInventario.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Caption := STituloAnadirBloqueInventario;

  // En inventario el stock importa siempre — lo activamos por defecto
  chkSoloConStock.Checked := True;

  FResultadoInv.Aceptado := False;
end;

// ============================================================================
//   Overrides de la base
// ============================================================================

function TfrmModalAddBlockInventario.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := True;
  AMensaje := '';
  if (FEmpresa = '') or (FAlmacen = '') or (FSerie = '') or (FNro = '') then
  begin
    Result := False;
    AMensaje := SErrorDestinoInventarioAddBlock;
  end;
end;

function TfrmModalAddBlockInventario.ColumnasSelectExtra: string;
begin
  // Numero de SKUs con stock>0 en el almacen del inventario
  // y PMP medio del articulo en ese almacen (referencia visual).
  Result :=
    '(SELECT COUNT(DISTINCT s.CODIGO_UNIDAD_STK)' +
    '   FROM fza_articulos_stockactual s' +
    '   LEFT JOIN fza_articulos_skus sk' +
    '          ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK' +
    '  WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK)' +
    '        = a.CODIGO_ART_ART' +
    '    AND s.CODIGO_ALM_STK = :P_INV_ALMACEN' +
    '    AND s.CANTIDAD_STK > 0) AS NUM_SKUS_CON_STOCK, ' +

    '(SELECT AVG(s.PRECIO_MEDIO_STK)' +
    '   FROM fza_articulos_stockactual s' +
    '   LEFT JOIN fza_articulos_skus sk' +
    '          ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK' +
    '  WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK)' +
    '        = a.CODIGO_ART_ART' +
    '    AND s.CODIGO_ALM_STK = :P_INV_ALMACEN_PMP' +
    '    AND s.PRECIO_MEDIO_STK > 0) AS PMP_ACTUAL,';
end;

function TfrmModalAddBlockInventario.SubquerYaCargado: string;
begin
  // En inventario, "ya cargado" = ya existe alguna linea para ese articulo
  Result :=
    'CASE WHEN EXISTS (SELECT 1 FROM fza_inventarios_lineas il' +
    '                   WHERE il.CODIGO_EMP_INVLIN = :P_INV_EMP_C' +
    '                     AND il.CODIGO_ALM_INVLIN = :P_INV_ALM_C' +
    '                     AND il.SERIE_INV_INVLIN          = :P_INV_SER_C' +
    '                     AND il.NUMERO_INV_INVLIN            = :P_INV_NRO_C' +
    '                     AND il.CODIGO_ART_INVLIN = a.CODIGO_ART_ART)' +
    '     THEN ''S'' ELSE ''N'' END';
end;

function TfrmModalAddBlockInventario.WhereExcluirYaCargados: string;
begin
  Result :=
    'NOT EXISTS (SELECT 1 FROM fza_inventarios_lineas ilx' +
    '             WHERE ilx.CODIGO_EMP_INVLIN = :P_INV_EMP_X' +
    '               AND ilx.CODIGO_ALM_INVLIN = :P_INV_ALM_X' +
    '               AND ilx.SERIE_INV_INVLIN  = :P_INV_SER_X' +
    '               AND ilx.NUMERO_INV_INVLIN = :P_INV_NRO_X' +
    '               AND ilx.CODIGO_ART_INVLIN = a.CODIGO_ART_ART)';
end;

procedure TfrmModalAddBlockInventario.VincularParametrosExtra(AQry: TUniQuery);

  function HasParam(const N: string): Boolean;
  begin
    Result := AQry.Params.FindParam(N) <> nil;
  end;

begin
  if HasParam(
    'P_INV_ALMACEN')     then AQry.ParamByName(
      'P_INV_ALMACEN').AsString     := FAlmacen;
  if HasParam(
    'P_INV_ALMACEN_PMP') then AQry.ParamByName(
      'P_INV_ALMACEN_PMP').AsString := FAlmacen;

  if HasParam('P_INV_EMP_C') then AQry.ParamByName('P_INV_EMP_C').AsString :=
    FEmpresa;
  if HasParam('P_INV_ALM_C') then AQry.ParamByName('P_INV_ALM_C').AsString :=
    FAlmacen;
  if HasParam('P_INV_SER_C') then AQry.ParamByName('P_INV_SER_C').AsString :=
    FSerie;
  if HasParam('P_INV_NRO_C') then AQry.ParamByName('P_INV_NRO_C').AsString :=
    FNro;

  if HasParam('P_INV_EMP_X') then AQry.ParamByName('P_INV_EMP_X').AsString :=
    FEmpresa;
  if HasParam('P_INV_ALM_X') then AQry.ParamByName('P_INV_ALM_X').AsString :=
    FAlmacen;
  if HasParam('P_INV_SER_X') then AQry.ParamByName('P_INV_SER_X').AsString :=
    FSerie;
  if HasParam('P_INV_NRO_X') then AQry.ParamByName('P_INV_NRO_X').AsString :=
    FNro;
end;

function TfrmModalAddBlockInventario.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarInventarioAddBlock,
    [ANumPendientes, FEmpresa, FAlmacen, FSerie, FNro]);
end;

function TfrmModalAddBlockInventario.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format(SInfoLineasInventarioAddBlock,
    [ANumInsertados]);
end;

function TfrmModalAddBlockInventario.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya en el inventario';
end;

// ============================================================================
//   Insercion real
// ============================================================================

function TfrmModalAddBlockInventario.ProximoNumeroLinea: Integer;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(LINEA_INVLIN AS UNSIGNED)),0)+1 AS PROX' +
      '  FROM fza_inventarios_lineas' +
      ' WHERE CODIGO_EMP_INVLIN = :EMP' +
      '   AND CODIGO_ALM_INVLIN = :ALM' +
      '   AND SERIE_INV_INVLIN          = :SER' +
      '   AND NUMERO_INV_INVLIN            = :NRO';
    qry.ParamByName('EMP').AsString := FEmpresa;
    qry.ParamByName('ALM').AsString := FAlmacen;
    qry.ParamByName('SER').AsString := FSerie;
    qry.ParamByName('NRO').AsString := FNro;
    qry.Open;
    Result := qry.FieldByName('PROX').AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmModalAddBlockInventario.InsertarSkusConStockDelArticulo(
  AIns: TUniQuery; const ACodigoArticulo: string;
  var ALineaActual: Integer; var ANumLineas: Integer;
  const AUsuario: string);
var
  qrySkus: TUniQuery;
  sku, descripcion: string;
begin
  qrySkus := TUniQuery.Create(nil);
  try
    qrySkus.Connection := FConn;

    qrySkus.SQL.Text :=
      'SELECT sk.CODIGO_UNIDAD_SKU AS SKU,' +
      '       a.DESCRIPCION_ART  AS DESC_ART' +
      '  FROM fza_articulos_skus sk' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = sk.CODIGO_ART_SKU' +
      ' WHERE sk.CODIGO_ART_SKU = :ART' +
      ' UNION ' +
      'SELECT a.CODIGO_ART_ART  AS SKU,' +
      '       a.DESCRIPCION_ART AS DESC_ART' +
      '  FROM fza_articulos a' +
      ' WHERE a.CODIGO_ART_ART = :ART2' +
      '   AND NOT EXISTS (SELECT 1 FROM fza_articulos_skus sk2' +
      '                    WHERE sk2.CODIGO_ART_SKU = a.CODIGO_ART_ART)' +
      ' ORDER BY SKU';
    qrySkus.ParamByName('ART').AsString  := ACodigoArticulo;
    qrySkus.ParamByName('ART2').AsString := ACodigoArticulo;
    qrySkus.Open;

    while not qrySkus.Eof do
    begin
      sku         := qrySkus.FieldByName('SKU').AsString;
      descripcion := qrySkus.FieldByName('DESC_ART').AsString;

      AIns.ParamByName('LINEA').AsString := Format('%.4d', [ALineaActual]);
      AIns.ParamByName('CODIGO_ART_ART').AsString := ACodigoArticulo;
      AIns.ParamByName('CODIGO_UNIDAD').AsString  := sku;
      AIns.ParamByName('DESCRIPCION').AsString    := descripcion;
      AIns.ParamByName('USR').AsString            := AUsuario;
      AIns.ParamByName('USR2').AsString           := AUsuario;
      AIns.Execute;

      Inc(ALineaActual);
      Inc(ANumLineas);
      qrySkus.Next;
    end;
  finally
    FreeAndNil(qrySkus);
  end;
end;

function TfrmModalAddBlockInventario.EjecutarInsercion(
  out ANumInsertados: Integer; out ACodigos: TArray<string>): Boolean;
var
  ins        : TUniQuery;
  usuario    : string;
  codigos    : TList<string>;
  lineaActual: Integer;
  numLineas  : Integer;
  numArt     : Integer;
  cod        : string;
begin
  Result := False;
  ANumInsertados := 0;
  ACodigos := nil;
  numLineas := 0;
  numArt    := 0;

  if (FSqlPreview = nil) or (not FSqlPreview.Active) or
     (FSqlPreview.RecordCount = 0) then
    Exit;

  usuario     := IdentidadSesion.Usuario;
  lineaActual := ProximoNumeroLinea;

  codigos := TList<string>.Create;
  ins     := TUniQuery.Create(nil);
  try
    ins.Connection := FConn;
    // Cantidades a 0: las rellena el "Recalcular teorico/PMP" del form padre
    // a partir de la fecha del inventario.
    ins.SQL.Text :=
      'INSERT INTO fza_inventarios_lineas (' +
      '  CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN,' +
      '  SERIE_INV_INVLIN, NUMERO_INV_INVLIN, LINEA_INVLIN,' +
      '  CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN,' +
      '  DESCRIPCION_ARTICULO_INVLIN,' +
      '  CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN,' +
      '  CANTIDAD_DIFERENCIA_INVLIN,' +
      '  PRECIO_MEDIO_INVLIN, PRECIO_MEDIO_NUEVO_INVLIN,' +
      '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA' +
      ') VALUES (' +
      '  :EMP, :ALM, :SER, :NRO, :LINEA,' +
      '  :CODIGO_ART_ART, :CODIGO_UNIDAD,' +
      '  :DESCRIPCION,' +
      '  0, 0, 0, 0, 0,' +
      '  :USR, :USR2, NOW()' +
      ')';
    ins.ParamByName('EMP').AsString := FEmpresa;
    ins.ParamByName('ALM').AsString := FAlmacen;
    ins.ParamByName('SER').AsString := FSerie;
    ins.ParamByName('NRO').AsString := FNro;

    FSqlPreview.DisableControls;
    FConn.StartTransaction;
    try
      FSqlPreview.First;
      while not FSqlPreview.Eof do
      begin
        if FSqlPreview.FieldByName('YA_CARGADO').AsString = 'S' then
        begin
          FSqlPreview.Next;
          Continue;
        end;

        cod := FSqlPreview.FieldByName('CODIGO_ART_ART').AsString;
        InsertarSkusConStockDelArticulo(ins,
                                        cod,
                                        lineaActual,
                                        numLineas,
                                        usuario);
        codigos.Add(cod);
        Inc(numArt);

        FSqlPreview.Next;
      end;
      FConn.Commit;
      Result := True;
      ANumInsertados := numLineas;
      ACodigos := codigos.ToArray;

      FResultadoInv.Aceptado         := True;
      FResultadoInv.NumLineas        := numLineas;
      FResultadoInv.NumArticulos     := numArt;
      FResultadoInv.ArticulosCodigos := ACodigos;
      FResultadoInv.Empresa := FEmpresa;
      FResultadoInv.Almacen := FAlmacen;
      FResultadoInv.Serie   := FSerie;
      FResultadoInv.Nro     := FNro;
    except
      on E: Exception do
      begin
        FConn.Rollback;
        ShowMessage(SErrorInsertarLineasInventarioAddBlock + E.Message);
        Result := False;
      end;
    end;
  finally
    FSqlPreview.EnableControls;
    FreeAndNil(ins);
    FreeAndNil(codigos);
  end;
end;

end.
