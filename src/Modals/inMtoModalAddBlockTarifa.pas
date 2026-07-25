{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockTarifa                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de carga masiva de articulos en una tarifa.                         }
{    Hereda de AddBlockBase y permite ajustes de precio y descuento.           }
{******************************************************************************}
unit inMtoModalAddBlockTarifa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxClasses, cxContainer, cxEdit,
  cxLabel, cxButtons, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxCurrencyEdit, cxCheckBox, cxRadioGroup,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inMtoModalAddBlockBase, cxLookAndFeelPainters, Vcl.Menus, cxFilter,
  cxCustomData, cxStyles, dxScrollbarAnnotations, cxTL, cxDBData, Vcl.ComCtrls,
  dxCore, cxDateUtils, JvComponentBase, JvEnterTab, cxLocalization, cxSplitter,
  cxSpinEdit, cxCustomListBox, cxCheckListBox, cxGroupBox, cxInplaceContainer,
  cxDBTL, cxTLData, cxPC;

type
  TAjusteAlcance = (aaSoloFinal, aaSoloSalida, aaAmbos);

  TAddBlockTarifaResult = record
    Aceptado          : Boolean;
    NumInsertados     : Integer;
    ArticulosCodigos  : TArray<string>;
    CodigoTarifa      : string;
    FechaDesdeTarifa  : TDateTime;
    FechaHastaTarifa  : TDateTime;
    UsaFechaHasta     : Boolean;
    PorcenDtoDefecto  : Double;
    AjustarPrecio     : Boolean;
    MultiploAjuste    : Double;
    RestarAjuste      : Double;
    AlcanceAjuste     : TAjusteAlcance;
    CopiarDeTarifa    : string;
  end;

  TfrmModalAddBlockTarifa = class(TfrmModalAddBlockBase)
    // Controles que viven en pnlCabeceraExtra (heredado vacio)
    lblTarifa: TcxLabel;
    cbxTarifa: TcxComboBox;
    lblFechaDesde: TcxLabel;
    dtFechaDesde: TcxDateEdit;
    chkConFechaHasta: TcxCheckBox;
    dtFechaHasta: TcxDateEdit;
    lblPorcenDto: TcxLabel;
    spnPorcenDto: TcxCurrencyEdit;
    chkAjustarPrecio: TcxCheckBox;
    lblMultiplo: TcxLabel;
    spnMultiplo: TcxCurrencyEdit;
    lblRestar: TcxLabel;
    spnRestar: TcxCurrencyEdit;
    rgAjusteAlcance: TcxRadioGroup;
    chkCopiarDeTarifa: TcxCheckBox;
    cbxTarifaOrigen: TcxComboBox;

    // Columnas extra del preview (precios origen)
    colPrevPrecioSalidaOrig: TcxGridDBColumn;
    colPrevPrecioFinalOrig: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);
    procedure chkConFechaHastaPropertiesChange(Sender: TObject);
    procedure chkAjustarPrecioPropertiesChange(Sender: TObject);
    procedure chkCopiarDeTarifaPropertiesChange(Sender: TObject);

  protected
    FResultadoTarifa : TAddBlockTarifaResult;
    FCodigoTarifaIni : string;

    // === Overrides ==========================================================
    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    override;
    function  ColumnasSelectExtra: string; override;
    function  SubquerYaCargado: string; override;
    function  WhereExcluirYaCargados: string; override;
    procedure VincularParametrosExtra(AQry: TUniQuery); override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;
    procedure ConfigurarPreviewExtra; override;

    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean; override;

  private
    procedure CargarTarifas;
    function  ObtenerCodigoTarifaActual: string;
    function  ObtenerCodigoTarifaOrigen: string;
    function  AlcanceAjusteActual: TAjusteAlcance;

    function  AjustarPrecio(APrecio: Double): Double;
    procedure CalcularPreciosFinales(APrecioOrigSalida,
                                     APrecioOrigFinal: Double;
                                     out APrecioSalida, APrecioFinal: Double;
                                     out APorcenDto: Double);

  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const ACodigoTarifa: string): TAddBlockTarifaResult;
    property ResultadoTarifa: TAddBlockTarifaResult read FResultadoTarifa;
  end;

implementation

{$R *.dfm}

// ============================================================================
//   API publica
// ============================================================================

class function TfrmModalAddBlockTarifa.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection;
  const ACodigoTarifa: string): TAddBlockTarifaResult;
var
  frm: TfrmModalAddBlockTarifa;
  i  : Integer;
begin
  frm := TfrmModalAddBlockTarifa.Create(AOwner);
  try
    frm.FCodigoTarifaIni := ACodigoTarifa;
    frm.Inicializar(AConn);
    frm.CargarTarifas;

    if ACodigoTarifa <> '' then
      for i := 0 to frm.cbxTarifa.Properties.Items.Count - 1 do
        if Pos(ACodigoTarifa, frm.cbxTarifa.Properties.Items[i]) = 1 then
        begin
          frm.cbxTarifa.ItemIndex := i;
          Break;
        end;

    frm.ShowModal;
    Result := frm.FResultadoTarifa;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockTarifa.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Caption := 'A~adir Bloque - Carga masiva en Tarifa';

  // Defaults especificos
  dtFechaDesde.Date           := Date;
  chkConFechaHasta.Checked    := False;
  dtFechaHasta.Enabled        := False;
  spnPorcenDto.Value          := 0;
  chkAjustarPrecio.Checked    := False;
  spnMultiplo.Value           := 0.01;
  spnRestar.Value             := 0.01;
  spnMultiplo.Enabled         := False;
  spnRestar.Enabled           := False;
  rgAjusteAlcance.Enabled     := False;
  rgAjusteAlcance.ItemIndex   := 0;
  chkCopiarDeTarifa.Checked   := False;
  cbxTarifaOrigen.Enabled     := False;

  FResultadoTarifa.Aceptado := False;
end;

procedure TfrmModalAddBlockTarifa.CargarTarifas;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR ' +
      'FROM fza_tarifas ' +
      'WHERE ESACTIVO_ARTTAR = ''S'' ' +
      'ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
    qry.Open;
    cbxTarifa.Properties.Items.Clear;
    cbxTarifaOrigen.Properties.Items.Clear;
    while not qry.Eof do
    begin
      cbxTarifa.Properties.Items.Add(
        qry.FieldByName('CODIGO_TAR_ARTTAR').AsString + ' - ' +
        qry.FieldByName('NOMBRE_TAR_TAR').AsString);
      cbxTarifaOrigen.Properties.Items.Add(
        qry.FieldByName('CODIGO_TAR_ARTTAR').AsString + ' - ' +
        qry.FieldByName('NOMBRE_TAR_TAR').AsString);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

// ============================================================================
//   Eventos
// ============================================================================

procedure TfrmModalAddBlockTarifa.chkConFechaHastaPropertiesChange(
  Sender: TObject);
begin
  dtFechaHasta.Enabled := chkConFechaHasta.Checked;
end;

procedure TfrmModalAddBlockTarifa.chkAjustarPrecioPropertiesChange(
  Sender: TObject);
begin
  spnMultiplo.Enabled     := chkAjustarPrecio.Checked;
  spnRestar.Enabled       := chkAjustarPrecio.Checked;
  rgAjusteAlcance.Enabled := chkAjustarPrecio.Checked;
end;

procedure TfrmModalAddBlockTarifa.chkCopiarDeTarifaPropertiesChange(
  Sender: TObject);
begin
  cbxTarifaOrigen.Enabled := chkCopiarDeTarifa.Checked;
  if not chkCopiarDeTarifa.Checked then
    cbxTarifaOrigen.ItemIndex := -1;
end;

// ============================================================================
//   Helpers
// ============================================================================

function TfrmModalAddBlockTarifa.ObtenerCodigoTarifaActual: string;
begin
  Result := Trim(cbxTarifa.Text);
  if Pos(' - ', Result) > 0 then
    Result := Copy(Result, 1, Pos(' - ', Result) - 1);
end;

function TfrmModalAddBlockTarifa.ObtenerCodigoTarifaOrigen: string;
begin
  if not chkCopiarDeTarifa.Checked then
  begin
    Result := '';
    Exit;
  end;
  Result := Trim(cbxTarifaOrigen.Text);
  if Pos(' - ', Result) > 0 then
    Result := Copy(Result, 1, Pos(' - ', Result) - 1);
end;

function TfrmModalAddBlockTarifa.AlcanceAjusteActual: TAjusteAlcance;
begin
  case rgAjusteAlcance.ItemIndex of
    1: Result := aaSoloSalida;
    2: Result := aaAmbos;
  else
    Result := aaSoloFinal;
  end;
end;

function TfrmModalAddBlockTarifa.AjustarPrecio(APrecio: Double): Double;
var
  n, r, val: Double;
begin
  Result := APrecio;
  if not chkAjustarPrecio.Checked then Exit;
  if APrecio <= 0 then Exit;

  n := spnMultiplo.Value;
  r := spnRestar.Value;
  if n <= 0 then Exit;

  // Ceil hacia el siguiente múltiplo de n y luego resta "menos"
  val := Ceil(APrecio / n) * n - r;
  if val < 0 then val := 0;
  Result := Round(val * 100) / 100;
end;

procedure TfrmModalAddBlockTarifa.CalcularPreciosFinales(
  APrecioOrigSalida, APrecioOrigFinal: Double;
  out APrecioSalida, APrecioFinal: Double; out APorcenDto: Double);
var
  baseSalida: Double;
  alcance   : TAjusteAlcance;
begin
  APorcenDto := spnPorcenDto.Value;

  if APrecioOrigSalida > 0 then
    baseSalida := APrecioOrigSalida
  else
    baseSalida := APrecioOrigFinal;

  APrecioSalida := baseSalida;

  if APorcenDto > 0 then
    APrecioFinal := baseSalida * (1 - APorcenDto / 100)
  else
    APrecioFinal := baseSalida;

  if chkAjustarPrecio.Checked then
  begin
    alcance := AlcanceAjusteActual;
    if alcance in [aaSoloSalida, aaAmbos] then
      APrecioSalida := AjustarPrecio(APrecioSalida);
    if alcance in [aaSoloFinal, aaAmbos] then
      APrecioFinal := AjustarPrecio(APrecioFinal);

    if (APrecioSalida > 0) and (APrecioSalida <> APrecioFinal) then
      APorcenDto := (1 - APrecioFinal / APrecioSalida) * 100
    else if APrecioSalida = APrecioFinal then
      APorcenDto := 0;
  end;
end;

// ============================================================================
//   Overrides de la base
// ============================================================================

function TfrmModalAddBlockTarifa.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := False;
  AMensaje := '';

  if ObtenerCodigoTarifaActual = '' then
  begin
    AMensaje := 'Selecciona la tarifa destino antes de previsualizar.';
    Exit;
  end;

  if chkCopiarDeTarifa.Checked then
  begin
    if ObtenerCodigoTarifaOrigen = '' then
    begin
      AMensaje := 'Selecciona la tarifa origen para copiar precios.';
      Exit;
    end;
    if SameText(ObtenerCodigoTarifaOrigen, ObtenerCodigoTarifaActual) then
    begin
      AMensaje :=
        'La tarifa origen no puede ser la misma que la tarifa destino.';
      Exit;
    end;
  end;

  if chkAjustarPrecio.Checked and (spnMultiplo.Value <= 0) then
  begin
    AMensaje := 'El multiplo del ajuste debe ser mayor que 0.';
    Exit;
  end;

  Result := True;
end;

function TfrmModalAddBlockTarifa.ColumnasSelectExtra: string;
var
  tarOrigen: string;
begin
  tarOrigen := ObtenerCodigoTarifaOrigen;
  if tarOrigen <> '' then
  begin
    Result :=
      '(SELECT t.PRECIO_SALIDA_ARTTAR' +
      '  FROM fza_articulos_tarifas t' +
      ' WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART' +
      '   AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_S' +
      '   AND t.ESACTIVO_ARTTAR = ''S''' +
      ' ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) AS PRECIO_SALIDA_ORIG, ' +
      '(SELECT t.PRECIO_FINAL_ARTTAR' +
      '  FROM fza_articulos_tarifas t' +
      ' WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART' +
      '   AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_F' +
      '   AND t.ESACTIVO_ARTTAR = ''S''' +
      ' ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) AS PRECIO_FINAL_ORIG,';
  end
  else
    Result := '0 AS PRECIO_SALIDA_ORIG, 0 AS PRECIO_FINAL_ORIG,';
end;

function TfrmModalAddBlockTarifa.SubquerYaCargado: string;
begin
  Result :=
    'CASE WHEN EXISTS (SELECT 1 FROM fza_articulos_tarifas ta' +
    '                   WHERE ta.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART' +
    '                     AND ta.CODIGO_TAR_ARTTAR = :P_TARIFA_CHK)' +
    '     THEN ''S'' ELSE ''N'' END';
end;

function TfrmModalAddBlockTarifa.WhereExcluirYaCargados: string;
begin
  Result :=
    'NOT EXISTS (SELECT 1 FROM fza_articulos_tarifas tx' +
    '             WHERE tx.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART' +
    '               AND tx.CODIGO_TAR_ARTTAR = :P_TARIFA_EXCL)';
end;

procedure TfrmModalAddBlockTarifa.VincularParametrosExtra(AQry: TUniQuery);

  function HasParam(const N: string): Boolean;
  begin
    Result := AQry.Params.FindParam(N) <> nil;
  end;

var
  tar, tarOrig: string;
begin
  tar     := ObtenerCodigoTarifaActual;
  tarOrig := ObtenerCodigoTarifaOrigen;

  if HasParam('P_TARIFA_CHK') then
    AQry.ParamByName('P_TARIFA_CHK').AsString := tar;
  if HasParam('P_TARIFA_EXCL') then
    AQry.ParamByName('P_TARIFA_EXCL').AsString := tar;
  if HasParam('P_TARIFA_ORIG_S') then
    AQry.ParamByName('P_TARIFA_ORIG_S').AsString := tarOrig;
  if HasParam('P_TARIFA_ORIG_F') then
    AQry.ParamByName('P_TARIFA_ORIG_F').AsString := tarOrig;
end;

function TfrmModalAddBlockTarifa.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result :=
    Format('Se van a insertar %d articulos en la tarifa "%s". Continuar?',
                   [ANumPendientes, ObtenerCodigoTarifaActual]);
end;

function TfrmModalAddBlockTarifa.TextoExito(ANumInsertados: Integer): string;
begin
  Result := Format('%d articulos anadidos a la tarifa correctamente.',
                   [ANumInsertados]);
end;

function TfrmModalAddBlockTarifa.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya en la tarifa';
end;

procedure TfrmModalAddBlockTarifa.ConfigurarPreviewExtra;
begin
  // Las columnas extra (precios origen) ya estan en el DFM
  // y se enlazan automaticamente por DataBinding.FieldName.
  // Aqui podriamos forzar visibilidad si el usuario no copia de tarifa.
  colPrevPrecioSalidaOrig.Visible := chkCopiarDeTarifa.Checked;
  colPrevPrecioFinalOrig.Visible  := chkCopiarDeTarifa.Checked;
end;

// ============================================================================
//   Insercion real
// ============================================================================

function TfrmModalAddBlockTarifa.EjecutarInsercion(out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  ins        : TUniQuery;
  codigoTar  : string;
  usuario    : string;
  codigos    : TList<string>;
  precOrigSal, precOrigFin: Double;
  precSalida, precFinal, dto: Double;
  dtoEuros: Double;
begin
  Result := False;
  ANumInsertados := 0;
  ACodigos := nil;

  if (FSqlPreview = nil) or (not FSqlPreview.Active) or
     (FSqlPreview.RecordCount = 0) then Exit;

  codigoTar := ObtenerCodigoTarifaActual;
  usuario   := IdentidadSesion.Usuario;

  codigos := TList<string>.Create;
  ins     := TUniQuery.Create(nil);
  try
    ins.Connection := FConn;
    ins.SQL.Text :=
      'INSERT INTO fza_articulos_tarifas (' +
      '  CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR,' +
      '  ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR,' +
      '  PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR,' +
      '  FECHA_DESDE_ARTTAR, FECHA_HASTA_ARTTAR,' +
      '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA' +
      ') VALUES (' +
      '  :CODIGO_ART_ART, '''', :CODIGO_TAR_ARTTAR,' +
      '  ''S'', :PRECIO_SALIDA, :PRECIO_FINAL,' +
      '  :PRECIO_DTO, :PORCEN_DTO, :FECHA_DESDE, :FECHA_HASTA,' +
      '  :USR, :USR2, NOW()' +
      ')';

    FSqlPreview.DisableControls;
    FConn.StartTransaction;
    try
      FSqlPreview.First;
      while not FSqlPreview.Eof do
      begin
        if FSqlPreview.FieldByName('YA_CARGADO').AsString = 'S' then
        begin
          FSqlPreview.Next;
          Continue;
        end;

        if chkCopiarDeTarifa.Checked then
        begin
          precOrigSal := FSqlPreview.FieldByName('PRECIO_SALIDA_ORIG').AsFloat;
          precOrigFin := FSqlPreview.FieldByName('PRECIO_FINAL_ORIG').AsFloat;
        end
        else
        begin
          precOrigSal := 0;
          precOrigFin := 0;
        end;

        CalcularPreciosFinales(precOrigSal, precOrigFin,
                               precSalida, precFinal, dto);

        if (precOrigSal = 0) and (precOrigFin = 0) then
        begin
          precSalida := 0;
          precFinal  := 0;
          dto        := spnPorcenDto.Value;
        end;

        // Euros de descuento: salida - final (0 si no hay descuento real)
        dtoEuros := precSalida - precFinal;
        if dtoEuros < 0 then
          dtoEuros := 0;

        ins.ParamByName('CODIGO_ART_ART').AsString :=
          FSqlPreview.FieldByName('CODIGO_ART_ART').AsString;
        ins.ParamByName('CODIGO_TAR_ARTTAR').AsString  := codigoTar;
        ins.ParamByName('PRECIO_SALIDA').AsFloat   := precSalida;
        ins.ParamByName('PRECIO_FINAL').AsFloat    := precFinal;
        ins.ParamByName('PRECIO_DTO').AsFloat      := dtoEuros;
        ins.ParamByName('PORCEN_DTO').AsFloat      := dto;
        ins.ParamByName('FECHA_DESDE').AsDateTime  := dtFechaDesde.Date;

        if chkConFechaHasta.Checked then
          ins.ParamByName('FECHA_HASTA').AsDateTime := dtFechaHasta.Date
        else
          ins.ParamByName('FECHA_HASTA').Clear;

        ins.ParamByName('USR').AsString  := usuario;
        ins.ParamByName('USR2').AsString := usuario;

        ins.Execute;
        codigos.Add(FSqlPreview.FieldByName('CODIGO_ART_ART').AsString);
        Inc(ANumInsertados);

        FSqlPreview.Next;
      end;
      FConn.Commit;
      Result := True;
      ACodigos := codigos.ToArray;

      // Rellenar resultado especifico
      FResultadoTarifa.Aceptado         := True;
      FResultadoTarifa.NumInsertados    := ANumInsertados;
      FResultadoTarifa.ArticulosCodigos := ACodigos;
      FResultadoTarifa.CodigoTarifa     := codigoTar;
      FResultadoTarifa.FechaDesdeTarifa := dtFechaDesde.Date;
      FResultadoTarifa.UsaFechaHasta    := chkConFechaHasta.Checked;
      if chkConFechaHasta.Checked then
        FResultadoTarifa.FechaHastaTarifa := dtFechaHasta.Date;
      FResultadoTarifa.PorcenDtoDefecto := spnPorcenDto.Value;
      FResultadoTarifa.AjustarPrecio    := chkAjustarPrecio.Checked;
      FResultadoTarifa.MultiploAjuste   := spnMultiplo.Value;
      FResultadoTarifa.RestarAjuste     := spnRestar.Value;
      FResultadoTarifa.AlcanceAjuste    := AlcanceAjusteActual;
      FResultadoTarifa.CopiarDeTarifa   := ObtenerCodigoTarifaOrigen;
    except
      on E: Exception do
      begin
        FConn.Rollback;
        ShowMessage('Error al insertar: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    FSqlPreview.EnableControls;
    FreeAndNil(ins);
    FreeAndNil(codigos);
  end;
end;

end.
