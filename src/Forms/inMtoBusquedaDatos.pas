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
  cxGridCustomView, cxGrid, cxPC;

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
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnPerfilesClick(Sender: TObject);
    procedure btnOcultarClick(Sender: TObject);
    procedure edtValorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbbCampoPropertiesChange(Sender: TObject);
    procedure edtValorPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure cxGrdDBTabPrinColorCustomDrawCell(
      Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
  private
    FColumnasCreadas: Boolean;
    FAltoCriterios: Integer;
    procedure InicializarListas;
    procedure ActualizarInterfazCampo;
    procedure ActualizarColumnasColor;
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
  public
    class procedure Ejecutar(AOwner: TComponent;
      AParentForm: TCustomForm = nil);
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoBusquedaDatos: TfrmMtoBusquedaDatos;

implementation

uses
  inLibGlobalVar, inLibLog, inLibShowMto, inLibAtributosPaleta;

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
  cbbStock.ItemIndex := 0;
  cbbLimite.Properties.Items.Clear;
  cbbLimite.Properties.Items.Add('500');
  cbbLimite.Properties.Items.Add('2.000');
  cbbLimite.Properties.Items.Add('5.000');
  cbbLimite.ItemIndex := 1;
  ActualizarInterfazCampo;
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
  cbbStock.ItemIndex := 0;
  chkDistinguirMayusculas.Checked := False;
  edtBusqGlobal.Clear;
  cxGrdDBTabPrin.DataController.Filter.Clear;
  Buscar;
end;

procedure TfrmMtoBusquedaDatos.cbbCampoPropertiesChange(Sender: TObject);
begin
  ActualizarInterfazCampo;
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
    lblValor.Caption := 'Color objetivo';
    edtValor.Properties.Nullstring :=
      'Código, nombre, HEX o botón para elegir color';
  end
  else if cbbCampo.ItemIndex = CAMPO_COLOR_BASICO then
  begin
    lblValor.Caption := 'Color básico';
    edtValor.Properties.Nullstring :=
      'Código, nombre o HEX del color básico';
  end
  else
  begin
    lblValor.Caption := 'Texto a buscar';
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
    qryPaleta.Connection := inLibGlobalVar.oConn;
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
    if SeleccionarAvConPaleta('CO', aColores, edtValor.Text, sColor,
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
  bConsultaPreparada: Boolean;
begin
  sw := TStopwatch.StartNew;
  Screen.Cursor := crHourGlass;
  try
    bConsultaPreparada := PrepararConsulta;
    if bConsultaPreparada then
    begin
      unqryResultados.Open;
      if not FColumnasCreadas then
      begin
        ProcesarPerfiles;
        FColumnasCreadas := True;
      end;
      ActualizarColumnasColor;
      ActualizarContador;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  if bConsultaPreparada then
  begin
    inLibLog.Log.LogPerf('BusquedaDatos.Buscar',
      Format('campo=%d filas=%d',
             [cbbCampo.ItemIndex, unqryResultados.RecordCount]),
      sw.ElapsedMilliseconds);
  end;
end;

function TfrmMtoBusquedaDatos.PrepararConsulta: Boolean;
var
  sCampo: string;
  sValor: string;
  sParametro: string;
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
  bProximidad := cbbCampo.ItemIndex = CAMPO_PROXIMIDAD_COLOR;
  if bProximidad then
  begin
    Result := ResolverColorObjetivo(sValor, sHexObjetivo, iRojo,
                                    iVerde, iAzul);
    if not Result then
    begin
      MessageDlg('Indique un color de paleta válido por código, nombre ' +
        'o HEX (#RRGGBB).', mtWarning, [mbOK], 0);
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
      qryColor.Connection := inLibGlobalVar.oConn;
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
  ConfigurarColumna('ATR_CO', 'Color', 125, True);
  ConfigurarColumna('CODIGO_COLOR_BASICO', 'Código básico', 110, False);
  ConfigurarColumna('COLOR_BASICO', 'Color básico', 155, True);
  ConfigurarColumna('HEX_COLOR_BASICO', 'HEX', 85, True);
  ConfigurarColumna('DISTANCIA_COLOR', 'Distancia RGB', 95, False);
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
