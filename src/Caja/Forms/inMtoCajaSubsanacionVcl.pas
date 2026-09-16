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
  Vcl.Controls, Vcl.ExtCtrls, cxButtons, cxLabel, cxTextEdit,
  cxDropDownEdit, cxGridDBTableView, inLibCajaSubsanacion,
  inLibCorreccionPagoIntf;

type
  TControlesSubsanacionCaja = record
    Propietario: TComponent;
    Contenedor: TWinControl;
    Lineas: TClientDataSet;
    Vista: TcxGridDBTableView;
    ColumnaImporte: TcxGridDBColumn;
    Recalcular: TProc;
  end;

  TModoSubsanacionCajaVcl = class
  private
    FControles: TControlesSubsanacionCaja;
    FOriginales: TLineasSubsanacionCaja;
    FMedios: TArray<TMedioCorreccionPago>;
    FAntesInsertar: TDataSetNotifyEvent;
    FAntesEliminar: TDataSetNotifyEvent;
    FDespuesGuardar: TDataSetNotifyEvent;
    FPanel: TPanel;
    FFormaPago: TcxComboBox;
    FReferencia: TcxTextEdit;
    FMotivo: TcxTextEdit;
    FBotonTotal: TcxButton;
    FGuardada: Boolean;
    procedure CrearControles;
    procedure ActualizarTotal(ADataSet: TDataSet);
    procedure BloquearEstructura(ADataSet: TDataSet);
    procedure CambiarTotal(Sender: TObject);
    procedure AjustarTotal;
    procedure ConfirmarEdicion;
    function LeerLineas: TLineasSubsanacionCaja;
  public
    constructor Create(const AControles: TControlesSubsanacionCaja;
      const AOriginales: TLineasSubsanacionCaja;
      const AMedios: TArray<TMedioCorreccionPago>;
      const AFormaPago, AReferencia: string);
    destructor Destroy; override;
    function LineasCorregidas: TLineasSubsanacionCaja;
    function FormaPago: string;
    function Referencia: string;
    function Motivo: string;
    procedure MarcarGuardada;
    property Guardada: Boolean read FGuardada;
  end;

implementation

uses
  Vcl.Forms, cxEdit, inLibMensajesVcl, inLibMsgSubsanacionCaja,
  UniDataCajaSubsanacionImportes, inMtoModalImporteSubsanacion;

constructor TModoSubsanacionCajaVcl.Create(
  const AControles: TControlesSubsanacionCaja;
  const AOriginales: TLineasSubsanacionCaja;
  const AMedios: TArray<TMedioCorreccionPago>;
  const AFormaPago, AReferencia: string);
var
  i: Integer;
begin
  inherited Create;
  FControles := AControles;
  FOriginales := Copy(AOriginales);
  FMedios := Copy(AMedios);
  FAntesInsertar := FControles.Lineas.BeforeInsert;
  FAntesEliminar := FControles.Lineas.BeforeDelete;
  FDespuesGuardar := FControles.Lineas.AfterPost;
  CrearControles;
  FReferencia.Text := AReferencia;
  for i := 0 to High(FMedios) do
  begin
    FFormaPago.Properties.Items.Add(
      FMedios[i].Codigo + ' - ' + FMedios[i].Descripcion);
    if SameText(FMedios[i].Codigo, AFormaPago) then
      FFormaPago.ItemIndex := i;
  end;
  FControles.Lineas.AfterPost := ActualizarTotal;
  FControles.Lineas.BeforeInsert := BloquearEstructura;
  FControles.Lineas.BeforeDelete := BloquearEstructura;
  FControles.Vista.OptionsData.Appending := False;
  FControles.Vista.OptionsData.Inserting := False;
  FControles.Vista.OptionsData.Deleting := False;
  FControles.Vista.OptionsView.NewItemRow := False;
  for i := 0 to FControles.Vista.ColumnCount - 1 do
    FControles.Vista.Columns[i].Options.Editing :=
      FControles.Vista.Columns[i] = FControles.ColumnaImporte;
end;

destructor TModoSubsanacionCajaVcl.Destroy;
begin
  if Assigned(FControles.Lineas) then
  begin
    FControles.Lineas.AfterPost := FDespuesGuardar;
    FControles.Lineas.BeforeInsert := FAntesInsertar;
    FControles.Lineas.BeforeDelete := FAntesEliminar;
  end;
  FreeAndNil(FPanel);
  inherited;
end;

procedure TModoSubsanacionCajaVcl.CrearControles;
var
  oEtiqueta: TcxLabel;
begin
  FPanel := TPanel.Create(FControles.Propietario);
  FPanel.Name := 'pnlSubsanacion';
  FPanel.Parent := FControles.Contenedor;
  FPanel.Align := alTop;
  FPanel.Height := 92;
  FPanel.BevelOuter := bvNone;
  oEtiqueta := TcxLabel.Create(FPanel);
  oEtiqueta.Parent := FPanel;
  oEtiqueta.Transparent := True;
  oEtiqueta.Caption := SSubsanacionModo;
  oEtiqueta.SetBounds(12, 4, 620, 22);
  FBotonTotal := TcxButton.Create(FPanel);
  FBotonTotal.Parent := FPanel;
  FBotonTotal.Caption := SSubsanacionAjustarTotal;
  FBotonTotal.SetBounds(12, 30, 140, 25);
  FBotonTotal.OnClick := CambiarTotal;
  oEtiqueta := TcxLabel.Create(FPanel);
  oEtiqueta.Parent := FPanel;
  oEtiqueta.Transparent := True;
  oEtiqueta.Caption := SSubsanacionFormaPago;
  oEtiqueta.SetBounds(164, 32, 94, 22);
  FFormaPago := TcxComboBox.Create(FPanel);
  FFormaPago.Parent := FPanel;
  FFormaPago.Properties.DropDownListStyle := lsFixedList;
  FFormaPago.SetBounds(260, 30, 245, 25);
  FReferencia := TcxTextEdit.Create(FPanel);
  FReferencia.Parent := FPanel;
  FReferencia.Properties.Nullstring := SSubsanacionReferencia;
  FReferencia.Hint := SSubsanacionReferencia;
  FReferencia.ShowHint := True;
  FReferencia.SetBounds(515, 30, 260, 25);
  oEtiqueta := TcxLabel.Create(FPanel);
  oEtiqueta.Parent := FPanel;
  oEtiqueta.Transparent := True;
  oEtiqueta.Caption := SSubsanacionMotivo;
  oEtiqueta.SetBounds(12, 62, 140, 22);
  FMotivo := TcxTextEdit.Create(FPanel);
  FMotivo.Parent := FPanel;
  FMotivo.Properties.MaxLength := 500;
  FMotivo.SetBounds(164, 60, 611, 25);
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

procedure TModoSubsanacionCajaVcl.CambiarTotal(Sender: TObject);
begin
  try
    AjustarTotal;
  except
    on E: EArgumentException do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TModoSubsanacionCajaVcl.AjustarTotal;
var
  oLineas: TLineasSubsanacionCaja;
  dTotal: Currency;
begin
  ConfirmarEdicion;
  oLineas := LeerImportesSubsanacion(FControles.Lineas);
  if TfrmModalImporteSubsanacion.Ejecutar(FControles.Propietario,
    TotalSubsanacion(oLineas), dTotal) then
  begin
    oLineas := RepartirTotalSubsanacion(oLineas, dTotal);
    AplicarImportesSubsanacion(FControles.Lineas, oLineas);
    FControles.Recalcular();
  end;
end;

function TModoSubsanacionCajaVcl.FormaPago: string;
begin
  if (FFormaPago.ItemIndex < 0) or
     (FFormaPago.ItemIndex >= Length(FMedios)) then
    raise EArgumentException.Create(SSubsanacionSeleccionePago);
  Result := FMedios[FFormaPago.ItemIndex].Codigo;
end;

function TModoSubsanacionCajaVcl.Referencia: string;
begin
  Result := Trim(FReferencia.Text);
end;

function TModoSubsanacionCajaVcl.Motivo: string;
begin
  Result := Trim(FMotivo.Text);
  if Result = '' then
    raise EArgumentException.Create(SSubsanacionMotivoObligatorio);
end;

procedure TModoSubsanacionCajaVcl.MarcarGuardada;
begin
  FGuardada := True;
  FPanel.Enabled := False;
  FControles.Vista.OptionsData.Editing := False;
end;

end.
