{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosVariaciones                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión dinámica de variaciones y SKUs de artículo.                       }
{    Edita los conjuntos de atributos y el catálogo de SKUs activos del        }
{    artículo.                                                                 }
{******************************************************************************}
unit UniDataArticulosVariaciones;

{
  Unidad: inLibArticulosVariaciones
  Descripción: Gestión dinámica de variaciones en la pestaña tsVariaciones
               del formulario TfrmMtoArticulos de Factuzam.

  Modelo de datos:
    fza_variaciones_atributos  → atributos del tipo de variación (CO=Color,
      TAL=Talla)
    fza_atributos_conjuntos    → conjuntos disponibles (COLORES BÁSICOS,
                                                          TALLAS 42-46…)
    fza_articulos_conjuntos_asign → conjunto que cubre cada atributo del
      artículo
    fza_articulos_skus         → SKUs generados (activar/desactivar)
    vi_articulos_conjuntos_slots  → vista que lo une todo

  Layout de la pestaña:
    ┌─────────────────────────────────────────────────────┐
    │  Tipo de variación: [TC - TALLAS Y COLORES]         │
    ├──────────────────────────────────┬──────────────────┤
    │  Atributo   │ Conjunto asignado  │                  │
    │  Color      │ [COLORES BÁSICOS▼] │                  │
    │  Talla      │ [TALLAS 42-46   ▼] │                  │
    ├─────────────────────────────────────────────────────┤
    │  SKUs del artículo                                  │
    │  [✓] CAMI-BASICA/NEGRO/M                            │
    │  [✓] CAMI-BASICA/NEGRO/L                            │
    │  [ ] CAMI-BASICA/BLANCO/M  (desactivado)            │
    └─────────────────────────────────────────────────────┘
}

interface

uses
  Uni, inLibArticulosVariacionesIntf;

function CrearArticulosVariacionesUniDAC(
  AConexion: TUniConnection): IArticulosVariaciones;

implementation

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs, Vcl.ComCtrls,
  cxControls, cxContainer, cxEdit, cxTextEdit,
  cxLabel, cxDropDownEdit, cxButtons,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGrid, cxCheckBox,
  Data.DB, DBAccess, System.StrUtils, inLibMsgArticulos;

type
  { Un slot = un atributo del tipo de variación + el conjunto asignado }
  TSlotVariacion = record
    IdAtributo    : string;   // CO, TAL, TEMP…
    NombreAtributo: string;   // Color, Talla…
    OrdenAtributo : Integer;
    // Conjunto asignado actualmente
    IdConjunto    : Integer;  // 0 = sin asignar
    NombreConjunto: string;
    // Control visual
    Ctrl          : TcxComboBox;
    // Opciones disponibles para este atributo: ID → Nombre
    Opciones      : TDictionary<Integer, string>;
  end;

  TGestorVariacionesUniDAC = class(
    TInterfacedObject,
    IGestorArticulosVariaciones)
  private
    FConexion        : TUniConnection;
    FPanelAtributos  : TScrollBox;   // zona superior — combos de conjuntos
    FCodigoArticulo  : string;
    FTipoVariacion   : string;       // TC, TEMP…
    FNombreVariacion : string;
    FUsuario         : string;
    FSlotsVar        : TList<TSlotVariacion>;
    FModificado      : Boolean;

    procedure LimpiarTodo;
    procedure LimpiarAtributos;
    procedure CargarAtributos;
    procedure ReconstruirAtributos;
    procedure CrearFilaAtributo(var S: TSlotVariacion; ATop: Integer);

    procedure UpsertConjunto(const S: TSlotVariacion);
    procedure BorrarConjunto(const IdAtributo: string);
  public
    constructor Create(APanelAtributos: TScrollBox;
                       AConexion: TUniConnection;
                       const AUsuario: string);
    destructor Destroy; override;

    procedure CargarVariaciones(const CodigoArticulo: string);
    function  GuardarVariaciones: Boolean;
    function  Validar: string;
    function ObtenerCodigoArticulo: string;
    function EstaModificado: Boolean;
  end;
  TArticulosVariacionesUniDAC = class(
    TInterfacedObject,
    IArticulosVariaciones)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure AsegurarSkuSinVariaciones(
      const ACodigoArticulo, AUsuario: string);
    procedure AsegurarSkuActivo(
      const ACodigoArticulo, AUsuario: string);
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function CrearGestor(
      APanelAtributos: TScrollBox;
      const AUsuario: string): IGestorArticulosVariaciones;
  end;

const
  ALTO_FILA     = 26;
  MARGEN_V      = 6;
  MARGEN_H      = 8;
  ANCHO_LABEL   = 160;
  ANCHO_COMBO   = 280;

function ArticuloTieneSkuActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if ACodigoArticulo <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT 1 FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :codigo ' +
        '   AND ESACTIVO_SKU = ''S'' ' +
        ' LIMIT 1';
      Consulta.ParamByName('codigo').AsString := ACodigoArticulo;
      Consulta.Open;
      Result := not Consulta.IsEmpty;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure InsertarSkuBaseArticulo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'INSERT INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:sku, :art, ''-'', ''S'', ' +
      '        CURRENT_TIMESTAMP, :usuario, :usuario)';
    Consulta.ParamByName('sku').AsString := ACodigoArticulo;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure AsegurarSkuArticuloSinVariaciones(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
var
  Consulta: TUniQuery;
  bTieneVariaciones: Boolean;
  bTieneSku: Boolean;
begin
  if ACodigoArticulo <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT ESVARIACION_ART FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :codigo';
      Consulta.ParamByName('codigo').AsString := ACodigoArticulo;
      Consulta.Open;
      bTieneVariaciones := (not Consulta.IsEmpty) and
        (Consulta.FieldByName('ESVARIACION_ART').AsString = 'S');
      Consulta.Close;
      bTieneSku := False;
      if not bTieneVariaciones then
      begin
        Consulta.SQL.Text :=
          'SELECT 1 FROM fza_articulos_skus ' +
          ' WHERE CODIGO_ART_SKU = :codigo ' +
          ' LIMIT 1';
        Consulta.ParamByName('codigo').AsString := ACodigoArticulo;
        Consulta.Open;
        bTieneSku := not Consulta.IsEmpty;
      end;
    finally
      FreeAndNil(Consulta);
    end;
    if (not bTieneVariaciones) and (not bTieneSku) then
      InsertarSkuBaseArticulo(
        AConexion, ACodigoArticulo, AUsuario);
  end;
end;

procedure AsegurarSkuArticuloActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
var
  Consulta: TUniQuery;
  bExisteSkuBase: Boolean;
begin
  if (ACodigoArticulo <> '') and
     (not ArticuloTieneSkuActivo(AConexion, ACodigoArticulo)) then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT 1 FROM fza_articulos_skus ' +
        ' WHERE CODIGO_UNIDAD_SKU = :sku ' +
        ' LIMIT 1';
      Consulta.ParamByName('sku').AsString := ACodigoArticulo;
      Consulta.Open;
      bExisteSkuBase := not Consulta.IsEmpty;
      Consulta.Close;
      if bExisteSkuBase then
      begin
        Consulta.SQL.Text :=
          'UPDATE fza_articulos_skus ' +
          '   SET ESACTIVO_SKU = ''S'', ' +
          '       INSTANTE_MODIF = CURRENT_TIMESTAMP, ' +
          '       USUARIO_MODIF = :usuario ' +
          ' WHERE CODIGO_UNIDAD_SKU = :sku';
        Consulta.ParamByName('sku').AsString := ACodigoArticulo;
        Consulta.ParamByName('usuario').AsString := AUsuario;
        Consulta.ExecSQL;
      end
      else
        InsertarSkuBaseArticulo(
          AConexion, ACodigoArticulo, AUsuario);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Constructor / Destructor                                                   }
{ ══════════════════════════════════════════════════════════════════════════ }

constructor TGestorVariacionesUniDAC.Create(APanelAtributos: TScrollBox;
  AConexion: TUniConnection; const AUsuario: string);
begin
  inherited Create;
  FPanelAtributos := APanelAtributos;
  FConexion       := AConexion;
  FUsuario        := AUsuario;
  FSlotsVar       := TList<TSlotVariacion>.Create;
  FModificado     := False;

  FPanelAtributos.AutoScroll := True;
  FPanelAtributos.Color      := clWindow;
end;

destructor TGestorVariacionesUniDAC.Destroy;
begin
  LimpiarTodo;
  FreeAndNil(FSlotsVar);
  inherited;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Limpieza                                                                   }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariacionesUniDAC.LimpiarAtributos;
var i: Integer;
begin
  for i := 0 to FSlotsVar.Count - 1 do
    if Assigned(FSlotsVar[i].Opciones) then
      FreeAndNil(FSlotsVar[i].Opciones);
  FSlotsVar.Clear;
  while FPanelAtributos.ControlCount > 0 do
    FreeAndNil(FPanelAtributos.Controls[0]);
end;

procedure TGestorVariacionesUniDAC.LimpiarTodo;
begin
  LimpiarAtributos;
end;
{ ══════════════════════════════════════════════════════════════════════════ }
{ Carga principal                                                            }
{ ══════════════════════════════════════════════════════════════════════════ }
procedure TGestorVariacionesUniDAC.CargarVariaciones(
  const CodigoArticulo: string);
var
  q: TUniQuery;
begin
  FCodigoArticulo := CodigoArticulo;
  FTipoVariacion  := '';
  FNombreVariacion:= '';
  LimpiarTodo;
  FModificado := False;
  if CodigoArticulo <> '' then
  begin
    // Leer tipo de variación del artículo
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      q.SQL.Text   :=
        'SELECT a.TIPO_VARIACION_ART, v.NOMBRE_VAR ' +
        'FROM   fza_articulos a ' +
        'LEFT JOIN fza_variaciones v ON ' +
        'v.CODIGO_VAR = a.TIPO_VARIACION_ART ' +
        'WHERE  a.CODIGO_ART_ART = :cod ' +
        '  AND  a.ESVARIACION_ART = ''S''';
      q.ParamByName('cod').AsString := CodigoArticulo;
      q.Open;
      if not q.Eof then
      begin
        FTipoVariacion  := q.FieldByName(
          'TIPO_VARIACION_ART').AsString;
        FNombreVariacion:= q.FieldByName('NOMBRE_VAR').AsString;
      end;
    finally
      FreeAndNil(q);
    end;
    if FTipoVariacion = '' then
    begin
      // Artículo sin variaciones — mostrar mensaje
      with TcxLabel.Create(FPanelAtributos) do
      begin
        Parent  := FPanelAtributos;
        Left    := MARGEN_H;
        Top     := MARGEN_V;
        Caption := 'Este artículo no tiene variaciones activadas.';
        Transparent := True;
      end;
    end
    else
    begin
      CargarAtributos;
      ReconstruirAtributos;
    end;
  end;
end;
{ ══════════════════════════════════════════════════════════════════════════ }
{ Carga atributos + conjuntos disponibles                                    }
{ ══════════════════════════════════════════════════════════════════════════ }
procedure TGestorVariacionesUniDAC.CargarAtributos;
var
  qSlots : TUniQuery;
  qOpc   : TUniQuery;
  S      : TSlotVariacion;
  i      : Integer;
begin
  // ── 1. Atributos de la variación + conjunto asignado al artículo ────────
  qSlots := TUniQuery.Create(nil);
  try
    qSlots.Connection := FConexion;
    qSlots.SQL.Text   :=
      'SELECT va.ID_ATB_VA, ' +
      '       COALESCE(va.NOMBRE_VA, va.ID_ATB_VA) AS NOMBRE_ATRIBUTO, ' +
      '       va.ORDEN_VA, ' +
      '       aca.ID_AC_ACA, ' +
      '       ac.NOMBRE_AC ' +
      'FROM   fza_variaciones_atributos va ' +
      'LEFT JOIN fza_articulos_conjuntos_asign aca ' +
      '       ON aca.CODIGO_ART_ACA = :art ' +
      '      AND aca.ID_VA_ACA     = va.ID_ATB_VA ' +
      'LEFT JOIN fza_atributos_conjuntos ac ' +
      '       ON ac.ID_AC = aca.ID_AC_ACA ' +
      'WHERE  va.ID_VAR_VA = :var ' +
      'ORDER  BY va.ORDEN_VA';
    qSlots.ParamByName('art').AsString := FCodigoArticulo;
    qSlots.ParamByName('var').AsString := FTipoVariacion;
    qSlots.Open;
    while not qSlots.Eof do
    begin
      S := Default(TSlotVariacion);
      S.IdAtributo     := qSlots.FieldByName('ID_ATB_VA').AsString;
      S.NombreAtributo := qSlots.FieldByName('NOMBRE_ATRIBUTO').AsString;
      S.OrdenAtributo  := qSlots.FieldByName('ORDEN_VA').AsInteger;
      S.IdConjunto     := qSlots.FieldByName('ID_AC_ACA').AsInteger;
      S.NombreConjunto := qSlots.FieldByName('NOMBRE_AC').AsString;
      S.Ctrl           := nil;
      S.Opciones       := nil;
      FSlotsVar.Add(S);
      qSlots.Next;
    end;
    finally
      FreeAndNil(qSlots);
  end;
  // ── 2. Cargar opciones de conjuntos disponibles para cada atributo ──────
  qOpc := TUniQuery.Create(nil);
  try
    qOpc.Connection := FConexion;
    qOpc.SQL.Text   :=
      'SELECT ID_AC, NOMBRE_AC ' +
      'FROM   fza_atributos_conjuntos ' +
      'WHERE  ID_VA_AC = :atr ' +
      '  AND  ESACTIVO_AC    = ''S'' ' +
      'ORDER  BY NOMBRE_AC';
  for i := 0 to FSlotsVar.Count - 1 do
    begin
      S := FSlotsVar[i];
      S.Opciones := TDictionary<Integer, string>.Create;
      qOpc.Close;
      qOpc.ParamByName('atr').AsString := S.IdAtributo;
      qOpc.Open;
      while not qOpc.Eof do
      begin
        S.Opciones.Add(
          qOpc.FieldByName('ID_AC').AsInteger,
          qOpc.FieldByName('NOMBRE_AC').AsString);
        qOpc.Next;
      end;
      FSlotsVar[i] := S;
    end;
  finally
    FreeAndNil(qOpc);
  end;
end;
{ ══════════════════════════════════════════════════════════════════════════ }
{ Construcción visual — zona atributos                                       }
{ ══════════════════════════════════════════════════════════════════════════ }
procedure TGestorVariacionesUniDAC.ReconstruirAtributos;
var
  i   : Integer;
  Top : Integer;
  S   : TSlotVariacion;
  lbl : TcxLabel;
begin
  FPanelAtributos.DisableAlign;
  try
    while FPanelAtributos.ControlCount > 0 do
      FreeAndNil(FPanelAtributos.Controls[0]);
    for i := 0 to FSlotsVar.Count - 1 do
    begin
      S := FSlotsVar[i];
      S.Ctrl := nil;
      FSlotsVar[i] := S;
    end;
  finally
    FPanelAtributos.EnableAlign;
  end;
  // Cabecera con tipo de variación
  lbl := TcxLabel.Create(FPanelAtributos);
  lbl.Parent  := FPanelAtributos;
  lbl.Left    := MARGEN_H;
  lbl.Top     := MARGEN_V;
  lbl.Caption := Format(SCaptionTipoVariacionDetalle,
                        [FTipoVariacion, FNombreVariacion]);
  lbl.Style.Font.Style := [fsBold];
  lbl.Transparent := True;
  //lbl.AutoSize := True;
  Top := MARGEN_V + ALTO_FILA + MARGEN_V;

  for i := 0 to FSlotsVar.Count - 1 do
  begin
    S := FSlotsVar[i];
    CrearFilaAtributo(S, Top);
    FSlotsVar[i] := S;
    Inc(Top, ALTO_FILA + MARGEN_V);
  end;
end;

procedure TGestorVariacionesUniDAC.CrearFilaAtributo(
  var S: TSlotVariacion;
  ATop: Integer);
var
  lbl : TcxLabel;
  cb  : TcxComboBox;
  IdV : Integer;
  Txt : string;
  Idx : Integer;
begin
  lbl := TcxLabel.Create(FPanelAtributos);
  lbl.Parent   := FPanelAtributos;
  lbl.Left     := MARGEN_H;
  lbl.Top      := ATop + 4;
  lbl.Width    := ANCHO_LABEL;
  lbl.Height   := ALTO_FILA;
//  lbl.AutoSize := False;
  lbl.Caption  := S.NombreAtributo;
  lbl.Transparent := True;
  cb := TcxComboBox.Create(FPanelAtributos);
  cb.Parent  := FPanelAtributos;
  cb.Left    := MARGEN_H + ANCHO_LABEL + 6;
  cb.Top     := ATop;
  cb.Width   := ANCHO_COMBO;
  cb.Height  := ALTO_FILA;
  cb.Properties.DropDownListStyle := lsFixedList;
  cb.Properties.Items.AddObject('— Sin conjunto —', TObject(0));
  if Assigned(S.Opciones) then
    for IdV in S.Opciones.Keys do
    begin
      Txt := S.Opciones[IdV];
      cb.Properties.Items.AddObject(Txt, TObject(IdV));
    end;
  cb.ItemIndex := 0;
  if S.IdConjunto > 0 then
    for Idx := 1 to cb.Properties.Items.Count - 1 do
      // CORRECTO: Uso de NativeInt para compatibilidad con punteros a 32/64
      // bits
      if Integer(NativeInt(
        cb.Properties.Items.Objects[Idx])) = S.IdConjunto then
      begin
        cb.ItemIndex := Idx;
        Break;
      end;
  S.Ctrl := cb;
end;

function TGestorVariacionesUniDAC.Validar: string;
begin
  Result := '';
end;

function TGestorVariacionesUniDAC.GuardarVariaciones: Boolean;
var
  i      : Integer;
  S      : TSlotVariacion;
  NuevoId: Integer;
begin
  for i := 0 to FSlotsVar.Count - 1 do
  begin
    S := FSlotsVar[i];
    if Assigned(S.Ctrl) then
    begin
      NuevoId := Integer(NativeInt(S.Ctrl.Properties.Items.Objects[
        S.Ctrl.ItemIndex]));
      if NuevoId <> S.IdConjunto then
      begin
        BorrarConjunto(S.IdAtributo);
        if NuevoId > 0 then
          UpsertConjunto(S);
        S.IdConjunto := NuevoId;
        FSlotsVar[i] := S;
      end;
    end;
  end;
  FModificado := False;
  Result := True;
end;

procedure TGestorVariacionesUniDAC.UpsertConjunto(
  const S: TSlotVariacion);
var
  q      : TUniQuery;
  NuevoId: Integer;
begin
  if Assigned(S.Ctrl) then
  begin
    NuevoId := Integer(
      S.Ctrl.Properties.Items.Objects[S.Ctrl.ItemIndex]);
    if NuevoId <> 0 then
    begin
      // Guardar la asignación del conjunto para el atributo.
      q := TUniQuery.Create(nil);
      try
        q.Connection := FConexion;
        q.SQL.Text   :=
          'INSERT INTO fza_articulos_conjuntos_asign ' +
          '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ' +
          '   ESGENERACION_AUTO_ACA, INSTANTE_ALTA, ' +
          'USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES ' +
          '  (:art, :conj, :atr, ''S'', NOW(), :usr, :usr) ' +
          'ON DUPLICATE KEY UPDATE ' +
          '  ID_AC_ACA    = VALUES(ID_AC_ACA), ' +
          '  ESGENERACION_AUTO_ACA = ''S'', ' +
          '  USUARIO_MODIF       = VALUES(USUARIO_MODIF)';
        q.ParamByName('art').AsString  := FCodigoArticulo;
        q.ParamByName('conj').AsInteger:= NuevoId;
        q.ParamByName('atr').AsString  := S.IdAtributo;
        q.ParamByName('usr').AsString  := FUsuario;
        q.Execute;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

procedure TGestorVariacionesUniDAC.BorrarConjunto(
  const IdAtributo: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'DELETE FROM fza_articulos_conjuntos_asign ' +
      'WHERE CODIGO_ART_ACA = :art ' +
      '  AND ID_VA_ACA     = :atr';
    q.ParamByName('art').AsString := FCodigoArticulo;
    q.ParamByName('atr').AsString := IdAtributo;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

function TGestorVariacionesUniDAC.ObtenerCodigoArticulo: string;
begin
  Result := FCodigoArticulo;
end;

function TGestorVariacionesUniDAC.EstaModificado: Boolean;
begin
  Result := FModificado;
end;

constructor TArticulosVariacionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

procedure TArticulosVariacionesUniDAC.AsegurarSkuSinVariaciones(
  const ACodigoArticulo, AUsuario: string);
begin
  AsegurarSkuArticuloSinVariaciones(
    FConexion, ACodigoArticulo, AUsuario);
end;

procedure TArticulosVariacionesUniDAC.AsegurarSkuActivo(
  const ACodigoArticulo, AUsuario: string);
begin
  AsegurarSkuArticuloActivo(
    FConexion, ACodigoArticulo, AUsuario);
end;

function TArticulosVariacionesUniDAC.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := ArticuloTieneSkuActivo(FConexion, ACodigoArticulo);
end;

function TArticulosVariacionesUniDAC.CrearGestor(
  APanelAtributos: TScrollBox;
  const AUsuario: string): IGestorArticulosVariaciones;
begin
  Result := TGestorVariacionesUniDAC.Create(
    APanelAtributos, FConexion, AUsuario);
end;

function CrearArticulosVariacionesUniDAC(
  AConexion: TUniConnection): IArticulosVariaciones;
begin
  Result := TArticulosVariacionesUniDAC.Create(AConexion);
end;

end.
