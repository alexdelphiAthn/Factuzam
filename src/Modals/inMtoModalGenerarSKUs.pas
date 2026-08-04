{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenerarSKUs                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para generar SKUs combinando dimensiones y valores de atributos.    }
{    Hereda de AceptCancel y devuelve el conjunto de SKUs generados.           }
{******************************************************************************}
unit inMtoModalGenerarSKUs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalAceptCancel, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, System.Actions, Vcl.ActnList, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, Data.DB,
  cxControls, cxSplitter, cxStyles, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  System.Generics.Collections, cxCheckBox, System.UITypes,
  inLibGeneracionSkusPersistenciaIntf;

type
  TValorAtributo = record
    IdConjunto: Integer;
    NombreValor: string;
  end;

  TDimensionSKU = class
    IdAtributo: string;
    NombreAtributo: string;
    Valores: TList<TValorAtributo>;
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmMtoModalGenerarSKUS = class(TfrmModalAceptCancel)
    dsMaestro: TDataSource;
    dsDetalle: TDataSource;
    pnlBodyCab: TPanel;
    pnlBodyDetalle: TPanel;
    cxSplitter1: TcxSplitter;
    tvMaestro: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    cxGrid2: TcxGrid;
    tvDetalle: TcxGridDBTableView;
    cxGridLevel1: TcxGridLevel;
    tvMaestroID_ATRIBUTO_VA: TcxGridDBColumn;
    tvMaestroID_VA: TcxGridDBColumn;
    tvMaestroNOMBRE_ATRIBUTO: TcxGridDBColumn;
    tvMaestroORDEN_VA: TcxGridDBColumn;
    tvMaestroORDEN_ACA: TcxGridDBColumn;
    tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn;
    tvDetalleID_CONJUNTO_AC: TcxGridDBColumn;
    tvDetalleNOMBRE_AC: TcxGridDBColumn;
    tvDetalleASIGNADO: TcxGridDBColumn;
    btnAddValue: TcxButton;
    tvDetalleID_ATRIBUTO_VA: TcxGridDBColumn;
    tvDetalleORDEN_AV: TcxGridDBColumn;
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAddValueClick(Sender: TObject);
    procedure tvMaestroDblClick(Sender: TObject);
    procedure tvDetalleCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
  private
    FDimensiones: TObjectList<TDimensionSKU>;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FCargando: Boolean;
    FRepositorio: IRepositorioGeneracionSkus;
    FDatos: IDatosGeneracionSkus;
    FMaestro: TDataSet;
    FDetalle: TDataSet;
    procedure GenerarCombinaciones(Nivel: Integer;
                                   NombreSKU, IdsValores: string);
    procedure GuardarOrdenAtributo(const AIdAtributo: string;
                                   AOrden: Integer);
    procedure RecargarMaestro;
    function CalcularSiguienteOrdenValor(const AIdAtributo: string;
                                         AIdConjunto: Integer): Integer;
  public
    // Método para llamar a esta pantalla desde el formulario principal
    class function Ejecutar(const ACodigoArticulo,
                            ATipoVariacion: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos, UniDataConfiguracionPantalla;


procedure TfrmMtoModalGenerarSKUS.GenerarCombinaciones(Nivel: Integer;
  NombreSKU, IdsValores: string);
var
  DimActual: TDimensionSKU;
  ValActual: TValorAtributo;
  NuevoNombre, NuevosIds: string;
  CodigoNuevoSKU: string;
  ArrayIds: TArray<string>;
  IdStr: string;
  oIdsValores: TList<Integer>;
begin
  if Nivel = FDimensiones.Count then
  begin
    CodigoNuevoSKU := FCodigoArticulo + '/' + NombreSKU;
    ArrayIds := IdsValores.Split([';']);
    oIdsValores := TList<Integer>.Create;
    try
      for IdStr in ArrayIds do
      begin
        if Trim(IdStr) <> '' then
        begin
          oIdsValores.Add(StrToInt(IdStr));
        end;
      end;
      FRepositorio.GuardarSku(
        CodigoNuevoSKU,
        FCodigoArticulo,
        FTipoVariacion,
        oIdsValores.ToArray);
    finally
      FreeAndNil(oIdsValores);
    end;
  end;
  if Nivel < FDimensiones.Count then
  begin
    DimActual := FDimensiones[Nivel];
    for ValActual in DimActual.Valores do
    begin
      if NombreSKU = '' then
      begin
        NuevoNombre := ValActual.NombreValor;
      end
      else
      begin
        NuevoNombre := NombreSKU + '/' + ValActual.NombreValor;
      end;
      if IdsValores = '' then
      begin
        NuevosIds := IntToStr(ValActual.IdConjunto);
      end
      else
      begin
        NuevosIds := IdsValores + ';' + IntToStr(ValActual.IdConjunto);
      end;
      GenerarCombinaciones(Nivel + 1, NuevoNombre, NuevosIds);
    end;
  end;
end;

class function TfrmMtoModalGenerarSKUS.Ejecutar(const ACodigoArticulo,
  ATipoVariacion: string): Boolean;
var
  frm: TfrmMtoModalGenerarSKUS;
begin
  frm := TfrmMtoModalGenerarSKUS.Create(nil);
  try
    frm.FCodigoArticulo := ACodigoArticulo;
    frm.FTipoVariacion  := ATipoVariacion;
    Result := (frm.ShowModal = mrOk);
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoModalGenerarSKUS.FormShow(Sender: TObject);
begin
  ComponerConfiguracionPantalla(
    Self,
    ConexionPrincipal,
    FRepositorio);
  FDatos := FRepositorio.PrepararDatos(
    FCodigoArticulo,
    FTipoVariacion);
  FMaestro := FDatos.Maestro;
  FDetalle := FDatos.Detalle;
  dsMaestro.DataSet := FMaestro;
  dsDetalle.DataSet := FDetalle;
  tvMaestro.OnDblClick := tvMaestroDblClick;
end;

procedure TfrmMtoModalGenerarSKUS.btnAceptarClick(Sender: TObject);
var
  DimDict: TObjectDictionary<string, TDimensionSKU>;
  DimActual: TDimensionSKU;
  ValorActual: TValorAtributo;
  i: Integer;
  BmMaestro: TBookmark;
  DimensionesSinValores: TStringList;
  bValido: Boolean;
begin
  if tvMaestro.DataController.IsEditing then
    tvMaestro.DataController.Post;
  if FMaestro.State in [dsEdit, dsInsert] then
  begin
    FMaestro.Post;
  end;
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;
  if FDetalle.State in [dsEdit, dsInsert] then
  begin
    FDetalle.Post;
  end;
  if not Assigned(FDimensiones) then
    FDimensiones := TObjectList<TDimensionSKU>.Create(False);
  FDimensiones.Clear;
  DimDict := TObjectDictionary<string, TDimensionSKU>.Create([doOwnsValues]);
  try
    BmMaestro := FMaestro.GetBookmark;
    tvMaestro.BeginUpdate;
    tvDetalle.BeginUpdate;
    try
      FMaestro.First;
      while not FMaestro.Eof do
      begin
        DimActual := TDimensionSKU.Create;
        DimActual.IdAtributo :=
          FMaestro.FieldByName('ID_ATB_VA').AsString;
        DimActual.NombreAtributo :=
          FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
        DimDict.Add(DimActual.IdAtributo, DimActual);
        FDimensiones.Add(DimActual);
        FDetalle.First;
        while not FDetalle.Eof do
        begin
          if FDetalle.FieldByName('ASIGNADO').AsInteger = 1 then
          begin
            ValorActual.IdConjunto :=
              FDetalle.FieldByName('ID_AC').AsInteger;
            ValorActual.NombreValor :=
              FDetalle.FieldByName('NOMBRE_AC').AsString;
            DimActual.Valores.Add(ValorActual);
          end;
          FDetalle.Next;
        end;
        FMaestro.Next;
      end;
    finally
      if FMaestro.BookmarkValid(BmMaestro) then
      begin
        FMaestro.GotoBookmark(BmMaestro);
      end;
      FMaestro.FreeBookmark(BmMaestro);
      tvDetalle.EndUpdate;
      tvMaestro.EndUpdate;
    end;
    DimensionesSinValores := TStringList.Create;
    try
      bValido := True;
      for i := 0 to FDimensiones.Count - 1 do
        if FDimensiones[i].Valores.Count = 0 then
          DimensionesSinValores.Add(FDimensiones[i].NombreAtributo);
      if FDimensiones.Count = 0 then
      begin
        ShowMessage(SErrorDimensionesSkuNoDefinidas);
        bValido := False;
      end
      else if DimensionesSinValores.Count = FDimensiones.Count then
      begin
        ShowMessage(SErrorValoresSkuNoSeleccionados);
        bValido := False;
      end
      else if DimensionesSinValores.Count > 0 then
      begin
        ShowMessage(Format(SErrorValoresDimensionesSkuIncompletos,
          [DimensionesSinValores.CommaText]));
        bValido := False;
      end;
    finally
      FreeAndNil(DimensionesSinValores);
    end;
    if bValido then
    begin
      GenerarCombinaciones(0, '', '');
      ShowMessage(SInfoCombinacionesSkuGeneradas);
      inherited;
    end;
  finally
    FreeAndNil(DimDict);
  end;
end;

procedure TfrmMtoModalGenerarSKUS.btnCancelarClick(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

function TfrmMtoModalGenerarSKUS.CalcularSiguienteOrdenValor(
  const AIdAtributo: string; AIdConjunto: Integer): Integer;
begin
  Result := FRepositorio.CalcularSiguienteOrdenValor(
    AIdAtributo,
    AIdConjunto);
end;

procedure TfrmMtoModalGenerarSKUS.btnAddValueClick(Sender: TObject);
var
  NuevoNombre, IdAtrSel, OrdenStr, NombreConjunto: string;
  IdConjuntoAsignado, IdNuevoValor, OrdenVal, OrdenSugerido: Integer;
  Respuesta: Integer;
  oConjunto: TConjuntoAtributoSku;
  bContinuar: Boolean;
begin
  // 1. INPUTS DEL USUARIO
  NuevoNombre := Trim(InputBox(STituloAnadirValorSku,
    SSolicitudNombreValorSku, ''));
  if NuevoNombre <> '' then
  begin
    // 2. Dimension seleccionada, por ejemplo CO para Color.
    IdAtrSel := FMaestro.FieldByName('ID_ATB_VA').AsString;
    oConjunto := FRepositorio.ObtenerConjuntoAtributo(
      FCodigoArticulo,
      IdAtrSel);
    IdConjuntoAsignado := oConjunto.Id;
    NombreConjunto := oConjunto.Nombre;
    OrdenSugerido := CalcularSiguienteOrdenValor(
      IdAtrSel,
      IdConjuntoAsignado);
    OrdenStr := Trim(InputBox(
      STituloAnadirValorSku,
      SSolicitudOrdenNuevoValorSku,
      IntToStr(OrdenSugerido)));
    if OrdenStr <> '' then
    begin
      OrdenVal := StrToIntDef(OrdenStr, OrdenSugerido);
      IdNuevoValor := FRepositorio.AsegurarValor(
        IdAtrSel,
        NuevoNombre,
        OrdenVal);
      if IdConjuntoAsignado > 0 then
      begin
        Respuesta := MessageDlg(
          Format(SPreguntaGuardarValorSkuGlobal,
            [NuevoNombre, NombreConjunto]),
          mtConfirmation,
          [mbYes, mbNo, mbCancel],
          0);
        bContinuar := Respuesta <> mrCancel;
        if Respuesta = mrYes then
        begin
          FRepositorio.GuardarValorEnConjunto(
            IdConjuntoAsignado,
            IdNuevoValor,
            OrdenVal);
        end;
      end
      else
      begin
        Respuesta := MessageDlg(
          Format(SPreguntaUsarValorSkuTemporal, [NuevoNombre]),
          mtConfirmation,
          [mbYes, mbNo],
          0);
        bContinuar := Respuesta = mrYes;
      end;
      if bContinuar then
      begin
        FDetalle.Append;
        FDetalle.FieldByName('ID_ATB_VA').AsString := IdAtrSel;
        FDetalle.FieldByName('ID_AC').AsInteger := IdNuevoValor;
        FDetalle.FieldByName('NOMBRE_AC').AsString := NuevoNombre;
        if FDetalle.FindField('ORDEN_AV') <> nil then
        begin
          FDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
          FDetalle.FieldByName('ORDEN_AV').AsInteger := OrdenVal;
        end;
        FDetalle.FieldByName('ASIGNADO').AsInteger := 1;
        FDetalle.Post;
      end;
    end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.RecargarMaestro;
var
  IdAtrPrevio: string;
begin
  IdAtrPrevio := '';
  if FMaestro.Active and (not FMaestro.IsEmpty)
     and (FMaestro.FindField('ID_ATB_VA') <> nil) then
  begin
    IdAtrPrevio := FMaestro.FieldByName('ID_ATB_VA').AsString;
  end;
  FCargando := True;
  try
    FDatos.RecargarMaestro;
  finally
    FCargando := False;
  end;
  if (IdAtrPrevio <> '')
     and FMaestro.Locate('ID_ATB_VA', IdAtrPrevio, []) then
  begin
    // Se conserva el atributo que el usuario estaba editando.
  end;
end;

procedure TfrmMtoModalGenerarSKUS.GuardarOrdenAtributo(
  const AIdAtributo: string; AOrden: Integer);
begin
  FRepositorio.GuardarOrdenAtributo(
    FCodigoArticulo,
    AIdAtributo,
    AOrden);
end;

procedure TfrmMtoModalGenerarSKUS.tvDetalleCellDblClick(
  Sender: TcxCustomGridTableView; ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton; AShift: TShiftState; var AHandled: Boolean);
var
  IdVal, OrdenActual, Orden: Integer;
  NombreVal, OrdenStr, IdAtr, NombreConjunto: string;
  bGuardar: Boolean;
begin
  if FDetalle.Active and (not FDetalle.IsEmpty) then
  begin
    IdVal := FDetalle.FieldByName('ID_AC').AsInteger;
    NombreVal := FDetalle.FieldByName('NOMBRE_AC').AsString;
    OrdenActual := FDetalle.FieldByName('ORDEN_AV').AsInteger;
    IdAtr := FDetalle.FieldByName('ID_ATB_VA').AsString;
    if IdVal > 0 then
    begin
      OrdenStr := Trim(InputBox(STituloCambiarOrdenValorSku,
        Format(SSolicitudOrdenValorSku, [NombreVal]),
        IntToStr(OrdenActual)));
      if OrdenStr <> '' then
      begin
        Orden := StrToIntDef(OrdenStr, -1);
        if Orden < 0 then
          ShowMessage(SErrorOrdenValorSkuNoValido)
        else
        begin
          NombreConjunto := FRepositorio.ObtenerNombreConjunto(
            FCodigoArticulo,
            IdAtr);
          bGuardar := True;
          if Trim(NombreConjunto) <> '' then
          begin
            bGuardar := MessageDlg(
              Format(SPreguntaCambiarOrdenValorSkuGlobal,
                [NombreConjunto]),
              mtWarning,
              [mbYes, mbNo],
              0) = mrYes;
          end;
          if bGuardar then
          begin
            FRepositorio.GuardarOrdenValor(IdVal, Orden);
            FDetalle.Edit;
            FDetalle.FieldByName('ORDEN_AV').AsInteger := Orden;
            FDetalle.Post;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.tvMaestroDblClick(Sender: TObject);
var
  IdAtr, NombreAtr, OrdenStr: string;
  Orden, OrdenActual: Integer;
begin
  if FMaestro.Active and (not FMaestro.IsEmpty) then
  begin
    IdAtr := FMaestro.FieldByName('ID_ATB_VA').AsString;
    NombreAtr := FMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
    OrdenActual := FMaestro.FieldByName('ORDEN_ACA').AsInteger;
    if IdAtr <> '' then
    begin
      OrdenStr := Trim(InputBox(STituloCambiarOrdenAtributoSku,
        Format(SSolicitudOrdenAtributoSku, [NombreAtr]),
        IntToStr(OrdenActual)));
      if OrdenStr <> '' then
      begin
        Orden := StrToIntDef(OrdenStr, -1);
        if Orden <= 0 then
          ShowMessage(SErrorOrdenAtributoSkuNoValido)
        else
        begin
          GuardarOrdenAtributo(IdAtr, Orden);
          RecargarMaestro;
        end;
      end;
    end;
  end;
end;

constructor TDimensionSKU.Create;
begin
  Valores := TList<TValorAtributo>.Create;
end;

destructor TDimensionSKU.Destroy;
begin
  if Assigned(Valores) then
    FreeAndNil(Valores);
  inherited;
end;

end.
