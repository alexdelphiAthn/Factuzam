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
    Dialogs, DB, ADODB, DBCtrls, StdCtrls, cxGridExportLink,
    ExtCtrls, Grids, DBGrids, ComCtrls, Buttons, Mask,
    cxControls, cxContainer, cxEdit, inLibUser, System.strUtils,
    cxTextEdit, cxMaskEdit, cxDBEdit, cxNavigator, cxLookAndFeelPainters,
    cxButtons, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
    cxDBLookupComboBox, cxImage, jpeg, cxCalendar, cxStyles, cxCustomData,
    cxGraphics, cxFilter, cxData, cxDataStorage, cxDBData,
    cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridLevel,
    cxClasses, cxGridCustomView, cxGrid, cxGridCardView, cxSpinEdit,
    cxGridDBCardView, cxGridBandedTableView, cxGridDBBandedTableView,
    cxRadioGroup, inMtoPrincipal, cxPc, dxShellDialogs,
    cxGroupBox, cxLabel,  cxListBox, //inMtoPrincipal,
    cxCheckBox, cxMemo, cxCurrencyEdit, ExtDlgs, OleServer, AxCtrls,
    OleCtrls, DBOleCtl, cxLookAndFeels, System.Generics.Collections, TypInfo;

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

implementation

  uses inMtoGen,
       inLibWin,
       inLibtb,
       inLibDir,
       inLibGlobalVar; // , DuckTypeUtilsU;

procedure ExportarExcel(cxGrd: TcxGrid; sNomFile: string);
var
  saveDialog: TdxSaveFileDialog;
begin
  saveDialog := TdxSaveFileDialog.Create(nil);
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir := GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
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

procedure GetSettingsColumnProfile( cxgrdtvVista: TcxGridDBTableView;
                                    sName: String;
                                    Sender: TComponent;
                                    sProfile: String);
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
    if (oColumn.Visible)
    then
      sValue := 'True'
    else
      sValue := 'False';
    odmPerfiles.GrabarPerfil(sProfile, sName,
      sVistaName + '_' + sColumnName + '_Visible',
      sValue);
    sValue := IntToStr(oColumn.Index);
    (Sender as TfrmMtoPrincipal).FdmDataPerfiles.GrabarPerfil(sProfile, sName,
      sVistaName + '_' + sColumnName + '_Index',
      sValue);
    if (oColumn.Visible) then
    begin
      sValue := IntToStr(oColumn.Width);
      odmPerfiles.GrabarPerfil(sProfile, sName,
        sVistaName + '_' + sColumnName + '_Width',
        sValue);
      sValue := oColumn.Caption;
      odmPerfiles.GrabarPerfil(sProfile, sName,
        sVistaName + '_' + sColumnName + '_Caption',
        sValue);
    end;
  end;
end;

procedure PonerAnchosTitulos( cxgrdtvVista: TcxGridDBTableView;
                              sDes: string;
                              var oPerfilDic: TProfileDicc);
var
  oColumn: TcxGridDBColumn;
  i: Integer;
  sName, sColumnName, sSubKey, sProperties: string;
  IsCurrencyField,
  IsBooleanField,
  IsDateField,
  IsPercentField,
  IsIntegerField: Boolean;
begin
  for i := 0 to cxgrdtvVista.ColumnCount - 1 do
  begin
    oColumn := cxgrdtvVista.Columns[i];
    sColumnName := oColumn.DataBinding.FieldName;
    sName := cxgrdtvVista.Name;
    sSubKey := sName + '_' + sColumnName;
    oColumn.Visible :=
      StrToBool(GetPerfilSubKeyValueDef(oPerfilDic,
        sSubKey,
        'Visible',
        'True'));
    if (oColumn.Visible) then
    begin
      oColumn.Caption :=
        GetPerfilSubKeyValueDef(oPerfilDic,
        sSubKey,
        'Caption',
        oColumn.Caption);
      oColumn.Width :=
        StrToInt(GetPerfilSubKeyValueDef( oPerfilDic,
                                          sSubKey,
                                          'Width',
                                          IntToStr(oColumn.Width)
                                        ));
      // StartsText es una función inline que aporta mucho mejor rendimiento
      IsCurrencyField := (StartsText('EUR', sColumnName) or
                          StartsText('TOTAL', sColumnName) or
                          StartsText('PRECIO', sColumnName));
      if (IsCurrencyField) then
      begin
        sProperties := (GetPerfilSubKeyValueDef(oPerfilDic,
                                                sSubKey,
                                                'PropertiesClass',
                                                ''
                                               ));
        oColumn.PropertiesClassName := 'TcxCurrencyEditProperties';
      end;
      IsBooleanField := (StartsText('ES', sColumnName) or
                        (StartsText('ACTIVO', sColumnName)));
      if (IsBooleanField) then
      begin
        sProperties := (GetPerfilSubKeyValueDef(oPerfilDic,
                                                sSubKey,
                                                'PropertiesClass',
                                                ''
                                               ));
        oColumn.PropertiesClassName := 'TcxCheckBoxProperties';
        TcxCheckBoxProperties(oColumn.Properties).ValueChecked := 'S';
        TcxCheckBoxProperties(oColumn.Properties).ValueUnChecked := 'N';
      end;
      IsDateField := StartsText('FECHA', sColumnName);
      if (IsDateField) then
      begin
        sProperties := (GetPerfilSubKeyValueDef(oPerfilDic,
                                                sSubKey,
                                                'PropertiesClass',
                                                ''
                                               ));
        oColumn.PropertiesClassName := 'TcxDateEditProperties';
        TcxDateEditProperties(oColumn.Properties).Kind := ckDate;
      end;
      IsPercentField := StartsText('PORCEN', sColumnName);
      if (IsPercentField) then
      begin
        sProperties := (GetPerfilSubKeyValueDef(oPerfilDic,
                                                sSubKey,
                                                'PropertiesClass',
                                                ''
                                               ));
        oColumn.PropertiesClassName := 'TcxSpinEditProperties';
        with TcxSpinEditProperties(oColumn.Properties) do
        begin
          AssignedValues.MinValue := True;
          DisplayFormat := '0.00 %';
          EditFormat := '0.00 %';
          Increment := 0.100000000000000000;
          LargeIncrement := 1.000000000000000000;
          MaxValue := 100.000000000000000000;
          MinValue := 0;
          ValueType := vtFloat;
        end;
      end;
      IsIntegerField := ((StartsText('ORDEN', sColumnName)) or
          (StartsText('N_', sColumnName)));
      if (IsIntegerField) then
      begin
        sProperties := (GetPerfilSubKeyValueDef(oPerfilDic,
                                                sSubKey,
                                                'PropertiesClass',
                                                ''
                                               ));
        oColumn.PropertiesClassName := 'TcxSpinEditProperties';
        with TcxSpinEditProperties(oColumn.Properties) do
        begin
          AssignedValues.MinValue := True;
          DisplayFormat := '0';
          EditFormat := '0';
          Increment := 1;
          LargeIncrement := 1;
          // MaxValue := 100.000000000000000000;
          MinValue := 0;
          ValueType := vtInt;
        end;
      end;
      (* Column.PropertiesClass := TcxBlobEditProperties;
        Properties := Column.Properties AS TcxBlobEditProperties;
        Properties.BlobEditKind := bekMemo; *)
    end;
  end;
  for i := 0 to cxgrdtvVista.ColumnCount - 1 do
  begin
    oColumn := cxgrdtvVista.Columns[i];
    sColumnName := oColumn.DataBinding.FieldName;
    sName := cxgrdtvVista.Name;
    sSubKey := sName + '_' + sColumnName;
    oColumn.Index := StrToInt(GetPerfilSubKeyValueDef(oPerfilDic,
                                                      sSubKey,
                                                      'Index',
                                                    IntToStr(oColumn.Index)));
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
  for i := 0 to frmMto.Componentcount - 1 do
  begin
    if frmMto.Components[i].ClassNameis('TcxGridDBTableView')
    then
    begin
      dsData := (frmMto.Components[i] as
            TcxGridDBTableView).DataController.DataSource;
      // ShowMessage((frmMto.Components[i] as TcxGridDBTableView).Name);
      if (dsData.DataSet <> nil)
      then
        if ((dsData.DataSet.State = dsInsert) or
            (dsData.DataSet.State = dsEdit)
          )
        then
        begin
          bResul:= true;
          Exit;
        end;
    end;
  end;
  Result:=bResul;
end;

  // procedure AplicarPermisos(frmMto:TComponent);
  // var
  // i:Integer;
  // begin
  //
  // for i:= 0 to frmMto.Componentcount - 1 do
  // begin
  // if frmMto.Components[i].ClassNameis('TcxGridDBTableView') then
  // begin
  // // ShowMessage((frmMto.Components[i] as TcxGridDBTableView).Name);
  // if ( (frmMto.Components[i] as
  // TcxGridDBTableView).DataController.DataSource <> nil ) then
  // if ( ((frmMto.Components[i] as
  // TcxGridDBTableView).DataController.DataSource.DataSet.State = dsInsert) or
  // ((frmMto.Components[i]
  // as TcxGridDBTableView).DataController.DataSource.DataSet.State = dsEdit)
  // ) then
  // begin
  // ((frmMto.Components[i] as
  // TcxGridDBTableView).DataController.DataSource.DataSet as
  // TZquery).ReadOnly := True;
  // end;
  // end;
  // end;
  // end;
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

//  procedure SaveColumnsStateActiveWindow;
//    var
//      X: Integer;
//      GridTV: TcxGridDBTableView;
//      Name: string;
//      Form: Tform;
//    begin
//      Form := screen.ActiveForm;
//      Name := screen.ActiveForm.Name;
//      for X := 0 to Form.Componentcount - 1 do
//      begin
//        if (Form.Components[X] is TcxGridDBTableView)
//        then
//        begin
//          GridTV := TcxGridDBTableView(Form.Components[X]);
//          GridTV.storetoIniFile(DirIni + inLibGlobalVar.oUser + '_' +
//              Form.Caption +
//              '_' + GridTV.Name + '.ini');
//        end;
//      end;
//    end;

//  procedure RecoverColumnsStateActiveWindow;
//    var
//      X: Integer;
//      GridTV: TcxGridDBTableView;
//      Name: string;
//      Form: Tform;
//    begin
//      Form := screen.ActiveForm;
//      Name := screen.ActiveForm.Name;
//      for X := 0 to Form.Componentcount - 1 do
//      begin
//        if (Form.Components[X] is TcxGridDBTableView)
//        then
//        begin
//          GridTV := TcxGridDBTableView(Form.Components[X]);
//          If FileExists(DirIni + inLibGlobalVar.oUser + '_' +
//          Form.Caption + '_' + GridTV.Name + '.ini')
//          then
//            GridTV.RestoreFromIniFile(DirIni + inLibGlobalVar.oUser +
//                '_' + Form.Caption + '_' + GridTV.Name + '.ini');
//        end;
//      end;
//    end;

//  procedure ResetColumnsStateActiveWindow;
//    var
//      X: Integer;
//      Grid: TcxGridDBTableView;
//      Name: string;
//      Form: Tform;
//    begin
//      Form := screen.ActiveForm;
//      Name := screen.ActiveForm.Name;
//      for X := 0 to Form.Componentcount - 1 do
//      begin
//        if (Form.Components[X] is TcxGridDBTableView)
//        then
//        begin
//          Grid := TcxGridDBTableView(Form.Components[X]);
//          If FileExists(DirIni + inLibGlobalVar.oUser +
//              '_' + Form.Caption + '_' + Grid.Name + '.ini')
//          then
//            DeleteFile(DirIni + inLibGlobalVar.oUser + '_' +
//                Form.Caption + '_' + Grid.Name + '.ini');
//        end;
//      end;
//    end;

end.
