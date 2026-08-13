{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlmacenes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de almacenes.                                                 }
{    Maestro de fza_almacenes y consulta auxiliar de cajas por almacén.        }
{******************************************************************************}
unit UniDataAlmacenes;
interface
uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants, UniDataGen, Data.DB,
  MemDS, DBAccess, Uni, inLibUser;
type
  TdmAlmacenes = class(TdmBase)
    qryAlmacenesCajas: TUniQuery;
    dsAlmacenesCajas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    FAlmacenAnteriorWeb: string;
    FCambioSeleccionWeb: Boolean;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
  end;
implementation

uses
  UniDataPrestaShopEncolado;

resourcestring
  SAlmacenWebNoValido =
    'Solo un almacén activo, físico y de tipo ESTANDAR puede ' +
    'marcarse En web';

{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
procedure ForceReferenceToClass(C: TClass); begin end;
procedure TdmAlmacenes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  qryAlmacenesCajas.Connection := ConexionPrincipal;
  qryAlmacenesCajas.Open;
end;

procedure TdmAlmacenes.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  CampoWeb: TField;
begin
  CampoWeb := nil;
  if Assigned(DataSet) then
    CampoWeb := DataSet.FindField('ESWEB_ALM');
  if Assigned(CampoWeb) and
     (Trim(CampoWeb.AsString) = '') then
    CampoWeb.AsString := 'N';
end;

procedure TdmAlmacenes.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FAlmacenAnteriorWeb := Trim(
    DataSet.FieldByName('CODIGO_ALM_ALM').AsString);
end;

procedure TdmAlmacenes.unqryTablaGAfterDelete(DataSet: TDataSet);
begin
  EncolarStockAlmacenPrestaShop(
    TUniQuery(DataSet).Connection,
    FAlmacenAnteriorWeb,
    IdentidadSesion.Usuario);
  FAlmacenAnteriorWeb := '';
end;

procedure TdmAlmacenes.unqryTablaGBeforePost(DataSet: TDataSet);
var
  bAlmacenWebValido: Boolean;
  sValorAnterior: string;
begin
  inherited;
  FAlmacenAnteriorWeb := '';
  FCambioSeleccionWeb := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
  begin
    FAlmacenAnteriorWeb := DataSet.FieldByName(
      'CODIGO_ALM_ALM').OldValue;
    sValorAnterior := VarToStr(DataSet.FieldByName(
      'ESWEB_ALM').OldValue);
    FCambioSeleccionWeb :=
      not SameText(sValorAnterior,
        DataSet.FieldByName('ESWEB_ALM').AsString) or
      not SameText(VarToStr(DataSet.FieldByName(
        'ESACTIVO_ALM').OldValue),
        DataSet.FieldByName('ESACTIVO_ALM').AsString) or
      not SameText(VarToStr(DataSet.FieldByName(
        'ESFISICO_ALM').OldValue),
        DataSet.FieldByName('ESFISICO_ALM').AsString) or
      not SameText(Trim(VarToStr(DataSet.FieldByName(
        'TIPO_USO_ALM').OldValue)),
        Trim(DataSet.FieldByName('TIPO_USO_ALM').AsString)) or
      not SameText(VarToStr(DataSet.FieldByName(
        'CODIGO_EMP_ALM').OldValue),
        DataSet.FieldByName('CODIGO_EMP_ALM').AsString) or
      not SameText(FAlmacenAnteriorWeb,
        DataSet.FieldByName('CODIGO_ALM_ALM').AsString);
  end;
  bAlmacenWebValido :=
    SameText(DataSet.FieldByName('ESACTIVO_ALM').AsString, 'S') and
    SameText(DataSet.FieldByName('ESFISICO_ALM').AsString, 'S') and
    SameText(Trim(DataSet.FieldByName('TIPO_USO_ALM').AsString),
      'ESTANDAR');
  if SameText(DataSet.FieldByName('ESWEB_ALM').AsString, 'S') and
     (not bAlmacenWebValido) then
    raise EDatabaseError.Create(SAlmacenWebNoValido);
end;

procedure TdmAlmacenes.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sAlmacenActual: string;
begin
  if FCambioSeleccionWeb then
  begin
    sAlmacenActual := DataSet.FieldByName('CODIGO_ALM_ALM').AsString;
    EncolarStockAlmacenPrestaShop(
      TUniQuery(DataSet).Connection,
      sAlmacenActual,
      IdentidadSesion.Usuario);
    if (FAlmacenAnteriorWeb <> '') and
       (not SameText(FAlmacenAnteriorWeb, sAlmacenActual)) then
      EncolarStockAlmacenPrestaShop(
        TUniQuery(DataSet).Connection,
        FAlmacenAnteriorWeb,
        IdentidadSesion.Usuario);
  end;
  FAlmacenAnteriorWeb := '';
  FCambioSeleccionWeb := False;
end;

procedure TdmAlmacenes.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  qryAlmacenesCajas.MasterSource := ADataSource;
end;


procedure TdmAlmacenes.DataModuleDestroy(Sender: TObject);
begin
  qryAlmacenesCajas.Close;
  inherited;
end;

initialization
  RegistrarDataModule(TdmAlmacenes);
  ForceReferenceToClass(TdmAlmacenes);
end.
