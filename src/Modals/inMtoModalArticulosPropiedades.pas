{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArticulosPropiedades                                }
{    Tipo:       Formulario (Modal)                                            }
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
unit inMtoModalArticulosPropiedades;

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
    Nivel           : string;
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
    FCargando       : Boolean;

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
    procedure CrearBtnPorUnidad(ASlotIdx, ATop: Integer);
    procedure BtnPorUnidadClick(Sender: TObject);
    procedure AbrirEditorPorUnidad(const S: TSlotProp);
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

  TFilaUnidadProp = record
    Unidad : string;
    Nombre : string;
    Ctrl   : TControl;
  end;

  TValUnidadProp = record
    IdValor    : Integer;
    ValorLibre : string;
  end;

  // Modal "propiedad por color/SKU": lista las unidades (colores o SKUs) del
  // articulo y fija el valor de UNA propiedad a ese nivel. Persiste directo en
  // fza_articulos_propiedades con CODIGO_UNIDAD_ARTPROP (mismo mecanismo que
  // tarifas/fotos). Construido en codigo, sin .dfm propio.
  TfrmPropPorUnidad = class(TFrmModalAceptCancel)
  private
    FConexion   : TUniConnection;
    FUsuario    : string;
    FArticulo   : string;
    FCodigoProp : string;
    FNombreProp : string;
    FTipoValor  : TTipoValorProp;
    FNivel      : string;
    FScroll     : TScrollBox;
    FFilas      : TList<TFilaUnidadProp>;
    FOpciones   : TList<TPair<Integer, string>>;
    FActuales   : TDictionary<string, TValUnidadProp>;
    procedure CargarOpciones;
    procedure CargarUnidades;
    procedure CargarValoresActuales;
    procedure ConstruirFilas;
    procedure CrearControlFila(var F: TFilaUnidadProp; ATop, AIdValor: Integer;
                               const AValorLibre: string);
    procedure UpsertUnidad(const AUnidad: string; AIdValor: Integer;
                           const AValorLibre: string);
    procedure DeleteUnidad(const AUnidad: string);
    procedure BtnAceptarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; AConexion: TUniConnection;
                       const AUsuario, AArticulo, ACodigoProp,
                       ANombreProp: string; ATipoValor: TTipoValorProp;
                       const ANivel: string); reintroduce;
    destructor Destroy; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
  end;

implementation

uses uGenericIfThen, inLibMsgArticulos;

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
  // Guard de reentrada: dos cargas solapadas (p.ej. dos AfterScroll casi
  // simultaneos) comparten FSlots y el LimpiarControles de una vacia la
  // lista mientras la otra la recorre -> EArgumentOutOfRangeException.
  if FCargando then
    Exit;
  FCargando := True;
  try
    FCodigoArticulo := ACodigoArticulo;
    LimpiarControles;
    FModificado := False;
    if ACodigoArticulo = '' then Exit;
    // ── 1. Propiedades ya asignadas a este artículo ──────────────────────
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      // Una fila por propiedad que el articulo tenga a CUALQUIER nivel
      // (DISTINCT sobre la PK ampliada de Fase 1). El valor que se edita en
      // esta pestaña es el de nivel ARTICULO (apz, CODIGO_UNIDAD_ARTPROP =
      // ''); el desglose por color/SKU se gestiona en TfrmPropPorUnidad.
      q.SQL.Text :=
        'SELECT p.CODIGO_PROP_ARTPROP, p.NOMBRE_PROP_PROP, p.TIPO_VALOR_PROP, ' +
        '       p.NIVEL_PROP, ' +
        '       apz.ID_PV_ARTPROP, apz.VALOR_LIBRE_ARTPROP, ' +
        '       COALESCE(fa.ESREQUERIDO_FA, ''N'') AS ESREQUERIDO_FA, ' +
        '       COALESCE(fa.ORDEN_MOSTRAR_FA, 999) AS ORDEN_MOSTRAR_FA ' +
        'FROM   (SELECT DISTINCT CODIGO_ART_ART, CODIGO_PROP_ARTPROP ' +
        '          FROM fza_articulos_propiedades ' +
        '         WHERE CODIGO_ART_ART = :art) d ' +
        'JOIN   fza_propiedades p ' +
        '       ON p.CODIGO_PROP_ARTPROP = d.CODIGO_PROP_ARTPROP ' +
        'LEFT JOIN fza_articulos_propiedades apz ' +
        '       ON apz.CODIGO_ART_ART        = d.CODIGO_ART_ART ' +
        '      AND apz.CODIGO_PROP_ARTPROP   = d.CODIGO_PROP_ARTPROP ' +
        '      AND apz.CODIGO_UNIDAD_ARTPROP = '''' ' +
        'LEFT JOIN fza_articulos art ' +
        '       ON art.CODIGO_ART_ART = d.CODIGO_ART_ART ' +
        'LEFT JOIN fza_familias_atributos fa ' +
        '       ON fa.CODIGO_PROP_ARTPROP = d.CODIGO_PROP_ARTPROP ' +
        '      AND fa.CODIGO_FAM_FAM      = art.CODIGO_FAM_ART ' +
        'WHERE  p.ESACTIVO_PROP = ''S'' ' +
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
        S.Nivel           := q.FieldByName('NIVEL_PROP').AsString;
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
    // ── 2. Opciones para slots tipo LISTA ────────────────────────────────
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
  finally
    FCargando := False;
  end;
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
      '       p.NIVEL_PROP, fa.ESREQUERIDO_FA ' +
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
        S.Nivel           := qProp.FieldByName('NIVEL_PROP').AsString;
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
    if (S.Nivel = 'COLOR') or (S.Nivel = 'SKU') then
      CrearBtnPorUnidad(i, Top);
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
  btn.Hint    := Format(SHintQuitarPropiedad,
                        [FSlots[ASlotIdx].NombrePropiedad]);
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

  if MessageDlg(Format(SPreguntaQuitarPropiedadArticulo,
                       [FSlots[idx].NombrePropiedad]),
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

procedure TGestorPropiedades.CrearBtnPorUnidad(ASlotIdx, ATop: Integer);
var
  btn: TcxButton;
  S  : TSlotProp;
begin
  S := FSlots[ASlotIdx];
  btn := TcxButton.Create(FScrollBox);
  btn.Parent := FScrollBox;
  btn.Left   := MARGEN_H + ANCHO_LABEL + 6 + ANCHO_CTRL + 6 + ANCHO_BTN_DEL + 6;
  btn.Top    := ATop;
  btn.Width  := 110;
  btn.Height := ALTO_FILA;
  if S.Nivel = 'SKU' then
    btn.Caption := SCaptionPorColorSku
  else
    btn.Caption := SCaptionPorColor;
  btn.Tag      := ASlotIdx;
  btn.Hint     := Format(SHintFijarPropiedadPorColorSku,
                         [S.NombrePropiedad]);
  btn.ShowHint := True;
  btn.OnClick  := BtnPorUnidadClick;
end;

procedure TGestorPropiedades.BtnPorUnidadClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := (Sender as TcxButton).Tag;
  if (idx >= 0) and (idx < FSlots.Count) then
  begin
    if FCodigoArticulo = '' then
      ShowMessage(SErrorArticuloNoGuardadoValoresColor)
    else
      AbrirEditorPorUnidad(FSlots[idx]);
  end;
end;

procedure TGestorPropiedades.AbrirEditorPorUnidad(const S: TSlotProp);
var
  dlg: TfrmPropPorUnidad;
begin
  dlg := TfrmPropPorUnidad.Create(nil, FConexion, FUsuario, FCodigoArticulo,
           S.CodigoPropiedad, S.NombrePropiedad, S.TipoValor, S.Nivel);
  try
    dlg.ShowModal;
  finally
    FreeAndNil(dlg);
  end;
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
    ShowMessage(SErrorArticuloNoGuardadoAnadirPropiedades);
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
          'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP, TIPO_VALOR_PROP, ' +
          '       NIVEL_PROP ' +
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
          S.Nivel           := qProp.FieldByName('NIVEL_PROP').AsString;
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
        Result := Format(SErrorPropiedadObligatoriaFamilia,
                         [S.NombrePropiedad]);
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

{ ═══════════════════════════════════════════════════════════════════════════ }
{ TfrmPropPorUnidad — editor de una propiedad por color/SKU                    }
{ ═══════════════════════════════════════════════════════════════════════════ }

constructor TfrmPropPorUnidad.Create(AOwner: TComponent;
  AConexion: TUniConnection; const AUsuario, AArticulo, ACodigoProp,
  ANombreProp: string; ATipoValor: TTipoValorProp; const ANivel: string);
begin
  inherited Create(AOwner);
  FConexion   := AConexion;
  FUsuario    := AUsuario;
  FArticulo   := AArticulo;
  FCodigoProp := ACodigoProp;
  FNombreProp := ANombreProp;
  FTipoValor  := ATipoValor;
  FNivel      := ANivel;
  FFilas      := TList<TFilaUnidadProp>.Create;
  FOpciones   := TList<TPair<Integer, string>>.Create;
  FActuales   := TDictionary<string, TValUnidadProp>.Create;
  if FNivel = 'SKU' then
    Caption := FNombreProp + ' por SKU'
  else
    Caption := FNombreProp + ' por color';
  Width       := 560;
  Height      := 460;
  Position    := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Font.Name   := 'Lucida Sans';
  FScroll := TScrollBox.Create(Self);
  FScroll.Parent      := pnlBody;
  FScroll.Align       := alClient;
  FScroll.BorderStyle := bsNone;
  FScroll.Color       := clWindow;
  FScroll.AutoScroll  := True;
  if FTipoValor = tvpLista then
    CargarOpciones;
  CargarUnidades;
  CargarValoresActuales;
  ConstruirFilas;
  if Assigned(btnAceptar) then
    btnAceptar.OnClick := BtnAceptarClick;
  if Assigned(btnCancelar) then
    btnCancelar.OnClick := BtnCancelarClick;
end;

destructor TfrmPropPorUnidad.Destroy;
begin
  FreeAndNil(FFilas);
  FreeAndNil(FOpciones);
  FreeAndNil(FActuales);
  inherited;
end;

function TfrmPropPorUnidad.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    BtnCancelarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmPropPorUnidad.CargarOpciones;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT ID_PV_ARTPROP, PV ' +
      'FROM   fza_propiedades_valores ' +
      'WHERE  ID_PROP_PV = :cod ' +
      '  AND  ESACTIVO_PV = ''S'' ' +
      'ORDER  BY PV';
    q.ParamByName('cod').AsString := FCodigoProp;
    q.Open;
    while not q.Eof do
    begin
      FOpciones.Add(TPair<Integer, string>.Create(
        q.FieldByName('ID_PV_ARTPROP').AsInteger,
        q.FieldByName('PV').AsString));
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPropPorUnidad.CargarUnidades;
var
  q      : TUniQuery;
  F      : TFilaUnidadProp;
  partes : TArray<string>;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    if FNivel = 'SKU' then
      q.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU AS UNIDAD, ' +
        '       COALESCE((SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV ' +
        '                          SEPARATOR '' / '') ' +
        '                   FROM fza_atributos_sku sa ' +
        '                   JOIN fza_atributos_valores av ' +
        '                     ON av.ID_AV = sa.ID_AV_SA ' +
        '                  WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                        sk.CODIGO_UNIDAD_SKU), ' +
        '                sk.CODIGO_UNIDAD_SKU) AS NOMBRE ' +
        'FROM   fza_articulos_skus sk ' +
        'WHERE  sk.CODIGO_ART_SKU = :art ' +
        '  AND  sk.ESACTIVO_SKU = ''S'' ' +
        'ORDER  BY sk.CODIGO_UNIDAD_SKU'
    else
      q.SQL.Text :=
        'SELECT DISTINCT ' +
        '       SUBSTRING_INDEX(CODIGO_UNIDAD_SKU, ''/'', 2) AS UNIDAD ' +
        'FROM   fza_articulos_skus ' +
        'WHERE  CODIGO_ART_SKU = :art ' +
        '  AND  ESACTIVO_SKU = ''S'' ' +
        '  AND  CHAR_LENGTH(CODIGO_UNIDAD_SKU) ' +
        '     - CHAR_LENGTH(REPLACE(CODIGO_UNIDAD_SKU, ''/'', '''')) >= 2 ' +
        'ORDER  BY UNIDAD';
    q.ParamByName('art').AsString := FArticulo;
    q.Open;
    while not q.Eof do
    begin
      F := Default(TFilaUnidadProp);
      F.Unidad := q.FieldByName('UNIDAD').AsString;
      if FNivel = 'SKU' then
        F.Nombre := q.FieldByName('NOMBRE').AsString
      else
      begin
        partes := F.Unidad.Split(['/']);
        if Length(partes) > 0 then
          F.Nombre := partes[High(partes)]
        else
          F.Nombre := F.Unidad;
      end;
      F.Ctrl := nil;
      FFilas.Add(F);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPropPorUnidad.CargarValoresActuales;
var
  q: TUniQuery;
  V: TValUnidadProp;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT CODIGO_UNIDAD_ARTPROP, ID_PV_ARTPROP, VALOR_LIBRE_ARTPROP ' +
      'FROM   fza_articulos_propiedades ' +
      'WHERE  CODIGO_ART_ART = :art ' +
      '  AND  CODIGO_PROP_ARTPROP = :prop ' +
      '  AND  CODIGO_UNIDAD_ARTPROP <> ''''';
    q.ParamByName('art').AsString  := FArticulo;
    q.ParamByName('prop').AsString := FCodigoProp;
    q.Open;
    while not q.Eof do
    begin
      V.IdValor    := q.FieldByName('ID_PV_ARTPROP').AsInteger;
      V.ValorLibre := q.FieldByName('VALOR_LIBRE_ARTPROP').AsString;
      FActuales.AddOrSetValue(
        q.FieldByName('CODIGO_UNIDAD_ARTPROP').AsString, V);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPropPorUnidad.ConstruirFilas;
var
  i        : Integer;
  Top      : Integer;
  F        : TFilaUnidadProp;
  V        : TValUnidadProp;
  lblVacio : TcxLabel;
begin
  if FFilas.Count = 0 then
  begin
    lblVacio := TcxLabel.Create(FScroll);
    lblVacio.Parent      := FScroll;
    lblVacio.Left        := MARGEN_H;
    lblVacio.Top         := MARGEN_V;
    lblVacio.Caption     := SCaptionSinColoresSkuDefinidos;
    lblVacio.Transparent := True;
  end;
  Top := MARGEN_V;
  for i := 0 to FFilas.Count - 1 do
  begin
    F := FFilas[i];
    if FActuales.TryGetValue(F.Unidad, V) then
      CrearControlFila(F, Top, V.IdValor, V.ValorLibre)
    else
      CrearControlFila(F, Top, 0, '');
    FFilas[i] := F;
    Inc(Top, ALTO_FILA + MARGEN_V);
  end;
end;

procedure TfrmPropPorUnidad.CrearControlFila(var F: TFilaUnidadProp;
  ATop, AIdValor: Integer; const AValorLibre: string);
var
  lbl : TcxLabel;
  cb  : TcxComboBox;
  ed  : TcxTextEdit;
  sp  : TcxSpinEdit;
  chk : TcxCheckBox;
  par : TPair<Integer, string>;
  Idx : Integer;
begin
  lbl := TcxLabel.Create(FScroll);
  lbl.Parent      := FScroll;
  lbl.Left        := MARGEN_H;
  lbl.Top         := ATop + 4;
  lbl.Width       := ANCHO_LABEL;
  lbl.AutoSize    := True;
  lbl.Caption     := F.Nombre;
  lbl.Transparent := True;
  case FTipoValor of
    tvpLista:
    begin
      cb := TcxComboBox.Create(FScroll);
      cb.Parent := FScroll;
      cb.Left   := MARGEN_H + ANCHO_LABEL + 6;
      cb.Top    := ATop;
      cb.Width  := ANCHO_CTRL;
      cb.Height := ALTO_FILA;
      cb.Properties.DropDownListStyle := lsFixedList;
      cb.Properties.Items.Add('');
      for par in FOpciones do
        cb.Properties.Items.AddObject(par.Value, TObject(par.Key));
      if AIdValor > 0 then
        for Idx := 1 to cb.Properties.Items.Count - 1 do
          if Integer(cb.Properties.Items.Objects[Idx]) = AIdValor then
            cb.ItemIndex := Idx;
      F.Ctrl := cb;
    end;
    tvpTextoLibre:
    begin
      ed := TcxTextEdit.Create(FScroll);
      ed.Parent := FScroll;
      ed.Left   := MARGEN_H + ANCHO_LABEL + 6;
      ed.Top    := ATop;
      ed.Width  := ANCHO_CTRL;
      ed.Height := ALTO_FILA;
      ed.Text   := AValorLibre;
      F.Ctrl := ed;
    end;
    tvpNumero:
    begin
      sp := TcxSpinEdit.Create(FScroll);
      sp.Parent := FScroll;
      sp.Left   := MARGEN_H + ANCHO_LABEL + 6;
      sp.Top    := ATop;
      sp.Width  := 120;
      sp.Height := ALTO_FILA;
      sp.Properties.EditFormat := '0.00';
      if AValorLibre <> '' then
        sp.Value := StrToFloatDef(
          StringReplace(AValorLibre, ',', '.', []), 0);
      F.Ctrl := sp;
    end;
    tvpBooleano:
    begin
      chk := TcxCheckBox.Create(FScroll);
      chk.Parent := FScroll;
      chk.Left   := MARGEN_H + ANCHO_LABEL + 6;
      chk.Top    := ATop + 4;
      chk.Width  := ALTO_FILA;
      chk.Height := ALTO_FILA;
      chk.Caption := '';
      chk.Properties.DisplayChecked   := '';
      chk.Properties.DisplayUnchecked := '';
      chk.Properties.DisplayGrayed    := '';
      chk.Checked := (AValorLibre = 'S') or (AValorLibre = '1');
      F.Ctrl := chk;
    end;
  end;
end;

procedure TfrmPropPorUnidad.UpsertUnidad(const AUnidad: string;
  AIdValor: Integer; const AValorLibre: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_propiedades ' +
      '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, CODIGO_UNIDAD_ARTPROP, ' +
      '   ID_PV_ARTPROP, VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES ' +
      '  (:art, :prop, :uni, :idval, :libre, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  ID_PV_ARTPROP       = VALUES(ID_PV_ARTPROP), ' +
      '  VALOR_LIBRE_ARTPROP = VALUES(VALOR_LIBRE_ARTPROP)';
    q.ParamByName('art').AsString  := FArticulo;
    q.ParamByName('prop').AsString := FCodigoProp;
    q.ParamByName('uni').AsString  := AUnidad;
    if AIdValor > 0 then
      q.ParamByName('idval').AsInteger := AIdValor
    else
      q.ParamByName('idval').Clear;
    if AValorLibre <> '' then
      q.ParamByName('libre').AsString := AValorLibre
    else
      q.ParamByName('libre').Clear;
    q.ParamByName('usr').AsString := FUsuario;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPropPorUnidad.DeleteUnidad(const AUnidad: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'DELETE FROM fza_articulos_propiedades ' +
      'WHERE CODIGO_ART_ART        = :art ' +
      '  AND CODIGO_PROP_ARTPROP   = :prop ' +
      '  AND CODIGO_UNIDAD_ARTPROP = :uni';
    q.ParamByName('art').AsString  := FArticulo;
    q.ParamByName('prop').AsString := FCodigoProp;
    q.ParamByName('uni').AsString  := AUnidad;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmPropPorUnidad.BtnAceptarClick(Sender: TObject);
var
  i     : Integer;
  F     : TFilaUnidadProp;
  idVal : Integer;
  libre : string;
  vacio : Boolean;
begin
  for i := 0 to FFilas.Count - 1 do
  begin
    F := FFilas[i];
    if Assigned(F.Ctrl) then
    begin
      idVal := 0;
      libre := '';
      vacio := True;
      case FTipoValor of
        tvpLista:
          if (F.Ctrl as TcxComboBox).ItemIndex > 0 then
          begin
            idVal := Integer((F.Ctrl as TcxComboBox).Properties.Items.Objects[
                       (F.Ctrl as TcxComboBox).ItemIndex]);
            vacio := False;
          end;
        tvpTextoLibre:
        begin
          libre := Trim((F.Ctrl as TcxTextEdit).Text);
          vacio := libre = '';
        end;
        tvpNumero:
          if Trim((F.Ctrl as TcxSpinEdit).Text) <> '' then
          begin
            libre := FloatToStr((F.Ctrl as TcxSpinEdit).Value);
            vacio := False;
          end;
        tvpBooleano:
          if (F.Ctrl as TcxCheckBox).Checked then
          begin
            libre := 'S';
            vacio := False;
          end;
      end;
      if vacio then
        DeleteUnidad(F.Unidad)
      else
        UpsertUnidad(F.Unidad, idVal, libre);
    end;
  end;
  ModalResult := mrOk;
end;

procedure TfrmPropPorUnidad.BtnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.

