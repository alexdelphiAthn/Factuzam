{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalAddBlockDocumentoTrabajo                            }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       23/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de carga masiva de articulos en Documento de Trabajo.               }
{    Hereda de AddBlockBase y reutiliza los filtros de Inventarios/Tarifas.    }
{******************************************************************************}
unit inMtoModalAddBlockDocumentoTrabajo;

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
  TAddBlockDocumentoTrabajoResult = record
    Aceptado: Boolean;
    NumLineas: Integer;
    NumArticulos: Integer;
    ArticulosCodigos: TArray<string>;
    IdDocumento: Int64;
  end;

  TfrmModalAddBlockDocumentoTrabajo = class(TfrmModalAddBlockBase)
    lblDocumentoInfo: TcxLabel;
    lblNotaCarga: TcxLabel;
    procedure FormCreate(Sender: TObject);
  protected
    FResultadoDoc: TAddBlockDocumentoTrabajoResult;
    FIdDtr: Int64;
    FAlmacen: string;
    FTitulo: string;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
      override;
    function SubquerYaCargado: string; override;
    function WhereExcluirYaCargados: string; override;
    procedure VincularParametrosExtra(AQry: TUniQuery); override;
    function TextoConfirmacion(ANumPendientes: Integer): string; override;
    function TextoExito(ANumInsertados: Integer): string; override;
    function TextoExcluirYaCargados: string; override;
    function EjecutarInsercion(out ANumInsertados: Integer;
                               out ACodigos: TArray<string>): Boolean;
      override;
  private
    procedure AjustarAPantalla;
    function AlmacenesCargaSql: string;
    function ProximoNumeroLinea: Integer;
    procedure PreseleccionarAlmacen;
    procedure InsertarSkusConStockDelArticulo(AIns: TUniQuery;
                                              const ACodigoArticulo,
                                                    AAlmacenesSql: string;
                                              var ALineaActual: Integer;
                                              var ANumLineas: Integer;
                                              const AUsuario: string);
  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            AIdDtr: Int64;
                            const AAlmacen,
                                  ATitulo: string):
                            TAddBlockDocumentoTrabajoResult;
    property ResultadoDoc: TAddBlockDocumentoTrabajoResult read FResultadoDoc;
  end;

implementation

{$R *.dfm}

uses
  inLibUser;

class function TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
  AOwner: TComponent; AConn: TUniConnection; AIdDtr: Int64;
  const AAlmacen, ATitulo: string): TAddBlockDocumentoTrabajoResult;
var
  frm: TfrmModalAddBlockDocumentoTrabajo;
begin
  frm := TfrmModalAddBlockDocumentoTrabajo.Create(AOwner);
  try
    frm.FIdDtr := AIdDtr;
    frm.FAlmacen := AAlmacen;
    frm.FTitulo := ATitulo;
    frm.Inicializar(AConn);
    frm.PreseleccionarAlmacen;
    frm.lblDocumentoInfo.Caption :=
      Format('Documento destino: %d - %s', [AIdDtr, ATitulo]);
    frm.ShowModal;
    Result := frm.FResultadoDoc;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.FormCreate(Sender: TObject);
begin
  inherited;
  AjustarAPantalla;
  Self.Caption := 'Anadir Bloque - Documento de Trabajo';
  btnAceptar.Caption := '&Aceptar (F12)';
  btnCancelar.Caption := '&Cancelar (ESC)';
  chkSoloConStock.Checked := True;
  chkSoloConStock.Enabled := False;
  FResultadoDoc.Aceptado := False;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F12) and (Shift = []) then
  begin
    Key := 0;
    btnAceptarClick(btnAceptar);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    btnCancelarClick(btnCancelar);
  end
  else
  begin
    inherited KeyDown(Key, Shift);
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.AjustarAPantalla;
var
  rArea: TRect;
begin
  if Assigned(Application.MainForm) then
  begin
    rArea := Application.MainForm.Monitor.WorkareaRect;
  end
  else
  begin
    rArea := Screen.PrimaryMonitor.WorkareaRect;
  end;
  if Height > rArea.Height then
  begin
    Height := rArea.Height;
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.PreseleccionarAlmacen;
var
  i: Integer;
begin
  if FAlmacen <> '' then
  begin
    for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    begin
      if (chkLstAlmacenes.Items[i].ItemObject is TStringList) and
         (TStringList(chkLstAlmacenes.Items[i].ItemObject).Count > 0) then
      begin
        if TStringList(chkLstAlmacenes.Items[i].ItemObject)[0] = FAlmacen then
        begin
          chkLstAlmacenes.Items[i].Checked := True;
        end;
      end;
    end;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.AlmacenesCargaSql: string;
var
  arrAlm: TArray<string>;
begin
  arrAlm := RecogerCodigosAlmacenesSeleccionados;
  Result := StrArrToCsvSql(arrAlm);
  if (Result = '') and (FAlmacen <> '') then
  begin
    Result := QuotedStr(FAlmacen);
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := False;
  AMensaje := '';
  chkSoloConStock.Checked := True;
  chkSoloConStock.Enabled := False;
  if Length(RecogerCodigosAlmacenesSeleccionados) = 0 then
  begin
    PreseleccionarAlmacen;
  end;
  if FIdDtr <= 0 then
  begin
    AMensaje := 'No se ha recibido el Documento de Trabajo destino.';
  end
  else if AlmacenesCargaSql = '' then
  begin
    AMensaje := 'Seleccione al menos un almacen para cargar articulos.';
  end
  else
  begin
    Result := True;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.SubquerYaCargado: string;
begin
  Result :=
    'CASE WHEN EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dl' +
    '                   WHERE dl.ID_DTR_DTL = :P_DTR_CHK' +
    '                     AND dl.CODIGO_ART_DTL = a.CODIGO_ART_ART)' +
    '     THEN ''S'' ELSE ''N'' END';
end;

function TfrmModalAddBlockDocumentoTrabajo.WhereExcluirYaCargados: string;
begin
  Result :=
    'NOT EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dlx' +
    '             WHERE dlx.ID_DTR_DTL = :P_DTR_EXCL' +
    '               AND dlx.CODIGO_ART_DTL = a.CODIGO_ART_ART)';
end;

procedure TfrmModalAddBlockDocumentoTrabajo.VincularParametrosExtra(
  AQry: TUniQuery);

  function HasParam(const N: string): Boolean;
  begin
    Result := AQry.Params.FindParam(N) <> nil;
  end;

begin
  if HasParam('P_DTR_CHK') then
  begin
    AQry.ParamByName('P_DTR_CHK').AsLargeInt := FIdDtr;
  end;
  if HasParam('P_DTR_EXCL') then
  begin
    AQry.ParamByName('P_DTR_EXCL').AsLargeInt := FIdDtr;
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(
    'Se van a cargar %d articulos en el Documento de Trabajo "%s".' +
    sLineBreak +
    'Se anadira una linea por cada SKU con stock positivo en los ' +
    'almacenes seleccionados.' + sLineBreak +
    'La cantidad operativa de cada linea sera 1.' + sLineBreak +
    sLineBreak + 'Continuar?',
    [ANumPendientes, FTitulo]);
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format('%d lineas anadidas al Documento de Trabajo.',
                   [ANumInsertados]);
end;

function TfrmModalAddBlockDocumentoTrabajo.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya en el documento';
end;

function TfrmModalAddBlockDocumentoTrabajo.ProximoNumeroLinea: Integer;
var
  qry: TUniQuery;
begin
  Result := 1;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)),0)+1 AS PROX' +
      '  FROM fza_documentos_trabajo_lineas' +
      ' WHERE ID_DTR_DTL = :ID_DTR';
    qry.ParamByName('ID_DTR').AsLargeInt := FIdDtr;
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('PROX').AsInteger;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmModalAddBlockDocumentoTrabajo.InsertarSkusConStockDelArticulo(
  AIns: TUniQuery; const ACodigoArticulo, AAlmacenesSql: string;
  var ALineaActual: Integer; var ANumLineas: Integer; const AUsuario: string);
var
  qrySkus: TUniQuery;
begin
  qrySkus := TUniQuery.Create(nil);
  try
    qrySkus.Connection := FConn;
    qrySkus.SQL.Text :=
      'SELECT s.CODIGO_ALM_STK AS ALM,' +
      '       s.CODIGO_UNIDAD_STK AS SKU,' +
      '       s.LOTE_STK,' +
      '       s.FECHA_CADUCIDAD_STK,' +
      '       s.CANTIDAD_STK,' +
      '       a.DESCRIPCION_ART AS DESC_ART,' +
      '       COALESCE((' +
      '         SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV' +
      '                  SEPARATOR '' / '')' +
      '           FROM fza_atributos_sku sa' +
      '           JOIN fza_atributos_valores av' +
      '             ON av.ID_AV = sa.ID_AV_SA' +
      '          WHERE sa.CODIGO_UNIDAD_SKU_SA = s.CODIGO_UNIDAD_STK' +
      '       ), '''') AS DESC_SKU' +
      '  FROM fza_articulos_stockactual s' +
      '  LEFT JOIN fza_articulos_skus sk' +
      '    ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK' +
      '  JOIN fza_articulos a' +
      '    ON a.CODIGO_ART_ART = COALESCE(sk.CODIGO_ART_SKU,' +
      '                                   s.CODIGO_UNIDAD_STK)' +
      ' WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK) = :ART' +
      '   AND s.CANTIDAD_STK > 0';
    if AAlmacenesSql <> '' then
    begin
      qrySkus.SQL.Add('   AND s.CODIGO_ALM_STK IN (' + AAlmacenesSql + ')');
    end;
    qrySkus.SQL.Add(' ORDER BY s.CODIGO_ALM_STK, s.CODIGO_UNIDAD_STK,');
    qrySkus.SQL.Add('          s.LOTE_STK');
    qrySkus.ParamByName('ART').AsString := ACodigoArticulo;
    qrySkus.Open;
    while not qrySkus.Eof do
    begin
      AIns.ParamByName('ID_DTR').AsLargeInt := FIdDtr;
      AIns.ParamByName('LINEA').AsString := Format('%.8d', [ALineaActual]);
      AIns.ParamByName('ART').AsString := ACodigoArticulo;
      AIns.ParamByName('SKU').AsString := qrySkus.FieldByName('SKU').AsString;
      AIns.ParamByName('ALM').AsString := qrySkus.FieldByName('ALM').AsString;
      AIns.ParamByName('LOTE').AsString :=
        qrySkus.FieldByName('LOTE_STK').AsString;
      if qrySkus.FieldByName('FECHA_CADUCIDAD_STK').IsNull then
      begin
        AIns.ParamByName('CADUCIDAD').Clear;
      end
      else
      begin
        AIns.ParamByName('CADUCIDAD').AsDate :=
          qrySkus.FieldByName('FECHA_CADUCIDAD_STK').AsDateTime;
      end;
      AIns.ParamByName('DESC_ART').AsString :=
        qrySkus.FieldByName('DESC_ART').AsString;
      AIns.ParamByName('DESC_SKU').AsString :=
        qrySkus.FieldByName('DESC_SKU').AsString;
      AIns.ParamByName('CANTIDAD_STOCK').AsFloat :=
        qrySkus.FieldByName('CANTIDAD_STK').AsFloat;
      AIns.ParamByName('CANTIDAD').AsFloat := 1;
      AIns.ParamByName('ORIGEN').AsString := 'FILTROS';
      AIns.ParamByName('USR').AsString := AUsuario;
      AIns.ParamByName('USR2').AsString := AUsuario;
      AIns.Execute;
      Inc(ALineaActual);
      Inc(ANumLineas);
      qrySkus.Next;
    end;
  finally
    FreeAndNil(qrySkus);
  end;
end;

function TfrmModalAddBlockDocumentoTrabajo.EjecutarInsercion(
  out ANumInsertados: Integer; out ACodigos: TArray<string>): Boolean;
var
  ins: TUniQuery;
  codigos: TList<string>;
  sUsuario: string;
  sAlmacenesSql: string;
  sCodArticulo: string;
  iLineaActual: Integer;
  iNumLineas: Integer;
  iNumArt: Integer;
  iAntes: Integer;
begin
  Result := False;
  ANumInsertados := 0;
  ACodigos := nil;
  if (FSqlPreview <> nil) and FSqlPreview.Active and
     (FSqlPreview.RecordCount > 0) then
  begin
    sUsuario := IdentidadSesion.Usuario;
    sAlmacenesSql := AlmacenesCargaSql;
    iLineaActual := ProximoNumeroLinea;
    iNumLineas := 0;
    iNumArt := 0;
    codigos := TList<string>.Create;
    ins := TUniQuery.Create(nil);
    try
      ins.Connection := FConn;
      ins.SQL.Text :=
        'INSERT INTO fza_documentos_trabajo_lineas (' +
        '  ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL,' +
        '  CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL,' +
        '  DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL,' +
        '  CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL,' +
        '  ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF' +
        ') VALUES (' +
        '  :ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD,' +
        '  :DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(),' +
        '  :ORIGEN, NOW(), :USR, :USR2' +
        ')';
      FSqlPreview.DisableControls;
      FConn.StartTransaction;
      try
        FSqlPreview.First;
        while not FSqlPreview.Eof do
        begin
          if FSqlPreview.FieldByName('YA_CARGADO').AsString <> 'S' then
          begin
            sCodArticulo := FSqlPreview.FieldByName('CODIGO_ART_ART').AsString;
            iAntes := iNumLineas;
            InsertarSkusConStockDelArticulo(ins, sCodArticulo, sAlmacenesSql,
                                            iLineaActual, iNumLineas,
                                            sUsuario);
            if iNumLineas > iAntes then
            begin
              codigos.Add(sCodArticulo);
              Inc(iNumArt);
            end;
          end;
          FSqlPreview.Next;
        end;
        FConn.Commit;
        Result := True;
        ANumInsertados := iNumLineas;
        ACodigos := codigos.ToArray;
        FResultadoDoc.Aceptado := True;
        FResultadoDoc.NumLineas := iNumLineas;
        FResultadoDoc.NumArticulos := iNumArt;
        FResultadoDoc.ArticulosCodigos := ACodigos;
        FResultadoDoc.IdDocumento := FIdDtr;
      except
        on E: Exception do
        begin
          FConn.Rollback;
          ShowMessage('Error al insertar lineas del documento: ' + E.Message);
          Result := False;
        end;
      end;
    finally
      FSqlPreview.EnableControls;
      FreeAndNil(ins);
      FreeAndNil(codigos);
    end;
  end;
end;

end.
