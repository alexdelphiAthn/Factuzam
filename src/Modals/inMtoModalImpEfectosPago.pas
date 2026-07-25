{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpEfectosPago                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Listado de efectos de pago". Lista la cartera     }
{    de pagos a proveedor con filtros por fecha, almacén, proveedor, número    }
{    de efecto, banco/remesa, tipo y situación del efecto.                     }
{******************************************************************************}
unit inMtoModalImpEfectosPago;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxRadioGroup,
  cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses, dxSkinsForm,
  System.Actions, Vcl.ActnList, frxSmartMemo, frLocalization,
  frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab,
  cxLocalization;

type
  TfrmPrintEfectosPago = class(TfrmPrintMultiFiltro)
    unqryEfectosPagoPrint: TUniQuery;
    fxdsEfectosPago: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FrgTipoFecha: TcxRadioGroup;
    FrgSituacion: TcxRadioGroup;
    FtxtNumeroDesde: TcxTextEdit;
    FtxtNumeroHasta: TcxTextEdit;
    FchkSoloTotales: TcxCheckBox;
    FclbTotales: TcxCheckListBox;
    FclbTipos: TcxCheckListBox;
    FclbSituaciones: TcxCheckListBox;
    FclbBancos: TcxCheckListBox;
    procedure CrearControlesPropios;
    procedure CargarChecklist(AClb: TcxCheckListBox; const ASQL: string);
    procedure CargarTotales;
    procedure CargarTiposEfecto;
    procedure CargarSituaciones;
    procedure CargarBancosRemesa;
    function CampoFechaSQL: string;
    function CSVTipos: string;
    function CSVSituaciones: string;
    function CSVBancos: string;
    function TextoNumero(AEdit: TcxTextEdit): string;
    function ExisteTabla(const ANombreTabla: string): Boolean;
    function NivelesTotales: TArray<string>;
    function NivelN(const ANiveles: TArray<string>; AIndex: Integer): string;
    function GrupoCodigoSQL(const ACodigo: string): string;
    function GrupoEtiquetaSQL(const ACodigo: string): string;
    function SQLListado: string;
    procedure ReportBeforePrint(Component: TfrxReportComponent);
  protected
    function FiltrosUsados: TFiltrosReport; override;
    function SQLFiltroProveedores: string; override;
    procedure DoShow; override;
  public
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

var
  frmPrintEfectosPago: TfrmPrintEfectosPago;

implementation

{$R *.dfm}

{ TfrmPrintEfectosPago }

function TfrmPrintEfectosPago.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frProveedores];
end;

function TfrmPrintEfectosPago.SQLFiltroProveedores: string;
begin
  Result :=
    'SELECT e.CODIGO_PRV_EFEC AS COD, ' +
    '       COALESCE(NULLIF(MAX(e.RAZON_SOCIAL_PRV_EFEC), ''''), ' +
    '                e.CODIGO_PRV_EFEC) AS NOM ' +
    '  FROM fza_efectos_compra e ' +
    ' WHERE COALESCE(e.CODIGO_PRV_EFEC, '''') <> '''' ' +
    ' GROUP BY e.CODIGO_PRV_EFEC ' +
    ' ORDER BY NOM, e.CODIGO_PRV_EFEC';
end;

procedure TfrmPrintEfectosPago.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    FInicializado := True;
  end;
end;

procedure TfrmPrintEfectosPago.CrearControlesPropios;
var
  lblDesde: TcxLabel;
  lblHasta: TcxLabel;
begin
  if TabFechas <> nil then
  begin
    FrgTipoFecha := TcxRadioGroup.Create(Self);
    FrgTipoFecha.Parent := TabFechas;
    FrgTipoFecha.Left := 190;
    FrgTipoFecha.Top := 12;
    FrgTipoFecha.Width := 155;
    FrgTipoFecha.Height := 94;
    FrgTipoFecha.Caption := ' Fecha ';
    FrgTipoFecha.Properties.Items.Add.Caption := 'Documento';
    FrgTipoFecha.Properties.Items.Add.Caption := 'Valor';
    FrgTipoFecha.Properties.Items.Add.Caption := 'Vencimiento';
    FrgTipoFecha.ItemIndex := 2;
    FrgSituacion := TcxRadioGroup.Create(Self);
    FrgSituacion.Parent := TabFechas;
    FrgSituacion.Left := 355;
    FrgSituacion.Top := 12;
    FrgSituacion.Width := 150;
    FrgSituacion.Height := 122;
    FrgSituacion.Caption := ' Situación ';
    FrgSituacion.Properties.Items.Add.Caption := 'Pagados';
    FrgSituacion.Properties.Items.Add.Caption := 'Impagados';
    FrgSituacion.Properties.Items.Add.Caption := 'Pendientes';
    FrgSituacion.Properties.Items.Add.Caption := 'Todos';
    FrgSituacion.ItemIndex := 3;
    lblDesde := TcxLabel.Create(Self);
    lblDesde.Parent := TabFechas;
    lblDesde.Transparent := True;
    lblDesde.Left := 16;
    lblDesde.Top := 132;
    lblDesde.Caption := 'Nº efecto desde:';
    FtxtNumeroDesde := TcxTextEdit.Create(Self);
    FtxtNumeroDesde.Parent := TabFechas;
    FtxtNumeroDesde.Left := 16;
    FtxtNumeroDesde.Top := 154;
    FtxtNumeroDesde.Width := 160;
    lblHasta := TcxLabel.Create(Self);
    lblHasta.Parent := TabFechas;
    lblHasta.Transparent := True;
    lblHasta.Left := 190;
    lblHasta.Top := 132;
    lblHasta.Caption := 'Nº efecto hasta:';
    FtxtNumeroHasta := TcxTextEdit.Create(Self);
    FtxtNumeroHasta.Parent := TabFechas;
    FtxtNumeroHasta.Left := 190;
    FtxtNumeroHasta.Top := 154;
    FtxtNumeroHasta.Width := 160;
    FchkSoloTotales := TcxCheckBox.Create(Self);
    FchkSoloTotales.Parent := TabFechas;
    FchkSoloTotales.Left := 355;
    FchkSoloTotales.Top := 154;
    FchkSoloTotales.Width := 170;
    FchkSoloTotales.Caption := 'Mostrar sólo totales';
  end;
  FclbTotales := CrearTabChecklist('Totales');
  CargarTotales;
  FclbTipos := CrearTabChecklist('Tipos de efecto');
  CargarTiposEfecto;
  FclbSituaciones := CrearTabChecklist('Situación efectos');
  CargarSituaciones;
  FclbBancos := CrearTabChecklist('Bancos remesa');
  CargarBancosRemesa;
end;

procedure TfrmPrintEfectosPago.CargarChecklist(AClb: TcxCheckListBox;
  const ASQL: string);
var
  item: TcxCheckListBoxItem;
  q: TUniQuery;
  sCod: string;
  sNom: string;
begin
  if AClb <> nil then
  begin
    AClb.Items.Clear;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text := ASQL;
      q.Open;
      while not q.Eof do
      begin
        sCod := q.FieldByName('COD').AsString;
        sNom := q.FieldByName('NOM').AsString;
        item := AClb.Items.Add;
        if (sNom <> '') and (sNom <> sCod) then
          item.Text := sCod + ' - ' + sNom
        else
          item.Text := sCod;
        item.State := cbsUnchecked;
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TfrmPrintEfectosPago.CargarTotales;

  procedure Agregar(const ACod, AEtiq: string; AMarcado: Boolean);
  var
    item: TcxCheckListBoxItem;
  begin
    item := FclbTotales.Items.Add;
    item.Text := ACod + ' - ' + AEtiq;
    if AMarcado then
      item.State := cbsChecked
    else
      item.State := cbsUnchecked;
  end;

begin
  if FclbTotales <> nil then
  begin
    FclbTotales.Items.Clear;
    Agregar('ALM', 'Almacenes', False);
    Agregar('FECHA', 'Fechas', False);
    Agregar('PRV', 'Proveedores', False);
    Agregar('BANCO', 'Bancos remesa', True);
    Agregar('ESTADO', 'Situación efectos', False);
    Agregar('TEFE', 'Tipos de efecto', False);
  end;
end;

procedure TfrmPrintEfectosPago.CargarTiposEfecto;
begin
  CargarChecklist(FclbTipos,
    'SELECT DISTINCT e.CODIGO_TEFE_EFEC AS COD, ' +
    '       COALESCE(NULLIF(t.DESCRIPCION_TEFE, ''''), ' +
    '                e.CODIGO_TEFE_EFEC) AS NOM ' +
    '  FROM fza_efectos_compra e ' +
    '  LEFT JOIN fza_tipos_efecto t ' +
    '    ON t.CODIGO_TEFE = e.CODIGO_TEFE_EFEC ' +
    ' WHERE COALESCE(e.CODIGO_TEFE_EFEC, '''') <> '''' ' +
    ' ORDER BY NOM, COD');
end;

procedure TfrmPrintEfectosPago.CargarSituaciones;
begin
  CargarChecklist(FclbSituaciones,
    'SELECT DISTINCT COALESCE(NULLIF(ESTADO_EFEC, ''''), ' +
    '       ''PENDIENTE'') AS COD, ' +
    '       COALESCE(NULLIF(ESTADO_EFEC, ''''), ''PENDIENTE'') AS NOM ' +
    '  FROM fza_efectos_compra ' +
    ' ORDER BY COD');
end;

procedure TfrmPrintEfectosPago.CargarBancosRemesa;
var
  bEmpBancos: Boolean;
  bBancos: Boolean;
  sSQL: string;
begin
  bEmpBancos := ExisteTabla('fza_empresas_bancos');
  bBancos := ExisteTabla('fza_bancos');
  sSQL :=
    'SELECT DISTINCT COALESCE(NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
    '       ''-'') AS COD, ';
  if bEmpBancos and bBancos then
  begin
    sSQL := sSQL +
      '       COALESCE(NULLIF(b.NOMBRE_BAN, ''''), ' +
      '                NULLIF(eb.NOMBRE_EMPBAN, ''''), ' +
      '                NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '                ''Sin banco remesa'') AS NOM ' +
      '  FROM fza_efectos_compra e ' +
      '  LEFT JOIN fza_empresas_bancos eb ' +
      '    ON eb.CODIGO_EMPBAN = e.CODIGO_EMPBAN_EFEC ' +
      '  LEFT JOIN fza_bancos b ' +
      '    ON b.CODIGO_BAN = eb.CODIGO_BAN_EMPBAN ';
  end
  else if bEmpBancos then
  begin
    sSQL := sSQL +
      '       COALESCE(NULLIF(eb.NOMBRE_EMPBAN, ''''), ' +
      '                NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '                ''Sin banco remesa'') AS NOM ' +
      '  FROM fza_efectos_compra e ' +
      '  LEFT JOIN fza_empresas_bancos eb ' +
      '    ON eb.CODIGO_EMPBAN = e.CODIGO_EMPBAN_EFEC ';
  end
  else
  begin
    sSQL := sSQL +
      '       COALESCE(NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '                ''Sin banco remesa'') AS NOM ' +
      '  FROM fza_efectos_compra e ';
  end;
  CargarChecklist(FclbBancos, sSQL + ' ORDER BY NOM, COD');
end;

function TfrmPrintEfectosPago.CampoFechaSQL: string;
begin
  if (FrgTipoFecha <> nil) and (FrgTipoFecha.ItemIndex = 0) then
    Result := 'COALESCE(E.FECHA_FACTURA_VIEW_EFEC, F.FECHA_FACC, ' +
              'E.FECHA_EMISION_EFEC, E.FECHA_VENCIMIENTO_EFEC)'
  else if (FrgTipoFecha <> nil) and (FrgTipoFecha.ItemIndex = 1) then
    Result := 'COALESCE(F.FECHA_VALOR_FACC, E.FECHA_EMISION_EFEC, ' +
              'E.FECHA_FACTURA_VIEW_EFEC, E.FECHA_VENCIMIENTO_EFEC)'
  else
    Result := 'COALESCE(E.FECHA_VENCIMIENTO_EFEC, ' +
              'E.FECHA_FACTURA_VIEW_EFEC, E.FECHA_EMISION_EFEC)';
end;

function TfrmPrintEfectosPago.CSVTipos: string;
begin
  Result := SeleccionadosCSV(FclbTipos);
end;

function TfrmPrintEfectosPago.CSVSituaciones: string;
begin
  Result := SeleccionadosCSV(FclbSituaciones);
end;

function TfrmPrintEfectosPago.CSVBancos: string;
begin
  Result := SeleccionadosCSV(FclbBancos);
end;

function TfrmPrintEfectosPago.TextoNumero(AEdit: TcxTextEdit): string;
begin
  if AEdit <> nil then
    Result := Trim(AEdit.Text)
  else
    Result := '';
end;

function TfrmPrintEfectosPago.ExisteTabla(const ANombreTabla: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'SELECT COUNT(*) AS C ' +
      '  FROM INFORMATION_SCHEMA.TABLES ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = :TABLA';
    q.ParamByName('TABLA').AsString := ANombreTabla;
    q.Open;
    Result := q.FieldByName('C').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

function TfrmPrintEfectosPago.NivelesTotales: TArray<string>;
var
  i: Integer;
  sl: TStringList;
  sCsv: string;
begin
  sCsv := SeleccionadosCSV(FclbTotales);
  if sCsv = '' then
  begin
    SetLength(Result, 1);
    Result[0] := 'BANCO';
  end
  else
  begin
    sl := TStringList.Create;
    try
      sl.StrictDelimiter := True;
      sl.Delimiter := ',';
      sl.DelimitedText := sCsv;
      SetLength(Result, sl.Count);
      for i := 0 to sl.Count - 1 do
        Result[i] := sl[i];
    finally
      FreeAndNil(sl);
    end;
  end;
end;

function TfrmPrintEfectosPago.NivelN(const ANiveles: TArray<string>;
  AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < Length(ANiveles)) then
    Result := ANiveles[AIndex]
  else
    Result := '';
end;

function TfrmPrintEfectosPago.GrupoCodigoSQL(const ACodigo: string): string;
begin
  if SameText(ACodigo, 'ALM') then
    Result := 'COALESCE(NULLIF(D.CODIGO_ALM_EFEC, ''''), ''-'')'
  else if SameText(ACodigo, 'FECHA') then
    Result := 'DATE_FORMAT(D.FECHA_FILTRO_EFEC, ''%Y-%m-%d'')'
  else if SameText(ACodigo, 'PRV') then
    Result := 'COALESCE(NULLIF(D.CODIGO_PRV_EFEC, ''''), ''-'')'
  else if SameText(ACodigo, 'BANCO') then
    Result := 'D.CODIGO_BANCO_REMESA'
  else if SameText(ACodigo, 'ESTADO') then
    Result := 'D.SITUACION_EFEC'
  else if SameText(ACodigo, 'TEFE') then
    Result := 'COALESCE(NULLIF(D.CODIGO_TEFE_EFEC, ''''), ''-'')'
  else
    Result := '''''';
end;

function TfrmPrintEfectosPago.GrupoEtiquetaSQL(const ACodigo: string): string;
begin
  if SameText(ACodigo, 'ALM') then
    Result := 'CONCAT(''ALMACEN '', ' + GrupoCodigoSQL('ALM') + ')'
  else if SameText(ACodigo, 'FECHA') then
    Result := 'CONCAT(''FECHA '', DATE_FORMAT(D.FECHA_FILTRO_EFEC, ' +
              '''%d/%m/%Y''))'
  else if SameText(ACodigo, 'PRV') then
    Result := 'CONCAT(''PVDOR. '', D.CODIGO_PRV_EFEC, '' '', ' +
              'D.PROVEEDOR_EFEC)'
  else if SameText(ACodigo, 'BANCO') then
    Result := 'CONCAT(''BANCO REM. '', D.BANCO_REMESA_EFEC)'
  else if SameText(ACodigo, 'ESTADO') then
    Result := 'CONCAT(''SITUACION '', D.SITUACION_EFEC)'
  else if SameText(ACodigo, 'TEFE') then
    Result := 'CONCAT(''TIPO EFECTO '', D.TIPO_EFECTO_EFEC)'
  else
    Result := '''''';
end;

function TfrmPrintEfectosPago.SQLListado: string;
var
  niveles: TArray<string>;
  sl: TStringList;
  bEmpBancos: Boolean;
  bBancos: Boolean;

  procedure Add(const S: string);
  begin
    sl.Add(S);
  end;

begin
  niveles := NivelesTotales;
  bEmpBancos := ExisteTabla('fza_empresas_bancos');
  bBancos := ExisteTabla('fza_bancos');
  sl := TStringList.Create;
  try
    Add('SELECT D.*,');
    Add('       ' + GrupoCodigoSQL(NivelN(niveles, 0)) + ' AS GRUPO1_COD,');
    Add('       ' + GrupoEtiquetaSQL(NivelN(niveles, 0)) +
        ' AS GRUPO1_ETIQ,');
    Add('       ' + GrupoCodigoSQL(NivelN(niveles, 1)) + ' AS GRUPO2_COD,');
    Add('       ' + GrupoEtiquetaSQL(NivelN(niveles, 1)) +
        ' AS GRUPO2_ETIQ,');
    Add('       ' + GrupoCodigoSQL(NivelN(niveles, 2)) + ' AS GRUPO3_COD,');
    Add('       ' + GrupoEtiquetaSQL(NivelN(niveles, 2)) +
        ' AS GRUPO3_ETIQ');
    Add('  FROM (');
    Add('SELECT CONCAT(E.SERIE_FACC_EFEC, ''.'', E.NUMERO_FACC_EFEC,');
    Add('              ''/'', LPAD(E.NUMERO_EFEC, 3, ''0''))');
    Add('          AS IDENTIFICADOR_EFECTO,');
    Add('       COALESCE(NULLIF(E.DESCRIPCION_TEFE_VIEW_EFEC, ''''),');
    Add('                ''No definido'') AS TIPO_EFECTO_EFEC,');
    Add('       COALESCE(NULLIF(F.CODIGO_ALM_FACC, ''''), '''')');
    Add('          AS CODIGO_ALM_EFEC,');
    Add('       COALESCE(NULLIF(E.CODIGO_PRV_EFEC, ''''), '''')');
    Add('          AS CODIGO_PRV_EFEC,');
    Add('       COALESCE(NULLIF(E.NOMBRE_PRV_VIEW_EFEC, ''''),');
    Add('                NULLIF(E.RAZON_SOCIAL_PRV_EFEC, ''''),');
    Add('                E.CODIGO_PRV_EFEC) AS PROVEEDOR_EFEC,');
    Add('       COALESCE(NULLIF(E.ESTADO_EFEC, ''''), ''PENDIENTE'')');
    Add('          AS SITUACION_EFEC,');
    Add('       E.FECHA_VENCIMIENTO_EFEC,');
    Add('       COALESCE(E.FECHA_FACTURA_VIEW_EFEC, F.FECHA_FACC)');
    Add('          AS FECHA_DOCUMENTO_EFEC,');
    Add('       COALESCE(F.FECHA_VALOR_FACC, E.FECHA_EMISION_EFEC)');
    Add('          AS FECHA_VALOR_EFEC,');
    Add('       ' + CampoFechaSQL + ' AS FECHA_FILTRO_EFEC,');
    Add('       DATEDIFF(E.FECHA_VENCIMIENTO_EFEC,');
    Add('                COALESCE(E.FECHA_FACTURA_VIEW_EFEC,');
    Add('                         F.FECHA_FACC, E.FECHA_EMISION_EFEC))');
    Add('          AS DIAS_EFEC,');
    Add('       COALESCE(E.IMPORTE_EFEC, 0) AS IMPORTE_EFEC,');
    Add('       COALESCE(E.IMPORTE_PAGADO_EFEC, 0) AS IMPORTE_PAGADO_EFEC,');
    Add('       COALESCE(E.IMPORTE_PENDIENTE_EFEC, 0)');
    Add('          AS IMPORTE_PENDIENTE_EFEC,');
    Add('       E.SERIE_FACC_EFEC,');
    Add('       E.NUMERO_FACC_EFEC,');
    Add('       E.NUMERO_EFEC,');
    Add('       E.CODIGO_TEFE_EFEC,');
    Add('       COALESCE(NULLIF(E.SERIE_REMC_EFEC, ''''), '''')');
    Add('          AS SERIE_REMC_EFEC,');
    Add('       COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''')');
    Add('          AS NUMERO_REMC_EFEC,');
    Add('       CASE');
    Add('         WHEN COALESCE(NULLIF(E.SERIE_REMC_EFEC, ''''), '''') = ''''');
    Add('           THEN COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''')');
    Add('         WHEN COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''') = ''''');
    Add('           THEN E.SERIE_REMC_EFEC');
    Add('         ELSE CONCAT(E.SERIE_REMC_EFEC, ''/'', E.NUMERO_REMC_EFEC)');
    Add('       END AS REMESA_EFEC,');
    Add('       COALESCE(NULLIF(E.CODIGO_EMPBAN_EFEC, ''''), ''-'')');
    Add('          AS CODIGO_BANCO_REMESA,');
    if bEmpBancos and bBancos then
    begin
      Add('       COALESCE(NULLIF(B.NOMBRE_BAN, ''''),');
      Add('                NULLIF(EB.NOMBRE_EMPBAN, ''''),');
      Add('                NULLIF(E.CODIGO_EMPBAN_EFEC, ''''),');
      Add('                ''Sin banco remesa'') AS BANCO_REMESA_EFEC,');
    end
    else if bEmpBancos then
    begin
      Add('       COALESCE(NULLIF(EB.NOMBRE_EMPBAN, ''''),');
      Add('                NULLIF(E.CODIGO_EMPBAN_EFEC, ''''),');
      Add('                ''Sin banco remesa'') AS BANCO_REMESA_EFEC,');
    end
    else
    begin
      Add('       COALESCE(NULLIF(E.CODIGO_EMPBAN_EFEC, ''''),');
      Add('                ''Sin banco remesa'') AS BANCO_REMESA_EFEC,');
    end;
    Add('       COALESCE(NULLIF(E.REFERENCIA_DOCUMENTO_EFEC, ''''),');
    Add('                NULLIF(E.DOC_EXTERNO_EFEC, ''''),');
    Add('                CONCAT(E.SERIE_FACC_EFEC, ''/'',');
    Add('                       E.NUMERO_FACC_EFEC)) AS REFERENCIA_EFEC');
    Add('  FROM vi_efectos_compra E');
    Add('  LEFT JOIN fza_facturas_compra F');
    Add('    ON F.SERIE_FACC = E.SERIE_FACC_EFEC');
    Add('   AND F.NUMERO_FACC = E.NUMERO_FACC_EFEC');
    if bEmpBancos then
    begin
      Add('  LEFT JOIN fza_empresas_bancos EB');
      Add('    ON EB.CODIGO_EMPBAN = E.CODIGO_EMPBAN_EFEC');
    end;
    if bEmpBancos and bBancos then
    begin
      Add('  LEFT JOIN fza_bancos B');
      Add('    ON B.CODIGO_BAN = EB.CODIGO_BAN_EMPBAN');
    end;
    Add('       ) D');
    Add(' WHERE D.FECHA_FILTRO_EFEC >= :pDESDE');
    Add('   AND D.FECHA_FILTRO_EFEC <= :pHASTA');
    Add('   AND (:pALM = '''' OR FIND_IN_SET(D.CODIGO_ALM_EFEC, :pALM))');
    Add('   AND (:pPRV = '''' OR FIND_IN_SET(D.CODIGO_PRV_EFEC, :pPRV))');
    Add('   AND (:pTIP = '''' OR FIND_IN_SET(D.CODIGO_TEFE_EFEC, :pTIP))');
    Add('   AND (:pEST = '''' OR FIND_IN_SET(D.SITUACION_EFEC, :pEST))');
    Add('   AND (:pBAN = '''' OR FIND_IN_SET(D.CODIGO_BANCO_REMESA, :pBAN))');
    Add('   AND (:pNUMDESDE = '''' OR D.IDENTIFICADOR_EFECTO >= :pNUMDESDE)');
    Add('   AND (:pNUMHASTA = '''' OR D.IDENTIFICADOR_EFECTO <= :pNUMHASTA)');
    Add('   AND (:pMODOEST = 3');
    Add('        OR (:pMODOEST = 0 AND D.IMPORTE_PENDIENTE_EFEC <= 0.0001)');
    Add('        OR (:pMODOEST = 1 AND D.SITUACION_EFEC = ''DEVUELTO'')');
    Add('        OR (:pMODOEST = 2 AND D.IMPORTE_PENDIENTE_EFEC > 0.0001');
    Add('            AND D.SITUACION_EFEC NOT IN');
    Add('              (''PAGADO'', ''ANULADO'', ''CONCILIADO'')))');
    Add(' ORDER BY GRUPO1_COD, GRUPO2_COD, GRUPO3_COD,');
    Add('          D.FECHA_VENCIMIENTO_EFEC,');
    Add('          D.IDENTIFICADOR_EFECTO');
    Result := sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

procedure TfrmPrintEfectosPago.preparar_consulta;
begin
  inherited;
  with unqryEfectosPagoPrint do
  begin
    Close;
    Connection := ConexionPrincipal;
    SQL.Text := SQLListado;
    ParamByName('pDESDE').AsDateTime := DateOf(FechaDesde);
    ParamByName('pHASTA').AsDateTime := DateOf(FechaHasta);
    ParamByName('pALM').AsString := CSVAlmacenes;
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTIP').AsString := CSVTipos;
    ParamByName('pEST').AsString := CSVSituaciones;
    ParamByName('pBAN').AsString := CSVBancos;
    ParamByName('pNUMDESDE').AsString := TextoNumero(FtxtNumeroDesde);
    ParamByName('pNUMHASTA').AsString := TextoNumero(FtxtNumeroHasta);
    if FrgSituacion <> nil then
      ParamByName('pMODOEST').AsInteger := FrgSituacion.ItemIndex
    else
      ParamByName('pMODOEST').AsInteger := 3;
    Open;
  end;
  fxdsEfectosPago.UpdateBounds;
end;

procedure TfrmPrintEfectosPago.AfterReportLoaded;
begin
  inherited;
  fxdsEfectosPago.DataSet := unqryEfectosPagoPrint;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsEfectosPago);
  frxrprt1.OnBeforePrint := ReportBeforePrint;
end;

procedure TfrmPrintEfectosPago.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  nivel: Integer;
  sNom: string;
begin
  ReportBeforePrintConQR(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or
       (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       unqryEfectosPagoPrint.Active then
      TfrxBand(Component).Visible :=
        unqryEfectosPagoPrint.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if sNom = 'MasterData1' then
      TfrxBand(Component).Visible :=
        (FchkSoloTotales = nil) or (not FchkSoloTotales.Checked);
  end;
end;

end.
