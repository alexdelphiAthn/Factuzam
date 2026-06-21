{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGen                                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module base de los mantenimientos (TdmBase).                         }
{    Provee unqryTablaG y servicios comunes (perfiles, GetOwnerForm) que       }
{    heredan los Mtos.                                                         }
{******************************************************************************}
unit UniDataGen;

interface

uses
  System.SysUtils, System.Classes, System.TypInfo, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, inLibWin, inLibLog;

type
  TdmBase = class(TDataModule)
    unqryTablaG: TUniQuery;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryPerfilesBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeInsert(DataSet: TDataSet);
  private
    function GetCurrentForm: TComponent;
    procedure SetCurrentForm(const Value: TComponent);
  protected
    procedure DoCreate; reintroduce; virtual;
    function GetOwnerForm<T: TComponent>: T;
    function HasOwnerForm: Boolean;
  public
    property CurrentForm: TComponent read GetCurrentForm write SetCurrentForm;
    procedure ResetGridsProfile(sGrid, sForm, sPermisos:String);
    // Reasigna la conexion (TUniConnection) de todos los datasets/SQL del
    // data module a `NewConn`. Lo usa TfrmMtoGen tras crear el data module
    // para que cada pestaña use una conexion propia del pool en lugar de
    // la global `oConn` (asi dos tabs no se serializan a nivel de conexion).
    procedure ReasignarConexion(NewConn: TUniConnection);
    // Corta consultas/procedimientos UniDAC en curso antes de destruir el
    // mantenimiento. Se llama desde el hilo principal mientras la tarea BBDD
    // corre en background.
    procedure CancelarEjecucionActiva;
    // Abre las queries detalle/lookup propias del Mto. Default no hace
    // nada; cada TdmXxx override para listar sus queries en el orden
    // adecuado. Lo invoca TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del
    // thread tras abrir unqryTablaG, asi todas las queries se abren en
    // background mientras la UI muestra el overlay y otros tabs siguen
    // interactivos. Antes esto ocurria sincrono en DataModuleCreate (y
    // congelaba la UI 21s en Articulos).
    procedure AbrirDetalles; virtual;
    // Reactiva los TDataSource y dispara cualquier AfterScroll que se
    // hubiera suprimido durante AbrirDetalles. Se invoca en MAIN thread
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync. Cada Mto override para
    // recorrer sus DataSource concretos.
    procedure ReactivarControlesTrasAbrir; virtual;
  public
    FCurrentForm: TComponent;
    FoPerfilDic: TProfileDicc;
  end;

//var
//  dmBase: TdmBase;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses  inLibGlobalVar, inMtoPrincipal, inMtoGen;

{$R *.dfm}

procedure TdmBase.DoCreate;
begin
  FoPerfilDic := nil;
  unqryTablaG.Connection := oConn;
  unqryPerfiles.Connection := oConn;
end;

procedure TdmBase.DataModuleCreate(Sender: TObject);
begin
  DoCreate;
end;

procedure TdmBase.DataModuleDestroy(Sender: TObject);
begin
  unqryTablaG.Close;
  unqryPerfiles.Close;
  if (FoPerfilDic <> nil) then
    FreeAndNil(FoPerfilDic);
//  oPerfilDic.Free;
end;

function TdmBase.GetCurrentForm: TComponent;
begin
  Result := FCurrentForm;
end;

procedure TdmBase.SetCurrentForm(const Value: TComponent);
begin
  FCurrentForm := Value;
end;

function TdmBase.GetOwnerForm<T>: T;
begin
  Result := nil;
  if Assigned(FCurrentForm) and (FCurrentForm is T) then
    Result := T(FCurrentForm)
  else if (Self.Owner <> nil) and (Self.Owner is T) then
    Result := T(Self.Owner);
end;

function TdmBase.HasOwnerForm: Boolean;
begin
  Result := Assigned(FCurrentForm) and
            not (csDestroying in FCurrentForm.ComponentState);
end;

procedure TdmBase.ReasignarConexion(NewConn: TUniConnection);
var
  i: Integer;
  Comp: TComponent;
  ds: TCustomDADataSet;
  sql: TCustomDASQL;
begin
  if NewConn = nil then
    Exit;
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    // TUniQuery, TUniTable, TUniStoredProc heredan de TCustomDADataSet.
    if Comp is TCustomDADataSet then
    begin
      ds := TCustomDADataSet(Comp);
      // Si el dataset YA esta activo, lo dejamos en paz. Muchos data
      // modules (Empresas, Clientes, Atributos...) abren lookups en su
      // DataModuleCreate contra `oConn` global; cerrarlos para reasignar
      // los dejaria vacios y obligaria a re-fetchearlos. Solo redirigimos
      // los datasets que aun no se han abierto — esos son los que nos
      // interesa que vayan contra FConn (unqryTablaG, SPs como
      // unspAplicar, queries on-demand que se abran mas tarde).
      if not ds.Active then
        ds.Connection := NewConn;
    end
    // TUniSQL, TUniScript heredan de TCustomDASQL. No tienen estado de
    // "activo" — solo guardan SQL pendiente — asi que reasignar es seguro.
    else if Comp is TCustomDASQL then
    begin
      sql := TCustomDASQL(Comp);
      sql.Connection := NewConn;
    end;
  end;
end;

procedure TdmBase.AbrirDetalles;
begin
  // Default: nada. Los Mtos con queries detalle/lookup override este metodo.
end;

procedure TdmBase.ReactivarControlesTrasAbrir;
begin
  // Default: nada.
end;

procedure TdmBase.CancelarEjecucionActiva;
var
  i: Integer;
  Comp: TComponent;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    Comp := Components[i];
    try
      if Comp is TUniQuery then
        TUniQuery(Comp).BreakExec
      else if Comp is TUniStoredProc then
        TUniStoredProc(Comp).BreakExec;
    except
      on E: Exception do
        inLibLog.Log.LogError('No se pudo cancelar ' + Comp.Name + ': ' +
                              E.Message);
    end;
  end;
end;

procedure TdmBase.ResetGridsProfile(sGrid, sForm, sPermisos: String);
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'DELETE FROM fza_usuarios_perfiles ' +
                       '      WHERE USUARIO_GRUPO_USUPER = :user ' +
                       '        AND KEY_USUPER = :form ';
//                       '        AND SUBKEY_USUPER LIKE ' +
//                                                      QuotedSTr(sGrid + '_%');
  unqrysol.ParamByName('user').AsString := sPermisos;
  unqrysol.ParamByName('form').AsString := sForm;
  unqrySol.Execute;
  FreeAndNil(unqrySol);
end;

procedure TdmBase.unqryPerfilesBeforePost(DataSet: TDataSet);
begin
  odmConn.ActualizarUserTimeModif(DataSet);
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforePost',
                  'state=' + GetEnumName(TypeInfo(TDataSetState),
                                          Ord(DataSet.State)));
end;

procedure TdmBase.unqryTablaGBeforeInsert(DataSet: TDataSet);
var
  LForm: TfrmMtoGen;
begin
  LForm := GetOwnerForm<TfrmMtoGen>;
  if Assigned(LForm) then
  begin
    if LForm.tsFicha.TabVisible then
       LForm.pcPantalla.ActivePage := LForm.tsFicha;
  end;
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforeInsert', '');
end;

procedure TdmBase.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  oDmConn.ActualizarUserTimeModif(DataSet);
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, DataSet.Name, 'BeforePost',
                  'state=' + GetEnumName(TypeInfo(TDataSetState),
                                          Ord(DataSet.State)));
end;

end.
