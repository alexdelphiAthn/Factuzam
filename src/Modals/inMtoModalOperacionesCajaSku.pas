{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalOperacionesCajaSku                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resumen de ventas, devoluciones y préstamos de un SKU desde la consulta   }
{    de stock. Muestra las operaciones VE, DV y DE vinculadas al artículo.     }
{******************************************************************************}
unit inMtoModalOperacionesCajaSku;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxButtons, cxCurrencyEdit, cxCalendar,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData,
  cxGridLevel, cxClasses, cxStyles, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  dxDateRanges, dxScrollbarAnnotations,
  Uni,
  inMtoFrmBase;

type
  TfrmModalOperacionesCajaSku = class(TfrmBase)
    pnlSuperior: TPanel;
    lblTitulo: TcxLabel;
    lblAyuda: TcxLabel;
    cxgrdOperaciones: TcxGrid;
    tvOperaciones: TcxGridDBTableView;
    cxgrdlvlOperaciones: TcxGridLevel;
    tvOperacionesTIPO_OPERACION: TcxGridDBColumn;
    tvOperacionesNUMERO_OPERACION: TcxGridDBColumn;
    tvOperacionesFECHA_OPERACION: TcxGridDBColumn;
    tvOperacionesFACTURA: TcxGridDBColumn;
    tvOperacionesDESCRIPCION_ARTICULO: TcxGridDBColumn;
    tvOperacionesPRECIO_VENTA: TcxGridDBColumn;
    tvOperacionesDESCUENTO: TcxGridDBColumn;
    dsOperaciones: TDataSource;
    pnlBotones: TPanel;
    lblResultado: TcxLabel;
    btnIrOperacion: TcxButton;
    btnIrFacturaSimplificada: TcxButton;
    btnCerrar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dsOperacionesDataChange(Sender: TObject; Field: TField);
    procedure btnIrOperacionClick(Sender: TObject);
    procedure btnIrFacturaSimplificadaClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConn: TUniConnection;
    FCodigoSku: string;
    FDescripcionArticulo: string;
    FQry: TUniQuery;
    FCallNavegacion: string;
    FBusquedaNavegacion: string;
    procedure ActualizarAcciones;
    procedure ActualizarCabecera;
    procedure CargarOperaciones;
    function FacturaSeleccionada(
      out ASerie, ANumero: string): Boolean;
    function OperacionSeleccionada(
      out AEmpresa, AAlmacen, ACaja, ANumero: string): Boolean;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ACodigoSku, ADescripcionArticulo: string);
  end;

implementation

uses
  inLibShowMto, inLibMsg;

{$R *.dfm}

class procedure TfrmModalOperacionesCajaSku.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ACodigoSku, ADescripcionArticulo: string);
var
  frm: TfrmModalOperacionesCajaSku;
begin
  frm := TfrmModalOperacionesCajaSku.Create(AOwner);
  try
    frm.FConn := AConn;
    frm.FCodigoSku := ACodigoSku;
    frm.FDescripcionArticulo := ADescripcionArticulo;
    frm.ShowModal;
    if frm.FCallNavegacion <> '' then
    begin
      if AOwner is TCustomForm then
      begin
        TCustomForm(AOwner).Hide;
      end;
      if Application.MainForm <> nil then
      begin
        ShowMto(
          Application.MainForm,
          frm.FCallNavegacion,
          frm.FBusquedaNavegacion);
      end;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalOperacionesCajaSku.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Self.KeyPreview := True;
  FQry := TUniQuery.Create(Self);
  dsOperaciones.DataSet := FQry;
  FCallNavegacion := '';
  FBusquedaNavegacion := '';
end;

procedure TfrmModalOperacionesCajaSku.FormShow(Sender: TObject);
begin
  ActualizarCabecera;
  CargarOperaciones;
  ActualizarAcciones;
  if (not FQry.IsEmpty) and cxgrdOperaciones.CanFocus then
    cxgrdOperaciones.SetFocus;
end;

procedure TfrmModalOperacionesCajaSku.ActualizarAcciones;
var
  sEmpresa  : string;
  sAlmacen  : string;
  sCaja     : string;
  sOperacion: string;
  sSerie    : string;
  sFactura  : string;
begin
  btnIrOperacion.Enabled := OperacionSeleccionada(
    sEmpresa, sAlmacen, sCaja, sOperacion);
  btnIrFacturaSimplificada.Enabled := FacturaSeleccionada(
    sSerie, sFactura);
end;

procedure TfrmModalOperacionesCajaSku.ActualizarCabecera;
var
  sDescripcion: string;
begin
  sDescripcion := Trim(FDescripcionArticulo);
  if sDescripcion = '' then
    sDescripcion := FCodigoSku;
  lblTitulo.Caption := sDescripcion + ' · ' + FCodigoSku;
end;

procedure TfrmModalOperacionesCajaSku.CargarOperaciones;
var
  iOperaciones: Integer;
begin
  if (FConn = nil) or (not FConn.Connected) then
    raise Exception.Create(SErrorConexionOperacionesCajaSkuNoDisponible);
  FQry.Close;
  FQry.Connection := FConn;
  FQry.SQL.Text :=
    ' SELECT X.TIPO_OPERACION, X.NUMERO_OPERACION, ' +
    '        X.FECHA_OPERACION, ' +
    '        CASE ' +
    '          WHEN TRIM(COALESCE(X.SERIE_FACTURA, '''')) = '''' ' +
    '            OR TRIM(COALESCE(X.NUMERO_FACTURA, '''')) IN ('''', ''0'') ' +
    '          THEN '''' ' +
    '          ELSE CONCAT(X.SERIE_FACTURA, ''/'', X.NUMERO_FACTURA) ' +
    '        END AS FACTURA, ' +
    '        X.DESCRIPCION_ARTICULO, X.PRECIO_VENTA, X.DESCUENTO, ' +
    '        X.CODIGO_EMP_OPCAJA, X.CODIGO_ALM_OPCAJA, ' +
    '        X.CODIGO_CAJA_OPCAJA, ' +
    '        X.SERIE_FACTURA, X.NUMERO_FACTURA ' +
    '   FROM ( ' +
    '     SELECT O.TIPO_OPERACION_OPCAJA AS TIPO_OPERACION, ' +
    '            O.NUMERO_OPERACION_OPCAJA AS NUMERO_OPERACION, ' +
    '            O.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION, ' +
    '            O.SERIE_FAC_OPCAJA AS SERIE_FACTURA, ' +
    '            O.NUMERO_FAC_OPCAJA AS NUMERO_FACTURA, ' +
    '            O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
    '            O.CODIGO_CAJA_OPCAJA, ' +
    '            COALESCE(NULLIF(L.DESCRIPCION_ARTICULO_FACLIN, ''''), ' +
    '                     A.DESCRIPCION_ART, '''') AS DESCRIPCION_ARTICULO, ' +
    '            L.PRECIO_VENTA_CIVA_ARTICULO_FACLIN AS PRECIO_VENTA, ' +
    '            NULLIF(L.PORCENTAJE_DTO_FACLIN, 0) AS DESCUENTO ' +
    '       FROM ( ' +
    '         SELECT CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '                CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    '                TIPO_OPERACION_OPCAJA, ' +
    '                MAX(FECHA_OPERACION_OPCAJA) AS FECHA_OPERACION_OPCAJA, ' +
    '                MAX(SERIE_FAC_OPCAJA) AS SERIE_FAC_OPCAJA, ' +
    '                MAX(NUMERO_FAC_OPCAJA) AS NUMERO_FAC_OPCAJA ' +
    '           FROM fza_caja_operaciones ' +
    '          WHERE TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'') ' +
    '          GROUP BY CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '                   CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    '                   TIPO_OPERACION_OPCAJA ' +
    '       ) O ' +
    '       JOIN fza_facturas_lineas L ' +
    '         ON ( ' +
    '              (L.CODIGO_EMP_FACLIN = O.CODIGO_EMP_OPCAJA ' +
    '               AND L.CODIGO_ALM_FACLIN = O.CODIGO_ALM_OPCAJA ' +
    '               AND L.CODIGO_CAJA_FACLIN = O.CODIGO_CAJA_OPCAJA ' +
    '               AND L.NUMERO_OPERACION_FACLIN = ' +
    '                   O.NUMERO_OPERACION_OPCAJA) ' +
    '              OR ' +
    '              (L.SERIE_FAC_FACLIN = O.SERIE_FAC_OPCAJA ' +
    '               AND L.NUMERO_FAC_FACLIN = O.NUMERO_FAC_OPCAJA) ' +
    '            ) ' +
    '       LEFT JOIN fza_articulos A ' +
    '         ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    '      WHERE L.CODIGO_UNIDAD_FACLIN = :SKU ' +
    '        AND ( ' +
    '              (O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    '               AND COALESCE(L.CANTIDAD_FACLIN, 0) > 0) ' +
    '              OR ' +
    '              (O.TIPO_OPERACION_OPCAJA = ''DV'' ' +
    '               AND COALESCE(L.CANTIDAD_FACLIN, 0) < 0) ' +
    '            ) ' +
    '     UNION ALL ' +
    '     SELECT O.TIPO_OPERACION_OPCAJA AS TIPO_OPERACION, ' +
    '            O.NUMERO_OPERACION_OPCAJA AS NUMERO_OPERACION, ' +
    '            O.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION, ' +
    '            O.SERIE_FAC_OPCAJA AS SERIE_FACTURA, ' +
    '            O.NUMERO_FAC_OPCAJA AS NUMERO_FACTURA, ' +
    '            O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
    '            O.CODIGO_CAJA_OPCAJA, ' +
    '            COALESCE(NULLIF(A.DESCRIPCION_ART, ''''), ' +
    '                     O.CONCEPTO_GASTO_INGRESO_OPCAJA, '''') ' +
    '              AS DESCRIPCION_ARTICULO, ' +
    '            D.PRECIO_VENTA_DEP AS PRECIO_VENTA, ' +
    '            CAST(NULL AS DECIMAL(19, 6)) AS DESCUENTO ' +
    '       FROM fza_caja_operaciones O ' +
    '       JOIN fza_depositos_cliente D ' +
    '         ON D.ID_DEPOSITO_DEP = O.ID_DEPOSITO_OPCAJA ' +
    '       LEFT JOIN fza_articulos A ' +
    '         ON A.CODIGO_ART_ART = D.CODIGO_ART_DEP ' +
    '      WHERE O.TIPO_OPERACION_OPCAJA = ''DE'' ' +
    '        AND D.CODIGO_UNIDAD_DEP = :SKU ' +
    '   ) X ' +
    '  ORDER BY X.FECHA_OPERACION DESC, ' +
    '           CAST(X.NUMERO_OPERACION AS UNSIGNED) DESC, ' +
    '           X.TIPO_OPERACION';
  FQry.ParamByName('SKU').AsString := FCodigoSku;
  FQry.Open;
  iOperaciones := 0;
  if not FQry.IsEmpty then
  begin
    FQry.Last;
    iOperaciones := FQry.RecordCount;
    FQry.First;
  end;
  if iOperaciones = 1 then
  begin
    lblResultado.Caption := '1 operación';
  end
  else
  begin
    lblResultado.Caption := Format('%d operaciones', [iOperaciones]);
  end;
end;

function TfrmModalOperacionesCajaSku.FacturaSeleccionada(
  out ASerie, ANumero: string): Boolean;
begin
  Result := False;
  ASerie := '';
  ANumero := '';
  if Assigned(FQry) and FQry.Active and
     (not FQry.IsEmpty) then
  begin
    ASerie := Trim(FQry.FieldByName('SERIE_FACTURA').AsString);
    ANumero := Trim(FQry.FieldByName('NUMERO_FACTURA').AsString);
    Result := (ASerie <> '') and
              (ANumero <> '') and
              (ANumero <> '0');
  end;
end;

function TfrmModalOperacionesCajaSku.OperacionSeleccionada(
  out AEmpresa, AAlmacen, ACaja, ANumero: string): Boolean;
begin
  Result := False;
  AEmpresa := '';
  AAlmacen := '';
  ACaja := '';
  ANumero := '';
  if Assigned(FQry) and FQry.Active and
     (not FQry.IsEmpty) then
  begin
    AEmpresa := Trim(FQry.FieldByName('CODIGO_EMP_OPCAJA').AsString);
    AAlmacen := Trim(FQry.FieldByName('CODIGO_ALM_OPCAJA').AsString);
    ACaja := Trim(FQry.FieldByName('CODIGO_CAJA_OPCAJA').AsString);
    ANumero := Trim(FQry.FieldByName('NUMERO_OPERACION').AsString);
    Result := (AEmpresa <> '') and
              (AAlmacen <> '') and
              (ACaja <> '') and
              (ANumero <> '');
  end;
end;

procedure TfrmModalOperacionesCajaSku.dsOperacionesDataChange(
  Sender: TObject; Field: TField);
begin
  ActualizarAcciones;
end;

procedure TfrmModalOperacionesCajaSku.btnIrOperacionClick(
  Sender: TObject);
var
  sEmpresa  : string;
  sAlmacen  : string;
  sCaja     : string;
  sOperacion: string;
begin
  if OperacionSeleccionada(
       sEmpresa, sAlmacen, sCaja, sOperacion) then
  begin
    FCallNavegacion := 'CajaOperacionesHist';
    FBusquedaNavegacion :=
      sEmpresa + ',' + sAlmacen + ',' + sCaja + ',' + sOperacion;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalOperacionesCajaSku.btnIrFacturaSimplificadaClick(
  Sender: TObject);
var
  sSerie  : string;
  sFactura: string;
begin
  if FacturaSeleccionada(sSerie, sFactura) then
  begin
    FCallNavegacion := 'FacturasSimplif';
    FBusquedaNavegacion := sFactura + ',' + sSerie;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalOperacionesCajaSku.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
