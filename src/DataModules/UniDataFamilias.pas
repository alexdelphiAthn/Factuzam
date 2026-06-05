{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFamilias                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de familias de artículos.                                     }
{    Queries de fza_familias, subfamilias, atributos por familia y artículos   }
{    relacionados.                                                             }
{******************************************************************************}
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

implementation

uses
  inMtoFamilias, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFamilias.unqryFamiliasAtributosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryFamiliasAtributos.FindField('ESREQUERIDO_FA').AsString := 'N';
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
  CampoPropiedad := unqryFamiliasAtributos.FindField('CODIGO_PROP_ARTPROP');
  DebeValidar := False;

  // 1. Si es un registro nuevo, validamos siempre
  if DataSet.State = dsInsert then
    DebeValidar := True
  // 2. Si estamos editando, validamos SOLO si el usuario modificó el campo
  else if DataSet.State = dsEdit then
  begin
    // VarToStr previene errores si el OldValue era Null (requiere 'uses
    // Variants')
    if CampoPropiedad.AsString <> VarToStr(CampoPropiedad.OldValue) then
      DebeValidar := True;
  end;

  // 3. Ejecutamos tu validación si se dio alguna de las dos condiciones
  if DebeValidar then
  begin
    if PropiedadExisteEnFamilia(CampoPropiedad.AsString,
                                unqryTablaG.FindField(
                                  'CODIGO_FAM_FAM').AsString) then
    begin
      ShowMessage('Propiedad Duplicada');
      Abort;
    end;
  end;
end;

procedure TdmFamilias.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FAM_FAM').AsString := '0';
  unqryTablaG.FindField('ORDEN_FAM').AsString := '0';
  unqryTablaG.FindField('ESACTIVO_FAM').AsString := 'S';
  unqryTablaG.FindField('ESDEFAULT_FAM').AsString := 'N';
  // PAD_ART_FAM es NOT NULL en BBDD; sin valor el INSERT manda NULL
  // explicito y falla (el DEFAULT solo aplica si se omite la columna)
  unqryTablaG.FindField('PAD_ART_FAM').AsInteger := 5;
end;

procedure TdmFamilias.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := oConn;
  unstrdprcContador.Connection := oConn;
  unqryArticulosFamilias.Connection := oConn;
  unqrySubFamilias.Connection := oConn;
  unqryFamiliasAtributos.Connection := oConn;
  unqryArticulosFamilias.MasterSource :=
                                       (GetOwnerForm<TfrmMtoFamilias>).dsTablaG;
  unqryFamiliasAtributos.MasterSource :=
                                       (GetOwnerForm<TfrmMtoFamilias>).dsTablaG;
  unqryArticulosFamilias.Open;
  unqrySubFamilias.Open;
  unqryFamiliasAtributos.Open;
  unqryPropiedades.Open;
end;

procedure TdmFamilias.GetCodigoAutoFamilia;
begin
  if (unqryTablaG.FindField('CODIGO_FAM_FAM').AsString = '0') then
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
      unqryTablaG.FindField('CODIGO_FAM_FAM').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if (unqryTablaG.FindField('ORDEN_FAM').AsString = '0') then
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
      unqryTablaG.FindField('ORDEN_FAM').AsString :=
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
    unqryFamProp.sql.Text := 'SELECT CODIGO_PROP_ARTPROP '+
                             '  FROM fza_familias_atributos ' +
                             ' WHERE CODIGO_FAM_FAM = :CODIGO_FAM_FAM ' +
                             '   AND CODIGO_PROP_ARTPROP = ' +
                             ':CODIGO_PROP_ARTPROP';
    unqryFamProp.ParamByName('CODIGO_FAM_FAM').AsString := sFamilia;
    unqryFamProp.ParamByName('CODIGO_PROP_ARTPROP').AsString := sPropiedad;
    unqryFamProp.Open;
    Result := (unqryFamProp.RecordCount > 0);
  finally
    FreeAndNil(unqryFamProp);
  end;
end;

procedure TdmFamilias.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('NOMBRE_FAM_FAM').AsString) = '') then
    Abort;
  with unqryTablaG do
  begin
    if Trim(FindField('NOMBRE_FAM_FAM').AsString) = '' then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Nombre de Familias',
               [FindField('NOMBRE_FAM_FAM').AsString]);
    end
    else
    if (FindField('CODIGO_FAM_FAM').AsString =
        FindField('CODIGO_SUBFAMILIA_FAM').AsString) then
    begin
      raise ERangeError.CreateFmt('%s no puede ser padre e hijo a la vez. ' +
                                       'Revise campo Familia Padre',
               [FindField('CODIGO_SUBFAMILIA_FAM').AsString]);
    end
    else
      if (FindField('CODIGO_FAM_FAM').AsString = '0') then
        GetCodigoAutoFamilia;
  end;
end;
initialization
  ForceReferenceToClass(TdmFamilias);
end.
