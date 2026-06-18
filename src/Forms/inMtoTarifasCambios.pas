{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifasCambios                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sesiones de cambios de tarifa: carga, calculo, revision y aplicacion.     }
{******************************************************************************}
unit inMtoTarifasCambios;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  cxNavigator, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxContainer, cxTextEdit, cxDBEdit, cxLabel, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxCurrencyEdit, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxCheckBox, cxPC,
  dxSkinsCore, dxSkinBlue, dxSkinsDefaultPainters, dxSkinscxPCPainter,
  dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataTarifasCambios, inMtoGen;

type
  TfrmMtoTarifasCambios = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados : Boolean;
    pnlCabecera       : TPanel;
    pnlParametros     : TPanel;
    pnlAcciones       : TPanel;
    pcDetalle         : TcxPageControl;
    tsLineas          : TcxTabSheet;
    cxgrdLineas       : TcxGrid;
    tvLineas          : TcxGridDBTableView;
    glLineas          : TcxGridLevel;
    txtNombre         : TcxDBTextEdit;
    dteFecha          : TcxDBDateEdit;
    txtEstado         : TcxDBTextEdit;
    cbbTarifaOrigen   : TcxDBLookupComboBox;
    cbbTarifaDestino  : TcxDBLookupComboBox;
    cbbCampoOrigen    : TcxDBComboBox;
    cbbCampoDestino   : TcxDBComboBox;
    cbbTipoAplicacion : TcxDBComboBox;
    curValor          : TcxDBCurrencyEdit;
    curRedondeo       : TcxDBCurrencyEdit;
    curMenos          : TcxDBCurrencyEdit;
    chkRedondear      : TcxDBCheckBox;
    dteDesde          : TcxDBDateEdit;
    dteHasta          : TcxDBDateEdit;
    btnCargar         : TcxButton;
    btnCalcular       : TcxButton;
    btnAplicar        : TcxButton;
    btnRefrescar      : TcxButton;
    procedure CrearControlesDinamicos;
    procedure CrearCabecera;
    procedure CrearParametros;
    procedure CrearAcciones;
    procedure CrearGridLineas;
    procedure CrearColumnasCabecera;
    procedure CrearColumnasLineas;
    procedure CrearEtiqueta(AParent: TWinControl;
                            const ATexto: string;
                            AIzq, ATop: Integer);
    function  CrearColumna(AView: TcxGridDBTableView;
                           const ACampo, ATitulo: string;
                           AAncho: Integer): TcxGridDBColumn;
    procedure ConfigurarCombos;
    procedure VincularDatos;
    function  GrabarCabeceraSiNecesario: Boolean;
    procedure btnCargarClick(Sender: TObject);
    procedure btnCalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
  public
    dmmTarifasCambios: TdmTarifasCambios;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoTarifasCambios: TfrmMtoTarifasCambios;

implementation

uses
  inMtoModalCargarSesionTarifa;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoTarifasCambios.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
end;

procedure TfrmMtoTarifasCambios.CrearControlesDinamicos;
begin
  if not FControlesCreados then
  begin
    CrearCabecera;
    CrearParametros;
    CrearAcciones;
    CrearGridLineas;
    ConfigurarCombos;
    FControlesCreados := True;
  end;
end;

procedure TfrmMtoTarifasCambios.CrearCabecera;
begin
  pnlCabecera := TPanel.Create(Self);
  pnlCabecera.Parent := tsFicha;
  pnlCabecera.Align := alTop;
  pnlCabecera.Height := 92;
  pnlCabecera.BevelOuter := bvNone;
  pnlCabecera.ParentBackground := False;
  pnlCabecera.Color := clWhite;
  CrearEtiqueta(pnlCabecera, 'Nombre', 12, 12);
  txtNombre := TcxDBTextEdit.Create(Self);
  txtNombre.Parent := pnlCabecera;
  txtNombre.Left := 80;
  txtNombre.Top := 8;
  txtNombre.Width := 330;
  CrearEtiqueta(pnlCabecera, 'Fecha', 430, 12);
  dteFecha := TcxDBDateEdit.Create(Self);
  dteFecha.Parent := pnlCabecera;
  dteFecha.Left := 486;
  dteFecha.Top := 8;
  dteFecha.Width := 120;
  CrearEtiqueta(pnlCabecera, 'Estado', 625, 12);
  txtEstado := TcxDBTextEdit.Create(Self);
  txtEstado.Parent := pnlCabecera;
  txtEstado.Left := 688;
  txtEstado.Top := 8;
  txtEstado.Width := 120;
  CrearEtiqueta(pnlCabecera, 'Tarifa origen', 12, 50);
  cbbTarifaOrigen := TcxDBLookupComboBox.Create(Self);
  cbbTarifaOrigen.Parent := pnlCabecera;
  cbbTarifaOrigen.Left := 110;
  cbbTarifaOrigen.Top := 46;
  cbbTarifaOrigen.Width := 220;
  CrearEtiqueta(pnlCabecera, 'Tarifa destino', 350, 50);
  cbbTarifaDestino := TcxDBLookupComboBox.Create(Self);
  cbbTarifaDestino.Parent := pnlCabecera;
  cbbTarifaDestino.Left := 456;
  cbbTarifaDestino.Top := 46;
  cbbTarifaDestino.Width := 220;
  CrearEtiqueta(pnlCabecera, 'Desde', 696, 50);
  dteDesde := TcxDBDateEdit.Create(Self);
  dteDesde.Parent := pnlCabecera;
  dteDesde.Left := 748;
  dteDesde.Top := 46;
  dteDesde.Width := 110;
  CrearEtiqueta(pnlCabecera, 'Hasta', 876, 50);
  dteHasta := TcxDBDateEdit.Create(Self);
  dteHasta.Parent := pnlCabecera;
  dteHasta.Left := 928;
  dteHasta.Top := 46;
  dteHasta.Width := 110;
end;

procedure TfrmMtoTarifasCambios.CrearParametros;
begin
  pnlParametros := TPanel.Create(Self);
  pnlParametros.Parent := tsFicha;
  pnlParametros.Align := alTop;
  pnlParametros.Height := 86;
  pnlParametros.BevelOuter := bvNone;
  pnlParametros.ParentBackground := False;
  pnlParametros.Color := clWhite;
  CrearEtiqueta(pnlParametros, 'Origen', 12, 10);
  cbbCampoOrigen := TcxDBComboBox.Create(Self);
  cbbCampoOrigen.Parent := pnlParametros;
  cbbCampoOrigen.Left := 80;
  cbbCampoOrigen.Top := 6;
  cbbCampoOrigen.Width := 170;
  CrearEtiqueta(pnlParametros, 'Destino', 268, 10);
  cbbCampoDestino := TcxDBComboBox.Create(Self);
  cbbCampoDestino.Parent := pnlParametros;
  cbbCampoDestino.Left := 338;
  cbbCampoDestino.Top := 6;
  cbbCampoDestino.Width := 145;
  CrearEtiqueta(pnlParametros, 'Aplicar', 502, 10);
  cbbTipoAplicacion := TcxDBComboBox.Create(Self);
  cbbTipoAplicacion.Parent := pnlParametros;
  cbbTipoAplicacion.Left := 572;
  cbbTipoAplicacion.Top := 6;
  cbbTipoAplicacion.Width := 180;
  CrearEtiqueta(pnlParametros, 'Valor', 770, 10);
  curValor := TcxDBCurrencyEdit.Create(Self);
  curValor.Parent := pnlParametros;
  curValor.Left := 820;
  curValor.Top := 6;
  curValor.Width := 90;
  CrearEtiqueta(pnlParametros, 'Redondeo', 12, 48);
  curRedondeo := TcxDBCurrencyEdit.Create(Self);
  curRedondeo.Parent := pnlParametros;
  curRedondeo.Left := 96;
  curRedondeo.Top := 44;
  curRedondeo.Width := 90;
  CrearEtiqueta(pnlParametros, 'Menos', 208, 48);
  curMenos := TcxDBCurrencyEdit.Create(Self);
  curMenos.Parent := pnlParametros;
  curMenos.Left := 264;
  curMenos.Top := 44;
  curMenos.Width := 90;
  chkRedondear := TcxDBCheckBox.Create(Self);
  chkRedondear.Parent := pnlParametros;
  chkRedondear.Left := 378;
  chkRedondear.Top := 43;
  chkRedondear.Width := 165;
  chkRedondear.Caption := 'Redondear hacia arriba';
  chkRedondear.Properties.ValueChecked := 'S';
  chkRedondear.Properties.ValueUnchecked := 'N';
end;

procedure TfrmMtoTarifasCambios.CrearAcciones;
begin
  pnlAcciones := TPanel.Create(Self);
  pnlAcciones.Parent := tsFicha;
  pnlAcciones.Align := alTop;
  pnlAcciones.Height := 44;
  pnlAcciones.BevelOuter := bvNone;
  pnlAcciones.ParentBackground := False;
  pnlAcciones.Color := clWhite;
  btnCargar := TcxButton.Create(Self);
  btnCargar.Parent := pnlAcciones;
  btnCargar.Left := 12;
  btnCargar.Top := 6;
  btnCargar.Width := 130;
  btnCargar.Caption := 'Cargar articulos';
  btnCargar.OnClick := btnCargarClick;
  btnCalcular := TcxButton.Create(Self);
  btnCalcular.Parent := pnlAcciones;
  btnCalcular.Left := 154;
  btnCalcular.Top := 6;
  btnCalcular.Width := 120;
  btnCalcular.Caption := 'Calcular lineas';
  btnCalcular.OnClick := btnCalcularClick;
  btnAplicar := TcxButton.Create(Self);
  btnAplicar.Parent := pnlAcciones;
  btnAplicar.Left := 286;
  btnAplicar.Top := 6;
  btnAplicar.Width := 116;
  btnAplicar.Caption := 'Aplicar tarifa';
  btnAplicar.OnClick := btnAplicarClick;
  btnRefrescar := TcxButton.Create(Self);
  btnRefrescar.Parent := pnlAcciones;
  btnRefrescar.Left := 414;
  btnRefrescar.Top := 6;
  btnRefrescar.Width := 92;
  btnRefrescar.Caption := 'Refrescar';
  btnRefrescar.OnClick := btnRefrescarClick;
end;

procedure TfrmMtoTarifasCambios.CrearGridLineas;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := tsFicha;
  pcDetalle.Align := alClient;
  tsLineas := TcxTabSheet.Create(Self);
  tsLineas.PageControl := pcDetalle;
  tsLineas.Caption := 'Lineas';
  cxgrdLineas := TcxGrid.Create(Self);
  cxgrdLineas.Parent := tsLineas;
  cxgrdLineas.Align := alClient;
  tvLineas := TcxGridDBTableView.Create(Self);
  glLineas := cxgrdLineas.Levels.Add;
  glLineas.GridView := tvLineas;
  tvLineas.OptionsData.Deleting := False;
  tvLineas.OptionsView.GroupByBox := False;
end;

procedure TfrmMtoTarifasCambios.ConfigurarCombos;
begin
  cbbCampoOrigen.Properties.DropDownListStyle := lsFixedList;
  cbbCampoOrigen.Properties.Items.Add('PRECIO_ORIGEN');
  cbbCampoOrigen.Properties.Items.Add('PRECIO_COSTE');
  cbbCampoOrigen.Properties.Items.Add('PRECIO_DESTINO_ACTUAL');
  cbbCampoDestino.Properties.DropDownListStyle := lsFixedList;
  cbbCampoDestino.Properties.Items.Add('AMBOS');
  cbbCampoDestino.Properties.Items.Add('PRECIO_SALIDA');
  cbbCampoDestino.Properties.Items.Add('PRECIO_FINAL');
  cbbTipoAplicacion.Properties.DropDownListStyle := lsFixedList;
  cbbTipoAplicacion.Properties.Items.Add('COPIAR');
  cbbTipoAplicacion.Properties.Items.Add('INCREMENTO_LINEAL');
  cbbTipoAplicacion.Properties.Items.Add('INCREMENTO_PORCENTUAL');
  cbbTipoAplicacion.Properties.Items.Add('PRECIO_FIJO');
  cbbTarifaOrigen.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaOrigen.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
  cbbTarifaDestino.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaDestino.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
end;

procedure TfrmMtoTarifasCambios.VincularDatos;
begin
  txtNombre.DataBinding.DataSource := dsTablaG;
  txtNombre.DataBinding.DataField := 'NOMBRE_TARC';
  dteFecha.DataBinding.DataSource := dsTablaG;
  dteFecha.DataBinding.DataField := 'FECHA_TARC';
  txtEstado.DataBinding.DataSource := dsTablaG;
  txtEstado.DataBinding.DataField := 'ESTADO_TARC';
  cbbTarifaOrigen.DataBinding.DataSource := dsTablaG;
  cbbTarifaOrigen.DataBinding.DataField := 'CODIGO_TAR_ORIGEN_TARC';
  cbbTarifaDestino.DataBinding.DataSource := dsTablaG;
  cbbTarifaDestino.DataBinding.DataField := 'CODIGO_TAR_DESTINO_TARC';
  cbbCampoOrigen.DataBinding.DataSource := dsTablaG;
  cbbCampoOrigen.DataBinding.DataField := 'CAMPO_ORIGEN_TARC';
  cbbCampoDestino.DataBinding.DataSource := dsTablaG;
  cbbCampoDestino.DataBinding.DataField := 'CAMPO_DESTINO_TARC';
  cbbTipoAplicacion.DataBinding.DataSource := dsTablaG;
  cbbTipoAplicacion.DataBinding.DataField := 'TIPO_APLICACION_TARC';
  curValor.DataBinding.DataSource := dsTablaG;
  curValor.DataBinding.DataField := 'VALOR_APLICACION_TARC';
  curRedondeo.DataBinding.DataSource := dsTablaG;
  curRedondeo.DataBinding.DataField := 'VALOR_REDONDEO_TARC';
  curMenos.DataBinding.DataSource := dsTablaG;
  curMenos.DataBinding.DataField := 'VALOR_MENOS_AJUSTE_TARC';
  chkRedondear.DataBinding.DataSource := dsTablaG;
  chkRedondear.DataBinding.DataField := 'ESREDONDEAR_ARRIBA_TARC';
  dteDesde.DataBinding.DataSource := dsTablaG;
  dteDesde.DataBinding.DataField := 'FECHA_DESDE_TARC';
  dteHasta.DataBinding.DataSource := dsTablaG;
  dteHasta.DataBinding.DataField := 'FECHA_HASTA_TARC';
end;

procedure TfrmMtoTarifasCambios.CrearTablaPrincipal;
begin
  inherited;
  dmmTarifasCambios := tdmDataModule as TdmTarifasCambios;
  tvLineas.DataController.DataSource := dmmTarifasCambios.dsLineas;
  cbbTarifaOrigen.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  cbbTarifaDestino.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  pkFieldName := 'CODIGO_TARC';
  VincularDatos;
  CrearColumnasCabecera;
  CrearColumnasLineas;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasCabecera;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TARC', 'Codigo', 70);
    CrearColumna(cxGrdDBTabPrin, 'NOMBRE_TARC', 'Nombre', 220);
    CrearColumna(cxGrdDBTabPrin, 'FECHA_TARC', 'Fecha', 90);
    CrearColumna(cxGrdDBTabPrin, 'ESTADO_TARC', 'Estado', 100);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_ORIGEN_TARC',
                 'Tarifa origen', 120);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_DESTINO_TARC',
                 'Tarifa destino', 120);
    CrearColumna(cxGrdDBTabPrin, 'TIPO_APLICACION_TARC', 'Aplicacion', 150);
    CrearColumna(cxGrdDBTabPrin, 'VALOR_APLICACION_TARC', 'Valor', 90);
  end;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasLineas;
begin
  if tvLineas.ColumnCount = 0 then
  begin
    CrearColumna(tvLineas, 'ESAPLICAR_TARCLIN', 'Aplicar', 65);
    CrearColumna(tvLineas, 'ESTADO_TARCLIN', 'Estado', 90);
    CrearColumna(tvLineas, 'CODIGO_ART_TARCLIN', 'Articulo', 110);
    CrearColumna(tvLineas, 'DESCRIPCION_ART', 'Descripcion', 240);
    CrearColumna(tvLineas, 'NOMBRE_FAM_FAM', 'Familia', 160);
    CrearColumna(tvLineas, 'RAZON_SOCIAL_PRV', 'Proveedor', 180);
    CrearColumna(tvLineas, 'PRECIO_ORIGEN_TARCLIN', 'P. origen', 90);
    CrearColumna(tvLineas, 'PRECIO_COSTE_TARCLIN', 'Coste', 90);
    CrearColumna(tvLineas, 'PRECIO_SALIDA_ACTUAL_TARCLIN',
                 'Salida actual', 100);
    CrearColumna(tvLineas, 'PRECIO_FINAL_ACTUAL_TARCLIN',
                 'Final actual', 100);
    CrearColumna(tvLineas, 'PRECIO_NUEVO_TARCLIN', 'Salida nueva', 100);
    CrearColumna(tvLineas, 'PRECIO_FINAL_NUEVO_TARCLIN',
                 'Final nuevo', 100);
    CrearColumna(tvLineas, 'PRECIO_DTO_NUEVO_TARCLIN', 'Dto nuevo', 90);
    CrearColumna(tvLineas, 'PORCENTAJE_DTO_NUEVO_TARCLIN',
                 '% dto nuevo', 90);
    CrearColumna(tvLineas, 'MENSAJE_TARCLIN', 'Mensaje', 180);
  end;
end;

procedure TfrmMtoTarifasCambios.CrearEtiqueta(AParent: TWinControl;
  const ATexto: string; AIzq, ATop: Integer);
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent := AParent;
  lbl.Left := AIzq;
  lbl.Top := ATop;
  lbl.Caption := ATexto;
  lbl.Transparent := True;
end;

function TfrmMtoTarifasCambios.CrearColumna(AView: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AView.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := AAncho;
end;

function TfrmMtoTarifasCambios.GrabarCabeceraSiNecesario: Boolean;
begin
  Result := True;
  if Assigned(dsTablaG.DataSet) and
     (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
    dsTablaG.DataSet.Post;
  if (not Assigned(dsTablaG.DataSet)) or dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage('Selecciona o crea primero una sesion.');
    Result := False;
  end;
end;

procedure TfrmMtoTarifasCambios.btnCargarClick(Sender: TObject);
var
  res: TCargarSesionTarifaResult;
begin
  if GrabarCabeceraSiNecesario then
  begin
    res := TfrmModalCargarSesionTarifa.Ejecutar(
      Self,
      dmmTarifasCambios.unqryTablaG.Connection,
      dsTablaG.DataSet.FieldByName('CODIGO_TARC').AsInteger,
      dsTablaG.DataSet.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString,
      dsTablaG.DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString);
    if res.Aceptado then
      dmmTarifasCambios.unqryLineas.Refresh;
  end;
end;

procedure TfrmMtoTarifasCambios.btnCalcularClick(Sender: TObject);
var
  sMensaje : string;
  iLineas  : Integer;
begin
  if GrabarCabeceraSiNecesario then
  begin
    iLineas := dmmTarifasCambios.RecalcularSesionActual(sMensaje);
    if sMensaje <> '' then
      ShowMessage(sMensaje)
    else
      ShowMessage(Format('%d lineas recalculadas.', [iLineas]));
  end;
end;

procedure TfrmMtoTarifasCambios.btnAplicarClick(Sender: TObject);
var
  sMensaje : string;
  iLineas  : Integer;
begin
  if GrabarCabeceraSiNecesario then
  begin
    if MessageDlg('Aplicar las lineas marcadas a la tarifa destino?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      iLineas := dmmTarifasCambios.AplicarSesionActual(sMensaje);
      if sMensaje <> '' then
        ShowMessage('No se pudo aplicar la sesion: ' + sMensaje)
      else
        ShowMessage(Format('%d lineas aplicadas.', [iLineas]));
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.btnRefrescarClick(Sender: TObject);
begin
  if Assigned(dmmTarifasCambios) then
  begin
    dmmTarifasCambios.unqryTablaG.Refresh;
    dmmTarifasCambios.unqryLineas.Refresh;
  end;
end;

procedure TfrmMtoTarifasCambios.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsFicha;
end;

initialization
  ForceReferenceToClass(TfrmMtoTarifasCambios);
end.
