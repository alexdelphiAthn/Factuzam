{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoBusquedaDatos                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Búsqueda avanzada de artículos y SKU por campos, talla, color, stock,     }
{    proveedor y propiedades. Reutiliza filtros y perfiles de Factuzam.        }
{******************************************************************************}
unit inMtoBusquedaDatos;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Diagnostics,
  System.Variants, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Graphics, Data.DB, Uni,
  cxControls, cxContainer, cxEdit, cxLabel, cxTextEdit, cxCheckBox,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxGridDBTableView,
  inMtoGenSearch, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxDBData, Vcl.Menus, cxBlobEdit, MemDS, DBAccess, System.Actions,
  Vcl.ActnList, Vcl.Dialogs, dxShellDialogs, JvComponentBase, JvEnterTab,
  cxLocalization, Vcl.StdCtrls, cxRadioGroup, cxNavigator, cxDBNavigator,
  Vcl.Buttons, cxGridCustomTableView, cxGridTableView, cxGridLevel, cxClasses,
  cxGridCustomView, cxGrid, cxPC, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, inLibDocumentosTrabajo;

type
  TfrmMtoBusquedaDatos = class(TfrmMtoSearch)
    pnlCriterios: TPanel;
    lblCampo: TcxLabel;
    cbbCampo: TcxComboBox;
    lblValor: TcxLabel;
    edtValor: TcxButtonEdit;
    lblCoincidencia: TcxLabel;
    cbbCoincidencia: TcxComboBox;
    chkDistinguirMayusculas: TcxCheckBox;
    lblEstado: TcxLabel;
    cbbEstado: TcxComboBox;
    lblStock: TcxLabel;
    cbbStock: TcxComboBox;
    lblLimite: TcxLabel;
    cbbLimite: TcxComboBox;
    lblAyuda: TcxLabel;
    btnBuscar: TcxButton;
    btnLimpiar: TcxButton;
    lblResultados: TcxLabel;
    unqryResultados: TUniQuery;
    btnOcultar: TcxButton;
    btnPerfiles: TcxButton;
    lblFamilia: TcxLabel;
    cbbFamilia: TcxComboBox;
    lblProveedor: TcxLabel;
    cbbProveedor: TcxLookupComboBox;
    lblTemporada: TcxLabel;
    cbbTemporada: TcxComboBox;
    unqryProveedoresBusqueda: TUniQuery;
    dsProveedoresBusqueda: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnPerfilesClick(Sender: TObject);
    procedure btnOcultarClick(Sender: TObject);
    procedure edtValorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbbCampoPropertiesChange(Sender: TObject);
    procedure cbbProveedorKeyPress(Sender: TObject; var Key: Char);
    procedure edtValorPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure cxGrdDBTabPrinColorCustomDrawCell(
      Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
  private
    FColumnasCreadas: Boolean;
    FAltoCriterios: Integer;
    FPopupGrid: TPopupMenu;
    FPopupGridOriginal: TNotifyEvent;
    FTimerPrecarga: TTimer;
    FCronometroApertura: TStopwatch;
    FBusquedaProveedor: string;
    FInstanteBusquedaProveedor: UInt64;
    procedure InicializarListas;
    procedure CargarFiltrosPrecarga;
    procedure CargarCombo(ACombo: TcxComboBox; const ASQL,
      ACampoCodigo, ACampoNombre: string);
    procedure SeleccionarProveedorPorInicio;
    procedure ActualizarInterfazCampo;
    procedure ActualizarColumnasColor;
    procedure ConfigurarMenuContextual;
    procedure PopupGridPopup(Sender: TObject);
    procedure MenuAgregarDocumentoClick(Sender: TObject);
    procedure Buscar;
    function PrepararConsulta: Boolean;
    procedure ActualizarContador;
    procedure ConfigurarColumna(const ACampo, ATitulo: string;
      AAncho: Integer; AVisible: Boolean);
    function ObtenerExpresionCampo: string;
    function ObtenerLimite: Integer;
    function NormalizarHexColor(const AValor: string; out AHex: string;
      out ARojo, AVerde, AAzul: Integer): Boolean;
    function ResolverColorObjetivo(const AValor: string; out AHex: string;
      out ARojo, AVerde, AAzul: Integer): Boolean;
    function ResolverLineaDocumentoTrabajo(
      out ALinea: TDocTrabajoLineaOrigen;
      out AMensaje: string): Boolean;
    function CodigoCombo(ACombo: TcxComboBox): string;
    function CodigoProveedor: string;
    procedure TimerPrecargaTimer(Sender: TObject);
  protected
    function DebeAjustarColumnasAutomaticamente: Boolean; override;
  public
    class procedure Ejecutar(AOwner: TComponent;
      AParentForm: TCustomForm = nil);
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  inLibLog, inLibShowMto, inLibAtributosPaleta, inLibMsgComun;

{$R *.dfm}

const
  CAMPO_TODOS = 0;
  CAMPO_ARTICULO = 1;
  CAMPO_SKU = 2;
  CAMPO_DESCRIPCION = 3;
  CAMPO_TALLA = 4;
  CAMPO_COLOR = 5;
  CAMPO_CODIGO_BARRAS = 6;
  CAMPO_FAMILIA = 7;
  CAMPO_PROVEEDOR = 8;
  CAMPO_REF_PROVEEDOR = 9;
  CAMPO_TEMPORADA = 10;
  CAMPO_ALMACEN = 11;
  CAMPO_PROPIEDADES = 12;
  CAMPO_COLOR_BASICO = 13;
  CAMPO_PROXIMIDAD_COLOR = 14;

class procedure TfrmMtoBusquedaDatos.Ejecutar(AOwner: TComponent;
  AParentForm: TCustomForm);
var
  frm: TfrmMtoBusquedaDatos;
  sCodigoArt: string;
  swApertura: TStopwatch;
begin
  swApertura := TStopwatch.StartNew;
  sCodigoArt := '';
  frm := TfrmMtoBusquedaDatos.Create(nil);
  try
    frm.FCronometroApertura := swApertura;
    if Assigned(AParentForm) then
      frm.PopupParent := AParentForm;
    frm.ShowModal;
    if (frm.sFicha = 'S') and
       frm.unqryResultados.Active and
       (not frm.unqryResultados.IsEmpty) then
    begin
      sCodigoArt := frm.unqryResultados.FieldByName(
                                      'CODIGO_ART_ART').AsString;
    end;
  finally
    FreeAndNil(frm);
  end;
  if sCodigoArt <> '' then
    ShowMto(AOwner, 'Articulos', sCodigoArt);
end;

procedure TfrmMtoBusquedaDatos.FormCreate(Sender: TObject);
begin
  inherited;
  unqryResultados.Connection := ConexionPrincipal;
  unqryResultados.ReadOnly := True;
  unqryProveedoresBusqueda.Connection := ConexionPrincipal;
  unqryProveedoresBusqueda.ReadOnly := True;
  dsTablaG.DataSet := unqryResultados;
  FColumnasCreadas := False;
  FAltoCriterios := pnlCriterios.Height;
  FBusquedaProveedor := '';
  FInstanteBusquedaProveedor := 0;
  InicializarListas;
  cxGrdDBTabPrin.FilterRow.Visible := True;
  cxGrdDBTabPrin.OptionsView.GroupByBox := True;
  ConfigurarMenuContextual;
  FTimerPrecarga := TTimer.Create(Self);
  FTimerPrecarga.Enabled := False;
  FTimerPrecarga.Interval := 1;
  FTimerPrecarga.OnTimer := TimerPrecargaTimer;
end;

procedure TfrmMtoBusquedaDatos.ConfigurarMenuContextual;
begin
  FPopupGrid := nil;
  if cxGrdPrincipal.PopupMenu is TPopupMenu then
    FPopupGrid := TPopupMenu(cxGrdPrincipal.PopupMenu);
  if Assigned(FPopupGrid) then
  begin
    FPopupGridOriginal := FPopupGrid.OnPopup;
    FPopupGrid.OnPopup := PopupGridPopup;
  end;
end;

procedure TfrmMtoBusquedaDatos.PopupGridPopup(Sender: TObject);
var
  miAgregar: TMenuItem;
  miSeparador: TMenuItem;
  linea: TDocTrabajoLineaOrigen;
  sMensaje: string;
begin
  if Assigned(FPopupGridOriginal) then
    FPopupGridOriginal(Sender);
  if Assigned(FPopupGrid) then
  begin
    miAgregar := TMenuItem.Create(FPopupGrid);
    miAgregar.Caption := SCaptionAnadirDocumentoTrabajo;
    miAgregar.Enabled := ResolverLineaDocumentoTrabajo(linea, sMensaje);
    miAgregar.OnClick := MenuAgregarDocumentoClick;
    FPopupGrid.Items.Insert(0, miAgregar);
    miSeparador := TMenuItem.Create(FPopupGrid);
    miSeparador.Caption := '-';
    FPopupGrid.Items.Insert(1, miSeparador);
  end;
end;

procedure TfrmMtoBusquedaDatos.MenuAgregarDocumentoClick(Sender: TObject);
var
  linea: TDocTrabajoLineaOrigen;
  sMensaje: string;
begin
  if ResolverLineaDocumentoTrabajo(linea, sMensaje) then
  begin
    try
      AgregarUnidadADocumentoTrabajo(Self, ConexionPrincipal,
        BusquedaVisual, ContextoSesion, ParametrosCaja, linea,
        CrearResolverArticulos(ConexionPrincipal));
    except
      on E: Exception do
      begin
        MessageDlg(E.Message, mtError, [mbOK], 0);
      end;
    end;
  end
  else
  begin
    MessageDlg(sMensaje, mtInformation, [mbOK], 0);
  end;
end;

procedure TfrmMtoBusquedaDatos.FormShow(Sender: TObject);
begin
  inherited;
  lblResultados.Caption := SCaptionSeleccioneFiltrosBuscar;
  FTimerPrecarga.Enabled := True;
end;

procedure TfrmMtoBusquedaDatos.TimerPrecargaTimer(Sender: TObject);
var
  sw: TStopwatch;
begin
  FTimerPrecarga.Enabled := False;
  Update;
  inLibLog.Log.LogPerf('BusquedaDatos.Abrir',
    'formulario visible sin consultar artículos',
    FCronometroApertura.ElapsedMilliseconds);
  sw := TStopwatch.StartNew;
  CargarFiltrosPrecarga;
  inLibLog.Log.LogPerf('BusquedaDatos.Precarga',
    'catálogos de familia, proveedor y temporada',
    sw.ElapsedMilliseconds);
  if edtValor.CanFocus then
    edtValor.SetFocus;
end;

procedure TfrmMtoBusquedaDatos.InicializarListas;
begin
  cbbCampo.Properties.Items.Clear;
  cbbCampo.Properties.Items.Add('Todos los campos');
  cbbCampo.Properties.Items.Add('Código de artículo');
  cbbCampo.Properties.Items.Add('SKU');
  cbbCampo.Properties.Items.Add('Descripción');
  cbbCampo.Properties.Items.Add('Talla');
  cbbCampo.Properties.Items.Add('Color');
  cbbCampo.Properties.Items.Add('Código de barras');
  cbbCampo.Properties.Items.Add('Familia');
  cbbCampo.Properties.Items.Add('Proveedor');
  cbbCampo.Properties.Items.Add('Referencia proveedor');
  cbbCampo.Properties.Items.Add('Temporada');
  cbbCampo.Properties.Items.Add('Almacén');
  cbbCampo.Properties.Items.Add('Atributos y propiedades');
  cbbCampo.Properties.Items.Add('Color básico');
  cbbCampo.Properties.Items.Add('Proximidad de paleta');
  cbbCampo.ItemIndex := CAMPO_TALLA;
  cbbCoincidencia.Properties.Items.Clear;
  cbbCoincidencia.Properties.Items.Add('Contiene');
  cbbCoincidencia.Properties.Items.Add('Empieza por');
  cbbCoincidencia.Properties.Items.Add('Es igual a');
  cbbCoincidencia.Properties.Items.Add('Termina en');
  cbbCoincidencia.Properties.Items.Add('No contiene');
  cbbCoincidencia.ItemIndex := 0;
  cbbEstado.Properties.Items.Clear;
  cbbEstado.Properties.Items.Add('Solo activos');
  cbbEstado.Properties.Items.Add('Todos');
  cbbEstado.Properties.Items.Add('Solo inactivos');
  cbbEstado.ItemIndex := 0;
  cbbStock.Properties.Items.Clear;
  cbbStock.Properties.Items.Add('Cualquier stock');
  cbbStock.Properties.Items.Add('Con existencias');
  cbbStock.Properties.Items.Add('Sin existencias');
  cbbStock.ItemIndex := 1;
  cbbLimite.Properties.Items.Clear;
  cbbLimite.Properties.Items.Add('500');
  cbbLimite.Properties.Items.Add('2.000');
  cbbLimite.Properties.Items.Add('5.000');
  cbbLimite.ItemIndex := 0;
  ActualizarInterfazCampo;
end;

procedure TfrmMtoBusquedaDatos.CargarFiltrosPrecarga;
begin
  CargarCombo(cbbFamilia,
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    '       COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, ' +
    '                CODIGO_FAM_FAM) AS NOM ' +
    '  FROM fza_articulos_familias ' +
    ' WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_FAM, CODIGO_FAM_FAM',
    'COD', 'NOM');
  unqryProveedoresBusqueda.Close;
  unqryProveedoresBusqueda.SQL.Text :=
    'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV ' +
    '  FROM fza_proveedores ' +
    ' WHERE IFNULL(ESACTIVO_PRV, ''S'') = ''S'' ' +
    ' ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV';
  unqryProveedoresBusqueda.Open;
  cbbProveedor.EditValue := Null;
  CargarCombo(cbbTemporada,
    'SELECT PV AS COD, PV AS NOM ' +
    '  FROM fza_propiedades_valores ' +
    ' WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    '   AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    ' ORDER BY PV',
    'COD', 'NOM');
end;

procedure TfrmMtoBusquedaDatos.CargarCombo(ACombo: TcxComboBox;
  const ASQL, ACampoCodigo, ACampoNombre: string);
var
  qry: TUniQuery;
  sCodigo: string;
  sNombre: string;
begin
  ACombo.Properties.Items.BeginUpdate;
  try
    ACombo.Properties.Items.Clear;
    ACombo.Properties.Items.Add('(Todos)');
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text := ASQL;
      qry.Open;
      while not qry.Eof do
      begin
        sCodigo := qry.FieldByName(ACampoCodigo).AsString;
        sNombre := qry.FieldByName(ACampoNombre).AsString;
        if (sNombre <> '') and (sNombre <> sCodigo) then
          ACombo.Properties.Items.Add(sCodigo + ' - ' + sNombre)
        else
          ACombo.Properties.Items.Add(sCodigo);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  finally
    ACombo.Properties.Items.EndUpdate;
  end;
  ACombo.ItemIndex := 0;
end;

procedure TfrmMtoBusquedaDatos.btnBuscarClick(Sender: TObject);
begin
  Buscar;
end;

procedure TfrmMtoBusquedaDatos.btnLimpiarClick(Sender: TObject);
begin
  edtValor.Clear;
  cbbCampo.ItemIndex := CAMPO_TALLA;
  ActualizarInterfazCampo;
  cbbCoincidencia.ItemIndex := 0;
  cbbEstado.ItemIndex := 0;
  cbbStock.ItemIndex := 1;
  cbbLimite.ItemIndex := 0;
  cbbFamilia.ItemIndex := 0;
  cbbProveedor.EditValue := Null;
  FBusquedaProveedor := '';
  FInstanteBusquedaProveedor := 0;
  cbbTemporada.ItemIndex := 0;
  chkDistinguirMayusculas.Checked := False;
  edtBusqGlobal.Clear;
  cxGrdDBTabPrin.DataController.Filter.Clear;
  unqryResultados.Close;
  lblResultados.Caption := SCaptionSeleccioneFiltrosBuscar;
end;

procedure TfrmMtoBusquedaDatos.cbbCampoPropertiesChange(Sender: TObject);
begin
  ActualizarInterfazCampo;
end;

procedure TfrmMtoBusquedaDatos.cbbProveedorKeyPress(Sender: TObject;
  var Key: Char);
const
  INTERVALO_BUSQUEDA_MS = 1500;
var
  iInstanteActual: UInt64;
begin
  if Key = #8 then
  begin
    if FBusquedaProveedor <> '' then
      Delete(FBusquedaProveedor, Length(FBusquedaProveedor), 1);
    SeleccionarProveedorPorInicio;
    Key := #0;
  end
  else if Key >= #32 then
  begin
    iInstanteActual := GetTickCount64;
    if (iInstanteActual - FInstanteBusquedaProveedor) >
       INTERVALO_BUSQUEDA_MS then
      FBusquedaProveedor := '';
    FBusquedaProveedor := FBusquedaProveedor + Key;
    FInstanteBusquedaProveedor := iInstanteActual;
    SeleccionarProveedorPorInicio;
    Key := #0;
  end;
end;

procedure TfrmMtoBusquedaDatos.SeleccionarProveedorPorInicio;
var
  sBusqueda: string;
  sCodigo: string;
  sCodigoEncontrado: string;
  sNombre: string;
begin
  sBusqueda := FBusquedaProveedor;
  sCodigoEncontrado := '';
  if sBusqueda = '' then
    cbbProveedor.EditValue := Null
  else if unqryProveedoresBusqueda.Active then
  begin
    unqryProveedoresBusqueda.First;
    while (not unqryProveedoresBusqueda.Eof) and
          (sCodigoEncontrado = '') do
    begin
      sCodigo := Trim(unqryProveedoresBusqueda.FieldByName(
                                           'CODIGO_PRV_PRV').AsString);
      sNombre := Trim(unqryProveedoresBusqueda.FieldByName(
                                         'RAZON_SOCIAL_PRV').AsString);
      if SameText(Copy(sCodigo, 1, Length(sBusqueda)), sBusqueda) or
         SameText(Copy(sNombre, 1, Length(sBusqueda)), sBusqueda) then
        sCodigoEncontrado := sCodigo;
      unqryProveedoresBusqueda.Next;
    end;
    if sCodigoEncontrado <> '' then
    begin
      cbbProveedor.EditValue := sCodigoEncontrado;
      if not cbbProveedor.DroppedDown then
        cbbProveedor.DroppedDown := True;
    end;
  end;
end;

procedure TfrmMtoBusquedaDatos.ActualizarInterfazCampo;
var
  bColorPaleta: Boolean;
  bProximidad: Boolean;
begin
  bColorPaleta := cbbCampo.ItemIndex in
    [CAMPO_COLOR_BASICO, CAMPO_PROXIMIDAD_COLOR];
  bProximidad := cbbCampo.ItemIndex = CAMPO_PROXIMIDAD_COLOR;
  edtValor.Properties.Buttons[0].Visible := bColorPaleta;
  cbbCoincidencia.Enabled := not bProximidad;
  chkDistinguirMayusculas.Enabled := not bProximidad;
  if bProximidad then
  begin
    lblValor.Caption := SCaptionColorObjetivo;
    edtValor.Properties.Nullstring :=
      'Código, nombre, HEX o botón para elegir color';
  end
  else if cbbCampo.ItemIndex = CAMPO_COLOR_BASICO then
  begin
    lblValor.Caption := SCaptionColorBasico;
    edtValor.Properties.Nullstring :=
      'Código, nombre o HEX del color básico';
  end
  else
  begin
    lblValor.Caption := SCaptionTextoABuscar;
    edtValor.Properties.Nullstring :=
      'Introduzca el valor y pulse Entrar';
  end;
end;

procedure TfrmMtoBusquedaDatos.edtValorPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  qryPaleta: TUniQuery;
  lstColores: TStringList;
  aColores: TArray<string>;
  sColor: string;
  pPopup: TPoint;
  i: Integer;
begin
  qryPaleta := TUniQuery.Create(nil);
  lstColores := TStringList.Create;
  try
    qryPaleta.Connection := ConexionPrincipal;
    qryPaleta.SQL.Add('SELECT NOMBRE_ATB');
    qryPaleta.SQL.Add('  FROM fza_atributos_basicos');
    qryPaleta.SQL.Add(' WHERE ID_VA_ATB = ''CO''');
    qryPaleta.SQL.Add('   AND ESACTIVO_ATB = ''S''');
    qryPaleta.SQL.Add(
      '   AND HEX_ATB REGEXP ''^#?[0-9A-Fa-f]{6}$''');
    qryPaleta.SQL.Add(' ORDER BY ORDEN_ATB, CODIGO_ATB');
    qryPaleta.Open;
    while not qryPaleta.Eof do
    begin
      lstColores.Add(qryPaleta.FieldByName('NOMBRE_ATB').AsString);
      qryPaleta.Next;
    end;
    SetLength(aColores, lstColores.Count);
    for i := 0 to lstColores.Count - 1 do
      aColores[i] := lstColores[i];
    pPopup.X := 0;
    pPopup.Y := edtValor.Height;
    pPopup := edtValor.ClientToScreen(pPopup);
    if SeleccionarAvConPaleta(
      ConexionPrincipal,
      'CO',
      aColores,
      edtValor.Text,
      sColor,
                              pPopup.X, pPopup.Y, edtValor.Width) then
    begin
      edtValor.Text := sColor;
    end;
  finally
    FreeAndNil(lstColores);
    FreeAndNil(qryPaleta);
  end;
end;

procedure TfrmMtoBusquedaDatos.btnPerfilesClick(Sender: TObject);
begin
  sbFiltros.Click;
end;

procedure TfrmMtoBusquedaDatos.btnOcultarClick(Sender: TObject);
var
  i: Integer;
  bMostrar: Boolean;
begin
  bMostrar := pnlCriterios.Height < FAltoCriterios;
  for i := 0 to pnlCriterios.ControlCount - 1 do
  begin
    if pnlCriterios.Controls[i] <> btnOcultar then
      pnlCriterios.Controls[i].Visible := bMostrar;
  end;
  if bMostrar then
  begin
    pnlCriterios.Height := FAltoCriterios;
    btnOcultar.Top := 78;
    btnOcultar.Caption := SCaptionOcultarCriterios;
  end
  else
  begin
    pnlCriterios.Height := 30;
    btnOcultar.Top := 3;
    btnOcultar.Caption := SCaptionMostrarCriterios;
  end;
end;

procedure TfrmMtoBusquedaDatos.edtValorKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    Buscar;
  end;
end;

procedure TfrmMtoBusquedaDatos.Buscar;
var
  swTotal: TStopwatch;
  swTramo: TStopwatch;
  bConsultaPreparada: Boolean;
  msPreparar: Int64;
  msConsulta: Int64;
  msColumnas: Int64;
  msInterfaz: Int64;
begin
  swTotal := TStopwatch.StartNew;
  msConsulta := 0;
  msColumnas := 0;
  msInterfaz := 0;
  Screen.Cursor := crHourGlass;
  try
    swTramo := TStopwatch.StartNew;
    bConsultaPreparada := PrepararConsulta;
    msPreparar := swTramo.ElapsedMilliseconds;
    if bConsultaPreparada then
    begin
      swTramo := TStopwatch.StartNew;
      unqryResultados.Open;
      msConsulta := swTramo.ElapsedMilliseconds;
      if not FColumnasCreadas then
      begin
        swTramo := TStopwatch.StartNew;
        ProcesarPerfiles;
        msColumnas := swTramo.ElapsedMilliseconds;
        FColumnasCreadas := True;
      end;
      swTramo := TStopwatch.StartNew;
      ActualizarColumnasColor;
      ActualizarContador;
      msInterfaz := swTramo.ElapsedMilliseconds;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  if bConsultaPreparada then
  begin
    inLibLog.Log.LogPerf('BusquedaDatos.Buscar',
      Format('campo=%d filas=%d preparar=%d consulta=%d columnas=%d ' +
             'interfaz=%d',
             [cbbCampo.ItemIndex, unqryResultados.RecordCount,
              msPreparar, msConsulta, msColumnas, msInterfaz]),
      swTotal.ElapsedMilliseconds);
  end;
end;

function TfrmMtoBusquedaDatos.DebeAjustarColumnasAutomaticamente: Boolean;
begin
  Result := False;
end;

function TfrmMtoBusquedaDatos.PrepararConsulta: Boolean;
var
  sCampo: string;
  sValor: string;
  sParametro: string;
  sFamilia: string;
  sProveedor: string;
  sTemporada: string;
  sHexObjetivo: string;
  sComponenteRojo: string;
  sComponenteVerde: string;
  sComponenteAzul: string;
  sDistancia: string;
  iRojo: Integer;
  iVerde: Integer;
  iAzul: Integer;
  bProximidad: Boolean;
begin
  Result := True;
  sValor := Trim(edtValor.Text);
  sFamilia := CodigoCombo(cbbFamilia);
  sProveedor := CodigoProveedor;
  sTemporada := CodigoCombo(cbbTemporada);
  bProximidad := cbbCampo.ItemIndex = CAMPO_PROXIMIDAD_COLOR;
  if bProximidad then
  begin
    Result := ResolverColorObjetivo(sValor, sHexObjetivo, iRojo,
                                    iVerde, iAzul);
    if not Result then
    begin
      MessageDlg(SErrorColorPaletaBusquedaInvalido,
        mtWarning, [mbOK], 0);
    end;
  end;
  if Result then
  begin
    if bProximidad then
      edtValor.Text := sHexObjetivo;
    sComponenteRojo :=
      'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 1, 2), 16, 10)';
    sComponenteVerde :=
      'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 3, 2), 16, 10)';
    sComponenteAzul :=
      'CONV(SUBSTRING(REPLACE(pal.HEX_ATB, ''#'', ''''), 5, 2), 16, 10)';
    sDistancia := 'ROUND(SQRT(POW(' + sComponenteRojo +
      ' - :ROJO, 2) + POW(' + sComponenteVerde +
      ' - :VERDE, 2) + POW(' + sComponenteAzul +
      ' - :AZUL, 2)), 2)';
    unqryResultados.Close;
    unqryResultados.SQL.Clear;
    unqryResultados.SQL.Add('SELECT eti.CODIGO_ART_ART,');
    unqryResultados.SQL.Add('       eti.CODIGO_UNIDAD_SKU,');
    unqryResultados.SQL.Add('       eti.DESCRIPCION_ART,');
    unqryResultados.SQL.Add('       eti.ATR_CO,');
    unqryResultados.SQL.Add('       pal.CODIGO_ATB AS CODIGO_COLOR_BASICO,');
    unqryResultados.SQL.Add('       pal.NOMBRE_ATB AS COLOR_BASICO,');
    unqryResultados.SQL.Add('       pal.HEX_ATB AS HEX_COLOR_BASICO,');
    if bProximidad then
      unqryResultados.SQL.Add(
        '       ' + sDistancia + ' AS DISTANCIA_COLOR,')
    else
      unqryResultados.SQL.Add(
        '       CAST(NULL AS DECIMAL(10, 2)) AS DISTANCIA_COLOR,');
    unqryResultados.SQL.Add('       eti.ATR_TAL,');
    unqryResultados.SQL.Add(
      '       COALESCE(stk.CANTIDAD_STOCK, 0) AS CANTIDAD_STOCK,');
    unqryResultados.SQL.Add(
      '       COALESCE(stk.CANTIDAD_STOCK_ALMACEN, 0)');
    unqryResultados.SQL.Add('         AS CANTIDAD_STOCK_ALMACEN,');
    unqryResultados.SQL.Add('       stk.ALMACENES_STOCK,');
    unqryResultados.SQL.Add('       eti.CODIGO_BARRAS_CB,');
    unqryResultados.SQL.Add('       eti.CODIGO_FAM_ART,');
    unqryResultados.SQL.Add('       eti.NOMBRE_FAM_FAM,');
    unqryResultados.SQL.Add('       eti.CODIGO_PRV_PRV,');
    unqryResultados.SQL.Add('       eti.RAZON_SOCIAL_PRV,');
    unqryResultados.SQL.Add('       eti.REF_PROVEEDOR,');
    unqryResultados.SQL.Add('       eti.PROP_TEMPORADA,');
    unqryResultados.SQL.Add('       eti.PROP_MARCA,');
    unqryResultados.SQL.Add('       eti.PROP_MATERIAL,');
    unqryResultados.SQL.Add('       eti.PROP_GENERO,');
    unqryResultados.SQL.Add('       eti.ATRIBUTOS_TXT,');
    unqryResultados.SQL.Add('       eti.PROPIEDADES_TXT,');
    unqryResultados.SQL.Add('       eti.ESACTIVO_ART,');
    unqryResultados.SQL.Add('       eti.ESACTIVO_SKU');
    unqryResultados.SQL.Add('  FROM vi_articulos_skus_etiquetas eti');
    unqryResultados.SQL.Add('  LEFT JOIN (');
    unqryResultados.SQL.Add(
      '       SELECT sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD_SKU,');
    unqryResultados.SQL.Add('              atb.CODIGO_ATB,');
    unqryResultados.SQL.Add('              atb.NOMBRE_ATB,');
    unqryResultados.SQL.Add('              atb.DESCRIPCION_ATB,');
    unqryResultados.SQL.Add('              atb.HEX_ATB');
    unqryResultados.SQL.Add('         FROM fza_atributos_sku sa');
    unqryResultados.SQL.Add('         JOIN fza_atributos_valores av');
    unqryResultados.SQL.Add('           ON av.ID_AV = sa.ID_AV_SA');
    unqryResultados.SQL.Add('          AND av.ID_VA_AV = ''CO''');
    unqryResultados.SQL.Add('         JOIN fza_articulos_skus sku');
    unqryResultados.SQL.Add(
      '           ON sku.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA');
    unqryResultados.SQL.Add(
      '    LEFT JOIN fza_articulos_atributos_basicos aab');
    unqryResultados.SQL.Add(
      '           ON aab.CODIGO_ART_AAB = sku.CODIGO_ART_SKU');
    unqryResultados.SQL.Add('          AND aab.ID_AV_AAB = av.ID_AV');
    unqryResultados.SQL.Add(
      '    LEFT JOIN fza_articulos_conjuntos_asign aca');
    unqryResultados.SQL.Add(
      '           ON aca.CODIGO_ART_ACA = sku.CODIGO_ART_SKU');
    unqryResultados.SQL.Add('          AND aca.ID_VA_ACA = av.ID_VA_AV');
    unqryResultados.SQL.Add(
      '    LEFT JOIN fza_atributos_conjuntos_det acd');
    unqryResultados.SQL.Add('           ON acd.ID_AC_ACD = aca.ID_AC_ACA');
    unqryResultados.SQL.Add('          AND acd.ID_AV_ACD = av.ID_AV');
    unqryResultados.SQL.Add('    LEFT JOIN fza_atributos_basicos atb');
    unqryResultados.SQL.Add('           ON atb.ID_ATB = CASE');
    unqryResultados.SQL.Add(
      '                WHEN aab.CODIGO_ART_AAB IS NOT NULL');
    unqryResultados.SQL.Add('                THEN aab.ID_ATB_AAB');
    unqryResultados.SQL.Add('                WHEN acd.ID_ATB_ACD IS NOT NULL');
    unqryResultados.SQL.Add('                THEN acd.ID_ATB_ACD');
    unqryResultados.SQL.Add('                ELSE av.ID_ATB_AV');
    unqryResultados.SQL.Add('              END');
    unqryResultados.SQL.Add('       ) pal');
    unqryResultados.SQL.Add(
      '    ON pal.CODIGO_UNIDAD_SKU = eti.CODIGO_UNIDAD_SKU');
    unqryResultados.SQL.Add('  LEFT JOIN (');
    unqryResultados.SQL.Add('       SELECT CODIGO_UNIDAD_STK,');
    unqryResultados.SQL.Add(
      '              SUM(CANTIDAD_STK) AS CANTIDAD_STOCK,');
    unqryResultados.SQL.Add(
      '              SUM(CASE WHEN CODIGO_ALM_STK = :ALMACEN_DOC');
    unqryResultados.SQL.Add('                       THEN CANTIDAD_STK');
    unqryResultados.SQL.Add('                       ELSE 0 END)');
    unqryResultados.SQL.Add('                AS CANTIDAD_STOCK_ALMACEN,');
    unqryResultados.SQL.Add(
      '              GROUP_CONCAT(DISTINCT CODIGO_ALM_STK');
    unqryResultados.SQL.Add(
      '                ORDER BY CODIGO_ALM_STK SEPARATOR '', '')');
    unqryResultados.SQL.Add('                AS ALMACENES_STOCK');
    unqryResultados.SQL.Add('         FROM fza_articulos_stockactual');
    unqryResultados.SQL.Add('        GROUP BY CODIGO_UNIDAD_STK');
    unqryResultados.SQL.Add('       ) stk');
    unqryResultados.SQL.Add(
      '    ON stk.CODIGO_UNIDAD_STK = eti.CODIGO_UNIDAD_SKU');
    unqryResultados.SQL.Add(' WHERE 1 = 1');
    if cbbEstado.ItemIndex = 0 then
    begin
      unqryResultados.SQL.Add('   AND eti.ESACTIVO_ART = ''S''');
      unqryResultados.SQL.Add('   AND eti.ESACTIVO_SKU = ''S''');
    end
    else if cbbEstado.ItemIndex = 2 then
    begin
      unqryResultados.SQL.Add(
        '   AND (COALESCE(eti.ESACTIVO_ART, ''N'') <> ''S''');
      unqryResultados.SQL.Add(
        '     OR COALESCE(eti.ESACTIVO_SKU, ''N'') <> ''S'')');
    end;
    if cbbStock.ItemIndex = 1 then
      unqryResultados.SQL.Add(
        '   AND COALESCE(stk.CANTIDAD_STOCK, 0) > 0')
    else if cbbStock.ItemIndex = 2 then
      unqryResultados.SQL.Add(
        '   AND COALESCE(stk.CANTIDAD_STOCK, 0) <= 0');
    if sFamilia <> '' then
      unqryResultados.SQL.Add(
        '   AND eti.CODIGO_FAM_ART = :FAMILIA');
    if sProveedor <> '' then
      unqryResultados.SQL.Add(
        '   AND eti.CODIGO_PRV_PRV = :PROVEEDOR');
    if sTemporada <> '' then
      unqryResultados.SQL.Add(
        '   AND eti.PROP_TEMPORADA = :TEMPORADA');
    if bProximidad then
      unqryResultados.SQL.Add(
        '   AND pal.HEX_ATB REGEXP ''^#?[0-9A-Fa-f]{6}$''')
    else if sValor <> '' then
    begin
      sCampo := ObtenerExpresionCampo;
      if chkDistinguirMayusculas.Checked then
        sCampo := 'BINARY COALESCE(' + sCampo + ', '''')'
      else
      begin
        sCampo := 'UPPER(COALESCE(' + sCampo + ', ''''))';
        sValor := UpperCase(sValor);
      end;
      sParametro := sValor;
      case cbbCoincidencia.ItemIndex of
        0:
          begin
            unqryResultados.SQL.Add(
              '   AND ' + sCampo + ' LIKE :BUSQUEDA');
            sParametro := '%' + sValor + '%';
          end;
        1:
          begin
            unqryResultados.SQL.Add(
              '   AND ' + sCampo + ' LIKE :BUSQUEDA');
            sParametro := sValor + '%';
          end;
        2:
          unqryResultados.SQL.Add(
            '   AND ' + sCampo + ' = :BUSQUEDA');
        3:
          begin
            unqryResultados.SQL.Add(
              '   AND ' + sCampo + ' LIKE :BUSQUEDA');
            sParametro := '%' + sValor;
          end;
        4:
          begin
            unqryResultados.SQL.Add(
              '   AND ' + sCampo + ' NOT LIKE :BUSQUEDA');
            sParametro := '%' + sValor + '%';
          end;
      end;
    end;
    if bProximidad then
    begin
      unqryResultados.SQL.Add(
        ' ORDER BY DISTANCIA_COLOR, eti.CODIGO_ART_ART,');
      unqryResultados.SQL.Add('          eti.CODIGO_UNIDAD_SKU');
    end
    else
    begin
      unqryResultados.SQL.Add(
        ' ORDER BY eti.CODIGO_ART_ART, eti.ATR_CO, eti.ATR_TAL,');
      unqryResultados.SQL.Add('          eti.CODIGO_UNIDAD_SKU');
    end;
    unqryResultados.SQL.Add(' LIMIT ' + IntToStr(ObtenerLimite));
    unqryResultados.ParamByName('ALMACEN_DOC').AsString := UbicacionSesion.Almacen;
    if sFamilia <> '' then
      unqryResultados.ParamByName('FAMILIA').AsString := sFamilia;
    if sProveedor <> '' then
      unqryResultados.ParamByName('PROVEEDOR').AsString := sProveedor;
    if sTemporada <> '' then
      unqryResultados.ParamByName('TEMPORADA').AsString := sTemporada;
    if bProximidad then
    begin
      unqryResultados.ParamByName('ROJO').AsInteger := iRojo;
      unqryResultados.ParamByName('VERDE').AsInteger := iVerde;
      unqryResultados.ParamByName('AZUL').AsInteger := iAzul;
    end
    else if sValor <> '' then
      unqryResultados.ParamByName('BUSQUEDA').AsString := sParametro;
  end;
end;

function TfrmMtoBusquedaDatos.ObtenerExpresionCampo: string;
begin
  case cbbCampo.ItemIndex of
    CAMPO_ARTICULO:
      Result := 'eti.CODIGO_ART_ART';
    CAMPO_SKU:
      Result := 'eti.CODIGO_UNIDAD_SKU';
    CAMPO_DESCRIPCION:
      Result := 'eti.DESCRIPCION_ART';
    CAMPO_TALLA:
      Result := 'eti.ATR_TAL';
    CAMPO_COLOR:
      Result := 'eti.ATR_CO';
    CAMPO_COLOR_BASICO:
      Result :=
        'CONCAT_WS('' '', pal.CODIGO_ATB, pal.NOMBRE_ATB, ' +
        'pal.DESCRIPCION_ATB, pal.HEX_ATB)';
    CAMPO_CODIGO_BARRAS:
      Result := 'eti.CODIGO_BARRAS_CB';
    CAMPO_FAMILIA:
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_FAM_ART, eti.NOMBRE_FAM_FAM)';
    CAMPO_PROVEEDOR:
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_PRV_PRV, ' +
        'eti.RAZON_SOCIAL_PRV)';
    CAMPO_REF_PROVEEDOR:
      Result := 'eti.REF_PROVEEDOR';
    CAMPO_TEMPORADA:
      Result := 'eti.PROP_TEMPORADA';
    CAMPO_ALMACEN:
      Result := 'stk.ALMACENES_STOCK';
    CAMPO_PROPIEDADES:
      Result :=
        'CONCAT_WS('' '', eti.ATRIBUTOS_TXT, ' +
        'eti.PROPIEDADES_TXT)';
    else
      Result :=
        'CONCAT_WS('' '', eti.CODIGO_ART_ART, ' +
        'eti.CODIGO_UNIDAD_SKU, eti.DESCRIPCION_ART, eti.ATR_CO, ' +
        'eti.ATR_TAL, eti.CODIGO_BARRAS_CB, eti.CODIGO_FAM_ART, ' +
        'eti.NOMBRE_FAM_FAM, eti.CODIGO_PRV_PRV, ' +
        'eti.RAZON_SOCIAL_PRV, eti.REF_PROVEEDOR, ' +
        'eti.PROP_TEMPORADA, eti.ATRIBUTOS_TXT, ' +
        'eti.PROPIEDADES_TXT, stk.ALMACENES_STOCK, ' +
        'pal.CODIGO_ATB, pal.NOMBRE_ATB, pal.HEX_ATB)';
  end;
end;

function TfrmMtoBusquedaDatos.NormalizarHexColor(const AValor: string;
  out AHex: string; out ARojo, AVerde, AAzul: Integer): Boolean;
var
  sHex: string;
  cColor: TColor;
begin
  sHex := Trim(AValor);
  if (sHex <> '') and (sHex[1] <> '#') then
    sHex := '#' + sHex;
  cColor := inLibAtributosPaleta.HexToColor(sHex);
  Result := cColor <> clNone;
  if Result then
  begin
    cColor := ColorToRGB(cColor);
    ARojo := GetRValue(cColor);
    AVerde := GetGValue(cColor);
    AAzul := GetBValue(cColor);
    AHex := Format('#%.2X%.2X%.2X', [ARojo, AVerde, AAzul]);
  end;
end;

function TfrmMtoBusquedaDatos.ResolverColorObjetivo(
  const AValor: string; out AHex: string;
  out ARojo, AVerde, AAzul: Integer): Boolean;
var
  qryColor: TUniQuery;
  sValor: string;
begin
  Result := NormalizarHexColor(AValor, AHex, ARojo, AVerde, AAzul);
  if (not Result) and (Trim(AValor) <> '') then
  begin
    qryColor := TUniQuery.Create(nil);
    try
      qryColor.Connection := ConexionPrincipal;
      qryColor.SQL.Add('SELECT HEX_ATB');
      qryColor.SQL.Add('  FROM fza_atributos_basicos');
      qryColor.SQL.Add(' WHERE ID_VA_ATB = ''CO''');
      qryColor.SQL.Add('   AND ESACTIVO_ATB = ''S''');
      qryColor.SQL.Add('   AND HEX_ATB IS NOT NULL');
      qryColor.SQL.Add('   AND (UPPER(CODIGO_ATB) = :VALOR');
      qryColor.SQL.Add(
        '     OR UPPER(REPLACE(CODIGO_ATB, ''_'', '' '')) = :VALOR');
      qryColor.SQL.Add('     OR UPPER(NOMBRE_ATB) = :VALOR');
      qryColor.SQL.Add('     OR UPPER(DESCRIPCION_ATB) = :VALOR)');
      qryColor.SQL.Add(' ORDER BY ORDEN_ATB, CODIGO_ATB');
      qryColor.SQL.Add(' LIMIT 1');
      sValor := UpperCase(Trim(AValor));
      qryColor.ParamByName('VALOR').AsString := sValor;
      qryColor.Open;
      if not qryColor.IsEmpty then
      begin
        Result := NormalizarHexColor(
          qryColor.FieldByName('HEX_ATB').AsString, AHex,
          ARojo, AVerde, AAzul);
      end;
    finally
      FreeAndNil(qryColor);
    end;
  end;
end;

function TfrmMtoBusquedaDatos.ResolverLineaDocumentoTrabajo(
  out ALinea: TDocTrabajoLineaOrigen;
  out AMensaje: string): Boolean;
var
  ds: TDataSet;
  rec: TcxCustomGridRecord;
  sColor: string;
  sTalla: string;
begin
  Result := False;
  ALinea.Clear;
  AMensaje := '';
  ds := unqryResultados;
  rec := cxGrdDBTabPrin.Controller.FocusedRecord;
  if (rec = nil) or (rec.RecordIndex < 0) then
  begin
    AMensaje := 'Seleccione una fila de SKU de la rejilla.';
  end
  else if (not ds.Active) or ds.IsEmpty then
  begin
    AMensaje := 'Seleccione un SKU de la rejilla.';
  end
  else if (ds.FindField('CODIGO_ART_ART') = nil) or
          (ds.FindField('CODIGO_UNIDAD_SKU') = nil) then
  begin
    AMensaje := 'No se ha podido identificar el artículo y el SKU.';
  end
  else
  begin
    ALinea.CodigoArticulo :=
      ds.FieldByName('CODIGO_ART_ART').AsString;
    ALinea.CodigoSku :=
      ds.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    if (Trim(ALinea.CodigoArticulo) = '') or
       (Trim(ALinea.CodigoSku) = '') then
    begin
      AMensaje := 'Seleccione una fila que contenga un SKU válido.';
    end
    else
    begin
      ALinea.CodigoAlmacen := UbicacionSesion.Almacen;
      ALinea.DescripcionArticulo :=
        ds.FieldByName('DESCRIPCION_ART').AsString;
      sColor := ds.FieldByName('ATR_CO').AsString;
      sTalla := ds.FieldByName('ATR_TAL').AsString;
      ALinea.DescripcionSku := Trim(sColor + ' ' + sTalla);
      if ALinea.DescripcionSku = '' then
        ALinea.DescripcionSku := ALinea.CodigoSku;
      ALinea.CantidadStock :=
        ds.FieldByName('CANTIDAD_STOCK_ALMACEN').AsFloat;
      ALinea.Cantidad := ALinea.CantidadStock;
      ALinea.Origen := 'CTRL_E';
      Result := True;
    end;
  end;
end;

function TfrmMtoBusquedaDatos.CodigoCombo(ACombo: TcxComboBox): string;
var
  iSeparador: Integer;
  sTexto: string;
begin
  Result := '';
  if ACombo.ItemIndex > 0 then
  begin
    sTexto := Trim(ACombo.Text);
    iSeparador := Pos(' - ', sTexto);
    if iSeparador > 0 then
      Result := Copy(sTexto, 1, iSeparador - 1)
    else
      Result := sTexto;
  end;
end;

function TfrmMtoBusquedaDatos.CodigoProveedor: string;
begin
  Result := Trim(VarToStr(cbbProveedor.EditValue));
end;

function TfrmMtoBusquedaDatos.ObtenerLimite: Integer;
begin
  case cbbLimite.ItemIndex of
    0:
      Result := 500;
    2:
      Result := 5000;
    else
      Result := 2000;
  end;
end;

procedure TfrmMtoBusquedaDatos.ActualizarContador;
var
  iFilas: Integer;
begin
  iFilas := unqryResultados.RecordCount;
  if iFilas >= ObtenerLimite then
    lblResultados.Caption := Format(SCaptionSkuEncontradosLimite,
                                    [FormatFloat('#,##0', iFilas)])
  else
    lblResultados.Caption := Format(SCaptionSkuEncontrados,
                                    [FormatFloat('#,##0', iFilas)]);
end;

procedure TfrmMtoBusquedaDatos.CrearTablaPrincipal;
begin
  inherited;
  ConfigurarColumna('CODIGO_ART_ART', 'Artículo', 120, True);
  ConfigurarColumna('CODIGO_UNIDAD_SKU', 'SKU', 190, True);
  ConfigurarColumna('DESCRIPCION_ART', 'Descripción', 230, True);
  ConfigurarColumna('ATR_CO', 'Color', 125, True);
  ConfigurarColumna('CODIGO_COLOR_BASICO', 'Código básico', 110, False);
  ConfigurarColumna('COLOR_BASICO', 'Color básico', 155, True);
  ConfigurarColumna('HEX_COLOR_BASICO', 'HEX', 85, True);
  ConfigurarColumna('DISTANCIA_COLOR', 'Distancia RGB', 95, False);
  ConfigurarColumna('ATR_TAL', 'Talla', 75, True);
  ConfigurarColumna('CANTIDAD_STOCK', 'Stock', 75, True);
  ConfigurarColumna('CANTIDAD_STOCK_ALMACEN', 'Stock almacén', 95, False);
  ConfigurarColumna('ALMACENES_STOCK', 'Almacenes', 110, True);
  ConfigurarColumna('CODIGO_BARRAS_CB', 'Código de barras', 135, True);
  ConfigurarColumna('CODIGO_FAM_ART', 'Familia', 90, True);
  ConfigurarColumna('NOMBRE_FAM_FAM', 'Nombre familia', 150, True);
  ConfigurarColumna('CODIGO_PRV_PRV', 'Proveedor', 90, True);
  ConfigurarColumna('RAZON_SOCIAL_PRV', 'Nombre proveedor', 180, True);
  ConfigurarColumna('REF_PROVEEDOR', 'Referencia proveedor', 130, True);
  ConfigurarColumna('PROP_TEMPORADA', 'Temporada', 110, True);
  ConfigurarColumna('PROP_MARCA', 'Marca', 110, False);
  ConfigurarColumna('PROP_MATERIAL', 'Material', 120, False);
  ConfigurarColumna('PROP_GENERO', 'Género', 90, False);
  ConfigurarColumna('ATRIBUTOS_TXT', 'Atributos', 220, False);
  ConfigurarColumna('PROPIEDADES_TXT', 'Propiedades', 260, False);
  ConfigurarColumna('ESACTIVO_ART', 'Artículo activo', 90, False);
  ConfigurarColumna('ESACTIVO_SKU', 'SKU activo', 80, False);
  ActualizarColumnasColor;
end;

procedure TfrmMtoBusquedaDatos.ActualizarColumnasColor;
var
  col: TcxGridDBColumn;
  bProximidad: Boolean;
begin
  if FColumnasCreadas or (cxGrdDBTabPrin.ColumnCount > 0) then
  begin
    bProximidad := cbbCampo.ItemIndex = CAMPO_PROXIMIDAD_COLOR;
    col := cxGrdDBTabPrin.GetColumnByFieldName('DISTANCIA_COLOR');
    if Assigned(col) then
      col.Visible := bProximidad;
    col := cxGrdDBTabPrin.GetColumnByFieldName('COLOR_BASICO');
    if Assigned(col) then
    begin
      col.Visible := True;
      col.OnCustomDrawCell := cxGrdDBTabPrinColorCustomDrawCell;
    end;
    col := cxGrdDBTabPrin.GetColumnByFieldName('ATR_CO');
    if Assigned(col) then
      col.OnCustomDrawCell := cxGrdDBTabPrinColorCustomDrawCell;
  end;
end;

procedure TfrmMtoBusquedaDatos.cxGrdDBTabPrinColorCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  colHex: TcxGridDBColumn;
  infoColor: TInfoBasico;
  sHex: string;
  sTexto: string;
begin
  ADone := False;
  colHex := cxGrdDBTabPrin.GetColumnByFieldName('HEX_COLOR_BASICO');
  if Assigned(AViewInfo) and Assigned(AViewInfo.GridRecord) and
     Assigned(colHex) then
  begin
    sHex := VarToStr(AViewInfo.GridRecord.Values[colHex.Index]);
    infoColor := Default(TInfoBasico);
    infoColor.HexColor := sHex;
    infoColor.Color := inLibAtributosPaleta.HexToColor(sHex);
    infoColor.EsValido := infoColor.Color <> clNone;
    sTexto := AViewInfo.Text;
    if infoColor.EsValido then
    begin
      ADone := PintarCeldaConCuadradoColor(ACanvas, AViewInfo,
                                          infoColor, sTexto);
    end;
  end;
end;

procedure TfrmMtoBusquedaDatos.ConfigurarColumna(
  const ACampo, ATitulo: string; AAncho: Integer; AVisible: Boolean);
var
  col: TcxGridDBColumn;
begin
  col := cxGrdDBTabPrin.GetColumnByFieldName(ACampo);
  if Assigned(col) then
  begin
    col.Caption := ATitulo;
    col.Width := AAncho;
    col.Visible := AVisible;
  end;
end;

end.
