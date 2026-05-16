{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidos                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de pedidos.                                                   }
{    Cabeceras y líneas de fza_pedidos, generación de albaranes e importación  }
{    PrestaShop.                                                               }
{******************************************************************************}
unit UniDataPedidos;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal,
  frxClass, frxDBSet,
  inLibPresta, frCoreClasses;

type
  TdmPedidos = class(TdmBase)
    unqryPedidosLineas: TUniQuery;
    dsPedidosLineas: TDataSource;
    unqryLinPedido: TUniQuery;
    dsLinPedido: TDataSource;
    unqryEmpDataPedido: TUniQuery;
    unqryCliDataPedido: TUniQuery;
    unqryArtDataLinPedido: TUniQuery;
    unstrdprcCrearPedido: TUniStoredProc;
    unstrdprcGetContadorPedido: TUniStoredProc;
    unstrdprcGetContador: TUniStoredProc;
    unstrdprcCrearAlbaranInicio: TUniStoredProc;
    unstrdprcCrearAlbaranLinea:  TUniStoredProc;
    unstrdprcCrearAlbaranFin:    TUniStoredProc;
    fxdsPrintPed: TfrxDBDataset;
    fxdstPrintLinPed: TfrxDBDataset;
    unqryAlbaranes: TUniQuery;
    dsAlbaranes:    TDataSource;
    unqryMensajes: TUniQuery;
    dsMensajes:    TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterPost(DataSet: TDataSet);
  public
    procedure GetCodigoAutoPedido;
    procedure GetCodigoAutoCliente;
    procedure CalcularTotalesPedido;
    procedure CopiarEmpresaaPedido(DataSet: TDataSet);
    procedure CopiarClienteaPedido(DataSet: TDataSet);

    // Cantidades entregadas / pendientes
    procedure RecalcularEntregasLinea;

    // Instala los procs PRC_PED_CREAR_ALBARAN_* de forma idempotente.
    // Cada CREATE PROCEDURE se envía al servidor como una sola sentencia,
    // evitando la necesidad de DELIMITER (que TUniScript no entiende).
    procedure InstalarProcedimientos;

    // Crear albarán a partir de las cantidades entregadas pendientes
    function CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                     aLineas: TList<TPair<string,
                                     Currency>>): Boolean;

    // Importación PrestaShop
    function ImportarPedidoPrestaShop(aOrder: TOrder): Boolean;
    function ExistePedidoPrestaShop(const sIdPS: string): Boolean;

    procedure OpenTables;
  private
    FProcsInstalados: Boolean;
  end;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmPedidos }

procedure TdmPedidos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := inLibGlobalVar.oConn;
  unqryPedidosLineas.Connection    := inLibGlobalVar.oConn;
  unqryLinPedido.Connection        := inLibGlobalVar.oConn;
  unqryEmpDataPedido.Connection    := inLibGlobalVar.oConn;
  unqryCliDataPedido.Connection    := inLibGlobalVar.oConn;
  unqryArtDataLinPedido.Connection := inLibGlobalVar.oConn;
  unstrdprcCrearPedido.Connection            := inLibGlobalVar.oConn;
  unstrdprcGetContadorPedido.Connection      := inLibGlobalVar.oConn;
  unstrdprcGetContador.Connection            := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranInicio.Connection     := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranLinea.Connection      := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranFin.Connection        := inLibGlobalVar.oConn;
  unqryPerfiles.Connection         := inLibGlobalVar.oConn;
  unqryAlbaranes.Connection        := inLibGlobalVar.oConn;
  unqryMensajes.Connection         := inLibGlobalVar.oConn;
end;

procedure TdmPedidos.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryPedidosLineas) and unqryPedidosLineas.Active then
    unqryPedidosLineas.Close;
  if Assigned(unqryAlbaranes) and unqryAlbaranes.Active then
    unqryAlbaranes.Close;
  if Assigned(unqryMensajes) and unqryMensajes.Active then
    unqryMensajes.Close;
  inherited;
end;

procedure TdmPedidos.OpenTables;
begin
  if not unqryPedidosLineas.Active then unqryPedidosLineas.Open;
  if not unqryAlbaranes.Active     then unqryAlbaranes.Open;
  if not unqryMensajes.Active      then unqryMensajes.Open;
end;

procedure TdmPedidos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('FECHA_PED').AsDateTime := Date;
    FieldByName('CODIGO_EMP_PED').AsString := '0';
    FieldByName('CODIGO_CLI_PED').AsString := '0';
    FieldByName('NUMERO_PED').AsString     := '0';
    if FindField('SERIE_PED') <> nil then
      FieldByName('SERIE_PED').AsString    := 'A1';
    if FindField('ESTADO_PED') <> nil then
      FieldByName('ESTADO_PED').AsString   := 'ABIERTO';
    if FindField('ESCONSOLIDADO_PED') <> nil then
      FieldByName('ESCONSOLIDADO_PED').AsString := 'N';
  end;
end;

procedure TdmPedidos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_PED').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PED').AsString = '') then
    GetCodigoAutoPedido;
  if (unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString = '0') then
    GetCodigoAutoCliente;
  CalcularTotalesPedido;
end;

procedure TdmPedidos.unqryPedidosLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryPedidosLineas do
  begin
    FieldByName('NUMERO_PED_PEDLIN').AsString :=
                                 unqryTablaG.FieldByName('NUMERO_PED').AsString;
    FieldByName('SERIE_PED_PEDLIN').AsString :=
                                  unqryTablaG.FieldByName('SERIE_PED').AsString;
    FieldByName('CANTIDAD_PEDLIN').AsFloat := 1;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
      FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := 0;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := 1;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
      FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforePost(DataSet: TDataSet);
var
  fCantidad, fEntregada, fPendiente: Double;
begin
  inherited;
  RecalcularEntregasLinea;
  // El total de la línea siempre se mantiene coherente
  with unqryPedidosLineas do
  begin
    fCantidad  := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
      fEntregada := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat
    else
      fEntregada := 0;
    fPendiente := fCantidad - fEntregada;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fPendiente;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
    begin
      if fPendiente <= 0 then
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
      else
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
    if (FindField('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN') <> nil) and
       (FindField('TOTAL_PEDLIN') <> nil) then
      FieldByName('TOTAL_PEDLIN').AsFloat :=
        fCantidad * FieldByName('PRECIO_VENTA_SIVA_ARTICULO_PEDLIN').AsFloat;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesPedido;
end;

procedure TdmPedidos.RecalcularEntregasLinea;
var
  fCant, fEntr: Double;
begin
  with unqryPedidosLineas do
  begin
    fCant := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') = nil then Exit;
    fEntr := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
    if fEntr > fCant then
      FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fCant - fEntr;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
    begin
      if (fCant - fEntr) <= 0 then
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
      else
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
  end;
end;

procedure TdmPedidos.GetCodigoAutoPedido;
begin
  with unstrdprcGetContadorPedido do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString    :=
      unqryTablaG.FieldByName('SERIE_PED').AsString;
    ParamByName('ptipodoc').AsString  := 'PE';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
                                 unqryTablaG.FieldByName(
                                   'CODIGO_EMP_PED').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_PED').AsString :=
                                                  ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.GetCodigoAutoCliente;
begin
  with unstrdprcGetContador do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'ptipodoc',     ptInput);
    Params.CreateParam(ftString, 'pcont',        ptOutput);
    Params.CreateParam(ftString, 'pUSUARIO',     ptInput);
    ParamByName('ptipodoc').AsString := 'CL';
    ParamByName('pUSUARIO').AsString  := oUser;
    ExecProc;
    unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString :=
                            ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.CalcularTotalesPedido;
var
  fBase, fIva, fTotal, fPorIva: Double;
  bk: TBookmark;
begin
  if not unqryPedidosLineas.Active then Exit;
  fBase := 0; fIva := 0;
  bk := unqryPedidosLineas.GetBookmark;
  try
    unqryPedidosLineas.DisableControls;
    unqryPedidosLineas.First;
    while not unqryPedidosLineas.Eof do
    begin
      fPorIva :=
        unqryPedidosLineas.FieldByName('PORCENTAJE_IVA_PEDLIN').AsFloat / 100;
      fTotal := unqryPedidosLineas.FieldByName('CANTIDAD_PEDLIN').AsFloat *
                unqryPedidosLineas.FieldByName(
                  'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN').AsFloat;
      fBase := fBase + fTotal;
      fIva  := fIva + (fTotal * fPorIva);
      unqryPedidosLineas.Next;
    end;
  finally
    if unqryPedidosLineas.BookmarkValid(bk) then
      unqryPedidosLineas.GotoBookmark(bk);
    unqryPedidosLineas.FreeBookmark(bk);
    unqryPedidosLineas.EnableControls;
  end;
  if (unqryTablaG.State = dsBrowse) then
    unqryTablaG.Edit;
  if unqryTablaG.FindField('TOTAL_BASES_PED') <> nil then
    unqryTablaG.FieldByName('TOTAL_BASES_PED').AsFloat := fBase;
  if unqryTablaG.FindField('TOTAL_IMPUESTOS_PED') <> nil then
    unqryTablaG.FieldByName('TOTAL_IMPUESTOS_PED').AsFloat := fIva;
  if unqryTablaG.FindField('TOTAL_LIQUIDO_PED') <> nil then
    unqryTablaG.FieldByName('TOTAL_LIQUIDO_PED').AsFloat := fBase + fIva;
end;

procedure TdmPedidos.CopiarEmpresaaPedido(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_EMP_PED').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PED').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PED').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PED').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PED').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_PED').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_PED').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    FindField('ESRETENCIONES_EMPRESA_PED').AsString  :=
      DataSet.FindField('ESRETENCIONES_EMP').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_PED').AsString :=
                            DataSet.FindField(
                              'ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  end;
end;

procedure TdmPedidos.CopiarClienteaPedido(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_CLI_PED').AsString                  :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_FISCAL_PED').AsString :=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_PED').AsString                 :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_FISCAL_PED').AsString        :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_PED').AsString               :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_FISCAL_PED').AsString:=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_PED').AsString        :=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_PED').AsString :=
                                       DataSet.FindField(
                                         'ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_PED').AsString  :=
      DataSet.FindField('ESINTRACOMUNITARIO_CLI').AsString;
    FindField('TARIFA_ARTICULO_CLIENTE_PED').AsString     :=
      DataSet.FindField('TARIFA_ARTICULO_CLI').AsString;
  end;
end;

procedure TdmPedidos.InstalarProcedimientos;
var
  q: TUniSQL;

  procedure Run(const sSql: string);
  begin
    q.SQL.Text := sSql;
    q.Execute;
  end;

begin
  if FProcsInstalados then Exit;
  q := TUniSQL.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
{
    // PRC_PED_CREAR_ALBARAN_INICIO
    Run('DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_INICIO');
    Run(
      'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_INICIO(' +
      '  IN  p_NUMERO_PED varchar(20),' +
      '  IN  p_SERIE_PED  varchar(20),' +
      '  IN  p_USUARIO    varchar(100),' +
      '  OUT p_NUMERO_ALB varchar(20),' +
      '  OUT p_SERIE_ALB  varchar(20)' +
      ') BEGIN ' +
      '  DECLARE v_serie  varchar(20); ' +
      '  DECLARE v_numero varchar(20); ' +
      '  SELECT SERIE_PED INTO v_serie FROM fza_pedidos ' +
      '   WHERE NUMERO_PED = p_NUMERO_PED AND SERIE_PED = p_SERIE_PED; ' +
      '  SELECT LPAD(IFNULL(MAX(CAST(NUMERO_ALB AS UNSIGNED)), 0) + 1, 6, ' +
      '''0'') ' +
      '    INTO v_numero FROM fza_albaranes WHERE SERIE_ALB = v_serie; ' +
      '  INSERT INTO fza_albaranes ( ' +
      '    NUMERO_ALB, SERIE_ALB, FECHA_ALB, ESTADO_ALB, ' +
      '    NUMERO_PED_ALB, SERIE_PED_ALB, ' +
      '    CODIGO_EMP_ALB, RAZON_SOCIAL_EMPRESA_ALB, NIF_EMPRESA_ALB, ' +
      '    MOVIL_EMPRESA_ALB, EMAIL_EMPRESA_ALB, ' +
      '    DIRECCION1_EMPRESA_ALB, DIRECCION2_EMPRESA_ALB, ' +
      '    POBLACION_EMPRESA_ALB, PROVINCIA_EMPRESA_ALB, ' +
      '    CODIGO_PAI_EMPRESA_ALB, NOMBRE_PAI_EMPRESA_ALB, ' +
      '    CODIGO_POSTAL_EMPRESA_ALB, GRUPO_ZONA_IVA_EMPRESA_ALB, ' +
      '    CODIGO_CLI_ALB, RAZON_SOCIAL_CLIENTE_ALB, NIF_CLIENTE_ALB, ' +
      '    MOVIL_CLIENTE_ALB, EMAIL_CLIENTE_ALB, ' +
      '    DIRECCION1_CLIENTE_ALB, DIRECCION2_CLIENTE_ALB, ' +
      '    POBLACION_CLIENTE_ALB, PROVINCIA_CLIENTE_ALB, ' +
      '    CODIGO_POSTAL_CLIENTE_ALB, ' +
      '    CODIGO_PAI_CLIENTE_ALB, NOMBRE_PAI_CLIENTE_ALB, ' +
      '    NOMBRE_CLI_ENVIO_ALB, MOVIL_CLIENTE_ENVIO_ALB, ' +
      '    DIRECCION1_CLIENTE_ENVIO_ALB, DIRECCION2_CLIENTE_ENVIO_ALB, ' +
      '    POBLACION_CLIENTE_ENVIO_ALB, PROVINCIA_CLIENTE_ENVIO_ALB, ' +
      '    CODIGO_POSTAL_CLIENTE_ENVIO_ALB, ' +
      '    CODIGO_PAI_CLIENTE_ENVIO_ALB, NOMBRE_PAI_CLIENTE_ENVIO_ALB, ' +
      '    TRANSPORTISTA_ALB, CODIGO_IVA_ALB, ' +
      '    ESIVA_RECARGO_CLIENTE_ALB, ESIVA_EXENTO_CLIENTE_ALB, ' +
      '    ESINTRACOMUNITARIO_CLIENTE_ALB, ' +
      '    TARIFA_ARTICULO_CLIENTE_ALB, ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
      '    PORCENTAJE_IVAN_ALB, PORCENTAJE_IVAR_ALB, ' +
      '    PORCENTAJE_IVAS_ALB, PORCENTAJE_IVAE_ALB, ' +
      '    FORMA_PAGO_ALB, CONTADOR_LINEAS_ALB, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT v_numero, v_serie, CURRENT_DATE(), ''ABIERTO'', ' +
      '         p_NUMERO_PED, p_SERIE_PED, ' +
      '         P.CODIGO_EMP_PED, P.RAZON_SOCIAL_EMPRESA_PED, ' +
      'P.NIF_EMPRESA_PED, ' +
      '         P.MOVIL_EMPRESA_PED, P.EMAIL_EMPRESA_PED, ' +
      '         P.DIRECCION1_EMPRESA_PED, P.DIRECCION2_EMPRESA_PED, ' +
      '         P.POBLACION_EMPRESA_PED, P.PROVINCIA_EMPRESA_PED, ' +
      '         P.CODIGO_PAI_EMPRESA_PED, P.NOMBRE_PAI_EMPRESA_PED, ' +
      '         P.CODIGO_POSTAL_EMPRESA_PED, P.GRUPO_ZONA_IVA_EMPRESA_PED, ' +
      '         P.CODIGO_CLI_PED, P.RAZON_SOCIAL_CLIENTE_FISCAL_PED, ' +
      '         P.NIF_CLIENTE_PED, P.MOVIL_CLIENTE_FISCAL_PED, ' +
      '         P.EMAIL_CLIENTE_PED, ' +
      '         P.DIRECCION1_CLIENTE_FISCAL_PED, ' +
      'P.DIRECCION2_CLIENTE_FISCAL_PED, ' +
      '         P.POBLACION_CLIENTE_FISCAL_PED, ' +
      'P.PROVINCIA_CLIENTE_FISCAL_PED, ' +
      '         P.CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
      '         P.CODIGO_PAI_CLIENTE_FISCAL_PED, ' +
      'P.NOMBRE_PAI_CLIENTE_FISCAL_PED, ' +
      '         P.NOMBRE_CLI_ENVIO_PED, P.MOVIL_CLIENTE_ENVIO_PED, ' +
      '         P.DIRECCION1_CLIENTE_ENVIO_PED, ' +
      'P.DIRECCION2_CLIENTE_ENVIO_PED, ' +
      '         P.POBLACION_CLIENTE_ENVIO_PED, P.PROVINCIA_CLIENTE_ENVIO_PED, '
        +
      '         P.CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
      '         P.CODIGO_PAI_CLIENTE_ENVIO_PED, ' +
      'P.NOMBRE_PAI_CLIENTE_ENVIO_PED, ' +
      '         P.TRANSPORTISTAPS_PED, P.CODIGO_IVA_PED, ' +
      '         P.ESIVA_RECARGO_CLIENTE_PED, P.ESIVA_EXENTO_CLIENTE_PED, ' +
      '         P.ESINTRACOMUNITARIO_CLIENTE_PED, ' +
      '         P.TARIFA_ARTICULO_CLIENTE_PED, ' +
      'P.ESIMP_INCL_TARIFA_CLIENTE_PED, ' +
      '         P.PORCENTAJE_IVAN_PED, P.PORCENTAJE_IVAR_PED, ' +
      '         P.PORCENTAJE_IVAS_PED, P.PORCENTAJE_IVAE_PED, ' +
      '         P.FORMA_PAGO_PED, ''0'', NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_pedidos P ' +
      '   WHERE P.NUMERO_PED = p_NUMERO_PED AND P.SERIE_PED = p_SERIE_PED; ' +
      '  SET p_NUMERO_ALB = v_numero; ' +
      '  SET p_SERIE_ALB  = v_serie; ' +
      'END');

    // PRC_PED_CREAR_ALBARAN_LINEA
    Run('DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_LINEA');
    Run(
      'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_LINEA(' +
      '  IN  p_NUMERO_ALB    varchar(20),' +
      '  IN  p_SERIE_ALB     varchar(20),' +
      '  IN  p_NUMERO_PED    varchar(20),' +
      '  IN  p_SERIE_PED     varchar(20),' +
      '  IN  p_LINEA_PED     varchar(4),' +
      '  IN  p_CANTIDAD      decimal(19,6),' +
      '  IN  p_USUARIO       varchar(100)' +
      ') PRC: BEGIN ' +
      '  DECLARE v_linea     varchar(4); ' +
      '  DECLARE v_pendiente decimal(19,6); ' +
      '  DECLARE v_cantidad  decimal(19,6); ' +
      '  SELECT (CANTIDAD_PEDLIN - IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0)) ' +
      '    INTO v_pendiente FROM fza_pedidos_lineas ' +
      '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
      '     AND SERIE_PED_PEDLIN  = p_SERIE_PED ' +
      '     AND LINEA_PEDLIN      = p_LINEA_PED; ' +
      '  IF v_pendiente IS NULL OR v_pendiente <= 0 THEN ' +
      '    LEAVE PRC; ' +
      '  END IF; ' +
      '  IF p_CANTIDAD > v_pendiente THEN ' +
      '    SET v_cantidad = v_pendiente; ' +
      '  ELSE ' +
      '    SET v_cantidad = p_CANTIDAD; ' +
      '  END IF; ' +
      '  SELECT LPAD(IFNULL(MAX(CAST(LINEA_ALBLIN AS UNSIGNED)), 0) + 10, 4, ' +
      '''0'') ' +
      '    INTO v_linea FROM fza_albaranes_lineas ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB; ' +
      '  INSERT INTO fza_albaranes_lineas ( ' +
      '    NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, ' +
      '    NUMERO_PED_ALBLIN, SERIE_PED_ALBLIN, LINEA_PED_ALBLIN, ' +
      '    CODIGO_ART_ALBLIN, CODIGO_FAM_ALBLIN, NOMBRE_FAM_ALBLIN, ' +
      '    DESCRIPCION_ARTICULO_ALBLIN, TIPO_CANTIDAD_ARTICULO_ALBLIN, ' +
      '    CANTIDAD_ALBLIN, CODIGO_TAR_ALBLIN, ESIMP_INCL_TARIFA_ALBLIN, ' +
      '    TIPO_IVA_ARTICULO_ALBLIN, PORCENTAJE_IVA_ALBLIN, ' +
      '    PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
      '    PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, ' +
      '    TOTAL_ALBLIN, CODIGO_ALMACEN_ALBLIN, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT p_NUMERO_ALB, p_SERIE_ALB, v_linea, ' +
      '         p_NUMERO_PED, p_SERIE_PED, p_LINEA_PED, ' +
      '         PL.CODIGO_ART_PEDLIN, PL.CODIGO_FAM_PEDLIN, ' +
      'PL.NOMBRE_FAM_PEDLIN, ' +
      '         PL.DESCRIPCION_ARTICULO_PEDLIN, ' +
      'PL.TIPO_CANTIDAD_ARTICULO_PEDLIN, ' +
      '         v_cantidad, PL.CODIGO_TAR_PEDLIN, PL.ESIMP_INCL_TARIFA_PEDLIN, '
        +
      '         PL.TIPO_IVA_ARTICULO_PEDLIN, PL.PORCENTAJE_IVA_PEDLIN, ' +
      '         PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
      '         PL.PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
      '         (v_cantidad * PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN), ' +
      '         PL.CODIGO_ALMACEN_PEDLIN, ' +
      '         NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_pedidos_lineas PL ' +
      '   WHERE PL.NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
      '     AND PL.SERIE_PED_PEDLIN  = p_SERIE_PED ' +
      '     AND PL.LINEA_PEDLIN      = p_LINEA_PED; ' +
      '  UPDATE fza_pedidos_lineas ' +
      '     SET CANTIDAD_ENTREGADA_PEDLIN = ' +
      'IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad, ' +
      '         CANTIDAD_PENDIENTE_PEDLIN = CANTIDAD_PEDLIN - ' +
      '(IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad), ' +
      '         ESENTREGADA_PEDLIN        = CASE WHEN CANTIDAD_PEDLIN <= ' +
      'IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0) + v_cantidad ' +
      '                                          THEN ''S'' ELSE ''N'' END, ' +
      '         INSTANTE_MODIF            = NOW(), ' +
      '         USUARIO_MODIF             = p_USUARIO ' +
      '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
      '     AND SERIE_PED_PEDLIN  = p_SERIE_PED ' +
      '     AND LINEA_PEDLIN      = p_LINEA_PED; ' +
      'END');

    // PRC_PED_CREAR_ALBARAN_FIN
    Run('DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_FIN');
    Run(
      'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_FIN(' +
      '  IN p_NUMERO_ALB varchar(20),' +
      '  IN p_SERIE_ALB  varchar(20),' +
      '  IN p_NUMERO_PED varchar(20),' +
      '  IN p_SERIE_PED  varchar(20),' +
      '  IN p_USUARIO    varchar(100)' +
      ') BEGIN ' +
      '  DECLARE v_total_base decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_total_iva  decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_pendientes int DEFAULT 0; ' +
      '  SELECT IFNULL(SUM(CANTIDAD_ALBLIN * ' +
      'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN), 0), ' +
      '         IFNULL(SUM(CANTIDAD_ALBLIN * ' +
      '(PRECIO_VENTA_CIVA_ARTICULO_ALBLIN - ' +
      'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN)), 0) ' +
      '    INTO v_total_base, v_total_iva ' +
      '    FROM fza_albaranes_lineas ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB; ' +
      '  UPDATE fza_albaranes ' +
      '     SET TOTAL_BASES_ALB     = v_total_base, ' +
      '         TOTAL_IMPUESTOS_ALB = v_total_iva, ' +
      '         TOTAL_LIQUIDO_ALB   = v_total_base + v_total_iva, ' +
      '         INSTANTE_MODIF      = NOW(), ' +
      '         USUARIO_MODIF       = p_USUARIO ' +
      '   WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '  SELECT COUNT(*) INTO v_pendientes ' +
      '    FROM fza_pedidos_lineas ' +
      '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
      '     AND SERIE_PED_PEDLIN  = p_SERIE_PED ' +
      '     AND IFNULL(ESENTREGADA_PEDLIN, ''N'') <> ''S''; ' +
      '  IF v_pendientes = 0 THEN ' +
      '    UPDATE fza_pedidos SET ESTADO_PED = ''ENTREGADO'', ' +
      '           INSTANTE_MODIF = NOW(), USUARIO_MODIF = p_USUARIO ' +
      '     WHERE NUMERO_PED = p_NUMERO_PED AND SERIE_PED = p_SERIE_PED; ' +
      '  ELSE ' +
      '    UPDATE fza_pedidos SET ESTADO_PED = ''PARCIAL'', ' +
      '           INSTANTE_MODIF = NOW(), USUARIO_MODIF = p_USUARIO ' +
      '     WHERE NUMERO_PED = p_NUMERO_PED AND SERIE_PED = p_SERIE_PED; ' +
      '  END IF; ' +
      'END');
}
    FProcsInstalados := True;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                            aLineas: TList<TPair<string,
                                            Currency>>): Boolean;
var
  i: Integer;
  sNumeroPed, sSeriePed: string;
  par: TPair<string, Currency>;
begin
  Result := False;
  sNumeroAlb := ''; sSerieAlb := '';
  if (aLineas = nil) or (aLineas.Count = 0) then Exit;

  // Asegura que los procedimientos existen (idempotente y barato).
  InstalarProcedimientos;

  sNumeroPed := unqryTablaG.FieldByName('NUMERO_PED').AsString;
  sSeriePed  := unqryTablaG.FieldByName('SERIE_PED').AsString;

  // 1) Cabecera del albarán a partir del pedido
  with unstrdprcCrearAlbaranInicio do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_PED', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_PED',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptOutput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptOutput);
    ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
    ParamByName('p_SERIE_PED').AsString  := sSeriePed;
    ParamByName('p_USUARIO').AsString    := oUser;
    ExecProc;
    sNumeroAlb := ParamByName('p_NUMERO_ALB').AsString;
    sSerieAlb  := ParamByName('p_SERIE_ALB').AsString;
  end;

  // 2) Por cada línea con cantidad > 0 generamos línea de albarán
  for i := 0 to aLineas.Count - 1 do
  begin
    par := aLineas[i];
    if par.Value <= 0 then Continue;
    with unstrdprcCrearAlbaranLinea do
    begin
      Params.Clear;
      Params.CreateParam(ftString,    'p_NUMERO_ALB', ptInput);
      Params.CreateParam(ftString,    'p_SERIE_ALB',  ptInput);
      Params.CreateParam(ftString,    'p_NUMERO_PED', ptInput);
      Params.CreateParam(ftString,    'p_SERIE_PED',  ptInput);
      Params.CreateParam(ftString,    'p_LINEA_PED',  ptInput);
      Params.CreateParam(ftBCD,       'p_CANTIDAD',   ptInput);
      Params.CreateParam(ftString,    'p_USUARIO',    ptInput);
      ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
      ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
      ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
      ParamByName('p_SERIE_PED').AsString  := sSeriePed;
      ParamByName('p_LINEA_PED').AsString  := par.Key;
      ParamByName('p_CANTIDAD').AsCurrency := par.Value;
      ParamByName('p_USUARIO').AsString    := oUser;
      ExecProc;
    end;
  end;

  // 3) Recalcular totales del albarán y refrescar estado del pedido
  with unstrdprcCrearAlbaranFin do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_PED', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_PED',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
    ParamByName('p_SERIE_PED').AsString  := sSeriePed;
    ParamByName('p_USUARIO').AsString    := oUser;
    ExecProc;
  end;

  // 4) Refrescar las queries del pedido en pantalla
  unqryPedidosLineas.Close; unqryPedidosLineas.Open;
  unqryAlbaranes.Close;     unqryAlbaranes.Open;
  unqryTablaG.RefreshRecord;
  Result := True;
end;

function TdmPedidos.ExistePedidoPrestaShop(const sIdPS: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    q.SQL.Text := 'SELECT 1 FROM fza_pedidos WHERE IDPS_PED = :id LIMIT 1';
    q.ParamByName('id').AsString := sIdPS;
    q.Open;
    Result := q.RecordCount > 0;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.ImportarPedidoPrestaShop(aOrder: TOrder): Boolean;
var
  qIns: TUniQuery;
  qLin: TUniQuery;
  qMsg: TUniQuery;
  i: Integer;
  sNumero, sSerie: string;
  lp: TLineaPed;
  tm: TMensaje;
begin
  Result := False;
  if aOrder = nil then Exit;
  if ExistePedidoPrestaShop(aOrder.idPedido) then Exit;

  // Reservar número usando el procedimiento de contadores
  unqryTablaG.Insert;
  try
    unqryTablaG.FieldByName('SERIE_PED').AsString          := 'A1';
    unqryTablaG.FieldByName('FECHA_PED').AsDateTime        := Date;
    if unqryTablaG.FindField('ESTADO_PED') <> nil then
      unqryTablaG.FieldByName('ESTADO_PED').AsString       := 'IMPORTADO';
    unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString     := '0';
    unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString     := '0';
    GetCodigoAutoPedido;
    sNumero := unqryTablaG.FieldByName('NUMERO_PED').AsString;
    sSerie  := unqryTablaG.FieldByName('SERIE_PED').AsString;
    unqryTablaG.Cancel;
  except
    unqryTablaG.Cancel;
    raise;
  end;

  qIns := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  qMsg := TUniQuery.Create(nil);
  try
    qIns.Connection := inLibGlobalVar.oConn;
    qIns.SQL.Text :=
      'INSERT INTO fza_pedidos (NUMERO_PED, SERIE_PED, FECHA_PED, ESTADO_PED, '
        +
      ' IDPS_PED, FECHAPS_PED, REFERENCIAPS_PED, ' +
      ' FORMAPAGOPS_PED, TRANSPORTISTAPS_PED, ESTADOPEDIDOPS_PED, ' +
      ' EMAIL_CLIENTE_PED, NIF_CLIENTE_PED, ' +
      ' NOMBRE_CLI_ENVIO_PED, MOVIL_CLIENTE_ENVIO_PED, ' +
      ' DIRECCION1_CLIENTE_ENVIO_PED, DIRECCION2_CLIENTE_ENVIO_PED, ' +
      ' POBLACION_CLIENTE_ENVIO_PED, PROVINCIA_CLIENTE_ENVIO_PED, ' +
      ' CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
      ' RAZON_SOCIAL_CLIENTE_FISCAL_PED, MOVIL_CLIENTE_FISCAL_PED, ' +
      ' DIRECCION1_CLIENTE_FISCAL_PED, DIRECCION2_CLIENTE_FISCAL_PED, ' +
      ' POBLACION_CLIENTE_FISCAL_PED, PROVINCIA_CLIENTE_FISCAL_PED, ' +
      ' CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
      ' TOTAL_LIQUIDO_PED, TOTAL_PAGADOREALPS_PED, ' +
      ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:NUMERO, :SERIE, :FECHA, :ESTADO, ' +
      '        :IDPS, :FECHAPS, :REFPS, ' +
      '        :FORMAPAGO, :TRANSP, :ESTADOPS, ' +
      '        :EMAILCLI, :NIFCLI, ' +
      '        :NOMENV, :MOVENV, :DIR1ENV, :DIR2ENV, ' +
      '        :POBLENV, :PROVENV, :CPENV, ' +
      '        :RSFIS, :MOVFIS, :DIR1FIS, :DIR2FIS, ' +
      '        :POBLFIS, :PROVFIS, :CPFIS, ' +
      '        :TOTAL, :PAGADO, ' +
      '        NOW(), :USU, :USU)';
    qIns.ParamByName('NUMERO').AsString  := sNumero;
    qIns.ParamByName('SERIE').AsString   := sSerie;
    qIns.ParamByName('FECHA').AsDateTime := Date;
    qIns.ParamByName('ESTADO').AsString  := 'IMPORTADO';
    qIns.ParamByName('IDPS').AsString    := aOrder.idPedido;
    qIns.ParamByName('FECHAPS').AsString := aOrder.FechaCreacion;
    qIns.ParamByName('REFPS').AsString   := aOrder.ReferenciaCliente;
    qIns.ParamByName('FORMAPAGO').AsString := aOrder.FormaPago;
    qIns.ParamByName('TRANSP').AsString    := aOrder.Transportista;
    qIns.ParamByName('ESTADOPS').AsString  := aOrder.EstadoPedido;
    qIns.ParamByName('EMAILCLI').AsString  := aOrder.custMail;
    qIns.ParamByName('NIFCLI').AsString    := aOrder.DniDel;
    qIns.ParamByName('NOMENV').AsString    :=
      aOrder.FirstnameDel + ' ' + aOrder.LastNameDel;
    qIns.ParamByName('MOVENV').AsString    := aOrder.PhoneDel;
    qIns.ParamByName('DIR1ENV').AsString   := aOrder.Address1Del;
    qIns.ParamByName('DIR2ENV').AsString   := aOrder.Address2Del;
    qIns.ParamByName('POBLENV').AsString   := aOrder.CityDel;
    qIns.ParamByName('PROVENV').AsString   := aOrder.NameStateDel;
    qIns.ParamByName('CPENV').AsString     := aOrder.PostcodeDel;
    qIns.ParamByName('RSFIS').AsString     := aOrder.CompanyBil;
    qIns.ParamByName('MOVFIS').AsString    := aOrder.PhoneBil;
    qIns.ParamByName('DIR1FIS').AsString   := aOrder.Address1Bil;
    qIns.ParamByName('DIR2FIS').AsString   := aOrder.Address2Bil;
    qIns.ParamByName('POBLFIS').AsString   := aOrder.CityBil;
    qIns.ParamByName('PROVFIS').AsString   := aOrder.NameStateBil;
    qIns.ParamByName('CPFIS').AsString     := aOrder.PostcodeBil;
    qIns.ParamByName('TOTAL').AsCurrency   := aOrder.TotalPedCIVA;
    qIns.ParamByName('PAGADO').AsCurrency  := aOrder.TotalPagadoReal;
    qIns.ParamByName('USU').AsString       := oUser;
    qIns.Execute;

    // Líneas
    qLin.Connection := inLibGlobalVar.oConn;
    qLin.SQL.Text :=
      'INSERT INTO fza_pedidos_lineas (NUMERO_PED_PEDLIN, SERIE_PED_PEDLIN, ' +
      'LINEA_PEDLIN, ' +
      ' IDLINEAPS_PEDLIN, IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, ' +
      'IDATRIBPRODPS_PEDLIN, ' +
      ' CODBAR_ART_PEDLIN, DESCRIPCION_ARTICULO_PEDLIN, ' +
      ' CANTIDAD_PEDLIN, CANTIDAD_ENTREGADA_PEDLIN, ' +
      'CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
      ' PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
      'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, TOTAL_PEDLIN, ' +
      ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:NUMERO, :SERIE, :LIN, ' +
      '        :IDLPS, :IDPPS, :REFPROD, :IDATRIB, ' +
      '        :EAN13, :DESCR, ' +
      '        :CANT, 0, :CANT, ''N'', ' +
      '        :PSIVA, :PCIVA, :TOT, ' +
      '        NOW(), :USU, :USU)';
    for i := 0 to aOrder.LineasPedido.Count - 1 do
    begin
      lp := aOrder.LineasPedido[i];
      qLin.ParamByName('NUMERO').AsString  := sNumero;
      qLin.ParamByName('SERIE').AsString   := sSerie;
      qLin.ParamByName('LIN').AsString     := Format('%.4d', [(i + 1) * 10]);
      qLin.ParamByName('IDLPS').AsString   := lp.idLinea;
      qLin.ParamByName('IDPPS').AsString   := lp.idProducto;
      qLin.ParamByName('REFPROD').AsString := lp.sRefProd;
      qLin.ParamByName('IDATRIB').AsString := lp.sRefAtrib;
      qLin.ParamByName('EAN13').AsString   := lp.sCodEAN13;
      qLin.ParamByName('DESCR').AsString   := lp.sDescripcion;
      qLin.ParamByName('CANT').AsFloat     := StrToFloatDef(lp.sCantidad, 1);
      qLin.ParamByName('PSIVA').AsCurrency := lp.cPrecioSIVA;
      qLin.ParamByName('PCIVA').AsCurrency := lp.cPrecioCIVA;
      qLin.ParamByName('TOT').AsCurrency   :=
        lp.cPrecioCIVA * StrToFloatDef(lp.sCantidad, 1);
      qLin.ParamByName('USU').AsString     := oUser;
      qLin.Execute;
    end;

    // Mensajes (si hay)
    qMsg.Connection := inLibGlobalVar.oConn;
    qMsg.SQL.Text :=
      'INSERT INTO fza_pedidos_mensajes (IDPS_MENSAJES_PEDMSG, ' +
      'IDMENSAJEPS_PEDMSG, ' +
      ' IDEMPLEADOPS_PEDMSG, MENSAJEPS_PEDMSG, FECHAPS_PEDMSG, ' +
      ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:HILO, :IDM, :IDE, :MSG, :FECHA, NOW(), :USU, :USU)';
    for tm in aOrder.MensajesPedido.LMensajes do
    begin
      qMsg.ParamByName('HILO').AsString  :=
        aOrder.MensajesPedido.idCustomer_Threat;
      qMsg.ParamByName('IDM').AsString   := tm.idMensaje;
      qMsg.ParamByName('IDE').AsString   := tm.idEmpleado;
      qMsg.ParamByName('MSG').AsString   := tm.Texto;
      qMsg.ParamByName('FECHA').AsDateTime := tm.InstanteMsg;
      qMsg.ParamByName('USU').AsString   := oUser;
      try
        qMsg.Execute;
      except
        // Si el mensaje ya existe (hilo PK), saltar
      end;
    end;
    Result := True;
  finally
    FreeAndNil(qIns);
    FreeAndNil(qLin);
    FreeAndNil(qMsg);
  end;
end;

initialization
  ForceReferenceToClass(TdmPedidos);

end.
