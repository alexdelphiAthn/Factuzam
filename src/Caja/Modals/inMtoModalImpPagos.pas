{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpPagos                                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del histórico de pagos de caja (FastReport).           }
{    Informe A4 horizontal con los pagos del TPV, filtrados por empresa /      }
{    almacén / caja, rango de fechas y forma(s) de pago. El usuario puede      }
{    retocar el formato con el diseñador (botón Editar) y guardarlo.           }
{                                                                              }
{    Es autocontenido: la consulta, el datasource y el TfrxDBDataset viven     }
{    en este propio formulario, sin depender de un data module externo. Lee    }
{    de la vista vi_caja_pagos (DESARROLLOS EN CURSO/vista_caja_pagos.sql).     }
{******************************************************************************}
unit inMtoModalImpPagos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxButtonEdit,
  cxDateUtils, cxCheckListBox, cxCheckBox,
  Vcl.ComCtrls, dxCore, cxStyles, dxSkinsForm, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, inLibGlobalVar;

type
  TfrmPrintPagos = class(TfrmPrint)
    unqryPagosPrint: TUniQuery;
    dsPagosPrint: TDataSource;
    fxdsPagos: TfrxDBDataset;
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblCajaTit: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    bedAlmacen: TcxButtonEdit;
    lblCaja: TcxLabel;
    bedCaja: TcxButtonEdit;
    lblFormasPago: TcxLabel;
    clbFormasPago: TcxCheckListBox;
    procedure bedAlmacenPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure bedCajaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure dtFechasPropertiesEditValueChanged(Sender: TObject);
  private
    // Fija los valores por defecto una sola vez al abrir; evita pisarlos en el
    // ciclo Hide/Show que hacen los botones del padre (Imprimir / PDF / etc.).
    FInicializado: Boolean;
    // Codigo de forma de pago de cada item de clbFormasPago, en el mismo
    // orden (el item solo guarda el texto "COD - Descripcion").
    FCodigosFP: TStringList;
    // Abre el selector estandar de caja (inMtoModalCajDef) acotado a la
    // empresa del usuario y vuelca el almacen y la caja en bedAlmacen/bedCaja.
    procedure SeleccionarAlmacenCaja;
    // Rellena el listbox con las formas de pago presentes en los pagos del
    // periodo / caja actuales (todas marcadas por defecto).
    procedure CargarFormasPago;
  protected
    procedure DoShow; override;
  public
    destructor Destroy; override;
    procedure preparar_consulta; override;
  end;

var
  frmPrintPagos: TfrmPrintPagos;

implementation

{$R *.dfm}

uses
  inMtoModalCajDef;

{ TfrmPrintPagos }

destructor TfrmPrintPagos.Destroy;
begin
  FreeAndNil(FCodigosFP);
  inherited;
end;

procedure TfrmPrintPagos.DoShow;
begin
  inherited;
  // Por defecto: rango del primer dia del mes en curso hasta hoy, y la
  // empresa / almacen / caja activos del usuario. El usuario puede ampliar
  // las fechas y cambiar almacen / caja con el boton '...' antes de imprimir.
  if not FInicializado then
  begin
    dteDesde.Date   := EncodeDate(YearOf(Date), MonthOf(Date), 1);
    dteHasta.Date   := Date;
    edtEmpresa.Text := oEmpresa;
    bedAlmacen.Text := oAlmacen;
    bedCaja.Text    := oCaja;
    FInicializado   := True;
    CargarFormasPago;
  end;
end;

procedure TfrmPrintPagos.CargarFormasPago;
var
  qry: TUniQuery;
  item: TcxCheckListBoxItem;
begin
  // Listamos las formas de pago distintas que aparecen en los pagos del
  // periodo / caja seleccionados, con su descripcion. Todas marcadas: por
  // defecto no se filtra por forma de pago.
  if FCodigosFP = nil then
    FCodigosFP := TStringList.Create;
  clbFormasPago.Items.BeginUpdate;
  try
    clbFormasPago.Items.Clear;
    FCodigosFP.Clear;
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text :=
        ' SELECT DISTINCT p.CODIGO_FP_CFP AS COD,                         ' +
        '        COALESCE(fp.DESCRIPCION_FORMA_PAGO_FP, p.CODIGO_FP_CFP)  ' +
        '          AS DESCR                                               ' +
        '   FROM vi_caja_pagos p                                          ' +
        '   LEFT JOIN fza_formas_pago fp                                  ' +
        '          ON fp.CODIGO_FP_FP = p.CODIGO_FP_CFP                   ' +
        '  WHERE p.CODIGO_EMP_PAGO  = :pEMP                               ' +
        '    AND p.CODIGO_ALM_PAGO  = :pALM                               ' +
        '    AND p.CODIGO_CAJA_PAGO = :pCAJA                              ' +
        '    AND DATE(p.FECHA_PAGO) BETWEEN :pDESDE AND :pHASTA           ' +
        '  ORDER BY COD                                                   ';
      qry.ParamByName('pEMP').AsString     := edtEmpresa.Text;
      qry.ParamByName('pALM').AsString     := bedAlmacen.Text;
      qry.ParamByName('pCAJA').AsString    := bedCaja.Text;
      qry.ParamByName('pDESDE').AsDateTime := dteDesde.Date;
      qry.ParamByName('pHASTA').AsDateTime := dteHasta.Date;
      qry.Open;
      while not qry.Eof do
      begin
        item := clbFormasPago.Items.Add;
        item.Text := qry.FieldByName('COD').AsString + ' - ' +
                     qry.FieldByName('DESCR').AsString;
        item.Checked := True;
        FCodigosFP.Add(qry.FieldByName('COD').AsString);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
  finally
    clbFormasPago.Items.EndUpdate;
  end;
end;

procedure TfrmPrintPagos.SeleccionarAlmacenCaja;
var
  frm: TfrmMtoModalCajDef;
  bCambio: Boolean;
begin
  // No se permite cambiar de empresa: acotamos el selector a la empresa
  // del usuario. De la fila elegida tomamos almacen y caja.
  bCambio := False;
  frm := TfrmMtoModalCajDef.Create(Self);
  try
    frm.qrySeleccion.Connection := oConn;
    frm.qrySeleccion.SQL.Text :=
      ' SELECT * FROM vi_cajasdef WHERE Empresa = :pEMP ' +
      ' ORDER BY Almacen, Caja ';
    frm.qrySeleccion.ParamByName('pEMP').AsString := edtEmpresa.Text;
    frm.qrySeleccion.Open;
    // Cierra el cronometro SQL antes de entrar en el selector modal.
    CerrarMonitorSQLPendiente;
    frm.sEmpresa := edtEmpresa.Text;
    frm.sAlmacen := bedAlmacen.Text;
    frm.sCaja    := bedCaja.Text;
    // Este modal es fsStayOnTop (heredado de TfrmPrint); si no nos
    // ocultamos, el selector saldria por detras. Mismo patron que usa el
    // padre al abrir el selector de formatos (Self.Hide / Self.Show).
    Self.Hide;
    try
      frm.ShowModal;
      if frm.sFicha = 'S' then
      begin
        bedAlmacen.Text := frm.qrySeleccion.FieldByName('Almacen').AsString;
        bedCaja.Text    := frm.qrySeleccion.FieldByName('Caja').AsString;
        bCambio         := True;
      end;
    finally
      Self.Show;
    end;
  finally
    FreeAndNil(frm);
  end;
  // Si cambio la caja, refrescamos las formas de pago de ese contexto.
  if bCambio and FInicializado then
    CargarFormasPago;
end;

procedure TfrmPrintPagos.bedAlmacenPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintPagos.bedCajaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  SeleccionarAlmacenCaja;
end;

procedure TfrmPrintPagos.dtFechasPropertiesEditValueChanged(Sender: TObject);
begin
  // Al cambiar el rango refrescamos las formas de pago del periodo. El guard
  // evita ejecutarlo mientras DoShow fija los valores por defecto (cuando
  // aun no estan puestos empresa / almacen / caja).
  if FInicializado then
    CargarFormasPago;
end;

procedure TfrmPrintPagos.preparar_consulta;
var
  i, nMarcadas: Integer;
  sInFP: string;
begin
  inherited;
  // Forma(s) de pago marcadas en el listbox. Solo se filtra cuando la
  // seleccion es parcial: si estan todas (o ninguna) marcadas no se filtra,
  // de modo que el listado no sale vacio por descuido.
  sInFP := '';
  nMarcadas := 0;
  for i := 0 to clbFormasPago.Items.Count - 1 do
  begin
    if clbFormasPago.Items[i].Checked then
    begin
      Inc(nMarcadas);
      if sInFP <> '' then
        sInFP := sInFP + ',';
      sInFP := sInFP + QuotedStr(FCodigosFP[i]);
    end;
  end;
  // fza_caja_pagos no tiene fecha propia: leemos de vi_caja_pagos, que expone
  // FECHA_PAGO (de la operacion asociada) y NUMERO_FAC_PAGO / SERIE_FAC_PAGO.
  // El rango se aplica sobre DATE(FECHA_PAGO) para ser inclusivo por dia.
  with unqryPagosPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      ' SELECT *                                                          ' +
      '   FROM vi_caja_pagos                                              ' +
      '  WHERE CODIGO_EMP_PAGO  = :pEMP                                   ' +
      '    AND CODIGO_ALM_PAGO  = :pALM                                   ' +
      '    AND CODIGO_CAJA_PAGO = :pCAJA                                  ' +
      '    AND DATE(FECHA_PAGO) BETWEEN :pDESDE AND :pHASTA               ';
    if (nMarcadas > 0) and (nMarcadas < clbFormasPago.Items.Count) then
      SQL.Text := SQL.Text +
        '    AND CODIGO_FP_CFP IN (' + sInFP + ')                         ';
    SQL.Text := SQL.Text +
      '  ORDER BY FECHA_PAGO, NUMERO_OPERACION_PAGO, NUMERO_LINEA_PAGO    ';
    ParamByName('pEMP').AsString     := edtEmpresa.Text;
    ParamByName('pALM').AsString     := bedAlmacen.Text;
    ParamByName('pCAJA').AsString    := bedCaja.Text;
    ParamByName('pDESDE').AsDateTime := dteDesde.Date;
    ParamByName('pHASTA').AsDateTime := dteHasta.Date;
    Open;
  end;
  fxdsPagos.UpdateBounds;
end;

end.
