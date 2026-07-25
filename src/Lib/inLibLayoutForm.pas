{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLayoutForm                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia de layout de formularios y grids.                            }
{    Guarda geometría, anchos de columnas y alturas de paneles por usuario.    }
{******************************************************************************}
unit inLibLayoutForm;

// =============================================================================
//  inLibLayoutForm
//
//  Helpers genéricos para guardar y restaurar layouts de formularios:
//    * Geometría (Left/Top/Width/Height/WindowState)
//    * Anchos de columnas de cxGrid (cualquier número de grids)
//    * Altura de paneles asociados a splitters
//
//  Persistencia: usa IPerfilesUsuario.GrabarPerfiles para escribir TODAS las
//  claves del layout en un único INSERT ... VALUES por lote, en lugar de un
//  INSERT por clave. Para un layout con varios grids esto reduce drásticamente
//  el tráfico contra MySQL.
//
//  Uso típico:
//    Para guardar (Alt+F12):
//      var Layout := TLayoutSaver.Create(Self.Name, PerfilesUsuario);
//      try
//        Layout.GuardarGeometria(Self);
//        Layout.GuardarAlturaPanel('PanelMaestro', pnlMaestro);
//        Layout.GuardarGrid('Maestro', cxViewMaestro);
//        Layout.GuardarGrid('Pagos', cxViewPagos);
//        Layout.PreguntarYGrabar('Personalización Consulta');
//      finally
//        Layout.Free;
//      end;
//
//    Para restaurar (FormShow):
//      var Layout := TLayoutLoader.Create(Self.Name, PerfilesUsuario);
//      try
//        if Layout.Disponible then
//        begin
//          Layout.RestaurarGeometria(Self);
//          Layout.RestaurarAlturaPanel('PanelMaestro', pnlMaestro, 80);
//          Layout.RestaurarGrid('Maestro', cxViewMaestro);
//        end;
//      finally
//        Layout.Free;
//      end;
// =============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls,
  cxGridDBTableView, cxGridCustomTableView,
  JvInspector,          // TJvInspector (divider del inspector)
  inLibUser,            // TProfileDicc
  inLibContextoSesionIntf,
  inLibPerfilesUsuarioIntf;

type
  // ---------------------------------------------------------------------------
  // Lee perfil al construirse, ofrece métodos Restaurar*
  // ---------------------------------------------------------------------------
  TLayoutLoader = class
  private
    FFormKey: string;
    FPerfil: TProfileDicc;
    FDisponible: Boolean;
    FPerfilesUsuario: IPerfilesUsuario;
  public
    constructor Create(
      const AFormKey: string;
      const AContextoSesion: IContextoSesionAplicacion;
      const APerfilesUsuario: IPerfilesUsuario);
    destructor  Destroy; override;
    procedure RestaurarGeometria(AForm: TForm);
    procedure RestaurarAlturaPanel(const AClave: string;
                                   APanel: TPanel;
                                   AMinimo: Integer = 30);
    procedure RestaurarAnchoPanel(const AClave: string;
                                  APanel: TPanel;
                                  AMinimo: Integer = 30);
    procedure RestaurarGrid(const APrefijoClave: string;
                            AView: TcxGridDBTableView);
    procedure RestaurarDividerInspector(const AClave: string;
                                        AInspector: TJvInspector;
                                        AMinimo: Integer = 100);
    function  RestaurarValor(const AClave, ADefault: string): string;
    property Disponible: Boolean read FDisponible;
  end;

  // ---------------------------------------------------------------------------
  // Acumula valores en memoria; PreguntarYGrabar los persiste TODOS de una
  // sola vez con GrabarPerfiles.
  // ---------------------------------------------------------------------------
  TLayoutSaver = class
  private
    FFormKey: string;
    FClaves: TStringList;
    FPerfilesUsuario: IPerfilesUsuario;
    procedure SetClave(const AClave, AValor: string);
  public
    constructor Create(
      const AFormKey: string;
      const APerfilesUsuario: IPerfilesUsuario);
    destructor  Destroy; override;
    procedure GuardarGeometria(AForm: TForm);
    procedure GuardarAlturaPanel(const AClave: string; APanel: TPanel);
    procedure GuardarAnchoPanel(const AClave: string; APanel: TPanel);
    procedure GuardarGrid(const APrefijoClave: string;
                          AView: TcxGridDBTableView);
    procedure GuardarDividerInspector(const AClave: string;
                                      AInspector: TJvInspector);
    procedure GuardarValor(const AClave, AValor: string);
    function  PreguntarYGrabar(const ADescripcion: string): Boolean;
  end;

// Borra el perfil de layout guardado para el formulario dado.
// Muestra un modal para elegir el nivel de permisos a resetear.
// Devuelve True si se borró, False si el usuario canceló.
function ResetearLayout(
  const AFormKey: string;
  const APerfilesUsuario: IPerfilesUsuario): Boolean;

implementation

uses
  Vcl.Dialogs,
  inLibLog, inLibtb, inMtoModalGenImpSave,
  cxGridDBDataDefinitions;

// =============================================================================
// TLayoutLoader
// =============================================================================

constructor TLayoutLoader.Create(
  const AFormKey: string;
  const AContextoSesion: IContextoSesionAplicacion;
  const APerfilesUsuario: IPerfilesUsuario);
var
  Identidad: TIdentidadSesion;
  iClaves: Integer;
begin
  inherited Create;
  FFormKey := AFormKey;
  FPerfilesUsuario := APerfilesUsuario;
  FPerfil  := nil;
  Log.LogInfo(Format('TLayoutLoader.Create: formKey="%s" -> GetFormUserProfile',
                     [AFormKey]));
  Identidad := AContextoSesion.Identidad;
  inLibUser.GetFormUserProfile(FPerfil, FFormKey, Identidad.Usuario,
    Identidad.Grupo, FPerfilesUsuario);
  FDisponible := FPerfil <> nil;
  if FPerfil <> nil then
    iClaves := FPerfil.Count
  else
    iClaves := -1;
  Log.LogInfo(Format('TLayoutLoader.Create: formKey="%s" disponible=%s claves=%d',
                     [AFormKey, BoolToStr(FDisponible, True), iClaves]));
end;

destructor TLayoutLoader.Destroy;
begin
  if Assigned(FPerfil) then
    FreeAndNil(FPerfil);
  inherited;
end;

procedure TLayoutLoader.RestaurarGeometria(AForm: TForm);
var
  Estado: TWindowState;
begin
  if not FDisponible then Exit;
  AForm.Left   := StrToIntDef(
    GetPerfilValueDef(FPerfil, 'Left',   IntToStr(AForm.Left)),   AForm.Left);
  AForm.Top    := StrToIntDef(
    GetPerfilValueDef(FPerfil, 'Top',    IntToStr(AForm.Top)),    AForm.Top);
  AForm.Width  := StrToIntDef(
    GetPerfilValueDef(FPerfil, 'Width',  IntToStr(AForm.Width)),  AForm.Width);
  AForm.Height := StrToIntDef(
    GetPerfilValueDef(FPerfil, 'Height', IntToStr(AForm.Height)), AForm.Height);
  Estado := TWindowState(StrToIntDef(
    GetPerfilValueDef(FPerfil, 'WindowState', '0'), 0));
  if Estado = wsMinimized then Estado := wsNormal;
  AForm.WindowState := Estado;
end;

function TLayoutLoader.RestaurarValor(const AClave, ADefault: string): string;
begin
  Result := GetPerfilValueDef(FPerfil, AClave, ADefault);
end;

procedure TLayoutLoader.RestaurarAlturaPanel(const AClave: string;
  APanel: TPanel; AMinimo: Integer);
var
  H: Integer;
begin
  if not FDisponible then Exit;
  H := StrToIntDef(GetPerfilValueDef(FPerfil, AClave, '0'), 0);
  if H > AMinimo then
    APanel.Height := H;
end;

procedure TLayoutLoader.RestaurarAnchoPanel(const AClave: string;
  APanel: TPanel; AMinimo: Integer);
var
  W: Integer;
begin
  if not FDisponible then Exit;
  W := StrToIntDef(GetPerfilValueDef(FPerfil, AClave, '0'), 0);
  if W > AMinimo then
    APanel.Width := W;
end;

procedure TLayoutLoader.RestaurarGrid(const APrefijoClave: string;
  AView: TcxGridDBTableView);
var
  i, Ancho: Integer;
  Col: TcxGridDBColumn;
  Clave: string;
begin
  if not FDisponible then Exit;
  AView.BeginUpdate;
  try
    for i := 0 to AView.ColumnCount - 1 do
    begin
      Col := AView.Columns[i] as TcxGridDBColumn;
      if Col.DataBinding.FieldName = '' then Continue;
      Clave := APrefijoClave + '_Col_' + Col.DataBinding.FieldName;
      Ancho := StrToIntDef(GetPerfilValueDef(FPerfil, Clave, '0'), 0);
      if Ancho > 10 then
        Col.Width := Ancho;
    end;
  finally
    AView.EndUpdate;
  end;
end;

procedure TLayoutLoader.RestaurarDividerInspector(const AClave: string;
  AInspector: TJvInspector; AMinimo: Integer);
var
  D: Integer;
begin
  if not FDisponible then
    Exit;
  D := StrToIntDef(GetPerfilValueDef(FPerfil, AClave, '0'), 0);
  if D > AMinimo then
    AInspector.Divider := D;
end;

// =============================================================================
// TLayoutSaver
// =============================================================================

constructor TLayoutSaver.Create(
  const AFormKey: string;
  const APerfilesUsuario: IPerfilesUsuario);
begin
  inherited Create;
  FFormKey := AFormKey;
  FPerfilesUsuario := APerfilesUsuario;
  FClaves  := TStringList.Create;
end;

destructor TLayoutSaver.Destroy;
begin
  FreeAndNil(FClaves);
  inherited;
end;

procedure TLayoutSaver.SetClave(const AClave, AValor: string);
begin
  FClaves.Values[AClave] := AValor;
end;

procedure TLayoutSaver.GuardarValor(const AClave, AValor: string);
begin
  SetClave(AClave, AValor);
end;

procedure TLayoutSaver.GuardarGeometria(AForm: TForm);
begin
  SetClave('WindowState', IntToStr(Ord(AForm.WindowState)));
  if AForm.WindowState = wsNormal then
  begin
    SetClave('Left',   IntToStr(AForm.Left));
    SetClave('Top',    IntToStr(AForm.Top));
    SetClave('Width',  IntToStr(AForm.Width));
    SetClave('Height', IntToStr(AForm.Height));
  end;
end;

procedure TLayoutSaver.GuardarAlturaPanel(const AClave: string; APanel: TPanel);
begin
  SetClave(AClave, IntToStr(APanel.Height));
end;

procedure TLayoutSaver.GuardarAnchoPanel(const AClave: string; APanel: TPanel);
begin
  SetClave(AClave, IntToStr(APanel.Width));
end;

procedure TLayoutSaver.GuardarGrid(const APrefijoClave: string;
  AView: TcxGridDBTableView);
var
  i: Integer;
  Col: TcxGridDBColumn;
begin
  for i := 0 to AView.ColumnCount - 1 do
  begin
    Col := AView.Columns[i] as TcxGridDBColumn;
    if Col.DataBinding.FieldName = '' then Continue;
    SetClave(APrefijoClave + '_Col_' + Col.DataBinding.FieldName,
             IntToStr(Col.Width));
  end;
end;

procedure TLayoutSaver.GuardarDividerInspector(const AClave: string;
  AInspector: TJvInspector);
begin
  SetClave(AClave, IntToStr(AInspector.Divider));
end;

// Pregunta al usuario el perfil destino y graba TODAS las claves acumuladas
// en una única llamada batch. Si el usuario cancela el modal, no se graba
// nada y devuelve False.
function TLayoutSaver.PreguntarYGrabar(const ADescripcion: string): Boolean;
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  i: Integer;
  Lote: TPerfilList;
  Item: TPerfilItem;
begin
  Result := False;
  if FClaves.Count = 0 then Exit;
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text   := FFormKey;
    formulario.edtDescripcion.Text    := ADescripcion;
    formulario.ShowModal;
    if formulario.sFicha <> 'S' then Exit;
    sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  Lote := TPerfilList.Create;
  try
    for i := 0 to FClaves.Count - 1 do
    begin
      Item.UserGroup := sPermisos;
      Item.KeyPerfil := FFormKey;
      Item.SubKey    := FClaves.Names[i];
      Item.Value     := FClaves.ValueFromIndex[i];
      Lote.Add(Item);
    end;
    FPerfilesUsuario.GrabarPerfiles(Lote);
  finally
    FreeAndNil(Lote);
  end;
  Result := True;
end;

// =============================================================================
// ResetearLayout
// =============================================================================

function ResetearLayout(
  const AFormKey: string;
  const APerfilesUsuario: IPerfilesUsuario): Boolean;
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
begin
  Result := False;
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtNombreOrigen.Text := AFormKey;
    formulario.edtDescripcion.Enabled := False;
    formulario.edtDescripcion.Text := 'Resetear Layout';
    formulario.ShowModal;
    if formulario.sFicha <> 'S' then
      Exit;
    sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  APerfilesUsuario.EliminarPerfil(sPermisos, AFormKey);
  ShowMessage('Layout reseteado.' + sLineBreak +
              'Se aplicará la próxima vez que abra el formulario.');
  Result := True;
end;

end.

