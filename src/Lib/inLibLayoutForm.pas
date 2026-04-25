unit inLibLayoutForm;

// =============================================================================
//  inLibLayoutForm
//
//  Helpers genéricos para guardar y restaurar layouts de formularios:
//    * Geometría (Left/Top/Width/Height/WindowState)
//    * Anchos de columnas de cxGrid (cualquier número de grids)
//    * Altura de paneles asociados a splitters
// =============================================================================

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.ExtCtrls,
  cxGridDBTableView, cxGridCustomTableView,
  inLibUser;   // TProfileDicc

type
  // ---------------------------------------------------------------------------
  // Lee perfil al construirse, ofrece métodos Restaurar*
  // ---------------------------------------------------------------------------
  TLayoutLoader = class
  private
    FFormKey: string;
    FPerfil: TProfileDicc;
    FDisponible: Boolean;
  public
    constructor Create(const AFormKey: string);
    destructor  Destroy; override;
    procedure RestaurarGeometria(AForm: TForm);
    procedure RestaurarAlturaPanel(const AClave: string;
                                   APanel: TPanel;
                                   AMinimo: Integer = 30);
    procedure RestaurarGrid(const APrefijoClave: string;
                            AView: TcxGridDBTableView);
    property Disponible: Boolean read FDisponible;
  end;

  // ---------------------------------------------------------------------------
  // Acumula valores en memoria, al final pregunta el perfil destino y graba
  // ---------------------------------------------------------------------------
  TLayoutSaver = class
  private
    FFormKey: string;
    FClaves: TStringList;
    procedure SetClave(const AClave, AValor: string);
  public
    constructor Create(const AFormKey: string);
    destructor  Destroy; override;
    procedure GuardarGeometria(AForm: TForm);
    procedure GuardarAlturaPanel(const AClave: string; APanel: TPanel);
    procedure GuardarGrid(const APrefijoClave: string;
                          AView: TcxGridDBTableView);
    function  PreguntarYGrabar(const ADescripcion: string): Boolean;
  end;

implementation

uses
  inLibGlobalVar, inLibtb, inMtoModalGenImpSave,
  cxGridDBDataDefinitions;

// =============================================================================
// TLayoutLoader
// =============================================================================

constructor TLayoutLoader.Create(const AFormKey: string);
begin
  inherited Create;
  FFormKey := AFormKey;
  FPerfil  := nil;
  inLibUser.GetFormUserProfile(FPerfil, FFormKey,
                               inLibGlobalVar.oUser, inLibGlobalVar.oGroup);
  FDisponible := FPerfil <> nil;
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
  AForm.Left   := StrToIntDef(GetPerfilValueDef(FPerfil, 'Left',   IntToStr(AForm.Left)),   AForm.Left);
  AForm.Top    := StrToIntDef(GetPerfilValueDef(FPerfil, 'Top',    IntToStr(AForm.Top)),    AForm.Top);
  AForm.Width  := StrToIntDef(GetPerfilValueDef(FPerfil, 'Width',  IntToStr(AForm.Width)),  AForm.Width);
  AForm.Height := StrToIntDef(GetPerfilValueDef(FPerfil, 'Height', IntToStr(AForm.Height)), AForm.Height);
  Estado := TWindowState(StrToIntDef(GetPerfilValueDef(FPerfil, 'WindowState', '0'), 0));
  if Estado = wsMinimized then Estado := wsNormal;
  AForm.WindowState := Estado;
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

// =============================================================================
// TLayoutSaver
// =============================================================================

constructor TLayoutSaver.Create(const AFormKey: string);
begin
  inherited Create;
  FFormKey := AFormKey;
  FClaves  := TStringList.Create;
end;

destructor TLayoutSaver.Destroy;
begin
  FClaves.Free;
  inherited;
end;

procedure TLayoutSaver.SetClave(const AClave, AValor: string);
begin
  FClaves.Values[AClave] := AValor;
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

function TLayoutSaver.PreguntarYGrabar(const ADescripcion: string): Boolean;
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  i: Integer;
  Clave, Valor: string;
begin
  Result := False;
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text   := FFormKey;
    formulario.edtDescripcion.Text    := ADescripcion;
    formulario.ShowModal;
    if formulario.sFicha <> 'S' then Exit;
    sPermisos := formulario.cbbPermisos.Text;
  finally
    formulario.Free;
  end;
  for i := 0 to FClaves.Count - 1 do
  begin
    Clave := FClaves.Names[i];
    Valor := FClaves.ValueFromIndex[i];
    odmPerfiles.GrabarPerfil(sPermisos, FFormKey, Clave, Valor);
  end;
  Result := True;
end;

end.
