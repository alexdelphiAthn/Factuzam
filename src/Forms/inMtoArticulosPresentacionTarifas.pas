{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionTarifas                             }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pestana de tarifas del articulo: recalculo de precios en linea, margen,   }
{    incorporacion desde el selector y alta masiva sku x tarifa. Recibe        }
{    dataset, vista y catalogos; nunca el formulario.                          }
{******************************************************************************}
unit inMtoArticulosPresentacionTarifas;

interface

uses
  System.SysUtils, System.Classes, System.Variants, System.UITypes,
  Vcl.ComCtrls, Data.DB,
  Uni,
  cxCustomData, cxEdit, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxListView,
  inLibArticulosPresentacionIntf,
  inLibMargenPersistenciaIntf;

type
  // Precio del articulo padre para una tarifa; lo resuelve el data module.
  TObtenerPrecioTarifaPadre = reference to function(
    const ACodigoArticulo, ACodigoTarifa: string): Double;
  // Rellena el selector del modal con las tarifas disponibles.
  TRellenarTarifasDisponibles = reference to procedure(
    ALista: TcxListView);
  // Aviso de que las filas de tarifa han cambiado (visibilidad de columnas).
  TTrasCambiarTarifasArticulo = reference to procedure;

  TPresentadorTarifasArticulo = class
  private
    FTarifas: TDataSet;
    FVista: TcxGridDBTableView;
    FColumnaPrecioSalida: TcxGridColumn;
    FConexion: TUniConnection;
    FCatalogo: ICatalogoAltaTarifasArticulo;
    FObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
    FRellenarTarifas: TRellenarTarifasDisponibles;
    FTrasCambiar: TTrasCambiarTarifasArticulo;
    FRepositorioMargen: IRepositorioMargen;
    function EnEdicion: Boolean;
    function ValorEditado(ASender: TObject): string;
    procedure IncorporarSeleccionadas(ALista: TcxListView);
  public
    constructor Create(
      ATarifas: TDataSet;
      AVista: TcxGridDBTableView;
      AColumnaPrecioSalida: TcxGridColumn;
      AConexion: TUniConnection;
      const ACatalogo: ICatalogoAltaTarifasArticulo;
      const AObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
      const ARellenarTarifas: TRellenarTarifasDisponibles;
      const ATrasCambiar: TTrasCambiarTarifasArticulo;
      const ARepositorioMargen: IRepositorioMargen);
    procedure RecalcularDesdePorcentajeDto(ASender: TObject);
    procedure RecalcularDesdePrecioFinal(ASender: TObject);
    procedure RecalcularDesdePrecioSalida(ASender: TObject);
    procedure RecalcularDesdePrecioDto(ASender: TObject);
    procedure MostrarMargen(ARegistro: TcxCustomGridRecord;
      var ATexto: string);
    procedure AbrirCalculadoraMargen(APropietario: TComponent);
    procedure IncorporarTarifas(APropietario: TComponent);
    procedure AltaMasivaPrecios(APropietario: TComponent;
      const ACodigoArticulo: string);
  end;

implementation

uses
  Vcl.Dialogs,
  inMtoModalArtTar,
  inMtoModalAddPreciosTar,
  inMtoModalCalcularMargen,
  inLibArticulosAltaTarifas,
  inLibArticulosPresentacion,
  inLibMsgArticulos;

constructor TPresentadorTarifasArticulo.Create(
  ATarifas: TDataSet;
  AVista: TcxGridDBTableView;
  AColumnaPrecioSalida: TcxGridColumn;
  AConexion: TUniConnection;
  const ACatalogo: ICatalogoAltaTarifasArticulo;
  const AObtenerPrecioPadre: TObtenerPrecioTarifaPadre;
  const ARellenarTarifas: TRellenarTarifasDisponibles;
  const ATrasCambiar: TTrasCambiarTarifasArticulo;
  const ARepositorioMargen: IRepositorioMargen);
begin
  inherited Create;
  if ATarifas = nil then
    raise EArgumentNilException.Create('ATarifas');
  if not Assigned(ACatalogo) then
    raise EArgumentNilException.Create('ACatalogo');
  FTarifas := ATarifas;
  FVista := AVista;
  FColumnaPrecioSalida := AColumnaPrecioSalida;
  FConexion := AConexion;
  FCatalogo := ACatalogo;
  FObtenerPrecioPadre := AObtenerPrecioPadre;
  FRellenarTarifas := ARellenarTarifas;
  FTrasCambiar := ATrasCambiar;
  if not Assigned(ARepositorioMargen) then
    raise EArgumentNilException.Create('ARepositorioMargen');
  FRepositorioMargen := ARepositorioMargen;
end;

function TPresentadorTarifasArticulo.EnEdicion: Boolean;
begin
  Result := FTarifas.State in [dsInsert, dsEdit];
end;

function TPresentadorTarifasArticulo.ValorEditado(ASender: TObject): string;
begin
  Result := VarToStr((ASender as TcxCustomEdit).EditingValue);
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePorcentajeDto(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsString :=
      ValorEditado(ASender);
    FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat :=
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat *
      (FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat / 100);
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat;
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioFinal(
  ASender: TObject);
var
  dPorcentaje: Double;
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsString :=
      ValorEditado(ASender);
    dPorcentaje := FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat;
    // Mantener el % fijo: salida = final / (1 - pct/100). Fuera de
    // (0,100) no se puede derivar la salida: fila sin descuento.
    if (dPorcentaje > 0) and (dPorcentaje < 100) then
    begin
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat :=
        FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat /
        (1 - (dPorcentaje / 100));
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat :=
        FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
        FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat;
    end
    else
    begin
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsString :=
        FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsString;
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat := 0;
      FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioSalida(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsString :=
      ValorEditado(ASender);
    FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
      FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
      FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat;
  end;
end;

procedure TPresentadorTarifasArticulo.RecalcularDesdePrecioDto(
  ASender: TObject);
begin
  if EnEdicion then
  begin
    FTarifas.FindField('PRECIO_DTO_ARTTAR').AsString :=
      ValorEditado(ASender);
    if FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat <> 0 then
    begin
      FTarifas.FindField('PORCENTAJE_DTO_ARTTAR').AsFloat :=
        (FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat /
         FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat) * 100;
      FTarifas.FindField('PRECIO_FINAL_ARTTAR').AsFloat :=
        FTarifas.FindField('PRECIO_SALIDA_ARTTAR').AsFloat -
        FTarifas.FindField('PRECIO_DTO_ARTTAR').AsFloat;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.MostrarMargen(
  ARegistro: TcxCustomGridRecord; var ATexto: string);
var
  oControlador: TcxCustomDataController;
  iRegistro: Integer;
  oItemCoste, oItemSalida: TcxCustomGridTableItem;
  vCoste, vSalida: Variant;
  dCoste, dSalida: Double;
  bLegible: Boolean;
begin
  ATexto := '';
  iRegistro := ARegistro.RecordIndex;
  oControlador := nil;
  if FVista <> nil then
    oControlador := FVista.DataController;
  if (iRegistro >= 0) and (oControlador <> nil) then
  begin
    oItemCoste := FVista.GetColumnByFieldName('PRECIO_ULT_COMPRA');
    oItemSalida := FVista.GetColumnByFieldName('PRECIO_SALIDA_ARTTAR');
    if (oItemCoste <> nil) and (oItemSalida <> nil) then
    begin
      vCoste := oControlador.Values[iRegistro, oItemCoste.Index];
      vSalida := oControlador.Values[iRegistro, oItemSalida.Index];
      bLegible := (not VarIsNull(vCoste)) and (not VarIsEmpty(vCoste)) and
                  (not VarIsNull(vSalida)) and (not VarIsEmpty(vSalida));
      if bLegible then
      begin
        dCoste := 0;
        dSalida := 0;
        try
          dCoste := vCoste;
          dSalida := vSalida;
        except
          // Valor no convertible: la columna queda sin margen visible.
          on Exception do
            bLegible := False;
        end;
        if bLegible and (dCoste > 0) then
          ATexto := FormatFloat('0.00" %"', (dSalida / dCoste) * 100);
      end;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.AbrirCalculadoraMargen(
  APropietario: TComponent);
var
  oCampoUnico: TField;
  iUnico: Integer;
  sCodigoUnidad, sCodigoArticulo, sDescripcionArticulo: string;
  sCodigoTarifa, sNombreTarifa, sDescripcionSku: string;
  dCoste, dPrecioSalida: Double;
  oResultado: TCalcularMargenResult;
begin
  if (not FTarifas.Active) or FTarifas.IsEmpty then
    ShowMessage(SErrorPrecioTarifaNoSeleccionado)
  else
  begin
    oCampoUnico := FTarifas.FindField('CODIGO_UNICO_ARTTAR');
    if (oCampoUnico = nil) or oCampoUnico.IsNull then
      ShowMessage(SErrorPrecioTarifaNoGuardado)
    else
    begin
      iUnico := oCampoUnico.AsInteger;
      sCodigoUnidad := '';
      sDescripcionArticulo := '';
      sNombreTarifa := '';
      sDescripcionSku := '';
      if FTarifas.FindField('CODIGO_UNIDAD_ARTTAR') <> nil then
        sCodigoUnidad :=
          FTarifas.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
      sCodigoArticulo := FTarifas.FieldByName('CODIGO_ART_ARTTAR').AsString;
      if FTarifas.FindField('DESCRIPCION_ART') <> nil then
        sDescripcionArticulo :=
          FTarifas.FieldByName('DESCRIPCION_ART').AsString;
      sCodigoTarifa := FTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      if FTarifas.FindField('NOMBRE_TAR_TAR') <> nil then
        sNombreTarifa := FTarifas.FieldByName('NOMBRE_TAR_TAR').AsString;
      if FTarifas.FindField('DESCRIPCION_SKU') <> nil then
        sDescripcionSku := FTarifas.FieldByName('DESCRIPCION_SKU').AsString;
      dCoste := FTarifas.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
      dPrecioSalida :=
        FTarifas.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
      oResultado := TfrmModalCalcularMargen.Ejecutar(
        APropietario, iUnico, sCodigoArticulo, sCodigoUnidad,
        sDescripcionArticulo, sCodigoTarifa, sNombreTarifa,
        sDescripcionSku, dCoste, dPrecioSalida, FRepositorioMargen);
      if oResultado.Aceptado then
      begin
        FTarifas.Refresh;
        if Assigned(FTrasCambiar) then
          FTrasCambiar();
      end;
    end;
  end;
end;

procedure TPresentadorTarifasArticulo.IncorporarSeleccionadas(
  ALista: TcxListView);
var
  bAnadida: Boolean;
  iItem: Integer;
  oItem: TListItem;
begin
  bAnadida := False;
  for iItem := 0 to ALista.Items.Count - 1 do
  begin
    oItem := ALista.Items[iItem];
    if oItem.Checked then
    begin
      // Evita duplicar: el modal consulta la BBDD y no ve las tarifas
      // aun pendientes de grabar. Si el articulo ya tiene esa tarifa a
      // nivel padre (CODIGO_UNIDAD_ARTTAR vacio) no se inserta.
      if not FTarifas.Locate('CODIGO_TAR_ARTTAR;CODIGO_UNIDAD_ARTTAR',
                             VarArrayOf([oItem.Caption, '']),
                             [loCaseInsensitive]) then
      begin
        FTarifas.Insert;
        FTarifas.FieldByName('CODIGO_TAR_ARTTAR').AsString := oItem.Caption;
        FTarifas.FieldByName('ESACTIVO_ARTTAR').AsString := 'S';
        FTarifas.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime := Now;
        FTarifas.FieldByName('PRECIO_SALIDA_ARTTAR').AsInteger := 0;
        FTarifas.FieldByName('PRECIO_FINAL_ARTTAR').AsInteger := 0;
        FTarifas.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString := '';
        FTarifas.Post;
        bAnadida := True;
      end;
    end;
  end;
  FTarifas.Refresh;
  if bAnadida and (FColumnaPrecioSalida <> nil) then
    FColumnaPrecioSalida.FocusWithSelection;
end;

procedure TPresentadorTarifasArticulo.IncorporarTarifas(
  APropietario: TComponent);
var
  oModal: TfrmMtoModalArtTar;
begin
  oModal := TfrmMtoModalArtTar.Create(APropietario);
  try
    oModal.Name := 'frmMtoModalArtTar';
    oModal.Caption := STituloSeleccionTarifasArticulo;
    if Assigned(FRellenarTarifas) then
      FRellenarTarifas(oModal.lstTarifas);
    oModal.ShowModal;
    if oModal.sFicha = 'S' then
      IncorporarSeleccionadas(oModal.lstTarifas);
  finally
    FreeAndNil(oModal);
  end;
end;

procedure TPresentadorTarifasArticulo.AltaMasivaPrecios(
  APropietario: TComponent; const ACodigoArticulo: string);
var
  oModal: TfrmMtoModalAddPreciosTar;
  iCombinacion: Integer;
  oListaTarifas: TStringList;
  oSkusSeleccionados, oTarifasSeleccionadas: TStringList;
  oCatalogoSkus: TOpcionesSkuTarifaArticulo;
  oCatalogoTarifas: TArray<string>;
  oMarca: TBookmark;
  dPrecioPadre: Double;
  oVigencia: TVigenciaTarifa;
  oExistentes: TFilasTarifaExistentes;
  oCombinaciones: TCombinacionesAltaTarifa;
  oFila: TFilaNuevaTarifa;
begin
  oModal := TfrmMtoModalAddPreciosTar.Create(APropietario);
  // Evitamos el caFree heredado para poder hacer Free manual.
  oModal.OnClose := nil;
  oListaTarifas := TStringList.Create;
  oSkusSeleccionados := TStringList.Create;
  oTarifasSeleccionadas := TStringList.Create;
  try
    oCatalogoSkus := ComponerListaSkusAltaTarifa(
      ACodigoArticulo,
      FCatalogo.ListarSkus(ACodigoArticulo));
    oModal.CargarSkus(oCatalogoSkus);
    oCatalogoTarifas := FCatalogo.ListarTarifasActivas;
    for iCombinacion := 0 to High(oCatalogoTarifas) do
      oListaTarifas.Add(oCatalogoTarifas[iCombinacion]);
    oModal.CargarTarifas(oListaTarifas);
    oModal.ShowModal;
    if oModal.sFicha = 'S' then
    begin
      oModal.ObtenerSkusSeleccionados(oSkusSeleccionados);
      oModal.ObtenerTarifasSeleccionadas(oTarifasSeleccionadas);
      oVigencia.Desde := oModal.FechaDesde;
      oVigencia.TieneHasta := oModal.TieneFechaHasta;
      if oVigencia.TieneHasta then
        oVigencia.Hasta := oModal.FechaHasta
      else
        oVigencia.Hasta := 0;
      // Las decisiones (solapamiento, ocupacion y herencia del precio
      // del padre) viven en inLibArticulosAltaTarifas; aqui queda el
      // dataset y el modal.
      FTarifas.DisableControls;
      try
        oMarca := FTarifas.GetBookmark;
        oExistentes := LeerFilasTarifaExistentes(FTarifas);
        if FTarifas.BookmarkValid(oMarca) then
          FTarifas.GotoBookmark(oMarca);
        FTarifas.FreeBookmark(oMarca);
        oCombinaciones := CalcularCombinacionesAltaTarifas(
          oSkusSeleccionados.ToStringArray,
          oTarifasSeleccionadas.ToStringArray,
          oExistentes, oVigencia);
        for iCombinacion := 0 to High(oCombinaciones) do
        begin
          if oCombinaciones[iCombinacion].EsFilaArticulo then
            dPrecioPadre := 0
          else
            dPrecioPadre := FObtenerPrecioPadre(
              ACodigoArticulo, oCombinaciones[iCombinacion].Tarifa);
          oFila := ComponerFilaNuevaTarifa(
            oCombinaciones[iCombinacion], dPrecioPadre, oVigencia);
          EscribirFilaNuevaTarifa(FTarifas, oFila);
        end;
      finally
        FTarifas.EnableControls;
      end;
      FTarifas.Refresh;
      if Assigned(FTrasCambiar) then
        FTrasCambiar();
    end;
  finally
    FreeAndNil(oSkusSeleccionados);
    FreeAndNil(oTarifasSeleccionadas);
    FreeAndNil(oListaTarifas);
    FreeAndNil(oModal);
  end;
end;

end.
