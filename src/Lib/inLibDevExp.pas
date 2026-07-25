{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevExp                                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades para componentes DevExpress (cxGrid y derivados).              }
{    Búsqueda en grids, persistencia de perfiles y manejo de columnas.         }
{******************************************************************************}
unit inLibDevExp;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, DB, ADODB, DBCtrls, StdCtrls, cxGridExportLink, dxCore,
    ExtCtrls, Grids, DBGrids, ComCtrls, Buttons, Mask,
    cxControls, cxContainer, cxEdit, System.strUtils, cxGridDBDataDefinitions,
    cxTextEdit, cxMaskEdit, cxDBEdit, cxNavigator, cxLookAndFeelPainters,
    cxButtons, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
    cxDBLookupComboBox, cxImage, jpeg, cxCalendar, cxStyles, cxCustomData,
    cxGraphics, cxFilter, cxData, cxDataStorage, cxDBData,
    cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridLevel,
    cxClasses, cxGridCustomView, cxGrid, cxGridCardView, cxSpinEdit,
    cxGridDBCardView, cxGridBandedTableView, cxGridDBBandedTableView,
    cxRadioGroup, inMtoPrincipal, cxPc, dxShellDialogs, inLibUser,
    cxGroupBox, cxLabel, cxListBox, System.NetEncoding,
    inLibPerfilesUsuarioIntf,
    cxCheckBox, cxMemo, cxCurrencyEdit, ExtDlgs, OleServer, AxCtrls,
    OleCtrls, DBOleCtl, cxLookAndFeels, System.Generics.Collections, TypInfo,
    inLibLog;
type
  TUpdateTotalEvent = procedure(Sender: TObject;
                                NuevoTotal: Currency) of object;
  procedure BusqAllGrid(var AdbTvGen: TcxGridDBTableView;
                        AsDatoBusq: String);
  procedure GrabarGrids(frmMto: TComponent);
  function CheckOpenGrids(frmMto: TComponent):Boolean;
  procedure CancelarGrids(AoPrincipal:TComponent);
  procedure SetCaseTcxTextProperty(oControl: TComponent;
                                   AsCase: TEditCharCase);
//  procedure SaveColumnsStateActiveWindow;
//  procedure RecoverColumnsStateActiveWindow;
//  procedure ResetColumnsStateActiveWindow;
  procedure RestaurarFocoGrid(AcxgrdtvVista: TcxCustomGridTableView;
                              var oPerfilDic: TProfileDicc);
  procedure CollectSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                        const sName: string;
                                        const AsProfile: string;
                                        const APerfilesUsuario:
                                          IPerfilesUsuario;
                                        AList: TPerfilList);

  procedure GetSettingsColumn(AcxgrdtvVista: TcxCustomGridTableView;
                              sName: String;
                              Sender: TComponent;
                              const APerfilesUsuario: IPerfilesUsuario;
                              sUserGroup:String = 'Todos');
  procedure GetSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                      sName: String;
                                      Sender: TComponent;
                                      const APerfilesUsuario: IPerfilesUsuario;
                                      AsProfile: String);
  procedure PonerAnchosTitulos( AcxgrdtvVista: TcxCustomGridTableView;
                                AsDes: string;
                                var oPerfilDic: TProfileDicc);
  // Asigna PropertiesClass a las columnas del view en funcion del prefijo
  // del campo, siguiendo la convencion del LIBRO_DE_ESTILO_BBDD.md §3.2.
  // Mapeo:
  //   PRECIO_  / TOTAL_ / IMPORTE_  -> TcxCurrencyEditProperties (€)
  //   PORCENTAJE_                   -> TcxCurrencyEditProperties (%)
  //   VALOR_   / CANTIDAD_          -> TcxCurrencyEditProperties (decimal)
  //   ESxxx (con TField varchar(1)) -> TcxCheckBoxProperties (S/N)
  // No toca columnas que ya traigan un PropertiesClassName distinto de
  // vacio o TcxTextEditProperties (respeta lo del .dfm). NUMERO_/LINEA_/
  // CONTADOR_ son varchar en BBDD (salen como texto, no necesitan
  // properties); ORDEN_ es int (cxGrid usa TcxSpinEditProperties por
  // defecto); FECHA_/INSTANTE_ son date/datetime (cxGrid usa
  // TcxDateEditProperties por defecto). Por eso quedan fuera.
  procedure AplicarPropertiesPorPrefijo(AView: TcxCustomGridTableView);
  procedure ExportarExcel(AcxGrd: TcxGrid;
                          AsNomFile: string);
  procedure BusqEnTodoElGrid(AGrid: TcxGrid; AsDatoBusq: String);
  procedure GridRecalc(Sender: TObject;
                       View: TcxGridDBTableView;
                       AcdsLineas, AcdsCabecera: TDataSet;
                       AOnUpdateTotal: TUpdateTotalEvent = nil);
  function GetDBDataController(
    AView: TcxCustomGridTableView): TcxGridDBDataController;
  function GetItemFieldName(AItem: TcxCustomGridTableItem): string;
  // Crea sólo las columnas para los Fields del dataset que aún no tengan
  // columna en la vista (comparación por FieldName, case-insensitive).
  // Devuelve el número de columnas nuevas creadas. Sustituye a la antigua
  // llamada directa a DataController.CreateAllItems, que duplicaba todas
  // las columnas en cada apertura del form con oCreateItems='True'.
  function CrearItemsFaltantes(AView: TcxCustomGridTableView): Integer;

implementation

  uses inMtoGen,
       inLibWin,
       inLibtb,
       inLibDir,
       inLibAppParam, uGenericIfThen,
       inLibConfigCampos;

procedure GridRecalc(Sender: TObject;
                     View: TcxGridDBTableView;
                     AcdsLineas, AcdsCabecera: TDataSet;
                     AOnUpdateTotal: TUpdateTotalEvent = nil);
var
  Edit: TcxCustomEdit;
  Column: TcxGridDBColumn;
  FieldName: string;
  ValoEditado: Variant;
begin
  ValoEditado := null;
  if (Sender is TcxCustomEdit) then
  begin
    Edit := TcxCustomEdit(Sender);
    // El editor in-place del grid puede llegar aqui sin Parent asignado
    // (transicion de celda, cierre de edicion...). PostEditValue invoca
    // HandleNeeded internamente y lanza EInvalidOperation 'no tiene
    // ventana principal' cuando Parent = nil. Si no esta parentado, dejamos
    // ValoEditado en null y el fallback de mas abajo lee del dataset.
    if Assigned(Edit.Parent) then
    begin
      Edit.PostEditValue;
      ValoEditado := Edit.EditValue;
    end;
  end;
  if (View.Controller.FocusedColumn <> nil) and
     (View.Controller.FocusedColumn is TcxGridDBColumn) then
  begin
    Column := TcxGridDBColumn(View.Controller.FocusedColumn);
    FieldName := Column.DataBinding.FieldName;
    if VarIsNull(ValoEditado) or (not VarIsNumeric(ValoEditado)) then
    begin
      FieldName := 'PRECIO_SALIDA_FACLIN';
      if AcdsLineas.FindField(FieldName) <> nil then
        ValoEditado := AcdsLineas.FieldByName(FieldName).Value
      else
        ValoEditado := 0;
    end;
    ActualizarLineaFacturaGen(AcdsLineas,
                              AcdsCabecera,
                              FieldName,
                              ValoEditado,
                              AOnUpdateTotal);
  end;
end;

procedure ExportarExcel(AcxGrd: TcxGrid; AsNomFile: string);
var
  saveDialog: TFileSaveDialog;
begin
  saveDialog := TFileSaveDialog.Create(nil);
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.DefaultFolder := oAppParams.GetPath('appDirExcel');
    with saveDialog.FileTypes.Add do
  begin
    DisplayName := 'Archivo Excel';
    FileMask := '*.xlsx';
  end;
//  saveDialog.FilterIndex := 1;
  saveDialog.FileName := AsNomFile;
  //saveDialog.Options.ofOverwritePrompt := True;
  if (saveDialog.Execute)
  then
    ExportGridToXLSX(saveDialog.FileName, AcxGrd);
  FreeAndNil(saveDialog);
end;

// Helpers para soportar tanto TcxGridDBTableView como TcxGridDBBandedTableView
// (sus columnas son TcxGridDBColumn / TcxGridDBBandedColumn, ambas con
// DataBinding tipo TcxGridItemDBDataBinding).
function GetItemFieldName(AItem: TcxCustomGridTableItem): string;
begin
  Result := '';
  if (AItem <> nil) and (AItem.DataBinding <> nil) and
     (AItem.DataBinding is TcxGridItemDBDataBinding) then
    Result := TcxGridItemDBDataBinding(AItem.DataBinding).FieldName;
end;

function GetDBDataController(
  AView: TcxCustomGridTableView): TcxGridDBDataController;
begin
  if (AView <> nil) and (AView.DataController is TcxGridDBDataController) then
    Result := TcxGridDBDataController(AView.DataController)
  else
    Result := nil;
end;

function CamposClaveDisponibles(ADataSet: TDataSet;
                                const ACamposClave: string): Boolean;
var
  Campos :TStringList;
  i      :Integer;
  sCampo :string;
begin
  Result := Assigned(ADataSet) and (Trim(ACamposClave) <> '');
  if Result then
  begin
    Campos := TStringList.Create;
    try
      Campos.StrictDelimiter := True;
      Campos.Delimiter := ';';
      Campos.DelimitedText := ACamposClave;
      i := 0;
      while Result and (i < Campos.Count) do
      begin
        sCampo := Trim(Campos[i]);
        Result := (sCampo <> '') and Assigned(ADataSet.FindField(sCampo));
        Inc(i);
      end;
    finally
      FreeAndNil(Campos);
    end;
  end;
end;

function CrearItemsFaltantes(AView: TcxCustomGridTableView): Integer;
var
  oCtrl       : TcxGridDBDataController;
  oDataSet    : TDataSet;
  oExistentes : TDictionary<string, Boolean>;
  i           : Integer;
  sField      : string;
  oCol        : TcxCustomGridTableItem;
begin
  Result := 0;
  oCtrl := GetDBDataController(AView);
  if (oCtrl <> nil) and Assigned(oCtrl.DataSource) then
  begin
    oDataSet := oCtrl.DataSource.DataSet;
    if Assigned(oDataSet) then
    begin
      oExistentes := TDictionary<string, Boolean>.Create;
      try
        // Recolectar FieldName ya presentes en la vista (case-insensitive)
        for i := 0 to AView.ItemCount - 1 do
        begin
          sField := GetItemFieldName(AView.Items[i]);
          if sField <> '' then
            oExistentes.AddOrSetValue(UpperCase(sField), True);
        end;
        // Crear sólo las columnas para los Fields que no estén ya
        for i := 0 to oDataSet.FieldCount - 1 do
        begin
          sField := oDataSet.Fields[i].FieldName;
          if not oExistentes.ContainsKey(UpperCase(sField)) then
          begin
            oCol := nil;
            if AView is TcxGridDBBandedTableView then
              oCol := TcxGridDBBandedTableView(AView).CreateColumn
            else if AView is TcxGridDBTableView then
              oCol := TcxGridDBTableView(AView).CreateColumn;
            if (oCol <> nil) and (oCol.DataBinding <> nil) and
               (oCol.DataBinding is TcxGridItemDBDataBinding) then
            begin
              TcxGridItemDBDataBinding(oCol.DataBinding).FieldName := sField;
              oExistentes.AddOrSetValue(UpperCase(sField), True);
              Inc(Result);
            end;
          end;
        end;
      finally
        FreeAndNil(oExistentes);
      end;
    end;
  end;
  Log.LogInfo(Format('CrearItemsFaltantes: vista=%s creadas=%d items_total=%d',
                     [AView.Name, Result, AView.ItemCount]));
end;

// Helpers locales para AplicarPropertiesPorPrefijo
function EsCampoBooleanoSN(AField: TField): Boolean;
begin
  // Booleano S/N de Factuzam: varchar(1). En UniDAC puede mapear a
  // ftString o ftFixedChar. En ambos casos Size=1.
  Result := Assigned(AField) and
            (AField.DataType in [ftString, ftFixedChar, ftWideString,
                                 ftFixedWideChar]) and
            (AField.Size = 1);
end;

procedure SetCurrencyProps(ACol: TcxGridDBColumn;
                           const AFormato: string);
var
  cp: TcxCurrencyEditProperties;
begin
  ACol.PropertiesClass := TcxCurrencyEditProperties;
  cp := TcxCurrencyEditProperties(ACol.Properties);
  cp.DisplayFormat               := AFormato;
  cp.UseDisplayFormatWhenEditing := True;
end;

procedure SetCheckBoxProps(ACol: TcxGridDBColumn);
var
  cb: TcxCheckBoxProperties;
begin
  ACol.PropertiesClass := TcxCheckBoxProperties;
  cb := TcxCheckBoxProperties(ACol.Properties);
  cb.ValueChecked   := 'S';
  cb.ValueUnchecked := 'N';
  cb.ValueGrayed    := '';
  cb.NullStyle      := nssUnchecked;
end;

procedure AplicarPropertiesPorPrefijo(AView: TcxCustomGridTableView);
const
  // Prefijos monetarios (€)
  PRE_DINERO: array[0..2] of string = ('PRECIO_', 'TOTAL_', 'IMPORTE_');
  // Prefijo porcentaje (%)
  PRE_PORC: array[0..0] of string = ('PORCENTAJE_');
  // Prefijos numericos sin moneda
  PRE_NUM: array[0..1] of string = ('VALOR_', 'CANTIDAD_');
  // Formatos con sufijo de moneda/porcentaje fijo
  FMT_EURO  = '#,##0.00 "€";-#,##0.00 "€";0.00 "€"';
  FMT_PORC  = '#,##0.00 "%";-#,##0.00 "%";0.00 "%"';
  FMT_NUM   = '#,##0.##;-#,##0.##;0';

  function CampoEmpiezaPor(const AField: string;
                           const APrefijos: array of string): Boolean;
  var
    p: string;
  begin
    Result := False;
    for p in APrefijos do
      if (not Result) and StartsText(p, AField) then
        Result := True;
  end;

  function EsPrefijoES(const AField: string): Boolean;
  begin
    // Booleano: 'ES' seguido de mayuscula (ESACTIVO, ESDEFECTO, ESVIP...).
    // No queremos confundir con campos que casualmente empiecen por 'es'
    // pero no sean booleanos. Adicionalmente se valida con
    // EsCampoBooleanoSN que el tipo subyacente sea varchar(1).
    Result := (Length(AField) >= 3) and
              (UpCase(AField[1]) = 'E') and
              (UpCase(AField[2]) = 'S') and
              CharInSet(AField[3], ['A'..'Z']);
  end;

var
  i: Integer;
  oItem: TcxCustomGridTableItem;
  oCol: TcxGridDBColumn;
  sField, sProp: string;
  oField: TField;
  oDBCtrl: TcxGridDBDataController;
  bAplicable: Boolean;
begin
  if AView <> nil then
  begin
    oDBCtrl := GetDBDataController(AView);
    AView.BeginUpdate;
    try
      for i := 0 to AView.ItemCount - 1 do
      begin
        oItem := AView.Items[i];
        if (oItem is TcxGridDBColumn) then
        begin
          oCol := TcxGridDBColumn(oItem);
          sField := GetItemFieldName(oCol);
          sProp := oCol.PropertiesClassName;
          // Solo aplicamos si la columna no tiene properties especificas
          // ya asignadas (no pisamos lo que venga del .dfm o de otra
          // rutina externa).
          bAplicable := (sField <> '') and
                        ((sProp = '') or (sProp = 'TcxTextEditProperties'));
          if bAplicable then
          begin
            if EsPrefijoES(sField) then
            begin
              // ESxxx -> CheckBox S/N (solo si el TField es varchar(1))
              oField := nil;
              if (oDBCtrl <> nil) and Assigned(oDBCtrl.DataSet) then
                oField := oDBCtrl.DataSet.FindField(sField);
              if EsCampoBooleanoSN(oField) then
                SetCheckBoxProps(oCol);
            end
            else if CampoEmpiezaPor(sField, PRE_DINERO) then
              SetCurrencyProps(oCol, FMT_EURO)
            else if CampoEmpiezaPor(sField, PRE_PORC) then
              SetCurrencyProps(oCol, FMT_PORC)
            else if CampoEmpiezaPor(sField, PRE_NUM) then
              SetCurrencyProps(oCol, FMT_NUM);
          end;
        end;
      end;
    finally
      AView.EndUpdate;
    end;
  end;
end;

procedure GetSettingsColumn(AcxgrdtvVista: TcxCustomGridTableView;
                            sName: String;
                            Sender: TComponent;
                            const APerfilesUsuario: IPerfilesUsuario;
                            sUserGroup:String = 'Todos');
var
  i: Integer;
  oItem: TcxGridColumn ;
  sVistaName, sColumnName, sValue: string;
begin
  sVistaName := AcxgrdtvVista.Name;
  for i := 0 to AcxgrdtvVista.ItemCount - 1 do
  begin
    oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
    sColumnName := GetItemFieldName(oItem);
    if sColumnName = '' then Continue;
    if (oItem.Visible) then
      sValue := 'True'
    else
      sValue := 'False';
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Visible',
                             sValue);
    sValue := IntToStr(oItem.Index);
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Index',
                             sValue);
    sValue := IntToStr(oItem.Width);
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Width',
                             sValue);
    sValue := oItem.Caption;
    APerfilesUsuario.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Caption',
                             sValue);
    if oItem is TcxGridDBBandedColumn then
    begin
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_BandIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_ColIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
      APerfilesUsuario.GrabarPerfil(sUserGroup, sName,
        sVistaName + '_' + sColumnName + '_RowIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
    end;
  end;
end;

procedure RestaurarFocoGrid(AcxgrdtvVista: TcxCustomGridTableView;
                            var oPerfilDic: TProfileDicc);
var
  sFocusedIDString: string;
  sCamposClave: string;
  vLocateValues: Variant;
  oDBDataCtrl: TcxGridDBDataController;
  bFound: Boolean;
begin
  oDBDataCtrl := GetDBDataController(AcxgrdtvVista);
  if (oDBDataCtrl = nil) or
     not Assigned(oDBDataCtrl.DataSet) or
     not oDBDataCtrl.DataSet.Active then
  begin
    Log.LogInfo(Format('RestaurarFocoGrid: vista=%s SKIP (dataset no activo)',
      [AcxgrdtvVista.Name]));
    Exit;
  end;

  sCamposClave := oDBDataCtrl.KeyFieldNames;
  if (sCamposClave <> '') and
     (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
  begin
    Log.LogWarning(Format('RestaurarFocoGrid: vista=%s clave="%s" ' +
      'no disponible en la SELECT activa',
      [AcxgrdtvVista.Name, sCamposClave]));
    oDBDataCtrl.KeyFieldNames := '';
    sCamposClave := '';
  end;
  if sCamposClave = '' then
  begin
    sCamposClave := ObtenerClavePrimaria(oDBDataCtrl.DataSet);
    if (sCamposClave <> '') and
       CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave) then
      oDBDataCtrl.KeyFieldNames := sCamposClave;
    if (sCamposClave <> '') and
       (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
    begin
      Log.LogWarning(Format('RestaurarFocoGrid: vista=%s clave="%s" ' +
        'descartada porque faltan campos',
        [AcxgrdtvVista.Name, sCamposClave]));
      sCamposClave := '';
    end;
  end;

  if sCamposClave = '' then
  begin
    Log.LogWarning(Format('RestaurarFocoGrid: vista=%s SKIP (sin clave primaria)',
      [AcxgrdtvVista.Name]));
    Exit;
  end;

  sFocusedIDString := GetPerfilValueDef(oPerfilDic,
                                        AcxgrdtvVista.Name + '_FocusedID', '');

  Log.LogInfo(Format('RestaurarFocoGrid: vista=%s clave="%s" valorGuardado="%s"',
    [AcxgrdtvVista.Name, sCamposClave, sFocusedIDString]));

  if sFocusedIDString <> '' then
  begin
    vLocateValues := StrToKeyValues(sFocusedIDString, sCamposClave);
    bFound := oDBDataCtrl.DataSet.Locate(
      sCamposClave,
      vLocateValues,
      []
    );
    Log.LogInfo(Format('RestaurarFocoGrid: Locate(%s, %s) = %s',
      [sCamposClave, sFocusedIDString, BoolToStr(bFound, True)]));
  end;
end;

procedure CollectSettingsColumnProfile(AcxgrdtvVista: TcxCustomGridTableView;
                                        const sName: string;
                                        const AsProfile: string;
                                        const APerfilesUsuario:
                                          IPerfilesUsuario;
                                        AList: TPerfilList);
var
  i: Integer;
  oItem: TcxGridColumn;
  sVistaName, sColumnName, sPrefix: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
  oDBDataCtrl: TcxGridDBDataController;

  procedure Add(const aSub, aVal: string);
  var item: TPerfilItem;
  begin
    item.UserGroup := AsProfile;
    item.KeyPerfil := sName;
    item.SubKey    := aSub;
    item.Value     := aVal;
    // El ValueText del record lo dejamos vacío para el batch normal
    AList.Add(item);
  end;

begin
  sVistaName := AcxgrdtvVista.Name;
  var sCamposClave: string;
  var vValoresClave: Variant;
  oDBDataCtrl := GetDBDataController(AcxgrdtvVista);
  if (oDBDataCtrl = nil) or
     not Assigned(oDBDataCtrl.DataSet) or
     not oDBDataCtrl.DataSet.Active then
    Exit;

  // Obtenemos la clave (con la función que vimos antes de UniDAC)
  sCamposClave := oDBDataCtrl.KeyFieldNames;
  if (sCamposClave <> '') and
     (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
  begin
    Log.LogWarning(Format('CollectSettingsColumnProfile: vista=%s ' +
      'clave="%s" no disponible en la SELECT activa',
      [AcxgrdtvVista.Name, sCamposClave]));
    oDBDataCtrl.KeyFieldNames := '';
    sCamposClave := '';
  end;
  if sCamposClave = '' then
  begin
    sCamposClave := ObtenerClavePrimaria(oDBDataCtrl.DataSet);
    if (sCamposClave <> '') and
       CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave) then
      oDBDataCtrl.KeyFieldNames := sCamposClave;
    if (sCamposClave <> '') and
       (not CamposClaveDisponibles(oDBDataCtrl.DataSet, sCamposClave)) then
    begin
      Log.LogWarning(Format('CollectSettingsColumnProfile: vista=%s ' +
        'clave="%s" descartada porque faltan campos',
        [AcxgrdtvVista.Name, sCamposClave]));
      sCamposClave := '';
    end;
  end;

  if sCamposClave <> '' then
  begin
    vValoresClave := oDBDataCtrl.GetKeyFieldsValues;

    if not VarIsNull(vValoresClave) and not VarIsEmpty(vValoresClave) then
    begin
      // USAMOS LA NUEVA FUNCIÓN AQUÍ:
      Add(AcxgrdtvVista.Name + '_FocusedID', KeyValuesToStr(vValoresClave));
    end;
  end;
  // 1. Recolección de propiedades de columnas (Para el Batch)
  for i := 0 to AcxgrdtvVista.ItemCount - 1 do
  begin
    oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
    sColumnName := GetItemFieldName(oItem);
    if sColumnName = '' then Continue;
    sPrefix := sVistaName + '_' + sColumnName + '_';

    Add(sPrefix + 'Visible',
        TGenUtils.IfThen<String>(oItem.Visible, 'True', 'False'));
    Add(sPrefix + 'Index',    IntToStr(oItem.Index));
    Add(sPrefix + 'Width',    IntToStr(oItem.Width));
    Add(sPrefix + 'Caption',  oItem.Caption);
    Add(sPrefix + 'SortOrder', IntToStr(Ord(oItem.SortOrder)));
    Add(sPrefix + 'SortIndex', IntToStr(oItem.SortIndex));
    if oItem is TcxGridDBBandedColumn then
    begin
      Add(sPrefix + 'BandIndex',
          IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
      Add(sPrefix + 'ColIndex',
          IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
      Add(sPrefix + 'RowIndex',
          IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
    end;
  end;
  if AcxgrdtvVista.DataController.Filter.IsEmpty then
  begin
    // No hay filtro: Mandamos un texto vacío para borrar cualquier filtro
    // previo en la BBDD
    APerfilesUsuario.GrabarPerfil(
      AsProfile,
      sName,
      sVistaName + '_Filtro',
      '',
      '');
  end
  else
  begin
    // 2. Grabación inmediata del Filtro (Caso especial: Texto Largo)
    LStream := TMemoryStream.Create;
    BStream := TStringStream.Create('');
    try
      AcxgrdtvVista.DataController.Filter.SaveToStream(LStream);
      LStream.Position := 0;
      TNetEncoding.Base64.Encode(LStream, BStream);

      // Grabamos directamente usando tu función del DataModule
      // psValue lo pasamos vacío (''), el Base64 va a psValueText
      APerfilesUsuario.GrabarPerfil(
        AsProfile,
        sName,
        sVistaName + '_Filtro',
        '',
        BStream.DataString);
    finally
      FreeAndNil(LStream);
      FreeAndNil(BStream);
    end;
  end;
end;

procedure GetSettingsColumnProfile( AcxgrdtvVista: TcxCustomGridTableView;
                                    sName: String;
                                    Sender: TComponent;
                                    const APerfilesUsuario:
                                      IPerfilesUsuario;
                                    AsProfile: String);
var
  i: Integer;
  oItem: TcxGridColumn;
  sVistaName, sColumnName, sValue: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
begin
  sVistaName := AcxgrdtvVista.Name;
  for i := 0 to AcxgrdtvVista.ItemCount - 1 do
  begin
    oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
    sColumnName := GetItemFieldName(oItem);
    if sColumnName = '' then Continue;

    // 1. Guardar Visibilidad
    if (oItem.Visible) then sValue := 'True' else sValue := 'False';
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Visible',
                             sValue);

    // 2. Guardar Orden (Mantenemos Index como lo tenías)
    sValue := IntToStr(oItem.Index);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Index',
                             sValue);

    // 3. Guardar Ancho
    sValue := IntToStr(oItem.Width);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Width',
                             sValue);

    // 4. Guardar Caption
    sValue := oItem.Caption;
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_Caption',
                             sValue);

    // 5. Guardar Ordenación de datos (Sorting)
    sValue := IntToStr(Ord(oItem.SortOrder));
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_SortOrder',
                             sValue);

    sValue := IntToStr(oItem.SortIndex);
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             sVistaName + '_' + sColumnName + '_SortIndex',
                             sValue);

    // 6. Si es columna banded, guardar tambien la posicion en band
    if oItem is TcxGridDBBandedColumn then
    begin
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_BandIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.BandIndex));
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_ColIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.ColIndex));
      APerfilesUsuario.GrabarPerfil(AsProfile, sName,
        sVistaName + '_' + sColumnName + '_RowIndex',
        IntToStr(TcxGridDBBandedColumn(oItem).Position.RowIndex));
    end;
  end;
  // 6. GUARDAR EL FILTRO DE LA VISTA COMPLETA (Binario -> Base64)
  LStream := TMemoryStream.Create;
  BStream := TStringStream.Create('');
  try
    // Extraemos el filtro del grid al stream de memoria
    AcxgrdtvVista.DataController.Filter.SaveToStream(LStream);
    LStream.Position := 0;

    // Lo codificamos a Base64 para que sea un texto seguro (sin caracteres
    // raros)
    TNetEncoding.Base64.Encode(LStream, BStream);
    sValue := BStream.DataString;

    // Lo guardamos en tu perfil con la clave terminada en "_Filtro"
    APerfilesUsuario.GrabarPerfil(AsProfile,
                             sName,
                             AcxgrdtvVista.Name + '_Filtro',
                             sValue);

    // Guardar el ancho general del componente TcxGrid contenedor
    if Assigned(AcxgrdtvVista.Control) then
    begin
      sValue := IntToStr(AcxgrdtvVista.Control.Width);
      APerfilesUsuario.GrabarPerfil(AsProfile,
                               sName,
                               AcxgrdtvVista.Name + '_GridTotalWidth',
                               sValue);
    end;
  finally
    FreeAndNil(LStream);
    FreeAndNil(BStream);
  end;
end;

procedure PonerAnchosTitulos(AcxgrdtvVista: TcxCustomGridTableView;
                             AsDes: string;
                             var oPerfilDic: TProfileDicc);
var
  oItem: TcxGridColumn;
  i, iIdx, iBand, iCol, iRow: Integer;
  sName, sColumnName, sSubKey, sFiltroBase64, sVal: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
  iMaxIdx: Integer;
  oBanded: TcxGridDBBandedColumn;
  oBandedView: TcxGridDBBandedTableView;
  iMaxBands: Integer;
begin
  AcxgrdtvVista.BeginUpdate;
  try
    sName := AcxgrdtvVista.Name;
    iMaxIdx := AcxgrdtvVista.ItemCount - 1;
    Log.LogInfo(Format('PonerAnchosTitulos: vista=%s items=%d form=%s',
                       [sName, AcxgrdtvVista.ItemCount, AsDes]));

    // 1. Restaurar Visibilidad, Caption, Ancho y Ordenación de datos
    for i := 0 to AcxgrdtvVista.ItemCount - 1 do
    begin
      oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
      sColumnName := GetItemFieldName(oItem);
      if sColumnName = '' then
        Continue;
      sSubKey := sName + '_' + sColumnName;
      oItem.Visible := SameText(
        GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Visible', 'True'),
        'True');
      // Caption: perfil usuario > config_campos > design-time
      sVal := GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Caption', '');
      if sVal <> '' then
        oItem.Caption := sVal
      else if Assigned(oConfigCampos) and oConfigCampos.Cargada and
              (oConfigCampos.ObtenerTitulo(sColumnName) <> '') then
        oItem.Caption := oConfigCampos.ObtenerTitulo(sColumnName);
      // Ancho: perfil usuario > config_campos > design-time
      sVal := GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Width', '');
      if sVal <> '' then
        oItem.Width := StrToIntDef(sVal, oItem.Width)
      else if Assigned(oConfigCampos) and oConfigCampos.Cargada and
              (oConfigCampos.ObtenerAncho(sColumnName) > 0) then
        oItem.Width := oConfigCampos.ObtenerAncho(sColumnName);
      oItem.SortOrder := TcxDataSortOrder(StrToIntDef(
        GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'SortOrder', '0'), 0));
      if Ord(oItem.SortOrder) <> 0 then
        oItem.SortIndex := StrToIntDef(
          GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'SortIndex', '-1'), -1);
    end;

    // 2. Restaurar la posición física de las columnas (Index).
    // Para banded grids, el Index general puede causar desorden si el
    // perfil tiene columnas que ya no existen; en ese caso solo aplicamos
    // BandIndex/ColIndex/RowIndex (paso 3) y dejamos el Index original.
    if not (AcxgrdtvVista is TcxGridDBBandedTableView) then
    begin
      for i := 0 to AcxgrdtvVista.ItemCount - 1 do
      begin
        oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
        sColumnName := GetItemFieldName(oItem);
        if sColumnName = '' then
          Continue;
        sSubKey := sName + '_' + sColumnName;
        sVal := GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Index', '');
        if sVal = '' then
          Continue;
        iIdx := StrToIntDef(sVal, oItem.Index);
        if iIdx > iMaxIdx then
        begin
          Log.LogWarning(Format(
            '  columna %s: Index guardado=%d > max=%d, ajustado',
            [sColumnName, iIdx, iMaxIdx]));
          iIdx := iMaxIdx;
        end;
        if iIdx < 0 then
          iIdx := 0;
        oItem.Index := iIdx;
      end;
    end;

    // 3. Para columnas banded, restaurar Position.BandIndex / ColIndex /
    // RowIndex con protección contra índices fuera de rango.
    iMaxBands := 0;
    if AcxgrdtvVista is TcxGridDBBandedTableView then
      iMaxBands := TcxGridDBBandedTableView(AcxgrdtvVista).Bands.Count;
    for i := 0 to AcxgrdtvVista.ItemCount - 1 do
    begin
      oItem := AcxgrdtvVista.Items[i] as TcxGridColumn;
      sColumnName := GetItemFieldName(oItem);
      if sColumnName = '' then
        Continue;
      if not (oItem is TcxGridDBBandedColumn) then
        Continue;
      oBanded := TcxGridDBBandedColumn(oItem);
      sSubKey := sName + '_' + sColumnName;
      iBand := StrToIntDef(
        GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'BandIndex', ''),
        oBanded.Position.BandIndex);
      iCol  := StrToIntDef(
        GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'ColIndex',  ''),
        oBanded.Position.ColIndex);
      iRow  := StrToIntDef(
        GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'RowIndex',  ''),
        oBanded.Position.RowIndex);
      // Protección contra BandIndex inválido
      if (iMaxBands > 0) and (iBand >= iMaxBands) then
      begin
        Log.LogWarning(Format(
          '  columna banded %s: BandIndex=%d >= bands=%d, ajustado a %d',
          [sColumnName, iBand, iMaxBands, iMaxBands - 1]));
        iBand := iMaxBands - 1;
      end;
      if iBand < 0 then
        iBand := 0;
      if iCol < 0 then
        iCol := 0;
      if iRow < 0 then
        iRow := 0;
      Log.LogInfo(Format('  banded %s: band=%d col=%d row=%d',
                         [sColumnName, iBand, iCol, iRow]));
      oBanded.Position.BandIndex := iBand;
      oBanded.Position.ColIndex  := iCol;
      oBanded.Position.RowIndex  := iRow;
    end;

    // 3. Restaurar el Filtro (Desde VALUE_TEXT_USUPER)
    // Se requiere una función que lea el ValueText del diccionario
    sFiltroBase64 := GetPerfilValueTextDef(oPerfilDic, sName + '_Filtro', '');

    if sFiltroBase64 <> '' then
    begin
      BStream := TStringStream.Create(sFiltroBase64);
      LStream := TMemoryStream.Create;
      try
        BStream.Position := 0;
        System.NetEncoding.TNetEncoding.Base64.Decode(BStream, LStream);
        LStream.Position := 0;
        AcxgrdtvVista.DataController.Filter.LoadFromStream(LStream);
      finally
        FreeAndNil(BStream);
        FreeAndNil(LStream);
      end;
    end;

    // Restaurar el ancho general del componente TcxGrid contenedor
    if Assigned(AcxgrdtvVista.Control) then
    begin
      sSubKey := AcxgrdtvVista.Name + '_GridTotalWidth';
      AcxgrdtvVista.Control.Width :=
                         StrToIntDef(GetPerfilValueDef(oPerfilDic, sSubKey, ''),
                                     AcxgrdtvVista.Control.Width);
    end;
  finally
    AcxgrdtvVista.EndUpdate;
  end;
end;

procedure BusqAllGrid(var AdbTvGen: TcxGridDBTableView; AsDatoBusq: String);
var
  i: Integer;
  oListaBusqueda: TcxFilterCriteriaItemList;
begin
  if AsDatoBusq <> ''
  then
  begin
    with AdbTvGen.DataController.Filter do
    begin
      BeginUpdate;
      Options := Options + [fcoCaseInsensitive];
      try
        Root.Clear;
        Root.BoolOperatorKind := fboAnd;
        oListaBusqueda := Root.AddItemList(fboOr);
        for i := 0 to AdbTvGen.ColumnCount - 1 do
        begin
          if AdbTvGen.Columns[i].DataBinding.Field <> nil then
            if AdbTvGen.Columns[i].DataBinding.Field.DataType in [ftSmallint,
                                                                 ftInteger,
                                                                 ftWord,
                                                                 ftCurrency,
                                                                 ftBCD,
                                                                 ftLargeint,
                                                                 ftFMTBcd,
                                                                 ftLongWord,
                                                                 ftShortint,
                                                                 ftString,
                                                                 ftWideString,
                                                                 ftMemo,
                                                                 ftFmtMemo,
                                                                 ftWideMemo]
          then
          begin
            oListaBusqueda.AddItem((AdbTvGen.Columns[i] as TObject),
              foLike,
              '%' + AsDatoBusq + '%',
              '%' + AsDatoBusq + '%');
          end;
        end;
      finally
        EndUpdate;
      end;
      Active := True;
    end;
  end
  else
  begin
    AdbTvGen.DataController.Filter.Root.Clear;
    AdbTvGen.DataController.Filter.Root.BoolOperatorKind := fboAnd;
  end;
end;

procedure BusqEnTodoElGrid(AGrid: TcxGrid; AsDatoBusq: String);
  procedure AplicarFiltroAVista(AView: TcxGridDBTableView);
  var
    i: Integer;
    bModoTemporal: Boolean; // Unifica Fecha y Hora
    sTextoBuscar: String;
    FieldType: TFieldType;
    oListaBusqueda: TcxFilterCriteriaItemList;
  begin
    if AsDatoBusq = '' then
    begin
      AView.DataController.Filter.Root.Clear;
      AView.DataController.Filter.Root.BoolOperatorKind := fboAnd;
      AView.DataController.Filter.Active := False;
      Exit;
    end;
    // --- LÓGICA DE DETECCIÓN INTELIGENTE ---
    bModoTemporal := False;
    sTextoBuscar := AsDatoBusq;
    // 1. Comodines de limpieza ("//" para fecha, "::" para hora)
    if Pos('//', AsDatoBusq) > 0 then
    begin
      bModoTemporal := True;
      sTextoBuscar := StringReplace(AsDatoBusq, '//', '', [rfReplaceAll]);
    end
    else if Pos('::', AsDatoBusq) > 0 then
    begin
      bModoTemporal := True;
      sTextoBuscar := StringReplace(AsDatoBusq, '::', '', [rfReplaceAll]);
    end
    // 2. Separadores estándar ("/" para fecha, ":" para hora)
    else if (Pos('/', AsDatoBusq) > 0) or (Pos(':', AsDatoBusq) > 0) then
    begin
      bModoTemporal := True;
      // Aquí NO borramos nada. Buscamos "23:00" o "12/05" tal cual.
      sTextoBuscar := AsDatoBusq;
    end;
    // Si entramos en modo temporal pero no hay texto a buscar, salimos
    if bModoTemporal and (Trim(sTextoBuscar) = '') then Exit;
    with AView.DataController.Filter do
    begin
      BeginUpdate;
      try
        Options := Options + [fcoCaseInsensitive];
        Root.Clear;
        Root.BoolOperatorKind := fboAnd;
        oListaBusqueda := Root.AddItemList(fboOr);
        for i := 0 to AView.ColumnCount - 1 do
        begin
          if (AView.Columns[i].DataBinding.Field <> nil) then
          begin
            FieldType := AView.Columns[i].DataBinding.Field.DataType;
            if bModoTemporal then
            begin
              // MODO TEMPORAL: Busca en Fechas, Horas y FechaHoras
              if FieldType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
              begin
                 oListaBusqueda.AddItem((AView.Columns[i] as TObject),
                    foLike,
                    '%' + sTextoBuscar + '%',
                    '%' + sTextoBuscar + '%');
              end;
            end
            else
            begin
              // MODO TEXTO/NUMÉRICO: Lo habitual
              if FieldType in [
                 ftSmallint, ftInteger, ftWord, ftCurrency, ftBCD, ftLargeint,
                 ftFMTBcd, ftLongWord, ftShortint, ftString, ftWideString,
                 ftMemo, ftFmtMemo, ftWideMemo] then
              begin
                oListaBusqueda.AddItem((AView.Columns[i] as TObject),
                  foLike,
                  '%' + sTextoBuscar + '%',
                  '%' + sTextoBuscar + '%');
              end;
            end;
          end;
        end;
      finally
        EndUpdate;
      end;
      Active := True;
    end;
  end;
  procedure ProcesarNivel(ALevel: TcxGridLevel);
  var
    i: Integer;
  begin
    if (ALevel.GridView <> nil) and (ALevel.GridView is TcxGridDBTableView) then
      AplicarFiltroAVista(TcxGridDBTableView(ALevel.GridView));
    for i := 0 to ALevel.Count - 1 do
      ProcesarNivel(ALevel.Items[i]);
  end;
var
  i: Integer;
begin
  if AGrid = nil then Exit;
  AGrid.BeginUpdate;
  try
    for i := 0 to AGrid.Levels.Count - 1 do
      ProcesarNivel(AGrid.Levels[i]);
  finally
    AGrid.EndUpdate;
  end;
end;

procedure CancelarGrids(AoPrincipal:TComponent);
var
  i: Integer;
  iPrincipal:Integer;
  frmMto:TfrmMtoGen;
  frmMtoPrin2:TfrmMtoPrincipal;
  tsNew: TcxTabSheet;
begin
  frmMtoPrin2 := (AoPrincipal as TfrmMtoPrincipal);
  iPrincipal := frmMtoPrin2.pcPrincipal.ActivePageIndex;
  tsNew := frmMtoPrin2.pcPrincipal.Pages[iPrincipal];
  frmMto := (tsNew.Controls[0] as TfrmMtoGen);
  for i := 0 to frmMto.Componentcount - 1 do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      // ShowMessage((frmMto.Components[i] as TcxGridDBTableView).Name);
      with ((frmMto.Components[i] as TcxGridDBTableView).DataController) do
      if ((DataSource <> nil) and
           ((DataSet.State = dsInsert) or
            (DataSet.State = dsEdit))) then
      begin
          //poner aquí un mensaje para preguntar al usuario
        DataSet.Cancel;
      end;
    end;
  end;
end;

procedure GrabarGrids(frmMto: TComponent);
var
  i: Integer;
  dsData:TDataSource;
begin
  for i := 0 to frmMto.Componentcount - 1 do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      dsData := (frmMto.Components[i] as
            TcxGridDBTableView).DataController.DataSource;
      // ShowMessage((frmMto.Components[i] as TcxGridDBTableView).Name);
      if (dsData <> nil)
      then
        if ((dsData.DataSet.State = dsInsert) or
            (dsData.DataSet.State = dsEdit)
          )
        then
        begin
          dsData.DataSet.Post;
        end;
    end;
  end;
end;

function CheckOpenGrids(frmMto: TComponent):Boolean;
var
  i: Integer;
  dsData:TDataSource;
  bResul:Boolean;
begin
  bResul:= False;
  i:= 0;
  while ((i<frmMto.Componentcount) and (bResul = False)) do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      dsData := (frmMto.Components[i] as
            TcxGridDBTableView).DataController.DataSource;
      // ShowMessage((frmMto.Components[i] as TcxGridDBTableView).Name);
      if dsData <> nil then
        if (dsData.DataSet <> nil)
        then
          if ((dsData.DataSet.State = dsInsert) or
              (dsData.DataSet.State = dsEdit)) then
          begin
            bResul:= true;
            //Exit;
          end;
    end;
    Inc(i);
  end;
  Result:=bResul;
end;

procedure SetCaseTcxTextProperty(oControl: TComponent; AsCase: TEditCharCase);
var
  i: Integer;
begin
  for i := 0 to oControl.Componentcount - 1 do
  begin
    if oControl.Components[i].ClassNameis('TcxDBTextEdit')
    then
      (oControl.Components[i] as TcxDBTextEdit).Properties.CharCase
        := AsCase;
    if oControl.Components[i].ClassNameis('TcxTextEdit')
    then
      (oControl.Components[i] as TcxTextEdit).Properties.CharCase := AsCase;

    if oControl.Components[i].ClassNameis('TcxDBMaskEdit')
    then
      (oControl.Components[i] as TcxDBMaskEdit).Properties.CharCase
        := AsCase;
    if oControl.Components[i].ClassNameis('TcxDBMemo')
    then
      (oControl.Components[i] as TcxDBMemo).Properties.CharCase := AsCase;
    if oControl.Components[i].ClassNameis('TcxGridDBColumn')
    then
      if (oControl.Components[i] as TcxGridDBColumn).PropertiesClassName =
        ('TcxTextEditProperties')
      then
      begin
        ((oControl.Components[i] as TcxGridDBColumn).Properties as
            TcxTextEditProperties).CharCase := AsCase;
      end
      else
      begin
        // ShowMessage( ((oControl.Components[i] as
        // TcxGridDBColumn).PropertiesClassName));
      end;
  end;
end;

end.
