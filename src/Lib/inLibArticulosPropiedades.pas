unit inLibArticulosPropiedades;

{
  Unidad: inLibArticuloPropiedades
  Descripción: Gestión dinámica de propiedades en la pestaña tsPropiedades
               del formulario TfrmMtoArticulos de Factuzam.

  Flujo de uso:
    1. Crear TGestorPropiedades en FormShow / CrearTablaPrincipal
    2. Llamar a CargarPropiedades cuando cambia el artículo activo
       (AfterScroll del dataset principal)
    3. Llamar a GuardarPropiedades dentro de btnGrabarClick
    4. Llamar a AbrirSelectorPropiedades desde el botón "+ Añadir propiedad"

  El gestor inyecta controles en un TScrollBox que debe existir en tsPropiedades.
  El botón de añadir y el scroll se crean dinámicamente si no existen.
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxSpinEdit,
  cxCheckBox, cxLabel, cxDropDownEdit, cxButtons,
  cxPC, cxLookAndFeels, cxLookAndFeelPainters,
  DBAccess, Uni;

type
  TTipoValorProp = (tvpLista, tvpTextoLibre, tvpNumero, tvpBooleano);

  TSlotProp = record
    CodigoPropiedad : string;
    NombrePropiedad : string;
    TipoValor       : TTipoValorProp;
    EsRequerido     : Boolean;
    // Valor actual
    IdValorPV       : Integer;    // tipo LISTA
    ValorLibre      : string;     // tipos TEXTO, NUMERO, BOOLEANO
    // Control visual
    Ctrl            : TControl;
    // Solo para LISTA: ID → Texto
    Opciones        : TDictionary<Integer, string>;
    // Marcado para eliminar
    Eliminar        : Boolean;
  end;

  { Diálogo selector de propiedades disponibles }
  TfrmSelPropiedades = class(TForm)
  private
    FConexion       : TUniConnection;
    FExcluirCodigos : TStringList;
    FListBox        : TListBox;
    FBtnAceptar     : TcxButton;
    FBtnCancelar    : TcxButton;
    procedure BtnAceptarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  public
    CodigosSeleccionados : TStringList;
    constructor Create(AOwner: TComponent; AConexion: TUniConnection;
                       AExcluir: TStringList); reintroduce;
    destructor Destroy; override;
    procedure CargarLista;
  end;

  { Gestor principal — instanciar uno por formulario de artículo }
  TGestorPropiedades = class
  private
    FConexion       : TUniConnection;
    FScrollBox      : TScrollBox;     // panel contenedor en tsPropiedades
    FCodigoArticulo : string;
    FUsuario        : string;
    FSlots          : TList<TSlotProp>;
    FModificado     : Boolean;

    function  TipoDesdeCadena(const s: string): TTipoValorProp;
    procedure LimpiarControles;
    procedure ReconstruirVista;

    // Creación de controles por tipo
    procedure CrearFilaLista      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaTexto      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaNumero     (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaBooleano   (var S: TSlotProp; ATop: Integer);
    procedure CrearBtnEliminar    (SlotIdx: Integer; ATop: Integer);

    procedure BtnEliminarClick(Sender: TObject);

    procedure UpsertSlot(const S: TSlotProp);
    procedure DeleteSlot(const CodigoPropiedad: string);

    function IndexOfCodigo(const Cod: string): Integer;
  public
    constructor Create(AScrollBox: TScrollBox;
                       AConexion: TUniConnection;
                       const AUsuario: string);
    destructor Destroy; override;

    { Carga las propiedades ya asignadas al artículo }
    procedure CargarPropiedades(const CodigoArticulo: string);
    procedure CargarPropiedadesPorFamilia(const CodigoFamilia: string);
    { Añade propiedades seleccionadas por el usuario desde el diálogo }
    procedure AbrirSelectorPropiedades;

    { Persiste todos los cambios pendientes; llamar desde btnGrabarClick }
    function GuardarPropiedades: Boolean;

    { Validación: devuelve '' si OK, mensaje de error si hay requeridos vacíos }
    function Validar: string;

    property Modificado: Boolean read FModificado;
  end;

implementation

{ ═══════════════════════════════════════════════════════════════════════════ }

uses uGenericIfThen;
{ Constantes de layout                                                        }
{ ═══════════════════════════════════════════════════════════════════════════ }

const
  ALTO_FILA      = 26;
  MARGEN_V       = 6;
  MARGEN_H       = 8;
  ANCHO_LABEL    = 160;
  ANCHO_CTRL     = 260;
  ANCHO_BTN_DEL  = 24;
  COLOR_REQUERIDO = clMaroon;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ TfrmSelPropiedades                                                          }
{ ═══════════════════════════════════════════════════════════════════════════ }

constructor TfrmSelPropiedades.Create(AOwner: TComponent;
  AConexion: TUniConnection; AExcluir: TStringList);
var
  pnlBtn: TPanel;
begin
  inherited CreateNew(AOwner);
  FConexion       := AConexion;
  FExcluirCodigos := AExcluir;
  CodigosSeleccionados := TStringList.Create;

  Caption    := 'Añadir propiedades al artículo';
  Width      := 380;
  Height     := 440;
  Position   := poOwnerFormCenter;
  BorderStyle:= bsDialog;
  Font.name := 'Lucida Sans';

  FListBox := TListBox.Create(Self);
  FListBox.Parent      := Self;
  FListBox.Align       := alClient;
  FListBox.MultiSelect := True;
  FListBox.Style       := lbOwnerDrawFixed;
  FListBox.ItemHeight  := 22;
  FListBox.BorderStyle := bsNone;
  FListBox.ParentFont := True;

  pnlBtn := TPanel.Create(Self);
  pnlBtn.Parent := Self;
  pnlBtn.Align  := alBottom;
  pnlBtn.Height := 40;
  pnlBtn.BevelOuter := bvNone;
  pnlBtn.Font.name := 'Lucida Sans';
  pnlBtn.Font.Height := -13;

  FBtnAceptar := TcxButton.Create(Self);
  FBtnAceptar.Parent  := pnlBtn;
  FBtnAceptar.Caption := '&Aceptar';
  FBtnAceptar.Width   := 90;
  FBtnAceptar.Height  := 28;
  FBtnAceptar.Left    := pnlBtn.Width - 200;
  FBtnAceptar.Top     := 6;
  FBtnAceptar.Anchors := [akRight, akTop];
  FBtnAceptar.ModalResult := mrNone;
  FbtnAceptar.ParentFont := True;
  FBtnAceptar.OnClick := BtnAceptarClick;

  FBtnCancelar := TcxButton.Create(Self);
  FBtnCancelar.Parent  := pnlBtn;
  FBtnCancelar.Caption := '&Cancelar';
  FBtnCancelar.Width   := 90;
  FBtnCancelar.Height  := 28;
  FBtnCancelar.Left    := pnlBtn.Width - 100;
  FBtnCancelar.Top     := 6;
  FBtnCancelar.ParentFont := True;
  FBtnCancelar.Anchors := [akRight, akTop];
  FBtnCancelar.ModalResult := mrNone;
  FBtnCancelar.OnClick := BtnCancelarClick;

  CargarLista;
end;

destructor TfrmSelPropiedades.Destroy;
begin
  CodigosSeleccionados.Free;
  inherited;
end;

procedure TfrmSelPropiedades.CargarLista;
var
  q: TUniQuery;
begin
  FListBox.Clear;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT CODIGO_PROPIEDAD, NOMBRE_PROPIEDAD, TIPO_VALOR ' +
      'FROM   fza_propiedades ' +
      'WHERE  ACTIVO_PROPIEDAD = ''S'' ' +
      'ORDER  BY NOMBRE_PROPIEDAD';
    q.Open;
    while not q.Eof do
    begin
      // Excluir las ya asignadas
      if FExcluirCodigos.IndexOf(q.FieldByName('CODIGO_PROPIEDAD').AsString) < 0 then
      begin
        FListBox.Items.AddObject(
          q.FieldByName('NOMBRE_PROPIEDAD').AsString + '  [' +
          q.FieldByName('TIPO_VALOR').AsString + ']',
          TObject(FListBox.Items.Count));
        // Guardar el código en un objeto paralelo usando tag del form
        // Usamos Items.Objects con índice entero como referencia, almacenamos
        // código en Tag via SubItems trick → usamos un StringList auxiliar
        CodigosSeleccionados.Add(q.FieldByName('CODIGO_PROPIEDAD').AsString);
      end;
      q.Next;
    end;
  finally
    q.Free;
  end;
  // CodigosSeleccionados servirá como mapa índice→código
  // lo reutilizamos; los seleccionados reales se calculan en BtnAceptarClick
end;

procedure TfrmSelPropiedades.BtnAceptarClick(Sender: TObject);
var
  i: Integer;
  seleccionados: TStringList;
begin
  seleccionados := TStringList.Create;
  try
    for i := 0 to FListBox.Items.Count - 1 do
      if FListBox.Selected[i] then
        seleccionados.Add(CodigosSeleccionados[i]);
    CodigosSeleccionados.Clear;
    CodigosSeleccionados.AddStrings(seleccionados);
  finally
    seleccionados.Free;
  end;
  ModalResult := mrOk;
end;

procedure TfrmSelPropiedades.BtnCancelarClick(Sender: TObject);
begin
  CodigosSeleccionados.Clear;
  ModalResult := mrCancel;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ TGestorPropiedades — constructor / destructor                               }
{ ═══════════════════════════════════════════════════════════════════════════ }

constructor TGestorPropiedades.Create(AScrollBox: TScrollBox;
  AConexion: TUniConnection; const AUsuario: string);
begin
  inherited Create;
  FScrollBox  := AScrollBox;
  FConexion   := AConexion;
  FUsuario    := AUsuario;
  FSlots      := TList<TSlotProp>.Create;
  FModificado := False;

  FScrollBox.AutoScroll := True;
  FScrollBox.Color      := clWindow;
end;

destructor TGestorPropiedades.Destroy;
begin
  LimpiarControles;
  FSlots.Free;
  inherited;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Helpers internos                                                            }
{ ═══════════════════════════════════════════════════════════════════════════ }

function TGestorPropiedades.TipoDesdeCadena(const s: string): TTipoValorProp;
begin
  if      s = 'LISTA'    then Result := tvpLista
  else if s = 'NUMERO'   then Result := tvpNumero
  else if s = 'BOOLEANO' then Result := tvpBooleano
  else                        Result := tvpTextoLibre;
end;

function TGestorPropiedades.IndexOfCodigo(const Cod: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FSlots.Count - 1 do
    if FSlots[i].CodigoPropiedad = Cod then
    begin
      Result := i;
      Break;
    end;
end;

procedure TGestorPropiedades.LimpiarControles;
var
  i: Integer;
begin
  // Liberar diccionarios de opciones
  for i := 0 to FSlots.Count - 1 do
    if Assigned(FSlots[i].Opciones) then
      FSlots[i].Opciones.Free;
  FSlots.Clear;

  // Destruir controles del scroll
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FScrollBox.Controls[0].Free;
  finally
    FScrollBox.EnableAlign;
  end;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Carga desde BD                                                              }
{ ═══════════════════════════════════════════════════════════════════════════ }

procedure TGestorPropiedades.CargarPropiedades(const CodigoArticulo: string);
var
  q    : TUniQuery;
  qOpc : TUniQuery;
  S    : TSlotProp;
  i    : Integer;
begin
  FCodigoArticulo := CodigoArticulo;
  LimpiarControles;
  FModificado := False;

  if CodigoArticulo = '' then Exit;

  // ── 1. Propiedades ya asignadas a este artículo ────────────────────────
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT p.CODIGO_PROPIEDAD, p.NOMBRE_PROPIEDAD, p.TIPO_VALOR, ' +
      '       ap.ID_VALOR_PV, ap.VALOR_LIBRE, ' +
      '       COALESCE(fa.ES_REQUERIDO, ''N'') AS ES_REQUERIDO, ' +
      '       COALESCE(fa.ORDEN_MOSTRAR, 999) AS ORDEN_MOSTRAR ' +
      'FROM   fza_articulos_propiedades ap ' +
      'JOIN   fza_propiedades p ON p.CODIGO_PROPIEDAD = ap.CODIGO_PROPIEDAD ' +
      'LEFT JOIN fza_articulos art ON art.CODIGO_ARTICULO = ap.CODIGO_ARTICULO ' +
      'LEFT JOIN fza_familias_atributos fa ' +
      '       ON fa.CODIGO_PROPIEDAD = ap.CODIGO_PROPIEDAD ' +
      '      AND fa.CODIGO_FAMILIA   = art.CODIGO_FAMILIA_ARTICULO ' +
      'WHERE  ap.CODIGO_ARTICULO = :art ' +
      '  AND  p.ACTIVO_PROPIEDAD = ''S'' ' +
      'ORDER  BY COALESCE(fa.ORDEN_MOSTRAR, 999), p.NOMBRE_PROPIEDAD';
    q.ParamByName('art').AsString := CodigoArticulo;
    q.Open;
    while not q.Eof do
    begin
      FillChar(S, SizeOf(S), 0);
      S.CodigoPropiedad := q.FieldByName('CODIGO_PROPIEDAD').AsString;
      S.NombrePropiedad := q.FieldByName('NOMBRE_PROPIEDAD').AsString;
      S.TipoValor       := TipoDesdeCadena(q.FieldByName('TIPO_VALOR').AsString);
      S.EsRequerido     := q.FieldByName('ES_REQUERIDO').AsString = 'S';
      S.IdValorPV       := q.FieldByName('ID_VALOR_PV').AsInteger;
      S.ValorLibre      := q.FieldByName('VALOR_LIBRE').AsString;
      S.Ctrl            := nil;
      S.Opciones        := nil;
      S.Eliminar        := False;
      FSlots.Add(S);
      q.Next;
    end;
  finally
    q.Free;
  end;
  // ── 2. Opciones para slots tipo LISTA ─────────────────────────────────
  qOpc := TUniQuery.Create(nil);
  try
    qOpc.Connection := FConexion;
    qOpc.SQL.Text   :=
      'SELECT ID_VALOR_PV, VALOR_PV ' +
      'FROM   fza_propiedades_valores ' +
      'WHERE  ID_PROPIEDAD_PV = :cod ' +
      '  AND  ESACTIVO_PV = ''S'' ' +
      'ORDER  BY VALOR_PV';
    for i := 0 to FSlots.Count - 1 do
    begin
      if FSlots[i].TipoValor = tvpLista then
      begin
        S := FSlots[i];
        S.Opciones := TDictionary<Integer, string>.Create;
        qOpc.Close;
        qOpc.ParamByName('cod').AsString := S.CodigoPropiedad;
        qOpc.Open;
        while not qOpc.Eof do
        begin
          S.Opciones.Add(
            qOpc.FieldByName('ID_VALOR_PV').AsInteger,
            qOpc.FieldByName('VALOR_PV').AsString);
          qOpc.Next;
        end;
        FSlots[i] := S;
      end;
    end;
  finally
    qOpc.Free;
  end;
  ReconstruirVista;
end;

procedure TGestorPropiedades.CargarPropiedadesPorFamilia(const CodigoFamilia: string);
var
  qProp     : TUniQuery;
  qOpc      : TUniQuery;
  S         : TSlotProp;
  cod       : string;
  idx, i    : Integer;
  EstaVacia : Boolean;
begin
  if CodigoFamilia = '' then Exit;

  // 1. SINCRONIZAR PANTALLA -> MEMORIA
  // Guardamos lo que el usuario haya escrito en los controles visuales
  // para no perderlo ni evaluarlo mal.
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if (not S.Eliminar) and Assigned(S.Ctrl) then
    begin
      case S.TipoValor of
        tvpLista:
          if (S.Ctrl as TcxComboBox).ItemIndex > 0 then
            S.IdValorPV := Integer((S.Ctrl as TcxComboBox).Properties.Items.Objects[(S.Ctrl as TcxComboBox).ItemIndex])
          else
            S.IdValorPV := 0;
        tvpTextoLibre:
          S.ValorLibre := Trim((S.Ctrl as TcxTextEdit).Text);
        tvpNumero:
          if Trim((S.Ctrl as TcxSpinEdit).Text) = '' then
            S.ValorLibre := ''
          else
            S.ValorLibre := FloatToStr((S.Ctrl as TcxSpinEdit).Value);
        tvpBooleano:
          if (S.Ctrl as TcxCheckBox).Checked then
            S.ValorLibre := 'S'
          else
            S.ValorLibre := 'N';
      end;
    end;
    FSlots[i] := S;
  end;

  // 2. MARCAR PARA ELIMINAR SOLO LAS QUE ESTÉN VACÍAS
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];

    EstaVacia := False;
    case S.TipoValor of
      tvpLista:      EstaVacia := (S.IdValorPV <= 0);
      tvpTextoLibre: EstaVacia := (S.ValorLibre = '');
      tvpNumero:     EstaVacia := (S.ValorLibre = '') or (S.ValorLibre = '0');
      tvpBooleano:   EstaVacia := (S.ValorLibre <> 'S') and (S.ValorLibre <> '1');
    end;

    if EstaVacia then
      S.Eliminar := True;
      // Si tiene datos (EstaVacia = False), NO tocamos S.Eliminar,
      // por lo que sobrevive al cambio de familia.

    FSlots[i] := S;
  end;
  FModificado := True;

  // 3. CARGAR LAS PROPIEDADES DE LA NUEVA FAMILIA
  qProp := TUniQuery.Create(nil);
  qOpc  := TUniQuery.Create(nil);
  try
    qProp.Connection := FConexion;
    qProp.SQL.Text   :=
      'SELECT p.CODIGO_PROPIEDAD, p.NOMBRE_PROPIEDAD, p.TIPO_VALOR, fa.ES_REQUERIDO ' +
      'FROM fza_familias_atributos fa ' +
      'JOIN fza_propiedades p ON p.CODIGO_PROPIEDAD = fa.CODIGO_PROPIEDAD ' +
      'WHERE fa.CODIGO_FAMILIA = :fam ' +
      '  AND p.ACTIVO_PROPIEDAD = ''S'' ' +
      'ORDER BY fa.ORDEN_MOSTRAR, p.NOMBRE_PROPIEDAD';
    qProp.ParamByName('fam').AsString := CodigoFamilia;
    qProp.Open;

    qOpc.Connection := FConexion;
    qOpc.SQL.Text   :=
      'SELECT ID_VALOR_PV, VALOR_PV ' +
      'FROM fza_propiedades_valores ' +
      'WHERE ID_PROPIEDAD_PV = :cod AND ESACTIVO_PV = ''S'' ' +
      'ORDER BY VALOR_PV';

    while not qProp.Eof do
    begin
      cod := qProp.FieldByName('CODIGO_PROPIEDAD').AsString;
      idx := IndexOfCodigo(cod);

      if idx < 0 then
      begin
        // AÑADIR NUEVA PROPIEDAD
        FillChar(S, SizeOf(S), 0);
        S.CodigoPropiedad := cod;
        S.NombrePropiedad := qProp.FieldByName('NOMBRE_PROPIEDAD').AsString;
        S.TipoValor       := TipoDesdeCadena(qProp.FieldByName('TIPO_VALOR').AsString);
        S.EsRequerido     := qProp.FieldByName('ES_REQUERIDO').AsString = 'S';
        S.IdValorPV       := 0;
        S.ValorLibre      := '';
        S.Ctrl            := nil;
        S.Opciones        := nil;
        S.Eliminar        := False;

        if S.TipoValor = tvpLista then
        begin
          S.Opciones := TDictionary<Integer, string>.Create;
          qOpc.Close;
          qOpc.ParamByName('cod').AsString := S.CodigoPropiedad;
          qOpc.Open;
          while not qOpc.Eof do
          begin
            S.Opciones.Add(qOpc.FieldByName('ID_VALOR_PV').AsInteger,
                           qOpc.FieldByName('VALOR_PV').AsString);
            qOpc.Next;
          end;
        end;
        FSlots.Add(S);
      end
      else
      begin
        // RESCATAR EXISTENTE (Pertenece a la nueva familia)
        S := FSlots[idx];
        S.EsRequerido := qProp.FieldByName('ES_REQUERIDO').AsString = 'S';
        S.Eliminar := False; // La salvamos, esté vacía o llena
        FSlots[idx] := S;
      end;
      qProp.Next;
    end;

    // Redibujamos la vista con las supervivientes y las nuevas
    ReconstruirVista;
  finally
    qProp.Free;
    qOpc.Free;
  end;
end;

procedure TGestorPropiedades.ReconstruirVista;
var
  i   : Integer;
  Top : Integer;
  S   : TSlotProp;
begin
  // Destruir controles viejos SIN borrar los slots
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FScrollBox.Controls[0].Free;
    // Limpiar referencias a controles en los slots
    for i := 0 to FSlots.Count - 1 do
    begin
      S := FSlots[i];
      S.Ctrl := nil;
      FSlots[i] := S;
    end;
  finally
    FScrollBox.EnableAlign;
  end;

  Top := MARGEN_V;
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if S.Eliminar then Continue;

    case S.TipoValor of
      tvpLista      : CrearFilaLista   (S, Top);
      tvpTextoLibre : CrearFilaTexto   (S, Top);
      tvpNumero     : CrearFilaNumero  (S, Top);
      tvpBooleano   : CrearFilaBooleano(S, Top);
    end;
    CrearBtnEliminar(i, Top);
    FSlots[i] := S;
    Inc(Top, ALTO_FILA + MARGEN_V);
  end;
end;

{ ── Fila LISTA ──────────────────────────────────────────────────────────── }
procedure TGestorPropiedades.CrearFilaLista(var S: TSlotProp; ATop: Integer);
var
  lbl : TcxLabel;
  cb  : TcxComboBox;
  IdV : Integer;
  Txt : string;
  Idx : Integer;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent  := FScrollBox;
  lbl.Left    := MARGEN_H;
  lbl.Top     := ATop + 4;
  lbl.Width   := ANCHO_LABEL;
  lbl.AutoSize:= True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption := S.NombrePropiedad;

  cb := TcxComboBox.Create(FScrollBox);
  cb.Parent  := FScrollBox;
  cb.Left    := MARGEN_H + ANCHO_LABEL + 6;
  cb.Top     := ATop;
  cb.Width   := ANCHO_CTRL;
  cb.Height  := ALTO_FILA;
  cb.Properties.DropDownListStyle := lsFixedList;
  cb.Properties.Items.Add('');   // opción vacía

  if Assigned(S.Opciones) then
    for IdV in S.Opciones.Keys do
    begin
      Txt := S.Opciones[IdV];
      cb.Properties.Items.AddObject(Txt, TObject(IdV));
    end;

  // Seleccionar valor actual
  if S.IdValorPV > 0 then
    for Idx := 1 to cb.Properties.Items.Count - 1 do
      if Integer(cb.Properties.Items.Objects[Idx]) = S.IdValorPV then
      begin
        cb.ItemIndex := Idx;
        Break;
      end;

  S.Ctrl := cb;
end;

{ ── Fila TEXTO LIBRE ────────────────────────────────────────────────────── }
procedure TGestorPropiedades.CrearFilaTexto(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  ed : TcxTextEdit;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := ANCHO_LABEL;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;

  ed := TcxTextEdit.Create(FScrollBox);
  ed.Parent := FScrollBox;
  ed.Left   := MARGEN_H + ANCHO_LABEL + 6;
  ed.Top    := ATop;
  ed.Width  := ANCHO_CTRL;
  ed.Height := ALTO_FILA;
  ed.Text   := S.ValorLibre;

  S.Ctrl := ed;
end;

{ ── Fila NUMERO ─────────────────────────────────────────────────────────── }
procedure TGestorPropiedades.CrearFilaNumero(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  sp : TcxSpinEdit;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := ANCHO_LABEL;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;

  sp := TcxSpinEdit.Create(FScrollBox);
  sp.Parent  := FScrollBox;
  sp.Left    := MARGEN_H + ANCHO_LABEL + 6;
  sp.Top     := ATop;
  sp.Width   := 120;
  sp.Height  := ALTO_FILA;
  sp.Properties.EditFormat := '0.00';
  if S.ValorLibre <> '' then
    sp.Value := StrToFloatDef(StringReplace(S.ValorLibre, ',', '.', []), 0);

  S.Ctrl := sp;
end;

{ ── Fila BOOLEANO ───────────────────────────────────────────────────────── }
procedure TGestorPropiedades.CrearFilaBooleano(var S: TSlotProp; ATop: Integer);
var
  lbl: TcxLabel;
  chk: TcxCheckBox;
begin
  lbl := TcxLabel.Create(FScrollBox);
  lbl.Parent   := FScrollBox;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := ANCHO_LABEL;
  lbl.AutoSize := True;
  if S.EsRequerido then
    lbl.Style.Font.Style := [fsBold];
  lbl.Caption  := S.NombrePropiedad;

  chk := TcxCheckBox.Create(FScrollBox);
  chk.Parent   := FScrollBox;
  chk.Left     := MARGEN_H + ANCHO_LABEL + 6;
  chk.Top      := ATop;
  chk.Width    := ALTO_FILA;
  chk.Height   := ALTO_FILA;
  chk.Caption  := '';
  // Eliminar cualquier texto que DevExpress muestre dentro del control
  chk.Properties.DisplayChecked   := '';
  chk.Properties.DisplayUnchecked := '';
  chk.Properties.DisplayGrayed    := '';
  chk.Checked  := (S.ValorLibre = 'S') or (S.ValorLibre = '1');

  S.Ctrl := chk;
end;

{ ── Botón eliminar (×) a la derecha de cada fila ───────────────────────── }
procedure TGestorPropiedades.CrearBtnEliminar(SlotIdx: Integer; ATop: Integer);
var
  btn: TcxButton;
begin
  btn := TcxButton.Create(FScrollBox);
  btn.Parent  := FScrollBox;
  btn.Left    := MARGEN_H + ANCHO_LABEL + 6 + ANCHO_CTRL + 6;
  btn.Top     := ATop;
  btn.Width   := ANCHO_BTN_DEL;
  btn.Height  := ALTO_FILA;
  btn.Caption := '×';
  btn.Tag     := SlotIdx;
  btn.Hint    := 'Quitar propiedad ' + FSlots[SlotIdx].NombrePropiedad;
  btn.ShowHint:= True;
  btn.OnClick := BtnEliminarClick;
end;

procedure TGestorPropiedades.BtnEliminarClick(Sender: TObject);
var
  idx: Integer;
  S  : TSlotProp;
begin
  idx := (Sender as TcxButton).Tag;
  if (idx < 0) or (idx >= FSlots.Count) then Exit;

  if MessageDlg('¿Quitar la propiedad "' + FSlots[idx].NombrePropiedad +
                '" de este artículo?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  S := FSlots[idx];
  S.Eliminar := True;
  FSlots[idx] := S;
  FModificado := True;
  TThread.ForceQueue(nil,
    procedure
    begin
      ReconstruirVista;
    end
  );
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Selector de nuevas propiedades                                              }
{ ═══════════════════════════════════════════════════════════════════════════ }

procedure TGestorPropiedades.AbrirSelectorPropiedades;
var
  dlg          : TfrmSelPropiedades;
  Excluidos    : TStringList;
  i            : Integer;
  cod          : string;
  qProp        : TUniQuery;
  qOpc         : TUniQuery;
  S            : TSlotProp;
begin
  if FCodigoArticulo = '' then
  begin
    ShowMessage('Primero guarde el artículo antes de añadir propiedades.');
    Exit;
  end;

  // Construir lista de propiedades ya presentes (no eliminadas)
  Excluidos := TStringList.Create;
  try
    for i := 0 to FSlots.Count - 1 do
      if not FSlots[i].Eliminar then
        Excluidos.Add(FSlots[i].CodigoPropiedad);

    dlg := TfrmSelPropiedades.Create(nil, FConexion, Excluidos);
    try
      if dlg.ShowModal <> mrOk then Exit;
      if dlg.CodigosSeleccionados.Count = 0 then Exit;

      // Cargar datos de cada propiedad seleccionada y añadir slot
      qProp := TUniQuery.Create(nil);
      qOpc  := TUniQuery.Create(nil);
      try
        qProp.Connection := FConexion;
        qProp.SQL.Text   :=
          'SELECT CODIGO_PROPIEDAD, NOMBRE_PROPIEDAD, TIPO_VALOR ' +
          'FROM   fza_propiedades ' +
          'WHERE  CODIGO_PROPIEDAD = :cod';
        qOpc.Connection := FConexion;
        qOpc.SQL.Text   :=
          'SELECT ID_VALOR_PV, VALOR_PV ' +
          'FROM   fza_propiedades_valores ' +
          'WHERE  ID_PROPIEDAD_PV = :cod ' +
          '  AND  ESACTIVO_PV = ''S'' ' +
          'ORDER  BY VALOR_PV';
        for cod in dlg.CodigosSeleccionados do
        begin
          qProp.Close;
          qProp.ParamByName('cod').AsString := cod;
          qProp.Open;
          if qProp.Eof then Continue;
          FillChar(S, SizeOf(S), 0);
          S.CodigoPropiedad := qProp.FieldByName('CODIGO_PROPIEDAD').AsString;
          S.NombrePropiedad := qProp.FieldByName('NOMBRE_PROPIEDAD').AsString;
          S.TipoValor       :=
                      TipoDesdeCadena(qProp.FieldByName('TIPO_VALOR').AsString);
          S.EsRequerido     := False;
          S.IdValorPV       := 0;
          S.ValorLibre      := '';
          S.Ctrl            := nil;
          S.Opciones        := nil;
          S.Eliminar        := False;
          if S.TipoValor = tvpLista then
          begin
            S.Opciones := TDictionary<Integer, string>.Create;
            qOpc.Close;
            qOpc.ParamByName('cod').AsString := S.CodigoPropiedad;
            qOpc.Open;
            while not qOpc.Eof do
            begin
              S.Opciones.Add(
                qOpc.FieldByName('ID_VALOR_PV').AsInteger,
                qOpc.FieldByName('VALOR_PV').AsString);
              qOpc.Next;
            end;
          end;
          FSlots.Add(S);
          FModificado := True;
        end;
      finally
        qProp.Free;
        qOpc.Free;
      end;
      ReconstruirVista;
    finally
      dlg.Free;
    end;
  finally
    Excluidos.Free;
  end;
end;

function TGestorPropiedades.Validar: string;
var
  i: Integer;
  S: TSlotProp;
  TieneValor: Boolean;
begin
  Result := '';
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if S.Eliminar then Continue;
    if S.EsRequerido and Assigned(S.Ctrl) then
    begin
      TieneValor := False;
      case S.TipoValor of
        tvpLista:
          TieneValor := (S.Ctrl as TcxComboBox).ItemIndex >= 0;
        tvpTextoLibre:
          TieneValor := Trim((S.Ctrl as TcxTextEdit).Text) <> '';
        tvpNumero, tvpBooleano:
          TieneValor := True;
      end;
      if not TieneValor then
      begin
        Result := 'La propiedad "' + S.NombrePropiedad +
                                       '" es obligatoria para esta familia.';
        Exit;
      end;
    end;
  end;
end;

function TGestorPropiedades.GuardarPropiedades: Boolean;
var
  i  : Integer;
  S  : TSlotProp;
  sE : string;
begin
  Result := False;
  sE := Validar;
  if sE <> '' then
    raise Exception.Create(sE);

  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];

    if S.Eliminar then
    begin
      DeleteSlot(S.CodigoPropiedad);
      Continue;
    end;

    if not Assigned(S.Ctrl) then Continue;

    // Leer valor del control
    case S.TipoValor of
      tvpLista:
      begin
        if (S.Ctrl as TcxComboBox).ItemIndex > 0 then
          S.IdValorPV := Integer(
            (S.Ctrl as TcxComboBox).Properties.Items.Objects[
              (S.Ctrl as TcxComboBox).ItemIndex])
        else
          S.IdValorPV := 0;
        S.ValorLibre := '';
      end;
      tvpTextoLibre:
      begin
        S.IdValorPV  := 0;
        S.ValorLibre := Trim((S.Ctrl as TcxTextEdit).Text);
      end;
      tvpNumero:
      begin
        S.IdValorPV  := 0;
        S.ValorLibre := FloatToStr((S.Ctrl as TcxSpinEdit).Value);
      end;
      tvpBooleano:
      begin
        S.IdValorPV  := 0;
        S.ValorLibre := TGenUtils.IfThen<String>((S.Ctrl as TcxCheckBox).Checked, 'S', 'N');
      end;
    end;

    UpsertSlot(S);
    FSlots[i] := S;
  end;

  FModificado := False;
  Result := True;
end;

procedure TGestorPropiedades.UpsertSlot(const S: TSlotProp);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'INSERT INTO fza_articulos_propiedades ' +
      '  (CODIGO_ARTICULO, CODIGO_PROPIEDAD, ID_VALOR_PV, VALOR_LIBRE, ' +
      '   INSTANTEALTA, USUARIOALTA) ' +
      'VALUES ' +
      '  (:art, :prop, :idval, :libre, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ID_VALOR_PV = VALUES(ID_VALOR_PV), ' +
      '  VALOR_LIBRE = VALUES(VALOR_LIBRE)';

    q.ParamByName('art').AsString  := FCodigoArticulo;
    q.ParamByName('prop').AsString := S.CodigoPropiedad;

    if S.IdValorPV > 0 then
      q.ParamByName('idval').AsInteger := S.IdValorPV
    else
      q.ParamByName('idval').Clear;

    if S.ValorLibre <> '' then
      q.ParamByName('libre').AsString := S.ValorLibre
    else
      q.ParamByName('libre').Clear;

    q.ParamByName('usr').AsString := FUsuario;
    q.Execute;
  finally
    q.Free;
  end;
end;

procedure TGestorPropiedades.DeleteSlot(const CodigoPropiedad: string);
var
  q: TUniQuery;
begin
  if FCodigoArticulo = '' then Exit;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'DELETE FROM fza_articulos_propiedades ' +
      'WHERE CODIGO_ARTICULO  = :art ' +
      '  AND CODIGO_PROPIEDAD = :prop';
    q.ParamByName('art').AsString  := FCodigoArticulo;
    q.ParamByName('prop').AsString := CodigoPropiedad;
    q.Execute;
  finally
    q.Free;
  end;
end;

end.

