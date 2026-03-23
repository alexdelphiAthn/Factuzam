{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataFamilias;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn, Windows, Dialogs, Variants;

type
  TdmFamilias = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosFamilias: TUniQuery;
    dsArticulosFamilias: TDataSource;
    unqrySubFamilias: TUniQuery;
    dsSubFamilias: TDataSource;
    unqryFamiliasAtributos: TUniQuery;
    dsFamiliasAtributos: TDataSource;
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryFamiliasAtributosAfterPost(DataSet: TDataSet);
    procedure unqryFamiliasAtributosAfterInsert(DataSet: TDataSet);
    procedure unqryFamiliasAtributosBeforePost(DataSet: TDataSet);
  private
    function PropiedadExisteEnFamilia(sPropiedad, sFamilia:String):Boolean;
  public
    procedure GetCodigoAutoFamilia;
    //procedure GetCodigoAutoRetencion;
  end;

//var
//  dmFamilias: TdmFamilias;

implementation

uses
  inMtoFamilias, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFamilias.unqryFamiliasAtributosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryFamiliasAtributos.FindField('ES_REQUERIDO').AsString := 'N';
end;

procedure TdmFamilias.unqryFamiliasAtributosAfterPost(DataSet: TDataSet);
begin
  inherited;
  unqryFamiliasAtributos.Refresh;
end;

procedure TdmFamilias.unqryFamiliasAtributosBeforePost(DataSet: TDataSet);
var
  CampoPropiedad: TField;
  DebeValidar: Boolean;
begin
  // Evitamos llamar a FindField varias veces guardándolo en una variable
  CampoPropiedad := unqryFamiliasAtributos.FindField('CODIGO_PROPIEDAD');
  DebeValidar := False;

  // 1. Si es un registro nuevo, validamos siempre
  if DataSet.State = dsInsert then
    DebeValidar := True
  // 2. Si estamos editando, validamos SOLO si el usuario modificó el campo
  else if DataSet.State = dsEdit then
  begin
    // VarToStr previene errores si el OldValue era Null (requiere 'uses Variants')
    if CampoPropiedad.AsString <> VarToStr(CampoPropiedad.OldValue) then
      DebeValidar := True;
  end;

  // 3. Ejecutamos tu validación si se dio alguna de las dos condiciones
  if DebeValidar then
  begin
    if PropiedadExisteEnFamilia(CampoPropiedad.AsString,
                                unqryTablaG.FindField('CODIGO_FAMILIA').AsString) then
    begin
      ShowMessage('Propiedad Duplicada');
      Abort;
    end;
  end;
end;

procedure TdmFamilias.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FAMILIA').AsString := '0';
  unqryTablaG.FindField('ORDEN_FAMILIA').AsString := '0';
  unqryTablaG.FindField('ACTIVO_FAMILIA').AsString := 'S';
  unqryTablaG.FindField('ESDEFAULT_FAMILIA').AsString := 'N';
end;

procedure TdmFamilias.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := oConn;
  unstrdprcContador.Connection := oConn;
  unqryArticulosFamilias.Connection := oConn;
  unqrySubFamilias.Connection := oConn;
  unqryArticulosFamilias.MasterSource :=
                                       (GetOwnerForm<TfrmMtoFamilias>).dsTablaG;
  unqryArticulosFamilias.Open;
  unqrySubFamilias.Open;
  unqryPropiedades.Open;
end;

procedure TdmFamilias.GetCodigoAutoFamilia;
begin
  if (unqryTablaG.FindField('CODIGO_Familia').AsString = '0') then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'FA';
      ExecProc;
      unqryTablaG.FindField('CODIGO_Familia').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if (unqryTablaG.FindField('ORDEN_FAMILIA').AsString = '0') then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'FO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_FAMILIA').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

function TdmFamilias.PropiedadExisteEnFamilia(sPropiedad,
                                              sFamilia:String): Boolean;
begin
  var unqryFamProp:TUniQuery := TUniQuery.Create(nil);
  try
    unqryFamProp.Connection := oConn;
    unqryFamProp.sql.Text := 'SELECT CODIGO_PROPIEDAD '+
                             '  FROM fza_familias_atributos ' +
                             ' WHERE CODIGO_FAMILIA = :CODIGO_FAMILIA ' +
                             '   AND CODIGO_PROPIEDAD = :CODIGO_PROPIEDAD';
    unqryFamProp.ParamByName('CODIGO_FAMILIA').AsString := sFamilia;
    unqryFamProp.ParamByName('CODIGO_PROPIEDAD').AsString := sPropiedad;
    unqryFamProp.Open;
    Result := (unqryFamProp.RecordCount > 0);
  finally
    unqryFamProp.Free;
  end;
end;

procedure TdmFamilias.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
    with unqryTablaG do
  begin
    if Trim(FindField('NOMBRE_FAMILIA').AsString) = '' then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Nombre de Familias',
               [FindField('NOMBRE_FAMILIA').AsString]);
      Abort;
    end
    else
    if (FindField('CODIGO_FAMILIA').AsString =
        FindField('CODIGO_SUBFAMILIA').AsString) then
    begin
      raise ERangeError.CreateFmt('%s no puede ser padre e hijo a la vez. ' +
                                       'Revise campo Familia Padre',
               [FindField('CODIGO_SUBFAMILIA').AsString]);
      Abort;
    end
    else
      if (FindField('CODIGO_FAMILIA').AsString = '0') then
        GetCodigoAutoFamilia;
  end;
end;
initialization
  ForceReferenceToClass(TdmFamilias);
end.
