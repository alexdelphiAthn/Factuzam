{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoGeneradorProcesos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, Math,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  dxBevel, cxDBNavigator, cxGridExportLink,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, SynEditHighlighter, SynHighlighterSQL, SynEdit,
  UniDataGeneradorProcesos, cxCurrencyEdit, inMtoPrincipal,
  SynDBEdit, SynEditTypes, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, JvExComCtrls, JvDBTreeView, System.Actions, Vcl.ActnList ;

const
  ecSelColumnMode = 2577;
  ecSelLineMode = 2578;

type
  TfrmMtoGeneradorProcesos = class(TfrmMtoGen)
    pnl1: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnl2: TPanel;
    pcPestana: TcxPageControl;
    tsSQL: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    Panel1: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsVistaDatos: TcxTabSheet;
    cxgrdbclmnPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilKEY_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilSUBKEY_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnPerfilINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnPerfilUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnPerfilUSUARIOMODIF: TcxGridDBColumn;
    txtNOMBRE_FAMILIA: TcxDBTextEdit;
    cxgrdbclmnGrdDBTabPrinCODIGO_GENERADORPROCESO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_GENERADORPROCESO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxspltr1: TcxSplitter;
    pnl6: TPanel;
    pnl7: TPanel;
    synsqlsyn2: TSynSQLSyn;
    btnEjecutar: TcxButton;
    cxmResul: TcxMemo;
    tsMetadatos: TcxTabSheet;
    cxspltr2: TcxSplitter;
    pnlTabs: TPanel;
    pcMetadato: TcxPageControl;
    tsEstructura: TcxTabSheet;
    syndtEstructura: TSynEdit;
    mmo1: TMemo;
    tsContenido: TcxTabSheet;
    cxgrdMetadatos1: TcxGrid;
    tvMetadatostvVista: TcxGridDBTableView;
    tv2: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdlvlMetadatoslv11: TcxGridLevel;
    pnlTree: TPanel;
    pnlTreeBotton: TPanel;
    btRefresh: TcxButton;
    cxdbtxtdtNOMBRE_METADATO: TcxDBTextEdit;
    cxVista: TcxGrid;
    tvVista: TcxGridDBTableView;
    tv3: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA11: TcxGridDBColumn;
    lvVista: TcxGridLevel;
    tsOtros: TcxTabSheet;
    pnl3: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    cxlblUsuarioAlta: TcxLabel;
    cxlblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    cxlblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    cxlblUsuarioModif: TcxLabel;
    dbsyndtTexto: TDBSynEdit;
    pnlFacturaOpts: TPanel;
    btnExportarExcel: TcxButton;
    btnEditar: TcxButton;
    pnlFacturaOpts1: TPanel;
    btnExportarExcelMeta: TcxButton;
    btnEditarMeta: TcxButton;
    TreeView1: TTreeView;
    Panel2: TPanel;
    btnBonito: TButton;
    ActionList1: TActionList;
    ActionSeleccionar: TAction;
    ActionEjecutar: TAction;
    procedure btRefreshClick(Sender: TObject);
    procedure cxdbtxtdtNOMBRE_METADATOPropertiesChange(Sender: TObject);
    procedure btnVerDatosClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
    procedure dbsyndtTextoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure syndtEstructuraKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEditarMetaClick(Sender: TObject);
    procedure btnExportarExcelMetaClick(Sender: TObject);
    procedure dbsyndtTextoKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbsyndtTextoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TreeView1DblClick(Sender: TObject);
    procedure tsMetadatosEnter(Sender: TObject);
    procedure TreeView1Click(Sender: TObject);
    procedure btnBonitoClick(Sender: TObject);
    procedure ActionSeleccionarExecute(Sender: TObject);
    procedure ActionSeleccionarUpdate(Sender: TObject);
    procedure ActionEjecutarExecute(Sender: TObject);
  public
    procedure CargarArbol;
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoGeneradorProcesos: TfrmMtoGeneradorProcesos;
  dmmGeneradorProcesos : TdmGeneradorProcesos;
  IsColumnMode: Boolean;

implementation

uses
  inLibWin,
  inLibUser,
  inLibNet,
  inLibDevExp,
  inLibGlobalVar,
  inLibDir,
  ts.Editor.CodeFormatters;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoGeneradorProcesos.ActionEjecutarExecute(Sender: TObject);
begin
  inherited;
  btnEjecutarClick(Sender);
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarExecute(Sender: TObject);
begin
  inherited;
  if screen.ActiveControl = dbsyndtTexto then
  begin
    dbsyndtTexto.SelectAll;
    dbsyndtTexto.CopyToClipboard;
  end;
  if (screen.ActiveControl = syndtEstructura) or
     (screen.ActiveControl = TreeView1) then
  begin
    syndtEstructura.SelectAll;
    syndtEstructura.CopyToClipboard;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarUpdate(Sender: TObject);
begin
  inherited;
  (Sender as TAction).Enabled := (Screen.ActiveControl = dbsyndtTexto);
  (Sender as TAction).Enabled := (Screen.ActiveControl = syndtEstructura);
  (Sender as TAction).Enabled := (screen.ActiveControl = TreeView1);
end;

procedure TfrmMtoGeneradorProcesos.btnBonitoClick(Sender: TObject);
var
  Formatter: ICodeFormatter;
begin
  inherited;
  var sSQL := dbsyndtTexto.Lines.Text;
  sSQL := StringReplace(sSQL, '`', '', [rfReplaceAll]);
  // 3. Normalizar espacios múltiples
  while Pos('  ', sSQL) > 0 do
    sSQL := StringReplace(sSQL, '  ', ' ', [rfReplaceAll]);
  Formatter := GetSQLFormatter;
  dbsyndtTexto.Lines.Text := Formatter.Format(sSQL);
end;

procedure TfrmMtoGeneradorProcesos.btnEditarClick(Sender: TObject);
begin
  inherited;
  tvVista.OptionsData.Editing := True;
  tvVista.OptionsData.Inserting := True;
  tvVista.OptionsData.Deleting := True;
  tvVista.OptionsData.Appending := True;
end;

procedure TfrmMtoGeneradorProcesos.btnEditarMetaClick(Sender: TObject);
begin
  inherited;
  tvMetadatostvVista.OptionsData.Editing := True;
  tvMetadatostvVista.OptionsData.Inserting := True;
  tvMetadatostvVista.OptionsData.Deleting := True;
  tvMetadatostvVista.OptionsData.Appending := True;
end;

procedure TfrmMtoGeneradorProcesos.btnEjecutarClick(Sender: TObject);
var
  startTime: TDateTime;
  iRowsAffected: Integer;
  sFormatteddt, sSQL: String;
  bIsSelect: Boolean;
begin
  inherited;
  if ((dsTablaG.DataSet.State = dsInsert) or (dsTablaG.DataSet.State = dsEdit)) then
    dsTablaG.DataSet.Post;

  with dmmGeneradorProcesos do
  begin
    sSQL := unqryTablaG.FieldByName('PROCESO_GENERADORPROCESO').AsString;
    sSQL := Trim(sSQL);

    // Determinamos si es una consulta que espera filas
    // Ahora incluimos 'CALL' como potencial generador de filas
    bIsSelect := (Pos('SELECT', UpperCase(sSQL)) = 1) or
                 (Pos('CALL', UpperCase(sSQL)) = 1) or
                 (Pos('SHOW', UpperCase(sSQL)) = 1);

    if bIsSelect then
    begin
      unqryVista.Close;
      tvVista.ClearItems;
      unqryVista.SQL.Text := sSQL;
      try
        startTime := Now;
        unqryVista.Open; // Intentamos abrir como Dataset

        // Verificamos si realmente devolvió columnas (útil para CALLs que no devuelven nada)
        if unqryVista.FieldCount > 0 then
        begin
          DateTimeToString(sformatteddt, 'ss:zzz', (Now - startTime));
          cxmResul.Lines.Add('Procedimiento/Consulta ejecutada. ' +
                             IntToStr(unqryVista.RecordCount) +
                             ' registros en ' + sformatteddt + ' seg:ms');
          if (tvVista.DataController.DataSource.dataset.RecordCount > 0) then
          begin
            pcPestana.ActivePage := tsVistaDatos;
            tvVista.DataController.CreateAllItems();
            tvVista.ApplyBestFit();
          end;
        end
        else
        begin
          // Si es un CALL que no devuelve filas, se comporta como comando
          iRowsAffected := unqryVista.RowsAffected;
          cxmResul.Lines.Add('Comando ejecutado con éxito. Filas afectadas: ' + IntToStr(iRowsAffected));
        end;
      except on E: Exception do
        begin
          // Si falla el Open por no ser un SELECT/Resultset, reintentamos con ExecSQL
          try
            unqryVista.Execute;
            cxmResul.Lines.Add('Comando ejecutado correctamente (sin filas de retorno).');
          except on E2: Exception do
            begin
              cxmResul.Lines.Add('Error: ' + E2.Message);
              ShowMessage('Error en ejecución: ' + E2.Message);
            end;
          end;
        end;
      end;
    end
    else
    begin
      // Comandos directos (INSERT, UPDATE, DELETE)
      unqryCommand.SQL.Text := sSQL;
      try
        startTime := Now;
        unqryCommand.ExecSQL;
        iRowsAffected := unqryCommand.RowsAffected;
        DateTimeToString(sformatteddt, 'ss:zzz', (Now - startTime));
        cxmResul.Lines.Add('Comando ejecutado. ' + IntToStr(iRowsAffected) +
                           ' registros afectados en ' + sformatteddt + ' seg:ms');
      except on E: Exception do
        begin
          cxmResul.Lines.Add(E.Message);
          ShowMessage('Error en comando SQL: ' + E.Message);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.btnExportarExcelClick(Sender: TObject);
var
  saveDialog : tsavedialog;
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir :=  GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
  if ( saveDialog.Execute ) then
    ExportGridToXLSX(saveDialog.FileName, cxVista);
  saveDialog.Free;
end;

procedure TfrmMtoGeneradorProcesos.btnExportarExcelMetaClick(Sender: TObject);
var
  saveDialog : tsavedialog;
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Guardar listado a Excel';
  saveDialog.InitialDir :=  GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
  saveDialog.Filter := 'Archivo Excel|*.xlsx';
  saveDialog.DefaultExt := 'xlsx';
  saveDialog.FilterIndex := 1;
  if ( saveDialog.Execute ) then
    ExportGridToXLSX(saveDialog.FileName, cxgrdMetadatos1);
  saveDialog.Free;
end;

procedure TfrmMtoGeneradorProcesos.btnVerDatosClick(Sender: TObject);
begin
  inherited;
  if ((dsTablaG.DataSet.State = dsInsert) or
      (dsTablaG.DataSet.State = dsEdit)
     ) then
    dsTablaG.DataSet.Post;
 end;

procedure TfrmMtoGeneradorProcesos.btRefreshClick(Sender: TObject);
begin
  inherited;
  Screen.Cursor := crHourGlass;
  try
    with dmmGeneradorProcesos do
    begin
      unstrdprcRefresh.ParamByName('pDATABASENAME').AsString :=
                                                    oConn.Database;
      unstrdprcRefresh.ExecProc;
      if unqryMetadatos.Active = False then
        unqryMetadatos.Open
      else
        unqryMetadatos.Refresh;
    end;
    CargarArbol;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CargarArbol;
var
  nodeRaiz, nodeHijo: TTreeNode;
  sCodigo, sNombre, sParent: string;
begin
  TreeView1.Items.BeginUpdate;
  try
    TreeView1.Items.Clear;
    dmmGeneradorProcesos.unqryMetadatos.DisableControls;
    // Pasar 1: nodos raíz (PARENT = '-1')
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent := dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_METADATO').AsString;
      sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName('CODIGO_METADATO').AsString;
      if sParent = '-1' then
      begin
        nodeRaiz := TreeView1.Items.Add(nil, sNombre);
        nodeRaiz.Data := Pointer(NativeInt(StrToInt(sCodigo))); // guardamos CODIGO
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;
    // Pasar 2: nodos hijo
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent := dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_METADATO').AsString;
      sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName('CODIGO_METADATO').AsString;
      if sParent <> '-1' then
      begin
        // Buscar el nodo padre por su CODIGO
        nodeRaiz := nil;
        for var i := 0 to TreeView1.Items.Count - 1 do
          if NativeInt(TreeView1.Items[i].Data) = StrToIntDef(sParent, -1) then
          begin
            nodeRaiz := TreeView1.Items[i];
            Break;
          end;
        if nodeRaiz <> nil then
        begin
          nodeHijo := TreeView1.Items.AddChild(nodeRaiz, sNombre);
          nodeHijo.Data := Pointer(NativeInt(StrToInt(sCodigo)));
        end;
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;
//    TreeView1.FullExpand;
  finally
    dmmGeneradorProcesos.unqryMetadatos.EnableControls;
    TreeView1.Items.EndUpdate;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CrearTablaPrincipal;
var
  qry: TUniQuery;
  nodeParent, nodeChild: TTreeNode;
  i: Integer;
begin
  inherited;
  dmmGeneradorProcesos := tdmDataModule as TdmGeneradorProcesos;
  tvMetadatostvVista.DataController.DataSource :=
                                               dmmGeneradorProcesos.dsContenido;
  tvVista.DataController.DataSource := dmmGeneradorProcesos.dsVista;
  pcPestana.ActivePage := tsSQL;
  pkFieldName := 'CODIGO_GENERADORPROCESO';
  // Asegúrate de que las opciones predeterminadas estén configuradas correctamente
//  dbsyndtTexto.Options := dbsyndtTexto.Options - [eoAltSetsColumnMode];
  IsColumnMode := False;
end;

procedure TfrmMtoGeneradorProcesos.cxdbtxtdtNOMBRE_METADATOPropertiesChange(
  Sender: TObject);
var
  Formatter: ICodeFormatter; // <--- Sustituimos sExec por el interfaz del formateador
begin
  inherited;
  with dmmGeneradorProcesos do
  begin
    pcMetadato.ActivePage := tsEstructura;
    if ((unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '1')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
                         unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      unqryEstructura.Open;
      syndtEstructura.Lines.Text :=
                           unqryEstructura.FieldByName('Create Table').AsString;
    end
      else
    if ((unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '2')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
                         unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      unqryEstructura.Open;
      mmo1.Lines.Text :=
                      Trim(unqryEstructura.FieldByName('Create View').AsString);
      mmo1.Lines.Text := StringReplace(mmo1.Lines.Text,
                           'ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` '+
                           'SQL SECURITY DEFINER',
                           '',
                           [rfReplaceAll]);
      var sSQL := mmo1.Lines.Text;
      sSQL := StringReplace(sSQL, '`', '', [rfReplaceAll]);
        // 2. Quitar prefijos tabla. en los campos (fza_articulos.CAMPO -> CAMPO)
  //    Usamos un bucle simple con expresión regular o StringReplace múltiple
  //    Alternativa sin regex: quitar todo lo que sea "palabra." antes de un campo
      var i := 1;
      var sOut := '';
      var sLen := Length(sSQL);
      while i <= sLen do
      begin
        // Detectar patrón: identificador seguido de punto
        if (sSQL[i] in ['A'..'Z','a'..'z','_','0'..'9']) then
        begin
          // Leer el identificador completo
          var j := i;
          while (j <= sLen) and (sSQL[j] in ['A'..'Z','a'..'z','_','0'..'9']) do
            Inc(j);
          // ¿Le sigue un punto?
          if (j <= sLen) and (sSQL[j] = '.') then
          begin
            // Saltar el identificador y el punto (era un prefijo tabla.)
            i := j + 1;
          end
          else
          begin
            // No le sigue punto, copiar el identificador
            sOut := sOut + Copy(sSQL, i, j - i);
            i := j;
          end;
        end
        else
        begin
          sOut := sOut + sSQL[i];
          Inc(i);
        end;
      end;
      sSQL := sOut;

      // 3. Normalizar espacios múltiples
      while Pos('  ', sSQL) > 0 do
        sSQL := StringReplace(sSQL, '  ', ' ', [rfReplaceAll]);
      // --- NUEVO CÓDIGO CON LA LIBRERÍA NATIVA ---
      Formatter := GetSQLFormatter;
      syndtEstructura.Lines.Text := Formatter.Format(sSQL);
      // -------------------------------------------

    end
    else
    if ((unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '3')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
                         unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      unqryEstructura.Open;
      syndtEstructura.Lines.Text := StringReplace(unqryEstructura.FieldByName(
                                                 'Create Procedure').AsString,
                                                 ' DEFINER=`root`@`localhost`',
                                                 '',
                                                 [rfReplaceAll]);
    end
      else
        syndtEstructura.Lines.Clear;
  end;
end;

procedure TfrmMtoGeneradorProcesos.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
  if (Key = VK_F5) then
    btnEjecutarClick(Sender);
end;

procedure TfrmMtoGeneradorProcesos.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ActiveControl is TSynEdit) or (ActiveControl is TDBSynEdit) then
    Exit;
  inherited;
end;

procedure TfrmMtoGeneradorProcesos.dbsyndtTextoKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  StartLine, EndLine, i: Integer;
//  SelStart, SelEnd: TBufferCoord;
//  NewCaretX, NewCaretY: Integer;
//  s:String;
begin
  inherited;
  (*
  if Key = VK_TAB then
  begin
    dbsyndtTexto.SelText := #9; // Insertar tabulador
    Key := 0; // Prevenir que el control cambie el foco
  end;
  if (ssAlt in Shift) then
  begin
    if (ssShift in Shift) then
    begin
      if not IsColumnMode then
      begin
        IsColumnMode := True;
        dbsyndtTexto.SelectionMode := smColumn;
      end;
    end;
    // Manejar movimiento del cursor con Alt
    if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN] then
    begin
      Key := 0; // Prevenir comportamiento predeterminado
      NewCaretX := dbsyndtTexto.CaretX;
      NewCaretY := dbsyndtTexto.CaretY;
      case Key of
        VK_LEFT:  NewCaretX := Max(1, NewCaretX - 1);
        VK_RIGHT: NewCaretX := Min(Length(dbsyndtTexto.Lines[NewCaretY - 1]) + 1, NewCaretX + 1);
        VK_UP:    NewCaretY := Max(1, NewCaretY - 1);
        VK_DOWN:  NewCaretY := Min(dbsyndtTexto.Lines.Count, NewCaretY + 1);
      end;
      dbsyndtTexto.CaretXY := BufferCoord(NewCaretX, NewCaretY);
    end;
  end
  else if (ssShift in Shift) and not (ssAlt in Shift) then
  begin
    // Mantenemos el comportamiento normal de Shift
    IsColumnMode := False;
    dbsyndtTexto.SelectionMode := smNormal;
  end
  else if not (ssShift in Shift) and not (ssAlt in Shift) then
  begin
    IsColumnMode := False;
    dbsyndtTexto.SelectionMode := smNormal;
  end;
  if (Key = VK_TAB) and (dbsyndtTexto.SelAvail) then
  begin
    Key := 0; // Previene el comportamiento predeterminado del tabulador
    // Obtiene las líneas de inicio y fin de la selección
    SelStart := dbsyndtTexto.BlockBegin;
    SelEnd := dbsyndtTexto.BlockEnd;
    StartLine := SelStart.Line;
    EndLine := SelEnd.Line;
    dbsyndtTexto.BeginUpdate;
    try
      // Añade un tabulador al inicio de cada línea seleccionada
      for i := StartLine to EndLine do
      begin
        dbsyndtTexto.Lines[i - 1] := #9 + dbsyndtTexto.Lines[i - 1];
      end;
      // Ajusta la selección para incluir los tabuladores añadidos
      dbsyndtTexto.BlockBegin := BufferCoord(SelStart.Char + 1, SelStart.Line);
      dbsyndtTexto.BlockEnd := BufferCoord(SelEnd.Char + 1, SelEnd.Line);
    finally
      dbsyndtTexto.EndUpdate;
    end;
  end
  else
  begin
    if (Key = VK_TAB) and (ssShift in Shift) then
    begin
      Key := 0; // Prevenir el comportamiento predeterminado
      // Obtener las líneas de inicio y fin de la selección
      StartLine := dbsyndtTexto.BlockBegin.Line - 1;
      EndLine := dbsyndtTexto.BlockEnd.Line - 1;
      // Si no hay selección, usar la línea actual
      if StartLine = EndLine then
      begin
        StartLine := dbsyndtTexto.CaretY - 1;
        EndLine := StartLine;
      end;
      dbsyndtTexto.BeginUpdate;
      try
        for i := StartLine to EndLine do
        begin
          s := dbsyndtTexto.Lines[i];
          if (Length(s) > 0) and (s[1] = #9) then
            // Eliminar el primer tabulador
            dbsyndtTexto.Lines[i] := Copy(s, 2, Length(s))
          else if (Length(s) >= dbsyndtTexto.TabWidth) and
                  (Copy(s, 1, dbsyndtTexto.TabWidth) =
                  StringOfChar(' ', dbsyndtTexto.TabWidth)) then
            // Eliminar los espacios equivalentes a un tabulador
            dbsyndtTexto.Lines[i] :=
                                  Copy(s, dbsyndtTexto.TabWidth + 1, Length(s));
        end;
      finally
        dbsyndtTexto.EndUpdate;
      end;
    end;
  end;*)
end;

procedure TfrmMtoGeneradorProcesos.dbsyndtTextoKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  (*if not (ssAlt in Shift) and not (ssShift in Shift) then
  begin
    IsColumnMode := False;
    dbsyndtTexto.SelectionMode := smNormal;
  end; *)
end;

procedure TfrmMtoGeneradorProcesos.dbsyndtTextoMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  (*if not (ssShift in Shift) and not (ssAlt in Shift) then
  begin
    IsColumnMode := False;
    dbsyndtTexto.SelectionMode := smNormal;
  end;*)
end;

procedure TfrmMtoGeneradorProcesos.syndtEstructuraKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  (*if Key = VK_TAB then
  begin
    syndtEstructura.SelText := #9; // Insertar tabulador
    Key := 0; // Prevenir que el control cambie el foco
  end; *)
end;

procedure TfrmMtoGeneradorProcesos.TreeView1Click(Sender: TObject);
var
  nodo: TTreeNode;
  iCodigo: Integer;
begin
  nodo := TreeView1.Selected;
  if nodo = nil then Exit;
  iCodigo := NativeInt(nodo.Data);
  // Posicionar el dataset en el registro correspondiente
  dmmGeneradorProcesos.unqryMetadatos.Locate(
    'CODIGO_METADATO', iCodigo, []);
  // Ahora llama a tu lógica existente
  cxdbtxtdtNOMBRE_METADATOPropertiesChange(Sender);
end;

procedure TfrmMtoGeneradorProcesos.TreeView1DblClick(Sender: TObject);
var
  nodo: TTreeNode;
  iCodigo: Integer;
  sProcName: string;
  sCallText: string;
  qryParams: TUniQuery;
begin
  nodo := TreeView1.Selected;
  if nodo = nil then Exit;

  iCodigo := NativeInt(nodo.Data);
  dmmGeneradorProcesos.unqryMetadatos.Locate('CODIGO_METADATO', iCodigo, []);

  with dmmGeneradorProcesos do
  begin
    // Si es una Tabla (1) o Vista (2), mostramos los datos
    if ((unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '1') or
        (unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '2')) then
    begin
      pcMetadato.ActivePage := tsContenido;
      tvMetadatostvVista.ClearItems;
      unqryContenido.Close;
      unqryContenido.SQL.Text := 'SELECT * FROM ' +
                         unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      unqryContenido.Open;
      tvMetadatostvVista.DataController.CreateAllItems();
      tvMetadatostvVista.ApplyBestFit();
    end
    // Si es un Procedimiento Almacenado (3), generamos el CALL
    else if (unqryMetadatos.FieldByName('PARENT_METADATO').AsString = '3') then
    begin
      sProcName := unqryMetadatos.FieldByName('NOMBRE_METADATO').AsString;
      sCallText := 'CALL ' + sProcName + '(';

      // Creamos un TUniQuery temporal para leer los parámetros del procedimiento
      qryParams := TUniQuery.Create(nil);
      try
        // Usamos la misma conexión de tus metadatos
        qryParams.Connection := unqryMetadatos.Connection;

        // Consultamos la tabla del sistema para obtener los parámetros
        qryParams.SQL.Text :=
          'SELECT PARAMETER_NAME, DTD_IDENTIFIER ' +
          'FROM information_schema.parameters ' +
          'WHERE SPECIFIC_NAME = :ProcName AND ROUTINE_TYPE = ''PROCEDURE'' ' +
          'ORDER BY ORDINAL_POSITION';
        qryParams.ParamByName('ProcName').AsString := sProcName;
        qryParams.Open;

        // Construimos el esquema de parámetros comentados
        while not qryParams.Eof do
        begin
          sCallText := sCallText + '/* ' +
                       qryParams.FieldByName('PARAMETER_NAME').AsString + ' ' +
                       qryParams.FieldByName('DTD_IDENTIFIER').AsString + ' */';

          qryParams.Next;
          if not qryParams.Eof then
            sCallText := sCallText + ', ';
        end;
        sCallText := sCallText + ');';
      finally
        qryParams.Free;
      end;

      // Ponemos el dataset principal en modo Inserción
      if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
        dsTablaG.DataSet.Append; // Usar Append o Insert según prefieras

      // Asignamos el nombre al proceso (opcional)
      unqryTablaG.FieldByName('NOMBRE_GENERADORPROCESO').AsString := 'Ejecutar ' + sProcName;

      // Asignamos el comando SQL generado al campo memo del editor
      unqryTablaG.FieldByName('PROCESO_GENERADORPROCESO').AsString := sCallText;

      // Foco visual: cambiamos a la pestaña de SQL y damos foco al editor SynEdit
      pcPestana.ActivePage := tsSQL;
      if dbsyndtTexto.CanFocus then
        dbsyndtTexto.SetFocus;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.tsMetadatosEnter(Sender: TObject);
begin
  inherited;
  btRefreshClick(nil);
end;

initialization
  ForceReferenceToClass(TfrmMtoGeneradorProcesos);

end.
