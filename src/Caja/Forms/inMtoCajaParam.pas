{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaParam                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de mantenimiento de parametros de caja.                        }
{    Editor tipo inspector con categorias para la configuracion del TPV.       }
{******************************************************************************}
unit inMtoCajaParam;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, // Añadido Generics
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxFilter, dxScrollbarAnnotations, cxEdit,
  cxCheckBox, cxInplaceContainer, cxTextEdit, cxContainer,
  inLibGlobalVar, dxCoreGraphics, cxMaskEdit, cxButtonEdit, cxSpinEdit,
  Vcl.ExtCtrls, inMtoFrmBase, Uni, cxDropDownEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons, JvComponentBase, JvInspector, JvExControls, System.Actions,
  Vcl.ActnList, Vcl.Printers, System.UITypes, inLibParametrosIntf;

type
  // Tipos de punteros necesarios para la generación dinámica en JvInspector
  PBoolean = ^Boolean;
  PInteger = ^Integer;
  PString  = ^String;

  TfrmMtoCajaParam = class(TFrmBase)
    Panel1: TPanel;
    edtBusqueda: TcxButtonEdit;
    Panel2: TPanel;
    cmbGrupoUsuario: TcxComboBox;
    btnGuardar: TcxButton;
    btnChangeId: TcxButton;
    JvInspector1: TJvInspector;
    JvInspectorDotNETPainter1: TJvInspectorDotNETPainter;
    ActionList1: TActionList;
    actGuardar: TAction;
    actSalir: TAction;
    actGuardarLayout: TAction;

    procedure cxButtonEdit1PropertiesButtonClick(Sender: TObject;
                                                 AButtonIndex: Integer);
    procedure edtBusquedaKeyDown(Sender: TObject;
                                 var Key: Word;
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
    procedure FormKeyDown(Sender: TObject;
                          var Key: Word;
                          Shift: TShiftState);
  private
    // Listas para gestionar la memoria dinámica de los parámetros
    FBools: TList<PBoolean>;
    FInts:  TList<PInteger>;
    FStrs:  TList<PString>;
    FValoresOriginales: TDictionary<string, string>;
    FParametrosEdicion: IParametrosEdicion;
    procedure CapturarValoresOriginales;
    function  HayCambiosPendientes: Boolean;
    procedure LimpiarMemoria;
    procedure ResetearADefectos;
    function  ObtenerCategoria(
      const NombreCat: string): TJvInspectorCustomCategoryItem;
    function  QuitarTildes(const Texto: string): string;
    function  BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                                  const Nombre: string): TJvCustomInspectorItem;
//    procedure GuardarNodos(ItemPadre: TJvCustomInspectorItem; qryS:TUniQuery);
    procedure FiltrarVerticalGrid(Grid: TJvInspector; Texto: string);
    procedure CargarParametros(Grid: TJvInspector;
                               const pUsuario,
                               pGrupo: string);
    procedure ConstruirInspector;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure GetTipoImpresionList(Sender: TJvCustomInspectorItem;
                                   Strings: TStrings);
    procedure GetImpresorasList(Sender: TJvCustomInspectorItem;
                                Strings: TStrings);
    procedure GetTarifasList(Sender: TJvCustomInspectorItem;
                             Strings: TStrings);
  end;

implementation

{$R *.dfm}

uses
  StrUtils, inLibLayoutForm, inLibLog, inLibMsgCaja;

// ----------------------------------------------------------------------
// GESTIÓN DE MEMORIA Y CICLO DE VIDA
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.FormCreate(Sender: TObject);
var
  Proveedor: IProveedorParametrosEdicion;
begin
  inherited;
  if not Supports(Owner, IProveedorParametrosEdicion, Proveedor) then
    raise Exception.Create(SErrorProveedorParametrosCajaNoConfigurado);
  FParametrosEdicion := Proveedor.ParametrosCajaEdicion;
  if not Assigned(FParametrosEdicion) then
    raise Exception.Create(SErrorParametrosCajaEditablesNoConfigurados);
  if jvntrstb1 <> nil then
    jvntrstb1.EnterAsTab := False;
  FBools := TList<PBoolean>.Create;
  FInts  := TList<PInteger>.Create;
  FStrs  := TList<PString>.Create;
  FValoresOriginales := TDictionary<string, string>.Create;
end;

procedure TfrmMtoCajaParam.FormKeyDown(Sender: TObject;
                                       var Key: Word;
                                       Shift: TShiftState);
var
  ControlActivo: TWinControl;
  EsBoton      : Boolean;
  EsInspector  : Boolean;
begin
  if (Key = VK_RETURN) and
     (not (ssCtrl in Shift)) and
     (not (ssAlt in Shift)) then
  begin
    ControlActivo := Screen.ActiveControl;
    EsBoton       := (ControlActivo <> nil) and
                     (ControlActivo is TcxButton);
    EsInspector   := (ControlActivo <> nil) and
                     ((ControlActivo = JvInspector1) or
                      JvInspector1.ContainsControl(ControlActivo));
    if (not EsBoton) and (not EsInspector) then
    begin
      Key := 0;
      if ActiveControl <> nil then
        SelectNext(ActiveControl, not (ssShift in Shift), True)
      else
        SelectNext(Self, True, True);
    end;
  end;
end;

procedure TfrmMtoCajaParam.FormDestroy(Sender: TObject);
begin
  FParametrosEdicion := nil;
  LimpiarMemoria;
  FreeAndNil(FBools);
  FreeAndNil(FInts);
  FreeAndNil(FStrs);
  FreeAndNil(FValoresOriginales);
  inherited;
end;

procedure TfrmMtoCajaParam.CapturarValoresOriginales;
var
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorExtraido: string;
begin
  FValoresOriginales.Clear;
  for i := 0 to JvInspector1.Root.Count - 1 do
  begin
    NodoPrincipal := JvInspector1.Root.Items[i];
    if NodoPrincipal is TJvInspectorCustomCategoryItem then
    begin
      for j := 0 to NodoPrincipal.Count - 1 do
      begin
        ParamItem := NodoPrincipal.Items[j];
        if ParamItem.Data <> nil then
        begin
          case ParamItem.Data.TypeInfo.Kind of
            tkEnumeration:
              if ParamItem.Data.AsOrdinal <> 0 then ValorExtraido :=
                'True' else ValorExtraido := 'False';
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
end;

procedure TfrmMtoCajaParam.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoCajaParam.LimpiarMemoria;
var
  pB: PBoolean; pI: PInteger; pS: PString;
begin
  // Liberamos la memoria de los punteros que asignamos a JvInspector.
  // Es vital tiparlos (Dispose) para que los strings decremente su contador de
  // referencias.
  for pB in FBools do Dispose(pB);
  FBools.Clear;

  for pI in FInts do Dispose(pI);
  FInts.Clear;

  for pS in FStrs do Dispose(pS);
  FStrs.Clear;
end;

// ----------------------------------------------------------------------
// CONSTRUCCIÓN DINÁMICA DE LA INTERFAZ
// ----------------------------------------------------------------------

function TfrmMtoCajaParam.ObtenerCategoria(
  const NombreCat: string): TJvInspectorCustomCategoryItem;
var
  i: Integer;
begin
  // Busca si la categoría ya existe; si no, la crea al vuelo
  for i := 0 to JvInspector1.Root.Count - 1 do
    if (JvInspector1.Root.Items[i] is TJvInspectorCustomCategoryItem) and
       SameText(JvInspector1.Root.Items[i].DisplayName, NombreCat) then
      Exit(TJvInspectorCustomCategoryItem(JvInspector1.Root.Items[i]));

  Result := TJvInspectorCustomCategoryItem.Create(JvInspector1.Root, nil);
  Result.DisplayName := NombreCat;
  Result.Expanded := True; // Expandir por defecto
end;

procedure TfrmMtoCajaParam.ConstruirInspector;
var
  Parametros: TArray<TParamInfo>;
  Param: TParamInfo;
  CatItem: TJvInspectorCustomCategoryItem;
  ItemCombo: TJvCustomInspectorItem;
  DescripcionTraducida: string;
  pBool: PBoolean; pInt: PInteger; pStr: PString;
begin
  LimpiarMemoria;
  Parametros := FParametrosEdicion.ListarDefiniciones;
  JvInspector1.BeginUpdate;
  try
    JvInspector1.Root.Clear;

    // La instantánea evita exponer el diccionario interno al editor.
    for Param in Parametros do
    begin
      CatItem := ObtenerCategoria(
        TraducirCategoriaParametro(
          'inMtoCajaParam',
          Param.Categoria));
      DescripcionTraducida :=
        TraducirDescripcionParametro(
          'inMtoCajaParam',
          Param);

      case Param.Tipo of
        tpBoolean:
          begin
            New(pBool);
            FBools.Add(pBool);
            pBool^ := SameText(Param.ValorPorDefecto,
                               'True') or (Param.ValorPorDefecto = '1');
            with TJvInspectorVarData.New(CatItem,
                                         Param.Nombre,
                                         TypeInfo(Boolean),
                                         pBool) do
              DisplayName := DescripcionTraducida;
          end;
        tpInteger:
          begin
            New(pInt);
            FInts.Add(pInt);
            pInt^ := StrToIntDef(Param.ValorPorDefecto, 0);
            with TJvInspectorVarData.New(CatItem,
                                         Param.Nombre,
                                         TypeInfo(Integer),
                                         pInt) do
              DisplayName := DescripcionTraducida;
          end;
        tpString:
          begin
            New(pStr);
            FStrs.Add(pStr);
            pStr^ := Param.ValorPorDefecto;
            ItemCombo := TJvInspectorVarData.New(CatItem,
                                                 Param.Nombre,
                                                 TypeInfo(string),
                                                 pStr);
            ItemCombo.DisplayName := DescripcionTraducida;
            if SameText(Param.Nombre, 'vgerTipoImpresion') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList];
              ItemCombo.OnGetValueList := GetTipoImpresionList;
            end
            else if SameText(Param.Nombre, 'vgerDefPrinter') then
            begin
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList,
                                                         iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetImpresorasList;
            end
            else if SameText(Param.Nombre, 'vgerDefTarifa') then
            begin
              // Única definición de la tarifa por defecto del sistema.
              ItemCombo.Flags := ItemCombo.Flags + [iifValueList,
                                                         iifAllowNonListValues];
              ItemCombo.OnGetValueList := GetTarifasList;
            end;
          end;
      end;
    end;
  finally
    JvInspector1.EndUpdate;
  end;
end;

// ----------------------------------------------------------------------
// LAYOUT (geometría + divider del inspector)
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarDividerInspector('Divider', JvInspector1);
    if Layout.PreguntarYGrabar('Personalización Parámetros Caja') then
      ShowMessage(SInfoLayoutCajaGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmMtoCajaParam.RestaurarLayout;
var
  Layout: TLayoutLoader;
begin
  Layout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
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

procedure TfrmMtoCajaParam.actGuardarLayoutExecute(Sender: TObject);
begin
  GuardarLayout;
end;

// ----------------------------------------------------------------------
// CARGA Y GUARDADO (LÓGICA GENÉRICA)
// ----------------------------------------------------------------------

procedure TfrmMtoCajaParam.ResetearADefectos;
var
  Parametros: TArray<TParamInfo>;
  Param: TParamInfo;
  ItemData: TJvCustomInspectorItem;
begin
  // Fuerza a los controles visuales a mostrar el valor por defecto antes de
  // cargar de DB
  Parametros := FParametrosEdicion.ListarDefiniciones;
  for Param in Parametros do
  begin
    ItemData := BuscarItemPorNombre(JvInspector1.Root, Param.Nombre);
    if ItemData <> nil then
      ItemData.DisplayValue := Param.ValorPorDefecto;
  end;
end;

procedure TfrmMtoCajaParam.CargarParametros(Grid: TJvInspector;
                                            const pUsuario,
                                            pGrupo: string);
var
  qry: TUniQuery;
  SubKey, ValorStr: string;
  ItemData: TJvCustomInspectorItem;
begin
  ResetearADefectos;
  Grid.Refresh;

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
            'CALL PRC_GETPERFILFORMULARIO(:p_usuario, :p_grupo, :p_formulario)';
    qry.ParamByName('p_usuario').AsString    := pUsuario;
    qry.ParamByName('p_grupo').AsString      := pGrupo;
    qry.ParamByName('p_formulario').AsString := 'frmMtoCajaParam';
    qry.Open;

    Grid.BeginUpdate;
    try
      while not qry.Eof do
      begin
        SubKey := qry.FieldByName('SUBKEY_USUPER').AsString;
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
            // El resto de parametros del perfil se sigue aplicando.
            on E: Exception do
              inLibLog.Log.LogWarning(
                'CajaParam: no se pudo aplicar el parametro "' +
                SubKey + '": ' + E.Message);
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

procedure TfrmMtoCajaParam.btnGuardarClick(Sender: TObject);
var
  qry: TUniQuery;
  sUsuarioGrupo: string;
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorAGuardar: string;
  GuardadosCount: Integer; // NUEVO: Para saber si ha habido cambios
begin
  JvInspector1.SaveValues;
  if cmbGrupoUsuario.ItemIndex = -1 then Exit;
  sUsuarioGrupo := cmbGrupoUsuario.Text;

  GuardadosCount := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text := 'CALL PRC_SETPERFILFORMULARIO(:p_usuario_grupo, ' +
                    '                             :p_formulario, ' +
                    '                             :p_subkey, ' +
                    '                             :p_value)';
    for i := 0 to JvInspector1.Root.Count - 1 do
    begin
      NodoPrincipal := JvInspector1.Root.Items[i];
      if NodoPrincipal is TJvInspectorCustomCategoryItem then
      begin
        for j := 0 to NodoPrincipal.Count - 1 do
        begin
          ParamItem := NodoPrincipal.Items[j];
          if ParamItem.Data <> nil then
          begin
            case ParamItem.Data.TypeInfo.Kind of
              tkEnumeration:
                if ParamItem.Data.AsOrdinal <> 0 then ValorAGuardar :=
                  'True' else ValorAGuardar := 'False';
              tkInteger:
                ValorAGuardar := IntToStr(ParamItem.Data.AsOrdinal);
              else
                ValorAGuardar := ParamItem.Data.AsString;
            end;
          end
          else
            ValorAGuardar := '';
          if FValoresOriginales.ContainsKey(ParamItem.Name) then
          begin
            // SameText protege contra posibles variaciones de
            // mayúsculas/minúsculas
            if SameText(FValoresOriginales[ParamItem.Name], ValorAGuardar) then
              Continue;
          end;
          qry.ParamByName('p_usuario_grupo').AsString := sUsuarioGrupo;
          qry.ParamByName('p_formulario').AsString    := 'frmMtoCajaParam';
          qry.ParamByName('p_subkey').AsString        := ParamItem.Name;
          qry.ParamByName('p_value').AsString         := ValorAGuardar;
          qry.Execute;
          Inc(GuardadosCount); // Contamos un guardado real
          FValoresOriginales.AddOrSetValue(ParamItem.Name, ValorAGuardar);
        end;
      end;
    end;
    if GuardadosCount > 0 then
    begin
      ShowMessage(Format(SInfoParametrosCajaGuardados,
                         [GuardadosCount, sUsuarioGrupo]));
      if (sUsuarioGrupo = IdentidadSesion.Usuario) or
         (sUsuarioGrupo = IdentidadSesion.Grupo) or
         (sUsuarioGrupo = oAll) then
        FParametrosEdicion.Recargar(
          IdentidadSesion.Usuario,
          IdentidadSesion.Grupo
        );
    end
    else
    begin
      ShowMessage(SInfoParametrosCajaSinCambios);
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TfrmMtoCajaParam.FormShow(Sender: TObject);
var
  qry: TUniQuery;
  s: string;
begin
  ConstruirInspector;
  cmbGrupoUsuario.Properties.Items.Clear;
  // Todo usuario gestiona sus propios parametros (IdentidadSesion.Usuario) y los de su
  // grupo (IdentidadSesion.Grupo), y puede consultar los de 'Todos' (oAll) en modo
  // solo lectura (lo aplica cmbGrupoUsuarioPropertiesChange).
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Usuario);
  cmbGrupoUsuario.Properties.Items.Add(IdentidadSesion.Grupo);
  cmbGrupoUsuario.Properties.Items.Add(oAll);
  // Solo los administradores ven ademas la lista completa de usuarios y
  // grupos del sistema (y pueden editarla).
  if IdentidadSesion.GrupoRaiz = 'S' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'SELECT ''Todos'' AS S ' +
        'UNION SELECT GRUPO_USUGRP FROM fza_usuarios_grupos ' +
        'UNION SELECT USUARIO_USU FROM fza_usuarios ' +
        'ORDER BY S';
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
  RestaurarLayout;
  if edtBusqueda.CanFocus then
    edtBusqueda.SetFocus;
end;

procedure TfrmMtoCajaParam.GetImpresorasList(
  Sender: TJvCustomInspectorItem; Strings: TStrings);
var
  i: Integer;
begin
  Strings.Clear;
  Strings.Add('');  // opción vacía: "sin impresora asignada"
  for i := 0 to Printer.Printers.Count - 1 do
    Strings.Add(Printer.Printers[i]);
end;

procedure TfrmMtoCajaParam.GetTipoImpresionList(Sender: TJvCustomInspectorItem;
                                                Strings: TStrings);
begin
  Strings.Clear;
  Strings.Add('ESC POS');
  Strings.Add('ESC POS NOQR');
  Strings.Add('EDITOR');
  Strings.Add('DEBUG');
end;

procedure TfrmMtoCajaParam.GetTarifasList(Sender: TJvCustomInspectorItem;
                                          Strings: TStrings);
var
  qry: TUniQuery;
begin
  Strings.Clear;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
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

function TfrmMtoCajaParam.BuscarItemPorNombre(ItemPadre: TJvCustomInspectorItem;
                                              const Nombre: string
): TJvCustomInspectorItem;
var
  i: Integer; Encontrado: TJvCustomInspectorItem;
begin
  Result := nil;
  for i := 0 to ItemPadre.Count - 1 do
  begin
    if SameText(ItemPadre.Items[i].Name, Nombre) then Exit(ItemPadre.Items[i]);
    if ItemPadre.Items[i] is TJvInspectorCustomCategoryItem then
    begin
      Encontrado := BuscarItemPorNombre(ItemPadre.Items[i], Nombre);
      if Encontrado <> nil then Exit(Encontrado);
    end;
  end;
end;

procedure TfrmMtoCajaParam.cmbGrupoUsuarioPropertiesChange(Sender: TObject);
var
  sUsuario, sGrupo: string;
  bSoloLectura: Boolean;
begin
  if cmbGrupoUsuario.ItemIndex >= 0 then
  begin
    case cmbGrupoUsuario.ItemIndex of
      0: begin sUsuario := IdentidadSesion.Usuario;  sGrupo := '';      end;
      1: begin sUsuario := '';     sGrupo := IdentidadSesion.Grupo;  end;
      2: begin sUsuario := '';     sGrupo := oAll;    end;
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
    bSoloLectura := (IdentidadSesion.GrupoRaiz <> 'S') and
                    (not SameText(cmbGrupoUsuario.Text, IdentidadSesion.Usuario)) and
                    (not SameText(cmbGrupoUsuario.Text, IdentidadSesion.Grupo));
    JvInspector1.ReadOnly := bSoloLectura;
    btnGuardar.Enabled    := not bSoloLectura;
    actGuardar.Enabled    := not bSoloLectura;
  end;
end;

procedure TfrmMtoCajaParam.actGuardarExecute(Sender: TObject);
begin
  inherited;
  btnGuardarClick(Sender);
  Close;
end;

procedure TfrmMtoCajaParam.actSalirExecute(Sender: TObject);
begin
  inherited;
  // Solo pedimos confirmación si hay cambios reales sin guardar
  if not HayCambiosPendientes then
  begin
    Close;
    Exit;
  end;
  if MessageDlg(SPreguntaSalirParametrosCajaSinGuardar,
                mtConfirmation,
                [mbYes, mbNo],
                0) = mrYes then
    Close;
end;

function TfrmMtoCajaParam.HayCambiosPendientes: Boolean;
var
  i, j: Integer;
  NodoPrincipal, ParamItem: TJvCustomInspectorItem;
  ValorActual: string;
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
      if FValoresOriginales.ContainsKey(ParamItem.Name) then
      begin
        if not SameText(FValoresOriginales[ParamItem.Name], ValorActual) then
          Exit(True);
      end
      else
      begin
        // Item nuevo no capturado: lo consideramos cambio si no está vacío
        if ValorActual <> '' then
          Exit(True);
      end;
    end;
  end;
end;

procedure TfrmMtoCajaParam.btnChangeIdClick(Sender: TObject);
var
  qry: TUniQuery;
  usuarios: TStringList;
  sUsuario: string;
begin
  qry := TUniQuery.Create(nil);
  usuarios := TStringList.Create;
  try
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text := 'SELECT ''Todos'' AS S ' +
                    'UNION SELECT GRUPO_USUGRP FROM fza_usuarios_grupos ' +
                    'UNION SELECT USUARIO_USU FROM fza_usuarios ' +
                    'ORDER BY S';
    qry.Open;
    while not qry.Eof do
    begin
      usuarios.Add(qry.Fields[0].AsString);
      qry.Next;
    end;

    if usuarios.Count = 0 then
    begin
      ShowMessage(SInfoUsuariosParametrosCajaNoEncontrados);
      Exit;
    end;

    sUsuario := usuarios[0];
    if InputQuery(STituloCambiarUsuarioParametrosCaja,
                  Format(SSolicitudCambiarUsuarioParametrosCaja,
                    [usuarios.CommaText]),
                  sUsuario) then
    begin
      if usuarios.IndexOf(sUsuario) < 0 then
        ShowMessage(Format(SErrorUsuarioParametrosCajaNoEncontrado,
          [sUsuario]))
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

function TfrmMtoCajaParam.QuitarTildes(const Texto: string): string;
var i: Integer;
begin
  Result := Texto;
  for i := 1 to Length(Result) do
    case Result[i] of
      'á', 'à', 'ä', 'â': Result[i] := 'a';
      'é', 'è', 'ë', 'ê': Result[i] := 'e';
      'í', 'ì', 'ï', 'î': Result[i] := 'i';
      'ó', 'ò', 'ö', 'ô': Result[i] := 'o';
      'ú', 'ù', 'ü', 'û': Result[i] := 'u';
      'Á', 'À', 'Ä', 'Â': Result[i] := 'A';
      'É', 'È', 'Ë', 'Ê': Result[i] := 'E';
      'Í', 'Ì', 'Ï', 'Î': Result[i] := 'I';
      'Ó', 'Ò', 'Ö', 'Ô': Result[i] := 'O';
      'Ú', 'Ù', 'Ü', 'Û': Result[i] := 'U';
    end;
end;

procedure TfrmMtoCajaParam.FiltrarVerticalGrid(Grid: TJvInspector;
                                               Texto: string);
var
  TextoBusquedaLimpio: string;
  function ProcesarFila(Row: TJvCustomInspectorItem): Boolean;
  var Coincide, HijoVisible: Boolean; i: Integer;
  begin
    Coincide := (Texto = '') or (AnsiContainsText(QuitarTildes(Row.DisplayName),
                                                  TextoBusquedaLimpio));
    HijoVisible := False;
    if Row is TJvInspectorCustomCategoryItem then
      for i := 0 to Row.Count - 1 do
        if ProcesarFila(Row.Items[i]) then HijoVisible := True;
    Row.Visible := Coincide or HijoVisible;
    if (Row is TJvInspectorCustomCategoryItem) and HijoVisible
       and (Texto <> '') then
      Row.Expanded := True;
    Result := Row.Visible;
  end;
var i: Integer;
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

procedure TfrmMtoCajaParam.cxButtonEdit1PropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  FiltrarVerticalGrid(JvInspector1, edtBusqueda.Text);
end;

procedure TfrmMtoCajaParam.edtBusquedaKeyDown(Sender: TObject;
                                              var Key: Word;
                                              Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    cxButtonEdit1PropertiesButtonClick(Sender, 0);
  end;
end;

end.
