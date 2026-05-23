{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGeneradorProcesos                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generador de procesos parametrizables.                                    }
{    Editor SQL y ejecucion de procesos almacenados sobre la BD.               }
{******************************************************************************}
unit inMtoGeneradorProcesos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, Math, strUtils, DAScript,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, System.Generics.Collections,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  dxBevel, cxDBNavigator, cxGridExportLink, SynEditSearch,
  dxDateRanges, MemDS, DBAccess, Uni, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, SynEditHighlighter, SynHighlighterSQL, SynEdit, UniScript,
  UniDataGeneradorProcesos, cxCurrencyEdit, SynEditKeyCmds,
  SynDBEdit, SynEditTypes, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, JvExComCtrls, JvDBTreeView, System.Actions, Vcl.ActnList, System.UITypes,
  dxBarBuiltInMenu;

const
  ecSelColumnMode = 2577;
  ecSelLineMode = 2578;

type
  TfrmMtoGeneradorProcesos = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
    pcPestana: TcxPageControl;
    tsSQL: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlInnerHeader: TPanel;
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
    splArbolMeta: TcxSplitter;
    pnlInferior: TPanel;
    pnlScriptOuter: TPanel;
    synsqlsyn2: TSynSQLSyn;
    btnEjecutar: TcxButton;
    cxmResul: TcxMemo;
    tsMetadatos: TcxTabSheet;
    splDetalleMeta: TcxSplitter;
    pnlTabs: TPanel;
    pcMetadato: TcxPageControl;
    tsEstructura: TcxTabSheet;
    mmoSalida: TMemo;
    tsContenido: TcxTabSheet;
    cxgrdMetadatos1: TcxGrid;
    tvMetadatostvVista: TcxGridDBTableView;
    tvVistaDatos: TcxGridDBTableView;
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
    btnRefresh: TcxButton;
    cxVista: TcxGrid;
    tvVista: TcxGridDBTableView;
    tvVistaContenido: TcxGridDBTableView;
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
    pnlBotonera: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    cxlblUsuarioAlta: TcxLabel;
    cxlblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    cxlblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    cxlblUsuarioModif: TcxLabel;
    pnlFacturaOpts: TPanel;
    btnExportarExcel: TcxButton;
    btnEditar: TcxButton;
    pnlFacturaOpts1: TPanel;
    btnExportarExcelMeta: TcxButton;
    btnEditarMeta: TcxButton;
    tvMetadatos: TTreeView;
    pnlSidePanel: TPanel;
    btnBonito: TButton;
    alGenerador: TActionList;
    ActionSeleccionar: TAction;
    ActionEjecutar: TAction;
    lblAyudaSeleccion: TcxLabel;
    pnlMetadatosBody: TPanel;
    syndtEstructura: TSynEdit;
    sbVertDerecho: TScrollBar;
    sbVertCentro: TScrollBar;
    DBSynEdit1: TDBSynEdit;
    actComentar: TAction;
    btnAbrirScript: TcxButton;
    actAbrirScript: TAction;
    procedure btnRefreshClick(Sender: TObject);
    procedure cxdbtxtdtNOMBRE_METADATOPropertiesChange(Sender: TObject);
    procedure btnVerDatosClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEditarMetaClick(Sender: TObject);
    procedure btnExportarExcelMetaClick(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
//    procedure TreeView1Click(Sender: TObject);
    procedure btnBonitoClick(Sender: TObject);
    procedure btnAbrirScriptClick(Sender: TObject);
    procedure ActionSeleccionarExecute(Sender: TObject);
    procedure ActionSeleccionarUpdate(Sender: TObject);
    procedure ActionEjecutarExecute(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure tsMetadatosShow(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure SynEdit1Scroll(Sender: TObject; ScrollBar: TScrollBarKind);
    procedure SynEdit1StatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure ScrollBar2Change(Sender: TObject);
    procedure syndtEstructuraStatusChange(Sender: TObject;
      Changes: TSynStatusChanges);
    procedure syndtEstructuraScroll(Sender: TObject; ScrollBar: TScrollBarKind);
    procedure tsSQLShow(Sender: TObject);
  public
    dmmGeneradorProcesos: TdmGeneradorProcesos;
    procedure CargarArbol;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  private
    FFindDialog: TFindDialog;
    FReplaceDialog: TReplaceDialog;
    FPopMenuEditores: TPopupMenu;
    FSearchEngine: TSynEditSearch;
    FEditorActualBusqueda: TCustomSynEdit;
    FAppEvents: TApplicationEvents;
    procedure AppEventsMessage(var Msg: TMsg; var Handled: Boolean);
    procedure ActionBuscarExecute(Sender: TObject);
    procedure ActionReemplazarExecute(Sender: TObject);
    procedure ActionBuscarGlobalExecute(Sender: TObject);
    procedure ActionEditoresUpdate(Sender: TObject);
    procedure ActionDeshacerExecute(Sender: TObject);
    procedure ActionRehacerExecute(Sender: TObject);
    procedure ActionBorrarLineaExecute(Sender: TObject);
    procedure ActionComentarExecute(Sender: TObject);
    procedure DoFind(Sender: TObject);
    procedure DoReplace(Sender: TObject);
    procedure BuscarGlobal;
    procedure ActionCortarExecute(Sender: TObject);
    procedure ActionCopiarExecute(Sender: TObject);
    procedure ActionPegarExecute(Sender: TObject);
    procedure CrearMenuContextual;
    procedure ActivarEnterComoTab(Activo: Boolean);
    procedure EditorEnter(Sender: TObject);
    procedure EditorExit(Sender: TObject);
    procedure SafeSetScrollBar(SB: TScrollBar;
                               AMax, APageSize, APosition: Integer);
    procedure UniScript1Error(Sender: TObject;
                              E: Exception;
                              SQL: string;
                              var Action: TErrorAction);
    procedure ScriptAfterExecute(Sender: TObject; SQL: string);
  end;

var
  frmMtoGeneradorProcesos: TfrmMtoGeneradorProcesos;
  IsColumnMode: Boolean;

implementation

uses
  inLibWin,
  inLibUser,
  inLibNet,
  inLibDevExp,
  inLibGlobalVar,
  inLibDir,
  ts.Editor.CodeFormatters, inMtoPrincipal;

{$R *.dfm}

procedure TfrmMtoGeneradorProcesos.ActionCortarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CutToClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.CutToClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionComentarExecute(Sender: TObject);
var
  Editor: TCustomSynEdit;
  i, LineStart, LineEnd: Integer;
begin
  if DBSynEdit1.Focused then
    Editor := DBSynEdit1
  else
    Exit;

  Editor.BeginUpdate;
  Editor.Lines.BeginUpdate;
  try
    if Editor.SelAvail then
    begin
      LineStart := Editor.BlockBegin.Line;
      LineEnd   := Editor.BlockEnd.Line;
      if Editor.BlockEnd.Char = 1 then
        Dec(LineEnd);
    end
    else
    begin
      LineStart := Editor.CaretY;
      LineEnd   := Editor.CaretY;
    end;

    for i := LineStart to LineEnd do
      Editor.Lines[i - 1] := '-- ' + Editor.Lines[i - 1];

  finally
    Editor.Lines.EndUpdate;
    Editor.EndUpdate;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionCopiarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CopyToClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.CopyToClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionPegarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.PasteFromClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.PasteFromClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionEditoresUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := DBSynEdit1.Focused or syndtEstructura.Focused;
end;

procedure TfrmMtoGeneradorProcesos.ActionDeshacerExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.Undo
  else if syndtEstructura.Focused then
    syndtEstructura.Undo;
end;

procedure TfrmMtoGeneradorProcesos.ActionRehacerExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.Redo
  else if syndtEstructura.Focused then
    syndtEstructura.Redo;
end;

procedure TfrmMtoGeneradorProcesos.ActionBorrarLineaExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CommandProcessor(ecDeleteLine, #0, nil)
  else if syndtEstructura.Focused then
    syndtEstructura.CommandProcessor(ecDeleteLine, #0, nil);
end;

procedure TfrmMtoGeneradorProcesos.AppEventsMessage(var Msg: TMsg;
                                                    var Handled: Boolean);
begin
  // Si la tecla pulsada es ESCAPE
  if (Msg.message = WM_KEYDOWN) and (Msg.wParam = VK_ESCAPE) then
  begin
    // Comprobamos si el diálogo de Buscar está abierto y es la ventana activa
    if Assigned(FFindDialog) and (FFindDialog.Handle <> 0) and
       (GetActiveWindow = FFindDialog.Handle) then
    begin
      FFindDialog.CloseDialog; // Cerramos la ventanita
      Handled := True;         // ¡Evitamos que se ejecute el botón Cancelar!
    end
    // Hacemos lo mismo para el diálogo de Reemplazar
    else if Assigned(FReplaceDialog) and (FReplaceDialog.Handle <> 0) and
            (GetActiveWindow = FReplaceDialog.Handle) then
    begin
      FReplaceDialog.CloseDialog;
      Handled := True;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.DoFind(Sender: TObject);
var
  Opciones: TSynSearchOptions;
  Dialog: TFindDialog;
begin
  Dialog := Sender as TFindDialog;

  // Si por lo que sea no hay un editor memorizado, salimos
  if not Assigned(FEditorActualBusqueda) then Exit;

  Opciones := [];
  if frMatchCase in Dialog.Options then Include(Opciones, ssoMatchCase);
  if not (frDown in Dialog.Options) then Include(Opciones, ssoBackwards);

  // Buscamos en el editor que memorizamos
  if FEditorActualBusqueda.SearchReplace(Dialog.FindText, '', Opciones) = 0 then
    MessageDlg('Texto no encontrado.', mtInformation, [mbOK], 0);
end;

procedure TfrmMtoGeneradorProcesos.DoReplace(Sender: TObject);
var
  Opciones: TSynSearchOptions;
  Dialog: TReplaceDialog;
begin
  Dialog := Sender as TReplaceDialog;

  if not Assigned(FEditorActualBusqueda) then Exit;

  Opciones := [ssoReplace];
  if frMatchCase in Dialog.Options then Include(Opciones, ssoMatchCase);
  if not (frDown in Dialog.Options) then Include(Opciones, ssoBackwards);
  if frReplaceAll in Dialog.Options then Include(Opciones, ssoReplaceAll);

  // Reemplazamos en el editor que memorizamos
  if FEditorActualBusqueda.SearchReplace(Dialog.FindText,
                                         Dialog.ReplaceText,
                                         Opciones) = 0 then
    MessageDlg('Texto no encontrado.', mtInformation, [mbOK], 0);
end;

procedure TfrmMtoGeneradorProcesos.BuscarGlobal;
var
  TextoBuscar: string;
begin
  if InputQuery('Búsqueda Global',
                'Introduce el texto a buscar en todos los procesos:',
                TextoBuscar) then
  begin
    if Trim(TextoBuscar) = '' then Exit;

    // Nos pasamos a la pestaña de la lista de procesos
    pcPantalla.ActivePage := tsLista;

    with dsTablaG.DataSet do
    begin
      DisableControls;
      try
        Filtered := False;
        // Filtramos por el contenido del proceso o por el nombre
        Filter := 'PROCESO_GENERADOR_PROCESO_GP LIKE '
          + QuotedStr('%' + TextoBuscar + '%') +
                  ' OR NOMBRE_GENERADOR_PROCESO_GP LIKE '
                    + QuotedStr('%' + TextoBuscar + '%');
        Filtered := True;

        if RecordCount = 0 then
        begin
          MessageDlg('No se encontraron procesos que contengan: ' + TextoBuscar,
                     mtInformation,
                     [mbOK],
                     0);
          Filtered := False; // Quitamos el filtro si no hay resultados
        end;
      finally
        EnableControls;
      end;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CrearMenuContextual;
var
  Item: TMenuItem;
begin
  if Assigned(FPopMenuEditores) then Exit;

  // Creamos el componente menú
  FPopMenuEditores := TPopupMenu.Create(Self);

  // Botón Deshacer
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '&Deshacer';
  Item.ShortCut := TextToShortCut('Ctrl+Z');
  Item.OnClick := ActionDeshacerExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Botón Rehacer
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '&Rehacer';
  Item.ShortCut := TextToShortCut('Shift+Ctrl+Z');
  Item.OnClick := ActionRehacerExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Botón Borrar Línea
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '&Borrar Línea';
  Item.ShortCut := TextToShortCut('Ctrl+Y');
  Item.OnClick := ActionBorrarLineaExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Añadimos un separador visual
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '-';
  FPopMenuEditores.Items.Add(Item);

// Botón Cortar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := 'Cor&tar';
  Item.ShortCut := TextToShortCut('Ctrl+X');
  Item.OnClick := ActionCortarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Botón Copiar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '&Copiar';
  Item.ShortCut := TextToShortCut('Ctrl+C');
  Item.OnClick := ActionCopiarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Botón Pegar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '&Pegar';
  Item.ShortCut := TextToShortCut('Ctrl+V');
  Item.OnClick := ActionPegarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Asignamos el menú a tus dos editores
  DBSynEdit1.PopupMenu := FPopMenuEditores;
  syndtEstructura.PopupMenu := FPopMenuEditores;
end;

procedure TfrmMtoGeneradorProcesos.ActivarEnterComoTab(Activo: Boolean);
  procedure CambiarEn(AOwner: TComponent);
  var
    i: Integer;
  begin
    if Assigned(AOwner) then
      for i := 0 to AOwner.ComponentCount - 1 do
        if AOwner.Components[i] is TJvEnterAsTab then
          TJvEnterAsTab(AOwner.Components[i]).EnterAsTab := Activo;
  end;
begin
  // Buscamos el componente problemático en los 3 niveles posibles y lo
  // apagamos/encendemos
  CambiarEn(Self);
  CambiarEn(Self.Owner);
  CambiarEn(Application.MainForm);
end;

procedure TfrmMtoGeneradorProcesos.EditorEnter(Sender: TObject);
begin
  ActivarEnterComoTab(False);
end;

procedure TfrmMtoGeneradorProcesos.EditorExit(Sender: TObject);
begin
  ActivarEnterComoTab(True);
end;

procedure TfrmMtoGeneradorProcesos.ScriptAfterExecute(Sender: TObject;
                                                      SQL: string);
begin
  // Detenemos el cronómetro lo antes posible
    cxmResul.Lines.Add(Format(' -- [OK] Filas afectadas: %d ',
                              [(Sender as TUniScript).RowsAffected]));
    cxmResul.Lines.Add('--------------------------------------------------');
end;

procedure TfrmMtoGeneradorProcesos.UniScript1Error(Sender: TObject;
                                           E: Exception;
                                           SQL: string;
                                           var Action: TErrorAction);
var
  Respuesta: Integer;
begin
    cxmResul.Lines.Add('  [ERROR] ' + E.Message );
    cxmResul.Lines.Add('--------------------------------------------------');
    Application.ProcessMessages;
  // Aquí podemos registrar el error en un log o preguntar al usuario
  var MsgCorta := E.Message;
  if Length(MsgCorta) > 20 then
    MsgCorta := Copy(MsgCorta, 1, 20) + '...';
  Respuesta := MessageDlg(
    'Ocurrió un error ejecutando el script.' +  sLineBreak +
    'Detalle del error: ' + MsgCorta + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?',
    mtError, [mbYes, mbNo], 0);
  if Respuesta = mrYes then
    Action := eaContinue  // Ignora la sentencia fallida
  else
    Action := eaFail;     // Detiene el script
end;

procedure TfrmMtoGeneradorProcesos.SafeSetScrollBar(SB: TScrollBar;
                                           AMax, APageSize, APosition: Integer);
begin
//  try
    AMax      := Max(AMax, 1);
    APageSize := Max(APageSize, 1);

    // +1 para que el scroll pueda llegar a mostrar la última línea arriba
    AMax      := Max(AMax + 1, APageSize + 1);

    // Position puede llegar hasta AMax - APageSize (última línea visible)
    APosition := Max(0, Min(APosition, AMax - APageSize));

    if SB.Max < APageSize then
    begin
      SB.Max      := AMax;
      SB.PageSize := APageSize;
    end
    else
    begin
      SB.PageSize := APageSize;
      SB.Max      := AMax;
    end;

    SB.Position := APosition;

end;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoGeneradorProcesos.ActionEjecutarExecute(Sender: TObject);
begin
  inherited;
  btnEjecutarClick(Sender);
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarExecute(Sender: TObject);
var
  sNombreMetadato, sScriptCompleto: string;
  bEsProcedimiento: Boolean;
begin
  inherited;

  // 1. Si el foco está en los editores, mantenemos "Seleccionar Todo"
  if Screen.ActiveControl = DBSynEdit1 then
  begin
    DBSynEdit1.SelectAll;
  end
  else if Screen.ActiveControl = syndtEstructura then
  begin
    syndtEstructura.SelectAll;
  end

  // 2. Si el foco está en el árbol, disparamos la magia de Ctrl + A
  else if Screen.ActiveControl = tvMetadatos then
  begin
    if tvMetadatos.Selected <> nil then
    begin
      with dmmGeneradorProcesos do
      begin
        sNombreMetadato :=
          unqryMetadatos.FieldByName('NOMBRE_META_META').AsString;

        // Comprobamos si el metadato actual es un procedimiento (tipo 3)
        bEsProcedimiento :=
          (unqryMetadatos.FieldByName('PARENT_META').AsString = '3');

        // Recogemos el script completo
        sScriptCompleto := Trim(syndtEstructura.Lines.Text);

        if sScriptCompleto = '' then
        begin
          ShowMessage(
            'No hay estructura o script disponible para este metadato.');
          Exit;
        end;

        // 3. INYECTAMOS EL "OR REPLACE" MÁGICAMENTE
        sScriptCompleto := StringReplace(sScriptCompleto,
                     'CREATE TABLE', 'CREATE OR REPLACE TABLE', [rfIgnoreCase]);
        sScriptCompleto := StringReplace(sScriptCompleto,
                       'CREATE VIEW', 'CREATE OR REPLACE VIEW', [rfIgnoreCase]);
        sScriptCompleto := StringReplace(sScriptCompleto,
             'CREATE PROCEDURE', 'CREATE OR REPLACE PROCEDURE', [rfIgnoreCase]);

        // --- MAGIA NUEVA: ENVOLVEMOS EN DELIMITERS SI ES PROCEDURE ---
        if bEsProcedimiento then
        begin
          // Quitamos el ; final porque el delimitador pasa a ser $$
          sScriptCompleto := Trim(sScriptCompleto);
          while (sScriptCompleto <> '') and
                (RightStr(sScriptCompleto, 1) = ';') do
            sScriptCompleto := Trim(Copy(sScriptCompleto,
                                         1,
                                         Length(sScriptCompleto) - 1));

          // El $$ debe quedar pegado al ultimo END con un espacio en medio,
          // y un blanco antes del DELIMITER ; final, si no MySQL no graba.
          sScriptCompleto := 'DELIMITER $$' + sLineBreak +
                             sScriptCompleto + ' $$' + sLineBreak +
                             sLineBreak +
                             'DELIMITER ;';
        end
        else
        begin
          // Para no-procedimientos, garantizamos el ; final
          if RightStr(Trim(sScriptCompleto), 1) <> ';' then
            sScriptCompleto := Trim(sScriptCompleto) + ';';
        end;
        // -------------------------------------------------------------

        // Ponemos la tabla en modo inserción
        if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
          dsTablaG.DataSet.Append;

        // Volcamos todo al editor principal
        unqryTablaG.FieldByName('NOMBRE_GENERADOR_PROCESO_GP').AsString :=
          'Modificar ' + sNombreMetadato;
        unqryTablaG.FieldByName('PROCESO_GENERADOR_PROCESO_GP').AsString :=
          sScriptCompleto;

        // Cambiamos de pestaña y damos foco
        pcPestana.ActivePage := tsSQL;
        if DBSynEdit1.CanFocus then
          DBSynEdit1.SetFocus;
      end;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarUpdate(Sender: TObject);
begin
  inherited;
  (Sender as TAction).Enabled := (Screen.ActiveControl = DBSynEdit1)
                                 or (Screen.ActiveControl = syndtEstructura)
                                 or (screen.ActiveControl = tvMetadatos);
end;

procedure TfrmMtoGeneradorProcesos.btnBonitoClick(Sender: TObject);
var
  Formatter: ICodeFormatter;
begin
  inherited;
  var sSQL := dbSynEdit1.Lines.Text;
  Formatter := GetSQLFormatter;
  dbSynEdit1.Lines.Text := Formatter.Format(sSQL);
end;

procedure TfrmMtoGeneradorProcesos.btnAbrirScriptClick(Sender: TObject);
var
  dlgAbrir: TOpenDialog;
  slScript: TStringList;
begin
  inherited;
  dlgAbrir := TOpenDialog.Create(Self);
  try
    dlgAbrir.Title      := 'Abrir Script SQL';
    dlgAbrir.InitialDir := GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
    dlgAbrir.Filter     := 'Scripts SQL (*.sql)|*.sql|' +
                           'Archivos de texto (*.txt)|*.txt|' +
                           'Todos los archivos (*.*)|*.*';
    dlgAbrir.DefaultExt := 'sql';
    dlgAbrir.Options    := dlgAbrir.Options + [ofFileMustExist];
    if not dlgAbrir.Execute then
      Exit;

    slScript := TStringList.Create;
    try
      slScript.LoadFromFile(dlgAbrir.FileName);

      with dmmGeneradorProcesos do
      begin
        pcPestana.ActivePage := tsSQL;
        if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
          dsTablaG.DataSet.Append;

        unqryTablaG.FieldByName('NOMBRE_GENERADOR_PROCESO_GP').AsString :=
          ChangeFileExt(ExtractFileName(dlgAbrir.FileName), '');
        unqryTablaG.FieldByName('PROCESO_GENERADOR_PROCESO_GP').AsString :=
          slScript.Text;

        if DBSynEdit1.CanFocus then
          DBSynEdit1.SetFocus;
      end;
    finally
      FreeAndNil(slScript);
    end;
  finally
    FreeAndNil(dlgAbrir);
  end;
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
  uScript:TUniScript;
begin
  inherited;
  if ((
    dsTablaG.DataSet.State = dsInsert) or (
      dsTablaG.DataSet.State = dsEdit)) then
    dsTablaG.DataSet.Post;

  with dmmGeneradorProcesos do
  begin
    // 1. Editor activo: el que tiene el foco si es uno de los SynEdit; si no,
    //    el principal (DBSynEdit1). Asi no nos comemos selecciones residuales
    //    de syndtEstructura cuando el usuario esta editando en DBSynEdit1.
    var ActiveEditor: TCustomSynEdit;
    if syndtEstructura.Focused then
      ActiveEditor := syndtEstructura
    else
      ActiveEditor := DBSynEdit1;

    // 2. Si hay seleccion en el editor activo, ejecutamos solo eso.
    //    Si no, ejecutamos todo el texto VISIBLE de ese editor (no el del
    //    campo del dataset, que puede estar desfasado respecto a lo escrito).
    if Trim(ActiveEditor.SelText) <> '' then
      sSQL := ActiveEditor.SelText
    else
      sSQL := ActiveEditor.Lines.Text;

    sSQL := Trim(sSQL);

    // Si está totalmente vacío, salimos para evitar errores de base de datos
    if sSQL = '' then
      Exit;

    // Determinamos si es una consulta que espera filas.
    // EXPLAIN / DESCRIBE / DESC devuelven resultset igual que un SELECT, asi
    // que los tratamos como tal para que el usuario pueda inspeccionar el plan
    // de ejecucion desde el generador.
    var sSQLUpper: String;
    sSQLUpper := UpperCase(sSQL);
    bIsSelect := (Pos('SELECT', sSQLUpper) = 1) or
                 (Pos('CALL', sSQLUpper) = 1) or
                 (Pos('SHOW', sSQLUpper) = 1) or
                 (Pos('EXPLAIN ', sSQLUpper) = 1) or
                 (Pos('DESCRIBE ', sSQLUpper) = 1) or
                 (Pos('DESC ', sSQLUpper) = 1);

    if bIsSelect then
    begin
      unqryVista.Close;
      tvVista.ClearItems;
      unqryVista.SQL.Text := sSQL;
      try
        startTime := Now;
        unqryVista.Open; // Intentamos abrir como Dataset

        // Verificamos si realmente devolvió columnas (útil para CALLs que no
        // devuelven nada)
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
          cxmResul.Lines.Add('-- Comando('+FormatDateTime('hh:nn:ss.zzz',
                                                          Now)+'): '
                             +sLineBreak + sSQL + sLineBreak +
           ' -- ejecutado con éxito. Filas afectadas: '
             + IntToStr(iRowsAffected));
        end;
      except on E: Exception do
        begin
          // Si falla el Open por no ser un SELECT/Resultset, reintentamos con
          // ExecSQL
          try
            unqryVista.Execute;
            cxmResul.Lines.Add('-- Comando('+
                                       FormatDateTime('hh:nn:ss.zzz', Now)+'): '
                               + sLineBreak + sSQL + sLineBreak +
                         ' -- ejecutado correctamente (sin filas de retorno).');
          except on E2: Exception do
            begin
              cxmResul.Lines.Add('-- Error('+FormatDateTime('hh:nn:ss.zzz',
                                                            Now)+
                                 '): ' + sLineBreak+ sSQL+ sLineBreak
                                 + '-- '+ E2.Message);
              ShowMessage('Error en ejecución: ' + E2.Message);
            end;
          end;
        end;
      end;
    end
    else
    begin
      uScript := TUniScript.Create(nil);
      uScript.Connection := oConn;
      showMessage(oConn.Database);
      uScript.OnError := UniScript1Error;
      uScript.AfterExecute := ScriptAfterExecute;
      try
        // Comandos directos (INSERT, UPDATE, DELETE)
        uScript.SQL.Text := sSQL;
        try
          startTime := Now;
          uScript.Execute;
          iRowsAffected := uScript.RowsAffected;
          DateTimeToString(sformatteddt, 'ss:zzz', (Now - startTime));
          var sCommand := Copy(sSQL,1,20);
          if sSQL.Length > 20 then
            sCommand := sCommand + '...';
          cxmResul.Lines.Add('Comando:'+sCommand+ ' ejecutado. ' + IntToStr(
            iRowsAffected) +
                             ' registros afectados en ' + sformatteddt
                               + ' seg:ms');
        except on E: Exception do
          begin
            cxmResul.Lines.Add(E.Message);
            ShowMessage('Error en comando SQL: ' + E.Message);
          end;
        end;
      finally
        FreeAndNil(uScript);
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
  FreeAndNil(saveDialog);
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
  FreeAndNil(saveDialog);
end;

procedure TfrmMtoGeneradorProcesos.btnVerDatosClick(Sender: TObject);
begin
  inherited;
  if ((dsTablaG.DataSet.State = dsInsert) or
      (dsTablaG.DataSet.State = dsEdit)
     ) then
    dsTablaG.DataSet.Post;
 end;

procedure TfrmMtoGeneradorProcesos.btnRefreshClick(Sender: TObject);
begin
  inherited;
  Screen.Cursor := crHourGlass;
  try
    with dmmGeneradorProcesos do
    begin
      unstrdprcRefresh.ParamByName('pDATABASENAME').AsString :=
                                                    oConn.Database;
      unstrdprcRefresh.ExecProc;
      if not unqryMetadatos.Active then
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
  iCodigo, iParent: Integer;
  DictNodos: TDictionary<Integer, TTreeNode>;
begin
  tvMetadatos.Items.BeginUpdate;

  // Inicializamos el diccionario que actuará como caché de búsqueda ultra
  // rápida
  DictNodos := TDictionary<Integer, TTreeNode>.Create;
  try
    tvMetadatos.Items.Clear;
    dmmGeneradorProcesos.unqryMetadatos.DisableControls;

    // Pasada 1: nodos raíz (PARENT = '-1')
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent :=
        dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_META').AsString;
      if sParent = '-1' then
      begin
        sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'NOMBRE_META_META').AsString;
        sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'CODIGO_META_META').AsString;
        iCodigo := StrToIntDef(sCodigo, 0);

        // Creamos el nodo raíz
        nodeRaiz := tvMetadatos.Items.Add(nil, sNombre);
        nodeRaiz.Data := Pointer(NativeInt(iCodigo));

        // ¡Magia! Lo guardamos en el diccionario usando su código como llave
        DictNodos.Add(iCodigo, nodeRaiz);
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;

    // Pasada 2: nodos hijo
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent :=
        dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_META').AsString;
      if sParent <> '-1' then
      begin
        sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'NOMBRE_META_META').AsString;
        sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'CODIGO_META_META').AsString;
        iCodigo := StrToIntDef(sCodigo, 0);
        iParent := StrToIntDef(sParent, -1);

        // Buscamos el nodo padre de forma instantánea, sin recorrer el árbol
        if DictNodos.TryGetValue(iParent, nodeRaiz) then
        begin
          nodeHijo := tvMetadatos.Items.AddChild(nodeRaiz, sNombre);
          nodeHijo.Data := Pointer(NativeInt(iCodigo));

          // Añadimos también este hijo al diccionario por si tiene subniveles
          if not DictNodos.ContainsKey(iCodigo) then
            DictNodos.Add(iCodigo, nodeHijo);
        end;
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;

  finally
    // Es vital liberar el diccionario de la memoria
    FreeAndNil(DictNodos);
    dmmGeneradorProcesos.unqryMetadatos.EnableControls;
    tvMetadatos.Items.EndUpdate;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CrearTablaPrincipal;
begin
  DBSynEdit1.BeginUpdate;
  syndtEstructura.BeginUpdate;
  inherited;
  dmmGeneradorProcesos := tdmDataModule as TdmGeneradorProcesos;
  tvMetadatostvVista.DataController.DataSource :=
                                               dmmGeneradorProcesos.dsContenido;
  tvVista.DataController.DataSource := dmmGeneradorProcesos.dsVista;
  pcPestana.ActivePage := tsSQL;
  pkFieldName := 'CODIGO_GENERADOR_PROCESO_GP';
  // Asegúrate de que las opciones predeterminadas estén configuradas
  // correctamente
//  dbsyndtTexto.Options := dbsyndtTexto.Options - [eoAltSetsColumnMode];
  IsColumnMode := False;
  DBSynEdit1.EndUpdate;
  syndtEstructura.EndUpdate;
end;

procedure TfrmMtoGeneradorProcesos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoGeneradorProcesos.cxdbtxtdtNOMBRE_METADATOPropertiesChange(
  Sender: TObject);
var
  // <--- Sustituimos sExec por el interfaz del formateador
  Formatter: ICodeFormatter;
begin
  inherited;
  sbVertCentro.Position := 1;
  with dmmGeneradorProcesos do
  begin
    pcMetadato.ActivePage := tsEstructura;
    if ((unqryMetadatos.FieldByName('PARENT_META').AsString = '1')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
                         unqryMetadatos.FieldByName(
                           'NOMBRE_META_META').AsString;
      unqryEstructura.Open;
      syndtEstructura.Lines.Text :=
                           unqryEstructura.FieldByName('Create Table').AsString;
    end
      else
    if ((unqryMetadatos.FieldByName('PARENT_META').AsString = '2')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
                         unqryMetadatos.FieldByName(
                           'NOMBRE_META_META').AsString;
      unqryEstructura.Open;
      mmoSalida.Lines.Text :=
                      Trim(unqryEstructura.FieldByName('Create View').AsString);
      mmoSalida.Lines.Text := StringReplace(mmoSalida.Lines.Text,
                           'ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` '+
                           'SQL SECURITY DEFINER',
                           '',
                           [rfReplaceAll]);
      mmoSalida.Lines.Text := StringReplace(mmoSalida.Lines.Text,
                           ' separator '',''',
                           '',
                           [rfReplaceAll, rfIgnoreCase]);
      var sSQL := mmoSalida.Lines.Text;
      sSQL := StringReplace(sSQL, '`', '', [rfReplaceAll]);

      // 3. Normalizar espacios múltiples
      while Pos('  ', sSQL) > 0 do
        sSQL := StringReplace(sSQL, '  ', ' ', [rfReplaceAll]);
      // --- NUEVO CÓDIGO CON LA LIBRERÍA NATIVA ---
      Formatter := GetSQLFormatter;
      syndtEstructura.Lines.Text := Formatter.Format(sSQL);
      // -------------------------------------------
    end
    else
    if ((unqryMetadatos.FieldByName('PARENT_META').AsString = '3')) then
    begin
      unqryEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
                         unqryMetadatos.FieldByName(
                           'NOMBRE_META_META').AsString;
      unqryEstructura.Open;
      syndtEstructura.Lines.Text := StringReplace(unqryEstructura.FieldByName(
                                                 'Create Procedure').AsString,
                                                 ' DEFINER=`root`@`localhost`',
                                                 '',
                                                 [rfReplaceAll]);
    end
      else
        syndtEstructura.Lines.Clear;
    syndtEstructuraStatusChange(nil, [scAll]);
  end;
end;

procedure TfrmMtoGeneradorProcesos.FormKeyDown(Sender: TObject;
                                               var Key: Word;
                                               Shift: TShiftState);
begin
  if (Key = VK_DIVIDE) then
  if (Shift = [ssCtrl]) then
  begin
    ActionComentarExecute(Sender);
    Key := 0;
    Exit;
  end;
  // 1. Comprobamos si es una de las teclas de navegación o el Enter
  if (Key = VK_RETURN) or (Key = VK_PRIOR) or (Key = VK_NEXT) or
     (Key = VK_HOME) or (Key = VK_END) then
  begin
    if (Key = VK_RETURN) and (ssCtrl in Shift) then
    begin
         SelectNext(ActiveControl as TWinControl, True, True);
         key := 0;
         Exit;
    end
    else
      if DBSynEdit1.Focused or syndtEstructura.Focused then
      begin
        Exit;
      end;
  end;
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

procedure TfrmMtoGeneradorProcesos.ActionBuscarGlobalExecute(Sender: TObject);
begin
  BuscarGlobal;
end;

procedure TfrmMtoGeneradorProcesos.ActionBuscarExecute(Sender: TObject);
begin
  if Assigned(FFindDialog) then
  begin
    // 1. Memorizamos qué editor disparó la búsqueda
    if syndtEstructura.Focused then
      FEditorActualBusqueda := syndtEstructura
    else
      FEditorActualBusqueda := DBSynEdit1;

    // 2. Si hay texto seleccionado, lo metemos en la caja
    if FEditorActualBusqueda.SelText <> '' then
      FFindDialog.FindText := FEditorActualBusqueda.SelText;

    FFindDialog.Execute;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionReemplazarExecute(Sender: TObject);
begin
  if Assigned(FReplaceDialog) then
  begin
    // 1. Memorizamos qué editor disparó el reemplazo
    if syndtEstructura.Focused then
      FEditorActualBusqueda := syndtEstructura
    else
      FEditorActualBusqueda := DBSynEdit1;

    // 2. Si hay texto seleccionado, lo metemos en la caja
    if FEditorActualBusqueda.SelText <> '' then
      FReplaceDialog.FindText := FEditorActualBusqueda.SelText;

    FReplaceDialog.Execute;
  end;
end;

procedure TfrmMtoGeneradorProcesos.FormShow(Sender: TObject);
begin
  inherited;
  // [Ctrl + X] Cortar
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+X');
    OnExecute := ActionCortarExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  // [Ctrl + C] Copiar
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+C');
    OnExecute := ActionCopiarExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  // [Ctrl + V] Pegar
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+V');
    OnExecute := ActionPegarExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+Z');
    OnExecute := ActionDeshacerExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  // [Shift + Ctrl + Z] Rehacer
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Shift+Ctrl+Z');
    OnExecute := ActionRehacerExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  // [Ctrl + Y] Borrar Línea
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+Y');
    OnExecute := ActionBorrarLineaExecute;
    OnUpdate  := ActionEditoresUpdate;
  end;
  if not Assigned(FAppEvents) then
  begin
    FAppEvents := TApplicationEvents.Create(Self);
    FAppEvents.OnMessage := AppEventsMessage;
  end;
  if not Assigned(FFindDialog) then
  begin
    FFindDialog := TFindDialog.Create(Self);
    FFindDialog.Options := [frDown, frHideUpDown, frHideWholeWord];
    FFindDialog.OnFind := DoFind;
  end;
  // 2. Creamos el diálogo de Reemplazar
  if not Assigned(FReplaceDialog) then
  begin
    FReplaceDialog := TReplaceDialog.Create(Self);
    FReplaceDialog.Options := [frDown, frHideUpDown, frHideWholeWord];
    FReplaceDialog.OnFind := DoFind;
    FReplaceDialog.OnReplace := DoReplace;
  end;
  if not Assigned(FSearchEngine) then
  begin
    FSearchEngine := TSynEditSearch.Create(Self);
    DBSynEdit1.SearchEngine := FSearchEngine;
    syndtEstructura.SearchEngine := FSearchEngine;
  end;
  CrearMenuContextual;
  DBSynEdit1.WantTabs := True;
  syndtEstructura.WantTabs := True;
  DBSynEdit1.WantReturns := True;
  syndtEstructura.WantReturns := True;
  DBSynEdit1.TabWidth := 4;
  // Asignamos nuestros vigilantes de foco
  DBSynEdit1.OnEnter := EditorEnter;
  DBSynEdit1.OnExit  := EditorExit;
  syndtEstructura.OnEnter := EditorEnter;
  syndtEstructura.OnExit  := EditorExit;
  DBSynEdit1.Visible := True;
  syndtEstructura.Visible := True;
  if DBsynEdit1.CanFocus then
    DBsynEdit1.SetFocus;
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+F');
    OnExecute := ActionBuscarExecute;
  end;
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+R');
    OnExecute := ActionReemplazarExecute;
  end;
  with TAction.Create(Self) do
  begin
    ActionList := alGenerador;
    ShortCut := TextToShortCut('Ctrl+Shift+F');
    OnExecute := ActionBuscarGlobalExecute;
  end;
  if DBsynEdit1.CanFocus then
    DBsynEdit1.SetFocus;
end;

procedure TfrmMtoGeneradorProcesos.SynEdit1StatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  inherited;
  SafeSetScrollBar(
    sbVertDerecho,
    DBSynEdit1.Lines.Count,
    DBSynEdit1.LinesInWindow,
    DBSynEdit1.TopLine
  );
end;

procedure TfrmMtoGeneradorProcesos.SynEdit1Scroll(Sender: TObject;
  ScrollBar: TScrollBarKind);
begin
  inherited;
  if ScrollBar = sbVertical then
    SynEdit1StatusChange(Sender, [scAll]);
end;

procedure TfrmMtoGeneradorProcesos.ScrollBar1Change(Sender: TObject);
begin
  inherited;
  if DBSynEdit1.TopLine <> sbVertDerecho.Position then
    DBSynEdit1.TopLine := sbVertDerecho.Position;
end;

procedure TfrmMtoGeneradorProcesos.syndtEstructuraStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  inherited;
  SafeSetScrollBar(
    sbVertCentro,
    syndtEstructura.Lines.Count,
    syndtEstructura.LinesInWindow,
    syndtEstructura.TopLine
  );
end;

procedure TfrmMtoGeneradorProcesos.syndtEstructuraScroll(Sender: TObject;
  ScrollBar: TScrollBarKind);
begin
  inherited;
  if ScrollBar = sbVertical then
    syndtEstructuraStatusChange(Sender, [scAll]);
end;

procedure TfrmMtoGeneradorProcesos.ScrollBar2Change(Sender: TObject);
begin
  inherited;
  if syndtEstructura.TopLine <> sbVertCentro.Position then
    syndtEstructura.TopLine := sbVertCentro.Position;
end;

procedure TfrmMtoGeneradorProcesos.TreeView1Change(Sender: TObject;
  Node: TTreeNode);
var
  iCodigo: Integer;
begin
  sbVertCentro.PageSize := 1;
  sbVertCentro.Max      := 1;
  sbVertCentro.Position := 0;
  // Si no hay nodo seleccionado (por ejemplo, al limpiar el árbol), salimos
  if Node = nil then Exit;

  // Recuperamos el código guardado en la propiedad Data del nodo
  iCodigo := NativeInt(Node.Data);

  // Posicionar el dataset de metadatos en el registro correspondiente
  dmmGeneradorProcesos.unqryMetadatos.Locate('CODIGO_META_META', iCodigo, []);

  // Llama a tu lógica existente para actualizar la interfaz/datos
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
  nodo := tvMetadatos.Selected;
  if nodo = nil then Exit;
  iCodigo := NativeInt(nodo.Data);
  dmmGeneradorProcesos.unqryMetadatos.Locate('CODIGO_META_META', iCodigo, []);
  with dmmGeneradorProcesos do
  begin
    // Si es una Tabla (1) o Vista (2), mostramos los datos
    if ((unqryMetadatos.FieldByName('PARENT_META').AsString = '1') or
        (unqryMetadatos.FieldByName('PARENT_META').AsString = '2')) then
    begin
      pcMetadato.ActivePage := tsContenido;
      tvMetadatostvVista.ClearItems;
      unqryContenido.Close;
      unqryContenido.SQL.Text := 'SELECT * FROM ' +
                         unqryMetadatos.FieldByName(
                           'NOMBRE_META_META').AsString;
      unqryContenido.Open;
      tvMetadatostvVista.DataController.CreateAllItems();
      tvMetadatostvVista.ApplyBestFit();
    end
    // Si es un Procedimiento Almacenado (3), generamos el CALL
    else if (unqryMetadatos.FieldByName('PARENT_META').AsString = '3') then
    begin
      sProcName := unqryMetadatos.FieldByName('NOMBRE_META_META').AsString;
      sCallText := 'CALL ' + sProcName + '(';
      // Creamos un TUniQuery temporal para leer los parámetros del
      // procedimiento
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
        FreeAndNil(qryParams);
      end;
      // Ponemos el dataset principal en modo Inserción
      if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
        dsTablaG.DataSet.Append; // Usar Append o Insert según prefieras
      // Asignamos el nombre al proceso (opcional)
      unqryTablaG.FieldByName('NOMBRE_GENERADOR_PROCESO_GP').AsString :=
        'Ejecutar ' + sProcName;
      // Asignamos el comando SQL generado al campo memo del editor
      unqryTablaG.FieldByName('PROCESO_GENERADOR_PROCESO_GP').AsString :=
        sCallText;
//      DBsynEdit1.Text := sCallText;
      // Foco visual: cambiamos a la pestaña de SQL y damos foco al editor
      // SynEdit
      pcPestana.ActivePage := tsSQL;
      if DBsynEdit1.CanFocus then
        DBsynEdit1.SetFocus;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.tsMetadatosShow(Sender: TObject);
begin
  inherited;
  if tvMetadatos.Items.Count = 0 then
    btnRefreshClick(nil);
end;

procedure TfrmMtoGeneradorProcesos.tsSQLShow(Sender: TObject);
begin
  inherited;
  SynEdit1StatusChange(nil, [scAll]);
end;

initialization
  ForceReferenceToClass(TfrmMtoGeneradorProcesos);

end.
