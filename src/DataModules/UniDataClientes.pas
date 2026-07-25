{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataClientes                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de clientes.                                                  }
{    Queries de fza_clientes, formas de pago, tarifas, depósitos y facturación }
{    asociada.                                                                 }
{******************************************************************************}
unit UniDataClientes;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  inMtoPrincipal, Uni, inLibUser, UniDataConn, inLibWin, Forms, Windows,
  Datasnap.DBClient, Datasnap.Provider, frxClass, frxDBSet, frCoreClasses;

type
  TdmClientes = class(TdmBase)
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
    dsEmpresasBancos: TDataSource;
    unqryEmpresasBancos: TUniQuery;
    dsTarifas: TDataSource;
    unqryTarifas: TUniQuery;
    dsFacturasClientes: TDataSource;
    unqryFacturasClientes: TUniQuery;
    dsFacturasLineasClientes: TDataSource;
    unqryFacturasLineasClientes: TUniQuery;
    cdsEtiquetas: TClientDataSet;
    dtstprvEtiquetas: TDataSetProvider;
    unqryCliPrint: TUniQuery;
    dsEtiquetas: TDataSource;
    fxdsEtiquetas: TfrxDBDataset;
    dsPaises: TDataSource;
    unqryPaises: TUniQuery;
    dsDepositos: TDataSource;
    unqryDepositos: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
  private
    procedure GuardarParametrosEDocCliente(ADataSet: TDataSet);
  public
    procedure GetCodigoAutoCliente;
    procedure CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                    sCodCli:String);
    // Override: abre los lookups (Paises, FormaPago, Tarifas). Las
    // queries de detail (FacturasClientes, FacturasLineasClientes,
    // Depositos) son lazy: se abren al activar su sub-pestaña.
    procedure AbrirDetalles; override;
    procedure AsegurarHistoriaFacturacionAbierta;
    procedure AsegurarDepositosAbierta;
  end;

//var
//  dmClientes2: TdmClientes;

implementation

uses
  inMtoClientes, inLibAppParam, inLibCajaParam, inLibtb,
  inLibLog,
  System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmClientes.CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                            sCodCli:String);
var
  i:Integer;
begin
  unqryCliPrint.Connection := ConexionPrincipal;
  unqryCliPrint.SQL.Text := ' SELECT * ' +
                            ' from vi_clientes ' +
                            ' where CODIGO_CLI_CLI = :CODIGO';
  unqryCliPrint.ParamByName('CODIGO').AsString := sCodCli;
  unqryCliPrint.Open;
  cdsEtiquetas.Data := dtstprvEtiquetas.Data;
  cdsEtiquetas.ReadOnly := False;
  cdsEtiquetas.Active := True;
  cdsEtiquetas.First;
  cdsEtiquetas.DisableControls;
  cdsEtiquetas.DisableConstraints;
  fxdsEtiquetas.UpdateBounds;
  //cdsEtiquetas.IndexDefs.Clear;
  for i := 0 to (cdsEtiquetas.Fieldcount-1) do
  begin
    cdsEtiquetas.fields[i].ReadOnly := false;
    cdsEtiquetas.Fields[i].Required := false;
    cdsEtiquetas.FieldDefs[i].Attributes := [];
  end;
  for i := 1 to iNroEspaciosBlanco do
  begin
    cdsEtiquetas.Insert;
    cdsEtiquetas.FieldByName('CODIGO_CLI_CLI').AsString := '0';
    cdsEtiquetas.FieldByName('RAZON_SOCIAL_CLI').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTE_MODIF').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTE_ALTA').AsString := '';
    cdsEtiquetas.FieldByName('USUARIO_MODIF').AsString := '';
    cdsEtiquetas.FieldByName('USUARIO_ALTA').AsString := '';
    cdsEtiquetas.Post;
  end;
end;

procedure TdmClientes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo asignaciones de Connection y MasterSource. Los .Open se han
  // movido a AbrirDetalles (callback main thread con overlay visible)
  // para no congelar la UI durante la creacion del data module.
  unqryFormaPago.Connection := ConexionPrincipal;
  unqryEmpresasBancos.Connection := ConexionPrincipal;
  unqryPerfiles.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unqryFacturasClientes.Connection := ConexionPrincipal;
  unqryFacturasLineasClientes.Connection := ConexionPrincipal;
  unqryPaises.Connection := ConexionPrincipal;
  var LForm := GetOwnerForm<TfrmMtoClientes>;
  unqryFacturasClientes.MasterSource := LForm.dsTablaG;
  unqryFacturasLineasClientes.MasterSource := LForm.dsTablaG;
  unqryDepositos.MasterSource := LForm.dsTablaG;
end;

procedure TdmClientes.AbrirDetalles;
const
  TAG = 'Clientes.AbrirDetalles';

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
  // Solo lookups. Historia (FacturasClientes+Lineas) y Depositos son
  // lazy: se abren al activar la pestaña Historia/Prestamos.
  AbrirConTiempo(unqryPaises,    'unqryPaises');
  AbrirConTiempo(unqryFormaPago, 'unqryFormaPago');
  AbrirConTiempo(unqryEmpresasBancos, 'unqryEmpresasBancos');
  AbrirConTiempo(unqryTarifas,   'unqryTarifas');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmClientes.AsegurarHistoriaFacturacionAbierta;
var swQ: TStopwatch;
begin
  if unqryFacturasClientes.Active
     and unqryFacturasLineasClientes.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    if not unqryFacturasClientes.Active then
      unqryFacturasClientes.Open;
    if not unqryFacturasLineasClientes.Active then
      unqryFacturasLineasClientes.Open;
    inLibLog.Log.LogPerf('Clientes.Lazy',
      'unqryFacturasClientes+Lineas OK', swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Clientes.Lazy',
        'unqryFacturasClientes+Lineas ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmClientes.AsegurarDepositosAbierta;
var swQ: TStopwatch;
begin
  if unqryDepositos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryDepositos.Open;
    inLibLog.Log.LogPerf('Clientes.Lazy', 'unqryDepositos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Clientes.Lazy',
        'unqryDepositos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmClientes.DataModuleDestroy(Sender: TObject);
begin
  inherited;
  //unqryTiposIVA.Close;
  unqryPerfiles.Close;
  unqryFormaPago.Close;
  unqryTarifas.Close;
  unqryFacturasClientes.Close;
  unqryFacturasLineasClientes.Close;
  unqryPaises.Close;
  unqryDepositos.Close;
end;

procedure TdmClientes.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLI_CLI').AsString = '0') then
  begin
    unqryTablaG.FindField('CODIGO_CLI_CLI').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'CL',
                                                   IdentidadSesion.Usuario);
  end;
  if (unqryTablaG.FindField('ORDEN_CLI').AsString = '0') then
  begin
    unqryTablaG.FindField('ORDEN_CLI').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'CO',
                                                   IdentidadSesion.Usuario);
  end;
end;

procedure TdmClientes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(ConexionPrincipal, unqryTablaG, 'fza_clientes');
  unqryTablaG.FindField('CODIGO_FP_CLI').AsString :=
                                            GetDefaultValue(
                                              ConexionPrincipal,
                                              'fza_formas_pago',
                                                            'CODIGO_FP_FP',
                                                     'ESDEFAULT_FORMA_PAGO_FP');
  unqryTablaG.FindField('TARIFA_ARTICULO_CLI').AsString := TarifaDefecto;
end;

procedure TdmClientes.GuardarParametrosEDocCliente(ADataSet: TDataSet);
var
  Qry: TUniQuery;
  bCamposDir3Disponibles: Boolean;
  bCamposPersonaDisponibles: Boolean;
  sCliente: string;
begin
  sCliente := Trim(ADataSet.FieldByName('CODIGO_CLI_CLI').AsString);
  bCamposDir3Disponibles :=
    (ADataSet.FindField('CODIGO_OFICINA_CONTABLE_CLI') <> nil) and
    (ADataSet.FindField('CODIGO_ORGANO_GESTOR_CLI') <> nil) and
    (ADataSet.FindField('CODIGO_UNIDAD_TRAMITADORA_CLI') <> nil);
  bCamposPersonaDisponibles :=
    (ADataSet.FindField('NOMBRE_PERSONA_CLIENTE_CLI') <> nil) and
    (ADataSet.FindField('APELLIDOS_PERSONA_CLIENTE_CLI') <> nil);
  if (bCamposDir3Disponibles or bCamposPersonaDisponibles) and
     (sCliente <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := ConexionPrincipal;
      if bCamposDir3Disponibles then
      begin
        Qry.SQL.Text :=
          ' UPDATE fza_clientes ' +
          ' SET CODIGO_OFICINA_CONTABLE_CLI = :OFICINA, ' +
          '     CODIGO_ORGANO_GESTOR_CLI = :ORGANO, ' +
          '     CODIGO_UNIDAD_TRAMITADORA_CLI = :UNIDAD ' +
          ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
        Qry.ParamByName('OFICINA').AsString :=
          ADataSet.FieldByName('CODIGO_OFICINA_CONTABLE_CLI').AsString;
        Qry.ParamByName('ORGANO').AsString :=
          ADataSet.FieldByName('CODIGO_ORGANO_GESTOR_CLI').AsString;
        Qry.ParamByName('UNIDAD').AsString :=
          ADataSet.FieldByName('CODIGO_UNIDAD_TRAMITADORA_CLI').AsString;
        Qry.ParamByName('CLIENTE').AsString := sCliente;
        Qry.ExecSQL;
      end;
      if bCamposPersonaDisponibles then
      begin
        Qry.SQL.Text :=
          ' UPDATE fza_clientes ' +
          ' SET NOMBRE_PERSONA_CLIENTE_CLI = :NOMBRE_PERSONA, ' +
          '     APELLIDOS_PERSONA_CLIENTE_CLI = :APELLIDOS_PERSONA ' +
          ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
        Qry.ParamByName('NOMBRE_PERSONA').AsString :=
          ADataSet.FieldByName('NOMBRE_PERSONA_CLIENTE_CLI').AsString;
        Qry.ParamByName('APELLIDOS_PERSONA').AsString :=
          ADataSet.FieldByName('APELLIDOS_PERSONA_CLIENTE_CLI').AsString;
        Qry.ParamByName('CLIENTE').AsString := sCliente;
        Qry.ExecSQL;
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmClientes.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  GuardarParametrosEDocCliente(DataSet);
end;

procedure TdmClientes.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  if (unqryFacturasClientes.RecordCount > 0) then
    if not ( Application.MessageBox( 'El cliente tiene facturas emitidas, ' +
                                   ' ¿Desea realmente borrar el registro?',
                                   'Mensaje Advertencia',
                                   MB_YESNO ) = ID_YES ) then
      Abort;
end;

procedure TdmClientes.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('RAZON_SOCIAL_CLI').AsString) = '') then
    Abort;
  (* if ((unqryRetenciones.State = dsInsert) or
      (unqryRetenciones.State = dsEdit)) then
         unqryRetenciones.Post; *)
  with unqryTablaG do
  begin
    if (Trim(FindField('RAZON_SOCIAL_CLI').AsString) = '') then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                        'para el campo Razón Social de Cliente',
               [FindField('RAZON_SOCIAL_CLI').AsString]);
    end
    else
      GetCodigoAutoCliente;
  end;
end;
initialization
  ForceReferenceToClass(TdmClientes);
end.
