{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosPropiedades                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión dinámica de propiedades de artículo.                              }
{    Inyecta controles en la pestaña de propiedades y persiste sus valores.    }
{******************************************************************************}
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
  Vcl.Dialogs, inMtoModalAceptCancel, Messages,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxSpinEdit,
  cxCheckBox, cxLabel, cxDropDownEdit, cxButtons,
  cxPC, cxLookAndFeels, cxLookAndFeelPainters,
  DBAccess, Uni, System.UITypes;

type
  TTipoValorProp = (tvpLista, tvpTextoLibre, tvpNumero, tvpBooleano);

  TSlotProp = record
    CodigoPropiedad : string;
    NombrePropiedad : string;
    TipoValor       : TTipoValorProp;
    EsRequerido     : Boolean;
    IdValorPV       : Integer;
    ValorLibre      : string;
    Ctrl            : TControl;
    Opciones        : TDictionary<Integer, string>;
    Eliminar        : Boolean;
    OriginalIdValorPV : Integer;
    OriginalValorLibre: string;
  end;

  TfrmSelPropiedades = class(TFrmModalAceptCancel)
  private
    FConexion       : TUniConnection;
    FExcluirCodigos : TStringList;
    FListBox        : TListBox;
    procedure BtnAceptarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  public
    CodigosSeleccionados : TStringList;
    constructor Create(AOwner: TComponent; AConexion: TUniConnection;
                       AExcluir: TStringList); reintroduce;
    destructor Destroy; override;
    procedure CargarLista;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

  TGestorPropiedades = class
  private
    FConexion       : TUniConnection;
    FScrollBox      : TScrollBox;
    FCodigoArticulo : string;
    FUsuario        : string;
    FSlots          : TList<TSlotProp>;
    FModificado     : Boolean;

    function  TipoDesdeCadena(const ATipo: string): TTipoValorProp;
    procedure LimpiarControles;
    procedure ReconstruirVista;
    procedure CrearFilaLista      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaTexto      (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaNumero     (var S: TSlotProp; ATop: Integer);
    procedure CrearFilaBooleano   (var S: TSlotProp; ATop: Integer);
    procedure CrearBtnEliminar    (ASlotIdx: Integer; ATop: Integer);
    procedure BtnEliminarClick(Sender: TObject);
    procedure UpsertSlot(const S: TSlotProp);
    procedure DeleteSlot(const CodigoPropiedad: string);
    function IndexOfCodigo(const ACod: string): Integer;
  public
    constructor Create(AScrollBox: TScrollBox;
                       AConexion: TUniConnection;
                       const AUsuario: string);
    destructor Destroy; override;
    procedure CargarPropiedades(const ACodigoArticulo: string);
    procedure CargarPropiedadesPorFamilia(const ACodigoFamilia: string);
    procedure AbrirSelectorPropiedades;
    function GuardarPropiedades: Boolean;
    function Validar: string;
    property Modificado: Boolean read FModificado;
  end;

implementation

uses uGenericIfThen;

const
  ALTO_FILA      = 26;
  MARGEN_V       = 6;
  MARGEN_H       = 8;
  ANCHO_LABEL    = 180;
  ANCHO_CTRL     = 260;
  ANCHO_BTN_DEL  = 24;
  COLOR_REQUERIDO = clMaroon;

constructor TfrmSelPropiedades.Create(AOwner: TComponent;
  AConexion: TUniConnection; AExcluir: TStringList);
begin
  inherited Create(AOwner);
  FConexion       := AConexion;
  FExcluirCodigos := AExcluir;
  CodigosSeleccionados := TStringList.Create;
  Caption    := 'Añadir propiedades al artículo';
  Width      := 542;
  Height     := 400;
  Position   := poOwnerFormCenter;
  BorderStyle:= bsDialog;
  Font.name := 'Lucida Sans';
  FListBox := TListBox.Create(Self);
  FListBox.Parent      := pnlBody;
  FListBox.Align       := alClient;
  FListBox.MultiSelect := True;
  FListBox.Style       := lbOwnerDrawFixed;
  FListBox.ItemHeight  := 22;
  FListBox.BorderStyle := bsNone;
  FListBox.ParentFont := True;
  if Assigned(btnAceptar) then
    btnAceptar.OnClick := BtnAceptarClick;
  if Assigned(btnCancelar) then
    btnCancelar.OnClick := BtnCancelarClick;
  CargarLista;
end;

destructor TfrmSelPropiedades.Destroy;
begin
  FreeAndNil(CodigosSeleccionados);
  inherited;
end;

function TfrmSelPropiedades.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    // Ejecutamos el botón cancelar y cerramos la modal
    BtnCancelarClick(Self);

    // Al devolver True, le decimos a Delphi: "Ya me he encargado de esta tecla,
    // córtala aquí y NO la pases al formulario principal".
    Result := True;
    Exit;
  end;

  // Para el resto de teclas, comportamiento normal
  Result := inherited IsShortCut(Message);
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
      'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP ' +
      'FROM   fza_propiedades ' +
      'WHERE  ESACTIVO_PROP = ''S'' ' +
      'ORDER  BY NOMBRE_PROP_PROP';
    q.Open;
    while not q.Eof do
    begin
      // Excluir las ya asignadas
      if FExcluirCodigos.IndexOf(q.FieldByName(
        'CODIGO_PROP_ARTPROP').AsString) < 0 then
      begin
        FListBox.Items.AddObject(
          q.FieldByName('NOMBRE_PROP_PROP').AsString + '  [' +
          q.FieldByName('TIPO_VALOR_PROP').AsString + ']',
          TObject(FListBox.Items.Count));
        // Guardar el código en un objeto paralelo usando tag del form
        // Usamos Items.Objects con índice entero como referencia, almacenamos
        // código en Tag via SubItems trick → usamos un StringList auxiliar
        CodigosSeleccionados.Add(q.FieldByName('CODIGO_PROP_ARTPROP').AsString);
      end;
      q.Next;
    end;
  finally
    FreeAndNil(q);
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
    FreeAndNil(seleccionados);
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
  FreeAndNil(FSlots);
  inherited;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Helpers internos                                                            }
{ ═══════════════════════════════════════════════════════════════════════════ }

function TGestorPropiedades.TipoDesdeCadena(const ATipo: string): TTipoValorProp;
begin
  if      ATipo = 'LISTA'    then Result := tvpLista
  else if ATipo = 'NUMERO'   then Result := tvpNumero
  else if ATipo = 'BOOLEANO' then Result := tvpBooleano
  else                            Result := tvpTextoLibre;
end;

function TGestorPropiedades.IndexOfCodigo(const ACod: string): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to FSlots.Count - 1 do
    if FSlots[i].CodigoPropiedad = ACod then
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
      FreeAndNil(FSlots[i].Opciones);
  FSlots.Clear;

  // Destruir controles del scroll
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FreeAndNil(FScrollBox.Controls[0]);
  finally
    FScrollBox.EnableAlign;
  end;
end;

{ ═══════════════════════════════════════════════════════════════════════════ }
{ Carga desde BD                                                              }
{ ═══════════════════════════════════════════════════════════════════════════ }

procedure TGestorPropiedades.CargarPropiedades(const ACodigoArticulo: string);
var
  q    : TUniQuery;
  qOpc : TUniQuery;
  S    : TSlotProp;
  i    : Integer;
begin
  FCodigoArticulo := ACodigoArticulo;
  LimpiarControles;
  FModificado := False;

  if ACodigoArticulo = '' then Exit;

  // ── 1. Propiedades ya asignadas a este artículo ────────────────────────
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, p.TIPO_VALOR_PROP, ' +
      '       ap.ID_PV_ARTPROP, ap.VALOR_LIBRE_ARTPROP, ' +
      '       COALESCE(fa.ESREQUERIDO_FA, ''N'') AS ESREQUERIDO_FA, ' +
      '       COALESCE(fa.ORDEN_MOSTRAR_FA, 999) AS ORDEN_MOSTRAR_FA ' +
      'FROM   fza_articulos_propiedades ap ' +
      'JOIN   fza_propiedades p ON p.CODIGO_PROP_ARTPROP = ' +
      'ap.CODIGO_PROP_ARTPROP ' +
      'LEFT JOIN fza_articulos art ON art.CODIGO_ART_ART = ap.CODIGO_ART_ART ' +
      'LEFT JOIN fza_familias_atributos fa ' +
      '       ON fa.CODIGO_PROP_ARTPROP = ap.CODIGO_PROP_ARTPROP ' +
      '      AND fa.CODIGO_FAM_FAM   = art.CODIGO_FAM_ART ' +
      'WHERE  ap.CODIGO_ART_ART = :art ' +
      '  AND  p.ESACTIVO_PROP = ''S'' ' +
      'ORDER  BY COALESCE(fa.ORDEN_MOSTRAR_FA, 999), p.NOMBRE_PROP_PROP';
    q.ParamByName('art').AsString := ACodigoArticulo;
    q.Open;
    while not q.Eof do
    begin
      // Default() libera los strings del record anterior (decrementa
      // su refcount) antes de re-inicializar. FillChar machacaba los
      // punteros sin liberar, dejando los buffers de strings huerfanos
      // -> ~20 UnicodeString leak por cada CargarPropiedades.
      S := Default(TSlotProp);
      S.CodigoPropiedad := q.FieldByName('CODIGO_PROP_ARTPROP').AsString;
      S.NombrePropiedad := q.FieldByName('NOMBRE_PROP_PROP').AsString;
      S.TipoValor := TipoDesdeCadena(q.FieldByName('TIPO_VALOR_PROP').AsString);
      S.EsRequerido     := q.FieldByName('ESREQUERIDO_FA').AsString = 'S';
      S.IdValorPV       := q.FieldByName('ID_PV_ARTPROP').AsInteger;
      S.ValorLibre      := q.FieldByName('VALOR_LIBRE_ARTPROP').AsString;
      S.OriginalIdValorPV  := S.IdValorPV;
      S.OriginalValorLibre := S.ValorLibre;
      S.Ctrl            := nil;
      S.Opciones        := nil;
      S.Eliminar        := False;
      FSlots.Add(S);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
  // ── 2. Opciones para slots tipo LISTA ─────────────────────────────────
  qOpc := TUniQuery.Create(nil);
  try
    qOpc.Connection := FConexion;
    qOpc.SQL.Text   :=
      'SELECT ID_PV_ARTPROP, PV ' +
      'FROM   fza_propiedades_valores ' +
      'WHERE  ID_PROP_PV = :cod ' +
      '  AND  ESACTIVO_PV = ''S'' ' +
      'ORDER  BY PV';
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
            qOpc.FieldByName('ID_PV_ARTPROP').AsInteger,
            qOpc.FieldByName('PV').AsString);
          qOpc.Next;
        end;
        FSlots[i] := S;
      end;
    end;
  finally
    FreeAndNil(qOpc);
  end;
  ReconstruirVista;
end;

procedure TGestorPropiedades.CargarPropiedadesPorFamilia(
                                                   const ACodigoFamilia: string);
var
  qProp     : TUniQuery;
  qOpc      : TUniQuery;
  S         : TSlotProp;
  cod       : string;
  idx, i    : Integer;
  EstaVacia : Boolean;
begin
  if ACodigoFamilia = '' then Exit;

  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    if (not S.Eliminar) and Assigned(S.Ctrl) then
    begin
      case S.TipoValor of
        tvpLista:
          if (S.Ctrl as TcxComboBox).ItemIndex > 0 then
            S.IdValorPV := Integer((S.Ctrl as TcxComboBox).Properties.Items.
                                     Objects[(S.Ctrl as TcxComboBox).ItemIndex])
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
      S.OriginalIdValorPV  := S.IdValorPV;
      S.OriginalValorLibre := S.ValorLibre;
    end;
    FSlots[i] := S;
  end;
  for i := 0 to FSlots.Count - 1 do
  begin
    S := FSlots[i];
    EstaVacia := False;
    case S.TipoValor of
      tvpLista:      EstaVacia := (S.IdValorPV <= 0);
      tvpTextoLibre: EstaVacia := (S.ValorLibre = '');
      tvpNumero:     EstaVacia := (S.ValorLibre = '') or (S.ValorLibre = '0');
      tvpBooleano:   EstaVacia := (S.ValorLibre <> 'S') and
                                                          (S.ValorLibre <> '1');
    end;
    if EstaVacia then
      S.Eliminar := True;
    FSlots[i] := S;
  end;
  FModificado := True;
  qProp := TUniQuery.Create(nil);
  qOpc  := TUniQuery.Create(nil);
  try
    qProp.Connection := FConexion;
    qProp.SQL.Text   :=
      'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, p.TIPO_VALOR_PROP, ' +
                                                            'fa.ESREQUERIDO_FA '
                                                              +
      'FROM fza_familias_atributos fa ' +
      'JOIN fza_propiedades p ON p.CODIGO_PROP_ARTPROP = ' +
      'fa.CODIGO_PROP_ARTPROP ' +
      'WHERE fa.CODIGO_FAM_FAM = :fam ' +
      '  AND p.ESACTIVO_PROP = ''S'' ' +
      'ORDER BY fa.ORDEN_MOSTRAR_FA, p.NOMBRE_PROP_PROP';
    qProp.ParamByName('fam').AsString := ACodigoFamilia;
    qProp.Open;
    qOpc.Connection := FConexion;
    qOpc.SQL.Text   :=
      'SELECT ID_PV_ARTPROP, PV ' +
      'FROM fza_propiedades_valores ' +
      'WHERE ID_PROP_PV = :cod AND ESACTIVO_PV = ''S'' ' +
      'ORDER BY PV';
    while not qProp.Eof do
    begin
      cod := qProp.FieldByName('CODIGO_PROP_ARTPROP').AsString;
      idx := IndexOfCodigo(cod);
      if idx < 0 then
      begin
        // Ver nota arriba: FillChar machacaba strings sin liberar.
        S := Default(TSlotProp);
        S.CodigoPropiedad := cod;
        S.NombrePropiedad := qProp.FieldByName('NOMBRE_PROP_PROP').AsString;
        S.TipoValor       :=
                      TipoDesdeCadena(qProp.FieldByName(
                        'TIPO_VALOR_PROP').AsString);
        S.EsRequerido     := qProp.FieldByName('ESREQUERIDO_FA').AsString = 'S';
        S.IdValorPV       := 0;
        S.ValorLibre      := '';
        S.OriginalIdValorPV  := S.IdValorPV;
        S.OriginalValorLibre := S.ValorLibre;
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
            S.Opciones.Add(qOpc.FieldByName('ID_PV_ARTPROP').AsInteger,
                           qOpc.FieldByName('PV').AsString);
            qOpc.Next;
          end;
        end;
        FSlots.Add(S);
      end
      else
      begin
        S := FSlots[idx];
        S.EsRequerido := qProp.FieldByName('ESREQUERIDO_FA').AsString = 'S';
        S.Eliminar := False;
        FSlots[idx] := S;
      end;
      qProp.Next;
    end;
    ReconstruirVista;
  finally
    FreeAndNil(qProp);
    FreeAndNil(qOpc);
  end;
end;

procedure TGestorPropiedades.ReconstruirVista;
var
  i   : Integer;
  Top : Integer;
  S   : TSlotProp;
begin
  FScrollBox.DisableAlign;
  try
    while FScrollBox.ControlCount > 0 do
      FreeAndNil(FScrollBox.Controls[0]);
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
  lbl.Transparent := True;
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
  if S.IdValorPV > 0 then
    for Idx := 1 to cb.Properties.Items.Count - 1 do
      if Integer(cb.Properties.Items.Objects[Idx]) = S.IdValorPV then
      begin
        cb.ItemIndex := Idx;
        Break;
      end;
  S.Ctrl := cb;
end;

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
  lbl.Transparent := True;
  ed := TcxTextEdit.Create(FScrollBox);
  ed.Parent := FScrollBox;
  ed.Left   := MARGEN_H + ANCHO_LABEL + 6;
  ed.Top    := ATop;
  ed.Width  := ANCHO_CTRL;
  ed.Height := ALTO_FILA;
  ed.Text   := S.ValorLibre;
  S.Ctrl := ed;
end;

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
  lbl.Transparent := True;
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
  lbl.Transparent := True;
  chk := TcxCheckBox.Create(FScrollBox);
  chk.Parent   := FScrollBox;
  chk.Left     := MARGEN_H + ANCHO_LABEL + 6;
  chk.Top      := ATop + 4;
  chk.Width    := ALTO_FILA;
  chk.Height   := ALTO_FILA;
  chk.Caption  := '';
  chk.Properties.DisplayChecked   := '';
  chk.Properties.DisplayUnchecked := '';
  chk.Properties.DisplayGrayed    := '';
  chk.Checked  := (S.ValorLibre = 'S') or (S.ValorLibre = '1');
  S.Ctrl := chk;
end;

procedure TGestorPropiedades.CrearBtnEliminar(ASlotIdx: Integer; ATop: Integer);
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
  btn.Tag     := ASlotIdx;
  btn.Hint    := 'Quitar propiedad ' + FSlots[ASlotIdx].NombrePropiedad;
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
  Excluidos := TStringList.Create;
  try
    for i := 0 to FSlots.Count - 1 do
      if not FSlots[i].Eliminar then
        Excluidos.Add(FSlots[i].CodigoPropiedad);
    dlg := TfrmSelPropiedades.Create(nil, FConexion, Excluidos);
    try
      if dlg.ShowModal <> mrOk then Exit;
      if dlg.CodigosSeleccionados.Count = 0 then Exit;
      qProp := TUniQuery.Create(nil);
      qOpc  := TUniQuery.Create(nil);
      try
        qProp.Connection := FConexion;
        qProp.SQL.Text   :=
          'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP ' +
          'FROM   fza_propiedades ' +
          'WHERE  CODIGO_PROP_ARTPROP = :cod';
        qOpc.Connection := FConexion;
        qOpc.SQL.Text   :=
          'SELECT ID_PV_ARTPROP, PV ' +
          'FROM   fza_propiedades_valores ' +
          'WHERE  ID_PROP_PV = :cod ' +
          '  AND  ESACTIVO_PV = ''S'' ' +
          'ORDER  BY PV';
        for cod in dlg.CodigosSeleccionados do
        begin
          qProp.Close;
          qProp.ParamByName('cod').AsString := cod;
          qProp.Open;
          if qProp.Eof then Continue;
          // Ver nota arriba: FillChar machacaba strings sin liberar.
          S := Default(TSlotProp);
          S.CodigoPropiedad :=
            qProp.FieldByName('CODIGO_PROP_ARTPROP').AsString;
          S.NombrePropiedad := qProp.FieldByName('NOMBRE_PROP_PROP').AsString;
          S.TipoValor       :=
                      TipoDesdeCadena(qProp.FieldByName(
                        'TIPO_VALOR_PROP').AsString);
          S.EsRequerido     := False;
          S.IdValorPV       := 0;
          S.ValorLibre      := '';
          S.OriginalIdValorPV  := S.IdValorPV;
          S.OriginalValorLibre := S.ValorLibre;
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
                qOpc.FieldByName('ID_PV_ARTPROP').AsInteger,
                qOpc.FieldByName('PV').AsString);
              qOpc.Next;
            end;
          end;
          FSlots.Add(S);
          FModificado := True;
        end;
      finally
        FreeAndNil(qProp);
        FreeAndNil(qOpc);
      end;
      ReconstruirVista;
    finally
      FreeAndNil(dlg);
    end;
  finally
    FreeAndNil(Excluidos);
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
        S.ValorLibre :=
            TGenUtils.IfThen<String>((S.Ctrl as TcxCheckBox).Checked, 'S', 'N');
      end;
    end;
    if (S.IdValorPV <> S.OriginalIdValorPV) or
       (S.ValorLibre <> S.OriginalValorLibre) then
    begin
      UpsertSlot(S);
      S.OriginalIdValorPV  := S.IdValorPV;
      S.OriginalValorLibre := S.ValorLibre;
    end;
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
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
      'VALOR_LIBRE_ARTPROP, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES ' +
      '  (:art, :prop, :idval, :libre, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ID_PV_ARTPROP = VALUES(ID_PV_ARTPROP), ' +
      '  VALOR_LIBRE_ARTPROP = VALUES(VALOR_LIBRE_ARTPROP)';
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
    FreeAndNil(q);
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
      'WHERE CODIGO_ART_ART  = :art ' +
      '  AND CODIGO_PROP_ARTPROP = :prop';
    q.ParamByName('art').AsString  := FCodigoArticulo;
    q.ParamByName('prop').AsString := CodigoPropiedad;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

end.

