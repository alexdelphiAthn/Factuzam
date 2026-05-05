{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibDevExp;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, DB, ADODB, DBCtrls, StdCtrls, cxGridExportLink, dxCore,
    ExtCtrls, Grids, DBGrids, ComCtrls, Buttons, Mask,
    cxControls, cxContainer, cxEdit, System.strUtils,
    cxTextEdit, cxMaskEdit, cxDBEdit, cxNavigator, cxLookAndFeelPainters,
    cxButtons, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
    cxDBLookupComboBox, cxImage, jpeg, cxCalendar, cxStyles, cxCustomData,
    cxGraphics, cxFilter, cxData, cxDataStorage, cxDBData,
    cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridLevel,
    cxClasses, cxGridCustomView, cxGrid, cxGridCardView, cxSpinEdit,
    cxGridDBCardView, cxGridBandedTableView, cxGridDBBandedTableView,
    cxRadioGroup, inMtoPrincipal, cxPc, dxShellDialogs, inLibUser,
    cxGroupBox, cxLabel,  cxListBox, System.NetEncoding, UniDataPerfiles,
    cxCheckBox, cxMemo, cxCurrencyEdit, ExtDlgs, OleServer, AxCtrls,
    OleCtrls, DBOleCtl, cxLookAndFeels, System.Generics.Collections, TypInfo;
type
  TUpdateTotalEvent = procedure(Sender: TObject; NuevoTotal: Currency) of object;
  procedure BusqAllGrid(var dbTvGen: TcxGridDBTableView;
                        sDatoBusq: String);
  procedure GrabarGrids(frmMto: TComponent);
  function CheckOpenGrids(frmMto: TComponent):Boolean;
  procedure CancelarGrids(oPrincipal:TComponent);
  procedure SetCaseTcxTextProperty(oControl: TComponent;
                                   sCase: TEditCharCase);
//  procedure SaveColumnsStateActiveWindow;
//  procedure RecoverColumnsStateActiveWindow;
//  procedure ResetColumnsStateActiveWindow;
  procedure RestaurarFocoGrid(cxgrdtvVista: TcxGridDBTableView;
                              var oPerfilDic: TProfileDicc);
  procedure CollectSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
                                        const sName: string;
                                        const sProfile: string;
                                        AList: TPerfilList);

  procedure GetSettingsColumn(cxgrdtvVista: TcxGridDBTableView;
                              sName: String;
                              Sender: TComponent;
                              sUserGroup:String = 'Todos');
  procedure GetSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
                                      sName: String;
                                      Sender: TComponent;
                                      sProfile: String);
  procedure PonerAnchosTitulos( cxgrdtvVista: TcxGridDBTableView;
                                sDes: string;
                                var oPerfilDic: TProfileDicc);
  procedure ExportarExcel(cxGrd: TcxGrid;
                          sNomFile: string);
  procedure BusqEnTodoElGrid(AGrid: TcxGrid; sDatoBusq: String);
  procedure GridRecalc(Sender: TObject;
                       View: TcxGridDBTableView;
                       cdsLineas, cdsCabecera: TDataSet;
                       OnUpdateTotal: TUpdateTotalEvent = nil);
implementation

  uses inMtoGen,
       inLibWin,
       inLibtb,
       inLibDir,
       inLibGlobalVar, inLibAppParam, uGenericIfThen; // , DuckTypeUtilsU;

procedure GridRecalc(Sender: TObject;
                     View: TcxGridDBTableView;
                     cdsLineas, cdsCabecera: TDataSet;
                     OnUpdateTotal: TUpdateTotalEvent = nil);
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
    Edit.PostEditValue;
    ValoEditado := Edit.EditValue;
  end;
  if (View.Controller.FocusedColumn <> nil) and
     (View.Controller.FocusedColumn is TcxGridDBColumn) then
  begin
    Column := TcxGridDBColumn(View.Controller.FocusedColumn);
    FieldName := Column.DataBinding.FieldName;
    if VarIsNull(ValoEditado) or (not VarIsNumeric(ValoEditado)) then
    begin
      FieldName := 'PRECIO_SALIDA_FACLIN';
      if cdsLineas.FindField(FieldName) <> nil then
        ValoEditado := cdsLineas.FieldByName(FieldName).Value
      else
        ValoEditado := 0;
    end;
    ActualizarLineaFacturaGen(cdsLineas,
                              cdsCabecera,
                              FieldName,
                              ValoEditado,
                              OnUpdateTotal);
  end;
end;

procedure ExportarExcel(cxGrd: TcxGrid; sNomFile: string);
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
  saveDialog.FileName := sNomFile;
  //saveDialog.Options.ofOverwritePrompt := True;
  if (saveDialog.Execute)
  then
    ExportGridToXLSX(saveDialog.FileName, cxGrd);
  saveDialog.Free;
end;

procedure GetSettingsColumn(cxgrdtvVista: TcxGridDBTableView;
                            sName: String;
                            Sender: TComponent;
                            sUserGroup:String = 'Todos');
var
  i: Integer;
  oColumn: TcxGridDBColumn;
  sVistaName, sColumnName, sValue: string;
begin
  for i := 0 to cxgrdtvVista.ColumnCount - 1 do
  begin
    oColumn := cxgrdtvVista.Columns[i];
    sColumnName := oColumn.DataBinding.FieldName;
    sVistaName := cxgrdtvVista.Name;
    if (oColumn.Visible) then
      sValue := 'True'
    else
      sValue := 'False';
    odmPerfiles.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Visible',
                             sValue);
    sValue := IntToStr(oColumn.Index);
    odmPerfiles.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Index',
                             sValue);
    sValue := IntToStr(oColumn.Width);
    odmPerfiles.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Width',
                             sValue);
    sValue := oColumn.Caption;
    odmPerfiles.GrabarPerfil(sUserGroup,
                             sName,
                             sVistaName + '_' + sColumnName + '_Caption',
                             sValue);
  end;
end;

procedure RestaurarFocoGrid(cxgrdtvVista: TcxGridDBTableView;
                            var oPerfilDic: TProfileDicc);
var
  sFocusedIDString: string;
  sCamposClave: string;
  vLocateValues: Variant;
begin
  if not Assigned(cxgrdtvVista.DataController.DataSet) or
     not cxgrdtvVista.DataController.DataSet.Active then
    Exit;

  sCamposClave := cxgrdtvVista.DataController.KeyFieldNames;
  if sCamposClave = '' then
  begin
    sCamposClave := ObtenerClavePrimaria(cxgrdtvVista.DataController.DataSet);
    if sCamposClave <> '' then
      cxgrdtvVista.DataController.KeyFieldNames := sCamposClave;
  end;

  if sCamposClave = '' then Exit;

  // 1. Buscamos el string guardado (ej. "1|1500" o "45")
  sFocusedIDString := GetPerfilValueDef(oPerfilDic,
                                        cxgrdtvVista.Name + '_FocusedID', '');

  if sFocusedIDString <> '' then
  begin
    // 2. Convertimos el string al formato que necesita el Locate
    vLocateValues := StrToKeyValues(sFocusedIDString, sCamposClave);

    // 3. Movemos el cursor
    cxgrdtvVista.DataController.DataSet.Locate(
      sCamposClave,
      vLocateValues,
      []
    );
  end;
end;

procedure CollectSettingsColumnProfile(cxgrdtvVista: TcxGridDBTableView;
                                        const sName: string;
                                        const sProfile: string;
                                        AList: TPerfilList);
var
  i: Integer;
  oColumn: TcxGridDBColumn;
  sVistaName, sColumnName, sPrefix: string;
  LStream: TMemoryStream;
  BStream: TStringStream;

  procedure Add(const aSub, aVal: string);
  var item: TPerfilItem;
  begin
    item.UserGroup := sProfile;
    item.KeyPerfil := sName;
    item.SubKey    := aSub;
    item.Value     := aVal;
    // El ValueText del record lo dejamos vacío para el batch normal
    AList.Add(item);
  end;

begin
  sVistaName := cxgrdtvVista.Name;
  var sCamposClave: string;
  var vValoresClave: Variant;
  if not Assigned(cxgrdtvVista.DataController.DataSet) or
     not cxgrdtvVista.DataController.DataSet.Active then
    Exit;

  // Obtenemos la clave (con la función que vimos antes de UniDAC)
  sCamposClave := cxgrdtvVista.DataController.KeyFieldNames;
  if sCamposClave = '' then
  begin
    sCamposClave := ObtenerClavePrimaria(cxgrdtvVista.DataController.DataSet);
    if sCamposClave <> '' then
      cxgrdtvVista.DataController.KeyFieldNames := sCamposClave;
  end;

  if sCamposClave <> '' then
  begin
    vValoresClave := cxgrdtvVista.DataController.GetKeyFieldsValues;

    if not VarIsNull(vValoresClave) and not VarIsEmpty(vValoresClave) then
    begin
      // USAMOS LA NUEVA FUNCIÓN AQUÍ:
      Add(cxgrdtvVista.Name + '_FocusedID', KeyValuesToStr(vValoresClave));
    end;
  end;
  // 1. Recolección de propiedades de columnas (Para el Batch)
  for i := 0 to cxgrdtvVista.ColumnCount - 1 do
  begin
    oColumn := cxgrdtvVista.Columns[i];
    sColumnName := oColumn.DataBinding.FieldName;
    sPrefix := sVistaName + '_' + sColumnName + '_';

    Add(sPrefix + 'Visible',  TGenUtils.IfThen<String>(oColumn.Visible, 'True', 'False'));
    Add(sPrefix + 'Index',    IntToStr(oColumn.Index));
    Add(sPrefix + 'Width',    IntToStr(oColumn.Width));
    Add(sPrefix + 'Caption',  oColumn.Caption);
    Add(sPrefix + 'SortOrder', IntToStr(Ord(oColumn.SortOrder)));
    Add(sPrefix + 'SortIndex', IntToStr(oColumn.SortIndex));
  end;
  if cxgrdtvVista.DataController.Filter.IsEmpty then
  begin
    // No hay filtro: Mandamos un texto vacío para borrar cualquier filtro previo en la BBDD
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_Filtro', '', '');
  end
  else
  begin
    // 2. Grabación inmediata del Filtro (Caso especial: Texto Largo)
    LStream := TMemoryStream.Create;
    BStream := TStringStream.Create('');
    try
      cxgrdtvVista.DataController.Filter.SaveToStream(LStream);
      LStream.Position := 0;
      TNetEncoding.Base64.Encode(LStream, BStream);

      // Grabamos directamente usando tu función del DataModule
      // psValue lo pasamos vacío (''), el Base64 va a psValueText
      odmPerfiles.GrabarPerfil(sProfile,
                               sName,
                               sVistaName + '_Filtro',
                               '',
                               BStream.DataString);
    finally
      LStream.Free;
      BStream.Free;
    end;
  end;
end;

procedure GetSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
                                    sName: String;
                                    Sender: TComponent;
                                    sProfile: String);
var
  i: Integer;
  oColumn: TcxGridDBColumn;
  sVistaName, sColumnName, sValue: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
begin
  for i := 0 to cxgrdtvVista.ColumnCount - 1 do
  begin
    oColumn := cxgrdtvVista.Columns[i];
    sColumnName := oColumn.DataBinding.FieldName;
    sVistaName := cxgrdtvVista.Name;

    // 1. Guardar Visibilidad
    if (oColumn.Visible) then sValue := 'True' else sValue := 'False';
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_Visible', sValue);

    // 2. Guardar Orden (Mantenemos Index como lo tenías)
    sValue := IntToStr(oColumn.Index);
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_Index', sValue);

    // 3. Guardar Ancho
    sValue := IntToStr(oColumn.Width);
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_Width', sValue);

    // 4. Guardar Caption
    sValue := oColumn.Caption;
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_Caption', sValue);

    // 5. Guardar Ordenación de datos (Sorting)
    sValue := IntToStr(Ord(oColumn.SortOrder));
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_SortOrder', sValue);

    sValue := IntToStr(oColumn.SortIndex);
    odmPerfiles.GrabarPerfil(sProfile, sName, sVistaName + '_' + sColumnName + '_SortIndex', sValue);
  end;
  // 6. GUARDAR EL FILTRO DE LA VISTA COMPLETA (Binario -> Base64)
  LStream := TMemoryStream.Create;
  BStream := TStringStream.Create('');
  try
    // Extraemos el filtro del grid al stream de memoria
    cxgrdtvVista.DataController.Filter.SaveToStream(LStream);
    LStream.Position := 0;

    // Lo codificamos a Base64 para que sea un texto seguro (sin caracteres raros)
    TNetEncoding.Base64.Encode(LStream, BStream);
    sValue := BStream.DataString;

    // Lo guardamos en tu perfil con la clave terminada en "_Filtro"
    odmPerfiles.GrabarPerfil(sProfile, sName, cxgrdtvVista.Name + '_Filtro', sValue);
  finally
    LStream.Free;
    BStream.Free;
  end;
end;

procedure PonerAnchosTitulos(cxgrdtvVista: TcxGridDBTableView;
                             sDes: string;
                             var oPerfilDic: TProfileDicc);
var
  oColumn: TcxGridDBColumn;
  i: Integer;
  sName, sColumnName, sSubKey, sFiltroBase64: string;
  LStream: TMemoryStream;
  BStream: TStringStream;
begin
  cxgrdtvVista.BeginUpdate;
  try
    sName := cxgrdtvVista.Name;

    // 1. Restaurar Visibilidad, Caption, Ancho y Ordenación de datos
    for i := 0 to cxgrdtvVista.ColumnCount - 1 do
    begin
      oColumn := cxgrdtvVista.Columns[i];
      sColumnName := oColumn.DataBinding.FieldName;
      sSubKey := sName + '_' + sColumnName;

      oColumn.Visible := SameText(GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Visible', 'True'), 'True');
      oColumn.Caption := GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Caption', oColumn.Caption);
      oColumn.Width   := StrToIntDef(GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Width', ''), oColumn.Width);

      // Restaurar Ordenación (Sorting)
      oColumn.SortOrder := TcxDataSortOrder(StrToIntDef(GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'SortOrder', '0'), 0));
      if Ord(oColumn.SortOrder) <> 0 then
        oColumn.SortIndex := StrToIntDef(GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'SortIndex', '-1'), -1);
    end;

    // 2. Restaurar la posición física de las columnas (Index)
    for i := 0 to cxgrdtvVista.ColumnCount - 1 do
    begin
      oColumn := cxgrdtvVista.Columns[i];
      sSubKey := sName + '_' + oColumn.DataBinding.FieldName;
      oColumn.Index := StrToIntDef(GetPerfilSubKeyValueDef(oPerfilDic, sSubKey, 'Index', ''), oColumn.Index);
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
        cxgrdtvVista.DataController.Filter.LoadFromStream(LStream);
      finally
        BStream.Free;
        LStream.Free;
      end;
    end;

  finally
    cxgrdtvVista.EndUpdate;
  end;
end;

procedure BusqAllGrid(var dbTvGen: TcxGridDBTableView; sDatoBusq: String);
var
  i: Integer;
begin
  if sDatoBusq <> ''
  then
  begin
    with dbTvGen.DataController.Filter do
    begin
      BeginUpdate;
      Options := Options + [fcoCaseInsensitive];
      try
        Root.Clear;
        Root.BoolOperatorKind := fboOr;
        for i := 0 to dbTvGen.ColumnCount - 1 do
        begin
          if dbTvGen.Columns[i].DataBinding.Field <> nil then
            if dbTvGen.Columns[i].DataBinding.Field.DataType in [ftSmallint,
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
            Root.AddItem((dbTvGen.Columns[i] as TObject),
              foLike,
              '%' + sDatoBusq + '%',
              '%' + sDatoBusq + '%');
          end;
        end;
      finally
        EndUpdate;
      end;
      Active := True;
    end;
  end
  else
    dbTvGen.DataController.Filter.Root.Clear;
end;

procedure BusqEnTodoElGrid(AGrid: TcxGrid; sDatoBusq: String);
  procedure AplicarFiltroAVista(AView: TcxGridDBTableView);
  var
    i: Integer;
    bModoTemporal: Boolean; // Unifica Fecha y Hora
    sTextoBuscar: String;
    FieldType: TFieldType;
  begin
    if sDatoBusq = '' then
    begin
      AView.DataController.Filter.Root.Clear;
      AView.DataController.Filter.Active := False;
      Exit;
    end;
    // --- LÓGICA DE DETECCIÓN INTELIGENTE ---
    bModoTemporal := False;
    sTextoBuscar := sDatoBusq;
    // 1. Comodines de limpieza ("//" para fecha, "::" para hora)
    if Pos('//', sDatoBusq) > 0 then
    begin
      bModoTemporal := True;
      sTextoBuscar := StringReplace(sDatoBusq, '//', '', [rfReplaceAll]);
    end
    else if Pos('::', sDatoBusq) > 0 then
    begin
      bModoTemporal := True;
      sTextoBuscar := StringReplace(sDatoBusq, '::', '', [rfReplaceAll]);
    end
    // 2. Separadores estándar ("/" para fecha, ":" para hora)
    else if (Pos('/', sDatoBusq) > 0) or (Pos(':', sDatoBusq) > 0) then
    begin
      bModoTemporal := True;
      // Aquí NO borramos nada. Buscamos "23:00" o "12/05" tal cual.
      sTextoBuscar := sDatoBusq;
    end;
    // Si entramos en modo temporal pero no hay texto a buscar, salimos
    if bModoTemporal and (Trim(sTextoBuscar) = '') then Exit;
    with AView.DataController.Filter do
    begin
      BeginUpdate;
      try
        Options := Options + [fcoCaseInsensitive];
        Root.Clear;
        Root.BoolOperatorKind := fboOr;
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
                 Root.AddItem((AView.Columns[i] as TObject),
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
                Root.AddItem((AView.Columns[i] as TObject),
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

procedure CancelarGrids(oPrincipal:TComponent);
var
  i: Integer;
  iPrincipal:Integer;
  frmMto:TfrmMtoGen;
  frmMtoPrin2:TfrmMtoPrincipal;
  tsNew: TcxTabSheet;
begin
  frmMtoPrin2 := (oPrincipal as TfrmMtoPrincipal);
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

procedure SetCaseTcxTextProperty(oControl: TComponent; sCase: TEditCharCase);
var
  i: Integer;
begin
  for i := 0 to oControl.Componentcount - 1 do
  begin
    if oControl.Components[i].ClassNameis('TcxDBTextEdit')
    then
      (oControl.Components[i] as TcxDBTextEdit).Properties.CharCase
        := sCase;
    if oControl.Components[i].ClassNameis('TcxTextEdit')
    then
      (oControl.Components[i] as TcxTextEdit).Properties.CharCase := sCase;

    if oControl.Components[i].ClassNameis('TcxDBMaskEdit')
    then
      (oControl.Components[i] as TcxDBMaskEdit).Properties.CharCase
        := sCase;
    if oControl.Components[i].ClassNameis('TcxDBMemo')
    then
      (oControl.Components[i] as TcxDBMemo).Properties.CharCase := sCase;
    if oControl.Components[i].ClassNameis('TcxGridDBColumn')
    then
      if (oControl.Components[i] as TcxGridDBColumn).PropertiesClassName =
        ('TcxTextEditProperties')
      then
      begin
        ((oControl.Components[i] as TcxGridDBColumn).Properties as
            TcxTextEditProperties).CharCase := sCase;
      end
      else
      begin
        // ShowMessage( ((oControl.Components[i] as
        // TcxGridDBColumn).PropertiesClassName));
      end;
  end;
end;

end.
