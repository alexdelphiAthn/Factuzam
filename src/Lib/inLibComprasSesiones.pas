unit inLibComprasSesiones;

{
  Unidad: inLibComprasSesiones
  Lógica de UI para la matriz pivotada en el formulario inMtoComprasSesiones.

  Inspirada en inLibArticulosVariaciones pero adaptada a la dimensionalidad
  multidocumento: cada línea de la sesión tiene su propia variación, sus
  ejes pivot y fila, y su matriz de celdas.

  Una matriz se construye con:
    - El conjunto de valores del eje PIVOT  → columnas (talla S/M/L/XL).
    - El conjunto de valores del eje FILA   → filas (color NEGRO/ROJO...).
    - Una celda (TcxSpinEdit / TcxCurrencyEdit) por intersección, enlazada
      a fza_compras_sesiones_celdas.

  Para líneas TIPO_LINEA = ESCALAR o SERVICIO la "matriz" se degenera a un
  único TcxSpinEdit con la cantidad escalar.

  Eje X (pivot) se determina por el atributo de mayor ORDEN_VA en la
  variación seleccionada para la línea. Si la línea no tiene override, se
  usa el de la cabecera.

  La etiqueta del eje pivot se lee de
    fza_variaciones_atributos.NOMBRE_VISIBLE_VA
  para permitir que el usuario llame al eje "Sistema de tallas", "Paleta",
  "Duración" o lo que necesite por dominio.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics, Vcl.Forms,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxLabel,
  cxSpinEdit, cxCurrencyEdit, cxDropDownEdit, cxLookupEdit,
  DBAccess, Uni,
  UniDataComprasSesiones;

type
  TCeldaMatriz = record
    LineaID    : Integer;
    FilaID     : Integer;
    IdAvPivot  : Integer;
    ValorPivot : string;
    Cantidad   : Double;
    Editor     : TcxSpinEdit;
  end;

  TFilaMatriz = record
    FilaID         : Integer;
    EtiquetaFila   : string;
    IdAvFila       : Integer;
    LblFila        : TcxLabel;
    LblTotalFila   : TcxLabel;
    BtnAplicarKit  : TButton;
    Celdas         : TList<TCeldaMatriz>;
  end;

  TColumnaMatriz = record
    IdAvPivot   : Integer;
    ValorPivot  : string;
    LblColumna  : TcxLabel;
    LblTotalCol : TcxLabel;
  end;

  TGestorMatrizCompras = class
  private
    FContenedor   : TScrollBox;
    FDM           : TdmComprasSesiones;
    FUsuario      : string;
    FLineaActual  : Integer;
    FFilas        : TList<TFilaMatriz>;
    FColumnas     : TList<TColumnaMatriz>;
    FFilaSeleccionada : Integer;

    procedure LimpiarMatriz;
    procedure CargarColumnasDesdeConjuntoPivot(const AIdAcPivot: Integer);
    procedure CargarFilasDesdeBBDD(const ALinea: Integer);
    procedure CargarCeldasDesdeBBDD(const ALinea: Integer);
    procedure DibujarCabecera;
    procedure DibujarFila(var F: TFilaMatriz; ATop: Integer);
    function  CrearLabel(AParent: TWinControl;
                         const AText: string;
                         ALeft, ATop, AWidth: Integer): TcxLabel;
    function  CrearSpin(AParent: TWinControl;
                        ALeft, ATop, AWidth: Integer): TcxSpinEdit;
    procedure OnCantidadChange(Sender: TObject);
  public
    constructor Create(AContenedor: TScrollBox;
                       ADataModule: TdmComprasSesiones;
                       const AUsuario: string);
    destructor  Destroy; override;

    procedure ReconstruirMatriz(const ALinea: Integer);
    procedure AddFila;
    procedure DelFilaSeleccionada;
    property  FilaSeleccionada: Integer read FFilaSeleccionada;
  end;

// Operaciones a nivel de sesión, no de matriz
procedure DuplicarLineaActual(ADM: TdmComprasSesiones; const AUsuario: string);
procedure BorrarLineaConCascada(ADM: TdmComprasSesiones);
procedure ClonarSesion(ADM: TdmComprasSesiones; const AUsuario: string);
procedure ImportarKitsDeProveedor(ADM: TdmComprasSesiones; const AUsuario: string);

function  ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;
function  ContarArticulosNuevos(ADM: TdmComprasSesiones): Integer;
function  ContarSkusPotenciales(ADM: TdmComprasSesiones): Integer;
function  CalcularTotalCompra(ADM: TdmComprasSesiones): Double;

implementation

uses
  inLibGlobalVar;

const
  COL_WIDTH      = 60;
  COL_FILA_WIDTH = 150;
  COL_BTN_WIDTH  = 90;
  ROW_HEIGHT     = 28;
  HEADER_HEIGHT  = 32;
  PAD_X          = 6;

{ TGestorMatrizCompras }

constructor TGestorMatrizCompras.Create(AContenedor: TScrollBox;
  ADataModule: TdmComprasSesiones; const AUsuario: string);
begin
  inherited Create;
  FContenedor := AContenedor;
  FDM         := ADataModule;
  FUsuario    := AUsuario;
  FFilas      := TList<TFilaMatriz>.Create;
  FColumnas   := TList<TColumnaMatriz>.Create;
  FFilaSeleccionada := -1;
end;

destructor TGestorMatrizCompras.Destroy;
begin
  LimpiarMatriz;
  FFilas.Free;
  FColumnas.Free;
  inherited;
end;

procedure TGestorMatrizCompras.LimpiarMatriz;
var
  i, j: Integer;
begin
  for i := 0 to FFilas.Count - 1 do
    FFilas[i].Celdas.Free;
  FFilas.Clear;
  FColumnas.Clear;

  // Liberar todos los hijos del contenedor
  for i := FContenedor.ControlCount - 1 downto 0 do
    FContenedor.Controls[i].Free;
end;

procedure TGestorMatrizCompras.ReconstruirMatriz(const ALinea: Integer);
var
  iIdAcPivot : Integer;
begin
  FLineaActual := ALinea;
  LimpiarMatriz;

  if FDM.unqrySesionLin.IsEmpty then Exit;

  // 1. Determinar conjunto pivot efectivo (override de línea o de cabecera)
  iIdAcPivot := FDM.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
  if iIdAcPivot = 0 then
    iIdAcPivot := FDM.unqryTablaG.FieldByName('ID_AC_PIVOT_SES').AsInteger;
  if iIdAcPivot = 0 then Exit;  // No hay variación; línea ESCALAR/SERVICIO

  // 2. Cargar columnas (valores del conjunto pivot)
  CargarColumnasDesdeConjuntoPivot(iIdAcPivot);

  // 3. Cargar filas existentes desde BBDD
  CargarFilasDesdeBBDD(ALinea);

  // 4. Cargar celdas existentes
  CargarCeldasDesdeBBDD(ALinea);

  // 5. Pintar todo
  DibujarCabecera;
  // ... (las filas se han pintado en CargarFilasDesdeBBDD)
end;

procedure TGestorMatrizCompras.CargarColumnasDesdeConjuntoPivot(
  const AIdAcPivot: Integer);
var
  q: TUniQuery;
  C: TColumnaMatriz;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT ACD.ID_AV_ACD, AV.VALOR_AV ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :p ' +
      ' ORDER BY ACD.ORDEN_ACD, AV.VALOR_AV';
    q.ParamByName('p').AsInteger := AIdAcPivot;
    q.Open;
    while not q.Eof do
    begin
      C.IdAvPivot  := q.FieldByName('ID_AV_ACD').AsInteger;
      C.ValorPivot := q.FieldByName('VALOR_AV').AsString;
      C.LblColumna  := nil;
      C.LblTotalCol := nil;
      FColumnas.Add(C);
      q.Next;
    end;
  finally
    q.Free;
  end;
end;

procedure TGestorMatrizCompras.CargarFilasDesdeBBDD(const ALinea: Integer);
var
  qF, qA: TUniQuery;
  F     : TFilaMatriz;
  yTop  : Integer;
begin
  yTop := HEADER_HEIGHT;
  qF := TUniQuery.Create(nil);
  qA := TUniQuery.Create(nil);
  try
    qF.Connection := inLibGlobalVar.oConn;
    qA.Connection := inLibGlobalVar.oConn;
    qF.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_lineas_filas ' +
      ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
      '   AND LINEA_SES_SESFIL = :l ' +
      ' ORDER BY ORDEN_SESFIL, ID_FILA_SESFIL';
    qF.ParamByName('s').AsString := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    qF.ParamByName('n').AsString := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    qF.ParamByName('l').AsInteger := ALinea;
    qF.Open;
    while not qF.Eof do
    begin
      F.FilaID := qF.FieldByName('ID_FILA_SESFIL').AsInteger;
      // Recoger valor de eje fila (puede haber 1 o N atributos)
      qA.SQL.Text :=
        'SELECT AV.VALOR_AV, FA.ID_AV_SESFILAT, FA.ID_VA_SESFILAT ' +
        '  FROM fza_compras_sesiones_lineas_filas_atr FA ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = FA.ID_AV_SESFILAT ' +
        ' WHERE FA.SERIE_SES_SESFILAT = :s AND FA.NUMERO_SES_SESFILAT = :n ' +
        '   AND FA.LINEA_SES_SESFILAT = :l AND FA.ID_FILA_SESFILAT = :f';
      qA.ParamByName('s').AsString  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
      qA.ParamByName('n').AsString  := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
      qA.ParamByName('l').AsInteger := ALinea;
      qA.ParamByName('f').AsInteger := F.FilaID;
      qA.Open;
      F.EtiquetaFila := '';
      F.IdAvFila := 0;
      while not qA.Eof do
      begin
        if F.EtiquetaFila <> '' then F.EtiquetaFila := F.EtiquetaFila + ' / ';
        F.EtiquetaFila := F.EtiquetaFila + qA.FieldByName('VALOR_AV').AsString;
        if F.IdAvFila = 0 then
          F.IdAvFila := qA.FieldByName('ID_AV_SESFILAT').AsInteger;
        qA.Next;
      end;
      qA.Close;

      F.Celdas := TList<TCeldaMatriz>.Create;
      DibujarFila(F, yTop);
      Inc(yTop, ROW_HEIGHT);
      FFilas.Add(F);
      qF.Next;
    end;
  finally
    qF.Free;
    qA.Free;
  end;
end;

procedure TGestorMatrizCompras.CargarCeldasDesdeBBDD(const ALinea: Integer);
var
  qC: TUniQuery;
  i, j: Integer;
  cant: Double;
  fila: TFilaMatriz;
  celda: TCeldaMatriz;
begin
  qC := TUniQuery.Create(nil);
  try
    qC.Connection := inLibGlobalVar.oConn;
    qC.SQL.Text :=
      'SELECT ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    qC.ParamByName('s').AsString  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    qC.ParamByName('n').AsString  := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    qC.ParamByName('l').AsInteger := ALinea;
    qC.Open;
    while not qC.Eof do
    begin
      // Buscar fila y columna correspondientes y volcar cantidad al editor
      for i := 0 to FFilas.Count - 1 do
      begin
        fila := FFilas[i];
        if fila.FilaID = qC.FieldByName('ID_FILA_SES_SESCEL').AsInteger then
        begin
          for j := 0 to fila.Celdas.Count - 1 do
          begin
            celda := fila.Celdas[j];
            if celda.IdAvPivot = qC.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger then
            begin
              cant := qC.FieldByName('CANTIDAD_SESCEL').AsFloat;
              if Assigned(celda.Editor) then
                celda.Editor.Value := cant;
              Break;
            end;
          end;
          Break;
        end;
      end;
      qC.Next;
    end;
  finally
    qC.Free;
  end;
end;

procedure TGestorMatrizCompras.DibujarCabecera;
var
  i, x: Integer;
  C   : TColumnaMatriz;
begin
  // Cabecera de fila (etiqueta del eje fila)
  CrearLabel(FContenedor, 'Color / Atributo', PAD_X, 4, COL_FILA_WIDTH);
  x := PAD_X + COL_FILA_WIDTH;
  for i := 0 to FColumnas.Count - 1 do
  begin
    C := FColumnas[i];
    C.LblColumna := CrearLabel(FContenedor, C.ValorPivot, x, 4, COL_WIDTH);
    Inc(x, COL_WIDTH);
    FColumnas[i] := C;
  end;
  CrearLabel(FContenedor, 'Total', x, 4, COL_WIDTH);
  Inc(x, COL_WIDTH);
  CrearLabel(FContenedor, 'Kit', x, 4, COL_BTN_WIDTH);
end;

procedure TGestorMatrizCompras.DibujarFila(var F: TFilaMatriz; ATop: Integer);
var
  i, x: Integer;
  celda: TCeldaMatriz;
begin
  F.LblFila := CrearLabel(FContenedor, F.EtiquetaFila, PAD_X, ATop, COL_FILA_WIDTH);
  x := PAD_X + COL_FILA_WIDTH;
  for i := 0 to FColumnas.Count - 1 do
  begin
    celda.LineaID    := FLineaActual;
    celda.FilaID     := F.FilaID;
    celda.IdAvPivot  := FColumnas[i].IdAvPivot;
    celda.ValorPivot := FColumnas[i].ValorPivot;
    celda.Cantidad   := 0;
    celda.Editor     := CrearSpin(FContenedor, x, ATop, COL_WIDTH);
    celda.Editor.Properties.OnEditValueChanged := OnCantidadChange;
    celda.Editor.Tag := (F.FilaID shl 16) or FColumnas[i].IdAvPivot;
    F.Celdas.Add(celda);
    Inc(x, COL_WIDTH);
  end;
  F.LblTotalFila := CrearLabel(FContenedor, '0', x, ATop, COL_WIDTH);
end;

procedure TGestorMatrizCompras.OnCantidadChange(Sender: TObject);
var
  edt  : TcxSpinEdit;
  tag  : Integer;
  iFila, iPivot: Integer;
  q    : TUniQuery;
  bExists: Boolean;
  rNew : Double;
begin
  edt := Sender as TcxSpinEdit;
  tag := edt.Tag;
  iFila  := tag shr 16;
  iPivot := tag and $FFFF;
  rNew   := edt.Value;

  // Upsert directo en fza_compras_sesiones_celdas
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    if rNew <= 0 then
    begin
      q.SQL.Text :=
        'DELETE FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :l AND ID_FILA_SES_SESCEL = :f ' +
        '   AND ID_AV_PIVOT_SESCEL = :p';
    end
    else
    begin
      // INSERT ... ON DUPLICATE KEY UPDATE (MySQL)
      q.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
        '   ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:s, :n, :l, :f, :p, :c, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_SESCEL = :c, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      q.ParamByName('c').AsFloat  := rNew;
      q.ParamByName('u').AsString := FUsuario;
    end;
    q.ParamByName('s').AsString  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := FLineaActual;
    q.ParamByName('f').AsInteger := iFila;
    q.ParamByName('p').AsInteger := iPivot;
    q.ExecSQL;
  finally
    q.Free;
  end;

  FDM.unqrySesionCel.Refresh;
end;

function TGestorMatrizCompras.CrearLabel(AParent: TWinControl;
  const AText: string; ALeft, ATop, AWidth: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(AParent);
  Result.Parent  := AParent;
  Result.Left    := ALeft;
  Result.Top     := ATop;
  Result.Width   := AWidth;
  Result.Caption := AText;
end;

function TGestorMatrizCompras.CrearSpin(AParent: TWinControl;
  ALeft, ATop, AWidth: Integer): TcxSpinEdit;
begin
  Result := TcxSpinEdit.Create(AParent);
  Result.Parent := AParent;
  Result.Left   := ALeft;
  Result.Top    := ATop;
  Result.Width  := AWidth;
  Result.Properties.MinValue := 0;
end;

procedure TGestorMatrizCompras.AddFila;
begin
  // Inserta una nueva fila en fza_compras_sesiones_lineas_filas con el
  // siguiente ID_FILA disponible para la línea, y abre un picker para
  // que el usuario elija el valor del eje fila (color) entre los que aún
  // no estén en la matriz. Implementación detallada pendiente.
  ReconstruirMatriz(FLineaActual);
end;

procedure TGestorMatrizCompras.DelFilaSeleccionada;
var
  q: TUniQuery;
begin
  if FFilaSeleccionada < 0 then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // 1. Borrar celdas
    q.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l AND ID_FILA_SES_SESCEL = :f';
    q.ParamByName('s').AsString  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := FLineaActual;
    q.ParamByName('f').AsInteger := FFilaSeleccionada;
    q.ExecSQL;
    // 2. Borrar atributos de fila
    q.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_lineas_filas_atr ' +
      ' WHERE SERIE_SES_SESFILAT = :s AND NUMERO_SES_SESFILAT = :n ' +
      '   AND LINEA_SES_SESFILAT = :l AND ID_FILA_SESFILAT = :f';
    q.ExecSQL;
    // 3. Borrar fila
    q.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_lineas_filas ' +
      ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
      '   AND LINEA_SES_SESFIL = :l AND ID_FILA_SESFIL = :f';
    q.ExecSQL;
  finally
    q.Free;
  end;

  ReconstruirMatriz(FLineaActual);
end;

// ---------------------------------------------------------------------------
// Operaciones a nivel de sesión completa
// ---------------------------------------------------------------------------

procedure DuplicarLineaActual(ADM: TdmComprasSesiones; const AUsuario: string);
begin
  // INSERT en fza_compras_sesiones_lineas con el siguiente LINEA_SESLIN,
  // copiando todos los campos no-PK. Lo mismo para filas, atributos de
  // fila y celdas. Implementación pendiente al integrar contadores.
end;

procedure BorrarLineaConCascada(ADM: TdmComprasSesiones);
var
  q: TUniQuery;
  s, n: string;
  l: Integer;
begin
  if ADM.unqrySesionLin.IsEmpty then Exit;
  s := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  n := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
  l := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_celdas ' +
                  ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
                  '   AND LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  := s;
    q.ParamByName('n').AsString  := n;
    q.ParamByName('l').AsInteger := l;
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_filas_atr ' +
                  ' WHERE SERIE_SES_SESFILAT = :s AND NUMERO_SES_SESFILAT = :n ' +
                  '   AND LINEA_SES_SESFILAT = :l';
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_filas ' +
                  ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
                  '   AND LINEA_SES_SESFIL = :l';
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_props ' +
                  ' WHERE SERIE_SES_SESLPROP = :s AND NUMERO_SES_SESLPROP = :n ' +
                  '   AND LINEA_SES_SESLPROP = :l';
    q.ExecSQL;
  finally
    q.Free;
  end;
  ADM.unqrySesionLin.Delete;
end;

procedure ClonarSesion(ADM: TdmComprasSesiones; const AUsuario: string);
begin
  // Crear nueva sesión con NUMERO_SES nuevo y copiar todas las tablas
  // detalle (props, kits, kits_det, lineas, filas, filas_atr, celdas,
  // lineas_props) con el nuevo NUMERO_SES. Implementación detallada
  // pendiente.
end;

procedure ImportarKitsDeProveedor(ADM: TdmComprasSesiones;
  const AUsuario: string);
begin
  // Lee kits con CODIGO_PRV_SESKIT del proveedor de la sesión, y los
  // duplica como kits propios de la sesión actual (vinculados al
  // SERIE/NUMERO local). Implementación pendiente.
end;

function ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;
var
  q: TUniQuery;
begin
  Result := True;
  AError := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // 1. Líneas marcadas como duplicado sin acción resuelta
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND ESDUPLICADO_SESLIN = ''S'' ' +
      '   AND (ACCION_DUPLICADO_SESLIN IS NULL OR ACCION_DUPLICADO_SESLIN = '''')';
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    if q.FieldByName('N').AsInteger > 0 then
    begin
      AError := 'Hay líneas con código duplicado sin resolver.';
      Exit(False);
    end;
    q.Close;

    // 2. Líneas MATRIZ sin celdas
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.DESCRIPCION_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_celdas C ' +
      '                    WHERE C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
      '                      AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
      '                      AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
      '                      AND C.CANTIDAD_SESCEL > 0)';
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    if not q.IsEmpty then
    begin
      AError := Format('La línea %d (%s) es de tipo MATRIZ pero no tiene celdas con cantidad.',
                       [q.FieldByName('LINEA_SESLIN').AsInteger,
                        q.FieldByName('DESCRIPCION_SESLIN').AsString]);
      Exit(False);
    end;
  finally
    q.Free;
  end;
end;

function ContarArticulosNuevos(ADM: TdmComprasSesiones): Integer;
var
  q: TUniQuery;
begin
  Result := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (ACCION_DUPLICADO_SESLIN <> ''REUSAR'' ' +
      '        OR ACCION_DUPLICADO_SESLIN IS NULL)';
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    q.Free;
  end;
end;

function ContarSkusPotenciales(ADM: TdmComprasSesiones): Integer;
var
  q: TUniQuery;
begin
  Result := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND CANTIDAD_SESCEL > 0';
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    q.Free;
  end;
end;

function CalcularTotalCompra(ADM: TdmComprasSesiones): Double;
var
  q: TUniQuery;
begin
  Result := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(TOTAL_LINEA_SESLIN), 0) AS T ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n';
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('T').AsFloat;
  finally
    q.Free;
  end;
end;

end.
