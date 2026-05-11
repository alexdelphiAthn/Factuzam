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
  Datasnap.DBClient, Datasnap.Provider, frxClass, frxDBSet;

type
  TdmClientes = class(TdmBase)
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
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
  private
    { Private declarations }
  public
    procedure GetCodigoAutoCliente;
    procedure CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                    sCodCli:String);
  end;

//var
//  dmClientes2: TdmClientes;

implementation

uses
  inMtoClientes, inLibGlobalVar, inLibtb;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmClientes.CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer;
                                            sCodCli:String);
var
  i:Integer;
begin
  unqryCliPrint.Connection := oConn;
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
//  unstrdprcContador.Connection := oConn;
  unqryFormaPago.Connection := oConn;
  unqryPerfiles.Connection := oConn;
  unqryTarifas.Connection := oConn;
  unqryFacturasClientes.Connection := oConn;
  unqryFacturasLineasClientes.Connection := oConn;
  unqryPaises.Connection := oConn;
  var LForm := GetOwnerForm<TfrmMtoClientes>;
  unqryFacturasClientes.MasterSource := LForm.dsTablaG;
  unqryFacturasLineasClientes.MasterSource := LForm.dsTablaG;
  unqryDepositos.MasterSource := LForm.dsTablaG;
  unqryPaises.Open;
  unqryFacturasClientes.Open;
  unqryFacturasLineasClientes.Open;
  unqryTarifas.Open;
  unqryFormaPago.Open;
  unqryDepositos.Open;
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
                                                 ObtenerSiguienteContador('CL');
  end;
  if (unqryTablaG.FindField('ORDEN_CLI').AsString = '0') then
  begin
    unqryTablaG.FindField('ORDEN_CLI').AsString :=
                                                 ObtenerSiguienteContador('CO');
  end;
end;

procedure TdmClientes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(unqryTablaG, 'fza_clientes');
  unqryTablaG.FindField('CODIGO_FP_CLI').AsString :=
                                                GetDefaultValue('fza_formapago',
                                                             'CODIGO_FP_FP',
                                                         'ESDEFAULT_FORMA_PAGO_FP');
  unqryTablaG.FindField('TARIFA_ARTICULO_CLI').AsString :=
                                                  GetDefaultValue('fza_tarifas',
                                                                'CODIGO_TAR_ARTTAR',
                                                            'ESDEFAULT_TAR');
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
        Abort;
    end
    else
      GetCodigoAutoCliente;
  end;
end;
initialization
  ForceReferenceToClass(TdmClientes);
end.
