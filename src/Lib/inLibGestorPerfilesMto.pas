{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGestorPerfilesMto                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestiona los perfiles de pantalla de los mantenimientos genéricos.        }
{******************************************************************************}
unit inLibGestorPerfilesMto;

interface

uses
  System.Classes, Vcl.Forms, Data.DB, Uni, cxLabel, cxGridCustomTableView,
  inLibPerfilesUsuarioIntf;

type
  TSolicitarDestinoPerfilMto = function(
    const ADescripcion: string;
    ADescripcionEditable: Boolean;
    out APermisos: string
  ): Boolean of object;

  TRecogerPerfilesParticularesMto = procedure(
    var APerfiles: TPerfilList;
    const APermisos: string
  ) of object;

  TResetearGridPerfilMto = procedure(
    const ANombreGrid, ANombreFormulario, APermisos: string
  ) of object;

  TBorrarGuiasPerfilMto = procedure of object;

  TGestorPerfilesMto = class
  private
    FFormulario: TCustomForm;
    FDatos: TDataSource;
    FEtiquetaTabla: TcxLabel;
    FServicio: IPerfilesUsuario;
    FSolicitarDestino: TSolicitarDestinoPerfilMto;
    FRecogerParticulares: TRecogerPerfilesParticularesMto;
    FResetearGrid: TResetearGridPerfilMto;
    FBorrarGuias: TBorrarGuiasPerfilMto;
    FPerfil: TProfileDicc;
    procedure AnadirPerfil(
      APerfiles: TPerfilList;
      const APermisos, ASubclave, AValor: string);
    function NombreTablaOrigen: string;
  public
    constructor Create(
      AFormulario: TCustomForm;
      ADatos: TDataSource;
      AEtiquetaTabla: TcxLabel;
      const AServicio: IPerfilesUsuario;
      ASolicitarDestino: TSolicitarDestinoPerfilMto;
      ARecogerParticulares: TRecogerPerfilesParticularesMto;
      AResetearGrid: TResetearGridPerfilMto;
      ABorrarGuias: TBorrarGuiasPerfilMto);
    destructor Destroy; override;
    procedure CargarPerfil(
      const AUsuario, AGrupo: string);
    function Valor(
      const ASubclave, AValorPredeterminado: string): string;
    procedure AplicarEtiquetas;
    procedure CargarPerfilesComunes(
      const AUsuarioGrupo: string = PERFIL_TODOS);
    procedure CargarCaptions;
    procedure CargarColumnas;
    procedure ConstruirPerfilesLayout(
      const APermisos: string;
      APerfiles: TPerfilList);
    procedure GrabarLayout(
      const ADescripcion: string;
      AConexion: TUniConnection);
    procedure ResetearLayout(const ADescripcion: string);
    procedure AbrirPerfiles(
      AVisible: Boolean;
      AConsulta: TUniQuery;
      const ANombreDataModule: string;
      AConexion: TUniConnection);
    procedure RestaurarFoco(AVista: TcxCustomGridTableView);
    property Perfil: TProfileDicc read FPerfil;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DBCommon,
  Vcl.Controls, cxGridDBTableView, inLibDevExp, inLibUser, inLibMsg;

constructor TGestorPerfilesMto.Create(
  AFormulario: TCustomForm;
  ADatos: TDataSource;
  AEtiquetaTabla: TcxLabel;
  const AServicio: IPerfilesUsuario;
  ASolicitarDestino: TSolicitarDestinoPerfilMto;
  ARecogerParticulares: TRecogerPerfilesParticularesMto;
  AResetearGrid: TResetearGridPerfilMto;
  ABorrarGuias: TBorrarGuiasPerfilMto);
begin
  inherited Create;
  FFormulario := AFormulario;
  FDatos := ADatos;
  FEtiquetaTabla := AEtiquetaTabla;
  FServicio := AServicio;
  FSolicitarDestino := ASolicitarDestino;
  FRecogerParticulares := ARecogerParticulares;
  FResetearGrid := AResetearGrid;
  FBorrarGuias := ABorrarGuias;
  FPerfil := nil;
end;

destructor TGestorPerfilesMto.Destroy;
begin
  FreeAndNil(FPerfil);
  FServicio := nil;
  inherited;
end;

procedure TGestorPerfilesMto.CargarPerfil(
  const AUsuario, AGrupo: string);
begin
  if not Assigned(FServicio) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  FreeAndNil(FPerfil);
  FServicio.CargarPerfilFormulario(
    FFormulario.Name, AUsuario, AGrupo, FPerfil);
  if not Assigned(FPerfil) then
    FPerfil := TProfileDicc.Create;
end;

function TGestorPerfilesMto.Valor(
  const ASubclave, AValorPredeterminado: string): string;
begin
  Result := AValorPredeterminado;
  if Assigned(FPerfil) then
    Result := GetPerfilValueDef(
      FPerfil, ASubclave, AValorPredeterminado);
end;

function TGestorPerfilesMto.NombreTablaOrigen: string;
begin
  Result := '';
  if Assigned(FDatos) and Assigned(FDatos.DataSet) then
  begin
    if FDatos.DataSet is TUniQuery then
      Result := GetTableNameFromQuery(
        TUniQuery(FDatos.DataSet).SQL.Text)
    else if FDatos.DataSet is TUniStoredProc then
      Result := TUniStoredProc(FDatos.DataSet).StoredProcName;
  end;
end;

procedure TGestorPerfilesMto.AplicarEtiquetas;
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
  oGrids: TList<TcxCustomGridTableView>;
begin
  if Assigned(FEtiquetaTabla) and
     Assigned(FDatos) and
     Assigned(FDatos.DataSet) then
    FEtiquetaTabla.Caption := NombreTablaOrigen;
  oGrids := TList<TcxCustomGridTableView>.Create;
  try
    for i := 0 to FFormulario.ComponentCount - 1 do
    begin
      if FFormulario.Components[i] is TcxCustomGridTableView then
        oGrids.Add(
          TcxCustomGridTableView(FFormulario.Components[i]));
    end;
    if SameText(
      Trim(Valor('oCreateItems', 'False')), 'True') then
    begin
      for oGrid in oGrids do
      begin
        if SameText(
          Trim(Valor(
            oGrid.Name + '__oCreateItems', 'False')),
          'True') then
        begin
          oGrid.BeginUpdate;
          try
            CrearItemsFaltantes(oGrid);
          finally
            oGrid.EndUpdate;
          end;
        end;
      end;
    end;
    if SameText(
      Trim(Valor('oApplyWidth', 'False')), 'True') then
    begin
      for oGrid in oGrids do
      begin
        if SameText(
          Trim(Valor(
            oGrid.Name + '__oApplyWidth', 'False')),
          'True') then
        begin
          PonerAnchosTitulos(
            oGrid, FFormulario.Name, FPerfil);
          RestaurarFocoGrid(oGrid, FPerfil);
        end;
      end;
    end;
  finally
    FreeAndNil(oGrids);
  end;
  // Los perfiles ya no sustituyen textos. La traducción usará su catálogo.
end;

procedure TGestorPerfilesMto.CargarPerfilesComunes(
  const AUsuarioGrupo: string);
begin
  if not Assigned(FServicio) then
    raise Exception.Create(SErrorServicioPerfilesUsuarioNoConfigurado);
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oRenameComponents', 'False');
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oCreateItems', 'False');
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oBusqGlobal', 'Grid');
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oApplyWidth', 'True');
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oMostrarPerfil', 'False');
  FServicio.GrabarPerfil(
    AUsuarioGrupo, FFormulario.Name,
    'oGetSQLFromDB', 'False');
end;

procedure TGestorPerfilesMto.CargarCaptions;
begin
  // Desactivado: los captions no se guardan en perfiles de usuario.
end;

procedure TGestorPerfilesMto.CargarColumnas;
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
begin
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxCustomGridTableView then
    begin
      oGrid := TcxCustomGridTableView(
        FFormulario.Components[i]);
      GetSettingsColumn(
        oGrid, FFormulario.Name, FFormulario.Owner, FServicio);
    end;
  end;
end;

procedure TGestorPerfilesMto.AnadirPerfil(
  APerfiles: TPerfilList;
  const APermisos, ASubclave, AValor: string);
var
  oItem: TPerfilItem;
begin
  oItem.UserGroup := APermisos;
  oItem.KeyPerfil := FFormulario.Name;
  oItem.SubKey := ASubclave;
  oItem.Value := AValor;
  APerfiles.Add(oItem);
end;

procedure TGestorPerfilesMto.ConstruirPerfilesLayout(
  const APermisos: string;
  APerfiles: TPerfilList);
var
  i: Integer;
  oGrid: TcxCustomGridTableView;
begin
  AnadirPerfil(
    APerfiles, APermisos, 'oRenameComponents',
    Valor('oRenameComponents', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oCreateItems',
    Valor('oCreateItems', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oBusqGlobal',
    Valor('oBusqGlobal', 'Grid'));
  AnadirPerfil(
    APerfiles, APermisos, 'oApplyWidth', 'True');
  AnadirPerfil(
    APerfiles, APermisos, 'oMostrarPerfil',
    Valor('oMostrarPerfil', 'False'));
  AnadirPerfil(
    APerfiles, APermisos, 'oGetSQLFromDB',
    Valor('oGetSQLFromDB', 'False'));
  for i := 0 to FFormulario.ComponentCount - 1 do
  begin
    if FFormulario.Components[i] is TcxCustomGridTableView then
    begin
      oGrid := TcxCustomGridTableView(
        FFormulario.Components[i]);
      AnadirPerfil(
        APerfiles, APermisos,
        oGrid.Name + '__oApplyWidth', 'True');
      AnadirPerfil(
        APerfiles, APermisos,
        oGrid.Name + '__oCreateItems',
        Valor(oGrid.Name + '__oCreateItems', 'False'));
      CollectSettingsColumnProfile(
        oGrid, FFormulario.Name, APermisos,
        FServicio, APerfiles);
    end;
  end;
  if Assigned(FRecogerParticulares) then
    FRecogerParticulares(APerfiles, APermisos);
end;

procedure TGestorPerfilesMto.GrabarLayout(
  const ADescripcion: string;
  AConexion: TUniConnection);
var
  sPermisos: string;
  oPerfiles: TPerfilList;
begin
  if Assigned(FSolicitarDestino) and
     FSolicitarDestino(
       ADescripcion, False, sPermisos) then
  begin
    Screen.Cursor := crHourGlass;
    oPerfiles := TPerfilList.Create;
    try
      if not Assigned(FServicio) then
        raise Exception.Create(
          SErrorServicioPerfilesUsuarioNoConfigurado);
      FServicio.EliminarPerfil(
        sPermisos, FFormulario.Name);
      ConstruirPerfilesLayout(sPermisos, oPerfiles);
      if not Assigned(AConexion) then
        raise Exception.Create(
          SErrorConexionPrincipalNoDisponible);
      AConexion.StartTransaction;
      try
        FServicio.GrabarPerfiles(oPerfiles);
        AConexion.Commit;
      except
        AConexion.Rollback;
        raise;
      end;
    finally
      FreeAndNil(oPerfiles);
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TGestorPerfilesMto.ResetearLayout(
  const ADescripcion: string);
var
  i: Integer;
  sPermisos: string;
  oGrid: TcxCustomGridTableView;
begin
  if Assigned(FSolicitarDestino) and
     FSolicitarDestino(
       ADescripcion, True, sPermisos) then
  begin
    for i := 0 to FFormulario.ComponentCount - 1 do
    begin
      if FFormulario.Components[i] is TcxCustomGridTableView then
      begin
        oGrid := TcxCustomGridTableView(
          FFormulario.Components[i]);
        if Assigned(FResetearGrid) then
          FResetearGrid(
            oGrid.Name, FFormulario.Name, sPermisos);
      end;
    end;
    if Assigned(FBorrarGuias) then
      FBorrarGuias;
  end;
end;

procedure TGestorPerfilesMto.AbrirPerfiles(
  AVisible: Boolean;
  AConsulta: TUniQuery;
  const ANombreDataModule: string;
  AConexion: TUniConnection);
begin
  if AVisible and Assigned(AConsulta) then
  begin
    if ANombreDataModule = '' then
    begin
      if (Pos('Nothing', AConsulta.SQL.Text) > 0) or
         (Trim(AConsulta.SQL.Text) = '') then
      begin
        AConsulta.SQL.Text :=
          'SELECT * ' +
          '  FROM fza_usuarios_perfiles ' +
          ' WHERE (KEY_USUPER = :NameFormModule)';
        AConsulta.ParamByName(
          'NameFormModule').AsString := FFormulario.Name;
      end;
    end
    else
    begin
      if (Pos('Nothing', AConsulta.SQL.Text) > 0) or
         (Trim(AConsulta.SQL.Text) = '') or
         (Pos(':NameDataModule', AConsulta.SQL.Text) > 0) then
      begin
        AConsulta.SQL.Text :=
          'SELECT * ' +
          '  FROM fza_usuarios_perfiles ' +
          ' WHERE ((KEY_USUPER = :NameDataModule) ' +
          '    OR  (KEY_USUPER = :NameFormModule)) ';
        AConsulta.ParamByName(
          'NameDataModule').AsString := FFormulario.Name;
        AConsulta.ParamByName(
          'NameFormModule').AsString := ANombreDataModule;
      end;
    end;
    if not AConsulta.Active then
    begin
      AConsulta.Connection := AConexion;
      AConsulta.Open;
    end;
  end;
end;

procedure TGestorPerfilesMto.RestaurarFoco(
  AVista: TcxCustomGridTableView);
begin
  if Assigned(FPerfil) and Assigned(AVista) then
    RestaurarFocoGrid(AVista, FPerfil);
end;

end.
