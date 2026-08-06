{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosVariacionesGestor                            }
{    Tipo:       Adaptador VCL y UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Edición visual de los conjuntos de atributos de un artículo.             }
{******************************************************************************}
unit UniDataArticulosVariacionesGestor;

interface

uses
  Vcl.Forms,
  Uni,
  inLibArticulosVariacionesIntf;

function CrearGestorArticulosVariacionesUniDAC(
  APanelAtributos: TScrollBox;
  AConexion: TUniConnection;
  const AUsuario: string): IGestorArticulosVariaciones;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Graphics,
  cxLabel,
  cxDropDownEdit,
  DBAccess,
  inLibMsgArticulos;

const
  ALTO_FILA = 26;
  MARGEN_V = 6;
  MARGEN_H = 8;
  ANCHO_LABEL = 160;
  ANCHO_COMBO = 280;

type
  TSlotVariacionUniDAC = record
    IdAtributo: string;
    NombreAtributo: string;
    OrdenAtributo: Integer;
    IdConjunto: Integer;
    NombreConjunto: string;
    Control: TcxComboBox;
    Opciones: TDictionary<Integer, string>;
  end;
  TGestorArticulosVariacionesUniDAC = class(
    TInterfacedObject,
    IGestorArticulosVariaciones)
  private
    FConexion: TUniConnection;
    FPanelAtributos: TScrollBox;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FNombreVariacion: string;
    FUsuario: string;
    FSlots: TList<TSlotVariacionUniDAC>;
    FModificado: Boolean;
    procedure LimpiarAtributos;
    procedure CargarAtributos;
    procedure ReconstruirAtributos;
    procedure CrearFilaAtributo(
      var ASlot: TSlotVariacionUniDAC;
      ATop: Integer);
    procedure UpsertConjunto(
      const ASlot: TSlotVariacionUniDAC);
    procedure BorrarConjunto(
      const AIdAtributo: string);
  public
    constructor Create(
      APanelAtributos: TScrollBox;
      AConexion: TUniConnection;
      const AUsuario: string);
    destructor Destroy; override;
    procedure CargarVariaciones(
      const ACodigoArticulo: string);
    function GuardarVariaciones: Boolean;
    function Validar: string;
    function ObtenerCodigoArticulo: string;
    function EstaModificado: Boolean;
  end;

constructor TGestorArticulosVariacionesUniDAC.Create(
  APanelAtributos: TScrollBox;
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  inherited Create;
  FPanelAtributos := APanelAtributos;
  FConexion := AConexion;
  FUsuario := AUsuario;
  FSlots := TList<TSlotVariacionUniDAC>.Create;
  FModificado := False;
  FPanelAtributos.AutoScroll := True;
  FPanelAtributos.Color := clWindow;
end;

destructor TGestorArticulosVariacionesUniDAC.Destroy;
begin
  LimpiarAtributos;
  FSlots.Free;
  inherited;
end;

procedure TGestorArticulosVariacionesUniDAC.LimpiarAtributos;
var
  Indice: Integer;
begin
  for Indice := 0 to FSlots.Count - 1 do
    if Assigned(FSlots[Indice].Opciones) then
      FSlots[Indice].Opciones.Free;
  FSlots.Clear;
  while FPanelAtributos.ControlCount > 0 do
    FPanelAtributos.Controls[0].Free;
end;

procedure TGestorArticulosVariacionesUniDAC.CargarVariaciones(
  const ACodigoArticulo: string);
var
  Consulta: TUniQuery;
  Etiqueta: TcxLabel;
begin
  FCodigoArticulo := ACodigoArticulo;
  FTipoVariacion := '';
  FNombreVariacion := '';
  LimpiarAtributos;
  FModificado := False;
  if ACodigoArticulo <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text :=
        'SELECT a.TIPO_VARIACION_ART, v.NOMBRE_VAR ' +
        'FROM fza_articulos a ' +
        'LEFT JOIN fza_variaciones v ON ' +
        '  v.CODIGO_VAR = a.TIPO_VARIACION_ART ' +
        'WHERE a.CODIGO_ART_ART = :codigo ' +
        '  AND a.ESVARIACION_ART = ''S''';
      Consulta.ParamByName('codigo').AsString := ACodigoArticulo;
      Consulta.Open;
      if not Consulta.Eof then
      begin
        FTipoVariacion := Consulta.FieldByName(
          'TIPO_VARIACION_ART').AsString;
        FNombreVariacion := Consulta.FieldByName(
          'NOMBRE_VAR').AsString;
      end;
    finally
      Consulta.Free;
    end;
    if FTipoVariacion = '' then
    begin
      Etiqueta := TcxLabel.Create(FPanelAtributos);
      Etiqueta.Parent := FPanelAtributos;
      Etiqueta.Left := MARGEN_H;
      Etiqueta.Top := MARGEN_V;
      Etiqueta.Caption :=
        'Este artículo no tiene variaciones activadas.';
      Etiqueta.Transparent := True;
    end
    else
    begin
      CargarAtributos;
      ReconstruirAtributos;
    end;
  end;
end;

procedure TGestorArticulosVariacionesUniDAC.CargarAtributos;
var
  ConsultaSlots: TUniQuery;
  ConsultaOpciones: TUniQuery;
  Slot: TSlotVariacionUniDAC;
  Indice: Integer;
begin
  ConsultaSlots := TUniQuery.Create(nil);
  try
    ConsultaSlots.Connection := FConexion;
    ConsultaSlots.SQL.Text :=
      'SELECT va.ID_ATB_VA, ' +
      '  COALESCE(va.NOMBRE_VA, va.ID_ATB_VA) NOMBRE_ATRIBUTO, ' +
      '  va.ORDEN_VA, aca.ID_AC_ACA, ac.NOMBRE_AC ' +
      'FROM fza_variaciones_atributos va ' +
      'LEFT JOIN fza_articulos_conjuntos_asign aca ' +
      '  ON aca.CODIGO_ART_ACA = :articulo ' +
      ' AND aca.ID_VA_ACA = va.ID_ATB_VA ' +
      'LEFT JOIN fza_atributos_conjuntos ac ' +
      '  ON ac.ID_AC = aca.ID_AC_ACA ' +
      'WHERE va.ID_VAR_VA = :variacion ' +
      'ORDER BY va.ORDEN_VA';
    ConsultaSlots.ParamByName('articulo').AsString :=
      FCodigoArticulo;
    ConsultaSlots.ParamByName('variacion').AsString :=
      FTipoVariacion;
    ConsultaSlots.Open;
    while not ConsultaSlots.Eof do
    begin
      Slot := Default(TSlotVariacionUniDAC);
      Slot.IdAtributo := ConsultaSlots.FieldByName(
        'ID_ATB_VA').AsString;
      Slot.NombreAtributo := ConsultaSlots.FieldByName(
        'NOMBRE_ATRIBUTO').AsString;
      Slot.OrdenAtributo := ConsultaSlots.FieldByName(
        'ORDEN_VA').AsInteger;
      Slot.IdConjunto := ConsultaSlots.FieldByName(
        'ID_AC_ACA').AsInteger;
      Slot.NombreConjunto := ConsultaSlots.FieldByName(
        'NOMBRE_AC').AsString;
      FSlots.Add(Slot);
      ConsultaSlots.Next;
    end;
  finally
    ConsultaSlots.Free;
  end;
  ConsultaOpciones := TUniQuery.Create(nil);
  try
    ConsultaOpciones.Connection := FConexion;
    ConsultaOpciones.SQL.Text :=
      'SELECT ID_AC, NOMBRE_AC ' +
      'FROM fza_atributos_conjuntos ' +
      'WHERE ID_VA_AC = :atributo ' +
      '  AND ESACTIVO_AC = ''S'' ' +
      'ORDER BY NOMBRE_AC';
    for Indice := 0 to FSlots.Count - 1 do
    begin
      Slot := FSlots[Indice];
      Slot.Opciones := TDictionary<Integer, string>.Create;
      ConsultaOpciones.Close;
      ConsultaOpciones.ParamByName('atributo').AsString :=
        Slot.IdAtributo;
      ConsultaOpciones.Open;
      while not ConsultaOpciones.Eof do
      begin
        Slot.Opciones.Add(
          ConsultaOpciones.FieldByName('ID_AC').AsInteger,
          ConsultaOpciones.FieldByName('NOMBRE_AC').AsString);
        ConsultaOpciones.Next;
      end;
      FSlots[Indice] := Slot;
    end;
  finally
    ConsultaOpciones.Free;
  end;
end;

procedure TGestorArticulosVariacionesUniDAC.ReconstruirAtributos;
var
  Indice: Integer;
  PosicionSuperior: Integer;
  Slot: TSlotVariacionUniDAC;
  Etiqueta: TcxLabel;
begin
  FPanelAtributos.DisableAlign;
  try
    while FPanelAtributos.ControlCount > 0 do
      FPanelAtributos.Controls[0].Free;
    for Indice := 0 to FSlots.Count - 1 do
    begin
      Slot := FSlots[Indice];
      Slot.Control := nil;
      FSlots[Indice] := Slot;
    end;
  finally
    FPanelAtributos.EnableAlign;
  end;
  Etiqueta := TcxLabel.Create(FPanelAtributos);
  Etiqueta.Parent := FPanelAtributos;
  Etiqueta.Left := MARGEN_H;
  Etiqueta.Top := MARGEN_V;
  Etiqueta.Caption := Format(
    SCaptionTipoVariacionDetalle,
    [FTipoVariacion, FNombreVariacion]);
  Etiqueta.Style.Font.Style := [fsBold];
  Etiqueta.Transparent := True;
  PosicionSuperior := MARGEN_V + ALTO_FILA + MARGEN_V;
  for Indice := 0 to FSlots.Count - 1 do
  begin
    Slot := FSlots[Indice];
    CrearFilaAtributo(Slot, PosicionSuperior);
    FSlots[Indice] := Slot;
    Inc(PosicionSuperior, ALTO_FILA + MARGEN_V);
  end;
end;

procedure TGestorArticulosVariacionesUniDAC.CrearFilaAtributo(
  var ASlot: TSlotVariacionUniDAC;
  ATop: Integer);
var
  Etiqueta: TcxLabel;
  Combo: TcxComboBox;
  IdConjunto: Integer;
  Indice: Integer;
begin
  Etiqueta := TcxLabel.Create(FPanelAtributos);
  Etiqueta.Parent := FPanelAtributos;
  Etiqueta.Left := MARGEN_H;
  Etiqueta.Top := ATop + 4;
  Etiqueta.Width := ANCHO_LABEL;
  Etiqueta.Height := ALTO_FILA;
  Etiqueta.Caption := ASlot.NombreAtributo;
  Etiqueta.Transparent := True;
  Combo := TcxComboBox.Create(FPanelAtributos);
  Combo.Parent := FPanelAtributos;
  Combo.Left := MARGEN_H + ANCHO_LABEL + 6;
  Combo.Top := ATop;
  Combo.Width := ANCHO_COMBO;
  Combo.Height := ALTO_FILA;
  Combo.Properties.DropDownListStyle := lsFixedList;
  Combo.Properties.Items.AddObject(
    '— Sin conjunto —', TObject(0));
  if Assigned(ASlot.Opciones) then
    for IdConjunto in ASlot.Opciones.Keys do
      Combo.Properties.Items.AddObject(
        ASlot.Opciones[IdConjunto],
        TObject(NativeInt(IdConjunto)));
  Combo.ItemIndex := 0;
  Indice := 1;
  while (Indice < Combo.Properties.Items.Count) and
        (Combo.ItemIndex = 0) do
  begin
    IdConjunto := Integer(NativeInt(
      Combo.Properties.Items.Objects[Indice]));
    if IdConjunto = ASlot.IdConjunto then
      Combo.ItemIndex := Indice;
    Inc(Indice);
  end;
  ASlot.Control := Combo;
end;

function TGestorArticulosVariacionesUniDAC.Validar: string;
begin
  Result := '';
end;

function TGestorArticulosVariacionesUniDAC.GuardarVariaciones:
  Boolean;
var
  Indice: Integer;
  Slot: TSlotVariacionUniDAC;
  NuevoId: Integer;
begin
  for Indice := 0 to FSlots.Count - 1 do
  begin
    Slot := FSlots[Indice];
    if Assigned(Slot.Control) then
    begin
      NuevoId := Integer(NativeInt(
        Slot.Control.Properties.Items.Objects[
          Slot.Control.ItemIndex]));
      if NuevoId <> Slot.IdConjunto then
      begin
        BorrarConjunto(Slot.IdAtributo);
        if NuevoId > 0 then
          UpsertConjunto(Slot);
        Slot.IdConjunto := NuevoId;
        FSlots[Indice] := Slot;
      end;
    end;
  end;
  FModificado := False;
  Result := True;
end;

procedure TGestorArticulosVariacionesUniDAC.UpsertConjunto(
  const ASlot: TSlotVariacionUniDAC);
var
  Consulta: TUniQuery;
  NuevoId: Integer;
begin
  if Assigned(ASlot.Control) then
  begin
    NuevoId := Integer(NativeInt(
      ASlot.Control.Properties.Items.Objects[
        ASlot.Control.ItemIndex]));
    if NuevoId <> 0 then
    begin
      Consulta := TUniQuery.Create(nil);
      try
        Consulta.Connection := FConexion;
        Consulta.SQL.Text :=
          'INSERT INTO fza_articulos_conjuntos_asign ' +
          '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ' +
          '   ESGENERACION_AUTO_ACA, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES ' +
          '  (:art, :conj, :atr, ''S'', NOW(), :usr, :usr) ' +
          'ON DUPLICATE KEY UPDATE ' +
          '  ID_AC_ACA = VALUES(ID_AC_ACA), ' +
          '  ESGENERACION_AUTO_ACA = ''S'', ' +
          '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
        Consulta.ParamByName('art').AsString := FCodigoArticulo;
        Consulta.ParamByName('conj').AsInteger := NuevoId;
        Consulta.ParamByName('atr').AsString := ASlot.IdAtributo;
        Consulta.ParamByName('usr').AsString := FUsuario;
        Consulta.Execute;
      finally
        Consulta.Free;
      end;
    end;
  end;
end;

procedure TGestorArticulosVariacionesUniDAC.BorrarConjunto(
  const AIdAtributo: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'DELETE FROM fza_articulos_conjuntos_asign ' +
      'WHERE CODIGO_ART_ACA = :articulo ' +
      '  AND ID_VA_ACA = :atributo';
    Consulta.ParamByName('articulo').AsString := FCodigoArticulo;
    Consulta.ParamByName('atributo').AsString := AIdAtributo;
    Consulta.Execute;
  finally
    Consulta.Free;
  end;
end;

function TGestorArticulosVariacionesUniDAC.ObtenerCodigoArticulo:
  string;
begin
  Result := FCodigoArticulo;
end;

function TGestorArticulosVariacionesUniDAC.EstaModificado: Boolean;
begin
  Result := FModificado;
end;

function CrearGestorArticulosVariacionesUniDAC(
  APanelAtributos: TScrollBox;
  AConexion: TUniConnection;
  const AUsuario: string): IGestorArticulosVariaciones;
begin
  Result := TGestorArticulosVariacionesUniDAC.Create(
    APanelAtributos, AConexion, AUsuario);
end;

end.
