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
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure unqryLinFacBeforeEdit(DataSet: TDataSet);
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

    // Genera movimientos de salida de stock para todas las líneas de la
    // factura cargada (sólo se llama automáticamente en facturas
    // simplificadas, pero se puede invocar manualmente). Idempotente: salta
    // líneas que ya tengan un movimiento registrado para el documento
    // (TIPO_DOC_REF_MOV='FC').
    function GenerarMovimientosSalidaFactura: Integer;
  end;
implementation

uses
  inMtoFacturas,
  inLibGlobalVar,
  inLibtb,
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
  end;
  oLinFac :=
    TLinFac.Create((GetOwnerForm<TfrmMtoFacturas>).dmmFacturas.unqryLinFac,
                            (
                              GetOwnerForm<TfrmMtoFacturas>).dmmFacturas.unqryTablaG);
  oLinFac.Cant := 1;
  FreeAndNil(oLinFac);
  facTotales := TFacturaTotales.Create(
    (GetOwnerForm<TfrmMtoFacturas>).dmmFacturas.unqryTablaG,
                                       (
                                         GetOwnerForm<TfrmMtoFacturas>).dmmFacturas.unqryLinFac);
  facTotales.ProcesarFacturaCompleta;//(oLinFac);
  FreeAndNil(facTotales);
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
      (GetOwnerForm<TfrmMtoFacturas>).ActualizarComboSeries;
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
       (GetOwnerForm<TfrmMtoFacturas>).ActualizarComboSeries;
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
  unqryLinfac.MasterSource := (GetOwnerForm<TfrmMtoFacturas>).dsTablaG;
  unqryRecibos.MasterSource := (GetOwnerForm<TfrmMtoFacturas>).dsTablaG;
  unqryConsolidacion.MasterSource := (GetOwnerForm<TfrmMtoFacturas>).dsTablaG;
  unqryErrores.MasterSource := (GetOwnerForm<TfrmMtoFacturas>).dsTablaG;
  unqryMovimientosFac.MasterSource := (GetOwnerForm<TfrmMtoFacturas>).dsTablaG;
end;

procedure TdmFacturas.OpenTables;
begin
  unqryIvasTipos.Open;
  unqryLinFac.Open;
  unqrySeries.Open;
  unqryIvas.Open;
  unqryFormaPago.Open;
  unqryTarifas.Open;
  unqryRecibos.Open;
  unqryPaisesCli.Open;
  unqryPaisesEmp.Open;
  unqryConsolidacion.Open;
  unqryErrores.Open;
  unqryMovimientosFac.Open;
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
  var  Form := GetOwnerForm<TfrmMtoFacturas>;
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
  with (GetOwnerForm<TfrmMtoFacturas>).dmmFacturas.unqryTablaG do
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
  unqryTarifas.Locate('ESDEFAULT_TAR', 'S', []);
  Result := unqryTarifas.FindField('CODIGO_TAR_ARTTAR').AsString;
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
begin
  inherited;
  CalcularFactura;
  // Sólo las facturas simplificadas (tickets directos sin albarán previo)
  // generan movimientos automáticos al consolidarse.
  if (unqryTablaG.Active) and
     (unqryTablaG.FindField('TIPO_FAC') <> nil) and
     (unqryTablaG.FieldByName('TIPO_FAC').AsString = 'SIMPLIFICADA') and
     (Trim(unqryTablaG.FieldByName('NUMERO_FAC').AsString) <> '') then
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
    FindField(fporiva).AsCurrency := GetTipoIVA(
          FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
    FieldByName(fimpcl).AsString :=
          unqryTablaG.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
  end;
end;

procedure TdmFacturas.unqryLinFacBeforePost(DataSet: TDataSet);
var
  qryMax: TUniQuery;
  sNuevoNroLinea: string;
begin
  inherited;
  with unqryLinFac do
  begin
    if (FieldByName(fdesart).AsString = '') then
    begin
      raise EDatabaseError.CreateFmt('Error.Descripción de linea ' +
                                     'de factura vacía.',[]);
    end;
    if (FindField(fnrolin).AsString = '0') or
       (FindField(fnrolin).AsString = '') then
    begin
      // Calculamos el siguiente LINEA_FACLIN directamente desde
      // fza_facturas_lineas para evitar depender de
      // fza_facturas.CONTADOR_LINEAS_FAC: ese contador puede estar
      // desincronizado con las lineas reales (factura antigua, Post de
      // la cabecera que sobrescribe el valor del SP con el viejo del
      // dataset, etc.), lo que provocaba duplicados de PK.
      qryMax := TUniQuery.Create(nil);
      try
        qryMax.Connection := inLibGlobalVar.oConn;
        qryMax.SQL.Text :=
          'SELECT LPAD(IFNULL(MAX(CAST(LINEA_FACLIN AS UNSIGNED)),0)+10,3,' +
          '''0'') AS NUEVA_LINEA' +
          '  FROM fza_facturas_lineas' +
          ' WHERE NUMERO_FAC_FACLIN = :pnumfac' +
          '   AND SERIE_FAC_FACLIN  = :pserie';
        qryMax.ParamByName('pnumfac').AsString :=
                              unqryTablaG.FieldByName(fnrofac).AsString;
        qryMax.ParamByName('pserie').AsString :=
                              unqryTablaG.FieldByName(fseriefac).AsString;
        qryMax.Open;
        sNuevoNroLinea := qryMax.FieldByName('NUEVA_LINEA').AsString;
      finally
        FreeAndNil(qryMax);
      end;
      FindField(fnrolin).AsString := sNuevoNroLinea;
      // Mantenemos sincronizado fza_facturas.CONTADOR_LINEAS_FAC con la
      // nueva linea para que otros caminos (caja, albaranes) que aun lo
      // consultan vean el valor correcto despues del Post.
      if unqryTablaG.FindField('CONTADOR_LINEAS_FAC') <> nil then
      begin
        if unqryTablaG.State = dsBrowse then unqryTablaG.Edit;
        unqryTablaG.FieldByName('CONTADOR_LINEAS_FAC').AsString :=
                                                            sNuevoNroLinea;
      end;
    end;
  end;
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmFacturas.unqryTablaGBeforeDelete(DataSet: TDataSet);
  var
  qryBorrarLineas : TUniQuery;
  qryBorrarRecibos: TUniquery;
begin
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
end;

procedure TdmFacturas.unqryTablaGBeforeEdit(DataSet: TDataSet);
begin
  inherited;
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
    (GetOwnerForm<TfrmMtoFacturas>).sbNuevaFacturaClick(Self.Owner);
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
  frmFac:TfrmMtoFacturas;
begin
  inherited;
  IsError := False;
  frmFac := (GetOwnerForm<TfrmMtoFacturas>);
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
    qExiste.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_REF_MOV   = ''FC'' ' +
      '   AND SERIE_DOC_REF_MOV  = :pSER ' +
      '   AND NUMERO_DOC_REF_MOV = :pNUM ' +
      '   AND LINEA_REF_MOV      = :pLIN';

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
