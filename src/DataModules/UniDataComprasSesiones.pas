unit UniDataComprasSesiones;

{
  Unidad: UniDataComprasSesiones
  DataModule de Sesiones de Compra (pre-pedidos / pre-albaranes).

  Contiene los TUniQuery sobre todas las tablas fza_compras_sesiones*,
  los DataSource asociados y las consultas auxiliares para listar
  proveedores, familias, variaciones, conjuntos de atributos y propiedades
  necesarios al formulario.

  PRINCIPIO: nada de lo que escribe el usuario en una sesión BORRADOR toca
  las tablas maestras (fza_articulos, fza_articulos_skus, fza_codigos_barras
  o fza_articulos_proveedores). La materialización es código explícito
  ubicado en inLibComprasSesionesMaterializar.
}

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  inLibUser, inMtoPrincipal, frCoreClasses;

type
  TdmComprasSesiones = class(TdmBase)
    // Cabecera de sesión (lista principal). unqryTablaG ya existe en TdmBase.
    unqrySesionLin: TUniQuery;
    dsSesionLin: TDataSource;
    // Lista de documentos generados al materializar la sesion (PEDC /
    // ALBC). Master/detail con unqryTablaG via SERIE_SES/NUMERO_SES.
    // Alimenta la pestania 'Documentos' del Mto.
    unqrySesDocs: TUniQuery;
    dsSesDocs: TDataSource;

    unqrySesionFil: TUniQuery;
    dsSesionFil: TDataSource;

    unqrySesionFilAtr: TUniQuery;
    dsSesionFilAtr: TDataSource;

    unqrySesionCel: TUniQuery;
    dsSesionCel: TDataSource;

    unqrySesionProps: TUniQuery;
    dsSesionProps: TDataSource;

    unqrySesionLinProps: TUniQuery;
    dsSesionLinProps: TDataSource;

    unqrySesionKits: TUniQuery;
    dsSesionKits: TDataSource;

    unqrySesionKitsDet: TUniQuery;
    dsSesionKitsDet: TDataSource;

    // Vista PREVIEW para la pestaña Materialización
    unqryPreviewSkus: TUniQuery;
    dsPreviewSkus: TDataSource;

    // Sub-grid de precios por SKU (solo activo si ESPRECIO_POR_SKU_SES='S')
    unqryLineaSkusPrecios: TUniQuery;
    dsLineaSkusPrecios: TDataSource;

    // Resumen agregado por almacén para la pestaña Materialización
    unqryResumenAlmacen: TUniQuery;
    dsResumenAlmacen: TDataSource;

    // Pestaña Proveedor: ficha completa del proveedor de la sesion (con el
    // nombre de su sistema de tallas por defecto) y su biblioteca de kits
    // de cantidades por talla (fza_proveedores_kits / _det). Se recargan
    // al navegar de sesion o cambiar CODIGO_PRV_SES (RecargarProveedorSesion).
    unqryPrvFicha: TUniQuery;
    dsPrvFicha: TDataSource;
    unqryPrvKits: TUniQuery;
    dsPrvKits: TDataSource;
    unqryPrvKitsDet: TUniQuery;
    dsPrvKitsDet: TDataSource;
    // Etiqueta descriptiva por kit para el desplegable "Aplicar kit" de la
    // cabecera de la sesion: "NOMBRE SISTEMA primera(cant)...ultima(cant)".
    // SQL en DataModuleCreate (evita comillas anidadas en el dfm).
    unqryPrvKitsCombo: TUniQuery;
    dsPrvKitsCombo: TDataSource;

    // Auxiliares (lookups)
    unqryProveedores: TUniQuery;
    dsProveedores: TDataSource;
    unqryFamilias: TUniQuery;
    dsFamilias: TDataSource;
    unqryVariaciones: TUniQuery;
    dsVariaciones: TDataSource;
    unqryVariacionesAtributos: TUniQuery;
    dsVariacionesAtributos: TDataSource;
    unqryAtributosConjuntos: TUniQuery;
    dsAtributosConjuntos: TDataSource;
    unqryAtributosValores: TUniQuery;
    dsAtributosValores: TDataSource;
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    unqryPropiedadesValores: TUniQuery;
    dsPropiedadesValores: TDataSource;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    unqryFormasPago: TUniQuery;
    dsFormasPago: TDataSource;
    // Lookup de temporadas (fza_propiedades_valores con ID_PROP_PV='TEMPORADA').
    // Una por sesion; se propaga a fza_articulos_propiedades al materializar.
    unqryTemporadas: TUniQuery;
    dsTemporadas: TDataSource;
    // Lookup de series de la empresa actual para TIPO_DOC='SE'
    unqryEmpresaSeries: TUniQuery;
    dsEmpresaSeries: TDataSource;

    // Detección de duplicados al teclear código de artículo
    unqryArticuloExiste: TUniQuery;

    // Contador propio: TIPO_DOC_CON = 'SE' (SEsion de compra; varchar(2))
    unstrdprcGetContadorSesion: TUniStoredProc;

    // Stored procs auxiliares (validación, etc.)
    unstrdprcValidarSesion: TUniStoredProc;

    // ------------------------------------------------------------------
    // Impresion FastReport horizontal (compras_sesiones, print)
    // ------------------------------------------------------------------
    // Vista cabecera enriquecida (empresa + proveedor + totales).
    unqryCabSesionPrint:  TUniQuery;
    dsCabSesionPrint:     TDataSource;
    // Lineas con T01..T20 pivotadas desde fza_compras_sesiones_celdas.
    unqryLinSesionPrint:  TUniQuery;
    dsLinSesionPrint:     TDataSource;
    // Guias (leyenda) de los sistemas de tallas usados en la sesion.
    unqryGuiasSesionPrint: TUniQuery;
    dsGuiasSesionPrint:    TDataSource;
    // Datasets FastReport con UserName estable para que el report los
    // resuelva por nombre via RebindReportDataSetsByDataModule.
    fxdsCabSesion:   TfrxDBDataset;
    fxdsLinSesion:   TfrxDBDataset;
    fxdsGuiasSesion: TfrxDBDataset;

    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqrySesionLinAfterInsert(DataSet: TDataSet);
    procedure unqrySesionLinBeforePost(DataSet: TDataSet);
    procedure unqrySesionLinAfterPost(DataSet: TDataSet);
    procedure unqrySesionLinAfterDelete(DataSet: TDataSet);
    procedure unqrySesionCelAfterPost(DataSet: TDataSet);
  private
    FInstanteCargaSesion: TDateTime;
    FTallajeDefectoActual: Integer;
                        // Sistema de tallas (ID_AC) que se propone a la
                        // siguiente linea NUEVA de la sesion. Arranca en 0
                        // (sin defecto). CopiarDefectosProveedor lo fija al
                        // ID_AC_TALLAS_PRV del proveedor recien elegido;
                        // cuando el usuario cambia el sistema de tallas de
                        // una linea (dbcLinTallasPropertiesButtonClick) pasa
                        // a ser ese, no el del proveedor: "se cambia el
                        // defecto del documento", no el del proveedor.
                        // RecargarProveedorSesion lo resetea a 0 al navegar
                        // a otra sesion o proveedor.
    procedure ConfigurarSqlCabecera;
    procedure AjustarCamposDerivadosCabecera;
    procedure CalcularTotalesLineaActual;
    procedure PersistirTotalesSesion;
  public
    property TallajeDefectoActual: Integer read FTallajeDefectoActual
                                            write FTallajeDefectoActual;
    procedure GetCodigoAutoSesion;
    procedure AsegurarSerieEnEmpresasSeries(const AEmpresa, ASerie: string);
    procedure ChequearDuplicado(const ACodigoArt: string;
                                 out AExiste: Boolean;
                                 out ADescripcion: string);
    procedure RefrescarTotalesSesion;
    function  DetectarConflictoConcurrencia: Boolean;
    procedure AplicarKitAFila(const AIdKit: string;
                              const ALineaID: Integer;
                              const AIdFila: Integer);
    procedure AplicarKitATodasFilas(const AIdKit: string;
                                    const ALineaID: Integer);
    procedure ReconstruirFilasLinea(const ALineaID: Integer);
    // Reabre la ficha y los kits del proveedor indicado (pestaña Proveedor).
    // Con cadena vacia deja las queries cerradas.
    procedure RecargarProveedorSesion(const ACodigoPrv: string);

    // Abre las tres queries de impresion para una sesion concreta.
    // Usado por TfrmPrintSesion.preparar_consulta.
    procedure PrepararPrint(const ASerie, ANumero: string);
  end;


implementation

uses
  System.Variants,
  inLibGlobalVar,
  inLibAppParam,
  inLibCajaParam,
  inLibtb,
  inLibComprasSesiones,
  inLibComprasSesionesMaterializar,
  inLibContadorLineas,
  inLibComprasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmComprasSesiones.AjustarCamposDerivadosCabecera;
const
  CAMPOS_DERIVADOS: array[0..9] of string = (
    'RAZON_SOCIAL_PRV_SES',
    'NOMBRE_PRV_SES',
    'TEMPORADA_SES',
    'FECHA_REALIZACION_SES',
    'FECHA_EFECTO_STOCK_SES',
    'TOTAL_PRENDAS_SES',
    'CANTIDAD_PEDIDA_SES',
    'TOTAL_LINEAS_SES',
    'CANTIDAD_RECIBIDA_SES',
    'CANTIDAD_PENDIENTE_RECEPCION_SES');
var
  i      : Integer;
  oCampo : TField;
begin
  for i := Low(CAMPOS_DERIVADOS) to High(CAMPOS_DERIVADOS) do
  begin
    oCampo := unqryTablaG.FindField(CAMPOS_DERIVADOS[i]);
    if oCampo <> nil then
    begin
      oCampo.Required := False;
      oCampo.ProviderFlags := [];
    end;
  end;
end;

procedure TdmComprasSesiones.ConfigurarSqlCabecera;
const
  CAMPOS_SES: array[0..78] of string = (
    'SERIE_SES',
    'NUMERO_SES',
    'FECHA_SES',
    'FECHA_TOPE_RECEPCION_SES',
    'ESTADO_SES',
    'CODIGO_EMP_SES',
    'CODIGO_PRV_SES',
    'REF_PRV_SES',
    'FORMA_PAGO_SES',
    'CODIGO_FAM_SES',
    'CODIGO_ALM_SES',
    'MONEDA_SES',
    'TIPO_IVA_SES',
    'CODIGO_IVA_SES',
    'ESVARIOS_TIPOS_IVA_SES',
    'PORCENTAJE_MARGEN_SES',
    'CODIGO_TAR_SES',
    'ESPRECIOS_SIN_IVA_SES',
    'ESREDONDEO_VENTA_SES',
    'MULTIPLO_REDONDEO_SES',
    'AJUSTE_FINAL_SES',
    'CODIGO_VAR_SES',
    'ID_VA_PIVOT_SES',
    'ID_AC_PIVOT_SES',
    'ID_VA_FILA_SES',
    'ID_AC_FILA_SES',
    'ESVAR_FIJA_SES',
    'PREFIJO_EAN_SES',
    'INSTANTE_MATERIALIZA_SES',
    'USUARIO_MATERIALIZA_SES',
    'ESGENERA_PEDIDO_SES',
    'ESGENERA_ALBARAN_SES',
    'ESFORMATO_DISTRIBUIDO_SES',
    'SERIE_PEDC_SES',
    'NUMERO_PEDC_SES',
    'SERIE_ALBC_SES',
    'NUMERO_ALBC_SES',
    'MENSAJE_ERROR_SES',
    'CONTADOR_LINEAS_SES',
    'COMENTARIOS_SES',
    'INSTANTE_ALTA',
    'USUARIO_ALTA',
    'INSTANTE_MODIF',
    'USUARIO_MODIF',
    'ESPRECIO_POR_SKU_SES',
    'ID_PV_TEMPORADA_SES',
    'ESIVA_RECARGO_COMPRAS_SES',
    'ESIVA_EXENTO_INTRACOMUNITARIO_SES',
    'PORCENTAJE_IVAN_SES',
    'TOTAL_BASEI_IVAN_SES',
    'TOTAL_IVAN_SES',
    'PORCENTAJE_REN_SES',
    'TOTAL_REN_SES',
    'PORCENTAJE_IVAR_SES',
    'TOTAL_BASEI_IVAR_SES',
    'TOTAL_IVAR_SES',
    'PORCENTAJE_RER_SES',
    'TOTAL_RER_SES',
    'PORCENTAJE_IVAS_SES',
    'TOTAL_BASEI_IVAS_SES',
    'TOTAL_IVAS_SES',
    'PORCENTAJE_RES_SES',
    'TOTAL_RES_SES',
    'PORCENTAJE_IVAE_SES',
    'TOTAL_BASEI_IVAE_SES',
    'TOTAL_IVAE_SES',
    'PORCENTAJE_REE_SES',
    'TOTAL_REE_SES',
    'PORCENTAJE_RETENCION_SES',
    'TOTAL_RETENCION_SES',
    'TOTAL_BRUTO_SES',
    'PORCENTAJE_DTO_COMERCIAL_SES',
    'TOTAL_DTO_COMERCIAL_SES',
    'PORCENTAJE_DTO_FINANCIERO_SES',
    'TOTAL_DTO_FINANCIERO_SES',
    'TOTAL_BASES_SES',
    'TOTAL_IMPUESTOS_SES',
    'TOTAL_SES',
    'TOTAL_LIQUIDO_SES');
var
  i: Integer;
  sCampos: string;
  sValores: string;
  sSet: string;

  procedure AgregarCampo(const ACampo: string);
  begin
    if sCampos = '' then
    begin
      sCampos := '  (' + ACampo;
      sValores := '  (:' + ACampo;
      sSet := '       ' + ACampo + ' = :' + ACampo;
    end
    else
    begin
      sCampos := sCampos + ',' + sLineBreak + '   ' + ACampo;
      sValores := sValores + ',' + sLineBreak + '   :' + ACampo;
      sSet := sSet + ',' + sLineBreak +
        '       ' + ACampo + ' = :' + ACampo;
    end;
  end;

begin
  sCampos := '';
  sValores := '';
  sSet := '';
  for i := Low(CAMPOS_SES) to High(CAMPOS_SES) do
    AgregarCampo(CAMPOS_SES[i]);
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_compras_sesiones ' + sLineBreak +
    sCampos + ')' + sLineBreak +
    'VALUES ' + sLineBreak +
    sValores + ')';
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_compras_sesiones ' + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_compras_sesiones ' + sLineBreak +
    '   SET ' + sLineBreak +
    sSet + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES';
  unqryTablaG.SQLLock.Text :=
    'SELECT * ' + sLineBreak +
    '  FROM fza_compras_sesiones ' + sLineBreak +
    ' WHERE SERIE_SES = :Old_SERIE_SES ' + sLineBreak +
    '   AND NUMERO_SES = :Old_NUMERO_SES ' + sLineBreak +
    ' FOR UPDATE';
end;

procedure TdmComprasSesiones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  ConfigurarSqlCabecera;
  unqryTablaG.SQL.Text :=
    'SELECT s.*, ' +
    '       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES, ' +
    '       prv.NOMBRE_PRV AS NOMBRE_PRV_SES, ' +
    '       t.PV AS TEMPORADA_SES, ' +
    '       s.FECHA_SES AS FECHA_REALIZACION_SES, ' +
    '       alb.FECHA_ALBC AS FECHA_EFECTO_STOCK_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS TOTAL_PRENDAS_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS CANTIDAD_PEDIDA_SES, ' +
    '       COALESCE(r.TOTAL_LINEAS_SES, 0) AS TOTAL_LINEAS_SES, ' +
    '       CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '            THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '            ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END ' +
    '          AS CANTIDAD_RECIBIDA_SES, ' +
    '       GREATEST(COALESCE(r.TOTAL_PRENDAS_SES, 0) - ' +
    '         CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '              THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '              ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END, 0) ' +
    '          AS CANTIDAD_PENDIENTE_RECEPCION_SES ' +
    '  FROM fza_compras_sesiones s ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES ' +
    '  LEFT JOIN fza_propiedades_valores t ' +
    '    ON t.ID_PV_ARTPROP = s.ID_PV_TEMPORADA_SES ' +
    '   AND t.ID_PROP_PV = ''TEMPORADA'' ' +
    '  LEFT JOIN fza_albaranes_compra alb ' +
    '    ON alb.SERIE_ALBC = s.SERIE_ALBC_SES ' +
    '   AND alb.NUMERO_ALBC = s.NUMERO_ALBC_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN, ' +
    '                    COALESCE(SUM(l.TOTAL_UNIDADES_SESLIN), 0) ' +
    '                      AS TOTAL_PRENDAS_SES, ' +
    '                    COALESCE(SUM(l.TOTAL_LINEA_SESLIN), 0) ' +
    '                      AS TOTAL_LINEAS_SES ' +
    '               FROM fza_compras_sesiones_lineas l ' +
    '              GROUP BY l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN) r ' +
    '    ON r.SERIE_SES_SESLIN = s.SERIE_SES ' +
    '   AND r.NUMERO_SES_SESLIN = s.NUMERO_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_PEDC_PEDCLIN, l.NUMERO_PEDC_PEDCLIN, ' +
    '                    COALESCE(SUM(l.CANTIDAD_RECIBIDA_PEDCLIN), 0) ' +
    '                      AS CANTIDAD_RECIBIDA_PEDC ' +
    '               FROM fza_pedidos_compra_lineas l ' +
    '              GROUP BY l.SERIE_PEDC_PEDCLIN, ' +
    '                       l.NUMERO_PEDC_PEDCLIN) ped ' +
    '    ON ped.SERIE_PEDC_PEDCLIN = s.SERIE_PEDC_SES ' +
    '   AND ped.NUMERO_PEDC_PEDCLIN = s.NUMERO_PEDC_SES ' +
    ' ORDER BY s.FECHA_SES DESC, s.NUMERO_SES DESC';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT s.*, ' +
    '       prv.RAZON_SOCIAL_PRV AS RAZON_SOCIAL_PRV_SES, ' +
    '       prv.NOMBRE_PRV AS NOMBRE_PRV_SES, ' +
    '       t.PV AS TEMPORADA_SES, ' +
    '       s.FECHA_SES AS FECHA_REALIZACION_SES, ' +
    '       alb.FECHA_ALBC AS FECHA_EFECTO_STOCK_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS TOTAL_PRENDAS_SES, ' +
    '       COALESCE(r.TOTAL_PRENDAS_SES, 0) AS CANTIDAD_PEDIDA_SES, ' +
    '       COALESCE(r.TOTAL_LINEAS_SES, 0) AS TOTAL_LINEAS_SES, ' +
    '       CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '            THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '            ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END ' +
    '          AS CANTIDAD_RECIBIDA_SES, ' +
    '       GREATEST(COALESCE(r.TOTAL_PRENDAS_SES, 0) - ' +
    '         CASE WHEN COALESCE(s.NUMERO_ALBC_SES, '''') <> '''' ' +
    '              THEN COALESCE(r.TOTAL_PRENDAS_SES, 0) ' +
    '              ELSE COALESCE(ped.CANTIDAD_RECIBIDA_PEDC, 0) END, 0) ' +
    '          AS CANTIDAD_PENDIENTE_RECEPCION_SES ' +
    '  FROM fza_compras_sesiones s ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = s.CODIGO_PRV_SES ' +
    '  LEFT JOIN fza_propiedades_valores t ' +
    '    ON t.ID_PV_ARTPROP = s.ID_PV_TEMPORADA_SES ' +
    '   AND t.ID_PROP_PV = ''TEMPORADA'' ' +
    '  LEFT JOIN fza_albaranes_compra alb ' +
    '    ON alb.SERIE_ALBC = s.SERIE_ALBC_SES ' +
    '   AND alb.NUMERO_ALBC = s.NUMERO_ALBC_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN, ' +
    '                    COALESCE(SUM(l.TOTAL_UNIDADES_SESLIN), 0) ' +
    '                      AS TOTAL_PRENDAS_SES, ' +
    '                    COALESCE(SUM(l.TOTAL_LINEA_SESLIN), 0) ' +
    '                      AS TOTAL_LINEAS_SES ' +
    '               FROM fza_compras_sesiones_lineas l ' +
    '              GROUP BY l.SERIE_SES_SESLIN, l.NUMERO_SES_SESLIN) r ' +
    '    ON r.SERIE_SES_SESLIN = s.SERIE_SES ' +
    '   AND r.NUMERO_SES_SESLIN = s.NUMERO_SES ' +
    '  LEFT JOIN (SELECT l.SERIE_PEDC_PEDCLIN, l.NUMERO_PEDC_PEDCLIN, ' +
    '                    COALESCE(SUM(l.CANTIDAD_RECIBIDA_PEDCLIN), 0) ' +
    '                      AS CANTIDAD_RECIBIDA_PEDC ' +
    '               FROM fza_pedidos_compra_lineas l ' +
    '              GROUP BY l.SERIE_PEDC_PEDCLIN, ' +
    '                       l.NUMERO_PEDC_PEDCLIN) ped ' +
    '    ON ped.SERIE_PEDC_PEDCLIN = s.SERIE_PEDC_SES ' +
    '   AND ped.NUMERO_PEDC_PEDCLIN = s.NUMERO_PEDC_SES ' +
    ' WHERE s.SERIE_SES = :SERIE_SES ' +
    '   AND s.NUMERO_SES = :NUMERO_SES';
  unqrySesionLin.Connection         := inLibGlobalVar.oConn;
  unqrySesDocs.Connection           := inLibGlobalVar.oConn;
  unqrySesionFil.Connection         := inLibGlobalVar.oConn;
  unqrySesionFilAtr.Connection      := inLibGlobalVar.oConn;
  unqrySesionCel.Connection         := inLibGlobalVar.oConn;
  unqrySesionProps.Connection       := inLibGlobalVar.oConn;
  unqrySesionLinProps.Connection    := inLibGlobalVar.oConn;
  unqrySesionKits.Connection        := inLibGlobalVar.oConn;
  unqrySesionKitsDet.Connection     := inLibGlobalVar.oConn;
  unqryPreviewSkus.Connection       := inLibGlobalVar.oConn;
  unqryResumenAlmacen.Connection    := inLibGlobalVar.oConn;
  unqryLineaSkusPrecios.Connection  := inLibGlobalVar.oConn;
  unqryPrvFicha.Connection          := inLibGlobalVar.oConn;
  unqryPrvKits.Connection           := inLibGlobalVar.oConn;
  unqryPrvKitsDet.Connection        := inLibGlobalVar.oConn;
  unqryPrvKitsCombo.Connection      := inLibGlobalVar.oConn;
  // Etiqueta del desplegable de kits: nombre + sistema de tallas +
  // primera y ultima talla CON cantidad>0, p.ej.
  //   "OPC A  Calzado Hombre EU 39-44  39(1)...44(2)".
  // El formato de cantidad recorta ceros/decimales sobrantes (1, 1.5).
  unqryPrvKitsCombo.SQL.Text :=
    'SELECT K.CODIGO_PRVKIT, ' +
    '  TRIM(CONCAT(K.NOMBRE_PRVKIT, ' +
    '    IFNULL(CONCAT('' '', AC.NOMBRE_AC), ''''), '' '', ' +
    '    IFNULL((SELECT CONCAT(D.VALOR_DESTINO_PRVKITD, ''('', ' +
    '              TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    '                CAST(D.CANTIDAD_PRVKITD AS CHAR))), '')'') ' +
    '         FROM fza_proveedores_kits_det D ' +
    '        WHERE D.CODIGO_PRV_PRVKITD = K.CODIGO_PRV_PRVKIT ' +
    '          AND D.CODIGO_PRVKIT_PRVKITD = K.CODIGO_PRVKIT ' +
    '          AND D.CANTIDAD_PRVKITD > 0 ' +
    '        ORDER BY D.ORDEN_PRVKITD, D.VALOR_DESTINO_PRVKITD LIMIT 1), ''''), ' +
    '    ''...'', ' +
    '    IFNULL((SELECT CONCAT(D.VALOR_DESTINO_PRVKITD, ''('', ' +
    '              TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    '                CAST(D.CANTIDAD_PRVKITD AS CHAR))), '')'') ' +
    '         FROM fza_proveedores_kits_det D ' +
    '        WHERE D.CODIGO_PRV_PRVKITD = K.CODIGO_PRV_PRVKIT ' +
    '          AND D.CODIGO_PRVKIT_PRVKITD = K.CODIGO_PRVKIT ' +
    '          AND D.CANTIDAD_PRVKITD > 0 ' +
    '        ORDER BY D.ORDEN_PRVKITD DESC, ' +
    '                 D.VALOR_DESTINO_PRVKITD DESC LIMIT 1), ''''))) ' +
    '    AS ETIQUETA_KIT ' +
    '  FROM fza_proveedores_kits K ' +
    '  LEFT JOIN fza_atributos_conjuntos AC ON AC.ID_AC = K.ID_AC_TALLAS_PRVKIT ' +
    ' WHERE K.CODIGO_PRV_PRVKIT = :prv ' +
    ' ORDER BY K.ORDEN_PRVKIT, K.CODIGO_PRVKIT';
  unqryProveedores.Connection       := inLibGlobalVar.oConn;
  unqryFamilias.Connection          := inLibGlobalVar.oConn;
  unqryVariaciones.Connection       := inLibGlobalVar.oConn;
  unqryVariacionesAtributos.Connection := inLibGlobalVar.oConn;
  unqryAtributosConjuntos.Connection := inLibGlobalVar.oConn;
  unqryAtributosValores.Connection  := inLibGlobalVar.oConn;
  unqryPropiedades.Connection       := inLibGlobalVar.oConn;
  unqryPropiedadesValores.Connection := inLibGlobalVar.oConn;
  unqryIvas.Connection              := inLibGlobalVar.oConn;
  unqryAlmacenes.Connection         := inLibGlobalVar.oConn;
  unqryTarifas.Connection           := inLibGlobalVar.oConn;
  unqryEmpresas.Connection          := inLibGlobalVar.oConn;
  unqryFormasPago.Connection        := inLibGlobalVar.oConn;
  unqryTemporadas.Connection        := inLibGlobalVar.oConn;
  unqryEmpresaSeries.Connection     := inLibGlobalVar.oConn;
  unqryArticuloExiste.Connection    := inLibGlobalVar.oConn;
  unstrdprcGetContadorSesion.Connection := inLibGlobalVar.oConn;
  unstrdprcValidarSesion.Connection := inLibGlobalVar.oConn;
  unqryCabSesionPrint.Connection    := inLibGlobalVar.oConn;
  unqryLinSesionPrint.Connection    := inLibGlobalVar.oConn;
  unqryGuiasSesionPrint.Connection  := inLibGlobalVar.oConn;
  // unqryProveedores alimenta tanto el rotulo resuelto de la cabecera
  // (ActualizarLabelProveedor via Locate) como cbbProveedor, el combo de
  // busqueda incremental por codigo.
  unqryProveedores.Open;
  unqryFamilias.Open;
  unqryVariaciones.Open;
  unqryVariacionesAtributos.Open;
  unqryAtributosConjuntos.Open;
  unqryAtributosValores.Open;
  unqryPropiedades.Open;
  unqryPropiedadesValores.Open;
  unqryIvas.Open;
  unqryAlmacenes.Open;
  unqryTarifas.Open;
  unqryEmpresas.Open;
  unqryFormasPago.Open;
  unqryTemporadas.Open;
end;

procedure TdmComprasSesiones.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('FECHA_SES').AsDateTime := Date;
    FieldByName('ESTADO_SES').AsString  := 'BORRADOR';
    FieldByName('MONEDA_SES').AsString  := 'EUR';
    FieldByName('TIPO_IVA_SES').AsString := 'N';
    FieldByName('ESPRECIOS_SIN_IVA_SES').AsString := 'S';
    FieldByName('ESREDONDEO_VENTA_SES').AsString  := 'N';
    // NOT NULL en la tabla: hay que darles valor en cliente o Post falla con
    // 'Field XXX must have a value' antes de llegar al DEFAULT del servidor.
    FieldByName('MULTIPLO_REDONDEO_SES').AsFloat  := 0;
    FieldByName('AJUSTE_FINAL_SES').AsFloat       := 0;
    FieldByName('ESPRECIO_POR_SKU_SES').AsString  := 'N';
    FieldByName('ESVAR_FIJA_SES').AsString        := 'N';
    if FindField('ESVARIOS_TIPOS_IVA_SES') <> nil then
      FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_SES') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString := 'N';
    FieldByName('ESGENERA_PEDIDO_SES').AsString   := 'N';
    FieldByName('ESGENERA_ALBARAN_SES').AsString  := 'N';
    if FindField('ESFORMATO_DISTRIBUIDO_SES') <> nil then
      FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString := 'N';
    // Contador de lineas: cada nueva linea hace +10 sobre este valor
    // (mismo patron que facturas/pedidos/albaranes). Arrancar en 0 => la
    // primera linea sera 10, la segunda 20, etc.
    FieldByName('CONTADOR_LINEAS_SES').AsInteger  := 0;
    // Prerelleno empresa/almacen del usuario logueado (igual que inventarios).
    // Sin esto el combo de serie queda vacio porque depende de CODIGO_EMP_SES,
    // y el usuario veria los combos en blanco al pulsar "+".
    if Trim(oEmpresa) <> '' then
      FieldByName('CODIGO_EMP_SES').AsString := oEmpresa;
    if Trim(oAlmacen) <> '' then
      FieldByName('CODIGO_ALM_SES').AsString := oAlmacen;
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_SES', 'ESIVA_RECARGO_COMPRAS_SES');
    AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG, 'SES');
    // Si solo hay una variacion definida, preseleccionarla. Es el caso
    // mayoritario (la mayoria de instalaciones solo tienen 'TC').
    if unqryVariaciones.Active and (unqryVariaciones.RecordCount = 1) then
      FieldByName('CODIGO_VAR_SES').AsString :=
        unqryVariaciones.FieldByName('CODIGO_VAR').AsString;
    // Temporada por defecto: el parámetro almacena el nombre visible
    // (ej. 'PRIM-VER 2026'); buscamos su ID numérico en el lookup
    var sTemp := oAppParams.GetString('appTemporadaDefecto');
    if (sTemp <> '') and unqryTemporadas.Active
       and unqryTemporadas.Locate('PV', sTemp, []) then
      FieldByName('ID_PV_TEMPORADA_SES').AsInteger :=
        unqryTemporadas.FieldByName('ID_PV_ARTPROP').AsInteger;
    // Tarifa sugerida desde parámetros (vgerDefTarifa, inLibCajaParam)
    if TarifaDefecto <> '' then
      FieldByName('CODIGO_TAR_SES').AsString := TarifaDefecto;
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='SE'
    if Trim(oEmpresa) <> '' then
    begin
      var sSerieDef := ObtenerSerieDefecto(oEmpresa, 'SE');
      if sSerieDef <> '' then
        FieldByName('SERIE_SES').AsString := sSerieDef;
    end;
    FieldByName('USUARIO_ALTA').AsString := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmComprasSesiones.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sSerie, sEmpresa, sNumero : string;
  oFldDist                  : TField;
begin
  AjustarCamposDerivadosCabecera;
  inherited;
  LogSes(Format('DM.unqryTablaGBeforePost: state=%d, SERIE=%s NUMERO=%s CONTADOR_LINEAS=%d',
                [Ord(unqryTablaG.State),
                 unqryTablaG.FieldByName('SERIE_SES').AsString,
                 unqryTablaG.FieldByName('NUMERO_SES').AsString,
                 unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger]));
  // 'Formato distribuido' solo puede fijarse al crear la sesion. Una
  // vez que la sesion existe (State=dsEdit) el valor no puede cambiar:
  // ya hay celdas asignadas a un almacen y cambiar el modo dejaria
  // datos inconsistentes (modo distribuido vacio o cantidades simples
  // sin almacen). El usuario tiene que crear una sesion nueva si
  // quiere otro modo.
  oFldDist := DataSet.FindField('ESFORMATO_DISTRIBUIDO_SES');
  if (oFldDist <> nil) and (DataSet.State = dsEdit) and
     (VarToStr(oFldDist.OldValue) <> VarToStr(oFldDist.NewValue)) then
    raise Exception.Create(
      'No se puede cambiar el formato distribuido de una sesion ya creada. ' +
      'Crea una sesion nueva con el modo deseado.');
  sNumero  := unqryTablaG.FieldByName('NUMERO_SES').AsString;
  sSerie   := Trim(unqryTablaG.FieldByName('SERIE_SES').AsString);
  sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  // Validacion: para obtener numero hace falta serie y empresa.
  if (sNumero = '') or (sNumero = '0') then
  begin
    if sEmpresa = '' then
      raise Exception.Create('Selecciona una empresa antes de grabar la sesion.');
    if sSerie = '' then
      raise Exception.Create('Teclea una serie antes de grabar la sesion ' +
        '(p.ej. ' + sEmpresa + '-SE-1).');
    // Si el usuario teclea una serie que no existe en fza_empresas_series,
    // la creamos al vuelo para que el SP PRC_GET_NEXT_CONT_FACT_SERIE
    // pueda devolver el contador. Asi el usuario no tiene que ir antes
    // a Mantenimiento > Empresas > 4_Series.
    AsegurarSerieEnEmpresasSeries(sEmpresa, sSerie);
    GetCodigoAutoSesion;
    if unqryTablaG.FieldByName('NUMERO_SES').AsString = '' then
      raise Exception.Create('No se pudo obtener el siguiente numero. ' +
        'Revisa que exista una fila en fza_contadores para (TIPO_DOC=SE, ' +
        'EMPRESA=' + sEmpresa + ', SERIE=' + sSerie + ') o que el SP ' +
        'PRC_GET_NEXT_CONT_FACT_SERIE este disponible.');
  end;
  RefrescarTotalesSesion;
  PersistirTotalesSesion;
  unqryTablaG.FieldByName('USUARIO_MODIF').AsString  := oUser;
  unqryTablaG.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterInsert(DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
begin
  inherited;
  // Pedimos la siguiente LINEA al helper generico (inLibContadorLineas).
  // El helper hace UPDATE atomico sobre fza_compras_sesiones incrementando
  // CONTADOR_LINEAS_SES en +10 y devuelve el nuevo valor. La persistencia
  // del contador NO depende de que el usuario Postee la cabecera, por lo
  // que ya no hay riesgo de colision si despues Cancela el master con
  // lineas posteadas (caso clasico: Add+navegacion=detail.Post implicito,
  // y Cancelar master rollbackeaba CONTADOR en memoria pero la linea ya
  // estaba en BD; el siguiente Add reasignaba la misma LINEA).
  sSerie  := unqryTablaG.FieldByName('SERIE_SES').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_SES').AsString;
  iNuevaLinea := GetSiguienteLineaDoc(CONT_SESIONES, sSerie, sNumero);
  if iNuevaLinea = 0 then
  begin
    // Cabecera no localizada (caso raro: master aun no posteado, sin
    // SERIE/NUMERO). Fallback al patron antiguo CONTADOR+10 en memoria.
    iNuevaLinea := unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger + 10;
    LogSes(Format('  helper devolvio 0 (cabecera sin SERIE/NUMERO?), fallback LINEA=%d',
                  [iNuevaLinea]));
  end;
  LogSes(Format('DM.unqrySesionLinAfterInsert: nueva LINEA=%d', [iNuevaLinea]));

  // Sincronizar CONTADOR en memoria con el nuevo valor para que los demas
  // handlers que lo leen (LogSes, displays, etc.) vean el valor coherente.
  if not (unqryTablaG.State in [dsEdit, dsInsert]) then
  begin
    LogSes('  master estaba fuera de edit/insert, forzando master.Edit');
    unqryTablaG.Edit;
  end;
  unqryTablaG.FieldByName('CONTADOR_LINEAS_SES').AsInteger := iNuevaLinea;

  with unqrySesionLin do
  begin
    FieldByName('SERIE_SES_SESLIN').AsString  :=
      unqryTablaG.FieldByName('SERIE_SES').AsString;
    FieldByName('NUMERO_SES_SESLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_SES').AsString;
    FieldByName('LINEA_SESLIN').AsInteger     := iNuevaLinea;
    FieldByName('TIPO_LINEA_SESLIN').AsString := 'MATRIZ';
    FieldByName('TIPO_ART_SESLIN').AsString   := 'ESTANDAR';
    if FindField('TIPO_IVA_SESLIN') <> nil then
      FieldByName('TIPO_IVA_SESLIN').AsString :=
        unqryTablaG.FieldByName('TIPO_IVA_SES').AsString;
    FieldByName('TIPO_CANTIDAD_SESLIN').AsString := 'Uds';
    FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
    // NOT NULL con DEFAULT en BBDD: hay que darles valor en cliente o Post
    // falla con 'Field XXX must have a value' antes de llegar al DEFAULT.
    FieldByName('ESTRAZABLE_SESLIN').AsString    := 'N';
    FieldByName('PRECIO_COMPRA_SESLIN').AsFloat  := 0;
    FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := 0;
    FieldByName('TOTAL_LINEA_SESLIN').AsFloat    := 0;
    // NOT NULL sin DEFAULT (debe rellenarlos el usuario): default a '' para
    // que Required pase y el usuario los rellene desde el grid.
    FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString := '';
    FieldByName('DESCRIPCION_SESLIN').AsString          := '';
    FieldByName('USUARIO_ALTA').AsString := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    // Sistema de tallas por defecto del documento (ver FTallajeDefectoActual):
    // viene del proveedor al elegirlo, o del ultimo que el usuario eligio a
    // mano en una linea. Solo se propone; el usuario lo puede cambiar en la
    // linea igual que siempre.
    if (FTallajeDefectoActual > 0) and
       (FindField('ID_AC_PIVOT_SESLIN') <> nil) then
      FieldByName('ID_AC_PIVOT_SESLIN').AsInteger := FTallajeDefectoActual;
  end;
end;

procedure TdmComprasSesiones.unqrySesionLinBeforePost(DataSet: TDataSet);
var
  bExiste : Boolean;
  sDescr  : string;
  sTecla  : string;
  sNuevo  : string;
begin
  inherited;
  LogSes(Format('DM.unqrySesionLinBeforePost: state=%d, LINEA=%d, COD_TENT=%s, FAM=%s',
                [Ord(unqrySesionLin.State),
                 unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger,
                 unqrySesionLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
                 unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString]));
  // Linea sin articulo: cancelar silenciosamente. El cxGrid hace Post
  // automatico al navegar con flechas; si la linea es un placeholder
  // vacio, Cancel + Abort lo descarta sin molestar al usuario.
  if Trim(unqrySesionLin.FieldByName(
              'CODIGO_ART_TENTATIVO_SESLIN').AsString) = '' then
  begin
    LogSes('  linea sin articulo, Cancel diferido + Abort');
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqrySesionLin.Active and
           (unqrySesionLin.State in [dsEdit, dsInsert]) then
          unqrySesionLin.Cancel;
      end);
    Abort;
  end;
  // Sincroniza TIPO_ART desde TIPO_LINEA
  if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'SERVICIO' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'SERVICIO'
  else if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'KIT' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'KIT'
  else
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'ESTANDAR';
  if (unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') = nil) or
     (UpperCase(Trim(unqryTablaG.FieldByName(
       'ESVARIOS_TIPOS_IVA_SES').AsString)) <> 'S') or
     (Trim(unqrySesionLin.FieldByName('TIPO_IVA_SESLIN').AsString) = '') then
    unqrySesionLin.FieldByName('TIPO_IVA_SESLIN').AsString :=
      unqryTablaG.FieldByName('TIPO_IVA_SES').AsString;
  // Saneo del color del proveedor al confirmar la linea: el usuario ve ya el
  // token real que ira al SKU (mayusculas, espacios->'-', simbolos prohibidos).
  // Misma regla que aplica el materializador (SanearColorSku) y la foto.
  if Trim(unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString) <> '' then
    unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString :=
      SanearColorSku(unqrySesionLin.FieldByName('COLOR_TEXTO_SESLIN').AsString);
  // Detección de duplicado
  if unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString <> '' then
  sTecla :=
       Trim(unqrySesionLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString);
  // Atajo familia->codigo autogenerado: si lo tecleado es exactamente el
  // codigo de una familia con contador activo, expandir al siguiente
  // numero de la serie e incrementar el contador.
  if sTecla <> '' then
  begin
    if inLibComprasSesiones.ResolverCodigoFamilia(
         inLibGlobalVar.oConn, sTecla, oUser, sNuevo) then
    begin
      unqrySesionLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString :=
                                                                         sNuevo;
      // Si la familia no esta seteada en la linea, ponerla a la tecleada
      if unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').IsNull or
         (unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString = '') then
        unqrySesionLin.FieldByName('CODIGO_FAM_SESLIN').AsString := sTecla;
      sTecla := sNuevo;
    end;
  end;
  // Detección de duplicado
  if sTecla <> '' then
  begin
    ChequearDuplicado(sTecla, bExiste, sDescr);
    if bExiste then
    begin
      unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S';
      // Si la linea no tiene accion resuelta, marcamos REUSAR por
      // defecto apuntando al articulo existente. Esto es lo que el
      // usuario espera en el flujo de muestrarios: tecleo el codigo
      // (o la ref. proveedor) de un articulo que ya tengo y meto
      // nuevo color + cantidades sin tener que arbitrar duplicados.
      // Si el usuario hubiera querido RENOMBRAR, la accion ya estaria
      // puesta por el flujo correspondiente y respetamos su eleccion.
      if Trim(unqrySesionLin.FieldByName(
                  'ACCION_DUPLICADO_SESLIN').AsString) = '' then
      begin
        unqrySesionLin.FieldByName('ACCION_DUPLICADO_SESLIN').AsString :=
                                                                    'REUSAR';
        unqrySesionLin.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString :=
                                                                       sTecla;
      end;
    end
    else
      unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
  end;
  CalcularTotalesLineaActual;
  unqrySesionLin.FieldByName('USUARIO_MODIF').AsString := oUser;
  unqrySesionLin.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterPost(DataSet: TDataSet);
begin
  inherited;
  LogSes(Format('DM.unqrySesionLinAfterPost: LINEA=%d posteada',
                [unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger]));
  RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterDelete(DataSet: TDataSet);
begin
  inherited;
  LogSes('DM.unqrySesionLinAfterDelete');
  // Las celdas y filas se borran en cascada por la app (no por FK).
  RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.unqrySesionCelAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesLineaActual;
  RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.CalcularTotalesLineaActual;
var
  q         : TUniQuery;
  rTotalUds : Double;
  rPrecio   : Double;
  iLinea    : Integer;
  sSerie    : string;
  sNumero   : string;
begin
  // Recalcula TOTAL_UNIDADES_SESLIN y TOTAL_LINEA_SESLIN para la línea
  // actualmente en edición sumando las celdas de fza_compras_sesiones_celdas.
  // Se invoca desde unqrySesionLinBeforePost para que los totales se
  // persistan correctamente cuando el usuario graba la sesión.
  rTotalUds := 0;
  if unqrySesionLin.IsEmpty then Exit;
  iLinea  := unqrySesionLin.FieldByName('LINEA_SESLIN').AsInteger;
  sSerie  := unqrySesionLin.FieldByName('SERIE_SES_SESLIN').AsString;
  sNumero := unqrySesionLin.FieldByName('NUMERO_SES_SESLIN').AsString;
  if iLinea <= 0 then Exit;
  if (sSerie = '') or (sNumero = '') then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COALESCE(SUM(CANTIDAD_SESCEL), 0) AS TOTAL ' +
      '  FROM fza_compras_sesiones_celdas ' +
      ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
      '   AND LINEA_SES_SESCEL = :l';
    q.ParamByName('s').AsString  := sSerie;
    q.ParamByName('n').AsString  := sNumero;
    q.ParamByName('l').AsInteger := iLinea;
    q.Open;
    rTotalUds := q.FieldByName('TOTAL').AsFloat;
  finally
    FreeAndNil(q);
  end;

  rPrecio := unqrySesionLin.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  if not (unqrySesionLin.State in [dsInsert, dsEdit]) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := rTotalUds;
  unqrySesionLin.FieldByName('TOTAL_LINEA_SESLIN').AsFloat    :=
                                                            rTotalUds * rPrecio;
end;

procedure TdmComprasSesiones.AsegurarSerieEnEmpresasSeries(
  const AEmpresa, ASerie: string);
var
  q          : TUniQuery;
  sCodigoSer : string;
begin
  // Si el usuario teclea una serie nueva (no existe en fza_empresas_series
  // para esa empresa+TIPO_DOC='SE'), la creamos al vuelo. El campo
  // CODIGO_SERIE_EMPSER es un contador propio que se genera con
  // PRC_GET_NEXT_CONT('ES') -- mismo patron que UniDataEmpresas.
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_empresas_series ' +
      ' WHERE TIPO_DOC_EMPSER = ''SE'' ' +
      '   AND CODIGO_EMP_EMPSER = :emp ' +
      '   AND EMPSER = :ser';
    q.ParamByName('emp').AsString := AEmpresa;
    q.ParamByName('ser').AsString := ASerie;
    q.Open;
    if q.FieldByName('N').AsInteger > 0 then Exit;
    q.Close;

    // PK de la nueva fila: contador 'ES' (mismo que pantalla Empresas)
    sCodigoSer := ObtenerSiguienteContador('ES');
    if Trim(sCodigoSer) = '' then
      raise Exception.Create('No se pudo obtener CODIGO_SERIE_EMPSER del ' +
        'contador ES via PRC_GET_NEXT_CONT.');

    q.SQL.Text :=
      'INSERT INTO fza_empresas_series ' +
      '  (CODIGO_SERIE_EMPSER, CODIGO_EMP_EMPSER, EMPSER, TIPO_DOC_EMPSER, ' +
      '   SUBTIPO_EMPSER, FECHA_DESDE_EMPSER, FECHA_HASTA_EMPSER, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:cod, :emp, :ser, ''SE'', ' +
      '   ''NORMAL'', CURDATE(), NULL, NOW(), :u, NOW(), :u)';
    q.ParamByName('cod').AsString := sCodigoSer;
    q.ParamByName('emp').AsString := AEmpresa;
    q.ParamByName('ser').AsString := ASerie;
    q.ParamByName('u').AsString   := oUser;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmComprasSesiones.GetCodigoAutoSesion;
var
  sSerie, sEmpresa : string;
begin
  // Usa PRC_GET_NEXT_CONT_FACT_SERIE (el mismo que facturas/inventarios)
  // para obtener el siguiente numero por (TIPO_DOC, EMPRESA, SERIE).
  // La serie viene de la cabecera (combo alimentado por fza_empresas_series
  // filtrado por TIPO_DOC_EMPSER='SE'). Si por lo que sea esta vacia,
  // dejamos NUMERO_SES sin asignar y la grabacion fallara con un mensaje
  // claro de "elige una serie primero".
  sSerie   := Trim(unqryTablaG.FieldByName('SERIE_SES').AsString);
  sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_SES').AsString);
  if (sSerie = '') or (sEmpresa = '') then
    Exit;
  with unstrdprcGetContadorSesion do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',           ptInput);
    Params.CreateParam(ftString, 'pTipoDoc',         ptInput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR',ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',    ptInput);
    Params.CreateParam(ftString, 'pcont',            ptOutput);
    ParamByName('pserie').AsString            := sSerie;
    ParamByName('pTipoDoc').AsString          := 'SE';
    ParamByName('pEMPRESA_CONTADOR').AsString := sEmpresa;
    ParamByName('pUSUARIOMODIF').AsString     := oUser;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_SES').AsString :=
                                                  ParamByName('pcont').AsString;
  end;
end;

procedure TdmComprasSesiones.ChequearDuplicado(const ACodigoArt: string;
  out AExiste: Boolean; out ADescripcion: string);
begin
  AExiste      := False;
  ADescripcion := '';
  unqryArticuloExiste.Close;
  unqryArticuloExiste.SQL.Text :=
    'SELECT CODIGO_ART_ART, DESCRIPCION_ART ' +
    '  FROM fza_articulos ' +
    ' WHERE CODIGO_ART_ART = :p';
  unqryArticuloExiste.ParamByName('p').AsString := ACodigoArt;
  unqryArticuloExiste.Open;
  try
    if not unqryArticuloExiste.IsEmpty then
    begin
      AExiste      := True;
      ADescripcion :=
        unqryArticuloExiste.FieldByName('DESCRIPCION_ART').AsString;
    end;
  finally
    unqryArticuloExiste.Close;
  end;
end;

procedure TdmComprasSesiones.RefrescarTotalesSesion;
var
  EstadoInicial: TDataSetState;
  sCampoTipoIvaLinea: string;
begin
  if Assigned(unqryTablaG) and unqryTablaG.Active and
     Assigned(unqrySesionLin) and unqrySesionLin.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    EstadoInicial := unqryTablaG.State;
    sCampoTipoIvaLinea := '';
    if (unqryTablaG.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) and
       (UpperCase(Trim(unqryTablaG.FieldByName(
         'ESVARIOS_TIPOS_IVA_SES').AsString)) = 'S') then
      sCampoTipoIvaLinea := 'TIPO_IVA_SESLIN';
    CalcularTotalesDocumentoCompra(inLibGlobalVar.oConn, unqryTablaG,
      unqrySesionLin, 'SES', 'TOTAL_LINEA_SESLIN',
      sCampoTipoIvaLinea, 'PORCENTAJE_IVA_SESLIN');
    if EstadoInicial <> dsInsert then
      PersistirTotalesSesion;
    if EstadoInicial = dsBrowse then
    begin
      if unqryTablaG.State = dsEdit then
      begin
        unqryTablaG.Cancel;
        unqryTablaG.Refresh;
      end;
    end;
  end;
end;

procedure TdmComprasSesiones.PersistirTotalesSesion;
const
  CAMPOS_TOTALES: array[0..31] of string = (
    'CODIGO_IVA_SES',
    'PORCENTAJE_IVAN_SES', 'TOTAL_BASEI_IVAN_SES', 'TOTAL_IVAN_SES',
    'PORCENTAJE_REN_SES', 'TOTAL_REN_SES',
    'PORCENTAJE_IVAR_SES', 'TOTAL_BASEI_IVAR_SES', 'TOTAL_IVAR_SES',
    'PORCENTAJE_RER_SES', 'TOTAL_RER_SES',
    'PORCENTAJE_IVAS_SES', 'TOTAL_BASEI_IVAS_SES', 'TOTAL_IVAS_SES',
    'PORCENTAJE_RES_SES', 'TOTAL_RES_SES',
    'PORCENTAJE_IVAE_SES', 'TOTAL_BASEI_IVAE_SES', 'TOTAL_IVAE_SES',
    'PORCENTAJE_REE_SES', 'TOTAL_REE_SES',
    'PORCENTAJE_RETENCION_SES', 'TOTAL_RETENCION_SES',
    'TOTAL_BRUTO_SES',
    'PORCENTAJE_DTO_COMERCIAL_SES', 'TOTAL_DTO_COMERCIAL_SES',
    'PORCENTAJE_DTO_FINANCIERO_SES', 'TOTAL_DTO_FINANCIERO_SES',
    'TOTAL_BASES_SES', 'TOTAL_IMPUESTOS_SES',
    'TOTAL_SES', 'TOTAL_LIQUIDO_SES');
var
  q       : TUniQuery;
  oCampo  : TField;
  sCampo  : string;
  sSql    : string;
  iCampos : Integer;
begin
  if (unqryTablaG.State <> dsInsert) and
     (Trim(unqryTablaG.FieldByName('SERIE_SES').AsString) <> '') and
     (Trim(unqryTablaG.FieldByName('NUMERO_SES').AsString) <> '') then
  begin
    sSql := 'UPDATE fza_compras_sesiones SET ';
    iCampos := 0;
    for sCampo in CAMPOS_TOTALES do
    begin
      if unqryTablaG.FindField(sCampo) <> nil then
      begin
        if iCampos > 0 then
          sSql := sSql + ', ';
        sSql := sSql + '`' + sCampo + '` = :' + sCampo;
        Inc(iCampos);
      end;
    end;
    if iCampos > 0 then
    begin
      sSql := sSql +
        ' WHERE `SERIE_SES` = :SERIE AND `NUMERO_SES` = :NUMERO';
      q := TUniQuery.Create(nil);
      try
        q.Connection := inLibGlobalVar.oConn;
        q.SQL.Text := sSql;
        for sCampo in CAMPOS_TOTALES do
        begin
          oCampo := unqryTablaG.FindField(sCampo);
          if oCampo <> nil then
            q.ParamByName(sCampo).Value := oCampo.Value;
        end;
        q.ParamByName('SERIE').AsString :=
          unqryTablaG.FieldByName('SERIE_SES').AsString;
        q.ParamByName('NUMERO').AsString :=
          unqryTablaG.FieldByName('NUMERO_SES').AsString;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

function TdmComprasSesiones.DetectarConflictoConcurrencia: Boolean;
var
  uxTmp: TUniQuery;
  dt   : TDateTime;
begin
  // Compara INSTANTE_MODIF actual del registro en BBDD contra el cargado.
  Result := False;
  uxTmp  := TUniQuery.Create(nil);
  try
    uxTmp.Connection := inLibGlobalVar.oConn;
    uxTmp.SQL.Text :=
      'SELECT INSTANTE_MODIF FROM fza_compras_sesiones ' +
      'WHERE SERIE_SES = :s AND NUMERO_SES = :n';
    uxTmp.ParamByName('s').AsString :=
      unqryTablaG.FieldByName('SERIE_SES').AsString;
    uxTmp.ParamByName('n').AsString :=
      unqryTablaG.FieldByName('NUMERO_SES').AsString;
    uxTmp.Open;
    if not uxTmp.IsEmpty then
    begin
      dt := uxTmp.FieldByName('INSTANTE_MODIF').AsDateTime;
      Result := (dt > FInstanteCargaSesion);
    end;
  finally
    FreeAndNil(uxTmp);
  end;
end;

procedure TdmComprasSesiones.AplicarKitAFila(const AIdKit: string;
                                             const ALineaID: Integer;
                                             const AIdFila: Integer);
begin
  // Lee fza_compras_sesiones_kits_det del kit indicado y vuelca cantidades
  // sobre la fila ALineaID/AIdFila buscando la columna del eje pivot que
  // case con VALOR_DESTINO_SESKITD. Implementación detallada en
  // inLibComprasSesiones (capa visual de matriz).
end;

procedure TdmComprasSesiones.AplicarKitATodasFilas(const AIdKit: string;
                                                   const ALineaID: Integer);
begin
  // Itera todas las filas de la línea y llama AplicarKitAFila.
end;

procedure TdmComprasSesiones.ReconstruirFilasLinea(const ALineaID: Integer);
begin
  // Cuando cambia ID_AC_FILA_SESLIN (conjunto de colores, p.ej.):
  //   - Borra filas que ya no aplican.
  //   - Inserta filas para valores nuevos del conjunto.
  //   - Borra celdas huérfanas.
end;

procedure TdmComprasSesiones.RecargarProveedorSesion(const ACodigoPrv: string);
begin
  // Reset del tallaje-defecto-del-documento: se recalcula desde el
  // proveedor (CopiarDefectosProveedor) solo cuando el usuario ESTA
  // cambiando el proveedor de la cabecera; al navegar a otra sesion (o
  // dejar el proveedor en blanco) no debe arrastrarse el de la sesion
  // anterior.
  FTallajeDefectoActual := 0;
  // Ficha + kits del proveedor para la pestaña Proveedor. El detalle de
  // kits es master/detail de unqryPrvKits y sigue solo al master.
  unqryPrvFicha.Close;
  unqryPrvKitsDet.Close;
  unqryPrvKits.Close;
  unqryPrvKitsCombo.Close;
  if Trim(ACodigoPrv) <> '' then
  begin
    unqryPrvFicha.ParamByName('prv').AsString     := ACodigoPrv;
    unqryPrvKits.ParamByName('prv').AsString       := ACodigoPrv;
    unqryPrvKitsCombo.ParamByName('prv').AsString  := ACodigoPrv;
    unqryPrvFicha.Open;
    unqryPrvKits.Open;
    unqryPrvKitsCombo.Open;
    if not unqryPrvKitsDet.Active then
      unqryPrvKitsDet.Open;
  end;
end;

procedure TdmComprasSesiones.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabSesionPrint.Close;
  unqryCabSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryCabSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryCabSesionPrint.Open;

  unqryLinSesionPrint.Close;
  unqryLinSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryLinSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryLinSesionPrint.Open;

  unqryGuiasSesionPrint.Close;
  unqryGuiasSesionPrint.ParamByName('SERIE_SES').AsString  := ASerie;
  unqryGuiasSesionPrint.ParamByName('NUMERO_SES').AsString := ANumero;
  unqryGuiasSesionPrint.Open;
end;

end.
