unit UniDataCaja;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Data.DB, Datasnap.Provider,
  Datasnap.DBClient, Uni, MemDS, DBAccess, system.Math, UniDataGen,
  inLibGlobalVar;

type
  TOnUpdateTotalEvent = 
                     procedure(Sender: TObject; NuevoTotal: Currency) of object;
  TdmCajaOpe = class(TDataModule)
    cdsLineas:TClientDataSet;
    cdsCabecera:TClientDataSet;
    DataSetProviderLineas:TDataSetProvider;
    DataSetProviderCabecera:TDataSetProvider;
    dsCabecera:TDataSource;
    dsLineas:TDataSource;
    qryDefinicionArticulo: TUniQuery;
    qryStock: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasAfterInsert(DataSet: TDataSet);
    procedure cdsCabeceraAfterInsert(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
  private
    FOnUpdateTotal: TOnUpdateTotalEvent;
    procedure ConfigurarEstructuraLineas;
    procedure ConfigurarEstructuraCabecera;
    procedure InicializarNuevaFactura(const ASerieFactura, ANroFactura: string);
  public
    //uConexion:TUniConnection;
    function GenerarSkuFinal(ArticuloBase: string): string;
    { Public declarations }
  public
    function BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                  var LabelDestino: String):Boolean;
    function GetTarifaDefault : string;
//    procedure CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//    procedure CalcularTotalesCabecera;
    property OnUpdateTotal: TOnUpdateTotalEvent read FOnUpdateTotal
                                                write FOnUpdateTotal;
  end;

var
  dmCajaOpe: TdmCajaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

//procedure TdmCajaOpe.CalcularTotalesCabecera;
//var
//  Clon: TClientDataSet;
//  TotalLiquido, TotalBase, TotalImpuestos: Currency;
//  EstaEditando: Boolean;
//  RecNoActivo: Integer;
//begin
//  TotalLiquido := 0;
//  TotalBase := 0;
//  if cdsLineas.Active then
//  begin
//    RecNoActivo := cdsLineas.RecNo;
//    EstaEditando := (cdsLineas.State in [dsEdit, dsInsert]);
//    Clon := TClientDataSet.Create(nil);
//    try
//      Clon.CloneCursor(cdsLineas, True);
//      Clon.DisableControls;
//      Clon.First;
//      while not Clon.Eof do
//      begin
//        if EstaEditando and (Clon.RecNo = RecNoActivo) then
//        begin
//          TotalLiquido := TotalLiquido +
//		                cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase    := TotalBase    +
//		            cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end
//        else
//        begin
//          TotalLiquido := TotalLiquido +
//		                     Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase := TotalBase +
//		                 Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end;
//        Clon.Next;
//      end;
//    finally
//      Clon.EnableControls;
//      Clon.Free;
//    end;
//  end;
//  TotalImpuestos := TotalLiquido - TotalBase;
//  cdsCabecera.Edit;
//  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := TotalBase;
//  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency :=
//                                                                 TotalImpuestos;
//  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := TotalLiquido;
//  cdsCabecera.Post;
//  if Assigned(FOnUpdateTotal) then
//    FOnUpdateTotal(Self, TotalLiquido);
//end;

//procedure TdmCajaOpe.CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//var
//  PrecioUnitario, Cantidad, PorcenDto, PorcenIVA: Currency;
//  TotalBruto, MontoDescuentoTotal, TotalNeto: Currency;
//  TotalBase, TotalImpuestos: Currency;
//  EsImpuestosIncluidos: Boolean;
//begin
//  if not cdsLineas.Active then Exit;
//  if cdsLineas.State = dsBrowse then cdsLineas.Edit;
//  Cantidad := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsCurrency;
//  PrecioUnitario := cdsLineas.FieldByName(
//                                       'PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
//  PorcenIVA := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency;
//  EsImpuestosIncluidos := (cdsLineas.FieldByName(
//                             'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString = 'S');
//  TotalBruto := RoundTo(PrecioUnitario * Cantidad, -2);
//  if MantenerImporteDto then
//  begin
//    MontoDescuentoTotal := cdsLineas.FieldByName(
//                                         'PRECIO_DTO_FACTURA_LINEA').AsCurrency;
//    if TotalBruto <> 0 then
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat :=
//                                        (MontoDescuentoTotal * 100) / TotalBruto
//    else
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat := 0;
//  end
//  else
//  begin
//    // MODO B: Cambio normal. El % manda.
//    PorcenDto := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
//    // Calculamos el descuento sobre el Total Bruto
//    MontoDescuentoTotal := RoundTo(TotalBruto * (PorcenDto / 100), -2);
//    cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency := MontoDescuentoTotal;
//  end;
//  // 4. Aplicar el Descuento (Resta Global)
//  // Aquí está la corrección: TotalBruto - DescuentoTotal
//  TotalNeto := TotalBruto - MontoDescuentoTotal;
//  // 5. Desglose de Impuestos
//  if EsImpuestosIncluidos then
//  begin
//    // Si el precio incluye IVA, TotalNeto es el Total a Pagar
//    // Desglosamos hacia atrás
//    if (1 + (PorcenIVA / 100)) <> 0 then
//      TotalBase := RoundTo(TotalNeto / (1 + (PorcenIVA / 100)), -2)
//    else
//      TotalBase := TotalNeto;
//    // El total final es lo que dio la resta
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalNeto;
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//  end
//  else
//  begin
//    // Si el precio NO incluye IVA, TotalNeto es la Base Imponible Total
//    TotalBase := TotalNeto;
//    TotalImpuestos := RoundTo(TotalBase * (PorcenIVA / 100), -2);
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalBase + TotalImpuestos;
//  end;
//  CalcularTotalesCabecera;
//end;

function TdmCajaOpe.BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                         var LabelDestino: String): Boolean;
var
  unqry: TUniQuery;
  FieldToGet: string;
  SQLStr: string;
begin
  LabelDestino := '';
  Result := False;
  if Trim(Codigo) = '' then
    Exit;
  if TipoEntidad = 'EMPLEADOS' then
  begin
    SQLStr := 'SELECT DIMINUTIVO_TICKET_USUARIO ' +
              '  FROM fza_usuarios ' +
              ' WHERE CODIGO_EMPLEADO_USUARIO = :COD';
    FieldToGet := 'DIMINUTIVO_TICKET_USUARIO';
  end
  else if TipoEntidad = 'CLIENTES' then
  begin
    SQLStr := 'SELECT RAZONSOCIAL_CLIENTE ' +
              '  FROM fza_clientes ' +
              ' WHERE CODIGO_CLIENTE = :COD';
    FieldToGet := 'RAZONSOCIAL_CLIENTE';
  end
  else
    Exit;
  unqry := TUniQuery.Create(nil);
  try
    unqry.Connection := oConn;
    unqry.SQL.Text := SQLStr;
    unqry.ParamByName('COD').AsString := Codigo;
    unqry.Open;
    if not unqry.IsEmpty then
    begin
      LabelDestino := unqry.FieldByName(FieldToGet).AsString;
      Result := True;
    end;
  finally
    unqry.Free;
  end;
end;

function TdmCajaOpe.GenerarSkuFinal(ArticuloBase: string): string;
var
  i: Integer;
  ValorAttr: string;
  SkuBuilder: string;
  NumAttr:Integer;
begin
  NumAttr := cdsLineas.FieldByName(
                         'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  SkuBuilder := ArticuloBase;
  for i := 1 to NumAttr do
  begin
    ValorAttr := cdsLineas.FieldByName('ATTR' + IntToStr(i) +
	                                                         '_VALOR').AsString;
    if ValorAttr <> '' then
       SkuBuilder := SkuBuilder + '/' + ValorAttr;
  end;
  Result := SkuBuilder;
end;

function TdmCajaOpe.GetTarifaDefault: string;
begin
  var sql := TUniQuery.Create(nil);
  try
    sql.Connection := oConn;
    sql.SQL.Text := 'SELECT CODIGO_TARIFA ' +
                    ' FROM fza_tarifas ' +
                    'WHERE ESDEFAULT_TARIFA = ' + QuotedStr('S') +
                    ' LIMIT 1 ' ;
    sql.Open;
    Result := sql.FieldByName('CODIGO_TARIFA').AsString;
    sql.Close;
  finally
    FreeAndNil(sql);
  end;
end;

procedure TdmCajaOpe.InicializarNuevaFactura(const ASerieFactura,
                                                   ANroFactura: string);
begin
  // Limpiar datos anteriores
  if cdsLineas.Active then cdsLineas.EmptyDataSet;
  if cdsCabecera.Active then cdsCabecera.EmptyDataSet;
  // Crear nuevo registro de cabecera
  cdsCabecera.Append;
  cdsCabecera.FieldByName('SERIE_FACTURA').AsString := ASerieFactura;
  cdsCabecera.FieldByName('NRO_FACTURA').AsString := ANroFactura;
  cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime := Date;
  cdsCabecera.FieldByName('ESCONSOLIDADA_FACTURA').AsString := 'N';
  cdsCabecera.FieldByName('TIPO_FACTURA').AsString := 'NORMAL';
  cdsCabecera.FieldByName('FASE_FACTURA').AsString := 'BORRADOR';
  cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := 0;
  cdsCabecera.FieldByName('INSTANTEALTA').AsDateTime := Now;
  cdsCabecera.FieldByName('USUARIOALTA').AsString := 'SISTEMA';
  // Inicializar totales a 0
  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := 0;
  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency := 0;
  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := 0;
  cdsCabecera.Post;
end;

procedure TdmCajaOpe.cdsCabeceraAfterInsert(DataSet: TDataSet);
begin
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := 0;
    cdsCabecera.FieldByName('SERIE_FACTURA').AsString := '0';
    cdsCabecera.FieldByName('NRO_FACTURA').AsString := '0';
end;

procedure TdmCajaOpe.cdsLineasAfterDelete(DataSet: TDataSet);
begin
//  CalcularTotalesCabecera;
end;

procedure TdmCajaOpe.cdsLineasAfterInsert(DataSet: TDataSet);
var
  NuevoNumero: Integer;
begin
  cdsLineas.FieldByName('SERIE_FACTURA_LINEA').AsString := '0';
  cdsLineas.FieldByName('NRO_FACTURA_LINEA').AsString := '0';
  NuevoNumero := cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger
                                                                          + 10;
  cdsCabecera.Edit;
  cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := NuevoNumero;
  cdsLineas.FieldByName('LINEA_FACTURA_LINEA').AsString :=
                                                  Format('%.4d', [NuevoNumero]);
  cdsLineas.FieldByName('CODIGO_VENDEDOR_FACTURA_LINEA').AsString :=
                      cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString;
end;

procedure TdmCajaOpe.cdsLineasAfterPost(DataSet: TDataSet);
begin
//  CalcularTotalesCabecera;
end;

procedure TdmCajaOpe.cdsLineasBeforePost(DataSet: TDataSet);
var
  i, Requeridos: Integer;
  ValorAttr: string;
  NombreAttr: string;
begin
  if DataSet.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString = ''
                                                                            then
    Abort;
  Requeridos := DataSet.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  if Requeridos = 0 then Exit;
  for i := 1 to Requeridos do
  begin
    ValorAttr := DataSet.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString;
    if Trim(ValorAttr) = '' then
    begin
      NombreAttr := DataSet.FieldByName('ATTR' + IntToStr(i) +
	                                                        '_NOMBRE').AsString;
      raise Exception.Create('Falta especificar: ' + NombreAttr +
	                                                      ' para el artículo.');
    end;
  end;
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  with cdsCabecera.FieldDefs do
  begin
    // -- IDENTIFICACIÓN DEL DOCUMENTO (PK) --
    Add('SERIE_FACTURA', ftString, 20, True);
    Add('NRO_FACTURA', ftString, 20, True);
    // -- ESTADOS Y TIPOS --
    Add('FECHA_FACTURA', ftDate, 0);
    Add('ESCONSOLIDADA_FACTURA', ftString, 1);
    Add('INSTANTECONSO_FACTURA', ftDateTime, 0);
    Add('TIPO_FACTURA', ftString, 20); // NORMAL, SIMPLIFICADA...
    Add('FASE_FACTURA', ftString, 20); // BORRADOR, ONLINE...
    // -- DATOS DE LA EMPRESA (EMISOR) --
    Add('CODIGO_EMPRESA_FACTURA', ftString, 8);
    Add('RAZONSOCIAL_EMPRESA_FACTURA', ftString, 200);
    Add('NIF_EMPRESA_FACTURA', ftString, 50);
    Add('MOVIL_EMPRESA_FACTURA', ftString, 40);
    Add('EMAIL_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION1_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION2_EMPRESA_FACTURA', ftString, 200);
    Add('POBLACION_EMPRESA_FACTURA', ftString, 200);
    Add('PROVINCIA_EMPRESA_FACTURA', ftString, 200);
    Add('CODIGO_PAIS_EMPRESA_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_EMPRESA_FACTURA', ftString, 150);
    Add('CPOSTAL_EMPRESA_FACTURA', ftString, 15);
    // -- CONFIGURACIÓN FISCAL EMPRESA --
    Add('ESRETENCIONES_EMPRESA_FACTURA', ftString, 1);
    Add('GRUPO_ZONA_IVA_EMPRESA_FACTURA', ftString, 10);
    Add('ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA', ftString, 1);
    // -- DATOS DEL CLIENTE (RECEPTOR) --
    Add('CODIGO_CLIENTE_FACTURA', ftString, 10);
    Add('RAZONSOCIAL_CLIENTE_FACTURA', ftString, 200);
    Add('NIF_CLIENTE_FACTURA', ftString, 50);
    Add('MOVIL_CLIENTE_FACTURA', ftString, 40);
    Add('EMAIL_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION1_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION2_CLIENTE_FACTURA', ftString, 200);
    Add('POBLACION_CLIENTE_FACTURA', ftString, 200);
    Add('PROVINCIA_CLIENTE_FACTURA', ftString, 200);
    Add('CPOSTAL_CLIENTE_FACTURA', ftString, 15);
    Add('CODIGO_PAIS_CLIENTE_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_CLIENTE_FACTURA', ftString, 150);
    Add('CODIGO_CAJERO_FACTURA', ftString, 20);
    // -- CONFIGURACIÓN FISCAL CLIENTE Y FACTURA --
    Add('CODIGO_IVA_FACTURA', ftString, 20);
    Add('ESIVA_RECARGO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIVA_EXENTO_CLIENTE_FACTURA', ftString, 1);
    Add('ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA', ftString, 1);
    Add('ESRETENCIONES_CLIENTE_FACTURA', ftString, 1);
    Add('TARIFA_ARTICULO_CLIENTE_FACTURA', ftString, 10);
    Add('ESIMP_INCL_TARIFA_CLIENTE_FACTURA', ftString, 1);
    Add('ESINTRACOMUNITARIO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESAPLICA_RE_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESIVAAGRICOLA_ZONA_IVA_FACTURA', ftString, 1);
    Add('PALABRA_REPORTS_ZONA_IVA_FACTURA', ftString, 10);
    Add('ESVENTA_ACTIVO_FIJO_FACTURA', ftString, 1);
    // -- IMPORTES Y DESGLOSES DE IVA (N:Normal, R:Reducido, S:Super, E:Exento)
    // IVA NORMAL
    Add('PORCEN_IVAN_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAN_FACTURA', ftBCD, 0);
    Add('PORCEN_REN_FACTURA', ftBCD, 0);
    Add('TOTAL_REN_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAN_FACTURA', ftBCD, 0);
    // IVA REDUCIDO
    Add('PORCEN_IVAR_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAR_FACTURA', ftBCD, 0);
    Add('PORCEN_RER_FACTURA', ftBCD, 0);
    Add('TOTAL_RER_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAR_FACTURA', ftBCD, 0);
    // IVA SUPER REDUCIDO
    Add('PORCEN_IVAS_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAS_FACTURA', ftBCD, 0);
    Add('PORCEN_RES_FACTURA', ftBCD, 0);
    Add('TOTAL_RES_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAS_FACTURA', ftBCD, 0);
    // IVA EXENTO
    Add('PORCEN_IVAE_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAE_FACTURA', ftBCD, 0);
    Add('PORCEN_REE_FACTURA', ftBCD, 0);
    Add('TOTAL_REE_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAE_FACTURA', ftBCD, 0);
    // -- TOTALES GENERALES --
    Add('TOTAL_BASES_FACTURA', ftBCD, 0);
    Add('TOTAL_IMPUESTOS_FACTURA', ftBCD, 0);
    Add('PORCEN_RETENCION_FACTURA', ftBCD, 0);
    Add('TOTAL_RETENCION_FACTURA', ftBCD, 0);
    Add('TOTAL_LIQUIDO_FACTURA', ftBCD, 0); // Lo que paga el cliente
    // -- OTROS DATOS --
    Add('FORMA_PAGO_FACTURA', ftString, 200);
    Add('NRO_FACTURA_ABONO_FACTURA', ftString, 8);
    Add('SERIE_FACTURA_ABONO_FACTURA', ftString, 8);
    // -- CAMPOS LARGOS Y MEMOS --
    Add('TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA', ftString, 1000);
    Add('TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA', ftString, 1000);
    Add('COMENTARIOS_FACTURA', ftString, 1000);
    Add('XML_FACTURA', ftMemo, 0); // Para VeriFactu
    Add('DOCUMENTO_FACTURA', ftBlob, 0);
    // -- CONTROL INTERNO --
    Add('CONTADOR_LINEAS_FACTURA', ftString, 8);
    Add('ESCREARARTICULOS_FACTURA', ftString, 1);
    Add('ESDESCRIPCIONES_AMP_FACTURA', ftString, 1);
    Add('ESFECHADEENTREGA_FACTURA', ftString, 1);
    // -- AUDITORÍA --
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;

  with cdsCabecera.IndexDefs.AddIndexDef do
  begin
    Name := 'PK_CABECERA';
    Fields := 'SERIE_FACTURA;NRO_FACTURA';
    Options := [ixPrimary, ixUnique];
  end;
  cdsCabecera.CreateDataSet;
end;

procedure TdmCajaOpe.ConfigurarEstructuraLineas;
begin
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  with cdsLineas.FieldDefs do
  begin
    // -- CLAVES DE ENLACE CON CABECERA (Foreign Keys) --
    Add('SERIE_FACTURA_LINEA', ftString, 20, True);
    Add('NRO_FACTURA_LINEA', ftString, 20, True);
    Add('LINEA_FACTURA_LINEA', ftString, 4, True);
    Add('CODIGO_VENDEDOR_FACTURA_LINEA', ftString, 20);
    // -- DATOS DEL ARTÍCULO (PADRE) --
    Add('CODIGO_ARTICULO_FACTURA_LINEA', ftString, 50);
    Add('CODIGO_FAMILIA_FACTURA_LINEA', ftString, 20);
    Add('NOMBRE_FAMILIA_FACTURA_LINEA', ftString, 200);
    Add('DESCRIPCION_ARTICULO_FACTURA_LINEA', ftString, 100);
    // El SKU exacto que descuenta stock (ej: ZAP-OXFORD/42/NEGRO)
    Add('CODIGO_UNIDAD_FACTURA_LINEA', ftString, 50);
    Add('TIPO_ARTICULO_FACTURA_LINEA', ftString, 10); // 'ESTANDAR' o 'SERVICIO'
    Add('NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger, 0);
    for var I := 1 to 5 do
    begin
      Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 50);
      Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 50);
    end;
    // DATOS DE TRAZABILIDAD (Si el artículo lo requiere)
    Add('LOTE_FACTURA_LINEA', ftString, 50);
    Add('FECHA_CADUCIDAD_FACTURA_LINEA', ftDate, 0);
    Add('PRECIO_ULT_COMPRA_FACTURA_LINEA', ftBCD, 0);
    Add('CODIGO_PROVEEDOR_FACTURA_LINEA', ftString, 20);
    Add('RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA', ftString, 200);
    Add('ESPROVEEDORPRINCIPAL_FACTURA_LINEA', ftString, 1);
    Add('FECHA_ENTREGA_FACTURA_LINEA', ftDateTime, 0);
    // -- CANTIDADES Y TARIFAS --
    Add('TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA', ftString, 20); // 'Uds', 'Kg'
    Add('ESIMP_INCL_TARIFA_FACTURA_LINEA', ftString, 1);
    Add('CODIGO_TARIFA_FACTURA_LINEA', ftString, 10);
    // IMPORTANTE: ftBCD maneja bien los decimales de MySQL (Decimal 19,6)
    Add('CANTIDAD_FACTURA_LINEA', ftBCD, 0);
    // -- PRECIOS Y DESCUENTOS --
    Add('PRECIOSALIDA_FACTURA_LINEA', ftBCD, 0);
    Add('PORCEN_DTO_FACTURA_LINEA', ftBCD, 0);
    Add('PRECIO_DTO_FACTURA_LINEA', ftBCD, 0);
    // -- IMPORTES Y TOTALES --
    Add('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA', ftBCD, 0);
    Add('TIPOIVA_ARTICULO_FACTURA_LINEA', ftString, 2);
    Add('PORCEN_IVA_FACTURA_LINEA', ftBCD, 0);
    Add('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA', ftBCD, 0);
    Add('TOTAL_FACTURA_LINEA', ftBCD, 0);
    Add('TOTAL_FACTURASIVA_LINEA', ftBCD, 0);
    // -- CAMPOS DE AUDITORÍA --
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;
  with cdsLineas.IndexDefs.AddIndexDef do
  begin
    Name := 'PRIMARY_KEY';
    Fields := 'SERIE_FACTURA_LINEA;NRO_FACTURA_LINEA;LINEA_FACTURA_LINEA';
    Options := [ixPrimary, ixUnique];
  end;
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := oConn;
  qryStock.Connection := oConn;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

end.
