{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataArticulos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn,  cxListView, Vcl.Forms, vcl.dialogs,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils;

type
  TdmArticulos = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryFamiliaArticulos: TUniQuery;
    dsFamiliaArticulos: TDataSource;
    unqryTarifasArticulos: TUniQuery;
    dsTarifasArticulos: TDataSource;
    unqryProveedoresArticulos: TUniQuery;
    dsProveedoresArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    unqryProveedores: TUniQuery;
    dsProveedores: TDataSource;
    unqryTiposIVA: TUniQuery;
    dsTiposIVA: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    unqryVariaciones: TUniQuery;
    dsVariaciones: TDataSource;
    unqryVariacionesArticulos: TUniQuery;
    dsVariacionesArticulos: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoArticulo;
    function ArticuloTieneProvPrin(sArt:String):Boolean;
    procedure CopiarProveedoraArticulo(dtProveedores:TDataset);
    function GetDefaultFamilia:String;
    procedure FillTarifas(lst:TcxListView);
  end;

//var
//  dmArticulos: TdmArticulos;

implementation

uses
  inMtoArticulos,
  inLibGlobalVar,
  inLibtb;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmArticulos.ArticuloTieneProvPrin(sArt:String):Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM vi_articulos_proveedores ' +
                       ' WHERE CODIGO_ARTICULO = :CODIGO_ARTICULO' +
                       '   AND ESPROVEEDORPRINCIPAL = ' + QuotedStr('S');
  unqrySol.ParamByName('CODIGO_ARTICULO').AsString := sArt;
  unqrySol.Open;
  if (unqrySol.RecordCount > 0) then
  begin
    Result := True
  end
  else
    Result := False;
  unqrySol.Close;
  FreeAndNil(unqrySol);
end;

procedure TdmArticulos.unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
begin
  inherited;
  with unqryProveedoresArticulos do
  if (unqryProveedoresARticulos.State = dsInsert) then
    if Trim(FindField('ESPROVEEDORPRINCIPAL').AsString) = 'S' then
    begin
      if (ArticuloTieneProvPrin(FindField('CODIGO_ARTICULO').AsString)) then
        raise ERangeError.CreateFmt('%s ya tiene un proveedor principal ' +
                                    'asociado a este Artículos.',
                                       [FindField('CODIGO_ARTICULO').AsString]);
      Abort;
    end;
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmArticulos.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  with qryBorrarLineas do
  begin
//  if not( Application.MessageBox(  '¿Desea borrar también tarifas y ' +
//                                   'proveedores de la ficha del artículo?',
//                                   'Mensaje Advertencia',
//                                   MB_YESNO ) = ID_YES ) then
//    begin
    qryBorrarLineas := TUniQuery.Create(Self);
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'DELETE ' +
                '  FROM fza_articulos_proveedores ' +
                ' WHERE CODIGO_ARTICULO_ARTICULO_PROVEEDOR = :Articulo ;';
    Params.ParamByName('Articulo').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
    ExecSQL;
    SQL.Text := 'DELETE ' +
                '  FROM fza_articulos_tarifas ' +
                ' WHERE CODIGO_ARTICULO_TARIFA = :Articulo ;';
    Params.ParamByName('Articulo').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
    ExecSQL;
    Free;
  end;
//  end;
end;

procedure TdmArticulos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_ARTICULO').AsString := '0';
  unqryTablaG.FindField('ACTIVO_ARTICULO').AsString := 'S';
  unqryTablaG.FindField('TIPOIVA_ARTICULO').AsString := 'N';
  unqryTablaG.FindField('TIPO_CANTIDAD_ARTICULO').AsString := 'Uds.';
  unqryTablaG.FindField('ESACTIVO_FIJO_ARTICULO').AsString := 'N';
  unqryTablaG.FindField('ORDEN_ARTICULO').AsInteger := 0;
  unqryTablaG.FindField('CODIGO_FAMILIA_ARTICULO').AsString :=
                                                              GetDefaultFamilia;
end;

procedure TdmArticulos.CopiarProveedoraArticulo(dtProveedores: TDataset);
begin
  with unqryProveedoresArticulos do
  begin
    if (State = dsBrowse) then
      Edit;
    FindField('CODIGO_PROVEEDOR').AsString :=
                           dtProveedores.FindField('CODIGO_PROVEEDOR').AsString;
    FindField('RAZONSOCIAL_PROVEEDOR').AsString :=
                      dtProveedores.FindField('RAZONSOCIAL_PROVEEDOR').AsString;
    if RecordCount = 0 then
      FindField('ESPROVEEDORPRINCIPAL').AsString := 'S'
    else
      FindField('ESPROVEEDORPRINCIPAL').AsString := 'N';
    Post;
  end;
end;

procedure TdmArticulos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryFamiliaArticulos.Connection := oConn;
  unstrdprcContador.Connection := oConn;
  unqryPerfiles.Connection := oConn;
  unqryTarifasArticulos.Connection := oConn;
  unqryProveedoresArticulos.Connection := oConn;
  unqryLinFacturasArticulos.Connection := oConn;
  unqryProveedores.Connection := oConn;
  unqryTiposIVA.Connection := oConn;
  unqryTarifas.Connection := oConn;
  unqryLinFacturasArticulos.MasterSource :=
                                      (Self.Owner as TfrmMtoArticulos).dsTablaG;
  unqryTarifasArticulos.MasterSource :=
                                      (Self.Owner as TfrmMtoArticulos).dsTablaG;
  unqryProveedoresArticulos.MasterSource :=
                                      (Self.Owner as TfrmMtoArticulos).dsTablaG;
  unqryTiposIVA.Open;
  unqryFamiliaArticulos.Open;
  unqryTarifasArticulos.Open;
  unqryProveedoresArticulos.Open;
  unqryLinFacturasArticulos.Open;
end;

procedure TdmArticulos.FillTarifas(lst: TcxListView);
var
  Itm: TListItem;
begin
  lst.Clear;
  with unqryTarifas do
  begin
    if ContainsText(SQL.Text, ':CODIGO_ARTICULO') then
      ParamByName('CODIGO_ARTICULO').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ARTICULO').AsString;
    Open;
    First;
    while not (Eof) do
    begin
      Itm := lst.Items.Add;
      Itm.Caption := FindField('CODIGO_TARIFA').AsString;
      Itm.SubItems.Add(FindField('NOMBRE_TARIFA').AsString);
      if FieldByName('ESDEFAULT_TARIFA').AsString = 'S' then
        Itm.Checked := True;
      Next;
    end;
    Close;
  end;
end;

procedure TdmArticulos.GetCodigoAutoArticulo;
begin
  if unqryTablaG.FindField('CODIGO_ARTICULO').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'AR';
      ExecProc;
      unqryTablaG.FindField('CODIGO_ARTICULO').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if unqryTablaG.FindField('ORDEN_ARTICULO').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'AO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_ARTICULO').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

function TdmArticulos.GetDefaultFamilia: String;
 var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'SELECT CODIGO_FAMILIA ' +
                       '  FROM vi_articulos_familias_list ' +
                       ' WHERE ESDEFAULT_FAMILIA = ' + QuotedStr('S');
  unqrySol.Open;
  if unqrySol.RecordCount = 0 then
    Result := '0'
  else
    Result := unqrySol.Fields[0].AsString;
  unqrySol.Close;
  FreeAndNil(unqrySol);
end;

procedure TdmArticulos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    if Trim(FindField('DESCRIPCION_ARTICULO').AsString) = '' then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Descripción de Artículos',
               [FindField('DESCRIPCION_ARTICULO').AsString]);
        Abort;
    end
    else
      GetCodigoAutoArticulo;
  end;
end;

procedure TdmArticulos.unqryTarifasArticulosBeforePost(DataSet: TDataSet);
var
  unqrySol:TUniQuery;
begin
  inherited;
  with unqryTarifasArticulos do
  begin
    if ((unqryTablaG.State = dsInsert) or (unqryTablaG.State = dsEdit)) then
      unqryTablaG.Post;
    if State = dsInsert then
    begin
      FieldByName('CODIGO_UNICO_TARIFA').Required := False;
      FieldByName('CODIGO_UNICO_TARIFA').AutoGenerateValue := arAutoInc;
    end;
    unqrySol := TUniQuery.Create(nil);
    unqrySol.Connection := oConn;
    unqrySol.SQL.Text := 'SELECT * ' +
                         '  FROM fza_articulos_tarifas ' +
                         ' WHERE CODIGO_ARTICULO_TARIFA = :CODIGO_ARTICULO' +
                         '   AND CODIGO_TARIFA = :CODIGO_TARIFA';
    unqrySol.ParamByName('CODIGO_ARTICULO').AsString :=
                            unqryTablaG.FindField('CODIGO_ARTICULO').AsString;
    unqrySol.ParamByName('CODIGO_TARIFA').AsString :=
                                          FindField('CODIGO_TARIFA').AsString;
    unqrySol.Open;
    if not(ExistePeriodoUnico(unqrySol,
                              FindField('FECHA_DESDE_TARIFA'),
                              FindField('FECHA_HASTA_TARIFA')))
    then
    begin
      ShowMessageFmt('No se pueden grabar dos precios para una tarifa ' +
                     'activa en fechas concurrentes para el artículo %s',
                     [FindField('CODIGO_ARTICULO_TARIFA').AsString]);
      Abort;
    end;
    if ((unqryTarifasArticulos.State = dsInsert) or
        (unqryTarifasArticulos.State = dsEdit)) then
      oDmConn.ActualizarUserTimeModif(DataSet);
  end;
end;

initialization
  ForceReferenceToClass(TdmArticulos);
end.
