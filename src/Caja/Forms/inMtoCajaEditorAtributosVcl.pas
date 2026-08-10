{******************************************************************************}
{                                                                              }
{  Seleccion y avance de atributos del editor de lineas de caja.               }
{                                                                              }
{******************************************************************************}
unit inMtoCajaEditorAtributosVcl;

interface

uses
  System.Classes, System.Diagnostics, Vcl.Forms, cxEdit, cxButtonEdit,
  cxGridDBTableView, Uni,
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
  end;
  TSelectorAtributosEditorLineasCajaVcl = class
  private
    FContexto: TContextoAtributosEditorLineasCajaVcl;
    FCronometroPopup: TStopwatch;
    FProcesandoAtributo: Boolean;
    procedure RegistrarValor(AOrden: Integer;
      const AValorNuevo: string);
    procedure FinalizarUltimoAtributo;
  public
    constructor Create(
      const AContexto: TContextoAtributosEditorLineasCajaVcl);
    procedure IniciarMedicionPopup;
    procedure AbrirPopupEnEntrada(Sender: TObject);
    procedure AbrirPopupAtributo;
    procedure SeleccionarAtributo(Sender: TObject;
      AButtonIndex: Integer);
    procedure FinalizarAtributos;
    procedure AvanzarAtributo(ANumeroColumna: Integer);
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Types,
  System.Generics.Collections, Data.DB, Vcl.Controls, Vcl.Dialogs,
  cxButtons, cxGridTableView, inLibAtributosPaleta,
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
    if (Editor is TcxButtonEdit) and
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
  Orden: Integer;
  Articulo: string;
  ValorActual: string;
  NombreAtributo: string;
  IdValorAtributo: string;
  ValorNuevo: string;
  Valores: TArray<string>;
  Mapa: TDictionary<string, string>;
  Editor: TWinControl;
  Punto: TPoint;
  Ancho: Integer;
  Continuar: Boolean;
begin
  Columna := FContexto.VistaLineas.Controller.FocusedColumn;
  Continuar := Columna <> nil;
  Orden := 0;
  if Continuar then
    Orden := Columna.Tag;
  Continuar := Continuar and (Orden >= 1) and (Orden <= 5) and
    FContexto.DatosCaja.cdsLineas.Active and
    not FContexto.DatosCaja.cdsLineas.IsEmpty;
  if Continuar then
  begin
    Articulo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    ValorActual := FContexto.DatosCaja.cdsLineas.FieldByName(
      'ATTR' + IntToStr(Orden) + '_VALOR').AsString;
    NombreAtributo := FContexto.DatosCaja.cdsLineas.FieldByName(
      'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString;
    CargarAvsValidosArticulo(
      Articulo,
      Orden,
      FContexto.AtributosArticulos,
      Valores);
    if Length(Valores) = 0 then
    begin
      ShowMessage(SErrorValoresAtributoCajaNoDefinidos);
      Continuar := False;
    end;
  end;
  if Continuar then
  begin
    IdValorAtributo := '';
    Mapa := ObtenerMapaAtributosGlobal(FContexto.Conexion);
    if Mapa <> nil then
      Mapa.TryGetValue(
        UpperCase(Trim(NombreAtributo)),
        IdValorAtributo);
    Punto.X := -1;
    Punto.Y := -1;
    Ancho := 120;
    if (Sender is TWinControl) and TWinControl(Sender).HasParent then
    begin
      Editor := TWinControl(Sender);
      try
        Punto := Editor.ClientToScreen(Point(0, Editor.Height));
        Ancho := Editor.Width;
      except
        on E: EInvalidOperation do
        begin
          Punto.X := -1;
          Punto.Y := -1;
          Ancho := 120;
        end;
      end;
    end;
    if SeleccionarAvConPaleta(
         FContexto.Conexion,
         IdValorAtributo,
         Valores,
         ValorActual,
         ValorNuevo,
         Punto.X,
         Punto.Y,
         Ancho,
         Articulo) then
    begin
      RegistrarValor(Orden, ValorNuevo);
      if (Sender is TcxCustomEdit) and
         TWinControl(Sender).HasParent then
      begin
        try
          TcxCustomEdit(Sender).EditValue := ValorNuevo;
        except
          on E: EInvalidOperation do
            FContexto.RegistroLog.RegistrarAviso(
              'CajaOpe: EditValue del editor inplace ignorado: ' +
              E.Message);
        end;
      end;
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
