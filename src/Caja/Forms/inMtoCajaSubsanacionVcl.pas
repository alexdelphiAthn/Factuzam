{******************************************************************************}
{  Módulo: inMtoCajaSubsanacionVcl                                             }
{  Tipo: Presentación de Caja                                                  }
{  Fecha: 16/09/2026                                                           }
{  Descripción: Edición limitada de importes y cobro de una operación.         }
{******************************************************************************}
unit inMtoCajaSubsanacionVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Datasnap.DBClient,
  Vcl.Controls, cxGridDBTableView, inLibCajaSubsanacion;

type
  TControlesSubsanacionCaja = record
    Propietario: TComponent;
    Contenedor: TWinControl;
    Lineas: TClientDataSet;
    Vista: TcxGridDBTableView;
    // Precio, descuento, "menos" y total, como en el ticket original.
    ColumnasEditables: TArray<TcxGridDBColumn>;
    Recalcular: TProc;
  end;

  TModoSubsanacionCajaVcl = class
  private
    FControles: TControlesSubsanacionCaja;
    FOriginales: TLineasSubsanacionCaja;
    FAntesInsertar: TDataSetNotifyEvent;
    FAntesEliminar: TDataSetNotifyEvent;
    FDespuesGuardar: TDataSetNotifyEvent;
    FGuardada: Boolean;
    procedure ActualizarTotal(ADataSet: TDataSet);
    procedure BloquearEstructura(ADataSet: TDataSet);
    function EsColumnaEditable(AColumna: TObject): Boolean;
    function EsLineaActualFija: Boolean;
    procedure ConfirmarEdicion;
    function LeerLineas: TLineasSubsanacionCaja;
  public
    // Forma de pago y descuento global se editan en la pantalla de Cobro.
    constructor Create(const AControles: TControlesSubsanacionCaja;
      const AOriginales: TLineasSubsanacionCaja);
    destructor Destroy; override;
    function LineasCorregidas: TLineasSubsanacionCaja;
    // Columna editable en la línea actual: los abonos a cuenta y anticipos
    // (líneas fijas) no se pueden corregir.
    function PermiteEditar(AColumna: TObject): Boolean;
    // Pide el motivo al grabar; False si el usuario cancela.
    function PedirMotivo(out AMotivo: string): Boolean;
    procedure MarcarGuardada;
    property Guardada: Boolean read FGuardada;
  end;

implementation

uses
  Vcl.Dialogs, cxEdit, inLibMensajesVcl, inLibMsgSubsanacionCaja,
  inLibFacturas, UniDataCajaSubsanacionImportes;

const
  LONGITUD_MOTIVO = 500;

constructor TModoSubsanacionCajaVcl.Create(
  const AControles: TControlesSubsanacionCaja;
  const AOriginales: TLineasSubsanacionCaja);
var
  i: Integer;
begin
  inherited Create;
  FControles := AControles;
  FOriginales := Copy(AOriginales);
  FAntesInsertar := FControles.Lineas.BeforeInsert;
  FAntesEliminar := FControles.Lineas.BeforeDelete;
  FDespuesGuardar := FControles.Lineas.AfterPost;
  FControles.Lineas.AfterPost := ActualizarTotal;
  FControles.Lineas.BeforeInsert := BloquearEstructura;
  FControles.Lineas.BeforeDelete := BloquearEstructura;
  FControles.Vista.OptionsData.Appending := False;
  FControles.Vista.OptionsData.Inserting := False;
  FControles.Vista.OptionsData.Deleting := False;
  FControles.Vista.OptionsView.NewItemRow := False;
  for i := 0 to FControles.Vista.ColumnCount - 1 do
    FControles.Vista.Columns[i].Options.Editing :=
      EsColumnaEditable(FControles.Vista.Columns[i]);
end;

function TModoSubsanacionCajaVcl.EsColumnaEditable(
  AColumna: TObject): Boolean;
var
  oColumna: TcxGridDBColumn;
begin
  Result := False;
  if not FGuardada then
    for oColumna in FControles.ColumnasEditables do
      Result := Result or (oColumna = AColumna);
end;

function TModoSubsanacionCajaVcl.EsLineaActualFija: Boolean;
var
  sNumero: string;
  oLinea: TLineaSubsanacionCaja;
begin
  Result := False;
  if FControles.Lineas.Active and not FControles.Lineas.IsEmpty then
  begin
    sNumero := FControles.Lineas.FieldByName(fnrolin).AsString;
    for oLinea in FOriginales do
      Result := Result or (oLinea.Fija and (oLinea.Numero = sNumero));
  end;
end;

function TModoSubsanacionCajaVcl.PermiteEditar(AColumna: TObject): Boolean;
begin
  Result := EsColumnaEditable(AColumna) and not EsLineaActualFija;
end;

destructor TModoSubsanacionCajaVcl.Destroy;
begin
  if Assigned(FControles.Lineas) then
  begin
    FControles.Lineas.AfterPost := FDespuesGuardar;
    FControles.Lineas.BeforeInsert := FAntesInsertar;
    FControles.Lineas.BeforeDelete := FAntesEliminar;
  end;
  inherited;
end;

procedure TModoSubsanacionCajaVcl.BloquearEstructura(ADataSet: TDataSet);
begin
  raise EcxEditValidationError.Create(SSubsanacionLineasFijas);
end;

procedure TModoSubsanacionCajaVcl.ActualizarTotal(ADataSet: TDataSet);
begin
  FControles.Recalcular();
end;

procedure TModoSubsanacionCajaVcl.ConfirmarEdicion;
begin
  FControles.Vista.Controller.EditingController.HideEdit(True);
  FControles.Lineas.CheckBrowseMode;
end;

function TModoSubsanacionCajaVcl.LeerLineas: TLineasSubsanacionCaja;
var
  i, j: Integer;
  bEncontrada: Boolean;
  oActuales: TLineasSubsanacionCaja;
begin
  oActuales := LeerImportesSubsanacion(FControles.Lineas);
  if Length(oActuales) <> Length(FOriginales) then
    raise EArgumentException.Create(SSubsanacionLineasFijas);
  Result := Copy(FOriginales);
  for i := 0 to High(Result) do
  begin
    bEncontrada := False;
    for j := 0 to High(oActuales) do
    begin
      if Result[i].Numero = oActuales[j].Numero then
      begin
        if Result[i].Cantidad <> oActuales[j].Cantidad then
          raise EArgumentException.Create(SSubsanacionLineasFijas);
        Result[i].Importe := oActuales[j].Importe;
        Result[i].PrecioSalida := oActuales[j].PrecioSalida;
        bEncontrada := True;
      end;
    end;
    if not bEncontrada then
      raise EArgumentException.Create(SSubsanacionLineasFijas);
  end;
end;

function TModoSubsanacionCajaVcl.LineasCorregidas:
  TLineasSubsanacionCaja;
begin
  ConfirmarEdicion;
  Result := LeerLineas;
  ValidarImportesSubsanacion(Result);
end;

function TModoSubsanacionCajaVcl.PedirMotivo(out AMotivo: string): Boolean;
var
  oValores: array of string;
begin
  SetLength(oValores, 1);
  Result := InputQuery_fza(SSubsanacionBoton, [SSubsanacionMotivo], oValores,
    function(const AValores: array of string): Boolean
    begin
      Result := (Trim(AValores[0]) <> '') and
        (Length(Trim(AValores[0])) <= LONGITUD_MOTIVO);
      if not Result then
        ShowMessage_fza(SSubsanacionMotivoObligatorio);
    end);
  AMotivo := '';
  if Result then
    AMotivo := Trim(oValores[0]);
end;

procedure TModoSubsanacionCajaVcl.MarcarGuardada;
begin
  FGuardada := True;
  FControles.Vista.OptionsData.Editing := False;
end;

end.
