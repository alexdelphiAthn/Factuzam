{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosVariaciones                                     }
{    Tipo:       Librería                                                      }
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
unit inLibArticulosVariaciones;

{
  Unidad: inLibArticulosVariaciones
  Descripción: Gestión dinámica de variaciones en la pestaña tsVariaciones
               del formulario TfrmMtoArticulos de Factuzam.

  Modelo de datos:
    fza_variaciones_atributos  → atributos del tipo de variación (CO=Color, TAL=Talla)
    fza_atributos_conjuntos    → conjuntos disponibles (COLORES BÁSICOS, TALLAS 42-46…)
    fza_articulos_conjuntos_asign → qué conjunto cubre cada atributo del artículo
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
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Dialogs, Vcl.ComCtrls,
  cxControls, cxContainer, cxEdit, cxTextEdit,
  cxLabel, cxDropDownEdit, cxButtons,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGrid, cxCheckBox,
  DBAccess, Uni;

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

  { Un SKU del artículo }
  TSlotSku = record
    CodigoUnidad : string;
    Activo       : Boolean;
    ActiveOriginal: Boolean;  // para detectar cambios
    // Control visual
    Chk          : TcxCheckBox;
  end;

  TGestorVariaciones = class
  private
    FConexion        : TUniConnection;
    FPanelAtributos  : TScrollBox;   // zona superior — combos de conjuntos
    FPanelSkus       : TScrollBox;   // zona inferior — checkboxes de SKUs
    FCodigoArticulo  : string;
    FTipoVariacion   : string;       // TC, TEMP…
    FNombreVariacion : string;
    FUsuario         : string;
    FSlotsVar        : TList<TSlotVariacion>;
    FSlotsSkus       : TList<TSlotSku>;
    FLblTipoVar      : TcxLabel;
    FModificado      : Boolean;

    procedure LimpiarTodo;
    procedure LimpiarAtributos;
    procedure LimpiarSkus;
    procedure CargarAtributos;
    procedure CargarSkus;
    procedure ReconstruirAtributos;
    procedure ReconstruirSkus;
    procedure CrearFilaAtributo(var S: TSlotVariacion; ATop: Integer);

    procedure UpsertConjunto(const S: TSlotVariacion);
    procedure BorrarConjunto(const IdAtributo: string);
    procedure ActualizarSku(const CodigoUnidad: string; Activo: Boolean);
  public
    constructor Create(APanelAtributos: TScrollBox;
                       AConexion: TUniConnection;
                       const AUsuario: string);
    destructor Destroy; override;

    procedure CargarVariaciones(const CodigoArticulo: string);
    function  GuardarVariaciones: Boolean;
    function  Validar: string;

    property CodigoArticulo: string  read FCodigoArticulo;
    property Modificado    : Boolean read FModificado;
  end;

implementation

uses
  System.StrUtils;

const
  ALTO_FILA     = 26;
  MARGEN_V      = 6;
  MARGEN_H      = 8;
  ANCHO_LABEL   = 160;
  ANCHO_COMBO   = 280;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Constructor / Destructor                                                   }
{ ══════════════════════════════════════════════════════════════════════════ }

constructor TGestorVariaciones.Create(APanelAtributos: TScrollBox;
  AConexion: TUniConnection; const AUsuario: string);
begin
  inherited Create;
  FPanelAtributos := APanelAtributos;
//  FPanelSkus      := APanelSkus;
  FConexion       := AConexion;
  FUsuario        := AUsuario;
  FSlotsVar       := TList<TSlotVariacion>.Create;
//  FSlotsSkus      := TList<TSlotSku>.Create;
  FModificado     := False;

  FPanelAtributos.AutoScroll := True;
  FPanelAtributos.Color      := clWindow;
//  FPanelSkus.AutoScroll      := True;
//  FPanelSkus.Color           := clWindow;
end;

destructor TGestorVariaciones.Destroy;
begin
  LimpiarTodo;
  FSlotsVar.Free;
//  FSlotsSkus.Free;
  inherited;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Limpieza                                                                   }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.LimpiarAtributos;
var i: Integer;
begin
  for i := 0 to FSlotsVar.Count - 1 do
    if Assigned(FSlotsVar[i].Opciones) then
      FSlotsVar[i].Opciones.Free;
  FSlotsVar.Clear;
  while FPanelAtributos.ControlCount > 0 do
    FPanelAtributos.Controls[0].Free;
end;

procedure TGestorVariaciones.LimpiarSkus;
begin
//  FSlotsSkus.Clear;
//  while FPanelSkus.ControlCount > 0 do
//    FPanelSkus.Controls[0].Free;
end;

procedure TGestorVariaciones.LimpiarTodo;
begin
  LimpiarAtributos;
//  LimpiarSkus;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Carga principal                                                            }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.CargarVariaciones(const CodigoArticulo: string);
var
  q: TUniQuery;
begin
  FCodigoArticulo := CodigoArticulo;
  FTipoVariacion  := '';
  FNombreVariacion:= '';
  LimpiarTodo;
  FModificado := False;

  if CodigoArticulo = '' then Exit;

  // Leer tipo de variación del artículo
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'SELECT a.TIPO_VARIACION_ART, v.NOMBRE_VAR ' +
      'FROM   fza_articulos a ' +
      'LEFT JOIN fza_variaciones v ON v.CODIGO_VAR = a.TIPO_VARIACION_ART ' +
      'WHERE  a.CODIGO_ART_ART = :cod ' +
      '  AND  a.ESVARIACION_ART = ''S''';
    q.ParamByName('cod').AsString := CodigoArticulo;
    q.Open;
    if not q.Eof then
    begin
      FTipoVariacion  := q.FieldByName('TIPO_VARIACION_ART').AsString;
      FNombreVariacion:= q.FieldByName('NOMBRE_VAR').AsString;
    end;
  finally
    q.Free;
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
    end;
    Exit;
  end;

  CargarAtributos;
//  CargarSkus;
  ReconstruirAtributos;
//  ReconstruirSkus;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Carga atributos + conjuntos disponibles                                    }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.CargarAtributos;
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
      qSlots.Free;
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
    qOpc.Free;
  end;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Carga SKUs                                                                 }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.CargarSkus;
var
  q  : TUniQuery;
  SK : TSlotSku;
begin
//  q := TUniQuery.Create(nil);
//  try
//    q.Connection := FConexion;
//    q.SQL.Text   :=
//      'SELECT sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU, ' +
//      '       GROUP_CONCAT(av.AV ORDER BY va.ORDEN_VA SEPARATOR '' / '') AS DESCRIPCION_SKU ' +
//      'FROM   fza_articulos_skus sk ' +
//      'LEFT JOIN fza_atributos_sku asku ON asku.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
//      'LEFT JOIN fza_atributos_valores av ON av.ID_AV = asku.ID_AV_SA ' +
//      'LEFT JOIN fza_variaciones_atributos va ON va.ID_ATB_VA = av.ID_VA_AV ' +
//      '                                      AND va.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
//      'WHERE  sk.CODIGO_ART_SKU = :art ' +
//      'GROUP  BY sk.CODIGO_UNIDAD_SKU, sk.ESACTIVO_SKU ' +
//      'ORDER  BY sk.CODIGO_UNIDAD_SKU';
//    q.ParamByName('art').AsString := FCodigoArticulo;
//    q.Open;
//
//    while not q.Eof do
//    begin
//      FillChar(SK, SizeOf(SK), 0);
//      SK.CodigoUnidad  := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
//      SK.Activo        := q.FieldByName('ESACTIVO_SKU').AsString = 'S';
//      SK.ActiveOriginal:= SK.Activo;
//      // Usar la descripción legible si la hay, si no el código
//      if q.FieldByName('DESCRIPCION_SKU').AsString <> '' then
//        SK.CodigoUnidad := q.FieldByName('DESCRIPCION_SKU').AsString +
//                           '  (' + q.FieldByName('CODIGO_UNIDAD_SKU').AsString + ')'
//      else
//        SK.CodigoUnidad := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
//      SK.Chk := nil;
//      FSlotsSkus.Add(SK);
//      q.Next;
//    end;
//  finally
//    q.Free;
//  end;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Construcción visual — zona atributos                                       }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.ReconstruirAtributos;
var
  i   : Integer;
  Top : Integer;
  S   : TSlotVariacion;
  lbl : TcxLabel;
begin
  FPanelAtributos.DisableAlign;
  try
    while FPanelAtributos.ControlCount > 0 do
      FPanelAtributos.Controls[0].Free;
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
  lbl.Caption := 'Tipo de variación: ' + FTipoVariacion + ' — ' +
                                                               FNombreVariacion;
  lbl.Style.Font.Style := [fsBold];
  lbl.AutoSize := True;

  Top := MARGEN_V + ALTO_FILA + MARGEN_V;

  for i := 0 to FSlotsVar.Count - 1 do
  begin
    S := FSlotsVar[i];
    CrearFilaAtributo(S, Top);
    FSlotsVar[i] := S;
    Inc(Top, ALTO_FILA + MARGEN_V);
  end;
end;

procedure TGestorVariaciones.CrearFilaAtributo(var S: TSlotVariacion;
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
  lbl.AutoSize := False;
  lbl.Caption  := S.NombreAtributo;
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
      // CORRECTO: Uso de NativeInt para compatibilidad con punteros a 32/64 bits
      if Integer(NativeInt(cb.Properties.Items.Objects[Idx])) = S.IdConjunto then
      begin
        cb.ItemIndex := Idx;
        Break;
      end;
  S.Ctrl := cb;
end;

{ ══════════════════════════════════════════════════════════════════════════ }
{ Construcción visual — zona SKUs                                            }
{ ══════════════════════════════════════════════════════════════════════════ }

procedure TGestorVariaciones.ReconstruirSkus;
var
  i   : Integer;
  Top : Integer;
  SK  : TSlotSku;
  lbl : TcxLabel;
  chk : TcxCheckBox;
begin
//  FPanelSkus.DisableAlign;
//  try
//    while FPanelSkus.ControlCount > 0 do
//      FPanelSkus.Controls[0].Free;
//    for i := 0 to FSlotsSkus.Count - 1 do
//    begin
//      SK := FSlotsSkus[i];
//      SK.Chk := nil;
//      FSlotsSkus[i] := SK;
//    end;
//  finally
//    FPanelSkus.EnableAlign;
//  end;
//
//  if FSlotsSkus.Count = 0 then
//  begin
//    lbl := TcxLabel.Create(FPanelSkus);
//    lbl.Parent  := FPanelSkus;
//    lbl.Left    := MARGEN_H;
//    lbl.Top     := MARGEN_V;
//    lbl.Caption := 'No hay SKUs generados para este artículo.';
//    Exit;
//  end;
//
//  // Cabecera
//  lbl := TcxLabel.Create(FPanelSkus);
//  lbl.Parent  := FPanelSkus;
//  lbl.Left    := MARGEN_H;
//  lbl.Top     := MARGEN_V;
//  lbl.Caption := 'SKUs  (' + IntToStr(FSlotsSkus.Count) + ' combinaciones)';
//  lbl.Style.Font.Style := [fsBold];
//  lbl.AutoSize := True;
//
//  Top := MARGEN_V + ALTO_FILA + MARGEN_V;
//
//  for i := 0 to FSlotsSkus.Count - 1 do
//  begin
//    SK := FSlotsSkus[i];
//
//    chk := TcxCheckBox.Create(FPanelSkus);
//    chk.Parent   := FPanelSkus;
//    chk.Left     := MARGEN_H;
//    chk.Top      := Top;
//    chk.Width    := FPanelSkus.ClientWidth - MARGEN_H * 2;
//    chk.Height   := ALTO_FILA;
//    chk.Caption  := SK.CodigoUnidad;
//    chk.Checked  := SK.Activo;
//    chk.Tag      := i;
//
//    // Colorear los desactivados en gris
//    if not SK.Activo then
//      chk.Style.TextColor := clGray;
//
//    SK.Chk := chk;
//    FSlotsSkus[i] := SK;
//    Inc(Top, ALTO_FILA + 2);
//  end;
end;

function TGestorVariaciones.Validar: string;
begin
  Result := '';
end;

function TGestorVariaciones.GuardarVariaciones: Boolean;
var
  i      : Integer;
  S      : TSlotVariacion;
  NuevoId: Integer;
begin
  Result := False;
  for i := 0 to FSlotsVar.Count - 1 do
  begin
    S := FSlotsVar[i];
    if not Assigned(S.Ctrl) then Continue;
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
  FModificado := False;
  Result := True;
end;

procedure TGestorVariaciones.UpsertConjunto(const S: TSlotVariacion);
var
  q      : TUniQuery;
  NuevoId: Integer;
begin
  if not Assigned(S.Ctrl) then Exit;
  NuevoId := Integer(S.Ctrl.Properties.Items.Objects[S.Ctrl.ItemIndex]);
  if NuevoId = 0 then Exit;

  // Leer ID_VARIACION del conjunto para rellenar el campo
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text   :=
      'INSERT INTO fza_articulos_conjuntos_asign ' +
      '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ' +
      '   ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
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
    q.Free;
  end;
end;

procedure TGestorVariaciones.BorrarConjunto(const IdAtributo: string);
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
    q.Free;
  end;
end;

procedure TGestorVariaciones.ActualizarSku(const CodigoUnidad: string;
  Activo: Boolean);
var
  q: TUniQuery;
begin
//  q := TUniQuery.Create(nil);
//  try
//    q.Connection := FConexion;
//    q.SQL.Text   :=
//      'UPDATE fza_articulos_skus ' +
//      'SET    ESACTIVO_SKU  = :act, ' +
//      '       USUARIO_MODIF  = :usr ' +
//      'WHERE  CODIGO_UNIDAD_SKU = :cod';
//    q.ParamByName('act').AsString := IfThen(Activo, 'S', 'N');
//    q.ParamByName('usr').AsString := FUsuario;
//    q.ParamByName('cod').AsString := CodigoUnidad;
//    q.Execute;
//  finally
//    q.Free;
//  end;
end;

end.
