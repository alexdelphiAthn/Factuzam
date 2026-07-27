unit inLibComprasSesiones;

{
  Unidad: inLibComprasSesiones
  Logica auxiliar para Sesiones de Compra: resolucion de codigos de familia,
  calculo de PVP propuesto (coste x margen / 100 - ajuste), etc.

  El Mto que la usa es inMtoComprasSesiones (patron grid inline con
  tallas pivotadas). La variante previa con matriz separada fue
  desechada; quedan los helpers utiles del lib.

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
  Vcl.Dialogs,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxLabel,
  cxSpinEdit, cxCurrencyEdit, cxDropDownEdit, cxLookupEdit,
  DBAccess, Uni,
  UniDataComprasSesiones, inLibGridTallasInline, System.UITypes, Data.DB;

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
    FAlmacenActual    : string;
                        // Codigo del almacen cuya capa de celdas se esta
                        // editando ahora mismo. Cadena vacia = usar el de
                        // cabecera de sesion. Se cambia desde el form al
                        // mover el cbbAlmacenMatriz.

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
    function  AlmacenEfectivo: string;
                        // Devuelve FAlmacenActual o, si esta vacio, el
                        // CODIGO_ALM_SES de la cabecera.
  public
    constructor Create(AContenedor: TScrollBox;
                       ADataModule: TdmComprasSesiones;
                       const AUsuario: string);
    destructor  Destroy; override;

    procedure ReconstruirMatriz(const ALinea: Integer);
    procedure AddFila;
    procedure AddColumna;
    procedure DelFilaSeleccionada;
    property  FilaSeleccionada: Integer read FFilaSeleccionada;
    property  AlmacenActual: string read FAlmacenActual write FAlmacenActual;
  end;

// Operaciones a nivel de sesión, no de matriz
procedure DuplicarLineaActual(ADM: TdmComprasSesiones; const AUsuario: string);
procedure BorrarLineaConCascada(ADM: TdmComprasSesiones);
procedure ClonarSesion(ADM: TdmComprasSesiones; const AUsuario: string);
procedure ImportarKitsDeProveedor(ADM: TdmComprasSesiones;
                                  const AUsuario: string);

// Comprueba que el kit del proveedor se puede aplicar sobre la linea con
// foco: sesion activa, linea con numero, sistema de tallas asignado, kit
// existente y tallaje del kit IGUAL al de la linea (ID_AC_TALLAS_PRVKIT =
// ID_AC_PIVOT_SESLIN). Con False, AResumen lleva la advertencia para el
// usuario. Lo usan AplicarKitProveedorALinea y el form antes de abrir el
// distribuidor en modo kit (formato distribuido).
function ValidarKitSobreLineaActual(ADM: TdmComprasSesiones;
                                     const ACodigoPrv, ACodigoKit: string;
                                     out AResumen: string): Boolean;

// Aplica un kit del proveedor (fza_proveedores_kits_det) sobre la linea
// con foco de la sesion. REGLA: el tallaje del kit (ID_AC_TALLAS_PRVKIT)
// debe COINCIDIR con el de la linea (ID_AC_PIVOT_SESLIN); si no coincide
// (o el kit no tiene sistema) devuelve False con la advertencia en
// AResumen y no aplica nada. Si coincide, cada VALOR_DESTINO_PRVKITD se
// casa por texto contra los valores del sistema para mapear su columna y
// se persiste con el mismo UPSERT que el tecleo manual en la celda
// (PersistirCantidad; cantidad 0 borra la celda). NO repinta el grid:
// tras un True el form debe RefrescarTotalesLineaActual +
// CargarCantidadesUnaLinea.
// Devuelve False si no se aplico nada; AResumen lleva el motivo o, con
// True, el detalle de tallas sin correspondencia (vacio si caso todo).
function AplicarKitProveedorALinea(ADM: TdmComprasSesiones;
                                    AGestor: TGestorGridTallas;
                                    const ACodigoPrv, ACodigoKit: string;
                                    out AResumen: string): Boolean;

function  ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;

// Recorre TODAS las reglas de validacion y deja una linea por
// incidencia en AIncidencias. Devuelve True si no hay ninguna (sesion
// lista para materializar). El form usa esto para abrir un modal con
// la lista en lugar del mensaje unico de ValidarSesion.
function ValidarSesionDetallado(ADM: TdmComprasSesiones;
                                 AIncidencias: TStrings): Boolean;

// Normaliza duplicados intra-sesion: para cada CODIGO_ART_TENTATIVO que
// aparece en >1 lineas, deja la primera (LINEA_SESLIN minimo) tal cual
// y marca las demas con ESDUPLICADO_SESLIN='S', ACCION='REUSAR',
// CODIGO_ART_REUSAR=el mismo codigo, para que la materializacion solo
// haga INSERT en fza_articulos una vez (la primera) y las variantes
// del mismo articulo (distinto color/SKU) reusen la cabecera. Devuelve
// el numero de lineas marcadas. Idempotente: si todas estan ya
// resueltas, devuelve 0.
function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;

function  ContarArticulosNuevos(ADM: TdmComprasSesiones): Integer;
function  ContarSkusPotenciales(ADM: TdmComprasSesiones): Integer;
function  CalcularTotalCompra(ADM: TdmComprasSesiones): Double;

// Formula:
//   base   = coste * (1 + margen/100)
//   redond = ceil(base, multiplo)   // 0 = sin redondeo, devuelve base
//   venta  = redond + ajuste        // ajuste suele ser negativo (-0.01)
function CalcularPrecioVenta(ACoste, AMargenPct,
                             AMultiplo, AAjuste: Double): Double;

// Aplica la formula a una linea concreta. Lee parametros de la cabecera
// y persiste PRECIO_VENTA_SESLIN. Si ALinea=-1 usa la linea en curso.
procedure CalcularPrecioVentaLinea(ADM: TdmComprasSesiones;
                                    const AUsuario: string;
                                    ALinea: Integer = -1);

// Variante para grid con multi-seleccion: itera las lineas indicadas.
procedure CalcularPrecioVentaLineas(ADM: TdmComprasSesiones;
                                     const AUsuario: string;
                                     const ALineas: array of Integer);

// Si ACodigoTecleado coincide exactamente con una familia que tiene el
// contador activo (ESCONTADOR_ART_FAM = 'S'), genera el siguiente codigo
// de articulo (FAMILIA + relleno de PAD_ART_FAM digitos del CONTADOR_ART_FAM
// incrementado), incrementa el contador en fza_articulos_familias y
// devuelve True con ACodigoGenerado lleno.
// Si no es una familia, o la familia no tiene contador activo, devuelve
// False y ACodigoGenerado queda vacio.
function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;

// ---------------------------------------------------------------------------
// Reutilizacion de articulos ya existentes en una sesion (ACCION=REUSAR)
// ---------------------------------------------------------------------------
type
  TResolverDuplicadoSesion = record
    Encontrado          : Boolean;
    Origen              : string;   // 'ART' = match CODIGO_ART_ART exacto,
                                    // 'REF' = match REF_PROVEEDOR_AP del prv
    CodigoArt           : string;
    DescripcionArt      : string;
    CodigoFam           : string;
    NombreFam           : string;
    IdAcPivot           : Integer;
    IdVaPivot           : string;
    IdAcFila            : Integer;
    IdVaFila            : string;
    TipoVariacion       : string;
    EsVariacion         : Boolean;
    EsTrazable          : Boolean;
    TipoArt             : string;
    TipoIva             : string;
    TipoCantidad        : string;
    UltimoCoste         : Double;
    PrecioVenta         : Double;
    RefProveedor        : string;
    // Solo rellenos con Origen = 'SES' (match contra otra linea de la
    // misma sesion): permiten ofrecer la copia completa de esa linea
    // (repetir en otro color / otro rango de precios).
    LineaOrigen         : Integer;
    ColorTexto          : string;
    CodigoAtbColor      : string;
    MargenPorcentaje    : Double;
  end;

// Busca un articulo existente que case con lo que el usuario teclea, por
// dos vias:
//   1. CODIGO_ART_ART exacto (cualquier proveedor)
//   2. REF_PROVEEDOR_AP exacto en fza_articulos_proveedores para
//      ACodigoProveedor (proveedor de la cabecera de la sesion)
// La preferencia normal es CODIGO_ART > REF_PROVEEDOR. Si ASoloRefProveedor
// es True, solo se busca por REF_PROVEEDOR_AP del proveedor de cabecera.
// ACodigoArticuloPreferido desambigua referencias repetidas elegidas desde
// el desplegable de "Modelo prov.".
function ResolverDuplicadoSesion(AConn: TUniConnection;
                                  const ACodigoBuscado,
                                        ACodigoProveedor: string;
                                  ASoloRefProveedor: Boolean = False;
                                  const ACodigoArticuloPreferido: string = '')
                                  : TResolverDuplicadoSesion;

// Busca una linea anterior del MISMO documento de sesion que ya tenga el
// mismo modelo de proveedor o el mismo codigo de articulo. Se usa durante
// la edicion para copiar familia, descripcion, tallaje y precios antes de
// materializar, igual que si el articulo ya existiera en fza_articulos.
function ResolverDuplicadoIntraSesion(AConn: TUniConnection;
                                       const ASerieSes, ANumSes: string;
                                       ALineaActual: Integer;
                                       const AModelo, ACodigoArt: string)
                                       : TResolverDuplicadoSesion;

// Aplica el resultado de ResolverDuplicadoSesion a la linea de sesion
// activa (debe estar en dsEdit o dsInsert):
//   - ACCION_DUPLICADO_SESLIN = 'REUSAR'
//   - CODIGO_ART_REUSAR_SESLIN / CODIGO_ART_TENTATIVO_SESLIN = CodigoArt
//   - DESCRIPCION_SESLIN, CODIGO_FAM_SESLIN, ID_AC_PIVOT_SESLIN,
//     ID_VA_PIVOT_SESLIN, ID_AC_FILA_SESLIN, ID_VA_FILA_SESLIN,
//     TIPO_LINEA_SESLIN, TIPO_ART_SESLIN, ESTRAZABLE_SESLIN,
//     TIPO_IVA_SESLIN, TIPO_CANTIDAD_SESLIN, CODIGO_VAR_SESLIN,
//     PRECIO_COMPRA_SESLIN, PRECIO_VENTA_SESLIN, REF_PRV_SESLIN
//     (si el origen NO es REF y hay RefProveedor del proveedor de la
//     cabecera).
procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);

implementation

uses
  System.Math,
  System.StrUtils,
  inLibMsg;

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
  FreeAndNil(FFilas);
  FreeAndNil(FColumnas);
  inherited;
end;

procedure TGestorMatrizCompras.LimpiarMatriz;
var
  i: Integer;
begin
  for i := 0 to FFilas.Count - 1 do
    FreeAndNil(FFilas[i].Celdas);
  FFilas.Clear;
  FColumnas.Clear;

  // Liberar todos los hijos del contenedor
  for i := FContenedor.ControlCount - 1 downto 0 do
    FreeAndNil(FContenedor.Controls[i]);
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
    q.Connection := FDM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT ACD.ID_AV_ACD, AV.AV AS VALOR ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :p ' +
      ' ORDER BY ACD.ORDEN_ACD, AV.AV';
    q.ParamByName('p').AsInteger := AIdAcPivot;
    q.Open;
    while not q.Eof do
    begin
      C.IdAvPivot  := q.FieldByName('ID_AV_ACD').AsInteger;
      C.ValorPivot := q.FieldByName('VALOR').AsString;
      C.LblColumna  := nil;
      C.LblTotalCol := nil;
      FColumnas.Add(C);
      q.Next;
    end;
  finally
    FreeAndNil(q);
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
    qF.Connection := FDM.ConexionPrincipal;
    qA.Connection := FDM.ConexionPrincipal;
    qF.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_lineas_filas ' +
      ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
      '   AND LINEA_SES_SESFIL = :l ' +
      ' ORDER BY ORDEN_SESFIL, ID_FILA_SESFIL';
    qF.ParamByName('s').AsString :=
      FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    qF.ParamByName('n').AsString :=
      FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    qF.ParamByName('l').AsInteger := ALinea;
    qF.Open;
    while not qF.Eof do
    begin
      F.FilaID := qF.FieldByName('ID_FILA_SESFIL').AsInteger;
      // Recoger valor de eje fila (puede haber 1 o N atributos)
      qA.SQL.Text :=
        'SELECT AV.AV AS VALOR, FA.ID_AV_SESFILAT, FA.ID_VA_SESFILAT ' +
        '  FROM fza_compras_sesiones_lineas_filas_atr FA ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = FA.ID_AV_SESFILAT ' +
        ' WHERE FA.SERIE_SES_SESFILAT = :s AND FA.NUMERO_SES_SESFILAT = :n ' +
        '   AND FA.LINEA_SES_SESFILAT = :l AND FA.ID_FILA_SESFILAT = :f';
      qA.ParamByName('s').AsString  :=
        FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
      qA.ParamByName('n').AsString  :=
        FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
      qA.ParamByName('l').AsInteger := ALinea;
      qA.ParamByName('f').AsInteger := F.FilaID;
      qA.Open;
      F.EtiquetaFila := '';
      F.IdAvFila := 0;
      while not qA.Eof do
      begin
        if F.EtiquetaFila <> '' then F.EtiquetaFila := F.EtiquetaFila + ' / ';
        F.EtiquetaFila := F.EtiquetaFila + qA.FieldByName('VALOR').AsString;
        if F.IdAvFila = 0 then
          F.IdAvFila := qA.FieldByName('ID_AV_SESFILAT').AsInteger;
        qA.Next;
      end;
      qA.Close;
      // Modo texto libre (§12): si _filas_atr no devolvio valores, usamos
      // la etiqueta tecleada por el usuario en ETIQUETA_TEXTO_SESFIL.
      if (F.EtiquetaFila = '')
         and (not qF.FieldByName('ETIQUETA_TEXTO_SESFIL').IsNull) then
        F.EtiquetaFila := qF.FieldByName('ETIQUETA_TEXTO_SESFIL').AsString;

      F.Celdas := TList<TCeldaMatriz>.Create;
      DibujarFila(F, yTop);
      Inc(yTop, ROW_HEIGHT);
      FFilas.Add(F);
      qF.Next;
    end;
  finally
    FreeAndNil(qF);
    FreeAndNil(qA);
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
    qC.Connection := FDM.ConexionPrincipal;
    // Filtramos por almacen: la matriz muestra una "capa" por almacen.
    // Para no perder celdas legacy (creadas antes de anadir CODIGO_ALM_SESCEL),
    // tambien traemos las que tienen el codigo vacio cuando ese caso aplica.
    qC.SQL.Text :=
      'SELECT ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l ' +
      '   AND (CODIGO_ALM_SESCEL = :a ' +
      '        OR (CODIGO_ALM_SESCEL = '''' AND :a = :acab))';
    qC.ParamByName('s').AsString  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    qC.ParamByName('n').AsString  := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    qC.ParamByName('l').AsInteger := ALinea;
    qC.ParamByName('a').AsString  := AlmacenEfectivo;
    qC.ParamByName('acab').AsString :=
      FDM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
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
            if celda.IdAvPivot = qC.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger then
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
    FreeAndNil(qC);
  end;
end;

procedure TGestorMatrizCompras.DibujarCabecera;
var
  i, x: Integer;
  C   : TColumnaMatriz;
  sUni, sTotal: string;
begin
  // Unidad de medida del articulo de la linea actual (indicativo en cabecera).
  sUni := '';
  if FDM.unqrySesionLin.FindField('TIPO_CANTIDAD_SESLIN') <> nil then
    sUni := Trim(FDM.unqrySesionLin.FieldByName('TIPO_CANTIDAD_SESLIN').AsString);
  // Cabecera de fila (etiqueta del eje fila); muestra la unidad de medida.
  if sUni <> '' then
    CrearLabel(FContenedor, 'Color / Atributo  ·  Ud: ' + sUni,
               PAD_X, 4, COL_FILA_WIDTH)
  else
    CrearLabel(FContenedor, 'Color / Atributo', PAD_X, 4, COL_FILA_WIDTH);
  x := PAD_X + COL_FILA_WIDTH;
  for i := 0 to FColumnas.Count - 1 do
  begin
    C := FColumnas[i];
    C.LblColumna := CrearLabel(FContenedor, C.ValorPivot, x, 4, COL_WIDTH);
    Inc(x, COL_WIDTH);
    FColumnas[i] := C;
  end;
  if sUni <> '' then
    sTotal := 'Total (' + sUni + ')'
  else
    sTotal := 'Total';
  CrearLabel(FContenedor, sTotal, x, 4, COL_WIDTH);
  Inc(x, COL_WIDTH);
  CrearLabel(FContenedor, 'Kit', x, 4, COL_BTN_WIDTH);
end;

procedure TGestorMatrizCompras.DibujarFila(var F: TFilaMatriz; ATop: Integer);
var
  i, x: Integer;
  celda: TCeldaMatriz;
begin
  F.LblFila := CrearLabel(FContenedor,
                          F.EtiquetaFila,
                          PAD_X,
                          ATop,
                          COL_FILA_WIDTH);
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
  rNew : Double;
  sAlm : string;
begin
  edt := Sender as TcxSpinEdit;
  tag := edt.Tag;
  iFila  := tag shr 16;
  iPivot := tag and $FFFF;
  rNew   := edt.Value;
  sAlm   := AlmacenEfectivo;

  // Upsert directo en fza_compras_sesiones_celdas para (linea, fila, pivot, almacen)
  q := TUniQuery.Create(nil);
  try
    q.Connection := FDM.ConexionPrincipal;
    if rNew <= 0 then
    begin
      q.SQL.Text :=
        'DELETE FROM fza_compras_sesiones_celdas ' +
        ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
        '   AND LINEA_SES_SESCEL = :l AND ID_FILA_SES_SESCEL = :f ' +
        '   AND ID_AV_PIVOT_SESCEL = :p AND CODIGO_ALM_SESCEL = :a';
    end
    else
    begin
      // INSERT ... ON DUPLICATE KEY UPDATE (MySQL)
      q.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
        '   ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL, CODIGO_ALM_SESCEL, ' +
        '   CANTIDAD_SESCEL, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:s, :n, :l, :f, :p, :a, :c, NOW(), :u) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_SESCEL = :c, INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u';
      q.ParamByName('c').AsFloat  := rNew;
      q.ParamByName('u').AsString := FUsuario;
    end;
    q.ParamByName('s').AsString  :=
      FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := FLineaActual;
    q.ParamByName('f').AsInteger := iFila;
    q.ParamByName('p').AsInteger := iPivot;
    q.ParamByName('a').AsString  := sAlm;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;

  FDM.unqrySesionCel.Refresh;
end;

function TGestorMatrizCompras.AlmacenEfectivo: string;
begin
  Result := FAlmacenActual;
  if Result = '' then
    Result := FDM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString;
end;

function TGestorMatrizCompras.CrearLabel(AParent: TWinControl;
  const AText: string; ALeft, ATop, AWidth: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(AParent);
  Result.Parent  := AParent;
  Result.Transparent := True;
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
  // Las compras se hacen en unidades enteras (80, 50 metros...), sin decimales.
end;

procedure TGestorMatrizCompras.AddFila;
var
  q          : TUniQuery;
  sSerie     : string;
  sNumero    : string;
  iIdAcFila  : Integer;
  bModoTexto : Boolean;
  sTexto     : string;
  iNuevoId   : Integer;
  iOrden     : Integer;
begin
  if FDM = nil then Exit;
  if FDM.unqryTablaG.IsEmpty then Exit;
  if FLineaActual <= 0 then Exit;

  sSerie  := FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;

  // Modo texto libre (§12): ID_AC_FILA_SES vacio en cabecera => el usuario
  // teclea el nombre de la fila libremente. Modo conjunto (TODO): habria
  // que abrir un picker con los valores del conjunto aun no usados; queda
  // pendiente.
  if FDM.unqryTablaG.FieldByName('ID_AC_FILA_SES').IsNull then
    iIdAcFila := 0
  else
    iIdAcFila := FDM.unqryTablaG.FieldByName('ID_AC_FILA_SES').AsInteger;
  bModoTexto := (iIdAcFila = 0);

  if not bModoTexto then
  begin
    // Modo conjunto: picker pendiente. Avisamos para no dejar al usuario
    // confundido (sin esto pulsar el boton no hacia absolutamente nada).
    MessageDlg(
      SAvisoSelectorConjuntoFilaNoImplementado,
      mtInformation, [mbOk], 0);
    Exit;
  end;

  // Pedir el texto de la fila
  sTexto := '';
  if not InputQuery(STituloNuevaFilaCompra, SSolicitudNombreFilaCompra,
                    sTexto) then Exit;
  sTexto := Trim(sTexto);
  if sTexto = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FDM.ConexionPrincipal;

    // Siguiente ID_FILA y ORDEN para la linea. Para el orden usamos pasos
    // de 10 (10, 20, 30...) para que el SKU se ordene correctamente y deje
    // huecos por si el usuario quiere reordenar despues.
    q.SQL.Text :=
      'SELECT COALESCE(MAX(ID_FILA_SESFIL), 0)  + 1  AS NEXT_ID, ' +
      '       COALESCE(MAX(ORDEN_SESFIL), 0)   + 10 AS NEXT_ORDEN ' +
      '  FROM fza_compras_sesiones_lineas_filas ' +
      ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
      '   AND LINEA_SES_SESFIL = :l';
    q.ParamByName('s').AsString  := sSerie;
    q.ParamByName('n').AsString  := sNumero;
    q.ParamByName('l').AsInteger := FLineaActual;
    q.Open;
    iNuevoId := q.FieldByName('NEXT_ID').AsInteger;
    iOrden   := q.FieldByName('NEXT_ORDEN').AsInteger;
    q.Close;

    q.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_lineas_filas ' +
      '  (SERIE_SES_SESFIL, NUMERO_SES_SESFIL, LINEA_SES_SESFIL, ' +
      '   ID_FILA_SESFIL, ORDEN_SESFIL, ETIQUETA_TEXTO_SESFIL, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:s, :n, :l, :id, :o, :t, NOW(), :u)';
    q.ParamByName('s').AsString  := sSerie;
    q.ParamByName('n').AsString  := sNumero;
    q.ParamByName('l').AsInteger := FLineaActual;
    q.ParamByName('id').AsInteger := iNuevoId;
    q.ParamByName('o').AsInteger  := iOrden;
    q.ParamByName('t').AsString   := sTexto;
    q.ParamByName('u').AsString   := FUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;

  ReconstruirMatriz(FLineaActual);
end;

procedure TGestorMatrizCompras.AddColumna;
var
  q             : TUniQuery;
  iIdAcPivot    : Integer;
  sIdAtb        : string;
  sNombreNueva  : string;
  sOrdenStr     : string;
  iOrdenSugerido: Integer;
  iOrden        : Integer;
  iIdAv         : Integer;
begin
  // Anade una talla (o valor pivot) al conjunto seleccionado. Replica el
  // patron de inMtoModalGenerarSKUs.btnAddValueClick: el valor entra en
  // fza_atributos_valores (si no estaba) y se engancha al conjunto pivot
  // de la sesion mediante fza_atributos_conjuntos_det para que aparezca
  // como columna nueva de la matriz y quede disponible en futuras sesiones.
  if FDM = nil then Exit;
  if FDM.unqryTablaG.IsEmpty then Exit;

  if FDM.unqryTablaG.FieldByName('ID_AC_PIVOT_SES').IsNull then
  begin
    MessageDlg(
      SAvisoConjuntoPivotCompraObligatorio,
      mtWarning, [mbOk], 0);
    Exit;
  end;
  iIdAcPivot := FDM.unqryTablaG.FieldByName('ID_AC_PIVOT_SES').AsInteger;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FDM.ConexionPrincipal;

    // Atributo del conjunto pivot (CO, TAL, ...) — necesario para crear el
    // AV bajo ese atributo.
    q.SQL.Text :=
      'SELECT ID_VA_AC, NOMBRE_AC FROM fza_atributos_conjuntos ' +
      ' WHERE ID_AC = :ac';
    q.ParamByName('ac').AsInteger := iIdAcPivot;
    q.Open;
    if q.IsEmpty then
    begin
      q.Close;
      MessageDlg(SErrorConjuntoPivotCompraNoExiste,
                 mtError, [mbOk], 0);
      Exit;
    end;
    sIdAtb := q.FieldByName('ID_VA_AC').AsString;
    q.Close;

    // Orden sugerido = ultimo orden en el conjunto + 10. Para que el SKU
    // ordene correctamente (38, 40, 42, 44...) y quede hueco para inserts.
    q.SQL.Text :=
      'SELECT COALESCE(MAX(ORDEN_ACD), 0) + 10 AS NEXT_ORDEN ' +
      '  FROM fza_atributos_conjuntos_det ' +
      ' WHERE ID_AC_ACD = :ac';
    q.ParamByName('ac').AsInteger := iIdAcPivot;
    q.Open;
    iOrdenSugerido := q.FieldByName('NEXT_ORDEN').AsInteger;
    q.Close;

    // Inputs del usuario: nombre del valor y orden.
    sNombreNueva := '';
    if not InputQuery(STituloAnadirValorPivotCompra,
                      SSolicitudNombreValorPivotCompra, sNombreNueva) then
      Exit;
    sNombreNueva := Trim(sNombreNueva);
    if sNombreNueva = '' then Exit;

    sOrdenStr := IntToStr(iOrdenSugerido);
    if not InputQuery(STituloAnadirValorPivotCompra,
        SSolicitudOrdenValorPivotCompra,
        sOrdenStr) then Exit;
    iOrden := StrToIntDef(Trim(sOrdenStr), iOrdenSugerido);

    // 1. AV en fza_atributos_valores (si no existe).
    q.SQL.Text :=
      'SELECT ID_AV FROM fza_atributos_valores ' +
      ' WHERE ID_VA_AV = :va AND TRIM(UPPER(AV)) = UPPER(:v)';
    q.ParamByName('va').AsString := sIdAtb;
    q.ParamByName('v').AsString  := sNombreNueva;
    q.Open;
    if not q.IsEmpty then
      iIdAv := q.FieldByName('ID_AV').AsInteger
    else
    begin
      q.Close;
      q.SQL.Text :=
        'INSERT INTO fza_atributos_valores ' +
        '  (ID_VA_AV, AV, ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   USUARIO_MODIF) ' +
        'VALUES (:va, :v, :o, NOW(), :u, :u)';
      q.ParamByName('va').AsString := sIdAtb;
      q.ParamByName('v').AsString  := sNombreNueva;
      q.ParamByName('o').AsInteger := iOrden;
      q.ParamByName('u').AsString  := FUsuario;
      q.ExecSQL;
      q.Close;
      q.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
      q.Open;
      iIdAv := q.FieldByName('ID').AsInteger;
    end;
    q.Close;

    // 2. Engancharlo al conjunto pivot (idempotente).
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_conjuntos_det ' +
      '  (ID_AC_ACD, ID_AV_ACD, ORDEN_ACD, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:ac, :av, :o, NOW(), :u, :u)';
    q.ParamByName('ac').AsInteger := iIdAcPivot;
    q.ParamByName('av').AsInteger := iIdAv;
    q.ParamByName('o').AsInteger  := iOrden;
    q.ParamByName('u').AsString   := FUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;

  ReconstruirMatriz(FLineaActual);
end;

procedure TGestorMatrizCompras.DelFilaSeleccionada;
var
  q: TUniQuery;
begin
  if FFilaSeleccionada < 0 then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FDM.ConexionPrincipal;
    // 1. Borrar celdas
    q.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l AND ID_FILA_SES_SESCEL = :f';
    q.ParamByName('s').AsString  :=
      FDM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  :=
      FDM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
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
    FreeAndNil(q);
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
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_celdas ' +
                  ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
                  '   AND LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  := s;
    q.ParamByName('n').AsString  := n;
    q.ParamByName('l').AsInteger := l;
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_filas_atr ' +
                  ' WHERE SERIE_SES_SESFILAT = :s AND NUMERO_SES_SESFILAT = :n '
                    +
                  '   AND LINEA_SES_SESFILAT = :l';
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_filas ' +
                  ' WHERE SERIE_SES_SESFIL = :s AND NUMERO_SES_SESFIL = :n ' +
                  '   AND LINEA_SES_SESFIL = :l';
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_compras_sesiones_lineas_props ' +
                  ' WHERE SERIE_SES_SESLPROP = :s AND NUMERO_SES_SESLPROP = :n '
                    +
                  '   AND LINEA_SES_SESLPROP = :l';
    q.ExecSQL;
  finally
    FreeAndNil(q);
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

function ValidarKitSobreLineaActual(ADM: TdmComprasSesiones;
                                     const ACodigoPrv, ACodigoKit: string;
                                     out AResumen: string): Boolean;
var
  q       : TUniQuery;
  iLinea  : Integer;
  iAc     : Integer;
  iAcKit  : Integer;
  sNomKit : string;
  sNomLin : string;
begin
  Result   := False;
  AResumen := '';
  if (ADM = nil) or ADM.unqryTablaG.IsEmpty then
    AResumen := SErrorSesionCompraNoActiva
  else if ADM.unqrySesionLin.IsEmpty then
    AResumen := SErrorLineaArticuloSesionNoSeleccionada
  else
  begin
    iLinea := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    iAc    := ADM.unqrySesionLin.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    if iLinea <= 0 then
      AResumen := SErrorLineaSesionSinNumero
    else if iAc <= 0 then
      AResumen := SErrorSistemaTallasLineaSesionObligatorio
    else
    begin
      // El tallaje del kit DEBE coincidir con el de la linea; si no, se
      // advierte y no se aplica nada (evita volcar curvas de un sistema
      // sobre otro aunque compartan algun valor de talla).
      q := TUniQuery.Create(nil);
      try
        q.Connection := ADM.ConexionPrincipal;
        q.SQL.Text :=
          'SELECT K.ID_AC_TALLAS_PRVKIT, ' +
          '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
          '    WHERE ID_AC = K.ID_AC_TALLAS_PRVKIT) AS NOMBRE_TALLAS_KIT, ' +
          '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
          '    WHERE ID_AC = :ac) AS NOMBRE_TALLAS_LIN ' +
          '  FROM fza_proveedores_kits K ' +
          ' WHERE K.CODIGO_PRV_PRVKIT = :prv ' +
          '   AND K.CODIGO_PRVKIT = :kit';
        q.ParamByName('ac').AsInteger := iAc;
        q.ParamByName('prv').AsString := ACodigoPrv;
        q.ParamByName('kit').AsString := ACodigoKit;
        q.Open;
        if q.IsEmpty then
          AResumen := Format(SErrorKitProveedorNoExiste,
                             [ACodigoKit, ACodigoPrv])
        else
        begin
          iAcKit  := q.FieldByName('ID_AC_TALLAS_PRVKIT').AsInteger;
          sNomKit := Trim(q.FieldByName('NOMBRE_TALLAS_KIT').AsString);
          sNomLin := Trim(q.FieldByName('NOMBRE_TALLAS_LIN').AsString);
          if sNomKit = '' then
            sNomKit := IntToStr(iAcKit);
          if sNomLin = '' then
            sNomLin := IntToStr(iAc);
          if iAcKit <= 0 then
            AResumen := Format(SErrorKitSinSistemaTallas, [ACodigoKit])
          else if iAcKit <> iAc then
            AResumen := Format(SErrorTallajeKitNoCoincide,
              [sNomKit, sNomLin])
          else
            Result := True;
        end;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

function AplicarKitProveedorALinea(ADM: TdmComprasSesiones;
                                    AGestor: TGestorGridTallas;
                                    const ACodigoPrv, ACodigoKit: string;
                                    out AResumen: string): Boolean;
var
  q          : TUniQuery;
  arr        : TArrPosConjunto;
  iLinea     : Integer;
  iAc        : Integer;
  i          : Integer;
  bCasada    : Boolean;
  iAplicadas : Integer;
  sValor     : string;
  rCant      : Double;
  sSinCasar  : string;
begin
  Result   := False;
  AResumen := '';
  if AGestor = nil then
    AResumen := SErrorGestorTallasNoInicializado
  else if ValidarKitSobreLineaActual(ADM, ACodigoPrv, ACodigoKit,
                                     AResumen) then
  begin
    iLinea     := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
    iAc        := ADM.unqrySesionLin.FieldByName(
                                            'ID_AC_PIVOT_SESLIN').AsInteger;
    arr        := AGestor.GetPosicionesConjunto(iAc);
    iAplicadas := 0;
    sSinCasar  := '';
    q := TUniQuery.Create(nil);
    try
      q.Connection := ADM.ConexionPrincipal;
      q.SQL.Text :=
        'SELECT VALOR_DESTINO_PRVKITD, CANTIDAD_PRVKITD ' +
        '  FROM fza_proveedores_kits_det ' +
        ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
        '   AND CODIGO_PRVKIT_PRVKITD = :kit ' +
        ' ORDER BY ORDEN_PRVKITD, VALOR_DESTINO_PRVKITD';
      q.ParamByName('prv').AsString := ACodigoPrv;
      q.ParamByName('kit').AsString := ACodigoKit;
      q.Open;
      if q.IsEmpty then
        AResumen := Format(SErrorKitSinTallasDefinidas, [ACodigoKit])
      else
      begin
        while not q.Eof do
        begin
          sValor  := Trim(q.FieldByName('VALOR_DESTINO_PRVKITD').AsString);
          rCant   := q.FieldByName('CANTIDAD_PRVKITD').AsFloat;
          bCasada := False;
          // El tallaje ya se ha validado; el casado por texto mapea
          // cada talla del kit a su columna (ID_AV) en la linea.
          for i := 0 to High(arr) do
          begin
            if SameText(Trim(arr[i].Valor), sValor) then
            begin
              AGestor.PersistirCantidad(iLinea, arr[i].IdAv, rCant);
              bCasada := True;
              Inc(iAplicadas);
              Break;
            end;
          end;
          if (not bCasada) and (rCant > 0) then
          begin
            if sSinCasar <> '' then
              sSinCasar := sSinCasar + ', ';
            sSinCasar := sSinCasar + Format('%s (%g)', [sValor, rCant]);
          end;
          q.Next;
        end;
      end;
    finally
      FreeAndNil(q);
    end;
    if iAplicadas > 0 then
    begin
      Result := True;
      if sSinCasar <> '' then
        AResumen := Format(SAvisoTallasKitSinCorrespondencia, [sSinCasar]);
    end
    else if AResumen = '' then
      AResumen := SErrorTallasKitSinCorrespondencia;
  end;
end;

function ValidarSesion(ADM: TdmComprasSesiones; out AError: string): Boolean;
var
  inc: TStringList;
begin
  // ValidarSesion (legacy) ahora delega en el validador detallado y
  // devuelve solo la primera incidencia como string. El form prefiere
  // llamar a ValidarSesionDetallado para mostrar todas.
  inc := TStringList.Create;
  try
    Result := ValidarSesionDetallado(ADM, inc);
    if Result then AError := ''
    else if inc.Count > 0 then AError := inc[0]
    else AError := SErrorSesionIncidenciasSinDetalle;
  finally
    FreeAndNil(inc);
  end;
end;

function ValidarSesionDetallado(ADM: TdmComprasSesiones;
                                 AIncidencias: TStrings): Boolean;
var
  q: TUniQuery;
  sSerie, sNum: string;

  procedure AnadirInc(const ALinea: Integer;
                       const ATipo, AMensaje: string);
  var
    sLin: string;
  begin
    if ALinea > 0 then sLin := Format(STextoLineaIncidenciaSesion, [ALinea])
    else sLin := STextoCabeceraIncidenciaSesion;
    AIncidencias.Add(Format(SFormatoIncidenciaSesion,
      [ATipo, sLin, AMensaje]));
  end;

begin
  Result := True;
  if AIncidencias = nil then Exit;
  AIncidencias.Clear;
  if ADM.unqryTablaG.IsEmpty then
  begin
    AIncidencias.Add(SErrorSesionInactivaIncidencia);
    Exit(False);
  end;

  sSerie := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNum   := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;

  // ---- Cabecera ----
  if Trim(ADM.unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString) = '' then
    AnadirInc(0, STipoIncidenciaCabecera, SErrorEmpresaSesionFaltante);
  if Trim(ADM.unqryTablaG.FieldByName('CODIGO_PRV_SES').AsString) = '' then
    AnadirInc(0, STipoIncidenciaCabecera, SErrorProveedorSesionFaltante);
  // Si la cabecera marca generar albaran, exigimos almacen
  if (ADM.unqryTablaG.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S')
     and (Trim(ADM.unqryTablaG.FieldByName('CODIGO_ALM_SES').AsString) = '')
  then
    AnadirInc(0, STipoIncidenciaCabecera,
        SErrorAlmacenSesionFaltante);

  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;

    // ---- Hay al menos una linea ----
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    if q.FieldByName('N').AsInteger = 0 then
      AnadirInc(0, STipoIncidenciaCabecera, SErrorSesionSinLineas);
    q.Close;

    // ---- Duplicados intra-sesion sin resolver (mismo CODIGO_ART_TENTATIVO
    //      en >1 lineas, alguna sin ACCION=REUSAR). La materializacion
    //      reventaria al hacer INSERT del segundo articulo con la misma
    //      PK CODIGO_ART_ART. El form auto-normaliza con
    //      NormalizarDuplicadosIntraSesion antes de validar, asi que esto
    //      es defensivo: si por algun camino llega sin normalizar, lo
    //      detectamos aqui antes que MySQL.
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       G.PRIMERA, G.N ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  JOIN (SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '               CODIGO_ART_TENTATIVO_SESLIN, ' +
      '               MIN(LINEA_SESLIN) AS PRIMERA, ' +
      '               COUNT(*)          AS N ' +
      '          FROM fza_compras_sesiones_lineas ' +
      '         WHERE SERIE_SES_SESLIN = :s ' +
      '           AND NUMERO_SES_SESLIN = :n ' +
      '           AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
      '           AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '         GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '                  CODIGO_ART_TENTATIVO_SESLIN ' +
      '        HAVING COUNT(*) > 1) AS G ' +
      '    ON G.SERIE_SES_SESLIN            = L.SERIE_SES_SESLIN ' +
      '   AND G.NUMERO_SES_SESLIN           = L.NUMERO_SES_SESLIN ' +
      '   AND G.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      ' WHERE L.SERIE_SES_SESLIN  = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'') ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicadoInterno,
          Format(SErrorCodigoDuplicadoInternoSesion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  q.FieldByName('PRIMERA').AsInteger]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas con codigo duplicado externo sin accion resuelta
    //      (CODIGO_ART_TENTATIVO ya existe en fza_articulos y el usuario
    //      no eligio REUSAR ni RENOMBRAR). ----
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN, ' +
      '       A.ESACTIVO_ART ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      '  LEFT JOIN fza_articulos A ' +
      '         ON A.CODIGO_ART_ART = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.ESDUPLICADO_SESLIN = ''S'' ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''') ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicado,
          Format(SErrorCodigoDuplicadoSesion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  IfThen(q.FieldByName('ESACTIVO_ART').AsString = 'N',
                         STextoArticuloInactivoSesion, '')]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas sin CODIGO_ART_TENTATIVO_SESLIN ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (CODIGO_ART_TENTATIVO_SESLIN IS NULL ' +
      '        OR TRIM(CODIGO_ART_TENTATIVO_SESLIN) = '''') ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCodigo,
          SErrorLineaSesionSinCodigo);
      q.Next;
    end;
    q.Close;

    // ---- Lineas sin descripcion ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (DESCRIPCION_SESLIN IS NULL ' +
      '        OR TRIM(DESCRIPCION_SESLIN) = '''') ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDescripcion,
          Format(SErrorLineaSesionSinDescripcion,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas MATRIZ sin celdas con cantidad > 0 ----
    q.SQL.Text :=
      'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_celdas C ' +
      '                    WHERE C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
      '                      AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
      '                      AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
      '                      AND C.CANTIDAD_SESCEL > 0) ' +
      ' ORDER BY L.LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCantidades,
          Format(SErrorLineaMatrizSinCantidades,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                  q.FieldByName('DESCRIPCION_SESLIN').AsString]));
      q.Next;
    end;
    q.Close;

    // ---- Lineas MATRIZ sin ID_AC_PIVOT (sistema de tallas) ----
    q.SQL.Text :=
      'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
      '   AND (ID_AC_PIVOT_SESLIN IS NULL OR ID_AC_PIVOT_SESLIN = 0) ' +
      ' ORDER BY LINEA_SESLIN';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNum;
    q.Open;
    while not q.Eof do
    begin
      AnadirInc(q.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaSistemaTallas,
          Format(SErrorLineaMatrizSinSistemaTallas,
                 [q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString]));
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;

  Result := AIncidencias.Count = 0;
end;

function ContarArticulosNuevos(ADM: TdmComprasSesiones): Integer;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND (ACCION_DUPLICADO_SESLIN <> ''REUSAR'' ' +
      '        OR ACCION_DUPLICADO_SESLIN IS NULL)';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

function ContarSkusPotenciales(ADM: TdmComprasSesiones): Integer;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND CANTIDAD_SESCEL > 0';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('N').AsInteger;
  finally
    FreeAndNil(q);
  end;
end;

function CalcularTotalCompra(ADM: TdmComprasSesiones): Double;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(TOTAL_LINEA_SESLIN), 0) AS T ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n';
    q.ParamByName('s').AsString :=
      ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString :=
      ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.Open;
    Result := q.FieldByName('T').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
// Calculo de precio de venta
// ---------------------------------------------------------------------------

function CalcularPrecioVenta(ACoste, AMargenPct,
                             AMultiplo, AAjuste: Double): Double;
var
  rBase : Double;
begin
  // Convencion canonica del sistema (igual que inMtoModalCalcularMargen):
  //   precio = coste * margen / 100
  // margen 100 -> coste tal cual; 120 -> coste*1.20; 250 -> coste*2.50;
  // 400 -> coste*4.
  // AAjuste se RESTA del precio redondeado (descuento final: introducir
  // 0.01 para terminar en .99).
  rBase := ACoste * AMargenPct / 100;
  if AMultiplo > 0 then
    Result := Ceil(rBase / AMultiplo) * AMultiplo
  else
    Result := rBase;
  Result := Result - AAjuste;
  if Result < 0 then Result := 0;
end;

procedure CalcularPrecioVentaLinea(ADM: TdmComprasSesiones;
                                    const AUsuario: string;
                                    ALinea: Integer);
var
  q          : TUniQuery;
  rCoste, rMargenCab, rMargen,
  rMultiplo, rAjuste, rVenta : Double;
  iLinea     : Integer;
begin
  if ADM.unqrySesionLin.IsEmpty then Exit;

  if ALinea = -1 then
    iLinea := ADM.unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger
  else
    iLinea := ALinea;

  // Parametros de cabecera
  rMargenCab := ADM.unqryTablaG.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat;
  rMultiplo  := ADM.unqryTablaG.FieldByName('MULTIPLO_REDONDEO_SES').AsFloat;
  rAjuste    := ADM.unqryTablaG.FieldByName('AJUSTE_FINAL_SES').AsFloat;

  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'SELECT PRECIO_COMPRA_SESLIN, PORCENTAJE_MARGEN_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN = :l';
    q.ParamByName('s').AsString  := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString  := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := iLinea;
    q.Open;
    if q.IsEmpty then Exit;

    rCoste := q.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
    // Margen: si la linea tiene override usa ese, si no el de cabecera
    if q.FieldByName('PORCENTAJE_MARGEN_SESLIN').IsNull or
       (q.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat = 0) then
      rMargen := rMargenCab
    else
      rMargen := q.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  finally
    FreeAndNil(q);
  end;

  rVenta := CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);

  // Persistir
  q := TUniQuery.Create(nil);
  try
    q.Connection := ADM.ConexionPrincipal;
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones_lineas SET ' +
      '  PRECIO_VENTA_SESLIN = :v, ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
      ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
      '   AND LINEA_SESLIN = :l';
    q.ParamByName('v').AsFloat  := rVenta;
    q.ParamByName('u').AsString := AUsuario;
    q.ParamByName('s').AsString := ADM.unqryTablaG.FieldByName('SERIE_SES').AsString;
    q.ParamByName('n').AsString := ADM.unqryTablaG.FieldByName('NUMERO_SES').AsString;
    q.ParamByName('l').AsInteger := iLinea;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure CalcularPrecioVentaLineas(ADM: TdmComprasSesiones;
                                     const AUsuario: string;
                                     const ALineas: array of Integer);
var
  i: Integer;
begin
  for i := Low(ALineas) to High(ALineas) do
    CalcularPrecioVentaLinea(ADM, AUsuario, ALineas[i]);
  ADM.unqrySesionLin.Refresh;
end;

// ---------------------------------------------------------------------------
// Resolver codigo de familia -> codigo de articulo autogenerado
// ---------------------------------------------------------------------------

function ResolverCodigoFamilia(AConn: TUniConnection;
                                const ACodigoTecleado, AUsuario: string;
                                out ACodigoGenerado: string): Boolean;
var
  q       : TUniQuery;
  iCont   : Integer;
  iPad    : Integer;
  sFlag   : string;
  sNumero : string;
begin
  Result := False;
  ACodigoGenerado := '';
  if Trim(ACodigoTecleado) = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Comprobar si lo tecleado coincide con un CODIGO_FAM_FAM activo
    //    y con contador habilitado.
    q.SQL.Text :=
      'SELECT CONTADOR_ART_FAM, ESCONTADOR_ART_FAM, ' +
      '       IFNULL(PAD_ART_FAM, 5) AS PAD_ART_FAM ' +
      '  FROM fza_articulos_familias ' +
      ' WHERE CODIGO_FAM_FAM = :p ' +
      '   AND ESACTIVO_FAM   = ''S'' ' +
      ' FOR UPDATE';
    q.ParamByName('p').AsString := ACodigoTecleado;
    q.Open;
    if q.IsEmpty then Exit;

    sFlag := q.FieldByName('ESCONTADOR_ART_FAM').AsString;
    if sFlag <> 'S' then Exit;     // familia existe pero no autogenera

    iCont := q.FieldByName('CONTADOR_ART_FAM').AsInteger + 1;
    iPad  := q.FieldByName('PAD_ART_FAM').AsInteger;
    if iPad < 1 then iPad := 5;
    q.Close;

    // 2. Componer el codigo
    sNumero := IntToStr(iCont);
    while Length(sNumero) < iPad do
      sNumero := '0' + sNumero;
    ACodigoGenerado := ACodigoTecleado + sNumero;

    // 3. Persistir el incremento del contador
    q.SQL.Text :=
      'UPDATE fza_articulos_familias SET ' +
      '  CONTADOR_ART_FAM = :c, ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u ' +
      ' WHERE CODIGO_FAM_FAM = :p';
    q.ParamByName('c').AsInteger := iCont;
    q.ParamByName('u').AsString  := AUsuario;
    q.ParamByName('p').AsString  := ACodigoTecleado;
    q.ExecSQL;

    Result := True;
  finally
    FreeAndNil(q);
  end;
end;

// ---------------------------------------------------------------------------
// Reutilizacion de articulos ya existentes (ACCION_DUPLICADO=REUSAR)
// ---------------------------------------------------------------------------

function ResolverDuplicadoSesion(AConn: TUniConnection;
                                  const ACodigoBuscado,
                                        ACodigoProveedor: string;
                                  ASoloRefProveedor: Boolean;
                                  const ACodigoArticuloPreferido: string)
                                  : TResolverDuplicadoSesion;
var
  q          : TUniQuery;
  sCod       : string;
  sPrv       : string;
  sCodArtPref: string;
begin
  // El registro empieza a cero (Encontrado=False).
  Result := Default(TResolverDuplicadoSesion);
  sCod := Trim(ACodigoBuscado);
  sPrv := Trim(ACodigoProveedor);
  sCodArtPref := Trim(ACodigoArticuloPreferido);
  if sCod = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // 1. Match exacto por CODIGO_ART_ART. Trae todos los campos que
    //    necesitamos para inicializar la linea.
    if not ASoloRefProveedor then
    begin
      q.SQL.Text :=
        'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
        '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
        '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
        '       a.TIPO_VARIACION_ART, ' +
        '       f.NOMBRE_FAM_FAM, ' +
        '       (SELECT aca.ID_AC_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA = ''TAL'' ' +
        '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
        '       (SELECT aca.ID_VA_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA = ''TAL'' ' +
        '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
        '       (SELECT aca.ID_AC_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_AC_FILA, ' +
        '       (SELECT aca.ID_VA_ACA ' +
        '          FROM fza_articulos_conjuntos_asign aca ' +
        '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
        '           AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_VA_FILA, ' +
        '       (SELECT ap.PRECIO_ULT_COMPRA_AP ' +
        '          FROM fza_articulos_proveedores ap ' +
        '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
        '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
        '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
        '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
        '         AS PRECIO_ULT_COMPRA, ' +
        '       (SELECT ap.REF_PROVEEDOR_AP ' +
        '          FROM fza_articulos_proveedores ap ' +
        '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
        '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
        '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
        '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
        '         AS REF_PROVEEDOR ' +
        '  FROM fza_articulos a ' +
        '  LEFT JOIN fza_articulos_familias f ' +
        '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
        ' WHERE a.CODIGO_ART_ART = :art ' +
        '   AND a.ESACTIVO_ART = ''S''';
      q.ParamByName('art').AsString := sCod;
      q.ParamByName('prv').AsString := sPrv;
      q.Open;
      if not q.IsEmpty then
      begin
        Result.Encontrado     := True;
        Result.Origen         := 'ART';
        Result.CodigoArt      := q.FieldByName('CODIGO_ART_ART').AsString;
        Result.DescripcionArt := q.FieldByName('DESCRIPCION_ART').AsString;
        Result.CodigoFam      := q.FieldByName('CODIGO_FAM_ART').AsString;
        Result.NombreFam      := q.FieldByName('NOMBRE_FAM_FAM').AsString;
        Result.IdAcPivot      := q.FieldByName('ID_AC_PIVOT').AsInteger;
        Result.IdVaPivot      := q.FieldByName('ID_VA_PIVOT').AsString;
        Result.IdAcFila       := q.FieldByName('ID_AC_FILA').AsInteger;
        Result.IdVaFila       := q.FieldByName('ID_VA_FILA').AsString;
        Result.TipoVariacion  :=
          q.FieldByName('TIPO_VARIACION_ART').AsString;
        Result.EsVariacion    :=
          q.FieldByName('ESVARIACION_ART').AsString = 'S';
        Result.EsTrazable     :=
          q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        Result.TipoArt        := q.FieldByName('TIPO_ART').AsString;
        Result.TipoIva        := q.FieldByName('TIPO_IVA_ART').AsString;
        Result.TipoCantidad   := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
        Result.UltimoCoste    := q.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
        Result.RefProveedor   := q.FieldByName('REF_PROVEEDOR').AsString;
        Exit;
      end;
      q.Close;
    end;

    if sPrv = '' then Exit;

    // 2. Match por REF_PROVEEDOR_AP del proveedor de la cabecera. Si hay
    //    multiples articulos con la misma referencia para el mismo
    //    proveedor (no esta forzado por PK), el codigo elegido desde el
    //    desplegable desambigua. Si no viene, tomamos el principal o el
    //    primero por orden alfabetico.
    q.SQL.Text :=
      'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
      '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
      '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
      '       a.TIPO_VARIACION_ART, ' +
      '       f.NOMBRE_FAM_FAM, ' +
      '       ap.PRECIO_ULT_COMPRA_AP AS PRECIO_ULT_COMPRA, ' +
      '       ap.REF_PROVEEDOR_AP    AS REF_PROVEEDOR, ' +
      '       (SELECT aca.ID_AC_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '           AND aca.ID_VA_ACA = ''TAL'' ' +
      '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
      '       (SELECT aca.ID_VA_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '           AND aca.ID_VA_ACA = ''TAL'' ' +
      '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
      '       (SELECT aca.ID_AC_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '            AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_AC_FILA, ' +
      '       (SELECT aca.ID_VA_ACA ' +
      '          FROM fza_articulos_conjuntos_asign aca ' +
      '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
      '            AND aca.ID_VA_ACA  = ''CO'' LIMIT 1) AS ID_VA_FILA ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
      '                       AND a.ESACTIVO_ART = ''S'' ' +
      '  LEFT JOIN fza_articulos_familias f ' +
      '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
      ' WHERE ap.CODIGO_PRV_AP    = :prv ' +
      '   AND ap.REF_PROVEEDOR_AP = :ref ' +
      '   AND (:artpref = '''' OR ap.CODIGO_ART_AP = :artpref) ' +
      ' ORDER BY (ap.CODIGO_ART_AP = :artpref) DESC, ' +
      '          ap.ESPROVEEDORPRINCIPAL_AP DESC, a.CODIGO_ART_ART ' +
      ' LIMIT 1';
    q.ParamByName('prv').AsString := sPrv;
    q.ParamByName('ref').AsString := sCod;
    q.ParamByName('artpref').AsString := sCodArtPref;
    q.Open;
    if q.IsEmpty then Exit;

    Result.Encontrado     := True;
    Result.Origen         := 'REF';
    Result.CodigoArt      := q.FieldByName('CODIGO_ART_ART').AsString;
    Result.DescripcionArt := q.FieldByName('DESCRIPCION_ART').AsString;
    Result.CodigoFam      := q.FieldByName('CODIGO_FAM_ART').AsString;
    Result.NombreFam      := q.FieldByName('NOMBRE_FAM_FAM').AsString;
    Result.IdAcPivot      := q.FieldByName('ID_AC_PIVOT').AsInteger;
    Result.IdVaPivot      := q.FieldByName('ID_VA_PIVOT').AsString;
    Result.IdAcFila       := q.FieldByName('ID_AC_FILA').AsInteger;
    Result.IdVaFila       := q.FieldByName('ID_VA_FILA').AsString;
    Result.TipoVariacion  := q.FieldByName('TIPO_VARIACION_ART').AsString;
    Result.EsVariacion    :=
                        q.FieldByName('ESVARIACION_ART').AsString = 'S';
    Result.EsTrazable     :=
                        q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
    Result.TipoArt        := q.FieldByName('TIPO_ART').AsString;
    Result.TipoIva        := q.FieldByName('TIPO_IVA_ART').AsString;
    Result.TipoCantidad   := q.FieldByName('TIPO_CANTIDAD_ART').AsString;
    Result.UltimoCoste    := q.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
    Result.RefProveedor   := q.FieldByName('REF_PROVEEDOR').AsString;
  finally
    FreeAndNil(q);
  end;
end;

function ResolverDuplicadoIntraSesion(AConn: TUniConnection;
                                       const ASerieSes, ANumSes: string;
                                       ALineaActual: Integer;
                                       const AModelo, ACodigoArt: string)
                                       : TResolverDuplicadoSesion;
var
  q       : TUniQuery;
  sSerie  : string;
  sNumero : string;
  sModelo : string;
  sCodigo : string;
begin
  Result := Default(TResolverDuplicadoSesion);
  sSerie := Trim(ASerieSes);
  sNumero := Trim(ANumSes);
  sModelo := Trim(AModelo);
  sCodigo := Trim(ACodigoArt);
  if AConn = nil then
    Exit;
  if (sSerie = '') or (sNumero = '') then
    Exit;
  if (sModelo = '') and (sCodigo = '') then
    Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.DESCRIPCION_SESLIN, L.CODIGO_FAM_SESLIN, ' +
      '       L.TIPO_LINEA_SESLIN, L.TIPO_ART_SESLIN, ' +
      '       L.TIPO_IVA_SESLIN, L.TIPO_CANTIDAD_SESLIN, ' +
      '       L.ESTRAZABLE_SESLIN, L.CODIGO_VAR_SESLIN, ' +
      '       L.ID_VA_PIVOT_SESLIN, L.ID_AC_PIVOT_SESLIN, ' +
      '       L.ID_VA_FILA_SESLIN, L.ID_AC_FILA_SESLIN, ' +
      '       L.PRECIO_COMPRA_SESLIN, L.PRECIO_VENTA_SESLIN, ' +
      '       L.REF_PRV_SESLIN, L.LINEA_SESLIN, ' +
      '       L.COLOR_TEXTO_SESLIN, L.CODIGO_ATB_COLOR_SESLIN, ' +
      '       L.PORCENTAJE_MARGEN_SESLIN ' +
      '  FROM fza_compras_sesiones_lineas L ' +
      ' WHERE L.SERIE_SES_SESLIN = :serie ' +
      '   AND L.NUMERO_SES_SESLIN = :numero ' +
      '   AND L.LINEA_SESLIN <> :linea ' +
      '   AND TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '   AND ((:modelo <> '''' ' +
      '         AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
      '        OR (:codigo <> '''' ' +
      '            AND (TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) = :codigo ' +
      '                 OR TRIM(COALESCE(L.CODIGO_ART_REUSAR_SESLIN, '''')) ' +
      '                    = :codigo))) ' +
      ' ORDER BY CASE WHEN (:modelo <> '''' ' +
      '                 AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
      '               THEN 0 ELSE 1 END, ' +
      '          L.LINEA_SESLIN ' +
      ' LIMIT 1';
    q.ParamByName('serie').AsString := sSerie;
    q.ParamByName('numero').AsString := sNumero;
    q.ParamByName('linea').AsInteger := ALineaActual;
    q.ParamByName('modelo').AsString := sModelo;
    q.ParamByName('codigo').AsString := sCodigo;
    q.Open;
    if q.IsEmpty then
      Exit;
    Result.Encontrado := True;
    Result.Origen := 'SES';
    Result.CodigoArt :=
      q.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString;
    Result.DescripcionArt := q.FieldByName('DESCRIPCION_SESLIN').AsString;
    Result.CodigoFam := q.FieldByName('CODIGO_FAM_SESLIN').AsString;
    Result.IdAcPivot := q.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    Result.IdVaPivot := q.FieldByName('ID_VA_PIVOT_SESLIN').AsString;
    Result.IdAcFila := q.FieldByName('ID_AC_FILA_SESLIN').AsInteger;
    Result.IdVaFila := q.FieldByName('ID_VA_FILA_SESLIN').AsString;
    Result.TipoVariacion := q.FieldByName('CODIGO_VAR_SESLIN').AsString;
    Result.TipoArt := q.FieldByName('TIPO_ART_SESLIN').AsString;
    Result.TipoIva := q.FieldByName('TIPO_IVA_SESLIN').AsString;
    Result.TipoCantidad := q.FieldByName('TIPO_CANTIDAD_SESLIN').AsString;
    Result.EsTrazable := q.FieldByName('ESTRAZABLE_SESLIN').AsString = 'S';
    Result.EsVariacion :=
      SameText(q.FieldByName('TIPO_LINEA_SESLIN').AsString, 'MATRIZ');
    Result.UltimoCoste := q.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
    Result.PrecioVenta := q.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
    Result.RefProveedor := q.FieldByName('REF_PRV_SESLIN').AsString;
    // Datos extra de la linea origen para la copia completa opcional.
    Result.LineaOrigen := q.FieldByName('LINEA_SESLIN').AsInteger;
    Result.ColorTexto := q.FieldByName('COLOR_TEXTO_SESLIN').AsString;
    Result.CodigoAtbColor :=
      q.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
    Result.MargenPorcentaje :=
      q.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

// Devuelve el PVP "padre" (CODIGO_UNIDAD_ARTTAR='') del articulo en la
// tarifa indicada; si no hay tarifa o esa fila no existe, cae a cualquier
// tarifa activa del articulo. 0 si el articulo no tiene tarifa. Se usa para
// proponer en la linea el PVP anterior como referencia al reusar un modelo
// ya existente (el usuario solo lo cambia si el documento trae otro precio).
function ObtenerPvpArticulo(AConn: TUniConnection;
                            const ACodArt, ACodTar: string): Double;
var
  q: TUniQuery;
begin
  Result := 0;
  if Trim(ACodArt) = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT t.PRECIO_FINAL_ARTTAR ' +
      '  FROM fza_articulos_tarifas t ' +
      ' WHERE t.CODIGO_ART_ARTTAR    = :art ' +
      '   AND t.CODIGO_UNIDAD_ARTTAR = '''' ' +
      '   AND (t.ESACTIVO_ARTTAR = ''S'' ' +
      '        OR t.CODIGO_TAR_ARTTAR = :tar) ' +
      ' ORDER BY (t.CODIGO_TAR_ARTTAR = :tar) DESC, ' +
      '          t.ESACTIVO_ARTTAR DESC, ' +
      '          t.FECHA_DESDE_ARTTAR DESC, ' +
      '          t.CODIGO_UNICO_ARTTAR DESC ' +
      ' LIMIT 1';
    q.ParamByName('art').AsString := ACodArt;
    q.ParamByName('tar').AsString := ACodTar;
    q.Open;
    if not q.IsEmpty then
      Result := q.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;

procedure AplicarDuplicadoEnLinea(ADM: TdmComprasSesiones;
                                   const AResul: TResolverDuplicadoSesion);
var
  ds: TDataSet;
  sTipoLinea: string;
  sTar: string;
  rPvp: Double;
begin
  if not AResul.Encontrado then Exit;
  if ADM = nil then Exit;
  ds := ADM.unqrySesionLin;
  if ds = nil then Exit;
  if ds.IsEmpty then Exit;
  if not (ds.State in [dsEdit, dsInsert]) then ds.Edit;

  // Marca REUSAR + codigo del articulo a reutilizar.
  ds.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
  ds.FieldByName('ACCION_DUPLICADO_SESLIN').AsString  := 'REUSAR';
  ds.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString := AResul.CodigoArt;
  ds.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := AResul.CodigoArt;

  // Datos del articulo. No machacamos descripcion si el usuario ya
  // tecleo algo (>0 caracteres distinto) — pero al ser REUSAR del
  // mismo articulo, la descripcion oficial es la del maestro: la
  // sobrescribimos siempre.
  ds.FieldByName('DESCRIPCION_SESLIN').AsString := AResul.DescripcionArt;
  if AResul.CodigoFam <> '' then
    ds.FieldByName('CODIGO_FAM_SESLIN').AsString := AResul.CodigoFam;
  if AResul.TipoArt <> '' then
    ds.FieldByName('TIPO_ART_SESLIN').AsString := AResul.TipoArt;
  if AResul.TipoIva <> '' then
    ds.FieldByName('TIPO_IVA_SESLIN').AsString := AResul.TipoIva;
  if AResul.TipoCantidad <> '' then
    ds.FieldByName('TIPO_CANTIDAD_SESLIN').AsString := AResul.TipoCantidad;
  if AResul.TipoVariacion <> '' then
    ds.FieldByName('CODIGO_VAR_SESLIN').AsString := AResul.TipoVariacion;
  ds.FieldByName('ESTRAZABLE_SESLIN').AsString :=
                                 IfThen(AResul.EsTrazable, 'S', 'N');

  // TIPO_LINEA segun ESVARIACION.
  if AResul.EsVariacion then sTipoLinea := 'MATRIZ' else sTipoLinea := 'ESCALAR';
  ds.FieldByName('TIPO_LINEA_SESLIN').AsString := sTipoLinea;

  // Ejes de variacion (pivot=tallas, fila=color).
  if AResul.IdAcPivot > 0 then
    ds.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := AResul.IdAcPivot;
  if AResul.IdVaPivot <> '' then
    ds.FieldByName('ID_VA_PIVOT_SESLIN').AsString := AResul.IdVaPivot;
  if AResul.IdAcFila > 0 then
    ds.FieldByName('ID_AC_FILA_SESLIN').AsInteger := AResul.IdAcFila;
  if AResul.IdVaFila <> '' then
    ds.FieldByName('ID_VA_FILA_SESLIN').AsString := AResul.IdVaFila;

  // Coste del proveedor del modelo resuelto. Se sobrescribe siempre para
  // no dejar valores de un modelo anterior en la misma linea.
  ds.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat := AResul.UltimoCoste;

  // PVP de referencia: precio de la tarifa de venta de la cabecera para el
  // articulo reusado. Tambien se sobrescribe siempre para que al cambiar
  // de modelo no sobreviva el precio del articulo anterior.
  if AResul.Origen = 'SES' then
    ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := AResul.PrecioVenta
  else
  begin
    sTar := '';
    rPvp := 0;
    if (ADM.unqryTablaG <> nil) and (not ADM.unqryTablaG.IsEmpty) then
    begin
      sTar := Trim(ADM.unqryTablaG.FieldByName('CODIGO_TAR_SES').AsString);
      rPvp := ObtenerPvpArticulo(ADM.unqryTablaG.Connection,
                                 AResul.CodigoArt, sTar);
    end;
    ds.FieldByName('PRECIO_VENTA_SESLIN').AsFloat := rPvp;
  end;

  // Si el match vino por CODIGO_ART y conocemos la REF del proveedor
  // de la cabecera, rellenamos REF_PRV_SESLIN para la traza.
  // Si el match vino por REF, el campo ya lleva lo que el usuario
  // tecleo (y coincide con lo que hay en la BBDD).
  if (AResul.Origen = 'ART') and (AResul.RefProveedor <> '') and
     (Trim(ds.FieldByName('REF_PRV_SESLIN').AsString) = '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
  if (AResul.Origen = 'SES') and (AResul.RefProveedor <> '') then
    ds.FieldByName('REF_PRV_SESLIN').AsString := AResul.RefProveedor;
end;

function NormalizarDuplicadosIntraSesion(AConn: TUniConnection;
                                          const AUsuario, ASerieSes,
                                                ANumSes: string): Integer;
var
  q : TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    // Para cada (CODIGO_ART_TENTATIVO_SESLIN) que aparece >1 veces en la
    // sesion, dejamos la primera linea (LINEA_SESLIN minimo) intacta y
    // marcamos el resto como REUSAR del mismo codigo. Asi InsertarArticulo
    // solo se ejecuta una vez por codigo durante la materializacion y las
    // demas lineas (variantes color/SKU) comparten la cabecera del
    // articulo en fza_articulos.
    //
    // Solo tocamos lineas que NO tienen ACCION_DUPLICADO ya resuelta
    // (NULL / vacia / distinta de REUSAR) — respetamos elecciones del
    // usuario (p. ej. si decidio RENOMBRAR alguna ya estara con su
    // codigo final distinto, no entra en este grupo).
    q.SQL.Text :=
      'UPDATE fza_compras_sesiones_lineas L ' +
      '  JOIN ( ' +
      '       SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '              CODIGO_ART_TENTATIVO_SESLIN, ' +
      '              MIN(LINEA_SESLIN) AS PRIMERA, ' +
      '              COUNT(*)          AS N ' +
      '         FROM fza_compras_sesiones_lineas ' +
      '        WHERE SERIE_SES_SESLIN = :s ' +
      '          AND NUMERO_SES_SESLIN = :n ' +
      '          AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
      '          AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
      '        GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
      '                 CODIGO_ART_TENTATIVO_SESLIN ' +
      '       HAVING COUNT(*) > 1 ' +
      '  ) AS G ' +
      '    ON G.SERIE_SES_SESLIN            = L.SERIE_SES_SESLIN ' +
      '   AND G.NUMERO_SES_SESLIN           = L.NUMERO_SES_SESLIN ' +
      '   AND G.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN ' +
      '   SET L.ESDUPLICADO_SESLIN       = ''S'', ' +
      '       L.ACCION_DUPLICADO_SESLIN  = ''REUSAR'', ' +
      '       L.CODIGO_ART_REUSAR_SESLIN = L.CODIGO_ART_TENTATIVO_SESLIN, ' +
      '       L.USUARIO_MODIF            = :u, ' +
      '       L.INSTANTE_MODIF           = NOW() ' +
      ' WHERE L.SERIE_SES_SESLIN  = :s ' +
      '   AND L.NUMERO_SES_SESLIN = :n ' +
      '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
      '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
      '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
      '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'')';
    q.ParamByName('s').AsString := ASerieSes;
    q.ParamByName('n').AsString := ANumSes;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
    Result := q.RowsAffected;
  finally
    FreeAndNil(q);
  end;
end;

end.
