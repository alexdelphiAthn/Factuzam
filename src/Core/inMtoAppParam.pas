{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAppParam                                                 }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de mantenimiento de parametros de la aplicacion.               }
{    Editor tipo inspector con categorias por usuario y grupo.                 }
{******************************************************************************}
unit inMtoAppParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxFilter,
  dxScrollbarAnnotations, cxEdit, cxCheckBox, cxInplaceContainer,
  cxTextEdit, cxContainer, inLibGlobalVar, dxCoreGraphics, cxMaskEdit,
  cxButtonEdit, cxSpinEdit, Vcl.ExtCtrls, inMtoFrmBase, Uni,
  cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  JvComponentBase, JvInspector, JvExControls, System.Actions,
  Vcl.ActnList, dxSkinsCore, System.UITypes;   // dxSkinsCore para TdxSkinController

type
  PBoolean = ^Boolean;
  PInteger = ^Integer;
  PString  = ^String;
  TInspectorItemEvent = procedure(Sender: TJvCustomInspectorItem) of object;
  TfrmMtoAppParam = class(TFrmBase)
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;
    ActionList1    : TActionList;
    actGuardar       : TAction;
    actSalir         : TAction;
    actGuardarLayout : TAction;
    JvInspector1: TJvInspector;
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
                                                 AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject; var Key: Word;
                                 Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure cmbGrupoUsuarioPropertiesChange(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnChangeIdClick(Sender: TObject);
    procedure actGuardarExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
//    procedure InspectorEditButtonClick(Sender: TObject;
//                                       Item: TJvCustomInspectorItem);
  private
    FBools            : TList<PBoolean>;
    FInts             : TList<PInteger>;
    FStrs             : TList<PString>;
    FValoresOriginales: TDictionary<string, string>;
    procedure InspectorItemEdit(Sender: TJvCustomInspector;
                                Item: TJvCustomInspectorItem;
                                var DisplayStr: string);
    procedure CapturarValoresOriginales;
    function  HayCambiosPendientes: Boolean;
    procedure LimpiarMemoria;
    procedure ResetearADefectos;
    function  ObtenerCategoria(const NombreCat: string)
                : TJvInspectorCustomCategoryItem;
    function  QuitarTildes(const Texto: string): string;
    function  BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                const Nombre: string): TJvCustomInspectorItem;
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    procedure AplicarBloqueoParametros;
    procedure CargarParametros(Grid: TJvInspector;
                               const pUsuario, pGrupo: string);
    procedure ConstruirInspector;
    procedure GuardarLayout;
    procedure RestaurarLayout;

    // Handlers de listas desplegables
    procedure GetImpresorasInformesList(Sender: TJvCustomInspectorItem;
                                        Strings: TStrings);
    procedure GetTemasList(Sender: TJvCustomInspectorItem;
                           Strings: TStrings);
    procedure GetPaletasList(Sender: TJvCustomInspectorItem;
                              Strings: TStrings);
    procedure GetTarifasList(Sender: TJvCustomInspectorItem;
                              Strings: TStrings);
    procedure GetTemporadasList(Sender: TJvCustomInspectorItem;
                                Strings: TStrings);
    procedure GetNifsEmpresasList(Sender: TJvCustomInspectorItem;
                                  Strings: TStrings);
    procedure GetModosVerifactuList(Sender: TJvCustomInspectorItem;
                                    Strings: TStrings);
    // Handler para el botón de selección de carpeta
//    procedure OnDirButtonClick(Sender: TObject;
//                               Index: Integer);
  end;

var
  frmMtoAppParam: TfrmMtoAppParam;

implementation

{$R *.dfm}

uses
  StrUtils, inLibAppParam, inLibLog, Vcl.Printers,
   dxSkinsLookAndFeelPainter,
   dxSkinsDefaultPainters, dxSkinsForm,
  FileCtrl, inLibPathTokens,               // SelectDirectory
  inLibLayoutForm, inLibVerifactu;

procedure RegistrarCambioConfiguracionVerifactuSeguro(
  const ADetalle: string);
begin
  try
    if oConn <> nil then
      RegistrarEventoVerifactu(oConn, cEventoNoVerifactuCambioConfig,
        'Cambio de configuración Verifactu', ADetalle);
  except
    on E: Exception do
      Log.LogError('No se pudo registrar el cambio de configuración ' +
        'Verifactu: ' + E.Message);
  end;
end;

function UsuarioPuedeEditarParametro(const ANombre: string): Boolean;
begin
  Result := True;
  if StartsText('appVerifactu', ANombre) then
    Result := SameText(oRootGroup, 'S');
end;

// -----------------------------------------------------------------------
// CICLO DE VIDA
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.FormCreate(Sender: TObject);
begin
  inherited;
  FBools             := TList<PBoolean>.Create;
  FInts              := TList<PInteger>.Create;
  FStrs              := TList<PString>.Create;
  FValoresOriginales := TDictionary<string, string>.Create;
  JvInspector1.OnItemEdit := InspectorItemEdit;
//  JvInspector1.OnEditButtonClick := InspectorEditButtonClick;
end;

procedure TfrmMtoAppParam.FormDestroy(Sender: TObject);
begin
  LimpiarMemoria;
  FreeAndNil(FBools);
  FreeAndNil(FInts);
  FreeAndNil(FStrs);
  FreeAndNil(FValoresOriginales);
  inherited;
end;

procedure TfrmMtoAppParam.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoAppParam.LimpiarMemoria;
var
  pB: PBoolean; pI: PInteger; pS: PString;
begin
  for pB in FBools do Dispose(pB);  FBools.Clear;
  for pI in FInts  do Dispose(pI);  FInts.Clear;
  for pS in FStrs  do Dispose(pS);  FStrs.Clear;
end;

// -----------------------------------------------------------------------
// CONSTRUCCIÓN DEL INSPECTOR
// -----------------------------------------------------------------------

function TfrmMtoAppParam.ObtenerCategoria(
  const NombreCat: string): TJvInspectorCustomCategoryItem;
var
  i: Integer;
begin
  for i := 0 to JvInspector1.Root.Count - 1 do
    if (JvInspector1.Root.Items[i] is TJvInspectorCustomCategoryItem) and
       SameText(JvInspector1.Root.Items[i].DisplayName, NombreCat) then
      Exit(TJvInspectorCustomCategoryItem(JvInspector1.Root.Items[i]));

  Result := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
  Result.DisplayName := NombreCat;
  Result.Expanded    := True;
end;

procedure TfrmMtoAppParam.ConstruirInspector;
var
  Param   : TAppParamDef;
  CatItem : TJvInspectorCustomCategoryItem;
  ItemCombo: TJvCustomInspectorItem;
  pBool   : PBoolean;
  pInt    : PInteger;
  pStr    : PString;
begin
  LimpiarMemoria;
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;

    for Param in oAppParams.Params.Values do
    begin
      CatItem := ObtenerCategoria(Param.Categoria);

      case Param.Tipo of
        tpBoolean:
          begin
            New(pBool);
            FBools.Add(pBool);
            pBool^ := SameText(Param.ValorPorDefecto, 'True') or
                      (Param.ValorPorDefecto = '1');
            with TJvInspectorVarData.New(CatItem, Param.Nombre,
                                         TypeInfo(Boolean), pBool) do
              DisplayName := Param.Descripcion;
          end;

        tpInteger:
          begin
            New(pInt);
            FInts.Add(pInt);
            pInt^ := StrToIntDef(Param.ValorPorDefecto, 0);
            with TJvInspectorVarData.New(CatItem, Param.Nombre,
                                         TypeInfo(Integer), pInt) do
              DisplayName := Param.Descripcion;
          end;

        tpString:
          begin
            New(pStr);
            FStrs.Add(pStr);
            pStr^     := Param.ValorPorDefecto;
            ItemCombo := TJvInspectorVarData.New(CatItem, Param.Nombre,
                                                 TypeInfo(string), pStr);
            ItemCombo.DisplayName := Param.Descripcion;

            if SameText(Param.Nombre, 'appImpresoraInformes') then
            begin
              ItemCombo.Flags := ItemCombo.Flags +
                                 [iifValueList, iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetImpresorasInformesList;
            end
            else if SameText(Param.Nombre, 'appTema') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetTemasList;
            end
            else if SameText(Param.Nombre, 'appPaleta') then
            begin
              ItemCombo.Flags := ItemCombo.Flags +
                                 [iifValueList, iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetPaletasList;
            end
            else if SameText(Param.Nombre, 'appTarifaDefecto') then
            begin
              ItemCombo.Flags := ItemCombo.Flags +
                                 [iifValueList, iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetTarifasList;
            end
            else if SameText(Param.Nombre, 'appTemporadaDefecto') then
            begin
              ItemCombo.Flags := ItemCombo.Flags +
                                 [iifValueList, iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetTemporadasList;
            end
            else if SameText(Param.Nombre, 'appVerifactuModo') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetModosVerifactuList;
            end
            else if SameText(Param.Nombre, 'appVerifactuSifNif') then
            begin
              // Combo editable: el editor plano del inspector rechaza
              // letras en este campo; con AllowNonListValues se puede
              // teclear cualquier NIF y se sugieren los de las empresas
              ItemCombo.Flags := ItemCombo.Flags +
                                 [iifValueList, iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetNifsEmpresasList;
            end
            else if StartsText('appDir', Param.Nombre) then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifEditButton];
            end;
            // Los directorios (appDirPDF, appDirExcel) quedan como
            // tpString normal: el usuario escribe la ruta directamente
          end;
      end;
    end;
    AplicarBloqueoParametros;
  finally
    JvInspector1.EndUpdate;
  end;
end;

procedure TfrmMtoAppParam.AplicarBloqueoParametros;
var
  i: Integer;
  j: Integer;
  NodoPrincipal: TJvCustomInspectorItem;
  ParamItem: TJvCustomInspectorItem;
begin
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
    begin
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        ParamItem.ReadOnly := not UsuarioPuedeEditarParametro(ParamItem.Name);
      end;
    end;
  end;
end;

// -----------------------------------------------------------------------
// HANDLERS DE LISTAS
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.GetImpresorasInformesList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  i: Integer;
begin
  Strings.Clear;
  Strings.Add('');
  for i := 0 to Printer.Printers.Count - 1 do
    Strings.Add(Printer.Printers[i]);
end;

procedure TfrmMtoAppParam.GetTemasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  I: Integer;
  LSorted: TStringList;
begin
  // Enumeración dinámica: muestra todos los skins registrados en la app
  LSorted := TStringList.Create;
  try
    LSorted.Sorted := True;
    LSorted.Duplicates := dupIgnore;
    for I := 0 to cxLookAndFeelPaintersManager.Count - 1 do
    begin
      if cxLookAndFeelPaintersManager[I].LookAndFeelStyle = lfsSkin then
        LSorted.Add(cxLookAndFeelPaintersManager[I].LookAndFeelName);
    end;
    Strings.Assign(LSorted);
  finally
    LSorted.Free;
  end;
end;

procedure TfrmMtoAppParam.GetPaletasList(Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  LSkinName: string;
  LItemTema: TJvCustomInspectorItem;
  LPainter: TcxCustomLookAndFeelPainter;
  LPainterInfo: TdxSkinLookAndFeelPainterInfo; // Usamos la clase de información de tu unidad
  I: Integer;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    Strings.Add('Default');

    // 1. Obtener el nombre del skin seleccionado actualmente en el inspector
    LItemTema := BuscarItemPorNombre(JvInspector1.Root, 'appTema');

    if (LItemTema <> nil) and Assigned(LItemTema.Data) then
      LSkinName := LItemTema.Data.AsString
    else
      LSkinName := oAppParams.GetString('appTema');

    if Trim(LSkinName) = '' then
      Exit;

    // 2. Usar el manager global nativo que SÍ existe en tu versión
    if cxLookAndFeelPaintersManager.GetPainter(LSkinName, LPainter) then
    begin
      // 3. Extraer la información interna del Skin de forma segura
      if LPainter.GetPainterData(LPainterInfo) then
      begin
        // 4. Ahora SÍ podemos acceder a .Skin y a sus Paletas sin que Delphi se queje
        if Assigned(LPainterInfo.Skin) and (LPainterInfo.Skin.ColorPalettes.Count > 0) then
        begin
          for I := 0 to LPainterInfo.Skin.ColorPalettes.Count - 1 do
          begin
            Strings.Add(LPainterInfo.Skin.ColorPalettes[I].Name);
          end;
        end;
      end;
    end;

  finally
    Strings.EndUpdate;
  end;
end;

procedure TfrmMtoAppParam.GetTarifasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  qry: TUniQuery;
begin
  Strings.Clear;
  Strings.Add('');
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT CODIGO_TAR_ARTTAR FROM fza_tarifas' +
      ' WHERE ESACTIVO_ARTTAR = ''S''' +
      ' ORDER BY ORDEN_TAR';
    qry.Open;
    while not qry.Eof do
    begin
      Strings.Add(qry.FieldByName('CODIGO_TAR_ARTTAR').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoAppParam.GetModosVerifactuList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add(cModoVerifactuSin);
  Strings.Add(cModoVerifactuVerifactu);
  Strings.Add(cModoVerifactuNoVerifactu);
end;

procedure TfrmMtoAppParam.GetTemporadasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  qry: TUniQuery;
begin
  Strings.Clear;
  Strings.Add('');
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT PV FROM fza_propiedades_valores' +
      ' WHERE ID_PROP_PV = ''TEMPORADA''' +
      '   AND ESACTIVO_PV = ''S''' +
      ' ORDER BY PV';
    qry.Open;
    while not qry.Eof do
    begin
      Strings.Add(qry.FieldByName('PV').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoAppParam.GetNifsEmpresasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  qry: TUniQuery;
begin
  Strings.Clear;
  Strings.Add('');
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT DISTINCT NIF_EMP FROM fza_empresas' +
      ' WHERE IFNULL(NIF_EMP, '''') <> ''''' +
      ' ORDER BY NIF_EMP';
    qry.Open;
    while not qry.Eof do
    begin
      Strings.Add(qry.FieldByName('NIF_EMP').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoAppParam.InspectorItemEdit(Sender: TJvCustomInspector;
  Item: TJvCustomInspectorItem; var DisplayStr: string);
var
  Dir: string;
begin
  if (Item = nil) or not StartsText('appDir', Item.Name) then
    Exit;

  // El valor guardado puede ya contener un token: lo expandimos
  // para que SelectDirectory arranque en la carpeta real
  Dir := ExpandPathTokens(DisplayStr);

  if SelectDirectory('Seleccione una carpeta', '', Dir,
                     [sdNewUI, sdNewFolder]) then
    DisplayStr := PathToToken(Dir);   // guardamos con token
end;


// -----------------------------------------------------------------------
// CARGA Y GUARDADO  (idéntico al de CajaParam)
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.CapturarValoresOriginales;
var
  i, j        : Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorExtraido: string;
begin
  FValoresOriginales.Clear;
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        if ParamItem.Data <> nil then
        begin
          case ParamItem.Data.TypeInfo.Kind of
            tkEnumeration:
              if ParamItem.Data.AsOrdinal <> 0 then
                ValorExtraido := 'True'
              else
                ValorExtraido := 'False';
            tkInteger:
              ValorExtraido := IntToStr(ParamItem.Data.AsOrdinal);
          else
            ValorExtraido := ParamItem.Data.AsString;
          end;
          FValoresOriginales.AddOrSetValue(ParamItem.Name, ValorExtraido);
        end;
      end;
  end;
end;

procedure TfrmMtoAppParam.ResetearADefectos;
var
  Param   : TAppParamDef;
  ItemData: TJvCustomInspectorItem;
begin
  for Param in oAppParams.Params.Values do
  begin
    ItemData := BuscarItemPorNombre(JvInspector1.Root, Param.Nombre);
    if ItemData <> nil then
      ItemData.DisplayValue := Param.ValorPorDefecto;
  end;
end;

procedure TfrmMtoAppParam.CargarParametros(Grid: TJvInspector;
                                           const pUsuario, pGrupo: string);
var
  qry     : TUniQuery;
  SubKey  : string;
  ValorStr: string;
  ItemData: TJvCustomInspectorItem;
begin
  ResetearADefectos;
  Grid.Refresh;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   :=
      'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoAppParam';
    qry.Open;

    Grid.BeginUpdate;
    try
      while not qry.Eof do
      begin
        SubKey   := qry.FieldByName('SUBKEY_USUPER').AsString;
        ValorStr := qry.FieldByName('VALUE_USUPER').AsString;
        ItemData := BuscarItemPorNombre(Grid.Root, SubKey);
        if (ItemData <> nil) and (ItemData.Data <> nil) then
        begin
          try
            if (ValorStr = '') and
               (ItemData.Data.TypeInfo.Kind in [tkInteger, tkFloat]) then
              ValorStr := '0';
            ItemData.DisplayValue := ValorStr;
          except
          end;
        end;
        qry.Next;
      end;
    finally
      Grid.EndUpdate;
    end;
    CapturarValoresOriginales;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoAppParam.btnGuardarClick(Sender: TObject);
var
  qry           : TUniQuery;
  sUsuarioGrupo : string;
  i, j          : Integer;
  NodoPrincipal : TJvCustomInspectorItem;
  ParamItem     : TJvCustomInspectorItem;
  ValorAGuardar : string;
  GuardadosCount: Integer;
  IgnoradosCount: Integer;
  TemaAnterior  : string;
  CambioVerifactu: Boolean;
  CambioReal: Boolean;
  PuedeEditar: Boolean;
begin
  JvInspector1.SaveValues;
  if cmbGrupoUsuario.ItemIndex = -1 then Exit;
  sUsuarioGrupo := cmbGrupoUsuario.Text;

  GuardadosCount := 0;
  IgnoradosCount := 0;
  TemaAnterior   := oAppParams.GetString('appTema');
  CambioVerifactu := False;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text   :=
      'CALL PRC_SETPERFILFORMULARIO(:p_usuario_grupo, ' +
      '                             :p_formulario,    ' +
      '                             :p_subkey,        ' +
      '                             :p_value)';

    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      NodoPrincipal := JvInspector1.Root.Items[i];
      if not (NodoPrincipal is TJvInspectorCustomCategoryItem) then
        Continue;

      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        if ParamItem.Data <> nil then
          case ParamItem.Data.TypeInfo.Kind of
            tkEnumeration:
              if ParamItem.Data.AsOrdinal <> 0 then
                ValorAGuardar := 'True'
              else
                ValorAGuardar := 'False';
            tkInteger:
              ValorAGuardar := IntToStr(ParamItem.Data.AsOrdinal);
          else
            ValorAGuardar := ParamItem.Data.AsString;
          end
        else
          ValorAGuardar := '';

        // Solo guardamos si hubo cambio real
        CambioReal := True;
        if FValoresOriginales.ContainsKey(ParamItem.Name) then
          CambioReal := not SameText(FValoresOriginales[ParamItem.Name],
                                     ValorAGuardar);
        PuedeEditar := UsuarioPuedeEditarParametro(ParamItem.Name);
        if CambioReal and PuedeEditar then
        begin
          qry.ParamByName('p_usuario_grupo').AsString := sUsuarioGrupo;
          qry.ParamByName('p_formulario').AsString    := 'frmMtoAppParam';
          qry.ParamByName('p_subkey').AsString        := ParamItem.Name;
          qry.ParamByName('p_value').AsString         := ValorAGuardar;
          qry.Execute;
          Inc(GuardadosCount);
          if StartsText('appVerifactu', ParamItem.Name) then
            CambioVerifactu := True;
          FValoresOriginales.AddOrSetValue(ParamItem.Name, ValorAGuardar);
        end
        else if CambioReal and (not PuedeEditar) then
          Inc(IgnoradosCount);
      end;
    end;

    if GuardadosCount > 0 then
    begin
      ShowMessage(Format('Se guardaron %d parámetros para: %s',
                         [GuardadosCount, sUsuarioGrupo]));

      // Recargamos en memoria si afecta al usuario/grupo actual
      if (sUsuarioGrupo = oUser) or
         (sUsuarioGrupo = oGroup) or
         (sUsuarioGrupo = oAll) then
      begin
        oAppParams.Recargar(oUser, oGroup);

        // ── Aplicar modos de depuración al vuelo ─────────────────────
        // Si el usuario acaba de tocar appModoDebug / appModoDebugSQL,
        // surte efecto sin necesidad de reiniciar.
        inLibLog.AplicarModosDepuracion;

        // ── Aplicar tema al vuelo si cambió ──────────────────────────
        var TemaNuevo := oAppParams.GetString('appTema');
        if not SameText(TemaAnterior, TemaNuevo) and (TemaNuevo <> '') then
        begin
//          dxSkinsCore.dxSkinController.SkinName := TemaNuevo;
//          ShowMessage('El tema "' + TemaNuevo +
//                      '" se aplicará completamente al reiniciar.');
        end;
      end;
      if CambioVerifactu then
        RegistrarCambioConfiguracionVerifactuSeguro(
          'Parámetros guardados para ' + sUsuarioGrupo + ': ' +
          IntToStr(GuardadosCount));
      if IgnoradosCount > 0 then
        ShowMessage(Format('Se ignoraron %d parámetros Verifactu. ' +
                           'Solo un usuario administrador puede cambiarlos.',
                           [IgnoradosCount]));
    end
    else if IgnoradosCount > 0 then
      ShowMessage(Format('No se guardaron %d parámetros Verifactu. ' +
                         'Solo un usuario administrador puede cambiarlos.',
                         [IgnoradosCount]))
    else
      ShowMessage('No se detectaron cambios para guardar.');
  finally
    FreeAndNil(qry);
  end;
end;

// -----------------------------------------------------------------------
// LAYOUT (geometría + divider del inspector)
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(Self.Name);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarDividerInspector('Divider', JvInspector1);
    if Layout.PreguntarYGrabar('Personalización Parámetros Aplicación') then
      ShowMessage('Layout guardado.');
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoAppParam.RestaurarLayout;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(Self.Name);
  try
    if Layout.Disponible then
    begin
      Layout.RestaurarGeometria(Self);
      Layout.RestaurarDividerInspector('Divider', JvInspector1);
    end;
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoAppParam.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayout;
end;

// -----------------------------------------------------------------------
// EVENTOS DE FORMULARIO
// -----------------------------------------------------------------------

procedure TfrmMtoAppParam.FormShow(Sender: TObject);
var
  qry: TUniQuery;
  s: string;
begin
  ConstruirInspector;
  cmbGrupoUsuario.Properties.Items.Clear;
  // Todo usuario gestiona sus propios parametros (oUser) y los de su
  // grupo (oGroup), y puede consultar los de 'Todos' (oAll) en modo
  // solo lectura (lo aplica cmbGrupoUsuarioPropertiesChange).
  cmbGrupoUsuario.Properties.Items.Add(oUser);
  cmbGrupoUsuario.Properties.Items.Add(oGroup);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  // Solo los administradores ven ademas la lista completa de usuarios y
  // grupos del sistema (y pueden editarla).
  if oRootGroup = 'S' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text :=
        'SELECT ''Todos'' AS S ' +
        ' UNION SELECT GRUPO_USUGRP FROM fza_usuarios_grupos ' +
        ' UNION SELECT USUARIO_USU FROM fza_usuarios ' +
        ' ORDER BY S';
      qry.Open;
      while not qry.Eof do
      begin
        s := qry.Fields[0].AsString;
        if cmbGrupoUsuario.Properties.Items.IndexOf(s) < 0 then
          cmbGrupoUsuario.Properties.Items.Add(s);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  end;
  cmbGrupoUsuario.Visible := True;
  cmbGrupoUsuario.ItemIndex := 0;
  btnChangeId.Visible := False;
  CargarParametros(JvInspector1, oUser, '');
  RestaurarLayout;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

procedure TfrmMtoAppParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
  bSoloLectura: Boolean;
begin
  if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    case cmbGrupoUsuario.ItemIndex of
      0: begin sUsuario := oUser;  sGrupo := '';     end;
      1: begin sUsuario := '';     sGrupo := oGroup; end;
      2: begin sUsuario := '';     sGrupo := oAll;   end;
    else
      begin
        // Sujeto del desplegable completo (solo visible a administradores):
        // se carga por su nombre tal cual.
        sUsuario := cmbGrupoUsuario.Text;
        sGrupo   := '';
      end;
    end;
    CargarParametros(JvInspector1, sUsuario, sGrupo);
    // Un usuario normal edita lo suyo y lo de su grupo; los parametros de
    // 'Todos' (y cualquier otro sujeto) solo los ve en modo lectura. Los
    // administradores editan todo.
    bSoloLectura := (oRootGroup <> 'S') and
                    (not SameText(cmbGrupoUsuario.Text, oUser)) and
                    (not SameText(cmbGrupoUsuario.Text, oGroup));
    JvInspector1.ReadOnly := bSoloLectura;
    AplicarBloqueoParametros;
    btnGuardar.Enabled    := not bSoloLectura;
    actGuardar.Enabled    := not bSoloLectura;
  end;
end;

procedure TfrmMtoAppParam.actGuardarExecute(Sender: TObject);
begin
  inherited;
  btnGuardarClick(Sender);
  Close;
end;

procedure TfrmMtoAppParam.actSalirExecute(Sender: TObject);
begin
  inherited;
  // Solo pedimos confirmación si hay cambios reales sin guardar
  if not HayCambiosPendientes then
  begin
    Close;
    Exit;
  end;
  if MessageDlg('¿Seguro que desea salir sin guardar?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Close;
end;

function TfrmMtoAppParam.HayCambiosPendientes: Boolean;
var
  i, j         : Integer;
  NodoPrincipal: TJvCustomInspectorItem;
  ParamItem    : TJvCustomInspectorItem;
  ValorActual  : string;
begin
  // Recorremos los items igual que en btnGuardarClick comparando contra los
  // valores capturados al cargar; basta un cambio para devolver True
  Result := False;
  if FValoresOriginales = nil then
    Exit;
  JvInspector1.SaveValues;
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if not (NodoPrincipal is TJvInspectorCustomCategoryItem) then
      Continue;
    for j := 0 to NodoPrincipal.Count - 1 do
    begin
      ParamItem := NodoPrincipal.Items[j];
      if ParamItem.Data <> nil then
        case ParamItem.Data.TypeInfo.Kind of
          tkEnumeration:
            if ParamItem.Data.AsOrdinal <> 0 then
              ValorActual := 'True'
            else
              ValorActual := 'False';
          tkInteger:
            ValorActual := IntToStr(ParamItem.Data.AsOrdinal);
        else
          ValorActual := ParamItem.Data.AsString;
        end
      else
        ValorActual := '';
      if UsuarioPuedeEditarParametro(ParamItem.Name) and
         FValoresOriginales.ContainsKey(ParamItem.Name) then
      begin
        if not SameText(FValoresOriginales[ParamItem.Name], ValorActual) then
          Exit(True);
      end
      else if UsuarioPuedeEditarParametro(ParamItem.Name) then
      begin
        // Item nuevo no capturado: lo consideramos cambio si no está vacío
        if ValorActual <> '' then
          Exit(True);
      end;
    end;
  end;
end;

procedure TfrmMtoAppParam.btnChangeIdClick(Sender: TObject);
var
  qry     : TUniQuery;
  usuarios: TStringList;
  sUsuario: string;
begin
  qry      := TUniQuery.Create(nil);
  usuarios := TStringList.Create;
  try
    qry.Connection := oConn;
    qry.SQL.Text   :=
      'SELECT ''Todos'' AS S ' +
      ' UNION SELECT GRUPO_USUGRP FROM fza_usuarios_grupos ' +
      ' UNION SELECT USUARIO_USU FROM fza_usuarios ' +
      ' ORDER BY S';
    qry.Open;
    while not qry.Eof do
    begin
      usuarios.Add(qry.Fields[0].AsString);
      qry.Next;
    end;

    if usuarios.Count = 0 then
    begin
      ShowMessage(
        'No hay usuarios con parámetros guardados para este formulario.');
      Exit;
    end;

    sUsuario := usuarios[0];
    if InputQuery('Cambiar usuario',
                  'Usuarios disponibles:' + sLineBreak + usuarios.CommaText +
                  sLineBreak + sLineBreak + 'Introduce el nombre de usuario:',
                  sUsuario) then
    begin
      if usuarios.IndexOf(sUsuario) < 0 then
        ShowMessage('Usuario no encontrado: ' + sUsuario)
      else
      begin
        CargarParametros(JvInspector1, sUsuario, '');
        if cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario) < 0 then
          cmbGrupoUsuario.Properties.Items.Add(sUsuario);
        cmbGrupoUsuario.ItemIndex :=
          cmbGrupoUsuario.Properties.Items.IndexOf(sUsuario);
      end;
    end;
  finally
    FreeAndNil(usuarios);
    FreeAndNil(qry);
  end;
end;

// -----------------------------------------------------------------------
// FILTRADO Y BÚSQUEDA
// -----------------------------------------------------------------------

function TfrmMtoAppParam.QuitarTildes(const Texto: string): string;
var
  i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
    case Result[i] of
      'á','à','ä','â': Result[i] := 'a';
      'é','è','ë','ê': Result[i] := 'e';
      'í','ì','ï','î': Result[i] := 'i';
      'ó','ò','ö','ô': Result[i] := 'o';
      'ú','ù','ü','û': Result[i] := 'u';
      'Á','À','Ä','Â': Result[i] := 'A';
      'É','È','Ë','Ê': Result[i] := 'E';
      'Í','Ì','Ï','Î': Result[i] := 'I';
      'Ó','Ò','Ö','Ô': Result[i] := 'O';
      'Ú','Ù','Ü','Û': Result[i] := 'U';
    end;
end;

function TfrmMtoAppParam.BuscarItemPorNombre(
  ItemPadre: TJvCustomInspectorItem;
  const Nombre: string): TJvCustomInspectorItem;
var
  i        : Integer;
  Encontrado: TJvCustomInspectorItem;
begin
  Result := nil;
  for i := 0 to ItemPadre.Count - 1 do
  begin
    if SameText(ItemPadre.Items[i].Name, Nombre) then
      Exit(ItemPadre.Items[i]);
    if ItemPadre.Items[i] is TJvInspectorCustomCategoryItem then
    begin
      Encontrado := BuscarItemPorNombre(ItemPadre.Items[i], Nombre);
      if Encontrado <> nil then Exit(Encontrado);
    end;
  end;
end;

procedure TfrmMtoAppParam.FiltrarVerticalGrid(Grid: TJvInspector;
                                              Texto: string);
var
  TextoBusquedaLimpio: string;

  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var
    Coincide, HijoVisible: Boolean;
    i: Integer;
  begin
    Coincide     := (Texto = '') or
                    AnsiContainsText(QuitarTildes(Row.DisplayName),
                                     TextoBusquedaLimpio);
    HijoVisible  := False;
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    Row.Visible := Coincide or HijoVisible;
    if (Row is TJvInspectorCustomCategoryItem) and
       HijoVisible and (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;

var
  i: Integer;
begin
  Grid.BeginUpdate;
  try
    TextoBusquedaLimpio := QuitarTildes(Texto);
    for i := 0 to Grid.Root.Count - 1 do
      ProcesarFila(Grid.Root.Items[i]);
  finally
    Grid.EndUpdate;
  end;
end;

procedure TfrmMtoAppParam.cxButtonEdit1PropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoAppParam.edtBusquedaKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

end.
