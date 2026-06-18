{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEmpresas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de empresas.                                                  }
{    Queries de fza_empresas, retenciones, series, IVAs, países y facturación  }
{    emitida.                                                                  }
{******************************************************************************}
unit UniDataEmpresas;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn, Datasnap.Provider,
  Datasnap.DBClient, Forms, Windows, Dateutils;

type
  TdmEmpresas = class(TdmBase)
    unqryRetenciones: TUniQuery;
    dsRetenciones: TDataSource;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    dsFacturasEmpresas: TDataSource;
    unqryFacturasEmpresas: TUniQuery;
    dsFacturasLineasEmpresas: TDataSource;
    unqryFacturasLineasEmpresas: TUniQuery;
    unqrySeries: TUniQuery;
    dsSeries: TDataSource;
    dsPaises: TDataSource;
    unqryPaises: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesAfterInsert(DataSet: TDataSet);
    procedure unqryRetencionesBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesBeforeInsert(DataSet: TDataSet);
    procedure unqrySeriesBeforePost(DataSet: TDataSet);
    procedure unqrySeriesAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private

    { Private declarations }
  public
    procedure GetCodigoAutoEmpresa;
    procedure GetCodigoAutoRetencion;
    procedure GetCodigoAutoSerie;
//    function GetLastCodeEmpresa:Integer;
//    function GetZonaDefault:String;
    // Override: abre los lookups (Paises, Ivas). Las queries de detail
    // (Retenciones, Series, Historia/Facturacion) son lazy y se abren
    // al activar su sub-pestaña.
    procedure AbrirDetalles; override;
    procedure AsegurarRetencionesAbierta;
    procedure AsegurarSeriesAbierta;
    procedure AsegurarHistoriaFacturacionAbierta;
  end;

implementation

uses
  inLibtb, inLibGlobalVar, inMtoEmpresas, inLibLog, System.Diagnostics,
  inLibFormatoDocumento;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmEmpresas.unqryRetencionesAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString := '0';
end;

procedure TdmEmpresas.unqryRetencionesBeforeInsert(DataSet: TDataSet);
begin
  inherited;
    if ( (unqryTablaG.State = dsInsert) or
         (unqryTablaG.State = dsEdit)
       ) then
      unqryTablaG.Post;
end;

procedure TdmEmpresas.unqryRetencionesBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  bSinErrores:Boolean;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  with unqryRetenciones do
  begin
    if ((FindField('PORCENTAJE_EMPRET').AsInteger <= 0) or
        (FindField('PORCENTAJE_EMPRET').IsNull)) then
    begin
      raise ERangeError.CreateFmt('%d no es un valor válido ' +
                                                        ' para %% de Retención',
             [FindField('PORCENTAJE_EMPRET').AsInteger]);
      bSinErrores := False;
    end;
    if (bSinErrores) then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM vi_empresas_retenciones ' +
                           ' WHERE CODIGO_EMP_EMPRET = :CODIGO_EMP_EMP';
      unqrySol.ParamByName('CODIGO_EMP_EMP').AsString :=
                                 FindField('CODIGO_EMP_EMPRET').AsString;
      unqrySol.Open;
    end;
    if ((bSinErrores) and  not(ExistePeriodoUnico(
                                            unqrySol,
                                            FindField('FECHA_DESDE_EMPRET'),
                                            FindField('FECHA_HASTA_EMPRET')))
       ) then
    begin
      raise ERangeError.CreateFmt('No se pueden grabar dos porcentajes ' +
                                ' activos en la misma fecha para la empresa %s',
                              [FindField('CODIGO_EMP_EMPRET').AsString]);
      bSinErrores := False;
    end;
  end;
  if (assigned(unqrySol)) then
  begin
    unqrySol.Close;
    FreeAndNil(unqrySol);
  end;
  if (bSinErrores) then
  begin
    oDmConn.ActualizarUserTimeModif(DataSet);
    GetCodigoAutoRetencion;
  end
  else
    Abort;
end;

procedure TdmEmpresas.unqrySeriesAfterInsert(DataSet: TDataSet);
begin
  inherited;
  Dataset.FindField('CODIGO_SERIE_EMPSER').AsString := '0';
end;

procedure TdmEmpresas.unqrySeriesBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  bSinErrores:Boolean;
//  sCodigoSerie:String;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  with unqrySeries do
  begin
    if (FindField('EMPSER').AsString = '') or
       (FindField('EMPSER').IsNull) or
       (SimbolosProhibidos(FindField('EMPSER').AsString)) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                                     ' para serie por Empresa ',
             [FindField('EMPSER').AsString]);
      bSinErrores := False;
    end;
//    if (State = dsEdit) then
//      sCodigoSerie := FindField('CODIGO_SERIE_EMPSER').AsString
//    else
//      sCodigoSerie := '';
    if (bSinErrores) then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM vi_empresas_series ' +
                           ' WHERE CODIGO_EMP_EMPSER = :CODIGO_EMP_EMP';
//      if (sCodigoSerie <> '') then
// unqrySol.SQL.Text := unqrySol.SQL.Text + ' AND CODIGO_SERIE_EMPSER <> ' +
//                                                                 sCodigoSerie;
      unqrySol.ParamByName('CODIGO_EMP_EMP').AsString :=
                                 FindField('CODIGO_EMP_EMPSER').AsString;
      unqrySol.Open;
    end;
  end;
  if (assigned(unqrySol)) then
  begin
    unqrySol.Close;
    FreeAndNil(unqrySol);
  end;
  if (bSinErrores) then
  begin
    oDmConn.ActualizarUserTimeModif(DataSet);
    GetCodigoAutoSerie;
  end
  else
    Abort;

end;

procedure TdmEmpresas.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  qryBorrarLineas := TUniQuery.Create(Self);
  with qryBorrarLineas do
  begin
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'DELETE ' +
                '  FROM fza_empresas_retenciones ' +
                ' WHERE CODIGO_EMP_EMPRET = :Empresa ;';
    Params.ParamByName('Empresa').AsString :=
                             unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
    ExecSQL;
    SQL.Text := 'DELETE ' +
                '  FROM fza_empresas_series ' +
                ' WHERE CODIGO_EMP_EMPSER = :Empresa ;';
    Params.ParamByName('Empresa').AsString :=
                             unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
    ExecSQL;
    Free;
  end;
end;

procedure TdmEmpresas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(unqryTablaG, 'fza_empresas');
  unqryTablaG.FindField('GRUPO_ZONA_IVA_EMP').AsString :=
       GetDefaultValue('vi_ivas_grupos', 'IVA_IVAGRP','ESDEFAULT_IVA_IVAGRP');
  if unqryTablaG.FindField('FORMATO_DOCUMENTO_EMP') <> nil then
    unqryTablaG.FindField('FORMATO_DOCUMENTO_EMP').AsString :=
      FORMATO_DOCUMENTO_DEFECTO;
  if unqryTablaG.FindField('ESIVA_RECARGO_COMPRAS_EMP') <> nil then
    unqryTablaG.FindField('ESIVA_RECARGO_COMPRAS_EMP').AsString := 'N';
end;

procedure TdmEmpresas.unqryTablaGAfterPost(DataSet: TDataSet);
var
  oCampoFormato: TField;
  oCampoPie1: TField;
  oCampoPie2: TField;
  oCampoPie3: TField;
  oCampoPie4: TField;
  sCodigo: string;
  sFormato: string;
  oConexion: TUniConnection;
  unqryPie: TUniQuery;
  unqryFormato: TUniQuery;
begin
  // Usar la conexion del Post evita bloquear la misma fila con oConn.
  oConexion := oConn;
  if DataSet is TUniQuery then
    oConexion := TUniQuery(DataSet).Connection;
  oCampoFormato := DataSet.FindField('FORMATO_DOCUMENTO_EMP');
  if oCampoFormato <> nil then
  begin
    sCodigo := DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
    sFormato := Trim(oCampoFormato.AsString);
    if sFormato = '' then
      sFormato := FORMATO_DOCUMENTO_DEFECTO;
    unqryFormato := TUniQuery.Create(nil);
    try
      unqryFormato.Connection := oConexion;
      unqryFormato.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET FORMATO_DOCUMENTO_EMP = :FORMATO ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      unqryFormato.ParamByName('FORMATO').AsString := sFormato;
      unqryFormato.ParamByName('CODIGO_EMP').AsString := sCodigo;
      unqryFormato.Execute;
    finally
      FreeAndNil(unqryFormato);
    end;
  end;
  oCampoPie1 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_1_EMP');
  oCampoPie2 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_2_EMP');
  oCampoPie3 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_3_EMP');
  oCampoPie4 := DataSet.FindField('TEXTO_PIE_TICKET_CAJA_4_EMP');
  if (oCampoPie1 <> nil) and
     (oCampoPie2 <> nil) and
     (oCampoPie3 <> nil) and
     (oCampoPie4 <> nil) then
  begin
    sCodigo := DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
    unqryPie := TUniQuery.Create(nil);
    try
      unqryPie.Connection := oConexion;
      unqryPie.SQL.Text :=
        'UPDATE fza_empresas ' +
        '   SET TEXTO_PIE_TICKET_CAJA_1_EMP = :PIE1, ' +
        '       TEXTO_PIE_TICKET_CAJA_2_EMP = :PIE2, ' +
        '       TEXTO_PIE_TICKET_CAJA_3_EMP = :PIE3, ' +
        '       TEXTO_PIE_TICKET_CAJA_4_EMP = :PIE4 ' +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      unqryPie.ParamByName('PIE1').AsString :=
        Copy(Trim(oCampoPie1.AsString), 1, 42);
      unqryPie.ParamByName('PIE2').AsString :=
        Copy(Trim(oCampoPie2.AsString), 1, 42);
      unqryPie.ParamByName('PIE3').AsString :=
        Copy(Trim(oCampoPie3.AsString), 1, 42);
      unqryPie.ParamByName('PIE4').AsString :=
        Copy(Trim(oCampoPie4.AsString), 1, 42);
      unqryPie.ParamByName('CODIGO_EMP').AsString := sCodigo;
      unqryPie.Execute;
    finally
      FreeAndNil(unqryPie);
    end;
  end;
end;

procedure TdmEmpresas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo asignaciones de Connection y MasterSource. Los .Open se han
  // movido a AbrirDetalles (callback main thread con overlay visible)
  // para no congelar la UI durante la creacion del data module.
  unqryRetenciones.Connection            := oConn;
  unqrySeries.Connection                 := oConn;
  unqryIvas.Connection                   := oConn;
  unqryFacturasEmpresas.Connection       := oConn;
  unqryFacturasLineasEmpresas.Connection := oConn;
  unqryPaises.Connection                 := oConn;
  unqryTablaG.AfterPost                  := unqryTablaGAfterPost;
  unqryFacturasEmpresas.MasterSource :=
                                       (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqryFacturasLineasEmpresas.MasterSource :=
                                       (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqryRetenciones.MasterSource    :=  (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqrySeries.MasterSource         :=  (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
end;

procedure TdmEmpresas.AbrirDetalles;
const
  TAG = 'Empresas.AbrirDetalles';

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
  // Solo lookups. Las queries de detail (Retenciones, Series,
  // FacturasEmpresas, FacturasLineasEmpresas) son lazy: se abren al
  // activar su pestaña via AsegurarXxxAbierta.
  AbrirConTiempo(unqryPaises, 'unqryPaises');
  AbrirConTiempo(unqryIvas,   'unqryIvas');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmEmpresas.AsegurarRetencionesAbierta;
var swQ: TStopwatch;
begin
  if unqryRetenciones.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryRetenciones.Open;
    inLibLog.Log.LogPerf('Empresas.Lazy', 'unqryRetenciones OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Empresas.Lazy',
        'unqryRetenciones ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmEmpresas.AsegurarSeriesAbierta;
var swQ: TStopwatch;
begin
  if unqrySeries.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqrySeries.Open;
    inLibLog.Log.LogPerf('Empresas.Lazy', 'unqrySeries OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Empresas.Lazy',
        'unqrySeries ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmEmpresas.AsegurarHistoriaFacturacionAbierta;
var swQ: TStopwatch;
begin
  // Las dos queries van en pareja: cabecera + lineas de facturas
  // emitidas a la empresa.
  if unqryFacturasEmpresas.Active
     and unqryFacturasLineasEmpresas.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    if not unqryFacturasEmpresas.Active then
      unqryFacturasEmpresas.Open;
    if not unqryFacturasLineasEmpresas.Active then
      unqryFacturasLineasEmpresas.Open;
    inLibLog.Log.LogPerf('Empresas.Lazy',
      'unqryFacturasEmpresas+Lineas OK', swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Empresas.Lazy',
        'unqryFacturasEmpresas+Lineas ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmEmpresas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMP_EMP').AsString = '0' then
  begin
      unqryTablaG.FindField('CODIGO_EMP_EMP').AsString :=
                                                 ObtenerSiguienteContador('EM');
  end;
  if unqryTablaG.FindField('ORDEN_EMP').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_EMP').AsString :=
                                                 ObtenerSiguienteContador('EO');
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
    if (unqryFacturasEmpresas.RecordCount > 0) then
      if not ( Application.MessageBox( 'La empresa tiene facturas emitidas, ' +
                                   ' ¿Desea realmente borrar el registro?',
                                   'Mensaje Advertencia',
                                   MB_YESNO ) = ID_YES ) then
        Abort;
end;

procedure TdmEmpresas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  bError:Boolean;
  sCodigoEmpresa, sRazonSocial:String;
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('RAZON_SOCIAL_EMP').AsString) = '') then
    Abort;
  bError := False;
  if ((unqryRetenciones.State = dsInsert) or
      (unqryRetenciones.State = dsEdit)) then
         unqryRetenciones.Post;
  with unqryTablaG do
  begin
    if FindField('FORMATO_DOCUMENTO_EMP') <> nil then
    begin
      if Trim(FindField('FORMATO_DOCUMENTO_EMP').AsString) = '' then
        FindField('FORMATO_DOCUMENTO_EMP').AsString :=
          FORMATO_DOCUMENTO_DEFECTO;
    end;
    if FindField('TEXTO_PIE_TICKET_CAJA_1_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_1_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_1_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_2_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_2_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_2_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_3_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_3_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_3_EMP').AsString), 1, 42);
    if FindField('TEXTO_PIE_TICKET_CAJA_4_EMP') <> nil then
      FindField('TEXTO_PIE_TICKET_CAJA_4_EMP').AsString :=
        Copy(Trim(FindField('TEXTO_PIE_TICKET_CAJA_4_EMP').AsString), 1, 42);
    sCodigoEmpresa := Trim(FindField('CODIGO_EMP_EMP').AsString);
    sRazonSocial := Trim(FindField('RAZON_SOCIAL_EMP').AsString);
    if ((sRazonSocial = '') or (SimbolosProhibidos(sRazonSocial))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                        'para el campo Razón Social de Empresa',
                                                                [sRazonSocial]);
    end;
    if ((sCodigoEmpresa = '') or (SimbolosProhibidos(sCodigoEmpresa))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                              'para el campo Código de Empresa',
                                                              [sCodigoEmpresa]);
    end;
    if bError then
      Abort
    else
      GetCodigoAutoEmpresa;
  end;
end;

procedure TdmEmpresas.GetCodigoAutoRetencion;
begin
  if unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString = '0' then
  begin
      unqryRetenciones.FindField('CODIGO_RETENCION_EMPRET').AsString :=
                                                 ObtenerSiguienteContador('RT');
    end;
end;

procedure TdmEmpresas.GetCodigoAutoSerie;
begin
  if unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString = '0' then
  begin
      unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString :=
                                                ObtenerSiguienteContador('ES');
  end;
end;





initialization
  ForceReferenceToClass(TdmEmpresas);
end.
