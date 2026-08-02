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
  Vcl.Graphics, Data.DB,
  cxControls, cxContainer, cxEdit, cxLabel, cxTextEdit, cxCheckBox,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxGridDBTableView,
  inMtoGenSearch, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxDBData, Vcl.Menus, cxBlobEdit, System.Actions,
  Vcl.ActnList, Vcl.Dialogs, dxShellDialogs, JvComponentBase, JvEnterTab,
  cxLocalization, Vcl.StdCtrls, cxRadioGroup, cxNavigator, cxDBNavigator,
  Vcl.Buttons, cxGridCustomTableView, cxGridTableView, cxGridLevel, cxClasses,
  cxGridCustomView, cxGrid, cxPC, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, inLibDocumentosTrabajo,
  inLibBusquedaDatosPersistenciaIntf;

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
    btnOcultar: TcxButton;
    btnPerfiles: TcxButton;
    lblFamilia: TcxLabel;
    cbbFamilia: TcxComboBox;
    lblProveedor: TcxLabel;
    cbbProveedor: TcxLookupComboBox;
    lblTemporada: TcxLabel;
    cbbTemporada: TcxComboBox;
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
    FRepositorioPersistencia: IRepositorioBusquedaDatos;
    FResultadoBusqueda: IResultadoBusquedaDatos;
    FResultadoProveedores: IResultadoBusquedaDatos;
    procedure InicializarListas;
    procedure CargarFiltrosPrecarga;
    procedure CargarCombo(
      ACombo: TcxComboBox;
      const AOpciones: TOpcionesBusquedaDatos);
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
  inLibShowMto, inLibAtributosPaleta, inLibMsgComun,
  inLibDocumentosTrabajoPresentacion;

{$R *.dfm}

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
       Assigned(frm.dsTablaG.DataSet) and
       frm.dsTablaG.DataSet.Active and
       (not frm.dsTablaG.DataSet.IsEmpty) then
    begin
      sCodigoArt := frm.dsTablaG.DataSet.FieldByName(
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
  FRepositorioPersistencia :=
    ContextoRepositoriosPantalla.Configuracion.
      CrearRepositorioBusquedaDatos(ConexionPrincipal);
  dsTablaG.DataSet := nil;
  dsProveedoresBusqueda.DataSet := nil;
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
        ContextoRepositoriosPantalla.Documentos.
          CrearRepositoriosDocumentosTrabajo(ConexionPrincipal),
        CrearInteraccionDocumentosTrabajoVcl,
        BusquedaVisual, ContextoSesion, ParametrosCaja, linea,
        ContextoRepositoriosPantalla.Articulos.
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
  RegistroLog.RegistrarRendimiento('BusquedaDatos.Abrir',
    'formulario visible sin consultar artículos',
    FCronometroApertura.ElapsedMilliseconds);
  sw := TStopwatch.StartNew;
  CargarFiltrosPrecarga;
  RegistroLog.RegistrarRendimiento('BusquedaDatos.Precarga',
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
  CargarCombo(
    cbbFamilia,
    FRepositorioPersistencia.ListarFamilias);
  dsProveedoresBusqueda.DataSet := nil;
  FResultadoProveedores :=
    FRepositorioPersistencia.ConsultarProveedores;
  dsProveedoresBusqueda.DataSet := FResultadoProveedores.DataSet;
  cbbProveedor.EditValue := Null;
  CargarCombo(
    cbbTemporada,
    FRepositorioPersistencia.ListarTemporadas);
end;

procedure TfrmMtoBusquedaDatos.CargarCombo(
  ACombo: TcxComboBox;
  const AOpciones: TOpcionesBusquedaDatos);
var
  oOpcion: TOpcionBusquedaDatos;
  sCodigo: string;
  sNombre: string;
begin
  ACombo.Properties.Items.BeginUpdate;
  try
    ACombo.Properties.Items.Clear;
    ACombo.Properties.Items.Add('(Todos)');
    for oOpcion in AOpciones do
    begin
      sCodigo := oOpcion.Codigo;
      sNombre := oOpcion.Nombre;
      if (sNombre <> '') and (sNombre <> sCodigo) then
        ACombo.Properties.Items.Add(sCodigo + ' - ' + sNombre)
      else
        ACombo.Properties.Items.Add(sCodigo);
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
  if Assigned(dsTablaG.DataSet) then
  begin
    dsTablaG.DataSet.Close;
  end;
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
  oProveedores: TDataSet;
  sBusqueda: string;
  sCodigo: string;
  sCodigoEncontrado: string;
  sNombre: string;
begin
  oProveedores := dsProveedoresBusqueda.DataSet;
  sBusqueda := FBusquedaProveedor;
  sCodigoEncontrado := '';
  if sBusqueda = '' then
    cbbProveedor.EditValue := Null
  else if Assigned(oProveedores) and oProveedores.Active then
  begin
    oProveedores.First;
    while (not oProveedores.Eof) and
          (sCodigoEncontrado = '') do
    begin
      sCodigo := Trim(oProveedores.FieldByName(
                                           'CODIGO_PRV_PRV').AsString);
      sNombre := Trim(oProveedores.FieldByName(
                                         'RAZON_SOCIAL_PRV').AsString);
      if SameText(Copy(sCodigo, 1, Length(sBusqueda)), sBusqueda) or
         SameText(Copy(sNombre, 1, Length(sBusqueda)), sBusqueda) then
        sCodigoEncontrado := sCodigo;
      oProveedores.Next;
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
  aColores: TCadenasBusquedaDatos;
  sColor: string;
  pPopup: TPoint;
begin
  aColores := FRepositorioPersistencia.ListarColoresPaleta;
  pPopup.X := 0;
  pPopup.Y := edtValor.Height;
  pPopup := edtValor.ClientToScreen(pPopup);
  if SeleccionarAvConPaleta(
    ConexionPrincipal,
    'CO',
    aColores,
    edtValor.Text,
    sColor,
    pPopup.X,
    pPopup.Y,
    edtValor.Width) then
  begin
    edtValor.Text := sColor;
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
      dsTablaG.DataSet.Open;
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
    RegistroLog.RegistrarRendimiento('BusquedaDatos.Buscar',
      Format('campo=%d filas=%d preparar=%d consulta=%d columnas=%d ' +
             'interfaz=%d',
             [cbbCampo.ItemIndex, dsTablaG.DataSet.RecordCount,
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
  oCriterios: TCriteriosBusquedaDatos;
  sHexObjetivo: string;
  iRojo: Integer;
  iVerde: Integer;
  iAzul: Integer;
  bProximidad: Boolean;
begin
  Result := True;
  iRojo := 0;
  iVerde := 0;
  iAzul := 0;
  bProximidad := cbbCampo.ItemIndex = CAMPO_PROXIMIDAD_COLOR;
  if bProximidad then
  begin
    Result := ResolverColorObjetivo(
      Trim(edtValor.Text),
      sHexObjetivo,
      iRojo,
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
    begin
      edtValor.Text := sHexObjetivo;
    end;
    oCriterios := Default(TCriteriosBusquedaDatos);
    oCriterios.Campo := cbbCampo.ItemIndex;
    oCriterios.Coincidencia := cbbCoincidencia.ItemIndex;
    oCriterios.Estado := cbbEstado.ItemIndex;
    oCriterios.Stock := cbbStock.ItemIndex;
    oCriterios.Limite := ObtenerLimite;
    oCriterios.DistinguirMayusculas :=
      chkDistinguirMayusculas.Checked;
    oCriterios.Valor := Trim(edtValor.Text);
    oCriterios.Familia := CodigoCombo(cbbFamilia);
    oCriterios.Proveedor := CodigoProveedor;
    oCriterios.Temporada := CodigoCombo(cbbTemporada);
    oCriterios.Almacen := UbicacionSesion.Almacen;
    oCriterios.Rojo := iRojo;
    oCriterios.Verde := iVerde;
    oCriterios.Azul := iAzul;
    dsTablaG.DataSet := nil;
    FResultadoBusqueda :=
      FRepositorioPersistencia.PrepararBusqueda(oCriterios);
    dsTablaG.DataSet := FResultadoBusqueda.DataSet;
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
  sHexEncontrado: string;
begin
  Result := NormalizarHexColor(AValor, AHex, ARojo, AVerde, AAzul);
  if (not Result) and (Trim(AValor) <> '') then
  begin
    sHexEncontrado :=
      FRepositorioPersistencia.BuscarHexColor(AValor);
    if sHexEncontrado <> '' then
    begin
      Result := NormalizarHexColor(
        sHexEncontrado,
        AHex,
        ARojo,
        AVerde,
        AAzul);
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
  ds := dsTablaG.DataSet;
  rec := cxGrdDBTabPrin.Controller.FocusedRecord;
  if (rec = nil) or (rec.RecordIndex < 0) then
  begin
    AMensaje := 'Seleccione una fila de SKU de la rejilla.';
  end
  else if (not Assigned(ds)) or (not ds.Active) or ds.IsEmpty then
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
  iFilas := dsTablaG.DataSet.RecordCount;
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
