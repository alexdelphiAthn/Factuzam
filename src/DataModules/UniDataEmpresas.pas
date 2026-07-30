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
  Uni, inLibUser, Datasnap.Provider,
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
    unqryBancos: TUniQuery;
    dsBancos: TDataSource;
    dsPaises: TDataSource;
    unqryPaises: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesAfterInsert(DataSet: TDataSet);
    procedure unqryRetencionesBeforePost(DataSet: TDataSet);
    procedure unqryRetencionesBeforeInsert(DataSet: TDataSet);
    procedure unqrySeriesBeforePost(DataSet: TDataSet);
    procedure unqrySeriesAfterInsert(DataSet: TDataSet);
    procedure unqryBancosBeforePost(DataSet: TDataSet);
    procedure unqryBancosAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    function ConfirmarCambioCriticoEmpresa(const sAccion: string): Boolean;
    { Private declarations }
  public
    procedure GetCodigoAutoEmpresa;
    procedure GetCodigoAutoRetencion;
    procedure GetCodigoAutoSerie;
    procedure GetCodigoAutoBanco;
//    function GetLastCodeEmpresa:Integer;
//    function GetZonaDefault:String;
    // Override: abre los lookups (Paises, Ivas). Las queries de detail
    // (Retenciones, Series, Historia/Facturacion) son lazy y se abren
    // al activar su sub-pestaña.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure AsegurarRetencionesAbierta;
    procedure AsegurarSeriesAbierta;
    procedure AsegurarBancosAbierta;
    procedure AsegurarHistoriaFacturacionAbierta;
  end;

implementation

uses
  inLibCadenas, inLibDatasets, inLibValoresAutomaticos, inLibLog,
  System.Diagnostics,
  inLibFormatoDocumento, inLibIBAN, inLibMsgComun,
  inLibMsgFacturas;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmEmpresas.ConfirmarCambioCriticoEmpresa(
  const sAccion: string): Boolean;
var
  sMensaje: string;
begin
  sMensaje := Format(SPreguntaCambioCriticoEmpresa, [sAccion]);
  Result := Application.MessageBox(PChar(sMensaje), PChar(SAdvMsg),
                                   MB_YESNO or MB_ICONWARNING) = ID_YES;
end;

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
      raise ERangeError.CreateFmt(SErrorPorcentajeRetencionEmpresa,
                                 [FindField('PORCENTAJE_EMPRET').AsInteger]);
      bSinErrores := False;
    end;
    if (bSinErrores) then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := ConexionPrincipal;
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
      raise ERangeError.CreateFmt(SErrorRetencionesEmpresaConcurrentes,
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
    ActualizarAuditoria(DataSet);
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
       SimbolosProhibidos(
         FindField('EMPSER').AsString,
         PerfilesUsuario) then
    begin
      raise ERangeError.CreateFmt(SErrorSerieEmpresa,
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
      unqrySol.Connection := ConexionPrincipal;
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
    ActualizarAuditoria(DataSet);
    GetCodigoAutoSerie;
  end
  else
    Abort;

end;

procedure TdmEmpresas.unqryBancosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Codigo a 0 -> lo asigna el contador 'EB' en el BeforePost.
  DataSet.FindField('CODIGO_EMPBAN').AsString          := '0';
  DataSet.FindField('ESACTIVO_EMPBAN').AsString        := 'S';
  DataSet.FindField('ESDEFECTO_COBRO_EMPBAN').AsString := 'N';
  DataSet.FindField('ESDEFECTO_PAGO_EMPBAN').AsString  := 'N';
end;

procedure TdmEmpresas.unqryBancosBeforePost(DataSet: TDataSet);
var
  sIban, sCCC, sBanco, sDC, sCuenta: string;
  stErr: TStringList;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) or
       (unqryTablaG.State = dsEdit) ) then
    unqryTablaG.Post;
  with unqryBancos do
  begin
    sIban := Trim(FindField('IBAN_EMPBAN').AsString);
    // El IBAN es opcional, pero si viene se valida y se descompone.
    if (sIban <> '') then
    begin
      stErr := TStringList.Create;
      try
        if (not TIBAN.ValidarIBAN(sIban, stErr)) then
          raise ERangeError.CreateFmt(SErrorIbanEmpresa, [stErr.Text]);
      finally
        FreeAndNil(stErr);
      end;
      sIban := TIBAN.FormatearElectronico(sIban);
      FindField('IBAN_EMPBAN').AsString := sIban;
      // Descomposicion del CCC espanol: entidad(4) + oficina(4) + DC + cuenta.
      sCCC := TIBAN.ExtraerCCC(sIban);
      if (TIBAN.DescomponerCCC(sCCC, sBanco, sDC, sCuenta)) then
      begin
        FindField('ENTIDAD_EMPBAN').AsString        := Copy(sBanco, 1, 4);
        FindField('OFICINA_EMPBAN').AsString        := Copy(sBanco, 5, 4);
        FindField('DIGITO_CONTROL_EMPBAN').AsString := sDC;
        FindField('CUENTA_EMPBAN').AsString         := sCuenta;
        FindField('CODIGO_BAN_EMPBAN').AsString     := Copy(sBanco, 1, 4);
      end;
    end;
  end;
  ActualizarAuditoria(DataSet);
  GetCodigoAutoBanco;
end;

procedure TdmEmpresas.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  qryBorrarLineas := TUniQuery.Create(Self);
  with qryBorrarLineas do
  begin
    Connection := ConexionPrincipal;
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
    SQL.Text := 'DELETE ' +
                '  FROM fza_empresas_bancos ' +
                ' WHERE CODIGO_EMP_EMPBAN = :Empresa ;';
    Params.ParamByName('Empresa').AsString :=
                             unqryTablaG.FieldByName('CODIGO_EMP_EMP').AsString;
    ExecSQL;
    Free;
  end;
end;

procedure TdmEmpresas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  inLibValoresAutomaticos.AplicarValoresPorDefecto(
    ConexionPrincipal, unqryTablaG, 'fza_empresas');
  unqryTablaG.FindField('GRUPO_ZONA_IVA_EMP').AsString :=
       ObtenerValorPorDefecto(
         ConexionPrincipal,
         'vi_ivas_grupos',
         'IVA_IVAGRP',
         'ESDEFAULT_IVA_IVAGRP');
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
  // Usar la conexion del Post evita bloquear la misma fila que la
  // conexion principal.
  oConexion := ConexionPrincipal;
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
  unqryRetenciones.Connection            := ConexionPrincipal;
  unqrySeries.Connection                 := ConexionPrincipal;
  unqryBancos.Connection                 := ConexionPrincipal;
  unqryIvas.Connection                   := ConexionPrincipal;
  unqryFacturasEmpresas.Connection       := ConexionPrincipal;
  unqryFacturasLineasEmpresas.Connection := ConexionPrincipal;
  unqryPaises.Connection                 := ConexionPrincipal;
  unqryTablaG.AfterPost                  := unqryTablaGAfterPost;
  unqryTablaG.BeforeInsert               := unqryTablaGBeforeInsert;
  unqryTablaG.BeforeEdit                 := unqryTablaGBeforeEdit;
end;

procedure TdmEmpresas.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryFacturasEmpresas.MasterSource := ADataSource;
  unqryFacturasLineasEmpresas.MasterSource := ADataSource;
  unqryRetenciones.MasterSource := ADataSource;
  unqrySeries.MasterSource := ADataSource;
  unqryBancos.MasterSource := ADataSource;
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

procedure TdmEmpresas.AsegurarBancosAbierta;
var swQ: TStopwatch;
begin
  if unqryBancos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryBancos.Open;
    inLibLog.Log.LogPerf('Empresas.Lazy', 'unqryBancos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Empresas.Lazy',
        'unqryBancos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
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
                          inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'EM',
                                                   IdentidadSesion.Usuario);
  end;
  if unqryTablaG.FindField('ORDEN_EMP').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_EMP').AsString :=
                          inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'EO',
                                                   IdentidadSesion.Usuario);
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  if not ConfirmarCambioCriticoEmpresa('borrar') then
  begin
    Abort;
  end;
  if unqryFacturasEmpresas.RecordCount > 0 then
  begin
    if not (Application.MessageBox(
      PWideChar(SPreguntaBorrarEmpresaConFacturas),
      PWideChar(SAdvMsg), MB_YESNO) = ID_YES) then
    begin
      Abort;
    end;
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  if not ConfirmarCambioCriticoEmpresa('editar') then
  begin
    Abort;
  end;
end;

procedure TdmEmpresas.unqryTablaGBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if not ConfirmarCambioCriticoEmpresa('crear') then
  begin
    Abort;
  end;
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
    if (sRazonSocial = '') or
       SimbolosProhibidos(sRazonSocial, PerfilesUsuario) then
    begin
      raise ERangeError.CreateFmt(SErrorRazonSocialEmpresa,
                                 [sRazonSocial]);
    end;
    if (sCodigoEmpresa = '') or
       SimbolosProhibidos(sCodigoEmpresa, PerfilesUsuario) then
    begin
      raise ERangeError.CreateFmt(SErrorCodigoEmpresa,
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
                          inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'RT',
                                                   IdentidadSesion.Usuario);
    end;
end;

procedure TdmEmpresas.GetCodigoAutoSerie;
begin
  if unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString = '0' then
  begin
      unqrySeries.FindField('CODIGO_SERIE_EMPSER').AsString :=
                         inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                  ConexionPrincipal,
                                                  'ES',
                                                  IdentidadSesion.Usuario);
  end;
end;

procedure TdmEmpresas.GetCodigoAutoBanco;
begin
  if unqryBancos.FindField('CODIGO_EMPBAN').AsString = '0' then
  begin
      unqryBancos.FindField('CODIGO_EMPBAN').AsString :=
                         inLibValoresAutomaticos.ObtenerSiguienteContador(
                                                  ConexionPrincipal,
                                                  'EB',
                                                  IdentidadSesion.Usuario);
  end;
end;





initialization
  ForceReferenceToClass(TdmEmpresas);
end.
