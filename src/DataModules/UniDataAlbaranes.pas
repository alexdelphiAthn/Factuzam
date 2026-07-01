{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes.                                                 }
{    Queries de cabecera y líneas, generación de facturas y movimientos de     }
{    stock asociados.                                                          }
{******************************************************************************}
unit UniDataAlbaranes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal,
  frxClass, frxDBSet, frCoreClasses;

type
  TdmAlbaranes = class(TdmBase)
    unqryAlbaranesLineas: TUniQuery;
    dsAlbaranesLineas:    TDataSource;
    unqryEmpDataAlb:      TUniQuery;
    unqryCliDataAlb:      TUniQuery;
    unqryArtDataLinAlb:   TUniQuery;
    unqrySkusAlb:         TUniQuery;
    unqryFacturas:        TUniQuery;
    dsFacturas:           TDataSource;
    unqryMovimientosAlb:  TUniQuery;
    dsMovimientosAlb:     TDataSource;
    unqryFormasPago:      TUniQuery;
    dsFormasPago:         TDataSource;
    unstrdprcGetContadorAlbaran: TUniStoredProc;
    unstrdprcCrearFacturaInicio: TUniStoredProc;
    unstrdprcCrearFacturaLinea:  TUniStoredProc;
    unstrdprcCrearFacturaFin:    TUniStoredProc;
    unstrdprcInsertarMovAlb:     TUniStoredProc;
    fxdsPrintAlb:    TfrxDBDataset;
    fxdstPrintLinAlb:TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
  public
    procedure GetCodigoAutoAlbaran;
    procedure CalcularTotalesAlbaran;
    procedure CopiarEmpresaaAlbaran(DataSet: TDataSet);
    procedure CopiarClienteaAlbaran(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    procedure OpenTables;
    // Override: abre las queries detalle del Mto de Albaranes tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;

    // Procedimientos de facturación: instalación idempotente.
    procedure InstalarProcedimientos;

    // Genera factura del albarán cargado en pantalla con las líneas indicadas.
    // Si aLineas es nil, se facturan todas las líneas no facturadas del
    // albarán.
    function CrearFacturaDesdeAlbaran(out sNumeroFac, sSerieFac: string;
                                      aLineas: TList<string>): Boolean;

    // Procesa una lista de albaranes (formato 'SERIE|NUMERO') y genera
    // factura(s).
    // Si bAgruparPorCliente es True, agrupa los albaranes del mismo cliente
    // en una única factura. Devuelve número de facturas generadas.
    function FacturarAlbaranesLista(aListaAlbaranes: TStrings;
                                    bAgruparPorCliente: Boolean): Integer;

    // Genera los movimientos de salida de stock asociados a las líneas del
    // albarán cargado. Idempotente: salta líneas sin SKU y líneas que ya
    // tengan un movimiento registrado para el documento (TIPO_DOC_MOV='AV').
    // Devuelve el número de movimientos creados.
    function GenerarMovimientosSalida: Integer;
  private
    FProcsInstalados: Boolean;
    FCalculandoTotales: Boolean;
    procedure BorrarMovimientosSalida;
    procedure SincronizarMovimientosSalida;
  end;

implementation

uses
  inLibGlobalVar, inLibtb, inLibLog, System.Diagnostics,
  System.UITypes, Vcl.Dialogs, inLibArticulosValidador,
  inLibVentasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmAlbaranes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                 := inLibGlobalVar.oConn;
  unqryTablaG.KeyFields                  := 'NUMERO_ALB;SERIE_ALB';
  unqryTablaG.SQLDelete.Text             :=
    'DELETE FROM fza_albaranes ' + sLineBreak +
    'WHERE NUMERO_ALB = :Old_NUMERO_ALB ' + sLineBreak +
    '  AND SERIE_ALB = :Old_SERIE_ALB';
  unqryAlbaranesLineas.Connection        := inLibGlobalVar.oConn;
  unqryEmpDataAlb.Connection             := inLibGlobalVar.oConn;
  unqryCliDataAlb.Connection             := inLibGlobalVar.oConn;
  unqryArtDataLinAlb.Connection          := inLibGlobalVar.oConn;
  unqrySkusAlb.Connection                := inLibGlobalVar.oConn;
  unqryFacturas.Connection               := inLibGlobalVar.oConn;
  unqryMovimientosAlb.Connection         := inLibGlobalVar.oConn;
  unqryFormasPago.Connection             := inLibGlobalVar.oConn;
  unstrdprcGetContadorAlbaran.Connection := inLibGlobalVar.oConn;
  unstrdprcCrearFacturaInicio.Connection := inLibGlobalVar.oConn;
  unstrdprcCrearFacturaLinea.Connection  := inLibGlobalVar.oConn;
  unstrdprcCrearFacturaFin.Connection    := inLibGlobalVar.oConn;
  unstrdprcInsertarMovAlb.Connection     := inLibGlobalVar.oConn;
end;

procedure TdmAlbaranes.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesLineas) and unqryAlbaranesLineas.Active then
    unqryAlbaranesLineas.Close;
  if Assigned(unqryFacturas) and unqryFacturas.Active then
    unqryFacturas.Close;
  if Assigned(unqryMovimientosAlb) and unqryMovimientosAlb.Active then
    unqryMovimientosAlb.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  inherited;
end;

procedure TdmAlbaranes.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmAlbaranes.AbrirDetalles;
const
  TAG = 'Albaranes.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Antes de abrir queries aseguramos que el esquema y los procs están al día
  // (idempotente y barato): así las nuevas columnas de seguimiento de
  // facturación están disponibles para el data-binding del formulario.
  InstalarProcedimientos;
  AbrirConTiempo(unqryAlbaranesLineas, 'unqryAlbaranesLineas');
  AbrirConTiempo(unqryFacturas,        'unqryFacturas');
  AbrirConTiempo(unqryMovimientosAlb,  'unqryMovimientosAlb');
  AbrirConTiempo(unqryFormasPago,      'unqryFormasPago');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_ALB').AsString  := '0';
    if FindField('SERIE_ALB') <> nil then
      FieldByName('SERIE_ALB').AsString := 'A1';
    FieldByName('FECHA_ALB').AsDateTime := Date;
    if FindField('ESTADO_ALB') <> nil then
      FieldByName('ESTADO_ALB').AsString := 'ABIERTO';
    if FindField('ESCONSOLIDADO_ALB') <> nil then
      FieldByName('ESCONSOLIDADO_ALB').AsString := 'N';
    FieldByName('CODIGO_EMP_ALB').AsString := '0';
    FieldByName('CODIGO_CLI_ALB').AsString := '0';
  end;
end;

procedure TdmAlbaranes.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '') then
    GetCodigoAutoAlbaran;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'ALB');
  CalcularTotalesAlbaran;
end;

procedure TdmAlbaranes.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  SincronizarMovimientosSalida;
end;

procedure TdmAlbaranes.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sSerie: string;
  sNumero: string;
  iBloqueos: Integer;

  procedure AsignarDocumento;
  begin
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNumero;
  end;

begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_ALB').AsString;
  sNumero := DataSet.FieldByName('NUMERO_ALB').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes ' +
      ' WHERE SERIE_ALB  = :s ' +
      '   AND NUMERO_ALB = :n ' +
      '   AND (COALESCE(NUMERO_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(ESTADO_ALB, '''') = ''FACTURADO'')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_albaranes_lineas ' +
        ' WHERE SERIE_ALB_ALBLIN  = :s ' +
        '   AND NUMERO_ALB_ALBLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_ALBLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_ALBLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_ALBLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      MessageDlg('No se puede borrar el albaran: ya esta facturado. ' +
                 'Borra o deshaz primero la factura vinculada.',
                 mtWarning, [mbOk], 0);
      Abort;
    end;
    if MessageDlg(Format('¿Borrar el albaran %s / %s?' + sLineBreak +
                         'Se eliminaran sus lineas y se revertiran los ' +
                         'movimientos de stock.',
                         [sSerie, sNumero]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      Abort;
    end;
    q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    q.ParamByName('t').AsString := 'AV';
    AsignarDocumento;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_albaranes_lineas ' +
      ' WHERE SERIE_ALB_ALBLIN  = :s ' +
      '   AND NUMERO_ALB_ALBLIN = :n';
    AsignarDocumento;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesLineas do
  begin
    FieldByName('NUMERO_ALB_ALBLIN').AsString :=
                                  unqryTablaG.FieldByName(
                                    'NUMERO_ALB').AsString;
    FieldByName('SERIE_ALB_ALBLIN').AsString  :=
                                  unqryTablaG.FieldByName('SERIE_ALB').AsString;
    FieldByName('CANTIDAD_ALBLIN').AsFloat := 1;
    if FindField('ESFACTURADA_ALBLIN') <> nil then
      FieldByName('ESFACTURADA_ALBLIN').AsString := 'N';
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  with unqryAlbaranesLineas do
  begin
    // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
    NormalizarArticuloSkuEnDataSet(inLibGlobalVar.oConn,
      unqryAlbaranesLineas, 'CODIGO_ART_ALBLIN',
      'CODIGO_UNIDAD_ALBLIN');
    if (FindField('CANTIDAD_ALBLIN') <> nil) and
       (FindField('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN') <> nil) and
       (FindField('TOTAL_ALBLIN') <> nil) then
      PrepararLineaFiscalVenta(inLibGlobalVar.oConn, unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');

    // Si el usuario ha tecleado un SKU pero no el artículo, lo deducimos
    // consultando fza_articulos_skus.
    if (FindField('CODIGO_UNIDAD_ALBLIN') <> nil) and
       (FindField('CODIGO_ART_ALBLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlb.Close;
        unqrySkusAlb.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlb.Open;
        if not unqrySkusAlb.Eof then
          FieldByName('CODIGO_ART_ALBLIN').AsString :=
                                  unqrySkusAlb.FieldByName(
                                    'CODIGO_ART_SKU').AsString;
        unqrySkusAlb.Close;
      end;
    end;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaran;
  SincronizarMovimientosSalida;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaran;
  SincronizarMovimientosSalida;
end;

procedure TdmAlbaranes.GetCodigoAutoAlbaran;
begin
  with unstrdprcGetContadorAlbaran do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString    :=
      unqryTablaG.FieldByName('SERIE_ALB').AsString;
    ParamByName('ptipodoc').AsString  := 'AV';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
                                  unqryTablaG.FieldByName(
                                    'CODIGO_EMP_ALB').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_ALB').AsString :=
                                                  ParamByName('pcont').AsString;
  end;
end;

procedure TdmAlbaranes.CalcularTotalesAlbaran;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(unqryTablaG.Connection, unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'TOTAL_ALBLIN',
        'TIPO_IVA_ARTICULO_ALBLIN', 'PORCENTAJE_IVA_ALBLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TdmAlbaranes.BorrarMovimientosSalida;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    q.ParamByName('t').AsString := 'AV';
    q.ParamByName('s').AsString :=
      unqryTablaG.FieldByName('SERIE_ALB').AsString;
    q.ParamByName('n').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALB').AsString;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranes.SincronizarMovimientosSalida;
var
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
    begin
      BorrarMovimientosSalida;
      GenerarMovimientosSalida;
    end;
  end;
end;

function TdmAlbaranes.BuscarEmpresa(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
      q.ParamByName('empresa').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarEmpresaaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmAlbaranes.BuscarCliente(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_clientes ' +
                    ' WHERE CODIGO_CLI_CLI = :cliente';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarClienteaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmAlbaranes.CopiarEmpresaaAlbaran(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_EMP_ALB').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_ALB').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_ALB').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_ALB').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_ALB').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_ALB').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_ALB').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
  end;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.CopiarClienteaAlbaran(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_CLI_ALB').AsString          :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_ALB').AsString:=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_ALB').AsString         :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_ALB').AsString   :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_ALB').AsString   :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_ALB').AsString :=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_ALB').AsString :=
                            DataSet.FindField(
                              'ESINTRACOMUNITARIO_CLI').AsString;
    FindField('TARIFA_ARTICULO_CLIENTE_ALB').AsString :=
                            DataSet.FindField('TARIFA_ARTICULO_CLI').AsString;
  end;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.InstalarProcedimientos;
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

    // Columna de seguimiento de facturación a nivel de línea (idempotente).
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS ESFACTURADA_ALBLIN VARCHAR(1) DEFAULT ''N''');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS NUMERO_FAC_ALBLIN VARCHAR(20) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS SERIE_FAC_ALBLIN VARCHAR(20) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS LINEA_FAC_ALBLIN VARCHAR(4) DEFAULT NULL');

    // Columnas SKU / lote / caducidad / variación (mismo nombre lógico que en
    // fza_facturas_lineas, sólo cambia el sufijo); permiten propagar la
    // información hacia la factura.
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS CODIGO_UNIDAD_ALBLIN VARCHAR(50) DEFAULT ' +
        'NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS LOTE_ALBLIN VARCHAR(50) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS FECHA_CADUCIDAD_ALBLIN DATE DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS DESCRIPCION_VARIACION_ALBLIN VARCHAR(200) ' +
        'DEFAULT NULL');

    // PRC_ALB_CREAR_FACTURA_INICIO: cabecera factura clonando del primer
    // albarán.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_INICIO');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_INICIO(' +
      '  IN  p_NUMERO_ALB varchar(20),' +
      '  IN  p_SERIE_ALB  varchar(20),' +
      '  IN  p_USUARIO    varchar(100),' +
      '  OUT p_NUMERO_FAC varchar(20),' +
      '  OUT p_SERIE_FAC  varchar(20)' +
      ') BEGIN ' +
      '  DECLARE v_serie  varchar(20); ' +
      '  DECLARE v_numero varchar(20); ' +
      '  SELECT SERIE_ALB INTO v_serie FROM fza_albaranes ' +
      '   WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '  SELECT LPAD(IFNULL(MAX(CAST(NUMERO_FAC AS UNSIGNED)), 0) + 1, 6, ' +
      '''0'') ' +
      '    INTO v_numero FROM fza_facturas WHERE SERIE_FAC = v_serie; ' +
      '  INSERT INTO fza_facturas ( ' +
      '    NUMERO_FAC, SERIE_FAC, FECHA_FAC, FASE_FAC, TIPO_FAC, ' +
      '    CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
      '    MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, ' +
      '    DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC, ' +
      '    POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC, ' +
      '    CODIGO_PAI_EMPRESA_FAC, NOMBRE_PAI_EMPRESA_FAC, ' +
      '    CODIGO_POSTAL_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
      '    CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, ' +
      '    MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, ' +
      '    DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
      '    POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
      '    CODIGO_POSTAL_CLIENTE_FAC, ' +
      '    CODIGO_PAI_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
      '    CODIGO_IVA_FAC, ' +
      '    ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
      '    ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
      '    TARIFA_ARTICULO_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
      '    PORCENTAJE_IVAN_FAC, PORCENTAJE_IVAR_FAC, ' +
      '    PORCENTAJE_IVAS_FAC, PORCENTAJE_IVAE_FAC, ' +
      '    FORMA_PAGO_FAC, CONTADOR_LINEAS_FAC, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT v_numero, v_serie, CURRENT_DATE(), ''BORRADOR'', ''NORMAL'', ' +
      '         A.CODIGO_EMP_ALB, A.RAZON_SOCIAL_EMPRESA_ALB, ' +
      'A.NIF_EMPRESA_ALB, ' +
      '         A.MOVIL_EMPRESA_ALB, A.EMAIL_EMPRESA_ALB, ' +
      '         A.DIRECCION1_EMPRESA_ALB, A.DIRECCION2_EMPRESA_ALB, ' +
      '         A.POBLACION_EMPRESA_ALB, A.PROVINCIA_EMPRESA_ALB, ' +
      '         A.CODIGO_PAI_EMPRESA_ALB, A.NOMBRE_PAI_EMPRESA_ALB, ' +
      '         A.CODIGO_POSTAL_EMPRESA_ALB, A.GRUPO_ZONA_IVA_EMPRESA_ALB, ' +
      '         A.CODIGO_CLI_ALB, A.RAZON_SOCIAL_CLIENTE_ALB, ' +
      'A.NIF_CLIENTE_ALB, ' +
      '         A.MOVIL_CLIENTE_ALB, A.EMAIL_CLIENTE_ALB, ' +
      '         A.DIRECCION1_CLIENTE_ALB, A.DIRECCION2_CLIENTE_ALB, ' +
      '         A.POBLACION_CLIENTE_ALB, A.PROVINCIA_CLIENTE_ALB, ' +
      '         A.CODIGO_POSTAL_CLIENTE_ALB, ' +
      '         A.CODIGO_PAI_CLIENTE_ALB, A.NOMBRE_PAI_CLIENTE_ALB, ' +
      '         A.CODIGO_IVA_ALB, ' +
      '         A.ESIVA_RECARGO_CLIENTE_ALB, A.ESIVA_EXENTO_CLIENTE_ALB, ' +
      '         A.ESINTRACOMUNITARIO_CLIENTE_ALB, ' +
      '         A.TARIFA_ARTICULO_CLIENTE_ALB, ' +
      'A.ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
      '         A.PORCENTAJE_IVAN_ALB, A.PORCENTAJE_IVAR_ALB, ' +
      '         A.PORCENTAJE_IVAS_ALB, A.PORCENTAJE_IVAE_ALB, ' +
      '         A.FORMA_PAGO_ALB, ''0'', NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_albaranes A ' +
      '   WHERE A.NUMERO_ALB = p_NUMERO_ALB AND A.SERIE_ALB = p_SERIE_ALB; ' +
      '  SET p_NUMERO_FAC = v_numero; ' +
      '  SET p_SERIE_FAC  = v_serie; ' +
      'END');

    // PRC_ALB_CREAR_FACTURA_LINEA: copia una línea concreta a la factura.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_LINEA');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_LINEA(' +
      '  IN  p_NUMERO_FAC varchar(20),' +
      '  IN  p_SERIE_FAC  varchar(20),' +
      '  IN  p_NUMERO_ALB varchar(20),' +
      '  IN  p_SERIE_ALB  varchar(20),' +
      '  IN  p_LINEA_ALB  varchar(4),' +
      '  IN  p_USUARIO    varchar(100)' +
      ') PRC: BEGIN ' +
      '  DECLARE v_linea_fac varchar(4); ' +
      '  DECLARE v_facturada varchar(1); ' +
      '  SELECT IFNULL(ESFACTURADA_ALBLIN, ''N'') INTO v_facturada ' +
      '    FROM fza_albaranes_lineas ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND LINEA_ALBLIN      = p_LINEA_ALB; ' +
      '  IF v_facturada = ''S'' THEN ' +
      '    LEAVE PRC; ' +
      '  END IF; ' +
      '  SELECT LPAD(IFNULL(MAX(CAST(LINEA_FACLIN AS UNSIGNED)), 0) + 10, 4, ' +
      '''0'') ' +
      '    INTO v_linea_fac FROM fza_facturas_lineas ' +
      '   WHERE NUMERO_FAC_FACLIN = p_NUMERO_FAC ' +
      '     AND SERIE_FAC_FACLIN  = p_SERIE_FAC; ' +
      '  INSERT INTO fza_facturas_lineas ( ' +
      '    NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
      '    CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
      '    LOTE_FACLIN, FECHA_CADUCIDAD_FACLIN, ' +
      '    CODIGO_FAM_FACLIN, NOMBRE_FAM_FACLIN, ' +
      '    DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
      '    TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '    CANTIDAD_FACLIN, CODIGO_TAR_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
      '    TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
      '    PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '    PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '    TOTAL_FACLIN, CODIGO_ALM_FACLIN, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT p_NUMERO_FAC, p_SERIE_FAC, v_linea_fac, ' +
      '         AL.CODIGO_ART_ALBLIN, AL.CODIGO_UNIDAD_ALBLIN, ' +
      '         AL.LOTE_ALBLIN, AL.FECHA_CADUCIDAD_ALBLIN, ' +
      '         AL.CODIGO_FAM_ALBLIN, AL.NOMBRE_FAM_ALBLIN, ' +
      '         AL.DESCRIPCION_ARTICULO_ALBLIN, ' +
      'AL.DESCRIPCION_VARIACION_ALBLIN, ' +
      '         AL.TIPO_CANTIDAD_ARTICULO_ALBLIN, ' +
      '         AL.CANTIDAD_ALBLIN, AL.CODIGO_TAR_ALBLIN, ' +
      'AL.ESIMP_INCL_TARIFA_ALBLIN, ' +
      '         AL.TIPO_IVA_ARTICULO_ALBLIN, AL.PORCENTAJE_IVA_ALBLIN, ' +
      '         AL.PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
      '         AL.PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, ' +
      '         AL.TOTAL_ALBLIN, AL.CODIGO_ALMACEN_ALBLIN, ' +
      '         NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_albaranes_lineas AL ' +
      '   WHERE AL.NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND AL.SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND AL.LINEA_ALBLIN      = p_LINEA_ALB; ' +
      '  UPDATE fza_albaranes_lineas ' +
      '     SET ESFACTURADA_ALBLIN = ''S'', ' +
      '         NUMERO_FAC_ALBLIN  = p_NUMERO_FAC, ' +
      '         SERIE_FAC_ALBLIN   = p_SERIE_FAC, ' +
      '         LINEA_FAC_ALBLIN   = v_linea_fac, ' +
      '         INSTANTE_MODIF     = NOW(), ' +
      '         USUARIO_MODIF      = p_USUARIO ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND LINEA_ALBLIN      = p_LINEA_ALB; ' +
      'END');

    // PRC_ALB_CREAR_FACTURA_FIN: recalcula totales y marca albarán como
    // facturado
    // si todas sus líneas se han facturado.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_FIN');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_FIN(' +
      '  IN p_NUMERO_FAC varchar(20),' +
      '  IN p_SERIE_FAC  varchar(20),' +
      '  IN p_NUMERO_ALB varchar(20),' +
      '  IN p_SERIE_ALB  varchar(20),' +
      '  IN p_USUARIO    varchar(100)' +
      ') BEGIN ' +
      '  DECLARE v_total_base decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_total_iva  decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_pendientes int DEFAULT 0; ' +
      '  SELECT IFNULL(SUM(CANTIDAD_FACLIN * ' +
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN), 0), ' +
      '         IFNULL(SUM(CANTIDAD_FACLIN * ' +
      '(PRECIO_VENTA_CIVA_ARTICULO_FACLIN - ' +
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN)), 0) ' +
      '    INTO v_total_base, v_total_iva ' +
      '    FROM fza_facturas_lineas ' +
      '   WHERE NUMERO_FAC_FACLIN = p_NUMERO_FAC ' +
      '     AND SERIE_FAC_FACLIN  = p_SERIE_FAC; ' +
      '  UPDATE fza_facturas ' +
      '     SET TOTAL_BASES_FAC     = v_total_base, ' +
      '         TOTAL_IMPUESTOS_FAC = v_total_iva, ' +
      '         TOTAL_LIQUIDO_FAC   = v_total_base + v_total_iva, ' +
      '         INSTANTE_MODIF      = NOW(), ' +
      '         USUARIO_MODIF       = p_USUARIO ' +
      '   WHERE NUMERO_FAC = p_NUMERO_FAC AND SERIE_FAC = p_SERIE_FAC; ' +
      '  IF p_NUMERO_ALB IS NOT NULL AND p_NUMERO_ALB <> '''' THEN ' +
      '    SELECT COUNT(*) INTO v_pendientes ' +
      '      FROM fza_albaranes_lineas ' +
      '     WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '       AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '       AND IFNULL(ESFACTURADA_ALBLIN, ''N'') <> ''S''; ' +
      '    IF v_pendientes = 0 THEN ' +
      '      UPDATE fza_albaranes ' +
      '         SET ESTADO_ALB    = ''FACTURADO'', ' +
      '             NUMERO_FAC_ALB = p_NUMERO_FAC, ' +
      '             SERIE_FAC_ALB  = p_SERIE_FAC, ' +
      '             INSTANTE_MODIF = NOW(), ' +
      '             USUARIO_MODIF  = p_USUARIO ' +
      '       WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '    ELSE ' +
      '      UPDATE fza_albaranes ' +
      '         SET ESTADO_ALB    = ''PARCIAL'', ' +
      '             INSTANTE_MODIF= NOW(), ' +
      '             USUARIO_MODIF = p_USUARIO ' +
      '       WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '    END IF; ' +
      '  END IF; ' +
      'END');

    FProcsInstalados := True;
  finally
    FreeAndNil(q);
  end;
end;

function TdmAlbaranes.CrearFacturaDesdeAlbaran(out sNumeroFac,
                                               sSerieFac: string;
                                               aLineas: TList<string>): Boolean;
var
  i: Integer;
  sNumeroAlb, sSerieAlb, sLinea: string;
  ds: TDataSet;
  bUsarTodas: Boolean;
begin
  sNumeroFac := '';
  sSerieFac  := '';
  InstalarProcedimientos;

  sNumeroAlb := unqryTablaG.FieldByName('NUMERO_ALB').AsString;
  sSerieAlb  := unqryTablaG.FieldByName('SERIE_ALB').AsString;
  bUsarTodas := (aLineas = nil) or (aLineas.Count = 0);

  // 1) Cabecera de la factura
  with unstrdprcCrearFacturaInicio do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_FAC', ptOutput);
    Params.CreateParam(ftString, 'p_SERIE_FAC',  ptOutput);
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_USUARIO').AsString    := oUser;
    ExecProc;
    sNumeroFac := ParamByName('p_NUMERO_FAC').AsString;
    sSerieFac  := ParamByName('p_SERIE_FAC').AsString;
  end;

  // 2) Líneas: las indicadas, o todas las pendientes si no se pasa lista.
  if bUsarTodas then
  begin
    ds := unqryAlbaranesLineas;
    ds.DisableControls;
    try
      ds.First;
      while not ds.Eof do
      begin
        if (ds.FindField('ESFACTURADA_ALBLIN') = nil) or
           (ds.FieldByName('ESFACTURADA_ALBLIN').AsString <> 'S') then
        begin
          with unstrdprcCrearFacturaLinea do
          begin
            Params.Clear;
            Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
            Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
            Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
            Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
            Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
            Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
            ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
            ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
            ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
            ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
            ParamByName('p_LINEA_ALB').AsString  :=
              ds.FieldByName('LINEA_ALBLIN').AsString;
            ParamByName('p_USUARIO').AsString    := oUser;
            ExecProc;
          end;
        end;
        ds.Next;
      end;
    finally
      ds.EnableControls;
    end;
  end
  else
  begin
    for i := 0 to aLineas.Count - 1 do
    begin
      sLinea := aLineas[i];
      if sLinea = '' then Continue;
      with unstrdprcCrearFacturaLinea do
      begin
        Params.Clear;
        Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
        Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
        ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
        ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
        ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
        ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
        ParamByName('p_LINEA_ALB').AsString  := sLinea;
        ParamByName('p_USUARIO').AsString    := oUser;
        ExecProc;
      end;
    end;
  end;

  // 3) Recalcular totales y estado del albarán.
  with unstrdprcCrearFacturaFin do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
    ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_USUARIO').AsString    := oUser;
    ExecProc;
  end;

  // 4) Refrescar la pantalla.
  unqryAlbaranesLineas.Close; unqryAlbaranesLineas.Open;
  if unqryFacturas.Active then
  begin
    unqryFacturas.Close;
    unqryFacturas.Open;
  end;
  unqryTablaG.RefreshRecord;
  Result := True;
end;

function TdmAlbaranes.FacturarAlbaranesLista(aListaAlbaranes: TStrings;
                                             bAgruparPorCliente: Boolean): Integer;
var
  i, iSep: Integer;
  sLin, sSer, sNum, sCliActual, sCliAlb: string;
  sNumFac, sSerFac, sNumFacActual, sSerFacActual: string;
  qCli: TUniQuery;
  qLin: TUniQuery;
begin
  Result := 0;
  if (aListaAlbaranes = nil) or (aListaAlbaranes.Count = 0) then Exit;
  InstalarProcedimientos;

  qCli := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  try
    qCli.Connection := inLibGlobalVar.oConn;
    qLin.Connection := inLibGlobalVar.oConn;
    qCli.SQL.Text :=
      'SELECT CODIGO_CLI_ALB FROM fza_albaranes ' +
      ' WHERE NUMERO_ALB = :pNUM AND SERIE_ALB = :pSER';
    qLin.SQL.Text :=
      'SELECT LINEA_ALBLIN FROM fza_albaranes_lineas ' +
      ' WHERE NUMERO_ALB_ALBLIN = :pNUM AND SERIE_ALB_ALBLIN = :pSER ' +
      '   AND IFNULL(ESFACTURADA_ALBLIN, ''N'') <> ''S'' ' +
      ' ORDER BY LINEA_ALBLIN';

    sCliActual    := '';
    sNumFacActual := '';
    sSerFacActual := '';

    for i := 0 to aListaAlbaranes.Count - 1 do
    begin
      sLin := aListaAlbaranes[i];
      iSep := Pos('|', sLin);
      if iSep <= 0 then Continue;
      sSer := Copy(sLin, 1, iSep - 1);
      sNum := Copy(sLin, iSep + 1, MaxInt);

      // Resolver cliente del albarán
      qCli.Close;
      qCli.ParamByName('pNUM').AsString := sNum;
      qCli.ParamByName('pSER').AsString := sSer;
      qCli.Open;
      if qCli.Eof then
      begin
        qCli.Close;
        Continue;
      end;
      sCliAlb := qCli.FieldByName('CODIGO_CLI_ALB').AsString;
      qCli.Close;

      // Decidir si reutilizar la factura previa o crear una nueva.
      if (not bAgruparPorCliente) or
         (sNumFacActual = '') or
         (sCliAlb <> sCliActual) then
      begin
        // Crear nueva cabecera
        with unstrdprcCrearFacturaInicio do
        begin
          Params.Clear;
          Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
          Params.CreateParam(ftString, 'p_NUMERO_FAC', ptOutput);
          Params.CreateParam(ftString, 'p_SERIE_FAC',  ptOutput);
          ParamByName('p_NUMERO_ALB').AsString := sNum;
          ParamByName('p_SERIE_ALB').AsString  := sSer;
          ParamByName('p_USUARIO').AsString    := oUser;
          ExecProc;
          sNumFac := ParamByName('p_NUMERO_FAC').AsString;
          sSerFac := ParamByName('p_SERIE_FAC').AsString;
        end;
        sNumFacActual := sNumFac;
        sSerFacActual := sSerFac;
        sCliActual    := sCliAlb;
        Inc(Result);
      end
      else
      begin
        sNumFac := sNumFacActual;
        sSerFac := sSerFacActual;
      end;

      // Volcar todas las líneas pendientes del albarán a la factura actual.
      qLin.Close;
      qLin.ParamByName('pNUM').AsString := sNum;
      qLin.ParamByName('pSER').AsString := sSer;
      qLin.Open;
      while not qLin.Eof do
      begin
        with unstrdprcCrearFacturaLinea do
        begin
          Params.Clear;
          Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
          Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
          ParamByName('p_NUMERO_FAC').AsString := sNumFac;
          ParamByName('p_SERIE_FAC').AsString  := sSerFac;
          ParamByName('p_NUMERO_ALB').AsString := sNum;
          ParamByName('p_SERIE_ALB').AsString  := sSer;
          ParamByName('p_LINEA_ALB').AsString  :=
            qLin.FieldByName('LINEA_ALBLIN').AsString;
          ParamByName('p_USUARIO').AsString    := oUser;
          ExecProc;
        end;
        qLin.Next;
      end;
      qLin.Close;

      // Cerrar el albarán: marcar como facturado si no quedan líneas
      // pendientes.
      with unstrdprcCrearFacturaFin do
      begin
        Params.Clear;
        Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
        Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
        ParamByName('p_NUMERO_FAC').AsString := sNumFac;
        ParamByName('p_SERIE_FAC').AsString  := sSerFac;
        ParamByName('p_NUMERO_ALB').AsString := sNum;
        ParamByName('p_SERIE_ALB').AsString  := sSer;
        ParamByName('p_USUARIO').AsString    := oUser;
        ExecProc;
      end;
    end;
  finally
    FreeAndNil(qCli);
    FreeAndNil(qLin);
  end;

  // Refrescar la pantalla del albarán activo.
  if unqryTablaG.Active then unqryTablaG.Refresh;
  if unqryAlbaranesLineas.Active then
  begin
    unqryAlbaranesLineas.Close;
    unqryAlbaranesLineas.Open;
  end;
  if unqryFacturas.Active then
  begin
    unqryFacturas.Close;
    unqryFacturas.Open;
  end;
end;

function TdmAlbaranes.GenerarMovimientosSalida: Integer;
var
  qLineas: TUniQuery;
  qExiste: TUniQuery;
  sNumeroAlb, sSerieAlb, sEmpresa, sCliente: string;
  sLinea, sSku, sAlmacen, sArticulo: string;
  fCantidad: Double;
begin
  Result := 0;
  if not unqryTablaG.Active then Exit;
  sNumeroAlb := unqryTablaG.FieldByName('NUMERO_ALB').AsString;
  sSerieAlb  := unqryTablaG.FieldByName('SERIE_ALB').AsString;
  if (sNumeroAlb = '') or (sNumeroAlb = '0') then Exit;
  sEmpresa := unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString;
  sCliente := unqryTablaG.FieldByName('CODIGO_CLI_ALB').AsString;

  qLineas := TUniQuery.Create(nil);
  qExiste := TUniQuery.Create(nil);
  try
    qLineas.Connection := unqryTablaG.Connection;
    qLineas.SQL.Text :=
      'SELECT LINEA_ALBLIN, CODIGO_UNIDAD_ALBLIN, CODIGO_ART_ALBLIN, ' +
      '       CANTIDAD_ALBLIN, CODIGO_ALMACEN_ALBLIN ' +
      '  FROM fza_albaranes_lineas ' +
      ' WHERE NUMERO_ALB_ALBLIN = :pNUM ' +
      '   AND SERIE_ALB_ALBLIN  = :pSER ' +
      ' ORDER BY LINEA_ALBLIN';
    qLineas.ParamByName('pNUM').AsString := sNumeroAlb;
    qLineas.ParamByName('pSER').AsString := sSerieAlb;
    qLineas.Open;

    qExiste.Connection := unqryTablaG.Connection;
    qExiste.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = ''AV'' ' +
      '   AND SERIE_DOC_MOV  = :pSER ' +
      '   AND NUMERO_DOC_MOV = :pNUM ' +
      '   AND LINEA_MOV      = :pLIN';

    qLineas.First;
    while not qLineas.Eof do
    begin
      sLinea    := qLineas.FieldByName('LINEA_ALBLIN').AsString;
      sSku      := Trim(qLineas.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
      sArticulo := qLineas.FieldByName('CODIGO_ART_ALBLIN').AsString;
      fCantidad := qLineas.FieldByName('CANTIDAD_ALBLIN').AsFloat;
      sAlmacen  := qLineas.FieldByName('CODIGO_ALMACEN_ALBLIN').AsString;

      if (sSku <> '') and (fCantidad > 0) then
      begin
        // ¿Ya hay movimiento para esta línea? Si es así, saltar.
        qExiste.Close;
        qExiste.ParamByName('pSER').AsString := sSerieAlb;
        qExiste.ParamByName('pNUM').AsString := sNumeroAlb;
        qExiste.ParamByName('pLIN').AsString := sLinea;
        qExiste.Open;
        if qExiste.FieldByName('N').AsInteger = 0 then
        begin
          with unstrdprcInsertarMovAlb do
          begin
            Connection := unqryTablaG.Connection;
            Params.Clear;
            Params.CreateParam(ftString, 'p_NUMERO_MOV',          ptInput);
            Params.CreateParam(ftString, 'p_TIPO_DOC_MOV',        ptInput);
            Params.CreateParam(ftString, 'p_SERIE_DOC_MOV',       ptInput);
            Params.CreateParam(ftString, 'p_NRO_DOC_MOV',         ptInput);
            Params.CreateParam(ftString, 'p_LINEA_MOV',           ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV',  ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV',  ptInput);
            Params.CreateParam(ftString,
                               'p_CODIGO_ALMACEN_CONTRA_MOV',
                               ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV',   ptInput);
            Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV', ptInput);
            Params.CreateParam(ftBCD,    'p_CANTIDAD_MOV',        ptInput);
            Params.CreateParam(ftBCD,    'p_PRECIO_MEDIO_MOV',    ptInput);
            Params.CreateParam(ftBCD,    'p_TOTAL_COSTE_MOV',     ptInput);
            Params.CreateParam(ftString, 'p_USUARIO',             ptInput);
            Params.CreateParam(ftString, 'p_ALMACEN_DOC',         ptInput);
            Params.CreateParam(ftString, 'p_NUMOP_DOC',           ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV', ptInput);
            Params.CreateParam(ftString, 'p_CODCLIENTE',          ptInput);
            Params.CreateParam(ftString, 'p_CODARTICULO',         ptInput);
            ParamByName('p_NUMERO_MOV').AsString          :=
                                            inLibtb.ObtenerSiguienteContador(
                                              'MV');
            ParamByName('p_TIPO_DOC_MOV').AsString        := 'AV';
            ParamByName('p_SERIE_DOC_MOV').AsString       := sSerieAlb;
            ParamByName('p_NRO_DOC_MOV').AsString         := sNumeroAlb;
            ParamByName('p_LINEA_MOV').AsString           := sLinea;
            ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sEmpresa;
            ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sAlmacen;
            ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
            ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sSku;
            ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := 'S';
            ParamByName('p_CANTIDAD_MOV').AsFloat         := fCantidad;
            ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := 0;
            ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := 0;
            ParamByName('p_USUARIO').AsString             := oUser;
            ParamByName('p_ALMACEN_DOC').AsString         := sAlmacen;
            ParamByName('p_NUMOP_DOC').AsString           := '';
            ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
            ParamByName('p_CODCLIENTE').AsString          := sCliente;
            ParamByName('p_CODARTICULO').AsString         := sArticulo;
            ExecProc;
          end;
          Inc(Result);
        end;
        qExiste.Close;
      end;
      qLineas.Next;
    end;
  finally
    FreeAndNil(qLineas);
    FreeAndNil(qExiste);
  end;

  // Refrescar el grid de movimientos si está abierto.
  if unqryMovimientosAlb.Active then
  begin
    unqryMovimientosAlb.Close;
    unqryMovimientosAlb.Open;
  end;
end;

end.
