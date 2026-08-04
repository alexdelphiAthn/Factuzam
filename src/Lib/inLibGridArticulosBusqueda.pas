{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridArticulosBusqueda                                   }
{    Tipo:       Presentación                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Colaboración visual cohesiva para entrada, escáner y búsquedas de la      }
{    columna de artículo. No conoce SQL ni conexiones.                         }
{******************************************************************************}
unit inLibGridArticulosBusqueda;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Variants,
  Data.DB, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  cxEdit, cxTextEdit, cxDropDownEdit, cxButtonEdit,
  cxEditRepositoryItems, cxDBExtLookupComboBox,
  cxGrid, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibGenBusq, inLibLogIntf, inLibModoTallasIntf,
  inLibGridArticulosPersistenciaIntf;

type
  TResolverEntradaGridArticulos = function(
    const AEntrada: string): Boolean of object;
  TAccionGridArticulos = procedure of object;
  TMostrarPaletaGridArticulos = procedure(AOrden: Integer) of object;
  TRegistroGridArticulos = procedure(const ATexto: string) of object;

  TBusquedaGridArticulos = class
  private
    FView: TcxGridDBTableView;
    FDatos: TDataSet;
    FCampoArticulo: string;
    FColArticulo: TcxGridDBColumn;
    FBusquedaVisual: IBusquedaVisual;
    FBusquedaSkus: IBusquedaSkusTallas;
    FConsultaArticulos: IConsultaArticulosGrid;
    FRegistroLog: IRegistroLog;
    FResolverEntrada: TResolverEntradaGridArticulos;
    FDespuesResolver: TAccionGridArticulos;
    FMostrarPaleta: TMostrarPaletaGridArticulos;
    FRegistro: TRegistroGridArticulos;
    FAlmacenStock: string;
    FBusqDs: TDataSource;
    FBusqRepo: TcxGridViewRepository;
    FBusqView: TcxGridDBTableView;
    FBusqColSku: TcxGridDBColumn;
    FBusqColInput: TcxGridDBColumn;
    FEditRepo: TcxEditRepository;
    FRepCombo: TcxEditRepositoryExtLookupComboBoxItem;
    FTimerResolve: TTimer;
    FTimerBusq: TTimer;
    FSkuPend: string;
    FEnScanner: Boolean;
    FScanBuffer: string;
    procedure CrearControlesBusqueda;
    procedure AbrirBusquedaFiltrada(const ATexto: string);
    procedure LimpiarFiltroDesplegable;
    procedure ComboBusqInitPopup(Sender: TObject);
    procedure ComboBusqCloseUp(Sender: TObject);
    procedure ArticuloChange(Sender: TObject);
    procedure TimerBusqTimer(Sender: TObject);
    procedure TimerResolveTimer(Sender: TObject);
    procedure DispararResolucion(const ACodigo: string);
    procedure OcultarEditor(const AOrigen: string);
    procedure AbrirBusquedaCompleta(Sender: TObject);
    procedure Registrar(const ATexto: string);
  public
    constructor Create(AView: TcxGridDBTableView; ADatos: TDataSet;
      const ACampoArticulo: string;
      const ABusquedaVisual: IBusquedaVisual;
      const ABusquedaSkus: IBusquedaSkusTallas;
      const AConsultaArticulos: IConsultaArticulosGrid;
      const ARegistroLog: IRegistroLog;
      AResolverEntrada: TResolverEntradaGridArticulos;
      ADespuesResolver: TAccionGridArticulos;
      AMostrarPaleta: TMostrarPaletaGridArticulos;
      ARegistro: TRegistroGridArticulos);
    destructor Destroy; override;
    procedure ConfigurarColumna(AColumna: TcxGridDBColumn);
    procedure ConfigurarEditorArticulo(AEditor: TcxCustomTextEdit);
    procedure Invalidar;
    procedure SetAlmacenStock(const AValue: string);
    procedure ArticuloGetProperties(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure ArticuloKeyPress(Sender: TObject; var Key: Char);
    procedure ArticuloButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure ArticuloValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure ViewEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    function LimpiarEntrada(const AEntrada: string): string;
    procedure MostrarEditorArticulo;
  end;

implementation

uses
  inLibMsgArticulos;

constructor TBusquedaGridArticulos.Create(
  AView: TcxGridDBTableView; ADatos: TDataSet;
  const ACampoArticulo: string;
  const ABusquedaVisual: IBusquedaVisual;
  const ABusquedaSkus: IBusquedaSkusTallas;
  const AConsultaArticulos: IConsultaArticulosGrid;
  const ARegistroLog: IRegistroLog;
  AResolverEntrada: TResolverEntradaGridArticulos;
  ADespuesResolver: TAccionGridArticulos;
  AMostrarPaleta: TMostrarPaletaGridArticulos;
  ARegistro: TRegistroGridArticulos);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(ADatos) then
    raise EArgumentNilException.Create('ADatos');
  if not Assigned(ABusquedaVisual) then
    raise EArgumentNilException.Create('ABusquedaVisual');
  if not Assigned(ABusquedaSkus) then
    raise EArgumentNilException.Create('ABusquedaSkus');
  if not Assigned(AConsultaArticulos) then
    raise EArgumentNilException.Create('AConsultaArticulos');
  FView := AView;
  FDatos := ADatos;
  FCampoArticulo := ACampoArticulo;
  FBusquedaVisual := ABusquedaVisual;
  FBusquedaSkus := ABusquedaSkus;
  FConsultaArticulos := AConsultaArticulos;
  FRegistroLog := ARegistroLog;
  FResolverEntrada := AResolverEntrada;
  FDespuesResolver := ADespuesResolver;
  FMostrarPaleta := AMostrarPaleta;
  FRegistro := ARegistro;
  FTimerResolve := TTimer.Create(nil);
  FTimerResolve.Enabled := False;
  FTimerResolve.Interval := 1;
  FTimerResolve.OnTimer := TimerResolveTimer;
  FTimerBusq := TTimer.Create(nil);
  FTimerBusq.Enabled := False;
  FTimerBusq.Interval := 350;
  FTimerBusq.OnTimer := TimerBusqTimer;
  CrearControlesBusqueda;
end;

destructor TBusquedaGridArticulos.Destroy;
begin
  if Assigned(FRepCombo) then
  begin
    FRepCombo.Properties.OnChange := nil;
    FRepCombo.Properties.OnInitPopup := nil;
    FRepCombo.Properties.OnCloseUp := nil;
    FRepCombo.Properties.OnValidate := nil;
    FRepCombo.Properties.OnButtonClick := nil;
  end;
  FTimerBusq.Free;
  FTimerResolve.Free;
  FEditRepo.Free;
  FBusqRepo.Free;
  FBusqDs.Free;
  FConsultaArticulos := nil;
  FBusquedaSkus := nil;
  FBusquedaVisual := nil;
  inherited;
end;

procedure TBusquedaGridArticulos.CrearControlesBusqueda;
var
  oColumna: TcxGridDBColumn;
begin
  FBusqDs := TDataSource.Create(nil);
  FBusqDs.DataSet := FBusquedaSkus.Dataset;
  FBusqRepo := TcxGridViewRepository.Create(nil);
  FBusqView := FBusqRepo.CreateItem(
    TcxGridDBTableView) as TcxGridDBTableView;
  FBusqView.DataController.DataSource := FBusqDs;
  FBusqView.DataController.KeyFieldNames := 'SKU';
  FBusqView.DataController.DataModeController.GridMode := True;
  FBusqView.DataController.DataModeController.SyncMode := False;
  FBusqView.OptionsView.GroupByBox := False;
  FBusqView.OptionsSelection.CellSelect := False;
  FBusqView.OptionsBehavior.IncSearch := False;
  FBusqColSku := FBusqView.CreateColumn;
  FBusqColSku.Caption := SCaptionColSku;
  FBusqColSku.DataBinding.FieldName := 'SKU';
  FBusqColSku.Width := 200;
  FBusqColInput := FBusqView.CreateColumn;
  FBusqColInput.DataBinding.FieldName := 'INPUT_BUSQUEDA';
  FBusqColInput.PropertiesClass := TcxTextEditProperties;
  TcxTextEditProperties(FBusqColInput.Properties).IncrementalSearch :=
    False;
  FBusqColInput.Visible := False;
  FBusqColInput.Options.Filtering := False;
  FBusqColInput.Options.FilteringPopup := False;
  FBusqColInput.Options.IncSearch := False;
  FBusqColInput.Options.Grouping := False;
  oColumna := FBusqView.CreateColumn;
  oColumna.Caption := 'Descripción';
  oColumna.DataBinding.FieldName := 'DESCRIPCION';
  oColumna.Width := 220;
  oColumna := FBusqView.CreateColumn;
  oColumna.Caption := 'Cód. barras';
  oColumna.DataBinding.FieldName := 'CODBARRAS';
  oColumna.Width := 130;
  oColumna := FBusqView.CreateColumn;
  oColumna.Caption := 'Ref. prov.';
  oColumna.DataBinding.FieldName := 'REFPRV';
  oColumna.Width := 110;
  oColumna := FBusqView.CreateColumn;
  oColumna.Caption := 'Stock';
  oColumna.DataBinding.FieldName := 'STOCK';
  oColumna.Width := 60;
  FEditRepo := TcxEditRepository.Create(nil);
  FRepCombo := FEditRepo.CreateItem(
    TcxEditRepositoryExtLookupComboBoxItem) as
    TcxEditRepositoryExtLookupComboBoxItem;
  FRepCombo.Properties.View := FBusqView;
  FRepCombo.Properties.KeyFieldNames := 'SKU';
  FRepCombo.Properties.ListFieldItem := FBusqColInput;
  FRepCombo.Properties.DropDownListStyle := lsEditList;
  FRepCombo.Properties.AutoSearchOnPopup := False;
  FRepCombo.Properties.IncrementalFiltering := False;
  FRepCombo.Properties.DropDownRows := 15;
  FRepCombo.Properties.DropDownAutoWidth := True;
  FRepCombo.Properties.ImmediateDropDownWhenKeyPressed := False;
  FRepCombo.Properties.OnInitPopup := ComboBusqInitPopup;
  FRepCombo.Properties.OnCloseUp := ComboBusqCloseUp;
  FRepCombo.Properties.OnChange := ArticuloChange;
  FRepCombo.Properties.Buttons.Clear;
  FRepCombo.Properties.Buttons.Add.Kind := bkEllipsis;
  FRepCombo.Properties.OnButtonClick := ArticuloButtonClick;
  FRepCombo.Properties.OnValidate := ArticuloValidate;
end;

procedure TBusquedaGridArticulos.ConfigurarColumna(
  AColumna: TcxGridDBColumn);
begin
  FColArticulo := AColumna;
  if Assigned(FColArticulo) then
    FColArticulo.OnGetProperties := ArticuloGetProperties;
end;

procedure TBusquedaGridArticulos.ConfigurarEditorArticulo(
  AEditor: TcxCustomTextEdit);
begin
  if Assigned(AEditor) then
  begin
    AEditor.OnKeyPress := ArticuloKeyPress;
    AEditor.Properties.OnChange := ArticuloChange;
  end;
end;

procedure TBusquedaGridArticulos.Registrar(const ATexto: string);
begin
  if Assigned(FRegistro) then
    FRegistro(ATexto);
end;

procedure TBusquedaGridArticulos.Invalidar;
begin
  FBusquedaSkus.Invalidar;
end;

procedure TBusquedaGridArticulos.SetAlmacenStock(
  const AValue: string);
begin
  if FAlmacenStock <> AValue then
  begin
    FAlmacenStock := AValue;
    Invalidar;
  end;
end;

procedure TBusquedaGridArticulos.AbrirBusquedaFiltrada(
  const ATexto: string);
begin
  LimpiarFiltroDesplegable;
  Screen.Cursor := crHourGlass;
  FBusqView.BeginUpdate;
  try
    FBusqView.DataController.DataSource := nil;
    FBusquedaSkus.Aplicar(ATexto, FAlmacenStock);
    FBusqView.DataController.DataSource := FBusqDs;
    FBusqView.DataController.Refresh;
  finally
    FBusqView.EndUpdate;
    Screen.Cursor := crDefault;
  end;
end;

procedure TBusquedaGridArticulos.LimpiarFiltroDesplegable;
begin
  if Assigned(FBusqView) then
  begin
    FBusqView.BeginUpdate;
    try
      FBusqView.Controller.IncSearchingText := '';
      FBusqView.DataController.Filter.Clear;
      FBusqView.DataController.Filter.Active := False;
      FBusqView.DataController.Filter.AutoDataSetFilter := False;
      FBusqView.DataController.Refresh;
    finally
      FBusqView.EndUpdate;
    end;
  end;
end;

procedure TBusquedaGridArticulos.ComboBusqInitPopup(Sender: TObject);
var
  sTexto: string;
begin
  sTexto := '';
  if Sender is TcxExtLookupComboBox then
  begin
    sTexto := TcxExtLookupComboBox(Sender).Text;
    if TcxExtLookupComboBox(Sender).SelLength > 0 then
      sTexto := Copy(sTexto, 1,
        TcxExtLookupComboBox(Sender).SelStart);
    sTexto := Trim(sTexto);
  end;
  AbrirBusquedaFiltrada(sTexto);
end;

procedure TBusquedaGridArticulos.ArticuloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  bEnfocada, bVacia: Boolean;
  vValor: Variant;
begin
  if Assigned(ARecord) and Assigned(FRepCombo) then
  begin
    vValor := ARecord.Values[Sender.Index];
    bVacia := VarIsNull(vValor) or (Trim(VarToStr(vValor)) = '');
    bEnfocada := (FView.Controller.FocusedRecord = ARecord) and
      (FView.Controller.FocusedItem = Sender);
    if bVacia and bEnfocada then
      AProperties := FRepCombo.Properties;
  end;
end;

procedure TBusquedaGridArticulos.ArticuloChange(Sender: TObject);
begin
  Registrar('GridArt.Change: scanner=' +
    BoolToStr(FEnScanner, True));
  if not FEnScanner and Assigned(FTimerBusq) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end;
end;

procedure TBusquedaGridArticulos.TimerBusqTimer(Sender: TObject);
var
  oCombo: TcxExtLookupComboBox;
  oDatos: TDataSet;
  oEdit: TcxCustomEdit;
  sTexto: string;
begin
  FTimerBusq.Enabled := False;
  if not FView.Controller.EditingController.IsEditing then
    Registrar('GridArt.Busq: sin editor activo')
  else
  begin
    oEdit := FView.Controller.EditingController.Edit;
    if not (oEdit is TcxExtLookupComboBox) then
      Registrar('GridArt.Busq: editor no es combo (' +
        oEdit.ClassName + ')')
    else
    begin
      oCombo := TcxExtLookupComboBox(oEdit);
      sTexto := oCombo.Text;
      if oCombo.SelLength > 0 then
        sTexto := Copy(sTexto, 1, oCombo.SelStart);
      sTexto := Trim(sTexto);
      Registrar('GridArt.Busq: texto="' + sTexto + '"');
      if Length(sTexto) >= 3 then
      begin
        AbrirBusquedaFiltrada(sTexto);
        oDatos := FBusquedaSkus.Dataset;
        Registrar(Format('GridArt.Busq: %d filas query, %d en vista',
          [oDatos.RecordCount, FBusqView.DataController.RecordCount]));
        if not oDatos.IsEmpty then
          Registrar(Format('GridArt.Busq: CODBARRAS size=%d val="%s"',
            [oDatos.FieldByName('CODBARRAS').Size,
             oDatos.FieldByName('CODBARRAS').AsString]));
        if not oCombo.DroppedDown then
          oCombo.DroppedDown := True;
      end;
    end;
  end;
end;

procedure TBusquedaGridArticulos.DispararResolucion(
  const ACodigo: string);
begin
  FSkuPend := Trim(ACodigo);
  if FSkuPend <> '' then
  begin
    FTimerResolve.Enabled := False;
    FTimerResolve.Enabled := True;
  end;
end;

procedure TBusquedaGridArticulos.ArticuloKeyPress(
  Sender: TObject; var Key: Char);
begin
  if Key = #2 then
  begin
    FEnScanner := True;
    FScanBuffer := '';
    FTimerBusq.Enabled := False;
    Key := #0;
  end
  else if FEnScanner then
  begin
    if Key = #3 then
    begin
      FEnScanner := False;
      Key := #0;
      DispararResolucion(FScanBuffer);
      FScanBuffer := '';
    end
    else
    begin
      FScanBuffer := FScanBuffer + Key;
      Key := #0;
    end;
  end;
end;

procedure TBusquedaGridArticulos.ViewEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  sEntrada: string;
begin
  if Key = VK_F3 then
  begin
    if AItem = FColArticulo then
    begin
      Key := 0;
      AbrirBusquedaCompleta(AEdit);
    end
    else if Assigned(AItem) and (AItem.Tag >= 1) and
            (AItem.Tag <= 5) then
    begin
      Key := 0;
      if Assigned(FMostrarPaleta) then
        FMostrarPaleta(AItem.Tag);
    end;
  end
  else if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    if AItem = FColArticulo then
      AbrirBusquedaCompleta(AEdit)
    else if Assigned(AItem) and (AItem.Tag >= 1) and
            (AItem.Tag <= 5) and Assigned(FMostrarPaleta) then
      FMostrarPaleta(AItem.Tag);
  end
  else if (AItem = FColArticulo) and not FEnScanner and
          ((Key = VK_BACK) or (Key = VK_DELETE) or
           ((Key >= Ord('0')) and
            not ((Key >= VK_F1) and (Key <= VK_F24)))) then
  begin
    FTimerBusq.Enabled := False;
    FTimerBusq.Enabled := True;
  end
  else if (AItem = FColArticulo) and (Key = VK_RETURN) then
  begin
    if (AEdit is TcxCustomDropDownEdit) and
       TcxCustomDropDownEdit(AEdit).DroppedDown then
      TcxCustomDropDownEdit(AEdit).DroppedDown := False;
    if AEdit is TcxCustomTextEdit then
      sEntrada := Trim(TcxCustomTextEdit(AEdit).Text)
    else
      sEntrada := Trim(VarToStr(AEdit.EditValue));
    if sEntrada <> '' then
    begin
      Key := 0;
      DispararResolucion(sEntrada);
    end;
  end;
end;

function TBusquedaGridArticulos.LimpiarEntrada(
  const AEntrada: string): string;
begin
  Result := StringReplace(AEntrada, #2, '', [rfReplaceAll]);
  Result := StringReplace(Result, #3, '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
  Result := Trim(Result);
end;

procedure TBusquedaGridArticulos.ComboBusqCloseUp(Sender: TObject);
begin
  LimpiarFiltroDesplegable;
  if Sender is TcxCustomEdit then
  begin
    FSkuPend := VarToStr(TcxCustomEdit(Sender).EditValue);
    if Trim(FSkuPend) <> '' then
    begin
      FTimerResolve.Enabled := False;
      FTimerResolve.Enabled := True;
    end;
  end;
end;

procedure TBusquedaGridArticulos.OcultarEditor(
  const AOrigen: string);
begin
  if FView.Controller.EditingController.IsEditing then
  begin
    try
      FView.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarAviso(
            'GridArticulos.' + AOrigen + ': HideEdit ignorado: ' +
            E.Message);
    end;
  end;
end;

procedure TBusquedaGridArticulos.TimerResolveTimer(Sender: TObject);
var
  sSku: string;
begin
  FTimerResolve.Enabled := False;
  sSku := FSkuPend;
  FSkuPend := '';
  if (Trim(sSku) <> '') and Assigned(FResolverEntrada) and
     FResolverEntrada(sSku) then
  begin
    OcultarEditor('TimerResolve');
    if Assigned(FDespuesResolver) then
      FDespuesResolver;
  end;
end;

procedure TBusquedaGridArticulos.AbrirBusquedaCompleta(
  Sender: TObject);
var
  oDatos: TDataSet;
  sArticulo: string;
begin
  if Sender is TcxExtLookupComboBox then
    TcxExtLookupComboBox(Sender).DroppedDown := False;
  FConsultaArticulos.Aplicar(FAlmacenStock);
  oDatos := FConsultaArticulos.DataSet;
  if FBusquedaVisual.EjecutarBusquedaDataSet(
    'Búsqueda de artículos', oDatos,
    'frmMtoArtTraspasoSearch') then
  begin
    sArticulo := oDatos.FieldByName('ARTICULO').AsString;
    if Assigned(FResolverEntrada) and FResolverEntrada(sArticulo) then
      OcultarEditor('ArticuloButtonClick');
  end;
end;

procedure TBusquedaGridArticulos.ArticuloButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  AbrirBusquedaCompleta(Sender);
end;

procedure TBusquedaGridArticulos.ArticuloValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
var
  sEntrada: string;
begin
  Error := False;
  ErrorText := '';
  sEntrada := Trim(VarToStr(DisplayValue));
  if sEntrada <> '' then
  begin
    if Assigned(FResolverEntrada) and FResolverEntrada(sEntrada) then
      DisplayValue := FDatos.FieldByName(FCampoArticulo).AsString
    else
    begin
      Error := True;
      ErrorText := Format(SErrorArticuloSkuNoEncontrado, [sEntrada]);
    end;
  end;
end;

procedure TBusquedaGridArticulos.MostrarEditorArticulo;
begin
  if Assigned(FView) and Assigned(FColArticulo) then
  begin
    FColArticulo.Focused := True;
    try
      FView.Controller.EditingController.ShowEdit;
    except
      on E: EInvalidOperation do
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarAviso(
            'GridArticulos.MostrarEditorArticulo: ' +
            'ShowEdit ignorado: ' + E.Message);
    end;
  end;
end;

end.
