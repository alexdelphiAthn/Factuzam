{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridCantidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formato de columnas de CANTIDAD en grids cx con decimales POR FILA segun  }
{    la unidad de medida de la linea. Usa OnGetDisplayText (texto por fila,    }
{    respeta el editor) + permite teclear decimales en el spin. Apoyo de       }
{    inLibUnidadesMedida para las fases de documentos.                         }
{******************************************************************************}
unit inLibGridCantidad;

interface

uses
  cxGridDBTableView;

// Vincula una columna de cantidad a su columna de unidad de medida: la celda
// mostrara los decimales que correspondan a la unidad de esa fila y el editor
// admitira decimales. AColUnidad puede ser nil (entonces decimales por defecto).
procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn);

implementation

uses
  System.Classes, System.SysUtils, System.Variants, System.Math, Data.DB,
  Vcl.ExtCtrls, cxGridCustomTableView, cxGridTableView, cxSpinEdit,
  inLibUnidadesMedida, inLibMsgArticulos;

type
  TVisibilidadTipoCantidad = class;

  TEnlaceTipoCantidad = class(TDataLink)
  private
    FGestor: TVisibilidadTipoCantidad;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure RecordChanged(Field: TField); override;
  end;

  TVisibilidadTipoCantidad = class(TComponent)
  private
    FColUnidad: TcxGridDBColumn;
    FEnlace: TEnlaceTipoCantidad;
    FTimer: TTimer;
    procedure Actualizar;
    procedure Programar;
    procedure TimerTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Configurar(AColUnidad: TcxGridDBColumn);
  end;

  TFormatoCantidadGrid = class(TComponent)
  private
    FColCantidad: TcxGridDBColumn;
    FColUnidad: TcxGridDBColumn;
    procedure GetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
  end;

function EsTipoCantidadPredeterminado(const AValor: string): Boolean;
var
  sValor: string;
begin
  sValor := Trim(AValor);
  Result := (sValor = '') or SameText(sValor, 'Uds') or
            SameText(sValor, 'Ud') or SameText(sValor, 'Unidad') or
            SameText(sValor, 'Unidades') or SameText(sValor, 'Cantidad');
end;

procedure TEnlaceTipoCantidad.ActiveChanged;
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

procedure TEnlaceTipoCantidad.DataSetChanged;
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

procedure TEnlaceTipoCantidad.RecordChanged(Field: TField);
begin
  inherited;
  if FGestor <> nil then
    FGestor.Programar;
end;

constructor TVisibilidadTipoCantidad.Create(AOwner: TComponent);
begin
  inherited;
  FEnlace := TEnlaceTipoCantidad.Create;
  FEnlace.FGestor := Self;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 1;
  FTimer.OnTimer := TimerTimer;
end;

destructor TVisibilidadTipoCantidad.Destroy;
begin
  FTimer.Enabled := False;
  FEnlace.DataSource := nil;
  FEnlace.FGestor := nil;
  FreeAndNil(FEnlace);
  inherited;
end;

procedure TVisibilidadTipoCantidad.Configurar(
  AColUnidad: TcxGridDBColumn);
begin
  FColUnidad := AColUnidad;
  if (FColUnidad <> nil) and
     (FColUnidad.GridView is TcxGridDBTableView) then
    FEnlace.DataSource := TcxGridDBTableView(FColUnidad.GridView).
      DataController.DataSource
  else
    FEnlace.DataSource := nil;
  if FColUnidad <> nil then
  begin
    FColUnidad.Visible := False;
    FColUnidad.VisibleForCustomization := False;
  end;
  Programar;
end;

procedure TVisibilidadTipoCantidad.Programar;
begin
  if FTimer <> nil then
  begin
    FTimer.Enabled := False;
    FTimer.Enabled := True;
  end;
end;

procedure TVisibilidadTipoCantidad.TimerTimer(Sender: TObject);
begin
  FTimer.Enabled := False;
  Actualizar;
end;

procedure TVisibilidadTipoCantidad.Actualizar;
var
  Vista: TcxGridDBTableView;
  i: Integer;
  sUnidad: string;
  vUnidad: Variant;
  bEspecial: Boolean;
begin
  bEspecial := False;
  Vista := nil;
  if (FColUnidad <> nil) and
     (FColUnidad.GridView is TcxGridDBTableView) then
    Vista := TcxGridDBTableView(FColUnidad.GridView);
  if Vista <> nil then
  begin
    i := 0;
    while (not bEspecial) and
          (i < Vista.DataController.RecordCount) do
    begin
      vUnidad := Vista.DataController.Values[i, FColUnidad.Index];
      sUnidad := '';
      if not (VarIsNull(vUnidad) or VarIsEmpty(vUnidad)) then
        sUnidad := VarToStr(vUnidad);
      bEspecial := not EsTipoCantidadPredeterminado(sUnidad);
      Inc(i);
    end;
  end;
  if FColUnidad <> nil then
  begin
    FColUnidad.Visible := bEspecial;
    FColUnidad.VisibleForCustomization := bEspecial;
    if bEspecial then
    begin
      if Trim(FColUnidad.Caption) = '' then
        FColUnidad.Caption := SCaptionColTipoCantidad;
      if FColUnidad.Width < 80 then
        FColUnidad.Width := 90;
    end;
  end;
end;

procedure TFormatoCantidadGrid.GetDisplayText(Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord; var AText: string);
var
  vVal: Variant;
  vUni: Variant;
  dVal: Double;
  sUni: string;
begin
  vVal := ARecord.Values[FColCantidad.Index];
  // Celda vacia: dejamos el texto por defecto (no formateamos null).
  if not (VarIsNull(vVal) or VarIsEmpty(vVal)) then
  begin
    dVal := vVal;
    sUni := '';
    if FColUnidad <> nil then
    begin
      vUni := ARecord.Values[FColUnidad.Index];
      if not (VarIsNull(vUni) or VarIsEmpty(vUni)) then
        sUni := VarToStr(vUni);
    end;
    AText := oUnidades.Formatear(dVal, sUni);
  end;
end;

procedure VincularCantidadGrid(AColCantidad, AColUnidad: TcxGridDBColumn);
var
  i: Integer;
  oFmt: TFormatoCantidadGrid;
  oVisibilidad: TVisibilidadTipoCantidad;
begin
  if AColCantidad <> nil then
  begin
    // El spin que hoy solo admite enteros pasa a admitir decimales.
    if (AColCantidad.Properties <> nil) and
       (AColCantidad.Properties is TcxSpinEditProperties) then
      TcxSpinEditProperties(AColCantidad.Properties).ValueType := vtFloat;
    // El formateador vive ligado a la columna (se libera con ella).
    oFmt := TFormatoCantidadGrid.Create(AColCantidad);
    oFmt.FColCantidad := AColCantidad;
    oFmt.FColUnidad := AColUnidad;
    AColCantidad.OnGetDisplayText := oFmt.GetDisplayText;
  end;
  if AColUnidad <> nil then
  begin
    oVisibilidad := nil;
    i := 0;
    while (oVisibilidad = nil) and (i < AColUnidad.ComponentCount) do
    begin
      if AColUnidad.Components[i] is TVisibilidadTipoCantidad then
        oVisibilidad := TVisibilidadTipoCantidad(
          AColUnidad.Components[i]);
      Inc(i);
    end;
    if oVisibilidad = nil then
      oVisibilidad := TVisibilidadTipoCantidad.Create(AColUnidad);
    oVisibilidad.Configurar(AColUnidad);
  end;
end;

end.
