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
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Data.DB, Uni,
  cxControls, cxContainer, cxEdit, cxLabel, cxTextEdit, cxCheckBox,
  cxButtons, cxMaskEdit, cxDropDownEdit, cxGridDBTableView,
  inMtoGenSearch, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxDBData, Vcl.Menus, cxBlobEdit, MemDS, DBAccess, System.Actions,
  Vcl.ActnList, Vcl.Dialogs, dxShellDialogs, JvComponentBase, JvEnterTab,
  cxLocalization, Vcl.StdCtrls, cxRadioGroup, cxNavigator, cxDBNavigator,
  Vcl.Buttons, cxGridCustomTableView, cxGridTableView, cxGridLevel, cxClasses,
  cxGridCustomView, cxGrid, cxPC;

type
  TfrmMtoBusquedaDatos = class(TfrmMtoSearch)
    pnlCriterios: TPanel;
    lblCampo: TcxLabel;
    cbbCampo: TcxComboBox;
    lblValor: TcxLabel;
    edtValor: TcxTextEdit;
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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnPerfilesClick(Sender: TObject);
    procedure btnOcultarClick(Sender: TObject);
    procedure edtValorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FColumnasCreadas: Boolean;
    FAltoCriterios: Integer;
    procedure InicializarListas;
    procedure Buscar;
    procedure PrepararConsulta;
    procedure ActualizarContador;
    procedure ConfigurarColumna(const ACampo, ATitulo: string;
      AAncho: Integer; AVisible: Boolean);
    function ObtenerExpresionCampo: string;
    function ObtenerLimite: Integer;
  public
    class procedure Ejecutar(AOwner: TComponent;
      AParentForm: TCustomForm = nil);
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoBusquedaDatos: TfrmMtoBusquedaDatos;

implementation

uses
  inLibGlobalVar, inLibLog, inLibShowMto;

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

class procedure TfrmMtoBusquedaDatos.Ejecutar(AOwner: TComponent;
  AParentForm: TCustomForm);
var
  frm: TfrmMtoBusquedaDatos;
  sCodigoArt: string;
begin
  sCodigoArt := '';
  frm := TfrmMtoBusquedaDatos.Create(nil);
  try
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
  unqryResultados.Connection := inLibGlobalVar.oConn;
  unqryResultados.ReadOnly := True;
  dsTablaG.DataSet := unqryResultados;
  FColumnasCreadas := False;
  FAltoCriterios := pnlCriterios.Height;
  InicializarListas;
  cxGrdDBTabPrin.FilterRow.Visible := True;
  cxGrdDBTabPrin.OptionsView.GroupByBox := True;
end;

procedure TfrmMtoBusquedaDatos.FormShow(Sender: TObject);
begin
  inherited;
  Buscar;
  TThread.ForceQueue(nil,
    procedure
    begin
      if (not (csDestroying in ComponentState)) and
         edtValor.CanFocus then
        edtValor.SetFocus;
    end);
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
  cbbStock.ItemIndex := 0;
  cbbLimite.Properties.Items.Clear;
  cbbLimite.Properties.Items.Add('500');
  cbbLimite.Properties.Items.Add('2.000');
  cbbLimite.Properties.Items.Add('5.000');
  cbbLimite.ItemIndex := 1;
end;

procedure TfrmMtoBusquedaDatos.btnBuscarClick(Sender: TObject);
begin
  Buscar;
end;

procedure TfrmMtoBusquedaDatos.btnLimpiarClick(Sender: TObject);
begin
  edtValor.Clear;
  cbbCampo.ItemIndex := CAMPO_TALLA;
  cbbCoincidencia.ItemIndex := 0;
  cbbEstado.ItemIndex := 0;
  cbbStock.ItemIndex := 0;
  chkDistinguirMayusculas.Checked := False;
  edtBusqGlobal.Clear;
  cxGrdDBTabPrin.DataController.Filter.Clear;
  Buscar;
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
    btnOcultar.Caption := 'Ocultar criterios';
  end
  else
  begin
    pnlCriterios.Height := 30;
    btnOcultar.Top := 3;
    btnOcultar.Caption := 'Mostrar criterios';
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
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  Screen.Cursor := crHourGlass;
  try
    PrepararConsulta;
    unqryResultados.Open;
    if not FColumnasCreadas then
    begin
      ProcesarPerfiles;
      FColumnasCreadas := True;
    end;
    ActualizarContador;
  finally
    Screen.Cursor := crDefault;
  end;
  inLibLog.Log.LogPerf('BusquedaDatos.Buscar',
    Format('campo=%d filas=%d',
           [cbbCampo.ItemIndex, unqryResultados.RecordCount]),
    sw.ElapsedMilliseconds);
end;

procedure TfrmMtoBusquedaDatos.PrepararConsulta;
var
  sCampo: string;
  sValor: string;
  sParametro: string;
begin
  unqryResultados.Close;
  unqryResultados.SQL.Clear;
  unqryResultados.SQL.Add('SELECT eti.CODIGO_ART_ART,');
  unqryResultados.SQL.Add('       eti.CODIGO_UNIDAD_SKU,');
  unqryResultados.SQL.Add('       eti.DESCRIPCION_ART,');
  unqryResultados.SQL.Add('       eti.ATR_CO,');
  unqryResultados.SQL.Add('       eti.ATR_TAL,');
  unqryResultados.SQL.Add(
    '       COALESCE(stk.CANTIDAD_STOCK, 0) AS CANTIDAD_STOCK,');
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
  unqryResultados.SQL.Add('       SELECT CODIGO_UNIDAD_STK,');
  unqryResultados.SQL.Add(
    '              SUM(CANTIDAD_STK) AS CANTIDAD_STOCK,');
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
  sValor := Trim(edtValor.Text);
  if sValor <> '' then
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
  unqryResultados.SQL.Add(
    ' ORDER BY eti.CODIGO_ART_ART, eti.ATR_CO, eti.ATR_TAL,');
  unqryResultados.SQL.Add('          eti.CODIGO_UNIDAD_SKU');
  unqryResultados.SQL.Add(' LIMIT ' + IntToStr(ObtenerLimite));
  if sValor <> '' then
    unqryResultados.ParamByName('BUSQUEDA').AsString := sParametro;
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
        'eti.PROPIEDADES_TXT, stk.ALMACENES_STOCK)';
  end;
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
  lblResultados.Caption := Format('%s SKU encontrados',
                                  [FormatFloat('#,##0', iFilas)]);
  if iFilas >= ObtenerLimite then
  begin
    lblResultados.Caption := lblResultados.Caption +
      ' (límite alcanzado; concrete la búsqueda)';
  end;
end;

procedure TfrmMtoBusquedaDatos.CrearTablaPrincipal;
begin
  inherited;
  ConfigurarColumna('CODIGO_ART_ART', 'Artículo', 120, True);
  ConfigurarColumna('CODIGO_UNIDAD_SKU', 'SKU', 190, True);
  ConfigurarColumna('DESCRIPCION_ART', 'Descripción', 230, True);
  ConfigurarColumna('ATR_CO', 'Color', 95, True);
  ConfigurarColumna('ATR_TAL', 'Talla', 75, True);
  ConfigurarColumna('CANTIDAD_STOCK', 'Stock', 75, True);
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
