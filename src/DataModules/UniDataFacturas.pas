{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de facturas.                                                  }
{    Cabeceras y líneas de fza_facturas, series, recibos, abonos y procesos de }
{    cálculo.                                                                  }
{******************************************************************************}
unit UniDataFacturas;

interface

uses
  SysUtils, Classes,  DB,
   inMtoPrincipal, DBClient, Provider, frxClass, frxDBSet, inLibUser,
   System.StrUtils, Windows, Dialogs, System.Variants, MemDS, DBAccess, Uni,
   UniDataGen, frCoreClasses;

type
  TdmFacturas = class(TdmBase)
    dsLinFac: TDataSource;
    dsFacPrint: TDataSource;
    dsLinFacPrint: TDataSource;
    dsSeries: TDataSource;
    fxdsPrintFac: TfrxDBDataset;
    fxdstPrintLinFac: TfrxDBDataset;
    unqryFacPrint: TUniQuery;
    unqryLinFacPrint: TUniQuery;
    unqrySeries: TUniQuery;
    unqryCliDataFac: TUniQuery;
    unqryArtDataLinFac: TUniQuery;
    unqryLinFac: TUniQuery;
    unstrdprcCrearFacturaAbono: TUniStoredProc;
    unstrdprcDuplicarFactura: TUniStoredProc;
    unstrdprcCrearCliente: TUniStoredProc;
    unstrdprcGetDataArticulo: TUniStoredProc;
    unstrdprcGetDataCliente: TUniStoredProc;
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
    dsRecibos: TDataSource;
    unqryRecibos: TUniQuery;
    dsRecibosPrint: TDataSource;
    fxdsRecibos: TfrxDBDataset;
    unqryRecibosPrint: TUniQuery;
    unstrdprcGetRecibos: TUniStoredProc;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    unqryEmpDataFac: TUniQuery;
    unstdCrearEmpresa: TUniStoredProc;
    dsTarifas: TDataSource;
    unqryTarifas: TUniQuery;
    unstdGetContadorLinea: TUniStoredProc;
    unstdCalcularFactura: TUniStoredProc;
    dsSeriesEditCombo: TDataSource;
    unqrySeriesEditCombo: TUniQuery;
    unstrdprcGetContadorFactura: TUniStoredProc;
    unqryIvasTipos: TUniQuery;
    dsIvasTipos: TDataSource;
    dsFactura: TDataSource;
    unstdCrearArticuloLin: TUniStoredProc;
    dsPaisesCli: TDataSource;
    unqryPaisesCli: TUniQuery;
    unqryPaisesEmp: TUniQuery;
    dsPaisesEmp: TDataSource;
    dsConsolidacion: TDataSource;
    unqryConsolidacion: TUniQuery;
    dsErrores: TDataSource;
    unqryErrores: TUniQuery;
    unqryMovimientosFac: TUniQuery;
    dsMovimientosFac:    TDataSource;
    unstrdprcInsertarMovFac: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryLinFacBeforeInsert(DataSet: TDataSet);
    procedure unqryFacBeforePost(DataSet: TDataSet);
    procedure unqryLinFacAfterPost(DataSet: TDataSet);
    procedure unqryFacAfterPost(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryLinFacAfterDelete(DataSet: TDataSet);
    procedure dsLinFacStateChange(Sender: TObject);
    procedure unqryLinFacBeforeEdit(DataSet: TDataSet);
private
    // Copia a los parámetros de la query los valores de los campos del
    // maestro (MasterSource) que se llamen igual. UniDAC solo rellena
    // los parámetros al hacer scroll del maestro con el detail ya
    // abierto; en la apertura perezosa (pestañas lazy) la query se abre
    // después de posicionar el maestro y se quedaba con parámetros NULL
    // (pestañas Verifactu y Movimientos vacías).
    procedure RellenarParamsDesdeMaestro(AQry: TUniQuery);
    // Helpers de validacion de coherencia en el BeforePost de la cabecera.
    function EsPaisUE(const ACodPais: string): Boolean;
    function ObtenerOperVfactu(const ACodigo: string; out AAmbito: string;
                               out ARepercute: Boolean): Boolean;
    function UltimaFechaSerie(const ASerie, AEmpresa,
                              ANumero: string): TDateTime;
    function HayHuecoNumeracion(const ASerie, AEmpresa,
                                ANumero: string): Boolean;
    procedure ValidarOperacionVfactu(var AIsError: Boolean);
public
    procedure GetCodigoAutoFactura;
    procedure GetCodigoAutoCliente;
    procedure GetCodigoAutoEmpresa;
    procedure CrearCliente;
    procedure CrearEmpresa;
    procedure CalcularRetencionesEmpresa;
    procedure CrearTablaSeries(sEmpresa, sCliente:string; dtFecha:TDateTime);
    procedure CopiarEmpresaaFactura(DataSet:TDataSet);
    procedure CopiarClienteaFactura(DataSet:TDataSet);
    procedure CopiarArticuloaLinea(DataSet:TDataSet);
    function FormaPagoDefault:String;
    function TarifaDefault:string;
    function BuscarCliente(s: string):Boolean;
    procedure AsignarIVA(s:string; unqryT:TUniQuery);
    function GetCodigoGrupoIVAAGricola:String;
    function GetUserEmpresaDef:String;
    procedure CalcularFactura;
    function GetTipoIVA(sTipoIVA:string):Currency;
    function ExisteSerieEmpresa(sSerie,
                                sEmpresa,
                                sTipoDoc:string): Boolean;
    function GetSubtipoSerieEmpresa(sSerie,
                                    sEmpresa:string;
                                    dtFecha:TDateTime): string;
    procedure OpenTables;
    // Override: abre las queries lookup + la query de la pestaña detail
    // por defecto (LineasFactura). Las queries de las pestañas Recibos,
    // Verifactu/Consolidacion, Registro/Errores y MovimientosFac son
    // lazy: solo se abren al activarse esa pestaña (ver
    // TfrmMtoFacturasBase.PcDetailChange).
    procedure AbrirDetalles; override;
    // Carga perezosa de sub-pestañas detail de la ficha de factura.
    procedure AsegurarRecibosAbierta;
    procedure AsegurarConsolidacionAbierta;
    procedure AsegurarErroresAbierta;
    procedure AsegurarMovimientosFacAbierta;

    // Genera movimientos de salida de stock para todas las líneas de la
    // factura cargada (sólo se llama automáticamente en facturas
    // simplificadas, pero se puede invocar manualmente). Idempotente: salta
    // líneas que ya tengan un movimiento registrado para el documento
    // (TIPO_DOC_MOV='FC' + serie/número/línea).
    function GenerarMovimientosSalidaFactura: Integer;
  end;
implementation

uses
  inMtoFacturasBase,
  inLibGlobalVar,
  inLibAppParam,
  inLibtb,
  inLibLog,
  System.Diagnostics,
  inLibFacturas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function  TdmFacturas.ExisteSerieEmpresa(sSerie,
                                         sEmpresa,
                                         sTipoDoc:string): Boolean;
var
  unqrySol:TUniQuery;
  sResul : String;
begin
  sResul := '';
  unqrySol := TUniQuery.Create(nil);
  with unqrySol do
  begin
    Connection := oConn;
    SQL.Text :=   'SELECT EMPRESA_CON ' +
                  '  FROM fza_contadores ' +
                  ' WHERE SERIE_CON = :Serie ' +
                  '   AND TIPO_DOC_CON = :TipoDoc ' +
                  '   AND EMPRESA_CON <> :Empresa ' +
                  '   AND EMPRESA_CON <> '+QuotedStr('-');
    ParamByName('Serie').AsString := sSerie;
    ParamByName('TipoDoc').AsString := sTipoDoc;
    ParamByName('Empresa').AsString := sEmpresa;
    Open;
    if RecordCount <> 0 then
    begin
      sResul := FieldByName('EMPRESA_CON').AsString;
      Result := (sResul = '') or (not(SameText(sResul, sEmpresa)));
    end
    else
      Result := False;
    Close;
    FreeAndNil(unqrySol);
  end;
end;
// Devuelve True si el pais (codigo numerico, p.ej. 724) es miembro de la UE
function TdmFacturas.EsPaisUE(const ACodPais: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if Trim(ACodPais) <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := oConn;
      q.SQL.Text := 'SELECT ESMIEMBRO_UE_PAI FROM fza_paises ' +
                    ' WHERE CODIGO_PAI_PAI = :pais';
      q.ParamByName('pais').AsString := Trim(ACodPais);
      q.Open;
      Result := (not q.IsEmpty) and
                SameText(Trim(q.FieldByName('ESMIEMBRO_UE_PAI').AsString), 'S');
      q.Close;
    finally
      FreeAndNil(q);
    end;
  end;
end;
// Lee del catalogo el ambito exigido y si la operacion repercute IVA.
// Devuelve True si el codigo existe en el catalogo.
function TdmFacturas.ObtenerOperVfactu(const ACodigo: string;
  out AAmbito: string; out ARepercute: Boolean): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  AAmbito := '';
  ARepercute := True;
  if Trim(ACodigo) <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := oConn;
      q.SQL.Text := 'SELECT AMBITO_VFO, ESREPERCUTE_IVA_VFO ' +
                    ' FROM fza_verifactu_operaciones WHERE CODIGO_VFO = :cod';
      q.ParamByName('cod').AsString := Trim(ACodigo);
      q.Open;
      if not q.IsEmpty then
      begin
        AAmbito    := Trim(q.FieldByName('AMBITO_VFO').AsString);
        ARepercute := not SameText(
          Trim(q.FieldByName('ESREPERCUTE_IVA_VFO').AsString), 'N');
        Result := True;
      end;
      q.Close;
    finally
      FreeAndNil(q);
    end;
  end;
end;
// Fecha de la ultima factura ya emitida (no borrador) de la misma serie y
// empresa, excluyendo la actual. 0 si no hay ninguna.
function TdmFacturas.UltimaFechaSerie(const ASerie, AEmpresa,
  ANumero: string): TDateTime;
var
  q: TUniQuery;
begin
  Result := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text := 'SELECT MAX(FECHA_FAC) AS ULTIMA FROM fza_facturas ' +
                  ' WHERE SERIE_FAC = :serie AND CODIGO_EMP_FAC = :emp ' +
                  '   AND NUMERO_FAC <> :num AND FECHA_FAC IS NOT NULL ' +
                  '   AND FASE_FAC <> ''BORRADOR''';
    q.ParamByName('serie').AsString := ASerie;
    q.ParamByName('emp').AsString   := AEmpresa;
    q.ParamByName('num').AsString   := ANumero;
    q.Open;
    if (not q.IsEmpty) and (not q.FieldByName('ULTIMA').IsNull) then
      Result := q.FieldByName('ULTIMA').AsDateTime;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;
// True si entre la ultima factura de la serie y la actual queda un hueco de
// numeracion (la ley exige numeracion correlativa, ese numero debe cubrirse).
function TdmFacturas.HayHuecoNumeracion(const ASerie, AEmpresa,
  ANumero: string): Boolean;
var
  q:         TUniQuery;
  iAsignado: Int64;
  iMax:      Int64;
begin
  Result := False;
  iAsignado := StrToInt64Def(Trim(ANumero), 0);
  if iAsignado > 1 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := oConn;
      q.SQL.Text := 'SELECT MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS MAXNUM ' +
                    ' FROM fza_facturas WHERE SERIE_FAC = :serie ' +
                    '   AND CODIGO_EMP_FAC = :emp ' +
                    '   AND CAST(NUMERO_FAC AS UNSIGNED) < :asig';
      q.ParamByName('serie').AsString  := ASerie;
      q.ParamByName('emp').AsString    := AEmpresa;
      q.ParamByName('asig').AsLargeInt := iAsignado;
      q.Open;
      if (not q.IsEmpty) and (not q.FieldByName('MAXNUM').IsNull) then
      begin
        iMax   := q.FieldByName('MAXNUM').AsLargeInt;
        Result := (iAsignado - iMax) > 1;
      end;
      q.Close;
    finally
      FreeAndNil(q);
    end;
  end;
end;
// Detecta incoherencias flagrantes entre el tipo de operacion Verifactu, el
// pais del cliente y el IVA de la factura. Si las hay, avisa y marca error.
procedure TdmFacturas.ValidarOperacionVfactu(var AIsError: Boolean);
var
  sTipo, sAmbito, sPais, sNif: string;
  bRepercute, bUE, bExtr:      Boolean;
  dCuota:                      Currency;
begin
  with unqryTablaG do
  begin
    sTipo  := Trim(FieldByName('TIPO_OPER_VFACTU_FAC').AsString);
    sPais  := Trim(FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString);
    sNif   := Trim(FieldByName('NIF_CLIENTE_FAC').AsString);
    dCuota := FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
    bUE    := EsPaisUE(sPais);
    bExtr  := (sPais <> '') and (sPais <> '724') and
              (not SameText(sPais, 'ES'));
    sAmbito    := '';
    bRepercute := True;
    if sTipo <> '' then
      ObtenerOperVfactu(sTipo, sAmbito, bRepercute);
    // Sin tipo y cliente fuera de la UE: el envio lo trata como exportacion
    // (sin IVA repercutido) de forma automatica.
    if (sTipo = '') and bExtr and (not bUE) then
      bRepercute := False;
    if (not AIsError) and SameText(sAmbito, 'UE') and (not bUE) then
    begin
      ShowMessage('La operacion "' + sTipo + '" es intracomunitaria, pero el ' +
        'cliente no es de la UE (pais ' + sPais + '). Corrija el tipo de ' +
        'operacion o el pais del cliente.');
      AIsError := True;
    end;
    if (not AIsError) and SameText(sAmbito, 'EXTRA_UE') and
       (bUE or (not bExtr)) then
    begin
      ShowMessage('La operacion "' + sTipo + '" es exportacion fuera de la ' +
        'UE, pero el cliente es comunitario o nacional. Corrija el tipo o el ' +
        'pais del cliente.');
      AIsError := True;
    end;
    if (not AIsError) and (not bRepercute) and (Abs(dCuota) > 0.01) then
    begin
      ShowMessage('La operacion no repercute IVA (intracomunitaria, ISP o ' +
        'exportacion), pero la factura tiene IVA (' +
        FormatFloat('#,##0.00', dCuota) + '). Revise el IVA o el tipo de ' +
        'operacion.');
      AIsError := True;
    end;
    if (not AIsError) and bExtr and (sNif = '') then
    begin
      ShowMessage('El cliente es extranjero (pais ' + sPais + ') y Verifactu ' +
        'exige su NIF-IVA. Indique el NIF del cliente.');
      AIsError := True;
    end;
  end;
end;

function TdmFacturas.GetSubtipoSerieEmpresa(sSerie,
                                            sEmpresa:string;
                                            dtFecha:TDateTime): string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  if ((sSerie = '') or (sEmpresa = '')) then
    Exit;
  unqrySol := TUniQuery.Create(nil);
  try
    with unqrySol do
    begin
      Connection := inLibGlobalVar.oConn;
      SQL.Text := 'SELECT SUBTIPO_EMPSER ' +
                  '  FROM fza_empresas_series ' +
                  ' WHERE EMPSER = :Serie ' +
                  '   AND CODIGO_EMP_EMPSER = :Empresa ' +
                  '   AND (FECHA_DESDE_EMPSER <= :Fecha ' +
                  '        AND (FECHA_HASTA_EMPSER >= :Fecha ' +
                  '             OR FECHA_HASTA_EMPSER IS NULL)) ';
      ParamByName('Serie').AsString := sSerie;
      ParamByName('Empresa').AsString := sEmpresa;
      ParamByName('Fecha').AsDateTime := dtFecha;
      Open;
      if (RecordCount <> 0) then
        Result := FieldByName('SUBTIPO_EMPSER').AsString;
      Close;
    end;
  finally
    FreeAndNil(unqrySol);
  end;
end;

function TdmFacturas.GetUserEmpresaDef:String;
var
  unqrySol:TUniQuery;
  sResul : String;
begin
  sResul := '';
  if ( ((unqryTablaG.State = dsEdit) or
        (unqryTablaG.State = dsInsert))
     ) then
  begin
    unqrySol := TUniQuery.Create(Self);
    with unqrySol do
    begin
      Connection := oConn;
      SQL.Text := 'SELECT EMPRESA_DEFECTO_USU ' +
                  '  FROM fza_usuarios ' +
                  ' WHERE USUARIO_USU = :Usuario ';
      ParamByName('Usuario').AsString := oUser;
      Open;
      if RecordCount <> 0 then
      begin
        sResul := FieldByName('EMPRESA_DEFECTO_USU').AsString;
      end;
      Close;
      FreeAndNil(unqrySol);
    end;
  end;
  Result := sResul;
end;

procedure TdmFacturas.CrearTablaSeries(sEmpresa,
                                       sCliente:string;
                                       dtFecha:TDateTime);
begin
  with unqrySeriesEditCombo do
  begin
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'SELECT SERIE_CON_CLI AS SERIE_CON ' +
                '  FROM vi_clientes                              ' +
                ' WHERE (SERIE_CON_CLI IS NOT NULL      ' +
                '        AND SERIE_CON_CLI <> '''')     ' +
                '   AND CODIGO_CLI_CLI = :CLIENTE                ' +
                ' UNION                                          ' +
                'SELECT EMPSER AS SERIE_CON            ' +
                '  FROM vi_empresas_series                       ' +
                ' WHERE CODIGO_EMP_EMPSER = :EMPRESA          ' +
                '   AND (FECHA_DESDE_EMPSER <= :FECHA             ' +
                '        AND (FECHA_HASTA_EMPSER >= :FECHA        ' +
                '             OR FECHA_HASTA_EMPSER IS NULL ))    ' +
                ' UNION                                          ' +
                'SELECT SERIE_CON AS SERIE_CON         ' +
                '  FROM vi_contadores                            ' +
                ' WHERE ESACTIVO_CON = ''S''                  ' +
                '   AND EMPRESA_CON = :EMPRESA              ';
    Prepare;
    Params.ParamByName('EMPRESA').AsSTring := sEmpresa;
    Params.ParamByName('FECHA').AsDateTime := dtFecha;
    Params.ParamByName('CLIENTE').AsString := sCliente;
    if unqrySeriesEditCombo.Active then
      unqrySeriesEditCombo.Close;
    unqrySeriesEditCombo.Open;
  end;
end;

procedure TdmFacturas.AsignarIVA(s:string; unqryT:TUniQuery);
var
  unqrySol:TUniQuery;
begin
  if ( (s <> '') ) then
  begin
    unqrySol := TUniQuery.Create(Self);
    with unqrySol do
    begin
      Connection := inLibGlobalVar.oConn;
      SQL.Text :=  'SELECT *  ' +
                   '  FROM vi_ivas ' +
                   ' WHERE IVA_IVAGRP = :grupo ' +
                   '   AND FECHA_DESDE_IVA <= :fecha_ini ' +
                   '   AND (    FECHA_HASTA_IVA >= :fecha_fin ' +
                   '         OR FECHA_HASTA_IVA IS NULL)';
      ParamByName('grupo').AsString := s;
      ParamByName('fecha_ini').AsDateTime :=
                              unqryT.FieldByName('FECHA_FAC').AsDateTime;
      ParamByName('fecha_fin').AsDateTime :=
                              unqryT.FieldByName('FECHA_FAC').AsDateTime;
      Open;
      if (unqrySol.RecordCount > 0) then
      begin
         unqryT.FindField('PORCENTAJE_IVAN_FAC').AsString :=
                              FieldByName('PORCENTAJE_NORMAL_IVA').AsString;
         unqryT.FindField('PORCENTAJE_REN_FAC').AsString :=
                              FieldByName('PORCENTAJE_NORMAL_RE_IVA').AsString;
         unqryT.FindField('PORCENTAJE_IVAR_FAC').AsString :=
                              FieldByName('PORCENTAJE_REDUCIDO_IVA').AsString;
         unqryT.FindField('PORCENTAJE_RER_FAC').AsString :=
                              FieldByName(
                                'PORCENTAJE_REDUCIDO_RE_IVA').AsString;
         unqryT.FindField('PORCENTAJE_IVAS_FAC').AsString :=
                              FieldByName(
                                'PORCENTAJE_SUPERREDUCIDO_IVA').AsString;
         unqryT.FindField('PORCENTAJE_RES_FAC').AsString :=
                             FieldByName(
                               'PORCENTAJE_SUPERREDUCIDO_RE_IVA').AsString;
         unqryT.FindField('PORCENTAJE_IVAE_FAC').AsString :=
                              FieldByName('PORCENTAJE_EXENTO_IVA').AsString;
         unqryT.FindField('PORCENTAJE_REE_FAC').AsString :=
                              FieldByName('PORCENTAJE_EXENTO_RE_IVA').AsString;
         unqryT.FindField('ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString :=
                              FieldByName(
                                'ESIRPF_IMP_INCL_IVA_IVAGRP').AsString;
         unqryT.FindField('ESAPLICA_RE_ZONA_IVA_FAC').AsString :=
                              FieldByName('ESAPLICA_RE_IVA_IVAGRP').AsString;
         unqryT.FindField('CODIGO_IVA_FAC').AsString :=
                              FieldByName('CODIGO_IVA').AsString;
         unqryT.FindField('ESIVAAGRICOLA_ZONA_IVA_FAC').AsString :=
                              FieldByName('ESIVAAGRICOLA_IVA_IVAGRP').AsString;
         unqryT.FindField('PALABRA_REPORTS_ZONA_IVA_FAC').AsString :=
                              FieldByName(
                                'PALABRA_REPORTS_IVA_IVAGRP').AsString;
         Close;
         FreeAndNil(unqrySol);
      end;
    end;
  end;
end;

function TdmFacturas.BuscarCliente(s: string):Boolean;
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  unqrySol.Connection := inLibGlobalVar.oConn;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM fza_clientes ' +
                       ' WHERE CODIGO_CLI_CLI = :cliente';
  unqrySol.ParamByName('cliente').AsString := s;
  unqrySol.Open;
  if unqrySol.RecordCount = 0 then
  begin
    Result := False;
  end
  else
  begin
    CopiarClienteaFactura(unqrySol);
    Result := True;
  end;
  unqrySol.Close;
  FreeAndNil(unqrySol);
end;


procedure TdmFacturas.CalcularFactura;
var
  facTotales: TFacturaTotales;
begin
  // Usar TFacturaTotales en lugar del procedimiento almacenado
  if Assigned(unqryTablaG) and unqryTablaG.Active and
     Assigned(unqryLinFac) and unqryLinFac.Active then
  begin
    try
      facTotales := TFacturaTotales.Create(unqryTablaG, unqryLinFac);
      try
        if facTotales.ProcesarFacturaCompleta then
        begin
          // Refrescar para ver los cambios
//          if unqryTablaG.Active and (unqryTablaG.State <> dsInsert) then
//            unqryTablaG.RefreshRecord;
        end
        else
        begin
          // Si hay error, mostrar mensaje
          if facTotales.MensajeError <> '' then
            ShowMessage(
              'Error al calcular factura: ' + facTotales.MensajeError);
        end;
      finally
        FreeAndNil(facTotales);
      end;
    except
      on E: Exception do
        ShowMessage('Error en cálculo de factura: ' + E.Message);
    end;
  end;
end;

procedure TdmFacturas.CalcularRetencionesEmpresa;
var
  unqrySol:TUniQuery;
begin
  with unqryTablaG do
  begin
    unqrySol := TUniQuery.Create(Self);
    unqrySol.Connection := inLibGlobalVar.oConn;
    unqrySol.SQL.Text := 'SELECT * '+
                         '  FROM fza_empresas_retenciones ' +
                         ' WHERE CODIGO_EMP_EMPRET = :empresa ' +
                         '   AND FECHA_DESDE_EMPRET <= :fecha ' +
                         '   AND (    FECHA_HASTA_EMPRET >= :fecha ' +
                         '         OR FECHA_HASTA_EMPRET IS NULL)' +
                         ' LIMIT 1';
    unqrySol.ParamByName('empresa').AsString :=
                                   FindField('CODIGO_EMP_FAC').AsString;
    unqrySol.ParamByName('fecha').AsDateTime :=
                                        FieldByName('FECHA_FAC').AsDateTime;
    unqrySol.Open;
    if (unqrySol.RecordCount = 0) then
      Sleep(0)
    else
      if (FindField('PORCENTAJE_RETENCION_FAC').AsFloat = 0) then
        FindField('PORCENTAJE_RETENCION_FAC').AsFloat :=
                        unqrySol.FindField('PORCENTAJE_EMPRET').AsFloat;
    unqrySol.Close;
    FreeAndNil(unqrySol);
  end;
end;

procedure TdmFacturas.CopiarArticuloaLinea(DataSet: TDataSet);
var
  sPpTipoIVA:string;
  fPorcen:Currency;
  iPorcen:Integer;
  oLinFac:TLinFac;
  facTotales : TFacturaTotales;
begin
  with dsLinFac.Dataset do
  begin
     if ( (State <> dsEdit) and
          (State <> dsInsert)
        ) then
       Edit;
     FindField('CODIGO_ART_FACLIN').AsString :=
                                  DataSet.FindField('CODIGO_ART_ART').AsString;
     FindField('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
                           DataSet.FindField('TIPO_CANTIDAD_ART').AsString;
     FindField('DESCRIPCION_ARTICULO_FACLIN').AsString :=
                             DataSet.FindField('DESCRIPCION_ART').AsString;
     FindField('TIPO_IVA_ARTICULO_FACLIN').AsString :=
                                 DataSet.FindField('TIPO_IVA_ART').AsString;
     sPpTipoIVA :=  DataSet.FindField('TIPO_IVA_ART').AsString;
     iPorcen := 0;
      case IndexStr(sPpTipoIVA, ['N', 'R', 'S', 'E']) of
         0: iPorcen := unqryTablaG.FindField('PORCENTAJE_IVAN_FAC').AsInteger;
         1: iPorcen := unqryTablaG.FindField('PORCENTAJE_IVAR_FAC').AsInteger;
         2: iPorcen := unqryTablaG.FindField('PORCENTAJE_IVAS_FAC').AsInteger;
         3: iPorcen := unqryTablaG.FindField('PORCENTAJE_IVAE_FAC').AsInteger;
      end;
     fPorcen := iPorcen / 100;
     FindField('CODIGO_TAR_FACLIN').AsString :=
              unqryTablaG.FindField('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
     FindField('ESIMP_INCL_TARIFA_FACLIN').AsString :=
            unqryTablaG.FindField('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
     FindField('CODIGO_FAM_FACLIN').AsString :=
                          DataSet.FindField('CODIGO_FAM_ART').AsString;
     FindField('NOMBRE_FAM_FACLIN').AsString :=
                              DataSet.FindField('DESCRIPCION_FAM').AsString;
     FindField('ESPROVEEDORPRINCIPAL_FACLIN').AsString :=
                             DataSet.FindField('ESPROVEEDORPRINCIPAL').AsString;
     FindField('CODIGO_PRV_FACLIN').AsString :=
                                 DataSet.FindField('CODIGO_PRV_PRV').AsString;
     FindField('RAZON_SOCIAL_PROVEEDOR_FACLIN').AsString :=
                           DataSet.FindField('RAZON_SOCIAL_PROVEEDOR').AsString;
     FindField('PRECIO_ULT_COMPRA_FACLIN').AsString :=
                                DataSet.FindField('PRECIO_ULT_COMPRA').AsString;
     FindField('PRECIO_SALIDA_FACLIN').AsString :=
                              DataSet.FindField(
                                'PRECIO_SALIDA_ARTTAR').AsString;
     FindField('PORCENTAJE_DTO_FACLIN').AsString :=
                                DataSet.FindField(
                                  'PORCENTAJE_DTO_ARTTAR').AsString;
     FindField('PRECIO_DTO_FACLIN').AsString :=
                                DataSet.FindField('PRECIO_DTO_ARTTAR').AsString;
     if  DataSet.FindField('ESIMP_INCL_TAR').AsString = 'S' then
     begin
       FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsString :=
                               DataSet.FindField(
                                 'PRECIO_FINAL_ARTTAR').AsString;
       FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsFloat :=
             (DataSet.FindField(
               'PRECIO_FINAL_ARTTAR').AsFloat / (1+ (fPorcen)));
     end
     else
     begin
       FindField('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsString :=
                               DataSet.FindField(
                                 'PRECIO_FINAL_ARTTAR').AsString;
       FindField('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat :=
              (DataSet.FindField(
                'PRECIO_FINAL_ARTTAR').AsFloat * (1 + fPorcen));
     end;
     // Cantidad por defecto = 1
     if FindField('CANTIDAD_FACLIN') <> nil then
       FindField('CANTIDAD_FACLIN').AsCurrency := 1;
  end;
end;

procedure TdmFacturas.CopiarClienteaFactura(DataSet:TDataSet);
begin
    with unqryTablaG do
  begin
    if ((State <> dsEdit) and (State <> dsInsert)) then
      Edit;
    FindField('CODIGO_CLI_FAC').AsString :=
                                   DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_FAC').AsString :=
                              DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_FAC').AsString :=
                                      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_FAC').AsString :=
                                    DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_FAC').AsString :=
                                    DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_FAC').AsString :=
                               DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_FAC').AsString :=
                               DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_FAC').AsString :=
                                DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_FAC').AsString :=
                                DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_FAC').AsString :=
                                  DataSet.FindField(
                                    'CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_FAC').AsString :=
                              DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_FAC').AsString :=
                              DataSet.FindField('CODIGO_PAI_CLI').AsString;

    FindField('ESIVA_RECARGO_CLIENTE_FAC').AsString :=
                            DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_FAC').AsString :=
                             DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString :=
                DataSet.FindField('ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_FAC').AsString :=
                            DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString :=
                       DataSet.FindField('ESINTRACOMUNITARIO_CLI').AsString;
    if ( DataSet.FindField('CODIGO_FP_CLI').AsString <> '' ) then
    begin
      FindField('FORMA_PAGO_FAC').AsString :=
                        DataSet.FindField('CODIGO_FP_CLI').AsString;
    end
    else
      FindField('FORMA_PAGO_FAC').AsString := FormapagoDefault;
    if (unqryTablaG.State = dsInsert) then
    begin
      if ( (DataSet.FieldByName('TARIFA_ARTICULO_CLI').AsString <> '') or
           (DataSet.FieldByName('TARIFA_ARTICULO_CLI').IsNull)
      ) then
      begin
        FindField('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
                        DataSet.FindField('TARIFA_ARTICULO_CLI').AsString;
      end
      else
        FindField('TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
      if (FindField('TARIFA_ARTICULO_CLIENTE_FAC').AsString <> '') then
      begin
        unqryTarifas.Locate('CODIGO_TAR_ARTTAR',
                  FindField('TARIFA_ARTICULO_CLIENTE_FAC').AsString, [] );
        FindField('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
                           unqryTarifas.FindField('ESIMP_INCL_TAR').ASString;
      end;
    end;
    if (FindField('ESRETENCIONES_CLIENTE_FAC').AsString <> 'S') then
      unqryTablaG.FindField('PORCENTAJE_RETENCION_FAC').AsFloat := 0;
    if (State = dsInsert) then
      (GetOwnerForm<TfrmMtoFacturasBase>).ActualizarComboSeries;
  end;
end;

procedure TdmFacturas.CopiarEmpresaaFactura(DataSet:TDataSet);
begin
  with unqryTablaG do
  begin
      if ((State <> dsEdit) and (State <> dsInsert)) then
        Edit;
      FindField('CODIGO_EMP_FAC').AsString :=
                                   Dataset.FindField('CODIGO_EMP_EMP').AsString;
      FindField('RAZON_SOCIAL_EMPRESA_FAC').AsString :=
                              DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
      FindField('NIF_EMPRESA_FAC').AsString :=
                                      DataSet.FindField('NIF_EMP').AsString;
      FindField('MOVIL_EMPRESA_FAC').AsString :=
                                    DataSet.FindField('MOVIL_EMP').AsString;
      FindField('EMAIL_EMPRESA_FAC').AsString :=
                                    DataSet.FindField('EMAIL_EMP').AsString;
      FindField('DIRECCION1_EMPRESA_FAC').AsString :=
                               DataSet.FindField('DIRECCION1_EMP').AsString;
      FindField('DIRECCION2_EMPRESA_FAC').AsString :=
                               DataSet.FindField('DIRECCION2_EMP').AsString;
      FindField('POBLACION_EMPRESA_FAC').AsString :=
                                DataSet.FindField('POBLACION_EMP').AsString;
      FindField('PROVINCIA_EMPRESA_FAC').AsString :=
                                DataSet.FindField('PROVINCIA_EMP').AsString;
      FindField('CODIGO_POSTAL_EMPRESA_FAC').AsString :=
                                  DataSet.FindField(
                                    'CODIGO_POSTAL_EMP').AsString;
      FindField('NOMBRE_PAI_EMPRESA_FAC').AsString :=
                              DataSet.FindField('NOMBRE_PAI_EMP').AsString;
      FindField('CODIGO_PAI_EMPRESA_FAC').AsString :=
                              DataSet.FindField('CODIGO_PAI_EMP').AsString;
      FindField('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString :=
                           DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
      FindField('ESRETENCIONES_EMPRESA_FAC').AsString :=
                            DataSet.FindField('ESRETENCIONES_EMP').AsString;
      FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString :=
                DataSet.FindField('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
      FindField('TEXTO_LEGAL_EMPRESA_FAC').AsString :=
                      DataSet.FindField('TEXTO_LEGAL_FACTURA_EMP').AsString;
      if (DataSet.FindField('ESRETENCIONES_EMP').AsString = 'S') then
      begin
        CalcularRetencionesEmpresa;
      end;
     if (State = dsInsert) then
       (GetOwnerForm<TfrmMtoFacturasBase>).ActualizarComboSeries;
   end;
end;

procedure TdmFacturas.CrearCliente;
begin
    with unstrdprcCrearCliente do
    begin
      ParamByName('pCODIGO_CLIENTE').AsString :=
                    unqryTablaG.FieldByName('CODIGO_CLI_FAC').AsString;
      ParamByName('pRAZONSOCIAL_CLIENTE').AsString :=
                unqryTablaG.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString;
      ParamByName('pNIF_CLIENTE').AsString :=
                        unqryTablaG.FieldByName('NIF_CLIENTE_FAC').AsString;
      ParamByName('pMOVIL_CLIENTE').AsString :=
                      unqryTablaG.FieldByName('MOVIL_CLIENTE_FAC').AsString;
      ParamByName('pEMAIL_CLIENTE').AsString :=
                      unqryTablaG.FieldByName('EMAIL_CLIENTE_FAC').AsString;
      ParamByName('pDIRECCION1_CLIENTE').AsString :=
                 unqryTablaG.FieldByName('DIRECCION1_CLIENTE_FAC').AsString;
      ParamByName('pDIRECCION2_CLIENTE').AsString :=
                 unqryTablaG.FieldByName('DIRECCION2_CLIENTE_FAC').AsString;
      ParamByName('pPOBLACION_CLIENTE').AsString :=
                  unqryTablaG.FieldByName('POBLACION_CLIENTE_FAC').AsString;
      ParamByName('pPROVINCIA_CLIENTE').AsString :=
                  unqryTablaG.FieldByName('PROVINCIA_CLIENTE_FAC').AsString;
      ParamByName('pCPOSTAL_CLIENTE').AsString :=
                    unqryTablaG.FieldByName(
                      'CODIGO_POSTAL_CLIENTE_FAC').AsString;
      ParamByName('pPAIS_CLIENTE').AsString :=
                unqryTablaG.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString;
      ParamByName('pCOD_PAIS_CLIENTE').AsString :=
                unqryTablaG.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString;
      ParamByName('pESINTRACOMUNITARIO_CLIENTE').AsString :=
         unqryTablaG.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString;
      ParamByName('pESIVA_EXENTO_CLIENTE').AsString :=
               unqryTablaG.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString;
      ParamByName('pESRETENCIONES_CLIENTE').AsString :=
              unqryTablaG.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString;
      ParamByName('pESIVA_RECARGO_CLIENTE').AsString :=
              unqryTablaG.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString;
      ParamByName('pESREGIMENESPECIALAGRICOLA_CLIENTE').AsString :=
                                                        unqryTablaG.FieldByName(
                          'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString;
      ParamByName('pTARIFA_ARTICULO_CLIENTE').AsString :=
            unqryTablaG.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString;
      ParamByName('pUSUARIO').AsString := oUser;
    end;
    unstrdprcCrearCliente.ExecProc;
end;

procedure TdmFacturas.CrearEmpresa;
begin
    with unstdCrearEmpresa do
    begin
      ParamByName('pCODIGO_EMPRESA').AsString :=
                     unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
      ParamByName('pRAZONSOCIAL_EMPRESA').AsString :=
                unqryTablaG.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString;
      ParamByName('pNIF_EMPRESA').AsString :=
                        unqryTablaG.FieldByName('NIF_EMPRESA_FAC').AsString;
      ParamByName('pMOVIL_EMPRESA').AsString :=
                      unqryTablaG.FieldByName('MOVIL_EMPRESA_FAC').AsString;
      ParamByName('pEMAIL_EMPRESA').AsString :=
                      unqryTablaG.FieldByName('EMAIL_EMPRESA_FAC').AsString;
      ParamByName('pDIRECCION1_EMPRESA').AsString :=
                 unqryTablaG.FieldByName('DIRECCION1_EMPRESA_FAC').AsString;
      ParamByName('pDIRECCION2_EMPRESA').AsString :=
                 unqryTablaG.FieldByName('DIRECCION2_EMPRESA_FAC').AsString;
      ParamByName('pPOBLACION_EMPRESA').AsString :=
                  unqryTablaG.FieldByName('POBLACION_EMPRESA_FAC').AsString;
      ParamByName('pPROVINCIA_EMPRESA').AsString :=
                  unqryTablaG.FieldByName('PROVINCIA_EMPRESA_FAC').AsString;
      ParamByName('pCPOSTAL_EMPRESA').AsString :=
                    unqryTablaG.FieldByName(
                      'CODIGO_POSTAL_EMPRESA_FAC').AsString;
      ParamByName('pPAIS_EMPRESA').AsString :=
                unqryTablaG.FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString;
      ParamByName('pCODPAIS_EMPRESA').AsString :=
                unqryTablaG.FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString;
      ParamByName('pRETENCIONES_EMPRESA').AsString :=
              unqryTablaG.FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString;
      ParamByName('pREGIMENESPECIALAGRICOLA_EMPRESA').AsString :=
  unqryTablaG.FieldByName('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString;
      ParamByName('pGRUPO_ZONA_IVA_EMPRESA').AsString :=
             unqryTablaG.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
      ParamByName('pUSUARIO').AsString := oUser;
    end;
    unstdCrearEmpresa.ExecProc;
end;

procedure TdmFacturas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPerfiles.Connection := inLibGlobalVar.oConn;
  unqryTablaG.Connection := inLibGlobalVar.oConn;
  unqryLinFac.Connection := inLibGlobalVar.oConn;
  unqrySeries.Connection := inLibGlobalVar.oConn;
  unqryIvas.Connection := inLibGlobalVar.oConn;
  unqryRecibos.Connection := inLibGlobalVar.oConn;
  unqryEmpDataFac.Connection := inLibGlobalVar.oConn;
  unqryCliDataFac.Connection := inLibGlobalVar.oConn;
  unqryArtDataLinFac.Connection := inLibGlobalVar.oConn;
  unqryTarifas.Connection := inLibGlobalVar.oConn;
  unstrdprcCrearCliente.Connection := inLibGlobalVar.oConn;
  unstdCrearEmpresa.Connection := inLibGlobalVar.oConn;
  unstdCrearArticuloLin.Connection := inLibGlobalVar.oConn;
  unqryFormaPago.Connection := inLibGlobalVar.oConn;
  unstrdprcGetContadorFactura.Connection := inLibGlobalVar.oConn;
  unstdGetContadorLinea.Connection := inLibGlobalVar.oConn;
  unstdCalcularFactura.Connection := inLibGlobalVar.oConn;
  unstrdprcGetDataCliente.Connection := inLibGlobalVar.oConn;
  unstrdprcGetRecibos.Connection := inLibGlobalVar.oConn;
  unqryRecibosPrint.Connection := inLibGlobalVar.oConn;
  unqrySeriesEditCombo.Connection := inLibGlobalVar.oConn;
  unqryIvasTipos.Connection := inLibGlobalVar.oConn;
  unqryPaisesEmp.Connection := inLibGlobalVar.oConn;
  unqryPaisesCli.Connection := inLibGlobalVar.oConn;
  unqryConsolidacion.Connection := inLibGlobalVar.oConn;
  unqryErrores.Connection := inLibGlobalVar.oConn;
  unqryMovimientosFac.Connection := inLibGlobalVar.oConn;
  unstrdprcInsertarMovFac.Connection := inLibGlobalVar.oConn;
  unqryLinfac.MasterSource := (GetOwnerForm<TfrmMtoFacturasBase>).dsTablaG;
  unqryRecibos.MasterSource := (GetOwnerForm<TfrmMtoFacturasBase>).dsTablaG;
  unqryConsolidacion.MasterSource := (GetOwnerForm<TfrmMtoFacturasBase>).dsTablaG;
  unqryErrores.MasterSource := (GetOwnerForm<TfrmMtoFacturasBase>).dsTablaG;
  unqryMovimientosFac.MasterSource := (GetOwnerForm<TfrmMtoFacturasBase>).dsTablaG;
end;

procedure TdmFacturas.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmFacturas.AbrirDetalles;
const
  TAG = 'Facturas.AbrirDetalles';

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
  // Lookups y pestaña por defecto. Las queries lazy (Recibos,
  // Consolidacion, Errores, MovimientosFac) se abren al activar su
  // sub-pestaña via AsegurarXxxAbierta.
  AbrirConTiempo(unqryIvasTipos,      'unqryIvasTipos');
  AbrirConTiempo(unqryLinFac,         'unqryLinFac');
  AbrirConTiempo(unqrySeries,         'unqrySeries');
  AbrirConTiempo(unqryIvas,           'unqryIvas');
  AbrirConTiempo(unqryFormaPago,      'unqryFormaPago');
  AbrirConTiempo(unqryTarifas,        'unqryTarifas');
  AbrirConTiempo(unqryPaisesCli,      'unqryPaisesCli');
  AbrirConTiempo(unqryPaisesEmp,      'unqryPaisesEmp');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFacturas.RellenarParamsDesdeMaestro(AQry: TUniQuery);
var
  oMaestro: TDataSet;
  oCampo:   TField;
  i:        Integer;
begin
  if (AQry.MasterSource <> nil) and
     (AQry.MasterSource.DataSet <> nil) then
  begin
    oMaestro := AQry.MasterSource.DataSet;
    if oMaestro.Active and (not oMaestro.IsEmpty) then
    begin
      for i := 0 to AQry.Params.Count - 1 do
      begin
        oCampo := oMaestro.FindField(AQry.Params[i].Name);
        if oCampo <> nil then
          AQry.Params[i].Value := oCampo.Value;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarRecibosAbierta;
var swQ: TStopwatch;
begin
  if unqryRecibos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    RellenarParamsDesdeMaestro(unqryRecibos);
    unqryRecibos.Open;
    inLibLog.Log.LogPerf('Facturas.Lazy', 'unqryRecibos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Facturas.Lazy',
        'unqryRecibos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmFacturas.AsegurarConsolidacionAbierta;
var swQ: TStopwatch;
begin
  if unqryConsolidacion.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    RellenarParamsDesdeMaestro(unqryConsolidacion);
    unqryConsolidacion.Open;
    inLibLog.Log.LogPerf('Facturas.Lazy', 'unqryConsolidacion OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Facturas.Lazy',
        'unqryConsolidacion ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmFacturas.AsegurarErroresAbierta;
var swQ: TStopwatch;
begin
  if unqryErrores.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    RellenarParamsDesdeMaestro(unqryErrores);
    unqryErrores.Open;
    inLibLog.Log.LogPerf('Facturas.Lazy', 'unqryErrores OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Facturas.Lazy',
        'unqryErrores ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmFacturas.AsegurarMovimientosFacAbierta;
var swQ: TStopwatch;
begin
  if unqryMovimientosFac.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    RellenarParamsDesdeMaestro(unqryMovimientosFac);
    unqryMovimientosFac.Open;
    inLibLog.Log.LogPerf('Facturas.Lazy', 'unqryMovimientosFac OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Facturas.Lazy',
        'unqryMovimientosFac ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmFacturas.DataModuleDestroy(Sender: TObject);
begin
  inherited;
  unqryLinFac.Close;
  unqryIvas.Close;
  unqryTarifas.Close;
  unqrySeries.Close;
  unqryFormaPago.Close;
  //unqryPerfiles.Close;
  unqryRecibos.Close;
  unqryPaisesEmp.Close;
  unqryPaisesCli.Close;
  unqryConsolidacion.Close;
  unqryErrores.Close;
  if Assigned(unqryMovimientosFac) and unqryMovimientosFac.Active then
    unqryMovimientosFac.Close;
  //unqrySeriesEditCombo.Close;
  //unqryCabIVA.Close;
  inherited;
end;

procedure TdmFacturas.dsLinFacStateChange(Sender: TObject);
begin
  inherited;
  var  Form := GetOwnerForm<TfrmMtoFacturasBase>;
  if not Assigned(Form) then Exit;
  with dsLinFac do
  begin
    with Form do
    begin
      if ((State = dsEdit) or (State = dsInsert) or (State = dsBrowse)) then
      begin               //si la factura es con impuestos incluídos
        if SameText(DataSet.FieldByName(fimpcl).AsString, 'S') then
        begin //el precio sin iva no se puede editar, sólo el precio con IVA
          ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
                                                                           True;
          ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
                                                                          False;
          ctbTOTAL_FACTURASIVA_LINEA.Visible := False;
          ctbTOTAL_FACTURA_LINEA.Visible := True;
        end
        else
        begin
          ctbPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
                                                                           True;
          ctbPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA.Properties.ReadOnly :=
                                                                          False;
          ctbTOTAL_FACTURASIVA_LINEA.Visible := True;
          ctbTOTAL_FACTURA_LINEA.Visible := False;
        end;
      end;
    end;
  end;
end;

function TdmFacturas.FormaPagoDefault: String;
var
  sFormaPago: string;
   LocateSuccess: Boolean;
begin
  LocateSuccess := unqryFormaPago.Locate('ESDEFAULT_FORMA_PAGO_FP', 'S', []);
  sFormaPago := unqryFormaPago.FindField('CODIGO_FP_FP').AsString;
  if LocateSuccess then
    Result := sFormaPago
  else
    Result := '';
end;

function TdmFacturas.GetCodigoGrupoIVAAGricola: String;
var
  qryIVAAG : TUniQuery;
  sResul:String;
begin
  qryIVAAG := TUniQuery.Create(Self);
  with qryIVAAG do
  begin
    Connection := inLibGlobalVar.oConn;
        SQL.Text := 'SELECT IVA_IVAGRP ' +
                    '  FROM vi_ivas_empresa ' +
                    ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = ' + QuotedStr('S') +
                    '   AND CODIGO_EMP_EMP = :pEMPRESA ' +
							     	'	  AND FECHA_DESDE_IVA <= :pFECHA '     +
							      '	  AND (FECHA_HASTA_IVA IS NULL  '   +
							     	'	      OR FECHA_HASTA_IVA > :pFECHA)'+
                    ' LIMIT 1;'  ;
        ParamByName('pFECHA').AsDateTime :=
                            unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
        ParamByName('pEMPRESA').AsString :=
                     unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
    Open;
    if (qryIVAAG.RecordCount > 0) then
      sResul := Fields[0].AsString
    else
    begin
        Close;
        SQL.Text := 'SELECT IVA_IVAGRP ' +
                    '  FROM vi_ivas_empresa ' +
                    ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = ' + QuotedStr('S') +
                    '   AND ESDEFAULT_IVA_IVAGRP = ' + QuotedStr('S') +
							      '  	AND FECHA_DESDE_IVA <= :pFECHA '     +
							      '		AND ( FECHA_HASTA_IVA IS NULL  '   +
								    '		       OR FECHA_HASTA_IVA > :pFECHA)'+
                    ' LIMIT 1;'  ;
        ParamByName('pFECHA').AsDateTime :=
                            unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
       Open;
       sResul := Fields[0].AsString;
    end;
    Close;
    FreeAndNil(qryIVAAG);
  end;
  Result := sResul;
end;

function TdmFacturas.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  with (GetOwnerForm<TfrmMtoFacturasBase>).dmmFacturas.unqryTablaG do
  begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := FindField('PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := FindField('PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := FindField('PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      ShowMessage('Tipo de Iva incorrecto');
      fPorcen := unqryLinFac.FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
      unqryLinFac.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
  end;
  end;
  Result := fPorcen;
end;

procedure TdmFacturas.GetCodigoAutoFactura;
begin
  if (unqryTablaG.FindField('NUMERO_FAC').AsString = '0') then
  begin
    with unstrdprcGetContadorFactura do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'pserie', ptInput);
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftString, 'pcont', ptOutput);
      Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
      ParamByName('pserie').AsString :=
                                unqryTablaG.FindField('SERIE_FAC').AsString;
      ParamByName('ptipodoc').AsString :=  'FC';
      ParamByName('pUSUARIOMODIF').AsString := oUser;
      ParamByName('pEMPRESA_CONTADOR').AsString :=
                       unqryTablaG.FindField('CODIGO_EMP_FAC').AsString;
      ExecProc;
      unqryTablaG.FindField('NUMERO_FAC').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmFacturas.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLI_FAC').AsString = '0') then
  begin
    //bEsNuevoCliente := True;
//    with unstrdprcGetContador do
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('pUSUARIOMODIF').AsString := oUser;
//      ParamByName('ptipodoc').AsString :=  'CL';
//      ExecProc;
      unqryTablaG.FindField('CODIGO_CLI_FAC').AsString :=
                                                 ObtenerSiguienteContador('CL');
//    end;
  end;
end;

function TdmFacturas.TarifaDefault: string;
begin
  Result := oAppParams.GetString('appTarifaDefecto', 'PVP');
end;

procedure TdmFacturas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMP_FAC').AsString = '0' then
  begin
//    with unstrdprcGetContador do
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('ptipodoc').AsString :=  'EM';
//      ParamByName('pUSUARIOMODIF').AsString := oUser;
//      ExecProc;
      unqryTablaG.FindField('CODIGO_EMP_FAC').AsString :=
                                                 ObtenerSiguienteContador('EM');
//    end;
  end;
end;

procedure TdmFacturas.unqryFacAfterPost(DataSet: TDataSet);
var
  sTipo, sMueveStock: string;
  bGeneraMovs: Boolean;
begin
  inherited;
  CalcularFactura;
  // Las facturas SIMPLIFICADAS (tickets directos sin albaran previo)
  // generan movimientos automaticos al consolidarse. Las NORMALES solo
  // si el usuario marco el check ESMUEVE_STOCK_FAC (caso venta directa
  // al mayor sin albaran). La generacion es idempotente: se comprueba
  // que no exista ya el movimiento por TIPO_DOC_MOV/SERIE/NUMERO/LINEA.
  if (not unqryTablaG.Active) or
     (unqryTablaG.FindField('TIPO_FAC') = nil) or
     (Trim(unqryTablaG.FieldByName('NUMERO_FAC').AsString) = '') then
    Exit;
  sTipo := unqryTablaG.FieldByName('TIPO_FAC').AsString;
  bGeneraMovs := (sTipo = 'SIMPLIFICADA');
  if (not bGeneraMovs) and (sTipo = 'NORMAL') and
     (unqryTablaG.FindField('ESMUEVE_STOCK_FAC') <> nil) then
  begin
    sMueveStock := unqryTablaG.FieldByName('ESMUEVE_STOCK_FAC').AsString;
    bGeneraMovs := SameText(sMueveStock, 'S');
  end;
  if bGeneraMovs then
    GenerarMovimientosSalidaFactura;
end;

procedure TdmFacturas.unqryLinFacAfterDelete(DataSet: TDataSet);
begin
  inherited;
  CalcularFactura;
end;

procedure TdmFacturas.unqryLinFacAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryLinFac do
  begin
    AplicarValoresPorDefecto(unqryLinFac, 'fza_facturas_lineas');
    // Limpiar nro de línea para que BeforePost llame al SP de contador
    FindField(fnrolin).AsString := '0';
    FindField(fporiva).AsCurrency := GetTipoIVA(
          FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
    FieldByName(fimpcl).AsString :=
          unqryTablaG.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
  end;
end;

procedure TdmFacturas.unqryLinFacBeforePost(DataSet: TDataSet);
var
  sNuevoNroLinea: string;
  iContadorBD: Integer;
begin
  inherited;
  with unqryLinFac do
  begin
    if (FieldByName(fdesart).AsString = '') then
    begin
      DataSet.Cancel;
      Abort;
    end;
    var sNumLin := FindField(fnrolin).AsString;
    if (sNumLin = '0') or
       (sNumLin = '') then
    begin
      unstdGetContadorLinea.ParamByName('pnumfac').AsString :=
                            unqryTablaG.FieldByName(fnrofac).AsString;
      unstdGetContadorLinea.ParamByName('pserie').AsString :=
                          unqryTablaG.FieldByName(fseriefac).AsString;
      unstdGetContadorLinea.ExecProc;
      sNuevoNroLinea :=
                       unstdGetContadorLinea.ParamByName('presul').AsString;
      FindField(fnrolin).AsString := sNuevoNroLinea;
      // Sincronizar el contador en el dataset de cabecera para que un
      // Post posterior de la cabecera no sobreescriba el valor correcto
      if unqryTablaG.FindField('CONTADOR_LINEAS_FAC') <> nil then
      begin
        iContadorBD := StrToIntDef(sNuevoNroLinea, 0) + 10;
        if unqryTablaG.State = dsBrowse then
          unqryTablaG.Edit;
        unqryTablaG.FieldByName('CONTADOR_LINEAS_FAC').AsString :=
                                                Format('%.3d', [iContadorBD]);
      end;
    end;
  end;
  if DataSet.State in [dsEdit, dsInsert] then
    oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmFacturas.unqryTablaGBeforeDelete(DataSet: TDataSet);
  var
  qryBorrarLineas : TUniQuery;
  qryBorrarRecibos: TUniquery;
begin
  // Una factura lanzada a Verifactu (fuera de BORRADOR) ya está
  // registrada en la AEAT: no se borra, se anula o rectifica
  if (DataSet.FindField(ffasefac) <> nil) and
     (DataSet.FieldByName(ffasefac).AsString <> '') and
     (not SameText(DataSet.FieldByName(ffasefac).AsString, 'BORRADOR')) then
  begin
    ShowMessage('La factura está en fase ' +
                DataSet.FieldByName(ffasefac).AsString +
                ': ya se ha lanzado a Verifactu y no puede borrarse. ' +
                'Use Anular Verifactu o emita una rectificativa.');
    Abort;
  end;
  qryBorrarLineas := TUniQuery.Create(Self);
  with qryBorrarLineas do
  begin
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'DELETE ' +
                '  FROM fza_facturas_lineas ' +
                ' WHERE SERIE_FAC_FACLIN = :serie ' +
                '   AND NUMERO_FAC_FACLIN   = :nrofactura';
    Params.Clear;
    Params.CreateParam(ftString, 'serie', ptInput);
    Params.CreateParam(ftString, 'nrofactura', ptInput);
    Params.ParamByName('serie').AsString :=
                                unqryTablaG.FieldByName(fseriefac).AsString;
    Params.ParamByName('nrofactura').AsString :=
                                  unqryTablaG.FieldByName(fnrofac).AsString;
    ExecSQL;
    Free;
  end;
  qryBorrarRecibos := TUniQuery.Create(Self);
  with qryBorrarRecibos do
  begin
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'DELETE ' +
                '  FROM fza_recibos ' +
                ' WHERE SERIE_FAC_REC = :serie ' +
                '   AND NUMERO_FAC_REC  = :nrofactura';
    Params.Clear;
    Params.CreateParam(ftString, 'serie', ptInput);
    Params.CreateParam(ftString, 'nrofactura', ptInput);
    Params.ParamByName('serie').AsString :=
                              unqryTablaG.FieldByName(fseriefac).AsString;
    Params.ParamByName('nrofactura').AsString :=
                                unqryTablaG.FieldByName(fnrofac).AsString;
    ExecSQL;
    Free;
  end;
  // Borrar movimientos asociados via SP (decrementa stock + acumulados)
  var qMov := TUniQuery.Create(Self);
  try
    qMov.Connection := inLibGlobalVar.oConn;
    qMov.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qMov.ParamByName('t').AsString := 'FC';
    qMov.ParamByName('s').AsString :=
                            unqryTablaG.FieldByName(fseriefac).AsString;
    qMov.ParamByName('n').AsString :=
                            unqryTablaG.FieldByName(fnrofac).AsString;
    qMov.ExecSQL;
  finally
    FreeAndNil(qMov);
  end;
end;

procedure TdmFacturas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    AplicarValoresPorDefecto(unqryTablaG, 'fza_facturas');
//    FieldByName('NUMERO_FAC').AsString := '0';
//    FieldByName('CODIGO_CLI_FAC').AsString := '0';
//    FieldByName('CODIGO_EMP_FAC').AsString := '0';
    FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
                         unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
    FieldByName('FECHA_FAC').AsDateTime := Trunc(Now);
    FieldByName('FORMA_PAGO_FAC').AsString := FormaPagoDefault;
    FieldByName('ESCONSOLIDADA_FAC').AsString := 'N';
    // Toda factura nace en borrador: editable y sin imprimir hasta
    // lanzarla a Verifactu (Consolidar)
    FieldByName('FASE_FAC').AsString := 'BORRADOR';
    // Tipo de factura segun el formulario (NORMAL / SIMPLIFICADA)
    FieldByName('TIPO_FAC').AsString :=
      (GetOwnerForm<TfrmMtoFacturasBase>).TipoFacturaFiltro;
    (GetOwnerForm<TfrmMtoFacturasBase>).sbNuevaFacturaClick(Self.Owner);
  end;
end;

procedure TdmFacturas.unqryLinFacBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  //
  unqryLinFacBeforeInsert(DataSet);
end;

procedure TdmFacturas.unqryLinFacBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  // Verificar que la factura esté guardada antes de insertar líneas
  if not Assigned(unqryTablaG) then
    Abort;
  // Si la cabecera está en edición o inserción, grabarla primero
  if unqryTablaG.State in [dsInsert, dsEdit] then
  begin
    try
      unqryTablaG.Post;
    except
      on E: Exception do
      begin
        ShowMessage('No se puede insertar líneas sin grabar primero la ' +
                    'cabecera: ' + E.Message);
        Abort;
      end;
    end;
  end;
  // Verificar que exista un número de factura válido
  if (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '') or
     (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '0') or
     (unqryTablaG.FieldByName('SERIE_FAC').AsString = '') then
  begin
    ShowMessage('Debe grabar primero la factura antes de añadir líneas');
    Abort;
  end;
  // Verificar estado de consolidación
//  if (unqryTablaG.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S') then
//  begin
//    ShowMessage('No se pueden añadir líneas a una factura consolidada');
//    Abort;
//  end;
end;

procedure TdmFacturas.unqryLinFacAfterPost(DataSet: TDataSet);
begin
  inherited;
  if (SameText(unqryTablaG.FieldByName(fcreart).AsString, 'S')) then
  begin
    with  unstdCrearArticuloLin do
    begin
      ParamByName('pCODIGO_ARTICULO').AsString :=
                                      unqryLinFac.FieldByName(fcodart).AsString;
      ParamByName('pDESCRIPCION_ARTICULO').AsString :=
                                      unqryLinFac.FieldByName(fdesart).AsString;
      ParamByName('pTIPOIVA_ARTICULO').AsString :=
                                      unqryLinFac.FieldByName(ftipiva).AsString;
      ParamByName('pTIPO_CANTIDAD_ARTICULO').AsString :=
                                    unqryLinFac.FieldByName(ftipocant).AsString;
      ParamByName('pESACTIVO_FIJO_ARTICULO').AsString :=
                                      unqryTablaG.FieldByName(factfij).AsString;
      ParamByName('pCODIGO_FAMILIA').AsString :=
                                      unqryLinFac.FieldByName(fcodfam).AsString;
      ParamByName('pNOMBRE_FAMILIA').AsString :=
                                      unqryLinFac.FieldByName(fnomfam).AsString;
      ParamByName('pCODIGO_PROVEEDOR').AsString :=
                                     unqryLinFac.FieldByName(fcodprov).AsString;
      ParamByName('pRAZONSOCIAL_PROVEEDOR').AsString :=
                                     unqryLinFac.FieldByName(frazprov).AsString;
      ParamByName('pESPROVEEDORPRINCIPAL').AsString :=
                                       unqryLinFac.FieldByName(fpprov).AsString;
      ParamByName('pPRECIO_ULT_COMPRA').AsCurrency :=
                                  unqryLinFac.FieldByName(fprecultc).AsCurrency;
//      ParamByName('pFECHA_FACTURA').AsString :=
//                                 unqryTablaG.FieldByName(ffechfac).AsString;
      ParamByName('pCODIGO_TARIFA').AsString :=
                                 unqryLinFac.FieldByName(fcodtariflin).AsString;
      ParamByName('pPRECIOSALIDA_TARIFA').AsCurrency :=
                                 unqryLinFac.FieldByName(fpreciosal).AsCurrency;
      if SameText(unqryLinFac.FieldByName(fimpcl).AsString, 'S')  then
        ParamByName('pPRECIOFINAL_TARIFA').AsCurrency :=
                                    unqryLinFac.FieldByName(fpreciva).AsCurrency
      else
        ParamByName('pPRECIOFINAL_TARIFA').AsCurrency :=
                                   unqryLinFac.FieldByName(fpresiva).AsCurrency;
      ParamByName('pPRECIO_DTO_TARIFA').AsCurrency :=
                                    unqryLinFac.FieldByName(fpordto).AsCurrency;
      ParamByName('pPORCEN_DTO_TARIFA').AsCurrency :=
                                    unqryLinFac.FieldByName(fpordto).AsCurrency;
      ParamByName('pUSUARIO').AsString         := oUser;
//      ParamByName('pUSUARIO').AsString         := oUser;
      //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
      // ojo!!!! HAY UN TEMAZO DE UNIDAC CON EL PASO DE TIMESTAMPS POR PARÁMETRO
      //  ParamByName('pINSTANTEMODIF').AsString :=
      //                             FormatDateTime('YYYY-MM-DD hh:mm:ss', Now);
      ExecProc;
    end;
  end;
  //CalcularFactura;
end;

procedure TdmFacturas.unqryFacBeforePost(DataSet: TDataSet);
var
  ISError:Boolean;
  frmFac:TfrmMtoFacturasBase;
  bValidar: Boolean;
  dtUltima: TDateTime;
begin
  inherited;
  IsError := False;
  frmFac := (GetOwnerForm<TfrmMtoFacturasBase>);
  with unqryTablaG do
  begin
    if ((ExisteSerieEmpresa(FieldByName(fseriefac).AsString,
                          FieldByName(fcodemp).AsString,
                          'FC')) and
        (IsError = False)) then
    begin
      ShowMessage('Esta serie es usada por otra empresa.' +
                  ' Debe cambiar la serie ');
      frmFac.pcCab.ActivePage := frmFac.tsCabecera;
      frmFac.cbbSerieFactura.SetFocus;
      IsError := True;
    end;
    if (FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString = '') and
       (FieldByName('TIPO_FAC').AsString <> 'SIMPLIFICADA') and
       (IsError = False) then
    begin
      ShowMessage('Debe escribir la razón social del cliente a facturar ');
      frmFac.pcCab.ActivePage := frmFac.tsDatosCliente;
      frmFac.txtRAZONSOCIAL_CLIENTE_FACTURA.SetFocus;
      IsError := True;
    end;
    if (FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsSTring = '') and
       (IsError = False) then
    begin
      ShowMessage('Debe escribir la razón social de ' +
                  ' la empresa a facturar ');
      frmFac.pcCab.ActivePage := frmFac.tsEmpresa;
      frmFac.txtRAZONSOCIAL_EMPRESA_FACTURA.SetFocus;
      IsError := True;
    end;
    if (FieldByName('SERIE_FAC').AsString = '') and
       (IsError = False) then
    begin
      ShowMessage('Debe seleccionar una serie para facturar ');
      frmFac.pcCab.ActivePage := frmFac.tsCabecera;
      frmFac.cbbSerieFactura.SetFocus;
      IsError := True;
    end;
    if ((FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString = '') or
        (FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString = '')) and
        (FieldByName('TIPO_FAC').AsString <> 'SIMPLIFICADA') then
    begin
      IsError := True;
      ShowMessage('Debe seleccionar un pais para cliente y empresa.');
    end;
    // Las validaciones de coherencia solo corren mientras la factura es un
    // borrador editable (no en los posts programaticos de consolidacion /
    // lanzamiento a Verifactu, que ya cambian la fase).
    bValidar := (FieldByName('TIPO_FAC').AsString <> 'SIMPLIFICADA') and
                (SameText(FieldByName('FASE_FAC').AsString, 'BORRADOR') or
                 (Trim(FieldByName('FASE_FAC').AsString) = ''));
    // Fecha de factura obligatoria (bloqueo)
    if (not IsError) and bValidar and
       (FieldByName('FECHA_FAC').AsString = '') then
    begin
      ShowMessage('Debe indicar la fecha de la factura.');
      frmFac.pcCab.ActivePage := frmFac.tsCabecera;
      IsError := True;
    end;
    // Coherencia del tipo de operacion Verifactu (bloqueo si es flagrante)
    if (not IsError) and bValidar then
      ValidarOperacionVfactu(IsError);
    // La fecha no puede ser anterior a la ultima factura emitida de la serie
    // (bloqueo): la numeracion debe seguir orden cronologico.
    if (not IsError) and bValidar and
       (FieldByName('FECHA_FAC').AsString <> '') then
    begin
      dtUltima := UltimaFechaSerie(FieldByName('SERIE_FAC').AsString,
                                   FieldByName('CODIGO_EMP_FAC').AsString,
                                   FieldByName('NUMERO_FAC').AsString);
      if (dtUltima > 0) and
         (FieldByName('FECHA_FAC').AsDateTime < dtUltima) then
      begin
        ShowMessage('La fecha ' +
          FormatDateTime('dd/mm/yyyy',
                         FieldByName('FECHA_FAC').AsDateTime) +
          ' es anterior a la ultima factura de la serie (' +
          FormatDateTime('dd/mm/yyyy', dtUltima) +
          '). La numeracion debe seguir orden cronologico.');
        frmFac.pcCab.ActivePage := frmFac.tsCabecera;
        IsError := True;
      end;
    end;
    // Fecha posterior a hoy (solo aviso, no bloquea)
    if (not IsError) and bValidar and
       (FieldByName('FECHA_FAC').AsString <> '') and
       (FieldByName('FECHA_FAC').AsDateTime > Date) then
      ShowMessage('Aviso: la fecha de la factura es posterior a hoy.');
    if IsError then
    begin
      raise Exception.Create('No se ha grabado la cabecera de la factura');
    end
    else
      if ((State = dsEdit) or (State = dsInsert)) then
      begin
        if (FieldByName('NUMERO_FAC').AsString = '0') then
          GetCodigoAutoFactura;
        if (FieldByName('CODIGO_CLI_FAC').AsString = '0') then
          GetCodigoAutoCliente;
        if (FieldByName('CODIGO_EMP_FAC').AsString = '0') then
          GetCodigoAutoEmpresa;
        // El numero no puede quedar en blanco tras la asignacion (bloqueo)
        if bValidar and
           ((Trim(FieldByName('NUMERO_FAC').AsString) = '') or
            (FieldByName('NUMERO_FAC').AsString = '0')) then
          raise Exception.Create('No se ha podido asignar numero a la ' +
            'factura (serie ' + FieldByName('SERIE_FAC').AsString +
            '). Revise el contador de la serie.');
        // Aviso (no bloquea): salto en la numeracion. La ley exige numeracion
        // correlativa, asi que el numero o numeros que falten deben cubrirse.
        if bValidar and (State = dsInsert) and
           HayHuecoNumeracion(FieldByName('SERIE_FAC').AsString,
                              FieldByName('CODIGO_EMP_FAC').AsString,
                              FieldByName('NUMERO_FAC').AsString) then
          ShowMessage('Aviso: hay un salto en la numeracion de la serie ' +
            FieldByName('SERIE_FAC').AsString + '. La ley exige numeracion ' +
            'correlativa: el numero o numeros que falten deben cubrirse.');
        odmConn.ActualizarUserTimeModif(DataSet);
      end;
  end;
end;

function TdmFacturas.GenerarMovimientosSalidaFactura: Integer;
var
  qLineas, qExiste: TUniQuery;
  sNumeroFac, sSerieFac, sEmpresa, sCliente: string;
  sLinea, sSku, sAlmacen, sArticulo, sCaja, sNumOp: string;
  fCantidad: Double;
begin
  Result := 0;
  if not unqryTablaG.Active then Exit;
  sNumeroFac := unqryTablaG.FieldByName('NUMERO_FAC').AsString;
  sSerieFac  := unqryTablaG.FieldByName('SERIE_FAC').AsString;
  if (sNumeroFac = '') then Exit;
  sEmpresa := unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
  sCliente := unqryTablaG.FieldByName('CODIGO_CLI_FAC').AsString;
  if unqryTablaG.FindField('CODIGO_CAJA_FAC') <> nil then
    sCaja := unqryTablaG.FieldByName('CODIGO_CAJA_FAC').AsString
  else
    sCaja := '';
  if unqryTablaG.FindField('NUMERO_OPERACION_FAC') <> nil then
    sNumOp := unqryTablaG.FieldByName('NUMERO_OPERACION_FAC').AsString
  else
    sNumOp := '';

  qLineas := TUniQuery.Create(nil);
  qExiste := TUniQuery.Create(nil);
  try
    qLineas.Connection := inLibGlobalVar.oConn;
    qLineas.SQL.Text :=
      'SELECT LINEA_FACLIN, CODIGO_UNIDAD_FACLIN, CODIGO_ART_FACLIN, ' +
      '       CANTIDAD_FACLIN, CODIGO_ALM_FACLIN ' +
      '  FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :pNUM ' +
      '   AND SERIE_FAC_FACLIN  = :pSER ' +
      ' ORDER BY LINEA_FACLIN';
    qLineas.ParamByName('pNUM').AsString := sNumeroFac;
    qLineas.ParamByName('pSER').AsString := sSerieFac;
    qLineas.Open;

    qExiste.Connection := inLibGlobalVar.oConn;
    // El SP guarda el documento en las columnas DOC (las REF quedan
    // NULL). Las ventas de caja ya registran su salida con
    // TIPO_DOC_MOV='VE': si no se cuentan, un Post posterior de la
    // simplificada duplicaría el movimiento (y el descuento de stock).
    qExiste.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV IN (''FC'', ''VE'') ' +
      '   AND SERIE_DOC_MOV  = :pSER ' +
      '   AND NUMERO_DOC_MOV = :pNUM ' +
      '   AND LINEA_MOV      = :pLIN';

    qLineas.First;
    while not qLineas.Eof do
    begin
      sLinea    := qLineas.FieldByName('LINEA_FACLIN').AsString;
      sSku      := Trim(qLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
      sArticulo := qLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
      fCantidad := qLineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
      sAlmacen  := qLineas.FieldByName('CODIGO_ALM_FACLIN').AsString;

      if (sSku <> '') and (fCantidad > 0) then
      begin
        qExiste.Close;
        qExiste.ParamByName('pSER').AsString := sSerieFac;
        qExiste.ParamByName('pNUM').AsString := sNumeroFac;
        qExiste.ParamByName('pLIN').AsString := sLinea;
        qExiste.Open;
        if qExiste.FieldByName('N').AsInteger = 0 then
        begin
          with unstrdprcInsertarMovFac do
          begin
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
                                                    ObtenerSiguienteContador(
                                                      'MV');
            ParamByName('p_TIPO_DOC_MOV').AsString        := 'FC';
            ParamByName('p_SERIE_DOC_MOV').AsString       := sSerieFac;
            ParamByName('p_NRO_DOC_MOV').AsString         := sNumeroFac;
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
            ParamByName('p_NUMOP_DOC').AsString           := sNumOp;
            ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := sCaja;
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

  if unqryMovimientosFac.Active then
  begin
    unqryMovimientosFac.Close;
    unqryMovimientosFac.Open;
  end;
end;

initialization
  ForceReferenceToClass(TdmFacturas);
end.
