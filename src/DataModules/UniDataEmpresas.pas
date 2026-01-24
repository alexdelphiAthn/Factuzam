{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
  end;

//var
//  dmEmpresas: TdmEmpresas;

implementation

uses
  inLibtb, inLibGlobalVar, inMtoEmpresas;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmEmpresas.unqryRetencionesAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryRetenciones.FindField('CODIGO_RETENCION').AsString := '0';
end;

procedure TdmEmpresas.unqryRetencionesBeforeInsert(DataSet: TDataSet);
begin
  inherited;
    if ( (unqryTablaG.State = dsInsert) and
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
  if ( (unqryTablaG.State = dsInsert) and
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  with unqryRetenciones do
  begin
    if ((FindField('PORCENRETENCION_RETENCION').AsInteger <= 0) or
        (FindField('PORCENRETENCION_RETENCION').IsNull)) then
    begin
      raise ERangeError.CreateFmt('%d no es un valor válido ' +
                                                        ' para %% de Retención',
             [FindField('PORCENRETENCION_RETENCION').AsInteger]);
      bSinErrores := False;
    end;
    if (bSinErrores) then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM vi_empresas_retenciones ' +
                           ' WHERE CODIGO_EMPRESA_RETENCION = :CODIGO_EMPRESA';
      unqrySol.ParamByName('CODIGO_EMPRESA').AsString :=
                                 FindField('CODIGO_EMPRESA_RETENCION').AsString;
      unqrySol.Open;
    end;
    if ((bSinErrores) and  not(ExistePeriodoUnico(
                                            unqrySol,
                                            FindField('FECHA_DESDE_RETENCION'),
                                            FindField('FECHA_HASTA_RETENCION')))
       ) then
    begin
      raise ERangeError.CreateFmt('No se pueden grabar dos porcentajes ' +
                                ' activos en la misma fecha para la empresa %s',
                              [FindField('CODIGO_EMPRESA_RETENCION').AsString]);
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
  Dataset.FindField('CODIGO_SERIE').AsString := '0';
end;

procedure TdmEmpresas.unqrySeriesBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  bSinErrores:Boolean;
//  sCodigoSerie:String;
begin
  inherited;
  if ( (unqryTablaG.State = dsInsert) and
       (unqryTablaG.State = dsEdit)
   ) then
    unqryTablaG.Post;
  bSinErrores := True;
  with unqrySeries do
  begin
    if (FindField('SERIE_SERIE').AsString = '') or
       (FindField('SERIE_SERIE').IsNull) or
       (SimbolosProhibidos(FindField('SERIE_SERIE').AsString)) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                                     ' para serie por Empresa ',
             [FindField('SERIE_SERIE').AsString]);
      bSinErrores := False;
    end;
//    if (State = dsEdit) then
//      sCodigoSerie := FindField('CODIGO_SERIE').AsString
//    else
//      sCodigoSerie := '';
    if (bSinErrores) then
    begin
      unqrySol := TUniQuery.Create(nil);
      unqrySol.Connection := oConn;
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM vi_empresas_series ' +
                           ' WHERE CODIGO_EMPRESA_SERIE = :CODIGO_EMPRESA';
//      if (sCodigoSerie <> '') then
//        unqrySol.SQL.Text := unqrySol.SQL.Text + ' AND CODIGO_SERIE <> ' +
//                                                                 sCodigoSerie;
      unqrySol.ParamByName('CODIGO_EMPRESA').AsString :=
                                 FindField('CODIGO_EMPRESA_SERIE').AsString;
      unqrySol.Open;
    end;
    if ((bSinErrores) and  not(ExistePeriodoUnico(
                                            unqrySol,
                                            FindField('FECHA_DESDE_SERIE'),
                                            FindField('FECHA_HASTA_SERIE')))
       ) then
    begin
      raise ERangeError.CreateFmt('No se pueden grabar dos series ' +
                                ' en la misma fecha para la empresa %s',
                              [FindField('CODIGO_EMPRESA_RETENCION').AsString]);
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
                ' WHERE CODIGO_EMPRESA_RETENCION = :Empresa ;';
    Params.ParamByName('Empresa').AsString :=
                             unqryTablaG.FieldByName('CODIGO_EMPRESA').AsString;
    ExecSQL;
    SQL.Text := 'DELETE ' +
                '  FROM fza_empresas_series ' +
                ' WHERE CODIGO_EMPRESA_SERIE = :Empresa ;';
    Params.ParamByName('Empresa').AsString :=
                             unqryTablaG.FieldByName('CODIGO_EMPRESA').AsString;
    ExecSQL;
    Free;
  end;
end;

procedure TdmEmpresas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(unqryTablaG, 'fza_empresas');
  unqryTablaG.FindField('GRUPO_ZONA_IVA_EMPRESA').AsString :=
       GetDefaultValue('vi_ivas_grupos', 'GRUPO_ZONA_IVA','ESDEFAULT_ZONA_IVA');
end;

procedure TdmEmpresas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryRetenciones.Connection            := oConn;
  unqrySeries.Connection                 := oConn;
  unqryIvas.Connection                   := oConn;
  unqryFacturasEmpresas.Connection       := oConn;
  unqryFacturasLineasEmpresas.Connection := oConn;
  unqryPaises.Connection                 := oConn;
  unqryFacturasEmpresas.MasterSource :=
                                       (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqryFacturasLineasEmpresas.MasterSource :=
                                       (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqryRetenciones.MasterSource    :=  (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqrySeries.MasterSource         :=  (GetOwnerForm<TfrmMtoEmpresas>).dsTablaG;
  unqryPaises.Open;
  unqryFacturasEmpresas.Open;
  unqryFacturasLineasEmpresas.Open;
  unqryIvas.Open;
  unqryRetenciones.Open;
  unqrySeries.Open;
end;

procedure TdmEmpresas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMPRESA').AsString = '0' then
  begin
      unqryTablaG.FindField('CODIGO_EMPRESA').AsString :=
                                                 ObtenerSiguienteContador('EM');
  end;
  if unqryTablaG.FindField('ORDEN_EMPRESA').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_EMPRESA').AsString :=
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
  bError := False;
  if ((unqryRetenciones.State = dsInsert) or
      (unqryRetenciones.State = dsEdit)) then
         unqryRetenciones.Post;
  with unqryTablaG do
  begin
    sCodigoEmpresa := Trim(FindField('CODIGO_EMPRESA').AsString);
    sRazonSocial := Trim(FindField('RAZONSOCIAL_EMPRESA').AsString);
    if ((sRazonSocial = '') or (SimbolosProhibidos(sRazonSocial))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                        'para el campo Razón Social de Empresa',
                                                                [sRazonSocial]);
      bError := True;
    end;
    if ((sCodigoEmpresa = '') or (SimbolosProhibidos(sCodigoEmpresa))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                              'para el campo Código de Empresa',
                                                              [sCodigoEmpresa]);
      bError := True;
    end;
    if bError then
      Abort
    else
      GetCodigoAutoEmpresa;
  end;
end;

procedure TdmEmpresas.GetCodigoAutoRetencion;
begin
  if unqryRetenciones.FindField('CODIGO_RETENCION').AsString = '0' then
  begin
//    with unstrdprcContador do
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
//      ParamByName('pUSUARIO_MODIF').AsString := oUser;
//      ParamByName('ptipodoc').AsString :=  'RT';
//      ExecProc;
      unqryRetenciones.FindField('CODIGO_RETENCION').AsString :=
                                                 ObtenerSiguienteContador('RT');
    end;
//  end;
end;

procedure TdmEmpresas.GetCodigoAutoSerie;
begin
  if unqrySeries.FindField('CODIGO_SERIE').AsString = '0' then
  begin
//    with unstrdprcContador do
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
//      ParamByName('pUSUARIO_MODIF').AsString := oUser;
//      ParamByName('ptipodoc').AsString :=  'ES';
//      ExecProc;
      unqrySeries.FindField('CODIGO_SERIE').AsString :=
                                                ObtenerSiguienteContador('ES');
//    end;
  end;

end;

//function TdmEmpresas.GetZonaDefault: String;
//var
//  unqrySol:TUniQuery;
//begin
//  unqrySol := TUniQuery.Create(Self);
//  unqrySol.Connection := oConn;
//  unqrySol.SQL.Text := 'SELECT GRUPO_ZONA_IVA FROM vi_ivas_grupos ' +
//                       ' WHERE ESDEFAULT_ZONA_IVA = ' + QuotedStr('S');
//  unqrySol.Open;
//  if unqrySol.RecordCount = 0 then
//    Sleep(0)
//  //   MessageDlg('Empresa: #' + VarToStr(e.EditingValue) + '# no existe')
//   else
//      Result := unqrySol.Fields[0].AsString;
//  unqrySol.Close;
//  FreeAndNil(unqrySol);
//end;




initialization
  ForceReferenceToClass(TdmEmpresas);
end.
