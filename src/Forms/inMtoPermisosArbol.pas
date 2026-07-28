{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPermisosArbol                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Gestion profesional de permisos en forma de arbol.                        }
{    Pinta el menu de la aplicacion como un arbol (mas las categorias de       }
{    acciones, caja y arqueo) y permite conceder/denegar/heredar permisos      }
{    por sujeto (Todos, grupo o usuario), asi como transferir permisos de      }
{    un sujeto a otro. Hereda de TfrmMtoGen pero no usa data module: el        }
{    arbol y las consultas se gestionan en codigo contra inLibPermisosAdmin.   }
{******************************************************************************}
unit inMtoPermisosArbol;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Menus, Data.DB, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxClasses,
  cxLocalization, cxContainer, cxLabel, cxTextEdit, cxButtons, cxCheckBox,
  cxRadioGroup, cxDropDownEdit, cxPC, cxInplaceContainer, cxTL, cxTLData,
  dxSkinsCore, dxSkinsDefaultPainters, dxSkinsForm, dxScrollbarAnnotations,
  dxCore, dxDateRanges,
  inMtoGen, inLibUnitForm, inLibPermisosAdmin;

type
  TfrmMtoPermisosArbol = class(TfrmMtoGen)
    tsGestion: TcxTabSheet;
    pnlSujeto: TPanel;
    lblSujeto: TcxLabel;
    cbbSujeto: TcxComboBox;
    lblAvisoAdmin: TcxLabel;
    btnRecargar: TcxButton;
    pnlHerramientas: TPanel;
    btnExpandir: TcxButton;
    btnContraer: TcxButton;
    btnPermitirRama: TcxButton;
    btnDenegarRama: TcxButton;
    btnHeredarRama: TcxButton;
    lblFiltro: TcxLabel;
    edtFiltro: TcxTextEdit;
    pnlArbol: TPanel;
    pnlTransfer: TPanel;
    lblTransfer: TcxLabel;
    lblDe: TcxLabel;
    cbbOrigen: TcxComboBox;
    lblA: TcxLabel;
    cbbDestino: TcxComboBox;
    rgModo: TcxRadioGroup;
    chkSoloMenu: TcxCheckBox;
    btnCopiar: TcxButton;
  private
    FtlPermisos   : TcxTreeList;
    FColNombre    : TcxTreeListColumn;
    FColPermitido : TcxTreeListColumn;
    FColEstado    : TcxTreeListColumn;
    FColCodigo    : TcxTreeListColumn;
    FSujetos      : TArray<TPermisoSujeto>;
    FCatalogo     : TArray<TPermisoCodigo>;
    FSujetoActual : TPermisoSujeto;
    FExpSujeto    : TDictionary<string, string>;
    FExpGrupo     : TDictionary<string, string>;
    FExpTodos     : TDictionary<string, string>;
    FColocados    : TDictionary<string, Boolean>;
    FInicializando: Boolean;
    procedure ConstruirInterfaz;
    procedure ConstruirArbol;
    procedure AgregarNodosMenu(AParent: TcxTreeListNode; AItem: TMenuItem;
                               AWinf: TfzaWinF);
    procedure AgregarCategorias;
    procedure AnadirAccionesPantalla(AParent: TcxTreeListNode;
                                     const ACall: string);
    function  EsPermisoAccionGenerico(const ACodigo: string): Boolean;
    function  EsPantallaMto(const AUnitForm: string): Boolean;
    function  NuevoNodo(AParent: TcxTreeListNode;
                        const ANombre, ACodigo: string): TcxTreeListNode;
    function  TituloCategoria(const ACodigo: string): string;
    procedure PoblarCombos;
    function  DescripcionSujeto(const ASujeto: TPermisoSujeto): string;
    function  IndiceSujeto(const ANombre: string): Integer;
    procedure CargarValoresSujeto;
    procedure RefrescarValores;
    function  ResolverEfectivo(const ACodigo: string;
                               out AOrigen: string): Boolean;
    procedure FijarPermiso(const ACodigo: string; AValor: Boolean;
                           const ADescripcion: string);
    procedure AlternarHoja(ANode: TcxTreeListNode);
    procedure AplicarRama(ANode: TcxTreeListNode; AValor: Boolean);
    procedure HeredarRama(ANode: TcxTreeListNode);
    procedure AplicarFiltro(const ATexto: string);
    procedure cbbSujetoChange(Sender: TObject);
    procedure edtFiltroChange(Sender: TObject);
    procedure btnRecargarClick(Sender: TObject);
    procedure btnExpandirClick(Sender: TObject);
    procedure btnContraerClick(Sender: TObject);
    procedure btnPermitirRamaClick(Sender: TObject);
    procedure btnDenegarRamaClick(Sender: TObject);
    procedure btnHeredarRamaClick(Sender: TObject);
    procedure btnCopiarClick(Sender: TObject);
    procedure tlPermisosDblClick(Sender: TObject);
    procedure tlPermisosKeyDown(Sender: TObject; var Key: Word;
                                Shift: TShiftState);
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    destructor Destroy; override;
  end;

var
  frmMtoPermisosArbol: TfrmMtoPermisosArbol;

implementation

uses
  System.StrUtils, System.Rtti, inMtoPrincipal, inLibMsg;

{$R *.dfm}

// Indices de columna del arbol (orden de creacion).
const
  cIdxNombre    = 0;
  cIdxPermitido = 1;
  cIdxEstado    = 2;
  cIdxCodigo    = 3;

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPermisosArbol }

// ===========================================================================
//   Construccion de la interfaz (arbol en codigo)
// ===========================================================================

procedure TfrmMtoPermisosArbol.ConstruirInterfaz;
var
  itm: TcxRadioGroupItem;
begin
  // Ocultar elementos heredados de TfrmMtoGen que no aplican aqui: la
  // barra de busqueda/exportacion y los botones Grabar/Cancelar (el alta
  // de permisos es inmediata). Se conserva el boton Salir.
  pnlTopPage.Visible  := False;
  btnGrabar.Visible   := False;
  btnCancelar.Visible := False;
  FtlPermisos := TcxTreeList.Create(Self);
  FtlPermisos.Parent := pnlArbol;
  FtlPermisos.Align  := alClient;
  FtlPermisos.OptionsBehavior.Sorting    := False;
  FtlPermisos.OptionsData.Editing        := False;
  FtlPermisos.OptionsData.Deleting       := False;
  FtlPermisos.OptionsData.Inserting      := False;
  FtlPermisos.OptionsSelection.MultiSelect := False;
  FtlPermisos.OptionsView.Buttons        := True;
  FtlPermisos.OptionsView.Headers        := True;
  FtlPermisos.OptionsView.ShowRoot       := True;
  if FtlPermisos.Bands.Count = 0 then
    FtlPermisos.Bands.Add;
  FColNombre := FtlPermisos.CreateColumn;
  FColNombre.Position.BandIndex := 0;
  FColNombre.Caption.Text       := 'Permiso / Menu';
  FColNombre.Width              := 360;
  FColNombre.Options.Editing    := False;
  FColPermitido := FtlPermisos.CreateColumn;
  FColPermitido.Position.BandIndex := 0;
  FColPermitido.Caption.Text       := 'Permitido';
  FColPermitido.Width              := 80;
  FColPermitido.DataBinding.ValueType := 'Boolean';
  FColPermitido.PropertiesClass    := TcxCheckBoxProperties;
  FColPermitido.Options.Editing    := False;
  FColEstado := FtlPermisos.CreateColumn;
  FColEstado.Position.BandIndex := 0;
  FColEstado.Caption.Text       := 'Estado';
  FColEstado.Width              := 250;
  FColEstado.Options.Editing    := False;
  FColCodigo := FtlPermisos.CreateColumn;
  FColCodigo.Position.BandIndex := 0;
  FColCodigo.Caption.Text       := 'Codigo';
  FColCodigo.Width              := 220;
  FColCodigo.Options.Editing    := False;
  FtlPermisos.OnDblClick := tlPermisosDblClick;
  FtlPermisos.OnKeyDown  := tlPermisosKeyDown;
  // Modo de copia del bloque de transferencia.
  rgModo.Properties.Items.Clear;
  itm := rgModo.Properties.Items.Add;
  itm.Caption := 'Combinar (agregar y actualizar)';
  itm := rgModo.Properties.Items.Add;
  itm.Caption := 'Reemplazar todos los del destino';
  rgModo.ItemIndex := 0;
  // Eventos de los controles del .dfm (asignados en codigo).
  cbbSujeto.Properties.OnChange := cbbSujetoChange;
  edtFiltro.Properties.OnChange := edtFiltroChange;
  btnRecargar.OnClick     := btnRecargarClick;
  btnExpandir.OnClick     := btnExpandirClick;
  btnContraer.OnClick     := btnContraerClick;
  btnPermitirRama.OnClick := btnPermitirRamaClick;
  btnDenegarRama.OnClick  := btnDenegarRamaClick;
  btnHeredarRama.OnClick  := btnHeredarRamaClick;
  btnCopiar.OnClick       := btnCopiarClick;
  FColocados := TDictionary<string, Boolean>.Create;
end;

function TfrmMtoPermisosArbol.NuevoNodo(AParent: TcxTreeListNode;
  const ANombre, ACodigo: string): TcxTreeListNode;
begin
  if AParent = nil then
    Result := FtlPermisos.Root.AddChild
  else
    Result := AParent.AddChild;
  Result.Texts[cIdxNombre]     := ANombre;
  Result.Texts[cIdxCodigo]     := ACodigo;
  Result.Texts[cIdxEstado]     := '';
  Result.Values[cIdxPermitido] := Null;
  if ACodigo <> '' then
    FColocados.AddOrSetValue(ACodigo, True);
end;

procedure TfrmMtoPermisosArbol.AgregarNodosMenu(AParent: TcxTreeListNode;
  AItem: TMenuItem; AWinf: TfzaWinF);
var
  nombre, code, sCall: string;
  node: TcxTreeListNode;
  ofza: TfzaForm;
  i: Integer;
begin
  if AItem.Caption <> '-' then
  begin
    nombre := Trim(StringReplace(AItem.Caption, '&', '', [rfReplaceAll]));
    code := '';
    // Solo las hojas (sin submenu) son permisos editables. Para cada hoja
    // el codigo lo da CodigoMenu: 'menu.<CALL>' si el item esta en
    // fza_winforms, o 'menu.<Name>' si no (items abiertos directamente,
    // p.ej. Parametros de Caja, Compras, copias de seguridad...).
    if (AItem.Count = 0) and Assigned(AWinf) then
      code := AWinf.CodigoMenu(AItem);
    node := NuevoNodo(AParent, nombre, code);
    // Los permisos de accion por pantalla (consultar / insertar / ...)
    // solo aplican a las pantallas que derivan de TfrmMtoGen. Las de caja
    // y demas (que NO son Mtos) solo tienen sus permisos especiales
    // (caja.*, arqueo.*...), que aparecen en las categorias.
    if (AItem.Count = 0) and Assigned(AWinf) then
    begin
      sCall := AWinf.CallRegistrado(AItem);
      if sCall <> '' then
      begin
        ofza := AWinf.GetElement(sCall);
        if (ofza <> nil) and EsPantallaMto(ofza.UnitForm) then
          AnadirAccionesPantalla(node, sCall);
      end;
    end;
    for i := 0 to AItem.Count - 1 do
      AgregarNodosMenu(node, AItem.Items[i], AWinf);
  end;
end;

procedure TfrmMtoPermisosArbol.AgregarCategorias;
var
  catNodes: TDictionary<string, TcxTreeListNode>;
  i: Integer;
  titulo, nombre: string;
  catNode: TcxTreeListNode;
begin
  catNodes := TDictionary<string, TcxTreeListNode>.Create;
  try
    for i := 0 to High(FCatalogo) do
    begin
      if (not FColocados.ContainsKey(FCatalogo[i].Codigo)) and
         (not EsPermisoAccionGenerico(FCatalogo[i].Codigo)) then
      begin
        titulo := TituloCategoria(FCatalogo[i].Codigo);
        if not catNodes.TryGetValue(titulo, catNode) then
        begin
          catNode := NuevoNodo(nil, titulo, '');
          catNodes.Add(titulo, catNode);
        end;
        nombre := FCatalogo[i].Descripcion;
        if nombre = '' then
          nombre := FCatalogo[i].Codigo;
        NuevoNodo(catNode, nombre, FCatalogo[i].Codigo);
      end;
    end;
  finally
    FreeAndNil(catNodes);
  end;
end;

function TfrmMtoPermisosArbol.EsPermisoAccionGenerico(
  const ACodigo: string): Boolean;
begin
  // Las acciones reales de un mantenimiento cuelgan de su propia pantalla.
  Result := StartsText('accion.', ACodigo);
end;

procedure TfrmMtoPermisosArbol.AnadirAccionesPantalla(
  AParent: TcxTreeListNode; const ACall: string);
begin
  NuevoNodo(AParent, 'Consultar / buscar',  ACall + '.consultar');
  NuevoNodo(AParent, 'Alta de registros',   ACall + '.insertar');
  NuevoNodo(AParent, 'Modificar registros', ACall + '.modificar');
  NuevoNodo(AParent, 'Borrar registros',    ACall + '.borrar');
  NuevoNodo(AParent, 'Exportar a Excel',    ACall + '.excel');
  NuevoNodo(AParent, 'Imprimir informes',   ACall + '.imprimir');
end;

function TfrmMtoPermisosArbol.EsPantallaMto(const AUnitForm: string): Boolean;
var
  ctx: TRttiContext;
  lType: TRttiType;
begin
  // Resuelve la clase del formulario por RTTI y comprueba si hereda de
  // TfrmMtoGen. Asi solo los mantenimientos reciben los permisos de
  // accion; las pantallas de caja, menus y demas quedan fuera.
  Result := False;
  if AUnitForm <> '' then
  begin
    ctx := TRttiContext.Create;
    try
      lType := ctx.FindType(AUnitForm);
      if (lType <> nil) and (lType.IsInstance) then
        Result := lType.AsInstance.MetaclassType.InheritsFrom(TfrmMtoGen);
    finally
      ctx.Free;
    end;
  end;
end;

function TfrmMtoPermisosArbol.TituloCategoria(const ACodigo: string): string;
var
  p: Integer;
  pref: string;
begin
  p := Pos('.', ACodigo);
  if p > 0 then
    pref := Copy(ACodigo, 1, p - 1)
  else
    pref := ACodigo;
  if SameText(pref, 'caja') then
    Result := 'Caja (TPV)'
  else if SameText(pref, 'arqueo') then
    Result := 'Arqueo'
  else if SameText(pref, 'menu') then
    Result := 'Menus no visibles'
  else
    Result := 'Otros';
end;

procedure TfrmMtoPermisosArbol.ConstruirArbol;
var
  frmPrin: TfrmMtoPrincipal;
  i: Integer;
begin
  FtlPermisos.Clear;
  FColocados.Clear;
  if (Self.Owner is TfrmMtoPrincipal) then
  begin
    frmPrin := TfrmMtoPrincipal(Self.Owner);
    FtlPermisos.BeginUpdate;
    try
      if frmPrin.Menu <> nil then
        for i := 0 to frmPrin.Menu.Items.Count - 1 do
          AgregarNodosMenu(nil, frmPrin.Menu.Items[i], frmPrin.oFzaWinf);
      AgregarCategorias;
    finally
      FtlPermisos.EndUpdate;
    end;
  end;
end;

// ===========================================================================
//   Sujetos y combos
// ===========================================================================

function TfrmMtoPermisosArbol.DescripcionSujeto(
  const ASujeto: TPermisoSujeto): string;
begin
  case ASujeto.Tipo of
    tsTodos:
      Result := 'Todos (valores por defecto)';
    tsGrupo:
      if ASujeto.EsAdmin then
        Result := 'Grupo: ' + ASujeto.Nombre + ' (administrador)'
      else
        Result := 'Grupo: ' + ASujeto.Nombre;
    tsUsuario:
      Result := 'Usuario: ' + ASujeto.Nombre + ' [grupo ' +
                ASujeto.Grupo + ']';
  else
    Result := ASujeto.Nombre;
  end;
end;

procedure TfrmMtoPermisosArbol.PoblarCombos;
var
  i: Integer;
  s: string;
begin
  cbbSujeto.Properties.Items.Clear;
  cbbOrigen.Properties.Items.Clear;
  cbbDestino.Properties.Items.Clear;
  for i := 0 to High(FSujetos) do
  begin
    s := DescripcionSujeto(FSujetos[i]);
    cbbSujeto.Properties.Items.Add(s);
    cbbOrigen.Properties.Items.Add(s);
    cbbDestino.Properties.Items.Add(s);
  end;
  if Length(FSujetos) > 0 then
  begin
    cbbSujeto.ItemIndex := 0;
    cbbOrigen.ItemIndex := 0;
    if Length(FSujetos) > 1 then
      cbbDestino.ItemIndex := 1
    else
      cbbDestino.ItemIndex := 0;
  end;
end;

function TfrmMtoPermisosArbol.IndiceSujeto(const ANombre: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FSujetos) do
    if (Result < 0) and SameText(FSujetos[i].Nombre, ANombre) then
      Result := i;
end;

procedure TfrmMtoPermisosArbol.CargarValoresSujeto;
begin
  FreeAndNil(FExpSujeto);
  FreeAndNil(FExpGrupo);
  FreeAndNil(FExpTodos);
  FExpSujeto := TPermisosAdmin.CargarExplicitos(
    ConexionPrincipal,
    FSujetoActual.Nombre);
  FExpTodos  := TPermisosAdmin.CargarExplicitos(ConexionPrincipal, 'Todos');
  if (FSujetoActual.Tipo = tsUsuario) and (FSujetoActual.Grupo <> '') then
    FExpGrupo := TPermisosAdmin.CargarExplicitos(
      ConexionPrincipal,
      FSujetoActual.Grupo)
  else
    FExpGrupo := nil;
  if FSujetoActual.EsAdmin then
    lblAvisoAdmin.Caption :=
      'Aviso: este sujeto es administrador; en ejecucion tiene TODOS los ' +
      'permisos, se marque lo que se marque aqui.'
  else
    lblAvisoAdmin.Caption := '';
  RefrescarValores;
end;

// ===========================================================================
//   Resolucion y refresco de valores
// ===========================================================================

function TfrmMtoPermisosArbol.ResolverEfectivo(const ACodigo: string;
  out AOrigen: string): Boolean;
var
  v: string;
begin
  Result  := True;
  AOrigen := 'Por defecto (permitido)';
  if (FExpTodos <> nil) and FExpTodos.TryGetValue(ACodigo, v) then
  begin
    Result  := (v = 'S');
    AOrigen := 'Heredado de Todos';
  end;
  if (FSujetoActual.Tipo = tsUsuario) and (FExpGrupo <> nil) and
     FExpGrupo.TryGetValue(ACodigo, v) then
  begin
    Result  := (v = 'S');
    AOrigen := 'Heredado del grupo ' + FSujetoActual.Grupo;
  end;
  if (FExpSujeto <> nil) and FExpSujeto.TryGetValue(ACodigo, v) then
  begin
    Result  := (v = 'S');
    AOrigen := 'Propio';
  end;
end;

procedure TfrmMtoPermisosArbol.RefrescarValores;
var
  i: Integer;
  procedure Contar(N: TcxTreeListNode; var APermit, ATotal: Integer);
  var
    j: Integer;
    code, o: string;
  begin
    code := N.Texts[cIdxCodigo];
    if code <> '' then
    begin
      Inc(ATotal);
      if ResolverEfectivo(code, o) then
        Inc(APermit);
    end;
    for j := 0 to N.Count - 1 do
      Contar(N.Items[j], APermit, ATotal);
  end;
  procedure Walk(N: TcxTreeListNode);
  var
    j, p, t: Integer;
    code, o: string;
    efec: Boolean;
  begin
    code := N.Texts[cIdxCodigo];
    if code <> '' then
    begin
      efec := ResolverEfectivo(code, o);
      N.Values[cIdxPermitido] := efec;
      if efec then
        N.Texts[cIdxEstado] := 'Permitido - ' + o
      else
        N.Texts[cIdxEstado] := 'Denegado - ' + o;
    end
    else
    begin
      p := 0;
      t := 0;
      Contar(N, p, t);
      N.Values[cIdxPermitido] := Null;
      if t > 0 then
        N.Texts[cIdxEstado] := Format('%d de %d permitidos', [p, t])
      else
        N.Texts[cIdxEstado] := '';
    end;
    for j := 0 to N.Count - 1 do
      Walk(N.Items[j]);
  end;
begin
  FtlPermisos.BeginUpdate;
  try
    for i := 0 to FtlPermisos.Root.Count - 1 do
      Walk(FtlPermisos.Root.Items[i]);
  finally
    FtlPermisos.EndUpdate;
  end;
end;

// ===========================================================================
//   Edicion de permisos
// ===========================================================================

procedure TfrmMtoPermisosArbol.FijarPermiso(const ACodigo: string;
  AValor: Boolean; const ADescripcion: string);
var
  sVal: string;
begin
  if AValor then
    sVal := 'S'
  else
    sVal := 'N';
  TPermisosAdmin.Establecer(
    ConexionPrincipal,
    ContextoSesion,
    FSujetoActual.Nombre,
    ACodigo, sVal, ADescripcion);
  if FExpSujeto <> nil then
    FExpSujeto.AddOrSetValue(ACodigo, sVal);
end;

procedure TfrmMtoPermisosArbol.AlternarHoja(ANode: TcxTreeListNode);
var
  code, o: string;
begin
  if ANode <> nil then
  begin
    code := ANode.Texts[cIdxCodigo];
    if code <> '' then
    begin
      FijarPermiso(code, not ResolverEfectivo(code, o),
                   ANode.Texts[cIdxNombre]);
      RefrescarValores;
    end;
  end;
end;

procedure TfrmMtoPermisosArbol.AplicarRama(ANode: TcxTreeListNode;
  AValor: Boolean);
  procedure Rec(N: TcxTreeListNode);
  var
    i: Integer;
    code: string;
  begin
    code := N.Texts[cIdxCodigo];
    if code <> '' then
      FijarPermiso(code, AValor, N.Texts[cIdxNombre]);
    for i := 0 to N.Count - 1 do
      Rec(N.Items[i]);
  end;
begin
  if ANode = nil then
    ShowMessage(SErrorNodoPermisosNoSeleccionado)
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      Rec(ANode);
    finally
      Screen.Cursor := crDefault;
    end;
    RefrescarValores;
  end;
end;

procedure TfrmMtoPermisosArbol.HeredarRama(ANode: TcxTreeListNode);
  procedure Rec(N: TcxTreeListNode);
  var
    i: Integer;
    code: string;
  begin
    code := N.Texts[cIdxCodigo];
    if code <> '' then
    begin
      TPermisosAdmin.Heredar(ConexionPrincipal, FSujetoActual.Nombre, code);
      if FExpSujeto <> nil then
        FExpSujeto.Remove(code);
    end;
    for i := 0 to N.Count - 1 do
      Rec(N.Items[i]);
  end;
begin
  if ANode = nil then
    ShowMessage(SErrorNodoPermisosNoSeleccionado)
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      Rec(ANode);
    finally
      Screen.Cursor := crDefault;
    end;
    RefrescarValores;
  end;
end;

procedure TfrmMtoPermisosArbol.AplicarFiltro(const ATexto: string);
var
  lt: string;
  i: Integer;
  function Match(N: TcxTreeListNode): Boolean;
  var
    j: Integer;
    hijo, vis: Boolean;
    nom, code: string;
  begin
    hijo := False;
    for j := 0 to N.Count - 1 do
      if Match(N.Items[j]) then
        hijo := True;
    nom  := LowerCase(N.Texts[cIdxNombre]);
    code := LowerCase(N.Texts[cIdxCodigo]);
    vis := hijo or (lt = '') or (Pos(lt, nom) > 0) or (Pos(lt, code) > 0);
    N.Visible := vis;
    Result := vis;
  end;
begin
  lt := LowerCase(Trim(ATexto));
  FtlPermisos.BeginUpdate;
  try
    for i := 0 to FtlPermisos.Root.Count - 1 do
      Match(FtlPermisos.Root.Items[i]);
  finally
    FtlPermisos.EndUpdate;
  end;
  if lt <> '' then
    FtlPermisos.FullExpand;
end;

// ===========================================================================
//   Manejadores de eventos
// ===========================================================================

procedure TfrmMtoPermisosArbol.cbbSujetoChange(Sender: TObject);
var
  i: Integer;
begin
  if not FInicializando then
  begin
    i := cbbSujeto.ItemIndex;
    if (i >= 0) and (i < Length(FSujetos)) then
    begin
      FSujetoActual := FSujetos[i];
      CargarValoresSujeto;
    end;
  end;
end;

procedure TfrmMtoPermisosArbol.edtFiltroChange(Sender: TObject);
begin
  AplicarFiltro(edtFiltro.Text);
end;

procedure TfrmMtoPermisosArbol.btnRecargarClick(Sender: TObject);
var
  sNombre: string;
  idx: Integer;
begin
  FInicializando := True;
  try
    sNombre := FSujetoActual.Nombre;
    FSujetos := TPermisosAdmin.ListarSujetos(ConexionPrincipal);
    FCatalogo := TPermisosAdmin.CatalogoCodigos(ConexionPrincipal);
    PoblarCombos;
    ConstruirArbol;
    idx := IndiceSujeto(sNombre);
    if idx < 0 then
      idx := 0;
    cbbSujeto.ItemIndex := idx;
    if (idx >= 0) and (idx < Length(FSujetos)) then
      FSujetoActual := FSujetos[idx];
  finally
    FInicializando := False;
  end;
  CargarValoresSujeto;
end;

procedure TfrmMtoPermisosArbol.btnExpandirClick(Sender: TObject);
begin
  FtlPermisos.FullExpand;
end;

procedure TfrmMtoPermisosArbol.btnContraerClick(Sender: TObject);
begin
  FtlPermisos.FullCollapse;
end;

procedure TfrmMtoPermisosArbol.btnPermitirRamaClick(Sender: TObject);
begin
  AplicarRama(FtlPermisos.FocusedNode, True);
end;

procedure TfrmMtoPermisosArbol.btnDenegarRamaClick(Sender: TObject);
begin
  AplicarRama(FtlPermisos.FocusedNode, False);
end;

procedure TfrmMtoPermisosArbol.btnHeredarRamaClick(Sender: TObject);
begin
  HeredarRama(FtlPermisos.FocusedNode);
end;

procedure TfrmMtoPermisosArbol.btnCopiarClick(Sender: TObject);
var
  io, idx, n: Integer;
  org, dst: TPermisoSujeto;
  reempl: Boolean;
  msg, sModo, sFiltro: string;
begin
  io  := cbbOrigen.ItemIndex;
  idx := cbbDestino.ItemIndex;
  if (io < 0) or (idx < 0) or (io > High(FSujetos)) or
     (idx > High(FSujetos)) then
    ShowMessage(SErrorOrigenDestinoPermisosNoSeleccionados)
  else
  begin
    org := FSujetos[io];
    dst := FSujetos[idx];
    if SameText(org.Nombre, dst.Nombre) then
      ShowMessage(SErrorOrigenDestinoPermisosIguales)
    else
    begin
      reempl := (rgModo.ItemIndex = 1);
      if reempl then
        sModo := SInfoModoReemplazarPermisos
      else
        sModo := SInfoModoCombinarPermisos;
      if chkSoloMenu.Checked then
        sFiltro := SInfoAlcancePermisosMenu
      else
        sFiltro := SInfoAlcanceTodosPermisos;
      msg := Format(SPreguntaCopiarPermisos,
                    [org.Nombre, dst.Nombre, sModo, sFiltro]);
      if MessageDlg(msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        Screen.Cursor := crHourGlass;
        try
          n := TPermisosAdmin.Copiar(
            ConexionPrincipal,
            ContextoSesion,
            org.Nombre,
            dst.Nombre, reempl, chkSoloMenu.Checked);
        finally
          Screen.Cursor := crDefault;
        end;
        ShowMessage(Format(SInfoPermisosCopiados,
                           [n, org.Nombre, dst.Nombre]));
        if SameText(dst.Nombre, FSujetoActual.Nombre) then
          CargarValoresSujeto;
      end;
    end;
  end;
end;

procedure TfrmMtoPermisosArbol.tlPermisosDblClick(Sender: TObject);
begin
  AlternarHoja(FtlPermisos.FocusedNode);
end;

procedure TfrmMtoPermisosArbol.tlPermisosKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
  begin
    AlternarHoja(FtlPermisos.FocusedNode);
    Key := 0;
  end;
end;

// ===========================================================================
//   Ciclo de vida
// ===========================================================================

procedure TfrmMtoPermisosArbol.CrearTablaPrincipal;
begin
  inherited;
  FInicializando := True;
  try
    ConstruirInterfaz;
    FSujetos  := TPermisosAdmin.ListarSujetos(ConexionPrincipal);
    FCatalogo := TPermisosAdmin.CatalogoCodigos(ConexionPrincipal);
    PoblarCombos;
    ConstruirArbol;
    if Length(FSujetos) > 0 then
      FSujetoActual := FSujetos[0];
  finally
    FInicializando := False;
  end;
  CargarValoresSujeto;
  if (pcPantalla <> nil) and (tsGestion <> nil) then
    pcPantalla.ActivePage := tsGestion;
end;

procedure TfrmMtoPermisosArbol.ResetForm;
begin
  inherited;
  if (pcPantalla <> nil) and (tsGestion <> nil) then
    pcPantalla.ActivePage := tsGestion;
end;

destructor TfrmMtoPermisosArbol.Destroy;
begin
  FreeAndNil(FExpSujeto);
  FreeAndNil(FExpGrupo);
  FreeAndNil(FExpTodos);
  FreeAndNil(FColocados);
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoPermisosArbol);

end.
