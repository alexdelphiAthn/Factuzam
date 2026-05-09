{*******************************************************}
{                                                       }
{       FactuZam - Datos de Albaranes                   }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit UniDataAlbaranes;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal,
  frxClass, frxDBSet;

type
  TdmAlbaranes = class(TdmBase)
    unqryAlbaranesLineas: TUniQuery;
    dsAlbaranesLineas:    TDataSource;
    unqryEmpDataAlb:      TUniQuery;
    unqryCliDataAlb:      TUniQuery;
    unqryArtDataLinAlb:   TUniQuery;
    unstrdprcGetContadorAlbaran: TUniStoredProc;
    fxdsPrintAlb:    TfrxDBDataset;
    fxdstPrintLinAlb:TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
  public
    procedure GetCodigoAutoAlbaran;
    procedure CalcularTotalesAlbaran;
    procedure CopiarEmpresaaAlbaran(DataSet: TDataSet);
    procedure CopiarClienteaAlbaran(DataSet: TDataSet);
    procedure OpenTables;
  end;

var
  dmAlbaranes: TdmAlbaranes;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmAlbaranes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := inLibGlobalVar.oConn;
  unqryAlbaranesLineas.Connection  := inLibGlobalVar.oConn;
  unqryEmpDataAlb.Connection       := inLibGlobalVar.oConn;
  unqryCliDataAlb.Connection       := inLibGlobalVar.oConn;
  unqryArtDataLinAlb.Connection    := inLibGlobalVar.oConn;
  unstrdprcGetContadorAlbaran.Connection := inLibGlobalVar.oConn;
end;

procedure TdmAlbaranes.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesLineas) and unqryAlbaranesLineas.Active then
    unqryAlbaranesLineas.Close;
  inherited;
end;

procedure TdmAlbaranes.OpenTables;
begin
  if not unqryAlbaranesLineas.Active then unqryAlbaranesLineas.Open;
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
  CalcularTotalesAlbaran;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesLineas do
  begin
    FieldByName('NUMERO_ALB_ALBLIN').AsString :=
                                  unqryTablaG.FieldByName('NUMERO_ALB').AsString;
    FieldByName('SERIE_ALB_ALBLIN').AsString  :=
                                  unqryTablaG.FieldByName('SERIE_ALB').AsString;
    FieldByName('CANTIDAD_ALBLIN').AsFloat := 1;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesLineas do
  begin
    if (FindField('CANTIDAD_ALBLIN') <> nil) and
       (FindField('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN') <> nil) and
       (FindField('TOTAL_ALBLIN') <> nil) then
      FieldByName('TOTAL_ALBLIN').AsFloat :=
        FieldByName('CANTIDAD_ALBLIN').AsFloat *
        FieldByName('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN').AsFloat;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaran;
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
    ParamByName('pserie').AsString    := unqryTablaG.FieldByName('SERIE_ALB').AsString;
    ParamByName('ptipodoc').AsString  := 'AL';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
                                  unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_ALB').AsString :=
                                                  ParamByName('pcont').AsString;
  end;
end;

procedure TdmAlbaranes.CalcularTotalesAlbaran;
var
  fBase, fIva, fTotal, fPorIva: Double;
  bk: TBookmark;
begin
  if not unqryAlbaranesLineas.Active then Exit;
  fBase := 0; fIva := 0;
  bk := unqryAlbaranesLineas.GetBookmark;
  try
    unqryAlbaranesLineas.DisableControls;
    unqryAlbaranesLineas.First;
    while not unqryAlbaranesLineas.Eof do
    begin
      fPorIva := unqryAlbaranesLineas.FieldByName('PORCENTAJE_IVA_ALBLIN').AsFloat / 100;
      fTotal  := unqryAlbaranesLineas.FieldByName('CANTIDAD_ALBLIN').AsFloat *
                 unqryAlbaranesLineas.FieldByName('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN').AsFloat;
      fBase := fBase + fTotal;
      fIva  := fIva  + (fTotal * fPorIva);
      unqryAlbaranesLineas.Next;
    end;
  finally
    if unqryAlbaranesLineas.BookmarkValid(bk) then
      unqryAlbaranesLineas.GotoBookmark(bk);
    unqryAlbaranesLineas.FreeBookmark(bk);
    unqryAlbaranesLineas.EnableControls;
  end;
  if (unqryTablaG.State = dsBrowse) then
    unqryTablaG.Edit;
  if unqryTablaG.FindField('TOTAL_BASES_ALB') <> nil then
    unqryTablaG.FieldByName('TOTAL_BASES_ALB').AsFloat := fBase;
  if unqryTablaG.FindField('TOTAL_IMPUESTOS_ALB') <> nil then
    unqryTablaG.FieldByName('TOTAL_IMPUESTOS_ALB').AsFloat := fIva;
  if unqryTablaG.FindField('TOTAL_LIQUIDO_ALB') <> nil then
    unqryTablaG.FieldByName('TOTAL_LIQUIDO_ALB').AsFloat := fBase + fIva;
end;

procedure TdmAlbaranes.CopiarEmpresaaAlbaran(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_EMP_ALB').AsString             := DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_ALB').AsString   := DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_ALB').AsString            := DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_ALB').AsString          := DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_ALB').AsString          := DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_ALB').AsString     := DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_ALB').AsString     := DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_ALB').AsString      := DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_ALB').AsString      := DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_ALB').AsString  := DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_ALB').AsString     := DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_ALB').AsString     := DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_ALB').AsString := DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
  end;
end;

procedure TdmAlbaranes.CopiarClienteaAlbaran(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_CLI_ALB').AsString          := DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_ALB').AsString:= DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_ALB').AsString         := DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_ALB').AsString       := DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_ALB').AsString       := DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_ALB').AsString  := DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_ALB').AsString  := DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_ALB').AsString   := DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_ALB').AsString   := DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_ALB').AsString := DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_ALB').AsString  := DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_ALB').AsString  := DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_ALB').AsString:= DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_ALB').AsString:= DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_ALB').AsString :=
                            DataSet.FindField('ESINTRACOMUNITARIO_CLI').AsString;
    FindField('TARIFA_ARTICULO_CLIENTE_ALB').AsString :=
                            DataSet.FindField('TARIFA_ARTICULO_CLI').AsString;
  end;
end;

end.
