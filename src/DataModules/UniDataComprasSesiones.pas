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
  inLibUser, inMtoPrincipal;

type
  TdmComprasSesiones = class(TdmBase)
    // Cabecera de sesión (lista principal). unqryTablaG ya existe en TdmBase.
    unqrySesionLin: TUniQuery;
    dsSesionLin: TDataSource;

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

    // Detección de duplicados al teclear código de artículo
    unqryArticuloExiste: TUniQuery;

    // Contador propio: TIPO_DOC_CON = 'SC' (Sesion de Compra; varchar(2))
    unstrdprcGetContadorSesion: TUniStoredProc;

    // Stored procs auxiliares (validación, etc.)
    unstrdprcValidarSesion: TUniStoredProc;

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
    procedure CalcularTotalesLineaActual;
  public
    procedure GetCodigoAutoSesion;
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
  end;

var
  dmComprasSesiones: TdmComprasSesiones;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmComprasSesiones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqrySesionLin.Connection         := inLibGlobalVar.oConn;
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
  unqryArticuloExiste.Connection    := inLibGlobalVar.oConn;
  unstrdprcGetContadorSesion.Connection := inLibGlobalVar.oConn;
  unstrdprcValidarSesion.Connection := inLibGlobalVar.oConn;

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
    FieldByName('ESVAR_FIJA_SES').AsString        := 'N';
    FieldByName('ESGENERA_PEDIDO_SES').AsString   := 'N';
    FieldByName('ESGENERA_ALBARAN_SES').AsString  := 'N';
    FieldByName('SERIE_SES').AsString  := 'SES';
    FieldByName('USUARIO_ALTA').AsString := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmComprasSesiones.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_SES').AsString = '') or
     (unqryTablaG.FieldByName('NUMERO_SES').AsString = '0') then
    GetCodigoAutoSesion;

  unqryTablaG.FieldByName('USUARIO_MODIF').AsString  := oUser;
  unqryTablaG.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqrySesionLin do
  begin
    FieldByName('SERIE_SES_SESLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_SES').AsString;
    FieldByName('NUMERO_SES_SESLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_SES').AsString;
    FieldByName('TIPO_LINEA_SESLIN').AsString := 'MATRIZ';
    FieldByName('TIPO_ART_SESLIN').AsString   := 'ESTANDAR';
    FieldByName('TIPO_CANTIDAD_SESLIN').AsString := 'Uds';
    FieldByName('ESDUPLICADO_SESLIN').AsString := 'N';
    FieldByName('USUARIO_ALTA').AsString := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmComprasSesiones.unqrySesionLinBeforePost(DataSet: TDataSet);
var
  bExiste: Boolean;
  sDescr : string;
begin
  inherited;
  // Sincroniza TIPO_ART desde TIPO_LINEA
  if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'SERVICIO' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'SERVICIO'
  else if unqrySesionLin.FieldByName('TIPO_LINEA_SESLIN').AsString = 'KIT' then
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'KIT'
  else
    unqrySesionLin.FieldByName('TIPO_ART_SESLIN').AsString := 'ESTANDAR';

  // Detección de duplicado
  if unqrySesionLin.FieldByName(
    'CODIGO_ART_TENTATIVO_SESLIN').AsString <> '' then
  begin
    ChequearDuplicado(
      unqrySesionLin.FieldByName('CODIGO_ART_TENTATIVO_SESLIN').AsString,
      bExiste, sDescr);
    if bExiste then
      unqrySesionLin.FieldByName('ESDUPLICADO_SESLIN').AsString := 'S'
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
  RefrescarTotalesSesion;
end;

procedure TdmComprasSesiones.unqrySesionLinAfterDelete(DataSet: TDataSet);
begin
  inherited;
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
  rTotalUds : Double;
  rPrecio   : Double;
begin
  // Recalcula TOTAL_UNIDADES_SESLIN y TOTAL_LINEA_SESLIN para la línea
  // actualmente en edición sumando las celdas activas.
  // Implementación: SELECT SUM(CANTIDAD_SESCEL) FROM
  // fza_compras_sesiones_celdas
  //                  WHERE pk de línea.
  rTotalUds := 0;
  // TODO: ejecutar consulta de agregación.
  rPrecio := unqrySesionLin.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
  if not (unqrySesionLin.State in [dsInsert, dsEdit]) then
    unqrySesionLin.Edit;
  unqrySesionLin.FieldByName('TOTAL_UNIDADES_SESLIN').AsFloat := rTotalUds;
  unqrySesionLin.FieldByName('TOTAL_LINEA_SESLIN').AsFloat    :=
    rTotalUds * rPrecio;
end;

procedure TdmComprasSesiones.GetCodigoAutoSesion;
begin
  with unstrdprcGetContadorSesion do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'ptipodoc', ptInput);
    Params.CreateParam(ftString, 'pcont',    ptOutput);
    Params.CreateParam(ftString, 'pUSUARIO', ptInput);
    ParamByName('ptipodoc').AsString := 'SC';
    ParamByName('pUSUARIO').AsString := oUser;
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
    'SELECT CODIGO_ART_ART, DESCRIPCION_ART FROM fza_articulos ' +
    'WHERE CODIGO_ART_ART = :p';
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
begin
  // Sumatorios globales se calculan al vuelo desde la vista VI_SES_RESUMEN
  // o se mantienen en la propia cabecera. Implementación pendiente al
  // conectar la pestaña Resumen del formulario.
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
    uxTmp.Free;
  end;
end;

procedure TdmComprasSesiones.AplicarKitAFila(const AIdKit: string;
  const ALineaID: Integer; const AIdFila: Integer);
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

end.
