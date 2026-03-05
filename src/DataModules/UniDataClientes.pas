{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
                            ' where CODIGO_CLIENTE = :CODIGO';
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
    cdsEtiquetas.FieldByName('CODIGO_CLIENTE').AsString := '0';
    cdsEtiquetas.FieldByName('RAZONSOCIAL_CLIENTE').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTEMODIF').AsString := '';
    cdsEtiquetas.FieldByName('INSTANTEALTA').AsString := '';
    cdsEtiquetas.FieldByName('USUARIOMODIF').AsString := '';
    cdsEtiquetas.FieldByName('USUARIOALTA').AsString := '';
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
  unqryPaises.Open;
  unqryFacturasClientes.Open;
  unqryFacturasLineasClientes.Open;
  unqryTarifas.Open;
  unqryFormaPago.Open;
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
end;

procedure TdmClientes.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLIENTE').AsString = '0') then
  begin
    unqryTablaG.FindField('CODIGO_CLIENTE').AsString :=
                                                 ObtenerSiguienteContador('CL');
  end;
  if (unqryTablaG.FindField('ORDEN_CLIENTE').AsString = '0') then
  begin
    unqryTablaG.FindField('ORDEN_CLIENTE').AsString :=
                                                 ObtenerSiguienteContador('CO');
  end;
end;

procedure TdmClientes.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(unqryTablaG, 'fza_clientes');
  unqryTablaG.FindField('CODIGO_FORMA_PAGO_CLIENTE').AsString :=
                                                GetDefaultValue('fza_formapago',
                                                             'CODIGO_FORMAPAGO',
                                                         'ESDEFAULT_FORMAPAGO');
  unqryTablaG.FindField('TARIFA_ARTICULO_CLIENTE').AsString :=
                                                  GetDefaultValue('fza_tarifas',
                                                                'CODIGO_TARIFA',
                                                            'ESDEFAULT_TARIFA');
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
    if (Trim(FindField('RAZONSOCIAL_CLIENTE').AsString) = '') then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                        'para el campo Razón Social de Cliente',
               [FindField('RAZONSOCIAL_CLIENTE').AsString]);
        Abort;
    end
    else
      GetCodigoAutoCliente;
  end;
end;
initialization
  ForceReferenceToClass(TdmClientes);
end.
