{******************************************************************************}
{                                                                              }
{  Seleccion y avance de atributos del editor de lineas de caja.               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorAtributosVcl;

interface

uses
  System.Classes, System.Diagnostics, System.Types, Vcl.Controls,
  Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, cxControls, cxEdit, cxDropDownEdit,
  cxGraphics, cxGridDBTableView, Uni,
  UniDataCaja, inLibParametrosIntf, inLibArticulosAtributosIntf,
  inLibLogIntf, inMtoCajaOpePresentacionVcl;

type
  TAccionSkuEditorCajaVcl = reference to procedure(const ASku: string);
  TConsultaSkuEditorCajaVcl = reference to function(
    const ASku: string): Boolean;
  TConsultaEnteroEditorCajaVcl = reference to function: Integer;
  TContextoAtributosEditorLineasCajaVcl = record
    Formulario: TCustomForm;
    DatosCaja: TdmCajaOpe;
    Conexion: TUniConnection;
    ParametrosCaja: IParametrosCaja;
    AtributosArticulos: IArticulosAtributosLookup;
    RegistroLog: IRegistroLog;
    VistaLineas: TcxGridDBTableView;
    ColumnaArticulo: TcxGridDBColumn;
    ColumnaDescripcion: TcxGridDBColumn;
    ObtenerNumeroAtributos: TConsultaEnteroEditorCajaVcl;
    RecalcularPrecio: TAccionSkuEditorCajaVcl;
    Consolidar: TConsultaSkuEditorCajaVcl;
    ValidarSku: TConsultaSkuEditorCajaVcl;
    ConsultarStock: TAccionSkuEditorCajaVcl;
    MensajeFinalizar: Cardinal;
    MensajeAvanzar: Cardinal;
    MensajeAbrirPopup: Cardinal;
    MensajeConfirmar: Cardinal;
  end;
  TSelectorAtributosEditorLineasCajaVcl = class
  private
    FContexto: TContextoAtributosEditorLineasCajaVcl;
    FCronometroPopup: TStopwatch;
    FProcesandoAtributo: Boolean;
    FConfirmacionPendiente: Boolean;
    FOrdenPendiente: Integer;
    FValorPendiente: string;
    FOpciones: array[1..5] of TArray<string>;
    function BuscarValorValido(AOrden: Integer;
      const AValor: string; out AValorCanonico: string): Boolean;
    function ObtenerOrdenEditor(AControl: TcxControl): Integer;
    procedure ProgramarConfirmacion(AOrden: Integer;
      const AValor: string);
    procedure RegistrarValor(AOrden: Integer;
      const AValorNuevo: string);
    procedure FinalizarUltimoAtributo;
  public
    constructor Create(
      const AContexto: TContextoAtributosEditorLineasCajaVcl);
    procedure IniciarMedicionPopup;
    procedure CargarOpciones(AOrden: Integer;
      const AArticulo: string;
      APropiedades: TcxComboBoxProperties);
    procedure DibujarOpcion(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
    procedure CerrarPopup(AControl: TcxControl;
      AReason: TcxEditCloseUpReason);
    procedure AbrirPopupEnEntrada(Sender: TObject);
    procedure AbrirPopupAtributo;
    procedure SeleccionarAtributo(Sender: TObject;
      AButtonIndex: Integer);
    procedure ConfirmarAtributoPendiente;
    procedure FinalizarAtributos;
    procedure AvanzarAtributo(ANumeroColumna: Integer);
  end;

implementation

uses
  Winapi.Windows, System.SysUtils,
  System.Generics.Collections, Data.DB, Vcl.Dialogs,
  cxGridTableView, inLibAtributosPaleta,
  inLibCajaVentaOperacion, inLibCajaOpePresentacion,
  inLibCajaOpePresentacionIntf, inLibMsgCaja;

constructor TSelectorAtributosEditorLineasCajaVcl.Create(
  const AContexto: TContextoAtributosEditorLineasCajaVcl);
begin
  inherited Create;
  FContexto := AContexto;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.IniciarMedicionPopup;
begin
  FCronometroPopup := TStopwatch.StartNew;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.CargarOpciones(
  AOrden: Integer; const AArticulo: string;
  APropiedades: TcxComboBoxProperties);
var
  I: Integer;
begin
  if (AOrden >= Low(FOpciones)) and
     (AOrden <= High(FOpciones)) and
     (APropiedades <> nil) then
  begin
    CargarAvsValidosArticulo(
      AArticulo,
      AOrden,
      FContexto.AtributosArticulos,
      FOpciones[AOrden]);
    APropiedades.Items.BeginUpdate;
    try
      APropiedades.Items.Clear;
      for I := 0 to High(FOpciones[AOrden]) do
        APropiedades.Items.Add(FOpciones[AOrden][I]);
    finally
      APropiedades.Items.EndUpdate;
    end;
  end;
end;

function TSelectorAtributosEditorLineasCajaVcl.BuscarValorValido(
  AOrden: Integer; const AValor: string;
  out AValorCanonico: string): Boolean;
var
  I: Integer;
  ValorBuscado: string;
begin
  Result := False;
  AValorCanonico := '';
  ValorBuscado := Trim(AValor);
  I := 0;
  if (AOrden >= Low(FOpciones)) and
     (AOrden <= High(FOpciones)) then
  begin
    while (I <= High(FOpciones[AOrden])) and not Result do
    begin
      Result := SameText(
        Trim(FOpciones[AOrden][I]),
        ValorBuscado);
      if Result then
        AValorCanonico := FOpciones[AOrden][I]
      else
        Inc(I);
    end;
  end;
end;

function TSelectorAtributosEditorLineasCajaVcl.ObtenerOrdenEditor(
  AControl: TcxControl): Integer;
var
  Columna: TcxGridColumn;
begin
  Result := 0;
  if AControl <> nil then
    Result := AControl.Tag;
  if (Result < Low(FOpciones)) or
     (Result > High(FOpciones)) then
  begin
    Columna := FContexto.VistaLineas.Controller.FocusedColumn;
    if Columna <> nil then
      Result := Columna.Tag;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.ProgramarConfirmacion(
  AOrden: Integer; const AValor: string);
begin
  if not FConfirmacionPendiente then
  begin
    FOrdenPendiente := AOrden;
    FValorPendiente := AValor;
    FConfirmacionPendiente := True;
    PostMessage(
      FContexto.Formulario.Handle,
      FContexto.MensajeConfirmar,
      0,
      0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.DibujarOpcion(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas;
  AIndex: Integer; const ARect: TRect; AState: TOwnerDrawState);
const
  LADO = 12;
  MARGEN_IZQUIERDO = 6;
  HUECO_TEXTO = 8;
var
  Articulo: string;
  Columna: TcxGridColumn;
  HayColor: Boolean;
  IdValorAtributo: string;
  Info: TInfoBasico;
  Mapa: TDictionary<string, string>;
  NombreAtributo: string;
  Orden: Integer;
  RectanguloColor: TRect;
  RectanguloTexto: TRect;
  Texto: string;
  TopColor: Integer;
begin
  if (AControl <> nil) and (ACanvas <> nil) and
     (AIndex >= 0) and
     (AIndex < AControl.ActiveProperties.Items.Count) then
  begin
    Texto := AControl.ActiveProperties.Items[AIndex];
    ACanvas.FillRect(ARect);
    Orden := ObtenerOrdenEditor(AControl);
    Articulo := '';
    NombreAtributo := '';
    if (Orden >= Low(FOpciones)) and
       (Orden <= High(FOpciones)) and
       FContexto.DatosCaja.cdsLineas.Active and
       not FContexto.DatosCaja.cdsLineas.IsEmpty then
    begin
      Articulo := FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString;
      NombreAtributo := FContexto.DatosCaja.cdsLineas.FieldByName(
        'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;
    end;
    if Trim(NombreAtributo) = '' then
    begin
      Columna := FContexto.VistaLineas.Controller.FocusedColumn;
      if (Columna <> nil) and (Columna.Tag = Orden) then
        NombreAtributo := Columna.Caption;
    end;
    IdValorAtributo := '';
    Mapa := ObtenerMapaAtributosGlobal(FContexto.Conexion);
    if Mapa <> nil then
      Mapa.TryGetValue(
        UpperCase(Trim(NombreAtributo)),
        IdValorAtributo);
    Info := Default(TInfoBasico);
    HayColor := ObtenerInfoBasicoArticulo(
      FContexto.Conexion,
      Articulo,
      IdValorAtributo,
      Texto,
      Info);
    if HayColor then
    begin
      TopColor := ARect.Top;
      if ARect.Height > LADO then
        TopColor := ARect.Top + (ARect.Height - LADO) div 2;
      RectanguloColor := Rect(
        ARect.Left + MARGEN_IZQUIERDO,
        TopColor,
        ARect.Left + MARGEN_IZQUIERDO + LADO,
        TopColor + LADO);
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := Info.Color;
      ACanvas.FillRect(RectanguloColor);
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Color := clBlack;
      ACanvas.Pen.Width := 1;
      ACanvas.Rectangle(RectanguloColor);
      RectanguloTexto := Rect(
        RectanguloColor.Right + HUECO_TEXTO,
        ARect.Top,
        ARect.Right,
        ARect.Bottom);
    end
    else
      RectanguloTexto := Rect(
        ARect.Left + MARGEN_IZQUIERDO,
        ARect.Top,
        ARect.Right,
        ARect.Bottom);
    ACanvas.Brush.Style := bsClear;
    ACanvas.DrawText(
      Texto,
      RectanguloTexto,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.CerrarPopup(
  AControl: TcxControl; AReason: TcxEditCloseUpReason);
var
  Confirmar: Boolean;
  Orden: Integer;
  ValorActual: string;
  ValorCanonico: string;
begin
  if (AControl is TcxCustomComboBox) and
     (AReason in [crClose, crEnter]) then
  begin
    Orden := ObtenerOrdenEditor(AControl);
    if BuscarValorValido(
         Orden,
         TcxCustomComboBox(AControl).Text,
         ValorCanonico) then
    begin
      Confirmar := AReason = crEnter;
      if (AReason = crClose) and
         FContexto.DatosCaja.cdsLineas.Active and
         not FContexto.DatosCaja.cdsLineas.IsEmpty then
      begin
        ValorActual := FContexto.DatosCaja.cdsLineas.FieldByName(
          'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
        Confirmar := not SameText(
          Trim(ValorActual),
          Trim(ValorCanonico));
      end;
      if Confirmar then
        ProgramarConfirmacion(Orden, ValorCanonico);
    end;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AbrirPopupEnEntrada(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  if Sender is TcxCustomEdit then
  begin
    Editor := TcxCustomEdit(Sender);
    Editor.OnEnter := nil;
    PostMessage(
      FContexto.Formulario.Handle,
      FContexto.MensajeAbrirPopup,
      0,
      0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AbrirPopupAtributo;
var
  Editor: TcxCustomEdit;
begin
  if FCronometroPopup.IsRunning then
    FCronometroPopup.Stop;
  if FContexto.VistaLineas.Controller.EditingController.IsEditing then
  begin
    Editor := FContexto.VistaLineas.Controller.EditingController.Edit;
    if (Editor is TcxComboBox) and
       (Editor.Tag >= 1) and (Editor.Tag <= 5) then
      SeleccionarAtributo(Editor, 0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.RegistrarValor(
  AOrden: Integer; const AValorNuevo: string);
var
  SkuNuevo: string;
  NumAtributosRequeridos: Integer;
begin
  if (AOrden >= 1) and (AOrden <= 5) and
     FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
  begin
    if FContexto.DatosCaja.cdsLineas.State = dsBrowse then
      FContexto.DatosCaja.cdsLineas.Edit;
    if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'ATTR' + IntToStr(AOrden) + '_VALOR').AsString := AValorNuevo;
      SkuNuevo := FContexto.DatosCaja.GenerarSkuFinal(
        FContexto.DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString);
      if Trim(SkuNuevo) = '' then
        SkuNuevo := FContexto.DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString;
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString := SkuNuevo;
      NumAtributosRequeridos :=
        FContexto.DatosCaja.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
      if SkuLineaCajaAdmitePrecio(
           SkuNuevo,
           NumAtributosRequeridos) then
        FContexto.RecalcularPrecio(SkuNuevo);
    end;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.FinalizarUltimoAtributo;
var
  SkuNuevo: string;
  EstabaInsertando: Boolean;
  Continuar: Boolean;
begin
  if not FProcesandoAtributo and
     FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
  begin
    if FContexto.VistaLineas.Controller.
       EditingController.IsEditing then
      FContexto.VistaLineas.Controller.
        EditingController.HideEdit(False);
    Continuar := True;
    FProcesandoAtributo := True;
    FContexto.DatosCaja.cdsLineas.DisableControls;
    try
      EstabaInsertando :=
        FContexto.DatosCaja.cdsLineas.State = dsInsert;
      SkuNuevo := FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString;
      if EstabaInsertando and FContexto.Consolidar(SkuNuevo) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          FContexto.DatosCaja.cdsLineas.Cancel;
        if not FContexto.DatosCaja.cdsLineas.IsEmpty and
           (FContexto.DatosCaja.cdsLineas.FieldByName(
             'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
          FContexto.DatosCaja.cdsLineas.Delete;
        FContexto.DatosCaja.cdsLineas.EnableControls;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
        FContexto.VistaLineas.Controller.
          EditingController.ShowEdit;
        Continuar := False;
      end;
      if Continuar and not FContexto.ValidarSku(SkuNuevo) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          FContexto.DatosCaja.cdsLineas.Cancel;
        if not FContexto.DatosCaja.cdsLineas.IsEmpty and
           (FContexto.DatosCaja.cdsLineas.FieldByName(
             'CODIGO_UNIDAD_FACLIN').AsString = SkuNuevo) then
          FContexto.DatosCaja.cdsLineas.Delete;
        FContexto.DatosCaja.cdsLineas.EnableControls;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
        FContexto.VistaLineas.Controller.
          EditingController.ShowEdit;
        Continuar := False;
      end;
      if Continuar then
        FContexto.ConsultarStock(SkuNuevo);
    finally
      FProcesandoAtributo := False;
      FContexto.DatosCaja.cdsLineas.EnableControls;
    end;
    if Continuar then
    begin
      if FContexto.ParametrosCaja.GetBool(
           'vgerMoverLineaIdentif', True) then
      begin
        if FContexto.DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
          FContexto.DatosCaja.cdsLineas.Post;
        FContexto.DatosCaja.cdsLineas.Append;
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaArticulo;
      end
      else
        FContexto.VistaLineas.Controller.FocusedColumn :=
          FContexto.ColumnaDescripcion;
      FContexto.VistaLineas.Controller.EditingController.ShowEdit;
    end;
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.SeleccionarAtributo(
  Sender: TObject; AButtonIndex: Integer);
var
  Columna: TcxGridColumn;
  Combo: TcxComboBox;
  Orden: Integer;
  Articulo: string;
  Propiedades: TcxComboBoxProperties;
  Continuar: Boolean;
begin
  Columna := FContexto.VistaLineas.Controller.FocusedColumn;
  Combo := nil;
  Continuar := (Columna <> nil) and (Sender is TcxComboBox);
  Orden := 0;
  if Continuar then
  begin
    Orden := Columna.Tag;
    Combo := TcxComboBox(Sender);
  end;
  Continuar := Continuar and (Orden >= 1) and (Orden <= 5) and
    FContexto.DatosCaja.cdsLineas.Active and
    not FContexto.DatosCaja.cdsLineas.IsEmpty;
  if Continuar then
  begin
    Articulo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    Propiedades := nil;
    if Columna.Properties is TcxComboBoxProperties then
      Propiedades := TcxComboBoxProperties(Columna.Properties);
    if Length(FOpciones[Orden]) = 0 then
      CargarOpciones(Orden, Articulo, Propiedades);
    if Length(FOpciones[Orden]) = 0 then
    begin
      ShowMessage(SErrorValoresAtributoCajaNoDefinidos);
      Continuar := False;
    end;
  end;
  if Continuar then
    Combo.DroppedDown := True;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.
  ConfirmarAtributoPendiente;
var
  Orden: Integer;
  Valor: string;
begin
  if FConfirmacionPendiente then
  begin
    Orden := FOrdenPendiente;
    Valor := FValorPendiente;
    FConfirmacionPendiente := False;
    FOrdenPendiente := 0;
    FValorPendiente := '';
    RegistrarValor(Orden, Valor);
    if FContexto.VistaLineas.Controller.
       EditingController.IsEditing then
      FContexto.VistaLineas.Controller.
        EditingController.HideEdit(False);
    if PasoTrasAtributoLineaCaja(
         Orden,
         FContexto.ObtenerNumeroAtributos()) = palFinalizar then
      PostMessage(
        FContexto.Formulario.Handle,
        FContexto.MensajeFinalizar,
        0,
        0)
    else
      PostMessage(
        FContexto.Formulario.Handle,
        FContexto.MensajeAvanzar,
        Orden + 1,
        0);
  end;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.FinalizarAtributos;
var
  SkuCompleto: Boolean;
begin
  SkuCompleto := False;
  if FContexto.DatosCaja.cdsLineas.Active and
     not FContexto.DatosCaja.cdsLineas.IsEmpty then
    SkuCompleto := SkuLineaCajaCompleto(
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString,
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString,
      FContexto.DatosCaja.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger);
  if SkuCompleto then
    FinalizarUltimoAtributo;
end;

procedure TSelectorAtributosEditorLineasCajaVcl.AvanzarAtributo(
  ANumeroColumna: Integer);
var
  Columna: TcxGridColumn;
  I: Integer;
begin
  Columna := nil;
  for I := 0 to FContexto.VistaLineas.ColumnCount - 1 do
  begin
    if (Columna = nil) and
       (FContexto.VistaLineas.Columns[I].Tag = ANumeroColumna) then
      Columna := FContexto.VistaLineas.Columns[I];
  end;
  if (Columna <> nil) and Columna.Visible then
  begin
    FContexto.VistaLineas.Controller.FocusedColumn := Columna;
    FContexto.VistaLineas.Controller.EditingController.ShowEdit;
  end;
end;

end.
