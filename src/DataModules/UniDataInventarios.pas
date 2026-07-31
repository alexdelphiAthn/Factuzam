{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInventarios                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de inventarios.                                               }
{    Cabeceras y líneas de fza_inventarios, regularizaciones de stock y        }
{    movimientos generados.                                                    }
{******************************************************************************}
unit UniDataInventarios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, Winapi.Windows, Data.DB, MemDS, DBAccess,
  Uni, Datasnap.DBClient, Datasnap.Provider, UniProvider, MySQLUniProvider,
  UniDataGen, Vcl.Controls, System.UITypes;

type
  // Cabecera (heredado de TdmBase)
  TdmInventarios = class(TdmBase)

    // === LÍNEAS DEL INVENTARIO (Detalle pestaña 2) ===
    unqryLineas: TUniQuery;                    // Líneas físicas en BD
    udspLineas: TDataSetProvider;
    cdsLineas: TClientDataSet;                 // Buffer cliente para edición
    dsLineas: TDataSource;

    // === CAMPOS CALCULADOS DE cdsLineas ===
    cdsLineasCODIGO_EMPRESA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ALMACEN_INVENTARIO_LINEA: TWideStringField;
    cdsLineasSERIE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasNRO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLINEA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_UNIDAD_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLOTE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasFECHA_CADUCIDAD_INVENTARIO_LINEA: TDateField;
    cdsLineasDESCRIPCION_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCANTIDAD_TEORICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_FISICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_DIFERENCIA_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_NUEVO_INVENTARIO_LINEA: TFloatField;
    cdsLineasTOTAL_COSTE_DIFERENCIA_LINEA: TFloatField;
    cdsLineasFECHA_RECUENTO_INVENTARIO_LINEA: TDateTimeField;
    // Conjunto pivotado en tallas horizontal (0 = sin pivote); columna
    // nueva de inventarios_tallas_horizontal.sql (ColumnSKUcxGrid).
    cdsLineasID_AC_PIVOT_INV_LINEA: TIntegerField;

    // === Campos in-memory para SKUs dinámicos (1 a 5 atributos) ===
    cdsLineasNUM_ATRIBUTOS_REQ_INV_LINEA: TIntegerField;
    cdsLineasATTR1_NOMBRE: TWideStringField;
    cdsLineasATTR1_VALOR: TWideStringField;
    cdsLineasATTR2_NOMBRE: TWideStringField;
    cdsLineasATTR2_VALOR: TWideStringField;
    cdsLineasATTR3_NOMBRE: TWideStringField;
    cdsLineasATTR3_VALOR: TWideStringField;
    cdsLineasATTR4_NOMBRE: TWideStringField;
    cdsLineasATTR4_VALOR: TWideStringField;
    cdsLineasATTR5_NOMBRE: TWideStringField;
    cdsLineasATTR5_VALOR: TWideStringField;
    // Unidades regularizadas (calculado: 0 si ABIERTO, =DIFERENCIA si APLICADO)
    cdsLineasUDS_REGULARIZADAS: TFloatField;

    // === MOVIMIENTOS DE ALMACÉN GENERADOS POR ESTE INVENTARIO (Pestaña 3) ===
    unqryMovsRegul: TUniQuery;
    dsMovsRegul: TDataSource;

    // === CONSULTAS AUXILIARES ===
    unqryArticulo: TUniQuery;                  // Buscar artículo por código
    unqryDefinicionArticulo: TUniQuery;        // Definición atributos del SKU
    unqryStockActual: TUniQuery;               // Lectura PMP/Stock actual
    unqryFamilias: TUniQuery;                  // Lookup familias
    dsFamilias: TDataSource;
    unqryProveedores: TUniQuery;               // Lookup proveedores
    dsProveedores: TDataSource;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    unqrySeries: TUniQuery;
    dsSeries: TDataSource;

    // === STORED PROCEDURES ===
    // PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO
    unspActualizarTeorico: TUniStoredProc;
    unspAplicar: TUniStoredProc;               // PRC_FZA_INVENTARIOS_APLICAR
    unspEliminarRegul: TUniStoredProc;
    cdsLineasINSTANTE_ALTA: TDateTimeField;
    cdsLineasUSUARIO_ALTA: TWideStringField;
    cdsLineasUSUARIO_MODIF: TWideStringField;
    // PRC_FZA_INVENTARIOS_ELIMINAR_REGUL (nuevo)
    cdsLineasINSTANTE_MODIF: TDateTimeField;

    // === EVENTOS DE DATASET ===
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterScroll(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasBeforeInsert(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
    procedure cdsLineasCalcFields(DataSet: TDataSet);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
  private
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FSerie: string;
    FNumero: string;
    FUsuario: string;
    FDesempaquetando: Boolean;
    FColumnasRecuentoRemoto: Boolean;
    FColumnaContadorLineas: Boolean;
    // Flag idempotente: True cuando ATTR1..ATTR5_VALOR ya estan rellenos
    // a partir del SKU para las lineas actualmente cargadas en cdsLineas.
    // Se resetea a False cada vez que CargarLineasInventario reabre cds.
    FLineasDesempaquetadas: Boolean;
    // True mientras el modo TALLAS EN HORIZONTAL (ColumnSKUcxGrid)
    // esta activo o convirtiendo lineas (pivote/des-pivote): el
    // backstop de atributos y la validacion de SKU de BeforePost no
    // aplican a sus Posts intermedios.
    FModoPivoteActivo: Boolean;
    // True cuando el modo de entrada del contrato ensenya atributos
    // (desglose): CADA recarga de lineas desempaqueta SKU->ATTR aqui
    // mismo. Las recargas llegan por varios caminos (AfterScroll de
    // cabecera, cargas masivas...) y si alguna se salta el form, los
    // ATTR in-memory quedaban en blanco hasta reconstruir a mano.
    FDesempaquetarAlCargar: Boolean;
    function ObtenerSeriePorDefecto(const AEmpresa,
                                          ATipoDoc: string): string;
    function ExisteColumnaInventarios(const ACampo: string): Boolean;
    procedure GetCodigoAutoInventario;
    procedure PrepararSqlCabecera;
    // Quita Required=True de todos los persistent fields de cdsLineas. La
    // herencia via udspLineas + poIncFieldProps hacia que el cds rechazara
    // el Post antes de cdsLineasBeforePost.
    procedure ForzarRequiredFalseEnCdsLineas;
  public
    // === CONFIGURACIÓN ===
    procedure SetClavesActivas(const AEmpresa,
                               AAlmacen,
                               ASerie,
                               ANumero: string);
    // Ver FModoPivoteActivo: lo gobierna inMtoInventarios al
    // construir/desmontar el modo de tallas en horizontal.
    property ModoPivoteActivo: Boolean read FModoPivoteActivo
                                       write FModoPivoteActivo;
    // Ver FDesempaquetarAlCargar: lo gobierna inMtoInventarios segun
    // el modo de entrada activo (True en desglose).
    property DesempaquetarAlCargar: Boolean
      read FDesempaquetarAlCargar write FDesempaquetarAlCargar;

    // === CARGA DE LÍNEAS ===
    procedure CargarLineasInventario;
    procedure CargarMovimientosRegularizacion;

    // === GESTIÓN DE LÍNEAS ===
    function GenerarSiguienteLinea: string;
    function FechaRecuentoPorDefecto: TDateTime;
    procedure AsegurarFechaRecuentoLinea;
    function ExisteLineaConSku(const ASku: string): Boolean;
    function GenerarSkuFinal(const AArticuloBase: string): string;
    procedure RellenarDatosArticulo(const ACodigoArticulo: string;
                                    out ADescripcion: string;
                                    out ANumAtributos: Integer;
                                    out ATipoArticulo: string);
    procedure RellenarDatosSku(const ASku: string;
                               out ACantidadTeorica: Currency;
                               out APMPActual: Currency);

    // === CARGAS MASIVAS ===
    procedure CargarPorFamilia(const ACodigoFamilia: string);
    procedure CargarPorProveedor(const ACodigoProveedor: string);
    procedure CargarTodosArticulosConStock;
    procedure CompletarUnidadesNoLeidas;
    procedure CargarDesdeListaSkus(ALista: TStringList);
    function  CargarSkusConMovimientosArticulo(
      const ACodigoArticulo: string): Integer;
    function  SkuExiste(const ASku: string): Boolean;
    function  CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
                                 const AAtributos: array of string): Boolean;

    // === ACCIONES SOBRE INVENTARIO ===
    function GetEstadoInventario: string;
    procedure AbrirDetalles; override;
    procedure RecalcularTeorico;
    // Camino sincrono original. Tiene instrumentacion [PERF:Aplicar] y
    // bloquea la UI hasta terminar. Util para llamadas batch o pruebas.
    procedure AplicarInventario;
    // Camino partido en 3 para Fase 2 (background). El llamador (el form)
    // ejecuta Pre y Refrescar en el main thread (tocan grids) y deja el
    // SP en TfrmMtoGen.EjecutarEnBackground. Ver TfrmMtoInventarios.btnAplicarClick.
    procedure PreAplicarValidaciones;
    procedure EjecutarSPAplicar;
    procedure RefrescarTrasAplicar;
    procedure EliminarRegularizacion;

    // === PROPIEDADES ===
    property CodigoEmpresa: string read FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen;
    property Serie: string read FSerie;
    property Numero: string read FNumero;
    property ColumnasRecuentoRemoto: Boolean read FColumnasRecuentoRemoto;
    // True una vez que DesempaquetarAtributosDesdeSku ha rellenado los
    // ATTR1..ATTR5_VALOR de las lineas actuales. El form consulta este
    // flag para no relanzar el desempaquetado si ya esta hecho.
    property LineasDesempaquetadas: Boolean read FLineasDesempaquetadas;

    procedure CargarAlmacenesPorEmpresa(const ACodigoEmpresa: string);
    procedure CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
    // Recorre cdsLineas rellenando ATTR1..ATTR5_VALOR a partir de
    // CODIGO_UNIDAD_INVLIN (SKU). Es idempotente: si FLineasDesempaquetadas
    // ya esta a True, sale sin hacer nada. El form lo invoca via
    // AsegurarDesempaquetadoAtributos cuando el toggle "Ver atributos en
    // columnas" esta activo (con barra de progreso si hay >150 lineas).
    procedure DesempaquetarAtributosDesdeSku;
  end;

implementation

uses
  Vcl.Dialogs,          // MessageDlg para validación de SKU en BeforePost
  System.Diagnostics,   // TStopwatch para instrumentacion de rendimiento
  System.StrUtils,      // IfThen(Boolean, string, string) para snapshot
  inLibUser,            // Usuario logueado
  inLibLog,             // Log.LogInfo para metricas
  inLibData,
  UniDataConn,
  inLibMsgArticulos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmInventarios }

procedure TdmInventarios.CargarLineasInventario;
begin
  // FNumero='0' es el marcador de "cabecera todavia sin numero asignado":
  // unqryTablaGAfterInsert lo pone, y BeforePost lo sustituye por el numero
  // real via GetCodigoAutoInventario. Si consultamos lineas con '0', traemos
  // cualquier linea huerfana persistida con esa clave de una insercion
  // previa que se cancelo despues de grabar lineas (registro fantasma).
  if (FCodigoEmpresa = '') or (FNumero = '') or (FNumero = '0') then
  begin
    if cdsLineas.Active then cdsLineas.EmptyDataSet;
    Exit;
  end;

  // Defensa contra reentrada: cdsLineasBeforeInsert puede llamar a
  // unqryTablaG.Post mientras cdsLineas esta a punto de entrar en dsInsert.
  // Si en esa secuencia AfterScroll/Refresh acaba reentrando aqui, cerrar
  // cdsLineas a mitad de un Insert deja el dataset en un estado inconsistente.
  if cdsLineas.Active and (cdsLineas.State in [dsInsert, dsEdit]) then
    Exit;

  unqryLineas.Close;
  unqryLineas.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
  unqryLineas.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryLineas.ParamByName('SERIE').AsString   := FSerie;
  unqryLineas.ParamByName('NUMERO').AsString  := FNumero;
  unqryLineas.Open;
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.Open;
  // El Open vuelve a inicializar Required a partir del provider
  // (poIncFieldProps default True). Lo deshacemos.
  ForzarRequiredFalseEnCdsLineas;

  // Lineas recien cargadas: los ATTR1..ATTR5_VALOR aun no estan rellenos.
  // El form decide cuando llamar a DesempaquetarAtributosDesdeSku (solo si
  // el usuario activa "Ver atributos en columnas") para no comerse N
  // Edit/Post en cada apertura.
  FLineasDesempaquetadas := False;
  // Contrato de entrada en desglose: los ATTR se rellenan AQUI, en la
  // misma recarga, venga de donde venga (ver FDesempaquetarAlCargar).
  if FDesempaquetarAlCargar then
    DesempaquetarAtributosDesdeSku;
end;

procedure TdmInventarios.DesempaquetarAtributosDesdeSku;
var
  Sku, ValorAtr: string;
  Partes: TArray<string>;
  i: Integer;
  Bm: TBookmark;
begin
  if (not cdsLineas.Active) or cdsLineas.IsEmpty then
    Exit;
  // Idempotente: si ya se desempaqueto para las lineas actualmente
  // cargadas, no relanzar el bucle. Si CargarLineasInventario recarga
  // las lineas, resetea FLineasDesempaquetadas y volvemos a entrar.
  if FLineasDesempaquetadas then
    Exit;
  FDesempaquetando := True;
  Bm := cdsLineas.GetBookmark;
  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      Sku := cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
      if Sku <> '' then
      begin
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          if not (cdsLineas.State in [dsEdit, dsInsert]) then
            cdsLineas.Edit;
          // Tantos atributos como segmentos haya tras el código de artículo.
          // Sin esto, GenerarSkuFinal itera 0 veces sobre las líneas cargadas
          // de BBDD y el SKU se queda obsoleto al cambiar Color/Talla.
          cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger :=
                                                          Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              ValorAtr := Partes[i]
            else
              ValorAtr := '';
            cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString :=
              ValorAtr;
          end;
          // AfterPost ya no enviara a BD (FDesempaquetando=True)
          cdsLineas.Post;
        end;
      end;
      cdsLineas.Next;
    end;
    cdsLineas.MergeChangeLog;
    FLineasDesempaquetadas := True;
  finally
    if cdsLineas.BookmarkValid(Bm) then
      cdsLineas.GotoBookmark(Bm);
    cdsLineas.FreeBookmark(Bm);
    cdsLineas.EnableControls;
    FDesempaquetando := False;
  end;
end;

procedure TdmInventarios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := ConexionPrincipal;
  unqryLineas.Connection           := ConexionPrincipal;
  unqryMovsRegul.Connection        := ConexionPrincipal;
  unqryArticulo.Connection         := ConexionPrincipal;
  unqryDefinicionArticulo.Connection := ConexionPrincipal;
  unqryStockActual.Connection      := ConexionPrincipal;
  unqryFamilias.Connection         := ConexionPrincipal;
  unqryProveedores.Connection      := ConexionPrincipal;
  unqryAlmacenes.Connection        := ConexionPrincipal;
  unqryEmpresas.Connection         := ConexionPrincipal;
  unqrySeries.Connection           := ConexionPrincipal;
  unspActualizarTeorico.Connection := ConexionPrincipal;
  unspAplicar.Connection           := ConexionPrincipal;
  unspEliminarRegul.Connection     := ConexionPrincipal;
  PrepararSqlCabecera;

  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_inventarios_lineas SET ' + sLineBreak +
    '  CODIGO_ART_INVLIN              = :CODIGO_ART_INVLIN,' + sLineBreak +
    '  CODIGO_UNIDAD_INVLIN           = :CODIGO_UNIDAD_INVLIN,' + sLineBreak +
    '  LOTE_INVLIN                    = :LOTE_INVLIN,' + sLineBreak +
    '  FECHA_CADUCIDAD_INVLIN         = :FECHA_CADUCIDAD_INVLIN,' + sLineBreak +
    '  DESCRIPCION_ARTICULO_INVLIN    = :DESCRIPCION_ARTICULO_INVLIN,'
      + sLineBreak +
    '  CANTIDAD_TEORICA_INVLIN        = :CANTIDAD_TEORICA_INVLIN,'
      + sLineBreak +
    '  CANTIDAD_FISICA_INVLIN         = :CANTIDAD_FISICA_INVLIN,' + sLineBreak +
    '  CANTIDAD_DIFERENCIA_INVLIN     = :CANTIDAD_DIFERENCIA_INVLIN,'
      + sLineBreak +
    '  PRECIO_MEDIO_INVLIN            = :PRECIO_MEDIO_INVLIN,' + sLineBreak +
    '  PRECIO_MEDIO_NUEVO_INVLIN      = :PRECIO_MEDIO_NUEVO_INVLIN,'
      + sLineBreak +
    '  TOTAL_COSTE_DIFERENCIA_INVLIN  = :TOTAL_COSTE_DIFERENCIA_INVLIN,'
      + sLineBreak +
    '  FECHA_RECUENTO_INVLIN          = :FECHA_RECUENTO_INVLIN,' + sLineBreak +
    '  ID_AC_PIVOT_INVLIN             = :ID_AC_PIVOT_INVLIN,' + sLineBreak +
    '  USUARIO_MODIF                  = :USUARIO_MODIF ' + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN ' + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN ' + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN ' + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN ' + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_inventarios_lineas ' + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN ' + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN ' + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN ' + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN ' + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  // Apertura de los lookups
  if not unqryEmpresas.Active   then unqryEmpresas.Open;
  if not unqryAlmacenes.Active  then unqryAlmacenes.Open;
  if not unqrySeries.Active     then unqrySeries.Open;
  if not unqryFamilias.Active   then unqryFamilias.Open;
  if not unqryProveedores.Active then unqryProveedores.Open;

  // Desactivamos Required en todos los persistent fields de cdsLineas. Con
  // poIncFieldProps a True (default de udspLineas), el TClientDataSet
  // hereda Required=True desde el esquema NOT NULL de la BBDD y rechaza
  // el Post con "Field value required" antes incluso de llegar a
  // cdsLineasBeforePost (que es donde damos mensajes claros y rellenamos
  // CODIGO_UNIDAD_INVLIN si llega vacio). NewRecord, BeforePost y la BBDD
  // siguen siendo los responsables reales de la integridad — la BBDD
  // rechazara cualquier INSERT NULL con un error 1048 que UniDataConn
  // ya traduce a "Hay campos obligatorios sin rellenar".
  ForzarRequiredFalseEnCdsLineas;

  FUsuario := IdentidadSesion.Usuario;
end;

procedure TdmInventarios.ForzarRequiredFalseEnCdsLineas;
var
  i: Integer;
begin
  if cdsLineas = nil then Exit;
  for i := 0 to cdsLineas.FieldCount - 1 do
    cdsLineas.Fields[i].Required := False;
  for i := 0 to cdsLineas.FieldDefs.Count - 1 do
    cdsLineas.FieldDefs[i].Required := False;
end;

function TdmInventarios.ExisteColumnaInventarios(const ACampo: string): Boolean;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := unqryTablaG.Connection;
    qry.SQL.Text :=
      'SELECT COUNT(*) AS N' + sLineBreak +
      '  FROM INFORMATION_SCHEMA.COLUMNS' + sLineBreak +
      ' WHERE TABLE_SCHEMA = DATABASE()' + sLineBreak +
      '   AND TABLE_NAME = ''fza_inventarios''' + sLineBreak +
      '   AND COLUMN_NAME = :campo';
    qry.ParamByName('campo').AsString := ACampo;
    qry.Open;
    Result := qry.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.PrepararSqlCabecera;
begin
  FColumnaContadorLineas := ExisteColumnaInventarios('CONTADOR_LINEAS_INV');
  FColumnasRecuentoRemoto :=
    ExisteColumnaInventarios('ESRECUENTO_REMOTO_INV') and
    ExisteColumnaInventarios('INSTANTE_ENVIO_RECUENTO_INV') and
    ExisteColumnaInventarios('INSTANTE_RECOGIDA_RECUENTO_INV') and
    ExisteColumnaInventarios('ID_RECUENTO_REMOTO_INV');
  unqryTablaG.Close;
  unqryTablaG.SQL.BeginUpdate;
  try
    unqryTablaG.SQL.Clear;
    unqryTablaG.SQL.Add('SELECT');
    unqryTablaG.SQL.Add('   CODIGO_EMP_INV,');
    unqryTablaG.SQL.Add('   CODIGO_ALM_INV,');
    unqryTablaG.SQL.Add('   SERIE_INV,');
    unqryTablaG.SQL.Add('   NUMERO_INV,');
    unqryTablaG.SQL.Add('   TIPO_DOC_INV,');
    unqryTablaG.SQL.Add('   FECHA_INV,');
    unqryTablaG.SQL.Add('   ESTADO_INV,');
    unqryTablaG.SQL.Add('   DESCRIPCION_INV,');
    unqryTablaG.SQL.Add('   OBSERVACIONES_INV,');
    unqryTablaG.SQL.Add('   TOTAL_UNIDADES_DIFERENCIA_INV,');
    unqryTablaG.SQL.Add('   TOTAL_EUROS_DIFERENCIA_INV,');
    if not FColumnaContadorLineas then
      Log.LogWarning('Inventarios: falta CONTADOR_LINEAS_INV. Ejecutar ' +
        'DESARROLLOS EN CURSO\inventarios_contador_lineas.sql antes de ' +
        'anadir lineas manuales.');
    if FColumnasRecuentoRemoto then
    begin
      unqryTablaG.SQL.Add('   ESRECUENTO_REMOTO_INV,');
      unqryTablaG.SQL.Add('   INSTANTE_ENVIO_RECUENTO_INV,');
      unqryTablaG.SQL.Add('   INSTANTE_RECOGIDA_RECUENTO_INV,');
      unqryTablaG.SQL.Add('   ID_RECUENTO_REMOTO_INV,');
    end
    else
      Log.LogWarning('Inventarios: faltan columnas de recuento remoto. ' +
        'La lista se abrira sin esos campos; ejecutar ' +
        'DESARROLLOS EN CURSO\recuento_inventarios_factuzam.sql.');
    unqryTablaG.SQL.Add('   INSTANTE_ALTA, INSTANTE_MODIF,');
    unqryTablaG.SQL.Add('   USUARIO_ALTA,  USUARIO_MODIF');
    unqryTablaG.SQL.Add('FROM fza_inventarios');
    unqryTablaG.SQL.Add('ORDER BY FECHA_INV DESC');
  finally
    unqryTablaG.SQL.EndUpdate;
  end;
end;

procedure TdmInventarios.SetClavesActivas(const AEmpresa, AAlmacen, ASerie,
  ANumero: string);
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FSerie         := ASerie;
  FNumero        := ANumero;
end;

procedure TdmInventarios.unqryTablaGAfterScroll(DataSet: TDataSet);
begin
  // La apertura async dispara AfterScroll desde un thread. Las lineas y
  // movimientos se abren en AbrirDetalles, ya en el hilo principal.
  if (not DataSet.IsEmpty) and
     (not DataSet.ControlsDisabled) and
     (GetCurrentThreadId = MainThreadID) then
  begin
    // OJO: aqui SI hay que resincronizar incluso durante dsInsert.
    // Al pulsar "+" desde una cabecera cargada, AfterInsert pone NUMERO='0'
    // y CargarLineasInventario vacia el detalle sin consultar la BD.
    SetClavesActivas(DataSet.FieldByName('CODIGO_EMP_INV').AsString,
                     DataSet.FieldByName('CODIGO_ALM_INV').AsString,
                     DataSet.FieldByName('SERIE_INV').AsString,
                     DataSet.FieldByName('NUMERO_INV').AsString);
    CargarLineasInventario;
    CargarMovimientosRegularizacion;
  end;
end;

procedure TdmInventarios.AbrirDetalles;
begin
  inherited;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    unqryTablaGAfterScroll(unqryTablaG);
end;

procedure TdmInventarios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Pre-rellenamos los datos por defecto del usuario logueado al crear un
  // inventario nuevo, igual que hace facturas:
  //   - empresa/almacen del usuario (UbicacionSesion.Empresa/UbicacionSesion.Almacen, cargados en login)
  //   - serie por defecto de la empresa para tipo IN
  //   - NUMERO_INV='0' como marcador para que BeforePost asigne el contador
  //     real desde fza_contadores via PRC_GET_NEXT_CONT_FACT_SERIE.
  if Trim(UbicacionSesion.Empresa) <> '' then
    DataSet.FieldByName('CODIGO_EMP_INV').AsString := UbicacionSesion.Empresa;
  if Trim(UbicacionSesion.Almacen) <> '' then
    DataSet.FieldByName('CODIGO_ALM_INV').AsString := UbicacionSesion.Almacen;
  DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
  DataSet.FieldByName('FECHA_INV').AsDateTime  := Now;
  DataSet.FieldByName('ESTADO_INV').AsString   := 'ABIERTO';
  DataSet.FieldByName('NUMERO_INV').AsString   := '0';
  if Trim(UbicacionSesion.Empresa) <> '' then
    DataSet.FieldByName('SERIE_INV').AsString  :=
                                       ObtenerSeriePorDefecto(UbicacionSesion.Empresa, 'IN');
  CargarAlmacenesPorEmpresa(
    DataSet.FieldByName('CODIGO_EMP_INV').AsString);
end;

procedure TdmInventarios.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
//
end;

procedure TdmInventarios.unqryTablaGBeforePost(DataSet: TDataSet);
var
  campoRecuento: TField;
begin
  inherited;
  // ESRECUENTO_REMOTO_INV es char(1) NOT NULL en BBDD (default 'N'). Al
  // anadirse al SELECT de la cabecera es un campo Required del dataset, asi
  // que una cabecera nueva (que no se ha enviado a recuento) llegaria al Post
  // con el valor sin asignar y reventaria con "Field 'ESRECUENTO_REMOTO_INV'
  // must have a value". Garantizamos el valor por defecto antes del Post.
  campoRecuento := DataSet.FindField('ESRECUENTO_REMOTO_INV');
  if campoRecuento <> nil then
    if Trim(campoRecuento.AsString) = '' then
      campoRecuento.AsString := 'N';
  // Validacion explicita: la serie es parte de la PK de las lineas y
  // varchar(20) NOT NULL en BBDD. Si llega vacia (porque la empresa no
  // tiene una serie por defecto en fza_empresas_series para tipo IN),
  // la cabecera se grabaria con SERIE_INV='' y las lineas heredarian
  // ese vacio, que despues hace reventar el TClientDataSet en Post con
  // un cryptico "Field value required" desde DSBase / MidasLib.
  if Trim(DataSet.FieldByName('SERIE_INV').AsString) = '' then
    raise Exception.Create(SErrorSerieInventarioObligatoria);
  // Forzamos campos de auditoría
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
    if DataSet.FieldByName('FECHA_INV').IsNull then
      DataSet.FieldByName('FECHA_INV').AsDateTime := Now;
    if DataSet.FieldByName('ESTADO_INV').AsString = '' then
      DataSet.FieldByName('ESTADO_INV').AsString := 'ABIERTO';
    if DataSet.FieldByName('TIPO_DOC_INV').AsString = '' then
      DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
    // Si el numero viene a '0' (recien insertado), tomamos el contador real
    // de fza_contadores. El SP esta nombrado como FACT_SERIE pero es generico
    // y acepta cualquier tipo de documento + serie + empresa.
    if DataSet.FieldByName('NUMERO_INV').AsString = '0' then
      GetCodigoAutoInventario;
  end;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
end;

function TdmInventarios.ObtenerSeriePorDefecto(const AEmpresa,
                                                     ATipoDoc: string): string;
var
  qry: TUniQuery;
begin
  Result := '';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT EMPSER ' +
      '  FROM fza_empresas_series ' +
      ' WHERE CODIGO_EMP_EMPSER = :EMPRESA ' +
      '   AND TIPO_DOC_EMPSER  = :TIPO ' +
      '   AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= NOW()) ' +
      '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= NOW()) ' +
      ' ORDER BY FECHA_DESDE_EMPSER DESC ' +
      ' LIMIT 1';
    qry.ParamByName('EMPRESA').AsString := AEmpresa;
    qry.ParamByName('TIPO').AsString    := ATipoDoc;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('EMPSER').AsString;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.GetCodigoAutoInventario;
var
  sp: TUniStoredProc;
begin
  if unqryTablaG.FindField('NUMERO_INV').AsString <> '0' then Exit;
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection := ConexionPrincipal;
    sp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString, 'pserie',           ptInput);
    sp.Params.CreateParam(ftString, 'ptipodoc',         ptInput);
    sp.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR',ptInput);
    sp.Params.CreateParam(ftString, 'pUSUARIOMODIF',    ptInput);
    sp.Params.CreateParam(ftString, 'pcont',            ptOutput);
    sp.ParamByName('pserie').AsString :=
                            unqryTablaG.FindField('SERIE_INV').AsString;
    sp.ParamByName('ptipodoc').AsString := 'IN';
    sp.ParamByName('pEMPRESA_CONTADOR').AsString :=
                            unqryTablaG.FindField('CODIGO_EMP_INV').AsString;
    sp.ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
    sp.ExecProc;
    unqryTablaG.FindField('NUMERO_INV').AsString :=
                                              sp.ParamByName('pcont').AsString;
  finally
    FreeAndNil(sp);
  end;
end;

procedure TdmInventarios.CargarMovimientosRegularizacion;
begin
  unqryMovsRegul.Close;
  if (FCodigoEmpresa = '') or (FCodigoAlmacen = '') or
     (FSerie = '') or (FNumero = '') then Exit;

  // Los movimientos de regularización solo existen si el inventario ya
  // ha sido APLICADO. Si el estado es ABIERTO o CANCELADO, no consultamos.
  if GetEstadoInventario <> 'APLICADO' then Exit;

  unqryMovsRegul.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
  unqryMovsRegul.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryMovsRegul.ParamByName('SERIE').AsString   := FSerie;
  unqryMovsRegul.ParamByName('NUMERO').AsString  := FNumero;
  unqryMovsRegul.Open;
end;

function TdmInventarios.GenerarSiguienteLinea: string;
var
  bTransPropia: Boolean;
  iNuevaLinea: Integer;
  qry: TUniQuery;
begin
  Result := '';
  if not FColumnaContadorLineas then
    raise Exception.Create(SErrorContadorLineasInventarioNoInstalado);
  if (Trim(FCodigoEmpresa) = '') or (Trim(FCodigoAlmacen) = '') or
     (Trim(FSerie) = '') or (Trim(FNumero) = '') or
     (Trim(FNumero) = '0') then
    raise Exception.Create(SErrorCabeceraInventarioSinGrabarParaReserva);
  bTransPropia := not ConexionPrincipal.InTransaction;
  if bTransPropia then
    ConexionPrincipal.StartTransaction;
  qry := TUniQuery.Create(nil);
  try
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(CONTADOR_LINEAS_INV ' +
        'AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM fza_inventarios ' +
        ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
        '   AND CODIGO_ALM_INV = :ALMACEN ' +
        '   AND SERIE_INV = :SERIE ' +
        '   AND NUMERO_INV = :NUMERO ' +
        ' FOR UPDATE';
      qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SERIE').AsString := FSerie;
      qry.ParamByName('NUMERO').AsString := FNumero;
      qry.Open;
      if qry.Eof then
        raise Exception.Create(SErrorCabeceraInventarioNoEncontrada);
      iNuevaLinea := qry.FieldByName('NV').AsInteger + 1;
      qry.Close;
      qry.SQL.Text :=
        'UPDATE fza_inventarios ' +
        '   SET CONTADOR_LINEAS_INV = :NUEVO ' +
        ' WHERE CODIGO_EMP_INV = :EMPRESA ' +
        '   AND CODIGO_ALM_INV = :ALMACEN ' +
        '   AND SERIE_INV = :SERIE ' +
        '   AND NUMERO_INV = :NUMERO';
      qry.ParamByName('NUEVO').AsString := Format('%.8d', [iNuevaLinea]);
      qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
      qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
      qry.ParamByName('SERIE').AsString := FSerie;
      qry.ParamByName('NUMERO').AsString := FNumero;
      qry.ExecSQL;
      if qry.RowsAffected = 0 then
        raise Exception.Create(SErrorActualizarContadorLineasInventario);
      if bTransPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Commit;
      Result := Format('%.4d', [iNuevaLinea]);
    except
      if bTransPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmInventarios.FechaRecuentoPorDefecto: TDateTime;
var
  CampoFecha: TField;
begin
  Result := Now;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    CampoFecha := unqryTablaG.FindField('FECHA_INV');
    if (CampoFecha <> nil) and (not CampoFecha.IsNull) then
      Result := CampoFecha.AsDateTime;
  end;
end;

procedure TdmInventarios.AsegurarFechaRecuentoLinea;
var
  CampoFecha: TField;
begin
  CampoFecha := nil;
  if (cdsLineas <> nil) and cdsLineas.Active then
    CampoFecha := cdsLineas.FindField('FECHA_RECUENTO_INVLIN');
  if (CampoFecha <> nil) and CampoFecha.IsNull then
    CampoFecha.AsDateTime := FechaRecuentoPorDefecto;
end;

function TdmInventarios.ExisteLineaConSku(const ASku: string): Boolean;
var
  Bookmark: TBookmark;
begin
  Result := False;
  if not cdsLineas.Active then
  begin
    Exit;
  end;

  Bookmark := cdsLineas.GetBookmark;
  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if SameText(cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString,
                  ASku) then
      begin
        Result := True;
        Break;
      end;
      cdsLineas.Next;
    end;
  finally
    if cdsLineas.BookmarkValid(Bookmark) then
      cdsLineas.GotoBookmark(Bookmark);
    cdsLineas.FreeBookmark(Bookmark);
    cdsLineas.EnableControls;
  end;
end;

function TdmInventarios.GenerarSkuFinal(const AArticuloBase: string): string;
var
  i, NumAttr: Integer;
  ValorAttr: string;
begin
  // Construye el SKU concatenando ARTICULO/ATTR1/ATTR2/... con los valores
  // que haya rellenados en cdsLineas. Si algun valor falta, se omite (el SKU
  // queda incompleto, lo que el llamante interpreta para decidir si ya hay
  // que recalcular teoricas/PMP).
  Result := AArticuloBase;
  if not cdsLineas.Active then Exit;
  if cdsLineas.FindField('NUM_ATRIBUTOS_REQ_INV_LINEA') = nil then Exit;
  NumAttr := cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  for i := 1 to NumAttr do
  begin
    ValorAttr :=
      cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString;
    if Trim(ValorAttr) <> '' then
      Result := Result + '/' + ValorAttr;
  end;
end;

procedure TdmInventarios.RellenarDatosArticulo(const ACodigoArticulo: string;
  out ADescripcion: string; out ANumAtributos: Integer;
  out ATipoArticulo: string);
var
  swTotal, swQry1, swQry2: TStopwatch;
  msArt, msDef: Int64;
begin
  ADescripcion  := '';
  ANumAtributos := 0;
  ATipoArticulo := 'ESTANDAR';
  msDef := 0;
  swTotal := TStopwatch.StartNew;

  swQry1 := TStopwatch.StartNew;
  unqryArticulo.Close;
  unqryArticulo.ParamByName('CODIGO').AsString := ACodigoArticulo;
  unqryArticulo.Open;
  msArt := swQry1.ElapsedMilliseconds;

  if not unqryArticulo.IsEmpty then
  begin
    ADescripcion  := unqryArticulo.FieldByName('DESCRIPCION_ART').AsString;
    ATipoArticulo := unqryArticulo.FieldByName('TIPO_ART').AsString;
    // Conteo de atributos del artículo padre
    swQry2 := TStopwatch.StartNew;
    unqryDefinicionArticulo.Close;
    unqryDefinicionArticulo.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    unqryDefinicionArticulo.Open;
    ANumAtributos := unqryDefinicionArticulo.RecordCount;
    msDef := swQry2.ElapsedMilliseconds;
  end;

  inLibLog.Log.LogPerf('RellenarDatosArticulo',
    Format('articulo=%s NumAtr=%d | unqryArticulo=%d ' +
           'unqryDefinicionArticulo=%d',
           [ACodigoArticulo, ANumAtributos, msArt, msDef]),
    swTotal.ElapsedMilliseconds);
end;

procedure TdmInventarios.RellenarDatosSku(const ASku: string;
  out ACantidadTeorica: Currency; out APMPActual: Currency);
var
  swTotal: TStopwatch;
begin
  ACantidadTeorica := 0;
  APMPActual       := 0;
  swTotal := TStopwatch.StartNew;

  unqryStockActual.Close;
  unqryStockActual.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryStockActual.ParamByName('SKU').AsString     := ASku;
  unqryStockActual.Open;

  if not unqryStockActual.IsEmpty then
  begin
    ACantidadTeorica := unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency;
    APMPActual := unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
  end;

  inLibLog.Log.LogPerf('RellenarDatosSku',
    Format('sku=%s almacen=%s teo=%.2f pmp=%.4f',
           [ASku, FCodigoAlmacen, ACantidadTeorica, APMPActual]),
    swTotal.ElapsedMilliseconds);
end;

procedure TdmInventarios.cdsLineasNewRecord(DataSet: TDataSet);
begin
  // Defaults al insertar una línea nueva.
  // Inicializamos a '' los campos NOT NULL del BD (CODIGO_ART_INVLIN,
  // CODIGO_UNIDAD_INVLIN) en vez de dejarlos NULL: asi al pulsar Grabar el
  // TClientDataSet.Post no falla con "Field value required" antes de que
  // cdsLineasBeforePost pueda dar un mensaje claro.
  DataSet.FieldByName('CODIGO_EMP_INVLIN').AsString := FCodigoEmpresa;
  DataSet.FieldByName('CODIGO_ALM_INVLIN').AsString := FCodigoAlmacen;
  DataSet.FieldByName('SERIE_INV_INVLIN').AsString  := FSerie;
  DataSet.FieldByName('NUMERO_INV_INVLIN').AsString := FNumero;
  DataSet.FieldByName('LINEA_INVLIN').AsString      := GenerarSiguienteLinea;
  DataSet.FieldByName('CODIGO_ART_INVLIN').AsString    := '';
  DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := '';
  DataSet.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency    := 0;
  DataSet.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency     := 0;
  DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency := 0;
  DataSet.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency        := 0;
  DataSet.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency  := 0;
  DataSet.FieldByName('FECHA_RECUENTO_INVLIN').AsDateTime      :=
    FechaRecuentoPorDefecto;
  DataSet.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger        := 0;
  DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
  // INSTANTE_ALTA / INSTANTE_MODIF son NOT NULL en BBDD con DEFAULT. El
  // TClientDataSet propaga Required=True por poIncFieldProps y, si los
  // dejamos NULL en el buffer, el Post de cdsLineas revienta con
  // "Field value required" antes incluso de llegar al provider. La BBDD
  // sobrescribira INSTANTE_MODIF en su ON UPDATE; aqui solo necesitamos
  // un valor inicial valido.
  DataSet.FieldByName('INSTANTE_ALTA').AsDateTime  := Now;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmInventarios.cdsLineasCalcFields(DataSet: TDataSet);
var
  Estado: string;
  Diferencia: Currency;
begin
  // El cálculo de uds regularizadas: si el inventario está APLICADO,
  // entonces es la propia diferencia. Si está ABIERTO/CANCELADO es 0.
  Estado := GetEstadoInventario;
  Diferencia := DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency;

  if Estado = 'APLICADO' then
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := Diferencia
  else
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := 0;
end;

procedure TdmInventarios.cdsLineasBeforePost(DataSet: TDataSet);
var
  CodArticulo, CodSku, Valor, SkuRebuilt: string;
  Atribs: array[0..4] of string;
  i, NumAtr: Integer;
  Snapshot: string;
  F: TField;
begin
  // Validamos antes de Post para dar un mensaje claro en lugar del cryptico
  // "Field value required" del TClientDataSet.
  if FDesempaquetando then Exit;
  // Belt-and-suspenders: aunque ya forzamos Required:=False en
  // DataModuleCreate y tras cada cdsLineas.Open, el cds puede recibir
  // un poIncFieldProps reactivado por alguna llamada interna durante
  // la edicion. Lo volvemos a apagar ahora mismo, justo antes del
  // chequeo InternalCheck del TClientDataSet (que ocurre tras nuestra
  // BeforePost). Solo TOCAMOS los campos del propio cds (DataSet).
  for i := 0 to DataSet.FieldCount - 1 do
    DataSet.Fields[i].Required := False;
  // Volcado del estado actual de los campos al log: si volvemos a ver
  // un EDBClient 'Field value required', el log nos dice exactamente
  // que campo iba vacio cuando el cds decidio rechazar el Post.
  Snapshot := '';
  for i := 0 to DataSet.FieldCount - 1 do
  begin
    F := DataSet.Fields[i];
    if Snapshot <> '' then Snapshot := Snapshot + ' | ';
    if F.IsNull then
      Snapshot := Snapshot + F.FieldName + '=<NULL>' +
        IfThen(F.Required, '(REQ)', '')
    else
      Snapshot := Snapshot + F.FieldName + '=' + F.AsString +
        IfThen(F.Required, '(REQ)', '');
  end;
  inLibLog.Log.LogInfo('[cdsLineasBeforePost] state=' +
    IntToStr(Ord(DataSet.State)) + ' | ' + Snapshot);
  AsegurarFechaRecuentoLinea;

  // Las 4 PK del inventario (empresa, almacen, serie, numero) son
  // varchar NOT NULL. DSBase / MidasLib trata el string vacio como
  // "valor requerido faltante" y revienta el Post con un
  // EDBClient 'Field value required' generico antes incluso de mandar
  // nada a la BBDD. Cazamos cada caso aqui con un mensaje claro.
  if Trim(DataSet.FieldByName('CODIGO_EMP_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorEmpresaCabeceraInventarioObligatoria);
  if Trim(DataSet.FieldByName('CODIGO_ALM_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorAlmacenCabeceraInventarioObligatorio);
  if Trim(DataSet.FieldByName('SERIE_INV_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorSerieCabeceraInventarioObligatoria);
  if Trim(DataSet.FieldByName('NUMERO_INV_INVLIN').AsString) = '' then
    raise Exception.Create(SErrorNumeroCabeceraInventarioObligatorio);

  // Linea sin articulo: cancelar silenciosamente en vez de lanzar
  // excepcion. El cxGrid hace Post automatico al navegar con las
  // flechas; si la linea es un placeholder vacio, Cancel + Abort
  // lo descarta sin molestar al usuario.
  if Trim(DataSet.FieldByName('CODIGO_ART_INVLIN').AsString) = '' then
  begin
    // Diferir el Cancel: no se puede llamar dentro de BeforePost
    // porque el dataset esta en medio de un Post. El Abort cancela
    // el Post y deja el registro en dsEdit/dsInsert; el Cancel
    // posterior lo revierte a Browse.
    TThread.ForceQueue(nil,
      procedure
      begin
        if cdsLineas.Active and (cdsLineas.State in [dsEdit, dsInsert]) then
          cdsLineas.Cancel;
      end);
    Abort;
  end;
  // Si por alguna razon CODIGO_UNIDAD_INVLIN ha quedado vacio, lo rellenamos
  // con el codigo del articulo. CODIGO_UNIDAD_INVLIN es NOT NULL en BD.
  if Trim(DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString) = '' then
    DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      DataSet.FieldByName('CODIGO_ART_INVLIN').AsString;

  CodArticulo := DataSet.FieldByName('CODIGO_ART_INVLIN').AsString;

  // LINEA PIVOTADA o MODO TALLAS ACTIVO (prueba ColumnSKUcxGrid): la
  // talla vive en las CELDAS (fza_inventarios_celdas) y la linea
  // consolida articulo+color, asi que ni tiene SKU cerrado ni debe
  // reconstruirse aqui. El flag cubre ademas los Posts intermedios de
  // la conversion (lineas con unidad=padre y pivote aun 0, p.ej.
  // DEMO-CAMISA sin SKU). El des-pivote regenera lineas por SKU
  // completo, que si pasan las validaciones cuando el modo se apaga.
  if FModoPivoteActivo or
     ((DataSet.FindField('ID_AC_PIVOT_INVLIN') <> nil) and
      (DataSet.FieldByName('ID_AC_PIVOT_INVLIN').AsInteger > 0)) then
    Exit;

  // BACKSTOP: si el artículo tiene atributos requeridos, reconstruimos el SKU
  // a partir de ATTRn_VALOR aquí mismo. Así, aunque OnAtributoChanged falle
  // silenciosamente al cambiar Color/Talla, no dejamos pasar al Post (y luego
  // a PRC_FZA_INVENTARIOS_APLICAR) una línea con CODIGO_UNIDAD_INVLIN igual
  // al artículo padre, que generaba movimientos huérfanos sin SKU.
  NumAtr := DataSet.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  if NumAtr > 0 then
  begin
    SkuRebuilt := CodArticulo;
    for i := 1 to NumAtr do
    begin
      Valor := Trim(DataSet.FieldByName('ATTR' + IntToStr(i) +
                                                          '_VALOR').AsString);
      if Valor = '' then
        raise Exception.CreateFmt(SErrorAtributoLineaInventarioObligatorio,
          [DataSet.FieldByName('LINEA_INVLIN').AsString,
           CodArticulo, NumAtr, i]);
      SkuRebuilt := SkuRebuilt + '/' + Valor;
    end;
    if DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString <> SkuRebuilt then
      DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := SkuRebuilt;
  end;

  // Validación de SKU: si la línea apunta a un SKU con atributos
  // (CODIGO_UNIDAD_INVLIN ≠ CODIGO_ART_INVLIN) que no existe en
  // fza_articulos_skus, preguntar al usuario si quiere crearlo. Sin esto,
  // PRC_FZA_INVENTARIOS_APLICAR genera movimientos huérfanos sobre un SKU
  // que no existe ni en fza_articulos_skus ni en fza_atributos_sku, y el
  // stock no aparece bien en las pestañas de stock pivotado.
  CodSku := DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
  if (CodSku <> CodArticulo) and (not SkuExiste(CodSku)) then
  begin
    if MessageDlg(
         Format(SPreguntaCrearSkuInventario, [CodSku]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      raise Exception.CreateFmt(SErrorSkuInventarioNoExiste, [CodSku]);

    for i := 0 to 4 do
      Atribs[i] := DataSet.FieldByName('ATTR' + IntToStr(i + 1) +
                                                          '_VALOR').AsString;
    CrearSkuDesdeLinea(CodArticulo, CodSku, Atribs);
  end;
end;

procedure TdmInventarios.cdsLineasAfterPost(DataSet: TDataSet);
begin
  // Durante el desempaquetado de atributos in-memory NO debemos enviar
  // cambios a BD: esos campos no existen en fza_inventarios_lineas.
  if FDesempaquetando then
    Exit;

  if cdsLineas.ChangeCount > 0 then
    cdsLineas.ApplyUpdates(0);
end;

procedure TdmInventarios.cdsLineasBeforeDelete(DataSet: TDataSet);
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorEliminarLineasInventarioNoAbierto);
end;

procedure TdmInventarios.cdsLineasBeforeInsert(DataSet: TDataSet);
begin
  // Si la linea actual es un placeholder sin articulo (p.ej. el usuario
  // pulso Insert pero no relleno nada), cancelar antes de que
  // CheckBrowseMode intente Post (que fallaria en BeforePost con
  // 'No se puede grabar una linea sin articulo').
  if DataSet.State in [dsEdit, dsInsert] then
  begin
    if Trim(DataSet.FieldByName('CODIGO_ART_INVLIN').AsString) = '' then
      DataSet.Cancel;
  end;
  // Exigimos que la cabecera tenga un NUMERO_INV definitivo. Si sigue
  // en dsInsert con NUMERO_INV='0' (marcador), cdsLineasNewRecord
  // copiaria ese '0' y la linea quedaria huerfana.
  if (unqryTablaG = nil) or (not unqryTablaG.Active) then Exit;
  if unqryTablaG.State in [dsInsert, dsEdit] then
  begin
    try
      unqryTablaG.Post;
    except
      on E: Exception do
      begin
        raise Exception.Create(Format(SErrorAnadirLineaCabeceraInventario,
                                      [E.Message]));
      end;
    end;
    SetClavesActivas(
      unqryTablaG.FieldByName('CODIGO_EMP_INV').AsString,
      unqryTablaG.FieldByName('CODIGO_ALM_INV').AsString,
      unqryTablaG.FieldByName('SERIE_INV').AsString,
      unqryTablaG.FieldByName('NUMERO_INV').AsString
    );
  end;
end;

procedure TdmInventarios.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  // Persistir la eliminacion en BBDD (mismo patron que AfterPost).
  if cdsLineas.ChangeCount > 0 then
    cdsLineas.ApplyUpdates(0);
end;

function TdmInventarios.GetEstadoInventario: string;
begin
  Result := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    Result := unqryTablaG.FieldByName('ESTADO_INV').AsString;
end;

procedure TdmInventarios.RecalcularTeorico;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorRecalcularInventarioNoAbierto);

  // Aseguramos que cualquier cambio pendiente se persiste antes de llamar al
  // SP. Si la linea recien insertada esta incompleta (sin articulo picado)
  // hacer Post da "Field value required". Cancelamos en ese caso.
  if cdsLineas.Active then
  begin
    if cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if (Trim(cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString) = '') or
         (Trim(cdsLineas.FieldByName(
           'CODIGO_UNIDAD_INVLIN').AsString) = '') then
        cdsLineas.Cancel
      else
        cdsLineas.Post;
    end;
    if cdsLineas.ChangeCount > 0 then
      cdsLineas.ApplyUpdates(0);
  end;

  unspActualizarTeorico.Close;
  unspActualizarTeorico.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspActualizarTeorico.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspActualizarTeorico.ParamByName('p_SERIE').AsString   := FSerie;
  unspActualizarTeorico.ParamByName('p_NRO').AsString     := FNumero;
  unspActualizarTeorico.ParamByName('p_USUARIO').AsString := FUsuario;
  unspActualizarTeorico.ExecProc;

  // Refrescamos las líneas
  CargarLineasInventario;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.PreAplicarValidaciones;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorAplicarInventarioNoAbierto);

  // Post defensivo + ApplyUpdates: vuelca cambios pendientes del cdsLineas
  // (buffer cliente) a BBDD via el provider. Debe correr en main thread
  // porque cdsLineas esta vinculado al grid tvLineas y Post/ApplyUpdates
  // disparan eventos UI (cdsLineasAfterPost, repintado de filas, etc).
  if cdsLineas.Active then
  begin
    if cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if (Trim(cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString) = '') or
         (Trim(cdsLineas.FieldByName(
           'CODIGO_UNIDAD_INVLIN').AsString) = '') then
        cdsLineas.Cancel
      else
        cdsLineas.Post;
    end;
    if cdsLineas.ChangeCount > 0 then
      cdsLineas.ApplyUpdates(0);
  end;

  // Salvaguarda: no aplicar un inventario sin líneas. Sin esto, la SP
  // PRC_FZA_INVENTARIOS_APLICAR cambia el estado a APLICADO sin generar
  // ningún movimiento, y cualquier línea con diferencia 0 se purga al
  // entrar en la SP, dejando un inventario vacío y aplicado.
  if (not cdsLineas.Active) or cdsLineas.IsEmpty then
    raise Exception.Create(SErrorAplicarInventarioSinLineas);
end;

procedure TdmInventarios.EjecutarSPAplicar;
begin
  // Solo el ExecProc. Es la pieza apta para background: no toca grids,
  // solo BBDD a traves de unspAplicar (que apunta a FConn del Mto desde
  // Fase 1). Mientras corre, otros tabs siguen interactivos.
  unspAplicar.Close;
  unspAplicar.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspAplicar.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspAplicar.ParamByName('p_SERIE').AsString   := FSerie;
  unspAplicar.ParamByName('p_NRO').AsString     := FNumero;
  unspAplicar.ParamByName('p_USUARIO').AsString := FUsuario;
  unspAplicar.ExecProc;
end;

procedure TdmInventarios.RefrescarTrasAplicar;
begin
  // Recarga de queries vinculadas a grids (tvLineas, tvMovsRegul) y la
  // lista principal. Debe correr en main thread.
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.AplicarInventario;
var
  swTotal, swTramo: TStopwatch;
  msApply, msExecProc, msRecargas, msRefresh: Int64;
begin
  // [PERF:Aplicar] Camino sincrono instrumentado. Mide los 4 tramos para
  // tener una base de comparacion con el camino background (Fase 2).
  swTotal := TStopwatch.StartNew;

  swTramo := TStopwatch.StartNew;
  PreAplicarValidaciones;
  msApply := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  EjecutarSPAplicar;
  msExecProc := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  msRecargas := swTramo.ElapsedMilliseconds;

  swTramo := TStopwatch.StartNew;
  unqryTablaG.Refresh;
  msRefresh := swTramo.ElapsedMilliseconds;

  inLibLog.Log.LogInfo(Format(
    '[PERF:Aplicar] total=%d ms | ApplyUpdates=%d | ExecProc=%d | ' +
    'Recargas=%d | Refresh=%d (emp=%s alm=%s ser=%s nro=%s)',
    [swTotal.ElapsedMilliseconds, msApply, msExecProc, msRecargas, msRefresh,
     FCodigoEmpresa, FCodigoAlmacen, FSerie, FNumero]));
end;

procedure TdmInventarios.EliminarRegularizacion;
begin
  if GetEstadoInventario <> 'APLICADO' then
    raise Exception.Create(SErrorEliminarRegularizacionInventarioNoAplicado);

  unspEliminarRegul.Close;
  unspEliminarRegul.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspEliminarRegul.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspEliminarRegul.ParamByName('p_SERIE').AsString   := FSerie;
  unspEliminarRegul.ParamByName('p_NRO').AsString     := FNumero;
  unspEliminarRegul.ParamByName('p_USUARIO').AsString := FUsuario;
  unspEliminarRegul.ExecProc;

  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.CargarPorFamilia(const ACodigoFamilia: string);
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)        AS CANTIDAD, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0)    AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.CODIGO_FAM_ART = :FAMILIA ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('FAMILIA').AsString := ACodigoFamilia;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        // Saltar duplicados
        if not ExisteLineaConSku(qry.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          // por defecto = teórica
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          // por defecto = anterior
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarPorProveedor(const ACodigoProveedor: string);
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)     AS CANTIDAD, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = ap.CODIGO_ARTICULO_AP ' +
      '  JOIN fza_articulos_skus s ' +
      '    ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE ap.CODIGO_PROVEEDOR_AP = :PROVEEDOR ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString   := FCodigoAlmacen;
    qry.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not ExisteLineaConSku(qry.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarTodosArticulosConStock;
var
  qry: TUniQuery;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not ExisteLineaConSku(qry.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
            qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CompletarUnidadesNoLeidas;
var
  qry: TUniQuery;
begin
  // "Completar" significa: traer al inventario todos los SKUs con stock que NO
  // estén ya en el inventario actual, asignándoles cantidad física = 0
  // (porque NO se han contado / son los que faltan).
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCompletarInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_inventarios_lineas l ' +
      '          WHERE l.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '            AND l.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '            AND l.SERIE_INV_INVLIN          = :SERIE ' +
      '            AND l.NUMERO_INV_INVLIN            = :NUMERO ' +
      '            AND l.CODIGO_UNIDAD_INVLIN  = s.CODIGO_UNIDAD_SKU) ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    qry.ParamByName('SERIE').AsString   := FSerie;
    qry.ParamByName('NUMERO').AsString  := FNumero;
    qry.Open;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString :=
          qry.FieldByName('CODIGO_ART_SKU').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   :=
          qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
          qry.FieldByName('DESCRIPCION_ART').AsString;
        cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
          qry.FieldByName('CANTIDAD').AsCurrency;
        // OJO: en COMPLETAR, la cantidad física es 0 — porque por
        // definición no se ha contado
        cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := 0;
        cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
          qry.FieldByName('PMP').AsCurrency;
        cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
          qry.FieldByName('PMP').AsCurrency;
        cdsLineas.Post;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmInventarios.CargarSkusConMovimientosArticulo(
  const ACodigoArticulo: string): Integer;
var
  qry: TUniQuery;
  Sku: string;
begin
  // Inserta una línea de inventario por cada SKU distinto del artículo
  // ACodigoArticulo que tenga al menos un movimiento en el almacén actual.
  // Salta SKUs que ya estén presentes en este inventario.
  // Devuelve el número de líneas insertadas.
  Result := 0;
  if Trim(ACodigoArticulo) = '' then
    raise Exception.Create(SErrorArticuloLineaInventarioObligatorio);
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorAnadirSkusInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT DISTINCT m.CODIGO_UNIDAD_MOV AS CODIGO_UNIDAD_SKU, ' +
      '       m.CODIGO_ART_MOV    AS CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       COALESCE(stk.CANTIDAD_STK, 0)     AS CANTIDAD_TEORICA, ' +
      '       COALESCE(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_movimientos_almacen m ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK = m.CODIGO_UNIDAD_MOV ' +
      '   AND stk.CODIGO_ALM_STK    = :ALMACEN ' +
      ' WHERE m.CODIGO_ART_MOV = :ARTICULO ' +
      '   AND m.CODIGO_ALM_MOV = :ALMACEN ' +
      ' ORDER BY m.CODIGO_UNIDAD_MOV';
    qry.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    qry.ParamByName('ALMACEN').AsString  := FCodigoAlmacen;
    qry.Open;

    if qry.IsEmpty then Exit;

    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        Sku := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        if (Sku <> '') and (not ExisteLineaConSku(Sku)) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString     :=
            qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString  := Sku;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            qry.FieldByName('CANTIDAD_TEORICA').AsCurrency;
          // Recuento por defecto = teorica (igual que
          // CargarPorFamilia/Proveedor):
          // diferencia 0. Si el usuario hace el recuento real lo sobreescribe.
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            qry.FieldByName('CANTIDAD_TEORICA').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
          Inc(Result);
        end;
        qry.Next;
      end;
      if Result > 0 then
      begin
        cdsLineas.ApplyUpdates(0);
        // Las lineas nuevas no tienen ATTR1..5_VALOR rellenos. Invalidamos
        // el flag para que el form, si tiene el toggle "Ver atributos"
        // activo, relance DesempaquetarAtributosDesdeSku (con su barra
        // de progreso si toca) en el siguiente FocusedRecordChanged.
        // Si el toggle esta off no perdemos nada: las columnas SKU1..5
        // estan ocultas.
        FLineasDesempaquetadas := False;
      end;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmInventarios.SkuExiste(const ASku: string): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  if Trim(ASku) = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus ' +
                    ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
    qry.ParamByName('SKU').AsString := ASku;
    qry.Open;
    Result := not qry.IsEmpty;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmInventarios.CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
  const AAtributos: array of string): Boolean;
var
  qry: TUniQuery;
  i, IdAv: Integer;
  ValorAtrib: string;
begin
  // Crea fza_articulos_skus + fza_atributos_sku para un SKU que no existía,
  // a partir del artículo padre y los valores de atributo de la línea.
  // CODIGO_VAR_SKU se hereda del primer SKU existente del artículo o, si no
  // hay ninguno, de fza_articulos.TIPO_VARIACION_ART.
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;

    // 1) Insertar la cabecera del SKU.
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :SKU, :ART, ' +
      '       COALESCE( ' +
      '         (SELECT s.CODIGO_VAR_SKU FROM fza_articulos_skus s ' +
      '           WHERE s.CODIGO_ART_SKU = :ART LIMIT 1), ' +
      '         (SELECT a.TIPO_VARIACION_ART FROM fza_articulos a ' +
      '           WHERE a.CODIGO_ART_ART = :ART) ' +
      '       ), ''S'', NOW(), :USR, :USR';
    qry.ParamByName('SKU').AsString := ASku;
    qry.ParamByName('ART').AsString := ACodigoArticulo;
    qry.ParamByName('USR').AsString := FUsuario;
    qry.ExecSQL;

    // 2) Insertar la relación con cada valor de atributo. La posición i+1
    //    corresponde al ORDEN_VISUAL_ATRIBUTO de vi_atributos_nombres.
    for i := 0 to High(AAtributos) do
    begin
      ValorAtrib := Trim(AAtributos[i]);
      if ValorAtrib = '' then Continue;

      qry.SQL.Text :=
        'SELECT v.ID_AV ' +
        '  FROM fza_atributos_valores v ' +
        '  JOIN vi_atributos_nombres n ON v.ID_VA_AV = n.ID_ATRIBUTO ' +
        ' WHERE n.CODIGO_ART_PADRE_ARTVIN = :ART ' +
        '   AND n.ORDEN_VISUAL_ATRIBUTO = :ORDEN ' +
        '   AND v.AV = :VALOR ' +
        '   AND COALESCE(v.ESACTIVO_AV, ''S'') = ''S'' ' +
        ' LIMIT 1';
      qry.ParamByName('ART').AsString    := ACodigoArticulo;
      qry.ParamByName('ORDEN').AsInteger := i + 1;
      qry.ParamByName('VALOR').AsString  := ValorAtrib;
      qry.Open;
      if qry.IsEmpty then
      begin
        qry.Close;
        raise Exception.CreateFmt(
          SErrorValorAtributoSkuInventarioNoEncontrado,
          [ValorAtrib, i + 1, ACodigoArticulo, ASku]);
      end;
      IdAv := qry.FieldByName('ID_AV').AsInteger;
      qry.Close;

      qry.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:SKU, :IDAV, NOW(), :USR, :USR)';
      qry.ParamByName('SKU').AsString   := ASku;
      qry.ParamByName('IDAV').AsInteger := IdAv;
      qry.ParamByName('USR').AsString   := FUsuario;
      qry.ExecSQL;
    end;

    Result := True;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmInventarios.CargarAlmacenesPorEmpresa(
  const ACodigoEmpresa: string);
begin
  if ACodigoEmpresa = '' then
  begin
    if unqryAlmacenes.Active then
      unqryAlmacenes.Close;
  end
  else if not (unqryAlmacenes.Active and
               SameText(unqryAlmacenes.ParamByName('EMPRESA').AsString,
                        ACodigoEmpresa)) then
  begin
    unqryAlmacenes.Close;
    unqryAlmacenes.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    unqryAlmacenes.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_INV', 'CODIGO_ALM_INV');
end;

procedure TdmInventarios.CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
begin
  // Solo aplicable si la SQL de unqrySeries declara el parámetro :EMPRESA
  // (ver dfm: tabla fza_empresas_series filtrada por CODIGO_EMP_EMPSER).
  unqrySeries.Close;
  if ACodigoEmpresa = '' then
  begin
    unqrySeries.Open;
    Exit;
  end;
  if unqrySeries.Params.FindParam('EMPRESA') <> nil then
    unqrySeries.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
  unqrySeries.Open;
end;

procedure TdmInventarios.CargarDesdeListaSkus(ALista: TStringList);
var
  i: Integer;
  Sku, ArticuloPadre: string;
  CANTIDAD, PMP: Currency;
  qry: TUniQuery;
begin
  // Cada línea de la lista debe tener: SKU;CANTIDAD_FISICA  (separador ; o tab)
  // O bien solo el SKU (cantidad física = 1)
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create(SErrorCargarArticulosInventarioNoAbierto);

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'SELECT s.CODIGO_ART_SKU, a.DESCRIPCION_ART ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      ' WHERE s.CODIGO_UNIDAD_SKU = :SKU';

    cdsLineas.DisableControls;
    try
      for i := 0 to ALista.Count - 1 do
      begin
        Sku := Trim(ALista.Names[i]);
        if Sku = '' then
          Sku := Trim(ALista[i]);
        if Sku = '' then Continue;

        CANTIDAD := StrToCurrDef(ALista.ValueFromIndex[i], 1);

        qry.Close;
        qry.ParamByName('SKU').AsString := Sku;
        qry.Open;
        if qry.IsEmpty then Continue; // ignorar SKUs que no existen
        ArticuloPadre := qry.FieldByName('CODIGO_ART_SKU').AsString;

        RellenarDatosSku(Sku, PMP, PMP); // PMP en variable temporal
        // Recargamos PMP correctamente:
        unqryStockActual.Close;
        unqryStockActual.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
        unqryStockActual.ParamByName('SKU').AsString     := Sku;
        unqryStockActual.Open;

        // Si el SKU ya existe en el inventario, sumamos cantidad
        if ExisteLineaConSku(Sku) then
        begin
          if cdsLineas.Locate('CODIGO_UNIDAD_INVLIN',
                              Sku,
                              [loCaseInsensitive]) then
          begin
            cdsLineas.Edit;
            cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency :=
              cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency
                + CANTIDAD;
            cdsLineas.Post;
          end;
        end
        else
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := ArticuloPadre;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := Sku;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString :=
            qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   :=
            unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    :=
            CANTIDAD;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       :=
            unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency :=
            unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
          AsegurarFechaRecuentoLinea;
          cdsLineas.Post;
        end;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    FreeAndNil(qry);
  end;
end;


initialization
  RegistrarDataModule(TdmInventarios);
  ForceReferenceToClass(TdmInventarios);
end.
